#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'
require 'yaml'

include OSX
OSX.require_framework 'Security'
OSX.load_bridge_support_file(NSBundle.mainBundle.pathForResource_ofType("Security", "bridgesupport"))
OSX.ruby_thread_switcher_stop

class ApplicationController < OSX::NSObject

	ib_outlet :preferencesWindow
	ib_outlet :menu
	ib_action :openInbox
	ib_action :checkMail
	ib_action :showAbout
	ib_action :showPreferencesWindow

		
	def	awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
		bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('app', 'tiff'))
		@mail_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('mail', 'tiff'))
		@check_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('check', 'tiff'))
		@error_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('error', 'tiff'))
		
		@status_item.setImage(@app_icon)
		
		setupDefaults
		
		@checker_path = NSBundle.mainBundle.pathForAuxiliaryExecutable('gmailchecker')
		
		@growl = GNGrowlController.alloc.init
		@growl.app = self
		setTimer
		checkMail
	end
	
	def	setupDefaults
		GNPreferences::setupDefaults
	end
	
	def	openInbox
		username = GNPreferences.alloc.init.username
		account_domain = username.split("@")
		
		inbox_url = (account_domain.length == 2 && account_domain[1] != "gmail.com") ? 
			"https://mail.google.com/a/#{account_domain[1]}" : "https://mail.google.com/mail"
		NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(inbox_url))
	end
	
	def	checkMail
		preferences = GNPreferences.alloc.init	
		username = preferences.username
		password = preferences.password
		return unless username.length > 0 && password.length > 0
		
		@status_item.setToolTip("checking mail...")
		@status_item.setImage(@check_icon)
				
		@checker.interrupt and @checker = nil if @checker
		@checker = NSTask.alloc.init
		@checker.setCurrentDirectoryPath(@checker_path.stringByDeletingLastPathComponent)
		@checker.setLaunchPath(@checker_path)

		args = NSArray.arrayWithObjects(username, password, nil)
		@checker.setArguments(args)		
		
		pipe = NSPipe.alloc.init
		@checker.setStandardOutput(pipe)
		
		nc = NSNotificationCenter.defaultCenter
		fn = pipe.fileHandleForReading
		nc.removeObserver(self)
		nc.addObserver_selector_name_object(self, 'checkCountReturned', NSFileHandleReadToEndOfFileCompletionNotification, fn)
		
		@checker.launch
		fn.readToEndOfFileInBackgroundAndNotify
	end
	
	def	checkCountReturned(notification)
		results = YAML.load(
			NSString.alloc.initWithData_encoding(
				notification.userInfo.valueForKey(NSFileHandleNotificationDataItem),
				NSUTF8StringEncoding
			)
		)
		#TODO: switch to multiple accounts check and display results in menus
		results.each do |k, v|
			
		end

		result = results[GNPreferences.alloc.init.username.to_s].split("\n")
		mail_count = result.shift
		
		if mail_count == "E"
			@status_item.setToolTip("connecting error")
			@status_item.setImage(@error_icon)
		elsif mail_count == "F"
			@status_item.setToolTip("username or password wrong")
			@status_item.setImage(@error_icon)
		else
			tooltip = "#{mail_count} new message#{mail_count == '1' ? '' : 's'}"
			@status_item.setToolTip(tooltip)
			if mail_count == "0"
				@status_item.setTitle('') # do not show count for 0
				@status_item.setImage(@app_icon)
			else
				@status_item.setTitle(mail_count)
				@status_item.setImage(@mail_icon)
				
				if @result != result
					preferences = GNPreferences.alloc.init
					
					if preferences.sound != GNPreferences::SOUND_NONE && sound = NSSound.soundNamed(preferences.sound)
						sound.play
					end
					@growl.notify("You have #{tooltip}!", result.join("\n")) if preferences.growl					
					
					@result = result
				end
			end
		end
	end

	def	checkMailByTimer(timer)
		checkMail
	end
	
	def	showAbout(sender)
		NSApplication.sharedApplication.activateIgnoringOtherApps(true)
		NSApplication.sharedApplication.orderFrontStandardAboutPanel(sender)
	end
	
	def	showPreferencesWindow(sender)	
		NSApplication.sharedApplication.activateIgnoringOtherApps(true)
		@preferencesWindow.makeKeyAndOrderFront(sender)
	end
	
	def	setTimer
		@timer.invalidate if @timer
		@timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
			GNPreferences.alloc.init.interval * 60, self, 'checkMailByTimer', nil, true)
	end

end

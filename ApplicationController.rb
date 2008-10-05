#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

include OSX
OSX.require_framework 'Security'
OSX.load_bridge_support_file(NSBundle.mainBundle.pathForResource_ofType("Security", "bridgesupport"))

class ApplicationController < OSX::NSObject
	
	MIN_INTERVAL = 1
	MAX_INTERVAL = 300
	DEFAULT_INTERVAL = 30

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
		
		icon_file = NSBundle.mainBundle.pathForResource_ofType('app', 'tiff')
		icon = NSImage.alloc.initWithContentsOfFile(icon_file)
		@status_item.setImage(icon)
		
		setupDefaults
		
		@checker_path = NSBundle.mainBundle.pathForAuxiliaryExecutable('gmailchecker')
		
		setTimer
		checkMail
	end
	
	def	setupDefaults
		defaults = NSUserDefaults.standardUserDefaults
		values = NSDictionary.dictionaryWithObjectsAndKeys(
			DEFAULT_INTERVAL, "interval",
			"", "username",
			"", "password",
			false, "auto_launch"
		)
		defaults.registerDefaults(values)
	end
	
	def	openInbox
		NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("http://mail.google.com/mail"))
	end
	
	def	checkMail
		@status_item.setToolTip("checking mail...")
		@status_item.setTitle("...")
				
		defaults = NSUserDefaults.standardUserDefaults		
		username = defaults.stringForKey("username")
		password = GNKeychain.new.get_password(username)
		return unless username.length > 0 && password.length > 0
				
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
		data = notification.userInfo.valueForKey(NSFileHandleNotificationDataItem)
		mail_count = NSString.alloc.initWithData_encoding(data, NSUTF8StringEncoding)
		
		#TOTO: better have icons for errors
		if mail_count == "F"
			@status_item.setToolTip("checking fails")
			@staus_item.setTitle(":(")
		elsif mail_count == "E"
			@status_item.setToolTip("username or password wrong")
			@status_item.setTitle(":(")
		else
			#TODO: use different icon to present
			@status_item.setToolTip("#{mail_count} unread mail(s)")
			@status_item.setTitle(mail_count)
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
		defaults = NSUserDefaults.standardUserDefaults		
		interval = defaults.integerForKey("interval")
		@timer.invalidate if @timer
		@timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
			interval * 60, self, 'checkMailByTimer', nil, true)
	end

end

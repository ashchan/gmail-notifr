#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'
OSX.require_framework 'Security'

class ApplicationController < OSX::NSObject
	include OSX
	
	MIN_INTERVAL = 1
	MAX_INTERVAL = 300
	DEFAULT_INTERVAL = 30

	ib_outlet :menu
	ib_action :openInbox
	ib_action :checkMail
		
	def	awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		@status_item.setTitle(0)
		
		icon_file = NSBundle.mainBundle.pathForResource_ofType('app', 'tiff')
		icon = NSImage.alloc.initWithContentsOfFile(icon_file)
		@status_item.setImage(icon)
		
		setupDefaults
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
	
	def checkMail
		defaults = NSUserDefaults.standardUserDefaults
		
		username = defaults.stringForKey("username")
		password = GNKeychain.new.get_password(username)
		
		if username.length > 0 && password.length > 0
			mail_count = GNGmailChecker.new(username, password).new_mail_count
			
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
	end

end

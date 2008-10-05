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

	attr_writer :menu
		
	def	awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		status_item.setHighlightMode(true)
		status_item.setMenu(@menu)
		status_item.setTitle(0)
		
		icon_file = NSBundle.mainBundle.pathForResource_ofType('app', 'tiff')
		icon = NSImage.alloc.initWithContentsOfFile(icon_file)
		status_item.setImage(icon)
		
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

end

#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class ApplicationController < OSX::NSObject
	include OSX

	attr_writer :menu

	def	init
		super_init
		self
	end
	
	def	awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		status_item.setHighlightMode(true)
		status_item.setMenu(@menu)
		status_item.setTitle(0)
		
		icon_file = NSBundle.mainBundle.pathForResource_ofType('app', 'tiff')
		icon = NSImage.alloc.initWithContentsOfFile(icon_file)
		status_item.setImage(icon)
	end

end

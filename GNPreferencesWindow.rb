#
#  GNPreferencesWindow.rb
#  Gmail Notifr
#
#  Created by james on 10/4/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class GNPreferencesWindow < OSX::NSWindow
	include OSX

	ib_outlet :applicationContrller
	ib_outlet :username
	ib_outlet :password
	ib_outlet :interval
	ib_outlet :autoLaunch
	ib_outlet :growl
	ib_outlet :soundList
	ib_action :save

	def	awakeFromNib
		@soundList.removeAllItems
		GNPreferences.sounds.each { |s| @soundList.addItemWithTitle(s) }
	
		load_defaults
		reload_ui
		self.setDelegate(self)
	end
	
	def windowWillClose(notification)
		#cancel changes
		load_defaults
		reload_ui
	end
	
	def	save
		self.orderOut(nil)
			
		interval = @interval.integerValue
		username = @username.stringValue
		password = @password.stringValue
		
		authChanged = false
		resetTimer = false
		
		if @preferences.interval != interval
			@preferences.interval = interval
			resetTimer = true
		end
		
		if (username.length > 0 && password.length > 0) &&
				(username != @preferences.username || password != @preferences.password)
			@preferences.username = username
			@preferences.password = password
			authChanged = true
		end
		
		@preferences.autoLaunch = @autoLaunch.state == NSOnState ? true : false
		@preferences.growl = @growl.state == NSOnState ? true : false
		@preferences.sound = @soundList.titleOfSelectedItem
		
		@preferences.writeBack
		
		reload_ui
		
		@applicationContrller.setTimer if resetTimer
		@applicationContrller.checkMail if authChanged
		
		self.close
	end
	
	def	load_defaults
		@preferences = GNPreferences.alloc.init
	end
	
	def	reload_ui
		@username.setTitleWithMnemonic(@preferences.username)
		@password.setTitleWithMnemonic(@preferences.password)
		@interval.setTitleWithMnemonic(@preferences.interval.to_s)
		@autoLaunch.setState(@preferences.autoLaunch ? NSOnState : NSOffState)
		@growl.setState(@preferences.growl ? NSOnState : NSOffState)
		@soundList.selectItemWithTitle(@preferences.sound)
	end
end

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

	ib_outlet :username
	ib_outlet :interval
	ib_action :save
	ib_outlet :test

	def	awakeFromNib
		reload_ui(load_defaults)
		self.setDelegate(self)
	end
	
	def windowWillClose(notification)
		#cancel changes
		reload_ui(load_defaults)
	end

	
	def	save
		old_values = load_defaults
		interval = 
			@interval.intValue.between?(ApplicationController::MIN_INTERVAL, ApplicationController::MAX_INTERVAL) ?
			@interval.intValue : ApplicationController::DEFAULT_INTERVAL
		username = old_values[:username] #todo
		
		defaults = NSUserDefaults.standardUserDefaults
		
		if old_values[:interval] != interval
			defaults.setInteger_forKey(interval, "interval")
			#todo timer
		end
		
		defaults.synchronize
		
		reload_ui({:username => username, :interval => interval})
		self.close
	end
	
	def	load_defaults
		defaults = NSUserDefaults.standardUserDefaults
		
		username = defaults.stringForKey("username")
		interval = defaults.integerForKey("interval")
		
		return { :username => username, :interval => interval }
	end
	
	def	reload_ui(values)
		username = values[:username]
		interval = values[:interval]
		@username.setTitleWithMnemonic(username) if username && username.length > 0
		@interval.setTitleWithMnemonic(interval.to_s)
	end

end

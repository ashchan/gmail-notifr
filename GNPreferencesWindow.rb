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
	ib_action :save

	def	awakeFromNib
		reload_ui(load_defaults)
		self.setDelegate(self)
	end
	
	def windowWillClose(notification)
		#cancel changes
		reload_ui(load_defaults)
	end

	
	def	save
		self.orderOut(nil)
		
		old_values = load_defaults
		interval = 
			@interval.intValue.between?(ApplicationController::MIN_INTERVAL, ApplicationController::MAX_INTERVAL) ?
			@interval.intValue : ApplicationController::DEFAULT_INTERVAL
		username = @username.stringValue
		password = @password.stringValue
		changed = false
		
		defaults = NSUserDefaults.standardUserDefaults
		
		if old_values[:interval] != interval
			defaults.setInteger_forKey(interval, "interval")
			changed = true
			@applicationContrller.setTimer
		end
		
		if (username.length > 0 && password.length > 0) && (username != old_values[:username] || password != old_values[:password])
			GNKeychain.new.set_account(username, password)
			defaults.setObject_forKey(username, "username")
			changed = true
		end
		
		if changed
			defaults.synchronize
			@applicationContrller.checkMail
		end
		
		reload_ui({:username => username, :password => password, :interval => interval})
		
		self.close
	end
	
	def	load_defaults
		defaults = NSUserDefaults.standardUserDefaults
		
		username = defaults.stringForKey("username")
		password = GNKeychain.new.get_password(username)
		interval = defaults.integerForKey("interval")
		
		return { :username => username, :password => password, :interval => interval }
	end
	
	def	reload_ui(values)
		username = values[:username]
		password = values[:password]
		interval = values[:interval]
		@username.setTitleWithMnemonic(username) if username && username.length > 0
		@password.setTitleWithMnemonic(password) if password && password.length > 0
		@interval.setTitleWithMnemonic(interval.to_s)
	end

end

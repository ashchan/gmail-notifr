#
#  GNAccount.rb
#  Gmail Notifr
#
#  Created by James Chan on 1/3/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

# a normal gmail account, or a google hosted email account
class GNAccount < OSX::NSObject

  attr_accessor :username, :password, :interval, :enabled, :sound, :growl
  Properties = [:username, :interval, :enabled, :sound, :growl]
  	
	MIN_INTERVAL		= 1
	MAX_INTERVAL		= 300
	DEFAULT_INTERVAL	= 30

	def init
		self.password = GNKeychain.alloc.init.get_password(@username)
		super_init
	end

	def	initWithNameIntervalEnabledGrowlSound(username, interval, enabled, growl, sound)
		self.username = username    
    self.interval = interval || DEFAULT_INTERVAL
    self.enabled = enabled
    self.growl = growl
    self.sound = sound
    
		init
	end
  
  def initWithCoder(coder)
    Properties.each do |prop|
      val = coder.decodeObjectForKey(prop)
      self.send("#{prop.to_s}=", val)
    end
    
    init
  end
  
  def encodeWithCoder(coder)
    Properties.each do |prop|
      val = self.send(prop)
      coder.encodeObject_forKey(val, prop)
    end
  end
  
  def description
    "<#{self.class}: #{username}, enabled? : #{enabled?}\ninterval: #{interval}, sound: #{sound}, growl: #{growl}>"
  end
  
  alias inspect to_s
  alias enabled? enabled
  
  def enabled=(val)
    @enabled = val
    @enabled = true if val == 0
  end
  
  def interval=(val)
    @interval = val.to_i
    @interval = DEFAULT_INTERVAL unless @interval.between?(MIN_INTERVAL, MAX_INTERVAL)
  end
  
  def growl=(val)
    @growl = val
    @growl = true if val == 0
  end
	
	def	username=(new_username)
		@old_username ||= @username
		@username = new_username
	end
	
	def	password=(new_password)
		@old_password ||= @password
		@password = new_password
	end
	
	def	username_changed?
		@old_username && @old_username != @username
	end
	
	def	password_changed?
		@old_password && @old_password != @password
	end
	
	def changed?
		username_changed? || password_changed? #todo
	end
end

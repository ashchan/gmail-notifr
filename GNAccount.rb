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

	attr_reader :username, :password

	def init
		super_init
	end

	def	initWithName(username)
		a = init
		
		@username = username
		@password = GNKeychain.alloc.init.get_password(username)
		@existing_account = true
		return a
	end
	
	def	username=(new_username)
		@old_username ||= @username
		@username = new_username
	end
	
	def	password=(new_password)
		@old_password ||= @password
		@password = new_password
	end
	
	def	new?
		!@existing_account
	end
	
	def	destroy
		@deleted = true
	end
	
	def	deleted?
		@deleted
	end
	
	def	username_changed?
		@old_username && @old_username != @username
	end
	
	def	password_changed?
		@old_password && @old_password != @password
	end
	
	def changed?
		username_changed? || password_changed? || deleted?
	end
end

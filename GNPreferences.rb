#
#  GNPreferences.rb
#  Gmail Notifr
#
#  Created by James Chan on 11/7/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

# a simple wrapper for preferences values
class GNPreferences < OSX::NSObject
	
	MIN_INTERVAL		= 1
	MAX_INTERVAL		= 300
	DEFAULT_INTERVAL	= 30
	SOUND_NONE			= "None"
			
	@@soundList = []
	
	attr_accessor :username, :accounts, :password, :interval, :autoLaunch, :growl, :sound
	
	def	init
		super_init
		
		defaults = NSUserDefaults.standardUserDefaults

		@username	= defaults.stringForKey("username") || ""

		@accounts	= NSMutableArray.alloc.init
		usernames = defaults.stringArrayForKey("usernames")

		usernames.each { |u| @accounts << GNAccount.alloc.initWithName(u) } if usernames
		
		# import the single username from version before 0.3
		if @accounts.size == 0 && @username.length > 0
			@accounts << GNAccount.alloc.initWithName(@username)
		end
		
		
		@interval	= defaults.integerForKey("interval") || DEFAULT_INTERVAL
		@growl		= defaults.boolForKey("growl")
		@sound		= defaults.stringForKey("sound") || SOUND_NONE

		@password	= GNKeychain.alloc.init.get_password(username)
				
		@autoLaunch = GNStartItems.alloc.init.isSet
		
		self
	end
	
	# clean accounts changes
	# return true if there's any changes that need to be written back
	def	merge_accounts_change
		changed = false
		accounts_to_remove = NSMutableArray.alloc.init
		@accounts.each do |account|
			NSLog("pending account: #{account.username}")
			if account.new?
				#new added and deleted account, just leave it
				if account.deleted?
					accounts_to_remove << account
				else
					changed = true
				end
			else
				changed = true if account.changed?
			end
		end
		@accounts.removeObjectsInArray(accounts_to_remove)
		changed
	end
	
	def writeBack
		@interval = DEFAULT_INTERVAL unless @interval.between?(MIN_INTERVAL, MAX_INTERVAL)
	
		defaults = NSUserDefaults.standardUserDefaults
		
		defaults.setInteger_forKey(@interval, "interval")
		defaults.setObject_forKey(@username, "username")
		
		defaults.setObject_forKey(@accounts.reject{ |a| a.deleted? }.collect{ |a| a.username }, "usernames")
		defaults.setBool_forKey(@growl, "growl")
		defaults.setObject_forKey(@sound, "sound")

		# save to Info.plist
		defaults.synchronize	
		
		# save accounts to default keychain
		#TODO: still don't delete removed accounts for now, perhaps should add this feature to make the keychain clean
		@accounts.each do |account|
			GNKeychain.alloc.init.set_account(account.username, account.password) if !account.deleted? && account.changed?
		end
		
		# save to startup items
		GNStartItems.alloc.init.set(@autoLaunch)
	end
	
	class << self
		def setupDefaults
			NSUserDefaults.standardUserDefaults.registerDefaults(
				NSDictionary.dictionaryWithObjectsAndKeys(
					DEFAULT_INTERVAL, "interval",
					"", "username",
					[], "usernames",
					"", "password",
					false, "auto_launch",
					SOUND_NONE, "sound",
					1, "growl",
					nil
				)
			)
		end
		
		def	sounds
			return @@soundList if @@soundList.size > 0			
					
			@@soundList.clear

			knownSoundTypes = NSSound.soundUnfilteredFileTypes
			libs = NSSearchPathForDirectoriesInDomains(
				NSLibraryDirectory,
				NSUserDomainMask | NSLocalDomainMask | NSSystemDomainMask,
				true
			)
			
			fileManager = NSFileManager.defaultManager
			
			libs.each do |folder|
				folder_name = File.join(folder, "Sounds")
				if fileManager.fileExistsAtPath_isDirectory(folder_name, nil)
					fileManager.directoryContentsAtPath(folder_name).each do |file|
						if knownSoundTypes.include?(file.pathExtension)						
							@@soundList << file.stringByDeletingPathExtension
						end
					end
				end
			end

			@@soundList.sort.unshift(SOUND_NONE)
		end
	end
	
end

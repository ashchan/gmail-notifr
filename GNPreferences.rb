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
	
	attr_accessor :username, :password, :interval, :autoLaunch, :growl, :sound
	
	def	init
		super_init
		
		defaults = NSUserDefaults.standardUserDefaults

		@username	= defaults.stringForKey("username") || ""
		@interval	= defaults.integerForKey("interval") || DEFAULT_INTERVAL
		@growl		= defaults.boolForKey("growl") || true
		@sound		= defaults.stringForKey("sound") || SOUND_NONE

		@password	= GNKeychain.new.get_password(username)
				
		@autoLaunch = GNStartItems.new.isSet
		
		self
	end
	
	def writeBack
		@interval = DEFAULT_INTERVAL unless @interval.between?(MIN_INTERVAL, MAX_INTERVAL)
	
		defaults = NSUserDefaults.standardUserDefaults
		
		defaults.setInteger_forKey(@interval, "interval")
		defaults.setObject_forKey(@username, "username")
		defaults.setBool_forKey(@growl, "growl")
		defaults.setObject_forKey(@sound, "sound")

		# save to Info.plist
		defaults.synchronize	
		
		# save to default keychain
		GNKeychain.new.set_account(@username, @password)
		
		# save to startup items
		GNStartItems.new.set(@autoLaunch)
	end
	
	class << self
		def setupDefaults
			NSUserDefaults.standardUserDefaults.registerDefaults(
				NSDictionary.dictionaryWithObjectsAndKeys(
					DEFAULT_INTERVAL, "interval",
					"", "username",
					"", "password",
					false, "auto_launch",
					SOUND_NONE, "sound",
					true, "growl",
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

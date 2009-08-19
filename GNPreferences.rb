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
	SOUND_NONE			= NSLocalizedString("Sound None")
			
	@@soundList = []
	
	attr_accessor :accounts, :autoLaunch, :showUnreadCount
  
  def self.sharedInstance
    @instance ||= self.alloc.init
  end
	
	def	init
		super_init
		
		defaults = NSUserDefaults.standardUserDefaults

		@accounts	= NSMutableArray.alloc.init
    
    
    if archivedAccounts = defaults.objectForKey(Accounts)
      @accounts = archivedAccounts.map { |a| NSKeyedUnarchiver.unarchiveObjectWithData(a) }
    end
    
    # from version <= 0.4.3
    if @accounts.count == 0 && usernames = defaults.stringArrayForKey("usernames")
      interval = defaults.integerForKey("interval")
      growl	= defaults.boolForKey("growl")
      sound	= defaults.stringForKey("sound") || SOUND_NONE
      
      usernames.each do |u|
        account = GNAccount.alloc.initWithNameIntervalEnabledGrowlSound(u, interval, true, growl, sound)
        @accounts.addObject(account)
      end
      
      # remove legacy preferences
      %w(username usernames growl sound interval show_unread_count).each do |k|
        defaults.removeObjectForKey(k)
      end
      writeBack
    end

		@autoLaunch = GNStartItems.alloc.init.isSet
		@showUnreadCount = defaults.boolForKey(ShowUnreadCount)

		self
	end
  
  def autoLaunch?
    GNStartItems.alloc.init.isSet
  end
    
  def autoLaunch=(val)
		GNStartItems.alloc.init.set(val)
  end
  
  def showUnreadCount?
    NSUserDefaults.standardUserDefaults.boolForKey(ShowUnreadCount)
  end
  
  def showUnreadCount=(val)
		NSUserDefaults.standardUserDefaults.setObject_forKey(val, ShowUnreadCount)
    NSUserDefaults.standardUserDefaults.synchronize
  end
	
	# clean accounts changes
	# return true if there's any changes that need to be written back
	def	merge_accounts_change
		true
	end
	
	def writeBack
		defaults = NSUserDefaults.standardUserDefaults
				
		defaults.setObject_forKey(
      @accounts.map { |a| NSKeyedArchiver.archivedDataWithRootObject(a) },
      Accounts
    )

		# save to Info.plist
		defaults.synchronize	
		
		# save accounts to default keychain
		#TODO: still don't delete removed accounts for now, perhaps should add this feature to make the keychain clean
		#@accounts.each do |account|
		#	GNKeychain.alloc.init.set_account(account.username, account.password) if !account.deleted? && account.changed?
		#end
		
	end
	
	class << self
		def setupDefaults
			NSUserDefaults.standardUserDefaults.registerDefaults(
				NSDictionary.dictionaryWithObjectsAndKeys(
					true, ShowUnreadCount,
          PrefsToolbarItemAccounts, PreferencesSelection,
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

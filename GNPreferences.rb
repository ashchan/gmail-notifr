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
      sound	= defaults.stringForKey("sound") || GNSound::SOUND_NONE
      
      usernames.each do |u|
        account = GNAccount.alloc.initWithNameIntervalEnabledGrowlSound(u, interval, true, growl, sound)
        account.save
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
    NSNotificationCenter.defaultCenter.postNotificationName_object(GNShowUnreadCountChangedNotification, self)
  end
  
  def addAccount(account)
    @accounts.addObject(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName_object(GNAccountAddedNotification, self)
  end
  
  def removeAccount(account)
    @accounts.removeObject(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName_object(GNAccountRemovedNotification, self)
  end
  
  def saveAccount(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName_object(GNAccountChangedNotification, self)
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
		@accounts.each do |account|
			GNKeychain.sharedInstance.set_account(account.username, account.password)# if !account.deleted? && account.changed?
		end
		
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
	end
	
end

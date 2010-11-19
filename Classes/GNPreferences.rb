#
#  GNPreferences.rb
#  Gmail Notifr
#
#  Created by James Chan on 11/7/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

# a simple wrapper for preferences values
class GNPreferences  

  attr_accessor :accounts, :autoLaunch, :showUnreadCount
  
  def self.sharedInstance
    @instance ||= self.alloc.init
  end
  
  def init
    super
    
    defaults = NSUserDefaults.standardUserDefaults

    @accounts = NSMutableArray.alloc.init
    
    if archivedAccounts = defaults.objectForKey(Accounts)
      archivedAccounts.each { |a| @accounts.addObject(NSKeyedUnarchiver.unarchiveObjectWithData(a)) }
    end
    
    # from version <= 0.4.3
    if @accounts.count == 0 && usernames = defaults.stringArrayForKey("usernames")
      interval = defaults.integerForKey("interval")
      growl = defaults.boolForKey("growl")
      sound = defaults.stringForKey("sound") || GNSound::SOUND_NONE
      
      usernames.each do |u|
        account = GNAccount.alloc.initWithNameIntervalEnabledGrowlSound(u, interval, true, growl, sound)
        account.gen_guid
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
    NSUserDefaults.standardUserDefaults.setObject(val, forKey:ShowUnreadCount)
    NSUserDefaults.standardUserDefaults.synchronize
    NSNotificationCenter.defaultCenter.postNotificationName(GNShowUnreadCountChangedNotification, object:self)
  end
  
  def addAccount(account)
    @accounts.addObject(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName(GNAccountAddedNotification, object:self, userInfo:{:guid => account.guid})
  end
  
  def removeAccount(account)
    guid = account.guid
    # also delete keychain item
    # FIXFIX should delete old item when renaming an account; don't track name changing now so it's not possible to do so for now
    keychain_item = MRKeychain::GenericItem.item_for_service(KeychainService, username:account.username)
    keychain_item.remove
      
    @accounts.removeObject(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName(GNAccountRemovedNotification, object:self, userInfo:{:guid => guid})
  end
  
  def saveAccount(account)
    writeBack
    NSNotificationCenter.defaultCenter.postNotificationName(GNAccountChangedNotification, object:self, userInfo:{:guid => account.guid})
  end
  
  def writeBack
    defaults = NSUserDefaults.standardUserDefaults
        
    defaults.setObject(
      @accounts.map { |a| NSKeyedArchiver.archivedDataWithRootObject(a) },
      forKey:Accounts
    )

    # save to Info.plist
    defaults.synchronize  
    
    # save accounts to default keychain
    @accounts.each do |account|
      keychain_item = MRKeychain::GenericItem.item_for_service(KeychainService, username:account.username)
      if keychain_item
        keychain_item.password = account.password
      else
        MRKeychain::GenericItem.add_item_for_service(KeychainService, username:account.username, password:account.password)
      end
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

#
#  PrefsSettingsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class PrefsSettingsViewController <  OSX::NSViewController

  ib_outlet :autoLaunch
  ib_outlet :showUnreadCount
  ib_action :saveAutoLaunch
  ib_action :saveShowUnreadCount

  def title
    OSX::NSLocalizedString("PrefsToolbarSettings")
  end
  
  def image
    NSImage.imageNamed('Settings')
  end
  
  def identifier
    "prefsToolbarItemSettings"
  end
  
  def loadView
    super_loadView
		@autoLaunch.setState(GNPreferences.sharedInstance.autoLaunch? ? NSOnState : NSOffState)
    @showUnreadCount.setState(GNPreferences.sharedInstance.showUnreadCount? ? NSOnState : NSOffState)
  end

  def saveAutoLaunch(sender)
    GNPreferences.sharedInstance.autoLaunch = (@autoLaunch.state == NSOnState)
  end 
  
  def saveShowUnreadCount(sender)
    GNPreferences.sharedInstance.showUnreadCount = (@showUnreadCount.state == NSOnState)
    # why NSNotificationCenter doesn't work?
    NSDistributedNotificationCenter.defaultCenter.postNotificationName_object(GNShowUnreadCountChangedNotification, nil)
  end
end

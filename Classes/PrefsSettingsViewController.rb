#
#  PrefsSettingsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

class PrefsSettingsViewController <  NSViewController

  attr_accessor :autoLaunch
  attr_accessor :showUnreadCount

  def title
    NSLocalizedString("Settings")
  end

  def image
    NSImage.imageNamed("NSPreferencesGeneral")
  end

  def identifier
    PrefsToolbarItemSettings
  end

  def loadView
    super
    @autoLaunch.setTitle(NSLocalizedString("Launch at login"))
    @autoLaunch.setState(GNPreferences.sharedInstance.autoLaunch? ? NSOnState : NSOffState)
    @showUnreadCount.setTitle(NSLocalizedString("Show unread count in menu bar"))
    @showUnreadCount.setState(GNPreferences.sharedInstance.showUnreadCount? ? NSOnState : NSOffState)
  end

  def saveAutoLaunch(sender)
    GNPreferences.sharedInstance.autoLaunch = (@autoLaunch.state == NSOnState)
  end

  def saveShowUnreadCount(sender)
    GNPreferences.sharedInstance.showUnreadCount = (@showUnreadCount.state == NSOnState)
  end
end

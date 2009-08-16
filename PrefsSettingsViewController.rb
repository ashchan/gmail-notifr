#
#  PrefsSettingsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class PrefsSettingsViewController <  OSX::NSViewController

  def title
    OSX::NSLocalizedString("PrefsToolbarSettings")
  end
  
  def image
    NSImage.imageNamed('Settings')
  end
  
  def identifier
    "prefsToolbarItemSettings"
  end

end

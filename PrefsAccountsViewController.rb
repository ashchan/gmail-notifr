#
#  PrefsAccountsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class PrefsAccountsViewController <  OSX::NSViewController

  def title
    OSX::NSLocalizedString("PrefsToolbarAccounts")
  end
  
  def image
    NSImage.imageNamed('Accounts')
  end
  
  def identifier
    "prefsToolbarItemAccounts"
  end

end

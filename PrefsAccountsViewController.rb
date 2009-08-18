#
#  PrefsAccountsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class PrefsAccountsViewController <  OSX::NSViewController

  ib_outlet :addButton
  ib_outlet :removeButton
  ib_outlet :editButton
  ib_outlet :accountList
  ib_action :addAccount
  ib_action :removeAccount
  ib_action :editAccount

  def title
    OSX::NSLocalizedString("PrefsToolbarAccounts")
  end
  
  def image
    NSImage.imageNamed('Accounts')
  end
  
  def identifier
    "prefsToolbarItemAccounts"
  end
  
  def loadView
    super_loadView
    #todo
  end
  
  def addAccount(sender)
  end
  
  def removeAccount(sender)
  end
  
  def editAccount(sender)
  end

end

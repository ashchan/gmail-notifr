#
#  AccountDetailController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/19/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class AccountDetailController < OSX::NSWindowController

  ib_action :cancel
  ib_action :okay
  
  def self.editAccountOnWindow(account, parentWindow)
    controller = alloc.initWithAccount(account)
    NSApp.beginSheet_modalForWindow_modalDelegate_didEndSelector_contextInfo(
      controller.window,
      parentWindow,
      controller,
      "sheetDidEnd_returnCode_contextInfo",
      nil
    )
  end
  
  def initWithAccount(account)
    initWithWindowNibName("AccountDetail")
    @account = account
    self
  end
  
  def cancel(sender)
    closeWindow
  end
  
  def okay(sender)
    @account.save
    
    closeWindow
  end
  
  def sheetDidEnd_returnCode_contextInfo(sheet, code, info)
    sheet.orderOut(nil)
  end

  private
  def closeWindow
    NSApp.endSheet(window)
  end
end

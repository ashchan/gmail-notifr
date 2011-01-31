#
#  AccountDetailController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/19/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

class AccountDetailController < NSWindowController

  attr_accessor :username
  attr_accessor :password
  attr_accessor :interval
  attr_accessor :accountEnabled
  attr_accessor :growl
  attr_accessor :soundList

  attr_accessor :usernameLabel
  attr_accessor :passwordLabel
  attr_accessor :checkLabel
  attr_accessor :minuteLabel
  attr_accessor :soundLabel
  attr_accessor :hint
  attr_accessor :cancelButton
  attr_accessor :okButton

  def self.editAccountOnWindow(account, parentWindow)
    controller = alloc.initWithAccount(account)
    NSApp.beginSheet(
      controller.window,
      modalForWindow:parentWindow,
      modalDelegate:controller,
      didEndSelector:"sheetDidEnd:returnCode:contextInfo:",
      contextInfo:nil
    )
  end

  def initWithAccount(account)
    initWithWindowNibName("AccountDetail")
    @account = account
    self
  end

  def awakeFromNib
    @soundList.removeAllItems
    @soundList.addItemWithTitle(GNSound::SOUND_NONE)
    @soundList.menu.addItem(NSMenuItem.separatorItem)
    GNSound.all.each { |s| @soundList.addItemWithTitle(s) }
    @soundList.selectItemWithTitle(@account.sound)

    @interval.setTitleWithMnemonic(@account.interval.to_s)
    @accountEnabled.setState(@account.enabled? ? NSOnState : NSOffState)
    @growl.setState(@account.growl ? NSOnState : NSOffState)
    @username.setTitleWithMnemonic(@account.username)
    @password.setTitleWithMnemonic(@account.password)

    @usernameLabel.setTitleWithMnemonic(NSLocalizedString("Username:"))
    @passwordLabel.setTitleWithMnemonic(NSLocalizedString("Password:"))
    @checkLabel.setTitleWithMnemonic(NSLocalizedString("Check for new mail every"))
    @minuteLabel.setTitleWithMnemonic(NSLocalizedString("minutes"))
    @accountEnabled.title = NSLocalizedString("Enable this account")
    @growl.title = NSLocalizedString("Use Growl Notification")
    @soundLabel.setTitleWithMnemonic(NSLocalizedString("Play sound:"))
    @hint.setTitleWithMnemonic(NSLocalizedString("To add a Google Hosted Account, specify the full email address as username, eg: admin@ashchan.com."))
    @cancelButton.title = NSLocalizedString("Cancel")
    @okButton.title = NSLocalizedString("OK")
  end

  def cancel(sender)
    closeWindow
  end

  def okay(sender)
    @account.sound = @soundList.titleOfSelectedItem
    @account.interval = @interval.integerValue
    @account.enabled = @accountEnabled.state == NSOnState ? true : false
    @account.growl = @growl.state == NSOnState ? true : false
    @account.username = @username.stringValue
    @account.password = @password.stringValue
    @account.save

    closeWindow
  end

  def soundSelect(sender)
    if sound = NSSound.soundNamed(@soundList.titleOfSelectedItem)
      sound.play
    end
  end

  def sheetDidEnd(sheet, returnCode:code, contextInfo:info)
    sheet.orderOut(nil)
  end

  private
  def closeWindow
    NSApp.endSheet(window)
  end
end

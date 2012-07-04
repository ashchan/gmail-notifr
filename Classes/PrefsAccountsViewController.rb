#
#  PrefsAccountsViewController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

class PrefsAccountsViewController <  NSViewController

  attr_accessor :addButton
  attr_accessor :removeButton
  attr_accessor :editButton
  attr_accessor :accountList

  def title
    NSLocalizedString("Accounts")
  end

  def image
    NSImage.imageNamed("NSUserAccounts")
  end

  def identifier
    PrefsToolbarItemAccounts
  end

  def loadView
    super
    registerObservers
    @editButton.title = NSLocalizedString("Edit")
    @accountList.target = self
    @accountList.setDoubleAction("startEditingAccount:")
    forceRefresh
  end

  ## account list table view
  def numberOfRowsInTableView(sender)
    accounts.size
  end

  def tableView tableView, objectValueForTableColumn:tableColumn, row:row
    account = accounts[row]
    if account
      case tableColumn.identifier
      when "AccountName"
        account.username
      when "EnableStatus"
        account.enabled?
      end
    end
  end

  def tableView tableView, setObjectValue:object, forTableColumn:tableColumn, row:row
    if (account = accounts[row]) && tableColumn.identifier == "EnableStatus"
      account.enabled = object
      account.save
    end
  end

  def tableViewSelectionDidChange(notification)
    forceRefresh
  end

  ## button actions
  def startAddingAccount(sender)
    account = GNAccount.alloc.initWithNameIntervalEnabledGrowlSound(
      "username", "", nil, true, true, nil
    )
    AccountDetailController.editAccountOnWindow(account, view.superview.window)
  end

  def endAddingAccount(sender)
    forceRefresh
    index = accounts.size - 1
    @accountList.selectRowIndexes(NSIndexSet.indexSetWithIndex(index), byExtendingSelection:false)
    @accountList.scrollRowToVisible(index)
  end

  def removeAccount(sender)
    account = currentAccount
    if account
      GNPreferences.sharedInstance.removeAccount(account)
      forceRefresh
    end
  end

  def startEditingAccount(sender)
    account = currentAccount
    if account
      AccountDetailController.editAccountOnWindow(account, view.superview.window)
    end
  end

  def endEditingAccount(sender)
    forceRefresh
  end

  private
  def accounts
    GNPreferences.sharedInstance.accounts
  end

  def currentAccount
    if @accountList.selectedRow > -1
      accounts[@accountList.selectedRow]
    else
      nil
    end
  end

  def forceRefresh
    @accountList.reloadData
    enabled = !currentAccount.nil?
    @removeButton.enabled = @editButton.enabled = enabled
  end

  def registerObservers
    center = NSNotificationCenter.defaultCenter
    center.addObserver(
      self,
      selector:"endAddingAccount:",
      name:GNAccountAddedNotification,
      object:nil
    )

    center.addObserver(
      self,
      selector:"endEditingAccount:",
      name:GNAccountChangedNotification,
      object:nil
    )
  end
end

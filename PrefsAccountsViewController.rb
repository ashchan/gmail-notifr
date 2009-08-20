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
  ib_action :startAddingAccount
  ib_action :endAddingAccount
  ib_action :removeAccount
  ib_action :startEditingAccount
  ib_action :endEditingAccount

  def title
    OSX::NSLocalizedString("PrefsToolbarAccounts")
  end
  
  def image
    NSImage.imageNamed("NSUserAccounts")
  end
  
  def identifier
    PrefsToolbarItemAccounts
  end
  
  def loadView
    super_loadView
    registerObservers
    @accountList.target = self
    @accountList.setDoubleAction("startEditingAccount")
    forceRefresh
  end
  
  ## account list table view
  def numberOfRowsInTableView(sender)
		accounts.size
	end
	
	def tableView_objectValueForTableColumn_row(tableView, tableColumn, row)
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
	
	def	tableView_setObjectValue_forTableColumn_row(tableView, object, tableColumn, row)	
    if (account = accounts[row]) && tableColumn.identifier == "EnableStatus"
      account.enabled = object
      account.save
    end
	end
	
	def	tableViewSelectionDidChange(notification)
		forceRefresh
	end
  
  ## button actions
  def startAddingAccount(sender)
    account = GNAccount.alloc.initWithNameIntervalEnabledGrowlSound(
      "username", nil, true, true, nil
    )
    account.markNew
    AccountDetailController.editAccountOnWindow(account, view.superview.window)
  end
  
  def endAddingAccount(sender)        
    forceRefresh
    index = accounts.count - 1
    @accountList.selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(index), false)
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
  
	def	currentAccount
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
    center.addObserver_selector_name_object(
      self,
      "endAddingAccount",
      GNAccountAddedNotification,
      nil
    )
    
    center.addObserver_selector_name_object(
      self,
      "endEditingAccount",
      GNAccountChangedNotification,
      nil
    )
  end
end

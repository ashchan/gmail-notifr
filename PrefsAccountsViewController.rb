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
    PrefsToolbarItemAccounts
  end
  
  def loadView
    super_loadView
    
    forceRefresh
  end
  
  ## account list table view
  def numberOfRowsInTableView(sender)
		accounts.size
	end
	
	def tableView_objectValueForTableColumn_row(tableView, tableColumn, row)
		account = accounts[row]
		account ? (tableColumn.identifier == "AccountName" ? account.username : account.enabled) : ""
	end
	
	def	tableView_setObjectValue_forTableColumn_row(tableView, object, tableColumn, row)		
	end
	
	def	tableViewSelectionDidChange(notification)
		forceRefresh
	end
  
  ## button actions
  def addAccount(sender)
  end
  
  def removeAccount(sender)
  end
  
  def editAccount(sender)
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
    enabled = !currentAccount.nil?
    @removeButton.enabled = @editButton.enabled = enabled
  end
end

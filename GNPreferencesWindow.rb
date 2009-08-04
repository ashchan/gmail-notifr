#
#  GNPreferencesWindow.rb
#  Gmail Notifr
#
#  Created by james on 10/4/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class GNPreferencesWindow < OSX::NSWindow
	include OSX
	
	TAG_USERNAME = 0
	TAG_PASSWORD = 1

	ib_outlet :applicationContrller
	ib_outlet :username
	ib_outlet :password
	ib_outlet :removeButton
	ib_outlet :hint
	ib_outlet :interval
	ib_outlet :autoLaunch
	ib_outlet :growl
	ib_outlet :soundList
	ib_outlet :userList
	ib_outlet :tabView
	
	ib_action :save
	ib_action :soundSelect
	ib_action :addUser
	ib_action :removeUser

	def	awakeFromNib
		@soundList.removeAllItems
		GNPreferences.sounds.each { |s| @soundList.addItemWithTitle(s) }
	
		load_defaults
		self.setDelegate(self)
		@userList.dataSource = self
		@userList.delegate = self
		@username.delegate = self
		@password.delegate = self
		
		reload_ui

		load_toolbar
	end
	
	def windowWillClose(notification)
		#cancel changes
		load_defaults
		reload_ui
	end
	
	def	save
		self.orderOut(nil)
			
		interval = @interval.integerValue
		
		authChanged = false
		resetTimer = false
		
		if @preferences.interval != interval
			@preferences.interval = interval
			resetTimer = true
		end
		
		authChanged = @preferences.merge_accounts_change
		
		@preferences.autoLaunch = @autoLaunch.state == NSOnState ? true : false
		@preferences.growl = @growl.state == NSOnState ? true : false
		@preferences.sound = @soundList.titleOfSelectedItem
		
		@preferences.writeBack
		
		reload_ui
		
		@applicationContrller.setTimer if resetTimer
		@applicationContrller.checkMail if authChanged
		
		self.close
	end
	
	def	load_defaults
		@preferences = GNPreferences.alloc.init
	end
	
	def	reload_ui
		@interval.setTitleWithMnemonic(@preferences.interval.to_s)
		@autoLaunch.setState(@preferences.autoLaunch ? NSOnState : NSOffState)
		@growl.setState(@preferences.growl ? NSOnState : NSOffState)
		@soundList.selectItemWithTitle(@preferences.sound)
		@userList.reloadData
		refresh_account_fields
		show_username_and_password
	end
	
	def soundSelect(sender)
		if sound = NSSound.soundNamed(@soundList.titleOfSelectedItem)
			sound.play
		end
	end
	
	def	addUser(sender)
		account = GNAccount.alloc.init
		account.username = "username"
		account.password = ""
		@preferences.accounts.addObject(account)
		@userList.reloadData
		@userList.selectRow_byExtendingSelection(accounts.size - 1, false)
		
		refresh_account_fields
		
		@username.selectText(self)
	end
	
	def	removeUser(sender)
		selected_account = current_account
		if selected_account
			selected_account.destroy
			@userList.reloadData
		end
		
		refresh_account_fields
		
		show_username_and_password
	end
	
	def numberOfRowsInTableView(sender)
		accounts.size
	end
	
	def tableView_objectValueForTableColumn_row(tableView, tableColumn, row)
		account = accounts[row]
		account ? account.username : ""
	end
	
	def	tableView_setObjectValue_forTableColumn_row(tableView, object, tableColumn, row)		
	end
	
	def	tableViewSelectionDidChange(notification)
		show_username_and_password
	end
	
	def	controlTextDidChange(notification)
		selected_account = current_account
		if selected_account
			field = notification.object
			if field.tag == TAG_USERNAME
				selected_account.username = @username.stringValue
				@userList.reloadData
			elsif field.tag == TAG_PASSWORD
				selected_account.password = @password.stringValue
			else
				NSLog("username/password input not captured")
			end
		end
	end
	
	def	toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar(toolbar, itemIdentifier, flag)
		@toolbarItems.objectForKey(itemIdentifier)
	end
	
	def	toolbarAllowedItemIdentifiers(toolbar)
		@toolbarIdentifiers
	end
	
	def	toolbarDefaultItemIdentifiers(toolbar)
		@toolbarIdentifiers
	end
	
	def	toolbarSelectableItemIdentifiers(toolbbar)
		@toolbarIdentifiers
	end
	
	def	switchToAccountsTab(sender)
		@tabView.selectTabViewItemAtIndex(0)
	end
	
	def	switchToSettingsTab(sender)
		@tabView.selectTabViewItemAtIndex(1)
	end
	
	private
	def	accounts
		@preferences.accounts.reject { |a| a.deleted? }
	end

	def	current_account
		accounts[@userList.selectedRow]
	end
	
	def show_username_and_password
		selected_account = current_account
		if selected_account
			@username.setTitleWithMnemonic(selected_account.username)
			@password.setTitleWithMnemonic(selected_account.password)
		end		
	end
	
	def refresh_account_fields
		enabled = accounts.size > 0
		@username.enabled = @password.enabled = @removeButton.enabled = enabled
		@hint.hidden = enabled
		unless enabled
			@username.setTitleWithMnemonic("")
			@password.setTitleWithMnemonic("")
		end
	end
	
	def	load_toolbar
		@toolbarIdentifiers = [
			"toolbarItemAccounts",
			"toolbarItemSettings"
		]
		
		
		bundle = NSBundle.mainBundle
		
		item_accounts = NSToolbarItem.alloc.initWithItemIdentifier(@toolbarIdentifiers[0])
		item_accounts.label = "Accounts"
		item_accounts.image = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('Accounts', 'tiff'))
		item_accounts.target = self;
		item_accounts.action = "switchToAccountsTab"
		
		item_settings = NSToolbarItem.alloc.initWithItemIdentifier(@toolbarIdentifiers[1])
		item_settings.label = "Settings"
		item_settings.image = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource_ofType('Settings', 'tiff'))
		item_settings.target = self;
		item_settings.action = "switchToSettingsTab"
		
		@toolbarItems = NSMutableDictionary.alloc.init
		@toolbarItems.setObject_forKey(item_accounts, @toolbarIdentifiers[0])
		@toolbarItems.setObject_forKey(item_settings, @toolbarIdentifiers[1])
		
		toolbar = NSToolbar.alloc.initWithIdentifier("preferencesToolbar")
		toolbar.delegate = self
		toolbar.setAllowsUserCustomization(false)
		toolbar.setSelectedItemIdentifier(@toolbarIdentifiers[0])
		self.setToolbar(toolbar)
	end
end

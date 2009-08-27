#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'
require 'yaml'

include OSX
OSX.require_framework 'Security'
OSX.load_bridge_support_file(NSBundle.mainBundle.pathForResource_ofType("Security", "bridgesupport"))
OSX.ruby_thread_switcher_stop

class ApplicationController < OSX::NSObject

	ACCOUNT_MENUITEM_POS = 2
	DONATE_URL = "http://www.pledgie.com/campaigns/2046"

	ib_outlet :menu
	ib_action :openInbox
	ib_action :checkMailByMenu
	ib_action :showAbout
	ib_action :showPreferencesWindow
	ib_action :donate

		
	def	awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
		@app_icon = NSImage.imageNamed('app.tiff')
		@app_alter_icon = NSImage.imageNamed('app_a.tiff')
		@mail_icon = NSImage.imageNamed('mail.tiff')
		@mail_alter_icon = NSImage.imageNamed('mail_a.tiff')
		@check_icon = NSImage.imageNamed('check.tiff')
		@check_alter_icon = NSImage.imageNamed('check_a.tiff')
		@error_icon = NSImage.imageNamed('error.tiff')
		
		@status_item.setImage(@app_icon)
		@status_item.setAlternateImage(@app_alter_icon)
		
		setupDefaults
    
    registerObservers

    registerGrowl

    setupMenu
    setupCheckers
	end
	
	def	setupDefaults
		GNPreferences::setupDefaults
	end
	
	def	openInbox(sender)
		if sender.title == NSLocalizedString("Open Inbox")
			# "Open Inbox" menu item
			account = accountForGuid(sender.menu.title)
		else
			# top menu item for account
			account = accountForGuid(sender.submenu.title)
		end
		# remove the "(number)" part from account name
		openInboxForAccount(account)
	end
  
  def toggleAccount(sender)
    account = accountForGuid(sender.menu.title)
    account.enabled = !account.enabled
    account.save
    
    updateMenuItemAccountEnabled(account)
    checkerForAccount(account).reset
  end

	def openMessage(sender)
		NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(sender.representedObject()))
	end
	
	def	openInboxForAccount(account)
    openInboxForAccountName(account.username)
	end
  
  def	openInboxForAccountName(name)
		account_domain = name.split("@")
		
		inbox_url = (account_domain.length == 2 && !["gmail.com", "googlemail.com"].include?(account_domain[1])) ? 
			"https://mail.google.com/a/#{account_domain[1]}" : "https://mail.google.com/mail"
		NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(inbox_url))
	end

	def checkMailByMenu
		checkAll
	end
	
	def	showAbout(sender)
		NSApplication.sharedApplication.activateIgnoringOtherApps(true)
		NSApplication.sharedApplication.orderFrontStandardAboutPanel(sender)
	end
	
	def	showPreferencesWindow(sender)	
		NSApplication.sharedApplication.activateIgnoringOtherApps(true)
		PreferencesController.sharedController.showWindow(sender)
	end

	def	donate
		NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(DONATE_URL))
	end
  
  #todo
  def updateMenuBarCount(notification = nil)
    if GNPreferences.sharedInstance.showUnreadCount? && @mail_count && @mail_count > 0
      @status_item.setTitle(@mail_count)
    else
      @status_item.setTitle('')
    end
  end
  
  def accountAdded(notification)
    account = accountForGuid(notification.userInfo[:guid])
    addAccountMenuItem(account, GNPreferences.sharedInstance.accounts.count - 1)
    checker = GNChecker.alloc.initWithAccount(account)
    @checkers << checker
    checker.reset
  end
    
  def accountChanged(notification)
    account = accountForGuid(notification.userInfo[:guid])
    updateMenuItemAccountEnabled(account)
    checkerForAccount(account).reset
  end
    
  def accountRemoved(notification)
    item = menuItemForGuid(notification.userInfo[:guid])
    @status_item.menu.removeItem(item)
    checker = checkerForGuid(notification.userInfo[:guid])
    checker.cleanupAndQuit
    @checkers.delete(checker)
  end
  
  def	updateAccountMenuItem(notification)
    account = accountForGuid(notification.userInfo[:guid])
    menuItem = menuItemForAccount(account)
    count = menuItem.submenu.itemArray.count
    if count > 3
      (count - 1).downto(3).each { |idx| menuItem.submenu.removeItemAtIndex(idx) }
    end
    
    if account.enabled?
      
      msgItem = menuItem.submenu.addItemWithTitle_action_keyEquivalent_("Last checked: #{notification.userInfo[:checkedAt]}", nil, "")
      msgItem.enabled = false
    end
  
    return
    #todo
		#new messages
		result = results.split("\n")
		mail_count = result.shift
		has_error = false
		
		if mail_count == "E"
			has_error = true
			item = accountMenu.addItemWithTitle_action_keyEquivalent(NSLocalizedString("Connection Error"), nil, "")
		elsif mail_count == "F"
			has_error = true
			item = accountMenu.addItemWithTitle_action_keyEquivalent(NSLocalizedString("Username/password Wrong"), nil, "")
		else
			mail_count = mail_count.to_i
			@mail_count += mail_count.to_i
			tooltip = (mail_count == 1 ? NSLocalizedString("Unread Message") % mail_count :
				NSLocalizedString("Unread Messages") % mail_count)
			subjects = Array.new
			result.each do |msg|	 
				link = msg.split("|")[0]
				subject = msg.split("|")[1]
				subjects.push(subject)
				msgItem = accountMenu.addItemWithTitle_action_keyEquivalent_(subject, "openMessage", "")
				msgItem.enabled = true
				msgItem.setRepresentedObject_(link)
				msgItem.target = self
			end
			
			if mail_count == 0
				force_clear_cache(account_name)
			else
				cache_result(account_name, tooltip + "\n" + subjects.join("\n"))
			end
		end
		
		
		if has_error
			accountItem.setImage(@error_icon)
			force_clear_cache(account_name)
		end
	end
  
  # delegate not working if :click_context not provided?
	def growlNotifierClicked_context(sender, context)
		openInboxForAccountName(context) if context
	end

	def growlNotifierTimedOut_context(sender, context)
	end

  private
  
  def registerObservers
    center = NSNotificationCenter.defaultCenter
    
    center.addObserver_selector_name_object(
      self,
      "updateMenuBarCount",
      GNShowUnreadCountChangedNotification,
      nil
    )
    
    center = NSNotificationCenter.defaultCenter
    center.addObserver_selector_name_object(
      self,
      "accountAdded",
      GNAccountAddedNotification,
      nil
    )
    
    center.addObserver_selector_name_object(
      self,
      "accountChanged",
      GNAccountChangedNotification,
      nil
    )
    
    center.addObserver_selector_name_object(
      self,
      "accountRemoved",
      GNAccountRemovedNotification,
      nil
    )
    
    center.addObserver_selector_name_object(
      self,
      "updateAccountMenuItem",
      GNAccountMenuUpdateNotification,
      nil
    )
  end
  
  def registerGrowl
    g = Growl::Notifier.sharedInstance
    g.delegate = self
    g.register('Gmail Notifr', ['new_messages'])
  end
  
  def setupCheckers
    @checkers = []
    GNPreferences.sharedInstance.accounts.each do |a|
      @checkers << GNChecker.alloc.initWithAccount(a)
    end
    
    checkAll
  end
  
  def checkAll  
    @checkers.each do |c|
      c.reset
    end
  end
  
  def accountForGuid(guid)
    GNPreferences.sharedInstance.accounts.find { |a| a.guid == guid }
  end
  
  def checkerForAccount(account)
    @checkers.find { |c| c.forAccount?(account) }
  end
  
  def checkerForGuid(guid)
    @checkers.find { |c| c.forGuid?(guid) }
  end
  
  def messageCount
    @checkers.sum { |c| c.messageCount }
  end
  
  def setupMenu
    GNPreferences.sharedInstance.accounts.each_with_index do |a, i|
      addAccountMenuItem(a, i)
    end
  end
  
  def addAccountMenuItem(account, index)
    accountMenu = NSMenu.alloc.initWithTitle(account.guid)
		
		#open inbox menu item
		openInboxItem = accountMenu.addItemWithTitle_action_keyEquivalent(NSLocalizedString("Open Inbox"), "openInbox", "")
		openInboxItem.target = self
		openInboxItem.enabled = true
    
    #enable/disable menu item
    enableAccountItem = accountMenu.addItemWithTitle_action_keyEquivalent(
      account.enabled? ? NSLocalizedString("Disable") : NSLocalizedString("Enable"),
      "toggleAccount", ""
    )
    enableAccountItem.target = self
    enableAccountItem.enabled = true
		
		accountMenu.addItem(NSMenuItem.separatorItem)
    
    #top level menu item for acount
		accountItem = NSMenuItem.alloc.init
		accountItem.title = account.username
		accountItem.submenu = accountMenu
		accountItem.target = self
		accountItem.action = 'openInbox'

		@status_item.menu.insertItem_atIndex(accountItem, ACCOUNT_MENUITEM_POS + index)
  end
  
  def menuItemForAccount(account)
    menuItemForGuid(account.guid)
  end
  
  def menuItemForGuid(guid)
    @status_item.menu.itemArray.find { |i| i.submenu && i.submenu.title == guid }
  end
  
  def updateMenuItemAccountEnabled(account)
    menuItemForAccount(account).submenu.itemAtIndex(1).title = account.enabled? ? NSLocalizedString("Disable") : NSLocalizedString("Enable")
  end
end

#
#  PreferencesController.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/16/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#
#  preferences window and toolbar implementation learnt from Matt Ball:
#  http://mattballdesign.com/blog/2008/10/01/building-a-preferences-window/

require 'osx/cocoa'

class PreferencesController < OSX::NSWindowController

  ib_outlet :accountsPane
  ib_outlet :settingsPane

  def self.sharedController
    unless @sharedInstance
      @sharedInstance = self.alloc.init
      
      accounts = PrefsAccountsViewController.alloc.initWithNibName_bundle("PreferencesAccounts", nil)
      settings = PrefsSettingsViewController.alloc.initWithNibName_bundle("PreferencesSettings", nil)
      @sharedInstance.modules = [accounts, settings]
    end
    
    @sharedInstance
  end

  def	init
    if super_init
      prefsWindow = NSWindow.alloc.initWithContentRect_styleMask_backing_defer(
        NSMakeRect(0, 0, 550, 260),
        NSTitledWindowMask | NSClosableWindowMask,
        NSBackingStoreBuffered,
        true
      )
      prefsWindow.setShowsToolbarButton(false)
      self.window = prefsWindow

      setupToolbar
    end

    self
  end
	
  def	toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar(toolbar, itemIdentifier, flag)
    mod = moduleForIdentifier(itemIdentifier)
    item = NSToolbarItem.alloc.initWithItemIdentifier(itemIdentifier)
    
    if mod
      item.label = mod.title
      item.image = mod.image
      item.target = self;
      item.action = "selectModule"
    end
    
    item
  end

  def	toolbarAllowedItemIdentifiers(toolbar)
    @modules.map { |mod| mod.identifier }
  end

  def	toolbarDefaultItemIdentifiers(toolbar)
    nil
  end

  def	toolbarSelectableItemIdentifiers(toolbar)
    toolbarAllowedItemIdentifiers(toolbar)
  end
  
  def showWindow(sender)
    self.window.center
    super_showWindow(sender)
  end

  def	selectModule(sender)
    mod = moduleForIdentifier(sender.itemIdentifier)
    switchToModule(mod) if mod
  end
  
  def modules=(newModules)
    @modules = newModules
    toolbar = self.window.toolbar
    return unless toolbar && toolbar.items.count == 0
    
    @modules.each do |mod|
      toolbar.insertItemWithItemIdentifier_atIndex(mod.identifier, toolbar.items.count)
    end
    
    savedIdentifier = NSUserDefaults.standardUserDefaults.stringForKey("PreferencesSelection")
    defaultModule = moduleForIdentifier(savedIdentifier) || @modules.first
    switchToModule(defaultModule)
  end

  private
	def	setupToolbar
    toolbar = NSToolbar.alloc.initWithIdentifier("preferencesToolbar")
    toolbar.delegate = self
    toolbar.setAllowsUserCustomization(false)
    self.window.setToolbar(toolbar)
	end

  def switchToModule(mod)
    @currentModule.view.removeFromSuperview if @currentModule
    
    newView = mod.view
    
    windowFrame = self.window.frameRectForContentRect(newView.frame)
    windowFrame.origin = self.window.frame.origin;
    windowFrame.origin.y -= windowFrame.size.height - self.window.frame.size.height
    self.window.setFrame_display_animate(windowFrame, true, true)
    
    self.window.toolbar.setSelectedItemIdentifier(mod.identifier)
    self.window.title = mod.title
    
    @currentModule = mod
    self.window.contentView.addSubview(@currentModule.view)
    self.window.setInitialFirstResponder(@currentModule.view)
    
    NSUserDefaults.standardUserDefaults.setObject_forKey(mod.identifier, "PreferencesSelection")
  end

  def moduleForIdentifier(identifier)
    @modules.find { |mod| mod.identifier == identifier }
  end
end

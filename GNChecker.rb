#
#  GNChecker.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/27/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class GNChecker < OSX::NSObject
  def init
    super_init
  end
  
  def initWithAccount(account)
    init
    @account = account
    @guid = account.guid
    
    @checker_path = NSBundle.mainBundle.pathForAuxiliaryExecutable('gmailchecker')    

    self
  end
  
  def forAccount?(account)
    account.guid == @account.guid
  end
  
  def forGuid?(guid)
    @guid == guid
  end
  
  def userError?
    true
  end
  
  def connectionError?
    true
  end
  
  def messages
  end
  
  def messageCount
    return 0 unless @account && @account.enabled?
    @msgCount || 0
  end
  
  def reset
    cleanup
    NSNotificationCenter.defaultCenter.postNotificationName_object_userInfo(GNCheckingAccountNotification, self, :guid => @account.guid)

    if @account && @account.enabled?
      @timer = NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats(
        @account.interval * 60, self, 'checkMail', nil, true)

      @checker = NSTask.alloc.init
      @checker.setCurrentDirectoryPath(@checker_path.stringByDeletingLastPathComponent)
      @checker.setLaunchPath(@checker_path)

      
      args = NSMutableArray.alloc.init
      args.addObject(@account.username.to_s)
      # pass password as base64 encoded to gmailchecker
      args.addObject([@account.password.to_s].pack("m"))
      @checker.setArguments(args)
      
      @pipe = NSPipe.alloc.init
      @checker.setStandardOutput(@pipe)
  
      nc = NSNotificationCenter.defaultCenter
      fn = @pipe.fileHandleForReading
      nc.addObserver_selector_name_object(self, 'checkResult', NSFileHandleReadToEndOfFileCompletionNotification, fn)
      
      @checker.launch
      
      fn.readToEndOfFileInBackgroundAndNotify
    else
      notifyMenuUpdate
    end
  end
  
  def	checkMail				
		reset
	end
	
	def	checkResult(notification)  
    @checkedAt = DateTime.now
    
		preferences = GNPreferences.sharedInstance

		results = YAML.load(
			NSString.alloc.initWithData_encoding(
				notification.userInfo.valueForKey(NSFileHandleNotificationDataItem),
				NSUTF8StringEncoding
			)
		)
    #todo, cache result, send notification
    should_notify = true
    notifyMenuUpdate
    
    if should_notify && @account.growl
      notify(@account.username, "todo")
    end
		if should_notify && @account.sound != GNSound::SOUND_NONE && sound = NSSound.soundNamed(@account.sound)
			sound.play
		end
	end
  
  def checkedAt
    @checkedAt ? @checkedAt.strftime("%I:%M%p") : "NA"
  end
  
  def notifyMenuUpdate
    NSNotificationCenter.defaultCenter.postNotificationName_object_userInfo(GNAccountMenuUpdateNotification, self, :guid => @account.guid, :checkedAt => checkedAt)
  end
  
  def notify(title, desc)
		Growl::Notifier.sharedInstance.notify('new_messages', title, desc, :click_context => title)
	end
  
  def cleanup
    @checker.interrupt and @checker = nil if @checker
    @timer.invalidate if @timer
    
		if @pipe
      NSNotificationCenter.defaultCenter.removeObserver_name_object(self, NSFileHandleReadToEndOfFileCompletionNotification, @pipe.fileHandleForReading)
    end
  end
  
  def cleanupAndQuit
    cleanup
    @timer = nil
    @pipe = nil
  end
end

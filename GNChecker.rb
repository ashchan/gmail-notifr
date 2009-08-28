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
    @messages = []
    
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
    @userError
  end
  
  def connectionError?
    @connectionError
  end
  
  def messages
    @messages
  end
  
  def messageCount
    return 0 unless @account && @account.enabled?
    @messageCount || 0
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
    
    result = results[@account.username.to_s]
    return unless result
    
    @messages.clear
    @messageCount = result[:count]
    @connectionError = result[:error] == "ConnectionError"
    @userError = result[:error] == "UserError"

    result[:messages].each do |msg|
      @messages << {
        :subject => msg[:subject],
        :author => msg[:author],
        :link => normalizeMessageLink(msg[:link]),
        :id => msg[:id],
        :date => msg[:date],
        :summary => msg[:summary]
      }
    end
    
    shouldNotify = @account.enabled? && @messages.count > 0
    if shouldNotify
      newestDate = @messages.map { |m| m[:date] }.sort[-1]
      
      if @newestDate
        shouldNotify = newestDate > @newestDate
      end

      @newestDate = newestDate
    end
    
    notifyMenuUpdate
    
    if shouldNotify && @account.growl
      info = @messages.map { |m| "#{m[:author]} : #{m[:subject]}" }.join("\n\n")
      if @messageCount > @messages.count
        info += "\n\n..."
      end
      
      unreadCount = @messageCount == 1 ? NSLocalizedString("Unread Message") % @messageCount :
          NSLocalizedString("Unread Messages") % @messageCount
      
      notify(@account.username, [unreadCount, info].join("\n\n"))
    end
		if shouldNotify && @account.sound != GNSound::SOUND_NONE && sound = NSSound.soundNamed(@account.sound)
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
  
  private
  def normalizeMessageLink(link)
    if @account.username.include?("@")
      domain = @account.username.split("@")[1]
      if domain != "gmail.com" && domain != "googlemail.com"
        link = link.gsub("/mail?", "/a/#{domain}/?")
      end
    end
    
    link
  end
end

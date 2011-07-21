#
#  GNChecker.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/27/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

class GNCheckOperation < NSOperation
  def initWithUsername(username, password:password, guid:guid)
    init
    @username = username
    @password = password
    @guid = guid
    self
  end

  def start
    if !NSThread.isMainThread
       performSelectorOnMainThread("start", withObject:nil, waitUntilDone:false)
       return
    end

    willChangeValueForKey("isExecuting")
    @isExecuting = true
    didChangeValueForKey("isExecuting")

    removeCredential

    @buffer = NSMutableData.new
    request = NSURLRequest.requestWithURL(NSURL.URLWithString("https://mail.google.com/mail/feed/atom"))
    NSURLConnection.alloc.initWithRequest(request, delegate:self)
  end

  def finish
    willChangeValueForKey("isExecuting")
    willChangeValueForKey("isFinished")
    @isExecuting = false
    @isFinished = true
    didChangeValueForKey("isExecuting")
    didChangeValueForKey("isFinished")
  end

  def isExecuting
    @isExecuting
  end

  def isFinished
    @isFinished
  end

  def main
  end

  def process(xml = nil)
    result = { :error => "ConnectionError", :count => 0, :messages => [] }
    if @error && @error.code == NSURLErrorUserCancelledAuthentication || @statusCode == 401
      result[:error] = "UserError"
    end

    if xml && !@error
      feed = NSXMLDocument.alloc.initWithXMLString(xml, options:NSXMLDocumentTidyXML, error:nil)
      # messages count
      result[:count] = feed.nodesForXPath('/feed/fullcount', error:nil)[0].stringValue.to_i
      result[:error] = "No"

      # return first 10 messages
      feed.nodesForXPath('/feed/entry', error:nil).first(10).each do |msg|
        # gmail atom gives time string like 2009-08-29T24:56:52Z
        # note 24 causes ArgumentError: argument out of range
        # make it 23 and hope it won't matter too much
        issued = msg.elementsForName('issued')[0].stringValue
        issued.gsub!(/T24/, 'T23')
        date = Time.parse(issued)

        result[:messages] << {
          :link => msg.elementsForName('link')[0].attributeForName('href').stringValue,
          :author => msg.elementsForName('author')[0].elementsForName('name')[0].stringValue,
          :subject => msg.elementsForName('title')[0].stringValue,
          :id => msg.elementsForName('id')[0].stringValue,
          :date => date,
          :summary => msg.elementsForName('summary')[0].stringValue
        }
      end
    end

    NSNotificationCenter.defaultCenter.postNotificationName(GNCheckedAccountNotification,
      object:self,
      userInfo:{:guid => @guid, :results => result}
    )
    finish
  end

  def removeCredential
    credentialStorage = NSURLCredentialStorage.sharedCredentialStorage

    space = credentialStorage.allCredentials.select do |space, dict|
      space.host =~ /^mail.google.com\//
    end
    if space
      space.values.each { |u, c| credentialStorage.removeCredential(c, forProtectionSpace:space) if u == @username || u == @username + "@gmail.com" }
    end
  end

  def connectionShouldUseCredentialStorage(conn)
    false
  end

  def connection(conn, didReceiveAuthenticationChallenge:challenge)
    if challenge.previousFailureCount == 0
      credential = NSURLCredential.credentialWithUser(@username, password:@password, persistence:NSURLCredentialPersistenceNone)
      challenge.sender.useCredential(credential, forAuthenticationChallenge:challenge)
    else
      challenge.sender.cancelAuthenticationChallenge(challenge)
    end
  end

  def connection(conn, didReceiveResponse:res)
    @buffer.setLength(0)
    @statusCode = res.statusCode
  end

  def connection(conn, didReceiveData:data)
    @buffer.appendData(data)
  end

  def connection(conn, didFailWithError:err)
    @error = err.copy
    process
  end

  def connectionDidFinishLoading(conn)
    process(NSString.alloc.initWithData(@buffer, encoding:NSUTF8StringEncoding))
  end
end

class GNChecker
  @@queue = NSOperationQueue.alloc.init

  def init
    super
  end

  def initWithAccount(account)
    init
    @account = account
    @guid = account.guid
    @messages = []
    NSNotificationCenter.defaultCenter.addObserver(self, selector:'checkResults:', name:GNCheckedAccountNotification, object:nil)
    self
  end

  def queue
    @@queue
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
    NSNotificationCenter.defaultCenter.postNotificationName(GNCheckingAccountNotification, object:self, userInfo:{:guid => @account.guid})

    if @account && @account.enabled?
      @timer = NSTimer.scheduledTimerWithTimeInterval(
        @account.interval * 60, target:self, selector:'checkMail', userInfo:nil, repeats:true)

      checker = GNCheckOperation.alloc.initWithUsername(@account.username, password:@account.password, guid:@account.guid)
      queue.addOperation(checker)
    else
      notifyMenuUpdate
    end
  end

  def checkMail
    reset
  end

  def checkResults(notification)
    return unless notification.userInfo[:guid] == @account.guid

    @checkedAt = Time.now
    results = notification.userInfo[:results]

    @messages.clear
    @messageCount = results[:count]
    @connectionError = results[:error] == "ConnectionError"
    @userError = results[:error] == "UserError"

    results[:messages].each do |msg|
      @messages << {
        :subject => msg[:subject],
        :author => msg[:author],
        :link => normalizeMessageLink(msg[:link]),
        :id => msg[:id],
        :date => msg[:date],
        :summary => msg[:summary]
      }
    end

    shouldNotify = @account.enabled? && @messages.size > 0
    if shouldNotify
      newestDate = @messages.map { |m| m[:date] }.sort[-1]

      if @newestDate
        shouldNotify = newestDate > @newestDate
      end

      @newestDate = newestDate
    end
    notifyMenuUpdate

    if shouldNotify && @account.growl
      info = @messages.map { |m| "#{m[:subject]}\nFrom: #{m[:author]}" }.join("\n#{'-' * 30}\n\n")
      if @messageCount > @messages.size
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
    @checkedAt ? @checkedAt.strftime("%H:%M") : "NA"
  end

  def notifyMenuUpdate
    NSNotificationCenter.defaultCenter.postNotificationName(GNAccountMenuUpdateNotification, object:self, userInfo:{:guid => @account.guid, :checkedAt => checkedAt})
  end

  def notify(title, desc)
    GrowlApplicationBridge.notifyWithTitle(title,
      description: desc,
      notificationName: "new_messages",
      iconData: nil,
      priority: 0,
      isSticky: false,
      clickContext: title)
  end

  def cleanup
    @timer.invalidate if @timer
  end

  def cleanupAndQuit
    cleanup
    NSNotificationCenter.defaultCenter.removeObserver(self, name:GNCheckedAccountNotification, object:nil)
    @timer = nil
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

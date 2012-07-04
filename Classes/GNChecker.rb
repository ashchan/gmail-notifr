#
#  GNChecker.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/27/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

class GNChecker
  def init
    super
  end

  def initWithAccount(account)
    init
    @account = account
    @guid = account.guid
    @messages = []
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
    NSNotificationCenter.defaultCenter.postNotificationName(GNCheckingAccountNotification, object:self, userInfo:{:guid => @account.guid})

    if @account && @account.enabled?
      @timer = NSTimer.scheduledTimerWithTimeInterval(@account.interval * 60, target:self, selector:'checkMail', userInfo:nil, repeats:true)
      Dispatch::Queue.concurrent.async do
        check!
      end
    else
      notifyMenuUpdate
    end
  end

  def check!
    http = Net::HTTP.new("mail.google.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = nil
    result = { :error => "ConnectionError", :count => 0, :messages => [] }

    begin
      http.start do |http|
        req = Net::HTTP::Get.new("/mail/feed/atom")
        req.basic_auth(@account.username, @account.password)
        response = http.request(req)
      end

      if response
        case response.code
        when "401" #HTTPUnauthorized
          result[:error] = "UserError"
        when "200" #HTTPOK
          # oops, response.body should be utf-8
          xml = response.body.force_encoding("UTF-8")
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
      end
    rescue => e
      puts "error: #{e}"
    rescue Timeout::Error => e
      #puts "time out on connection"
    end

    Dispatch::Queue.main.async do
      processResult(result)
    end
  end

  def checkMail
    reset
  end

  def processResult(result)
    @checkedAt = Time.now

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
    NSNotificationCenter.defaultCenter.postNotificationName(GNAccountMenuUpdateNotification, object:nil, userInfo:{:guid => @account.guid, :checkedAt => checkedAt})
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
    if @account.customurl.length > 0
      link = @account.customurl + link.split("/mail")[2]
    end
    link
  end
end

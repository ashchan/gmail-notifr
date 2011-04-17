#
#  GNChecker.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/27/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#
framework 'Growl'
require 'net/https'
require 'rexml/document'
require 'time'

class GNCheckOperation < NSOperation
  def initWithUsername(username, password:password, guid:guid)
    init
    @username = username
    @password = password
    @guid = guid
    self
  end

  def main
    http = Net::HTTP.new("mail.google.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    response = nil
    result = { :error => "ConnectionError", :count => 0, :messages => [] }

    begin
      http.start do |http|
        req = Net::HTTP::Get.new("/mail/feed/atom")
        req.basic_auth(@username, @password)
        response = http.request(req)
      end

      if response
        case response.code
        when "401" #HTTPUnauthorized
          result[:error] = "UserError"
        when "200" #HTTPOK
          feed = REXML::Document.new response.body
          # messages count
          result[:count] = feed.get_elements('/feed/fullcount')[0].text.to_i
          result[:error] = "No"

          cnt = 0
          feed.each_element('/feed/entry') do |msg|
            cnt += 1
            # only return first 10 messages
            break if cnt > 10

            #contributor = msg.get_elements('contributor')[0]
            #author = if contributor
            #  contributor.get_elements('name')[0].text
            #else
            #  msg.get_elements('author/name')[0].text
            #end

            # gmail atom gives time string like 2009-08-29T24:56:52Z
            # note 24 causes ArgumentError: argument out of range
            # make it 23 and hope it won't matter too much
            issued = msg.get_elements('issued')[0].text
            issued.gsub!(/T24/, 'T23')
            date = Time.parse(issued) 

            result[:messages] << {
              :link => msg.get_elements('link')[0].attributes['href'],
              :author => msg.get_elements('author/name')[0].text,
              :subject => msg.get_elements('title')[0].text,
              :id => msg.get_elements('id')[0].text,
              :date => date,
              :summary => msg.get_elements('summary')[0].text
            }
          end
        end
      end
    rescue REXML::ParseException => e
      #puts "error parsing feed: #{e.message}"
    rescue => e
      #puts "error: #{e}"
    rescue Timeout::Error => e
      #puts "time out on connection"
    end

    NSNotificationCenter.defaultCenter.postNotificationName(GNCheckedAccountNotification,
      object:self,
      userInfo:{:guid => @guid, :results => result}
    )
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

      NSNotificationCenter.defaultCenter.addObserver(self, selector:'checkResults:', name:GNCheckedAccountNotification, object:nil)
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

    @checkedAt = DateTime.now
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
    NSNotificationCenter.defaultCenter.removeObserver(self, name:GNCheckedAccountNotification, object:nil)
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

    link
  end
end

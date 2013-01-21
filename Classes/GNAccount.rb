#
#  GNAccount.rb
#  Gmail Notifr
#
#  Created by James Chan on 1/3/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

# a normal gmail account, or a google hosted email account

class GNAccount

  attr_accessor :guid, :username, :password, :interval, :enabled, :sound, :growl, :browser
  Properties = [:guid, :username, :interval, :enabled, :sound, :growl, :browser]

  MIN_INTERVAL    = 1
  MAX_INTERVAL    = 900
  DEFAULT_INTERVAL  = 30

  def fetch_pass
    keychain_item = MRKeychain::GenericItem.item_for_service(KeychainService, username:@username)
    self.password = keychain_item ? keychain_item.password : ""
  end

  def initWithNameIntervalEnabledGrowlSound(username, interval, enabled, growl, sound, browser = GNBrowser::DEFAULT)

    self.username = username
    self.interval = interval || DEFAULT_INTERVAL
    self.enabled = enabled
    self.growl = growl
    self.sound = sound || GNSound::SOUND_NONE
    self.browser = browser || GNBrowser::DEFAULT

    fetch_pass

    self
  end

  def initWithCoder(coder)
    Properties.each do |prop|
      val = coder.decodeObjectForKey(prop)
      self.send("#{prop.to_s}=", val)
    end

    fetch_pass

    self
  end

  def self.accountByName(name)
    GNPreferences.sharedInstance.accounts.find { |a| a.username == name }
  end

  def self.accountByMessageLink(link)
    params = link.split("?")[1].split("&").map { |p| p.split("=") }
    mail = params.find { |p| p.first == "account_id" }[1]
    GNPreferences.sharedInstance.accounts.find do |a|
      [mail, mail.split("@").first].include?(a.username)
    end
  end

  def self.baseurl_for(name)
    account_name = name.include?("@") ? name : name + "@gmail.com"
    url = "https://mail.google.com/mail/b/#{account_name}"
  end

  def baseurl
    self.class.baseurl_for(username)
  end

  def encodeWithCoder(coder)
    Properties.each do |prop|
      val = self.send(prop)
      coder.encodeObject(val, forKey:prop)
    end
  end

  def description
    "<#{self.class}: #{username}(#{guid}), enabled? : #{enabled?}\ninterval: #{interval}, sound: #{sound}, growl: #{growl}, browser: #{browser}>"
  end

  alias inspect to_s
  alias enabled? enabled

  def enabled=(val)
    @enabled = val
    @enabled = false if val == 0
  end

  def interval=(val)
    @interval = val.to_i
    @interval = DEFAULT_INTERVAL unless @interval.between?(MIN_INTERVAL, MAX_INTERVAL)
  end

  def growl=(val)
    @growl = val
    @growl = false if val == 0
  end

  def username=(new_username)
    @old_username ||= @username
    @username = new_username
  end

  def password=(new_password)
    @old_password ||= @password
    @password = new_password
  end

  def username_changed?
    @old_username && @old_username != @username
  end

  def password_changed?
    @old_password && @old_password != @password
  end

  def changed?
    username_changed? || password_changed? #todo
  end

  def new?
    @guid.nil?
  end

  def gen_guid
    self.guid = `uuidgen`.strip
  end

  def save
    if new?
      gen_guid
      GNPreferences.sharedInstance.addAccount(self)
    else
      GNPreferences.sharedInstance.saveAccount(self)
    end
  end
end

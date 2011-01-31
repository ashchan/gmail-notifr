#
#  GNAccount.rb
#  Gmail Notifr
#
#  Created by James Chan on 1/3/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#

# a normal gmail account, or a google hosted email account

class GNAccount

  attr_accessor :guid, :username, :password, :interval, :enabled, :sound, :growl
  Properties = [:guid, :username, :interval, :enabled, :sound, :growl]

  MIN_INTERVAL    = 1
  MAX_INTERVAL    = 900
  DEFAULT_INTERVAL  = 30

  def fetch_pass
    keychain_item = MRKeychain::GenericItem.item_for_service(KeychainService, username:@username)
    self.password = keychain_item ? keychain_item.password : ""
  end

  def initWithNameIntervalEnabledGrowlSound(username, interval, enabled, growl, sound)

    self.username = username
    self.interval = interval || DEFAULT_INTERVAL
    self.enabled = enabled
    self.growl = growl
    self.sound = sound || GNSound::SOUND_NONE

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

  def self.baseurl_for(name)
    account_domain = name.split("@")
    url = (account_domain.length == 2 && !["gmail.com", "googlemail.com"].include?(account_domain[1])) ?
      "https://mail.google.com/a/#{account_domain[1]}/" : "https://mail.google.com/mail"
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
    "<#{self.class}: #{username}(#{guid}), enabled? : #{enabled?}\ninterval: #{interval}, sound: #{sound}, growl: #{growl}>"
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

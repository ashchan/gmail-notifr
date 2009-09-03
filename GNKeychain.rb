#
#  GNKeychain.rb
#  Gmail Notifr
#
#  Created by james on 10/4/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'
OSX.require_framework 'Security'

class GNKeychain < OSX::NSObject
  include OSX 
  SERVICE = "GmailNotifr"
  
    
  def self.sharedInstance
    @instance ||= self.alloc.init
  end
  
  def set_account(username, password)
    return if username.nil? || password.nil?
    pass = "#{password}"
    error = SecKeychainAddGenericPassword(
      nil,
      SERVICE.length,
      SERVICE,
      username.length,
      username,
      pass.length,
      pass,
      nil)
      
    #already set
    if error == OSX::ErrSecDuplicateItem
      status, *data = SecKeychainFindGenericPassword(
        nil,
        SERVICE.length,
        SERVICE,
        username.length,
        username)
      data.shift
      data.shift
      item = data.shift #SecKeychainItemRef
      SecKeychainItemModifyContent(item, nil, pass.length, pass)
    end
  end
  
  def delete_account(username)
    return if username.nil?
    status, *data = SecKeychainFindGenericPassword(
      nil,
      SERVICE.length,
      SERVICE,
      username.length,
      username)
    if status == 0
      data.shift
      data.shift
      item = data.shift
      SecKeychainItemDelete(item)
    end
  end
  
  def get_password(username)
    return "" if username.nil?
    status, *data = SecKeychainFindGenericPassword(
      nil,
      SERVICE.length,
      SERVICE,
      username.length,
      username)
    if status == 0
      password_length = data.shift
      password_data = data.shift
      password = password_data.bytestr(password_length)
    else
      ""
    end
  end
end

#
#  GNKeychain.rb
#  Gmail Notifr
#
#  Created by james on 10/4/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

framework 'Security'

class GNKeychain
  SERVICE = "GmailNotifr"
  
    
  def self.sharedInstance
    @instance ||= self.new
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
    if error == ErrSecDuplicateItem
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
    password_length = Pointer.new('I')
    password_data = Pointer.new('^v')
    item_ref = Pointer.new('^{OpaqueSecKeychainItemRef}')
    status = SecKeychainFindGenericPassword(
      nil,
      SERVICE.length,
      SERVICE,
      username.length,
      username,
      password_length,
      password_data,
      item_ref)
    if status == 0
      p = ""
      password_length[0].times do |i|
        p << password_data[0][i]
      end
      p
    else
      ""
    end
  end
end

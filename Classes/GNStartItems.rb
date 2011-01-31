#
#  GMStartItems.rb
#  Gmail Notifr
#
#  Created by james on 10/5/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

class GNStartItems

  def isSet
    cf = CFPreferencesCopyValue(
      "AutoLaunchedApplicationDictionary",
      "loginwindow",
      KCFPreferencesCurrentUser,
      KCFPreferencesAnyHost
    )

    return false unless cf

    cf.any? { |app| path == app["Path"] }
  end

  def set(autoLaunch)
    if autoLaunch != isSet
      cf = CFPreferencesCopyValue(
        "AutoLaunchedApplicationDictionary",
        "loginwindow",
        KCFPreferencesCurrentUser,
        KCFPreferencesAnyHost
      )

      if cf
        cf = cf.mutableCopy
      else
        cf = NSMutableArray.alloc.init
      end

      if autoLaunch
        #add
        #cf << { "Path" => path }
        cf.addObject(NSDictionary.dictionaryWithObject(path, forKey:"Path"))
      else
        #remove
        to_remove = nil
        cf.each do |app|
          to_remove = app and break if app.valueForKey("Path") == path
        end
        cf.removeObject(to_remove) if to_remove
      end

      CFPreferencesSetValue(
        "AutoLaunchedApplicationDictionary",
        cf,
        "loginwindow",
        KCFPreferencesCurrentUser,
        KCFPreferencesAnyHost
      )

      CFPreferencesSynchronize(
        "loginwindow",
        KCFPreferencesCurrentUser,
        KCFPreferencesAnyHost
      )
    end
  end

  def path
    @path ||= NSBundle.mainBundle.bundlePath
  end
end

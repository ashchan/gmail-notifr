#
#  GMStartItems.rb
#  Gmail Notifr
#
#  Created by james on 10/5/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

class GNStartItems

  def isSet
    # isInLoginItems returns BOOL but apparently Ruby doesn't cast
    # that to an internal boolean, so do it manually.
    return NSApp.isInLoginItems == 1 ? true : false
  end

  def set(autoLaunch)
    if autoLaunch != isSet
      if autoLaunch
        #add
        NSApp.addToLoginItems
      else
        #remove
        NSApp.removeFromLoginItems
      end
    end
  end
end

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
    NSApp.isInLoginItems == 1
  end

  def set(autoLaunch)
    if autoLaunch != isSet
      if autoLaunch
        NSApp.addToLoginItems
      else
        NSApp.removeFromLoginItems
      end
    end
  end
end

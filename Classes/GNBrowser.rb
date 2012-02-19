#
#  GNBrowser.rb
#  Gmail Notifr
#
#  Created by James Chen on 2/19/12.
#  Copyright 2012 ashchan.com. All rights reserved.
#

class GNBrowser
  DEFAULT = "default"

  class << self
    def all
      [
        ["Default", DEFAULT],
        ["Safari", "com.apple.Safari"],
        ["Google Chrome", "com.google.Chrome"],
        ["Firefox", "org.mozilla.firefox"]
      ]
    end

    def default?(identifier)
      all.first.include?(identifier)
    end

    def getName(identifier)
      identifier ||= DEFAULT
      all.find { |b| b[1] == identifier }.first
    end

    def getIdentifier(name)
      all.find { |b| b.first == name }[1]
    end
  end
end

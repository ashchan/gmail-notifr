#
# rb_main.rb
# Gmail Notifr
#
# Created by James Chen on 10/24/10.
# Copyright ashchan.com 2010. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'
framework 'Growl'
require 'time'
require 'net/https'

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

# try to load Security bs file on SnowLeopard
if NSAppKitVersionNumber < 1138 # Lion 10.7 is 1138
  load_bridge_support_file "#{dir_path}/BridgeSupport/Security.bridgesupport"
end

Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

def NSLocalizedString(key)
  NSBundle.mainBundle.localizedStringForKey(key, value:'', table:nil)
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)

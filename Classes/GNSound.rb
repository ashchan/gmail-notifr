#
#  Sound.rb
#  Gmail Notifr
#
#  Created by James Chen on 8/19/09.
#  Copyright (c) 2009 ashchan.com. All rights reserved.
#


class GNSound

  SOUND_NONE = "None" #NSLocalizedString("Sound None")
  
  @@soundList = []
  
  class << self
    
    def all
      return @@soundList if @@soundList.size > 0      
          
      @@soundList.clear

      knownSoundTypes = NSSound.soundUnfilteredFileTypes
      libs = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory,
        NSUserDomainMask | NSLocalDomainMask | NSSystemDomainMask,
        true
      )
      
      fileManager = NSFileManager.defaultManager
      
      libs.each do |folder|
        folder_name = File.join(folder, "Sounds")
        if fileManager.fileExistsAtPath_isDirectory(folder_name, nil)
          fileManager.directoryContentsAtPath(folder_name).each do |file|
            if knownSoundTypes.include?(file.pathExtension)           
              @@soundList << file.stringByDeletingPathExtension
            end
          end
        end
      end

      @@soundList.sort!
    end
  end

end

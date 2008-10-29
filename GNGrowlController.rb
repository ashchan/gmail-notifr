#
#  GNGrowlController.rb
#  Gmail Notifr
#
#  Created by James Chan on 10/29/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'osx/cocoa'

class GNGrowlController < OSX::NSObject
	def init
		if super_init
			@g = Growl::Notifier.sharedInstance
			@g.delegate = self
			@g.register('Gmail Notifr', ['new_messages'])
			self
		end
	end

	def growlNotifierClicked_context(sender, context)
	end

	def growlNotifierTimedOut_context(sender, context)
	end
	
	def notify(title, desc)
		@g.notify('new_messages', title, desc)
	end
end

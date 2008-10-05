#
#  GNGmailChecker.rb
#  Gmail Notifr
#
#  Created by james on 10/5/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

require 'net/https'
require 'rexml/document'

class GNGmailChecker
	def initialize(username, password)
		@username = username
		@password = password
	end
	
	def	new_mail_count
		http = Net::HTTP.new("mail.google.com", 443)
		http.use_ssl = true
		response = nil
		count = 0

		begin
		  http.start do |http|
			req = Net::HTTP::Get.new("/mail/feed/atom")
			req.basic_auth(@username, @password)
			response = http.request(req)
		  end

		  if response
			case response.code
				when "401" #HTTPUnauthorized
					count = "E"
				when "200" #HTTPOK				
					feed = REXML::Document.new response.body
					count = feed.get_elements('/feed/fullcount')[0].text
				else
					count = "F"
			end
		  else
			#don't get response
		  end
		rescue REXML::ParseException => e
		  puts "error parsing feed: #{e.message}"
		rescue => e
		  puts "error: #{e.to_s}"
		end
		
		count
	end
end

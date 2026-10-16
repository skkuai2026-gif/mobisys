require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadActivityListModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			lead = self.parentBaseDO
			leadActivityList = []
			if lead.LeadActivityList.size == 0
				leadActivity = LeadActivity.new
				leadActivityList.push(leadActivity)
			else
				leadActivityList = lead.LeadActivityList
			end

			return leadActivityList
		end

		def setModel(entity)
			if entity and entity.size > 0
				entity.each do |activity|
					if activity.removed.to_s == "YES"
						if System::get_property('platform') == 'APPLE' || System::get_property('platform') == 'ANDROID'
							# begin 
							# 	if activity.calendarId.to_s != ""
							# 		MobiSys::Calendar.delete(activity.calendarId)
							# 	end
							# rescue MobiSys::CalendarAccessError => error 
							# 	puts "Calendar Access Not Available"
							# end
						end
					end
				end
			end
		end
	end
	
end

begin 
    require 'Lead/LeadActivityListModel_company'
rescue LoadError => e
    puts 'LeadActivityListModel_company not included'
end
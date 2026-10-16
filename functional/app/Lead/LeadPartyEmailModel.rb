require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyEmailModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyEmail = self.parentBaseDO.getPartyEmail(true)
            
            return partyEmail
		end
	end
	
end

begin 
    require 'Lead/LeadPartyEmailModel_company'
rescue LoadError => e
    puts 'LeadPartyEmailModel_company not included'
end
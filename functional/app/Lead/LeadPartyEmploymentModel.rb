require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyEmploymentModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyEmployment = self.parentBaseDO.getPartyEmployment(true)
            
            return partyEmployment
		end
	end
	
end

begin 
    require 'Lead/LeadPartyEmploymentModel_company'
rescue LoadError => e
    puts 'LeadPartyEmploymentModel_company not included'
end
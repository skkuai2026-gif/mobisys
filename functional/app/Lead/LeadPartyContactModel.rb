require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyContactModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
            partyContact = self.parentBaseDO.getPartyContact(self.contactTypeCd,true)
            
            return partyContact
		end
	end
	
end

begin 
    require 'Lead/LeadPartyContactModel_company'
rescue LoadError => e
    puts 'LeadPartyContactModel_company not included'
end
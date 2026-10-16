require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyAdditionalFieldsListModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			
            return self.parentBaseDO.PartyAdditionalFieldsList
		end
	end
	
end

begin 
    require 'Lead/LeadPartyAdditionalFieldsListModel_company'
rescue LoadError => e
    puts 'LeadPartyAdditionalFieldsListModel_company not included'
end
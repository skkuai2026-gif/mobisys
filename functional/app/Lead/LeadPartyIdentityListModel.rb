require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyIdentityListModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyIdentityList = []
            if self.parentBaseDO.PartyIdentityList.size == 0
                partyIdentity = PartyIdentity.new
                partyIdentityList.push(partyIdentity)
            else
                partyIdentityList = self.parentBaseDO.PartyIdentityList
            end
      
            return partyIdentityList
		end
	end
	
end

begin 
    require 'Lead/LeadPartyIdentityListModel_company'
rescue LoadError => e
    puts 'LeadPartyIdentityListModel_company not included'
end
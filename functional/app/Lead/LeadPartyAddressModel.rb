require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyAddressModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyAddress = self.parentBaseDO.getPartyAddress(self.addressType,true)

			return partyAddress
		end
	end
	
end

begin 
    require 'Lead/LeadPartyAddressModel_company'
rescue LoadError => e
    puts 'LeadPartyAddressModel_company not included'
end
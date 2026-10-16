require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyAddressModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyAddress = self.parentBaseDO.getPartyAddress(self.addressType,true)

			return partyAddress
		end

		def setModel(entity)
            if entity != nil
                if MobiSys::PolicyBO.checkForEmptyFields(entity)
                    entity.removed = "YES"
                end
            end

            return entity
        end
	end
	
end

begin 
    require 'Lead/LeadPartyAddressModel_company'
rescue LoadError => e
    puts 'LeadPartyAddressModel_company not included'
end
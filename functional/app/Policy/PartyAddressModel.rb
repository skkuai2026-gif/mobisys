require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyAddressModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyAddressModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyAddressModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            
            return self.parentBaseDO.getPartyAddress(self.addressType, self.createNewObject)
        end

        def setModel(entity)
            if entity != nil
                if MobiSys::PolicyBO.checkForEmptyFields(entity)
                    entity.removed = "YES"
                elsif self.parentBaseDO.roleCd == "PROPOSER" && self.parentBaseDO.partyTypeCd == "ORGANIZATION" && (entity.addressTypeCd == "RESIDENTIAL" || entity.addressTypeCd == "PERMANENT")
                    entity.removed = "YES"
                elsif (self.parentBaseDO.copyFromAddr2.to_s != "" && entity.addressTypeCd.to_s == "PERMANENT") || (self.parentBaseDO.copyFromAddr3.to_s != "" && entity.addressTypeCd.to_s == "OFFICE") 
                    entity.removed = "YES"
                end
            end
 
            return entity
        end
    end
end

begin 
    require 'Policy/PartyAddressModel_company'
rescue LoadError => e
    puts 'PartyAddressModel_company not included'
end
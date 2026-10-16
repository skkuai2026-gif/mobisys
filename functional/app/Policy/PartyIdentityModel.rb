require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyIdentityModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyIdentityModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyIdentityModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyIdentity = nil
            partyIdentity = self.parentBaseDO.getPartyIdentity(self.identityTypeCd)

            if partyIdentity == nil && self.createNewObject
                partyIdentity = PartyIdentity.new(:identityTypeCd => self.identityTypeCd.to_s)
                self.parentBaseDO.addPartyIdentity(partyIdentity)
            end
            
            return partyIdentity
        end

        def setModel(entity)
            # if entity
            #     if MobiSys::PolicyBO.checkForEmptyFields(entity)
            #         entity.removed = "YES"
            #     end
            # end

            return entity
        end
    end
end

begin 
    require 'Policy/PartyIdentityModel_company'
rescue LoadError => e
    puts 'PartyIdentityModel_company not included'
end

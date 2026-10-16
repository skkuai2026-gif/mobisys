require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyContactModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyContactModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyContactModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyContact = nil
            partyContact = self.parentBaseDO.getPartyContact(self.contactTypeCd,self.createNewObject) if self.contactTypeCd.to_s != ""
            
            return partyContact
        end

        def setModel(entity)
            # entity.removed = "YES" if entity != nil && MobiSys::PolicyBO.checkForEmptyFields(entity)

            return entity
        end
    end
end

begin 
    require 'Policy/PartyContactModel_company'
rescue LoadError => e
    puts 'PartyContactModel_company not included'
end
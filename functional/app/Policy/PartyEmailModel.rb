require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyEmailModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyEmailModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyEmailModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyEmail = self.parentBaseDO.getPartyEmail(self.createNewObject)
            
            return partyEmail
        end

        def setModel(entity)
            entity.removed = "YES" if entity != nil && MobiSys::PolicyBO.checkForEmptyFields(entity)

            return entity
        end
    end
end

begin 
    require 'Policy/PartyEmailModel_company'
rescue LoadError => e
    puts 'PartyEmailModel_company not included'
end
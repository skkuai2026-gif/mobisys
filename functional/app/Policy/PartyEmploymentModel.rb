require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyEmploymentModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyEmploymentModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyEmploymentModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyEmployment = self.parentBaseDO.getPartyEmployment(self.createNewObject)
            
            return partyEmployment
        end

        def setModel(entity)
            if entity
                if MobiSys::PolicyBO.checkForEmptyFields(entity)
                    entity.removed = "YES"
                else
                    entity.annualIncome = entity.annualIncome.to_s.gsub(',', '').to_i unless entity.annualIncome.to_s.strip.empty?
                end
            end

            return entity
        end
    end
end

begin 
    require 'Policy/PartyEmploymentModel_company'
rescue LoadError => e
    puts 'PartyEmploymentModel_company not included'
end

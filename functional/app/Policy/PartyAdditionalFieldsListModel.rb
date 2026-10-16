require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyAdditionalFieldsListModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyAdditionalFiledsListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyAdditionalFiledsListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            additionalFieldsList = []
            additionalFields = self.parentBaseDO.getPartyAdditionalField(self.createNewObject)
            additionalFieldsList << additionalFields if additionalFields != nil
        
            return additionalFieldsList
        end
    end
end

begin 
    require 'Policy/PartyAdditionalFieldsListModel_company'
rescue LoadError => e
    puts 'PartyAdditionalFieldsListModel_company not included'
end

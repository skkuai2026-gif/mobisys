require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyAdditionalFieldsListModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyAdditionalFieldsListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyAdditionalFieldsListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            return self.parentBaseDO.PolicyAdditionalFiledsList
        end
    end
end

begin 
    require 'Policy/PolicyAdditionalFieldsListModel_company'
rescue LoadError => e
    puts 'PolicyAdditionalFieldsListModel_company not included'
end

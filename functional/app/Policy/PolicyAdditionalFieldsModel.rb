require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyAdditionalFieldsModel < BaseModel

        def initialize(io)
            # puts "~~~in PolicyAdditionalFieldsModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in PolicyAdditionalFieldsModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
            policyAdditionalField = nil
            policyAdditionalField = policy.getPolicyAddionalField(self.additionalTypeCd.to_s)
            if policyAdditionalField == nil && self.createNewObject
                policyAdditionalField = PolicyAdditionalFields.new;
                policyAdditionalField.additionalTypeCd = self.additionalTypeCd
                policy.addPolicyAdditionalFields(policyAdditionalField)
            end

            return policyAdditionalField
        end

        # def setModel(entity)
        #     return entity
        # end
    end
end

begin 
    require 'Policy/PolicyAdditionalFieldsModel_company'
rescue LoadError => e
    puts 'PolicyAdditionalFieldsModel_company not included'
end

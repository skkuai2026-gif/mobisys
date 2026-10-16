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
            if policyAdditionalField && policyAdditionalField.additionalTypeCd.to_s != "000" && self.additionalTypeCd.to_s == "000"
                policyAdditionalField.additionalTypeCd = self.additionalTypeCd
            end
            if policyAdditionalField == nil && self.createNewObject
                policyAdditionalField = PolicyAdditionalFields.new;
                policyAdditionalField.additionalTypeCd = self.additionalTypeCd
                policy.addPolicyAdditionalFields(policyAdditionalField)
            end

            # Adding Transaction Reference No. for P.R. generation code
            if self.additionalTypeCd.to_s == "000" || self.additionalTypeCd.to_s == ""
                if policyAdditionalField && policyAdditionalField.field13.to_s == ""
                    number = 0
                    r = Random.new
                    number = r.rand(10000...99999)
                    @AgentRegdetails = AgentReg.forUserId($userId)
                    if @AgentRegdetails
                        currentAgentId = @AgentRegdetails.agentId
                    end
                    policyAdditionalField.field13 = currentAgentId + number.to_s
                end
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

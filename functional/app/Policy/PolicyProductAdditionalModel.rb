require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyProductAdditionalModel < BaseModel
        def initialize(io)
            # logInfo "~~~in PolicyProductAdditionalModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in PolicyProductAdditionalModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            policyProductDO = self.parentBaseDO
            qpad = nil
            if policyProductDO && policyProductDO.PolicyProductAdditionalList
                if policyProductDO.PolicyProductAdditionalList.size == 0
                    qpad = PolicyProductAdditional.new
                    qpad.parentKey = policyProductDO.object
                    policyProductDO.addPolicyProductAdditional(qpad)
                else
                    qpad = policyProductDO.PolicyProductAdditionalList[0]
                end
            end
			return qpad
		end

	end
	
end

begin 
    require 'Policy/PolicyProductAdditionalModel_company'
rescue LoadError => e
    puts 'PolicyProductAdditionalModel_company not included'
end
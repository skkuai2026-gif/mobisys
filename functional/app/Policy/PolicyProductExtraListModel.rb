require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyProductExtraListModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyProductExtraListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyProductExtraListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            # policyProductExtraList = MobiSys::PolicyBO.computeProductExtra(self.baseIO.baseDO, self.parentBaseDO) if self.createNewObject
            policyProductExtraList = []

            self.parentBaseDO.PolicyProductExtraList.each do |policyProductExtra|
                if policyProductExtra.extraTypeCd != 'PRDDISCOUNT'
                    # policyProductExtraList.add(policyProductExtra)
                end
            end

            return policyProductExtraList
		end
	end
end

begin 
    require 'Policy/PolicyProductExtraListModel_company'
rescue LoadError => e
    puts 'PolicyProductExtraListModel_company not included'
end
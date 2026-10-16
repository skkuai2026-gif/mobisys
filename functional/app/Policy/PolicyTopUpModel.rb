require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyTopUpModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyTopUpModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyTopUpModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policyTopup = nil

            self.parentBaseDO.PolicyTopUpList.each do |topUp|
                next unless topUp.topUpTypeCd.upcase == self.topUpTypeCd.upcase
                policyTopup = topUp 
            end

            if !policyTopup and self.createNewObject
                policyTopup = PolicyTopUp.new;
                policyTopup.topUpAmount = 0.0
                policyTopup.topUpTypeCd = self.topUpTypeCd
                self.parentBaseDO.addPolicyTopUp(policyTopup)
            end

            return policyTopup
        end
    end
end

begin 
    require 'Policy/PolicyTopUpModel_company'
rescue LoadError => e
    puts 'PolicyTopUpModel_company not included'
end

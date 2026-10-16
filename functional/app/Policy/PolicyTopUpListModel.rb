require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyTopUpListModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyTopUpListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PolicyTopUpListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policyTopup = nil

            self.parentBaseDO.PolicyTopUpList.each do |topUp|
                next unless topUp.topUpTypeCd.upcase == self.topUpTypeCd.upcase
                policyTopup = topUp 
            end

            return policyTopup
        end
    end
end

begin 
    require 'Policy/PolicyTopUpListModel_company'
rescue LoadError => e
    puts 'PolicyTopUpListModel_company not included'
end

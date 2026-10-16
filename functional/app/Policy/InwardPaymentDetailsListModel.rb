require 'CommonClasses/BaseModel'

module MobiSys
	
	class InwardPaymentDetailsListModel < BaseModel

        def initialize(io)
            #puts "~~~in InwardPaymentDetailsListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in InwardPaymentDetailsListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
           
            return self.parentBaseDO.InwardDetailsList
        end

        def setModel(entity)
            if entity and entity.size > 0
                inward = self.parentBaseDO
                inward.removed = "" if inward.status.to_s == "N" and inward.removed.to_s == "YES"
                inward.status = ""
                policyDO = self.baseIO.baseDO
                basePlanDO = policyDO.getBaseProduct

                entity.each do |inwardDetail|
                    inwardDetail.instrumentStatusCd = "PENDING" if inwardDetail && inwardDetail.instrumentStatusCd.to_s == "" && inwardDetail.paymentMethodCd.to_s == "IPG"
                    if(basePlanDO != nil && inwardDetail.currency.to_s == "")
                        inwardDetail.currency = basePlanDO.currencyCd
                    end
                end
                inward.addInwardDetailsList(entity)
                self.parentBaseDO.persistAll
            end

            return entity
        end
    end
end

begin 
    require 'Policy/InwardPaymentDetailsListModel_company'
rescue LoadError => e
    puts 'InwardPaymentDetailsListModel_company not included'
end

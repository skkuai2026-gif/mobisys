require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationProductAdditionalModel < BaseModel
        def initialize(io)
            # logInfo "~~~in QuotationProductAdditionalModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationProductAdditionalModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")

            quotatioProductDO = self.parentBaseDO
            qpad = nil
            if quotatioProductDO && quotatioProductDO.QuotationProductAdditionalList
                if quotatioProductDO.QuotationProductAdditionalList == nil or quotatioProductDO.QuotationProductAdditionalList.size == 0
                    qpad = QuotationProductAdditional.new
                    qpad.parentKey = quotatioProductDO.object
                    quotatioProductDO.addQuotationProductAdditional(qpad)
                else
                    qpad = quotatioProductDO.QuotationProductAdditionalList[0]
                end
            end
			return qpad
		end

	end
	
end

begin 
    require 'Quotation/QuotationProductAdditionalModel_company'
rescue LoadError => e
    puts 'QuotationProductAdditionalModel_company not included'
end
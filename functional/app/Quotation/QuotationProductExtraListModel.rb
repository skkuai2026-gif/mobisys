require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationProductExtraListModel < BaseModel
        def initialize(io)
            # logInfo "~~~in QuotationProductExtraListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationProductExtraListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            if self.createNewObject
                quotationProductExtraList = MobiSys::QuotationBO.computeProductExtra(self.baseIO.baseDO, self.parentBaseDO)
            end

			return self.parentBaseDO.QuotationProductExtraList
		end

        def setModel(quotationProductExtraList)
            if self.parentBaseDO.is_a?(QuotationProduct)
                quotationProduct = self.parentBaseDO
                quotationProductExtraList.each do |quotationProductExtra|
                    quotationProduct.addQuotationProductExtra(quotationProductExtra)
                end
            elsif self.parentBaseDO.is_a?(QuotationParty)
                quotationParty = self.parentBaseDO
                quotationProductExtraList.each do |quotationProductExtra|
                    quotationParty.quotationProductExtra = quotationProductExtraList
                end
            end
        end

	end
	
end

begin 
    require 'Quotation/QuotationProductExtraListModel_company'
rescue LoadError => e
    puts 'QuotationProductExtraListModel_company not included'
end
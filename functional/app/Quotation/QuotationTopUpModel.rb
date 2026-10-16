require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationTopUpModel < BaseModel

		def initialize(io)
      # logInfo "~~~in QuotationTopUpModel initialize: #{io.inspect}"
      super(io)
      # logInfo "~~~baseIO:#{self.baseIO}"
    end

		def getModel
			# logInfo("~~~baseIO in QuotationTopUpModel:#{self.baseIO.inspect}")
      # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
   		quotationTopUp = nil
   			
   		if self.topUpTypeCd == "REGULARTOPUP"
   			quotationTopUp = self.parentBaseDO.getRegularTopup
   		elsif self.topUpTypeCd == "INITIALINVESTMENT"
   			quotationTopUp = self.parentBaseDO.getInitialInvestment
   		end

      if quotationTopUp == nil and self.createNewObject
        quotationTopUp = QuotationTopUp.new;
        quotationTopUp.topUpTypeCd = self.topUpTypeCd
        self.parentBaseDO.addQuotationTopUp(quotationTopUp)
      end

      if quotationTopUp #and self.parentBaseDO.regularTopupFl == "YES"
          quotationTopUp.topupFrequencyVal = 1 if quotationTopUp.topupFrequencyVal.to_s == ""
          quotationTopUp.topUpPeriod = self.parentBaseDO.getBaseProduct.productTerm if quotationTopUp.topUpPeriod.to_s == ""
      end
			return quotationTopUp
		end

	end
  
end

begin 
    require 'Quotation/QuotationTopUpModel_company'
rescue LoadError => e
    puts 'QuotationTopUpModel_company not included'
end
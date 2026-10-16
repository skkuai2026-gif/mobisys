require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationTopUpListModel < BaseModel

		def initialize(io)
            # logInfo "~~~in QuotationTopUpListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationTopUpListModel:#{self.baseIO.inspect}")
      		# logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
      		quotationTopupList = self.parentBaseDO.getTopupByType(self.topUpTypeCd)
      		if quotationTopupList.size == 0
      			quotationTopup = QuotationTopUp.new(:topUpTypeCd => self.topUpTypeCd)
      			quotationTopupList << quotationTopup
      		end

			return quotationTopupList
		end

	end
	
end

begin 
    require 'Quotation/QuotationTopUpListModel_company'
rescue LoadError => e
    puts 'QuotationTopUpListModel_company not included'
end
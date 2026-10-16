require 'CommonClasses/BaseModel'

module MobiSys
	class QuotationAdditionalFieldsListModel < BaseModel

		def initialize(io)
            #logInfo "~~~in QuotationAdditionalFieldsListModel initialize: #{io.inspect}"
            super(io)
            #logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			quotationAddtnlFieldsList = []
			quotationAddtnlFieldsList.push(self.parentBaseDO.getQuotationAdditionalFieldsDO)

			return quotationAddtnlFieldsList
		end

	end

end

begin 
    require 'Quotation/QuotationAdditionalFieldsListModel_company'
rescue LoadError => e
    puts 'QuotationAdditionalFieldsListModel_company not included'
end
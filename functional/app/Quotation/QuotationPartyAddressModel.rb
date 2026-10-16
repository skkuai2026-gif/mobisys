require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationPartyAddressModel < BaseModel

        # attr_accessor :addressType
		def initialize(io)
            # logInfo "~~~in QuotationPartyAddressModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
            # logInfo("~~~self.roleCd:#{self.roleCd}")
            quotationParty = self.parentBaseDO
            return nil if quotationParty == nil
            quotepartyAddress = quotationParty.getAddress(self.addressType)
			if quotepartyAddress == nil
				quotepartyAddress = QuotationPartyAddress.new(:addressTypeCd => self.addressType)
            	self.parentBaseDO.addQuotationPartyAddress(quotepartyAddress)
            end
			logInfo("~~~baseIO in QuotationPartyAddressModel:#{self.baseIO.inspect}")
			return quotepartyAddress
		end

		def setModel(quotationPartyAddress)
			if quotationPartyAddress.to_s != ""
				quotationPartyAddress.addressTypeCd = self.addressType
			end
			return quotationPartyAddress
		end

	end
	
end

begin 
    require 'Quotation/QuotationPartyAddressModel_company'
rescue LoadError => e
    puts 'QuotationPartyAddressModel_company not included'
end
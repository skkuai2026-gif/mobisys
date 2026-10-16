require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationPartyModel < BaseModel

		def initialize(io)
            # logInfo "~~~in QuotationPartyModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationPartyModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
            # logInfo("~~~self.roleCd:#{self.roleCd}")
            quotationParty = self.parentBaseDO.getPartyByRole(self.roleCd)
			if quotationParty == nil and self.createNewObject
				quotationParty = QuotationParty.new(:roleCd => self.roleCd,:partyTypeCd => "INDIVIDUAL")
            	self.parentBaseDO.addQuotationParty(quotationParty)
            end
			return quotationParty
		end

		def setModel(entity)
			quotation = @baseIO.baseDO
			if self.roleCd.to_s == "PRIMARY"
				if (quotation.proposerLASame.to_s == "YES" || quotation.proposerLASame == "COPYFROMINSURED")
					policyHolder = MobiSys::QuotationBO.getPolicyHolder(quotation)
					entity.status = policyHolder.status
				else
					entity.status = ""
				end
			end

			return entity
		end

	end
	
end

begin 
    require 'Quotation/QuotationPartyModel_company'
rescue LoadError => e
    puts 'QuotationPartyModel_company not included'
end
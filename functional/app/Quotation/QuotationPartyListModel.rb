require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationPartyListModel < BaseModel

		def initialize(io)
            #logInfo "~~~in QuotationPartyListModel initialize: #{io.inspect}"
            super(io)
            #logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in QuotationPartyListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
			partyList = []

			if self.roleCd.to_s == "SUPPLEMENTARY"
				partyList = self.parentBaseDO.getPartyListByRoleCd(self.roleCd) if self.parentBaseDO.supplementaryLives.to_s == "YES"
			else
				partyList = self.parentBaseDO.getPartyListByRoleCd(self.roleCd)
			end

			return partyList
		end

	end
	
end

begin 
    require 'Quotation/QuotationPartyListModel_company'
rescue LoadError => e
    puts 'QuotationPartyListModel_company not included'
end
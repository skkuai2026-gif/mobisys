require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationWithdrawalListModel < BaseModel

		def initialize(io)
            # logInfo "~~~in QuotationWithdrawalListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationWithdrawalListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
            quotationWithdrawalList = []
            if self.parentBaseDO.QuotationWithdrawalList.size > 0
            	self.parentBaseDO.QuotationWithdrawalList.each do |withdrawal|
            		self.parentBaseDO.QuotationWithdrawalList.delete(withdrawal) if withdrawal.status.to_s == "N" and withdrawal.removed.to_s == "YES"
            	end
            end
            if self.parentBaseDO.QuotationWithdrawalList.size > 0
            	quotationWithdrawalList = self.parentBaseDO.QuotationWithdrawalList
            else
				quotationWithdrawal = QuotationWithdrawal.new
				quotationWithdrawalList = [quotationWithdrawal]
			end

			return quotationWithdrawalList
		end

        def setModel(entity)
            if entity
                #If withdrawalFl in quotation is set to NO, delete withdrawal list and set withdrawal related fields to nil
                quotation = self.parentBaseDO
                if quotation.withdrawalFl.to_s != "YES"
                    quotation.solverTypeCd = nil
                    quotation.withdrawalRateTypeCd = nil
                    quotation.payingYears = nil
                    entity.each{|withdrawal| withdrawal.removed = "YES" } if entity.size > 0
                end
            end
        end

	end
	
end

begin 
    require 'Quotation/QuotationWithdrawalListModel_company'
rescue LoadError => e
    puts 'QuotationWithdrawalListModel_company not included'
end
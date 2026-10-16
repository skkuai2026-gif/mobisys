require 'Quotation/QuotationWithdrawalListModel'
require 'CommonClasses/BaseModel'

module MobiSys
  
  class QuotationWithdrawalListModel_SUNPH < QuotationWithdrawalListModel

    def getModel
      quotationObj = self.parentBaseDO
      quotationWithdrawalList = []
      withdrawalList = []
      listQuotationWithdrawal = quotationObj.QuotationWithdrawalList
      if listQuotationWithdrawal.empty?
        puts "inside if listQuotationWithdrawal"
      else
          quotationWithdrawalList = self.parentBaseDO.QuotationWithdrawalList
          if !quotationWithdrawalList.empty?
            quotationWithdrawalList.each do |withdrawal|
              # if (withdrawal.policyYearFrom.to_s != '' && withdrawal.policyYearTo.to_s != '') || (withdrawal.policyYearFrom.to_s == '' && withdrawal.policyYearTo.to_s != '') || (withdrawal.policyYearFrom.to_s != '' && withdrawal.policyYearTo.to_s == '')
                withdrawalList << withdrawal
              #elsif withdrawal.policyYearFrom.to_i == withdrawal.policyYearTo.to_i
                #withdrawalList << withdrawal
              # end
            end
          end
      end
      return withdrawalList
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
        return entity
      end
    end


  end
end

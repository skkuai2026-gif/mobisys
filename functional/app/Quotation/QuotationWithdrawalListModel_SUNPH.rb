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
            else
                quotationWithdrawalList = self.parentBaseDO.QuotationWithdrawalList
                 quotationWithdrawalList.each do |withdrawal|
                  if withdrawal.policyYearFrom.to_s == '' || withdrawal.policyYearTo.to_s == '' || withdrawal.withdrawalAmount.to_s == ''
                     withdrawalList << withdrawal
                  elsif withdrawal.policyYearFrom.to_i == withdrawal.policyYearTo.to_i
                     withdrawalList << withdrawal
                  end
                end
            end
            return withdrawalList
    end
        
  end
  
end

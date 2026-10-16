require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class LeadPartyOtherIncomeListModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			partyOtherIncomeList = []
            if self.parentBaseDO.getPartyOtherIncomeList.size == 0
                partyOtherIncome = PartyOtherIncome.new
                partyOtherIncomeList << partyOtherIncome
            else
            	partyOtherIncomeList = self.parentBaseDO.getPartyOtherIncomeList
            end

            return partyOtherIncomeList
		end
	end
	
end

begin 
    require 'Lead/LeadPartyOtherIncomeListModel_company'
rescue LoadError => e
    puts 'LeadPartyOtherIncomeListModel_company not included'
end
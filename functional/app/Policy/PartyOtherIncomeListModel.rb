require 'CommonClasses/BaseModel'

module MobiSys
	
	class PartyOtherIncomeListModel < BaseModel

        def initialize(io)
            #puts "~~~in PartyOtherIncomeListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PartyOtherIncomeListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            partyOtherIncomeList = self.parentBaseDO.getPartyOtherIncomeList
            if(self.createNewObject && partyOtherIncomeList.size == 0)
                partyOtherIncome = PartyOtherIncome.new
                self.parentBaseDO.addPartyOtherIncome(partyOtherIncome)
                partyOtherIncomeList << partyOtherIncome
            end

            return partyOtherIncomeList
        end
    end
end

begin 
    require 'Policy/PartyOtherIncomeListModel_company'
rescue LoadError => e
    puts 'PartyOtherIncomeListModel_company not included'
end

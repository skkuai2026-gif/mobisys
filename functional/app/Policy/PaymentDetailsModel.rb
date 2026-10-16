require 'CommonClasses/BaseModel'

module MobiSys
	
	class PaymentDetailsModel < BaseModel

        def initialize(io)
            #puts "~~~in PaymentDetailsModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in PaymentDetailsModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = @baseIO.baseDO
            policyPayment = self.parentBaseDO
            party = policy.getPayerParty(self.paymentInstructionTypeCd)
            partyFinancialAccount = nil

            if party != nil and party.PartyFinancialAccountList.size > 0
                party.PartyFinancialAccountList.each do |partyFinAcc|
                    if(partyFinAcc.guid == policyPayment.partyFinAccRefGuid)
                        partyFinancialAccount = partyFinAcc
                        break
                    end
                end
            end

            if partyFinancialAccount == nil
                partyFinancialAccount = PartyFinancialAccount.new
            end

            metaDataCd = nil
            if policyPayment.paymentInstructionTypeCd.to_s == "RENEWALPREMIUM"
                metaDataCd = "RenewalPartyFinancialAccountDO.micrNum"
            elsif policyPayment.paymentInstructionTypeCd.to_s == "REFUND"
                metaDataCd = "RefundPartyFinancialAccountDO.micrNum"
            end
            if(metaDataCd != nil and MobiSys::BrowserHelper.renderField?(metaDataCd))
                partyFinancialAccount.isMicrApplicable = "YES"
            else
                partyFinancialAccount.isMicrApplicable = "NO"
            end

            return partyFinancialAccount
		end

        def setModel(entity)
            if entity
                policyPayment = self.parentBaseDO
                policy = @baseIO.baseDO
                payerParty = policy.getPayerParty(self.paymentInstructionTypeCd)

                #In case of remove party fin ref ,need to set id as null
                if(policyPayment.paymentInstructionTypeCd.to_s == "RENEWALPREMIUM" and @baseIO.respond_to?("additionalData") and @baseIO.additionalData != nil and @baseIO.additionalData.has_key?("ISPARTYFINANCIALREFCHANGE") and @baseIO.additionalData["@baseIO.additionalData"] != nil)
                    entity.id = nil
                end

                entity.status = ""
                policyPayment.partyFinAccRefGuid = entity.uniqueKey
                policyPayment.partyFinAccountSeq = entity.id
                payerParty.status = "" if payerParty != nil
                policyPayment.removed = "" if policyPayment.status.to_s == "N" and policyPayment.removed.to_s == "YES"
                policyPayment.status = ""
                payerParty.addPartyFinancialAccount(entity) if payerParty != nil
                entity.persistAll
            end

            return entity
        end

	end
end

begin 
    require 'Policy/PaymentDetailsModel_company'
rescue LoadError => e
    puts 'PaymentDetailsModel_company not included'
end
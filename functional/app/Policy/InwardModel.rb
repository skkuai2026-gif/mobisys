require 'CommonClasses/BaseModel'

module MobiSys
	
	class InwardModel < BaseModel

        def initialize(io)
            #puts "~~~in InwardModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in InwardModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
            inward = (policy.proposalNum.to_s != "" ? policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE") : nil)
            if inward == nil
                inward = Inward.new
                policy.addInward(inward)
            end

            if inward.InwardDetailsList.size == 0
                inwardDetails = InwardDetails.new
                basePlan = policy.getBaseProduct
                inwardDetails.inwardAmount = basePlan.modalPremium if basePlan != nil
                inwardDetails.status = ""
                inward.addInwardDetails(inwardDetails)
            end

            #if payer doesnt exist then proposer will be payer
            inward.payerTypeCd = "PROPOSER" if inward.payerTypeCd.to_s == ""
            inward.isMicrApplicable = (MobiSys::BrowserHelper.renderField?("InwardDetailsDO.micrNum") ? "YES" : "NO")

            return inward 
        end

        def setModel(entity)
            if entity
                policy = self.parentBaseDO
                party = policy.getPayerParty("INITIAL")
                policyPartyRole = policy.getPayerPartyRole("INITIAL")
                entity.payerPartyRefGuid = policyPartyRole.refGuid if policyPartyRole != nil
                entity.inwardTypeCd = 'NEWBUSINESSR'
                entity.inwardSubTypeCd = 'BASICPREMIUM'
                entity.inwardDt = Time.now
                entity.agentId = policy.baseAgentId

                if entity.InwardPolicyList.size == 0
                    inwardPolicy = InwardPolicy.new
                    inwardPolicy.policyNum =  policy.proposalNum if policy.proposalNum
                    inwardPolicy.acctTypeCd =  "APPLICATION_SUSPENSE"
                    entity.addInwardPolicy(inwardPolicy)
                end

                if entity.payerTypeCd.to_s == "SUPPLEMENTARY"
                    #If there is 1 supplementary, set that as payerPartyRefGuid
                    suppPartyList = policy.getPartyList("SUPPLEMENTARY")
                    entity.payerPartyRefGuid = suppPartyList.first.guid if suppPartyList.size == 1

                    if entity.payerPartyRefGuid.to_s != ""
                        #If Db Party has partySameAsCd as OTHER, remove from Db
                        party.removed = "YES" if party != nil and policyPartyRole != nil and policyPartyRole.partySameAsCd.to_s == "OTHER"
                        #Set same partyRefGuid in policyPartyRole
                        updatedParty = policy.getPartyByGuid(entity.payerPartyRefGuid)
                        if updatedParty
                            policyPartyRole.refGuid = updatedParty.guid
                            #policyPartyRole.partyId = updatedParty.partyId
                            entity.payerPartyRefGuid = updatedParty.guid
                            policyPartyRole.status = ""
                        end
                    end
                elsif entity.payerTypeCd.to_s != "OTHER"
                    #If Db Party has partySameAsCd as OTHER, remove from Db
                    party.removed = "YES" if party != nil and policyPartyRole != nil and (policyPartyRole.partySameAsCd.to_s == "" || policyPartyRole.partySameAsCd.to_s == "OTHER")
                    updatedParty = policy.getParty(entity.payerTypeCd)
                    if updatedParty != nil
                        if policyPartyRole != nil
                            policyPartyRole.refGuid = updatedParty.guid
                            policyPartyRole.status = ""
                        end
                        entity.payerPartyRefGuid = updatedParty.guid
                    end
                end
                if policyPartyRole != nil
                    policyPartyRole.partySameAsCd = entity.payerTypeCd
                    #If party changed to OTHER do not delete the party record
                    party.removed = "" if party != nil and party.removed.to_s == "YES" and entity.payerTypeCd.to_s == "OTHER"
                end

                entity.persistAll
            end

            return entity
        end

    end
end

begin 
    require 'Policy/InwardModel_company'
rescue LoadError => e
    puts 'InwardModel_company not included'
end

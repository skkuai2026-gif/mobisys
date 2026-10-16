require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyPartyModel < BaseModel

        def initialize(io)
            #puts "~~~in PolicyPartyModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            #logInfo("~~~baseIO in PolicyPartyModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
            policyParty = nil
            paymentInstructionTypeCd = (self.respond_to?("paymentInstructionTypeCd") ? self.paymentInstructionTypeCd : "")
            if paymentInstructionTypeCd.to_s != ""
                policyParty = self.parentBaseDO.getPayerParty(paymentInstructionTypeCd)
            else
                policyParty = self.parentBaseDO.getParty(self.roleCd)
            end

            if policyParty == nil
                policyParty = Party.new(:roleCd => self.roleCd, :partyTypeCd => "INDIVIDUAL")
                policyParty.paymentInstructionTypeCd = paymentInstructionTypeCd if paymentInstructionTypeCd.to_s != ""
                policy.addParty(policyParty)
            end
            policyPartyRole = policy.getPolicyPartyRoleByPartyGuid(policyParty.uniqueKey, self.roleCd, paymentInstructionTypeCd)

            #If the  self.roleCd is not the same as the current party's roleCd, it implies the party is SAMEAS another party 
            if policyParty.roleCd != self.roleCd
                #Create a new party to show on the UI. In case of PRIMARY create clone record and for OTHER ie. PAYER create new record.
                returnParty = nil
                if self.roleCd.to_s == "PRIMARY"
                    returnParty = policyParty.cloneObject
                    self.mergeAndAddFlag = false
                    if(policyPartyRole != nil and policyPartyRole.partySameAsCd.to_s != "")
                        returnParty.partySameAsCd = policyPartyRole.partySameAsCd
                    else
                        returnParty.partySameAsCd = policyParty.roleCd
                    end 
                else
                    returnParty = Party.new
                    returnParty.partySameAsCd = policyParty.roleCd
                end
                returnParty.roleCd = self.roleCd
                returnParty.status = ""
                returnParty.partyTypeCd = "INDIVIDUAL"
                policyParty = returnParty
            end

            if self.roleCd.to_s == "APPOINTEE"
                nomineeList = policy.getPartyList("NOMINEE")
                majorAgeFacet = $rhoconfig[:majorAge]
                minorFl = false
                if nomineeList.size > 0 and majorAgeFacet != nil
                    ageFacet = majorAgeFacet.actionValue
                    nomineeList.each do |nominee|
                        minorFl =  ((nominee.age.to_i < ageFacet.to_i) ? true : false ) if(nominee.age.to_s != "" and ageFacet != nil)
                        break if minorFl
                    end
                end
                unless minorFl
                    if policyPartyRole != nil
                        policyParty.removed = "YES"
                        policyPartyRole.removed = "YES"
                    else
                        policy.removeParty(policyParty)
                        policyParty = nil
                    end
                end
            end

            if(policyParty != nil and policyPartyRole != nil)
                policyParty.paymentInstructionTypeCd = policyPartyRole.paymentInstructionTypeCd
                policyParty.policyPartyRoleGuid = policyPartyRole.guid
            end

            return policyParty
        end

        def setModel(entity)
            if entity
                policy = self.parentBaseDO
                entity.partyTypeCd = "INDIVIDUAL" if entity.partyTypeCd.to_s == ""
                policyPartyRole = nil
                policyPartyRole = policy.getPolicyPartyRoleByGuid(entity.policyPartyRoleGuid) if entity.policyPartyRoleGuid.to_s != ""

                if policyPartyRole == nil
                    policyPartyRole = PolicyPartyRole.new(:roleCd => self.roleCd)
                    policy.addPolicyPartyRole(policyPartyRole)
                end

                if policyPartyRole != nil
                    paymentInstructionTypeCd = (self.respond_to?("paymentInstructionTypeCd") ? self.paymentInstructionTypeCd : "")
                    policyPartyRole.refGuid = entity.uniqueKey
                    #partySameAs is set for PRIMARY. In case of PAYER, it set from payerTypeCd from the UI
                    policyPartyRole.partySameAsCd = entity.partySameAsCd if self.roleCd.to_s == "PRIMARY"
                    policyPartyRole.paymentInstructionTypeCd = paymentInstructionTypeCd       
                end
                if entity.partySameAsCd.to_s != ""
                    entity.removed = "YES"
                else
                    entity.status = ""
                end
            end

            return entity
        end

  end
end

begin 
    require 'Policy/PolicyPartyModel_company'
rescue LoadError => e
    puts 'PolicyPartyModel_company not included'
end
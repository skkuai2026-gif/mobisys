require 'CommonClasses/BaseModel'

module MobiSys
    
    class PolicyPartyListModel < BaseModel
        attr_accessor :autoPopulateSingleParty, :roleCd
        def initialize(io)
            #puts "~~~in PolicyPartyListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            #logInfo("~~~baseIO in PolicyPartyListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
            partyList = nil
            partyList = policy.getPartyList(self.roleCd)
            returnPartyList = []
            
            if((self.createNewObject && partyList == nil) || self.addEntity)
                newParty = Party.new(:roleCd => self.roleCd, :partyTypeCd => "INDIVIDUAL")
                # newParty.nomineeTypeCd = 'PRIMARY' if self.roleCd.to_s == "NOMINEE"
                policy.addParty(newParty)
                returnPartyList << newParty
            elsif(partyList != nil && partyList.size > 0)
                partyList.each do |party|
                    policyPartyRole = policy.getPolicyPartyRoleByPartyGuid(party.guid,self.roleCd)
                    sameAsPartyDO = policy.getPartyByRole(policyPartyRole.partySameAsCd) if policyPartyRole
                    #In case of SAMEAS, create a new empty Party so that UI will update if changed to OTHER party type scenario
                    if policyPartyRole != nil and policyPartyRole.partySameAsCd.to_s != "" and policyPartyRole.partySameAsCd.to_s != "OTHER" and sameAsPartyDO != nil
                        returnParty = Party.new
                        returnParty.partyTypeCd = "INDIVIDUAL"
                        returnParty.roleCd = self.roleCd
                        returnParty.status = ""
                        returnParty.guid = policyPartyRole.guid
                        party = returnParty
                    end
                    if self.roleCd.to_s == "NOMINEE" && policyPartyRole != nil
                        party.percentage = policyPartyRole.percentage.to_f
                        party.nomineeTypeCd = policyPartyRole.nomineeTypeCd
                        party.irrevocableFl = policyPartyRole.irrevocableFl
                        #Set date from db to UNIX format for response
                        if policyPartyRole.effectiveFromDt.to_s != ""
                            date = DateTime.parse(policyPartyRole.effectiveFromDt.to_s)      
                            effectiveFromDt = date.strftime('%Q').to_i
                            party.effectiveFromDt = effectiveFromDt
                        end
                        if policyPartyRole.effectiveToDt.to_s != ""
                            date = DateTime.parse(policyPartyRole.effectiveToDt.to_s)      
                            effectiveToDt = date.strftime('%Q').to_i
                            party.effectiveToDt = effectiveToDt
                        end
                        party.suppPartyGuid = policyPartyRole.refGuid if policyPartyRole.partySameAsCd.to_s == "SUPPLEMENTARY"
                    end
                    party.partySameAsCd = policyPartyRole.partySameAsCd if policyPartyRole != nil
                    party.policyPartyRoleGuid = policyPartyRole.guid if policyPartyRole != nil
                    party.eventTypeCd = policyPartyRole.eventTypeCd

                    returnPartyList << party
                end
            end
            
            if self.createNewObject && autoPopulateSingleParty.to_s != "" && autoPopulateSingleParty.to_s == "YES" && returnPartyList.empty?
                party = Party.new(:roleCd => roleCd, :partyTypeCd => "INDIVIDUAL")
                policy.addParty(party)
                policyPartyRole = PolicyPartyRole.new(:roleCd => roleCd, :refGuid => party.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRole)
                returnPartyList << party
            end

            if self.roleCd.to_s == "NOMINEE"
              partyRoleList = getPartyRoleListInPartySameAs()
              if partyRoleList.size > 0
                MobiSys::CommonUtil.addLookupData(@baseIO, "NOMINEEPARTYSAMEAS", partyRoleList)
              end
            end

            return returnPartyList
        end

        def setModel(entity)
            partyList = []
            if entity && entity.size > 0
                policy = self.parentBaseDO
                nomineeCount = entity.select{ |h| h.removed.to_s != "YES" }.size
                entity.each do |party|
                    policyPartyRole = nil
                    policyPartyRole = policy.getPolicyPartyRoleByGuid(party.policyPartyRoleGuid) if party.policyPartyRoleGuid.to_s != ""
                    #Delete partyrole if party has been deleted from UI
                    if party.partySameAsCd.to_s != "" and party.removed.to_s == "YES"
                        policyPartyRole.removed = "YES" if policyPartyRole
                    else
                        if policyPartyRole == nil
                            policyPartyRole = PolicyPartyRole.new
                            policyPartyRole.roleCd = self.roleCd
                            policy.addPolicyPartyRole(policyPartyRole)
                        end
                        policyPartyRole.refGuid = party.guid

                        if self.roleCd.to_s == "NOMINEE"
                            #If there is 1 nominee, set the percentage to 100
                            policyPartyRole.percentage = ((nomineeCount == 1 and party.percentage.to_s == "") ? 100 : party.percentage.to_f)
                            policyPartyRole.nomineeTypeCd = party.nomineeTypeCd
                            policyPartyRole.irrevocableFl = party.irrevocableFl
                            #Division by 100 required for date since it is in the UNIX format
                            policyPartyRole.effectiveFromDt = getScreenDate(party.effectiveFromDt/1000) if party.effectiveFromDt.to_s != ""
                            policyPartyRole.effectiveToDt = getScreenDate(party.effectiveToDt/1000) if party.effectiveToDt.to_s != ""
                            policyPartyRole.partySameAsCd = party.partySameAsCd
                            policyPartyRole.eventTypeCd = party.eventTypeCd
                        end
                        policyPartyRole.paymentInstructionTypeCd = party.paymentInstructionTypeCd if party.paymentInstructionTypeCd.to_s != ""

                        #In case of OTHER party, add in the partyList for update. Incase of SAMEAS, don't save the UI party in the db
                        if(party.partySameAsCd.to_s == "OTHER")
                            partyList.push(party)
                        elsif party.partySameAsCd.to_s != ""
                            sameAsParty = nil
                            sameAsParty = (policyPartyRole.partySameAsCd.to_s == "SUPPLEMENTARY" ? policy.getPartyByGuid(party.suppPartyGuid) : policy.getParty(party.partySameAsCd))
                            if sameAsParty != nil
                                policyPartyRole.refGuid = sameAsParty.guid
                                party.removed = "YES"
                            else #this scenario will arise if the party same as is not a pre defined role 
                                partyList.push(party)
                            end
                        else
                            party.removed = "YES"
                        end
                        policyPartyRole.removed = "YES" if party.status.to_s == "N"
                    end
                end
            end

            return partyList
        end

        def getPartyRoleListInPartySameAs
            partyRoleList = {}
            policy = self.parentBaseDO
            if policy
                partySameAsList = Lookupvalue.getValue("PARTYSAMEAS")
                insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
                if insuredPartyRole
                    proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
                else
                    proposerIsSameAsInsured = false
                end
                partySameAsList.each do |lkpData|
                    currRoleCd = lkpData.cd
                    currDesc = lkpData.desc
                    next if self.roleCd.to_s == currRoleCd
                    # Beneficiary cannot be same as that of the Primary insured.if Proposer,
                    # Primary are same then it cannot be Proposer as well.
                    next if (self.roleCd.to_s == "NOMINEE" && proposerIsSameAsInsured && (currRoleCd == "PROPOSER" || currRoleCd == "PRIMARY"))
                    if currRoleCd.to_s == "OTHER" && self.roleCd.to_s == "NOMINEE"
                        partyRoleList[currRoleCd] = currDesc
                    end
                    partyList = policy.getPartyList(currRoleCd)
                    if partyList.size > 0                        
                        partyRoleList[currRoleCd] = currDesc
                    end
                end
            end
            return partyRoleList
        end

  end
end

begin 
    require 'Policy/PolicyPartyListModel_company'
rescue LoadError => e
    puts 'PolicyPartyListModel_company not included'
end
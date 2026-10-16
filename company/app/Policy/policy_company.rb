# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Policy/policy_b_o'
require 'Product/product_b_o'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class Policy
    include MobiSys::MobiSysEntitySchema
    include BrowserHelper
    include MobiSys::BrowserHelper

    set :schema_version, '1.2'

    property :totModalPremium, :float

    attr_accessor :channelId
    attr_accessor :currentTab, :buttonClicked, :insuredSameAsProposer, :entityTypeCd, :isEditQuotation, :payingYears, :fnaSeq
      
    def getPartyAddressList
        listPartyAddressDO = []
        self.PartyList.each do |policyParty|
            policyParty.PartyAddressList.each do |partyAddressDO|
                listPartyAddressDO.push(partyAddressDO)
            end
        end
        return listPartyAddressDO
    end

    def getPolicyWithdrawalList
        policyWithdrawalList = []
        if self.policyWithdrawalList != nil
            policyWithdrawalList = self.policyWithdrawalList 
            return policyWithdrawalList
        end
    end

    def getBasePlan
        return getBaseProduct
    end

    def afterSync
        if self.policyResult != nil
            self.policyResult.each do |polResult|
                polResult.parentKey = self.guid
            end    
        end
        policyPortfolioModelCode = ""
        if $rhoconfig[:TABFEATUREREQD] 
            self.PolicyProductList.each do |policyProd|
                policyProd.selected = 'YES' if policyProd.builtInRiderFl != 'YES' && policyProd.productTypeCd == 'RIDER'
                if policyProd.productTypeCd.to_s == "PLAN"
                    policyPortfolioModelCode = policyProd.portfolioModelCd.to_s
                end
                if (self.quoteProposerSameAsInsured.to_s == "YES" || self.quoteProposerSameAsInsured.to_s == "COPYFROMINSURED") && (policyProd.partyRoleCd.to_s == "PRIMARY" || policyProd.partyRoleCd.to_s == "PROPCUMINS")
                    policyProd.partyRoleCd = "PRIMARY"
                    policyProd.PolicyProductInsuredList.each do|policyProdInsured|
                        if policyProdInsured.roleCd.to_s == "PROPCUMINS"
                           policyProdInsured.insuredSequenceTypeCd = "PRIMARY"
                           policyProdInsured.roleCd = "PRIMARY"
                        end
                    end
                end    
            end
        end
        if self.statusCd.to_s == "ACCEPTED" && self.signatureStatus.to_s == ""
           self.signatureStatus = "SUCCESS" 
        end    

        if !self.PolicyPaymentList.empty? 
            partyFinancialAccount = []
            self.PartyList.each do |party|
                partyFinnanAcc =  party.PartyFinancialAccountList
                partyFinnanAcc.each do |partyFinnAccount|
                    partyFinancialAccount << partyFinnAccount   if partyFinnAccount && partyFinnAccount.id.to_s != ""
                end
            end
            self.PolicyPaymentList.each do |policyPayment|
                partyFinancialAccount.each do |partyFinAcc|
                    policyPayment.partyFinAccRefGuid = partyFinAcc.guid  if partyFinAcc.id == policyPayment.partyFinAccountSeq
                end
            end
        end
        MobiSys::CommonUtil.addUserActivity('POLICYSYNCEDFROMONLINE',"quotationRefNum => #{self.quotationRefNum},proposalNum => #{self.proposalNum},policyGuid => #{self.guid},policyfnaId => #{self.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode}", 'POLICY', self.proposalNum)
        self.persistAll
    end

    def getServiceDocumentListForParty(guid)
        serviceDocument = []
        documentContainer = DocumentContainer.loadObject(:first, :conditions => {:entityGuid => guid.to_s}) 
        if documentContainer
            serviceDocument = documentContainer.ServiceDocumentList
        end
        return serviceDocument
    end

    def BasePlan
        baseProduct = nil
        self.PolicyProductList.each do |policyProduct|
            if policyProduct.productTypeCd == 'PLAN'
                baseProduct = policyProduct
                break
            elsif policyProduct.productTypeCd == "PA"
                baseProduct = policyProduct
                break
            end
        end
        return baseProduct
    end

    def getPolicyAdditionalFieldsDO
        policyAdditionalFieldsDO = nil
        if self.PolicyAdditionalFieldsList.size > 0
            policyAdditionalFieldsDO = self.PolicyAdditionalFieldsList[0]
        else
            policyAdditionalFieldsDO = PolicyAdditionalFields.new
            self.addPolicyAdditionalFields(policyAdditionalFieldsDO)
        end
        return policyAdditionalFieldsDO
    end

    def getRiderList
        riderList = []
        self.PolicyProductList.each do |policyProduct|
            riderList.push policyProduct if policyProduct.productTypeCd == "RIDER" && policyProduct.builtInRiderFl != "YES" && policyProduct.selected.to_s == "YES"
        end
        return riderList
    end

    def getPartyEmploymentList
        listPartyEmploymentDO = []
        self.PartyList.each do |policyParty|
            policyParty.PartyEmploymentList.each do |partyEmploymentDO|
                listPartyEmploymentDO.push(partyEmploymentDO)
            end
        end
        return listPartyEmploymentDO
    end    

    def contextExtendForClass
        # return "PolicyAdditionalFields"
        return nil
    end

    def getPartyList(roleCd=nil)
        returnPartyList = Array.new
        if roleCd
            self.PolicyPartyRoleList.each do |policyPartyRole|
                if policyPartyRole.roleCd == roleCd
                    self.PartyList.each do |party|
                        if party.guid == policyPartyRole.refGuid && party.parentKey == policyPartyRole.parentKey
                            returnPartyList.push(party)
                            break
                        end
                    end   
                end
            end
        else
            self.PartyList.each do |party|
                returnPartyList.push(party)
            end
        end
        return returnPartyList
    end

    def getPartyContactList
        partyContactList = []
        self.PartyList.each do |party|
            party.PartyContactList.each do |partyContact|
                partyContactList.push(partyContact)
            end
        end
        return partyContactList
    end

    def getPartyIdentityList
        partyIdentityList = []
        self.PartyList.each do |party|
            party.PartyIdentityList.each do |partyIdentity|
                partyIdentityList.push(partyIdentity)
            end
        end
        return partyIdentityList
    end

    def beforeSync
        self.quotationSeq = nil
    end

     def getBasePlanAdditionalDO
        policyProductAdditional = nil
        policyProduct = self.getBaseProduct
        policyProductAdditionalList = policyProduct.PolicyProductAdditionalList
        if policyProductAdditionalList && policyProductAdditionalList.size > 0
            policyProductAdditional = policyProductAdditionalList[0]
        else
            policyProductAdditional = PolicyProductAdditional.new
            policyProduct.addPolicyProductAdditional(policyProductAdditional)
        end
        return policyProductAdditional
    end

    def getPartyDOByGuid(refGuid)
        if refGuid.to_s != ""
            self.PartyList.each do |party|
                return party if refGuid.to_s == party.guid.to_s
            end
        end
        return nil
    end

    def getNomineePartyList
        returnPartyList = Array.new
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == 'NOMINEE'
                self.PartyList.each do |party|
                    if party.guid == policyPartyRole.refGuid && party.parentKey == policyPartyRole.parentKey && party.removed.to_s != "YES"
                        party.nomineeTypeCd = policyPartyRole.nomineeTypeCd
                        party.partySameAsCd = policyPartyRole.partySameAsCd
                        party.percentage = policyPartyRole.percentage.to_f
                        party.irrevocableFl = policyPartyRole.irrevocableFl
                        party.eventTypeCd = policyPartyRole.eventTypeCd
                        returnPartyList.push(party)
                        break
                    end
                end   
            end
        end 
        return returnPartyList
    end

    def getPartyNames(tabName="",roleCds='')
        partyNames = {}
        if roleCds == ''
            roleCdList = ['PRIMARY','PROPOSER','SUPPLEMENTARY','JOINT','PAYER']
        else
            roleCdList = roleCds.split(',')
        end
        insuredPartyRole = self.getPolicyPartyRole("PRIMARY")
        if insuredPartyRole
            proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
        else
            proposerIsSameAsInsured = false
        end
        payerPartyRole = self.getPolicyPartyRole("PAYER")
        if payerPartyRole
            payerIsSameAs = payerPartyRole.partySameAsCd
        end

        if tabName == "tab_questionnaire"
            product = MobiSys::ProductUtil.getProduct(self.baseProductSeq)
            productQuestFacet = product.getFacet('PRODUCTQUESTIONSETGROUP')
            proposerQuestFacet = product.getFacet('PROPOSERQUESTIONSETGROUP')
            payerQuestFacet = product.getFacet('PAYERQUESTIONSETGROUP')
            self.PartyList.each do |party|
                if party.roleCd.to_s == 'PROPOSER' && (productQuestFacet.to_s != "" || proposerQuestFacet.to_s != "" || (payerQuestFacet.to_s != "" && payerIsSameAs == party.roleCd.to_s)) 
                    if proposerIsSameAsInsured
                        if party.partyTypeCd == "ORGANIZATION"
                            displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s)
                        else
                            displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                        end
                        if payerIsSameAs == party.roleCd.to_s && payerQuestFacet.to_s != ""
                            partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}/#{getLabelValue('PAYER')}-#{displayName}"
                        else
                            partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}-#{displayName}"
                        end                        
                    else 
                        policyProductInsured = PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>party.guid})
                        if policyProductInsured || proposerQuestFacet || (payerQuestFacet && payerIsSameAs == 'PROPOSER')
                            if party.partyTypeCd == "ORGANIZATION"
                                displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s)
                            else
                                displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                            end
                            if payerIsSameAs == party.roleCd.to_s && payerQuestFacet.to_s != ""
                                partyNames[party.guid] = "#{getLabelValue(party.roleCd)}/#{getLabelValue('PAYER')}-#{displayName}"
                            else
                                partyNames[party.guid] = "#{getLabelValue(party.roleCd)}-#{displayName}"
                            end
                        end
                    end
                elsif party.roleCd.to_s == 'PAYER' && payerQuestFacet.to_s != ""
                    if party.partyTypeCd == "ORGANIZATION"
                        displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                    else  
                        displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                    end
                    partyNames[party.guid] = "#{getLabelValue(party.roleCd)}-#{displayName}"
                elsif productQuestFacet.to_s != "" || (payerQuestFacet.to_s != "" && payerIsSameAs == party.roleCd.to_s)
                    policyProductInsured = PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>party.guid})
                    next unless policyProductInsured
                    if roleCdList.include?(policyProductInsured.roleCd.to_s)
                        if party.roleCd.to_s == 'PRIMARY' && proposerIsSameAsInsured
                            if party.partyTypeCd == "ORGANIZATION"
                                displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                            else
                                displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                            end
                            if payerIsSameAs == party.roleCd.to_s && payerQuestFacet.to_s != ""
                                partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}/#{getLabelValue('PAYER')}-#{displayName}"
                            else
                                partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}-#{displayName}"
                            end
                        else
                            if party.partyTypeCd == "ORGANIZATION"
                                displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                            else
                                displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                            end 
                            if payerIsSameAs == party.roleCd.to_s && payerQuestFacet.to_s != ""
                                partyNames[party.guid] = "#{getLabelValue(party.roleCd)}/#{getLabelValue('PAYER')}-#{displayName}"
                            else
                                partyNames[party.guid] = "#{getLabelValue(party.roleCd)}-#{displayName}"
                            end
                        end
                    end
                end
            end
        else
            roleCollection = {}
            applicableRoles = ""
            roleCdListDocument = []
            for i in 0..20 do
                if i == 0
                   offlineFacet = $currentProduct.getFacet('NBREQUIRMENTS') 
                else
                    offlineFacet = $currentProduct.getFacet('NBREQUIRMENTS'+i.to_s) 
                end
                if offlineFacet 
                    if offlineFacet.applicableRoles.to_s != ""
                        roleCdListDocument.push(offlineFacet.applicableRoles.split(","))
                    else
                        roleCdListDocument = roleCdList
                    end
                end
            end
            roleCdList = roleCdListDocument.flatten.uniq 
            self.PolicyPartyRoleList.each do |policyPartyRole|
                if roleCdList.include?(policyPartyRole.roleCd.to_s)
                    if tabName.to_s == "tab_requirement"
                        if((policyPartyRole.roleCd.to_s == "PAYER" and policyPartyRole.partySameAsCd.to_s == "OTHER") || policyPartyRole.roleCd.to_s != "PAYER")
                            roleCollection[policyPartyRole.refGuid] = roleCollection[policyPartyRole.refGuid].to_s+"/" if roleCollection[policyPartyRole.refGuid].to_s != ""
                            roleCollection[policyPartyRole.refGuid] = roleCollection[policyPartyRole.refGuid].to_s+"#{getLabelValue(policyPartyRole.roleCd)}"
                        end
                    else
                        roleCollection[policyPartyRole.refGuid] = roleCollection[policyPartyRole.refGuid].to_s+"/" if roleCollection[policyPartyRole.refGuid].to_s != ""
                        roleCollection[policyPartyRole.refGuid] = roleCollection[policyPartyRole.refGuid].to_s+"#{getLabelValue(policyPartyRole.roleCd)}"
                    end
                end
            end
             
             # Sort only if roleCollection exists and is not empty and Sorts according to roleCollection order; unmatched parties naturally go after the last key index
            if roleCollection.respond_to?(:keys) && !roleCollection.empty?
                self.PartyList.sort_by! { |party| roleCollection.keys.index(party.guid.to_s) || roleCollection.keys.size }
            end

            self.PartyList.each do |party|
                next if party.removed.to_s == "YES"
                if roleCollection.has_key?(party.guid.to_s)
                    if party.partyTypeCd == "ORGANIZATION"
                        displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                    else
                        displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                    end         
                    partyNames[party.guid] = "#{roleCollection[party.guid.to_s]}-#{displayName}"
                end
            end
        end
        return partyNames
    end
end
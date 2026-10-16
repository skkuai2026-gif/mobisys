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
      
    set :schema_version, '1.4'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync

    #add model specifc code here
    property :policySeq, :integer
    property :quotationRefGuid, :string
    property :baseProductVersion, :string
    property :policyNum, :string
    property :proposalNum, :string
    property :applicationRefNum, :string
    property :proposalSignedDt, :date
    property :proposalReceivedDt, :date
    property :proposalEntryDt, :date
    property :baseAgentId, :string
    property :baseProductId, :string
    property :baseProductSeq, :string
    property :baseProductTypeCd, :string
    property :baseProductFamilyCd, :string
    property :groupCd, :string
    property :schemeCd, :string
    property :policyIssueDt, :date
    property :policyMaturityDt, :date
    property :policyCommencementDt, :date
    property :riskCommencementDt, :date
    property :statusCd, :string
    property :totSumAssured, :integer
    property :totAnnualPremium, :integer
    property :totModalPremium, :integer, :decimal
    property :totalRiderPremium, :integer
    property :totExtraPremium, :integer, :decimal
    property :statusDt, :date
    property :stageCd, :string
    property :processStatusCd, :string
    property :quotationRefNum, :string
    property :branchCd, :string
    property :uwDecisionCd, :string
    property :uwDecisionValue, :string
    property :overallUWDecisionCd, :string
    property :insuredUWDecisionCd, :string
    property :financerUWDecisionCd, :string
    property :policyOtherUWDecisionCd, :string
    property :purposeOfInsuranceCd , :string
    property :intimationSourceCd, :string
    property :policyStatusCd, :string
    property :leadGenerationCd, :string
    property :productPlanOptionCd, :string
    property :leadGeneratorRemarks, :string
    property :campaignCode, :string
    property :statCd, :string
    property :totalCoi, :integer
    property :removed, :string
    property :imageName, :string
 
    #added for Product version
    property :corrByEmail, :string
    property :formName, :string
    property :policyDispatchModeCd, :string
    property :otherPurposeOfInsurance, :string
    property :otherSourceOfFund, :string
    property :communicationPreference, :string

    #added for FWDPH
    property :agentDeclarationSignatureCd, :string
    property :agentSignatureCd, :string
    property :bankStaffReferralCd, :string
    property :fnaId, :string
    property :leadId, :string
    property :policySignedPlace, :string
    property :primarySignatureCd, :string
    property :primarySignatureDt, :date
    property :primarySignaturePlace, :string
    property :proposalSecureInfoSignatureCd, :string
    property :proposalSecureInfoSignatureDt, :date
    property :proposerSignedDt, :date
    property :proposerSignedPlace, :string
    property :ropAgentSignatureCd, :string
    property :ropAgentSignatureDt, :date
    property :ropProposalSignatureCd, :string
    property :rpqId, :string
    property :thirdPartyCustId, :string

    #new attributes
    property :apoProductId, :string  
    property :decisionReason, :string  
    property :firstPremium, :float 
    property :quoteProposerSameAsInsured, :string
    property :initialTopupFl, :string 
    property :parentAgencyId, :string 
    property :quotAddtnlField1, :string 
    property :quotAddtnlField2, :string 
    property :quotAddtnlField3, :string 
    property :quotAddtnlField4, :string 
    property :quotAddtnlField5, :string 
    property :quotAddtnlField6, :string 
    property :quotAddtnlField7, :string
    property :quotAddtnlField8, :string
    property :quotAddtnlField9, :string
    property :quotAddtnlField10, :string
    property :quotAddtnlField11, :string
    property :quotAddtnlField12, :string
    property :regularTopupFl, :string 
    property :solverTypeCd, :string 
    property :sourceOfFund, :string
    property :totTax, :float  
    property :withdrawalFl, :string
    property :withdrawalRateTypeCd, :string
    property :jointLife, :string
    property :signatureStatus, :string
    property :visitedTabs, :string
    property :isBackdatedFl, :string
    property :quotationDt, :date
    property :unselectedRiders, :string
    property :insuranceTypeCd, :string
    property :tripTypeCd, :string
    property :maxTripPeriod, :integer
    property :travelGeographyCd, :string
    property :visitPurposeCd, :string
    property :numberOfAdult, :integer
    property :numberOfChildren, :integer
    property :startDt, :date 
    property :endDt, :date
    property :coverTypeCd, :string
    property :counterOfferDecisionCd, :string
    property :counterOfferReasonCd, :string 
    property :counterOfferAcceptDt, :date
    property :counterOfferRemarks, :string
    property :autoRegistrationNum, :string
    property :autoMakeCd, :string
    property :autoModelCd, :string
    property :topupOptionCd, :string
    property :transferControlTo, :string
    property :supplementaryLives, :string
    property :step, :integer
    property :stepActionTabs, :string
    property :systTransferOptionCd, :string
    property :allocatedToRole, :string
    property :allocatedToPartyGuid, :string
    property :allocationPartyGuidList, :string
    property :allowModifyAllRoles, :string
    property :uploadFlag, :string
    property :quotationSeq, :float
    property :courierName, :string
    
    #derived attributes
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :currentTab, :buttonClicked, :insuredSameAsProposer

    has_many 'PolicyProduct' 
    has_many 'PolicyAdditionalFields'
    has_many 'Party'
    has_many 'PolicyPartyRole'
    has_many 'PolicyAgent'
    has_many 'PolicyDocTemp'
    has_many 'PolicyOfflineQuestion'
    has_many 'PolicyPayment'
    has_many 'PolicyTopUp'
    has_many 'PolicyResult'

  
    # attr_accessor :quotationSeq
	attr_accessor :entityDesc
    attr_accessor :questionContainer
    attr_accessor :policyWithdrawalList
    attr_accessor :isInvalid
    attr_accessor :invalidReason
    attr_accessor :isCompleted
    attr_accessor :additionalData
    attr_accessor :action
    attr_accessor :proposerLASame

	def getEntityDesc
		self.entityDesc = self.proposalNum.to_s
	end


    #online-offline sync methods
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO"
    end
        

    #return the list of child classes whose context need to be evaluated along with this class.
      def contextExtendForClass
        return "PolicyAdditionalFields"
      end

    def afterSync
        if self.policyResult != nil
            self.policyResult.each do |polResult|
                polResult.parentKey = self.guid
            end    
        end
        if $rhoconfig[:TABFEATUREREQD] 
            self.PolicyProductList.each do |policyProd|
                policyProd.selected = 'YES' if policyProd.builtInRiderFl != 'YES' && policyProd.productTypeCd == 'RIDER'
            end
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
        self.persistAll
    end

    def getRegularTopUp
        regular_top_up = nil
        self.PolicyTopUpList.each do |top_up|
            next unless top_up.topUpTypeCd == "REGULARTOPUP"
            regular_top_up = top_up 
        end
        regular_top_up
    end

    def getDocumentParties
        partyNames = self.getPartyNames("tab_requirement")
        documentPartyList = Array.new
        partyNames.keys.each do|partyGuid|
            party = self.getPartyByGuid(partyGuid)
                documentPartyList.push party  if party != nil
        end
        return documentPartyList
    end

    def getTopup(policyYear)
        topup = nil
        self.PolicyTopUpList.each do |policyTopup|
            if policyTopup.removed.to_s == ""
                if policyTopup.policyYearFrom.to_s != "" and policyTopup.policyYearTo.to_s != "" and policyTopup.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= policyTopup.policyYearTo.to_i
                    topup = policyTopup
                    break 
                end
            end
        end
        unless topup
            topup = PolicyTopUp.new
            topup.topUpAmount = 0.0
        end
        return topup
    end

    def getPolicyTopup(policyYear, topuUpTypeCd)
        topup = nil
        self.PolicyTopUpList.each do |policyTopup|
            if policyTopup.removed.to_s == "" && topuUpTypeCd.to_s != '' && policyTopup.topUpTypeCd.to_s == topuUpTypeCd
                if policyTopup.policyYearFrom.to_s != "" and policyTopup.policyYearTo.to_s != "" and policyTopup.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= policyTopup.policyYearTo.to_i
                    topup = policyTopup
                    break 
                end
            end
        end
        unless topup
            topup = PolicyTopUp.new
            topup.topUpAmount = 0.0
        end
        return topup
    end

    #Method to get base product for a given policy 
    def getBaseProduct
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

    def getBasePlan
        return getBaseProduct
    end

    #Method to get insured name for a given policy
    def getProposerName
        proposerName = ""
        proposer = self.getParty("PROPOSER")
        if proposer
            proposerName1 = getLabelValue(proposer.titleCd.to_s) + " " + proposer.firstName1.to_s + " " + proposer.lastName1.to_s
            proposerName2 = getLabelValue(proposer.titleCd.to_s) + " " + proposer.firstName2.to_s + " " + proposer.lastName2.to_s
            if proposerName1 != ""
                proposerName = proposerName1
            else
                proposerName = proposerName2
            end
        end

        return proposerName
    end


    #Avdhut Vaidya 06-05-2015: Method to get PolicyAgent list of child objects of policy
    def getPolicyAgentList(createNewObject = false)
        returnPolicyAgentList = Array.new
        self.PolicyAgentList.each do |policyAgent|
            returnPolicyAgentList.push(policyAgent)
        end   
        if returnPolicyAgentList.length < 2 && createNewObject
            policyAgent1 = PolicyAgent.new
            self.addPolicyAgent(policyAgent1)
            returnPolicyAgentList.push(policyAgent1)

            policyAgent2 = PolicyAgent.new
            self.addPolicyAgent(policyAgent2)
            returnPolicyAgentList.push(policyAgent2)
        end
        return returnPolicyAgentList
    end 


    #Avdhut Vaidya 05-05-2015: Method to get Party child objects of policy based on roleCd
    def getParty(roleCd)
        returnParty = nil      
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == roleCd
                self.PartyList.each do |party|
                    if party.guid == policyPartyRole.refGuid && party.parentKey == policyPartyRole.parentKey && party.removed.to_s != "YES"
                        returnParty = party
                        break
                    end
                end
                break
            end
        end    
        return returnParty
    end 


    #Avdhut Vaidya 05-05-2015: Method to get Array of all Party child objects of policy for a specific roleCd
    def getPartyList(roleCd)
        returnPartyList = Array.new
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
        return returnPartyList
    end 


    #Avdhut Vaidya 05-05-2015: Method to get PolicyPartyRole child objects of policy based on roleCd
    def getPolicyPartyRole(roleCd)
        returnPolicyPartyRole = nil
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == roleCd
                returnPolicyPartyRole = policyPartyRole
                break
            end
        end
        return returnPolicyPartyRole
    end  


    #Avdhut Vaidya 05-05-2015: Method to get Array of all PolicyPartyRole child objects of policy for a specific roleCd
    def getPolicyPartyRoleList(roleCd)
        returnPolicyPartyRoleList = Array.new
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == roleCd
                returnPolicyPartyRoleList.push(policyPartyRole)
            end
        end 
        return returnPolicyPartyRoleList
    end 


    #Avdhut Vaidya 12-05-2015: Method to get InwardPolicy child objects of Inward based on policyNum & accTypeCd
    def getInward(policyNum, acctTypeCd)
        returnInward = nil
        
        inwardPolicy = InwardPolicy.loadObject(
            :first,
            :conditions => {
                {:name => 'policyNum'} => policyNum,
                {:name => 'acctTypeCd'} => acctTypeCd
            },
            :op => 'AND'
        )
        
        if inwardPolicy
            returnInward = Inward.loadObject(
                :first,
                :conditions => {
                    {:name => 'object'} => inwardPolicy.parentKey
                }
            )
        end
        return returnInward
    end


    #Avdhut Vaidya 21-05-2015: Method to get Payer Party child of policy based on paymentInstructionTypeCd
    def getPayerParty(paymentInstructionTypeCd)
        returnPayer = nil
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == "PAYER" && policyPartyRole.paymentInstructionTypeCd == paymentInstructionTypeCd
                self.PartyList.each do |party|
                    if party.guid == policyPartyRole.refGuid && party.parentKey == policyPartyRole.parentKey
                        returnPayer = party
                        break
                    end
                end
                break
            end
        end
        return returnPayer
    end


    #Avdhut Vaidya 21-05-2015: Method to get PolicyPayment child of policy based on paymentInstructionTypeCd
    def getPolicyPayment(paymentInstructionTypeCd)
        returnPolicyPayment = nil
        self.PolicyPaymentList.each do |policyPayment|
            if policyPayment.paymentInstructionTypeCd == paymentInstructionTypeCd
                returnPolicyPayment = policyPayment
            end
        end 
        return returnPolicyPayment
    end
    #Swati Ahire 30-09-2015: Method to get PolicyPartyRole hash for Payer
    def getPayerPolicyPartyRoleList
      policyPartyRoleHash = Hash.new
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == "PAYER" && policyPartyRole.paymentInstructionTypeCd == "INITIAL"
                self.PartyList.each do |party|
                    if party.guid == policyPartyRole.refGuid
                        policyPartyRoleHash[policyPartyRole.refGuid] = policyPartyRole
                        break
                    end
                end   
            end
        end
        return policyPartyRoleHash
    end
    
    def getRiderCountForParty(partyGuid)
        counter = 0
        self.PolicyProductList.each do |ppd|
            if ppd.productTypeCd.to_s == "RIDER" && ppd.insuredPartyRefGuid.to_s == partyGuid
                counter = counter + 1
            end
        end
        return counter
    end

    def getLifeCountForRider(riderId)
        counter = 0
        self.PolicyProductList.each do |ppd|
            if ppd.productTypeCd.to_s == "RIDER" && ppd.productId.to_s == riderId
                counter = counter + 1
            end
        end
        return counter
    end

    def getPayerPartyList
        payerList = []
        self.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd == "PAYER"
                self.PartyList.each do |party|
                    if party.guid == policyPartyRole.refGuid && policyPartyRole.partySameAsCd.to_s == ""
                        payerList.push(party)
                        #break
                    end
                end
                #break
            end
        end
        return payerList
    end

    #Nikhil Chaudhary 04-11-2016: Method to get NonBuilt-in Riders
    def getNonBuiltInRiders
        riderList = []
        self.PolicyProductList.each do |policyProduct|
            riderList.push policyProduct if policyProduct.productTypeCd == "RIDER" and policyProduct.builtInRiderFl != "YES"
        end
        return riderList
    end

    #Nikhil Chaudhary 04-11-2016: Method to get Built-in Riders
    def getBuiltInRiders
        builtInRiderList = []
        self.PolicyProductList.each do |policyProduct|
            builtInRiderList.push policyProduct if policyProduct.productTypeCd == "RIDER" and policyProduct.builtInRiderFl == "YES"
        end
        return builtInRiderList
    end

    def getRidersByParty(guid)
        riderList = Array.new
        self.PolicyProductList.each do |policyProduct|
            riderList.push policyProduct if policyProduct.productTypeCd == "RIDER" && policyProduct.insuredPartyRefGuid.to_s == guid
        end        
        riderList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
        return riderList
    end

    def getPartyByGuid(guid)
        party = nil
        self.PartyList.each do |policyParty|
            if policyParty.uniqueKey == guid
                party = policyParty
                break
            end
        end
        return party
    end


    def getPolicyPartyRoleByPartyGuid(guid, roleCd=nil, paymentInstructionTypeCd = nil)
        policyPartyRoleList = []
        policyPartyRole = nil
        if roleCd.to_s != ""
            policyPartyRoleList = self.getPolicyPartyRoleList(roleCd)
        else
            policyPartyRoleList = self.PolicyPartyRoleList
        end
        policyPartyRoleList.each do |partyRole|
            if partyRole.refGuid == guid
                if paymentInstructionTypeCd.to_s != ""
                    if partyRole.paymentInstructionTypeCd == paymentInstructionTypeCd
                        policyPartyRole = partyRole 
                        break
                    end
                else
                    policyPartyRole = partyRole
                    break
                end
            end
        end
        return policyPartyRole
    end


    def getMainInsured(policyProduct)
        mainInsured = nil
        policyProduct.PolicyProductInsuredList.each do |policyProductInsured|
            if policyProductInsured.insuredPartyRefGuid.to_s != ""
                mainInsured = getPartyByGuid(policyProductInsured.insuredPartyRefGuid)
            elsif policyProductInsured.partyRoleCd.to_s != ""
                mainInsured = getParty(policyProductInsured.partyRoleCd)
            else
                mainInsured = getParty("PRIMARY")
            end
        end
        return mainInsured
    end

    def getPolicyProductByProductTypeCd(productTypeCd)
        policyProducts = []
        self.PolicyProductList.each do |policyProduct|
            if policyProduct.productTypeCd.to_s == productTypeCd
                policyProducts.push policyProduct
            end
        end
        return policyProducts
    end 

    def getPartyRoleCds
        roleCds = []
        roleCds = self.PolicyPartyRoleList.group_by{|party| party.roleCd}.keys.uniq
        return roleCds
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

    def getPartyByRelation(relationCd)
        relationParty = nil
        if(relationCd != '')
            parties = self.PartyList
            parties.each do |party|
                if party.relationCd == relationCd
                    relationParty = party
                    break
                end
            end
        end
        return relationParty
    end

    def getNomineePartyAddressList
		nomineePtyList = self.getPartyList("NOMINEE")
		nomineePtyAddressList = []
		nomineePtyList.each do |nomineePty|
			nomineePtyAddressList = nomineePtyAddressList + nomineePty.PartyAddressList unless nomineePty.PartyAddressList == nil
		end
		return nomineePtyAddressList
	end

    def getGatewayFlag
        gatewayFlag = false
        inward = self.getInward(self.proposalNum, "APPLICATION_SUSPENSE")
        if inward
            inward.InwardDetailsList.each do |inwardDetail|
                gatewayFlag = true if inwardDetail.paymentMethodCd == "IPG"
            end
        end
        return gatewayFlag
    end

    def self.entitiesForSync
        lastSyncDate = Time.at(0)
        lastSyncDateAppObject = Application.getValue("Policy_" + $userId + '_lastSyncDate')
        if lastSyncDateAppObject
            lastSyncDate = Time.load(lastSyncDateAppObject.value)
        end
        entitiesForSync = [] 
        policyList = Policy.loadObject(:all)
        policyList.each do|policy|
            if (policy.policyNum.to_s == "" && Time.parse(policy.systemUpdatedDt) > Time.parse(lastSyncDate.to_s))
                entitiesForSync.push policy
            end
        end
        return entitiesForSync
    end

    def getInitialPaymentMethods
        inward = self.getInward(self.proposalNum, "APPLICATION_SUSPENSE")
        paymentMethodList = []
        if inward
            inward.InwardDetailsList.each do |inwardDetail|
                paymentMethodList.push(inwardDetail.paymentMethodCd)
            end
        end
        return paymentMethodList
    end

    def getTotalServiceTax
        totServiceTax = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.serviceTax != nil )
                totServiceTax = totServiceTax + policyProduct.serviceTax
            end
        end
        return totServiceTax
    end

    def getTotSumAssured
        totSumAssured = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.baseSumAssured != nil )
                totSumAssured = totSumAssured + policyProduct.baseSumAssured
            end
        end
        return totSumAssured
    end

    def getTotAnnualPremium
        totAnnualPremium = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.baseAnnualPremium != nil )
                totAnnualPremium = totAnnualPremium + policyProduct.baseAnnualPremium
            end
        end
        return totAnnualPremium
    end

    def getTotModalPremium
        totModalPremium = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.modalPremium != nil )
                totModalPremium = totModalPremium + policyProduct.modalPremium
            end
        end
        return totModalPremium
    end

    def getTotExtraPremium
        totExtraPremium = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.extraPremium != nil )
                totExtraPremium = totExtraPremium + policyProduct.extraPremium
            end
        end
        return totExtraPremium
    end

    def getTotalCoi
        totCoi = 0.0
        self.PolicyProductList.each do |policyProduct|
            if (policyProduct != nil && policyProduct.coi != nil )
                totCoi = totCoi +  policyProduct.coi
            end
        end
        return totCoi
    end

    def getPayerPartyRole(paymentInstructionTypeCd)
        policyPartyRoleDO = nil
        policyPartyRoleList = self.getPolicyPartyRoleList("PAYER")
        policyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.paymentInstructionTypeCd == paymentInstructionTypeCd
                policyPartyRoleDO = policyPartyRole
                break
            end
        end
        return policyPartyRoleDO
    end

    def getPolicyProductByGuid(guid)
        policyProduct = nil
        self.PolicyProductList.each do |policyProd|
            if policyProd.guid == guid
               policyProduct =  policyProd
               break;
           end
        end
        return policyProduct
    end


    def getListPartyIdentityList
        partyIdentityList = []
        self.PartyList.each do |party|
            party.PartyIdentityList.each do |partyIdentity|
                partyIdentityList.push(partyIdentity)
            end
        end
        return partyIdentityList
    end

    def getListPartyAddressList
        partyAddressList = []
        self.PartyList.each do |party|
            party.PartyAddressList.each do |partyAddress|
                partyAddressList.push(partyAddress)
            end
        end
        return partyAddressList
    end

    def getListPartyContactList
        partyContactList = []
        self.PartyList.each do |party|
            party.PartyContactList.each do |partyContact|
                partyContactList.push(partyContact)
            end
        end
        return partyContactList
    end

    def getListPartyEmploymentList
        partyEmploymentList = []
        self.PartyList.each do |party|
            party.PartyEmploymentList.each do |partyEmployment|
                partyEmploymentList.push(partyEmployment)
            end
        end
        return partyEmploymentList
    end

    def getSupplementaryPartyList
        return  self.getPartyList("SUPPLEMENTARY")
    end

    def getNomineePartyList
        return self.getPartyList("NOMINEE")
    end

    def getListPolicyTopUpList
        return self.PolicyTopUpList
    end

    def getListPartyList
        return  self.PartyList
    end

    def getRiderList
        riderList = Array.new
        self.PolicyProductList.each do |policyProduct|
            riderList.push policyProduct if policyProduct.productTypeCd == "RIDER"
        end        
        return riderList
    end

    def getQuestionnaireParties
        partyNames = self.getPartyNames("tab_questionnaire")
        questionnairePartyList = Array.new
        partyNames.keys.each do|partyGuid|
            party = self.getPartyByGuid(partyGuid)
                questionnairePartyList.push party  if party != nil
        end
        return questionnairePartyList
    end

    def getListPolicyWithdrawalList
        policyWithdrawalList = []
        policyWithdrawalList = self.policyWithdrawalList if self.policyWithdrawalList != nil
        return policyWithdrawalList
    end

    def getPolicyTopupForType(topUpType)
        topUpRet = nil
        self.PolicyTopUpList.each do |top_up|
            next unless top_up.topUpTypeCd.upcase == topUpType.upcase
            topUpRet = top_up 
        end
        if topUpRet == nil
            topUpRet = PolicyTopUp.new
            topUpRet.topUpAmount = 0.0
            topUpRet.topUpTypeCd = topUpType
        end
        return topUpRet
    end

    def getSupplementaryLivesCount
        return self.getSupplementaryPartyList.size
    end

    def getNomineeCount
        return self.getNomineePartyList.size
    end

    def getRiderCount
        return self.getRiderList.size
    end

    def getPolicyPartyRoleByGuid(guid, roleCd=nil)
        policyPartyRoleList = []
        policyPartyRole = nil
        if roleCd.to_s != ""
            policyPartyRoleList = self.getPolicyPartyRoleList(roleCd)
        else
            policyPartyRoleList = self.PolicyPartyRoleList
        end
        policyPartyRoleList.each do |partyRole|
            if partyRole.guid == guid
                policyPartyRole = partyRole
                break
            end
        end
        return policyPartyRole
    end

    def createPolicyPartyRole(party,roleCd)
        if(party != nil && roleCd.to_s != "")
            policyPartyRole = self.getPolicyPartyRoleByGuid(party.guid,party.roleCd)
            if(policyPartyRole == nil)
                policyPartyRole = PolicyPartyRole.new 
                policyPartyRole.roleCd = roleCd
                policyPartyRole.refGuid = party.guid
                self.addPolicyPartyRole(policyPartyRole)
            end
            # self.addParty(party)
        end

    end

     def getPartyNamesRestAPI(tabName="",roleCds='')
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
                        partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}/#{getLabelValue('PAYER')}: #{displayName}"
                    else
                        partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}: #{displayName}"
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
                            partyNames[party.guid] = "#{getLabelValue(party.roleCd)}/#{getLabelValue('PAYER')}: #{displayName}"
                        else
                            partyNames[party.guid] = "#{getLabelValue(party.roleCd)}: #{displayName}"
                        end
                    end
                end
            elsif party.roleCd.to_s == 'PAYER' && payerQuestFacet.to_s != ""
                if party.partyTypeCd == "ORGANIZATION"
                    displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                else  
                    displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                end
                partyNames[party.guid] = "#{getLabelValue(party.roleCd)}: #{displayName}"
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
                            partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}/#{getLabelValue('PAYER')}: #{displayName}"
                        else
                            partyNames[party.guid] = "#{getLabelValue('PRIMARY')}/#{getLabelValue('PROPOSER')}: #{displayName}"
                        end
                    else
                        if party.partyTypeCd == "ORGANIZATION"
                            displayName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                        else
                            displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
                        end 
                        if payerIsSameAs == party.roleCd.to_s && payerQuestFacet.to_s != ""
                            partyNames[party.guid] = "#{getLabelValue(party.roleCd)}/#{getLabelValue('PAYER')}: #{displayName}"
                        else
                            partyNames[party.guid] = "#{getLabelValue(party.roleCd)}: #{displayName}"
                        end
                    end
                end
            end
        end
        return partyNames
    end

    def getPolicyWithdrawalDO(index)
        policyWithdrawal = nil
        policyWithdrawal = self.policyWithdrawalList[index] if self.policyWithdrawalList != nil
        policyWithdrawal = QuotationWithdrawal.new if policyWithdrawal == nil
        return policyWithdrawal
    end

    def getPartyDOByQuotationPartyGuid(quotationPartyGuid)
        if quotationPartyGuid.to_s != ""
            self.PartyList.each do |party|
                return party if quotationPartyGuid.to_s == party.quotationPartyGuid.to_s
            end
        end
        return nil
    end

    def getPartyByRole(roleCd)
        if !self.PolicyPartyRoleList.nil? && self.PolicyPartyRoleList.size > 0
            ppr = nil
            # check if the role passed is prop cum insured then search for role primary since propcumins does not exist in policypartyrole
            roleCd = "PRIMARY" if roleCd.to_s == "PROPCUMINS"
            self.PolicyPartyRoleList.each do |pprd|
                if pprd.roleCd.to_s != "" && pprd.roleCd.to_s == roleCd.to_s
                    ppr = pprd
                    break
                end
            end
            if !ppr.nil?
                self.PartyList.each do |party|
                    if party.partyId.to_s != "" && ppr.partyId.to_s != "" && party.partyId.to_s == ppr.partyId.to_s
                        return party
                    elsif ppr.refGuid.to_s != "" && party.guid.to_s == ppr.refGuid.to_s
                        return party
                    end
                end
            end
        else
            if self.quoteProposerSameAsInsured.to_s == "YES"
                roleCd = "PROPCUMINS"
                self.PartyList.each do |party|
                    return party if party.roleCd.to_s == roleCd.to_s
                end
            end
        end
        return nil
    end

    def getPartyDOByGuid(refGuid)
        if refGuid.to_s != ""
            self.PartyList.each do |party|
                return party if refGuid.to_s == party.refGuid.to_s
            end
        end
        return nil
    end

    def getPolicyAdditionalFieldsDO
        policyAdditionalFieldsDO = nil
        if self.PolicyAdditionalFieldsList.size > 0
            # policyAdditionalFieldsDO = self.PolicyAdditionalFieldsList[0]
            policyAdditionalFieldsDO = self.getPolicyAddionalField("000")
        else
            policyAdditionalFieldsDO = PolicyAdditionalFields.new
            self.addPolicyAdditionalFields(policyAdditionalFieldsDO)
        end
        return policyAdditionalFieldsDO
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

    def getPolicyAddionalField(additionalTypeCd)
        policyAdditionalFieldsDO = nil
        self.PolicyAdditionalFieldsList.each do |pad|
            if additionalTypeCd.to_s != "" && pad.additionalTypeCd.to_s != "" && pad.additionalTypeCd.to_s == additionalTypeCd.to_s
                policyAdditionalFieldsDO = pad
            elsif additionalTypeCd.to_s == "" && pad.additionalTypeCd == "000"
                policyAdditionalFieldsDO = pad
            elsif additionalTypeCd == "000" && pad.additionalTypeCd.to_s == ""
                policyAdditionalFieldsDO = pad
            end
        end
        policyAdditionalFieldsDO
    end

    def getEntityTypeCd
      entityTypeCd = self.entityTypeCd
      entityTypeCd = "POLICY" if entityTypeCd.to_s == ""
      return entityTypeCd
    end    

    def getServiceSignature(roleCd)
        serviceSignature = nil
        signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => self.guid}) 
        if signatureContainer
            serviceSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.roleCd == roleCd}.first 
        end
        return serviceSignature
    end
end

begin 
    require 'Policy/policy_company'
rescue LoadError => e
    puts 'policy_company not included'
end
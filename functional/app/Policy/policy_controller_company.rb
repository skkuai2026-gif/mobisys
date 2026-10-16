require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Policy/policy_b_o'
require 'Policy/PolicyUtil'
require 'Policy/policy_service'
require 'Policy/UIGenUtilEapp'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'CommonClasses/PolicyIO'
require 'CommonModules/entityschema'
require 'SignatureContainer/signatureUtil'
require 'TrackLead/track_lead_b_o'
require 'CommonModules/mobisysuihelper_jazz'
require 'ostruct'
require 'Policy/PolicyPreview'
require 'Quotation/quotation_service'

class PolicyController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper


    def process
    	policy = @baseIO.baseDO

        quotation = Quotation.loadObject(:first,:conditions =>{:guid => policy.quotationRefGuid})
        parsedData = parseRequestBodyParams
        fetchData = parsedData['FetchData'] if parsedData.has_key?("FetchData")
        currentActiveTab = fetchData['currentActiveTab'] if fetchData && fetchData.has_key?("currentActiveTab")
        parsedModels = parsedData["FormData"]["Models"]
        if parsedModels && parsedModels.has_key?("PolicyAdditionalFields")
        paramField26 = parsedModels["PolicyAdditionalFields"]["field26"]
        end
       
        # policy.PartyList.each do |party|
        #     puts "party-----------#{party}"
        # end
        # policy.PartyList.each do |party|
        #     if (party.roleCd.to_s.casecmp("PROPOSER").zero? || party.roleCd.to_s.casecmp("PRIMARY").zero? || party.roleCd.to_s.casecmp("PROPCUMINS").zero?)
        #         uniqueAddressTypeCd = []
        #         uniqueAddress = []
        #         party.PartyAddressList.each do|partyAddress|
        #             uniqueAddressTypeCd << partyAddress.addressTypeCd
        #             uniqueAddress << partyAddress
        #             partyAddress.removed = "YES"
        #         end
        #         if uniqueAddress.size > 0
        #             uniqueAddress.each do |address|
        #                 if address.addressTypeCd.to_s != ""
        #                 party.getPartyUniqueAddress(address.addressTypeCd, address)
        #                 end
        #             end
        #         end
        #     end
        # end

        baseProduct = policy.getBaseProduct

        if currentActiveTab.to_s == "tab_questionnaire"
            medExMand = nil
            medExMandOwn = nil

            $currentProduct ||= ProductUtil.getProduct(policy.baseProductSeq)
            medexmandFacet = $currentProduct.getFacet("MEDEXMAND")
            if medexmandFacet
                quotationIO = MobiSys::IO::QuotationIO.new
            	quotationIO.baseDO = quotation.cloneObject
            	quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
            	returnHash = {}
            	if quotePlan.product == nil
            		product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
            	else
            		product = quotePlan.product
            	end 
            	quotationIO.baseProduct = product
            	MobiSys::ProductBO.loadModel("MEDEXMAND",quotationIO)
                quotationIO.listCalculation = []
            	quotationIO.illustrationHeader = nil
            	quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                medexmand = quotationIO.results.medexmand
                medexmandown = quotationIO.results.medexmandown
                puts "medexmand======#{medexmand}"
                puts "medexmandown=====#{medexmandown}"
                policy.quotAddtnlField3 = medExMand
            	policy.quotAddtnlField4 = medExMandOwn
            end
        end
        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => policy.guid})
        if signatureContainer
            signatureContainer.ServiceSignatureList.each do |signature|
                if (signature.signatureTypeCd.to_s.casecmp("SIGNATURECAPTUREEAPPPROPOSER").zero? && signature.roleCd.to_s.casecmp("PROPOSER").zero? && signature.signatureDt.to_s != "")
                    signatureDt = Time.parse(signature.signatureDt.to_s)
                    policy.proposalSignedDt = signatureDt
                end
            end
        end

        if policy.statusCd.to_s == "SUBMITTED_UWCOMPLETE"
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            RhoLog.error("PROCESS","has_network :- #{has_network}")
            # has_network = false #uncomment to test offline flow.
            if has_network
                responseHash = MobiSys::PolicyService.executeSubmit(true,policy)
                @success = responseHash["success"]
                @message = responseHash["message"]
            else
                @success = false
                @message = getLabelValue('ERR_NETWORK')
            end
            return
        end
        #moved the logic here to validatePolicy method. This is to have a method which will only validate a policy without saving to the database.
        validatePolicy(policy)
        #submitPaymentDetails(newPolicy)
        #submitQuestionnaire(newPolicy)


        # if ((policy.statusCd.to_s == "SIGNED" && (policy.uwDecisionCd.to_s == "ACCEPTEDRATED" || policy.uwDecisionCd.to_s == "REQUIREMENTPENDING")) || (policy.statusCd.to_s == "UWCOMPLETE" && (policy.uwDecisionCd.to_s == "ACCEPTEDRATED" || policy.uwDecisionCd.to_s == "REQUIREMENTPENDING")) || policy.statusCd.to_s == "COMPLETE" || policy.statusCd.to_s == "ACCEPTED" || policy.statusCd.to_s == "PENDING" || policy.statusCd.to_s == "")
        #     MobiSys::SignatureUtil.clearSignatures(policy) if policy.uwDecisionCd != "REQUIREMENTPENDING"
        #     policy.proposalSignedDt = "" if policy.uwDecisionCd != "REQUIREMENTPENDING"
        #     policy.uwDecisionCd = "PENDING" if policy.uwDecisionCd != "REQUIREMENTPENDING"
        #     policy.statusCd = "PENDING" if policy.uwDecisionCd != "REQUIREMENTPENDING"
        # end

        if policy.uwDecisionCd == "ACCEPTEDRATED" && policy.counterOfferDecisionCd.to_s == ""
        	originalQuotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
        	newQuotation = MobiSys::PolicyBO.convertToQuotation(policy)
        	newQuotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
        	newQuotation.productId = originalQuotation.productId
        	newQuotation.productVersion = originalQuotation.productVersion
        	newQuotation.quoteStatusCd = "COMPLETED"
        	newQuotation.signature = ""
        	newQuotation.productTypeCd = originalQuotation.productTypeCd
        	newQuotation.productFamilyCd = originalQuotation.productFamilyCd
        	newQuotation.policyYear = originalQuotation.policyYear
        	newQuotation.withdrawalFl = originalQuotation.withdrawalFl
        	newQuotation.childUserId = originalQuotation.childUserId
        	newQuotation.quotationExpiryDt = originalQuotation.quotationExpiryDt
        	newQuotation.issueDt = originalQuotation.issueDt
        	newQuotation.signatureDt = ""
        	newQuotation.visitedTabs = originalQuotation.visitedTabs
        	newQuotation.guid = newQuotation.object.gsub(".","_")
        	newQuotation.persistAll
        	policy.quotationRefGuid = newQuotation.uniqueKey
        	policy.quotationRefNum = newQuotation.quotationRefNum
        	policy.counterOfferAcceptDt = Time.new #.strftime("%F 00:00:00 %z")
        end
        #For step feature in UI
        MobiSys::PolicyService.incrementStep(policy,true)

        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.entityTypeCd = "POLICY"
        policy.totModalPremium = MobiSys::PolicyService.getTotModalPremium(policy)
        # p "currentActiveTab============#{currentActiveTab}"
        # p "paramField26=============#{paramField26}"
        if currentActiveTab.to_s == "tab_plan"
            policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
                if policyAdditionalFieldsDO.field26.to_s != ""  && paramField26.to_s == ""
                    policyAdditionalFieldsDO.field26 = paramField26
                end
            end
        end
        
        # policy.PartyList.each do |party|
        #     if party.roleCd == "NOMINEE"
        #         nomineePartyRole = policy.getPolicyPartyRoleByPartyGuid(party.guid,"NOMINEE")
        #         if nomineePartyRole
        #         party.partySameAsCd = nomineePartyRole.partySameAsCd
        #         nomineePartyRole.eventTypeCd = party.eventTypeCd
        #         end
        #     end
        # end
        number = 0;
        r = Random.new
        number = r.rand(10000...99999);
        policyAdditionalFields = policy.PolicyAdditionalFieldsList[0]
        p "policyAdditionalFields=====#{policyAdditionalFields}"
        @AgentRegdetails = AgentReg.forUserId($userId)
        if @AgentRegdetails
            currentAgentId = @AgentRegdetails.agentId
        end
        p "number===========#{number}"
        policyAdditionalFields.field13 = currentAgentId + number.to_s if policyAdditionalFields && policyAdditionalFields.field13.to_s == ""
        p "policyAdditionalFields====fieldd13====#{policyAdditionalFields}"
        if policy.action.to_s == ""
            policy.action = "Save"
        end
        policy.persistAll
    end



    def generateApplicationNumber
        p "inside generate generateApplicationNumber****#{@params}*****"
        parsedData = parseRequestBodyParams
        p "inside parseedData=============#{parsedData}"
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        p "policy=========#{@policy}"

        @policyProduct = PolicyProduct.loadObject(:first, :conditions=>{{:name=>'parentKey'}=>@policy.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND')
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        $appDbMismatchFlag = false if !has_network
        if(has_network)
            # checkLicensetype = validateLicenseType   #SUNSS 2405 NEW
            # p "checkLicensetype==========#{checkLicensetype}"
            if true #checkLicensetype
                begin
                    responseHash = {}
                    productId = @policy.getBaseProduct.productId.to_s
                    userId = $userId.to_s
                    proposalNum = @policy.proposalNum.to_s
                    addtnField1 = @policyProduct.addtnField1 if @policyProduct
                    paymentHash = { PRODUCTCODE: productId, PROPOSALNUM: proposalNum, USERID: userId, ADDTNFIELD1: addtnField1}
                    result = doJSONPost('/generateSerialNumber.run', paymentHash.to_json)
                    p "result==========#{result}"
                    if result.to_s != ""
                        responseHash = Rho::JSON.parse(result.to_s)
                    policyNum = responseHash["APPNUM"].to_s if responseHash.has_key?("APPNUM")
                    p "policyNum=====#{policyNum}"
                    end
                    responseHash['data'] = {}
                    responseHash['data']['applicationNum'] = policyNum
                    responseHash['success'] = true
                    responseHash['message'] = "Successful"
                    # MobiSys::BrowserHelper.addUserActivityHelper('GENERATEAPPLICATIONNUM', @params, 'POLICY', @policy.proposalNum)
                    
                rescue StandardError => se
                    puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    responseHash['success'] = false
                    responseHash['message'] = "Exception in doJSONPost:"
                    # if $userordeviceDeactivated == true
                    #     WebView.navigate("/app/AgentReg/userordeviceDeactivated")
                    # elsif $appDbMismatchFlag == true
                    #     Alert.show_popup({
                    #         :message => getLabelValue('UPGRADEAPPLICATION'),
                    #         :title => '',
                    #         :icon => :info,
                    #         :buttons => ["OK"]
                    #     })
                    # elsif $redirectionFlag
                    #     Alert.show_popup({
                    #         :message => getLabelValue('SERVERERROR'),
                    #         :title => '',
                    #         :icon => :info,
                    #         :buttons => [getLabelValue('OK')]
                    #     })
                    # end
                end
            else
                results="USERLICENSECHECK"
                # logError($errors,'USERLICENSECHECK',getLabelValue('USERLICENSECHECK'))
                # WebView.navigate('/app/AgentReg/licenseLoginRedirect')
            end
        else
            results="ERR_NETWORK"
        end
        if results == "ERR_NETWORK"
            responseHash['success'] = false
            responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_NETWORK')
        elsif results == "USERLICENSECHECK"
            responseHash['success'] = false
            responseHash['message'] = MobiSys::BrowserHelper.getLabel('USERLICENSECHECK')
        end
        render :string => responseHash.to_json
    end

    # def validateLicenseType   #SUNSS 2405 new
    #     currentAgent = AgentReg.getCurrentAgentReg
    #     @currentAgentId = currentAgent.agentId
    #     agentLicenseType = currentAgent.licenseType.to_s          
    #     result = doJSONPost('/checkAgentLicense.run', @currentAgentId)
    #         if result.to_s != ""
    #             responseHash = Rho::JSON.parse(result.to_s)
    #             licenseValue = responseHash["LICENSEVALUE"].to_s if responseHash.has_key?("LICENSEVALUE")
    #         else
    #             licenseValue = ""
    #         end
    #         p "licenseValue=====#{licenseValue}"
    #         if (licenseValue.to_s == "" || licenseValue.to_s != agentLicenseType)
    #             # addError($errors,'USERLICENSECHECK',getLabelValue('USERLICENSECHECK'))
    #             # WebView.navigate('/app/AgentReg/licenseLoginRedirect')
    #             return false 
    #         end
    #     return true 
    # end

    def autoUnderwrite(id, parsedData)
        policy = @baseIO.baseDO
        p "policy=====#{policy}"
        # PolicyUnderwriting polUw = PolicyUnderwriting.new
        # polUw.setPolicyIO(this.io);
        # polUw.autoUnderwrite();
        autoUWRule = PolicyUtil::AutoUWUtil.new
        serviceDocumentList = []
        serviceDocumentList = autoUWRule.execute(policy, serviceDocumentList)

		if(policy.uwDecisionCd.to_s == "")
            policy.uwDecisionCd = policy.overallUWDecisionCd
			# policyIO.getBaseDO().setUwDecisionCd(policyIO.getBaseDO().getOverallUWDecisionCd());
        end
        p "policy================#{policy}"
    end

    def unlockPolicy
        p "inside unlock policy****************#{@params}"
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        p "policy=========#{@policy}"
        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => @policy.guid})
        if signatureContainer
            signatureContainer.ServiceSignatureList.each do|servSign|
              if servSign.to_s != "" && servSign.signatureTypeCd != "AGENTDECLARATION" #&& servSign.removed=="YES"
                  servSign.destroy  
              end
            end
            signatureContainer.ServiceSignatureList.each do|servSignRemove|
              if servSignRemove.to_s != "" && servSignRemove.signatureTypeCd != "AGENTDECLARATION" #&& servSignRemove.removed=="YES"
                signatureContainer.removeServiceSignature(servSignRemove) 
              end
            end
            signatureContainer.destroy if signatureContainer.ServiceSignatureList.size <= 0
            entity.signatureStatus = ""
        end
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        decoupling = true
        @errorTabList = @errorTabs.to_s.split(",") if @errorTabs.to_s != ""
        if @errorTabList
            @errorTabList.each do |tabId|
                if tabId.to_s != ""
                    if tabId.to_s != "tab_requirement" && tabId.to_s != "tab_agentDeclaration"
                        decoupling = false
                        break
                    end
                end
            end
        end
        p "decoupling======#{decoupling}"
        @policy.proposalSignedDt = ""
        @policy.uwDecisionCd = "PENDING"
        @policy.overallUWDecisionCd = ""
        @policy.insuredUWDecisionCd = ""
        @policy.financerUWDecisionCd = ""
        if decoupling
            @policy.statusCd = "COMPLETED"
        else
            @policy.statusCd = "PENDING"
        end
        @policy.persistAll
        p "@policy======#{@policy}"
        process
    end

    def getCSASeq
        parsedData = parseRequestBodyParams
        responseHash = {}
        fnaId = parsedData["fnaId"] if parsedData.has_key?("fnaId")
        fnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=> fnaId.to_s}) if fnaId
        if fnaRequest
            responseHash = {"success" => true,
                            "data" => {"cffSeq" => fnaRequest.object}}
        else
            responseHash = {"success" => false,
                            "message" => "fnaRequest not found."}
        end
        render :string => responseHash.to_json
    end
end

begin
    require 'Policy/policy_controller_company'
rescue LoadError => e
    puts 'policy_controller_company not included'
end

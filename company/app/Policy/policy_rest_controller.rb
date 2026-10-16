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
require 'Policy/PolicyCopyData'
require 'base64'

class PolicyController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
        # logInfo "~~~in policy rest initialize"
        super(MobiSys::IO::PolicyIO.new, "Policy")
        @listLookupsToBeFiltered = []
        @listLookupsToBeFiltered << "CURRENCYMASTER"
        @listLookupsToBeFiltered << "PLANOPTION"
        @listLookupsToBeFiltered << "FUND"
        @listLookupsToBeFiltered << "PREMIUMTYPE"
        @listLookupsToBeFiltered << "FREQUENCY"
        @listLookupsToBeFiltered << "RIDERPRODUCT"
    end

    def fetch(id)
        policy = Policy.loadObject(:first, :conditions => {:object => id})
    	@baseIO.baseDO = policy
        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.entityTypeCd = "POLICY"  
    end

    def init
        # logInfo "~~~~formData n quotation init:"
        $currentProduct = nil
        $rhoconfig[:moduleForProductValidations] = "Policy"
    end

    def process
    	policy = @baseIO.baseDO

        if policy.statusCd.to_s == "SUBMITTED_UWCOMPLETE"
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            #RhoLog.error("PROCESS","has_network :- #{has_network}")
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
    	$currentProduct ||= ProductUtil.getProduct(policy.baseProductSeq)
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

        if policy.action.to_s == ""
            policy.action = "Save"
        end
        policy.persistAll

    end

    def isCompleted
        isCompleted = false
        if (@baseIO.baseDO.statusCd == "SUBMITTED") || (@baseIO.baseDO.statusCd == "SUBMITTED_UWCOMPLETE") #|| @baseIO.baseDO.statusCd == "COMPLETED")
            isCompleted = true
        end
        return isCompleted
    end

    def isInvalid
        isInvalid = false
        # in case of non face to face,if login user and allocated user are different then it is invalid scenario.
        policy = @baseIO.baseDO
        if($rhoconfig[:nonFaceToFace] && $rhoconfig[:nonFaceToFace].actionValue.to_s == "YES")
            puts "policy.allocatedToRole.to_s :- #{policy.allocatedToRole.to_s}"
            puts "AgentReg.getCurrentAgentReg.userType.to_s :- #{AgentReg.getCurrentAgentReg.userType.to_s}"

            if(policy.allocatedToRole.to_s != "" && "AGENT" != policy.allocatedToRole.to_s) #hardcoding AGENT as currently it is not passed from online to offline
            # if(policy.allocatedToRole.to_s != "" && AgentReg.getCurrentAgentReg.userType.to_s != policy.allocatedToRole.to_s)
                isInvalid = true
                invalidReason = ""

                # The Proposal is currently allocated to Proposer - Shital Durgade and cannot be modified. Please Revoke to continue.
                if(AgentReg.getCurrentAgentReg.userType.to_s == "AGENT")
                    allocatedParty = policy.getPartyByGuid(policy.allocatedToPartyGuid)
                    invalidReason = getLabelValue("agentInvalidReason",[policy.allocatedToRole,allocatedParty.getFullName]).to_s
                else
                    invalidReason = getLabelValue("customerInvalidReason").to_s
                    #The Proposal can no longer be modified by you. Please check with your Advisor in case of any queries.
                end
            end
        end
        # Status will be set to LOCKED when we want to edit quotation from policy
        if policy.statusCd.to_s == "LOCKED"
            isInvalid = true
            invalidReason = getLabelValue("policyLockInvalidReason").to_s
        end
        policy.invalidReason = invalidReason
        return isInvalid
    end

    def validate
        puts "Validate Called!"
        policy = @baseIO.baseDO
        $currentProduct ||= ProductUtil.getProduct(policy.baseProductSeq)
        policy.action = "Validate"
        validatePolicy(policy)
        puts "Validation Complete!"


    end

    def validatePolicy(policy)
        primary = policy.getParty("PRIMARY")
        primaryPartyRole = policy.getPolicyPartyRole("PRIMARY")
        guid = primary.guid if primary
        primaryPartyRelation = []

        policy.PartyList.each do |party|
            if party.roleCd == "PRIMARY" || (party.roleCd == "PROPOSER" && primaryPartyRole.partySameAsCd == "PROPOSER")
                next
            else
                if party.PartyRelationList.size == 0
                    party.addPartyRelation(PartyRelation.new(:roleCd => party.roleCd, :relationCd => party.relationCd, :relatedToPartyId => guid))
                    primaryPartyRelation.push(PartyRelation.new(:roleCd => primary.roleCd, :relationCd => party.relationCd, :relatedToPartyId => party.guid))
                else
                    party.PartyRelationList.each do |partyRelation|
                        partyRelation.relationCd = party.relationCd
                        primaryPartyRelation.push(PartyRelation.new(:roleCd => primary.roleCd, :relationCd => party.relationCd, :relatedToPartyId => party.guid))
                        break
                    end
                end
            end
        end
       
        if primary && primary.PartyRelationList.size == 0
            primaryPartyRelation.each do |primaryRelation|
                primary.addPartyRelation(primaryRelation)
            end
        else
            if primary
                primary.PartyRelationList.each do |primaryRelation1|
                    primaryPartyRelation.each do |primaryRelation2|
                        if primaryRelation1.relatedToPartyId == primaryRelation2.relatedToPartyId
                            primaryRelation2.relationCd = primaryRelation1.relationCd
                            break
                        end
                    end
                end
            end    
        end

        policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if policy.proposalNum.to_s == ""
        MobiSys::PolicyService.createPolicyProductInsured(policy)

        primaryInsuredPolicyPartyRole = policy.getPolicyPartyRole("PRIMARY")
        proposerParty = policy.getParty("PROPOSER")
        if primaryInsuredPolicyPartyRole
            if primaryInsuredPolicyPartyRole.partySameAsCd.to_s == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd.to_s == "PROPOSER"
                primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                primaryInsuredPolicyPartyRole.refGuid = proposerParty.guid if proposerParty
            else
                primaryInsuredPolicyPartyRole.partySameAsCd = nil
                insured = nil
                policy.PartyList.each do |party|
                    if party.roleCd == "PRIMARY"
                        insured = party
                        break
                    end
                end
                primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
            end
        elsif !MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct) && proposerParty
            policy.addPolicyPartyRole(PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => proposerParty.uniqueKey, :partySameAsCd => "PROPOSER"))
        end

        MobiSys::PolicyService.submitPlanDetails(policy)
        MobiSys::PolicyService.submitSupplementary(policy)

        policy.PartyList.each do |party|
            if party.visitedTabs.to_s == ""
                party.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",party.roleCd)
            end
            #To set entityDesc for party children for new party objects before save
            MobiSys::PolicyService.setPartyDesc(party)
        end
        policy.PolicyProductList.each do|policyProduct|
            if policyProduct.visitedTabs.to_s == ""
                policyProduct.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",policyProduct.productTypeCd)
            end
        end
        MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
        $responseHash = {}
        policy.PartyList.each do |party|
            questionContainer = QuestionContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'} => party.guid,
                                    {:name=>'policyGuid'} => policy.uniqueKey
                                },
                                :op=>'AND'
                                )
            # p "questionContainer====#{questionContainer}"
        $responseHash = MobiSys::Questionnaire.setupResponseHash(questionContainer) if questionContainer
            # p "$responseHash====#{$responseHash}"
        end
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(policy)


    end

    def computeAge
        parsedData = parseRequestBodyParams
        dob = age = nil
        dob = parsedData['dob'] if parsedData.has_key?("dob")
        age = parsedData['age'] if parsedData.has_key?("age")
        responseHash = {}

        if dob.to_s != ""
            birthDt = getScreenDate(Time.at(dob/1000).to_s) if parsedData['dob'].to_s != ""
            referenceDt = getScreenDate(Time.at(parsedData['referenceDate']/1000).to_s) if parsedData["referenceDate"].to_s != ""
            commencementDt = (referenceDt.to_s != "" ? referenceDt : getScreenDate(Time.new.to_s))
            age = 0
            if birthDt != nil and commencementDt != nil
                age = MobiSys::ProductUtil.getAge(birthDt, MobiSys::ProductUtil::LASTBIRTHDAY, commencementDt)
                age = age.split("|")[0]
            end

            responseHash['data'] = {"age" => age.to_i}
        elsif age.to_s != ""
            referenceDt = Time.at(parsedData['referenceDate']/1000) if parsedData["referenceDate"].to_s != ""
            commencementDt = (referenceDt.to_s != "" ? referenceDt : Time.now)
            dt = MobiSys::ProductUtil.calculateDOB(age, commencementDt)
            d = DateTime.parse(dt.to_s)
            birthDt = d.strftime('%Q').to_i

            responseHash['data'] = {"dob" => birthDt}
        end

        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def getDocumentPartyList
    	parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        baseProduct = policy.getBaseProduct
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
        responseHash = {}
        partyNames = policy.getPartyNames("tab_requirement")
        partyDetails = []
        if partyNames != nil
        	partyNames.each do |key, val|
        		partyValue = val.to_s.split("-")
        		tempHash = {'partyGuid' => key.to_s, 'partyName' => partyValue[1], 'partyRole' => partyValue[0]}
        		partyDetails.push(tempHash)
        	end
        end

        responseHash["data"] = {'documentPartyList' => partyDetails}
		responseHash['success'] = true
		responseHash['message'] = "Successful"

	    render :string => responseHash.to_json
    end

    def callPaymentGateWay
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isValid = true
        responseHash = {}
        # if dbPolicy.statusCd == "PENDING" || dbPolicy.statusCd == "COMPLETE"
        #     newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        #     unless newPolicy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
        #         newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['currentTab']
        #     end
        #     # Check for empty party objects and set them as removed
        #     newPolicy.PartyList.each do |party|
        #         setPartyDetails(party)
        #     end
        #     submitBeneficiaryAppointeeDetails(newPolicy)
        #     submitPaymentDetails(newPolicy)
        #     submitQuestionnaire(newPolicy)
        #     newPolicy.persistAll

        #     @policy = dbPolicy
        #     @policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if @policy.proposalNum.to_s == ""
        #     createPolicyProductInsured(@policy)
        #     primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
        #     if primaryInsuredPolicyPartyRole
        #         if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
        #             primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
        #             primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
        #         else
        #             primaryInsuredPolicyPartyRole.partySameAsCd = nil
        #             insured = nil
        #             @policy.PartyList.each do |party|
        #                 if party.roleCd == "PRIMARY"
        #                     insured = party
        #                     break
        #                 end
        #             end
        #             primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
        #         end
        #     end
        #     submitPlanDetails(@policy)
        #     submitRequirements if @params.has_key?('DocumentContainer')
        #     submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
        #     submitSignatureTab(@policy) if @params.has_key?('SignatureContainer') && !@params.has_key?('QuestionContainer')
        #     MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
        #     MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
        #     policyNum = ""
        #     @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        #     isValid = false unless @errors.empty?
        # else
        #     @policy = dbPolicy
        # end

        if isValid && policy.proposalSignedDt.to_s != "" && policy.signatureStatus == "SUCCESS"
            ##### Fetch inward DO then serialize to JSON and send to online  #####
            payer = policy.getPayerParty("INITIAL")
            inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
            syncEntities = Hash.new
            syncEntities[Inward.onlineClassName] = ::JSON.generate([{Inward.onlineClassName => [inward.hashForSync]}.to_json])
            syncEntities[Party.onlineClassName] = ::JSON.generate([{Party.onlineClassName => [payer.hashForSync]}.to_json])
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            offlineEntities = Hash.new
            offlineEntities[inward.class.name.to_s+ inward.guid.to_s] = inward
            offlineEntities[payer.class.name.to_s+ payer.guid.to_s] = payer
            if has_network
                begin
                    clazz = Class.new do
                    include MobiSys::BrowserHelper
                    end
                    obj = clazz.new
                    response = obj.doJSONPost('/PaymentGateway.run', ::JSON.generate(syncEntities))
                    if response.to_s != ''
                        resultsHash = Rho::JSON.parse(response)
                    else
                        resultsHash = {}
                    end
                    resultsHash.each do |key,value|
                        if value.to_s != ""
                            entities = Rho::JSON.parse(value)
                        else
                            entities = []
                        end
                        if offlineEntities
                            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                            db.start_transaction
                            entities.each do |entity|
                                className = entity["class"].slice((entity["class"].rindex('.')+1)..(entity["class"].rindex('DO')-1))
                                offlineEntity = offlineEntities[className+entity['guid']]
                                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
                                if onlineEntity.versionID == -1 and offlineEntity
                                    offlineEntity.destroy
                                elsif offlineEntity
                                    offlineEntity.merge(onlineEntity)
                                    offlineEntity.persist('fromSync')
                                    if offlineEntity.respond_to?('afterSync'.to_sym)
                                        offlineEntity.afterSync
                                    end
                                else
                                    onlineEntity.persist
                                    if onlineEntity.respond_to?('afterSync'.to_sym)
                                        onlineEntity.afterSync
                                    end
                                end
                            end
                            db.commit
                        end
                    end

                rescue StandardError => se
                    puts "Error while generating entities hash for sync =>" + se.to_s
                    responseHash['success'] = false
                    responseHash['message'] = "Error while generating entities hash for sync"
                    # Alert.show_popup({
                    #     :message => getLabelValue('SERVERERROR'),
                    #     :title => '',
                    #     :icon => :info,
                    #     :buttons => ["OK"]
                    # })
                    # isValid = false
                    # WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => {:submit => ''})
                end
            else
                results="ERR_NETWORK"
            end
            if results == "PAYMENT_SUCESS"
                responseHash['success'] = true
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('SUCCESS_PAYRECEIVED')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('SUCCESS_PAYRECEIVED'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif results == "ERR_AGENT"
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_AGENTPAYMENT')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('ERR_AGENTPAYMENT'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif results == "ERR_NETWORK"
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_NETWORK')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORK'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif results == "ERR_STP"
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_STP')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('ERR_STP'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif results == "CURR_RATE_REQ_ERROR"
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('CURR_RATE_REQ_ERROR')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('CURR_RATE_REQ_ERROR'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif results == "TXN_NUM_REQ_ERROR"
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('TXN_NUM_REQ_ERROR')
                # Alert.show_popup( {
                #     :message => MobiSys::BrowserHelper.getLabel('TXN_NUM_REQ_ERROR'),
                #     :title => '',
                #     :icon => :info,
                #     :buttons => ["OK"] } )
            elsif isValid
                htmlContent = "<!DOCTYPE html><html><body><form id='paymentSubmit' name='paymentSubmit' action='#{Application.getValue('online_server_url').value}/jsp/TPLoginUser.jsp?&redirectPage=..%2FPaymentGatewayInvoke.run' method='POST'><input type='hidden' name='userId' id='userId' value='#{$userId}'></input><input type='hidden' name='password' id='password' value='#{$userPassword}'></input><input type='hidden' name='fileName' id='fileName' value='#{inward.fileName}'></input></form></body></html><script>document.getElementById('paymentSubmit').submit();</script>"

                # paymentFilePath = Rho::RhoFile.join(Rho::Application.userFolder, 'payment.html')
                # file = File.open(paymentFilePath,"w")
                # file.write(htmlContent)
                # file.close

                # System.open_url(paymentFilePath)

                if policy.isBackdatedFl.to_s == "YES"
                    policy.policyCommencementDt = policy.quotationDt
                else
                    policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                if policy.isBackdatedFl.to_s == "YES"
                    policy.riskCommencementDt = policy.quotationDt
                else
                    policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end
                policy.persistAll
                responseHash['data'] = htmlContent
                responseHash['success'] = true
                responseHash['message'] = "Successful"
            end
            # WebView.navigate(url_for :action => :showProposal, :id => policy.object)
        else
            responseHash['success'] = false
            responseHash['message'] = "Please resolve all warnings & sign before online payment."
            # Alert.show_popup({
            #     :message => "Please resolve all warnings & sign before online payment.",
            #     :title => '',
            #     :icon => :info,
            #     :buttons => ["OK"]
            # })
            # WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => {:submit => ''})
        end
	    render :string => responseHash.to_json
    end

    def checkPaymentStatus_jeet
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        responseHash = {}
        if policy.statusCd == "PAYMENTDONE"
            responseHash['success'] = true
            responseHash['message'] = "Your payment is successful. Please note transaction no. 457891230 for future reference."
        else
            responseHash['success'] = false
            responseHash['message'] = getLabelValue("PAYMENTFAILED",[]).to_s
        end

	    render :string => responseHash.to_json
    end
    ##################################################################################################
    def checkPaymentStatus
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isPoll = (parsedData.has_key?("isPoll") ? parsedData["isPoll"] : false)
        pollCount = $rhoconfig[:paymentPollCount].to_i #Number of hits to the online server
        pollInterval = $rhoconfig[:paymentPollInterval].to_i #Interval after which to hit the online server again
        @success = true
        @message = "Successful"
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)

        if policy and (policy.statusCd.to_s == "PAYMENTPENDING" || policy.statusCd.to_s == "PAYMENTFAILED")
            if isPoll
                (1..pollCount).each do |n|
                    #Hit the online server for updated payment status
                    MobiSys::PolicyService.updatePaymentStatus(policy)
                    break if (policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "PAYMENTSUCCESS")
                    sleep(pollInterval)
                end
            else
                #Hit the online server for updated payment status
                MobiSys::PolicyService.updatePaymentStatus(policy)
            end
        end

        if(policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "PAYMENTSUCCESS")
            @message = "Your payment is successful. Please note transaction number for future reference."
        else
            @success = false
            @message = getLabelValue("PAYMENTFAILED").to_s
        end
        #Get Data for Response
        fetchData(parsedData,true,isMetadataRequired)
        responseHash = generateResponseHash(true)

        render :string => responseHash.to_json
    end
    ################################################################################

    def getPartyDocument
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        lifeGuid = parsedData['partyGuid'].to_s
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
        if lifeGuid != ""
            life = policy.getPartyByGuid(lifeGuid)
            lifePartyRole = nil
            policy.PolicyPartyRoleList.each do |ppr|
                if ppr.refGuid == lifeGuid
                    lifePartyRole = ppr
                    break
                end
            end
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
            policyPayment = policy.getPolicyPayment("RENEWALPREMIUM")
            if policyPayment != nil && (lifePartyRole.roleCd == "PROPOSER" || lifePartyRole.roleCd == "PAYER") && baseProduct != nil
                baseProduct.paymentMethodCd = policyPayment.paymentMethodCd
            end

            if baseProduct
                originalPartyRole = baseProduct.partyRoleCd
                originalInsureRefGuid = baseProduct.insuredPartyRefGuid
                originalCombinedEntryAge = baseProduct.combinedEntryAge
                baseProduct.partyRoleCd = lifePartyRole.roleCd
                if lifePartyRole.roleCd == "SUPPLEMENTARY" || lifePartyRole.roleCd == "NOMINEE"
                    baseProduct.insuredPartyRefGuid = life.object
                    baseProduct.combinedEntryAge = life.age
                end
            end

            facetObj = $rhoconfig[:multiDocMode]
            if facetObj && facetObj.actionValue.to_s == 'YES'
                multiDocMode = true
            else
                multiDocMode = false
            end

            categoriesDerivedFromDT = []
            for i in 0..20
                if i == 0
                    i = ""
                end
                nbReqName = "NBREQUIRMENTS" << i.to_s
                offlineFacet = $currentProduct.getFacet(nbReqName)
                if  (offlineFacet && offlineFacet.applicableRoles.to_s == "" ) || (offlineFacet  && offlineFacet.applicableRoles.to_s.split(",").include?(life.roleCd.to_s))
                    ttms = $currentProduct.getTableTypeMappingSeq(nbReqName)
                    defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true, true)
                    defTables.each do |defTable|
                        if defTable.documentCategoryCd.to_s != ''
                            categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                        end
                    end
                    insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
                    if insuredPartyRole
                        proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
                    end
                    if proposerIsSameAsInsured
                        tempCurrRoleCd = life.roleCd
                        life.roleCd = insuredPartyRole.roleCd.to_s
                        defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true, true)
                        defTables.each do |defTable|
                            if defTable.documentCategoryCd.to_s != ''
                                categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                                categoriesDerivedFromDT = categoriesDerivedFromDT.uniq
                            end
                        end
                        life.roleCd = tempCurrRoleCd
                    end
                end
            end
            categoriesDerivedFromDT = categoriesDerivedFromDT.flatten.uniq
            container = DocumentContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>life.guid, {:name=>'policyGuid'} => policy.guid},:op => 'AND')

            documentImage = Hash.new
            documentListArray = []
            metadataHash = {}
            @lookupHash = {}
            tempHash = {}

            if container != nil
                existingServiceDocumentList = {}
                if multiDocMode
                    container.ServiceDocumentList.each do |serviceDocument|
                        existingServiceDocumentList["#{serviceDocument.docCategoryCd}|#{serviceDocument.documentCd}"] = serviceDocument
                        categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
                    end
                    categoriesDerivedFromDT.each do |docCategory|
                        documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd, dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory <<"';")
                        documents.sort_by!{|document| document.sortOrder.to_i}
                        docCatDocument = existingServiceDocumentList.select{|key| key.include? docCategory}
                        documents.each do |document|
                            if existingServiceDocumentList["#{docCategory}|#{document.documentCd}"].to_s != ''
                                serviceDocument = existingServiceDocumentList["#{docCategory}|#{document.documentCd}"]
                                serviceDocument.docDescription = document.documentDesc
                                #New Code for Document Image
                                documentImage = DocumentImage.getDocumentImages(serviceDocument.guid)
                                methodName = "DocumentImageList="
                                serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                                if documentImage
                                    serviceDocument.send(methodName, documentImage.collect{|x| x.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }})
                                else
                                    serviceDocument.send(methodName,[])
                                end
                                tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                                documentListArray << tempHash["ServiceDocumentList"]
                            else
                                serviceDocument = ServiceDocument.new
                                serviceDocument.partyGuid = life.guid
                                serviceDocument.docCategoryTypeCd = document.categoryTypeCd
                                serviceDocument.docCategoryCd = docCategory
                                serviceDocument.documentCd = document.documentCd
                                serviceDocument.docDescription = document.documentDesc
                                serviceDocument.acceptanceStatusCd = "PENDING"
                                serviceDocument.isAutoGeneratedFl = "YES"
                                #add DocumentImage key to Document
                                methodName = "DocumentImageList="
                                serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                                    serviceDocument.send(methodName,[])
                                tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                                container.addServiceDocument(serviceDocument)
                                documentListArray << tempHash["ServiceDocumentList"] if docCatDocument.size == 0
                            end

                            if isMetadataRequired && (docCatDocument.size == 0 || existingServiceDocumentList["#{docCategory}|#{document.documentCd}"].to_s != '')
                                evaluateContextForObject(serviceDocument)
                                metadataHash.merge!(processMetadata(serviceDocument))
                                contextEnd
                            end
                        end
                    end
                else
                    existingServiceDocumentList = container.ServiceDocumentList.group_by{|serviceDocument| serviceDocument.docCategoryCd}
                    container.ServiceDocumentList.each do |serviceDocument|
                        categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
                    end
                    categoriesDerivedFromDT.each do |docCategory|
                        documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory <<"';")
                        documents.sort_by!{|document| document.sortOrder.to_i}
                        if existingServiceDocumentList[docCategory].to_s != ''
                            serviceDocument = existingServiceDocumentList[docCategory][0]
                            serviceDocument.receivedDt = getScreenDate(serviceDocument.receivedDt) if serviceDocument.receivedDt
                            #New Code for Document Image
                            documentImage = DocumentImage.getDocumentImages(serviceDocument.guid)
                            methodName = "DocumentImageList="
                            serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                            if documentImage
                                serviceDocument.send(methodName, documentImage.collect{|x| x.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }})
                            else
                                serviceDocument.send(methodName, [])
                            end
                            tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                            documentListArray << tempHash["ServiceDocumentList"]
                        else
                            serviceDocument = ServiceDocument.new
                            serviceDocument.partyGuid = life.guid
                            serviceDocument.docCategoryTypeCd = documents.first.categoryTypeCd
                            serviceDocument.docCategoryCd = docCategory
                            serviceDocument.acceptanceStatusCd = "PENDING"
                            serviceDocument.isAutoGeneratedFl = "YES"
                            methodName = "DocumentImageList="
                            serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                            serviceDocument.send(methodName, [])
                            tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                            container.addServiceDocument(serviceDocument)
                            documentListArray << tempHash["ServiceDocumentList"]
                        end

                        if isMetadataRequired
                            evaluateContextForObject(serviceDocument)
                            metadataHash.merge!(processMetadata(serviceDocument))
                            contextEnd
                        end
                    end
                end
            else
                container = DocumentContainer.new
                container.entityGuid = life.guid
                container.entityTypeCd = life.class.name.to_s
                container.policyGuid = policy.guid
                if multiDocMode
                    categoriesDerivedFromDT.each do |docCategory|
                        documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd, dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '"<< docCategory <<"';")
                        documents.sort_by!{|document| document.sortOrder.to_i}
                        documents.each do |document|
                            serviceDocument = ServiceDocument.new
                            serviceDocument.partyGuid = life.guid
                            serviceDocument.docCategoryTypeCd = document.categoryTypeCd
                            serviceDocument.docCategoryCd = docCategory
                            serviceDocument.documentCd = document.documentCd
                            serviceDocument.docDescription = document.documentDesc
                            serviceDocument.acceptanceStatusCd = "PENDING"
                            serviceDocument.isAutoGeneratedFl = "YES"
                            methodName = "DocumentImageList="
                            serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                            serviceDocument.send(methodName, [])
                            tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                            container.addServiceDocument(serviceDocument)

                            documentListArray << tempHash["ServiceDocumentList"]
                            if isMetadataRequired
                                evaluateContextForObject(serviceDocument)
                                metadataHash.merge!(processMetadata(serviceDocument))
                                contextEnd
                            end
                        end
                    end
                else
                    categoriesDerivedFromDT.each do |docCategory|
                        documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '"<< docCategory <<"';")
                        documents.sort_by!{|document| document.sortOrder.to_i}
                        serviceDocument = ServiceDocument.new
                        serviceDocument.partyGuid = life.guid
                        serviceDocument.docCategoryTypeCd = documents[0].categoryTypeCd
                        serviceDocument.docCategoryCd = docCategory
                        serviceDocument.acceptanceStatusCd = "PENDING"
                        serviceDocument.isAutoGeneratedFl = "YES"
                        container.addServiceDocument(serviceDocument)
                        methodName = "DocumentImageList="
                        serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                        serviceDocument.send(methodName, [])
                        tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false,["DocumentImageList"]).select {|key| !["class","userId"].include? key.to_s }
                        documentListArray << tempHash["ServiceDocumentList"]
                        if isMetadataRequired
                            evaluateContextForObject(serviceDocument)
                            metadataHash.merge!(processMetadata(serviceDocument))
                            contextEnd
                        end
                    end
                end
            end
            if $lookupArray
                $lookupArray.uniq.each do |lookup|
                    addToLookupHash(lookup)
                end
            end

            responseHash = {"data" => {"documentList" => documentListArray}, "metadata" => metadataHash,"lookups" => @lookupHash, "success" => true, "message" => "Successful"}
        else
            responseHash = {"success" => false, "message" => "Party Guid missing"}
        end

        render :string => responseHash.to_json
    end

    def addNominee
        parsedData = parseRequestBodyParams
        responseHash = {}
        @metadataHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        @createNewObject = true
        @addEntity = true
        @entityHash = {}
        parsedData = parseRequestBodyParams
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        modelHash = $PolicyDataXMLHash['Entity']['children']['NomineeList']
        nomineeChildren = $PolicyDataXMLHash['Entity']['children']["NomineeList"].has_key?("children") ? $PolicyDataXMLHash['Entity']['children']["NomineeList"]["children"].keys : []
        nomineeHash = processModel(modelHash,policy,"NomineeList",{},isMetadataRequired)
        @entityHash['Nominee'] = nomineeHash[0].hashForApi(false, nomineeChildren).select {|key| !["class","userId"].include? key.to_s } if nomineeHash != nil
        if isMetadataRequired
            partySameAsList = Lookupvalue.getValue("PARTYSAMEAS")
            partySameAsList.each{|partySameAs| addToLookupHash(partySameAs.key.to_s) }
        end
        @success = true
        @message = "Successful"
        responseHash = generateResponseHash(true)
        render :string => responseHash.to_json
    end

    def addServiceSignature
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        signatureHash = {}
        @lookupHash = {}
        party = nil
        validRoleCds = ["PROPOSER","PRIMARY","SUPPLEMENTARY","AGENT"]

        if policy
            if parsedData['roleCd'].to_s != "" && !validRoleCds.include?(parsedData['roleCd'].to_s)
                signatureHash['success'] = false
                signatureHash['message'] = "Invalid Role Code"
            elsif parsedData['signatureTypeCd'].to_s != "" && parsedData['roleCd'] != ""
                #Check if present in db else create new
                signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => policy.guid
                                        }
                                )
                signature = signatureContainer.ServiceSignatureList.select{ |s| s.roleCd == parsedData["roleCd"] }.first if signatureContainer != nil

                signature = ServiceSignature.new(:signatureTypeCd => parsedData['signatureTypeCd'], :entityGuid => policy.guid , :roleCd => parsedData['roleCd'], :entityType => @entityClass) if signature == nil

                if parsedData['roleCd'].to_s == "PROPOSER" || parsedData['roleCd'].to_s == "PRIMARY" || parsedData['roleCd'].to_s == "SUPPLEMENTARY"
                    party = Party.loadObject(:first,
                                    :conditions => {
                                        :roleCd => parsedData['roleCd'],
                                        :parentKey => policy.object
                                    }
                                )
                end

                signatureArray = [signature]
                if party != nil
                    methodName = "ServiceSignature="
                    party.instance_eval { class << self; self end }.send(:attr_accessor, "ServiceSignature") unless party.respond_to? methodName
                    party.send(methodName,signatureArray.hashForApi(false))
                    signatureHash[parsedData['roleCd'].downcase.capitalize] = party.hashForApi(false,["ServiceSignature"])
                else
                    signatureHash["data"] = {"ServiceSignature" => signatureArray.hashForApi(false)}
                end

                isMetadataRequired = true
                if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                    isMetadataRequired = false
                end

                if isMetadataRequired
                    metadataHash = {}
                    if party != nil
                        evaluateContextForObject(party)
                        evaluateContextForObject(signature)
                        signatureHash["metadata"] = metadataHash.merge!(processMetadata(party))
                        signatureHash["metadata"] = metadataHash.merge!(processMetadata(signature))
                        contextEnd
                    else
                        evaluateContextForObject(signature)
                        signatureHash["metadata"] = metadataHash.merge!(processMetadata(signature))
                    end
                    if $lookupArray
                        $lookupArray.uniq.each do |lookup|
                            addToLookupHash(lookup)
                        end
                    end
                    signatureHash["lookups"] = @lookupHash
                    contextEnd
                end
                signatureHash["success"] = true
                signatureHash["message"] = "Successful"
            else
                signatureHash["success"] = false
                signatureHash["message"] = "Data is missing"
            end
        else
            signatureHash["success"] = false
            signatureHash["message"] = "Policy not found"
        end

        render :string => signatureHash.to_json
    end

    def acceptServiceSignature
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        signatureHash = {}
        signatureHash["success"] = false
        signatureHash["message"] = "Policy not found"

        if policy
            fetchData(parsedData, false, false) if parsedData.has_key?("FormData")
            signatureContainer = SignatureContainer.loadObject(:first,
                :conditions => {
                    :entityGuid => policy.guid
                }
                )

            if signatureContainer
                errors = Hash.new
                MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
                # unless policy.visitedTabs.to_s.include?('tab_signature')
                #     policy.visitedTabs = policy.visitedTabs.to_s + "," + 'tab_signature'
                # end
                policy.persistAll
                errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, policy.visitedTabs)
                if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                    policy.signatureStatus = "SIGNED"
                    policy.proposalSignedDt = Time.new.strftime("%F 00:00:00 %z")
                    policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                    policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                    if policy.isBackdatedFl.to_s == "YES"
                        policy.policyCommencementDt = policy.quotationDt
                    else
                        policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                    end

                    if policy.isBackdatedFl.to_s == "YES"
                        policy.riskCommencementDt = policy.quotationDt
                    else
                        policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                    end
                    policy.persistAll
                    MobiSys::TrackLeadBO.updateTrackLead(policy)

                    signatureHash["success"] = true
                    signatureHash["message"] = "Successful"
                else
                    signatureHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
                    signatureHash["validationerrors"] = errors
                end
            else
                signatureHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
            end
        end

        render :string => signatureHash.to_json
    end

    def addAppointee
        parsedData = parseRequestBodyParams
        responseHash = {}
        @metadataHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        @addEntity = true
        @createNewObject = true
        @entityHash = {}
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        modelAttributes = $PolicyDataXMLHash["Entity"]["children"]["Appointee"]["attributes"]
        modelHash = $PolicyDataXMLHash['Entity']['children']['Appointee']
        appointeeChildren = $PolicyDataXMLHash['Entity']['children']["Appointee"].has_key?("children") ? $PolicyDataXMLHash['Entity']['children']["Appointee"]["children"].keys : []
        appointeeHash = processModel(modelHash,policy,"Appointee",{},isMetadataRequired)
        @entityHash['Appointee'] = appointeeHash.hashForApi(false, appointeeChildren).select {|key| !["class","userId"].include? key.to_s }
        @success = true
        @message = 'Successful'
        responseHash = generateResponseHash(isMetadataRequired)

        render :string => responseHash.to_json
    end

    def addPolicyParty
        parsedData = parseRequestBodyParams
        responseHash = {}
        @metadataHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        partyDetails = @params["addToNodeName"] if @params.has_key?("addToNodeName")
        policy = @baseIO.baseDO
        @addEntity = true
        @entityHash = {}
        @createNewObject = true
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        modelAttributes = $PolicyDataXMLHash["Entity"]["children"][partyDetails.to_s]["attributes"]
        modelHash = $PolicyDataXMLHash['Entity']['children'][partyDetails.to_s]
        partyChildren = $PolicyDataXMLHash['Entity']['children'][partyDetails.to_s].has_key?("children") ? $PolicyDataXMLHash['Entity']['children'][partyDetails.to_s]["children"].keys : []
        partyrHash = processModel(modelHash,policy,partyDetails.to_s,{},isMetadataRequired)
        @entityHash['Party'] = partyrHash.hashForApi(false, partyChildren).select {|key| !["class","userId"].include? key.to_s }
        @success = true
        @message = 'Successful'

        responseHash = generateResponseHash(isMetadataRequired)
        render :string => responseHash.to_json
    end

    def addPayer
        parsedData = parseRequestBodyParams
        responseHash = {}
        @metadataHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        @addEntity = true
        @entityHash = {}
        @createNewObject = true
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        modelAttributes = $PolicyDataXMLHash["Entity"]["children"]["InitialOtherPayerParty"]["attributes"]
        modelHash = $PolicyDataXMLHash['Entity']['children']['InitialOtherPayerParty']
        payerChildren = $PolicyDataXMLHash['Entity']['children']["InitialOtherPayerParty"].has_key?("children") ? $PolicyDataXMLHash['Entity']['children']["InitialOtherPayerParty"]["children"].keys : []
        payerHash = processModel(modelHash,policy,"InitialOtherPayerParty",{},isMetadataRequired)
        @entityHash['Payer'] = payerHash.hashForApi(false, payerChildren).select {|key| !["class","userId"].include? key.to_s }
        @success = true
        @message = 'Successful'

        responseHash = generateResponseHash(isMetadataRequired)
        render :string => responseHash.to_json
    end

    def eappPreview
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        process()
        fetchData(parsedData.reject { |k,v| k == "FormData" },true,false)
        responseHash["data"] = {}
        policy = @baseIO.baseDO
        baseProduct = policy.getBaseProduct
        quotation = MobiSys::PolicyBO.convertToQuotation(policy)
        quotationProduct = quotation.getBaseProduct
        party = quotation.getParty(quotationProduct)
        product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq.to_s)
        facetValue = MobiSys::ProductBO.evaluateProductFacet(product, "EAPPTEMPLATEID")
        templateFacetValue = nil
        if facetValue.to_s != ""
            if facetValue.is_a?(Integer)
                templateFacetValue = MobiSys::ProductBO.getFacetOutput(facetValue.to_i, quotation, quotationProduct, party)
            else
                templateFacetValue = facetValue.to_s
            end
        end
        templatePath = Rho::Application.userFolder + "Templates/#{templateFacetValue}/index.erb_enc"
        @baseIO.isFullHTMLRequired = parsedData["isFullHTMLRequired"].to_s != "" ? parsedData["isFullHTMLRequired"] : true
        @baseIO.bodyContent = ""
        @baseIO.cssContent = ""
        if templateFacetValue.to_s != ""
            if File.exists?(templatePath)
                html, this = evaluateEappTemplate(templateFacetValue, @entityHash)
                @baseIO.isTemplateBasedOutput = true
                @baseIO.htmlContent = []
                @baseIO.htmlContent.push html
                @baseIO.signatureList = this.eapp.Policy.ServiceSignatureList
                if @baseIO.isFullHTMLRequired
                    responseHash['data'] = {"EappHTMLPreview" => @baseIO.htmlContent.first}
                else
                    MobiSys::SymTemplateUtil.loadHTMLBodyContent(@baseIO.htmlContent.first, @baseIO.bodyContent, @baseIO.cssContent)
                    responseHash['data'] = { "EappHTMLPreview" => @baseIO.bodyContent, "htmlStyles" => @baseIO.cssContent }
                end
                responseHash['data']['signatureList'] = @baseIO.signatureList
            else
                template = TemplateMaster.loadObject(:first, :conditions=> {'templateId' => templateFacetValue})
                if template && template.zippedTemplateOffline.to_s != ""
                    compressed = Base64.strict_decode64(template.zippedTemplateOffline.to_s)
                    Rho::RhoFile.makeDir(Rho::RhoFile.join(Rho::Application.userFolder, "Templates")) unless Rho::RhoFile.exists(Rho::RhoFile.join(Rho::Application.userFolder, "Templates"))

                    filePath = Rho::RhoFile.join(Rho::Application.userFolder, "Templates/zippedTemplateOffline.zip")
                    file = File.open(filePath,"wb")
                    file.write(compressed)
                    file.close

                    result = Rho::System.unzipFile(filePath)
                    File.delete(filePath)

                    Dir.glob("#{Rho::Application.userFolder}Templates/#{templateFacetValue}/**/*.erb").each do |file|
                        encodedContent = MobiSys::Encryption.encryptAndEncodeContent(File.read(file))
                        File.open(file + "_enc","w") do |outf|
                            outf << encodedContent
                        end
                        File.delete file
                    end

                    html, this = evaluateEappTemplate(templateFacetValue, @entityHash)
                    @baseIO.isTemplateBasedOutput = true
                    @baseIO.htmlContent = []
                    @baseIO.htmlContent.push html
                    @baseIO.signatureList = this.eapp.Policy.ServiceSignatureList
                    if @baseIO.isFullHTMLRequired
                        responseHash['data'] = {"EappHTMLPreview" => @baseIO.htmlContent.first}
                    else
                        MobiSys::SymTemplateUtil.loadHTMLBodyContent(@baseIO.htmlContent.first, @baseIO.bodyContent, @baseIO.cssContent)
                        responseHash['data'] = { "EappHTMLPreview" => @baseIO.bodyContent, "htmlStyles" => @baseIO.cssContent }
                    end
                    responseHash['data']['signatureList'] = @baseIO.signatureList
                else
                    MobiSys::PolicyService.generateEappPreview(policy)
                    responseHash['data'] = {"EappHTMLPreview" => $policyIO.htmlContent}
                end
            end
        else
            p "Inside generateEappPreview condition"
            MobiSys::PolicyService.generateEappPreview(policy)
            responseHash['data'] = {"EappPreview" => $policyIO.htmlContent}
        end
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def evaluateEappTemplate(templateFacetValue, entityHash)
        html = ""
        thisHM = MobiSys::PolicyPreview.generateEappPreview_new(@baseIO, entityHash)
        this = ::JSON.parse(thisHM.to_json, object_class:OpenStruct)
        html = renderTemplate(:template =>"Templates/#{templateFacetValue}/index", :locals => { :this=>this})
        return html, this
    end

    def policySubmit(id,parsedData)
        policy = @baseIO.baseDO
        policy.action = "Submit"
        responseHash = {}
        exceptionMessage = nil
        responseHash = MobiSys::PolicyService.executeSubmit(true,policy)
        tempHash = {}
        errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid,policy.visitedTabs)
        isValid = false unless errors.empty?

        if policy.statusCd.to_s == "DECLARATIONCOMPLETE" && policy.signatureStatus.to_s != "SUCCESS"
            isValid = false
        end
        
        if isValid
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            # has_network = false #uncomment to test offline flow.
            transactionSuccessfull = false
            if has_network && policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                duplicatePolicy = false
                policyNum = doJSONPost('/checkPolicyDup.run', policy.proposalNum)
                if policyNum.to_s == ""
                    policy.uwDecisionCd = "COMPLETE"
                    policy.statusCd = "COMPLETE"
                    policyArray = Array.new
                    serviceQuestionResponseArray = Array.new
                    serviceDocumentRequirementArray = Array.new
                    partyImageList = Array.new
                    serviceSignatureArray = Array.new
                    inwardArray = Array.new

                    [policy].each do |pol|
                        pol.PartyList.each do |party|
                            questionContainer = QuestionContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'} => party.guid,
                                    {:name=>'policyGuid'} => pol.uniqueKey
                                },
                                :op=>'AND'
                                )
                            if questionContainer
                                partyResponseList = questionContainer.ServiceQuestionResponseList
                                serviceQuestionResponseArray.concat partyResponseList
                            end

                            documentContainer = DocumentContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'}=> party.guid,
                                    {:name=>'policyGuid'}=> pol.guid
                                },
                                :op => 'AND'
                                )
                            if documentContainer
                                partyDocumentList = documentContainer.ServiceDocumentList
                                #code added to make sericeDocument status received if document is selected and image exist
                                partyDocumentList.each do|partydoc|
                                    imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                    partyImageList.concat imageList if imageList.size > 0

                                    if partydoc.acceptanceStatusCd != "FULFILLED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                        partydoc.imageCount = imageList.size
                                        partydoc.acceptanceStatusCd = "FULFILLED"

                                        partydoc.persistAll
                                    end
                                end
                                serviceDocumentRequirementArray.concat partyDocumentList
                            end
                        end
                    end

                    #Discussed with Neha: Hardcoded value sent for online validations for doDocumentValidation
                    serviceDocumentRequirementArray.each do|partydoc|
                        partydoc.imageURL = "offline"
                    end

                    agentQuestionContainer = QuestionContainer.loadObject(
                        :first,
                        :conditions => {
                            {:name => 'entityGuid'} => policy.guid,
                            {:name => 'policyGuid'} => policy.guid,
                            {:name => 'entityTypeCd'} => 'AGENT'
                        },
                        :op => 'AND'
                        )
                    if agentQuestionContainer
                        agentResponseList = agentQuestionContainer.ServiceQuestionResponseList
                        serviceQuestionResponseArray.concat agentResponseList
                    end

                    signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => policy.guid})
                    serviceSignatureArray = signatureContainer.ServiceSignatureList if signatureContainer

                    inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                    emailResponseHash = nil
                    policy.policyStatusCd = "DECLARATIONCOMPLETE"
                    #generating pdf for illustration before submitting application
                    emailResponseHash = MobiSys::PolicyService.generateSIPDF(policy)
                    policyArray.push(policy)

                    syncEntities = Hash.new
                    syncEntities[Policy.onlineClassName] = policyArray
                    syncEntities[ServiceQuestionResponse.onlineClassName] = serviceQuestionResponseArray if serviceQuestionResponseArray.size > 0
                    syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
                    syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
                    syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                    syncEntities[Inward.onlineClassName] = inward if inward

                    transactionSuccessfull = false
                    if (emailResponseHash != nil && !emailResponseHash.empty?)
                        transactionSuccessfull = true # if generateSIPDF is successfull
                        responseHash = {}
                        responseHash = PolicyUtil::ApplicationUtil.invokeOnlineService(syncEntities,"/callPolicyService.run",true)
                        transactionSuccessfull = false # resetting the flag again after invoking next service
                        if responseHash != nil && !responseHash.empty?
                            transactionSuccessfull = true # if callPolicyService is successfull
                            #Mark all documents are done uploading
                            serviceDocumentRequirementArray.each do |serviceDoc|
                                serviceDoc.uploadStatus = "DONE"
                                serviceDoc.persistAll
                            end

                            partyImageList.each do |image|
                                image.uploadStatus = "DONE"
                                image.persistAll
                            end

                            facetData = MobiSys::PolicyService.getFacetData("result", policy.baseProductSeq)
                            facetData[:showResults] = true

                            MobiSys::PolicyService.processPolicyResult(nil, nil, responseHash,facetData)
                        else
                           transactionSuccessfull = false # callPolicyService failed
                        end
                    end
                else
                    policy.policyNum = policyNum
                    policy.persistAll
                    MobiSys::TrackLeadBO.updateTrackLead(policy)
                    duplicatePolicy = true
                end
            end
            if transactionSuccessfull
                MobiSys::TrackLeadBO.updateTrackLead(policy)
                isMetadataRequired = true
                if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                    isMetadataRequired = false
                end
                fetch(policy.object)
                fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
                @message = "Successful"
                tempHash = generateResponseHash(isMetadataRequired)
                tempHash['success'] = true
            elsif duplicatePolicy
                tempHash["success"] = false
                 tempHash["message"] = MobiSys::CommonUtil.replacePlaceHolders(MobiSys::BrowserHelper.getLabel('ERR_submitEappFromWeb'), [policy.policyNum, policy.proposalNum])
            else
                tempHash["success"] = false
                tempHash["message"] = getLabelValue('SERVERERROR')
            end
        else
            tempHash["success"] = false
            tempHash["message"] = "Please resolve all warnings & sign before policy submission"
        end

        return responseHash
    end

    def policySubmitRaw(id,parsedData)
        policy = @baseIO.baseDO
        policy.action = "Submit"
        responseHash = {}
        exceptionMessage = nil
        responseHash = MobiSys::PolicyService.executeSubmit(true,policy)
        tempHash = {}
        errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid,policy.visitedTabs)
        isValid = false unless errors.empty?

        if policy.statusCd.to_s == "DECLARATIONCOMPLETE" && policy.signatureStatus.to_s != "SUCCESS"
            isValid = false
        end
        
        if isValid
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            # has_network = false #uncomment to test offline flow.
            transactionSuccessfull = false
            if has_network && policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                duplicatePolicy = false
                policyNum = doJSONPost('/checkPolicyDup.run', policy.proposalNum)
                if policyNum.to_s == ""
                    policy.uwDecisionCd = "COMPLETE"
                    policy.statusCd = "COMPLETE"
                    policyArray = Array.new
                    serviceQuestionResponseArray = Array.new
                    serviceDocumentRequirementArray = Array.new
                    partyImageList = Array.new
                    serviceSignatureArray = Array.new
                    inwardArray = Array.new

                    [policy].each do |pol|
                        pol.PartyList.each do |party|
                            questionContainer = QuestionContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'} => party.guid,
                                    {:name=>'policyGuid'} => pol.uniqueKey
                                },
                                :op=>'AND'
                                )
                            if questionContainer
                                partyResponseList = questionContainer.ServiceQuestionResponseList
                                serviceQuestionResponseArray.concat partyResponseList
                            end

                            documentContainer = DocumentContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'}=> party.guid,
                                    {:name=>'policyGuid'}=> pol.guid
                                },
                                :op => 'AND'
                                )
                            if documentContainer
                                partyDocumentList = documentContainer.ServiceDocumentList
                                #code added to make sericeDocument status received if document is selected and image exist
                                partyDocumentList.each do|partydoc|
                                    imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                    partyImageList.concat imageList if imageList.size > 0

                                    if partydoc.acceptanceStatusCd != "FULFILLED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                        partydoc.imageCount = imageList.size
                                        partydoc.acceptanceStatusCd = "FULFILLED"

                                        partydoc.persistAll
                                    end
                                end
                                serviceDocumentRequirementArray.concat partyDocumentList
                            end
                        end
                    end

                    #Discussed with Neha: Hardcoded value sent for online validations for doDocumentValidation
                    serviceDocumentRequirementArray.each do|partydoc|
                        partydoc.imageURL = "offline"
                    end

                    agentQuestionContainer = QuestionContainer.loadObject(
                        :first,
                        :conditions => {
                            {:name => 'entityGuid'} => policy.guid,
                            {:name => 'policyGuid'} => policy.guid,
                            {:name => 'entityTypeCd'} => 'AGENT'
                        },
                        :op => 'AND'
                        )
                    if agentQuestionContainer
                        agentResponseList = agentQuestionContainer.ServiceQuestionResponseList
                        serviceQuestionResponseArray.concat agentResponseList
                    end

                    signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => policy.guid})
                    serviceSignatureArray = signatureContainer.ServiceSignatureList if signatureContainer

                    inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                    emailResponseHash = nil
                    policy.policyStatusCd = "DECLARATIONCOMPLETE"
                    #generating pdf for illustration before submitting application
                    emailResponseHash = MobiSys::PolicyService.generateSIPDF(policy)
                    policyArray.push(policy)

                    syncEntities = Hash.new
                    syncEntities[Policy.onlineClassName] = policyArray
                    syncEntities[ServiceQuestionResponse.onlineClassName] = serviceQuestionResponseArray if serviceQuestionResponseArray.size > 0
                    syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
                    syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
                    syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                    syncEntities[Inward.onlineClassName] = inward if inward

                    transactionSuccessfull = false
                    if (emailResponseHash != nil && !emailResponseHash.empty?)
                        transactionSuccessfull = true # if generateSIPDF is successfull
                        responseHash = {}
                        responseHash = PolicyUtil::ApplicationUtil.invokeOnlineService(syncEntities,"/callPolicyService.run",true)
                        transactionSuccessfull = false # resetting the flag again after invoking next service
                        if responseHash != nil && !responseHash.empty?
                            transactionSuccessfull = true # if callPolicyService is successfull
                            #Mark all documents are done uploading
                            serviceDocumentRequirementArray.each do |serviceDoc|
                                serviceDoc.uploadStatus = "DONE"
                                serviceDoc.persistAll
                            end

                            partyImageList.each do |image|
                                image.uploadStatus = "DONE"
                                image.persistAll
                            end

                            facetData = MobiSys::PolicyService.getFacetData("result", policy.baseProductSeq)
                            facetData[:showResults] = true

                            MobiSys::PolicyService.processPolicyResult(nil, nil, responseHash,facetData)
                        else
                           transactionSuccessfull = false # callPolicyService failed
                        end
                    end
                else
                    policy.policyNum = policyNum
                    policy.persistAll
                    MobiSys::TrackLeadBO.updateTrackLead(policy)
                    duplicatePolicy = true
                end
            end
            if transactionSuccessfull
                MobiSys::TrackLeadBO.updateTrackLead(policy)
                isMetadataRequired = true
                if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                    isMetadataRequired = false
                end
                fetch(policy.object)
                fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
                @message = "Successful"
                tempHash = generateResponseHash(isMetadataRequired)
                tempHash['success'] = true
            elsif duplicatePolicy
                tempHash["success"] = false
                 tempHash["message"] = MobiSys::CommonUtil.replacePlaceHolders(MobiSys::BrowserHelper.getLabel('ERR_submitEappFromWeb'), [policy.policyNum, policy.proposalNum])
            else
                tempHash["success"] = false
                tempHash["message"] = getLabelValue('SERVERERROR')
            end
        else
            tempHash["success"] = false
            tempHash["message"] = "Please resolve all warnings & sign before policy submission"
        end

        return responseHash
    end


    def addPartyIdentity
        parsedData = parseRequestBodyParams
        responseHash = {}
        @lookupHash = {}
        @entityHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        partyIdentity = PartyIdentity.new
        partyIdentity.identityTypeCd = parsedData["identityTypeCd"] if parsedData.has_key?("identityTypeCd")
        @entityHash["PartyIdentity"] = partyIdentity.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
        if isMetadataRequired
            evaluateContextForObject(partyIdentity)
            @metadataHash = processMetadata(partyIdentity)
            contextEnd
        end

        @success = true
        @message = 'Successful'
        responseHash = generateResponseHash(isMetadataRequired)
        render :string => responseHash.to_json
    end

    def addInitialPayment
        parsedData = parseRequestBodyParams
        responseHash = {}
        @lookupHash = {}
        @entityHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        if policy
            isMetadataRequired = true
            if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                isMetadataRequired = false
            end
            inwardDetail = InwardDetails.new
            basePlan = policy.getBaseProduct
            inwardDetail.inwardAmount = basePlan.modalPremium if basePlan != nil
            @entityHash['InitialPayment'] = inwardDetail.hashForApi(true).select {|key| !["class","userId"].include? key.to_s }
            if isMetadataRequired
                evaluateContextForObject(inwardDetail)
                @metadataHash = processMetadata(inwardDetail)
                contextEnd
            end
            @success = true
            @message = 'Successful'
        else
            @success = false
            @message = 'Policy not found.'
        end
        responseHash = generateResponseHash(isMetadataRequired)
        render :string => responseHash.to_json
    end

    def addImage_bkp
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        $taskExceptionHash = []

        #Image content for Ocr validation
        imageContent = parsedData["imageContent"]
        serviceDoc = parsedData["serviceDocument"]
        serviceDocument = MobiSys::BrowserHelper.convertToObject("ServiceDocument",serviceDoc,nil,false)
        documentDO = Document.loadObject(
            :first,
            :conditions=>{
                {:name=>'documentCd'} => serviceDocument.documentCd
            }
        ) if serviceDocument

        if !documentDO
            responseHash["success"] = false
            responseHash["message"] = "\nDocument is not found in configuration."
        else
            docImage = DocumentImage.new
            offlineFile = OfflineFile.new
            new_image = Image.new
            new_image.addOfflineFile offlineFile
            docImage.object = new_image.object
            docImage.guid = new_image.uniqueKey
            docImage.fileContents = imageContent
            offlineFile.fileContents = imageContent
            if $rhoconfig.has_key?(:encrypt_images) and $rhoconfig[:encrypt_images]=='YES' and offlineFile.fileContents.to_s != ""
                parts = offlineFile.fileContents.rpartition('|')
                offlineFile.fileContents = parts[0]
                offlineFile.encryptionIv = parts[2]
                offlineFile.fileEncrypted = "YES"
            else
                offlineFile.fileEncrypted = 'NO'
                offlineFile.fileContents = offlineFile.fileContents
            end

            MobiSys::PolicyService.processServiceDocumentOcr(@baseIO.baseDO,documentDO,serviceDocument,new_image) if (serviceDocument != nil and serviceDocument.ocrCheckReqd.to_s == "YES" and serviceDocument.disableOcrFl.to_s != "YES")
        end
        if $taskExceptionHash.size > 0
            errorMessage = ""
            $taskExceptionHash.each{|exception| errorMessage = errorMessage+"\n"+exception.exceptionMessage}
            responseHash["success"] = false
            responseHash["message"] = errorMessage
        elsif (serviceDocument != nil and serviceDocument.disableOcrFl.to_s != "YES" and documentDO == nil and serviceDocument.ocrCheckReqd.to_s == "YES") or (serviceDocument != nil && serviceDocument.disableOcrFl.to_s != "YES" && docImage.ocrExtractedText.to_s == "" and serviceDocument.ocrCheckReqd.to_s == "YES")
            responseHash["success"] = false
            responseHash["message"] = "\nError in processing OCR data.Please contact system administrator."
        else
            responseHash["success"] = true
            responseHash["message"] = 'Successful'
        end

        $taskExceptionHash = nil
        render :string => responseHash.to_json
    end

    def addImage
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        $taskExceptionHash = []

        #Image content for Ocr validation
        imageContent = parsedData["imageContent"]
        serviceDoc = parsedData["serviceDocument"]
        serviceDocument = (serviceDoc.to_s != "" ? MobiSys::BrowserHelper.convertToObject("ServiceDocument",serviceDoc,nil,false) : nil)

        docImage = DocumentImage.new
        offlineFile = OfflineFile.new
        new_image = Image.new
        new_image.addOfflineFile offlineFile
        docImage.object = new_image.object
        docImage.guid = new_image.uniqueKey
        if imageContent.to_s != ""
            docImage.fileContents = imageContent
            offlineFile.fileContents = imageContent
        end
        if $rhoconfig.has_key?(:encrypt_images) and $rhoconfig[:encrypt_images]=='YES' and offlineFile.fileContents.to_s != ""
            parts = offlineFile.fileContents.rpartition('|')
            offlineFile.fileContents = parts[0]
            offlineFile.encryptionIv = parts[2]
            offlineFile.fileEncrypted = "YES"
        else
            offlineFile.fileEncrypted = 'NO'
            offlineFile.fileContents = offlineFile.fileContents
        end

        if (serviceDocument != nil and serviceDocument.ocrCheckReqd.to_s == "YES" and serviceDocument.disableOcrFl.to_s != "YES")
            documentDO = Document.loadObject(
                :first,
                :conditions=>{
                    {:name=>'documentCd'} => serviceDocument.documentCd
                }
            )
            MobiSys::PolicyService.processServiceDocumentOcr(@baseIO.baseDO,documentDO,serviceDocument,new_image) if documentDO != nil
            docImage.ocrExtractedText = offlineFile.ocrExtractedText
        end

        responseHash['data'] = {}
        responseHash['data']['DocumentImage'] = docImage.hashForApi(false)
        if $taskExceptionHash.size > 0
            errorMessage = ""
            # $taskExceptionHash.each{|exception| errorMessage = errorMessage+"\n"+exception.exceptionMessage}
            #########################################
            heading = {}
            $taskExceptionHash.each do|exception|
                exceptionMessage = exception.exceptionMessage
                exceptionCode = exception.exceptionCd
                responseHash['data']['error'] = exceptionCode
                if exceptionCode == "ERR_DATAMISMATCH" && exceptionMessage && exceptionMessage.include?("•")
                    bulletIndex = exceptionMessage.index("•")
                        if bulletIndex
                            headerMessage = exceptionMessage[0...bulletIndex].strip
                            bulletPointMessage = exceptionMessage[bulletIndex..-1].strip

                            if heading.key?(headerMessage)
                              heading[headerMessage] += "\n" + bulletPointMessage
                            else
                              heading[headerMessage] = bulletPointMessage
                            end
                        else
                            errorMessage += "\n#{exceptionMessage}"
                        end
                else
                    errorMessage += "\n#{exceptionMessage}"
                end
            end
            p "heading=====#{heading}"
            if heading && !heading.empty?
              # errorMessage ||= ""

              heading.each do |headerLine, bulletPointMessage|
                # Split message into lines
                bulleLines = bulletPointMessage.split("\n").map(&:strip)
                last_name = ""
                first_name = ""
                middle_name = ""
                others = []

                bulleLines.each do |line|
                  if line.strip.downcase.start_with?("• last name")
                    last_name = line
                  elsif line.strip.downcase.start_with?("• first name")
                    first_name = line
                  elsif line.strip.downcase.start_with?("• middle name")
                    middle_name = line
                  else
                    others << line
                  end
                end
                # Reorder bullet points
                reordered = []
                reordered << last_name unless last_name.empty?
                reordered << first_name unless first_name.empty?
                reordered << middle_name unless middle_name.empty?
                reordered.concat(others)

                # Append to message
                errorMessage += "\n#{headerLine}\n#{reordered.join("\n")}"
                p "errorMessage===#{errorMessage}"
              end
            end
            #########################################
            responseHash["success"] = false
            responseHash["message"] = errorMessage
        elsif (serviceDocument != nil and serviceDocument.disableOcrFl.to_s != "YES" and documentDO == nil and serviceDocument.ocrCheckReqd.to_s == "YES") or (serviceDocument != nil && serviceDocument.disableOcrFl.to_s != "YES" && docImage.ocrExtractedText.to_s == "" and serviceDocument.ocrCheckReqd.to_s == "YES")
            responseHash["success"] = false
            responseHash["message"] = "\nError in processing OCR data.Please contact system administrator."
        else
            responseHash["success"] = true
            responseHash["message"] = 'Successful'
        end

        if !validate_file(parsedData,serviceDocument)
            responseHash["success"] = false
            responseHash['data']['File_Validation'] = false
            responseHash["message"] = 'Invalid image file upload'
        end

        $taskExceptionHash = nil
        render :string => responseHash.to_json
    end


    def validate_file(rest_io, service_document)
        image_content = rest_io["imageContent"]
        file_name     = rest_io["fileName"]
        ext           = File.extname(file_name).delete('.').downcase

        document_desc = service_document.document_desc
        party_desc    = service_document.party_desc

        if image_content
          begin
            if ext != "pdf"
              decoded = Base64.decode64(image_content)
              validate_corrupted_image(decoded, "corruptedDoc", ext)
            end
          rescue => e
            return false
          end
        end

        if image_content
          begin
            validate_file_size(
              image_content,
              "IMAGE_SIZE_LIMIT",
              "fileSizeValidation",
              document_desc,
              party_desc
            )
          rescue => e
            return false
          end
        end

        if image_content
          begin
            if ext == "pdf"
              decoded = Base64.decode64(image_content)
              validate_corrupted_pdf(decoded, "corruptedDoc")
            end
          rescue => e
            return false
          end
        end

        true
    end

      # Validate Image
    def validate_corrupted_image(data, err_key, ext)
        valid = case ext.downcase
                when "jpg", "jpeg"
                  data.start_with?("\xFF\xD8".b) && data.end_with?("\xFF\xD9".b)
                when "png"
                  data.start_with?("\x89PNG\r\n\x1A\n".b)
                when "gif"
                  data.start_with?("GIF87a".b) || data.start_with?("GIF89a".b)
                when "bmp"
                  data.start_with?("BM".b)
                else
                  false
                end

        unless valid
          msg = get_message(err_key, [ext.upcase])
          raise RuntimeError, msg
        end
        true
    end

      # Validate PDF
    def validate_corrupted_pdf(data, err_key)
        pdf_header = "%PDF".b
        eof_marker = "%%EOF".b

        valid = data.start_with?(pdf_header) && data.include?(eof_marker)

        unless valid
          msg = get_message(err_key, ["PDF"])
          raise RuntimeError, msg
        end
        true
    end

      # Validate File Size
    def validate_file_size(file_content, property_name, err_key, *args)
        file_limit = get_property(property_name).to_i

        data = Base64.decode64(file_content)
        file_kb = data.length.to_f / 1024

        if file_kb == 0
          params = [file_kb.to_s, file_limit.to_s] + args
          msg = get_message(err_key, params)
          raise RuntimeError, msg
        end
        true
    end
    def get_property(name)
        ENV[name] || "1024"
    end

    def get_message(key, params)
        "#{key} - #{params.join(', ')}"
    end


    def getPartyQuestionnaire
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO

        product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
        productFacet = product.getFacet('AGENTQUESTIONSETGROUP')

        questionSetCd = ""
        questionSetCd = productFacet.actionValue if productFacet

        # questionSetData = QuestionSet.loadObject(:all)
        questionSetMapData = QuestionSetMap.find(
            :all,
            :order => ['parentQuestionSetCd', 'displayOrder']
        )
        getQuestionSetHash unless $questionSetData 
        getQuestionSetQuestionHash if $inputTypeOfQuestion.empty?
        $questionnaireLookups = []
        questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, questionSetMapData, questionSetCd)
        questionContainer = nil
        questionContainer = QuestionContainer.loadObject(
            :first,
            :conditions=>{
                {:name=>'entityGuid'} => policy.uniqueKey,
                {:name=>'policyGuid'} => policy.uniqueKey,
                {:name=>'entityTypeCd'} => parsedData['questionnaireTypeCd'].to_s
            },
            :op => 'AND'
        )

        responseList = []
        # responseList = MobiSys::Questionnaire.setupResponseHash(questionContainer)
        if questionContainer
            questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
                responseList.push(serviceQuestionResponse.hashForApi(false).select {|key| !["class","userId"].include? key.to_s })
            end
        end
        @lookupHash = {}
        $questionnaireLookups.each do|qLookup|
            addToLookupHash(qLookup,"")
        end
        $questionnaireLookups = nil
        responseHash['data'] = {}
        responseHash['data']['responseList'] = responseList
        responseHash['data']['questionnaireMaster'] = questionnaireHash
        responseHash['data']['lookups'] = @lookupHash

        responseHash["success"] = true
        responseHash["message"] = 'Successful'
        render :string => responseHash.to_json

    end

     def addPolicyAgent
        parsedData = parseRequestBodyParams
        responseHash = {}
        @entityHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        if policy
            policyAgent = PolicyAgent.new
            policy.addPolicyAgent(policyAgent)
            policyAgent.primaryAgentFl = "NO"
            @entityHash['policyAgent'] = policyAgent.hashForApi(false)
            if isMetadataRequired
                evaluateContextForObject(policyAgent)
                @lookupHash = {}
                metadataHash = {}
                @metadataHash = metadataHash.merge!(processMetadata(policyAgent))
                contextEnd
            end
            @success = true
            @message = 'Successful'
        else
            @success = false
            @message = 'Policy not found.'
        end

        responseHash = generateResponseHash(true)

        render :string => responseHash.to_json
    end

    def getReflexiveQuestionnaire
        parsedData = parseRequestBodyParams
        RhoLog.error("parsedData","parsedData :- #{parsedData}")
        responseHash = {}
        @lookupHash = {}
        $currentDTCache = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        quotation = MobiSys::PolicyBO.convertToQuotation(@baseIO.baseDO)
        partyGuid = parsedData["currPartyGuid"]
        quotationParty = quotation.QuotationPartyList.select{|qp| qp.guid == partyGuid }.first
        policyParty = policy.getPartyByGuid(partyGuid)
        roleCd = policyParty ? policyParty.roleCd : nil
        if (parsedData["CurrPartyQuestionnaireResponseList"].to_s != "")
            questRespListModel = MobiSys::QuestionnaireResponseListModel.new(@baseIO)
            questRespListModel.questionnaireTypeCd = "INSUREDPARTY"
            listPartyQuestionnaire = []
            currPartyQuestionnaireRespList = MobiSys::BrowserHelper.convertToObject("PolicyPartyContainer", parsedData["CurrPartyQuestionnaireResponseList"])
            listPartyQuestionnaire << currPartyQuestionnaireRespList
            questRespListModel.setModel(listPartyQuestionnaire)
            listPartyQuestionnaire = questRespListModel.getModel
            responseHash['data'] = {}
            responseHash['data']["CurrPartyQuestionnaireResponseList"] = listPartyQuestionnaire[0].hashForApi
            if (@baseIO and @baseIO.additionalData != nil and @baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and @baseIO.additionalData["ADDTNL_LOOKUPS"] != nil)
                @baseIO.additionalData["ADDTNL_LOOKUPS"].each do |addtnlLookup|
                    addToLookupHash(addtnlLookup.keys.first,nil) if addtnlLookup.keys.first.to_s != "" && @lookupHash
                end
            end
        else
            questionSetCd = parsedData["currQuestionSetCd"]
            dataElementCd = parsedData["currDataElementCd"]
            responseValue = parsedData["currResponseValue"] != "" && parsedData["currResponseValue"] != nil ? parsedData["currResponseValue"] : nil
            parentRefPath = parsedData["currParentReferencePath"].to_s != "" ? parsedData["currParentReferencePath"] : nil
            #if particular data element is passed implies only current question set needs to be refreshed
            #replace response in IO with that passed and then evaluate the question set
            if questionSetCd.to_s != "" && dataElementCd.to_s != ""
                if partyGuid
                    # questionContainer = nil
                   party = @baseIO.baseDO.getPartyByGuid(partyGuid)
                   questionContainer = party.questionContainer || 
                    QuestionContainer.new(
                        :entityGuid => partyGuid,
                        :entityTypeCd => roleCd,
                        :policyGuid => policy.guid
                    )
                else
                    questionContainer =    QuestionContainer.new(
                            :entityGuid => policy.guid,
                            :entityTypeCd => "AGENT",
                            :policyGuid => policy.guid
                        )
                end
                #first check if a response already exists.. if so then replace that response else add new response from UI
                sqRespDO = ServiceQuestionResponse.new
                sqRespDO.partyGuid = partyGuid
                sqRespDO.questionSetCd = questionSetCd
                sqRespDO.questionDataElementCd = dataElementCd
                sqRespDO.responseValue = responseValue
                sqRespDO.parentReferencePath = parentRefPath
                questionContainer.addServiceQuestionResponse(sqRespDO)
                $parentQuestionCd = ""
                key = "#{sqRespDO.questionSetCd}|#{sqRespDO.questionDataElementCd}"
                key << "|#{sqRespDO.parentReferencePath}" if sqRespDO.parentReferencePath.to_s != ""
                key << "|#{sqRespDO.partyGuid}" if sqRespDO.partyGuid.to_s != ""
                key << "|#{sqRespDO.rowGuid}" if sqRespDO.rowGuid.to_s != ""
                $responseHash.reject! { |key, _| key.include?("~#{questionSetCd.to_s}") }
                $responseHash[key] = sqRespDO
                $policyModelEval = {}
                $questionSetMapData = QuestionSetMap.find(
                    :all,
                    :order => ['parentQuestionSetCd', 'displayOrder']
                ) unless $questionSetMapData
                getQuestionSetHash unless $questionSetData 
                getQuestionSetQuestionHash if $inputTypeOfQuestion.empty?
                $questionnaireLookups = []
                questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, questionSetCd, parentRefPath)
                
                currentQuestionSetMap = MobiSys::PolicyService.getRecursiveQuestionSet(questionnaireHash, partyGuid,@baseIO,questionContainer,quotation,quotationParty,$responseHash,nil,parentRefPath)
                if (@baseIO and @baseIO.additionalData != nil and @baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and @baseIO.additionalData["ADDTNL_LOOKUPS"] != nil)
                    @baseIO.additionalData["ADDTNL_LOOKUPS"].each do |addtnlLookup|
                        addToLookupHash(addtnlLookup.keys.first,nil) if addtnlLookup.keys.first.to_s != "" && @lookupHash
                    end
                end

            end
            responseHash['data'] = {}
            responseHash['data']["currQuestionSet"] = currentQuestionSetMap
        end
        responseHash["lookups"] = @lookupHash
        responseHash["success"] = true
        responseHash["message"] = 'Successful'

        render :string => responseHash.to_json
    end

    def changeAllocation(id,parsedData)
        p "in changeallocation "
        policy = @baseIO.baseDO
        quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
        proposer = policy.getParty("PROPOSER")
        primary = policy.getParty("PRIMARY")
        responseHash = {}
        # process()
        isValid = true
        if policy.allocatedToRole.to_s == "AGENT"
            if MobiSys::PolicyService.hasProposalExpired(quotation)
                @message = getLabelValue('ERR_PROPOSAL_EXPIRED')
                @success = false 
                isValid = false
            else 
                proposerPhilippinesNum = proposer.getPartyContact("PHILIPPINESNUM")
                proposerCountryCode = proposerPhilippinesNum.countryCd if proposerPhilippinesNum
                primaryContactMobile = primary.getPartyContact("MOBILE")
                priPartyEmail = primary.getPartyEmail
                policyAddtnField = policy.getPolicyAdditionalFieldsDO
                emailAdd = priPartyEmail.emailAddress.to_s if priPartyEmail
                primaryAdditnlField = primary.getPartyAdditionalField
                primaryAdditnlField28 = primaryAdditnlField.field28 if primaryAdditnlField
                if (proposerCountryCode && proposerCountryCode != "0063") || (policyAddtnField && (primary.age.to_i >= 18 || policyAddtnField.field11.to_s == "Y") && primaryAdditnlField28.to_s != "MOBILEPHONE" && ((priPartyEmail && emailAdd == "" ) || (primaryContactMobile == nil || primaryContactMobile.countryCd != "0063" )))
                    @message = getLabelValue('ERR_transferredToCustomerMsg')
                    @success = false 
                    isValid = false
                end
            end
            @message = getLabelValue('transferredToCustomerMsg') if isValid
            MobiSys::PolicyService.transferToCustomer(policy) if isValid
        else
            if MobiSys::PolicyService.hasProposalExpired(quotation)
                @message = getLabelValue('ERR_PROPOSAL_EXPIRED')
                @success = false 
                isValid = false
            end
            @message = getLabelValue('transferredToAgent') if isValid
            MobiSys::PolicyService.revokeFromCustomer(policy) if isValid
        end
        fetch(id)
        policy = @baseIO.baseDO
        policy.isInvalid = isInvalid
        policy.isCompleted = isCompleted
        policy.step = 0
        return policy
    end

    def getPolicyTransferDetails
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        responseHash = {}
        tempUserLoginDOList = []
        inputHash = Hash.new
        policyPackage = Hash.new
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            begin
                # policyPackage[Policy.onlineClassName] = [policy.hashForSync]
                # inputHash[0] = ::JSON.generate([policyPackage.to_json])
                 if (policy.quoteProposerSameAsInsured.to_s != "YES" && policy.quoteProposerSameAsInsured.to_s != "COPYFROMINSURED")
                    proposerParty = policy.getParty("PROPOSER")
                    primaryParty = policy.getPartyByRole("PRIMARY")
                    primaryPartyGuid = primaryParty.guid
                else
                    proposerParty = policy.getParty("PROPOSER")

                 end
                inputHash = { proposerGuid: proposerParty.guid.to_s, primaryGuid: primaryPartyGuid.to_s, allocatedToRole: policy.allocatedToRole.to_s}

                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/policyTransferHistory.run', json)
                 resultsHash = response.to_s != '' ? Rho::JSON.parse(response) : {}
                parsed_array = Rho::JSON.parse(resultsHash.values.first)
                # Convert each user into flat hash
                flat_result = parsed_array.map do |user|
                  {
                    "guid"           => user["guid"],
                    "id"             => user["id"],
                    "status"         => user["status"],       # may be nil if not present
                    "versionID"      => user["versionID"],
                    "entityTypeCd"   => user["entityType"],   # mapped from entityType
                    "contactNum"     => user["contactNum"],
                    "emailId"        => user["emailId"],
                    "removed"        => user["removed"],
                    "transferStatus" => user["transferStatus"],
                    "urlCreatedDt"   => user["urlCreatedDt"],
                    "userName"       => user["userName"],
                    "userType"       => user["userType"],
                    "visitedTabs"    => user["visitedTabs"]
                  }
                end

                flat_result.each do |record|
                    if record["urlCreatedDt"].to_s != ""
                      time = Time.parse(record["urlCreatedDt"])
                      record["urlCreatedDt"] = (time.to_f * 1000).to_i.to_s
                    else
                       record["urlCreatedDt"] = nil
                    end
                end

                responseHash["data"] = { "PolicyTransferHistoryList" => flat_result }
                responseHash["success"] = true
                responseHash["message"] = "Successful"
            rescue StandardError => se
                puts "Error while getting policy transfer history => #{se}"
                responseHash["message"] = getLabelValue('SERVERERROR')
            end
        else
            responseHash["message"] = getLabelValue('ERR_NETWORK')
        end
        render :string => responseHash.to_json
    end

    def getPartyRoleList
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        roleCd = (parsedData.has_key?("roleCd") ? parsedData["roleCd"] : nil)
        paymentInstructionTypeCd = (parsedData.has_key?("paymentInstructionTypeCd") ? parsedData["paymentInstructionTypeCd"] : nil)
        responseHash = {}
        @lookupHash = {}
        filterCond = {}
        if policy
            insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
            if insuredPartyRole
                proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
            else
                proposerIsSameAsInsured = false
            end
            if roleCd.to_s != ""
                partyRoleHash = {}
                partySameAsList = Lookupvalue.getValue("PARTYSAMEAS")
                roleList = ""
                partySameAsList.each do |partySameAs|

                    partyDetailList = []
                    currentRoleCd = partySameAs.cd
                    next if roleCd.to_s == currentRoleCd
                    next if (roleCd.to_s == "NOMINEE" && proposerIsSameAsInsured && (currentRoleCd == "PROPOSER" || currentRoleCd == "PRIMARY"))
                    partyList = policy.getPartyList(currentRoleCd)
                    if currentRoleCd.to_s == "OTHER"
                        if paymentInstructionTypeCd.to_s != ""
                            payerParty = policy.getPayerParty(paymentInstructionTypeCd)
                            partyList.push(payerParty) if payerParty != nil and payerParty.roleCd.to_s == "PAYER"
                        end
                        partyRoleHash[currentRoleCd] = []
                    end

                    if partyList.size > 0
                        partyList.each do |party|
                            partyDetailsHash = {}
                            partyDetailsHash["guid"] = party.guid
                            partyDetailsHash["name"] = party.getFullName
                            partyDetailList.push(partyDetailsHash)
                            roleList << "'#{partySameAs.cd}',"
                        end
                        partyRoleHash[currentRoleCd] = partyDetailList
                    end
                end
                roleList = roleList[0..-2] if roleList != "" && roleList[-1] == ","
                filterCond['partyRoles'] = roleList
                filterCond['object'] = policy.object
                addToLookupHash('PARTYSAMEAS', nil,nil,filterCond)


                responseHash['data'] = {'values' => partyRoleHash}
                responseHash["lookups"] = @lookupHash
                responseHash["success"] = true
            else
                responseHash = { success: false, message: "Input data missing."}
            end
        else
            responseHash = { success: false, message: "Policy not found."}
        end

        render :string => responseHash.to_json
    end

    def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata = nil)
        p "$currentActiveTab=======#{$currentActiveTab}"
        baseProduct = nil
        prdMetadataChkReqd = true
        #For PolicyProductAdditional set the parent object as baseProduct for metadata evaulation
        if(currentTagObject != nil && currentTagObject.is_a?(PolicyProduct)  && currentTagObject.productSeq.to_s != "")
            baseProduct = currentTagObject
        elsif(currentTagObject != nil && currentTagObject.is_a?(PolicyProductAdditional))
            policyProductList = @baseIO.baseDO.PolicyProductList
            baseProduct = policyProductList.select{|policyProduct| policyProduct.object == currentTagObject.parentKey}.first if policyProductList.size > 0
        elsif(currentTagObject != nil && currentTagObject.is_a?(Party) && ["PROPOSER","PRIMARY","JOINT","PROPCUMINS"].include?(currentTagObject.roleCd.to_s))
            prdMetadataChkReqd = false
        end
        productDO = nil
        if baseProduct.to_s != ""
            prdMetadataChkReqd = true
            # add readonly fields only for that quotationProduct
            productDO = baseProduct.getProduct
            if productDO.to_s == ""
                productDO = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
                # baseProduct.setProductDO(productDO) Need to check as to how to set this as we don't have setProduct method in baseProduct
            end
        else
            productDO = $currentProduct
        end
        baseProduct = @baseIO.baseDO.getBaseProduct if baseProduct == nil
        if productDO.to_s != "" && prdMetadataChkReqd
            if(baseProduct != nil && baseProduct.is_a?(PolicyProduct) && baseProduct.productSeq.to_s != "")
                #create a Product Prdfield MetaData Cache and if the field has metadata in this replace it with the UIMetaData
                metadataHash = loadProductAdditionalMetadata(@baseIO, baseProduct, currentTagObject, metadataHash, companyMetadata)
            end
        end

        if currentTagObject.is_a?(ServiceDocument)
            #Check if the document is mandatory then set in the metadata
            docCatgDO = DocumentCategory.loadObject(:first, :conditions=>{{:name=>'categoryCd'}=>currentTagObject.docCategoryCd.to_s})
            if docCatgDO.to_s != ""
                documentCategoryMapDO = DocumentCategoryMap.loadObject(:all, :conditions=>{{:name=>'categoryCd'}=>docCatgDO.categoryCd.to_s})

                documentCategoryMapDO.each do |documentCategoryMapDO|
                    if documentCategoryMapDO.documentCd.to_s == currentTagObject.documentCd.to_s
                        if documentCategoryMapDO.isMandatoryFl.to_s == "YES"
                            metadataHash["#{currentTagObject.uniqueKey}"]["documentCd"]["MINOCCURS"] = "1"
                        end

                        documentDO = Document.loadObject(:first, :conditions=>{{:name=>'documentCd'}=>currentTagObject.documentCd.to_s})
                        if documentDO
                            # check if the document description is a label key.. in that case get the tooltip as well
                            tooltipVal = Localization::LabelCache.instance.getLabelToolTipValue(documentDO.documentDesc.to_s)
                            metadataHash["#{currentTagObject.uniqueKey}"]["documentCd"]["TOOLTIP"] = tooltipVal if tooltipVal.to_s != ""
                        end
                    end
                end
            end
        end

        #set Enabled to NO if policy is accepted/submitted/signed
        statusCd = @baseIO.baseDO.statusCd.to_s
        updateEnableMetadataProperty(currentTagObject,metadataHash,companyMetadata = nil)

        
        # in case of requirment pending,make editable service document otherwise make it read only
        if statusCd.to_s == "SUBMITTED_UWCUSTOMERINPUT"
            if currentTagObject.is_a?(ServiceDocument) && currentTagObject.isAutoGeneratedFl.to_s == "YES_UW"
                # do nothing
            else
                metadataHash[currentTagObject.uniqueKey].each do |k, v|
                    metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
                end
            end
        end

        if @baseIO.baseDO.isInvalid
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
            end
        end
        if currentTagObject != nil && (statusCd == "ACCEPTED" || statusCd == "SIGNED" || statusCd == "PAYMENTDONE" || statusCd == "PAYMENTPENDING" || statusCd == "PAYMENTSUCCESS" || statusCd == "PAYMENTFAILED" || statusCd == "SUBMITTED" || statusCd == "DECLARATIONCOMPLETE" || @baseIO.baseDO.policyNum.to_s != "")
            if isCompleted
                metadataHash[currentTagObject.uniqueKey].each do |k, v|
                    metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
                end
            end
        end
        return metadataHash
    end

    def updateEnableMetadataProperty(currentTagObject,metadataHash,companyMetadata = nil)
        agent_type_sign = nil
        if currentTagObject.is_a?(ServiceSignature)
            agent_type_sign = currentTagObject.signatureTypeCd
        end
        statusCd = @baseIO.baseDO.statusCd.to_s
        if statusCd == "ACCEPTED" || isCompleted
            # Additional conditions based on object type and completion status
            if (currentTagObject.is_a?(PolicyAgent) || currentTagObject.is_a?(ServiceDocument)) && !isCompleted
              # do nothing
            elsif agent_type_sign && agent_type_sign == "AGENTTYPE"
              # do nothing
            else
              # Disable the field
              if metadataHash[currentTagObject.uniqueKey]
                metadataHash[currentTagObject.uniqueKey].each do |k, v|
                    metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
                end
              end
            end
        end 

        # Handle the freeze status based on excluded statuses
        inward_status_excluded = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'POLICYSTATUS_NOT_TO_FREEZE'})

          if statusCd && inward_status_excluded
             fieldsToInclude = inward_status_excluded.to_s != "" && inward_status_excluded.value.to_s != "" ? inward_status_excluded.value.split(",") : []
            unless fieldsToInclude.include?(statusCd)
              if metadataHash[currentTagObject.uniqueKey]
                metadataHash[currentTagObject.uniqueKey].each do |k, v|
                    metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
                end
              end
            end
        end   

    end    

    def addPartyOtherIncome
        parsedData = parseRequestBodyParams
        responseHash = {}
        @lookupHash = {}
        @entityHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        partyOtherIncome = PartyOtherIncome.new
        @entityHash["PartyOtherIncome"] = partyOtherIncome.hashForApi(false)
        if isMetadataRequired
            evaluateContextForObject(partyOtherIncome)
            @metadataHash = processMetadata(partyOtherIncome)
            contextEnd
        end
        @success = true
        @message = 'Successful'
        responseHash = generateResponseHash(isMetadataRequired)

        render :string => responseHash.to_json
    end

    def acceptPolicy(id, parseData)
        policy = @baseIO.baseDO
        responseHash = {}
        responseHash["success"] = false
        @success = false
        signatureContainer = SignatureContainer.loadObject(:first,
            :conditions => {
                :entityGuid => policy.guid
            }
        )
        if signatureContainer
            errors = Hash.new
            # process
            MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
            # unless policy.visitedTabs.to_s.include?('tab_signature')
            #     policy.visitedTabs = policy.visitedTabs.to_s + "," + 'tab_signature'
            # end
            # policy.persistAll
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, policy.visitedTabs)
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                policy.signatureStatus = "SUCCESS"
                policy.statusCd = "ACCEPTED"
                policy.proposalSignedDt = Time.new.strftime("%F 00:00:00 %z")
                policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                if policy.isBackdatedFl.to_s == "YES"
                    policy.policyCommencementDt = policy.quotationDt
                else
                    policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end
                if policy.isBackdatedFl.to_s == "YES"
                    policy.riskCommencementDt = policy.quotationDt
                else
                    policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                # if $rhoconfig[:fuw_applicable] #check flag here
                #      MobiSys::PolicyService.executeSubmit(false,policy)
                # end

                $policyIO = MobiSys::IO::PolicyIO.new
                $policyIO.baseDO = policy.cloneObject
                MobiSys::UIGenUtilEapp.findTemplatePageMapping($policyIO,"EAPP")
                MobiSys::UIGenUtilEapp.getHtmlStringandGeneratePDF(true, $policyIO)
                filehtmlArray = Array.new

                filehtml = ''
                filehtml << '<!DOCTYPE html>'
                filehtml << '<html lang="en">'
                filehtml << '<head>'
                filehtml << '<meta charset="utf-8">'
                filehtml << '</head>'
                filehtml << '<body>'
                totalPages = $policyIO.htmlContent.size
                skipPageNumber = 0
                totalSkipNumber = 0
                $policyIO.htmlContent.each_pair do |_pageNumber, page|
                    totalSkipNumber -= 1 if page['content'].include? '$SKIPPAGENUMBER$'
                end

                $policyIO.htmlContent.each_pair do |pageNumber, page|
                    content = page['content']
                    if page['content'].include? '$ZEROMARGIN$'
                        content.gsub!('$ZEROMARGIN$', '')
                        filehtml << '<div style="margin:0px !important;padding:0px !important;">'
                    else
                        filehtml << '<div class="bodyDiv">'
                    end
                    if content.include? '$SKIPPAGENUMBER$'
                        skipPageNumber -= 1
                        content.gsub!('$SKIPPAGENUMBER$', '')
                        content << if pageNumber != totalPages
                                    '<pd4ml:page.break></div></div>'
                                else
                                    '</div>'
                                end
                    else
                        content.gsub!('$PAGENUMBER$', (pageNumber + skipPageNumber).to_s)
                        content.gsub!('$TOTALPAGENUMBER$', (totalPages + totalSkipNumber).to_s)
                        content << if pageNumber != totalPages
                                    '<pd4ml:page.break></div></div>'
                                else
                                    '</div>'
                                end
                    end
                    filehtml << content
                end
                filehtml << '</body>'
                filehtml << '</html>'
                filehtml.gsub!('/public/jquery/', '')
                filehtml.gsub!('/public/js/RGraph/', '')
                filehtml.gsub!('/public/js/', '')
                filehtml.gsub!('/public/images/SalesIllustration/', '')
                filehtml.gsub!('/public/images/outputimages/', '')
                filehtml.gsub!('/public/css/', '')

                outputHash = {}
                outputHash["html1"] = filehtml
                outputHash["htmlCount"] = "1"
                outputHash["graphJSON"] = $policyIO.graphJSON

                jsonFileName= Rho::RhoApplication.userFolder + File::SEPARATOR + "Policy_#{policy.proposalNum.gsub('/','')}_ACCEPT.json"
                file = File.open(jsonFileName,'w+b')
                encryptedContent = MobiSys::Encryption.encryptAndEncodeContent(outputHash.to_json)
                file.write(encryptedContent)
                file.close

                inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                paymentMethodCd = inward.InwardDetailsList[0].paymentMethodCd if inward.InwardDetailsList.size > 0 if inward
                if paymentMethodCd.to_s == "IPG"
                    isValid = true
                    message = nil
                    if policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                        payer = policy.getPayerParty("INITIAL")
                        syncEntities = Hash.new
                        inputHash = Hash.new
                        inwardEntity = inward.hashForSync
                        onlinePartyClass = "list#{payer.class.name}DOList"
                        inwardEntity[onlinePartyClass] = [payer.hashForSync]
                        syncEntities[Inward.onlineClassName] = [inwardEntity]
                        inputHash[Inward.onlineClassName] = ::JSON.generate([syncEntities.to_json])
                        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                        offlineEntities = Hash.new
                        offlineEntities[inward.class.name.to_s+ inward.guid.to_s] = inward
                        offlineEntities[payer.class.name.to_s+ payer.guid.to_s] = payer
                        if has_network
                            begin
                                clazz = Class.new do
                                include MobiSys::BrowserHelper
                                end
                                obj = clazz.new
                                response = obj.doJSONPost('/MergeEntities.run', ::JSON.generate(inputHash))
                                if response.to_s != ''
                                    resultsHash = Rho::JSON.parse(response)
                                else
                                    resultsHash = {}
                                end
                                resultsHash.each do |key,value|
                                    if value.to_s != ""
                                        entities = Rho::JSON.parse(value)
                                    else
                                        entities = []
                                    end
                                    if offlineEntities
                                        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                                        db.start_transaction

                                        entities.each do |mainEntity|
                                            next if mainEntity[key].to_s == ''
                                            inwardEntities = Rho::JSON.parse(mainEntity[key])
                                            inwardEntities.each do |inward|
                                                className = inward["class"].slice((inward["class"].rindex('.')+1)..(inward["class"].rindex('DO')-1))
                                                offlineEntity = offlineEntities[className+inward['guid']]

                                                if inward["listPartyDOList"] and inward["listPartyDOList"].size > 0
                                                    #Party Entity Merge online and offline
                                                    partyHash = inward["listPartyDOList"][0]
                                                    partyClassName = partyHash["class"].slice((partyHash["class"].rindex('.')+1)..(partyHash["class"].rindex('DO')-1))
                                                    offlinePartyEntity = offlineEntities[partyClassName+partyHash['guid']]

                                                    onlinePartyEntity = MobiSys::MobiSysEntitySchema.from_hash(partyClassName,partyHash)
                                                    if offlinePartyEntity and onlinePartyEntity and onlinePartyEntity.versionID != -1
                                                        offlinePartyEntity.merge(onlinePartyEntity)
                                                        offlinePartyEntity.persist('fromSync')
                                                        if offlinePartyEntity.respond_to?('afterSync'.to_sym)
                                                            offlinePartyEntity.afterSync
                                                        end
                                                    end
                                                end

                                                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,inward)
                                                if onlineEntity.versionID == -1 and offlineEntity
                                                    offlineEntity.destroy
                                                elsif offlineEntity
                                                    offlineEntity.merge(onlineEntity)
                                                    offlineEntity.persist('fromSync')
                                                    if offlineEntity.respond_to?('afterSync'.to_sym)
                                                        offlineEntity.afterSync
                                                    end
                                                else
                                                    onlineEntity.persist
                                                    if onlineEntity.respond_to?('afterSync'.to_sym)
                                                        onlineEntity.afterSync
                                                    end
                                                end
                                            end
                                        end
                                        db.commit
                                    end
                                end
                            rescue StandardError => se
                                puts "Error while generating entities hash for sync =>" + se.to_s
                                isValid = false
                                message = getLabelValue('SERVERERROR')
                            end
                        else
                            isValid = false
                            message = getLabelValue('ERR_NETWORK')
                        end
                    else
                        isValid = false
                        message = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
                    end
                    if isValid
                        policy.statusCd = "PAYMENTPENDING"
                        @success = true
                        @message = "Successful"
                        responseHash["success"] = true
                    else
                        policy.statusCd = "PENDING"
                        responseHash['message'] = message if message
                    end
                else
                    @success = true
                    @message = "Successful"
                    responseHash["success"] = true
                end
            else
                responseHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
                responseHash["validationerrors"] = errors
            end
            policy.persistAll
        else
            responseHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
        end
        # process
        return responseHash
    end


    def autoUnderwrite
        PolicyUnderwriting polUw = PolicyUnderwriting.new
        polUw.setPolicyIO(this.io);
        polUw.autoUnderwrite();
    end
    def createRevisedQuotation(id,parsedData)
        policy = @baseIO.baseDO
        originalQuotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
        newQuotation = MobiSys::PolicyBO.convertToQuotation(policy)
        #RhoLog.error("CREATEREVISEDQUOTATION","originalQuotation.quoteStatusCd :- #{originalQuotation.quoteStatusCd}")
        #RhoLog.error("CREATEREVISEDQUOTATION","newQuotation.quoteStatusCd :- #{newQuotation.quoteStatusCd}")
        #RhoLog.error("CREATEREVISEDQUOTATION","originalQuotation.object :- #{originalQuotation.object}")
        #RhoLog.error("CREATEREVISEDQUOTATION","newQuotation.object :- #{newQuotation.object}")
        #RhoLog.error("CREATEREVISEDQUOTATION","newQuotation.getBaseProduct.QuotationProductInvestmentFundList :- #{newQuotation.getBaseProduct.QuotationProductInvestmentFundList}")
        if originalQuotation.quoteStatusCd == "COMPLETED"
            newQuotation.quotationRefNum = originalQuotation.quotationRefNum
            newQuotation.object = originalQuotation.object
            newQuotation.guid = originalQuotation.guid
        else
            newQuotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
            newQuotation.quoteStatusCd = "COMPLETED"
            newQuotation.signature = ""
            newQuotation.signatureDt = ""
            newQuotation.guid = newQuotation.object.gsub(".","_")
        end
        #set old quotation status cd = REVISED
        #set object of new quotation in Policy (needs as per new APIs)

        newQuotation.productId = originalQuotation.productId
        newQuotation.productVersion = originalQuotation.productVersion
        newQuotation.productTypeCd = originalQuotation.productTypeCd
        newQuotation.productFamilyCd = originalQuotation.productFamilyCd
        newQuotation.policyYear = originalQuotation.policyYear
        newQuotation.withdrawalFl = originalQuotation.withdrawalFl
        newQuotation.childUserId = originalQuotation.childUserId
        newQuotation.quotationExpiryDt = originalQuotation.quotationExpiryDt
        newQuotation.issueDt = originalQuotation.issueDt
        newQuotation.visitedTabs = originalQuotation.visitedTabs
        newQuotation.persistAll
        # policy.quotationSeq = newQuotation.object
        policy.quotationRefGuid = newQuotation.uniqueKey
        policy.quotationRefNum = newQuotation.quotationRefNum
        policy.counterOfferAcceptDt = Time.new #.strftime("%F 00:00:00 %z") #counter offer accept date is changed to timestapm in Online.
        policy.persistAll
        responseHash = {}
        @success = true
        @message = "Successful"
        responseHash["success"] = true

        return responseHash
    end

    def updateLeadParty
        policy = @baseIO.baseDO
        leadId = policy.leadId
        lead = Lead.loadObject( :first, :conditions => { :leadId => leadId } )
        if lead
            leadParty = lead.getLeadParty
            proposerParty = policy.getParty("PROPOSER")
            fieldsToExcludeArr = ["guid"]
            leadParty = MobiSys::CommonUtil.copyFields(proposerParty, leadParty, fieldsToExcludeArr)
            lead.persistAll
        end
    end

    def filterLookupData(lookupKey)
        listLookupDataFiltered = []
        if(@listLookupsToBeFiltered.include?(lookupKey))
            baseProduct = @baseIO.baseDO.getBaseProduct
            if baseProduct
                $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) 
            elsif @baseIO.baseDO.baseProductId.to_s != ""
                #change logic to fetch only productseq in below load object and load children false
                product = Product.loadObject(:first,:conditions=>{
                    { :name => 'productId' } => @baseIO.baseDO.baseProductId.to_s, 
                    { :name => 'productVersion' } => @baseIO.baseDO.productVersion.to_s})
                $currentProduct ||= MobiSys::ProductUtil.getProduct(product.id.to_s) 
            end
            listLookupDataFiltered = MobiSys::ProductUtil.filterLookupDataOnBasisOfProduct($currentProduct, lookupKey)
        else
            listLookupDataFiltered = super(lookupKey)
        end
        return listLookupDataFiltered
    end

    # API to be called when we need to edit quotation from policy.
    def editQuotation(id, parseData)
        # Edit quotation from policy
        @baseIO.baseDO.statusCd = "LOCKED"
        @baseIO.baseDO.persistAll
        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => @baseIO.baseDO.guid})
        if signatureContainer
            signatureContainer.ServiceSignatureList.each do |signature|
                signature.destroy
            end
        end
        process()
        policy = @baseIO.baseDO
        MobiSys::QuotationService.reopenQuotation(@baseIO.baseDO)

        policyPortfolioModelCode = policy.PolicyProductList
                              .find { |ppd| 
                                ppd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

        if policy.quotationRefGuid.to_s != ""
            quotation = Quotation.find(:first, :conditions => {:guid => policy.quotationRefGuid })
            quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
            quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
        end
                    
        MobiSys::CommonUtil.addUserActivity('EDITPROPOSAL_OFFLINE',"quotationRefNum => #{policy.quotationRefNum},proposalNum => #{policy.proposalNum},quotationGuid => #{policy.guid},quotationfnaId => #{policy.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
    end

    # def isCompleted
    #     isCompleted=false;
    #     policy = @baseIO.baseDO
    #     if(policy.statusCd.to_s == "SUBMITTED" || policy.statusCd.to_s == "SUBMITTED_UWCOMPLETE")
    #         isCompleted=true
    #     end
    #     return isCompleted
    # end

end

begin
    require 'Policy/policy_controller_company'
rescue LoadError => e
    puts 'policy_controller_company not included'
end

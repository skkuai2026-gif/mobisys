require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisysuihelper_jazz'
require 'Policy/policy_b_o'
require 'Product/product_b_o'

module MobiSys
    class PolicyService
        extend MobiSys::BrowserHelper

        def self.checkForValidADADoc(serviceDoc,policy)
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection 
            if has_network
                # hashArray = Array.new
                entityPackage = Hash.new
                tempList = []
                tempImageList = []
                serviceDoc.each do |doc|
                    tempList.push doc.hashForSync
                    imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>doc.uniqueKey})
                    imageList.each do|img|
                        tempImageList.push img.hashForSync
                    end
                end

                syncEntities = Hash.new
                syncEntities[ServiceDocument.onlineClassName] = ::JSON.generate([{ServiceDocument.onlineClassName => tempList}.to_json])
                syncEntities[Image.onlineClassName] = ::JSON.generate([{Image.onlineClassName => tempImageList}.to_json])
                syncEntities["PROPOSALNUM"] = ::JSON.generate([{"PROPOSALNUM" => [policy.proposalNum]}.to_json])
                syncEntities["USERID"] = ::JSON.generate([{"USERID" => [$userId.to_s]}.to_json])
                
                begin
                    json = ::JSON.generate(syncEntities)
                rescue StandardError => se
                    puts "Error while generating entities from hash =>" + se.to_s
                end
                response = doJSONPost('/GenAIADA.run', json)
                if response.to_s != ''
                    resultsHash = Rho::JSON.parse(response)    
                else
                    resultsHash = {}
                end
                if resultsHash["status"] == "failed"
                    exception = []
                    exception = resultsHash["errorList"]
                    return exception
                else
                    exception = []
                    return exception
                end
            else
                Alert.show_popup({
                    :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORKREQUIREDFORADA'),
                    :title => '',
                    :icon => :alert,
                    :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
                })
                return []
            end
        end

        def self.getTotModalPremium(policy)
            # p "inside getTotModalPremium************"
            totModalPremium = 0.0
            policy.PolicyProductList.each do |policyProduct|
                if (policyProduct != nil && policyProduct.modalPremium != nil )
                    totModalPremium = totModalPremium.to_f + policyProduct.modalPremium.to_f
                    # p "totModalPremium==============#{totModalPremium}"
                end
            end
            return totModalPremium
        end

        #Method to submit policy to online server/perform underwriting
        def self.executeSubmit(doPolicySubmit=true, policy)
            isValid = true
            policyNum = ""
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid,policy.visitedTabs)
            isValid = false unless errors.empty?
            isValid = false if doPolicySubmit && policy.statusCd.to_s == "DECLARATIONCOMPLETE" && policy.signatureStatus.to_s != "SUCCESS"
            networkPresent = false
            facetData = nil
            tempHash = {}

            if isValid
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection 
                isOnlinePayment = false
                paymentSerialNumber = ""
                policyAdditionalField = policy.getPolicyAddionalField("PAYMENT")
                policyAdditionalFieldSecondObject = policy.getPolicyAddionalField("000")
                paymentSerialNumber = policyAdditionalFieldSecondObject.field2 if policyAdditionalFieldSecondObject.to_s != "" 
                isOnlinePayment = true if policyAdditionalField.to_s != "" && policyAdditionalField.field15.to_s == "YES"
                updatePaymentStatus(policy) if isOnlinePayment
                # has_network = false if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE" #uncomment to test offline flow.
                policyPortfolioModelCode = policy.PolicyProductList
                                          .find { |ppd| 
                                            ppd.productTypeCd == "PLAN"
                                          }&.portfolioModelCd

                if policy.quotationRefGuid.to_s != ""
                    quotation = Quotation.find(:first, :conditions => {:guid => policy.quotationRefGuid })
                    quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
                    quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
                end

                transactionSuccessfull = false 
                if has_network
                    networkPresent = true
                    if policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                        MobiSys::PolicyService.leadEmailOtpSent(policy)
                        duplicatePolicy = false
                        exceptionPresent = false
                        policyNum = ""
                        MobiSys::CommonUtil.addUserActivity('SUBMIT_OFFLINE',"quotationRefNum=>#{policy.quotationRefNum},proposalNum =>#{policy.proposalNum},policyGuid=>#{policy.guid},policyfnaId=>#{policy.fnaId},paymentSerialNumber => #{paymentSerialNumber},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
                        
                        if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE"
                            policyNum = doJSONPost('/checkPolicyDupSUNPH.run', policy.proposalNum)
                        end
                        if policyNum.to_s == "" || policy.statusCd.to_s == "SUBMITTED_UWCOMPLETE"
                            if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE"
                                policy.uwDecisionCd = "COMPLETE"
                                #Need# to remove this submitted status. the fix needs to be done in online task.                        
                                
                            end
                            policyArray = Array.new
                            serviceQuestionResponseArray = Array.new
                            serviceDocumentRequirementArray = Array.new
                            partyImageList = Array.new
                            serviceSignatureArray = Array.new
                            inwardArray = Array.new

                            policyProduct = policy.getBaseProduct
                            policyProduct.pdfPeriod = 0 if policyProduct != nil and policyProduct.pdfPeriod.to_s == ""

                            policy.quotationSeq = nil
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
                                        #code added to make serviceDocument status received if document is selected and image exist 
                                        partyDocumentList.each do|partydoc|
                                            imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                            partyImageList.concat imageList if imageList.size > 0

                                            if partydoc.acceptanceStatusCd.to_s != "FULFILLED" && imageList.size > 0 && partydoc.documentCd.to_s != "" && partydoc.documentCd != nil
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
                            if doPolicySubmit
                                policy.policyStatusCd = "DECLARATIONCOMPLETE"
                                #generating pdf for illustration before submitting application
                                emailResponseHash = MobiSys::PolicyService.generateSIPDF(policy)
                            else
                                policy.policyStatusCd = "AUTOUW"
                            end
                            quotation = Quotation.loadObject(:first, :conditions=>{:guid=>policy.quotationRefGuid}) if policy && policy.quotationRefGuid != nil
                            policy.policyIssueDt = quotation.issueDt
                            policy.userId = MobiSys::Encryption.encryptContent($userId) if $userId
                            policy.quotationSeq = quotation.id if quotation.id
                            policyArray.push(policy)

                            csaAppToParty = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"CSAAPPTOPARTY"})
                            quotProposerParty = quotation.getPartyByRole('PROPOSER') if quotation
                            fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'fnaNum'}=>quotation.fnaId}) if quotation.fnaId.to_s != ""
                            leadRPQ = LeadRPQ.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'rpqId'}=>fnaRequest.addtnField1Str}) if csaAppToParty && quotProposerParty && csaAppToParty.actionValue.include?(quotProposerParty.partyTypeCd) && fnaRequest && fnaRequest.addtnField1Str.to_s != ""
                            rpqResponse = RPQResponse.loadObject(:all, :conditions => { :rpqId => leadRPQ.rpqId.to_s }) if leadRPQ && leadRPQ.rpqId.to_s != ""

                            syncEntities = Hash.new
                            syncEntities[Policy.onlineClassName] = policyArray
                            syncEntities[ServiceQuestionResponse.onlineClassName] = serviceQuestionResponseArray if serviceQuestionResponseArray.size > 0
                            syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
                            syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
                            syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                            syncEntities[Inward.onlineClassName] = inward if inward
                            syncEntities[FNARequest.onlineClassName] = fnaRequest if fnaRequest && csaAppToParty && quotProposerParty && csaAppToParty.actionValue.include?(quotProposerParty.partyTypeCd)
                            syncEntities[LeadRPQ.onlineClassName] = leadRPQ if leadRPQ
                            syncEntities[RPQResponse.onlineClassName] = rpqResponse if rpqResponse
                            syncEntities[Quotation.onlineClassName] = quotation if quotation

                            if fnaRequest
                                signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => fnaRequest.guid})
                                
                                if signatureContainer
                                    signatureContainer.ServiceSignatureList.each do |sign|
                                        sign.id = nil
                                        sign.versionID = nil
                                        serviceSignatureArray.push(sign)
                                    end
                                end
                                syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                            end

                            # if quotation  #SUNSS 1372
                            #     quotsignatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => quotation.guid})
                            #     # serviceSignatureArray = signatureContainer.ServiceSignatureList if signatureContainer
                            #     if quotsignatureContainer
                            #       quotsignatureContainer.ServiceSignatureList.each do |sign|
                            #             sign.id = nil
                            #             sign.versionID = nil
                            #             serviceSignatureArray.push(sign)
                            #         end
                            #     end
                            #     syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                            # end

                            servSignArray = syncEntities[ServiceSignature.onlineClassName]
                            servSignArray.each do |servSign|
                                if servSign.signature.to_s != "" && servSign.signature.to_s.start_with?('ZLIBCMP')
                                    compressed_signature = servSign.signature.gsub!('ZLIBCMP', '')
                                    decoded_compressed_signature = MobiSys::Encryption.decodeContents(compressed_signature)
                                    original_signature = MobiSys::Encryption.unZipData(decoded_compressed_signature)
                                    servSign.signature = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(original_signature)
                                end
                            end

                            syncEntities[ServiceSignature.onlineClassName] = servSignArray if servSignArray

                            transactionSuccessfull = false

                            if !doPolicySubmit || (emailResponseHash != nil && !emailResponseHash.empty?)
                                transactionSuccessfull = true # if generateSIPDF is successfull
                                responseHash = {}
                                exceptionMessageArray = []
                                responseHash = PolicyUtil::ApplicationUtil.invokeOnlineService(syncEntities,"/callPolicyService.run",true)
                                transactionSuccessfull = false # resetting the flag again after invoking next service
                                $taskExceptionHash = []
                                if responseHash != nil && !responseHash.empty?
                                    taskExceptions = responseHash["com.c2lbiz.symbiosys.systemcommon.dataobjects.service.TaskExceptionDO"]
                                    responsePolicy = responseHash["com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO"]
                                    policyHash = Rho::JSON.parse(responsePolicy)

                                    resPolicy = policyHash.first

                                    # Access applicationRefNum
                                    application_ref_num = resPolicy['applicationRefNum']
                                    exceptions = Rho::JSON.parse(taskExceptions)
                                    exceptions.each do |exception|
                                        # exception.persistAll
                                        if exception["exceptionCd"] != "ERR_PROPOSALSUBMIT"
                                            tab_id = exception["tabId"]
                                            field_ref = exception["fieldReference"]
                                            message = exception["exceptionMessage"]

                                            # field_id, field_name = field_ref.to_s.split("-", 2) if field_ref

                                            if field_ref
                                              field_id, field_name = field_ref.to_s.split("-", 2)
                                            else
                                              field_id = field_name = nil
                                            end

                                            # Build required nested hash
                                            result = {
                                              tab_id => {
                                                field_id => {
                                                  field_name => message
                                                }
                                              }
                                            }
                                            exceptionMessageArray << result
                                            # exceptionMessageArray << exception["exceptionMessage"]
                                            exceptionPresent = true

                                        #     $taskExceptionHash.push(TaskException.new(
                                        #     :entitySeq=>"",
                                        #     :fieldReference=>"",
                                        #     :exceptionCd=>"exceptionCd",
                                        #     :tabId=>"tabId",
                                        #     :exceptionMessage=>"exceptionMessage",
                                        #     :correspondenceMessage=>"correspondenceMessage"
                                        # ))
                                        end
                                    end

                                    merged_output = {}
                                    exceptionMessageArray.each do |ex|
                                      ex.each do |tab, data|
                                        merged_output[tab] ||= {}

                                        data.each do |field_id, field_hash|
                                          merged_output[tab][field_id] ||= {}   

                                          field_hash.each do |field_name, msg|
                                            merged_output[tab][field_id][field_name] = msg
                                          end
                                        end
                                      end
                                    end
                                    exceptionMessageArray = merged_output

                                    if exceptionPresent
                                        # policy.update_attributes
                                        policy.update_attributes(:policyStatusCd => nil)
                                        transactionSuccessfull = false # if callPolicyService is failed
                                    else
                                        transactionSuccessfull = true # if callPolicyService is successfull
                                        policy.statusCd = "SUBMITTED"
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
                                    end

                                    if policyAdditionalFieldSecondObject.to_s != "" && application_ref_num.to_s != ""
                                        policyAdditionalFieldSecondObject.field2 = application_ref_num.to_s
                                        policyAdditionalFieldSecondObject.persistAll
                                    elsif policyAdditionalFieldSecondObject.to_s != "" && paymentSerialNumber.to_s != ""
                                        policyAdditionalFieldSecondObject.field2 = paymentSerialNumber.to_s
                                        policyAdditionalFieldSecondObject.persistAll
                                    end

                                    #################
                                    # transactionSuccessfull = true # if callPolicyService is successfull
                                else                         
                                   transactionSuccessfull = false # callPolicyService failed 
                                end
                            end
                        else
                            policy.applicationRefNum = policyNum
                            policy.statusCd = "SUBMITTED"

                            policy.persistAll
                            duplicatePolicy = true
                        end
                    elsif policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                        serviceDocumentList = []
                        policy.PartyList.each do |party|
                            documentContainer = DocumentContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'}=> party.guid,
                                    {:name=>'policyGuid'}=> policy.guid
                                },
                                :op => 'AND',
                                :loadChild => 'false'
                            )
                            if documentContainer
                                partyDocumentList = ServiceDocument.loadObject(
                                    :all,
                                    :conditions=>{
                                        {:name=>'partyGuid'}=> party.guid,
                                        {:name=>'parentKey'}=> documentContainer.object
                                    },
                                    :op => 'AND',
                                    :loadChild => 'false'
                                )
                                #code added to make sericeDocument status received if document is selected and image exist 
                                partyDocumentList.each do|partydoc|
                                    imageList = Image.loadObject(
                                        :all,
                                        :conditions=>{
                                            {:name=>'parentRefGuid'}=> partydoc.uniqueKey
                                        },
                                        :loadChild => 'false'
                                    )
                                    if partydoc.acceptanceStatusCd.to_s != "FULFILLED" && imageList.size > 0 && partydoc.documentCd.to_s != "" && partydoc.documentCd != nil
                                        partydoc.imageCount = imageList.size
                                        partydoc.acceptanceStatusCd = "FULFILLED"
                                        partydoc.persistAll
                                    end
                                end
                                serviceDocumentList.concat partyDocumentList
                            end
                        end
                        # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
                       # ##RhoLog.error("EXECUTE SUBMIT","serviceDocumentList :- #{serviceDocumentList}")
                        if $rhoconfig[:fuw_applicable] && (policy.uwDecisionCd.to_s == "" || policy.uwDecisionCd.to_s == "PENDING")
                            autoUWRule = PolicyUtil::AutoUWUtil.new
                            serviceDocumentList = autoUWRule.execute(policy, serviceDocumentList)
                            if policy.uwDecisionCd == "ACCEPTED" || policy.uwDecisionCd == "REFERTOMUW" || policy.uwDecisionCd == "ACCEPTEDEXCLUSION"
                                policy.statusCd = "SUBMITTED"
                            elsif policy.uwDecisionCd == "ACCEPTEDRATED"
                                policy.statusCd = "SUBMITTED_UWCUSTOMERINPUT" 
                            elsif policy.uwDecisionCd == "REQUIREMENTPENDING"
                                policy.statusCd = "SUBMITTED_UWCUSTOMERINPUT"
                            end
                            policy.persistAll
                            documentContainerHash = {}
                            serviceDocumentList.each do |servDoc|
                                next if servDoc.isAutoGeneratedFl.to_s == "YES"
                                #load document container only if the document is for a different party
                                documentContainer = nil
                                if documentContainerHash[servDoc.partyGuid] == nil
                                    documentContainer = DocumentContainer.loadObject(
                                        :first,
                                        :conditions=>{
                                            {:name=>'entityGuid'}=> servDoc.partyGuid,
                                            {:name=>'policyGuid'}=> policy.guid
                                        },
                                        :op => 'AND',
                                        :loadChild => 'false'
                                    )
                                    documentContainerHash[servDoc.partyGuid] = documentContainer
                                else
                                    documentContainer = documentContainerHash[servDoc.partyGuid]
                                end
                                if documentContainer
                                    documentContainer.addServiceDocument(servDoc)
                                end
                            end
                            documentContainerHash.each do |key, docContainer|
                                docContainer.persistAll
                            end
     
                        end
                        transactionSuccessfull = true
                    end
                else
                    networkPresent = false
                end

                if transactionSuccessfull
                    tempHash["success"] = true
                    if !doPolicySubmit
                        policy.statusCd = "UWCOMPLETE"
                        if facetData[:uwType].to_s == "TYPE1" || facetData[:uwType].to_s == "TYPE2"
                            policy.statusCd = "PAYMENTDONE" if !policy.getGatewayFlag
                            policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                        end
                        policy.persistAll
                        if facetData[:uwType] && (facetData[:uwType].to_s == "TYPE3" || facetData[:uwType].to_s == "TYPE4")
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid}) 
                            if signatureContainer.to_s == ""
                                signatureContainer = SignatureContainer.new(:entityGuid => policy.guid, :entityTypeCd => policy.class.name.to_s)
                            end
                    
                            counterOfferSignature = MobiSys::SignatureUtil.getCounterOfferSignature(policy, signatureContainer) if signatureContainer
                            if counterOfferSignature.signatureDt.to_s != ""
                                counterOfferSignature.signatureDt = getScreenDate(counterOfferSignature.signatureDt.to_s)
                            else
                                counterOfferSignature.signatureDt = getScreenDate(Time.new.strftime("%F 00:00:00 %z").to_s)
                            end
                        end

                        if facetData[:uwType] == "TYPE4"
                            quotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
                        end
                    end
                    # add user addUserActivity on SUBMIT_SUCCESSFUL_OFFLINE
                    MobiSys::CommonUtil.addUserActivity('SUBMIT_SUCCESSFUL_OFFLINE',"quotationRefNum=>#{policy.quotationRefNum},proposalNum =>#{policy.proposalNum},policyGuid=>#{policy.guid},policyfnaId=>#{policy.fnaId},paymentSerialNumber => #{paymentSerialNumber},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
                elsif !networkPresent
                    tempHash["success"] = false
                    tempHash["message"] = getLabelValue('REQUIRENETWORK')

                elsif exceptionPresent
                   RhoLog.error("exceptionMessageArray", "#{exceptionMessageArray}")

                   tempHash["success"] = false
                   tempHash["validationerrors"] = exceptionMessageArray

                    # break
                elsif duplicatePolicy
                    tempHash["success"] = false
                    tempHash["message"] = MobiSys::CommonUtil.replacePlaceHolders(MobiSys::BrowserHelper.getLabel('ERR_submitEappFromWeb'), [policy.applicationRefNum, policy.proposalNum]) 
                else
                    tempHash["success"] = false
                    tempHash["message"] = getLabelValue('SERVERERROR')
                end
            else
                tempHash["success"] = false
                tempHash["validationerrors"] = errors

                # tempHash["success"] = false
                # tempHash["message"] = "There are pending warnings generated on this case. Please contact system administrator."

            end


            return tempHash
        end

        def self.hasProposalExpired(quotation)
            proposalVersionMatrix = Lookupvalue.loadObject(
                :first,
                :conditions => {
                    {:name => 'cd'} => quotation.proposalVersion.to_s,
                    {:name => 'key'} => 'PROPOSALVERMATRIX'},
                :op => 'AND'
            )
            if proposalVersionMatrix
                proposalStartDt = proposalVersionMatrix.additionalField1
                proposalEndDt = proposalVersionMatrix.additionalField2
                currentTime = Time.now

                if proposalEndDt.to_s != ""
                    if currentTime.to_date >= MobiSys::ProductUtil.getDBDate(proposalStartDt.to_s).to_date && currentTime.to_date <= MobiSys::ProductUtil.getDBDate(proposalEndDt.to_s).to_date
                        return false
                    else
                        return true
                    end
                else
                    return false
                end
            end
        end

        def self.isRemoteSellingComplete(policy)
            isRemoteSellingCompleteFlag = false
            policyAdditionalFieldsList = policy.PolicyAdditionalFieldsList
            policyAdditionalFieldsList.each do|policyAdd|
               if policyAdd.additionalTypeCd.to_s == "000" 
                   if policyAdd.field17.to_s != "" && policyAdd.field17.to_s == "Y"
                    isRemoteSellingCompleteFlag = true
                  end
               end 
            end  
            return isRemoteSellingCompleteFlag  
        end

        def self.updatePaymentStatus(policy)
            offlineInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE") if policy != nil

            if offlineInward != nil
                has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
                inputHash = Hash.new
                inputHash["inwardGuid"] = offlineInward.guid
                className = Inward.onlineClassName

                if has_network
                    begin
                        clazz = Class.new do
                        include MobiSys::BrowserHelper
                        end
                        obj = clazz.new
                        response = obj.doJSONPost('/GetInwardData.run', ::JSON.generate(inputHash))
                        if response.to_s != ''
                            resultsHash = Rho::JSON.parse(response)
                        else
                            resultsHash = {}
                        end
                        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                        db.start_transaction

                        resultsHash.each do |key, value|
                            if value.to_s != ""
                                entities = Rho::JSON.parse(value)
                            else
                                entities = []
                            end

                            entities.each do |onlineInwardDO|
                                next if onlineInwardDO.to_s == ''
                                onlineInwardEntity = MobiSys::MobiSysEntitySchema.from_hash(offlineInward.class.name.to_s,onlineInwardDO)
                                if onlineInwardEntity.versionID == -1 and offlineInward
                                    offlineInward.destroy
                                elsif offlineInward
                                    offlineInward.merge(onlineInwardEntity)
                                    offlineInward.persist('fromSync')
                                    if offlineInward.respond_to?('afterSync'.to_sym)
                                        offlineInward.afterSync
                                    end
                                else
                                    onlineInwardEntity.persist
                                    if onlineInwardEntity.respond_to?('afterSync'.to_sym)
                                        onlineInwardEntity.afterSync
                                    end
                                end
                            end
                        end
                        db.commit
                        isValid = true
                    rescue StandardError => se
                        puts "Error while generating entities hash for sync =>" + se.to_s
                        isValid = false
                    end
                else
                    isValid = false
                end
            end
            return isValid
        end

        def self.transferToCustomer(policy)
            quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
            if policy != nil
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                showMessages = true
                if has_network 
                    begin
                        className = Policy.onlineClassName
                        entityPackage = Hash.new
                        entityPackage[className] = [policy.hashForSync]
                        inputHash = Hash.new
                        offlineEntitiesHash = Hash.new
                        offlineEntitiesHash[className] = Hash.new
                        currentEntityTypeHash = offlineEntitiesHash[className]
                        currentEntityTypeHash[policy.guid] = policy
 
                        questionContainers = QuestionContainer.loadObject(
                            :all, 
                            :conditions=>{
                                {:name=>'policyGuid'} => policy.guid
                            }
                        )
                        if questionContainers
                            tempList = []
                            questionContainers.each do |questionContainer|
                                questionContainer.ServiceQuestionResponseList.each do |sq|
                                    tempList.push sq.hashForSync
                                end
                            end
                            entityPackage[ServiceQuestionResponse.onlineClassName] = tempList.flatten
                        end
                        documentContainers = DocumentContainer.loadObject(
                            :all,
                            :conditions=>{
                                {:name=>'policyGuid'}=> policy.guid
                            }
                        )
                        if documentContainers
                            tempList = []
                            tempImageList = []
                            documentContainers.each do |documentContainer|
                                documentContainer.ServiceDocumentList.each do |sd|
                                    tempList.push sd.hashForSync
                                end
                            end
                            entityPackage[ServiceDocument.onlineClassName] = tempList.flatten
 
                            documentContainers.each do |documentContainer|
                                partyDocumentList = documentContainer.ServiceDocumentList 
                                partyDocumentList.each do|partydoc|
                                    imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                    imageList.each do|img|
                                        tempImageList.push img.hashForSync
                                    end
                                end
                            end
                            entityPackage[Image.onlineClassName] = tempImageList.flatten
                        end
 

                        inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                        if inward
                            inwardHash = inward.hashForSync
                            if inwardHash["listInwardDetailsDOList"]
                              inwardHash["listInwardDetailsDOList"].each do |detail|
                                if detail[:authCode].to_s != ""
                                   detail[:authCode] = detail[:authCode].to_s
                                end   
                              end
                            end
                           entityPackage[Inward.onlineClassName] = [inwardHash]
                           offlineEntitiesHash[Inward.onlineClassName] = Hash.new
                           currentEntityTypeHash = offlineEntitiesHash[Inward.onlineClassName]
                           currentEntityTypeHash[inward.guid] = inward
                        end
 
                        if policy.quotationRefNum.to_s != ""
                            entityPackage[Quotation.onlineClassName] = [quotation.hashForSync] if quotation
                        end
                        @quotProposerParty = quotation.getPartyByRole('PROPOSER')
                        csaAppToParty = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"CSAAPPTOPARTY"})
                        fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'fnaNum'}=>quotation.fnaId}) if quotation.fnaId.to_s != ""
                        
                        entityPackage[FNARequest.onlineClassName] = [fnaRequest.hashForSync] if fnaRequest

                        leadRPQ = LeadRPQ.loadObject(:first,:conditions => {{:name=>'rpqId'}=>fnaRequest.addtnField1Str}) if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd) && fnaRequest && fnaRequest.addtnField1Str.to_s != ""
                        
                        entityPackage[LeadRPQ.onlineClassName] = [leadRPQ.hashForSync] if leadRPQ

                        # rpqResponse = RPQResponse.loadObject(:all, :conditions => { :rpqId => leadRPQ.rpqId.to_s }) if leadRPQ && leadRPQ.rpqId.to_s != ""
                        
                         if leadRPQ
                            rpqtempList = []
                           leadRPQ.getRPQResponseList.each do |ss|
                                    rpqtempList.push ss.hashForSync
                                end
                                
                            entityPackage[RPQResponse.onlineClassName] = rpqtempList.flatten
                        end
                        # entityPackage[RPQResponse.onlineClassName] = [rpqResponse.hashForSync] if rpqResponse

                        # if policy.fnaId.to_s != ""
                        #   fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
                        #   entityPackage[Quotation.onlineClassName] = [quotation.hashForSync] if quotation
                        # end

                        signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => policy.guid})
                        signatureContainersQuot = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => quotation.guid})
                        signatureContainersFna = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => fnaRequest.guid}) if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd)          
                        tempList = []
                        if signatureContainers
                            signatureContainers.each do |serviceSignature|
                                serviceSignature.ServiceSignatureList.each do |ss|
                                    if ss && ss.signature.to_s == ""
                                       ss.signatureDt = nil
                                    end   
                                    tempList.push ss.hashForSync
                                end
                            end
                        end

                        if signatureContainersQuot
                            signatureContainersQuot.each do |serviceSignature|
                                serviceSignature.ServiceSignatureList.each do |ss|
                                    tempList.push ss.hashForSync
                                end
                            end
                        end

                        if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd) && signatureContainersFna
                            signatureContainersFna.each do |serviceSignature|
                                serviceSignature.ServiceSignatureList.each do |ss|
                                    tempList.push ss.hashForSync
                                end
                            end
                        end

                        entityPackage[ServiceSignature.onlineClassName] = tempList if tempList.size > 0

                        servSignArray = entityPackage[ServiceSignature.onlineClassName]
                        if servSignArray
                            servSignArray.each do |servSign|
                              if servSign[:signature].to_s != "" && servSign[:signature].to_s.start_with?('ZLIBCMP')
                                compressed_signature = servSign[:signature].sub(/^ZLIBCMP/, '')
                                decoded_compressed_signature = MobiSys::Encryption.decodeContents(compressed_signature)
                                original_signature = MobiSys::Encryption.unZipData(decoded_compressed_signature)
                                servSign[:signature] = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(original_signature)
                              end
                            end
                        end  

                        puts"servSignArray==========#{servSignArray}"
                        entityPackage[ServiceSignature.onlineClassName] = servSignArray if servSignArray

                        

                        inputHash[0] = ::JSON.generate([entityPackage.to_json])
                        
                        clazz = Class.new do
                        include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        json = ::JSON.generate(inputHash)
                        response = obj.doJSONPost('/PolicyTransferToCustomer.run', json)
                         
                        if response.to_s != ""
                            resultsHash = Rho::JSON.parse(response)
                        else
                            resultsHash = {}
                        end
                        resultsHash.each do |key,value|
                            next if value.to_s == '' || value.to_s == '[]' || value.empty?
                            # puts "Key: " + key.to_s
                            # puts "Value: " + value.to_s
                            entities = Rho::JSON.parse(value)
                            offlineEntities = offlineEntitiesHash[key]
                            count = 0
                            begin
                                db = ::Rho::RHO.get_db_partitions()['local']
                                db.start_transaction
                                entities.each do |mainEntity|
                                    next if mainEntity.to_s == ''
                                    saveEntitiesPostMerge(key,mainEntity,offlineEntities)
                                end#entities.each ends
                                db.commit
                            rescue StandardError => se
                                db.rollback
                                if showMessages
                                    Alert.show_popup({:title=>'',:message=>se.to_s, 
                                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                                else
                                    log('Error while syncing entities: ' + se.to_s)
                                    raise se
                                end
                            end
                        end

                        policyPortfolioModelCode = policy.PolicyProductList
                                                  .find { |ppd| 
                                                    ppd.productTypeCd == "PLAN"
                                                  }&.portfolioModelCd

                        quotationPortfolioModelCode = quotation.QuotationProductList
                                                      .find { |qpd| 
                                                        qpd.productTypeCd == "PLAN"
                                                      }&.portfolioModelCd

                        MobiSys::CommonUtil.addUserActivity('TRANSFER_OFFLINE',"quotationRefNum => #{policy.quotationRefNum},proposalNum => #{policy.proposalNum},policyGuid => #{policy.guid},policyfnaId => #{policy.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
                    end
                end
            end
        end

        def self.generateViewPaymentBody(afterStatusCheckInwardDOs)
            paymentDetails = getLabelValue("paymentDetails")
            refNum = getLabelValue("refNum")
            payOption = getLabelValue("payOption")
            amount = getLabelValue("amount")
            statusCd = getLabelValue("statusCd")
            transactionDt = getLabelValue("transactionDt")
            inwardStatusExcluded = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'CPAGSTATUS_ToHideViewPaymentDetails'})
            fieldsToExclude = inwardStatusExcluded.to_s != "" && inwardStatusExcluded.value.to_s != "" ? inwardStatusExcluded.value.split(",") : []


            emailBody = ""
            emailBody << "<html>\n"
            emailBody << " \n"
            emailBody << "<body>\n"
            emailBody << "<table width=\"100%\" id='payment-table' style=\"color: #555 !important;border-bottom: 1px solid grey !important;border-collapse:collapse !important;margin-bottom: 10%\">\n"
            emailBody << "  <thead>\n"
            emailBody << "     <tr>\n"
            emailBody << "     <th colspan=\"5\" style=\"background-color:none !important;text-align: center !important;border-bottom:none !important;border-collapse:collapse !important;\">"
            emailBody << (paymentDetails.to_s != "" ? paymentDetails : "")
            emailBody << "</th>\n"
            emailBody << "     </tr> \n"
            emailBody << " </thead>\n"
            emailBody << " <thead style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">\n"
            emailBody << "     <tr> "
            emailBody << ("<th width=\"22%\">")
            emailBody << (refNum.to_s != "" ? refNum.to_s : "")
            emailBody << ("</th><th width=\"18%\">")
            emailBody << (payOption.to_s != "" ? payOption.to_s : "")
            emailBody << ("</th><th width=\"22%\">");
            emailBody << (amount.to_s != "" ? amount.to_s : "")
            emailBody << ("</th><th width=\"15%\">")
            emailBody << (statusCd.to_s != "" ? statusCd.to_s : "")
            emailBody << ("</th><th width=\"23%\">")
            emailBody << (transactionDt.to_s != "" ? transactionDt.to_s : "")
            emailBody << ("</th></tr></thead>")


            if !afterStatusCheckInwardDOs.empty?
                afterStatusCheckInwardDOs.each do |iodata|
                    if iodata.inwardAmount.to_s != "" && iodata.instrumentStatusCd.to_s != ""
                        if !fieldsToExclude.include?(iodata.instrumentStatusCd.to_s) && iodata.inwardAmount.to_f > 0.0
                            transcationDate = ""
                            refrenceNum = ""
                            paymentMethod = ""
                            currencyCD = ""
                            status = ""
                            s = ""
                            if iodata.midCd.to_s != ""
                                trxDate = iodata.midCd.to_s
                                p "trxDate ======> #{trxDate}"
                                begin
                                    if trxDate.match(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/)
                                        p "inside if of format time"
                                        transcationDate = Time.strptime(trxDate.to_s, "%Y-%m-%d %H:%M:%S").strftime("%B %d, %Y %H:%M %P").to_s
                                        p "transcationDate ===> #{transcationDate}"
                                    else
                                        transcationDate = Time.strptime(trxDate.to_s, "%Y%m%d%H%M%S").strftime("%B %d, %Y %H:%M %P").to_s
                                        p "transcationDate ===> #{transcationDate}"
                                    end
                                rescue StandardError => se
                                    puts "Error while conversion time--- => #{trxDate}==" + se.to_s
                                end
                            end


                            refrenceNum = iodata.paymentFrequencyCd if iodata.paymentFrequencyCd.to_s != ""

                            if iodata.paymentMethodCd.to_s != ""
                                paymentMethod = Lookupvalue.getLookupValue("CPAGPAYMENTMETHOD", iodata.paymentMethodCd.to_s)
                                paymentMethod = iodata.paymentMethodCd.to_s if paymentMethod.to_s == ""
                            end

                            currencyCD = iodata.currency.to_s if iodata.currency.to_s != ""


                            s = MobiSys::UIGenUtilEapp.formatDoubleTwoDecimal(iodata.inwardAmount.to_s) if iodata.inwardAmount.to_s != ""

                            status = iodata.instrumentStatusCd.to_s if iodata.instrumentStatusCd.to_s != ""

                            emailBody << ("<tr>")
                            emailBody << ("<td style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">")
                            emailBody << (refrenceNum.to_s != "" ? refrenceNum : "")
                            emailBody << ("</td>")
                            emailBody << ("<td style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">")
                            emailBody << (paymentMethod.to_s != "" ? paymentMethod : "")
                            emailBody << ("</td>")
                            emailBody << ("<td style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">")
                            emailBody << (currencyCD.to_s != "" ? currencyCD : "")
                            emailBody << (s.to_s != "" ? s : "")
                            emailBody << ("</td>")
                            emailBody << ("<td style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">")
                            emailBody << (status.to_s != "" ? status : "")
                            emailBody << ("</td>")
                            emailBody << ("<td style=\"border-bottom: 1px solid grey !important;border-collapse:collapse !important;\">")
                            emailBody << (transcationDate.to_s != "" ? transcationDate : "")
                            emailBody << ("</td>")
                            emailBody << ("</tr>")

                        end
                    end
                end
            end
            emailBody << "</table></body>"
            emailBody << "<style type=\"text/css\">\n"
            emailBody <<"    .heading {\n"
            emailBody <<"        color: #555 !important;\n"
            emailBody <<"        border: none !important;\n"
            emailBody <<"        font-size: 1rem !important;\n"
            emailBody <<"        font-family: NotoSansCJKBold !important;\n"
            emailBody <<"    }\n"
            emailBody <<"     .mainArea {\n"
            emailBody <<"     width: 95% !important;\n"
            emailBody <<"     margin-left: auto !important;\n"
            emailBody <<"     margin-right: auto !important;\n"
            emailBody <<"    }\n"
            emailBody <<"\n"
            emailBody <<"    #payment-table {\n"
            emailBody <<"     font-size: 1rem !important;\n"
            emailBody <<"    }\n"
            emailBody <<"\n"
            emailBody <<"    #payment-table {\n"
            emailBody <<"     font-size: 0.8rem !important;\n"
            emailBody <<"     color: #555 !important;\n"
            emailBody <<"    }\n"
            emailBody <<"\n"
            emailBody <<"    #payment-table th {\n"
            emailBody <<"     font-family: NotoSansCJKBold !important;\n"
            emailBody <<"     font-weight: bold !important;\n"
            emailBody <<"     font-size: 1rem !important;\n"
            emailBody <<"     color: #555 !important;\n"
            emailBody <<"     text-transform: none !important;\n"
            emailBody <<"     padding: 10px !important;\n"
            emailBody <<"    }\n"
            emailBody <<"    \n"
            emailBody <<"     #payment-table td {\n"
            emailBody <<"     font-family: NotoSansCJKBold !important;\n"
            emailBody <<"     font-size: 1rem !important;\n"
            emailBody <<"     color: #555 !important;\n"
            emailBody <<"     text-align: center !important;\n"
            emailBody <<"     text-transform: none !important;\n"
            emailBody <<"     padding: 10px !important;\n"
            emailBody <<"    }\n"
            emailBody <<"\n"
            emailBody <<"    \n"
            emailBody <<"</style>\n"
            emailBody <<"\n"
            emailBody <<"<html>"

            return emailBody.to_s
        end

        def self.leadEmailOtpSent(policy)
            lead = Lead.loadObject(:first, :conditions=>{:leadId=>policy.leadId}) if policy && policy.leadId != nil
            if lead && lead.statusCd == "COMPLETED" && lead.uploadedFl.to_s != "EMAILANDOTPSENT" && lead.leadSourceOther.to_s == ""
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    begin
                        leadParty = lead.getLeadParty
                        advisorEmail = leadParty.getPartyEmail.emailAddress if leadParty.getPartyEmail
                        userId = $userId.to_s
                        advisorPhone = leadParty.getPartyContact("PHILIPPINESNUM").contactNum if leadParty.getPartyContact("PHILIPPINESNUM")
                        partyId = lead.leadId
                        syncEntities = Hash.new
                        syncEntities[Lead.onlineClassName] = ::JSON.generate([{Lead.onlineClassName => [lead.hashForSync]}.to_json])
                        syncEntities[Party.onlineClassName] = ::JSON.generate([{Party.onlineClassName => [leadParty.hashForSync]}.to_json])
                        begin
                            json = ::JSON.generate(syncEntities)
                        rescue StandardError => se
                            puts "Error while generating JSON of request data" + se.to_s
                        end
                        # leadDetailsHash = { emailId: advisorEmail, userId: userId, mobileNumber: advisorPhone, partyId: partyId, firstName: firstName}
                        # result = doJSONPost('/leadSendEmailOtp.run', syncEntities)
                        clazz = Class.new do
                            include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        result = obj.doJSONPost('/leadSendEmailOtp.run', json)
                        if result.to_s != ""
                            responseHash = Rho::JSON.parse(result.to_s)
                        end          
                    rescue StandardError => se
                        puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    end
                end
            end
            return
        end

        def self.createServiceQuestionResponse(partyGuid, questionSetCd, rowGuid, questionResponse,
            listServiceQuestionResponse,baseIO,questionnaireTypeCd)
            return if questionResponse == nil

            guid = questionResponse["guid"]
            serviceQuestionResponse = nil
            if guid.to_s != ""
                serviceQuestionResponse = ServiceQuestionResponse.new(:guid => guid)
            else
                serviceQuestionResponse = ServiceQuestionResponse.new
            end

            serviceQuestionResponse.entityGuid = baseIO.baseDO.uniqueKey
            serviceQuestionResponse.questionSetCd = questionSetCd
            serviceQuestionResponse.partyGuid = partyGuid
            serviceQuestionResponse.responseValue = questionResponse["responseValue"].to_s if questionResponse["responseValue"].to_s != ""
            serviceQuestionResponse.questionnaireTypeCd = questionnaireTypeCd
            serviceQuestionResponse.questionDataElementCd = questionResponse["dataElementCd"]
            serviceQuestionResponse.parentReferencePath = questionResponse["parentReferencePath"]
            serviceQuestionResponse.rowGuid = rowGuid
            serviceQuestionResponse.status = ""
            if questionnaireTypeCd.to_s == "AGENT"
                serviceQuestionResponse.visitedTabs = "tab_agentDeclaration"
            else
                serviceQuestionResponse.visitedTabs = "tab_questionnaire"
            end
            listServiceQuestionResponse.push(serviceQuestionResponse)
            return serviceQuestionResponse
        end

        def self.checkIfPolicySubmitted(policy)
            submitted = false
            # logic
            policyNum = doJSONPost('/checkPolicyDupSUNPH.run', policy.proposalNum)
            if policyNum.to_s != ""
                submitted = true
            end
            return submitted
        end

    end
end

begin 
    require 'Policy/policy_service_company'
rescue LoadError => e
    puts 'policy_service_company not included'
end
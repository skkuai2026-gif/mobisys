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
        pol = Policy.find(:first,:conditions =>{:proposalNum => policy.proposalNum.to_s})
        policy.versionID = pol.versionID
        policy.userId = MobiSys::Encryption.encryptContent($userId)
        $currentPolicy = policy
        unless $quotation
            if  policy && policy.quotationRefGuid.to_s != "" 
                $quotation = quotation = Quotation.loadObject(:first,:conditions =>{:guid => policy.quotationRefGuid})
            else
                $quotation = quotation = Quotation.loadObject(:first,:conditions =>{:object => policy.quotationSeq})
            end
        end

        if $currencyFormat == nil
            $currencyFormat = $rhoconfig[:number_format_pattern]
        end
        quotation = $quotation
        parsedData = parseRequestBodyParams
        fetchData = parsedData['FetchData'] if parsedData.has_key?("FetchData")
        currentActiveTab = fetchData['currentActiveTab'] if fetchData && fetchData.has_key?("currentActiveTab")
        parsedModels = parsedData["FormData"]["Models"]
        if parsedModels && parsedModels.has_key?("PolicyAdditionalFields")
        paramField26 = parsedModels["PolicyAdditionalFields"]["field26"]
        end

        baseProduct = policy.getBaseProduct
        baseProduct.capturedPremiumAmt = 0.0 if baseProduct && baseProduct.capturedPremiumAmt.to_s == ""
        if currentActiveTab.to_s == "tab_questionnaire" || currentActiveTab.to_s == "tab_agentDeclaration"
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
                quotationIO.baseDO.quotAddtnlField5 = policy.quotAddtnlField5
                quotationIO.baseDO.quotAddtnlField6 = policy.quotAddtnlField6
                MobiSys::ProductBO.loadModel("MEDEXMAND",quotationIO)
                quotationIO.listCalculation = []
                quotationIO.illustrationHeader = nil
                quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                policy.quotAddtnlField3 = quotationIO.results.medexmand
                policy.quotAddtnlField4 = quotationIO.results.medexmandown
            end
        end
        if currentActiveTab.to_s == "tab_payment"
            $currentProduct ||= ProductUtil.getProduct(policy.baseProductSeq)
            ePaymentActivatorFacet = $currentProduct.getFacet("EPAYMENTACTIVATORFORV8")
            if ePaymentActivatorFacet
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
                MobiSys::ProductBO.loadModel("EPAYMENTACTIVATORFORV8",quotationIO)
                quotationIO.listCalculation = []
                quotationIO.illustrationHeader = nil
                quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                fopvalid = quotationIO.results.fopvalid
                policyProduct = policy.getBaseProduct
                policyProductAdditionalList = policyProduct.PolicyProductAdditionalList if policyProduct
                if policyProductAdditionalList && policyProductAdditionalList.size > 0 && fopvalid
                    policyProductAdditional = policyProductAdditionalList[0]
                    policyProductAdditional.prdAddtnField8d = fopvalid.to_f
                end
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

        updateParentSignature(policy)

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
       

        # $partyWiseDocumentCategoryCdHM = {}
        
        @quotation = MobiSys::PolicyBO.convertToQuotation(policy)
        
        nomineeCount = policy.PartyList.select{ |h| h.removed.to_s != "YES" and h.roleCd.to_s == "NOMINEE" }.size
        
        policy.PartyList.each do |party|
           
            if party.roleCd == "NOMINEE"
                nomineePartyRole = policy.getPolicyPartyRoleByPartyGuid(party.guid,"NOMINEE")
                if nomineePartyRole && nomineePartyRole.removed.to_s != "YES"

                    nomineePartyRole.percentage = ((nomineeCount == 1 and nomineePartyRole.percentage.to_s == "") ? 100 : nomineePartyRole.percentage)

                    # nomineePartyRole.percentage = 100 if nomineeCount == 1
                    party.nomineeTypeCd = nomineePartyRole.nomineeTypeCd
                    party.partySameAsCd = nomineePartyRole.partySameAsCd
                    party.percentage = nomineePartyRole.percentage.to_f
                    party.irrevocableFl = nomineePartyRole.irrevocableFl
                    party.eventTypeCd = nomineePartyRole.eventTypeCd
                end
            end
           
            # if (party.roleCd.to_s == "PROPOSER" || party.roleCd.to_s == "PRIMARY") && currentActiveTab.to_s == "tab_requirement"
            if (party.roleCd.to_s == "PROPOSER" || party.roleCd.to_s == "PRIMARY") #&& $currentActiveTab.to_s == "tab_requirement"
               populateDocuments(policy,party)
              
            end  
        end
        @quotation = nil
        

        policy.PolicyProductList.each do |policyProduct|
            product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq) if policyProduct.productSeq.to_s != ""
            policyProduct.productLongName = product.longName if product
        end
        
        # if (policy.quoteProposerSameAsInsured.to_s != "YES" && policy.quoteProposerSameAsInsured.to_s != "COPYFROMINSURED")
        #     proposer = policy.getParty("PROPOSER")
        #     proposer.update_attributes(:smoker => nil) if proposer.smoker.to_s != ""
        # end
        ## update the policyfeild31 here
        policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
            policyAdditionalFieldsDO.update_attributes(:policyField31 => "FaceToFace") if (policyAdditionalFieldsDO.additionalTypeCd.to_s == "000" && policyAdditionalFieldsDO.policyField31.to_s == "")
        end
        policy.totModalPremium = MobiSys::PolicyService.getTotModalPremium(policy)
        #moved the logic here to validatePolicy method. This is to have a method which will only validate a policy without saving to the database.
        

        validatePolicy(policy)
        

        #submitPaymentDetails(newPolicy)
        #submitQuestionnaire(newPolicy)

        # if currentActiveTab.to_s == "tab_csaIllustration" || currentActiveTab.to_s == "tab_siIllustration" || currentActiveTab.to_s == "tab_illustration"
        #      signatureContainer = SignatureContainer.loadObject(:first,
        #         :conditions => {
        #             :entityGuid => policy.guid
        #         }
        #     )
        #     if signatureContainer
        #         policy.visitedTabs += ",tab_siIllustration"
        #         policy.persistAll
        #         errors = Hash.new
        #         MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
        #     end
        # end

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
        @baseIO.baseDO.isEditQuotation = isEditQuotation
        @baseIO.baseDO.entityTypeCd = "POLICY"

        # p "currentActiveTab============#{currentActiveTab}"
        # p "paramField26=============#{paramField26}"
        if currentActiveTab.to_s == "tab_plan"
            policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
                if policyAdditionalFieldsDO.field26.to_s != ""  && paramField26.to_s == ""
                    policyAdditionalFieldsDO.field26 = paramField26
                end
            end
        end

        if policy.action.to_s == ""
            policy.action = "Save"
        end
        policy.persistAll
    end

    def populateDocuments(policy,party)
        # Rho::Log.error("~~~policy in populateDocuments:#{policy}", LOGCATEGORY)

        # life = policy.getPartyByGuid(partyGuid)
        life = party

        $currentProduct ||= ProductUtil.getProduct(policy.baseProductSeq) if policy.baseProductSeq != ""
        facetObj = $rhoconfig[:multiDocMode]
        if facetObj && facetObj.actionValue.to_s == 'YES'
            multiDocMode = true
        else
            multiDocMode = false
        end

        
        if $quotation
            quotation = $quotation
        else
          
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
        end
        
        
        baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
        # Rho::Log.error("~~~quotation in populateDocuments:#{quotation}", LOGCATEGORY)
        
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
                # Rho::Log.error("~~~defTables:#{defTables}", LOGCATEGORY)
                defTables.each do |defTable|
                    if defTable.documentCategoryCd.to_s != ''
                        # p "defTable====#{defTable}"
                        categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                        # p "categoriesDerivedFromDT=====#{categoriesDerivedFromDT}"
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
        # Rho::Log.error("~~~categoriesDerivedFromDT:#{categoriesDerivedFromDT}", LOGCATEGORY)

        container = DocumentContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>life.guid, {:name=>'policyGuid'} => policy.guid},:op => 'AND')

        documentImage = Hash.new
        documentListArray = []
        # metadataHash = {}
        # @lookupHash = {}
        tempHash = {}

        if container != nil
            # p"container != nil==========>"
            existingServiceDocumentList = {}
            if multiDocMode
            # p"1057=========>"
                container.ServiceDocumentList.each do |serviceDocument|
                    existingServiceDocumentList["#{serviceDocument.docCategoryCd}|#{serviceDocument.documentCd}"] = serviceDocument
                    categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
                end
                # p "categoriesDerivedFromDT=====#{categoriesDerivedFromDT}"
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd, dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory <<"';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    docCatDocument = existingServiceDocumentList.select{|key| key.include? docCategory}
                    documents.each do |document|
                        if existingServiceDocumentList["#{docCategory}|#{document.documentCd}"].to_s != ''
                            serviceDocument = existingServiceDocumentList["#{docCategory}|#{document.documentCd}"]
                            serviceDocument.docDescription = document.documentDesc
                            #New Code for Document Image
                            # documentImage = DocumentImage.getDocumentImages(serviceDocument.guid)
                            # methodName = "DocumentImageList="
                            # serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                            # if documentImage
                            #     serviceDocument.send(methodName, documentImage.collect{|x| x.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }})
                            # else
                                # serviceDocument.send(methodName,[])
                                # serviceDocument.send(methodName,nil)
                            # end
                            tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
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
                            # methodName = "DocumentImageList="
                            # serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                            #     serviceDocument.send(methodName,[])
                            tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
                            # container.addServiceDocument(serviceDocument)
                            documentListArray << tempHash["ServiceDocumentList"] if docCatDocument.size == 0
                        end
                    end
                end
            else
            # p"1101=========>"
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
                        # container.addServiceDocument(serviceDocument)
                        documentListArray << tempHash["ServiceDocumentList"]
                    end

                end
            end
        else
            # p"container == nil=========>"
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
                        # methodName = "DocumentImageList="
                        # serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                        # serviceDocument.send(methodName, [])
                        tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
                        # container.addServiceDocument(serviceDocument)

                        documentListArray << tempHash["ServiceDocumentList"]
                       
                    end
                end
            else
            # p"1169=========>"
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '"<< docCategory <<"';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    serviceDocument = ServiceDocument.new
                    serviceDocument.partyGuid = life.guid
                    serviceDocument.docCategoryTypeCd = documents[0].categoryTypeCd
                    serviceDocument.docCategoryCd = docCategory
                    serviceDocument.acceptanceStatusCd = "PENDING"
                    serviceDocument.isAutoGeneratedFl = "YES"
                    # container.addServiceDocument(serviceDocument)
                    # methodName = "DocumentImageList="
                    # serviceDocument.instance_eval { class << self; self end }.send(:attr_accessor, "DocumentImageList") unless serviceDocument.respond_to? methodName
                    # serviceDocument.send(methodName, [])
                    tempHash["ServiceDocumentList"] = serviceDocument.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
                    documentListArray << tempHash["ServiceDocumentList"]
                   
                end
            end
        end
        # p"documentListArray=======#{documentListArray}"


        $partyWiseDocumentCategoryCdHM[life.guid] = documentListArray if $partyWiseDocumentCategoryCdHM
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
                # if(AgentReg.getCurrentAgentReg.userType.to_s == "AGENT")
                    allocatedParty = policy.getPartyByGuid(policy.allocatedToPartyGuid)
                    invalidReason =  MobiSys::BrowserHelper.getLabelValue("agentInvalidReason",[policy.allocatedToRole,allocatedParty.getFullName]).to_s
                # else
                #     invalidReason = getLabelValue("customerInvalidReason").to_s
                #     puts"inside 246==========>"
                #     #The Proposal can no longer be modified by you. Please check with your Advisor in case of any queries.
                # end
            end
        end
        # Status will be set to LOCKED when we want to edit quotation from policy
        if policy.statusCd.to_s == "LOCKED"
            isInvalid = true
            invalidReason = getLabelValue("policyLockInvalidReason").to_s
        end

        #ProposalVersion check logic

        quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
        if MobiSys::PolicyService.hasProposalExpired(quotation)
            invalidReason = getLabelValue('ERR_PROPOSAL_EXPIRED')
            isInvalid = true  
        end
        
        policy.invalidReason = invalidReason
        return isInvalid
    end

    def updateParentSignature(policy)
        insured = policy.getParty("PRIMARY")
        if insured && policy.quoteProposerSameAsInsured.to_s == "NO"
            signatureContainer = SignatureContainer.find(:first,:conditions =>{:entityGuid => policy.guid})
            if signatureContainer
                signatureContainer.ServiceSignatureList.each do |signature|
                    if signature && signature.signatureTypeCd.to_s == "PARENTSIGNATURECAPTURE"
                      signature.signatureTypeCd = "SIGNATURECAPTUREEAPPPRIMARY"
                      signature.partyGuid = insured.guid
                      signature.roleCd = insured.roleCd
                      signature.persistAll
                    end  
                end  
            end 
        end    
    end    

    def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata = nil)
        # p "$currentActiveTab=======#{$currentActiveTab}"
        baseProduct = nil
        prdMetadataChkReqd = true
        additionalTypeCdPayment = false
        additionalTypeCd000 = false
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
                            metadataHash["#{currentTagObject.uniqueKey}"]["documentCd"]["isMandatoryByConfig"] = true
                        end

                        documentDO = Document.loadObject(:first, :conditions=>{{:name=>'documentCd'}=>currentTagObject.documentCd.to_s})
                        documentCategoryDO = DocumentCategory.loadObject(:first, :conditions=>{{:name=>'categoryCd'}=>currentTagObject.docCategoryCd.to_s})
                        if documentCategoryDO
                            # check if the document description is a label key.. in that case get the tooltip as well
                            tooltipVal = Localization::LabelCache.instance.getLabelToolTipValue(documentCategoryDO.categoryDesc.to_s)
                            metadataHash["#{currentTagObject.uniqueKey}"]["docCategoryCd"]["TOOLTIP"] = tooltipVal if tooltipVal.to_s != ""
                        end
                    end
                end
                if metadataHash["#{currentTagObject.uniqueKey}"]["documentCd"]["isMandatoryByConfig"] == true
                   metadataHash[currentTagObject.uniqueKey.to_s]["selected"]["ENABLED"] = "NO"
                   currentTagObject.selected = "YES"
                end
            end
        end
        if currentTagObject.is_a?(ServiceSignature)
            #Check if the document is mandatory then set in the metadata
            if currentTagObject.signatureTypeCd.to_s =="FATCASIGNATURECAPTURE" && currentTagObject.entityType.to_s =="Policy"
                metadataHash["#{currentTagObject.uniqueKey}"]["placeOfSignature"]["VISIBILITY"] = "NO"
            end    
        end

        if currentTagObject.is_a?(PolicyAdditionalFields)
            policyAdditionalFieldsList = @baseIO.baseDO.PolicyAdditionalFieldsList
            if policyAdditionalFieldsList.size > 0
                policyAdditionalFieldsList.each do|policyAddtnField|
                    if policyAddtnField.additionalTypeCd.to_s == 'PAYMENT'
                       additionalTypeCdPayment = true
                    elsif policyAddtnField.additionalTypeCd.to_s == '000' && policyAddtnField.field2.to_s !=""
                       additionalTypeCd000 = true
                    end
                end    
            end   
            if additionalTypeCdPayment && additionalTypeCd000 
                metadataHash["#{currentTagObject.uniqueKey}"]["field15"]["ENABLED"] = "YES"
                if metadataHash[currentTagObject.uniqueKey.to_s] && metadataHash[currentTagObject.uniqueKey.to_s]["policyField46"]
                   metadataHash[currentTagObject.uniqueKey.to_s]["policyField46"]["ENABLED"] = "YES"
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
        policyAdditionalField19 = nil
        if currentTagObject.is_a?(ServiceSignature)
            agent_type_sign = currentTagObject.signatureTypeCd
        end
        if currentTagObject.is_a?(PolicyAdditionalFields) && currentTagObject.additionalTypeCd.to_s != "" && currentTagObject.additionalTypeCd.to_s == "000"
            policyAdditionalField19 = currentTagObject.additionalTypeCd.to_s
        end
        isRemoteSellingCompleteFlag = MobiSys::PolicyService.isRemoteSellingComplete(@baseIO.baseDO)
        statusCd = @baseIO.baseDO.statusCd.to_s
        if metadataHash[currentTagObject.uniqueKey]
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                if statusCd.to_s == "ACCEPTED" || isCompleted || isRemoteSellingCompleteFlag == true
                    # Additional conditions based on object type and completion status
                    if (currentTagObject.is_a?(PolicyAgent) || currentTagObject.is_a?(ServiceDocument)) && !isCompleted
                      # do nothing
                    elsif agent_type_sign && agent_type_sign.to_s == "AGENTTYPE"
                      # do nothing
                    elsif k.to_s == "field19" && policyAdditionalField19.to_s != ""
                      # do nothing 
                    elsif statusCd.to_s == "COMPLETED" && currentTagObject.is_a?(ServiceSignature) && isRemoteSellingCompleteFlag == true
                         # do nothing 
                    elsif k.to_s == "allocationPartyGuidList"
                         # do nothing 
                    else
                      # Disable the field
                        v["ENABLED"] = "NO"
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



    def generateApplicationNumber
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        responseHash = {}

        @policyProduct = PolicyProduct.loadObject(:first, :conditions=>{{:name=>'parentKey'}=>@policy.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND')
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        $appDbMismatchFlag = false if !has_network
        if(has_network)
            # checkLicensetype = validateLicenseType   #SUNSS 2405 NEW
            # p "checkLicensetype==========#{checkLicensetype}"
            if true #checkLicensetype
                begin
                    productId = @policy.getBaseProduct.productId.to_s
                    userId = $userId.to_s
                    proposalNum = @policy.proposalNum.to_s
                    addtnField1 = @policyProduct.addtnField1 if @policyProduct
                    paymentHash = { PRODUCTCODE: productId, PROPOSALNUM: proposalNum, USERID: userId, ADDTNFIELD1: addtnField1}
                    result = doJSONPost('/generateSerialNumber.run', paymentHash.to_json)
                    if result.to_s != ""
                        responseHash = Rho::JSON.parse(result.to_s)
                        policyNum = responseHash["APPNUM"].to_s if responseHash.has_key?("APPNUM")
                        policyAdditionalField = @policy.getPolicyAddionalField("000")
                        policyAdditionalField.field2 = policyNum
                        policyAdditionalField.persistAll
                    end
                    responseHash['data'] = {}
                    responseHash['data']['applicationNum'] = policyNum
                    responseHash['success'] = true
                    responseHash['message'] = "Successful"
                    # MobiSys::BrowserHelper.addUserActivityHelper('GENERATEAPPLICATIONNUM', @params, 'POLICY', @policy.proposalNum)

                    paymentSerialNo = ""
                    policyAdditionalFieldData = PolicyAdditionalFields.find(:first,:conditions =>{:additionalTypeCd => "000",:parentKey => @policy.object })
                    paymentSerialNo = policyAdditionalFieldData.field2 if policyAdditionalFieldData


                    policyPortfolioModelCode = @policy.PolicyProductList
                              .find { |ppd| 
                                ppd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

                    if @policy.quotationRefGuid.to_s != ""
                        quotation = Quotation.find(:first, :conditions => {:guid => @policy.quotationRefGuid })
                        quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
                        quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
                    end

                     MobiSys::CommonUtil.addUserActivity('GENERATEAPPLICATIONNUM_OFFLINE',"quotationRefNum => #{@policy.quotationRefNum},proposalNum => #{@policy.proposalNum},policyGuid => #{@policy.guid},policyfnaId => #{@policy.fnaId},paymentSerialNumber => #{paymentSerialNo},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', @policy.proposalNum)
                    
                rescue StandardError => se
                    puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    responseHash['success'] = false
                    responseHash['message'] = message if message
                    # responseHash['message'] = "Exception in doJSONPost:"
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
        #policy.statusCd = "COMPLETED"
        # policy.statusCd = "COMPLETED" if policy.statusCd.to_s != "LOCKED"
        if policy.step.to_i != 0 && policy.step.to_i > 0 && policy.allocatedToRole.to_s != "" && policy.allocatedToRole.to_s == "AGENT" && policy.statusCd.to_s == "PENDING"
            policy.statusCd = "COMPLETED" 
        end   
        policy.persistAll
    end

    def unlockPolicy(id, parsedData)
        p "inside unlock policy****************#{@params}"
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        p "policy=========#{@policy}"
        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => @policy.guid})
        if signatureContainer
            signatureContainer.ServiceSignatureList.each do|servSign|
              if servSign.to_s != "" && (servSign.signatureTypeCd != "AGENTSIGNATURECAPTURE" && servSign.signatureTypeCd != "AGENTTYPE") #&& servSign.removed=="YES"
                   #servSign.signature = nil
                   #servSign.placeOfSignature = nil
                  # servSign.destroy  
                  servSign.removed = "YES" 
              end
            end
            # signatureContainer.ServiceSignatureList.each do|servSignRemove|
            #   if servSignRemove.to_s != "" && (servSignRemove.signatureTypeCd != "AGENTDECLARATION" && servSignRemove.signatureTypeCd != "AGENTTYPE") #&& servSignRemove.removed=="YES"
            #     signatureContainer.removeServiceSignature(servSignRemove) 
            #   end
            # end
            signatureContainer.persistAll if signatureContainer
            # signatureContainer.destroy if signatureContainer.ServiceSignatureList.size <= 0
            @policy.signatureStatus = ""
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
        @policy.step = 0
        if decoupling
            @policy.statusCd = "COMPLETED"
        else
            @policy.statusCd = "PENDING"
        end
        @policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
          policyAdditionalFieldsDO.update_attributes(:policyField31 => "FaceToFace") if policyAdditionalFieldsDO.additionalTypeCd.to_s == "000"
        end
        @policy.persistAll

        policyPortfolioModelCode = @policy.PolicyProductList
                              .find { |ppd| 
                                ppd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

        if @policy.quotationRefGuid.to_s != ""
            quotation = Quotation.find(:first, :conditions => {:guid => @policy.quotationRefGuid })
            quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
            quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
        end
            
        # addUserActivity in unlockEapp
        MobiSys::CommonUtil.addUserActivity('UNLOCKEAPP_OFFLINE',"quotationRefNum => #{@policy.quotationRefNum},proposalNum => #{@policy.proposalNum},policyGuid => #{@policy.guid},policyfnaId => #{@policy.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', @policy.proposalNum)
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
    
    #temmporary method overrride from functional because final html content should be go in key EappPreview instead of EappHTMLPreview
    def eappPreview
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        # fetchData(parsedData,false,false)
        # process()
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
            MobiSys::PolicyService.generateEappPreview(policy)
            @lookupHash = {}
            #responseHash['data'] = {"EappHTMLPreview" => $policyIO.htmlContent}
            responseHash['data'] = {"EappPreview" => $policyIO.htmlContent}
            if $policyIO.htmlContent.to_s != ""
                @metadataHash = {}
                $mvelHashMap["signatureHM"].each do |k, v|
                    signature = $mvelHashMap["signatureHM"][k]
                    @metadataHash.merge!(processMetadata(signature))
                end
                @metadataHash.merge!(processMetadata(policy))
                responseHash['metadata'] = @metadataHash
                if $lookupArray
                    $lookupArray.uniq.each do |lookup|
                        addToLookupHash(lookup)
                    end
                end
                responseHash['lookups'] = @lookupHash
            end
        end
        responseHash['success'] = true
        responseHash['message'] = "Successful"
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
        if isMetadataRequired
            if policy != nil
                evaluateContextForObject(policy)
            end
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

    def copyPolicyData
        parsedData = parseRequestBodyParams
        # fetch current policy by fetch and merge data function
        fetch(@params["id"]) if @params.has_key?("id")
        copyToPolicyDO = @baseIO.baseDO
        proposalDataToBeCopiedList = []
        copyFromPolicySeq = parsedData['copyFromPolicySeq'].to_s
        if copyFromPolicySeq.to_s != ""
            copyFromPolicyDO = Policy.loadObject(:first, :conditions => {:object => copyFromPolicySeq})
            if copyFromPolicyDO && parsedData['proposalDataToBeCopied'].to_s != ""
                proposalDataToBeCopiedList = parsedData['proposalDataToBeCopied']
                begin
                    policyCopyData = MobiSys::PolicyCopyData.new
                    policyCopyData.execute(copyFromPolicyDO, copyToPolicyDO, proposalDataToBeCopiedList)  
                    copyFromPolicyDO.PolicyAdditionalFieldsList.each do|copyFromPolicyAdditionalsDO|
                        copyToPolicyDO.PolicyAdditionalFieldsList.each do|copyToPolicyAdditionalsDO|
                            copyToPolicyAdditionalsDO.policyFieldDt58 = copyFromPolicyAdditionalsDO.policyFieldDt58 if copyFromPolicyAdditionalsDO.policyFieldDt58.to_s != "" 
                        end    
                    end                  
                    copyToPolicyDO.step = 0
                    copyToPolicyDO.visitedTabs = nil
                    copyToPolicyDO.statusCd = "PENDING"
                    copyToPolicyDO.persistAll

                    policyPortfolioModelCode = copyToPolicyDO.PolicyProductList
                              .find { |ppd| 
                                ppd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

                    if copyToPolicyDO.quotationRefGuid.to_s != ""
                        quotation = Quotation.find(:first, :conditions => {:guid => copyToPolicyDO.quotationRefGuid })
                        quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
                        quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
                    end

                     # addUserActivity in copyPolicyData
                    MobiSys::CommonUtil.addUserActivity('COPYEAPP_OFFLINE',"quotationRefNum => #{copyToPolicyDO.quotationRefNum},proposalNum => #{copyToPolicyDO.proposalNum},policyGuid => #{copyToPolicyDO.guid},policyfnaId => #{copyToPolicyDO.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', copyToPolicyDO.proposalNum)
                rescue StandardError => e
                    puts "Error while copying party data #{e}"
                end
            end
        end
    end

    def checkEnrollNowStatus
        p "inside checkEnrollNowStatus=="
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        isValid = false
        message = nil
        if @policy.proposalSignedDt.to_s != "" && @policy.signatureStatus.to_s == "SUCCESS"
            has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
            if has_network
                begin
                    proposalNum = @policy.proposalNum.to_s
                    inputHash = { PROPOSALNUM: proposalNum }
                    result = doJSONPost('/checkEnrollNowStatus.run', inputHash.to_json)
                    if result.to_s != ""
                        responseHash = Rho::JSON.parse(result.to_s)
                        policyAdditionalField = @policy.getPolicyAddionalField("PAYMENT")
                        policyAdditionalField.policyField30 = responseHash["policyfield30"].to_s if responseHash.has_key?("policyfield30")
                        policyAdditionalField.policyField32 = responseHash["policyfield32"].to_s if responseHash.has_key?("policyfield32")
                        policyAdditionalField.policyField38 = responseHash["policyfield38"].to_s if responseHash.has_key?("policyfield38")
                        policyAdditionalField.policyField40 = responseHash["policyfield40"].to_s if responseHash.has_key?("policyfield40")
                        policyAdditionalField.persistAll
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
        end
    end

    def getAcaPaymentDetails
        parsedData = parseRequestBodyParams
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        proposalNum = (parsedData.has_key?("proposalNum") ? parsedData["proposalNum"] : "")
        @policy = @baseIO.baseDO
        isValid = false
        message = nil
        if @policy.proposalSignedDt.to_s != "" && @policy.signatureStatus.to_s == "SUCCESS"
            has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
            if has_network
                begin
                    proposalNum = proposalNum.to_s
                    inputHash = { PROPOSALNUM: proposalNum }
                    result = doJSONPost('/checkEnrollNowStatus.run', inputHash.to_json)
                    if result.to_s != ""
                        resultHash = Rho::JSON.parse(result.to_s)
                        policyAdditionalField = @policy.getPolicyAddionalField("PAYMENT")
                        policyAdditionalField.policyField30 = resultHash["policyfield30"].to_s if resultHash.has_key?("policyfield30")
                        policyAdditionalField.policyField32 = resultHash["policyfield32"].to_s if resultHash.has_key?("policyfield32")
                        policyAdditionalField.policyField38 = resultHash["policyfield38"].to_s if resultHash.has_key?("policyfield38")
                        policyAdditionalField.policyField40 = resultHash["policyfield40"].to_s if resultHash.has_key?("policyfield40")
                        policyAdditionalField.persistAll
                        responseHash["policyAdditionalFields"] = {
                          "policyField30" => policyAdditionalField.policyField30,
                          "policyField32" => policyAdditionalField.policyField32,
                          "policyField38" => policyAdditionalField.policyField38,
                          "policyField40" => policyAdditionalField.policyField40
                        }
                        isValid = true
                        responseHash['success'] = true
                        responseHash['message'] = getLabelValue('ACASTATUSSUCCESSFUL')
                    else
                        isValid = false
                        responseHash['success'] = false
                        responseHash['message'] = getLabelValue('NOACASTATUS')
                    end
                rescue StandardError => se
                    puts "Error while generating entities hash for sync =>" + se.to_s
                    isValid = false
                    responseHash['success'] = false
                    responseHash['message'] = getLabelValue('SERVERERROR')
                end 
            else
                isValid = false
                responseHash['success'] = false
                responseHash['message'] = getLabelValue('ERR_NETWORK')
            end
        end
        render :string => responseHash.to_json
    end

    def checkPaymentStatus
        p "inside checkPaymentStatus=="
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

        htmlContent = ""
        viewPaymentDetailsCall = false
        policy.additionalData = {} if policy.additionalData == nil

        if parsedData.has_key?("source") && parsedData["source"].to_s == "PAYNENTDETAILSQUERY"
            viewPaymentDetailsCall = true
        end

        if policy and (policy.statusCd.to_s != "PAYMENTDONE" && policy.statusCd.to_s != "PAYMENTSUCCESS")
            if isPoll
                (1..pollCount).each do |n|
                    #Hit the online server for updated payment status
                    htmlContent = reQueryCheck(viewPaymentDetailsCall)
                    break if (policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "PAYMENTSUCCESS")
                    sleep(pollInterval)
                end
            else
                #Hit the online server for updated payment status
                htmlContent = reQueryCheck(policy, viewPaymentDetailsCall)
            end
        elsif policy and (policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "PAYMENTSUCCESS")
            offlineInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
            afterStatusCheckInwardDOs = offlineInward.InwardDetailsList if offlineInward
            htmlContent = MobiSys::PolicyService.generateViewPaymentBody(afterStatusCheckInwardDOs) if afterStatusCheckInwardDOs
        end
        policy.additionalData["paymentMessage"] = @message if @message.to_s != "Successful"

        #Get Data for Response
        # fetchData(parsedData,true,isMetadataRequired)
        # responseHash = generateResponseHash(true)

        if viewPaymentDetailsCall
            if htmlContent.to_s != ""
                responseHash['data'] = {}
                responseHash['data']['viewPaymentData'] = htmlContent
                responseHash['success'] = true
            else
                responseHash['success'] = false
                responseHash['message'] = "Error gnerating view details."
            end

        else
            paymentMessage = ""
            if policy.additionalData.has_key?("paymentMessage") && policy.additionalData["paymentMessage"].to_s != ""
                paymentMessage = policy.additionalData["paymentMessage"].to_s
            end

            if(policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "PAYMENTSUCCESS")
                responseHash['success'] = true
                responseHash['message'] = "Payment is Already Done."
                responseHash['message'] = paymentMessage if paymentMessage.to_s != ""
            else
                responseHash['success'] = false
                responseHash['message'] = MobiSys::BrowserHelper.getLabel('PAYMENTPENDING')
                responseHash['message'] = paymentMessage if paymentMessage.to_s != ""
            end
        end
        render :string => responseHash.to_json
    end
    ################################################################################

    def changeAllocation(id,parsedData)
        p "in changeallocation "
        policy = @baseIO.baseDO
        quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
        proposer = policy.getParty("PROPOSER")
        primary = policy.getParty("PRIMARY")
        # allocatedToPartyGuidList = []
        allocatedToPartyGuidList = policy.allocationPartyGuidList.to_s.split(",") if policy.allocationPartyGuidList.to_s != ""
        responseHash = {}
        # process()
        isValid = true
        has_error = false
        party_Guid_List = []
        party_Guid_hash = {}


        if policy.allocatedToRole.to_s == "AGENT"
            if MobiSys::PolicyService.hasProposalExpired(quotation)
                @message = getLabelValue('ERR_PROPOSAL_EXPIRED')
                @success = false 
                isValid = false
            else 
                if allocatedToPartyGuidList && allocatedToPartyGuidList.size > 0
                allocatedToPartyGuidList.each do |allocationPartyGuid|
                  allocated_party = policy.getPartyByGuid(allocationPartyGuid)
                    if allocated_party && allocated_party.PartyContactList.size > 0
                       allocated_party.PartyContactList.each do |party_contact|
                            roleCd = allocated_party.roleCd
                            # === PROPOSER role ===
                            if roleCd == "PROPOSER"
                              if party_contact.contactTypeCd == "PHILIPPINESNUM"
                                if party_contact.countryCd.nil? || party_contact.countryCd.casecmp("0063") != 0
                                  has_error = true
                                end
                              end
                            # === PRIMARY role ===
                            elsif roleCd == "PRIMARY"
                              if party_contact.contactTypeCd == "MOBILE"
                                # if field28 = MOBILEPHONE, use PROPOSER’s mobile contact instead
                                partyAdditnlField = allocated_party.getPartyAdditionalField
                                partyAdditnlField28 = partyAdditnlField.field28 if partyAdditnlField
                                if partyAdditnlField28 && partyAdditnlField28.casecmp("MOBILEPHONE") == 0
                                  owner = policy.getParty("PROPOSER")
                                  party_contact = owner.getPartyContact("MOBILE")
                                end

                                if (party_contact && (party_contact.countryCd.nil? || party_contact.countryCd.casecmp("0063") != 0))
                                    has_error = true
                                end
                              end
                            end
                       end
                    end
                    party_Guid_hash['PROPOSER'] = allocated_party.guid if allocated_party.roleCd.to_s == "PROPOSER"
                    party_Guid_hash['PRIMARY'] = allocated_party.guid if allocated_party.roleCd.to_s == "PRIMARY"

                end
                end
                if has_error
                    @message = getLabelValue('ERR_transferredToCustomerMsg')
                    @success = false 
                    isValid = false
                end

                ###########################
                
            end

            if !party_Guid_hash.nil? && !party_Guid_hash.empty?
                # Reorder hash to always keep PROPOSER first
                ordered_hash = {}
                ordered_hash['PROPOSER'] = party_Guid_hash['PROPOSER'] if party_Guid_hash['PROPOSER']
                ordered_hash['PRIMARY']  = party_Guid_hash['PRIMARY'] if party_Guid_hash['PRIMARY']

                party_Guid_List = ordered_hash.values
                policy.allocationPartyGuidList = party_Guid_List.join(",")
            end

            @message = getLabelValue('transferredToCustomerMsg') if isValid
            policy.userId = MobiSys::Encryption.encryptContent($userId)
            submitted = false
            submitted = MobiSys::PolicyService.checkIfPolicySubmitted(policy)
            if !submitted
                MobiSys::PolicyService.transferToCustomer(policy) if isValid
            else
                @message = getLabelValue('ERR_transferredToCustomerWeb')
                @success = false 
                isValid = false
            end
        else
            if MobiSys::PolicyService.hasProposalExpired(quotation)
                @message = getLabelValue('ERR_PROPOSAL_EXPIRED')
                @success = false 
                isValid = false
            end
            @message = getLabelValue('transferredToAgent') if isValid
            policy.userId = MobiSys::Encryption.encryptContent($userId)
            submitted = false
            submitted = MobiSys::PolicyService.checkIfPolicySubmitted(policy)
            if !submitted
                MobiSys::PolicyService.revokeFromCustomer(policy) if isValid
            else
                @message = getLabelValue('ERR_revokeFromCustomerWeb')
                @success = false 
                isValid = false
            end
        end
        fetch(id)
        policy = @baseIO.baseDO
        policy.isInvalid = isInvalid
        policy.isCompleted = isCompleted
        policy.step = 0
        return policy
    end
    ###########################################################################################

    def reQueryCheck(policy, viewPaymentDetailsCall)
        htmlContent = ""
        initiatePayment = true
        isValid = true
        afterStatusCheckInwardDOs = []

        offlineInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE") if policy != nil
        if offlineInward != nil
            isValid = MobiSys::PolicyService.updatePaymentStatus(policy)

            if isValid
                updatedInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                afterStatusCheckInwardDOs = updatedInward.InwardDetailsList

                if viewPaymentDetailsCall
                    htmlContent = MobiSys::PolicyService.generateViewPaymentBody(afterStatusCheckInwardDOs) if !afterStatusCheckInwardDOs.empty?
                else
                    amountToPaid = 0.0
                    paidAmount = 0.0
                    inwardStatusInclude = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'CPAG_StatusIncludedIn_Calculation'})
                    fieldsToInclude = inwardStatusInclude.to_s != "" && inwardStatusInclude.value.to_s != "" ? inwardStatusInclude.value.split(",") : []

                    afterStatusCheckInwardDOs.each do |inwardDetails|

                        paidAmount += inwardDetails.inwardAmount.to_f if fieldsToInclude.include?(inwardDetails.instrumentStatusCd.to_s)

                        if inwardDetails.authCode.to_s != ""
                            amountToPaid = inwardDetails.authCode.to_f
                        elsif inwardDetails.inwardAmount.to_s != ""
                            amountToPaid = inwardDetails.inwardAmount.to_f
                        end

                    end

                    balanceAmt = amountToPaid.to_f - paidAmount.to_f
                    balanceAmtRound = MobiSys::UIGenUtilEapp.formatDoubleTwoDecimal(balanceAmt.to_f)
                    balanceAmt = balanceAmtRound.to_f
                    paymentMessage = ""

                    if balanceAmt.to_f == 0.0
                        initiatePayment = false
                        if updatedInward.inwardStatusCd.to_s != ""
                            updatedInward.inwardStatusCd = updatedInward.isChqRepresentation.to_s + "," + "FULLPAYMENT"
                        else
                            updatedInward.inwardStatusCd =  "200,FULLPAYMENT"
                        end

                    elsif balanceAmt.to_f < 0.0
                        initiatePayment = false
                        if updatedInward.inwardStatusCd.to_s != ""
                            updatedInward.inwardStatusCd = updatedInward.isChqRepresentation.to_s + "," + "EXCESSPAYMENT"
                        else
                            updatedInward.inwardStatusCd =  "200,EXCESSPAYMENT"
                        end
                    end

                    if !initiatePayment
                        policy.additionalData["paymentMessage"] =  paymentMessage
                        policy.statusCd = "PAYMENTSUCCESS"
                        updatedInward.inwardStatusCd = "SUCCESS"
                    end
                end

                updatedInward.persistAll
                policy.persist
            end
        end
        return htmlContent
    end

    def fetch(id)
        policy = Policy.loadObject(:first, :conditions => {:object => id})
        $currentPolicy = policy
        @baseIO.baseDO = policy
        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.isEditQuotation = isEditQuotation
        @baseIO.baseDO.entityTypeCd = "POLICY"
        $partyWiseDocumentCategoryCdHM = {}

        updateParentSignature(policy)

        if $currencyFormat == nil
            $currencyFormat = $rhoconfig[:number_format_pattern]
        end

        
        $quotation = MobiSys::PolicyBO.convertToQuotation(policy)
        
        policy.PartyList.each do |party|
            # logError("~~~in fetch populating doc for party: #{party}")
            if (party.roleCd.to_s == "PROPOSER" || party.roleCd.to_s == "PRIMARY")
               populateDocuments(policy,party)
            end   
        end
        # @quotation = nil

        
        isOnlinePayment = false
        policyAdditionalField = policy.getPolicyAddionalField("PAYMENT")
        isOnlinePayment = true if policyAdditionalField.to_s != "" && policyAdditionalField.field15.to_s == "YES"
        if isOnlinePayment 
            if policy.step.to_i > 2 and (policy.statusCd.to_s == "COMPLETED" || policy.statusCd.to_s == "PENDING")
                @baseIO.baseDO.step = 2
            end 
        end
        
    end

    def isCompleted
        isComplete = false
        if (@baseIO.baseDO.statusCd == "SUBMITTED") || (@baseIO.baseDO.statusCd == "SUBMITTED_UWCOMPLETE") #|| @baseIO.baseDO.statusCd == "COMPLETED")
            isComplete = true
        end

        if !isComplete
            policyStatusExcluded = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'POLICYSTATUS_NOT_TO_FREEZE'})
            if policyStatusExcluded && @baseIO.baseDO.statusCd.to_s != ""
                fieldsToInclude1 = policyStatusExcluded.value.to_s.split(",")
                if fieldsToInclude1 && !fieldsToInclude1.empty? && !(fieldsToInclude1.include?(@baseIO.baseDO.statusCd.to_s))
                    isComplete = true
                end
            end
        end

        return isComplete
    end

    def isEditQuotation
      isEditQuot = false
      policyStatusExcluded = "PENDING,COMPLETED"

      if @baseIO.baseDO.statusCd.to_s != "" && policyStatusExcluded.to_s != ""
        fieldsToInclude1 = policyStatusExcluded.split(",")

        if fieldsToInclude1.include?(@baseIO.baseDO.statusCd.to_s)
          isEditQuot = true
        end
      end

      return isEditQuot
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
            MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, "tab_csaIllustration,tab_siIllustration,tab_illustration")
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
                fnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=> policy.fnaId.to_s})
                if fnaRequest
                    fnaRequest.statusCd = "ACCEPTED"
                    fnaRequest.persistAll
                end

                quotation =  Quotation.loadObject(:first,:conditions =>{:guid => policy.quotationRefGuid})
                if quotation
                    quotation.signature = "SUCCESS"
                    quotation.persistAll
                end
                leadRPQ = LeadRPQ.loadObject(:first, :conditions=>{:rpqId=> policy.rpqId.to_s})
                
                isOnlinePayment = isACAModeSelected = false
                policyAdditionalField = policy.getPolicyAddionalField("PAYMENT")
                isOnlinePayment = true if policyAdditionalField.to_s != "" && policyAdditionalField.field15.to_s == "YES"
                isACAModeSelected = true if policyAdditionalField.to_s != "" && policyAdditionalField.policyField46.to_s == "YES"
                if isOnlinePayment || isACAModeSelected
                    isValid = false
                    message = nil
                    if policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                        has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
                        if has_network
                            begin
                                clazz = Class.new do
                                include MobiSys::BrowserHelper
                                end
                                obj = clazz.new
                                syncEntities = []
                                # policy = Policy.loadObject(:first, :conditions => {:proposalNum => policy.proposalNum})
                                policy.userId = MobiSys::Encryption.encryptContent($userId)
                                # check dup......
                                submitted = false
                                submitted = MobiSys::PolicyService.checkIfPolicySubmitted(policy)
                                if !submitted
                                    syncEntities.push fnaRequest if fnaRequest
                                    syncEntities.push leadRPQ if leadRPQ
                                    syncEntities.push quotation
                                    syncEntities.push policy
                                    #responseHash = MobiSys::Sync.entities([policy],false)
                                    responseHash = MobiSys::Sync.entities(syncEntities,false)
                                    if responseHash.to_s != ""
                                        isValid = true
                                    end
                                else
                                    message =  MobiSys::BrowserHelper.getLabelValue("ERR_acceptPreviewFromWeb",[]).to_s
                                    @success = false 
                                    isValid = false
                                end
                                #######
                                # responseHash = MobiSys::Sync.entities([policy],false)
                                # if responseHash.to_s != ""
                                #     isValid = true
                                # end
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
                 # addUserActivity in acceptPolicy
                MobiSys::CommonUtil.addUserActivity('ACCEPTEAPP_OFFLINE',"quotationRefNum => #{policy.quotationRefNum},proposalNum => #{policy.proposalNum},policyGuid => #{policy.guid},policyfnaId => #{policy.fnaId}", 'POLICY', policy.proposalNum)
            else
                policy.visitedTabs += ",tab_siIllustration"
                @success = false
                @message = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
                policy.persistAll 
                return
            end
            policy.persistAll
        else
            responseHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
            return
        end
        return responseHash
    end

    def acceptPolicyRaw(id, parseData)
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
            MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, "tab_csaIllustration,tab_siIllustration,tab_illustration")
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
                fnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=> policy.fnaId.to_s})
                if fnaRequest
                    fnaRequest.statusCd = "ACCEPTED"
                    fnaRequest.persistAll
                end

                quotation =  Quotation.loadObject(:first,:conditions =>{:guid => policy.quotationRefGuid})
                if quotation
                    quotation.signature = "SUCCESS"
                    quotation.persistAll
                end
                leadRPQ = LeadRPQ.loadObject(:first, :conditions=>{:rpqId=> policy.rpqId.to_s})
                
                isOnlinePayment = isACAModeSelected = false
                policyAdditionalField = policy.getPolicyAddionalField("PAYMENT")
                isOnlinePayment = true if policyAdditionalField.to_s != "" && policyAdditionalField.field15.to_s == "YES"
                isACAModeSelected = true if policyAdditionalField.to_s != "" && policyAdditionalField.policyField46.to_s == "YES"
                if isOnlinePayment || isACAModeSelected
                    isValid = false
                    message = nil
                    if policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                        has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
                        if has_network
                            begin
                                clazz = Class.new do
                                include MobiSys::BrowserHelper
                                end
                                obj = clazz.new
                                syncEntities = []
                                # policy = Policy.loadObject(:first, :conditions => {:proposalNum => policy.proposalNum})
                                policy.userId = MobiSys::Encryption.encryptContent($userId)
                                # check dup......
                                submitted = false
                                submitted = MobiSys::PolicyService.checkIfPolicySubmitted(policy)
                                if !submitted
                                    syncEntities.push fnaRequest if fnaRequest
                                    syncEntities.push leadRPQ if leadRPQ
                                    syncEntities.push quotation
                                    syncEntities.push policy
                                    #responseHash = MobiSys::Sync.entities([policy],false)
                                    responseHash = MobiSys::Sync.entities(syncEntities,false)
                                    if responseHash.to_s != ""
                                        isValid = true
                                    end
                                else
                                    message =  MobiSys::BrowserHelper.getLabelValue("ERR_acceptPreviewFromWeb",[]).to_s
                                    @success = false 
                                    isValid = false
                                end
                                #######
                                # responseHash = MobiSys::Sync.entities([policy],false)
                                # if responseHash.to_s != ""
                                #     isValid = true
                                # end
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

                policyPortfolioModelCode = policy.PolicyProductList
                                          .find { |ppd| 
                                            ppd.productTypeCd == "PLAN"
                                          }&.portfolioModelCd
                if quotation
                    quotationPortfolioModelCode = quotation.QuotationProductList
                                                  .find { |qpd| 
                                                    qpd.productTypeCd == "PLAN"
                                                  }&.portfolioModelCd
                end
                    
                 # addUserActivity in acceptPolicy
                MobiSys::CommonUtil.addUserActivity('ACCEPTEAPP_OFFLINE',"quotationRefNum => #{policy.quotationRefNum},proposalNum => #{policy.proposalNum},policyGuid => #{policy.guid},policyfnaId => #{policy.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
            else
                policy.visitedTabs += ",tab_siIllustration"
                @success = false
                @message = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
                policy.persistAll 
                return
            end
            @baseIO.baseDO.isEditQuotation = isEditQuotation
            policy.persistAll
        else
            responseHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
            return
        end
        return responseHash
    end

    def isMonthlyModeApplicable
        flagMain = false
        facet = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"MONTHLYMODEENABLED"})
        if facet && facet.actionValue.casecmp('YES').zero?
            flagMain = facet.actionValue
        end
        responseHash = {"data" => {"isMonthlyModeApplicable" => flagMain},
        "success" => true,
        "message" => "Successful"}
        render :string => responseHash.to_json
    end

    def sendCPAGPaymentLink
        parsedData = parseRequestBodyParams
        responseHash = {}
        trigger = (parsedData.has_key?("trigger") ? parsedData["trigger"] : false)
        fetch(@params["id"]) if @params.has_key?("id")
        @policy = @baseIO.baseDO
        results = ""
        if @policy.proposalSignedDt.to_s != "" && @policy.signatureStatus.to_s == "SUCCESS"
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            if has_network 
                begin
                    proposalNum = @policy.proposalNum.to_s
                    paymentHash = { trigger: trigger, proposalNum: proposalNum}
                    result = doJSONPost('/sendCpagAcaEmail.run', paymentHash.to_json)
                    if result.to_s != ""
                        resultHash = Rho::JSON.parse(result.to_s)
                        if resultHash["SUCCESS"].to_s == "true"
                            responseHash['success'] = true
                        else
                            responseHash['success'] = false
                        end    
                        # responseHash['success'] = resultHash["SUCCESS"]
                        responseHash['message'] = resultHash["MESSAGE"]
                   end 
                rescue StandardError => se
                    puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    responseHash['success'] = false
                    responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_NETWORK')
                end
            else
                results ="ERR_NETWORK"
            end
        end
        if results.to_s == "ERR_NETWORK"
            responseHash['success'] = false
            responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_NETWORK')
        elsif results == "USERLICENSECHECK"
            responseHash['success'] = false
            responseHash['message'] = MobiSys::BrowserHelper.getLabel('USERLICENSECHECK')
        end
        render :string => responseHash.to_json
    end    
end

begin
    require 'Policy/policy_controller_company'
rescue LoadError => e
    puts 'policy_controller_company not included'
end

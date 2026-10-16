require 'CommonModules/mobisysuihelper_jazz'
require 'TrackLead/track_lead_b_o'
require 'Policy/UIGenUtilEapp'
require 'CommonClasses/PolicyIO'
require 'fileutils'

class PolicyController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    
    def requiredTabs
        requiredTabs = Hash.new
        images = []
        if @policy.insuranceTypeCd == 'TRAVEL'
            requiredTabs['tab_travellerDetails'] = 'tab_travellerDetails'
            # images.push 'icon-owner1'

            requiredTabs['tab_paymentGateway'] = 'tab_paymentGateway'
            # images.push 'icon-payment1'
        elsif @policy.insuranceTypeCd == 'AUTO'
            requiredTabs['tab_vehicleDetails'] = 'tab_vehicleDetails'
            images.push 'icon-owner'
            
            requiredTabs['tab_vehicleInsuredDetails'] = 'tab_vehicleInsuredDetails'
            images.push 'icon-owner'

            requiredTabs['tab_paymentGateway'] = 'tab_paymentGateway'
            images.push 'icon-payment'
        else
            requiredTabs['tab_basic'] = 'tab_basic'
            images.push 'icon-basic'

            proposerLASame = false
            primaryPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            proposerLASame = true if primaryPartyRole && primaryPartyRole.partySameAsCd.to_s == "PROPOSER"

            if proposerLASame
                requiredTabs['tab_owner'] = "#{getLabelValue('tab_owner')}/#{getLabelValue('tab_primary')}"
            else
                requiredTabs['tab_owner'] = 'tab_owner'
            end
            images.push 'icon-owner'

            if !proposerLASame && MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct)
                requiredTabs['tab_primary'] = 'tab_primary'
                images.push 'icon-insured'
            end

            if MobiSys::BrowserHelper.renderPanel?('JOINTINSUREDDETAILS', $currentProduct)
                requiredTabs['tab_joint'] = 'tab_joint'
                images.push 'icon-joint-life'
            end
        
            if $currentProduct && $currentProduct.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES'
                requiredTabs['tab_coverage'] = 'tab_coverage'
                images.push 'icon-coverage'

                if MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                    requiredTabs['tab_supplementary'] = 'FAMILYINSUREDDETAILS'
                    images.push 'icon-supplementary'
                end
            else
                if MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                    requiredTabs['tab_supplementary'] = 'tab_supplementary'
                    images.push 'icon-supplementary'
                end

                requiredTabs['tab_coverage'] = 'tab_coverage'
                images.push 'icon-coverage'
            end
        
            if $currentProduct.getFacet('EXCLUDENOMINEECAPTURE')==nil || !MobiSys::BrowserHelper.renderPanel?('EXCLUDENOMINEECAPTURE', $currentProduct)
                requiredTabs['tab_nominee'] = 'tab_nominee'
                images.push 'icon-beneficiary'
            end

            requiredTabs['tab_payment'] = 'tab_payment'
            images.push 'icon-payment'

            if $currentProduct.getFacet('PRODUCTQUESTIONSETGROUP').to_s != "" || $currentProduct.getFacet('PROPOSERQUESTIONSETGROUP').to_s != "" || $currentProduct.getFacet('PAYERQUESTIONSETGROUP').to_s != ""
                requiredTabs['tab_questionnaire'] = 'tab_questionnaire'
                images.push 'icon-questionnaire'
            end

            requiredTabs['tab_requirement'] = 'tab_requirement'
            images.push 'icon-requirements'
        
            if $rhoconfig[:captureSignatureInTab]
                requiredTabs['tab_signature'] = 'tab_signature'
                images.push 'icon-declaration'
            else
                # requiredTabs['tab_agentDeclaration'] = 'tab_agentDeclaration'
                images.push 'icon-declaration'
            end
        end   
        tabName = requiredTabs.keys.join(",")
        tabLabel = requiredTabs.values.join(",")

        return tabName,tabLabel,images.join(',')
    end 
    ###########################################################################################


    def getNavbarDetails(currentTab, object=nil, count='0')
        tempHash = {}
        case currentTab
        when "tab_basic"
            tempHash['basicDetails'] = getLabelValue("basicDetails")
            if MobiSys::BrowserHelper.renderPanel?('AGENTSHARING', $currentProduct)
                tempHash['agentSharing'] = getLabelValue("agentSharing")
            end
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_owner"
            classname = "PolicyProposerDO"
            renderPartyOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
            renderPartyAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
            renderPartyContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')

            tempHash['proposerDetailsTabContainer'] = getLabelValue('policyProposerDetails')
            tempHash['proposerContactDetailsTabContainer'] = getLabelValue('CONTACTINFORMATION') if renderPartyAddressPanel || renderPartyContactPanel
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_primary"
            classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO"
            renderPartyOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
            renderPartyAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
            renderPartyContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
            
            tempHash['insuredDetailsTabContainer'] = getLabelValue('primaryPartyInsured')
            tempHash['insuredContactDetailsTabContainer'] = getLabelValue('CONTACTINFORMATION') if renderPartyAddressPanel || renderPartyContactPanel
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_joint"
            classname = "PolicyJointLifeDO"
            renderPartyOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
            renderPartyAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
            renderPartyContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
            
            tempHash['jointLifeDetailsTabContainer'] = getLabelValue('jointLifeDetails')
            tempHash['jointLifeContactDetailsTabContainer'] = getLabelValue('CONTACTINFORMATION') if renderPartyAddressPanel || renderPartyContactPanel
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_supplementary"
            classname = "PolicySupplementaryLifeDO"
            renderPartyOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
            renderPartyAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
            renderPartyContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
            
            tempHash['supplementaryDetailsTabContainer'+'--'+count.to_s] = getLabelValue('supplementary')
            tempHash['supplementaryContactDetailsTabContainer'+'--'+count.to_s] = getLabelValue('CONTACTINFORMATION') if renderPartyAddressPanel || renderPartyContactPanel
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_nominee"
            tempHash['nomineeDetails'] = getLabelValue("beneficiaryHeader")
            tempHash['appointeeDetails'] = getLabelValue("appointeeHeader")
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_payment"
            tempHash['initialPaymentContainer'] = getLabelValue('initialPayment')
            if MobiSys::BrowserHelper.renderPanel?('RENEWALPREMIUMREQUIRED', $currentProduct)
                tempHash['renewalPaymentContainer'] = getLabelValue('renewalPayment')
            end
            if MobiSys::BrowserHelper.renderPanel?('REFUNDPAYMENTREQUIRED', $currentProduct)
                tempHash['refundPaymentContainer'] = getLabelValue('refundPayment')
            end
            return tempHash.keys.join(","), tempHash.values.join(",")
        when "tab_questionnaire"
            partyNames = object.getPartyNames(currentTab)
            return partyNames.keys.join(','), partyNames.values.join(',')
        when "tab_requirement"
            partyNames = object.getPartyNames(currentTab)
            return partyNames.keys.join(','), partyNames.values.join(',')
        end
    end
    ##################################################################################################


    #Method to get party age based on entered birth date
    def getAge
        @birthDt = @params["birthDt"]
        if @birthDt != nil
            dateParts = @birthDt.split("/")
            @age = MobiSys::ProductUtil.calculateAge(Time.new(dateParts[2].to_i, dateParts[1].to_i, dateParts[0].to_i), MobiSys::ProductUtil::LASTBIRTHDAY, Time.now)
        end
        return render :string => @age.to_json
    end

    #Method to get party birth date based on entered age
    def getBirthDt
        @age = @params["age"]
        if @age != nil
            @birthDt = MobiSys::ProductUtil.calculateDOB(@age, Time.now)
            @birthDate = getScreenDate(@birthDt.to_s)
        end
      return render :string => @birthDate
    end
    ##################################################################################################
    

    def filterProduct
        productFamily = @params['productFamilyCd']
        productFamilyDesc = @params['productFamilyDesc']
        offlineApplicationEnvironment = @params['offlineApplicationEnvironment']
        @productArray = Array.new
        applicableProductList = AgentReg.getCurrentAgentReg.applicableProducts
        currentTime = Time.now
        newProductList = Array.new
        if  offlineApplicationEnvironment == "UAT"     
            $productMaster.each do |key, product|
                if product.productFamilyId == productFamily
                    newProductList.push product
                end
            end
        else
            $productMaster.each do |key, product|
                if product.productFamilyId == productFamily && product.launchDt.to_s != "" && Time.parse(product.launchDt.to_s) <= Time.now
                    if product.withdrawDt.to_s != '' 
                        newProductList.push(product) if Time.parse(product.withdrawDt) >= Time.now
                    else
                        newProductList.push(product)
                    end
                end
            end                                   
        end
        newProductList.each do |product|
            if $filteredPlans
                currentPlanInFilter = false
                $filteredPlans.each do |productFilter|
                    currentPlanInFilter = true if productFilter.productId == product.productId
                end
                next unless currentPlanInFilter
            end
            next unless applicableProductList and applicableProductList.split(",").include? product.productId
            validProduct = true
            product.OfflineFacetList.each do |offlineFacet|
                validProduct = false if offlineFacet.facetId == 'SINOTAPPLICABLE' && offlineFacet.actionValue == "YES"
            end
            if validProduct
                @productArray.push product
            end 
        end

        @productArray.sort_by!{|filterProductName| filterProductName.longName}
        @productArray = @productArray.uniq{|x| x.productId}
        @option = "product"
        html = ""
        html << render(:partial => 'EAPPFilterProduct_Jazz', :locals => {:productFamilyDesc => productFamilyDesc})
        return html
    end
    ##################################################################################################


    def filterProductVersion
        productIdDesc = @params['productIdDesc']
        @filterProductVersionArray = []
        $productMaster.each do |key, product|
            if product.productId.to_s == @params['productId']
                @filterProductVersionArray.push product
            end
        end
        @filterProductVersionArray.sort!{|x,y| x.productVersion.to_i<=>y.productVersion.to_i}.reverse
        @option = "productVersion"
        html = ""
        html << render(:partial => 'EAPPFilterProduct_Jazz', :locals => { :productIdDesc => productIdDesc })
        return html
    end
    ##################################################################################################
    

    def filterProductPlan
        productIdDesc = @params['productIdDesc']
        
        @selectedProduct = ''
        @offlinePlanOptionArray = Array.new

        $productMaster.each do |key, product|
            if product.productFamilyId.to_s == @params['productFamily'].to_s && product.productId.to_s == @params['productId'].to_s && product.launchDt.to_s != "" && Time.parse(product.launchDt.to_s) <= Time.now
                if product.withdrawDt.to_s != ''
                    @selectedProduct = product if Time.parse(product.withdrawDt) >= Time.now
                else
                    @selectedProduct = product
                end
            end
        end

        offlineFacets = @selectedProduct.OfflineFacetList

        offlineFacets.each do |offlineFacet|
            if offlineFacet.facetId == 'PLANOPTION'
                offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                    @offlinePlanOptionArray.push(offlinePlanOptionLookup)
                end
            end
        end
        @offlinePlanOptionArray.sort_by!{|filterPlanName| filterPlanName.description}

        @option = "productPlanOptions"
        html = ""
        html << render(:partial => 'QuoteFilterProduct_Jazz', :locals => {:productIdDesc => productIdDesc})
        return html
    end
    ##################################################################################################
    

    def filterPlanOptionOnProductVersionSelection
        productIdDesc = @params['productIdDesc']  
        @selectedProduct = ''
        @offlinePlanOptionArray = Array.new
        
        $productMaster.each do |key, product|
            if product.productId.to_s == @params['productId'].to_s && product.productVersion == @params['productVersion'].to_s
                @selectedProduct = product
            end
        end

        offlineFacets = @selectedProduct.OfflineFacetList
   
        offlineFacets.each do |offlineFacet|
            if offlineFacet.facetId == 'PLANOPTION'
                offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                    @offlinePlanOptionArray.push(offlinePlanOption)
                end
            end
        end
        
        @offlinePlanOptionArray.sort_by!{|filterPlanName| filterPlanName.description}

        @option = "productPlanOptions"
        html = ""
        html << render(:partial => 'EAPPFilterProduct_Jazz', :locals => {:productIdDesc => productIdDesc})
        return html
    end
    ##################################################################################################


    #Method to load EAPP Product Selection Page
    def addProposal
        if @params['insuranceTypeCd'].to_s != ''
            insuranceTypeCd = @params['insuranceTypeCd']
        else
            insuranceTypeCd = 'LIFE'
        end
        @productFamilyArray = Array.new

        @offlineApplicationEnvironment = OfflineApplication.find(
            :first,
            :conditions => {
                { :name => 'PROPERTY' } => 'ENVIRONMENT'
        })
        
        if @offlineApplicationEnvironment != nil
            if  @offlineApplicationEnvironment.value == nil
                @offlineApplicationEnvironment.value = "PRODUCTION"
            end
        else
            @offlineApplicationEnvironment = OfflineApplication.new
            @offlineApplicationEnvironment.property = 'ENVIRONMENT'
            @offlineApplicationEnvironment.value = "PRODUCTION"
        end
    
    
        applicableProductList = AgentReg.getCurrentAgentReg.applicableProducts.split(',')
        unless $filteredPlans.nil?
            $filteredPlans.each do |productFamily|
                @productFamilyArray = ProductFamily.find(:first, :conditions=>{{:name=>'ProductFamilyId'} => productFamily.planType})
            end
        else
            productFamiliesInProductTable = Product.loadObject(:all, :conditions => {
                {:name => 'productTypeCd'} => "PLAN",
                {:name => 'productId', :op => 'IN'} => applicableProductList
                }, :op => 'AND')
            $productMaster = {}
            productFamiliesInProductTable.each do |product|
                $productMaster["#{product.productId.to_s}_#{product.productVersion.to_s}"] = product
            end
            productFamiliesToShown = productFamiliesInProductTable.map{|value| value.productFamilyId}
            productFamilies = ProductFamily.find(:all, :conditions => {
                {:name => 'productFamilyId', :op => 'IN'} => productFamiliesToShown.uniq
                }, :select => ['productFamilyId', 'description'])
            @productFamilyArray = productFamilies.sort_by{|productFamily| productFamily.productFamilyId}
        end
        render :action => :EAPPProductPage_Jazz, :layout => :jazzLayout
    end
    ##################################################################################################


    #Method to load Search Proposal page alongwith providing search results
    def searchProposal
        if @params['insuranceTypeCd'].to_s != ''
            @insuranceType = @params['insuranceTypeCd']
        else
            @insuranceType = nil
        end
        render :action => :EAPPSearch_Jazz, :layout => :jazzLayout
    end
    ##################################################################################################


    #Method to load Proposal from search results page
    def showProposal
        WebView.execute_js("loading('show');")
        $rhoconfig[:moduleForProductValidations] = "Policy"
        $checkForSearch = true
        # $dirtyQuestionnaireTab = false if $dirtyQuestionnaireTab == nil
        id = @params['id'][1..-1].chop
        @currentAgentId = AgentReg.getCurrentAgentReg.agentId
        @params['sym_current_Tab'] = 'tab_requirement' if @params["set_get_req_tab"] == "TRUE"
        $globalFacetHash = nil
        $childHTMLHash = nil
        @policy = Policy.loadObject(:first, :conditions => {:object => id })
        if @params['backLink'].to_s != ''
            @backLink = @params['backLink']
        else
            @backLink = "/app/Policy/searchProposal?insuranceTypeCd=#{@policy.insuranceTypeCd}"
        end
        @product = MobiSys::ProductUtil.getProduct(@policy.baseProductSeq)
        $currentProduct = @product

        @tabName, @tabLabel, @tabImages = requiredTabs
        @gatewayFlag = @policy.getGatewayFlag
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs,@tabName)
        @visitedTabs = @policy.visitedTabs.to_s
        if @policy.insuranceTypeCd == 'TRAVEL'
            @params['sym_current_Tab'] = 'tab_travellerDetails' unless @params.has_key?('sym_current_Tab')
        elsif @policy.insuranceTypeCd == 'AUTO'
            @params['sym_current_Tab'] = 'tab_vehicleDetails' unless @params.has_key?('sym_current_Tab')
        else
            @params['sym_current_Tab'] = 'tab_basic' unless @params.has_key?('sym_current_Tab')
        end
        getTravelDetails if @params['sym_current_Tab'] == 'tab_travellerDetails'  
        getTravelPaymentDetails if @params['sym_current_Tab'] == 'tab_paymentGateway'
        getBasicVehicleDetails if @params['sym_current_Tab'] == 'tab_vehicleDetails'
        getVehicleInsuredDetails if @params['sym_current_Tab'] == 'tab_vehicleInsuredDetails'
        getAgentDetails if @params['sym_current_Tab'] == 'tab_basic' 
        getPrdSelection if @params['sym_current_Tab'] == 'tab_selProduct' 
        getPolicyHolder if @params['sym_current_Tab'] == 'tab_owner'
        getInsured if @params['sym_current_Tab'] == 'tab_primary' 
        getJointLifeInsured if @params['sym_current_Tab'] == 'tab_joint'
        getSupplementaryInsured if @params['sym_current_Tab'] == 'tab_supplementary'
        getPlanDetails
        getBeneficiaryAppointee if @params['sym_current_Tab'] == 'tab_nominee' 
        getPaymentDetails if @params['sym_current_Tab'] == 'tab_payment' 
        getQuestionnaires if @params['sym_current_Tab'] == 'tab_questionnaire' 
        getRequirements if @params['sym_current_Tab'] == 'tab_requirement' 
        getPremiumSummary if @params['sym_current_Tab'].to_s == 'tab_premiumSummary'
            
        if $rhoconfig[:captureSignatureInTab]
            if @params['sym_current_Tab'] == 'tab_signature' 
                errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
                if errorTabs.gsub("tab_signature","").gsub(",","") == "" && incompleteTabs.empty?
                     getSignature
                else
                    Alert.show_popup({
                        :message => getLabelValue('ERR_WARNINGRESOLVE',['sign']),
                        :title => '', 
                        :icon => :info,
                        :buttons => ["OK"] 
                    })
                    @params['sym_current_Tab'] = 'tab_basic'
                    getAgentDetails
                end
            end
        else
            getAgentQuestion if @params['sym_current_Tab'] == 'tab_agentDeclaration'
        end

        @renderMultiLanguagePanel = MobiSys::BrowserHelper.renderPanel?('MULTILINGUALPARTYNAME', $currentProduct)
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@policy)

        render :action => :NBProposalEntryComplete, :layout => :jazzLayout, :query => {"selectedProductFamily" => @selectedProductFamily, "selectedProductId" => @selectedProductId, "selectedProductPlanOptionCd" => @selectedProductPlanOptionCd, "quotationObject" => @quotationObject, "baseProdObj" => @baseProdObj, "ridersObjArray" => @ridersObjArray, "fundsObjArray" => @fundsObjArray}
    end
    ##################################################################################################


    #Method to render EAPP Main Edit Page after EAPP Product Selection Page/ after Link to EAPP
    def newPolicy
        WebView.execute_js("loading('show');")
        $rhoconfig[:moduleForProductValidations] = "Policy"
        $checkForSearch = false
        # $dirtyQuestionnaireTab = false
        @language = Application.getValue('DEFAULTLOCALE')
        quotationObject = @params['quotationId']
        
        quotation = Quotation.loadObject(:first,:conditions => {:object => quotationObject })
        $globalFacetHash = nil
        quotpolicy = nil
        if quotation != nil
            quotpolicy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
            if quotpolicy
                @policy = quotpolicy
            else
                @policy = Policy.new
                @policy.quotationRefGuid = quotation.uniqueKey
                @policy.bankStaffReferralCd = quotation.bankStaffReferralCd
                @policy.quotationRefNum = quotation.quotationRefNum
                @policy.leadId = quotation.leadId
                @policy.fnaId = quotation.fnaId
                @policy.rpqId = quotation.rpqId
                @policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                @policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                @policy.isBackdatedFl = quotation.isBackdatedFl
                @policy.quotationDt = quotation.quotationDt
                @policy.insuranceTypeCd = quotation.insuranceTypeCd
                @policy.tripTypeCd = quotation.tripTypeCd
                @policy.maxTripPeriod = quotation.maxTripPeriod
                @policy.travelGeographyCd = quotation.travelGeographyCd
                @policy.visitPurposeCd = quotation.visitPurposeCd
                @policy.numberOfAdult = quotation.numberOfAdult
                @policy.numberOfChildren = quotation.numberOfChildren
                @policy.startDt = quotation.startDt
                @policy.endDt = quotation.endDt
                @policy.coverTypeCd = quotation.coverTypeCd
                @policy.autoRegistrationNum = quotation.autoRegistrationNum
                @policy.autoMakeCd = quotation.autoMakeCd
                @policy.autoModelCd = quotation.autoModelCd

                if quotation.isBackdatedFl.to_s == "YES"
                    @policy.policyCommencementDt = quotation.quotationDt
                else
                    @policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                if quotation.isBackdatedFl.to_s == "YES"
                    @policy.riskCommencementDt = quotation.quotationDt
                else
                    @policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                @policy.baseAgentId = $userId
                @policy.intimationSourceCd = "ESUBMISSION"
                @policy.uwDecisionCd = "PENDING"
                @policy.statusCd = "PENDING"

                MobiSys::PolicyBO.convertIllustrationToEappPlanDetails(quotation, @policy)
                
                policyHolder = Party.new(:roleCd => "PROPOSER")
                @policy.addParty(policyHolder)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, policyHolder, "PROPOSER")
                policyPartyRoleProposer = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => policyHolder.uniqueKey)
                @policy.addPolicyPartyRole(policyPartyRoleProposer)

                if quotation.proposerLASame == "COPYFROMINSURED" || quotation.getPartyByRole('PRIMARY').partySameAsCd.to_s == 'PROPOSER'
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => "PROPOSER")
                    @policy.addPolicyPartyRole(policyPartyRoleInsured)
                    @policy.insuredSameAsProposer = 'YES'
                    @policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => policyHolder.guid)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                else
                    insured = Party.new(:roleCd => "PRIMARY")
                    @policy.addParty(insured)
                    MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, insured, "PRIMARY")
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => insured.uniqueKey, :partySameAsCd => "")
                    @policy.addPolicyPartyRole(policyPartyRoleInsured)
                    @policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => insured.guid)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                end

                if quotation.getPartyByRole("JOINT")
                    jointLife = Party.new(:roleCd => "JOINT")
                    @policy.addParty(jointLife)
                    MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, jointLife, "JOINT")
                    policyPartyRoleJointLife = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => jointLife.uniqueKey)
                    @policy.addPolicyPartyRole(policyPartyRoleJointLife)
                    @policy.jointLife = 'YES'
                    @policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            jointProductInsured = PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => jointLife.guid)
                            policyProduct.addPolicyProductInsured(jointProductInsured)
                        end
                    end
                end

                $currentProduct = MobiSys::ProductUtil.getProduct(@policy.baseProductSeq) if !$currentProduct
                familyFloaterFl = $currentProduct.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES'
                quotation.getPartyListByRoleCd("SUPPLEMENTARY").each_with_index do |oldParty, index|
                    if oldParty.partySameAsCd == 'PROPOSER' && quotation.insuranceTypeCd == 'AUTO'
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => 'PROPOSER')
                        @policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                    else
                        suppLife = Party.new(:roleCd => "SUPPLEMENTARY")
                        @policy.addParty(suppLife)
                        MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, suppLife, "SUPPLEMENTARY", index)
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => suppLife.uniqueKey)
                        @policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                        if familyFloaterFl
                            @policy.PolicyProductList.each do |policyProduct|
                                if policyProduct.productTypeCd == 'PLAN'
                                    supProductInsured = PolicyProductInsured.new(:roleCd => "SUPPLEMENTARY", :insuredSequenceTypeCd => "SUPPLEMENTARY", :insuredPartyRefGuid => suppLife.guid)
                                    policyProduct.addPolicyProductInsured(supProductInsured)
                                    break
                                end
                            end 
                        end
                    end
                end
                # Deepali Singh: This method is generally to be overridden at company to copy any additional fields from SI to EAPP
                MobiSys::PolicyBO.convertIllustrationToEappAdditionalDetails(quotation, @policy)
                @policy.persistAll
            end
            @product = MobiSys::ProductUtil.getProduct(@policy.baseProductSeq)
        else
            @product = MobiSys::ProductUtil.getProduct(@params['productSeq']) if @params['productSeq'] != ""
            @policy = Policy.new
            
            @policy.baseProductSeq = @product.id
            @policy.baseProductId = @params['productId']
            @policy.baseProductTypeCd = 'PLAN'
            @policy.baseProductFamilyCd = @params['productFamily']
            @policy.productPlanOptionCd = @params['productPlanOptionCd'] if @params['productPlanOptionCd'] != "null"
            @policy.baseProductVersion = @product.productVersion
            @policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
            @policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
            @policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            @policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            @policy.baseAgentId = $userId
            @policy.intimationSourceCd = "ESUBMISSION"
            @policy.uwDecisionCd = "PENDING"
            @policy.statusCd = "PENDING"
            @policy.insuranceTypeCd = @params['insuranceTypeCd'] if @params['insuranceTypeCd'].to_s != ''
            setObjectCount(@policy, 250)
            setObjectMapping(@policy, @policy.class.name)
        end
        $currentProduct = @product
        @tabName, @tabLabel, @tabImages = requiredTabs

        @gatewayFlag = @policy.getGatewayFlag
        if @policy.insuranceTypeCd == 'TRAVEL'
            @params['sym_current_Tab'] = 'tab_travellerDetails' unless @params.has_key?('sym_current_Tab')
        elsif @policy.insuranceTypeCd == 'AUTO'
            @params['sym_current_Tab'] = 'tab_vehicleDetails' unless @params.has_key?('sym_current_Tab')
        else
            @params['sym_current_Tab'] = 'tab_basic' unless @params.has_key?('sym_current_Tab')
        end
        getTravelDetails if @params['sym_current_Tab'] == 'tab_travellerDetails' 
        getTravelPaymentDetails if @params['sym_current_Tab'] == 'tab_paymentGateway'
        getBasicVehicleDetails if @params['sym_current_Tab'] == 'tab_vehicleDetails'
        getVehicleInsuredDetails if @params['sym_current_Tab'] == 'tab_vehicleInsuredDetails'
        getAgentDetails if @params['sym_current_Tab'] == 'tab_basic' 
        getPolicyHolder if @params['sym_current_Tab'] == 'tab_owner'
        getInsured if @params['sym_current_Tab'] == 'tab_primary' 
        getJointLifeInsured if @params['sym_current_Tab'] == 'tab_joint'
        getSupplementaryInsured if @params['sym_current_Tab'] == 'tab_supplementary'
        getPlanDetails
        getBeneficiaryAppointee if @params['sym_current_Tab'] == 'tab_nominee' 
        getPaymentDetails if @params['sym_current_Tab'] == 'tab_payment' 
        getQuestionnaires if @params['sym_current_Tab'] == 'tab_questionnaire' 
        getRequirements if @params['sym_current_Tab'] == 'tab_requirements' 
        if $rhoconfig[:captureSignatureInTab]
            getSignature if @params['sym_current_Tab'] == 'tab_signature' 
        else
            getAgentQuestion if @params['sym_current_Tab'] == 'tab_agentDeclaration' 
        end

        @renderMultiLanguagePanel = MobiSys::BrowserHelper.renderPanel?('MULTILINGUALPARTYNAME', $currentProduct)
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@policy)
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        @visitedTabs = @policy.visitedTabs.to_s
        if @params['backLink'].to_s != ''
            @backLink = @params['backLink']
        else
            @backLink = "/app/Policy/searchProposal?insuranceTypeCd="+@policy.insuranceTypeCd.to_s
        end
        
        render :action => :NBProposalEntryComplete, :layout => :jazzLayout
    end
    ##################################################################################################


    #Method to load Agent Details Tab
    def getAgentDetails
        agent_array = @policy.getPolicyAgentList(true)
        @policyAgent1 = agent_array[0]
        @policyAgent2 = agent_array[1]

        @AgentRegdetails = AgentReg.forUserId($userId)
        if @AgentRegdetails
            @policyAgent1.agentId = @AgentRegdetails.agentId
            @policyAgent1.agentName = @AgentRegdetails.agentName1
            @policyAgent1.channelId = @AgentRegdetails.channel
        end
        if !MobiSys::BrowserHelper.renderPanel?('AGENTSHARING', $currentProduct)
            @policyAgent1.commPercent = "100"
            @policyAgent1.prodnPercent = "100"
            @policyAgent1.jointFieldWork = "NO"
            @policyAgent2.jointFieldWork = "NO"
        else
            @policyAgent1.jointFieldWork = "YES"
            @policyAgent2.jointFieldWork = "YES"
        end
        @policyAgent1.primaryAgentFl = "YES"
        @policyAgent2.primaryAgentFl = "NO"

        @policy.proposalSignedDt = getScreenDate(@policy.proposalSignedDt) if @policy.proposalSignedDt.to_s != ""
        @policy.proposalReceivedDt = getScreenDate(@policy.proposalReceivedDt) if @policy.proposalReceivedDt.to_s != ""
        @policy.riskCommencementDt = getScreenDate(@policy.riskCommencementDt) if @policy.riskCommencementDt.to_s != ""
        @policy.startDt = getScreenDate(@policy.startDt) if @policy.startDt.to_s != ""
        @policy.endDt = getScreenDate(@policy.endDt) if @policy.endDt.to_s != ""
        
        @policy.PolicyAgentList.each do |policyAgent|
            policyAgent.yearFrom = policyAgent.yearFrom if policyAgent.yearFrom.to_s != ""
            policyAgent.yearTo = policyAgent.yearTo if policyAgent.yearTo.to_s != ""
        end
        
        @basicNavbarIds,@basicNavbarLabels = getNavbarDetails('tab_basic',$currentProduct)
    end
    ##################################################################################################
    
    def getPrdSelection
        @baseProduct = @policy.getBaseProduct
        @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@policy)
        if @policy.insuranceTypeCd == 'TRAVEL'
            @premiumMatrix = travelPremiumComputation(@policy)
        end
    end

    #Method to load Policy Holder/ Proposer Details Tab
    def getPolicyHolder
        @policyHolder = @policy.getParty("PROPOSER")
        if @policy && @policyHolder != nil
            @policyHolderPolicyPartyRole = @policy.getPolicyPartyRole("PROPOSER")
        else
            setObjectCount(@policy, 100)
            setObjectMapping(@policy, @policy.class.name)
            @policyHolder = Party.new(:roleCd => "PROPOSER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@policyHolder)
            @policyHolderPolicyPartyRole = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => @policyHolder.uniqueKey)
            @policy.addPolicyPartyRole(@policyHolderPolicyPartyRole)
        end

        @policyHolderHomeAddress = @policyHolder.getPartyAddress("RESIDENTIAL", true)
        @policyHolderBusinessAddress = @policyHolder.getPartyAddress("OFFICE", true)
        @policyHolderPermanentAddress = @policyHolder.getPartyAddress("PERMANENT", true)
        
        @policyHolderContactHome = @policyHolder.getPartyContact("RESIDENTIAL", true)
        @policyHolderContactOffice = @policyHolder.getPartyContact("OFFICE", true) 
        @policyHolderContactMobile = @policyHolder.getPartyContact("MOBILE", true)
        
        @policyHolderEmail = @policyHolder.getPartyEmail(true)
        @policyHolderEmployment = @policyHolder.getPartyEmployment(true)
        identity_array = @policyHolder.getPartyIdentityList(true)
        @policyHolderIdentity1, @policyHolderIdentity2 = identity_array[0], identity_array[1]

        #converting db date to screen date
        @policyHolder.birthDt = getScreenDate(@policyHolder.birthDt) if @policyHolder.birthDt != nil || @policyHolder.birthDt != ""
        @policyHolderIdentity1.expiryDt = getScreenDate(@policyHolderIdentity1.expiryDt) if @policyHolderIdentity1.expiryDt != nil || @policyHolderIdentity1.expiryDt != ""
        @policyHolderIdentity1.issueDt = getScreenDate(@policyHolderIdentity1.issueDt) if @policyHolderIdentity1.issueDt != nil || @policyHolderIdentity1.issueDt != ""
        @policyHolderIdentity2.expiryDt = getScreenDate(@policyHolderIdentity2.expiryDt) if @policyHolderIdentity2.expiryDt != nil || @policyHolderIdentity2.expiryDt != ""
        @policyHolderIdentity2.issueDt = getScreenDate(@policyHolderIdentity2.issueDt) if @policyHolderIdentity2.issueDt != nil || @policyHolderIdentity2.issueDt != ""

        classname = "PolicyProposerDO"

        @renderPolicyHolderNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPolicyHolderIdentityPanel = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
        @renderPolicyHolderOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
        @renderPolicyHolderAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyHolderHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyHolderOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPolicyHolderPermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPolicyHolderContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyHolderHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyHolderOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyHolderMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyHolderEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        @proposerNavbarIds,@proposerNavbarLabels = getNavbarDetails('tab_owner')
    end
    ##################################################################################################


    #Method to load Insured/ Primary Details Tab
    def getInsured
        if @policy
            @primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
        end

        if @primaryInsuredPolicyPartyRole
            if @primaryInsuredPolicyPartyRole.partySameAsCd != "" && @primaryInsuredPolicyPartyRole.partySameAsCd != nil
                setObjectCount(@policy, 50)
                setObjectMapping(@policy, @policy.class.name)
                @primaryInsured = Party.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
                @policy.addParty(@primaryInsured)
            else
                @primaryInsured = @policy.getParty("PRIMARY")
            end
        else  
            setObjectCount(@policy, 50)
            setObjectMapping(@policy, @policy.class.name)
            @primaryInsured = Party.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@primaryInsured)
            @primaryInsuredPolicyPartyRole = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => @primaryInsured.uniqueKey, :partySameAsCd => "")
            @policy.addPolicyPartyRole(@primaryInsuredPolicyPartyRole)
        end
        if @primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
            @primaryInsuredPolicyPartyRole.partySameAsCd = "YES" 
            @policy.insuredSameAsProposer = 'YES'
        end
        @primaryInsuredHomeAddress = @primaryInsured.getPartyAddress("RESIDENTIAL", true)
        @primaryInsuredBusinessAddress = @primaryInsured.getPartyAddress("OFFICE", true)
        @primaryInsuredPermanentAddress = @primaryInsured.getPartyAddress("PERMANENT", true)
        
        @primaryInsuredContactHome = @primaryInsured.getPartyContact("RESIDENTIAL", true)
        @primaryInsuredContactOffice = @primaryInsured.getPartyContact("OFFICE", true) 
        @primaryInsuredContactMobile = @primaryInsured.getPartyContact("MOBILE", true)
        
        @primaryInsuredEmail = @primaryInsured.getPartyEmail(true)
        @primaryInsuredEmployment = @primaryInsured.getPartyEmployment(true)
        identity_array = @primaryInsured.getPartyIdentityList(true)
        @primaryInsuredIdentity1, @primaryInsuredIdentity2 = identity_array[0], identity_array[1]

        #converting db date to screen date
        @primaryInsured.birthDt = getScreenDate(@primaryInsured.birthDt) if @primaryInsured.birthDt != nil || @primaryInsured.birthDt != ""
        @primaryInsuredIdentity1.expiryDt = getScreenDate(@primaryInsuredIdentity1.expiryDt) if @primaryInsuredIdentity1.expiryDt != nil || @primaryInsuredIdentity1.expiryDt != ""
        @primaryInsuredIdentity1.issueDt = getScreenDate(@primaryInsuredIdentity1.issueDt) if @primaryInsuredIdentity1.issueDt != nil || @primaryInsuredIdentity1.issueDt != ""
        @primaryInsuredIdentity2.expiryDt = getScreenDate(@primaryInsuredIdentity2.expiryDt) if @primaryInsuredIdentity2.expiryDt != nil || @primaryInsuredIdentity2.expiryDt != ""
        @primaryInsuredIdentity2.issueDt = getScreenDate(@primaryInsuredIdentity2.issueDt) if @primaryInsuredIdentity2.issueDt != nil || @primaryInsuredIdentity2.issueDt != ""

        @proposerExists = true if @policy.getParty("PROPOSER")
        classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO"
        @renderPrimaryInsuredNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPrimaryInsuredIdentityPanel = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
        @renderPrimaryInsuredOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
        @renderPrimaryInsuredAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPrimaryInsuredHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPrimaryInsuredOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPrimaryInsuredPermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPrimaryInsuredContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPrimaryInsuredHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPrimaryInsuredOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPrimaryInsuredMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPrimaryInsuredEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        @primaryInsuredNavbarIds,@primaryInsuredNavbarLabels = getNavbarDetails('tab_primary')

        @insured = true    
    end
    ##################################################################################################


    #Method to load Joint Life Details Tab
    def getJointLifeInsured
        @jointLife = @policy.getParty("JOINT")

        if @policy && @jointLife != nil
            @jointLifePolicyPartyRole = @policy.getPolicyPartyRole("JOINT")
        else  
            setObjectCount(@policy, 50)
            setObjectMapping(@policy, @policy.class.name)
            @jointLife = Party.new(:roleCd => "JOINT", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@jointLife)
            @jointLifePolicyPartyRole = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => @jointLife.uniqueKey)
            @policy.addPolicyPartyRole(@jointLifePolicyPartyRole)
        end
        
        if @policy.jointLife.to_s != "YES"
            @jointLife.removed = "YES"
            @jointLifePolicyPartyRole.removed = "YES"
        end

        @jointLifeHomeAddress = @jointLife.getPartyAddress("RESIDENTIAL", true)
        @jointLifeBusinessAddress = @jointLife.getPartyAddress("OFFICE", true)
        @jointLifePermanentAddress = @jointLife.getPartyAddress("PERMANENT", true)
        
        @jointLifeContactHome = @jointLife.getPartyContact("RESIDENTIAL", true)
        @jointLifeContactOffice = @jointLife.getPartyContact("OFFICE", true) 
        @jointLifeContactMobile = @jointLife.getPartyContact("MOBILE", true)
        
        @jointLifeEmail = @jointLife.getPartyEmail(true)
        @jointLifeEmployment = @jointLife.getPartyEmployment(true)
        identity_array = @jointLife.getPartyIdentityList(true)
        @jointLifeIdentity1, @jointLifeIdentity2 = identity_array[0], identity_array[1]

        #converting db date to screen date
        @jointLife.birthDt = getScreenDate(@jointLife.birthDt) if @jointLife.birthDt != nil || @jointLife.birthDt != ""
        @jointLifeIdentity1.expiryDt = getScreenDate(@jointLifeIdentity1.expiryDt) if @jointLifeIdentity1.expiryDt != nil || @jointLifeIdentity1.expiryDt != ""
        @jointLifeIdentity1.issueDt = getScreenDate(@jointLifeIdentity1.issueDt) if @jointLifeIdentity1.issueDt != nil || @jointLifeIdentity1.issueDt != ""
        @jointLifeIdentity2.expiryDt = getScreenDate(@jointLifeIdentity2.expiryDt) if @jointLifeIdentity2.expiryDt != nil || @jointLifeIdentity2.expiryDt != ""
        @jointLifeIdentity2.issueDt = getScreenDate(@jointLifeIdentity2.issueDt) if @jointLifeIdentity2.issueDt != nil || @jointLifeIdentity2.issueDt != ""

        classname = "PolicyJointLifeDO"
        @renderjointLifeNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderjointLifeIdentityPanel = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
        @renderjointLifeOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
        @renderjointLifeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderjointLifeHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderjointLifeOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderjointLifePermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderjointLifeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderjointLifeHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderjointLifeOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderjointLifeMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderjointLifeEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        @jointLifeNavbarIds,@jointLifeNavbarLabels = getNavbarDetails('tab_joint')
    end
    ##################################################################################################


    #Method to load Supplementary Life Insured Details Tab
    def getSupplementaryInsured
        @supplementaryLife = Array.new
        @supplementaryLife = @policy.getPartyList("SUPPLEMENTARY")
        @suplementaryInsuredCount = 0
        if @policy && @supplementaryLife != nil
            @suplementaryInsuredCount = @supplementaryLife.length
        end
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
        @supPolicyProductHM = {}

        if @supplementaryProductFacet
            @supPolicyProductCount = 200
            supPolicyProducts = @policy.getPolicyProductByProductTypeCd('PLANMULTI')
            supPolicyProducts.each do |qp|
                @supPolicyProductHM[qp.insuredPartyRefGuid] = qp
            end
        end
        @language = Application.getValue('DEFAULTLOCALE')
    end
    ##################################################################################################


    #Method to dynamically create/ load Supplementary Life Insured data
    def addSupplementaryInsured(policy=nil, party=nil, suplementaryInsuredCount=nil, policyProduct=nil, supPolicyProductCount=nil)
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')

        if party != nil && policy != nil && suplementaryInsuredCount != nil
            @suplementaryInsuredCount = suplementaryInsuredCount
            # @visibleSupplementaryCount = suplementaryInsuredCount
            @policy = policy
            @party = party
            @policy.getPolicyPartyRoleList("SUPPLEMENTARY").each do |policyPartyRole|
                if policyPartyRole.refGuid == @party.guid
                    @policyPartyRole = policyPartyRole
                end
            end
            if @supplementaryProductFacet && policyProduct != nil
                @supPolicyProductCount = supPolicyProductCount
                @policyProduct = policyProduct
                @policyProductInsured = @policyProduct.PolicyProductInsuredList[0]
            end
        else
            policyObject = @params['policyObject']
            @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>policyObject})
            @suplementaryInsuredCount = @params['suplementaryInsuredCount']
            # @visibleSupplementaryCount = @params['visibleSupplementaryCount']

            @party = Party.new(:roleCd => "SUPPLEMENTARY", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@party)
            @policyPartyRole = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => @party.uniqueKey)
            @policy.addPolicyPartyRole(@policyPartyRole)

            if @supplementaryProductFacet
                @supPolicyProductCount = @params['supPolicyProductCount']
                @policyProduct = PolicyProduct.new
                @policyProduct.productTypeCd = "PLANMULTI"
                @policyProduct.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.baseAnnualPremium = 0.0
                @policyProduct.baseSumAssured = 0.0
                @policyProduct.modalPremium = 0.0
                @policy.addpolicyProduct(@policyProduct)
                @policyProductInsured = PolicyProductInsured.new
                @policyProductInsured.roleCd = 'SUPPLEMENTARY'
                @policyProductInsured.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.addPolicyProductInsured(@policyProductInsured)
            end
        end
        @homeAddress = @party.getPartyAddress("RESIDENTIAL", true)
        @businessAddress = @party.getPartyAddress("OFFICE", true)
        @permanentAddress = @party.getPartyAddress("PERMANENT", true)
        
        @partyContactHome = @party.getPartyContact("RESIDENTIAL", true)
        @partyContactOffice = @party.getPartyContact("OFFICE", true) 
        @partyContactMobile = @party.getPartyContact("MOBILE", true)
        
        @partyEmail = @party.getPartyEmail(true)
        @partyEmployment = @party.getPartyEmployment(true)
        identity_array = @party.getPartyIdentityList(true)
        @partyIdentity1, @partyIdentity2 = identity_array[0], identity_array[1]  

        #converting db date to screen date
        @party.birthDt = getScreenDate(@party.birthDt) if @party.birthDt != nil || @party.birthDt != ""
        @partyIdentity1.expiryDt = getScreenDate(@partyIdentity1.expiryDt) if @partyIdentity1.expiryDt != nil || @partyIdentity1.expiryDt != ""
        @partyIdentity1.issueDt = getScreenDate(@partyIdentity1.issueDt) if @partyIdentity1.issueDt != nil || @partyIdentity1.issueDt != ""
        @partyIdentity2.expiryDt = getScreenDate(@partyIdentity2.expiryDt) if @partyIdentity2.expiryDt != nil || @partyIdentity2.expiryDt != ""
        @partyIdentity2.issueDt = getScreenDate(@partyIdentity2.issueDt) if @partyIdentity2.issueDt != nil || @partyIdentity2.issueDt != ""

        @language = Application.getValue('DEFAULTLOCALE')
        # maskNumbers(@party)  
        setObjectCount(@policy, @suplementaryInsuredCount)
        setObjectMapping(@policy, @policy.class.name) 

        classname = "PolicySupplementaryLifeDO"
        @renderSupplementaryNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderSupplementaryIdentityPanel = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
        @renderSupplementaryOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
        @renderSupplementaryAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderSupplementaryHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderSupplementaryOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderSupplementaryPermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderSupplementaryContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderSupplementaryHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderSupplementaryOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderSupplementaryMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderSupplementaryEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')
        @supplementaryNavbarIds,@supplementaryNavbarLabels = getNavbarDetails('tab_supplementary', nil, @suplementaryInsuredCount)
        html = ""
        html << render(:partial => 'addSupplimentaryInsuredDetails_Jazz')
        return html     
    end
    ##################################################################################################


    def submitSupplementary(policy)
        if $currentProduct
            supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
            if supplementaryProductFacet
                supplementaryLifeGuids = policy.getPartyList('SUPPLEMENTARY').collect{|sup| sup.guid}
                supPolicyProducts = policy.getPolicyProductByProductTypeCd('PLANMULTI')
                if policy.getBaseProduct
                    supPolicyProducts.each do |qp|
                        if supplementaryLifeGuids.include? qp.insuredPartyRefGuid
                            baseProductClone = policy.getBaseProduct.cloneObject
                            baseProductClone.baseAnnualPremium = qp.baseAnnualPremium
                            baseProductClone.baseSumAssured = qp.baseSumAssured
                            baseProductClone.productTypeCd = qp.productTypeCd
                            baseProductClone.insuredPartyRefGuid = qp.insuredPartyRefGuid
                            baseProductClone.modalPremium = qp.modalPremium
                            baseProductClone.guid = baseProductClone.object.gsub(".","_")
                            baseProductClone.systemCreatedDt = qp.systemCreatedDt
                            baseProductClone.PolicyProductInsuredList[0].roleCd = 'SUPPLEMENTARY'
                            baseProductClone.PolicyProductInsuredList[0].insuredPartyRefGuid = qp.insuredPartyRefGuid
                            policy.removePolicyProduct(qp)
                            policy.removePolicyProductInvestmentFund(qp.PolicyProductInvestmentFundList[0])
                            policy.removePolicyProductInsured(qp.PolicyProductInsuredList[0])
                            policy.removePolicyProductExtra(qp.PolicyProductExtraList[0])
                            policy.removePolicyProductAdditional(qp.PolicyProductAdditionalList[0])
                            policy.addPolicyProduct(baseProductClone)
                            policy.addPolicyProductInsured(baseProductClone.PolicyProductInsuredList[0])
                        else
                            qp.removed = 'YES'
                        end
                    end
                end
            end
        end
    end
    ##################################################################################################


    #Method to load Coverage Details Tab
    def getPlanDetails
        @baseProduct = @policy.getBaseProduct
        unless @baseProduct
            @baseProduct = PolicyProduct.new(:productTypeCd => "PLAN", :productSeq => @policy.baseProductSeq, :productId => @policy.baseProductId, :productPlanOptionCd => @policy.productPlanOptionCd, :productFamilyCd => @policy.baseProductFamilyCd, :productVersion => @policy.baseProductVersion)
            @baseProduct.product =  $currentProduct
            @policy.addPolicyProduct(@baseProduct)
        end
        
        if @params['sym_current_Tab'] == 'tab_coverage'
            @showRider = false

            if @policy.quotationRefGuid.to_s == ""
                @showRider = true
            else
                @policy.PolicyProductList.each do |riderProduct|
                    if riderProduct.productTypeCd == "RIDER"
                        @showRider = true
                        break
                    end
                end
            end

            #Initialize TopUps
            unless @policy.PolicyTopUpList.empty?
                @policy.PolicyTopUpList.each do |topUp|
                    if topUp.topUpTypeCd == 'REGULARTOPUP'
                        @regularTopUp = topUp
                    elsif topUp.topUpTypeCd == 'INITIALINVESTMENT'
                        @initialTopup = topUp
                    end    
                end   
            else
                @regularTopUp = PolicyTopUp.new(:topUpTypeCd =>'REGULARTOPUP')
                @policy.addPolicyTopUp(@regularTopUp)
                @initialTopup = PolicyTopUp.new(:topUpTypeCd =>'INITIALINVESTMENT')
                @policy.addPolicyTopUp(@initialTopup)
            end
            
            prePopulateFunds(@policy, @baseProduct)

            @funds = @baseProduct.PolicyProductInvestmentFundList
            @fundCount = 250
            @riderObjects = 100
            
            $premiumSAFl = ''
            $multiplierFacet = ''
            $premiumPayingTerm = true
            
            $currentProduct.OfflineFacetList.each do |offlineFacet|
                if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
                    $premiumPayingTerm = false
                elsif offlineFacet.facetId == 'MINMAXTERM'
                    @minMaxTermFacet = offlineFacet
                end
            end

            premiumFacet = $currentProduct.getFacet('PREMIUMDETAILS')
            @allowedCurrency = ''
            @allowedPaymentTypeCd = ''
            @allowedPaymentFrequencyCd = ''
            if premiumFacet
                premiumFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
                    @readOnlyFields = offlinePremiumDetail.inputDataElement.to_s
                    if offlinePremiumDetail.premiumSAFl != nil
                        if offlinePremiumDetail.premiumSAFl == 'SA'
                            $premiumSAFl = 'SA'
                        elsif offlinePremiumDetail.premiumSAFl == 'PREMIUM'
                            $premiumSAFl = 'PREMIUM'
                        elsif offlinePremiumDetail.premiumSAFl == 'DUAL'
                            $premiumSAFl = 'DUAL'
                        elsif offlinePremiumDetail.premiumSAFl == 'ANNUALINCOME'
                            $premiumSAFl = 'ANNUALINCOME'
                        elsif offlinePremiumDetail.premiumSAFl == 'MONTHLYINCOME'
                            $premiumSAFl = 'MONTHLYINCOME'
                        elsif offlinePremiumDetail.premiumSAFl == 'ANNUALPREMIUM'
                            $premiumSAFl = 'ANNUALPREMIUM'
                        elsif offlinePremiumDetail.premiumSAFl == 'COMPUTEDSA'
                            $premiumSAFl = 'COMPUTEDSA'
                        end
                    end

                    if offlinePremiumDetail.premiumTypeCd.to_s != ''
                        @allowedPaymentTypeCd = offlinePremiumDetail.premiumTypeCd
                    end
                    if offlinePremiumDetail.paymentFrequencyCd.to_s != ''
                        @allowedPaymentFrequencyCd = offlinePremiumDetail.paymentFrequencyCd
                    end
                    if offlinePremiumDetail.currencyCd.to_s != ''
                        @allowedCurrency = offlinePremiumDetail.currencyCd
                    end
                end
            end

            @policyProductExtraLabelObject = PolicyProductExtra.new(:removed=>"YES")
            @fundLabelObject = PolicyProductInvestmentFund.new(:removed=>"YES")
            @adhocTopupLabelObject = PolicyTopUp.new(:topUpTypeCd => "ADHOCTOPUP",:removed=>"YES")
            @transferTopupLabelObject = PolicyTopUp.new(:topUpTypeCd => "TRANSFERTOPUP",:removed=>"YES")


            @quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
            @quotationBasePlan = @quotation.getBaseProduct
            party = @quotation.getParty(@quotationBasePlan)
            @quotationBasePlan.combinedEntryAge = party.age.to_s if party

            #Initialize Product Models
            fundRequiredDetailsDT = $currentProduct.getFacetValue("FUNDSREQUIREDNB")
            @modelArray = getPortfolioModelCd($currentProduct, @quotation, @quotationBasePlan) if fundRequiredDetailsDT == 'YES'

            #Initialize additional fields facets & lookups
            @addtnField1TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD1INPUTTYPE')
            @addtnField1LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD1LABEL')
            @addtnField1LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD1LOOKUP')
            
            @addtnField2TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD2INPUTTYPE')
            @addtnField2LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD2LABEL')
            @addtnField2LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD2LOOKUP')
            
            @addtnField3TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD3INPUTTYPE')
            @addtnField3LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD3LABEL')
            @addtnField3LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD3LOOKUP')
            
            @addtnField4TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD4INPUTTYPE')
            @addtnField4LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD4LABEL')
            @addtnField4LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD4LOOKUP')
            
            @addtnField5TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD5INPUTTYPE')
            @addtnField5LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD5LABEL')
            @addtnField5LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD5LOOKUP')
            
            @addtnField6TypeFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD6INPUTTYPE')
            @addtnField6LabelFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD6LABEL')
            @addtnField6LookupFacet = $currentProduct.getFacet('ADDITIONALCAPTUREFIELD6LOOKUP')
            
            if @showRider
                @builtInRiderArray = getBuiltInRiderList($currentProduct, @policy)
                if @policy.quotationRefGuid.to_s == ""
                    loadRiderProducts(@policy, $currentProduct, true)
                else
                    loadRiderProducts(@policy, $currentProduct, false)
                end
            end
            @riderCount = @policy.getBuiltInRiders.size
        end
    end
    ##################################################################################################


    #Method to save & validate Plan/ Coverage Details Tab
    def submitPlanDetails(policy)
        baseProduct = policy.getBaseProduct
        
        if $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES"
            policy.PolicyProductList.each do |policyProduct|
                if policyProduct.selected.to_s != "YES" && policyProduct.productTypeCd == "RIDER" && policyProduct.builtInRiderFl != "YES"
                    policyProduct.removed = "YES" 
                end
            end
        end
        policy.PolicyProductList.each do |policyProduct|
            if policyProduct.productTypeCd == "PLAN"
                if policyProduct.topUpAllocSameAsPremAllocFl.to_s == "on"
                    policyProduct.topUpAllocSameAsPremAllocFl = "YES"
                else
                    policyProduct.topUpAllocSameAsPremAllocFl = nil
                end
            elsif policyProduct.productTypeCd == "RIDER"
                if $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES" && policyProduct.builtInRiderFl != 'YES'
                    policyProduct.selected = "" unless policyProduct.selected
                    if policyProduct.selected.to_s != "YES"
                        policyProduct.removed = "YES"
                        next
                    end
                end
                riderProduct = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                if riderProduct
                    policyProduct.productId = riderProduct.productId
                    policyProduct.productVersion = riderProduct.productVersion
                    policyProduct.productFamilyCd = riderProduct.productFamilyId
                end
                policyProduct.PolicyProductInsuredList.each do |policyProductInsured|
                    if policyProductInsured.roleCd != "SUPPLEMENTARY"
                        policyPartyRole = policy.getPolicyPartyRole(policyProductInsured.roleCd)
                        if policyPartyRole != nil
                            policyProductInsured.insuredPartyRefGuid = policyPartyRole.refGuid
                        else
                            policyProductInsured.insuredPartyRefGuid = ""
                        end
                    end
                end
            end
        end
    end
    ####################################################################################


    #Method to calculate Premium based on Base Plan selected
    def ajaxCalculatePremium 
        policy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        policy.persistAll

        policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => policy.object})
        if policy.getParty("PRIMARY") != nil && policy.getParty("PROPOSER") != nil
            baseProduct = policy.getBaseProduct
            # set policy product sort order
            listPolicyProduct = Array.new
            riderAsscFacet = $currentProduct.getRiderAssociationFacet()
            policy.PolicyProductList.each do |policyProduct|
                if policyProduct.productTypeCd == "RIDER"
                    riderAssc = $currentProduct.getRiderAssociationDO(nil,baseProduct.productPlanOptionCd,policyProduct.productPlanOptionCd, riderAsscFacet, policyProduct.productSeq, policyProduct.partyRoleCd)
                    policyProduct.sortOrder = riderAssc.sortOrder if riderAssc
                else
                    policyProduct.sortOrder = 0
                end
                listPolicyProduct.push policyProduct
            end
            listPolicyProduct.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
            policy.setPolicyProductList(listPolicyProduct)

            quotation = MobiSys::PolicyBO.convertToQuotation(policy)

            quotation.QuotationProductList.each do |quotationProduct|
                party = quotation.getParty(quotationProduct)
                quotationProduct.combinedEntryAge = party.age if party and party.age.to_s !=""
            end
            $taskExceptionHash = []
            MobiSys::ProductBO.validatePolicy(quotation, policy, "", Hash.new)
            $taskExceptionHash = nil
        end
        policyProduct = policy.getBaseProduct
        if policyProduct.paymentFrequencyCd == "SINGLE"
            policyProduct.premiumPayingTerm = "1"
        end

        render :string => policyProduct.to_json
    end
    ##################################################################################################


    def getProductTerm
        formPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        formPolicy.persistAll
        existingPolicy = Policy.loadObject(:first,:conditions=>{:object=>@params['Policy']['object']})
        
        quotation = MobiSys::PolicyBO.convertToQuotation(existingPolicy)

        minMaxTermTTMS = $currentProduct.getTableTypeMappingSeq('MINMAXTERM')
        @productTerm = quotation.getBaseProduct.productTerm
        @termArray = []
        if minMaxTermTTMS
            minMaxTermFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(minMaxTermTTMS, quotation, quotation.getBaseProduct)
            if minMaxTermFacetProductDef
                if minMaxTermFacetProductDef.fixedTermValues.to_s != ""
                    fixedTermArr = minMaxTermFacetProductDef.fixedTermValues.strip.split(',')
                    @termArray = Lookupvalue.find(:all, 
                        :conditions => {
                            {
                                :name => 'KEY'
                            } =>'TERMVALUE',
                            {
                                :name => 'cd',
                                :op => 'IN'
                            } =>fixedTermArr
                        },
                        :op => 'AND'
                    )
                elsif minMaxTermFacetProductDef.minValue.to_s != "" && minMaxTermFacetProductDef.maxValue.to_s != ""
                    min = minMaxTermFacetProductDef.minValue.to_i
                    max = minMaxTermFacetProductDef.maxValue.to_i
                     @termArray = Lookupvalue.find(:all,
                        :conditions => {
                            {
                                :name => 'KEY'
                            } => 'TERMVALUE',
                            { 
                                :func=> 'CAST', 
                                :name => 'cd as INTEGER',
                                :op => '<='
                            } => max,
                            {
                                :func=> 'CAST', 
                                :name => 'cd as INTEGER',
                                :op => '>='
                            } => min
                        },
                        :op => 'AND'
                    )
                end
            end
        else
            @termArray = Lookupvalue.getValue('TERMVALUE')
        end
        @termArray.sort_by!{|lookUp| lookUp.sortOrder.to_i}
        render :action => :getProductTerm, :layout => false
    end
    ##################################################################################################


    def getPremiumPayingTerm
        formPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        formPolicy.persistAll
        existingPolicy = Policy.loadObject(:first,:conditions=>{:object=>@params['Policy']['object']})
        quotation = MobiSys::PolicyBO.convertToQuotation(existingPolicy)

        @premiumPayingTerm = quotation.getBaseProduct.premiumPayingTerm
        @ppTermArray = []

        minMaxTermPPTTMS = $currentProduct.getTableTypeMappingSeq('MINMAXPPTERM')
        if minMaxTermPPTTMS
            minMaxPPTermFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(minMaxTermPPTTMS,quotation, quotation.getBaseProduct)
            if minMaxPPTermFacetProductDef
                if minMaxPPTermFacetProductDef.fixedTermValues.to_s != ""
                    fixedTermArr = minMaxPPTermFacetProductDef.fixedTermValues.strip.split(',')
                    @ppTermArray = Lookupvalue.find(:all, 
                        :conditions => {
                            {
                                :name => 'KEY'
                            } =>'TERMVALUE',
                            {
                                :name => 'cd',
                                :op => 'IN'
                            } =>fixedTermArr
                        },
                        :op => 'AND'
                    )
                elsif minMaxPPTermFacetProductDef.minValue.to_s != "" && minMaxPPTermFacetProductDef.maxValue.to_s != ""
                    ppTermMin = minMaxPPTermFacetProductDef.minValue.to_i
                    ppTermMax = minMaxPPTermFacetProductDef.maxValue.to_i
                    @ppTermArray = Lookupvalue.find(:all,
                        :conditions => {
                            {
                                :name => 'KEY'
                            } => 'TERMVALUE',
                            { 
                                :func=> 'CAST', 
                                :name => 'cd as INTEGER',
                                :op => '<='
                            } => ppTermMax,
                            {
                                :func=> 'CAST', 
                                :name => 'cd as INTEGER',
                                :op => '>='
                            } => ppTermMin
                        },
                        :op => 'AND'
                    )
                end
                if existingPolicy.getBaseProduct.paymentFrequencyCd == "SINGLE"
                    @ppTermArray.push(Lookupvalue.new(:cd => "1", :desc => "1"))
                    existingPolicy.getBaseProduct.premiumPayingTerm = "1"
                end
            else
                $premiumPayingTerm = true
            end
        else
            @ppTermArray = Lookupvalue.getValue('TERMVALUE')
        end

        @ppTermArray.sort_by!{|lookUp| lookUp.sortOrder.to_i}
        render :action => :getPremiumPayingTerm, :layout => false
    end
    ##################################################################################################


    def prePopulateFunds(policy=nil, baseProduct=nil)
        ajaxCall = false
        if !policy
            ajaxCall = true
            MobiSys::BrowserHelper.convertToObject('Policy', @params['form']['Policy']).persistAll
            policy = Policy.loadObject(:first,:conditions=>{:object=>@params['form']['Policy']['object']})
            baseProduct = policy.getBaseProduct
            @gridID = @params['gridID']
            @columns = @params['columns'].split(',')
        end

        if baseProduct.portfolioModelCd.to_s != ""
            model = Model.loadObject(:first,
                    :conditions =>{
                    {
                        :name => 'modelCd'
                    } => baseProduct.portfolioModelCd
                }
            )
        end
        if model
            fundArray = model.getModelFunds.map {|x| x.fundCd.to_s}

            fundList = Fund.find(
                :all,
                :conditions =>{
                    {
                        :name => 'fundCd',
                        :op => 'IN' 
                    } => fundArray
                }
            )
        else
            fundList = []
        end

        selectedFundCdList = baseProduct.PolicyProductInvestmentFundList.map{|x| x.fundCd.to_s}
        fundList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
        fundCdList = fundList.map {|x| x.fundCd.to_s}
        fundList.each do |fund|
            unless selectedFundCdList.include?(fund.fundCd.to_s)
                policyProductInvestmentFund = PolicyProductInvestmentFund.new
                policyProductInvestmentFund.fundCd = fund.fundCd
                policyProductInvestmentFund.expiryDt = fund.expiryDt
                policyProductInvestmentFund.fundTypeCd = fund.fundTypeCd
                policyProductInvestmentFund.maturityDt = fund.maturityDt
                policyProductInvestmentFund.sortOrder = fund.sortOrder
                policyProductInvestmentFund.removed = "YES"
                baseProduct.addPolicyProductInvestmentFund(policyProductInvestmentFund)
            end
        end

        baseProduct.PolicyProductInvestmentFundList.delete_if do |policyProductInvestmentFund|
            unless fundCdList.include?(policyProductInvestmentFund.fundCd.to_s)
                existingFund = PolicyProductInvestmentFund.loadObject(
                    :first,
                    :loadChild => false,
                    :conditions => {
                        :object=>policyProductInvestmentFund.object
                    }
                )
                existingFund.destroy if existingFund
                true
            end
        end
        #Sort based on fundList sortorder
        sortedList = baseProduct.PolicyProductInvestmentFundList.sort_by{|x| fundCdList.index x.fundCd} 
        baseProduct.setPolicyProductInvestmentFundList(sortedList)
        if ajaxCall
            @baseProduct = baseProduct
            html = ""
            html << render(:partial => 'prePopulateFunds_Jazz')
            return html
        end
    end
    ##################################################################################################


    def addRider
        policyObject = @params['policyObject']
        @riderObjects = @params['riderObjects']
        @policy = Policy.loadObject(:first,:conditions => {:object => policyObject})

        @rider = PolicyProduct.new(
            :productTypeCd => 'RIDER',
            :modalPremium => 0.0,
            :baseAnnualPremium => 0.0,
            :baseSumAssured => 0.0,
            :productTerm => 0,
            :premiumPayingTerm => 0,
            :coi => 0.0,
            :productFamilyCd => "",
            :productId => "",
            :productVersion => ""
        )

        @policy.addPolicyProduct(@rider)
        
        @policyProductInsured = PolicyProductInsured.new
        @rider.addPolicyProductInsured(@policyProductInsured)
        
        @premiumSAFlriders = {@rider.productSeq.to_s => ""}
        @newRiderFields = {@rider.productSeq.to_s => ""}

        @riderObjects = @riderObjects.to_i + 1  

        html = ""
        html << render(:partial => 'addRiderDetails_Jazz')
        return html
    end
    ##################################################################################################


    def refreshRiderSection
        @riderObjects = @params['riderCount']
        riderObject = @params['riderObject']
        @policy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        @policy.persistAll  
        @policy = Policy.loadObject(:first,:conditions=>{:object=>@params['Policy']['object']})
        @product = $currentProduct
        loadRiderProducts(@policy, @product)
        @newriders.each do |rider|
            if rider.object == riderObject
                @rider = rider
                @rider.modalPremium = 0.0
                @rider.baseAnnualPremium = 0.0
                @rider.baseSumAssured = 0.0
                @rider.productTerm = 0
                @rider.premiumPayingTerm = 0
                @rider.coi = 0.0
                @rider.partyRoleCd = ""
                @rider.insuredPartyRefGuid = ""
                @rider.productPlanOptionCd = ""
                break
            end   
        end
        html = ""
        html << render(:partial => 'addRiderDetails_Jazz')
        return html
    end
    ##########################################################################################


    def populateRider
        @policy = MobiSys::BrowserHelper.convertToObjectWithMerge('Policy', @params['Policy'])
        accordionKey = @params['accordionKey']
        @riders = $displayRidersHM[accordionKey].values

        @riderLabelObject = PolicyProduct.new(:removed=>"YES",:builtInRiderFl => "NO") 
        riderExtraLabelObject = PolicyProductExtra.new(:removed=>"YES")
        @riderHeader = @riders[0].insuredNames.to_s.force_encoding('UTF-8') if @riders[0]
        @riderObjects = @params['riderInitialCount'].to_i

        @riderLoadingHash = {}
        @riders.each do |qp|
            @riderLoadingHash[qp.object] = $displayRidersHM["#{accordionKey}|#{qp.object}"]
        end
        @riders.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        html = ""
        html << render(:partial => 'autoPopulateRider_Jazz', :locals => {:riders => @riders, :riderLabelObject => @riderLabelObject, :riderExtraLabelObject => riderExtraLabelObject, :riderObjects => @riderObjects, :riderHeader => @riderHeader})
        html << MobiSys::BrowserHelper.attachMaskAll(true)
        return html
    end

    ##########################################################################################


    def loadRiderProducts(policy, product = nil, validateRider=true)
        #if rider auto population not required then just get the saved non built in riders and display on screen.
        @riderAutoPopulationReqFlag =  $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')
        @policyProductExtraLabelObject = PolicyProductExtra.new(:removed=>"YES")

        if @riderAutoPopulationReqFlag != "YES" 
            @newriders = []
            @newRiderFields = {}
            @premiumSAFlriders = {}
            @planLookups = {}
            nonBuiltInRiders = policy.getNonBuiltInRiders
            nonBuiltInRiders.each do | nonBuiltInRider|
                #mark existing as selected as only these would be considered and this is not a persisted value.
                #riderProduct.setIsObjectSelected(MasterDataConstants.BOOLEAN.YES);
                if nonBuiltInRider.productSeq and nonBuiltInRider.productSeq != ""
                    planLookupArr = []
                    riderProduct = MobiSys::ProductUtil.getProduct(nonBuiltInRider.productSeq)
        
                    # baseProduct = MobiSys::ProductUtil.getProduct(policy.getBaseProduct.productSeq)

                    riderPlanOptionArray = []
                    riderAssocFacet = $currentProduct.getFacet('RIDERASSOCIATION')
                    if riderAssocFacet != nil
                        riderAssocFacet.OfflineRiderAssociationList.each do |offlineRider|
                            if offlineRider.productSeq == riderProduct.id && offlineRider.builtInRiderFl != 'YES' && (offlineRider.basePlanOptionCd == policy.getBaseProduct.productPlanOptionCd || offlineRider.basePlanOptionCd.to_s == "")
                                riderPlanOptionArray.push(offlineRider.planOptionCd.to_s)
                            end
                        end
                    end
                    nonBuiltInRider.productId = riderProduct.productId
                    planOptionFacet = riderProduct.getFacet('PLANOPTION')
                    if planOptionFacet != nil
                        planOptionFacet.OfflinePlanOptionList.each do |offlinePlan|
                            if riderPlanOptionArray.include?(offlinePlan.optionCd) || riderPlanOptionArray.include?("")
                                planLookup = Lookupvalue.new
                                planLookup.cd = offlinePlan.optionCd
                                planLookup.desc = offlinePlan.description
                                planLookupArr.push(planLookup)
                            end
                        end
                    end
                    planLookupArr.sort!{|x,y| x.desc<=>y.desc}
                    @planLookups.push(planLookupArr)
                    if riderProduct.getPremiumDetailsFacet != nil && riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList != nil &&
                      riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0] != nil && riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement != nil
                      @newRiderFields[nonBuiltInRider.productSeq.to_i] = riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement
                    end
                end
                @newriders.push(nonBuiltInRider)
            end
        else #below logic is for auto population of riders
            @riderLabelObject = PolicyProduct.new(:removed=>"YES") 
            @disableRiderCheckox = {}
            $displayRidersHM = {}
            @displayRiderLifeHeader = {}
            @ridersReadOnlyFields = {}
            ridersHM = {}
            facetRADO = $currentProduct.getFacet('RIDERASSOCIATION')
            if facetRADO != nil
                basePlan = policy.getBaseProduct
                primaryPartyDO = policy.getParty('PRIMARY')
                basePlan.combinedEntryAge = primaryPartyDO.age.to_i if primaryPartyDO != nil

                basePlan.product = $currentProduct
                #fetching all rider associated with the base product
                offlineRiderAssociationList = facetRADO.OfflineRiderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
                #segregating all rider based on specified applicable roles, if applicable role is not defined in association than it means it is applicable for all roles
                riderAssociationListAsPerRoles = {}
                offlineRiderAssociationList.each do|riderAsso|
                    if riderAsso.applicableRoles.to_s != ''
                        riderAsso.applicableRoles.split(',').each do |role|
                            if riderAssociationListAsPerRoles[role] == nil
                                riderAssociationListAsPerRoles[role] = []
                                riderAssociationListAsPerRoles[role].push riderAsso
                            else
                                riderAssociationListAsPerRoles[role].push riderAsso
                            end
                        end
                    else
                        policy.getPartyRoleCds.each do |role|
                            if riderAssociationListAsPerRoles[role] == nil
                                riderAssociationListAsPerRoles[role] = []
                                riderAssociationListAsPerRoles[role].push riderAsso
                            else
                                riderAssociationListAsPerRoles[role].push riderAsso
                            end
                        end
                    end
                end

                # creating hash of existing riders with unique key
                existingPolicyProducts = {}
                policy.PolicyProductList.each do |qp|
                    if qp.productTypeCd.to_s == 'RIDER'
                        existingPolicyProducts["#{qp.insuredPartyRefGuid}|#{qp.productSeq}"] = qp
                    end
                end
                policyPartyRoles = policy.PolicyPartyRoleList
                policyPartyRoles.each do |ppr|
                    party = policy.getPartyByGuid(ppr.refGuid)
                    riderAssociationList = riderAssociationListAsPerRoles[ppr.roleCd]
                    if riderAssociationList
                        riderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
                        riderAssociationList.each do |offlineRiderAssociation|
                            #Do not consider built in riders at all..
                            if offlineRiderAssociation.builtInRiderFl == 'YES'
                                next
                            end
                            # only consider those rider association whose base plan option match.
                            #if basePlan.basePlanOptionCd  && offlineRiderAssociation.basePlanOptionCd  && !basePlan.basePlanOptionCd == offlineRiderAssociation.getBasePlanOptionCd
                            if basePlan.productPlanOptionCd  && offlineRiderAssociation.basePlanOptionCd && basePlan.productPlanOptionCd != offlineRiderAssociation.basePlanOptionCd
                                next
                            end
                            
                            if offlineRiderAssociation.associationRelationTTmapSeq != nil
                                #if dependentRiderRoleCd is defined in association and DT then pasing all the qp's in quotation list otherwise qp's of corresponding party
                                if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''
                                    ogPolicyProductList = policy.PolicyProductList
                                    tempPolicyProductList = []
                                    tempPolicyProductList.push basePlan
                                    tempPolicyProductList.push policy.getRidersByParty(party.guid)
                                    policy.setPolicyProductList(tempPolicyProductList.flatten)
                                end
                                quotation = MobiSys::PolicyBO.convertToQuotation(policy)
                                quotationParty = quotation.QuotationPartyList.select{|qp| qp.guid == party.guid && qp.roleCd == ppr.roleCd}.first
                                defTableDO = MobiSys::ProductBO.getProductDefinitionTable(offlineRiderAssociation.associationRelationTTmapSeq, quotation, basePlan, quotationParty)
                                policy.setPolicyProductList(ogPolicyProductList) if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''

                                #if dt matched then based on the association relation mark as mandatory, auto selected
                                if defTableDO != nil
                                    autoPopulateRider(policy, ridersHM, existingPolicyProducts, offlineRiderAssociation, defTableDO, party)
                                else
                                    listDefinitionTable = MobiSys::ProductUtil.loadProductDefinitionTableListByTableTypeMappingSeq(offlineRiderAssociation.associationRelationTTmapSeq, false)
                                    if listDefinitionTable != nil
                                        #if even one record is found defined as optional .. it implies that rider is optional only under certain conditions..
                                        #else by default consider it as optional.//User would not define all possible combinations for rider to be optional .. if it is always optional.
                                        isByDefaultOptional = true
                                        listDefinitionTable.each do |defnTableDOInList|
                                            if defnTableDOInList.associationRelationCd == "OPTIONAL" || defnTableDOInList.associationRelationCd == "OPTIONALDEFAULT"
                                                isByDefaultOptional = false
                                                break
                                            end
                                        end
                                        if isByDefaultOptional
                                            autoPopulateRider(policy, ridersHM, existingPolicyProducts, offlineRiderAssociation, defTableDO, party)
                                        end
                                    end
                                end
                            else
                                autoPopulateRider(policy, ridersHM, existingPolicyProducts, offlineRiderAssociation, nil, party)
                            end
                        end
                    end
                end

                # evaluating  currency cd for validation 
                currencyCode = basePlan.currencyCd

                lookupValueOfCurrencyMaster = Lookupvalue.find(:first, :conditions =>  {
                        {
                            :name => 'key',
                        } => 'CURRENCYMASTER',
                        {
                            :name => 'cd',
                        } => currencyCode
                    },
                    :op => 'AND'
                )

                $currencyFormat = nil
                if lookupValueOfCurrencyMaster != nil
                    if lookupValueOfCurrencyMaster.additionalField1 != nil
                        $currencyFormat = lookupValueOfCurrencyMaster.additionalField1
                    end
                end
                
                if $currencyFormat == nil
                    $currencyFormat = $rhoconfig[:number_format_pattern].to_s
                end
            end
            msg = ""
            errors = Hash.new
            $taskExceptionHash = []
            @riderLoadingHash = {}
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            ridersHM.each do |key, rider|
                product = MobiSys::ProductUtil.getProduct(rider.productSeq)
                if rider.selected.to_s == 'YES' 
                    rider.removed = ''
                else
                    rider.removed = 'YES'
                end
                if validateRider && rider.selected.to_s == 'YES' 
                    MobiSys::ProductBO.validatePolicy(quotation, policy, msg, errors, rider)
                end
                extraFacet = product.getFacetValue('PRODUCTEXTRAREQUIRED').to_s == 'YES'
                if extraFacet && rider.selected.to_s == 'YES' 
                    riderExtras, rider = MobiSys::PolicyBO.computeProductExtra(policy, rider)
                else
                    riderExtras = nil
                end

                @riderLoadingHash[rider.object] = riderExtras
                if (quotation.proposerLASame == 'COPYFROMINSURED' || quotation.proposerLASame == 'YES') && (rider.partyRoleCd == 'PRIMARY' || rider.partyRoleCd == 'PROPOSER')
                    lifeBasedKey = 'SAMEAS'
                else
                    lifeBasedKey = key.split('|')[0]
                end
                loadingKey = "#{lifeBasedKey}|#{rider.object}"
                if $displayRidersHM.has_key?(lifeBasedKey) && $displayRidersHM[lifeBasedKey].to_s != ''
                    $displayRidersHM[lifeBasedKey][rider.productSeq.to_s] = rider
                    $displayRidersHM[loadingKey] = riderExtras
                else
                    $displayRidersHM[lifeBasedKey] = Hash.new
                    $displayRidersHM[lifeBasedKey][rider.productSeq.to_s] = rider
                    $displayRidersHM[loadingKey] = riderExtras
                    @displayRiderLifeHeader[lifeBasedKey] = rider.insuredNames
                end
            end
            if validateRider
                db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                db.start_transaction
                $taskExceptionHash.each do |taskException|
                    taskException.persistAll
                end
                db.commit
                $taskExceptionHash = nil
            end
        end
    end
    ##########################################################################################


    def autoPopulateRider(policy, displayRidersHM, existingPolicyProducts, riderAssociationDO, defTableDO, party)
        # unselectedRiders old format partyguid1|r1,partyguid1|r2,partyguid1|r3,partyguid2|r1,partyguid2|r2
        # unselectedRiders new format partyguid1:r1,r2,r3|partyguid2:r1,r2

        # unselectedRidersArray = policy.unselectedRiders.to_s.split(',') 
        # converting old format to new format for backward compatibility
        if policy.unselectedRiders.to_s != "" && !policy.unselectedRiders.include?(":")
            unselectedRidersHM = {}
            policy.unselectedRiders.split(",").each do |unselectedRider|
                partyGuid = unselectedRider.split("|")[0]
                if unselectedRidersHM.has_key?(partyGuid)
                    unselectedRidersHM[partyGuid] = unselectedRidersHM[partyGuid] + "," + unselectedRider.split("|")[1]
                else
                    unselectedRidersHM[partyGuid] = unselectedRider.split("|")[1]
                end
            end
            tempUnselectedRiders = ""
            unselectedRidersHM.map{|k,v| tempUnselectedRiders << "#{k}:#{v}|"}
            policy.unselectedRiders = tempUnselectedRiders
        end

        unselectedRidersArray = []
        # unselectedRidersArray = policy.unselectedRiders.to_s.split("|").select{|a| a if a.include?(party.guid)}[0].split(":")[1] if policy.unselectedRiders.to_s != ""
        if policy.unselectedRiders.to_s != ""  
            tempArray = policy.unselectedRiders.to_s.split("|").select{|a| a if a.include?(party.guid)} 
            unselectedRidersArray = tempArray[0].split(":")[1]   if !tempArray.empty?
        end
        riderKeyId = party.guid.to_s+'|'+riderAssociationDO.productSeq.to_s 
        # if insured is same as proposer then do not add same rider again in hash just skip it, also check planoption, if rider with new planoption comes then it is a new rider not the existing rider.. uniqueness of rider within life is defined with productseq and planoption
        insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
        if insuredPartyRole
            partySameAsFlag = (insuredPartyRole.partySameAsCd.to_s == 'PROPOSER') && (party.roleCd == 'PRIMARY' || party.roleCd == 'PROPOSER')
        else
            partySameAsFlag = false
        end
        riderExistFlag = false
        if partySameAsFlag
            insuredRider = displayRidersHM[insuredPartyRole.refGuid.to_s+'|'+riderAssociationDO.productSeq.to_s]
            if insuredRider
                if insuredRider.productSeq.to_s == riderAssociationDO.productSeq.to_s
                    if riderAssociationDO.planOptionCd.to_s == ''
                        riderExistFlag = true
                    elsif insuredRider.applicablePlanOptions.include? riderAssociationDO.planOptionCd.to_s
                        riderExistFlag = true
                    end
                end 
            end
        end
        return if partySameAsFlag && riderExistFlag

        if existingPolicyProducts.has_key?(riderKeyId)
            if displayRidersHM[riderKeyId] == nil
                displayRidersHM[riderKeyId] = existingPolicyProducts[riderKeyId]
                # resetting applicablePlanOptions on first load and then populating it subsequently
                displayRidersHM[riderKeyId].applicablePlanOptions = ''
            else
                displayRidersHM[riderKeyId] = existingPolicyProducts[riderKeyId]
            end
            if party.firstName1.to_s == '' && party.lastName1.to_s == ''
                displayRidersHM[riderKeyId].insuredNames = getLabelValue(party.roleCd.to_s)
            else
                if party.titleCd.to_s == "OTHER"
                   displayRidersHM[riderKeyId].insuredNames= party.otherTitle.to_s+ " " + party.firstName1.to_s + " " + party.lastName1.to_s
                else
                    displayRidersHM[riderKeyId].insuredNames = getLabelValue(party.titleCd.to_s) + " " + party.firstName1.to_s + " " + party.lastName1.to_s
                end
            end
        elsif displayRidersHM[riderKeyId] == nil 
            displayRidersHM[riderKeyId] = addBlankRider(policy, party, riderAssociationDO)
        end
        displayRidersHM[riderKeyId].impactedFields = riderAssociationDO.impactedFields
        product = MobiSys::ProductUtil.getProduct(displayRidersHM[riderKeyId].productSeq)
        if product
            
            displayRidersHM[riderKeyId].productLongName = product.longName

            if defTableDO != nil
                if defTableDO.associationRelationCd == 'MANDATORY'
                    displayRidersHM[riderKeyId].selected = "YES"
                    displayRidersHM[riderKeyId].riderDisableField = "YES"
                elsif defTableDO.associationRelationCd == 'OPTIONALDEFAULT'
                    # if optional default rider was unchecked on form than do not default it to selected. User selection should overwrite the existing behaviour.
                    unless unselectedRidersArray.include? riderKeyId.split("|")[1]
                        displayRidersHM[riderKeyId].selected = "YES" 
                    end

                    displayRidersHM[riderKeyId].riderDisableField = "NO"
                elsif defTableDO.associationRelationCd == 'OPTIONAL'
                    displayRidersHM[riderKeyId].riderDisableField = "NO"
                    #do not mark as selected as optional select for User.
                    #Need to reset back the mandatory to NO.. as it could have been mandatory earlier.. but due to new set of conditions on refresh is now no longer mandatory
                    # displayRidersHM[riderKeyId].setMandatoryCheckFl(MasterDataConstants.BOOLEAN.NO);
                end
            else
                displayRidersHM[riderKeyId].riderDisableField = "NO"
            end
            if product.getPremiumDetailsFacet
                offlinePremiumDetail = product.getPremiumDetailsFacet.OfflinePremiumDetailsList[0]
                if offlinePremiumDetail
                    if displayRidersHM[riderKeyId].selected.to_s == 'YES'
                        displayRidersHM[riderKeyId].readOnlyFields = riderAssociationDO.inputDataElement.to_s != '' ? riderAssociationDO.inputDataElement : offlinePremiumDetail.inputDataElement 
                        displayRidersHM[riderKeyId].premiumSAFl = offlinePremiumDetail.premiumSAFl
                    else
                        displayRidersHM[riderKeyId].readOnlyFields = ''
                        displayRidersHM[riderKeyId].premiumSAFl = ''
                    end
                end
            end
            planOptions = nil
            if riderAssociationDO.planOptionCd.to_s != ""
                planOptions = OfflinePlanOption.find(:all, :conditions=>{:optionCd => riderAssociationDO.planOptionCd})
            else
                planOptionFacet = product.getFacet('PLANOPTION')
                planOptions = planOptionFacet.OfflinePlanOptionList if planOptionFacet != nil
            end
            if planOptions
                planOptions.each do |planOption|
                    if displayRidersHM[riderKeyId].applicablePlanOptions.to_s == ''
                        displayRidersHM[riderKeyId].applicablePlanOptions = "|#{getLabelValue('select')},#{planOption.optionCd}|#{getLabelValue(planOption.description)}"
                    else
                        displayRidersHM[riderKeyId].applicablePlanOptions = "#{displayRidersHM[riderKeyId].applicablePlanOptions.to_s},#{planOption.optionCd}|#{getLabelValue(planOption.description)}"
                    end
                end
            end
        end
    end
    ##########################################################################################


    def addBlankRider(policy, party, riderAssociation = nil)
        rider = PolicyProduct.new(:productTypeCd => 'RIDER', :builtInRiderFl => 'NO', :coi=>0.0, :insuredPartyRefGuid => party.guid)
        if riderAssociation != nil
            riderProduct = MobiSys::ProductUtil.getProduct(riderAssociation.productSeq)
            rider.productSeq = riderAssociation.productSeq
            rider.productId = riderAssociation.productId
            rider.productPlanOptionCd = riderAssociation.planOptionCd
            rider.linkedFl = riderAssociation.linkedFl
            rider.productFamilyCd = riderProduct.productFamilyId
            rider.productVersion = riderProduct.productVersion
            rider.guid = rider.uniqueKey
            rider.selected = 'NO'
            rider.combinedEntryAge = party.age
            
            if party.titleCd.to_s == "OTHER"
                rider.insuredNames = party.otherTitle.to_s + " " + party.firstName1.to_s + " " + party.lastName1.to_s
            else
                rider.insuredNames = getLabelValue(party.titleCd.to_s) + " " + party.firstName1.to_s + " " + party.lastName1.to_s
            end
            rider.partyRoleCd = party.roleCd
        end
        
        policy.addPolicyProduct(rider)
        return rider
    end
    ####################################################################################


    #Method to load BeneficiaryAppointee Details Tab
    def getBeneficiaryAppointee
        @nomineeLifeCount = 50
        @beneficiaries = Array.new

        majorAgeFacet = $rhoconfig[:majorAge]
        @ageFacet = majorAgeFacet.actionValue if majorAgeFacet

        minorFl = false
        
        @beneficiaryPartyRoles = @policy.getPolicyPartyRoleList("NOMINEE")
        @beneficiaryPartyRoles.each do |partyRole|
            party = @policy.getPartyByGuid(partyRole.refGuid)
            if (party && party.roleCd.to_s != "NOMINEE") || party == nil
                party = Party.new(:roleCd => "NOMINEE", :partyTypeCd => "INDIVIDUAL")
                @policy.addParty(party)
            end
            partyRole.nomineeRefGuid = party.uniqueKey

            #converting db date to screen date
            party.birthDt = getScreenDate(party.birthDt) if party.birthDt.to_s != ""
            @beneficiaries.push(party)

            minorFl = true if @ageFacet && party.age.to_i < @ageFacet.to_i
        end

        @selectedPartyRoles = []
        @policy.PolicyPartyRoleList.each do |policyPartyRole|
            if policyPartyRole.roleCd != 'NOMINEE' && policyPartyRole.roleCd != 'APPOINTEE'
                @selectedPartyRoles.push(policyPartyRole.roleCd)
            end  
        end
        @selectedPartyRoles = @selectedPartyRoles.map{|s| "'#{s}'"}.uniq.join(',')
        
        classname = "PolicyNomineeDO"
        @renderPolicyNomineeNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPolicyNomineeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyNomineeHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyNomineeOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPolicyNomineePermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPolicyNomineeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyNomineeHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyNomineeOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyNomineeMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyNomineeEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')


        # Appointee initialization
        @appointeeParty = @policy.getParty("APPOINTEE")
        if @appointeeParty
            @appointeePolicyPartyRole = @policy.getPolicyPartyRole("APPOINTEE")
        else
            @appointeeParty = Party.new(:roleCd => "APPOINTEE", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@appointeeParty)
            @appointeePolicyPartyRole = PolicyPartyRole.new(:roleCd => "APPOINTEE", :refGuid => @appointeeParty.uniqueKey)
            @policy.addPolicyPartyRole(@appointeePolicyPartyRole)
        end

        #converting db date to screen date
        @appointeeParty.birthDt = getScreenDate( @appointeeParty.birthDt) if @appointeeParty.birthDt.to_s != ""
        unless minorFl
            @appointeeParty.removed = "YES" 
            @appointeePolicyPartyRole.removed = "YES"
        end

        classname = "PolicyAppointeeDO"
        @renderPolicyAppointeeNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPolicyAppointeeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyAppointeeHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyAppointeeOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPolicyAppointeePermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPolicyAppointeeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyAppointeeHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyAppointeeOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyAppointeeMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyAppointeeEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        @nomineeNavbarIds,@nomineeNavbarLabels = getNavbarDetails('tab_nominee',$currentProduct)
    end
    ##################################################################################################


    #Method to dynamically create/ load Beneficiary/ Nominee data
    def addBeneficiary
        @nomineeLifeCount = @params['nomineeLifeCount'].to_i + 1
        @displayCount = @params['displayCount'].to_i + 1
        @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>@params['policyObject']})
        @nomineeParty = Party.new(:roleCd => "NOMINEE", :partyTypeCd => "INDIVIDUAL")
        @policy.addParty(@nomineeParty)
        @policyPartyRole = PolicyPartyRole.new(:roleCd => "NOMINEE")
        @policyPartyRole.nomineeRefGuid = @nomineeParty.uniqueKey
        @policy.addPolicyPartyRole(@policyPartyRole)

        classname = "PolicyNomineeDO"
        @renderPolicyNomineeNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPolicyNomineeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyNomineeHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyNomineeOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPolicyNomineePermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPolicyNomineeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyNomineeHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyNomineeOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyNomineeMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyNomineeEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        html = ""
        html <<  render(:partial => 'addBeneficiary_Jazz')
        return html
    end
    ##################################################################################################


    #Method to save & validate Beneficiary & Appointee Details Tab
    def submitBeneficiaryAppointeeDetails(policy)
        navbar = @params['currentNavTab'].to_s.split('-')[1]
        if navbar == 'nomineeDetails'
            majorAgeFacet = $rhoconfig[:majorAge]
            ageFacet = majorAgeFacet.actionValue if majorAgeFacet
            minorFl = false
            nominee = Array.new
            policy.PolicyPartyRoleList.each do|policyPartyRole|
                next if policyPartyRole.roleCd.to_s != "NOMINEE"
                if policyPartyRole.partySameAsCd.to_s == "" || policyPartyRole.partySameAsCd.to_s == "OTHER"
                    party = policy.getPartyByGuid(policyPartyRole.refGuid)
                    party.birthDt = getDBDate(party.birthDt) if party && party.birthDt.to_s != ""
                    policyPartyRole.refGuid = policyPartyRole.nomineeRefGuid

                    minorFl = true if party && party.removed != "YES" && ageFacet && party.age.to_i < ageFacet.to_i
                elsif policyPartyRole.partySameAsCd.to_s != "SUPPLEMENTARY"
                    refParty = Party.loadObject(
                        :first, 
                        :loadChild => false,
                        :conditions => {
                            { :name => 'roleCd' } => policyPartyRole.partySameAsCd,
                            { :name => 'parentKey' } => policy.object,
                            :op => 'AND'
                        }
                    )
                    if refParty
                        party = policy.getPartyByGuid(policyPartyRole.nomineeRefGuid)
                        party.removed = "YES" if party
                        policyPartyRole.refGuid = refParty.guid

                        minorFl = true if ageFacet && refParty.age.to_i < ageFacet.to_i 
                    end
                else
                    party = policy.getPartyByGuid(policyPartyRole.nomineeRefGuid)
                    party.removed = "YES" if party

                    refParty = Party.loadObject(
                        :first, 
                        :loadChild => false,
                        :conditions => {
                            { :name => 'guid' } => policyPartyRole.refGuid,
                            { :name => 'parentKey' } => policy.object,
                            :op => 'AND'
                        }
                    )

                    minorFl = true if ageFacet && refParty && refParty.age.to_i < ageFacet.to_i
                end
                policyPartyRole.effectiveFromDt = getScreenDate(policyPartyRole.effectiveFromDt) if policyPartyRole.effectiveFromDt.to_s != ""
                policyPartyRole.effectiveToDt = getScreenDate(policyPartyRole.effectiveToDt) if policyPartyRole.effectiveToDt.to_s != ""
                if policyPartyRole.removed != "YES" && policyPartyRole.roleCd == "NOMINEE"
                    nominee << policyPartyRole
                end
            end
            if  nominee.size() == 1
                if (nominee[0].percentage.to_s == "")
                nominee[0].percentage = 100
                end
                if (nominee[0].nomineeTypeCd.to_s == "")
                nominee[0].nomineeTypeCd = "PRIMARY"
                end
            end

            unless minorFl
                appointee = policy.getParty("APPOINTEE")
                appointee.removed = "YES" if appointee

                appointeePolicyPartyRole = policy.getPolicyPartyRole("APPOINTEE")
                appointeePolicyPartyRole.removed = "YES" if appointeePolicyPartyRole
            end
        end
    end
    ##################################################################################################


    #Method to load Payment Details Tab
    def getPaymentDetails
        @paymentNavbarIds,@paymentNavbarLabels = getNavbarDetails('tab_payment')
        navbar = @params['sym_navbar'].to_s.split('-')[1]
        if @policy.getParty("PROPOSER")
            @proposerExists = true
        else
            party = Party.new(:roleCd => "PROPOSER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(party)
            policyPartyRole = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => party.uniqueKey)
            @policy.addPolicyPartyRole(policyPartyRole)
            @policy.persistAll
            @proposerExists = true
        end
        if navbar == nil || navbar == 'initialPaymentContainer' 
            getInitialPayment()
        elsif navbar == 'renewalPaymentContainer'
            getRenewalPayment()
        elsif navbar == 'refundPaymentContainer'
            getRefundPayment()
        end
        @parties = @policy.PartyList.collect{|party| party.roleCd party.roleCd != 'PAYER'}
        @parties << 'AGENT'
    end
    ##################################################################################################

    def getInitialPayment
        # #Initial Payment Code
        @inward = @policy.getInward(@policy.proposalNum, "APPLICATION_SUSPENSE")
        @inwardDetail_form = ""
        @inwardPayer_form = ""
        if @inward == nil
            if @proposerExists
                @inward = Inward.new(:payerTypeCd => "PROPOSER", :inwardStatusCd => 'PENDING')
            else
                @inward = Inward.new
            end
            @inwardPolicy = InwardPolicy.new(:policyNum => @policy.proposalNum, :acctTypeCd => "APPLICATION_SUSPENSE")
            @inward.addInwardPolicy(@inwardPolicy)
            # @inward.persistAll
            
            @inwardPayer = Party.new(:roleCd => "PAYER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@inwardPayer)
            @inwardPartyRole = PolicyPartyRole.new(:roleCd => "PAYER", :paymentInstructionTypeCd => "INITIAL", :refGuid => @inwardPayer.uniqueKey)
            @policy.addPolicyPartyRole(@inwardPartyRole)

            inwardDetail = InwardDetails.new
            inwardDetail.inwardAmount =  @policy.getBaseProduct.modalPremium if @policy.getBaseProduct
            @inward.addInwardDetails(inwardDetail)
            @initialPaymentCount = 0
            @visibleInitialPaymentCount = 0
            setObjectCount(@inward, @initialPaymentCount)
            setObjectMapping(@inward, @inward.class.name)
        else
            @inwardPolicy = @inward.InwardPolicyList[0]
            @policy.getPolicyPartyRoleList("PAYER").each do |payerPartyRole|
                if payerPartyRole.paymentInstructionTypeCd == "INITIAL"
                    @inwardPartyRole = payerPartyRole
                end
            end
            @inwardPayer = @policy.getPayerParty("INITIAL")
            if (@inwardPayer && @inwardPayer.roleCd != "PAYER") || @inwardPayer == nil
                @inwardPayer = Party.new(:roleCd => "PAYER", :partyTypeCd => "INDIVIDUAL")
                @policy.addParty(@inwardPayer)
            end
            if @inwardPartyRole == nil
                @inwardPartyRole = PolicyPartyRole.new(:roleCd => "PAYER", :paymentInstructionTypeCd => "INITIAL", :refGuid => @inwardPayer.uniqueKey)
                @policy.addPolicyPartyRole(@inwardPartyRole)
            end
            @inwardPartyRole.refGuid = @inwardPayer.uniqueKey

            if @inward.InwardDetailsList.length > 0
                @inward.InwardDetailsList.each_with_index do |inwardDetail, index|
                    inwardDetail.inwardAmount =  @policy.getBaseProduct.modalPremium if @policy.getBaseProduct != nil && index == 0 && inwardDetail.inwardAmount.to_s == "0.0"
                    inwardDetail.instrumentDt = getScreenDate(inwardDetail.instrumentDt) if inwardDetail.instrumentDt.to_s != ""
                end
                @initialPaymentCount = @inward.InwardDetailsList.length
            else
                inwardDetail = InwardDetails.new
                @inward.addInwardDetails(inwardDetail)
                inwardDetail.inwardAmount =  @policy.getBaseProduct.modalPremium if @policy.getBaseProduct
                @initialPaymentCount = 1
            end
        end
        @inward.inwardTypeCd = 'NEWBUSINESSR'
        @inward.inwardSubTypeCd = 'BASICPREMIUM'
        @inward.inwardDt = @policy.proposalReceivedDt
        @inward.agentId = @policy.baseAgentId
        if MobiSys::BrowserHelper.renderField?('InwardDetailsDO.micrNum')
            @inward.isMicrApplicable = "YES"
        else
            @inward.isMicrApplicable = "NO"
        end
        @inward.payerPartyRefGuid = "" if @inward.payerTypeCd != "SUPPLEMENTARY"
        addPayer('INITIAL')
    end


    def getRenewalPayment
        # #Renewal Payment Code
        @renewalPayment = @policy.getPolicyPayment("RENEWALPREMIUM")
        if @renewalPayment == nil
            @renewalPayment = PolicyPayment.new(:paymentInstructionTypeCd => "RENEWALPREMIUM", :payerTypeCd => "PROPOSER")
            @policy.addPolicyPayment(@renewalPayment)
            
            @renewalPayer = Party.new(:roleCd => "PAYER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@renewalPayer)
            
            @renewalPartyRole = PolicyPartyRole.new(:roleCd => "PAYER", :paymentInstructionTypeCd => "RENEWALPREMIUM", :refGuid => @renewalPayer.uniqueKey)
            @policy.addPolicyPartyRole(@renewalPartyRole)

            @renewalFinancialAccount = PartyFinancialAccount.new
            @renewalPayment.partyFinAccRefGuid = @renewalFinancialAccount.uniqueKey
        else
            @renewalPayer = @policy.getPayerParty("RENEWALPREMIUM")
            
            @policy.getPolicyPartyRoleList("PAYER").each do |payerPartyRole|
                if payerPartyRole.paymentInstructionTypeCd == "RENEWALPREMIUM"
                    @renewalPartyRole = payerPartyRole
                end
            end

            if (@renewalPayer && @renewalPayer.roleCd != "PAYER") || @renewalPayer == nil
                @renewalPayer = Party.new(:roleCd => "PAYER", :partyTypeCd => "INDIVIDUAL")
                @policy.addParty(@renewalPayer)
            end
            @renewalPartyRole.refGuid = @renewalPayer.uniqueKey

            @renewalFinancialAccount = PartyFinancialAccount.loadObject(
                :first,
                :conditions => {
                    {:name => 'guid'} => @renewalPayment.partyFinAccRefGuid
                }
            )
            if @renewalFinancialAccount == nil
                @renewalFinancialAccount = PartyFinancialAccount.new
                @renewalPayment.partyFinAccRefGuid = @renewalFinancialAccount.uniqueKey
            end
            @renewalFinancialAccount.paymentMethodCd = @renewalPayment.paymentMethodCd
        end

        if MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.micrNum')
            @renewalFinancialAccount.isMicrApplicable = "YES"
        else
            @renewalFinancialAccount.isMicrApplicable = "NO"
        end
        @renewalPayment.payerPartyRefGuid = "" if @renewalPayment.payerTypeCd != "SUPPLEMENTARY"
        addPayer('RENEWAL')
    end


    def getRefundPayment
        @refundPayment = @policy.getPolicyPayment("REFUND")
        if @refundPayment == nil
            @refundPayer = @policy.getParty("PROPOSER")
            
            @refundFinancialAccount = PartyFinancialAccount.new
            @refundPayer.addPartyFinancialAccount(@refundFinancialAccount)
            
            @refundPayment = PolicyPayment.new(:paymentInstructionTypeCd => "REFUND", :payerTypeCd => "PROPOSER")
            
            @refundPayment.partyFinAccRefGuid = @refundFinancialAccount.uniqueKey
            @refundPayment.payerPartyRefGuid = @refundPayer.uniqueKey
            @policy.addPolicyPayment(@refundPayment)
        else
            @refundFinancialAccount = PartyFinancialAccount.loadObject(
                :first,
                :conditions => {
                    {:name => 'guid'} => @refundPayment.partyFinAccRefGuid
                }
            )
            @refundPayer = @policy.getParty("PROPOSER")
            if @refundFinancialAccount == nil
                @refundFinancialAccount = PartyFinancialAccount.new
                @refundPayment.partyFinAccRefGuid = @refundFinancialAccount.uniqueKey
                @refundPayment.payerPartyRefGuid = @refundPayer.uniqueKey
                @refundPayer.addPartyFinancialAccount(@refundFinancialAccount)
            end
            @refundFinancialAccount.paymentMethodCd = @refundPayment.paymentMethodCd
        end
        
        if MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.micrNum')
            @refundFinancialAccount.isMicrApplicable = "YES"
        else
            @refundFinancialAccount.isMicrApplicable = "NO"
        end
    end


    def addInitialPaymentMethod
        inwardObject = @params['inwardObject']
        @initialPaymentCount = @params['inwardDetailCount'].to_i + 1  
        @inward = Inward.new
        @inward.object = inwardObject
        if MobiSys::BrowserHelper.renderField?('InwardDetailsDO.micrNum')
            @inward.isMicrApplicable = "YES"
        else
            @inward.isMicrApplicable = "NO"
        end
        @inwardDetail = InwardDetails.new
        @inward.addInwardDetails(@inwardDetail)
 
        html = ''
        html << render(:partial => 'addInitialPaymentMethod_Jazz')
        return html
    end
    ##################################################################################################


    #Method to dynamically create/ load Payer data
    def addPayer(type)
        @payer = true
        if type == 'INITIAL' && @inwardPayer != nil
            addInitialPayer()
        elsif type == 'RENEWAL' && @renewalPayer != nil
            addRenewalPayer()
        end

        classname = "PolicyPayerDO"

        @renderPayerNationalityPanel = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
        @renderPayerIdentityPanel = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
        @renderPayerOccupationPanel = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
        @renderPayerAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPayerHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPayerOfficeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
        @renderPayerPermanentAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
        @renderPayerContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPayerHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPayerOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPayerMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPayerEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')
    end
    ##################################################################################################


    def addInitialPayer
        @inwardPayerHomeAddress = @inwardPayer.getPartyAddress("RESIDENTIAL", true)
        @inwardPayerBusinessAddress = @inwardPayer.getPartyAddress("OFFICE", true)
        @inwardPayerPermanentAddress = @inwardPayer.getPartyAddress("PERMANENT", true)
        
        @inwardPayerContactHome = @inwardPayer.getPartyContact("RESIDENTIAL", true)
        @inwardPayerContactOffice = @inwardPayer.getPartyContact("OFFICE", true) 
        @inwardPayerContactMobile = @inwardPayer.getPartyContact("MOBILE", true)
        
        @inwardPayerEmail = @inwardPayer.getPartyEmail(true)
        @inwardPayerEmployment = @inwardPayer.getPartyEmployment(true)
        identity_array = @inwardPayer.getPartyIdentityList(true)
        @inwardPayerIdentity1, @inwardPayerIdentity2 = identity_array[0], identity_array[1]

        #converting db date to screen date
        @inwardPayer.birthDt = getScreenDate(@inwardPayer.birthDt) if @inwardPayer.birthDt != nil || @inwardPayer.birthDt != ""
        @inwardPayerIdentity1.expiryDt = getScreenDate(@inwardPayerIdentity1.expiryDt) if @inwardPayerIdentity1.expiryDt != nil || @inwardPayerIdentity1.expiryDt != ""
        @inwardPayerIdentity1.issueDt = getScreenDate(@inwardPayerIdentity1.issueDt) if @inwardPayerIdentity1.issueDt != nil || @inwardPayerIdentity1.issueDt != ""
        @inwardPayerIdentity2.expiryDt = getScreenDate(@inwardPayerIdentity2.expiryDt) if @inwardPayerIdentity2.expiryDt != nil || @inwardPayerIdentity2.expiryDt != ""
        @inwardPayerIdentity2.issueDt = getScreenDate(@inwardPayerIdentity2.issueDt) if @inwardPayerIdentity2.issueDt != nil || @inwardPayerIdentity2.issueDt != ""
    end


    def addRenewalPayer
        @renewalPayerHomeAddress = @renewalPayer.getPartyAddress("RESIDENTIAL", true)
        @renewalPayerBusinessAddress = @renewalPayer.getPartyAddress("OFFICE", true)
        @renewalPayerPermanentAddress = @renewalPayer.getPartyAddress("PERMANENT", true)
        
        @renewalPayerContactHome = @renewalPayer.getPartyContact("RESIDENTIAL", true)
        @renewalPayerContactOffice = @renewalPayer.getPartyContact("OFFICE", true) 
        @renewalPayerContactMobile = @renewalPayer.getPartyContact("MOBILE", true)
        
        @renewalPayerEmail = @renewalPayer.getPartyEmail(true)
        @renewalPayerEmployment = @renewalPayer.getPartyEmployment(true)
        identity_array = @renewalPayer.getPartyIdentityList(true)
        @renewalPayerIdentity1, @renewalPayerIdentity2 = identity_array[0], identity_array[1]

        #converting db date to screen date
        @renewalPayer.birthDt = getScreenDate(@renewalPayer.birthDt) if @renewalPayer.birthDt != nil || @renewalPayer.birthDt != ""
        @renewalPayerIdentity1.expiryDt = getScreenDate(@renewalPayerIdentity1.expiryDt) if @renewalPayerIdentity1.expiryDt != nil || @renewalPayerIdentity1.expiryDt != ""
        @renewalPayerIdentity1.issueDt = getScreenDate(@renewalPayerIdentity1.issueDt) if @renewalPayerIdentity1.issueDt != nil || @renewalPayerIdentity1.issueDt != ""
        @renewalPayerIdentity2.expiryDt = getScreenDate(@renewalPayerIdentity2.expiryDt) if @renewalPayerIdentity2.expiryDt != nil || @renewalPayerIdentity2.expiryDt != ""
        @renewalPayerIdentity2.issueDt = getScreenDate(@renewalPayerIdentity2.issueDt) if @renewalPayerIdentity2.issueDt != nil || @renewalPayerIdentity2.issueDt != ""
    end

    #Method to save & validate Payment Details Tab
    def submitPaymentDetails(policy)
        navbar = @params['currentNavTab'].to_s.split('-')[1]
        if navbar == 'initialPaymentContainer' || navbar == 'renewalPaymentContainer'
            policy.PolicyPartyRoleList.each do |policyPartyRole|
                if navbar == 'initialPaymentContainer' && policyPartyRole.paymentInstructionTypeCd == "INITIAL"
                    @inwardPartyRole = policyPartyRole
                elsif navbar == 'renewalPaymentContainer' && policyPartyRole.paymentInstructionTypeCd == "RENEWALPREMIUM"
                    @renewalPartyRole = policyPartyRole
                end
            end

            policy.PartyList.each do |party|
                if navbar == 'initialPaymentContainer' && party.roleCd == "PAYER" && party.guid == @inwardPartyRole.refGuid
                    @inwardPayer = party    
                elsif navbar == 'renewalPaymentContainer' && party.roleCd == "PAYER" && party.guid == @renewalPartyRole.refGuid
                    @renewalPayer = party
                end
                # deleting dependent documents of payer
                container = DocumentContainer.loadObject(:first,  :conditions=>{{:name=>'policyGuid'}=> policy.guid,{:name=>'entityGuid'} =>party.guid },:op => 'AND')

                questionContainer = QuestionContainer.loadObject(:first,  :conditions=>{{:name=>'policyGuid'}=> policy.guid,{:name=>'entityGuid'} =>party.guid },:op => 'AND')

                container.delete if container && party.removed == "YES" 
                questionContainer.delete if questionContainer && party.removed == "YES" 
            end
        end

        if navbar == 'initialPaymentContainer'
            submitInitialPayment(policy)
        elsif navbar == 'renewalPaymentContainer'
            submitRenewalPayment(policy)
        end
    end
    ##################################################################################################

    def submitInitialPayment(policy)
        #Initial Payment Code
        inward = MobiSys::BrowserHelper.convertToObject('Inward', @params['Inward'])
        inward.inwardDt = Time.now

        inwardDetailExists = false
        inward.InwardDetailsList.each do |inwardDetail|
            if inwardDetail.removed == nil || inwardDetail.removed == ""
                inwardDetailExists = true
                break
            end
        end

        @gatewayFlag = false
        if inwardDetailExists
            inwardAmount = 0
            inward.InwardDetailsList.each do |inwardDetail|
                inwardAmount += inwardDetail.inwardAmount.to_s.gsub(",", "").to_f
                @gatewayFlag = true if inwardDetail.paymentMethodCd == "IPG"
            end
            inward.inwardAmount = inwardAmount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse.gsub(",", "").to_f
        end

        if inward.payerTypeCd == "PRIMARY" || inward.payerTypeCd == "JOINT" || inward.payerTypeCd == "PROPOSER"
            payerPartyRole = PolicyPartyRole.loadObject(
                :first,
                :conditions => {
                    {:name => 'parentKey'} => policy.object,
                    {:name => 'roleCd'} => inward.payerTypeCd,
                    :op => 'AND'
                }
            )
            inward.payerPartyRefGuid = payerPartyRole.refGuid
            @inwardPartyRole.partySameAsCd = inward.payerTypeCd
            @inwardPartyRole.refGuid = inward.payerPartyRefGuid
        elsif inward.payerTypeCd == "OTHER"
            #Avdhut Vaidya 16-04-2015: Code checks for empty fields in child objects and sets removed flag accordingly
            @inwardPayer.PartyAddressList.each do |address|
                if MobiSys::PolicyBO.checkForEmptyFields(address)
                    address.removed = "YES"
                elsif (@inwardPayer.copyFromAddr1 != "" && address.addressTypeCd == "RESIDENTIAL") || (@inwardPayer.copyFromAddr2 != "" && address.addressTypeCd == "PERMANENT") || (@inwardPayer.copyFromAddr3 != "" && address.addressTypeCd == "OFFICE") 
                    address.removed = "YES"
                end
            end
            @inwardPayer.PartyEmploymentList.each do |employment|
                if MobiSys::PolicyBO.checkForEmptyFields(employment)
                    employment.removed = "YES"
                else
                    employment.annualIncome = employment.annualIncome.to_s.gsub(',','').to_i
                end
            end
            @inwardPayer.PartyContactList.each do |contact|
                contact.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(contact)
            end
            @inwardPayer.PartyIdentityList.each do |identity|
                identity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(identity)
            end
            @inwardPayer.PartyEmailList.each do |email|
                email.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(email)
            end

            inward.payerPartyRefGuid = @inwardPayer.uniqueKey
            @inwardPartyRole.partySameAsCd = ""
            @inwardPartyRole.refGuid = inward.payerPartyRefGuid
            partyIdentity1 = @inwardPayer.PartyIdentityList[0]
            partyIdentity2 = @inwardPayer.PartyIdentityList[1]

            #converting screen date to db date
            @inwardPayer.birthDt = getDBDate(@inwardPayer.birthDt) if @inwardPayer && @inwardPayer.birthDt.to_s != ""
            partyIdentity1.expiryDt = getDBDate(partyIdentity1.expiryDt) if partyIdentity1 && partyIdentity1.expiryDt.to_s != ""
            partyIdentity1.issueDt = getDBDate(partyIdentity1.issueDt) if partyIdentity1 && partyIdentity1.issueDt.to_s != ""
            partyIdentity2.expiryDt = getDBDate(partyIdentity2.expiryDt) if partyIdentity2 && partyIdentity2.expiryDt.to_s != ""
            partyIdentity2.issueDt = getDBDate(partyIdentity2.issueDt) if partyIdentity2 && partyIdentity2.issueDt.to_s != ""
        else
            payerParty = Party.loadObject(
                :first,
                :loadChild => false,
                :conditions => {
                    {:name => 'parentKey'} => policy.object,
                    {:name => 'guid'} => inward.payerPartyRefGuid,
                    :op => 'AND'
                }
            )
            inward.payerPartyRefGuid = payerParty != nil ? payerParty.uniqueKey : ""
            @inwardPartyRole.partySameAsCd = inward.payerTypeCd
            @inwardPartyRole.refGuid = inward.payerPartyRefGuid    
        end
        inward.persistAll
        policy.persistAll
    end


    def submitRenewalPayment(policy)
        #Renewal Payment Code
        if @params['PartyFinancialAccount'].to_s != ""
            @renewalFinancialAccount = MobiSys::BrowserHelper.convertToObject('PartyFinancialAccount', @params['PartyFinancialAccount'])
            
            policy.PolicyPaymentList.each do |policyPayment|
                if policyPayment.paymentInstructionTypeCd == "RENEWALPREMIUM"
                    @renewalPayment = policyPayment
                    break
                end
            end

            if @renewalPayment.payerTypeCd == "PRIMARY" || @renewalPayment.payerTypeCd == "JOINT" || @renewalPayment.payerTypeCd == "PROPOSER"
                payerParty = Party.loadObject(
                    :first,
                    :loadChild => false,
                    :conditions => {
                        {:name => 'parentKey'} => policy.object,
                        {:name => 'roleCd'} => @renewalPayment.payerTypeCd,
                        :op => 'AND'
                    }
                )
                if payerParty
                    @renewalPayment.payerPartyRefGuid = payerParty.uniqueKey
                    @renewalFinancialAccount.parentKey = payerParty.object
                end
                @renewalPartyRole.partySameAsCd = @renewalPayment.payerTypeCd
                @renewalPartyRole.refGuid = @renewalPayment.payerPartyRefGuid
            elsif @renewalPayment.payerTypeCd == "OTHER"
                #Avdhut Vaidya 16-04-2015: Code checks for empty fields in child objects and sets removed flag accordingly
                @renewalPayer.PartyAddressList.each do |address|
                    if MobiSys::PolicyBO.checkForEmptyFields(address)
                        address.removed = "YES"
                    elsif (@renewalPayer.copyFromAddr1 != "" && address.addressTypeCd == "RESIDENTIAL") || (@renewalPayer.copyFromAddr2 != "" && address.addressTypeCd == "OFFICE") || (@renewalPayer.copyFromAddr3 != "" && address.addressTypeCd == "PERMANENT") 
                        address.removed = "YES"
                    end
                end
                @renewalPayer.PartyEmploymentList.each do |employment|
                    if MobiSys::PolicyBO.checkForEmptyFields(employment)
                        employment.removed = "YES"
                    else
                        employment.annualIncome = employment.annualIncome.to_s.gsub(',','').to_i
                    end
                end
                @renewalPayer.PartyContactList.each do |contact|
                    contact.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(contact)
                end
                @renewalPayer.PartyIdentityList.each do |identity|
                    identity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(identity)
                end
                @renewalPayer.PartyEmailList.each do |email|
                    email.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(email)
                end

                @renewalPayment.payerPartyRefGuid = @renewalPayer.uniqueKey
                @renewalPartyRole.partySameAsCd = ""
                @renewalPartyRole.refGuid = @renewalPayment.payerPartyRefGuid
                @renewalFinancialAccount.parentKey = @renewalPayer.object
                partyIdentity1 = @renewalPayer.PartyIdentityList[0]
                partyIdentity2 = @renewalPayer.PartyIdentityList[1]

                #converting screen date to db date
                @renewalPayer.birthDt = getDBDate(@renewalPayer.birthDt) if @renewalPayer && @renewalPayer.birthDt.to_s != ""
                partyIdentity1.expiryDt = getDBDate(partyIdentity1.expiryDt) if partyIdentity1 && partyIdentity1.expiryDt.to_s != ""
                partyIdentity1.issueDt = getDBDate(partyIdentity1.issueDt) if partyIdentity1 && partyIdentity1.issueDt.to_s != ""
                partyIdentity2.expiryDt = getDBDate(partyIdentity2.expiryDt) if partyIdentity2 && partyIdentity2.expiryDt.to_s != ""
                partyIdentity2.issueDt = getDBDate(partyIdentity2.issueDt) if partyIdentity2 && partyIdentity2.issueDt.to_s != ""
            else
                payerParty = Party.loadObject(
                    :first,
                    :loadChild => false,
                    :conditions => {
                        {:name => 'parentKey'} => policy.object,
                        {:name => 'guid'} => @renewalPayment.payerPartyRefGuid,
                        :op => 'AND'
                    }
                )
                @renewalPayment.payerPartyRefGuid = payerParty != nil ? payerParty.uniqueKey : ""
                @renewalPartyRole.partySameAsCd = @renewalPayment.payerTypeCd
                @renewalPartyRole.refGuid = @renewalPayment.payerPartyRefGuid
                @renewalFinancialAccount.parentKey =  payerParty != nil ? payerParty.object : "" 
            end
            @renewalFinancialAccount.persistAll

            if @renewalPayment.payerTypeCd == ""
                oldRenewalPayer = PolicyPayment.loadObject(:first, :conditions=>{{:name=>'object'}=>@renewalPayment.object})
                oldRenewalPayer.delete if oldRenewalPayer
            end
            policy.persistAll
        end
    end


    #Method to load Questionnaires Tab
    def getQuestionnaires
        if (@errors && !@errors.empty?)
            Alert.show_popup({ 
                :message => getLabelValue("The questionnaires applicable to Customers are based on various parameters. If the parameters have changed the questionnaires need to be refreshed. The existing data will be merged with the applicable questionnaires."), 
                :title => getLabelValue("ERROR"),
                :buttons=> ["Ok"],
                :callback => url_for(:action => :prompt_dismiss)
            })
        end
        @navbarIds, @navbarLabels = getNavbarDetails('tab_questionnaire', @policy)
        if  @params['sym_navbar'].to_s != ''
            partyGuid = @params['sym_navbar'].sub("#{@params['sym_current_Tab']}-",'')
            getLifeQuestionnaire(partyGuid)
        else
            if @navbarIds.split(',').first.to_s != ''
                getLifeQuestionnaire(@navbarIds.split(',').first)
            end
        end
    end
    ##################################################################################################


    def getLifeQuestionnaire(lifeGuid)
        $childHTMLHash = {}
        $questionSetData = nil
        $questionSetMapData = nil

        # @life = Party.loadObject(:first, :conditions=>{{:name=>'guid'}=>lifeGuid})
        @quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
        @quotationParty = @quotation.QuotationPartyList.select{|qp| qp.guid == lifeGuid }.first
        @baseProduct = MobiSys::QuotationBO.getBaseProduct(@quotation)

        policyProductInsuredObj = PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>@quotationParty.guid,{:name=>'roleCd'} => @quotationParty.roleCd},:op => 'AND')
         
        productFacet = $currentProduct.getFacet('PRODUCTQUESTIONSETGROUP')
        proposerQuestFacet = $currentProduct.getFacet('PROPOSERQUESTIONSETGROUP')
        payerQuestFacet = $currentProduct.getFacet('PAYERQUESTIONSETGROUP')
        displayProductQuestion = false
        displayProposerQuestion = false
        displayPayerQuestion = false
        questionSetCd = ""
        proposerQuestionSetCd = ""
        payerQuestionSetCd = ""
        questionnaireTypeCd = ""

        if productFacet
            if productFacet.actionTypeCd=='VALUE' || productFacet.actionTypeCd=='LOOKUP'
                questionSetCd = productFacet.actionValue
            elsif productFacet.actionTypeCd=='RULE'
                prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(productFacet.ruleSeq, @quotation, @baseProduct, @quotationParty)
                questionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
            end
        end
        displayProductQuestion = true if questionSetCd.to_s != ""

        if @quotationParty.roleCd.to_s == 'PROPOSER' 
            insuredPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            if insuredPartyRole
                proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
            else
                proposerIsSameAsInsured = false
            end
            if proposerQuestFacet != nil
                if proposerQuestFacet.actionTypeCd=='VALUE' || proposerQuestFacet.actionTypeCd=='LOOKUP'
                    proposerQuestionSetCd = proposerQuestFacet.actionValue
                elsif proposerQuestFacet.actionTypeCd=='RULE'
                    prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(proposerQuestFacet.ruleSeq, @quotation, @baseProduct, @quotationParty)
                    proposerQuestionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
                end
                displayProposerQuestion = true if proposerQuestionSetCd.to_s != ''
            end
            if policyProductInsuredObj == nil && !proposerIsSameAsInsured
                displayProductQuestion = false
            end
        elsif @quotationParty.roleCd.to_s == 'PAYER' 
            displayProductQuestion = false
        end

        payerPolicyPartyRole = @policy.getPolicyPartyRoleByPartyGuid(lifeGuid, 'PAYER')
        if payerPolicyPartyRole && payerQuestFacet
            if payerQuestFacet.actionTypeCd=='VALUE' || payerQuestFacet.actionTypeCd=='LOOKUP'
                payerQuestionSetCd = payerQuestFacet.actionValue
            elsif payerQuestFacet.actionTypeCd=='RULE'
                prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(payerQuestFacet.ruleSeq, @quotation, @baseProduct, @quotationParty)
                payerQuestionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
            end
            displayPayerQuestion = true if payerQuestionSetCd != ''
        end

        $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
        $questionSetMapData = QuestionSetMap.find(
            :all,
            :order => ['parentQuestionSetCd', 'displayOrder']
        ) unless $questionSetMapData
        @totalQuestionSetQuestionCount = QuestionSetQuestion.find(:count)

        @finalQuestions = []
        if displayProductQuestion
            # display product question for insured/joint/supplementary/proposer/payer
            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, questionSetCd)
            @finalQuestions.push questionnaireHash
            questionnaireTypeCd = 'INSUREDPARTY'
        end

        if displayProposerQuestion
            # display proposer questions for proposer
            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, proposerQuestionSetCd)
            @finalQuestions.push questionnaireHash
            questionnaireTypeCd = 'PROPOSERPARTY' if questionnaireTypeCd == ''
        end

        if displayPayerQuestion
            # display payer questions for payer
            payerQuestionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, payerQuestionSetCd)
            @finalQuestions.push payerQuestionnaireHash if payerQuestionnaireHash
            questionnaireTypeCd = 'PAYERPARTY' if questionnaireTypeCd == ''
        end

        @questionContainer = QuestionContainer.loadObject(
            :first, 
            :conditions=>{
                {:name=>'entityGuid'} => @quotationParty.guid,
                {:name=>'policyGuid'} => @policy.uniqueKey
            },
            :op => 'AND'
        ) || 
        QuestionContainer.new(
            :entityGuid => @quotationParty.guid,
            :entityTypeCd => @quotationParty.roleCd,
            :policyGuid => @policy.uniqueKey
        )
        @questionContainer.questionnaireTypeCd = questionnaireTypeCd
        @responseHash = MobiSys::Questionnaire.setupResponseHash(@questionContainer)
    end
    ##################################################################################################


    def loadChildQuestions
        key = @params['questionToBeLoaded']
        html = $childHTMLHash[key]
        render :string => html
    end
    ##################################################################################################


    def getExpressionBasedChildQuestions
        drivingParentQsetCd = @params['drivingParent']
        impactedQSetCds = @params['impactedQSetCds']
        policyObject = @params['Policy']['object']
        impactedQSetCdList = Array.new
        impactedQSetCdList.push drivingParentQsetCd if impactedQSetCds == 'undefined'
        impactedQSetCdList.push impactedQSetCds.split(',') if impactedQSetCds != 'undefined'
        impactedQSetCdList = impactedQSetCdList.flatten.compact

        policy = Policy.loadObject(:first, :conditions=>{ :object => policyObject})
        quotation = MobiSys::PolicyBO.convertToQuotation(policy,false)
        
        questionContainer = MobiSys::BrowserHelper.convertToObject('QuestionContainer', @params['QuestionContainer'])
        responseHash = MobiSys::Questionnaire.setupResponseHash(questionContainer)
        
        party = policy.getPartyByGuid(questionContainer.entityGuid)
        quotationParty = quotation.QuotationPartyList.select{|qp| qp.guid == party.guid}.first
        baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
        @totalQuestionSetQuestionCount = QuestionSetQuestion.find(:count)
        $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
        $questionSetMapData = QuestionSetMap.find(
            :all,
            :order => ['parentQuestionSetCd', 'displayOrder']
        ) unless $questionSetMapData
       
        dataHash = {}
        impactedQSetCdList.each do |impactedQSetCd|
            htmlContent = ''
            childQsetCds = ''
            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, impactedQSetCd)
            htmlContent << renderQuestionnaire(questionnaireHash, nil, questionContainer, responseHash, quotationParty, quotation, baseProduct, false, policy, childQsetCds)
            dataHash[impactedQSetCd] = htmlContent
        end
        render :nothing => true
        return dataHash.to_json
    end
    ##################################################################################################

    def evaluateChildQuestions
        $parentQuestionCd = @params['drivingParent']
        drivingParentQsetCd = $parentQuestionCd.split('|')[0]
        questionToBeLoaded = @params['questionToBeLoaded']
        if $childHTMLHash[questionToBeLoaded]
            html = $childHTMLHash[questionToBeLoaded]
        else
            policyObject = @params['Policy']['object']

            policy = Policy.loadObject(:first, :conditions=>{ :object => policyObject})
            quotation = MobiSys::PolicyBO.convertToQuotation(policy,false)
            
            questionContainer = MobiSys::BrowserHelper.convertToObject('QuestionContainer', @params['QuestionContainer'])
            responseHash = MobiSys::Questionnaire.setupResponseHash(questionContainer)
            
            party = policy.getPartyByGuid(questionContainer.entityGuid)
            quotationParty = quotation.QuotationPartyList.select{|qp| qp.guid == party.guid}.first
            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            @totalQuestionSetQuestionCount = QuestionSetQuestion.find(:count)
            $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
            $questionSetMapData = QuestionSetMap.find(
                :all,
                :order => ['parentQuestionSetCd', 'displayOrder']
            ) unless $questionSetMapData
           
            dataHash = {}
            htmlContent = ''
            childQsetCds = ''
            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, drivingParentQsetCd)
            htmlContent << renderQuestionnaire(questionnaireHash, nil, questionContainer, responseHash, quotationParty, quotation, baseProduct, true, policy, childQsetCds)
            html = $childHTMLHash[questionToBeLoaded]
        end
        $parentQuestionCd = nil
        render :string => html
    end
    ##################################################################################################


    def submitQuestionnaire(newPolicy)
        if @params['QuestionContainer']
            questionContainer = MobiSys::BrowserHelper.convertToObject('QuestionContainer', @params['QuestionContainer'])
            ServiceQuestionResponse.delete_all(:conditions => {'parentKey'=>questionContainer.object }) if questionContainer.additionalFieldQuest.to_s != 'FORMBASED' 
            taskList = TaskException.loadObject(:all, :conditions => {'fieldReference'=> questionContainer.guid + "-questionnaire"})
            TaskException.delete_all(:conditions => {'fieldReference'=> questionContainer.guid + "-questionnaire"})
        end
    end
    ##################################################################################################


    #Method to load Requirements Tab
    def getRequirements
        @navbarIds, @navbarLabels = getNavbarDetails('tab_requirement', @policy)
        if  @params['sym_navbar'].to_s != ''
            partyGuid = @params['sym_navbar'].sub("#{@params['sym_current_Tab']}-",'')
            getLifeRequirements(partyGuid)
        else
            if @navbarIds.split(',').first.to_s != ''
                getLifeRequirements(@navbarIds.split(',').first)
            end
        end
    end
    ##################################################################################################


    def getLifeRequirements(lifeGuid)
        life = @policy.getPartyByGuid(lifeGuid)
        lifePartyRole = nil
        @policy.PolicyPartyRoleList.each do |ppr|
            if ppr.refGuid == lifeGuid
                lifePartyRole = ppr
                break
            end
        end

        quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
        baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
        @policyPayment = @policy.getPolicyPayment("RENEWALPREMIUM")
        if @policyPayment != nil && (lifePartyRole.roleCd == "PROPOSER" || lifePartyRole.roleCd == "PAYER") && baseProduct != nil
            baseProduct.paymentMethodCd = @policyPayment.paymentMethodCd
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
            @multiDocMode = true
        else
            @multiDocMode = false
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
                    # if lifePartyRole.partySameAsCd.to_s != ""
                    #     tempCurrRoleCd = life.roleCd
                    #     life.roleCd = lifePartyRole.roleCd.to_s
                    # end
                    defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true, true)
                    defTables.each do |defTable|
                        if defTable.documentCategoryCd.to_s != ''
                            categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                        end
                    end
                    insuredPartyRole = @policy.getPolicyPartyRole("PRIMARY")
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
        if baseProduct
            baseProduct.partyRoleCd = originalPartyRole
            baseProduct.insuredPartyRefGuid = originalInsureRefGuid
            baseProduct.combinedEntryAge = originalCombinedEntryAge
        end
        @container = DocumentContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>life.guid, {:name=>'policyGuid'} => @policy.guid},:op => 'AND')

        @requirementsHM = Hash.new
        @imageHM = Hash.new
        @categoryLabelHM = {}

        categoryCdDescHM = {}
        @documentHashMap = {}
        docCategoryTypeLookup = Lookupvalue.getValue('DOCCATEGORYTYPE')
        docCategoryTypeLookup.each do |lookup|
            categoryCdDescHM[lookup.cd] = lookup.desc
        end

        if @container != nil
            existingServiceDocumentList = {}
            if @multiDocMode
                @container.ServiceDocumentList.each do |serviceDocument|
                    existingServiceDocumentList["#{serviceDocument.docCategoryCd}|#{serviceDocument.documentCd}"] = serviceDocument
                    categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
                end
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd, dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory << "';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    serviceDocumentsPerCategory = {}
                    documents.each do |document|
                        if existingServiceDocumentList["#{docCategory}|#{document.documentCd}"].to_s != ''
                            serviceDocument = existingServiceDocumentList["#{docCategory}|#{document.documentCd}"]
                            serviceDocument.docDescription = document.documentDesc
                            images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDocument.guid})
                            images.each do |image|
                                if @imageHM[serviceDocument.guid].to_s == ""
                                    @imageHM[serviceDocument.guid] = []
                                    @imageHM[serviceDocument.guid].push image
                                else
                                    @imageHM[serviceDocument.guid].push image
                                end
                            end
                        else
                            serviceDocument = ServiceDocument.new
                            serviceDocument.partyGuid = life.guid
                            serviceDocument.docCategoryTypeCd = document.categoryTypeCd
                            serviceDocument.docCategoryCd = docCategory
                            serviceDocument.documentCd = document.documentCd
                            serviceDocument.docDescription = document.documentDesc
                            serviceDocument.acceptanceStatusCd = "PENDING"
                            serviceDocument.isAutoGeneratedFl = "YES"
                            @container.addServiceDocument(serviceDocument)
                        end
                        serviceDocumentsPerCategory[document.documentCd] = serviceDocument
                        @categoryLabelHM[document.categoryCd] = categoryCdDescHM[document.categoryTypeCd]
                        @documentHashMap[document.documentCd] = document.ocrIdentifier
                    end
                    @requirementsHM[docCategory] = serviceDocumentsPerCategory
                end
            else
                existingServiceDocumentList = @container.ServiceDocumentList.group_by{|serviceDocument| serviceDocument.docCategoryCd}
                @container.ServiceDocumentList.each do |serviceDocument|
                    categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
                end
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory << "';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    documents.each do |document|
                        @categoryLabelHM[document.categoryCd] = categoryCdDescHM[document.categoryTypeCd]
                    end
                    if existingServiceDocumentList[docCategory].to_s != ''
                        serviceDocument = existingServiceDocumentList[docCategory][0]
                        images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDocument.guid})
                        images.each do |image|
                            if @imageHM[serviceDocument.guid].to_s == ""
                                @imageHM[serviceDocument.guid] = []
                                @imageHM[serviceDocument.guid].push image
                            else
                                @imageHM[serviceDocument.guid].push image
                            end
                        end
                    else
                        serviceDocument = ServiceDocument.new
                        serviceDocument.partyGuid = life.guid
                        serviceDocument.docCategoryTypeCd = @docCategoryType
                        serviceDocument.docCategoryCd = docCategory
                        serviceDocument.acceptanceStatusCd = "PENDING"
                        serviceDocument.isAutoGeneratedFl = "YES"
                        @container.addServiceDocument(serviceDocument)
                    end
                    serviceDocument.receivedDt = getScreenDate(serviceDocument.receivedDt) if serviceDocument.receivedDt
                    @requirementsHM[docCategory] = serviceDocument
                end
            end
        else
            @container = DocumentContainer.new
            @container.entityGuid = life.guid
            @container.entityTypeCd = life.class.name.to_s
            @container.policyGuid = @policy.guid
            if @multiDocMode
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd, dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory << "';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    serviceDocumentsPerCategory = {}
                    documents.each do |document|
                        serviceDocument = ServiceDocument.new
                        serviceDocument.partyGuid = life.guid
                        serviceDocument.docCategoryTypeCd = document.categoryTypeCd
                        serviceDocument.docCategoryCd = docCategory
                        serviceDocument.documentCd = document.documentCd
                        serviceDocument.docDescription = document.documentDesc
                        serviceDocument.acceptanceStatusCd = "PENDING"
                        serviceDocument.isAutoGeneratedFl = "YES"
                        @container.addServiceDocument(serviceDocument)

                        serviceDocumentsPerCategory[document.documentCd] = serviceDocument
                        @categoryLabelHM[document.categoryCd] = categoryCdDescHM[document.categoryTypeCd]
                        @documentHashMap[document.documentCd] = document.ocrIdentifier
                    end
                    @requirementsHM[docCategory] = serviceDocumentsPerCategory
                end
            else
                categoriesDerivedFromDT.each do |docCategory|
                    documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategory << "';")
                    documents.sort_by!{|document| document.sortOrder.to_i}
                    documents.each do |document|
                        @categoryLabelHM[document.categoryCd] = categoryCdDescHM[document.categoryTypeCd]
                    end
                    serviceDocument = ServiceDocument.new
                    serviceDocument.partyGuid = life.guid
                    serviceDocument.docCategoryTypeCd = documents[0].categoryTypeCd
                    serviceDocument.docCategoryCd = docCategory
                    serviceDocument.acceptanceStatusCd = "PENDING"
                    serviceDocument.isAutoGeneratedFl = "YES"
                    @container.addServiceDocument(serviceDocument)
                    @requirementsHM[docCategory] = serviceDocument
                end 
            end
        end
    end
    ##################################################################################################


    #Method to save & validate Requirements Tab
    def submitRequirements
        container = MobiSys::BrowserHelper.convertToObject('DocumentContainer', @params['DocumentContainer'])

        if @params['multiDocMode'] == 'true'
            container.ServiceDocumentList.each do |serviceDoc|
                if serviceDoc.selected.to_s != 'YES' && serviceDoc.isAutoGeneratedFl != "YES_UW"
                    serviceDoc.removed = 'YES'
                    images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDoc.guid })
                    images.each do |img|
                        File.delete(img.OfflineFileList[0].fileLocation) if File.exist?(img.OfflineFileList[0].fileLocation)
                        img.OfflineFileList[0].destroy
                        img.destroy  
                    end
                    serviceDoc.imageCount = 0
                else
                    serviceDoc.receivedDt = getDBDate(serviceDoc.receivedDt) if serviceDoc.receivedDt
                end
            end
        else
            container.ServiceDocumentList.each do |serviceDoc|
                if serviceDoc.documentCd.to_s == '' && serviceDoc.isAutoGeneratedFl != "YES_UW"
                    serviceDoc.removed = 'YES'
                else
                    serviceDoc.receivedDt = getDBDate(serviceDoc.receivedDt) if serviceDoc.receivedDt
                end
            end
        end
        container.persistAll
    end
    ##################################################################################################


    #Deepali Singh:18/07/2017 - removed load and persist of servicedocument and updating value of image count. Image count is now handled in form. Made provsion to delete single and multiple images. 
    def removeImage
        imageObjects = []
        if @params['numberOfimages'].to_s == 'single'
            img = Image.loadObject(:first, :conditions => { :object => @params['imageObject'] })
            File.delete(img.OfflineFileList[0].fileLocation) if File.exist?(img.OfflineFileList[0].fileLocation)
            img.OfflineFileList[0].destroy
            img.destroy
        else
            images = Image.loadObject(:all, :conditions => { :parentRefGuid => @params['servicedocGuid'] })
            images.each do |img|
                imageObjects.push img.object
                File.delete(img.OfflineFileList[0].fileLocation) if File.exist?(img.OfflineFileList[0].fileLocation)
                img.OfflineFileList[0].destroy
                img.destroy  
            end
        end
        WebView.execute_js("loading('hide');")
        return render :string => imageObjects.join(',').to_json
    end
    #################################################################################################
    

    def take_cam_pic
        container = MobiSys::BrowserHelper.convertToObject('DocumentContainer', @params['DocumentContainer'])
        if @params['multiDocMode'] == 'true'
            container.ServiceDocumentList.each do |serviceDoc|
                if serviceDoc.selected.to_s != 'YES'
                    serviceDoc.removed = 'YES'
                    images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDoc.guid })
                    images.each do |img|
                        File.delete(img.OfflineFileList[0].fileLocation) if File.exist?(img.OfflineFileList[0].fileLocation)
                        img.OfflineFileList[0].destroy
                        img.destroy  
                    end
                    serviceDoc.imageCount = 0
                else
                    serviceDoc.receivedDt = getDBDate(serviceDoc.receivedDt) if serviceDoc.receivedDt
                end
            end
        else
            container.ServiceDocumentList.each do |serviceDoc|
                if serviceDoc.documentCd.to_s == ''
                    serviceDoc.removed = 'YES'
                else
                    serviceDoc.receivedDt = getDBDate(serviceDoc.receivedDt) if serviceDoc.receivedDt
                end
            end
        end
        container.persistAll
        id = @params["serviceDocument_guid"]
        file_name = "http://localhost:9000/app/Camera.html?docId=#{id}"
        System.open_url(file_name)        
        redirect :action => :showProposal, :id => @params["policyObject"], :query => {:set_get_req_tab=>"TRUE"}
    end
    ##################################################################################################


    #Method to decode & return the base64 encoded string generated by the camera capture feature
    def get_decode_string
        begin
            incode_image_str = @params["img"]
            serviceDocument_guid = @params["docId"]       
            serviceDoc = ServiceDocument.loadObject(:first, :conditions=>{'guid'=>serviceDocument_guid.to_s})
            serviceDoc.imageCount = serviceDoc.imageCount.to_i + 1
            serviceDoc.acceptanceStatusCd = 'RECEIVED'
            serviceDoc.receivedDt = Time.now
            serviceDoc.persistAll
            #remved the str till to "data:image/png;base64,"
            image = incode_image_str[22..-1]
            uniq_num = rand(10000)
            file_name = "#{Rho::RhoApplication.get_blob_folder}/#{uniq_num}.jpg"
            decode_image = Base64.decode64(image)
            File.open(file_name, 'wb') do|f|
                f.write(decode_image)
            end

            image_uri = "db/db-files/#{uniq_num}.jpg"
            offlineFile = OfflineFile.new
            new_image = Image.new
            new_image.parentRefGuid = serviceDocument_guid
            new_image.dateTimeTaken = Time.now
            fileName = image_uri

            fileName = Rho::RhoApplication.get_blob_path(fileName)

            offlineFile.fileLocation = fileName
            offlineFile.fileEncrypted = 'NO'
            offlineFile.fileContents = image

            offlineFile.md5Hash = MobiSys::Encryption.digest(offlineFile.fileContents)
            new_image.addOfflineFile offlineFile
            new_image.persistAll
            File.delete(fileName)
            WebView.execute_js("loading('hide');")
            render :action => :get_decode_string
        rescue StandardError => se
            puts "Error while capturing image =>" + se.to_s
        end
    end
    ##################################################################################################


    #Method to load Agent Declaration Tab
    def getAgentQuestion
        $childHTMLHash = {}
        @life = nil
        @quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
        @baseProduct = MobiSys::QuotationBO.getBaseProduct(@quotation)

        #Agent Signature code
        @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
        if @signatureContainer.to_s == ""
            @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
        end
        
        @agentDeclarationSignature = MobiSys::SignatureUtil.getAgentSignature(@policy, @signatureContainer) if @signatureContainer

        #Agent Questionnaire Code      
        product = MobiSys::ProductUtil.getProduct(@policy.baseProductSeq)
        productFacet = product.getFacet('AGENTQUESTIONSETGROUP')

        questionSetCd = ""
        questionSetCd = productFacet.actionValue if productFacet

        $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
        $questionSetMapData = QuestionSetMap.find(
            :all,
            :order => ['parentQuestionSetCd', 'displayOrder']
        ) unless $questionSetMapData
        @finalQuestions = []
        questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, questionSetCd)
        @finalQuestions.push questionnaireHash
        @totalQuestionSetQuestionCount = QuestionSetQuestion.find(:count)
        @questionContainer = QuestionContainer.loadObject(
            :first, 
            :conditions=>{
                {:name=>'entityGuid'} => @policy.uniqueKey,
                {:name=>'policyGuid'} => @policy.uniqueKey,
                {:name=>'entityTypeCd'} => 'AGENT'
            },
            :op => 'AND'
        ) || 
        QuestionContainer.new(
            :entityGuid => @policy.uniqueKey,
            :policyGuid => @policy.uniqueKey,
            :entityTypeCd => 'AGENT'
        )
        @questionContainer.questionnaireTypeCd = 'AGENT'
        @responseHash = MobiSys::Questionnaire.setupResponseHash(@questionContainer)
        return @responseHash
    end
    ##################################################################################################


    #Method to save & validate Agent Declaration Tab
    def submitAgentQuestionDetails
        errors = Hash.new
        container = MobiSys::BrowserHelper.convertToObject('QuestionContainer', @params['QuestionContainer'])
        container.persistAll
        if @params['SignatureContainer'].to_s != ''
            signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['SignatureContainer'])
            signatureContainer.ServiceSignatureList.each do |serviceSign|
                serviceSign.signatureDt = getDBDate(serviceSign.signatureDt) if serviceSign.signatureDt.to_s != ""
                if serviceSign.signature.to_s != "" && !serviceSign.signature.to_s.start_with?('ZLIBCMP')
                    serviceSign.signature = serviceSign.signature.gsub!('data:image/png;base64,','')
                    original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSign.signature)
                    compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                    serviceSign.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                end
            end

            signatureContainer.persistAll
        end
    end
    ##################################################################################################


    #Method to check for empty party objects and set them as removed
    def setPartyDetails(party)
        #Code checks for empty fields in child objects and sets removed flag accordingly
        partyIdentity1 = party.PartyIdentityList[0]
        partyIdentity2 = party.PartyIdentityList[1]
        party.PartyAddressList.each do |address|
            if MobiSys::PolicyBO.checkForEmptyFields(address)
                address.removed = "YES"
            elsif party.roleCd == "PROPOSER" && party.partyTypeCd == "ORGANIZATION" && (address.addressTypeCd == "RESIDENTIAL" || address.addressTypeCd == "PERMANENT")
                address.removed = "YES"
            elsif (party.copyFromAddr1.to_s != "" && (address.addressTypeCd.to_s == "RESIDENTIAL" || address.addressTypeCd.to_s == "PROPOSERRESIDENTIAL")) || (party.copyFromAddr2.to_s != "" && address.addressTypeCd.to_s == "PERMANENT") || (party.copyFromAddr3.to_s != "" && address.addressTypeCd.to_s == "OFFICE") 
                address.removed = "YES"
            end
        end
        party.PartyEmploymentList.each do |employment|
            if MobiSys::PolicyBO.checkForEmptyFields(employment)
                employment.removed = "YES"
            else
                employment.annualIncome = employment.annualIncome.to_s.gsub(',','').to_i
            end
        end
        party.PartyContactList.each do |contact|
            contact.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(contact)
        end
        party.PartyIdentityList.each do |identity|
            identity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(identity)
        end
        party.PartyEmailList.each do |email|
            email.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(email)
        end

        party.partyTypeCd = "INDIVIDUAL" if party.partyTypeCd.to_s == ""
        #converting screen date to db date
        party.birthDt = getDBDate(party.birthDt) if party.birthDt.to_s != ""
        partyIdentity1.expiryDt = getDBDate(partyIdentity1.expiryDt) if (partyIdentity1 && partyIdentity1.expiryDt.to_s != "")
        partyIdentity1.issueDt = getDBDate(partyIdentity1.issueDt) if (partyIdentity1 && partyIdentity1.issueDt.to_s != "")
        partyIdentity2.expiryDt = getDBDate(partyIdentity2.expiryDt) if (partyIdentity2 && partyIdentity2.expiryDt.to_s != "")
        partyIdentity2.issueDt = getDBDate(partyIdentity2.issueDt) if (partyIdentity2 && partyIdentity2.issueDt.to_s != "")
    end
    ##################################################################################################


    #Method to create PolicyProductInsured records for Primary & Joint
    def createPolicyProductInsured(policy)
        baseProduct = policy.getBaseProduct
        if baseProduct
            primary = policy.getParty("PRIMARY")
            joint = policy.getParty("JOINT")
            supplementaries = policy.getPartyList("SUPPLEMENTARY")
            primaryFl = true
            jointFl = true
            baseProduct.PolicyProductInsuredList.each do |policyProductInsured|
                if !primary || policyProductInsured.insuredPartyRefGuid.to_s == primary.guid.to_s
                    primaryFl = false
                elsif !joint || policyProductInsured.insuredPartyRefGuid.to_s == joint.guid.to_s
                    jointFl = false
                end
            end
            if $currentProduct.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES'
                supplementaries.each do |supplementary|
                    createSupPPI = true
                    baseProduct.PolicyProductInsuredList.each do |policyProductInsured|
                        if policyProductInsured.roleCd.to_s == 'SUPPLEMENTARY' && policyProductInsured.insuredPartyRefGuid.to_s == supplementary.guid.to_s
                            createSupPPI = false
                            break
                        end
                    end
                    if createSupPPI
                        baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "SUPPLEMENTARY", :insuredSequenceTypeCd => "SUPPLEMENTARY", :insuredPartyRefGuid => supplementary.guid))
                    end
                end
            end
            
            if primary && primaryFl
                baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => primary.guid))
            end
            if joint && jointFl
                baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => joint.guid))
            end
        end
    end
    ##################################################################################################


    #Method to save policy and validate all tabs
    def executeSave
        resetObjectMapping
        if @params.has_key?('mode') && @params['mode'] == "FETCH"
            if Policy.loadObject(:first, :loadChild => false, :conditions=>{:object=>@params['id']})
                redirect :action => :showProposal, :query => {"sym_current_Tab" => @params['sym_current_Tab'], "sym_navbar" => @params['sym_navbar']}, :id => @params['id']
            else
                policy = MobiSys::BrowserHelper.convertToObject('Policy',  @params['formData']['Policy'])
                redirect :action => :newPolicy, :query => {"productFamily"=>policy.getBaseProduct.productFamilyCd,"productId"=>policy.getBaseProduct.productId,"productSeq"=>policy.getBaseProduct.productSeq,"productPlanOptionCd"=>policy.getBaseProduct.productPlanOptionCd,"leadid"=>policy.leadId,"rpqid"=>policy.rpqId}
            end
        else
            if @params['Policy']['insuranceTypeCd'].to_s == 'AUTO'
                policy = executePolicyAuto
            elsif @params['Policy']['insuranceTypeCd'].to_s == 'TRAVEL'
                policy = executePolicyTravel
            elsif @params['Policy']['insuranceTypeCd'].to_s == 'HEALTH'
                policy = executePolicyLife
            else
                policy = executePolicyLife
            end
            MobiSys::TrackLeadBO.updateTrackLead(policy)
            redirect :action => :showProposal, :query => {:submit => '', "sym_navbar" => @params['sym_navbar'], "sym_current_Tab" => @params['sym_current_Tab']}, :id => policy.object
        end
    end
    ##################################################################################################


    def executePolicyLife
        # Convert request params and merge with existing policy
        policyObj = @params['Policy']['object']
        newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        unless newPolicy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
            newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['currentTab']
        end
        newPolicy.startDt = getDBDate(newPolicy.startDt) if newPolicy.startDt.to_s != ''
        newPolicy.endDt = getDBDate(newPolicy.endDt) if newPolicy.endDt.to_s != ''
        # Check for empty party objects and set them as removed
        newPolicy.PartyList.each do |party|
            setPartyDetails(party)
        end
        submitBeneficiaryAppointeeDetails(newPolicy)
        submitPaymentDetails(newPolicy)
        submitQuestionnaire(newPolicy)
        newPolicy.persistAll
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        #File reset over here
        if $rhoconfig[:setPolicyModelLog] == 1
            fileName = policy.proposalNum.to_s+"_Policy_Logs.txt"
            Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
            downloadFolder = Rho::RhoApplication.get_blob_folder
            filePath = File.join(downloadFolder, fileName)
            if File::exist? filePath
                File.open(filePath, 'w') { |file| file.puts "" }
            end
        end


        # Party Relation logic
        primary = policy.getParty("PRIMARY")
        primaryPartyRole = policy.getPolicyPartyRole("PRIMARY")
        guid = primary.guid
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

        if primary.PartyRelationList.size == 0
            primaryPartyRelation.each do |primaryRelation|
                primary.addPartyRelation(primaryRelation)
            end
        else
            primary.PartyRelationList.each do |primaryRelation1|
                primaryPartyRelation.each do |primaryRelation2|
                    if primaryRelation1.relatedToPartyId == primaryRelation2.relatedToPartyId
                        primaryRelation2.relationCd = primaryRelation1.relationCd
                        break
                    end
                end
            end
        end


        policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if policy.proposalNum.to_s == ""
        createPolicyProductInsured(policy)
        primaryInsuredPolicyPartyRole = policy.getPolicyPartyRole("PRIMARY")
        proposerParty = policy.getParty("PROPOSER")
        if primaryInsuredPolicyPartyRole
            if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
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

        submitPlanDetails(policy)
        submitSupplementary(policy)
        submitRequirements if @params.has_key?('DocumentContainer')
        submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
        policy.PartyList.each do |party|
            if party.visitedTabs.to_s == ""
                party.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",party.roleCd)
            end
        end
        policy.PolicyProductList.each do|policyProduct|
            if policyProduct.visitedTabs.to_s == ""
                policyProduct.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",policyProduct.productTypeCd)
            end
        end
        MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(policy)
        if @params['currentTab'] != "tab_signature" && ((policy.statusCd.to_s == "SIGNED" && (policy.uwDecisionCd.to_s == "ACCEPTEDRATED" || policy.uwDecisionCd.to_s == "REQUIREMENTPENDING")) || (policy.statusCd.to_s == "UWCOMPLETE" && (policy.uwDecisionCd.to_s == "ACCEPTEDRATED" || policy.uwDecisionCd.to_s == "REQUIREMENTPENDING")) || policy.statusCd.to_s == "COMPLETE" || policy.statusCd.to_s == "ACCEPTED" || policy.statusCd.to_s == "PENDING" || policy.statusCd.to_s == "")
            MobiSys::SignatureUtil.clearSignatures(policy) if policy.uwDecisionCd != "REQUIREMENTPENDING"
            policy.proposalSignedDt = "" if policy.uwDecisionCd != "REQUIREMENTPENDING"
            policy.uwDecisionCd = "PENDING" if policy.uwDecisionCd != "REQUIREMENTPENDING"
            policy.statusCd = "PENDING" if policy.uwDecisionCd != "REQUIREMENTPENDING"
        end
        
        submitSignatureTab(policy) if @params.has_key?('SignatureContainer') && !@params.has_key?('QuestionContainer') && $rhoconfig[:captureSignatureInTab]

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
            policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
        end

        policy.persistAll
        return policy
    end

    def executePolicyTravel
        # Convert request params and merge with existing policy
        policyObj = @params['Policy']['object']
        newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        unless newPolicy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
            newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['currentTab']
        end
        newPolicy.startDt = getDBDate(newPolicy.startDt) if newPolicy.startDt.to_s != ''
        newPolicy.endDt = getDBDate(newPolicy.endDt) if newPolicy.endDt.to_s != ''
        # Check for empty party objects and set them as removed
        newPolicy.PartyList.each do |party|
            setPartyDetails(party)
        end
        newPolicy.persistAll
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if policy.proposalNum.to_s == ""
        createPolicyProductInsured(policy)
        primaryInsuredPolicyPartyRole = policy.getPolicyPartyRole("PRIMARY")
        proposerParty = policy.getParty("PROPOSER")
        if primaryInsuredPolicyPartyRole
            if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
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
        MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(policy)
        policy.persistAll
        return policy
    end

    def executePolicyAuto
        # Convert request params and merge with existing policy
        policyObj = @params['Policy']['object']
        policy = MobiSys::BrowserHelper.convertToObjectWithMerge('Policy', @params['Policy'])
        if @params.has_key?('QuestionContainer')
            policyQuestionContainer = MobiSys::BrowserHelper.convertToObjectWithMerge('QuestionContainer', @params['QuestionContainer'])
            policyQuestionContainer.persistAll
        end
        unless policy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
            policy.visitedTabs = policy.visitedTabs.to_s + "," + @params['currentTab']
        end
        policy.startDt = getDBDate(policy.startDt) if policy.startDt.to_s != ''
        policy.endDt = getDBDate(policy.endDt) if policy.endDt.to_s != ''
        # Check for empty party objects and set them as removed
        policy.PartyList.each do |party|
            setPartyDetails(party)
        end
        policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if policy.proposalNum.to_s == ""
        createPolicyProductInsured(policy)
        primaryInsuredPolicyPartyRole = policy.getPolicyPartyRole("PRIMARY")
        proposerParty = policy.getParty("PROPOSER")
        # if primaryInsuredPolicyPartyRole
        #     if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
        #         primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
        #         primaryInsuredPolicyPartyRole.refGuid = proposerParty.guid if proposerParty
        #     else
        #         primaryInsuredPolicyPartyRole.partySameAsCd = nil
        #         insured = nil
        #         policy.PartyList.each do |party|
        #             if party.roleCd == "PRIMARY"
        #                 insured = party 
        #                 break
        #             end
        #         end
        #         primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
        #     end
        # elsif !MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct) && proposerParty
        #     policy.addPolicyPartyRole(PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => proposerParty.uniqueKey, :partySameAsCd => "PROPOSER"))
        # end
        policyPartyRole = policy.PolicyPartyRoleList
        policyPartyRole.each do |ppr|
            if ppr.partySameAsCd == "YES" || ppr.partySameAsCd == "PROPOSER"
                ppr.partySameAsCd = 'PROPOSER'
                ppr.refGuid = proposerParty.guid if proposerParty
            end
        end
        MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(policy)
        policy.persistAll
        return policy
    end

    #Method to submit policy to online server
    def executeSubmit(doPolicySubmit=true)
        resetObjectMapping
        # Convert request params and merge with existing policy
        if @params.has_key?('doPolicySubmit') && @params['doPolicySubmit'] == "false"
            doPolicySubmit = false
        end

        if @params.has_key?('id') && @params['id'] != ""
            if @params['id'].include? "{"
                policyObj = @params['id'][1..-1].chop 
            else
                policyObj = @params['id']
            end
        elsif @params.has_key?('formData')
            policyObj = @params['formData']['Policy']['object']
        else
            policyObj = @params['Policy']['object']
        end

        @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        isValid = true
        policyNum = ""
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        isValid = false unless @errors.empty?
        if doPolicySubmit && @policy.statusCd == "DECLARATIONCOMPLETE" && @policy.signatureStatus != "SUCCESS"
            isValid = false
        end
        if isValid
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection 
            # has_network = false #uncomment to test offline flow.
            begin
                transactionSuccessfull = false 
                if has_network && @policy.proposalSignedDt.to_s != "" && @policy.signatureStatus == "SUCCESS"
                    policyNum = doJSONPost('/checkPolicyDup.run', @policy.proposalNum)
                    if policyNum.to_s == ""
                        @policy.uwDecisionCd = "COMPLETE"
                        @policy.statusCd = "COMPLETE"
                        policyArray = Array.new
                        serviceQuestionResponseArray = Array.new
                        serviceDocumentRequirementArray = Array.new
                        partyImageList = Array.new
                        serviceSignatureArray = Array.new
                        inwardArray = Array.new
                        @taskExceptionsList = Array.new
                       
                        [@policy].each do |policy|
                            policy.PartyList.each do |party|
                                questionContainer = QuestionContainer.loadObject(
                                    :first,
                                    :conditions=>{
                                        {:name=>'entityGuid'} => party.guid,
                                        {:name=>'policyGuid'} => policy.uniqueKey
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
                                        {:name=>'policyGuid'}=> policy.guid
                                    },
                                    :op => 'AND'
                                )
                                if documentContainer
                                    partyDocumentList = documentContainer.ServiceDocumentList
                                    #code added to make sericeDocument status received if document is selected and image exist 
                                    partyDocumentList.each do|partydoc|
                                        imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                        partyImageList.concat imageList if imageList.size > 0

                                        if partydoc.acceptanceStatusCd != "RECEIVED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                            partydoc.imageCount = imageList.size
                                            partydoc.acceptanceStatusCd = "RECEIVED"
                                            partydoc.persistAll
                                        end
                                    end
                                    serviceDocumentRequirementArray.concat partyDocumentList
                                end
                            end
                        end

                        agentQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions => {
                                {:name => 'entityGuid'} => @policy.guid, 
                                {:name => 'policyGuid'} => @policy.guid,
                                {:name => 'entityTypeCd'} => 'AGENT'
                            },
                            :op => 'AND'
                        )
                        if agentQuestionContainer
                            agentResponseList = agentQuestionContainer.ServiceQuestionResponseList
                            serviceQuestionResponseArray.concat agentResponseList
                        end

                        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => @policy.guid})            
                        serviceSignatureArray = signatureContainer.ServiceSignatureList if signatureContainer

                        inward = @policy.getInward(@policy.proposalNum, "APPLICATION_SUSPENSE")
                        emailResponseHash = nil
                        if doPolicySubmit
                            @policy.policyStatusCd = "POLICYSUBMIT"
                            #generating pdf for illustration before submitting application
                            emailResponseHash = generateSIPDF(@policy) 
                        else
                            @policy.policyStatusCd = "AUTOUW"
                        end
                        policyArray.push(@policy)

                        syncEntities = Hash.new
                        syncEntities[Policy.onlineClassName] = policyArray
                        syncEntities[ServiceQuestionResponse.onlineClassName] = serviceQuestionResponseArray if serviceQuestionResponseArray.size > 0
                        syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
                        syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
                        syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                        syncEntities[Inward.onlineClassName] = inward if inward                       
                        
                        transactionSuccessfull = false
                        if !doPolicySubmit || (emailResponseHash != nil && !emailResponseHash.empty?)
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

                                @facetData = getFacetData("result", @policy.baseProductSeq)
                                @facetData[:showResults] = true
                                @exclusionList = []
                                @coverageLoadingList = []
                                @requirementList     = []
                                @uwDecisionCd = ""

                                processPolicyResult(nil, nil, responseHash)
                                
                            else
                               transactionSuccessfull = false # callPolicyService failed 
                            end
                        end
                    else
                        @policy.policyNum = policyNum
                        @policy.persistAll
                        MobiSys::TrackLeadBO.updateTrackLead(@policy)
                        Alert.show_popup({
                            :message => MobiSys::CommonUtil.replacePlaceHolders(MobiSys::BrowserHelper.getLabel('ERR_DUPLPOLICY'), [@policy.policyNum, @policy.proposalNum]),
                            :title => '',
                            :icon => :info,
                            :buttons => ["OK"]
                        })
                        WebView.navigate(url_for :action => :showProposal, :query => {:submit => ''}, :id => @policy.object)
                    end
                elsif !doPolicySubmit
                    serviceDocumentList = []
                    @policy.PartyList.each do |party|
                        documentContainer = DocumentContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'}=> party.guid,
                                {:name=>'policyGuid'}=> @policy.guid
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
                                if partydoc.acceptanceStatusCd != "RECEIVED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                    partydoc.imageCount = imageList.size
                                    partydoc.acceptanceStatusCd = "RECEIVED"
                                    partydoc.persistAll
                                end
                            end
                            serviceDocumentList.concat partyDocumentList
                        end
                    end
                    # puts "before AUW----------#{@policy.hashForSync.to_json}"
                    # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
                    if @policy.statusCd.to_s != "UWCOMPLETE"
                        autoUWRule = PolicyUtil::AutoUWUtil.new
                        serviceDocumentList = autoUWRule.execute(@policy, serviceDocumentList)
                        @policy.statusCd = "UWCOMPLETE"
                        # puts "after AUW----------#{@policy.hashForSync.to_json}"
                        # @policy.statusCd = "PENDINGSUBMIT" #temporary commented
                        @facetData = getFacetData("result", @policy.baseProductSeq)
                        @facetData[:uwType] = "TYPE1"
                        overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                        overallUWDecisionLookup.each do |overallUWDecisionCd|
                            if overallUWDecisionCd.cd == @policy.overallUWDecisionCd
                                @facetData[:uwType] = overallUWDecisionCd.additionalField2.to_s
                                break
                            end
                        end
                        
                    end
                    # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
                    

                    @facetData[:showResults] = true
                    @exclusionList = []
                    @coverageLoadingList = []
                    @requirementList     = []
                    @uwDecisionCd = ""

                    processPolicyResult(@policy, serviceDocumentList)

                    @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid, @policy.visitedTabs)
                    transactionSuccessfull = true
                end
                if transactionSuccessfull
                    MobiSys::TrackLeadBO.updateTrackLead(@policy)
                    if !doPolicySubmit
                        @policy.statusCd = "UWCOMPLETE"
                        if @facetData[:uwType].to_s == "TYPE1" || @facetData[:uwType].to_s == "TYPE2"
                                @policy.counterOfferDecisionCd = "ACCEPTED"
                                @policy.statusCd = "PAYMENTDONE" if !@policy.getGatewayFlag
                                @policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                        end
                        @policy.persistAll
                        if @facetData[:uwType] && (@facetData[:uwType].to_s == "TYPE3" || @facetData[:uwType].to_s == "TYPE4")
                            @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
                            if @signatureContainer.to_s == ""
                                @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
                            end
                    
                            @counterOfferSignature = MobiSys::SignatureUtil.getCounterOfferSignature(@policy, @signatureContainer) if @signatureContainer
                            if @counterOfferSignature.signatureDt.to_s != ""
                                @counterOfferSignature.signatureDt = getScreenDate(@counterOfferSignature.signatureDt.to_s)
                            else
                                @counterOfferSignature.signatureDt = getScreenDate(Time.new.strftime("%F 00:00:00 %z").to_s)
                            end
                        end

                        if @facetData[:uwType] == "TYPE4"
                            @quotation = Quotation.loadObject(:first, :conditions => {:guid => @policy.quotationRefGuid})
                        end
                    end
                    render :action => :outputAUW_Jazz, :layout => :jazzLayout
                elsif doPolicySubmit
                    Alert.show_popup({
                    :message => getLabelValue('SERVERERROR'), 
                                :title => '', 
                                :icon => :info,
                                :buttons => ["OK"] 
                            })
                    
                    if $redirectionFlag
                        WebView.navigate(url_for :action => :showProposal, :query => {:submit => ''}, :id => @policy.object)
                    end
                end
            rescue StandardError => se
                puts se.backtrace
                Alert.show_popup({
                    :message => getLabelValue('SERVERERROR'), 
                    :title => '', 
                    :icon => :info,
                    :buttons => ["OK"] 
                })
                if $redirectionFlag
                    WebView.navigate(url_for :action => :showProposal, :query => {:submit => ''}, :id => @policy.object)
                end
            end
        else
            Alert.show_popup({
                :message => "Please resolve all warnings & sign before policy submission.", 
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
            WebView.navigate(url_for :action => :showProposal, :query => {:submit => ''}, :id => @policy.object)
        end
    end
    ##################################################################################################


    #Method to call online payment gateway
    def executePaymentGateWay
        resetObjectMapping
        # Convert request params and merge with existing policy
        if @params.has_key?('id')
           policyObj = @params['id'][1..-1].chop
        else
            policyObj = @params['Policy']['object']
        end
        dbPolicy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        isValid = true
        if dbPolicy.statusCd == "PENDING" || dbPolicy.statusCd == "COMPLETE"
            newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            unless newPolicy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
                newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['currentTab']
            end
            # Check for empty party objects and set them as removed
            newPolicy.PartyList.each do |party|
                setPartyDetails(party)
            end
            submitBeneficiaryAppointeeDetails(newPolicy)
            submitPaymentDetails(newPolicy)
            submitQuestionnaire(newPolicy)
            newPolicy.persistAll

            @policy = dbPolicy
            @policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if @policy.proposalNum.to_s == ""
            createPolicyProductInsured(@policy)
            primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            if primaryInsuredPolicyPartyRole
                if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                    primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                    primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
                else
                    primaryInsuredPolicyPartyRole.partySameAsCd = nil
                    insured = nil
                    @policy.PartyList.each do |party|
                        if party.roleCd == "PRIMARY"
                            insured = party 
                            break
                        end
                    end
                    primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
                end
            end
            submitPlanDetails(@policy)        
            submitRequirements if @params.has_key?('DocumentContainer')
            submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
            submitSignatureTab(@policy) if @params.has_key?('SignatureContainer') && !@params.has_key?('QuestionContainer')
            MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
            MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
            policyNum = ""
            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
            isValid = false unless @errors.empty?
        else
            @policy = dbPolicy
        end

        if isValid && @policy.proposalSignedDt.to_s != "" && @policy.signatureStatus == "SUCCESS"
            ##### Fetch inward DO then serialize to JSON and send to online  #####
            payer = @policy.getPayerParty("INITIAL")
            inward = @policy.getInward(@policy.proposalNum, "APPLICATION_SUSPENSE")
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
                    Alert.show_popup({
                        :message => getLabelValue('SERVERERROR'), 
                        :title => '', 
                        :icon => :info,
                        :buttons => ["OK"] 
                    })
                    isValid = false
                    WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
                end
            else
                results="ERR_NETWORK"
            end 
            if results == "PAYMENT_SUCESS"
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('SUCCESS_PAYRECEIVED'),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } )
            elsif results == "ERR_AGENT"
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('ERR_AGENTPAYMENT'),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } )
            elsif results == "ERR_NETWORK"
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORK'),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } )
            elsif results == "ERR_STP"
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('ERR_STP'),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } ) 
            elsif results == "CURR_RATE_REQ_ERROR  "
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('CURR_RATE_REQ_ERROR  '),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } )   
            elsif results == "TXN_NUM_REQ_ERROR"
                Alert.show_popup( {
                    :message => MobiSys::BrowserHelper.getLabel('TXN_NUM_REQ_ERROR'),
                    :title => '',
                    :icon => :info,
                    :buttons => ["OK"] } )                                                       
            elsif isValid
                htmlContent = "<!DOCTYPE html><html><body><form id='paymentSubmit' name='paymentSubmit' action='#{Application.getValue('online_server_url').value}/jsp/TPLoginUser.jsp?&redirectPage=..%2FPaymentGatewayInvoke.run' method='POST'><input type='hidden' name='userId' id='userId' value='#{$userId}'></input><input type='hidden' name='password' id='password' value='#{$userPassword}'></input><input type='hidden' name='fileName' id='fileName' value='#{inward.fileName}'></input></form></body></html><script>document.getElementById('paymentSubmit').submit();</script>"

                paymentFilePath = Rho::RhoFile.join(Rho::Application.userFolder, 'payment.html')
                file = File.open(paymentFilePath,"w")
                file.write(htmlContent)
                file.close

                System.open_url(paymentFilePath) 

                if @policy.isBackdatedFl.to_s == "YES"
                    @policy.policyCommencementDt = @policy.quotationDt
                else
                    @policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                if @policy.isBackdatedFl.to_s == "YES"
                    @policy.riskCommencementDt = @policy.quotationDt
                else
                    @policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end
                @policy.persistAll
            end               
            WebView.navigate(url_for :action => :showProposal, :id => @policy.object)
        else
            Alert.show_popup({
                :message => "Please resolve all warnings & sign before online payment.", 
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
            WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
        end
    end
    ##################################################################################################
    

    def captureSignature
        resetObjectMapping
        if @params['policyObj'].to_s != ''
            policyObj = @params['policyObj'] 
        else
            policyObj = @params['Policy']['object']
        end
        dbPolicy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        if @params['Policy'] && dbPolicy.statusCd != "ACCEPTED"
            newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            # Check for empty party objects and set them as removed
            newPolicy.PartyList.each do |party|
                setPartyDetails(party)
            end
            submitBeneficiaryAppointeeDetails(newPolicy)
            submitPaymentDetails(newPolicy)
            newPolicy.persistAll

            @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
            createPolicyProductInsured(@policy)
            primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            if primaryInsuredPolicyPartyRole
                if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                    primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                    primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
                else
                    primaryInsuredPolicyPartyRole.partySameAsCd = nil
                    insured = nil
                    @policy.PartyList.each do |party|
                        if party.roleCd == "PRIMARY"
                            insured = party 
                            break
                        end
                    end
                    primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
                end
            end
            submitRequirements if @params.has_key?('DocumentContainer')
            submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
            MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
            MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
        else
            # @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
            @policy = dbPolicy
        end
        
        @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
        if @signatureContainer.to_s == ""
            @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
            setObjectCount(@signatureContainer, 50)
            setObjectMapping(@signatureContainer, @signatureContainer.class.name)
        end
        @agentSign, @proposerSign, @insuredSign, @supplementarySigns = nil
        @agentSign, @proposerSign, @insuredSign, @supplementarySigns = MobiSys::SignatureUtil.getSignatures(@policy,@signatureContainer) if @signatureContainer
        if @agentSign.to_s != "" && @agentSign.signatureDt != ""
            @agentSign.signatureDt = getScreenDate(@agentSign.signatureDt)
        end
        if @proposerSign.to_s != "" && @proposerSign.signatureDt != ""
            @proposerSign.signatureDt = getScreenDate(@proposerSign.signatureDt)
        end
        if @insuredSign.to_s != "" && @insuredSign.signatureDt != ""
            @insuredSign.signatureDt = getScreenDate(@insuredSign.signatureDt)
        end
        if !@supplementarySigns.empty?
            @supplementarySigns.each do |supplementarySign|
                if supplementarySign.to_s != "" && supplementarySign.signatureDt != ""
                    supplementarySign.signatureDt = getScreenDate(supplementarySign.signatureDt)
                end
            end
        end

        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        if @errors.empty? && @params.has_key?('submit')
            @policy.uwDecisionCd = "COMPLETE"
            @policy.statusCd = "COMPLETE"
            @policy.persistAll
            WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
        elsif !@errors.empty? && !@params.has_key?('submit')
            Alert.show_popup({
                :message => getLabelValue('ERR_WARNINGRESOLVE',['signature']),
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
            WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
            redirect :action => "showProposal", :layout => :jazzLayout, :id => @policy.object.to_s, :query => {:submit => ''}
        else
            render :action => "captureSignature_Jazz", :layout => :jazzLayout
        end
    end
    ##################################################################################################


    def submitSignature
        policy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['SignatureContainer'])
        if signatureContainer.to_s != ""
            signatureContainer.ServiceSignatureList.each do |serviceSign|
                serviceSign.signatureDt = getDBDate(serviceSign.signatureDt)
                if serviceSign.signature.to_s != "" && !serviceSign.signature.to_s.start_with?('ZLIBCMP')
                    serviceSign.signature = serviceSign.signature.gsub!('data:image/png;base64,','')
                    original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSign.signature)
                    compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                    serviceSign.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                end
            end
            signatureContainer.persistAll
        end
        
        @errors = Hash.new
        MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, @errors)
        dbPolicy = Policy.loadObject(:first, :conditions => {:object => policy.object})
        unless dbPolicy.visitedTabs.to_s.include?('tab_signature')
            dbPolicy.visitedTabs = dbPolicy.visitedTabs.to_s + "," + 'tab_signature'
        end
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(dbPolicy.guid, dbPolicy.visitedTabs)
        if @errors.empty? && @errorTabs == "" && @incompleteTabs.empty?
            dbPolicy.signatureStatus = "SUCCESS"
            dbPolicy.statusCd = "SIGNED"
            dbPolicy.proposalSignedDt = Time.new.strftime("%F 00:00:00 %z")
            dbPolicy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
            dbPolicy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
            if dbPolicy.isBackdatedFl.to_s == "YES"
                dbPolicy.policyCommencementDt = dbPolicy.quotationDt
            else
                dbPolicy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end

            if dbPolicy.isBackdatedFl.to_s == "YES"
                dbPolicy.riskCommencementDt = dbPolicy.quotationDt
            else
                dbPolicy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end
        end
        dbPolicy.persistAll
        MobiSys::TrackLeadBO.updateTrackLead(dbPolicy)
        if @errors.empty?
            WebView.navigate(url_for :action => :showProposal, :id => dbPolicy.object.to_s, :query => {:submit => ''})
        else
            WebView.navigate(url_for :action => :captureSignature, :query => {:policyObj => dbPolicy.object.to_s, :submit => ''})
        end
    end
    ##################################################################################################


    #Method to submit policy and execute autoUW rules on the policy
    def executeAutoUW
        resetObjectMapping
        # Convert request params and merge with existing policy
        if @params.has_key?('id') && @params['id'] != ""
            if @params['id'].include? "{"
                policyObj = @params['id'][1..-1].chop 
            else
                policyObj = @params['id']
            end
        elsif @params.has_key?('formData')
            policyObj = @params['formData']['Policy']['object']
        else
            policyObj = @params['Policy']['object']
            newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            unless newPolicy.visitedTabs.to_s.include?(@params['currentTab'].to_s)
                newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['currentTab']
            end
            # Check for empty party objects and set them as removed
            newPolicy.PartyList.each do |party|
                setPartyDetails(party)
            end
            submitBeneficiaryAppointeeDetails(newPolicy)
            submitPaymentDetails(newPolicy)
            submitQuestionnaire(newPolicy)
            newPolicy.persistAll
        end

        @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        @policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY') if @policy.proposalNum.to_s == ""
        createPolicyProductInsured(@policy)
        primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
        if primaryInsuredPolicyPartyRole
            if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
            else
                primaryInsuredPolicyPartyRole.partySameAsCd = nil
                insured = nil
                @policy.PartyList.each do |party|
                    if party.roleCd == "PRIMARY"
                        insured = party 
                        break
                    end
                end
                primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
            end
        end
        submitPlanDetails(@policy)
        submitRequirements if @params.has_key?('DocumentContainer')
        submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
        submitSignatureTab(@policy) if @params.has_key?('SignatureContainer') && !@params.has_key?('QuestionContainer')
        MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)

        isValid = true
        policyNum = ""
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        isValid = false unless @errors.empty?

        if isValid
            if System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection

            end
            serviceDocumentList = []
            @policy.PartyList.each do |party|
                documentContainer = DocumentContainer.loadObject(
                    :first,
                    :conditions=>{
                        {:name=>'entityGuid'}=> party.guid,
                        {:name=>'policyGuid'}=> @policy.guid
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
                        if partydoc.acceptanceStatusCd != "RECEIVED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                            partydoc.imageCount = imageList.size
                            partydoc.acceptanceStatusCd = "RECEIVED"
                            partydoc.persistAll
                        end
                    end
                    serviceDocumentList.concat partyDocumentList
                end
            end
            # puts "before AUW----------#{@policy.hashForSync.to_json}"
            # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
            if @policy.statusCd.to_s != "UWCOMPLETE"
                autoUWRule = PolicyUtil::AutoUWUtil.new
                serviceDocumentList = autoUWRule.execute(@policy, serviceDocumentList)
                @policy.statusCd = "UWCOMPLETE"
                # puts "after AUW----------#{@policy.hashForSync.to_json}"
                # @policy.statusCd = "PENDINGSUBMIT" #temporary commented
                @facetData = getFacetData("result", @policy.baseProductSeq)
                @facetData[:uwType] = "TYPE1"
                overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                overallUWDecisionLookup.each do |overallUWDecisionCd|
                    if overallUWDecisionCd.cd == @policy.overallUWDecisionCd
                        @facetData[:uwType] = overallUWDecisionCd.additionalField2.to_s
                        break
                    end
                end
                if @facetData[:uwType].to_s == "TYPE1" || @facetData[:uwType].to_s == "TYPE2"
                    @policy.counterOfferDecisionCd = "ACCEPTED"
                    @policy.statusCd = "PAYMENTDONE" if !@policy.getGatewayFlag
                    @policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                end
                @policy.persistAll
            end
            # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
            if @facetData[:uwType] && (@facetData[:uwType].to_s == "TYPE3" || @facetData[:uwType].to_s == "TYPE4")
                @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
                if @signatureContainer.to_s == ""
                    @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
                end
        
                @counterOfferSignature = MobiSys::SignatureUtil.getCounterOfferSignature(@policy, @signatureContainer) if @signatureContainer
                if @counterOfferSignature.signatureDt.to_s != ""
                    @counterOfferSignature.signatureDt = getScreenDate(@counterOfferSignature.signatureDt.to_s)
                else
                    @counterOfferSignature.signatureDt = getScreenDate(Time.new.strftime("%F 00:00:00 %z").to_s)
                end
            end
            
            @facetData[:showResults] = true
            @exclusionList = []
            @coverageLoadingList = []
            @requirementList = []
            @uwDecisionCd = ""
            responseHash = {}
            @taskExceptionsList = Array.new

            processPolicyResult(@policy, serviceDocumentList)

            if @facetData[:uwType] == "TYPE4"
                @quotation = Quotation.loadObject(:first, :conditions => {:guid => @policy.quotationRefGuid})
            end

            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid, @policy.visitedTabs)

        else
            Alert.show_popup({
                :message => "Please resolve all warnings & sign before policy submission.", 
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
            WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
        end

        render :action => :outputAUW_Jazz, :layout => :jazzLayout
    end
    ##################################################################################################


    def processPolicyResult(policy = nil, serviceDocumentList = nil , responseHash = {})
        if policy == nil && responseHash.has_key?(Policy.onlineClassName) && responseHash[Policy.onlineClassName].to_s != ""
            policyList = Rho::JSON.parse(responseHash[Policy.onlineClassName])
            if policyList != nil
            policyList.each do |pol|
                    policy = Policy.loadObject(:first,:conditions=>{:proposalNum=>pol["proposalNum"]})
                    @facetData[:uwType] = "TYPE1"
                    overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                    overallUWDecisionLookup.each do |overallUWDecisionCd|
                        if overallUWDecisionCd.cd == policy.overallUWDecisionCd
                            @facetData[:uwType] = overallUWDecisionCd.additionalField2.to_s
                            break
                        end
                    end

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
                                if partydoc.acceptanceStatusCd != "RECEIVED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                    partydoc.imageCount = imageList.size
                                    partydoc.acceptanceStatusCd = "RECEIVED"
                                    partydoc.persistAll
                                end
                            end
                            serviceDocumentList.concat partyDocumentList
                        end
                    end
                end
            end
        end
        if policy
            uwDecisionLookup = Lookupvalue.getValue("DECISIONMASTER")
            if uwDecisionLookup
                uwDecisionLookup.each do |uwDecisionCd|
                    if uwDecisionCd.cd == policy.uwDecisionCd
                        @uwDecisionCd = getLabelValue(uwDecisionCd.desc)
                        if uwDecisionCd.additionalField1.to_s != ""
                            @staticMessage = getLabelValue(uwDecisionCd.additionalField1)
                            @facetData[:showResults] = false
                        end
                        break
                    else
                        @uwDecisionCd = policy.uwDecisionCd.to_s
                    end
                end
            end


            if @facetData[:showResults]
                overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                overallUWDecisionLookup.each do |overallUWDecisionCd|
                    if overallUWDecisionCd.cd == policy.overallUWDecisionCd
                        overallUWDecisionCd.additionalField1.to_s.split(",").each do |panel|
                            @facetData[panel.to_sym] = true
                        end
                        break
                    end
                end


                #Hash setup for Exclusion Panel
                if @facetData[:PolicyUWResultExclusion]
                    policy.PolicyResultList.each do |policyResult|
                        next if policyResult.decisionCd != "ACCEPTEDEXCLUSION"
                        tempResult = {}
                        tempResult[:event]           = policyResult.event.to_s
                        tempResult[:benefit]         = policyResult.benefit.to_s
                        tempResult[:cause]           = policyResult.cause.to_s
                        tempResult[:icdCd]           = policyResult.icdCd.to_s
                        tempResult[:reasonCd]        = policyResult.reasonCd.to_s
                        tempResult[:remarksKey]      = policyResult.remarksKey.to_s
                        tempResult[:exclusionTypeCd] = policyResult.exclusionTypeCd.to_s
                        loadingTypeCdLookup = Lookupvalue.find(
                            :first,
                            :conditions => {
                                {:name => 'key'} => "LOADINGTYPE",
                                {:name => 'cd'} => policyResult.exclLoadingTypeCd.to_s, 
                            },
                            :op => 'AND'
                        )
                        if loadingTypeCdLookup
                            tempResult[:exclLoadingTypeCd] = getLabelValue(loadingTypeCdLookup.desc.to_s)
                        else
                            tempResult[:exclLoadingTypeCd] = getLabelValue(policyResult.exclLoadingTypeCd.to_s)
                        end
                        policyResult.exclValue = policyResult.exclValue.to_f if policyResult.exclValue.class.to_s == "BigDecimal"
                        tempResult[:exclValue] = getMaskedValue(policyResult, "exclValue")
                        periodTypeCdLookup = Lookupvalue.find(
                            :first,
                            :conditions => {
                                {:name => 'key'} => "PERIODTYPE",
                                {:name => 'cd'} => policyResult.exclPeriodTypeCd.to_s,  
                            },
                            :op => 'AND'
                        )
                        if periodTypeCdLookup
                            tempResult[:exclPeriodTypeCd] = getLabelValue(periodTypeCdLookup.desc.to_s)
                        else
                            tempResult[:exclPeriodTypeCd] = getLabelValue(policyResult.exclPeriodTypeCd.to_s)
                        end
                        policyResult.exclDuration = policyResult.exclDuration.to_f if policyResult.exclDuration.class.to_s == "BigDecimal"
                        tempResult[:exclDuration] = getMaskedValue(policyResult, "exclDuration")
                        tempResult[:exclPeriodUnit] = policyResult.exclPeriodUnit.to_s
                        tempResult[:partyName] = getLabelValue(policy.getPartyByGuid(policyResult.partyRefGuid).titleCd.to_s) + " " + policy.getPartyByGuid(policyResult.partyRefGuid).firstName1.to_s + " " " " + policy.getPartyByGuid(policyResult.partyRefGuid).lastName1.to_s
                        policy.PolicyProductList.each do |policyProduct|
                            if policyProduct.guid == policyResult.policyProductRefGuid
                                tempResult[:productName] = MobiSys::ProductUtil.getProduct(policyProduct.productSeq).shortName.to_s
                                break
                            end
                        end
                        
                        @exclusionList.push(tempResult)
                    end
                end


                #Hash setup for Coverage & Loading Panel
                if @facetData[:PolicyUWResultLoading]
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.PolicyProductExtraList.size > 0
                            tempResult = {}
                            productMaster = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                            tempResult[:productName] = getLabelValue(productMaster.shortName.to_s)

                            offlinePlan = nil
                            productMaster.OfflineFacetList.each do |facet|
                                if facet.facetId == 'PLANOPTION'
                                    facet.OfflinePlanOptionList.each do |offlinePlanOption|
                                        if offlinePlanOption.optionCd == policyProduct.productPlanOptionCd
                                            offlinePlan = offlinePlanOption
                                            break
                                        end
                                    end
                                    break
                                end
                            end                            
                            if offlinePlan
                                tempResult[:productPlanOptionCd] = getLabelValue(offlinePlan.description.to_s)
                            else
                                tempResult[:productPlanOptionCd] = getLabelValue(policyProduct.productPlanOptionCd.to_s)
                            end
                            policyProduct.baseSumAssured    = policyProduct.baseSumAssured.to_f if policyProduct.baseSumAssured.class.to_s == "BigDecimal"
                            tempResult[:baseSumAssured]     = getMaskedValue(policyProduct, "baseSumAssured")
                            policyProduct.productTerm       = policyProduct.productTerm.to_f if policyProduct.productTerm.class.to_s == "BigDecimal"
                            tempResult[:productTerm]        = getMaskedValue(policyProduct, "productTerm")
                            policyProduct.premiumPayingTerm = policyProduct.premiumPayingTerm.to_f if policyProduct.premiumPayingTerm.class.to_s == "BigDecimal"
                            tempResult[:premiumPayingTerm]  = getMaskedValue(policyProduct, "premiumPayingTerm")
                            policyProduct.modalPremium      = policyProduct.modalPremium.to_f if policyProduct.modalPremium.class.to_s == "BigDecimal"
                            tempResult[:modalPremium]       = getMaskedValue(policyProduct, "modalPremium")
                            policyProduct.extraPremium      = policyProduct.extraPremium.to_f if policyProduct.extraPremium.class.to_s == "BigDecimal"
                            tempResult[:extraPremium]       = getMaskedValue(policyProduct, "extraPremium")
                            tempResult[:partyName] = getLabelValue(policy.getMainInsured(policyProduct).titleCd.to_s) + " " + policy.getMainInsured(policyProduct).firstName1.to_s + " " " " + policy.getMainInsured(policyProduct).lastName1.to_s

                            tempResult[:policyProductExtra] = []
                            policyProduct.PolicyProductExtraList.each do |policyProductExtra|
                                tempExtra = {}
                                extraTypeCdLookup = Lookupvalue.find(
                                    :first,
                                    :conditions => {
                                        {:name => 'key'} => "PRODUCTEXTRATYPE",
                                        {:name => 'cd'} => policyProductExtra.extraTypeCd.to_s, 
                                    },
                                    :op => 'AND'
                                )
                                if extraTypeCdLookup
                                    tempExtra[:extraTypeCd] = getLabelValue(extraTypeCdLookup.desc.to_s)
                                else
                                    tempExtra[:extraTypeCd] = getLabelValue(policyProductExtra.extraTypeCd.to_s)
                                end

                                loadingTypeCdLookup = Lookupvalue.find(:first,
                                    :conditions => {
                                        {:name => 'key'} => "LOADINGTYPE",
                                        {:name => 'cd'} => policyProductExtra.loadingTypeCd.to_s,   
                                    },
                                    :op => 'AND'
                                )
                                if loadingTypeCdLookup
                                    tempExtra[:loadingTypeCd] = getLabelValue(loadingTypeCdLookup.desc.to_s)
                                else
                                    tempExtra[:loadingTypeCd] = getLabelValue(policyProductExtra.loadingTypeCd.to_s)
                                end
                                policyProductExtra.extraFlatAmt         = policyProductExtra.extraFlatAmt.to_f if policyProductExtra.extraFlatAmt.class.to_s == "BigDecimal"
                                tempExtra[:extraFlatAmt]                = getMaskedValue(policyProductExtra, "extraFlatAmt")
                                policyProductExtra.extraFlatDuration    = policyProductExtra.extraFlatDuration.to_f if policyProductExtra.extraFlatDuration.class.to_s == "BigDecimal"
                                tempExtra[:extraFlatDuration]           = getMaskedValue(policyProductExtra, "extraFlatDuration")
                                policyProductExtra.extraPercent         = policyProductExtra.extraPercent.to_f if policyProductExtra.extraPercent.class.to_s == "BigDecimal"
                                tempExtra[:extraPercent]                = getMaskedValue(policyProductExtra, "extraPercent")
                                policyProductExtra.extraPercDuration    = policyProductExtra.extraPercDuration.to_f if policyProductExtra.extraPercDuration.class.to_s == "BigDecimal"
                                tempExtra[:extraPercDuration]           = getMaskedValue(policyProductExtra, "extraPercDuration")
                                tempResult[:policyProductExtra].push(tempExtra)
                            end
                            
                            @coverageLoadingList.push(tempResult)
                        end
                    end
                end

                #Hash setup for Requirement Panel
                if @facetData[:PolicyUWResultDocument]
                    if serviceDocumentList != nil
                        serviceDocumentList.each do |serviceDocument|
                            if serviceDocument.isAutoGeneratedFl == 'YES_UW'
                                tempResult = {}
                                documentCat = DocumentCategory.find(
                                    :first,
                                    :conditions => {
                                        {:name => "categoryCd"} => serviceDocument.docCategoryCd
                                    }
                                )

                                document = Document.find(
                                    :first,
                                    :conditions => {
                                        {:name => "documentCd"} => serviceDocument.documentCd
                                    }
                                )
                                if documentCat
                                    tempResult[:docCategoryCd] = documentCat.categoryDesc.to_s
                                else
                                    tempResult[:docCategoryCd] = serviceDocument.docCategoryCd.to_s
                                end

                                if document
                                    tempResult[:documentCd] = document.documentDesc.to_s
                                else
                                    tempResult[:documentCd] = serviceDocument.documentCd.to_s
                                end

                                party = Party.loadObject(
                                    :first,
                                    :conditions => {
                                        {:name => "guid"} => serviceDocument.partyGuid
                                    },
                                    :loadChild => 'false'
                                )
                                tempResult[:partyName] = getLabelValue(party.titleCd.to_s) + " " + party.firstName1.to_s + " " " " + party.lastName1.to_s
                                tempResult[:documentStatusCd] = serviceDocument.acceptanceStatusCd
                                @requirementList.push(tempResult)
                                documentContainer = DocumentContainer.loadObject(
                                    :first,
                                    :conditions=>{
                                        {:name=>'entityGuid'}=> party.guid,
                                        {:name=>'policyGuid'}=> policy.guid
                                    },
                                    :op => 'AND',
                                    :loadChild => 'false'
                                )
                                documentContainer.addServiceDocument(serviceDocument)
                                documentContainer.persistAll
                            end
                        end
                    end
                end
            end
        end
        #Hash setup for Task Exception Panel
        taskExceptionClassName = TaskException.onlineClassName
        if responseHash.has_key?(taskExceptionClassName) && responseHash[taskExceptionClassName].to_s != ""
            taskExceptions = Rho::JSON.parse(responseHash[taskExceptionClassName])
            
            if taskExceptions != nil
                taskExceptions.each do |taskException|
                   exception = MobiSys::MobiSysEntitySchema.from_hash('TaskException', taskException) 
                   @taskExceptionsList.push exception
                end
            end
        end
    end


    def sendCounterOfferResponse
        if @params['action'] == "createQuotationCopy"
            policy = MobiSys::BrowserHelper.convertToObjectWithMerge('Policy', @params['Policy'])
            originalQuotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
            newQuotation = MobiSys::PolicyBO.convertToQuotation(policy)
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
            policy.quotationRefGuid = newQuotation.uniqueKey
            policy.quotationRefNum = newQuotation.quotationRefNum
            policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
            policy.persistAll

            render :string => {"quotationRefNum"=>newQuotation.quotationRefNum, "viewIllustration"=>url_for({:controller => :Quotation, :action => :viewIllustration, :id=>newQuotation.object}), "acceptIllustration"=>url_for({:controller => :Quotation, :action => :acceptIllustration, :id=>newQuotation.object})}.to_json
        else
            policy = MobiSys::BrowserHelper.convertToObjectWithMerge('Policy', @params['Policy'])
            uwType = @params['uwType'].to_s
            redirectQuery = {:submit => ''}

            if uwType == "TYPE3" || uwType == "TYPE4"
                if policy.counterOfferDecisionCd == "DECLINED"
                    policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                elsif policy.counterOfferDecisionCd.to_s == ""
                    policy.counterOfferDecisionCd = ""
                    policy.counterOfferAcceptDt = ""
                    redirectQuery = {:sym_current_Tab => 'tab_coverage'}
                end
            elsif uwType == "TYPE2"
                policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                redirectQuery = {:sym_current_Tab => 'tab_requirement'}
            else
                policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
            end

            if @params.has_key?('SignatureContainer') && @params['SignatureContainer'].to_s != ""
                signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['SignatureContainer'])
                capturedSignatureCount = 0
                signatureContainer.ServiceSignatureList.each do |serviceSign|
                    capturedSignatureCount += 1 if serviceSign.removed.to_s == ""
                    serviceSign.signatureDt = getDBDate(serviceSign.signatureDt)
                    if serviceSign.signature.to_s != "" && !serviceSign.signature.to_s.start_with?('ZLIBCMP')
                        serviceSign.signature = serviceSign.signature.gsub!('data:image/png;base64,','')
                        original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSign.signature)
                        compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                        serviceSign.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                    end
                end
                signatureContainer.persistAll if capturedSignatureCount > 0
            end

            # @errors = Hash.new
            # MobiSys::PolicyBO.validateCounterOfferResponse(policy, signatureContainer, @errors)
            if policy.counterOfferDecisionCd == "ACCEPTED" && !policy.getGatewayFlag
                policy.statusCd = "PAYMENTDONE"
            end
            policy.persistAll
            WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => redirectQuery)
        end
    end
    ##################################################################################################


    #Method to display result of policy underwriting
    def showPolicyResult
        resetObjectMapping
        # Convert request params and merge with existing policy
        if @params.has_key?('id') && @params['id'] != ""
            if @params['id'].include? "{"
                policyObj = @params['id'][1..-1].chop 
            else
                policyObj = @params['id']
            end
        end

        @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        serviceDocumentList = []
        @policy.PartyList.each do |party|
            documentContainer = DocumentContainer.find(
                :first,
                :conditions=>{
                    {:name=>'entityGuid'}=> party.guid,
                    {:name=>'policyGuid'}=> @policy.guid
                },
                :op => 'AND',
                :loadChild => 'false'
            )
            if documentContainer
                partyDocumentList = ServiceDocument.find(
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
                    if partydoc.acceptanceStatusCd != "RECEIVED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                        partydoc.imageCount = imageList.size
                        partydoc.acceptanceStatusCd = "RECEIVED"
                        partydoc.persistAll
                    end
                end
                serviceDocumentList.concat partyDocumentList
            end
        end

        @facetData = getFacetData("result", @policy.baseProductSeq)
        @facetData[:showResults] = true
        @exclusionList = []
        @coverageLoadingList = []
        @requirementList = []
        @uwDecisionCd = ""
        responseHash = {}

        @facetData[:uwType] = "TYPE1"
        overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
        overallUWDecisionLookup.each do |overallUWDecisionCd|
            if overallUWDecisionCd.cd == @policy.overallUWDecisionCd
                @facetData[:uwType] = overallUWDecisionCd.additionalField2.to_s
                break
            end
        end

        if @facetData[:uwType] && (@facetData[:uwType].to_s == "TYPE3" || @facetData[:uwType].to_s == "TYPE4")
            @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
            if @signatureContainer.to_s == ""
                @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
            end
    
            @counterOfferSignature = MobiSys::SignatureUtil.getCounterOfferSignature(@policy, @signatureContainer) if @signatureContainer
            if @counterOfferSignature.signatureDt.to_s != ""
                @counterOfferSignature.signatureDt = getScreenDate(@counterOfferSignature.signatureDt.to_s)
            else
                @counterOfferSignature.signatureDt = getScreenDate(Time.new.strftime("%F 00:00:00 %z").to_s)
            end
        end

        processPolicyResult(@policy, serviceDocumentList)

        if @facetData[:uwType] == "TYPE4"
            @quotation = Quotation.loadObject(:first, :conditions => {:guid => @policy.quotationRefGuid})
        end

        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid, @policy.visitedTabs)

        render :action => :outputAUW_Jazz, :layout => :jazzLayout
    end
    ##################################################################################################


    def reUploadImages
        if @params['id'] != ""
            if @params['id'].include? "{"
                id = @params['id'][1..-1].chop 
            else
                id = @params['id']
            end
        else
            id = @params['Policy']['object']
        end
        @policy = Policy.loadObject(:first, :conditions => {:object => id })
        unless $currentProduct
            $currentProduct = MobiSys::ProductUtil.getProduct(@policy.baseProductSeq)
        end
        @tabToBeLoaded = "tab_requirement"
        if (!@params.has_key?('mode') || (@params.has_key?('mode') && @params['mode'] != "FETCH")) && @params.has_key?('DocumentContainer')
            submitRequirements
        end
        @navbarIds, @navbarLabels = getNavbarDetails('tab_requirement', @policy)
        if  @params['sym_navbar'].to_s != ''
            partyGuid = @params['sym_navbar'].sub("#{@tabToBeLoaded}-",'')
            getLifeRequirements(partyGuid)
        else
            if @navbarIds.split(',').first.to_s != ''
                getLifeRequirements(@navbarIds.split(',').first)
            end
        end
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        render :action => :reUploadRequirements_Jazz, :layout => :jazzLayout
    end
    ##################################################################################################


    def reUploadingDocumentsToServer
        MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache
        errors = Hash.new
        $globalContextObjectMap = {}
        $taskExceptionHash = []
        $currentValidationMetadata = nil
        $currentTabId = nil
        policyObject = @params['policyObject']
        @policy = Policy.loadObject(:first, :conditions=>{:object=> policyObject})
        MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)

        if $rhoconfig[:contextBasedMetadata]
            classToFind = "#{@policy.class.name}DO"
            contextMasterGeneratedArray = []
            if $contextMasterCache.has_key?(classToFind.to_sym)
              contextMasterList = $contextMasterCache[classToFind.to_sym]
              contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,@policy)
            end
            MobiSys::Validation.processValidContexts(@policy.hashForSync, contextMasterGeneratedArray, "PolicySet")
            validationContexts = $globalContextObjectMap[@policy.guid]
        else
            PolicySet.setObject(@policy)
            validationContexts = PolicySet::ValidationContexts
        end
        MobiSys::Validation.validationLoop(@policy.hashForSync, validationContexts, errors, "PolicySet")

        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
        db.start_transaction
        $taskExceptionHash.each do |taskException|
            taskException.persistAll
        end
        db.commit
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        if @errors.empty?
            partyImageList = Array.new
            serviceDocumentRequirementArray = Array.new
            @policy.PartyList.each do |party|
                documentContainer = DocumentContainer.loadObject(
                    :first,
                    :conditions=>{
                        {:name=>'entityGuid'}=> party.guid,
                        {:name=>'policyGuid'}=> @policy.guid
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
                    partyDocumentList.each do|partydoc|
                        imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                        partyImageList.concat imageList if imageList.size > 0

                        # if imageList.size > 0 && partydoc.documentCd.to_s != ""
                            # partydoc.imageCount = imageList.size
                            # partydoc.persist
                        # end
                    end
                    serviceDocumentRequirementArray.concat partyDocumentList
                end
                serviceDocumentRequirementArray.each do |serviceDoc|
                    serviceDoc.uploadStatus = "DONE"
                    serviceDoc.persistAll
                end
                partyImageList.each do |image|
                    image.uploadStatus = "DONE"
                    image.persistAll
                end
            end
            @policy = Policy.loadObject(:first, 
                :conditions=>{:object=> policyObject},
                :select => ['guid','policyNum','proposalNum'],
                :loadChild => false
            )
            
            syncEntities = Hash.new
            syncEntities[Policy.onlineClassName] = @policy if @policy
            syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
            syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
            begin
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if !has_network
                    Alert.show_popup( {
                        :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORK'),
                        :title => '',
                        :icon => :info,
                        :buttons => ["OK"] } )
                    WebView.navigate(url_for :action => :showProposal, :id => @policy.object)
                end
                transactionSuccessfull = false
                responseHash = PolicyUtil::ApplicationUtil.invokeOnlineService(syncEntities,"/callPolicyService.run",true)
                if responseHash != nil && !responseHash.empty?
                    transactionSuccessfull = true # if callPolicyService is successfull
                    #Hash setup for Task Exception Panel
                    taskExceptionClassName = TaskException.onlineClassName
                    if responseHash.has_key?(taskExceptionClassName) && responseHash[taskExceptionClassName].to_s != ""
                        taskExceptions = Rho::JSON.parse(responseHash[taskExceptionClassName])
                        @taskExceptionsList = Array.new
                        if taskExceptions != nil
                            taskExceptions.each do |taskException|
                               exception = MobiSys::MobiSysEntitySchema.from_hash('TaskException', taskException) 
                               @taskExceptionsList.push exception
                            end
                        end
                    end

                    @facetData = Hash.new
                    @facetData[:showResults] = false
                    @reUploadImages = true
                else
                    transactionSuccessfull = false # callPolicyService failed 
                end
                if transactionSuccessfull
                    render :action => :output_Jazz, :layout => :jazzLayout
                else
                    Alert.show_popup({
                        :message => getLabelValue('SERVERERROR'), 
                        :title => '', 
                        :icon => :info,
                        :buttons => ["OK"] 
                    })
                    WebView.navigate(url_for :action => :reUploadImages, :id => @policy.object)
                end
            rescue StandardError => se
                puts se.backtrace
                Alert.show_popup({
                    :message => getLabelValue('SERVERERROR'), 
                    :title => '', 
                    :icon => :info,
                    :buttons => ["OK"] 
                })
            end
        else
            WebView.navigate(url_for :action => :reUploadImages, :id => @policy.object)
        end
    end
    ##################################################################################################


    def getSignature
        @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
        if @signatureContainer.to_s == ""
            @signatureContainer = SignatureContainer.new(:entityGuid => @policy.guid, :entityTypeCd => @policy.class.name.to_s)
            setObjectCount(@signatureContainer, 50)
            setObjectMapping(@signatureContainer, @signatureContainer.class.name)
        end
        @agentSign, @proposerSign, @insuredSign, @supplementarySign = nil
        @agentSign, @proposerSign, @insuredSign, @supplementarySigns = MobiSys::SignatureUtil.getSignatures(@policy,@signatureContainer) if @signatureContainer
        if @agentSign.to_s != "" && @agentSign.signatureDt != ""
            @agentSign.signatureDt = getScreenDate(@agentSign.signatureDt)
        end
        if @proposerSign.to_s != "" && @proposerSign.signatureDt != ""
            @proposerSign.signatureDt = getScreenDate(@proposerSign.signatureDt)
        end
        if @insuredSign.to_s != "" && @insuredSign.signatureDt != ""
            @insuredSign.signatureDt = getScreenDate(@insuredSign.signatureDt)
        end
        if !@supplementarySigns.empty?
            @supplementarySigns.each do |supplementarySign|
                if supplementarySign.to_s != "" && supplementarySign.signatureDt != ""
                    supplementarySign.signatureDt = getScreenDate(supplementarySign.signatureDt)
                end
            end
        end
    end
    ##################################################################################################


    def submitSignatureTab(policy)
        signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['SignatureContainer'])
        if signatureContainer.to_s != ""
            signatureContainer.ServiceSignatureList.each do |serviceSign|
                serviceSign.signatureDt = getDBDate(serviceSign.signatureDt)
                if serviceSign.signature.to_s != "" && !serviceSign.signature.to_s.start_with?('ZLIBCMP')
                    serviceSign.signature = serviceSign.signature.gsub!('data:image/png;base64,','')
                    original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSign.signature)
                    compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                    serviceSign.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                end
            end
            signatureContainer.persistAll
            errors = Hash.new
            MobiSys::PolicyBO.validateEappSignature_Jazz(policy, signatureContainer, errors)
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, policy.visitedTabs)
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                policy.signatureStatus = "SUCCESS"
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
            end
            return errors
        end
    end
    ##################################################################################################


    def captureAgentDeclaration
        resetObjectMapping
        if @params['policyObj'].to_s != ''
            policyObj = @params['policyObj'] 
        else
            policyObj = @params['Policy']['object']
        end
        
        if @params['Policy'] && !@params.has_key?('mode') || (@params.has_key?('mode') && @params['mode'] != "FETCH")
            newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            unless newPolicy.visitedTabs.to_s.include?(@params['sym_current_Tab'].to_s)
                newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['sym_current_Tab']
            end
            # Check for empty party objects and set them as removed
            newPolicy.PartyList.each do |party|
                setPartyDetails(party)
            end
            submitBeneficiaryAppointeeDetails(newPolicy)
            submitPaymentDetails(newPolicy)
            if @params['currentTab'] != "tab_signature" && (newPolicy.statusCd.to_s == "SIGNED" || newPolicy.statusCd.to_s == "UWCOMPLETE" || newPolicy.statusCd.to_s == "COMPLETE" || newPolicy.statusCd.to_s == "ACCEPTED" || newPolicy.statusCd.to_s == "PENDING")
                MobiSys::SignatureUtil.clearSignatures(newPolicy)
                newPolicy.proposalSignedDt = ""
                newPolicy.uwDecisionCd = "PENDING"
                newPolicy.statusCd = "PENDING"
            end
            newPolicy.persistAll

            @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
            createPolicyProductInsured(@policy)
            primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            if primaryInsuredPolicyPartyRole
                if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                    primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                    primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
                else
                    primaryInsuredPolicyPartyRole.partySameAsCd = nil
                    insured = nil
                    @policy.PartyList.each do |party|
                        if party.roleCd == "PRIMARY"
                            insured = party 
                            break
                        end
                    end
                    primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
                end
            end
            submitRequirements if @params.has_key?('DocumentContainer')
            submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
            MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
            MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
            if @params.has_key?('SignatureContainer')
                submitSignatureTab(@policy) 
                @policy.persistAll
            end
        else
            @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        end
        
        getAgentQuestion()
       
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        if @errors.empty? && @errorTabs == "" && @incompleteTabs.empty?
            if @params.has_key?('submit')
                @policy.statusCd = "DECLARATIONCOMPLETE"
                @policy.persistAll
                WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
            else
                render :action => "captureDeclaration_Jazz", :layout => :jazzLayout
            end
        else
            if @params.has_key?('submit')  || @errorTabs.to_s.include?("tab_agentDeclaration")   
                render :action => "captureDeclaration_Jazz", :layout => :jazzLayout
            else
                Alert.show_popup({
                    :message => getLabelValue('ERR_WARNINGRESOLVE',['declaration']),
                    :title => '', 
                    :icon => :info,
                    :buttons => ["OK"] 
                })
                WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
            end
        end
    end
    ##################################################################################################


    def submitAgentDeclaration
        policy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
        container = MobiSys::BrowserHelper.convertToObject('QuestionContainer', @params['QuestionContainer'])
        container.persistAll
        if @params['SignatureContainer'].to_s != ''
            signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['SignatureContainer'])
            signatureContainer.ServiceSignatureList.each do |serviceSign|
                serviceSign.signatureDt = getDBDate(serviceSign.signatureDt) if serviceSign.signatureDt.to_s != ""
                if serviceSign.signature.to_s != "" && !serviceSign.signature.to_s.start_with?('ZLIBCMP')
                    serviceSign.signature = serviceSign.signature.gsub!('data:image/png;base64,','')
                    original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSign.signature)
                    compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                    serviceSign.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                end
            end
            signatureContainer.persistAll
        end
        @errors = Hash.new
        MobiSys::PolicyBO.validateEappAgentDeclaration_Jazz(policy, @errors)
        
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, policy.visitedTabs)
        unless policy.visitedTabs.to_s.include?('tab_agentDeclaration')
            policy.visitedTabs = policy.visitedTabs.to_s + "," + 'tab_agentDeclaration'
        end
        
        if @errors.empty? && @errorTabs == "" && @incompleteTabs.empty?
            policy.statusCd = "DECLARATIONCOMPLETE"
            policy.persistAll
            MobiSys::TrackLeadBO.updateTrackLead(policy)
            WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => {:submit => ''})
        else
            policy.persistAll
            MobiSys::TrackLeadBO.updateTrackLead(policy)
            WebView.navigate(url_for :action => :captureAgentDeclaration, :query => {:policyObj => policy.object.to_s, :submit => ''})
        end
    end
    ##################################################################################################


    def requiredQuickLinks(policy)
        quickLinks = Hash.new
        if policy.insuranceTypeCd == 'TRAVEL'
            quickLinks['SUBMIT'] = 'javascript: eappSubmit();'
        else
            if policy.quotationRefGuid.to_s != ""
                quotation = Quotation.loadObject(:first, :loadChild => false, :conditions=>{:guid=>policy.quotationRefGuid})
                if quotation
                    if quotation.fnaId.to_s != ""
                        leadFNA = LeadFNA.find(:first, :loadChild => false, :conditions=>{:fnaId=>quotation.fnaId})
                        quickLinks['viewFNA'] = "#{url_for :controller => :LeadFNA, :action => :showFNA, :id=> leadFNA.object}" if leadFNA
                    end
                    quickLinks['viewQuotation'] = "#{url_for :controller => :Quotation, :action => :show, :id=> quotation.object}"
                    quickLinks['VIEWILLUSTRATION'] = "#{url_for :controller => :Quotation, :action => :viewIllustration, :id=> quotation.object}"
                end
            end
            uwAccepted = true
            uwAccepted = false if $rhoconfig[:fuw_applicable] && ((policy.counterOfferDecisionCd != "ACCEPTED") || policy.overallUWDecisionCd == "DECLINED")

            if policy.policyNum.to_s == ""
                quickLinks['EAPPPREVIEW'] = 'javascript: previewEapp();'
            end
            if $rhoconfig[:fuw_applicable]
                if policy.statusCd.to_s == "SIGNED" || policy.statusCd.to_s == "ACCEPTED"
                    quickLinks['evaluatePolicy'] = 'javascript: executeAutoUWSubmit();'
                elsif policy.uwDecisionCd.to_s != "" && policy.uwDecisionCd.to_s != "PENDING"
                    quickLinks['policyResult'] = 'javascript: showPolicyResult();'
                end
            end
            if (policy.statusCd.to_s == "UWCOMPLETE" || policy.statusCd.to_s == "PAYMENTFAILED" || policy.statusCd.to_s == "SIGNED") && policy.getGatewayFlag && uwAccepted
                quickLinks['paymentGateway'] = 'javascript: paymentGateway();'
            end
            if policy.getGatewayFlag && (policy.statusCd.to_s == "PAYMENTDONE" || policy.statusCd.to_s == "DECLARATIONCOMPLETE") && policy.counterOfferDecisionCd != "DECLINED" 
                quickLinks['checkPaymentStatus'] = 'javascript: checkPaymentStatus();'
            end
            # if $rhoconfig[:captureSignatureInTab]
            if ["PAYMENTDONE","DECLARATIONCOMPLETE"].include?(policy.statusCd.to_s) || (["UWCOMPLETE","PAYMENTFAILED"].include?(policy.statusCd.to_s) && policy.counterOfferDecisionCd == "DECLINED") || (policy.statusCd.to_s == "SIGNED" && !policy.getGatewayFlag)
                quickLinks['declaration'] = 'javascript: captureAgentDeclaration();'
            end
            # else
                # quickLinks['signature'] = 'javascript: captureSignature();'
            # end
            if policy.statusCd.to_s == "DECLARATIONCOMPLETE"
                quickLinks['SUBMIT'] = 'javascript: eappSubmit();'
            end
            if policy.policyNum.to_s != ""
                quickLinks['DOWNLOADPDF'] = 'javascript: genPdfFile();'
            end
        end

        quickLinkLabels = quickLinks.keys.join(",")
        quickLinkActions = quickLinks.values.join(",")

        return quickLinkLabels,quickLinkActions
    end
    ##################################################################################################

    def travelPremiumComputation(policy)
        premiumMatrix = {}
        if @offlineApplicationEnvironment == 'PRODUCTION'
            @productIdHash.each do |key, productDetails|
                productDetails.each do |each_product|
                    planList = @productPlanOptionHash[each_product[:id].to_s.to_sym]
                    planList.each do |plan|
                        clonedPolicy = policy.cloneObject
                        quotePartyList = clonedPolicy.PartyList
                        
                        if clonedPolicy.getBaseProduct.nil?
                            policyProduct = PolicyProduct.new
                            policyProduct.productTypeCd = 'PLAN'
                            clonedPolicy.addPolicyProduct(policyProduct)
                        else
                            policyProduct = clonedPolicy.getBaseProduct
                        end
                        policyProduct.productId = each_product[:key]
                        policyProduct.productSeq = each_product[:id]
                        policyProduct.productFamilyCd = key
                        policyProduct.productPlanOptionCd = plan[:key]
                        policyProduct.premiumPayingTerm = 1
                        policyProduct.paymentTypeCd = "SINGLE"
                        policyProduct.paymentFrequencyCd = "SINGLE"
                        if policy.startDt.to_s != '' && policy.endDt.to_s != ''
                            startDt = Date.strptime(getScreenDate(policy.startDt), "%d/%m/%Y")
                            endDt = Date.strptime(getScreenDate(policy.endDt), "%d/%m/%Y")
                            policyProduct.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
                        end
                        clonedQuotation = MobiSys::PolicyBO.convertToQuotation(clonedPolicy)
                        $taskExceptionHash = []
                        MobiSys::ProductBO.validatePolicy(clonedQuotation, clonedPolicy, "", Hash.new)
                        $taskExceptionHash = nil

                        baseProduct = clonedPolicy.getBaseProduct
                        premiumMatrix[each_product[:id].to_sym] = Hash.new if !premiumMatrix[each_product[:id].to_sym].is_a?(Hash)
                        premiumMatrix[each_product[:id].to_sym][plan[:key].to_sym] = [baseProduct.baseSumAssured, baseProduct.baseAnnualPremium]
                    end
                end
            end
        else
            @productIdHash.each do |key, productDetails|
                productDetails.each do |each_product|
                    planList = @productPlanOptionHash[each_product[:id].to_s.to_sym]
                    planList.each do |plan|
                        clonedPolicy = policy.cloneObject
                        quotePartyList = clonedPolicy.PartyList
                        
                        if clonedPolicy.getBaseProduct.nil?
                            policyProduct = PolicyProduct.new
                            policyProduct.productTypeCd = 'PLAN'
                            clonedPolicy.addPolicyProduct(policyProduct)
                        else
                            policyProduct = clonedPolicy.getBaseProduct
                        end
                        policyProduct.productId = each_product[:key]
                        policyProduct.productSeq = each_product[:id]
                        policyProduct.productFamilyCd = key
                        policyProduct.productPlanOptionCd = plan[:key]
                        policyProduct.premiumPayingTerm = 1
                        policyProduct.paymentTypeCd = "SINGLE"
                        policyProduct.paymentFrequencyCd = "SINGLE"
                        if policy.startDt.to_s != '' && policy.endDt.to_s != ''
                            startDt = Date.strptime(getScreenDate(policy.startDt), "%d/%m/%Y")
                            endDt = Date.strptime(getScreenDate(policy.endDt), "%d/%m/%Y")
                            policyProduct.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
                        end
                        clonedQuotation = MobiSys::PolicyBO.convertToQuotation(clonedPolicy)
                        $taskExceptionHash = []
                        MobiSys::ProductBO.validatePolicy(clonedQuotation, clonedPolicy, "", Hash.new)
                        $taskExceptionHash = nil

                        baseProduct = clonedPolicy.getBaseProduct
                        premiumMatrix[each_product[:id].to_sym] = Hash.new if !premiumMatrix[each_product[:id].to_sym].is_a?(Hash)
                        premiumMatrix[each_product[:id].to_sym][plan[:key].to_sym] = [baseProduct.baseSumAssured, baseProduct.baseAnnualPremium]
                    end
                end
            end
        end
        return premiumMatrix
    end

    def getPremiumSummary
        html = ""
        @premiumSummaryHtml = premiumSummary(@policy, html)
    end
    
    def premiumSummary(policy, html)
        summaryPopupView = policy.insuranceTypeCd != 'TRAVEL'
        riders = policy.getRiders
        planColumn = false
        planColumn = true if riders.select { |key, rider| key.planCode.to_s != "" }.size > 0

        summaryResult = Array.new
        
        policy.PolicyProductList.each do |policy_product|
            next if policy_product.removed.to_s != ''
            policyProductSummary = Hash.new
            policyProductSummary[:sum_assured] = getMaskedValue(policy_product, "baseSumAssured")
            policyProductSummary[:modal_premium] = getMaskedValue(policy_product,"modalPremium")

            policy_party = policy.getParty(policy_product)
            policyProductSummary[:fullname] = policy_party.getFullName.to_s.strip.upcase if policy_party

            product_object = MobiSys::ProductUtil.getProduct(policy_product.productSeq)
            if product_object
                policyProductSummary[:product] = getLabelValue(product_object.longName.to_s.strip)

                product_object.OfflineFacetList.each do |offlineFacet|
                    if offlineFacet.facetId == 'PLANOPTION'
                        offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                            if offlinePlanOption.optionCd == policy_product.productPlanOptionCd.to_s
                                policyProductSummary[:plan] = getLabelValue(offlinePlanOption.description.to_s.strip)
                                planColumn = true
                            end
                        end
                    end
                end
            end
            summaryResult << policyProductSummary
        end
        # code for output preferences starts
        $currencyFormat = $rhoconfig[:number_format_pattern]

        # code for output preferences ends
        html << render(:partial => 'SummaryPopup_Jazz', :locals => { :summaryResult => summaryResult,:planColumn => planColumn, :summaryPopupView => summaryPopupView})
        return html 
    end

    def getTravelDetails
        @policyHolder = @policy.getParty("PROPOSER")
        if @policy && @policyHolder != nil
            @policyHolderPolicyPartyRole = @policy.getPolicyPartyRole("PROPOSER")
        else
            setObjectCount(@policy, 100)
            setObjectMapping(@policy, @policy.class.name)
            @policyHolder = Party.new(:roleCd => "PROPOSER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@policyHolder)
            @policyHolderPolicyPartyRole = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => @policyHolder.uniqueKey)
            @policy.addPolicyPartyRole(@policyHolderPolicyPartyRole)
        end

        @policyHolderHomeAddress = @policyHolder.getPartyAddress("RESIDENTIAL", true)
        
        @policyHolderContactHome = @policyHolder.getPartyContact("RESIDENTIAL", true)
        @policyHolderContactOffice = @policyHolder.getPartyContact("OFFICE", true) 
        @policyHolderContactMobile = @policyHolder.getPartyContact("MOBILE", true)
        
        @policyHolderEmail = @policyHolder.getPartyEmail(true)
        #converting db date to screen date
        @policyHolder.birthDt = getScreenDate(@policyHolder.birthDt) if @policyHolder.birthDt != nil || @policyHolder.birthDt != ""
        classname = "PolicyProposerDO"

        @renderPolicyHolderAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyHolderHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyHolderContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyHolderHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyHolderOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyHolderMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyHolderEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        @supplementaryLife = Array.new
        @supplementaryLife = @policy.getPartyList("SUPPLEMENTARY")
        @suplementaryInsuredCount = 5
        if @policy && !@supplementaryLife.empty?
            @suplementaryInsuredCount = @supplementaryLife.length
        end
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
        @supPolicyProductHM = {}

        if @supplementaryProductFacet
            @supPolicyProductCount = 200
            supPolicyProducts = @policy.getPolicyProductByProductTypeCd('PLANMULTI')
            supPolicyProducts.each do |qp|
                @supPolicyProductHM[qp.insuredPartyRefGuid] = qp
            end
        end
    end

    def getTravelPaymentDetails
        createPolicyProductInsured(@policy)
        @policyHolder = @policy.getParty("PROPOSER")
        primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
        if primaryInsuredPolicyPartyRole
            if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
            else
                primaryInsuredPolicyPartyRole.partySameAsCd = nil
                insured = nil
                @policy.PartyList.each do |party|
                    if party.roleCd == "PRIMARY"
                        insured = party 
                        break
                    end
                end
                primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
            end
        end
    end

    # method to save payment status
    def submitTravelPaymentDetails
        policyObj = @params['policy_object']
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        cardNumber = @params['cardNumber']
        messageLabel = ""
        if cardNumber == "1111-2222-3333-4444"
            policy.statusCd = "PAYMENTDONE"
            messageLabel = "Your payment is successful. Please note transaction no. 457891230 for future reference."
        else
            policy.statusCd = "PAYMENTFAILED"
            messageLabel = "PAYMENTFAILED"
            Alert.show_popup({
                :message => getLabelValue(messageLabel,[]),
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
        end
        policy.persistAll
        WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => {:submit => ''})
    end

    def addMoreTraveller(policy=nil, party=nil, suplementaryInsuredCount=nil, policyProduct=nil, supPolicyProductCount=nil)
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')

        if party != nil && policy != nil && suplementaryInsuredCount != nil
            @travellerCount = suplementaryInsuredCount
            @suplementaryInsuredCount = suplementaryInsuredCount + 5

            @policy = policy
            @party = party
            @policy.getPolicyPartyRoleList("SUPPLEMENTARY").each do |policyPartyRole|
                if policyPartyRole.refGuid == @party.guid
                    @policyPartyRole = policyPartyRole
                end
            end
            if @supplementaryProductFacet && policyProduct != nil
                @supPolicyProductCount = supPolicyProductCount
                @policyProduct = policyProduct
                @policyProductInsured = @policyProduct.PolicyProductInsuredList[0]
            end
        else
            policyObject = @params['policyObject']
            @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>policyObject})
            @suplementaryInsuredCount = @params['suplementaryInsuredCount']
            @travellerCount = @params['displayCount']

            @party = Party.new(:roleCd => "SUPPLEMENTARY", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@party)
            @policyPartyRole = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => @party.uniqueKey)
            @policy.addPolicyPartyRole(@policyPartyRole)

            if @supplementaryProductFacet
                @supPolicyProductCount = @params['supPolicyProductCount']
                @policyProduct = PolicyProduct.new
                @policyProduct.productTypeCd = "PLANMULTI"
                @policyProduct.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.baseAnnualPremium = 0.0
                @policyProduct.baseSumAssured = 0.0
                @policyProduct.modalPremium = 0.0
                @policy.addpolicyProduct(@policyProduct)
                @policyProductInsured = PolicyProductInsured.new
                @policyProductInsured.roleCd = 'SUPPLEMENTARY'
                @policyProductInsured.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.addPolicyProductInsured(@policyProductInsured)
            end
        end
        
        #converting db date to screen date
        @party.birthDt = getScreenDate(@party.birthDt) if @party.birthDt != nil || @party.birthDt != ""
          
        setObjectCount(@policy, @suplementaryInsuredCount)
        setObjectMapping(@policy, @policy.class.name) 

        html = ""
        html << render(:partial => 'addMoreTravellerDetails_Jazz')
        return html    
    end


    def getBasicVehicleDetails
        @policy.policyCommencementDt = getScreenDate(@policy.policyCommencementDt) if @policy.policyCommencementDt.to_s != ""
    end


    def getVehicleInsuredDetails
        @policyHolder = @policy.getParty("PROPOSER")
        if @policy && @policyHolder != nil
            @policyHolderPolicyPartyRole = @policy.getPolicyPartyRole("PROPOSER")
        else
            @policyHolder = Party.new(:roleCd => "PROPOSER", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@policyHolder)
            @policyHolderPolicyPartyRole = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => @policyHolder.uniqueKey)
            @policy.addPolicyPartyRole(@policyHolderPolicyPartyRole)
        end

        @policyHolderHomeAddress = @policyHolder.getPartyAddress("RESIDENTIAL", true)
        
        @policyHolderContactHome = @policyHolder.getPartyContact("RESIDENTIAL", true)
        @policyHolderContactOffice = @policyHolder.getPartyContact("OFFICE", true) 
        @policyHolderContactMobile = @policyHolder.getPartyContact("MOBILE", true)
        
        @policyHolderEmail = @policyHolder.getPartyEmail(true)
        #converting db date to screen date
        @policyHolder.birthDt = getScreenDate(@policyHolder.birthDt) if @policyHolder.birthDt != nil || @policyHolder.birthDt != ""
        classname = "PolicyProposerDO"

        @renderPolicyHolderAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPolicyHolderHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPolicyHolderContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPolicyHolderHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPolicyHolderOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPolicyHolderMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPolicyHolderEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        # Insured objects start-----------------
        if @policy
            @primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
        end

        if @primaryInsuredPolicyPartyRole
            if @primaryInsuredPolicyPartyRole.partySameAsCd.to_s != ""
                @primaryInsured = Party.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
                @policy.addParty(@primaryInsured)
            else
                @primaryInsured = @policy.getParty("PRIMARY")
            end
        else  
            @primaryInsured = Party.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@primaryInsured)
            @primaryInsuredPolicyPartyRole = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => @primaryInsured.uniqueKey, :partySameAsCd => "")
            @policy.addPolicyPartyRole(@primaryInsuredPolicyPartyRole)
        end
        if @primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
            @primaryInsuredPolicyPartyRole.partySameAsCd = "YES" 
        end
        @primaryInsuredHomeAddress = @primaryInsured.getPartyAddress("RESIDENTIAL", true)
        
        @primaryInsuredContactHome = @primaryInsured.getPartyContact("RESIDENTIAL", true)
        @primaryInsuredContactOffice = @primaryInsured.getPartyContact("OFFICE", true) 
        @primaryInsuredContactMobile = @primaryInsured.getPartyContact("MOBILE", true)
        
        @primaryInsuredEmail = @primaryInsured.getPartyEmail(true)

        #converting db date to screen date
        @primaryInsured.birthDt = getScreenDate(@primaryInsured.birthDt) if @primaryInsured.birthDt != nil || @primaryInsured.birthDt != ""

        @proposerExists = true if @policy.getParty("PROPOSER")
        classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO"
        @renderPrimaryInsuredAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderPrimaryInsuredHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderPrimaryInsuredContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderPrimaryInsuredHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderPrimaryInsuredOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderPrimaryInsuredMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderPrimaryInsuredEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        # Supplementary object starts---------------------
        @supplementaryLife = Array.new
        @supplementaryLife = @policy.getPartyList("SUPPLEMENTARY")
        @suplementaryInsuredCount = 5
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
        @supPolicyProductHM = {}

        if @supplementaryProductFacet
            @supPolicyProductCount = 200
            supPolicyProducts = @policy.getPolicyProductByProductTypeCd('PLANMULTI')
            supPolicyProducts.each do |qp|
                @supPolicyProductHM[qp.insuredPartyRefGuid] = qp
            end
        end
    end


    def addMoreDriver(policy=nil, party=nil, suplementaryInsuredCount=nil, policyProduct=nil, supPolicyProductCount=nil)
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')

        if party != nil && policy != nil && suplementaryInsuredCount != nil
            @driverCount = suplementaryInsuredCount
            @suplementaryInsuredCount = suplementaryInsuredCount + 5
            @policy = policy
            @party = party
            @policy.getPolicyPartyRoleList("SUPPLEMENTARY").each do |policyPartyRole|
                if policyPartyRole.refGuid == @party.guid
                    if policyPartyRole.partySameAsCd == 'PROPOSER'
                        policyPartyRole.partySameAsCd = "YES" 
                        @party = Party.new(:roleCd => "SUPPLEMENTARY", :partyTypeCd => "INDIVIDUAL")
                        @policy.addParty(@party)
                    end
                    @policyPartyRole = policyPartyRole
                end
            end

            if @supplementaryProductFacet && policyProduct != nil
                @supPolicyProductCount = supPolicyProductCount
                @policyProduct = policyProduct
                @policyProductInsured = @policyProduct.PolicyProductInsuredList[0]
            end
        else
            policyObject = @params['policyObject']
            @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>policyObject})
            @suplementaryInsuredCount = @params['suplementaryInsuredCount']
            @driverCount = @params['displayCount']

            @party = Party.new(:roleCd => "SUPPLEMENTARY", :partyTypeCd => "INDIVIDUAL")
            @policy.addParty(@party)
            @policyPartyRole = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => @party.uniqueKey)
            @policy.addPolicyPartyRole(@policyPartyRole)

            if @supplementaryProductFacet
                @supPolicyProductCount = @params['supPolicyProductCount']
                @policyProduct = PolicyProduct.new
                @policyProduct.productTypeCd = "PLANMULTI"
                @policyProduct.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.baseAnnualPremium = 0.0
                @policyProduct.baseSumAssured = 0.0
                @policyProduct.modalPremium = 0.0
                @policy.addpolicyProduct(@policyProduct)
                @policyProductInsured = PolicyProductInsured.new
                @policyProductInsured.roleCd = 'SUPPLEMENTARY'
                @policyProductInsured.insuredPartyRefGuid = @party.uniqueKey
                @policyProduct.addPolicyProductInsured(@policyProductInsured)
            end
            setObjectCount(@policy, @suplementaryInsuredCount)
            setObjectMapping(@policy, @policy.class.name)
        end
        
        @homeAddress = @party.getPartyAddress("RESIDENTIAL", true)
        
        @partyContactHome = @party.getPartyContact("RESIDENTIAL", true)
        @partyContactOffice = @party.getPartyContact("OFFICE", true) 
        @partyContactMobile = @party.getPartyContact("MOBILE", true)
        
        @partyEmail = @party.getPartyEmail(true)

        #converting db date to screen date
        @party.birthDt = getScreenDate(@party.birthDt) if @party.birthDt != nil || @party.birthDt != ""

        classname = "PolicySupplementaryLifeDO"
        
        @renderSupplementaryAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
        @renderSupplementaryHomeAddressPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
        @renderSupplementaryContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
        @renderSupplementaryHomeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
        @renderSupplementaryOfficeContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
        @renderSupplementaryMobileContactPanel = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
        @renderSupplementaryEmailPanel = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')

        html = ""
        html << render(:partial => 'addMoreDriverDetails_Jazz')
        return html    
    end

    def filterParty
        policy = Policy.loadObject(:first, :conditions => {:object => @params['policyObject']})
        roleCd = @params['roleCd']
        paymentInstructionTypeCd = @params['paymentInstructionTypeCd']
        parties = {}
        if roleCd == 'OTHER'
            parties = policy.getPayerParty(paymentInstructionTypeCd)
            if parties.roleCd == 'PAYER'
                partyName = (parties.firstName1.to_s=="" && parties.lastName1.to_s=="") ? (parties.firstName2.to_s + " " + parties.lastName2.to_s) : (parties.firstName1.to_s + " " + parties.lastName1.to_s)
                parties = {parties.guid => partyName}
            end
        elsif roleCd == 'AGENT'
            agentId = policy.baseAgentId 
            parties = {policy.guid => agentId}
        else
            party = Party.find(:all, :conditions => {:parentKey => policy.object})
            party.each do |party|
                if party.roleCd == roleCd
                    if party.partyTypeCd == "ORGANIZATION" 
                         partyName = (party.corporateName1.to_s=="") ? (party.corporateName2.to_s) : (party.corporateName1.to_s) 
                    else
                        partyName = (party.firstName1.to_s=="" && party.lastName1.to_s=="") ? (party.firstName2.to_s + " " + party.lastName2.to_s) : (party.firstName1.to_s + " " + party.lastName1.to_s)
                    end
                    parties[party.guid] = partyName
                end
            end
        end
        @selectedValue = @params['fieldValue']
        @selectLookup = []
        partyLookup = Lookupvalue.new
        partyLookup.cd = ""
        partyLookup.desc = getLabelValue("select")
        @selectLookup[0] = partyLookup
        parties.each do |guid, fullname|
           partyLookup = Lookupvalue.new
           partyLookup.cd = guid
           partyLookup.desc = fullname
           @selectLookup.push(partyLookup)
        end
        render :action => :filterLookupData, :layout => false
    end

    ##################################################################################################

    #Method to show EAPP Preview
    def previewEapp
        policyObject = @params['Policy']['object']
        resetObjectMapping
        
        if @params['Policy'] && !@params.has_key?('mode') || (@params.has_key?('mode') && @params['mode'] != "FETCH")
            newPolicy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            unless newPolicy.visitedTabs.to_s.include?(@params['sym_current_Tab'].to_s)
                newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + @params['sym_current_Tab']
            end
            # Check for empty party objects and set them as removed
            newPolicy.PartyList.each do |party|
                setPartyDetails(party)
            end
            submitBeneficiaryAppointeeDetails(newPolicy)
            submitPaymentDetails(newPolicy)
            if @params['currentTab'] != "tab_signature" && (newPolicy.statusCd.to_s == "SIGNED" || newPolicy.statusCd.to_s == "UWCOMPLETE" || newPolicy.statusCd.to_s == "COMPLETE" || newPolicy.statusCd.to_s == "ACCEPTED" || newPolicy.statusCd.to_s == "PENDING")
                MobiSys::SignatureUtil.clearSignatures(newPolicy)
                newPolicy.proposalSignedDt = ""
                newPolicy.uwDecisionCd = "PENDING"
                newPolicy.statusCd = "PENDING"
            end
            newPolicy.persistAll

            @policy = Policy.loadObject(:first,:conditions=>{:object=>policyObject})
            createPolicyProductInsured(@policy)
            primaryInsuredPolicyPartyRole = @policy.getPolicyPartyRole("PRIMARY")
            if primaryInsuredPolicyPartyRole
                if primaryInsuredPolicyPartyRole.partySameAsCd == "YES" || primaryInsuredPolicyPartyRole.partySameAsCd == "PROPOSER"
                    primaryInsuredPolicyPartyRole.partySameAsCd = "PROPOSER"
                    primaryInsuredPolicyPartyRole.refGuid = @policy.getParty("PROPOSER").guid if @policy.getParty("PROPOSER")
                else
                    primaryInsuredPolicyPartyRole.partySameAsCd = nil
                    insured = nil
                    @policy.PartyList.each do |party|
                        if party.roleCd == "PRIMARY"
                            insured = party 
                            break
                        end
                    end
                    primaryInsuredPolicyPartyRole.refGuid = insured.uniqueKey if insured
                end
            end
            submitRequirements if @params.has_key?('DocumentContainer')
            submitAgentQuestionDetails if @params.has_key?('QuestionContainer')
            MobiSys::CommonUtil.clearTaskExceptionList(@policy.guid)
            MobiSys::PolicyBO.validateAllEappTabs_Jazz(@policy)
            if @params.has_key?('SignatureContainer')
                submitSignatureTab(@policy) 
                @policy.persistAll
            end
        else
            @policy = Policy.loadObject(:first, :conditions=>{object: policyObject})
        end
        
        if @policy.visitedTabs.to_s.include?('tab_signature')
            @errors = Hash.new
            signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => @policy.guid}) 
            MobiSys::PolicyBO.validateEappSignature_Jazz(@policy, signatureContainer, @errors) if signatureContainer
        end
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@policy.guid,@policy.visitedTabs)
        getSignature if $rhoconfig[:captureSignOnEappPreview]
        # if @errors.empty? && @errorTabs == "" && @incompleteTabs.empty? #errors_before_preview.uniq.include?(false)
            $policyIO = MobiSys::IO::PolicyIO.new
            $policyIO.baseDO = @policy.cloneObject
            MobiSys::UIGenUtilEapp.findTemplatePageMapping($policyIO,"EAPP")
            MobiSys::UIGenUtilEapp.getHtmlStringandGeneratePDF(true, $policyIO)
            render :action => :EAPPPreview_Jazz, :layout => :jazzLayout
        # else
        #     WebView.navigate(url_for :action => :showProposal, :id => @policy.object.to_s, :query => {:submit => ''})
        # end
    end
    ##################################################################################################


    def acceptEappPreview
        if @params.has_key?('Policy')
            policyObject = @params['Policy']['object']
            policy = MobiSys::BrowserHelper.convertToObject('Policy', @params['Policy'])
            policy.persistAll
        else
            policyObject = @params['id'][1..-1].chop
        end
        
        newPolicy = Policy.loadObject(:first, :conditions=>{object: policyObject})

        MobiSys::CommonUtil.clearTaskExceptionList(newPolicy.guid)
        MobiSys::PolicyBO.validateAllEappTabs_Jazz(newPolicy)
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(newPolicy.guid,newPolicy.visitedTabs)


        if @errors.empty? && @errorTabs == "" && @incompleteTabs.empty? 
            if $rhoconfig[:captureSignOnEappPreview] && @params.has_key?('captureSignatureOnOutput')
                # @params['SignatureContainer'] = @params['formData']['SignatureContainer']
                unless newPolicy.visitedTabs.to_s.include?('tab_signature')
                    newPolicy.visitedTabs = newPolicy.visitedTabs.to_s + "," + 'tab_signature'
                end
                @errors = submitSignatureTab(newPolicy)
                newPolicy.statusCd = "SIGNED" if newPolicy.signatureStatus == "SUCCESS"
                newPolicy.persistAll 

            else
                newPolicy.statusCd = "ACCEPTED"
                newPolicy.persistAll
            end

            if  ((newPolicy.statusCd == "SIGNED") || (newPolicy.statusCd == "ACCEPTED"))
                if $rhoconfig[:fuw_applicable] #check flag here
                    executeSubmit(false)
                else
                    newPolicy.statusCd = "PAYMENTDONE" if !newPolicy.getGatewayFlag && newPolicy.signatureStatus == "SUCCESS"
                    newPolicy.persistAll
                    MobiSys::TrackLeadBO.updateTrackLead(newPolicy)
                    WebView.navigate(url_for :action => :showProposal, :id => newPolicy.object.to_s, :query => {:submit => ''})
                end
            else
                MobiSys::TrackLeadBO.updateTrackLead(newPolicy)
                @policy = newPolicy 
                $policyIO = MobiSys::IO::PolicyIO.new
                $policyIO.baseDO = @policy.cloneObject
                MobiSys::UIGenUtilEapp.findTemplatePageMapping($policyIO,"EAPP")
                MobiSys::UIGenUtilEapp.getHtmlStringandGeneratePDF(true, $policyIO)
                if !@errors.empty?
                    render :action => :EAPPPreview_Jazz, :layout => :jazzLayout
                else
                    WebView.navigate(url_for :action => :showProposal, :id => newPolicy.object.to_s, :query => {:submit => ''})
                end
            end
        else
            MobiSys::TrackLeadBO.updateTrackLead(newPolicy)
            WebView.navigate(url_for :action => :showProposal, :id => newPolicy.object.to_s, :query => {:submit => ''})
        end
    
    end
    ##################################################################################################

    # method to check payment status from online
    def checkPaymentStatus
        policyObj = @params['policy_object']
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        if policy.statusCd == "PAYMENTDONE"
            messageLabel = "Your payment is successful. Please note transaction no. 457891230 for future reference."
        else
            messageLabel = "PAYMENTFAILED"
        end

        return render :string =>getLabelValue(messageLabel,[]).to_s
    end
    ##################################################################################################


    # method to save payment status
    def submitPaymentGateway
        policyObj = @params['policy_object']
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObj})
        cardNumber = @params['cardNumber']
        messageLabel = ""
        if cardNumber == "1111-2222-3333-4444"
            policy.statusCd = "PAYMENTDONE"
            messageLabel = "Your payment is successful. Please note transaction no. 457891230 for future reference."
        else
            policy.statusCd = "PAYMENTFAILED"
            messageLabel = "PAYMENTFAILED"
            Alert.show_popup({
                :message => getLabelValue(messageLabel,[]),
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
        end
        policy.persistAll
        MobiSys::TrackLeadBO.updateTrackLead(policy)
        WebView.navigate(url_for :action => :showProposal, :id => policy.object.to_s, :query => {:submit => ''})
    end
    ##################################################################################################

    def captureSignatureOnOutput(signatureObject,policy,signatureCount)
        @signatureObject = signatureObject
        @signatureCount = signatureCount
        @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid}) 
        if @signatureContainer.to_s == ""
            @signatureContainer = SignatureContainer.new(:entityGuid => policy.guid, :entityTypeCd => policy.class.name.to_s)
            setObjectCount(@signatureContainer, signatureCount)
            setObjectMapping(@signatureContainer, @signatureContainer.class.name)
        end
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid,policy.visitedTabs)
        @signature = @signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.guid == @signatureObject.guid}.first if @signatureContainer

        html = ""
        html << render(:partial => 'captureSignatureOnOutput')
    end

    def genPdfFile
        policyObject = @params['policy_object']
        policy = Policy.loadObject(:first,:conditions=>{:object=>policyObject})
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            onlineServer = Application.getValue('online_server_url').value
            onlineServerUrl = "#{onlineServer}/GeneratePolicyPDF.run?PolicyNum=#{policy.proposalNum}"
            response = Rho::AsyncHttp.get(
                :url => onlineServerUrl,
                :headers => {"username"=>$userId,"password"=>$userPassword},
                :ssl_verify_peer => false
            )

            fileName = "#{policy.proposalNum}.pdf"

            Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
            downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
            Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
            filePath = File.join(downloadFolder, fileName)
            File.delete(filePath) if File::exist?(filePath)
            url = Application.getValue('online_server_url').value + "/GetPolicyPDF.run"
            Rho::AsyncHttp.download_file(
                :url => url,
                :filename => filePath,
                :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName},
                :callback => '/app/Policy/eappPreviewPdfdownload',
                :callback_param => "fileName=#{fileName}&policyObject=#{policy.object}",
                :ssl_verify_peer => false)
        else
            Alert.show_popup( {
                :message => getLabelValue('ERR_NETWORK'),
                :title => '',
                :icon => :alert,
                :buttons => ["OK"],
                :callback => WebView.navigate(url_for :action => :showProposal, :query => {:submit => ''}, :id => policy.object)
            } )
        end
    end


    def eappPreviewPdfdownload
        if @params['status'] == 'ok' and @params['http_error'] != "404" and @params['http_error'] != "500"
            Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
            downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
            Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
            filePath = File.join(downloadFolder, @params['fileName'])
            System.open_url filePath
        else
            Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
                :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
                :buttons=>["OK"]})
        end
        WebView.navigate("/app/Policy/{#{@params['policyObject']}}/showProposal")
    end

    def getPincodeCityStateCountryLookups
  
        countryCd = @params['countryCd']
        pinCode = @params['pinCode']
        @option = @params['option']

        @districtLookUps = Array.new
        @cityLookUps = Array.new

        districtCityLookup = PincodeCityStateCountryMapping.loadObject(
            :all,
            :conditions => {
                { :name => 'countryCd' }=> countryCd,
                { :name => 'pinCode' }=> pinCode,
                :op => 'AND'
            }
        )
    
        districtCityLookup.each do |distCity|
            districtLookup = Lookupvalue.new
            districtLookup.cd = distCity.stateCd.to_s
            districtLookup.desc = distCity.stateDesc.to_s
            @districtLookUps.push(districtLookup)

            cityLookup = Lookupvalue.new
            cityLookup.cd = distCity.cityCd.to_s
            cityLookup.desc = distCity.cityDesc.to_s
            @cityLookUps.push(cityLookup)
        end

        @districtLookUps.uniq!{|district| district.desc}
        @cityLookUps.uniq!{|city| city.desc}

            if @option == "district"
                @selectLookup = @districtLookUps
            else
                @selectLookup = @cityLookUps
            end
        render :action => :LookupData, :layout => false
    end

    def filterNomineeParty
        policy = Policy.loadObject(:first, :conditions => {:object => @params['policyObject']})
        nomineeLookUp = Lookupvalue.loadObject(:all, :conditions => {:key => "PARTYSAMEAS"})
        party = Party.find(:all, :conditions => {:parentKey => policy.object})
        parties = []
        party.each do |party|
            nomineeLookUp.each do|nominee|
                if (party.roleCd.to_s == nominee.cd.to_s || nominee.cd == "OTHER")
                    parties << nominee
                end
            end
        end
        @selectedValue = @params['fieldValue']
        @selectLookup = []
        partyLookup = Lookupvalue.new
        partyLookup.cd = ""
        partyLookup.desc = getLabelValue("select")
        @selectLookup[0] = partyLookup
        parties.uniq.each do |role|
           partyLookup = Lookupvalue.new
           partyLookup.cd = role.cd
           partyLookup.desc = role.desc
           @selectLookup.push(partyLookup)
        end
        render :action => :filterLookupData, :layout => false
    end

    def deletePolicy
        if @params['deleteCheck'].to_s != ""
            @params['deleteCheck'].each do |selectedPolicyId|
                policy = Policy.loadObject( :first, :conditions => { :object => selectedPolicyId } )
                MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
                policy.delete if policy

                inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                inward.delete if inward

                container = QuestionContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
                if container
                    container.each do |question_container|
                        question_container.delete   if question_container
                    end
                end

                container = DocumentContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
                if container
                    container.each do|document_container|
                        document_container.ServiceDocumentList.each do |service_document|
                            imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>service_document.uniqueKey})
                            if imageList
                                imageList.each do |image|
                                    image.delete if image
                                end
                            end
                            document_container.delete if document_container
                        end
                    end
                end

                container = SignatureContainer.loadObject(:all,:condition=>{{:name=>'entityGuid'}=>policy.guid})
                if container
                    container.each do|signature_container|
                        signature_container.delete if signature_container
                    end
                end
            end
        end
        WebView.navigate("#{url_for :controller => :Policy, :action => :searchProposal}")
    end

end
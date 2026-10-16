require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Quotation/quotation_b_o'
require 'Quotation/quotation_util'
require 'Quotation/quotation_service'
require 'Quotation/UIGenUtil'
require 'Quotation/QuoteIllustration'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'TrackLead/track_lead_b_o'
require 'Quotation/Solver'
require 'ostruct'
require 'CommonModules/sym_template_util'
require 'erb'

class QuotationController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::SymTemplateUtil

    def initialize
        # logInfo "~~~in quotation rest initialize"
        super(MobiSys::IO::QuotationIO.new, "Quotation")
        @listLookupsToBeFiltered = []
        @listLookupsToBeFiltered << "CURRENCYMASTER"
        #@listLookupsToBeFiltered << "PLANOPTION"
        @listLookupsToBeFiltered << "FUND"
        @listLookupsToBeFiltered << "PREMIUMTYPE"
        @listLookupsToBeFiltered << "FREQUENCY"
        @listLookupsToBeFiltered << "RIDERPRODUCT"
    end

    def process
        # logInfo "~~~in quotation process"
        #Add executeLife code here for initializin quot_product
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct()
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
       
        if baseProduct.nil?
            baseProduct = QuotationProduct.new
            baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, quotation)
            quotation.addQuotationProduct(baseProduct)
        elsif baseProduct.productSeq.to_s == ""
            baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, quotation)
        end

        if $currentProduct
            baseProduct.product = $currentProduct
        else
            baseProduct.product = Product.new
        end

        #check if any party attributes have changed then need to check if product is still applicable
        if (!@baseIO.additionalData || !@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") || (@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") && @baseIO.additionalData['TRIGGERCHANGEPLAN'].to_s != "YES"))
            # MobiSys::QuotationUtil.checkProductApplicable(quotation)
        end

        if @baseIO.baseDO.proposerLASame.to_s == 'YES' || @baseIO.baseDO.proposerLASame.to_s == "COPYFROMINSURED"
            @baseIO.baseDO.proposerLASame = "COPYFROMINSURED"
        else
            @baseIO.baseDO.proposerLASame = "NO"
        end
        @baseIO.baseDO.QuotationPartyList.each do |quotationParty|
            if  quotationParty.visitedTabs.to_s == ""
                quotationParty.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationParty.roleCd)
            end
        end
        @baseIO.baseDO.QuotationProductList.each do|quotationProduct|
            if quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs =  MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
            end
        end 

        MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
        # saveValidate
        saveModel = @saveModel != nil ? @saveModel : true
        if quotation.action.to_s == ""
            quotation.action = "Save"
        end
        MobiSys::QuotationService.saveValidate(quotation,saveModel)
        MobiSys::QuotationService.populateMultiLife(quotation)
        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.entityTypeCd = "QUOTATION"
    end

    def fetch(id)
        # logInfo "~~~@baseIO in fetch:#{@baseIO}"
        quotation = Quotation.loadObject(:first, :conditions => {:object => id})
        # if quotation == nil
        #     raise "Invalid Id #{id}"
        # end
        @baseIO.baseDO = quotation
    end

    def init
        # logInfo "~~~~formData n quotation init:"
        $currentProduct = nil
        $rhoconfig[:moduleForProductValidations] = "Quotation"
    end

    def productFilteringImpl(id)

        render :string => "index base_api_controller" 
    end

    def getApplicableProducts
        p "insidegetapplicabelproducts***********"
        parsedData = parseRequestBodyParams
        p "parseData2========#{parsedData}"
        responseHash = {}
        data = {}
        # @entityHash = {}
        # @metadataHash = {}
        # @lookupHash = {}
        # isMetadataRequired = true
        # if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
        #   isMetadataRequired = false
        # end
        fetch(@params["id"]) if @params.has_key?("id")
        p "after fetch**************"
        @offlineApplicationEnvironment,@productFamilyList,@productIdList,@productPlanOptionList = MobiSys::ProductUtil.getApplicableProductsForApi(@baseIO.baseDO)
        data["applicationEnvironment"] =  @offlineApplicationEnvironment
        data["productFamilyList"] = @productFamilyList
        p "data======#{data}"
        p "@baseIO.baseDO.getBasePlan========#{@baseIO.baseDO.getBasePlan.inspect}"
        selectedId = @baseIO.baseDO.getBasePlan.productId if @baseIO.baseDO.getBasePlan 
        if selectedId.to_s != ""
            familyKey, productList = @productIdList.find { |key, list| list.any? { |product| product[:cd] == selectedId } }
            if productList
                sortedList = productList.partition { |product| product[:cd] == selectedId }.flatten
                @productIdList[familyKey] = sortedList
            end
        end

        data["productList"] = @productIdList
        # data["productVersionHash"] = @productVersionHash
        data["planOptionList"] = @productPlanOptionList
        responseHash['data'] = data
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        
        render :string => responseHash.to_json
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
            if birthDt != nil and commencementDt != ""
                ageCalculationBasis = MobiSys::ProductUtil::LASTBIRTHDAY
                companyFacetAgeCalculationBasis = CompanyFacet.find(
                    :first,
                    :conditions => {
                        { :name => 'facetCd' } => 'AGECALCULATIONBASIS'
                    }
                )
                if companyFacetAgeCalculationBasis && companyFacetAgeCalculationBasis.actionValue.to_s != ""
                    ageCalculationBasis = companyFacetAgeCalculationBasis.actionValue.to_s
                end
                age = MobiSys::ProductUtil.getAge(birthDt, ageCalculationBasis, commencementDt)
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

    def getProductTerm
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        termArray = MobiSys::QuotationService.getProductTerm(@baseIO.baseDO)
        tempLookup = []
        termArray.each do |lookup|
            tempHash = {}
            tempHash["cd"] = lookup.cd
            tempHash["desc"] = lookup.desc
            tempLookup.push(tempHash)
        end
        responseHash = {}
        responseHash['data'] = {}
        responseHash['data']['productTerm'] = tempLookup
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def getPremiumPayingTerm(id,parsedData)
        ppTermArray = MobiSys::QuotationService.getProductTerm(@baseIO.baseDO)
        tempLookup = []
        ppTermArray.each do |lookup|
            tempHash = {}
            tempHash["cd"] = lookup.cd
            tempHash["desc"] = lookup.desc
            tempLookup.push(tempHash)
        end
        responseHash = {}
        responseHash['data'] = {}
        responseHash['data']['premiumPayingTerm'] = tempLookup
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def calculatePremium(id,parsedData)
        MobiSys::QuotationService.calculatePremium(@baseIO.baseDO)
    end

    def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata = nil)
        baseProduct = nil
        prdMetadataChkReqd = false
        #For QuotationProductAdditional set the parent object as baseProduct for metadata evaulation
        if(currentTagObject != nil && currentTagObject.is_a?(QuotationProduct)  && currentTagObject.productSeq.to_s != "")
            baseProduct = currentTagObject
        elsif(currentTagObject != nil && (currentTagObject.is_a?(QuotationProductAdditional) || currentTagObject.is_a?(QuotationProductExtra)))
            # for productadditional and product extra need to get the correct parent productdo since can be for rider as well
            quotationProductList = @baseIO.baseDO.QuotationProductList
            baseProduct = quotationProductList.select{|quotProduct| quotProduct.object == currentTagObject.parentKey}.first if quotationProductList.size > 0
        elsif(currentTagObject != nil && (currentTagObject.is_a?(QuotationTopUp) || currentTagObject.is_a?(QuotationWithdrawal) || currentTagObject.is_a?(QuotationProductInvestmentFund) || currentTagObject.is_a?(Quotation) || currentTagObject.is_a?(OutputPreferences) ||
                    (currentTagObject.is_a?(QuotationParty) && currentTagObject.roleCd.to_s == "SUPPLEMENTARY")))
            prdMetadataChkReqd = true
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
        # if object name exists then compare the objects are the same
        if productDO.to_s != "" && prdMetadataChkReqd
            if(baseProduct != nil && baseProduct.is_a?(QuotationProduct) && baseProduct.productSeq.to_s != "")
                #create a Product Prdfield MetaData Cache and if the field has metadata in this replace it with the UIMetaData
                metadataHash = loadProductAdditionalMetadata(@baseIO, baseProduct, currentTagObject, metadataHash, companyMetadata)
            end
        end
        #set Enabled to NO if quotation is accepted except for OutputPreferences and EmailRequest
        #Signature object should enable in case of policy preview from policy,From there we got tab_siIllustration tab id,so added this condition.
        if currentTagObject != nil && isCompleted && !currentTagObject.is_a?(OutputPreferences) && !currentTagObject.is_a?(EmailRequest) && !($currentActiveTab.to_s == "tab_siIllustration" && currentTagObject.is_a?(ServiceSignature))
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
            end
        end

        #set Enabled to NO if quotation is accepted except for OutputPreferences and EmailRequest
        if currentTagObject != nil && isInvalid
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
            end
        end
        return metadataHash
    end
    
    def filterLookupData(lookupKey)
        listLookupDataFiltered = []
        if(@listLookupsToBeFiltered.include?(lookupKey))
            baseProduct = @baseIO.baseDO.getBaseProduct
            if baseProduct
                $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) 
            elsif @baseIO.baseDO.productId.to_s != ""
                #change logic to fetch only productseq in below load object and load children false
                product = Product.loadObject(:first,:conditions=>{
                    { :name => 'productId' } => @baseIO.baseDO.productId.to_s, 
                    { :name => 'productVersion' } => @baseIO.baseDO.productVersion.to_s})
                $currentProduct ||= MobiSys::ProductUtil.getProduct(product.id.to_s) 
            end
            listLookupDataFiltered = MobiSys::ProductUtil.filterLookupDataOnBasisOfProduct($currentProduct, lookupKey)
        else
            listLookupDataFiltered = super(lookupKey)
        end
        return listLookupDataFiltered
    end

     def addSupplementary
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct()
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
        supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE') if $currentProduct
        quotationParty = QuotationParty.new(:roleCd => 'SUPPLEMENTARY',:partyTypeCd => "INDIVIDUAL")
        quotation.addQuotationParty(quotationParty)
        supplementaryHash = {}
        tempHash = {}
        supplementaryHash["Supplementary"] = quotationParty.hashForApi(false)
        # if $currentProduct && supplementaryProductFacet  
        #     baseProduct = QuotationProduct.new
        #     baseProduct.productTypeCd = "PLANMULTI"
        #     baseProduct.partyRoleCd = "SUPPLEMENTARY"
        #     baseProduct.insuredPartyRefGuid = quotationParty.uniqueKey
        #     baseProduct.baseAnnualPremium = 0.0
        #     baseProduct.baseSumAssured = 0.0
        #     baseProduct.modalPremium = 0.0
        #     baseProduct.productSeq = quotation.getBaseProduct.productSeq
        #     quotation.addQuotationProduct(baseProduct)
        #     # QuotationProductExtra Section
        #     quotationProductExtras, baseProduct = MobiSys::QuotationBO.computeProductExtra(quotation, baseProduct)
        #     if quotationProductExtras
        #         methodName = "ProductExtraList="
        #         baseProduct.instance_eval { class << self; self end }.send(:attr_accessor, "ProductExtraList") unless baseProduct.respond_to? methodName
        #         baseProduct.send(methodName,baseProduct.QuotationProductExtraList.collect{|m| m.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }})
        #         supplementaryHash["Product"] = baseProduct.hashForApi(false,["ProductExtraList"]).select {|key| !["class","userId"].include? key.to_s }
        #     end
        # end
        tempHash["data"] = supplementaryHash
        attributeHash = {}
        attributeHash["companyMetadata"] = "PolicySupplementaryLifeDO"
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)

        if isMetadataRequired
            @lookupHash = {}
            evaluateContextForObject(quotation)
            evaluateContextForObject(quotationParty)
            metadataHash = {}
            tempHash["metadata"] = metadataHash.merge!(processMetadata(quotationParty, attributeHash))
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
            tempHash["lookups"] = @lookupHash
            contextEnd
            contextEnd
        end
        tempHash['success'] = true
        tempHash['message'] = "Successful"
        
        render :string => tempHash.to_json
    end

    def addTopup
        topupHash = {}
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
        quotation = @baseIO.baseDO
        topUpTypeCd = "ADHOCTOPUP"
        topUpTypeCd = parsedData['topUpTypeCd'].to_s if parsedData.has_key?("topUpTypeCd") && parsedData["topUpTypeCd"].to_s != ""
        topUp = QuotationTopUp.new(:topUpTypeCd => topUpTypeCd)
        quotation.addQuotationTopUp(topUp)
        topupHash["data"] = {"Topup" => topUp.hashForApi(false)}
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)

        if isMetadataRequired
            @lookupHash = {}
            evaluateContextForObject(quotation)
            evaluateContextForObject(topUp)
            metadataHash = {}
            topupHash["metadata"] = metadataHash.merge!(processMetadata(topUp))
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
            topupHash["lookups"] = @lookupHash
            contextEnd
            contextEnd
        end
        topupHash['success'] = true
        topupHash['message'] = "Successful"

        render :string => topupHash.to_json
    end

    def addWithdrawal
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
        quotation = @baseIO.baseDO
        quotationWithdrawal = QuotationWithdrawal.new
        quotation.addQuotationWithdrawal(quotationWithdrawal)
        withdrawHash = {}
        withdrawHash["data"] = {"Withdrawal" => quotationWithdrawal.hashForApi(false)}
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)

        if isMetadataRequired
            @lookupHash = {}
            evaluateContextForObject(quotation)
            evaluateContextForObject(quotationWithdrawal)
            metadataHash = {}
            withdrawHash["metadata"] = metadataHash.merge!(processMetadata(quotationWithdrawal))
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
            withdrawHash["lookups"] = @lookupHash
            contextEnd
            contextEnd
        end
        withdrawHash['success'] = true
        withdrawHash['message'] = "Successful"

        render :string => withdrawHash.to_json
    end

    def getProductFunds
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
        model = nil
        fundsHash = {}
        metadataHash = {}
        fundList = []
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
        if isMetadataRequired
            evaluateContextForObject(quotation)
            evaluateContextForObject(baseProduct)
        end

        if baseProduct.portfolioModelCd.to_s != ""
            model = Model.loadObject(:first,
                    :conditions =>{
                    {
                        :name => 'modelCd'
                    } => baseProduct.portfolioModelCd
                }
            )
        elsif baseProduct.portfolioModelCd.to_s == "" && baseProduct.productSeq.to_s != ""
            models = MobiSys::QuotationService.getPortfolioModels(quotation,baseProduct,$currentProduct)
            model = models[0] if models  
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
        end

        if fundList.size > 0
            selectedFundCdList = baseProduct.QuotationProductInvestmentFundList.map{|x| x.fundCd.to_s}
            fundList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
            fundCdList = fundList.map {|x| x.fundCd.to_s}
            fundList.each do |fund|
                if Date.parse(fund.expiryDt) > Date.parse(quotation.quotationDt)    
                   unless selectedFundCdList.include?(fund.fundCd.to_s)
                    quotationProductInvestmentFund = QuotationProductInvestmentFund.new
                    quotationProductInvestmentFund.fundCd = fund.fundCd
                    quotationProductInvestmentFund.expiryDt = fund.expiryDt
                    quotationProductInvestmentFund.fundTypeCd = fund.fundTypeCd
                    quotationProductInvestmentFund.maturityDt = fund.maturityDt
                    quotationProductInvestmentFund.sortOrder = fund.sortOrder
                    baseProduct.addQuotationProductInvestmentFund(quotationProductInvestmentFund)
                    end
                else
                    fund.delete
                end
            end
            baseProduct.QuotationProductInvestmentFundList.delete_if do |quotationProductInvestmentFund|
                unless fundCdList.include?(quotationProductInvestmentFund.fundCd.to_s)
                    existingFund = QuotationProductInvestmentFund.find(
                        :first,
                        :conditions => {
                            :object=>quotationProductInvestmentFund.object
                        }
                    )
                    existingFund.destroy if existingFund
                    true
                end
            end
            #Sort based on fundList sortorder
            sortedList = baseProduct.QuotationProductInvestmentFundList.sort_by{|x| fundCdList.index x.fundCd}
            baseProduct.setQuotationProductInvestmentFundList(sortedList)

            if isMetadataRequired
                baseProduct.QuotationProductInvestmentFundList.each do |investFund|
                    evaluateContextForObject(investFund) 
                    metadataHash.merge!(processMetadata(investFund))
                    contextEnd
                end
            end

            fundsHash["FundList"] = baseProduct.QuotationProductInvestmentFundList.hashForApi(false)
        end
        tempHash = {}
        tempHash["data"] = fundsHash 
        if isMetadataRequired
            tempHash["metadata"] = metadataHash
            tempHash["lookups"] = @lookupHash
            contextEnd
        end
        tempHash['success'] = true
        tempHash['message'] = "Successful"

        render :string => tempHash.to_json
    end

    def getIllustrationValuesByFacet
        parsedData = parseRequestBodyParams
        tempHash = {}
        returnHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        unless @baseIO.baseDO == nil
            fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
            returnHash["data"] = MobiSys::QuotationService.runIllustration(@baseIO.baseDO)
            returnHash['success'] = true
            returnHash['message'] = "Successful"
        else
            returnHash['success'] = false
            returnHash['message'] = "Quotation not found."
        end
        render :string => returnHash.to_json
    end

    #method added to only use the model evaluation engine and fetch the values with/without saving the quotation data in database
    def fetchIllustrationValues
        parsedData = parseRequestBodyParams
        tempHash = {}
        responseHash = {}
        @saveModel = false
        fetch(@params["id"]) if @params.has_key?("id")
        @message = nil

        agentreg = AgentReg.new
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
        if parsedData.has_key?("FormData")
            if parsedData["FormData"].has_key?("Models")
                if parsedData["FormData"]["Models"].has_key?("Entity")
                    $userId = parsedData["FormData"]["Models"]["Entity"]["agentId"]
                    agentreg.userId = MobiSys::Encryption.encryptContent($userId)
                    agentreg.channel = parsedData["FormData"]["Models"]["Entity"]["channel"]
                    agentreg.subChannel = parsedData["FormData"]["Models"]["Entity"]["subChannel"]
                    agentreg.save
                    quotationDt = parsedData["FormData"]["Models"]["Entity"]["quotationDt"]
                    if quotationDt.is_a?(Integer)
                        quotationDt = Time.at(quotationDt)
                    end
                    productId = parsedData["FormData"]["Models"]["Entity"]["productId"]
                    productList = Product.loadObject(
                        :all,
                        :conditions => {
                            :productId=>productId
                        }
                    )
                    productList.each do |product|
                        if quotationDt.to_s!="" && product.launchDt !=nil && (Time.parse(product.launchDt.to_s) < Time.parse(quotationDt.to_s) ||  Time.parse(product.withdrawDt.to_s) > Time.parse(quotationDt.to_s)) 
                            $currentProduct = product
                            parsedData["FormData"]["Models"]["Entity"]["productVersion"] = product.productVersion
                            if parsedData["FormData"]["Models"].has_key?("BasePlan")
                                parsedData["FormData"]["Models"]["BasePlan"]["productSeq"] = product.id
                                parsedData["FormData"]["Models"]["BasePlan"]["productVersion"] = product.productVersion
                            end
                            #check if premiumSAFl value needs to be set from before the getModel call. if yes fetch from offlineDetails table and set it here.
                            #parsedData["FormData"]["Models"]["BasePlan"]["premiumSAFl"]
                            break
                        end
                    end
                end
                if parsedData["FormData"]["Models"].has_key?("RiderList")
                    quotationDt = parsedData["FormData"]["Models"]["Entity"]["quotationDt"]
                    if quotationDt.is_a?(Integer)
                        quotationDt = Time.at(quotationDt)
                    end
                    parsedData["FormData"]["Models"]["RiderList"].each do |rider|
                        productId = rider["productId"]
                        productList = Product.loadObject(
                            :all,
                            :conditions => {
                                :productId=>productId
                            }
                        )
                        productList.each do |product|
                            if quotationDt.to_s!="" && product.launchDt !=nil && (Time.parse(product.launchDt.to_s) < Time.parse(quotationDt.to_s) ||  Time.parse(product.withdrawDt.to_s) > Time.parse(quotationDt.to_s)) 
                                rider["productSeq"] = product.id
                                rider["productVersion"] = product.productVersion
                                break
                            end
                        end
                    end
                end
            end
            fetchData(parsedData,false,false) if parsedData.has_key?("FormData")
            @baseIO.baseDO.quotationDt = getScreenDate(@baseIO.baseDO.quotationDt.to_s)
            @baseIO.baseDO.QuotationPartyList.each do |quotationParty|
                if quotationParty.age == nil
                    quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                    quotationParty.age = MobiSys::ProductBO.calculateAge(@baseIO.baseDO, @baseIO.baseDO.getBaseProduct, quotationParty, nil).split("|")[0]
                    quotationParty.dob = getDBDate(quotationParty.dob.to_s)
                end
            end
            @baseIO.baseDO.quotationDt = getDBDate(@baseIO.baseDO.quotationDt.to_s)
            process()
            quotation = @baseIO.baseDO
            if quotation.quoteStatusCd.to_s == "" || quotation.quoteStatusCd.to_s == 'PENDING'
                responseHash['data'] = {}
                responseHash["validationerrors"] = fetchExceptions(@baseIO.baseDO.guid, @baseIO.baseDO.visitedTabs) if @baseIO.baseDO.guid.to_s != ""
                responseHash['success'] = false
                responseHash['message'] = "Please resolve all the warnings." 
            else
                tempHash = MobiSys::QuotationService.runIllustrationAndGenerateFinalMap(@baseIO.baseDO)
                fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
                @message = "Illustration Generated Successfully" unless @message

                responseHash = generateResponseHash(isMetadataRequired)
                responseHash.merge!(tempHash)
                responseHash['success'] = true
            end
            MobiSys::CommonUtil.clearTaskExceptionList(@baseIO.baseDO.guid)
            agentreg.destroy
        else
             responseHash['data'] = {}
            responseHash['success'] = false
            responseHash['message'] = "Input Data missing" 
        end
        @saveModel = nil
        render :string => responseHash.to_json
    end 

    def getAllIllustrationValues
        parsedData = parseRequestBodyParams
        tempHash = {}
        responseHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        @message = nil
        quotation = @baseIO.baseDO

        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
        if quotation.quoteStatusCd.to_s == "" || quotation.quoteStatusCd.to_s == 'PENDING'
            responseHash['data'] = {}
            responseHash["validationerrors"] = fetchExceptions(quotation.guid, quotation.visitedTabs) if quotation.guid.to_s != ""
            responseHash['success'] = false
            responseHash['message'] = "Please resolve all the warnings." 
        else
            tempHash = MobiSys::QuotationService.runIllustrationAndGenerateFinalMap(quotation)
            fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
            @message = "Successful"

            responseHash = generateResponseHash(isMetadataRequired)
            responseHash.merge!(tempHash)
            responseHash['success'] = true
        end
        
        render :string => responseHash.to_json
    end

    def validateQuotation(id, parsedData)
        @saveModel = false
        process()
        @saveModel = nil
        responseHash = {}
    end

    def validate(id, parsedData)
        @baseIO.baseDO.action = "Validate"
        @saveModel = false
        process()
        @saveModel = nil
    end

    def getOutputPreferences
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        outputPref = OutputPreferences.new
        outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)
        tempHash = {}
        $lookupArray = [] unless $lookupArray
        tempHash["data"] = {"OutputPreferences" => outputPref.hashForApi(false)}
        isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
        if isMetadataRequired
            @lookupHash = {}
            evaluateContextForObject(outputPref)
            metadataHash = {}
            tempHash["metadata"] =  metadataHash.merge!(processMetadata(outputPref))
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
            tempHash["lookups"] = @lookupHash
            contextEnd
        end
        tempHash['success'] = true
        tempHash['message'] = "Successful"
        render :string => tempHash.to_json
    end

    def getEmailRequest
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        tempHash = {}
        outputPrefHash = ""

        if quotation
            emailRequest = EmailRequest.new
            emailRequest.entityGuid = quotation.guid
            emailRequest.entityNumber = quotation.quotationRefNum
            proposer = quotation.getPartyByRole('PROPOSER')
            emailRequest.toEmail = proposer.emailAddress if proposer && proposer.emailAddress.to_s != ""
            emailRequest.entityName = 'Quotation'
            if $rhoconfig[:capture_output_preferences].to_s == "YES"
                outputPref = OutputPreferences.new
                outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)
                emailRequest.outputPrefEntityGuid = outputPref.uniqueKey
                outputPrefHash = outputPref.hashForApi(false)
            end
            tempHash["data"] = {"OutputPreferences" => outputPrefHash, "EmailRequest" => emailRequest.hashForApi(false)}
            isMetadataRequired = (parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false' ? false : true)
            if isMetadataRequired
                @lookupHash = {}
                metadataHash = {}
                if $rhoconfig[:capture_output_preferences].to_s == "YES"
                    evaluateContextForObject(outputPref)
                    tempHash["metadata"] = metadataHash.merge!(processMetadata(outputPref))
                    contextEnd
                end
                evaluateContextForObject(emailRequest)
                tempHash["metadata"] = metadataHash.merge!(processMetadata(emailRequest))
                tempHash["lookups"] = @lookupHash
                contextEnd
            end
            tempHash['success'] = true
            tempHash['message'] = "Successful"
        else
            tempHash["success"] = false
            tempHash["message"] = "Quotation not found"
        end

        render :string => tempHash.to_json
    end

    def getPortfolioModel
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
        modelArray = []
        tempHash = {}
        metadataHash = {}
        models = MobiSys::QuotationService.getPortfolioModels(quotation,baseProduct,$currentProduct)

        models.each do |modelFund|
            if modelFund.modelCd != nil
                modelLookup = Lookupvalue.new
                modelLookup.cd = modelFund.modelCd
                modelLookup.desc = modelFund.modelDesc
                tempHash["cd"] = modelFund.modelCd
                tempHash["desc"] = modelFund.modelDesc
                modelArray.push(tempHash)
            end
        end

        modelsHash = {"data" => {"portfolioModel" => modelArray }} 
        modelsHash['success'] = true
        modelsHash['message'] = "Successful"
        render :string => modelsHash.to_json
    end

    def evaluateRider(id,parsedData)
        riderObject = parsedData['currentRider']
        formQuotationProduct = []
        parsedData['FormData']['Models']['RiderList'].each do |rider|
            formQuotationProduct.push(MobiSys::BrowserHelper.convertToObject('QuotationProduct', rider, nil, false))
        end
        if parsedData['FormData']['Models'].has_key?('BasePlan')
            formQuotationProduct.push(MobiSys::BrowserHelper.convertToObject('QuotationProduct', parsedData['FormData']['Models']['BasePlan'], nil, false))
        end
        MobiSys::QuotationService.evaluateRider(@baseIO.baseDO,formQuotationProduct,riderObject)
    end

    def deleteQuotation
        parsedData = parseRequestBodyParams
        tempHash = {}
        if @params.has_key?("id")
            fetch(@params["id"])
            quotation = @baseIO.baseDO
            if quotation
                if quotation.quoteStatusCd != "ACCEPTED"
                    MobiSys::QuotationService.deleteQuotation(quotation)
                    tempHash = {"success" => true, "message" => "Quotation deleted successfully"}
                else
                    tempHash = {"success" => false, "message" => "Accepted quotation cannot be deleted."}
                end
            else
                tempHash["success"] = false
                tempHash["message"] = "Quotation not found"
            end
        elsif (parsedData.has_key?("ids") && parsedData['ids'].to_s != "")
                quotationIds = parsedData['ids'].split(',')
            if quotationIds.size > 0
                successDeletedQuotation = 0
                failedDeletedQuotation = 0
                quotationIds.each do |id|
                    fetch(id) if id != ""
                    quotation = @baseIO.baseDO
                    if quotation != nil
                        if quotation.quoteStatusCd != "ACCEPTED"
                            MobiSys::QuotationService.deleteQuotation(quotation)
                            successDeletedQuotation += 1
                        else
                            failedDeletedQuotation += 1
                        end
                    end
                end
                message = successDeletedQuotation.to_i > 0 ? "Successfully deleted #{successDeletedQuotation} quotation(s)." : ""
                message = message + "\n#{failedDeletedQuotation} quotation(s) with status Accepted could not be deleted." if failedDeletedQuotation.to_i > 0
                tempHash = {"success" => true, "message" => message}
            end
        else
            tempHash["success"] = false
            tempHash["message"] = "Quotation Id is required for deletion."
        end

        render :string => tempHash.to_json
    end

    def getApplicableRiderPlanOptions
        parsedData = parseRequestBodyParams
        tempHash = {}
        tempHash["success"] = false
        tempHash["message"] = "Applicable Plan Options not found"
        planOptionArray = []
        applicablePlanOptions = parsedData['applicablePlanOptions'].to_s.split(',')

        if applicablePlanOptions.size > 0
            applicablePlanOptions.each do |planOption|
                planHash = {}
                planOptionDetails = planOption.split("|")
                if planOptionDetails[0].to_s != ""
                    planHash["cd"] = planOptionDetails[0]
                    planHash["desc"] = planOptionDetails[1]
                    planOptionArray.push(planHash)
                end
            end
            tempHash = {"data" => {"planOption" => planOptionArray}, "success" => true, "message" => "Successful" }
        end

        render :string => tempHash.to_json
    end

    def copyQuotation(id,parsedData)
        sourceQuotation = @baseIO.baseDO
        responseHash = {}

        if sourceQuotation
            targetToBeQuotation = Quotation.new
            targetQuotation = MobiSys::QuotationService.copyQuotation(sourceQuotation, targetToBeQuotation, true)
            targetQuotation.guid = targetQuotation.uniqueKey
            baseProduct = targetQuotation.getBaseProduct
            $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s)
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, targetQuotation)
                targetQuotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, targetQuotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end
            MobiSys::QuotationService.saveValidate(targetQuotation,true)
            @baseIO.baseDO = targetQuotation
            @message = "Copy Successful"
        else
            responseHash["success"] = false
            responseHash["message"] = "Quotation not found"
        end
        return responseHash
    end

    # def viewIllustration
    #     responseHash = {}
    #     data = {}
    #     if !Rho::System.isRhoSimulator
    #         # 2 times parsing require because it converts to json object again before calling from native
    #         ####
    #         parsedData = Rho::JSON.parse(@params['request-body'])
    #         if parsedData.has_key?("params")
    #             parseData2 = Rho::JSON.parse(parsedData["params"])
    #         else 
    #             parseData2 = parsedData
    #         end
    #         formData = {}
            
    #         if @params.has_key?("id")
    #             fetch(@params["id"]) 
    #         else
    #             if parseData2.has_key?('FormData') && parseData2['FormData'].has_key?('Models') && parseData2['FormData']["Models"].has_key?('Entity')
    #                 formData = parseData2['FormData']["Models"]["Entity"]
    #             end
    #             fetch(formData["object"]) if formData.has_key?('object')
    #         end
    #         fetchData(parseData2,false,false)
    #         ###
    #     else
    #         parsedData = parseRequestBodyParams
    #         fetch(@params["id"]) if @params.has_key?("id")
    #         fetchData(parsedData,false,false)
    #     end
    #     # process()
    #     quotation = @baseIO.baseDO
    #     $graphHtmlHM = {}
    #     $graphHtmlCounter = 0
    #     $graphHtmlCallbackCounter = 0
    #     if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""

    #         outputPref = OutputPreferences.new
    #         outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

    #         responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
    #     else
    #         html = ""
    #         MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
    #         $quotationIO.bodyContent = ""
    #         $quotationIO.cssContent = ""
    #         $quotationIO.isFullHTMLRequired = parsedData["isFullHTMLRequired"].to_s != "" ? parsedData["isFullHTMLRequired"] : true
    #         $quotationIO.isTemplateBasedOutput = false
    #         responseHash["data"] = {}
    #         quotationProduct = quotation.getBaseProduct
    #         party = quotation.getParty(quotationProduct)
    #         product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq.to_s)
    #         facetValue = MobiSys::ProductBO.evaluateProductFacet(product, "SITEMPLATEID")
    #         templateFacetValue = nil
    #         if facetValue.to_s != ""
    #             if facetValue.is_a?(Integer)
    #                 templateFacetValue = MobiSys::ProductBO.getFacetOutput(facetValue.to_i, quotation, quotationProduct, party)
    #             else
    #                 templateFacetValue = facetValue.to_s
    #             end
    #         end
    #         templatePath = Rho::Application.userFolder + "Templates/#{templateFacetValue}/index.erb_enc"
            
    #         if templateFacetValue.to_s != ""
    #             responseHash['data']['signatureList'] = nil
    #             if File.exists?(templatePath)
    #                 html, this = evaluateTemplate(templateFacetValue)

    #                 $quotationIO.isTemplateBasedOutput = true
    #                 $quotationIO.htmlContent = []
    #                 $quotationIO.htmlContent.push html
    #                 if this.si.Quotation.ServiceSignatureList.size > 0 and this.si.Quotation.ServiceSignatureList[0].class.to_s == "OpenStruct"
    #                     $quotationIO.signatureList = openstruct_to_hash(this.si.Quotation.ServiceSignatureList)
    #                 else
    #                     $quotationIO.signatureList = this.si.Quotation.ServiceSignatureList.hashForApi
    #                 end
    #                 if $quotationIO.isFullHTMLRequired
    #                     responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
    #                 else
    #                     MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
    #                     responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
    #                 end
    #                 responseHash['data']['signatureList'] = $quotationIO.signatureList


    #             else

    #                 template = TemplateMaster.loadObject(:first, :conditions=> {'templateId' => templateFacetValue})
    #                 if template && template.zippedTemplateOffline.to_s != ""
    #                     compressed = Base64.strict_decode64(template.zippedTemplateOffline.to_s)
    #                     Rho::RhoFile.makeDir(Rho::RhoFile.join(Rho::Application.userFolder, "Templates")) unless Rho::RhoFile.exists(Rho::RhoFile.join(Rho::Application.userFolder, "Templates"))

    #                     filePath = Rho::RhoFile.join(Rho::Application.userFolder, "Templates/zippedTemplateOffline.zip")
    #                     file = File.open(filePath,"wb")
    #                     file.write(compressed)
    #                     file.close

    #                     result = Rho::System.unzipFile(filePath)
    #                     File.delete(filePath)

    #                     Dir.glob("#{Rho::Application.userFolder}Templates/#{templateFacetValue}/**/*.erb").each do |file|
    #                         encodedContent = MobiSys::Encryption.encryptAndEncodeContent(File.read(file))
    #                         File.open(file + "_enc","w") do |outf|
    #                             outf << encodedContent
    #                         end
    #                         File.delete file
    #                     end

    #                     html, this = evaluateTemplate(templateFacetValue)

    #                     $quotationIO.isTemplateBasedOutput = true
    #                     $quotationIO.htmlContent = []
    #                     $quotationIO.htmlContent.push html
    #                     if this.si.Quotation.ServiceSignatureList.size > 0 and this.si.Quotation.ServiceSignatureList[0].class.to_s == "OpenStruct"
    #                         $quotationIO.signatureList = openstruct_to_hash(this.si.Quotation.ServiceSignatureList)
    #                     else
    #                         $quotationIO.signatureList = this.si.Quotation.ServiceSignatureList.hashForApi
    #                     end
    #                     if $quotationIO.isFullHTMLRequired
    #                         responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
    #                     else
    #                         MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
    #                         responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
    #                     end
    #                     responseHash['data']['signatureList'] = $quotationIO.signatureList


    #                 else
    #                     MobiSys::QuotationService.commonShowBenefitTable()
    #                     responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}    
    #                 end

    #             end
    #         else
    #             MobiSys::QuotationService.commonShowBenefitTable()
    #             responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
    #         end
 
    #         if !Rho::System.isRhoSimulator && defined?(Rho::HtmlToGraph)
    #             if $graphHtmlHM.size > 0
    #                 objects = Rho::HtmlToGraph.enumerate
    #                 obj = objects[0]
    #                 $graphHtmlHM.each do |key, value|
    #                     puts "value==#{key}==#{value}"
    #                     res = obj.getGraphIOS(value,"/app/Quotation/htmlCallback")
    #                 end
    #             else
    #                 responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
    #                 responseHash['data']['signatureList'] = $quotationIO.signatureList
    #                 responseHash['success'] = true
    #                 responseHash['message'] = "Illustration HTML generated successfully."
    #                 $graphHtmlHM = {}
    #                 $graphHtmlCounter = 0
    #                 $graphHtmlCallbackCounter = 0
    #                 Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
    #             end
    #             obj = nil
    #         else
    #             if $quotationIO.isTemplateBasedOutput == true
    #                 if $quotationIO.isFullHTMLRequired
    #                     responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
    #                 else
    #                     MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
    #                     responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
    #                 end
    #             else
    #                 responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
    #             end
    #             responseHash['data']['signatureList'] = $quotationIO.signatureList
    #             responseHash['success'] = true
    #             responseHash['message'] = "Illustration HTML generated successfully."
    #         end
    #     end
        
    #     render :string => responseHash.to_json 
    # end

    def viewIllustration
        responseHash = {}
        data = {}
        if !Rho::System.isRhoSimulator #and false
            # 2 times parsing require because it converts to json object again before calling from native
            ####
            parsedData = Rho::JSON.parse(@params['request-body'])
            parseData2 = Rho::JSON.parse(parsedData["params"])
            formData = {}
            
            if parseData2.has_key?("id")
                fetch(parseData2["id"]) 
            else
                if parseData2.has_key?('FormData') && parseData2['FormData'].has_key?('Models') && parseData2['FormData']["Models"].has_key?('Entity')
                    formData = parseData2['FormData']["Models"]["Entity"]
                end
                fetch(formData["object"]) if formData.has_key?('object')
            end
            # puts "~~~~quotation.getBasePlan before fetchData:#{@baseIO.baseDO.getBasePlan}"

            fetchData(parseData2,false,false)
            ###
        else
            parsedData = parseRequestBodyParams
            fetch(@params["id"]) if @params.has_key?("id")
            fetchData(parsedData,false,false)
        end
        # process()
        quotation = @baseIO.baseDO
        quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)

        $graphHtmlHM = {}
        $graphHtmlCounter = 0
        $graphHtmlCallbackCounter = 0
        if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""

            outputPref = OutputPreferences.new
            outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

            responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        else
            html = ""
            MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

            #copy html resources to graphHtml folder in apps/documents
            outputFolder = Rho::RhoFile.join(Rho::Application.userFolder, "graphHtml")
            Rho::RhoFile.makeDir(outputFolder) unless Rho::RhoFile.exists(outputFolder)
            data = [
                            "/public/jquery/jquery-1.11.3.min.js",
                            "/public/js/RGraph/RGraph.bar.js",
                            "/public/js/RGraph/RGraph.hbar.js",
                            "/public/js/RGraph/RGraph.scatter.js",
                            "/public/js/RGraph/RGraph.common.annotate.js",
                            "/public/js/RGraph/RGraph.common.context.js",
                            "/public/js/RGraph/RGraph.common.dynamic.js",
                            "/public/js/RGraph/RGraph.common.effects.js",
                            "/public/js/RGraph/RGraph.common.resizing.js",
                            "/public/js/RGraph/RGraph.common.tooltips.js",
                            "/public/js/RGraph/RGraph.common.zoom.js",
                            "/public/js/RGraph/RGraph.drawing.circle.js",
                            "/public/js/RGraph/RGraph.drawing.image.js",
                            "/public/js/RGraph/RGraph.drawing.marker1.js",
                            "/public/js/RGraph/RGraph.drawing.marker2.js",
                            "/public/js/RGraph/RGraph.drawing.text.js",
                            "/public/js/RGraph/RGraph.drawing.xaxis.js",
                            "/public/js/RGraph/RGraph.drawing.yaxis.js",
                            "/public/js/RGraph/RGraph.drawing.rect.js",
                            "/public/js/RGraph/RGraph.line.js",
                            "/public/js/RGraph/RGraph.common.core.js",
                            "/public/js/RGraph/RGraph.pie.js",
                            "/public/js/RGraph/RGraph.common.key.js"
                    ]
            data.each do |entry|
                newEntry = entry.gsub('"','')
                @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
            end

            $quotationIO.bodyContent = ""
            $quotationIO.cssContent = ""
            $quotationIO.isFullHTMLRequired = parsedData["isFullHTMLRequired"].to_s != "" ? parsedData["isFullHTMLRequired"] : true
            $quotationIO.isTemplateBasedOutput = false
            responseHash["data"] = {}
            quotationProduct = quotation.getBaseProduct
            party = quotation.getParty(quotationProduct)
            product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq.to_s)
            facetValue = MobiSys::ProductBO.evaluateProductFacet(product, "SITEMPLATEID")
            templateFacetValue = nil
            if facetValue.to_s != ""
                if facetValue.is_a?(Integer)
                    templateFacetValue = MobiSys::ProductBO.getFacetOutput(facetValue.to_i, quotation, quotationProduct, party)
                else
                    templateFacetValue = facetValue.to_s
                end
            end
            templatePath = Rho::Application.userFolder + "Templates/#{templateFacetValue}/index.erb_enc"
            
            if templateFacetValue.to_s != ""
                responseHash['data']['signatureList'] = nil
                if File.exists?(templatePath)
                    html, this = evaluateTemplate(templateFacetValue)

                    $quotationIO.isTemplateBasedOutput = true
                    $quotationIO.htmlContent = []
                    $quotationIO.htmlContent.push html
                    if this.si.Quotation.ServiceSignatureList.size > 0 and this.si.Quotation.ServiceSignatureList[0].class.to_s == "OpenStruct"
                        $quotationIO.signatureList = openstruct_to_hash(this.si.Quotation.ServiceSignatureList)
                    else
                        $quotationIO.signatureList = this.si.Quotation.ServiceSignatureList.hashForApi
                    end
                    if $quotationIO.isFullHTMLRequired
                        responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                    else
                        MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                        responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                    end
                    responseHash['data']['signatureList'] = $quotationIO.signatureList


                else

                    template = TemplateMaster.loadObject(:first, :conditions=> {'templateId' => templateFacetValue})
                    if template && template.zippedTemplateOffline.to_s != ""
                        compressed = Base64.strict_decode64(template.zippedTemplateOffline.to_s)
                        Rho::RhoFile.makeDir(Rho::RhoFile.join(Rho::Application.userFolder, "Templates")) unless Rho::RhoFile.exists(Rho::RhoFile.join(Rho::Application.userFolder, "Templates"))

                        filePath = Rho::RhoFile.join(Rho::Application.userFolder, "Templates/zippedTemplateOffline.zip")
                        file = File.open(filePath,"wb")
                        file.write(compressed)
                        file.close

                        puts "~~~ unzipping file"

                        result = System.unzip_file(filePath)
                        puts "~~~unzip result:#{result}"


                        Dir.glob("#{Rho::Application.userFolder}Templates/#{templateFacetValue}/**/*.erb").each do |file|
                            encodedContent = MobiSys::Encryption.encryptAndEncodeContent(File.read(file))
                            File.open(file + "_enc","w") do |outf|
                                outf << encodedContent
                            end
                            File.delete file
                        end
                        File.delete(filePath)


                        html, this = evaluateTemplate(templateFacetValue)

                        $quotationIO.isTemplateBasedOutput = true
                        $quotationIO.htmlContent = []
                        $quotationIO.htmlContent.push html
                        if this.si.Quotation.ServiceSignatureList.size > 0 and this.si.Quotation.ServiceSignatureList[0].class.to_s == "OpenStruct"
                            $quotationIO.signatureList = openstruct_to_hash(this.si.Quotation.ServiceSignatureList)
                        else
                            $quotationIO.signatureList = this.si.Quotation.ServiceSignatureList.hashForApi
                        end
                        if $quotationIO.isFullHTMLRequired
                            responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                        else
                            MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                            responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                        end
                        responseHash['data']['signatureList'] = $quotationIO.signatureList


                    else
                        MobiSys::QuotationService.commonShowBenefitTable()
                        responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}    
                    end

                end
            else
                MobiSys::QuotationService.commonShowBenefitTable()
                responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
            end
            # puts "~~~~$graphHtmlHM:#{$graphHtmlHM}"
            if !Rho::System.isRhoSimulator && defined?(Rho::HtmlToGraph)
                if $graphHtmlHM.size > 0
                    
                    # tempHTMLFileName = Rho::RhoFile.join(outputFolder, "graph.html")
                    index = 1
                    $graphHtmlHM.each do |key, value|
                        tempHTMLFileName = Rho::RhoFile.join(outputFolder, "graph#{index}.html")
                        # puts "~~~~tempHTMLFileName:#{tempHTMLFileName}"
                        if File.exist?(tempHTMLFileName)
                            File.delete(tempHTMLFileName)
                        end
                        File.open(tempHTMLFileName,'w') do |f|
                                f.puts(value)
                        end
                        objects = Rho::HtmlToGraph.enumerate
                        obj = objects[0]
                        # res = obj.getGraphIOS(tempHTMLFileName,"/app/Quotation/htmlCallback")
                        res = obj.getGraphIOS(tempHTMLFileName)
                        # puts "~~~res['html']:#{res['html']}"
                        # puts "~~~res['graphPlaceHolder']:#{res['graphPlaceHolder']}"
                        graphBase64 = res['html']
                        graphPlaceHolder = res['graphPlaceHolder']
                        graphBase64 = "<img src=\"#{graphBase64}\">" if $quotationIO.isTemplateBasedOutput == false
                        $quotationIO.htmlContent.each do |htmlContent|
                            if $quotationIO.isTemplateBasedOutput == false
                                htmlContent[1]["content"].gsub!(graphPlaceHolder,graphBase64)
                            else
                                htmlContent.gsub!(graphPlaceHolder,graphBase64)
                            end
                        end

                        index = index + 1
                    end
                    responseHash = {}
                    data = {}
                    if $quotationIO.isTemplateBasedOutput == true
                        if $quotationIO.isFullHTMLRequired
                            responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                        else
                            MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                            responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                        end
                    else
                        responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
                    end
                    responseHash['data']['signatureList'] = $quotationIO.signatureList
                    responseHash['success'] = true
                    responseHash['message'] = "Illustration HTML generated successfully."
                   
                    $graphHtmlHM = nil
                    $graphHtmlCounter = nil
                    $graphHtmlCallbackCounter = nil
                    Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
                else
                    # puts "~~~~in else"
                    # responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
                    responseHash['data']['signatureList'] = $quotationIO.signatureList
                    responseHash['success'] = true
                    responseHash['message'] = "Illustration HTML generated successfully."
                    $graphHtmlHM = nil
                    $graphHtmlCounter = nil
                    $graphHtmlCallbackCounter = nil
                    # puts "~~~~returning to HtmlCreated"
                    Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
                    # puts "~~~~responseHash:#{responseHash}"
                    # $responseHash = responseHash
                    # System.start_timer(2000,url_for(:action=>:htmlCreatedCallback),"test")

                end
                obj = nil
            else
                if $quotationIO.isTemplateBasedOutput == true
                    if $quotationIO.isFullHTMLRequired
                        responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                    else
                        MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                        responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                    end
                else
                    responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
                end
                responseHash['data']['signatureList'] = $quotationIO.signatureList
                responseHash['success'] = true
                responseHash['message'] = "Illustration HTML generated successfully."
            end
        end
        
        render :string => responseHash.to_json 
    end

    def htmlCallback
        puts "@params======#{@params}"
        graphBase64 = @params['html']
        graphPlaceHolder = @params['graphPlaceHolder']
        puts "graphPlaceHolder======#{graphPlaceHolder}"
        graphBase64 = "<img src=\"#{graphBase64}\">" if $quotationIO.isTemplateBasedOutput == false

        $graphHtmlCallbackCounter = $graphHtmlCallbackCounter + 1
        $quotationIO.htmlContent.each do |htmlContent|
            if $quotationIO.isTemplateBasedOutput == false
                htmlContent[1]["content"].gsub!(graphPlaceHolder,graphBase64)
            else
                htmlContent.gsub!(graphPlaceHolder,graphBase64)
            end
        end
        if $graphHtmlHM.size == $graphHtmlCallbackCounter
            
            responseHash = {}
            data = {}
            if $quotationIO.isTemplateBasedOutput == true
                if $quotationIO.isFullHTMLRequired
                    responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                else
                    MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                    responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                end
            else
                responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
            end
            responseHash['data']['signatureList'] = $quotationIO.signatureList
            responseHash['success'] = true
            responseHash['message'] = "Illustration HTML generated successfully."
           
            $graphHtmlHM = {}
            $graphHtmlCounter = 0
            $graphHtmlCallbackCounter = 0
            Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
        end
    end

    def evaluateTemplate(templateFacetValue)
        html = ""
        thisHM = MobiSys::QuoteIllustration.generatePdfUi_new(@baseIO)
        this = ::JSON.parse(thisHM.to_json, object_class:OpenStruct)
        html = renderTemplate(:template =>"Templates/#{templateFacetValue}/index", :locals => { :this=>this})
        html.gsub!("$[sym_page_totalCount]",this.sym_page_count.to_s)

        return html, this
    end

    def generateIllustrationPdf
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        quotation = @baseIO.baseDO
       
        if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""
            outputPref = OutputPreferences.new
            outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

            responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        else
            if $rhoconfig[:offlinePDFGeneration] && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'
                # ofline pdf generation
                MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                result = MobiSys::QuotationService.generateOfflinePDFHTML()
                if result.has_key?('error') and result['error'].to_s != ""
                    responseHash['success'] = false
                    responseHash['message'] = result['error'].to_s
                else
                    responseHash['data'] = {"pdfFileContents" => "", "FileName" => result['pdfFileName'], "pdfMode" => "offlinePDFGeneration"}
                    responseHash['success'] = true
                    responseHash['message'] = "Pdf generated successfully."
                end
            else
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
                    if navigateToSync
                        responseHash['success'] = false
                        responseHash['message'] = "Please take Primary database sync."
                    else
                        if $rhoconfig[:offlineOutputGeneration]
                            
                            $CreateOutputFiles = false

                            MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                            result = MobiSys::QuotationService.generateOutputHTML()
                            if result.has_key?('error') and result['error'].to_s != ""
                                responseHash['success'] = false
                                responseHash['message'] = result['error'].to_s
                            else
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => "", "pdfMode" => ""}
                                responseHash['success'] = true
                                responseHash['message'] = "Pdf generated successfully."
                            end
                        else
                            outputPreferencesDO = nil
                            outputPreferencesDO = @baseIO.outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES" 
                            result = MobiSys::QuotationService.get_pdf(quotation, outputPreferencesDO)
                            if result and result.has_key?('PDFCONTENT')
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => "", "pdfMode" => ""}
                                responseHash['success'] = true
                                responseHash['message'] = "Pdf generated successfully."
                            else
                                responseHash['success'] = false
                                responseHash['message'] = "Error generating pdf."
                            end
                        end
                    end
                else
                    responseHash['success'] = false
                    responseHash['message'] = getLabelValue('CHECKNETWORK')
                end
            end            
        end

        render :string => responseHash.to_json 
    end

    def sendEmail
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        quotation = @baseIO.baseDO
        if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""
            outputPref = OutputPreferences.new
            outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

            responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        elsif @baseIO.emailRequestDO != nil
            if parsedData["FormData"]["Models"].has_key?("Entity")
                emailRequestObj = parsedData["FormData"]["Models"]["EmailRequest"]
            end
            emailRequest = @baseIO.emailRequestDO
            emailRequest.emailReqStatusCd = "PENDING"
            emailRequest.entityName = "Quotation"
            emailRequest.entityGuid = quotation.guid
            emailRequest.entityNumber = quotation.quotationRefNum
            emailRequest.toEmail = emailRequestObj["toEmail"]
            emailRequest.ccEmail = emailRequestObj["ccEmail"]
            emailRequest.message = emailRequestObj["message"]
            outputPref = @baseIO.outputPreferencesDO
            emailRequest.outputPrefEntityGuid = outputPref.guid
            outputPref.persistAll
            emailRequest.persistAll
            unless $rhoconfig[:offlineOutputGeneration]
                signature_image = Image.loadObject(:first, :conditions=>{{:name=>'parentRefGuid'}=>quotation.uniqueKey})

                quotation.QuotationProductList.each do|quotaProduct|
                    if quotaProduct.emr==nil || quotaProduct.emr==""
                        quotaProduct.emr=0
                    end
                    if quotaProduct.emrDuration==nil || quotaProduct.emrDuration==""
                        quotaProduct.emrDuration=0
                    end
                    if quotaProduct.flatExtra==nil || quotaProduct.flatExtra==""
                        quotaProduct.flatExtra=0
                    end
                    if quotaProduct.flatExtraDuration==nil || quotaProduct.flatExtraDuration==""
                        quotaProduct.flatExtraDuration=0
                    end
                end
                quotation.QuotationTopUpList.each do| topup|
                    if topup.topUpAmount==nil || topup.topUpAmount==""
                        topup.topUpAmount=0
                    end
                end
            end

            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            # has_network = false # for offline testing only
            if has_network
                forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
                if navigateToSync
                    responseHash['success'] = false
                    responseHash['message'] = "Please take Primary database sync."
                else
                    if $rhoconfig[:offlineOutputGeneration]
                        $CreateOutputFiles = false
                        MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                        $quotationIO.emailRequestDO = emailRequest
                        result = MobiSys::QuotationService.generateOutputHTML()
                        responseHash['success'] = true
                        responseHash['message'] = "Successful"
                        if result["error"].to_s != ""
                            responseHash['success'] = false
                            responseHash['message'] = result["error"]
                        end
                    else
                        signaturecontainer = SignatureContainer.loadObject(:first,
                                                :conditions => {
                                                :entityGuid => quotation.guid
                                                }
                                            )
                        syncEntities = []
                        if signature_image!=nil
                            syncEntities.push signature_image unless signature_image.uploadStatus == 'DONE'
                        end
                        syncEntities.push quotation if quotation.quoteStatusCd != 'SYNCDONE'
                        syncEntities = syncEntities + signaturecontainer.ServiceSignatureList if signaturecontainer
                        syncEntities.push emailRequest
                        if @baseIO.outputPreferencesDO
                            syncEntities.push @baseIO.outputPreferencesDO
                        end
                        begin
                            result = MobiSys::Sync.sendEmailRequest(syncEntities, true)
                            responseHash['success'] = true
                            responseHash['message'] = "Successful"
                            if result["error"].to_s != ""
                                responseHash['success'] = false
                                responseHash['message'] = result["error"]
                            end
                        rescue StandardError => se
                            #do nothing
                            puts "exception: #{se}"
                        end
                    end
                end
            else
                if $rhoconfig[:offlineOutputGeneration]
                    $CreateOutputFiles = true
                    MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                    $quotationIO.emailRequestDO = emailRequest
                    result = MobiSys::QuotationService.generateOutputHTML()
                    $CreateOutputFiles = false
                    if result['success'] == true
                        responseHash['success'] = true
                        responseHash['message'] = getLabelValue('EMAILREQUESTQUEUED')
                    end
                else
                    responseHash['success'] = true
                    responseHash['message'] = getLabelValue('EMAILREQUESTQUEUED')
                end
            end
        else
            responseHash['success'] = false
            responseHash['message'] = getLabelValue('emailSendFail')
        end
        render :string => responseHash.to_json 
    end

    def addServiceSignature
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        signatureHash = {}
        @lookupHash = {}
        
        if quotation
            signatureTypeCd = parsedData["signatureTypeCd"]
            if parsedData["signatureTypeCd"].to_s != "" && parsedData["roleCd"].to_s != ""
                #Check if present in db else create new
                signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )

                signature = signatureContainer.ServiceSignatureList.select{ |s| s.signatureTypeCd == signatureTypeCd }.first if signatureContainer != nil

                signature = ServiceSignature.new(:signatureTypeCd => signatureTypeCd, :entityGuid => quotation.guid, :entityType => @entityClass, :roleCd => parsedData["roleCd"]) if signature == nil
                signatureHash["data"] = {"serviceSignature" => signature.hashForApi(false)}
                isMetadataRequired = true
                if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") && parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                    isMetadataRequired = false
                end

                if isMetadataRequired
                    evaluateContextForObject(signature)
                    metadataHash = {}
                    signatureHash["metadata"] = metadataHash.merge!(processMetadata(signature))
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
            signatureHash["message"] = "Quotation not found"
        end

        render :string => signatureHash.to_json
    end

    def acceptServiceSignature
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        signatureHash = {}
        signatureHash["success"] = false
        signatureHash["message"] = "Quotation not found"
        @saveModel = false

        if quotation
            fetchData(parsedData, false, false) if parsedData.has_key?("FormData")
            process()
            quotation = @baseIO.baseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )
           
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(quotation.guid, quotation.visitedTabs)
                
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                #Probably add validation (process function) here
                quotation.signature = "SUCCESS"
                quotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
                quotation.signatureDt = Time.new.strftime("%F 00:00:00 %z")
                quotation.persistAll
                MobiSys::TrackLeadBO.updateTrackLead(quotation)
                if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                    emailRequest = @baseIO.emailRequestDO
                    $CreateOutputFiles = false
                    MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                    $quotationIO.emailRequestDO = emailRequest
                    result = MobiSys::QuotationService.generateOutputHTML()
                end
                signatureHash["success"] = true
                signatureHash["message"] = "Successful"
            else
                signatureHash["message"] = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
            end
        end
        @saveModel = nil
        render :string => signatureHash.to_json
    end

    def acceptQuotation(id,parsedData)
        p "insie acceptQuotation*******#{parsedData}"
        # parsedData = parseRequestBodyParams
        # fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        quotation.action = "Submit"
        signatureHash = {}
        @success = false
        @message = "Quotation not found"
        @saveModel = false
        p "quotation=====#{quotation}"
        if quotation
            quotation.entityStatus = "LOCKED" if quotation.entityStatus.to_s == "REOPEN"
            process()
            quotation = @baseIO.baseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )
           
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(quotation.guid, quotation.visitedTabs)
            p "errors===#{errors}"
            p "errorTabs=====#{errorTabs}"
            p "incompleteTabs====#{incompleteTabs}"
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                p "inside if empty***********"
                #Probably add validation (process function) here
                quotation.signature = "SUCCESS"
                quotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
                quotation.signatureDt = Time.new.strftime("%F 00:00:00 %z")
                quotation.persistAll
                MobiSys::TrackLeadBO.updateTrackLead(quotation)
                if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                    emailRequest = @baseIO.emailRequestDO
                    $CreateOutputFiles = false
                    MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                    $quotationIO.emailRequestDO = emailRequest
                    result = MobiSys::QuotationService.generateOutputHTML()
                end
                @success = true
                @message = "Successful"
            else
                p "else NOTTTTTTTTTT empty"
                @message = getLabelValue('ERR_PLZCOMPLETE_SIGNATURE')
            end
        end
        @saveModel = nil
        return nil
    end

    def convertToEapp(id, parseData)
        quotation = @baseIO.baseDO
        err_message = ''
        responseHash = {}
        if quotation != nil
            if quotation.isBackdatedFl.to_s == "YES"
                policy = newPolicy(quotation)
                quotation.policySeq = policy.object
            else
                if quotation.quotationExpiryDt.to_s != "" && (Time.now.to_date - Date.strptime(getScreenDate(quotation.quotationExpiryDt.to_s), "%d/%m/%Y") > 0)
                    err_message = 'ERR_QUOTATION_EXPIRED'
                elsif !(($rhoconfig[:captureSignOnSIOutput] || quotation.signature.to_s != "") && quotation.signatureDt.to_s != "" && (quotation.quoteStatusCd == "ACCEPTED" || quotation.quoteStatusCd == "SYNCDONE"))
                    err_message = 'Quotation status should be accepted.'
                else
                    isAgeValid = true
                    quotation.QuotationPartyList.each do |quotationParty|
                        if quotationParty.dob.to_s != ""
                            quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                            newAge = MobiSys::ProductBO.calculateAge(quotation, quotation.getBaseProduct, quotationParty, nil, getScreenDate(Time.new.to_s)).split("|")[0]
                            quotationParty.dob = getDBDate(quotationParty.dob.to_s)
                            if newAge.to_i != quotationParty.age.to_i
                                isAgeValid = false
                                break
                            end
                        end
                    end
                    unless isAgeValid
                        err_message = 'ERR_AGE_CHANGED'
                    else
                        policy = newPolicy(quotation)
                        quotation.policySeq = policy.object
                    end
                end
            end
        else
            err_message = 'Quotation not found.'
        end
        
        if err_message != ''
            responseHash['success'] = false
            responseHash['message'] = err_message
        end
        return responseHash
    end

    def newPolicy(quotation)
        $rhoconfig[:moduleForProductValidations] = "Policy"
        quotpolicy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
        if quotpolicy
            policy = quotpolicy
        else
            policy = Policy.new
            policy.quotationRefGuid = quotation.uniqueKey
            policy.bankStaffReferralCd = quotation.bankStaffReferralCd
            policy.quotationRefNum = quotation.quotationRefNum
            policy.leadId = quotation.leadId
            policy.fnaId = quotation.fnaId
            policy.rpqId = quotation.rpqId
            policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
            policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
            policy.isBackdatedFl = quotation.isBackdatedFl
            policy.quotationDt = quotation.quotationDt
            policy.insuranceTypeCd = quotation.insuranceTypeCd
            policy.supplementaryLives = quotation.supplementaryLives if quotation.supplementaryLives.to_s != ""
            policy.step = 0
            policy.statusCd = "PENDING"
            policy.campaignCode = quotation.campaignCode

            if quotation.isBackdatedFl.to_s == "YES"
                policy.policyCommencementDt = quotation.quotationDt
            else
                policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end

            if quotation.isBackdatedFl.to_s == "YES"
                policy.riskCommencementDt = quotation.quotationDt
            else
                policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end

            policy.baseAgentId = $userId
            policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY')
            # policy.policyNum = policy.proposalNum
            policy.intimationSourceCd = "ESUBMISSION"
            policy.uwDecisionCd = "PENDING"

            #Add data for non face-to-face
            companyFacet = CompanyFacet.find(
                :first,
                :conditions => {
                    { :name => 'facetCd' } => 'NONFACETOFACE'
                }
            )
            if companyFacet && companyFacet.actionValue.to_s == "YES"
                policy.allocatedToRole = "AGENT"
                policy.allowModifyAllRoles = "YES"
            else
                policy.allocatedToRole = "NA"
            end

            MobiSys::PolicyBO.convertIllustrationToEappPlanDetails(quotation, policy)
            
            policyHolder = Party.new(:roleCd => "PROPOSER")
            policy.addParty(policyHolder)
            MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, policyHolder, "PROPOSER")
            policyPartyRoleProposer = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => policyHolder.uniqueKey)
            policy.addPolicyPartyRole(policyPartyRoleProposer)

            if quotation.proposerLASame == "COPYFROMINSURED"
                policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => "PROPOSER")
                policy.addPolicyPartyRole(policyPartyRoleInsured)
                policy.insuredSameAsProposer = true
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => policyHolder.guid)
                        policyProduct.addPolicyProductInsured(primaryProductInsured)
                    end
                end
            else
                insured = Party.new(:roleCd => "PRIMARY")
                policy.addParty(insured)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, insured, "PRIMARY")
                policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => insured.uniqueKey, :partySameAsCd => "")
                policy.addPolicyPartyRole(policyPartyRoleInsured)
                policy.insuredSameAsProposer = false
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => insured.guid)
                        policyProduct.addPolicyProductInsured(primaryProductInsured)
                    end
                end
            end

            if quotation.getPartyByRole("JOINT")
            jointLife = Party.new(:roleCd => "JOINT")
                policy.addParty(jointLife)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, jointLife, "JOINT")
                policyPartyRoleJointLife = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => jointLife.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleJointLife)
                
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        jointProductInsured = PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => jointLife.guid)
                        policyProduct.addPolicyProductInsured(jointProductInsured)
                    end
                end
            end

            quotation.getPartyListByRoleCd("SUPPLEMENTARY").each_with_index do |oldParty, index|
                suppLife = Party.new(:roleCd => "SUPPLEMENTARY")
                policy.addParty(suppLife)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, suppLife, "SUPPLEMENTARY", index)
                policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => suppLife.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleSuppLife)
            end
            policy.persistAll
            quotation.proposalNum = policy.proposalNum
            quotation.persistAll
        end
        product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
        return policy
    end

    def postProcessEntity(parsedData, createResponseHash = true, isMetadataRequired = true)
        if createResponseHash
            @baseIO.baseDO.isInvalid = isInvalid
            @baseIO.baseDO.isCompleted = isCompleted
            @baseIO.baseDO.entityTypeCd = "QUOTATION"
        end
    end

    def isInvalid
        isInvalid = false
        quotation = @baseIO.baseDO
        if(!isCompleted && quotation && quotation.quotationDt.to_s != "" && quotation.quotationExpiryDt.to_s != "")
            todayDt = Time.parse(Time.new.strftime("%F 00:00:00 %z"))
            quotationExpiryDt = Time.parse(quotation.quotationExpiryDt.to_s)
            if(quotationExpiryDt < todayDt) 
                isInvalid = true
                quotationExpiryDays = "0"
                quotationExpiryDays = MobiSys::BrowserHelper.getFacetMappedValue("QUOTATIONEXPIRYDAYS", nil)
                toreturn_str = Localization::LabelCache.instance.getLabel(:invalidReason).to_s.force_encoding("UTF-8").clone
                quotation.invalidReason = MobiSys::CommonUtil.replacePlaceHolders(toreturn_str,[quotationExpiryDays,quotationExpiryDt.to_s])
            end
        end
        return isInvalid
    end
    
    def isCompleted   
        isCompleted=false;
        quotation = @baseIO.baseDO
        if(quotation && (quotation.quoteStatusCd.to_s == "ACCEPTED" || quotation.quoteStatusCd.to_s == "INFORCE"))
            isCompleted=true
        end
        return isCompleted
    end

   def solve(id,parsedData)
        quotation = @baseIO.baseDO
        solverFacetId = quotation.currentSolverFacetId
        $taskExceptionHash = []

        MobiSys::Solver.execute(@baseIO, solverFacetId) if solverFacetId.to_s != ""
        if !$taskExceptionHash.empty?
            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
            db.start_transaction
            $taskExceptionHash.each do |taskException|
                taskException.persistAll
            end
            db.commit
        end
        $taskExceptionHash = nil
        responseHash = {}
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        
        return responseHash
    end

    def calculateIllustration
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        process()
        quotation = @baseIO.baseDO
        MobiSys::QuotationService.initializeQuotationIO(quotation, nil)
        resultsSI = {}
        resultsSI["SICalc"] = $quotationIO.additionalData["SICalc"]

        siModelMap = {}
        siModelMap["modelCd"] = $quotationIO.illustrationModel.modelCd
        siModelMap["GlobalRates"] = $quotationIO.illustrationModel.IllustrationRateList
        siModelMap["FundRates"] = $quotationIO.originalSIModel.IllustrationRateList
        resultsSI["SIModel"] = siModelMap 

        responseHash = {}
        responseHash['data'] = resultsSI
        responseHash['success'] = true
        responseHash['message'] = "Successfully Calculate Illustration."
        return responseHash
    end

    def refreshEapp(id, parseData)
        begin
            policy = nil
            @baseIO.baseDO.entityStatus = "EAPPREFRESHED"
            @baseIO.baseDO.persistAll
            policy = MobiSys::QuotationService.refreshEapp(@baseIO.baseDO)
            @baseIO.baseDO.policySeq = policy.object if policy.to_s != ""
        rescue StandardError => se
            puts "exception: #{se}"
        end
    end

    def getLeadSeq
        responseHash = {}
        parsedData = parseRequestBodyParams
        if parsedData.has_key?("leadId")
            leadId = parsedData["leadId"].to_s
            leadSeq = Lead.loadObject(:first, :conditions => {:leadId => leadId}).object if leadId.to_s != ""
            if leadSeq.to_s != ""
                responseHash["data"] = {"leadSeq" => leadSeq}
            else
                responseHash["success"] = false
                responseHash["message"] = "LEAD Seq not found"
            end
        else
            responseHash["success"] = false
            responseHash["message"] = "LEAD ID not received"
        end
        render :string => responseHash.to_json
    end

end

begin 
    require 'Quotation/quotation_controller_company'
rescue LoadError => e
    puts 'quotation_controller_company not included'
end
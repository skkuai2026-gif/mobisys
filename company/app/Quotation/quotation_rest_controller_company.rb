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
                    key = "FUNDRISKCLASS" + fund.fundManagementCharges.to_s
                    quotationProductInvestmentFund.fundRiskClassLabel = $fundRiskClassCache[key.to_sym].desc if $fundRiskClassCache.has_key?(key.to_sym)
                    baseProduct.addQuotationProductInvestmentFund(quotationProductInvestmentFund)
                    end
                else
                    fund.delete
                end
            end

            quotationParty = quotation.getQuotationPartyByRole("PROPOSER")
            companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
            companyColorValue = companyColor.value.to_s if companyColor
            filteredList = Array.new
            if quotationParty.to_s != "" && quotationParty.partyTypeCd.to_s == "INDIVIDUAL"
                if companyColorValue.to_s == "SLGFI"
                    if quotation && quotation.fnaId.to_s != ""
                      fnaId = quotation.fnaId
                      fnaRequest = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})
                      listFnaFund = fnaRequest.FNAFundList
                      fnaFundList = listFnaFund.map{|x| x.fundCd.to_s}
                      quotationFundList = baseProduct.QuotationProductInvestmentFundList
                      quotationFundList.each do |investmentFund|
                        if fnaFundList.include?(investmentFund.fundCd.to_s)
                            listFnaFund.each do |fnaFund|
                                if fnaFund.fundCd.to_s == investmentFund.fundCd.to_s
                                    investmentFund.allocationPerc = investmentFund.topupAllocationPerc = fnaFund.allocationPerc
                                end
                            end
                        else
                            investmentFund.allocationPerc = nil
                            investmentFund.removed = 'YES'
                        end
                      end
                    end
                    filteredList = baseProduct.QuotationProductInvestmentFundList.select do |fund|
                      fund.vars[:allocationPerc].to_f > 0 || fund.vars[:removed].to_s == 'YES'
                    end
                elsif companyColorValue.to_s == "SLOCPI"
                    fnaId = quotation.fnaId
                    if fnaId.to_s != ""
                        fnaRequest = FNARequest.find(:first, :conditions => {:fnaNum => fnaId})
                        leadRPQ = LeadRPQ.find(:first, :conditions => {:rpqID => fnaRequest.addtnField1Str}) if fnaRequest   
                        if leadRPQ && leadRPQ.education.to_s != ''
                            rpqFundList = leadRPQ.education.split(",")
                            quotationFundList = baseProduct.QuotationProductInvestmentFundList
                            quotationFundList.each do |fund|
                                if rpqFundList.include?(fund.fundCd.to_s)
                                    fund.allocationPerc = 0.0
                                    filteredList.push(fund)
                                else
                                    fund.allocationPerc = nil
                                    fund.removed = 'YES'
                                    filteredList.push(fund)
                                end
                            end
                        end
                    end
                end

                # To remove quotationProductInvestmentFund from filterdList if removed set to YES
                filteredList.delete_if do |quotationProductInvestmentFund|
                    if quotationProductInvestmentFund.removed.to_s == 'YES'
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
                #merged filteredLIst in baseProduct.QuotationProductInvestmentFundList
                baseProduct.setQuotationProductInvestmentFundList(filteredList)
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
        if $lookupArray
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
        end
        if isMetadataRequired
            tempHash["metadata"] = metadataHash
            tempHash["lookups"] = @lookupHash
            contextEnd
        end
        tempHash['success'] = true
        tempHash['message'] = "Successful"

        render :string => tempHash.to_json
    end

    def getApplicableProducts
        parsedData = parseRequestBodyParams
        paramsBasePlan   = parsedData.dig("FormData", "Models", "BasePlan")
        $productIdExist  = !!paramsBasePlan&.dig("productId")
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
        @offlineApplicationEnvironment,@productFamilyList,@productIdList,@productPlanOptionList = MobiSys::ProductUtil.getApplicableProductsForApi(@baseIO.baseDO)
        data["applicationEnvironment"] =  @offlineApplicationEnvironment

        selectedId = @baseIO.baseDO.getBasePlan.productId
        if selectedId.to_s != ""
            familyKey, productList = @productIdList.find { |key, list| list.any? { |product| product[:cd] == selectedId } }
            if productList
                sortedList = productList.partition { |product| product[:cd] == selectedId }.flatten
                @productIdList[familyKey] = sortedList
            end
        end
       
        agentRegdetails = AgentReg.getCurrentAgentReg 
        tradLicenseStartDate = agentRegdetails.field15 if agentRegdetails
        tradLicenseEndDate   = agentRegdetails.agentField14 if agentRegdetails
        vulLicenseStartDate  = agentRegdetails.agentField15 if agentRegdetails
        vulLicenseEndDate    = agentRegdetails.agentField16 if agentRegdetails

        selectedFamily =  @baseIO.baseDO.getBasePlan.productFamilyCd
        if @baseIO.baseDO.quoteStatusCd.to_s != "ACCEPTED" && @baseIO.baseDO.quoteStatusCd.to_s != "SYNCDONE"
            # Remove TRAD if license
            if !isLicenseValid(tradLicenseStartDate, tradLicenseEndDate)
                if @productIdList.has_key?(:TRAD)
                  @productIdList[:TRAD] = []
                end

                if (selectedFamily.nil? || selectedFamily.upcase != "TRAD" || @productFamilyList.size() == 1 || (vulLicenseStartDate != null && vulLicenseEndDate != null) && !isLicenseValid(vulLicenseStartDate, vulLicenseEndDate))
                    @productFamilyList.delete_if { |item| item[:cd].to_s.upcase == "TRAD" }
                end
            end

            # Remove VUL if license
            if !isLicenseValid(vulLicenseStartDate, vulLicenseEndDate)
                if @productIdList.has_key?(:VUL)
                  @productIdList[:VUL] = []
                end

                if (selectedFamily.nil? || selectedFamily.upcase != "VUL" || @productFamilyList.size() == 1  || (tradLicenseStartDate != null && tradLicenseEndDate != null) && !isLicenseValid(tradLicenseStartDate, tradLicenseEndDate))
                    @productFamilyList.delete_if { |item| item[:cd].to_s.upcase == "VUL" }
                end
            end
        end

        data["productFamilyList"] = @productFamilyList
        data["productList"] = @productIdList
        # data["productVersionHash"] = @productVersionHash
        data["planOptionList"] = @productPlanOptionList

        companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
        companyColorValue = companyColor.value.to_s if companyColor
        if @baseIO.baseDO && @baseIO.baseDO.fnaId.to_s != "" && companyColorValue.to_s == "SLGFI"
            fnaRequest = FNARequest.find(:first, :conditions => {:fnaNum => @baseIO.baseDO.fnaId})
            if fnaRequest && fnaRequest.reasonForRecoCd.to_s != ""
                productCdToMatch = fnaRequest.reasonForRecoCd
                matchFound = false
                @productIdList.each do |key, list|
                    if key.to_s != "" && (key.to_s == "VUL" || key.to_s == "TRAD")
                        list.each do |product|
                            if product.to_s != ""
                                if product[:cd].to_s != "" && productCdToMatch.to_s != "" && product[:cd].to_s == productCdToMatch.to_s
                                    matchFound = true
                                    break
                                end
                            end
                        end
                    end
                end
                if !matchFound && @baseIO.baseDO.getBasePlan.to_s == ""
                    data["productFamilyList"] = []
                    data["productList"] = {}
                    data["planOptionList"] = {}
                end
            end
        end

        responseHash['data'] = data
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        $productIdExist = true
        render :string => responseHash.to_json
    end

    def isLicenseValid(startDate, endDate)
        begin
            dateFormat = '%d-%b-%Y'
            today = Date.today

            # Treat nil and blank strings as nil
            startDate = nil if startDate.nil? || startDate.to_s.strip.empty?
            endDate = nil if endDate.nil? || endDate.to_s.strip.empty?

            # Both dates are missing
            return false if startDate.nil? && endDate.nil?

            # Only end date is available
            if startDate.nil?
              endDateValue = Date.strptime(endDate, dateFormat)
              return today <= endDateValue
            end

            # Only start date is available
            if endDate.nil?
              startDateValue = Date.strptime(startDate, dateFormat)
              return today >= startDateValue
            end

            # Both dates are available
            startDateValue = Date.strptime(startDate, dateFormat)
            endDateValue = Date.strptime(endDate, dateFormat)

            today >= startDateValue && today <= endDateValue

        rescue => e
            p "isLicenseValid ERROR: #{e.class} - #{e.message}"
            false
        end
    end

    def process
        # logInfo "~~~in quotation process"
        #Add executeLife code here for initializin quot_product
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct()
        newBaseProduct = baseProduct if baseProduct
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
         parsedData = parseRequestBodyParams
        fetchData = parsedData['FetchData'] if parsedData.has_key?("FetchData")
        currentActiveTab = fetchData['currentActiveTab'] if fetchData && fetchData.has_key?("currentActiveTab")
        #check if any party attributes have changed then need to check if product is still applicable
        if (!@baseIO.additionalData || !@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") || (@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") && @baseIO.additionalData['TRIGGERCHANGEPLAN'].to_s != "YES"))
            #MobiSys::QuotationUtil.checkProductApplicable(quotation)
        end

        if @baseIO.additionalData && @baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") && @baseIO.additionalData['TRIGGERCHANGEPLAN'].to_s == "YES" && currentActiveTab == 'tab_selProduct'
           @baseIO.baseDO.autoRegistrationNum = '' 
        end

        if currentActiveTab == 'tab_plan'
            @baseIO.baseDO.autoRegistrationNum = 'YES' if @baseIO.baseDO.autoRegistrationNum.to_s == ""
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
            if quotationParty.dob.to_s != ""
                quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                quotationParty.age = MobiSys::ProductBO.calculateAge(quotation, quotation.getBaseProduct, quotationParty, nil, getScreenDate(Time.new.to_s)).split("|")[0]
                quotationParty.dob = getDBDate(quotationParty.dob.to_s)
            end
            if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.proposerLASame == 'YES')
                quotationParty.quotPartyAddtnField4  = "YES"
            else
                quotationParty.quotPartyAddtnField4 = "NO"
            end
            if quotationParty.roleCd.to_s == "PRIMARY"
                quotationParty.partyTypeCd = "INDIVIDUAL" if quotationParty.partyTypeCd.to_s == ""
            end
        end
        @baseIO.baseDO.QuotationProductList.each do|quotationProduct|
            if quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs =  MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
            end
            if quotationProduct.productTypeCd == "RIDER" 
                # if currentActiveTab.to_s == "tab_plan"
                #    quotationProduct.baseSumAssured = 0
                # end   
                quotationProduct.wopPremium = 0
                if quotationProduct.selected.to_s == "YES" && quotationProduct.removed.to_s == "YES"
                  quotationProduct.removed = ''
                end
            end
        end 

        if baseProduct
            baseProduct.QuotationProductInvestmentFundList.each do|investmentFund|
                if investmentFund && investmentFund.allocationPerc.to_s == ""
                    investmentFund.removed = "YES"
                end
            end  
        end

        reqBodyHash = Hash.new
        formDataHash = Hash.new
        modelsHash = Hash.new
        entityHash = Hash.new

        if @params.has_key? ('request-body')
            begin
                reqBodyHash = Rho::JSON.parse(@params['request-body']) 
                formDataHash = reqBodyHash['FormData'] if reqBodyHash.has_key? ('FormData')
                modelsHash = formDataHash['Models'] if formDataHash.has_key? ('Models')
                entityHash = modelsHash['Entity'] if modelsHash.has_key? ('Entity')
                if entityHash && entityHash['stepActionTabs'].to_s == "tab_selProduct," && (entityHash['productFamilyCd'].to_s != newBaseProduct.productFamilyCd || entityHash['productId'].to_s != newBaseProduct.productId )
                    if quotation.visitedTabs.include? (",tab_plan")
                        quotation.update_attributes(:visitedTabs => quotation.visitedTabs.to_s.gsub(",tab_plan",""))
                    end
                end
            rescue Exception => e
                logError("Error in parsing request-body",e, LOGCATEGORY)
            end
        end 

        MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
        # saveValidate
        saveModel = @saveModel != nil ? @saveModel : true
        if quotation.action.to_s == ""
            quotation.action = "Save"
        end
        agentRegdetails = AgentReg.getCurrentAgentReg 
        quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
        if quotation.leadId.to_s == ""
        quotation.quotAddtnlField12 = "INDIVIDUAL"
        quotation.quotAddtnlField11 = "BOTH"
        end

        MobiSys::QuotationService.saveValidate(quotation,saveModel)
        MobiSys::QuotationService.populateMultiLife(quotation)
        # signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid})
        # @baseIO.signatureList = signatureContainer
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(quotation.guid,quotation.visitedTabs)
        @quotation = quotation
        tabName, tabLabel = MobiSys::QuotationService.requiredTabs
        visitedTabs = quotation.visitedTabs.to_s.split(",").reject{ |c| c.empty? }
        tabName = tabName.split(",")
        if (@errors!=nil && !@errors.empty?) || (@incompleteTabs!=nil && !@incompleteTabs.empty?) || ((tabName - visitedTabs).join("").to_s != "" && ((tabName - visitedTabs).join("").to_s != "tab_supplementary") && (tabName - visitedTabs).join("").to_s != "tab_selProduct" && (tabName - visitedTabs).join("").to_s != "tab_rider")
            quotation.quoteStatusCd = MobiSys::QuotationBO::PENDING
        else
            quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
        end
        propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
        quotation.proposalVersion =  propVersion.value.to_s if propVersion && propVersion.value.to_s != "" && quotation.leadId.to_s == ""
        quotation.persistAll
        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.entityTypeCd = "QUOTATION" #Temp added need to discuss with Nikhil
        @baseIO.baseDO.totAnnualPremium = quotation.getTotAnnualPremium if quotation && quotation.getTotAnnualPremium.to_s != ""
        @baseIO.baseDO.totModalPremium = quotation.getTotModalPremium if quotation && quotation.getTotModalPremium.to_s != ""
    end

    def viewCSA
        parsedData = parseRequestBodyParams
        fnaId = parsedData['fnaId'] if parsedData.has_key?("fnaId")        
        fnaRequest = FNARequest.find(:first, :conditions => {:fnaNum => fnaId.to_s}) if fnaId

        responseHash = {}
        if fnaRequest.to_s != ''
            responseHash = {"data" => {"fnaSeq" => fnaRequest.object.to_s},
                                "success" => true,
                                "message" => "Success."}
        else
            responseHash = {"success" => false, "message" => "FNA Seq not found try again."}
        end
        render :string => responseHash.to_json
    end

    def calculatePremium(id,parsedData)
        # on change of currencyCd, set portfolio model code
        if $currentActiveField.to_s == "currencyCd"
            MobiSys::QuotationService.getPortfolioModels(@baseIO.baseDO,@baseIO.baseDO.getBaseProduct(),$currentProduct)
        end
        @baseIO.baseDO.QuotationProductList.each do|quotationProduct|
            if quotationProduct.productTypeCd.to_s == "RIDER" 
                if $currentActiveTab.to_s == "tab_plan" && $currentActiveField.to_s == "baseSumAssured"
                   quotationProduct.baseSumAssured = 0
                end   
            end
        end
        MobiSys::QuotationService.calculatePremium(@baseIO.baseDO)        
    end

    def viewLeadOnQuotation
        parsedData = parseRequestBodyParams
        leadId = parsedData['leadId'] if parsedData.has_key?("leadId")        
        lead = Lead.find(:first, :conditions => {:leadId => leadId.to_s}) if leadId

        responseHash = {}
        if lead.to_s != ''
            responseHash = {"data" => {"leadSeq" => lead.object.to_s},
                                "success" => true,
                                "message" => "Success."}
        else
            responseHash = {"success" => false, "message" => "Lead Seq not found try again."}
        end
        render :string => responseHash.to_json
    end

    def acceptQuotation(id,parsedData)
        # parsedData = parseRequestBodyParams
        # fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        quotation.action = "Submit"
        signatureHash = {}
        @success = false
        @message = "Quotation not found"
        @saveModel = false

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
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                #Probably add validation (process function) here
                # quotation.signature = "SUCCESS"
                quotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
                quotation.signatureDt = Time.new.strftime("%F 00:00:00 %z")
                quotation.persistAll
                MobiSys::TrackLeadBO.updateTrackLead(quotation)
                #code commented for while acceptquotation Quotation is sync in online DPHSS-8303
                # if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                #     p"@baseIO.emailRequestDO=======#{@baseIO.emailRequestDO}"
                #     emailRequest = @baseIO.emailRequestDO
                #     $CreateOutputFiles = false
                #     MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                #     $quotationIO.emailRequestDO = emailRequest
                #     # result = MobiSys::QuotationService.generateOutputHTML()
                # end
                # addUserActivity in acceptQuotation
                MobiSys::CommonUtil.addUserActivity('ACCEPTQUOTATION_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId}", 'QUOTATION', quotation.quotationRefNum)
                @success = true
                @message = "Successful"
            else
                @message = getLabelValue('systemError')
                @success = false 
                isValid = false
            end
        end
        @saveModel = nil
        return nil
    end

    def acceptQuotationRaw(id,parsedData)
        # parsedData = parseRequestBodyParams
        # fetch(@params["id"]) if @params.has_key?("id")
        quotation = @baseIO.baseDO
        quotation.action = "Submit"
        signatureHash = {}
        @success = false
        @message = "Quotation not found"
        @saveModel = false

        if quotation
            if quotation.entityStatus.to_s == "REOPEN"
                quotation.entityStatus = "LOCKED"
                quotation.persistAll
            end
            # process()
            quotation = @baseIO.baseDO
            signatureContainer = SignatureContainer.loadObject(:first,
                                        :conditions => {
                                        :entityGuid => quotation.guid
                                        }
                                )

            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(quotation.guid, quotation.visitedTabs)
            if errors.empty? && errorTabs == "" && incompleteTabs.empty?
                #Probably add validation (process function) here
                # quotation.signature = "SUCCESS"


                baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
                baseProduct.multiLifeField2 = nil
                solverModelFacet = $currentProduct.getFacetValue('TARGETFUNDSOLVERFORV8') if $currentProduct
                if solverModelFacet && baseProduct && baseProduct.productTerm.to_s != '' && baseProduct.targetFundVal.to_s != '' && baseProduct.targetFundVal.to_i != 0 && baseProduct.targetPeriod.to_s != '' && baseProduct.targetPeriod.to_i != 0
                    quotationIO = MobiSys::IO::QuotationIO.new
                    quotationIO.baseDO = quotation.cloneObject
                    MobiSys::Solver.execute(quotationIO, "TARGETFUNDSOLVERFORV8")

                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup
                    if regularQuotationTopup
                        baseProduct.multiLifeField2 = regularQuotationTopup.topUpAmount
                    end
                end 
           
                quotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
                quotation.signatureDt = Time.new.strftime("%F 00:00:00 %z")
                quotation.persistAll
                MobiSys::TrackLeadBO.updateTrackLead(quotation)
                #code commented for while acceptquotation Quotation is sync in online DPHSS-8303
                # if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                #     p"@baseIO.emailRequestDO=======#{@baseIO.emailRequestDO}"
                #     emailRequest = @baseIO.emailRequestDO
                #     $CreateOutputFiles = false
                #     MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                #     $quotationIO.emailRequestDO = emailRequest
                #     # result = MobiSys::QuotationService.generateOutputHTML()
                # end

                quotationPortfolioModelCode = quotation.QuotationProductList
                                              .find { |qpd| 
                                                qpd.productTypeCd == "PLAN"
                                              }&.portfolioModelCd

                if quotation.proposalNum.to_s !=""
                    policyDO = Policy.find(:first, :conditions => {:quotationRefGuid => quotation.guid })
                    policyProduct = PolicyProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>policyDO.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if policyDO
                    policyPortfolioModelCode = policyProduct.portfolioModelCd if policyProduct
                end

                # addUserActivity in acceptQuotation
                MobiSys::CommonUtil.addUserActivity('ACCEPTQUOTATION_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'QUOTATION', quotation.quotationRefNum)
                @success = true
                @message = "Successful"
            else
                @message = getLabelValue('systemError')
                @success = false 
                isValid = false
            end
        end
        @saveModel = nil
        return nil
    end

    def generateIllustrationPdf
        $graphHtmlCounter = 0
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        quotation = @baseIO.baseDO
        policy = Policy.find(:first, :conditions => {:quotationRefNum => quotation.quotationRefNum.to_s}) if quotation
        $submitPolicyFlag = true if policy
        $agentFlagRS = false if policy
        $policyFlag = "true" if policy
        if policy 
            if policy.allocatedToRole.to_s != "" && policy.allocatedToRole.to_s == "AGENT"
              $agentFlagRS = true   
            end
            if policy.statusCd.to_s != "SUBMITTED"
                $submitPolicyFlag = false
            end 
        end
       
        if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""
            outputPref = OutputPreferences.new
            outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

            responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        else
            if $rhoconfig[:offlinePDFGeneration] && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'

                quotationPortfolioModelCode = quotation.QuotationProductList
                                          .find { |qpd| 
                                            qpd.productTypeCd == "PLAN"
                                          }&.portfolioModelCd
                if policy
                    policyProduct = PolicyProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>policy.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND')
                    policyPortfolioModelCode = policyProduct.portfolioModelCd if policyProduct
                end
                
                # ofline pdf generation
                MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                result = MobiSys::QuotationService.generateOfflinePDFHTML()
                if result.has_key?('error') and result['error'].to_s != ""
                    responseHash['success'] = false
                    responseHash['message'] = result['error'].to_s
                else
                    responseHash['data'] = {"FileName" => result['pdfFileName'], "pdfMode" => "offlinePDFGeneration"}
                    responseHash['success'] = true
                    responseHash['message'] = "Pdf generated successfully."
                end

                # addUserActivity in generateIllustrationPdf
                MobiSys::CommonUtil.addUserActivity('DOWNLOADQUOTATIONPDF_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'QUOTATION', quotation.quotationRefNum)
            else
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
                    if navigateToSync
                        responseHash['success'] = false
                        responseHash['message'] = "Please take Primary database sync."
                    else
                        quotationPartyList = quotation.QuotationPartyList
                        lastNamePrimary = ''
                        firstNamePrimary = ''
                        filename = ''
                        baseProduct = quotation.getBasePlan
                        quotationPartyList.each do |quotationParty|
                            if quotationParty.roleCd == 'PRIMARY'
                              lastNamePrimary = quotationParty.lastname
                              firstNameArray = quotationParty.firstname.split(" ")
                              firstNamePrimary = firstNameArray.map do |word|
                                word.strip.empty? ? '' : word.strip[0].upcase
                              end.join
                            end
                        end

                        company =  CompanyFacet.find(
                                :first,
                                :conditions => {
                                    { :name => 'facetCd' } => 'PROPPDFFILENAME'
                                }
                            )
                        if company.actionTypeCd.to_s == "RULE"
                            facetValue = company.ruleSeq 
                            pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(facetValue, quotation, baseProduct)
                            facetValuePlanCd = pdt.outputAction
                            dateTime = DateTime.now.strftime('%d%m%Y%H%M%S')
                            filename = "#{lastNamePrimary}_#{firstNamePrimary}_#{facetValuePlanCd}_#{dateTime}.pdf"
                        end
                        if $rhoconfig[:offlineOutputGeneration]
                            
                            $CreateOutputFiles = false

                            quotationPortfolioModelCode = quotation.QuotationProductList
                                                      .find { |qpd| 
                                                        qpd.productTypeCd == "PLAN"
                                                      }&.portfolioModelCd
                            if policy
                                policyProduct = PolicyProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>policy.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND')
                                policyPortfolioModelCode = policyProduct.portfolioModelCd if policyProduct
                            end

                            MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                            result = MobiSys::QuotationService.generateOutputHTML()
                            if result.has_key?('error') and result['error'].to_s != ""
                                responseHash['success'] = false
                                responseHash['message'] = result['error'].to_s
                            else
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => filename}
                                responseHash['success'] = true
                                responseHash['message'] = "Pdf generated successfully."
                            end

                            # addUserActivity in generateIllustrationPdf
                            MobiSys::CommonUtil.addUserActivity('DOWNLOADQUOTATIONPDF_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'QUOTATION', quotation.quotationRefNum)   
                        else
                            outputPreferencesDO = nil
                            outputPreferencesDO = @baseIO.outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES" 
                            result = MobiSys::QuotationService.get_pdf(quotation, outputPreferencesDO)
                            if result and result.has_key?('PDFCONTENT')

                                quotationPortfolioModelCode = quotation.QuotationProductList
                                                          .find { |qpd| 
                                                            qpd.productTypeCd == "PLAN"
                                                          }&.portfolioModelCd
                                if policy
                                    policyProduct = PolicyProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>policy.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND')
                                    policyPortfolioModelCode = policyProduct.portfolioModelCd if policyProduct
                                end

                                 # addUserActivity in generateIllustrationPdf
                                MobiSys::CommonUtil.addUserActivity('DOWNLOADQUOTATIONPDF_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'QUOTATION', quotation.quotationRefNum)  
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => filename}
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

    def newPolicy(quotation)
        $rhoconfig[:moduleForProductValidations] = "Policy"
        quotpolicy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
        agentRegdetails = AgentReg.getCurrentAgentReg
        if quotpolicy
            policy = quotpolicy
        else
            policy = Policy.new
            MobiSys::CommonUtil.copyFields(quotation, policy, MobiSys::PolicyBO::FIELDS_TO_EXCLUDE)
            # policy.quotationRefGuid = quotation.uniqueKey
            policy.quotationRefGuid = quotation.guid
            policy.branchCd = quotation.quotAddtnlField2
            policy.quotAddtnlField5 = agentRegdetails.field11
            policy.quotAddtnlField6 = agentRegdetails.field12
            policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
            policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
            policy.supplementaryLives = quotation.supplementaryLives if quotation.supplementaryLives.to_s != "" #need to verify 
            policy.step = 0
            policy.stepActionTabs = nil
            policy.statusCd = "PENDING"
            policy.policyIssueDt = quotation.issueDt

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
                policy.quoteProposerSameAsInsured = "YES"
                policyHolder.relationCd = "INSUR"
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
                policy.quoteProposerSameAsInsured = "NO"
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

    def fetch(id)
        $currentPolicy = nil
        quotation = Quotation.loadObject(:first, :conditions => {:object => id})
        if quotation
            @baseIO.baseDO = quotation 
            agentRegdetails = AgentReg.getCurrentAgentReg 
            @baseIO.baseDO.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
        end
        policy = Policy.loadObject(:first, :conditions=>{:quotationRefGuid=>@baseIO.baseDO.guid.to_s}) if @baseIO.baseDO
        if policy.to_s != ""
            @baseIO.baseDO.policySeq = policy.object
        end
        @baseIO.baseDO.isViewEappApplicable = isViewEappApplicable(quotation, policy) if quotation && policy
        @baseIO.baseDO.isEappLinkApplicable = MobiSys::QuotationService.isEappLinkApplicable(quotation) if quotation
        @baseIO.baseDO.totAnnualPremium = quotation.getTotAnnualPremium if quotation && quotation.getTotAnnualPremium.to_s != ""
        @baseIO.baseDO.totModalPremium = quotation.getTotModalPremium if quotation && quotation.getTotModalPremium.to_s != ""
    end

    def isViewEappApplicable(quotation, policy)
        viewEapp = ''
        if quotation.proposalNum.to_s != '' && policy.applicationRefNum.to_s != '' && policy.statusCd.to_s != '' && policy.statusCd.to_s == 'SUBMITTED'
            viewEapp = 'NO'
        end
        return viewEapp
    end

    def isCompleted   
        isCompleted=false;
        quotation = @baseIO.baseDO
        if(quotation && (quotation.quoteStatusCd.to_s == "ACCEPTED" || quotation.quoteStatusCd.to_s == "INFORCE" || quotation.quoteStatusCd.to_s == "SYNCDONE"))
            isCompleted=true
        end
        return isCompleted
    end

    def convertToEapp(id, parseData)
        quotation = @baseIO.baseDO
        err_message = ''
        responseHash = {}
        proposalExpiredCheck = MobiSys::QuotationService.hasProposalExpired(quotation) if quotation
        unless proposalExpiredCheck
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

                # policyPortfolioModelCode = existingPolicyDO.PolicyProductList
                #                       .find { |ppd| 
                #                         ppd.productTypeCd == "PLAN"
                #                       }&.portfolioModelCd
                # p"policyPortfolioModelCode---------refreshEapp---------#{policyPortfolioModelCode}"


                quotationPortfolioModelCode = quotation.QuotationProductList
                                      .find { |qpd| 
                                        qpd.productTypeCd == "PLAN"
                                      }&.portfolioModelCd

                # addUserActivity to convertToEapp
                MobiSys::CommonUtil.addUserActivity('LINKTOEAPP_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},quotationPortfolioModelCode => #{quotationPortfolioModelCode} ", 'QUOTATION', quotation.quotationRefNum)
            else
                err_message = 'Quotation not found.'
            end
        else
        Alert.show_popup({
            :message => MobiSys::BrowserHelper.getLabel('Quotation is expired'),
            :title => '',
            :icon => :alert,
            :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
        })
            err_message = "Quotation is expired"
        end
        
        if err_message != ''
            responseHash['success'] = false
            responseHash['message'] = err_message
        end
        return responseHash
    end

    #added below method temporarily, as added $policyflag it is required for mvelhashflag showsignflafg set as true
    def viewIllustration
        responseHash = {}
        data = {}
        if !Rho::System.isRhoSimulator
            # 2 times parsing require because it converts to json object again before calling from native
            ####
            parsedData = Rho::JSON.parse(@params['request-body'])
            if parsedData.has_key?("params")
                parseData2 = Rho::JSON.parse(parsedData["params"])
            else 
                parseData2 = parsedData
            end
            formData = {}
            if @params.has_key?("id")
                fetch(@params["id"]) 
            else
                if parseData2.has_key?('FormData') && parseData2['FormData'].has_key?('Models') && parseData2['FormData']["Models"].has_key?('Entity')
                    formData = parseData2['FormData']["Models"]["Entity"]
                end
                fetch(formData["object"]) if formData.has_key?('object')
            end
            fetchData(parseData2,false,false)
            ###
        else
            parsedData = parseRequestBodyParams
            fetch(@params["id"]) if @params.has_key?("id")
            fetchData(parsedData,false,false)
        end
        # process()
        quotation = @baseIO.baseDO
        $graphHtmlHM = {}
        $graphHtmlCounter = 0
        $graphHtmlCallbackCounter = 0
        
        policy = Policy.find(:first, :conditions => {:quotationRefNum => quotation.quotationRefNum.to_s}) if quotation
        $submitPolicyFlag = true if policy
        $agentFlagRS = false if policy
        $policyFlag = "true" if policy
        if policy 
            if policy.allocatedToRole.to_s != "" && policy.allocatedToRole.to_s == "AGENT"
              $agentFlagRS = true   
            end
            if policy.statusCd.to_s != "SUBMITTED"
                $submitPolicyFlag = false
            end 
        p " $agentFlagRS====#{$agentFlagRS}= $submitPolicyFlag--#{$submitPolicyFlag}=="     
        end
        quotation.update_attributes(:systemUpdatedDt => Time.now) if quotation.respond_to?(:update_attributes)
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
                            "/public/jquery/jquery-3.7.1.min.js",
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
                        $quotationIO.signatureList =  MobiSys::CommonUtil.openstruct_to_hash(this.si.Quotation.ServiceSignatureList)
                    else
                        $quotationIO.signatureList = this.si.Quotation.ServiceSignatureList.hashForApi
                    end
                    if $quotationIO.isFullHTMLRequired
                        responseHash['data'] = {"viewHtmlIllustration" => $quotationIO.htmlContent.first}
                    else
                        MobiSys::SymTemplateUtil.loadHTMLBodyContent($quotationIO.htmlContent.first, $quotationIO.bodyContent, $quotationIO.cssContent)
                        responseHash['data'] = { "viewHtmlIllustration" => $quotationIO.bodyContent, "htmlStyles" => $quotationIO.cssContent }
                    end
                    # responseHash['data']['signatureList'] = $quotationIO.signatureList


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
                        # responseHash['data']['signatureList'] = $quotationIO.signatureList


                    else
                        MobiSys::QuotationService.commonShowBenefitTable()
                        responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}    
                    end

                end
            else
                MobiSys::QuotationService.commonShowBenefitTable()
                responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
            end
 
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
                    # responseHash['data']['signatureList'] = $quotationIO.signatureList
                    responseHash['success'] = true
                    responseHash['message'] = "Illustration HTML generated successfully."
                   
                    $graphHtmlHM = nil
                    $graphHtmlCounter = nil
                    $graphHtmlCallbackCounter = nil
                    Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
                else
                    # responseHash['data'] = {"viewIllustration" => $quotationIO.htmlContent.first}
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
                    # responseHash['data']['signatureList'] = $quotationIO.signatureList
                    responseHash['success'] = true
                    responseHash['message'] = "Illustration HTML generated successfully."
                    $graphHtmlHM = {}
                    $graphHtmlCounter = 0
                    $graphHtmlCallbackCounter = 0
                    Rho::Ruby.callNativeCallback("HtmlCreated", responseHash)
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

                responseHash['success'] = true
                responseHash['message'] = "Illustration HTML generated successfully."
            end
        end
        
        render :string => responseHash.to_json 
    end

    def htmlCallback
        graphBase64 = @params['html']
        graphPlaceHolder = @params['graphPlaceHolder']
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

    def sendEmail
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetchData = parsedData['FetchData'] if parsedData.has_key?("FetchData")
        currentActiveTab = fetchData['currentActiveTab'] if fetchData && fetchData.has_key?("currentActiveTab")
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
                MobiSys::QuotationService.leadEmailOtpSent(quotation)
                MobiSys::QuotationService.fnaDataSync(quotation)
                forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
                if navigateToSync
                    responseHash['success'] = false
                    responseHash['message'] = "Please take Primary database sync."
                else
                    if $rhoconfig[:offlineOutputGeneration]
                        $CreateOutputFiles = false
                        MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)
                        $quotationIO.emailRequestDO = emailRequest
                        errors = Hash.new
                        MobiSys::CommonUtil.clearTaskExceptionList(emailRequest.guid)
                        $taskExceptionHash = [] unless $taskExceptionHash
                        MobiSys::QuotationBO.validateEmailRequest(quotation, emailRequest, errors, currentActiveTab)
                        errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(emailRequest.guid, quotation.visitedTabs)
                        if !errors.empty?
                            responseHash['success'] = false
                            responseHash['validationerrors'] = errors
                            responseHash['message'] = getLabelValue('emailSendFail')
                        else
                            result = MobiSys::QuotationService.generateOutputHTML()
                            responseHash['success'] = true
                            responseHash['message'] = "Successful"
                            if result["error"].to_s != ""
                                responseHash['success'] = false
                                responseHash['message'] = result["error"]
                            end
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

        if quotation.proposalNum.to_s !=""
            policyDO = Policy.find(:first, :conditions => {:quotationRefGuid => quotation.guid })
            policyProduct = PolicyProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>policyDO.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if policyDO
            policyPortfolioModelCode = policyProduct.portfolioModelCd if policyProduct
                    
        end
        
        quotationPortfolioModelCode = quotation.QuotationProductList
                              .find { |qpd| 
                                qpd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

         # addUserActivity in sendEmail 
        MobiSys::CommonUtil.addUserActivity('SENDEMAIL_OFFLINE',"quotationRefNum => #{quotation.quotationRefNum},proposalNum => #{quotation.proposalNum},quotationGuid => #{quotation.guid},quotationfnaId => #{quotation.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode} ", 'QUOTATION', quotation.quotationRefNum)
        render :string => responseHash.to_json 
    end

    def deleteQuotation
        parsedData = parseRequestBodyParams
        tempHash = {}
        if @params.has_key?("id") || (parsedData.has_key?("ids") && parsedData['ids'].to_s != "" && !parsedData['ids'].to_s.include?(","))
            id = @params["id"] if @params.has_key?("id")
            id = parsedData['ids'] if (parsedData.has_key?("ids") && parsedData['ids'].to_s != "" && !parsedData['ids'].to_s.include?(","))
            fetch(id)
            quotation = @baseIO.baseDO
            if quotation
                if quotation.quoteStatusCd != "ACCEPTED"
                    if quotation.proposalNum.to_s == ""
                        MobiSys::QuotationService.deleteQuotation(quotation)
                        tempHash = {"success" => true, "message" => "Quotation deleted successfully"}
                    else
                        message = getLabelValue("ERR_DeleteQuotationIgnore")
                        tempHash = {"success" => false, "message" => message}
                    end
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
                            if quotation.proposalNum.to_s == ""
                                MobiSys::QuotationService.deleteQuotation(quotation)
                                successDeletedQuotation += 1
                            else
                                failedDeletedQuotation += 1
                            end
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

            sourceQuotationPortfolioModelCode = sourceQuotation.QuotationProductList
                                  .find { |qpd| 
                                    qpd.productTypeCd == "PLAN"
                                  }&.portfolioModelCd

            targetQuotationPortfolioModelCode = targetQuotation.QuotationProductList
                                  .find { |qpd| 
                                    qpd.productTypeCd == "PLAN"
                                  }&.portfolioModelCd

            MobiSys::CommonUtil.addUserActivity('COPYQUOTATION_OFFLINE',"QuotationOld => #{sourceQuotation.quotationRefNum},QuotationNew => #{targetQuotation.quotationRefNum},QuotationOldguid => #{sourceQuotation.guid},QuotationNewguid => #{targetQuotation.guid},QuotationFnaId => #{targetQuotation.fnaId},QuotationOldFnaId => #{sourceQuotation.fnaId},sourceQuotationPortfolioModelCode => #{sourceQuotationPortfolioModelCode},targetQuotationPortfolioModelCode => #{targetQuotationPortfolioModelCode}", 'QUOTATION', targetQuotation.quotationRefNum)
            @message = "Copy Successful"
        else
            responseHash["success"] = false
            responseHash["message"] = "Quotation not found"
        end
        return responseHash
    end
end

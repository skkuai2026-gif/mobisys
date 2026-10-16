require 'CommonModules/mobisysuihelper_jazz'
require 'fileutils'
require 'TrackLead/track_lead_b_o'
require 'base64'

class QuotationController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper


    def requiredTabs
        requiredTabs = Hash.new
        $prdSelectionFacet ||= $rhoconfig[:prdSelection]
        if @quotation.insuranceTypeCd.to_s == 'AUTO'
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                requiredTabs['tab_basic'] = 'tab_basic'
                if $rhoconfig[:tab_based_product_selection]
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
            else
                if $rhoconfig[:tab_based_product_selection]
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
                requiredTabs['tab_basic'] = 'tab_basic'
            end
            if $currentProduct
                riderAssocFacet = $currentProduct.getFacet('RIDERASSOCIATION')
                if riderAssocFacet && riderAssocFacet.OfflineRiderAssociationList.size > 0
                    requiredTabs['tab_rider'] = 'tab_rider'
                end
            end
            requiredTabs['tab_premiumSummary'] = 'premiumSummary'
        elsif @quotation.insuranceTypeCd.to_s == 'TRAVEL'
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                requiredTabs['tab_basic'] = 'tab_basic'
                if $rhoconfig[:tab_based_product_selection]
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
            else
                if $rhoconfig[:tab_based_product_selection]
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
                requiredTabs['tab_basic'] = 'tab_basic'
            end
            if $currentProduct
                riderAssocFacet = $currentProduct.getFacet('RIDERASSOCIATION')
                if riderAssocFacet && riderAssocFacet.OfflineRiderAssociationList.size > 0
                    requiredTabs['tab_rider'] = 'tab_rider'
                end
            end
            requiredTabs['tab_premiumSummary'] = 'premiumSummary'
        else
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                requiredTabs['tab_basic'] = 'tab_basic'
                if $rhoconfig[:tab_based_product_selection] && (@quotation == nil || (@quotation.quoteStatusCd.to_s != 'ACCEPTED' && @quotation.quoteStatusCd.to_s != 'SYNCDONE'))
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
            else
                if $rhoconfig[:tab_based_product_selection] && (@quotation == nil || (@quotation.quoteStatusCd.to_s != 'ACCEPTED' && @quotation.quoteStatusCd.to_s != 'SYNCDONE'))
                   requiredTabs['tab_selProduct'] = 'tab_selProduct'
                end
                requiredTabs['tab_basic'] = 'tab_basic'
            end
            if $currentProduct && $currentProduct.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES'
                requiredTabs['tab_plan'] = 'tab_plan'
                if MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                    requiredTabs['tab_supplementary'] = 'FAMILYINSUREDDETAILS'
                end
            else
                if MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                    requiredTabs['tab_supplementary'] = 'supplementary'
                end
                requiredTabs['tab_plan'] = 'tab_plan'
            end
            if $currentProduct
                riderAssocFacet = $currentProduct.getFacet('RIDERASSOCIATION')
                if riderAssocFacet && riderAssocFacet.OfflineRiderAssociationList.size > 0
                    requiredTabs['tab_rider'] = 'tab_rider'
                end
            end
        end
        tabName = requiredTabs.keys.join(",")
        tabLabel = requiredTabs.values.join(",")
        tabIcon = ""
        # if $rhoconfig[:application_view_mode] == "mobile"
            tabIcon = requiredTabs.keys.join(",")
            tabIcon.gsub!('tab_basic','icon-personal-info')
            tabIcon.gsub!('tab_selProduct','icon-select-product')
            tabIcon.gsub!('tab_supplementary','icon-supplementary')
            tabIcon.gsub!('tab_plan','icon-coverage')
            tabIcon.gsub!('tab_rider','icon-rider-details')
            tabIcon.gsub!('tab_premiumSummary','icon-summary')
        # end
        return tabName,tabLabel,tabIcon
    end
    ########################################################################################################

    
    def getAge
        partyObject = @params['partyObject']
        quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
        quotation.quotationDt = getScreenDate(quotation.quotationDt)
        @errors = Hash.new
        quotation.QuotationPartyList.each do |quotationParty|
            if quotationParty.object == partyObject
                quotationParty.dob = getScreenDate(quotationParty.dob)
                @age = MobiSys::ProductBO.calculateAge(quotation, quotation.getBaseProduct, quotationParty,@errors)
            end
        end
        render :string => @age.to_json
    end
    ########################################################################################################
    

    def getBirthDt
        quotationDt = @params["quotationDt"]
        @age = @params["age"]
        prdIssueDt = $currentProduct.getFacet('PRDISSUEDATE') if $currentProduct
        dt = (prdIssueDt && prdIssueDt.actionValue.to_s != "") ? Time.parse(prdIssueDt.actionValue) : Time.parse(quotationDt)
        if @age != nil
            @birthDt = MobiSys::ProductUtil.calculateDOB(@age, dt)
        end
        render :string => getScreenDate(@birthDt.to_s)
    end
    ########################################################################################################

    def search
        if @params['insuranceTypeCd'].to_s != ''
            @insuranceType = @params['insuranceTypeCd']
        else
            @insuranceType = nil
        end
        render :action => :QuoteSearch_Jazz, :layout => :jazzLayout
    end

     def searchmulti
        WebView.execute_js("loading('show');")
        # company specific starts here
        searchParams = @params
        if @params['insuranceTypeCd'].to_s != ''
            @insuranceType = @params['insuranceTypeCd']
        else
            @insuranceType = nil
        end
        if @params.has_key?('insuranceTypeCd')
            searchParams.delete('insuranceTypeCd')
        end
        
        # company specific ends here
        @searchResultList = {}
        if @params['illustrationCheck'].to_s != ""
            @params['illustrationCheck'].each do |selectedQuotationId|
                quotation = Quotation.loadObject( :first, :conditions => { :object => selectedQuotationId } )
                MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
                quotation.delete if quotation

                container = SignatureContainer.loadObject(:all,:condition=>{{:name=>'entityGuid'}=>quotation.guid})
                if container
                    container.each do|signature_container|
                        signature_container.delete if signature_container
                    end
                end
            end
        end

        #commenting if condition to show all search results on page load.
        # if !searchParams.empty?
            @mainSearchField = @params['mainSearchField'].to_s
            quotationRefNum = @params['quotationRefNum'].to_s
            productId = @params['productId'].to_s
            fullName = @params['fullName'].to_s
            quoteStatusCd = @params['quoteStatusCd'].to_s
            quotationDt = getDBDate(@params['quotationDt']) if @params['quotationDt'].to_s != ""
            if @insuranceType == nil
                quotationList = Quotation.loadObject(
                    :all,
                    :per_page => 200,
                    :order => ['quotationRefNum', 'quotationDt'],
                    :orderdir => 'DESC',
                    :select => ['quotationRefNum', 'productId', 'quotationDt', 'quoteStatusCd', 'object']
                )
            else
                quotationList = Quotation.loadObject(
                    :all,
                    :conditions => {:insuranceTypeCd => @insuranceType},
                    :per_page => 200,
                    :order => ['quotationRefNum', 'quotationDt'],
                    :orderdir => 'DESC',
                    :select => ['quotationRefNum', 'productId', 'quotationDt', 'quoteStatusCd', 'object']
                )
            end
            quotationList.each do |quotation|
                insured = quotation.getMainInsured(quotation.getBaseProduct)
                firstname = ""
                lastname = ""
                if insured
                    firstname = insured.firstname
                    lastname = insured.lastname
                end
                product = MobiSys::ProductUtil.getProduct(quotation.getBaseProduct.productSeq) if quotation.getBaseProduct
                shortName = ""
                longName = ""
                if product
                    shortName = product.shortName
                    longName =  product.longName
                end
                validQuotation = true
                
                if @mainSearchField != ""
                    unless quotation.quotationRefNum.to_s.include?(@mainSearchField) || longName.include?(@mainSearchField) || quotation.getInsuredName.to_s.downcase.include?(@mainSearchField.downcase) || quotation.quoteStatusCd.to_s.include?(@mainSearchField.upcase) || getScreenDate(quotation.quotationDt).to_s.include?(@mainSearchField)
                        validQuotation = false
                    end
                else
                    if quotationRefNum != ""
                        validQuotation = false unless quotation.quotationRefNum.to_s.include?(quotationRefNum)
                    end
                    
                    if productId != "" && validQuotation
                        validQuotation = false unless quotation.productId.to_s.include?(productId)
                    end

                    if fullName != "" && validQuotation
                        validQuotation = false unless quotation.getInsuredName.to_s.include?(fullName)
                    end

                    if quoteStatusCd != "" && validQuotation
                        validQuotation = false unless quotation.quoteStatusCd.to_s.include?(quoteStatusCd.upcase)
                    end

                    if quotationDt != "" && validQuotation
                        validQuotation = false unless quotation.quotationDt.to_s.include?(quotationDt.to_s)
                    end
                end

                if validQuotation
                    @searchResultList[quotation.object] = [quotation.quotationRefNum.to_s,shortName.to_s,quotation.getInsuredName.to_s,getScreenDate(quotation.quotationDt),getLabelValue(quotation.quoteStatusCd.to_s)]
                end
            end
        # end

        render :action => :QuoteSearchmulti_Jazz, :layout => :jazzLayout
    end


    def getIllustrationOptions
        WebView.execute_js("showLoadingMessage()")
        @view_email = @params['view_email']
        @quotationObjects = @params['illustrationCheck']
        @outputPref = OutputPreferences.new
        @outputPref = defaultOutputPreferences(@outputPref)
        if @view_email == "email" 
            @emailRequest = EmailRequest.new
            @emailRequest.entityGuid = @quotation.guid
            @emailRequest.entityNumber = @quotation.quotationRefNum
            proposer = @quotation.getPartyByRole('PROPOSER')
            @emailRequest.toEmail = proposer.emailAddress if proposer && proposer.emailAddress.to_s != ""
            @emailRequest.entityName = 'Quotation'
            @emailRequest.outputPrefEntityGuid = @outputPref.uniqueKey

            filteredProduct = Product.loadObject(
                :first,
                :conditions => {
                    {
                        :name => 'productId',
                    } => @quotation.productId,
                    {
                        :name => 'productVersion'
                    } => @quotation.productVersion
                },
                :op => 'AND'
            )
            quotationProduct = QuotationProduct.new

            quotationProduct.productId = filteredProduct.productId if filteredProduct != nil

            @illustrationReports = Array.new

            @shortIllustration = false
            @longIllustration = false
            @reportSections = []

            @illustrationReports.each do |illustrationReportDT|
                if illustrationReportDT.ruleName != nil
                    @longIllustration = true if illustrationReportDT.ruleName == "LONG"
                    @shortIllustration = true if illustrationReportDT.ruleName == "SHORT"
                    @reportSections.push(illustrationReportDT.ruleName)
                end
            end
        end

        @render_c_o_p = false
        @render_c_o_p = true if $rhoconfig[:capture_output_preferences] == 'YES'

        @formname = "viewForm"
        @formaction = "#{url_for :action => :generateIllustrations}"
        @header_field = getLabelValue("outputPrefDetail")
                                    

        @submit_anchor_tag = "<a href='#' name='view' onclick='sendview();'>#{getLabelValue('SUBMIT')}</a>"
        render :action => :captureIllustrationPreferences_Jazz, :layout => :jazzLayout   
    end

    def generateIllustrations
        @illustrationData = {}
        @displayIllustrationHeader = []
        if @params['illustrationsToBeGenerated'].to_s != ""
             @params['illustrationsToBeGenerated'].each do |selectedQuotationId|
                outputpreference = nil
                if @params['OutputPreferences']
                    outputPref = MobiSys::BrowserHelper.convertToObject('OutputPreferences', @params['OutputPreferences'])
                    outputPref.persist
                    outputpreference = outputPref.object
                end
                @quotation = Quotation.loadObject(  :first,
                    :conditions => {
                      :object => selectedQuotationId
                    }
                )
                
                @quotationIO = MobiSys::IO::QuotationIO.new
                @quotationIO.baseDO = @quotation

                if @params['outputPref'] != nil
                    @outputpreference = OutputPreferences.loadObject(:first,
                        :conditions => {
                            :object => @params['outputPref']
                        }
                    )
                    @quotationIO.outputPreferencesDO = @outputpreference
                 
                end

                quotePlan = MobiSys::QuotationBO.getBaseProduct(@quotation)
              
                
                if quotePlan.product == nil
                    product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
                else
                    product = quotePlan.product
                end  
                @quotationIO.baseProduct = product
                preGenerateIllustration(@quotationIO)
                @quotationIO.illustrationModel = nil
                MobiSys::ProductBO.loadModel("SIMODEL",@quotationIO)
                $quotationIO = MobiSys::ProductBO.callCalculateIllustration(@quotationIO)
                postGenerateIllustration($quotationIO)
                MobiSys::UIGenUtil.finalMapNew($quotationIO)
                
                entityHash = Hash.new
                entityHash[Quotation.onlineClassName] = [@quotation.hashForSync].to_json
                entityHash['finalMap'] = [$quotationIO.finalMap].to_json
                entityHash[IllustrationModel.onlineClassName] = [$quotationIO.illustrationModel.hashForSync].to_json
                @illustrationData[$quotationIO.baseDO.quotationRefNum] = ::JSON.generate(entityHash)
    
            end
        end
           
        
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network 
            begin
                results = doJSONPost('/callGenerateIllustrationExcel.run', ::JSON.generate(@illustrationData))
                Alert.show_popup({
                    :message => getLabelValue('Illustration generated successfully'), 
                    :title => '', 
                    :icon => :info,
                    :buttons => ["OK"] 
                })
            rescue Exception => e
            end
        else
            results="ERR_NETWORK"
            Alert.show_popup({
                :message => getLabelValue('Illustration generation failed'), 
                :title => '', 
                :icon => :info,
                :buttons => ["OK"] 
            })
        end 
        WebView.navigate(url_for(:controller=> :Quotation, :action => :searchmulti))
    end

    def searchEmailRequest
        #logUserActivity
        WebView.execute_js("loading('show');")
        @searchResultList = {}
        @searchValue = "%"+@params['mainSearchField']+"%" if @params['mainSearchField']

        if @searchValue != nil #&& @searchValue != ""
            _sql = ""
            _sql << "select q.quotationRefNum, er.toEmail, er.systemUpdatedDt, er.emailReqStatusCd, er.entityGuid, qp.firstname, qp.lastname from Quotation q, EmailRequest er, QuotationParty qp where "
            _sql << "q.guid = er.entityGuid and q.object = qp.parentkey and (q.quotationRefNum LIKE '%"
            _sql << @searchValue
            _sql << "%' OR er.toEmail LIKE '%"
            _sql << @searchValue
            _sql << "%' OR er.emailReqStatusCd LIKE '%"
            _sql << @searchValue
            _sql << "%' OR er.systemUpdatedDt LIKE '%"
            _sql << @searchValue
            _sql << "%' OR qp.firstname LIKE '%"
            _sql << @searchValue
            _sql << "%' OR qp.lastname LIKE '%"
            _sql << @searchValue
            _sql << "%') and qp.roleCd = 'PROPOSER' and q.quoteStatusCd IS NOT 'PENDING' and q.userId = '#{AgentReg.forUserId($userId, true).userId}'"

            @quotations = Quotation.find_by_sql(_sql)
            @quotations.each_with_index do |x,index|
                @searchResultList[index] = [x.quotationRefNum,(x.firstname+" "+x.lastname).strip,x.toEmail,getScreenDate(x.systemUpdatedDt),getLabelValue(x.emailReqStatusCd)]
            end
        end
        render :action => :indexEmailRequest_Jazz, :back => '/app/Menu/salesIllustration', :layout => :jazzLayout
    end
    ########################################################################################################


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
        html << render(:partial => 'QuoteFilterProduct_Jazz', :locals => {:productFamilyDesc => productFamilyDesc})
        return html
    end
    ########################################################################################################


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
        html << render(:partial => 'QuoteFilterProduct_Jazz', :locals => { :productIdDesc => productIdDesc })
        return html
    end
    ########################################################################################################


    def filterPlanOptionCodes
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
                    @offlinePlanOptionArray.push(offlinePlanOption)
                end
            end
        end
        @offlinePlanOptionArray.sort_by!{|filterPlanName| filterPlanName.description}

        @option = "productPlanOptions"
        html = ""
        html << render(:partial => 'QuoteFilterProduct_Jazz', :locals => {:productIdDesc => productIdDesc})
        return html
    end
    ########################################################################################################


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
        html << render(:partial => 'QuoteFilterProduct_Jazz', :locals => {:productIdDesc => productIdDesc})
        return html
    end
    ########################################################################################################


    def productPage
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
        render :action => :QuoteProductPage_Jazz, :layout => :jazzLayout
    end
    ########################################################################################################


    def copyQuotation(srcQuotation, targetQuotation, isShow)
        if isShow ## show
            targetQuotation = srcQuotation.cloneObject
            targetQuotation.quotationRefNum = ""
            targetQuotation.quoteStatusCd = "PENDING"
            targetQuotation.signature = ""
            targetQuotation.agentSignature = ""
            targetQuotation.productId = srcQuotation.productId
            targetQuotation.guid = nil
            targetQuotation.quotationDt = Time.now.strftime("%d/%m/%Y")
            targetQuotation.systemCreatedDt = ""
            targetQuotation.id = ''
            targetQuotation.fnaId = ''
   
            #Deepali Singh - 04/04/2016 Resetting all old guids to new guids      
            partyOldNewGuidMapping = Hash.new
            if targetQuotation.QuotationPartyList && targetQuotation.QuotationPartyList.size > 0
                targetQuotation.QuotationPartyList.each do |qp|
                    partyOldNewGuidMapping[qp.guid] = qp.object.gsub(".","_")
                end

                targetQuotation.QuotationPartyList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = ''
                    qp.id = ''
                end
            end

            @partyGuidMapping = "#{partyOldNewGuidMapping.keys.join(',')}|#{partyOldNewGuidMapping.values.join(',')}"
            if targetQuotation.QuotationProductList && targetQuotation.QuotationProductList.size > 0
                targetQuotation.QuotationProductList.each do |qp|
                    if qp.insuredPartyRefGuid.to_s != ""
                        qp.insuredPartyRefGuid = partyOldNewGuidMapping[qp.insuredPartyRefGuid] 
                    end
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = ''
                    qp.id = ''
                    if qp.QuotationProductInvestmentFundList && qp.QuotationProductInvestmentFundList.size > 0
                        qp.QuotationProductInvestmentFundList.each do |qpif|
                            qpif.guid = qpif.object.gsub(".","_")
                            qpif.systemCreatedDt = ''
                            qpif.id = ''
                        end 
                    end
                    if qp.QuotationProductExtraList && qp.QuotationProductExtraList.size > 0
                        qp.QuotationProductExtraList.each do |qpe|
                            qpe.guid = qpe.object.gsub(".","_")
                            qpe.systemCreatedDt = ''
                            qpe.id = ''
                        end 
                    end
                    if qp.QuotationProductAdditionalList && qp.QuotationProductAdditionalList.size > 0
                        qp.QuotationProductAdditionalList.each do |qpe|
                            qpe.guid = qpe.object.gsub(".","_")
                            qpe.systemCreatedDt = ''
                            qpe.id = ''
                        end 
                    end
                end
            end

            if targetQuotation.QuotationTopUpList && targetQuotation.QuotationTopUpList.size > 0
                targetQuotation.QuotationTopUpList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = ''
                    qp.id = ''
                end
            end
            if targetQuotation.QuotationWithdrawalList && targetQuotation.QuotationWithdrawalList.size > 0
                targetQuotation.QuotationWithdrawalList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = ''
                    qp.id = ''
                end
            end
            if targetQuotation.QuotationAdditionalFieldsList && targetQuotation.QuotationAdditionalFieldsList.size > 0
                targetQuotation.QuotationAdditionalFieldsList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = ''
                    qp.id = ''
                end
            end
            return targetQuotation 
        else ## execute 
            targetColnnedQuotation = srcQuotation.cloneObject  
            quotationProductLst = targetColnnedQuotation.QuotationProductList
            quotationTopUpLst = targetColnnedQuotation.QuotationTopUpList
            quotationPartyLst = targetColnnedQuotation.QuotationPartyList
            quotationWithdrawalLst = targetColnnedQuotation.QuotationWithdrawalList
            imageLst = targetColnnedQuotation.ImageList
            quotationAdditionalFieldsLst = targetColnnedQuotation.QuotationAdditionalFieldsList  
            # copying data again in quotation as these fields are not present in current form
            targetQuotation.productVersion  = srcQuotation.productVersion
            targetQuotation.productTypeCd = srcQuotation.productTypeCd
            targetQuotation.productFamilyCd = srcQuotation.productFamilyCd
            targetQuotation.topupOptionCd = srcQuotation.topupOptionCd
            targetQuotation.regularTopupFl = srcQuotation.regularTopupFl
            targetQuotation.initialTopupFl = srcQuotation.initialTopupFl
            targetQuotation.withdrawalFl = srcQuotation.withdrawalFl
            targetQuotation.solverTypeCd = srcQuotation.solverTypeCd
            targetQuotation.withdrawalRateTypeCd = srcQuotation.withdrawalRateTypeCd

            targetQuotation.childUserId = srcQuotation.childUserId
            targetQuotation.coverTypeCd = srcQuotation.coverTypeCd
            targetQuotation.isEditableQuoRefNumFl = srcQuotation.isEditableQuoRefNumFl
            targetQuotation.uploadFlag = srcQuotation.uploadFlag
            targetQuotation.termTypeCd = srcQuotation.termTypeCd
            targetQuotation.pptermTypeCd = srcQuotation.pptermTypeCd
            targetQuotation.multiplierTypeCd = srcQuotation.multiplierTypeCd
            targetQuotation.termCalculationBasisCd = srcQuotation.termCalculationBasisCd
            targetQuotation.isAgeEditableFl = srcQuotation.isAgeEditableFl

            targetQuotation.quotAddtnlField5 = srcQuotation.quotAddtnlField5
            targetQuotation.quotAddtnlField6 = srcQuotation.quotAddtnlField6
            targetQuotation.quotAddtnlField7 = srcQuotation.quotAddtnlField7
            targetQuotation.quotAddtnlField8 = srcQuotation.quotAddtnlField8
            targetQuotation.quotAddtnlField9 = srcQuotation.quotAddtnlField9
            targetQuotation.quotAddtnlField10 = srcQuotation.quotAddtnlField10
            targetQuotation.payingYears = srcQuotation.payingYears
            targetQuotation.unselectedRiders = srcQuotation.unselectedRiders
            targetQuotation.leadId = srcQuotation.leadId
            targetQuotation.fnaId = srcQuotation.fnaId
            targetQuotation.rpqId = srcQuotation.rpqId  

            partyOldNewGuidMapping = Hash.new
            partyGuidMapping = @params['partyGuidMapping'].split('|')
            oldGuids = partyGuidMapping[0].split(',')
            newGuids = partyGuidMapping[1].split(',')
            oldGuids.each_with_index do |oldGuid,index|
                partyOldNewGuidMapping[oldGuid] = newGuids[index]
                targetQuotation.unselectedRiders.to_s.gsub!(oldGuid,newGuids[index])
            end
            targetQuotation.persistAll 
            copiedQuotation = Quotation.loadObject(:first,:conditions=>{:object=>targetQuotation.object})
            copiedQuotation.QuotationProductList.each do |quotationProduct|  
                quotationProduct.removed = "YES"
            end
            quotationProductLst.each do |quotationProduct| 
                if quotationProduct.insuredPartyRefGuid.to_s != ""
                    quotationProduct.insuredPartyRefGuid = partyOldNewGuidMapping[quotationProduct.insuredPartyRefGuid] 
                end
                quotationProduct.guid = quotationProduct.object.gsub(".","_")
                quotationProduct.systemCreatedDt = Time.now
                quotationProduct.id = nil
                if quotationProduct.QuotationProductInvestmentFundList && quotationProduct.QuotationProductInvestmentFundList.size > 0
                    quotationProduct.QuotationProductInvestmentFundList.each do |qpif|
                        qpif.guid = qpif.object.gsub(".","_")
                        qpif.systemCreatedDt = Time.now
                        qpif.id = nil
                    end 
                end
                if quotationProduct.QuotationProductExtraList && quotationProduct.QuotationProductExtraList.size > 0
                    quotationProduct.QuotationProductExtraList.each do |qpe|
                        qpe.guid = qpe.object.gsub(".","_")
                        qpe.systemCreatedDt = Time.now
                        qpe.id = nil
                    end 
                end
                if quotationProduct.QuotationProductAdditionalList && quotationProduct.QuotationProductAdditionalList.size > 0
                    quotationProduct.QuotationProductAdditionalList.each do |qpe|
                        qpe.guid = qpe.object.gsub(".","_")
                        qpe.systemCreatedDt = ''
                        qpe.id = ''
                    end 
                end
                copiedQuotation.addQuotationProduct(quotationProduct)
            end

            quotationPartyLst.each do |quotationParty|
                if quotationParty.roleCd != 'PRIMARY' && quotationParty.roleCd != 'PROPOSER' && quotationParty.roleCd != 'JOINT'
                    copiedQuotation.addQuotationParty(quotationParty)
                end
            end
            copiedQuotation.QuotationPartyList.each do |qp|
                # resetting the object of quotationparty to the one created at the instant of first clone or show
                qp.object = partyOldNewGuidMapping[qp.guid].gsub("_",".") if partyOldNewGuidMapping[qp.guid].to_s != ''
                qp.guid = qp.object.gsub(".","_")
                qp.systemCreatedDt = Time.now
                qp.id = nil
            end

            quotationTopUpLst.each do |quotationTopUp|
                quotationTopUp.guid = quotationTopUp.object.gsub(".","_")
                quotationTopUp.systemCreatedDt = Time.now
                quotationTopUp.id = nil
                copiedQuotation.addQuotationTopUp(quotationTopUp)
            end  

            quotationWithdrawalLst.each do |quotationWithdrawal|
                quotationWithdrawal.guid = quotationWithdrawal.object.gsub(".","_")
                quotationWithdrawal.systemCreatedDt = Time.now
                quotationWithdrawal.id = nil
                copiedQuotation.addQuotationWithdrawal(quotationWithdrawal)
            end

            imageLst.each do |image|
                copiedQuotation.addImage(image)
            end

            quotationAdditionalFieldsLst.each do |quotationAdditionalFields|
                quotationAdditionalFields.guid = quotationAdditionalFields.object.gsub(".","_")
                quotationAdditionalFields.systemCreatedDt = Time.now
                quotationAdditionalFields.id = nil
                copiedQuotation.addQuotationAdditionalFields(quotationAdditionalFields)
            end 
            return copiedQuotation 
        end 
    end
    ########################################################################################################


    def newCaptureIllustration
        $globalFacetHash = nil
        $productMaster = nil # clearing product master hash created at product selection page
        $rhoconfig[:moduleForProductValidations] = "Quotation"
        
        MobiSys::ProductUtil.resetCache
        addUserActivityHelper('NEWILLUSTRATION', @params, 'QUOTATION')

        $currentProduct = MobiSys::ProductUtil.getProduct(@params['productSeq']) if @params['productSeq'] != ""
        
        if !@params['quotationRefNum'].nil? and @params['quotationRefNum'] != ""
            @quotation = Quotation.loadObject( :first,
                :conditions => {
                    :quotationRefNum => @params['quotationRefNum']
                }
            )
            @quotation.delete
        end

        @quotation = Quotation.new
        @quotation.insuranceTypeCd = @params['insuranceTypeCd'] if @params['insuranceTypeCd'].to_s != ''
        @tabName, @tabLabel,@tabIcons = requiredTabs
        if @quotation.insuranceTypeCd.to_s == 'AUTO'
            captureAuto
        elsif @quotation.insuranceTypeCd.to_s == 'TRAVEL'
            captureTravel
        elsif @quotation.insuranceTypeCd.to_s == 'HEALTH'
            captureHealth
        else
            captureLife
        end

        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
        @visitedTabs = @quotation.visitedTabs.to_s
        @renderMultiLanguagePanel = true
        @renderMultiLanguagePanel = MobiSys::BrowserHelper.renderPanel?('MULTILINGUALPARTYNAME', $currentProduct) if $currentProduct.to_s != ""
        renderEditableQuotDt =  MobiSys::BrowserHelper.renderPanel?('BACKDATINGALLOWED', $currentProduct) if $currentProduct.to_s 
        @quotation.isQuotationDtEditableFl = "YES" if renderEditableQuotDt
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@quotation)

        render :action => :QuoteCapture_Jazz, :layout => :jazzLayout
    end
    #################################################################################################


    def setLeadRPQFNADetails
        lead = Lead.loadObject(:first,:conditions=>{{:name=>'object'}=> @params['leadid']})
        leadRPQ = LeadRPQ.loadObject(:first,:conditions=>{{:name=>'rpqId'}=> @params['rpqId']})
        selectedProduct = @params['selectedProductId']

        if @params['fnaId']
            if @params['fnaId'].include? ('{')
                str = @params['fnaId'][1..-1].chop
                strArrayOfIdAndProduct = []
                fnaPlan = ""
                fnaIOSelectedGuid = ""
            else
                str = @params['fnaId']
            end
            
            if str
                if str.include?("|")
                    strArrayOfIdAndProduct = str.split("|")
                    id = strArrayOfIdAndProduct[0]
                    strArrayOfIdAndProduct.shift
                    fnaIOSelectedGuid = strArrayOfIdAndProduct[0]
                    strArrayOfIdAndProduct.shift
                    fnaPlan = strArrayOfIdAndProduct[0].to_s
                    @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
                else
                    id = str
                    @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
                end
            else  
                @fnaRequest = nil
            end
        end

        if lead
            @policyHolder.title = lead.title
            @policyHolder.firstname = lead.firstname
            @policyHolder.middlename = lead.middlename
            @policyHolder.lastname = lead.lastname
            @policyHolder.dob = getScreenDate(lead.dob) if lead.dob.to_s != ""
            @policyHolder.age = lead.age
            @policyHolder.genderCd = lead.genderCd
            @policyHolder.contactNum = lead.mobileNumber
            @policyHolder.industryCd = lead.industryCd
            @policyHolder.natureOfDuty = lead.natureofDutyId
            @policyHolder.occupationCd = lead.occupationCd
            @policyHolder.emailAddress = lead.emailAddress
            @quotation.leadId = lead.leadId
        elsif leadRPQ
            @policyHolder.title = leadRPQ.title
            @policyHolder.firstname = leadRPQ.firstname
            @policyHolder.middlename = leadRPQ.middlename
            @policyHolder.lastname = leadRPQ.lastname
            @policyHolder.dob = getScreenDate(leadRPQ.dob) if leadRPQ.dob.to_s != ""
            @policyHolder.age = leadRPQ.age
            @policyHolder.genderCd = leadRPQ.genderCd
            @policyHolder.contactNum = leadRPQ.mobileNumber
            @policyHolder.emailAddress = leadRPQ.emailAddress   
            @quotation.fnaId = leadRPQ.fnaId
            @quotation.rpqId = leadRPQ.rpqId
            @quotation.leadId = leadRPQ.leadId
            @policyHolder.smoker = "NO"

            if selectedProduct != ""
                $currentProduct = Product.loadObject(:first,:conditions => {:productId => selectedProduct})
                baseProduct = QuotationProduct.new
                @params = Hash.new
                @params['productFamily'] = $currentProduct.productFamilyId
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, @quotation)
                @quotation.addQuotationProduct(baseProduct)
            end
        elsif @fnaRequest
            @fnaProposer = @fnaRequest.getParty("PROPOSER") 
            @policyHolder.firstname = @fnaProposer.firstName1
            @policyHolder.lastname = @fnaProposer.lastName1
            @policyHolder.dob = getScreenDate(@fnaProposer.birthDt) if @fnaProposer.birthDt.to_s != ""
            @policyHolder.age = @fnaProposer.age
            @policyHolder.contactNum = @fnaProposer.mobileNum
            @policyHolder.emailAddress = @fnaProposer.emailAddress
            @quotation.fnaId = @fnaRequest.fnaNum.to_s + "|" + fnaIOSelectedGuid.to_s
            @quotation.leadId = @fnaRequest.leadId
            @policyHolder.smoker = "NO"

            # Copying Products From FNA to SI
            if strArrayOfIdAndProduct.to_s != ""
                fnaSIProductLinkList = []
                productArray = []

                fnaSIProductLinkList = FNASIProductLink.find( :all,  :conditions =>{ { :name => "fnaProductId", :op => "IN" } => strArrayOfIdAndProduct } )
                
                if fnaSIProductLinkList.to_s != "" && fnaSIProductLinkList.size > 0
                    fnaSIProductLinkList.each do |fnaSIProductLink|
                        # Here productArray[0] = base plan & other will be riders 
                        productArray.push(Product.loadObject(:first, :conditions => { :productId => fnaSIProductLink.siProductId }))
                    end
                end

                if fnaSIProductLinkList[0].to_s != ""
                    $currentProduct = productArray[0]
                    @quotation.insuranceTypeCd = 'LIFE'
                    fnaSIPlan = fnaSIProductLinkList[0]

                    if productArray[0].to_s != ""
                        baseProduct = QuotationProduct.new
                        # used params below to follow setBaseProductDetails method
                        @params = Hash.new
                        @params['productFamily'] = $currentProduct.productFamilyId
                        @params['productPlanOptionCd'] = fnaSIPlan.optionCd
                        baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, @quotation)
                        @quotation.addQuotationProduct(baseProduct)
                        
                        fnaSIProductLinkList.shift # deleting base plan entry from fnaSIProductLinkList
                        productArray.shift # deleting base plan entry from productArray
                    end
                end

                if fnaSIProductLinkList.size > 0 && fnaSIProductLinkList.to_s != nil
                    @riders = []
                    fnaSIProductLinkList.zip(productArray).each do |fnaSIProductLink,product|
                        siRiderId = fnaSIProductLink.siProductId
                        siRiderOptionCd =  fnaSIProductLink.optionCd

                        rider = QuotationProduct.new(:productTypeCd => 'RIDER', :partyRoleCd => "PRIMARY", :builtInRiderFl => 'NO')
                        rider.productId = siRiderId
                        rider.productPlanOptionCd = siRiderOptionCd
                        rider.productSeq = product.id
                        rider.productFamilyCd = product.productFamilyId
                        rider.productVersion = product.productVersion
                        rider.selected = "YES"

                        @quotation.addQuotationProduct(rider)
                        @riders << rider
                    end
                end 
            end
        end
    end
    ########################################################################################################

    def setBaseProductDetails(baseProduct, product, params, quotation)
        if params.has_key?('selectProductFamily')
            baseProduct.productFamilyCd = params['selectProductFamily']
        elsif params.has_key?('productFamily')
            baseProduct.productFamilyCd = params['productFamily']
        end

        if params.has_key?('selectProductPlan')
            baseProduct.productPlanOptionCd = params['selectProductPlan']
        elsif params.has_key?('productFamily')
            baseProduct.productPlanOptionCd = params['productPlanOptionCd']
        end

        if product
            baseProduct.productId = product.productId
            baseProduct.productSeq = product.id
            baseProduct.productVersion = product.productVersion
        end

        baseProduct.annuityPerc = 100;
        baseProduct.pdfFrequencyVal = 1;

        baseProduct.productTypeCd = "PLAN"
        baseProduct.planCode = params['planCode'][0..-4].chop if params['planCode'] != nil  
        baseProduct.partyRoleCd = "PRIMARY"
        baseProduct.topUpAllocSameAsPremAllocFl = nil
        baseProduct.modalPremium = 0.0
        baseProduct.baseAnnualPremium = 0.0
        baseProduct.baseSumAssured = 0.0
        baseProduct.coi = 0.0
        baseProduct.capturedPremiumAmt = 0.0
        baseProduct.minTargetPremium = 0.0
        baseProduct.maxTargetPremium = 0.0
        baseProduct.recommendedPremium = 0.0
        baseProduct.unapliedPremium = 0.0
        baseProduct.annualizedPremium = 0.0
        baseProduct.totAnnualizedPremium = 0.0
        if (quotation && quotation.insuranceTypeCd == 'TRAVEL') || params['insuranceTypeCd'] == 'TRAVEL'
            if quotation.startDt.to_s != '' && quotation.endDt.to_s != ''
                startDt = Date.strptime(getScreenDate(quotation.startDt), "%d/%m/%Y")
                endDt = Date.strptime(getScreenDate(quotation.endDt), "%d/%m/%Y")
                baseProduct.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
            end
            baseProduct.premiumPayingTerm = 1
            baseProduct.paymentTypeCd = "SINGLE"
            baseProduct.paymentFrequencyCd = "SINGLE"
            baseProduct.productFamilyCd = product.productFamilyId if product
        elsif (quotation && quotation.insuranceTypeCd == 'AUTO') || params['insuranceTypeCd'] == 'AUTO'
            baseProduct.productFamilyCd = product.productFamilyId if product
        else
            baseProduct.paymentTypeCd = ""
            baseProduct.paymentFrequencyCd = ""
            baseProduct.productTerm = ''
            baseProduct.premiumPayingTerm = ''
        end

        return baseProduct
    end
    ########################################################################################################


    def show
        WebView.execute_js("loading('show');")
        $displayRidersHM = nil
        $globalFacetHash = nil
        $rhoconfig[:moduleForProductValidations] = "Quotation"
        MobiSys::ProductUtil.resetCache
        
        if @params['id'].to_s != "" 
            id = @params['id'][1..-1].chop
            @quotation = Quotation.loadObject(:first, :conditions => {:object => id})
        elsif @params['quotationId'].to_s != ""
            if @params['quotationId'].include? ('{')
              quotationId = @params['quotationId'][1..-1].chop
            else
              quotationId = @params['quotationId']
            end
            @quotation = Quotation.loadObject(:first, :conditions => {:quotationRefNum => quotationId})
        end
    
        # handle copy requests
        type = @params['type']
        if type != nil && type== "copy"  
            @sourceQuotationId = @quotation.object
            @mode = "copy" 
            targetQuotation = Quotation.new
            @quotation = copyQuotation(@quotation,targetQuotation,true)

            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                @quotation.QuotationPartyList.each do |quotationParty|
                    if quotationParty.dob.to_s != ""
                        quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                        quotationParty.age = MobiSys::ProductBO.calculateAge(@quotation, @quotation.getBaseProduct, quotationParty, nil).split("|")[0].to_i
                        quotationParty.dob = getDBDate(quotationParty.dob.to_s).to_s
                    end
                end
            end
        end

        @baseProduct = @quotation.getBaseProduct
        if @baseProduct == nil 
            @baseProduct = QuotationProduct.new
            @baseProduct = setBaseProductDetails(@baseProduct, $currentProduct, @params, @quotation)
            @quotation.addQuotationProduct(@baseProduct)
        end

        $currentProduct = MobiSys::ProductUtil.getProduct(@baseProduct.productSeq.to_s) 
     
        @tabName, @tabLabel, @tabIcons = requiredTabs

        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
        if @baseProduct == nil || @baseProduct.productSeq.to_s == ""
            if  @incompleteTabs.include?("tab_selProduct")
                @incompleteTabs = ["tab_selProduct"]
            else
                @incompleteTabs = []
            end
        end
        
        @visitedTabs = @quotation.visitedTabs.to_s

        if @quotation.insuranceTypeCd.to_s == 'AUTO'
            renderErb = showAuto
        elsif @quotation.insuranceTypeCd.to_s == 'TRAVEL'
            renderErb = showTravel
        elsif @quotation.insuranceTypeCd.to_s == 'HEALTH'
            renderErb = showHealth
        else
            renderErb = showLife
        end
        @renderMultiLanguagePanel = true
        @renderMultiLanguagePanel = MobiSys::BrowserHelper.renderPanel?('MULTILINGUALPARTYNAME', $currentProduct) if $currentProduct.to_s != ""
        renderEditableQuotDt =  MobiSys::BrowserHelper.renderPanel?('BACKDATINGALLOWED', $currentProduct) if $currentProduct.to_s 
        @quotation.isQuotationDtEditableFl = "YES" if renderEditableQuotDt
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@quotation)
        if renderErb
            render :action => :QuoteCapture_Jazz, :layout => :jazzLayout
        end
    end
    #################################################################################################


    def linkToFNAPopup
        quotationId = @params["quotationId"]
        fnaNum = @params["fnaId"].split("|").first
        fnaRefGuid = @params["fnaId"].split("|").last
        @quotation = Quotation.loadObject(:first, :conditions=>{'quotationRefNum'=> quotationId.to_s}, :loadChild => false)
        @quotation.fnaId = @params["fnaId"].to_s
        @quotation.persistAll
        @fnaIOSelected = FNAIOSelected.loadObject(:first, :conditions=>{'guid'=> fnaRefGuid.to_s}, :loadChild => false)
        @fnaIOSelected.quotationId = quotationId.to_s
        @fnaIOSelected.persistAll
    end
    ###################################################################################################


    def changePlan(quotation, params)
        quotation.QuotationTopUpList.each do |quotationTopUp|
            quotationTopUp.removed = "YES"
        end
        quotation.regularTopupFl = ""
        quotation.initialTopupFl = ""
        quotation.withdrawalFl = ""
        quotation.unselectedRiders = ""

        quotation.QuotationWithdrawalList.each do |quotationWithdrawal|
            quotationWithdrawal.removed = "YES"
        end

        quotation.QuotationProductList.each do |quotationProduct|
            quotationProduct.removed = "YES"
        end

        quotation.QuotationPartyList.each do |quotationParty|
            quotationParty.removed = "YES" if quotationParty.roleCd == 'SUPPLEMENTARY'
        end

        baseProduct = QuotationProduct.new
        baseProduct = setBaseProductDetails(baseProduct, $currentProduct, params, quotation)
        quotation.addQuotationProduct(baseProduct)
        quotation.unselectedRiders = ""
        quotation.persistAll if quotation.quoteStatusCd.to_s != 'ACCEPTED' && quotation.quoteStatusCd.to_s != 'SYNCDONE'
        Alert.show_popup({
            :message => getLabelValue('PRODUCT_INVALIDATED'), 
            :title => getLabelValue("info"),
            :buttons => ["OK"]
        })
    end
    ##############################################################################################


    def execute
        resetObjectMapping
        if @params.has_key?('mode') && @params['mode'] == "FETCH"
            if Quotation.find(:first,:conditions=>{:object=>@params['id']})
                redirect :action => :show, :query => {"sym_current_Tab" => @params['sym_current_Tab']}, :id => @params['id']
            else
                quotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['formData']['Quotation'])
                redirect :action => :newCaptureIllustration, :query => {"productFamily"=>quotation.productFamilyCd,"productId"=>quotation.productId,"productSeq"=>quotation.getBaseProduct.productSeq,"productPlanOptionCd"=>quotation.getBaseProduct.productPlanOptionCd,"leadid"=>quotation.leadId,"rpqid"=>quotation.rpqId,"insuranceTypeCd" => quotation.insuranceTypeCd}
            end
        else
            if @params['Quotation']['insuranceTypeCd'].to_s == 'AUTO'
                executeQuotation = executeAuto
            elsif @params['Quotation']['insuranceTypeCd'].to_s == 'TRAVEL'
                executeQuotation = executeTravel
            elsif @params['Quotation']['insuranceTypeCd'].to_s == 'HEALTH'
                executeQuotation = executeHealth
            else
                executeQuotation = executeLife
            end
            if executeQuotation
                MobiSys::CommonUtil.clearTaskExceptionList(executeQuotation.guid)
                # This method is implemented in company layer
                preSaveValidate(executeQuotation)
                # attach question container to quotation object for dynamic DT evaluation
                attachQuestionContainer(executeQuotation)
                saveValidate(@params, true, executeQuotation)
                # This method is implemented in company layer
                postSaveValidate(executeQuotation)
                redirect :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => @params['sym_current_Tab']}, :id => executeQuotation.object
            end
        end
    end
    ########################################################################################################


    def preSaveValidate(quotation)
        # Do nothing this method is to be implemented in company layer        
    end
    ########################################################################################################


    def postSaveValidate(quotation)
        # Do nothing this method is to be implemented in company layer
        MobiSys::TrackLeadBO.updateTrackLead(quotation)
        if quotation.fnaId
            fnaId = quotation.fnaId.split("|")
            fnaRequest = FNARequest.loadObject(:all, :conditions => { :fnaNum => fnaId[0].to_s })
            
            if fnaRequest && fnaId[1].to_s != ""
                fnaIOSelected = FNAIOSelected.loadObject(:first, :conditions => { :guid => fnaId[1].to_s })
                if fnaIOSelected.to_s != "" 
                    fnaIOSelected.quotationId = quotation.quotationRefNum 
                    fnaIOSelected.persist if fnaIOSelected.quotationId.to_s != ""
                end
            end  
        end
    end
    ########################################################################################################


    def addSupplementLife(quotationParty=nil, quotation=nil, quotationObjectName=nil, supplementLifeCount=nil, supQuotationProductCount=nil)
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE') if $currentProduct

        if quotationParty != nil && quotation != nil && quotationObjectName != nil && supplementLifeCount != nil
            @quotationParty = quotationParty
            @quotation = quotation
        else
            quotationObject = @params['quotationObject']
            @supplementCurrentLifeCount = @params['supplementLifeCount']
            @displayCount = @params['displayCount'].to_i + 1
            @supplementCurrentLifeCount =  @supplementCurrentLifeCount.to_i + 1 
            @quotation = Quotation.loadObject(:first,:conditions => {:object => quotationObject})
            # @quotation = Quotation.new
            # @quotation.object = quotationObject
            # @quotation.insuranceTypeCd = @params['insuranceTypeCd']
            @quotationParty = QuotationParty.new(:roleCd => 'SUPPLEMENTARY',:partyTypeCd => "INDIVIDUAL")
            @quotation.addQuotationParty(@quotationParty)
            
            if $currentProduct && @supplementaryProductFacet
                @supQuotationProductCurrentCount = @params['supQuotationProductCount']
                @supQuotationProductCurrentCount = @supQuotationProductCurrentCount.to_i + 1  
                @baseProduct = QuotationProduct.new
                @baseProduct.productTypeCd = "PLANMULTI"
                @baseProduct.partyRoleCd = "SUPPLEMENTARY"
                @baseProduct.insuredPartyRefGuid = @quotationParty.uniqueKey
                @baseProduct.baseAnnualPremium = 0.0
                @baseProduct.baseSumAssured = 0.0
                @baseProduct.modalPremium = 0.0
                @baseProduct.productSeq = @quotation.getBaseProduct.productSeq
                @quotation.addQuotationProduct(@baseProduct)
                # QuotationProductExtra Section
                @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
                @quotationProductExtras, @baseProduct = MobiSys::QuotationBO.computeProductExtra(@quotation, @baseProduct)
            end
        end

        html = ""
        if @quotation.insuranceTypeCd.to_s == 'AUTO'
            html << render(:partial => 'addSupplementLifeAuto_Jazz')
        else
            html << render(:partial => 'addSupplementLife_Jazz')
        end
        return html
    end
    ########################################################################################################


    def ajaxCalculateBasePremium
        quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
        if quotation.proposerLASame=='YES' || quotation.proposerLASame=='COPYFROMINSURED'
            quotation.proposerLASame = "COPYFROMINSURED"
        else
            quotation.proposerLASame = nil
        end
        # attach question container to quotation object for dynamic DT evaluation
        attachQuestionContainer(quotation)
        saveValidate(@params['form'],false,quotation)

        @msg = ""
        @errors = Hash.new
        @modelPremium = @annualPremium = 0
        
        quot_prod = @quotation.getBaseProduct
        @product = $currentProduct
        @ropLookups = []

        @offlineFacets = @product.OfflineFacetList
        @offlineFacets.each do |offlineFacet|
            offlineFacet.parentKey == @baseProduct.productId
        end
        #to set flag for enabling & disabling div based on the product
        $premiumSAFl = ''
        $multiplierFacet = ''
        $premiumPayingTerm = true

        premiumFacet = @product.getFacet('PREMIUMDETAILS')
        @allowedCurrency = ''
        @allowedPaymentTypeCd = ''
        @allowedPaymentFrequencyCd = ''

        @product.OfflineFacetList.each do |offlineFacet|
            if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
                $premiumPayingTerm = false
            end
            if offlineFacet.facetId == 'MULTIPLIER'
                $multiplierFacet = offlineFacet
            end
            if offlineFacet.facetId == 'MINMAXTERM'
                @minMaxTermFacet = offlineFacet
            end

            offlineFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
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
            end
        end

        if premiumFacet != nil
            if premiumFacet.OfflinePremiumDetailsList[0]
                if premiumFacet.OfflinePremiumDetailsList[0].currencyCd.to_s != ''
                    @allowedCurrency = premiumFacet.OfflinePremiumDetailsList[0].currencyCd
                end
            end
        end
        
        quot_prod.vars.each do |key,value|
            if value.to_s == "NaN"
                stmt = "quot_prod.#{key}=0.0"
                eval(stmt)
            end
        end
        render :string => quot_prod.to_json
    end
    ########################################################################################################


    def getProductTerm
        quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
        quotationProduct = quotation.getBaseProduct()
        minMaxTermTTMS = $currentProduct.getTableTypeMappingSeq('MINMAXTERM')
        @productTerm = quotation.getBaseProduct.productTerm
        @termArray = []
        if minMaxTermTTMS
            minMaxTermFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(minMaxTermTTMS, quotation, quotation.getBaseProduct)
            if minMaxTermFacetProductDef
                results = MobiSys::DataObjects::Results.new
                if (minMaxTermFacetProductDef.minValueExpression and minMaxTermFacetProductDef.minValueExpression != "") || (minMaxTermFacetProductDef.maxValueExpression and minMaxTermFacetProductDef.maxValueExpression != "")
                    results.createAttr("quotation")
                    results.quotation = quotation
                    results.createAttr("quotationProduct")
                    results.quotationProduct = quotationProduct
                    results.createAttr("basePlan")
                    results.basePlan = quotation.getBaseProduct()
                    results.createAttr("mainRider")
                    results.mainRider = quotation.getMainRider(results.quotationProduct)
                end
                minValue = minMaxTermFacetProductDef.minValue if minMaxTermFacetProductDef.minValue.to_s != "" 
                maxValue = minMaxTermFacetProductDef.maxValue if minMaxTermFacetProductDef.maxValue.to_s != ""
                if minMaxTermFacetProductDef.minValueExpression.to_s != ""
                    results.defineMethod("minValue_m",minMaxTermFacetProductDef.minValueExpression)
                    minValue = results.minValue_m
                end
                if minMaxTermFacetProductDef.maxValueExpression.to_s != ""
                    results.defineMethod("maxValue_m",minMaxTermFacetProductDef.maxValueExpression)
                    maxValue = results.maxValue_m
                end
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
                elsif minValue.to_s != "" && maxValue.to_s != ""
                    min = minValue.to_i
                    max = maxValue.to_i
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
    ########################################################################################################


    def getPremiumPayingTerm
        quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
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
                if quotation.getBaseProduct.paymentFrequencyCd == "SINGLE"
                    @ppTermArray.push(Lookupvalue.new(:cd => "1", :desc => "1"))
                    quotation.getBaseProduct.premiumPayingTerm = "1"
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
    ########################################################################################################


    def prePopulateFunds(quotation=nil, baseProduct=nil)
        ajaxCall = false
        if !quotation
            ajaxCall = true
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
            baseProduct = quotation.getBaseProduct
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
                quotationProductInvestmentFund.removed = "YES"
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
        if ajaxCall
            @baseProduct = baseProduct
            html = ""
            html << render(:partial => 'prePopulateFunds_Jazz')
            return html
        end
    end
    ########################################################################################################


    def addTopup
        @topupCount = @params['topupObjects']
        @gridID = @params['gridID']
        @columns = @params['columns'].split(',')

        @quotation = Quotation.new
        @quotation.object = @params['quotationObject']

        @topUp = QuotationTopUp.new(:topUpTypeCd => @params['topUpTypeCd'])
        @quotation.addQuotationTopUp(@topUp)

        html = ""
        html << render(:partial => 'addTopup_Jazz')
        return html
    end
    ########################################################################################################


    def addWithdraw
        quotationObject = @params['quotationObject']
        @withdrawalCurrentCount = @params['withdrawalCount'].to_i + 1  
        @checkboxMode = @params['checkboxMode']
        @columns = @params['columns'].split(',')

        @quotation = Quotation.new
        @quotation.object = quotationObject
  
        @quotationWithdrawal = QuotationWithdrawal.new
        @quotation.addQuotationWithdrawal(@quotationWithdrawal)

        html = ""
        html << render(:partial => 'addWithdraw_Jazz')
        return html
    end
    ########################################################################################################


    def addRider
        quotationObject = @params['quotationObject']
        @riderObjects = @params['riderObjects']
        @quotation = Quotation.loadObject(:first,:conditions => {:object => quotationObject})

        @rider = QuotationProduct.new(
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
        @quotation.addQuotationProduct(@rider)
        @premiumSAFlriders = {@rider.productSeq.to_s => ""}
        @newRiderFields = {@rider.productSeq.to_s => ""}
        @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
        @riderObjects = @riderObjects.to_i + 1  

        html = ""
        html << render(:partial => 'addRiderDetails_Jazz')
        return html
    end
    ########################################################################################################

   
    def refreshRiderSection
        @riderObjects = @params['riderCount']
        riderObject = @params['riderObject']
        @quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
        @product = $currentProduct
        loadRiderProducts(@quotation, @product)
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
    ########################################################################################################


    def evaluateRider
        # first collecting forms quotation product only, it is required because later when we use convertToObjectWithMerge, it merges form state with DB state and series of modifications done on form are lost
        formQuotationProduct = MobiSys::BrowserHelper.convertToObjectList('QuotationProduct', @params['Quotation']['QuotationProduct'])
        formQuotationProductObjectList = formQuotationProduct.collect{|fqp| fqp.object}
        @quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
        riderObject = @params['riderObject']
        partyRefGuid = @params['partyRefGuid']
        clickedAccordians = @params['clickedAccordians'].to_s.split(',')
        @riderObjects = @params['riderInitialCount'].to_i
        current_partyRoleCd = @params['partyRoleCd']
        accordionKey = @params['accordionKey']
        accordionsToBeRefresh = []
        existingQuotProductsToBeRemoved = []
        existingQuotationProducts = {}
        impactedRidersHM = {}
        @riderLoadingHash = {}
        @displayRiderLifeHeader = {}
        current_rider = nil
        basePlan = nil
        current_party = nil
        # creating hash of existing riders with unique key & finding current rider to be evaluated
        @quotation.QuotationProductList.each do |qp|
            if (!(clickedAccordians.include?qp.insuredPartyRefGuid)) && qp.partyRoleCd.to_s != "PRIMARY"
              existingQuotProductsToBeRemoved.push "#{qp.insuredPartyRefGuid}|#{qp.productSeq}"
            end
            if (formQuotationProductObjectList.include? qp.object) || (qp.productTypeCd.to_s == 'RIDER' && (!(clickedAccordians.include?qp.insuredPartyRefGuid)))
                if qp.productTypeCd.to_s == 'RIDER' && qp.builtInRiderFl.to_s != 'YES'
                    existingQuotationProducts["#{qp.insuredPartyRefGuid}|#{qp.productSeq}"] = qp
                    current_rider = qp if qp.object.to_s == riderObject
                    @riderLoadingHash[qp.object] = qp.QuotationProductExtraList
                elsif qp.productTypeCd.to_s == 'PLAN'
                    basePlan = qp
                end
            elsif qp.productTypeCd.to_s != 'PLAN' && qp.productTypeCd.to_s != 'PLANMULTI'
                qp.removed = 'YES'
                qp.selected = 'NO'
            end
        end

        # implicitly deleting existing object mapping because while evaluating riders new riders are added to the list and existing objectmapping becomes invalid
        existingQuotationProducts.each do |key,qp|
            $objectMapping.delete(qp.object)
            qp.QuotationProductExtraList.each do |qpe|
                $objectMapping.delete(qpe.object)
            end
        end
        basePlan.product = $currentProduct
        
        quotePartyList = @quotation.QuotationPartyList
        quotePartyList.each do |party|
            current_party = party if party.guid == current_rider.insuredPartyRefGuid
        end
        
        facetRADO = $currentProduct.getFacet('RIDERASSOCIATION')
        offlineRiderAssociationList = facetRADO.OfflineRiderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
        listOfImpactedAssociations = MobiSys::QuotationBO.getImpactedRiderAssociation(current_rider.productSeq, current_rider.partyRoleCd, offlineRiderAssociationList, [])
        impactedAssociationProdSeqs = []
        parties = @quotation.QuotationPartyList
        riderAssociationListAsPerRoles = {}
        listOfImpactedAssociations.each do|riderAsso|
            if riderAsso.applicableRoles.to_s != ''
                riderAsso.applicableRoles.split(',').each do |role|
                    if riderAssociationListAsPerRoles[role] == nil
                        riderAssociationListAsPerRoles[role] = []
                        riderAssociationListAsPerRoles[role].push riderAsso
                    else
                        riderAssociationListAsPerRoles[role].push riderAsso
                    end
                end
            end
        end
        parties.each do |party|
            evaluationParty = party
            riderAssociationList = riderAssociationListAsPerRoles[party.roleCd]
            if riderAssociationList
                # emptying the global rider map of impacted parties so that after evaluating riders we will merge with form riders and push back in global map
                if (@quotation.proposerLASame == 'COPYFROMINSURED' || @quotation.proposerLASame == 'YES') && (evaluationParty.roleCd == 'PRIMARY' || evaluationParty.roleCd == 'PROPOSER')
                    if evaluationParty.guid == current_party.guid
                        $displayRidersHM.delete('SAMEAS')
                    else
                        $displayRidersHM['SAMEAS'].reject! { |k, _| riderAssociationList.collect{|x|x.productSeq.to_s}.include? k } if $displayRidersHM['SAMEAS']
                    end
                    accordionsToBeRefresh.push 'SAMEAS'
                else
                    if evaluationParty.guid == current_party.guid
                        $displayRidersHM.delete(evaluationParty.guid)
                    else
                        $displayRidersHM[evaluationParty.guid].reject! { |k, _| riderAssociationList.collect{|x|x.productSeq.to_s}.include? k } if $displayRidersHM[evaluationParty.guid]
                    end
                    accordionsToBeRefresh.push evaluationParty.guid
                end
                riderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
                riderAssociationList.each do |offlineRiderAssociation|
                    if offlineRiderAssociation.impactedRiders.to_s == "NA"
                        impactedRidersHM[current_party.guid.to_s+'|'+offlineRiderAssociation.productSeq.to_s] = existingQuotationProducts[current_party.guid.to_s+'|'+offlineRiderAssociation.productSeq.to_s]
                        next
                    end
                    #Do not consider built in riders at all..
                    if offlineRiderAssociation.builtInRiderFl == 'YES'
                        next
                    end
                    # only consider those rider association whose base plan option match.
                    #if basePlan.basePlanOptionCd  && offlineRiderAssociation.basePlanOptionCd  && !basePlan.basePlanOptionCd == offlineRiderAssociation.getBasePlanOptionCd
                    if basePlan.productPlanOptionCd  && offlineRiderAssociation.basePlanOptionCd && basePlan.productPlanOptionCd != offlineRiderAssociation.basePlanOptionCd
                        next
                    end
                
                    impactedAssociationProdSeqs.push "#{evaluationParty.guid}|#{offlineRiderAssociation.productSeq}"
                    if offlineRiderAssociation.associationRelationTTmapSeq != nil
                        #if dependentRiderRoleCd is defined in association and DT then pasing all the qp's in quotation list otherwise qp's of corresponding party
                        if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''
                            ogQuotationProductList = @quotation.QuotationProductList
                            tempQuotationProductList = []
                            tempQuotationProductList.push basePlan
                            tempQuotationProductList.push @quotation.getRidersByParty(evaluationParty.guid)
                            @quotation.setQuotationProductList(tempQuotationProductList.flatten)
                        end
                        defTableDO = MobiSys::ProductBO.getProductDefinitionTable(offlineRiderAssociation.associationRelationTTmapSeq, @quotation, basePlan, evaluationParty)
                        @quotation.setQuotationProductList(ogQuotationProductList) if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''
                        #if dt matched then based on the association relation mark as mandatory, auto selected ..
                        if defTableDO != nil
                            autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, evaluationParty)
                        else
                            listDefinitionTable = MobiSys::ProductUtil.loadProductDefinitionTableListForRidersByTableTypeMappingSeq(offlineRiderAssociation.associationRelationTTmapSeq, false)
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
                                    autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, evaluationParty)
                                else
                                    @quotation.QuotationProductList.each do |qp|
                                        if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && ((offlineRiderAssociation.planOptionCd.to_s != "" && offlineRiderAssociation.planOptionCd.to_s == qp.productPlanOptionCd.to_s) || offlineRiderAssociation.planOptionCd.to_s == "") && qp.partyRoleCd.to_s == evaluationParty.roleCd.to_s && qp.insuredPartyRefGuid.to_s == evaluationParty.guid.to_s
                                            qp.selected = "NO"
                                            qp.removed = "YES"
                                            break
                                        end
                                    end
                                end
                            else
                                @quotation.QuotationProductList.each do |qp|
                                    if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && ((offlineRiderAssociation.planOptionCd.to_s != "" && offlineRiderAssociation.planOptionCd.to_s == qp.productPlanOptionCd.to_s) || offlineRiderAssociation.planOptionCd.to_s == "") && qp.partyRoleCd.to_s == evaluationParty.roleCd.to_s && qp.insuredPartyRefGuid.to_s == evaluationParty.guid.to_s
                                        qp.selected = "NO"
                                        qp.removed = "YES"
                                        break
                                    end
                                end
                            end
                        end
                    else
                        autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, nil, evaluationParty)
                    end
                end
            end
        end
        msg = ""
        errors = Hash.new
        $taskExceptionHash = []
        MobiSys::CommonUtil.clearTaskExceptionList(@quotation.guid)
        unless @quotation.visitedTabs.to_s.include?(@params['sym_current_Tab'])
            @quotation.visitedTabs = @quotation.visitedTabs.to_s + "," + @params['sym_current_Tab']
        end
        impactedRiderProdSeqs = []
        impactedRidersHM.each do |key,rider|
            impactedRiderProdSeqs.push "#{rider.insuredPartyRefGuid}|#{rider.productSeq}"
            product = MobiSys::ProductUtil.getProduct(rider.productSeq)
            extraFacet = product.getFacetValue('PRODUCTEXTRAREQUIRED').to_s == 'YES'
            if rider.selected.to_s == 'YES' 
                rider.removed = ''
                MobiSys::ProductBO.validate(@quotation, msg, errors, rider)
                if extraFacet
                    riderExtras, rider = MobiSys::QuotationBO.computeProductExtra(@quotation, rider)
                else
                    riderExtras = nil
                end
                @riderLoadingHash[rider.object] = riderExtras
            else
                rider.removed = 'YES'
            end
        end
        # deleting riders which are no longer applicable due to change of data
        if !impactedAssociationProdSeqs.empty?
            impactedAssociationProdSeqs.uniq.each do |impactedGuidProdSeq|
                refGuid = impactedGuidProdSeq.split('|')[0]
                productSeq = impactedGuidProdSeq.split('|')[1]
                next if productSeq.to_s == current_rider.productSeq.to_s && refGuid == current_rider.insuredPartyRefGuid # skipping the current rider
                unless impactedRiderProdSeqs.include? impactedGuidProdSeq
                    existingQuotationProducts.delete(impactedGuidProdSeq)
                end
            end
        end
        existingQuotProductsToBeRemoved.each do |toBeRemovedQP|
          existingQuotationProducts.delete(toBeRemovedQP)
        end
        currentTotalPremium = basePlan.modalPremium.to_f
        
        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
        db.start_transaction
        $taskExceptionHash.each do |taskException|
            taskException.persistAll
        end
        db.commit
        $taskExceptionHash = nil
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
        
        ridersHM = MobiSys::BrowserHelper.deep_merge(existingQuotationProducts, impactedRidersHM)
        # updating global rider display hash with new sets of rider
        ridersHM.each do |key, rider|
            if rider.selected.to_s == 'YES'
                currentTotalPremium = currentTotalPremium + rider.modalPremium.to_f
                rider.removed = ''
            else
                rider.removed = 'YES'
            end
            if (@quotation.proposerLASame == 'COPYFROMINSURED' || @quotation.proposerLASame == 'YES') && (rider.partyRoleCd == 'PRIMARY' || rider.partyRoleCd == 'PROPOSER')
                lifeBasedKey = 'SAMEAS'
            else
                lifeBasedKey = key.split('|')[0]
            end
            loadingKey = "#{lifeBasedKey}|#{rider.object}"

            if $displayRidersHM.has_key?(lifeBasedKey) && $displayRidersHM[lifeBasedKey].to_s != ''
                $displayRidersHM[lifeBasedKey][rider.productSeq.to_s] = rider
                $displayRidersHM[loadingKey] = rider.QuotationProductExtraList
            else
                $displayRidersHM[lifeBasedKey] = Hash.new
                $displayRidersHM[lifeBasedKey][rider.productSeq.to_s] = rider
                $displayRidersHM[loadingKey] = rider.QuotationProductExtraList
            end
            @displayRiderLifeHeader[lifeBasedKey] = rider.insuredNames.to_s.force_encoding('UTF-8')
        end
        
        @totalPremium = maskDecimal(currentTotalPremium,"###,###,###.##")
        riderLabelObject = QuotationProduct.new(:removed=>"YES") 
        riderExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")

        returnHash = {}
        accordionsToBeRefresh.each do |accordionkey|
            next if $displayRidersHM[accordionkey] == nil
            if returnHash.has_key?('impactedLifeAccordions') && returnHash['impactedLifeAccordions'].to_s != ''
                returnHash['impactedLifeAccordions'] = "#{returnHash['impactedLifeAccordions']},#{accordionkey}"
            else
                returnHash['impactedLifeAccordions'] = accordionkey
            end
            riderObjects = if @params["riderInitialCount#{accordionkey}"] == nil
                @params['riderLastCount'] = @params['riderLastCount'].to_i+100
                @params['riderLastCount']
            else 
                @params["riderInitialCount#{accordionkey}"]
            end
            html = ""
            ridersSortBySelected,remainingRiders = $displayRidersHM[accordionkey].values.partition{|rider| rider.selected.to_s == "YES"}
            ridersSortBySelected.sort_by!{|rider| rider.sortOrder.to_i} if ridersSortBySelected.size > 0
            remainingRiders.sort_by!{|rider| rider.sortOrder.to_i} if remainingRiders.size > 0
            riders = ridersSortBySelected.concat remainingRiders

            if $rhoconfig[:application_view_mode] == "mobile"
                html << render(:partial => 'autoPopulateRiderMobile_Jazz', :locals => {:riders => riders, :riderLabelObject => riderLabelObject, :riderExtraLabelObject => riderExtraLabelObject, :riderObjects => riderObjects, :riderHeader => @displayRiderLifeHeader[accordionkey]})
            else
                html << render(:partial => 'autoPopulateRider_Jazz', :locals => {:riders => riders, :riderLabelObject => riderLabelObject, :riderExtraLabelObject => riderExtraLabelObject, :riderObjects => riderObjects, :riderHeader => @displayRiderLifeHeader[accordionkey]})
            end
            if returnHash.has_key?('html') && returnHash["html"].to_s != ''
                returnHash['html'][accordionkey] = html
            else
                returnHash['html'] = Hash.new
                returnHash['html'][accordionkey] = html
            end
        end
        return returnHash.to_json
    end

    def populateRider
        @quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
        
        accordionKey = @params['accordionKey']
        @riders = []
        @riderHeader = ''
        if $displayRidersHM.has_key?(accordionKey)
            riders = $displayRidersHM[accordionKey].values
            @riderHeader = riders[0].insuredNames.to_s.force_encoding('UTF-8')
        end
        @riderLabelObject = QuotationProduct.new(:removed=>"YES",:builtInRiderFl => "NO")
        riderExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
        @riderObjects = @params['riderInitialCount'].to_i

        @riderLoadingHash = {}
        riders.each do |qp|
            @riderLoadingHash[qp.object] = $displayRidersHM["#{accordionKey}|#{qp.object}"]
        end
        ridersSortBySelected,remainingRiders = riders.partition{|rider| rider.selected.to_s == "YES"}
        ridersSortBySelected.sort_by!{|rider| rider.sortOrder.to_i} if ridersSortBySelected.size > 0
        remainingRiders.sort_by!{|rider| rider.sortOrder.to_i} if remainingRiders.size > 0
        @riders = ridersSortBySelected.concat remainingRiders

        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
        html = ""

        if $rhoconfig[:application_view_mode] == "mobile"
            html << render(:partial => 'autoPopulateRiderMobile_Jazz', :locals => {:riders => @riders, :riderLabelObject => @riderLabelObject, :riderExtraLabelObject => riderExtraLabelObject, :riderObjects => @riderObjects, :riderHeader => @riderHeader})
        else
            html << render(:partial => 'autoPopulateRider_Jazz', :locals => {:riders => @riders, :riderLabelObject => @riderLabelObject, :riderExtraLabelObject => riderExtraLabelObject, :riderObjects => @riderObjects, :riderHeader => @riderHeader})
        end

        html << MobiSys::BrowserHelper.attachMaskAll(true)
        return html
    end

    def loadRiderProducts(quotation, product = nil, validateRider=true)
        #if rider auto population not required then just get the saved non built in riders and display on screen.
        @riderAutoPopulationReqFlag =  $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')
        @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")

        if @riderAutoPopulationReqFlag != "YES" 
            @newriders = []
            @newRiderFields = {}
            @premiumSAFlriders = {}
            @planLookups = {}
            nonBuiltInRiders = quotation.getNonBuiltInRiders
            nonBuiltInRiders.each do | nonBuiltInRider|
                #mark existing as selected as only these would be considered and this is not a persisted value.
                #riderProduct.setIsObjectSelected(MasterDataConstants.BOOLEAN.YES);
                if nonBuiltInRider.productSeq and nonBuiltInRider.productSeq != ""
                    planLookupArr = []
                    riderProduct = MobiSys::ProductUtil.getProduct(nonBuiltInRider.productSeq)
                    baseProduct = MobiSys::ProductUtil.getProduct(quotation.getBaseProduct.productSeq)

                    riderPlanOptionArray = []
                    riderAssocFacet = baseProduct.getFacet('RIDERASSOCIATION')
                    if riderAssocFacet != nil
                        riderAssocFacet.OfflineRiderAssociationList.each do |offlineRider|
                            if offlineRider.productSeq == riderProduct.id && offlineRider.builtInRiderFl != 'YES' && (offlineRider.basePlanOptionCd == quotation.getBaseProduct.productPlanOptionCd || offlineRider.basePlanOptionCd.to_s == "")
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
                    @planLookups[nonBuiltInRider.productSeq] = planLookupArr
                    if riderProduct.getPremiumDetailsFacet != nil && riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList != nil &&
                      riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0] != nil && riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement != nil
                      @newRiderFields[nonBuiltInRider.productSeq.to_i] = riderProduct.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement
                    end
                end
                @newriders.push(nonBuiltInRider)
            end
        else #below logic is for auto population of riders
            @riderLabelObject = QuotationProduct.new(:removed=>"YES") 
            @disableRiderCheckox = {}
            $displayRidersHM = {}
            @displayRiderLifeHeader = {}
            @ridersReadOnlyFields = {}
            ridersHM = {}
            facetRADO = $currentProduct.getFacet('RIDERASSOCIATION')
            if facetRADO != nil
                basePlan = quotation.getBaseProduct
                quotation.proposerLASame == "YES" ?  primaryPartyDO = quotation.getPartyByRole('PROPOSER') : primaryPartyDO = quotation.getPartyByRole('PRIMARY')
                basePlan.combinedEntryAge = primaryPartyDO.age.to_i if primaryPartyDO
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
                        quotation.getPartyRoleCds.each do |role|
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
                existingQuotationProducts = {}
                quotation.QuotationProductList.each do |qp|
                    if qp.productTypeCd.to_s == 'RIDER'
                        existingQuotationProducts["#{qp.insuredPartyRefGuid}|#{qp.productSeq}"] = qp
                    end
                end

                parties = quotation.QuotationPartyList
                
                parties.each do |party|
                    #when more than one RiderAssociation are mapped for one Rider based on plan options. this map will be used to check if the rider is applicable on atleast one of the plan options.
                    planOptionApplicableMap = Hash.new
                    riderAssociationList = riderAssociationListAsPerRoles[party.roleCd]
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
                            if offlineRiderAssociation.planOptionCd.to_s != ""
                              planOptionApplicableMap[offlineRiderAssociation.productSeq] = Hash.new unless planOptionApplicableMap[offlineRiderAssociation.productSeq]
                              planOptionApplicableMap[offlineRiderAssociation.productSeq][:applicable] ||= false
                            end
                            if offlineRiderAssociation.associationRelationTTmapSeq != nil
                                #if dependentRiderRoleCd is defined in association and DT then pasing all the qp's in quotation list otherwise qp's of corresponding party
                                if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''
                                    ogQuotationProductList = quotation.QuotationProductList
                                    tempQuotationProductList = []
                                    tempQuotationProductList.push basePlan
                                    tempQuotationProductList.push quotation.getRidersByParty(party.guid)
                                    quotation.setQuotationProductList(tempQuotationProductList.flatten)
                                end
                                defTableDO = MobiSys::ProductBO.getProductDefinitionTable(offlineRiderAssociation.associationRelationTTmapSeq, quotation, basePlan, party)
                                quotation.setQuotationProductList(ogQuotationProductList) if offlineRiderAssociation.dependentRiderRoleCd.to_s == ''

                                #if dt matched then based on the association relation mark as mandatory, auto selected
                                if defTableDO != nil
                                    if offlineRiderAssociation.planOptionCd.to_s != ""
                                      planOptionApplicableMap[offlineRiderAssociation.productSeq][:applicable] = true
                                    end
                                    autoPopulateRider(quotation, ridersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, party)
                                else
                                    listDefinitionTable = MobiSys::ProductUtil.loadProductDefinitionTableListForRidersByTableTypeMappingSeq(offlineRiderAssociation.associationRelationTTmapSeq, false)
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
                                            autoPopulateRider(quotation, ridersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, party)
                                        else
                                          quotation.QuotationProductList.each do |qp|
                                              if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && qp.partyRoleCd.to_s == party.roleCd.to_s && qp.insuredPartyRefGuid.to_s == party.guid.to_s
                                                if (offlineRiderAssociation.planOptionCd.to_s != "" && offlineRiderAssociation.planOptionCd.to_s == qp.productPlanOptionCd.to_s )
                                                    qp.selected = "NO"
                                                    qp.removed = "YES"
                                                elsif offlineRiderAssociation.planOptionCd.to_s == "" || (qp.productPlanOptionCd.to_s == "" && !planOptionApplicableMap[offlineRiderAssociation.productSeq][:applicable])
                                                  qp.selected = "NO"
                                                  qp.removed = "YES"
                                                else 
                                                end
                                                break
                                              end
                                          end
                                        end
                                    else
                                      quotation.QuotationProductList.each do |qp|
                                          if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && qp.partyRoleCd.to_s == party.roleCd.to_s && qp.insuredPartyRefGuid.to_s == party.guid.to_s
                                            if ((offlineRiderAssociation.planOptionCd.to_s != "" && (offlineRiderAssociation.planOptionCd.to_s == qp.productPlanOptionCd.to_s)) || offlineRiderAssociation.planOptionCd.to_s == "")
                                              if offlineRiderAssociation.planOptionCd.to_s != "" && planOptionApplicableMap[offlineRiderAssociation.productSeq][:applicable] && qp.productPlanOptionCd.to_s == ""
                                                qp.selected = planOptionApplicableMap[offlineRiderAssociation.productSeq][:selected] if planOptionApplicableMap[offlineRiderAssociation.productSeq][:selected].to_s != ""
                                                qp.removed = planOptionApplicableMap[offlineRiderAssociation.productSeq][:removed] if planOptionApplicableMap[offlineRiderAssociation.productSeq][:removed].to_s != ""
                                              else
                                                if offlineRiderAssociation.planOptionCd.to_s != ""
                                                  planOptionApplicableMap[offlineRiderAssociation.productSeq][:selected] = qp.selected if planOptionApplicableMap[offlineRiderAssociation.productSeq][:selected] == nil
                                                  planOptionApplicableMap[offlineRiderAssociation.productSeq][:removed] = qp.removed if planOptionApplicableMap[offlineRiderAssociation.productSeq][:removed] == nil
                                                end
                                                qp.selected = "NO"
                                                qp.removed = "YES"
                                              end
                                              break
                                            end
                                          end
                                      end
                                    end
                                end
                            else
                                autoPopulateRider(quotation, ridersHM, existingQuotationProducts, offlineRiderAssociation, nil, party)
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
            ridersHM.each do |key, rider|
                product = MobiSys::ProductUtil.getProduct(rider.productSeq)
                if rider.selected.to_s == 'YES' 
                    rider.removed = ''
                else
                    rider.removed = 'YES'
                end
                if validateRider && rider.selected.to_s == 'YES' 
                    MobiSys::ProductBO.validate(quotation, msg, errors, rider)
                end
                extraFacet = product.getFacetValue('PRODUCTEXTRAREQUIRED').to_s == 'YES'
                if extraFacet && rider.selected.to_s == 'YES' 
                    riderExtras, rider = MobiSys::QuotationBO.computeProductExtra(quotation, rider)
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

    def autoPopulateRider(quotationDO, displayRidersHM, existingQuotationProducts, riderAssociationDO, defTableDO, party)
        # unselectedRiders old format partyguid1|r1,partyguid1|r2,partyguid1|r3,partyguid2|r1,partyguid2|r2
        # unselectedRiders new format partyguid1:r1,r2,r3|partyguid2:r1,r2
        # converting old format to new format for backward compatibility
        if quotationDO.unselectedRiders.to_s != "" && !quotationDO.unselectedRiders.include?(":")
            unselectedRidersHM = {}
            quotationDO.unselectedRiders.split(",").each do |unselectedRider|
                partyGuid = unselectedRider.split("|")[0]
                if unselectedRidersHM.has_key?(partyGuid)
                    unselectedRidersHM[partyGuid] = unselectedRidersHM[partyGuid] + "," + unselectedRider.split("|")[1]
                else
                    unselectedRidersHM[partyGuid] = unselectedRider.split("|")[1]
                end
            end
            tempUnselectedRiders = ""
            unselectedRidersHM.map{|k,v| tempUnselectedRiders << "#{k}:#{v}|"}
           quotationDO.unselectedRiders = tempUnselectedRiders
        end
        # unselectedRidersArray = quotationDO.unselectedRiders.to_s.split(',') 
        unselectedRidersArray = []
        # unselectedRidersArray =  quotationDO.unselectedRiders.to_s.split("|").map{|a| a.split(":")[1]}.join(",").split(",").uniq
        # unselectedRidersArray = quotationDO.unselectedRiders.to_s.split("|").select{|a| a if a.include?(party.guid)}[0].split(":")[1]  if quotationDO.unselectedRiders.to_s != "" 
        if quotationDO.unselectedRiders.to_s != ""  
            tempArray = quotationDO.unselectedRiders.to_s.split("|").select{|a| a if a.include?(party.guid)} 
            unselectedRidersArray = tempArray[0].split(":")[1]   if !tempArray.empty?
        end

        riderKeyId = party.guid.to_s+'|'+riderAssociationDO.productSeq.to_s 
        # if insured is same as proposer then do not add same rider again in hash just skip it, also check planoption, if rider with new planoption comes then it is a new rider not the existing rider.. uniqueness of rider within life is defined with productseq and planoption
        partySameAsFlag = (quotationDO.proposerLASame == 'COPYFROMINSURED' || quotationDO.proposerLASame == 'YES') && (party.roleCd == 'PRIMARY' || party.roleCd == 'PROPOSER')
        riderExistFlag = false
        if partySameAsFlag
            insuredRiderExistFlag = false
            proposerRiderExistFlag = false
            insured = quotationDO.getPartyByRole('PRIMARY')
            insuredRider = displayRidersHM[insured.guid.to_s+'|'+riderAssociationDO.productSeq.to_s]
            if insuredRider
                if insuredRider.productSeq.to_s == riderAssociationDO.productSeq.to_s
                    if riderAssociationDO.planOptionCd.to_s == ''
                        insuredRiderExistFlag = true
                    elsif insuredRider.applicablePlanOptions.include? riderAssociationDO.planOptionCd.to_s
                        insuredRiderExistFlag = true
                    end
                end 
            end
            proposer = quotationDO.getPartyByRole('PROPOSER')
            proposerRider = displayRidersHM[proposer.guid.to_s+'|'+riderAssociationDO.productSeq.to_s]
            if proposerRider
                if proposerRider.productSeq.to_s == riderAssociationDO.productSeq.to_s
                    if riderAssociationDO.planOptionCd.to_s == ''
                        proposerRiderExistFlag = true
                    elsif proposerRider.applicablePlanOptions.include? riderAssociationDO.planOptionCd.to_s
                        proposerRiderExistFlag = true
                    end
                end 
            end
            riderExistFlag = insuredRiderExistFlag || proposerRiderExistFlag
        end

        return if partySameAsFlag && riderExistFlag

        if existingQuotationProducts.has_key?(riderKeyId)
            if displayRidersHM[riderKeyId] == nil
                displayRidersHM[riderKeyId] = existingQuotationProducts[riderKeyId]
                # resetting applicablePlanOptions on first load and then populating it subsequently
                displayRidersHM[riderKeyId].applicablePlanOptions = ''
            else
                displayRidersHM[riderKeyId] = existingQuotationProducts[riderKeyId]
            end

            if party.firstname.to_s == '' && party.lastname.to_s == ''
                displayRidersHM[riderKeyId].insuredNames = getLabelValue(party.roleCd.to_s)
            else
                if $rhoconfig[:application_view_mode] == "mobile"
                    if party.title.to_s == "OTHER"
                        displayRidersHM[riderKeyId].insuredNames =(party.firstname.to_s[0].to_s+party.lastname.to_s[0].to_s).upcase  << "|" <<  party.otherTitle.to_s + " " + party.firstname.to_s
                    else
                        displayRidersHM[riderKeyId].insuredNames =(party.firstname.to_s[0].to_s+party.lastname.to_s[0].to_s).upcase << "|" << getLabelValue(party.title.to_s) + " " + party.firstname.to_s  
                    end
                    if  displayRidersHM[riderKeyId].insuredNames.to_s.length  < 29
                        displayRidersHM[riderKeyId].insuredNames =  displayRidersHM[riderKeyId].insuredNames+ " " + party.lastname.to_s
                    end
                else                
                    if party.title.to_s == "OTHER"
                         displayRidersHM[riderKeyId].insuredNames = party.otherTitle.to_s + " " + party.firstname.to_s + " " + party.lastname.to_s
                    else
                        displayRidersHM[riderKeyId].insuredNames = getLabelValue(party.title.to_s) + " " + party.firstname.to_s + " " + party.lastname.to_s
                    end
                end 
            end
        elsif displayRidersHM[riderKeyId] == nil
            displayRidersHM[riderKeyId] = addBlankRider(quotationDO, party, riderAssociationDO)
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
            planOptionFacet = product.getFacet('PLANOPTION')
            if riderAssociationDO.planOptionCd.to_s != ""
                planOptions = OfflinePlanOption.find(:all, :conditions =>  {
                        {
                            :name => 'optionCd',
                        } => riderAssociationDO.planOptionCd,
                        {
                            :name => 'parentKey',
                        } => planOptionFacet.object
                    },
                    :op => 'AND'
                )
            else
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

    def addBlankRider(quotation, party, riderAssociation = nil)
        rider = QuotationProduct.new(:productTypeCd => 'RIDER', :partyRoleCd => party.roleCd, :builtInRiderFl => 'NO', :coi=>0.0, :insuredPartyRefGuid => party.guid)
        if riderAssociation != nil
            riderProduct = MobiSys::ProductUtil.getProduct(riderAssociation.productSeq)
            rider.productSeq = riderAssociation.productSeq
            rider.productId = riderAssociation.productId
            rider.parentproductSeq = riderAssociation.parentproductSeq
            rider.linkedFl = riderAssociation.linkedFl
            rider.sortOrder = riderAssociation.sortOrder
            rider.productFamilyCd = riderProduct.productFamilyId
            rider.productVersion = riderProduct.productVersion
            rider.guid = rider.uniqueKey
            rider.selected = 'NO'
            rider.combinedEntryAge = party.age
            if party.firstname.to_s == '' && party.lastname.to_s == ''
                rider.insuredNames = getLabelValue(party.roleCd.to_s)
            else
                if $rhoconfig[:application_view_mode] == "mobile"
                    if party.title.to_s == "OTHER"
                        rider.insuredNames = (party.firstname.to_s[0].to_s + party.lastname.to_s[0].to_s).upcase  << "|" <<  party.otherTitle.to_s + " " + party.firstname.to_s
                    else
                        rider.insuredNames = (party.firstname.to_s[0].to_s + party.lastname.to_s[0].to_s).upcase  << "|" << getLabelValue(party.title.to_s) + " " + party.firstname.to_s  
                    end

                    if  rider.insuredNames.to_s.length  < 29
                        rider.insuredNames = rider.insuredNames+ " " + party.lastname.to_s
                    end

                else                
                    if party.title.to_s == "OTHER"
                        rider.insuredNames = party.otherTitle.to_s + " " + party.firstname.to_s + " " + party.lastname.to_s
                    else
                        rider.insuredNames = getLabelValue(party.title.to_s) + " " + party.firstname.to_s + " " + party.lastname.to_s
                    end
                end 
            end
        end
        quotation.addQuotationProduct(rider)
        return rider
    end
    ###################################################################################################


     def summarypopup
        html = ""
        begin
            ############################## save Quotation ######################################
            if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                quotation_object = @params['quotation_object']
                @quotation = Quotation.loadObject(:first,:conditions=>{:object=> quotation_object })
            else
                @quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
                if @params['form'].has_key?("selectProductVersion")
                    $currentProduct = MobiSys::ProductUtil.getProduct(@params['form']['selectProductVersion'])
                elsif @params['form'].has_key?("selectProductId")
                    $currentProduct = MobiSys::ProductUtil.getProduct(@params["form"]['selectProductId'])
                end
                baseProduct = @quotation.getBaseProduct
                # Reset Base Plan hierarchy upon product change
                if baseProduct && $currentProduct && ((baseProduct.productSeq.to_s != $currentProduct.id.to_s && baseProduct.productSeq.to_s != "") || (@params['form'].has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['form']['selectProductPlan'] && baseProduct.productPlanOptionCd.to_s != ""))
                    changePlan(@quotation, @params['form'])

                    @quotation.visitedTabs = @params['form']['currentTab']
                    $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                    if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                        @quotation.visitedTabs = @quotation.visitedTabs.to_s + ",tab_basic"
                    end

                    if baseProduct.nil? && $currentProduct
                        baseProduct = QuotationProduct.new
                        baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params['form'], @quotation)
                        @quotation.addQuotationProduct(baseProduct)
                    elsif baseProduct.productSeq.to_s == "" && $currentProduct
                        baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params['form'], @quotation)
                    elsif baseProduct.productSeq.to_s == ""
                        baseProduct.product = Product.new
                    end
                end

                if baseProduct.nil?
                    baseProduct = QuotationProduct.new
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params['form'], @quotation)
                    @quotation.addQuotationProduct(baseProduct)
                elsif baseProduct.productSeq.to_s == ""
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params['form'], @quotation)
                end
                if @quotation.proposerLASame=='YES' || @quotation.proposerLASame=='COPYFROMINSURED'
                    @quotation.proposerLASame = "COPYFROMINSURED"
                else
                    @quotation.proposerLASame = nil
                end
                MobiSys::CommonUtil.clearTaskExceptionList(@quotation.guid)
                saveValidate(@params['form'],true,@quotation)
            end

            ########################### save Quotation Ends ###############################

            product_valid = true
            baseProduct = @quotation.getBaseProduct
            if @params.has_key?('form')
                if @params['form'].has_key?('sym_current_Tab') && @params['form']['sym_current_Tab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                    $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                    if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                        @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)
                        if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                            product_valid = false
                        end
                    end
                # elsif @params['form'].has_key?('sym_current_Tab') && @params['form']['sym_current_Tab'] == "tab_selProduct"
                #   currentProduct = nil
                    if @params['form'].has_key?("selectProductVersion")
                        currentProduct = MobiSys::ProductUtil.getProduct(@params['form']['selectProductVersion'])
                    elsif @params['form'].has_key?("selectProductId")
                        currentProduct = MobiSys::ProductUtil.getProduct(@params['form']['selectProductId'])
                    end
                    if baseProduct && currentProduct && (baseProduct.productSeq != currentProduct.id || (@params['form'].has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['form']['selectProductPlan']))
                        product_valid = false
                    end
                end
            end

            if product_valid
                ########################### summary Popup ########################################
                currencyCode = @quotation.getBaseProduct.currencyCd

                lookupValueOfCurrencyMaster = Lookupvalue.find(:first, 
                    :conditions =>  {
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
                html = premiumSummary(@quotation, html)  
            end
        rescue Exception => e
            Alert.show_popup({
                :message => getLabelValue('premiumSummaryError'), 
                :title => getLabelValue("error"),
                :buttons => ["OK"]
            })
        end
        return html
    end
    ########################################################################################################


    def emailQuotation
        emailRequest = MobiSys::BrowserHelper.convertToObject('EmailRequest', @params['EmailRequest'])
        emailRequest.emailReqStatusCd = "PENDING"
        emailRequest.persistAll
        quotation = Quotation.loadObject(  :first,
            :conditions => {
                :guid => emailRequest.entityGuid
            }
        )
        #OutputPreferences persist,retrieving and sync code added
        if @params['OutputPreferences']
            @outputPref = MobiSys::BrowserHelper.convertToObject('OutputPreferences', @params['OutputPreferences'])
            @outputPref.persistAll
        end

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
        if has_network
            forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

            if navigateToSync
                redirect :controller => :SyncCategory , :action => :syncPreferences, :query => {:forceNetworkLogin => forceNetworkLogin, :navigateToSync => navigateToSync, :masterSyncEnabled => masterSyncEnabled, :masterSyncDefault => masterSyncDefault, :transactionSyncEnabled => transactionSyncEnabled, :transactionSyncDefault => transactionSyncDefault, :masterDBUpgradeDt => masterDBUpgradeDt, :transactionSyncDt => transactionSyncDt, :masterDBMandatory => masterDBMandatory}
            else
                if $rhoconfig[:offlineOutputGeneration]
                    commonCalculateIllustration1
                    $CreateOutputFiles = false
                    System.start_timer(2000,url_for(:action=>:outputHTMLCallback)+"?outputPrefObj=#{@outputPref.object}&emailRequestObj=#{emailRequest.object}",@str)
                    render :action=>:syncProgress_Jazz, :layout => :jazzLayout
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
                    if @outputPref
                        syncEntities.push @outputPref
                    end
                    begin
                        MobiSys::Sync.sendEmailRequest(syncEntities, true)
                        WebView.navigate("#{url_for :action => :show, :id => quotation.object}")
                    rescue StandardError => se
                        #do nothing
                        puts "exception: #{se}"
                    end
                end
            end
        else
            if $rhoconfig[:offlineOutputGeneration]
                commonCalculateIllustration1
                $CreateOutputFiles = true
                System.start_timer(2000,url_for(:action=>:outputHTMLCallback)+"?outputPrefObj=#{@outputPref.object}&emailRequestObj=#{emailRequest.object}",@str)
                WebView.navigate(url_for :action => :syncProgress_Jazz, :id => quotation.object)
                Alert.show_popup( {
                    :message => getLabelValue('EMAILREQUESTQUEUED'),
                    :title => '',
                    :icon => :alert,
                    :buttons => ["OK"]
                } )
            else
                Alert.show_popup( {
                    :message => getLabelValue('EMAILREQUESTQUEUED'),
                    :title => '',
                    :icon => :alert,
                    :buttons => ["OK"],
                    :callback => WebView.navigate("/app/Menu/getInsuranceType?module=SALESILLUSTRATION") 
                } )
            end

        end
    end
    ########################################################################################################

    def viewIllustration
        WebView.execute_js("loading('show');")
        if @params.has_key?('id')
            id = @params['id'][1..-1].chop
            sym_current_Tab = "tab_basic"
            existingQuotation = Quotation.loadObject(:first,:conditions=>{:object=>id})
        else
            existingQuotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
            id = @params['form']['Quotation']['object']
            sym_current_Tab = @params['form']['sym_current_Tab']
        end
        trigger_source = ""
        trigger_source = "search" if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"

        unless @params.has_key?('id')
            existingQuotation.jointLife = nil if existingQuotation.jointLife==nil || existingQuotation.jointLife =='NO'

            if existingQuotation.proposerLASame=='YES' || existingQuotation.proposerLASame=='COPYFROMINSURED'
                existingQuotation.proposerLASame = "COPYFROMINSURED"
            else
                existingQuotation.proposerLASame = nil
            end

            unless existingQuotation.visitedTabs.to_s.include?(@params['form']['sym_current_Tab'])
                existingQuotation.visitedTabs = existingQuotation.visitedTabs.to_s + "," + @params['form']['sym_current_Tab']
            end

            MobiSys::CommonUtil.clearTaskExceptionList(existingQuotation.guid)
            saveValidate(@params['form'],true,existingQuotation)
        end

        if existingQuotation.quoteStatusCd.to_s != "" && existingQuotation.quoteStatusCd.to_s != 'PENDING'
            capture_output_preferences = $rhoconfig[:capture_output_preferences]
            if capture_output_preferences =='YES'
                WebView.navigate( url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'view', 'trigger_source' => trigger_source}, :id=>existingQuotation.object )
            else
                WebView.navigate( url_for :action => :calculateIllustration1, :id=>existingQuotation.object )
            end
        else
            WebView.navigate( url_for :action => :show, :query => {"msg" => @msg}, :id => existingQuotation.object )
        end
    end
    ########################################################################################################


    def acceptIllustration
        WebView.execute_js("loading('show');")
        if @params.has_key?('id')
            id = @params['id'][1..-1].chop
            sym_current_Tab = "tab_basic"
            existingQuotation = Quotation.loadObject(:first,:conditions=>{:object=>id})
        else
            existingQuotation= MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
            id = @params['form']['Quotation']['object']
            sym_current_Tab = @params['form']['sym_current_Tab']
        end

        unless @params.has_key?('id')
            existingQuotation.jointLife = nil if existingQuotation.jointLife==nil || existingQuotation.jointLife =='NO'

            if existingQuotation.proposerLASame=='YES' || existingQuotation.proposerLASame=='COPYFROMINSURED'
                existingQuotation.proposerLASame = "COPYFROMINSURED"
            else
                existingQuotation.proposerLASame = nil
            end
           
            unless existingQuotation.visitedTabs.to_s.include?(@params['form']['sym_current_Tab'])
                existingQuotation.visitedTabs = existingQuotation.visitedTabs.to_s + "," + @params['form']['sym_current_Tab']
            end

            MobiSys::CommonUtil.clearTaskExceptionList(existingQuotation.guid)          
            saveValidate(@params['form'],true,existingQuotation)
        end
        
        if existingQuotation.quoteStatusCd.to_s != "" && existingQuotation.quoteStatusCd.to_s != 'PENDING'
            if $rhoconfig[:capture_signature_on_quotataion] == "YES"
                existingQuotation.persistAll
                WebView.navigate(url_for :action => :captureSignature, :id => existingQuotation.object)
            else
                existingQuotation.signature = "SUCCESS"
                existingQuotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
                existingQuotation.signatureDt = Time.new.strftime("%F 00:00:00 %z") if existingQuotation.signatureDt.to_s == ""
                existingQuotation.persistAll
                MobiSys::TrackLeadBO.updateTrackLead(existingQuotation)
                addUserActivityHelper('ACCEPTILLUSTRATION', @params, 'QUOTATION', existingQuotation.quotationRefNum)
                if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                    @params['id'] = "{#{existingQuotation.object}}"
                    commonCalculateIllustration1
                    $CreateOutputFiles = true
                    System.start_timer(2000,url_for(:action=>:outputHTMLCallback)+"?outputPrefObj=#{@outputPref.object}",@str)
                    WebView.navigate(url_for :action => :syncProgress_Jazz, :id => existingQuotation.object)
                else
                    WebView.navigate(url_for :action => :show, :id => existingQuotation.object)
                end
            end
        else
            WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => sym_current_Tab}, :id => existingQuotation.object)
        end
    end
    ########################################################################################################


    def printOptionsAndEmail
       
        WebView.execute_js("loading('show');")
        @view_email = @params['view_email']
        quotationObject = @params['id'][1..-1].chop
        @quotation = Quotation.loadObject(:first,
          :conditions => {
              :object => quotationObject
              })
        @outputPref = OutputPreferences.new
        @outputPref = defaultOutputPreferences(@outputPref)

        if @view_email == "email" 
            @emailRequest = EmailRequest.new
            @emailRequest.entityGuid = @quotation.guid
            @emailRequest.entityNumber = @quotation.quotationRefNum
            proposer = @quotation.getPartyByRole('PROPOSER')
            @emailRequest.toEmail = proposer.emailAddress if proposer && proposer.emailAddress.to_s != ""
            @emailRequest.entityName = 'Quotation'
            @emailRequest.outputPrefEntityGuid = @outputPref.uniqueKey

            filteredProduct = Product.loadObject(
                :first,
                :conditions => {
                    {
                        :name => 'productId',
                    } => @quotation.productId,
                    {
                        :name => 'productVersion'
                    } => @quotation.productVersion
                },
                :op => 'AND'
            )
            quotationProduct = QuotationProduct.new

            quotationProduct.productId = filteredProduct.productId if filteredProduct != nil

            @illustrationReports = Array.new

            @shortIllustration = false
            @longIllustration = false
            @reportSections = []

            @illustrationReports.each do |illustrationReportDT|
                if illustrationReportDT.ruleName != nil
                    @longIllustration = true if illustrationReportDT.ruleName == "LONG"
                    @shortIllustration = true if illustrationReportDT.ruleName == "SHORT"
                    @reportSections.push(illustrationReportDT.ruleName)
                end
            end
        end

        @render_c_o_p = false
        @render_c_o_p = true if $rhoconfig[:capture_output_preferences] == 'YES'

        @formname = ""
        @formaction = ""
        @header_field = ""
        @submit_anchor_tag = ""
        if @view_email=="email"
            @formname = "emailForm"
            @formaction = "#{url_for :action => :emailQuotation}"
            @header_field = getLabelValue("EMAILHEADER")
            @submit_anchor_tag = "<a href='#' name='email' onclick='sendemail();'>#{getLabelValue('SUBMIT')}</a>"
        elsif @view_email=="view"
            @formname = "viewForm"
            @formaction = "#{url_for :action => :calculateIllustration1}"
            @header_field = getLabelValue("outputPrefDetail")
            @submit_anchor_tag = "<a href='#' name='view' onclick='sendview();'>#{getLabelValue('SUBMIT')}</a>"
        elsif @view_email=="get_pdf"
            @formname = "emailForm"
            if $rhoconfig[:offlinePDFGeneration] && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'
                @formaction = "#{url_for :action => :offlinePDFCalculateIllustration1}"
            else
                if $rhoconfig[:offlineOutputGeneration]
                    @formaction = "#{url_for :action => :outputCalculateIllustration1}"
                else
                    @formaction = "#{url_for :action => :get_pdf}"
                end
            end
            @header_field = getLabelValue("outputPrefDetail")
            @submit_anchor_tag = "<a href='#' name='email' onclick='sendemail();'>#{getLabelValue('SUBMIT')}</a>"
        elsif @view_email == 'downloadPDF'
            @formname = "viewForm"
            @formaction = "#{url_for :action => :pdfCalculateIllustration1}"
            @header_field = getLabelValue("outputPrefDetail")
            @submit_anchor_tag = "<a href='#' name='view' onclick='sendview();'>#{getLabelValue('SUBMIT')}</a>"
        end
        render :action => :captureOutputPreferencesAndEmail_Jazz, :back=>:illustration1, :id=> quotationObject, :layout => :jazzLayout   
    end

    ########################################################################################################


    def calculateIllustration1
        commonCalculateIllustration1
        System.start_timer(2000,url_for(:action=>:timerCallback),@str)
        render :action=>:syncProgress_Jazz, :layout => :jazzLayout
    end
    ########################################################################################################


    def captureSignature
        quotationObject = @params['id'][1..-1].chop
        @quotation = Quotation.loadObject(:first,:conditions => {:object => quotationObject})
        @agentSignatureCaptureFlag = $rhoconfig[:capture_agent_signature_on_quotataion] == "YES"
        render :action => :signature_Jazz, :layout => :jazzLayout
    end
    ########################################################################################################


    def saveSignature
        if @params.has_key?('captureSignatureOnOutput')
            if @params['formData'].has_key?('SignatureContainer')
                @signatureContainer = MobiSys::BrowserHelper.convertToObject('SignatureContainer', @params['formData']['SignatureContainer'])
                @signatureContainer.ServiceSignatureList.each do |serviceSignature|
                    if serviceSignature.signature.to_s != "" && !serviceSignature.signature.to_s.start_with?('ZLIBCMP')
                        serviceSignature.signature = serviceSignature.signature.gsub!('data:image/png;base64,','')
                        original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignature.signature)
                        compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                        serviceSignature.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
                        serviceSignature.signatureDt = getDBDate(serviceSignature.signatureDt) if serviceSignature.signatureDt.to_s != ""
                    end
                end
                @signatureContainer.persistAll
            end
            @quotation = Quotation.loadObject(  :first,
                :conditions => {
                    :object => @params['formData']['quotationObject']
                }
            )
                @quotation.signature = "SUCCESS"
            saveSignatureFlag = true  
        else
            @quotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['Quotation'])
            @agentSignatureCaptureFlag = $rhoconfig[:capture_agent_signature_on_quotataion] == "YES"
            if @quotation.signature.to_s != "" && !@quotation.signature.to_s.start_with?('ZLIBCMP')
                @quotation.signature = @quotation.signature.gsub!('data:image/png;base64,','')
                original_signature_decoded = MobiSys::Encryption.decodeContents(@quotation.signature)
                compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                @quotation.signature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
            end
            if @agentSignatureCaptureFlag && @quotation.agentSignature.to_s != "" && !@quotation.agentSignature.to_s.start_with?('ZLIBCMP')
                @quotation.agentSignature = @quotation.agentSignature.gsub!('data:image/png;base64,','')
                original_signature_decoded = MobiSys::Encryption.decodeContents(@quotation.agentSignature)
                compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
                @quotation.agentSignature = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
            end
            if @quotation.signature.to_s != "" 
                saveSignatureFlag = true  
                if @agentSignatureCaptureFlag && @quotation.agentSignature.to_s == "" 
                    saveSignatureFlag = false
                end  
            else
                saveSignatureFlag = false  
            end
        end
        if saveSignatureFlag
            @quotation.quoteStatusCd = MobiSys::QuotationBO::ACCEPTED
            @quotation.signatureDt = Time.new.strftime("%F 00:00:00 %z")
            @quotation.persistAll
            MobiSys::TrackLeadBO.updateTrackLead(@quotation)
            addUserActivityHelper('ACCEPTILLUSTRATION', @params, 'QUOTATION', @quotation.quotationRefNum)
            if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                @params['quotationObject'] = @quotation.object
                @params['id'] = "{#{@quotation.object}}"
                commonCalculateIllustration1
                $CreateOutputFiles = true
                System.start_timer(2000,url_for(:action=>:outputHTMLCallback)+"?outputPrefObj=#{@outputPref.object}",@str)
                WebView.navigate(url_for :action => :syncProgress_Jazz)
            else
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @quotation.object)
            end
        else
            Alert.show_popup({ 
                :message => getLabelValue("Please fill in signature"), 
                :title => getLabelValue("ERROR"),
                :buttons=> ["Ok"],
                :callback => url_for(:action => :prompt_dismiss)
            })
            render :action => :signature_Jazz, :layout => :jazzLayout
        end
    end
    ########################################################################################################


    def newShowBenefitTable
        commonShowBenefitTable
        unless $quotationIO.baseDO.taskExcDO == 'error'
          render :action=>:newUi_Jazz, :layout => :jazzLayoutWithGraph
        else
          redirect :action => :show, :id => $quotationIO.baseDO.object
        end
    end
    ########################################################################################################


    def get_pdf
        WebView.execute_js("loading('show');")
        if @params['OutputPreferences']
            quotation = Quotation.loadObject(:first,:conditions=>{{:name => 'guid'} => @params['Quotation']['guid']})
            outputPreferencesDO = MobiSys::BrowserHelper.convertToObject('OutputPreferences',@params['OutputPreferences'])
        else
            id = @params['id'][1..-1].chop
            quotation = Quotation.loadObject(:first,:conditions=>{:object => id})
            outputPreferencesDO = OutputPreferences.new
            outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
            outputPreferencesDO.persistAll
        end
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

            if navigateToSync
                redirect :controller => :SyncCategory , :action => :syncPreferences, :query => {:forceNetworkLogin => forceNetworkLogin, :navigateToSync => navigateToSync, :masterSyncEnabled => masterSyncEnabled, :masterSyncDefault => masterSyncDefault, :transactionSyncEnabled => transactionSyncEnabled, :transactionSyncDefault => transactionSyncDefault, :masterDBUpgradeDt => masterDBUpgradeDt, :transactionSyncDt => transactionSyncDt, :masterDBMandatory => masterDBMandatory}
            else
                signaturecontainer = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => quotation.guid
                                            }
                                        )
                syncEntities = []
                quotation.quoteStatusCd = 'ACCEPTED' if quotation.quoteStatusCd == 'SYNCDONE'
                syncEntities.push quotation
                syncEntities = syncEntities + signaturecontainer.ServiceSignatureList.flatten if signaturecontainer
                syncEntities.push outputPreferencesDO if outputPreferencesDO
                begin
                    resultsHash = MobiSys::Sync.sendEmailRequest(syncEntities, false, '/GenerateIllustrationPDF.run')
                    fileName = resultsHash['pdfFile']
                    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                    downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
                    Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                    filePath = File.join(downloadFolder, fileName)
                    if File::exist? filePath
                        System.open_url filePath
                        # WebView.navigate("/app/Quotation/{#{quotation.object}}/show")
                    else
                        decFCont = Base64.strict_decode64(resultsHash['PDFCONTENT'])
                        File.open(filePath, 'wb') { |file| file.write(decFCont) }
                        System.open_url(filePath)
                        # url = Application.getValue('online_server_url').value + "/GetIllustrationPDF.run"
                        # Rho::AsyncHttp.download_file(
                        #     :url => url,
                        #     :filename => filePath,
                        #     :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName},
                        #     :callback => '/app/Quotation/quotationPdfdownload',
                        #     :callback_param => "filePath=#{filePath}&quotationObject=#{quotation.object}",
                        #     :ssl_verify_peer => false)
                    end
                    WebView.navigate("/app/Quotation/{#{quotation.object}}/show")
                rescue StandardError => se
                    puts "exception: #{se}"
                    Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
                        :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
                        :buttons=>["OK"]})
                    WebView.navigate("/app/Quotation/{#{quotation.object}}/show")
                end
            end
        else
            Alert.show_popup( {
                :message => getLabelValue('REQUIRENETWORK'),
                :title => '',
                :icon => :alert,
                :buttons => ["OK"],
                :callback => WebView.navigate("/app/Quotation/{#{quotation.object}}/show") } )
        end
    end
    ########################################################################################################


    def quotationPdfdownload
        if @params['status'] == 'ok' and @params['http_error'] != "404" and @params['http_error'] != "500"
            System.open_url @params["filePath"]
        else
            Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
                :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
                :buttons=>["OK"]})
        end
        WebView.navigate("/app/Quotation/{#{@params['quotationObject']}}/show")
    end
    ########################################################################################################


    def pdfCalculateIllustration1
        WebView.execute_js("loading('show');")
        commonCalculateIllustration1
        System.start_timer(2000,url_for(:action=>:pdfTimerCallback),@str)
        render :action=>:syncProgress_Jazz, :layout => :jazzLayout
    end
    ########################################################################################################


    def pdfNewShowBenefitTable
        $showPdf = true
        commonShowBenefitTable
        unless $quotationIO.baseDO.taskExcDO == 'error'
          downLoadBenifitTable
        else
          redirect :action => :show, :id => $quotationIO.baseDO.object
        end
    end
    ########################################################################################################


    def downLoadBenifitTable
        Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
        $showPdf = nil
        @quotationIO = $quotationIO
        view = @quotationIO.illustrationModel.xslTemplateName
        @quotation = @quotationIO.baseDO
        @baseQuotationProduct = @quotation.getBaseProduct
        policyBenefitTerm = @baseQuotationProduct.productTerm

        @lineGraphKey = []
        @lineGraphKey = [getLabelValue('LOW'),getLabelValue('MEDIUM'),getLabelValue('HIGH')]

        isSinglePDFRequired = $rhoconfig[:isSinglePDFRequired]
        
        # create products hash
        @products = Product.find( :all,
        :order=>'sortOrder',
        :orderdir=>'ASC'
        )

        @products.each do |selectedProduct|
            if selectedProduct.productId == @baseQuotationProduct.productId
                @productDesc = selectedProduct.longName
            end
        end

        @listCalculation = @quotationIO.listCalculation
        @benefitTable = Hash.new
        @deathBenefitArray = []
        @elemMap = Hash.new
        ill_facet = IllustrationFacet.loadObject(:all)
        ill_facet.each do |illFacet|
            @elemMap[illFacet.computedElementName] = illFacet
        end
        @isMonthly = false
        illustration_model = @quotationIO.illustrationModel
        if illustration_model.computationFrequencyCd = "MONTHLY"
            @isMonthly = true
        end
        isTwoPdf = false
        fileNamesArray = []
        if view
          # html = render :action=>:newUi.to_sym
            html = render :action=>:newUi_Jazz.to_sym
            if(System.get_property('platform') == 'WINDOWS_DESKTOP')
                java_exists = system("java -version")
                if java_exists
                    # puts "isSinglePDFRequired.to_s :- #{isSinglePDFRequired.inspect}"
                    #filehtml = render :action=>:newUi, :layout=> :printlayout
                    if isSinglePDFRequired.to_s == "TWOSTEP"
                        $quotationIO.htmlContent.each_with_index do |htmlContent,index|
                            next if htmlContent.empty?
                            htmlHead = ""
                            htmlHead << "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">  <meta charset=\"utf-8\"> "
                            htmlHead << "<html>"
                            htmlHead << "<script src=\"/public/jquery/jquery-1.6.4.js\" type=\"text/javascript\"></script>"
                            htmlHead << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.scatter.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.annotate.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.context.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.dynamic.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.effects.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.resizing.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.tooltips.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.zoom.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.circle.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.image.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker1.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker2.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.text.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.xaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.yaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.rect.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.line.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.core.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.pie.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.key.js\" ></script>"

                            htmlHead << "<script src=\"/public/jquery/jquery.json-2.3.js\" type=\"text/javascript\"></script>"
                            htmlHead << "<script src=\"/public/js/jquery-barcode.js\" type=\"text/javascript\"></script>"
                            htmlHead << "<script src=\"/public/js/jquery-wp7-patch.js\"></script>"
                            htmlHead << "<script src=\"/public/js/jqueryMobile-c2l_patch.js\"></script>"
                            htmlHead << "<script src=\"/public/js/encrypt.js?v=1.0\" type=\"text/javascript\"></script>"
                            #htmlHead << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>"
                            #htmlHead << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>"
                            htmlHead << "<body>"

                            totalPages = htmlContent.size
                            pdfSkipOrder = "_1"
                            pdfPartOrder = "_2"

                            skipPageNumber=0
                            skipPageArray = []
                            lastNum = 0
                            startOfSecondPdf = 1 
                            endOfSecondPdf = totalPages 
                            totalSkipNumber = 0

                            htmlContent.each_pair do |pageNumber, page|
                                if(page["content"].include? "$SKIPPAGENUMBER$")
                                    skipPageArray << pageNumber
                                    isTwoPdf = true
                                    totalSkipNumber = totalSkipNumber - 1  
                                end
                            end

                            if(isTwoPdf)
                                pageCounter = 1
                                if(!skipPageArray.empty? && skipPageArray[0] != 1)
                                    pdfSkipOrder = "_2"
                                    pdfPartOrder = "_1"
                                    endOfSecondPdf = skipPageArray[0]-1
                                end
                                filehtml = ""
                                filehtml << htmlHead
                                skipPageArray.each do |i|
                                    # puts "$quotationIO.htmlContent[i][content] #{$quotationIO.htmlContent[i]["content"].inspect}"
                                    content = htmlContent[i]["content"]
                                    if(content.include? "$ZEROMARGIN$")
                                        htmlContent[i]["content"] = content.gsub("$ZEROMARGIN$", "")
                                        filehtml.concat("<div style=\"margin:0px !important;padding:0px !important;\">")
                                    else
                                        filehtml.concat("<div class=\"bodyDiv\">")
                                    end
                                    content = htmlContent[i]["content"]
                                    skipPageNumber -= 1
                                    filehtml.concat(content.gsub("$SKIPPAGENUMBER$", ""))
                                    if(pageCounter!=skipPageArray.size)
                                        filehtml.concat("<pd4ml:page.break></div></div>")
                                    else
                                        filehtml.concat("</div>")
                                    end
                                    pageCounter += 1
                                end #skipPageArray.each do |i|

                                filehtml << "</body>"
                                filehtml << "</html>"
                                data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                                data.each do |entry|
                                    newEntry = entry.gsub('"','')
                                    @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                                    FileUtils.cp @absolutePath, "#{Rho::RhoApplication.get_blob_folder}#{File::SEPARATOR}"
                                end
                                filehtml.gsub!('/public/jquery/','')
                                filehtml.gsub!('/public/js/RGraph/','')
                                filehtml.gsub!('/public/js/','')
                                filehtml.gsub!('/public/images/SalesIllustration/','')
                                filehtml.gsub!('/public/images/outputimages/','')
                                filehtml.gsub!('/public/css/','')
                                fileName= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}"+pdfSkipOrder.to_s+"_#{index}.html"
                                File.open(fileName,'w') do |f|
                                    f.puts filehtml
                                end
                                fileNamesArray.push(fileName)
                                # this.generateQuotationPDFFileUsingBuffer(quotationIO, null, filehtml, getFileName(quotationIO,false,true)+String.valueOf(pdfSkipOrder));
                     
                                lastNum = skipPageArray[skipPageArray.size-1] if !skipPageArray.empty?
                            end #isTwoPdf

                            if(lastNum != totalPages)
                                startOfSecondPdf = lastNum+1
                            end
                            filehtml = ""
                            filehtml << htmlHead
                            # htmlContent.each_pair{|pageNumber, page|
                            (startOfSecondPdf..endOfSecondPdf).each do |i|
                                # puts "htmlContent[i][content] #{htmlContent[i]["content"].inspect}"
                                pageNumber = i
                                content = htmlContent[i]["content"]
                                if(content.include? "$ZEROMARGIN$")
                                    content.gsub!("$ZEROMARGIN$", "")
                                    filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
                                else
                                    filehtml  << "<div class=\"bodyDiv\">"
                                end
                                if(content.include? "$SKIPPAGENUMBER$")
                                    skipPageNumber = skipPageNumber - 1
                                    content.gsub!("$SKIPPAGENUMBER$", "")
                                    if(pageNumber != totalPages)
                                        content << "<pd4ml:page.break></div></div>"
                                    else
                                        content << "</div>"
                                    end
                                else
                                    content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
                                    content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s)
                                    if(pageNumber != totalPages)
                                        content << "<pd4ml:page.break></div></div>"
                                    else
                                        content << "</div>"
                                    end
                                end            
                                filehtml << content
                            end #(startOfSecondPdf..endOfSecondPdf).each do |i|
                            filehtml << "</body>"
                            filehtml << "</html>"
                            data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                            data.each do |entry|
                                newEntry = entry.gsub('"','')
                                @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                                FileUtils.cp @absolutePath, "#{Rho::RhoApplication.get_blob_folder}#{File::SEPARATOR}"
                            end
                            filehtml.gsub!('/public/jquery/','')
                            filehtml.gsub!('/public/js/RGraph/','')
                            filehtml.gsub!('/public/js/','')
                            filehtml.gsub!('/public/images/SalesIllustration/','')
                            filehtml.gsub!('/public/images/outputimages/','')
                            filehtml.gsub!('/public/css/','')
                            if isTwoPdf 
                                fileName= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}"+pdfPartOrder+"_#{index}.html"
                            else
                                fileName= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}_#{index}.html"
                            end
                            File.open(fileName,'w') do |f|
                                f.puts filehtml
                            end
                            fileNamesArray.push(fileName)
                        end
                    elsif isSinglePDFRequired.to_s == "YES"#isSinglePDFRequired
                        $quotationIO.htmlContent.each_with_index do |htmlContent,index|
                            next if htmlContent.empty?
                            filehtml = ""
                            filehtml << "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">  <meta charset=\"utf-8\"> "
                            filehtml << "<html>"
                            filehtml << "<script src=\"/public/jquery/jquery-1.6.4.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.scatter.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.annotate.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.context.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.dynamic.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.effects.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.resizing.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.tooltips.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.zoom.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.circle.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.image.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker1.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker2.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.text.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.xaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.yaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.rect.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.line.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.core.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.pie.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.key.js\" ></script>"

                            filehtml << "<script src=\"/public/jquery/jquery.json-2.3.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script src=\"/public/js/jquery-barcode.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script src=\"/public/js/jquery-wp7-patch.js\"></script>"
                            filehtml << "<script src=\"/public/js/jqueryMobile-c2l_patch.js\"></script>"
                            filehtml << "<script src=\"/public/js/encrypt.js?v=1.0\" type=\"text/javascript\"></script>"
                            #filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>"
                            #filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>"
                            filehtml << "<body>"
                      
                            totalPages = htmlContent.size
                            skipPageNumber=0;
                            totalSkipNumber = 0;
                            htmlContent.each_pair do |pageNumber, page|
                                if(page["content"].include? "$SKIPPAGENUMBER$")
                                    totalSkipNumber = totalSkipNumber - 1;  
                                end
                            end
                            htmlContent.each_pair do |pageNumber, page|
                                content = page["content"]
                                if(page["content"].include? "$ZEROMARGIN$")
                                    content.gsub!("$ZEROMARGIN$", "")
                                    filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
                                else
                                    filehtml  << "<div class=\"bodyDiv\">"
                                end
                                if(content.include? "$SKIPPAGENUMBER$")
                                    skipPageNumber = skipPageNumber - 1
                                    content.gsub!("$SKIPPAGENUMBER$", "")
                                    if(pageNumber != totalPages)
                                        content << "<pd4ml:page.break></div></div>"
                                    else
                                        content << "</div>"
                                    end
                                else
                                    content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
                                    content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
                                    if(pageNumber != totalPages)
                                        content << "<pd4ml:page.break></div></div>"
                                    else
                                        content << "</div>"
                                    end
                                end            
                                filehtml << content
                            end
                            filehtml << "</body>"
                            filehtml << "</html>"
                            data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                            data.each do |entry|
                                newEntry = entry.gsub('"','')
                                @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                                FileUtils.cp @absolutePath, "#{Rho::RhoApplication.get_blob_folder}#{File::SEPARATOR}"
                            end
                            filehtml.gsub!('/public/jquery/','')
                            filehtml.gsub!('/public/js/RGraph/','')
                            filehtml.gsub!('/public/js/','')
                            filehtml.gsub!('/public/images/SalesIllustration/','')
                            filehtml.gsub!('/public/images/outputimages/','')
                            filehtml.gsub!('/public/css/','')
                            fileName= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}"+"_#{index}.html"
                            File.open(fileName,'w') do |f|
                                f.puts filehtml
                            end
                            fileNamesArray.push(fileName)
                        end
                    else #isSinglePDFRequired
                        $quotationIO.htmlContent.each_pair do |pageNumber, page|
                            filehtml = ""
                            filehtml << "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">  <meta charset=\"utf-8\"> "
                            filehtml << "<html>"
                            filehtml << "<script src=\"/public/jquery/jquery-1.6.4.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.scatter.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.annotate.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.context.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.dynamic.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.effects.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.resizing.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.tooltips.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.zoom.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.circle.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.image.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker1.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.marker2.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.text.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.xaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.yaxis.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.drawing.rect.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.line.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.core.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.pie.js\" ></script>
                            <script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.common.key.js\" ></script>"

                            filehtml << "<script src=\"/public/jquery/jquery.json-2.3.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script src=\"/public/js/jquery-barcode.js\" type=\"text/javascript\"></script>"
                            filehtml << "<script src=\"/public/js/jquery-wp7-patch.js\"></script>"
                            filehtml << "<script src=\"/public/js/jqueryMobile-c2l_patch.js\"></script>"
                            filehtml << "<script src=\"/public/js/encrypt.js?v=1.0\" type=\"text/javascript\"></script>"
                            #filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.bar.js\" ></script>"
                            #filehtml << "<script type=\"text/javascript\" src=\"/public/js/RGraph/RGraph.hbar.js\" ></script>"
                            filehtml << "<body>"
                            filehtml << page["content"].gsub("$SKIPPAGENUMBER$", "")
                            filehtml << "</body>"
                            filehtml << "</html>"
                            data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                            data.each do |entry|
                                newEntry = entry.gsub('"','')
                                @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                                FileUtils.cp @absolutePath, "#{Rho::RhoApplication.get_blob_folder}#{File::SEPARATOR}"
                            end
                            filehtml.gsub!('/public/jquery/','')
                            filehtml.gsub!('/public/js/RGraph/','')
                            filehtml.gsub!('/public/js/','')
                            filehtml.gsub!('/public/images/SalesIllustration/','')
                            filehtml.gsub!('/public/images/outputimages/','')
                            filehtml.gsub!('/public/css/','')
                            #changes for page ordering start #jeet
                            pageNumberTemp = pageNumber
                            if pageNumber.to_s.length == 1
                                pageNumberTemp = "0" + pageNumber.to_s
                            end
                            fileName= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}_#{pageNumberTemp.to_s}.html"
                            #changes for page ordering end
                            File.open(fileName,'w') do |f|
                                f.puts filehtml
                            end
                        end
                    end #isSinglePDFRequired
                    queryString = "Select tpmDO.* from OutputContext outputDO , TemplateMaster tpmDO where 
                    outputDO.product = '#{@baseQuotationProduct.productId}' and outputDO.templateMasterSeq = tpmDO.id"
                    # puts "queryString: #{queryString}"
                    orientation = "PORTRAIT"
                    templateMasterDOList = TemplateMaster.find_by_sql(queryString)
                    templateMasterDOList.each do |templateMasterDOListev|
                    orientation = templateMasterDOListev.orientation
                    end
                    fileNameNew= Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{@quotation.quotationRefNum.gsub('/','')}.html"
                    pdfFile = fileNameNew.gsub('html','pdf')
                    cmdStr = "javaw -classpath #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pd4ml.jar;"
                    cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}pdf.jar;"
                    cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}ss_css2.jar;"
                    cmdStr << "#{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}lib#{File::SEPARATOR}fonts.jar"
                    cmdStr << " com.c2lbiz.pdf.Converter"
                    cmdStr << " #{@quotation.quotationRefNum.gsub('/','')}" #0 inputHTMLFileName
                    cmdStr << " #{@quotation.quotationRefNum.gsub('/','')}.pdf" #1 outputPDFFile
                    cmdStr << " #{Rho::RhoApplication.get_blob_folder + File::SEPARATOR}" #2 path
                    cmdStr << " #{Rho::RhoApplication.get_base_app_path()}public#{File::SEPARATOR}fonts" #3 fontsDir
                    cmdStr << " #{orientation.to_s.upcase}" #4 orientation should be "LANDSCAPE" or "PORTRAIT"
                    cmdStr << " #{isSinglePDFRequired.to_s.upcase}" #5 pdf Generation method should be "SINGLE" or "MULTIPLE"
                    # cmdStr << " 1>D:#{File::SEPARATOR}1.txt 2>D:#{File::SEPARATOR}2.txt" #to debug
                    puts "cmdStr: #{cmdStr}"

                    system(cmdStr)

                    #Deleting html files
                    fileNamesArray.each do |fileName|
                        FileUtils.rm_r fileName
                    end
                    
                    if isSinglePDFRequired.to_s != "YES" && isSinglePDFRequired.to_s != "TWOSTEP"
                        fileNameNew = fileNameNew.gsub('.html','')
                        $quotationIO.htmlContent.each_pair do |pageNumber, page|
                            pageNumberTemp = pageNumber
                            if pageNumber.to_s.length == 1
                                pageNumberTemp = "0" + pageNumber.to_s
                            end
                            FileUtils.rm_r "#{fileNameNew}_#{pageNumberTemp.to_s}.html"
                        end
                    end

                    Dir[Rho::RhoApplication.get_blob_folder + File::SEPARATOR+"*[png|jpeg|jpg]"].each do |fname|
                        FileUtils.rm_r fname
                    end
                    System.open_url(pdfFile)
                else
                    Alert.show_popup({:title=>getLabelValue('No Java found, Could not generate '),
                        :message=>getLabelValue('No Java found, Could not generate PDF '),
                        :buttons=>["OK"]})
                end
            end
            redirect :action => :show, :id => @quotation.object
        else
              # render :action => :newBenefittable
            render :action => :show, :id => @quotation.object
        end
    end
    ########################################################################################################


    #Method to get portfolioModelCd for base product based on DT evaluation
    def getPortfolioModelCd(product=nil, quotation=nil, baseProduct=nil)
        if !product
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            baseProduct = quotation.getBaseProduct
            product = $currentProduct
        end

        modelArray = []
        offlineProductModelArray = []
        modelString = '<option value="" selected>Select</option>'

        fundDervFacet = product.getFacet("FUNDMODELDERIVATION")
        if fundDervFacet
            fundDervFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(product.getTableTypeMappingSeq("FUNDMODELDERIVATION"), quotation, baseProduct)
            if fundDervFacetProductDef
                offlineProductModelArray = fundDervFacetProductDef.outputAction.split(',')
            else
                if baseProduct.currencyCd.to_s != ""
                    premiumModel = product.getPremiumModel(baseProduct.currencyCd.to_s)
                    offlineProductModelArray.push premiumModel.modelCd if premiumModel
                else
                    product.OfflineProductModelMapList.each do |offlineProductModel|
                        offlineProductModelArray.push(offlineProductModel.modelCd)
                    end
                end
            end
        else
            if baseProduct.currencyCd.to_s != ""
                premiumModel = product.getPremiumModel(baseProduct.currencyCd.to_s)
                offlineProductModelArray.push premiumModel.modelCd if premiumModel
            else
                product.OfflineProductModelMapList.each do |offlineProductModel|
                    offlineProductModelArray.push(offlineProductModel.modelCd)
                end
            end
        end

        modelfunds = Model.loadObject(
            :all, 
            :conditions => {
                {
                    :name => 'modelCd',
                    :op => 'IN'
                    } => offlineProductModelArray
                }
                )

        modelfunds.each do |modelFund|
            if modelFund.modelCd != nil
                modelLookup = Lookupvalue.new
                modelLookup.cd = modelFund.modelCd
                modelLookup.desc = modelFund.modelDesc
                modelArray.push(modelLookup)
                selected = "selected" if baseProduct.portfolioModelCd.to_s == modelFund.modelCd.to_s
                if modelfunds.length == 1
                    modelString =  '<option value="' + modelFund.modelCd + '" '+selected.to_s+'>' + modelFund.modelDesc + '</option>'
                else
                    modelString = modelString + '<option value="' + modelFund.modelCd + '" '+selected.to_s+'>' + modelFund.modelDesc + '</option>'
                end
            end
        end

        if @params.has_key?('Quotation')
            render :string => modelString
        else
            return modelArray
        end
    end
    ########################################################################################################


    #Method to initiate online PDF generation based on offline HTML
    def outputCalculateIllustration1
        WebView.execute_js("loading('show');")
        if @params['OutputPreferences']
            quotation = Quotation.loadObject(:first,:conditions=>{{:name => 'guid'} => @params['Quotation']['guid']})
            outputPreferencesDO = MobiSys::BrowserHelper.convertToObject('OutputPreferences',@params['OutputPreferences'])
        else
            id = @params['id'][1..-1].chop
            quotation = Quotation.loadObject(:first,:conditions=>{:object => id})
            outputPreferencesDO = OutputPreferences.new
            outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
            outputPreferencesDO.persistAll
        end
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

            if navigateToSync
                redirect :controller => :SyncCategory , :action => :syncPreferences, :query => {:forceNetworkLogin => forceNetworkLogin, :navigateToSync => navigateToSync, :masterSyncEnabled => masterSyncEnabled, :masterSyncDefault => masterSyncDefault, :transactionSyncEnabled => transactionSyncEnabled, :transactionSyncDefault => transactionSyncDefault, :masterDBUpgradeDt => masterDBUpgradeDt, :transactionSyncDt => transactionSyncDt, :masterDBMandatory => masterDBMandatory}
            else
                commonCalculateIllustration1
                $CreateOutputFiles = false
                System.start_timer(2000,url_for(:action=>:outputHTMLCallback)+"?outputPrefObj=#{outputPreferencesDO.object}",@str)
                render :action=>:syncProgress_Jazz, :layout => :jazzLayout
            end
        else
            Alert.show_popup({
                :message => getLabelValue('REQUIRENETWORK'),
                :title => '',
                :icon => :alert,
                :buttons => ["OK"],
                :callback => WebView.navigate("/app/Quotation/{#{quotation.object}}/show") 
                })
        end
    end
    ########################################################################################################
    

    # generatePdfs: takes multiple requests from illustrationSelect page to find OutputPreferences for selected quotation and sends to generateMultipleOutputHTML
    def generatePdfs
        pdfsToBeGenerated = @params['illustrationCheck']
        if pdfsToBeGenerated.to_s != ""
            pdfsToBeGenerated.each do |selectedQuotationId|
                quotationobject = Quotation.loadObject(:first, :conditions => {{:name => 'object'} => selectedQuotationId},:loadChild=>false)
                if quotationobject
                    emailRequestForPdf = EmailRequest.loadObject(:first,:conditions=>{{:name => 'entityGuid'} => quotationobject.guid },:loadChild=>false)
                    if emailRequestForPdf
                        outputPreferencesObject = OutputPreferences.loadObject(:first, :conditions => {{:name => 'guid' } => emailRequestForPdf.outputPrefEntityGuid },:loadChild=>false)
                    else
                        outputPreferencesObject = OutputPreferences.new
                        outputPreferencesObject = defaultOutputPreferences(outputPreferencesObject)
                        outputPreferencesObject.persistAll
                    end
                    outputpreference = outputPreferencesObject.object if outputPreferencesObject
                end

                # formed string @str with object column values of OutputPreference and selectedQuotationId
                @str = "selectedQuotationId=#{selectedQuotationId}&outputPref=#{outputpreference}&quotationObject=#{selectedQuotationId}"
                if quotationobject && outputPreferencesObject
                    System.start_timer(2000,url_for(:action=>:generateMultipleOutputHTML)+"?outputPrefObj=#{outputpreference}",@str)
                end
            end
            render :action=>:syncProgress_Jazz, :layout => :jazzLayout
        end
        WebView.navigate(url_for(:controller=> :Quotation, :action => :searchmulti))
    end
    ########################################################################################################
    

    # generateMultipleOutputHTML: creates HTML  and sends to online server
    def generateMultipleOutputHTML
        outputPrefObj = @params['outputPrefObj']
        commonTimerCallback
        $showPdf = true
        commonShowBenefitTable
        $showPdf = nil
        filehtmlArray = Array.new

        $quotationIO.htmlContent.each do |htmlContent|
            if !htmlContent.empty?
                filehtml = ""
                filehtml << "<!DOCTYPE html>"
                filehtml << "<html lang=\"en\">"
                filehtml << "<head>"
                filehtml << "<meta charset=\"utf-8\">"
                filehtml << "</head>"
                filehtml << "<body>"

                totalPages = htmlContent.size
                skipPageNumber=0;
                totalSkipNumber = 0;
                htmlContent.each_pair do |pageNumber, page|
                    if(page["content"].include? "$SKIPPAGENUMBER$")
                        totalSkipNumber = totalSkipNumber - 1;  
                    end
                end
                htmlContent.each_pair do |pageNumber, page|
                    content = page["content"]
                    if(page["content"].include? "$ZEROMARGIN$")
                        content.gsub!("$ZEROMARGIN$", "")
                        filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
                    else
                        filehtml  << "<div class=\"bodyDiv\">"
                    end
                    if(content.include? "$SKIPPAGENUMBER$")
                        skipPageNumber = skipPageNumber - 1
                        content.gsub!("$SKIPPAGENUMBER$", "")
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    else
                        content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
                        content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    end
                    filehtml << content
                end
                filehtml << "</body>"
                filehtml << "</html>"

                # data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                # data.each do |entry|
                #     newEntry = entry.gsub('"','')
                #     @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                #     FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
                # end
                filehtml.gsub!('/public/jquery/','')
                filehtml.gsub!('/public/js/RGraph/','')
                filehtml.gsub!('/public/js/','')
                filehtml.gsub!('/public/images/SalesIllustration/','')
                filehtml.gsub!('/public/images/outputimages/','')
                filehtml.gsub!('/public/css/','')
                filehtmlArray.push(filehtml)
            end
        end
        
        begin
            syncEntities = {}
            filehtmlArray.each_with_index do |filehtml, index|
                syncEntities["html#{index+1}"] = filehtml
            end
            syncEntities["htmlCount"] = filehtmlArray.size.to_s
            syncEntities["graphJSON"] = $quotationIO.graphJSON

            $quotationIO.baseDO.quoteStatusCd = 'ACCEPTED' if $quotationIO.baseDO.quoteStatusCd == 'SYNCDONE'
            syncEntities[Quotation.onlineClassName] = ::JSON.generate([{Quotation.onlineClassName => [$quotationIO.baseDO.hashForSync]}.to_json])

            if outputPrefObj.to_s != ""
                outputPreferencesDO = OutputPreferences.loadObject(:first,:conditions=>{{:name => 'object' } =>outputPrefObj.to_s},:loadChild=>false)
                syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) if outputPreferencesDO
            end

            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            if has_network         
                obj.doJSONPost('/GenerateIllustrationPDF.run', ::JSON.generate(syncEntities))
            else
                results="ERR_NETWORK"
            end
        rescue StandardError => se
            puts "exception: #{se}"
            Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
                :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
                :buttons=>["OK"]})
            WebView.navigate(url_for(:controller=> :Menu, :action => :landingPage))

        end
    end
    ########################################################################################################

    #Timer callback method for online PDF generation based on offline HTML
    def outputHTMLCallback
        commonTimerCallback
        WebView.navigate("/app/Quotation/generateOutputHTML?outputPrefObj=#{@params['outputPrefObj']}&emailRequestObj=#{@params['emailRequestObj']}")
    end
    ########################################################################################################

    #Method to generate HTML source for online PDF generation based on offline HTML
    def generateOutputHTML
        $showPdf = true
        commonShowBenefitTable
        $showPdf = nil
        filehtmlArray = Array.new

        $quotationIO.htmlContent.each do |htmlContent|
            if !htmlContent.empty?
                filehtml = ""
                filehtml << "<!DOCTYPE html>"
                filehtml << "<html lang=\"en\">"
                filehtml << "<head>"
                filehtml << "<meta charset=\"utf-8\">"
                filehtml << "</head>"
                filehtml << "<body>"

                totalPages = htmlContent.size
                skipPageNumber=0;
                totalSkipNumber = 0;
                htmlContent.each_pair do |pageNumber, page|
                    if(page["content"].include? "$SKIPPAGENUMBER$")
                        totalSkipNumber = totalSkipNumber - 1;  
                    end
                end
                htmlContent.each_pair do |pageNumber, page|
                    content = page["content"]
                    if(page["content"].include? "$ZEROMARGIN$")
                        content.gsub!("$ZEROMARGIN$", "")
                        filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
                    else
                        filehtml  << "<div class=\"bodyDiv\">"
                    end
                    if(content.include? "$SKIPPAGENUMBER$")
                        skipPageNumber = skipPageNumber - 1
                        content.gsub!("$SKIPPAGENUMBER$", "")
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    else
                        content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
                        content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    end
                    filehtml << content
                end
                filehtml << "</body>"
                filehtml << "</html>"

                # data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
                # data.each do |entry|
                #     newEntry = entry.gsub('"','')
                #     @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
                #     FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
                # end
                filehtml.gsub!('/public/jquery/','')
                filehtml.gsub!('/public/js/RGraph/','')
                filehtml.gsub!('/public/js/','')
                filehtml.gsub!('/public/images/SalesIllustration/','')
                filehtml.gsub!('/public/images/outputimages/','')
                filehtml.gsub!('/public/css/','')
                filehtmlArray.push(filehtml)
            end
        end
        begin
            syncEntities = {}
            filehtmlArray.each_with_index do |filehtml, index|
                syncEntities["html#{index+1}"] = filehtml
            end
            syncEntities["htmlCount"] = filehtmlArray.size.to_s
            syncEntities["graphJSON"] = $quotationIO.graphJSON

            $quotationIO.baseDO.quoteStatusCd = 'ACCEPTED' if $quotationIO.baseDO.quoteStatusCd == 'SYNCDONE'
            quotation = Quotation.loadObject(:first, :conditions => {:object => $quotationIO.baseDO.object})
            syncEntities[Quotation.onlineClassName] = ::JSON.generate([{Quotation.onlineClassName => [quotation.hashForSync]}.to_json])
            
            jsonFileSuffix = ""
            if $quotationIO.baseDO.quoteStatusCd == 'ACCEPTED' && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                jsonFileSuffix = "ACCEPT"
                if $rhoconfig[:offlineOutputGeneration]
                    fileName = "Quotation_#{$quotationIO.baseDO.quotationRefNum.to_s}_ACCEPT.json"
                    filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
                    if File.exist?(filePath)
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlHash = {}
                        htmlCount = jsonObjects["htmlCount"].to_i
                        for i in 1..htmlCount
                            htmlHash["html#{i}"] = jsonObjects["html#{i}"]
                        end
                        otherDetailsHM = {}
                        otherDetailsHM["html#{1}"] = htmlHash.to_json
                        otherDetailsHM["graphJSON#{1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{1}"] = $quotationIO.baseDO.class.name.to_s
                        otherDetailsHM["entityNum#{1}"] = $quotationIO.baseDO.quotationRefNum.to_s
                        otherDetailsHM["entityGuid#{1}"] = $quotationIO.baseDO.guid.to_s
                        otherDetailsHM["htmlCount#{1}"] = jsonObjects["htmlCount"]
                        otherDetailsHM["accept#{1}"] = "ACCEPT"
                        syncEntities["otherDetails"] = ::JSON.generate(otherDetailsHM) if !otherDetailsHM.empty?
                    end
                end
            end
            if @params['outputPrefObj'].to_s != ""
                outputPreferencesDO = OutputPreferences.loadObject(:first,:conditions=>{:object => @params['outputPrefObj']},:loadChild=>false)
                if outputPreferencesDO
                    syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
                end
            else
                outputPreferencesDO = OutputPreferences.new
                outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
                outputPreferencesDO.persistAll
                syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
            end

            if @params['emailRequestObj'].to_s != ""
                emailRequestDO = EmailRequest.loadObject(:first,:conditions=>{:object => @params['emailRequestObj']},:loadChild=>false)
                jsonFileSuffix = emailRequestDO.outputPrefEntityGuid
                if emailRequestDO
                    syncEntities[EmailRequest.onlineClassName] = ::JSON.generate([{EmailRequest.onlineClassName => [emailRequestDO.hashForSync]}.to_json])                   
                end
            end

            signaturecontainer = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => $quotationIO.baseDO.guid
                                            }
                                        )
            if signaturecontainer
                tempList = []
                    signaturecontainer.ServiceSignatureList.each do |ss|
                        tempList.push ss.hashForSync
                    end
                syncEntities[ServiceSignature.onlineClassName] = ::JSON.generate([{ServiceSignature.onlineClassName => tempList.flatten}.to_json])
            end

            if $CreateOutputFiles == true && jsonFileSuffix.to_s != ""
                jsonFileName= Rho::RhoApplication.userFolder + File::SEPARATOR + "Quotation_#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{jsonFileSuffix}.json"
                file = File.open(jsonFileName,'w+b')
                encryptedContent = MobiSys::Encryption.encryptAndEncodeContent(syncEntities.to_json)
                file.write(encryptedContent)
                file.close
            elsif !$CreateOutputFiles
                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new

                unless @params['emailRequestObj'].to_s != ""
                    response = obj.doJSONPost('/GenerateIllustrationPDF.run', ::JSON.generate(syncEntities))
                    resultsHash = Rho::JSON.parse(response)
                    fileName = resultsHash['pdfFile']
                    if resultsHash[Quotation.onlineClassName]
                        quotation_hash = Rho::JSON.parse(resultsHash[Quotation.onlineClassName])[0]
                        existingQuotation = Quotation.loadObject(:first, conditions: { object: $quotationIO.baseDO.object })
                        quotation = MobiSys::MobiSysEntitySchema.from_hash('Quotation', quotation_hash)
                        existingQuotation.merge(quotation)
                        existingQuotation.persistAll
                    end

                    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                    downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
                    Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                    filePath = File.join(downloadFolder, fileName)
                    File.delete(filePath) if File::exist?(filePath)

                    decFCont = Base64.strict_decode64(resultsHash['PDFCONTENT'])
                    File.open(filePath, 'wb') { |file| file.write(decFCont) }
                    System.open_url(filePath)

                    # url = Application.getValue('online_server_url').value + "/GetIllustrationPDF.run"
                    # Rho::AsyncHttp.download_file(
                    #   :url => url,
                    #   :filename => filePath,
                    #   :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName},
                    #   :callback => '/app/Quotation/quotationPdfdownload',
                    #   :callback_param => "filePath=#{filePath}&quotationObject=#{$quotationIO.baseDO.object}",
                    #   :ssl_verify_peer => $ssl_verify_peer)
                else
                    response = obj.doJSONPost('/SendEmailRequest.run', ::JSON.generate(syncEntities))
                    if response != ""
                        emailRequestDO.afterSync if @params['emailRequestObj'].to_s != ""
                    end
                    Alert.show_popup({
                        :message => MobiSys::BrowserHelper.getLabel('EMAILSENT'),
                        :title => '',
                        :icon => :alert,
                        :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
                    })
                end
            end
            if @params['emailRequestObj'].to_s != ""
                errorPopup = getLabelValue('Email')
            else
                errorPopup = getLabelValue('ILLUSTRATIONDOWNLOAD')
            end
        rescue StandardError => se
            puts "exception: #{se}"
            Alert.show_popup({:title=> errorPopup,
                :message=>getLabelValue('DOWNLOADFAILED',[errorPopup]),
                :buttons=>["OK"]})
            WebView.navigate("/app/Quotation/{#{$quotationIO.baseDO.object}}/show")
        end

        redirect :action => :show, :id => $quotationIO.baseDO.object, :layout => :jazzLayout
    end
    ########################################################################################################


    #Method to initiate offline PDF generation based on offline HTML
    def offlinePDFCalculateIllustration1
        WebView.execute_js("loading('show');")
        if @params['OutputPreferences']
            quotation = Quotation.loadObject(:first,:conditions=>{{:name => 'guid'} => @params['Quotation']['guid']})
            outputPreferencesDO = MobiSys::BrowserHelper.convertToObject('OutputPreferences',@params['OutputPreferences'])
            outputPreferencesDO.persistAll
        else
            id = @params['id'][1..-1].chop
            quotation = Quotation.loadObject(:first,:conditions=>{:object => id})
            outputPreferencesDO = OutputPreferences.new
            outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
            outputPreferencesDO.persistAll
        end

        commonCalculateIllustration1
        System.start_timer(2000,url_for(:action=>:offlinePDFCallback)+"?outputPrefObj=#{outputPreferencesDO.object}",@str)
        render :action=>:syncProgress_Jazz, :layout => :jazzLayout
    end
    ########################################################################################################


    #Timer callback method for offline PDF generation based on offline HTML
    def offlinePDFCallback
        commonTimerCallback
        WebView.navigate("/app/Quotation/generateOfflinePDFHTML?outputPrefObj=#{@params['outputPrefObj']}")
    end
    ########################################################################################################


    #Method to generate HTML source for offline PDF generation based on offline HTML
    def generateOfflinePDFHTML
        if System.get_property('platform') == 'ANDROID'
            $showPdf = true
        elsif System.get_property('platform') == 'APPLE'
            $outputPageSize = "A4"
            $outputPageHeightMM = "297mm"
            $outputPageWidthMM = "210mm"
            $outputPageHeightPX = "1164px"
            $outputPageWidthPX = "827px"
            $outputPagePaddingLeftMM = "1mm"
            $outputPagePaddingRightMM = "10mm"
        end
        commonShowBenefitTable
        $showPdf = nil

        filehtml = ""
        if System.get_property('platform') == 'ANDROID'
            filehtml << "<!DOCTYPE html>"
            filehtml << "<html lang=\"en\">"
            filehtml << "<head>"
            filehtml << "<meta charset=\"utf-8\">"
            filehtml << "</head>"
            filehtml << "<body>"
        end

        $quotationIO.htmlContent.each do |htmlContent|
            if !htmlContent.empty?
                totalPages = htmlContent.size
                skipPageNumber=0;
                totalSkipNumber = 0;
                htmlContent.each_pair do |pageNumber, page|
                    if(page["content"].include? "$SKIPPAGENUMBER$")
                        totalSkipNumber = totalSkipNumber - 1;  
                    end
                end
                htmlContent.each_pair do |pageNumber, page|
                    content = page["content"]
                    if(page["content"].include? "$ZEROMARGIN$")
                        content.gsub!("$ZEROMARGIN$", "")
                        filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
                    else
                        filehtml  << "<div class=\"bodyDiv\">"
                    end
                    if(content.include? "$SKIPPAGENUMBER$")
                        skipPageNumber = skipPageNumber - 1
                        content.gsub!("$SKIPPAGENUMBER$", "")
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    else
                        content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
                        content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
                        if(pageNumber != totalPages)
                            content << "<pd4ml:page.break></div></div>"
                        else
                            content << "</div>"
                        end
                    end
                    filehtml << content
                end
            end
        end

        if System.get_property('platform') == 'ANDROID'
            filehtml << "</body>"
            filehtml << "</html>"
        end

        #Create output folder
        outputFolder = Rho::RhoFile.join(Rho::Application.userFolder, $quotationIO.baseDO.quotationRefNum.gsub('/',''))
        Rho::RhoFile.makeDir(outputFolder) unless Rho::RhoFile.exists(outputFolder)

        #Copy output resources
        data = filehtml.scan(/\/public\S*[js|css|jpg|png]/)
        if System.get_property('platform') == 'APPLE'
            data = data + [
                "/public/jazz/js/jquery.min.js",
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
        end
        data.each do |entry|
            newEntry = entry.gsub('"','')
            @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
            FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
        end
        FileUtils.copy_entry("#{Rho::RhoApplication.get_base_app_path()}/public/fonts", "#{outputFolder}#{File::SEPARATOR}fonts")

        #Remove relative paths
        filehtml.gsub!('/public/jquery/','')
        filehtml.gsub!('/public/js/RGraph/','')
        filehtml.gsub!('/public/js/','')
        if System.get_property('platform') == 'ANDROID'
            filehtml.gsub!('/public/images/SalesIllustration/',"#{outputFolder}/")
            filehtml.gsub!('/public/images/outputimages/',"#{outputFolder}/")
            filehtml.gsub!('</pd4ml:page.footer>','</pd4ml:page.footer><main_body>')
            filehtml.gsub!('</div><!--div class tabcontent end--><pd4ml:page.break></div></div>','</main_body></div><!--div class tabcontent end--><pd4ml:page.break></div></div>')
            # UI changes...ideally to be moved to section details
            filehtml.gsub!('height="40%"','')
            filehtml.gsub!('height="10%"','')
            # filehtml.gsub!('width="2%"','')
            filehtml.gsub!('<tr> <td> <b  style="font-size:10px;font-family:arial;color:#003946">','<tr width="30%"><td></td></tr><tr width="30%"> <td> <b  style="font-size:10px;font-family:arial;color:#003946">')
            filehtml.gsub!('<!-- Processing sectionDetailsDO with id 820101 -->','<!-- Processing sectionDetailsDO with id 820101 --><main_body>')
            filehtml.gsub!('font-size:14px;"><b>THIS','font-size:9px;"><b>THIS')
            filehtml.gsub!('<div style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;color:#003946;padding-top:10px;"> <b>Prepared by</b></div>','<p style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;color:#003946;padding-top:10px;"> <b>Prepared by</b></p>')
            filehtml.gsub!('<div style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;"> 1)&nbsp;&nbsp;&nbsp;&nbsp;Assumes using Premium Holiday feature after Commitment Period if the Investment Fund Value is still enough to pay mandatory charges by due date.</div>','<p style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;"> 1)&nbsp;&nbsp;&nbsp;&nbsp;Assumes using Premium Holiday feature after Commitment Period if the Investment Fund Value is still enough to pay mandatory charges by due date.</p>')
            filehtml.gsub!('style=" margin-bottom: 10px;"','')
            filehtml.gsub!('style="margin-bottom:10px"','')
        elsif System.get_property('platform') == 'APPLE'
            filehtml.gsub!('/public/images/SalesIllustration/','')
            filehtml.gsub!('/public/images/outputimages/','')
        end
        filehtml.gsub!('/public/css/','')
        filehtml.gsub!('/public/jazz/js/','')

        begin
            if System.get_property('platform') == 'ANDROID'
                #Generate HTML file
                htmlFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}.html")
                File.open(htmlFileName,'w') do |f|
                    f.puts filehtml
                end
            end

            pdfFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}.pdf")
            objects = Rho::Pdfgen.enumerate
            obj = objects[0]

            if System.get_property('platform') == 'ANDROID'
                # Android code
                res = obj.generateAndroidPDF(htmlFileName, "PORTRAIT", "YES", "")
            elsif System.get_property('platform') == 'APPLE'
                # iOS code
                individualPages = filehtml.split("<pd4ml:page.break>")
                listOfPdfs = ""
                individualPages.each_with_index do |page, index|
                    headerSplit = ""
                    if page.include?("<pd4ml:page.header>")
                        headerSplit = page[page.index("<pd4ml:page.header>")..page.index("</pd4ml:page.header>")+19]
                    end
                    footerSplit = ""
                    if page.include?("<pd4ml:page.footer>")
                        footerSplit = page[page.index("<pd4ml:page.footer>")..page.index("</pd4ml:page.footer>")+19]
                    end
                    mainSplit = page
                    if mainSplit.include?("<pd4ml:page.header>")
                        mainSplit = mainSplit.gsub(headerSplit,"")
                    end
                    if mainSplit.include?("<pd4ml:page.footer>")
                        mainSplit = mainSplit.gsub(footerSplit,"")
                    end
                    # mainSplit.gsub!("$(document).height()","$(document).height()*window.devicePixelRatio")
                    # mainSplit.gsub!("$(document).width()","$(document).width()*window.devicePixelRatio")
                    mainSplit.gsub!("$(document).ready","$(window).load")
                    mainSplit = headerSplit+mainSplit+footerSplit
                    mainSplit.gsub!("<pd4ml:page.footer>","<pd4ml:page.footer id='footer'>")


                    filehtml = ""
                    filehtml << "<!DOCTYPE html>"
                    filehtml << "<html lang=\"en\">"
                    filehtml << "<head>"
                    filehtml << "<meta charset=\"utf-8\">"
                    filehtml << "<script type=\"text/javascript\" src=\"jquery.min.js\"></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.bar.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.hbar.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.scatter.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.annotate.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.context.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.dynamic.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.effects.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.resizing.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.tooltips.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.zoom.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.circle.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.image.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker1.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker2.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.text.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.xaxis.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.yaxis.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.rect.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.line.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.core.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.pie.js\" ></script>"
                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.key.js\" ></script>"
                    filehtml << "</head>"
                    filehtml << "<body>"
                    filehtml << "<style type='text/css'>#footer{clear:both;position:absolute;}</style>"
                    filehtml << mainSplit
                    filehtml << "<script type=\"text/javascript\">$(window).load(function(){document.body.style.height='#{$outputPageHeightMM}';document.body.style.width='#{$outputPageWidthMM}';document.body.style.paddingLeft='#{$outputPagePaddingLeftMM}';document.body.style.paddingRight='#{$outputPagePaddingRightMM}';document.body.style.margin='0';var footer = document.getElementById('footer');
                    var height = footer.offsetHeight;
                    var style = getComputedStyle(footer);
                    height += parseInt(style.marginTop) + parseInt(style.marginBottom);
                    footer.style.top = (297-(height*25.4/72)-25)+'mm';});</script>"
                    filehtml << "<script type=\"text/javascript\">$(window).load(function(){$('.pisImg').css(\"width\", 827 +\"px\");$('.pisImg').css(\"height\", 1160 +\"px\");});</script>"
                    filehtml << "</body>"
                    filehtml << "</html>"

                    tempHTMLFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{index}.html")
                    tempPDFFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{index}.pdf")
                    File.open(tempHTMLFileName,'w') do |f|
                        f.puts(filehtml)
                    end
                    res = obj.generateIOSPDF(tempHTMLFileName, tempPDFFileName)
                    listOfPdfs += "#{tempPDFFileName}|"
                end
                userPassword = ""
                if $quotationIO.baseDO.QuotationPartyList.size > 0
                    primaryParty = $quotationIO.baseDO.getPartyByRole("PRIMARY")
                    if primaryParty
                        if primaryParty.lastname.to_s.size < 4
                            userPassword = primaryParty.lastname.to_s.upcase+primaryParty.age.to_s
                        else
                            userPassword = primaryParty.lastname.to_s[0..3].upcase+primaryParty.age.to_s
                        end
                    end
                end
                res = obj.mergeIOSPDF(listOfPdfs[0..-2], pdfFileName, userPassword)
            end
            Rho::System.openUrl(pdfFileName)
        rescue StandardError => se
            puts "exception: #{se}"
            Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
                :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
                :buttons=>["OK"]})
            WebView.navigate("/app/Quotation/{#{$quotationIO.baseDO.object}}/show")
        end

        redirect :action => :show, :id => $quotationIO.baseDO.object, :layout => :jazzLayout
    end
    ########################################################################################################


    def requiredQuickLinks(quotation)
        quickLinks = Hash.new
        if quotation.insuranceTypeCd.to_s != 'TRAVEL' && quotation.insuranceTypeCd.to_s != 'AUTO'
            quickLinks['premiumSummary'] = 'javascript: showSummaryPopup();'
            quickLinks['VIEWILLUSTRATION'] = '/app/Quotation/viewIllustration'
        end

        if quotation.fnaId.to_s != ""
            if quotation.fnaId.include?("|")
                fnaId = quotation.fnaId.split("|").first
                quickLinks[getLabelValue('FNA') + " " + fnaId] = url_for :controller => :FNARequest, :action=> :show, :query => { :fnaNum => fnaId}
            end
        else
            @policyholder = quotation.getPartyByRole("PROPOSER")
            @applicableMenus = AgentReg.getCurrentAgentReg.applicableMenus.split(",")
            if @applicableMenus.include?('FNA') && @applicableMenus.include?('SalesIllustrationTab') 
                if @policyholder && @policyholder.partyTypeCd = "INDIVIDUAL"
                    quickLinks["createFNA"] = url_for :controller => :FNARequest, :action=> :newFNA, :query => {:quotationId => quotation.object }
                    quickLinks["linkFNA"] = 'javascript: showLinkFNAPopup();'
                end
            end
        end

        policy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid }) if quotation.guid.to_s != ""
        quickLinks['viewPolicy'] = "#{url_for :controller => :Policy, :action => :showProposal, :id=> policy.object}" if policy

        quickLinkLabels = quickLinks.keys.join(",")
        quickLinkActions = quickLinks.values.join(",")

        return quickLinkLabels,quickLinkActions
    end
    ########################################################################################################

    def captureSignatureOnOutput(signatureTypeCd,quotation,signatureCount)
        @signatureTypeCd = signatureTypeCd
        @signatureCount = signatureCount
        @signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid}) 
        if @signatureContainer.to_s == ""
            @signatureContainer = SignatureContainer.new(:entityGuid => quotation.guid, :entityTypeCd => quotation.class.name.to_s)
            setObjectCount(@signatureContainer, signatureCount)
            setObjectMapping(@signatureContainer, @signatureContainer.class.name)
        end
        @signature = @signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == signatureTypeCd}.first if @signatureContainer
        if @signature.to_s == ""
            @signature = ServiceSignature.new(:signatureTypeCd => signatureTypeCd, :entityGuid => quotation.guid, :entityType => quotation.class.name.to_s)
            @signatureContainer.addServiceSignature(@signature)
        end
        html = ""
        html << render(:partial => 'captureSignatureOnOutput')
    end


    def syncProgress_Jazz
        render :action=>:syncProgress_Jazz, :layout => :jazzLayout
    end


    def premiumSummary(quotation, html)
        summaryPopupView = quotation.insuranceTypeCd != 'TRAVEL'
        riders = quotation.getRiders
        planColumn = false
        planColumn = true if riders.select { |key, rider| key.planCode.to_s != "" }.size > 0

        summaryResult = Array.new
        
        quotationProductList = quotation.QuotationProductList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
        quotationProductList.each do |quotation_product|
            next if quotation_product.removed.to_s != ''
            quotationProductSummary = Hash.new
            quotation_product.baseSumAssured = quotation_product.baseSumAssured.to_f if quotation_product.baseSumAssured.class.to_s == "BigDecimal"
            quotationProductSummary[:sum_assured] = getMaskedValue(quotation_product, "baseSumAssured")
            quotation_product.modalPremium = quotation_product.modalPremium.to_f if quotation_product.modalPremium.class.to_s == "BigDecimal"
            quotationProductSummary[:modal_premium] = getMaskedValue(quotation_product,"modalPremium")

            quotation_party = quotation.getParty(quotation_product)
            quotationProductSummary[:fullname] = quotation_party.getFullName.to_s.strip.upcase if quotation_party

            product_object = MobiSys::ProductUtil.getProduct(quotation_product.productSeq)
            if product_object
                quotationProductSummary[:product] = getLabelValue(product_object.longName.to_s.strip)

                product_object.OfflineFacetList.each do |offlineFacet|
                    if offlineFacet.facetId == 'PLANOPTION'
                        offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                            if offlinePlanOption.optionCd == quotation_product.productPlanOptionCd.to_s
                                quotationProductSummary[:plan] = getLabelValue(offlinePlanOption.description.to_s.strip)
                                planColumn = true
                            end
                        end
                    end
                end
            end
            summaryResult << quotationProductSummary
        end
        
        capture_output_preferences, capture_signature_on_quotataion, get_pdf_enabled, link_to_eapp_enabled    = getApplicationProperties
        companyFacet = MobiSys::BrowserHelper.renderPanel?("EAPPAPPLICABLE",MobiSys::ProductUtil.getProduct(quotation.getBaseProduct.productSeq))

        summaryButtons = Array.new

        quotationAccepted = false
        quotationAccepted = true if (($rhoconfig[:captureSignOnSIOutput] || quotation.signature.to_s != "") && quotation.signatureDt.to_s != "" && (quotation.quoteStatusCd == "ACCEPTED" || quotation.quoteStatusCd == "SYNCDONE"))
        quotationAccepted = true if quotation.quoteStatusCd == "COMPLETED" && quotation.insuranceTypeCd == "HEALTH"
        windowsPlatform = false
        windowsPlatform = true if System.get_property('platform') == 'WINDOWS_DESKTOP'
        if summaryPopupView
            if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                summaryButtons << "<a rel='external' href='#{url_for :action => :viewIllustration, :id=>quotation.object, :query => {:trigger_source => 'search'}}' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='icon-illustration'></i></span><span class='summary-btn-text'>#{getLabelValue('VIEWILLUSTRATION')}</span></a>"
            else
                summaryButtons << "<a rel='external' href='javascript: viewIllustration();' data-role='button' data-theme='a' ><span class= 'summary-btn-icon'><i class='icon-illustration'></i></span><span class='summary-btn-text'>#{getLabelValue('VIEWILLUSTRATION')}</span></a>"
            end

            if quotationAccepted
                if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                     summaryButtons << "<a rel='external' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'email',:trigger_source => 'search'}, :id=>quotation.object}' name='email' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='icon-mail'></i></span><span class='summary-btn-text'>#{getLabelValue('Email')}</span></a>"
                else
                    summaryButtons << "<a rel='external' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'email'}, :id=>quotation.object}' name='email' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='icon-mail'></i></span><span class='summary-btn-text'>#{getLabelValue('Email')}</span></a>"
                end

                if windowsPlatform
                    if quotation.quoteStatusCd != "PENDING" 
                        if capture_output_preferences =='YES'
                            summaryButtons << "<a rel='external' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'downloadPDF'}, :id=>quotation.object}' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class=' icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('DOWNLOADPDF')}</span></a>"
                        else
                            summaryButtons << "<a rel='external' href='#{url_for :action => :pdfCalculateIllustration1, :id=>quotation.object}' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class=' icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('DOWNLOADPDF')}</span></a>"
                        end
                    end
                else
                    if get_pdf_enabled == "YES"
                        if capture_output_preferences =='YES'
                            summaryButtons << "<a rel='external' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'get_pdf'}, :id=>quotation.object}' name='email' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='  icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('GETPDF')}</span></a>"
                        else
                            if $rhoconfig[:offlinePDFGeneration] && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'
                                summaryButtons << "<a rel='external' href='#{url_for :action => :offlinePDFCalculateIllustration1, :id=>quotation.object}' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='  icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('GETPDF')}</span></a>"
                            else
                                if $rhoconfig[:offlineOutputGeneration]
                                    summaryButtons << "<a rel='external' href='#{url_for :action => :outputCalculateIllustration1, :id=>quotation.object}' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='  icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('GETPDF')}</span></a>"
                                else
                                    summaryButtons << "<a rel='external' href='#{url_for :action => :get_pdf, :id=>quotation.object}' name='email' data-role='button' data-theme='a'><span class= 'summary-btn-icon'><i class='  icon-file-pdf'></i></span><span class='summary-btn-text'>#{getLabelValue('GETPDF')}</span></a>"
                                end
                            end
                        end
                    end
                end

                if companyFacet
                    if link_to_eapp_enabled == "YES"
                        x = "<a rel='external' href='#' onclick=\"location.href='"+"#{url_for :action => 'linkToEapp', :query =>{ :quotationId => quotation.object}}';\""+" name='new' data-role='button' data-theme='a'><span class='summary-btn-icon'><i class='icon-e-app'></i></span><span class='summary-btn-text'>#{getLabelValue('LINKTOEAPP')}</span></a>"
                        summaryButtons << x
                    end
                end
            else
                if quotation.quoteStatusCd.to_s == MobiSys::QuotationBO::COMPLETED && !$rhoconfig[:captureSignOnSIOutput]
                    if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                        summaryButtons << "<a rel='external' href='#{url_for :action => :acceptIllustration, :id=>quotation.object}' name='sign' data-role='button' data-theme='a'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    else
                        summaryButtons << "<a rel='external' href='javascript: acceptIllustration();' name='sign' data-role='button' data-theme='a'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    end
                end
            end
        else
            summaryButtons << "<a href='#' class='summaryTabView' id='saveAndPrevButton' data-transition='slide'>#{getLabelValue('Previous')}</a>"

            if quotationAccepted
                summaryButtons << "<a rel='external' class='summaryTabView' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'email'}, :id=>quotation.object}' name='email'>#{getLabelValue('Email')}</a>"

                if companyFacet
                    if link_to_eapp_enabled == "YES"
                        x = "<a rel='external' class='summaryTabView' href='#' onclick=\"location.href='"+"#{url_for :action => 'linkToEapp', :query =>{ :quotationId => quotation.object}}';\""+" name='new'>#{getLabelValue('LINKTOEAPP')}</a>"
                        summaryButtons << x
                    end
                end
            else
                if quotation.quoteStatusCd.to_s == MobiSys::QuotationBO::COMPLETED
                    if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                        summaryButtons << "<a class='summaryTabView' rel='external' href='#{url_for :action => :acceptIllustration, :id=>quotation.object}' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    else
                        summaryButtons << "<a rel='external' class='summaryTabView' href='javascript: acceptIllustration();' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    end
                end
            end
        end
        # code for output preferences ends
        html << render(:partial => 'SummaryPopup_Jazz', :locals => { :summaryResult => summaryResult,:summaryButtons => summaryButtons,:planColumn => planColumn, :summaryPopupView => summaryPopupView})
        return html 
    end


    def travelPremiumComputation(quotation)
        premiumMatrix = {}
        if @offlineApplicationEnvironment == 'PRODUCTION'
            @productIdHash.each do |key, productDetails|
                productDetails.each do |each_product|
                    planList = @productPlanOptionHash[each_product[:id].to_s.to_sym]
                    if planList
                        planList.each do |plan|
                            clonedQuotation = quotation.cloneObject
                            quotePartyList = clonedQuotation.QuotationPartyList
                            msg = ""
                            errors = Hash.new
                            if clonedQuotation.getBaseProduct.nil?
                                qp = QuotationProduct.new
                                qp.productTypeCd = 'PLAN'
                                clonedQuotation.addQuotationProduct(qp)
                            else
                                qp = clonedQuotation.getBaseProduct
                            end
                            qp.productId = each_product[:key]
                            qp.productSeq = each_product[:id]
                            qp.productFamilyCd = key
                            qp.productPlanOptionCd = plan[:key]
                            qp.premiumPayingTerm = 1
                            qp.paymentTypeCd = "SINGLE"
                            qp.paymentFrequencyCd = "SINGLE"
                            if quotation.startDt.to_s != '' && quotation.endDt.to_s != ''
                                startDt = Date.strptime(getScreenDate(quotation.startDt.to_s), "%d/%m/%Y")
                                endDt = Date.strptime(getScreenDate(quotation.endDt.to_s), "%d/%m/%Y")
                                qp.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
                            end
                            $taskExceptionHash = []
                            MobiSys::ProductBO.validateProduct(clonedQuotation, qp, quotePartyList, msg, errors)
                            $taskExceptionHash = nil
                            baseProduct = clonedQuotation.getBaseProduct
                            premiumMatrix[each_product[:id].to_sym] = Hash.new if !premiumMatrix[each_product[:id].to_sym].is_a?(Hash)
                            premiumMatrix[each_product[:id].to_sym][plan[:key].to_sym] = [baseProduct.baseSumAssured, plan[:SA] ]
                        end
                    end
                end
            end
        else
            @productIdHash.each do |key, productDetails|
                @productIdHash.each do |key, productDetails|
                productDetails.each do |each_product|
                    planList = @productPlanOptionHash[each_product[:id].to_s.to_sym]
                    if planList
                        planList.each do |plan|
                            clonedQuotation = quotation.cloneObject
                            quotePartyList = clonedQuotation.QuotationPartyList
                            msg = ""
                            errors = Hash.new
                            if clonedQuotation.getBaseProduct.nil?
                                qp = QuotationProduct.new
                                qp.productTypeCd = 'PLAN'
                                clonedQuotation.addQuotationProduct(qp)
                            else
                                qp = clonedQuotation.getBaseProduct
                            end
                            qp.productId = each_product[:key]
                            qp.productSeq = each_product[:id]
                            qp.productFamilyCd = key
                            qp.productPlanOptionCd = plan[:key]
                            qp.premiumPayingTerm = 1
                            qp.paymentTypeCd = "SINGLE"
                            qp.paymentFrequencyCd = "SINGLE"
                            if quotation.startDt.to_s != '' && quotation.endDt.to_s != ''
                                startDt = Date.strptime(getScreenDate(quotation.startDt.to_s), "%d/%m/%Y")
                                endDt = Date.strptime(getScreenDate(quotation.endDt.to_s), "%d/%m/%Y")
                                qp.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
                            end
                            $taskExceptionHash = []
                            MobiSys::ProductBO.validateProduct(clonedQuotation, qp, quotePartyList, msg, errors)
                            $taskExceptionHash = nil
                            baseProduct = clonedQuotation.getBaseProduct
                            premiumMatrix[each_product[:id].to_sym] = Hash.new if !premiumMatrix[each_product[:id].to_sym].is_a?(Hash)
                            premiumMatrix[each_product[:id].to_sym][plan[:key].to_sym] = [baseProduct.baseSumAssured, plan[:SA] ]
                        end
                    end
                end
            end
            end
        end
        return premiumMatrix
    end


    def getApplicationProperties
        capture_output_preferences = $rhoconfig[:capture_output_preferences]
        capture_signature_on_quotataion = $rhoconfig[:capture_signature_on_quotataion]
        get_pdf_enabled = $rhoconfig[:get_pdf_enabled]
        link_to_eapp_enabled = $rhoconfig[:link_to_eapp_enabled]
        $currencyFormat = $rhoconfig[:number_format_pattern]
        return capture_output_preferences, capture_signature_on_quotataion, get_pdf_enabled, link_to_eapp_enabled
    end


    def captureLife
        if @tabName.to_s != ""
            if @tabName.split(",").first == "tab_selProduct"
                @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)
            elsif @tabName.split(",").first == "tab_basic"
                @partyGuidMapping = nil
                agentRegdetails = AgentReg.getCurrentAgentReg
                @quotation = setAgentDetails(@quotation, agentRegdetails)
                @quotation.currentLayout = "newcaptureIllustration"
                @quotation.quotationDt = getScreenDate(Time.now.to_s)
                #to set agent location in branch name field(quotAddtnlField2)
                @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails

                @quotation.isAgeEditableFl = nil
                isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
                if isAgeEditableFl.to_s != ''
                    @quotation.isAgeEditableFl = isAgeEditableFl
                end

                renderInsuredPanel = MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct)
                @quotation.proposerLASame = 'YES' if !renderInsuredPanel && $currentProduct

                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)

                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@policyHolder)

                setLeadRPQFNADetails

                @jointLife = QuotationParty.new(:roleCd => "JOINT",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@jointLife)

                @baseProduct = QuotationProduct.new
                @baseProduct = setBaseProductDetails(@baseProduct, $currentProduct, @params, @quotation)
                @quotation.addQuotationProduct(@baseProduct)
            end
        end

        if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
            @quotation.QuotationPartyList.each do |quotationParty|
                if quotationParty.dob.to_s != ""
                    quotationParty.age = MobiSys::ProductBO.calculateAge(@quotation, @quotation.getBaseProduct, quotationParty, nil).split("|")[0].to_i
                end
            end
        end
    end


    def showLife
        if @params['sym_current_Tab'].to_s == "" && $currentProduct
            @params['sym_current_Tab'] = "tab_basic"
        end

        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_selProduct") || @params['sym_current_Tab'].to_s == "tab_selProduct"
            @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)

            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && @productFamilyHash.empty?
                Alert.show_popup({
                    :message => getLabelValue('ERR_NOLAUNCHEDPRD'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })

                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @quotation.object)
                return false
            end
        end
        # @quotation.quotationDt = getScreenDate(@quotation.quotationDt) if @quotation.quotationDt.to_s != ""

        # Basic Tab
        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_basic") || @params['sym_current_Tab'].to_s == "tab_basic"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if ($prdSelectionFacet==nil || MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s == "") && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            agentRegdetails = AgentReg.getCurrentAgentReg
            @quotation = setAgentDetails(@quotation, agentRegdetails)
            @quotation.currentLayout = "newcaptureIllustration"
            @quotation.quotationDt = getScreenDate(Time.now.to_s) if @quotation.quotationDt.to_s == ""
            #to set agent location in branch name field(quotAddtnlField2)
            @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
            unless @policyHolder
                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@policyHolder)
            end

            @jointLife = MobiSys::QuotationBO.getJointLife(@quotation)
            if !@jointLife
                @jointLife = QuotationParty.new(:roleCd => "JOINT")
                @quotation.addQuotationParty(@jointLife)
            end
        end


        # Supplementary Tab
        if @params['sym_current_Tab'].to_s =="tab_supplementary"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })

                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            getSupplementaryDetails
        end


        # @quotation.QuotationPartyList.each do |quotationParty|
        #     quotationParty.dob = getScreenDate(quotationParty.dob) if quotationParty.dob.to_s != ""
        # end
        @quotation.isAgeEditableFl = nil
        isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
        if isAgeEditableFl.to_s != ''
            @quotation.isAgeEditableFl = isAgeEditableFl
        end
        @partialProducts = MobiSys::QuotationBO.getPartialProducts(@quotation)
        renderInsuredPanel = MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct)
        @quotation.proposerLASame = "YES" if @quotation.proposerLASame == "COPYFROMINSURED" && (($currentProduct && !renderInsuredPanel) || ($currentProduct && renderInsuredPanel) || !$currentProduct)


        # Plan Tab
        if @params['sym_current_Tab'].to_s =="tab_plan"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            #to set flag for enabling & disabling div based on the product
            $premiumSAFl = ''
            $multiplierFacet = ''
            $premiumPayingTerm = true

            $currentProduct.OfflineFacetList.each do |offlineFacet|
                if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
                    $premiumPayingTerm = false
                    @quotation.pptCalcBasis = 'YES'
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

            # QuotationProductExtra Section
            @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
            @quotationProductExtras, @baseProduct = MobiSys::QuotationBO.computeProductExtra(@quotation, @baseProduct)

            # TopUp Section
            @regularTopup = MobiSys::QuotationBO.getRegularTopup(@quotation)
            @initialTopup = MobiSys::QuotationBO.getInitialTopup(@quotation)
            @adhocTopupLabelObject = QuotationTopUp.new(:topUpTypeCd => "ADHOCTOPUP",:removed=>"YES")
            @adHocTopups = MobiSys::QuotationBO.getAdHocTopup(@quotation)
            @transferTopupLabelObject = QuotationTopUp.new(:topUpTypeCd => "TRANSFERTOPUP",:removed=>"YES")
            @contributionTopups = MobiSys::QuotationBO.getContributionTopup(@quotation)
            @topupCount = 52+@adHocTopups.size+@contributionTopups.size

            # Funds section
            @fundLabelObject = QuotationProductInvestmentFund.new(:removed=>"YES")
            prePopulateFunds(@quotation, @baseProduct)
            @funds = @baseProduct.QuotationProductInvestmentFundList
            @fundCount = 250
            fundRequiredDetailsDT = $currentProduct.getFacetValue("FUNDSREQUIRED")
            @modelArray = getPortfolioModelCd($currentProduct, @quotation, @baseProduct) if fundRequiredDetailsDT == 'YES'

            @showSearchFl = false
            if @baseProduct.portfolioModelCd.to_s != ""
                model = Model.find(:first, :conditions=>{{:name => 'modelCd'} => @baseProduct.portfolioModelCd})
                @showSearchFl = (model.modelTypeCd == 'FIXEDMODELOVERRIDE' || model.modelTypeCd == 'FIXEDMODEL')  ? true : false
                @modelFundType = model.modelTypeCd
            end

            # Withdrawal section
            @withdrawalLabelObject = QuotationWithdrawal.new(:removed=>"YES")
            @withdraws = @quotation.QuotationWithdrawalList
            @withdrawalCount = 0
        end

        # Rider Tab
        if @params['sym_current_Tab'].to_s =="tab_rider"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })

                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @riders = MobiSys::QuotationBO.getRiders(@quotation)
            
            @riderObjects = 100
            if @quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE'
                loadRiderProducts(@quotation, $currentProduct, false)
            else
                loadRiderProducts(@quotation, $currentProduct)
            end
        end

        if @quotation.fnaId.to_s == "" && @baseProduct && @baseProduct.productId.to_s != ""
            @policyholder_details = @quotation.getPartyByRole("PROPOSER")
            if @baseProduct.productPlanOptionCd.to_s != ""
                linkedProduct = FNASIProductLink.find(:first, :conditions => { :optionCd  => @baseProduct.productPlanOptionCd })
            else
                linkedProduct = FNASIProductLink.find(:first, :conditions => { :siProductId => @baseProduct.productId })
            end
            if linkedProduct
                product = FNAProduct.find(:first, :conditions => { :productId => linkedProduct.fnaProductId})
                fnaRequestList = FNARequest.loadObject(:all, :conditions => { :statusCd => "FNAPENDING"})
                
                @fnaRequestListFiltered = []
                fnaRequestList.each do |fnaRequest|
                    @fnaParty = fnaRequest.getParty("PROPOSER")
                    if @fnaParty.lastName1.to_s == @policyholder_details.lastname.to_s && @fnaParty.firstName1.to_s == @policyholder_details.firstname.to_s
                        fnaRequest.FNAIOSelectedList.each do |fnaIOSelected|
                            if fnaIOSelected.quotationId.to_s == "" && fnaIOSelected.selectedFlag.to_s == "on" && fnaIOSelected.fnaRiderProductRefGuid.to_s == "" && fnaIOSelected.fnaBaseProductRefGuid.to_s == product.id.to_s
                                fnaRequest.witnessId = fnaIOSelected.guid
                                fnaRequest.addtnField3Str = product.longName
                                @fnaRequestListFiltered << fnaRequest
                            end
                        end
                    else
                        next
                    end
                end
            end
        end

        @quotation.quotationDt = getScreenDate(@quotation.quotationDt.to_s) if @quotation.quotationDt.to_s != ""

        @quotation.QuotationPartyList.each do |quotationParty|
            quotationParty.dob = getScreenDate(quotationParty.dob.to_s) if quotationParty.dob.to_s != ""
        end

        return true
    end


    def executeLife
        if @params['mode'] == "copy"
           ### copying existing quotation to create new one 
           # loding source quotation  
           @sourceQuotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['sourceQuotationId']})
           # getting quotation from screen   
           targetToBeQuotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['Quotation'])    
           # merging quotation from screen with source quotation to get copied quotation      
           copiedQuotation = copyQuotation(@sourceQuotation,targetToBeQuotation,false)    
           copiedQuotation.persistAll   
            if @params.has_key?("selectProductVersion")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductVersion'])
            elsif @params.has_key?("selectProductId")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductId'])
            end 
            baseProduct = targetToBeQuotation.getBaseProduct 
            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(targetToBeQuotation)
                    if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                        $currentProduct = nil
                        changePlan(targetToBeQuotation, @params)
                        targetToBeQuotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['Quotation']['object']})
                        baseProduct =  targetToBeQuotation.getBaseProduct
                        targetToBeQuotation.visitedTabs  = @params['currentTab']
                    end
                end
            end
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end 
            executeQuotation = targetToBeQuotation

        elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_selProduct"
            if (@params.has_key?("selectProductVersion") && @params["selectProductVersion"].to_s == "") || (@params.has_key?("selectProductId") && @params["selectProductId"].to_s == "") || (@params.has_key?("selectProductPlan") && @params["selectProductPlan"].to_s == "") || !@params.has_key?("selectProductId")
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    if @params['sym_current_Tab'] == "tab_basic"
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @params['Quotation']['object'])
                    else
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @params['Quotation']['object'])
                    end
                else
                    WebView.navigate(url_for :action => :newCaptureIllustration)
                end
                return
            end
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            if @params.has_key?("selectProductVersion")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductVersion'])
            elsif @params.has_key?("selectProductId")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductId'])
            end
            
            baseProduct = quotation.getBaseProduct
            # Reset Base Plan hierarchy upon product change
            if baseProduct && $currentProduct && ((baseProduct.productSeq.to_s != $currentProduct.id.to_s && baseProduct.productSeq.to_s != "") || (@params.has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['selectProductPlan'] && baseProduct.productPlanOptionCd.to_s != ""))
                
                changePlan(quotation, @params)

                quotation.visitedTabs = @params['currentTab']
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    quotation.visitedTabs = quotation.visitedTabs.to_s + ",tab_basic"
                    end

                if baseProduct.nil? && $currentProduct
                    baseProduct = QuotationProduct.new
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                    quotation.addQuotationProduct(baseProduct)
                elsif baseProduct.productSeq.to_s == "" && $currentProduct
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                elsif baseProduct.productSeq.to_s == ""
                    baseProduct.product = Product.new
                end
            end

            if baseProduct.nil?
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct.productSeq.to_s == ""
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            end
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            executeQuotation = quotation
            if $currentProduct && @params["sym_current_Tab"] == 'tab_plan' && MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                @params["sym_current_Tab"] = 'tab_supplementary'
            elsif $currentProduct && @params["sym_current_Tab"] == 'tab_supplementary' && !MobiSys::BrowserHelper.renderPanel?('SUPPLEMENTARYINSUREDREQUIRED', $currentProduct)
                @params["sym_current_Tab"] = 'tab_plan'
            end
        else
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            baseProduct = quotation.getBaseProduct

            # Reset Base Plan hierarchy if selected product is not applicable anymore base on filtering creteria
            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(quotation)
                    if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                        $currentProduct = nil
                        changePlan(quotation, @params)
                        quotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['Quotation']['object']})
                        baseProduct = quotation.getBaseProduct
                        quotation.visitedTabs = @params['currentTab']
                    end
                end
            end
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end
            executeQuotation = quotation
        end
        #File reset over here
        if $rhoconfig[:setPolicyModelLog] == 1
            fileName = quotation.quotationRefNum.to_s+"_Quotation_Logs.txt"
            Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
            downloadFolder = Rho::RhoApplication.get_blob_folder
            filePath = File.join(downloadFolder, fileName)
            if File::exist? filePath
                File.open(filePath, 'w') { |file| file.puts "" }
            end
        end

        if executeQuotation.proposerLASame == 'YES' || executeQuotation.proposerLASame == "COPYFROMINSURED"
            executeQuotation.proposerLASame = "COPYFROMINSURED"
        else
            executeQuotation.proposerLASame = "NO"
        end
        executeQuotation.QuotationPartyList.each do |quotationParty|
            if  quotationParty.visitedTabs.to_s == ""
                quotationParty.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationParty.roleCd)
            end
        end
        executeQuotation.QuotationProductList.each do|quotationProduct|
            if quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs =  MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
            end
        end

        return executeQuotation
    end


    def getSupplementaryDetails
        @supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)
        @supplementLifeCount = 500
        @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
        if @supplementaryProductFacet
            supQuotationProducts = @quotation.getQuotationProductByProductTypeCd('PLANMULTI')
            @supQuotProductHM = {}
            @supQuotProductExtraHM = {}
            supQuotationProducts.each do |qp|
                @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
                quotationProductExtras, qp = MobiSys::QuotationBO.computeProductExtra(@quotation, qp)
                @supQuotProductHM[qp.insuredPartyRefGuid] = qp
                @supQuotProductExtraHM[qp.guid] = quotationProductExtras
            end
            @supQuotationProductCount = 200
        end
    end


    def captureAuto
        $globalFacetHash = nil
        $productMaster = nil # clearing product master hash created at product selection page
        MobiSys::ProductUtil.resetCache
        addUserActivityHelper('NEWILLUSTRATION', @params, 'QUOTATION')

        @quotation = Quotation.new
        @quotation.insuranceTypeCd = @params['insuranceTypeCd'] if @params['insuranceTypeCd'].to_s != ''
        @tabName, @tabLabel, @tabIcons = requiredTabs

        @quotation.quotationDt = getScreenDate(Time.now.to_s)

        @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
        @quotation.addQuotationParty(@insured)

        @policyHolder = QuotationParty.new(:roleCd => "PROPOSER",:partyTypeCd => "INDIVIDUAL")
        @quotation.addQuotationParty(@policyHolder)

        setLeadRPQFNADetails

        @baseProduct = QuotationProduct.new
        @baseProduct = setBaseProductDetails(@baseProduct, $currentProduct, @params, @quotation)
        @quotation.addQuotationProduct(@baseProduct)

        @supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)
        @supplementLifeCount = 5
        if $currentProduct
            @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
            if @supplementaryProductFacet
                supQuotationProducts = @quotation.getQuotationProductByProductTypeCd('PLANMULTI')
                @supQuotProductHM = {}
                supQuotationProducts.each do |qp|
                    @supQuotProductHM[qp.insuredPartyRefGuid] = qp
                end
                @supQuotationProductCount = 200
            end
        end

        @quotationQuestionContainer = QuestionContainer.new(
            :additionalFieldQuest => 'FORMBASED',
            :policyGuid => @quotation.uniqueKey
        )
        @quotationResponseHash = MobiSys::UIHelper.setupResponseHashForTag(@quotationQuestionContainer)        
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
        @visitedTabs = @quotation.visitedTabs.to_s
        
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@quotation)

        render :action => :QuoteCaptureAuto_Jazz, :layout => :jazzLayout
    end


    def showAuto
        if @params['sym_current_Tab'].to_s == "" && $currentProduct
            @params['sym_current_Tab'] = "tab_basic"
        end
        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_selProduct") || @params['sym_current_Tab'].to_s == "tab_selProduct"
            @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && @productFamilyHash.empty?
                Alert.show_popup({
                    :message => getLabelValue('ERR_NOLAUNCHEDPRD'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @quotation.object)
                return false
            end
            @premiumMatrix = {}
        end
        @quotation.quotationDt = getScreenDate(@quotation.quotationDt) if @quotation.quotationDt.to_s != ""

        # Basic Tab
        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_basic") || @params['sym_current_Tab'].to_s == "tab_basic"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if ($prdSelectionFacet==nil || MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s == "") && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            agentRegdetails = AgentReg.getCurrentAgentReg
            @quotation = setAgentDetails(@quotation, agentRegdetails)
            @quotation.currentLayout = "newcaptureIllustration"
            @quotation.quotationDt = getScreenDate(Time.now.to_s) if @quotation.quotationDt.to_s == ""
            #to set agent location in branch name field(quotAddtnlField2)
            @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails

            @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
            unless @policyHolder
                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER")
                @quotation.addQuotationParty(@policyHolder)
            end

            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            @supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)
            @supplementLifeCount = 5

            @quotation.QuotationPartyList.each do |quotationParty|
                quotationParty.dob = getScreenDate(quotationParty.dob) if quotationParty.dob.to_s != ""
                quotationParty.partySameAsCd = 'YES' if quotationParty.partySameAsCd.to_s == 'PROPOSER'
            end
            @quotation.isAgeEditableFl = nil
            isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
            if isAgeEditableFl.to_s != ''
                @quotation.isAgeEditableFl = isAgeEditableFl
            end
            @partialProducts = MobiSys::QuotationBO.getPartialProducts(@quotation)
        end

        # Rider Tab
        if @params['sym_current_Tab'].to_s == "tab_rider"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @riders = MobiSys::QuotationBO.getRiders(@quotation)
            
            @riderObjects = 100
            if @quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE'
                loadRiderProducts(@quotation, $currentProduct, false)
            else
                loadRiderProducts(@quotation, $currentProduct)
            end
        end

        # Premium summary Tab
        if @params['sym_current_Tab'].to_s == "tab_premiumSummary"
            @summaryTable = Array.new
            @summaryButtons = Array.new
            @totalModalPremium = 0.0
            @quotation.QuotationProductList.each do |quotation_product|
                next if quotation_product.removed.to_s != ''
                quotationProductSummary = Hash.new
                quotationProductSummary[:sum_assured] = getMaskedValue(quotation_product, "baseSumAssured")
                quotationProductSummary[:modal_premium] = getMaskedValue(quotation_product,"modalPremium")
                @totalModalPremium += quotation_product.modalPremium.to_f
                product_object = MobiSys::ProductUtil.getProduct(quotation_product.productSeq)
                if product_object
                    quotationProductSummary[:product] = getLabelValue(product_object.longName.to_s.strip)
                    product_object.OfflineFacetList.each do |offlineFacet|
                        if offlineFacet.facetId == 'PLANOPTION'
                            offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                                if offlinePlanOption.optionCd == quotation_product.productPlanOptionCd.to_s
                                    quotationProductSummary[:plan] = getLabelValue(offlinePlanOption.description.to_s.strip)
                                end
                            end
                        end
                    end
                end
                @summaryTable << quotationProductSummary
            end
            @totalModalPremium = maskDecimal(@totalModalPremium,"###,###,###.##")
            quotationAccepted = false
            quotationAccepted = true if (($rhoconfig[:captureSignOnSIOutput] || @quotation.signature.to_s != "") && @quotation.signatureDt.to_s != "" && (@quotation.quoteStatusCd == "ACCEPTED" || @quotation.quoteStatusCd == "SYNCDONE"))
            companyFacet = MobiSys::BrowserHelper.renderPanel?("EAPPAPPLICABLE",MobiSys::ProductUtil.getProduct(@quotation.getBaseProduct.productSeq))

            capture_output_preferences, capture_signature_on_quotataion, get_pdf_enabled, link_to_eapp_enabled = getApplicationProperties

            @summaryButtons << "<a href='#' class='summaryTabView' id='saveAndPrevButton' data-transition='slide'>#{getLabelValue('Previous')}</a>"

            if quotationAccepted
                @summaryButtons << "<a rel='external' class='summaryTabView' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'email'}, :id=>@quotation.object}' name='email'>#{getLabelValue('Email')}</a>"

                if companyFacet
                    if link_to_eapp_enabled == "YES"
                        x = "<a rel='external' class='summaryTabView' href='#' onclick=\"location.href='"+"#{url_for :action => 'linkToEapp', :query =>{ :quotationId => @quotation.object}}';\""+" name='new'>#{getLabelValue('LINKTOEAPP')}</a>"
                        @summaryButtons << x
                    end
                end
            else
                if @quotation.quoteStatusCd.to_s == MobiSys::QuotationBO::COMPLETED
                    if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                        @summaryButtons << "<a class='summaryTabView' rel='external' href='#{url_for :action => :acceptIllustration, :id=>@quotation.object}' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    else
                        @summaryButtons << "<a rel='external' class='summaryTabView' href='javascript: acceptIllustration();' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    end
                end
            end
        end

        @quotationQuestionContainer = QuestionContainer.loadObject(
            :first, 
            :conditions=>{
                {:name=>'additionalFieldQuest'} => 'FORMBASED',
                {:name=>'policyGuid'} => @quotation.uniqueKey
            },
            :op => 'AND'
        )
        @quotationResponseHash = MobiSys::UIHelper.setupResponseHashForTag(@quotationQuestionContainer)
        return true
    end


    def executeAuto
        if @params['mode'] == "copy"
           ### copying existing quotation to create new one 
           # loding source quotation  
           @sourceQuotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['sourceQuotationId']})
           # getting quotation from screen   
           targetToBeQuotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['Quotation'])    
           # merging quotation from screen with source quotation to get copied quotation      
           copiedQuotation = copyQuotation(@sourceQuotation,targetToBeQuotation,false)    
           copiedQuotation.persistAll   
           executeQuotation = copiedQuotation
        elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_selProduct"
            if (@params.has_key?("selectProductVersion") && @params["selectProductVersion"].to_s == "") || (@params.has_key?("selectProductId") && @params["selectProductId"].to_s == "") || (@params.has_key?("selectProductPlan") && @params["selectProductPlan"].to_s == "") || !@params.has_key?("selectProductId")
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    if @params['sym_current_Tab'] == "tab_basic"
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @params['Quotation']['object'])
                    else
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @params['Quotation']['object'])
                    end
                else
                    WebView.navigate(url_for :action => :newCaptureIllustration)
                end
                return
            end
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            if @params.has_key?('QuestionContainer')
                quotationQuestionContainer = MobiSys::BrowserHelper.convertToObjectWithMerge('QuestionContainer', @params['QuestionContainer'])
                quotationQuestionContainer.persistAll
            end
            if @params.has_key?("selectProductVersion")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductVersion'])
            elsif @params.has_key?("selectProductId")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductId'])
            end
            
            baseProduct = quotation.getBaseProduct
            # Reset Base Plan hierarchy upon product change
            if baseProduct && $currentProduct && ((baseProduct.productSeq.to_s != $currentProduct.id.to_s && baseProduct.productSeq.to_s != "") || (@params.has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['selectProductPlan'] && baseProduct.productPlanOptionCd.to_s != ""))
                
                changePlan(quotation, @params)

                quotation.visitedTabs = @params['currentTab']
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    quotation.visitedTabs = quotation.visitedTabs.to_s + ",tab_basic"
                end

                if baseProduct.nil? && $currentProduct
                    baseProduct = QuotationProduct.new
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                    quotation.addQuotationProduct(baseProduct)
                elsif baseProduct.productSeq.to_s == "" && $currentProduct
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                elsif baseProduct.productSeq.to_s == ""
                    baseProduct.product = Product.new
                end
            end

            if baseProduct.nil?
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct.productSeq.to_s == ""
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            end
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            executeQuotation = quotation
        else
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            if @params.has_key?('QuestionContainer')
                quotationQuestionContainer = MobiSys::BrowserHelper.convertToObjectWithMerge('QuestionContainer', @params['QuestionContainer'])
                quotationQuestionContainer.persistAll
            end
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            baseProduct = quotation.getBaseProduct

            # Reset Base Plan hierarchy if selected product is not applicable anymore base on filtering creteria
            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(quotation)
                    if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                        $currentProduct = nil
                        changePlan(quotation, @params)
                        quotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['Quotation']['object']})
                        baseProduct = quotation.getBaseProduct
                        quotation.visitedTabs = @params['currentTab']
                    end
                end
            end
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end
            policyHolder = MobiSys::QuotationBO.getPolicyHolder(quotation)
            quotation.QuotationPartyList.each do |qp|
                if qp.partySameAsCd == 'YES'
                    qp.refGuid = policyHolder.guid
                    qp = copyPartyFields(qp,policyHolder)
                end
            end
            quotation.QuotationPartyList.each do |quotationParty|
                quotationParty.partySameAsCd = 'PROPOSER' if quotationParty.partySameAsCd.to_s == 'YES'
            end
            executeQuotation = quotation
        end
        return executeQuotation
    end


    def captureTravel
        if @tabName.to_s != ""
            if @tabName.split(",").first == "tab_selProduct"
                @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)
            elsif @tabName.split(",").first == "tab_basic"
                @partyGuidMapping = nil
                agentRegdetails = AgentReg.getCurrentAgentReg
                @quotation = setAgentDetails(@quotation, agentRegdetails)
                @quotation.currentLayout = "newcaptureIllustration"
                @quotation.quotationDt = getScreenDate(Time.now.to_s)
                #to set agent location in branch name field(quotAddtnlField2)
                @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails

                @quotation.isAgeEditableFl = nil
                isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
                if isAgeEditableFl.to_s != ''
                    @quotation.isAgeEditableFl = isAgeEditableFl
                end

                @quotation.proposerLASame = 'COPYFROMINSURED'

                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)

                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@policyHolder)

                setLeadRPQFNADetails

                @baseProduct = QuotationProduct.new
                @baseProduct = setBaseProductDetails(@baseProduct, $currentProduct, @params, @quotation)
                @quotation.addQuotationProduct(@baseProduct)
            end
        end

        if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
            @quotation.QuotationPartyList.each do |quotationParty|
                if quotationParty.dob.to_s != ""
                    quotationParty.age = MobiSys::ProductBO.calculateAge(@quotation, @quotation.getBaseProduct, quotationParty, nil).split("|")[0].to_i
                end
            end
        end    
    end


    def showTravel
        if @params['sym_current_Tab'].to_s == "" && $currentProduct
            @params['sym_current_Tab'] = "tab_basic"
        end

        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_selProduct") || @params['sym_current_Tab'].to_s == "tab_selProduct"
            @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)

            @premiumMatrix = travelPremiumComputation(@quotation)

            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && @productFamilyHash.empty?
                Alert.show_popup({
                    :message => getLabelValue('ERR_NOLAUNCHEDPRD'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @quotation.object)
                return false
            end
        end
        @quotation.quotationDt = getScreenDate(@quotation.quotationDt) if @quotation.quotationDt.to_s != ""

        # Basic Tab
        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_basic") || @params['sym_current_Tab'].to_s == "tab_basic"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if ($prdSelectionFacet==nil || MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s == "") && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            agentRegdetails = AgentReg.getCurrentAgentReg
            @quotation = setAgentDetails(@quotation, agentRegdetails)
            @quotation.currentLayout = "newcaptureIllustration"
            @quotation.quotationDt = getScreenDate(Time.now.to_s) if @quotation.quotationDt.to_s == ""
            #to set agent location in branch name field(quotAddtnlField2)
            @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
            unless @policyHolder
                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER")
                @quotation.addQuotationParty(@policyHolder)
            end

            @quotation.startDt = getScreenDate(@quotation.startDt.to_s)
            @quotation.endDt = getScreenDate(@quotation.endDt.to_s)
            if @quotation.startDt.to_s != '' && @quotation.endDt.to_s != ''
                startDt = Date.strptime(@quotation.startDt, "%d/%m/%Y")
                endDt = Date.strptime(@quotation.endDt, "%d/%m/%Y")
                @quotation.getBaseProduct.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
            end
        end

        # Plan Tab
        if @params['sym_current_Tab'].to_s =="tab_plan"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            #to set flag for enabling & disabling div based on the product
            $premiumSAFl = ''
            $multiplierFacet = ''
            $premiumPayingTerm = true

            $currentProduct.OfflineFacetList.each do |offlineFacet|
                if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
                    $premiumPayingTerm = false
                    @quotation.pptCalcBasis = 'YES'
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
        end

        # Rider Tab
        if @params['sym_current_Tab'].to_s =="tab_rider"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @riders = MobiSys::QuotationBO.getRiders(@quotation)
            
            @riderObjects = 100
            if @quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE'
                loadRiderProducts(@quotation, $currentProduct, false)
            else
                loadRiderProducts(@quotation, $currentProduct)
            end
            # @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
            # puts "$displayRidersHM['SAMEAS'].values:#{$displayRidersHM['SAMEAS'].values}"
            # @ridersHM = $displayRidersHM['SAMEAS'].values  
            # if !@dbRiders.empty?
            #     @dbRiders.each do |dbRiders|
            #         @ridersHM.each do |riders|
            #             if dbRiders.productId == riders.productId 
            #                 @riders.push(dbRiders)
            #             else
            #                 @riders.push(riders)
            #             end
            #         end
            #     end
            #     @riders =  @riders.uniq
            # else
            #     @riders = @ridersHM
            # end
            # puts "**************************@riders:#{@riders}"
            # @riderLabelObject = QuotationProduct.new(:removed=>"YES") 
            # @riderExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
            # @riderHeader = @riders.first.insuredNames.to_s.force_encoding('UTF-8')
            # # @riderObjects = @params['riderInitialCount'].to_i

            # @riderLoadingHash = {}
            # currentTotalPremium = @baseProduct.modalPremium.to_f
            # @riders.each do |qp|
            #     currentTotalPremium = currentTotalPremium + qp.modalPremium.to_f if qp.selected == 'YES'
            #     @riderLoadingHash[qp.object] = $displayRidersHM["#{@policyHolder.guid}|#{qp.object}"]
            # end
            # @totalPremium = maskDecimal(currentTotalPremium,"###,###,###.##")
            # ridersSortBySelected,remainingRiders = @riders.partition{|rider| rider.selected.to_s == "YES"}
            # ridersSortBySelected.sort_by!{|rider| rider.sortOrder.to_i} if ridersSortBySelected.size > 0
            # remainingRiders.sort_by!{|rider| rider.sortOrder.to_i} if remainingRiders.size > 0
            # @riders = ridersSortBySelected.concat remainingRiders
            # puts "FINALllllllllllllllllllll:#{@riders}"
        end

        # Premium summary Tab
        if @params['sym_current_Tab'].to_s =="tab_premiumSummary"
            @summaryTable = Array.new
            @summaryButtons = Array.new
            @totalModalPremium = 0.0
            @quotation.QuotationProductList.each do |quotation_product|
                next if quotation_product.removed.to_s != ''
                quotationProductSummary = Hash.new
                quotationProductSummary[:sum_assured] = getMaskedValue(quotation_product, "baseSumAssured")
                quotationProductSummary[:modal_premium] = getMaskedValue(quotation_product,"modalPremium")
                @totalModalPremium += quotation_product.modalPremium.to_f
                product_object = MobiSys::ProductUtil.getProduct(quotation_product.productSeq)
                if product_object
                    quotationProductSummary[:product] = getLabelValue(product_object.longName.to_s.strip)
                    product_object.OfflineFacetList.each do |offlineFacet|
                        if offlineFacet.facetId == 'PLANOPTION'
                            offlineFacet.OfflinePlanOptionList.each do |offlinePlanOption|
                                if offlinePlanOption.optionCd == quotation_product.productPlanOptionCd.to_s
                                    quotationProductSummary[:plan] = getLabelValue(offlinePlanOption.description.to_s.strip)
                                end
                            end
                        end
                    end
                end
                @summaryTable << quotationProductSummary
            end
            @totalModalPremium = maskDecimal(@totalModalPremium,"###,###,###.##")
            quotationAccepted = false
            quotationAccepted = true if (($rhoconfig[:captureSignOnSIOutput] || @quotation.signature.to_s != "") && @quotation.signatureDt.to_s != "" && (@quotation.quoteStatusCd == "ACCEPTED" || @quotation.quoteStatusCd == "SYNCDONE"))
            companyFacet = MobiSys::BrowserHelper.renderPanel?("EAPPAPPLICABLE",MobiSys::ProductUtil.getProduct(@quotation.getBaseProduct.productSeq))

            capture_output_preferences, capture_signature_on_quotataion, get_pdf_enabled, link_to_eapp_enabled = getApplicationProperties

            @summaryButtons << "<a href='#' class='summaryTabView' id='saveAndPrevButton' data-transition='slide'>#{getLabelValue('Previous')}</a>"

            if quotationAccepted
                @summaryButtons << "<a rel='external' class='summaryTabView' href='#{url_for :action => :printOptionsAndEmail, :query => {'view_email' => 'email'}, :id=>@quotation.object}' name='email'>#{getLabelValue('Email')}</a>"

                if companyFacet
                    if link_to_eapp_enabled == "YES"
                        x = "<a rel='external' class='summaryTabView' href='#' onclick=\"location.href='"+"#{url_for :action => 'linkToEapp', :query =>{ :quotationId => @quotation.object}}';\""+" name='new'>#{getLabelValue('LINKTOEAPP')}</a>"
                        @summaryButtons << x
                    end
                end
            else
                if @quotation.quoteStatusCd.to_s == MobiSys::QuotationBO::COMPLETED
                    if @params.has_key?("trigger_source") && @params["trigger_source"] == "search"
                        @summaryButtons << "<a class='summaryTabView' rel='external' href='#{url_for :action => :acceptIllustration, :id=>@quotation.object}' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    else
                        @summaryButtons << "<a rel='external' class='summaryTabView' href='javascript: acceptIllustration();' name='sign'>#{getLabelValue('ACCEPTILLUSTRATION')}</a>"
                    end
                end
            end
        end
        return true
    end


    def executeTravel
        if @params['mode'] == "copy"
           ### copying existing quotation to create new one 
           # loding source quotation  
           @sourceQuotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['sourceQuotationId']})
           # getting quotation from screen   
           targetToBeQuotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['Quotation'])    
           # merging quotation from screen with source quotation to get copied quotation      
           copiedQuotation = copyQuotation(@sourceQuotation,targetToBeQuotation,false)    
           copiedQuotation.persistAll   
           executeQuotation = copiedQuotation
        elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_selProduct"
            if (@params.has_key?("selectProductVersion") && @params["selectProductVersion"].to_s == "") || (@params.has_key?("selectProductId") && @params["selectProductId"].to_s == "") || (@params.has_key?("selectProductPlan") && @params["selectProductPlan"].to_s == "") || !@params.has_key?("selectProductId")
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    if @params['sym_current_Tab'] == "tab_basic"
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @params['Quotation']['object'])
                    else
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @params['Quotation']['object'])
                    end
                else
                    WebView.navigate(url_for :action => :newCaptureIllustration)
                end
                return
            end
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            if @params.has_key?("selectProductVersion")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductVersion'])
            elsif @params.has_key?("selectProductId")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductId'])
            end
            
            baseProduct = quotation.getBaseProduct
            # Reset Base Plan hierarchy upon product change
            if baseProduct && $currentProduct && ((baseProduct.productSeq.to_s != $currentProduct.id.to_s && baseProduct.productSeq.to_s != "") || (@params.has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['selectProductPlan'] && baseProduct.productPlanOptionCd.to_s != ""))
                
                changePlan(quotation, @params)

                quotation.visitedTabs = @params['currentTab']
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    quotation.visitedTabs = quotation.visitedTabs.to_s + ",tab_basic"
                end

                if baseProduct.nil? && $currentProduct
                    baseProduct = QuotationProduct.new
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                    quotation.addQuotationProduct(baseProduct)
                elsif baseProduct.productSeq.to_s == "" && $currentProduct
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                elsif baseProduct.productSeq.to_s == ""
                    baseProduct.product = Product.new
                end
            end

            if baseProduct.nil?
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct.productSeq.to_s == ""
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            end
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            executeQuotation = quotation
        else
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            baseProduct = quotation.getBaseProduct

            # Reset Base Plan hierarchy if selected product is not applicable anymore base on filtering creteria
            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(quotation)
                    if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                        $currentProduct = nil
                        changePlan(quotation, @params)
                        quotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['Quotation']['object']})
                        baseProduct = quotation.getBaseProduct
                        quotation.visitedTabs = @params['currentTab']
                    end
                end
            end
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end
            executeQuotation = quotation
        end

        executeQuotation.startDt = getDBDate(executeQuotation.startDt.to_s) if executeQuotation.startDt.to_s != ''
        executeQuotation.endDt = getDBDate(executeQuotation.endDt.to_s) if executeQuotation.endDt.to_s != ''
        return executeQuotation
    end


    def captureHealth
        if @tabName.to_s != ""
            if @tabName.split(",").first == "tab_selProduct"
                @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)
            elsif @tabName.split(",").first == "tab_basic"
                @partyGuidMapping = nil
                agentRegdetails = AgentReg.getCurrentAgentReg
                @quotation = setAgentDetails(@quotation, agentRegdetails)
                @quotation.currentLayout = "newcaptureIllustration"
                @quotation.quotationDt = getScreenDate(Time.now.to_s)
                #to set agent location in branch name field(quotAddtnlField2)
                @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails

                @quotation.isAgeEditableFl = nil
                isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
                if isAgeEditableFl.to_s != ''
                    @quotation.isAgeEditableFl = isAgeEditableFl
                end

                renderInsuredPanel = MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct)
                @quotation.proposerLASame = 'YES' if !renderInsuredPanel && $currentProduct

                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)

                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@policyHolder)

                setLeadRPQFNADetails

                @jointLife = QuotationParty.new(:roleCd => "JOINT",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@jointLife)

                @baseProduct = QuotationProduct.new
                @baseProduct = setBaseProductDetails(@baseProduct, $currentProduct, @params, @quotation)
                @quotation.addQuotationProduct(@baseProduct)
            end
        end

        if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
            @quotation.QuotationPartyList.each do |quotationParty|
                if quotationParty.dob.to_s != ""
                    quotationParty.age = MobiSys::ProductBO.calculateAge(@quotation, @quotation.getBaseProduct, quotationParty, nil).split("|")[0].to_i
                end
            end
        end
    end


    def showHealth
        if @params['sym_current_Tab'].to_s == "" && $currentProduct
            @params['sym_current_Tab'] = "tab_basic"
        end

        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_selProduct") || @params['sym_current_Tab'].to_s == "tab_selProduct"
            @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(@quotation)

            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && @productFamilyHash.empty?
                Alert.show_popup({
                    :message => getLabelValue('ERR_NOLAUNCHEDPRD'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @quotation.object)
                return false
            end
        end
        @quotation.quotationDt = getScreenDate(@quotation.quotationDt) if @quotation.quotationDt.to_s != ""

        # Basic Tab
        if (@params['sym_current_Tab'].to_s == "" && @tabName.split(",").first == "tab_basic") || @params['sym_current_Tab'].to_s == "tab_basic"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if ($prdSelectionFacet==nil || MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s == "") && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            agentRegdetails = AgentReg.getCurrentAgentReg
            @quotation = setAgentDetails(@quotation, agentRegdetails)
            @quotation.currentLayout = "newcaptureIllustration"
            @quotation.quotationDt = getScreenDate(Time.now.to_s) if @quotation.quotationDt.to_s == ""
            #to set agent location in branch name field(quotAddtnlField2)
            @quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
            unless @policyHolder
                @policyHolder = QuotationParty.new(:roleCd => "PROPOSER")
                @quotation.addQuotationParty(@policyHolder)
            end

            @jointLife = MobiSys::QuotationBO.getJointLife(@quotation)
            if !@jointLife
                @jointLife = QuotationParty.new(:roleCd => "JOINT")
                @quotation.addQuotationParty(@jointLife)
            end
        end


        # Supplementary Tab
        if @params['sym_current_Tab'].to_s =="tab_supplementary"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)
            @supplementLifeCount = 500
            @supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
            if @supplementaryProductFacet
                supQuotationProducts = @quotation.getQuotationProductByProductTypeCd('PLANMULTI')
                @supQuotProductHM = {}
                supQuotationProducts.each do |qp|
                    @supQuotProductHM[qp.insuredPartyRefGuid] = qp
                end
                @supQuotationProductCount = 200
            end
        end


        @quotation.QuotationPartyList.each do |quotationParty|
            quotationParty.dob = getScreenDate(quotationParty.dob) if quotationParty.dob.to_s != ""
        end
        @quotation.isAgeEditableFl = nil
        isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
        if isAgeEditableFl.to_s != ''
            @quotation.isAgeEditableFl = isAgeEditableFl
        end
        @partialProducts = MobiSys::QuotationBO.getPartialProducts(@quotation)
        renderInsuredPanel = MobiSys::BrowserHelper.renderPanel?('PROPOSERDIFFERENTFROMINSURED', $currentProduct)
        @quotation.proposerLASame = "YES" if @quotation.proposerLASame == "COPYFROMINSURED" && (($currentProduct && !renderInsuredPanel) || ($currentProduct && renderInsuredPanel) || !$currentProduct)


        # Plan Tab
        if @params['sym_current_Tab'].to_s =="tab_plan"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @insured = MobiSys::QuotationBO.getInsured(@quotation)
            unless @insured
                @insured = QuotationParty.new(:roleCd => "PRIMARY",:partyTypeCd => "INDIVIDUAL")
                @quotation.addQuotationParty(@insured)
            end

            #to set flag for enabling & disabling div based on the product
            $premiumSAFl = ''
            $multiplierFacet = ''
            $premiumPayingTerm = true

            $currentProduct.OfflineFacetList.each do |offlineFacet|
                if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
                    $premiumPayingTerm = false
                    @quotation.pptCalcBasis = 'YES'
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

            # QuotationProductExtra Section
            @quotationProductExtraLabelObject = QuotationProductExtra.new(:removed=>"YES")
            @quotationProductExtras, @baseProduct = MobiSys::QuotationBO.computeProductExtra(@quotation, @baseProduct)

            # TopUp Section
            @regularTopup = MobiSys::QuotationBO.getRegularTopup(@quotation)
            @initialTopup = MobiSys::QuotationBO.getInitialTopup(@quotation)
            @adhocTopupLabelObject = QuotationTopUp.new(:topUpTypeCd => "ADHOCTOPUP",:removed=>"YES")
            @adHocTopups = MobiSys::QuotationBO.getAdHocTopup(@quotation)
            @transferTopupLabelObject = QuotationTopUp.new(:topUpTypeCd => "TRANSFERTOPUP",:removed=>"YES")
            @contributionTopups = MobiSys::QuotationBO.getContributionTopup(@quotation)
            @topupCount = 52+@adHocTopups.size+@contributionTopups.size

            # Funds section
            @fundLabelObject = QuotationProductInvestmentFund.new(:removed=>"YES")
            prePopulateFunds(@quotation, @baseProduct)
            @funds = @baseProduct.QuotationProductInvestmentFundList
            @fundCount = 250
            fundRequiredDetailsDT = $currentProduct.getFacetValue("FUNDSREQUIRED")
            @modelArray = getPortfolioModelCd($currentProduct, @quotation, @baseProduct) if fundRequiredDetailsDT == 'YES'

            @showSearchFl = false
            if @baseProduct.portfolioModelCd.to_s != ""
                model = Model.find(:first, :conditions=>{{:name => 'modelCd'} => @baseProduct.portfolioModelCd})
                @showSearchFl = (model.modelTypeCd == 'FIXEDMODELOVERRIDE' || model.modelTypeCd == 'FIXEDMODEL')  ? true : false
                @modelFundType = model.modelTypeCd
            end

            # Withdrawal section
            @withdrawalLabelObject = QuotationWithdrawal.new(:removed=>"YES")
            @withdraws = @quotation.QuotationWithdrawalList
            @withdrawalCount = 0
        end

        # Rider Tab
        if @params['sym_current_Tab'].to_s =="tab_rider"
            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
            if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != "" && (@baseProduct==nil || @baseProduct.productSeq.to_s=="") && $rhoconfig[:tab_based_product_selection]
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @quotation.object)
                return false
            end
            @riders = MobiSys::QuotationBO.getRiders(@quotation)
            
            @riderObjects = 100
            if @quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE'
                loadRiderProducts(@quotation, $currentProduct, false)
            else
                loadRiderProducts(@quotation, $currentProduct)
            end
        end

        if @quotation.fnaId.to_s == "" && @baseProduct && @baseProduct.productId.to_s != ""
            @policyholder_details = @quotation.getPartyByRole("PROPOSER")
            if @baseProduct.productPlanOptionCd.to_s != ""
                linkedProduct = FNASIProductLink.find(:first, :conditions => { :optionCd  => @baseProduct.productPlanOptionCd })
            else
                linkedProduct = FNASIProductLink.find(:first, :conditions => { :siProductId => @baseProduct.productId })
            end
            if linkedProduct
                product = FNAProduct.find(:first, :conditions => { :productId => linkedProduct.fnaProductId})
                fnaRequestList = FNARequest.loadObject(:all, :conditions => { :statusCd => "FNAPENDING"})
                
                @fnaRequestListFiltered = []
                fnaRequestList.each do |fnaRequest|
                    @fnaParty = fnaRequest.getParty("PROPOSER")
                    if @fnaParty.lastName1.to_s == @policyholder_details.lastname.to_s && @fnaParty.firstName1.to_s == @policyholder_details.firstname.to_s
                        fnaRequest.FNAIOSelectedList.each do |fnaIOSelected|
                            if fnaIOSelected.quotationId.to_s == "" && fnaIOSelected.selectedFlag.to_s == "on" && fnaIOSelected.fnaRiderProductRefGuid.to_s == "" && fnaIOSelected.fnaBaseProductRefGuid.to_s == product.id.to_s
                                fnaRequest.witnessId = fnaIOSelected.guid
                                fnaRequest.addtnField3Str = product.longName
                                @fnaRequestListFiltered << fnaRequest
                            end
                        end
                    else
                        next
                    end
                end
            end
        end
        return true
    end


    def executeHealth
        if @params['mode'] == "copy"
           ### copying existing quotation to create new one 
           # loding source quotation  
           @sourceQuotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['sourceQuotationId']})
           # getting quotation from screen   
           targetToBeQuotation = MobiSys::BrowserHelper.convertToObject('Quotation', @params['Quotation'])    
           # merging quotation from screen with source quotation to get copied quotation      
           copiedQuotation = copyQuotation(@sourceQuotation,targetToBeQuotation,false)    
           copiedQuotation.persistAll   
           executeQuotation = copiedQuotation
        elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_selProduct"
            if (@params.has_key?("selectProductVersion") && @params["selectProductVersion"].to_s == "") || (@params.has_key?("selectProductId") && @params["selectProductId"].to_s == "") || (@params.has_key?("selectProductPlan") && @params["selectProductPlan"].to_s == "") || !@params.has_key?("selectProductId")
                Alert.show_popup({
                    :message => getLabelValue('PLEASE_SELECT_PRODUCT'), 
                    :title => getLabelValue("error"),
                    :buttons => ["OK"]
                })
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    if @params['sym_current_Tab'] == "tab_basic"
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_basic"}, :id => @params['Quotation']['object'])
                    else
                        WebView.navigate(url_for :action => :show, :query => {"msg" => @msg, "sym_current_Tab" => "tab_selProduct"}, :id => @params['Quotation']['object'])
                    end
                else
                    WebView.navigate(url_for :action => :newCaptureIllustration)
                end
                return
            end
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            if @params.has_key?("selectProductVersion")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductVersion'])
            elsif @params.has_key?("selectProductId")
                $currentProduct = MobiSys::ProductUtil.getProduct(@params['selectProductId'])
            end
            
            baseProduct = quotation.getBaseProduct
            # Reset Base Plan hierarchy upon product change
            if baseProduct && $currentProduct && ((baseProduct.productSeq.to_s != $currentProduct.id.to_s && baseProduct.productSeq.to_s != "") || (@params.has_key?('selectProductPlan') && baseProduct.productPlanOptionCd != @params['selectProductPlan'] && baseProduct.productPlanOptionCd.to_s != ""))
                
                changePlan(quotation, @params)

                quotation.visitedTabs = @params['currentTab']
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    quotation.visitedTabs = quotation.visitedTabs.to_s + ",tab_basic"
                end

                if baseProduct.nil? && $currentProduct
                    baseProduct = QuotationProduct.new
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                    quotation.addQuotationProduct(baseProduct)
                elsif baseProduct.productSeq.to_s == "" && $currentProduct
                    baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                elsif baseProduct.productSeq.to_s == ""
                    baseProduct.product = Product.new
                end
            end

            if baseProduct.nil?
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct.productSeq.to_s == ""
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            end
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            executeQuotation = quotation
        else
            quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['Quotation'])
            
            unless quotation.visitedTabs.to_s.include?(@params['currentTab'])
                quotation.visitedTabs = quotation.visitedTabs.to_s + "," + @params['currentTab']
            end
            baseProduct = quotation.getBaseProduct

            # Reset Base Plan hierarchy if selected product is not applicable anymore base on filtering creteria
            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic" && $rhoconfig[:tab_based_product_selection]
                $prdSelectionFacet ||= $rhoconfig[:prdSelection]
                if baseProduct && $currentProduct && MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet).to_s != ""
                    @offlineApplicationEnvironment,@productFamilyHash,@productIdHash,@productVersionHash,@productPlanOptionHash = MobiSys::ProductUtil.getApplicableProducts(quotation)
                    if !@productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) || (@offlineApplicationEnvironment == "PRODUCTION" && @productIdHash.has_key?(baseProduct.productFamilyCd.to_sym) && @productIdHash[baseProduct.productFamilyCd.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0) || (@offlineApplicationEnvironment == "UAT" && @productVersionHash.has_key?(baseProduct.productId.to_sym) && @productVersionHash[baseProduct.productId.to_sym].select{|x| x[:id]==baseProduct.productSeq.to_s}.size == 0)
                        $currentProduct = nil
                        changePlan(quotation, @params)
                        quotation = Quotation.loadObject(:first,:conditions=>{:object=>@params['Quotation']['object']})
                        baseProduct = quotation.getBaseProduct
                        quotation.visitedTabs = @params['currentTab']
                    end
                end
            end
            if baseProduct.nil? && $currentProduct
                baseProduct = QuotationProduct.new
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
                quotation.addQuotationProduct(baseProduct)
            elsif baseProduct && baseProduct.productSeq.to_s == "" && $currentProduct
                baseProduct = setBaseProductDetails(baseProduct, $currentProduct, @params, quotation)
            elsif baseProduct && baseProduct.productSeq.to_s == ""
                baseProduct.product = Product.new
            end
            executeQuotation = quotation
        end

        if executeQuotation.proposerLASame == 'YES' || executeQuotation.proposerLASame == "COPYFROMINSURED"
            executeQuotation.proposerLASame = "COPYFROMINSURED"
        else
            executeQuotation.proposerLASame = nil
        end
        return executeQuotation
    end

    def copyPartyFields(party1, party2)
        party1.partyTypeCd = "INDIVIDUAL"
        party1.title = party2.title
        party1.otherTitle = party2.otherTitle
        party1.firstname = party2.firstname
        party1.middlename = party2.middlename
        party1.lastname = party2.lastname
        party1.extensionName = party2.extensionName
        party1.firstname2 = party2.firstname2
        party1.middlename2 = party2.middlename2
        party1.lastname2 = party2.lastname2
        party1.extensionName2 = party2.extensionName2
        party1.genderCd = party2.genderCd
        party1.dob = party2.dob
        party1.age = party2.age
        party1.relationCd = party2.relationCd
        party1.smoker = party2.smoker
        party1.industryCd = party2.industryCd
        party1.countryCd = party2.countryCd
        party1.contactNum = party2.contactNum
        party1.emailAddress = party2.emailAddress
        party1.natureOfDuty = party2.natureOfDuty
        party1.occupationCd = party2.occupationCd
        party1.nsap = party2.nsap
        return party1
    end

    # attach question container to quotation object for dynamic DT evaluation
    def attachQuestionContainer(quotation)
        quotationQuestionContainer = QuestionContainer.loadObject(
            :first, 
            :conditions=>{
                {:name=>'entityGuid'} => quotation.uniqueKey,
                {:name=>'policyGuid'} => quotation.uniqueKey
            },
            :op => 'AND'
        )
        quotation.questionContainer = quotationQuestionContainer if quotationQuestionContainer

        quotation.QuotationPartyList.each do |quotationParty|
            quotPartyQuestionContainer = QuestionContainer.loadObject(
                :first, 
                :conditions=>{
                    {:name=>'entityGuid'} => quotationParty.uniqueKey,
                    {:name=>'policyGuid'} => quotation.uniqueKey
                },
                :op => 'AND'
            )
            quotationParty.questionContainer = quotPartyQuestionContainer if quotPartyQuestionContainer
        end
    end


    def illustrationSelect
        WebView.execute_js("showLoadingMessage()")
        @searchResult = Array.new
          
        productList = Product.loadObject(
            :all,
            :conditions => {
                {:name => 'productTypeCd'} => 'PLAN'
            },
            :select => ['id', 'longName']
        )

        @productLookup = Array.new
        productList.each do |product|
            productTemp = Lookupvalue.new
            productTemp.cd = product.id.to_s
            productTemp.desc = product.longName
            @productLookup.push(productTemp)
        end

        if !@params.empty?
            quotationRefNum = @params['quotationRefNum']
            productSeq = @params['productSeq']
            insuredName = @params['insuredName']
            quoteStatusCd = @params['quoteStatusCd']
            quotationDt = getDBDate(@params['quotationDt']) if @params['quotationDt'].to_s != ""


            quotationList = Quotation.loadObject(
                :count => '200',
                :order => 'quotationRefNum', 
                :orderdir => 'DESC',
                :select => ['quotationRefNum', 'productId', 'quotationDt', 'quoteStatusCd', 'object', 'signature']
            )

            quotationList.each do |quotation|
                next if quotation.quoteStatusCd == "PENDING"

                validQuotation = true

                if quotationRefNum != ""
                    validQuotation = false if quotation.quotationRefNum.to_s.index(quotationRefNum) == nil
                end
            
                if quoteStatusCd != "" && validQuotation
                    validQuotation = false if quotation.quoteStatusCd != quoteStatusCd
                end
                
                if quotationDt != "" && validQuotation
                    validQuotation = false if quotation.quotationDt.to_s.index(quotationDt.to_s) == nil
                end
                
                if insuredName != "" && validQuotation
                    validQuotation = false if quotation.getInsuredName.index(insuredName) == nil
                end
                
                if productSeq != "" && validQuotation
                    validQuotation = false if quotation.getBaseProduct.productSeq.to_s != productSeq.to_s
                end

                if validQuotation
                    quotationHash = Hash.new
                    quotationHash[:object] = quotation.object
                    if quotation.quotationRefNum.to_s != ""
                        quotationHash[:quotationRefNum] = quotation.quotationRefNum
                    else
                        quotationHash[:quotationRefNum] = "-"
                    end
                    if quotation.quoteStatusCd.to_s != ""
                        quotationHash[:quoteStatusCd] = quotation.quoteStatusCd
                    else
                        quotationHash[:quoteStatusCd] = "-"
                    end
                    product = MobiSys::ProductUtil.getProduct(quotation.getBaseProduct.productSeq)
                    if product && product.shortName.to_s != ""
                        quotationHash[:productName] = product.shortName
                    else
                        quotationHash[:productName] = "-"
                    end
                    if quotation.getInsuredName.to_s != ""
                        quotationHash[:insuredName] = quotation.getInsuredName
                    else
                        quotationHash[:insuredName] = "-"
                    end
                    if quotation.quotationDt.to_s != ""
                        quotationHash[:quotationDt] = getScreenDate(quotation.quotationDt)
                    else
                        quotationHash[:quotationDt] = "-"
                    end
                    @searchResult.push(quotationHash)
                end
            end
        end

        render :action => :QuoteSearchmulti_Jazz, :layout => :jazzLayout
    end

    def deleteQuotation
        if @params['deleteCheck'].to_s != ""
            @params['deleteCheck'].each do |selectedQuotationId|
                quotation = Quotation.loadObject( :first, :conditions => { :object => selectedQuotationId } )
                MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
                quotation.delete if quotation

                container = SignatureContainer.loadObject(:all,:condition=>{{:name=>'entityGuid'}=>quotation.guid})
                if container
                    container.each do|signature_container|
                        signature_container.delete if signature_container
                    end
                end
            end
        end
        WebView.navigate("#{url_for :controller => :Quotation, :action => :search}")
    end

end
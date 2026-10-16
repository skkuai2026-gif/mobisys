require 'CommonModules/entityschema'
# require 'CommonModules/syncmodule'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'Quotation/APO'


module MobiSys
	class QuotationService
		extend MobiSys::BrowserHelper
		
		def self.requiredTabs
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
	            requiredTabs['tab_premiumSummary'] = 'premiumSummary'
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

		def self.saveValidate(quotation, needToPersist = true, mode = "")
	        @quotation = quotation
	        return false if @quotation != nil && ((@quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE') && @quotation.entityStatus.to_s != "REOPEN")
	       
	        @quotation.quotationDt = getDBDate(@quotation.quotationDt) if @quotation.quotationDt != nil && @quotation.quotationDt != ""
	        @quotation.jointLife = nil if @quotation.jointLife == nil || @quotation.jointLife =='NO'

	        # @quotation.jointLife = nil unless @quotation.jointLife #Line added so that on flag gets removed when de-selecting the flag on screen.
	        @baseProduct = @quotation.getBaseProduct()
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(@baseProduct.productSeq)
	        currencyCode = @baseProduct != nil ? @baseProduct.currencyCd : nil
	        $currencyFormat = nil
	        if currencyCode
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

	            if lookupValueOfCurrencyMaster != nil
	                if lookupValueOfCurrencyMaster.additionalField1 != nil
	                    $currencyFormat = lookupValueOfCurrencyMaster.additionalField1
	                end
	            end
	        end
	        if $currencyFormat == nil
	            $currencyFormat = $rhoconfig[:number_format_pattern].to_s
	        end
	        if @baseProduct.product == nil
	            quot_product = MobiSys::ProductUtil.getProduct(@baseProduct.productSeq)
	        else  
	            quot_product = @baseProduct.product
	        end
	        #Code block to check if BATCHSETTLEMENTOPTION is present or not
	        #If present do the needful
	        planOptionFacet = quot_product.getFacet('BATCHSETTLEMENTOPTION') if quot_product
	        if planOptionFacet
	            prdBankPart = quot_product.getFacet('PRDBANKINGPARTNER')
	            @quotation.quotAddtnlField1 = (prdBankPart && !prdBankPart.actionValue.nil?) ? prdBankPart.actionValue : @quotation.quotAddtnlField1
	            prdIssueDt = quot_product.getFacet('PRDISSUEDATE')
	            @quotation.issueDt = (prdIssueDt && !prdIssueDt.actionValue.nil?) ? prdIssueDt.actionValue : @quotation.quotationDt
	        else
	            # @quotation.quotAddtnlField1 ='nil'
	            @quotation.issueDt = @quotation.quotationDt
	        end
	        #BATCHSETTLEMENTOPTION code block ends

	        # set covert type base upon product facet
	        if quot_product.getFacetValue('FAMILYINSUREDDETAILS') == "YES"
	        	@quotation.coverTypeCd = "FAMILYFLOATER"
        	elsif quot_product.getFacetValue('MULTILIFEAPPLICABLE') == "YES"
        		@quotation.coverTypeCd = "INDIVIDUAL"
        	end

	        # Quotation expiry date computation
	        expiryDays = MobiSys::BrowserHelper.getFacetMappedValue("QUOTATIONEXPIRYDAYS", nil)
	        if expiryDays.to_s != "" && @quotation.quotationDt.to_s != "" && @quotation.quotationExpiryDt.to_s == ""
	            @quotation.quotationExpiryDt = getDBDate((Date.strptime(getScreenDate(@quotation.quotationDt.to_s), "%d/%m/%Y") + expiryDays.to_i).strftime("%d/%m/%Y").to_s)
	        end

	        # Quotation backdated flag computation
	        if @quotation.systemCreatedDt.to_s != "" && @quotation.quotationDt.to_s != ""
	            if (Date.strptime(getScreenDate(@quotation.systemCreatedDt.to_s), "%d/%m/%Y") - Date.strptime(getScreenDate(@quotation.quotationDt.to_s), "%d/%m/%Y") > 0)
	                @quotation.isBackdatedFl = "YES"
	            else
	                @quotation.isBackdatedFl = "NO"
	            end
	        end

	        @insured = MobiSys::QuotationBO.getInsured(@quotation)
	        @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
	        @quotation.proposerLASame = 'COPYFROMINSURED' if @quotation.insuranceTypeCd == 'TRAVEL'
	        if @policyHolder == nil && @quotation.proposerLASame == "COPYFROMINSURED"
	            @policyHolder = QuotationParty.new(:roleCd => "PROPOSER")
	            @quotation.addQuotationParty(@policyHolder)
	        end

	        @quotation.proposerLASame = nil unless @quotation.proposerLASame #Line added so that on flag gets removed when de-selecting the floag on screen.
	        if @quotation.proposerLASame == 'YES' ||  @quotation.proposerLASame == "COPYFROMINSURED"
	            proposerLASameCopy
	        end

	        if quot_product.getFacetValue('PROPOSERDIFFERENTFROMINSURED') == "YES"
		        @quotation.proposerLASame = "NO" if @quotation.proposerLASame == nil
			elsif @quotation.insuranceTypeCd.to_s == "LIFE" || @quotation.insuranceTypeCd == nil
				@quotation.proposerLASame = "YES" if @quotation.proposerLASame == nil
			end
	        
	        #code for removing on value from db on uncheck
	        @baseProduct.topUpAllocSameAsPremAllocFl = nil unless @baseProduct.topUpAllocSameAsPremAllocFl
	        #end of code for removing on value from db on uncheck
	        @riders = MobiSys::QuotationBO.getRiders(@quotation)
	        getBuiltInRiderList(quot_product, @quotation)
	        if quot_product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES"
	            if needToPersist == true 
	                @newriders = @quotation.getNonBuiltInRiders
	                # callMethodFlag = @params['currentTab'].to_s != "tab_rider" && @params['sym_current_Tab'].to_s != 'tab_rider'
	                # if callMethodFlag
	                    loadRiderProducts(@quotation, quot_product, false)
	                # end
	                if $rhoconfig[:TABFEATUREREQD]
	                    # especially for cases where personal details are changed and some riders are no longer applicable
	                    unless ($displayRidersHM == nil || $displayRidersHM.empty?)
	                        @quotation.QuotationProductList.each do |qp|
	                            if qp.productTypeCd.to_s == 'RIDER' && qp.builtInRiderFl.to_s != 'YES'
	                                if (qp.partyRoleCd == 'PRIMARY' || qp.partyRoleCd == 'PROPOSER') && @quotation.proposerLASame == 'COPYFROMINSURED'
	                                    qp.removed = 'YES' unless ($displayRidersHM['SAMEAS'].values.flatten.compact.collect{|x| x.object}.include? qp.object)
	                                else
	                                    qp.removed = 'YES' unless ($displayRidersHM[qp.insuredPartyRefGuid] != nil and $displayRidersHM[qp.insuredPartyRefGuid].values.flatten.compact.collect{|x| x.object}.include? qp.object)
	                                end
	                            end
	                        end
	                    else
	                        if mode != "copy"
	                            @quotation.QuotationProductList.each do |qp|
	                                if qp.productTypeCd.to_s == 'RIDER' && qp.builtInRiderFl.to_s != 'YES'
	                                    qp.removed = 'YES'
	                                end
	                            end
	                        end
	                    end
	                else
	                    @newriders.each do |rider|
	                        rider.selected = nil unless rider.selected
	                        if (rider.selected.to_s != "on" && rider.selected.to_s != 'YES')
	                            rider.removed = "YES" if rider.builtInRiderFl != 'YES'
	                            @quotation.removeQuotationProduct(rider) if rider.builtInRiderFl != 'YES'
	                        elsif rider.selected.to_s == 'on' || rider.selected.to_s == 'YES'
	                            rider.removed = ''
	                        end
	                    end
	                end
	            else
	                @riders.each do |rider|
	                    rider.selected = nil unless rider.selected
	                    if (rider.selected.to_s != "on" && rider.selected.to_s != 'YES')
	                        rider.removed = "YES" if rider.builtInRiderFl != 'YES'
	                    elsif rider.selected.to_s == 'on' || rider.selected.to_s == 'YES'
	                        rider.removed = ''
	                    end
	                end
	            end
	        end

	        @funds = @baseProduct.QuotationProductInvestmentFundList
	        
	        ######## check duplicate quotationRefNum########################################
	        if needToPersist and (@quotation.quotationRefNum == nil || @quotation.quotationRefNum == "")
	            @quotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
	        end
	        
	        @riders.each do |rider|
	            if rider.productSeq.to_s != ''
	                @riderProduct = MobiSys::ProductUtil.getProduct(rider.productSeq)

	                rider.paymentTypeCd = @baseProduct.paymentTypeCd
	                rider.paymentFrequencyCd = @baseProduct.paymentFrequencyCd
	                rider.currencyCd = @baseProduct.currencyCd
	                if @riderProduct
	                    rider.productVersion = @riderProduct.productVersion
	                    rider.productFamilyCd = @riderProduct.productFamilyId
	                end

	                if rider.partyRoleCd != "SUPPLEMENTARY"
	                    @quotation.QuotationPartyList.each do |party|
	                        if party.roleCd == rider.partyRoleCd
	                            rider.insuredPartyRefGuid = party.guid
	                            break
	                        end
	                    end
	                end
	            else
	                rider.removed = 'YES'
	            end
	        end

	        #actions with quotation
	        @quotation.QuotationPartyList.each do |quotationParty|
	            quotationParty.dob = getDBDate(quotationParty.dob) if quotationParty.dob != nil && quotationParty.dob != ""
	        end

	        @quotation.productVersion = @baseProduct.productVersion
	        ### Namrata commented for testing
	        @quotation.productSeq = @baseProduct.productSeq
	        @quotation.productId = @baseProduct.productId
	        @quotation.productTypeCd = @baseProduct.productTypeCd
	        @quotation.productFamilyCd = @baseProduct.productFamilyCd

	        #Code to set combinedEntryAge starts
	        @quotation.QuotationProductList.each do |quotationProduct|
	            party = @quotation.getParty(quotationProduct)
	            quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!=""
	        end
	        #code to set combinedEntryAge ends
	    

	        ### if supplementary is marked for deletion then delete it's rider too
	        # unless $rhoconfig[:TABFEATUREREQD]
	        supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)  
	        supplementaryLife.each do |suppParty|
	            if suppParty.removed == "YES"
	                @quotation.QuotationProductList.each do |quotationProduct|
	                    if (quotationProduct.productTypeCd == "RIDER" || quotationProduct.productTypeCd == 'PLANMULTI') && quotationProduct.insuredPartyRefGuid == suppParty.guid
	                        quotationProduct.removed = "YES"
	                    end  
	                end
	            end
	        end
	        # end
	        @baseProduct.minTargetPremium = 0.0 if @baseProduct.minTargetPremium.to_s == ""
	        @baseProduct.maxTargetPremium = 0.0 if @baseProduct.maxTargetPremium.to_s == ""
	        @baseProduct.recommendedPremium = 0.0 if @baseProduct.recommendedPremium.to_s == ""
	        @baseProduct.unapliedPremium = 0.0 if @baseProduct.unapliedPremium.to_s == ""

	        # now check if multi life is applicable (i.e. SA, premium exists on the supp lives).. in that case add QuotationProductDOs.
	        supplementaryProductFacet = quot_product.getFacet('MULTILIFEAPPLICABLE')
	        if supplementaryProductFacet
	        	createMultiLifeQuotationProduct()
	        end
	        # set quotation product sort order
	        listQuotationProduct = Array.new
	        riderAsscFacet = quot_product.getRiderAssociationFacet()
	        @quotation.QuotationProductList.each do |quotationProduct|
	            if quotationProduct.productTypeCd == "RIDER"
	                riderAssc = quot_product.getRiderAssociationDO(nil,@baseProduct.productPlanOptionCd,quotationProduct.productPlanOptionCd, riderAsscFacet, quotationProduct.productSeq, quotationProduct.partyRoleCd)
	                quotationProduct.sortOrder = (riderAssc.sortOrder.to_s != "" ? riderAssc.sortOrder : riderAssc.id) if riderAssc
	            else
	                quotationProduct.sortOrder = 0
	            end
	            listQuotationProduct.push quotationProduct
	        end
	        listQuotationProduct.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
	        @quotation.setQuotationProductList(listQuotationProduct)
	        # Function for blanking out fields based on partyTypeCd (INDIVIDUAL/ORGANIZATION)
	        setPartyFields(@quotation)
	        # This method is implemented in company layer
	        # preValidate(params, needToPersist, @quotation)
	        @errors = Hash.new
	        isValidated = MobiSys::QuotationBO.validate(@quotation, @msg, @errors)
	        # This method is implemented in company layer
	        # postValidate(params, needToPersist, @quotation)
	        if $rhoconfig[:TABFEATUREREQD]
	            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
	            tabName, tabLabel = requiredTabs
	            visitedTabs = @quotation.visitedTabs.to_s.split(",").reject{ |c| c.empty? }
	            tabName = tabName.split(",")
	            if (@errors!=nil && !@errors.empty?) || (@incompleteTabs!=nil && !@incompleteTabs.empty?) || ((tabName - visitedTabs).join("").to_s != "" && ((tabName - visitedTabs).join("").to_s != "tab_supplementary") && (tabName - visitedTabs).join("").to_s != "tab_selProduct")
	                @msg = "ERROR"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::PENDING
	            else
	                @msg = "SUCCESS"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
	            end
	        else
	            if !isValidated
	                @msg = "ERROR"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::PENDING
	            else
	                @msg = "SUCCESS"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
	            end
	        end
	        #For step feature in UI
	        incrementStep(@quotation,true)

	        if needToPersist
	            @quotation.childUserId = $userId
	            @quotation.appVersion = Rho::RhoConfig.app_version
	            @quotation.dbVersion = Application.getValue('DBVERSION').value
	            @quotation.persistAll
	        end
	    end

	    def self.createMultiLifeQuotationProduct
	    	supplementaryLifes = MobiSys::QuotationBO.getSupplementaryLife(@quotation)
            supplementaryLifes.each do |individualLifeParty|
            	individualLifeQuoteProduct = @quotation.getBasePlanMulti(individualLifeParty.guid)
            	if individualLifeQuoteProduct == nil
            		individualLifeQuoteProduct = QuotationProduct.new
            	end
            	fieldsToExcludeArr = ["guid"]
            	individualLifeQuoteProduct = MobiSys::CommonUtil.copyFields(@quotation.getBasePlan, individualLifeQuoteProduct, fieldsToExcludeArr)
				individualLifeQuoteProduct.addQuotationProductExtra(QuotationProductExtra.new) if individualLifeQuoteProduct.QuotationProductExtraList && individualLifeQuoteProduct.QuotationProductExtraList.size == 0
				individualLifeQuoteProduct.addQuotationProductInvestmentFund(QuotationProductInvestmentFund.new) if individualLifeQuoteProduct.QuotationProductInvestmentFundList && individualLifeQuoteProduct.QuotationProductInvestmentFundList.size == 0
            	individualLifeQuoteProduct.productTypeCd = "PLANMULTI"
            	individualLifeQuoteProduct.combinedEntryAge = individualLifeParty.age
            	individualLifeQuoteProduct.baseSumAssured = individualLifeParty.baseSumAssured
            	individualLifeQuoteProduct.modalPremium = individualLifeParty.modalPremium
            	individualLifeQuoteProduct.baseAnnualPremium = individualLifeParty.baseAnnualPremium
            	individualLifeQuoteProduct.productPlanOptionCd = individualLifeParty.productPlanOptionCd
            	individualLifeQuoteProduct.insuredPartyRefGuid = individualLifeParty.guid
            	individualLifeQuoteProduct.partyRoleCd = individualLifeParty.roleCd
            	individualLifeQuoteProduct.selected = "YES"
            	individualLifeQuoteProduct.multiLifeField1 = individualLifeParty.multiLifeField1
            	individualLifeQuoteProduct.multiLifeField2 = individualLifeParty.multiLifeField2
            	individualLifeQuoteProduct.multiLifeField3 = individualLifeParty.multiLifeField3
            	@quotation.addQuotationProduct(individualLifeQuoteProduct)
            end
	    end

	    def self.populateMultiLife(quotation)
	    	supplementaryLifes = MobiSys::QuotationBO.getSupplementaryLife(quotation)
	    	supplementaryLifes.each do |individualLifeParty|
	    		individualLifeQuoteProduct = @quotation.getBasePlanMulti(individualLifeParty.guid)
	    		if individualLifeQuoteProduct
	            	individualLifeParty.baseSumAssured = individualLifeQuoteProduct.baseSumAssured
	            	individualLifeParty.modalPremium = individualLifeQuoteProduct.modalPremium
	            	individualLifeParty.baseAnnualPremium = individualLifeQuoteProduct.baseAnnualPremium
	            	individualLifeParty.productPlanOptionCd = individualLifeQuoteProduct.productPlanOptionCd
	            	individualLifeParty.multiLifeField1 = individualLifeQuoteProduct.multiLifeField1
	            	individualLifeParty.multiLifeField2 = individualLifeQuoteProduct.multiLifeField2
	            	individualLifeParty.multiLifeField3 = individualLifeQuoteProduct.multiLifeField3
	            	quotationProductExtra = Array.new
	            	individualLifeQuoteProduct.QuotationProductExtraList.each do |qpe|
		                quotationProductExtra.push(qpe)
		            end
	            	individualLifeParty.quotationProductExtra = quotationProductExtra
	            end
	    	end
	    end

	    def self.incrementStep(quotation,isErrorCheckReq=true)
	        if quotation.stepActionTabs.to_s != ""
	            stepActionTabList = quotation.stepActionTabs.to_s.split(",")
	            quotation.stepActionTabs = nil
	            incrementStep = true
	            if isErrorCheckReq
	            	if stepActionTabList.size > 0
		            	tabWiseTaskExceptionMap,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(quotation.guid, quotation.visitedTabs)
		                stepActionTabList.each do |stepAction|
		                    if(tabWiseTaskExceptionMap[stepAction] != nil and tabWiseTaskExceptionMap[stepAction].size > 0)
		                        incrementStep = false
		                        break
		                    end
		                end
		            else
		            	incrementStep = false
		            end
	            end
	            quotation.step = 0 if quotation.step.to_s == ""
	            quotation.step = (quotation.step.to_i + 1) if incrementStep
	        end
	    end

	    def self.getBuiltInRiderList(product, quotation)
	        existingBuiltInRiderProductSeqList = quotation.getBuiltInRiders.group_by{|qp| qp.productSeq.to_s}
	        builtInRiderArray = []
	        offlineFacet = product.getFacet('RIDERASSOCIATION')
	        riderAutoPopulationReqFlag = product.getFacet('RIDERAUTOPOPULATIONREQUIRED')
	        if offlineFacet
	            offlineFacet.OfflineRiderAssociationList.each do |offlineRider|
	                if offlineRider.builtInRiderFl == 'YES'
	                    if existingBuiltInRiderProductSeqList.keys.include? offlineRider.productSeq.to_s
	                        builtInRider = existingBuiltInRiderProductSeqList[offlineRider.productSeq.to_s][0]
	                    else
	                        if riderAutoPopulationReqFlag
	                            applicableRoles = offlineRider.applicableRoles.to_s.split(',')
	                            if applicableRoles.to_s != ''
	                                applicableRoles.each do |roleCd|
	                                    builtInRider = QuotationProduct.new(:productTypeCd => 'RIDER', :productId => offlineRider.productId, :productSeq => offlineRider.productSeq, :builtInRiderFl => offlineRider.builtInRiderFl, :productTerm => 0, :premiumPayingTerm => 0, :coi=>0.0,:sortOrder => offlineRider.sortOrder)
	                                    builtInRider.partyRoleCd = roleCd
	                                    quotation.addQuotationProduct(builtInRider)
	                                end
	                            else
	                                builtInRider = QuotationProduct.new(:productTypeCd => 'RIDER', :productId => offlineRider.productId, :productSeq => offlineRider.productSeq, :builtInRiderFl => offlineRider.builtInRiderFl, :productTerm => 0, :premiumPayingTerm => 0, :coi=>0.0, :partyRoleCd=>'PRIMARY',:sortOrder => offlineRider.sortOrder)
	                                quotation.addQuotationProduct(builtInRider)
	                            end
	                        else
	                            builtInRider = QuotationProduct.new(:productTypeCd => 'RIDER', :productId => offlineRider.productId, :productSeq => offlineRider.productSeq, :builtInRiderFl => offlineRider.builtInRiderFl, :productTerm => 0, :premiumPayingTerm => 0, :coi=>0.0, :partyRoleCd=>'PRIMARY',:sortOrder => offlineRider.sortOrder)
	                            quotation.addQuotationProduct(builtInRider)
	                        end
	                    end
	                    builtInRiderArray.push(builtInRider)
	                end
	            end
	        end
	        return builtInRiderArray
	    end

	    def self.loadRiderProducts(quotation, product = nil, validateRider=true)
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
	            	#set status from N to blank to prevent rider object deletion
	            	nonBuiltInRider.status = ""
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
	            	#set status to "" to prevent rider object deletion
	            	rider.status = ""
	                product = MobiSys::ProductUtil.getProduct(rider.productSeq)
	                if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
		                if rider.selected.to_s == 'YES' 
		                    rider.removed = ''
		                else
		                    rider.removed = 'YES'
		                end
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

	    def self.autoPopulateRider(quotationDO, displayRidersHM, existingQuotationProducts, riderAssociationDO, defTableDO, party, addDefaultBlankRiderFl = false)
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
	                    elsif insuredRider.applicablePlanOptions.to_s.include? riderAssociationDO.planOptionCd.to_s
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
	                    elsif proposerRider.applicablePlanOptions.to_s.include? riderAssociationDO.planOptionCd.to_s
	                        proposerRiderExistFlag = true
	                    end
	                end 
	            end
	            riderExistFlag = insuredRiderExistFlag || proposerRiderExistFlag
	        end

	        return if partySameAsFlag && riderExistFlag

	        #Added addDefaultBlankRiderFl flag; when evaluateRider is called it is set to true add blank rider to show unselected riders on the UI.
	        if existingQuotationProducts.has_key?(riderKeyId) && ((addDefaultBlankRiderFl && existingQuotationProducts[riderKeyId].removed.to_s != "YES") || !addDefaultBlankRiderFl)
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

	    def self.addBlankRider(quotation, party, riderAssociation = nil)
	        rider = QuotationProduct.new(:productTypeCd => 'RIDER', :partyRoleCd => party.roleCd, :builtInRiderFl => 'NO', :coi=>0.0, :insuredPartyRefGuid => party.guid, :insuredPartyName => party.getFullName)
	        if riderAssociation != nil
	            riderProduct = MobiSys::ProductUtil.getProduct(riderAssociation.productSeq)
	            rider.productSeq = riderAssociation.productSeq
	            rider.productId = riderAssociation.productId
	            rider.parentproductSeq = riderAssociation.parentproductSeq
	            rider.linkedFl = riderAssociation.linkedFl
	            rider.sortOrder = (riderAssociation.sortOrder.to_s != "" ? riderAssociation.sortOrder : riderAssociation.id)
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

	    def self.setBaseProductDetails(baseProduct, product, quotation)
            if product
                baseProduct.productId = product.productId
                baseProduct.productSeq = product.id
                baseProduct.productVersion = product.productVersion
            end

 

            baseProduct.annuityPerc = 100;
            baseProduct.pdfFrequencyVal = 0;
            baseProduct.pdfPeriod = 0

 

            baseProduct.productTypeCd = "PLAN"
            # baseProduct.planCode = params['planCode'][0..-4].chop if params['planCode'] != nil  
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
            if (quotation && quotation.insuranceTypeCd == 'TRAVEL')
                if quotation.startDt.to_s != '' && quotation.endDt.to_s != ''
                    startDt = Date.strptime(getScreenDate(quotation.startDt), "%d/%m/%Y")
                    endDt = Date.strptime(getScreenDate(quotation.endDt), "%d/%m/%Y")
                    baseProduct.productTerm = MobiSys::ProductUtil.getDifference(startDt,endDt)
                end
                baseProduct.premiumPayingTerm = 1
                baseProduct.paymentTypeCd = "SINGLE"
                baseProduct.paymentFrequencyCd = "SINGLE"
                baseProduct.productFamilyCd = product.productFamilyId if product
            elsif (quotation && quotation.insuranceTypeCd == 'AUTO')
                baseProduct.productFamilyCd = product.productFamilyId if product
            else
                baseProduct.paymentTypeCd = nil
                baseProduct.paymentFrequencyCd = nil
                baseProduct.productTerm = nil
                baseProduct.premiumPayingTerm = nil
                baseProduct.productFamilyCd = product.productFamilyId if product
            end
            
            return baseProduct
        end

        def self.getProductTerm(quotation)
	        quotationProduct = quotation.getBaseProduct()
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(quotationProduct.productSeq.to_s)
	        minMaxTermTTMS = $currentProduct.getTableTypeMappingSeq('MINMAXTERM')
	        termArray = []
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
	                    termArray = Lookupvalue.find(:all, 
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
	                     termArray = Lookupvalue.find(:all,
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
	            termArray = Lookupvalue.getValue('TERMVALUE')
	        end
	        termArray.sort_by!{|lookUp| lookUp.sortOrder.to_i}
	        
	        return termArray
	    end

	    def self.getPremiumPayingTerm(quotation)
	        ppTermArray = []
	        quotationProduct = quotation.getBaseProduct()
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(quotationProduct.productSeq.to_s)
	        minMaxTermPPTTMS = $currentProduct.getTableTypeMappingSeq('MINMAXPPTERM')
	        if minMaxTermPPTTMS
	            minMaxPPTermFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(minMaxTermPPTTMS,quotation, quotation.getBaseProduct)
	            if minMaxPPTermFacetProductDef
	                if minMaxPPTermFacetProductDef.fixedTermValues.to_s != ""
	                    fixedTermArr = minMaxPPTermFacetProductDef.fixedTermValues.strip.split(',')
	                    ppTermArray = Lookupvalue.find(:all, 
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
	                    ppTermArray = Lookupvalue.find(:all,
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
	                    ppTermArray.push(Lookupvalue.new(:cd => "1", :desc => "1"))
	                    quotation.getBaseProduct.premiumPayingTerm = "1"
	                end
	            end
	        else
	            ppTermArray = Lookupvalue.getValue('TERMVALUE')
	        end

	        ppTermArray.sort_by!{|lookUp| lookUp.sortOrder.to_i}
	        return ppTermArray
		end
		
		 # attach question container to quotation object for dynamic DT evaluation
		def self.attachQuestionContainer(quotation)
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
		
		def self.calculatePremium(quotation)
			# quotation = MobiSys::BrowserHelper.convertToObjectWithMerge('Quotation', @params['form']['Quotation'])
			if quotation.proposerLASame=='YES' || quotation.proposerLASame=='COPYFROMINSURED'
				quotation.proposerLASame = "COPYFROMINSURED"
			else
				quotation.proposerLASame = nil
			end
			# attach question container to quotation object for dynamic DT evaluation
			attachQuestionContainer(quotation)
			saveValidate(quotation,false,"")
			# logInfo "Calculate Premmium after saveValidate #{quotation.getBaseProduct.baseAnnualPremium}"

			# @msg = ""
			# @errors = Hash.new
			# @modelPremium = @annualPremium = 0
			
			# quot_prod = @quotation.getBaseProduct
			# @product = $currentProduct
			# @ropLookups = []

			# @offlineFacets = @product.OfflineFacetList
			# @offlineFacets.each do |offlineFacet|
			# 	offlineFacet.parentKey == @baseProduct.productId
			# end
			# #to set flag for enabling & disabling div based on the product
			# $premiumSAFl = ''
			# $multiplierFacet = ''
			# $premiumPayingTerm = true

			# premiumFacet = @product.getFacet('PREMIUMDETAILS')
			# @allowedCurrency = ''
			# @allowedPaymentTypeCd = ''
			# @allowedPaymentFrequencyCd = ''

			# @product.OfflineFacetList.each do |offlineFacet|
			# 	if (offlineFacet.facetId == 'ISPPTDIFFERENTFROMPT' && offlineFacet.actionValue == 'YES')
			# 		$premiumPayingTerm = false
			# 	end
			# 	if offlineFacet.facetId == 'MULTIPLIER'
			# 		$multiplierFacet = offlineFacet
			# 	end
			# 	if offlineFacet.facetId == 'MINMAXTERM'
			# 		@minMaxTermFacet = offlineFacet
			# 	end

			# 	offlineFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
			# 		@readOnlyFields = offlinePremiumDetail.inputDataElement.to_s
			# 		if offlinePremiumDetail.premiumSAFl != nil
			# 			if offlinePremiumDetail.premiumSAFl == 'SA'
			# 				$premiumSAFl = 'SA'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'PREMIUM'
			# 				$premiumSAFl = 'PREMIUM'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'DUAL'
			# 				$premiumSAFl = 'DUAL'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'ANNUALINCOME'
			# 				$premiumSAFl = 'ANNUALINCOME'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'MONTHLYINCOME'
			# 				$premiumSAFl = 'MONTHLYINCOME'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'ANNUALPREMIUM'
			# 				$premiumSAFl = 'ANNUALPREMIUM'
			# 			elsif offlinePremiumDetail.premiumSAFl == 'COMPUTEDSA'
			# 				$premiumSAFl = 'COMPUTEDSA'
			# 			end
			# 		end
			# 		if offlinePremiumDetail.premiumTypeCd.to_s != ''
			# 			@allowedPaymentTypeCd = offlinePremiumDetail.premiumTypeCd
			# 		end
			# 		if offlinePremiumDetail.paymentFrequencyCd.to_s != ''
			# 			@allowedPaymentFrequencyCd = offlinePremiumDetail.paymentFrequencyCd
			# 		end
			# 	end
			# end

			# if premiumFacet != nil
			# 	if premiumFacet.OfflinePremiumDetailsList[0]
			# 		if premiumFacet.OfflinePremiumDetailsList[0].currencyCd.to_s != ''
			# 			@allowedCurrency = premiumFacet.OfflinePremiumDetailsList[0].currencyCd
			# 		end
			# 	end
			# end
			
			# quot_prod.vars.each do |key,value|
			# 	if value.to_s == "NaN"
			# 		stmt = "quot_prod.#{key}=0.0"
			# 		eval(stmt)
			# 	end
			# end
			# render :string => quot_prod.to_json
		end

		def self.proposerLASameCopy
	        @insured.partyTypeCd = "INDIVIDUAL"
	        @insured.title = @policyHolder.title
	        @insured.otherTitle = @policyHolder.otherTitle
	        @insured.firstname = @policyHolder.firstname
	        @insured.middlename = @policyHolder.middlename
	        @insured.lastname = @policyHolder.lastname
	        @insured.extensionName = @policyHolder.extensionName
	        @insured.firstname2 = @policyHolder.firstname2
	        @insured.middlename2 = @policyHolder.middlename2
	        @insured.lastname2 = @policyHolder.lastname2
	        @insured.extensionName2 = @policyHolder.extensionName2
	        @insured.genderCd = @policyHolder.genderCd
	        @insured.dob = @policyHolder.dob
	        @insured.age = @policyHolder.age
	        @insured.relationCd = @policyHolder.relationCd
	        @insured.smoker = @policyHolder.smoker
	        @insured.industryCd = @policyHolder.industryCd
	        @insured.countryCd = @policyHolder.countryCd
	        @insured.contactNum = @policyHolder.contactNum
	        @insured.emailAddress = @policyHolder.emailAddress
	        @insured.natureOfDuty = @policyHolder.natureOfDuty
	        @insured.occupationCd = @policyHolder.occupationCd
	        @insured.nsap = @policyHolder.nsap
	        @insured.nationality = @policyHolder.nationality
	        if @insured.QuotationPartyAddressList.empty?
		        @policyHolder.QuotationPartyAddressList.each do |proposerPartyAdddress|
					primaryPartyAdddress = QuotationPartyAddress.new
					fieldsToExcludeArr = ["guid"]
					primaryPartyAdddress = MobiSys::CommonUtil.copyFields(proposerPartyAdddress, primaryPartyAdddress, fieldsToExcludeArr)
					@insured.addQuotationPartyAddress(primaryPartyAdddress)
		        end
		    else
		       @policyHolder.QuotationPartyAddressList.each do |proposerPartyAdddress|
					primaryPartyAdddressList = @insured.QuotationPartyAddressList
					primaryPartyAdddressList.each do|primaryPartyAdddress|
						if primaryPartyAdddress.addressTypeCd == proposerPartyAdddress.addressTypeCd
							fieldsToExcludeArr = ["guid"]
							primaryPartyAdddress = MobiSys::CommonUtil.copyFields(proposerPartyAdddress, primaryPartyAdddress, fieldsToExcludeArr)
							@insured.addQuotationPartyAddress(primaryPartyAdddress)
					    end
				    end		
		        end 
		    end
		end
		
		def self.runIllustration(quotation)
			quotationIO = MobiSys::IO::QuotationIO.new
			quotationIO.baseDO = quotation.cloneObject
			quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
			returnHash = {} 
			valueHash = {}
		
		
			if quotePlan.product == nil
				product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
			else
				product = quotePlan.product
			end 
			if product.getFacet('SISUMMARYRATESELEMENTS') == nil || product.getFacet('SISUMMARYELEMENTS') == nil
				return {"Error"=>"Facet missing in configuration"}
			end
			quotationIO.baseProduct = product

			MobiSys::ProductBO.loadModel("SIMODEL",quotationIO)

			quotationIO.listCalculation = []
			quotationIO.illustrationHeader = nil
			quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
			ratesFromFacet = product.getFacet('SISUMMARYRATESELEMENTS').actionValue.to_s.split(',')
			labelsFromFacet = []
			elementsFromFacet = []
			product.getFacet('SISUMMARYELEMENTS').actionValue.to_s.split(',').each do |element| 
				elementsFromFacet << ((element[0..0] =~ /[A-Z]/) ? element.downcase : element)
			end
			illustrationFacetMap = MobiSys::CommonUtil.getLinkedHashedList("computedElementName",quotationIO.illustrationModel.IllustrationFacetList)
			elementsFromFacet.each do |element|
				if(illustrationFacetMap != nil && illustrationFacetMap[element] != nil)
					labelsFromFacet.push(illustrationFacetMap[element].first.elementLabel)
				else
					labelsFromFacet.push(getLabelValue(element.to_s+"_lbl"))
				end
			end

			rates = {}
			rateOrder = []
			rates["NORATE"] = 0
			if quotationIO.illustrationModel != nil &&  quotationIO.illustrationModel.IllustrationRateList.size > 0
				rates = Hash.new
				quotationIO.illustrationModel.IllustrationRateList.each do |illusRate|
					# If rates are different for different policy year, multiple rates were displayed
					rateOrder << illusRate.rateTypeCd if !rateOrder.include?(illusRate.rateTypeCd)
					rates[illusRate.rateTypeCd] = MobiSys::Math.round(illusRate.rate,2)
				end
				rates.each_key do |rate|
					valueHash[rate] = {}
					valueHash[rate]["data"] = []
					elementsFromFacet.each do |t|
						valueHash[rate]["data"] << []
					end
				end
			else
				rateOrder << "NORATE"
				valueHash["NORATE"] = {}
				valueHash["NORATE"]["data"] = []
				elementsFromFacet.each do |t|
						valueHash["NORATE"]["data"] << []
				end
			end
			# elementsFromFacet.each_with_index do |ele,index|
			# 	valueHash[ele+ratesFromFacet[index]] = []
			# end
			freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(quotationIO.illustrationModel.computationFrequencyCd)
			computationCycles = quotationIO.baseProduct.productTerm.to_i * freqMultiplier           
			computationCyclesCheck = quotationIO.computationCycles
			
			age = quotationIO.baseDO.getPartyByRole("PRIMARY").age.to_i
			yearsToPrint = []
			ageToPrint = []
			(1..quotePlan.productTerm.to_i).each do |i|
				if(i.modulo(5) == 0 || (i == quotePlan.productTerm.to_i && quotePlan.productTerm.to_i.modulo(5) != 0))
                    yearsToPrint<< i
                end
			end   
			yearsToPrint.each do |policyYear|
				ageToPrint << age+policyYear
			end

			(1..quotePlan.productTerm.to_i).each do |policyYear|
				computationCycles = policyYear.to_i * freqMultiplier           
				rates.each_key do |rate|
					elementsFromFacet.each_with_index do |element, index|
						ele = (element[0..0] =~ /[A-Z]/) ? element.downcase : element
						rateToPass = (ratesFromFacet[index].to_s == "NORATE") ? nil : rate
						valueHash[rate]["data"][index] << getElementValue(quotationIO,ele,computationCycles,rateToPass)
					end
				end
			end
			rates.each_key do |rate|
				dataArray = valueHash[rate]["data"].flatten
				yMaxVal = dataArray.max
				valueHash[rate]["yMax"] = (( ( ( yMaxVal + (yMaxVal * 0.1 ) )  / 10000 ).to_i + 1 ) * 10000).to_f
				valueHash[rate]["toolTip"] = []
				valueHash[rate]["data"].each_with_index do |data,index|
					data.each_with_index do |x,i|
						num = x.to_f == 0 ? "0" : maskDecimal(x,"###,###,###").to_s
						valueHash[rate]["toolTip"] << "#{labelsFromFacet[index].to_s} = " + num.to_s + " Age = "  + (age + 1 + i).to_s
					end
				end
			end
			returnHash["yearsToPrint"] = yearsToPrint
			returnHash["ageToPrint"] = ageToPrint
			returnHash["calculatedData"] = valueHash
			returnHash["rateOrder"] = rateOrder
			returnHash["rates"] = rates #.each {|k,v| rates[k] = rates[k] * 100 }
			returnHash["ratesElements"] = ratesFromFacet
			returnHash["siSummaryElements"] = elementsFromFacet
			returnHash["elementLabel"] = labelsFromFacet
			return returnHash
		end

		def self.runIllustrationAndGenerateFinalMap(quotation)
			quotationIO = MobiSys::IO::QuotationIO.new
			quotationIO.baseDO = quotation.cloneObject
			quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
			returnHash = {}
			illustrationRateHM = {}
		
			if quotePlan.product == nil
				product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
			else
				product = quotePlan.product
			end 
			quotationIO.baseProduct = product

			MobiSys::ProductBO.loadModel("SIMODEL",quotationIO)

			quotationIO.listCalculation = []
			quotationIO.illustrationHeader = nil
			quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
		 	postGenerateIllustration(quotationIO)

		 	illustrationModelDO = quotationIO.illustrationModel
		 	#Create a new IllustrationRate hashmap
		 	illustrationRateDOsList = illustrationModelDO.IllustrationRateList
			illustrationRateDOsList.each do |illustrationRateDO|
				illustrationRateHM[illustrationRateDO.rateTypeCd.to_s] = illustrationRateDO.rate.to_s
			end
		 	iftList = illustrationModelDO.IllustrationFacetList.select {|ift| ift.outputDisplayTypeCd == "PARTOFHEADER" }
             partOfHeaderElementMap = {}
             iftList.each do |ift|
                 partOfHeaderElementMap[ift.computedElementName] = quotationIO.getIllustrationHeaderFieldValue(ift.computedElementName)
             end

            MobiSys::UIGenUtil.finalMapNew(quotationIO)
            returnHash['finalmap'] = quotationIO.finalMap
            returnHash['finalmap'].merge!(partOfHeaderElementMap)
            returnHash['rateMap'] = illustrationRateHM
			return returnHash
		end

		def self.getElementValue(quotationIO,elementName, computationCyclesCheck, rate)
			testVal = quotationIO.group_valueAsOf(elementName,computationCyclesCheck,rate)
			testVal = MobiSys::Math.roundNearest(testVal)
			return (testVal !=nil ? testVal.to_f : 0.0)
		end

	    def self.defaultOutputPreferences(outputPref)
	        outputPref.languageCd = "EN"
	        outputPref.field1 = "CHARTILLUSTRATION"
	        outputPref.field2 = "POLICYYEAR"
	        outputPref.field3 = "NO"
	        outputPref.field4 = "NO"
	        outputPref.field5 = "NO"
	        return outputPref
    	end

    	def self.getPortfolioModels(quotation,baseProduct,product)
	        offlineProductModelArray = []

	        fundDervFacet = product.getFacet("FUNDMODELDERIVATION")
	        if fundDervFacet
		        quotationIO = MobiSys::IO::QuotationIO.new
	            quotationIO.baseDO = quotation
	            quotationIO.baseProduct = baseProduct
	            fundDervFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(product.getTableTypeMappingSeq("FUNDMODELDERIVATION"), quotation, baseProduct, nil, quotationIO)
	            if fundDervFacetProductDef
	            	if fundDervFacetProductDef.outputAction.to_s != ""
	            		if quotationIO.baseProduct.portfolioModelCd.to_s != "" && quotationIO.baseProduct.portfolioModelCd.to_s != fundDervFacetProductDef.outputAction.to_s
	            			quotationIO.baseProduct.QuotationProductInvestmentFundList.each(&:delete)
	            			quotationIO.baseProduct.portfolioModelCd = fundDervFacetProductDef.outputAction
	            		end
	                	offlineProductModelArray = fundDervFacetProductDef.outputAction.split(',')
	                end
	            else
	                # if dt is not match then set port folio model cd as null and clear out fund records.
					# earlier this logic is there in angular,now moved here
					quotationIO.baseProduct.QuotationProductInvestmentFundList.each(&:delete)
					quotationIO.baseProduct.portfolioModelCd = nil
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

	        models = Model.loadObject(
	            :all, 
	            :conditions => {
	                {
	                    :name => 'modelCd',
	                    :op => 'IN'
	                    } => offlineProductModelArray
	                }
	            )

	        return models
    	end

    	def self.evaluateRider(quotation, formQuotationProduct, riderObject)
	        # first collecting forms quotation product only, it is required because later when we use convertToObjectWithMerge, it merges form state with DB state and series of modifications done on form are lost
	        # formQuotationProduct = MobiSys::BrowserHelper.convertToObjectList('QuotationProduct', @params['Quotation']['QuotationProduct'])
	        formQuotationProductObjectList = formQuotationProduct.collect{|fqp| fqp.object}
	        @quotation = quotation
	        # riderObject = @params['riderObject']
	        if riderObject
		        partyRefGuid = formQuotationProduct.select{|fqp| fqp.object == riderObject}[0].insuredPartyRefGuid
		        # partyRefGuid = @params['partyRefGuid']
		        @riderObjects = @params['riderInitialCount'].to_i if @params and @params.has_key?('riderInitialCount')
		        current_partyRoleCd = formQuotationProduct.select{|fqp| fqp.object == riderObject}[0].partyRoleCd
		    end
	        accordionKey = @params['accordionKey'] if @params and @params.has_key?('accordionKey')
	        accordionsToBeRefresh = []
	        
	        existingQuotationProducts = {}
	        impactedRidersHM = {}
	        @riderLoadingHash = {}
	        @displayRiderLifeHeader = {}
	        current_rider = nil
	        basePlan = nil
	        current_party = nil
	        # creating hash of existing riders with unique key & finding current rider to be evaluated
	        @quotation.QuotationProductList.each do |qp|
	            if formQuotationProductObjectList.include? qp.object
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
        	basePlan = @quotation.getBasePlan if basePlan == nil
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(basePlan.productSeq.to_s) if basePlan
	        basePlan.product = $currentProduct
	        
	        quotePartyList = @quotation.QuotationPartyList
	        quotePartyList.each do |party|
	            current_party = party if current_rider != nil && party.guid == current_rider.insuredPartyRefGuid
	        end
	        
	        facetRADO = $currentProduct.getFacet('RIDERASSOCIATION')
	        offlineRiderAssociationList = facetRADO.OfflineRiderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
	        listOfImpactedAssociations = []
	        listOfImpactedAssociations = MobiSys::QuotationBO.getImpactedRiderAssociation(current_rider.productSeq, current_rider.partyRoleCd, offlineRiderAssociationList, []) if current_rider != nil
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
	                if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
		                if (@quotation.proposerLASame == 'COPYFROMINSURED' || @quotation.proposerLASame == 'YES') && (evaluationParty.roleCd == 'PRIMARY' || evaluationParty.roleCd == 'PROPOSER')
		                    if current_party != nil && evaluationParty.guid == current_party.guid
		                        $displayRidersHM.delete('SAMEAS')
		                    else
		                        $displayRidersHM['SAMEAS'].reject! { |k, _| riderAssociationList.collect{|x|x.productSeq.to_s}.include? k }
		                    end
		                    accordionsToBeRefresh.push 'SAMEAS'
		                else
		                    if current_party != nil && evaluationParty.guid == current_party.guid
		                        $displayRidersHM.delete(evaluationParty.guid)
		                    else
		                        $displayRidersHM[evaluationParty.guid].reject! { |k, _| riderAssociationList.collect{|x|x.productSeq.to_s}.include? k } if $displayRidersHM[evaluationParty.guid]
		                    end
		                    accordionsToBeRefresh.push evaluationParty.guid
		                end
		            end
	                riderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
	                riderAssociationList.each do |offlineRiderAssociation|
	                    if offlineRiderAssociation.impactedRiders.to_s == "NA"
	                        impactedRidersHM[current_party.guid.to_s+'|'+offlineRiderAssociation.productSeq.to_s] = existingQuotationProducts[current_party.guid.to_s+'|'+offlineRiderAssociation.productSeq.to_s] if  current_rider != nil
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
	                        	#Added addDefaultBlankRiderFl flag for evaluateRider;if it is set to true add blank rider to show unselected riders on the UI.
	                            autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, evaluationParty, true)
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
	                                	#Added addDefaultBlankRiderFl flag for evaluateRider;if it is set to true add blank rider to show unselected riders on the UI.
	                                    autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, defTableDO, evaluationParty, true)
	                                else
	                                    @quotation.QuotationProductList.each do |qp|
	                                        if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && ((offlineRiderAssociation.planOptionCd.to_s != "" && offlineRiderAssociation.planOptionCd.to_s == qp.planOptionCd.to_s) || current_rider != nil && offlineRiderAssociation.planOptionCd.to_s == "") && qp.partyRoleCd.to_s == current_party.roleCd.to_s && qp.insuredPartyRefGuid.to_s == current_party.guid.to_s
	                                            qp.selected = "NO"
	                                            qp.removed = "YES"
	                                            break
	                                        end
	                                    end
	                                end
	                            else
	                                @quotation.QuotationProductList.each do |qp|
	                                    if qp.productSeq.to_s == offlineRiderAssociation.productSeq.to_s && ((offlineRiderAssociation.planOptionCd.to_s != "" && offlineRiderAssociation.planOptionCd.to_s == qp.planOptionCd.to_s) || offlineRiderAssociation.planOptionCd.to_s == "") && current_rider != nil && qp.partyRoleCd.to_s == current_party.roleCd.to_s && qp.insuredPartyRefGuid.to_s == current_party.guid.to_s
	                                        qp.selected = "NO"
	                                        qp.removed = "YES"
	                                        break
	                                    end
	                                end
	                            end
	                        end
	                    else
	                    	#Added addDefaultBlankRiderFl flag for evaluateRider;if it is set to true add blank rider to show unselected riders on the UI.
	                        autoPopulateRider(@quotation, impactedRidersHM, existingQuotationProducts, offlineRiderAssociation, nil, evaluationParty, true)
	                    end
	                end
	            end
	        end
	        msg = ""
	        errors = Hash.new
	        $taskExceptionHash = []
	        MobiSys::CommonUtil.clearTaskExceptionList(@quotation.guid)
	        if @params and @params.has_key?('sym_current_Tab') and !@quotation.visitedTabs.to_s.include?(@params['sym_current_Tab'])
	            @quotation.visitedTabs = @quotation.visitedTabs.to_s + "," + @params['sym_current_Tab']
	        end
	        impactedRiderProdSeqs = []
	        #Create an updated QuotationProductList which will have the BasePlan and the impacted as well as blank unselected riders to display on the UI.
	        finalQuotationProductList = []
	        finalQuotationProductList.push(basePlan)
	        impactedRidersHM.each do |key,rider|
	            impactedRiderProdSeqs.push "#{rider.insuredPartyRefGuid}|#{rider.productSeq}"
	            product = MobiSys::ProductUtil.getProduct(rider.productSeq)
	            extraFacet = product.getFacetValue('PRODUCTEXTRAREQUIRED').to_s == 'YES'
	            if rider.selected.to_s == 'YES' 
	                rider.removed = ''
	                if $rhoconfig[:contextBasedMetadata]
						classToFind = "#{@quotation.class.name}DO"

						if $contextMasterCache.has_key?(classToFind.to_sym)
							contextMasterList = $contextMasterCache[classToFind.to_sym]
							contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,@quotation)
						end
						MobiSys::Validation.processValidContexts(@quotation.hashForSync, contextMasterGeneratedArray, "QuotationSet")
						validationContextsPolicy = $globalContextObjectMap[@quotation.guid]
					else
						QuotationSet.setObject(@quotation)
						validationContexts = QuotationSet::ValidationContexts
						MobiSys::Validation.processValidContexts(@quotation.hashForSync, validationContexts, "QuotationSet")
					end
	                MobiSys::ProductBO.validate(@quotation, msg, errors, rider)
	                if extraFacet
	                    riderExtras, rider = MobiSys::QuotationBO.computeProductExtra(@quotation, rider)
	                else
	                    riderExtras = nil
	                end
	                @riderLoadingHash[rider.object] = riderExtras
	            else
	            	 if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
	                	rider.removed = 'YES'
	                end
	            end
	            finalQuotationProductList.push(rider)
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
	        currentTotalPremium = basePlan.modalPremium.to_f

	        #Add the non-impacted riders to the updated quotation product list and set it on the quotation to show on the UI.
	        formQuotationProduct.each do |rider|
	    		finalQuotationProductList.push(rider) if finalQuotationProductList.select{|qp| qp.productSeq == rider.productSeq}.size == 0
	    	end
	    	@quotation.setQuotationProductList(finalQuotationProductList)
	        
	        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
	        db.start_transaction
	        $taskExceptionHash.each do |taskException|
	            taskException.persistAll
	        end
	        db.commit
	        $taskExceptionHash = nil
	        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
	        ridersHM = MobiSys::BrowserHelper.deep_merge(existingQuotationProducts, impactedRidersHM)

	        if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
		        
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
	    end

	    def self.deleteQuotation(quotation)
	    	if quotation
	            MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
	            container = SignatureContainer.loadObject(:all,
                                    :conditions => {
                                    :entityGuid => quotation.guid
                                }
                            )
	            if container
	                container.each do|signature_container|
	                    signature_container.delete if signature_container
	                end
	            end

	            quotation.delete
	        end
	    end

	    def self.copyQuotation(srcQuotation, targetQuotation, isShow=true)
            if isShow ## show
                targetQuotation = srcQuotation.cloneObject
                targetQuotation.quotationRefNum = ""
                targetQuotation.quoteStatusCd = "PENDING"
                targetQuotation.entityStatus = nil
                targetQuotation.signature = ""
                targetQuotation.agentSignature = ""
                targetQuotation.productId = srcQuotation.productId
                targetQuotation.guid = nil
                targetQuotation.quotationDt = Time.now.strftime("%d/%m/%Y")
                targetQuotation.systemCreatedDt = ""
                targetQuotation.id = ''
                targetQuotation.fnaId = srcQuotation.fnaId
                targetQuotation.step = srcQuotation.step - 1 if srcQuotation.quoteStatusCd.to_s == "ACCEPTED"
       
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
                        if qp.QuotationPartyAddressList && qp.QuotationPartyAddressList.size > 0
                            qp.QuotationPartyAddressList.each do |qpa|
                                qpa.guid = qpa.object.gsub(".","_")
                                qpa.systemCreatedDt = ''
                                qpa.id = ''
                            end 
                        end
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
                targetQuotation.status = ""

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
                copiedQuotation.status = ""

                return copiedQuotation 
            end
        end

	    def self.commonShowBenefitTable
	        #puts "!!!!!!!!!!!!!!!!!!!!!!!!#{$quotationIO.inspect}"
	        #MobiSys::QuotationUtil.finalMapNew($quotationIO)
	        MobiSys::UIGenUtil.finalMapNew($quotationIO)
	        #puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#{$quotationIO.inspect}"
	        MobiSys::QuotationUtil.findTemplatePageMapping($quotationIO)
	        #puts "****************************************#{$quotationIO.inspect}"
	        MobiSys::UIGenUtil.getHtmlStringandGeneratePDF(true, $quotationIO, $apoQuotationIO)
	        #puts "****************************************#{$quotationIO.inspect}"
	    end

	    #Method to generate HTML source for online PDF generation based on offline HTML
	    def self.generateOutputHTML
	     	$showPdf = true
            commonShowBenefitTable()
            $showPdf = nil	        
	        filehtmlArray = Array.new
	        returnHash = {}
	        generateHTMLfor = "pdf"
	        generateHTMLfor = "email" if (@params and @params['emailRequestObj'].to_s != "") or $quotationIO.emailRequestDO.to_s != ""
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
	            if (@params and @params['outputPrefObj'].to_s != "") or $quotationIO.outputPreferencesDO.to_s != ""
	            	if $quotationIO.outputPreferencesDO.to_s != ""
	            		outputPreferencesDO = $quotationIO.outputPreferencesDO
	            	else
	                	outputPreferencesDO = OutputPreferences.loadObject(:first,:conditions=>{:object => @params['outputPrefObj']},:loadChild=>false)
	                end
	                if outputPreferencesDO
	                    syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
	                end
	            else
	                outputPreferencesDO = OutputPreferences.new
	                outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
	                outputPreferencesDO.persistAll
	                syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
	            end
	            if generateHTMLfor == "email"
	            	if $quotationIO.emailRequestDO.to_s != ""
	            		emailRequestDO = $quotationIO.emailRequestDO
	            	else
	                	emailRequestDO = EmailRequest.loadObject(:first,:conditions=>{:object => @params['emailRequestObj']},:loadChild=>false)
	            	end
	                if emailRequestDO
	                	jsonFileSuffix = emailRequestDO.outputPrefEntityGuid
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
	                returnHash['success'] = true
	            elsif !$CreateOutputFiles
	                clazz = Class.new do
	                    include MobiSys::BrowserHelper 
	                end
	                obj = clazz.new

	                if generateHTMLfor == "pdf"
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

	                    if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')

		                    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
		                    downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
		                    Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
		                    filePath = File.join(downloadFolder, fileName)
		                    File.delete(filePath) if File::exist?(filePath)

		                    decFCont = Base64.strict_decode64(resultsHash['PDFCONTENT'])
		                    File.open(filePath, 'wb') { |file| file.write(decFCont) }
		                    System.open_url(filePath)
		                 else
		                 	returnHash['PDFCONTENT'] = resultsHash['PDFCONTENT']
		                 end

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
	                        emailRequestDO.afterSync if generateHTMLfor == "email"
	                    end
	                    if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
		                    Alert.show_popup({
		                        :message => MobiSys::BrowserHelper.getLabel('EMAILSENT'),
		                        :title => '',
		                        :icon => :alert,
		                        :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
		                    })
		                else
		                	returnHash = response
		                end
	                end
	            end
	            if generateHTMLfor == "email"
	                errorPopup = getLabelValue('Email')
	            else
	                errorPopup = getLabelValue('ILLUSTRATIONDOWNLOAD')
	            end
	        rescue StandardError => se
	            puts "exception: #{se.backtrace}"
	            returnHash["error"] = getLabelValue('DOWNLOADFAILED',[errorPopup])
	        end
	        return returnHash
	    end

	    def self.get_pdf(quotation, outputPreferencesDO = nil)
	    	returnHash = {}
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
                if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
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
	            else
	            	returnHash['PDFCONTENT'] = resultsHash['PDFCONTENT']
	            end
            rescue StandardError => se
                puts "exception: #{se}"
                returnHash["error"] = getLabelValue('ILLUSTRATIONDOWNLOADFAILED')
                if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
	                Alert.show_popup({:title=>getLabelValue('ILLUSTRATIONDOWNLOAD'),
	                    :message=>getLabelValue('ILLUSTRATIONDOWNLOADFAILED'),
	                    :buttons=>["OK"]})
	                WebView.navigate("/app/Quotation/{#{quotation.object}}/show")
	            end
            end
            return returnHash
	    end

	    def self.initializeQuotationIO(quotation, outputPreferencesDO)
	    	quotationIO = MobiSys::IO::QuotationIO.new
            quotationIO.baseDO = quotation
            quotationIO.outputPreferencesDO = outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES"

            if quotationIO.outputPreferencesDO == nil
            	outputPref = OutputPreferences.new
                quotationIO.outputPreferencesDO = defaultOutputPreferences(outputPref)
            end

            quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
            puts "quotePlan.productSeq----#{quotePlan.productSeq}"
            if quotePlan.product == nil
                product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
            else
                product = quotePlan.product
            end  
            #Product.loadObject(:first, :conditions => {{ :name => 'id' } => quotePlan.productSeq})
            quotationIO.baseProduct = product
            preGenerateIllustration(quotationIO)
            quotationIO.illustrationModel = nil
            MobiSys::ProductBO.loadModel("SIMODEL",quotationIO)
            $quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
            postGenerateIllustration($quotationIO)
            return quotationIO
	    end

	    def self.postGenerateIllustration(quotationIO)
	        freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(quotationIO.illustrationModel.computationFrequencyCd)
	        basePlan = quotationIO.baseDO.getBaseProduct
	        if basePlan.productTerm == nil
	            # Alert.show_popup({:title=>'Solve Quotation',
	            # :message=>'Error: No product term entered. Evaluation runs for the entire product term.',
	            # :buttons=>["OK"]})
	        end
	        computationCycles = basePlan.productTerm * freqMultiplier

	        if ((quotationIO.listCalculation.size != computationCycles) || ("break" == quotationIO.group_valueAsOf("fundbreak",computationCycles,"LOW")))
	            #$taskExcDO = false
	            quotationIO.baseDO.taskExcDO = "error"
	        end
	    end


	    def self.preGenerateIllustration(quotationIO)
	        $apoQuotationIO = nil
	        puts "quotationIO.baseProduct.----#{quotationIO.baseProduct}"
	        $apoQuotationIO = MobiSys::APO.execute(quotationIO)  if quotationIO.baseProduct.getFacetFast('APOFINDFACET')
	        topupOptionCd = quotationIO.baseDO.topupOptionCd
	        puts ">>>topupOptionCd in quotation: #{topupOptionCd}"
			#This is commented for time being to run the solver based on model. remove the false condition to run this code.
	        if (topupOptionCd == "TFCALCULATIONWITHOUTPH" or topupOptionCd == "TFCALCULATIONWITHPH" or topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH") && false
	            computedFundValue = 0.0
	            basePlanQuote = quotationIO.baseDO.getBaseProduct
	            if basePlanQuote.productTerm == nil or basePlanQuote.productTerm == ""
	                puts "Error: No product term entered. Evaluation runs for the entire product term."
	                return
	            end  
	            targetFundVal = basePlanQuote.targetFundVal
	            return unless targetFundVal and targetFundVal.to_i != 0
	            targetFundValue = MobiSys::Math.roundDown(targetFundVal,0);
	            targetFundPeriod = basePlanQuote.targetPeriod
	            return unless targetFundPeriod and targetFundPeriod != 0
	            originalProductTerm = basePlanQuote.productTerm
	            targetPeriodRef = basePlanQuote.targetPeriodRefCd
	            if targetPeriodRef
	                if targetPeriodRef == "TARGETAGE"
	                    currentAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age
	                    targetFundPeriod = basePlanQuote.targetPeriod.to_i - currentAge.to_i
	                end  
	            end

	            basePlanQuote.productTerm = targetFundPeriod
	            regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	            unless regularQuotationTopup
	                regularQuotationTopup = QuotationTopUp.new
	                regularQuotationTopup.topUpAmount = 0
	                regularQuotationTopup.topUpTypeCd = "REGULARTOPUP"
	                quotationIO.baseDO.addQuotationTopUp regularQuotationTopup
	            end

	            orignalQuotation = quotationIO.baseDO
	            quotationIO.baseDO = orignalQuotation.cloneObject

	            #Ready to start calculations now.
	            #puts ">>>starting calculations with targetFundVal: #{targetFundVal}"          
	            regularExcess = regularQuotationTopup.topUpAmount
	            computedFundValue = 0.0
	            iterations = 0
	            requiredTopUpAmt = regularQuotationTopup.topUpAmount;
	            regularQuotationTopup.topUpPeriod = targetFundPeriod
	            puts"requiredTopUp:" + regularQuotationTopup.topUpAmount.to_s + "requiredTopUpAmt : "  + requiredTopUpAmt.to_s
	            # ProductBO productBO = (ProductBO)SymbiosysApplicationContext.getInstance().getApplicationContextObject("productBO",quotationIO.getCompanyDO().getCompanyCd());
	            # productBO.setDO(quotationIO.getBaseProduct());
	            # //productBO.loadModel(facetId, quotationIO);
	            # regularQuotationTopup.setTopUpPeriod(targetFundPeriod);
	            # System.out.println("requiredTopUp:" + regularQuotationTopup.getTopUpAmount() + "requiredTopUpAmt : "  + requiredTopUpAmt);
	            # MobiSys::ProductBO..loadModel("TARGETFUNDVALUECALC", quotationIO);
	            # # quotationIO.resetModelCalculation();
	            # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 

	            solveForTarget(quotationIO, regularExcess)
	            # PolicyDO policyDO = quotationIO.getPolicyDO();
	            computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	            puts"computedFundValue : " + computedFundValue.to_s

	            isComputedFundValueGreater=false;
	            if(computedFundValue > targetFundValue)
	                isComputedFundValueGreater=true;
	            end
	            puts"targetFundValue : " + targetFundValue.to_s

	            # noofpayingyears = targetFundPeriod;

	            # 11-13-2014
	            if(!isComputedFundValueGreater)
	                mintopup=0.0;
	                maxtopup=0.0;
	                if "PHP" == basePlanQuote.currencyCd
	                    maxtopup=500000;
	                    incrementBy = 500000;
	                elsif "USD"== basePlanQuote.currencyCd
	                    maxtopup=50000;
	                    incrementBy = 50000;
	                end
	                requiredAvgTopUp=0.0;
	                checkedAvgTopUp =0.0;
	                loop do 
	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	                    regularQuotationTopup.topUpAmount = maxtopup
	                    # //    productBO.loadModel(facetId, quotationIO);
	                    # quotationIO.resetModelCalculation();
	                    # quotationIO =  MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, maxtopup)

	                    computedFundValue =  MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    if(computedFundValue == 0)
	                        break;
	                    end

	                    if(computedFundValue < targetFundValue)
	                        mintopup=maxtopup;
	                        maxtopup=maxtopup+incrementBy;
	                    end
	                    puts"computedFundValue : #{computedFundValue}"
	                    break if !(computedFundValue <= targetFundValue);
	                end
	                puts"Got range value between : #{mintopup}  and #{maxtopup}"
	                loop do 
	                    if((("TFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd) || 
	                        ("EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd)) && ("PHP" == basePlanQuote.currencyCd))
	                        incrementBy=100;
	                    else
	                        incrementBy=1;
	                    end

	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

	                    requiredAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;

	                    regularQuotationTopup.topUpAmount = requiredAvgTopUp
	                    puts"requiredTopUp: " + regularQuotationTopup.topUpAmount.to_s

	                    # quotationIO.resetModelCalculation();
	                    # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, requiredAvgTopUp)

	                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    puts"computedFundValue " + computedFundValue.to_s
	                    if(computedFundValue == 0)
	                        break;
	                    end

	                    if(computedFundValue < targetFundValue)
	                        mintopup=requiredAvgTopUp;
	                    else
	                        maxtopup=requiredAvgTopUp;
	                    end
	                    checkedAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;
	                    puts"computedFundValue : #{computedFundValue.inspect}"
	                    break if !((checkedAvgTopUp < maxtopup) || (computedFundValue < targetFundValue));
	                end

	                regularQuotationTopup.topUpAmount = MobiSys::Math.roundUp(requiredAvgTopUp,0);

	            elsif (isComputedFundValueGreater && "EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd) 
	                noofpayingyears = targetFundPeriod;
	                decrementBy = 1;

	                loop do 
	                    noofpayingyears = noofpayingyears - decrementBy
	                    # //computedFundValue = requiredTopUp * 50 * 100;//TARGETFUNDVALUECALC model evaluation
	                    # //invoke the fund value calculation model to compute the fund value
	                    # //regularQuotationTopup.setTopUpPeriod(noofpayingyears);

	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

	                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	                    regularQuotationTopup.topUpAmount = requiredTopUpAmt
	                    puts"no of paying years:==3rd" + noofpayingyears.to_s
	                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	                    # //      productBO.loadModel(facetId, quotationIO);
	                    # quotationIO.resetModelCalculation();
	                    # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, requiredTopUpAmt)


	                    # computedFundValue = CommonUtil.getRoundedDownDouble(policyDO.getBasePlan().getTargetFundVal(),0);
	                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    puts"computedFundValue  : " + computedFundValue.to_s
	                    puts"targetFundValue   : " + targetFundValue.to_s
	                    if(computedFundValue == 0)
	                        break;      
	                    end      
	                    break if !( computedFundValue >= targetFundValue);
	                end
	                noofpayingyears = noofpayingyears + decrementBy
	                regularQuotationTopup.topUpPeriod = noofpayingyears
	                quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	            end
	            puts ">>>completed all loops: iterations: #{iterations} regularExcess: #{regularExcess}"
	            basePlanQuote.productTerm = originalProductTerm
	            orignalQuotation.getBasePlan.payingYears = quotationIO.baseDO.getBasePlan.payingYears

	            orignalQuotation.getRegularTopup.topUpAmount = quotationIO.baseDO.getRegularTopup.topUpAmount
	            quotationIO.baseDO = orignalQuotation

	            regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	            # regularQuotationTopup.topUpAmount = regularExcess
	            # quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears

	            quotationIO.illustrationModel = nil
	        end  
	        return quotationIO
	    end

	    def self.solveForTarget(quotationIO, regularExcess)
	        puts ">>>solveForTarget called for regularExcess: #{regularExcess}"
	        regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	        regularQuotationTopup.topUpAmount = regularExcess
	        puts ">>>after incrementing topUpAmount: #{quotationIO.baseDO.getRegularTopup.inspect}"
	        newQuotationIO = MobiSys::IO::QuotationIO.new
	        newQuotationIO.baseDO = quotationIO.baseDO
	        newQuotationIO.baseProduct = quotationIO.baseProduct
	        newQuotationIO.loopReference = regularExcess
	        MobiSys::ProductBO.loadModel("TARGETFUNDVALUECALC", newQuotationIO)
	        #newQuotationIO.loopReference = regularQuotationTopup.topUpAmount.to_s
	        MobiSys::ProductBO.callCalculateIllustration(newQuotationIO, 'TARGETFUNDVALUE')
	        computedFundValue = newQuotationIO.baseDO.getBaseProduct.targetFundVal
	        puts ">>>computedFundValue: #{computedFundValue}"
	        return computedFundValue
	    end

	    def self.changePlan(quotation, planOptionCd = nil)
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
            baseProduct = setBaseProductDetails(baseProduct, $currentProduct, quotation)
            baseProduct.productPlanOptionCd = planOptionCd if planOptionCd.to_s != ""
            quotation.addQuotationProduct(baseProduct)
            quotation.unselectedRiders = ""
            quotation.persistAll if quotation.quoteStatusCd.to_s != 'ACCEPTED' && quotation.quoteStatusCd.to_s != 'SYNCDONE'
        end

        def self.reopenQuotation(policy)
        	if policy
        		quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
        		quotation.entityStatus = "REOPEN"
        		quotation.step = 0
        		quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
        		quotation.policyNum = nil
        		signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => quotation.guid})
		        if signatureContainer
			        signatureContainer.ServiceSignatureList.delete_if do |signature|
					    signature.destroy
					    true
					end
				end
		        saveValidate(quotation)
		        return quotation
        	end
        end

        def self.refreshEapp(quotation)
        	if quotation
        		existingPolicyDO = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
        		if existingPolicyDO
        			# clone policy record so that company project retain some existing policy records fields in postCopyQuotationToPolicyAttributes
        			clonePolicyDO = existingPolicyDO.cloneObject
        			# just copy only quotation related fields and retain policy fields 
					currPolicyDO = copyQuotationToPolicyAttributes(quotation,existingPolicyDO);
					postCopyQuotationToPolicyAttributes(quotation,currPolicyDO,clonePolicyDO);
        			# save that merge policy do
        			currPolicyDO.versionID = existingPolicyDO.versionID
        			currPolicyDO.step = 0
        			currPolicyDO.guid = existingPolicyDO.guid
        			currPolicyDO.statusCd = "PENDING"
        			currPolicyDO.persistAll
        			return currPolicyDO
        		end
        	end
        end

        def self.postCopyQuotationToPolicyAttributes(quotation,currPolicyDO,clonePolicyDO)
        end

        def self.copyQuotationToPolicyAttributes(quotation,policy)
        	# copy quotation related fields to policy do
			fieldsToExcludeArr = ["guid"]
        	policy = MobiSys::CommonUtil.copyFields(quotation, policy, fieldsToExcludeArr)
			policy.proposalEntryDt = quotation.quotationDt
			policy.proposalReceivedDt = quotation.quotationDt
			policy.proposalSignedDt = quotation.quotationDt
			quotation.issueDt = quotation.quotationDt if quotation.issueDt.to_s == ""
			policy.policyIssueDt = quotation.issueDt
			policy.riskCommencementDt = quotation.quotationDt
			quoteBasePlan = quotation.getBasePlan
			if quoteBasePlan
				policy.baseProductId = quoteBasePlan.productId
				policy.baseProductVersion = quoteBasePlan.productVersion
				policy.baseProductTypeCd = quoteBasePlan.productTypeCd
				policy.baseProductFamilyCd = quoteBasePlan.productFamilyCd
			end
			policy.quoteProposerSameAsInsured = quotation.proposerLASame
			policy.baseAgentId = $userId

			#copy quotation party related fields to policy party
			copyQuotationPartyToPolicyPartyAttributes(quotation,policy)
			#create new quotation product and copy product related fields
			copyQuotationProductToPolicyProductAttributes(quotation,policy)
			#create new quotation top up and withdraw and copy related fields
			copyQuotationExtra(quotation,policy)
			#copy quotation additional field into 000 type of policy additional fields and reatin other fields
			copyAdditionalFields(quotation,policy)

			# for changing quotation party guid ref in unselectedRiders
			quotationPartyAndPolicyPartyGuidMap = {}
			policy.PartyList.each do |partyDO|
				quotationPartyAndPolicyPartyGuidMap[partyDO.quotationPartyGuid] = partyDO.guid
			end

			riders = []
			partyGuids = []
			unselectedRiders = quotation.unselectedRiders
			if unselectedRiders.to_s != ""
				riders = unselectedRiders.split("|");
				partyGuids = Array.new(riders.length)
				riders.each_with_index do |rider, i|
					values = rider.split(/\s*:\s*/)
					partyGuids[i] = values[0]
				end
				unselectedRiders = ""
			end

			if partyGuids.to_s != ""
				partyGuids.each_with_index do |guid, i|
					partyGuids[i] = quotationPartyAndPolicyPartyGuidMap[guid]
					rider = riders[i]
					oldPrdSeq = rider.split(":").last
					unselectedRiders += "#{partyGuids[i]}:#{oldPrdSeq}|"
				end
			end
			policy.unselectedRiders = unselectedRiders
			return policy
        end

        def self.copyQuotationPartyToPolicyPartyAttributes(quotation, policy)
        	# TODO new supplementary case need to handle in policy
        	quotation.QuotationPartyList.each do |quoteParty|
        		if quotation.proposerLASame.to_s == "YES"
        			if quotation.proposerLACopyCd.to_s == "PROPOSERCOPIEDFROMLA"
        				if quoteParty.roleCd.to_s == "PROPOSER"
        					next
        				end
        			elsif quotation.proposerLACopyCd.to_s == "LACOPIEDFROMPROPOSER" || quotation.proposerLACopyCd.to_s == ""
        				if quoteParty.roleCd.to_s == "PRIMARY"
        					next
        				end
        			end
        		end
        		# just copy party related fields
        		policy.PartyList.each do |party|
        			if (quoteParty.roleCd.to_s == party.roleCd.to_s || (party.roleCd.to_s == "PROPCUMINS" && (quoteParty.roleCd.to_s == "PROPOSER" || quoteParty.roleCd.to_s == "PRIMARY")))
						fieldsToExcludeArr = ["guid"]
        				party = MobiSys::CommonUtil.copyFields(quoteParty, party, fieldsToExcludeArr)
						party.quotationPartyGuid = quoteParty.guid
						party.firstName1 = quoteParty.firstname
						party.lastName1 = quoteParty.lastname
						party.middleName1 = quoteParty.middlename
						party.firstName2 = quoteParty.firstname2
						party.lastName2 = quoteParty.lastname2
						party.middleName2 = quoteParty.middlename2
						party.corporateName1 = quoteParty.corporateName
						party.titleCd = quoteParty.title
						party.nonResidentFl = quoteParty.nsap
						party.occupationClass = quoteParty.occupationCd
						party.educationLevelCd = quoteParty.educationCd
						party.birthDt = quoteParty.dob
						party.extensionName1 = quoteParty.extensionName
						party.citizenshipCd = quoteParty.nationality

						# copy employment related fields
						if party.getListPartyEmploymentList.to_s != "" && party.getListPartyEmploymentList.size > 0
							partyEmploymentDO = party.getListPartyEmploymentList[0]
							if partyEmploymentDO.to_s != ""
								partyEmploymentDO.natureOfDuty = quoteParty.natureOfDuty
								partyEmploymentDO.industryCd = quoteParty.industryCd
								partyEmploymentDO.occupationCd = quoteParty.occupationCd
								if quoteParty.monthlyIncome.to_s != "" && quoteParty.monthlyIncome > 0
									partyEmploymentDO.annualIncome = quoteParty.monthlyIncome
								else
									partyEmploymentDO.annualIncome = quoteParty.annualIncome
								end
							end
						end

						# copy contact related fields
						partyContactDO = party.getPartyContact("MOBILE")
						if partyContactDO.to_s != ""
							partyContactDO.countryCd = quoteParty.isdCode
							partyContactDO.contactNum = quoteParty.contactNum
							partyContactDO.stdCode = quoteParty.stdCode
						end

						# copy email address related fields
						partyEmailDO = party.getPartyEmail
						if partyEmailDO.to_s != ""
							partyEmailDO.emailAddress = quoteParty.emailAddress
						end

						# copy party identity related fields
						if quoteParty.idType.to_s != ""
							partyIdentityDO = party.getPartyIdentity(quoteParty.idType)
							if partyIdentityDO.to_s != ""
								partyIdentityDO.identityNum = quoteParty.idNumber
							end
						end

						# copy party address related fields
						quoteParty.QuotationPartyAddressList.each do |quotationPartyAddressDO|
							party.PartyAddressList.each do |partyAddressDO|
								if quotationPartyAddressDO.addressTypeCd.to_s != "" && party.addressTypeCd.to_s != "" && quotationPartyAddressDO.addressTypeCd.to_s == party.addressTypeCd.to_s
									fieldsToExcludeArr = ["guid"]
									partyAddressDO = MobiSys::CommonUtil.copyFields(quotationPartyAddressDO, partyAddressDO, fieldsToExcludeArr)
								end
							end
						end
        				break
        			end
        		end # end of policy party looup
        	end # end of QuotaionParty looup        	
        end

        def self.copyQuotationProductToPolicyProductAttributes(quotation, policy)
        	quoteBasePlan = quotation.getBasePlan
        	policyProductDOList = []
        	policy.PolicyProductList.each do |ppd|
			    ppd.removed = "YES"
			end
			policy.persistAll
        	quotation.QuotationProductList.each do |quotationProductDO|
        		# create new product do and copy product related fields
        		policyProductDO = PolicyProduct.new
        		fieldsToExcludeArr = ["guid"]
        		policyProductDO = MobiSys::CommonUtil.copyFields(quotationProductDO, policyProductDO, fieldsToExcludeArr)
        		# store reference of quotation product guid in policyproduct since required during comparison later.
        		policyProductDO.holderRefGuid = quotationProductDO.guid
        		if quotationProductDO.pdfPeriod.to_s == ""
        			policyProductDO.pdfPeriod = 0
        		else
        			policyProductDO.pdfPeriod = quotationProductDO.pdfPeriod
        		end
        		if policyProductDO.annualIncome.to_s == "" && quoteBasePlan.annualIncome.to_s != ""
					policyProductDO.annualIncome = quoteBasePlan.annualIncome
				end
				policyProductDO.monthlyIncome = quotationProductDO.monthlyIncome
				if policyProductDO.monthlyIncome.to_s == "" && quoteBasePlan.monthlyIncome.to_s != ""
					policyProductDO.monthlyIncome = quoteBasePlan.monthlyIncome
				end
				if policyProductDO.partyRoleCd.to_s == ""
					policyProductDO.partyRoleCd = "PRIMARY"
				end
				if quotationProductDO.pdfFrequencyVal.to_s == ""
        			policyProductDO.pdfFrequencyVal = 0
        		else
        			policyProductDO.pdfFrequencyVal = quotationProductDO.pdfFrequencyVal
        		end

        		# add wop flag
        		policyProductDO.isWOP = isWOP(policyProductDO, policy)

        		# create PolicyProductInsured
        		prid = PolicyProductInsured.new
        		prid.insuredSequenceTypeCd = policyProductDO.partyRoleCd
        		prid.roleCd = policyProductDO.partyRoleCd
        		roleParty = nil
        		if quotationProductDO.insuredPartyRefGuid.to_s != ""
        			# if primary and proposer are different and rider taken by proposer,after changing into primary proposer same case then need to set proper party guid on rider.
        			if quotation.proposerLASame.to_s == "YES" && policy.getPartyDOByGuid(quotationProductDO.insuredPartyRefGuid).to_s == ""
        				roleParty = policy.getPartyByRole("PROPCUMINS")
        				if roleParty.to_s != ""
        					prid.refGuid = roleParty.guid
        					policyProductDO.insuredPartyRefGuid = roleParty.guid
        				end
        			else
        				prid.refGuid = quotationProductDO.insuredPartyRefGuid
        				policyProductDO.insuredPartyRefGuid = quotationProductDO.insuredPartyRefGuid
        				roleParty = policy.getPartyDOByGuid(quotationProductDO.insuredPartyRefGuid)
        			end
        			# setting Combined Entry Age For Rider
        			if roleParty.to_s != ""
        				policyProductDO.combinedEntryAge = roleParty.age
        			end
        		else
        			roleParty = policy.getPartyByRole(policyProductDO.partyRoleCd)
        			if roleParty.to_s != ""
    					prid.refGuid = roleParty.guid
    					policyProductDO.insuredPartyRefGuid = roleParty.guid
    					# setting Combined Entry Age For Rider
    					policyProductDO.combinedEntryAge = roleParty.age
    				end
        		end
        		# setting combined Entry Age back to persist 
        		quotationProductDO.combinedEntryAge = policyProductDO.combinedEntryAge
        		policyProductDO.addPolicyProductInsured(prid)

        		quotationProductDO.QuotationProductExtraList.each do |quotationProductExtraDO|
                	policyProductExtraDO = PolicyProductExtra.new
        			fieldsToExcludeArr = ["guid"]
                	policyProductExtraDO = MobiSys::CommonUtil.copyFields(quotationProductExtraDO, policyProductExtraDO, fieldsToExcludeArr)
        			policyProductDO.addPolicyProductExtra(policyProductExtraDO)
                end

                quotationProductDO.QuotationProductAdditionalList.each do |quotationProductAdditionalDO|
                	policyProductAdditionalDO = PolicyProductAdditional.new
        			fieldsToExcludeArr = ["guid"]
                	policyProductAdditionalDO = MobiSys::CommonUtil.copyFields(quotationProductAdditionalDO, policyProductAdditionalDO, fieldsToExcludeArr)
        			policyProductDO.addPolicyProductAdditional(policyProductAdditionalDO)
                end

                if policyProductDO.productTypeCd.to_s == "PLAN"
                	policy.baseProductSeq = policyProductDO.productSeq
	                quoteBasePlan.QuotationProductInvestmentFundList.each do |qpif|
	                	if qpif.allocationPerc.to_s != "" && qpif.topupAllocationPerc.to_s != ""
		                	ppif = PolicyProductInvestmentFund.new
		        			fieldsToExcludeArr = ["guid"]
		                	ppif = MobiSys::CommonUtil.copyFields(qpif, ppif, fieldsToExcludeArr)
		        			policyProductDO.addPolicyProductInvestmentFund(ppif)
		        		end
	                end
	            end
	            policyProductDOList.push(policyProductDO)
        	end
        	policy.setPolicyProductList(policyProductDOList)
        end

        def self.isWOP(policyProductDO, policy)
			isWOP = false;
			if( policyProductDO.productTypeCd == "RIDER" )
				otherDetailsFacet = policyProductDO.getProduct.getOtherDetailsFacet.OfflineOtherDetailsList[0] if policyProductDO.getProduct.getOtherDetailsFacet
				if otherDetailsFacet != nil && otherDetailsFacet.isWOPFl != nil && otherDetailsFacet.isWOPFl == "YES"
				   isWOP = true
				end
		   end
		   return isWOP
		end

        def self.copyQuotationExtra(quotation, policy)
        	# Copy topup related fields as well .. Create new list and copy and reset all.
        	quotation.QuotationTopUpList.each do |quotationTopUpDO|
        		policyTopUpDO = PolicyTopUp.new
        		fieldsToExcludeArr = ["guid"]
        		policyTopUpDO = MobiSys::CommonUtil.copyFields(quotationTopUpDO, policyTopUpDO, fieldsToExcludeArr)
        		policy.addPolicyTopUp(policyTopUpDO)
        	end
        	# Copy withdrawal related fields as well .. Create new list and copy and reset all.
        	policyWithdrawalList = []
        	quotation.QuotationWithdrawalList.each do |quotationWithdrawalDO|
        		policyWithdrawalDO = PolicyWithdrawa.new
        		fieldsToExcludeArr = ["guid"]
        		policyWithdrawalDO = MobiSys::CommonUtil.copyFields(quotationWithdrawalDO, policyWithdrawalDO, fieldsToExcludeArr)
        		policyWithdrawalList.push(policyWithdrawalDO)
        	end
        	policy.policyWithdrawalList = policyWithdrawalList
        end

        def self.copyAdditionalFields(quotation, policy)
        	# copy quotation additional field into 000 type of policy additional fields and reatin other fields
        	if quotation.getQuotationAdditionalFieldsDO.to_s != ""
        		quotation.getQuotationAdditionalFieldsDO.each do |quotationAdditionalFieldsDO|
        			policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
        				if policyAdditionalFieldsDO.additionalTypeCd.to_s == "000"
				        	fieldsToExcludeArr = ["guid"]
		        			policyWithdrawalDO = MobiSys::CommonUtil.copyFields(quotationAdditionalFieldsDO, policyAdditionalFieldsDO, fieldsToExcludeArr)
				        	break
			        	end
			        end
        		end
        	end
        end

        def self.setPartyFields(quotation)
        	if quotation
	        	quotation.QuotationPartyList.each do |quotationPartyDO|
	        		if quotationPartyDO.partyTypeCd.to_s == "INDIVIDUAL"
	        			quotationPartyDO.corporateName = nil
	        			quotationPartyDO.corporateName2 = nil
	        		elsif quotationPartyDO.partyTypeCd.to_s == "ORGANIZATION"
	        			quotationPartyDO.title = nil
						quotationPartyDO.firstname = nil
						quotationPartyDO.firstname2 = nil
						quotationPartyDO.lastname = nil
						quotationPartyDO.middlename = nil
						quotationPartyDO.middlename2 = nil
						quotationPartyDO.smoker = nil
						quotationPartyDO.lastname2 = nil
						quotationPartyDO.dob = nil
						quotationPartyDO.genderCd = nil
						quotationPartyDO.age = nil
						# quotationPartyDO.nsap = nil
						quotationPartyDO.coverageCityCd = nil
						quotationPartyDO.coverageCountryCd = nil
						quotationPartyDO.maritalStatus = nil
						quotationPartyDO.idType = nil
						quotationPartyDO.idNumber = nil
						quotationPartyDO.industryCd = nil
						quotationPartyDO.natureOfDuty = nil
						quotationPartyDO.occupationCd = nil
	        		end
	        	end
	        end
        end

        def self.generateOfflinePDFHTML
	    	returnHash = {}
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

	        $quotationIO.offlinePDFGeneration = "true"
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
	            returnHash['pdfFileName'] = pdfFileName
	            # Rho::System.openUrl(pdfFileName)
	        rescue StandardError => se
	        	puts "exception: #{se.backtrace}"
	            returnHash["error"] = getLabelValue('ILLUSTRATIONDOWNLOADFAILED',[errorPopup])
	        end
	        return returnHash
	        # redirect :action => :show, :id => $quotationIO.baseDO.object, :layout => :jazzLayout
	    end

	end
end

begin 
    require 'Quotation/quotation_service_company'
rescue LoadError => e
    puts 'quotation_service_company not included'
end
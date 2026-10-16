require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'Product/product_util'
require 'Quotation/quotation_service'
require 'time'


module MobiSys
	class QuotationUtil

		def self.setBaseProductDetail(quotationIO, prdDO)
			if quotationIO.baseProduct == nil and prdDO != nil
				if prdDO.product
					quotationIO.baseProduct prdDO.product
					return
				end	

				productDO = nil
				if prdDO.productSeq != nil
					productDO = Product.loadObject(:first,:conditions=>{{:name=>'id'}=>prdDO.productSeq})
					quotationIO.baseProduct = productDO
					prdDO.product = productDO
				else	
					if prdDO.productId
						products = Product.loadObject(:all,:conditions=>{{:name=>'productId'}=>prdDO.productId},:order=>'launchDt',:orderdir=>'DESC')
						foundProduct = nil
						products.each do |prd|
							foundProduct = prd
							if prd.launchDt and quotationIO.baseDO.quotationDt and Time.parse(prd.launchDt.to_s) <= Time.parse(quotationIO.baseDO.quotationDt.to_s)
								break
							else
								next
							end
						end
						puts ">>>foundProduct: #{foundProduct.inspect}"
						if foundProduct
							quotationIO.baseProduct = foundProduct
							prdDO.productId = foundProduct.productId
							prdDO.productSeq = foundProduct.id
							prdDO.productVersion = foundProduct.productVersion
						end	
					end
				end	
			end	
		end

		def self.finalMapNew(quotationIO)
	    #view = quotationIO.illustrationModel.xslTemplateName
	    @listCalculation = quotationIO.listCalculation
	    illustration_model = quotationIO.illustrationModel

	    elemMap = CommonUtil.convertToHash(illustration_model.IllustrationFacetList, 'computedElementName')
	    finalMap = {}

	    isMonthly = (illustration_model.computationFrequencyCd == 'MONTHLY') ? true : false

	    tabArrayList = Array.new

	    @listCalculation.each_with_index do |calcRes, row|
	      if isMonthly && (calcRes.id % 12) != 0
	        next
	      end

	      colCount = 0
	      fieldsToBeDisplPostRates = Array.new
	      calcRes.fieldValueList.each do |calcCol|
	      	colCount += 1
	      	facetDO = elemMap[calcCol.fieldCd]
	      	if facetDO.outputDisplayTypeCd
	      		if facetDO.computationOrder and facetDO.computationOrder == colCount
	      			if not tabArrayList.include? facetDO.computationOrder
	      				finalMap[facetDO.computationOrder] = calcCol.fieldValue
	      			end	#if not tabArrayList.include? facetDO.computationOrder
	      		elsif facetDO.computationOrder
	      			fieldsToBeDisplPostRates.push calcCol
	      		end	#if facetDO.computationOrder and facetDO.computationOrder == colCount
	      	end	#if facetDO.outputDisplayTypeCd
	      end	#calcRes.fieldValueList.each do |calcCol|

	      fieldsToBeDisplPostRates.each do |calcCol|
	      	facetDO = elemMap[calcCol.fieldCd]
	      	if facetDO and facetDO.outputDisplayTypeCd
	      		if not tabArrayList.include? facetDO.computationOrder
	      			finalMap[facetDO.computationOrder] = calcCol.fieldValue
	      		end	#if not tabArrayList.include? facetDO.computationOrder
	      	end	#if facetDO and facetDO.outputDisplayTypeCd
	      end	#fieldsToBeDisplPostRates.each do |calcCol|

	      calcRes.fieldResultList.each do |innerCalc|
	      	innerCalc.fieldValueList.each do |calcCol|
	      		facetDO = elemMap[calcCol.fieldCd]
	      		if facetDO.outputDisplayTypeCd
	      			if not tabArrayList.include? facetDO.computationOrder
	      				if calcCol.fieldValue.include? "-"
	      					finalMap[facetDO.computationOrder] = "0"
	      				else
	      					finalMap[facetDO.computationOrder] = calcCol.fieldValue
	      				end	#if calcCol.fieldValue.include? "-"
	      			end #if not tabArrayList.include? facetDO.computationOrder	
	      		end #if facetDO.outputDisplayTypeCd	
	      	end	#innerCalc.fieldValueList.each do |calcCol|
	      end	#calcRes.fieldResultList.each do |innerCalc|
	      quotationIO.finalMap = finalMap
	    end
	  end


		def self.findTemplatePageMapping(quotationIO)
	  		quotationProduct = quotationIO.baseDO.getBaseProduct
		  	currency = quotationProduct.currencyCd
		  	
		  	product = quotationIO.baseProduct.productId
			productVersion = quotationProduct.productVersion

		  	finalTemplatePageMappingDOList = {}
		  	quot_prod = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
	  		offlineFacet = quot_prod.getFacet("SITEMPLATEID")
		  	if offlineFacet
  				template = TemplateMaster.loadObject(:first, :conditions=> {'templateId' => offlineFacet.actionValue})
  				templatePageMappingDOList = TemplatePageMapping.loadObject(:all, :conditions=> {'templateMasterSeq' => template.id}, :order=>'displayOrder', :orderdir=>'ASC')
  				templatePageMappingDOList.each do |templatePageMappingDOListev|
					groupCd = templatePageMappingDOListev.groupCd.to_s != "" ? templatePageMappingDOListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDOListev)
				end
	  			$quotationIO.templatePageMappingDO = finalTemplatePageMappingDOList
		  	else
			  	queryString = "Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where 
			  		outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq 
					  and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null) and tpmDO.displayOrder < 501 and (outputDO.productVersion = '#{productVersion}' or outputDO.productVersion is null ) order by tpmDO.displayOrder"
			  	puts "queryString: #{queryString}"
			  	templatePageMappingDOList = TemplatePageMapping.find_by_sql(queryString)
				templatePageMappingDOList.each do |templatePageMappingDOListev|
					groupCd = templatePageMappingDOListev.groupCd.to_s != "" ? templatePageMappingDOListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDOListev)
				end

				riderList = quotationIO.baseDO.getRiders

				riderListString = ""
				maxElement = riderList.size
				riderList.each_with_index do |rider, i|
				  riderListString << "'#{rider.productId}'"
				  riderListString << "," if i < maxElement - 1
				end

				queryString = "Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null) and outputDO.productVersion = '#{productVersion}' and tpmDO.rider in (#{riderListString}) and tpmDO.displayOrder > 500 
						order by tpmDO.displayOrder,tpmDO.rider"
				puts ">>>queryString: #{queryString}"
				unless riderList == []
					templatePageMappingDORiderList = TemplatePageMapping.find_by_sql(queryString)
					puts ">>>templatePageMappingDORiderList: #{templatePageMappingDORiderList.inspect}"
					#finalTemplatePageMappingDOList << templatePageMappingDORiderList
					templatePageMappingDORiderList.each do |templatePageMappingDORiderListev|
						groupCd = templatePageMappingDORiderListev.groupCd.to_s != "" ? templatePageMappingDORiderListev.groupCd.to_s : 'NoGroupCd'
						finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
						finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDORiderListev)
					end
				end

				templatePageMappingList = TemplatePageMapping.find_by_sql("Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where 
					outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null)  and tpmDO.displayOrder > 800 and (outputDO.productVersion = '#{productVersion}' or outputDO.productVersion is null )
					order by tpmDO.displayOrder")

				#finalTemplatePageMappingDOList << templatePageMappingList
				templatePageMappingList.each do |templatePageMappingListev|
					groupCd = templatePageMappingListev.groupCd.to_s != "" ? templatePageMappingListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingListev)
				end
				puts ">>>finalListSize: #{finalTemplatePageMappingDOList.size}"
				$quotationIO.templatePageMappingDO = finalTemplatePageMappingDOList
			end
	  	end

	  	def self.checkProductApplicable(quotation)
	        #Here check if product id is present then if this product is still applicable based on party attributes.
	        #eg. if party age/gender has changed or Joint / Supplementary life is added.. the product may not support such features.
	        #In this case instead of raising an error we need to reset all product data as user is not going to change age/gender etc.
	        #This check is only required for quotation
	        if quotation.getBasePlan != nil && quotation.getBasePlan.productId.to_s != ""
	            currentQuotationProduct = quotation.getBasePlan
	            productPlanOptionHash = {}
	            productIdList = []
	            $prdSelectionFacet ||= $rhoconfig[:prdSelection]
				prdSelectionFacetValue = MobiSys::ProductUtil.getCompanyFacetValue($prdSelectionFacet)
				productsByUser = []
				#Add the current productid to the list of products by user since we need to check only against this product
				productsByUser << currentQuotationProduct.productId
				#If product selection facet exists then return only those products that are applicable based on data from the list of allowed products for  user
				if prdSelectionFacetValue.to_s != ""
					prdSelectionProductHash, applicableProducts = MobiSys::ProductUtil.filterProducts(quotation, prdSelectionFacetValue, productsByUser)
					clearProductData = false
			
					if applicableProducts != nil
						if applicableProducts.select{|prod| prod.productId == currentQuotationProduct.productId}.size == 0
							clearProductData = true
						else
							#if it contains product id then go ahead and compare if the plan option is present
							applicableProduct = applicableProducts.select{|prod| prod.productId == currentQuotationProduct.productId}.first
							MobiSys::ProductUtil.populateProductPlanOptions(applicableProduct, prdSelectionProductHash, productPlanOptionHash)
							clearProductData = true if(currentQuotationProduct.productPlanOptionCd.to_s != "" && !productPlanOptionHash.empty? && productPlanOptionHash.select{|planCd, planOptionList| planOptionList.select{|planOption| planOption['cd'] == currentQuotationProduct.productPlanOptionCd}}.size == 0)
						end
					end

					if clearProductData
						$currentProduct = Product.new
						MobiSys::QuotationService.changePlan(quotation)
						newQuotProd = quotation.getBasePlan
						newQuotProd.product = $currentProduct
					end
				end
	        end
	    end

	end
end

begin 
    require 'Quotation/quotation_util_company'
rescue LoadError => e
    puts 'quotation_util_company not included'
end
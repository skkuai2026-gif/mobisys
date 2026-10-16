require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationPlanModel < BaseModel

        def initialize(io)
            # logInfo "~~~in QuotationPlanModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in getQuotationPlan:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
            quotationProduct = self.parentBaseDO.getBasePlan

            if quotationProduct == nil
                quotationProduct = QuotationProduct.new
                quotationProduct.productTypeCd = "PLAN"
                quotationProduct.topUpAllocSameAsPremAllocFl = "YES"
                self.parentBaseDO.addQuotationProduct(quotationProduct)
            end

            if quotationProduct
                product ||= MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
                #Display currencyCd by default if only one exists
                if (quotationProduct.currencyCd.to_s == "" && quotationProduct.productSeq.to_s != "")
                    premiumFacet = product.getFacet('PREMIUMDETAILS')
                    premiumFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
                        currencyCdCodes = offlinePremiumDetail.currencyCd.split(',').map { |s| s.strip }.reject(&:empty?)
                        if currencyCdCodes.count == 1
                            quotationProduct.currencyCd = currencyCdCodes[0]
                        end
                    end
                end

                if (quotationProduct.portfolioModelCd.to_s == "" && quotationProduct.productSeq.to_s != "")
                    modelArray = []
                    if product
                        #Set productPlanOptionDesc
                        quotationProduct.productPlanOptionDesc = quotationProduct.getProductPlanOptionDesc
                        models = MobiSys::QuotationService.getPortfolioModels(self.parentBaseDO,quotationProduct,product)

                        models.each do |modelFund|
                            if modelFund.modelCd != nil
                                modelLookup = Lookupvalue.new
                                modelLookup.cd = modelFund.modelCd
                                modelLookup.desc = modelFund.modelDesc
                                modelArray.push(modelLookup)
                            end
                        end
                        if modelArray.count == 1 
                            quotationProduct.portfolioModelCd = modelArray[0].cd
                        end
                    end
                end
                #default the premium type from product to the payment type of quotation since this seems to be used everywhere in Output
                if(quotationProduct.paymentTypeCd.to_s == "")
                    if(product != nil)
                        premiumFacet = product.getFacet('PREMIUMDETAILS')
                        if(premiumFacet != nil) 
                            premiumFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
                                premiumTypeCd = offlinePremiumDetail.premiumTypeCd
                                if(premiumTypeCd.to_s != "") 
                                    premiumCdList = premiumTypeCd.split(",")
                                    if(premiumCdList.size == 1)
                                        quotationProduct.paymentTypeCd = premiumCdList[0]
                                    end
                                end
                            end
                        end
                    end
                end

                if product
                    premiumFacet = product.getFacet('PREMIUMDETAILS')
                    if premiumFacet
                        premiumFacet.OfflinePremiumDetailsList.each do |offlinePremiumDetail|
                            quotationProduct.premiumSAFl = (offlinePremiumDetail.premiumSAFl.to_s == "" ? "SA" : offlinePremiumDetail.premiumSAFl)
                        end
                    end
                end

                if quotationProduct.topUpAllocSameAsPremAllocFl.to_s == ""
                    quotationProduct.topUpAllocSameAsPremAllocFl = "YES"
                end
                if(quotationProduct.targetPeriod == nil && quotationProduct.productTerm.to_i != 0) 
                    quotationProduct.targetPeriod = quotationProduct.productTerm
                end
                @productIdVersion = ((quotationProduct.productId.to_s != "" and quotationProduct.productVersion.to_s != "") ? "#{quotationProduct.productId.to_s}_#{quotationProduct.productVersion.to_s}" : nil)
                quotationProduct.status = ""
            end

			return quotationProduct
		end

        def setModel(entity)
            if entity
                currentProductIdVersion = ((entity.productId.to_s != "" and entity.productVersion.to_s != "") ? "#{entity.productId.to_s}_#{entity.productVersion.to_s}" : nil) 
                if(currentProductIdVersion.to_s != "" and @productIdVersion.to_s != "" and currentProductIdVersion != @productIdVersion)
                    @baseIO.additionalData = {} if (@baseIO.additionalData == nil || (@baseIO.additionalData != nil and !@baseIO.additionalData.is_a?(Hash)))
                    @baseIO.additionalData["TRIGGERCHANGEPLAN"] = "YES"

                    planOptionCd = nil
                    $currentProduct = MobiSys::ProductUtil.getProduct(entity.productSeq.to_s)
                    planOptionFacet = $currentProduct.getFacet('PLANOPTION')
                    if planOptionFacet != nil
                        if planOptionFacet.OfflinePlanOptionList.size > 0 and entity.productPlanOptionCd.to_s != "" 
                            planOptionCd = entity.productPlanOptionCd if planOptionFacet.OfflinePlanOptionList.select{|offlinePlan| offlinePlan.optionCd == entity.productPlanOptionCd}.size > 0
                        end
                    end   
                    MobiSys::QuotationService.changePlan(self.parentBaseDO,planOptionCd)
                end
                if entity !=nil && entity.paymentTypeCd == "SINGLE"
                    entity.paymentFrequencyCd = "SINGLE"
                    entity.premiumPayingTerm = 1
                end

                if entity.productSeq.to_i > 0
                    product = MobiSys::ProductUtil.getProduct(entity.productSeq.to_s)
                    if product
                        entity.productId = product.productId if entity.productId.to_s == ""
                        entity.productFamilyCd = product.productFamilyCd if entity.productFamilyCd.to_s == ""
                        entity.productLongName = product.longName if entity.productLongName.to_s == ""
                    end
                end

                entity.productTypeCd = "PLAN" if entity.productTypeCd.to_s == ""
            end
            return entity
        end
	end	
end

begin 
    require 'Quotation/QuotationPlanModel_company'
rescue LoadError => e
    puts 'QuotationPlanModel_company not included'
end
 require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationRiderListModel < BaseModel
        
        def initialize(io)
            # logInfo "~~~in QuotationRiderListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationRiderListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            $displayRidersHM = nil
            quotationRiderList = []
            quotation = self.parentBaseDO
            orderedQuotationRiderList = []
            
            if self.createNewObject
                baseProduct = quotation.getBaseProduct()
                $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
                if quotation.quoteStatusCd.to_s == 'ACCEPTED' || quotation.quoteStatusCd.to_s == 'SYNCDONE'
                    MobiSys::QuotationService.loadRiderProducts(quotation, $currentProduct, false)
                else
                    MobiSys::QuotationService.loadRiderProducts(quotation, $currentProduct) if $currentProduct
                end
            end            
            quotationRiderList.push(quotation.getNonBuiltInRiders).flatten!
            
            if quotationRiderList.size > 0
                #Set insuredPartyName for tabs on UI
                quotationRiderList.each do |rider|
                    product = MobiSys::ProductUtil.getProduct(rider.productSeq) if rider.productSeq.to_s != ""
                    rider.productLongName = product.longName if product
                    # set media and text i.e. Collateral  data for api
                    setCollateralData(rider)
                    party = self.parentBaseDO.getPartyByGuid(rider.insuredPartyRefGuid)
                    rider.insuredPartyName = party.getFullName if party
                end

                #Order Riders as per Party Roles
                quotationRiderProducts = CommonUtil.getLinkedHashedList("insuredPartyRefGuid",quotationRiderList)
                quotation.getOrderedPartyList.each do |quotationParty|
                    partyWiseRiderList  = quotationRiderProducts[quotationParty.guid]
                    if partyWiseRiderList != nil and partyWiseRiderList.size > 0
                        partyWiseRiderList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
                        orderedQuotationRiderList.push(partyWiseRiderList).flatten!
                    end
                end
            end

			return orderedQuotationRiderList
		end

        def setCollateralData(qProductDO)
            if qProductDO.to_s != ""
                collateralLevelCd = qProductDO.getProduct.collateralLevelCd.to_s
                if collateralLevelCd.to_s != ""
                    # qProductDO.additionalData = {}
                    collateralRenderLevel = CollateralRenderLevel.find(:first,:conditions => {:levelCd => collateralLevelCd})
                    if collateralRenderLevel.to_s != ""
                        text = collateralRenderLevel.header1
                        qProductDO.header = text
                        if collateralRenderLevel.contentPart1TypeCd.to_s != "" && collateralRenderLevel.contentPart1TypeCd.to_s == "HTML"
                            text = collateralRenderLevel.contentPart1
                            qProductDO.html = MobiSys::UIGenUtilHelper.getLabelValue(text, Application.getValue('DEFAULTLOCALE').value.downcase)
                        elsif collateralRenderLevel.contentPart1TypeCd.to_s != "" && collateralRenderLevel.contentPart1TypeCd.to_s == "MEDIA"
                            collateral = Collateral.find(
                                :first,
                                :conditions => {
                                    :collateralCd => collateralRenderLevel.contentPart1
                                }
                                )

                            mediaFileName = (collateral != nil ? collateral.fileName : nil)
                            qProductDO.media = mediaFileName
                        end
                        if collateralRenderLevel.icon.to_s != ""
                            collateral = Collateral.find(
                                :first,
                                :conditions => {
                                    :collateralCd => collateralRenderLevel.icon
                                }
                                )

                            iconFileName = (collateral != nil ? collateral.fileName : nil)
                            qProductDO.icon = iconFileName
                        end
                        if collateralRenderLevel.footer1.to_s != ""
                            qProductDO.footer = collateralRenderLevel.footer1
                        end
                    end
                end
            end
        end

        def setModel(entity)
            quotation = self.parentBaseDO
            unselectedRidersHM = {}
            entity.each do |quotationProduct|
                if quotationProduct.productTypeCd.to_s == "RIDER" && quotationProduct.selected.to_s != "YES"
                    quotationProduct.removed = "YES"
                    if !unselectedRidersHM.has_key?(quotationProduct.insuredPartyRefGuid)
                        unselectedRidersHM[quotationProduct.insuredPartyRefGuid] = []
                    end 
                    unselectedRidersHM[quotationProduct.insuredPartyRefGuid].push(quotationProduct.productSeq)
                end
            end
            unselectedRiders = ""
            unselectedRidersHM.each do |k,v|
                unselectedRiders = unselectedRiders + "#{k}:#{v.join(',')}|"
            end
            quotation.unselectedRiders = unselectedRiders

            return entity
        end

	end
	
end

begin 
    require 'Quotation/QuotationRiderListModel_company'
rescue LoadError => e
    puts 'QuotationRiderListModel_company not included'
end
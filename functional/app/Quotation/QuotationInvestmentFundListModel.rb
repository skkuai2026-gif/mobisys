require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationInvestmentFundListModel < BaseModel

        def initialize(io)
            # logInfo "~~~in QuotationInvestmentFundListModel initialize: #{io.inspect}"
            super(io)
            # logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuotationInvestmentFundListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            baseProduct = self.parentBaseDO
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
                if Date.parse(fund.expiryDt) > Date.parse(self.baseIO.baseDO.quotationDt.to_s)
                    collateralLevelCd = fund.collateralLevelCd
                    text = nil
                    mediaFileName = nil
                    #Set media and Text value
                    if collateralLevelCd.to_s != ""
                        collateralRenderLevel = CollateralRenderLevel.find(:first,:conditions => {:levelCd => collateralLevelCd})
                        if collateralRenderLevel != nil
                            text = ((collateralRenderLevel.contentPart1TypeCd.to_s == "HTML" and collateralRenderLevel.contentPart1.to_s != "") ? collateralRenderLevel.contentPart1 : collateralRenderLevel.header1)
                            
                            if collateralRenderLevel.contentPart1TypeCd.to_s == "MEDIA" and collateralRenderLevel.contentPart1.to_s != ""
                                collateral = Collateral.find(
                                    :first,
                                    :conditions => {
                                        :collateralCd => collateralRenderLevel.contentPart1
                                    }
                                    )

                                mediaFileName = (collateral != nil ? collateral.fileName : nil)
                            end
                        end
                    end

                    unless selectedFundCdList.include?(fund.fundCd.to_s)
                        if self.createNewObject
                            quotationProductInvestmentFund = QuotationProductInvestmentFund.new
                            quotationProductInvestmentFund.fundCd = fund.fundCd
                            quotationProductInvestmentFund.expiryDt = fund.expiryDt
                            quotationProductInvestmentFund.fundTypeCd = fund.fundTypeCd
                            quotationProductInvestmentFund.maturityDt = fund.maturityDt
                            quotationProductInvestmentFund.sortOrder = fund.sortOrder
                            quotationProductInvestmentFund.fundDesc = text
                            quotationProductInvestmentFund.fundMedia = mediaFileName
                            quotationProductInvestmentFund.addtnlFld1Str = fund.addtnlFld1Str
                            quotationProductInvestmentFund.addtnlFld2Str = fund.addtnlFld2Str

                            baseProduct.addQuotationProductInvestmentFund(quotationProductInvestmentFund)
                        end
                    else
                        investmentFund = baseProduct.QuotationProductInvestmentFundList.select{|m| m if m.fundCd == fund.fundCd}.first
                        investmentFund.fundDesc = text
                        investmentFund.fundMedia = mediaFileName
                        investmentFund.addtnlFld1Str = fund.addtnlFld1Str
                        investmentFund.addtnlFld2Str = fund.addtnlFld2Str
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
            if baseProduct.topUpAllocSameAsPremAllocFl.to_s == "YES"
                baseProduct.QuotationProductInvestmentFundList.each do |investmentFund|
                    if investmentFund.allocationPerc.to_s != ""
                        investmentFund.topupAllocationPerc = investmentFund.allocationPerc
                        investmentFund.status = ""
                    end
                end
            end

            #Sort based on fundList sortorder
            sortedList = baseProduct.QuotationProductInvestmentFundList.sort_by{|x| fundCdList.index x.fundCd}
            baseProduct.setQuotationProductInvestmentFundList(sortedList)
           
			return baseProduct.QuotationProductInvestmentFundList
		end

        def setModel(entity)
            baseProduct = self.parentBaseDO
            entity.each do |investmentFund|
                #Assigned UI value of alloc percent to topup
                investmentFund.topupAllocationPerc = investmentFund.allocationPerc if baseProduct.topUpAllocSameAsPremAllocFl.to_s == "YES"
                #Remove investment record if no alloc or topup percent value added
                investmentFund.removed = "YES" if(investmentFund.allocationPerc.to_s == "" and investmentFund.topupAllocationPerc.to_s == "")
                investmentFund.removed = "" if((investmentFund.allocationPerc.to_s != "" || investmentFund.topupAllocationPerc.to_s != "") and investmentFund.status.to_s != "N" and investmentFund.removed.to_s == "YES")
            end

            return entity
        end

	end
	
end

begin 
    require 'Quotation/QuotationInvestmentFundListModel_company'
rescue LoadError => e
    puts 'QuotationInvestmentFundListModel_company not included'
end
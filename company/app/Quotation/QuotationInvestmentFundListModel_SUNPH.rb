require 'Quotation/QuotationInvestmentFundListModel'
require 'CommonClasses/BaseModel'

module MobiSys
	
	class QuotationInvestmentFundListModel_SUNPH < QuotationInvestmentFundListModel

        # def initialize(io)
        #     # logInfo "~~~in QuotationInvestmentFundListModel initialize: #{io.inspect}"
        #     super(io)
        #     # logInfo "~~~baseIO:#{self.baseIO}"
        # end

		def getModel
			# logInfo("~~~baseIO in QuotationInvestmentFundListModel:#{self.baseIO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
            companyColorValue = companyColor.value.to_s if companyColor
            puts "QuotationInvestmentFundListModel_SUNPH---------------"
            $fundRiskClassCache = Lookupvalue.createLookupCache(["FUNDRISKCLASS"]) unless $fundRiskClassCache
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
                # fundArray = model.getModelFunds.map {|x| x.fundCd.to_s}

                fundArray = model.getModelFunds
                                .sort_by { |x| x.sortOrder.to_i rescue 0 }
                                .map(&:fundCd)

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

            #Create order index
            order_index = fundArray.each_with_index.to_h
            #Sort fundList as per fundArray order
            fundList.sort_by! { |f| order_index[f.fundCd] || Float::INFINITY }

            # fundList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}

            fundCdList = fundList.map {|x| x.fundCd.to_s}

            agent = AgentReg.getCurrentAgentReg
            rpqFundList = Lookupvalue.find(:all,:conditions=>{'key'=>"RPQFUNDS"})

            fx_fund_codes = rpqFundList
                  .select { |l| l.additionalField2.to_s == "FX" }
                  .map(&:cd)

            # Remove FX funds from fundCdList if agent.field6 != "FX"
            if agent && agent.field6.to_s != "FX"
              fundCdList -= fx_fund_codes
            end

            quotationParty = self.baseIO.baseDO.getQuotationPartyByRole("PROPOSER")
            filteredList = Array.new
            quotation = self.baseIO.baseDO
            fundList.each do |fund|
                next if agent && agent.field6.to_s != "FX" && fx_fund_codes.include?(fund.fundCd.to_s)

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
                    fundColor = fund.addtnlFld1Str
                    unless selectedFundCdList.include?(fund.fundCd.to_s)
                        if self.createNewObject
                            quotationProductInvestmentFund = QuotationProductInvestmentFund.new
                            quotationProductInvestmentFund.addtnlFld2Str = fund.addtnlFld2Str
                            quotationProductInvestmentFund.fundCd = fund.fundCd
                            quotationProductInvestmentFund.expiryDt = fund.expiryDt
                            quotationProductInvestmentFund.fundTypeCd = fund.fundTypeCd
                            quotationProductInvestmentFund.maturityDt = fund.maturityDt
                            quotationProductInvestmentFund.sortOrder = fund.sortOrder
                            quotationProductInvestmentFund.addtnlFld1Str = fundColor
                            quotationProductInvestmentFund.fundDesc = text
                            quotationProductInvestmentFund.fundMedia = mediaFileName
                            if quotationParty.partyTypeCd.to_s == "INDIVIDUAL" && quotation.autoRegistrationNum.to_s == ""
                                quotation = self.baseIO.baseDO
                                if quotation && quotation.fnaId.to_s != ""
                                  fnaId = quotation.fnaId
                                  fnaRequest = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})
                                  listFnaFund = fnaRequest.FNAFundList
                                  listFnaFund.each do |fnaFund|
                                    if fnaFund.fundCd.to_s == quotationProductInvestmentFund.fundCd.to_s
                                        quotationProductInvestmentFund.allocationPerc = quotationProductInvestmentFund.topupAllocationPerc = fnaFund.allocationPerc
                                    end
                                  end 
                                end
                            end
                            key = "FUNDRISKCLASS" + fund.fundManagementCharges.to_s
                            quotationProductInvestmentFund.fundRiskClassLabel = $fundRiskClassCache[key.to_sym].desc if $fundRiskClassCache.has_key?(key.to_sym)
                            baseProduct.addQuotationProductInvestmentFund(quotationProductInvestmentFund)
                        end
                    else
                        investmentFund = baseProduct.QuotationProductInvestmentFundList.select{|m| m if m.fundCd == fund.fundCd}.first
                        investmentFund.fundDesc = text
                        investmentFund.fundMedia = mediaFileName
                        key = "FUNDRISKCLASS" + fund.fundManagementCharges.to_s
                        investmentFund.fundRiskClassLabel = $fundRiskClassCache[key.to_sym].desc if $fundRiskClassCache.has_key?(key.to_sym)
                        investmentFund.addtnlFld1Str = fundColor
                    end
                else
                    # fund.delete
                end
            end
            if quotationParty.to_s != "" && quotationParty.partyTypeCd.to_s == "INDIVIDUAL" && quotation.leadId.to_s != ""
                if companyColorValue.to_s == "SLGFI"
                    if quotation.autoRegistrationNum.to_s == ""
                        quotation.autoRegistrationNum = "YES"
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
                    end
                    filteredList = baseProduct.QuotationProductInvestmentFundList.select do |fund|
                      fund.vars[:allocationPerc].to_f > 0 || fund.vars[:removed].to_s == 'YES'
                    end
                elsif companyColorValue.to_s == "SLOCPI"
                    if quotation.autoRegistrationNum.to_s == ""
                        quotation.autoRegistrationNum = "YES"
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
                    else
                        baseProduct.QuotationProductInvestmentFundList.select do |fund|
                            if fund.vars[:allocationPerc] != nil
                                if fund.vars[:allocationPerc].to_f >= 0.0
                                    filteredList.push(fund)
                                end
                            else
                                fund.removed = 'YES'
                                filteredList.push(fund)
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
            if baseProduct.topUpAllocSameAsPremAllocFl.to_s == "YES"
                baseProduct.QuotationProductInvestmentFundList.each do |investmentFund|
                    if investmentFund.allocationPerc.to_s != ""
                        investmentFund.topupAllocationPerc = investmentFund.allocationPerc
                        investmentFund.status = ""
                    end
                end
            end

			return baseProduct.QuotationProductInvestmentFundList
		end

        def setModel(entity)
            baseProduct = self.parentBaseDO
            entity = baseProduct.QuotationProductInvestmentFundList
  .select { |x| !x.allocationPerc.to_s.strip.empty? }
  .sort_by { |x| x.sortOrder.to_i }
            return entity
        end
	end
end

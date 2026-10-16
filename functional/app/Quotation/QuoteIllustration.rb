require 'Product/product_util'
require 'json'


module MobiSys
	class QuoteIllustration
		def self.generatePdfUi_new(baseIO)
			results = Hash.new
			results["si"] = createSIOuputData(baseIO)
			results["sym_page_count"] = 0
			return results
		end

		def self.createSIOuputData(baseIO)
			resultsSI = Hash.new
			resultsSI["Quotation"] = createQuotationData(baseIO)

			agent = AgentReg.getCurrentAgentReg
			resultsUser = Hash.new
			resultsUser["userId"] = agent.userId
			resultsUser["userName"] = agent.agentName1
			resultsUser["userLanguage"] = Application.getValue('DEFAULTLOCALE').value
			resultsSI["User"] = resultsUser
			
			agentHash2 = {}
			modelSource = Rho::RhoConfig.sources[agent.class.name.to_s]
			dataTypes = modelSource["schema"]["property"]
			agent.vars.each do |key,value|
				next if value == nil || key != :agentName1 #|| key == :parentAgency || key == :agentClassification
				dataType = nil
				dataType = dataTypes[key.to_s][0] if dataTypes[key.to_s]
				hashKey = key.to_sym
				agentHash2[hashKey] = value.to_s.force_encoding("UTF-8") if dataType and dataType == "string".to_sym
				agentHash2[hashKey] = value unless dataType and dataType == "string".to_sym
			end

			resultsSI["Agent"] = agentHash2
			
			resultsSI["SICalc"] = nil

			resultsSI["ApplicationMode"] = "OFFLINE"

			resultsSI["ViewType"] = "html"


			product = MobiSys::ProductUtil.getProduct(baseIO.baseDO.getBaseProduct.productSeq)
			resultsSI["BaseProductM"] = getProductData(product)

			fundMMap = {}
			if baseIO.baseDO.getBaseProduct.portfolioModelCd.to_s != ""
	            model = Model.loadObject(:first,
	                    :conditions =>{
	                    {
	                        :name => 'modelCd'
	                    } => baseIO.baseDO.getBaseProduct.portfolioModelCd
	                }
	            )
	        end
	        fundList = []
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
			resultsSI["FundM"] = nil

	        if !fundList.empty?
		        baseIO.baseDO.getBaseProduct.QuotationProductInvestmentFundList.each do |qpif|
		        	fundDO = fundList.select { |fund|  fund.fundCd == qpif.fundCd  }[0]
		        	qpif.fundDesc = fundDO.fundDesc
		        	fundMMap[qpif.fundCd] = fundDO
		        end
				resultsSI["FundM"] = fundMMap
			end
			resultsSI["SICalc"] = $quotationIO.additionalData["SICalc"]

			siModelMap = {}
			siModelMap["modelCd"] = $quotationIO.illustrationModel.modelCd
			siModelMap["GlobalRates"] = $quotationIO.illustrationModel.IllustrationRateList
			siModelMap["FundRates"] = $quotationIO.originalSIModel.IllustrationRateList
			resultsSI["SIModel"] = siModelMap 

			resultsSI["LanguageCd"] = Application.getValue('DEFAULTLOCALE').value.upcase.to_s
			
			resultsSI["RootPath"] = "#{Rho::RhoApplication.get_base_app_path()}public/images/outputimages/"

			return resultsSI



		end

		def self.getProductData(productDO)
			productHM = {}
			prdSelectionFacetList = productDO.getFacetByFacetType("PRDSELECTION")
			prdSelectionFacetList.each do |facet|
				productHM[facet.facetId] = facet.actionValue
			end

			prdOthersFacetList = productDO.getFacetByFacetType("PRDOTHERS")
			prdOthersFacetList.each do |facet|
				productHM[facet.facetId] = facet.actionValue
			end

			riderAsscFacet = productDO.getRiderAssociationFacet
			if riderAsscFacet != nil
				productHM["RIDERASSOCIATION"] = "YES"
			end

			productHM["productId"] = productDO.productId
			productHM["longName"] = productDO.longName
			productHM["shortName"] = productDO.shortName
			productHM["isWOPFl"] = nil

			otherDetFacet = productDO.getOtherDetailsFacet
			if otherDetFacet != nil
				otherDetails = otherDetFacet.OfflineOtherDetailsList[0]
				if otherDetails != nil
					productHM["isWOPFl"] = otherDetails.isWOPFl
					if otherDetails.illustrationFormat.to_s != ""
						productHM["ILLUSTRATIONMODEL"] = "YES"
					end
				end
			end

			baseProductM = productHM
			return baseProductM

		end

		def self.createQuotationData(baseIO)
			quotationDO = baseIO.baseDO
			resultsQuote = Hash.new
			resultsQuote["OutputPreferences"] = baseIO.outputPreferencesDO
			resultsQuote["Entity"] = quotationDO
			resultsQuote["BasePlan"] = quotationDO.getBasePlan.hashForApi
			resultsQuote["BasePlan"]["FundList"] = {}
			fundList = []
			fundList = quotationDO.getBasePlan.QuotationProductInvestmentFundList if quotationDO.getBasePlan.QuotationProductInvestmentFundList
			resultsQuote["BasePlan"]["FundList"] = quotationDO.getBasePlan.QuotationProductInvestmentFundList.select {|qpif| qpif.removed.to_s != "YES"}
			resultsQuote["RiderList"] = quotationDO.getRiders
			resultsQuote["Proposer"] = quotationDO.getPartyByRole("PROPOSER")
			resultsQuote["PrimaryInsured"] = quotationDO.getPartyByRole("PRIMARY")
			resultsQuote["JointLife"] = quotationDO.getPartyByRole("JOINT")
			resultsQuote["SupplementaryList"] = quotationDO.getPartyListByRoleCd("SUPPLEMENTARY")

			initialInvestment = quotationDO.getInitialInvestment
			if initialInvestment != nil
				resultsQuote["InitialInvestment"] = initialInvestment
			end

			regularTopup = quotationDO.getRegularTopup
			if regularTopup != nil
				resultsQuote["RegularTopup"] = regularTopup
			end

			resultsQuote["AdHocTopupList"] = quotationDO.getTopupByType("ADHOCTOPUP")

			resultsQuote["TransferTopupList"] = quotationDO.getTopupByType("TRANSFERTOPUP")

			resultsQuote["WithdrawalList"] = quotationDO.QuotationWithdrawalList

			resultsQuote["AdditionalFieldsList"] = quotationDO.QuotationAdditionalFieldsList

			signaturecontainer = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => quotationDO.guid
                                            }
                                        )
			resultsQuote["ServiceSignatureList"] = []
			if signaturecontainer
				resultsQuote["ServiceSignatureList"] = signaturecontainer.ServiceSignatureList
			end

			return resultsQuote

		end
	end
end
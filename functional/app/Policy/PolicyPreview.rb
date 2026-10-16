require 'Product/product_util'
require 'ostruct'
require 'json'


module MobiSys
	class PolicyPreview
		def self.generateEappPreview_new(baseIO, entityHash)
			results = Hash.new
			results["eapp"] = createEappOuputData(baseIO, entityHash)
			results["eapp"].merge!(extraEappJSONData(baseIO))

			return results
		end

		def self.createEappOuputData(baseIO, entityHash)
			eappOutputData = Hash.new
			eappOutputData["Policy"] = entityHash
			eappOutputData["Policy"]["BasePlan"]["FundList"] = []
			fundList = []
			baseIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList.each do |qpif|
	        	if qpif.removed.to_s != "YES" && qpif.allocationPerc.to_s != ""
	        		fundList.push qpif
	        	end
	        end
			eappOutputData["Policy"]["BasePlan"]["FundList"] = fundList
			# TODO need to comment the below lines as we don't want to add HTML as part of the JSON
			eappOutputData["Policy"]["PartyQuestionnaireInHtml"] = MobiSys::UIGenUtilEapp.getQuestionnaireTableRestAPI(baseIO.baseDO)
			eappOutputData["Policy"]["ServiceSignatureList"] = []
			signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => baseIO.baseDO.guid}) 
            eappOutputData["Policy"]["ServiceSignatureList"] = signatureContainer.ServiceSignatureList if signatureContainer
			return eappOutputData
		end

		def self.extraEappJSONData(baseIO)
			eappExtraJsonHM = Hash.new

			agent = AgentReg.getCurrentAgentReg
			eappExtraJsonHMUser = Hash.new
			eappExtraJsonHMUser["userId"] = agent.userId
			eappExtraJsonHMUser["userName"] = agent.agentName1
			eappExtraJsonHMUser["userLanguage"] = Application.getValue('DEFAULTLOCALE').value
			eappExtraJsonHM["User"] = eappExtraJsonHMUser
			eappExtraJsonHM["Agent"] = agent.hashForApi
			eappExtraJsonHM["ApplicationMode"] = "OFFLINE"

			eappExtraJsonHM["ViewType"] = "html"

			product = MobiSys::ProductUtil.getProduct(baseIO.baseDO.getBaseProduct.productSeq)
			eappExtraJsonHM["BaseProductM"] = getProductData(product)

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
			eappExtraJsonHM["FundM"] = nil

	        if !fundList.empty?
		        baseIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList.each do |qpif|
		        	fundDO = fundList.select { |fund|  fund.fundCd == qpif.fundCd  }[0]
		        	qpif.fundDesc = fundDO.fundDesc
		        	fundMMap[qpif.fundCd] = fundDO
		        end
				eappExtraJsonHM["FundM"] = fundMMap
			end			
			
			eappExtraJsonHM["RootPath"] = "#{Rho::RhoApplication.get_base_app_path()}public/images/outputimages/"
			
			eappExtraJsonHM["LanguageCd"] = baseIO.outputPreferencesDO.to_s != "" && baseIO.outputPreferencesDO.languageCd.to_s != "" ?  baseIO.outputPreferencesDO.languageCd.to_s : Application.getValue('DEFAULTLOCALE').value.upcase.to_s

			return eappExtraJsonHM
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
			return productHM
		end
	end
end
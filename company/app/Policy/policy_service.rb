require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisysuihelper_jazz'
require 'Policy/policy_b_o'
require 'Product/product_b_o'

module MobiSys
	class PolicyService
		extend MobiSys::BrowserHelper

		def self.getPortfolioModels(product, quotation, baseProduct)
			modelArray = []
			offlineProductModelArray = []

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
				end
			end

			return modelArray
		end

		#Method to create PolicyProductInsured records for Primary & Joint
		def self.createPolicyProductInsured(policy)
			baseProduct = policy.getBaseProduct

			if baseProduct
				primary = policy.getParty("PRIMARY")
				joint = policy.getParty("JOINT")
				supplementaries = policy.getPartyList("SUPPLEMENTARY")
				primaryFl = true
				jointFl = true
				baseProduct.PolicyProductInsuredList.each do |policyProductInsured|
					if !primary || policyProductInsured.insuredPartyRefGuid.to_s == primary.guid.to_s
						primaryFl = false
					elsif !joint || policyProductInsured.insuredPartyRefGuid.to_s == joint.guid.to_s
						jointFl = false
					end
				end
				if $currentProduct.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES'
					supplementaries.each do |supplementary|
						createSupPPI = true
						baseProduct.PolicyProductInsuredList.each do |policyProductInsured|
							if policyProductInsured.roleCd.to_s == 'SUPPLEMENTARY' && policyProductInsured.insuredPartyRefGuid.to_s == supplementary.guid.to_s
								createSupPPI = false
								break
							end
						end
						if createSupPPI
							baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "SUPPLEMENTARY", :insuredSequenceTypeCd => "SUPPLEMENTARY", :insuredPartyRefGuid => supplementary.guid))
						end
					end
				end

				if primary && primaryFl
					baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => primary.guid))
				end
				if joint && jointFl
					baseProduct.addPolicyProductInsured(PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => joint.guid))
				end
			end
		end

		#Method to save & validate Plan/ Coverage Details Tab
		def self.submitPlanDetails(policy)
			baseProduct = policy.getBaseProduct

			if $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES"
				policy.PolicyProductList.each do |policyProduct|
					if policyProduct.selected.to_s != "YES" && policyProduct.productTypeCd == "RIDER" && policyProduct.builtInRiderFl != "YES"
						policyProduct.removed = "YES" 
					end
				end
			end
			policy.PolicyProductList.each do |policyProduct|
				if policyProduct.productTypeCd == "PLAN"
					if policyProduct.topUpAllocSameAsPremAllocFl.to_s == "on"
						policyProduct.topUpAllocSameAsPremAllocFl = "YES"
					else
						policyProduct.topUpAllocSameAsPremAllocFl = nil
					end
				elsif policyProduct.productTypeCd == "RIDER"
					if $currentProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES" && policyProduct.builtInRiderFl != 'YES'
						policyProduct.selected = "" unless policyProduct.selected
						if policyProduct.selected.to_s != "YES"
							policyProduct.removed = "YES"
							next
						end
					end
					riderProduct = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
					if riderProduct
						policyProduct.productId = riderProduct.productId
						policyProduct.productVersion = riderProduct.productVersion
						policyProduct.productFamilyCd = riderProduct.productFamilyId
					end
					policyProduct.PolicyProductInsuredList.each do |policyProductInsured|
						if policyProductInsured.roleCd != "SUPPLEMENTARY"
							policyPartyRole = policy.getPolicyPartyRole(policyProductInsured.roleCd)
							if policyPartyRole != nil
								policyProductInsured.insuredPartyRefGuid = policyPartyRole.refGuid
							else
								policyProductInsured.insuredPartyRefGuid = ""
							end
						end
					end
				end
			end
		end

		def self.submitSupplementary(policy)
			if $currentProduct
				supplementaryProductFacet = $currentProduct.getFacet('MULTILIFEAPPLICABLE')
				if supplementaryProductFacet
					supplementaryLifeGuids = policy.getPartyList('SUPPLEMENTARY').collect{|sup| sup.guid}
					supPolicyProducts = policy.getPolicyProductByProductTypeCd('PLANMULTI')
					if policy.getBaseProduct
						supPolicyProducts.each do |qp|
							if supplementaryLifeGuids.include? qp.insuredPartyRefGuid
								baseProductClone = policy.getBaseProduct.cloneObject
								baseProductClone.baseAnnualPremium = qp.baseAnnualPremium
								baseProductClone.baseSumAssured = qp.baseSumAssured
								baseProductClone.productTypeCd = qp.productTypeCd
								baseProductClone.insuredPartyRefGuid = qp.insuredPartyRefGuid
								baseProductClone.modalPremium = qp.modalPremium
								baseProductClone.guid = baseProductClone.object.gsub(".","_")
								baseProductClone.systemCreatedDt = qp.systemCreatedDt
								baseProductClone.PolicyProductInsuredList[0].roleCd = 'SUPPLEMENTARY'
								baseProductClone.PolicyProductInsuredList[0].insuredPartyRefGuid = qp.insuredPartyRefGuid
								policy.removePolicyProduct(qp)
								policy.removePolicyProductInvestmentFund(qp.PolicyProductInvestmentFundList[0])
								policy.removePolicyProductInsured(qp.PolicyProductInsuredList[0])
								policy.removePolicyProductExtra(qp.PolicyProductExtraList[0])
								policy.removePolicyProductAdditional(qp.PolicyProductAdditionalList[0])
								policy.addPolicyProduct(baseProductClone)
								policy.addPolicyProductInsured(baseProductClone.PolicyProductInsuredList[0])
							else
								qp.removed = 'YES'
							end
						end
					end
				end
			end
		end

		def self.generateEappPreview(policy)
			$policyIO = MobiSys::IO::PolicyIO.new
            $policyIO.baseDO = policy
            MobiSys::UIGenUtilEapp.findTemplatePageMapping($policyIO,"EAPP")
            MobiSys::UIGenUtilEapp.getHtmlStringandGeneratePDF(true, $policyIO)
            $showPdf = false
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

		def self.generateSIPDF(policy)
            if policy.quotationRefNum.to_s != ""
                quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
                if quotation != nil
                    quotation.QuotationProductList.each do|quotationProduct|
                        quotationProduct.emr = 0 if quotationProduct.emr.to_s == ""
                        quotationProduct.emrDuration = 0 if quotationProduct.emrDuration.to_s == ""
                        quotationProduct.flatExtra = 0 if quotationProduct.flatExtra.to_s == ""
                        quotationProduct.flatExtraDuration = 0 if quotationProduct.flatExtraDuration.to_s == ""
                    end
                
                    quotation.QuotationTopUpList.each do| topup|
                        topup.topUpAmount = 0 if topup.topUpAmount.to_s == ""
                    end
            
                    has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                    if has_network
                        begin         
                            responseHash = MobiSys::Sync.entities([quotation],false)
                            return responseHash
                        rescue StandardError => se
                            puts se
                        end
                    else
                        Alert.show_popup({
                            :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORK'),
                            :title => '',
                            :icon => :info,
                            :buttons => ["OK"] } 
                        )
                        return
                    end
                end
            end
        end

        #Method to get facet data common to all EAPP tabs based on tab
        def self.getFacetData(tab, productSeq=nil)
            classname = ""
            facetKeyPrefix = ""
            facetData = Hash.new

            if productSeq.to_s != ""
                product = MobiSys::ProductUtil.getProduct(productSeq)
            end

            case tab
            when "basic"
                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO"
                facetData[:renderPolicyNum] = MobiSys::BrowserHelper.renderField?(classname + '.policyNum')
                facetData[:renderProposalNum] = MobiSys::BrowserHelper.renderField?(classname + '.proposalNum')
                facetData[:renderQuotationRefNum] = MobiSys::BrowserHelper.renderField?(classname + '.quotationRefNum')
                facetData[:renderProposalSignedDt] = MobiSys::BrowserHelper.renderField?(classname + '.proposalSignedDt')
                facetData[:renderRiskCommencementDt] = MobiSys::BrowserHelper.renderField?(classname + '.riskCommencementDt')
                facetData[:renderProposalReceivedDt] = MobiSys::BrowserHelper.renderField?(classname + '.proposalReceivedDt')

                facetData[:renderLeadGenerationCd] = MobiSys::BrowserHelper.renderField?(classname + '.leadGenerationCd')
                facetData[:renderCampaignCode] = MobiSys::BrowserHelper.renderField?(classname + '.campaignCode')
                facetData[:renderPurposeOfInsuranceCd] = MobiSys::BrowserHelper.renderField?(classname + '.purposeOfInsuranceCd')
                facetData[:renderOtherPurposeOfInsurance] = MobiSys::BrowserHelper.renderField?(classname + '.otherPurposeOfInsurance')
                facetData[:renderSourceOfFund] = MobiSys::BrowserHelper.renderField?(classname + '.sourceOfFund')
                facetData[:renderOtherSourceOfFund] = MobiSys::BrowserHelper.renderField?(classname + '.otherSourceOfFund')
                facetData[:renderStatcd] = MobiSys::BrowserHelper.renderField?(classname + '.statCd')
                facetData[:renderAgentId] = MobiSys::BrowserHelper.renderField?('PolicyAgentDO.agentId')
                facetData[:renderCommPercent] = MobiSys::BrowserHelper.renderField?('PolicyAgentDO.commPercent')
                facetData[:renderProdnPercent] = MobiSys::BrowserHelper.renderField?('PolicyAgentDO.prodnPercent')
                facetData[:renderYearFrom] = MobiSys::BrowserHelper.renderField?('PolicyAgentDO.yearFrom')
                facetData[:renderYearTo] = MobiSys::BrowserHelper.renderField?('PolicyAgentDO.yearTo')

                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO"
                facetData[:renderProductFamilyCd] = MobiSys::BrowserHelper.renderField?(classname + '.productFamilyCd')
                facetData[:renderProductId] = MobiSys::BrowserHelper.renderField?(classname + '.productId')
                facetData[:renderProductPlanOptionCd] = MobiSys::BrowserHelper.renderField?(classname + '.productPlanOptionCd')

                if product != nil
                    facetData[:renderJointFieldWork] = MobiSys::BrowserHelper.renderPanel?('AGENTSHARING', product)
                end
                return facetData
            when "primary"
                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO"
                facetKeyPrefix = "PRIMARY"
            when "jointlife"
                classname = "PolicyJointLifeDO"
                facetKeyPrefix = "JOINTLA"
            when "proposer"
                classname = "PolicyProposerDO"
                facetKeyPrefix = "PROPOSER"
            when "supplementarylife"
                classname = "PolicySupplementaryLifeDO"
                facetKeyPrefix = "SUPPLY"
            when "nominee"
                classname = "PolicyNomineeDO"
                facetKeyPrefix = "NOMINEE"
            when "appointee"
                classname = "PolicyAppointeeDO"
                facetKeyPrefix = "APPOINTEE"
            when "payer"
                classname = "PolicyPayerDO"
                facetKeyPrefix = "PAYER"
            when "coverage"
                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO"
                facetData[:renderProductFamilyCd] = MobiSys::BrowserHelper.renderField?(classname + '.productFamilyCd')
                facetData[:renderProductId] = MobiSys::BrowserHelper.renderField?(classname + '.productId')
                facetData[:renderProductPlanOptionCd] = MobiSys::BrowserHelper.renderField?(classname + '.productPlanOptionCd')
                facetData[:renderCurrencyCd] = MobiSys::BrowserHelper.renderField?(classname + '.currencyCd')
                facetData[:renderPaymentTypeCd] = MobiSys::BrowserHelper.renderField?(classname + '.paymentTypeCd')
                facetData[:renderPaymentFrequencyCd] = MobiSys::BrowserHelper.renderField?(classname + '.paymentFrequencyCd')
                facetData[:renderProductTerm] = MobiSys::BrowserHelper.renderField?(classname + '.productTerm')
                facetData[:renderPremiumPayingTerm] = MobiSys::BrowserHelper.renderField?(classname + '.premiumPayingTerm')
                facetData[:renderCapturedPremiumAmt] = MobiSys::BrowserHelper.renderField?(classname + '.capturedPremiumAmt')
                facetData[:renderBaseSumAssured] = MobiSys::BrowserHelper.renderField?(classname + '.baseSumAssured')
                facetData[:renderCoi] = MobiSys::BrowserHelper.renderField?(classname + '.coi')
                facetData[:renderBaseAnnualPremium] = MobiSys::BrowserHelper.renderField?(classname + '.baseAnnualPremium')
                facetData[:renderModalPremium] = MobiSys::BrowserHelper.renderField?(classname + '.modalPremium')
                facetData[:renderAnnualIncome] = MobiSys::BrowserHelper.renderField?(classname + '.annualIncome')
                facetData[:renderMonthlyIncome] = MobiSys::BrowserHelper.renderField?(classname + '.monthlyIncome')
                facetData[:renderMinTargetPremium] = MobiSys::BrowserHelper.renderField?(classname + '.minTargetPremium')
                facetData[:renderMaxTargetPremium] = MobiSys::BrowserHelper.renderField?(classname + '.maxTargetPremium')
                facetData[:renderRecommendedPremium] = MobiSys::BrowserHelper.renderField?(classname + '.recommendedPremium')
                facetData[:renderUnapliedPremium] = MobiSys::BrowserHelper.renderField?(classname + '.unapliedPremium')
                facetData[:renderPdfRequiredFl] = MobiSys::BrowserHelper.renderField?(classname + '.pdfRequiredFl')
                facetData[:renderPdfAmount] = MobiSys::BrowserHelper.renderField?(classname + '.pdfAmount')
                facetData[:renderPdfFrequencyVal] = MobiSys::BrowserHelper.renderField?(classname + '.pdfFrequencyVal')
                facetData[:renderPdfPeriod] = MobiSys::BrowserHelper.renderField?(classname + '.pdfPeriod')
                facetData[:renderPortfolioModelCd] = MobiSys::BrowserHelper.renderField?(classname + '.portfolioModelCd')
                facetData[:renderTopUpAllocSameAsPremAllocFl] = MobiSys::BrowserHelper.renderField?(classname + '.topUpAllocSameAsPremAllocFl')

                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO"
                facetData[:renderInitialTopupFl] = MobiSys::BrowserHelper.renderField?(classname + '.initialTopupFl')
                facetData[:renderRegularTopupFl] = MobiSys::BrowserHelper.renderField?(classname + '.regularTopupFl')

                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO"
                facetData[:renderTopUpAmount] = MobiSys::BrowserHelper.renderField?(classname + '.topUpAmount')
                facetData[:renderTopupFrequencyVal] = MobiSys::BrowserHelper.renderField?(classname + '.topupFrequencyVal')

                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO"
                facetData[:renderFundCd] = MobiSys::BrowserHelper.renderField?(classname + '.fundCd')
                facetData[:renderAllocationPerc] = MobiSys::BrowserHelper.renderField?(classname + '.allocationPerc')
                facetData[:renderTopupAllocationPerc] = MobiSys::BrowserHelper.renderField?(classname + '.topupAllocationPerc')
                facetData[:renderExpiryDt] = MobiSys::BrowserHelper.renderField?(classname + '.expiryDt')
                facetData[:renderFundTypeCd] = MobiSys::BrowserHelper.renderField?(classname + '.fundTypeCd')
                facetData[:renderMaturityDt] = MobiSys::BrowserHelper.renderField?(classname + '.maturityDt')

                if product != nil
                    facetData[:renderCurrencyPanel] = MobiSys::BrowserHelper.renderPanel?('CAPTURECURRENCY', product)
                    facetData[:renderCapturePremiumPanel] = MobiSys::BrowserHelper.renderPanel?('CAPTUREPREMIUMREQUIRED', product)
                    facetData[:renderOtherPremiumPanel] = MobiSys::BrowserHelper.renderPanel?('OTHERPREMIUMSREQUIRED', product)
                facetData[:renderPDFPanel] = false #MobiSys::BrowserHelper.renderPanel?('PDFDETAILSREQUIRED', product)
                facetData[:renderInitialTopupPanel] = MobiSys::BrowserHelper.renderPanel?('INITIALINVESTMENTREQUIREDNB', product)
                facetData[:renderRegularTopupPanel] = MobiSys::BrowserHelper.renderPanel?('REGULARTOPUPSREQUIREDNB', product)
                facetData[:renderFundsPanel] = MobiSys::BrowserHelper.renderPanel?('FUNDSREQUIREDNB', product)
                facetData[:renderTermBasedOnMaturity] = MobiSys::BrowserHelper.renderPanel?('TERMBASEDONMATURITY', product)
            end
            return facetData
            when "rider"
                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyRiderDO"
                facetData[:renderProductSeq] = MobiSys::BrowserHelper.renderField?(classname + '.productSeq')
                facetData[:renderProductPlanOptionCd] = MobiSys::BrowserHelper.renderField?(classname + '.productPlanOptionCd')
                facetData[:renderPartyRoleCd] = MobiSys::BrowserHelper.renderField?(classname + '.partyRoleCd')
                facetData[:renderInsuredPartyRefGuid] = MobiSys::BrowserHelper.renderField?(classname + '.insuredPartyRefGuid')
                facetData[:renderProductTerm] = MobiSys::BrowserHelper.renderField?(classname + '.productTerm')
                facetData[:renderPremiumPayingTerm] = MobiSys::BrowserHelper.renderField?(classname + '.premiumPayingTerm')
                facetData[:renderBaseSumAssured] = MobiSys::BrowserHelper.renderField?(classname + '.baseSumAssured')
                facetData[:renderCoi] = MobiSys::BrowserHelper.renderField?(classname + '.coi')
                facetData[:renderBaseAnnualPremium] = MobiSys::BrowserHelper.renderField?(classname + '.baseAnnualPremium')
                facetData[:renderModalPremium] = MobiSys::BrowserHelper.renderField?(classname + '.modalPremium')
                return facetData
            when "funds"
                classname = "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO"
                facetData[:renderFundCd] = MobiSys::BrowserHelper.renderField?(classname + '.fundCd')
                facetData[:renderAllocationPerc] = MobiSys::BrowserHelper.renderField?(classname + '.allocationPerc')
                facetData[:renderTopupAllocationPerc] = MobiSys::BrowserHelper.renderField?(classname + '.topupAllocationPerc')
                facetData[:renderExpiryDt] = MobiSys::BrowserHelper.renderField?(classname + '.expiryDt')
                facetData[:renderFundTypeCd] = MobiSys::BrowserHelper.renderField?(classname + '.fundTypeCd')
                facetData[:renderMaturityDt] = MobiSys::BrowserHelper.renderField?(classname + '.maturityDt')
                return facetData
            when "payment"
                facetData[:renderInwardPayerTypeCd] = MobiSys::BrowserHelper.renderField?('InwardDO.payerTypeCd')
                facetData[:renderInwardPayerPartyRefGuid] = MobiSys::BrowserHelper.renderField?('InwardDO.payerPartyRefGuid')
                facetData[:renderInwardPaymentMethodCd] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.paymentMethodCd')
                facetData[:renderInwardPaymentSubTypeCd] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.paymentSubTypeCd')
                facetData[:renderInwardMicrNum] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.micrNum')
                facetData[:renderInwardAccountName] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.accountName')
                facetData[:renderInwardBankCd] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.bankCd')
                facetData[:renderInwardBankBranch] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.bankBranch')
                facetData[:renderInwardInstrumentDt] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.instrumentDt')
                facetData[:renderInwardInwardNum] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.inwardNum')
                facetData[:renderInwardInwardAmount] = MobiSys::BrowserHelper.renderField?('InwardDetailsDO.inwardAmount')

                facetData[:renderRenewalPayerTypeCd] = MobiSys::BrowserHelper.renderField?('RenewalPolicyPaymentDO.payerTypeCd')
                facetData[:renderRenewalPayerPartyRefGuid] = MobiSys::BrowserHelper.renderField?('RenewalPolicyPaymentDO.payerPartyRefGuid')
                facetData[:renderRenewalPaymentMethodCd] = MobiSys::BrowserHelper.renderField?('RenewalPolicyPaymentDO.paymentMethodCd')
                facetData[:renderRenewalMicrNum] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.micrNum')
                facetData[:renderRenewalBankCd] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.bankCd')
                facetData[:renderRenewalBranchName] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.branchName')
                facetData[:renderRenewalCardTypeCd] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.cardTypeCd')
                facetData[:renderRenewalAccountName] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.accountName')
                facetData[:renderRenewalAccountNum] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.accountNum')
                facetData[:renderRenewalCardExpiryYear] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.cardExpiryYear')
                facetData[:renderRenewalCardExpiryMnth] = MobiSys::BrowserHelper.renderField?('RenewalPartyFinancialAccountDO.cardExpiryMnth')

                facetData[:renderRefundPaymentMethodCd] = MobiSys::BrowserHelper.renderField?('RefundPolicyPaymentDO.paymentMethodCd')
                facetData[:renderRefundMicrNum] = MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.micrNum')
                facetData[:renderRefundBankCd] = MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.bankCd')
                facetData[:renderRefundBranchName] = MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.branchName')
                facetData[:renderRefundAccountName] = MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.accountName')
                facetData[:renderRefundAccountNum] = MobiSys::BrowserHelper.renderField?('RefundPartyFinancialAccountDO.accountNum')

                if product != nil
                    facetData[:renderRenewalPanel] = MobiSys::BrowserHelper.renderPanel?('RENEWALPREMIUMREQUIRED', product)
                    facetData[:renderRefundPanel] = MobiSys::BrowserHelper.renderPanel?('REFUNDPAYMENTREQUIRED', product)
                end
                return facetData
            when "result"
                facetData[:renderCategoryCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultDocument.categoryCd')
                facetData[:renderDocumentCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultDocument.documentCd')

                facetData[:renderBenefit] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.benefit')
                facetData[:renderCause] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.cause')
                facetData[:renderEvent] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.event')
                facetData[:renderIcdCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.icdCd')
                facetData[:renderExclusionTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclusionTypeCd')
                facetData[:renderExclLoadingTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclLoadingTypeCd')
                facetData[:renderExclPeriodTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclPeriodTypeCd')
                facetData[:renderExclPeriodUnit] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclPeriodUnit')
                facetData[:renderExclValue] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclValue')
                facetData[:renderExclDuration] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExclusion.exclDuration')

                facetData[:renderExtraFlatAmt] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.extraFlatAmt')
                facetData[:renderExtraFlatDuration] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.extraFlatDuration')
                facetData[:renderExtraPercDuration] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.extraPercDuration')
                facetData[:renderExtraPercent] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.extraPercent')
                facetData[:renderLoadingTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.loadingTypeCd')
                facetData[:renderPeriodTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.periodTypeCd')
                facetData[:renderPeriodUnit] = MobiSys::BrowserHelper.renderField?('PolicyUWResultExtraDtl.periodUnit')

                facetData[:renderExtraTypeCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultLoading.extraTypeCd')
                facetData[:renderReasonCd] = MobiSys::BrowserHelper.renderField?('PolicyUWResultReason.reasonCd')
                facetData[:renderRemarksKey] = MobiSys::BrowserHelper.renderField?('PolicyUWResultRemarks.remarksKey')
                return facetData
            end

            #-----Field Type Facets Start-----#
            #-------------Basic Facets-------------#
            facetData[:renderPartytypecd] = MobiSys::BrowserHelper.renderField?(classname + '.partyTypeCd')
            facetData[:renderCustomerId] = MobiSys::BrowserHelper.renderField?(classname + '.customerId')
            facetData[:renderTitlecd] = MobiSys::BrowserHelper.renderField?(classname + '.titleCd')

            facetData[:renderFirstname1] = MobiSys::BrowserHelper.renderField?(classname + '.firstName1')
            facetData[:renderMiddlename1] = MobiSys::BrowserHelper.renderField?(classname + '.middleName1')
            facetData[:renderLastname1] = MobiSys::BrowserHelper.renderField?(classname + '.lastName1')
            facetData[:renderExtensionname1] = MobiSys::BrowserHelper.renderField?(classname + '.extensionName1')

            facetData[:renderFirstname2] = MobiSys::BrowserHelper.renderField?(classname + '.firstName2')
            facetData[:renderMiddlename2] = MobiSys::BrowserHelper.renderField?(classname + '.middleName2')
            facetData[:renderLastname2] = MobiSys::BrowserHelper.renderField?(classname + '.lastName2')
            facetData[:renderExtensionname2] = MobiSys::BrowserHelper.renderField?(classname + '.extensionName2')

            facetData[:renderGendercd] = MobiSys::BrowserHelper.renderField?(classname + '.genderCd')
            facetData[:renderBirthdt] = MobiSys::BrowserHelper.renderField?(classname + '.birthDt')
            facetData[:renderAge] = MobiSys::BrowserHelper.renderField?(classname + '.age')

            facetData[:renderCountryOfBirth] = MobiSys::BrowserHelper.renderField?(classname + '.countryOfBirth')
            facetData[:renderPlaceOfBirth] = MobiSys::BrowserHelper.renderField?(classname + '.placeOfBirth')
            facetData[:renderMaritalStatusCd] = MobiSys::BrowserHelper.renderField?(classname + '.maritalStatusCd')

            facetData[:renderRelationcd] = MobiSys::BrowserHelper.renderField?(classname + '.relationCd')
            facetData[:renderMotherMaidenFirstname] = MobiSys::BrowserHelper.renderField?(classname + '.motherMaidenFirstname')
            facetData[:renderMotherMaidenLastname] = MobiSys::BrowserHelper.renderField?(classname + '.motherMaidenLastname')

            facetData[:renderSmoker] = MobiSys::BrowserHelper.renderField?(classname + '.smoker') 
            facetData[:renderNsap] = MobiSys::BrowserHelper.renderField?(classname + '.nsap')

            facetData[:renderFatherFirstName1] = MobiSys::BrowserHelper.renderField?(classname + '.fatherFirstName1')
            facetData[:renderFatherMiddleName1] = MobiSys::BrowserHelper.renderField?(classname + '.fatherMiddleName1')
            facetData[:renderFatherLastName1] = MobiSys::BrowserHelper.renderField?(classname + '.fatherLastName1')

            facetData[:renderCoveragecountrycd] = MobiSys::BrowserHelper.renderField?(classname + '.coverageCountryCd')
            facetData[:renderCoveragecitycd] = MobiSys::BrowserHelper.renderField?(classname + '.coverageCityCd')

            facetData[:renderCorporatename1] = MobiSys::BrowserHelper.renderField?(classname + '.corporateName1')
            facetData[:renderCorporatename2] = MobiSys::BrowserHelper.renderField?(classname + '.corporateName2')

            facetData[:renderCitizenshipCd] = MobiSys::BrowserHelper.renderField?(classname + '.citizenshipCd')
            facetData[:renderOtherCitizenship] = MobiSys::BrowserHelper.renderField?(classname + '.otherCitizenship')
            facetData[:renderNonResidentFl] = MobiSys::BrowserHelper.renderField?(classname + '.nonResidentFl')

            facetData[:renderReligionCd] = MobiSys::BrowserHelper.renderField?(classname + '.religionCd')
            facetData[:renderRaceCd] = MobiSys::BrowserHelper.renderField?(classname + '.raceCd')

            #-------------Identity Facets-------------#
            facetData[:renderIdentityTypeCd] = MobiSys::BrowserHelper.renderField?('PartyIdentityDO.identityTypeCd')
            facetData[:renderIdentityNum] = MobiSys::BrowserHelper.renderField?('PartyIdentityDO.identityNum')
            facetData[:renderIssuingAuthority] = MobiSys::BrowserHelper.renderField?('PartyIdentityDO.issuingAuthority')
            facetData[:renderIssueDt] = MobiSys::BrowserHelper.renderField?('PartyIdentityDO.issueDt')
            facetData[:renderExpiryDt] = MobiSys::BrowserHelper.renderField?('PartyIdentityDO.expiryDt')

            #-------------Occupation Facets-------------#
            facetData[:renderOccupationTypeCd] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.occupationTypeCd')
            facetData[:renderEmployerName] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.employerName')
            facetData[:renderPepCd] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.pepCd')
            facetData[:renderAnnualIncome] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.annualIncome')
            facetData[:renderIndustrycd] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.industryCd')
            facetData[:renderNatureofduty] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.natureOfDuty')
            facetData[:renderOccupationclass] = MobiSys::BrowserHelper.renderField?('PartyEmploymentDO.occupationClass')

            #-------------Address Facets-------------#
            facetData[:renderCopyFromAddr1] = MobiSys::BrowserHelper.renderField?(classname + '.copyFromAddr1')
            facetData[:renderCopyFromAddr2] = MobiSys::BrowserHelper.renderField?(classname + '.copyFromAddr2')
            facetData[:renderCopyFromAddr3] = MobiSys::BrowserHelper.renderField?(classname + '.copyFromAddr3')
            facetData[:renderAddressLine1Lang1] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine1Lang1')
            facetData[:renderaddressLine2Lang1] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine2Lang1')
            facetData[:renderaddressLine3Lang1] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine3Lang1')
            facetData[:renderaddressLine4Lang1] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine4Lang1')
            facetData[:renderAddressLine1Lang2] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine1Lang2')
            facetData[:renderaddressLine2Lang2] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine2Lang2')
            facetData[:renderaddressLine3Lang2] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine3Lang2')
            facetData[:renderaddressLine4Lang2] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.addressLine4Lang2')
            facetData[:renderAddressCountryCd] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.countryCd')
            facetData[:renderDistrictCd] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.stateCd')
            facetData[:renderCityCd] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.cityCd')
            facetData[:renderPinCode] = MobiSys::BrowserHelper.renderField?('PartyAddressDO.pinCode')

            #-------------Contact Facets-------------#
            facetData[:renderStdCode] = MobiSys::BrowserHelper.renderField?('PartyContactDO.stdCode')
            facetData[:renderContactNum] = MobiSys::BrowserHelper.renderField?('PartyContactDO.contactNum')
            facetData[:renderExtensionNum] = MobiSys::BrowserHelper.renderField?('PartyContactDO.extensionNum')
            facetData[:renderContactCountryCd] = MobiSys::BrowserHelper.renderField?('PartyContactDO.countryCd')
            facetData[:renderEmailaddress] = MobiSys::BrowserHelper.renderField?('PartyEmailDO.emailAddress')   

            #-------------Other Details Facets-------------#
            facetData[:renderPolicyDispatchModeCd] = MobiSys::BrowserHelper.renderField?('com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.policyDispatchModeCd')
            facetData[:renderCorrByEmail] = MobiSys::BrowserHelper.renderField?('com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.corrByEmail')
            facetData[:renderCommunicationPreference] = MobiSys::BrowserHelper.renderField?('com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO.communicationPreference')

            #-------------Beneficiary Specific Facets-------------#
            facetData[:renderNomineePartySameAs] = MobiSys::BrowserHelper.renderField?(classname + '.partySameAs')
            facetData[:renderNomineeTypeCd] = MobiSys::BrowserHelper.renderField?(classname + '.nomineeTypeCd')
            facetData[:renderEffectiveFromDt] = MobiSys::BrowserHelper.renderField?(classname + '.effectiveFromDt')
            facetData[:renderEffectiveToDt] = MobiSys::BrowserHelper.renderField?(classname + '.effectiveToDt')
            facetData[:renderPercentage] = MobiSys::BrowserHelper.renderField?(classname + '.percentage')
            facetData[:renderIrrevocablefl] = MobiSys::BrowserHelper.renderField?(classname + '.irrevocableFl')
            #-----Field Type Facets End-----#


            #-----Panel Facets Start-----#
            facetData[:renderNationalityPanel] = MobiSys::BrowserHelper.renderField?(classname + '.nationalityReqd')
            facetData[:renderIdentityPanel] = MobiSys::BrowserHelper.renderField?(classname + '.identityReqd')
            facetData[:renderOccupationPanel] = MobiSys::BrowserHelper.renderField?(classname + '.employmentDtlReqd')
            facetData[:renderAddressPanel] = MobiSys::BrowserHelper.renderField?(classname + '.addressReqd')
            facetData[:renderHomeAddressPanel] = MobiSys::BrowserHelper.renderField?(classname + '.residentalAddressReqd')
            facetData[:renderOfficeAddressPanel] = MobiSys::BrowserHelper.renderField?(classname + '.officeAddressReqd')
            facetData[:renderPermanentAddressPanel] = MobiSys::BrowserHelper.renderField?(classname + '.permanentAddressReqd')
            facetData[:renderContactPanel] = MobiSys::BrowserHelper.renderField?(classname + '.contactReqd')
            facetData[:renderHomeContactPanel] = MobiSys::BrowserHelper.renderField?(classname + '.residentalContactReqd')
            facetData[:renderOfficeContactPanel] = MobiSys::BrowserHelper.renderField?(classname + '.officeContactReqd')
            facetData[:renderMobileContactPanel] = MobiSys::BrowserHelper.renderField?(classname + '.mobileContactReqd')
            facetData[:renderEmailPanel] = MobiSys::BrowserHelper.renderField?(classname + '.emailReqd')        
            #-----Panel Facets End-----#

            #-----Product Facets Start-----#
            if product != nil
                facetData[:renderMultiLanguagePanel] = MobiSys::BrowserHelper.renderPanel?('MULTILINGUALPARTYNAME', product)
                facetData[:renderMiddlenamePanel] = MobiSys::BrowserHelper.renderPanel?('MIDDLENAMEREQUIRED', product)
                facetData[:readOnlyAge] = MobiSys::BrowserHelper.renderPanel?('AGECAPTUREREQUIRED', product)
                facetData[:renderNsapPanel] = MobiSys::BrowserHelper.renderPanel?(facetKeyPrefix + 'NSAP', product)
                facetData[:renderSmokerPanel] = MobiSys::BrowserHelper.renderPanel?(facetKeyPrefix + 'SMOKER', product)
                facetData[:renderCoverageLocPanel] = MobiSys::BrowserHelper.renderPanel?(facetKeyPrefix + 'COVERAGELOCATION', product)
                facetData[:renderCorporatePanel] = MobiSys::BrowserHelper.renderPanel?(facetKeyPrefix + 'CANBECORPORATE', product)
                facetData[:renderOccupationClassPanel] = MobiSys::BrowserHelper.renderPanel?(facetKeyPrefix + 'OCCUPATION', product)
                ageFacet = $rhoconfig[:majorAge]
                facetData[:majorAge] = ageFacet.actionValue if ageFacet
            end
            #------Product Facets End------#

            return facetData
        end

        def self.processPolicyResult(policy = nil, serviceDocumentList = nil , responseHash = {},facetData)
            @facetData = facetData
            if policy == nil && responseHash.has_key?(Policy.onlineClassName) && responseHash[Policy.onlineClassName].to_s != ""
            	@exclusionList = []
            	@coverageLoadingList = []
            	@requirementList     = []
            	@uwDecisionCd = ""
            	@taskExceptionsList = Array.new

                policyList = Rho::JSON.parse(responseHash[Policy.onlineClassName])
                if policyList != nil
                policyList.each do |pol|
                        policy = Policy.loadObject(:first,:conditions=>{:proposalNum=>pol["proposalNum"]})
                    	@facetData[:uwType] = "TYPE1"
                        overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                        overallUWDecisionLookup.each do |overallUWDecisionCd|
                            if overallUWDecisionCd.cd == policy.overallUWDecisionCd
                                @facetData[:uwType] = overallUWDecisionCd.additionalField2.to_s
                                break
                            end
                        end

                        serviceDocumentList = []
                        policy.PartyList.each do |party|
                            documentContainer = DocumentContainer.loadObject(
                                :first,
                                :conditions=>{
                                    {:name=>'entityGuid'}=> party.guid,
                                    {:name=>'policyGuid'}=> policy.guid
                                },
                                :op => 'AND',
                                :loadChild => 'false'
                            )
                            if documentContainer
                                partyDocumentList = ServiceDocument.loadObject(
                                    :all,
                                    :conditions=>{
                                        {:name=>'partyGuid'}=> party.guid,
                                        {:name=>'parentKey'}=> documentContainer.object
                                    },
                                    :op => 'AND',
                                    :loadChild => 'false'
                                )
                                #code added to make sericeDocument status received if document is selected and image exist 
                                partyDocumentList.each do|partydoc|
                                    imageList = Image.loadObject(
                                        :all,
                                        :conditions=>{
                                            {:name=>'parentRefGuid'}=> partydoc.uniqueKey
                                        },
                                        :loadChild => 'false'
                                    )
                                    if partydoc.acceptanceStatusCd != "FULFILLED" && imageList.size > 0 && partydoc.documentCd != "" && partydoc.documentCd != nil
                                        partydoc.imageCount = imageList.size
                                        partydoc.acceptanceStatusCd = "FULFILLED"
                                        partydoc.persistAll
                                    end
                                end
                                serviceDocumentList.concat partyDocumentList
                            end
                        end
                    end
                end
            end
            if policy
                uwDecisionLookup = Lookupvalue.getValue("DECISIONMASTER")
                if uwDecisionLookup
                    uwDecisionLookup.each do |uwDecisionCd|
                        if uwDecisionCd.cd == policy.uwDecisionCd && uwDecisionCd.additionalField1.to_s != ""
                            exceptionMessage = Localization::LabelCache.instance.getLabel(uwDecisionCd.additionalField1.to_sym).to_s.force_encoding("UTF-8").clone
		                    exceptionMessage = CommonUtil.replacePlaceHolders(exceptionMessage,[policy.policyNum])
		                    policy.uwDecisionValue = exceptionMessage
		                    break
                        end
                    end
                end


                if @facetData[:showResults]
                    overallUWDecisionLookup = Lookupvalue.getValue("UWDECISION")
                    overallUWDecisionLookup.each do |overallUWDecisionCd|
                        if overallUWDecisionCd.cd == policy.overallUWDecisionCd
                            overallUWDecisionCd.additionalField1.to_s.split(",").each do |panel|
                                @facetData[panel.to_sym] = true
                            end
                            break
                        end
                    end


                    #Hash setup for Exclusion Panel
                    if @facetData[:PolicyUWResultExclusion]
                        policy.PolicyResultList.each do |policyResult|
                            next if policyResult.decisionCd != "ACCEPTEDEXCLUSION"
                            tempResult = {}
                            tempResult[:event]           = policyResult.event.to_s
                            tempResult[:benefit]         = policyResult.benefit.to_s
                            tempResult[:cause]           = policyResult.cause.to_s
                            tempResult[:icdCd]           = policyResult.icdCd.to_s
                            tempResult[:reasonCd]        = policyResult.reasonCd.to_s
                            tempResult[:remarksKey]      = policyResult.remarksKey.to_s
                            tempResult[:exclusionTypeCd] = policyResult.exclusionTypeCd.to_s
                            loadingTypeCdLookup = Lookupvalue.find(
                                :first,
                                :conditions => {
                                    {:name => 'key'} => "LOADINGTYPE",
                                    {:name => 'cd'} => policyResult.exclLoadingTypeCd.to_s, 
                                },
                                :op => 'AND'
                            )
                            if loadingTypeCdLookup
                                tempResult[:exclLoadingTypeCd] = getLabelValue(loadingTypeCdLookup.desc.to_s)
                            else
                                tempResult[:exclLoadingTypeCd] = getLabelValue(policyResult.exclLoadingTypeCd.to_s)
                            end
                            policyResult.exclValue = policyResult.exclValue.to_f if policyResult.exclValue.class.to_s == "BigDecimal"
                            tempResult[:exclValue] = getMaskedValue(policyResult, "exclValue")
                            periodTypeCdLookup = Lookupvalue.find(
                                :first,
                                :conditions => {
                                    {:name => 'key'} => "PERIODTYPE",
                                    {:name => 'cd'} => policyResult.exclPeriodTypeCd.to_s,  
                                },
                                :op => 'AND'
                            )
                            if periodTypeCdLookup
                                tempResult[:exclPeriodTypeCd] = getLabelValue(periodTypeCdLookup.desc.to_s)
                            else
                                tempResult[:exclPeriodTypeCd] = getLabelValue(policyResult.exclPeriodTypeCd.to_s)
                            end
                            policyResult.exclDuration = policyResult.exclDuration.to_f if policyResult.exclDuration.class.to_s == "BigDecimal"
                            tempResult[:exclDuration] = getMaskedValue(policyResult, "exclDuration")
                            tempResult[:exclPeriodUnit] = policyResult.exclPeriodUnit.to_s
                            tempResult[:partyName] = getLabelValue(policy.getPartyByGuid(policyResult.partyRefGuid).titleCd.to_s) + " " + policy.getPartyByGuid(policyResult.partyRefGuid).firstName1.to_s + " " " " + policy.getPartyByGuid(policyResult.partyRefGuid).lastName1.to_s
                            policy.PolicyProductList.each do |policyProduct|
                                if policyProduct.guid == policyResult.policyProductRefGuid
                                    tempResult[:productName] = MobiSys::ProductUtil.getProduct(policyProduct.productSeq).shortName.to_s
                                    break
                                end
                            end
                            
                            @exclusionList.push(tempResult)
                        end
                    end


                    #Hash setup for Coverage & Loading Panel
                    if @facetData[:PolicyUWResultLoading]
                        policy.PolicyProductList.each do |policyProduct|
                            if policyProduct.PolicyProductExtraList.size > 0
                                tempResult = {}
                                productMaster = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                                tempResult[:productName] = getLabelValue(productMaster.shortName.to_s)

                                offlinePlan = nil
                                productMaster.OfflineFacetList.each do |facet|
                                    if facet.facetId == 'PLANOPTION'
                                        facet.OfflinePlanOptionList.each do |offlinePlanOption|
                                            if offlinePlanOption.optionCd == policyProduct.productPlanOptionCd
                                                offlinePlan = offlinePlanOption
                                                break
                                            end
                                        end
                                        break
                                    end
                                end                            
                                if offlinePlan
                                    tempResult[:productPlanOptionCd] = getLabelValue(offlinePlan.description.to_s)
                                else
                                    tempResult[:productPlanOptionCd] = getLabelValue(policyProduct.productPlanOptionCd.to_s)
                                end
                                policyProduct.baseSumAssured    = policyProduct.baseSumAssured.to_f if policyProduct.baseSumAssured.class.to_s == "BigDecimal"
                                tempResult[:baseSumAssured]     = getMaskedValue(policyProduct, "baseSumAssured")
                                policyProduct.productTerm       = policyProduct.productTerm.to_f if policyProduct.productTerm.class.to_s == "BigDecimal"
                                tempResult[:productTerm]        = getMaskedValue(policyProduct, "productTerm")
                                policyProduct.premiumPayingTerm = policyProduct.premiumPayingTerm.to_f if policyProduct.premiumPayingTerm.class.to_s == "BigDecimal"
                                tempResult[:premiumPayingTerm]  = getMaskedValue(policyProduct, "premiumPayingTerm")
                                policyProduct.modalPremium      = policyProduct.modalPremium.to_f if policyProduct.modalPremium.class.to_s == "BigDecimal"
                                tempResult[:modalPremium]       = getMaskedValue(policyProduct, "modalPremium")
                                policyProduct.extraPremium      = policyProduct.extraPremium.to_f if policyProduct.extraPremium.class.to_s == "BigDecimal"
                                tempResult[:extraPremium]       = getMaskedValue(policyProduct, "extraPremium")
                                tempResult[:partyName] = getLabelValue(policy.getMainInsured(policyProduct).titleCd.to_s) + " " + policy.getMainInsured(policyProduct).firstName1.to_s + " " " " + policy.getMainInsured(policyProduct).lastName1.to_s

                                tempResult[:policyProductExtra] = []
                                policyProduct.PolicyProductExtraList.each do |policyProductExtra|
                                    tempExtra = {}
                                    extraTypeCdLookup = Lookupvalue.find(
                                        :first,
                                        :conditions => {
                                            {:name => 'key'} => "PRODUCTEXTRATYPE",
                                            {:name => 'cd'} => policyProductExtra.extraTypeCd.to_s, 
                                        },
                                        :op => 'AND'
                                    )
                                    if extraTypeCdLookup
                                        tempExtra[:extraTypeCd] = getLabelValue(extraTypeCdLookup.desc.to_s)
                                    else
                                        tempExtra[:extraTypeCd] = getLabelValue(policyProductExtra.extraTypeCd.to_s)
                                    end

                                    loadingTypeCdLookup = Lookupvalue.find(:first,
                                        :conditions => {
                                            {:name => 'key'} => "LOADINGTYPE",
                                            {:name => 'cd'} => policyProductExtra.loadingTypeCd.to_s,   
                                        },
                                        :op => 'AND'
                                    )
                                    if loadingTypeCdLookup
                                        tempExtra[:loadingTypeCd] = getLabelValue(loadingTypeCdLookup.desc.to_s)
                                    else
                                        tempExtra[:loadingTypeCd] = getLabelValue(policyProductExtra.loadingTypeCd.to_s)
                                    end
                                    policyProductExtra.extraFlatAmt         = policyProductExtra.extraFlatAmt.to_f if policyProductExtra.extraFlatAmt.class.to_s == "BigDecimal"
                                    tempExtra[:extraFlatAmt]                = getMaskedValue(policyProductExtra, "extraFlatAmt")
                                    policyProductExtra.extraFlatDuration    = policyProductExtra.extraFlatDuration.to_f if policyProductExtra.extraFlatDuration.class.to_s == "BigDecimal"
                                    tempExtra[:extraFlatDuration]           = getMaskedValue(policyProductExtra, "extraFlatDuration")
                                    policyProductExtra.extraPercent         = policyProductExtra.extraPercent.to_f if policyProductExtra.extraPercent.class.to_s == "BigDecimal"
                                    tempExtra[:extraPercent]                = getMaskedValue(policyProductExtra, "extraPercent")
                                    policyProductExtra.extraPercDuration    = policyProductExtra.extraPercDuration.to_f if policyProductExtra.extraPercDuration.class.to_s == "BigDecimal"
                                    tempExtra[:extraPercDuration]           = getMaskedValue(policyProductExtra, "extraPercDuration")
                                    tempResult[:policyProductExtra].push(tempExtra)
                                end
                                
                                @coverageLoadingList.push(tempResult)
                            end
                        end
                    end

                    #Hash setup for Requirement Panel
                    if @facetData[:PolicyUWResultDocument]
                        if serviceDocumentList != nil
                            serviceDocumentList.each do |serviceDocument|
                                if serviceDocument.isAutoGeneratedFl == 'YES_UW'
                                    tempResult = {}
                                    documentCat = DocumentCategory.find(
                                        :first,
                                        :conditions => {
                                            {:name => "categoryCd"} => serviceDocument.docCategoryCd
                                        }
                                    )

                                    document = Document.find(
                                        :first,
                                        :conditions => {
                                            {:name => "documentCd"} => serviceDocument.documentCd
                                        }
                                    )
                                    if documentCat
                                        tempResult[:docCategoryCd] = documentCat.categoryDesc.to_s
                                    else
                                        tempResult[:docCategoryCd] = serviceDocument.docCategoryCd.to_s
                                    end

                                    if document
                                        tempResult[:documentCd] = document.documentDesc.to_s
                                    else
                                        tempResult[:documentCd] = serviceDocument.documentCd.to_s
                                    end

                                    party = Party.loadObject(
                                        :first,
                                        :conditions => {
                                            {:name => "guid"} => serviceDocument.partyGuid
                                        },
                                        :loadChild => 'false'
                                    )
                                    tempResult[:partyName] = getLabelValue(party.titleCd.to_s) + " " + party.firstName1.to_s + " " " " + party.lastName1.to_s
                                    tempResult[:documentStatusCd] = serviceDocument.acceptanceStatusCd
                                    @requirementList.push(tempResult)
                                    documentContainer = DocumentContainer.loadObject(
                                        :first,
                                        :conditions=>{
                                            {:name=>'entityGuid'}=> party.guid,
                                            {:name=>'policyGuid'}=> policy.guid
                                        },
                                        :op => 'AND',
                                        :loadChild => 'false'
                                    )
                                    documentContainer.addServiceDocument(serviceDocument)
                                    documentContainer.persistAll
                                end
                            end
                        end
                    end
                end
            end
            #Hash setup for Task Exception Panel
            taskExceptionClassName = TaskException.onlineClassName
            if responseHash.has_key?(taskExceptionClassName) && responseHash[taskExceptionClassName].to_s != ""
                taskExceptions = Rho::JSON.parse(responseHash[taskExceptionClassName])
                
                if taskExceptions != nil
                    taskExceptions.each do |taskException|
                       exception = MobiSys::MobiSysEntitySchema.from_hash('TaskException', taskException) 
                       @taskExceptionsList.push exception
                    end
                end
            end
        end


        ############################ Questionnaire Related Methods #####################################

        def self.getApplicableQuestionnaireResponse(partyGuid,questionnaireTypeList,baseIO)
        	$parentQuestionCd = ""
        	$policyModelEval = {}
			questionSetMasterList = []
			$questionnaireLookups = []
			applicableQuestionResponseList = []
			$currentPolicy = nil
			$currentPolicy = baseIO.baseDO
			quotation = MobiSys::PolicyBO.convertToQuotation(baseIO.baseDO) 
        	baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
        	quotationParty = nil
        	questionContainer = nil

			# $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
			getQuestionSetHash
        	getQuestionSetQuestionHash
        	# $questionSetData = QuestionSet.loadObject(:all) unless $questionSetData
	        $questionSetMapData = QuestionSetMap.find(
	            :all,
	            :order => ['parentQuestionSetCd', 'displayOrder']
	        ) unless $questionSetMapData

	     	if partyGuid.to_s != ""
	     		quotationParty = quotation.QuotationPartyList.select{|qp| qp.guid == partyGuid }.first
	     		policyProductInsuredObj = PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>quotationParty.guid,{:name=>'roleCd'} => quotationParty.roleCd},:op => 'AND')
	     		productFacet = $currentProduct.getFacet('PRODUCTQUESTIONSETGROUP')
	     		proposerQuestFacet = $currentProduct.getFacet('PROPOSERQUESTIONSETGROUP')
		        payerQuestFacet = $currentProduct.getFacet('PAYERQUESTIONSETGROUP')
		        questionSetCd = ""
		        proposerQuestionSetCd = ""
		        payerQuestionSetCd = ""
		        questionnaireTypeCd = ""
		        displayProductQuestion = false
		        if productFacet
		            if productFacet.actionTypeCd=='VALUE' || productFacet.actionTypeCd=='LOOKUP'
		                questionSetCd = productFacet.actionValue
		            elsif productFacet.actionTypeCd=='RULE'
		                prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(productFacet.ruleSeq, quotation, baseProduct, quotationParty)
		                questionSetCd = (prodFacetDT.to_s != "" && prodFacetDT.outputAction.to_s != "") ? prodFacetDT.outputAction.to_s : ((prodFacetDT.to_s != "" && prodFacetDT.questionSetCd.to_s != "") ? prodFacetDT.questionSetCd.to_s : "")
		            end
		        end
		        displayProductQuestion = true if questionSetCd.to_s != ""

				questionnaireTypeList.each do |qType|
			        displayProposerQuestion = false
		        	displayPayerQuestion = false
					key = qType.keys.first.to_s
					if key == "PROPOSERPARTY"
				    	insuredPartyRole = baseIO.baseDO.getPolicyPartyRole("PRIMARY")
			            if insuredPartyRole
			                proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
			            else
			                proposerIsSameAsInsured = false
			            end
			            if proposerQuestFacet != nil
			                if proposerQuestFacet.actionTypeCd=='VALUE' || proposerQuestFacet.actionTypeCd=='LOOKUP'
			                    proposerQuestionSetCd = proposerQuestFacet.actionValue
			                elsif proposerQuestFacet.actionTypeCd=='RULE'
			                    prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(proposerQuestFacet.ruleSeq, quotation, baseProduct, quotationParty)
			                    proposerQuestionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
			                end
			                displayProposerQuestion = true if proposerQuestionSetCd.to_s != ''
			            end
			            if policyProductInsuredObj == nil && !proposerIsSameAsInsured
			                 displayProductQuestion = false
			            end
				    elsif key == "PAYERPARTY"
				    	displayProductQuestion = false
				    	if payerQuestFacet
				            if payerQuestFacet.actionTypeCd=='VALUE' || payerQuestFacet.actionTypeCd=='LOOKUP'
				                payerQuestionSetCd = payerQuestFacet.actionValue
				            elsif payerQuestFacet.actionTypeCd=='RULE'
				                prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(payerQuestFacet.ruleSeq, quotation, baseProduct, quotationParty)
				                payerQuestionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
				            end
				            displayPayerQuestion = true if payerQuestionSetCd != ''
				        end
					end
			
					if displayProductQuestion and key.to_s == "INSUREDPARTY"
			            # display product question for insured/joint/supplementary/proposer/payer
			            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, questionSetCd)
			            questionSetMasterList.push questionnaireHash if questionnaireHash
			        end

			        if displayProposerQuestion
			            # display proposer questions for proposer
			            questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, proposerQuestionSetCd)
			            questionSetMasterList.push questionnaireHash if questionnaireHash
			        end

			        if displayPayerQuestion
			            # display payer questions for payer
			            payerQuestionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, payerQuestionSetCd)
			            questionSetMasterList.push payerQuestionnaireHash if payerQuestionnaireHash
			        end
				end
				
				questionContainer = QuestionContainer.loadObject(
		            :first, 
		            :conditions=>{
		                {:name=>'entityGuid'} => quotationParty.guid,
		                {:name=>'policyGuid'} => baseIO.baseDO.uniqueKey
		            },
		            :op => 'AND'
		        ) || 
		        QuestionContainer.new(
		            :entityGuid => quotationParty.guid,
		            :entityTypeCd => quotationParty.roleCd,
		            :policyGuid => baseIO.baseDO.uniqueKey
		        )
		        
		        # MobiSys::Questionnaire.setupResponseHash(questionContainer)
		        s1 = Time.now
				questionSetMasterList.each do |questionSet|
					#Don't include the parent wrapper in the Party Question List
					if questionSet[:questionSetTypeCd].to_s != "PARENTWRAPPER"
						questionSetMap = getRecursiveQuestionSet(questionSet,partyGuid,baseIO,questionContainer,quotation,quotationParty)
						applicableQuestionResponseList.push questionSetMap if questionSetMap != nil and questionSetMap.size > 0
					else
						questionSet["listQuestionSetDOList"].each do |childQSet|
							questionSetMap = getRecursiveQuestionSet(childQSet,partyGuid,baseIO,questionContainer,quotation,quotationParty,nil,questionSet)
							applicableQuestionResponseList.push questionSetMap if questionSetMap != nil and questionSetMap.size > 0
						end
					end
				end
				#RhoLog.error("Recursive method=====","Recursive method final==#{Time.now - s2}")
	     	else
	     		productFacet = $currentProduct.getFacet('AGENTQUESTIONSETGROUP')
        		questionSetCd = ""
        		questionSetCd = productFacet.actionValue if productFacet

        		questionnaireHash = MobiSys::Questionnaire.getQuestionnaire($questionSetData, $questionSetMapData, questionSetCd)
        		questionSetMasterList.push(questionnaireHash)

        		questionContainer = QuestionContainer.loadObject(
		            :first, 
		            :conditions=>{
		                {:name=>'entityGuid'} => baseIO.baseDO.uniqueKey,
		                {:name=>'policyGuid'} => baseIO.baseDO.uniqueKey,
		                {:name=>'entityTypeCd'} => 'AGENT'
		            },
		            :op => 'AND'
		        ) || 
		        QuestionContainer.new(
		            :entityGuid => baseIO.baseDO.uniqueKey,
		            :policyGuid => baseIO.baseDO.uniqueKey,
		            :entityTypeCd => 'AGENT'
		        )
		        
		        questionSetMasterList.each do |questionSet|
					#Don't include the parent wrapper in the Agent Declaration Question List
					if questionSet[:questionSetTypeCd].to_s != "PARENTWRAPPER"
						questionSetMap = getRecursiveQuestionSet(questionSet,partyGuid,baseIO,questionContainer,quotation)
						applicableQuestionResponseList.push questionSetMap if questionSetMap != nil and questionSetMap.size > 0
					else
						questionSet["listQuestionSetDOList"].each do |childQSet|
							questionSetMap = getRecursiveQuestionSet(childQSet,partyGuid,baseIO,questionContainer,quotation)
							applicableQuestionResponseList.push questionSetMap if questionSetMap != nil and questionSetMap.size > 0
						end
					end
				end
	     	end

	     	return applicableQuestionResponseList
		end

		def self.getRecursiveQuestionSet(questionSet, partyGuid,baseIO=nil,questionContainer=nil,quotation=nil,quotationParty=nil,responseHash=nil,questionSetHash=nil,parentReferencePath=nil)		
            quotationParty = nil if questionContainer.entityTypeCd.to_s == "AGENT"
			#This logic checks if there is any DT and evaluates DT to check if questionSet is applicable
			return if !MobiSys::Questionnaire.isQuestionSetApplicable(baseIO, quotation, questionSet, partyGuid)

			responseHash = (responseHash  != nil ? responseHash : MobiSys::Questionnaire.setupResponseHash(questionContainer))
			questionSetQuestionDO = MobiSys::Questionnaire.getQuestionSetQuestion(questionSet)

			return if !MobiSys::Questionnaire.isQuestionApplicable(questionSet, partyGuid, questionSetQuestionDO,baseIO,questionContainer,responseHash,parentReferencePath)
			
			#The below logic checks if the question set is a conditional question set then evaluates the answer of the parent Question set
			
			if questionSet[:questionSetTypeCd] == "LEAF"
				if questionSet.has_key?("listQuestionSetQuestionDOList")
					firstQuestionSetQuestionDO = questionSet["listQuestionSetQuestionDOList"][0]
           		end
            end
			questionSetRespMap = {}
			questionSetRespMap['questionSetCd'] = questionSet[:questionSetCd]
			questionSetRespMap["displayNum"] = questionSet[:displayNumber]
			questionSetRespMap["questionSetTypeCd"] = questionSet[:questionSetTypeCd]
			questionSetRespMap["headerText"] = (questionSet.has_key?(:header) ? questionSet[:header] : nil)
			isGridBasedFl = (questionSet.has_key?(:isGridTypeFl) ? (questionSet[:isGridTypeFl].to_s == "YES" ? true : false) : false)
			questionSetRespMap["isGridBasedFl"] = isGridBasedFl
			if parentReferencePath
				questionSetRespMap["parentReferencePath"] = parentReferencePath
			elsif firstQuestionSetQuestionDO
				questionSetRespMap["parentReferencePath"] = firstQuestionSetQuestionDO[:parentReferencePath] 
			else
				questionSetRespMap["parentReferencePath"] = questionSetHash[:questionSetCd] if questionSetHash
			end
			#2 dimension array logic for grid based questions
			if isGridBasedFl
				reflexiveQuestion = nil
				reflexiveQuestion = MobiSys::Questionnaire.getReflexiveQuestion(questionSet["listQuestionSetQuestionDOList"]) if questionSet != nil and questionSet["listQuestionSetQuestionDOList"] != nil
				#for grid based questionnaire if there is a single reflexive question we will have to add it separately to the QuestionSet object
				#since it does not fit into the 2 dimensional array structure
				if reflexiveQuestion != nil
					gridBasedReflexiveQuestionRespMap = createQuestionSetQuestionResponseMap(questionSet, partyGuid, reflexiveQuestion, baseIO, quotationParty, questionContainer, responseHash , nil)
					questionSetRespMap["gridReflexiveQuestion"] = gridBasedReflexiveQuestionRespMap
				end

				#Get questions for the current questionSetCd and current party
				linkHashQuestionSet = nil
				listRowGuid = nil
				linkHashQuestionSet = MobiSys::CommonUtil.getLinkedHashedList("questionSetCd",responseHash.values)
				if !linkHashQuestionSet.empty?
					questionSetRespList = linkHashQuestionSet[questionSet[:questionSetCd]]
					partyQRespList = []
					#check if there are any responses already existing for the party
					if partyGuid
						partyHashServiceQResp = MobiSys::CommonUtil.getLinkedHashedList("partyGuid",questionSetRespList)
						partyQRespList = partyHashServiceQResp[partyGuid]
					else
						#if partyguid is nil then consider all responses to belong to the entity itself
						partyQRespList = questionSetRespList
					end
					rowHashServiceQResp = MobiSys::CommonUtil.getLinkedHashedList("rowGuid",partyQRespList)
					listRowGuid = rowHashServiceQResp.keys.select{|val| val if val.to_s != ""}  if !rowHashServiceQResp.empty?
				end

				outerListApplicableQuestDataResponse = []
				if listRowGuid != nil and listRowGuid.size > 0
					#below logic is for looping and displaying existing questionnaire responses.
					listRowGuid.each do |rowGuid|
						innerListApplicableQuestDataResponse = []
						if questionSet["listQuestionSetQuestionDOList"] != nil
							questionSet["listQuestionSetQuestionDOList"].each do |questionSetQuestion|
								next if questionSetQuestion[:conditional] == "REFLEXIVE"
								next if !MobiSys::Questionnaire.isQuestionApplicable(questionSet, partyGuid, questionSetQuestion,baseIO,questionContainer,responseHash)
								questionRespMap = createQuestionSetQuestionResponseMap(questionSet,partyGuid,questionSetQuestion,baseIO,quotationParty,questionContainer,responseHash,rowGuid)
								innerListApplicableQuestDataResponse.push(questionRespMap)
							end
							outerListApplicableQuestDataResponse.push(innerListApplicableQuestDataResponse) if innerListApplicableQuestDataResponse.size > 0
						end
					end
				else
					#if no existing responses exist.. then dont add a blank row of questions since this should come only on selection of yes 
					#But if the reflexive question answered is positive then add a blank row
					#check if even 1 question is applicable then 1 row needs to be added
					if questionSet["listQuestionSetQuestionDOList"] != nil
						innerListApplicableQuestDataResponse = []
						questionSet["listQuestionSetQuestionDOList"].each do |questionSetQuestion|
							next if questionSetQuestion[:conditional] == "REFLEXIVE"

							next if !MobiSys::Questionnaire.isQuestionApplicable(questionSet, partyGuid, questionSetQuestion,baseIO,questionContainer,responseHash)

							questionRespMap = createQuestionSetQuestionResponseMap(questionSet,partyGuid,questionSetQuestion,baseIO,quotationParty,questionContainer,responseHash,"0")
							innerListApplicableQuestDataResponse.push(questionRespMap)
						end
						outerListApplicableQuestDataResponse.push(innerListApplicableQuestDataResponse) if innerListApplicableQuestDataResponse.size > 0
					end
				end
				questionSetRespMap["questions"] = outerListApplicableQuestDataResponse
			else
				#for non grid based a single dimensional array is required.
				 
				listApplicableQuestDataResponse = []
				if questionSet["listQuestionSetQuestionDOList"] != nil
					questionSet["listQuestionSetQuestionDOList"].each do |questionSetQuestion|
						# Check if question is applicable based on the response of the single reflexive question within the question set
						applicable = MobiSys::Questionnaire.isQuestionApplicable(questionSet, partyGuid, questionSetQuestion,baseIO,questionContainer,responseHash)
						next if !applicable
						questionRespMap = createQuestionSetQuestionResponseMap(questionSet, partyGuid,	questionSetQuestion,baseIO,quotationParty,questionContainer,responseHash,nil)
						listApplicableQuestDataResponse.push(questionRespMap)
					end
				end
				questionSetRespMap["questions"] = listApplicableQuestDataResponse
				
			end 
			
			if questionSet["listQuestionSetDOList"] != nil and questionSet["listQuestionSetDOList"].size > 0

				applicableQuestionResponseList = []
				questionSetQuestionDO = MobiSys::Questionnaire.getQuestionSetQuestion(questionSet)
				
				currentQuestionSetResponse = responseHash["#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}|#{questionSetQuestionDO[:parentReferencePath]}#{"|#{partyGuid}" if partyGuid.to_s != ''}"] if questionSetQuestionDO
				if (currentQuestionSetResponse && currentQuestionSetResponse.responseValue != "" && currentQuestionSetResponse.responseValue != nil) || questionSet[:header].to_s != ""
					questionSet["listQuestionSetDOList"].each do |questionSetChild|
						childQSetMap = getRecursiveQuestionSet(questionSetChild,partyGuid,baseIO,questionContainer,quotation,quotationParty,responseHash)
						applicableQuestionResponseList.push childQSetMap if childQSetMap != nil
					end
				end

				questionSetRespMap["questionSets"] = applicableQuestionResponseList
			end
			
			return questionSetRespMap
		end

		def self.createQuestionSetQuestionResponseMap(questionSet,partyGuid,questionSetQuestion,baseIO,quotationParty,questionContainer,responseHash,rowGuid = nil)
			questionRespMap = {}
			questionRespMap["dataElementCd"] = questionSetQuestion[:dataElementCd]
			if questionSetQuestion[:inputTypeCd].to_s != "HIDDEN" || (questionSetQuestion[:inputTypeCd].to_s == "HIDDEN" &&questionSetQuestion[:conditional].to_s == "STATIC")
				questionRespMap["questionText"] = questionSetQuestion[:question]
				questionRespMap["questionLabelKey"] = questionSetQuestion[:questionCd]
				questionRespMap["questionLabelLang"] = MobiSys::BrowserHelper.getLabel(questionSetQuestion[:questionCd])
			end
			questionRespMap["displayNum"] = questionSetQuestion[:displayNumber]
			questionRespMap["inputTypeCd"] = questionSetQuestion[:inputTypeCd]
			questionRespMap["lookupKey"] = questionSetQuestion[:lookupkey] if questionSetQuestion.has_key?(:lookupkey)
			questionRespMap["parentReferencePath"] = questionSetQuestion[:parentReferencePath] if questionSetQuestion.has_key?(:parentReferencePath)
			resVal = responseHash["#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{questionSetQuestion[:parentReferencePath]}#{"|#{quotationParty.guid}" if quotationParty.to_s != ''}"] if responseHash && responseHash.is_a?(Hash) && !responseHash.empty?
			if resVal && (!questionSetQuestion[:parentReferencePath].to_s.include?($parentQuestionCd.to_s) || $parentQuestionCd == "")
				questionRespMap["responseValue"] = resVal.responseValue 
			else
				questionRespMap["responseValue"] = ""
			end

			defaultValue = ""
			labelValueModelElem = ""
			if questionSetQuestion[:otherMetadataProps].to_s != ""
				otherMetadataPropsHM = Rho::JSON.parse(questionSetQuestion[:otherMetadataProps])
				if otherMetadataPropsHM.is_a?(Hash) && !otherMetadataPropsHM.empty?
					questionRespMap.merge!(otherMetadataPropsHM)
					if otherMetadataPropsHM.has_key?("DEFAULTVALUE")
						defaultValue = otherMetadataPropsHM["DEFAULTVALUE"]
					end
					if otherMetadataPropsHM.has_key?("LABELVAL_MODELELEM")
						labelValueModelElem = otherMetadataPropsHM["LABELVAL_MODELELEM"]
					end
			    end
			end

			#add the lookupkey to list of additional lookups to be loaded
			if questionSetQuestion.has_key?(:lookupkey) and questionSetQuestion[:lookupkey].to_s != ""
				addtnlLookup = {}
				baseIO.additionalData = {} if (baseIO.additionalData == nil || (baseIO.additionalData != nil and !baseIO.additionalData.is_a?(Hash)))
				addtnlLookup[questionSetQuestion[:lookupkey].to_s] = []
				
				if !addtnlLookup.empty?
					if ((baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and baseIO.additionalData["ADDTNL_LOOKUPS"] == nil) || baseIO.additionalData.empty? || (!baseIO.additionalData.empty? and !baseIO.additionalData.has_key?("ADDTNL_LOOKUPS")))
						baseIO.additionalData["ADDTNL_LOOKUPS"] = []
					end

					baseIO.additionalData["ADDTNL_LOOKUPS"].push(addtnlLookup) if baseIO.additionalData["ADDTNL_LOOKUPS"].select{|lookups| lookups if lookups.has_key?(questionSetQuestion[:lookupkey].to_s)}.size == 0
				end
			end

			isRemoteSellingCompleteFlag = MobiSys::PolicyService.isRemoteSellingComplete(baseIO.baseDO)
			questionRespMap["dataTypeCd"] = questionSetQuestion[:dataElementType]
			questionRespMap["minOccurs"] = (questionSetQuestion[:mandatory].to_s == "YES" ? 1 : 0)
			questionRespMap["maxLength"] = questionSetQuestion[:maxLength]
			questionRespMap["minValue"] = questionSetQuestion[:minValue]
			questionRespMap["maxValue"] = questionSetQuestion[:maxValue]
			questionRespMap["isReflexiveFl"] = (questionSetQuestion[:conditional].to_s == "REFLEXIVE" ? true : false)
			questionRespMap["partOfImpactingQuest"] = (questionSetQuestion[:applyOn].to_s == "YES" ? false : false)
			questionRespMap["enabled"] = questionSetQuestion[:enabled]
			#Agent/Insured party questionnaire should be read only for the following statuses
			if(questionContainer.entityTypeCd.to_s != "AGENT" and (baseIO.baseDO.statusCd.to_s == "ACCEPTED" || baseIO.baseDO.statusCd.to_s == "PAYMENTPENDING" || baseIO.baseDO.statusCd.to_s == "PAYMENTDONE" || baseIO.baseDO.statusCd.to_s == "PAYMENTFAILED" || baseIO.baseDO.statusCd.to_s == "PAYMENTSUCCESS" || baseIO.baseDO.statusCd.to_s == "SUBMITTED" || baseIO.baseDO.statusCd.to_s == "SUBMITTED_UWCUSTOMERINPUT" || baseIO.baseDO.statusCd.to_s == "SUBMITTED_UWCOMPLETE" || baseIO.baseDO.statusCd.to_s == "SIGNED" || baseIO.baseDO.statusCd.to_s == "DECLARATIONCOMPLETE" || baseIO.baseDO.policyNum.to_s != ""))
				questionRespMap["enabled"] = "NO"
			elsif(questionContainer.entityTypeCd.to_s == "AGENT" and (baseIO.baseDO.statusCd.to_s == "SUBMITTED" || baseIO.baseDO.statusCd.to_s == "SUBMITTED_UWCUSTOMERINPUT" || baseIO.baseDO.statusCd.to_s == "SUBMITTED_UWCOMPLETE" || baseIO.baseDO.policyNum.to_s != ""))
				questionRespMap["enabled"] = "NO"
			elsif(baseIO.baseDO.allocatedToRole.to_s != "" && baseIO.baseDO.allocatedToRole.to_s != "AGENT") || (isRemoteSellingCompleteFlag == true && questionContainer.entityTypeCd.to_s != "AGENT")
				questionRespMap["enabled"] = "NO"
			end

			resp = MobiSys::Questionnaire.getResponseForApi(questionSetQuestion, questionSet[:isGridTypeFl], questionContainer, responseHash, quotationParty, rowGuid)

			key = "#{questionSet[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
			key << "|#{partyGuid}" if partyGuid.to_s != ""
			key << "|#{rowGuid}" if rowGuid.to_s != ""
            party = baseIO.baseDO.getPartyByGuid(partyGuid)
			# If no existing response exists then Check if there is any assignment of response in the Model evaluation
			# eg. defaulting of smoker values from the Policy object is done in the Policy Model.
			# if(resp.to_s == "" && questionSetQuestion[:modelCd].to_s != "")
			questionSetQuestionDO = MobiSys::Questionnaire.getQuestionSetQuestion(questionSet)
			currentQuestionSetResponse = responseHash["#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}|#{questionSetQuestionDO[:parentReferencePath]}#{"|#{partyGuid}" if partyGuid.to_s != ''}"] if questionSetQuestionDO
			# if (currentQuestionSetResponse && currentQuestionSetResponse.responseValue != "" && currentQuestionSetResponse.responseValue != nil) || questionSet[:header].to_s != ""
				if questionSetQuestion[:modelCd].to_s != ""
					resp = createServiceQuestionResponse(partyGuid, questionSet[:questionSetCd], rowGuid, responseHash[key], questionContainer.ServiceQuestionResponseList, baseIO, nil) if resp.to_s == ""
					policyModel = PolicyUtil::PolicyModel.new
					modelResultDO = policyModel.execute(baseIO.baseDO, baseIO.baseDO.getBaseProduct, party, questionSetQuestion[:modelCd])
					if labelValueModelElem.to_s != "" && modelResultDO.to_s != "" && modelResultDO.getFieldValue(labelValueModelElem).to_s != ""
						questionRespMap["questionLabelKey"] = modelResultDO.getFieldValue(labelValueModelElem)
						questionRespMap["questionLabelLang"] = modelResultDO.getFieldValue(labelValueModelElem)
					end
					if modelResultDO
					   metadataElems = ["minOccurs", "maxLength", "minValue", "maxValue", "enabled", "visibility", "inputTypeCd", "lookupKey","MINVALUEWARN","MAXVALUEWARN"]
					  metadataElems.each do |metadataElem|
					    if modelResultDO.containsFieldInMap(metadataElem) && modelResultDO.getFieldValue(metadataElem)
					      questionRespMap[metadataElem.to_s] = modelResultDO.getFieldValue(metadataElem)
					    end
					  end
					end
				end
			# end
			
			if resp.to_s != "" && (!questionSetQuestion[:parentReferencePath].to_s.include?($parentQuestionCd.to_s) || $parentQuestionCd == "")
				responseVal = resp.responseValue
			else
				responseVal = ""
			end
			tooltipval = Localization::LabelCache.instance.getLabelToolTipValue(questionSetQuestion[:questionCd].to_s)
			if tooltipval.to_s != ""
				questionRespMap["questionToolTip"] = tooltipval
			end
			
			questionRespMap["responseValue"] = responseVal.to_s == "" && defaultValue.to_s != "" ? defaultValue.to_s : responseVal.to_s
			if responseVal.to_s != "" and questionRespMap["inputTypeCd"].to_s == "DATE"
				questionRespMap["responseValue"] = responseVal.to_i
			end

			#Adding the ServiceQuestionResponse guid as this record guid since used for identifying the mandatory error messages on the UI. 
			questionRespMap["guid"] = (resp.to_s == "" ? nil : resp.guid)
			if questionRespMap["inputTypeCd"] == "HIDDEN" && questionRespMap["isReflexiveFl"]
				#first check if a response already exists.. if so then replace that response else add new response from UI
				if resp.to_s == ""
	                sqRespDO = ServiceQuestionResponse.new
	                sqRespDO.partyGuid = partyGuid
	                sqRespDO.questionSetCd = questionSetQuestion[:questionSetCd]
	                sqRespDO.questionDataElementCd = questionSetQuestion[:dataElementCd]
	                sqRespDO.parentReferencePath = questionRespMap["parentReferencePath"]
	                sqRespDO.questionnaireTypeCd = questionSetQuestion[:questionnaireTypeCd].to_s
	                sqRespDO.entityGuid = questionContainer.policyGuid
	                questionContainer.addServiceQuestionResponse(sqRespDO)
	                questionContainer.persistAll
	                key = "#{sqRespDO.questionSetCd}|#{sqRespDO.questionDataElementCd}"
	                key << "|#{sqRespDO.parentReferencePath}" if sqRespDO.parentReferencePath.to_s != ""
	                key << "|#{sqRespDO.partyGuid}" if sqRespDO.partyGuid.to_s != ""
	                key << "|#{sqRespDO.rowGuid}" if sqRespDO.rowGuid.to_s != ""
	                $responseHash[key] = sqRespDO
	                party = baseIO.baseDO.getPartyByGuid(partyGuid)
	                if questionSetQuestion && questionSetQuestion[:modelCd].to_s != ""
		                $parentReferenceForPolModel = questionRespMap["parentReferencePath"]
		                MobiSys::Questionnaire.evaluateExpressionBasedReflexiveQuestionSet(questionSetQuestion[:modelCd], nil, questionContainer, party, baseIO.baseDO)
		                $parentReferenceForPolModel = ""
		            end
	            else 
		            key = "#{resp.questionSetCd}|#{resp.questionDataElementCd}"
	                key << "|#{resp.parentReferencePath}" if resp.parentReferencePath.to_s != ""
	                key << "|#{resp.partyGuid}" if resp.partyGuid.to_s != ""
	                key << "|#{resp.rowGuid}" if resp.rowGuid.to_s != ""
	                $responseHash[key] = resp
	                party = baseIO.baseDO.getPartyByGuid(partyGuid)
	                if questionSetQuestion && questionSetQuestion[:modelCd].to_s != ""
		                $parentReferenceForPolModel = questionRespMap["parentReferencePath"]
		                MobiSys::Questionnaire.evaluateExpressionBasedReflexiveQuestionSet(questionSetQuestion[:modelCd], nil, questionContainer, party, baseIO.baseDO)
		                $parentReferenceForPolModel = ""
		            end   
               end
			end
			# questionRespMap = {} if questionRespMap["inputTypeCd"] == "HIDDEN" && questionRespMap["isReflexiveFl"]
			updateQuestionRespProperties(questionRespMap, questionSet, partyGuid, questionSetQuestion)
			return questionRespMap
		end

		def self.updateQuestionRespProperties(questionRespMap, questionSet, partyGuid, questionSetQuestion)
			if questionSetQuestion && questionSetQuestion[:entityFieldTypeCd].to_s != ""
			  entityTypeDO = $entityTypeCache[questionSetQuestion[:entityFieldTypeCd].to_s.to_sym] if $entityTypeCache
                if entityTypeDO !=nil
                    entityTypeDO.EntityPropertyList.each do |entityProperty|
                    	 if entityProperty.propertyCd.to_s == "BLACKLISTCHARS"
						  questionRespMap["BLACKLISTCHARS"] = entityProperty.propertyValue.to_s
						 end  
				    end
				end    
			end
		end

		def self.createServiceQuestionSetResponse(partyGuid,questionSetResponse, listServiceQuestionResponse,baseIO,questionnaireTypeCd)
			return if questionSetResponse == nil

			isGridBasedFl = questionSetResponse["isGridBasedFl"]
			if !isGridBasedFl
				#for non grid based we get a single dimensional array of data elements
				listQuestionResponse = ( questionSetResponse.has_key?("questions") ? questionSetResponse["questions"] : [])
				listQuestionResponse.each do |questionResponse|
					createServiceQuestionResponse(partyGuid,questionSetResponse["questionSetCd"].to_s,nil,questionResponse,listServiceQuestionResponse,baseIO,questionnaireTypeCd)
				end
			else
				#first create response for the single reflexive question asked
				gridSingleReflexiveQuest = questionSetResponse["gridReflexiveQuestion"]
				createServiceQuestionResponse(partyGuid,questionSetResponse["questionSetCd"].to_s,nil,gridSingleReflexiveQuest,listServiceQuestionResponse,baseIO,questionnaireTypeCd)

				#now get the remaining 2 dimensional array of questions
				outerListQuestionResponse = (questionSetResponse.has_key?("questions") ? questionSetResponse["questions"] : [])
				#loop through the question response array
				rowId = 0

				outerListQuestionResponse.each do |listQuestionResponse|
					#create question response
					#link all these question response of a single record with a rowguid
					listQuestionResponse.each do |questionResponse|
						createServiceQuestionResponse(partyGuid,questionSetResponse["questionSetCd"].to_s,rowId.to_s,questionResponse,listServiceQuestionResponse,baseIO,questionnaireTypeCd)
					end
					rowId += 1
				end
			end

			#call recursively question set response for child question sets within current Question set
			listChildQuestionSetResponse = questionSetResponse["questionSets"]
			if listChildQuestionSetResponse != nil
				listChildQuestionSetResponse.each do |childQuestionSetResponse|
					createServiceQuestionSetResponse(partyGuid,childQuestionSetResponse,listServiceQuestionResponse,baseIO,questionnaireTypeCd)
				end
			end

		end


		def self.createServiceQuestionResponse(partyGuid, questionSetCd, rowGuid, questionResponse,
			listServiceQuestionResponse,baseIO,questionnaireTypeCd)
			return if questionResponse == nil

			guid = questionResponse["guid"]
			serviceQuestionResponse = nil
			if guid.to_s != ""
				serviceQuestionResponse = ServiceQuestionResponse.new(:guid => guid)
			else
				serviceQuestionResponse = ServiceQuestionResponse.new
			end

			serviceQuestionResponse.entityGuid = baseIO.baseDO.uniqueKey
			serviceQuestionResponse.questionSetCd = questionSetCd
			serviceQuestionResponse.partyGuid = partyGuid
			serviceQuestionResponse.responseValue = questionResponse["responseValue"].to_s if questionResponse["responseValue"].to_s != ""
			serviceQuestionResponse.questionnaireTypeCd = questionnaireTypeCd
			serviceQuestionResponse.questionDataElementCd = questionResponse["dataElementCd"]
			serviceQuestionResponse.parentReferencePath = questionResponse["parentReferencePath"]
			serviceQuestionResponse.rowGuid = rowGuid
			serviceQuestionResponse.status = ""
			listServiceQuestionResponse.push(serviceQuestionResponse)
			return serviceQuestionResponse
		end


        ################################################################################################

        def self.getDocumentCategoryCd(policy, party)
			partyRole = nil
            policy.PolicyPartyRoleList.each do |ppr|
                if ppr.refGuid == party.guid
                    partyRole = ppr
                    break
                end
            end
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
            policyPayment = policy.getPolicyPayment("RENEWALPREMIUM")
            if policyPayment != nil && (partyRole.roleCd == "PROPOSER" || partyRole.roleCd == "PAYER") && baseProduct != nil
                baseProduct.paymentMethodCd = policyPayment.paymentMethodCd
            end
            if baseProduct
                originalPartyRole = baseProduct.partyRoleCd
                originalInsureRefGuid = baseProduct.insuredPartyRefGuid
                originalCombinedEntryAge = baseProduct.combinedEntryAge
                baseProduct.partyRoleCd = partyRole.roleCd
                if partyRole.roleCd == "SUPPLEMENTARY" || partyRole.roleCd == "NOMINEE"
                    baseProduct.insuredPartyRefGuid = party.object
                    baseProduct.combinedEntryAge = party.age
                end
            end
            categoriesDerivedFromDT = []
            for i in 0..20
                if i == 0
                    i = ""
                end
                nbReqName = "NBREQUIRMENTS" << i.to_s
                offlineFacet = $currentProduct.getFacet(nbReqName)
                if  (offlineFacet && offlineFacet.applicableRoles.to_s == "" ) || (offlineFacet  && offlineFacet.applicableRoles.to_s.split(",").include?(party.roleCd.to_s))
                    ttms = $currentProduct.getTableTypeMappingSeq(nbReqName)
                    defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, party, true, true)
                    defTables.each do |defTable|
                        if defTable.documentCategoryCd.to_s != ''
                            categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                        end
                    end
                    ###############
                    insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
		                if insuredPartyRole
		                    proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
		                end
		                if proposerIsSameAsInsured
		                    tempCurrRoleCd = party.roleCd
		                    party.roleCd = insuredPartyRole.roleCd.to_s
		                    defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, party, true, true)
		                    defTables.each do |defTable|
		                        if defTable.documentCategoryCd.to_s != ''
		                            categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
		                        end
		                    end
		                    party.roleCd = tempCurrRoleCd
		                end
                    ###############
                end
            end
            categoriesDerivedFromDT = categoriesDerivedFromDT.flatten.uniq
            return categoriesDerivedFromDT
		end

		def self.createDocumentCategoryContainer(docCategoryCd, partyGuid, documentCategoryList=[], documentCategoryContainerList=[], serviceDocGuid=nil)
            docCategoryContainer = DocumentCategoryContainer.new
            docCategoryContainer.guid = serviceDocGuid if serviceDocGuid != nil
            docCategoryContainer.docCategoryCd = docCategoryCd
            docCategoryContainer.docPartyGuid = partyGuid
            docCategoryContainer.status = ""
            documentCategoryContainerList << docCategoryContainer
            documentCategoryList << docCategoryCd

            return documentCategoryContainerList, documentCategoryList
		end

		def self.createServiceDocument(partyGuid, docCategoryCd, partyDocumentList=[])
			documents = Document.find_by_sql("select distinct d.documentDesc,d.documentCd,d.ocrIdentifier,dc.categoryCd,dc.categoryDesc,dc.categoryTypeCd,dcm.categoryCd,dcm.sortOrder from documentcategory dc,documentcategorymap dcm,document d where dc.categoryCd = dcm.categoryCd and dcm.documentCd=d.documentCd  and dc.categoryCd = '" << docCategoryCd << "';")
            documents.sort_by!{|document| document.sortOrder.to_i}
            facetObj = $rhoconfig[:multiDocMode]
            if facetObj && facetObj.actionValue.to_s == 'YES'
                multiDocMode = true
            else
                multiDocMode = false
            end
            existingDocs = []
            partyDocumentList.each do |partyDoc|
            	existingDocs << partyDoc.documentCd
            end
            ocrReqd = ($rhoconfig[:ocr_enabled].value.to_s == "YES" ? true : false)
            documents = [documents.first] unless multiDocMode
            documents.each do |document|
            	next if existingDocs.include? document.documentCd
                serviceDocument = ServiceDocument.new
                serviceDocument.partyGuid = partyGuid
                serviceDocument.docCategoryTypeCd = document.categoryTypeCd
                serviceDocument.docCategoryCd = docCategoryCd
                serviceDocument.documentCd = document.documentCd
                serviceDocument.docDescription = document.documentDesc
                serviceDocument.acceptanceStatusCd = "PENDING"
                serviceDocument.isAutoGeneratedFl = "YES"
                serviceDocument.status = ""
                serviceDocument.ocrCheckReqd = "YES" if(ocrReqd and document.ocrIdentifier.to_s != "")

                partyDocumentList << serviceDocument
            end
            return partyDocumentList
		end

		def self.incrementStep(policy,isErrorCheckReq=true)
            if policy.stepActionTabs.to_s != "" && (policy.uwDecisionCd.to_s == "PENDING" || policy.uwDecisionCd.to_s == "COMPLETE" || policy.uwDecisionCd.to_s == "ACCEPTED" || policy.uwDecisionCd.to_s == "APPROVED")
				stepActionTabList = policy.stepActionTabs.to_s.split(",")
				visitedTabs = (policy.stepActionTabs.to_s != "" ? policy.stepActionTabs.to_s : policy.visitedTabs )
				policy.stepActionTabs = nil
				incrementStep = true
				if isErrorCheckReq
					if stepActionTabList.size > 0
						tabWiseTaskExceptionMap,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid, visitedTabs)
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
				policy.step = 0 if policy.step.to_s == ""
				policy.step = (policy.step.to_i + 1) if incrementStep
			end
		end

		def self.processServiceDocumentOcr(policy,documentDO,serviceDocument,image)
	        documentContainer = DocumentContainer.loadObject(
	                                :first,
	                                :conditions=>{
	                                    {:name=>'entityGuid'}=> serviceDocument.partyGuid,
	                                    {:name=>'policyGuid'}=> policy.guid
	                                },
	                                :op => 'AND'
	                                )
	        
	        documentContainer = DocumentContainer.new(
			                    	:entityGuid => serviceDocument.partyGuid,
			                    	:entityTypeCd => 'Party',
			                    	:policyGuid => policy.guid
			                	) if documentContainer == nil

	        persistOcr = false
	        errors = {}
	        offlineFile = image.OfflineFileList[0]
	        imageBase64 = offlineFile.fileContents
	        life = policy.getPartyByGuid(serviceDocument.partyGuid)
	        lifeName = (life.lastName1.to_s=="" && life.firstName1.to_s=="") ? (life.lastName2.to_s + " " + life.firstName2.to_s) : (life.lastName1.to_s + " " + life.firstName1.to_s)
	        docCategoryDesc = Lookupvalue.getLookupValue('DOCCATEGORYTYPE',serviceDocument.docCategoryTypeCd)
	        catgDesc = docCategoryDesc.to_s + '-' + documentDO.documentDesc.to_s

			begin
				MobiSys::BrowserHelper.setOcrDetails(persistOcr,offlineFile)
	        	extractedData = MobiSys::BrowserHelper.documentTextDetection(imageBase64, false, nil, "updateOcrExtractedText")
	        	MobiSys::PolicyBO.validateServiceDocumentOcr([serviceDocument.documentCd], serviceDocument, documentContainer, policy, life, lifeName, catgDesc, errors, image)
			rescue NoMethodError => nme
				#Ignore. Calling controller has not implemented imageCaptured(image) method
			end
    	end

    	#This method is added to set Party children's entityDesc when the party is not saved. Party object will not be accessible in child so this will be used.
    	def self.setPartyDesc(party)
    		if party
    			partyEmail = party.getPartyEmail
    			partyIdentityList = party.PartyIdentityList
    			partyAddressList = party.PartyAddressList
				roleDesc =  (party.roleCd.to_s != "" ? MobiSys::BrowserHelper.getLabel(party.roleCd.to_s) : "")
				partyDesc = roleDesc + " " + party.getFullName
				ofLabel = LabelValue.getLabel("of",Application.getValue('DEFAULTLOCALE').value)
				spaceLabel = LabelValue.getLabel("SPACE",Application.getValue('DEFAULTLOCALE').value)

				#Updating entityDesc for IdentityNum. Adding Identity type in the message for better understanding.
				if partyIdentityList.size > 0
					partyIdentityList.each do |identity| 
						identity.entityDesc = Lookupvalue.getLookupValue("IDENTITYTYPE",identity.identityTypeCd.to_s) + spaceLabel + ofLabel + spaceLabel if identity.identityTypeCd.to_s != "" 
						identity.entityDesc = identity.entityDesc.to_s + partyDesc
					end
				end

				#Updating entityDesc for Email Address. Adding role in the message for better understanding.
				partyEmail.entityDesc = spaceLabel + ofLabel + spaceLabel + partyDesc if partyDesc.to_s != "" and partyEmail.to_s != "" and partyEmail.emailAddress.to_s != ""

				#Updating entityDesc for Party Address. Adding role in the message for better understanding.
				if partyAddressList.size > 0
					partyAddressList.each do |address|
						if address.removed.to_s != "YES"
							address.entityDesc = MobiSys::BrowserHelper.getLabel(address.addressTypeCd.to_s) + " address"
							address.entityDesc = address.entityDesc.to_s + spaceLabel + ofLabel + spaceLabel + partyDesc if partyDesc.to_s != ""
						end
					end
				end
			end
    	end

    	def self.updatePaymentStatus(policy)
    		offlineInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE") if policy != nil

    		if offlineInward != nil
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                inputHash = Hash.new
                inputHash["inwardGuid"] = offlineInward.guid
                className = Inward.onlineClassName

                if has_network 
                    begin
                        clazz = Class.new do
                        include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        response = obj.doJSONPost('/GetInwardData.run', ::JSON.generate(inputHash))
                        if response.to_s != ''
                            resultsHash = Rho::JSON.parse(response)
                        else
                            resultsHash = {}
                        end
                        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                        db.start_transaction

                        resultsHash.each do |key, value|
                            if value.to_s != ""
                                entities = Rho::JSON.parse(value)
                            else
                                entities = []
                            end

                            entities.each do |onlineInwardDO|
                                next if onlineInwardDO.to_s == ''
                                onlineInwardEntity = MobiSys::MobiSysEntitySchema.from_hash(offlineInward.class.name.to_s,onlineInwardDO)
                                if onlineInwardEntity.versionID == -1 and offlineInward
                                    offlineInward.destroy
                                elsif offlineInward
                                    offlineInward.merge(onlineInwardEntity)
                                    offlineInward.persist('fromSync')
                                    if offlineInward.respond_to?('afterSync'.to_sym)
                                        offlineInward.afterSync
                                    end
                                else
                                    onlineInwardEntity.persist
                                    if onlineInwardEntity.respond_to?('afterSync'.to_sym)
                                        onlineInwardEntity.afterSync
                                    end  
                                end
                            end
                        end

                        updatedInward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                        if updatedInward.InwardDetailsList[0].instrumentStatusCd.to_s == "SUCCESS"
                            policy.statusCd = "PAYMENTDONE"
                        elsif updatedInward.InwardDetailsList[0].instrumentStatusCd.to_s == "FAIL"
                            policy.statusCd = "PAYMENTFAILED"
                        end
                        policy.persist
                        db.commit
                      
                    rescue StandardError => se
                        puts "Error while generating entities hash for sync =>" + se.to_s
                        isValid = false
                        message = getLabelValue('SERVERERROR')
                    end
                else
                    isValid = false
                    message = getLabelValue('ERR_NETWORK')
                end
            end
    	end

        #Method to submit policy to online server/perform underwriting
        def self.executeSubmit(doPolicySubmit=true, policy)
            isValid = true
            policyNum = ""
            errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(policy.guid,policy.visitedTabs)
            isValid = false unless errors.empty?
            isValid = false if doPolicySubmit && policy.statusCd.to_s == "DECLARATIONCOMPLETE" && policy.signatureStatus.to_s != "SUCCESS"
            facetData = nil
            tempHash = {}

            if isValid
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection 
                # has_network = false if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE" #uncomment to test offline flow.
                transactionSuccessfull = false 
                if has_network && policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                    duplicatePolicy = false
                    policyNum = ""
                	if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE"
                    	policyNum = doJSONPost('/checkPolicyDup.run', policy.proposalNum)
                    end
                    if policyNum.to_s == "" || policy.statusCd.to_s == "SUBMITTED_UWCOMPLETE"
                    	if policy.statusCd.to_s != "SUBMITTED_UWCOMPLETE"
                        	policy.uwDecisionCd = "COMPLETE"
	                        #Need to remove this submitted status. the fix needs to be done in online task.                        
                        	policy.statusCd = "SUBMITTED"
                        end
                        policyArray = Array.new
                        serviceQuestionResponseArray = Array.new
                        serviceDocumentRequirementArray = Array.new
                        partyImageList = Array.new
                        serviceSignatureArray = Array.new
                        inwardArray = Array.new

                        policyProduct = policy.getBaseProduct
				        policyProduct.pdfPeriod = 0 if policyProduct != nil and policyProduct.pdfPeriod.to_s == ""

				        policy.quotationSeq = nil
                        [policy].each do |pol|
                            pol.PartyList.each do |party|
                                questionContainer = QuestionContainer.loadObject(
                                    :first,
                                    :conditions=>{
                                        {:name=>'entityGuid'} => party.guid,
                                        {:name=>'policyGuid'} => pol.uniqueKey
                                    },
                                    :op=>'AND'
                                    )
                                if questionContainer
                                    partyResponseList = questionContainer.ServiceQuestionResponseList
                                    serviceQuestionResponseArray.concat partyResponseList
                                end

                                documentContainer = DocumentContainer.loadObject(
                                    :first,
                                    :conditions=>{
                                        {:name=>'entityGuid'}=> party.guid,
                                        {:name=>'policyGuid'}=> pol.guid
                                    },
                                    :op => 'AND'
                                    )
                                if documentContainer
                                    partyDocumentList = documentContainer.ServiceDocumentList
                                    #code added to make serviceDocument status received if document is selected and image exist 
                                    partyDocumentList.each do|partydoc|
                                        imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                                        partyImageList.concat imageList if imageList.size > 0

                                        if partydoc.acceptanceStatusCd.to_s != "FULFILLED" && imageList.size > 0 && partydoc.documentCd.to_s != "" && partydoc.documentCd != nil
                                            partydoc.imageCount = imageList.size
                                            partydoc.acceptanceStatusCd = "FULFILLED"
                                            
                                            partydoc.persistAll
                                        end
                                    end
                                    serviceDocumentRequirementArray.concat partyDocumentList
                                end
                            end
                        end

                        #Discussed with Neha: Hardcoded value sent for online validations for doDocumentValidation
                        serviceDocumentRequirementArray.each do|partydoc|
                            partydoc.imageURL = "offline"
                        end

                        agentQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions => {
                                {:name => 'entityGuid'} => policy.guid, 
                                {:name => 'policyGuid'} => policy.guid,
                                {:name => 'entityTypeCd'} => 'AGENT'
                            },
                            :op => 'AND'
                            )
                        if agentQuestionContainer
                            agentResponseList = agentQuestionContainer.ServiceQuestionResponseList
                            serviceQuestionResponseArray.concat agentResponseList
                        end

                        signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => policy.guid}) 
                        serviceSignatureArray = signatureContainer.ServiceSignatureList if signatureContainer

                        inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                        emailResponseHash = nil
                        if doPolicySubmit
                            policy.policyStatusCd = "DECLARATIONCOMPLETE"
                            #generating pdf for illustration before submitting application
                            emailResponseHash = MobiSys::PolicyService.generateSIPDF(policy)
                        else
                            policy.policyStatusCd = "AUTOUW"
                        end
                        policyArray.push(policy)

                        syncEntities = Hash.new
                        syncEntities[Policy.onlineClassName] = policyArray
                        syncEntities[ServiceQuestionResponse.onlineClassName] = serviceQuestionResponseArray if serviceQuestionResponseArray.size > 0
                        syncEntities[ServiceDocument.onlineClassName] = serviceDocumentRequirementArray if serviceDocumentRequirementArray.size > 0
                        syncEntities[Image.onlineClassName] = partyImageList if partyImageList.size > 0
                        syncEntities[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0
                        syncEntities[Inward.onlineClassName] = inward if inward

                        transactionSuccessfull = false
                        if !doPolicySubmit || (emailResponseHash != nil && !emailResponseHash.empty?)
                            transactionSuccessfull = true # if generateSIPDF is successfull
                            responseHash = {}
                            responseHash = PolicyUtil::ApplicationUtil.invokeOnlineService(syncEntities,"/callPolicyService.run",true)
                            transactionSuccessfull = false # resetting the flag again after invoking next service
                            if responseHash != nil && !responseHash.empty?
                                transactionSuccessfull = true # if callPolicyService is successfull
                                #Mark all documents are done uploading
                                serviceDocumentRequirementArray.each do |serviceDoc|
                                    serviceDoc.uploadStatus = "DONE"
                                    serviceDoc.persistAll
                                end

                                partyImageList.each do |image|
                                    image.uploadStatus = "DONE"
                                    image.persistAll
                                end

                                facetData = MobiSys::PolicyService.getFacetData("result", policy.baseProductSeq)
                                facetData[:showResults] = true

                            else                         
                               transactionSuccessfull = false # callPolicyService failed 
                            end
                        end
                    else
                        policy.policyNum = policyNum
                        policy.persistAll
                        duplicatePolicy = true
                    end
                elsif policy.proposalSignedDt.to_s != "" && policy.signatureStatus.to_s == "SUCCESS"
                    serviceDocumentList = []
                    policy.PartyList.each do |party|
                        documentContainer = DocumentContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'}=> party.guid,
                                {:name=>'policyGuid'}=> policy.guid
                            },
                            :op => 'AND',
                            :loadChild => 'false'
                        )
                        if documentContainer
                            partyDocumentList = ServiceDocument.loadObject(
                                :all,
                                :conditions=>{
                                    {:name=>'partyGuid'}=> party.guid,
                                    {:name=>'parentKey'}=> documentContainer.object
                                },
                                :op => 'AND',
                                :loadChild => 'false'
                            )
                            #code added to make sericeDocument status received if document is selected and image exist 
                            partyDocumentList.each do|partydoc|
                                imageList = Image.loadObject(
                                    :all,
                                    :conditions=>{
                                        {:name=>'parentRefGuid'}=> partydoc.uniqueKey
                                    },
                                    :loadChild => 'false'
                                )
                                if partydoc.acceptanceStatusCd.to_s != "FULFILLED" && imageList.size > 0 && partydoc.documentCd.to_s != "" && partydoc.documentCd != nil
                                    partydoc.imageCount = imageList.size
                                    partydoc.acceptanceStatusCd = "FULFILLED"
                                    partydoc.persistAll
                                end
                            end
                            serviceDocumentList.concat partyDocumentList
                        end
                    end
                    # puts "after AUW serviceDocumentList-----#{serviceDocumentList}"
                   # ##RhoLog.error("EXECUTE SUBMIT","serviceDocumentList :- #{serviceDocumentList}")
                    if $rhoconfig[:fuw_applicable] && (policy.uwDecisionCd.to_s == "" || policy.uwDecisionCd.to_s == "PENDING")
                        autoUWRule = PolicyUtil::AutoUWUtil.new
                        serviceDocumentList = autoUWRule.execute(policy, serviceDocumentList)
			        	if policy.uwDecisionCd == "ACCEPTED" || policy.uwDecisionCd == "REFERTOMUW" || policy.uwDecisionCd == "ACCEPTEDEXCLUSION"
                        	policy.statusCd = "SUBMITTED"
                        elsif policy.uwDecisionCd == "ACCEPTEDRATED"
                        	policy.statusCd = "SUBMITTED_UWCUSTOMERINPUT" 
                        elsif policy.uwDecisionCd == "REQUIREMENTPENDING"
                        	policy.statusCd = "SUBMITTED_UWCUSTOMERINPUT"
                       	end
                        policy.persistAll
                        documentContainerHash = {}
                        serviceDocumentList.each do |servDoc|
                        	next if servDoc.isAutoGeneratedFl.to_s == "YES"
                        	#load document container only if the document is for a different party
                        	documentContainer = nil
                        	if documentContainerHash[servDoc.partyGuid] == nil
	                        	documentContainer = DocumentContainer.loadObject(
		                            :first,
		                            :conditions=>{
		                                {:name=>'entityGuid'}=> servDoc.partyGuid,
		                                {:name=>'policyGuid'}=> policy.guid
		                            },
		                            :op => 'AND',
		                            :loadChild => 'false'
		                        )
		                        documentContainerHash[servDoc.partyGuid] = documentContainer
	                        else
                        		documentContainer = documentContainerHash[servDoc.partyGuid]
	                        end
	                        if documentContainer
                        		documentContainer.addServiceDocument(servDoc)
                        	end
                        end
                        documentContainerHash.each do |key, docContainer|
                        	docContainer.persistAll
                        end
 
                    end
                    transactionSuccessfull = true
                end

                if transactionSuccessfull
                    tempHash["success"] = true
                    if !doPolicySubmit
                        policy.statusCd = "UWCOMPLETE"
                        if facetData[:uwType].to_s == "TYPE1" || facetData[:uwType].to_s == "TYPE2"
                            policy.statusCd = "PAYMENTDONE" if !policy.getGatewayFlag
                            policy.counterOfferAcceptDt = Time.new.strftime("%F 00:00:00 %z")
                        end
                        policy.persistAll
                        if facetData[:uwType] && (facetData[:uwType].to_s == "TYPE3" || facetData[:uwType].to_s == "TYPE4")
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid}) 
                            if signatureContainer.to_s == ""
                                signatureContainer = SignatureContainer.new(:entityGuid => policy.guid, :entityTypeCd => policy.class.name.to_s)
                            end
                    
                            counterOfferSignature = MobiSys::SignatureUtil.getCounterOfferSignature(policy, signatureContainer) if signatureContainer
                            if counterOfferSignature.signatureDt.to_s != ""
                                counterOfferSignature.signatureDt = getScreenDate(counterOfferSignature.signatureDt.to_s)
                            else
                                counterOfferSignature.signatureDt = getScreenDate(Time.new.strftime("%F 00:00:00 %z").to_s)
                            end
                        end

                        if facetData[:uwType] == "TYPE4"
                            quotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
                        end
                    end
                elsif duplicatePolicy
                    tempHash["success"] = false
                    tempHash["message"] = MobiSys::CommonUtil.replacePlaceHolders(MobiSys::BrowserHelper.getLabel('ERR_submitEappFromWeb'), [policy.applicationRefNum, policy.proposalNum]) 
                else
                    tempHash["success"] = false
                    tempHash["message"] = getLabelValue('SERVERERROR')
                end
            else
                tempHash["success"] = false
                tempHash["message"] = "This eApp is already revoked via web and cannot be revoked again via SunSmart+ App."
            end

            return tempHash
        end

       	def self.transferToCustomer(policy)
	        quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
			if policy != nil
				has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
				showMessages = true
				if has_network 
                    begin
						className = Policy.onlineClassName
		                entityPackage = Hash.new
		                entityPackage[className] = [policy.hashForSync]
		                inputHash = Hash.new
						offlineEntitiesHash = Hash.new
						offlineEntitiesHash[className] = Hash.new
                    	currentEntityTypeHash = offlineEntitiesHash[className]
                		currentEntityTypeHash[policy.guid] = policy
 
						questionContainers = QuestionContainer.loadObject(
		                    :all, 
		                    :conditions=>{
		                        {:name=>'policyGuid'} => policy.guid
		                    }
		                )
		                if questionContainers
		                    tempList = []
		                    questionContainers.each do |questionContainer|
		                        questionContainer.ServiceQuestionResponseList.each do |sq|
		                            tempList.push sq.hashForSync
		                        end
		                    end
		                    entityPackage[ServiceQuestionResponse.onlineClassName] = tempList.flatten
		                end
		                documentContainers = DocumentContainer.loadObject(
		                    :all,
		                    :conditions=>{
		                        {:name=>'policyGuid'}=> policy.guid
		                    }
		                )
		                if documentContainers
		                    tempList = []
		                    tempImageList = []
		                    documentContainers.each do |documentContainer|
		                        documentContainer.ServiceDocumentList.each do |sd|
		                            tempList.push sd.hashForSync
		                        end
		                    end
		                    entityPackage[ServiceDocument.onlineClassName] = tempList.flatten
 
		                    documentContainers.each do |documentContainer|
		                        partyDocumentList = documentContainer.ServiceDocumentList 
		                        partyDocumentList.each do|partydoc|
		                            imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
		                            imageList.each do|img|
		                                tempImageList.push img.hashForSync
		                            end
		                        end
		                    end
		                    entityPackage[Image.onlineClassName] = tempImageList.flatten
		                end
 

		                inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
		                if inward
		                   entityPackage[Inward.onlineClassName] = [inward.hashForSync]
		                   offlineEntitiesHash[Inward.onlineClassName] = Hash.new
		                   currentEntityTypeHash = offlineEntitiesHash[Inward.onlineClassName]
                		   currentEntityTypeHash[inward.guid] = inward
		                end
 
                		if policy.quotationRefNum.to_s != ""
                			entityPackage[Quotation.onlineClassName] = [quotation.hashForSync] if quotation
                		end
                		@quotProposerParty = quotation.getPartyByRole('PROPOSER')
                		csaAppToParty = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"CSAAPPTOPARTY"})
                		fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'fnaNum'}=>quotation.fnaId}) if quotation.fnaId.to_s != ""
                		
                		entityPackage[FNARequest.onlineClassName] = [fnaRequest.hashForSync] if fnaRequest

                		leadRPQ = LeadRPQ.loadObject(:first,:conditions => {{:name=>'rpqId'}=>fnaRequest.addtnField1Str}) if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd) && fnaRequest && fnaRequest.addtnField1Str.to_s != ""
                		
                		entityPackage[LeadRPQ.onlineClassName] = [leadRPQ.hashForSync] if leadRPQ

                		# rpqResponse = RPQResponse.loadObject(:all, :conditions => { :rpqId => leadRPQ.rpqId.to_s }) if leadRPQ && leadRPQ.rpqId.to_s != ""
                		
                		 if leadRPQ
                		 	rpqtempList = []
		                   leadRPQ.getRPQResponseList.each do |ss|
		                            rpqtempList.push ss.hashForSync
		                        end
		                        
		                    entityPackage[RPQResponse.onlineClassName] = rpqtempList.flatten
		                end
                		# entityPackage[RPQResponse.onlineClassName] = [rpqResponse.hashForSync] if rpqResponse

                		# if policy.fnaId.to_s != ""
                		# 	fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
                		# 	entityPackage[Quotation.onlineClassName] = [quotation.hashForSync] if quotation
                		# end

		                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => policy.guid})
		                signatureContainersQuot = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => quotation.guid})
		                signatureContainersFna = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => fnaRequest.guid}) if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd)          
		                tempList = []
		                if signatureContainers
		                    signatureContainers.each do |serviceSignature|
		                        serviceSignature.ServiceSignatureList.each do |ss|
		                        	if ss && ss.signature.to_s == ""
		                        	   ss.signatureDt = nil
		                        	end   
		                            tempList.push ss.hashForSync
		                        end
		                    end
		                end

		                if signatureContainersQuot
		                    signatureContainersQuot.each do |serviceSignature|
		                        serviceSignature.ServiceSignatureList.each do |ss|
		                            tempList.push ss.hashForSync
		                        end
		                    end
		                end

		                if csaAppToParty && csaAppToParty.actionValue.include?(@quotProposerParty.partyTypeCd) && signatureContainersFna
		                    signatureContainersFna.each do |serviceSignature|
		                        serviceSignature.ServiceSignatureList.each do |ss|
		                            tempList.push ss.hashForSync
		                        end
		                    end
		                end

		               	entityPackage[ServiceSignature.onlineClassName] = tempList.flatten

		               	

		                inputHash[0] = ::JSON.generate([entityPackage.to_json])
 						
                        clazz = Class.new do
                        include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        json = ::JSON.generate(inputHash)
                        response = obj.doJSONPost('/PolicyTransferToCustomer.run', json)
                         
                        if response.to_s != ""
		                	resultsHash = Rho::JSON.parse(response)
		                else
		                	resultsHash = {}
		                end
		                resultsHash.each do |key,value|
		                    next if value.to_s == '' || value.to_s == '[]' || value.empty?
		                    # puts "Key: " + key.to_s
		                    # puts "Value: " + value.to_s
		                    entities = Rho::JSON.parse(value)
		                    offlineEntities = offlineEntitiesHash[key]
                    		count = 0
		                    begin
		                        db = ::Rho::RHO.get_db_partitions()['local']
		                        db.start_transaction
		                        entities.each do |mainEntity|
		                            next if mainEntity.to_s == ''
		                            saveEntitiesPostMerge(key,mainEntity,offlineEntities)
		                        end#entities.each ends
		                        db.commit
		                    rescue StandardError => se
		                        db.rollback
		                        if showMessages
		                            Alert.show_popup({:title=>'',:message=>se.to_s, 
		                            :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
		                        else
		                            log('Error while syncing entities: ' + se.to_s)
		                            raise se
		                        end
		                    end
		                end
                    end
                end
            end
		end

		def self.transferToCustomerTest(policy)
			if policy != nil
				has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
				showMessages = true
				if has_network 
                    begin
						className = Policy.onlineClassName
		                entityPackage = Hash.new
		                entityPackage[className] = [policy.hashForSync]
		                inputHash = Hash.new
						offlineEntitiesHash = Hash.new
						offlineEntitiesHash[className] = Hash.new
                    	currentEntityTypeHash = offlineEntitiesHash[className]
                		currentEntityTypeHash[policy.guid] = policy

						questionContainers = QuestionContainer.loadObject(
		                    :all, 
		                    :conditions=>{
		                        {:name=>'policyGuid'} => policy.guid
		                    }
		                )
		                if questionContainers
		                    tempList = []
		                    questionContainers.each do |questionContainer|
		                        questionContainer.ServiceQuestionResponseList.each do |sq|
		                            tempList.push sq.hashForSync
		                        end
		                    end
		                    entityPackage[ServiceQuestionResponse.onlineClassName] = tempList.flatten
		                end
		                documentContainers = DocumentContainer.loadObject(
		                    :all,
		                    :conditions=>{
		                        {:name=>'policyGuid'}=> policy.guid
		                    }
		                )
		                if documentContainers
		                    tempList = []
		                    tempImageList = []
		                    documentContainers.each do |documentContainer|
		                        documentContainer.ServiceDocumentList.each do |sd|
		                            tempList.push sd.hashForSync
		                        end
		                    end
		                    entityPackage[ServiceDocument.onlineClassName] = tempList.flatten

		                    documentContainers.each do |documentContainer|
		                        partyDocumentList = documentContainer.ServiceDocumentList 
		                        partyDocumentList.each do|partydoc|
		                            imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
		                            imageList.each do|img|
		                                tempImageList.push img.hashForSync
		                            end
		                        end
		                    end
		                    entityPackage[Image.onlineClassName] = tempImageList.flatten
		                end

		                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => policy.guid})            
		                if signatureContainers
		                    tempList = []
		                    signatureContainers.each do |serviceSignature|
		                        serviceSignature.ServiceSignatureList.each do |ss|
		                            tempList.push ss.hashForSync
		                        end
		                    end
		                    entityPackage[ServiceSignature.onlineClassName] = tempList.flatten
		                end

		                inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
		                if inward
		                   entityPackage[Inward.onlineClassName] = [inward.hashForSync]
		                   offlineEntitiesHash[Inward.onlineClassName] = Hash.new
		                   currentEntityTypeHash = offlineEntitiesHash[Inward.onlineClassName]
                		   currentEntityTypeHash[inward.guid] = inward
		                end

		                inputHash[0] = ::JSON.generate([entityPackage.to_json])

                        clazz = Class.new do
                        include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        json = ::JSON.generate(inputHash)
                        response = obj.doJSONPost('/PolicyTransferToCustomer.run', json)
                        if response.to_s != ""
		                	resultsHash = Rho::JSON.parse(response)
		                else
		                	resultsHash = {}
		                end
		                resultsHash.each do |key,value|
		                    next if value.to_s == '' || value.to_s == '[]' || value.empty?
		                    # puts "Key: " + key.to_s
		                    # puts "Value: " + value.to_s
		                    entities = Rho::JSON.parse(value)
		                    offlineEntities = offlineEntitiesHash[key]
                    		count = 0
		                    
		                    begin
		                        db = ::Rho::RHO.get_db_partitions()['local']
		                        db.start_transaction
		                        entities.each do |mainEntity|
		                            next if mainEntity.to_s == ''
		                            saveEntitiesPostMerge(key,mainEntity,offlineEntities)
		                        end#entities.each ends
		                        db.commit
		                    rescue StandardError => se
		                        db.rollback
		                        if showMessages
		                            Alert.show_popup({:title=>'',:message=>se.to_s, 
		                            :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
		                        else
		                            log('Error while syncing entities: ' + se.to_s)
		                            raise se
		                        end
		                    end
		                end
                    end
                end
            end
		end

		def self.revokeFromCustomer(policy)
			
			if policy != nil
				has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
				showMessages = true
				if has_network 
                    begin
						className = Policy.onlineClassName
		               	offlineEntitiesHash = Hash.new
						offlineEntitiesHash[className] = Hash.new
                    	currentEntityTypeHash = offlineEntitiesHash[className]
                		currentEntityTypeHash[policy.guid] = policy
                		inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
		                if inward
		                   offlineEntitiesHash[Inward.onlineClassName] = Hash.new
		                   currentEntityTypeHash = offlineEntitiesHash[Inward.onlineClassName]
                		   currentEntityTypeHash[inward.guid] = inward
		                end
                		# policyGuid = policy.guid

		                inputHash = Hash.new
		                inputHash["id"] = policy.id
						return if policy.id.to_s == ""
                        clazz = Class.new do
                        include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        response = obj.doJSONPost('/RevokeTransferToCustomer.run', ::JSON.generate(inputHash))
                        
                        if response.to_s != ""
		                	resultsHash = Rho::JSON.parse(response)
		                else
		                	resultsHash = {}
		                end

		                
		                # resultsHash.sort_by { |key, _value| key.end_with?("PolicyDO") ? 0 : 1 }.each do |key, value|

		              	 resultsHash = {"com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO" => resultsHash["com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO"]}.merge(resultsHash.reject { |k, _| k == "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDO" })

		                resultsHash.each do |key,value|
		                    next if value.to_s == '' || value.to_s == '[]' || value.empty?# || key.to_s != className
		                    # logError "Key: " + key.to_s
		                    # logError "Value: " + value.to_s
		                    entities = Rho::JSON.parse(value)
		                    
		                    offlineEntities = offlineEntitiesHash[key]
                    		begin
		                        db = ::Rho::RHO.get_db_partitions()['local']
		                        db.start_transaction
		                        # delete the docuemnts before adding online docs
	                            if key.end_with?("ServiceDocumentDO") || key.end_with?("ServiceSignatureDO")
	                            	deleteExistingDocsAndSign(policy, key)
	                            end
		                        entities.each do |mainEntity|
		                            
		                             
		                            next if mainEntity.to_s == ''
		                            # saveEntitiesPostMerge1(key,mainEntity,offlineEntities,policyGuid)
		                            saveEntitiesPostMerge1(key,mainEntity,offlineEntities,policy)
		                        end#entities.each ends
		                        db.commit
		                    rescue StandardError => se
		                        db.rollback
		                        RhoLog.error('Error while syncing entities: ', se.to_s)
		                    end
		                end

		                policyPortfolioModelCode = policy.PolicyProductList
                              .find { |ppd| 
                                ppd.productTypeCd == "PLAN"
                              }&.portfolioModelCd

				        if policy.quotationRefGuid.to_s != ""
				            quotation = Quotation.find(:first, :conditions => {:guid => policy.quotationRefGuid })
				            quotationProduct = QuotationProduct.find(:first, :conditions=>{{:name=>'parentKey'}=>quotation.object, {:name=>'productTypeCd'} => "PLAN"},:op => 'AND') if quotation
				            quotationPortfolioModelCode = quotationProduct.portfolioModelCd if quotationProduct
				        end

                    	MobiSys::CommonUtil.addUserActivity('REVOKEREQUEST_OFFLINE',"quotationRefNum => #{policy.quotationRefNum},proposalNum => #{policy.proposalNum},policyGuid => #{policy.guid},policyfnaId => #{policy.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'POLICY', policy.proposalNum)
                    end
		        end
		    end
		end

		def getCSASeq
	        parsedData = parseRequestBodyParams
	        responseHash = {}
	        fnaId = parsedData["fnaId"] if parsedData.has_key?("fnaId")
	        fnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=> fnaId.to_s}) if fnaId
	        if fnaRequest
	            responseHash = {"success" => true,
	                            "data" => {"cffSeq" => fnaRequest.object}}
	        else
	            responseHash = {"success" => false,
	                            "message" => "fnaRequest not found."}
	        end
	        render :string => responseHash.to_json
	    end

	    def self.deleteExistingDocsAndSign(policy, key)
	    	
	    	

	    	if policy
	    		if key.end_with?("ServiceSignatureDO")
			    	quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
			    	fnaRequest = FNARequest.loadObject(:first,:conditions => {{:name=>'fnaNum'}=>quotation.fnaId}) if quotation.fnaId.to_s != ""
			    	signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => policy.guid}) if policy
		            signatureContainersQuot = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => quotation.guid}) if quotation
		            signatureContainersFna = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => fnaRequest.guid}) if fnaRequest

		            if signatureContainers
		                signatureContainers.each do |serviceSignature|
		                    serviceSignature.ServiceSignatureList.each do |ss|
		                        ss.removed = "YES"
		                    end
		                    serviceSignature.persistAll
		                end
		            end

		            if signatureContainersQuot
		                signatureContainersQuot.each do |serviceSignature|
		                    serviceSignature.ServiceSignatureList.each do |ss|
		                        ss.removed = "YES"
		                    end
		                    serviceSignature.persistAll
		                end
		            end

		            if signatureContainersFna
		                signatureContainersFna.each do |serviceSignature|
		                    serviceSignature.ServiceSignatureList.each do |ss|
		                        ss.removed = "YES"
		                    end
		                    serviceSignature.persistAll
		                end
		            end
				end

				if key.end_with?("ServiceDocumentDO")
			    	containers = DocumentContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'} => policy.guid})
			    	
			    	if containers
			    		containers.each do |eachContainer|
			    			
			    			eachContainer.ServiceDocumentList.each do |serviceDocumentOfflineEntity|
			    				serviceDocumentOfflineEntity.removed = 'YES' 
			                    Image.delete_all(
			                        :conditions => {
			                            {:name=>'parentRefGuid'} => serviceDocumentOfflineEntity.guid
			                        },
			                        :op => 'AND'
			                    )
			    			end
			    			eachContainer.persistAll
			    		end
			    	end
			    end
	    	end
	    	
	    end

		#Method created to save online data to offline post policy sync for non face to face
		def self.saveEntitiesPostMerge1(entityName,mainEntity,offlineEntities,policy)
            subEntity = mainEntity
            if offlineEntities
                offlineEntity = offlineEntities[subEntity['guid']]
            end
            if entityName == Policy.onlineClassName
                policyEntity = subEntity
                className = offlineEntity.class.name.to_s
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,policyEntity)
                if onlineEntity.versionID == -1 and offlineEntity
                    offlineEntity.destroy
                elsif offlineEntity
                	
                    offlineEntity.merge(onlineEntity)
                    offlineEntity.persist('fromSync')
                    if offlineEntity.respond_to?('afterSync'.to_sym)
                        offlineEntity.afterSync
                    end
                else
                    onlineEntity.persist
                    if onlineEntity.respond_to?('afterSync'.to_sym)
                        onlineEntity.afterSync
                    end  
                end

                if mainEntity[ServiceQuestionResponse.onlineClassName].to_s != ''
                    serviceQuestionResponseEntities = Rho::JSON.parse(mainEntity[ServiceQuestionResponse.onlineClassName])
                    if serviceQuestionResponseEntities.size > 0
                        serviceQuestionResponseEntities.each do |serviceQuestionResponseEntity|
                            questionContainer = QuestionContainer.loadObject(
                                :first, 
                                :conditions=>{
                                    {:name=>'entityGuid'} => serviceQuestionResponseEntity['partyGuid'],
                                    {:name=>'policyGuid'} => serviceQuestionResponseEntity['entityGuid']
                                },
                                :op => 'AND'
                            )

                            unless questionContainer
                                questionContainer = QuestionContainer.new
                                questionContainer.entityGuid = serviceQuestionResponseEntity['partyGuid']
                                questionContainer.policyGuid = policyEntity['guid']
                            end
                            serviceQuestionResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceQuestionResponse',serviceQuestionResponseEntity)
                            questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponseOfflineEntity|
                                if  serviceQuestionResponseOfflineEntity.to_s != "" && serviceQuestionResponseOfflineEntity.guid == serviceQuestionResponse.guid
                                    serviceQuestionResponseOfflineEntity.merge(serviceQuestionResponse)
                                    questionContainer.persist('fromSync')
                                    if serviceQuestionResponseEntity.respond_to?('afterSync'.to_sym)
                                        serviceQuestionResponseEntity.afterSync
                                    end
                                end
                            end
                        end
                    end
                end

                if mainEntity[Inward.onlineClassName].to_s != ''
                    inwardEntities = Rho::JSON.parse(mainEntity[Inward.onlineClassName])
                    inwardOfflineEntity = offlineEntity.getInward(policyEntity['proposalNum'], "APPLICATION_SUSPENSE")
                    if inwardEntities.size > 0 && inwardOfflineEntity.to_s != ""
                        inwardEntities.each do |inwardEntity|
                            inwardEntity = MobiSys::MobiSysEntitySchema.from_hash('Inward',inwardEntity)
                            if inwardOfflineEntity.to_s != "" && inwardOfflineEntity.guid == inwardEntity.guid
                                inwardOfflineEntity.merge(inwardEntity)
                                inwardOfflineEntity.persist('fromSync')
                                if inwardEntity.respond_to?('afterSync'.to_sym)
                                    inwardEntity.afterSync
                                end
                            end
                        end
                    end
                end
            elsif entityName == ServiceDocument.onlineClassName
                serviceDocumentEntity = mainEntity
                freshDoc = false
                docConditionMet = false
            	if !serviceDocumentEntity.empty?
                	begin
                    	documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'entityGuid' => serviceDocumentEntity['partyGuid'], 'policyGuid' => serviceDocumentEntity['entityGuid']})
                    	
               		rescue StandardError => boom
						puts ">>>StandardError occured in documentContainer: #{boom}\n#{boom.backtrace}"
					end
                    unless documentContainer
                        documentContainer = DocumentContainer.new
                        documentContainer.entityGuid = serviceDocumentEntity['partyGuid']
                        documentContainer.entityTypeCd = 'Party'
                        documentContainer.policyGuid = serviceDocumentEntity['entityGuid']
                        
                    end
                    serviceDocument = MobiSys::MobiSysEntitySchema.from_hash('ServiceDocument',serviceDocumentEntity)
                    updatedPolicy = Policy.loadObject(:first,:conditions=>{:proposalNum=>policy.proposalNum})

                    quotation = MobiSys::PolicyBO.convertToQuotation(updatedPolicy)
		            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
		            $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
		            $currentPolicy = nil
		            $currentPolicy = updatedPolicy
                    updatedPolicy.PartyList.each do |party|
                    	categoriesDerivedFromDT = []
			            for i in 0..20
			                if i == 0
			                    i = ""
			                end
			                nbReqName = "NBREQUIRMENTS" << i.to_s
			                offlineFacet = $currentProduct.getFacet(nbReqName)
			                if  (offlineFacet && offlineFacet.applicableRoles.to_s == "" ) || (offlineFacet  && offlineFacet.applicableRoles.to_s.split(",").include?(party.roleCd.to_s))
			                    ttms = $currentProduct.getTableTypeMappingSeq(nbReqName)
			                    defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, party, true, true)
			                    defTables.each do |defTable|
			                        if defTable.documentCategoryCd.to_s != ''
			                            categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
			                        end
			                    end
			                    insuredPartyRole = updatedPolicy.getPolicyPartyRole("PRIMARY")
			                    if insuredPartyRole
			                        proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
			                    end
			                    if proposerIsSameAsInsured
			                        tempCurrRoleCd = party.roleCd
			                        party.roleCd = insuredPartyRole.roleCd.to_s
			                        defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, party, true, true)
			                        defTables.each do |defTable|
			                            if defTable.documentCategoryCd.to_s != ''
			                                categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
			                                categoriesDerivedFromDT = categoriesDerivedFromDT.uniq
			                            end
			                        end
			                        party.roleCd = tempCurrRoleCd
			                    end
			                end
			            end
			            categoriesDerivedFromDT = categoriesDerivedFromDT.flatten.uniq
			            categoriesDerivedFromDT.each do |categoryFromDT|
            				docCatgDO = DocumentCategory.loadObject(:first, :conditions=>{{:name=>'categoryCd'}=>categoryFromDT.to_s})
            				docCatgDO.DocumentCategoryMapList.each do |documentCategoryMap|
            					documentcd = documentCategoryMap.documentCd
            					if serviceDocument.partyGuid.to_s == party.guid.to_s && serviceDocument.documentCd.to_s == documentCategoryMap.documentCd.to_s
            						serviceDocument.docCategoryCd = docCatgDO.categoryCd
            					end
            				end

			            end
                    end


                    if serviceDocument
                        if serviceDocument.documentCd.to_s != ""
                           serviceDocument.selected = "YES"
                        end
                        documentContainer.addServiceDocument(serviceDocument)
                        documentContainer.persistAll
                    end
                    $currentPolicy = nil
                end
            elsif entityName == ServiceQuestionResponse.onlineClassName
			    mainEntity = Rho::JSON.parse(mainEntity) if mainEntity.is_a?(String)
			    serviceQuestionResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceQuestionResponse', mainEntity)
			    if serviceQuestionResponse && serviceQuestionResponse.partyGuid.to_s != ""
			       questionContainer = QuestionContainer.loadObject(:first,:conditions=>{{:name=>'entityGuid'} => serviceQuestionResponse.partyGuid.to_s,{:name=>'policyGuid'} => policy.uniqueKey},:op=>'AND')
			    else
                   questionContainer = QuestionContainer.loadObject( :first,:conditions => { {:name => 'entityGuid'} => policy.guid,{:name => 'entityTypeCd'} => "AGENT"},:op => "AND")
			    end 
			    dbserviceQuestionResponseEntity = nil	
			    questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponseOfflineEntity|
                    if serviceQuestionResponseOfflineEntity.guid == serviceQuestionResponse.guid
                        dbserviceQuestionResponseEntity = serviceQuestionResponseOfflineEntity
                        break
                    end
                end
                if  dbserviceQuestionResponseEntity != nil
                    dbserviceQuestionResponseEntity.merge(serviceQuestionResponse)
                    if dbserviceQuestionResponseEntity.respond_to?('afterSync'.to_sym)
                        dbserviceQuestionResponseEntity.afterSync
                    end
                else
                    questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
                    if serviceQuestionResponse.respond_to?('afterSync'.to_sym)
                        serviceQuestionResponse.afterSync
                    end
                end
                questionContainer.persistAll
           	elsif entityName == Image.onlineClassName
                begin 
	                imageEntity = mainEntity
	            	
            		if !imageEntity.empty?
                        image = MobiSys::MobiSysEntitySchema.from_hash('Image',imageEntity)
						if image
                    		
		                	newImageDO = Image.new
				    		MobiSys::CommonUtil.copyFields(image, newImageDO)
							offlineFile = image.OfflineFileList[0]
							newOfflineFileDO = OfflineFile.new
							MobiSys::CommonUtil.copyFields(offlineFile, newOfflineFileDO)
							newImageDO.addOfflineFile(newOfflineFileDO)
							newImageDO.persistAll
							
						end
                    end
	            rescue StandardError => boom
					puts ">>>StandardError occured in image: #{boom}\n#{boom.backtrace}"
				end
            elsif entityName == ServiceSignature.onlineClassName
            	serviceSignatureEntity = mainEntity
            	# freshSignature = false
            	# signConditionMet = false
            	if !serviceSignatureEntity.empty?
                	
                    signatureContainer = SignatureContainer.loadObject(
                        :first, 
                        :conditions=>{
                            {:name=>'entityGuid'} => serviceSignatureEntity['entityGuid']
                        }
                    )
                    policy = Policy.loadObject(:first,:conditions=>{:guid=>serviceSignatureEntity['entityGuid']})
                    quotation = Quotation.loadObject(:first,:conditions=>{:guid=>serviceSignatureEntity['entityGuid']})
                    fnaRequest = FNARequest.loadObject(:first,:conditions=>{:guid=>serviceSignatureEntity['entityGuid']})
                    if !signatureContainer && policy
                        signatureContainer = SignatureContainer.new
                        signatureContainer.entityTypeCd = 'Policy'
                        signatureContainer.entityGuid = serviceSignatureEntity['entityGuid']
                    elsif !signatureContainer && quotation
                    	signatureContainer = SignatureContainer.new
                        signatureContainer.entityTypeCd = 'Quotation'
                        signatureContainer.entityGuid = serviceSignatureEntity['entityGuid']
                    elsif !signatureContainer && fnaRequest
                    	signatureContainer = SignatureContainer.new
                        signatureContainer.entityTypeCd = 'FNARequest'
                        signatureContainer.entityGuid = serviceSignatureEntity['entityGuid']
                    end

                    serviceSignatureEntity = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
	                if serviceSignatureEntity
	                    signatureContainer.addServiceSignature(serviceSignatureEntity)
	                    signatureContainer.persistAll
	                end
                end
            elsif entityName == Inward.onlineClassName
                offlineEntity = offlineEntities[subEntity["guid"]]
                className = offlineEntity.class.name.to_s

                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,subEntity)
                if onlineEntity.versionID == -1 and offlineEntity
                    offlineEntity.destroy
                elsif offlineEntity
                    offlineEntity.merge(onlineEntity)
                    offlineEntity.persist('fromSync')
                    if offlineEntity.respond_to?('afterSync'.to_sym)
                        offlineEntity.afterSync
                    end
                else
                    onlineEntity.persist
                    if onlineEntity.respond_to?('afterSync'.to_sym)
                        onlineEntity.afterSync
                    end  
                end
            end
        end

  		def self.saveEntitiesPostMerge(entityName,mainEntity,offlineEntities)
            subEntity = mainEntity
            if offlineEntities
                offlineEntity = offlineEntities[subEntity['guid']]
            end
            if entityName == Policy.onlineClassName
                policyEntity = subEntity
                
                className = offlineEntity.class.name.to_s
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,policyEntity)
                if onlineEntity.versionID == -1 and offlineEntity
                    offlineEntity.destroy
                elsif offlineEntity
                    offlineEntity.merge(onlineEntity)
                    offlineEntity.persist('fromSync')
                    if offlineEntity.respond_to?('afterSync'.to_sym)
                        offlineEntity.afterSync
                    end
                else
                    onlineEntity.persist
                    if onlineEntity.respond_to?('afterSync'.to_sym)
                        onlineEntity.afterSync
                    end  
                end
                if mainEntity[ServiceDocument.onlineClassName].to_s != ''
                    serviceDocumentEntities = Rho::JSON.parse(mainEntity[ServiceDocument.onlineClassName])
                    puts "ModifiedEntities serviceDocumentEntities size : #{serviceDocumentEntities.size}"
                    if serviceDocumentEntities.size > 0
                        serviceDocumentEntities.each do |serviceDocumentEntity|
                            documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'entityGuid' => serviceDocumentEntity['partyGuid'], 'policyGuid' => policyEntity['guid']})
                            unless documentContainer
                            	
                                documentContainer = DocumentContainer.new
                                documentContainer.entityGuid = serviceDocumentEntity['partyGuid']
                                documentContainer.entityTypeCd = 'Party'
                                documentContainer.policyGuid = policyEntity['guid']
                            end
                            serviceDocument = MobiSys::MobiSysEntitySchema.from_hash('ServiceDocument',serviceDocumentEntity)
                            
                            documentContainer.ServiceDocumentList.each do|serviceDocumentOfflineEntity| 
                                if serviceDocumentOfflineEntity.to_s != "" && serviceDocumentOfflineEntity.guid == serviceDocument.guid
                                    serviceDocumentOfflineEntity.merge(serviceDocument)
                                    documentContainer.persistAll('fromSync')
                                    if serviceDocumentEntity.respond_to?('afterSync'.to_sym)
                                        serviceDocumentEntity.afterSync
                                    end
                                end
                            end
                        end
                    end
                end

                if mainEntity[ServiceQuestionResponse.onlineClassName].to_s != ''
                    serviceQuestionResponseEntities = Rho::JSON.parse(mainEntity[ServiceQuestionResponse.onlineClassName])
                    puts "ModifiedEntities serviceQuestionResponseEntities size : #{serviceQuestionResponseEntities.size}"
                    if serviceQuestionResponseEntities.size > 0
                        serviceQuestionResponseEntities.each do |serviceQuestionResponseEntity|
                            questionContainer = QuestionContainer.loadObject(
                                :first, 
                                :conditions=>{
                                    {:name=>'entityGuid'} => serviceQuestionResponseEntity['partyGuid'],
                                    {:name=>'policyGuid'} => serviceQuestionResponseEntity['entityGuid']
                                },
                                :op => 'AND'
                            )

                            unless questionContainer
                                questionContainer = QuestionContainer.new
                                questionContainer.entityGuid = serviceQuestionResponseEntity['partyGuid']
                                questionContainer.policyGuid = policyEntity['guid']
                            end
                            serviceQuestionResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceQuestionResponse',serviceQuestionResponseEntity)
                            questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponseOfflineEntity|
                                if  serviceQuestionResponseOfflineEntity.to_s != "" && serviceQuestionResponseOfflineEntity.guid == serviceQuestionResponse.guid
                                    serviceQuestionResponseOfflineEntity.merge(serviceQuestionResponse)
                                    questionContainer.persist('fromSync')
                                    if serviceQuestionResponseEntity.respond_to?('afterSync'.to_sym)
                                        serviceQuestionResponseEntity.afterSync
                                    end
                                end
                            end
                        end
                    end
                end

                if mainEntity[Image.onlineClassName].to_s != ''
                    imageEntities = Rho::JSON.parse(mainEntity[Image.onlineClassName])
                    puts "ModifiedEntities imageEntities size : #{imageEntities.size}"
                    if imageEntities.size > 0
                        imageEntities.each do |imageEntity|
                            imageOfflineEntity = Image.loadObject(:first, :conditions=>{'guid' => imageEntity['guid']})
                            image = MobiSys::MobiSysEntitySchema.from_hash('Image',imageEntity)
                            if imageOfflineEntity.to_s != "" && imageOfflineEntity.guid == image.guid
                                imageOfflineEntity.merge(image)
                                imageOfflineEntity.persist('fromSync')
                                if imageEntity.respond_to?('afterSync'.to_sym)
                                    imageEntity.afterSync
                                end
                            end
                        end
                    end
                end

                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                    serviceSignatureEntities = Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                    puts "ModifiedEntities serviceSignatureEntities size : #{serviceSignatureEntities.size}"
                    if serviceSignatureEntities.size > 0
                        serviceSignatureEntities.each do |serviceSignatureEntity|
                            signatureContainer = SignatureContainer.loadObject(
                                :first, 
                                :conditions=>{
                                    {:name=>'entityGuid'} => policyEntity['guid']
                                }
                            )
                            unless signatureContainer
                                signatureContainer = SignatureContainer.new
                                signatureContainer.entityTypeCd = 'Policy'
                                signatureContainer.entityGuid = policyEntity['guid']
                            end
                            serviceSignatureEntity = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                if serviceSignatureOfflineEntity.to_s != "" && serviceSignatureOfflineEntity.guid == serviceSignatureEntity.guid
                                    serviceSignatureOfflineEntity.merge(serviceSignatureEntity)
                                    signatureContainer.persistAll
                                end
                            end
                        end
                    end
                end
                if mainEntity[Inward.onlineClassName].to_s != ''
                    inwardEntities = Rho::JSON.parse(mainEntity[Inward.onlineClassName])
                    puts "ModifiedEntities inwardEntities size : #{inwardEntities.size}"
                    inwardOfflineEntity = offlineEntity.getInward(policyEntity['proposalNum'], "APPLICATION_SUSPENSE")
                    if inwardEntities.size > 0 && inwardOfflineEntity.to_s != ""
                        inwardEntities.each do |inwardEntity|
                            inwardEntity = MobiSys::MobiSysEntitySchema.from_hash('Inward',inwardEntity)
                            if inwardOfflineEntity.to_s != "" && inwardOfflineEntity.guid == inwardEntity.guid
                                inwardOfflineEntity.merge(inwardEntity)
                                inwardOfflineEntity.persist('fromSync')
                                if inwardEntity.respond_to?('afterSync'.to_sym)
                                    inwardEntity.afterSync
                                end
                            end
                        end
                    end
                end
            elsif entityName == Inward.onlineClassName
                offlineEntity = offlineEntities[subEntity["guid"]]
                className = offlineEntity.class.name.to_s

                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,subEntity)
                if onlineEntity.versionID == -1 and offlineEntity
                    offlineEntity.destroy
                elsif offlineEntity
                    offlineEntity.merge(onlineEntity)
                    offlineEntity.persist('fromSync')
                    if offlineEntity.respond_to?('afterSync'.to_sym)
                        offlineEntity.afterSync
                    end
                else
                    onlineEntity.persist
                    if onlineEntity.respond_to?('afterSync'.to_sym)
                        onlineEntity.afterSync
                    end  
                end
            end
        end

	end
end

begin 
    require 'Policy/policy_service_company'
rescue LoadError => e
    puts 'policy_service_company not included'
end
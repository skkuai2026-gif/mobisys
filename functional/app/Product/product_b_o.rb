require 'Product/product_util'
require 'CommonModules/commonutil'
require 'singleton'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonClasses/FieldResult'
require 'CommonClasses/FieldValue'
require 'CommonClasses/QuotationIO'
require 'CommonModules/math'
require 'CommonClasses/Results'
require 'Policy/policy_b_o'

module MobiSys
	class ProductBO
		include Singleton
		extend MobiSys::BrowserHelper
		include MobiSys::CommonUtil
		@isCalculateIllust = false
		@isSolverCall = false
		@calculate_loggin_file = Array.new

		def self.getDashboard
			productsDashboard = Array.new
			# total
			sql = ""
			sql << "Select * from (Select * from Product p where p.productTypeCd = 'PLAN' order by launchDt desc limit 5) a order by launchdt asc limit 3"
			products = Product.find_by_sql(sql)

			products.each do |product|
				productsHM = Hash.new
				productsHM['PRODUCT'] = product.productId
				productsHM['PRODUCTFAMILY'] = product.productFamilyId
				productsDashboard.push(productsHM)
			end

			return productsDashboard
		end
		###################################################################################################


		def self.calculateModalRates(quotation, quotationProduct)
			if quotationProduct == nil
				return
			end
			@baseAnnualPremium = quotationProduct.baseAnnualPremium

			#/*
			# * calculate modal premium
			# */
			modalFactorList = nil#MobiSys::ProductUtil.getProductDefinitionTables(quotationProduct.productId, "MODALFACTOR")

			if modalFactorList == nil || modalFactorList.size == 0
				modalFactorList = Array.new#MobiSys::ProductUtil.getProductDefinitionTables("COMPANY", "MODALFACTOR")
			end

			modalPremiums = Hash.new
			modalFactorList.each do |modalFactorDT|
				modalPremium = @baseAnnualPremium.to_f * modalFactorDT.rate.to_f
				premiumAfterRounding = applyRoundingRule(modalPremium,  quotationProduct)
				modalPremiums[modalFactorDT.paymentFrequencyCd] = premiumAfterRounding
			end

			modalPremiumString = ""
			modalPremiumString << modalPremiums["YEARLY"].to_s << "|"
			modalPremiumString << modalPremiums["HALFYEARLY"].to_s << "|"
			modalPremiumString << modalPremiums["QUARTERLY"].to_s << "|"
			modalPremiumString << modalPremiums["MONTHLY"].to_s

			return modalPremiumString
		end
		###################################################################################################


		def self.calculateRateBasedSA(quotation, quotationProduct)
			MobiSys::ProductUtil.resetCache()
			if quotationProduct == nil
				return
			end

			@baseAnnualPremium = quotationProduct.baseAnnualPremium

			#/*
			# * calculate charges
			# */
			#chargeFacet = getFacet(quotationProduct, "CHARGE")
			#chargeList = nil

			#if chargeFacet != nil
			#  chargeList = calculateCharge(quotation, quotationProduct)
			#  chargeList.each do |charge|
			#    @baseAnnualPremium = @baseAnnualPremium.to_f + charge.to_f
			#  end
			#end

			premiumAfterRounding = applyRoundingRule(@baseAnnualPremium,  quotationProduct)
			@baseAnnualPremium = premiumAfterRounding
			@baseSumAssured = 0.0
			premiumDetails = getFacet(quotationProduct, "PREMIUMDETAILS")
			definitionTable = fetchPremiumDT(quotation, quotationProduct)

			if definitionTable == nil
				return
			end

			# formulae here
			if premiumDetails != nil
				case premiumDetails.premiumCalcMethod
				when "METHOD1"
					@baseSumAssured = @baseAnnualPremium.to_f * premiumDetails.units.to_f / definitionTable.rate.to_f
				when "METHOD2"
					@baseSumAssured = definitionTable.rate.to_f * premiumDetails.units.to_f
				when "METHOD3"
					#tbd
					@baseSumAssured = 0.0
				when "METHOD4"
					#tbd
					@baseSumAssured = 0.0
				else
					@baseSumAssured = @baseAnnualPremium.to_f * premiumDetails.units.to_f / definitionTable.rate.to_f
				end
			end

			sumAssuredAfterRounding = applyRoundingRule(@baseSumAssured,  quotationProduct)
			@baseSumAssured = sumAssuredAfterRounding
			quotationProduct.baseSumAssured = @baseSumAssured
			#
			# calculate discounts
			#
			discountFacet = getFacet(quotationProduct, "DISCOUNT")
			discountList = nil
			totalDiscount = 0
			if discountFacet != nil
				discountList = fetchDiscount(quotation, quotationProduct)
				discountList.each do |discount|
					totalDiscount = totalDiscount + discount.to_f
				end
			end

			if premiumDetails != nil
				case premiumDetails.premiumCalcMethod
				when "METHOD1"
					@baseSumAssured = @baseAnnualPremium.to_f * premiumDetails.units.to_f / ( definitionTable.rate.to_f - totalDiscount )
				when "METHOD2"
					@baseSumAssured = definitionTable.rate.to_f * premiumDetails.units.to_f
				when "METHOD3"
					#tbd
					@baseSumAssured = 0.0
				when "METHOD4"
					#tbd
					@baseSumAssured = 0.0
				else
					@baseSumAssured = @baseAnnualPremium.to_f * premiumDetails.units.to_f / ( definitionTable.rate.to_f - totalDiscount )
				end
			end

			sumAssuredAfterRounding = applyRoundingRule(@baseSumAssured,  quotationProduct)
			@baseSumAssured = sumAssuredAfterRounding
			#/*
			# * calculate modal premium
			# */
			modalFactor = 1.0
			modalFactorFacet = getFacet(quotationProduct, "MODALFACTOR")

			if modalFactorFacet != nil
				modalFactorDT = getProductDefinitionTable("MODALFACTOR", quotation, quotationProduct)
				if modalFactorDT != nil
					modalFactor = modalFactorDT.rate.to_f
				end
			else
				modalFactorList = MobiSys::ProductUtil.getProductDefinitionTables("COMPANY", "MODALFACTOR")
				modalFactorList.each do |modalFactorDO|
					if quotationProduct.paymentFrequencyCd != nil &&
						quotationProduct.paymentFrequencyCd == modalFactorDO.paymentFrequencyCd

						modalFactor = modalFactorDO.rate
						break
					end
				end
			end
			quotationProduct.modalPremium = @baseAnnualPremium.to_f * modalFactor.to_f
			premiumAfterRounding = applyRoundingRule(quotationProduct.modalPremium,  quotationProduct)
			quotationProduct.modalPremium = premiumAfterRounding
			MobiSys::ProductUtil.resetCache()
			return @baseSumAssured
		end
		###################################################################################################


		#TODO Remove as this thing is not driven by product definition table now. - MS
		def self.fetchPremiumDT(quotation, quotationProduct)
			singlePremium = getFacet(quotationProduct, "SINGLEPREMIUM")
			regularPremium = getFacet(quotationProduct, "REGULARPREMIUM")
			flexiblePremium = getFacet(quotationProduct, "FLEXIBLEPREMIUM")
			definitionTable = nil

			# check which premium facet needs to be used
			if singlePremium != nil
				definitionTable = getProductDefinitionTable("SINGLEPREMIUM", quotation, quotationProduct)
			elsif regularPremium != nil
				definitionTable = getProductDefinitionTable("REGULARPREMIUM", quotation, quotationProduct)
			elsif flexiblePremium != nil
				definitionTable = getProductDefinitionTable("FLEXIBLEPREMIUM", quotation, quotationProduct)
			end # check which premium facet needs to be used

			return definitionTable
		end
		###################################################################################################


		def self.calculateExactAnnualPremium(quotation, quotationProduct)
			MobiSys::ProductUtil.resetCache()
			if quotationProduct == nil
				return
			end

			@baseAnnualPremium = 0.0
			premiumDetails = getFacet(quotationProduct, "PREMIUMDETAILS")
			definitionTable = fetchPremiumDT(quotation, quotationProduct)
			if definitionTable == nil
				return
			end

			# formulae here
			if premiumDetails != nil
				case premiumDetails.premiumCalcMethod
				when "METHOD1"
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD2"
					@baseAnnualPremium = definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD3"
					#tbd
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD4"
					#tbd
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD5"
					fpDefinitionTable = getProductDefinitionTable("FLEXIBLEPREMIUM", quotation, quotationProduct)

					premiumRate = ((definitionTable.rate.to_f * 300000.0) + (fpDefinitionTable.rate.to_f * (quotationProduct.baseSumAssured.to_f - 300000.0))) / quotationProduct.baseSumAssured.to_f
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * premiumRate.to_f / premiumDetails.units.to_f
				else
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				end
			end

			#
			# calculate discounts
			#
			discountFacet = getFacet(quotationProduct, "DISCOUNT")
			discountList = nil

			if discountFacet != nil
				discountList = calculateDiscount(quotation, quotationProduct)
				discountList.each do |discount|
					@baseAnnualPremium = @baseAnnualPremium.to_f - discount.to_f
				end
			end

			#/*
			# * calculate charges
			# */
			chargeFacet = getFacet(quotationProduct, "CHARGE")
			chargeList = nil

			quotationProduct.baseAnnualPremium = @baseAnnualPremium

			if chargeFacet != nil
				chargeList = calculateCharge(quotation, quotationProduct)
				chargeList.each do |charge|
					@baseAnnualPremium = @baseAnnualPremium.to_f + charge.to_f
				end
			end

			quotationProduct.baseAnnualPremium = @baseAnnualPremium.to_f
			MobiSys::ProductUtil.resetCache()
			return @baseAnnualPremium.to_f
		end
		###################################################################################################


		def self.calculateRateBasedPremium(quotation, quotationProduct)
			MobiSys::ProductUtil.resetCache()

			if quotationProduct == nil
				return
			end

			@baseAnnualPremium = 0.0
			premiumDetails = getFacet(quotationProduct, "PREMIUMDETAILS")
			definitionTable = fetchPremiumDT(quotation, quotationProduct)

			if definitionTable == nil
				return
			end

			# formulae here
			if premiumDetails != nil
				case premiumDetails.premiumCalcMethod
				when "METHOD1"
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD2"
					@baseAnnualPremium = definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD3"
					#tbd
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				when "METHOD4"
					#tbd
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				else
					@baseAnnualPremium = quotationProduct.baseSumAssured.to_f * definitionTable.rate.to_f / premiumDetails.units.to_f
				end

			end

			#
			# calculate discounts
			#
			discountFacet = getFacet(quotationProduct, "DISCOUNT")
			discountList = nil

			if discountFacet != nil
				discountList = calculateDiscount(quotation, quotationProduct)
				discountList.each do |discount|
					@baseAnnualPremium = @baseAnnualPremium.to_f - discount.to_f
				end
			end

			#/*
			# * calculate charges
			# */
			chargeFacet = getFacet(quotationProduct, "CHARGE")
			chargeList = nil

			if chargeFacet != nil
				chargeList = calculateCharge(quotation, quotationProduct)
				chargeList.each do |charge|
					@baseAnnualPremium = @baseAnnualPremium.to_f + charge.to_f
				end
			end

			premiumAfterRounding = applyRoundingRule(@baseAnnualPremium,  quotationProduct)
			@baseAnnualPremium = premiumAfterRounding

			#/*
			# * calculate modal premium
			# */
			modalFactor = 1.0
			modalFactorFacet = getFacet(quotationProduct, "MODALFACTOR")

			if modalFactorFacet != nil
				modalFactorDT = getProductDefinitionTable("MODALFACTOR", quotation, quotationProduct)

				if modalFactorDT != nil
					modalFactor = modalFactorDT.rate.to_f
				end
			else
				modalFactorList = MobiSys::ProductUtil.getProductDefinitionTables("COMPANY", "MODALFACTOR")
				modalFactorList.each do |modalFactorDO|
					if  quotationProduct.paymentFrequencyCd != nil &&
						quotationProduct.paymentFrequencyCd == modalFactorDO.paymentFrequencyCd
						modalFactor = modalFactorDO.rate
						break
					end
				end
			end
			quotationProduct.modalPremium = @baseAnnualPremium.to_f * modalFactor.to_f
			premiumAfterRounding = applyRoundingRule(quotationProduct.modalPremium,  quotationProduct)
			quotationProduct.modalPremium = premiumAfterRounding
			MobiSys::ProductUtil.resetCache()

			return @baseAnnualPremium
		end
		###############################################################################################


		def self.calculateRiderValues(quotation, quotationProduct,policyYear)
			mainProduct = quotation.getBaseProduct.product
			riderAutoPopulationReqFlag =  mainProduct.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')
			facetRiderAssociation = mainProduct.getRiderAssociationFacet()

			basePlan = quotation.getBasePlan()
			if facetRiderAssociation and facetRiderAssociation != ""
				riderAssociation = mainProduct.getRiderAssociationDO(quotationProduct.productId, basePlan.productPlanOptionCd, quotationProduct.productPlanOptionCd, facetRiderAssociation, quotationProduct.productSeq, quotationProduct.partyRoleCd)

				if riderAssociation && riderAssociation.riderModelCd.to_s != ''
					# set some field of rider assosiation to current rider product
					quotationProduct.linkedFl = riderAssociation.linkedFl
					quotationProduct.parentproductSeq = riderAssociation.parentproductSeq
					evaluateModel(quotation, quotationProduct, riderAssociation.riderModelCd, true,policyYear)
					if quotationProduct.roleCd
						party = quotation.getPartyByRole(quotationProduct.roleCd)
						quotationProduct.combinedEntryAge = party.age if party and party.age
					end
				end
			end
		end
		###################################################################################################


		def self.evaluateModel(quotation, quotationProduct, modelCd, isReqCheckGetValue,policyYear=nil)
			modelFieldResult = nil
			results = MobiSys::DataObjects::Results.new
			results.createAttr("quotation")
			results.quotation = quotation
			results.createAttr("quotationProduct")
			results.quotationProduct = quotationProduct
			results.createAttr("basePlan")
			results.basePlan = quotation.getBaseProduct()
			results.createAttr("currPolicyYear")
			results.currPolicyYear = policyYear
			results.createAttr("currPolicyMonth")
			results.currPolicyMonth = 1

			#firstDTHash = Hash.new
			productDO = quotationProduct.product

			if modelCd
				illustrationModelDO = IllustrationModel.loadObject(:first, :conditions => {{:name => 'modelCd'} => modelCd})
				if illustrationModelDO != nil
					if "ONCE" == illustrationModelDO.computationFrequencyCd
						if policyYear > 1
							return modelFieldResult
						end
					end

					#method creation - start
					illustrationModelDO.IllustrationFacetList.each do |ift|
						#Method creation start
						if ift.facetTypeCd == "INPUT"
							results.defineMethod(ift.methodName,"self.#{ift.inputElementSource}.#{ift.inputDataElement}")
							results.createAttr(ift.computedElementName)
						elsif ift.facetTypeCd == "COMPUTEDFORMULA" #or ift.facetTypeCd == "INPUT"
							unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
								results.defineMethod(ift.methodName, ift.expression, false)
								results.createAttr(ift.computedElementName)
							else
								illustrationModelDO.IllustrationRateList.each do |irt|
									newExp = ift.expression
									data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = original.gsub("perRate_", "")
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|
									results.defineMethod("#{ift.computedElementName}#{irt.id}_m", newExp)
									results.createAttr("#{ift.computedElementName}#{irt.id}")
								end
							end
						elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL" or ift.facetTypeCd == "GROUPING"
							unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
								results.createAttr(ift.computedElementName)
							else
								illustrationModelDO.IllustrationRateList.each do |irt|
									results.createAttr("#{ift.computedElementName}#{irt.id}")
								end
							end
						end
						#method creation end
					end
				end
			end
			if illustrationModelDO == nil
				# log.warn("No Master defined for Model " + modelCd)
				#throw new SymbiosysRuntimeException("No Master defined for SA Illustration model " + modelCd);
				return modelFieldResult
			end
			if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
				modellog(illustrationModelDO)
			end

			modelFieldResult = MobiSys::DataObjects::FieldResult.new
			#first add the product name as hardcoded field value
			modelFieldResult.addFieldValue(nil, "product_name", productDO.getLongName(), "Product name", 0)
			modelFieldResult.entityTypeCd = productDO.longName
			illustrationModelDO.IllustrationFacetList.each do |illusFacetDO|
				evaluatedVal = evaluateFieldNew(illustrationModelDO, illusFacetDO, quotation, results, quotationProduct, nil)
				#for premium context input data element attribute is being used to store the output in a particular field of PolicyProductDO.
				fieldName = ""
				if illusFacetDO.inputDataElement!=nil and illusFacetDO.inputDataElement!=""  and evaluatedVal
					begin
						fieldName = illusFacetDO.inputDataElement
						planProductDO = (defined? $currentProduct) ? $currentProduct : quotation.getBaseProduct.product
        				riderAsscFacet = planProductDO.getRiderAssociationFacet()

						riderAssociationDO = planProductDO.getRiderAssociationDO(quotationProduct.productId, quotation.getBaseProduct.productPlanOptionCd, quotationProduct.productPlanOptionCd, riderAsscFacet, quotationProduct.productSeq, quotationProduct.partyRoleCd)

						if productDO.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement && productDO.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement.to_s.include?(illusFacetDO.inputDataElement) || (riderAssociationDO && riderAssociationDO.inputDataElement.to_s.include?(illusFacetDO.inputDataElement))
							quotationProduct.send(illusFacetDO.mapSetter,evaluatedVal)
						else
							isReqSetMethodInvoke = true
							premiumDetails = productDO.getPremiumDetailsFacet.OfflinePremiumDetailsList[0]
							
							readOnlyFields = premiumDetails.inputDataElement if premiumDetails
							#only if the readonly fields is overridden at rider association level then consider it. 
							readOnlyFields = riderAssociationDO.inputDataElement if riderAssociationDO && riderAssociationDO.inputDataElement != nil
							if isReqCheckGetValue
								if readOnlyFields.to_s != ""
									readOnlyFldList = readOnlyFields.to_s.split(',')
									if (readOnlyFldList == nil or readOnlyFldList.empty?) or !readOnlyFldList.include? fieldName
										modelSource = Rho::RhoConfig.sources[quotationProduct.class.name.to_s]
										propertyExists = modelSource["schema"]["property"].has_key?(fieldName)
										object = propertyExists ? quotationProduct.send("#{fieldName}".to_sym) : nil
										if(!propertyExists || object.to_i != 0)
											isReqSetMethodInvoke = false
										end
									end
								end
							end
							if isReqSetMethodInvoke
								quotationProduct.send(illusFacetDO.mapSetter, evaluatedVal)
							end
						end
						#quotationProduct.send("#{illusFacetDO.inputDataElement}=", evaluatedVal)
					rescue StandardError => boom
						puts ">>>StandardError occured in eval: #{boom}"
					end
				end
				modelFieldResult.addFieldValue(nil, illusFacetDO.computedElementName, evaluatedVal, illusFacetDO.elementLabel, illusFacetDO.computationOrder)
				if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
					log(modelFieldResult,illusFacetDO.computedElementName)
				end
			end
 			return modelFieldResult
		end
		###################################################################################################

		def getFacetOutput(tableTypeMappingSeq, quotation, quotationProduct, party)
			dt = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, party)
			if dt and dt.rate.to_s != ""
				return dt.rate.to_f
			elsif dt and dt.outputAction and dt.outputAction != ""
				return dt.outputAction
			else
				return 0.0  
			end
		end

		def self.getProductDefinitionTable(tableTypeMappingSeq, quotation, quotationProduct, party=nil, quotationIO=nil)
			definitionTable = nil
			definitionTable = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, party, false, false, quotationIO) if tableTypeMappingSeq
			return definitionTable
		end
		###################################################################################################


		def self.getProductDefinitionTableList(tableTypeMappingSeq, quotation, quotationProduct)
			definitionTables = nil
			definitionTables = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, nil, true, false) if tableTypeMappingSeq
			return definitionTables
		end
		###################################################################################################


		def self.applyRoundingRule(amount, quotationProduct)
			otherDetailsFacet = getFacet(quotationProduct, "OTHERDETAILS")

			if otherDetailsFacet != nil
				case otherDetailsFacet.roundingRule
				when "NEARCENT"
					amount = amount.to_f.round(2)
				when "NEXTCENT"
					amount = amount.to_f * 100;
					tmp = amount.to_f.ceil
					amount = tmp.to_f / 100;
				when "NEARDOLLAR"
					amount = amount.to_f.round(0)
				when "NEXTDOLLAR"
					amount = amount.to_f.ceil
				when "TRUNCATE"
					amount = amount.to_f.floor
				else
					amount = amount
				end
			end
			return amount
		end
		###################################################################################################


		def self.mergeHybridIllustration(partialProducts, partialBenefits, term)
			@benefitTable = Array.new
			totalAccumulatedPremium = 0
			(1..term).each do |policyYear|

				@benefitRow = Hash.new

				totalPremiumReceived = 0

				totalTopupPremium = 0
				totalSumAssured = 0
				totalDeathBenefit = 0
				totalMaturityValue = 0
				totalICPValue = 0
				totalNGBenefitValue = 0
				totalLoyaltyBenefit = 0
				totalCV = 0

				partialProducts.each do |quotationProduct|
					@benefitRow["policyYear"] = policyYear
					benefitForPlanCode = partialBenefits[quotationProduct.planCode]
					benefitPlanCodeYear = benefitForPlanCode[policyYear]
					#puts "benefit for " << quotationProduct.planCode << " for year "<< policyYear.to_i << ": " << benefitPlanCodeYear.to_s

					if benefitPlanCodeYear != nil
						@benefitRow["attainedAge"] = benefitPlanCodeYear["attainedAge"]
						@benefitRow["allocationCharge"] = benefitPlanCodeYear["allocationCharge"] if benefitPlanCodeYear["allocationCharge"] != nil && benefitPlanCodeYear["allocationCharge"] != 0
						@benefitRow["allocatedPremium"] = benefitPlanCodeYear["allocatedPremium"] if benefitPlanCodeYear["allocatedPremium"] != nil && benefitPlanCodeYear["allocatedPremium"] != 0

						@benefitRow["premiumReceived"+quotationProduct.planCode] = benefitPlanCodeYear["premiumReceived"]
						totalPremiumReceived = totalPremiumReceived + benefitPlanCodeYear["premiumReceived"].to_f.round(2)
						totalAccumulatedPremium = totalAccumulatedPremium + benefitPlanCodeYear["premiumReceived"]
						totalTopupPremium = totalTopupPremium + benefitPlanCodeYear["topupPremium"] if benefitPlanCodeYear["topupPremium"] != nil
						totalDeathBenefit = totalDeathBenefit + benefitPlanCodeYear["benefitAmount"] if benefitPlanCodeYear["benefitAmount"] != nil
						totalSumAssured = totalSumAssured + benefitPlanCodeYear["sumAssured"] if benefitPlanCodeYear["sumAssured"] != nil
						totalMaturityValue = totalMaturityValue + benefitPlanCodeYear["maturityValue"] if benefitPlanCodeYear["maturityValue"] != nil
						totalICPValue = totalICPValue + benefitPlanCodeYear["icpValue"] if benefitPlanCodeYear["icpValue"] != nil
						totalNGBenefitValue = totalNGBenefitValue + benefitPlanCodeYear["ngBenefitValue"] if benefitPlanCodeYear["ngBenefitValue"] != nil
						totalLoyaltyBenefit = totalLoyaltyBenefit + benefitPlanCodeYear["loyaltyBenefitValue"] if benefitPlanCodeYear["loyaltyBenefitValue"] != nil
						totalCV = totalCV + benefitPlanCodeYear["cvAmount"] if benefitPlanCodeYear["cvAmount"] != nil

						# fund value
						if benefitPlanCodeYear["totalFundValueL"] != nil
							@benefitRow["accumulatedBenefitsL"] = benefitPlanCodeYear["totalFundValueL"]
						end

						if benefitPlanCodeYear["totalFundValueM"] != nil
							@benefitRow["accumulatedBenefitsM"] = benefitPlanCodeYear["totalFundValueM"]
						end

						if benefitPlanCodeYear["totalFundValueH"] != nil
							@benefitRow["accumulatedBenefitsH"] = benefitPlanCodeYear["totalFundValueH"]
						end

						# mortality charge
						if benefitPlanCodeYear["mortalityChargeL"] != nil
							@benefitRow["mortalityChargeL"] = benefitPlanCodeYear["mortalityChargeL"]
						end

						if benefitPlanCodeYear["mortalityChargeM"] != nil
							@benefitRow["mortalityChargeM"] = benefitPlanCodeYear["mortalityChargeM"]
						end

						if benefitPlanCodeYear["mortalityChargeH"] != nil
							@benefitRow["mortalityChargeH"] = benefitPlanCodeYear["mortalityChargeH"]
						end

						#amc
						if benefitPlanCodeYear["amcL"] != nil
							@benefitRow["amcL"] = benefitPlanCodeYear["amcL"]
						end

						if benefitPlanCodeYear["amcM"] != nil
							@benefitRow["amcM"] = benefitPlanCodeYear["amcM"]
						end

						if benefitPlanCodeYear["amcH"] != nil
							@benefitRow["amcH"] = benefitPlanCodeYear["amcH"]
						end

						#aamc
						if benefitPlanCodeYear["aamcL"] != nil
							@benefitRow["aamcL"] = benefitPlanCodeYear["aamcL"]
						end

						if benefitPlanCodeYear["aamcM"] != nil
							@benefitRow["aamcM"] = benefitPlanCodeYear["aamcM"]
						end

						if benefitPlanCodeYear["aamcH"] != nil
							@benefitRow["aamcH"] = benefitPlanCodeYear["aamcH"]
						end

						# compounded value
						if benefitPlanCodeYear["compoundedValueL"] != nil
							@benefitRow["compoundedValueL"] = benefitPlanCodeYear["compoundedValueL"]
						end

						if benefitPlanCodeYear["compoundedValueM"] != nil
							@benefitRow["compoundedValueM"] = benefitPlanCodeYear["compoundedValueM"]
						end

						if benefitPlanCodeYear["compoundedValueH"] != nil
							@benefitRow["compoundedValueH"] = benefitPlanCodeYear["compoundedValueH"]
						end

						# deathBenefit
						if benefitPlanCodeYear["benefitAmountL"] != nil
							@benefitRow["benefitAmountL"] = totalDeathBenefit + benefitPlanCodeYear["benefitAmountL"].to_f
						end

						if benefitPlanCodeYear["benefitAmountM"] != nil
							@benefitRow["benefitAmountM"] = totalDeathBenefit + benefitPlanCodeYear["benefitAmountM"].to_f
						end

						if benefitPlanCodeYear["benefitAmountH"] != nil
							@benefitRow["benefitAmountH"] = totalDeathBenefit + benefitPlanCodeYear["benefitAmountH"].to_f
						end

						# loyalty benefit
						if benefitPlanCodeYear["totalLoyaltyBenefitL"] != nil
							@benefitRow["totalLoyaltyBenefitL"] = totalLoyaltyBenefit + benefitPlanCodeYear["totalLoyaltyBenefitL"].to_f
						end

						if benefitPlanCodeYear["totalLoyaltyBenefitM"] != nil
							@benefitRow["totalLoyaltyBenefitM"] = totalLoyaltyBenefit + benefitPlanCodeYear["totalLoyaltyBenefitM"].to_f
						end

						if benefitPlanCodeYear["totalLoyaltyBenefitH"] != nil
							@benefitRow["totalLoyaltyBenefitH"] = totalLoyaltyBenefit + benefitPlanCodeYear["totalLoyaltyBenefitH"].to_f
						end

						# total self fund value
						if benefitPlanCodeYear["totalSelfFundValueL"] != nil
							@benefitRow["totalSelfFundValueL"] = benefitPlanCodeYear["totalSelfFundValueL"]
						end

						if benefitPlanCodeYear["totalSelfFundValueM"] != nil
							@benefitRow["totalSelfFundValueM"] = benefitPlanCodeYear["totalSelfFundValueM"]
						end

						if benefitPlanCodeYear["totalSelfFundValueH"] != nil
							@benefitRow["totalSelfFundValueH"] = benefitPlanCodeYear["totalSelfFundValueH"]
						end

						# cv
						if benefitPlanCodeYear["totalFundValueL"] != nil
							@benefitRow["totalCVL"] = totalCV + benefitPlanCodeYear["totalFundValueL"]
						end

						if benefitPlanCodeYear["totalFundValueM"] != nil
							@benefitRow["totalCVM"] = totalCV + benefitPlanCodeYear["totalFundValueM"]
						end

						if benefitPlanCodeYear["totalFundValueH"] != nil
							@benefitRow["totalCVH"] = totalCV + benefitPlanCodeYear["totalFundValueH"]
						end

						#puts "#{quotationProduct.planCode}, #{policyYear.to_s}, #{benefitPlanCodeYear["premiumReceived"]}, #{totalAccumulatedPremium}"
					end

				end
				@benefitRow["totalPremiumReceived"] = totalPremiumReceived
				@benefitRow["totalAccumulatedPremium"] = totalAccumulatedPremium
				@benefitRow["totalTopupPremium"] = totalTopupPremium
				@benefitRow["totalDeathBenefit"] = totalDeathBenefit
				@benefitRow["totalSumAssured"] = totalSumAssured
				@benefitRow["totalMaturityValue"] = totalMaturityValue
				@benefitRow["totalICPValue"] = totalICPValue
				@benefitRow["totalNGBenefitValue"] = totalNGBenefitValue

				@benefitTable.push(@benefitRow)
			end

			return @benefitTable
		end
		####################################################################################################


		def self.calculateNARAmount(basisCd, rate, sumAssured, targetPremium, accumulatedExcessPremium, accumulatedWithdrawals, fundValue)
			benefitAmount = 0

			if basisCd != nil && rate != nil
				#benefit amount
				case basisCd
				when "MAX_SA_PR" # sum assured
					accumulatedValue = (targetPremium.to_f * rate.to_f / 100.0) + ( 1.25 * ( accumulatedExcessPremium.to_f - accumulatedWithdrawals.to_f ) ) - fundValue.to_f
					if sumAssured.to_f > accumulatedValue.to_f
						benefitAmount = sumAssured
					else
						benefitAmount = accumulatedValue
					end
				end
			end

			return benefitAmount
		end
		###################################################################################################


		def self.calculateBenefitAmount(basisCd, rate, sumAssured, accumulatedPremium, cvAmount, fundValue=nil)
			benefitAmount = 0

			if basisCd != nil && rate != nil
				#benefit amount
				case basisCd
				when "SA" # sum assured
					benefitAmount = sumAssured.to_f * rate.to_f / 100
				when "AP" # accumulated premium
					benefitAmount = accumulatedPremium.to_f * rate.to_f / 100
				when "CV" # current value of investment
					benefitAmount = cvAmount.to_f * rate.to_f / 100
				when "MAX_SA_AP_CV" # max of sum assured, accumulated premium and current value
					sumAssured = sumAssured.to_f * rate.to_f / 100
					if sumAssured.to_f > accumulatedPremium.to_f
						if sumAssured.to_f > cvAmount.to_f
							benefitAmount = sumAssured
						else
							benefitAmount = cvAmount
						end
					else
						if accumulatedPremium.to_f > cvAmount.to_f
							benefitAmount = accumulatedPremium.to_f
						else
							benefitAmount = cvAmount
						end
					end
				when "MAX_SA_CV" # max of sum assured and current value
					sumAssured = sumAssured.to_f * rate.to_f / 100
					if sumAssured.to_f > cvAmount.to_f
						benefitAmount = sumAssured
					else
						benefitAmount = cvAmount
					end
				when "MAX_SA_AP" # max of sum assured and accumulated premium
					sumAssured = sumAssured.to_f * rate.to_f / 100
					if sumAssured.to_f > accumulatedPremium.to_f
						benefitAmount = sumAssured
					else
						benefitAmount = accumulatedPremium.to_f
					end
				when "MAX_AP_SA" # max of sum assured and accumulated premium
					accumulatedPremium = accumulatedPremium.to_f * rate.to_f / 100
					if sumAssured.to_f > accumulatedPremium.to_f
						benefitAmount = sumAssured
					else
						benefitAmount = accumulatedPremium.to_f
					end
				when "MAX_AP_CV" # max of accumulated premium and current value
					accumulatedPremium = accumulatedPremium.to_f * rate.to_f / 100
					if accumulatedPremium.to_f > cvAmount.to_f
						benefitAmount = accumulatedPremium.to_f
					else
						benefitAmount = cvAmount
					end
				when "FV" # fund value
					benefitAmount = fundValue.to_f * rate.to_f / 100
				else
					benefitAmount = sumAssured.to_f * rate.to_f / 100
				end

			end
			return benefitAmount
		end
		###################################################################################################


		def self.calculateTerm(quotation,quotationProduct)
			# calcTerm=0;
			# definitionTable=nil;
			# basePlan=quotation.getBaseProduct()
			# if quotationProduct.product.getFacetValue("TERMBASEDONMATURITY")=="YES"
			#    maturityAge= quotationProduct.product.getFacetValue("MATURITYAGE")
			#   if maturityAge!=nil && quotationProduct.combinedEntryAge!= nil
			#     calcTerm=maturityAge.to_i - quotationProduct.combinedEntryAge.to_i
			#   end
			# end
			# if basePlan!=nil && calcTerm > basePlan.productTerm.to_i
			#   calcTerm=basePlan.productTerm
			# end
			# if calcTerm!=0
			#   quotationProduct.productTerm=calcTerm
			# end

			modelCd = nil
			if quotationProduct.product == nil
				quotationProduct.product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
			end
			premiumDetailsFacet = quotationProduct.product.getFacet("PREMIUMDETAILS")
			premiumDetailsDO = nil
			if premiumDetailsFacet != nil
				premiumDetailsDO =  premiumDetailsFacet.OfflinePremiumDetailsList[0]
			end

			if premiumDetailsDO != nil and premiumDetailsDO.termModelCd != nil
				modelCd = premiumDetailsDO.termModelCd
			end
			if modelCd != nil
				evaluateModel(quotation, quotationProduct, modelCd, false, 1)
			end
		end
		###################################################################################################


		def self.premiumSAFlagBasedComputation(quotationProduct, quotation,premiumDetails, isWOP)
			#initialize the total to 0 since if used in expressions then gives an issue
			quotation.calculateTotalSumAssured()
			quotation.calculateTotalModalPremium()
			quotation.calculateTotalCoi()
			quotation.calculateTotalAnnualPremium()

			product = quotationProduct.product
			if premiumDetails.premiumSAFl == nil or premiumDetails.premiumSAFl == "SA"
				premiumResultField =  calculateModelBasedPremium(1, quotation, quotationProduct, product)
			elsif premiumDetails.premiumSAFl and (premiumDetails.premiumSAFl == "PREMIUM" or premiumDetails.premiumSAFl == "ANNUALPREMIUM")
				unless isWOP
					calculateModelBasedSA(1, quotation, quotationProduct, product)
					if premiumDetails.premiumModelCd
						calculateModelBasedPremium(1, quotation, quotationProduct, product)
					end
				end
			elsif premiumDetails.premiumSAFl and premiumDetails.premiumSAFl == "DUAL"
				# dual logic move from ui to api based on whichever field is modified other set as blank.
				if quotationProduct.to_s != "" && $currentActiveField.to_s != "" && quotationProduct.premiumSAFl && quotationProduct.premiumSAFl.to_s == "DUAL"
					if $currentActiveField.to_s == "baseSumAssured"
						quotationProduct.baseAnnualPremium = nil
						quotationProduct.modalPremium = nil
					elsif $currentActiveField.to_s == "modalPremium" || $currentActiveField.to_s == "baseAnnualPremium"
						quotationProduct.baseSumAssured = nil
					end
				end
				calculateModelBasedSA(1, quotation, quotationProduct, product) if quotationProduct.baseSumAssured.to_f == 0.0
				if premiumDetails.premiumModelCd
					calculateModelBasedPremium(1, quotation, quotationProduct, product)
				end
			elsif premiumDetails.premiumSAFl and (premiumDetails.premiumSAFl == "ANNUALINCOME" or premiumDetails.premiumSAFl == "MONTHLYINCOME")
				calculateModelBasedSA(1, quotation, quotationProduct, product) if premiumDetails.saModelCd
				if premiumDetails.premiumModelCd
					calculateModelBasedPremium(1, quotation, quotationProduct, product)
				end
			elsif premiumDetails.premiumSAFl and premiumDetails.premiumSAFl == "COMPUTEDSA"
				calculateModelBasedSA(1, quotation, quotationProduct, product) if premiumDetails.saModelCd
				if premiumDetails.premiumModelCd
					calculateModelBasedPremium(1, quotation, quotationProduct, product)
				end
			else
				calculateModelBasedSA(1, quotation, quotationProduct, product) if premiumDetails.saModelCd
				if premiumDetails.premiumModelCd
					calculateModelBasedPremium(1, quotation, quotationProduct, product)
				end
			end
		end
		###################################################################################################


		def self.calculateWOPSumAssured(quotation, quotationProduct)
      		#puts ">>>Inside calculateWOPSumAssured for quotation: #{quotation.quotationRefNum} quotationProduct: #{quotationProduct.productId}"
			basePlan = quotation.getBaseProduct
			rider_association_facet = basePlan.product.getRiderAssociationFacet
			rider_quotation_products_hash = MobiSys::CommonUtil.convertToHash(quotation.getRiders(),'productSeq',true)
			rider_quotation_products_hash = rider_quotation_products_hash.inject({}){|memo,(k,v)| memo[k.to_i] = v; memo}
			baseProduct = quotationProduct.product
			wopPremiumField = baseProduct.getFacetValue('WOPPREMIUMFIELD')
			wopPremiumField ||= "wopPremium"
			puts ">>>wop field derived as: #{wopPremiumField}"
			wopSA = basePlan.send wopPremiumField.to_sym
			wopSA = wopSA.to_f
			wopSAMonthly = basePlan.send (wopPremiumField+"Monthly").to_sym
			wopSAMonthly = wopSAMonthly.to_f
			wopSAQuarterly = basePlan.send (wopPremiumField+"Quarterly").to_sym
			wopSAQuarterly = wopSAQuarterly.to_f
			wopSAHalfYearly = basePlan.send (wopPremiumField+"HalfYearly").to_sym
			wopSAHalfYearly = wopSAHalfYearly.to_f
			if wopSA
				rider_association_facet.OfflineRiderAssociationList.each do |rad|
					if rider_quotation_products_hash.has_key? rad.productSeq.to_i
						rider_quotation_products_list = rider_quotation_products_hash[rad.productSeq.to_i]
						basePlanOptionMatched = true
						planOptionMatched = true
						if rad.basePlanOptionCd.to_s != '' && basePlan.productPlanOptionCd.to_s != '' && rad.basePlanOptionCd.to_s != basePlan.productPlanOptionCd.to_s
							basePlanOptionMatched = false
						end
						if !basePlanOptionMatched
							next
						end
						rider_quotation_products_list.each do |riderQuotationProduct|
							if rad.planOptionCd.to_s != '' && riderQuotationProduct.productPlanOptionCd.to_s != '' && rad.planOptionCd.to_s != riderQuotationProduct.productPlanOptionCd.to_s
								planOptionMatched = false
							end
							if !planOptionMatched
								next
							end
							if quotationProduct.productSeq.to_i != rad.productSeq.to_i #and rad.waivePremiumForWOPFl == 'YES' and riderQuotationProduct.wopPremium != nil
								wopRiderSA = riderQuotationProduct.send wopPremiumField.to_sym
								wopRiderSAMonthly = riderQuotationProduct.send (wopPremiumField+"Monthly").to_sym
								wopRiderSAQuarterly = riderQuotationProduct.send (wopPremiumField+"Quarterly").to_sym
								wopRiderSAHalfYearly = riderQuotationProduct.send (wopPremiumField+"HalfYearly").to_sym
								puts ">>>wopRiderSA calculated for rider #{riderQuotationProduct.productId}: #{wopRiderSA}"
								if wopRiderSA.to_s != ""
									wopSA += wopRiderSA.to_f
								end
								puts ">>>wopRiderSAMonthly calculated for rider #{riderQuotationProduct.productId}: #{wopRiderSAMonthly}"
								if wopRiderSAMonthly.to_s != ""
									wopSAMonthly += wopRiderSAMonthly.to_f
								end
									puts ">>>wopRiderSAQuarterly calculated for rider #{riderQuotationProduct.productId}: #{wopRiderSAQuarterly}"
								if wopRiderSAQuarterly.to_s != ""
									wopSAQuarterly += wopRiderSAQuarterly.to_f
								end
								puts ">>>wopRiderSAHalfYearly calculated for rider #{riderQuotationProduct.productId}: #{wopRiderSAHalfYearly}"
								if wopRiderSAHalfYearly.to_s != ""
									wopSAHalfYearly += wopRiderSAHalfYearly.to_f
								end
							end
						end
					end
				end
			end
			puts ">>>wop sa calculated as: #{wopSA}"
			quotationProduct.baseSumAssured = wopSA
			puts ">>>wop sa calculated as: #{wopSAMonthly}"
			quotationProduct.baseSumAssuredMonthly = wopSAMonthly
			puts ">>>wop sa calculated as: #{wopSAQuarterly}"
			quotationProduct.baseSumAssuredQuarterly = wopSAQuarterly
			puts ">>>wop sa calculated as: #{wopSAHalfYearly}"
			quotationProduct.baseSumAssuredHalfYearly = wopSAHalfYearly
    	end
		###################################################################################################


    	def self.calculateWOPPremium(quotation, quotationProduct, wopPremiumField)
			#puts ">>>Inside calculateWOPSumAssured for quotation: #{quotation.quotationRefNum} quotationProduct: #{quotationProduct.productId}"
			basePlan = quotation.getBaseProduct
			rider_association_facet = basePlan.product.getRiderAssociationFacet
			rider_quotation_products_hash = MobiSys::CommonUtil.convertToHash(quotation.getRiders(),'productSeq',true)
			rider_quotation_products_hash = rider_quotation_products_hash.inject({}){|memo,(k,v)| memo[k.to_i] = v; memo}
			# baseProduct = quotationProduct.product
			# wopPremiumField = baseProduct.getFacetValue('WOPPREMIUMCOMPONENT')
			# wopPremiumField ||= "wopPremium"
			#puts ">>>wopPremium field derived as: #{wopPremiumField}"
			wopPremium = basePlan.send wopPremiumField.to_sym
			wopPremium = wopPremium.to_f

			if wopPremium
				rider_association_facet.OfflineRiderAssociationList.each do |rad|
					if rider_quotation_products_hash.has_key? rad.productSeq.to_i
						rider_quotation_products_list = rider_quotation_products_hash[rad.productSeq.to_i]
						basePlanOptionMatched = true
						planOptionMatched = true
						if rad.basePlanOptionCd.to_s != '' && basePlan.productPlanOptionCd.to_s != '' && rad.basePlanOptionCd.to_s != basePlan.productPlanOptionCd.to_s
							basePlanOptionMatched = false
						end
						if !basePlanOptionMatched
							next
						end
						rider_quotation_products_list.each do |riderQuotationProduct|
							if rad.planOptionCd.to_s != '' && riderQuotationProduct.productPlanOptionCd.to_s != '' && rad.planOptionCd.to_s != riderQuotationProduct.productPlanOptionCd.to_s
								planOptionMatched = false
							end
							if !planOptionMatched
								next
							end
              				if quotationProduct.productSeq.to_i != rad.productSeq.to_i #and rad.waivePremiumForWOPFl == 'YES' and riderQuotationProduct.wopPremium != nil
              					wopRiderPremium = riderQuotationProduct.send wopPremiumField.to_sym
                				#puts ">>>wopRiderSA calculated for rider #{riderQuotationProduct.productId}: #{wopRiderPremium}"
				                if wopRiderPremium.to_s != ""
				                  	wopPremium += wopRiderPremium.to_f
				                end
              				end
            			end
          			end
        		end
      		end
      		#puts ">>>wop sa calculated as wopPremium: #{wopPremium}"
      		quotationProduct.baseAnnualPremium = wopPremium
    	end
		###################################################################################################


		def self.calculateModelBasedPremium(policyYear, quotation, quotationProduct, product)
			#puts ">>>Inside calculateModelBasedPremium"
			#variables = Hash.new
			results = MobiSys::DataObjects::Results.new
			results.createAttr("currPolicyYear")
			results.currPolicyYear = policyYear.to_f
			#results.addAttr("currPolicyYear", policyYear.to_f)
			results.createAttr("currYear")
			results.currYear = policyYear.to_f
			#results.addAttr("currYear", policyYear.to_f)
			results.createAttr("currPolicyMonth")
			results.currPolicyMonth = 1.to_f
			#results.addAttr("currPolicyMonth", 1.to_f)
			results.createAttr("quotation")
			results.quotation = quotation
			#results.addAttr("quotation", quotation)
			results.createAttr("quotationProduct")
			results.quotationProduct = quotationProduct
			results.createAttr("basePlan")
			results.basePlan = quotation.getBaseProduct()
			results.createAttr("currInsured")
			results.currInsured = quotationProduct.insuredPartyRefGuid
			results.createAttr("currBasicParseCount")
			currParseCount = results.currBasicParseCount
			results.createAttr("currCycleCount")
			currCycleCount = results.currCycleCount

			premiumResultField = nil
			#firstDTHash = Hash.new
			@@prdPremiumModelMap ||= Hash.new
			illustrationModel = @@prdPremiumModelMap[product.object]
			premiumDetailsFacet = product.getPremiumDetailsFacet
			unless illustrationModel
				if premiumDetailsFacet
					premiumDetails = premiumDetailsFacet.OfflinePremiumDetailsList[0]
					if premiumDetails
						modelCd = premiumDetails.premiumModelCd
						if modelCd
							illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => modelCd})
							illustrationModel.setIllustrationFacetList illustrationModel.IllustrationFacetList.sort{|x,y| x.computationOrder <=> y.computationOrder}
							puts ">>>No model defined  with modelCd #{modelCd}" unless illustrationModel
							@@prdPremiumModelMap[product.object] = illustrationModel
						else
							#puts ">>>No premium model defined for product #{product.productId}"
						end
					else
						puts ">>>No premium details defined for product #{product.productId}"
					end
				else
					puts ">>>No Premium details facet defined for product #{product.productId} "
				end
			end

			if illustrationModel
				if "ONCE" == illustrationModel.computationFrequencyCd
					if policyYear > 1
						return premiumResultField
					end
				end

				#method creation - start
				illustrationModel.IllustrationFacetList.each do |ift|
					#Method creation start
					if ift.facetTypeCd == "INPUT"
						results.defineMethod(ift.methodName,"self.#{ift.inputElementSource}.#{ift.inputDataElement}")
						results.createAttr(ift.computedElementName)
					elsif ift.facetTypeCd == "COMPUTEDFORMULA" #or ift.facetTypeCd == "INPUT"
						unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
							results.defineMethod(ift.methodName, ift.expression)
							results.createAttr(ift.computedElementName)
						else
							illustrationModel.IllustrationRateList.each do |irt|
								newExp = ift.expression
								data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
								data.each do |match|
									original = match[0].to_s
									newString = String.new(original.gsub("perRate_", ""))
									newString << irt.id.to_s
									newExp = newExp.sub(original, newString)
								end #data.each do |match|
								results.defineMethod("#{ift.computedElementName}#{irt.id}_m", newExp)
								results.createAttr("#{ift.computedElementName}#{irt.id}")
							end
						end
					elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL" or ift.facetTypeCd == "GROUPING"
						unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
							results.createAttr(ift.computedElementName)
						else
							illustrationModel.IllustrationRateList.each do |irt|
								results.createAttr("#{ift.computedElementName}#{irt.id}")
							end
						end
					end
					#method creation end
				end #illustrationModel.IllustrationFacetList.each do |ift|
				#method creation - end

				quotation.policyYear = policyYear
				if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
					modellog(illustrationModel)
				end
				premiumResultField = MobiSys::DataObjects::FieldResult.new
				premiumResultField.addFieldValue(nil, "product_name", product.longName,"Product name",0)
				premiumResultField.entityTypeCd = product.longName
				results.createAttr("currCycleCount")
				currCycleCount = results.currCycleCount
				premiumResultField.id = currCycleCount
				#*************@WOPChanges start**********
				illusFacetsPerRider = Array.new
				basicIllusFacets = Array.new
				maxParseLevel = 1

				illustrationModel.IllustrationFacetList.each do |illustrationFacet|
					if illustrationFacet.parseLevel == nil
						illustrationFacet.parseLevel = 1
					end
					if illustrationFacet.computePerInstanceOf == 'RIDER'
						illustrationFacet.computationFreqCd = 'EVERYCYCLE'
						illusFacetsPerRider.push(illustrationFacet)
						next
					else
						basicIllusFacets.push(illustrationFacet)
					end
					maxParseLevel = illustrationFacet.parseLevel if illustrationFacet.parseLevel > maxParseLevel
				end

				hmRiderGroupedAttribValues= {}
				riders = quotation.getRiders
				riders.push(quotation.getBaseProduct)
				riderProductHash = Hash.new
				quotation.QuotationProductList.each do |qp|
					next if qp.productTypeCd == "PLAN"
					riderProductHash[qp.productId] = qp.product
				end

				for parseCount in 1..maxParseLevel
					riderFacetsComputed = false
					basicIllusFacets.each do |illustrationFacet|
						if illustrationFacet.parseLevel != parseCount
							if premiumResultField.containsFieldInMap(illustrationFacet.computedElementName)
								results.setAttr(illustrationFacet.computedElementName, premiumfieldResult.getFieldValueObject(illustrationFacet.computedElementName))
								next
							end
						end

						if illustrationFacet.facetTypeCd == 'GROUPING'
							if !riderFacetsComputed && riders.size > 0 && illusFacetsPerRider.size > 0
								$wopIO = MobiSys::IO::QuotationIO.new unless $wopIO
								hmRiderGroupedAttribValues = calculateRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, $wopIO, riderProductHash, riders, Hash.new, quotationProduct)
								riderFacetsComputed=true
							end

							if !hmRiderGroupedAttribValues.empty?
								evaluatedValue = hmRiderGroupedAttribValues["Group_#{illustrationFacet.inputDataElement}"]
								results.setAttr(illustrationFacet.computedElementName, evaluatedValue)
							else
								evaluatedValue = 0.0
								results.setAttr(illustrationFacet.computedElementName, evaluatedValue)
							end
						else
							evaluatedValue = evaluateFieldNew(illustrationModel, illustrationFacet, quotation, results, quotationProduct, nil)
						end

						#evaluatedValue = evaluateField(illustrationModel, illustrationFacet, quotation, variables, quotationProduct)
						premiumDetails = premiumDetailsFacet.OfflinePremiumDetailsList[0]
						if illustrationFacet.inputDataElement!=nil and illustrationFacet.inputDataElement!=""  and evaluatedValue and illustrationFacet.facetTypeCd != "GROUPING"
							begin
								# exp = "quotationProduct.#{illustrationFacet.inputDataElement} = evaluatedValue"
								# eval(exp)
								fieldName = illustrationFacet.inputDataElement
								isReqSetMethodInvoke = true
								if premiumDetails
									readOnlyFields = premiumDetails.inputDataElement
									if readOnlyFields.to_s != ""
										readOnlyFldList = readOnlyFields.to_s.split(',')
										unless readOnlyFldList.include? fieldName
											modelSource = Rho::RhoConfig.sources[quotationProduct.class.name.to_s]
											propertyExists = modelSource["schema"]["property"].has_key?(fieldName)
											object = propertyExists ? quotationProduct.send("#{fieldName}".to_sym) : nil
											if(!propertyExists || object.to_f != 0.0)
												isReqSetMethodInvoke = false
											end
										end
									end
									if quotationProduct.productTypeCd.to_s == "PLAN" && premiumDetails.premiumSAFl.to_s == 'DUAL'
										isReqSetMethodInvoke = true
									end
								end
								if isReqSetMethodInvoke
									quotationProduct.send(illustrationFacet.mapSetter, evaluatedValue)
								end
								# quotationProduct.send(illustrationFacet.mapSetter, evaluatedValue)
							rescue StandardError => boom
								puts ">>>StandardError occured in eval: #{boom}"
							end
						end
						premiumResultField.addFieldValue(nil,illustrationFacet.computedElementName, evaluatedValue,illustrationFacet.elementLabel,illustrationFacet.computationOrder)
						if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
							log(premiumResultField,illustrationFacet.computedElementName)
						end
					end
				end
			end
			$wopIO = nil
			# puts "Returning from calculateModelBasedPremium with results #{premiumResultField.inspect}"
			premiumResultField
		end
		###################################################################################################


		def self.evaluateFieldNew(illustrationModel, illustrationFacet, quotation, results, quotationProduct, quotationIO)
			p "inside evaluate field neww=====#{illustrationModel.modelCd}"
			evaluatedValue = nil
			begin
				case illustrationFacet.facetTypeCd
				when "INPUT"
					results.quotationProduct = quotationProduct if quotationProduct
					value = results.send illustrationFacet.methodName
					evaluatedValue = value
					evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
				when "COMPUTEDFORMULA"
					results.quotationProduct = quotationProduct
					evaluatedValue = results.send illustrationFacet.methodName
					evaluatedValue.gsub!("\"","") if evaluatedValue.is_a? String
					evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
					results.setAttr1(illustrationFacet.setter, evaluatedValue)
				when "COMPUTEDLOOKUP"
					results.quotationIO = quotationIO
					evaluatedValue = results.send illustrationFacet.methodName
					evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
					results.setAttr1(illustrationFacet.setter, evaluatedValue)
				when "COMPUTEDDECISIONTBL"
					if illustrationFacet.computedFieldNameForRule
						quotation.additionalField = results.send illustrationFacet.computedFieldNameForRule
					end
					party = nil
					if illustrationFacet.partyRoleCdForRule.to_s != ""
						party = quotation.getPartyByRole(illustrationFacet.partyRoleCdForRule.to_s)
					end
					dt = MobiSys::ProductUtil.getProductDefinitionTableDO(illustrationFacet.ruleSeq, quotation, quotationProduct, party)
					value = nil
					if dt and dt.rate.to_s != ""
						value = dt.rate.to_f
					elsif dt and dt.outputAction and dt.outputAction != ""
						value = dt.outputAction
					else
						value = 0.0  
					end
					evaluatedValue = value
					evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
					results.setAttr1(illustrationFacet.setter, evaluatedValue) unless illustrationFacet.facetTypeCd == "INPUT"
				end
			rescue StandardError => boom
				RhoLog.error("EvaluateFieldNew", ">>>Error occured while evaluating field: #{boom}\n#{boom.backtrace}")
			end
			puts ">>>evaluatedFieldNEWWWWWWWWWWWWW model: #{illustrationModel.modelCd} computedElementName: #{illustrationFacet.computedElementName} evaluatedValue: #{evaluatedValue}"
			evaluatedValue
		end
		###################################################################################################


		def self.evaluateField(illustrationModel, illustrationFacet, quotation, results, quotationProduct, quotationIO,computedElementName=nil)
			evaluatedValue = nil
			expression = illustrationFacet.expression
			if illustrationFacet.facetTypeCd == "INPUT"
				results.quotationProduct = quotationProduct if quotationProduct
				methodName = "#{illustrationFacet.computedElementName}_m".to_sym
				value = results.send methodName
				evaluatedValue = value
				evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
			elsif expression and illustrationFacet.facetTypeCd == "COMPUTEDFORMULA"
				results.quotationProduct = quotationProduct
				methodName = "#{illustrationFacet.computedElementName}_m".to_sym
				evaluatedValue = results.send methodName
				evaluatedValue.gsub!("\"","") if evaluatedValue.is_a? String
				evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
				results.setAttr(illustrationFacet.computedElementName, evaluatedValue)
			elsif expression and illustrationFacet.facetTypeCd == "COMPUTEDLOOKUP"
				results.quotationIO = quotationIO
				methodName = "#{illustrationFacet.computedElementName}_m".to_sym
				evaluatedValue = results.send methodName
				evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
				results.setAttr(illustrationFacet.computedElementName, evaluatedValue)
			elsif illustrationFacet.ruleSeq
				if illustrationFacet.computedFieldNameForRule
					quotation.additionalField = results.send illustrationFacet.computedFieldNameForRule
				end

				party = nil
				if illustrationFacet.partyRoleCdForRule.to_s != ""
					party = quotation.getPartyByRole(illustrationFacet.partyRoleCdForRule.to_s)
				end

				dt = MobiSys::ProductUtil.getProductDefinitionTableDO(illustrationFacet.ruleSeq, quotation, quotationProduct, party)
				value = nil
				if dt and dt.rate.to_s != ""
					value = dt.rate.to_f
				elsif dt and dt.outputAction and dt.outputAction != ""
					value = dt.outputAction
				else
					value = 0.0
				end
				evaluatedValue = value
				evaluatedValue = evaluatedValue.to_s.to_d if defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.class.name.to_s == "Float" && $rhoconfig[:useBigDecimal]
				results.setAttr("#{illustrationFacet.computedElementName}", evaluatedValue) unless illustrationFacet.facetTypeCd == "INPUT"
			end
			#if outputdisplay is part of table/header and if this is an SI model then add to output map
			if(illustrationFacet.outputDisplayTypeCd.to_s != "" && @siCalcCompleteOutputData != nil)
				addElementToOutputMap(illustrationFacet, evaluatedValue,computedElementName);
			end
			# puts ">>>evaluatedField model: #{illustrationModel.modelCd} computedElementName: #{illustrationFacet.computedElementName} evaluatedValue: #{evaluatedValue}"
			evaluatedValue
		end
		###################################################################################################


		def self.calculateModelBasedSA(policyYear, quotation, quotationProduct, product)
			#puts ">>>Inside calculateModelBasedSA"
			saFieldResult = nil
			#return saFieldResult unless quotationProduct.baseAnnualPremium or quotationProduct.modalPremium
			results = MobiSys::DataObjects::Results.new
			results.createAttr("quotation")
			results.quotation = quotation
			results.createAttr("quotationProduct")
			results.quotationProduct = quotationProduct
			results.createAttr("basePlan")
			results.basePlan = quotation.getBaseProduct()

			#results.addAttr("currPolicyYear", policyYear.to_f)
			results.createAttr("currPolicyYear")
			results.currPolicyYear = policyYear.to_f
			#results.addAttr("currPolicyMonth", 1.to_f)
			results.createAttr("currPolicyMonth")
			results.currPolicyMonth = 1.to_f
			#firstDTHash = Hash.new
			@@prdSAModelMap = Hash.new
			illustrationModel = @@prdSAModelMap[product.object]
			premiumDetailsFacet = product.getPremiumDetailsFacet
			unless illustrationModel
				if premiumDetailsFacet
					premiumDetails = premiumDetailsFacet.OfflinePremiumDetailsList[0]
					if premiumDetails
						modelCd = premiumDetails.saModelCd
						if modelCd
							illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => modelCd})
							puts ">>>No model defined  with modelCd #{modelCd}" unless illustrationModel
							@@prdSAModelMap[product.object] = illustrationModel
						else
							puts ">>>No SA model defined for product #{product.productId}"
						end
					else
						puts ">>>No premium details defined for product #{product.productId}"
					end
				else
					puts ">>>No Premium details facet defined for product #{product.productId} "
				end
			end
			illusFacetsPerRider = Array.new if illusFacetsPerRider == nil
			illusFacetsPerFund = Array.new if illusFacetsPerFund == nil
			illusFacetComputedOnce = Array.new if illusFacetComputedOnce == nil
			illusFacetComputedEveryCycle = Array.new if illusFacetComputedEveryCycle == nil
			illusFacetComputedEveryCyclePerRate = Array.new if illusFacetComputedEveryCyclePerRate == nil
			illusFacetComputedOnceAtEnd = Array.new if illusFacetComputedOnceAtEnd == nil
			illusFacetComputedOnceAtEndPerRate = Array.new if illusFacetComputedOnceAtEndPerRate == nil
			if illustrationModel
				if "ONCE" == illustrationModel.computationFrequencyCd
					if policyYear > 1
						return saFieldResult
					end
				end

				#puts ">>>Evaluating model: #{illustrationModel.modelCd}"
				maxParseLevel = 1
				#method creation - start -> Changed by zeeshan to handle COMPUTEDDECISIONTBL copied from self.calculateIllustration
				illustrationModel.IllustrationFacetList.each do |ift|
					#Method creation start
					if ift.facetTypeCd == "INPUT"
						results.defineMethod("#{ift.computedElementName}_m","self.#{ift.inputElementSource}.#{ift.inputDataElement}")
						results.createAttr(ift.computedElementName)
					#elsif ift.facetTypeCd == "COMPUTEDFORMULA" or ift.facetTypeCd == "COMPUTEDLOOKUP" or ift.facetTypeCd == "COMPUTEDDECISIONTBL"
					elsif ift.computePerInstanceOf == 'FUND'
						#puts ">>>creating method for ift: #{ift.inspect}"
						quotation.getBaseProduct().QuotationProductInvestmentFundList.each do |qpif|
							# next unless qpif.allocationPerc and qpif.allocationPerc.to_f > 0
							next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0) #no point in continuing further if allocation percent doesn't exist or is zero
							illustrationModel.IllustrationRateList.each do |irt|
								#puts ">>>irt: #{irt.inspect}"
								if ift.expression
									newExp = ift.expression.clone
									#puts ">>>methodName: #{ift.computedElementName}#{qpif.fundCd}#{irt.id}_m oldExp: #{ift.expression}"
									data = newExp.scan(/\b(self.perFund_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perFund_",""))
										newString << qpif.fundCd
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|
									#puts ">>>methodName: #{ift.computedElementName}#{qpif.fundCd}#{irt.id}_m newExp:#{newExp}"
									results.defineMethod("#{ift.computedElementName}#{qpif.fundCd}#{irt.id}_m", newExp)
								end
								results.createAttr("#{ift.computedElementName}#{qpif.fundCd}#{irt.id}")
							end
						end
					else
						unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
							if ift.computePerInstanceOf == 'POLICY' or ift.computePerInstanceOf == 'RIDER'
								#results.defineMethod("#{ift.computedElementName}_m", ift.expression, ift.facetTypeCd=="COMPUTEDLOOKUP") unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								results.defineMethod("#{ift.computedElementName}_m", ift.expression) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								results.createAttr(ift.computedElementName)
							end
						else
							illustrationModel.IllustrationRateList.each do |irt|
								if ift.expression
									newExp = ift.expression
									data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perRate_", ""))
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|
									results.defineMethod("#{ift.computedElementName}#{irt.id}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								end
								results.createAttr("#{ift.computedElementName}#{irt.id}")
							end
						end
						#elsif ift.facetTypeCd == "COMPUTEDDECISIONTBL"
						#  unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
						#    results.createAttr(ift.computedElementName)
						#  else
						#    illustrationModel.IllustrationRateList.each do |irt|
						#      results.createAttr("#{ift.computedElementName}#{irt.id}")
						#    end
						#  end
					end
					#method creation end
					ift.parseLevel = 1 unless ift.parseLevel
					maxParseLevel = ift.parseLevel if maxParseLevel < ift.parseLevel and ift.computePerInstanceOf == "POLICY"

					#illusFacetsPerRider.push ift if ift.computePerInstanceOf == "RIDER"

					#illusFacetsPerFund.push ift if ift.computePerInstanceOf == "FUND"

					case ift.computePerInstanceOf
					when "RIDER"
						illusFacetsPerRider.push ift
					when "FUND"
						illusFacetsPerFund.push ift
					end

					if ift.outputDisplayTypeCd == "PARTOFHEADER" and ift.computationFreqCd=="ONCE"
						evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)
						evaluatedValue = Localization::LabelCache.instance.getLabel(evaluatedValue) if evaluatedValue.is_a? String
						resFieldForHeader.addFieldValue(nil, ift.computedElementName,evaluatedValue, ift.elementLabel, ift.computationOrder) if ift.outputDisplayTypeCd
					else
						#illusFacetComputedOnce.push ift if ift.computationFreqCd == "ONCE"
						#illusFacetComputedEveryCycle.push ift if ift.computationFreqCd == "EVERYCYCLE" or ift.computationFreqCd == "EVERYCYCLEFM"
						#illusFacetComputedEveryCyclePerRate.push ift if ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
						#illusFacetComputedOnceAtEnd.push ift if ift.computationFreqCd == "ONCEATEND"
						#illusFacetComputedOnceAtEndPerRate.push ift if ift.computationFreqCd == "ONCEATENDPERRATE"
						case ift.computationFreqCd
						when "ONCE"
							illusFacetComputedOnce.push ift
						when "EVERYCYCLE", "EVERYCYCLEFM"
							illusFacetComputedEveryCycle.push ift
						when "EVERYCYCLEPERRATE", "EVERYCYCLEPERRATEFM"
							illusFacetComputedEveryCyclePerRate.push ift
						when "ONCEATEND"
							illusFacetComputedOnceAtEnd.push ift
						when "ONCEATENDPERRATE"
							illusFacetComputedOnceAtEndPerRate.push ift
						end
					end
				end
				#        This is how it was originally
				#        illustrationModel.IllustrationFacetList.each do |ift|
				#          if ift.facetTypeCd == "INPUT"
				#            results.defineMethod("#{ift.computedElementName}_m","self.#{ift.inputElementSource}.#{ift.inputDataElement}")
				#            #results.createAttr(ift.computedElementName)
				#          elsif ift.facetTypeCd == "COMPUTEDFORMULA" #or ift.facetTypeCd == "INPUT"
				#            unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM"
				#              results.defineMethod("#{ift.computedElementName}_m", ift.expression)
				#              #results.createAttr(ift.computedElementName)
				#            else
				#              illustrationModel.IllustrationRateList.each do |irt|
				#                newExp = ift.expression
				#                data = newExp.scan(/\b(results.perRate_[a-zA-Z0-9]*)\b/)
				#                data.each do |match|
				#                  original = match[0].to_s
				#                  newString = String.new(original.gsub("perRate_", ""))
				#                  newString << irt.id.to_s
				#                  #puts "Old string: #{original} newString: #{newString}"
				#                  newExp = newExp.gsub(original, newString)
				#                  #puts "newExp: #{newExp}"
				#                end #data.each do |match|
				#                results.defineMethod("#{ift.computedElementName}#{irt.id}_m", newExp)
				#                #results.createAttr("#{ift.computedElementName}#{irt.id}")
				#              end
				#            end
				#          else
				#            #results.createAttr(ift.computedElementName)
				#          end
				#        end #illustrationModel.IllustrationFacetList.each do |ift|

				#method creation - end


				quotation.policyYear = policyYear
				saFieldResult = MobiSys::DataObjects::FieldResult.new
				saFieldResult.entityTypeCd = product.longName
				saFieldResult.addFieldValue(nil,"product_name", product.getLongName(),"Product name",0)
				quotationProduct.modalPremium = 0.0 unless quotationProduct.modalPremium
				quotationProduct.baseAnnualPremium = 0.0 unless quotationProduct.baseAnnualPremium
				premiumDetails = premiumDetailsFacet.OfflinePremiumDetailsList[0]
				illustrationModel.IllustrationFacetList.each do |illustrationFacet|
					#evaluatedValue = evaluateField(illustrationModel, illustrationFacet, quotation, variables, quotationProduct)
					evaluatedValue = evaluateField(illustrationModel, illustrationFacet, quotation, results, quotationProduct,nil)
					#puts ">>>Computing facet: #{illustrationFacet.computedElementName} evaluated value: #{evaluatedValue}"
					if illustrationFacet.inputDataElement and evaluatedValue
						begin
							# exp = "quotationProduct.#{illustrationFacet.inputDataElement} = evaluatedValue"
							# eval(exp)
							fieldName = illustrationFacet.inputDataElement
							isReqSetMethodInvoke = true
							if premiumDetails
								readOnlyFields = premiumDetails.inputDataElement
								if readOnlyFields.to_s != ""
									readOnlyFldList = readOnlyFields.to_s.split(',')
									unless readOnlyFldList.include? fieldName
										modelSource = Rho::RhoConfig.sources[quotationProduct.class.name.to_s]
										propertyExists = modelSource["schema"]["property"].has_key?(fieldName)
										object = propertyExists ? quotationProduct.send("#{fieldName}".to_sym) : nil
										if(!propertyExists || object.to_f != 0.0)
											isReqSetMethodInvoke = false
										end
									end
								end
							end
							if isReqSetMethodInvoke
								quotationProduct.send(illustrationFacet.mapSetter, evaluatedValue)
							end
							# quotationProduct.send("#{illustrationFacet.inputDataElement}=", evaluatedValue)
						rescue StandardError => boom
							puts ">>>StandardError occured in eval: #{boom}"
						end
					end
					saFieldResult.addFieldValue(nil,illustrationFacet.computedElementName, evaluatedValue,illustrationFacet.elementLabel,illustrationFacet.computationOrder)
					if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
						log(saFieldResult,illustrationFacet.computedElementName)
					end
 				end
			end
			#firstDTHash = nil
			saFieldResult
		end
		###################################################################################################


		def self.copyCalculatedAttributes(quotationProduct,policyProduct)
			if quotationProduct.baseSumAssured.to_s == 'NaN'
				quotationProduct.baseSumAssured = 0
			end
			if quotationProduct.baseAnnualPremium.to_s == 'NaN'
				quotationProduct.baseAnnualPremium = 0
			end
			if quotationProduct.modalPremium.to_s == 'NaN'
				quotationProduct.modalPremium = 0
			end
			if quotationProduct.extraPremium.to_s == 'NaN'
				quotationProduct.extraPremium = 0
			end
			if quotationProduct.computedmodalPremium.to_s == 'NaN'
				quotationProduct.computedmodalPremium = 0
			end

			puts ">>>Inside baseSumAssured: #########{quotationProduct.baseSumAssured.inspect}"
			puts ">>>Inside baseAnnualPremium: #########{quotationProduct.baseAnnualPremium.inspect}"
			puts ">>>Inside modalPremium: #########{quotationProduct.modalPremium.inspect}"
			puts ">>>Inside extraPremium: #########{quotationProduct.extraPremium.inspect}"
			puts ">>>Inside computedmodalPremium: #########{quotationProduct.computedmodalPremium.inspect}"
			policyProduct.baseSumAssured = quotationProduct.baseSumAssured.round(2) if quotationProduct.baseSumAssured.to_s!=""
			policyProduct.baseSumAssured = policyProduct.baseSumAssured.to_f if policyProduct.baseSumAssured.class.to_s == "BigDecimal"
			policyProduct.baseAnnualPremium = quotationProduct.baseAnnualPremium.round(2) if quotationProduct.baseAnnualPremium.to_s!=""
			policyProduct.baseAnnualPremium = policyProduct.baseAnnualPremium.to_f if policyProduct.baseAnnualPremium.class.to_s == "BigDecimal"
			policyProduct.annualizedPremium = quotationProduct.annualizedPremium.round(2) if quotationProduct.annualizedPremium.to_s!=""
			policyProduct.annualizedPremium = policyProduct.annualizedPremium.to_f if policyProduct.annualizedPremium.class.to_s == "BigDecimal"
			policyProduct.modalPremium = quotationProduct.modalPremium.round(2) if quotationProduct.modalPremium.to_s!=""
			policyProduct.modalPremium = policyProduct.modalPremium.to_f if policyProduct.modalPremium.class.to_s == "BigDecimal"
			policyProduct.extraPremium = quotationProduct.extraPremium.round(2) if quotationProduct.extraPremium.to_s!=""
			policyProduct.extraPremium = policyProduct.extraPremium.to_f if policyProduct.extraPremium.class.to_s == "BigDecimal"
			policyProduct.coi = quotationProduct.coi
			policyProduct.coi = policyProduct.coi.to_f if policyProduct.coi.class.to_s == "BigDecimal"
			policyProduct.productTerm = quotationProduct.productTerm
			policyProduct.productTerm = policyProduct.productTerm.to_f if policyProduct.productTerm.class.to_s == "BigDecimal"
			policyProduct.premiumPayingTerm = quotationProduct.premiumPayingTerm
			policyProduct.premiumPayingTerm = policyProduct.premiumPayingTerm.to_f if policyProduct.premiumPayingTerm.class.to_s == "BigDecimal"
			if policyProduct.PolicyProductInsuredList.first
				policyProduct.PolicyProductInsuredList.first.roleCd = quotationProduct.partyRoleCd
			end
			#policyProduct.annualizedPremium=quotationProduct.annualizedPremium
			#policyProduct.totAnnualizedPremium=quotationProduct.totAnnualizedPremium
			#policyProduct.totDiscount=quotationProduct.totDiscount
			policyProduct.serviceTax=quotationProduct.serviceTax
			policyProduct.serviceTax = policyProduct.serviceTax.to_f if policyProduct.serviceTax.class.to_s == "BigDecimal"
			#policyProduct.educationCess=quotationProduct.educationCess
			policyProduct.computedmodalPremium=quotationProduct.computedmodalPremium.round(2) if quotationProduct.computedmodalPremium.to_s!=""
			policyProduct.computedmodalPremium = policyProduct.computedmodalPremium.to_f if policyProduct.computedmodalPremium.class.to_s == "BigDecimal"
			#policyProduct.wopPremium=quotationProduct.wopPremium
			policyProduct.minTargetPremium=quotationProduct.minTargetPremium.round(2) if quotationProduct.minTargetPremium.to_s!=""
			policyProduct.minTargetPremium = policyProduct.minTargetPremium.to_f if policyProduct.minTargetPremium.class.to_s == "BigDecimal"
			policyProduct.maxTargetPremium=quotationProduct.maxTargetPremium.round(2) if quotationProduct.maxTargetPremium.to_s!=""
			policyProduct.maxTargetPremium = policyProduct.maxTargetPremium.to_f if policyProduct.maxTargetPremium.class.to_s == "BigDecimal"
			policyProduct.recommendedPremium=quotationProduct.recommendedPremium.round(2) if quotationProduct.recommendedPremium.to_s!=""
			policyProduct.recommendedPremium = policyProduct.recommendedPremium.to_f if policyProduct.recommendedPremium.class.to_s == "BigDecimal"
			policyProduct.unapliedPremium=quotationProduct.unapliedPremium.round(2) if quotationProduct.unapliedPremium.to_s!=""
			policyProduct.unapliedPremium = policyProduct.unapliedPremium.to_f if policyProduct.unapliedPremium.class.to_s == "BigDecimal"
			policyProduct.addtnField3 = quotationProduct.addtnField3
			policyProduct.addtnField3 = policyProduct.addtnField3.to_f if policyProduct.addtnField3.class.to_s == "BigDecimal"
		end
		###################################################################################################


		def self.calculateDiscount(quotation, quotationProduct)
			definitionTables = getProductDefinitionTableList("DISCOUNT", quotation, quotationProduct)
			discountList = Array.new
			definitionTables.each do |definitionTable|
				if definitionTable.rate != nil && quotationProduct.baseSumAssured != nil
					discount = definitionTable.rate.to_f * quotationProduct.baseSumAssured.to_f / 1000
					discountList.push(discount)
				end
			end
			return discountList
		end
		###################################################################################################


		def self.calculateCharge(quotation, quotationProduct)
			definitionTables = getProductDefinitionTableList("CHARGE", quotation, quotationProduct)
			chargeList = Array.new
			definitionTables.each do |definitionTable|
				if definitionTable.rate != nil && quotationProduct.baseAnnualPremium != nil
					if definitionTable.basisCd != nil && definitionTable.basisCd == "FLAT"
						charge = definitionTable.rate.to_f
					else
						charge = definitionTable.rate.to_f * quotationProduct.baseAnnualPremium.to_f / 100.0
					end
					chargeList.push(charge)
				end
			end
			return chargeList
		end
		###################################################################################################


		def self.calculatePDFAmount(quotation, quotationProduct)
			pdfDepositDT = getFacet(quotationProduct, "PDFDEPOSIT")

			pdfDepositAmount = 0
			rate = 0
			annualPremium = quotationProduct.baseAnnualPremium.to_f

			if pdfDepositDT != nil
				rate = pdfDepositDT.rate.to_f if pdfDepositDT.rate != nil

				(1..quotationProduct.premiumPayingTerm.to_i).each do |index|
					yearlyVal = ( (1 + rate/100.0)**-(index-1) ) * annualPremium
					pdfDepositAmount = pdfDepositAmount + yearlyVal
				end
				pdfDepositAmount = pdfDepositAmount - annualPremium

			end
			pdfDepositAmount = applyRoundingRule(pdfDepositAmount,  quotationProduct)

			return pdfDepositAmount
		end
		###################################################################################################


		def self.calculateAge(quotation, quotationProduct, party, errors, commencementDt=nil)
			product = nil
			if(quotationProduct.product != nil)
				product = quotationProduct.product
			elsif(quotationProduct.productSeq != nil)
				product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
			end

			polCommcDtBasis = ""
			dob = nil
			# default to last bday
			ageCalculationBasis = "LASTBIRTHDAY"
            companyFacetAgeCalculationBasis = CompanyFacet.find(
                :first,
                :conditions => {
                    { :name => 'facetCd' } => 'AGECALCULATIONBASIS'
                }
            )
            if companyFacetAgeCalculationBasis && companyFacetAgeCalculationBasis.actionValue.to_s != ""
                ageCalculationBasis = companyFacetAgeCalculationBasis.actionValue.to_s
            end
			dt = quotation.quotationDt # defaulting it to quotation issue date

			if product
				product.OfflineFacetList.each do |fd|
					next if fd.facetId == nil
					# check if the facet is overridden for a scheme/agent. If so then
					# it should match the scheme/agent of the quotation
					if (fd.schemeId != nil && fd.schemeId != quotation.schemeCd)
						next
					end
					if (fd.agentId != nil && fd.agentId != quotation.agentId)
						next
					end

					case fd.facetId.downcase
					when "SINGLELIFE".downcase
						singleLife = fd.OfflineSingleLifeList.first

						if (singleLife != nil)
							ageCalculationBasis = singleLife.ageCalculationBasisCd
						end
					when "JOINTLIFE".downcase
						jointLife = fd.OfflineJointLifeList.first

						if (jointLife != nil)
							ageCalculationBasis = jointLife.ageCalculationBasisCd
						end
					when "FAMILYFLOATER".downcase
						familyFloater = fd.OfflineFamilyFloaterList.first
						if (familyFloater != nil)
							ageCalculationBasis = familyFloater.ageCalculationBasisCd
						end
					end
				end

				prdIssueDt = product.getFacet('PRDISSUEDATE')
				if prdIssueDt
					dt = (prdIssueDt && !prdIssueDt.actionValue.nil?) ? prdIssueDt.actionValue : quotation.quotationDt
				end

				if dt.to_s == ""
					dt = getScreenDate(Time.new.to_s)
				end
				dt = commencementDt if (commencementDt.to_s != "" && ((prdIssueDt && prdIssueDt.actionValue.to_s == "") || !(prdIssueDt)))
			end

			if (party.dob != nil)
				dob = party.dob
			end

			entryAge = 0
			if (dob != nil && ageCalculationBasis != nil && dt != nil)
				entryAge = MobiSys::ProductUtil.getAge(dob, ageCalculationBasis, dt)
			end

			return entryAge
		end
		###################################################################################################


		def self.validateTerm(quotation,quotationProduct,msg,errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateTerm",$rhoconfig[:moduleForProductValidations])
			definitionTable= nil
			isOverrideAtRiderAssc=false
			fixedTermValues=nil
			if quotationProduct.productTypeCd=="RIDER"
				baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
				if baseProduct.product ==nil
					product = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
					baseProduct.product=product
				end
				begin
					riderAssoList = baseProduct.product.getRiderAssociationFacet.OfflineRiderAssociationList
				rescue
					riderAssoList = []
				end
				riderAssociation=nil
				riderAssoList.each do|riderAsso|
					if riderAsso.productId==quotationProduct.productId
						riderAssociation=riderAsso
						break
					end
				end
				if riderAssociation!=nil && riderAssociation.minMaxTermTableTypeMapSeq!=nil
					definitionTable = getProductDefinitionTable(riderAssociation.getMinMaxTermTableTypeMapSeq(), quotation, quotationProduct)
				end
				if definitionTable!=nil
					fixedTermValues=definitionTable.fixedTermValues
					isOverrideAtRiderAssc=true
				end
			end

			if fixedTermValues==nil
				minMaxTermTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTERM')
				definitionTable = getProductDefinitionTable(minMaxTermTTMS, quotation, quotationProduct)
				if definitionTable!=nil
					fixedTermValues=definitionTable.fixedTermValues()
				end
			end
			if fixedTermValues!=nil
				termList = fixedTermValues.split(",")
				termList.each do|termValue|
					if termValue.include? "-"
						termList = fixedTermValues.split("-")
						if quotationProduct.productTerm < termList[0] && quotationProduct.productTerm > termList[1]
							return isValid
						end
					else
						if termValue.to_i==quotationProduct.productTerm.to_i
							return isValid
						end
					end
				end
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "productTerm", "ERR_FIXEDTERMVALUES", ["productTerm", quotationProduct.productTerm, fixedTermValues, quotationProduct.planCode])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productTerm", "ERR_FIXEDTERMVALUES", "ERR_FIXEDTERMVALUES", nil, ["productTerm", quotationProduct.productTerm, fixedTermValues, quotationProduct.planCode])
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end

					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
				isValid=false
				return isValid
			end
			#validation for min max values
			if definitionTable==nil
				minMaxTermTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTERM')
				definitionTable = getProductDefinitionTable(minMaxTermTTMS, quotation, quotationProduct)
			end
			if definitionTable !=nil && !isOverrideAtRiderAssc
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				isValid = isValid and validateMinMaxValue(definitionTable, quotationProduct.productTerm, quotation, quotationProduct, "productTerm", 'productTerm', quotationProduct,tempErrorHash, nil, "MINMAXTERM")

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		#Deepali Singh : 13-08-2015 - Passing Time.now as first parameter and quotationDt as second
		def self.validateRiskCommDt(quotation, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotation.getBaseProduct,"validateRiskCommDt",$rhoconfig[:moduleForProductValidations])
			if(quotation.quotationDt != nil)
				baseProduct = quotation.getBaseProduct
				if baseProduct
					product = baseProduct.product
					if product and product.getFacetValue("BACKDATINGALLOWED") == "YES" and product.getFacet("BACKDATINGPERIOD")
						diffInMonths = getDifferenceInMonths(Time.now,MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						backDatingPeriod = product.getFacetValue("BACKDATINGPERIOD").to_i
						if(diffInMonths.to_i > backDatingPeriod.to_i)
							# ERR_RISKCOMMDT: "Difference between Risk commencement date and Todays Date cannot be more than {1} months, allowed on product {2}. Current difference is {3} months."
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end

							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "quotationDt", "ERR_RISKCOMMDT", [backDatingPeriod.to_s, product.longName.to_s, diffInMonths.to_i.abs])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-quotationDt", "ERR_RISKCOMMDT", "ERR_RISKCOMMDT", nil, [backDatingPeriod.to_s, product.longName.to_s, diffInMonths.to_i.abs])
							end

							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
										errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
										errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
									end
								end

								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
										errors[:PolicyProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][baseProduct.guid.to_sym].is_a?(Hash)
										errors[:PolicyProductDO][baseProduct.guid.to_sym] = errors[:PolicyProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
									end
								end
							end

							isValid = false
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.getDifferenceInMonths(screenDate1, screenDate2)
			return (screenDate1.year - screenDate2.year) * 12 + screenDate1.month - screenDate2.month + (screenDate1.day < screenDate2.day ? -1 : (screenDate1.day == screenDate2.day ? 0 : 1))
		end
		###################################################################################################


		def self.validatePPT(quotation,quotationProduct,msg,errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validatePPTerm",$rhoconfig[:moduleForProductValidations])
			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			if quotationProduct.productTerm!=nil && quotationProduct.productTerm.to_i < quotationProduct.premiumPayingTerm.to_i
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash,"premiumPayingTerm","ERR_COMPAREVALUES",["premiumPayingTerm",quotationProduct.premiumPayingTerm.to_s,"productTerm",quotationProduct.productTerm.to_s])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-premiumPayingTerm", "ERR_COMPAREVALUES", "ERR_COMPAREVALUES", nil, ["premiumPayingTerm",quotationProduct.premiumPayingTerm.to_s,"productTerm",quotationProduct.productTerm.to_s])
				end
			end
			minMaxPPTermTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXPPTERM')
			defTableDO=getProductDefinitionTable(minMaxPPTermTTMS, quotation, quotationProduct)
			if defTableDO !=nil && defTableDO.fixedPPTermValues !=nil
				if defTableDO.fixedPPTermValues and defTableDO.fixedPPTermValues != ""
					fixedPPTermValues = defTableDO.fixedPPTermValues.split(",")
					fixedPPTermValues.each do |term|
						if term.include? "-"
							splitFixedTerm2 = term.split("-");
							if quotationProduct.premiumPayingTerm >= splitFixedTerm2[0] && quotationProduct.premiumPayingTerm <= splitFixedTerm2[1]
								return isValid
							end
						elsif term.to_i == quotationProduct.premiumPayingTerm
							return isValid
						end
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "premiumPayingTerm", "ERR_FIXEDTERMVALUES", ["premiumPayingTerm", quotationProduct.premiumPayingTerm.to_s, fixedPPTermValues.to_s, quotationProduct.planCode])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-premiumPayingTerm", "ERR_FIXEDTERMVALUES", "ERR_FIXEDTERMVALUES", nil, ["premiumPayingTerm", quotationProduct.premiumPayingTerm.to_s, fixedPPTermValues.to_s, quotationProduct.planCode])
					end
				end
				return
			end
			if defTableDO !=nil
				isValid = isValid and validateMinMaxValue(defTableDO, quotationProduct.premiumPayingTerm, quotation, quotationProduct, "premiumPayingTerm", 'premiumPayingTerm', quotationProduct, tempErrorHash, nil, "MINMAXPPTERM")
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if $rhoconfig[:moduleForProductValidations] == "Quotation"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end

				if $rhoconfig[:moduleForProductValidations] == "Policy"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end
			end

			return isValid
		end
		###################################################################################################


		def self.validatePolicy(quotation,policy,msg, errors)
			$isValidatePolicy = true
			MobiSys::ProductUtil.resetCache()
			puts ">>>Inside loop: Reach Validate Policy#########"
			riderWopPpd = nil
			quotePartyList=quotation.QuotationPartyList
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct
					if(quotation.proposerLASame!="COPYFROMINSURED" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)|| (quotation.proposerLASame!="COPYFROMINSURED" && quotationProduct.partyRoleCd == "PRIMARY")
						quotParty = quotation.getPartyByRole("PRIMARY")
					elsif quotation.proposerLASame!="COPYFROMINSURED" && quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="PROPOSER"
						quotParty = quotation.getPartyByRole("PROPOSER")
					elsif (quotation.proposerLASame=="COPYFROMINSURED" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)  || (quotation.proposerLASame=="COPYFROMINSURED" && (quotationProduct.partyRoleCd=="PRIMARY"  || quotationProduct.partyRoleCd=="PROPOSER"))
						quotParty = quotation.getPartyByRole("PROPOSER")
					else
						quotParty = quotation.getPartyByRole("PRIMARY")
					end
				end

				quotationProduct.combinedEntryAge = quotParty.age if quotParty and quotParty.age and quotParty.age!=""

				if quotationProduct.productId ==nil ||quotationProduct.productId =="" ||quotationProduct.productSeq ==nil
					next
				end
				puts ">>>Inside loop: #{quotationProduct.productId} #{quotationProduct.selected}"
				#if quotationProduct.selected == "on"
					isWOP = false
					product=nil

					if quotationProduct.product ==nil
						puts ">>>Inside load product"
						product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
						puts ">>>>Loaded product: #{product.inspect}"
						quotationProduct.product=product
					end
					otherDetailsFacet = quotationProduct.product.getOtherDetailsFacet.OfflineOtherDetailsList[0] if quotationProduct.product.getOtherDetailsFacet
					if otherDetailsFacet != nil && otherDetailsFacet.isWOPFl != nil && otherDetailsFacet.isWOPFl == "YES"
						isWOP = true
						riderWopPpd = quotationProduct
					end

					if !isWOP
						isValid = validateProduct(quotation, quotationProduct,quotePartyList, msg, errors) && isValid
					end
				#end
				policy.PolicyProductList.each do |policyProduct|
					if policyProduct.object==quotationProduct.holderRefGuid
						copyCalculatedAttributes(quotationProduct,policyProduct)
						break
					end
				end
			end

			if riderWopPpd != nil
				#isValid = validateProduct(quotation,quotePartyList,riderWopPpd,msg, errors) && isValid
				isValid = validateProduct(quotation,riderWopPpd,quotePartyList,msg, errors) && isValid
				policy.PolicyProductList.each do |policyProduct|
					if policyProduct.object==riderWopPpd.holderRefGuid
						copyCalculatedAttributes(riderWopPpd,policyProduct)
						break
					end
				end
			end
			baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
			isValid=validateRidersSA(quotation,msg,errors) && isValid
			#Deepali Singh - 12/10/2016: customeRiderRelationValidation & calculateAndValidateOtherPremium method is specific to FWD Indonesia implementation hence removing it from product code.
			# isValid=customeRiderRelationValidation(quotation,msg,errors)&& isValid
			# facetValue = baseProduct.product.getFacetValue('OTHERPREMIUMSREQUIRED')
			# isValid=calculateAndValidateOtherPremium(quotation,baseProduct,msg,errors) && isValid if facetValue and facetValue == 'YES'
			policy.PolicyProductList.each do |policyProduct|
				if policyProduct.object==baseProduct.holderRefGuid
					copyCalculatedAttributes(baseProduct,policyProduct)
					break
				end
			end

			validatePortfolioModel(quotation,msg,errors)
			MobiSys::ProductUtil.resetCache()
			$isValidatePolicy = nil
			return isValid
		end
		###################################################################################################


		def self.validate(quotation, msg, errors, individualQuotProd=nil)
			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			MobiSys::ProductUtil.resetCache()

			isValid = true
			quotePartyList=quotation.QuotationPartyList
			if $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
			# riders = MobiSys::QuotationBO.getRiders(quotation)
			# setting product for baseproduct
			product = nil
			if baseProduct.productId.to_s != ""
				if baseProduct.product.to_s == ''
					product = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
					baseProduct.product = product
				end
			end
			riderWopPpd = []
			quotation.QuotationProductList.each do |quotationProduct|
				next if quotationProduct.removed and quotationProduct.removed != ""
				if (quotationProduct.productId.to_s == '' || quotationProduct.productSeq.to_s == '')
					next
				end
				if (individualQuotProd && individualQuotProd.productSeq.to_s == quotationProduct.productSeq.to_s && individualQuotProd.insuredPartyRefGuid.to_s == quotationProduct.insuredPartyRefGuid.to_s) || individualQuotProd == nil
					isWOP = false
					product = nil

					if quotationProduct.product == nil
						puts ">>>Loading product with productId: #{quotationProduct.productId} productSeq: #{quotationProduct.productSeq}"
						product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
						puts ">>>Found product: #{product.inspect}"
						quotationProduct.product = product
					end

					if quotationProduct.product && !quotationProduct.product.getOtherDetailsFacet.nil?
						otherDetailsFacet = quotationProduct.product.getOtherDetailsFacet.OfflineOtherDetailsList[0]
						if otherDetailsFacet != nil && otherDetailsFacet.isWOPFl != nil && otherDetailsFacet.isWOPFl == "YES"
							isWOP = true
							riderWopPpd.push(quotationProduct)
						end
					end

					if individualQuotProd && !isWOP
						isValid = validateProduct(quotation, quotationProduct,quotePartyList, msg, errors, true) && isValid
					elsif !isWOP
						isValid = validateProduct(quotation, quotationProduct,quotePartyList, msg, errors) && isValid
					end
					break if individualQuotProd
				end
			end

			if riderWopPpd.size > 0
				riderWopPpd.each do |wopRider|
					isValid = validateProduct(quotation, wopRider, quotePartyList, msg, errors) && isValid
				end
			end

        	if individualQuotProd
				isValid = validateRidersSA(quotation,msg,errors,individualQuotProd) && isValid
			else
				isValid = validateRidersSA(quotation,msg,errors) && isValid
			end
			#Deepali Singh - 08/08/2016: customeRiderRelationValidation & calculateAndValidateOtherPremium method is specific to FWD Indonesia implementation hence removing it from product code.
			# isValid=customeRiderRelationValidation(quotation,msg,errors)&& isValid
			# facetValue = baseProduct.product.getFacetValue('OTHERPREMIUMSREQUIRED')
			# isValid=calculateAndValidateOtherPremium(quotation,baseProduct,msg,errors) && isValid if facetValue and facetValue == 'YES'
			puts "product errors: #{errors.to_json}"
			MobiSys::ProductUtil.resetCache()
			return isValid
		end
		###################################################################################################


		def self.validatePortfolioModel(quotation, msg, errors)
			quotationProduct = quotation.getBaseProduct
			return true unless MobiSys::Validation.validateMethodCall(quotationProduct,"validatePortfolioModel",$rhoconfig[:moduleForProductValidations])
			fundModelDerivationTTMS = quotationProduct.product.getTableTypeMappingSeq('FUNDMODELDERIVATION')
			definitionTable = getProductDefinitionTable(fundModelDerivationTTMS, quotation, quotationProduct)
			if definitionTable
				isValidPortfolioModelCd = false
				splitPortfolioModelCd = definitionTable.outputAction.split(",");
				splitPortfolioModelCd.each do |portfolioModelCd|
					if portfolioModelCd == quotationProduct.portfolioModelCd
						isValidPortfolioModelCd = true
						break
					end
				end
				if !isValidPortfolioModelCd
					selectedModel = Model.find(
						:first,
						:conditions=>{
							{:name=>'modelCd'}=>quotationProduct.portfolioModelCd
							},
							:select=>['modelDesc']
							)
					modelName = selectedModel ? selectedModel.modelDesc.to_s : ""
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end

					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "portfolioModelCd", "ERR_INVALID",[MobiSys::BrowserHelper.getLabel("portfolioModelCd") << " - " << modelName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-portfolioModelCd", "ERR_INVALID", "ERR_INVALID", nil, [MobiSys::BrowserHelper.getLabel("portfolioModelCd") << " - " << modelName])
					end

					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
								errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
								errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
							end
						end

						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
								errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
								errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
		end
		###################################################################################################


		# Method to validate party crossover in case of proposal
		def self.validateAgeCrossover(quotation, quotationParty)
			validContext = MobiSys::Validation.validateMethodCall(quotationParty,"validateAgeCrossover",$rhoconfig[:moduleForProductValidations])
			currentDate = nil
			currentDate = getScreenDate(Time.new.to_s) if quotation.isBackdatedFl.to_s != "YES" && $rhoconfig[:moduleForProductValidations] == "Policy"
			newAge = calculateAge(quotation, quotation.getBaseProduct, quotationParty, nil, currentDate).split("|")[0]
			if validContext
				if newAge.to_i != quotationParty.age.to_i
					return false
				else
					quotationParty.age = newAge.to_i
					return true
				end
			else
				quotationParty.age = newAge.to_i
				return true
			end
		end
		###################################################################################################


		def self.validateProduct(quotation, quotationProduct,quotePartyList,msg, errors, validateSingleRider=false)
			isValid = true
			if quotation != nil && quotationProduct != nil
				if (quotationProduct.productSeq != nil and quotationProduct.productSeq != "") or (quotationProduct.productId != nil and quotationProduct.productId != "")
					if quotationProduct.product == nil
						quotationProduct.product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
					end

					#isValid = validateProductLaunch(quotationProduct,msg,errors) && isValid
					@offlineApplicationEnvironment = OfflineApplication.loadObject(
						:first,
						:conditions => {
							{ :name => 'PROPERTY' } => 'ENVIRONMENT'})

					if @offlineApplicationEnvironment != nil
						if  @offlineApplicationEnvironment.value == nil
							@offlineApplicationEnvironment.value = "PRODUCTION"
						end
					else
						@offlineApplicationEnvironment = OfflineApplication.new
						@offlineApplicationEnvironment.property = 'ENVIRONMENT'
						@offlineApplicationEnvironment.value = "PRODUCTION"
					end

					if  @offlineApplicationEnvironment.value != "UAT"
						isValid = validateProductLaunchDate(quotation,quotationProduct,msg,errors) && isValid
					end
					##############################################
					# Eligibility limits
					##############################################

					# Compute party ages and validate crossover
					begin
						quotation.quotationDt = getScreenDate(quotation.quotationDt.to_s)
						isAgeValid = true
						quotation.QuotationPartyList.each do |quotationParty|
							if quotationParty.dob.to_s != ""
								quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
								unless validateAgeCrossover(quotation, quotationParty)
									isAgeValid = false
								end
								quotationParty.dob = getDBDate(quotationParty.dob.to_s)
							end
						end
						quotation.quotationDt = getDBDate(quotation.quotationDt.to_s)
						if !isAgeValid
							unless $ageShowPopup
			    				Alert.show_popup({
					                :message => getLabelValue('ERR_AGE_CHANGED'),
					                :title => getLabelValue("error"),
					                :buttons => ["OK"]
					            })
					            $ageShowPopup = true
			    			end
				            unless $rhoconfig[:TABFEATUREREQD]
				            	tempErrorHash = {}
								MobiSys::CommonUtil.addErrors(tempErrorHash, "quotationDt", "ERR_AGE_CHANGED")
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-quotationDt", "ERR_AGE_CHANGED", "ERR_AGE_CHANGED", nil)
							end
				            return isAgeValid
		    			end
					rescue Exception => e
						Rho::Log.error("Error in age computation in ProductBO--->#{e}\n#{e.backtrace}", "PRODUCTBO")
					end

					#to get insured party
					party = quotation.getParty(quotationProduct)

					if party !=nil
						minMaxEntryAgeFacet = quotationProduct.product.getFacet("MINMAXENTRYAGE")
						if party.age != nil && minMaxEntryAgeFacet
							isValid = validateEntryAge(quotation, quotationProduct, msg, errors, party) && isValid
						end
						minMaxExpiryAgeTTMS = quotationProduct.product.getTableTypeMappingSeq("MINMAXEXPIRYAGE")
						if party.age != nil && quotationProduct.productTerm != nil && minMaxExpiryAgeTTMS
							minMaxExpiryAge = getProductDefinitionTable(minMaxExpiryAgeTTMS, quotation, quotationProduct)
							if minMaxExpiryAge != nil
								isValid = validateExpiryAge(quotation, quotationProduct, minMaxExpiryAge, msg, errors,party) && isValid
							end
						end
					end

					if quotationProduct.productTypeCd=="PLAN"
						isValid = validateRelations(quotation, quotationProduct,msg, errors,quotePartyList) && isValid
					end
					#validating joint's Age'
					jointLife = quotation.getPartyByRole('JOINT')
					jointAgeDefnTTMS = quotationProduct.product.getTableTypeMappingSeq('JOINTAGEDEFINITION')
					if jointLife and jointLife.age != nil && jointAgeDefnTTMS && quotationProduct.productTypeCd=="PLAN"
						minMaxJointLAEntryAge = getProductDefinitionTable(jointAgeDefnTTMS, quotation, quotationProduct)
						if minMaxJointLAEntryAge != nil
							isValid = validateJointEntryAge(quotation, quotationProduct, minMaxJointLAEntryAge, msg, errors, jointLife) && isValid
						end
					end

					insuredLife = quotation.getMainInsured(quotation.getBaseProduct)
					insuredAgeDefnTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXMAININSUREDAGE')
					if insuredLife and insuredLife.age != nil and insuredAgeDefnTTMS
						isValid = validateEntryAge(quotation, quotationProduct, msg, errors, insuredLife, 'MINMAXMAININSUREDAGE') && isValid
					end

					#validating proposer's Age'
					minMaxEntryAgeTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXENTRYAGE')
					if quotation.getPartyByRole('PROPOSER')!=nil && quotation.getPartyByRole('PROPOSER').age.to_s != '' && minMaxEntryAgeTTMS && quotationProduct.productTypeCd=="PLAN"
						originalPartyRole=quotationProduct.partyRoleCd
						quotationProduct.partyRoleCd="PROPOSER"
						minMaxProposerEnrtyAge = getProductDefinitionTable(minMaxEntryAgeTTMS, quotation, quotationProduct, quotation.getPartyByRole('PROPOSER'))
						if minMaxProposerEnrtyAge != nil
							isValid = validateProposerEntryAge(quotation, quotationProduct, minMaxProposerEnrtyAge, msg, errors) && isValid
						end
						quotationProduct.partyRoleCd=originalPartyRole
					end

					calculateTerm(quotation, quotationProduct)

					if quotationProduct.productTerm != nil
						isValid=validateTerm(quotation, quotationProduct,msg, errors)
					end

					if quotationProduct.premiumPayingTerm !=nil
						isValid=validatePPT(quotation,quotationProduct,msg,errors) && isValid
					end

					if quotationProduct.capturedPremiumAmt !=nil
						minMaxEnterablePremiumTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXENTERABLEPREMIUM')
						if minMaxEnterablePremiumTTMS
							minMaxEnterablePremium = getProductDefinitionTable(minMaxEnterablePremiumTTMS, quotation, quotationProduct)
							if minMaxEnterablePremium !=nil
								isValid=validateEnterablePremium(quotation,quotationProduct,minMaxEnterablePremium,msg,errors) && isValid
							end
						end
					end

					minMaxSupLivesTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXSUPPLEMENTARYLIVES')
					if minMaxSupLivesTTMS
						minMaxSuppleLives = getProductDefinitionTable(minMaxSupLivesTTMS, quotation, quotationProduct)
						if minMaxSuppleLives !=nil
							isValid=validateSupplementaryLives(quotation,quotationProduct,minMaxSuppleLives,msg,errors) && isValid
						end
					end
					isValid=validateLoading(quotation,quotationProduct,msg,errors,party) && isValid
					isValid=validateLoadingDuration(quotation,quotationProduct,msg,errors) && isValid

					if quotationProduct.productTypeCd=="PLAN"
						#isValid=validateDiscount(quotation,quotationProduct,msg,errors) && isValid
						isValid=validateWithdrawal(quotation,quotationProduct,msg,errors) && isValid
						isValid=validateTopup(quotation,quotationProduct,msg,errors, party) && isValid
						isValid=otherTopUpValidation(quotation,quotationProduct,msg,errors) && isValid
						isValid=validateTransfer(quotation, quotationProduct, party, errors) && isValid
						isValid=regularTopUpMaxValidation(quotation, quotationProduct,msg, errors) && isValid

						isValid=validateMinMaxpdfAmount(quotation,quotationProduct,msg,errors) && isValid
						isValid=validateMinMaxpdfPeriod(quotation,quotationProduct,msg,errors) && isValid
					end

					##############################################
					# Validate riders here TBD
					##############################################



					##############################################
					# Other product validations here
					##############################################

					##############################################
					# Payment frequency
					##############################################
					if quotationProduct.paymentFrequencyCd != nil and quotationProduct.product != nil
						premiumDetailsDT = quotationProduct.product.getPremiumDetailsFacet()
						if premiumDetailsDT != nil and premiumDetailsDT.OfflinePremiumDetailsList[0] != nil
							isValid = validatePaymentFrequency(quotation, quotationProduct, premiumDetailsDT.OfflinePremiumDetailsList[0], msg, errors) && isValid
						end
					end

					##############################################
					# Funds
					##############################################
					# if quotationProduct.productFamilyCd == "UNITLINKED" && quotationProduct.productTypeCd=="PLAN"
					if quotationProduct.productTypeCd=="PLAN"
						fundAllocationDT = quotationProduct.product.getFacet("FUNDSREQUIRED")
						if fundAllocationDT && fundAllocationDT.actionValue == "YES"
							isValid = validateFundAllocation(quotation, quotationProduct, fundAllocationDT, msg, errors) && isValid
						end
					end

					##############################################
					# Calculate model based SA and premium
					##############################################
					puts ">>>Before calculating model based premium and SA"
					# fix not a solution
					flag = false # This flag is for deleting Sum Assured Validations
					flag = true if quotationProduct.baseSumAssured.to_s==""
					if quotationProduct.productId != nil && quotationProduct.productId != ""
						if quotationProduct.product == nil
							product = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
						else
							product = quotationProduct.product
						end
						puts ">>#{product}"
						puts ">>>Found product with id: #{product.productId}"
						otherDetails = product.getOtherDetailsFacet.OfflineOtherDetailsList[0] if !product.getOtherDetailsFacet.nil?
						puts ">>>Found offlineOtherDetails: #{otherDetails}"
						isWOP = false
						isWOP = true if otherDetails and otherDetails.isWOPFl == "YES"
						puts ">>>Before calculating WOP sum assured flag: #{isWOP}"
						premiumDetails = product.getPremiumDetailsFacet.OfflinePremiumDetailsList[0] if product.getPremiumDetailsFacet
						calculateWOPSumAssured(quotation,quotationProduct) if isWOP
            			wopPremiumField = product.getFacetValue('WOPPREMIUMCOMPONENT')
						calculateWOPPremium(quotation,quotationProduct,wopPremiumField) if isWOP && wopPremiumField.to_s != ""
						premiumSAFlagBasedComputation(quotationProduct, quotation,premiumDetails, isWOP) if isWOP && premiumDetails
						calculateRiderValues(quotation,quotationProduct,1) if isWOP
						puts ">>>After calculating model based premium and SA"

						if premiumDetails
							#If sum assured is captured, calculate premium
							# if premiumDetails.premiumSAFl and premiumDetails.premiumSAFl == "SA"
							#   calculateModelBasedPremium(1, quotation, quotationProduct, product)
							# elsif premiumDetails.premiumSAFl and (premiumDetails.premiumSAFl == "PREMIUM" or premiumDetails.premiumSAFl == "PREMIUM")
							#   unless isWOP
							#     calculateModelBasedSA(1, quotation, quotationProduct, product)
							#     calculateModelBasedPremium(1, quotation, quotationProduct, product) if premiumDetails.premiumModelCd
							#   end
							# elsif premiumDetails.premiumSAFl and premiumDetails.premiumSAFl == "DUAL"
							#   calculateModelBasedSA(1, quotation, quotationProduct, product) if quotationProduct.baseSumAssured and quotationProduct.baseSumAssured == 0
							#   calculateModelBasedPremium(1, quotation, quotationProduct, product) if premiumDetails.premiumModelCd
							# elsif premiumDetails.premiumSAFl and (premiumDetails.premiumSAFl == "ANNUALINCOME" or premiumDetails.premiumSAFl == "MONTHLYINCOME")
							#   calculateModelBasedSA(1, quotation, quotationProduct, product) if premiumDetails.saModelCd
							#   calculateModelBasedPremium(1, quotation, quotationProduct, product) if premiumDetails.premiumModelCd
							# elsif premiumDetails.premiumSAFl and premiumDetails.premiumSAFl == "COMPUTEDSA"
							#    calculateModelBasedSA(1, quotation, quotationProduct, product) if premiumDetails.saModelCd
							#    premiumfieldResult = calculateModelBasedPremium(1, quotation, quotationProduct, product) if premiumDetails.premiumModelCd
							# end

							if quotationProduct.productTypeCd == "PLAN" || quotationProduct.productTypeCd == "PLANMULTI"
								premiumSAFlagBasedComputation(quotationProduct, quotation,premiumDetails, isWOP)
							end
							if quotationProduct.pdfOption == "YES" and quotationProduct.productTypeCd == "PLAN"
								#TODO calculatePDFOption
							end
						end
					end
					flag = (flag && quotationProduct.baseSumAssured.to_s!="")? true : false
					errors.delete("baseSumAssured") if flag # if sumassured is obtained by the above calculations and was previously empty delete its error
					minMaxSumAssuredTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXSUMASSURED')
					if quotationProduct.baseSumAssured != nil && (minMaxSumAssuredTTMS || quotationProduct.product.getFacetValue("SAMULTIPLEOFENTERABLEPREMIUM")=="YES" )
						minMaxSumAssured = getProductDefinitionTable(minMaxSumAssuredTTMS, quotation, quotationProduct)
						isValid = validateSA(quotation, quotationProduct, minMaxSumAssured, msg, errors) && isValid
					end

					minMaxModalPremiumTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXMODALPREMIUM')
					if quotationProduct.modalPremium != nil && minMaxModalPremiumTTMS
						minMaxModalPremium = getProductDefinitionTable(minMaxModalPremiumTTMS, quotation, quotationProduct)
						if minMaxModalPremium != nil
							isValid = validateModalPremium(quotation, quotationProduct, minMaxModalPremium, msg, errors) && isValid
						end
					end
					isValid = validateTotalModalPremium(quotation, quotationProduct, msg, errors) && isValid

					minMaxPremiumTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXPREMIUM')
					if quotationProduct.baseAnnualPremium != nil && minMaxPremiumTTMS
						minMaxPremium = getProductDefinitionTable(minMaxPremiumTTMS, quotation, quotationProduct)
						if minMaxPremium != nil
							isValid = validateAnnualPremium(quotation, quotationProduct, minMaxPremium, msg, errors) && isValid
						end
					end

					if quotationProduct.productTypeCd == "PLAN"
						riderAssociation=quotationProduct.product.getRiderAssociationFacet
						if riderAssociation!=nil
							isValid = validateRiders(quotation, quotationProduct, riderAssociation.OfflineRiderAssociationList, msg, errors) && isValid
						end
						isValid = validateRiskCommDt(quotation, errors) && isValid
						riderGroupDefinition=quotationProduct.product.getFacet("RIDERGROUPDEFINITION")
						if riderGroupDefinition != nil && riderAssociation != nil
							isValid = validateRiderGroupDefinition(quotation, quotationProduct, riderAssociation.OfflineRiderAssociationList, riderGroupDefinition.OfflineRiderGroupDefinitionList,quotePartyList,msg, errors) && isValid
						end
					# elsif quotationProduct.productTypeCd == "RIDER"
					#   calculateRiderValues(quotation, quotationProduct)
					end
					if validateSingleRider
						riderAssociation = quotation.getBaseProduct.product.getRiderAssociationFacet
						if riderAssociation!=nil
							isValid = validateRiders(quotation, quotation.getBaseProduct, riderAssociation.OfflineRiderAssociationList, msg, errors, quotationProduct) && isValid
						end
						isValid = validateRiskCommDt(quotation, errors) && isValid
						riderGroupDefinition = quotation.getBaseProduct.product.getFacet("RIDERGROUPDEFINITION")
						if riderGroupDefinition != nil && riderAssociation != nil
							isValid = validateRiderGroupDefinition(quotation, quotation.getBaseProduct, riderAssociation.OfflineRiderAssociationList, riderGroupDefinition.OfflineRiderGroupDefinitionList,quotePartyList,msg, errors) && isValid
						end
					end

					# should be called after SA Calculation
					isValid=validateSAMultiple(quotation,quotationProduct,msg,errors)&& isValid
				# else
				# 	if (quotationProduct.productTypeCd=="RIDER" and quotationProduct.removed == "") || quotationProduct.productTypeCd == "PLAN"
				# 		if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				# 			tempErrorHash= Hash.new
				# 		else
				# 			tempErrorHash = errors
				# 		end
				# 		MobiSys::CommonUtil.addErrors(tempErrorHash, "productSeq", "MISSINGPRODUCTSEQ")
				# 		MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productSeq", "MISSINGPRODUCTSEQ", "MISSINGPRODUCTSEQ", nil)

				# 		if $rhoconfig[:moduleForProductValidations] == "Quotation"
				# 			if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
				# 				errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
				# 				errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
				# 				errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
				# 			end
				# 		end

				# 		if $rhoconfig[:moduleForProductValidations] == "Policy"
				# 			if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
				# 				errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
				# 				errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
				# 				errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
				# 			end
				# 		end

				# 		isValid = false
				# 	end

					additionalModelSetFacet = quotationProduct.product.getFacet("ADDTNLMODELSET")
					if !defined?($isValidatePolicy) && additionalModelSetFacet != nil && additionalModelSetFacet.actionValue.to_s != ""
						policyModelSet = PolicyUtil::PolicyModelSet.new
						policy = MobiSys::PolicyBO.convertToPolicy(quotation)
						if (quotation.proposerLASame.to_s == 'YES' || quotation.proposerLASame.to_s == 'COPYFROMINSURED') && quotationProduct.partyRoleCd.to_s == 'PRIMARY'
							policyParty = quotation.getPartyByRole("PROPOSER")
						else
							policyParty = quotation.getParty(quotationProduct)
						end
						policyParty.policyYear = quotation.policyYear
						policyProduct = policy.getBaseProduct if policy

						quotationIO = MobiSys::IO::QuotationIO.new
		        		quotationIO.baseDO = quotation.cloneObject
		        		quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)

						policyModelSet.execute(policy, policyProduct, policyParty, additionalModelSetFacet.actionValue, quotationIO)
						MobiSys::PolicyBO.copyToQuotation(policy, quotation)
					end
					
					polAdditionalModelSetFacet = quotationProduct.product.getFacet("POLADDTNLMODELSET")
					if polAdditionalModelSetFacet != nil && polAdditionalModelSetFacet.actionValue.to_s != ""
						policyModelSet = PolicyUtil::PolicyModelSet.new
						policy = MobiSys::PolicyBO.convertToPolicy(quotation)
						if (quotation.proposerLASame.to_s == 'YES' || quotation.proposerLASame.to_s == 'COPYFROMINSURED') && quotationProduct.partyRoleCd.to_s == 'PRIMARY'
							policyParty = quotation.getPartyByRole("PROPOSER")
						else
							policyParty = quotation.getParty(quotationProduct)
						end
						policyParty.policyYear = quotation.policyYear
						policyProduct = policy.getBaseProduct if policy

						quotationIO = MobiSys::IO::QuotationIO.new
		        		quotationIO.baseDO = quotation.cloneObject
		        		quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)

						policyModelSet.execute(policy, policyProduct, policyParty, polAdditionalModelSetFacet.actionValue, quotationIO)
						MobiSys::PolicyBO.copyToQuotation(policy, quotation)
					end

					#Added to validate prdmetadatado minoccurs .. Adding for Both Plan and Riders
					# if quotationProduct.productTypeCd == "PLAN"
						validatePrdFieldMetadata(quotation,quotationProduct)
					# end
				end
			end

			return isValid
		end
		###################################################################################################

		def self.validatePrdFieldMetadata(quotation,quotationProduct)
			if $productMetaDataCache && $productMetaDataCache[quotationProduct.productSeq.to_s]
				$productMetaDataCache[quotationProduct.productSeq.to_s].each do |field,prdMtdtHash|
					if prdMtdtHash
						prdMtdtHash.each do |propertyCd,metaDataDOArr|
							metaDataDO = metaDataDOArr[0] if metaDataDOArr.size > 0
				            if(metaDataDO && propertyCd.to_s == "MINOCCURS" && metaDataDO.propertyValue.to_s == "1")
								tabId = quotationProduct.productTypeCd.to_s == "PLAN" ? "tab_plan": "tab_rider"
				                object = quotationProduct.send field.to_sym
                        		fieldLabel = field.to_s
                        		classToFind = "#{quotationProduct.class.name}DO"
                        		metadataCd = classToFind+".#{field}".to_s
                        		currentApplicableContexts = []
                        		if $contextMasterCache.has_key?(classToFind.to_sym)
	                        		if !Object.const_get(quotationProduct.class.name).instance_methods(false).include?(:isParentExtendingContext) || (Object.const_get(quotationProduct.class.name).instance_methods(false).include?(:isParentExtendingContext) && !quotationProduct.isParentExtendingContext )
										contextMasterList = $contextMasterCache[classToFind.to_sym]
										contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,quotationProduct)
										currentApplicableContexts.push(contextMasterGeneratedArray)
									end
								end
                        		if $uiMetaDataCache && $uiMetaDataCache.has_key?(classToFind.to_sym)
                        			if $uiMetaDataCache[classToFind.to_sym].has_key?(metadataCd.to_sym)
										uiMetaDataDOList = $uiMetaDataCache[classToFind.to_sym][metadataCd.to_sym]
										labelMt = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, currentApplicableContexts.flatten)
										fieldLabel = (labelMt == nil ? field.to_s : labelMt.propertyValue.to_s)
									end
								end

				                if(object == nil || object.to_s.strip.length == 0 || object.to_s == "")
				                    # registerException(InsExceptionConstants.ERR_MANDATORY , new String[] { metaDataDO.getFieldCd() }, policyProduct, null, null,metaDataDO.getFieldCd());

				                    exceptionCd = metaDataDO.errLabelKey.to_s != "" ? metaDataDO.errLabelKey.to_s : "ERR_MANDATORY"
									MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-#{field}", exceptionCd, exceptionCd, tabId,[fieldLabel.to_s])
				                end
				            end
			            end
			        end
		        end
	        end
	    end

		###################################################################################################

		def self.validateTransfer(quotation, quotationProduct, party, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateTransfer",$rhoconfig[:moduleForProductValidations])
			definitionTable = nil
			topupList = quotation.getTopupByType("TRANSFERTOPUP")
			minMaxTransferContriTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTRANSFERCONTRIBUTION')
			orgPolicyYear = party.policyYear
			if minMaxTransferContriTTMS
				quotation.field21 = "TRANSFERTOPUP"
				topupList.each do |ptup|
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					if(ptup.policyYearFrom != nil and ptup.policyYearTo != nil)
						(ptup.policyYearFrom .. ptup.policyYearTo).each do |i|
							party.policyYear = i
							definitionTable = getProductDefinitionTable(minMaxTransferContriTTMS, quotation, quotationProduct)
							if (definitionTable != nil and ptup.topUpAmount != nil)
								if (definitionTable.minValue != nil and ptup.topUpAmount < definitionTable.minValue)
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MINTOPUPAMT")
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MINTOPUPAMT", "MINTOPUPAMT", nil)
									end
									isValid = false
									party.policyYear = orgPolicyYear
									break
								elsif (definitionTable.maxValue != nil and ptup.topUpAmount > definitionTable.maxValue)
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MAXTOPUPAMT")
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MAXTOPUPAMT", "MAXTOPUPAMT", nil)
									end
									isValid = false
									party.policyYear = orgPolicyYear
									break
								end
							end
						end
					elsif(ptup.policyYearFrom != nil)
						party.policyYear = ptup.policyYearFrom
						definitionTable = getProductDefinitionTable(minMaxTransferContriTTMS, quotation, quotationProduct)
						if (definitionTable != nil and ptup.topUpAmount != nil)
							if (definitionTable.minValue != nil and ptup.topUpAmount < definitionTable.minValue)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MINTOPUPAMT")
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MINTOPUPAMT", "MINTOPUPAMT", nil)
								end
								isValid = false
								party.policyYear = orgPolicyYear
							elsif (definitionTable.maxValue != nil and ptup.topUpAmount > definitionTable.maxValue)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MAXTOPUPAMT")
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MAXTOPUPAMT", "MAXTOPUPAMT", nil)
								end
								isValid = false
								party.policyYear = orgPolicyYear
							end
						end
					elsif(ptup.policyYearTo != nil)
						party.policyYear = ptup.policyYearTo
						definitionTable = getProductDefinitionTable(minMaxTransferContriTTMS, quotation, quotationProduct)
						if (definitionTable != nil and ptup.topUpAmount != nil)
							if (definitionTable.minValue != nil and ptup.topUpAmount < definitionTable.minValue)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MINTOPUPAMT")
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MINTOPUPAMT", "MINTOPUPAMT", nil)
								end
								party.policyYear = orgPolicyYear
								isValid = false
							elsif (definitionTable.maxValue != nil and ptup.topUpAmount > definitionTable.maxValue)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "MAXTOPUPAMT")
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{ptup.guid}-topUpAmount", "MAXTOPUPAMT", "MAXTOPUPAMT", nil)
								end
								party.policyYear = orgPolicyYear
								isValid = false
							end
						end
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationTopupDO] = Hash.new if !errors[:QuotationTopupDO].is_a?(Hash)
								errors[:QuotationTopupDO][ptup.guid.to_sym] = Hash.new if !errors[:QuotationTopupDO][ptup.guid.to_sym].is_a?(Hash)
								errors[:QuotationTopupDO][ptup.guid.to_sym] = errors[:QuotationTopupDO][ptup.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
								errors[:PolicyProductDO][ptup.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][ptup.guid.to_sym].is_a?(Hash)
								errors[:PolicyProductDO][ptup.guid.to_sym] = errors[:PolicyProductDO][ptup.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateProductLaunchDate(quotation,quotationProduct,msg,errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotation,"validateProductLaunchDate",$rhoconfig[:moduleForProductValidations])
			### added check of withdrawn date as well. i.e. signed date between launch date and withdrawn date
			if quotationProduct.product != nil && quotationProduct.product.withdrawDt == nil
				quotationProduct.product.withdrawDt = Time.new(2099,12,31)
			end
			if quotation.quotationDt.to_s!="" && quotationProduct.product != nil && quotationProduct.product.launchDt !=nil && (Time.parse(quotationProduct.product.launchDt.to_s) > Time.parse(quotation.quotationDt.to_s) ||  Time.parse(quotationProduct.product.withdrawDt.to_s) < Time.parse(quotation.quotationDt.to_s))
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "productId", "ERR_PRDLAUNCH",[quotationProduct.product.longName, quotationProduct.product.productVersion])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productId", "ERR_PRDLAUNCH", "ERR_PRDLAUNCH", nil,[quotationProduct.product.longName, quotationProduct.product.productVersion])
				end

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end

					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end

				isValid=false
			end
			return isValid
		end
		###################################################################################################


		def self.validateEntryAge(quotation, quotationProduct, msg, errors, party, facetId='MINMAXENTRYAGE')
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateEntryAge",$rhoconfig[:moduleForProductValidations])
			definitionTable = nil
			labelKey = ""
			if (quotationProduct.productTypeCd == "RIDER")
				riderAsscFacet = quotation.getBaseProduct.product.getRiderAssociationFacet()
				riderAssc = quotation.getBaseProduct.product.getRiderAssociationDO(quotationProduct.productId ,quotation.getBasePlan.productPlanOptionCd,quotationProduct.productPlanOptionCd, riderAsscFacet, nil, quotationProduct.partyRoleCd)
				if (riderAssc && !riderAssc.empty? && riderAssc.entryAgeTableTypeMapSeq != nil)
					definitionTable = MobiSys::ProductUtil.getProductDefinitionTableDO(riderAssc.entryAgeTableTypeMapSeq, quotation, quotationProduct)
					labelKey = riderAssc.getLabelKey("MINMAXENTRYAGE")
				else
					if quotationProduct.product
						minMaxEntryAgeTTMS = quotationProduct.product.getTableTypeMappingSeq(facetId)
					end
					#party = quotation.getPartyByRole("PRIMARY")
					definitionTable = getProductDefinitionTable(minMaxEntryAgeTTMS, quotation, quotationProduct, party)
				end
			else
				minMaxEntryAgeTTMS = nil
				product = quotation.getBaseProduct.product
				if product
					minMaxEntryAgeTTMS = product.getTableTypeMappingSeq(facetId)
				end
				definitionTable = getProductDefinitionTable(minMaxEntryAgeTTMS, quotation, quotationProduct, party)
			end
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				minDTValue = definitionTable.minValue.to_i
				maxDTValue = definitionTable.maxValue.to_i

				results = MobiSys::DataObjects::Results.new
				if (definitionTable.minValueExpression and definitionTable.minValueExpression != "") || (definitionTable.maxValueExpression and definitionTable.maxValueExpression != "")
					results.createAttr("quotation")
					results.quotation = quotation
					results.createAttr("quotationProduct")
					results.quotationProduct = quotationProduct
					results.createAttr("basePlan")
					results.basePlan = quotation.getBaseProduct()
					results.createAttr("mainRider")
					results.mainRider = quotation.getMainRider(results.quotationProduct)
					results.createAttr("currPolicyYear")
					results.currPolicyYear = 1
					results.createAttr("currPolicyMonth")
					results.currPolicyMonth = 1
				end

				if definitionTable.minValueExpression.to_s != ""
					results.defineMethod("minValue_m",definitionTable.minValueExpression)
					minDTValue = results.minValue_m
				end

				if definitionTable.maxValueExpression.to_s != ""
					results.defineMethod("maxValue_m",definitionTable.maxValueExpression)
					maxDTValue = results.maxValue_m
				end

				age = party.age.to_i
				unitsDesc = "Years"

				if definitionTable.minValueUnits.to_s != ""
					if definitionTable.minValueUnits.to_s == "DAY"
						age = getDifferenceInDays(MobiSys::PolicyBO.getDBDateTemp(party.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Days"
					elsif definitionTable.minValueUnits.to_s == "MONTH"
						age = getDifferenceInMonths(MobiSys::PolicyBO.getDBDateTemp(party.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Months"
					end
				end
				if minDTValue != nil && (age < minDTValue.to_i)

					exceptionCd = "ERR_MIN"
					if facetId.to_s != "" && labelKey.to_s == ""
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MIN"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MIN"
						end
					elsif labelKey.to_s != ""
						exceptionCd = labelKey
					end

					paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel(party.roleCd.to_s)} "<< party.getFullName, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}"]
					if exceptionCd == "ERR_MINMAX"
						paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel(party.roleCd.to_s)} "<< party.getFullName, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s]
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, paramsArray)
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{party.guid}-age", exceptionCd, exceptionCd, nil,paramsArray)
					end
					isValid = false
				end

				unitsDesc = "Years"
				age = party.age.to_i
				if definitionTable.maxValueUnits.to_s != ""
					if definitionTable.maxValueUnits.to_s == "DAY"
						age = getDifferenceInDays(MobiSys::PolicyBO.getDBDateTemp(party.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Days"
					elsif definitionTable.maxValueUnits.to_s == "MONTH"
						age = getDifferenceInMonths(MobiSys::PolicyBO.getDBDateTemp(party.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Months"
					end
				end
				if maxDTValue != nil && (age > maxDTValue.to_i)
					exceptionCd = "ERR_MAX"
					if facetId.to_s != "" && labelKey.to_s == ""
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MAX"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MAX"
						end
					elsif labelKey.to_s != ""
						exceptionCd = labelKey
					end
					paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel(party.roleCd.to_s)} "<< party.getFullName, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}"]
					if exceptionCd == "ERR_MINMAX"
						paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel(party.roleCd.to_s)} "<< party.getFullName, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s]
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, paramsArray)
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{party.guid}-age", exceptionCd, exceptionCd, nil,paramsArray)
					end
					isValid = false
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
							errors[:QuotationPartyDO][party.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][party.guid.to_sym].is_a?(Hash)
							errors[:QuotationPartyDO][party.guid.to_sym]["age"] = Array.new if !errors[:QuotationPartyDO][party.guid.to_sym]["age"].is_a?(Array)
							errors[:QuotationPartyDO][party.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end

					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
							errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
							errors[:PartyDO][party.guid.to_sym]["age"] = Array.new if !errors[:PartyDO][party.guid.to_sym]["age"].is_a?(Array)
							errors[:PartyDO][party.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateJointEntryAge(quotation, quotationProduct, definitionTable, msg, errors, jointLife, facetId='MINMAXENTRYAGE')
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(jointLife,"validateJointLAEntryAge",$rhoconfig[:moduleForProductValidations])
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				if definitionTable.minValue != nil &&  jointLife.age.to_i < definitionTable.minValue.to_i
					exceptionCd = "ERR_MIN"
					facetDO = quotationProduct.product.getFacet("MINMAXENTRYAGE")
					if facetDO != nil && facetDO.labelKey.to_s != ""
						exceptionCd = facetDO.labelKey
					elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
						exceptionCd = facetId
					elsif LabelValue.getLabel(("ERR_"+facetId+"_MIN"), Application.getValue('DEFAULTLOCALE')) != ""
						exceptionCd = "ERR_"+facetId+"_MIN"
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, ["JOINTENTRYAGE", jointLife.age.to_s, definitionTable.minValue.to_i.to_s, quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{jointLife.guid}-age", exceptionCd, exceptionCd, nil,["JOINTENTRYAGE", jointLife.age.to_s, definitionTable.minValue.to_i.to_s, quotationProduct.product.longName])
					end
					isValid = false
				elsif definitionTable.maxValue != nil &&  jointLife.age.to_i > definitionTable.maxValue.to_i
					exceptionCd = "ERR_MAX"
					facetDO = quotationProduct.product.getFacet("MINMAXENTRYAGE")
					if facetDO != nil && facetDO.labelKey.to_s != ""
						exceptionCd = facetDO.labelKey
					elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
						exceptionCd = facetId
					elsif LabelValue.getLabel(("ERR_"+facetId+"_MAX"), Application.getValue('DEFAULTLOCALE')) != ""
						exceptionCd = "ERR_"+facetId+"_MAX"
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, ["JOINTENTRYAGE", jointLife.age.to_s, definitionTable.maxValue.to_i.to_s, quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{jointLife.guid}-age", exceptionCd, exceptionCd, nil,["JOINTENTRYAGE", jointLife.age.to_s, definitionTable.maxValue.to_i.to_s, quotationProduct.product.longName])
					end
					isValid = false
				end

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
							errors[:QuotationPartyDO][jointLife.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][jointLife.guid.to_sym].is_a?(Hash)
							errors[:QuotationPartyDO][jointLife.guid.to_sym]["age"] = Array.new if !errors[:QuotationPartyDO][jointLife.guid.to_sym]["age"].is_a?(Array)
							errors[:QuotationPartyDO][jointLife.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end

					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
							errors[:PartyDO][jointLife.guid.to_sym] = Hash.new if !errors[:PartyDO][jointLife.guid.to_sym].is_a?(Hash)
							errors[:PartyDO][jointLife.guid.to_sym]["age"] = Array.new if !errors[:PartyDO][jointLife.guid.to_sym]["age"].is_a?(Array)
							errors[:PartyDO][jointLife.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateProposerEntryAge(quotation, quotationProduct, definitionTable, msg, errors, facetId='MINMAXENTRYAGE')
			isValid = true
			if definitionTable != nil
				proposer = quotation.getPartyByRole('PROPOSER')
				return isValid unless MobiSys::Validation.validateMethodCall(proposer,"validateEntryAge",$rhoconfig[:moduleForProductValidations])
				if proposer.partyTypeCd  != 'ORGANIZATION'
					unitsDesc = "Years"
					age = proposer.age.to_i

					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end

					if definitionTable.minValueUnits.to_s == "DAY"
						age = getDifferenceInDays(MobiSys::PolicyBO.getDBDateTemp(proposer.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Days"
					elsif definitionTable.minValueUnits.to_s == "MONTH"
						age = getDifferenceInMonths(MobiSys::PolicyBO.getDBDateTemp(proposer.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Months"
					end
					minDTValue = definitionTable.minValue.to_i
					maxDTValue = definitionTable.maxValue.to_i

					results = MobiSys::DataObjects::Results.new
					if (definitionTable.minValueExpression and definitionTable.minValueExpression != "") || (definitionTable.maxValueExpression and definitionTable.maxValueExpression != "")
						results.createAttr("quotation")
						results.quotation = quotation
						results.createAttr("quotationProduct")
						results.quotationProduct = quotationProduct
						results.createAttr("basePlan")
						results.basePlan = quotation.getBaseProduct()
						results.createAttr("mainRider")
						results.mainRider = quotation.getMainRider(results.quotationProduct)
						results.createAttr("currPolicyYear")
						results.currPolicyYear = 1
						results.createAttr("currPolicyMonth")
						results.currPolicyMonth = 1
					end

					if definitionTable.minValueExpression.to_s != ""
						results.defineMethod("minValue_m",definitionTable.minValueExpression)
						minDTValue = results.minValue_m
					end

					if definitionTable.maxValueExpression.to_s != ""
						results.defineMethod("maxValue_m",definitionTable.maxValueExpression)
						maxDTValue = results.maxValue_m
					end

					if minDTValue != nil && age < minDTValue.to_i
						exceptionCd = "ERR_MIN"
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MIN"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MIN"
						end

						paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel('PROPOSER')} "<< proposer.getFullName, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}"]
						if exceptionCd == "ERR_MINMAX"
							paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel('PROPOSER')} "<< proposer.getFullName, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s]
						end
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, paramsArray)
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{proposer.guid}-age", exceptionCd, exceptionCd, nil,paramsArray)
						end
						isValid = false
					end
					unitsDesc = "Years"
					age = proposer.age.to_i
					if definitionTable.maxValueUnits.to_s == "DAY"
						age = getDifferenceInDays(MobiSys::PolicyBO.getDBDateTemp(proposer.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Days"
					elsif definitionTable.maxValueUnits.to_s == "MONTH"
						age = getDifferenceInMonths(MobiSys::PolicyBO.getDBDateTemp(proposer.dob), MobiSys::PolicyBO.getDBDateTemp(quotation.quotationDt))
						unitsDesc = "Months"
					end
					if maxDTValue != nil &&  age > maxDTValue.to_i
						exceptionCd = "ERR_MAX"
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MAX"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MAX"
						end

						paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel('PROPOSER')} "<< proposer.getFullName, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s, minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}"]
						if exceptionCd == "ERR_MINMAX"
							paramsArray = [MobiSys::BrowserHelper.getLabel('entryAge'), "#{age} #{MobiSys::BrowserHelper.getLabel(unitsDesc)} #{MobiSys::BrowserHelper.getLabel('for')} #{MobiSys::BrowserHelper.getLabel('PROPOSER')} "<< proposer.getFullName, maxDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", minDTValue.to_i.to_s << " #{MobiSys::BrowserHelper.getLabel(unitsDesc)}", quotationProduct.product.longName, quotation.entityDesc.to_s]
						end
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "age", exceptionCd, paramsArray)
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{proposer.guid}-age", exceptionCd, exceptionCd, nil,paramsArray)
						end
						isValid = false
					end

					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
								errors[:QuotationPartyDO][proposer.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][proposer.guid.to_sym].is_a?(Hash)
								errors[:QuotationPartyDO][proposer.guid.to_sym]["age"] = Array.new if !errors[:QuotationPartyDO][proposer.guid.to_sym]["age"].is_a?(Array)
								errors[:QuotationPartyDO][proposer.guid.to_sym]["age"].push(tempErrorHash["age"])
							end
						end

						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
								errors[:PartyDO][proposer.guid.to_sym] = Hash.new if !errors[:PartyDO][proposer.guid.to_sym].is_a?(Hash)
								errors[:PartyDO][proposer.guid.to_sym]["age"] = Array.new if !errors[:PartyDO][proposer.guid.to_sym]["age"].is_a?(Array)
								errors[:PartyDO][proposer.guid.to_sym]["age"].push(tempErrorHash["age"])
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		#Swati Ahire 06-06-2015: Method to get difference between two dates in days
		def self.getDifferenceInDays(dateFrom, dateTo)
			dateTo = Date.new(dateTo.year, dateTo.month, dateTo.day)
			if dateFrom.to_s != ""
				dateFrom = Date.new(dateFrom.year, dateFrom.month, dateFrom.day)
				return (dateTo-dateFrom).to_i
			else
				return 0
			end
		end
		###################################################################################################


		def self.validateExpiryAge(quotation, quotationProduct, definitionTable, msg, errors,party)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(party,"validateExpiryAge",$rhoconfig[:moduleForProductValidations])
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				isValid = isValid and validateMinMaxValue(definitionTable, party.age.to_i + quotationProduct.productTerm.to_i, quotation, quotationProduct, "age", "age", party, tempErrorHash, nil, "MINMAXEXPIRYAGE")

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
							errors[:QuotationPartyDO][party.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][party.guid.to_sym].is_a?(Hash)
							errors[:QuotationPartyDO][party.guid.to_sym]["age"] = Array.new if !errors[:QuotationPartyDO][party.guid.to_sym]["age"].is_a?(Array)
							errors[:QuotationPartyDO][party.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end

					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
							errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
							errors[:PartyDO][party.guid.to_sym]["age"] = Array.new if !errors[:PartyDO][party.guid.to_sym]["age"].is_a?(Array)
							errors[:PartyDO][party.guid.to_sym]["age"].push(tempErrorHash["age"])
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateSA(quotation, quotationProduct, definitionTable, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateSA",$rhoconfig[:moduleForProductValidations])
			dt = definitionTable

			prod = quotationProduct.product.getFacet("SALABEL")
        	labelKey = (prod != nil && prod.actionValue.to_s != "") ? prod.actionValue : 'baseSumAssured'

			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			if definitionTable != nil
				isValid = validateMinMaxValue(dt, quotationProduct.baseSumAssured, quotation, quotationProduct, labelKey, 'baseSumAssured', quotationProduct, tempErrorHash, nil, "MINMAXSUMASSURED")
			end
			# unless $rhoconfig[:TABFEATUREREQD]
			# 	if $rhoconfig[:moduleForProductValidations] == "Quotation"
			# 		if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
			# 			errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
			# 			errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
			# 			errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
			# 		end
			# 	end

			# 	if $rhoconfig[:moduleForProductValidations] == "Policy"
			# 		if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
			# 			errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
			# 			errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
			# 			errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
			# 		end
			# 	end
			# end

			# if  $rhoconfig[:new_validations_in_productbo]== 'YES'
			# 	tempErrorHash= Hash.new
			# else
			# 	tempErrorHash = errors
			# end

			isValid = validateMultiple(quotation, definitionTable,quotationProduct.baseSumAssured,'baseSumAssured', tempErrorHash, quotationProduct, labelKey) and isValid

			#Avdhut 07/10/2015: Removed following facet from 3.1 Product version, thus code is also commented
			# if quotationProduct.product.getFacetValue("SAMULTIPLEOFENTERABLEPREMIUM")== "YES" && quotationProduct.capturedPremiumAmt!=nil
			#   minValue=quotationProduct.capturedPremiumAmt.to_i * 5
			#   if  quotationProduct.baseSumAssured.to_i < minValue
			#      MobiSys::CommonUtil.addErrors(tempErrorHash, "baseSumAssured", "ERR_MIN", ["SUMASSURED", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(quotationProduct.baseSumAssured), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(minValue), $currencyFormat), quotationProduct.product.longName])
			#     isValid=false
			#   end
			# end

			unless $rhoconfig[:TABFEATUREREQD]
				if $rhoconfig[:moduleForProductValidations] == "Quotation"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end

				if $rhoconfig[:moduleForProductValidations] == "Policy"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateMultiple(quotation, definitionTable, valueToBeChecked, fieldName, errors, quotationProduct, fieldLabel=nil)
			if valueToBeChecked.to_s != ""
				valueToBeChecked = valueToBeChecked.round(2)
			end
			fieldLabel = fieldName if fieldLabel.to_s == ""
			isValid = true
			if definitionTable && definitionTable.multipleFactor && definitionTable.multipleFactor != ""
				if (valueToBeChecked.to_s != "" && (valueToBeChecked.to_f % definitionTable.multipleFactor) > 0)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, "ERR_MULTIPLE", [fieldLabel, MobiSys::BrowserHelper.formatNumber(valueToBeChecked.to_s, $currencyFormat) , MobiSys::BrowserHelper.formatNumber(definitionTable.multipleFactor.to_s, $currencyFormat), quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-#{fieldName}", "ERR_MULTIPLE", "ERR_MULTIPLE", nil,[fieldLabel, MobiSys::BrowserHelper.formatNumber(valueToBeChecked.to_s, $currencyFormat) , MobiSys::BrowserHelper.formatNumber(definitionTable.multipleFactor.to_s, $currencyFormat), quotationProduct.product.longName])
					end
					isValid=false
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateLoading(quotation,quotationProduct,msg,errors,party)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateLoading",$rhoconfig[:moduleForProductValidations])
			definitionTable=nil
			offlineQuotProdExtraList = quotationProduct.QuotationProductExtraList
			if offlineQuotProdExtraList != nil
				offlineQuotProdExtraList.each do |quotationProductExtraDO|
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					quotationProduct.loadingTypeCd = quotationProductExtraDO.extraTypeCd
					if quotationProductExtraDO.loadingTypeCd.to_s == "FLAT"
						if quotationProductExtraDO.extraFlatAmt.to_s != "" && quotationProductExtraDO.extraFlatDuration.to_s == ""
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProductExtraDO.guid}-extraFlatDuration", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil,["extraFlatDuration",quotationProduct.product.longName + " " + MobiSys::BrowserHelper.checkNil(party.firstname) + " " + MobiSys::BrowserHelper.checkNil(party.lastname)])
						end
					elsif quotationProductExtraDO.loadingTypeCd.to_s == "PERCENTAGE"
						if quotationProductExtraDO.extraPercent.to_s != "" && quotationProductExtraDO.extraPercDuration.to_s == ""
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProductExtraDO.guid}-extraPercDuration", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil,["extraPercDuration",quotationProduct.product.longName + " " + MobiSys::BrowserHelper.checkNil(party.firstname) + " " + MobiSys::BrowserHelper.checkNil(party.lastname)])
						end
					elsif ["EITHER", "BOTH"].include?(quotationProductExtraDO.loadingTypeCd.to_s)
						if quotationProductExtraDO.loadingTypeCd.to_s == "EITHER" && quotationProductExtraDO.extraFlatAmt.to_s != "" && quotationProductExtraDO.extraPercent.to_s != ""
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProductExtraDO.guid}-extraFlatAmt", "ERR_EITHERLODING", "ERR_EITHERLODING", nil,["extraFlatAmt","extraPercent",quotationProduct.product.longName])
						else
							if quotationProductExtraDO.extraFlatAmt.to_s != "" && quotationProductExtraDO.extraFlatDuration.to_s == ""
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProductExtraDO.guid}-extraFlatDuration", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil,["extraFlatDuration",quotationProduct.product.longName + " " + MobiSys::BrowserHelper.checkNil(party.firstname) + " " + MobiSys::BrowserHelper.checkNil(party.lastname)])
							end
							if quotationProductExtraDO.extraPercent.to_s != "" && quotationProductExtraDO.extraPercDuration.to_s == ""
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProductExtraDO.guid}-extraPercDuration", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil,["extraPercDuration",quotationProduct.product.longName + " " + MobiSys::BrowserHelper.checkNil(party.firstname) + " " + MobiSys::BrowserHelper.checkNil(party.lastname)])
							end
						end
					end

					minMaxPrdExtraPercTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXPRDEXTRAPERC')
					if  minMaxPrdExtraPercTTMS
						if(quotationProductExtraDO.extraPercent != nil)
							definitionTable = getProductDefinitionTable(minMaxPrdExtraPercTTMS, quotation, quotationProduct)
							if(definitionTable != nil)
								if quotationProductExtraDO.extraPercent.to_s != ""
								   	validateMultiple(quotation, definitionTable, quotationProductExtraDO.extraPercent,"extraPercent",tempErrorHash,quotationProduct)
									isValid = isValid and validateMinMaxValue(definitionTable, quotationProductExtraDO.extraPercent, quotation, quotationProduct, MobiSys::BrowserHelper.getLabel('extraPercent') << MobiSys::BrowserHelper.getLabel("-") <<  MobiSys::BrowserHelper.getLabel(quotationProductExtraDO.extraTypeCd), 'extraPercent', quotationProductExtraDO,tempErrorHash, nil, "MINMAXPRDEXTRAPERC")
								end
							end
						end
					end
					minMaxPrdExtraFlatTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXPRDEXTRAFLAT')
					if  minMaxPrdExtraFlatTTMS
						if(quotationProductExtraDO.extraFlatAmt != nil)
							definitionTable = getProductDefinitionTable(minMaxPrdExtraFlatTTMS, quotation, quotationProduct)
							if(definitionTable != nil)
								validateMultiple(quotation, definitionTable, quotationProductExtraDO.extraFlatAmt,"extraFlatAmt",tempErrorHash,quotationProduct);
								if quotationProductExtraDO.extraFlatAmt.to_s != ""
									isValid = isValid and validateMinMaxValue(definitionTable, quotationProductExtraDO.extraFlatAmt, quotation, quotationProduct, MobiSys::BrowserHelper.getLabel('extraFlatAmt') << MobiSys::BrowserHelper.getLabel("-") <<  MobiSys::BrowserHelper.getLabel(quotationProductExtraDO.extraTypeCd), 'extraFlatAmt', quotationProductExtraDO,tempErrorHash, nil, "MINMAXPRDEXTRAFLAT")
								end
							end
						end
					end

					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationProductExtraDO] = Hash.new if !errors[:QuotationProductExtraDO].is_a?(Hash)
								errors[:QuotationProductExtraDO][quotationProductExtraDO.guid.to_sym] = Hash.new if !errors[:QuotationProductExtraDO][quotationProductExtraDO.guid.to_sym].is_a?(Hash)
								errors[:QuotationProductExtraDO][quotationProductExtraDO.guid.to_sym] = errors[:QuotationProductExtraDO][quotationProductExtraDO.guid.to_sym].merge(tempErrorHash)
							end
						end

						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyProductExtraDO] = Hash.new if !errors[:PolicyProductExtraDO].is_a?(Hash)
								errors[:PolicyProductExtraDO][quotationProductExtraDO.guid.to_sym] = Hash.new if !errors[:PolicyProductExtraDO][quotationProductExtraDO.guid.to_sym].is_a?(Hash)
								errors[:PolicyProductExtraDO][quotationProductExtraDO.guid.to_sym] = errors[:PolicyProductExtraDO][quotationProductExtraDO.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateLoadingDuration(quotation, quotationProduct, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateLoadingDuration",$rhoconfig[:moduleForProductValidations])
			ruleSeq = nil
			minMaxPrdExtraPeriodFacet = quotationProduct.product.getTableTypeMappingSeq('MINMAXPRDEXTRAPERIOD')
			minMaxPrdExtraPeriodPerc = quotationProduct.product.getTableTypeMappingSeq('MINMAXPRDEXTRAPERIODPERC')
			ruleSeq = minMaxPrdExtraPeriodFacet
			if minMaxPrdExtraPeriodFacet.to_s != ""
				quotationProduct.QuotationProductExtraList.each do |quotationProductExtra|
					quotationProduct.loadingTypeCd = quotationProductExtra.extraTypeCd
					dt = getProductDefinitionTable(minMaxPrdExtraPeriodFacet, quotation,quotationProduct)
					if dt
						#call validateMinMaxValue
						# label = Localization::LabelCache.instance.getLabel("extraFlatAmt".to_sym)
						label = MobiSys::BrowserHelper.getLabel('extraFlatDuration') << " " << MobiSys::BrowserHelper.getLabel("-") << " " <<  MobiSys::BrowserHelper.getLabel(quotationProductExtra.extraTypeCd)
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						validateMultiple(quotation, dt, quotationProductExtra.extraFlatDuration,"extraFlatDuration",tempErrorHash,quotationProduct)
						isValid = isValid and validateMinMaxValue(dt, quotationProductExtra.extraFlatDuration, quotation, quotationProduct, "#{label}", 'extraFlatDuration', quotationProductExtra, tempErrorHash, nil, "MINMAXPRDEXTRAPERIOD")
						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationProductExtraDO] = Hash.new if !errors[:QuotationProductExtraDO].is_a?(Hash)
									errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym] = Hash.new if !errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym] = errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyProductExtraDO] = Hash.new if !errors[:PolicyProductExtraDO].is_a?(Hash)
									errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym] = Hash.new if !errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym].is_a?(Hash)
									errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym] = errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end

				end
			end
			if minMaxPrdExtraPeriodPerc.to_s != ""
				quotationProduct.QuotationProductExtraList.each do |quotationProductExtra|
					quotationProduct.loadingTypeCd = quotationProductExtra.extraTypeCd
					dt = getProductDefinitionTable(minMaxPrdExtraPeriodPerc, quotation,quotationProduct)
					if dt
						#call validateMinMaxValue
						# label = Localization::LabelCache.instance.getLabel("extraPercent".to_sym)
						label = MobiSys::BrowserHelper.getLabel('extraPercDuration') << " " << MobiSys::BrowserHelper.getLabel("-") <<  " " << MobiSys::BrowserHelper.getLabel(quotationProductExtra.extraTypeCd)
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						validateMultiple(quotation, dt, quotationProductExtra.extraPercDuration,"extraPercDuration",tempErrorHash,quotationProduct)
						isValid = isValid and validateMinMaxValue(dt, quotationProductExtra.extraPercDuration, quotation, quotationProduct, "#{label}", 'extraPercDuration', quotationProductExtra,  tempErrorHash, nil, "MINMAXPRDEXTRAPERIODPERC")
						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationProductExtraDO] = Hash.new if !errors[:QuotationProductExtraDO].is_a?(Hash)
									errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym] = Hash.new if !errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym] = errors[:QuotationProductExtraDO][quotationProductExtra.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyProductExtraDO] = Hash.new if !errors[:PolicyProductExtraDO].is_a?(Hash)
									errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym] = Hash.new if !errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym].is_a?(Hash)
									errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym] = errors[:PolicyProductExtraDO][quotationProductExtra.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateMinMaxValue(definitionTable, valueToValidate, quotation, quotationProduct, fieldLabel, fieldName, objContainingVal, errors, policyYear = nil, facetId = nil, labelKey = nil)

			puts ">>>Inside validateMinMaxValue: valueToValidate: #{valueToValidate} fieldLabel: #{fieldLabel}"
			if valueToValidate.to_s == "" || definitionTable == nil
				return false
			end
			isValid = true
			return isValid unless valueToValidate and valueToValidate != ""
			return isValid unless definitionTable.minValueExpression || definitionTable.maxValueExpression || definitionTable.minValue || definitionTable.maxValue
			minDTValue = definitionTable.minValue
			maxDTValue = definitionTable.maxValue
			puts ">>>minDTValue from dt: #{minDTValue}"
			puts ">>>maxDTValue from dt: #{maxDTValue}"
			results = MobiSys::DataObjects::Results.new
			if (definitionTable.minValueExpression and definitionTable.minValueExpression != "") || (definitionTable.maxValueExpression and definitionTable.maxValueExpression != "")
				results.createAttr("quotation")
				results.quotation = quotation
				results.createAttr("quotationProduct")
				results.quotationProduct = quotationProduct
				results.createAttr("basePlan")
				results.basePlan = quotation.getBaseProduct()
				results.createAttr("mainRider")
				results.mainRider = quotation.getMainRider(results.quotationProduct)

				policyYear = 1 if policyYear == nil
				results.createAttr("currPolicyYear")
				results.currPolicyYear = policyYear
				results.createAttr("currPolicyMonth")
				results.currPolicyMonth = 1

				results.createAttr("currInsured")
				results.currInsured = quotationProduct.insuredPartyRefGuid
			end
			insuredParty = quotation.getParty(quotationProduct)
			if definitionTable.minValueExpression.to_s != ""
				results.defineMethod("minValue_m",definitionTable.minValueExpression)
				minDTValue = results.minValue_m
			end
			if definitionTable.maxValueExpression.to_s != ""
				results.defineMethod("maxValue_m",definitionTable.maxValueExpression)
				maxDTValue = results.maxValue_m
			end

			if minDTValue.to_s != ""
				if valueToValidate.to_f < minDTValue.to_f
					exceptionCd = "ERR_MIN"
					if facetId.to_s != "" && labelKey.to_s == ""
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MIN"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MIN"
						end
					elsif labelKey.to_s != ""
						exceptionCd = labelKey
					end
					paramsArray = [Localization::LabelCache.instance.getLabel(fieldLabel), MobiSys::BrowserHelper.formatNumber(valueToValidate.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(minDTValue.to_f.to_s, $currencyFormat), quotationProduct.product.longName, quotation.entityDesc.to_s, MobiSys::BrowserHelper.formatNumber(maxDTValue.to_f.to_s, $currencyFormat)]
					if exceptionCd == "ERR_MINMAX"
						paramsArray = [Localization::LabelCache.instance.getLabel(fieldLabel), MobiSys::BrowserHelper.formatNumber(valueToValidate.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(minDTValue.to_f.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(maxDTValue.to_f.to_s, $currencyFormat), quotationProduct.product.longName, quotation.entityDesc.to_s]
					end
					paramsArray << insuredParty.getFullName
					paramsArray << Localization::LabelCache.instance.getLabel(insuredParty.roleCd.to_s)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldLabel, exceptionCd, paramsArray)
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{objContainingVal.guid}-#{fieldName}", exceptionCd, exceptionCd, nil,paramsArray)
					end
					isValid = false
				end
			end

			if maxDTValue.to_s != ""
				if valueToValidate.to_f > maxDTValue.to_f
					exceptionCd = "ERR_MAX"
					if facetId.to_s != "" && labelKey.to_s == ""
						facetDO = quotationProduct.product.getFacet(facetId)
						if facetDO != nil && facetDO.labelKey.to_s != ""
							exceptionCd = facetDO.labelKey
						elsif LabelValue.getLabel(facetId, Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = facetId
						elsif LabelValue.getLabel(("ERR_"+facetId+"_MAX"), Application.getValue('DEFAULTLOCALE')) != ""
							exceptionCd = "ERR_"+facetId+"_MAX"
						end
					elsif labelKey.to_s != ""
						exceptionCd = labelKey
					end
					paramsArray = [Localization::LabelCache.instance.getLabel(fieldLabel), MobiSys::BrowserHelper.formatNumber(valueToValidate.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(maxDTValue.to_f.to_s, $currencyFormat), quotationProduct.product.longName, quotation.entityDesc.to_s, MobiSys::BrowserHelper.formatNumber(minDTValue.to_f.to_s, $currencyFormat)]
					if exceptionCd == "ERR_MINMAX"
						paramsArray = [Localization::LabelCache.instance.getLabel(fieldLabel), MobiSys::BrowserHelper.formatNumber(valueToValidate.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(minDTValue.to_f.to_s, $currencyFormat), MobiSys::BrowserHelper.formatNumber(maxDTValue.to_f.to_s, $currencyFormat), quotationProduct.product.longName, quotation.entityDesc.to_s]
					end
					paramsArray << insuredParty.getFullName
					paramsArray << Localization::LabelCache.instance.getLabel(insuredParty.roleCd.to_s)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldLabel, exceptionCd, paramsArray)
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{objContainingVal.guid}-#{fieldName}", exceptionCd, exceptionCd, nil,paramsArray)
					end
					isValid = false
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateMinMaxpdfPeriod(quotation, quotationProduct, msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validatepdfPeriod",$rhoconfig[:moduleForProductValidations])
			minMaxPdfPeriod = quotationProduct.product.getTableTypeMappingSeq('MINMAXPDFPERIOD')
			if minMaxPdfPeriod
				definitionTable = getProductDefinitionTable(minMaxPdfPeriod,quotation,quotationProduct)
				if quotationProduct.pdfPeriod != nil && quotationProduct.pdfPeriod != "" && quotationProduct.solvertypecd != 'NO'
					if definitionTable != nil

						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end

						isValid = validateMinMaxValue(definitionTable, quotationProduct.pdfPeriod, quotation, quotationProduct, "pdfPeriod", 'pdfPeriod', quotationProduct,  tempErrorHash, nil, "MINMAXPDFPERIOD")

						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validateMinMaxpdfAmount(quotation, quotationProduct, msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateMinMaxpdfAmount",$rhoconfig[:moduleForProductValidations])
			minMaxPdfAmount = quotationProduct.product.getTableTypeMappingSeq('MINMAXPDFAMOUNT')
			if minMaxPdfAmount
				definitionTable = getProductDefinitionTable(minMaxPdfAmount,quotation,quotationProduct)
				if quotationProduct.pdfAmount != nil && quotationProduct.pdfAmount != "" && quotationProduct.solvertypecd != 'NO'
					if definitionTable !=nil
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end

						isValid = validateMinMaxValue(definitionTable, quotationProduct.pdfAmount, quotation, quotationProduct, "pdfAmount", 'pdfAmount', quotationProduct,  tempErrorHash, nil, "MINMAXPDFAMOUNT")

						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validateWithdrawal(quotation, quotationProduct, msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateWithdrawal",$rhoconfig[:moduleForProductValidations])
			minMaxWithdrawalTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
			minMaxPolicyYearWithdrawalDT = quotationProduct.product.getTableTypeMappingSeq('MINMAXPOLICYYEARWITHDRAWAL')

			if minMaxWithdrawalTTMS  || minMaxPolicyYearWithdrawalDT
				definitionTable = getProductDefinitionTable(minMaxWithdrawalTTMS,quotation,quotationProduct)
				policyYearWithdrawalDT = getProductDefinitionTable(minMaxPolicyYearWithdrawalDT,quotation,quotationProduct)
				quotation.QuotationWithdrawalList.each do |withrawal|
					next if withrawal.removed && withrawal.removed != ""
					# puts withrawal.withdrawalAmount.to_f
					# puts definitionTable.minValue.to_f
					# puts withrawal.withdrawalAmount.to_f < definitionTable.minValue.to_f
					# puts definitionTable.minValue !=nil
					# puts withrawal.withdrawalAmount !=nil
					# puts withrawal.withdrawalAmount !=nil
					# puts withrawal.withdrawalAmount.to_f > 0

					policyYearDesc = MobiSys::BrowserHelper.getLabel('Withdrawal Amount')
					withWithdrawal = MobiSys::BrowserHelper.getLabel("with")
					forPolicyYearWithdrawal = MobiSys::BrowserHelper.getLabel("for policy year")

					policyYearDesc = policyYearDesc + " #{forPolicyYearWithdrawal} "+ withrawal.policyYearFrom.to_s;
					if(withrawal.policyYearFrom.to_i != 0 && withrawal.policyYearTo.to_i != 0 && withrawal.policyYearFrom.to_i != withrawal.policyYearTo.to_i)
						policyYearDesc = policyYearDesc + " - " + withrawal.policyYearTo.to_s
					elsif (withrawal.policyYearTo.to_i != 0 && withrawal.policyYearFrom.to_i == 0)
						policyYearDesc = policyYearDesc + " - " + withrawal.policyYearTo.to_s
					end
					policyYearDesc = policyYearDesc + " #{withWithdrawal} "
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end

					if definitionTable != nil
						isValid = validateMinMaxValue(definitionTable,withrawal.withdrawalAmount,quotation,quotationProduct, policyYearDesc, 'withdrawalAmount', withrawal, tempErrorHash, nil, "MINMAXWITHDRAWALAMOUNT") and isValid
						isValid = validateMultiple(quotation, definitionTable,withrawal.withdrawalAmount,"withdrawalAmount", tempErrorHash, quotationProduct) and isValid
					end

					if policyYearWithdrawalDT != nil
						isValid = validateMinMaxValue(policyYearWithdrawalDT,withrawal.policyYearFrom,quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearFrom"), 'policyYearFrom', withrawal, tempErrorHash, nil, "MINMAXPOLICYYEARWITHDRAWAL") and isValid
						isValid = validateMinMaxValue(policyYearWithdrawalDT,withrawal.policyYearTo,quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearTo"), 'policyYearTo', withrawal, tempErrorHash, nil, "MINMAXPOLICYYEARWITHDRAWAL") and isValid
					end

					if(quotationProduct.productTerm != nil && withrawal.policyYearTo.to_s != "" && withrawal.policyYearTo > quotationProduct.productTerm)
                           # registerException("ERR_WITHDRAWALPOLICYYEAR", new String[] {String.valueOf(withrawal.policyYearTo),String.valueOf(quotationProduct.productTerm),this.dataObject.getLongName()},pwdlDO ,null, this.baseIO.getBaseDO(),"policyYearTo");
						MobiSys::CommonUtil.registerException(quotation.guid, "#{withrawal.guid}-policyYearTo", "ERR_WITHDRAWALPOLICYYEAR", "ERR_WITHDRAWALPOLICYYEAR", nil,[withrawal.policyYearTo.to_s,quotationProduct.productTerm.to_s,quotationProduct.product.longName.to_s])
                   	end

					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationWithdrawalDO] = Hash.new if !errors[:QuotationWithdrawalDO].is_a?(Hash)
								errors[:QuotationWithdrawalDO][withrawal.guid.to_sym] = Hash.new if !errors[:QuotationWithdrawalDO][withrawal.guid.to_sym].is_a?(Hash)
								errors[:QuotationWithdrawalDO][withrawal.guid.to_sym] = errors[:QuotationWithdrawalDO][withrawal.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validateTopup(quotation, quotationProduct, msg, errors, party)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateTopup",$rhoconfig[:moduleForProductValidations])
			minMaxTopupAmtTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOPUPAMOUNT')
			minMaxPolicyYearTopupDT = quotationProduct.product.getTableTypeMappingSeq('MINMAXPOLICYYEARTOPUP')
			if minMaxTopupAmtTTMS || minMaxPolicyYearTopupDT
				quotationProduct.topUpTypeCd="ADHOCTOPUP"
				definitionTable = getProductDefinitionTable(minMaxTopupAmtTTMS,quotation,quotationProduct)
				policyYearTopupDT =  getProductDefinitionTable(minMaxPolicyYearTopupDT,quotation,quotationProduct)
				orgPolicyYear = party.policyYear
				quotation.QuotationTopUpList.each do |topup|
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					if topup.removed != "YES"
						if topup.topUpTypeCd=="ADHOCTOPUP"
							policyYearDesc = MobiSys::BrowserHelper.getLabel('ADHOCTOPUPPOLICYYEARDESC')
							with = MobiSys::BrowserHelper.getLabel("with")

							policyYearDesc = "#{policyYearDesc} #{topup.policyYearFrom.to_s}"
							if(topup.policyYearFrom.to_i != 0 && topup.policyYearTo.to_i != 0 && topup.policyYearFrom.to_i != topup.policyYearTo.to_i)
								policyYearDesc = policyYearDesc + " - " + topup.policyYearTo.to_s
							elsif (topup.policyYearTo.to_i != 0 && topup.policyYearFrom.to_i == 0)
								policyYearDesc = "#{policyYearDesc} #{topup.policyYearTo.to_s}"
							end
							policyYearDesc = policyYearDesc + " #{with} "

							if topup.policyYearFrom.to_s != '' && topup.policyYearTo.to_s != ''
								for i in topup.policyYearFrom.to_i..topup.policyYearTo.to_i
									party.policyYear = i
									definitionTable =getProductDefinitionTable(minMaxTopupAmtTTMS,quotation,quotationProduct,party)
									isValid = validateMinMaxValue(definitionTable,topup.topUpAmount, quotation,quotationProduct, policyYearDesc, 'topUpAmount', topup, tempErrorHash, i, "MINMAXTOPUPAMOUNT")
									isValid = validateMultiple(quotation, definitionTable,topup.topUpAmount,"topUpAmount", tempErrorHash, quotationProduct) and isValid
									isValid = validateMinMaxValue(policyYearTopupDT,topup.policyYearFrom, quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearFrom"), 'policyYearFrom', topup, tempErrorHash, i, "MINMAXPOLICYYEARTOPUP")
									isValid = validateMinMaxValue(policyYearTopupDT,topup.policyYearTo, quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearTo"), 'policyYearTo', topup, tempErrorHash, i, "MINMAXPOLICYYEARTOPUP")
								end
								party.policyYear = orgPolicyYear

							elsif topup.policyYearFrom != nil
								party.policyYear = topup.policyYearFrom
								definitionTable =getProductDefinitionTable(minMaxTopupAmtTTMS,quotation,quotationProduct,party)
								if definitionTable != nil
									isValid = validateMinMaxValue(definitionTable,topup.topUpAmount, quotation,quotationProduct, policyYearDesc, 'topUpAmount', topup, tempErrorHash, topup.policyYearFrom, "MINMAXTOPUPAMOUNT")
									isValid = validateMultiple(quotation, definitionTable, topup.topUpAmount,"topUpAmount",tempErrorHash, quotationProduct) and isValid
								end
								isValid = validateMinMaxValue(policyYearTopupDT,topup.policyYearFrom, quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearFrom"), 'policyYearFrom', topup, tempErrorHash, i, "MINMAXPOLICYYEARTOPUP")
								party.policyYear = orgPolicyYear

							elsif topup.policyYearTo != nil
								party.policyYear = ptup.policyYearTo
								definitionTable = getProductDefinitionTable(minMaxTopupAmtTTMS,quotation,quotationProduct,party)
								if definitionTable != nil
									isValid = validateMinMaxValue(definitionTable,topup.topUpAmount, quotation,quotationProduct, policyYearDesc, 'topUpAmount',topup, tempErrorHash, topup.policyYearTo, "MINMAXTOPUPAMOUNT");
									isValid = validateMultiple(quotation, definitionTable, topup.topUpAmount,"topUpAmount",tempErrorHash, quotationProduct) and isValid
								end
								isValid = validateMinMaxValue(policyYearTopupDT,topup.policyYearTo, quotation,quotationProduct, MobiSys::BrowserHelper.getLabel("policyYearTo"), 'policyYearTo', topup, tempErrorHash, i, "MINMAXPOLICYYEARTOPUP")
								party.policyYear = orgPolicyYear
							end
						end # topup.topUpTypeCd=="ADHOCTOPUP" ends here
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
								errors[:QuotationTopUpDO][topup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][topup.guid.to_sym].is_a?(Hash)
								errors[:QuotationTopUpDO][topup.guid.to_sym] = errors[:QuotationTopUpDO][topup.guid.to_sym].merge(tempErrorHash)
							end
						end

						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
								errors[:PolicyTopUpDO][topup.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][topup.guid.to_sym].is_a?(Hash)
								errors[:PolicyTopUpDO][topup.guid.to_sym] = errors[:PolicyTopUpDO][topup.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
				baseQuotationProduct = quotation.getBaseProduct
				baseQuotationProduct.product = MobiSys::ProductUtil.getProduct(baseQuotationProduct.productSeq) unless baseQuotationProduct.product
				renderRegularTopupPanel = MobiSys::BrowserHelper.renderPanel?('REGULARTOPUPSREQUIRED', baseQuotationProduct.product)
				if renderRegularTopupPanel && quotation.regularTopupFl == 'YES'
					quotationProduct.topUpTypeCd="REGULARTOPUP"
					regularTopup = MobiSys::QuotationBO.getRegularTopup(quotation)
					prod = quotationProduct.product.getFacet("REGULARTOPUPLABEL")
        			labelKey = (prod != nil && prod.actionValue.to_s != "") ? prod.actionValue : 'topUpAmount'

					minMaxTopUpAmountTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOPUPAMOUNT')

					definitionTable = getProductDefinitionTable(minMaxTopUpAmountTTMS,quotation,quotationProduct)
					regularTpAmt=quotation.getRegularPolicyTopupAmt(1)
					if definitionTable !=nil
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						isValid = validateMinMaxValue( definitionTable,regularTpAmt,quotation,quotationProduct,labelKey, 'topUpAmount', regularTopup, tempErrorHash, nil, "MINMAXTOPUPAMOUNT")
						isValid = validateMultiple(quotation, definitionTable,regularTpAmt,'topUpAmount', tempErrorHash, quotationProduct,labelKey) and isValid
						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
									errors[:QuotationTopUpDO][regularTopup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][regularTopup.guid.to_sym].is_a?(Hash)
									errors[:QuotationTopUpDO][regularTopup.guid.to_sym] = errors[:QuotationTopUpDO][regularTopup.guid.to_sym].merge(tempErrorHash)
								end
							end

							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
									errors[:PolicyTopUpDO][regularTopup.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][regularTopup.guid.to_sym].is_a?(Hash)
									errors[:PolicyTopUpDO][regularTopup.guid.to_sym] = errors[:PolicyTopUpDO][regularTopup.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			if quotation.initialTopupFl == 'YES'
				quotationProduct.topUpTypeCd="INITIALINVESTMENT"
				initialTopup = MobiSys::QuotationBO.getInitialTopup(quotation)
				minMaxTopUpAmountTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOPUPAMOUNT')
				definitionTable =getProductDefinitionTable(minMaxTopUpAmountTTMS,quotation,quotationProduct)
				initialAmount=quotation.getInitialInvestmentAmt(1)
				if definitionTable !=nil
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					isValid = validateMinMaxValue( definitionTable,initialAmount,quotation,quotationProduct,"topUpAmount", 'topUpAmount', initialTopup, tempErrorHash, nil, "MINMAXTOPUPAMOUNT")
					isValid = validateMultiple(quotation, definitionTable,initialAmount,"topUpAmount", tempErrorHash, quotationProduct) and isValid
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
								errors[:QuotationTopUpDO][initialTopup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][initialTopup.guid.to_sym].is_a?(Hash)
								errors[:QuotationTopUpDO][initialTopup.guid.to_sym] = errors[:QuotationTopUpDO][initialTopup.guid.to_sym].merge(tempErrorHash)
							end
						end

						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
								errors[:PolicyTopUpDO][initialTopup.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][initialTopup.guid.to_sym].is_a?(Hash)
								errors[:PolicyTopUpDO][initialTopup.guid.to_sym] = errors[:PolicyTopUpDO][initialTopup.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validatePrimaryJointGender(quotation, quotationProduct,msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validatePrimaryJointGender",$rhoconfig[:moduleForProductValidations])
			jointLife = quotation.getPartyByRole('JOINT')
			insured = quotation.getPartyByRole('PRIMARY')
			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			if quotationProduct.product !=nil && quotationProduct.product.getFacetValue("quotationProduct")=="YES"
				if insured.genderCd != nil && jointLife.genderCd !=nil && insured.genderCd==jointLife.genderCd
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "genderCd", "ERR_INVALIDGENDER", ["JOINTLIFE",jointLife.firstname+" "+jointLife.lastname,"PRIMARYLIFE",insured.firstname+" "+insured.lastname,quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{jointLife.guid}-genderCd", "ERR_INVALIDGENDER", "ERR_INVALIDGENDER", nil,["JOINTLIFE",jointLife.firstname+" "+jointLife.lastname,"PRIMARYLIFE",insured.firstname+" "+insured.lastname,quotationProduct.product.longName])
					end
					isValid=false
				end
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if $rhoconfig[:moduleForProductValidations] == "Quotation"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
						errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
						errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
					end
				end
				if $rhoconfig[:moduleForProductValidations] == "Policy"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
						errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
						errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.regularTopUpMaxValidation(quotation, quotationProduct,msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"regularTopUpMaxValidation",$rhoconfig[:moduleForProductValidations])
			maxRegTopupMultiple=quotationProduct.product.getFacetValue("MAXREGTOPUPMULTIPLEOFPREMIUM")
			regularTpAmt=quotation.getRegularPolicyTopupAmt(1)
			regularTopup = MobiSys::QuotationBO.getRegularTopup(quotation)
			if maxRegTopupMultiple != nil && quotationProduct.capturedPremiumAmt!=nil && regularTpAmt!=nil && regularTpAmt!=""
				maxRegTopupValue=maxRegTopupMultiple.to_f * quotationProduct.capturedPremiumAmt.to_f
				if maxRegTopupValue != nil && regularTpAmt > maxRegTopupValue
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "ERR_MAXTOPUPAMT", ["regularTopUpAmount", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(regularTpAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(maxRegTopupValue), $currencyFormat), "", quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{regularTopup.guid}-topUpAmount", "ERR_MAXTOPUPAMT", "ERR_MAXTOPUPAMT", nil,["regularTopUpAmount", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(regularTpAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(maxRegTopupValue), $currencyFormat), "", quotationProduct.product.longName])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
								errors[:QuotationTopUpDO][regularTopup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][regularTopup.guid.to_sym].is_a?(Hash)
								errors[:QuotationTopUpDO][regularTopup.guid.to_sym] = errors[:QuotationTopUpDO][regularTopup.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
								errors[:PolicyTopUpDO][regularTopup.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][regularTopup.guid.to_sym].is_a?(Hash)
								errors[:PolicyTopUpDO][regularTopup.guid.to_sym] = errors[:PolicyTopUpDO][regularTopup.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
					isValid = false
				end
			end
			return isValid
		end
		####################################################################################################


		def self.otherTopUpValidation(quotation, quotationProduct,msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateTopup",$rhoconfig[:moduleForProductValidations])
			topupAmt=0.0
			premiumAmt=quotationProduct.baseAnnualPremium
			minMaxTopupPercTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOPUPPREMPERC')
			if minMaxTopupPercTTMS
				definitionTable=getProductDefinitionTable(minMaxTopupPercTTMS,quotation,quotationProduct)
				if definitionTable!=nil
					fromYear=definitionTable.policyYearFrom.to_i
					toYear=definitionTable.policyYearTo==nil ? quotationProduct.productTerm.to_i : definitionTable.policyYearTo.to_i
					quotation.QuotationTopUpList.each do |topUp|
						if topUp.topUpTypeCd != "ADHOCTOPUP"
							next
						end
						if topUp.policyYearFrom != nil && topUp.policyYearTo !=nil
							for year in topUp.policyYearFrom.to_i..topUp.policyYearTo.to_i
								if year >= fromYear && year <= toYear &&  topUp.topUpAmount!=nil
									topupAmt=topupAmt+topUp.topUpAmount.to_f
								end
							end
						end
					end
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					if definitionTable.minValue != nil && topupAmt >= 0 && topupAmt < (premiumAmt/100)*definitionTable.minValue.to_f
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "ERR_MINTOPUPAMT", ["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(topupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.minValue), $currencyFormat), "POLICYYEAR "+fromYear.to_s+" - "+toYear.to_s ,quotationProduct.product.longName])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-topUpAmount", "ERR_MINTOPUPAMT", "ERR_MINTOPUPAMT", nil,["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(topupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.minValue), $currencyFormat), "POLICYYEAR "+fromYear.to_s+" - "+toYear.to_s ,quotationProduct.product.longName])
						end
						isValid = false
					elsif definitionTable.maxValue != nil && totalTopupAmt>=0 &&  topupAmt > (premiumAmt/100)*definitionTable.maxValue.to_f
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "ERR_MINTOPUPAMT", ["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(topupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.maxValue), $currencyFormat), "POLICYYEAR "+fromYear.to_s+" - "+toYear.to_s ,quotationProduct.product.longName])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-topUpAmount", "ERR_MINTOPUPAMT", "ERR_MINTOPUPAMT", nil,["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(topupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.maxValue), $currencyFormat), "POLICYYEAR "+fromYear.to_s+" - "+toYear.to_s ,quotationProduct.product.longName])
						end
						isValid = false
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
								errors[:QuotationTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][topUp.guid.to_sym].is_a?(Hash)
								errors[:QuotationTopUpDO][topUp.guid.to_sym] = errors[:QuotationTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
								errors[:PolicyTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][topUp.guid.to_sym].is_a?(Hash)
								errors[:PolicyTopUpDO][topUp.guid.to_sym] = errors[:PolicyTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end

			minMaxTotalTopupAmtTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOTALTOPUPAMT')
			if minMaxTotalTopupAmtTTMS
				definitionTable=getProductDefinitionTable(minMaxTotalTopupAmtTTMS,quotation,quotationProduct)
				totaltopupAmt=0.0
				istopUpYearValid=true
				quotation.QuotationTopUpList.each do |topUp|
					if topUp.topUpTypeCd != "ADHOCTOPUP"
						next
					end
					if topUp.policyYearFrom != nil && topUp.policyYearTo !=nil
						for year in topUp.policyYearFrom.to_i..topUp.policyYearTo.to_i
							totaltopupAmt=totaltopupAmt+topUp.topUpAmount.to_f
						end
					end
				end
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				if definitionTable.minValue != nil && totaltopupAmt >= 0 && totaltopupAmt < (premiumAmt/100)*definitionTable.minValue.to_f
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "ERR_MINTOPUPAMT", ["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(totaltopupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.minValue), $currencyFormat),"PRODUCTTERM" ,quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-topUpAmount", "ERR_MINTOPUPAMT", "ERR_MINTOPUPAMT", nil,["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(totaltopupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.minValue), $currencyFormat),"PRODUCTTERM" ,quotationProduct.product.longName])
					end
					isValid = false
				elsif definitionTable.maxValue != nil && totaltopupAmt>=0 &&  totaltopupAmt > (premiumAmt/100)*definitionTable.maxValue.to_f
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "topUpAmount", "ERR_MINTOPUPAMT", ["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(totaltopupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.maxValue), $currencyFormat), "PRODUCTTERM" ,quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-topUpAmount", "ERR_MINTOPUPAMT", "ERR_MINTOPUPAMT", nil,["TOTALTOPUPAMOUNT", MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(totaltopupAmt), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(definitionTable.maxValue), $currencyFormat), "PRODUCTTERM" ,quotationProduct.product.longName])
					end
					isValid = false
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
							errors[:QuotationTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][topUp.guid.to_sym].is_a?(Hash)
							errors[:QuotationTopUpDO][topUp.guid.to_sym] = errors[:QuotationTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
							errors[:PolicyTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][topUp.guid.to_sym].is_a?(Hash)
							errors[:PolicyTopUpDO][topUp.guid.to_sym] = errors[:PolicyTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end

			quotation.QuotationTopUpList.each do |topUp|
				if topUp.topUpTypeCd != "ADHOCTOPUP"
					next
				end
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				if topUp.policyYearFrom.to_s != "" &&  quotationProduct.productTerm.to_s != ""  && (topUp.policyYearFrom.to_i > quotationProduct.productTerm.to_i)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearFrom", "ERR_TOPUPTOYEAR", [topUp.policyYearFrom.to_s, quotationProduct.productTerm.to_s ,quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{topUp.guid}-policyYearFrom", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil,[topUp.policyYearFrom.to_s , quotationProduct.productTerm.to_s ,quotationProduct.product.longName])
					end
					isValid = false
				end
				if topUp.policyYearTo.to_s != "" &&  quotationProduct.productTerm.to_s != ""  && (topUp.policyYearTo.to_i > quotationProduct.productTerm.to_i)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_TOPUPTOYEAR", [topUp.policyYearTo.to_s, quotationProduct.productTerm.to_s ,quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{topUp.guid}-policyYearTo", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil,[topUp.policyYearTo.to_s , quotationProduct.productTerm.to_s ,quotationProduct.product.longName])
					end
					isValid = false
				end
				noTopUpFacet = quotationProduct.product.getFacet('NOTOPUPFORPPT')
				if noTopUpFacet  && quotationProduct.premiumPayingTerm.to_s != ""
					if topUp.policyYearFrom.to_s != "" &&  quotationProduct.productTerm.to_s !=""  && (topUp.policyYearFrom.to_i <= quotationProduct.premiumPayingTerm.to_i)
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearFrom", "ERR_TOPUPYEARWITHINPPT", [quotationProduct.product.longName])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{topUp.guid}-policyYearFrom", "ERR_TOPUPYEARWITHINPPT", "ERR_TOPUPYEARWITHINPPT", nil,[quotationProduct.product.longName])
						end
						isValid = false
					end
					if topUp.policyYearTo.to_s != "" &&  quotationProduct.productTerm.to_s != ""  && (topUp.policyYearTo.to_i <= quotationProduct.premiumPayingTerm.to_i)
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_TOPUPYEARWITHINPPT", [quotationProduct.product.longName])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{topUp.guid}-policyYearTo", "ERR_TOPUPYEARWITHINPPT", "ERR_TOPUPYEARWITHINPPT", nil,[quotationProduct.product.longName])
						end
						isValid = false
					end
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
							errors[:QuotationTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][topUp.guid.to_sym].is_a?(Hash)
							errors[:QuotationTopUpDO][topUp.guid.to_sym] = errors[:QuotationTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyTopUpDO] = Hash.new if !errors[:PolicyTopUpDO].is_a?(Hash)
							errors[:PolicyTopUpDO][topUp.guid.to_sym] = Hash.new if !errors[:PolicyTopUpDO][topUp.guid.to_sym].is_a?(Hash)
							errors[:PolicyTopUpDO][topUp.guid.to_sym] = errors[:PolicyTopUpDO][topUp.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end

			return isValid
		end
		####################################################################################################


		def self.validateSAMultiple(quotation, quotationProduct,msg, errors)
			isValid=true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateSA",$rhoconfig[:moduleForProductValidations])
			tableTypeMappingSeq=nil
			if quotationProduct.product.getPremiumDetailsFacet !=nil
				tableTypeMappingSeq
				premiumDttl = quotationProduct.product.getOtherDetailsFacet.OfflinePremiumDetailsList[0] if !quotationProduct.product.getOtherDetailsFacet.nil?
				if premiumDttl !=nil
					if premiumDttl.units !=nil
						tableTypeMappingSeq=premiumDttl.units
					else
						return isValid
					end
				end
			end
			if tableTypeMappingSeq
				definitionTable=getProductDefinitionTable(tableTypeMappingSeq,quotation,quotationProduct)
				if definitionTable !=nil && definitionTable.rate!=nil && quotationProduct.baseSumAssured !=nil
					remainder=quotationProduct.baseSumAssured/definitionTable.rate
					if(remainder>0)
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "unappliedPremium", "ERR_SAMULTIPLE", ["sumAssured",MobiSys::BrowserHelper.formatNumber(quotationProduct.baseSumAssured.to_s, $currencyFormat),MobiSys::BrowserHelper.renderNumber(definitionTable.rate),quotationProduct.product.longName])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-unappliedPremium", "ERR_SAMULTIPLE", "ERR_SAMULTIPLE", nil,["sumAssured",MobiSys::BrowserHelper.formatNumber(quotationProduct.baseSumAssured.to_s, $currencyFormat),MobiSys::BrowserHelper.renderNumber(definitionTable.rate),quotationProduct.product.longName])
						end
						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
									errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validateRelations(quotation, quotationProduct, msg, errors, partyList)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validatePartyRelation",$rhoconfig[:moduleForProductValidations])
			relnOfOtherLivesWithPrimaryTTMS = quotationProduct.product.getTableTypeMappingSeq('RELNOFOTHERLIVESWITHPRIMARY')
			if relnOfOtherLivesWithPrimaryTTMS
				definitionTable = getProductDefinitionTable(relnOfOtherLivesWithPrimaryTTMS,quotation,quotationProduct)
				if definitionTable != nil && definitionTable.allowedRelations != nil
					partyList = quotation.QuotationPartyList
					partyList.each do |party|
						if !(party.roleCd == "PRIMARY" || party.roleCd == "PROPOSER" || party.roleCd == "PROPCUMINS") && !definitionTable.allowedRelations.include?(party.relationCd)
							isValid = false
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RELATIONWITHPROPOSER", [party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{party.guid}-relationCd", "ERR_RELATIONWITHPROPOSER", "ERR_RELATIONWITHPROPOSER", nil,[party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
										errors[:QuotationPartyDO][party.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][party.guid.to_sym].is_a?(Hash)
										errors[:QuotationPartyDO][party.guid.to_sym] = errors[:QuotationPartyDO][party.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
										errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
										errors[:PartyDO][party.guid.to_sym] = errors[:PartyDO][party.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
							break
						end
					end
				end
			end
			relnOfPrimaryWithProposerTTMS = quotationProduct.product.getTableTypeMappingSeq('RELNOFPRIMARYWITHPROPOSER')
			if relnOfPrimaryWithProposerTTMS
				definitionTable = getProductDefinitionTable(relnOfPrimaryWithProposerTTMS,quotation,quotationProduct)
				party = quotation.getPartyByRole("PRIMARY")
				if definitionTable != nil && definitionTable.allowedRelations != nil && party != nil && party.relationCd != nil && !definitionTable.allowedRelations.include?(party.relationCd)
					isValid = false
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RELATIONWITHPROPOSER", [party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{party.guid}-relationCd", "ERR_RELATIONWITHPROPOSER", "ERR_RELATIONWITHPROPOSER", nil,[party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
								errors[:QuotationPartyDO][party.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][party.guid.to_sym].is_a?(Hash)
								errors[:QuotationPartyDO][party.guid.to_sym] = errors[:QuotationPartyDO][party.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
								errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
								errors[:PartyDO][party.guid.to_sym] = errors[:PartyDO][party.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end

			relnOfProposerWithPrimary = quotationProduct.product.getTableTypeMappingSeq('RELNOFPROPOSERWITHPRIMARY')
			if relnOfProposerWithPrimary
				definitionTable = getProductDefinitionTable(relnOfProposerWithPrimary,quotation,quotationProduct)
				party = quotation.getPartyByRole("PROPOSER")
				party = quotation.getPartyByRole("PROPCUMINS") if party == nil
				if definitionTable != nil && definitionTable.allowedRelations != nil && party != nil && party.relationCd != nil && !definitionTable.allowedRelations.include?(party.relationCd)
					isValid = false
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RELATIONWITHPRIMARY", [party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{party.guid}-relationCd", "ERR_RELATIONWITHPRIMARY", "ERR_RELATIONWITHPRIMARY", nil,[party.roleCd ,definitionTable.allowedRelations.to_s, quotationProduct.product.longName])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
								errors[:QuotationPartyDO][party.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][party.guid.to_sym].is_a?(Hash)
								errors[:QuotationPartyDO][party.guid.to_sym] = errors[:QuotationPartyDO][party.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
								errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
								errors[:PartyDO][party.guid.to_sym] = errors[:PartyDO][party.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		####################################################################################################


		def self.validateModalPremium(quotation, quotationProduct, definitionTable, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateModalPremium",$rhoconfig[:moduleForProductValidations])
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				isValid = isValid and validateMinMaxValue(definitionTable, quotationProduct.modalPremium, quotation, quotationProduct, "modalPremium", 'modalPremium', quotationProduct, tempErrorHash, nil, "MINMAXMODALPREMIUM")

				isValid = validateMultiple(quotation, definitionTable,quotationProduct.modalPremium,"modalPremium", tempErrorHash, quotationProduct) and isValid

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateTotalModalPremium(quotation, quotationProduct, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateTotalModalPremium",$rhoconfig[:moduleForProductValidations])

			totalModalPrem = MobiSys::QuotationBO.calculateTotalModalPremium(quotation)
			# minmaxmodelpremium = quotationProduct.product.getFacet(quotationProduct, "MINMAXTOTALMODALPREM")
			minMaxModalPremiumTTMS = quotationProduct.product.getTableTypeMappingSeq('MINMAXTOTALMODALPREM')
			definitionTable = getProductDefinitionTable(minMaxModalPremiumTTMS, quotation, quotationProduct)

			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			if definitionTable != nil
				isValid = isValid and validateMinMaxValue(definitionTable, totalModalPrem, quotation, quotationProduct, "modalPremium", 'modalPremium', quotationProduct, tempErrorHash, nil, "MINMAXTOTALMODALPREM")
			end

			unless $rhoconfig[:TABFEATUREREQD]
				if $rhoconfig[:moduleForProductValidations] == "Quotation"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
						errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
						errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
					end
				end
				if $rhoconfig[:moduleForProductValidations] == "Policy"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
						errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
						errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateAnnualPremium(quotation, quotationProduct, definitionTable, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateAnnualPremium",$rhoconfig[:moduleForProductValidations])
			prod = quotationProduct.product.getFacet("ANNUALPREMIUMLABEL")
        	labelKey = (prod != nil && prod.actionValue.to_s != "") ? prod.actionValue : 'baseAnnualPremium'

			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				isValid = validateMinMaxValue(definitionTable, quotationProduct.baseAnnualPremium, quotation, quotationProduct, labelKey, 'baseAnnualPremium', quotationProduct,  tempErrorHash, nil, "MINMAXPREMIUM")
				isValid = validateMultiple(quotation, definitionTable, quotationProduct.baseAnnualPremium, 'baseAnnualPremium', tempErrorHash, quotationProduct, labelKey) and isValid

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateRidersSA(quotation,msg,errors,selectedSingleRider=nil)
			isValid=true
			quotationProduct=MobiSys::QuotationBO.getBaseProduct(quotation)
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			riders = MobiSys::QuotationBO.getRiders(quotation)
			riderAssoHM=Hash.new
			quotationProductMap= Hash.new
			riderAssociationList= Array.new
			offlineFacet=quotationProduct.product.getFacet("RIDERASSOCIATION")
			if offlineFacet!=nil
				riderAssociationList=offlineFacet.OfflineRiderAssociationList
			end
			riderAssociationList.each do |riderAsso|
				riderAssoHM[riderAsso.productSeq.to_s]=riderAsso
			end
			laRiderflag=false
			juvenileAge=18
			riders.each do |rider|
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				if rider.productSeq ==nil || rider.productSeq==""
					next
				end
				if rider.product !=nil
					product = MobiSys::ProductUtil.getProduct(rider.productSeq)
					rider.product=product
				end
				if (selectedSingleRider && selectedSingleRider.productSeq.to_s == rider.productSeq) || selectedSingleRider == nil
					riderPrimarySA=0.0
					riders.each do |riderPrimary|
						if riderPrimary.object!=rider.object && riderPrimary.productSeq.to_s == rider.productSeq.to_s && (riderPrimary.partyRoleCd=="PRIMARY" || riderPrimary.partyRoleCd=="PROPCUMINS")
							riderPrimarySA=riderPrimary.baseSumAssured
							laRiderflag=true
						end
					end
					#puts ">>>>>>>rider<<<<<<<<<<<<#{rider.inspect}"
					#puts ">>>>>>>>riderPrimarySA<<<<#{riderPrimarySA.inspect}"
					lifeApplFL = riderAssoHM[rider.productSeq.to_s].supplLifeAppl if riderAssoHM[rider.productSeq.to_s]
					# puts lifeApplFL
					#lifeApplFL1=lifeApplFL.supplLifeAppl
					#puts ">>>>>>>>lifeApplFL<<<<#{lifeApplFL.inspect}"
					if lifeApplFL !=nil && laRiderflag && rider.partyRoleCd=="SUPPLEMENTARY"
						party = quotation.getPartyByGuid(rider.insuredPartyRefGuid)
						if lifeApplFL == "FOLLOWPL" || lifeApplFL == "MUSTFOLLOWPL"
							if rider.baseSumAssured.to_s != '' && rider.baseSumAssured.to_f > riderPrimarySA.to_f
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "baseAnnualPremium", "ERR_FOLLOBASEPLAN", [rider.productId, MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(rider.baseSumAssured), $currencyFormat),MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(riderPrimarySA), $currencyFormat)])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-baseAnnualPremium", "ERR_FOLLOBASEPLAN", "ERR_FOLLOBASEPLAN", nil,[rider.productId, MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(rider.baseSumAssured), $currencyFormat),MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(riderPrimarySA), $currencyFormat)])
								end

								isValid=true
							end
						end
					end

					lifeApplFL = riderAssoHM[rider.productSeq.to_s].jointLifeAppl if riderAssoHM[rider.productSeq.to_s]
					if lifeApplFL !=nil && laRiderflag && rider.partyRoleCd=="JOINT"
						party = quotation.getPartyByGuid(rider.insuredPartyRefGuid)
						if lifeApplFL == "FOLLOWPL" || lifeApplFL == "MUSTFOLLOWPL"
							if rider.baseSumAssured!=nil && rider.baseSumAssured > riderPrimarySA
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "baseSumAssured", "ERR_FOLLOBASEPLAN", [rider.productId, MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(rider.baseSumAssured), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(riderPrimarySA), $currencyFormat)])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-baseSumAssured", "ERR_FOLLOBASEPLAN", "ERR_FOLLOBASEPLAN", nil,[rider.productId, MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(rider.baseSumAssured), $currencyFormat), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(riderPrimarySA), $currencyFormat)])
								end
								isValid=true
							end
						end
					end

					if rider.partyRoleCd=="SUPPLEMENTARY"
						insured = quotation.getPartyByGuid(rider.insuredPartyRefGuid)
						if insured !=nil && insured.age.to_i <= juvenileAge
							if quotationProductMap.has_key?(rider.productSeq)
								quotationProductMap[rider.productSeq].push(rider)
							else
								quoteProductList=Array.new
								quoteProductList.push(rider)
								quotationProductMap[rider.productSeq]=quoteProductList
							end
						end
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
								errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
								errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
								errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
								errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
				break if selectedSingleRider
			end
			# riderSupplyJvList=Array.new
			# riders.each do |juveRider|
			#     if quotationProductMap.has_key?(juveRider.productSeq)
			#         riderSupplyJvList=quotationProductMap[juveRider.productSeq]
			#         riderSupplyJvList.each do |riderJV1|
			#             riderSupplyJvList.each do |riderJV2|
			#                 if riderJV1.baseSumAssured !=nil && riderJV2.baseSumAssured !=nil && riderJV1.baseSumAssured.to_i != riderJV2.baseSumAssured.to_i
			#                     if  $rhoconfig[:new_validations_in_productbo]== 'YES'
			#                         tempErrorHash= Hash.new
			#                     else
			#                         tempErrorHash = errors
			#                     end
			#                     MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_JUVENILERIDERSA", [riderJV2.product.longName])
			#                     if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
			#                         errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
			#                         errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
			#                         errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
			#                     end
			#                     isValid=true
			#                 end
			#             end
			#         end
			#         quotationProductMap.delete(juveRider.productSeq)
			#     end
			# end
			return isValid
		end
		###################################################################################################


		def self.validateEnterablePremium(quotation, quotationProduct, definitionTable, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateEnterablePremium",$rhoconfig[:moduleForProductValidations])
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				isValid = isValid and validateMinMaxValue(definitionTable, quotationProduct.capturedPremiumAmt, quotation, quotationProduct, "capturedPremiumAmt", 'capturedPremiumAmt', quotationProduct, tempErrorHash, nil, "MINMAXENTERABLEPREMIUM")
				isValid = validateMultiple(quotation, definitionTable,quotationProduct.capturedPremiumAmt,"capturedPremiumAmt", tempErrorHash, quotationProduct) and isValid

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validateSupplementaryLives(quotation, quotationProduct, definitionTable, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateSupplementaryLives",$rhoconfig[:moduleForProductValidations])
			if definitionTable != nil
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				isValid = isValid and validateMinMaxValue(definitionTable, quotation.getPartyListByRoleCd("SUPPLEMENTARY").size, quotation, quotationProduct, "NOOFSUPPLYMENTARYLVES", 'genericColumn', quotation, tempErrorHash, nil, "MINMAXSUPPLEMENTARYLIVES")

				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.validatePaymentFrequency(quotation, quotationProduct, premiumDetails, msg, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotation.getBaseProduct,"validatePaymentFrequency",$rhoconfig[:moduleForProductValidations])

			# dont validate payment frequency for PA only plans
			if quotationProduct.productTypeCd == "PA" &&  # if PA product
				quotation.productId != quotationProduct.planCode # and not PA only quotation
				return isValid
			end

			if premiumDetails != nil && premiumDetails.paymentFrequencyCd != nil
				isValid = false

				if premiumDetails.paymentFrequencyCd.to_s.include? quotationProduct.paymentFrequencyCd.to_s
					isValid = true
				end

				if !isValid
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "paymentFrequencyCd", "ERR_INVALIDPAYMENTFREQUENCY", [quotationProduct.product.longName])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-paymentFrequencyCd", "ERR_INVALIDPAYMENTFREQUENCY", "ERR_INVALIDPAYMENTFREQUENCY", nil,[quotationProduct.product.longName])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
								errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
								errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
								errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
								errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.isWOP(quotationProduct, quotation)
			isWOP = false;
			if( quotationProduct.productTypeCd == "RIDER" )

				otherDetailsFacet = quotationProduct.product.getOtherDetailsFacet.OfflineOtherDetailsList[0] if quotationProduct.product.getOtherDetailsFacet
				if otherDetailsFacet != nil && otherDetailsFacet.isWOPFl != nil && otherDetailsFacet.isWOPFl == "YES"
				   isWOP = true
				   riderWopPpd = quotationProduct
				end
		   end
		   return isWOP
		end
		###################################################################################################


		def self.validateRiders(quotation, quotationProduct, riderAssociation, msg, errors, selectedSingleRider=nil)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			basePlan = quotation.getBasePlan()
			riders = MobiSys::QuotationBO.getRiders(quotation)
			ridersHM = Hash.new

			#riders.each do |riderQP|
			#  ridersHM[riderQP.productSeq] = riderQP
			#end
			key = []
			key.push "productSeq"
			key.push "productPlanOptionCd"
			ridersHM = MobiSys::CommonUtil.convertToHash(riders,key,true)

			riderAssociationHM=Hash.new

			riderAssociation.each do |riderAsso|
				basePlanOptionMatched = true
				if riderAsso.basePlanOptionCd.to_s != '' && basePlan.productPlanOptionCd.to_s != '' && riderAsso.basePlanOptionCd != basePlan.productPlanOptionCd
					basePlanOptionMatched = false
				end
				if !basePlanOptionMatched
					next
				end
				riderAssociationHM[riderAsso.productSeq.to_s + "|" + riderAsso.planOptionCd.to_s] = riderAsso
			end

			#riders taken by Primary
			primaryRiderList=Array.new
			riders.each do|riderP|
				if riderP.partyRoleCd=="PRIMARY" || riderP.partyRoleCd=="PROPCUMINS"
					primaryRiderList.push(riderP.productSeq.to_s)
				end
			end
			#puts ">>>>>>primaryRiderList<<<<<#{primaryRiderList.inspect}"

			riders.each do|rider|
				if (selectedSingleRider && selectedSingleRider.productSeq.to_s == rider.productSeq.to_s && selectedSingleRider.insuredPartyRefGuid.to_s == rider.insuredPartyRefGuid.to_s) || selectedSingleRider == nil
					if rider.productSeq and rider.productSeq != ""
						riderParty = quotation.getParty(rider)
						product = MobiSys::ProductUtil.getProduct(rider.productSeq)
						otherDetails = product.getOtherDetailsFacet.OfflineOtherDetailsList[0] if !product.getOtherDetailsFacet.nil?
						isWOP = false
						isWOP = true if otherDetails and otherDetails.isWOPFl == "YES"
						# next if isWOP

						if rider.productSeq==nil || rider.productSeq ==""
							next
						end

						if rider.product ==nil
							product = MobiSys::ProductUtil.getProduct(rider.productSeq)
							rider.product=product
						end


						premiumDetailsFacet = rider.product.getFacet("PREMIUMDETAILS")
						premiumDetailsDO = nil
						premiumDetails = nil
						# if(premiumDetailsFacet != nil)
						#   premiumDetailsDO =   premiumDetailsFacet.OfflinePremiumDetailsList[0]
						# end

						calculateTerm(quotation, rider)

						isWOP = isWOP(rider, quotation)

						if premiumDetailsFacet != nil
							premiumDetails =  premiumDetailsFacet.OfflinePremiumDetailsList[0]
						end

						if premiumDetails != nil
							premiumSAFlagBasedComputation(rider, quotation,premiumDetails, isWOP)
						end

						calculateRiderValues(quotation,rider,1)

						#comented for FWD
						if rider.productTerm !=nil && quotationProduct.productTerm !=nil
							#Rider term should be lesser than base plans term
							if rider.productTerm.to_i>quotationProduct.productTerm.to_i
								if  $rhoconfig[:new_validations_in_productbo]== 'YES'
									tempErrorHash= Hash.new
								else
									tempErrorHash = errors
								end
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "productTerm", "ERR_COMPAREVALUES", [ "RIDERTERM", rider.productTerm.to_i, "BASEPLANTERM", quotationProduct.productTerm.to_i])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-productTerm", "ERR_COMPAREVALUES", "ERR_COMPAREVALUES", nil,[ "RIDERTERM", rider.productTerm.to_i, "BASEPLANTERM", quotationProduct.productTerm.to_i])
								end
								unless $rhoconfig[:TABFEATUREREQD]
									if $rhoconfig[:moduleForProductValidations] == "Quotation"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
									if $rhoconfig[:moduleForProductValidations] == "Policy"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
								end
								isValid=false
							end
						end

						#No duplicate combination rows for Rider + Role and Supplementary lives in the rider section
						#if rider.partyRoleCd=="SUPPLEMENTARY" && rider.insuredPartyRefGuid!=nil
						#   riders.each do |supplyRider|
						#        if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						#            tempErrorHash= Hash.new
						#        else
						#            tempErrorHash = errors
						#        end
						#        if rider.guid!=supplyRider.guid && rider.productSeq==supplyRider.productSeq && rider.partyRoleCd==supplyRider.partyRoleCd && rider.insuredPartyRefGuid==supplyRider.insuredPartyRefGuid
						#           MobiSys::CommonUtil.addErrors(tempErrorHash, "productTypeCd", "ERR_RIDERSUPLIVEMAP", [quotationProduct.product.longName])
						#           isValid=false
						#        end
						#        if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						#            errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
						#            errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
						#            errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
						#        end
						#   end
						#end

						riderPrimaryDO = nil
						riders.each do |riderPrimary|
							if riderPrimary.productSeq == rider.productSeq and riderPrimary.partyRoleCd == "PRIMARY"
								riderPrimaryDO = riderPrimary
								riderPrimaryDO.product = MobiSys::ProductUtil.getProduct(riderPrimary.productSeq)
								break
							end
						end

						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end

						#Supplementary Life Applicability – Follow PL, Must Follow PL, N/A
						if riderAssociationHM.has_key?(rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s)
							lifeApplFL=riderAssociationHM[rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s].supplLifeAppl
						elsif riderAssociationHM.has_key?(rider.productSeq.to_s + "|")
							lifeApplFL=riderAssociationHM[rider.productSeq.to_s + "|"].supplLifeAppl
						end
						if rider.partyRoleCd=="SUPPLEMENTARY" && rider.insuredPartyRefGuid!=nil  && lifeApplFL!=nil
							party=quotation.getPartyByGuid(rider.insuredPartyRefGuid)
							if (lifeApplFL=="FOLLOWPL"|| lifeApplFL=="MUSTFOLLOWPL")  && party!=nil
								if !primaryRiderList.include?(rider.productSeq.to_s)
									#string1="Supplementary Life "
									#string1=string1 << party.firstname <<
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_FOLLOWPL", [ "Supplementary Life " + party.firstname + " " + party.lastname + " must",rider.product.longName])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "ERR_FOLLOWPL", "ERR_FOLLOWPL", nil,[ "Supplementary Life " + party.firstname + " " + party.lastname + " must",rider.product.longName])
									end
									isValid=false
								end
							end
						end

						if riderAssociationHM.has_key?(rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s)
							lifeApplFL=riderAssociationHM[rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s].jointLifeAppl
						elsif riderAssociationHM.has_key?(rider.productSeq.to_s + "|")
							lifeApplFL=riderAssociationHM[rider.productSeq.to_s + "|"].jointLifeAppl
						end
						if rider.partyRoleCd=="JOINT" && lifeApplFL!=nil
							if lifeApplFL=="FOLLOWPL"|| lifeApplFL=="MUSTFOLLOWPL"
								if !primaryRiderList.include?(rider.productSeq.to_s)
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_FOLLOWPL", [ "Joint Life " + quotation.getPartyByRole('JOINT').firstname + " " + quotation.getPartyByRole('JOINT').lastname + " must",rider.product.longName])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "ERR_FOLLOWPL", "ERR_FOLLOWPL", nil,[ "Joint Life " + quotation.getPartyByRole('JOINT').firstname + " " + quotation.getPartyByRole('JOINT').lastname + " must",rider.product.longName])
									end
									isValid=false
								end
							end
						end

						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
						#Follow changes here
						if rider.partyRoleCd == "SUPPLEMENTARY" or rider.partyRoleCd == "JOINT"
							facetDO = rider.product.getFacet("PLANOPTION")
							if facetDO
								planOptionDO = facetDO.getPlanOptionByPlanOptionCd(rider.productPlanOptionCd)
								if planOptionDO != nil && riderPrimaryDO != nil
									level = planOptionDO.levelNum
									riderPrimaryFacetDO = riderPrimaryDO.product.getFacet('PLANOPTION')
									if riderPrimaryFacetDO
										riderPrimaryPlanOptionDO = riderPrimaryFacetDO.getPlanOptionByPlanOptionCd(riderPrimaryDO.productPlanOptionCd)
										if riderPrimaryPlanOptionDO
											insuredLevel = riderPrimaryPlanOptionDO.levelNum
											if level and insuredLevel and level < insuredLevel
												if  $rhoconfig[:new_validations_in_productbo]== 'YES'
													tempErrorHash= Hash.new
												else
													tempErrorHash = errors
												end
												unless $rhoconfig[:TABFEATUREREQD]
													MobiSys::CommonUtil.addErrors(tempErrorHash, 'partyRoleCd', "CHECKLEVELPLANOPTION", [Localization::LabelCache.instance.getLabel(rider.partyRoleCd),planOptionDO.description,rider.product.longName, riderPrimaryPlanOptionDO.description])
												else
													MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "CHECKLEVELPLANOPTION", "CHECKLEVELPLANOPTION", nil,[Localization::LabelCache.instance.getLabel(rider.partyRoleCd),planOptionDO.description,rider.product.longName, riderPrimaryPlanOptionDO.description])
												end
												unless $rhoconfig[:TABFEATUREREQD]
													if $rhoconfig[:moduleForProductValidations] == "Quotation"
														if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
															errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
															errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
															errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
														end
													end
													if $rhoconfig[:moduleForProductValidations] == "Policy"
														if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
															errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
															errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
															errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
														end
													end
												end
											end
										end
									end
								end
							end
						end
						#Follow changes end

						#if rider association does not exist for the selected rider log an error and check the next
						if !riderAssociationHM.select{|k,v| k.include?(rider.productSeq.to_s)}
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_PRODUCT", [ "RIDER " + rider.product.longName])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "ERR_PRODUCT", "ERR_PRODUCT", nil,[ "RIDER " + rider.product.longName])
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
							isValid=false
							next
						end

						if riderAssociationHM.has_key?(rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s)
							rad = riderAssociationHM[rider.productSeq.to_s + "|" + rider.productPlanOptionCd.to_s]
						elsif riderAssociationHM.has_key?(rider.productSeq.to_s + "|")
							rad = riderAssociationHM[rider.productSeq.to_s + "|"]
						end
						if rider.baseSumAssured!=nil
							riderSA=rider.baseSumAssured
							if rad != nil && rad.saPercTableTypeMapSeq !=nil
								# DT call need to change
								definitionTable=getProductDefinitionTable(rad.saPercTableTypeMapSeq,quotation,quotationProduct,riderParty)
								if definitionTable !=nil
									if  $rhoconfig[:new_validations_in_productbo]== 'YES'
										tempErrorHash= Hash.new
									else
										tempErrorHash = errors
									end
									isValid = validateMinMaxValue(definitionTable, riderSA, quotation, rider, 'baseSumAssured', 'baseSumAssured', rider, tempErrorHash, nil, "MINMAXSUMASSURED", rad.getLabelKey("MINMAXSUMASSURED"))
									isValid = validateMultiple(quotation, definitionTable, riderSA,'baseSumAssured',tempErrorHash, rider) and isValid

									unless $rhoconfig[:TABFEATUREREQD]
										if $rhoconfig[:moduleForProductValidations] == "Quotation"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
										if $rhoconfig[:moduleForProductValidations] == "Policy"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
									end
								end
							end
						end

						if rider.modalPremium!=nil
							riderModalPremium=rider.modalPremium
							if rad != nil && rad.premiumPercTableTypeMapSeq !=nil
								#need to change
								definitionTable=getProductDefinitionTable(rad.premiumPercTableTypeMapSeq,quotation,quotationProduct,riderParty)
								if definitionTable!=nil
									if  $rhoconfig[:new_validations_in_productbo]== 'YES'
										tempErrorHash= Hash.new
									else
										tempErrorHash = errors
									end
									validateMinMaxValue(definitionTable, riderModalPremium, quotation, rider, 'modalPremium', 'modalPremium', rider, tempErrorHash, nil, "MINMAXMODALPREMIUM", rad.getLabelKey("MINMAXMODALPREMIUM"))

									unless $rhoconfig[:TABFEATUREREQD]
										if $rhoconfig[:moduleForProductValidations] == "Quotation"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
										if $rhoconfig[:moduleForProductValidations] == "Policy"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
									end
									isValid=false
								end
							end
						end
						if rider.productTerm !=nil
							term=rider.productTerm
							if rad != nil && rad.minMaxTermTableTypeMapSeq!=nil
								#need to cahngw
								definitionTable=getProductDefinitionTable(rad.minMaxTermTableTypeMapSeq,quotation,quotationProduct,riderParty)
								if definitionTable !=nil
									if  $rhoconfig[:new_validations_in_productbo]== 'YES'
										tempErrorHash= Hash.new
									else
										tempErrorHash = errors
									end
									validateMinMaxValue(definitionTable, term, quotation, rider, 'productTerm', 'productTerm', rider, tempErrorHash, nil, "MINMAXTERM", rad.getLabelKey("MINMAXTERM"))

									unless $rhoconfig[:TABFEATUREREQD]
										if $rhoconfig[:moduleForProductValidations] == "Quotation"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
										if $rhoconfig[:moduleForProductValidations] == "Policy"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
									end
									isValid=false
								end
							end
							if rad != nil && rad.termAsPlan=="YES" && quotationProduct.productTerm!=nil && quotationProduct.productTerm.to_f !=rider.productTerm.to_f
								if  $rhoconfig[:new_validations_in_productbo]== 'YES'
									tempErrorHash= Hash.new
								else
									tempErrorHash = errors
								end
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_CHECKRIDER", [ "PRODUCTTERM", MobiSys::BrowserHelper.renderNumber(term) ,rider.product.longName, quotationProduct.product.longName])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "ERR_CHECKRIDER", "ERR_CHECKRIDER", nil,[ "PRODUCTTERM", MobiSys::BrowserHelper.renderNumber(term) ,rider.product.longName, quotationProduct.product.longName])
								end
								unless $rhoconfig[:TABFEATUREREQD]
									if $rhoconfig[:moduleForProductValidations] == "Quotation"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
									if $rhoconfig[:moduleForProductValidations] == "Policy"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
								end
							end
						end

						if rider.premiumPayingTerm !=nil
							term=rider.premiumPayingTerm
							if rad != nil && rad.ppTermTableTypeMapSeq !=nil
								definitionTable=getProductDefinitionTable(rad.ppTermTableTypeMapSeq,quotation,quotationProduct,riderParty)
								if definitionTable !=nil
									if  $rhoconfig[:new_validations_in_productbo]== 'YES'
										tempErrorHash= Hash.new
									else
										tempErrorHash = errors
									end
									validateMinMaxValue(definitionTable, term, quotation, rider, 'premiumPayingTerm', 'premiumPayingTerm', rider, tempErrorHash, nil, "MINMAXPPTERM", rad.getLabelKey("MINMAXPPTERM"))

									unless $rhoconfig[:TABFEATUREREQD]
										if $rhoconfig[:moduleForProductValidations] == "Quotation"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
										if $rhoconfig[:moduleForProductValidations] == "Policy"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
												errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
											end
										end
									end
									isValid=false
								end
							end
							if rad != nil && rad.pptAsPlan !=nil && rad.pptAsPlan=="YES" && quotationProduct.premiumPayingTerm !=nil && quotationProduct.premiumPayingTerm.to_f != rider.premiumPayingTerm.to_f
								if  $rhoconfig[:new_validations_in_productbo]== 'YES'
									tempErrorHash= Hash.new
								else
									tempErrorHash = errors
								end
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "premiumPayingTerm", "ERR_CHECKRIDER", [ "premiumPayingTerm", MobiSys::BrowserHelper.renderNumber(term) ,rider.product.longName, quotationProduct.product.longName])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-premiumPayingTerm", "ERR_CHECKRIDER", "ERR_CHECKRIDER", nil,[ "premiumPayingTerm", MobiSys::BrowserHelper.renderNumber(term) ,rider.product.longName, quotationProduct.product.longName])
								end
								unless $rhoconfig[:TABFEATUREREQD]
									if $rhoconfig[:moduleForProductValidations] == "Quotation"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
									if $rhoconfig[:moduleForProductValidations] == "Policy"
										if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
											errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][rider.guid.to_sym].is_a?(Hash)
											errors[:PolicyProductDO][rider.guid.to_sym] = errors[:PolicyProductDO][rider.guid.to_sym].merge(tempErrorHash)
										end
									end
								end
								isValid=false
							end
						end

						subCategory=rider.product.productKey

						facetDetails=rider.product.getOtherDetailsFacet
						if facetDetails && facetDetails != ""
							otherDetails=facetDetails.OfflineOtherDetailsList[0]
							if otherDetails !=nil && otherDetails.isWOPFl=="YES"
								regulartopUpAmt=quotation.getRegularPolicyTopupAmt(1)
								if regulartopUpAmt <= 0 && (subCategory=="PAYORPLUS" || subCategory=="INSUREDPLUS" || subCategory=="FAMILYPLUS")
									if  $rhoconfig[:new_validations_in_productbo]== 'YES'
										tempErrorHash= Hash.new
									else
										tempErrorHash = errors
									end
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_INVALIDWOPTOPUPRIDER", [rider.product.longName, MobiSys::BrowserHelper.renderNumber(regulartopUpAmt)])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-partyRoleCd", "ERR_INVALIDWOPTOPUPRIDER", "ERR_INVALIDWOPTOPUPRIDER", nil,[rider.product.longName, MobiSys::BrowserHelper.renderNumber(regulartopUpAmt)])
									end
									unless $rhoconfig[:TABFEATUREREQD]
										if $rhoconfig[:moduleForProductValidations] == "Quotation"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
												errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
												errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
											end
										end
										if $rhoconfig[:moduleForProductValidations] == "Policy"
											if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
												errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
												errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
												errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
											end
										end
									end
									isValid=false
								end
							end
						end
					end
					break if selectedSingleRider
				end
			end

			#Deepali Singh: 09-03-2016 - Eliminating duplicate combination of rows for Rider, Role and lives in the rider section
			uniqueRiderForLifeHM = {}
			riders.each do |rider|
				if rider.partyRoleCd == "SUPPLEMENTARY"
					uniqueRiderForLifeHM[rider.insuredPartyRefGuid.to_s] = [] if uniqueRiderForLifeHM[rider.insuredPartyRefGuid.to_s] == nil
					uniqueRiderForLifeHM[rider.insuredPartyRefGuid.to_s].push rider.productSeq.to_s + rider.productPlanOptionCd.to_s
				else
					uniqueRiderForLifeHM[rider.partyRoleCd.to_s] = [] if uniqueRiderForLifeHM[rider.partyRoleCd.to_s] == nil
					uniqueRiderForLifeHM[rider.partyRoleCd.to_s].push rider.productSeq.to_s + rider.productPlanOptionCd.to_s
				end
			end
			quotation.QuotationPartyList.each do |quotationParty|
				if uniqueRiderForLifeHM[quotationParty.roleCd.to_s] != nil && (quotationParty.roleCd.to_s == "PRIMARY" || quotationParty.roleCd.to_s == "PROPOSER")
					duplicateRiders = uniqueRiderForLifeHM[quotationParty.roleCd.to_s].group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)
					if !duplicateRiders.empty?
						duplicateRiders.each do |dupRider|
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							riderproduct = ridersHM[dupRider]
							rider_product = MobiSys::ProductUtil.getProduct(riderproduct[0].productSeq)
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "productSeq", "ERR_COMPARERIDERS", [rider_product.longName, Localization::LabelCache.instance.getLabel(quotationParty.roleCd.to_s)])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-productSeq", "ERR_COMPARERIDERS", "ERR_COMPARERIDERS", nil,[rider_product.longName, Localization::LabelCache.instance.getLabel(quotationParty.roleCd.to_s)])
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
						end
					end
				elsif uniqueRiderForLifeHM[quotationParty.guid.to_s] != nil && quotationParty.roleCd.to_s == "SUPPLEMENTARY"
					duplicateRiders = uniqueRiderForLifeHM[quotationParty.guid.to_s].group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)
					if !duplicateRiders.empty?
						duplicateRiders.each do |dupRider|
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							riderproduct = ridersHM[dupRider]
							rider_product = MobiSys::ProductUtil.getProduct(riderproduct[0].productSeq)
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "isRiderUnique", "ERR_COMPARERIDERS", [rider_product.longName, Localization::LabelCache.instance.getLabel(quotationParty.roleCd.to_s)])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-isRiderUnique", "ERR_COMPARERIDERS", "ERR_COMPARERIDERS", nil,[rider_product.longName, Localization::LabelCache.instance.getLabel(quotationParty.roleCd.to_s)])
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
						end
					end
				end
			end

			if quotationProduct.product != nil && (quotationProduct.product.getFacetValue("RIDERAUTOPOPULATIONREQUIRED").to_s == "YES" && quotationProduct.product.getFacetValue("DISABLERIDERASSOCIATIONVALIDATION").to_s != "YES") || quotationProduct.product.getFacetValue("RIDERAUTOPOPULATIONREQUIRED").to_s != "YES"
				isValid = validateRiderAssociation(quotation, quotationProduct, riderAssociation, ridersHM, errors)
			end
			isValid = validateSupplementaryRiders(quotation,quotationProduct,errors) && isValid
			return isValid
		end
		###################################################################################################


		def self.validateRiderAssociation(quotation, quotationProduct, riderAssociation, ridersHM, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			basePlan = quotation.getBasePlan
			#new riderAssociation code: Anubhaw
			riderAssociation.each do |rad|
				defTableDO = nil
				isByDefaultOptional = true
				listDefinitionTable = nil
				productId = MobiSys::ProductUtil.getProduct(rad.productSeq)
				if rad.associationRelationTTmapSeq != nil
					#get all the records matching to the TT before evaluating the DT as we need to check for instance of even one DT as optional
					# set some field of rider assosiation to current rider product
					basePlanOptionMatched = true
					if rad.basePlanOptionCd.to_s != '' && basePlan.productPlanOptionCd.to_s != '' && rad.basePlanOptionCd != basePlan.productPlanOptionCd
						basePlanOptionMatched = false
					end
					if !basePlanOptionMatched
						next
					end
					#get all the records matching to the TT before evaluating the DT as we need to check for instance of even one DT as optional
					# planOptionMatched = true
					#ppdRiderCm = nil
					# ppdRiderDO = ridersHM[rad.productSeq.to_s + rad.planOptionCd.to_s]
					# if ppdRiderDO!=nil && ppdRiderDO.size > 0
					# 	ppdRiderCm=ppdRiderDO[0]
					# end
					if ridersHM[rad.productSeq.to_s] != nil && ridersHM[rad.productSeq.to_s].size > 0
						ridersHM[rad.productSeq.to_s].each do |ppdRiderDO|
							planOptionMatched = true
							ppdRiderCm = nil
							if ppdRiderDO
								ppdRiderCm = ppdRiderDO
								if rad.planOptionCd.to_s != "" && ppdRiderCm.productPlanOptionCd.to_s != ""
									if rad.planOptionCd == ppdRiderCm.productPlanOptionCd
										planOptionMatched = true
									else
										planOptionMatched = false
									end
                               	end
	                        end
	                        if planOptionMatched
	                        	validationRiderMandatory(rad, quotation, quotationProduct, ppdRiderCm,  ridersHM, errors)
	                        end
						end
						# if rad.planOptionCd.to_s != "" && ridersHM[rad.productSeq.to_s][0].productPlanOptionCd != ""
						# 	if ridersHM[rad.productSeq.to_s][0].productPlanOptionCd.to_s == rad.planOptionCd.to_s
						# 		planOptionMatched = true
						# 	else
						# 		planOptionMatched = false
						# 	end
						# end
					else
						validationRiderMandatory(rad, quotation, quotationProduct, nil, ridersHM, errors)
					end

					#Moved entire code below to new method validateRiderMandatory
					# if ppdRiderDO!=nil && ppdRiderDO.size()>0 ##&& lhmPolicyProductRiders.get(rad.getProductSeq())!=null){
					# #for(PolicyProductDO ppdRiderDO:lhmPolicyProductRiders.get(rad.getProductSeq())){

					# 	ppdRiderDO.each  do |ppdrider|
					# 		# if ppdRiderDO!=nil && ppdRiderDO.size > 0
					# 			#  ppdRiderCm=ppdRider
					# 		# end
					# 		if ppdrider != nil #&& ridersHM[rad.productSeq.to_s + rad.productPlanOptionCd.to_s].size > 0
					# 			if rad.planOptionCd.to_s != "" && ppdrider.productPlanOptionCd != "" && ppdrider.productPlanOptionCd.to_s != rad.planOptionCd.to_s
					# 				planOptionMatched = false
					# 			end
					# 		end
					# 		#last three values are java. need to check ruby equivalent
					# 		if planOptionMatched
					# 			primaryPartyDO = quotation.getPartyByRole("PRIMARY") #Need to confirm about Quotation
					# 			policyProductInsuredDO = quotationProduct.getInsuredByRole("PRIMARY") #Need to confirm about quotationProduct
					# 			if ppdrider != nil # && ridersHM[rad.productSeq.to_s + rad.productPlanOptionCd.to_s].size > 0
					# 				policyProductInsuredDO = ppdrider
					# 				primaryPartyDO=quotation.getPartyByGuid(policyProductInsuredDO.insuredPartyRefGuid)
					# 				defTableDO = getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct,primaryPartyDO)
					# 			else
					# 				defTableDO = getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct,primaryPartyDO)
					# 			end
					# 			# p "defTableDO++++++++++#{defTableDO}"
					# 			if defTableDO != nil
					# 				if "MANDATORY" == defTableDO.associationRelationCd
					# 					ridersHMKeys = []
					# 					ridersHMKeys = ridersHM.keys
					# 					ridersHMKeys = ridersHMKeys.map { |e| e.to_s }
					# 					# blnMandatory = ridersHMKeys.include? (rad.productSeq.to_s)
					# 					blnMandatory = ridersHMKeys.find {|k| k.include? (rad.productSeq.to_s) }
					# 					if !blnMandatory
					# 						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 							tempErrorHash= Hash.new
					# 						else
					# 							tempErrorHash = errors
					# 						end
					# 						if(defTableDO.riderProductId.to_s != "")
					# 							riderProductIdList = defTableDO.riderProductId.split(",")
					# 							mandatoryRiderProductId = ""
					# 							riderProductIdList.each do |riderProductId|
					# 								riderProductId = Product.loadObject(:first, :conditions => {{ :name => 'productId' } => riderProductId.to_s})
					# 								mandatoryRiderProductId=mandatoryRiderProductId + riderProductId.longName.to_s + ","
					# 							end
					# 							if(mandatoryRiderProductId.end_with? ",")
					# 								mandatoryRiderProductId = mandatoryRiderProductId[0,mandatoryRiderProductId.length - 1]
					# 							end
					# 							mandatoryRiderProductId = quotationProduct.product.longName if mandatoryRiderProductId.to_s == ""
					# 							MobiSys::CommonUtil.addErrors(tempErrorHash,"productSeq","ERR_RIDERMANDATORY",[productId.longName, mandatoryRiderProductId, quotation.entityDesc.to_s])
					# 							isValid=false
					# 							next
					# 						else
					# 							MobiSys::CommonUtil.addErrors(tempErrorHash,"productSeq","ERR_CHECKRIDERMANDATORY",[MobiSys::BrowserHelper.getLabel('RIDER') << " " << productId.longName, quotation.entityDesc.to_s])
					# 							isValid=false
					# 						end
					# 						if $rhoconfig[:moduleForProductValidations] == "Quotation"
					# 							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 								errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
					# 								errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
					# 								errors[:QuotationDO][quotation.guid.to_sym]["productId"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["productId"].is_a?(Array)
					# 								errors[:QuotationDO][quotation.guid.to_sym]["productId"].push(tempErrorHash["productId"])
					# 							end
					# 						end
					# 						if $rhoconfig[:moduleForProductValidations] == "Policy"
					# 							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 								errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
					# 								errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
					# 								errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
					# 							end
					# 						end

					# 					end

					# 					#if rider found then compare that the role of the rider matches that of the mandatory rider associaton role
					# 					roleMatchFound = false
					# 					if defTableDO.partyRoleCd != nil && defTableDO.partyRoleCd != ""
					# 						dtPartyRoles = defTableDO.partyRoleCd.split(",")

					# 						ridersHM[rad.productSeq.to_s + rad.productPlanOptionCd.to_s].each do |ppRider|
					# 							rad.productId = ppRider.productId
					# 							if dtPartyRoles.include? ppRider.partyRoleCd
					# 								roleMatchFound = true
					# 								break
					# 							end
					# 						end

					# 						exceptionCd = defTableDO.riderProductId ? "ERR_RIDERMANDATORY" : "ERR_MANDATORY"

					# 						unless roleMatchFound
					# 							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 								tempErrorHash= Hash.new
					# 							else
					# 								tempErrorHash = errors
					# 							end
					# 							MobiSys::CommonUtil.addErrors(tempErrorHash, 'productId', exceptionCd, [Localization::LabelCache.instance.getLabel(rad.productId), Localization::LabelCache.instance.getLabel(defTableDO.riderProductId)])
					# 							if $rhoconfig[:moduleForProductValidations] == "Quotation"
					# 								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 									errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
					# 									errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
					# 									errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
					# 								end
					# 							end
					# 							if $rhoconfig[:moduleForProductValidations] == "Policy"
					# 								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 									errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
					# 									errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
					# 									errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
					# 								end
					# 							end
					# 							isValid=false
					# 						end
					# 					end
					# 				end#//if DT has not been evaluated ,record is found defined as optional and Policy still contains the selected Rider then we need to raise an error

					# 			elsif defTableDO == nil
					# 				listDefinitionTable = MobiSys::ProductUtil.loadProductDefinitionTableListByTableTypeMappingSeq(rad.associationRelationTTmapSeq, false) #Need to confirm method
					# 				# p "listDefinitionTable+++++++++#{listDefinitionTable}"
					# 				if listDefinitionTable != nil
					# 					#if even one record is found defined as optional .. it implies that rider is optional only under certain conditions..
					# 					#else by default consider it as optional.//User would not define all possible combinations for rider to be optional .. if it is always optional.
					# 					listDefinitionTable.each do |defnTableDOInList|
					# 						if defnTableDOInList.associationRelationCd == "OPTIONAL" or defnTableDOInList.associationRelationCd == "OPTIONALDEFAULT"
					# 							isByDefaultOptional = false
					# 							break
					# 						end
					# 					end
					# 				end
					# 				productObj = MobiSys::ProductUtil.getProduct(rad.productSeq)
					# 				# p "isByDefaultOptional: #{isByDefaultOptional}"
					# 				if ridersHM.include?(rad.productSeq.to_s + rad.productPlanOptionCd.to_s) and !isByDefaultOptional
					# 					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 						tempErrorHash= Hash.new
					# 					else
					# 						tempErrorHash = errors
					# 					end
					# 					exceptionCd = "ERR_INVALIDRIDER"
					# 					if rad.getLabelKey("VALIDATERIDERRELATION").to_s != ""
					# 						exceptionCd = rad.getLabelKey("VALIDATERIDERRELATION")
					# 					end
					# 					MobiSys::CommonUtil.addErrors(tempErrorHash, 'productId',exceptionCd,["#{Localization::LabelCache.instance.getLabel("rider")} #{Localization::LabelCache.instance.getLabel(productObj.longName)}"])
					# 					isValid=false

					# 					if $rhoconfig[:moduleForProductValidations] == "Quotation"
					# 						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 							errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
					# 							errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
					# 							errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
					# 						end
					# 					end
					# 					if $rhoconfig[:moduleForProductValidations] == "Policy"
					# 						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					# 							errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
					# 							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
					# 							errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					# 						end
					# 					end
					# 				end
					# 			end
					# 		end
					# 	end
					# end
				end
			end
			return isValid
		end
		################################################################################################
		def self.validateSupplementaryRiders(quotation, quotationProduct, errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			#If Supplementary lives are entered, then atleast one rider should be entered for each supplementary lives
			#for multi life scenario validate that lives exist for at least one baseplan. i..e PLANMULTI
			quot_prod = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
			supplifreFacet = quot_prod.getFacet("SUPPLIFERIDEROPTIONAL")
			if (supplifreFacet == nil) || (supplifreFacet != nil && supplifreFacet.actionValue == "NO")
				supplemetaryLives = quotation.getPartyListByRoleCd("SUPPLEMENTARY")
				supplemetaryLives.each do |supLife|
					mapingExist = false
					quotation.QuotationProductList.each do |quotProd|
						if quotProd.partyRoleCd == "SUPPLEMENTARY" && quotProd.insuredPartyRefGuid == supLife.guid && quotProd.selected == "YES"
							mapingExist = true
							break
						end
					end
					if !mapingExist && supLife.removed != "YES"
						firstNameField = "firstName"
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, 'riderCount',"ERR_SUPPLYRIDERMAPMAND",[supLife.firstname.to_s + " " + supLife.lastname.to_s])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-riderCount", "ERR_SUPPLYRIDERMAPMAND", "ERR_SUPPLYRIDERMAPMAND", nil,[supLife.firstname.to_s + " " + supLife.lastname.to_s])
						end

						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
						isValid=false
					end
				end
			end
			return isValid
		end


		def self.validationRiderMandatory(rad, quotation, quotationProduct, ppdrider=nil, ridersHM, errors)
			return true unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			isByDefaultOptional = true
			productId = MobiSys::ProductUtil.getProduct(rad.productSeq)
			primaryPartyDO = quotation.getPartyByRole("PRIMARY")
			if ppdrider != nil
				primaryPartyDO = quotation.getParty(ppdrider)
				defTableDO = getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct,primaryPartyDO)
			else
				defTableDO = getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct,primaryPartyDO)
			end
			if defTableDO != nil
				if "MANDATORY" == defTableDO.associationRelationCd
					ridersHMKeys = []
					ridersHMKeys = ridersHM.keys
					ridersHMKeys = ridersHMKeys.map { |e| e.to_s }
					# blnMandatory = ridersHMKeys.include? (rad.productSeq.to_s)
					blnMandatory = ridersHMKeys.find {|k| k.include? (rad.productSeq.to_s) }
					if !blnMandatory
						if  $rhoconfig[:new_validations_in_productbo]== 'YES'
							tempErrorHash= Hash.new
						else
							tempErrorHash = errors
						end
						if(defTableDO.riderProductId.to_s != "")
							riderProductIdList = defTableDO.riderProductId.split(",")
							mandatoryRiderProductId = ""
							riderProductIdList.each do |riderProductId|
								riderProductId = Product.loadObject(:first, :conditions => {{ :name => 'productId' } => riderProductId.to_s})
								mandatoryRiderProductId=mandatoryRiderProductId + riderProductId.longName.to_s + ","
							end
							if(mandatoryRiderProductId.end_with? ",")
								mandatoryRiderProductId = mandatoryRiderProductId[0,mandatoryRiderProductId.length - 1]
							end
							mandatoryRiderProductId = quotationProduct.product.longName if mandatoryRiderProductId.to_s == ""
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash,"productSeq","ERR_RIDERMANDATORY",[productId.longName, mandatoryRiderProductId, quotation.entityDesc.to_s])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productSeq", "ERR_RIDERMANDATORY", "ERR_RIDERMANDATORY", nil,[productId.longName, mandatoryRiderProductId, quotation.entityDesc.to_s])
							end
							isValid=false
						else
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash,"productSeq","ERR_CHECKRIDERMANDATORY",[MobiSys::BrowserHelper.getLabel('RIDER') << " " << productId.longName, quotation.entityDesc.to_s])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productSeq", "ERR_CHECKRIDERMANDATORY", "ERR_CHECKRIDERMANDATORY", nil,[MobiSys::BrowserHelper.getLabel('RIDER') << " " << productId.longName, quotation.entityDesc.to_s])
							end
							isValid=false
						end
						unless $rhoconfig[:TABFEATUREREQD]
							if $rhoconfig[:moduleForProductValidations] == "Quotation"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:QuotationDO][quotation.guid.to_sym]["productSeq"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["productSeq"].is_a?(Array)
									errors[:QuotationDO][quotation.guid.to_sym]["productSeq"].push(tempErrorHash["productSeq"])
								end
							end
							if $rhoconfig[:moduleForProductValidations] == "Policy"
								if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
									errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
									errors[:PolicyDO][quotation.guid.to_sym]["productSeq"] = Array.new if !errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].is_a?(Array)
									errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].push(tempErrorHash["productSeq"])
								end
							end
						end
					end

					#if rider found then compare that the role of the rider matches that of the mandatory rider associaton role
					roleMatchFound = false
					if defTableDO.partyRoleCd != nil && defTableDO.partyRoleCd != "" && ridersHM[rad.productSeq.to_s + rad.planOptionCd.to_s] != nil
						dtPartyRoles = defTableDO.partyRoleCd.split(",")

						ridersHM[rad.productSeq.to_s + rad.planOptionCd.to_s].each do |ppRider|
							rad.productId = ppRider.productId
							if dtPartyRoles.include? ppRider.partyRoleCd
								roleMatchFound = true
								break
							end
						end

						exceptionCd = defTableDO.riderProductId ? "ERR_RIDERMANDATORY" : "ERR_MANDATORY"

						unless roleMatchFound
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, 'productSeq', exceptionCd, [Localization::LabelCache.instance.getLabel(rad.productId), Localization::LabelCache.instance.getLabel(defTableDO.riderProductId)])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productSeq", exceptionCd, exceptionCd, nil,[Localization::LabelCache.instance.getLabel(rad.productId), Localization::LabelCache.instance.getLabel(defTableDO.riderProductId)])
							end

							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym]["productId"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["productId"].is_a?(Array)
										errors[:QuotationDO][quotation.guid.to_sym]["productId"].push(tempErrorHash["productId"])
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym]["productSeq"] = Array.new if !errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].is_a?(Array)
										errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].push(tempErrorHash["productSeq"])
									end
								end
							end
							isValid=false
						end
					end
				end#//if DT has not been evaluated ,record is found defined as optional and Policy still contains the selected Rider then we need to raise an error

			elsif defTableDO == nil
				listDefinitionTable = MobiSys::ProductUtil.loadProductDefinitionTableListByTableTypeMappingSeq(rad.associationRelationTTmapSeq, false) #Need to confirm method
				# p "listDefinitionTable+++++++++#{listDefinitionTable}"
				if listDefinitionTable != nil
					#if even one record is found defined as optional .. it implies that rider is optional only under certain conditions..
					#else by default consider it as optional.//User would not define all possible combinations for rider to be optional .. if it is always optional.
					listDefinitionTable.each do |defnTableDOInList|
						if defnTableDOInList.associationRelationCd == "OPTIONAL" or defnTableDOInList.associationRelationCd == "OPTIONALDEFAULT"
							isByDefaultOptional = false
							break
						end
					end
				end
				productObj = MobiSys::ProductUtil.getProduct(rad.productSeq)
				# p "isByDefaultOptional: #{isByDefaultOptional}"
				# if ridersHM.include?(rad.productSeq.to_s) and !isByDefaultOptional
				if ((rad.planOptionCd.to_s == "" && ridersHM.keys.select{|y| /^#{rad.productSeq}{1}(?![0-9])/.match(y)}.size > 0) || (rad.planOptionCd.to_s != "" && ridersHM.keys.select{|y| /^#{rad.productSeq}{1}#{rad.planOptionCd}{1}/.match(y)}.size > 0)) and !isByDefaultOptional
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					exceptionCd = "ERR_INVALIDRIDER"
					if rad.getLabelKey("VALIDATERIDERRELATION").to_s != ""
						exceptionCd = rad.getLabelKey("VALIDATERIDERRELATION")
					end

					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, 'productId',exceptionCd,["#{Localization::LabelCache.instance.getLabel("rider")} #{Localization::LabelCache.instance.getLabel(productObj.longName)}", primaryPartyDO.getEntityDesc])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-productSeq", exceptionCd, exceptionCd, nil,["#{Localization::LabelCache.instance.getLabel("rider")} #{Localization::LabelCache.instance.getLabel(productObj.longName)}", primaryPartyDO.getEntityDesc])
					end
					isValid=false

					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym]["productId"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["productId"].is_a?(Array)
								errors[:QuotationDO][quotation.guid.to_sym]["productId"].push(tempErrorHash["productId"])
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym]["productSeq"] = Array.new if !errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].is_a?(Array)
								errors[:PolicyDO][quotation.guid.to_sym]["productSeq"].push(tempErrorHash["productSeq"])
							end
						end
					end
				end
			end
		end
		################################################################################################


		def self.getRiderCombination(rider,quotation,quotationProduct)
			return true unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiders",$rhoconfig[:moduleForProductValidations])
			flag = false

			offlineFacet=quotationProduct.product.getFacet("RIDERASSOCIATION")
			if offlineFacet!=nil
				riderAssociationList=offlineFacet.OfflineRiderAssociationList
			end

			if riderAssociationList and riderAssociationList != ""
				riderAssociationList.each do |rad|

					if rad.saPercTableTypeMapSeq !=nil
						# DT call need to change
						definitionTable=getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct)
						if definitionTable !=nil
							if listPolicyProductRiders
								listPolicyProductRiders.each do |ppd|
									if definitionTable.associationRelationCd == "EXCLUSIVE"
										if ppd.productId == rad.productId
											flag = true
										end
									end
								end
							end
						end
					end
				end
			end

			if flag
				if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "partyRoleCd", "ERR_RIDER_EXCLUSIVE", [rad.productId])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-partyRoleCd", "ERR_RIDER_EXCLUSIVE", "ERR_RIDER_EXCLUSIVE", nil,[rad.productId])
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if $rhoconfig[:moduleForProductValidations] == "Quotation"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
							errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
							errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
						end
					end
					if $rhoconfig[:moduleForProductValidations] == "Policy"
						if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
							errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
							errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
							errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
		end
		###################################################################################################


		def self.validateRiderGroupDefinition(quotation, quotationProduct, riderAssociation, riderGroupDefinition, quotePartyList, msg,  errors)
			isValid = true
			return isValid unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateRiderGroupDefinition",$rhoconfig[:moduleForProductValidations])
			riders = quotation.getRiders
			basePlan = quotation.getBasePlan()
			riderGroupHM = Hash.new
			riderAssociation.each do|rad|
				basePlanOptionMatched = true
				if rad.basePlanOptionCd.to_s != '' && basePlan.productPlanOptionCd.to_s != '' && rad.basePlanOptionCd.to_s != basePlan.productPlanOptionCd.to_s
					basePlanOptionMatched = false
				end
				if rad.groupId.to_s != "" && basePlanOptionMatched
					if getProductDefinitionTable(rad.associationRelationTTmapSeq,quotation,quotationProduct) != nil
						groups = rad.groupId.to_s.split(",")
						groups.each do |groupId|  #I,II,III
							riders.each do |rider|
								planOptionMatched = true
								if rider.productSeq.to_i == rad.productSeq.to_i && rider.removed != "YES"
									if rad.planOptionCd.to_s != "" && rider.productPlanOptionCd.to_s != "" && rad.planOptionCd.to_s != rider.productPlanOptionCd.to_s
										### add plan option condition while creating group
										planOptionMatched = false
									end
									if planOptionMatched
										##set some field of rider assosiation to current rider product
										quotationProduct.linkedFl = rad.linkedFl
										quotationProduct.parentproductSeq = rad.parentproductSeq
										if riderGroupHM.has_key?(groupId.to_s.upcase)
											#Added this extra condition to push rider into hash only if it not already present in hash
											# if !(riderGroupHM[groupId.to_s.upcase].include? rider)
												riderGroupHM[groupId.to_s.upcase].push(rider)
											# end
										else
											policyProductList = Array.new
											policyProductList.push(rider)
											riderGroupHM[groupId.to_s.upcase] = policyProductList
										end
									end
								end
							end
							riderGroupHM[groupId.to_s.upcase] = [] unless riderGroupHM.has_key?(groupId.to_s.upcase)
						end
					end
				end
			end

			unless riderGroupHM.empty?
				riderGroupDefinition.each do |groupDef|
					if riderGroupHM.has_key?(groupDef.groupId.to_s.upcase)
						quotePartyList.each do |quoteParty|
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							totalGroupSA = 0.0
							isRiderTaken = false
							riderCount = 0
							if riderGroupHM.has_key?(groupDef.groupId.to_s.upcase) && riderGroupHM[groupDef.groupId.to_s.upcase].size > 0
								riderGroupHM[groupDef.groupId.to_s.upcase].each do |productRider|
									if(quoteParty.roleCd=="PROPCUMINS" && (productRider.partyRoleCd=="PRIMARY" || productRider.partyRoleCd=="PROPOSER" )) && quoteParty.roleCd==productRider.partyRoleCd ||
										((quoteParty.roleCd=="PRIMARY" || quoteParty.roleCd=="PROPOSER" || quoteParty.roleCd=="JOINT") && quoteParty.roleCd==productRider.partyRoleCd)||
										(quoteParty.roleCd=="SUPPLEMENTARY" && quoteParty.roleCd==productRider.partyRoleCd && quoteParty.uniqueKey==productRider.insuredPartyRefGuid)
										riderCount = riderCount+1
										isRiderTaken = true
										if productRider.baseSumAssured.to_s != ""
											totalGroupSA = totalGroupSA+productRider.baseSumAssured.to_f
										end
									end
								end
							end


							#Swati Ahire 28-09-2014: Replaced Group Definition ID with rider name
							groupName = Lookupvalue.loadObject(:first, :conditions => {{ :name => 'key'} => 'GROUPID', {:name => 'cd'} => groupDef.groupId.to_s}, :op => 'AND')
							groupName = Lookupvalue.new(:cd => groupDef.groupId.to_s, :desc => groupDef.groupId.to_s) unless groupName

							if groupDef.minRider.to_s != "" && !(riderCount>=groupDef.minRider) && groupDef.roleCd.to_s != ""
								if (groupDef.roleCd.include?('PROPCUMINS') && quotation.proposerLASame=="COPYFROMINSURED" && quoteParty.roleCd=="PRIMARY") || groupDef.roleCd.include?(quoteParty.roleCd)
									exceptionCd = "ERR_MINRIDER"
									if groupDef.getLabelKey("MINMAXRIDER").to_s != ""
										exceptionCd = groupDef.getLabelKey("MINMAXRIDER")
									elsif LabelValue.getLabel("ERR_MINRIDER_MIN", Application.getValue('DEFAULTLOCALE')) != ""
										exceptionCd = "ERR_MINRIDER_MIN"
									end
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "productIdAtleast", exceptionCd, [groupName.desc.to_s, MobiSys::BrowserHelper.renderNumber(groupDef.minRider),groupDef.roleCd,MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-productIdAtleast", exceptionCd, exceptionCd, nil,[groupName.desc.to_s, MobiSys::BrowserHelper.renderNumber(groupDef.minRider),groupDef.roleCd,MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
									end
									isValid = false
								end
							end

							if groupDef.maxRider.to_s != "" && !(riderCount<=groupDef.maxRider) && groupDef.roleCd.to_s != ""
								if (groupDef.roleCd.include?('PROPCUMINS') && quotation.proposerLASame=="COPYFROMINSURED" && quoteParty.roleCd=="PRIMARY") || groupDef.roleCd.include?(quoteParty.roleCd)
									exceptionCd = "ERR_MAXRIDER"
									if groupDef.getLabelKey("MINMAXRIDER").to_s != ""
										exceptionCd = groupDef.getLabelKey("MINMAXRIDER")
									elsif LabelValue.getLabel("ERR_MAXRIDER_MAX", Application.getValue('DEFAULTLOCALE')) != ""
										exceptionCd = "ERR_MAXRIDER_MAX"
									end
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "productIdAtleast", exceptionCd, [groupName.desc.to_s, MobiSys::BrowserHelper.renderNumber(groupDef.maxRider),quoteParty.roleCd,MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-productIdAtleast", exceptionCd, exceptionCd, nil,[groupName.desc.to_s, MobiSys::BrowserHelper.renderNumber(groupDef.maxRider),quoteParty.roleCd,MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
									end
									isValid = false
								end
							end

							if isRiderTaken
								saflatAmountPercentFl = groupDef.saflatAmountPercentFl
								if saflatAmountPercentFl.to_s == ''
									saflatAmountPercentFl = "FLATAMT"
								end
								if saflatAmountPercentFl.to_s != ''
									definitionTable = nil
									if(groupDef.minMaxTTSeq != nil)
										definitionTable = MobiSys::ProductUtil.getProductDefinitionTableDO(groupDef.minMaxTTSeq, quotation, quotationProduct)
									end
									if definitionTable != nil
										if saflatAmountPercentFl == "FLATAMT"
											# flat group SA
											prod = quotationProduct.product.getFacet("SALABEL")
		    								labelKey = (prod.nil?) ? 'baseSumAssured' : prod.actionValue
											sALabel = MobiSys::BrowserHelper.getLabel(labelKey)
											label = MobiSys::BrowserHelper.getLabel('Total') + " " + sALabel + " "+ MobiSys::BrowserHelper.getLabel('for') + " " + MobiSys::BrowserHelper.getLabel(groupName.desc.to_s) + " " + MobiSys::BrowserHelper.getLabel('Riders for') + " " + MobiSys::BrowserHelper.getLabel(quoteParty.roleCd.to_s) + " " + MobiSys::BrowserHelper.getLabel('insured') + " " + quoteParty.getFullName

											isValid = validateMinMaxValue(definitionTable, totalGroupSA, quotation, quotationProduct, label, 'genericColumn', quotationProduct, tempErrorHash, nil, nil, groupDef.getLabelKey("MINMAXSUMASSURED"))
										elsif saflatAmountPercentFl == "PERCENTAGE" && quotationProduct.baseSumAssured.to_s != ""
											if definitionTable.minValue != nil
												minPercentSA = (definitionTable.minValue.to_f * quotationProduct.baseSumAssured.to_f / 100)
												exceptionCd = "ERR_MINSA"
												if groupDef.getLabelKey("MINMAXSUMASSURED").to_s != ""
													exceptionCd = groupDef.getLabelKey("MINMAXSUMASSURED")
												end
												if totalGroupSA.to_f < minPercentSA
													unless $rhoconfig[:TABFEATUREREQD]
														MobiSys::CommonUtil.addErrors(tempErrorHash, "baseSumAssured", exceptionCd, [groupDef.groupId, MobiSys::BrowserHelper.renderNumber(minPercentSA), quoteParty.roleCd, MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
													else
														MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-baseSumAssured", exceptionCd, exceptionCd, nil,[groupDef.groupId, MobiSys::BrowserHelper.renderNumber(minPercentSA), quoteParty.roleCd, MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
													end
													isValid = false
												end
											end
											if definitionTable.maxValue != nil
												maxPercentSA = definitionTable.maxValue.to_f * quotationProduct.baseSumAssured.to_f / 100
												exceptionCd = "ERR_MAXSA"
												if groupDef.getLabelKey("MINMAXSUMASSURED").to_s != ""
													exceptionCd = groupDef.getLabelKey("MINMAXSUMASSURED")
												end
												if totalGroupSA.to_f > maxPercentSA
													unless $rhoconfig[:TABFEATUREREQD]
														MobiSys::CommonUtil.addErrors(tempErrorHash, "baseSumAssured", exceptionCd, [groupDef.groupId, MobiSys::BrowserHelper.renderNumber(maxPercentSA), quoteParty.roleCd, MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
													else
														MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-baseSumAssured", exceptionCd, exceptionCd, nil,[groupDef.groupId, MobiSys::BrowserHelper.renderNumber(maxPercentSA), quoteParty.roleCd, MobiSys::BrowserHelper.checkNil(quoteParty.firstname)+ " " + MobiSys::BrowserHelper.checkNil(quoteParty.lastname)])
													end
													isValid = false
												end
											end
										end
									end
								end
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
						end
					end
				end
			end
			return isValid
		end
		###################################################################################################


		def self.formRiderGroupStringAnd(riders)
			returnVal = ""
			riders.each_with_index do |rider, index|
				returnVal << rider
				if index < riders.length - 1
					returnVal << " " << Localization::LabelCache.instance.getLabel("AND".to_sym) << " "
				end
			end

			if riders.size > 1
				returnVal << " " << Localization::LabelCache.instance.getLabel("TOGETHER".to_sym)
			end

			return returnVal
		end
		###################################################################################################


		def self.formRiderGroupStringOr(riders)
			returnVal = ""
			riders.each_with_index do |rider, index|
				returnVal << rider
				if index < riders.length - 1
					returnVal << " " << Localization::LabelCache.instance.getLabel("OR".to_sym) << " "
				end
			end

			return returnVal
		end
		###################################################################################################


		def self.implementPlanCode(quotationProduct, age)
			if quotationProduct.planCode != nil
				@sql = ""
				@sql << " select * from ProductDefinitionTable where facetId = 'PLANCODEDERIVATION' and planCd = '"
				@sql << quotationProduct.planCode
				@sql << "'"

				@productDefinitionTables = nil
				@productDefinitionTables = ProductDefinitionTable.find_by_sql(@sql)

				if @productDefinitionTables.length >0

					if @productDefinitionTables[0].term != nil
						# handle to ages
						if @productDefinitionTables[0].term[0] == "T"
							quotationProduct.productTerm = @productDefinitionTables[0].term[1..-1].to_i - age.to_i
						else
							quotationProduct.productTerm = @productDefinitionTables[0].term
						end
					else
						quotationProduct.productTerm = 1 if quotationProduct.productTerm == nil or quotationProduct.productTerm == ""
					end

					if @productDefinitionTables[0].ppTerm != nil
						# handle to ages
						if @productDefinitionTables[0].ppTerm[0] == "T"
							quotationProduct.premiumPayingTerm = @productDefinitionTables[0].ppTerm[1..-1].to_i - age.to_i
						else
							quotationProduct.premiumPayingTerm = @productDefinitionTables[0].ppTerm
						end
					else
						quotationProduct.premiumPayingTerm = 1 if quotationProduct.premiumPayingTerm == nil or quotationProduct.premiumPayingTerm == ""
					end

					if @productDefinitionTables[0].planOptionCd != nil
						quotationProduct.productPlanOptionCd = @productDefinitionTables[0].planOptionCd
					end
				end
			end
		end
		###################################################################################################


		def self.derivePlanCode(quotationProduct)
			@sql = ""
			@sql << " select * from ProductDefinitionTable where facetId = 'PLANCODEDERIVATION' "

			if quotationProduct.productId != nil
				@sql << "and productId = '"
				@sql << quotationProduct.productId
				@sql << "' "
			end

			if quotationProduct.productPlanOptionCd != nil
				@sql << "and planOptionCd = '"
				@sql << quotationProduct.productPlanOptionCd
				@sql << "' "
			elsif quotationProduct.baseSumAssured != nil
				@sql << "and safrom <= "
				@sql << quotationProduct.baseSumAssured
				@sql << " "
				@sql << "and saTo >= "
				@sql << quotationProduct.baseSumAssured
				@sql << " "
			end

			@productDefinitionTables = ProductDefinitionTable.find_by_sql(@sql)

			if @productDefinitionTables.length >0
				if @productDefinitionTables[0].planCd != nil
					quotationProduct.planCode = @productDefinitionTables[0].planCd
				end
			end
		end
		###################################################################################################


		def self.fetchDiscount(quotation, quotationProduct)
			definitionTables = getProductDefinitionTableList("DISCOUNT", quotation, quotationProduct)
			discountList = Array.new
			definitionTables.each do |definitionTable|
				if definitionTable.rate != nil && quotationProduct.baseSumAssured != nil
					discountList.push(definitionTable.rate.to_f)
				end
			end
			return discountList
		end
		###################################################################################################


		def self.validateFundAllocation(quotation, quotationProduct, fundAllocationDT, msg, errors)
			return true unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateFunds",$rhoconfig[:moduleForProductValidations])
			funds = quotationProduct.QuotationProductInvestmentFundList
			allocationPerc = 0.0
			totalTopupPercent = 0.0
			investmentFundHM=Hash.new
			selectedFundCds = []
			selectedFundsHash = {}

			funds.each do |fund|
				selectedFundCds.push(fund.fundCd)
			end
			selectedFunds = Fund.loadObject(:all, :conditions => {{:name => 'fundCd',:op => 'IN'} => selectedFundCds})
			selectedFunds.each do |fund|
				selectedFundsHash[fund.fundCd] = fund.fundDesc
			end
			#### Fetch companyFieldMetadata form table to check if 'topupAllocationPerc' is configured in the companyFieldMetadata
			companyFieldMetadataDO = CompanyFieldMetadata.find(
				:first,
				:conditions=>{
		  			{ :name => 'inputMetadataCd' } => 'com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO.topupAllocationPerc'
		  		}
			)

			if quotationProduct.portfolioModelCd != nil
				model = Model.loadObject(:first, :conditions => {{ :name => 'modelCd' } => quotationProduct.portfolioModelCd})
				multipleFactor = 1
				funds.each do |fund|
					unless fund.removed && fund.removed != ""
						investmentFundHM[fund.fundCd]=fund
						if fund.allocationPerc!=nil
							allocationPerc += fund.allocationPerc.to_f
						end
					end
				end
				subModelCdTotalAllocPercHM = Hash.new
				if model!=nil
					model.ModelFundList.each do |modelfund|
						multipleFactor = 1
						if modelfund.multipleFactor != nil
							multipleFactor = modelfund.multipleFactor
						end
						if modelfund.minFundAllocPerc == nil && modelfund.maxFundAllocPerc == nil
							next
						end
						if investmentFundHM.has_key?(modelfund.fundCd)
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end
							investFund=investmentFundHM[modelfund.fundCd]

							if investFund.allocationPerc !=nil and investFund.allocationPerc != ""
								if investFund.allocationPerc.to_f < modelfund.minFundAllocPerc.to_f || investFund.allocationPerc.to_f > modelfund.maxFundAllocPerc.to_f
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "allocationPerc", "ERR_MINMAXFUND", [MobiSys::BrowserHelper.getLabel('allocationPerc'),investFund.allocationPerc.to_s, modelfund.minFundAllocPerc.to_s,modelfund.maxFundAllocPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{investFund.guid}-allocationPerc", "ERR_MINMAXFUND", "ERR_MINMAXFUND", nil,[MobiSys::BrowserHelper.getLabel('allocationPerc'),investFund.allocationPerc.to_s, modelfund.minFundAllocPerc.to_s,modelfund.maxFundAllocPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
									end
									isValid=false
								end
								if investFund.allocationPerc.to_f % multipleFactor.to_f != 0
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "allocationPerc", "ERR_INDALLOCATIONPERC", [MobiSys::BrowserHelper.getLabel('allocationPerc'),multipleFactor.to_s, MobiSys::BrowserHelper.getLabel('allocationPerc'),investFund.allocationPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{investFund.guid}-allocationPerc", "ERR_INDALLOCATIONPERC", "ERR_INDALLOCATIONPERC", nil,[MobiSys::BrowserHelper.getLabel('allocationPerc'),multipleFactor.to_s, MobiSys::BrowserHelper.getLabel('allocationPerc'),investFund.allocationPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
									end
								end
							end

							topupAllocPercent = investFund.topupAllocationPerc
							if companyFieldMetadataDO != nil
								if topupAllocPercent != nil
									totalTopupPercent = totalTopupPercent.to_f + topupAllocPercent.to_f
									if topupAllocPercent.to_f % multipleFactor.to_f != 0
										unless $rhoconfig[:TABFEATUREREQD]
											MobiSys::CommonUtil.addErrors(tempErrorHash, "topupAllocationPerc", "ERR_INDALLOCATIONPERC", [MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),multipleFactor.to_s, MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),investFund.topupAllocationPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
										else
											MobiSys::CommonUtil.registerException(quotation.guid, "#{investFund.guid}-topupAllocationPerc", "ERR_INDALLOCATIONPERC", "ERR_INDALLOCATIONPERC", nil,[MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),multipleFactor.to_s, MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),investFund.topupAllocationPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
										end
									end
								end
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationProductInvestmentFundDO] = Hash.new if !errors[:QuotationProductInvestmentFundDO].is_a?(Hash)
										errors[:QuotationProductInvestmentFundDO][investFund.guid.to_sym] = Hash.new if !errors[:QuotationProductInvestmentFundDO][investFund.guid.to_sym].is_a?(Hash)
										errors[:QuotationProductInvestmentFundDO][investFund.guid.to_sym] = errors[:QuotationProductInvestmentFundDO][investFund.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyProductInvestmentFundDO] = Hash.new if !errors[:PolicyProductInvestmentFundDO].is_a?(Hash)
										errors[:PolicyProductInvestmentFundDO][investFund.guid.to_sym] = Hash.new if !errors[:PolicyProductInvestmentFundDO][investFund.guid.to_sym].is_a?(Hash)
										errors[:PolicyProductInvestmentFundDO][investFund.guid.to_sym] = errors[:PolicyProductInvestmentFundDO][investFund.guid.to_sym].merge(tempErrorHash)
									end
							  	end
							end
			              	if modelfund.subModelCd != nil
			                	if subModelCdTotalAllocPercHM[modelfund.subModelCd] != nil
			                  		allocationPercentage = subModelCdTotalAllocPercHM[modelfund.subModelCd].to_f
			                  		allocationPercentage = allocationPercentage + investFund.allocationPerc.to_f
			                  		subModelCdTotalAllocPercHM[modelfund.subModelCd] = allocationPercentage
			                	else
			                  		subModelCdTotalAllocPercHM[modelfund.subModelCd] = investFund.allocationPerc
			                	end
			             	end
		          		end
				  	end
				   	model.ModelSubModelList.each do |modelSubModel|
						if subModelCdTotalAllocPercHM[modelSubModel.subModelCd] != nil
							if modelSubModel.minFundAllocPerc != nil && modelSubModel.minFundAllocPerc > subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_f
								if  $rhoconfig[:new_validations_in_productbo] == 'YES'
									tempErrorHash= Hash.new
								else
									tempErrorHash = errors
								end
								minAllocationFundCds = ""
								model.ModelFundList.each do |modelFund|
									if modelFund.subModelCd != nil && modelFund.subModelCd == modelSubModel.subModelCd
		                 				minAllocationFundCds = minAllocationFundCds + " & " + MobiSys::BrowserHelper.getLabel(selectedFundsHash[modelFund.fundCd])
		              				end
		            			end
		            			minAllocationFundCds =  minAllocationFundCds[3,minAllocationFundCds.length - 1]
								unless $rhoconfig[:TABFEATUREREQD]
	            					MobiSys::CommonUtil.addErrors(tempErrorHash, "allocationPerc", "ERR_MINFUNDALLOCATION", [minAllocationFundCds,modelSubModel.minFundAllocPerc.to_s,subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_s])
	            				else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-allocationPerc", "ERR_MINFUNDALLOCATION", "ERR_MINFUNDALLOCATION", nil,[minAllocationFundCds,modelSubModel.minFundAllocPerc.to_s,subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_s])
								end
								unless $rhoconfig[:TABFEATUREREQD]
			            			if $rhoconfig[:moduleForProductValidations] == "Quotation"
						            	if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo] == 'YES'
						            		errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
						            		errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
						            		errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"].is_a?(Array)
						            		errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"].push(tempErrorHash["allocationPerc"])
						            	end
						            end
						            if $rhoconfig[:moduleForProductValidations] == "Policy"
						            	if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo] == 'YES'
						            		errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
						            		errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
						            		errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"] = Array.new if !errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"].is_a?(Array)
						            		errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"].push(tempErrorHash["allocationPerc"])
						            	end
						            end
						        end
					        end
					        if modelSubModel.maxFundAllocPerc != nil && modelSubModel.maxFundAllocPerc < subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_f
					        	if  $rhoconfig[:new_validations_in_productbo]== 'YES'
					        		tempErrorHash= Hash.new
					        	else
					        		tempErrorHash = errors
					        	end
					        	maxAllocationFundCds = ""
					        	model.ModelFundList.each do |modelFund|
					        		if modelFund.subModelCd != nil && modelFund.subModelCd == modelSubModel.subModelCd
			                  			maxAllocationFundCds = maxAllocationFundCds + " & " + MobiSys::BrowserHelper.getLabel(selectedFundsHash[modelFund.fundCd])
			              			end
			          			end
			          			maxAllocationFundCds =  maxAllocationFundCds[3,maxAllocationFundCds.length - 1]
								unless $rhoconfig[:TABFEATUREREQD]
		          					MobiSys::CommonUtil.addErrors(tempErrorHash, "allocationPerc", "ERR_MAXFUNDALLOCATION", [maxAllocationFundCds,modelSubModel.maxFundAllocPerc.to_s,subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_s])
		          				else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-allocationPerc", "ERR_MAXFUNDALLOCATION", "ERR_MAXFUNDALLOCATION", nil,[maxAllocationFundCds,modelSubModel.maxFundAllocPerc.to_s,subModelCdTotalAllocPercHM[modelSubModel.subModelCd].to_s])
								end

								unless $rhoconfig[:TABFEATUREREQD]
				          			if $rhoconfig[:moduleForProductValidations] == "Quotation"
				          				if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo] == 'YES'
				          					errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
				          					errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
				          					errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"] = Array.new if !errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"].is_a?(Array)
				                    		errors[:QuotationDO][quotation.guid.to_sym]["allocationPerc"].push(tempErrorHash["allocationPerc"])
				                  		end
				          			end
				          			if $rhoconfig[:moduleForProductValidations] == "Policy"
				          				if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo] == 'YES'
				          					errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
				          					errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
				          					errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"] = Array.new if !errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"].is_a?(Array)
				                    		errors[:PolicyDO][quotation.guid.to_sym]["allocationPerc"].push(tempErrorHash["allocationPerc"])
				                  		end
				          			end
				          		end
			          		end
		        		end
          			end
				end
				#Get the funds which have alloc percent and add exception only if atleast one record exists
				investmentFundsList = funds.select{|x| x.removed.to_s != "YES"}
				if(investmentFundsList != nil and investmentFundsList.size > 0 and allocationPerc.to_i != 100)
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, 'allocationPerc', "ERR_INVESTMENTPERCENTAGE", [MobiSys::BrowserHelper.getLabel('allocationPerc'),allocationPerc.to_s])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-allocationPerc", "ERR_INVESTMENTPERCENTAGE", "ERR_INVESTMENTPERCENTAGE", nil,[MobiSys::BrowserHelper.getLabel('allocationPerc'),allocationPerc.to_s])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
					isValid = false
				end
				#Get the funds which have top up alloc percent and add exception only if atleast one record exists
				if (investmentFundsList != nil && investmentFundsList.size > 0 && companyFieldMetadataDO != nil && totalTopupPercent.to_i != 100)
					if  $rhoconfig[:new_validations_in_productbo]== 'YES'
						tempErrorHash= Hash.new
					else
						tempErrorHash = errors
					end
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, 'topupAllocationPerc', "ERR_INVESTMENTPERCENTAGE", [MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),totalTopupPercent.to_s])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-topupAllocationPerc", "ERR_INVESTMENTPERCENTAGE", "ERR_INVESTMENTPERCENTAGE", nil,[MobiSys::BrowserHelper.getLabel('topupAllocationPerc'),totalTopupPercent.to_s])
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if $rhoconfig[:moduleForProductValidations] == "Quotation"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
							end
						end
						if $rhoconfig[:moduleForProductValidations] == "Policy"
							if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
								errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
								errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
							end
						end
					end
					isValid = false
				end

				product = quotationProduct.product
				minMaxFundCountsFacet = product.getFacet('MINMAXFUNDSCOUNT')
				if minMaxFundCountsFacet
					facetDetails = minMaxFundCountsFacet.OfflineFacetDetailsList[0]
					if facetDetails
						minMaxFundsCountTTMS = facetDetails.tableTypeMappingSeq
						if minMaxFundsCountTTMS
							dt = MobiSys::ProductUtil.getProductDefinitionTableDO(minMaxFundsCountTTMS, quotation, quotationProduct)
							size = quotationProduct.QuotationProductInvestmentFundList.select{|fund| fund.allocationPerc.to_s != ""}.size
							if  $rhoconfig[:new_validations_in_productbo]== 'YES'
								tempErrorHash= Hash.new
							else
								tempErrorHash = errors
							end

							if(dt != nil && dt.minValue.to_s != "" && size < dt.minValue.to_i)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "minfundscount", "ERR_MINFUNDSCOUNT", [size.to_s, dt.minValue.to_i.to_s])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-minfundscount", "ERR_MINFUNDSCOUNT", "ERR_MINFUNDSCOUNT", nil,[size.to_s, dt.minValue.to_i.to_s])
								end
							elsif(dt != nil && dt.maxValue.to_s != "" && size > dt.maxValue.to_i)
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "maxfundscount", "ERR_MAXFUNDSCOUNT", [size.to_s, dt.maxValue.to_i.to_s])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-maxfundscount", "ERR_MAXFUNDSCOUNT", "ERR_MAXFUNDSCOUNT", nil,[size.to_s, dt.maxValue.to_i.to_s])
								end
							end

							unless $rhoconfig[:TABFEATUREREQD]
								if $rhoconfig[:moduleForProductValidations] == "Quotation"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
								if $rhoconfig[:moduleForProductValidations] == "Policy"
									if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
										errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
										errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
									end
								end
							end
						end
					end
				end
			end
		end
		###################################################################################################


		def self.getFundTableEntry(policyYearFrom, policyYearTo, growthRates, managementCharges, quotationProductInvestmentFundList)
			fundArrayEntry = Hash.new
			fundArrayEntry["policyYearFrom"] = policyYearFrom
			fundArrayEntry["policyYearTo"] = policyYearTo

			fundHash = Hash.new
			growthRates.each do |growthRate|
				if growthRate.policyYearFrom.to_i >= policyYearFrom and growthRate.policyYearTo.to_i <= policyYearTo
					fundDetails = Hash.new
					fundAdded = false
					quotationProductInvestmentFundList.each do |fund|
						if fund.fundCd == growthRate.ruleName
							fundDetails["allocation"] = fund.allocationPerc
							fundAdded = true
						end
					end
					fundDetails["allocation"] = 0 unless fundAdded
					fundDetails["lowRate"] = growthRate.illustrationRateFrom
					fundDetails["hiRate"] = growthRate.illustrationRateTo
					fundDetails["managementCharges"] = managementCharges[growthRate.ruleName]
					fundHash[growthRate.ruleName] = fundDetails
				end
			end

			fundArrayEntry["funds"] = fundHash

			#calculate weighted expected return
			weightedExpectedReturnHi = 0
			weightedExpectedReturnLow = 0
			weightedManagementCharges = 0
			fundHash.each{|fundCd,fundDetails|
				allocationRate = fundDetails["allocation"].to_f/100
				hiRate = fundDetails["hiRate"].to_f/100
				weightedExpectedReturnHi += (allocationRate * hiRate)

				lowRate = fundDetails["lowRate"].to_f/100
				weightedExpectedReturnLow += (allocationRate * lowRate)

				managementChargeRate = fundDetails["managementCharges"].to_f/100
				weightedManagementCharges += (allocationRate * managementChargeRate)
			}

			fundArrayEntry["weightedExpectedReturnLow"] = weightedExpectedReturnLow
			fundArrayEntry["weightedExpectedReturnHigh"] = weightedExpectedReturnHi
			fundArrayEntry["weightedManagementCharges"] = weightedManagementCharges
			return fundArrayEntry
		end
		###################################################################################################


		def self.populateProduct(quotation)
			quotation.QuotationProductList.each do |qp|
				next if qp.product
				qp.product = MobiSys::ProductUtil.getProduct(qp.productSeq)
			end
		end
		###################################################################################################


		def self.calculateIllustration(quotationIO, calledFrom = nil)
			@isCalculateIllust = true
			@calculate_loggin_file = Array.new
			return quotationIO unless quotationIO.baseDO.getBaseProduct.productTerm
			stepStartTime = illusStartTime = Time.now
			RhoLog.error("CalculateIllustration", ">>>Starting calculateIllustration for quotation ref num: #{quotationIO.baseDO.quotationRefNum} at #{illusStartTime.to_s}")
			GC.enable
			$messages.clear if $messages
			stepStartTime = illusStartTime = Time.now
			illusStartTime = Time.now
			quotation = quotationIO.baseDO
			populateProduct(quotation)
			#Defaulting code start
			quotation.QuotationProductList.each do |qp|
				qp.pdfPeriod = 0 unless qp.pdfPeriod
			end
			#Defaulting code end
			RhoLog::error("CalculateIllustration", ">>>Starting calculateIllustration for quotation ref num: #{quotation.quotationRefNum} at #{illusStartTime.to_s}")
			jointLAIssueAge = 0
			quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
			proposer = quotation.getPartyByRole("PROPOSER")
			jointLife = quotation.getPartyByRole("JOINT")
			jointLAIssueAge = (jointLife and jointLife.age ? jointLife.age : 0)

			product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)

			if quotationIO.illustrationModel == nil
				illustrationModelCd = product.getOtherDetailsFacet.OfflineOtherDetailsList[0].illustrationFormat
				raise StandardError.new("illustration model not configured for product #{product.productId}") unless illustrationModelCd
				illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => illustrationModelCd})
				raise StandardError.new("Illustration model for modelcd #{illustrationModelCd} not found") unless illustrationModel
				#puts ">>>Found model with modelCd: #{illustrationModel.modelCd}"
				quotationIO.illustrationModel =  illustrationModel
			end

			if quotationIO.getModelAdditionalParams["SOLVER_CALL"].to_s != ""
				@isSolverCall = quotationIO.getModelAdditionalParams["SOLVER_CALL"]
			end
			quotationIO.originalSIModel = quotationIO.illustrationModel.cloneObject

			illustrationModel = quotationIO.illustrationModel
			# if this is called from solver then do not overwrite the PolicyModel log file as Solvers are also configured in PolicyModel
			if Rho::RhoConfig.LogToOutput.to_i == 1 && @isCalculateIllust && !@isSolverCall
				modellog(illustrationModel)
			end
			#inititalizing these fields only for SIModel and not otherwise ..eg. we dont require these for solver etc.
			@calcYearlyResultsOutput = []
			@currCycleCalcOutputData = nil
			@siCalcCompleteOutputData = {}
			@siCalcGlobalOutputData = {}
			@currSICalcFundDO = nil
			@currSICalcRiderDO = nil
			@currSICalcRateDO = nil
			@siCalcCompleteOutputData["TermData"] = @calcYearlyResultsOutput
			@siCalcCompleteOutputData["GlobalData"] = @siCalcGlobalOutputData
			quotationIO.additionalData = {} if !(quotationIO.additionalData.is_a?Hash)
			quotationIO.additionalData["SICalc"] = @siCalcCompleteOutputData

			riderProductHash = Hash.new
			quotation.QuotationProductList.each do |qp|
				next if qp.productTypeCd == "PLAN"
				riderProductHash[qp.productId] = qp.product
			end

			illusFacetComputedOnce = Array.new
			illusFacetComputedEveryCycle = Array.new
			illusFacetComputedEveryCyclePerRate = Array.new
			illusFacetsPerRider = Array.new
			illusFacetsPerRiderFilter = Array.new
			illusFacetsPerFund = Array.new
			illusFacetsPerLifePerCycle = Array.new
			illusFacetsPerLifePerCyclePerRate = Array.new
			illusFacetComputedOnceAtEnd = Array.new
			illusFacetComputedOnceAtEndPerRate = Array.new
			illusFacetsOncePerFund = Array.new

			#variables  = Hash.new
			results = MobiSys::DataObjects::Results.new
			quotationIO.results = results
			results.createAttr("quotation")
			results.quotation = quotation
			results.createAttr("quotationProduct")
			results.createAttr("basePlan")
			results.basePlan = quotation.getBaseProduct()

			results.createAttr("currCycleCount")
			results.createAttr("currPolicyYear")
			results.createAttr("currPolicyMonth")
			results.createAttr("currIllusNetRate")
			results.createAttr("quotationIO")
			results.createAttr("investmentFund")
			results.createAttr("fieldValueEvalOnceForFilter")

			riderList = Array.new
			riders = quotation.getRiders
			riders.each do |quotationProduct|
				if !isWOP(quotationProduct,quotation)
					riderList.push quotationProduct
				end
			end

			riderList.each do |quotationProduct|
				eval("results.createAttr(\"fieldValueEvalOnceForFilter#{quotationProduct.guid}\")")
			end

			if quotationIO.getModelAdditionalParams["ADDITIONAL_EVAL_PARAMS"] != nil
				quotationIO.getModelAdditionalParams["ADDITIONAL_EVAL_PARAMS"].each do |key, hash|
					results.createAttr(key)
					results.setAttr(key, hash)
				end
			end

			resFieldForHeader = MobiSys::DataObjects::FieldResult.new
			resFieldForHeader.versionID = 1
			quotationIO.illustrationHeader = resFieldForHeader
			initializeIllustrationRates(quotePlan, illustrationModel, product, quotationIO)
			
			maxParseLevel = 1
			fieldNamesToReuseInSolver = Array.new

			#MobiSys::ProductUtil.enableCache

			groupSummationFacetNames = Array.new
			computedLookupFacets = illustrationModel.getIllustrationFacetsByFacetTypeCd("COMPUTEDLOOKUP")
			computedLookupFacets.each do |ift|
				if ift.expression and ift.expression.include? "group_summation"
					exp = ift.expression.sub("self.quotationIO.group_summation('","")
					elementName = exp[0,exp.index("'")]
					groupSummationFacetNames.push elementName
				end
			end

			illustrationModel.IllustrationFacetList.each do |ift|
				#Method creation start
				if ift.facetTypeCd == "INPUT"
					results.defineMethod("#{ift.computedElementName}_m","self.#{ift.inputElementSource}.#{ift.inputDataElement}")
					results.createAttr(ift.computedElementName)
				elsif ift.computePerInstanceOf == 'FUND'
					quotation.getBaseProduct().QuotationProductInvestmentFundList.each do |qpif|
						# next unless qpif.allocationPerc and qpif.allocationPerc.to_f > 0
						next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0) #no point in continuing further if allocation percent doesn't exist or is zero
						if ift.computationFreqCd == "ONCEPERFUND"
							if ift.expression
								newExp = ift.expression.clone
								data = newExp.scan(/\b(self.perFundOnce_[a-zA-Z0-9]*)\b/)
								data.each do |match|
									original = match[0].to_s
									newString = String.new(original.gsub("perFundOnce_",""))
									newString << qpif.fundCd
									newExp = newExp.sub(original, newString)
								end #data.each do |match|
								results.defineMethod("#{ift.computedElementName}#{qpif.fundCd}_m", newExp)
							end
							results.createAttr("#{ift.computedElementName}#{qpif.fundCd}")
							results.createAttr("#{ift.computedElementName}_summation#{qpif.fundCd}") if groupSummationFacetNames.include? ift.computedElementName
						else
							illustrationModel.IllustrationRateList.each do |irt|
								if ift.expression
									newExp = ift.expression.clone
									data = newExp.scan(/\b(self.perFundOnce_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perFundOnce_",""))
										newString << qpif.fundCd
										newExp = newExp.sub(original, newString)
									end #data.each do |match|

									data = newExp.scan(/\b(self.perFund_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perFund_",""))
										newString << qpif.fundCd
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|

									data = newExp.scan((/\b(self.perRate_[a-zA-Z0-9]*)\b/))
									data.each do |match|
										original=match[0].to_s
										newString=String.new(original.gsub("perRate_",""))
										newString << irt.id.to_s
										newExp = newExp.sub(original,newString)
									end
									results.defineMethod("#{ift.computedElementName}#{qpif.fundCd}#{irt.id}_m", newExp)
								end
								results.createAttr("#{ift.computedElementName}#{qpif.fundCd}#{irt.id}")
								results.createAttr("#{ift.computedElementName}_summation#{qpif.fundCd}#{irt.id}") if groupSummationFacetNames.include? ift.computedElementName
							end
						end
					end
				elsif ift.computePerInstanceOf == 'LIFE'
					quotation.QuotationPartyList.each do |quotationParty|
						if ift.computationFreqCd == "EVERYCYCLE"
							if ift.expression
								newExp = ift.expression
								data = newExp.scan(/\b(self.perLife_[a-zA-Z0-9]*)\b/)
								data.each do |match|
									original = match[0].to_s
									newString = String.new(original.gsub("perLife_",""))
									newString << quotationParty.roleCd.to_s
									newExp = newExp.sub(original, newString)
								end #data.each do |match|
								results.defineMethod("#{ift.computedElementName}#{quotationParty.roleCd}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							end
							results.createAttr("#{ift.computedElementName}#{quotationParty.roleCd}")
							results.createAttr("#{ift.computedElementName}_summation#{quotationParty.roleCd}") if groupSummationFacetNames.include? ift.computedElementName
							ift.isBreakExpression = ift.expression.include? "break" if ift.expression
						elsif ift.computationFreqCd == "EVERYCYCLEPERRATE"
							illustrationModel.IllustrationRateList.each do |irt|
								if ift.expression
									newExp = ift.expression
									data = newExp.scan(/\b(self.perLife_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perLife_",""))
										newString << quotationParty.roleCd
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|

									data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
									data.each do |match|
										original = match[0].to_s
										newString = String.new(original.gsub("perRate_", ""))
										newString << irt.id.to_s
										newExp = newExp.sub(original, newString)
									end #data.each do |match|
									results.defineMethod("#{ift.computedElementName}#{quotationParty.roleCd}#{irt.id}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
								end
								results.createAttr("#{ift.computedElementName}#{quotationParty.roleCd}#{irt.id}")
								results.createAttr("#{ift.computedElementName}_summation#{quotationParty.roleCd}#{irt.id}") if groupSummationFacetNames.include? ift.computedElementName
								ift.isBreakExpression = ift.expression.include? "break" if ift.expression
							end
						end
					end
				else
					unless ift.computationFreqCd == "EVERYCYCLEPERRATE" or ift.computationFreqCd == "EVERYCYCLEPERRATEFM" or ift.computationFreqCd == "ONCEATENDPERRATE"
						if ift.computePerInstanceOf == 'POLICY' or ift.computePerInstanceOf == 'RIDER'
							results.defineMethod("#{ift.computedElementName}_m", ift.expression) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							results.createAttr(ift.computedElementName)
							results.createAttr("#{ift.computedElementName}_summation") if groupSummationFacetNames.include? ift.computedElementName
							ift.isBreakExpression = ift.expression.include? "break" if ift.expression
						end
					else
						illustrationModel.IllustrationRateList.each do |irt|
							if ift.expression
								newExp = ift.expression
								data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
								data.each do |match|
									original = match[0].to_s
									newString = String.new(original.gsub("perRate_", ""))
									newString << irt.id.to_s
									newExp = newExp.sub(original, newString)
								end #data.each do |match|
								results.defineMethod("#{ift.computedElementName}#{irt.id}_m", newExp) unless ift.facetTypeCd == "COMPUTEDDECISIONTBL"
							end
							results.createAttr("#{ift.computedElementName}#{irt.id}")
							results.createAttr("#{ift.computedElementName}_summation#{irt.id}") if groupSummationFacetNames.include? ift.computedElementName
							ift.isBreakExpression = ift.expression.include? "break" if ift.expression
						end
					end
				end
				#method creation end
				ift.parseLevel = 1 unless ift.parseLevel
				maxParseLevel = ift.parseLevel if maxParseLevel < ift.parseLevel and ift.computePerInstanceOf == "POLICY"

				case ift.computePerInstanceOf
				when "RIDER"
					if ift.computationFreqCd == "ONCEFILTER"
						illusFacetsPerRiderFilter.push ift
					else
						illusFacetsPerRider.push ift
					end
					next
				when "LIFE"
					if ift.computationFreqCd == "EVERYCYCLE"
						illusFacetsPerLifePerCycle.push ift
						next
					elsif ift.computationFreqCd == "EVERYCYCLEPERRATE"
						illusFacetsPerLifePerCyclePerRate.push ift
						next
					end
				when "FUND"
					illusFacetsPerFund.push ift
					ift.groupingName = "Group_#{ift.computedElementName}"
					illusFacetsOncePerFund.push ift if ift.computationFreqCd == "ONCEPERFUND"
					next
				end

				if ift.outputDisplayTypeCd == "PARTOFHEADER" and ift.computationFreqCd=="ONCE"
					evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)
					evaluatedValue = Localization::LabelCache.instance.getLabel(evaluatedValue) if evaluatedValue.is_a? String
					results.setAttr(ift.computedElementName, evaluatedValue)

					resFieldForHeader.addFieldValue(nil, ift.computedElementName,evaluatedValue, ift.elementLabel, ift.computationOrder)
					 #if ift.outputDisplayTypeCd
					if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
						log(resFieldForHeader,ift.computedElementName)
					end
 				else
					case ift.computationFreqCd
					when "ONCE","ONCEFILTER"
						illusFacetComputedOnce.push ift
					when "EVERYCYCLE", "EVERYCYCLEFM"
						illusFacetComputedEveryCycle.push ift
					when "EVERYCYCLEPERRATE", "EVERYCYCLEPERRATEFM"
						illusFacetComputedEveryCyclePerRate.push ift
					when "ONCEATEND"
						illusFacetComputedOnceAtEnd.push ift
					when "ONCEATENDPERRATE"
						illusFacetComputedOnceAtEndPerRate.push ift
					end
				end
				# Check if it is set up as once per solver then initialize these element names to be reused.
				# ReUsing OutputDisplayTypeCd since in Solver this field is not used for output display

				if ift.outputDisplayTypeCd == "ONCEPERSOLVER" && (quotationIO.getModelAdditionalParams["SOLVER_CALL"].to_s != "" && quotationIO.getModelAdditionalParams["SOLVER_CALL"] == true)
					if quotationIO.getModelAdditionalParams["FIELD_NAMES_SET"].to_s != ""
						fieldNamesToReuseInSolver = quotationIO.getModelAdditionalParams["FIELD_NAMES_SET"]
					end
					if fieldNamesToReuseInSolver.to_s == ""
						fieldNamesToReuseInSolver = Array.new
						quotationIO.addModelAdditionalParams("FIELD_NAMES_SET", fieldNamesToReuseInSolver)
					end
					fieldNamesToReuseInSolver.push ift.computedElementName
				end
			end

			illustrationModel.IllustrationRateList.each do |irt|
				illusFacetComputedEveryCyclePerRate.each do |ift|
					newIft = ift.clone
					newIft.originalComputedElementName = newIft.computedElementName
					newIft.computedElementName = "#{newIft.computedElementName}#{irt.id}"
					if newIft.computedFieldNameForRule.to_s != ""
						newIft.computedFieldNameForRule.gsub!("perRate_","")
						newIft.computedFieldNameForRule = "#{newIft.computedFieldNameForRule}#{irt.id}"
					end
					newIft.isBreakExpression = ift.isBreakExpression
					irt.addIllustrationFacet newIft
				end
				irt.illustrationFacetList = irt.illustrationFacetList.sort{|x,y| x.computationOrder.to_i <=> y.computationOrder.to_i}
			end

			illusFacetComputedEveryCycle.sort{|x,y| x.computationOrder.to_i <=> y.computationOrder.to_i}

			fundFacetsParseLevelHashMap = IllustrationModel.prepareParseLevelHashmap(illusFacetsPerFund)

			#Copy over quotationParty.age to quotationParty.entryAge
			#quotationParty.entryAge will later be used to restore entry age in quotationParty.age
			quotation.QuotationPartyList.each do |qp|
				qp.entryAge = qp.age
			end

			resFieldsOnceComputed = nil
			siIllustrationResult = Array.new
			quotationIO.listCalculation = siIllustrationResult
			fieldValueEvalOnceForFilter = nil

			freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(illustrationModel.computationFrequencyCd)

			computationCycles = quotePlan.productTerm.to_i * freqMultiplier.to_i
			parseCount = 1
			while parseCount <= maxParseLevel
				resFieldsOnceComputed = MobiSys::DataObjects::FieldResult.new
				resFieldsOnceComputed.versionID = parseCount.to_i
				#Computing facets computed once - start
				illusFacetComputedOnce.each do |ift|
					if fieldNamesToReuseInSolver.to_s != "" && fieldNamesToReuseInSolver.include?(ift.computedElementName)
						if quotationIO.getModelAdditionalParams["EXIST_HDR_RESULT"].to_s != ""
							if quotationIO.getModelAdditionalParams["EXIST_HDR_RESULT"].respond_to?(:getFieldValueObject)
								resFieldsOnceComputed.addFieldValue(nil, ift.computedElementName, quotationIO.getModelAdditionalParams["EXIST_HDR_RESULT"].getFieldValueObject(ift.computedElementName), ift.elementLabel, ift.computationOrder)
							end
						end
					end
					if ift.parseLevel != parseCount
						results.setAttr(ift.computedElementName, resFieldsOnceComputed.getFieldValue(ift.computedElementName)) if resFieldsOnceComputed.containsFieldInMap(ift.computedElementName)
						next
					end
					evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)
					resFieldsOnceComputed.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)  #if ift.outputDisplayTypeCd
					if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
						log(resFieldsOnceComputed,ift.computedElementName)
					end

					if ift.computationFreqCd == "ONCEFILTER"
						fieldValueEvalOnceForFilter = evaluatedValue
						results.fieldValueEvalOnceForFilter = evaluatedValue
					end

					if ift.outputDisplayTypeCd == "PARTOFFIELD"
						setModelFieldData(quotation, 1, ift, evaluatedValue);
					end
				end
				#Computing facets computed once -end

				#Computed facets computed once per fund - start
				evaluatedValue = nil
				fundData = {}
				quotation.getBaseProduct.QuotationProductInvestmentFundList.each do |qpif|
					# next unless qpif.allocationPerc and qpif.allocationPerc.to_f > 0
					next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0) #no point in continuing further if allocation percent doesn't exist or is zero
					fundElemData = {}
					fundData[qpif.fundCd] =  fundElemData
					illusFacetsOncePerFund.each do |ift|
						origComputedElementName = ift.computedElementName 
						origComputedElementName = ift.origElementName if quotationIO.isTemplateBasedOutput != nil and quotationIO.isTemplateBasedOutput == true
						ift.computedElementName = "#{ift.computedElementName}#{qpif.fundCd}"
						results.investmentFund = qpif
						quotation.getBaseProduct.fundCd = qpif.fundCd
						evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO,origComputedElementName)
						ift.computedElementName = origComputedElementName
						resFieldsOnceComputed.entityTypeCd = qpif.fundCd
						resFieldsOnceComputed.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)  #if ift.outputDisplayTypeCd
						# Adding the element appended with the fund code since the element value keeps getting overwritten for each fund. 
						resFieldsOnceComputed.addFieldValue(nil, ift.computedElementName + "_" + qpif.fundCd, evaluatedValue, ift.elementLabel, ift.computationOrder)
						if(ift.outputDisplayTypeCd.to_s != "")
							fundElemData[origComputedElementName] = evaluatedValue
						end
						if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
							log(resFieldsOnceComputed,ift.computedElementName)
						end
 					end
				end
				if @siCalcCompleteOutputData["GlobalData"] != nil
					@siCalcCompleteOutputData["GlobalData"]["FundData"] = fundData
				end
				#Computed facets computed once per fund - end

				#Computed facets computed once per rider for filter start
				riderList.each do |quotationProduct|
					if (quotationProduct.productTypeCd.to_s != 'PLAN' && quotation.getBaseProduct.product && quotation.getBaseProduct.product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES" && (quotationProduct.selected != "on" &&quotationProduct.selected != "YES" )) || quotationProduct.removed == "YES"
						next
					end
					illusFacetsPerRiderFilter.each do |ift|
						# resFieldsPerRider.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder) #if ift.outputDisplayTypeCd
						if ift.computationFreqCd == "ONCEFILTER"
							evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotationProduct, nil)
							eval("results.fieldValueEvalOnceForFilter#{quotationProduct.guid} = \"#{evaluatedValue}\"")
							if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
								log(resFieldsOnceComputed,ift.computedElementName)
							end
						end
					end
				end

				#Computed facets computed once per rider for filter end



				freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(illustrationModel.computationFrequencyCd)
				return quotationIO unless quotePlan.productTerm
				fieldNamesToReuseArr = quotationIO.getModelAdditionalParams["FIELD_NAMES_SET"]
				@isMonthly = false
				if(illustrationModel.computationFrequencyCd == "MONTHLY")
					@isMonthly = true
				end
				#WOP changes start
				wopRidersList = Array.new
				nonWopRidersList = Array.new
				riders = quotation.getRiders
				riders.each do |quotationProduct|
					if isWOP(quotationProduct,quotation)
						wopRidersList.push quotationProduct
					else
						nonWopRidersList.push quotationProduct
					end
				end
				wopRiderCount = wopRidersList.size
				riderCount = riders.size

				#WOP changes end
				computationCycles = quotePlan.productTerm.to_i * freqMultiplier.to_i
				policyYear = policyMonth = 0

				results.createAttr("currBasicParseCount")
				results.currBasicParseCount = parseCount

				cycleCount = 1
				while cycleCount <= computationCycles
					riderFacetsComputed = false
					lifeFacetsComputedPerCycle = false
					shouldBreak = false
					hmRiderGroupedAttribValues = resFieldsPerCycle = nil
					if parseCount == 1
						resFieldsPerCycle = MobiSys::DataObjects::FieldResult.new
						siIllustrationResult.push resFieldsPerCycle
						#this.calcResults.add(resFieldsPerCycle.getLHmFieldValues());
						if(@siCalcCompleteOutputData != nil)
							if(@isMonthly)
								#for monthly we need calcOutputData only for each year
								if(cycleCount % 12 == 0)
									@currCycleCalcOutputData = {}
								else
									@currCycleCalcOutputData = nil
								end
							else
								@currCycleCalcOutputData = {}
							end
							if(@currCycleCalcOutputData != nil)
								@calcYearlyResultsOutput << @currCycleCalcOutputData
							end
						end
					else
						resFieldsPerCycle = siIllustrationResult[cycleCount - 1]
						if(@siCalcCompleteOutputData != nil)
							if(@isMonthly)
								if(cycleCount % 12 == 0)
									@currCycleCalcOutputData = @calcYearlyResultsOutput[(cycleCount/12) -1]
								else
									@currCycleCalcOutputData = nil
								end
							else
								@currCycleCalcOutputData = @calcYearlyResultsOutput[cycleCount -1]
							end
						end
					end

 					resFieldsPerCycle.id = cycleCount
					resFieldsPerCycle.versionID = parseCount.to_i
					results.currCycleCount = cycleCount

					policyMonth = 0 if policyMonth == 12 or illustrationModel.computationFrequencyCd == "YEARLY"

					policyYear = (cycleCount/freqMultiplier) #if cycleCount%freqMultiplier == 0
					policyYear += 1 unless cycleCount%freqMultiplier == 0
					policyMonth += 1
			  		quotation.policyYear = policyYear
					quotationIO.addModelAdditionalParams("modelTotalCycles", cycleCount)
					#compute the premium every first month of each year. Not computing for first year since this would have already been saved.
					#and for the following years it would compute based on premium model computation frequency.
					#for parse level 2 we need to compute the model premium etc. again for first year as well since the values in the DO would be replaced with the
					#last year values and for the first policy year we need to recalculate in case premium model was yearly.
					if(policyMonth == 1 && (policyYear > 1 || parseCount > 1 || @isSolverCall))
						if policyYear > 1
							quotation.QuotationPartyList.each do |party|
								party.policyYear = policyYear
								if party.age.to_s != ''
									party.age = party.age.to_i + 1
								end
							end
						end
						calculateModelBasedPremium(policyYear, quotation, quotePlan, product) if policyYear <= (quotation.getBaseProduct.premiumPayingTerm.to_i + 1)
	  			    end

					results.currPolicyYear = policyYear
					results.currPolicyMonth = policyMonth
					quotationIO.currentRate = nil
					illusFacetComputedEveryCycle.each do |ift|

						if ift.elementFilter
							filterArray = ift.elementFilter.split(",")
							next unless filterArray.include? fieldValueEvalOnceForFilter
						end

						if ift.parseLevel != parseCount
							results.setAttr(ift.computedElementName, resFieldsPerCycle.getFieldValue(ift.computedElementName)) if resFieldsPerCycle.containsFieldInMap(ift.computedElementName)
							next
						end
						evaluatedValue = nil

						if ift.computationFreqCd == "EVERYCYCLEFM" and policyMonth > 1
							fldResPrevMonth = siIllustrationResult[cycleCount - 2]
							if fldResPrevMonth.containsFieldInMap(ift.computedElementName)
								prevMonthVal = fldResPrevMonth.getFieldValue(ift.computedElementName)
								prevMonthVal = (prevMonthVal.is_a? MobiSys::DataObjects::FieldValue) ? prevMonthVal.fieldValue : prevMonthVal

								results.setAttr(ift.computedElementName, prevMonthVal)
								#add the every cycle first month fields here since it is not available in evaluateField function as that is not called.
								if(@currCycleCalcOutputData != nil && ift.outputDisplayTypeCd != nil && @siCalcCompleteOutputData != nil)
									@currCycleCalcOutputData[ift.computedElementName] = prevMonthVal
								end
								resFieldsPerCycle.addFieldValue(nil, ift.computedElementName, prevMonthVal, ift.elementLabel, ift.computationOrder)  #if ift.outputDisplayTypeCd
								if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
									log(resFieldsPerCycle,ift.computedElementName)
								end
							end #if fldResPrevMonth.containsFieldInMap(ift.computedElementName)
							next
						end  #if ift.computationFreqCd == "EVERYCYCLEFM" and policyMonth > 1

						if ift.facetTypeCd == "GROUPING"
							if ift.inputElementSource == "quotationProduct"
								#life facets are computed once per cycle for all Plan lives and then grouped
								if !lifeFacetsComputedPerCycle && illusFacetsPerLifePerCycle.size > 0 && quotation.getPlanList.size > 0
									hmRiderGroupedAttribValues = calculateLifeFacets(illustrationModel, illusFacetsPerLifePerCycle, quotation, results, quotationIO, nil)
									lifeFacetsComputedPerCycle = true
								end
							else
								if !riderFacetsComputed and quotation.getRiderCount > 0
									hmRiderGroupedAttribValues = calculateRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, quotationIO, riderProductHash, nonWopRidersList, Hash.new)
									if wopRiderCount > 0
										hmRiderGroupedAttribValues = calculateWopRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, quotationIO, riderProductHash, wopRidersList, hmRiderGroupedAttribValues)
									end
									riderFacetsComputed = true
								end
							end
							if hmRiderGroupedAttribValues
								evaluatedValue = hmRiderGroupedAttribValues["Group_#{ift.inputDataElement}"]
								results.setAttr(ift.computedElementName, evaluatedValue)
								resFieldsPerCycle.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
								if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
									log(resFieldsPerCycle,ift.computedElementName)
								end
							else
								evaluatedValue = 0
								results.setAttr(ift.computedElementName, evaluatedValue)
								resFieldsPerCycle.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
								if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
									log(resFieldsPerCycle,ift.computedElementName)
								end
							end
						elsif ift.facetTypeCd == "COMPUTEDLOOKUP"
								evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)
								resFieldsPerCycle.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
								if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
									log(resFieldsPerCycle,ift.computedElementName)
								end
						else
							evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, nil)
							resFieldsPerCycle.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
							if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
								log(resFieldsPerCycle,ift.computedElementName)
							end
						end
						if groupSummationFacetNames.include? ift.computedElementName
							# puts ">>>summation present for #{ift.computedElementName}"
							prevMonthVal = 0.0
							if cycleCount - 2 >= 0
								fldResPrevMonth = siIllustrationResult[cycleCount - 2]
								facetName = "#{ift.computedElementName}_summation"
								if fldResPrevMonth.containsFieldInMap(facetName)
									prevMonthVal = fldResPrevMonth.getFieldValue(facetName)
									prevMonthVal = (prevMonthVal.is_a? MobiSys::DataObjects::FieldValue) ? prevMonthVal.fieldValue : prevMonthVal
								end #if fldResPrevMonth.containsFieldInMap(ift.computedElementName)
							end

							summation = prevMonthVal + evaluatedValue
							# puts ">>>prevMonthVal: #{prevMonthVal} evaluatedValue: #{evaluatedValue} summation: #{summation}"
							resFieldsPerCycle.addFieldValue(nil,"#{ift.computedElementName}_summation", summation, "#{ift.elementLabel}_summation", ift.computationOrder)
							#puts ">>>resFieldsPerCycle: #{resFieldsPerCycle.inspect}"
						end

						if ift.outputDisplayTypeCd == "PARTOFFIELD"
							setModelFieldData(quotation, policyYear, ift, evaluatedValue);
						end #part of field

						if evaluatedValue and ift.isBreakExpression
							if evaluatedValue.is_a?(String) && evaluatedValue.include?("break")
								shouldBreak = true
							end
						end
					end

					#Loop through the illustration rates
					if illusFacetComputedEveryCyclePerRate.size > 0
						rateCounter = 0
						illustrationModel.IllustrationRateList.each do |illustrationRate|

							next if illustrationRate.rate.to_s == ""
							# Compare if the rates are policy year wise then get the rate for that policy year itself. 
							# Check the policy year range with the current policy year
							if illustrationRate.policyYearFrom.to_s != "" && illustrationRate.policyYearTo.to_s != ""
								if !(illustrationRate.policyYearFrom.to_i <= policyYear.to_i && illustrationRate.policyYearTo.to_i >= policyYear.to_i)
									next
								end
							end

							@currSICalcRateDO = illustrationRate
							fundFacetsComputed = false
							lifeFacetsComputedPerRate = false
							hmFundGroupedAttribValues = Hash.new
							resFieldsPerCyclePerRate = nil
							if parseCount == 1
								resFieldsPerCyclePerRate = MobiSys::DataObjects::FieldResult.new
								resFieldsPerCycle.addFieldResult(resFieldsPerCyclePerRate)
							else
								resFieldsPerCyclePerRate = resFieldsPerCycle.fieldResultList[rateCounter]
							end

							results.currIllusNetRate = illustrationRate.rate.to_f
							resFieldsPerCyclePerRate.id = cycleCount.to_i
							resFieldsPerCyclePerRate.versionID = parseCount.to_i
							resFieldsPerCyclePerRate.objectName = illustrationRate.rate.to_s

							quotePlan.illustrationRate = illustrationRate.rate
							quotePlan.currentRate = illustrationRate.rate
							quotationIO.currentRate = illustrationRate.rate

							illustrationRate.illustrationFacetList.each do |ift|
								next unless ift.computePerInstanceOf == "POLICY"

								if ift.elementFilter
									filterArray = ift.elementFilter.split(",")
									next unless filterArray.include? fieldValueEvalOnceForFilter
								end

								if ift.parseLevel.to_i != parseCount
									results.setAttr(ift.computedElementName, resFieldsPerCyclePerRate.getFieldValue(ift.computedElementName)) if resFieldsPerCyclePerRate.containsFieldInMap(ift.computedElementName)
									next
								end

								if ift.computationFreqCd == "EVERYCYCLEPERRATEFM" and policyMonth > 1
									fldResPrevMonth = siIllustrationResult[cycleCount - 2]
									fldResPerRatePrevMonth = fldResPrevMonth.fieldResultList[rateCounter]
									if fldResPerRatePrevMonth.containsFieldInMap(ift.originalComputedElementName)
										prevMonthVal = fldResPerRatePrevMonth.getFieldValue(ift.originalComputedElementName)
										prevMonthVal = (prevMonthVal.is_a? MobiSys::DataObjects::FieldValue) ? prevMonthVal.fieldValue : prevMonthVal

										results.setAttr(ift.computedElementName, prevMonthVal)
										resFieldsPerCyclePerRate.addFieldValue(nil,ift.originalComputedElementName, prevMonthVal, ift.elementLabel, ift.computationOrder) #if ift.outputDisplayTypeCd
										if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
											log(resFieldsPerCyclePerRate,ift.originalComputedElementName)
										end
 									end #if fldResPerRatePrevMonth.containsFieldInMap(ift.computedElementName)
									next
								end #if ift.computationFreqCd == "EVERYCYCLEPERRATEFM" and policyMonth > 1

								evaluatedValue = nil
								if ift.facetTypeCd == "GROUPING"
									if ift.inputElementSource == "quotationProduct"
										#life facets are computed again once per cycle per rate for all plan lives and then grouped
										if !lifeFacetsComputedPerRate && illusFacetsPerLifePerCyclePerRate.size > 0 && policy.getPlanList.size > 0
											hmFundGroupedAttribValues = calculateLifeFacets(illustrationModel, illusFacetsPerLifePerCyclePerRate, quotation, results, quotationIO, illustrationRate)
											lifeFacetsComputedPerRate = true
										end
									else
										if !fundFacetsComputed and quotePlan.QuotationProductInvestmentFundListSize > 0
											hmFundGroupedAttribValues = calculateFundFacets(illusFacetsPerFund, quotation, results, quotationIO, illustrationRate, illustrationModel, groupSummationFacetNames, fundFacetsParseLevelHashMap)
											fundFacetsComputed = true
										end
									end

									if hmFundGroupedAttribValues
										evaluatedValue = hmFundGroupedAttribValues["Group_#{ift.inputDataElement}"]
										results.setAttr(ift.computedElementName, evaluatedValue)
										resFieldsPerCyclePerRate.addFieldValue(nil,ift.originalComputedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)

									end
								else
									@currSICalcRateDO = illustrationRate unless @currSICalcRateDO
									evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)

								end

								if groupSummationFacetNames.include? ift.originalComputedElementName
									fldResPrevMonth = siIllustrationResult[cycleCount - 2]
									fldResPerRatePrevMonth = fldResPrevMonth.fieldResultList[rateCounter]
									prevMonthVal = 0.0
									if fldResPerRatePrevMonth.containsFieldInMap("#{ift.originalComputedElementName}_summation")
										prevMonthVal = fldResPerRatePrevMonth.getFieldValue("#{ift.originalComputedElementName}_summation")
										prevMonthVal = (prevMonthVal.is_a? MobiSys::DataObjects::FieldValue) ? prevMonthVal.fieldValue : prevMonthVal
									end
									summation = prevMonthVal + evaluatedValue
									resFieldsPerCyclePerRate.addFieldValue(nil,"#{ift.originalComputedElementName}_summation", summation, ift.elementLabel, ift.computationOrder)
								end
								resFieldsPerCyclePerRate.addFieldValue(nil,ift.originalComputedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
								if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
									log(resFieldsPerCyclePerRate,ift.originalComputedElementName)
								end

								if ift.outputDisplayTypeCd == "PARTOFFIELD"
									setModelFieldData(quotation, policyYear, ift, evaluatedValue);
								end #part of field

								if evaluatedValue and ift.isBreakExpression
									if evaluatedValue.is_a?(String) && evaluatedValue.include?("break")
										shouldBreak = true
									end
								end
							end
							rateCounter += 1
						end
						@currSICalcRateDO = nil
					end

					#copy all the data that was computed once into each of the resultant fields.
					resFieldsOnceComputed.fieldValueList.each do |fldValueComputedOnce|
						resFieldsPerCycle.fieldValueList.insert((fldValueComputedOnce.sortOrder-1), fldValueComputedOnce)
					end

					break if shouldBreak
					quotationIO.computationCycles = cycleCount
					if illustrationModel.computationFrequencyCd == "YEARLY"
						percentage = ((cycleCount + ((parseCount - 1) * computationCycles.to_f))/(computationCycles.to_f * maxParseLevel) * 100 )
						WebView.execute_js("update_progress(\"#{percentage}\", \"#{calledFrom}\")")
					else
						if cycleCount%12 == 0
							# percentage = ((cycleCount * parseCount)/(computationCycles.to_f * maxParseLevel)) * 100
							percentage = ((cycleCount + ((parseCount - 1) * computationCycles.to_f))/(computationCycles.to_f * maxParseLevel) * 100 )
							WebView.execute_js("update_progress(\"#{percentage}\", \"#{calledFrom}\")")
						end
					end
					cycleCount += 1
				end  #end cycle count

				@currCycleCalcOutputData = nil
				illusFacetComputedOnceAtEnd.each do |ift|
					if ift.parseLevel != parseCount
						results.setAttr(ift.computedElementName, resFieldForHeader.getFieldValue(ift.computedElementName)) if resFieldForHeader.containsFieldInMap ift.computedElementName
						next
					end
					evaluatedValue = nil
					if ift.facetTypeCd=="COMPUTEDLOOKUP"
						evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO)
					else
						evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, nil)
					end
					resFieldForHeader.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)  #if ift.outputDisplayTypeCd
					if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
						log(resFieldForHeader,ift.computedElementName)
					end


					if ift.outputDisplayTypeCd == "PARTOFFIELD"
						setModelFieldData(quotation, 0, ift, evaluatedValue);
					end #part of field
				end #illusFacetComputedOnceAtEnd.each - end

				if illusFacetComputedOnceAtEndPerRate.size > 0
					rateCounter = 0
					illustrationModel.IllustrationRateList.each do |illustrationRate|
						quotationIO.currentRate = illustrationRate.rate
						resFieldsAtEndPerRate = nil
						if parseCount == 1
							resFieldsAtEndPerRate = MobiSys::DataObjects::FieldResult.new
							resFieldForHeader.addFieldResult resFieldsAtEndPerRate
						else
							resFieldsAtEndPerRate = resFieldForHeader.fieldResultList[rateCounter]
						end #parseCount == 1
						results.currIllusNetRate = illustrationRate.rate.to_f
						resFieldsAtEndPerRate.objectName = illustrationRate.rate.to_s

						illusFacetComputedOnceAtEndPerRate.each do |ift|
							if ift.parseLevel != parseCount
								results.setAttr("#{ift.computedElementName}#{illustrationRate.id}", resFieldsAtEndPerRate.getFieldValue(ift.computedElementName)) if resFieldsAtEndPerRate.containsFieldInMap(ift.getComputedElementName())
								next
							end  #if ift.parseLevel != parseCount
							evaluatedValue = nil
							origComputedElementName = ift.computedElementName 
							origComputedElementName = ift.origElementName if quotationIO.isTemplateBasedOutput != nil and quotationIO.isTemplateBasedOutput == true
							origExpression = ift.expression
							# ift.computedElementName="perRate_#{origComputedElementName}#{illustrationRate.rateTypeCd}"
							ift.computedElementName="#{origComputedElementName}#{illustrationRate.id}"
							newExp = ift.expression
							data = newExp.scan(/\b(self.perRate_[a-zA-Z0-9]*)\b/)
							data.each do |match|
								original = match[0].to_s
								newString = String.new(original.gsub("perRate_", ""))
								newString << illustrationRate.id.to_s
								newExp = newExp.sub(original, newString)
							end
							ift.expression = newExp
							case illustrationRate.rateTypeCd
							when "LOW"
								ift.expression = ift.expressionForLowRate if ift.expressionForLowRate.to_s != ""
							when "MEDIUM"
								ift.expression = ift.expressionForMediumRate if ift.expressionForMediumRate.to_s != ""
							when "HIGH"
								ift.expression = ift.expressionForHighRate if ift.expressionForHighRate.to_s != ""
							end

							if ift.facetTypeCd == "COMPUTEDLOOKUP"
								quotationIO.currentRate = illustrationRate.rate
								evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, quotationIO,origComputedElementName)
							else
								evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotePlan, nil,origComputedElementName)
							end
							ift.computedElementName = origComputedElementName
							ift.expression = origExpression
							resFieldsAtEndPerRate.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)  #if ift.outputDisplayTypeCd
							if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
								log(resFieldsAtEndPerRate,ift.computedElementName)
							end
						end  #illusFacetComputedOnceAtEndPerRate.each do |ift|
						rateCounter +=1
					end  #illustrationModel.IllustrationRateList.each do |illustrationRate|
				end #  if illusFacetComputedOnceAtEndPerRate.size > 0
				parseCount += 1
				#Copy over quotationParty.age into quotationParty.attainedAge as the age attribute has incremented in every cycle.
				#Copy over quotationParty.entryAge into quotationParty.age as that was the original value before incrementing.
				quotation.QuotationPartyList.each do |qp|
					qp.attainedAge = qp.age
					qp.age = qp.entryAge
				end
				break if shouldBreak
			end #end parseLevel count

			#Done. Finished.

			illusEndTime = Time.now
			#MobiSys::ProductUtil.disableCache
			stampStepTime(illusStartTime, "step-1calculateIllustration")
			RhoLog.error("CalculateIllustration","Calculated illustration at #{illusEndTime.to_s} in #{illusEndTime-illusStartTime}s")
			if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
				writelog("SIModel", quotation)
			end
			return quotationIO
		end
		###################################################################################################

		#method to add element evaluation value to hashmap for Output json
		def self.addElementToOutputMap(illusFacetDO, hmEvalVal,computedElementName =nil)
			elementName = (computedElementName.to_s != "") ? computedElementName : illusFacetDO.origElementName
			#Check if it is part of table then add it to the Ouput display map.
			if(@currCycleCalcOutputData != nil)
				#if evaluated once per cycle directly add it else add to fund map else to rate map else to rider map
				if(@currSICalcFundDO != nil)
					fundCalcMap = @currCycleCalcOutputData[elementName]
					if(fundCalcMap == nil)
						fundCalcMap = {}
						@currCycleCalcOutputData[elementName] = fundCalcMap
					end
					fundRateCalcMap = fundCalcMap[@currSICalcFundDO.fundCd]
					if(fundRateCalcMap == nil)
						fundRateCalcMap = {}
						fundCalcMap[@currSICalcFundDO.fundCd] = fundRateCalcMap
					end
					fundRateCalcMap[@currSICalcRateDO.rateTypeCd] = hmEvalVal
				elsif(@currSICalcRateDO != nil)
					rateCalcMap = @currCycleCalcOutputData[elementName]
					if(rateCalcMap == nil)
						rateCalcMap = {}
						@currCycleCalcOutputData[elementName] = rateCalcMap
					end
					rateCalcMap[@currSICalcRateDO.rateTypeCd] = hmEvalVal
				elsif (@currSICalcRiderDO != nil)
					partyRiderCalcMap = @currCycleCalcOutputData[elementName]
					if(partyRiderCalcMap == nil)
						partyRiderCalcMap = {}
						@currCycleCalcOutputData[elementName] = partyRiderCalcMap
					end
					riderCalcMap = partyRiderCalcMap[@currSICalcRiderDO.insuredPartyRefGuid]
					if(riderCalcMap == nil)
						riderCalcMap = {}
						partyRiderCalcMap[@currSICalcRiderDO.insuredPartyRefGuid] = riderCalcMap
					end
					riderCalcMap[@currSICalcRiderDO.productId] = hmEvalVal
				else #per cycle elements
					@currCycleCalcOutputData[elementName] = hmEvalVal
				end
			else #else check if defined once then add to output display
				if((illusFacetDO.computationFreqCd == "ONCE" || illusFacetDO.computationFreqCd == "ONCEATEND") && illusFacetDO.outputDisplayTypeCd != nil)
					@siCalcCompleteOutputData["GlobalData"][elementName] = hmEvalVal if @siCalcCompleteOutputData.class.name.to_s == "Hash"
				end
			end
		end


		def self.initializeIllustrationRates(quotationProduct, illustrationModel, product, quotationIO)
			returnRateFacet = product.getOverrideReturnRatesFacet
			if returnRateFacet and returnRateFacet.actionValue == "YES" and (quotationProduct.veryLowReturnRate or quotationProduct.lowReturnRate or quotationProduct.mediumReturnRate or quotationProduct.highReturnRate or quotationProduct.veryHighReturnRate)
				#if rates have been overwritten at a quotation level then these should be used and not the rates defined in the model.
				overrideIllusRateList = Array.new

				tempIllusRate = illustrationModel.getIllustrationRate("VERYLOW")
				if tempIllusRate or quotationProduct.veryLowReturnRate
					newIllusRateVeryLow = IllustrationRate.new
					#newIllusRateVeryLow.rate = quotationProduct.highReturnRate
					newIllusRateVeryLow.rateTypeCd = "VERYLOW"
					#newIllusRateVeryLow.rate = tempIllusRate.rate if newIllusRateVeryLow.rate == nil and tempIllusRate

					newIllusRateVeryLow.rate = (quotationProduct.veryLowReturnRate == nil and tempIllusRate) ? tempIllusRate.rate : quotationProduct.veryLowReturnRate
					newIllusRateVeryLow.id = 4
					overrideIllusRateList.push newIllusRateVeryLow
				end  #if tempIllusRate or quotationProduct.highReturnRate

				tempIllusRate = illustrationModel.getIllustrationRate("LOW")
				if tempIllusRate or quotationProduct.lowReturnRate
					newIllusRateLow = IllustrationRate.new
					#newIllusRateLow.rate = quotationProduct.highReturnRate
					newIllusRateLow.rateTypeCd = "LOW"
					#newIllusRateLow.rate = tempIllusRate.rate if newIllusRateLow.rate == nil and tempIllusRate

					newIllusRateLow.rate = (quotationProduct.lowReturnRate == nil and tempIllusRate) ? tempIllusRate.rate : quotationProduct.lowReturnRate
					newIllusRateLow.id = 3
					overrideIllusRateList.push newIllusRateLow
				end  #if tempIllusRate or quotationProduct.highReturnRate

				tempIllusRate = illustrationModel.getIllustrationRate("MEDIUM")
				if tempIllusRate or quotationProduct.mediumReturnRate
					newIllusRateMedium = IllustrationRate.new
					#newIllusRateMedium.rate = quotationProduct.mediumReturnRate
					newIllusRateMedium.rateTypeCd = "MEDIUM"
					#newIllusRateMedium.rate = tempIllusRate.rate if newIllusRateMedium.rate == nil and tempIllusRate

					newIllusRateMedium.rate = (quotationProduct.mediumReturnRate == nil and tempIllusRate) ? tempIllusRate.rate : quotationProduct.mediumReturnRate
					newIllusRateMedium.id = 2
					overrideIllusRateList.push newIllusRateMedium
				end  #if tempIllusRate or quotationProduct.mediumReturnRate

				tempIllusRate = illustrationModel.getIllustrationRate("HIGH")
				if tempIllusRate or quotationProduct.highReturnRate
					newIllusRateHigh = IllustrationRate.new
					#newIllusRateHigh.rate = quotationProduct.lowReturnRate
					newIllusRateHigh.rateTypeCd = "HIGH"
					#newIllusRateHigh.rate = tempIllusRate.rate if newIllusRateHigh.rate == nil and tempIllusRate

					newIllusRateHigh.rate = (quotationProduct.highReturnRate == nil and tempIllusRate) ? tempIllusRate.rate : quotationProduct.highReturnRate
					newIllusRateHigh.id = 1
					overrideIllusRateList.push newIllusRateHigh
				end  #if tempIllusRate or quotationProduct.mediumReturnRate

				tempIllusRate = illustrationModel.getIllustrationRate("VERYHIGH")
				if tempIllusRate or quotationProduct.veryHighReturnRate
					newIllusRateVeryHigh = IllustrationRate.new
					#newIllusRateVeryHigh.rate = quotationProduct.lowReturnRate
					newIllusRateVeryHigh.rateTypeCd = "VERYHIGH"
					#newIllusRateVeryHigh.rate = tempIllusRate.rate if newIllusRateVeryHigh.rate == nil and tempIllusRate

					newIllusRateVeryHigh.rate = (quotationProduct.veryHighReturnRate == nil and tempIllusRate) ? tempIllusRate.rate : quotationProduct.veryHighReturnRate
					newIllusRateVeryHigh.id = 0
					overrideIllusRateList.push newIllusRateVeryHigh
				end  #if tempIllusRate or quotationProduct.mediumReturnRate

				overrideIllusRateList.sort!{ |x,y| y.id <=> x.id }
				illustrationModel.setIllustrationRateList overrideIllusRateList
			else
				if illustrationModel.IllustrationRateListSize > 0
					returnRate = illustrationModel.IllustrationRateList[0]
					if returnRate and returnRate.fundCd
						rateTypeLookups = Lookupvalue.loadObject(:all, :conditions=>{{:name=>'key'}=>'RATETYPE'})
						if rateTypeLookups.size > 0
							averageIllusRateList = Array.new
							rateTypeLookups.each do |rateTypeLookup|
								rateType = rateTypeLookup.cd
								illustrationRateListForType = illustrationModel.getIllustrationRateListForType(rateType)
								next if illustrationRateListForType.empty?
								newIllusRate = IllustrationRate.new
								newIllusRate.rateTypeCd = rateType
								newIllusRate.policyYearFrom = nil
								newIllusRate.policyYearTo = nil
								newIllusRate.fundCd = nil
								averageIllusRateList.push newIllusRate

								averageRate = 0
								illustrationRateListForType.each do |illustrationRateForType|
									quotationProduct.QuotationProductInvestmentFundList.each do |fund|
										if fund.fundCd == illustrationRateForType.fundCd
											fund.allocationPerc = 0 unless fund.allocationPerc
											averageRate += (fund.allocationPerc.to_f/100 * illustrationRateForType.rate)
											newIllusRate.id = illustrationRateForType.id
											break
										end  #if fund.fundCd == illustrationRateForType.fundCd
									end  #quotationProduct.QuotationProductInvestmentFundList.each do |fund|
								end  #illustrationRateListForType.each do |illustrationRateForType|
								newIllusRate.rate = averageRate
							end  #rateTypeLookups.each do |rateTypeLookup|
							illustrationModel.setIllustrationRateList averageIllusRateList
							quotationIO.isSIModelRateFundWise = true
							#puts ">>>Average ratelist size: #{averageIllusRateList.size}"
							#puts ">>>RateList size 1: #{illustrationModel.IllustrationRateListSize}"
						end #if rateTypeLookups.size > 0
					elsif returnRate.policyYearFrom.to_s != "" && returnRate.policyYearTo.to_s != ""
						# if rates are defined year wise but not fund wise. then keep the rate id as the same since id is used for calculation
						# handling of year wise rates is done within the calculation loop itself
						rateTypeLookups = Lookupvalue.loadObject(:all, :conditions=>{{:name=>'key'}=>'RATETYPE'})
						if rateTypeLookups.size > 0
							rateTypeLookups.each do |rateTypeLookup|
								rateType = rateTypeLookup.cd
								illustrationRateListForType = illustrationModel.getIllustrationRateListForType(rateType)
								next if illustrationRateListForType.empty?
								illustrationRateListForType.each do |illusRate|
									# keep the same id for all the rate objects since data is used for further computation.
									illusRate.id = illustrationRateListForType.first.id
								end
							end
						end
					end
					illustrationModel.IllustrationRateList.sort!{ |x,y| x.rate <=> y.rate }
				end #if illustrationModel.IllustrationRateListSize > 0
			end #if returnRateFacet and returnRateFacet.actionValue == "YES" and quotationProduct.lowReturnRate
		end
		###################################################################################################


		def self.calculateWopRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, quotationIO, riderProductHash, riderList, hmGroupedSumValue)
			riderList.each do |quotationProduct|
				calculateWOPSumAssured(quotation, quotationProduct)
        		wopPremiumField = quotationProduct.product.getFacetValue('WOPPREMIUMCOMPONENT')
				calculateWOPPremium(quotation,quotationProduct,wopPremiumField) if wopPremiumField.to_s != ""
			end
			hmGroupedSumValue = calculateRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, quotationIO, riderProductHash, riderList, hmGroupedSumValue)
			return hmGroupedSumValue
		end
		###################################################################################################


		def self.calculateRiderFacets(illustrationModel, illusFacetsPerRider, quotation, results, quotationIO, riderProductHash, riderList, hmGroupedSumValue, currQuotationProductDO = nil)
			hmRiderAttributes = quotationIO.hmRiderComputedAttributes if quotationIO && quotationIO != nil
			listQuotationProductAdditional = Array.new
			#hmGroupedSumValue = Hash.new
			riderList.each do |quotationProduct|
				if (quotationProduct.productTypeCd.to_s != 'PLAN' && quotation.getBaseProduct.product && quotation.getBaseProduct.product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES" && (quotationProduct.selected != "on" &&quotationProduct.selected != "YES" )) || quotationProduct.removed == "YES"
					next
				end
				@currSICalcRiderDO = quotationProduct;
				resFieldsPerRider = MobiSys::DataObjects::FieldResult.new
				quotationProductAdditional = nil
				if currQuotationProductDO
					quotationProductAdditional = QuotationProductAdditional.find(:first, :conditions => {{:name => 'productRefGuid'} => quotationProduct.guid ,{:name =>'parentKey'} => currQuotationProductDO.object,:op => "AND" })
					unless quotationProductAdditional
						quotationProductAdditional = QuotationProductAdditional.new
						quotationProductAdditional.productRefGuid = quotationProduct.guid
						currQuotationProductDO.addQuotationProductAdditional(quotationProductAdditional)
					end
				end
				policyMonth = results.currPolicyMonth
				policyYear = results.currPolicyYear
				currParseCount = results.currBasicParseCount
				currentCycle = results.currCycleCount
				product = riderProductHash[quotationProduct.productId]
				if policyMonth == 1 and (policyYear > 1 || currParseCount > 1 || @isSolverCall) and quotationProduct.builtInRiderFl != "YES" and policyYear <= (quotationProduct.premiumPayingTerm.to_i + 1) && illustrationModel.modelFor.to_s == "SI"
					calculateModelBasedPremium(policyYear, quotation, quotationProduct, product)
					calculateRiderValues(quotation, quotationProduct,policyYear)
				end
				#initialize fields to 0
				quotationProduct.baseAnnualPremium = 0 unless quotationProduct.baseAnnualPremium
				quotationProduct.baseSumAssured = 0 unless quotationProduct.baseSumAssured
				quotationProduct.modalPremium = 0 unless quotationProduct.modalPremium
				quotationProduct.extraPremium = 0 unless quotationProduct.extraPremium


				illusFacetsPerRider.each do |ift|
					fieldValueEvalOnceForFilter =  eval("results.fieldValueEvalOnceForFilter#{quotationProduct.guid}")
					if ift.elementFilter
						filterArray = ift.elementFilter.split(",")
						next unless filterArray.include? fieldValueEvalOnceForFilter
					end

					evaluatedValue = evaluateField(illustrationModel, ift, quotation, results, quotationProduct, nil)
					groupedValue = hmGroupedSumValue["Group_#{ift.computedElementName}"]
					groupedValue = 0.0 unless groupedValue
					unless evaluatedValue.is_a? String
						groupedValue += evaluatedValue if !evaluatedValue.nil?
						hmGroupedSumValue["Group_#{ift.computedElementName}"] = groupedValue
					end
					resFieldsPerRider.addFieldValue(nil, ift.computedElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
					resFieldsPerRider.id = currentCycle
					resFieldsPerRider.versionID = currParseCount.to_i
					resFieldsPerRider.entityTypeCd = quotationProduct.product.longName
					#*************@WOPChanges start**********
					#check if inputDataElement is set if so then instantiate QuotationProductAdditional and set value in QuotationProductAdditional.
					if ift.inputDataElement != nil && currQuotationProductDO != nil
						fieldName = ift.inputDataElement
						eval("quotationProductAdditional.#{fieldName}=#{evaluatedValue.to_f}")
					end

					if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
						 log(resFieldsPerRider,ift.computedElementName)
					end
				end
				listQuotationProductAdditional.push(quotationProductAdditional) if currQuotationProductDO != nil
				if quotationIO && quotationIO != nil
					listResFieldRider = hmRiderAttributes[quotationProduct]
					unless listResFieldRider
						listResFieldRider = Array.new
						listResFieldRider.push resFieldsPerRider
						hmRiderAttributes[quotationProduct] = listResFieldRider
					else
						listResFieldRider.push resFieldsPerRider
					end
				end
			end #riderList.each do |quotationProduct|
			@currSICalcRiderDO = nil;
			if currQuotationProductDO != nil
				currQuotationProductDO.setQuotationProductAdditionalList(listQuotationProductAdditional)
			end
			#*************@WOPChanges end**********
			quotationIO.hmRiderComputedAttributes = hmRiderAttributes if quotationIO && quotationIO != nil
			return hmGroupedSumValue
		end
		###################################################################################################


		def self.calculateFundFacets(illusFacetsPerFund, quotation, results, quotationIO, illustrationRate, illustrationModel, groupSummationFacetNames, fundFacetsParseLevelHashMap)

			listQuotationProductFunds = quotation.getBaseProduct.QuotationProductInvestmentFundList
			hmFundAttributes = quotationIO.hmFundComputedAttributes
			hmGroupedSumValue = Hash.new
			currentCycle = results.currCycleCount

			currIllusNetRate = results.currIllusNetRate
			parseCount = 1
			maxParseLevel = fundFacetsParseLevelHashMap.keys.last
			while parseCount <= maxParseLevel

				listQuotationProductFunds.each do |qpif|
					# next unless qpif.allocationPerc and qpif.allocationPerc.to_f > 0 #no point in continuing further if allocation percent doesn't exist or is zero
					next unless (qpif.allocationPerc and qpif.allocationPerc.to_f > 0) or (qpif.topupAllocationPerc and qpif.topupAllocationPerc.to_f > 0) #no point in continuing further if allocation percent doesn't exist or is zero
					@currSICalcFundDO = qpif;
					fundRate = illustrationRate.rate
					if quotationIO.isSIModelRateFundWise
						illustrationFundRate = quotationIO.originalSIModel.getIllustrationRate(illustrationRate.rateTypeCd,qpif.fundCd,results.currPolicyYear)

						if illustrationFundRate == nil
							RhoLog.error("CalculateIllustration","No rate defined for fund: #{qpif.fundCd} for rate type: #{illustrationRate.rateTypeCd}")
							next
						end

						fundRate = illustrationFundRate.rate
						@currSICalcRateDO = illustrationFundRate;
						results.currIllusNetRate = fundRate.to_f
					end
					resFieldsPerFundPerRate = nil
					fieldResultPerFundCycle = nil

					results.investmentFund = qpif

					if parseCount == 1
						resFieldsPerFundPerRate = MobiSys::DataObjects::FieldResult.new
						resFieldsPerFundPerRate.id = currentCycle
						resFieldsPerFundPerRate.objectName = fundRate.to_s
						resFieldsPerFundPerRate.versionID = parseCount.to_i

						resFieldsPerFundPerRate.entityTypeCd = qpif.fundCd
						qpif.allocationPerc ||= 0
						listResFieldFundPerCycle = hmFundAttributes[qpif]
						unless listResFieldFundPerCycle
							listResFieldFundPerCycle = Array.new
							fieldResultPerFundCycle = MobiSys::DataObjects::FieldResult.new
							fieldResultPerFundCycle.id = currentCycle
							fieldResultPerFundCycle.entityTypeCd = qpif.FundCd
							fieldResultPerFundCycle.objectName = fundRate.to_s
							fieldResultPerFundCycle.versionID = parseCount.to_i
							fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate
							listResFieldFundPerCycle.push fieldResultPerFundCycle
							hmFundAttributes[qpif] = listResFieldFundPerCycle
						else
							if listResFieldFundPerCycle.size == currentCycle
								fieldResultPerFundCycle = listResFieldFundPerCycle[currentCycle - 1]
								fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate
							else
								fieldResultPerFundCycle = MobiSys::DataObjects::FieldResult.new
								fieldResultPerFundCycle.id = currentCycle
								fieldResultPerFundCycle.entityTypeCd = qpif.FundCd
								fieldResultPerFundCycle.objectName = fundRate.to_s
								fieldResultPerFundCycle.versionID = parseCount.to_i
								fieldResultPerFundCycle.fieldResultList.push resFieldsPerFundPerRate
								listResFieldFundPerCycle.push fieldResultPerFundCycle
							end
						end
					else
						fieldResultPerFundCycle = hmFundAttributes[qpif].at(currentCycle - 1)
						fieldResultPerFundCycle.fieldResultList.each do |fieldResDO|
							if fieldResDO.objectName == fundRate.to_s
								resFieldsPerFundPerRate = fieldResDO
								break
							end
						end
					end

					fundFacets = fundFacetsParseLevelHashMap[parseCount]
					fundFacets.each do |illusFacetDO|

						if illusFacetDO.elementFilter
							filterArray = illusFacetDO.elementFilter.split(",")
							next unless filterArray.include? results.fieldValueEvalOnceForFilter
						end

						evaluatedValue = 0

						if illusFacetDO.computationFreqCd == "ONCEPERFUND"
							methodName = "#{illusFacetDO.computedElementName}#{qpif.fundCd}".to_sym
							evaluatedValue = results.send methodName
							resFieldsPerFundPerRate.addFieldValue(nil,illusFacetDO.computedElementName, evaluatedValue, illusFacetDO.elementLabel, illusFacetDO.computationOrder)
							next
						end

						origComputedElementName = illusFacetDO.computedElementName
						illusFacetDO.computedElementName="#{origComputedElementName}#{qpif.fundCd}#{illustrationRate.id}"

						if illusFacetDO.rateTypeCd == nil or illusFacetDO.rateTypeCd == illustrationRate.rateTypeCd

							if illusFacetDO.facetTypeCd == "COMPUTEDLOOKUP"
								quotationIO.currentRate = fundRate
								quotationIO.currentRateTypeCd = illustrationRate.rateTypeCd
								quotationIO.currentQuotationPrdInvFundDO = qpif
								evaluatedValue = evaluateField(illustrationModel, illusFacetDO, quotation, results, quotation.getBaseProduct, quotationIO,origComputedElementName)
							elsif illusFacetDO.facetTypeCd == "GROUPING"
								evaluatedValue = hmGroupedSumValue["Group_#{illusFacetDO.inputDataElement}"]
								results.setAttr(illusFacetDO.computedElementName, evaluatedValue)
							else
								baseQuotationProduct = quotation.getBaseProduct
								baseQuotationProduct.fundCd = qpif.fundCd
								evaluatedValue = evaluateField(illustrationModel, illusFacetDO, quotation, results, baseQuotationProduct, nil,origComputedElementName)
								baseQuotationProduct.fundCd = nil
							end

						else

							results.setAttr(illusFacetDO.computedElementName, evaluatedValue)
						end

						illusFacetDO.computedElementName = origComputedElementName

						mapKey = "Group_#{illusFacetDO.computedElementName}"
						#mapKey = "Group_#{illusFacetDO.computedElementName}"
						mapKey = illusFacetDO.groupingName
						groupedObjVal = hmGroupedSumValue[mapKey]
						groupedVal = (groupedObjVal ? groupedObjVal.to_f : 0) + evaluatedValue.to_f
						hmGroupedSumValue[mapKey] = groupedVal
						resFieldsPerFundPerRate.addFieldValue(nil,illusFacetDO.computedElementName, evaluatedValue, illusFacetDO.elementLabel, illusFacetDO.computationOrder)

						if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
							log(resFieldsPerFundPerRate,illusFacetDO.computedElementName)
						end


						if groupSummationFacetNames.include? origComputedElementName
							prevMonthVal = 0.0
							if currentCycle - 2 >= 0
								fieldResultPerFundCyclePrev = hmFundAttributes[qpif].at(currentCycle - 2)

								if fieldResultPerFundCycle
									resFieldsPerFundPerRatePrev = nil
									fieldResultPerFundCyclePrev.fieldResultList.each do |fieldResDO|
										if fieldResDO.objectName == fundRate.to_s
											resFieldsPerFundPerRatePrev = fieldResDO
											break
										end
									end
									if resFieldsPerFundPerRatePrev.containsFieldInMap("#{origComputedElementName}_summation")
										prevMonthVal = resFieldsPerFundPerRatePrev.getFieldValue("#{origComputedElementName}_summation")
										prevMonthVal = (prevMonthVal.is_a? MobiSys::DataObjects::FieldValue) ? prevMonthVal.fieldValue : prevMonthVal
									end
								end
							end
							summation = prevMonthVal + evaluatedValue
							resFieldsPerFundPerRate.addFieldValue(nil,"#{illusFacetDO.computedElementName}_summation", summation, illusFacetDO.elementLabel, illusFacetDO.computationOrder)
						end

					end
				end
				parseCount += 1
				@currSICalcFundDO = nil;
				@currSICalcRateDO = nil;

			end
			results.currIllusNetRate = currIllusNetRate
			quotationIO.hmFundComputedAttributes = hmFundAttributes

			return hmGroupedSumValue
		end
		###################################################################################################


		def self.calculateLifeFacets(illustrationModel, illusFacetsPerLife, quotation, results, quotationIO, illustrationRate)

			listPolicyProductLives = quotation.getPlanList
			hmMultiLifeAttributes = quotationIO.hmMultiLifeComputedAttributes
			hmGroupedSumValue = Hash.new
			currentCycle = results.currCycleCount
			currIllusNetRate = results.currIllusNetRate
			maxParseLevel = parseCount = 1
			while parseCount <= maxParseLevel


				listPolicyProductLives.each do |policyProductLifeDO|


					fieldResultPerLifePerCycle = nil
					fieldResultPerLifePerCyclePerRate = nil
					fieldResultPerLifeToAddData = nil
					if parseCount == 1
						#add fieldresultdo first so that it is available for group operations
						listResFieldMultiLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO]
						if listResFieldMultiLifePerCycle != nil && listResFieldMultiLifePerCycle.size == currentCycle
							fieldResultPerLifePerCycle = listResFieldMultiLifePerCycle[currentCycle - 1]
							fieldResultPerLifePerCycle.versionID = parseCount.to_i
							fieldResultPerLifePerCycle.entityTypeCd = policyProductLifeDO.roleCd
						else
							fieldResultPerLifePerCycle = MobiSys::DataObjects::FieldResult.new
							fieldResultPerLifePerCycle.id = currentCycle
							fieldResultPerLifePerCycle.versionID = parseCount.to_i
							fieldResultPerLifePerCycle.entityTypeCd = policyProductLifeDO.roleCd

						end
						fieldResultPerLifeToAddData = fieldResultPerLifePerCycle
						#if rate wise data
						if illustrationRate
							fieldResultPerLifePerCyclePerRate = MobiSys::DataObjects::FieldResult.new
							fieldResultPerLifePerCyclePerRate.id = currentCycle
							fieldResultPerLifePerCyclePerRate.versionID = parseCount.to_i
							fieldResultPerLifePerCyclePerRate.entityTypeCd = policyProductLifeDO
							fieldResultPerLifePerCyclePerRate.objectName = currIllusNetRate
							fieldResultPerLifePerCyclePerRate.sortOrder = illustrationRate.id
							fieldResultPerLifeToAddData = fieldResultPerLifePerCyclePerRate
							fieldResultPerLifePerCycle.fieldResultList.addFieldResult(fieldResultPerLifePerCyclePerRate)
						end

						#if no records found for that life then create list for the first time.
						if listResFieldMultiLifePerCycle == nil
							listResFieldMultiLifePerCycle  = []
							listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)
							hmMultiLifeAttributes[policyProductLifeDO] = listResFieldMultiLifePerCycle
						elsif listResFieldMultiLifePerCycle.size < currentCycle
							listResFieldMultiLifePerCycle.push(fieldResultPerLifePerCycle)
						end
					else
						fieldResultPerLifePerCycle = hmMultiLifeAttributes[policyProductLifeDO][currentCycle - 1]
						fieldResultPerLifeToAddData = fieldResultPerLifePerCycle
						if illustrationRate
							fieldResultPerLifePerCycle.fieldResultList.each do |fieldResDO|
								if fieldResDO.objectName.to_s == illustrationRate.rate.to_s
									fieldResultPerLifeToAddData = fieldResDO
									break
								end
							end
						end
					end

					illusFacetsPerLife.each do |illusFacetDO|
						evaluatedValue = 0

						origComputedElementName = illusFacetDO.computedElementName
						if illustrationRate
							illusFacetDO.computedElementName="#{origComputedElementName}#{policyProductLifeDO.partyRoleCd}#{illustrationRate.id}"
							if illusFacetDO.rateTypeCd == nil or illusFacetDO.rateTypeCd == illustrationRate.rateTypeCd
								if illusFacetDO.facetTypeCd == "COMPUTEDLOOKUP"
									quotationIO.currentRate = currIllusNetRate
									quotationIO.currentRateTypeCd = illustrationRate.rateTypeCd
									evaluatedValue = evaluateField(illustrationModel, illusFacetDO, quotation, results, policyProductLifeDO, quotationIO,origComputedElementName)
								elsif illusFacetDO.facetTypeCd == "GROUPING"
									evaluatedValue = hmGroupedSumValue["Group_#{illusFacetDO.inputDataElement}"]
									results.setAttr(illusFacetDO.computedElementName, evaluatedValue)
								else
									evaluatedValue = evaluateField(illustrationModel, illusFacetDO, quotation, results, policyProductLifeDO, quotationIO,origComputedElementName)
								end
							else
								results.setAttr(illusFacetDO.computedElementName, evaluatedValue)
							end
						else
							illusFacetDO.computedElementName="#{origComputedElementName}#{policyProductLifeDO.partyRoleCd}"
							evaluatedValue = evaluateField(illustrationModel, illusFacetDO, quotation, results, policyProductLifeDO, quotationIO,origComputedElementName)
						end

						if illusFacetDO.outputDisplayTypeCd == "PARTOFFIELD"
							setModelFieldData(quotation, 1, illusFacetDO, evaluatedValue)
						end

						# after the fields is evaluated reset the expression, field names.. so that the next time they are ready for replacement as well
						illusFacetDO.computedElementName = origComputedElementName

						mapKey = "Group_#{illusFacetDO.computedElementName}"
						groupedObjVal = hmGroupedSumValue[mapKey]
						groupedVal = (groupedObjVal ? groupedObjVal.to_f : 0) + evaluatedValue.to_f
						hmGroupedSumValue[mapKey] = groupedVal
						fieldResultPerLifeToAddData.addFieldValue(nil,illusFacetDO.computedElementName, evaluatedValue, illusFacetDO.elementLabel, illusFacetDO.computationOrder)

						if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
							log(fieldResultPerLifeToAddData,illusFacetDO.computedElementName)
					    end

					end
				end
				parseCount += 1
			end
			results.currIllusNetRate = currIllusNetRate
			quotationIO.hmMultiLifeComputedAttributes = hmMultiLifeAttributes

			return hmGroupedSumValue
		end
		###################################################################################################


		def self.evaluateProductFacet(product,facetId)
			actionValue=nil
			validFacet=false
			#puts ">>>>>>>>>>>>>>>facetId<<<<<<<#{facetId.inspect}"
			listFacets=product.getFacets(facetId)
			#puts ">>>>>>>>>>>>>>>facetId<<<<<<<#{facetId.inspect}"

			listFacets.each do |fDO|
				if fDO.effectiveFromDt!=nil && fDO.effectiveToDt != nil
					if Time.now >Time.new(fDO.effectiveFromDt.to_s)  &&  Time.now < Time.new(fDO.effectiveToDt.to_s)
						validFacet=true
					end
				else
					validFacet=true
				end
				if validFacet
					if fDO.actionTypeCd=="VALUE" || fDO.actionTypeCd=="LOOKUP"
						actionValue=fDO.actionValue
					elsif fDO.actionTypeCd=="RULE"
						actionValue=fDO.ruleSeq
					end
					break
				end
			end
			return actionValue
		end
		###################################################################################################


		def self.stampStepTime(startTime,stepStr)
			$messages ||= Array.new
			endTime = Time.now
			$messages.push "#{stepStr} \t #{endTime-startTime}"
		end
		###################################################################################################


		def self.dumpMessages(fileName)
			file = File.open(fileName,'w')# do |f|
			$messages.each do |message|
				file.puts message
			end
			file.close
		end
		###################################################################################################


		def self.setModelFieldData(quotation,cycleCount,illusFacetDO,evaluatedVal)
			bdo = nil;

			if(illusFacetDO.inputElementSource != nil)

				if illusFacetDO.inputElementSource == "quotation"
					bdo = quotation;
				elsif illusFacetDO.inputElementSource == "quotationProduct"
					bdo = quotation.getBaseProduct
				elsif illusFacetDO.inputElementSource == "quotation.getParty(quotationProduct)"
					bdo = quotation.getPartyByRole("PRIMARY")
				elsif illusFacetDO.inputElementSource == "quotation.getPartyByRole('JOINT')"
					bdo = quotation.getPartyByRole("JOINT")
				elsif illusFacetDO.inputElementSource == "quotation.getPartyByRole('PROPOSER')"
					bdo = quotation.getPartyByRole("PROPOSER")
				elsif illusFacetDO.inputElementSource == "basePlan"
					bdo = quotation.getBaseProduct
				elsif illusFacetDO.inputElementSource == "quotation.getTopup( currPolicyYear )"

					#for topups and withdrawals create new instances and set as a schedule is to be generated.
					#new instance is to be created per cycle .. thus for each element in the cycle check if already created
					if(quotation.QuotationTopUpList.size == cycleCount)
						bdo = quotation.QuotationTopUpList.last
					else
						bdo = QuotationTopUp.new
						quotation.addQuotationTopUp(bdo)
					end
					#for the first cycle clear the existing data and going forward only the generated data would get added.
					if(cycleCount == 1 && bdo.guid == nil)
						bdo.removed = "YES"
						#if it is new implies created from screen so new one shd get created after clearing.
						bdo = QuotationTopUp.new
						quotation.addQuotationTopUp(bdo)
					end


				elsif illusFacetDO.inputElementSource == "quotation.getWithdrawal( currPolicyYear )"
					# #for topups and withdrawals create new instances and set as a schedule is to be generated.
					# if(quotation.QuotationWithdrawal.size == cycleCount)
					#   bdo = quotation.QuotationWithdrawal.last
					# else
					#   bdo = QuotationWithdrawal.new
					#   quotation.addQuotationWithdrawal(bdo)
					# end
					# #for the first cycle clear the existing data and going forward only the generated data would get added.
					# if(cycleCount == 1 && bdo.guid == nil)
					#   bdo.removed = "YES"
					#   #if it is new implies created from screen so new one shd get created after clearing.
					#   bdo = QuotationWithdrawal.new
					#   quotation.addQuotationWithdrawal(bdo)
					# end
					bdo = quotation.getWithdrawal(cycleCount)
					if quotation.QuotationWithdrawalList.include? bdo
						currPolicyWithdrawalDO = bdo
						if currPolicyWithdrawalDO.policyYearFrom and currPolicyWithdrawalDO.policyYearTo
							if currPolicyWithdrawalDO.policyYearFrom.to_i < currPolicyWithdrawalDO.policyYearTo.to_i
								quotation.removeQuotationWithdrawal bdo
								i = currPolicyWithdrawalDO.policyYearFrom.to_i
								while i <= currPolicyWithdrawalDO.policyYearTo.to_i
									generateWithdrawalDO = QuotationWithdrawal.new
									generateWithdrawalDO.policyYearFrom = i
									generateWithdrawalDO.policyYearTo = i
									quotation.addQuotationWithdrawal generateWithdrawalDO
									i += 1
								end
								quotation.QuotationWithdrawalList.sort!{|a,b| a.policyYearFrom.to_i <=> b.policyYearFrom.to_i}
								bdo = quotation.getWithdrawal(cycleCount)
							end
						end
					else
						bdo = nil
					end
				end
			end

			if(illusFacetDO.inputDataElement != nil && bdo != nil && evaluatedVal != nil)
				begin
					methodName = "#{illusFacetDO.inputDataElement.gsub(".to_f","")}=".to_sym
					bdo.send(methodName,evaluatedVal)
				rescue StandardError => boom
					puts ">>>StandardError occured in eval: #{boom}"
				end
			end
		end
		###################################################################################################


		def self.loadModel(facetId, quotationIO)
			modelCd = nil
			if(facetId == nil)
				return nil;
			else
				modelCd = nil;
				#For Si model we need to hardcode and fetch from other facets..
				if(facetId == "SIMODEL")

					# FacetDO otherDetailsFacet = this.dataObject.getFacetDO(ParameterDataConstants.FACET.OTHERDETAILS);
					# OtherDetailsDO otherDetailsDO = otherDetailsFacet.getOtherDetailsDO();
					# modelCd = otherDetailsDO.getIllustrationFormat();
					quotationProduct = quotationIO.baseDO.getBaseProduct
					otherDetailsFacet = quotationIO.baseProduct.getFacetFast("OTHERDETAILS")
					if otherDetailsFacet
						otherDetailsDO = otherDetailsFacet.OfflineOtherDetailsList[0]
						modelCd = otherDetailsDO.illustrationFormat
					end
				else
					baseProductSeq = quotationIO.baseDO.getBaseProduct.productSeq
					#puts ">>>baseProductId fouund is: #{baseProductSeq}"
					baseProduct = MobiSys::ProductUtil.getProduct(baseProductSeq)
					modelCd = baseProduct.getFacetValue(facetId)
					#puts ">>>ModeCd to be loaded is: #{modelCd}"
				end

				if(modelCd == nil)
					puts"<<<<<<<<<<<Error No Model defined for facet  "+facetId
					#throw new SymbiosysRuntimeException("No Model defined for facet " + facetId);
				end
				if modelCd
					illustrationmodel = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => modelCd})
					if(illustrationmodel == nil)
						puts"<<<<<<<<<<<Error No Master defined for Model code " + modelCd
						# throw new SymbiosysRuntimeException("No Master defined for Model code " + modelCd);
					end
					quotationIO.illustrationModel = illustrationmodel
					return illustrationmodel
				end
				return nil
			end
		end
		###################################################################################################


		def self.callCalculateIllustration(quotationIO, calledFrom = nil, generateExpression = true)
			if(quotationIO.illustrationModel.useGeneratedCode.to_s != "" && (quotationIO.illustrationModel.useGeneratedCode == "YES" || quotationIO.illustrationModel.useGeneratedCode == "YESWITHMERGING"))
				modelCd = quotationIO.illustrationModel.modelCd
				begin
					dbversion = Application.getValue('DBVERSION').value
					modelFileName = "#{Rho::Application.userFolder}#{modelCd}_#{generateExpression}_#{dbversion}"
					if !File.exist?("#{modelFileName}.rb") || !File.exist?("#{modelFileName}.iseq")
						Dir.glob("#{Rho::Application.userFolder}#{modelCd}_#{generateExpression}_*").each do |file|
							File.delete(file) if File.exists?(file)
						end
						quotationIO.illustrationModel.generateCode(generateExpression)
					end

					if Rho::System.platform != "APPLE"
						require modelFileName
					else
						b = Object.new.get_binding
						fileContents = File.read("#{modelFileName}.rb")
						eval(fileContents, b)
					end

					modelClass = Object.const_get(modelCd+generateExpression.to_s.upcase)
					quotationIO = modelClass.send(:calculateIllustration, quotationIO, calledFrom)
				rescue Exception => boom
					#Rho::Notification.showStatus("Error", "Error occured while generating illustration with generated code: #{boom}", "Close")
					Rho::Notification.showPopup( {:message => "Error occured while generating illustration with generated code: #{boom}", :title => "Error", :icon => :alert, :buttons => ['OK'] }, '/app/Product/popupCallback')
				end
			else
				quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, calledFrom)
			end
			return quotationIO
		end
		###################################################################################################


		def self.freeSpace
			GC.enable
			MobiSys::ProductUtil.resetCache
			$quotationIO = nil
			MobiSys::ProductUtil.resetProductCache
			MobiSys::MobiSysFixedSchema.class_variable_set(:@@children,{})
			MobiSys::MobiSysEntitySchema.class_variable_set(:@@children,{})
			MobiSys::PolicyBO.instance_variable_set(:@policy,nil)
			MobiSys::PolicyBO.instance_variable_set(:@quotation,nil)
			MobiSys::ProductBO.class_variable_set(:@@prdPremiumModelMap,{})
			MobiSys::ProductBO.instance_variable_set(:@baseAnnualPremium,nil)
			MobiSys::ProductBO.class_variable_set(:@@prdSAModelMap,{})
			GC.start
		end
		###################################################################################################
		def self.modellog(modeldo)
			@calculate_loggin_file = Array.new unless @calculate_loggin_file
			if Rho::RhoConfig.LogToOutput.to_i == 1 &&  @isCalculateIllust
				@calculate_loggin_file.push(" , , , , Model>>>>" + modeldo.modelFor + " >>>>, " + modeldo.modelCd )
			end
		end
		def self.log(fldResultDO,elementName)
			begin
					cycleCount = fldResultDO.id != nil ? fldResultDO.id.to_s : ""
					parseCount = fldResultDO.versionID != nil ? fldResultDO.versionID.to_s : ""
					rate = 	fldResultDO.objectName != nil ? fldResultDO.objectName : ""
					fundCd = fldResultDO.entityTypeCd != nil ? fldResultDO.entityTypeCd : ""
					@calculate_loggin_file.push( parseCount + " , " + cycleCount + " , " + rate + " , " + fundCd + " , "+  elementName + "," +fldResultDO.getFieldValue(elementName).to_s)

			rescue Exception => e
				Rho::Log.error("Error in log--->#{e}\n#{e.backtrace}", "Model Log")
			end
		end
		def self.writelog(logFor, quotation)
 			if ( logFor == "SIModel" )
			 	@calculate_loggin_file.unshift("Parse,Cycle,Rate,Fund/Rider,Element,Value")


			  end
			Dir.glob("#{Rho::RhoApplication.get_blob_folder}#{File::SEPARATOR}_#{quotation.quotationRefNum.gsub('/','')}_#{logFor}*").each do |file|
				File.delete(file) if File.exists?(file)
			end
			file = File.open(Rho::RhoApplication.get_blob_folder + File::SEPARATOR + "#{quotation.quotationRefNum.gsub('/','')}_#{logFor}#{Time.now.to_i}.csv",'w')
			@calculate_loggin_file.each do |lines|
				file.puts lines
			end
			file.close
			@calculate_loggin_file = nil
		end
=begin
		def self.validateProductLaunch(quotationProduct, msg, errors)
			if (quotationProduct.productId != nil) && ("LAUNCHED" != quotationProduct.product.productStatusCd)

				if $rhoconfig[:new_validations_in_productbo]== 'YES'
					tempErrorHash= Hash.new
				else
					tempErrorHash = errors
				end

				MobiSys::CommonUtil.addErrors(tempErrorHash, "productId", "ERR_PRDLAUNCH", [quotationionProduct.product.longName, quotationProduct.product.productVersion])
				MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationProduct.guid}-productId", "ERR_PRDLAUNCH", "ERR_PRDLAUNCH", nil,[quotationionProduct.product.longName, quotationProduct.product.productVersion])

				if $rhoconfig[:moduleForProductValidations] == "Quotation"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:QuotationProductDO][quotationProduct.guid.to_sym] = errors[:QuotationProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end

				if $rhoconfig[:moduleForProductValidations] == "Policy"
					if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
						errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][quotationProduct.guid.to_sym].is_a?(Hash)
						errors[:PolicyProductDO][quotationProduct.guid.to_sym] = errors[:PolicyProductDO][quotationProduct.guid.to_sym].merge(tempErrorHash)
					end
				end
				isValid=false
			end
			return isValid
		end
=end
		###################################################################################################


=begin
		def self.calculateAndValidateOtherPremium(quotation,quotationProduct,msg,errors)
			isValid=true
			sumModalExtraWithoutWop=0.0
			wopModalExtraPremium=0.0
			enterablePremium=0.0
			totalModalExtra=0.0
			minTargetPremium=0.0
			constantValue=0.0
			maxTargetPremium=0.0
			recommendedPremium=0.0
			unappliedPremium=0.0
			basePlan=nil
			otherddtls=nil
			minValue=nil

			otherPremiumFacet = quotationProduct.product.getFacet('OTHERPREMIUMCONSTANTVALUE')
			if otherPremiumFacet
				ruleSeq = otherPremiumFacet.ruleSeq
				if ruleSeq
					definitionTable=getProductDefinitionTable(ruleSeq,quotation,quotationProduct)
					if definitionTable != nil
						constantValue=definitionTable.rate==nil ? 0.0: definitionTable.rate
						minValue=definitionTable.minValue
					else
						return isValid
					end
				end
			end
			otherddtls=nil
			quotation.QuotationProductList.each do |quoteProduct|
				otherddtls=nil
				if quoteProduct.productTypeCd=="PLAN"
					if quoteProduct.capturedPremiumAmt!=nil
						enterablePremium=quoteProduct.capturedPremiumAmt
					end
					basePlan=quoteProduct
				else
					if quoteProduct.product !=nil
						otherDetFacet = quoteProduct.product.getOtherDetailsFacet
						otherddtls=otherDetFacet.OfflineOtherDetailsList[0] if otherDetFacet
					end
				end

				if otherddtls !=nil && otherddtls.isWOPFl!=nil && otherddtls.isWOPFl=="YES"
					if quoteProduct.modalPremium !=nil
						wopModalExtraPremium=wopModalExtraPremium+quoteProduct.modalPremium.to_f
					end
					#if quoteProduct.extraPremium!=nil
					# wopModalExtraPremium=wopModalExtraPremium+quoteProduct.extraPremium.to_f
					#end
				else
					if quoteProduct.modalPremium!=nil
						sumModalExtraWithoutWop=sumModalExtraWithoutWop+quoteProduct.modalPremium.to_f
					end
					# if quoteProduct.extraPremium!=nil
					#sumModalExtraWithoutWop=sumModalExtraWithoutWop+quoteProduct.extraPremium.to_f
					# end
				end
			end
			#total Model + Extra Premium
			totalModalExtra= sumModalExtraWithoutWop + wopModalExtraPremium;
			# max Target Premium Validation
			if enterablePremium !=nil && enterablePremium.to_f>0
				maxTarget1=(sumModalExtraWithoutWop.to_f*12)+constantValue.to_f
				maxTarget2=(0.2-(((wopModalExtraPremium.to_f*12))/enterablePremium.to_f))

				maxTargetPremium=maxTarget1/maxTarget2
				if basePlan.currencyCd !="USD"
					maxTargetPremium1=maxTargetPremium/100000
					maxTargetPremium=((maxTargetPremium1.to_i))*100000
				end

				minTarget1=(sumModalExtraWithoutWop.to_f*12)+constantValue.to_f
				minTarget2=(0.4875-(wopModalExtraPremium.to_f*12)/enterablePremium.to_f)
				minTargetPremium=minTarget1/minTarget2
				if basePlan.currencyCd !="USD"
					minTargetPremium1=(minTargetPremium/100000)
					minTargetPremium=((minTargetPremium1.to_i)*100000)+100000
				end

				if minValue !=nil && minTargetPremium<minValue
					minTargetPremium=minValue
				end
				if minTargetPremium>maxTargetPremium
					maxTargetPremium=minTargetPremium *10
				end
			end
			#Sum of all Modal + Extra Premium (Base + ALL riders) + Constant Value
			recommendedPremium=(totalModalExtra.to_f*12)+constantValue.to_f
			#(.4875* Enterable Premium )- Recommended Premium
			# unappliedPremium=(0.4875*enterablePremium.to_f)-recommendedPremium.to_f
			basePlan.minTargetPremium=minTargetPremium if basePlan.minTargetPremium.to_s == ""
			basePlan.maxTargetPremium=maxTargetPremium
			basePlan.recommendedPremium=recommendedPremium
			basePlan.unapliedPremium=unappliedPremium if basePlan.unapliedPremium.to_s == ""
			# if  $rhoconfig[:new_validations_in_productbo]== 'YES'
			#     tempErrorHash= Hash.new
			# else
			#     tempErrorHash = errors
			# end
			# if unappliedPremium<0
			#     MobiSys::CommonUtil.addErrors(tempErrorHash, "unappliedPremium", "UNAPPLIEDPREMIUM_MIN", [])
			#     isValid=false
			# end
			# if (unappliedPremium.to_f/enterablePremium.to_f)>0.2
			#     MobiSys::CommonUtil.addErrors(tempErrorHash, "unappliedPremium", "UNAPPLIEDPREMIUM_MAX", [])
			#     isValid=false
			# end
			# if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
			#     errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
			#     errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
			#     errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
			# end
			return isValid
		end
=end
		####################################################################################################


=begin
		def self.customeRiderRelationValidation(quotation,msg,errors)
			quotationProduct=MobiSys::QuotationBO.getBaseProduct(quotation)
			party=quotation.getParty(quotationProduct)
			isWOPFopt=false
			isWOPFopt1=false
			isFamilyTermOpt=false
			isFamilyTermOpt1=false
			isFamilyTermnOptOtherThanSpouse=false
			riders = MobiSys::QuotationBO.getRiders(quotation)
			if  $rhoconfig[:new_validations_in_productbo]== 'YES'
				tempErrorHash= Hash.new
			else
				tempErrorHash = errors
			end
			if party!=nil && party.roleCd=='PROPCUMINS' && quotationProduct.product.getFacetValue('VALIDATERIDERRELATION')=="YES"
				riders.each do|rider|
					if (rider.productId.include? 'WOPI') || (rider.productId.to_s.include? 'WPPI')
						isWOPFopt=true
						break
					end
					if (rider.productId.include? 'WOPF') || (rider.productId.include? 'WPPF')
						isWOPFopt1=true
						break
					end
				end
				if isWOPFopt==true
					riders.each do|rider1|
						party1=quotation.getParty(rider1)
						if rider1.productId=='FTR' && party1.relationCd!=nil && party1.relationCd!="SPOUSE"
							isFamilyTermOpt=true
							break
						end
					end
					if isFamilyTermOpt
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RIDERRELATION", ["FTR", "WPPF", "WOPF","W0PI","WPPI" , quotationProduct.product.longName])
					end
				elsif isWOPFopt1
					spouseExist=false
					partyList=quotation.QuotationPartyList
					partyList.each do|spouseParty|
						if spouseParty.relationCd=="SPOUSE"
							spouseExist=true
							break
						end
					end
					riders.each do|rider1|
						party1=quotation.getParty(rider1)
						if rider1.productId=='FTR' && party1.relationCd!=nil && party1.relationCd=="SPOUSE"
							isFamilyTermOpt1=true
						end
						if rider1.productId=='FTR' && party1.relationCd!=nil && party1.relationCd!="SPOUSE"
							isFamilyTermnOptOtherThanSpouse=true
						end
					end
					if !isFamilyTermOpt1 && spouseExist
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RIDERRELATIONMAND", ["FTR", "WPPF", "WOPF", quotationProduct.product.longName])
					end
					if isFamilyTermnOptOtherThanSpouse
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RIDERRELATION", ["FTR", "WPPF", "WOPF" ,"W0PI","WPPI" , quotationProduct.product.longName])
					end
				else
					riders.each do|rider1|
						party1=quotation.getParty(rider1)
						if rider1.productId=='FTR'
							isFamilyTermOpt=true
							break
						end
					end
					if isFamilyTermOpt
						MobiSys::CommonUtil.addErrors(tempErrorHash, "relationCd", "ERR_RIDERRELATION", ["FTR", "WPPF", "WOPF" ,"W0PI","WPPI" , quotationProduct.product.longName])
					end
				end
			end
			if $rhoconfig[:moduleForProductValidations] == "Quotation"
				if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					errors[:QuotationDO] = Hash.new if !errors[:QuotationDO].is_a?(Hash)
					errors[:QuotationDO][quotation.guid.to_sym] = Hash.new if !errors[:QuotationDO][quotation.guid.to_sym].is_a?(Hash)
					errors[:QuotationDO][quotation.guid.to_sym] = errors[:QuotationDO][quotation.guid.to_sym].merge(tempErrorHash)
				end
			end
			if $rhoconfig[:moduleForProductValidations] == "Policy"
				if !tempErrorHash.empty? && $rhoconfig[:new_validations_in_productbo]== 'YES'
					errors[:PolicyDO] = Hash.new if !errors[:PolicyDO].is_a?(Hash)
					errors[:PolicyDO][quotation.guid.to_sym] = Hash.new if !errors[:PolicyDO][quotation.guid.to_sym].is_a?(Hash)
					errors[:PolicyDO][quotation.guid.to_sym] = errors[:PolicyDO][quotation.guid.to_sym].merge(tempErrorHash)
				end
			end
		end
=end
		###################################################################################################
	end
end

begin
    require 'Product/product_b_o_company'
rescue LoadError => e
    puts 'product_b_o_company not included'
end

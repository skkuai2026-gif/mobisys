module MobiSys
	class ProductBO

		def self.validateFundAllocation(quotation, quotationProduct, fundAllocationDT, msg, errors)
			return true unless MobiSys::Validation.validateMethodCall(quotationProduct,"validateFunds",$rhoconfig[:moduleForProductValidations])
			funds = quotationProduct.QuotationProductInvestmentFundList

			allocationPerc = 0.0
			totalTopupPercent = 0.0
			investmentFundHM=Hash.new
			selectedFundCds = []
			selectedFundsHash = {}

			funds.each do |fund|
				next if fund.removed.to_s == "YES"
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
					if fund.allocationPerc.to_i > 0
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
										MobiSys::CommonUtil.addErrors(tempErrorHash, "allocationPerc", "ERR_MINMAXFUND", [MobiSys::BrowserHelper.getLabel('ALLOCATIONPERCENT'),investFund.allocationPerc.to_s, modelfund.minFundAllocPerc.to_s,modelfund.maxFundAllocPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{investFund.guid}-allocationPerc", "ERR_MINMAXFUND", "ERR_MINMAXFUND", nil,[MobiSys::BrowserHelper.getLabel('ALLOCATIONPERCENT'),investFund.allocationPerc.to_i, modelfund.minFundAllocPerc.to_s,modelfund.maxFundAllocPerc.to_s,MobiSys::BrowserHelper.getLabel(selectedFundsHash[investFund.fundCd])])
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
						MobiSys::CommonUtil.addErrors(tempErrorHash, 'allocationPerc', "ERR_INVESTMENTPERCENTAGE", ['Allocation',allocationPerc.to_s])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-allocationPerc", "ERR_INVESTMENTPERCENTAGE", "ERR_INVESTMENTPERCENTAGE", nil,['Allocation',allocationPerc.to_i])
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
				party = quotation.getParty(quotationProduct)
	            quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!="" and quotationProduct.combinedEntryAge.to_s == ""
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
						if riderGroupDefinition != nil
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
						if riderGroupDefinition != nil
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
					if $isValidatePolicy != true && additionalModelSetFacet != nil && additionalModelSetFacet.actionValue.to_s != ""
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
		
	end
end
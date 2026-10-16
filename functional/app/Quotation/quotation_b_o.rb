require 'Product/product_b_o'
require 'CommonModules/commonutil'
require 'date'
require 'singleton'

module MobiSys
	class QuotationBO
		include Singleton
		include MobiSys::CommonUtil

		PENDING = "PENDING"
		COMPLETED = "COMPLETED"
		ACCEPTED = "ACCEPTED"
		SYNCDONE = "SYNCDONE"

		################################################################################
		#-----------------Code based on Validation Metadata Sheet Start----------------#
		################################################################################

		def self.validateWithdrawalsPolicYear(quotation, errors)
			isValid = true
			isOverlap = false;

			withdrawals = getWithdrawals(quotation)

			withdrawals.each do |withdrawal|
				if withdrawal.removed != "YES"
					tempErrorHash = Hash.new
					if withdrawal.policyYearFrom.to_s ==""
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearFrom", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('withdrawalFl') << " " <<  MobiSys::BrowserHelper.getLabel('policyYearFrom')])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{withdrawal.guid}-policyYearFrom", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('withdrawalFl') << " " <<  MobiSys::BrowserHelper.getLabel('policyYearFrom')])
						end
						isValid = false
					elsif withdrawal.policyYearTo.to_s ==""
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('withdrawalFl') << " " <<  MobiSys::BrowserHelper.getLabel('policyYearTo')])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{withdrawal.guid}-policyYearTo", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('withdrawalFl') << " " <<  MobiSys::BrowserHelper.getLabel('policyYearTo')])
						end
						isValid = false
					elsif withdrawal.policyYearTo.to_i < withdrawal.policyYearFrom.to_i
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearFrom", "ERR_POLICYYEARTOINVALID", [MobiSys::BrowserHelper.getLabel(withdrawal.policyYearFrom.to_s),MobiSys::BrowserHelper.getLabel(withdrawal.policyYearTo.to_s),MobiSys::BrowserHelper.getLabel('withdrawalFl')])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{withdrawal.guid}-policyYearTo", "ERR_POLICYYEARTOINVALID", "ERR_POLICYYEARTOINVALID", nil, [MobiSys::BrowserHelper.getLabel(withdrawal.policyYearFrom.to_s),MobiSys::BrowserHelper.getLabel(withdrawal.policyYearTo.to_s),MobiSys::BrowserHelper.getLabel('withdrawalFl')])
						end
						isValid = false
					end
					if withdrawal.dateFrom.to_s !="" && withdrawal.dateTo.to_s !="" && withdrawal.dateFrom.to_i >  withdrawal.dateTo.to_i
						MobiSys::CommonUtil.registerException(quotation.guid, "#{withdrawal.guid}-dateFrom", "ERR_DATE2AFTER", "ERR_DATE2AFTER", nil, [MobiSys::BrowserHelper.getLabel(withdrawal.dateFrom.to_s),MobiSys::BrowserHelper.getLabel(withdrawal.dateTo.to_s),MobiSys::BrowserHelper.getLabel('withdrawalFl'),""])
						isValid = false
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if !tempErrorHash.empty?
							errors[:QuotationWithdrawalDO] = Hash.new if !errors[:QuotationWithdrawalDO].is_a?(Hash)
							errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym] = Hash.new if !errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym].is_a?(Hash)
							errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym] = errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end

			withdrawals.each_with_index do |withdrawal, i|
				if withdrawal.removed != "YES"
					tempErrorHash = Hash.new
					if withdrawals[i+1].to_s != ""
						fromA = withdrawals[i].policyYearFrom.to_i
						toA = withdrawals[i].policyYearTo.to_i
						fromB = withdrawals[i+1].policyYearFrom.to_i
						toB = withdrawals[i+1].policyYearTo.to_i

						if fromA.to_s != "" && toA.to_s != "" && fromB.to_s != "" && toB.to_s != ""
							isFromABeforeToB = fromA <= toB
							isToAAfterFromB = toA >= fromB
							isCurrentPairOverlap = isFromABeforeToB && isToAAfterFromB
							if isCurrentPairOverlap
								isOverlap = true
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearFrom", "ERR_WITHDRAWOVERLAP", [])
								else
									MobiSys::CommonUtil.registerException(quotation.guid, "#{withdrawal.guid}-policyYearFrom", "ERR_WITHDRAWOVERLAP", "ERR_WITHDRAWOVERLAP", nil, [])
								end
							end
						end
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if !tempErrorHash.empty?
							errors[:QuotationWithdrawalDO] = Hash.new if !errors[:QuotationWithdrawalDO].is_a?(Hash)
							errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym] = Hash.new if !errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym].is_a?(Hash)
							errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym] = errors[:QuotationWithdrawalDO][withdrawal.guid.to_sym].merge(tempErrorHash)
						end
					end
					break if isOverlap
				end
			end

			return isValid
		end

		###################################################################################################

		def self.validateRiderPlanOption(quotation, errors)
			isValid = true
			riders = getRiders(quotation)
			riders.each do |rider|
				tempErrorHash = Hash.new
				riderProduct = rider.product
				if riderProduct == nil
					riderProduct = MobiSys::ProductUtil.getProduct(rider.productSeq)
					rider.product = riderProduct
				end
				if riderProduct != nil
					planOptionFacet = rider.product.getFacet('PLANOPTION')
					if planOptionFacet
						if (rider.productPlanOptionCd.to_s == "" )
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "productPlanOptionCd", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('RIDER') << " " << MobiSys::BrowserHelper.getLabel(rider.product.longName)])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{rider.guid}-productPlanOptionCd", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('RIDER') << " " <<  MobiSys::BrowserHelper.getLabel(rider.product.longName)])
							end
							isValid = false
						end
					end
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if !tempErrorHash.empty?
						errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
						errors[:QuotationProductDO][rider.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][rider.guid.to_sym].is_a?(Hash)
						errors[:QuotationProductDO][rider.guid.to_sym] = errors[:QuotationProductDO][rider.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validateBasePlanPlanOption(quotation, errors)
			isValid = true
			baseProduct = quotation.getBasePlan
			product = nil

			if baseProduct
				if baseProduct.product == nil
		            product = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
		            baseProduct.product = product
		        else
		            product = baseProduct.product
		        end

		        if product
		        	tempErrorHash = Hash.new
		        	planOptionFacet = product.getFacet('PLANOPTION')
		        	if baseProduct.productPlanOptionCd.to_s == "" and planOptionFacet != nil and planOptionFacet.OfflinePlanOptionList.size > 0
		        		unless $rhoconfig[:TABFEATUREREQD]
		        			MobiSys::CommonUtil.addErrors(tempErrorHash, "productPlanOptionCd", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('PRODUCT') << " " << MobiSys::BrowserHelper.getLabel(product.longName)])
		        		else
		        			MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-productPlanOptionCd", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('PRODUCT') << " " <<  MobiSys::BrowserHelper.getLabel(product.longName)])
		        		end
		        		isValid = false
		        	end
		        	unless $rhoconfig[:TABFEATUREREQD]
						if !tempErrorHash.empty?
							errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
							errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
							errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
						end
					end
		        end
			end
			return isValid
	    end

		###################################################################################################

		def self.validateTopupsPolicYear(quotation, errors)
			isValid = true
			quotation.QuotationTopUpList.each do |quotationTopup|
				tempErrorHash = Hash.new
				if quotationTopup.policyYearTo.to_s != "" && quotationTopup.policyYearFrom.to_s != "" && quotationTopup.policyYearTo.to_i < quotationTopup.policyYearFrom.to_i
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_POLICYYEARTOINVALID", [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearFrom.to_s),MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearTo.to_s),MobiSys::BrowserHelper.getLabel(quotationTopup.topUpTypeCd.to_s) ])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationTopup.guid}-policyYearTo", "ERR_POLICYYEARTOINVALID", "ERR_POLICYYEARTOINVALID", nil, [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearFrom.to_s),MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearTo.to_s),MobiSys::BrowserHelper.getLabel(quotationTopup.topUpTypeCd.to_s) ])
					end
					isValid = false
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if !tempErrorHash.empty?
						errors[:QuotationTopUpDO ] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
						errors[:QuotationTopUpDO][quotationTopup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][quotationTopup.guid.to_sym].is_a?(Hash)
						errors[:QuotationTopUpDO][quotationTopup.guid.to_sym] = errors[:QuotationTopUpDO][quotationTopup.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validateRateOfReturn(quotation, errors)
			isValid = true
			basePlan = quotation.getBasePlan
			tempErrorHash = Hash.new
			if basePlan.lowReturnRate.to_s != "" && basePlan.mediumReturnRate.to_s != "" && basePlan.lowReturnRate.to_f >= basePlan.mediumReturnRate.to_f
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "mediumReturnRate", "ERR_RATEOFRETURNINVALID", [MobiSys::BrowserHelper.getLabel('mediumReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRate.to_s),MobiSys::BrowserHelper.getLabel('lowReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRate.to_s)  ])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-mediumReturnRate", "ERR_RATEOFRETURNINVALID", "ERR_RATEOFRETURNINVALID", nil, [MobiSys::BrowserHelper.getLabel('mediumReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRate.to_s),MobiSys::BrowserHelper.getLabel('lowReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRate.to_s)  ])
				end
				isValid = false
			elsif basePlan.mediumReturnRate.to_s != "" && basePlan.highReturnRate.to_s != "" && basePlan.mediumReturnRate.to_f >= basePlan.highReturnRate.to_f
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "highReturnRate", "ERR_RATEOFRETURNINVALID", [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),MobiSys::BrowserHelper.getLabel('mediumReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRateto_s)  ])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-highReturnRate", "ERR_RATEOFRETURNINVALID", "ERR_RATEOFRETURNINVALID", nil, [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),MobiSys::BrowserHelper.getLabel('mediumReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRateto_s)  ])
				end
				isValid = false
			elsif basePlan.lowReturnRate.to_s != "" && basePlan.highReturnRate.to_s != "" && basePlan.lowReturnRate.to_f >= basePlan.highReturnRate.to_f
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "highReturnRate", "ERR_RATEOFRETURNINVALID", [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),MobiSys::BrowserHelper.getLabel('lowReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRateto_s)  ])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-highReturnRate", "ERR_RATEOFRETURNINVALID", "ERR_RATEOFRETURNINVALID", nil, [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),MobiSys::BrowserHelper.getLabel('lowReturnRate'), MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRateto_s)  ])
				end
				isValid = false
			end

			if basePlan.lowReturnRate.to_s != "" && basePlan.lowReturnRate.to_i <= 0
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "lowReturnRate", "ERR_INVALIDRATE", [MobiSys::BrowserHelper.getLabel('lowReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRate.to_s),"0"])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-lowReturnRate", "ERR_INVALIDRATE", "ERR_INVALIDRATE", nil, [MobiSys::BrowserHelper.getLabel('lowReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.lowReturnRate.to_s),"0"])
				end
				isValid = false
			end
			if basePlan.mediumReturnRate.to_s != "" && basePlan.mediumReturnRate.to_i <= 0
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "mediumReturnRate", "ERR_INVALIDRATE", [MobiSys::BrowserHelper.getLabel('mediumReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRate.to_s),"0"])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-mediumReturnRate", "ERR_INVALIDRATE", "ERR_INVALIDRATE", nil, [MobiSys::BrowserHelper.getLabel('mediumReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.mediumReturnRate.to_s),"0"])
				end
				isValid = false
			end
			if basePlan.highReturnRate.to_s != "" && basePlan.highReturnRate.to_i <= 0
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "highReturnRate", "ERR_INVALIDRATE", [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),"0"])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{basePlan.guid}-highReturnRate", "ERR_INVALIDRATE", "ERR_INVALIDRATE", nil, [MobiSys::BrowserHelper.getLabel('highReturnRate'),MobiSys::BrowserHelper.getLabel(basePlan.highReturnRate.to_s),"0"])
				end
				isValid = false
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if !tempErrorHash.empty?
					errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
					errors[:QuotationProductDO][basePlan.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][basePlan.guid.to_sym].is_a?(Hash)
					errors[:QuotationProductDO][basePlan.guid.to_sym] = errors[:QuotationProductDO][basePlan.guid.to_sym].merge(tempErrorHash)
				end
			end

			return isValid
		end

		###################################################################################################

		def self.validateTopup(quotation, errors)
			isValid = true
			basePlan = quotation.getBasePlan
			quotation.QuotationTopUpList.each do |quotationTopup|
				tempErrorHash = Hash.new
				if quotationTopup.policyYearTo.to_s != "" && basePlan.productTerm.to_s != "" && quotationTopup.policyYearTo.to_i > basePlan.productTerm.to_i
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_TOPUPTOYEAR", [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearTo),MobiSys::BrowserHelper.getLabel(basePlan.productTerm.to_s)])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationTopup.guid}-policyYearTo", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil, [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearTo),MobiSys::BrowserHelper.getLabel(basePlan.productTerm.to_s)])
					end
					isValid = false
				elsif quotationTopup.policyYearFrom.to_s != "" && basePlan.productTerm.to_s != "" && quotationTopup.policyYearFrom.to_i > basePlan.productTerm.to_i
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(tempErrorHash, "policyYearTo", "ERR_TOPUPTOYEAR", [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearFrom),MobiSys::BrowserHelper.getLabel(basePlan.productTerm.to_s)])
					else
						MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationTopup.guid}-policyYearTo", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil, [MobiSys::BrowserHelper.getLabel(quotationTopup.policyYearFrom),MobiSys::BrowserHelper.getLabel(basePlan.productTerm.to_s)])
					end
					isValid = false
				end
				unless $rhoconfig[:TABFEATUREREQD]
					if !tempErrorHash.empty?
						errors[:QuotationTopUpDO] = Hash.new if !errors[:QuotationTopUpDO].is_a?(Hash)
						errors[:QuotationTopUpDO][quotationTopup.guid.to_sym] = Hash.new if !errors[:QuotationTopUpDO][quotationTopup.guid.to_sym].is_a?(Hash)
						errors[:QuotationTopUpDO][quotationTopup.guid.to_sym] = errors[:QuotationTopUpDO][quotationTopup.guid.to_sym].merge(tempErrorHash)
					end
				end
			end
			return isValid
		end

		######################################################################################

		def self.checkFund(quotation,errors)
			isValid = true
			tempErrorHash = Hash.new
			facetData = {}
			facetData = $globalFacetHash[:basic] if $globalFacetHash
			baseProduct = getBaseProduct(quotation)
            product = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
			if facetData != nil && facetData.empty?
				if product
					facetData[:renderFundPanel] = MobiSys::BrowserHelper.renderPanel?('FUNDSREQUIRED', product)
				end
				facetData[:renderPortfoliomodelcd] = MobiSys::BrowserHelper.renderField?('com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO.portfolioModelCd')
			end
			if facetData[:renderFundPanel]
				facetData = $globalFacetHash[:fund] if $globalFacetHash
				if facetData[:renderPortfoliomodelcd]
					investmentFundsList = baseProduct.QuotationProductInvestmentFundList.select{|x| x.removed.to_s != "YES"}
					if baseProduct.portfolioModelCd.to_s == ""
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "portfolioModelCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('fundCd') << " " <<  MobiSys::BrowserHelper.getLabel('portfolioModelCd')])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-portfolioModelCd", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('fundCd') << " " <<  MobiSys::BrowserHelper.getLabel('portfolioModelCd')])
						end
						isValid = false
					elsif(investmentFundsList == nil || investmentFundsList.size == 0)
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "portfolioModelCd", "ERR_MANDATORY", ['Fund Allocation'])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-portfolioModelCd", "ERR_MANDATORY", "ERR_MANDATORY", nil, ['Fund Allocation'])
						end
						isValid = false
					end
				end
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if !tempErrorHash.empty?
					errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
				end
			end
			return isValid
		end

		#Validates that Base Plan exists on the Quotation
		def self.checkBasePlan(quotation,errors)
			basePlanExists = true
			basePlan = quotation.getBasePlan
			if basePlan.productId.to_s == ""
				MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil,[MobiSys::BrowserHelper.getLabel('PLAN')])
				basePlanExists = false
			end
			return basePlanExists
		end

		def self.checkRoleExists(quotation,roleCd)
			roleExists = true
			partyRoleList = quotation.getPartyListByRoleCd(roleCd)
			if partyRoleList.size == 0
				MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil,[MobiSys::BrowserHelper.getLabel(roleCd)])
				roleExists = false
			end
			return roleExists
		end

		def self.checkProposerExists(quotation,errors)
			proposerExists = checkRoleExists(quotation,'PROPOSER')
			return proposerExists
		end

		def self.checkInsuredExists(quotation,errors)
			insuredExists = checkRoleExists(quotation,'PRIMARY')
			return insuredExists
		end

		def self.checkJointLife(quotation,errors)
			jointLifeExists = true
			if quotation.jointLife == "YES"
				jointLifeExists = checkRoleExists(quotation,'JOINT')
			end
			return jointLifeExists
		end

		###################################################################################################

		def self.validatePremiumHolidayYear(quotation, errors)
			isValid = true
			baseProduct = getBaseProduct(quotation)
			tempErrorHash = Hash.new
			if quotation.quotationDt.to_s != ""
				quotationYear = DateTime.strptime(quotation.quotationDt.to_s,"%Y-%m-%d %H:%M:%S %z").strftime('%Y')
				if baseProduct.to_s != "" && baseProduct.premiumHolidayYear.to_s != ""
					if baseProduct.premiumHolidayYear.to_i < quotationYear.to_i
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "premiumHolidayYear", "ERR_PREMIUMHOLIDAY", "")
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-premiumHolidayYear", "ERR_PREMIUMHOLIDAY", "ERR_PREMIUMHOLIDAY", nil)
						end
						isValid = false
					end
				end
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if !tempErrorHash.empty?
					errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validatePdfPeriod(quotation, errors)
			isValid = true
			baseProduct = getBaseProduct(quotation)
			tempErrorHash = Hash.new
			if baseProduct.to_s != "" && baseProduct.pdfPeriod.to_s != "" && baseProduct.premiumPayingTerm.to_s != "" && baseProduct.pdfPeriod.to_i > baseProduct.premiumPayingTerm.to_i
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(tempErrorHash, "pdfPeriod", "ERR_QUOTATIONMIN", [MobiSys::BrowserHelper.getLabel('pdfPeriod') + " " + MobiSys::BrowserHelper.getLabel(baseProduct.pdfPeriod.to_s), MobiSys::BrowserHelper.getLabel('PREMIUMPAYINGTERM') + " " + MobiSys::BrowserHelper.getLabel(baseProduct.premiumPayingTerm.to_s)  ])
				else
					MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-pdfPeriod", "ERR_QUOTATIONMIN", "ERR_QUOTATIONMIN", nil, [MobiSys::BrowserHelper.getLabel('pdfPeriod') + " " + MobiSys::BrowserHelper.getLabel(baseProduct.pdfPeriod.to_s), MobiSys::BrowserHelper.getLabel('PREMIUMPAYINGTERM') + " " + MobiSys::BrowserHelper.getLabel(baseProduct.premiumPayingTerm.to_s)  ])
				end
				isValid = false
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if !tempErrorHash.empty?
					errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validateTargetPeriod(quotation, errors)
			isValid = true
			baseProduct = getBaseProduct(quotation)
			tempErrorHash = Hash.new
			if baseProduct.targetPeriodRefCd.to_s != "" && baseProduct.premiumPayingTerm.to_s != "" && baseProduct.targetPeriod.to_s != ""
				if baseProduct.targetPeriodRefCd == "DURATION"
					if (baseProduct.targetPeriod.to_i > baseProduct.premiumPayingTerm.to_i) || (baseProduct.targetPeriod.to_i < 1)
						unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(tempErrorHash, "targetPeriod", "ERR_TARGETPERIOD", ["1",MobiSys::BrowserHelper.getLabel(basePlan.premiumPayingTerm.to_s)])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-targetPeriod", "ERR_TARGETPERIOD", "ERR_TARGETPERIOD", nil, ["1",MobiSys::BrowserHelper.getLabel(basePlan.premiumPayingTerm.to_s)])
						end
						isValid = false
					end
				elsif baseProduct.targetPeriodRefCd == "TARGETAGE"
					insured = getInsured(quotation)
					if insured.age.to_s != ""
						allowedTargetPeriod = insured.age.to_i + baseProduct.premiumPayingTerm.to_i
						if (baseProduct.targetPeriod.to_i > allowedTargetPeriod.to_i) || (baseProduct.targetPeriod.to_i < insured.age.to_i)
							unless $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.addErrors(tempErrorHash, "targetPeriod", "ERR_TARGETPERIOD", [MobiSys::BrowserHelper.getLabel(insured.age.to_i + 1),MobiSys::BrowserHelper.getLabel(allowedTargetPeriod.to_s)])
							else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-targetPeriod", "ERR_TARGETPERIOD", "ERR_TARGETPERIOD", nil, [MobiSys::BrowserHelper.getLabel(insured.age.to_i + 1),MobiSys::BrowserHelper.getLabel(allowedTargetPeriod.to_s)])
							end
							isValid = false
						end
					end
				end
			end
			unless $rhoconfig[:TABFEATUREREQD]
				if !tempErrorHash.empty?
					errors[:QuotationProductDO] = Hash.new if !errors[:QuotationProductDO].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:QuotationProductDO][baseProduct.guid.to_sym].is_a?(Hash)
					errors[:QuotationProductDO][baseProduct.guid.to_sym] = errors[:QuotationProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validateMandatoryCheckForAgeBirthDt(quotation, errors)
			isValid = true
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
					tempErrorHash = Hash.new
					if quotationParty.removed != "YES" && quotationParty.age.to_s == "" && quotationParty.dob.to_s == "" && (quotationParty.partyTypeCd == "INDIVIDUAL" || quotationParty.partyTypeCd.to_s == "")
						unless $rhoconfig[:TABFEATUREREQD]
					 		MobiSys::CommonUtil.addErrors(tempErrorHash, "dob", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('AGEORBIRTHDATE') ,MobiSys::BrowserHelper.getLabel(quotationParty.roleCd.to_s)])
					 	else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationParty.guid}-dob", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('AGEORBIRTHDATE') ,MobiSys::BrowserHelper.getLabel(quotationParty.roleCd.to_s)])
						end
						 isValid = false
					end
					unless $rhoconfig[:TABFEATUREREQD]
						if !tempErrorHash.empty?
							errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
							errors[:QuotationPartyDO][quotationParty.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][quotationParty.guid.to_sym].is_a?(Hash)
							errors[:QuotationPartyDO][quotationParty.guid.to_sym] = errors[:QuotationPartyDO][quotationParty.guid.to_sym].merge(tempErrorHash)
						end
					end
				end
			end
		end

		###################################################################################################

		def self.validateProductExtra(quotation, errors)
			isValid = true

			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.builtInRiderFl == 'YES'
					quotationProductExtras = getQuotationProductExtras(quotation)
					quotationProductExtras.each do |key, values|
						values.each do |val|
							tempErrorHash = Hash.new
							if val.decisionCd == "DECLINED"
								productExtraTypes = Lookupvalue.loadObject(:all, :conditions=>{{:name=>'key'}=>'PRODUCTEXTRATYPE'})
								productExtraTypes.each do |productExtraType|
									if productExtraType.cd == val.extraTypeCd
										break;
									end
									unless $rhoconfig[:TABFEATUREREQD]
										MobiSys::CommonUtil.addErrors(tempErrorHash, "decisionCd", "ERR_WARNINGDECLINED", [MobiSys::BrowserHelper.getLabel(val.extraTypeCd.to_s)])
									else
										MobiSys::CommonUtil.registerException(quotation.guid, "#{val.guid}-decisionCd", "ERR_WARNINGDECLINED", "ERR_WARNINGDECLINED", nil, [MobiSys::BrowserHelper.getLabel(val.extraTypeCd.to_s)])
									end
									isValid = false
								end
							end
							unless $rhoconfig[:TABFEATUREREQD]
								if !tempErrorHash.empty?
									errors[:QuotationProductExtraDO] = Hash.new if !errors[:QuotationProductExtraDO].is_a?(Hash)
									errors[:QuotationProductExtraDO][val.guid.to_sym] = Hash.new if !errors[:QuotationProductExtraDO][val.guid.to_sym].is_a?(Hash)
									errors[:QuotationProductExtraDO][val.guid.to_sym] = errors[:QuotationProductExtraDO][val.guid.to_sym].merge(tempErrorHash)
								end
							end
						end
					end
				end
			end
			return isValid
		end

		###################################################################################################

		def self.validateContactDetails(quotation, errors)
			isValid = true
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
            		tempErrorHash = Hash.new
					if facetData[:renderContactnum] || facetData[:renderEmailaddress]
		                if (quotationParty.contactNum == nil || quotationParty.contactNum == "") && (quotationParty.emailAddress == nil || quotationParty.emailAddress == "")
		                	unless $rhoconfig[:TABFEATUREREQD]
		                    	MobiSys::CommonUtil.addErrors(tempErrorHash, "contactNum", "ERR_MOBILEEMAIL", [MobiSys::BrowserHelper.getLabel(label) << " " <<  MobiSys::BrowserHelper.getLabel('proposerMobileNum')])
		                    else
								MobiSys::CommonUtil.registerException(quotation.guid, "#{quotationParty.guid}-contactNum", "ERR_MOBILEEMAIL", "ERR_MOBILEEMAIL", nil, [MobiSys::BrowserHelper.getLabel(label) << " " <<  MobiSys::BrowserHelper.getLabel('proposerMobileNum')])
							end
		                    isValid = false
		                end
		            end
		            unless $rhoconfig[:TABFEATUREREQD]
			            if !tempErrorHash.empty?
			                errors[:QuotationPartyDO] = Hash.new if !errors[:QuotationPartyDO].is_a?(Hash)
			                errors[:QuotationPartyDO][quotationParty.guid.to_sym] = Hash.new if !errors[:QuotationPartyDO][quotationParty.guid.to_sym].is_a?(Hash)
			                errors[:QuotationPartyDO][quotationParty.guid.to_sym] = errors[:QuotationPartyDO][quotationParty.guid.to_sym].merge(tempErrorHash)
			            end
			        end
		        end
		    end
		end

		################################################################################
		#-----------------Code based on Validation Metadata Sheet End------------------#
		################################################################################


		###################################################################################################


		################################################################################
		#----------------------Code used for Old Validation Start----------------------#
		################################################################################

		def self.calculateTotalModalPremium(quotation)
			totalModalPrem = 0
			quotation.QuotationProductList.each do |quotationProduct|
				if  ( quotationProduct and quotationProduct.modalPremium )
					totalModalPrem += quotationProduct.modalPremium.to_i
				end
			end
			return totalModalPrem
		end

		###################################################################################################

		def self.getBaseProduct(quotation)
			baseProduct = nil
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == "PLAN"
					baseProduct = quotationProduct
					break
				end
			end
			return baseProduct
		end # getBaseProduct

		###################################################################################################

		def self.getPAProduct(quotation)
			paProduct = nil
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == "PA"
					paProduct = quotationProduct
					break
				end
			end
			return paProduct
		end # getPAProduct

		###################################################################################################

		def self.getRiders(quotation)
			riders = Array.new
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == "RIDER" && quotationProduct.removed.to_s == ""
					if quotationProduct.flatExtra==""
						quotationProduct.flatExtra=0
					end
					if quotationProduct.flatExtraDuration==""
						quotationProduct.flatExtraDuration=0
					end
					riders.push(quotationProduct)
				end
			end
			return riders
		end # getRiders

		###################################################################################################

		def self.getPartialProducts(quotation)
			partialProducts = Array.new
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productTypeCd == "PARTIAL"
					partialProducts.push(quotationProduct)
				end
			end
			return partialProducts
		end # getPartialProducts

		###################################################################################################

		def self.getQuotationProductByProductId(quotation, productId)
			qp = nil
			quotation.QuotationProductList.each do |quotationProduct|
				if quotationProduct.productId == productId
					qp = quotationProduct
				end
			end
			return qp
		end # getQuotationProductByProductId

		###################################################################################################

		def self.getRegularTopup(quotation)
			regularTopup = nil
			if quotation != nil && quotation.QuotationTopUpList.size > 0
				quotation.QuotationTopUpList.each do |quotationTopup|
					if quotationTopup.topUpTypeCd == "REGULARTOPUP"
						regularTopup = quotationTopup
						break
					end
				end
			end
			unless regularTopup
				regularTopup = QuotationTopUp.new(:topUpTypeCd => "REGULARTOPUP")
				regularTopup.removed="YES" if quotation.regularTopupFl.to_s != "YES"
	        	quotation.addQuotationTopUp(regularTopup)
	        end
			return regularTopup
		end

		###################################################################################################

		def self.getInitialTopup(quotation)
			initialTopup = nil
			if quotation != nil && quotation.QuotationTopUpList.size > 0
				quotation.QuotationTopUpList.each do |quotationTopup|
					if quotationTopup.topUpTypeCd == "INITIALINVESTMENT"
						initialTopup = quotationTopup
						break
					end
				end
			end
			unless initialTopup
				initialTopup = QuotationTopUp.new(:topUpTypeCd => "INITIALINVESTMENT")
				initialTopup.removed="YES" if quotation.initialTopupFl.to_s != "YES"
	        	quotation.addQuotationTopUp(initialTopup)
	        end
			return initialTopup
		end

		###################################################################################################

		def self.getAdHocTopup(quotation)
			adHocTopup = Array.new
			if quotation != nil && quotation.QuotationTopUpList.size > 0
				quotation.QuotationTopUpList.each do |quotationTopup|
					if quotationTopup.topUpTypeCd == "ADHOCTOPUP"
						adHocTopup.push(quotationTopup)
					end
				end
			end
			return adHocTopup
		end

		###################################################################################################

		def self.getContributionTopup(quotation)
			countributionTopup = Array.new
			if quotation != nil && quotation.QuotationTopUpList.size > 0
				quotation.QuotationTopUpList.each do |quotationTopup|
					if quotationTopup.topUpTypeCd == "TRANSFERTOPUP"
						countributionTopup.push(quotationTopup)
					end
				end
			end
			return countributionTopup
		end

		###################################################################################################

		def self.getSupplementaryLife(quotation)
			supplementaryLife = Array.new
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
					if quotationParty.roleCd == "SUPPLEMENTARY"
						supplementaryLife.push(quotationParty)
					end
				end
			end
			return supplementaryLife
		end

		###################################################################################################

		def self.getRiderSupplementaryGuid(quotation)
			supGuidTemp = Array.new
			if quotation != nil && quotation.QuotationProductList.size > 0
				quotation.QuotationProductList.each do |quotProd|
					if quotProd.productTypeCd == "RIDER"
						if quotProd.partyRoleCd == "SUPPLEMENTARY"
							supGuidTemp.push(quotProd.insuredPartyRefGuid)
							#supGuidTemp = supGuidTemp.group_by { |e| e }.select { |k, v| v.size > 1 }.map(&:first)
							supGuidTemp.uniq!
						end
					end
				end
			end
			return supGuidTemp
		end

		###################################################################################################

		def self.getSupplementaryRider(quotation)
			supplementaryRider = Array.new
			h1 = Hash.new
			supGuid = getRiderSupplementaryGuid(quotation)
			if quotation != nil && quotation.QuotationProductList.size > 0
				quotation.QuotationProductList.each do |quotProd|
					if quotProd.productTypeCd == "RIDER"
						if quotProd.partyRoleCd == "SUPPLEMENTARY"
							supplementaryRider.push(quotProd)
						end
					end
				end
				supGuid.each do |sup_ref_guid|
					a1 = Array.new
					supplementaryRider.each do |sup_rider|
						if sup_ref_guid == sup_rider.insuredPartyRefGuid
							a1.push(sup_rider)
						end
						h1[sup_ref_guid] = a1
					end
				end
			end
			return h1
		end

		###################################################################################################

		def self.getWithdrawals(quotation)
			withdrawal = Array.new
			if quotation != nil && quotation.QuotationWithdrawalList.size > 0
				quotation.QuotationWithdrawalList.each do |quotationWithdrawal|
					withdrawal.push(quotationWithdrawal)
				end
			end
			return withdrawal
		end

		######################Model validations start ####################################################

		def self.getFunds(quotation)
			funds = nil
			if quotation != nil && quotation.QuotationProductList.size > 0
				quotation.QuotationProductList.each do |quotationProduct|
					if quotationProduct.productTypeCd == "PLAN"
						funds = quotationProduct.QuotationProductInvestmentFundList
					end
				end
			end
			return funds
		end

		###################################################################################################

		def self.getInsured(quotation)
			insured = nil
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
					if quotationParty.roleCd == "PRIMARY"
						insured = quotationParty
					end
				end
			end
			return insured
		end

		###################################################################################################

		def self.getPolicyHolder(quotation)
			policyHolder = nil
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
					if quotationParty.roleCd == "PROPOSER"
						policyHolder = quotationParty
						break
					end
				end
			end
			return policyHolder
		end

		###################################################################################################

		def self.getJointLife(quotation)
			jointLife = nil
			if quotation != nil && quotation.QuotationPartyList.size > 0
				quotation.QuotationPartyList.each do |quotationParty|
					if quotationParty.roleCd == "JOINT"
						jointLife = quotationParty
						break
					end
				end
			end
			return jointLife
		end

		###################################################################################################

		def self.getQuotationProductExtras(quotation)
			quotationProductExtra = {}
			quotation.QuotationProductList.each do |quotationProduct|
				quotationProductExtra[quotationProduct.productId] = quotationProduct.QuotationProductExtraList if quotationProduct.productId != nil
			end
			quotationProductExtra
		end

		######################Model validations end ####################################################

		def self.validate(quotation, msg, errors)
        	$globalContextObjectMap = {}
			$currentValidationMetadata = nil
			$currentTabId = nil
            $taskExceptionHash = []
			isValid = true

			#################################
			# product business validations
			#################################
			if $rhoconfig[:contextBasedMetadata]
				classToFind = "#{quotation.class.name}DO"

				if $contextMasterCache.has_key?(classToFind.to_sym)
					contextMasterList = $contextMasterCache[classToFind.to_sym]
					contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,quotation)
				end
				MobiSys::Validation.processValidContexts(quotation.hashForSync, contextMasterGeneratedArray, "QuotationSet")
				validationContextsPolicy = $globalContextObjectMap[quotation.guid]
			else
				QuotationSet.setObject(quotation)
				validationContexts = QuotationSet::ValidationContexts
				MobiSys::Validation.processValidContexts(quotation.hashForSync, validationContexts, "QuotationSet")
			end
			isProductValid = MobiSys::ProductBO.validate(quotation,msg,errors)

			$currentValidationMetadata = nil
			validationContexts = $globalContextObjectMap[quotation.guid]
			MobiSys::Validation.validationLoop(quotation.hashForSync, validationContexts, errors, "QuotationSet", quotation.guid,"array")
			validateCompanyFacet(quotation, errors)
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid})
			#signatureErrors = Hash.new
            validateSignature_Jazz(quotation, signatureContainer, errors)

			# check if all errors have been retained or removed

			# puts "errors: #{errors.to_json}"

			# check without loop

			isValid = true
			if !errors.empty?
				isValid = false
			end

			db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
            db.start_transaction
            $taskExceptionHash.each do |taskException|
                taskException.persistAll
            end
            db.commit
            $taskExceptionHash = nil
            $ageShowPopup = nil

			return isValid #&& isProductValid
		end # validate

		###################################################################################################

		#Method to validate EAPP Signatures
    	def self.validateSignature_Jazz(quotation, signatureContainer, errors)
        MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache

    		$globalContextObjectMap = {}
            $currentValidationMetadata = nil
            $currentTabId = nil
            #$taskExceptionHash = []
            if $rhoconfig[:contextBasedMetadata]
              validationContextsQuotation=[]
              if($globalContextObjectMap == nil || !$globalContextObjectMap.has_key?(quotation.guid))
                classToFind = "#{quotation.class.name}DO"
                contextMasterGeneratedArray = []
                if $contextMasterCache.has_key?(classToFind.to_sym)
                  contextMasterList = $contextMasterCache[classToFind.to_sym]
                  contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,quotation)
                end
                MobiSys::Validation.processValidContexts(quotation.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                validationContextsQuotation = $globalContextObjectMap[quotation.guid]
              end
            end
            #MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
            if signatureContainer
	            serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign|serviceSign.signatureTypeCd == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd == "SIGNATURECAPTURE2" }
	            serviceSignatures.each do |serviceSignObj|
	                if $rhoconfig[:contextBasedMetadata]
	                  classToFind = "#{serviceSignObj.class.name}DO"
	                  contextMasterGeneratedArray = []
	                  if $contextMasterCache.has_key?(classToFind.to_sym)
	                    contextMasterList = $contextMasterCache[classToFind.to_sym]
	                    contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
	                  end
	                  MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
	                  validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsQuotation)
	                else
	                  ServiceSignatureSet.setObject(serviceSignObj)
	                  validationContexts = ServiceSignatureSet::ValidationContexts
	                end
	                MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", quotation.guid)
	            end
	            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
	            db.start_transaction
	            $taskExceptionHash.each do |taskException|
	                taskException.persistAll
	            end
	            db.commit
	        end
        end
        ##################################################################################################

		def self.getBirthdayDashboard()
			quotationsDashboard = Array.new
			# total
			sql = ""
			# sql << "Select q.firstname as firstname, q.dob as dob from quotationParty q where q.dob != \"\" limit 3"
			# quotations = Quotation.find_by_sql(sql)

			#sql << "Select q.firstname as firstname, q.dob as dob from quotationParty q where q.dob != \"\" limit 3"
			#sql << "Select q.firstname as firstname, q.dob as dob from quotationParty q where q.dob != '' limit 3"
			quotations = QuotationParty.loadObject(  :all,
				:conditions => {
					{
						:name => 'dob',
						:op => '!='
						} => ''
					}
					)
			#quotations = Quotation.find_by_sql(sql)

			quotations.each do |quotation|
				insured = quotation.getPartyByRole("PRIMARY")
				if insured and insured.dob and insured.dob != ""
					quotationsHM = Hash.new
					quotationsHM['LEAD'] = insured.firstname.to_s
					quotationsHM['BIRTHDAY'] = Date.parse(insured.dob).strftime('%d/%m/%Y')
					quotationsDashboard.push(quotationsHM)
				end
			end

			return quotationsDashboard
		end # self.getBirthdayDashboard()

		###################################################################################################

		def self.getDashboard()
			quotationsDashboard = Array.new
			# total
			quotations = Quotation.loadObject(:all)

			quotationsHM = Hash.new
			quotationsHM['ILLUSTRATIONS'] = "TOTAL"
			quotationsHM['COUNT'] = quotations.size.to_s
			quotationsDashboard.push(quotationsHM)

			# draft
			quotations = Quotation.loadObject(  :all,
				:conditions => {
					{
						:name => 'quoteStatusCd',
						:op => 'LIKE'
						} => MobiSys::QuotationBO::PENDING
					}
					)
			quotationsHM = Hash.new
			quotationsHM['ILLUSTRATIONS'] = "Draft"
			quotationsHM['COUNT'] = quotations.size.to_s
			quotationsDashboard.push(quotationsHM)

			# awaiting conversion
			quotations = Quotation.loadObject(  :all,
				:conditions => {
					{
						:name => 'quoteStatusCd',
						:op => 'LIKE'
						} => '%SYNC%',
						{
							:name => 'signature',
							:op => 'IS'
							} => nil,
							},
							:op => 'AND'
							)

			quotationsHM = Hash.new
			quotationsHM['ILLUSTRATIONS'] = "AWAITING CONVERSION"
			quotationsHM['COUNT'] = quotations.size.to_s
			quotationsDashboard.push(quotationsHM)

			# Converted
			quotations = Quotation.loadObject(  :all,
				:conditions => {
					{
						:name => 'quoteStatusCd',
						:op => 'LIKE'
						} => '%SYNC%',
						{
							:name => 'signature',
							:op => 'IS NOT'
							} => nil,
							},
							:op => 'AND'
							)

			quotationsHM = Hash.new
			quotationsHM['ILLUSTRATIONS'] = "CONVERTED"
			quotationsHM['COUNT'] = quotations.size.to_s
			quotationsDashboard.push(quotationsHM)

			return quotationsDashboard
		end # self.getDashboard

		###################################################################################################

		def self.computeProductExtra(quotation,quotationProduct)
			quotationProductExtraArray = []
			productDO = quotationProduct.product
			if(productDO == nil && quotationProduct.productSeq != nil)
				productDO = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
			end
			if (productDO != nil)
				productExtraTypes = Lookupvalue.find(:all, :conditions=>{{:name=>'key'}=>'PRODUCTEXTRATYPE'})
				if productExtraTypes != nil
					productExtraTypes.each do |productExtraType|
						facetId = productExtraType.cd
						if facetId != "PRDDISCOUNT"
							prdFacet = productDO.getFacet(facetId)
							if prdFacet
								offlineQuotProdExtraList = quotationProduct.getExtraQuotationProduct(facetId)
								if offlineQuotProdExtraList == nil
									offlineQuotProdExtraList = QuotationProductExtra.new
									quotationProduct.addQuotationProductExtra(offlineQuotProdExtraList)
								else
									offlineQuotProdExtraList = offlineQuotProdExtraList
								end
								offlineQuotProdExtraList.extraTypeCd = facetId #facetId
								tableTypeMappingSeq = productDO.getTableTypeMappingSeq(facetId)
								definitionTable = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, nil, false, false) if tableTypeMappingSeq
								if(definitionTable != nil)
									offlineQuotProdExtraList.decisionCd = definitionTable.loadingDecisionCd if definitionTable.loadingDecisionCd && definitionTable.loadingDecisionCd != ""
									offlineQuotProdExtraList.extraFlatAmt = definitionTable.flatLoadingAmt if definitionTable.flatLoadingAmt && definitionTable.flatLoadingAmt != ""
									offlineQuotProdExtraList.extraPercent = definitionTable.loadingPercent if definitionTable.loadingPercent && definitionTable.loadingPercent != ""
									offlineQuotProdExtraList.loadingTypeCd = definitionTable.loadingTypeCd if definitionTable.loadingTypeCd && definitionTable.loadingTypeCd != ""
									offlineQuotProdExtraList.processingTypeCd = definitionTable.processingTypeCd if definitionTable.processingTypeCd
									if(!(offlineQuotProdExtraList.extraTypeCd.include? "TEMPLOADING"))
										offlineQuotProdExtraList.extraFlatDuration = quotationProduct.premiumPayingTerm
										offlineQuotProdExtraList.extraPercDuration = quotationProduct.premiumPayingTerm
									end
								else
									offlineQuotProdExtraList.decisionCd = "STANDARD"
									offlineQuotProdExtraList.extraFlatDuration = ""
									offlineQuotProdExtraList.extraPercDuration = ""
									offlineQuotProdExtraList.extraFlatAmt = ""
									offlineQuotProdExtraList.extraPercent = ""
									offlineQuotProdExtraList.status = ""
								end
								quotationProductExtraArray.push(offlineQuotProdExtraList)
							end
						end
					end
				end
			end
			return quotationProductExtraArray, quotationProduct
		end

		def self.getImpactedRiderAssociation(productSeq, roleCd, riderAssociationList, listOfImpactedAssociations)
			riderAssociationList.each do |riderAssociation|
				if riderAssociation.productSeq.to_s == productSeq.to_s
					if (riderAssociation.applicableRoles.to_s.include?roleCd) || (riderAssociation.dependentRiderRoleCd.to_s.include?roleCd)
						listOfImpactedAssociations.push riderAssociation
						if riderAssociation.impactedRiders.to_s != ''
							riderAssociation.impactedRiders.split(',').each do |riderSeq|
								getImpactedRiderAssociation(riderSeq, roleCd, riderAssociationList, listOfImpactedAssociations)
							end
						end
					end
				end
			end
			return listOfImpactedAssociations
	    end

	    def self.checkGenderTitleMapping(quotation,errors)
	    	isValid = true
	    	fieldTargetValueMap = FieldTargetValueMap.loadObject(:all, :conditions=>{{:name=>'targetField'}=> "genderCd"})
	    	quotation.QuotationPartyList.each do|party|
	    		if party.genderCd.to_s != "" && party.title.to_s != ""
	    			fieldTargetValueMap.each do |fields|
						if (party.title == fields.drivingValue && party.genderCd != fields.targetValue)
							MobiSys::CommonUtil.registerException(quotation.guid,"#{party.guid}-genderCd","ERR_GENDERTITLE","ERR_GENDERTITLE",nil,[party.roleCd]);
                        	isValid = false
						end
					end
				end
	    	end
	    	return isValid
	    end


	    def self.validateCompanyFacet(quotation,errors)
	    	baseProduct = getBaseProduct(quotation)
	    	if $rhoconfig[:addtnlSICompanyModelSet] != nil && $rhoconfig[:addtnlSICompanyModelSet].actionValue.to_s != ""
				policyModelSet = PolicyUtil::PolicyModelSet.new
				policy = MobiSys::PolicyBO.convertToPolicy(quotation)
				party = quotation.getParty(baseProduct)
				party.policyYear = quotation.policyYear
				policyProduct = policy.getBaseProduct if policy
				policyModelSet.execute(policy, policyProduct, party, $rhoconfig[:addtnlSICompanyModelSet].actionValue)
				quotation = MobiSys::PolicyBO.copyToQuotation(policy,quotation)
			end
	    end

	    def self.checkSupplementary(quotation,errors)
	    	supplementaryExists = (quotation.supplementaryLives.to_s == "YES" ? checkRoleExists(quotation,'SUPPLEMENTARY') : true)
	    	return supplementaryExists
	    end

	    def self.validateSignature(quotation,errors)
			baseProduct = quotation.getBasePlan
			if baseProduct.product == nil
	            baseProductDO = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
	            baseProduct.product = baseProductDO
	        else
	            baseProductDO = baseProduct.product
	        end
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid})

			if (baseProductDO && baseProductDO.getFacetValue("CAPTURE_SIGNATURE_ON_SI_OUTPUT").to_s == "YES" && (signatureContainer == nil || signatureContainer.ServiceSignatureList.size == 0))
				MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('signature')])
			end
		end
	end
end

begin
    require 'Quotation/quotation_b_o_company'
rescue LoadError => e
    puts 'quotation_b_o_company not included'
end

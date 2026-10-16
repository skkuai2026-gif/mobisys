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
							MobiSys::CommonUtil.addErrors(tempErrorHash, "portfolioModelCd", "ERR_MANDATORY_FUNDS", ['Fund allocation'])
						else
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-portfolioModelCd", "ERR_MANDATORY_FUNDS", "ERR_MANDATORY_FUNDS", nil, ['Fund allocation'])
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

		def self.validateCSAFunds(quotation,errors)
			baseProduct = quotation.getBasePlan
			isValid = true
			if (quotation.fnaId.to_s != '')
				fnaId = quotation.fnaId.to_s
				fnaRequest = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})
				quotFundArray = []
		    	if fnaRequest
		    		rpqId = quotation.rpqId.to_s
		    		leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:rpqId => rpqId})

		    		if leadRPQ && leadRPQ.education.to_s != ''
		    			education = leadRPQ.education.split(",")

		    			if baseProduct
				          baseProduct.QuotationProductInvestmentFundList.each do |investFund|
				            if investFund.allocationPerc
				              quotFundArray << investFund.fundCd
				            end
				          end
				          
				          quotFundArray.sort!
				          education.sort!

				          arraysMatch = education == quotFundArray

				          if !arraysMatch
							MobiSys::CommonUtil.registerException(quotation.guid, "#{baseProduct.guid}-fundCd", "ERR_MISMATCHFUND", "ERR_MISMATCHFUND", nil, [])

				            isValid = false
				          end
				        end
		    		end
		    	end
			end
			return isValid
		end

		def self.generateQuotationNum(quotation)
			# quotation = @baseIO.baseDO
            quotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION') if quotation && quotation.quotationRefNum.to_s == ""
		end

        def self.setPolicyPartyDO(policy, quotation)
            if policy.to_s == ""
                policy = MobiSys::PolicyBO.convertToPolicy(quotation)
            end
            if policy.to_s != ""
                roleCd = ""
                policy.PartyList.each do |party|
                    if party.roleCd == "PROPOSER" || party.roleCd == "PRIMARY" || party.roleCd == "PROPCUMINS"
                        if party.roleCd.to_s == "PROPCUMINS"
                            roleCd = "PROPOSER"
                        else
                            roleCd = party.roleCd
                        end
                        quotationParty = quotation.getPartyByRole(roleCd)
                        if quotationParty.to_s != ""
                            party.copyFromAddr2 = quotationParty.residency
                            party.copyFromAddr3 = quotationParty.educationCd
                            if quotationParty.officeIsdCode.to_s != ""
                            party.otherReligion = quotationParty.officeIsdCode
                            end
                        end
                    end
                end
            end
            return policy
        end

        def self.setDefaultQuotation(quotation)
            # quotation = @baseIO.baseDO
            policy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid})
            policy = setPolicyPartyDO(policy, quotation)
        end

        def setPartyFields(quotation)
            # quotation = @baseIO.baseDO
            quotation.QuotaionPartyList.each do |quotParty|
                if quotParty.partyTypeCd.to_s == "INDIVIDUAL"
                    quotParty.corporateName = nil
                    quotParty.corporateName2 = nil
                elsif quotParty.partyTypeCd.to_s == "ORGANIZATION"
                    quotParty.title = nil
                    quotParty.firstname = nil
                    quotParty.firstname2 = nil
                    quotParty.lastname = nil
                    quotParty.middlename = nil
                    quotParty.middleName2 = nil
                    quotParty.smoker = nil
                    quotParty.lastname2 = nil
                    quotParty.dob = nil
                    quotParty.genderCd = nil
                    quotParty.age = nil
                    quotParty.coverageCityCd = nil
                    quotParty.coverageCountryCd = nil
                    quotParty.maritalStatus = nil
                    quotParty.idType = nil
                    quotParty.industryCd = nil
                    quotParty.idNumber = nil
                    quotParty.natureOfDuty = nil
                    quotParty.occupationCd = nil
                end

            end
        end

        def preSave(quotation)
            # quotation = @baseIO.baseDO
            if quotation && quotation.proposalVersion.to_s == ""
			  proposalVersionVal = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'PROPOSALVERSION'})
              quotation.proposalVersion = proposalVersionVal.value if proposalVersionVal
            end
            if quotation && quotation.quotAddtnlField11.to_s == ""
                quotation.quotAddtnlField11 = "BOTH"
            end
            policy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid})
            policy = setPolicyPartyDO(policy, quotation)
        end

        def self.checkBasePlan(quotation,errors)
			basePlanExists = true
			basePlan = quotation.getBasePlan
			if basePlan.to_s == ""
				MobiSys::CommonUtil.registerException(quotation.guid, "#{quotation.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil,[MobiSys::BrowserHelper.getLabel('PLAN')])
				basePlanExists = false
			end
			return basePlanExists
		end

		def self.prePremiumOffsetSolver(quotationIO)
	    if quotationIO.baseProduct.getFacetFast('PREMIUMOFFSETSOLVER')
	      originalQuotation = quotationIO.baseDO
	      quotationIO.baseDO = originalQuotation.cloneObject
	      if originalQuotation.getBaseProduct.addtnField4 != "PR"
	        quotationIO = premiumOffsetSolver(quotationIO, "PREMIUMOFFSETSOLVER", originalQuotation)
	        originalQuotation.quotAddtnlField3 = quotationIO.baseDO.quotAddtnlField3
	        originalQuotation.quotAddtnlField4 = quotationIO.baseDO.quotAddtnlField4
	        originalQuotation.getBaseProduct.addtnField2 = quotationIO.baseDO.getBaseProduct.addtnField2
	        #Swati Ahire 04-09-2014: addtnField2 was assigned twice. Replaced addtnField2 with addtnField3
	        originalQuotation.getBaseProduct.addtnField3 = quotationIO.baseDO.getBaseProduct.addtnField3
	      end
	    quotationIO.baseDO = originalQuotation
	    end
	    return quotationIO
		end

		def self.premiumOffsetSolver(quotationIO, facetId, originalQuotation = nil)
      if facetId != nil
        MobiSys::ProductBO.loadModel(facetId,quotationIO)
        quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER')

        if quotationIO.baseDO.getBaseProduct.premiumPayingTerm == nil
          Alert.show_popup({:title=>'Solve Quotation',
            :message=>'Error: No premium paying term entered. Evaluation runs for the entire premium paying term.',
            :buttons=>["OK"]})
        else
          quotationProductDO = quotationIO.baseDO.getBaseProduct
          offsetYear = 0
          lowOffsetYear = 0
          if "PUA" == quotationProductDO.addtnField4 || "DA" == quotationProductDO.addtnField4
            offsetYear = calculatePremiumOffset(quotationIO,"totallod","cumulativeloss","totalltda","cumulativedividenda","totalannualpremium","cumulativetotalpremium","totalpremium","finaldividenda")
          end
          if "DA" == quotationProductDO.addtnField4
            lowOffsetYear = calculatePremiumOffset(quotationIO,"totallod","cumulativeloss","totalltdb","cumulativedividendb","totalannualpremium","cumulativetotalpremium","totalpremium","finaldividendb")
          end

          if "DA" == quotationProductDO.addtnField4
            highAlternate = calculatePremiumOffset(quotationIO,"totallodc","cumulativelossalt","totalltdc","cumulativedividendc","totalannualpremium","cumulativetotalpremium","totalpremium","finaldividendc")
          end

          if "DA" == quotationProductDO.addtnField4
            lowAlternate = calculatePremiumOffset(quotationIO,"totallodc","cumulativelossalt","totalltdd","cumulativedividendd","totalannualpremium","cumulativetotalpremium","totalpremium","finaldividendd")
          end

          #puts "********************** Offset Year: #{offsetYear} ,Low Offset Year: #{lowOffsetYear} ********************** "
          quotationIO.baseDO.quotAddtnlField3 = offsetYear
          quotationIO.baseDO.quotAddtnlField4 = lowOffsetYear
          quotationIO.baseDO.getBaseProduct.addtnField2 = highAlternate
          quotationIO.baseDO.getBaseProduct.addtnField3 = lowAlternate
          originalQuotation.quotAddtnlField3 = offsetYear
          originalQuotation.quotAddtnlField4 = lowOffsetYear
          originalQuotation.getBaseProduct.addtnField2 = highAlternate
          originalQuotation.getBaseProduct.addtnField3 = lowAlternate
          productBO = nil
          MobiSys::ProductBO.loadModel("PREMIUMOFFSETSOLVER2",quotationIO);
          # ClonedQuotationIO = quotationIO
          #puts "Offset Year: #{offsetYear.inspect}"
          #puts "Low Offset Year: #{lowOffsetYear.inspect}"
          #puts "highAlternate Year: #{highAlternate.inspect}"
          #puts "lowAlternate Year: #{lowAlternate.inspect}"

          if "PUA" == quotationProductDO.addtnField4
            pOffsetYear = calculateYearforPUA(quotationIO,offsetYear,productBO,"popuabreak", originalQuotation);
          end

          if "DA" == quotationProductDO.addtnField4

            pOffsetYear = calculateYearforDA(quotationIO,offsetYear,productBO,"podahighbreak", originalQuotation);
            pLowOffsetYear = calculateLowYearforDA(quotationIO,lowOffsetYear,productBO,"podalowbreak", originalQuotation);
            pHighAlternate = calculateHighAltYearforDA(quotationIO,highAlternate,productBO,"podahighaltbreak", originalQuotation);
            pLowAlternate = calculateLowAltYearforDA(quotationIO,lowAlternate,productBO,"podalowaltbreak", originalQuotation);
          end

          quotationIO.baseDO.quotAddtnlField3 = pOffsetYear
          quotationIO.baseDO.quotAddtnlField4 = pLowOffsetYear
          quotationIO.baseDO.getBaseProduct.addtnField2 = pHighAlternate
          quotationIO.baseDO.getBaseProduct.addtnField3 = pLowAlternate


          #puts "POffset Year: #{pOffsetYear.inspect}"
          #puts "PLow Offset Year: #{pLowOffsetYear.inspect}"
          #puts "PhighAlternate Year: #{pHighAlternate.inspect}"
          #puts "PlowAlternate Year: #{pLowAlternate.inspect}"

        end

      end
      return quotationIO
    end

    def self.calculateYearforPUA(quotationIO, offsetYear, productBO, breakElement, orignalQuotation)
      quotationIO.baseDO = orignalQuotation.cloneObject
      year = 0;
      outerBreak = false
        if(offsetYear > 0)
          year = offsetYear - 1;
          while year <=  quotationIO.baseDO.getBasePlan.productTerm
            quotationIO.baseDO.quotAddtnlField3 = year
            quotationIO.loopReference = "PUA:-#{year.inspect}"
            quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER');
            cycleCount = 1
            while cycleCount <=  quotationIO.baseDO.getBasePlan.productTerm
              outerBreak = false
              breakValue = quotationIO.group_valueAsOf(breakElement,cycleCount,nil)
              if("break" == breakValue)
                year = year +1;
              else
                outerBreak = true
              end
              break if (breakValue != nil && (breakValue != 0));
              cycleCount = cycleCount+1;
            end
            break if outerBreak
          end
        end
        quotationIO.baseDO = orignalQuotation.cloneObject
      return year;
    end

    def self.calculateYearforDA(quotationIO, offsetYear, productBO, breakElement, orignalQuotation)
      quotationIO.baseDO = orignalQuotation.cloneObject
      hmAddtnlEvalParams = {}
      hmAddtnlEvalParams["breaktype"] = "HIGHBRK"
      quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)
      outerBreak = false
      year = 0;
      if(offsetYear > 0)
        year = offsetYear - 1;
        while year <=  quotationIO.baseDO.getBasePlan.productTerm
          quotationIO.baseDO.quotAddtnlField3 = year
          quotationIO.loopReference = "DA:-#{year.inspect}"
          quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER');
          cycleCount = 1
          while cycleCount <=  quotationIO.baseDO.getBasePlan.productTerm
            outerBreak = false
            breakValue = quotationIO.group_valueAsOf(breakElement,cycleCount,nil)
            if("break" == breakValue)
              year = year +1;
            else
              outerBreak = true
            end
            break if (breakValue != nil && (breakValue != 0));
            cycleCount = cycleCount+1;
          end
          break if outerBreak
        end
      end
      quotationIO.baseDO = orignalQuotation.cloneObject
      return year;
    end

    def self.calculateHighAltYearforDA(quotationIO, offsetYear, productBO, breakElement, orignalQuotation)
      year = 0;
      outerBreak = false
      if(offsetYear > 0)
        year = offsetYear - 1;
        hmAddtnlEvalParams = {}
        hmAddtnlEvalParams["breaktype"] = "HIGHALTBRK"
        quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)
        while year <=  quotationIO.baseDO.getBasePlan.productTerm
          quotationIO.baseDO.getBasePlan.addtnField2 = year
          quotationIO.loopReference = "HighAltYearforDA:-#{year.inspect}"
          quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER');
          cycleCount = 1
          while cycleCount <=  quotationIO.baseDO.getBasePlan.productTerm
            outerBreak = false
            breakValue = quotationIO.group_valueAsOf(breakElement,cycleCount,nil)
            if("break" == breakValue)
              year = year +1;
            else
              outerBreak = true
            end
            break if (breakValue != nil && (breakValue != 0));
            cycleCount = cycleCount+1;
          end
          break if outerBreak
        end
      end
      return year;
    end

    def self.calculateLowYearforDA(quotationIO, offsetYear, productBO, breakElement, orignalQuotation)
        year = 0;
        outerBreak = false
          if(offsetYear > 0)
            year = offsetYear - 1;
            hmAddtnlEvalParams = {}
            hmAddtnlEvalParams["breaktype"] = "LOWBRK"
            quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)
            while year <=  quotationIO.baseDO.getBasePlan.productTerm
                quotationIO.baseDO.quotAddtnlField4 = year
                quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER');
                cycleCount = 1
                while cycleCount <=  quotationIO.baseDO.getBasePlan.productTerm
                  outerBreak = false
                  breakValue = quotationIO.group_valueAsOf(breakElement,cycleCount,nil)
                  if("break" == breakValue)
                    year = year + 1;
                  else
                    outerBreak = true
                  end
                  break if (breakValue != nil && (breakValue != 0));
                  cycleCount = cycleCount+1;
                end
              break if outerBreak
            end
          end
        return year;
    end

    def self.calculateLowAltYearforDA(quotationIO, offsetYear, productBO, breakElement, orignalQuotation)
      #puts "**************in calculateLowAltYearforDA******************** "
      year = 0;
      outerBreak = false
      if (('AEB' == quotationIO.baseDO.getBasePlan.addtnField6) ||
          ('Both' == quotationIO.baseDO.getBasePlan.addtnField6))
        if(offsetYear > 0)
          year = offsetYear - 1;
          hmAddtnlEvalParams = {}
          hmAddtnlEvalParams["breaktype"] = "LOWALTBRK"
          quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)
          while year <=  quotationIO.baseDO.getBasePlan.productTerm
            quotationIO.baseDO.getBasePlan.addtnField3 = year
            quotationIO.loopReference = "LowAltYearforDA:-#{year.inspect}"
            quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO, 'PREMIUMOFFSETSOLVER');
            cycleCount = 1
            while cycleCount <=  quotationIO.baseDO.getBasePlan.productTerm
              outerBreak = false
              breakValue = quotationIO.group_valueAsOf(breakElement,cycleCount,nil)
              if("break" == breakValue)
                year = year +1;
              else
                outerBreak = true
              end
              break if (breakValue != nil && (breakValue != 0));
              cycleCount = cycleCount+1;
            end
            break if outerBreak
          end
        end
      end
      return year;
    end

    def self.calculatePremiumOffset(quotationIO, totalLOD, cumulativeLoss, totalLTD, illustrativeAccumulatedDividend, totalPremium, cumulativePremium, totalAnnualizedPremium, illustrativeYearlyCashDividend)

      basePlan = quotationIO.baseDO.getBaseProduct
      illustrationModelDO = quotationIO.illustrationModel
      freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(illustrationModelDO.computationFrequencyCd)
      computationCycles = (basePlan.premiumPayingTerm * freqMultiplier).to_i
      offsetYear = 0
      #puts "**********************************************Start of computationCycles loop*************#{computationCycles.inspect}*************freqMultiplier***#{freqMultiplier.inspect}**********"
      cycleCount = 1
      while cycleCount <=  computationCycles

        #Potential Pending Loss
        potentialPendingLoss = 0.0
        if cycleCount.to_i <= basePlan.premiumPayingTerm.to_i && quotationIO.getIllustrationHeaderFieldValue(totalLOD) != nil
          potentialPendingLoss = (quotationIO.getIllustrationHeaderFieldValue(totalLOD) - ((quotationIO.group_valueAsOf(cumulativeLoss,cycleCount-1)) != nil ? quotationIO.group_valueAsOf(cumulativeLoss,cycleCount-1) : 0.0))
        end

        #Balance dividend to be paid
        balanceDividendPaid = 0.0
        if cycleCount.to_i <= basePlan.premiumPayingTerm.to_i && quotationIO.getIllustrationHeaderFieldValue(totalLTD) != nil

          balanceDividendPaid = (quotationIO.getIllustrationHeaderFieldValue(totalLTD) - (quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) != nil ? quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) : 0.0))
        end

        #Diff K & L col
        diffKLcol = 0.0
        if cycleCount.to_i <= basePlan.premiumPayingTerm.to_i

          diffKLcol = balanceDividendPaid - potentialPendingLoss + ((quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) != nil ? quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) : 0.0 ))
        end

        #Pending Premium to be paid
        pendingPremiumPaid = 0.0
        if cycleCount.to_i <= basePlan.premiumPayingTerm.to_i && quotationIO.getIllustrationHeaderFieldValue(totalPremium) != nil
          pendingPremiumPaid = quotationIO.getIllustrationHeaderFieldValue(totalPremium) - (quotationIO.group_valueAsOf(cumulativePremium,cycleCount-1) != nil ? quotationIO.group_valueAsOf(cumulativePremium,cycleCount-1) : 0.0 )
        end

        #diff
        diff = 0.0
        diff = diffKLcol - pendingPremiumPaid
        offsetYearfound = false
        if diff>0
          offsetYear = cycleCount
          offsetYearfound = true
        end
        #puts "cycleCount : #{cycleCount}, potentialPendingLoss : #{potentialPendingLoss}, balanceDividendPaid : #{balanceDividendPaid}, diffKLcol : #{diffKLcol}, pendingPremiumPaid : #{pendingPremiumPaid}, diff : #{diff}"
        if offsetYearfound
          break
        end


        cycleCount = cycleCount + 1
      end
      #puts "**********************************************End of computationCycles loop***************************************"

      finalOffsetYear = 0
      offsetYearfound = false
      #puts "**********************************************Start of computationCycles loop1***************************************"
      cycleCount = offsetYear
      while cycleCount <= computationCycles

        premium = 0.0

        preCummulativedivident = (quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) != nil) ? quotationIO.group_valueAsOf(illustrativeAccumulatedDividend,cycleCount-1) : 0.0

        offsetYearfound = true

        innerCycleCount = cycleCount
        while innerCycleCount <=  computationCycles


          #Premium Offset
          premiumOffset = 0.0
          if innerCycleCount <= basePlan.premiumPayingTerm.to_i
            if innerCycleCount >= cycleCount
              premiumOffset= quotationIO.group_valueAsOf(totalAnnualizedPremium, innerCycleCount) != nil ? quotationIO.group_valueAsOf(totalAnnualizedPremium,innerCycleCount).to_f : 0.0
            end
          end

          #Total Dividend Post Premium Offset
          totDividentPostPremOffset = 0.0
          if innerCycleCount <= basePlan.productTerm.to_i

            divAccinterest=(quotationIO.getIllustrationHeaderFieldValue("dividendaveragerate") != nil ? (quotationIO.getIllustrationHeaderFieldValue("dividendaveragerate").to_s) : 0.0)

            totDividentPostPremOffset = ((preCummulativedivident != nil ? preCummulativedivident.to_f : 0.0) - premiumOffset.to_f) * (divAccinterest.to_f) + (quotationIO.group_valueAsOf(illustrativeYearlyCashDividend,innerCycleCount) != nil ? quotationIO.group_valueAsOf(illustrativeYearlyCashDividend,innerCycleCount).to_f : 0.0)
          end


          #Cummulative Dividend
          cummulativedivident = 0.0
          if innerCycleCount <= basePlan.productTerm.to_i
            cummulativedivident = (preCummulativedivident != nil ? preCummulativedivident.to_f : 0.0) +totDividentPostPremOffset.to_f - premiumOffset.to_f
          end

          diff = 0
          if premiumOffset.to_f > preCummulativedivident.to_f
            diff = 1
          end

          preCummulativedivident = cummulativedivident.to_f

          difffound = false
          if diff >= 1
            #finalOffsetYear = innerCycleCount
            offsetYearfound = false
            difffound = true
          end
          #puts "preCummulativedivident : #{preCummulativedivident}, innerCycleCount : #{innerCycleCount}, premiumOffset : #{premiumOffset}, totDividentPostPremOffset : #{totDividentPostPremOffset}, cummulativedivident : #{cummulativedivident}, diff : #{diff}"
          if difffound
            break
          end
          innerCycleCount = innerCycleCount + 1
        end
        if offsetYearfound == true && cycleCount!=computationCycles
          finalOffsetYear = cycleCount
          break
        end
        cycleCount = cycleCount + 1
      end
      return finalOffsetYear
    end
	end
end
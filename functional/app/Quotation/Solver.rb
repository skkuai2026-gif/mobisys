require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_b_o'
require 'Policy/policy_b_o'
require 'Policy/PolicyUtil'


module MobiSys
	class Solver
		extend MobiSys::BrowserHelper
		
		def self.execute(quotationIO, facetId)
			return nil if quotationIO == nil
			$illustrationModelMap = Hash.new unless $illustrationModelMap
			quotation = quotationIO.baseDO
			basePlanQuote = quotation.getBasePlan
			basePlanProductDO = MobiSys::ProductUtil.getProduct(basePlanQuote.productSeq)
			policyDO = nil
			if quotation != nil
				policyDO = MobiSys::PolicyBO.convertToPolicy(quotation)
			end

			origProductTerm = basePlanQuote.productTerm
			#basePlanQuote.productTerm = ((basePlanQuote.targetPeriodRefCd.to_s=='TARGETAGE') ? (basePlanQuote.targetPeriod.to_i-quotation.getPartyByRole('PRIMARY').age.to_i) : basePlanQuote.targetPeriod.to_i)
			#From Facet Id get the Policy Model which will further evaluate the Solver model.
			policyModelCd = basePlanProductDO.getFacetValue(facetId)
			policyProductDO = policyDO.getBaseProduct
			
			policyModel = PolicyUtil::PolicyModel.new
			quotationIO.addModelAdditionalParams("SOLVER_CALL", true)
			# // load illustration model based on policyModelCd and check modelfor == policy
			illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{:name => 'modelCd'} => policyModelCd})
			if facetId.to_s != "WITHDRAWALSOLVERWRAPPERV8" && facetId.to_s != "TARGETFUNDSOLVERFORV8"
      modelResultDO = policyModel.execute(policyDO, policyProductDO, policyDO.getParty("PRIMARY"), policyModelCd,nil,nil,nil,quotationIO) if illustrationModel && illustrationModel.modelFor == "POLICY"
      else
      modelResultDO = nil
      end
      p "modelResultDO=========#{modelResultDO.inspect}"
			#reset the term back to original
			basePlanQuote.productTerm = origProductTerm
			#nullify all the calculations.. as the final SI Model needs to be evaluated after this. 
			quotationIO.illustrationModel = nil
			quotationIO.resetModelCalculation
			MobiSys::Solver.copyPolicyToQuotationAttributes(policyDO,quotation)
			#if no result was found then evaluate the earlier fixed solvers.
			quotationIO.baseDO = quotation
			quotation.getBasePlan.QuotationProductInvestmentFundList.each do |qpif|
				qpif.allocationPerc = "" if qpif.removed == "YES"
			end
      p "facetId============#{facetId}"
      if facetId.to_s == "WITHDRAWALSOLVERWRAPPERV8"
        if quotation.productFamilyCd.to_s == "TRAD"
          facetId = "WITHDRAWALSCHEDULESOLVERTRAD"
        else
          facetId = "WITHDRAWALSCHEDULESOLVERFORVUL"
        end
      end
      p "facetId=====22======#{facetId}"
			if modelResultDO == nil
				modelResultDO = MobiSys::Solver.solveFixedSolver(facetId, quotationIO, policyDO)
			end
			$illustrationModelMap = nil
			return modelResultDO
		end

		def self.copyPolicyToQuotationAttributes(policyDO, quotation)
			#copy all policy Product DO  to quotation Product DO
			policyProduct = policyDO.getBaseProduct
			quotationProduct = quotation.getBasePlan
			quotationProduct = MobiSys::CommonUtil.copyFields(policyProduct, quotationProduct)
			quotationProduct.status = ""
			#copy all policy Product Additional DO list to quotation Product Additional
			quotationProductAdditionalDOList = []

			if policyProduct.PolicyProductAdditionalList.size > 0
				policyProduct.PolicyProductAdditionalList.each do |policyProductAddtnl|
					quotationProductAddtnl = QuotationProductAdditional.new
					MobiSys::CommonUtil.copyFields(policyProductAddtnl, quotationProductAddtnl)
					quotationProductAddtnl.status = ""
					quotationProductAdditionalDOList << quotationProductAddtnl
				end
				quotationProduct.setQuotationProductAdditionalList(quotationProductAdditionalDOList)
			end

			quotationTopupDOList = []
			policyDO.PolicyTopUpList.each do |policyTopupDO|
				qtp = QuotationTopUp.new
				MobiSys::CommonUtil.copyFields(policyTopupDO, qtp)
				qtp.status = ""
				quotationTopupDOList << qtp
			end
			quotation.setQuotationTopUpList(quotationTopupDOList)
		end

		def self.solveFixedSolver(facetId, quotationIO, policy)
			flag = true
			if facetId.to_s == "INCOMEBASEDSASOLVER"
				#for SA solver copy the Sum assured
                MobiSys::ProductBO.loadModel(facetId,quotationIO)
                quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                quotationIO.baseDO.getBaseProduct.baseSumAssured = policy.getBaseProduct.baseSumAssured if quotationIO.baseDO.getBaseProduct != nil && policy.getBaseProduct != nil
			elsif facetId.to_s == "WITHDRAWALBASEDSASOLVER"
                MobiSys::ProductBO.loadModel(facetId,quotationIO)
                quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                #for withdrawal based SA solver compare the Sum assured and raise validation
                #raise validation on the UI not to be added to exception list
                quotationIO.baseDO.getBaseProduct.baseSumAssured = policy.getBaseProduct.baseSumAssured if quotationIO.baseDO.getBaseProduct != nil && policy.getBaseProduct != nil
			elsif facetId.to_s == "WITHDRAWALSCHEDULESOLVER"
				        MobiSys::ProductBO.loadModel(facetId,quotationIO)
                quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                #for withdrawal schedule solver copy the withdrawal schedule.
                quotationIO.baseDO.QuotationWithdrawalList = []
                listPolWithdrawal = policy.getListPolicyWithdrawalList
                if listPolWithdrawal.size > 0
                	listPolWithdrawal.each do |policyWithdrawal|
                		quotWithdrawal = QuotationWithdrawal.new
                		quotWithdrawal.policyYearFrom = policyWithdrawal.policyYearFrom
                		quotWithdrawal.policyYearTo = policyWithdrawal.policyYearTo
                		quotWithdrawal.withdrawalAmount = policyWithdrawal.withdrawalAmount
                		quotWithdrawal.ageFrom = policyWithdrawal.ageFrom
                		quotWithdrawal.ageTo = policyWithdrawal.ageTo
                		quotWithdrawal.frequencyVal = policyWithdrawal.frequencyVal
                		quotWithdrawal.status = ""
                		quotationIO.baseDO.addQuotationWithdrawal(quotWithdrawal)
                	end
                end
			elsif facetId.to_s == "TARGETFUNDVALUESOLVER" || facetId.to_s == "TARGETFUNDSOLVERFORV8"
				        computedFundValue = 0.0
                basePlanQuote = quotationIO.baseDO.getBasePlan
                quotationIO.baseProduct = basePlanQuote

                if basePlanQuote.productTerm.to_s == ""
                	Rho::Log.error("Error: No product term entered. Evaluation runs for the entire product term.", "Solver")
                	return
                end
                return if (basePlanQuote.targetFundVal.to_s == nil || basePlanQuote.targetFundVal.to_i == 0)

                targetFundValue = MobiSys::Math.roundDown(basePlanQuote.targetFundVal,0)
                targetFundPeriod = basePlanQuote.targetPeriod

                return if(targetFundPeriod.to_s == "" || targetFundPeriod.to_i == 0)

                origProductTerm = basePlanQuote.productTerm
                #set the policyterm as the target fund value period
				        #check based on reference whether age based or policy year based.
                targetPeriodRef = basePlanQuote.targetPeriodRefCd
                if targetPeriodRef.to_s != ""
                	#if age based then calculate the period based on the current age and the target age
                	if targetPeriodRef.to_s == "TARGETAGE"
                		currentAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age
                		targetFundPeriod = basePlanQuote.targetPeriod.to_i - currentAge.to_i
                	end
                end

                basePlanQuote.productTerm = targetFundPeriod
                quotationTopUpList = quotationIO.baseDO.getTopupByType("REGULARTOPUP")
                regularQuotationTopup = (quotationTopUpList.size > 0 ? quotationTopUpList[0] : nil)
                if regularQuotationTopup.to_s == nil
                	regularQuotationTopup = QuotationTopUp.new
                	regularQuotationTopup.topUpTypeCd = "REGULARTOPUP"
                	quotationIO.baseDO.addQuotationTopUp(regularQuotationTopup)
                end
                requiredTopUpAmt = regularQuotationTopup.topUpAmount if regularQuotationTopup
                incrementBy = 10000000
                incrementDiv = 10
                requiredTopUp = 0
                MobiSys::ProductBO.loadModel(facetId, quotationIO)
                regularQuotationTopup.topUpPeriod = targetFundPeriod

                loop do
                	requiredTopUp = requiredTopUp + incrementBy
                	#invoke the fund value calculation model to compute the fund value
                	regularQuotationTopup.topUpAmount = requiredTopUp  
                	quotationIO.resetModelCalculation
                	quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                	computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBaseProduct.targetFundVal,0)

                	break if computedFundValue.to_i == 0

                	if computedFundValue > targetFundValue
                		requiredTopUp = requiredTopUp - incrementBy
                		incrementBy = incrementBy / incrementDiv
                	end
                	break if computedFundValue == targetFundValue
                end

                regularQuotationTopup.topUpAmount = MobiSys::Math.roundUp(requiredTopUp,0)

                #reset the term back to original
                basePlanQuote.productTerm = origProductTerm
                regularQuotationTopup.topUpAmount = requiredTopUpAmt
                #nullify all the calculations.. as the final SI Model needs to be evaluated after this.
                quotationIO.illustrationModel = nil
                quotationIO.resetModelCalculation
            ##########################################
      elsif facetId.to_s == "WITHDRAWALSCHEDULESOLVERFORVUL"
            	##################
            	startTime = Time.now
            # quotationIO = MobiSys::IO::QuotationIO.new
            @quotation = quotationIO.baseDO
			      basePlanQuote = @quotation.getBasePlan
			      basePlanProductDO = MobiSys::ProductUtil.getProduct(basePlanQuote.productSeq)
            listQuotationProductFunds = basePlanQuote.QuotationProductInvestmentFundList
            basePlanQuote.setQuotationProductInvestmentFundList([])

            listQuotationProductFunds.each do |quotationProductFund|
              basePlanQuote.QuotationProductInvestmentFundList.push(quotationProductFund) if quotationProductFund.allocationPerc.to_i > 0
            end


            quotationIO.baseDO = @quotation.cloneObject
            quotationIO.baseProduct = quotationIO.baseDO.getBasePlan
            topupOptionCd = quotationIO.baseDO.topupOptionCd
            if (topupOptionCd == "TFCALCULATIONWITHOUTPH")
            preGenerateIllustration(quotationIO)
            @quotation.getRegularTopup.topUpAmount = quotationIO.baseDO.getRegularTopup.topUpAmount
            basePlanQuote.payingYears = quotationIO.baseDO.getBasePlan.payingYears
            end

            basePlanQuote = quotationIO.baseDO.getBasePlan
            @withdraws = quotationIO.baseDO.QuotationWithdrawalList
            if flag
                if basePlanQuote.productTerm.to_i != 0
                  # productDO = Product.loadObject(:first, :conditions => {{:name => 'id'} => basePlanQuote.productSeq })
                  #added code to fetch product from memery
                  productDO = MobiSys::ProductUtil.getProduct(basePlanQuote.productSeq)
                  if productDO != nil && productDO.OfflineFacetList != nil && productDO.getPremiumDetailsFacet != nil
                    premiumDetailsDO = productDO.getPremiumDetailsFacet.OfflinePremiumDetailsList
                    if premiumDetailsDO != nil
                      #basePlanQuote.update_attributes(:currencyCd => premiumDetailsDO[0].currencyCd)
                    end
                  end

                  jholFlag = false
                  withdrawalAmount = 0
                  initialWithdrawalAmount = 0
                  incrementBy = 0.0
                  basePlanQuote.currencyCd = "USD"
                  if basePlanQuote.currencyCd == "PHP"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue
                    initialWithdrawalAmount = withdrawalAmount
                    dMin_Fund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end
                  if basePlanQuote.currencyCd == "USD"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue
                    initialWithdrawalAmount = withdrawalAmount
                    incrementBy = 100000.0
                    dMin_Fund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end

                  hmAddtnlEvalParams = {}
                  # hmAddtnlEvalParams["withdrawalmethod"] = "NR"
                  quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)

                  MobiSys::ProductBO.loadModel(facetId,quotationIO)
                  originalIllustrationModel  = MobiSys::ProductBO.loadModel(facetId,quotationIO)
                  originalIllustrationRateList = originalIllustrationModel.IllustrationRateList

                  freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(quotationIO.illustrationModel.computationFrequencyCd)
                  if("EDUCATION" == quotationIO.baseDO.withdrawalRateTypeCd)
                    maxYear = []
                    quotationWithdrawalList = quotationIO.baseDO.QuotationWithdrawalList;
                    if(quotationWithdrawalList.size > 0)
                      quotationWithdrawalList.each do |quotationWithdrawal|
                        maxYear.push(quotationWithdrawal.policyYearTo.to_i)
                      end
                    end
                    maxYear = maxYear.max
                    iFundMonth = maxYear * freqMultiplier
                  else
                    iFundMonth = basePlanQuote.productTerm.to_i * freqMultiplier
                  end

                  iChg = 1
                  i = 0
                  iThreshold = productDO.getFacetValue('WITHDRAWALTHRESHOLD').to_i #20
                  dTolerance = productDO.getFacetValue('WITHDRAWALTOLERANCE').to_f #0.1
                  iFundMonthOriginal = iFundMonth #684
                  # incrementBy =  1000000.0
                  findMaxValue = 0
                  findMinValue = initialWithdrawalAmount
                  p "quotationIO======#{quotationIO.input_minimum("self.quotation.getWithdrawal", "policyYearFrom").inspect}"
                  earliestWithdrawMonth1 = (quotationIO.input_minimum("self.quotation.getWithdrawal", "policyYearFrom")).to_i * freqMultiplier.to_i

                  begin
                    i = i + 1
                    earliestWithdrawMonth =earliestWithdrawMonth1
                    quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                    quotationIO.listCalculation = []
                    quotationIO.illustrationHeader = nil
                    quotationIO.baseDO = @quotation.cloneObject
                    quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount
                    #quotationIO.baseDO.getBaseProduct.productTerm = (iFundMonthOriginal / 12)
                    quotationIO.loopReference = "outerLoop" + initialWithdrawalAmount.to_s
                    quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                    computationCycles = quotationIO.baseDO.getBasePlan.productTerm.to_i * freqMultiplier
                    matFundA = quotationIO.group_valueAsOf("tfvgrouplow", iFundMonthOriginal, "LOW");
                    if(earliestWithdrawMonth != nil && findMaxValue == 0)
                      minWithdrawalYearPol = earliestWithdrawMonth;
                      #since this is monthly running the cycle count would be 12 * minWithdrawalYear
                      tfvGroupLowA = quotationIO.group_valueAsOf("tfvgrouplow", minWithdrawalYearPol, "LOW")
                      if(tfvGroupLowA != nil)
                     
                      end
                      tfvGroupLowB = quotationIO.group_valueAsOf("tfvgrouplow", computationCycles, "LOW");
                      if(tfvGroupLowB != nil)
                    
                      end
                      if(tfvGroupLowA != nil && tfvGroupLowB != nil)
                        maxWithdrawalAmt = tfvGroupLowA < tfvGroupLowB ? tfvGroupLowA : tfvGroupLowB;
                    
                        findMaxValue = maxWithdrawalAmt #686425
                      end
                    end

                   #'***********Find BS Initial Value**************

                    if initialWithdrawalAmount > findMaxValue#indicator > 0 And
                        # findMaxValue = initialWithdrawalAmount #' Find maximum withdrawal amount with no fund value < dMin_Fund
                      if findMaxValue < withdrawalAmount #Then ' Exit NR and do BS once iteration hits threshold
                        initialWithdrawalAmount = findMaxValue
                        break
                      end
                    elsif initialWithdrawalAmount < findMinValue #Then indicator = 0 And
                        findMinValue = initialWithdrawalAmount #' Find minimum withdrawal amount with fund value > dMin_Fund
                    end

                   #'***********End**************

                    if i > iThreshold #Then ' Exit NR and do BS once iteration hits threshold
                      break
                    end

                    tfvgrouplowHash = {}
                    monthCount  = 1
                    while monthCount <= iFundMonthOriginal
                      tfvGroupLowB = quotationIO.group_valueAsOf("tfvgrouplow", monthCount, "LOW");
                      tfvgrouplowHash[monthCount] = tfvGroupLowB
                      monthCount = monthCount + 1
                    end

                    earliestWithdrawMonthHash = {}
                    withdrawalMonths = earliestWithdrawMonth
                   
                    while withdrawalMonths <= iFundMonthOriginal
                      tfvGroupLowB = quotationIO.group_valueAsOf("tfvgrouplow", withdrawalMonths, "LOW");
                      earliestWithdrawMonthHash[withdrawalMonths] = tfvGroupLowB
                      withdrawalMonths = withdrawalMonths + 1
                    end
                    
                    minTfvgroupValue = earliestWithdrawMonthHash.select {|k,v| v == earliestWithdrawMonthHash.values.min }

                    if minTfvgroupValue.values[0] < dMin_Fund
                      jholFlag = true
                    else
                      jholFlag = false
                    end
                  
                    iFundMonth = MobiSys::Solver.newFundMonth2(iFundMonthOriginal, quotationIO, minTfvgroupValue, tfvgrouplowHash, freqMultiplier, dMin_Fund)
                    if iFundMonth != iFundMonthOriginal
                        if i == 1 #Then 'If any fund turns less than min fund, break the loop
                           initialWithdrawalAmount = 4500
                           dWD_Old = 4500
                           quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount
                        else
                            initialWithdrawalAmount = 5000 #'Min withdrawal amount
                            iFundMonthOriginal = iFundMonth
                            dWD_Old = 0
                        end
                    else
                        i = i + 1 #'Iteration counter
                        #'Determine fund value at the target fund month after a small change in withdrawals
                        quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                        quotationIO.listCalculation = []
                        quotationIO.illustrationHeader = nil
                        quotationIO.baseDO = @quotation.cloneObject
                        quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount + iChg
                        quotationIO.loopReference = "innerLoop" + (initialWithdrawalAmount + iChg).to_s
                        quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                        matFundB = quotationIO.group_valueAsOf("tfvgrouplow", iFundMonthOriginal, "LOW");#value of iFundMonth
                        # matFundB = 0 #testing
                        dWD_Old = initialWithdrawalAmount #' Store current iteration's withdrawal value

                        initialWithdrawalAmount = (dWD_Old - (iChg * (matFundA - dMin_Fund) / (matFundB - matFundA))) #'Calculate next iteration's withdrawal value
                    end
                  end while (dWD_Old - initialWithdrawalAmount).abs > dTolerance #' If the difference in sequential withdrawals is within the tolerence limit, end NR. Else loop again

                  if i > iThreshold #Then ' Exit NR and do BS once iteration hits threshold
                    quotationIO = bisection_Method_NR(@quotation, quotationIO, findMinValue, findMaxValue, i, originalIllustrationRateList)
                  else
                    if initialWithdrawalAmount < withdrawalAmount
                      Alert.show_popup({:title=>'Warning',
                        :message=>getLabelValue("ERR_GENERATEILLUSTRATIONADDMESG"),
                        :buttons=>["OK"]})
                      quotationIO.baseDO.QuotationWithdrawalList.each do |withdrawal|
                        withdrawal.withdrawalAmount = ''
                      end
                    else

                      quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                      quotationIO.listCalculation = []
                      quotationIO.illustrationHeader = nil
                      quotationIO.baseDO = @quotation.cloneObject
                      quotationIO.baseDO.getBaseProduct.ropPerc = MobiSys::Math.roundDown(initialWithdrawalAmount.to_f, 2)
                      quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)

                      earliestWithdrawMonthOriginal1 = quotationIO.input_minimum("self.quotation.getWithdrawal", "policyYearFrom") * freqMultiplier
                      earliestWithdrawMonthOriginal2 = earliestWithdrawMonthOriginal1
                      while earliestWithdrawMonthOriginal1 <= iFundMonthOriginal
                        tfvGroupLowB = quotationIO.group_valueAsOf("tfvgrouplow", earliestWithdrawMonthOriginal1, "LOW");
                        # earliestWithdrawMonthHash[earliestWithdrawMonthOriginal1] = tfvGroupLowB
                        if(earliestWithdrawMonthOriginal2 == earliestWithdrawMonthOriginal1)
                            minValue = tfvGroupLowB
                            minKey = earliestWithdrawMonthOriginal2-earliestWithdrawMonthOriginal1
                        elsif(minValue > tfvGroupLowB)
                            minValue = tfvGroupLowB;
                            minKey = earliestWithdrawMonthOriginal1 - earliestWithdrawMonthOriginal2;
                        end
                        # p "minValue===#{tfvGroupLowB}====minKey=====#{minKey}===dMin_Fund===#{dMin_Fund}"
                        earliestWithdrawMonthOriginal1 = earliestWithdrawMonthOriginal1 + 1
                      end
                      if(minValue < dMin_Fund)
                        jholFlag = true;
                      else
                        jholFlag = false;
                      end
                      if(jholFlag)
                        initialWithdrawalAmount = initialWithdrawalAmount - 0.02;
                      end

                      quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                      quotationIO.listCalculation = []
                      quotationIO.illustrationHeader = nil
                      quotationIO.baseDO = @quotation.cloneObject
                      quotationIO.baseDO.getBaseProduct.ropPerc = MobiSys::Math.roundDown(initialWithdrawalAmount.to_f, 2)
                      quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                    end
                  end

                    $commonResults = nil
                    @withdraws = quotationIO.baseDO.QuotationWithdrawalList
                    @withdraws.each do |withdrawal|
                        
                            withdrawal.withdrawalAmount = MobiSys::Math.roundDown(withdrawal.withdrawalAmount.to_f, 2)
                            $maxWithdrawalAmount = withdrawal.withdrawalAmount
                            @quotation.QuotationWithdrawalList.each do |quotationWithdraw|
                                if withdrawal.guid == quotationWithdraw.guid
                                    withdrawal.object = quotationWithdraw.object
                                
                                end
                            end
                    end
                    @withdraws = @withdraws.sort_by!{|k| k.policyYearFrom.to_i} if @withdraws.size > 0
                end
              end
              GC.enable
              GC.start
              # html = render(:partial => 'showWithdrawalInformation')
              return @withdraws
            
      elsif facetId.to_s == "WITHDRAWALSCHEDULESOLVERTRAD"
              startTime = Time.now
              # quotationIO = MobiSys::IO::QuotationIO.new
              @quotation = quotationIO.baseDO
              quotationIO.baseDO = @quotation.cloneObject
              quotationIO.baseProduct = quotationIO.baseDO.getBasePlan
              topupOptionCd = quotationIO.baseDO.topupOptionCd
              basePlanQuote = quotationIO.baseDO.getBasePlan
              # productDO = Product.loadObject(:first, :conditions => {{:name => 'id'} => basePlanQuote.productSeq })
              #added code to fetch product from memery
              productDO = MobiSys::ProductUtil.getProduct(basePlanQuote.productSeq)
              @withdraws = quotationIO.baseDO.QuotationWithdrawalList

              flag = true
              if flag
                if basePlanQuote.productTerm.to_i != 0
                  # productDO = Product.loadObject(:first, :conditions => {{:name => 'id'} => basePlanQuote.productSeq })
                  if productDO != nil && productDO.OfflineFacetList != nil && productDO.getPremiumDetailsFacet != nil
                    premiumDetailsDO = productDO.getPremiumDetailsFacet.OfflinePremiumDetailsList
                    if premiumDetailsDO != nil
                      #basePlanQuote.update_attributes(:currencyCd => premiumDetailsDO[0].currencyCd)
                    end
                  end
                  withdrawalAmount = 0
                  initialWithdrawalAmount = 0
                  incrementBy = 0.0
                  if basePlanQuote.currencyCd == "PHP"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue
                   
                    initialWithdrawalAmount = withdrawalAmount
                    smallestAllowableFund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end
                  if basePlanQuote.currencyCd == "USD"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue
                    initialWithdrawalAmount = withdrawalAmount
                    incrementBy = 100000.0
                    smallestAllowableFund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end

                  iChg = 1
                  i = 0
                  dTolerance = productDO.getFacetValue('WITHDRAWALTOLERANCE').to_f
                  iPaymentYears = quotationIO.baseDO.payingYears.to_i
                  iFundYear = quotationIO.input_minimum("self.quotation.getWithdrawal", "policyYearFrom");
                  iFundMonthOriginal = iFundYear
                  iMaxWDDur = basePlanQuote.productTerm.to_i
                  tfvgrouplowHash = {}

                  MobiSys::ProductBO.loadModel(facetId,quotationIO)
                  originalIllustrationModel  = MobiSys::ProductBO.loadModel(facetId,quotationIO)
                  originalIllustrationRateList = originalIllustrationModel.IllustrationRateList
                  begin
                    begin
                      i = i + 1
                      quotationIO.listCalculation = []
                      quotationIO.illustrationHeader = nil
                      quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                      quotationIO.baseDO = @quotation.cloneObject
                      quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount
                      quotationIO.loopReference = "innerLoop" + initialWithdrawalAmount.to_s
                      quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                      matFundA = quotationIO.group_valueAsOf("varfunetaccumfund", iFundMonthOriginal, "LOW");


                      iterator = iFundYear
                      while iterator <= iMaxWDDur
                        tfvGroupLowB = quotationIO.group_valueAsOf("varfunetaccumfund", iterator, "LOW");
                        tfvgrouplowHash[iterator] = tfvGroupLowB
                        iterator = iterator + 1
                      end

                      minTfvgroupValue = tfvgrouplowHash.select {|k,v| v == tfvgrouplowHash.values.min }

                      iCount = minTfvgroupValue.keys[0]

                      if minTfvgroupValue.values[0] < smallestAllowableFund
                        if i == 1 #Then 'If any fund turns less than min fund, break the loop
                           initialWithdrawalAmount = 500
                           dWD_Old = 500
                           quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount
                        end
                      end

                      #'Determine fund value at the target fund month after a small change in withdrawals
                      i = i + 1
                      quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                      quotationIO.listCalculation = []
                      quotationIO.illustrationHeader = nil
                      quotationIO.baseDO = @quotation.cloneObject
                      quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount + iChg
                      quotationIO.loopReference = "innerLoop2" + (initialWithdrawalAmount + iChg).to_s
                      quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                      matFundB = quotationIO.group_valueAsOf("varfunetaccumfund", iFundMonthOriginal, "LOW");#value of iFundMonth

                      dWD_Old = initialWithdrawalAmount #' Store current iteration's withdrawal value
                      p "dWD_Old==============#{dWD_Old}"
                      p "matFundA============#{matFundA}==matfundb====#{matFundB}"
                      p "smallestAllowableFund==========#{smallestAllowableFund}"
                      initialWithdrawalAmount = MobiSys::Math.roundDown((dWD_Old - (iChg * (matFundA - smallestAllowableFund) / (matFundB - matFundA))), 2) #'Calculate next iteration's withdrawal value
                      p "initialWithdrawalAmount===============#{initialWithdrawalAmount}"
                      
                    end while (dWD_Old - initialWithdrawalAmount).abs >= dTolerance #' If the difference in sequential withdrawals is within the tolerence limit, end NR. Else loop again

                    quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList
                    quotationIO.listCalculation = []
                    quotationIO.illustrationHeader = nil
                    quotationIO.baseDO = @quotation.cloneObject
                    quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount
                    quotationIO.loopReference = "outerLoop" + (initialWithdrawalAmount).to_s
                    quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                    iterator = iFundYear
                    while iterator <= iMaxWDDur
                      tfvGroupLowB = quotationIO.group_valueAsOf("varfunetaccumfund", iterator, "LOW");
                      tfvgrouplowHash[iterator] = tfvGroupLowB
                      iterator = iterator + 1
                    end
                    minTfvgroupValue = tfvgrouplowHash.select {|k,v| v == tfvgrouplowHash.values.min }

                    earliestWithdrawMonthHash = {}
                    # iterator = iFundYear
                    minFunDTest = iFundYear #1
                    while minFunDTest <= iMaxWDDur
                      tfvGroupLowB = quotationIO.group_valueAsOf("minfundtest", minFunDTest, "LOW");
                      earliestWithdrawMonthHash[minFunDTest] = tfvGroupLowB
                      minFunDTest = minFunDTest + 1
                    end

                    minTfvgroupValue2 = earliestWithdrawMonthHash.select {|k,v| v == earliestWithdrawMonthHash.values.min }
                    iCount = minTfvgroupValue2.keys[0]
                    if iFundMonthOriginal == iCount
                        iFundMonthOriginal = -1
                    else
                        iFundMonthOriginal = iCount
                    end
                  end while (iFundMonthOriginal != -1)
                 
                  if (minTfvgroupValue.values[0] < smallestAllowableFund) || (initialWithdrawalAmount < withdrawalAmount) #Then ' If the smallest withdrawal causes the fund to be less than the min fund at any duration
                    Alert.show_popup({:title=>'Warning',
                      :message=> getLabelValue("ERR_GENERATEILLUSTRATIONADDMESG"),
                      :buttons=>["OK"]})
                    quotationIO.baseDO.QuotationWithdrawalList.each do |withdrawal|
                      withdrawal.withdrawalAmount = ''
                    end
                  end

                  $commonResults = nil
                  @withdraws = quotationIO.baseDO.QuotationWithdrawalList
                  
                  @withdraws.each do |withdrawal|
                        
                    withdrawal.withdrawalAmount = MobiSys::Math.roundDown(withdrawal.withdrawalAmount.to_f, 2)
                    $maxWithdrawalAmount = withdrawal.withdrawalAmount
                    @quotation.QuotationWithdrawalList.each do |quotationWithdraw|
                        if withdrawal.guid == quotationWithdraw.guid
                            withdrawal.object = quotationWithdraw.object
                        
                        end
                    end
                        
                    end
                    @withdraws = @withdraws.sort_by!{|k| k.policyYearFrom.to_i} if @withdraws.size > 0
                   
                end
              end
              return @withdraws
              # html = render(:partial => 'showWithdrawalInformation')
              # returnValue = html
            ##########################################
			end
		end

		def self.newFundMonth2(iFundMonth, quotationIO, minTfvgroupValue = nil , tfvgrouplowHash = nil, freqMultiplier = nil, dMin_Fund =nil )
	        basePlanQuote = quotationIO.baseDO.getBasePlan
	        earliestWithdrawMonth = quotationIO.input_minimum("self.quotation.getWithdrawal", "policyYearFrom") * freqMultiplier
	        tfvGroupLowA = quotationIO.group_valueAsOf("tfvgrouplow", earliestWithdrawMonth, "LOW");
	        iCount = minTfvgroupValue.keys[0]
	        iCount = iCount
	        if minTfvgroupValue.values[0] < dMin_Fund
	          if minTfvgroupValue.values[0] < tfvgrouplowHash.values.last
	            newFundMonth2 = iCount #'if the month with the min fund value was not used in the previous NR run,set it as the new fund month for the NR run
	          else
	            if minTfvgroupValue.values[0] == tfvgrouplowHash.values.last#value of iFundMonth
	              newFundMonth2 = iFundMonth
	            else
	              newFundMonth2 = -1 #'otherwise end the NR solver
	            end
	          end
	        else
	          newFundMonth2 = iFundMonth
	        end
	        newFundMonth2
    	end
	
	end
end
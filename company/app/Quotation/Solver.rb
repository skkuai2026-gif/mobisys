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
      p"facetId==========#{facetId}"
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
      # basePlanQuote.productTerm = ((basePlanQuote.targetPeriodRefCd.to_s=='TARGETAGE') ? (basePlanQuote.targetPeriod.to_i-quotation.getPartyByRole('PRIMARY').age.to_i) : basePlanQuote.targetPeriod.to_i)
   #    p"basePlanQuote.productTerm=======#{basePlanQuote.productTerm}"
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
      quotation.quotAddtnlField10 = policyDO.quotAddtnlField10
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
            topupOptionCd = quotationIO.baseDO.topupOptionCd
            if (topupOptionCd == "TFCALCULATIONWITHOUTPH" or topupOptionCd == "TFCALCULATIONWITHPH" or topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH")
              computedFundValue = 0.0
              basePlanQuote = quotationIO.baseDO.getBaseProduct
              if basePlanQuote.productTerm == nil or basePlanQuote.productTerm == ""
                #puts "Error: No product term entered. Evaluation runs for the entire product term."
                return
              end
              targetFundVal = basePlanQuote.targetFundVal
              return unless targetFundVal and targetFundVal.to_i != 0
              targetFundValue = MobiSys::Math.roundDown(targetFundVal,0);
              targetFundPeriod = basePlanQuote.targetPeriod
              return unless targetFundPeriod and targetFundPeriod != 0
              originalProductTerm = basePlanQuote.productTerm
              targetPeriodRef = basePlanQuote.targetPeriodRefCd
              if targetPeriodRef
                if targetPeriodRef == "TARGETAGE"
                  currentAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age
                  targetFundPeriod = basePlanQuote.targetPeriod.to_i - currentAge.to_i
                end
              end

              basePlanQuote.productTerm = targetFundPeriod
              regularQuotationTopup = quotationIO.baseDO.getRegularTopup
              unless regularQuotationTopup
                regularQuotationTopup = QuotationTopUp.new
                regularQuotationTopup.topUpAmount = 0
                regularQuotationTopup.topUpTypeCd = "REGULARTOPUP"
                quotationIO.baseDO.addQuotationTopUp regularQuotationTopup
              end
              
              orignalQuotation = quotationIO.baseDO
              quotationIO.baseDO = orignalQuotation.cloneObject

              regularExcess = regularQuotationTopup.topUpAmount
              computedFundValue = 0.0
              iterations = 0
              requiredTopUpAmt = regularQuotationTopup.topUpAmount;
              regularQuotationTopup.topUpPeriod = targetFundPeriod
              MobiSys::ProductBO.loadModel("TARGETFUNDVALUECALC", quotationIO);

              MobiSys::QuotationService.solveForTarget(quotationIO, regularExcess)
              computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);

              isComputedFundValueGreater=false;
              if(computedFundValue > targetFundValue)
                isComputedFundValueGreater=true;
              end

              # 11-13-2014
              firstCount = 1
              if(!isComputedFundValueGreater)
                mintopup=0.0;
                if "PHP" == basePlanQuote.currencyCd
                  maxtopup=500000;
                  incrementBy = 500000;
                elsif "USD"== basePlanQuote.currencyCd
                  maxtopup=50000;
                  incrementBy = 50000;
                end
                requiredAvgTopUp=0.0;
                checkedAvgTopUp =0.0;
                loop do
                    quotationIO.baseDO = orignalQuotation.cloneObject
                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup
                    regularQuotationTopup.topUpAmount = maxtopup
                    MobiSys::QuotationService.solveForTarget(quotationIO, maxtopup)

                    computedFundValue =  MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
                    if(computedFundValue == 0)
                      break;
                    end

                    if(computedFundValue < targetFundValue)
                      mintopup=maxtopup;
                      maxtopup=maxtopup+incrementBy;
                    end
                     break if !(computedFundValue <= targetFundValue);
                     firstCount = firstCount+1

                end
                loop do
                    if((("TFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd) ||
                        ("EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd)) && ("PHP" == basePlanQuote.currencyCd))
                      incrementBy=100;
                    else
                      incrementBy=1;
                    end

                    quotationIO.baseDO = orignalQuotation.cloneObject
                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

                    requiredAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;

                    regularQuotationTopup.topUpAmount = requiredAvgTopUp
                    MobiSys::QuotationService.solveForTarget(quotationIO, requiredAvgTopUp)

                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
                    if(computedFundValue == 0)
                      break;
                    end

                    if(computedFundValue < targetFundValue)
                      mintopup=requiredAvgTopUp;
                    else
                      maxtopup=requiredAvgTopUp;
                    end
                    checkedAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;
                    break if !((checkedAvgTopUp < maxtopup) || (computedFundValue < targetFundValue));
                end

                regularQuotationTopup.topUpAmount = MobiSys::Math.roundUp(requiredAvgTopUp,0);
              elsif (isComputedFundValueGreater && "EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd)
                noofpayingyears = targetFundPeriod;
                decrementBy = 10;

                loop do
                    noofpayingyears = noofpayingyears - decrementBy

                    quotationIO.baseDO = orignalQuotation.cloneObject
                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
                    regularQuotationTopup.topUpAmount = requiredTopUpAmt
                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
                    MobiSys::QuotationService.solveForTarget(quotationIO, requiredTopUpAmt)


                    
                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
                    if(computedFundValue == 0)
                      break;
                    end
                    break if !( computedFundValue >= targetFundValue);
                end

                  noofpayingyears = noofpayingyears+decrementBy
                  decrementBy = 1;
                loop do
                    noofpayingyears = noofpayingyears - decrementBy

                    quotationIO.baseDO = orignalQuotation.cloneObject
                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
                    regularQuotationTopup.topUpAmount = requiredTopUpAmt
                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
                    MobiSys::QuotationService.solveForTarget(quotationIO, requiredTopUpAmt)
                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
                    if(computedFundValue == 0)
                      break;
                    end
                    break if !( computedFundValue >= targetFundValue);
                end
                noofpayingyears = noofpayingyears + decrementBy
                regularQuotationTopup.topUpPeriod = noofpayingyears
                quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
              end
              basePlanQuote.productTerm = originalProductTerm
              orignalQuotation.getBasePlan.payingYears = quotationIO.baseDO.getBasePlan.payingYears

              orignalQuotation.getRegularTopup.topUpAmount = quotationIO.baseDO.getRegularTopup.topUpAmount
              quotationIO.baseDO = orignalQuotation

              regularQuotationTopup = quotationIO.baseDO.getRegularTopup
              quotationIO.illustrationModel = nil
            end
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
            MobiSys::QuotationService.preGenerateIllustration(quotationIO)
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
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue if minMaxWithdrawalAmount
                    initialWithdrawalAmount = withdrawalAmount if withdrawalAmount
                    dMin_Fund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end
                  if basePlanQuote.currencyCd == "USD"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue if minMaxWithdrawalAmount
                    initialWithdrawalAmount = withdrawalAmount if withdrawalAmount
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
                    matFundA = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", iFundMonthOriginal, "LOW"))
                    if(earliestWithdrawMonth != nil && findMaxValue == 0)
                      minWithdrawalYearPol = earliestWithdrawMonth;
                      #since this is monthly running the cycle count would be 12 * minWithdrawalYear
                      tfvGroupLowA = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", minWithdrawalYearPol, "LOW"))
                      if(tfvGroupLowA != nil)
                     
                      end
                      tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", computationCycles, "LOW"));
                      if(tfvGroupLowB != nil)
                    
                      end
                      if(tfvGroupLowA != nil && tfvGroupLowB != nil)
                        maxWithdrawalAmt = tfvGroupLowA < tfvGroupLowB ? tfvGroupLowA : tfvGroupLowB;
                    
                        findMaxValue =maxWithdrawalAmt #686425
                      end
                    end

                   #'***********Find BS Initial Value**************

                    if initialWithdrawalAmount.to_f > findMaxValue.to_f#indicator > 0 And
                        # findMaxValue = initialWithdrawalAmount #' Find maximum withdrawal amount with no fund value < dMin_Fund
                      if findMaxValue < withdrawalAmount.to_f #Then ' Exit NR and do BS once iteration hits threshold
                        initialWithdrawalAmount = findMaxValue
                        break
                      end
                    elsif initialWithdrawalAmount.to_f < findMinValue.to_f #Then indicator = 0 And
                        findMinValue = initialWithdrawalAmount #' Find minimum withdrawal amount with fund value > dMin_Fund
                    end

                   #'***********End**************

                    if i > iThreshold #Then ' Exit NR and do BS once iteration hits threshold
                      break
                    end

                    tfvgrouplowHash = {}
                    monthCount  = 1
                    while monthCount <= iFundMonthOriginal
                      tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", monthCount, "LOW"));
                      tfvgrouplowHash[monthCount] = tfvGroupLowB
                      monthCount = monthCount + 1
                    end

                    earliestWithdrawMonthHash = {}
                    withdrawalMonths = earliestWithdrawMonth
                   
                    while withdrawalMonths <= iFundMonthOriginal
                      tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", withdrawalMonths, "LOW"));
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
                        quotationIO.baseDO.getBaseProduct.ropPerc = initialWithdrawalAmount.to_f + iChg
                        quotationIO.loopReference = "innerLoop" + (initialWithdrawalAmount.to_f + iChg).to_s
                        quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
                        matFundB = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", iFundMonthOriginal, "LOW"));#value of iFundMonth
                        # matFundB = 0 #testing
                        dWD_Old = initialWithdrawalAmount.to_f #' Store current iteration's withdrawal value
                        initialWithdrawalAmount = asDouble(dWD_Old - (iChg * (matFundA - dMin_Fund) / (matFundB - matFundA))) #'Calculate next iteration's withdrawal value
                    end
                  end while (dWD_Old - initialWithdrawalAmount).abs > dTolerance #' If the difference in sequential withdrawals is within the tolerence limit, end NR. Else loop again

                  if i > iThreshold #Then ' Exit NR and do BS once iteration hits threshold
                    quotationIO = MobiSys::Solver.bisection_Method_NR(@quotation, quotationIO, findMinValue, findMaxValue, i, originalIllustrationRateList)
                  else
                    if initialWithdrawalAmount.to_f < withdrawalAmount.to_f
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
                        tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("tfvgrouplow", earliestWithdrawMonthOriginal1, "LOW"));
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
                   
                    initialWithdrawalAmount = withdrawalAmount.to_f
                    smallestAllowableFund = productDO.getFacetValue('WITHDRAWALMINALLFUND').to_i
                  end
                  if basePlanQuote.currencyCd == "USD"
                    minMaxWithdrawalAmount = productDO.getTableTypeMappingSeq('MINMAXWITHDRAWALAMOUNT')
                    withdrawalAmount = MobiSys::ProductBO.getProductDefinitionTable(minMaxWithdrawalAmount, @quotation, basePlanQuote).minValue
                    initialWithdrawalAmount = withdrawalAmount.to_f
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
                      matFundA = asDouble(quotationIO.group_valueAsOf("varfunetaccumfund", iFundMonthOriginal, "LOW"));


                      iterator = iFundYear
                      while iterator <= iMaxWDDur
                        tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("varfunetaccumfund", iterator, "LOW"));
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
                      matFundB = asDouble(quotationIO.group_valueAsOf("varfunetaccumfund", iFundMonthOriginal, "LOW"));#value of iFundMonth

                      dWD_Old = initialWithdrawalAmount #' Store current iteration's withdrawal value
                      initialWithdrawalAmount = MobiSys::Math.roundDown((dWD_Old - (iChg * (matFundA - smallestAllowableFund) / (matFundB - matFundA))), 2) #'Calculate next iteration's withdrawal value
                      
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
                      tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("varfunetaccumfund", iterator, "LOW"));
                      tfvgrouplowHash[iterator] = tfvGroupLowB
                      iterator = iterator + 1
                    end
                    minTfvgroupValue = tfvgrouplowHash.select {|k,v| v == tfvgrouplowHash.values.min }

                    earliestWithdrawMonthHash = {}
                    # iterator = iFundYear
                    minFunDTest = iFundYear #1
                    while minFunDTest <= iMaxWDDur
                      tfvGroupLowB = asDouble(quotationIO.group_valueAsOf("minfundtest", minFunDTest, "LOW"));
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
                 
                  if (minTfvgroupValue.values[0] < smallestAllowableFund) || (initialWithdrawalAmount.to_f < withdrawalAmount.to_f) #Then ' If the smallest withdrawal causes the fund to be less than the min fund at any duration
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
     

     def self.asDouble(value)
      return 0.0 if value.nil?

      if value.is_a?(Numeric)
        value.to_f
      else
        Float(value.to_s)
      end
      return value
    end
    def self.bisection_Method_NR(quotation, quotationIO, minWithdrawalAmt, maxWithdrawalAmt, i, originalIllustrationRateList)
      
      freqMultiplier = MobiSys::ProductUtil.getFrequencyMultiplier(quotationIO.illustrationModel.computationFrequencyCd)
      computationCycles = quotationIO.baseDO.getBasePlan.productTerm.to_i * freqMultiplier
      loopCounter = 1
      hmAddtnlEvalParams = {}
      hmAddtnlEvalParams["withdrawalmethod"] = "BS"
      quotationIO.addModelAdditionalParams('ADDITIONAL_EVAL_PARAMS', hmAddtnlEvalParams)


      begin
        isFundValueNeg=false
        avgWithdrawalAmt = (minWithdrawalAmt + maxWithdrawalAmt)/2.0;
        diffMinMaxWithdAmt = maxWithdrawalAmt - minWithdrawalAmt;
        withdrawalAmount = avgWithdrawalAmt;
        withdrawalAmount = MobiSys::Math.roundDown(withdrawalAmount, 2);

        quotationIO.baseDO.getBasePlan.ropPerc = withdrawalAmount
        quotationIO.illustrationModel.setIllustrationRateList originalIllustrationRateList

        quotationIO.listCalculation = []
        quotationIO.illustrationHeader = nil
        quotationIO.baseDO = quotation.cloneObject
        basePlanQuote = quotationIO.baseDO.getBasePlan
        basePlanQuote.ropPerc = withdrawalAmount
        loopCounter = loopCounter + 1
        #quotationIO.loopReference = "BS" + withdrawalAmount.to_s
        isFundValueNeg=false;
        
        quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
        calcListSize = quotationIO.computationCycles
        if calcListSize < computationCycles
          isFundValueNeg=true
        else
          fundBreakValue = asDouble(quotationIO.group_valueAsOf("fundbreak",computationCycles, "LOW"))
          fundBreak = (fundBreakValue!=nil ? fundBreakValue.to_s : 0.0)
          if fundBreak == "break"
            isFundValueNeg = true
          end
        end
        if isFundValueNeg
          maxWithdrawalAmt = avgWithdrawalAmt;
        else
          minWithdrawalAmt = avgWithdrawalAmt;
        end
        preAvgWithdrawalAmt = (minWithdrawalAmt + maxWithdrawalAmt)/2;

        
      end while (((MobiSys::Math.roundUp(diffMinMaxWithdAmt, 2)).abs > 0.01) || isFundValueNeg)# && preAvgWithdrawalAmt > minWithdrawalAmt )  #End do
      returnValue = quotationIO
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
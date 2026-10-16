# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationProduct
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
        
  # Uncomment the following line to enable sync with Label.
  # enable :sync

  #add model specific code here

  property :quotationProductSeq, :integer
  property :productSeq, :integer
  property :productId, :string
  property :productVersion, :integer
  property :productTypeCd, :string
  property :productFamilyCd, :string
  property :baseSumAssured, :float, :decimal
  property :baseAnnualPremium, :float, :decimal
  property :modalPremium, :float, :decimal
  property :productTerm, :integer
  property :premiumPayingTerm, :integer
  property :paymentTypeCd, :string
  property :paymentFrequencyCd, :string
  property :productPlanOptionCd, :string
  property :premiumSAFl, :string
  property :emr, :integer
  property :flatExtra, :integer
  property :planCode, :string
  property :selected, :string
  property :flatLoading, :integer
  property :flatLoadingDuration, :integer
  property :multipleLoading, :integer
  property :multipleLoadingDuration, :integer
  property :premiumDiscount, :integer
  property :premiumDiscountDuration, :integer
  property :currencyCd, :string
  property :ropIndicatorCd, :string
  property :ropInterestRate, :integer
  property :dividendOptionCd, :string
  property :enhancedProtectionOptionTDBTarget, :integer
  property :floorWithGuaranteedCashValueCd, :string
  property :capWithBasicPlanFACd, :string
  property :cashDropReinvest, :string
  property :terminalBonusReinvest, :string
  property :dividendOption, :string
  property :endowmentOption, :string
  property :pdfOption, :string
  property :pdfAmount, :float, :decimal
  property :oe, :integer    
  #property :versionId, :integer
  #property :guid, :string

  #newly added attributes
  property :multiplier, :float
  property :annuityAge, :integer
  property :annuityPerc, :float
  property :annuityOptionCd, :string
  property :veryLowReturnRate, :float
  property :lowReturnRate, :float
  property :mediumReturnRate, :float
  property :highReturnRate, :float
  property :veryHighReturnRate, :float
  property :partyRoleCd, :string
  property :portfolioModelCd, :string
  property :emrDuration, :integer
  property :occuExtra, :float
  property :occuExtraDuration, :integer
  property :nsapExtra, :integer
  property :nsapExtraDuration, :integer
  property :healthExtra, :integer
  property :healthExtraDuration, :integer
  property :monthlyIncome, :float, :decimal
  property :annualIncome, :float
  property :flatExtraDuration, :integer
  property :capturedPremiumAmt, :float, :decimal
  property :insuredPartyRefGuid, :string
  property :insuredPartyName, :string
  property :combinedEntryAge, :integer
  #property :discountPerc, :integer
  #property :discountDuration, :integer
  property :ropPerc, :float
  property :addtnField1, :string
  property :addtnField2, :string
  property :addtnField3, :string
  property :addtnField4, :string
  property :addtnField5, :string
  property :addtnField6, :string
  property :annualizedPremium, :float
  property :totAnnualizedPremium, :float
  property :educationCess, :float
  property :serviceTax, :float
  property :extraPremium, :float, :decimal
  property :totDiscount, :float
  property :wopPremium, :float
  property :maxTargetPremium, :float, :decimal
  property :minTargetPremium, :float, :decimal
  property :recommendedPremium, :float, :decimal
  property :unapliedPremium, :float, :decimal
  property :emrExtraPremium, :integer
  property :flatExtraPremium, :integer
  property :nsapExtraPremium, :integer
  property :occExtraPremium, :integer
  property :healthExtraPremium, :integer
  property :riderRegularPayProduct, :string
  property :coi, :float, :decimal

  #property :premiumHolidayFl  , :string
  #property :premiumHolidayYear, :integer
  #property :premiumOffsetFl, :string
  #property :premiumOffsetOptionCd, :string
  #property :premiumOffsetYear, :integer
  #property :premiumOffsetValues, :string

  #property :pdfRequiredFl, :string
  #property :pdfFrequencyVal, :integer
  #property :pdfPeriod, :integer
  #property :solverTypeCd, :string
  #property :targetFundFl, :string
  #property :payingYears, :integer
  #property :retirementOptionFl, :string
  #property :retirementPercent, :integer
  property :linkedFl, :string
  property :parentproductSeq, :integer

  # not synced
  property :illustrationRate, :integer
  property :premiumSplit, :integer
  property :premiumGuarantees, :integer
  property :computedmodalPremium, :float

  # online attributes
  property :productSetSeq, :string
  property :paidUpValue, :float
  property :productTermUnitCd, :string
  property :premiumPayingTermUnitCd, :string
  property :vestingAge, :integer
  property :singleLifeAllowed, :string
  property :riderType, :string
  property :saIndexationCd, :string
  property :premiumIndexationCd, :string
  property :fixedPrmIndexationVal, :float
  property :fixedSAIndexationVal, :float
  property :payoutFrequencyCd, :string
  property :systTransferOptionCd, :string
  property :pdfRequiredFl, :string
  property :tpdLoadingValue, :float
  property :ciLoadingValue, :float
  property :lifeLoadingValue, :float
  property :ciLoadingTerm, :integer
  property :tpdLoadingTerm, :integer
  property :lifeLoadingTerm, :integer
  property :premiumHolidayFl, :string
  property :premiumHolidayYear, :integer
  property :premiumOffsetFl, :string
  property :premiumOffsetOptionCd, :string
  property :premiumOffsetYear, :integer
  property :premiumOffsetValues, :string
  property :topUpAllocSameAsPremAllocFl, :string
  property :pdfFrequencyVal, :integer
  property :pdfPeriod, :integer
  property :solverTypeCd, :string
  property :targetFundFl, :string
  property :payingYears, :integer
  property :targetFundVal, :float, :decimal
  property :targetPeriodRefCd, :string
  property :targetPeriod, :integer
  property :retirementOptionFl, :string
  property :retirementPercent, :float
  property :compAnnualPremium, :float, :decimal
  property :compHalfYlyPremium, :float, :decimal
  property :compQtlyPremium, :float, :decimal
  property :compMonthlyPremium, :float, :decimal
  property :builtInRiderFl, :string
  property :sortOrder, :integer
  property :paidUpFl , :string
  property :wopPremium2, :float
  property :wopPremiumQuarterly, :float
  property :wopPremiumHalfYearly, :float
  property :wopPremiumMonthly, :float
  property :wopPremium2Quarterly, :float
  property :wopPremium2HalfYearly, :float
  property :wopPremium2Monthly, :float
  property :baseSumAssuredQuarterly, :float
  property :baseSumAssuredHalfYearly, :float
  property :baseSumAssuredMonthly, :float
  property :wopPremium3, :float
  property :wopPremium3Quarterly, :float
  property :wopPremium3HalfYearly, :float
  property :wopPremium3Monthly, :float
  #sanketnew filed added for wop rider task
  property :wopPremiumField, :float
  property :wopPremiumField2, :float
  property :wopPremiumField3, :float

  property :tripTypeCd, :string
  property :geographyCd, :string
  property :visitPurposeCd, :string
  property :maxTripPeriod, :integer
  property :visitedTabs, :string
  property :multiLifeField1, :string
  property :multiLifeField2, :string
  property :multiLifeField3, :string


  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :removed, :string

  #to hold matuirity age value
  attr_accessor :maturityAge
  attr_accessor :currentRate
  #to hold Respective Product Details
  attr_accessor :product
  attr_accessor :loadingTypeCd
  attr_accessor :topUpTypeCd
  attr_accessor :holderRefGuid
  attr_accessor :paymentMethodCd
  attr_accessor :fundCd
  attr_accessor :planCode
  attr_accessor :additionalData, :header, :html, :media, :icon, :footer
  attr_accessor :productLongName, :readOnlyFields, :insuredNames, :riderDisableField, :impactedFields, :applicablePlanOptions, :productPlanOptionDesc

      
  has_many 'QuotationProductInvestmentFund'
  has_many 'QuotationProductExtra'
  has_many 'QuotationProductAdditional'

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationProductDO"
  end
  
  #return the list of child classes whose context need to be evaluated along with this class.
  def contextExtendForClass
      return "QuotationProductAdditional"
  end
  def getPaymentFrequencyInMonths
    paymentFrequency = 0
    case paymentFrequencyCd
    when "YEARLY"
      paymentFrequency = 12
    when "MONTLY"
      paymentFrequency = 1
    when "HALFYEARLY"
      paymentFrequency = 6
    when "QUARTERLY"
      paymentFrequency = 3
    end
    return paymentFrequency
  end

  def getQuotationProductExta(extraTypeCd)
    qpe = nil
    self.QuotationProductExtraList.each do |quotationProductExtra|
      if quotationProductExtra.extraTypeCd == extraTypeCd
        qpe = quotationProductExtra
        break
      end    
    end
    return qpe
  end

  def getExtraQuotationProducts
    quotationProductExtra = []
    self.QuotationProductExtraList.each do |quotationProdExtra|
      quotationProductExtra.push(quotationProdExtra)
    end
    quotationProductExtra
  end

  def getExtraQuotationProduct(facetId)
    quotationProductExtra = nil
    self.QuotationProductExtraList.each do |quotationProdExtra|
      if quotationProdExtra.extraTypeCd == facetId
        quotationProductExtra = quotationProdExtra
      end
    end
    quotationProductExtra
  end
    
  def getDecisionCd(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.decisionCd if qpe
    return nil
  end

  def getLoadingTypeCd(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.loadingTypeCd if qpe
    return nil 
  end

  def getProcessingTypeCd(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.processingTypeCd if qpe
    return nil 
  end

  def getExtraFlatAmt(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.extraFlatAmt.to_f if qpe and qpe.extraFlatAmt and qpe.extraFlatAmt != ""
    return 0.0
  end

  def getExtraFlatDuration(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.extraFlatDuration.to_i if qpe and qpe.extraFlatDuration and qpe.extraFlatDuration != ""
    return 0
  end

  def getExtraPercent(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.extraPercent.to_f if qpe and qpe.extraPercent and qpe.extraPercent != ""
    return 0.0 
  end

  def getExtraPercDuration(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe.extraPercDuration.to_i if qpe and qpe.extraPercDuration and qpe.extraPercDuration != ""
    return 0
  end

  def discountFlatAmt()
    return getExtraFlatAmt("PRDDISCOUNT")
  end

  def discountFlatDuration()
    return getExtraFlatDuration("PRDDISCOUNT")
  end

  def discountPercent()
    return getExtraPercent("PRDDISCOUNT")
  end

  def discountPercDuration()
    return getExtraPercDuration("PRDDISCOUNT")
  end

  def getProduct
    product = MobiSys::ProductUtil.getProduct(self.productSeq)
    #Product.loadObject(:first, :conditions =>{{:name => 'productId'} => self.productId})
    return product
  end
 
  def getQuotationProduct(quotation, productId, roleCd='')
    listPolPrd = quotation.getRiders
    riderDO = nil
    thisParty = quotation.getMainInsured(self)
    listPolPrd.each do |polPrdRider|
      if productId == polPrdRider.productId
        loopRiderParty = quotation.getMainInsured(polPrdRider)
        if roleCd != ''
          if thisParty != nil && loopRiderParty != nil && (roleCd == loopRiderParty.roleCd)
            riderDO = polPrdRider
            break
          end
        else
          if thisParty != nil && loopRiderParty != nil && (thisParty.guid == loopRiderParty.guid)
            riderDO = polPrdRider
            break
          end
        end
      end
    end   
    if riderDO == nil
      riderDO = QuotationProduct.new
      riderDO.annualizedPremium = 0.0
      riderDO.baseAnnualPremium = 0.0
      riderDO.capturedPremiumAmt = 0.0
      riderDO.computedmodalPremium = 0.0
      riderDO.extraPremium = 0.0
      riderDO.modalPremium = 0.0
      riderDO.recommendedPremium = 0.0
      riderDO.serviceTax = 0.0
      riderDO.unapliedPremium = 0.0
      riderDO.wopPremium = 0.0
      riderDO.baseSumAssured = 0.0
      riderDO.productTerm = 0.0
      riderDO.premiumPayingTerm = 0.0
      riderDO.educationCess = 0.0
      riderDO.totAnnualizedPremium = 0.0
      riderDO.totDiscount = 0.0
      riderDO.coi = 0.0
    end
    return riderDO
  end

  def getPolicyProductAdditionalDO(quotation, productId)
  	quotationProductAdditional = nil
		quotationProduct = self.getQuotationProduct(quotation, productId)
		quotationProductAdditionalList = quotationProduct.QuotationProductAdditionalList
		if quotationProductAdditionalList && quotationProductAdditionalList.size > 0
			quotationProductAdditional = quotationProductAdditionalList[0]
		else
			quotationProductAdditional = QuotationProductAdditional.new
			quotationProduct.addQuotationProductAdditional(quotationProductAdditional)
		end
		return quotationProductAdditional
  end

  #For API
  def getProductPlanOptionDesc
    productPlanOptionDesc = self.productPlanOptionCd
    product = MobiSys::ProductUtil.getProduct(self.productSeq)
    planOptionFacet = product.getFacet('PLANOPTION')
    if planOptionFacet != nil
      planOptionFacet.OfflinePlanOptionList.each do |offlinePlan|
        productPlanOptionDesc = offlinePlan.description if(offlinePlan.optionCd != nil && self.productPlanOptionCd != nil && self.productPlanOptionCd == offlinePlan.optionCd)
      end
    end

    return productPlanOptionDesc
  end

  def getPolicyProductExtra(extraTypeCd)
    qpe = getQuotationProductExta(extraTypeCd)
    return qpe
  end

  ############
  def getPolicyProductForParty(quotation, productId, guid='')
      p "quotation quopro==========#{quotation}"
      listPolPrd = quotation.getNonBuiltInRiders
      p "listPolPrd==========#{listPolPrd}"
      riderDO = nil
      thisParty = quotation.getMainInsured(self)
      p "thisParty========#{thisParty}"
      listPolPrd.each do |polPrdRider|
          if productId == polPrdRider.productId
              loopRiderParty = quotation.getMainInsured(polPrdRider)
              if guid != ''
                  if thisParty != nil && loopRiderParty != nil && (guid == loopRiderParty.guid)
                      riderDO = polPrdRider
                      break
                  end
              else
                  if thisParty != nil && loopRiderParty != nil && (thisParty.guid == loopRiderParty.guid)
                      riderDO = polPrdRider
                      break
                  end
              end
          end
      end   
      if riderDO == nil
          riderDO = QuotationProduct.new
          riderDO.annualizedPremium = 0.0
          riderDO.baseAnnualPremium = 0.0
          riderDO.capturedPremiumAmt = 0.0
          riderDO.computedmodalPremium = 0.0
          riderDO.extraPremium = 0.0
          riderDO.modalPremium = 0.0
          riderDO.recommendedPremium = 0.0
          riderDO.serviceTax = 0.0
          riderDO.unapliedPremium = 0.0
          riderDO.wopPremium = 0.0
          riderDO.baseSumAssured = 0.0
          riderDO.productTerm = 0.0
          riderDO.premiumPayingTerm = 0.0
          riderDO.totAnnualizedPremium = 0.0
          riderDO.coi = 0.0
      end
      return riderDO
  end
  
  ############ow 
end

begin 
    require 'QuotationProduct/quotation_product_company'
rescue LoadError => e
    puts 'quotation_product_company not included'
end 
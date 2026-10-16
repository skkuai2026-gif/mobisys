# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PolicyProduct
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.1'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################     
    property :productSeq, :integer
    property :productId, :string
    property :productVersion, :integer
    property :productTypeCd, :string
    property :productFamilyCd, :string
    property :baseSumAssured, :float, :decimal
    property :baseAnnualPremium, :float, :decimal
    property :modalPremium, :float, :decimal
    property :extraPremium, :float, :decimal
    property :discount, :float
    property :productTerm, :integer
    property :productTermUnitCd, :string
    property :premiumPayingTerm, :integer
    property :premiumPayingTermUnitCd, :string
    property :combinedEntryAge, :integer
    property :riskCommencementDt, :date
    property :productCommencementDt, :date 
    property :computedmodalPremium, :float
    property :portfolioModelCd, :string 
    property :vestingAge, :integer 
    property :riderType, :string 
    property :paymentTypeCd, :string
    property :paymentFrequencyCd, :string
    property :productPlanOptionCd, :string 
    property :planCode, :string
    property :premiumSAFl, :string
    property :selected, :string
    property :currencyCd, :string
    property :capturedPremiumAmt, :float, :decimal
    property :maxTargetPremium, :integer, :decimal
    property :minTargetPremium, :integer, :decimal
    property :recommendedPremium, :integer, :decimal
    property :unapliedPremium, :float, :decimal   
    property :insuredPartyRefGuid, :string
    property :topupFrequencyVal, :integer
    property :coi, :integer, :decimal
    property :addtnField3, :string
    property :pdfFl, :integer
    property :serviceTax, :string
    property :pdfRequiredFl, :boolean
    property :monthlyIncome, :float
    property :annualIncome, :float
    property :sortOrder, :integer


    #sanket new filed added for wop rider task
    property :wopPremiumField, :float
    property :wopPremiumField2, :float
    property :wopPremiumField3, :float
    property :ropPerc, :float, :decimal

    
    property :addtnField1, :string
    property :addtnField2, :string
    property :addtnField4, :string
    property :addtnField5, :string
    property :addtnField6, :string
    property :annualizedPremium, :float
    property :annuityAge, :integer
    property :annuityOptionCd, :string
    property :annuityPerc, :float
    property :builtInRiderFl, :string
    property :defermentPeriod, :integer
    property :defermentPeriodUnitCd, :string
    property :highReturnRate, :float
    property :linkedFl, :string
    property :mediumReturnRate, :float
    property :payingYears, :integer
    property :payoutFrequencyCd, :string
    property :pdfAmount, :float
    property :pdfFrequencyVal, :integer
    property :pdfPeriod, :integer
    property :premiumHolidayFl, :string
    property :premiumHolidayYear, :integer
    property :premiumOffsetFl, :string
    property :premiumOffsetOptionCd, :string
    property :premiumOffsetValues, :string
    property :premiumOffsetYear, :integer
    property :productSetSeq, :integer
    property :retirementOptionFl, :string
    property :retirementPercent, :float
    property :solverTypeCd, :string
    property :targetFundFl, :string
    property :targetFundVal, :float
    property :targetPeriod, :integer
    property :targetPeriodRefCd, :string
    property :topUpAllocSameAsPremAllocFl, :string
    property :totAnnualizedPremium, :float
    property :uwClassCd, :string
    property :decisionCd, :string
    property :veryHighReturnRate, :float
    property :veryLowReturnRate, :float
    property :wopPremium, :float
    property :wopPremium2, :float
    # property :isWOP, :boolean
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
    property :parentproductSeq, :integer
    property :partyRoleCd, :string
    property :tripTypeCd, :string
    property :geographyCd, :string
    property :visitPurposeCd, :string
    property :maxTripPeriod, :integer
    property :fixedPrmIndexationVal, :float
    property :visitedTabs, :string
    property :paidUpFl, :string
    property :compAnnualPremium, :float, :decimal
    property :compHalfYlyPremium, :float, :decimal
    property :compQtlyPremium, :float, :decimal
    property :compMonthlyPremium, :float, :decimal
    property :multiLifeField1, :string
    property :multiLifeField2, :string
    property :multiLifeField3, :string

    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string

    #to hold Respective Product Details
    attr_accessor :product, :productLongName, :readOnlyFields, :insuredNames, :riderDisableField, :impactedFields, :applicablePlanOptions, :topUpTypeCd,:productPlanOptionDesc
    attr_accessor :insuredPartyName, :holderRefGuid
    has_many 'PolicyProductInvestmentFund'
    has_many 'PolicyProductInsured'
    has_many 'PolicyProductExtra'
    has_many 'PolicyProductAdditional'
    

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO"
    end

     #return the list of child classes whose context need to be evaluated along with this class.
    def contextExtendForClass
        return "PolicyProductAdditional"
    end

    def getProduct
        @product ||= MobiSys::ProductUtil.getProduct(self.productSeq)
    end

    def getFunds
        funds = []
        funds = self.PolicyProductInvestmentFundList if self.productTypeCd == "PLAN"
    end

    def getPolicyProductExtra(extraTypeCd)
        policyProductExtra = nil
        self.PolicyProductExtraList.each do |policyProductExtraDO|
            if policyProductExtraDO.extraTypeCd == extraTypeCd
                policyProductExtra = policyProductExtraDO
                break
            end
        end
        return policyProductExtra
    end

    def getExtraPercent(extraTypeCd)
        qpe = getPolicyProductExtra(extraTypeCd)
        return qpe.extraPercent.to_f if qpe && qpe.extraPercent.to_s != ""
        return 0.0
    end

    def getDecisionCd(extraTypeCd)
        qpe = getPolicyProductExtra(extraTypeCd)
        return qpe.decisionCd.to_s if qpe && qpe.decisionCd.to_s != ""
        return ""
    end

    def getExtraTypeCd(extraTypeCd)
        qpe = getPolicyProductExtra(extraTypeCd)
        return qpe.extraTypeCd.to_s if qpe && qpe.extraTypeCd.to_s != ""
        return ""
    end

    def getPolicyProduct(policy, productId, roleCd='')
        listPolPrd = policy.getNonBuiltInRiders
        riderDO = nil
        thisParty = policy.getMainInsured(self)
        listPolPrd.each do |polPrdRider|
            if productId == polPrdRider.productId
                loopRiderParty = policy.getMainInsured(polPrdRider)
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
            riderDO = PolicyProduct.new
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

        def getPolicyProductForParty(policy, productId, guid='')
        listPolPrd = policy.getNonBuiltInRiders
        riderDO = nil
        thisParty = policy.getMainInsured(self)
        listPolPrd.each do |polPrdRider|
            if productId == polPrdRider.productId
                loopRiderParty = policy.getMainInsured(polPrdRider)
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
            riderDO = PolicyProduct.new
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
    
    def getListPolicyProductInvestmentFundList
        return  self.PolicyProductInvestmentFundList 
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
end

begin 
    require 'PolicyProduct/policy_product_company'
rescue LoadError => e
    puts 'policy_product_company not included'
end
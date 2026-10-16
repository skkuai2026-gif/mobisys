# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'

class ProductDefinitionTable
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
    
  # Uncomment the following line to enable sync with ProductDefinitionTable.
  # enable :sync

  #add model specifc code here
  
  property :prdCompanyCd, :integer
  property :definitionTableSeq, :integer
  property :tableTypeMappingSeq, :integer
  property :entryAgeFrom, :integer
  property :entryAgeTo, :integer
  property :entryAge, :integer
  property :termFrom, :integer
  property :termTo, :integer
  property :term, :string
  property :premiumFrom, :float
  property :premiumTo, :float
  property :premium, :float
  property :saFrom, :float
  property :saTo, :float
  property :sa, :float
  property :genderCd, :string
  property :planOptionCd, :string
  property :isSubStandardFl, :string
  property :ppTermFrom, :integer
  property :ppTermTo, :integer
  property :ppTerm, :string
  property :vestingAgeFrom, :integer
  property :vestingAgeTo, :integer
  property :vestingAge, :integer
  property :paymentFrequencyCd, :string
  property :paymentMethodCd, :string
  property :paymentInstructionTypeCd, :string
  property :paymentTypeCd, :string
  property :rate, :float
  property :sarFrom, :float
  property :sarTo, :float
  property :documentCategoryCd, :string
  property :premiumIndexationCd, :string
  property :planProductCd, :string
  property :ruleName, :string
  property :planCd, :string
  property :annualPremiumFrom, :float
  property :annualPremiumTo, :float
  property :annualPremium, :float
  property :baseProductFamilyCd, :string
  property :policyYearFrom, :integer
  property :policyYearTo, :integer
  property :policyYear, :integer
  property :attainedAgeFrom, :integer
  property :attainedAgeTo, :integer
  property :attainedAge, :integer
  property :illustrationRateFrom, :float
  property :illustrationRateTo, :float
  property :illustrationRate, :float
  #property :grossIllustrationRateFrom, :float
  #property :grossIllustrationRateTo, :float
  #property :grossIllustrationRate, :float
  #property :monthlyIllustrationRateFrom, :float
  #property :monthlyIllustrationRateTo, :float
  #property :monthlyIllustrationRate, :float
  property :occupationClass, :string
  property :roomType, :string
  property :smoker, :string
  property :termsConditions, :string
  property :sortOrder, :integer
  property :allowedOccupations, :string
  property :basisCd, :string
  property :benefitAmount, :float
  property :benefitTypeCd, :string
  property :benefitLabelCd, :string
  property :messageCd, :string
  property :fieldCd, :string
  property :partyRoleCd, :string
  property :collateralCd, :string
  property :dataStyle, :string
  property :dataVariable, :string
  property :fixedTermValues, :string
  property :associationRelationCd, :string
  property :coverTypeCd, :string
  property :allowedRelations, :string
  property :fixedPPTermValues, :string
  property :fundCd, :string
  property :fixedMultiplier, :string
  property :limitedPPTFl, :string
  property :outputAction, :string
  property :questionSetCd, :string
  property :jointLifeAge, :integer
  property :jointLifeAgeFrom, :integer
  property :jointLifeAgeTo, :integer
  property :loadingTypeCd, :string
  property :minValue, :BLOB
  property :maxValue, :BLOB
  property :computedField, :string
  property :computedFieldFrom, :float
  property :computedFieldTo, :float
  property :currencyCd, :string
  property :roleCd, :string
  property :relationCd, :string
  property :channelId, :string
  property :subChannelId, :string
  property :intimationSourceCd, :string
  property :riderProductId, :string
  property :parentAgencyId, :string
  property :industryCd, :string
  property :natureOfDutyId, :string
  property :financialSar, :float
  property :financialSarFrom, :float
  property :financialSarTo, :float
  property :totModalExtraPremium, :float
  property :totModalExtraPremiumFrom, :float
  property :totModalExtraPremiumTo, :float
  property :topUpTypeCd, :string
  property :citizenshipCd, :string
  property :cityCd, :string
  property :countryCd, :string
  property :partyTypeCd, :string
  property :maxValueUnits, :string
  property :minValueUnits, :string
  property :fixedValue, :float
  property :loadingDecisionCd, :string
  property :flatLoadingAmt, :float
  property :loadingPercent, :float
  property :multipleFactor, :float
  property :addtnField1, :string
  property :addtnField2, :string
  property :addtnField3, :string
  property :processingTypeCd, :string
  property :extraTypeCd, :string
  property :portfolioModelCd, :string
  property :minValueExpression, :string
  property :maxValueExpression, :string
  property :minValueExpresDisplay, :string
  property :maxValueExpresDisplay, :string
  property :proposerAge, :integer
  property :proposerAgeFrom, :integer
  property :proposerAgeTo, :integer
  property :primaryAge, :integer
  property :primaryAgeFrom, :integer
  property :primaryAgeTo, :integer
  property :quotAddtnlField1, :string
  property :quotAddtnlField2, :string
  property :quotAddtnlField3, :string
  property :quotAddtnlField4, :string
  property :indexKey, :string

  property :monthlyIncome, :float
  property :annualIncome, :float
  property :monthlyIncomeFrom, :float
  property :annualIncomeFrom, :float
  property :monthlyIncomeTo, :float
  property :annualIncomeTo, :float
  property :quotPartyAddtnField1, :string
  property :quotPartyAddtnField2, :string
  property :quotPartyAddtnField3, :string
  property :quotPartyAddtnField4, :string
  property :maritalStatusCd, :string
  property :riderPlanOptions, :string
  property :riderProductIdNotIn, :string
  property :dependentRiderRoleCd, :string
  property :insuranceTypeCd, :string

  # Dynamic DT columns
  property :dtCondition1d, :float
  property :dtCondition11d, :float
  property :dtCondition2d, :float
  property :dtCondition22d, :float
  property :dtCondition3d, :float
  property :dtCondition33d, :float
  property :dtCondition4str, :string
  property :dtCondition5str, :string
  property :dtCondition6str, :string
  property :dtCondition7str, :string
  property :dtCondition8d, :float
  property :dtCondition9d, :float
  property :dtCondition13dt, :date
  property :dtCondition14dt, :date

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  index :PDT_TableTypeMappingSeq, [:tableTypeMappingSeq]
  index :PDT_ttms_indexkey, [:tableTypeMappingSeq,:indexKey]
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.ProductDefinitionTableDO"
  end
  
  def afterSync
    #puts "After sync ProductDefinitionTableDO called..."
  end

  def getValue
    value = nil
    if rate.to_s != ""
      value = rate.to_f
    elsif outputAction and outputAction != ""
      value = outputAction
    else
      value = 0.0  
    end
    return value
  end
  
end

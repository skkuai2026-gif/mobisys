# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflinePremiumDetails
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  
  # Uncomment the following line to enable sync with PremiumDetails.
  # enable :sync

  #add model specifc code here
  property :facetSeq, :integer
  property :paymentFrequencyCd, :string
  property :paymentMethodCd, :string
  property :premiumTypeCd, :string
  property :premiumSAFl, :string
  property :units, :integer
  property :serviceTaxRate, :float
  property :eduCessRate, :float
  property :policyPrmRelationType, :string
  property :relationValue, :string
  property :loadingDefaultValue, :string
  property :currencyCd, :string
  property :pptFixedValues, :string
  property :termfixedValues, :string
  property :multiplierfixedValues, :string
  property :premiumModelCd, :string
  property :saModelCd, :string
  property :termModelCd, :string
  property :inputDataElement, :string
  property :allowedCardType, :string  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  index :opd_parentKey, [:parentKey]
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.PremiumDetailsDO"
  end
end

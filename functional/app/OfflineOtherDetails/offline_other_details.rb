# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineOtherDetails
  include MobiSys::MobiSysFixedSchema
    
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with OtherDetails.
  # enable :sync

  #add model specifc code here
  property :facetSeq, :integer
  property :allowedOccupations, :string
  property :policyCommencementOptionCd, :string
  property :isWOPFl, :string
  property :minTotalRiderPremiumPercent, :float
  property :maxTotalRiderPremiumPercent, :float
  property :proposalFormType, :string
  property :illustrationFormat, :string
  property :roundingRule, :string
  property :planCdDerivationRuleSeq, :integer
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  index :ood_parentKey, [:parentKey]
    
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.OtherDetailsDO"
  end
end

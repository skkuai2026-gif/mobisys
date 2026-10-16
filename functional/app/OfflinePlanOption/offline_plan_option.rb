# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflinePlanOption
  include MobiSys::MobiSysFixedSchema
    
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with PlanOption.
  # enable :sync

  #add model specifc code here
  property :facetSeq, :integer
  property :optionCd, :string
  property :description, :string
  property :defaultSumAssured, :float
  property :levelNum, :integer
  property :sortOrder, :integer
  property :planOptionAddtnlFld1, :string
  property :collateralLevelCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  index :opo_parentKey, [:parentKey]

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.PlanOptionDO"
  end
end

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineJointLife
  include MobiSys::MobiSysFixedSchema
    
    set :schema_version, '1.0'
    set :partition, :master
  
    # Uncomment the following line to enable sync with JointLife.
    # enable :sync
  
    #add model specifc code here
    property :facetSeq, :integer
    property :ageCalculationBasisCd, :string
    property :jointAgeCalculationCd, :string
    property :minimumAgeDiffWithLAFl, :string
    property :ageDifference, :integer
    
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    index :ojl_parentKey, [:parentKey]
  
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.JointLifeDO"
    end
end

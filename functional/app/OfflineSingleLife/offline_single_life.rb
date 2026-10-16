# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineSingleLife
  include MobiSys::MobiSysFixedSchema
      
    set :schema_version, '1.0'
    set :partition, :master
  
    # Uncomment the following line to enable sync with SingleLife.
    # enable :sync
  
    #add model specifc code here
    property :facetSeq, :integer
    property :genderApplicabilityCd, :string
    property :ageCalculationBasisCd, :string
    property :noOfAdultDependants, :string
    property :noOfChildDependants, :string
    property :noOfLives, :integer
    property :proposerLADifferent, :string  
    
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    index :osl_parentKey, [:parentKey]
  
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.SingleLifeDO"
    end
end

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class ModelFund
  include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master

    # Uncomment the following line to enable sync with Product.
    # enable :sync
  
    #add model specifc code here
  
    property :fundCd,           :string
    property :allocationPerc,   :integer
    property :minFundAllocPerc, :integer
    property :maxFundAllocPerc, :integer
    property :multipleFactor, :float
    property :subModelCd,       :string
    property :sortOrder,       :integer
    
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ModelFundDO"
    end
    
    def afterSync
      #puts "After sync ModelFundDO called..."
    end
      

end

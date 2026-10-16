# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Fund
  include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master  

    # Uncomment the following line to enable sync with Product.
    # enable :sync
  
    #add model specifc code here
  
    property :fundSeq,          :integer 
    property :fundCd,           :string
    property :fundDesc,         :string
    property :assetClass,       :string
    property :issueDt,          :date
    property :fundManagementCharges,  :integer
    property :fmcST,            :integer
    property :expiryDt, :date
    property :fundTypeCd, :string
    property :maturityDt, :date
    property :sortOrder, :integer
    property :collateralLevelCd, :string
    property :addtnlFld1Str, :string
    property :addtnlFld2Str, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.FundDO"
    end
    
    def afterSync
      #puts "After sync FundDO called..."
    end
      

end

require "CommonModules/schema_module"

class FNAProduct
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
        
    # Uncomment the following line to enable sync with FNAProduct_M.
    # enable :sync
  
    #add model specifc code here
    property :productId, :string
    property :productVersion, :integer
    property :versionName, :string
    property :longName, :string
    property :shortName, :string
    property :description, :string
    property :productTypeCd, :string
    property :productFamilyId, :string
    property :productStatusCd, :string
    property :launchDt, :date
    property :withdrawDt, :date
    property :sortOrder, :integer
    property :productTerm, :string
    property :ppt, :string
    property :productGroupName, :string
    property :naBenefitTerm, :string

    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :String

    has_many 'FNARiderMapping'
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAProductDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for FNAProduct"   
    end 
end

begin
    require 'FNAProduct/f_n_a_product_company'
rescue LoadError => e
    puts 'f_n_a_product_company not included'
end
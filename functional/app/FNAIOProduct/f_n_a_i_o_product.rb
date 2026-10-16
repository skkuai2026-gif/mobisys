# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAIOProduct
 
	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAIOProduct.
  # enable :sync

  #add model specifc code here
  property  :fnaIONeedRefGuid, :string
  property  :fnaProductRefGuid, :string
  property  :fnaRequestRefGuid, :string
  property  :introducedFl, :string
  property  :productTypeCd, :string
  property  :productRecommended, :string
  property  :productIntroduced, :string
  property  :removed, :string
 
	
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
	
  #attr_accessor :entityDesc

  #Ashwini: 07-06-2017: To select the the product on Product Introduction Page.
  def get_check_box_value(io_product_obj, io_product_guid)
          if io_product_obj.productIntroduced != nil && io_product_obj.productIntroduced.include?(io_product_guid)
        product_check = "on"
      end
        
      return product_check
  end
 

  def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAIOProductDO"
  end
  
end

begin 
	require 'FNAIOProduct/f_n_a_io_product_company'
rescue LoadError => e
	puts 'f_n_a_io_product_company not included'
end 

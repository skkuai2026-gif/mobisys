# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class ProductFiltering
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
    
  # Uncomment the following line to enable sync with ProductFiltering.
  # enable :sync

  #add model specifc code here
  property :entryAgeFrom,         :integer
  property :entryAgeTo,           :integer
  property :genderCd,             :string
  property :occupationClass,      :string
  property :productTypeCd,        :string
  property :planType,             :string
  property :productId,            :string
  property :productVersion,       :string
  property :planCode,             :string
  property :sortOrder,            :integer
  property :riderProductId,       :string
  property :riderProductVersion,  :string
  property :riderPlanCode,        :string
  property :smokerStatus,         :string
  property :minUnit,              :string
  property :maxUnit,              :string
  property :roleCd,               :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ProductFilteringDO"
  end
  
  def afterSync
    #puts "After sync ProductDO called..."
  end
    

end


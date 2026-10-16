# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineProductModelMap
  include MobiSys::MobiSysFixedSchema
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with FacetDetails.
  # enable :sync

  #add model specifc code here
  property :modelCd, :string
  property :currencyCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ProductModelMapDO"
  end

  def getModel
    @model ||= Model.find(:first,:conditions => {'modelCd'=>modelCd})
  end
end

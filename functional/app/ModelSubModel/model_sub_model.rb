# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class ModelSubModel
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with ModelSubModel.
  # enable :sync

  #add model specifc code here
  property :subModelCd, :string
  property :minFundAllocPerc, :float
  property :maxFundAllocPerc, :float
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ModelSubModelDO"
  end
end

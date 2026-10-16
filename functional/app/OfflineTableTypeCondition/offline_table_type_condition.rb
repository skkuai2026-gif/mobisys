# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineTableTypeCondition
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
    
  property :tableTypeMappingSeq, :integer
  property :condition, :string
  property :rangeValueFl, :string
  property :cacheCondition, :string
  property :sortOrderForKey, :string
  property :dtColumnNames, :string
  property :entityDataTypeCd, :string
  property :fixedDynamicCondTypeCd, :string
  property :modelCd, :string
    
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineTableTypeConditionDO"
  end

end

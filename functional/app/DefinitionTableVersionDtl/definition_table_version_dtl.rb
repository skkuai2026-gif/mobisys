# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class DefinitionTableVersionDtl
  include MobiSys::MobiSysFixedSchema
      
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with DefinitiontTableVersionDtl.
  # enable :sync

  #add model specifc code here
  property :tableTypeMappingSeq, :string
  property :effectiveFromDt, :time
  property :effectiveToDt, :time
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.DefinitionTableVersionDtlDO"
  end
end

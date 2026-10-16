# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module' 
class FieldTargetValueMap
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  set :partition, :master
  
  property :mappingKey, :string
  property :drivingField, :string
  property :targetField, :string
  property :drivingValue, :string
  property :targetValue, :string
  property :targetLookupCd, :string
  property :companyCd, :string


  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time


  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.FieldTargetValueMapDO"
  end
  
  def self.entitiesForSync
  end
  
  def afterSync
    puts "After sync called FieldTargetValueMap"
  end 

end
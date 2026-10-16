# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class SyncEntity
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  set :partition, :master
  
  property :entityName, :string
  property :entityType, :string
  #property :enabled, :boolean
  property :entitySubCategory, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

end
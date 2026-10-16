# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class SyncCategory
  include MobiSys::MobiSysFixedSchema
  
  set :partition, :master

  property :categoryCd, :string
  property :subCategoryCd, :string
  property :enabled, :boolean

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

end

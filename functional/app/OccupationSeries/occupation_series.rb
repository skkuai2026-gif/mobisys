# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OccupationSeries
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
    
  property :occupationSeriesId, :string
  property :occupationSeriesCd, :string
  property :occupationSeriesDesc, :string
  property :fromDt, :date
  property :toDt, :date
 
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
end

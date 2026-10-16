# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Occupation
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  property :occupationId, :string
  property :occupationGroupCd, :string
  property :occupationName, :string
  property :occupationClass, :string
  property :occupationTypeCd, :string
  property :occupationRate, :string
  property :occupationNotForSale, :integer
  property :occupationsortOrder, :integer
  property :occClassForAddPI, :string
  property :derivedOccupationClass, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
end

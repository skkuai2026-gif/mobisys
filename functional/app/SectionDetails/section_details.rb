# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class SectionDetails
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  
  property :elementType, :string
  property :elementName, :string
  property :language, :string
  property :displayOrder, :float
  property :property1, :string
  property :includeTD, :string
  property :onlyType, :string
  property :parentTableElementName, :string
  property :label1Ruby, :string
  property :label2Ruby, :string
  property :mvelConditionRuby, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.SectionDetailsDO"
  end
  
end
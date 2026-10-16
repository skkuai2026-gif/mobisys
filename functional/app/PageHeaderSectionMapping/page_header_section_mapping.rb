# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class PageHeaderSectionMapping
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  
  property :pageHeaderSeq, :integer
  property :pageSectionSeq, :integer
  property :displayOrder, :integer
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :pageSectionSeq, :string
  property :mvelConditionRuby, :string

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.PageHeaderSectionMappingDO"
  end
  
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class TemplatePageMapping
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  
  property :templateMasterSeq, :integer
  property :pageHeaderSeq, :integer
  property :displayOrder, :float
  property :rider, :string
  property :currency, :string
  property :fund, :string
  property :productPlanOptionCd, :string
  property :mvelConditionRuby, :string
  property :pageName, :string
  property :isAPOFl, :string
  property :groupCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.TemplatePageMappingDO"
  end
  
end
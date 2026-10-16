# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OutputContext
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  
  property :templateMasterSeq, :integer
  property :productFamily, :string
  property :product, :string
  property :productVersion, :string
  property :rider, :string
  property :currency, :string
  property :fund, :string
  property :isDefaultFl, :string
  property :companyCd, :string
  property :entityTypeCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.OutputContextDO"
  end
  
end

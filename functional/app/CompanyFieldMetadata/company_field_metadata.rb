# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class CompanyFieldMetadata
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with CompanyFieldMetadata.
  # enable :sync
  set :schema_version, '1.0'
  set :partition, :master

  property :inputMetadataCd, :string
  property :inputSource, :string
  property :inputElementName, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  #add model specific code here

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.CompanyFieldMetadataDO"
  end

end

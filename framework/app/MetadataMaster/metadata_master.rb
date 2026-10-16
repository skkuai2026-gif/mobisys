# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class MetadataMaster
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with Contet.
  # enable :sync
  set :schema_version, '1.0'
  set :partition, :master

  property :fieldTypeCd, :string
  property :metaDataCd, :string
  property :objectName, :string
  property :attributeCd, :string
  property :metaDataTypeCd, :string
  property :runtimeDrivingMTDT, :string

  # derived attributes
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  #add model specific code here

  has_many 'UiMetaDataProperty'
  has_many 'ValidationMetadata'
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.MetaDataDO"
  end

  def afterSync
    # puts "+++After sync called for modelcd #{self.className}.#{self.fieldName}"
  end
end

require 'CommonModules/entityschema'

class DocumentCategoryContainer
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with Image.
  # enable :sync

  #add model specifc code here
  property :docCategoryCd, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  attr_accessor :docPartyGuid
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.DocumentCategoryContainerDO"
  end

end

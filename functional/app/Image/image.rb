# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Image
  include MobiSys::MobiSysEntitySchema

  # Uncomment the following line to enable sync with Image.
  # enable :sync

  #add model specifc code here
  
  property :dateTimeTaken, :time
  property :latitude, :string
  property :longitude, :string
  property :parentRefGuid, :string
  property :uploadStatus, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  attr_accessor :removed
  has_many 'OfflineFile'
  
  def afterSync
    self.uploadStatus = 'DONE'
    self.persistAll 
  end
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.mobisys.ImageDO"
  end  
end
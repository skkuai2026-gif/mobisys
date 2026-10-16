# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class OfflineFile
  include MobiSys::MobiSysEntitySchema

  # Uncomment the following line to enable sync with OfflineFile.
  # enable :sync

  #add model specifc code here
  property :fileLocation, :string
  property :md5Hash, :string
  property :fileContents, :string
  property :fileEncrypted, :string
  property :encryptionIv, :string
  property :ocrExtractedText, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  attr_accessor :removed
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.mobisys.OfflineFileDO"
  end
end

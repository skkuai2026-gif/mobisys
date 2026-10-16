# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class DocumentImage
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

  property :fileLocation, :string
  property :fileContents, :string
  property :md5Hash, :string
  property :fileEncrypted, :string
  property :encryptionIv, :string
  property :ocrExtractedText, :string
  property :removed, :string
  
  def afterSync
    self.uploadStatus = 'DONE'
    self.persistAll 
  end
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.mobisys.DocumentImageDO"
  end

  def self.getDocumentImages(serviceDocGuid)
    documentImages = []
    images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDocGuid})
    images.each do |img|
      offlineFile = img.OfflineFileList[0]
      if offlineFile.fileEncrypted.to_s == 'YES'
        decodedContent = MobiSys::Encryption.decryptContent("#{offlineFile.fileContents}|#{offlineFile.encryptionIv}")
        imageBase64 = MobiSys::Encryption.encodeContents(decodedContent)
      else
        imageBase64 = offlineFile.fileContents
      end
       
      docImage = DocumentImage.new 
      docImage.dateTimeTaken      = img.dateTimeTaken
      docImage.latitude           = img.latitude
      docImage.longitude          = img.longitude
      docImage.parentRefGuid      = img.parentRefGuid
      docImage.fileLocation       = offlineFile.fileLocation
      docImage.fileContents       = imageBase64
      docImage.fileEncrypted      = offlineFile.fileEncrypted
      docImage.encryptionIv       = offlineFile.encryptionIv
      docImage.md5Hash            = offlineFile.md5Hash
      docImage.ocrExtractedText   = offlineFile.ocrExtractedText
      docImage.object             = img.object
      docImage.guid               = img.guid
      documentImages.push(docImage)
    end

    return documentImages
  end
end
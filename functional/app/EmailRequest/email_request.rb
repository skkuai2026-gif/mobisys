# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here

require 'CommonModules/entityschema'

class EmailRequest
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with EmailRequest.
  # enable :sync

  #add model specifc code here
  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  property :entityName, :string
  property :entityGuid, :string
  property :entityNumber, :string
  property :toEmail, :string
  property :ccEmail, :string
  property :message, :string
  property :emailReqStatusCd, :string
  property :outputPrefEntityGuid, :string
  

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.EmailRequestDO"
  end

  def self.entitiesForSync
     entitiesForSync = EmailRequest.loadObject(:all,:conditions=>{
                                                              {
                                                                :name=>'emailReqStatusCd',
                                                                :op => 'IS NOT'
                                                              }=> 'SYNCDONE'
                                                              })
     return entitiesForSync
  end
  
  def afterSync
    puts "After sync called for EmailRequest "
    #Deleting generated json files
    if $rhoconfig[:offlineOutputGeneration]
      fileName = "#{self.entityName}_#{self.entityNumber}_#{self.outputPrefEntityGuid}.json"
      filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
      if File.exist?(filePath)
        FileUtils.rm_r filePath
      end
    end
    self.emailReqStatusCd = "SYNCDONE"
    self.persistAll
  end
end

begin 
    require 'EmailRequest/email_request_company'
rescue LoadError => e
    puts 'email_request_company not included'
end
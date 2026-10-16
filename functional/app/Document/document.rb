# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'

class Document
  include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master  
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :documentSeq, :int
    property :documentCd, :string
    property :questionSetCd, :string
    property :documentDesc, :string
    property :caseTemplateSeq, :int
    property :captureAdditionalInfoFl, :string
    property :remarks, :string
    property :documentMasterStatusCd, :string
    property :ocrIdentifier, :string
    property :ocrPriority, :integer
  

    # derived attributes  
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'DocumentProperty'

    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.DocumentDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for document"
   
    end 
end
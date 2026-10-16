# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class ServiceQuestionResponse
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.1'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :questionSetCd, :int
    property :questionDataElementCd, :string
    property :documentCd, :string
    property :questionnaireTypeCd, :string
    property :entityGuid, :string
    property :partyGuid, :string
    property :rowGuid, :string
    property :responseValue, :string
    property :score, :string
    property :weight, :string
    property :parentQuestionSeq, :string
    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :visitedTabs, :string
    property :removed, :String
     property :parentReferencePath, :string 
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.ServiceQuestionResponseDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for servicequestionresponse"   
    end 
end

begin
    require 'ServiceQuestionResponse/service_question_response_company'
rescue LoadError => e
    puts 'service_question_response_company not included'
end
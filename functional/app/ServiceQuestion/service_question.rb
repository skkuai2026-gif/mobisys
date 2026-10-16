# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class ServiceQuestion
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :serviceQuestionSeq, :int
    property :referenceObject, :string
    property :questionSetCd, :string
    property :questionCd, :string
    property :dataElementCd, :string
    property :response, :string
    
    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.ServiceQuestionDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for servicequestion"   
    end 
end

begin 
    require 'ServiceQuestion/service_question_company'
rescue LoadError => e
    puts 'service_question_company not included'
end
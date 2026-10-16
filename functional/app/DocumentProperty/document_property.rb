# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'

class DocumentProperty
  include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master  
        
    # Uncomment the following line to enable sync with DocumentProperty.
    # enable :sync
  
    #add model specifc code here
    property :ocrPrePopulationMetadata, :string
    property :attributeRegex, :string
    property :priority, :integer
    property :lookupValues, :string
    property :ocrValidationMetadata, :string

    # derived attributes  
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.DocumentPropertyDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for document property"
   
    end 
end
require "CommonModules/schema_module"

class ValidationMetadata
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :conditionCd, :string
    property :contextCd, :string
    property :exceptionCd, :string
    property :validationCd, :string
    property :validationParam, :string
    property :validationTypeCd, :string
    property :overridable, :string
    property :deferrable, :string
    property :disabled, :string
    property :metaDataCd, :string
    property :chaseTemplateCd, :string
    property :requiredAtStageCd, :string
    property :externalReqmtCd, :string
    property :propertyFields, :string
    property :tabId, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :evaluatedTabId
    
  	def self.onlineClassName
    	return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.ValidationMetaDataDO"
  	end
             
  	def self.entitiesForSync
  	end
             
  	def afterSync
    	puts "After sync called ValidationMetaDataDO"
  	end 
    
end
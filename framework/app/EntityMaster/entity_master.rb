require "CommonModules/schema_module"

class EntityMaster
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :entityTypeCd, :string
    property :restXmlHierarchy, :string
    property :restJsonAttributes, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
  	def self.onlineClassName
    	return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.EntityDO"
  	end
             
  	def self.entitiesForSync
  	end
             
  	def afterSync
    	# puts "After sync called EntityDO"
  	end 
    
end
require "CommonModules/schema_module"

class DataElement
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :attributeCd, :string
    property :attributeTypeCd, :string
    property :entityFieldTypeCd, :string
    property :globalFl, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
  	def self.onlineClassName
    	return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.DataElementDO"
  	end
             
  	def self.entitiesForSync
  	end
             
  	def afterSync
    	# puts "After sync called DataElementDO"
  	end 
    
end
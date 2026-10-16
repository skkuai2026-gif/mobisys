require "CommonModules/schema_module"

class OfflineLookupM
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :lookupKey, :string
    property :lookupEntityName, :string
    property :lookupFilterCriteria, :string
    property :lookupDataCodeName, :string
    property :lookupDataDescName, :string
    property :lookupDataSortOrderName, :string
    property :offlineDBPartition, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineLookupMDO"
    end
    
end

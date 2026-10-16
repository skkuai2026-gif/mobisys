require "CommonModules/schema_module"

class SearchResultField
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
  
    #add model specifc code here
    
    property :position, :integer
    property :metaDataCd, :string
    property :link, :string
    property :criteriaFieldQuery, :string
    property :resultFieldQuery, :string
    property :modifyQuery, :string
    property :modifyFromPartition, :string
    property :submitId, :integer

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OfflineSearchResultFieldDO"
    end
    
end

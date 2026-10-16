require "CommonModules/schema_module"

class SearchCriterion
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
  
    #add model specifc code here
    
    property :subQuery, :string
    property :subQueryOffline, :string
    property :rowPosition, :integer
    property :columnPosition, :integer
    property :mandatory, :string
    property :postSubQuery, :string
    property :metaDataCd, :string
    property :displayTypeCd, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.SearchCriterionDO"
    end
    
end

require "CommonModules/schema_module"

class IndustryOccupation
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :industryCd, :string
    property :natureOfDutyCd, :string
    property :occupationClassCd, :string
    property :occupationCd, :string
    property :industryDesc, :string
    property :natureOfDutyDesc, :string
    property :occupationClassDesc, :string
    property :occupationDesc, :string
    

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.IndustryOccupationDO"
    end

    def self.entitiesForSync
    end

    def afterSync
        puts "After sync called IndustryOccupationDO"
    end 
end

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class LeadActivity
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with LeadActivity.
    # enable :sync
  
    #add model specifc code here
    property :statusCd,     :string
    property :title,        :string
    property :description,  :string
    property :activityDt,   :date 
    property :closureDate,   :date 
  
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string
    
    # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.lead.LeadActivityDO"
    end
    
    def self.entitiesForSync
      entitiesForSync = LeadActivity.loadObject(:all)
    end
    

end

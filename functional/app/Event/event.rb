# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Event
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with Lead.
    # enable :sync
  
    #add model specifc code here
    property :eventType,     :string
    property :age,          :integer
    property :amount,       :string
  
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'ServiceQuestion'
    
    # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.Lead.EventDO"
    end
    
    def self.entitiesForSync
      entitiesForSync = Lead.loadObject(:all)
    end
    
    def afterSync
      puts "After sync called for event "   
    end
end

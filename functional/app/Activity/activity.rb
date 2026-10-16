# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Activity
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with LeadActivity.
    # enable :sync
  
    #add model specifc code here
    property :type,          :string
    property :description,   :string
    property :creationDate,  :date
    property :closureDate,   :date
    property :notes,         :string
    property :statusCd,      :string
    property :closureReason, :string
    property :closureNotes,  :string  
    property :updateActivityFlag,  :string
    property :calendarId, :string
    property :title, :string
    property :activityDt,   :time 
    
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.Lead.ActivityDO"
    end
    
    def self.entitiesForSync
      entitiesForSync = Activity.loadObject(:all)
    end
    

end
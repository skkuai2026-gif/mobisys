# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Policy/policy_b_o'

class NeedAnalysis
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with Lead.
    # enable :sync
  
    #add model specifc code here
    property :leadGuid,     :string
  
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'ServiceQuestion'
    has_many 'Event'
    
    # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.Lead.NeedAnalysisDO"
    end
    
    def self.entitiesForSync
      entitiesForSync = Lead.loadObject(:all)
    end
    
    def afterSync
      puts "After sync called for needAnalysis "   
    end
end

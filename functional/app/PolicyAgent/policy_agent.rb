# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyAgent
    include MobiSys::MobiSysEntitySchema
      
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################     
    property :policyAgentSeq, :integer
    property :primaryAgentFl, :string
    property :yearFrom, :integer
    property :yearTo, :integer
    property :commPercent, :integer
    property :prodnPercent, :integer
    property :agentId, :string
    property :agentName, :string
    property :channelId, :string
    property :subChannelId, :string
    property :unitCd, :string
    property :branchCd, :string
    property :jointFieldWork, :string
    property :location, :string
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time


    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyAgentDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
        #puts "After sync called for policy agent fields "   
    end 
    ################################################################################
    #-------------------------------Common Code End--------------------------------#
    ################################################################################    
end

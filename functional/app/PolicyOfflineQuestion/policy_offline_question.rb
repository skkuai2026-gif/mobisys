# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyOfflineQuestion
  include MobiSys::MobiSysEntitySchema
    
      set :schema_version, '1.0'
          
      # Uncomment the following line to enable sync with Label.
      # enable :sync
    
      #add model specifc code here
      property :policyQuestionSeq, :int
      property :referenceObject, :string
     
      # derived attributes  
      property :userId, :string
      property :parentKey, :string
      property :versionID, :integer
      property :id, :integer
      property :guid, :string
      property :systemCreatedDt, :time
      property :systemUpdatedDt, :time
  
      has_many "PolicyOfflineService"
      
      def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyOfflineQuestionDO"
      end
      
      def self.entitiesForSync
      end
      
      def afterSync
        #puts "After sync called for policyquestion"   
      end 
end

begin 
    require 'PolicyOfflineQuestion/policy_offline_question_company'
rescue LoadError => e
    puts 'policy_offline_question_company not included'
end

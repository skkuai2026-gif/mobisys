# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyDocTemp
  include MobiSys::MobiSysEntitySchema
      
        set :schema_version, '1.0'
            
        # Uncomment the following line to enable sync with Label.
        # enable :sync
      
        #add model specifc code here
        property :policyDocumentSeq, :int
        property :referenceObject, :string
        property :memoCode1, :string
        property :memoCode2, :string
        property :stage, :string
        property :remarks, :string
        property :documentCd, :string
       
        # derived attributes  
        property :userId, :string
        property :parentKey, :string
        property :versionID, :integer
        property :id, :integer
        property :guid, :string
        property :systemCreatedDt, :time
        property :systemUpdatedDt, :time
    
        def self.onlineClassName
          return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyDocTempDO"
        end
        
        def self.entitiesForSync
        end
        
        def afterSync
          #puts "After sync called for policy  document"   
        end 
end

begin 
    require 'PolicyDocTemp/policy_doc_temp_company'
rescue LoadError => e
    puts 'policy_doc_temp_company not included'
end

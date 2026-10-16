# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyAdditionalFields
    include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.2'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync

    #add model specifc code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################       
    property :policyAdditionalFieldsSeq, :int
    property :field1, :string
    property :field2, :string
    property :field3, :string
    property :field4, :string
    property :field5, :string
    property :field6, :string
    property :field7, :string
    property :field8, :string
    property :field9, :string
    property :field10, :string
    property :field11, :string
    property :field12, :string
    property :field13, :string
    property :field14, :string
    property :field15, :string
    property :field16, :string
    property :field17, :string
    property :field18, :string
    property :field19, :string
    property :field20, :string
    property :field21, :string
    property :field22, :string
    property :field23, :string
    property :field24, :string
    property :field25, :string
    property :field26, :string
    property :field27, :string
    property :field28, :string
    property :field29, :string
    property :policyField30, :string
    property :policyField31, :string
    property :policyField32, :string
    property :policyField33, :string
    property :policyField34, :string
    property :policyField35, :string
    property :policyField36, :string
    property :policyField37, :string
    property :policyField38, :string
    property :policyField39, :string
    property :policyField40, :string
    property :policyField41, :string
    property :policyField42, :string
    property :policyField43, :string
    property :policyField44, :string
    property :policyField45, :string
    property :policyField46, :string
    property :policyField47, :string
    property :policyField48, :string
    property :policyField49, :string
    property :policyField50, :string
    property :additionalTypeCd, :string
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :policyFieldDt51, :time
    property :policyFieldDt52, :time
    property :policyFieldDt54, :time
    property :policyFieldDt55, :time
    property :policyFieldDt56, :time
    property :policyFieldDt57, :time
    property :policyFieldDt59, :time
    property :policyFieldDt60, :time
    property :policyFieldDt58, :time
    property :policyFieldDt53, :time

    property :policyFieldDbl61, :float
    property :policyFieldDbl62, :float
    property :policyFieldDbl63, :float
    property :policyFieldDbl64, :float
    property :policyFieldDbl65, :float
    property :policyFieldDbl66, :float
    property :policyFieldDbl67, :float
    property :policyFieldDbl68, :float
    property :policyFieldDbl69, :float
    property :policyFieldDbl70, :float

    property :policyFieldSrt71, :integer 
    property :policyFieldSrt72, :integer 
    property :policyFieldSrt73, :integer 
    property :policyFieldSrt74, :integer 
    property :policyFieldSrt75, :integer
    property :removed, :string


    

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyAdditionalFieldsDO"
    end

    def self.entitiesForSync
    end

    
    #Method to indicate that this class is extended for context evaluation.
    def isParentExtendingContext
        return false
    end 

    def afterSync
        #puts "After sync called for policy additional fields "   
    end 
    ################################################################################
    #-------------------------------Common Code End--------------------------------#
    ################################################################################  
end

begin 
    require 'PolicyAdditionalFields/policy_additional_fields_company'
rescue LoadError => e
    puts 'policy_additional_fields_company not included'
end
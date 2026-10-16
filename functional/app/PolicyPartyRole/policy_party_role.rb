# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyPartyRole
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here
    property :policyPartyRoleSeq, :integer
    property :roleCd, :string
    property :partyId, :string
    property :percentage, :float, :decimal
    property :nomineeTypeCd, :string
    property :nomineeCatgCd, :string
    property :assignmentTypeCd, :string
    property :effectiveFromDt, :date
    property :effectiveToDt, :date
    property :refGuid, :string
    property :customerId, :string
    property :removed, :string

    #new attributes
    property :decisionCd, :string
    property :decisionValue, :string
    property :irrevocableFl, :string
    property :partySameAsCd, :string
    property :paymentInstructionTypeCd, :string
    property :eventTypeCd, :string

    #derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :nomineeRefGuid
    
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyPartyRoleDO"
    end
end

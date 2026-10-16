# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PolicyPayment
    include MobiSys::MobiSysEntitySchema
    
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with PolicyPayment.
    # enable :sync

    #add model specifc code here
    property :guid, :string
    property :paymentMethodCd, :string
    property :paymentInstructionTypeCd, :string
    property :partyFinAccountSeq, :string
    property :payerPartyId, :string

    #new attributes
    property :partyFinAccRefGuid, :string
    property :payerPartyRefGuid, :string
    property :payerTypeCd, :string

    #derived attributes
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
     
    attr_accessor :entityDesc
    attr_accessor :removed

    def getEntityDesc
        self.entityDesc = self.paymentInstructionTypeCd.to_s
    end
    
    #online-offline sync methods
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyPaymentDO"
    end    
end

begin 
    require 'PolicyPayment/policy_payment_company'
rescue LoadError => e
    puts 'policy_payment_company not included'
end
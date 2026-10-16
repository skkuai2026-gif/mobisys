# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PolicyProductExtra
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here

    property :extraTypeCd, :string
    property :decisionCd, :string
    property :loadingTypeCd, :string
    property :processingTypeCd, :string
    property :extraFlatAmt, :float
    property :extraPercent, :float
    property :extraFlatDuration, :integer
    property :extraPercDuration, :integer
    property :mainExtraTypeCd, :string  

    property :removed, :string
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time  

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductExtraDO"
    end
end


begin 
    require 'PolicyProductExtra/policy_product_extra_company'
rescue LoadError => e
    puts 'policy_product_extra_company not included'
end

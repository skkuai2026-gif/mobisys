# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PolicyProductInvestmentFund
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################   
    property :policyProductInvestmentFundSeq, :integer
    property :fundCd,         :string
    property :allocationPerc, :integer
    property :fundDesc, :string
    property :sortOrder, :integer
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string
        
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInvestmentFundDO"
    end   
    ################################################################################
    #-------------------------------Common Code End--------------------------------#
    ################################################################################  
    
    #################################New Properties#################################  
    property :policyProductSeq, :integer      
    property :topupAllocationPerc, :float    
    property :expiryDt, :date   
    property :maturityDt, :date 
    property :fundTypeCd, :string

end

begin 
    require 'PolicyProductInvestmentFund/policy_product_investment_fund_company'
rescue LoadError => e
    puts 'policy_product_investment_fund_company not included'
end
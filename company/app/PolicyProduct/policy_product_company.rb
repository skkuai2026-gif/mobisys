# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PolicyProduct
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.1'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################     
    attr_accessor :entityDesc, :isWOP, :systTransferOptionCd

    def getPolicyProductInvestmentFundList
        fundList = []
        self.PolicyProductInvestmentFundList.each do |fund|
            fundList.push(fund) if fund.allocationPerc.to_s != ""
        end
        return fundList
    end
end

begin 
    require 'PolicyProduct/policy_product_company'
rescue LoadError => e
    puts 'policy_product_company not included'
end
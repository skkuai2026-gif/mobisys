require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisysuihelper_jazz'
require 'Policy/policy_b_o'
require 'Product/product_b_o'

module MobiSys
	class PolicyService
		extend MobiSys::BrowserHelper

	    def self.getTotModalPremium(policy)
            # p "inside getTotModalPremium************"
            totModalPremium = 0.0
            policy.PolicyProductList.each do |policyProduct|
                if (policyProduct != nil && policyProduct.modalPremium != nil )
                    totModalPremium = totModalPremium.to_f + policyProduct.modalPremium.to_f
                    # p "totModalPremium==============#{totModalPremium}"
                end
            end
            return totModalPremium
        end

	end
end

begin 
    require 'Policy/policy_service_company'
rescue LoadError => e
    puts 'policy_service_company not included'
end
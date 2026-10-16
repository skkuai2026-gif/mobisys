#encoding: UTF-8
require 'Product/product_b_o'
require 'CommonModules/commonutil'
require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
    class PartyBO
        include Singleton
        include MobiSys::CommonUtil
        include BrowserHelper
        extend MobiSys::BrowserHelper



	    #Validates that any of the party's birthdate is not beyond system date
	    def self.checkBirthDate(party, errors)
			isValid = true
			policyGuid = party.parentKey.gsub(".","_")
	    	currentDt = Time.new
    		if party.birthDt.to_s != ""
    			birthDt = Time.parse(party.birthDt.to_s)
	    		if birthDt > currentDt
    				MobiSys::CommonUtil.registerException(policyGuid, "#{party.guid}-birthDt", "ERR_DOB", "ERR_DOB", nil, [MobiSys::BrowserHelper.getLabel("POLICY")])
					isValid = false
    			end
    		end

			return isValid 
	    end
	    ##################################################################################################
  
    end
end

begin 
    require 'Party/party_b_o_company'
rescue LoadError => e
    puts 'party_b_o_company not included'
end
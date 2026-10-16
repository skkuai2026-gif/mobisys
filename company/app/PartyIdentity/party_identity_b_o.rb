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
    class PartyIdentityBO
        include Singleton
        include MobiSys::CommonUtil
        include BrowserHelper
        extend MobiSys::BrowserHelper

    end
end

begin 
    require 'Party/party_identity_b_o_company'
rescue LoadError => e
    puts 'party_identity_b_o_company not included'
end
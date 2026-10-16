# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Policy/policy_b_o'
require 'Product/product_b_o'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class Policy
    include MobiSys::MobiSysEntitySchema
    include BrowserHelper
    include MobiSys::BrowserHelper

    attr_accessor :channelId
    attr_accessor :currentTab, :buttonClicked, :insuredSameAsProposer, :entityTypeCd
      
    def getPartyAddressList
        listPartyAddressDO = []
        self.PartyList.each do |policyParty|
            policyParty.PartyAddressList.each do |partyAddressDO|
                listPartyAddressDO.push(partyAddressDO)
            end
        end
        return listPartyAddressDO
    end

    def getBasePlan
        return getBaseProduct
    end

    def BasePlan
        baseProduct = nil
        self.PolicyProductList.each do |policyProduct|
            if policyProduct.productTypeCd == 'PLAN'
                baseProduct = policyProduct
                break
            elsif policyProduct.productTypeCd == "PA"
                baseProduct = policyProduct
                break
            end
        end
        return baseProduct
    end

    def getPolicyAdditionalFieldsDO
        policyAdditionalFieldsDO = nil
        if self.PolicyAdditionalFieldsList.size > 0
            policyAdditionalFieldsDO = self.PolicyAdditionalFieldsList[0]
        else
            policyAdditionalFieldsDO = PolicyAdditionalFields.new
            self.addPolicyAdditionalFields(policyAdditionalFieldsDO)
        end
        return policyAdditionalFieldsDO
    end

    def getRiderList
        riderList = []
        self.PolicyProductList.each do |policyProduct|
            riderList.push policyProduct if policyProduct.productTypeCd == "RIDER" && policyProduct.builtInRiderFl != "YES" && policyProduct.selected.to_s == "YES"
        end
        return riderList
    end

    def getPartyEmploymentList
        listPartyEmploymentDO = []
        self.PartyList.each do |policyParty|
            policyParty.PartyEmploymentList.each do |partyEmploymentDO|
                listPartyEmploymentDO.push(partyEmploymentDO)
            end
        end
        return listPartyEmploymentDO
    end    

    def contextExtendForClass
        # return "PolicyAdditionalFields"
        return nil
    end

    def getPartyList(roleCd=nil)
        returnPartyList = Array.new
        if roleCd
            self.PolicyPartyRoleList.each do |policyPartyRole|
                if policyPartyRole.roleCd == roleCd
                    self.PartyList.each do |party|
                        if party.guid == policyPartyRole.refGuid && party.parentKey == policyPartyRole.parentKey
                            returnPartyList.push(party)
                            break
                        end
                    end   
                end
            end
        else
            self.PartyList.each do |party|
                returnPartyList.push(party)
            end
        end
        return returnPartyList
    end 
end
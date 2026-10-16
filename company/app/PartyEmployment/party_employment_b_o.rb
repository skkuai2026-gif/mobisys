require 'Party/party_b_o'
require 'Policy/policy_b_o'
require 'CommonModules/commonutil'
require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
    class PartyEmploymentBO
        include Singleton
        include MobiSys::CommonUtil
        include BrowserHelper
        include MobiSys::BrowserHelper

      # def self.validatePrimaryOccupationEmployment(partyEmployment,errors)
      # #p "in validatePrimaryOccupationEmployment"
      
      #   party = Party.loadObject(:first, :conditions => {{ :name => 'object' } => partyEmployment.parentKey},:loadChild=>false)
      #   #p "party===>#{party}"
      #   policyGuid = party.parentKey
      #   policyGuid = party.parentKey.gsub(".","_")   
      #   partyEmploymentGuid = partyEmployment.guid
      #   isValid=true
      #   if party.roleCd == "PROPOSER" 
      #     partyEmployment = party.getPartyEmployment(false)
      #     partyBusinessAddress = party.getPartyAddress("OFFICE",false)
      #     partyAddtnField = party.getPartyAdditionalField(false)
      #     partyAddtnFieldGuid = partyAddtnField.guid if partyAddtnField
      #     if partyEmployment != nil
      #       if partyEmployment.occupationTypeCd.to_s == "RETIR" || partyEmployment.occupationTypeCd.to_s == "UNEMP" || partyEmployment.occupationTypeCd.to_s == "RETIREE"
      #         if partyAddtnField.field11.to_s == ""
      #           MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field11", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('previousOccupation') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #         end
      #         if partyAddtnField.field12.to_s == "" && partyAddtnField.field11.to_s != ""
      #           MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field12", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('previousEmployer') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])

      #         end
      #          if party.copyFromAddr3.to_s != ""
      #           # if partyBusinessAddress
      #             if partyEmployment.employerName.to_s == ""
      #               # MobiSys::CommonUtil.addErrors(errors, "employerName", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               if party.copyFromAddr3.to_s != "OTHERS" || (party.copyFromAddr3.to_s == "OTHERS" && partyBusinessAddress && partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != "")
      #                   MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerNameOrBusinessAdd", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", nil, [])

      #               end
      #             end
      #             # end
      #           end
               
      #       elsif partyEmployment.occupationTypeCd.to_s =="" || partyEmployment.occupationTypeCd.to_s =="STUDY" || partyEmployment.occupationTypeCd.to_s == "HWIFE" || partyEmployment.occupationTypeCd.to_s == "HOME"
      #         if party.copyFromAddr3.to_s != ""
      #           if partyEmployment.employerName.to_s == ""
      #             if party.copyFromAddr3.to_s != "OTHERS" || (party.copyFromAddr3.to_s == "OTHERS" && partyBusinessAddress && partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != "")
      #                 MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerNameOrBusinessAdd", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", nil, [])
      #             end
      #           end
      #         end
      #         if party.partyTypeCd.to_s == "ORGANIZATION"
      #           if partyEmployment.natureOfDuty.to_s == "OTHER"
      #             if partyAddtnField.field23.to_s == ""
      #                 MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field23", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('adquespayinfpi') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #             end
      #           end
      #         end
      #       else
      #          if partyEmployment.otherDetails.to_s == ""
                                 
      #             # MobiSys::CommonUtil.addErrors(errors, "otherDetails", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-otherDetails", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])


      #          end
      #          if partyAddtnField.field16.to_s == ""
                                 
      #             # MobiSys::CommonUtil.addErrors(errors, "otherDetails", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field16", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('currency') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])


      #          end
      #          if partyEmployment.employerName.to_s == ""
      #               # MobiSys::CommonUtil.addErrors(errors, "employerName", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerName", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               end
      #          if partyEmployment.yearsWithJob.to_s == ""
      #                                  #p "error business address2"
      #             # MobiSys::CommonUtil.addErrors(errors, "yearsWithJob", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('yearsWithJobBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-yearsWithJob", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('yearsWithJobBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])

      #          end
               
      #          if (partyEmployment.annualIncome.to_s == "") 
                  
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-annualIncome", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('amount') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #           end
               
      #         @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>party.parentKey})
      #         @basePolicyProduct = @policy.getBaseProduct
      #         @applicationType = @basePolicyProduct.addtnField1
      #         if (party.partyTypeCd.to_s == "INDIVIDUAL" || (@applicationType == "RU" && party.partyTypeCd.to_s == "ORGANIZATION"))
      #          if partyEmployment.natureOfDuty.to_s == ""
               
      #             # MobiSys::CommonUtil.addErrors(errors, "natureOfDuty", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('natureOfBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-natureOfDuty", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('natureOfBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])

      #          end
      #         end
              
      #         if partyEmployment.natureOfDuty.to_s == "OTHER"
      #           if partyAddtnField.field23.to_s == ""
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field23", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('adquespayinfpi') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #           end
      #         end
                   

      #       end 

      #     end

      #   end
      #    #Phase 2: added validation for Child Primary Occupation
      #   if party.roleCd == "PRIMARY"
      #     partyEmployment = party.getPartyEmployment(false)
      #     partyBusinessAddress = party.getPartyAddress("OFFICE",false)
      #     partyAddtnField = party.getPartyAdditionalField(false)
      #     partyAddtnFieldGuid = partyAddtnField.guid if partyAddtnField
          
      #     if partyEmployment != nil
      #       if partyEmployment.occupationTypeCd.to_s == "RETIR" || partyEmployment.occupationTypeCd.to_s == "UNEMP" || partyEmployment.occupationTypeCd.to_s == "RETIREE"
      #         if partyAddtnField.field11.to_s == ""
      #           MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field11", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('previousOccupation') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #         end
      #         if partyAddtnField.field12.to_s == "" && partyAddtnField.field11.to_s != ""
      #           MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field12", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('previousEmployer') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])

      #         end
      #         # if party.copyFromAddr3.to_s != "" && party.copyFromAddr3.to_s == "OTHERS"
      #         if party.copyFromAddr3.to_s != ""
      #           # if partyBusinessAddress
      #           #   if partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != ""
      #               if partyEmployment.employerName.to_s == ""
      #                 if party.copyFromAddr3.to_s != "OTHERS" || (party.copyFromAddr3.to_s == "OTHERS" && partyBusinessAddress && partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != "")
      #                     MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerNameOrBusinessAdd", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", nil, [])
      #                 end
      #               # MobiSys::CommonUtil.addErrors(errors, "employerName", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               end
      #             # end
      #             # end
      #           end
               
      #       elsif partyEmployment.occupationTypeCd.to_s =="" || partyEmployment.occupationTypeCd.to_s =="STUDY" || partyEmployment.occupationTypeCd.to_s == "HWIFE" || partyEmployment.occupationTypeCd.to_s == "HOME" || partyEmployment.occupationTypeCd.to_s == "CHILD"
      #         if party.copyFromAddr3.to_s != ""
      #           # if partyBusinessAddress
      #           #   if partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != ""
      #               if partyEmployment.employerName.to_s == ""
      #                 if party.copyFromAddr3.to_s != "OTHERS" || (party.copyFromAddr3.to_s == "OTHERS" && partyBusinessAddress && partyBusinessAddress.addressLine1Lang1.to_s != "" && partyBusinessAddress.countryCd.to_s != "" && partyBusinessAddress.cityCd.to_s != "" && partyBusinessAddress.stateCd.to_s != "" && partyBusinessAddress.pinCode.to_s != "")
      #                     MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerNameOrBusinessAdd", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", "ERR_MANDATORYEMPLOYERORBUSINESSNAME", nil, [])
      #                 end
      #               # MobiSys::CommonUtil.addErrors(errors, "employerName", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #               end
      #             # end
      #             # end
      #           end
      #       else
      #          if partyEmployment.otherDetails.to_s == ""
                                 
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-otherDetails", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #             # MobiSys::CommonUtil.addErrors(errors, "otherDetails", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 

      #          end
               
      #          if partyEmployment.yearsWithJob.to_s == ""
      #                                  #p "error business address2"
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-yearsWithJob", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('yearsWithJobBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #             # MobiSys::CommonUtil.addErrors(errors, "yearsWithJob", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('yearsWithJobBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 
      #          end
      #          if(partyEmployment.occupationTypeCd.to_s != "OJT")
      #             if partyAddtnField.field16.to_s == ""
      #               # MobiSys::CommonUtil.addErrors(errors, "otherDetails", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('detailsOfDuties') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')]) 
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field16", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('currency') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #             end
      #             if (partyEmployment.annualIncome.to_s == "" || partyEmployment.annualIncome.to_i == 0)                                        # p "error business address3"
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-annualIncome", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('amount') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #             end
                  
      #          end
      #          if partyEmployment.employerName.to_s == ""
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-employerName", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('employerNameOrBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #                                 # p "error business address4"
      #          end
      #           @policy = Policy.loadObject(:first, :conditions=>{{:name=>'object'}=>party.parentKey})
      #           @basePolicyProduct = @policy.getBaseProduct
      #           @applicationType = @basePolicyProduct.addtnField1
      #           if (party.partyTypeCd.to_s == "INDIVIDUAL" || (@applicationType == "RU" && party.partyTypeCd.to_s == "ORGANIZATION"))
      #          if partyEmployment.natureOfDuty.to_s == ""
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyEmploymentGuid}-natureOfDuty", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('natureOfBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
                  
      #             # MobiSys::CommonUtil.addErrors(errors, "natureOfDuty", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('natureOfBusiness') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #          end
      #         end
              
      #         if partyEmployment.natureOfDuty.to_s == "OTHER"
      #           if partyAddtnField.field23.to_s == ""
      #               MobiSys::CommonUtil.registerException(policyGuid, "#{partyAddtnFieldGuid}-field23", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('adquespayinfpi') ,MobiSys::BrowserHelper.getLabel('employmentStatusCd')])
      #           end
      #         end
                 

      #       end 

      #     end

      #    end
       
      # end

    end

end


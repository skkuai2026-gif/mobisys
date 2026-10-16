#encoding: UTF-8
require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/commonutil'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/metadata'
require 'Product/product_b_o'
require 'Party/party_b_o'
require 'CommonModules/questionnaire'
require 'Product/product_util'

module MobiSys
    class PolicyBO
        include Singleton
        include MobiSys::CommonUtil
        extend MobiSys::BrowserHelper
        include MobiSys::BrowserHelper

        
        PENDING = "PENDING"
        READYFORSYNC = "READYFORSYNC"
        SUBMITTED = "SUBMITTED"
        SYNCDONE = "SYNCDONE"
        FIELDS_TO_EXCLUDE = ["guid", "parentKey", "versionID", "visitedTabs", "systemCreatedDt","id"]

        ################################################################################
        #-----------------Code based on Validation Metadata Sheet Start----------------#
        ################################################################################
  
        def self.convertToQuotation(policy,loadQuestionContainer=true)
            quotation = Quotation.new
            agentRegDetails = AgentReg.getCurrentAgentReg

            MobiSys::CommonUtil.copyFields(policy, quotation, FIELDS_TO_EXCLUDE)
            quotation.guid = policy.guid
            quotation.intimationSourceCd = policy.intimationSourceCd
            quotation.quotationDt = policy.riskCommencementDt
            policy.channelId = agentRegDetails.channel
            quotation.channel = policy.channelId
            quotation.allocatedToRole = policy.allocatedToRole
            quotation.payingYears = policy.payingYears
            


            if loadQuestionContainer
                quotQuestionContainer = QuestionContainer.loadObject(
                    :first,
                    :conditions=>{
                        {:name=>'entityGuid'} => policy.uniqueKey,
                        {:name=>'policyGuid'} => policy.uniqueKey
                    },
                    :op=>'AND'
                )
                quotation.questionContainer = quotQuestionContainer if quotQuestionContainer
            end

            insured = policy.getParty("PRIMARY")
            proposer = policy.getParty("PROPOSER")
            if proposer !=nil
                pqp = QuotationParty.new
                MobiSys::CommonUtil.copyFields(proposer, pqp, FIELDS_TO_EXCLUDE)
                #pqp.title = proposer.titleCd
                #pqp.firstname = proposer.firstName1
                #pqp.lastname = proposer.lastName1
                pqp.nsap = proposer.nonResidentFl


                if proposer.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(proposer.PartyEmploymentList[0], pqp, FIELDS_TO_EXCLUDE)
                    pqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass 
                end
                if proposer.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(proposer.getPartyContact("MOBILE"), pqp, FIELDS_TO_EXCLUDE)
                end
                if proposer.getPartyEmail
                    MobiSys::CommonUtil.copyFields(proposer.getPartyEmail, pqp, FIELDS_TO_EXCLUDE)
                end
               
                ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                  partyAddress = pqp.getAddress(addressType.to_s, true)
                  proposerAddress = proposer.getPartyAddress(addressType.to_s)
                  if proposerAddress
                      MobiSys::CommonUtil.copyFields(proposerAddress, partyAddress, FIELDS_TO_EXCLUDE)
                      partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                  end
                  partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                end


                #pqp.dob = proposer.birthDt
                pqp.citizenshipCd = proposer.citizenshipCd
                pqp.nationality = proposer.citizenshipCd
                pqp.guid = proposer.guid
                #pqp.maritalStatus = proposer.maritalStatusCd
                if loadQuestionContainer
                    pqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => proposer.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    pqp.questionContainer = pqpQuestionContainer if pqpQuestionContainer
                end
                quotation.addQuotationParty pqp
            end

            if insured
                iqp = QuotationParty.new
                if insured.roleCd =='PROPOSER'
                    MobiSys::CommonUtil.copyFields(proposer, iqp, FIELDS_TO_EXCLUDE)
                    quotation.proposerLASame="COPYFROMINSURED"
                    #iqp.title = proposer.titleCd
                    iqp.nsap = proposer.nonResidentFl
                    iqp.relationCd = "SELF"                    
                    if proposer.PartyEmploymentList[0]
                        MobiSys::CommonUtil.copyFields(proposer.PartyEmploymentList[0], iqp, FIELDS_TO_EXCLUDE)
                        iqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass
                    end
                    if proposer.getPartyContact("MOBILE")
                        MobiSys::CommonUtil.copyFields(proposer.getPartyContact("MOBILE"), iqp, FIELDS_TO_EXCLUDE)
                    end
                    if proposer.getPartyEmail
                        MobiSys::CommonUtil.copyFields(proposer.getPartyEmail, iqp, FIELDS_TO_EXCLUDE)
                    end
                    #iqp.dob = proposer.birthDt
                    #iqp.firstname=proposer.firstName1
                    #iqp.lastname=proposer.lastName1
                    iqp.citizenshipCd=proposer.citizenshipCd
                    iqp.nationality=proposer.citizenshipCd
                    iqp.roleCd="PRIMARY"
                    iqp.guid = proposer.guid
                    #iqp.maritalStatus = proposer.maritalStatusCd
                    quotation.quotAddtnlField1 = "YES"

                    
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = iqp.getAddress(addressType.to_s, true)
                      proposerAddress = proposer.getPartyAddress(addressType.to_s)
                      if proposerAddress
                          MobiSys::CommonUtil.copyFields(proposerAddress, partyAddress, FIELDS_TO_EXCLUDE)
                          partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                      end
                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    end
                else
                    quotation.proposerLASame=""
                    MobiSys::CommonUtil.copyFields(insured, iqp, FIELDS_TO_EXCLUDE)
                    #iqp.title = insured.titleCd
                    iqp.nsap = insured.nonResidentFl
                    if insured.PartyEmploymentList[0]
                        MobiSys::CommonUtil.copyFields(insured.PartyEmploymentList[0], iqp, FIELDS_TO_EXCLUDE)
                        iqp.occupationCd = insured.PartyEmploymentList[0].occupationClass
                    end
                    if insured.getPartyContact("MOBILE")
                        MobiSys::CommonUtil.copyFields(insured.getPartyContact("MOBILE"), iqp, FIELDS_TO_EXCLUDE)
                    end
                    if insured.getPartyEmail
                        MobiSys::CommonUtil.copyFields(insured.getPartyEmail, iqp, FIELDS_TO_EXCLUDE)
                    end
                    #iqp.dob = insured.birthDt
                    #iqp.firstname=insured.firstName1
                    #iqp.lastname=insured.lastName1
                    iqp.citizenshipCd=insured.citizenshipCd
                    iqp.nationality=insured.citizenshipCd
                    iqp.guid = insured.guid
                    #iqp.maritalStatus = insured.maritalStatusCd
                    quotation.quotAddtnlField1 = "NO"
                    
                    
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = iqp.getAddress(addressType.to_s, true)
                      proposerAddress = insured.getPartyAddress(addressType.to_s)
                      if proposerAddress
                          MobiSys::CommonUtil.copyFields(proposerAddress, partyAddress, FIELDS_TO_EXCLUDE)
                          partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                      end
                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    end
                end
                if loadQuestionContainer
                    iqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => insured.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    iqp.questionContainer = iqpQuestionContainer if iqpQuestionContainer
                end
                quotation.addQuotationParty iqp        
            end 

            joint = policy.getParty("JOINT")
            if joint !=nil && joint.removed.to_s != "YES"
                jqp = QuotationParty.new
                MobiSys::CommonUtil.copyFields(joint, jqp, FIELDS_TO_EXCLUDE)
                #jqp.title = joint.titleCd
                #jqp.firstname = joint.firstName1
                #jqp.lastname = joint.lastName1
                jqp.nsap = joint.nonResidentFl
                if joint.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(joint.PartyEmploymentList[0], jqp, FIELDS_TO_EXCLUDE)
                    jqp.occupationCd = joint.PartyEmploymentList[0].occupationClass
                end
                if joint.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(joint.getPartyContact("MOBILE"), jqp, FIELDS_TO_EXCLUDE)
                end
                if joint.getPartyEmail
                    MobiSys::CommonUtil.copyFields(joint.getPartyEmail, jqp, FIELDS_TO_EXCLUDE)
                end
                #jqp.dob = joint.birthDt
                jqp.citizenshipCd = joint.citizenshipCd
                jqp.nationality = joint.citizenshipCd
                jqp.guid = joint.guid
                #jqp.maritalStatus = joint.maritalStatusCd
                if loadQuestionContainer
                    jqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => joint.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    jqp.questionContainer = jqpQuestionContainer if jqpQuestionContainer
                end
                quotation.addQuotationParty jqp
            end


            
            mailing = policy.getParty("MAILING")
            # Rho::Log.error("~~~mailing party in convertToQuotation:#{mailing}", "convertToQuotation")
            if mailing !=nil
                mqp = QuotationParty.new

                MobiSys::CommonUtil.copyFields(mailing, mqp, FIELDS_TO_EXCLUDE)

                # mqp.partyTypeCd = mailing.partyTypeCd
                #mqp.title = mailing.titleCd
                # mqp.otherTitle = mailing.otherTitle
                #mqp.firstname = mailing.firstName1
                #mqp.lastname = mailing.lastName1
                # mqp.age = mailing.age
                # mqp.genderCd = mailing.genderCd
                # mqp.smoker = mailing.smoker
                mqp.nsap = mailing.nonResidentFl
                if mailing.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(mailing.PartyEmploymentList[0], mqp, FIELDS_TO_EXCLUDE)
                    mqp.occupationCd = mailing.PartyEmploymentList[0].occupationClass
                    # mqp.industryCd = mailing.PartyEmploymentList[0].industryCd
                    # mqp.natureOfDuty = mailing.PartyEmploymentList[0].natureOfDuty
                end

                if mailing.getPartyContact("MOBILE")
                    # mqp.contactNum = mailing.getPartyContact("MOBILE").contactNum
                    MobiSys::CommonUtil.copyFields(mailing.getPartyContact("MOBILE"), mqp, FIELDS_TO_EXCLUDE)
                end

                if mailing.getPartyEmail
                    MobiSys::CommonUtil.copyFields(mailing.getPartyEmail, mqp, FIELDS_TO_EXCLUDE)
                    # if mailing.getPartyEmail.emailAddress.to_s != ''
                    #     mqp.emailAddress = mailing.getPartyEmail.emailAddress
                    # end
                end

                ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                  partyAddress = mqp.getAddress(addressType.to_s, true)
                  mailingAddress = mailing.getPartyAddress(addressType.to_s)
                  if mailingAddress
                      MobiSys::CommonUtil.copyFields(mailingAddress, partyAddress, FIELDS_TO_EXCLUDE)
                      # partyAddress.addressLine1Lang1 = mailingAddress.addressLine1Lang1
                      # partyAddress.addressLine2Lang1 = mailingAddress.addressLine2Lang1
                      # partyAddress.addressLine3Lang1 = mailingAddress.addressLine3Lang1
                      partyAddress.addressLine4Lang1 = mailingAddress.addressLine4
                      # partyAddress.countryCd = mailingAddress.countryCd
                      # partyAddress.pinCode = mailingAddress.pinCode
                      # partyAddress.stateCd = mailingAddress.stateCd
                      # partyAddress.cityCd = mailingAddress.cityCd
                  end
                  partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                end
                #mqp.dob = mailing.birthDt
                mqp.citizenshipCd = mailing.citizenshipCd
                mqp.nationality = mailing.citizenshipCd
                # mqp.roleCd = mailing.roleCd
                mqp.guid = mailing.guid
                # mqp.monthlyIncome = mailing.monthlyIncome
                # mqp.annualIncome = mailing.annualIncome
                #mqp.maritalStatus = mailing.maritalStatusCd
                # mqp.quotPartyAddtnField1 = mailing.quotPartyAddtnField1
                # mqp.quotPartyAddtnField2 = mailing.quotPartyAddtnField2
                # mqp.quotPartyAddtnField3 = mailing.quotPartyAddtnField3
                # mqp.quotPartyAddtnField4 = mailing.quotPartyAddtnField4
                if loadQuestionContainer
                    mqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => mailing.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    mqp.questionContainer = mqpQuestionContainer if mqpQuestionContainer
                end
                quotation.addQuotationParty mqp
            end

            nominee = policy.getParty("NOMINEE")
            # Rho::Log.error("~~~nominee party in convertToQuotation:#{nominee}", "convertToQuotation")
            if nominee !=nil
                nqp = QuotationParty.new

                MobiSys::CommonUtil.copyFields(nominee, nqp, FIELDS_TO_EXCLUDE)

                # nqp.partyTypeCd = nominee.partyTypeCd
                #nqp.title = nominee.titleCd
                # nqp.otherTitle = nominee.otherTitle
                #nqp.firstname = nominee.firstName1
                #nqp.lastname = nominee.lastName1
                # nqp.age = nominee.age
                # nqp.genderCd = nominee.genderCd
                # nqp.smoker = nominee.smoker
                nqp.nsap = nominee.nonResidentFl
                if nominee.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(nominee.PartyEmploymentList[0], nqp, FIELDS_TO_EXCLUDE)
                    nqp.occupationCd = nominee.PartyEmploymentList[0].occupationClass
                    # nqp.industryCd = nominee.PartyEmploymentList[0].industryCd
                    # nqp.natureOfDuty = nominee.PartyEmploymentList[0].natureOfDuty
                end
                if nominee.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(nominee.getPartyContact("MOBILE"), nqp, FIELDS_TO_EXCLUDE)
                    # nqp.contactNum = nominee.getPartyContact("MOBILE").contactNum
                end
                if nominee.getPartyEmail
                    MobiSys::CommonUtil.copyFields(nominee.getPartyEmail, nqp, FIELDS_TO_EXCLUDE)

                    # if nominee.getPartyEmail.emailAddress.to_s != ''
                    #     nqp.emailAddress = nominee.getPartyEmail.emailAddress
                    # end
                end
                
                ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                  partyAddress = nqp.getAddress(addressType.to_s, true)
                  nomineeAddress = nominee.getPartyAddress(addressType.to_s)
                  if nomineeAddress
                      MobiSys::CommonUtil.copyFields(nomineeAddress, partyAddress, FIELDS_TO_EXCLUDE)
                      # partyAddress.addressLine1Lang1 = nomineeAddress.addressLine1Lang1
                      # partyAddress.addressLine2Lang1 = nomineeAddress.addressLine2Lang1
                      # partyAddress.addressLine3Lang1 = nomineeAddress.addressLine3Lang1
                      partyAddress.addressLine4Lang1 = nomineeAddress.addressLine4
                      # partyAddress.countryCd = nomineeAddress.countryCd
                      # partyAddress.pinCode = nomineeAddress.pinCode
                      # partyAddress.stateCd = nomineeAddress.stateCd
                      # partyAddress.cityCd = nomineeAddress.cityCd
                  end
                  partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                end
                #nqp.dob = nominee.birthDt
                nqp.citizenshipCd = nominee.citizenshipCd
                nqp.nationality = nominee.citizenshipCd
                # nqp.roleCd = nominee.roleCd
                nqp.guid = nominee.guid
                # nqp.monthlyIncome = nominee.monthlyIncome
                # nqp.annualIncome = nominee.annualIncome
                #nqp.maritalStatus = nominee.maritalStatusCd
                # nqp.quotPartyAddtnField1 = nominee.quotPartyAddtnField1
                # nqp.quotPartyAddtnField2 = nominee.quotPartyAddtnField2
                # nqp.quotPartyAddtnField3 = nominee.quotPartyAddtnField3
                # nqp.quotPartyAddtnField4 = nominee.quotPartyAddtnField4
                if loadQuestionContainer
                    nqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => nominee.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    nqp.questionContainer = nqpQuestionContainer if nqpQuestionContainer
                end
                quotation.addQuotationParty nqp
            end
            #Deepali Singh: 25-08-2015 - Separating logic for base paln and rider, PolicyProductInvestmentFund is only for plan not for rider
            basePlan = policy.getBaseProduct
            if basePlan
                quotationProduct = QuotationProduct.new
                quotation.addQuotationProduct(quotationProduct)
                MobiSys::CommonUtil.copyFields(basePlan, quotationProduct, FIELDS_TO_EXCLUDE)
                quotationProduct.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                quotationProduct.productSeq = basePlan.productSeq
                quotationProduct.guid = basePlan.guid
                quotationProduct.planCode = basePlan.planCode 
                quotationProduct.systTransferOptionCd = basePlan.systTransferOptionCd

                quotationProduct.holderRefGuid = basePlan.object
                basePlan.PolicyProductInsuredList.each do|policyProductInsured|
                    quotationProduct.partyRoleCd = policyProductInsured.roleCd
                    quotationProduct.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                end

                basePlan.PolicyProductExtraList.each do|policyProductExtra|
                    quotationProductExtra = QuotationProductExtra.new
                    MobiSys::CommonUtil.copyFields(policyProductExtra, quotationProductExtra, FIELDS_TO_EXCLUDE)
                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
                    # quotationProductExtra.guid = policyProductExtra.guid
                    quotationProduct.addQuotationProductExtra(quotationProductExtra)
                end

                basePlan.PolicyProductInvestmentFundList.each do|fund|
                    next if fund.removed.to_s == "YES"
                    quotationFund = QuotationProductInvestmentFund.new
                    MobiSys::CommonUtil.copyFields(fund, quotationFund, FIELDS_TO_EXCLUDE)
                    quotationFund.fundCd = fund.fundCd
                    quotationFund.guid = fund.guid
                    quotationProduct.addQuotationProductInvestmentFund(quotationFund)
                end

                basePlan.PolicyProductAdditionalList.each do |policyProductAdditional| 
                    quotationProductAdditional = QuotationProductAdditional.new
                    MobiSys::CommonUtil.copyFields(policyProductAdditional, quotationProductAdditional, FIELDS_TO_EXCLUDE)
                    quotationProductAdditional.productRefGuid = policyProductAdditional.productRefGuid
                end
            end

            policy.PolicyProductList.each do |policyRider|
                if policyRider.productTypeCd == "RIDER"
                    quotationRider = QuotationProduct.new(:productTypeCd => "RIDER")
                    quotation.addQuotationProduct(quotationRider)
                    quotationRider.product = MobiSys::ProductUtil.getProduct(policyRider.productSeq)
                    MobiSys::CommonUtil.copyFields(policyRider, quotationRider, FIELDS_TO_EXCLUDE)
                    quotationRider.productSeq = policyRider.productSeq
                    quotationRider.guid = policyRider.guid
                    quotationRider.productLongName = policyRider.productLongName
                    quotationRider.holderRefGuid = policyRider.object
                    quotationRider.planCode = policyRider.planCode 

                    policyRider.PolicyProductInsuredList.each do|policyProductInsured|
                        if quotation.proposerLASame == "COPYFROMINSURED" && policyProductInsured.roleCd.to_s == 'PRIMARY'
                                quotationRider.insuredPartyRefGuid = insured.guid
                        else 
                            quotationRider.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                        end
                        quotationRider.partyRoleCd = policyProductInsured.roleCd
                    end

                    policyRider.PolicyProductExtraList.each do|policyProductExtra|
                        quotationProductExtra = QuotationProductExtra.new
                        MobiSys::CommonUtil.copyFields(policyProductExtra, quotationProductExtra, FIELDS_TO_EXCLUDE)
                        # quotationProductExtra.guid = policyProductExtra.guid
                        quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
                        quotationRider.addQuotationProductExtra(quotationProductExtra)
                    end
                elsif policyRider.productTypeCd == "PLANMULTI"
                    quotationPlanMulti = QuotationProduct.new(:productTypeCd => "PLANMULTI")
                    quotation.addQuotationProduct(quotationPlanMulti)

                    quotationPlanMulti.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                    MobiSys::CommonUtil.copyFields(policyRider, quotationPlanMulti, FIELDS_TO_EXCLUDE)
                    quotationPlanMulti.productSeq = policyRider.productSeq
                    quotationPlanMulti.guid = policyRider.guid
                    quotationPlanMulti.planCode = policyRider.planCode 

                    quotationPlanMulti.holderRefGuid = policyRider.object
                    policyRider.PolicyProductInsuredList.each do|policyProductInsured|
                        if quotation.proposerLASame == "COPYFROMINSURED" && policyProductInsured.roleCd.to_s == 'PRIMARY'
                            quotationPlanMulti.insuredPartyRefGuid = insured.guid
                        else 
                            quotationPlanMulti.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                        end
                        quotationPlanMulti.partyRoleCd = policyProductInsured.roleCd
                    end
                    quotationPlanMulti.sortOrder = policyRider.sortOrder

                    policyRider.PolicyProductExtraList.each do|policyProductExtra|
                        quotationProductExtra = QuotationProductExtra.new
                        MobiSys::CommonUtil.copyFields(policyProductExtra, quotationProductExtra, FIELDS_TO_EXCLUDE)
                        # quotationProductExtra.guid = policyProductExtra.guid
                        quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd

                        quotationPlanMulti.addQuotationProductExtra(quotationProductExtra)
                    end
                end
            end    

            policySupplementary = policy.getPartyList("SUPPLEMENTARY")
            policySupplementary.each do |suplementary|
                quotationParty = QuotationParty.new
                MobiSys::CommonUtil.copyFields(suplementary, quotationParty, FIELDS_TO_EXCLUDE)
                quotationParty.object=suplementary.object
                #quotationParty.title = suplementary.titleCd
                #quotationParty.firstname=suplementary.firstName1
                #quotationParty.lastname=suplementary.lastName1
                quotationParty.nsap = suplementary.nonResidentFl  

                if suplementary.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(suplementary.PartyEmploymentList[0], quotationParty, FIELDS_TO_EXCLUDE)
                    quotationParty.occupationCd = suplementary.PartyEmploymentList[0].occupationClass
                end
                if suplementary.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(suplementary.getPartyContact("MOBILE"), quotationParty, FIELDS_TO_EXCLUDE)
                end
                if suplementary.getPartyEmail
                    MobiSys::CommonUtil.copyFields(suplementary.getPartyEmail, quotationParty, FIELDS_TO_EXCLUDE)
                end
                #quotationParty.dob = suplementary.birthDt
                quotationParty.citizenshipCd=suplementary.citizenshipCd
                quotationParty.nationality=suplementary.citizenshipCd
                quotationParty.guid = suplementary.guid
                #quotationParty.maritalStatus = suplementary.maritalStatusCd
                if loadQuestionContainer
                    suppQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => suplementary.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    quotationParty.questionContainer = suppQuestionContainer if suppQuestionContainer
                end
                quotation.addQuotationParty(quotationParty)
            end

            payerList = policy.getPartyList("PAYER")
            payerList.each do |payer|
                quotationParty = QuotationParty.new
                MobiSys::CommonUtil.copyFields(payer, quotationParty, FIELDS_TO_EXCLUDE)
                #quotationParty.title = payer.titleCd
                quotationParty.guid = payer.guid
                #quotationParty.firstname = payer.firstName1
                #quotationParty.lastname = payer.lastName1
                quotationParty.nsap = payer.nonResidentFl        
                if payer.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(payer.PartyEmploymentList[0], quotationParty, FIELDS_TO_EXCLUDE)
                    quotationParty.occupationCd = payer.PartyEmploymentList[0].occupationClass
                end
                if payer.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(payer.getPartyContact("MOBILE"), quotationParty, FIELDS_TO_EXCLUDE)
                end
                if payer.getPartyEmail
                    MobiSys::CommonUtil.copyFields(payer.getPartyEmail, quotationParty, FIELDS_TO_EXCLUDE)
                end
                #quotationParty.dob = payer.birthDt
                quotationParty.roleCd = "PAYER"
                quotationParty.citizenshipCd=payer.citizenshipCd
                quotationParty.nationality=payer.citizenshipCd
                #quotationParty.maritalStatus = payer.maritalStatusCd
                quotation.addQuotationParty(quotationParty)
            end

            nomineeList = policy.getPartyList("NOMINEE")
            nomineeList.each do |nomineee|
                quotationParty = QuotationParty.new
                MobiSys::CommonUtil.copyFields(nomineee, quotationParty, FIELDS_TO_EXCLUDE)
                #quotationParty.title = nomineee.titleCd
                quotationParty.guid = nomineee.guid
                #quotationParty.firstname = nomineee.firstName1
                #quotationParty.lastname = nomineee.lastName1
                quotationParty.nsap = nomineee.nonResidentFl  
                if nomineee.PartyEmploymentList[0]
                    MobiSys::CommonUtil.copyFields(nomineee.PartyEmploymentList[0], quotationParty, FIELDS_TO_EXCLUDE)
                    quotationParty.occupationCd = nomineee.PartyEmploymentList[0].occupationClass
                end
                if nomineee.getPartyContact("MOBILE")
                    MobiSys::CommonUtil.copyFields(nomineee.getPartyContact("MOBILE"), quotationParty, FIELDS_TO_EXCLUDE)
                end
                if nomineee.getPartyEmail
                    MobiSys::CommonUtil.copyFields(nomineee.getPartyEmail, quotationParty, FIELDS_TO_EXCLUDE)
                end
                #quotationParty.dob = nomineee.birthDt
                quotationParty.roleCd = "NOMINEE"
                quotationParty.citizenshipCd=nomineee.citizenshipCd
                quotationParty.nationality=nomineee.citizenshipCd
                #quotationParty.maritalStatus = nomineee.maritalStatusCd
                quotation.addQuotationParty(quotationParty)
            end

            policy.PolicyTopUpList.each do|topUp|
                quotationTopUp = QuotationTopUp.new
                MobiSys::CommonUtil.copyFields(topUp, quotationTopUp, FIELDS_TO_EXCLUDE)
                quotationTopUp.topUpTypeCd = topUp.topUpTypeCd
                quotationTopUp.guid = topUp.guid
                quotation.addQuotationTopUp(quotationTopUp)
            end
            if policy && policy.policyWithdrawalList
                policy.policyWithdrawalList.each do |withdrawal|
                    quotation.addQuotationWithdrawal(withdrawal)
                end
            end
            quotation.QuotationPartyList.each do |quotationParty|
              if quotationParty.visitedTabs.to_s == ""
                quotationParty.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationParty.roleCd)
              end
            end
            quotation.QuotationProductList.each do|quotationProduct|
              if  quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs  = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
              end
            end
            return quotation       
        end
        ##################################################################################################

        def self.convertToPolicy(quotation, copyInsured = false)

            # if quotation != nil
                agentRegDetails = AgentReg.getCurrentAgentReg
                policy = Policy.new
                MobiSys::CommonUtil.copyFields(quotation, policy, FIELDS_TO_EXCLUDE)
                policy.guid = quotation.guid
                policy.quotationRefGuid = quotation.guid 
                # policy.quotationRefGuid = quotation.uniqueKey
                policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                policy.branchCd = quotation.quotAddtnlField2
                policy.questionContainer = quotation.questionContainer
                policy.action = quotation.action
                policy.proposerLASame = quotation.proposerLASame
                policy.quoteProposerSameAsInsured = quotation.getPartyByRole("PROPOSER").quotPartyAddtnField4
                policy.channelId = agentRegDetails.channel
                policy.payingYears = quotation.payingYears
                
                if quotation.isBackdatedFl.to_s == "YES"
                    policy.policyCommencementDt = quotation.quotationDt
                else
                    policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                if quotation.isBackdatedFl.to_s == "YES"
                    policy.riskCommencementDt = quotation.quotationDt
                else
                    policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                policy.baseAgentId = $userId
                policy.intimationSourceCd = "ESUBMISSION"
                policy.uwDecisionCd = "PENDING"
                policy.statusCd = "PENDING"
                policy.allocatedToRole = quotation.allocatedToRole
                

                convertIllustrationToEappPlanDetails(quotation, policy)
                policyHolder = Party.new(:roleCd => "PROPOSER")
                policy.addParty(policyHolder)
                convertIllustrationToEappParty(quotation, policyHolder, "PROPOSER")
                policyPartyRoleProposer = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => policyHolder.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleProposer)

                if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.getPartyByRole('PRIMARY').partySameAsCd.to_s == 'PROPOSER') && !copyInsured
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => "PROPOSER")
                    policy.addPolicyPartyRole(policyPartyRoleInsured)
                    policy.insuredSameAsProposer = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => policyHolder.guid, :issueAge => policyHolder.age)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                else
                    insured = Party.new(:roleCd => "PRIMARY")
                    policy.addParty(insured)
                    convertIllustrationToEappParty(quotation, insured, "PRIMARY")
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => insured.uniqueKey, :partySameAsCd => "")
                    policy.addPolicyPartyRole(policyPartyRoleInsured)
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => insured.guid, :issueAge => insured.age)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                end

                if quotation.getPartyByRole("JOINT") && quotation.getPartyByRole("JOINT").removed.to_s != "YES"
                    jointLife = Party.new(:roleCd => "JOINT")
                    policy.addParty(jointLife)
                    convertIllustrationToEappParty(quotation, jointLife, "JOINT")
                    policyPartyRoleJointLife = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => jointLife.uniqueKey)
                    policy.addPolicyPartyRole(policyPartyRoleJointLife)
                    policy.jointLife = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            jointProductInsured = PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => jointLife.guid)
                            policyProduct.addPolicyProductInsured(jointProductInsured)
                        end
                    end
                end
                if quotation.getPartyByRole("MAILING") && quotation.getPartyByRole("MAILING").removed.to_s != "YES"
                    mailingLife = Party.new(:roleCd => "MAILING")
                    policy.addParty(mailingLife)
                    convertIllustrationToEappParty(quotation, mailingLife, "MAILING")
                    policyPartyRolemailingLife = PolicyPartyRole.new(:roleCd => "MAILING", :refGuid => mailingLife.uniqueKey)
                    policy.addPolicyPartyRole(policyPartyRolemailingLife)
                    policy.jointLife = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            mailingProductInsured = PolicyProductInsured.new(:roleCd => "MAILING", :insuredSequenceTypeCd => "MAILING", :insuredPartyRefGuid => mailingLife.guid)
                            policyProduct.addPolicyProductInsured(mailingProductInsured)
                        end
                    end
                end

                if quotation.getPartyByRole("NOMINEE") && quotation.getPartyByRole("NOMINEE").removed.to_s != "YES"
                    nomineeLife = Party.new(:roleCd => "NOMINEE")
                    policy.addParty(nomineeLife)
                    convertIllustrationToEappParty(quotation, nomineeLife, "NOMINEE")
                    policyPartyRolenomineeLife = PolicyPartyRole.new(:roleCd => "NOMINEE", :refGuid => nomineeLife.uniqueKey)
                    policy.addPolicyPartyRole(policyPartyRolenomineeLife)
                    policy.jointLife = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            nomineeProductInsured = PolicyProductInsured.new(:roleCd => "NOMINEE", :insuredSequenceTypeCd => "NOMINEE", :insuredPartyRefGuid => nomineeLife.guid)
                            policyProduct.addPolicyProductInsured(nomineeProductInsured)
                        end
                    end
                end
                
                product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq) if policy.baseProductSeq.to_s != ""
                familyFloaterFl = product.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES' if product
                quotation.getPartyListByRoleCd("SUPPLEMENTARY").each_with_index do |oldParty, index|
                    if oldParty.partySameAsCd == 'PROPOSER' && quotation.insuranceTypeCd == 'AUTO'
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => 'PROPOSER')
                        policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                    else
                        suppLife = Party.new(:roleCd => "SUPPLEMENTARY")
                        policy.addParty(suppLife)
                        convertIllustrationToEappParty(quotation, suppLife, "SUPPLEMENTARY", index)
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => suppLife.uniqueKey)
                        policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                        if familyFloaterFl
                            policy.PolicyProductList.each do |policyProduct|
                                if policyProduct.productTypeCd == 'PLAN'
                                    supProductInsured = PolicyProductInsured.new(:roleCd => "SUPPLEMENTARY", :insuredSequenceTypeCd => "SUPPLEMENTARY", :insuredPartyRefGuid => suppLife.guid)
                                    policyProduct.addPolicyProductInsured(supProductInsured)
                                    break
                                end
                            end 
                        end
                    end
                end
                policyAdditional = PolicyAdditionalFields.new
                policyAdditional.field20 = quotation.additionalField
                policy.addPolicyAdditionalFields(policyAdditional)
                policy.PartyList.each do |party|
                  if  party.visitedTabs.to_s == ""
                    party.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",party.roleCd)
                  end
                end
                policy.PolicyProductList.each do|policyProduct|
                  if policyProduct.visitedTabs.to_s == ""
                    policyProduct.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",policyProduct.productTypeCd)
                  end
                end

                #copy lead party identity,contact,address into policy
                if(quotation.leadId.to_s != "")
                    lead = Lead.loadObject(:first, :conditions => {:leadId => quotation.leadId})
                    partyRefGuid = lead.partyRefGuid if lead
                    if(partyRefGuid.to_s != "")
                        quoteParty = quotation.getPartyByRole("PROPOSER")
                        leadParty = Party.loadObject(:first, :conditions => {:guid => partyRefGuid})
                        if(leadParty != nil)
                            proposerParty = policy.getParty("PROPOSER")
                            proposerParty.citizenshipCd = leadParty.citizenshipCd
                            proposerParty.otherCitizenship = leadParty.otherCitizenship
                            proposerParty.religionCd = leadParty.religionCd
                            proposerParty.raceCd = leadParty.raceCd
                            # proposerParty.nonResidentFl = leadParty.nonResidentFl
                            proposerParty.placeOfBirth = leadParty.placeOfBirth
                            proposerParty.countryOfBirth = leadParty.countryOfBirth
                            # proposerParty.copyFromAddr3 = leadParty.copyFromAddr3
                            # proposerParty.copyFromAddr2 = leadParty.copyFromAddr2
                            if(leadParty.PartyIdentityList.size > 0)
                                leadParty.PartyIdentityList.each do |leadPartyIdentity|
                                    if(leadPartyIdentity.identityNum != nil && quoteParty.idNumber.to_s == leadPartyIdentity.identityNum.to_s &&
                                           leadPartyIdentity.identityTypeCd != nil && quoteParty.idType.to_s == leadPartyIdentity.identityTypeCd.to_s)
                                        next
                                    end

                                    partyIdentity = PartyIdentity.new
                                    MobiSys::CommonUtil.copyFields(leadPartyIdentity, partyIdentity)
                                    proposerParty.addPartyIdentity(partyIdentity)
                                end
                            end
                            # if(leadParty.PartyAddressList.size > 0)
                            #   leadParty.PartyAddressList.each do |leadPartyAddressDO|
                            #       partyAddress = PartyAddress.new
                            #       MobiSys::CommonUtil.copyFields(leadPartyAddressDO, partyAddress)
                            #       proposerParty.addPartyAddress(partyAddress)
                            #   end
                            # end
                            if(leadParty.PartyContactList.size > 0)
                                leadParty.PartyContactList.each do |leadPartyContact|
                                    if(leadPartyContact.contactTypeCd.to_s == "MOBILE" && quoteParty.contactNum.to_s != "")
                                        next
                                    end
                                    partyContact = PartyContact.new
                                    MobiSys::CommonUtil.copyFields(leadPartyContact, partyContact)
                                    proposerParty.addPartyContact(partyContact)
                                end
                            end
                            if(leadParty.PartyOtherIncomeList.size > 0)
                                leadParty.PartyOtherIncomeList .each do |leadPartyOtherIncome|
                                    partyOtherIncome = PartyOtherIncome.new
                                    MobiSys::CommonUtil.copyFields(leadPartyOtherIncome, partyOtherIncome)
                                    proposerParty.addPartyOtherIncome(partyOtherIncome)
                                end
                            end
                            #added party email related field
                            if(leadParty.PartyEmailList.size > 0 && quoteParty.emailAddress.to_s == "")
                                leadPartyEmail = leadParty.getPartyEmail("PERSONAL")
                                if(leadPartyEmail != nil) 
                                    partyEmail = PartyEmail.new
                                    MobiSys::CommonUtil.copyFields(leadPartyEmail, partyEmail)
                                    proposerParty.addPartyEmail(partyEmail)
                                end
                            end
                            #added party employment related field
                            if(leadParty.PartyEmploymentList.size > 0)
                                leadPartyEmployment = leadParty.PartyEmploymentList[0]
                                if(leadPartyEmployment != nil) 
                                    partyEmployment = PartyEmployment.new
                                    MobiSys::CommonUtil.copyFields(leadPartyEmployment, partyEmployment)
                                    proposerParty.addPartyEmployment(partyEmployment)
                                end
                            end
                            #added PartyAdditionalFields related field
                            if(leadParty.PartyAdditionalFieldsList.size > 0)
                                leadPartyAdditionalFields = leadParty.PartyAdditionalFieldsList[0]
                                if(leadPartyAdditionalFields != nil) 
                                    partyAdditionalFields = PartyAdditionalFields.new
                                    MobiSys::CommonUtil.copyFields(leadPartyAdditionalFields, partyAdditionalFields)
                                    proposerParty.addPartyAdditionalFields(partyAdditionalFields)
                                end
                            end
                        end
                    end
                end

                # policy.persistAll
                
                # @product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                return policy
            # end
        end

        ##################################################################################################

        #Method to duplicate Quotation Plan data to Policy Plan data
        def self.convertIllustrationToEappPlanDetails(quotation, policy)
            insured = quotation.getPartyByRole('PRIMARY')
            proposer = quotation.getPartyByRole('PROPOSER')
            agentRegDetails = AgentReg.getCurrentAgentReg
            policy.quotAddtnlField1 = quotation.quotAddtnlField1
            policy.quotAddtnlField2 = quotation.quotAddtnlField2
            policy.quotAddtnlField3 = quotation.quotAddtnlField3
            policy.quotAddtnlField4 = quotation.quotAddtnlField4
            policy.quotAddtnlField5 = agentRegDetails.field11
            policy.quotAddtnlField6 = agentRegDetails.field12
            policy.quotAddtnlField7 = quotation.quotAddtnlField7
            policy.quotAddtnlField8 = quotation.quotAddtnlField8
            policy.quotAddtnlField9 = quotation.quotAddtnlField9
            policy.quotAddtnlField10 = quotation.quotAddtnlField10
            policy.quotAddtnlField11 = quotation.quotAddtnlField11
            policy.quotAddtnlField12 = quotation.quotAddtnlField12
            policy.channelId = agentRegDetails.channel
            policy.initialTopupFl = quotation.initialTopupFl
            policy.regularTopupFl = quotation.regularTopupFl
            policy.topupOptionCd = quotation.topupOptionCd
            
            if quotation.proposerLASame == "COPYFROMINSURED"
                unselectedRiders = quotation.unselectedRiders.to_s
                unselectedRiders = unselectedRiders.gsub(insured.guid,proposer.guid)
                policy.unselectedRiders = unselectedRiders
            else
                policy.unselectedRiders = quotation.unselectedRiders
            end

            quotation.QuotationProductList.each do |quotationProduct|
                if quotationProduct.productTypeCd == 'PLAN'
                    policy.baseProductId = quotationProduct.productId
                    policy.baseProductSeq = quotationProduct.productSeq
                    policy.baseProductFamilyCd = quotationProduct.productFamilyCd
                    policy.productPlanOptionCd = quotationProduct.productPlanOptionCd
                end
                policyProduct = PolicyProduct.new
                MobiSys::CommonUtil.copyFields(quotationProduct, policyProduct, FIELDS_TO_EXCLUDE)
                policyProduct.productSeq = quotationProduct.productSeq
                policyProduct.guid = quotationProduct.guid
                policyProduct.topUpTypeCd = quotationProduct.topUpTypeCd
                policyProduct.productLongName = quotationProduct.productLongName
                policyProduct.planCode = quotationProduct.planCode
                policyProduct.systTransferOptionCd = quotationProduct.systTransferOptionCd

                if (quotation.proposerLASame.to_s == 'YES' || quotation.proposerLASame.to_s == 'COPYFROMINSURED') && quotationProduct.partyRoleCd.to_s == 'PRIMARY'
                    policyProduct.insuredPartyRefGuid = proposer.guid
                else
                    policyProduct.insuredPartyRefGuid = quotationProduct.insuredPartyRefGuid
                end
                policyProduct.partyRoleCd = quotationProduct.partyRoleCd
                policy.addPolicyProduct(policyProduct)

                if quotationProduct.productTypeCd != 'PLAN'
                    policyProductInsured = PolicyProductInsured.new
                    policyProduct.addPolicyProductInsured(policyProductInsured)
                    policyProductInsured.roleCd = policyProduct.partyRoleCd
                    policyProductInsured.insuredPartyRefGuid = policyProduct.insuredPartyRefGuid
                    policyProductInsured.refGuid = policyProduct.insuredPartyRefGuid
                end

                quotationProduct.QuotationProductAdditionalList.each do |qpAdditional|
                    @policyProductAdditional = PolicyProductAdditional.new
                    policyProduct.addPolicyProductAdditional(@policyProductAdditional)
                    MobiSys::CommonUtil.copyFields(qpAdditional, @policyProductAdditional, FIELDS_TO_EXCLUDE)
                end

                quotationProduct.QuotationProductExtraList.each do |quotationProductExtra|
                    policyProductExtra = PolicyProductExtra.new
                    policyProduct.addPolicyProductExtra(policyProductExtra)
                    MobiSys::CommonUtil.copyFields(quotationProductExtra, policyProductExtra, FIELDS_TO_EXCLUDE)
                    policyProductExtra.loadingTypeCd = quotationProductExtra.loadingTypeCd
                    # policyProductExtra.guid = quotationProductExtra.guid
                end
                
                quotationProduct.QuotationProductInvestmentFundList.each do |quotationFund|
                    policyProductInvestmentFund = PolicyProductInvestmentFund.new
                    policyProduct.addPolicyProductInvestmentFund(policyProductInvestmentFund)
                    MobiSys::CommonUtil.copyFields(quotationFund, policyProductInvestmentFund, FIELDS_TO_EXCLUDE)
                    policyProductInvestmentFund.fundCd = quotationFund.fundCd

                end
            end

            quotation.QuotationTopUpList.each do |topUp|
                if topUp.topUpTypeCd == 'REGULARTOPUP'
                    regularTopUp = PolicyTopUp.new(:topUpTypeCd =>'REGULARTOPUP')
                    policy.addPolicyTopUp(regularTopUp)
                    MobiSys::CommonUtil.copyFields(topUp, regularTopUp, FIELDS_TO_EXCLUDE)
                elsif topUp.topUpTypeCd == 'INITIALINVESTMENT'
                    initialTopup = PolicyTopUp.new(:topUpTypeCd =>'INITIALINVESTMENT')
                    policy.addPolicyTopUp(initialTopup)
                    MobiSys::CommonUtil.copyFields(topUp, initialTopup, FIELDS_TO_EXCLUDE)
                end     
            end
            policyWithdrawalList = []
            quotation.QuotationWithdrawalList.each do |withdrawal|
              policyWithdrawalList.push(withdrawal)
            end
            policy.policyWithdrawalList = policyWithdrawalList

        end


        ##################################################################################################

        #Method to duplicate QuotationParty object data to policy Party object
        def self.convertIllustrationToEappParty(quotation, newParty, roleCd, supplementaryCount = -1)
            if roleCd == "PROPOSER"
                lead = Lead.loadObject(
                    :first, 
                    :conditions => {
                        { :name => 'leadId' } => quotation.leadId
                    }
                )
            end
            if supplementaryCount > -1 && roleCd == "SUPPLEMENTARY"
                oldParty = quotation.getPartyListByRoleCd(roleCd)[supplementaryCount]
            else
                oldParty = quotation.getPartyByRole(roleCd)
            end
            if oldParty
                oldParty.partyTypeCd = 'INDIVIDUAL' if oldParty.roleCd != "PROPOSER"
                newParty.guid = oldParty.guid
                newParty.quotationPartyGuid = oldParty.guid
                newParty.partyTypeCd = oldParty.partyTypeCd
                newParty.questionContainer = oldParty.questionContainer
                if oldParty.partyTypeCd == 'INDIVIDUAL'
                    MobiSys::CommonUtil.copyFields(oldParty, newParty, FIELDS_TO_EXCLUDE)
                    #newParty.titleCd = oldParty.title
                    #newParty.firstName1 = oldParty.firstname
                    #newParty.middleName1 = oldParty.middlename
                    #newParty.lastName1 = oldParty.lastname
                    #newParty.extensionName1 = oldParty.extensionName
                    #newParty.firstName2 = oldParty.firstname2
                    #newParty.middleName2 = oldParty.middlename2
                    #newParty.lastName2 = oldParty.lastname2
                    newParty.nonResidentFl = oldParty.nsap
                    #newParty.maritalStatusCd = oldParty.maritalStatus
                    #newParty.birthDt = oldParty.dob
                    newParty.citizenshipCd = oldParty.nationality
                    newParty.copyFromAddr3 = oldParty.educationCd
                    newParty.copyFromAddr2 = oldParty.residency
                    newParty.otherReligion = oldParty.officeIsdCode
                                
                    partyEmployment = newParty.getPartyEmployment(true)
                    MobiSys::CommonUtil.copyFields(oldParty, partyEmployment, FIELDS_TO_EXCLUDE)
                    #partyEmployment.occupationClass = oldParty.occupationCd
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = newParty.getPartyAddress(addressType.to_s, true)
                      quotPartyAddress = oldParty.getAddress(addressType.to_s)
                      if quotPartyAddress
                          MobiSys::CommonUtil.copyFields(quotPartyAddress, partyAddress, FIELDS_TO_EXCLUDE)

                          partyAddress.addressLine4Lang1 = quotPartyAddress.addressLine4
                      end
                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    end
                    
                    # partyAddress = newParty.getPartyAddress("RESIDENTIAL", true)
                    # MobiSys::CommonUtil.copyFields(oldParty, partyAddress, FIELDS_TO_EXCLUDE)
                    
                    partyContact1 = newParty.getPartyContact("MOBILE", true)
                    MobiSys::CommonUtil.copyFields(oldParty, partyContact1, FIELDS_TO_EXCLUDE)

                    partyEmail = newParty.getPartyEmail(true)
                    MobiSys::CommonUtil.copyFields(oldParty, partyEmail, FIELDS_TO_EXCLUDE)

                    if oldParty.idNumber.to_s != "" && oldParty.idType.to_s != ""
                      newPartyIdentity = PartyIdentity.new
                      MobiSys::CommonUtil.copyFields(oldParty, newPartyIdentity, FIELDS_TO_EXCLUDE)
                      #newPartyIdentity.identityNum = oldParty.idNumber
                      #newPartyIdentity.identityTypeCd = oldParty.idType
                      newParty.addPartyIdentity(newPartyIdentity)
                    end

                    if lead
                        #Copy Lead Party Details
                        leadParty = lead.getLeadParty
                        if leadParty
                          #Nationality Details
                          newParty.countryOfBirth = leadParty.countryOfBirth
                          # newParty.nonResidentFl = leadParty.nonResidentFl
                          newParty.raceCd = leadParty.raceCd
                          newParty.religionCd = leadParty.religionCd
                          newParty.maritalStatusCd = leadParty.maritalStatusCd # populate civil status from lead
                          newParty.titleCd = leadParty.titleCd # populate tile from lead
                          #Party Identity Details
                          if leadParty.PartyIdentityList.size > 0
                            leadParty.PartyIdentityList.each do |partyIdentity|
                              next if partyIdentity.identityTypeCd.to_s == oldParty.idType.to_s
                              newPartyIdentity = PartyIdentity.new
                              # newPartyIdentity.identityNum = partyIdentity.identityNum
                              # newPartyIdentity.expiryDt = partyIdentity.expiryDt
                              # newPartyIdentity.issueDt = partyIdentity.issueDt
                              # newPartyIdentity.identityTypeCd = partyIdentity.identityTypeCd
                              # newPartyIdentity.issuingAuthority = partyIdentity.issuingAuthority
                              MobiSys::CommonUtil.copyFields(partyIdentity, newPartyIdentity, FIELDS_TO_EXCLUDE)
                              newParty.addPartyIdentity(newPartyIdentity)
                              newPartyIdentity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newPartyIdentity)
                            end
                          end

                          #Party Other Income Details
                          if leadParty.getPartyOtherIncomeList.size > 0
                            leadParty.getPartyOtherIncomeList.each do |otherIncome|
                              newOtherIncome = PartyOtherIncome.new
                              # newOtherIncome.incomeTypeCd = otherIncome.incomeTypeCd
                              # newOtherIncome.sourceOfIncome = otherIncome.sourceOfIncome
                              # newOtherIncome.incomeAmount = otherIncome.incomeAmount
                              # newOtherIncome.otherSourceIncome = otherIncome.otherSourceIncome
                              # newOtherIncome.currencyCd = otherIncome.currencyCd
                              # newOtherIncome.incomeYear = otherIncome.incomeYear
                              MobiSys::CommonUtil.copyFields(otherIncome, newOtherIncome, FIELDS_TO_EXCLUDE)
                              newParty.addPartyOtherIncome(newOtherIncome)
                              newOtherIncome.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newOtherIncome)
                            end
                          end

                          # Party Additional Fields Details - for C360
                          if lead.leadSourceOther.to_s != ''
                            if(leadParty.PartyAdditionalFieldsList.size > 0)
                                leadPartyAdditionalFields = leadParty.PartyAdditionalFieldsList[0]
                                if(leadPartyAdditionalFields != nil)
                                  newPartyAdditional = PartyAdditionalFields.new
                                  MobiSys::CommonUtil.copyFields(leadPartyAdditionalFields, newPartyAdditional, FIELDS_TO_EXCLUDE)

                                  # newPartyAdditional.field1 = leadPartyAdditionalFields.field1 # other first name
                                  # newPartyAdditional.field2 = leadPartyAdditionalFields.field2 # other last name
                                  # newPartyAdditional.field3 = leadPartyAdditionalFields.field3 # other middle name
                                  # newPartyAdditional.field30 = leadPartyAdditionalFields.field30 # other suffix
                                  # newPartyAdditional.field4 = leadPartyAdditionalFields.field4 # country of legal residence 1
                                  # newPartyAdditional.field7 = leadPartyAdditionalFields.field7 # citizenship 1

                                  newParty.addPartyAdditionalFields(newPartyAdditional)
                                  newPartyAdditional.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(leadPartyAdditionalFields)
                                end
                            end
                          end

                          #Residential and Office Contact Details
                          if leadParty.getPartyContact("OFFICE")
                            leadOfficeContact = leadParty.getPartyContact("OFFICE")
                            partyContact2 = newParty.getPartyContact("OFFICE",true)
                            # partyContact2.countryCd = leadOfficeContact.countryCd
                            # partyContact2.stdCode = leadOfficeContact.stdCode
                            # partyContact2.contactNum = leadOfficeContact.contactNum
                            # partyContact2.extensionNum = leadOfficeContact.extensionNum
                            MobiSys::CommonUtil.copyFields(leadOfficeContact, partyContact2, FIELDS_TO_EXCLUDE)
                            partyContact2.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact2)
                          end

                          if leadParty.getPartyContact("RESIDENTIAL")
                            leadHomeContact = leadParty.getPartyContact("RESIDENTIAL")
                            partyContact3 = newParty.getPartyContact("RESIDENTIAL",true)
                            # partyContact3.countryCd = leadHomeContact.countryCd
                            # partyContact3.stdCode = leadHomeContact.stdCode
                            # partyContact3.contactNum = leadHomeContact.contactNum
                            MobiSys::CommonUtil.copyFields(leadHomeContact, partyContact3, FIELDS_TO_EXCLUDE)
                            partyContact3.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact3)
                          end

                          if leadParty.getPartyContact("PHILIPPINESNUM")
                            leadHomeContact = leadParty.getPartyContact("PHILIPPINESNUM")
                            partyContact4 = newParty.getPartyContact("PHILIPPINESNUM",true)
                            MobiSys::CommonUtil.copyFields(leadHomeContact, partyContact4, FIELDS_TO_EXCLUDE)
                            # partyContact4.countryCd = leadHomeContact.countryCd
                            # partyContact4.stdCode = leadHomeContact.stdCode
                            # partyContact4.contactNum = leadHomeContact.contactNum
                            partyContact4.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact4) #corrected variable name from partyContact3 to partyContact4
                          end

                          # Mobile contact details - for C360
                          if lead.leadSourceOther.to_s != ''
                            if leadParty.getPartyContact("MOBILE")
                                leadMobileContact = leadParty.getPartyContact("MOBILE")
                                partyContact5 = newParty.getPartyContact("MOBILE",true)
                                MobiSys::CommonUtil.copyFields(leadMobileContact, partyContact5, FIELDS_TO_EXCLUDE)
                                # partyContact5.countryCd = leadMobileContact.countryCd
                                # partyContact5.stdCode = leadMobileContact.stdCode
                                # partyContact5.contactNum = leadMobileContact.contactNum
                                partyContact5.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact5)
                            end
                          end  
                        end
                    end 

                    partyEmployment.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmployment)
                    # partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    partyContact1.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact1)
                    partyEmail.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmail)
                elsif oldParty.partyTypeCd == 'ORGANIZATION'
                    MobiSys::CommonUtil.copyFields(oldParty, newParty, FIELDS_TO_EXCLUDE)
                    #newParty.corporateName1 = oldParty.corporateName
                    
                    newParty.nonResidentFl = oldParty.nsap
                    partyIdentity = newParty.getPartyIdentityList(true)[0]
                    # MobiSys::CommonUtil.copyFields(oldParty, partyIdentity, FIELDS_TO_EXCLUDE)
                    partyIdentity.identityNum = oldParty.businessTIN
                    
                    partyAddress = newParty.getPartyAddress("OFFICE", true)
                    quotPartyAddress = oldParty.getAddress("OFFICE")
                    if quotPartyAddress
                      MobiSys::CommonUtil.copyFields(quotPartyAddress, partyAddress, FIELDS_TO_EXCLUDE)
                      # partyAddress.addressLine1Lang1 = quotPartyAddress.addressLine1Lang1
                      # partyAddress.addressLine2Lang1 = quotPartyAddress.addressLine2Lang1
                      # partyAddress.addressLine3Lang1 = quotPartyAddress.addressLine3Lang1
                      partyAddress.addressLine4Lang1 = quotPartyAddress.addressLine4
                      # partyAddress.countryCd = quotPartyAddress.countryCd
                      # partyAddress.pinCode = quotPartyAddress.pinCode
                      # partyAddress.stateCd = quotPartyAddress.stateCd
                      # partyAddress.cityCd = quotPartyAddress.cityCd
                    end
                    partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                        

                    partyContact = newParty.getPartyContact("OFFICE", true)
                    MobiSys::CommonUtil.copyFields(oldParty, partyContact, FIELDS_TO_EXCLUDE)
                    #partyContact.countryCd = oldParty.isdCode

                    partyEmail = newParty.getPartyEmail(true)
                    MobiSys::CommonUtil.copyFields(oldParty, partyEmail, FIELDS_TO_EXCLUDE)

                    if lead
                        leadParty = lead.getLeadParty
                        if leadParty
                            if leadParty.getPartyContact("PHILIPPINESNUM")
                                leadOfficeContact = leadParty.getPartyContact("PHILIPPINESNUM")
                                partyContact1 = newParty.getPartyContact("PHILIPPINESNUM",true)
                                MobiSys::CommonUtil.copyFields(leadOfficeContact, partyContact1, FIELDS_TO_EXCLUDE)

                                # partyContact1.countryCd = leadOfficeContact.countryCd
                                # partyContact1.stdCode = leadOfficeContact.stdCode
                                # partyContact1.contactNum = leadOfficeContact.contactNum
                                # partyContact1.extensionNum = leadOfficeContact.extensionNum

                                partyContact1.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact1)
                            end
                        end
                    end
                    partyIdentity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyIdentity)
                    partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    partyContact.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact)
                    partyEmail.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmail)
                end

            end
        end

        ##################################################################################################

        # Method to copy policy values to existing quotation
        def self.copyToQuotation(policy, quotation)
            quotation.quotAddtnlField1 = policy.quotAddtnlField1
            quotation.campaignCode = policy.campaignCode
            quotation.quotAddtnlField2 = policy.quotAddtnlField2
            quotation.quotAddtnlField3 = policy.quotAddtnlField3
            quotation.quotAddtnlField4 = policy.quotAddtnlField4
            quotation.quotAddtnlField5 = policy.quotAddtnlField5
            quotation.quotAddtnlField6 = policy.quotAddtnlField6
            quotation.quotAddtnlField7 = policy.quotAddtnlField7
            quotation.quotAddtnlField8 = policy.quotAddtnlField8
            quotation.quotAddtnlField9 = policy.quotAddtnlField9
            quotation.quotAddtnlField10 = policy.quotAddtnlField10
            # copy all products values from policy to quotation           
            policy.PolicyProductList.each do |policyProduct|
                quotation.QuotationProductList.each do |quotationProduct|
                    if policyProduct.guid == quotationProduct.guid 
                        MobiSys::CommonUtil.copyFields(policyProduct, quotationProduct, FIELDS_TO_EXCLUDE)
                        quotationProduct.product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                        quotationProduct.productSeq = policyProduct.productSeq
                        quotationProduct.guid = policyProduct.guid
                        quotationProduct.systTransferOptionCd = policyProduct.systTransferOptionCd
                        quotationProduct.holderRefGuid = policyProduct.object
                        quotationProduct.planCode = policyProduct.planCode 
                        
                        policyProduct.PolicyProductInsuredList.each do|policyProductInsured|
                            if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.proposerLASame == "YES") && policyProductInsured.roleCd.to_s == 'PRIMARY'
                                    quotationProduct.insuredPartyRefGuid = quotation.getPartyByRole('PRIMARY').guid
                            else 
                                quotationProduct.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                            end
                            quotationProduct.partyRoleCd = policyProductInsured.roleCd
                        end
                    end
                end
            end
 
            return quotation       
        end

       def self.agentBancaCodeCheck(policy,errors)
            isValidated = true
            bankCodeQuestionResponseDO = nil
            refrrerCodeQuestionResponseDO = nil
            container = QuestionContainer.loadObject(
                :first, 
                :conditions=>{
                    {:name => 'entityGuid'} => policy.guid,
                    {:name => 'entityTypeCd'} => "AGENT"
                },
                :op => "AND"
            )
            # 👉 If container is nil, skip further checks
            return false if container.nil?

            list = Array(container.ServiceQuestionResponseList)
            # puts "++++++++++container.ServiceQuestionResponseList++++++>>>>#{container.ServiceQuestionResponseList}"
            if list.size > 0
                container.ServiceQuestionResponseList.each do |questionResponseDO|
                  if questionResponseDO.questionnaireTypeCd.to_s == "AGENT"
                    if questionResponseDO.questionSetCd != nil && questionResponseDO.questionDataElementCd != nil && questionResponseDO.responseValue != nil
                         puts "inside i am  111"
                      if questionResponseDO.questionSetCd.to_s == "BancaAdQues1" && questionResponseDO.questionDataElementCd.to_s == "adquesadvinfb" # branchCode
                        bankCodeQuestionResponseDO = questionResponseDO
                        # p "bankCodeQuestionResponseDO inside===>#{bankCodeQuestionResponseDO.guid}"
                    end
                      if questionResponseDO.questionSetCd.to_s == "BancaAdQues2" && questionResponseDO.questionDataElementCd.to_s =="adquesadvinfb" # ReferrerCode
                        refrrerCodeQuestionResponseDO = questionResponseDO
                      end
                    end
                  end
                end
            end

            # puts "+++++++++++++++bankCodeQuestionResponseDO+++++++++++++++++++#{bankCodeQuestionResponseDO}"
            # puts "+++++++++++++++refrrerCodeQuestionResponseDO+++++++++++++++++++#{refrrerCodeQuestionResponseDO}"

            if bankCodeQuestionResponseDO != nil
                bankresponseValue = bankCodeQuestionResponseDO.responseValue.to_s
                if bankresponseValue.length != 6
                  MobiSys::CommonUtil.registerException(policy.guid, "#{bankCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Bank Code", "BXXXXX"])

                elsif !bankresponseValue.upcase.start_with?("B")
                  MobiSys::CommonUtil.registerException(policy.guid, "#{bankCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Bank Code", "BXXXXX"])
                end
            end

            if refrrerCodeQuestionResponseDO != nil
                refresponseValue = refrrerCodeQuestionResponseDO.responseValue.to_s
                if refresponseValue.length != 6
                  MobiSys::CommonUtil.registerException(policy.guid, "#{refrrerCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Referrer Code", "RXXXXX"])
                elsif !refresponseValue.upcase.start_with?("R")
                  MobiSys::CommonUtil.registerException(policy.guid, "#{refrrerCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Referrer Code", "RXXXXX"])
                end
            end

          return isValidated
        end

        def self.eappSignature(policy, errors)
            serviceSignatureList = []
            eappProposerSignPresent = false
             agentSignPresent = false
             primarySignPresent = false
             parentSignatureRequired = false
             parentSignPresent = false
             parentSignature = nil
            signatureContainer = SignatureContainer.loadObject(:first,
                                    :conditions => {
                                    :entityGuid => policy.guid
                                    }
                                )
            insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
            policyadditionalfield = policy.getPolicyAddionalField("000")
            insured = policy.getParty("PRIMARY")
            proposer = policy.getParty("PROPOSER")
            proposerRelation = proposer.relationCd if proposer
            
            if insured  && insuredPartyRole.partySameAsCd.to_s == ""
              if insured && insured.age.to_i < 18 && policyadditionalfield && policyadditionalfield.field11.to_s == 'Y'
                parentSignatureRequired = true
              end
            end    
            if signatureContainer
                 signatureContainer.ServiceSignatureList.each do |serviceSign|
                    serviceSignatureList << serviceSign if serviceSign.signature.to_s != ''
                    if (serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPROPOSER")
                        eappProposerSignPresent = true
                    end
                    if (serviceSign.signatureTypeCd.to_s == "AGENTSIGNATURECAPTURE")
                        agentSignPresent = true
                    end
                    if serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPRIMARY" && insured && insured.age.to_i >= 18 && policy.quoteProposerSameAsInsured.to_s == "NO"
                        primarySignPresent = true
                    end    
                    if (serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPRIMARY" && parentSignatureRequired) 
                        parentSignPresent = true
                        parentSignature = serviceSign
                    end
                 end
            end


            # if((serviceSignatureList != nil && serviceSignatureList.size == 0)||(!eappProposerSignPresent) || (!agentSignPresent))
                
            #     # unless $rhoconfig[:TABFEATUREREQD]
            #     #     MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORY", ["Signature for EAPP"])
            #     # else
            #     #     MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, ["Signature for EAPP"])
            #     # end
            # end
            
            if !eappProposerSignPresent
                MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposerSignUI", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Signature",proposer.roleCd.to_s])
            end

            if !primarySignPresent && insured && insured.age.to_i >= 18 && policy.quoteProposerSameAsInsured.to_s == "NO"
                MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-primarySignUI", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Signature",insured.roleCd.to_s])
            end 

            if !agentSignPresent
                MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-agentSignUI", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Signature","Agent"])
            end 
            if parentSignatureRequired && !parentSignPresent 
               MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-parentSignUI", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Signature","Parent"])
            end    

            if parentSignPresent
                if parentSignature && parentSignature.signature.to_s == ""
                    unless $rhoconfig[:TABFEATUREREQD] 
                        MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORYFOR", ["Signature","Parent"])
                    else
                        MobiSys::CommonUtil.registerException(policy.guid, "#{parentSignature.guid}-signature", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Signature","Parent"])
                    end
                end
                 if parentSignature && parentSignature.placeOfSignature.to_s == ""
                    unless $rhoconfig[:TABFEATUREREQD] 
                        MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORYFOR", ["Place of Signing", "Parent"])
                    else
                        MobiSys::CommonUtil.registerException(policy.guid, "#{parentSignature.guid}-placeOfSignature", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Place of Signing", "Parent"])
                    end
                end     
            end     


        end

        def self.checksignonrequirements(policy, errors)
            eappProposerSignPresent = false
            primary = policy.getPartyByRole('PRIMARY')
            primaryIsChildFlag = false
            if (primary.age.to_i < 18)
                primaryIsChildFlag = true
            end

            serviceSignatureList = []
            signatureContainer = SignatureContainer.loadObject(:first,
                                    :conditions => {
                                    :entityGuid => policy.guid
                                    }
                                )
            if signatureContainer
                 signatureContainer.ServiceSignatureList.each do |serviceSign|
                    if ((primaryIsChildFlag && serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPRIMARY") || serviceSign.signatureTypeCd.to_s == "AGENTTYPE")
                        next
                    end
                    serviceSignatureList << serviceSign
                    if (serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREEAPPPROPOSER")
                        eappProposerSignPresent = true
                    end
                 end
            end

            if serviceSignatureList.size > 0
                serviceSignatureList.each do |servSign|
                    if (servSign.signature.to_s == '' || (servSign.signature.to_s == '' && servSign.signatureDt.to_s == '')) || !eappProposerSignPresent
                        unless $rhoconfig[:TABFEATUREREQD]
                            MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORY", ["Completing all Signature for EAPP"])
                        else
                            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, ["Completing all Signature for EAPP"])
                        end
                    end
                end
            end
        end

        def self.commissionSharingCheck(policy, errors)
          isValidated = true
          percentage = 0.0
          indivPercentage = 0.0
          flagShare = true
          quotation = Quotation.find(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
          container = QuestionContainer.loadObject(
                :first, 
                :conditions=>{
                    {:name => 'entityGuid'} => policy.guid,
                    {:name => 'entityTypeCd'} => "AGENT"
                },
                :op => "AND"
            )
          targetResObj = nil
          if container && container.ServiceQuestionResponseList.size > 0
            container.ServiceQuestionResponseList.each do |serviceQuestionResp|
                if serviceQuestionResp.questionnaireTypeCd != nil && serviceQuestionResp.questionnaireTypeCd.to_s == "AGENT" && (serviceQuestionResp.questionDataElementCd == "adquesadvinfh" || serviceQuestionResp.questionDataElementCd == "adquesadvinfc") && serviceQuestionResp.responseValue.to_s != ""
                  targetResObj = serviceQuestionResp
                  percentage += serviceQuestionResp.responseValue.to_f
                  indivPercentage = serviceQuestionResp.responseValue.to_f
                  flagShare = false if indivPercentage < 10.0 && indivPercentage > 0.0
                end
            end
          end

          serviceSignatureList = []

          signatureContainer = SignatureContainer.loadObject(
                :first, 
                :conditions=>{
                    {:name => 'entityGuid'} => policy.guid,
                    {:name => 'entityTypeCd'} => "Policy"
                },
                :op => "AND"
            )

          if signatureContainer && signatureContainer.ServiceSignatureList.size > 0
            signatureContainer.ServiceSignatureList.each do |servicesignature|
              if servicesignature.entityGuid == policy.guid && servicesignature.signatureTypeCd.to_s == "AGENTTYPE" && servicesignature.roleCd.to_s == "AGENT"
                  serviceSignatureList << servicesignature
                end
            end
          end

          if serviceSignatureList.nil? || serviceSignatureList.empty?
            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, ["Signature for Agent"])
          end

          if !flagShare
            isValidated = false
            MobiSys::CommonUtil.registerException(policy.guid, "", "ERR_SHARE", "ERR_SHARE", nil, ["Advisors"])
          end

          if percentage != 100.0
            isValidated = false
            errorGuid = targetResObj.guid if targetResObj
             MobiSys::CommonUtil.registerException(policy.guid, "#{errorGuid}-guid", "ERR_PERCENTAGE", "ERR_PERCENTAGE", nil, ["Advisors", MobiSys::CommonUtil.getDoubleValue(percentage)])
          end
            # if MobiSys::PolicyService.hasProposalExpired(quotation)
            #    isValidated = false
            #    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_PROPOSAL_EXPIRED", "ERR_PROPOSAL_EXPIRED", nil, [])
            # end  
          return isValidated
        end

        def self.validateProposalVersioncheck(policy, errors)
            isValidated = true
            quotation = Quotation.find(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
            if MobiSys::PolicyService.hasProposalExpired(quotation)
               isValidated = false
               MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_PROPOSAL_EXPIRED", "ERR_PROPOSAL_EXPIRED", nil, [])
            end 
            return isValidated
        end 

        def self.checkOwnerPartyIdentity(policy, errors)
            isValid = true
            count = 0
            birDocFlag = false
            partyIdentityList = []
            party = policy.getPartyByRole("PROPOSER")
            party.PartyIdentityList.each do |partyId|
                if (partyId.identityTypeCd.to_s != '')
                    if (partyId.identityTypeCd.to_s != 'PTIN' && partyId.identityTypeCd.to_s != 'SSN')
                        if partyId.identityTypeCd.to_s == 'BIR'
                            birDocFlag = true
                        end
                        partyIdentityList << partyId.identityTypeCd.to_s
                    end
                    count += 1
                end
            end
            if count == 2
                MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-guid", "ERR_MANDATORYIDDESC", "ERR_MANDATORYIDDESC", nil, ["I.D. Presented ", "PROPOSER"])
                isValid = false
            end
            if partyIdentityList.size == 1 && birDocFlag
                MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORYFORBIRDOCSUNPH", "ERR_MANDATORYFORBIRDOCSUNPH", nil, [])
                isValid = false
            end
            if partyIdentityList.size >= 2
                docValForTwo = CompanyFacet.find(:first, :conditions => {:facetCd => "DOCVALIDATIONFORTWO"})
                docValForTwoVal = docValForTwo.actionValue.to_s if docValForTwo
                if docValForTwoVal.to_s != ''
                    pairs = docValForTwoVal.split(",")
                    counter = 0
                    pairs.each do |pair|
                        keyValue = pair.split(":")
                        if (keyValue.length == 2)
                            key = keyValue[0]
                            value = keyValue[1]

                            if partyIdentityList.include?(key) && partyIdentityList.include?(value)
                                doc1 = Document.find(:first, :conditions=>{:documentCd => key.to_s})
                                docDesc1 = doc1.documentDesc.to_s.upcase if doc1

                                doc2 = Document.find(:first, :conditions=>{:documentCd => value.to_s})
                                docDesc2 = doc2.documentDesc.to_s.upcase if doc2

                                MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid#{party.roleCd}#{counter}", "ERR_MANDATORYFORDOCSUNPH", "ERR_MANDATORYFORDOCSUNPH", nil, [docDesc1, docDesc2])
                                isValid = false
                            end
                        end
                    end
                end
            end
            return isValid
        end

        def self.checkInsuredPartyIdentity(policy, errors)
            isValid = true
            if !policy.insuredSameAsProposer
                count = 0
                birDocFlag = false
                partyIdentityList = []
                party = policy.getPartyByRole("PRIMARY")
                party.PartyIdentityList.each do |partyId|
                    if (partyId.identityTypeCd.to_s != '')
                        if (partyId.identityTypeCd.to_s != 'PTIN' && partyId.identityTypeCd.to_s != 'SSN')
                            if partyId.identityTypeCd.to_s == 'BIR'
                                birDocFlag = true
                            end
                            partyIdentityList << partyId.identityTypeCd.to_s
                        end
                        count += 1
                    end
                end
                if count == 2
                    MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-guid", "ERR_MANDATORYIDDESC", "ERR_MANDATORYIDDESC", nil, ["I.D. Presented ", "PROPOSER"])
                    isValid = false
                end
                if partyIdentityList.size == 1 && birDocFlag
                    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORYFORBIRDOCSUNPH", "ERR_MANDATORYFORBIRDOCSUNPH", nil, [])
                    isValid = false
                end
                if partyIdentityList.size >= 2
                    docValForTwo = CompanyFacet.find(:first, :conditions => {:facetCd => "DOCVALIDATIONFORTWO"})
                    docValForTwoVal = docValForTwo.actionValue.to_s if docValForTwo
                    if docValForTwoVal.to_s != ''
                        pairs = docValForTwoVal.split(",")
                        counter = 0
                        pairs.each do |pair|
                            keyValue = pair.split(":")
                            if (keyValue.length == 2)
                                key = keyValue[0]
                                value = keyValue[1]

                                if partyIdentityList.include?(key) && partyIdentityList.include?(value)
                                    doc1 = Document.find(:first, :conditions=>{:documentCd => key.to_s})
                                    docDesc1 = doc1.documentDesc.to_s.upcase if doc1

                                    doc2 = Document.find(:first, :conditions=>{:documentCd => value.to_s})
                                    docDesc2 = doc2.documentDesc.to_s.upcase if doc2

                                    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid#{party.roleCd}#{counter}", "ERR_MANDATORYFORDOCSUNPH", "ERR_MANDATORYFORDOCSUNPH", nil, [docDesc1, docDesc2])
                                    isValid = false
                                end
                            end
                        end
                    end
                end
            end
            return isValid
        end

        def self.documentValidationSunph(policy, errors)
          isValidated = true
          partyGuid = []
          # maxFileSizePerDoc = OfflineApplication.find(:first, :conditions=>{:property=>'MAXFILESIZELIMITPERDOC'})
          uploadFileCount = OfflineApplication.find(:first, :conditions=>{:property=>'UPLOADFILECOUNTLIMIT'})

          if policy && policy.allocatedToRole && policy.allocatedToRole.to_s == "AGENT"
            primaryPartyRole = policy.getPolicyPartyRole("PRIMARY")
            insuredSameAsProposer = (primaryPartyRole.partySameAsCd.to_s == "PROPOSER") if primaryPartyRole != nil
            if insuredSameAsProposer
              currentParty = policy.getPartyByRole("PROPOSER")
              partyGuid << currentParty.guid
            else
              currentProposerParty = policy.getPartyByRole("PROPOSER")
              currentPrimaryParty = policy.getPartyByRole("PRIMARY")
              partyGuid << currentProposerParty.guid
              partyGuid << currentPrimaryParty.guid
            end

            selectedDocCount = 0
            partyGuid.each do |currentPartyGuid|
              listServiceDocDOByParty = policy.getServiceDocumentListForParty(currentPartyGuid)
              currentParty = policy.getPartyDOByGuid(currentPartyGuid)
              if listServiceDocDOByParty
                serviceDocumentAttachedMap = {}

                listServiceDocDOByParty.each do |serviceDocumentDO|
                  if serviceDocumentDO.acceptanceStatusCd && serviceDocumentDO.acceptanceStatusCd.to_s == "FULFILLED"
                    serviceDocumentAttachedMap[serviceDocumentDO.documentCd] = serviceDocumentDO
                  end
                end

                serviceDoc = CompanyFacet.find(:first, :conditions => {:facetCd => "DOCVALIDATION"})

                if serviceDoc && !serviceDocumentAttachedMap.empty?
                  pairs = serviceDoc.actionValue.split(",")
                  counter1 = 0

                  pairs.each do |pair|
                    counter1 += 1
                    keyValue = pair.split(":")
                    if keyValue.length == 2
                      key, value = keyValue
                      skipMinorFlag = true

                      if currentParty && currentParty.roleCd.to_s == "PRIMARY" && currentParty.age < 18
                        serviceDocSkipMinor = CompanyFacet.find(:first, :conditions => {:facetCd => "DOCVALIDATIONMINOROFF"})
                        if serviceDocSkipMinor && serviceDocSkipMinor.actionValue.to_s != ""
                          documentSkipPairs = serviceDocSkipMinor.actionValue.to_s.split(",")
                          documentSkipPairs.each do |docSkipMinor|
                            skipMinorFlag = false if key.to_s == docSkipMinor.to_s
                          end
                        end
                      end

                      if skipMinorFlag
                        if serviceDocumentAttachedMap.key?(key)
                          unless serviceDocumentAttachedMap.key?(value)
                            documentDO = Document.find(:first, :conditions=>{:documentCd => value.to_s})
                            documentDesc = documentDO.documentDesc.upcase
                            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid#{currentParty.roleCd}#{counter1}", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", "tab_requirement", [documentDesc, currentParty.roleCd])
                          end
                        elsif serviceDocumentAttachedMap.key?(value)
                          unless serviceDocumentAttachedMap.key?(key)
                            documentDO = Document.find(:first, :conditions=>{:documentCd => key.to_s})
                            documentDesc = documentDO.documentDesc.upcase
                            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid#{currentParty.roleCd}#{counter1}", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", "tab_requirement", [documentDesc, currentParty.roleCd])
                          end
                        end
                      end
                    end
                  end

                  serviceDoc1 = CompanyFacet.find(:first, :conditions => {:facetCd => "DOCVALIDATIONFORTWO"})
                  if serviceDoc1 && !serviceDocumentAttachedMap.empty?
                    pairs1 = serviceDoc1.actionValue.to_s.split(",")

                    pairs1.each do |pair|
                      counter1 += 1
                      keyValue = pair.split(":")
                      if keyValue.length == 2
                        key, value = keyValue

                        if serviceDocumentAttachedMap.key?(key) && serviceDocumentAttachedMap.key?(value)
                          documentDO1 = Document.find(:first, :conditions=>{:documentCd => key.to_s})
                          documentDO2 = Document.find(:first, :conditions=>{:documentCd => value.to_s})
                          documentDesc1 = documentDO1.documentDesc.upcase
                          documentDesc2 = documentDO2.documentDesc.upcase
                          MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid#{currentParty.roleCd}#{counter1}", "ERR_MANDATORYFORDOCSUNPH", "ERR_MANDATORYFORDOCSUNPH", "tab_requirement", [documentDesc1, documentDesc2, documentDesc1, documentDesc2])
                        end
                      end
                    end
                  end
                end
              end
                serviceDocAdaAttached = []
                listServiceDocDOByParty.each do |serviceDocumentDO|
                    if serviceDocumentDO.documentCd.to_s != "" && serviceDocumentDO.selected.to_s == 'YES' && serviceDocumentDO.removed.to_s != 'YES' 
                        # documentDO = Document.find(:first, :conditions=>{:documentCd => serviceDocumentDO.documentCd.to_s})
                        # documentDesc = documentDO.documentDesc.upcase
                        pdfFlag = false
                        otherFlag = false
                        selectedDocCount+=1
                        imageOfflineEntity = Image.loadObject(:all, :conditions=>{'parentRefGuid' => serviceDocumentDO.guid.to_s})
                        pdfCount = 0
                        totalFileSizeInBytes = 0
                        imageOfflineEntity.each do |imageOffline|
                            offlineFile = OfflineFile.loadObject(:first, :conditions=>{'parentKey' => imageOffline.object.to_s})
                            # puts "offlineFile~~~~~~~~~~~~~~~#{offlineFile}"
                            # if imageOffline.parentRefGuid == serviceDocumentDO.guid
                            #      data = Base64.decode64(offlineFile.fileContents)
                            #      totalFileSizeInBytes += data.length.to_f;
                            # end
                            fileLocation = offlineFile.fileLocation.to_s
                            fileLocation = fileLocation.split(".")
                            size = fileLocation.length
                            # p "size===>#{size}"
                            extension = fileLocation[size-1]
                            # puts "extension~~~~~~~#{extension}"
                            if extension == "pdf"
                                pdfFlag = true
                                pdfCount = pdfCount + 1
                            else
                                otherFlag = true
                            end
                            # puts "pdfFlag!!!!~~~#{pdfFlag}"
                            # puts "otherFlag!!!!~~~#{otherFlag}"

                        end
                        # totalFileSizeInMB = totalFileSizeInBytes / (1024 * 1024);
                        # if maxFileSizePerDoc && totalFileSizeInMB && totalFileSizeInMB > maxFileSizePerDoc.value.to_f 
                        #     MobiSys::CommonUtil.registerException(policy.guid, "#{serviceDocumentDO.guid}-documentCd", "ERR_MAXFILESIZELIMITPERDOC", "ERR_MAXFILESIZELIMITPERDOC", nil, [documentDesc, maxFileSizePerDoc.value.to_s])
                        # end
                        if pdfFlag && otherFlag
                             # puts "errrorrrsss~~~~DIFF_FILETYPE~~~"
                            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-documentCd", "ERR_DIFFFILEYPECHECK", "ERR_DIFFFILEYPECHECK", nil, [])

                        end
                        if pdfCount.to_i > 1
                            documentDO = Document.find(:first, :conditions=>{:documentCd => serviceDocumentDO.documentCd.to_s})
                            documentDesc = documentDO.documentDesc.upcase
                            MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-documentCdNew", "MULTIPLEPDF", "MULTIPLEPDF", $currentTabId, [documentDesc])
                        end
                    end
                    adaDocList = CompanyFacet.find(:first, :conditions => {:facetCd => "BANKDOCS"})
                    adaDocArray = []
                    if adaDocList && adaDocList.actionValue.to_s != nil
                      adaDocArray = adaDocList.actionValue.split(",")
                    end
                    if !adaDocArray.empty? && adaDocArray.size > 0 && adaDocArray.include?(serviceDocumentDO.documentCd.to_s)
                        adaFlag = nil
                        adaFlag = OfflineApplication.find(:first, :conditions=>{:property=>'ADA_VALIDATION_REQUIREMENTTAB_FLAG'})
                        if ((adaFlag && adaFlag.value.to_s == "YES") || adaFlag == nil || adaFlag == "")
                            serviceDocAdaAttached.push(serviceDocumentDO)
                        end
                    end
                end
                additionalDocs = CompanyFacet.find(:first, :conditions => {:facetCd => "ADDITIONALDOCS"})
                if additionalDocs && !serviceDocumentAttachedMap.empty?
                    groups = additionalDocs.actionValue.split(",")

                    groups.each do |pair|
                        docs = pair.split(":")
                        allSelected = true;

                        docs.each do |doc|
                          unless serviceDocumentAttachedMap.key?(doc.strip)
                            allSelected = false
                            break
                          end
                        end

                        if allSelected
                          selectedDocCount -= (docs.length - 1)
                        end
                    end
                end
                if !serviceDocAdaAttached.empty?
                    exception = MobiSys::PolicyService.checkForValidADADoc(serviceDocAdaAttached,policy)
                    exception.each do |excep|
                        # MobiSys::CommonUtil.registerException(policy.guid, "#{excep.guid}-documentCd", "#{excep.exceptionCd}", getLabelValue(excep.exceptionCd), "tab_requirement")
                        MobiSys::CommonUtil.registerException(policy.guid, "#{excep['guid']}-documentCd","#{excep['exceptionCd']}", getLabelValue(excep['exceptionCd']), "tab_requirement")
                    end
                end
            end
            if uploadFileCount && selectedDocCount > uploadFileCount.value.to_i
                MobiSys::CommonUtil.registerException(policy.guid, "documentCd", "ERR_FILECOUNT", "ERR_FILECOUNT", nil, [uploadFileCount.value.to_s])
            end
          end
          isValidated
        end

        #Method to validate Requirements Tab
        def self.validateServiceDocument(container, lifeName, policy, life, errors, isAutoUwGeneratedFl = false)
            product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            
            lifePartyRoles = []
            lifePartyRole = nil
            
            policy.PolicyPartyRoleList.each do |policyPartyRole|
                if policyPartyRole.refGuid.to_s == life.guid
                    lifePartyRoles.push policyPartyRole
                end
            end
            lifePartyRoles.each do |lpr|
                if lpr.roleCd.to_s == life.roleCd.to_s
                    lifePartyRole = lpr
                end
            end

            policyPayment = policy.getPolicyPayment("RENEWALPREMIUM")
            if policyPayment != nil && (lifePartyRole.roleCd == "PROPOSER" || lifePartyRole.roleCd == "PAYER") && baseProduct != nil
                baseProduct.paymentMethodCd = policyPayment.paymentMethodCd
            end

            if baseProduct && lifePartyRole
                originalPartyRole = baseProduct.partyRoleCd
                originalInsureRefGuid = baseProduct.insuredPartyRefGuid
                originalCombinedEntryAge = baseProduct.combinedEntryAge
                baseProduct.partyRoleCd = lifePartyRole.roleCd
                if lifePartyRole.roleCd == "SUPPLEMENTARY" || lifePartyRole.roleCd == "NOMINEE"
                    baseProduct.insuredPartyRefGuid = life.object
                    baseProduct.combinedEntryAge = life.age
                end
            end
            categoriesDerivedFromDT = []
              for i in 0..20
                if i == 0
                  i = ""
                end
                nbReqName = "NBREQUIRMENTS" << i.to_s
                ttms = product.getTableTypeMappingSeq(nbReqName)
                offlineFacet = product.getFacet(nbReqName)
                if (ttms.to_s != '' && ((offlineFacet && offlineFacet.applicableRoles.to_s == "" ) || (offlineFacet  && offlineFacet.applicableRoles.to_s.split(",").include?(life.roleCd.to_s))))
                  defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true)
                  # defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true)
                  defTables.each do |defTable|
                    if defTable.documentCategoryCd.to_s != ''
                      categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                    end
                  end
                  insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
                  if insuredPartyRole
                      proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
                  end
                  if proposerIsSameAsInsured
                      tempCurrRoleCd = life.roleCd
                      life.roleCd = insuredPartyRole.roleCd.to_s
                      defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true, true)
                      defTables.each do |defTable|
                          if defTable.documentCategoryCd.to_s != ''
                              categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                              # categoriesDerivedFromDT = categoriesDerivedFromDT.uniq
                          end
                      end
                      life.roleCd = tempCurrRoleCd
                  end
                end
              end
            categoriesDerivedFromDT = categoriesDerivedFromDT.flatten.uniq
            container.ServiceDocumentList.each do |serviceDocument|
                # only uw document need to validate in cae of uw flag...if non uw then only non uw document need to validate
                if((isAutoUwGeneratedFl && !serviceDocument.isAutoGeneratedFl.to_s == "YES_UW") || (!isAutoUwGeneratedFl && serviceDocument.isAutoGeneratedFl.to_s == "YES_UW"))
                    next
                end
                if !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s) && serviceDocument.isAutoGeneratedFl != "YES_UW" && serviceDocument.isAutoGeneratedFl != "QUESTION"
                    serviceDocument.removed = 'YES' 
                    Image.delete_all(
                        :conditions => {
                            {:name=>'parentRefGuid'} => serviceDocument.guid
                        },
                        :op => 'AND'
                    )
                end
                categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
            end
            if baseProduct
                baseProduct.partyRoleCd = originalPartyRole
                baseProduct.insuredPartyRefGuid = originalInsureRefGuid
                baseProduct.combinedEntryAge = originalCombinedEntryAge
            end
            documentCategoryM = DocumentCategory.loadObject( 
                :all,
                :conditions => {
                    { :name => 'categoryCd', :op => 'IN' } => categoriesDerivedFromDT
                }
            )
            
            categoryCdDescHM = {}
            documentCdDescHM = {}
            documentCdObjHM = {}
            documentCdList = []
            docCategoryTypeLookup = Lookupvalue.getValue('DOCCATEGORYTYPE')
            docCategoryTypeLookup.each do |lookup|
                categoryCdDescHM[lookup.cd] = lookup.desc
            end
            documentCategoryM.each do |docCategory|
                # Validating minimum number of documents per category
                totalDocsPerCatg = 0
                container.ServiceDocumentList.each_with_index do |serviceDocument, index|
                    if serviceDocument.docCategoryCd.to_s == docCategory.categoryCd  && serviceDocument.removed.to_s != 'YES' && serviceDocument.selected.to_s == 'YES'
                        totalDocsPerCatg = index + 1
                    end
                end
                
                minNoOfDocuments = docCategory.minNoOfDocuments
                conditionFlag = totalDocsPerCatg < minNoOfDocuments.to_i
                
                if conditionFlag
                    unless $rhoconfig[:TABFEATUREREQD]
                        tempErrorHash = Hash.new
                        MobiSys::CommonUtil.addErrors(tempErrorHash, "minNoOfDocuments", "ERR_MINDOCUMENT", [minNoOfDocuments, categoryCdDescHM[docCategory.categoryTypeCd], lifeName])

                        errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                        errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = Hash.new if !errors[:ServiceDocumentDO][container.guid.to_s.to_sym].is_a?(Hash)
                        errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = errors[:ServiceDocumentDO][container.guid.to_s.to_sym].merge(tempErrorHash)
                    else
                        MobiSys::CommonUtil.registerException(container.policyGuid, "#{docCategory.categoryTypeCd}-docCategoryCd", "ERR_MINDOCUMENT", MobiSys::BrowserHelper.getLabel("ERR_MINDOCUMENT"), $currentTabId, [minNoOfDocuments, categoryCdDescHM[docCategory.categoryTypeCd], lifeName])
                    end
                end
                # Validating mandatory documents per category
                docCategory.DocumentCategoryMapList.each do |docCategoryMap|
                    documentCdDescHM[docCategoryMap.documentCd] = docCategoryMap.documentDesc
                    if docCategoryMap.isMandatoryFl.to_s == 'YES'
                        documentNotFound = true
                        container.ServiceDocumentList.each do |serviceDocument|
                            if serviceDocument.docCategoryCd.to_s == docCategoryMap.categoryCd && serviceDocument.documentCd.to_s == docCategoryMap.documentCd.to_s && serviceDocument.selected.to_s == 'YES' && serviceDocument.removed.to_s != 'YES'
                                documentNotFound = false
                                documentCdList.push(serviceDocument.documentCd.to_s)
                                break
                            end
                        end 
                        if documentNotFound
                            unless $rhoconfig[:TABFEATUREREQD]
                                tempErrorHash = Hash.new
                                MobiSys::CommonUtil.addErrors(tempErrorHash, "documentIsMandatory", "ERR_MANDATORYSERVICEDOC", [docCategoryMap.documentDesc, categoryCdDescHM[docCategory.categoryTypeCd] << ' ' << MobiSys::BrowserHelper.getLabel("categoryCd"), lifeName])
                                errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = Hash.new if !errors[:ServiceDocumentDO][container.guid.to_s.to_sym].is_a?(Hash)
                                errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = errors[:ServiceDocumentDO][container.guid.to_s.to_sym].merge(tempErrorHash)
                            else
                                MobiSys::CommonUtil.registerException(container.policyGuid, "#{container.guid}-documentIsMandatory", "ERR_MANDATORYSERVICEDOC", MobiSys::BrowserHelper.getLabel("ERR_MANDATORYSERVICEDOC"), $currentTabId, [docCategoryMap.documentDesc, categoryCdDescHM[docCategory.categoryTypeCd] << ' ' << MobiSys::BrowserHelper.getLabel("categoryCd"),lifeName])
                            end
                        end
                    else
                        container.ServiceDocumentList.each do |serviceDocument|
                            if serviceDocument.docCategoryCd.to_s == docCategoryMap.categoryCd && serviceDocument.documentCd.to_s == docCategoryMap.documentCd.to_s && serviceDocument.selected.to_s == 'YES' && serviceDocument.removed.to_s != 'YES'
                                documentCdList.push(serviceDocument.documentCd.to_s)
                                break
                            end
                        end
                    end
                end
            end

            # At least one image is mandatory, if any document is taken
            container.ServiceDocumentList.each_with_index do |serviceDocument, index|
                catgDesc = categoryCdDescHM[serviceDocument.docCategoryTypeCd].to_s + '-' + documentCdDescHM[serviceDocument.documentCd].to_s
                images = Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDocument.guid})
                imageListSize = images.size if images
                if (imageListSize.to_i < 1 ) && serviceDocument.removed.to_s != 'YES' && serviceDocument.selected.to_s == 'YES'
                    unless $rhoconfig[:TABFEATUREREQD]
                        tempErrorHash = Hash.new
                        MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_MANDATORYSERVICEDOC", [MobiSys::BrowserHelper.getLabel("documentImage"), catgDesc, lifeName])
                        errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                    else
                        MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_MANDATORYSERVICEDOC", "ERR_MANDATORYSERVICEDOC", $currentTabId, [MobiSys::BrowserHelper.getLabel("documentImage"), catgDesc, lifeName])
                    end
                end
                if serviceDocument.disableOcrFl.to_s != "YES"
                   validateServiceDocumentOcr(documentCdList, serviceDocument, container, policy, life, lifeName, catgDesc, errors)
                end
            end

        end
        ######################################################################################

        def self.validateBenficiaryAddressData(policy, errors)
            isValid = true
            nomineeList = policy.getPolicyPartyRoleList("NOMINEE")
            nomineePercentageBlank = false
            nomineePercentageNotBlank = false
            nomineeList.each do |nominee|
                if nominee.percentage == "" || nominee.percentage == nil
                    nomineePercentageBlank = true
                end 
                if nominee.percentage != nil && nominee.percentage != ""
                    nomineePercentageNotBlank = true
                end
            end 
            if(nomineePercentageBlank && nomineePercentageNotBlank)
                # MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-percentageNominee", "ERR_MANDATORY", "ERR_MANDATORY", nil, ["Share(%) for Beneficiary"])
            isValid = false
            end
            return isValid
        end

        # def self.validateMandatoryChildQuestion(questionSet, questionSetHash, responseHash, questionContainer, serviceQuestionResponse, parentRefPath, partyGuid, rowGuid,questionSetQuestionHash)
        #     isPositiveResp = false
        #     parentRefPath << "~#{questionSet.questionSetCd}" 
        #     if questionSetHash["listConditionalQuestionSetMapDOList"].size >= 3 && serviceQuestionResponse.responseValue.to_s == "0"
        #         questionSetHash["listConditionalQuestionSetMapDOList"].each do |condQuestMap|
        #             if condQuestMap && (condQuestMap[:reflexiveValue].to_s == "0" || condQuestMap[:reflexiveValue].to_s == "1")
        #                 questionSetQuestiondata = questionSetQuestionHash["#{condQuestMap[:childQuestionSetCd]}"]  
        #                 key = "#{questionSetQuestiondata.questionSetCd}|#{questionSetQuestiondata.dataElementCd}"
        #                 key << "|#{parentRefPath}" if parentRefPath.to_s != ""
        #                 key << "|#{partyGuid}" if partyGuid.to_s != ""
        #                 key << "|#{rowGuid}" if rowGuid.to_s != ""
        #                 childResp = responseHash[key]
        #                 if childResp && (childResp.responseValue.to_s == "0" || childResp.responseValue.to_s == "")
        #                     isPositiveResp = true
        #                     break
        #                 end
        #             end
        #         end
        #         unless isPositiveResp
        #             errorPlaceholder = MobiSys::BrowserHelper.getLabel("#{serviceQuestionResponse.questionSetCd}_#{serviceQuestionResponse.questionDataElementCd}_lbl")
        #             MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_MAXLENGTH", "At least One Positive answer is required for {1}", nil, [errorPlaceholder])
        #         end
        #     end
        # end

        ############
        def self.validateProductWithdraw(policy,errors)
          isValid = true
          basePlan = policy.getBaseProduct
          if basePlan && basePlan.productSeq.to_s != ""
            product = MobiSys::ProductUtil.getProduct(basePlan.productSeq)
            if product && product.withdrawDt.to_s != ""
              system_date = Date.parse(Time.now.to_s)
                withdrawn_date = Date.parse(product.withdrawDt.to_s)
                if withdrawn_date < system_date
                  p "inside validate****policy*********"
                  MobiSys::CommonUtil.registerException(policy.guid, "#{basePlan.guid}-productId", "ERR_PRDLAUNCH", "ERR_PRDLAUNCH", nil,[product.longName, product.productVersion])
                isValid = false
                end
            end
          end
          return isValid
        end
        ############


        def self.individualCaseFnaIdMissing(policy,errors)
          policyHolder = policy.getPartyByRole('PROPOSER')
          csaAppToParty = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"CSAAPPTOPARTY"})
          if csaAppToParty && csaAppToParty.actionValue.include?(policyHolder.partyTypeCd.to_s) && policy.fnaId.to_s == ""
             MobiSys::CommonUtil.registerException(policy.guid, "#{policyHolder.guid}-names", "ERR_FNARECORDMISSING", "ERR_FNARECORDMISSING", nil, [])
          end
        end

        ############ added the validation bank code and reffral code ############  
        def self.agentBancaCodeCheck(policy,errors)
            isValidated = true
            bankCodeQuestionResponseDO = nil
            refrrerCodeQuestionResponseDO = nil
            container = QuestionContainer.loadObject(
                :first, 
                :conditions=>{
                    {:name => 'entityGuid'} => policy.guid,
                    {:name => 'entityTypeCd'} => "AGENT"
                },
                :op => "AND"
            )
            # 👉 If container is nil, skip further checks
            return false if container.nil?

            list = Array(container.ServiceQuestionResponseList)
            puts "++++++++++container.ServiceQuestionResponseList++++++>>>>#{container.ServiceQuestionResponseList}"
            if list.size > 0
                container.ServiceQuestionResponseList.each do |questionResponseDO|
                  if questionResponseDO.questionnaireTypeCd.to_s == "AGENT"
                    if questionResponseDO.questionSetCd != nil && questionResponseDO.questionDataElementCd != nil && questionResponseDO.responseValue != nil
                         puts "inside i am  111"
                      if questionResponseDO.questionSetCd.to_s == "BancaAdQues1" && questionResponseDO.questionDataElementCd.to_s == "adquesadvinfb" # branchCode
                        bankCodeQuestionResponseDO = questionResponseDO
                      elsif questionResponseDO.questionSetCd.to_s == "BancaAdQues2" && questionResponseDO.questionDataElementCd.to_s =="adquesadvinfb" # ReferrerCode
                        refrrerCodeQuestionResponseDO = questionResponseDO
                      end
                    end
                  end
                end
            end

            # puts "+++++++++++++++bankCodeQuestionResponseDO+++++++++++++++++++#{bankCodeQuestionResponseDO}"
            # puts "+++++++++++++++refrrerCodeQuestionResponseDO+++++++++++++++++++#{refrrerCodeQuestionResponseDO}"

            if bankCodeQuestionResponseDO != nil
                bankresponseValue = bankCodeQuestionResponseDO.responseValue.to_s
                if bankresponseValue.length != 6
                  MobiSys::CommonUtil.registerException(policy.guid, "#{bankCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Bank Code", "BXXXXX"])

                elsif !bankresponseValue.upcase.start_with?("B")
                  MobiSys::CommonUtil.registerException(policy.guid, "#{bankCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Bank Code", "BXXXXX"])
                end
            end

            if refrrerCodeQuestionResponseDO != nil
                refresponseValue = refrrerCodeQuestionResponseDO.responseValue.to_s
                if refresponseValue.length != 6
                  MobiSys::CommonUtil.registerException(policy.guid, "#{refrrerCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Referrer Code", "RXXXXX"])
                elsif !refresponseValue.upcase.start_with?("R")
                  MobiSys::CommonUtil.registerException(policy.guid, "#{refrrerCodeQuestionResponseDO.guid}-responseValue", "ERR_AGENTCODE", "ERR_AGENTCODE", nil, ["Referrer Code", "RXXXXX"])
                end
            end

          return isValidated
        end

        def self.validateAgentLicense(policy,errors)
          if (policy.to_s !="" && policy.baseAgentId.to_s !="" && policy.baseProductFamilyCd.to_s !="")
            isLicenseValid = agentLicenseCheck(policy.baseAgentId, policy.baseProductFamilyCd)
            unless isLicenseValid
              MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-names", "ERR_VALIDLICENSE", "ERR_VALIDLICENSE", nil, [])
            end
          end
        end

        def self.agentLicenseCheck(agentId, productFamilyCd)
          agentReg = AgentReg.find(:first, :conditions =>{{:name =>'agentId'} =>agentId})
          productFamily = productFamilyCd.to_s.upcase

          tradLicenseStartDate = agentReg.field15 
          tradLicenseEndDate   = agentReg.agentField14 
          vulLicenseStartDate  = agentReg.agentField15 
          vulLicenseEndDate    = agentReg.agentField16 

          if (productFamily.to_s == "TRAD" && !licenseValid(tradLicenseStartDate, tradLicenseEndDate)) 
            return false;
          elsif (productFamily.to_s == "VUL" && !licenseValid(vulLicenseStartDate, vulLicenseEndDate))
            return false;
          end
          return true;
        end

        def self.licenseValid(startDate, endDate)
            begin
                dateFormat = '%d-%b-%Y'
                today = Date.today

                # Treat nil and blank strings as nil
                startDate = nil if startDate.nil? || startDate.to_s.strip.empty?
                endDate = nil if endDate.nil? || endDate.to_s.strip.empty?

                # Both dates are missing
                return false if startDate.nil? && endDate.nil?

                # Only end date is available
                if startDate.nil?
                  endDateValue = Date.strptime(endDate, dateFormat)
                  return today <= endDateValue
                end

                # Only start date is available
                if endDate.nil?
                  startDateValue = Date.strptime(startDate, dateFormat)
                  return today >= startDateValue
                end

                # Both dates are available
                startDateValue = Date.strptime(startDate, dateFormat)
                endDateValue = Date.strptime(endDate, dateFormat)

                today >= startDateValue && today <= endDateValue

            rescue => e
                p "isLicenseValid ERROR: #{e.class} - #{e.message}"
                false
            end
        end


        #11-06-2026: DPHSS-11503/11504- No UW limit validation upon removing MDRT and SLU tagging
        def self.validateMedExQuestion(policy, errors)
            isValidated = true
            proposer = policy.getParty("PROPOSER")
            if policy.quoteProposerSameAsInsured.to_s != "YES"
                insured = policy.getParty("PRIMARY")
            end
            proposer_guid = proposer.guid.to_s if proposer
            primary_guid  = insured.guid.to_s if insured
            rowGuidArrayMedExIns          = []
            rowGuidArrayMedExOwn          = []
            serviceQuestionResponseHMInsu = {}
            serviceQuestionResponseHMOwn  = {}
            container = QuestionContainer.loadObject(
                :first,
                :conditions => {
                    {:name => 'entityGuid'} => policy.guid,
                    {:name => 'policyGuid'} => policy.guid
                },
                :op => 'OR'
            )
            return isValidated if container.nil?
            list = Array(container.ServiceQuestionResponseList)
            return isValidated if list.empty?
            container.ServiceQuestionResponseList.each do |serviceQuesResponse|
                if serviceQuesResponse.partyGuid.to_s != "" && !serviceQuesResponse.questionDataElementCd.to_s.upcase.include?("CLASS")
                    if serviceQuesResponse.questionSetCd.to_s.include?("quesreqdetinsa") ||
                       serviceQuesResponse.questionSetCd.to_s.include?("quesreqdetinsanew")
                        if serviceQuesResponse.partyGuid.to_s == primary_guid.to_s
                            if serviceQuesResponse.questionDataElementCd.to_s.include?("quesreqdetinsba") && 
                               serviceQuesResponse.responseValue.to_s != "" && 
                               serviceQuesResponse.responseValue.to_s == "N"
                                if policy.quotAddtnlField3.to_s != "" &&
                                   policy.quotAddtnlField3.to_s == "1"
                                    MobiSys::CommonUtil.registerException(
                                        policy.guid,
                                        "#{serviceQuesResponse.guid}-responseValue",
                                        "ERR_MANDATORYMEDEX1",
                                        "ERR_MANDATORYMEDEX1",
                                        nil, []
                                    )
                                end
                            end
                            if serviceQuesResponse.rowGuid.to_s != ""
                                rowGuidArrayMedExIns << serviceQuesResponse.rowGuid.to_s
                                serviceQuestionResponseHMInsu["#{serviceQuesResponse.questionDataElementCd}_#{serviceQuesResponse.rowGuid}"] = serviceQuesResponse
                            end
                        elsif serviceQuesResponse.partyGuid.to_s == proposer_guid.to_s
                            if serviceQuesResponse.questionDataElementCd.to_s.include?("quesreqdetinsba") &&
                               serviceQuesResponse.responseValue.to_s != "" &&
                               serviceQuesResponse.responseValue.to_s == "N"
                                if policy.quotAddtnlField4.to_s != "" &&
                                   policy.quotAddtnlField4.to_s == "2"
                                    MobiSys::CommonUtil.registerException(
                                        policy.guid,
                                        "#{serviceQuesResponse.guid}-responseValue",
                                        "ERR_MANDATORYMEDEX2",
                                        "ERR_MANDATORYMEDEX2",
                                        nil, []
                                    )
                                elsif policy.quotAddtnlField4.to_s != "" &&
                                      policy.quotAddtnlField4.to_s == "3"
                                    MobiSys::CommonUtil.registerException(
                                        policy.guid,
                                        "#{serviceQuesResponse.guid}-responseValue",
                                        "ERR_MANDATORYMEDEX3",
                                        "ERR_MANDATORYMEDEX3",
                                        nil, []
                                    )
                                end
                            end
                            if serviceQuesResponse.rowGuid.to_s != ""
                                rowGuidArrayMedExOwn << serviceQuesResponse.rowGuid.to_s
                                serviceQuestionResponseHMOwn["#{serviceQuesResponse.questionDataElementCd}_#{serviceQuesResponse.rowGuid}"] = serviceQuesResponse
                            end
                        end
                    end
                end
            end

            if policy.quotAddtnlField3.to_s != "" && policy.quotAddtnlField3.to_s == "1"
                if !rowGuidArrayMedExIns.empty? && !serviceQuestionResponseHMInsu.empty?
                    rowGuidArrayCountIns = rowGuidArrayMedExIns.uniq.sort
                    medExListIns = []
                    rowGuidArrayCountIns.each do |i|
                        resp = serviceQuestionResponseHMInsu["quesreqdetinsbbc_#{i}"]
                        medExListIns << (resp ? resp.responseValue.to_s : "")
                    end
                    if !medExListIns.empty?
                        if !medExListIns.include?("MEDICALEXAMINATION")
                            responseDO   = serviceQuestionResponseHMInsu["quesreqdetinsbbc_0"]
                            responseGuid = responseDO ? responseDO.guid.to_s : ""
                            MobiSys::CommonUtil.registerException(
                                policy.guid,
                                "#{responseGuid}-responseValue",
                                "ERR_MANDATORYMEDEX1",
                                "ERR_MANDATORYMEDEX1",
                                nil, []
                            )
                        end
                    end
                end
            end

            if policy.quotAddtnlField4.to_s != "" &&
               !rowGuidArrayMedExOwn.empty? &&
               !serviceQuestionResponseHMOwn.empty?
                if policy.quotAddtnlField4.to_s == "2" ||
                   policy.quotAddtnlField4.to_s == "3"
                    rowGuidArrayCountOwn = rowGuidArrayMedExOwn.uniq.sort
                    medExListOwn = []
                    rowGuidArrayCountOwn.each do |i|
                        resp = serviceQuestionResponseHMOwn["quesreqdetinsbbc_#{i}"]
                        medExListOwn << (resp ? resp.responseValue.to_s : "")
                    end
                    if !medExListOwn.empty?
                        if !medExListOwn.include?("MEDICALEXAMINATION")
                            responseDO   = serviceQuestionResponseHMOwn["quesreqdetinsbbc_0"]
                            responseGuid = responseDO ? responseDO.guid.to_s : ""
                            if policy.quotAddtnlField4.to_s != "" &&
                               policy.quotAddtnlField4.to_s == "2"
                                MobiSys::CommonUtil.registerException(
                                    policy.guid,
                                    "#{responseGuid}-responseValue",
                                    "ERR_MANDATORYMEDEX2",
                                    "ERR_MANDATORYMEDEX2",
                                    nil, []
                                )
                            elsif policy.quotAddtnlField4.to_s != "" &&
                                  policy.quotAddtnlField4.to_s == "3"
                                MobiSys::CommonUtil.registerException(
                                    policy.guid,
                                    "#{responseGuid}-responseValue",
                                    "ERR_MANDATORYMEDEX3",
                                    "ERR_MANDATORYMEDEX3",
                                    nil, []
                                )
                            end
                        end
                    end
                end
            end

            return isValidated
        end
    end
end
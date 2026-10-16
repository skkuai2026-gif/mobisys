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


        ################################################################################
        #-----------------Code based on Validation Metadata Sheet Start----------------#
        ################################################################################
  
        def self.convertToQuotation(policy,loadQuestionContainer=true)
            quotation = Quotation.new
            quotation.intimationSourceCd = policy.intimationSourceCd
            quotation.quotationDt = policy.riskCommencementDt
            quotation.isBackdatedFl = policy.isBackdatedFl
            quotation.guid = policy.guid
            quotation.insuranceTypeCd = policy.insuranceTypeCd

            quotation.tripTypeCd = policy.tripTypeCd
            quotation.maxTripPeriod = policy.maxTripPeriod
            quotation.travelGeographyCd = policy.travelGeographyCd
            quotation.visitPurposeCd = policy.visitPurposeCd
            quotation.numberOfAdult = policy.numberOfAdult
            quotation.numberOfChildren = policy.numberOfChildren
            quotation.startDt = policy.startDt
            quotation.endDt = policy.endDt
            quotation.coverTypeCd = policy.coverTypeCd

            quotation.quotAddtnlField1 = policy.quotAddtnlField1
            quotation.quotAddtnlField2 = policy.quotAddtnlField2
            quotation.quotAddtnlField3 = policy.quotAddtnlField3
            quotation.quotAddtnlField4 = policy.quotAddtnlField4
            quotation.quotAddtnlField5 = policy.quotAddtnlField5
            quotation.quotAddtnlField6 = policy.quotAddtnlField6
            quotation.quotAddtnlField7 = policy.quotAddtnlField7
            quotation.quotAddtnlField8 = policy.quotAddtnlField8
            quotation.quotAddtnlField9 = policy.quotAddtnlField9
            quotation.quotAddtnlField10 = policy.quotAddtnlField10
            quotation.quotAddtnlField11 = policy.quotAddtnlField11
            quotation.quotAddtnlField12 = policy.quotAddtnlField12
            
            quotation.uploadFlag = policy.uploadFlag
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
                pqp.partyTypeCd = proposer.partyTypeCd
                pqp.title = proposer.titleCd
                pqp.otherTitle = proposer.otherTitle
                pqp.firstname = proposer.firstName1
                pqp.lastname = proposer.lastName1
                pqp.age = proposer.age
                pqp.genderCd = proposer.genderCd
                pqp.smoker = proposer.smoker
                pqp.nsap = proposer.nonResidentFl
                if proposer.PartyEmploymentList[0]
                    pqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass
                    pqp.industryCd = proposer.PartyEmploymentList[0].industryCd
                    pqp.natureOfDuty = proposer.PartyEmploymentList[0].natureOfDuty

                end
                if proposer.getPartyContact("MOBILE")
                    pqp.contactNum = proposer.getPartyContact("MOBILE").contactNum
                end
                if proposer.getPartyEmail
                    if proposer.getPartyEmail.emailAddress.to_s != ''
                        pqp.emailAddress = proposer.getPartyEmail.emailAddress
                    end
                end
                ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                  partyAddress = pqp.getAddress(addressType.to_s, true)
                  proposerAddress = proposer.getPartyAddress(addressType.to_s)
                  if proposerAddress
                      partyAddress.addressLine1Lang1 = proposerAddress.addressLine1Lang1
                      partyAddress.addressLine2Lang1 = proposerAddress.addressLine2Lang1
                      partyAddress.addressLine3Lang1 = proposerAddress.addressLine3Lang1
                      partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                      partyAddress.countryCd = proposerAddress.countryCd
                      partyAddress.pinCode = proposerAddress.pinCode
                      partyAddress.stateCd = proposerAddress.stateCd
                      partyAddress.cityCd = proposerAddress.cityCd
                  end
                  partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                end
                pqp.dob = proposer.birthDt
                pqp.citizenshipCd = proposer.citizenshipCd
                pqp.nationality = proposer.citizenshipCd
                pqp.roleCd = proposer.roleCd
                pqp.guid = proposer.guid
                pqp.monthlyIncome = proposer.monthlyIncome
                pqp.annualIncome = proposer.annualIncome
                pqp.maritalStatus = proposer.maritalStatusCd
                pqp.quotPartyAddtnField1 = proposer.quotPartyAddtnField1
                pqp.quotPartyAddtnField2 = proposer.quotPartyAddtnField2
                pqp.quotPartyAddtnField3 = proposer.quotPartyAddtnField3
                pqp.quotPartyAddtnField4 = proposer.quotPartyAddtnField4
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
                    quotation.proposerLASame="COPYFROMINSURED"
                    iqp.age = proposer.age
                    iqp.partyTypeCd = proposer.partyTypeCd
                    iqp.title = proposer.titleCd
                    iqp.otherTitle = proposer.otherTitle
                    iqp.genderCd = proposer.genderCd
                    iqp.smoker = proposer.smoker
                    iqp.nsap = proposer.nonResidentFl
                    iqp.relationCd = "SELF"                    
  	                if proposer.PartyEmploymentList[0]
  	                    iqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass
                        iqp.industryCd = proposer.PartyEmploymentList[0].industryCd
                        iqp.natureOfDuty = proposer.PartyEmploymentList[0].natureOfDuty
  	                end
                    if proposer.getPartyContact("MOBILE")
                        iqp.contactNum = proposer.getPartyContact("MOBILE").contactNum
                    end
                    if proposer.getPartyEmail
                        if proposer.getPartyEmail.emailAddress.to_s != ""
                            iqp.emailAddress = proposer.getPartyEmail.emailAddress
                        end
                    end
                    iqp.dob = proposer.birthDt
                    iqp.firstname=proposer.firstName1
                    iqp.lastname=proposer.lastName1
                    iqp.citizenshipCd=proposer.citizenshipCd
                    iqp.nationality=proposer.citizenshipCd
                    iqp.roleCd="PRIMARY"
                    iqp.monthlyIncome = proposer.monthlyIncome
                    iqp.annualIncome = proposer.annualIncome
                    iqp.guid = proposer.guid
                    iqp.maritalStatus = proposer.maritalStatusCd
                    iqp.quotPartyAddtnField1 = proposer.quotPartyAddtnField1
                    iqp.quotPartyAddtnField2 = proposer.quotPartyAddtnField2
                    iqp.quotPartyAddtnField3 = proposer.quotPartyAddtnField3
                    iqp.quotPartyAddtnField4 = proposer.quotPartyAddtnField4
                    quotation.quotAddtnlField1 = "YES"
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = iqp.getAddress(addressType.to_s, true)
                      proposerAddress = proposer.getPartyAddress(addressType.to_s)
                      if proposerAddress
                          partyAddress.addressLine1Lang1 = proposerAddress.addressLine1Lang1
                          partyAddress.addressLine2Lang1 = proposerAddress.addressLine2Lang1
                          partyAddress.addressLine3Lang1 = proposerAddress.addressLine3Lang1
                          partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                          partyAddress.countryCd = proposerAddress.countryCd
                          partyAddress.pinCode = proposerAddress.pinCode
                          partyAddress.stateCd = proposerAddress.stateCd
                          partyAddress.cityCd = proposerAddress.cityCd
                      end
                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    end
                else
                    quotation.proposerLASame=""
                    iqp.age = insured.age
                    iqp.partyTypeCd = insured.partyTypeCd
                    iqp.title = insured.titleCd
                    iqp.otherTitle = insured.otherTitle
                    iqp.genderCd = insured.genderCd
                    iqp.smoker = insured.smoker
                    iqp.nsap = insured.nonResidentFl
                    iqp.relationCd = insured.relationCd                 
                    if insured.PartyEmploymentList[0]
                        iqp.occupationCd = insured.PartyEmploymentList[0].occupationClass
                        iqp.industryCd = insured.PartyEmploymentList[0].industryCd
                        iqp.natureOfDuty = insured.PartyEmploymentList[0].natureOfDuty
                    end
                    if insured.getPartyContact("MOBILE")
                        iqp.contactNum = insured.getPartyContact("MOBILE").contactNum
                    end
                    if insured.getPartyEmail
                        iqp.emailAddress = insured.getPartyEmail.emailAddress
                    end
                    iqp.dob = insured.birthDt
                    iqp.firstname=insured.firstName1
                    iqp.lastname=insured.lastName1
                    iqp.citizenshipCd=insured.citizenshipCd
                    iqp.nationality=insured.citizenshipCd
                    iqp.roleCd=insured.roleCd
                    iqp.monthlyIncome = insured.monthlyIncome
                    iqp.annualIncome = insured.annualIncome
                    iqp.guid = insured.guid
                    iqp.maritalStatus = insured.maritalStatusCd
                    iqp.quotPartyAddtnField1 = insured.quotPartyAddtnField1
                    iqp.quotPartyAddtnField2 = insured.quotPartyAddtnField2
                    iqp.quotPartyAddtnField3 = insured.quotPartyAddtnField3
                    iqp.quotPartyAddtnField4 = insured.quotPartyAddtnField4
                    quotation.quotAddtnlField1 = "NO"
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = iqp.getAddress(addressType.to_s, true)
                      proposerAddress = insured.getPartyAddress(addressType.to_s)
                      if proposerAddress
                          partyAddress.addressLine1Lang1 = proposerAddress.addressLine1Lang1
                          partyAddress.addressLine2Lang1 = proposerAddress.addressLine2Lang1
                          partyAddress.addressLine3Lang1 = proposerAddress.addressLine3Lang1
                          partyAddress.addressLine4Lang1 = proposerAddress.addressLine4
                          partyAddress.countryCd = proposerAddress.countryCd
                          partyAddress.pinCode = proposerAddress.pinCode
                          partyAddress.stateCd = proposerAddress.stateCd
                          partyAddress.cityCd = proposerAddress.cityCd
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
                jqp.partyTypeCd = joint.partyTypeCd
                jqp.title = joint.titleCd
                jqp.otherTitle = joint.otherTitle
                jqp.firstname = joint.firstName1
                jqp.lastname = joint.lastName1
                jqp.age = joint.age
                jqp.genderCd = joint.genderCd
                jqp.smoker = joint.smoker
                jqp.nsap = joint.nonResidentFl
                jqp.relationCd = joint.relationCd
                if joint.PartyEmploymentList[0]
                    jqp.occupationCd = joint.PartyEmploymentList[0].occupationClass
                    jqp.industryCd = joint.PartyEmploymentList[0].industryCd
                    jqp.natureOfDuty = joint.PartyEmploymentList[0].natureOfDuty
                end
                if joint.getPartyContact("MOBILE")
                    jqp.contactNum = joint.getPartyContact("MOBILE").contactNum
                end
                if joint.getPartyEmail
                    jqp.emailAddress = joint.getPartyEmail.emailAddress
                end
                jqp.dob = joint.birthDt
                jqp.citizenshipCd = joint.citizenshipCd
                jqp.nationality = joint.citizenshipCd
                jqp.roleCd = joint.roleCd
                jqp.guid = joint.guid
                jqp.monthlyIncome = joint.monthlyIncome
                jqp.annualIncome = joint.annualIncome
                jqp.maritalStatus = joint.maritalStatusCd
                jqp.quotPartyAddtnField1 = joint.quotPartyAddtnField1
                jqp.quotPartyAddtnField2 = joint.quotPartyAddtnField2
                jqp.quotPartyAddtnField3 = joint.quotPartyAddtnField3
                jqp.quotPartyAddtnField4 = joint.quotPartyAddtnField4
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

            #Deepali Singh: 25-08-2015 - Separating logic for base paln and rider, PolicyProductInvestmentFund is only for plan not for rider
            basePlan = policy.getBaseProduct
            if basePlan
                quotationProduct = QuotationProduct.new
                quotation.addQuotationProduct(quotationProduct)

                quotationProduct.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                quotationProduct.productId = basePlan.productId
                quotationProduct.productVersion = basePlan.productVersion
                quotationProduct.productSeq = basePlan.productSeq
                quotationProduct.parentproductSeq = basePlan.parentproductSeq
                quotationProduct.productTypeCd = basePlan.productTypeCd 
                quotationProduct.productFamilyCd = basePlan.productFamilyCd 
                quotationProduct.baseSumAssured = basePlan.baseSumAssured
                quotationProduct.baseAnnualPremium = basePlan.baseAnnualPremium 
                quotationProduct.modalPremium = basePlan.modalPremium
                quotationProduct.capturedPremiumAmt = basePlan.capturedPremiumAmt 
                quotationProduct.productTerm = basePlan.productTerm 
                quotationProduct.premiumPayingTerm = basePlan.premiumPayingTerm 
                quotationProduct.annualizedPremium = basePlan.annualizedPremium 
                quotationProduct.totAnnualizedPremium = basePlan.totAnnualizedPremium
                quotationProduct.vestingAge = basePlan.vestingAge
                quotationProduct.annuityAge = basePlan.annuityAge
                quotationProduct.annuityPerc = basePlan.annuityPerc
                quotationProduct.extraPremium = basePlan.extraPremium
                quotationProduct.maxTargetPremium = basePlan.maxTargetPremium
                quotationProduct.minTargetPremium = basePlan.minTargetPremium
                quotationProduct.recommendedPremium = basePlan.recommendedPremium
                quotationProduct.unapliedPremium = basePlan.unapliedPremium
                quotationProduct.linkedFl = basePlan.linkedFl
                quotationProduct.pdfRequiredFl = basePlan.pdfRequiredFl
                quotationProduct.topUpAllocSameAsPremAllocFl = basePlan.topUpAllocSameAsPremAllocFl
                quotationProduct.targetFundFl = basePlan.targetFundFl
                quotationProduct.builtInRiderFl = basePlan.builtInRiderFl
                quotationProduct.guid = basePlan.guid
                quotationProduct.premiumSAFl = basePlan.premiumSAFl
                quotationProduct.payoutFrequencyCd = basePlan.payoutFrequencyCd

                # every time get copied From Base Plan
                quotationProduct.paymentFrequencyCd = basePlan.paymentFrequencyCd
                quotationProduct.currencyCd = basePlan.currencyCd
                quotationProduct.paymentTypeCd = basePlan.paymentTypeCd
                quotationProduct.minTargetPremium = basePlan.minTargetPremium

                quotationProduct.productPlanOptionCd = basePlan.productPlanOptionCd 
                quotationProduct.planCode = basePlan.planCode 
                quotationProduct.productSeq = basePlan.productSeq
                quotationProduct.coi = basePlan.coi 

                quotationProduct.combinedEntryAge = basePlan.combinedEntryAge
                quotationProduct.portfolioModelCd = basePlan.portfolioModelCd
                quotationProduct.holderRefGuid = basePlan.object
                quotationProduct.selected = basePlan.selected

                quotationProduct.addtnField1 = basePlan.addtnField1 
                quotationProduct.addtnField2 = basePlan.addtnField2 
                quotationProduct.addtnField3 = basePlan.addtnField3 
                quotationProduct.addtnField4 = basePlan.addtnField4 
                quotationProduct.addtnField5 = basePlan.addtnField5 
                quotationProduct.addtnField6 = basePlan.addtnField6 
                # Extra Loading And Duration 
                quotationProduct.flatExtra = basePlan.flatExtra
                #quotationProduct.emr = basePlan.emr 

                quotationProduct.wopPremium = basePlan.wopPremium
                quotationProduct.wopPremium2 = basePlan.wopPremium2
                quotationProduct.wopPremiumQuarterly = basePlan.wopPremiumQuarterly
                quotationProduct.wopPremiumHalfYearly = basePlan.wopPremiumHalfYearly
                quotationProduct.wopPremiumMonthly = basePlan.wopPremiumMonthly
                quotationProduct.wopPremium2Quarterly = basePlan.wopPremium2Quarterly
                quotationProduct.wopPremium2HalfYearly = basePlan.wopPremium2HalfYearly
                quotationProduct.wopPremium2Monthly = basePlan.wopPremium2Monthly
                quotationProduct.wopPremium3 = basePlan.wopPremium3
                quotationProduct.wopPremium3Quarterly = basePlan.wopPremium3Quarterly
                quotationProduct.wopPremium3HalfYearly = basePlan.wopPremium3HalfYearly
                quotationProduct.wopPremium3Monthly = basePlan.wopPremium3Monthly
                quotationProduct.wopPremiumField = basePlan.wopPremiumField
                quotationProduct.wopPremiumField2 = basePlan.wopPremiumField2
                quotationProduct.wopPremiumField3 = basePlan.wopPremiumField3

                quotationProduct.sortOrder = basePlan.sortOrder
                quotationProduct.paidUpFl = basePlan.paidUpFl

                basePlan.PolicyProductInsuredList.each do|policyProductInsured|
                    quotationProduct.partyRoleCd = policyProductInsured.roleCd
                    quotationProduct.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                end

                basePlan.PolicyProductExtraList.each do|policyProductExtra|
                	quotationProductExtra = QuotationProductExtra.new
                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
                    quotationProduct.addQuotationProductExtra(quotationProductExtra)
                end

                basePlan.PolicyProductInvestmentFundList.each do|fund|
                	next if fund.removed.to_s == "YES"
                    quotationFund = QuotationProductInvestmentFund.new
                    quotationFund.fundCd = fund.fundCd
                    quotationFund.allocationPerc = fund.allocationPerc
                    quotationFund.guid = fund.guid
                    quotationFund.topupAllocationPerc = fund.topupAllocationPerc
                    quotationFund.expiryDt = fund.expiryDt
                    quotationFund.fundTypeCd = fund.fundTypeCd
                    quotationFund.maturityDt = fund.maturityDt
                    quotationProduct.addQuotationProductInvestmentFund(quotationFund)
                end

                basePlan.PolicyProductAdditionalList.each do |policyProductAdditional| 
                    quotationProductAdditional = QuotationProductAdditional.new
                    quotationProductAdditional.prdAddtnField1str = policyProductAdditional.prdAddtnField1str
                    quotationProductAdditional.prdAddtnField2str = policyProductAdditional.prdAddtnField2str
                    quotationProductAdditional.prdAddtnField3str = policyProductAdditional.prdAddtnField3str
                    quotationProductAdditional.prdAddtnField4str = policyProductAdditional.prdAddtnField4str
                    quotationProductAdditional.prdAddtnField5str = policyProductAdditional.prdAddtnField5str
                    quotationProductAdditional.prdAddtnField6d = policyProductAdditional.prdAddtnField6d
                    quotationProductAdditional.prdAddtnField7d = policyProductAdditional.prdAddtnField7d
                    quotationProductAdditional.prdAddtnField8d = policyProductAdditional.prdAddtnField8d
                    quotationProductAdditional.prdAddtnField9d = policyProductAdditional.prdAddtnField9d
                    quotationProductAdditional.prdAddtnField10d = policyProductAdditional.prdAddtnField10d
                    quotationProductAdditional.prdAddtnField11d = policyProductAdditional.prdAddtnField11d
                    quotationProductAdditional.prdAddtnField12d = policyProductAdditional.prdAddtnField12d
                    quotationProductAdditional.prdAddtnField13d = policyProductAdditional.prdAddtnField13d
                    quotationProductAdditional.prdAddtnField14d = policyProductAdditional.prdAddtnField14d
                    quotationProductAdditional.prdAddtnField15d = policyProductAdditional.prdAddtnField15d
                    quotationProductAdditional.prdAddtnField16dt = policyProductAdditional.prdAddtnField16dt
                    quotationProductAdditional.prdAddtnField17dt = policyProductAdditional.prdAddtnField17dt
                    quotationProductAdditional.prdAddtnField18dt = policyProductAdditional.prdAddtnField18dt
                    quotationProductAdditional.prdAddtnField19dt = policyProductAdditional.prdAddtnField19dt
                    quotationProductAdditional.prdAddtnField20dt = policyProductAdditional.prdAddtnField20dt
                    quotationProductAdditional.productRefGuid = policyProductAdditional.productRefGuid
                end
            end

            policy.PolicyProductList.each do |policyRider|
                if policyRider.productTypeCd == "RIDER"
                    quotationRider = QuotationProduct.new(:productTypeCd => "RIDER")
                    quotation.addQuotationProduct(quotationRider)
                    quotationRider.product = MobiSys::ProductUtil.getProduct(policyRider.productSeq)
                    quotationRider.productId = policyRider.productId
                    quotationRider.productVersion = policyRider.productVersion
                    quotationRider.productSeq = policyRider.productSeq
                    quotationRider.parentproductSeq = policyRider.parentproductSeq
                    quotationRider.productTypeCd = policyRider.productTypeCd 
                    quotationRider.productFamilyCd = policyRider.productFamilyCd 
                    quotationRider.baseSumAssured = policyRider.baseSumAssured
                    quotationRider.baseAnnualPremium = policyRider.baseAnnualPremium 
                    quotationRider.modalPremium = policyRider.modalPremium
                    quotationRider.capturedPremiumAmt = policyRider.capturedPremiumAmt 
                    quotationRider.productTerm = policyRider.productTerm 
                    quotationRider.premiumPayingTerm = policyRider.premiumPayingTerm 
                    quotationRider.annualizedPremium = policyRider.annualizedPremium 
                    quotationRider.totAnnualizedPremium = policyRider.totAnnualizedPremium
	                quotationRider.vestingAge = policyRider.vestingAge
	                quotationRider.annuityPerc = policyRider.annuityPerc
                    quotationRider.extraPremium = policyRider.extraPremium
                    quotationRider.maxTargetPremium = policyRider.maxTargetPremium
                    quotationRider.minTargetPremium = policyRider.minTargetPremium
                    quotationRider.recommendedPremium = policyRider.recommendedPremium
                    quotationRider.unapliedPremium = policyRider.unapliedPremium
                    quotationRider.linkedFl = policyRider.linkedFl
                    quotationRider.pdfRequiredFl = policyRider.pdfRequiredFl
                    quotationRider.topUpAllocSameAsPremAllocFl = policyRider.topUpAllocSameAsPremAllocFl
                    quotationRider.targetFundFl = policyRider.targetFundFl
                    quotationRider.builtInRiderFl = policyRider.builtInRiderFl
                    quotationRider.guid = policyRider.guid
                    quotationRider.premiumSAFl = policyRider.premiumSAFl
                    quotationRider.productLongName = policyRider.productLongName

                    # every time get copied From Base Plan
                    quotationRider.paymentFrequencyCd = policyRider.paymentFrequencyCd
                    quotationRider.currencyCd = policyRider.currencyCd
                    quotationRider.paymentTypeCd = policyRider.paymentTypeCd
                    quotationProduct.minTargetPremium = policyRider.minTargetPremium

                    quotationRider.productPlanOptionCd = policyRider.productPlanOptionCd 
                    quotationRider.planCode = policyRider.planCode 
                    quotationRider.productSeq = policyRider.productSeq
                    quotationRider.coi = policyRider.coi 

                    quotationRider.combinedEntryAge = policyRider.combinedEntryAge
                    quotationRider.portfolioModelCd = policyRider.portfolioModelCd
                    quotationRider.holderRefGuid = policyRider.object
                    quotationRider.selected = policyRider.selected

                    quotationRider.addtnField1 = policyRider.addtnField1 
                    quotationRider.addtnField2 = policyRider.addtnField2 
                    quotationRider.addtnField3 = policyRider.addtnField3 
                    quotationRider.addtnField4 = policyRider.addtnField4 
                    quotationRider.addtnField5 = policyRider.addtnField5 
                    quotationRider.addtnField6 = policyRider.addtnField6 
                    # Extra Loading And Duration 
                    quotationRider.flatExtra = policyRider.flatExtra

                    quotationRider.wopPremium = policyRider.wopPremium
                    quotationRider.wopPremium2 = policyRider.wopPremium2
                    quotationRider.wopPremiumQuarterly = policyRider.wopPremiumQuarterly
                    quotationRider.wopPremiumHalfYearly = policyRider.wopPremiumHalfYearly
                    quotationRider.wopPremiumMonthly = policyRider.wopPremiumMonthly
                    quotationRider.wopPremium2Quarterly = policyRider.wopPremium2Quarterly
                    quotationRider.wopPremium2HalfYearly = policyRider.wopPremium2HalfYearly
                    quotationRider.wopPremium2Monthly = policyRider.wopPremium2Monthly
                    quotationRider.wopPremium3 = policyRider.wopPremium3
                    quotationRider.wopPremium3Quarterly = policyRider.wopPremium3Quarterly
                    quotationRider.wopPremium3HalfYearly = policyRider.wopPremium3HalfYearly
                    quotationRider.wopPremium3Monthly = policyRider.wopPremium3Monthly
                    quotationRider.wopPremiumField = policyRider.wopPremiumField
                    quotationRider.wopPremiumField2 = policyRider.wopPremiumField2
                    quotationRider.wopPremiumField3 = policyRider.wopPremiumField3
                    quotationRider.paidUpFl = policyRider.paidUpFl

                    quotationRider.sortOrder = policyRider.sortOrder

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
	                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
	                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
	                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
	                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
	                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
	                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
	                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
	                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
	                    quotationRider.addQuotationProductExtra(quotationProductExtra)
	                end
                elsif policyRider.productTypeCd == "PLANMULTI"
					quotationPlanMulti = QuotationProduct.new(:productTypeCd => "PLANMULTI")
					quotation.addQuotationProduct(quotationPlanMulti)

					quotationPlanMulti.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
					quotationPlanMulti.productId = policyRider.productId
					quotationPlanMulti.productVersion = policyRider.productVersion
					quotationPlanMulti.productSeq = policyRider.productSeq
					quotationPlanMulti.parentproductSeq = policyRider.parentproductSeq
					quotationPlanMulti.productTypeCd = policyRider.productTypeCd 
					quotationPlanMulti.productFamilyCd = policyRider.productFamilyCd 
					quotationPlanMulti.baseSumAssured = policyRider.baseSumAssured
					quotationPlanMulti.baseAnnualPremium = policyRider.baseAnnualPremium 
					quotationPlanMulti.modalPremium = policyRider.modalPremium
					quotationPlanMulti.capturedPremiumAmt = policyRider.capturedPremiumAmt 
					quotationPlanMulti.productTerm = policyRider.productTerm 
					quotationPlanMulti.premiumPayingTerm = policyRider.premiumPayingTerm 
					quotationPlanMulti.annualizedPremium = policyRider.annualizedPremium 
					quotationPlanMulti.totAnnualizedPremium = policyRider.totAnnualizedPremium
	                quotationPlanMulti.vestingAge = policyRider.vestingAge
	                quotationPlanMulti.annuityPerc = policyRider.annuityPerc
					quotationPlanMulti.extraPremium = policyRider.extraPremium
					quotationPlanMulti.maxTargetPremium = policyRider.maxTargetPremium
					quotationPlanMulti.minTargetPremium = policyRider.minTargetPremium
					quotationPlanMulti.recommendedPremium = policyRider.recommendedPremium
					quotationPlanMulti.unapliedPremium = policyRider.unapliedPremium
					quotationPlanMulti.linkedFl = policyRider.linkedFl
					quotationPlanMulti.pdfRequiredFl = policyRider.pdfRequiredFl
					quotationPlanMulti.topUpAllocSameAsPremAllocFl = policyRider.topUpAllocSameAsPremAllocFl
					quotationPlanMulti.targetFundFl = policyRider.targetFundFl
					quotationPlanMulti.builtInRiderFl = policyRider.builtInRiderFl
					quotationPlanMulti.guid = policyRider.guid
					quotationPlanMulti.premiumSAFl = policyRider.premiumSAFl

					# every time get copied From Base Plan
					quotationPlanMulti.paymentFrequencyCd = policyRider.paymentFrequencyCd
					quotationPlanMulti.currencyCd = policyRider.currencyCd
					quotationPlanMulti.paymentTypeCd = policyRider.paymentTypeCd
                    quotationPlanMulti.minTargetPremium = policyRider.minTargetPremium

					quotationPlanMulti.productPlanOptionCd = policyRider.productPlanOptionCd 
					quotationPlanMulti.planCode = policyRider.planCode 
					quotationPlanMulti.productSeq = policyRider.productSeq
					quotationPlanMulti.coi = policyRider.coi 

					quotationPlanMulti.combinedEntryAge = policyRider.combinedEntryAge
					quotationPlanMulti.portfolioModelCd = policyRider.portfolioModelCd
					quotationPlanMulti.holderRefGuid = policyRider.object
					quotationPlanMulti.selected = policyRider.selected

					quotationPlanMulti.addtnField1 = policyRider.addtnField1 
					quotationPlanMulti.addtnField2 = policyRider.addtnField2 
					quotationPlanMulti.addtnField3 = policyRider.addtnField3 
					quotationPlanMulti.addtnField4 = policyRider.addtnField4 
					quotationPlanMulti.addtnField5 = policyRider.addtnField5 
					quotationPlanMulti.addtnField6 = policyRider.addtnField6 
					# Extra Loading And Duration 
					quotationPlanMulti.flatExtra = policyRider.flatExtra
					#quotationPlanMulti.emr = policyRider.emr 

					quotationPlanMulti.wopPremium = policyRider.wopPremium
					quotationPlanMulti.wopPremium2 = policyRider.wopPremium2
					quotationPlanMulti.wopPremiumQuarterly = policyRider.wopPremiumQuarterly
					quotationPlanMulti.wopPremiumHalfYearly = policyRider.wopPremiumHalfYearly
					quotationPlanMulti.wopPremiumMonthly = policyRider.wopPremiumMonthly
					quotationPlanMulti.wopPremium2Quarterly = policyRider.wopPremium2Quarterly
					quotationPlanMulti.wopPremium2HalfYearly = policyRider.wopPremium2HalfYearly
					quotationPlanMulti.wopPremium2Monthly = policyRider.wopPremium2Monthly
					quotationPlanMulti.wopPremium3 = policyRider.wopPremium3
					quotationPlanMulti.wopPremium3Quarterly = policyRider.wopPremium3Quarterly
					quotationPlanMulti.wopPremium3HalfYearly = policyRider.wopPremium3HalfYearly
					quotationPlanMulti.wopPremium3Monthly = policyRider.wopPremium3Monthly
					quotationPlanMulti.wopPremiumField = policyRider.wopPremiumField
					quotationPlanMulti.wopPremiumField2 = policyRider.wopPremiumField2
					quotationPlanMulti.wopPremiumField3 = policyRider.wopPremiumField3
          quotationPlanMulti.paidUpFl = policyRider.paidUpFl
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
	                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
	                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
	                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
	                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
	                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
	                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
	                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
	                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
	                    quotationPlanMulti.addQuotationProductExtra(quotationProductExtra)
	                end
                end
            end    

            policySupplementary = policy.getPartyList("SUPPLEMENTARY")
            policySupplementary.each do |suplementary|
                quotationParty = QuotationParty.new
                quotationParty.object=suplementary.object
                quotationParty.title = suplementary.titleCd
                quotationParty.otherTitle = suplementary.otherTitle
                quotationParty.firstname=suplementary.firstName1
                quotationParty.lastname=suplementary.lastName1
                quotationParty.age = suplementary.age
                quotationParty.genderCd = suplementary.genderCd
                quotationParty.smoker = suplementary.smoker
                quotationParty.nsap = suplementary.nonResidentFl  
                quotationParty.partyTypeCd = suplementary.partyTypeCd

                if suplementary.PartyEmploymentList[0]
                    quotationParty.occupationCd = suplementary.PartyEmploymentList[0].occupationClass
                    quotationParty.industryCd = suplementary.PartyEmploymentList[0].industryCd
                    quotationParty.natureOfDuty = suplementary.PartyEmploymentList[0].natureOfDuty
                end
                if suplementary.getPartyContact("MOBILE")
                    quotationParty.contactNum = suplementary.getPartyContact("MOBILE").contactNum
                end
                if suplementary.getPartyEmail
                    quotationParty.emailAddress = suplementary.getPartyEmail.emailAddress
                end
                quotationParty.dob = suplementary.birthDt
                quotationParty.roleCd = suplementary.roleCd
                quotationParty.relationCd = suplementary.relationCd
                quotationParty.citizenshipCd=suplementary.citizenshipCd
                quotationParty.nationality=suplementary.citizenshipCd
                quotationParty.guid = suplementary.guid
                quotationParty.maritalStatus = suplementary.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = suplementary.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = suplementary.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = suplementary.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = suplementary.quotPartyAddtnField4
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
                quotationParty.title = payer.titleCd
                quotationParty.guid = payer.guid
                quotationParty.otherTitle = payer.otherTitle
                quotationParty.guid = payer.guid
                quotationParty.firstname = payer.firstName1
                quotationParty.lastname = payer.lastName1
                quotationParty.age = payer.age
                quotationParty.genderCd = payer.genderCd
                quotationParty.smoker = payer.smoker     
                quotationParty.nsap = payer.nonResidentFl        
                quotationParty.partyTypeCd = payer.partyTypeCd           
                if payer.PartyEmploymentList[0]
                    quotationParty.occupationCd = payer.PartyEmploymentList[0].occupationClass
                    quotationParty.industryCd = payer.PartyEmploymentList[0].industryCd
                    quotationParty.natureOfDuty = payer.PartyEmploymentList[0].natureOfDuty
                end
                if payer.getPartyContact("MOBILE")
                    quotationParty.contactNum = payer.getPartyContact("MOBILE").contactNum
                end
                if payer.getPartyEmail
                    quotationParty.emailAddress = payer.getPartyEmail.emailAddress
                end
                quotationParty.dob = payer.birthDt
                quotationParty.roleCd = "PAYER"
                quotationParty.relationCd = payer.relationCd
                quotationParty.citizenshipCd=payer.citizenshipCd
                quotationParty.nationality=payer.citizenshipCd
                quotationParty.maritalStatus = payer.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = payer.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = payer.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = payer.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = payer.quotPartyAddtnField4
                quotation.addQuotationParty(quotationParty)
            end

            nomineeList = policy.getPartyList("NOMINEE")
            nomineeList.each do |nomineee|
                quotationParty = QuotationParty.new
                quotationParty.title = nomineee.titleCd
                quotationParty.guid = nomineee.guid
                quotationParty.otherTitle = nomineee.otherTitle
                quotationParty.guid = nomineee.guid
                quotationParty.firstname = nomineee.firstName1
                quotationParty.lastname = nomineee.lastName1
                quotationParty.partyTypeCd = nomineee.partyTypeCd           
                quotationParty.age = nomineee.age
                quotationParty.genderCd = nomineee.genderCd
                quotationParty.smoker = nomineee.smoker
                quotationParty.nsap = nomineee.nonResidentFl  
                if nomineee.PartyEmploymentList[0]
                    quotationParty.occupationCd = nomineee.PartyEmploymentList[0].occupationClass
                end
                if nomineee.getPartyContact("MOBILE")
                    quotationParty.contactNum = nomineee.getPartyContact("MOBILE").contactNum
                end
                if nomineee.getPartyEmail
                    quotationParty.emailAddress = nomineee.getPartyEmail.emailAddress
                end
                quotationParty.dob = nomineee.birthDt
                quotationParty.roleCd = "NOMINEE"
                quotationParty.relationCd = nomineee.relationCd
                quotationParty.citizenshipCd=nomineee.citizenshipCd
                quotationParty.nationality=nomineee.citizenshipCd
                quotationParty.maritalStatus = nomineee.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = nomineee.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = nomineee.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = nomineee.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = nomineee.quotPartyAddtnField4
                quotation.addQuotationParty(quotationParty)
            end

            policy.PolicyTopUpList.each do|topUp|
                quotationTopUp = QuotationTopUp.new
                quotationTopUp.topupFrequencyValUnit = topUp.topupFrequencyValUnit
                quotationTopUp.policyYearFrom = topUp.policyYearFrom
                quotationTopUp.policyYearTo = topUp.policyYearTo
                quotationTopUp.topUpTypeCd = topUp.topUpTypeCd
                quotationTopUp.topUpAmount = topUp.topUpAmount
                quotationTopUp.topupFrequencyVal = topUp.topupFrequencyVal
                quotationTopUp.guid = topUp.guid
                quotation.addQuotationTopUp(quotationTopUp)
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
                policy.guid = quotation.guid
                policy.quotationRefGuid = quotation.uniqueKey
                policy.bankStaffReferralCd = quotation.bankStaffReferralCd
                policy.quotationRefNum = quotation.quotationRefNum
                policy.leadId = quotation.leadId
                policy.fnaId = quotation.fnaId
                policy.rpqId = quotation.rpqId
                policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                policy.isBackdatedFl = quotation.isBackdatedFl
                policy.quotationDt = quotation.quotationDt
                policy.insuranceTypeCd = quotation.insuranceTypeCd
                policy.tripTypeCd = quotation.tripTypeCd
                policy.maxTripPeriod = quotation.maxTripPeriod
                policy.travelGeographyCd = quotation.travelGeographyCd
                policy.visitPurposeCd = quotation.visitPurposeCd
                policy.numberOfAdult = quotation.numberOfAdult
                policy.numberOfChildren = quotation.numberOfChildren
                policy.startDt = quotation.startDt
                policy.endDt = quotation.endDt
                policy.coverTypeCd = quotation.coverTypeCd
                policy.autoRegistrationNum = quotation.autoRegistrationNum
                policy.autoMakeCd = quotation.autoMakeCd
                policy.autoModelCd = quotation.autoModelCd
                policy.questionContainer = quotation.questionContainer
                policy.action = quotation.action
                policy.proposerLASame = quotation.proposerLASame
                policy.uploadFlag = quotation.uploadFlag
                policy.branchCd = quotation.quotAddtnlField2
                policy.quoteProposerSameAsInsured = quotation.getPartyByRole("PROPOSER").quotPartyAddtnField4
                policy.channelId = agentRegDetails.channel
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
    			if(quotation.leadId != nil)
    				lead = Lead.loadObject(:first, :conditions => {:leadId => quotation.leadId})
    				partyRefGuid = lead.partyRefGuid
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
    						# 	leadParty.PartyAddressList.each do |leadPartyAddressDO|
    						# 		partyAddress = PartyAddress.new
    						# 		MobiSys::CommonUtil.copyFields(leadPartyAddressDO, partyAddress)
    						# 		proposerParty.addPartyAddress(partyAddress)
    						# 	end
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
                policyProduct.guid = quotationProduct.guid
                policyProduct.productTypeCd = quotationProduct.productTypeCd
                policyProduct.productId = quotationProduct.productId
                policyProduct.productSeq = quotationProduct.productSeq
                policyProduct.productPlanOptionCd = quotationProduct.productPlanOptionCd
                policyProduct.parentproductSeq = quotationProduct.parentproductSeq
                policyProduct.productTypeCd  = quotationProduct.productTypeCd
                policyProduct.productFamilyCd = quotationProduct.productFamilyCd
                policyProduct.currencyCd = quotationProduct.currencyCd
                policyProduct.baseSumAssured = quotationProduct.baseSumAssured
                policyProduct.baseAnnualPremium = quotationProduct.baseAnnualPremium
                policyProduct.annualizedPremium = quotationProduct.annualizedPremium 
                policyProduct.totAnnualizedPremium = quotationProduct.totAnnualizedPremium
                policyProduct.vestingAge = quotationProduct.vestingAge
                policyProduct.annuityPerc = quotationProduct.annuityPerc
                policyProduct.modalPremium = quotationProduct.modalPremium
                policyProduct.extraPremium = quotationProduct.extraPremium
                policyProduct.productTerm = quotationProduct.productTerm
                policyProduct.premiumPayingTerm = quotationProduct.premiumPayingTerm
                policyProduct.paymentTypeCd = quotationProduct.paymentTypeCd
                policyProduct.paymentFrequencyCd = quotationProduct.paymentFrequencyCd
                policyProduct.planCode = quotationProduct.planCode
                policyProduct.portfolioModelCd = quotationProduct.portfolioModelCd
                policyProduct.capturedPremiumAmt = quotationProduct.capturedPremiumAmt
                policyProduct.maxTargetPremium = quotationProduct.maxTargetPremium
                policyProduct.minTargetPremium = quotationProduct.minTargetPremium
                policyProduct.recommendedPremium = quotationProduct.recommendedPremium
                policyProduct.unapliedPremium = quotationProduct.unapliedPremium
                policyProduct.combinedEntryAge = quotationProduct.combinedEntryAge
                policyProduct.coi = quotationProduct.coi
                policyProduct.addtnField1 = quotationProduct.addtnField1
                policyProduct.addtnField2 = quotationProduct.addtnField2
                policyProduct.addtnField3 = quotationProduct.addtnField3
                policyProduct.addtnField4 = quotationProduct.addtnField4
                policyProduct.addtnField5 = quotationProduct.addtnField5
                policyProduct.addtnField6 = quotationProduct.addtnField6
                policyProduct.builtInRiderFl = quotationProduct.builtInRiderFl
                policyProduct.productVersion = quotationProduct.productVersion
                policyProduct.selected = quotationProduct.selected
                policyProduct.wopPremium = quotationProduct.wopPremium
                policyProduct.wopPremium2 = quotationProduct.wopPremium2
                policyProduct.wopPremiumQuarterly = quotationProduct.wopPremiumQuarterly
                policyProduct.wopPremiumHalfYearly = quotationProduct.wopPremiumHalfYearly
                policyProduct.wopPremiumMonthly = quotationProduct.wopPremiumMonthly
                policyProduct.wopPremium2Quarterly = quotationProduct.wopPremium2Quarterly
                policyProduct.wopPremium2HalfYearly = quotationProduct.wopPremium2HalfYearly
                policyProduct.wopPremium2Monthly = quotationProduct.wopPremium2Monthly
                policyProduct.wopPremium3 = quotationProduct.wopPremium3
                policyProduct.wopPremium3Quarterly = quotationProduct.wopPremium3Quarterly
                policyProduct.wopPremium3HalfYearly = quotationProduct.wopPremium3HalfYearly
                policyProduct.wopPremium3Monthly = quotationProduct.wopPremium3Monthly
                policyProduct.wopPremiumField = quotationProduct.wopPremiumField
                policyProduct.wopPremiumField2 = quotationProduct.wopPremiumField2
                policyProduct.wopPremiumField3 = quotationProduct.wopPremiumField3
                policyProduct.ropPerc = quotationProduct.ropPerc
                policyProduct.fixedPrmIndexationVal = quotationProduct.fixedPrmIndexationVal
                policyProduct.pdfRequiredFl = quotationProduct.pdfRequiredFl
                policyProduct.pdfFrequencyVal = quotationProduct.pdfFrequencyVal
                policyProduct.pdfPeriod = quotationProduct.pdfPeriod
                policyProduct.paidUpFl = quotationProduct.paidUpFl
                policyProduct.topUpTypeCd = quotationProduct.topUpTypeCd
                policyProduct.annuityAge = quotationProduct.annuityAge
                policyProduct.payingYears = quotationProduct.payingYears
                policyProduct.compAnnualPremium = quotationProduct.compAnnualPremium
                policyProduct.compHalfYlyPremium = quotationProduct.compHalfYlyPremium
                policyProduct.compQtlyPremium = quotationProduct.compQtlyPremium
                policyProduct.compMonthlyPremium = quotationProduct.compMonthlyPremium
                policyProduct.targetFundVal = quotationProduct.targetFundVal
                policyProduct.targetPeriod = quotationProduct.targetPeriod
                policyProduct.payoutFrequencyCd = quotationProduct.payoutFrequencyCd
                policyProduct.productLongName = quotationProduct.productLongName
                policyProduct.targetPeriodRefCd = quotationProduct.targetPeriodRefCd
                policyProduct.sortOrder = quotationProduct.sortOrder
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
                    @policyProductAdditional.prdAddtnField1str = qpAdditional.prdAddtnField1str
                    @policyProductAdditional.prdAddtnField2str = qpAdditional.prdAddtnField2str
                    @policyProductAdditional.prdAddtnField3str = qpAdditional.prdAddtnField3str
                    @policyProductAdditional.prdAddtnField4str = qpAdditional.prdAddtnField4str
                    @policyProductAdditional.prdAddtnField5str = qpAdditional.prdAddtnField5str
                    @policyProductAdditional.prdAddtnField6d = qpAdditional.prdAddtnField6d
                    @policyProductAdditional.prdAddtnField7d = qpAdditional.prdAddtnField7d
                    @policyProductAdditional.prdAddtnField8d = qpAdditional.prdAddtnField8d
                    @policyProductAdditional.prdAddtnField9d = qpAdditional.prdAddtnField9d
                    @policyProductAdditional.prdAddtnField10d = qpAdditional.prdAddtnField10d
                    @policyProductAdditional.prdAddtnField11d = qpAdditional.prdAddtnField11d
                    @policyProductAdditional.prdAddtnField12d = qpAdditional.prdAddtnField12d
                    @policyProductAdditional.prdAddtnField13d = qpAdditional.prdAddtnField13d
                    @policyProductAdditional.prdAddtnField14d = qpAdditional.prdAddtnField14d
                    @policyProductAdditional.prdAddtnField15d = qpAdditional.prdAddtnField15d
                    @policyProductAdditional.prdAddtnField16dt = qpAdditional.prdAddtnField16dt
                    @policyProductAdditional.prdAddtnField17dt = qpAdditional.prdAddtnField17dt
                    @policyProductAdditional.prdAddtnField18dt = qpAdditional.prdAddtnField18dt
                    @policyProductAdditional.prdAddtnField19dt = qpAdditional.prdAddtnField19dt
                    @policyProductAdditional.prdAddtnField20dt = qpAdditional.prdAddtnField20dt
                end

                quotationProduct.QuotationProductExtraList.each do |quotationProductExtra|
                    policyProductExtra = PolicyProductExtra.new
                    policyProduct.addPolicyProductExtra(policyProductExtra)
                    policyProductExtra.extraTypeCd = quotationProductExtra.extraTypeCd
                    policyProductExtra.decisionCd = quotationProductExtra.decisionCd
                    policyProductExtra.loadingTypeCd = quotationProductExtra.loadingTypeCd
                    policyProductExtra.processingTypeCd = quotationProductExtra.processingTypeCd
                    policyProductExtra.extraFlatAmt = quotationProductExtra.extraFlatAmt
                    policyProductExtra.extraPercent = quotationProductExtra.extraPercent
                    policyProductExtra.extraFlatDuration = quotationProductExtra.extraFlatDuration
                    policyProductExtra.extraPercDuration = quotationProductExtra.extraPercDuration
                end
                
                quotationProduct.QuotationProductInvestmentFundList.each do |quotationFund|
                    policyProductInvestmentFund = PolicyProductInvestmentFund.new
                    policyProduct.addPolicyProductInvestmentFund(policyProductInvestmentFund)
                    policyProductInvestmentFund.fundCd = quotationFund.fundCd
                    policyProductInvestmentFund.allocationPerc = quotationFund.allocationPerc
                    policyProductInvestmentFund.topupAllocationPerc = quotationFund.topupAllocationPerc
                    policyProductInvestmentFund.expiryDt = quotationFund.expiryDt
                    policyProductInvestmentFund.fundTypeCd = quotationFund.fundTypeCd
                    policyProductInvestmentFund.maturityDt = quotationFund.maturityDt
                    policyProductInvestmentFund.sortOrder = quotationFund.sortOrder
                end
            end

            quotation.QuotationTopUpList.each do |topUp|
                if topUp.topUpTypeCd == 'REGULARTOPUP'
                    regularTopUp = PolicyTopUp.new(:topUpTypeCd =>'REGULARTOPUP')
                    policy.addPolicyTopUp(regularTopUp)
                    regularTopUp.topUpAmount = topUp.topUpAmount
                    regularTopUp.topUpPeriod = topUp.topUpPeriod
                    regularTopUp.topupFrequencyVal = topUp.topupFrequencyVal
                elsif topUp.topUpTypeCd == 'INITIALINVESTMENT'
                    initialTopup = PolicyTopUp.new(:topUpTypeCd =>'INITIALINVESTMENT')
                    policy.addPolicyTopUp(initialTopup)
                    initialTopup.topUpPeriod = topUp.topUpPeriod
                    initialTopup.topUpAmount = topUp.topUpAmount
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
                    newParty.titleCd = oldParty.title
                    newParty.otherTitle = oldParty.otherTitle
                    newParty.firstName1 = oldParty.firstname
                    newParty.middleName1 = oldParty.middlename
                    newParty.lastName1 = oldParty.lastname
                    newParty.extensionName1 = oldParty.extensionName
                    newParty.firstName2 = oldParty.firstname2
                    newParty.middleName2 = oldParty.middlename2
                    newParty.lastName2 = oldParty.lastname2
                    newParty.extensionName2 = oldParty.extensionName2
                    newParty.genderCd = oldParty.genderCd
                    newParty.relationCd = oldParty.relationCd
                    newParty.otherRelation = oldParty.otherRelation
                    newParty.smoker = oldParty.smoker
                    newParty.nonResidentFl = oldParty.nsap
                    newParty.coverageCountryCd = oldParty.coverageCountryCd
                    newParty.coverageCityCd = oldParty.coverageCityCd
                    newParty.maritalStatusCd = oldParty.maritalStatus
                    newParty.birthDt = oldParty.dob
                    newParty.age = oldParty.age
                    newParty.monthlyIncome = oldParty.monthlyIncome
                    newParty.annualIncome = oldParty.annualIncome
                    newParty.quotPartyAddtnField1 = oldParty.quotPartyAddtnField1
                    newParty.quotPartyAddtnField2 = oldParty.quotPartyAddtnField2
                    newParty.quotPartyAddtnField3 = oldParty.quotPartyAddtnField3
                    newParty.quotPartyAddtnField4 = oldParty.quotPartyAddtnField4
                    newParty.citizenshipCd = oldParty.nationality
                    newParty.copyFromAddr3 = oldParty.educationCd
                    newParty.copyFromAddr2 = oldParty.residency
                    newParty.otherReligion = oldParty.officeIsdCode
                                
                    partyEmployment = newParty.getPartyEmployment(true)
                    partyEmployment.industryCd = oldParty.industryCd
                    partyEmployment.natureOfDuty = oldParty.natureOfDuty
                    #partyEmployment.occupationClass = oldParty.occupationCd
                    partyEmployment.occupationCd = oldParty.occupationCd
                    ["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
                      partyAddress = newParty.getPartyAddress(addressType.to_s, true)
                      quotPartyAddress = oldParty.getAddress(addressType.to_s)
                      if quotPartyAddress
                          partyAddress.addressLine1Lang1 = quotPartyAddress.addressLine1Lang1
                          partyAddress.addressLine2Lang1 = quotPartyAddress.addressLine2Lang1
                          partyAddress.addressLine3Lang1 = quotPartyAddress.addressLine3Lang1
                          partyAddress.addressLine4Lang1 = quotPartyAddress.addressLine4
                          partyAddress.countryCd = quotPartyAddress.countryCd
                          partyAddress.pinCode = quotPartyAddress.pinCode
                          partyAddress.stateCd = quotPartyAddress.stateCd
                          partyAddress.cityCd = quotPartyAddress.cityCd
                      end
                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    end
                    
                    partyContact1 = newParty.getPartyContact("MOBILE", true)
                    partyContact1.countryCd = oldParty.countryCd
                    partyContact1.stdCode = oldParty.stdCode
                    partyContact1.contactNum = oldParty.contactNum

                    partyEmail = newParty.getPartyEmail(true)
                    partyEmail.emailAddress = oldParty.emailAddress

                    if oldParty.idNumber.to_s != "" && oldParty.idType.to_s != ""
                      newPartyIdentity = PartyIdentity.new
                      newPartyIdentity.identityNum = oldParty.idNumber
                      newPartyIdentity.identityTypeCd = oldParty.idType
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
                          #Party Identity Details
                          if leadParty.PartyIdentityList.size > 0
                            leadParty.PartyIdentityList.each do |partyIdentity|
                              next if partyIdentity.identityTypeCd.to_s == oldParty.idType.to_s
                              newPartyIdentity = PartyIdentity.new
                              newPartyIdentity.identityNum = partyIdentity.identityNum
                              newPartyIdentity.expiryDt = partyIdentity.expiryDt
                              newPartyIdentity.issueDt = partyIdentity.issueDt
                              newPartyIdentity.identityTypeCd = partyIdentity.identityTypeCd
                              newPartyIdentity.issuingAuthority = partyIdentity.issuingAuthority
                              newParty.addPartyIdentity(newPartyIdentity)
                              newPartyIdentity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newPartyIdentity)
                            end
                          end

                          #Party Other Income Details
                          if leadParty.getPartyOtherIncomeList.size > 0
                            leadParty.getPartyOtherIncomeList.each do |otherIncome|
                              newOtherIncome = PartyOtherIncome.new
                              newOtherIncome.incomeTypeCd = otherIncome.incomeTypeCd
                              newOtherIncome.sourceOfIncome = otherIncome.sourceOfIncome
                              newOtherIncome.incomeAmount = otherIncome.incomeAmount
                              newOtherIncome.otherSourceIncome = otherIncome.otherSourceIncome
                              newOtherIncome.currencyCd = otherIncome.currencyCd
                              newOtherIncome.incomeYear = otherIncome.incomeYear
                              newParty.addPartyOtherIncome(newOtherIncome)
                              newOtherIncome.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newOtherIncome)
                            end
                          end

                          #Residential and Office Contact Details
                          if leadParty.getPartyContact("OFFICE")
                            leadOfficeContact = leadParty.getPartyContact("OFFICE")
                            partyContact2 = newParty.getPartyContact("OFFICE",true)
                            partyContact2.countryCd = leadOfficeContact.countryCd
                            partyContact2.stdCode = leadOfficeContact.stdCode
                            partyContact2.contactNum = leadOfficeContact.contactNum
                            partyContact2.extensionNum = leadOfficeContact.extensionNum
                            partyContact2.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact2)
                          end

                          if leadParty.getPartyContact("RESIDENTIAL")
                            leadHomeContact = leadParty.getPartyContact("RESIDENTIAL")
                            partyContact3 = newParty.getPartyContact("RESIDENTIAL",true)
                            partyContact3.countryCd = leadHomeContact.countryCd
                            partyContact3.stdCode = leadHomeContact.stdCode
                            partyContact3.contactNum = leadHomeContact.contactNum
                            partyContact3.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact3)
                          end

                          if leadParty.getPartyContact("PHILIPPINESNUM")
                            leadHomeContact = leadParty.getPartyContact("PHILIPPINESNUM")
                            partyContact4 = newParty.getPartyContact("PHILIPPINESNUM",true)
                            partyContact4.countryCd = leadHomeContact.countryCd
                            partyContact4.stdCode = leadHomeContact.stdCode
                            partyContact4.contactNum = leadHomeContact.contactNum
                            partyContact4.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact3)
                          end
                        end
                    end 

                    partyEmployment.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmployment)
                    # partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    partyContact1.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact1)
                    partyEmail.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmail)
                elsif oldParty.partyTypeCd == 'ORGANIZATION'
                    newParty.corporateName1 = oldParty.corporateName
                    newParty.quotPartyAddtnField1 = oldParty.quotPartyAddtnField1
                    newParty.quotPartyAddtnField2 = oldParty.quotPartyAddtnField2
                    newParty.quotPartyAddtnField3 = oldParty.quotPartyAddtnField3
                    newParty.quotPartyAddtnField4 = oldParty.quotPartyAddtnField4
                    newParty.nonResidentFl = oldParty.nsap
                    partyIdentity = newParty.getPartyIdentityList(true)[0]
                    partyIdentity.identityNum = oldParty.businessTIN
                    
                    partyAddress = newParty.getPartyAddress("OFFICE", true)
                    quotPartyAddress = oldParty.getAddress("OFFICE")
                    if quotPartyAddress
                      partyAddress.addressLine1Lang1 = quotPartyAddress.addressLine1Lang1
                      partyAddress.addressLine2Lang1 = quotPartyAddress.addressLine2Lang1
                      partyAddress.addressLine3Lang1 = quotPartyAddress.addressLine3Lang1
                      partyAddress.addressLine4Lang1 = quotPartyAddress.addressLine4
                      partyAddress.countryCd = quotPartyAddress.countryCd
                      partyAddress.pinCode = quotPartyAddress.pinCode
                      partyAddress.stateCd = quotPartyAddress.stateCd
                      partyAddress.cityCd = quotPartyAddress.cityCd
                    end
                    partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                        
                    partyContact = newParty.getPartyContact("OFFICE", true)
                    partyContact.countryCd = oldParty.isdCode
                    partyContact.stdCode = oldParty.stdCode
                    partyContact.contactNum = oldParty.contactNum

                    partyEmail = newParty.getPartyEmail(true)
                    partyEmail.emailAddress = oldParty.emailAddress

                    if lead
                        leadParty = lead.getLeadParty
                        if leadParty
                            if leadParty.getPartyContact("PHILIPPINESNUM")
                                leadOfficeContact = leadParty.getPartyContact("PHILIPPINESNUM")
                                partyContact1 = newParty.getPartyContact("PHILIPPINESNUM",true)
                                partyContact1.countryCd = leadOfficeContact.countryCd
                                partyContact1.stdCode = leadOfficeContact.stdCode
                                partyContact1.contactNum = leadOfficeContact.contactNum
                                partyContact1.extensionNum = leadOfficeContact.extensionNum
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
                        quotationProduct.product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                        quotationProduct.productId = policyProduct.productId
                        quotationProduct.productVersion = policyProduct.productVersion
                        quotationProduct.productSeq = policyProduct.productSeq
                        quotationProduct.parentproductSeq = policyProduct.parentproductSeq
                        quotationProduct.productTypeCd = policyProduct.productTypeCd 
                        quotationProduct.productFamilyCd = policyProduct.productFamilyCd 
                        quotationProduct.baseSumAssured = policyProduct.baseSumAssured
                        quotationProduct.baseAnnualPremium = policyProduct.baseAnnualPremium 
                        quotationProduct.modalPremium = policyProduct.modalPremium
                        quotationProduct.capturedPremiumAmt = policyProduct.capturedPremiumAmt 
                        quotationProduct.productTerm = policyProduct.productTerm 
                        quotationProduct.premiumPayingTerm = policyProduct.premiumPayingTerm 
                        quotationProduct.annualizedPremium = policyProduct.annualizedPremium 
                        quotationProduct.totAnnualizedPremium = policyProduct.totAnnualizedPremium
                        quotationProduct.vestingAge = policyProduct.vestingAge
                        quotationProduct.annuityPerc = policyProduct.annuityPerc
                        quotationProduct.extraPremium = policyProduct.extraPremium
                        quotationProduct.maxTargetPremium = policyProduct.maxTargetPremium
                        quotationProduct.minTargetPremium = policyProduct.minTargetPremium
                        quotationProduct.recommendedPremium = policyProduct.recommendedPremium
                        quotationProduct.unapliedPremium = policyProduct.unapliedPremium
                        quotationProduct.linkedFl = policyProduct.linkedFl
                        quotationProduct.pdfRequiredFl = policyProduct.pdfRequiredFl
                        quotationProduct.topUpAllocSameAsPremAllocFl = policyProduct.topUpAllocSameAsPremAllocFl
                        quotationProduct.targetFundFl = policyProduct.targetFundFl
                        quotationProduct.builtInRiderFl = policyProduct.builtInRiderFl
                        quotationProduct.guid = policyProduct.guid
                        quotationProduct.premiumSAFl = policyProduct.premiumSAFl
                        quotationProduct.pdfFrequencyVal = policyProduct.pdfFrequencyVal
                        quotationProduct.pdfPeriod = policyProduct.pdfPeriod
                        quotationProduct.payoutFrequencyCd = policyProduct.payoutFrequencyCd
                        # every time get copied From Base Plan
                        quotationProduct.paymentFrequencyCd = policyProduct.paymentFrequencyCd
                        quotationProduct.currencyCd = policyProduct.currencyCd
                        quotationProduct.paymentTypeCd = policyProduct.paymentTypeCd
                        quotationProduct.minTargetPremium = policyProduct.minTargetPremium

                        quotationProduct.productPlanOptionCd = policyProduct.productPlanOptionCd 
                        quotationProduct.planCode = policyProduct.planCode 
                        quotationProduct.productSeq = policyProduct.productSeq
                        quotationProduct.coi = policyProduct.coi 

                        quotationProduct.combinedEntryAge = policyProduct.combinedEntryAge
                        quotationProduct.portfolioModelCd = policyProduct.portfolioModelCd
                        quotationProduct.holderRefGuid = policyProduct.object
                        quotationProduct.selected = policyProduct.selected

                        quotationProduct.addtnField1 = policyProduct.addtnField1 
                        quotationProduct.addtnField2 = policyProduct.addtnField2 
                        quotationProduct.addtnField3 = policyProduct.addtnField3 
                        quotationProduct.addtnField4 = policyProduct.addtnField4 
                        quotationProduct.addtnField5 = policyProduct.addtnField5 
                        quotationProduct.addtnField6 = policyProduct.addtnField6 
                        # Extra Loading And Duration 
                        quotationProduct.flatExtra = policyProduct.flatExtra

                        quotationProduct.wopPremium = policyProduct.wopPremium
                        quotationProduct.wopPremium2 = policyProduct.wopPremium2
                        quotationProduct.wopPremiumQuarterly = policyProduct.wopPremiumQuarterly
                        quotationProduct.wopPremiumHalfYearly = policyProduct.wopPremiumHalfYearly
                        quotationProduct.wopPremiumMonthly = policyProduct.wopPremiumMonthly
                        quotationProduct.wopPremium2Quarterly = policyProduct.wopPremium2Quarterly
                        quotationProduct.wopPremium2HalfYearly = policyProduct.wopPremium2HalfYearly
                        quotationProduct.wopPremium2Monthly = policyProduct.wopPremium2Monthly
                        quotationProduct.wopPremium3 = policyProduct.wopPremium3
                        quotationProduct.wopPremium3Quarterly = policyProduct.wopPremium3Quarterly
                        quotationProduct.wopPremium3HalfYearly = policyProduct.wopPremium3HalfYearly
                        quotationProduct.wopPremium3Monthly = policyProduct.wopPremium3Monthly
                        quotationProduct.wopPremiumField = policyProduct.wopPremiumField
                        quotationProduct.wopPremiumField2 = policyProduct.wopPremiumField2
                        quotationProduct.wopPremiumField3 = policyProduct.wopPremiumField3
                        quotationProduct.paidUpFl = policyProduct.paidUpFl

                        quotationProduct.compAnnualPremium = policyProduct.compAnnualPremium
                        quotationProduct.compHalfYlyPremium = policyProduct.compHalfYlyPremium
                        quotationProduct.compQtlyPremium = policyProduct.compQtlyPremium
                        quotationProduct.compMonthlyPremium = policyProduct.compMonthlyPremium

                        quotationProduct.sortOrder = policyProduct.sortOrder

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
    end
end

begin 
    require 'Policy/policy_b_o_company'
rescue LoadError => e
    puts 'policy_b_o_company not included'
end
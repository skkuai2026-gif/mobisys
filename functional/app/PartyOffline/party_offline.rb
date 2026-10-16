# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyOffline
    include MobiSys::MobiSysEntitySchema
   
    set :schema_version, '1.0'
         
    # Uncomment the following line to enable sync with Label.
    # enable :sync
   
    #add model specifc code here

    ################################################################################
    #------------------------------Common Code Start-------------------------------#
    ################################################################################    
    property :roleCd, :string
    property :titleCd, :string
    property :firstName1, :string
    property :firstName2, :string
    property :middleName1, :string
    property :middleName2, :string
    property :lastName1, :string
    property :lastName2, :string
    property :birthDt, :date
    property :age, :integer
    property :placeOfBirth, :string
    property :countryOfBirth, :string
    property :otherPlaceOfBirth, :string
    property :genderCd, :string
    property :maritalStatusCd, :string
    property :raceCd, :string
    property :otherRace,   :string
    property :citizenshipCd, :string
    property :otherCitizenship, :string
    property :relationCd,  :string
    property :npwp, :string
    property :partyId, :string
    property :partyTypeCd, :string
    property :customerId, :string
    property :corporateName1, :string
    property :nonResidentFl, :string
    property :totalSAR, :integer
    property :smoker, :string
    property :financialSAR, :integer
    property :intimationSourceCd, :string
    property :occupationClass, :string
    property :otherTitle, :string
    property :spouseName, :string
    property :spouseSurname, :string
    property :selectedDetailsForPrimaryInsured, :string
    property :partyContactSeq, :integer
    property :priority, :integer
    property :contactTypeCd, :string
    property :homeContactNum, :string
    property :homeExtensionNum, :string
    property :homeStdCode, :integer
    property :officeContactNum, :string
    property :officeExtensionNum, :string
    property :officeStdCode, :integer
    property :mobileContactNum, :string
    property :mobileExtensionNum, :string
    property :emailAddress, :string
    property :partyAddressSeq, :integer
    property :addressTypeCd, :string
    property :homeAddressSubTypeCd, :string
    property :homeAddressLine1Lang1, :string
    property :homeAddressLine1Lang2, :string
    property :homeAddressLine2Lang1, :string
    property :homeAddressLine2Lang2, :string
    property :homeAddressLine3Lang1, :string
    property :homeAddressLine3Lang2, :string
    property :homeAddressLine4, :string
    property :homeVillageCd, :string
    property :homeCountryCd, :string
    property :homeTalukaCd, :string
    property :homeDistrictCd, :string
    property :homeStateCd, :string
    property :homeCityCd, :string
    property :homePinCode, :string
    property :selectedAddressForHome, :string
    property :officeAreaCode, :string
    property :officeAddressSubTypeCd, :string
    property :officeAddressLine1Lang1, :string
    property :officeAddressLine1Lang2, :string
    property :officeAddressLine2Lang1, :string
    property :officeAddressLine2Lang2, :string
    property :officeAddressLine3Lang1, :string
    property :officeAddressLine3Lang2, :string
    property :officeAddressLine4, :string
    property :officeVillageCd, :string
    property :officeCountryCd, :string
    property :officeTalukaCd, :string
    property :officeDistrictCd, :string
    property :officeStateCd, :string
    property :officeCityCd, :string
    property :officePinCode, :string
    property :selectedAddressForOffice, :string
    property :partyFinancialAccountSeq, :integer
    property :accountCategoryCd, :string
    property :accountTypeCd, :string
    property :bankCd, :string
    property :sortCd, :string
    property :branchCd, :string
    property :bankName, :string
    property :branchName, :string
    property :accountNum, :string
    property :ledgerFolioNum, :string
    property :accountHolderName, :string
    property :cardTypeCd, :string
    property :cardExpiryDt, :date
    property :cardExpiryMnth, :string
    property :cardExpiryYear, :string
    property :accountName, :string
    property :paymentTypeCd, :string
    property :cash, :string
    property :ifscCd, :string
    property :tempReceiptNum, :string
    property :creditCardNum, :string
    property :fullName, :string
    property :refundAccountHolderName, :string
    property :refundBankName, :string
    property :refundAccNum, :string
    property :ccIssuingBankName, :string
    property :otherRelation, :string
    property :occupationCd, :string
    property :employerName, :string  
    property :grade, :string
    property :industryCd, :string
    property :natureOfDuty, :string
    property :occupationClass, :string
    property :partyIdentitySeq1, :integer
    property :identityTypeCd1, :string
    property :identityNum1, :string       
    property :expiryDt1, :date
    property :partyIdentitySeq2, :integer
    property :identityTypeCd2, :string
    property :identityNum2, :string       
    property :expiryDt2, :date
    property :signatureStatusCd, :string
    property :questionnaireStatusCd, :string
    property :documentStatusCd, :string
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string


    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyOfflineDO"
    end
       
    def self.entitiesForSync
    end
       
    def afterSync
        #puts "After sync called for party" + self.partyId.to_s
    end 
    ################################################################################
    #-------------------------------Common Code End--------------------------------#
    ################################################################################        





    ################################################################################
    #-------------------------------FWDPH Code Start-------------------------------#
    ################################################################################
    property :annualIncome, :integer, :decimal
    property :communicationPreference, :string
    property :contactPersonExtensionName, :string
    property :contactPersonTitle, :string
    property :contactPersonFirstName, :string
    property :contactPersonMiddleName, :string
    property :contactPersonLastName, :string
    property :corporateEmailAddress, :string
    property :corporateTelAreaCd, :string
    property :corporateTelCountryCd, :string
    property :corporateTelNum, :string
    property :corrByEmail, :string
    property :designation, :string
    property :extensionName, :string
    property :homeNonPhPincode, :string
    property :identityNum, :string
    property :individualNatureOfDuty, :string
    property :individualOccupationCd, :string
    property :individualOccupationClass, :string
    property :initialAccountNum, :string
    property :initialAmount, :integer, :decimal
    property :initialBankName, :string
    property :initialTransactionDt, :date
    property :initialTransactionRefNum, :string
    property :leadType, :string
    property :legalExtensionName, :string
    property :legalFirstname, :string
    property :legalMiddleName, :string
    property :legalLastName, :string
    property :mobileAreaCode, :string
    property :mobileCountryCode, :string
    property :modeOfDocuments, :string
    property :motherMaidenFirstname, :string
    property :motherMaidenLastname, :string 
    property :nomieeDesignation, :string
    property :nomineeType, :string
    property :officeAddressCountryCd, :string
    property :officeAreaCode, :string
    property :officeCountryCode, :string
    property :officeNonPhPincode, :string
    property :otherLegalName, :string
    property :otherPurpose, :string
    property :otherReligion, :string
    property :otherSourceOfFund, :string
    property :otherSourceOfFundDesc, :string 
    property :permAddressLine1Lang1, :string
    property :permAddressLine2Lang1, :string
    property :permAddressLine3Lang1, :string
    property :permAddressLine4, :string
    property :permCityCd, :string
    property :permCountryCd,         :string
    property :permDistrictCd, :string
    property :permNonPhPincode, :string
    property :permPinCode, :string
    property :position, :string
    property :preferredModeOfContact, :string
    property :purposeOfInsurance, :string
    property :refundAccountTypeCd, :string
    property :refundBankBranchName, :string
    property :relationWithPolicyHolder, :string
    property :residenceAreaCode, :string
    property :residenceCountryCode, :string
    property :selectedPermanentAddress, :string
    property :sourcePersonalBusiness, :string
    property :trusteeName, :string
    ################################################################################
    #--------------------------------FWDPH Code End--------------------------------#
    ################################################################################





    ################################################################################
    #------------------------Offline Beta v3.0 Code Start--------------------------#
    ################################################################################ 
    property :amount, :integer
    property :annualIncome, :integer
    property :approvalCd, :string
    property :autopay, :string
    property :correspondanceAddressLine1Lang1, :string
    property :correspondanceAddressLine1Lang2, :string
    property :correspondanceAddressLine2Lang1, :string
    property :correspondanceAddressLine2Lang2, :string
    property :correspondanceAddressLine3Lang1, :string
    property :correspondanceAddressLine3Lang2, :string
    property :correspondanceCountryCd, :string
    property :correspondanceDistrictCd, :string
    property :correspondancePinCode, :string
    property :correspondancePoBox, :string
    property :correspondenceTypeCd, :string
    property :correspondenceTypeCd, :string
    property :coverageCityCd, :string
    property :coverageCountryCd, :string
    property :exchangeDt, :date
    property :fatherFirstName1, :string
    property :fatherFirstName2, :string
    property :fatherMiddleName1, :string
    property :height, :integer
    property :homePoBox, :string
    property :initialRemnimbiRate, :string
    property :initialUSDRate, :string
    property :isEmployed, :string
    property :jobDescription, :string
    property :manualWorkFI, :string
    property :monthlyIncome, :string
    property :monthsWithJob, :string
    property :officePoBox, :string
    property :otherDetails, :string
    property :payerSameAs, :string
    property :paymentLimit, :integer
    property :previousJobDetails, :string
    property :proposerPartyTypeCd, :string
    property :relationship, :string
    property :selectedAddressForCorrespondance, :string
    property :selectedDetailsForPolicyHolder, :string
    property :workAtConstruction, :string
    property :workAtHeight, :string
    property :workNature, :string
    property :yearsWithJob, :string    

    has_many 'PartyFinancialAccount' 
    ################################################################################
    #-------------------------Offline Beta v3.0 Code End---------------------------#
    ################################################################################  
end

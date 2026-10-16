# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Party
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with Label.
	# enable :sync

	#add model specifc code here   
	property :roleCd, :string
	property :titleCd, :string
	property :firstName1, :string
	property :firstName2, :string
	property :middleName1, :string
	property :middleName2, :string
	property :lastName1, :string
	property :lastName2, :string
	property :extensionName1, :string
	property :extensionName2, :string
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
	property :partyId, :string
	property :partyTypeCd, :string
	property :customerId, :string
	property :corporateName1, :string
	property :corporateName2, :string
	property :religionCd, :string
	property :nonResidentFl, :string
	property :totalSAR, :integer
	property :nsap, :string
	property :smoker, :string
	property :financialSAR, :integer
	property :intimationSourceCd, :string
	property :occupationClass, :string
	property :spouseName, :string
	property :spouseSurname, :string
	property :partyContactSeq, :integer
	property :priority, :integer
	property :partyAddressSeq, :integer
	property :officeAreaCode, :string
	property :partyFinancialAccountSeq, :integer
	property :refundBankName, :string
	property :refundAccNum, :string
	property :ccIssuingBankName, :string
	property :otherRelation, :string
	property :signatureStatusCd, :string
	property :questionnaireStatusCd, :string
	property :documentStatusCd, :string
	property :removed, :string

	#added for Product version
	property :coverageCityCd, :string
	property :coverageCountryCd, :string
	property :fatherFirstName1, :string
	property :fatherFirstName2, :string
	property :fatherMiddleName1, :string
	property :fatherMiddleName2, :string
	property :fatherLastName1, :string
	property :fatherLastName2, :string

	#added for FWDPH
	property :contactPersonTitle, :string
	property :contactPersonFirstName, :string
	property :contactPersonMiddleName, :string
	property :contactPersonLastName, :string
	property :motherMaidenFirstname, :string
	property :motherMaidenLastname, :string 
	property :nomineeType, :string
	property :refundAccountTypeCd, :string
	property :refundBankBranchName, :string
	property :relationWithPolicyHolder, :string
	property :trusteeName, :string

	#new attributes
	property :copyFromAddr1, :string
	property :copyFromAddr2, :string
	property :copyFromAddr3, :string
	property :otherReligion, :string

  property :monthlyIncome, :float, :decimal
  property :annualIncome, :float, :decimal
  property :quotPartyAddtnField1, :string
  property :quotPartyAddtnField2, :string
  property :quotPartyAddtnField3, :string
  property :quotPartyAddtnField4, :string
  property :otherTitle , :string
  property :visitedTabs, :string
  property :multiLifeField1, :string
  property :multiLifeField2, :string
  property :multiLifeField3, :string
  property :quotationPartyGuid, :string
  property :educationLevelCd, :string

	#derived attributes   
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	has_many 'PartyContact'
	has_many 'PartyEmail'
	has_many 'PartyAddress'
	has_many 'PartyFinancialAccount'
	has_many 'PartyRelation'
	has_many 'PartyOccupation'
	has_many 'PartyEmployment'
	has_many 'PartyIdentity'
	has_many 'PartyAdditionalFields'
	has_many 'PartyOtherIncome'

  
  attr_accessor :entityDesc
  attr_accessor :questionContainer
  attr_accessor :issueAge
  attr_accessor :policyYear
  #For API to show PartyRole fields on UI
  attr_accessor :partySameAsCd
  attr_accessor :percentage
  attr_accessor :nomineeTypeCd
  attr_accessor :irrevocableFl
  attr_accessor :effectiveFromDt
  attr_accessor :effectiveToDt
  attr_accessor :eventTypeCd
  attr_accessor :paymentInstructionTypeCd
  attr_accessor :nomineeRefGuid
  attr_accessor :suppPartyGuid
  attr_accessor :policyPartyRoleGuid

  def getEntityDesc
    self.entityDesc = MobiSys::BrowserHelper.getLabel(self.roleCd.to_s) + " " + self.firstName1.to_s + " " + self.middleName1.to_s + " " + self.lastName1.to_s
  end
  #return the list of child classes whose context need to be evaluated along with this class.
  def contextExtendForClass
    return "PartyAdditionalFields,PartyEmployment"
  end


    #online-offline sync methods
    def self.onlineClassName
    	return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyDO"
    end

    def afterSync
    	puts "After sync called for party" + self.partyId.to_s
    end 


  	#Swati Ahire 08-04-2015: Method to get addresses related to party
  	def getPartyAddress(addressTypeCd, createNewObject=false)
  		returnPartyAddress = nil
  		self.PartyAddressList.each do |partyAddress|
  			returnPartyAddress = partyAddress if partyAddress.addressTypeCd == addressTypeCd
  		end
  		if returnPartyAddress == nil && createNewObject
  			returnPartyAddress = PartyAddress.new(:addressTypeCd => addressTypeCd)
  			self.addPartyAddress(returnPartyAddress)
  		end
  		return returnPartyAddress
  	end


  	#Avdhut Vaidya 15-04-2015: Method to get contacts related to party
  	def getPartyContact(contactTypeCd, createNewObject=false)
  		returnPartyContact = nil
  		self.PartyContactList.each do |partyContact|
  			returnPartyContact = partyContact if partyContact.contactTypeCd == contactTypeCd
  		end
  		if returnPartyContact == nil && createNewObject
  			returnPartyContact = PartyContact.new(:contactTypeCd => contactTypeCd)
  			self.addPartyContact(returnPartyContact)
  		end
  		return returnPartyContact
  	end


  	#Avdhut Vaidya 15-04-2015: Method to get email related to party
  	def getPartyEmail(createNewObject = false)
  		returnPartyEmail = nil
  		self.PartyEmailList.each do |partyEmail|
  			returnPartyEmail = partyEmail
  		end
  		if returnPartyEmail == nil && createNewObject
  			returnPartyEmail = PartyEmail.new(:emailTypeCd => "PERSONAL")
  			self.addPartyEmail(returnPartyEmail)
  		end
  		return returnPartyEmail
  	end


  	#Avdhut Vaidya 15-04-2015: Method to get employment related to party
  	def getPartyEmployment(createNewObject = false)
  		returnPartyEmployment = nil
  		self.PartyEmploymentList.each do |partyEmployment|
  			returnPartyEmployment = partyEmployment
  		end
  		if returnPartyEmployment == nil && createNewObject
  			returnPartyEmployment = PartyEmployment.new
  			self.addPartyEmployment(returnPartyEmployment)
  		end
  		return returnPartyEmployment
  	end
  

  	#Avdhut Vaidya 06-05-2015: Method to get identities related to party
  	def getPartyIdentityList(createNewObject = false)
  		returnPartyIdentityList = Array.new
  		self.PartyIdentityList.each do |partyIdentity|
  			returnPartyIdentityList.push(partyIdentity)
  		end
  		if returnPartyIdentityList.length < 2 && createNewObject
  			partyIdentity1 = PartyIdentity.new
  			self.addPartyIdentity(partyIdentity1)
  			returnPartyIdentityList.push(partyIdentity1)

  			partyIdentity2 = PartyIdentity.new
  			self.addPartyIdentity(partyIdentity2)
  			returnPartyIdentityList.push(partyIdentity2)
  		end
  		return returnPartyIdentityList
  	end 

  	def partyIdentityType
  		return self.PartyIdentityList.size > 0 ? self.PartyIdentityList[0].identityTypeCd : nil
  	end

  	#Deepali Singh 31-07-2015: Method to get party other income related to party
  	def getPartyOtherIncomeList(createNewObject = false)
  		returnPartyOtherIncomeList = Array.new
  		self.PartyOtherIncomeList.each do |partyOtherIncome|
  			returnPartyOtherIncomeList.push(partyOtherIncome)
  		end
  		return returnPartyOtherIncomeList
  	end

  	# method to get PartyAdditionalFields related to party
  	def getPartyAdditionalField(createNewObject=false)
  		returnPartyAdditionalField = self.PartyAdditionalFieldsList[0]
  		if returnPartyAdditionalField == nil && createNewObject
  			returnPartyAdditionalField = PartyAdditionalFields.new
  			self.addPartyAdditionalFields(returnPartyAdditionalField)
  		end
  		return returnPartyAdditionalField
  	end
  
  	# method to get PartyFinancialAccount related to party
  	def getPartyFinancialAccount(createNewObject=false)
  		returnPartyFinancialAccount = nil
  		returnPartyFinancialAccount = self.PartyFinancialAccountList[0]
  		if returnPartyFinancialAccount == nil && createNewObject
  			returnPartyFinancialAccount = PartyFinancialAccount.new
  			self.addPartyFinancialAccount(returnPartyFinancialAccount)
  		end
  		return returnPartyFinancialAccount
  	end

    def getFullName
      fullName = ""
      if self.firstName1.to_s != ""
        fullName = fullName + self.firstName1 + " "
      end
      if self.middleName1.to_s != ""
        fullName = fullName + self.middleName1 + " "
      end
      if self.lastName1.to_s != ""
        fullName = fullName + self.lastName1 + " "
      end
      return fullName
    end 

    def getPartyIdentity(identityType) 
      returnPartyIdentity =  nil
      self.PartyIdentityList.each do |partyIdentity|
        if partyIdentity.identityTypeCd == identityType
          returnPartyIdentity = partyIdentity
        end
      end
      return returnPartyIdentity
    end

    def getIndustryCd
      industryCd = nil
      industryCd = self.PartyEmploymentList[0].industryCd if self.PartyEmploymentList.size > 0
      return industryCd
    end

    def getOccupationCd
      occupationCd = nil
      occupationCd = self.PartyEmploymentList[0].occupationCd if self.PartyEmploymentList.size > 0
      return occupationCd
    end

    def getNatureOfDuty
      natureOfDuty = nil
      natureOfDuty = self.PartyEmploymentList[0].natureOfDuty if self.PartyEmploymentList.size > 0
      return natureOfDuty
    end

    def getOccupationTypeCd
      occupationTypeCd = nil
      occupationTypeCd = self.PartyEmploymentList[0].occupationTypeCd if self.PartyEmploymentList.size > 0
      return occupationTypeCd
    end
end

begin 
    require 'Party/party_company'
rescue LoadError => e
    puts 'party_company not included'
end
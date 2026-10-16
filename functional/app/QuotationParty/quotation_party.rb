# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationParty
    include Rhom::PropertyBag

    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'

    property :customerId, :string
    property :roleCd, :string
    property :partyOrder, :integer
    property :title, :string
    property :firstname, :string
    property :middlename, :string
    property :lastname, :string
    property :genderCd, :string
    property :dob, :date
    property :age, :integer
    property :educationCd, :string
    property :occupationCd, :string
    property :incomeGroup, :string
    property :maritalStatus, :string
    property :nsap, :string
    property :smoker, :string
    property :relationCd, :string
    property :removed, :string
    property :industryCd, :string
    property :natureOfDuty, :string
    property :firstname2, :string
    property :middlename2, :string
    property :lastname2, :string
    property :contactNum, :string
    property :emailAddress, :string
    property :coverageCountryCd, :string
    property :coverageCityCd, :string
    property :staff, :string
    property :residency, :string
    property :nationality, :string
    property :alias, :string
    property :idType, :string
    property :idNumber, :string
    property :partyTypeCd, :string
    property :corporateName, :string
    property :corporateName2, :string
    property :attainedAge, :integer
    property :addressLine1Lang1, :string
    property :addressLine2Lang1, :string
    property :addressLine3Lang1, :string
    property :addressLine4, :string
    property :stateCd,  :string
    property :cityCd,  :string
    property :pinCode,  :string
    property :stdCode,  :string
    property :extensionName, :string
    property :extensionName2, :string
    property :isdCode,  :string
    property :otherRelation, :string
    property :countryCd, :string
    property :designation, :string
    property :contactPersonTitle, :string
    property :contactPersonFirstName, :string
    property :contactPersonMiddleName, :string
    property :contactPersonLastName, :string
    property :contactPersonExtensionName, :string
    property :residentialStdCode, :string
    property :residentialIsdCode, :string
    property :residentialContactNum, :string
    property :officeStdCode, :string
    property :officeIsdCode, :string
    property :officeContactNum, :string
    property :policyYear, :integer
    property :monthlyIncome, :float, :decimal
    property :annualIncome, :float, :decimal
    property :quotPartyAddtnField1, :string
    property :quotPartyAddtnField2, :string
    property :quotPartyAddtnField3, :string
    property :quotPartyAddtnField4, :string
    property :refGuid, :string
    property :partySameAsCd, :string
    property :otherTitle, :string
    property :visitedTabs, :string
    property :multiLifeField1, :string
    property :multiLifeField2, :string
    property :multiLifeField3, :string
    property :productPlanOptionCd, :string
    property :baseSumAssured, :string
    property :modalPremium, :string
    property :baseAnnualPremium, :string
    property :educationLevelCd, :string
    
    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    attr_accessor :citizenshipCd
    attr_accessor :attainedAge
    attr_accessor :entryAge
    attr_accessor :entityDesc
    attr_accessor :issueAge
    attr_accessor :questionContainer
    attr_accessor :quotationProductExtra
  
    has_many 'QuotationPartyExtra'
    has_many 'QuotationPartyAddress'


    def getEntityDesc
        self.entityDesc = MobiSys::BrowserHelper.getLabel(self.roleCd.to_s) + " " + self.firstname.to_s + " " + self.middlename.to_s + " " + self.lastname.to_s
    end

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationPartyDO"
    end
  
    def getFullName
        fullName = ""
        if self.firstname.to_s != ""
            fullName = fullName + self.firstname + " "
        end
        if self.middlename.to_s != ""
            fullName = fullName + self.middlename + " "
        end
        if self.lastname.to_s != ""
            fullName = fullName + self.lastname + " "
        end
        return fullName
    end

    def getAddress(addressTypeCd)
        self.QuotationPartyAddressList.each do |quotationPartyAddress|
            if addressTypeCd.to_s != "" && quotationPartyAddress.addressTypeCd.to_s != "" && quotationPartyAddress.addressTypeCd.to_s == addressTypeCd.to_s
                return quotationPartyAddress
            end
        end
        return nil
    end

    #Deepali Singh 23-11-2015: Method to get Array of all PolicyPartyRole child objects of policy for a specific roleCd
    def getQuotationPartyExtra
        returnQuotationPartyExtraList = self.QuotationPartyExtraList
    end
end

begin 
    require 'QuotationParty/quotation_party_company'
rescue LoadError => e
    puts 'quotation_party_company not included'
end 

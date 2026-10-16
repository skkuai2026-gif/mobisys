# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class PaymentRequest
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
    
  property :referenceNumber, :string
  property :modalPremium, :float
  property :titleCd, :string
  property :firstName, :string
  property :middleName, :string
  property :lastName, :string
  property :genderCd, :string
  property :birthDt, :date
  property :maritalStatusCd, :string
  property :identityTypeCd, :string
  property :identityNum, :string
  property :identityExpiryDt, :date
  property :addressType, :string
  property :addressLine1, :string
  property :addressLine2, :string
  property :addressLine3, :string
  property :addressLine4, :string
  property :city, :string
  property :zipCode, :string
  property :nationality, :string
  property :placeOfBirth, :string
  property :countryCd, :string
  property :occupation, :string
  property :phoneHome, :string
  property :phoneOffice, :string
  property :phoneMobile, :string
  property :email, :string
  property :specialIndicator, :string
  property :amount, :string
  property :invoiceCode, :string

  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :industryCd, :string
  property :natureOfDuty, :string

  property :currencyCd
  property :languageCd
  property :paymentChannel
  property :successUrl
  property :failureUrl
  property :cancelUrl


  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collection.PaymentRequestDO"
  end
end

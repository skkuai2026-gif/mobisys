# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationPartyAddress
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with QuotationPartyAddress.
  # enable :sync

  #add model specifc code here
	property :addressTypeCd, :string
  property :addressSubTypeCd, :string
  property :addressLine1Lang1, :string
  property :addressLine1Lang2, :string
  property :addressLine2Lang1, :string
  property :addressLine2Lang2, :string
  property :addressLine3Lang1, :string
  property :addressLine3Lang2, :string
  property :addressLine4Lang1, :string
  property :addressLine4Lang2, :string
  property :villageCd, :string
  property :countryCd, :string
  property :talukaCd, :string
  property :districtCd, :string
  property :stateCd, :string
  property :cityCd, :string
  property :pinCode, :string
  property :poBox, :string

  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :removed, :string


  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationPartyAddressDO"
  end
    
end
begin 
  require 'QuotationPartyAddress/quotation_party_address_company'
rescue LoadError => e
  puts 'quotation_party_address_company not included'
end
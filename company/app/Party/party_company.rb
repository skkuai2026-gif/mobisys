# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Party
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
    property :eventTypeCd, :string
    property :partySameAsCd, :string
    property :nomineeTypeCd, :string

    # attr_accessor :eventTypeCd
	# Uncomment the following line to enable sync with Label.
	# enable :sync

  	def getPartyUniqueAddress(addressTypeCd, oldAddress)
  		returnPartyNewAddress = nil
  		if returnPartyNewAddress == nil && oldAddress.to_s != ""
			# returnPartyNewAddress  = PartyAddress.new(:addressTypeCd =>addressTypeCd,:addressLine1Lang1 => oldAddress.addressLine1Lang1,:addressLine2Lang1 =>oldAddress.addressLine2Lang1,:addressLine3Lang1 =>oldAddress.addressLine3Lang1,:addressLine4Lang1 =>oldAddress.addressLine4Lang1,:cityCd => oldAddress.cityCd,:pinCode => oldAddress.pinCode, :countryCd => oldAddress.countryCd, :districtCd => oldAddress.districtCd, :villageCd => oldAddress.villageCd)
  			self.addPartyAddress(returnPartyNewAddress)
  		end
  		return returnPartyNewAddress
  	end

  	def industryCd
      industryCd = nil
      industryCd = self.PartyEmploymentList[0].industryCd if self.PartyEmploymentList.size > 0

      return (industryCd.to_s != '' ? industryCd : nil)
    end

    def occupationCd
      occupationCd = nil
      occupationCd = self.PartyEmploymentList[0].occupationCd if self.PartyEmploymentList.size > 0
      return (occupationCd.to_s != '' ? occupationCd : nil)
    end

    def additionalContextObjectList(policy)
        additionalContextList = []
        baseProduct = policy.getBaseProduct if policy
        additionalContextList << baseProduct if baseProduct
        return additionalContextList
    end

end

begin 
    require 'Party/party_company'
rescue LoadError => e
    puts 'party_company not included'
end
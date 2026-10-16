# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationParty
    include Rhom::PropertyBag

    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'

    def getAddress(addressTypeCd, createNewObject=false)
        returnPartyAddress = nil
        self.QuotationPartyAddressList.each do |quotationPartyAddress|
            returnPartyAddress = quotationPartyAddress if quotationPartyAddress.addressTypeCd == addressTypeCd
        end
        if returnPartyAddress == nil && createNewObject
            returnPartyAddress = QuotationPartyAddress.new(:addressTypeCd => addressTypeCd)
            self.addQuotationPartyAddress(returnPartyAddress)
        end
        return returnPartyAddress
    end
end
 

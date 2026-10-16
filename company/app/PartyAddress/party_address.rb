# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyAddress
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :addressTypeCd, :string
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
    
    #Swati Ahire 06-04-2015: Newly added fields
    property :poBox, :string
    property :moduleType, :string
    property :correspondenceTypeCd, :string

    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string  


    attr_accessor :entityDesc

    def getEntityDesc
        if self.entityDesc.to_s == ""
            ofLabel = LabelValue.getLabel("of",Application.getValue('DEFAULTLOCALE').value)
            spaceLabel = LabelValue.getLabel("SPACE",Application.getValue('DEFAULTLOCALE').value)
            #Adding Party roleCd in entityDesc for better understanding.
            party = Party.loadObject(:first, :conditions => {:object => (self.parentKey).to_s}, :loadChild => false)
            self.entityDesc = MobiSys::BrowserHelper.getLabel(self.addressTypeCd.to_s) + " address"
            self.entityDesc = self.entityDesc.to_s + spaceLabel + ofLabel + spaceLabel + party.getEntityDesc if party
            if  self.addressTypeCd.to_s == "MAILING"
                self.entityDesc = MobiSys::BrowserHelper.getLabel("emailID") + " and " +MobiSys::BrowserHelper.getLabel("CONTACTINFORMATION")
            end
        end
        
        return self.entityDesc
    end

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyAddressDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for party address"
    end 
end

begin
    require 'PartyAddress/party_address_company'
rescue LoadError => e
    puts 'party_address_company not included'
end
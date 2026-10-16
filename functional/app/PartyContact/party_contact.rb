# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyContact
    include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :contactTypeCd, :string
    property :countryCd, :string
    property :stdCode, :string
    property :contactNum, :string
    property :extensionNum, :string
    property :partyAddressSeq, :string
    property :priority, :string

    #derived attributes  
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
        self.entityDesc = MobiSys::BrowserHelper.getLabel(self.contactTypeCd.to_s)
    end

    #online-offline sync methods
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyContactDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
        puts "After sync called for party contact"
    end 
end

begin 
    require 'PartyContact/party_contact_company'
rescue LoadError => e
    puts 'party_contact_company not included'
end
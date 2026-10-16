# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyEmail
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :emailAddress, :string
    property :emailTypeCd, :string

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
            self.entityDesc =  spaceLabel + ofLabel + spaceLabel + party.getEntityDesc if party
        end

        return self.entityDesc
    end

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyEmailDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for party email"
    end 
end

begin 
    require 'PartyEmail/party_email_company'
rescue LoadError => e
    puts 'party_email_company not included'
end
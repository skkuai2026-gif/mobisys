# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyOccupation
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
    property :partyOccupationSeq, :int
    property :businessType, :string
    property :occupationCd, :string
    property :occupationTypeCd, :string
    property :natureOfDuty, :string
    property :jobScope, :string
    property :occupationName, :string
    property :position, :string
    property :occupationClass, :string
    property :occupationGroupName, :string
    property :occupationGroupCode, :string
    property :income, :integer
    property :derivedOccupationClass, :string
    property :emailCorrespondence, :string
    property :companyName, :string
    property :grade, :string

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
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyOccupationDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      puts "After sync called for party occupation      "
   
    end 
end

begin 
    require 'PartyOccupation/party_occupation_company'
rescue LoadError => e
    puts 'party_occupation_company not included'
end

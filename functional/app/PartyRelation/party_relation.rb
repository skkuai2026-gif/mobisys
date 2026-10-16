# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyRelation
  include MobiSys::MobiSysEntitySchema
  
      set :schema_version, '1.0'
          
      # Uncomment the following line to enable sync with Label.
      # enable :sync
    
      #add model specific code here
      property :partyRelationSeq, :int
      property :relationCd, :string
      property :otherRelation, :string
      property :relatedToPartyId, :string
      property :roleCd, :string
     
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
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyRelationDO"
      end
end

begin 
    require 'PartyRelation/party_relation_company'
rescue LoadError => e
    puts 'party_relation_company not included'
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Lead
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'

    # Uncomment the following line to enable sync with Lead.
    # enable :sync
  
    #add model specifc code here
    property :leadId,       :string
    property :statusCd,     :string
    property :fromTime,     :time
    property :toTime,       :time
    property :leadUpdatedDt, :string
    property :leadSource,   :string
    property :leadSourceOther,    :string
    property :leadStatus,   :string
    property :closureNotes, :string
    property :visitedTabs, :string
    property :partyRefGuid, :string
    
    # derived attributes  
    property :userId,       :string
    property :parentKey,    :string
    property :versionID,    :integer
    property :id,           :integer
    property :guid,         :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :quotationSeq, :fnaSeq, :insuranceTypeCd

    has_many 'LeadActivity'
    has_many 'Party'
    
    
    # model specific methods
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.lead.LeadDO"
    end
    
    #def self.entitiesForSync
    #  entitiesForSync = Lead.loadObject(:all)
    #end
    
    def afterSync
      puts "After sync called for lead " + self.leadId.to_s    
    end

    def getLeadParty
        leadParty = (self.PartyList.size > 0 ? self.PartyList[0] : nil)
        return leadParty
    end

    def getEntityTypeCd
      entityTypeCd = self.entityTypeCd
      entityTypeCd = "LEAD" if entityTypeCd.to_s == ""
      return entityTypeCd
    end
end

begin 
    require 'Lead/lead_company'
rescue LoadError => e
    puts 'lead_company not included'
end
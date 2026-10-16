# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here


class PolicyPartyContainer
  include MobiSys::MobiSysEntitySchema
  
  property :partyGuid, :string
  property :partyName, :string
  property :partyRole, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  attr_accessor :questionSets

  # Uncomment the following line to enable sync with QuestionContainer.
  # enable :sync

  #add model specific code here
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyPartyContainerDO"
    end
end

begin 
    require 'DocumentContainer/document_container_company'
rescue LoadError => e
    puts 'document_container_company not included'
end

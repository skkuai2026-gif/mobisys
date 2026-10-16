# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here

require 'CommonModules/entityschema'

class QuestionContainer
    include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'

    property :entityGuid, :string
    # entityGuid is treated as PartyGuid  
    property :entityTypeCd, :string
    property :policyGuid, :string
    # In policyGuid when entity is Policy, policyGuid is set and when entity is Quotation quotationGuid is set
    property :additionalFieldQuest, :string

    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    attr_accessor :removed, :questionnaireTypeCd

    has_many 'ServiceQuestionResponse'
    has_many 'QuestionContainer'


    def self.onlineClassName
        return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.QuestionContainerDO" 
    end
end

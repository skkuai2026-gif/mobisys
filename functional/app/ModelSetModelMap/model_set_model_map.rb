# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class ModelSetModelMap
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master

    property :computationOrder, :string
    property :modelCd, :string
    property :ruleSeq, :integer

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    #Accessor to hold respective IllustrationModelDO
    attr_accessor :model
    
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ModelSetModelMapDO"
    end
end

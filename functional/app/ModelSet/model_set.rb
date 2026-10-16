# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class ModelSet
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master

    property :modelSetCd, :string
    property :modelSetDesc, :string
    property :modelSetFor, :string

    # derived attributes
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'ModelSetModelMap'
    
    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ModelSetDO"
    end
end

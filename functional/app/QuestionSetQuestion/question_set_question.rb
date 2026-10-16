# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class QuestionSetQuestion
  include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master  

    # Uncomment the following line to enable sync with Product.
    # enable :sync
  
    #add model specifc code here
    property :questionSetCd, :string
    property :dataElementCd, :string
    property :questionCd, :string
    property :question, :string
    property :displayOrder, :integer
    property :conditional, :string
    property :weight, :int
    property :inputTypeCd, :string
    property :reflexiveValue, :string
    property :mandatory, :string
    property :minValue, :int
    property :maxValue, :int
    property :maxLength, :int
    property :dataElementType, :string
    property :lookupkey, :string
    property :visibility, :string
    property :enabled, :string
    property :applyOn, :string
    property :expression, :string
    # field name is documentCd but it is used as documentCategory
    property :documentCd, :string
    property :displayNumber, :string
    property :entityFieldTypeCd, :string
    property :impactedQSetCd, :string
    property :modelCd, :string
    property :otherMetadataProps, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.QuestionSetQuestionDO"
    end
    
    def afterSync
      #puts "After sync ProductDO called..."
    end
      

end

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class IllustrationFacet
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.1'
  set :partition, :master 

  # Uncomment the following line to enable sync with Product.
  # enable :sync

  #add model specifc code here  
  property :facetTypeCd, :string
  property :inputElementSource, :string
  property :inputDataElement, :string
  property :computedElementName, :string
  property :computationOrder, :integer
  property :computationFreqCd, :string
  property :computePerInstanceOf, :string
  property :elementLabel, :string
  property :outputDisplayTypeCd, :string
  property :displayColumnOrder, :integer
  property :expression, :string
  property :expressionForLowRate, :string
  property :expressionForHighRate, :string
  property :expressionForMediumRate, :string
  property :expressionForDisplay, :string
  property :origExpression, :string
  property :facetId, :integer
  property :ruleSeq, :integer
  property :computedFieldNameForRule, :string
  property :parseLevel, :integer
  property :elementFilter, :string
  property :rateTypeCd, :string
  property :isSystemFl, :string
  property :partyRoleCdForRule, :string
  property :entityFieldTypeCd, :string
  property :entityDataTypeCd, :string
  property :lookupkey, :string
  property :rangeValueFl, :string
  property :dtColumnNames, :string
  property :origElementName, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  attr_accessor :originalComputedElementName, :isBreakExpression, :groupingName
  
  index :ift_parentKey, [:parentKey]

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.IllustrationFacetDO"
  end
  
  def methodName
    @methodName ||= :"#{self.computedElementName}_m"
  end

  def mapSetter
    @mapSetter ||= :"#{self.inputDataElement}="
  end

  def mapGetter
    @mapGetter ||= self.inputDataElement.to_sym
  end

  def setter
    @setter ||= :"#{self.computedElementName}="
  end

  def getter
    @getter ||= self.computedElementName.to_sym
  end

  def parseLevelInt
    @parseLevelInt ||= parseLevel.to_i
  end
  
  def afterSync
    #puts "After sync Illustration facet called..."
  end
end

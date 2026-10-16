# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class IllustrationRate
  include MobiSys::MobiSysFixedSchema
    
  set :schema_version, '1.0'
  set :partition, :master

  # Uncomment the following line to enable sync with IllustrationRate.
  # enable :sync

  #add model specifc code here
  
  property :rateTypeCd, :string
  property :rate, :float
  property :policyYearFrom, :integer
  property :policyYearTo, :integer
  property :fundCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  attr_accessor :illustrationFacetList
  
  index :irt_parentKey, [:parentKey]
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.IllustrationRateDO"
  end
  
  def addIllustrationFacet(ift)
    @illustrationFacetList = Array.new unless @illustrationFacetList
    @illustrationFacetList.push ift
  end
  
end

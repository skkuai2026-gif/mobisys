 # The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'

class ProductModelDecisionTable
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master 

  # Uncomment the following line to enable sync with Product.
  # enable :sync

  #add model specifc code here  
  property :dtCondition1d, :float
  property :dtCondition11d, :float
  property :dtCondition2d, :float
  property :dtCondition22d, :float
  property :dtCondition3d, :float
  property :dtCondition33d, :float
  property :dtCondition4d, :float
  property :dtCondition44d, :float
  property :dtCondition4str, :string
  property :dtCondition5str, :string
  property :dtCondition6str, :string
  property :dtCondition7str, :string
  property :dtCondition8str, :string
  property :dtCondition8d, :float
  property :dtCondition9d, :float
  property :dtCondition13dt, :date
  property :dtCondition14dt, :date
  property :rate, :float
  property :outputAction, :string
  property :minValue, :float
  property :maxValue, :float
  property :dtAction1Str, :string
  property :dtAction2Str, :string
  property :dtAction3Str, :string
  property :dtAction4Str, :string
  property :dtAction5d, :float
  property :illustrationModelSeq, :integer
  property :indexKey, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  index :PMDT_illustrationModelSeq, [:illustrationModelSeq]
  index :PMDT_IMS_indexkey, [:illustrationModelSeq,:indexKey]
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ProductModelDecisionTableDO"
  end
  
  def afterSync
    #puts "After sync ProductModelDecisionTable called..."
  end
end

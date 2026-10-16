# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Level2
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with Level2.
  # enable :sync

  #C2L add model specifc code here
  
  property :levelCd, :string
  property :icon, :string
  property :header, :string
  property :text, :string
  property :layout, :string
  property :sortOrder, :integer
  property :level1_levelCd, :string
  property :collateralView, :string
  
  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.from_json(o)
    level2 = Level2.new
    level2.levelCd = o["levelCd"]
    level2.icon = o["icon"]
    level2.header = o["header"]  
    level2.text = o["text"]  
    level2.layout = o["layout"]
    level2.sortOrder = o["sortOrder"]
    level2.level1_levelCd = o["level1Ref"]
    level2.versionId = o["versionID"]
    return level2
  end
  
  def self.onlineClassName
  	return "com.c2lbiz.symbiosys.collateral.dataobjects.Level2"
  end

  def self.entitiesForSync
  	return []
  end
  
  def afterSync
  end  
  
end

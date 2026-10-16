# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Level1
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with Level1.
  # enable :sync

  #C2L add model specifc code here
  
  property :levelCd, :string
  property :name, :string
  property :icon, :string
  property :text, :string
  property :layout, :string
  property :sortOrder, :integer
  property :collateralView, :string
  property :level0_levelCd, :string  

  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.from_json(o)
    level1 = Level1.new
    level1.levelCd = o["levelCd"]
    level1.name = o["name"]
    level1.icon = o["icon"]
    level1.text = o["text"]
    level1.layout = o["layout"]
    level1.sortOrder = o["sortOrder"]
    level1.collateralView = o["collateralView"]
    level1.level0_levelCd = o["level0Ref"]
    level1.versionId = o["versionID"]
    return level1
  end
  
	def self.onlineClassName
      return "com.c2lbiz.symbiosys.collateral.dataobjects.Level1"
  end
  
  def afterSync
  end  

end

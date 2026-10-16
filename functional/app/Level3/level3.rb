# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Level3
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  property :levelCd, :string
  property :name, :string
  property :icon, :string
  property :text_h, :string
  property :text_f, :string
  property :layout, :string
  property :sortOrder, :integer
  property :level2_levelCd, :string
  property :collateralView, :string
  
  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.from_json(o)
    level3 = Level3.new
    level3.levelCd = o["levelCd"]
    level3.name = o["name"]
    level3.icon = o["icon"]
    level3.layout = o["layout"]
    level3.sortOrder = o["sortOrder"]
    level3.text_h = o["text_h"]
    level3.text_f = o["text_f"]  
    level3.level2_levelCd = o["level2Ref"]
    level3.versionId = o["versionID"]
    return level3
  end
        
  def self.onlineClassName
  	return "com.c2lbiz.symbiosys.collateral.dataobjects.Level3"
  end

  def self.entitiesForSync
  	return []
  end
  
  def afterSync
  end  
  
end

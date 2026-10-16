# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Level4
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'
    
  property :levelCd, :string
  property :name, :string
  property :icon, :string
  property :text_h, :string
  property :text_f, :string
  property :layout, :string
  property :sortOrder, :integer
  property :collateralView, :string
  property :level3_levelCd, :string

  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.from_json(o)
    level4 = Level4.new
    level4.levelCd = o["levelCd"]
    level4.name = o["name"]
    level4.icon = o["icon"]
    level4.layout = o["layout"]
    level4.sortOrder = o["sortOrder"]
    level4.text_h = o["text_h"]
    level4.text_f = o["text_f"]
    level4.collateralView = o["collateralView"]    
    level4.level3_levelCd = o["level3Ref"]
    level4.versionId = o["versionID"]
    return level4
  end
    
  def self.onlineClassName
  	return "com.c2lbiz.symbiosys.collateral.dataobjects.Level4"
  end

  def self.entitiesForSync
  	return []
  end
  
  def afterSync
  end  

end

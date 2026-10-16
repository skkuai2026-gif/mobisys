# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class Level0
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'
    
  # Uncomment the following line to enable sync with Level0.
  # enable :sync

  #C2L add model specifc code here
  
  property :levelCd, :string
  property :name1, :string
  property :name2, :string
  property :icon, :string
  property :layout, :string
  property :sortOrder, :integer
  property :menu, :string
  property :landingPage, :string
  property :text, :string
  
  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.from_json(o)
    level0 = Level0.new
    level0.levelCd = o["levelCd"]
    level0.name1 = o["name1"]
    level0.name2 = o["name2"]
    level0.icon = o["icon"]
    level0.layout = o["layout"]
    level0.sortOrder = o["sortOrder"]
    level0.menu = o["menu"]
    level0.landingPage = o["landingPage"]
    level0.text = o["text"]
    level0.versionId = o["versionID"]
    return level0
  end
  
  def self.onlineClassName
		return "com.c2lbiz.symbiosys.collateral.dataobjects.Level0"
	end

	def self.entitiesForSync
		return []
	end
	
  def afterSync
  end  
  
end

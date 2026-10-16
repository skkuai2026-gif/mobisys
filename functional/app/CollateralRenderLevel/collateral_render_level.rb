# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
require 'CommonModules/entityschema'
class CollateralRenderLevel
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
	# Uncomment the following line to enable sync with Collateral.
	# enable :sync

	#C2L add model specifc code here

	property :levelCd, :string
	property :levelDesc, :string
	property :parentLevelCd, :string
	property :childLayoutTypeCd, :string
	property :sortOrder, :integer
	property :header1, :string
	property :header2, :string
	property :icon, :integer
	property :contentEmbedTypeCd, :string
	property :contentPart1TypeCd ,:string
	property :contentPart1, :string
	property :contentPart2TypeCd, :string
	property :contentPart2, :string
	property :footer1, :string
	property :footer2, :string
	property :countPerRow, :string
	property :previousMenuFl, :string

	# derived attributes
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
  
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collateral.CollateralRenderLevelDO"
	end

	# def self.entitiesForSync
	# 	#entitiesForSync = Collateral.loadObject(:all, :conditions => {{:name => "colStatus",:op => "NOT" } => "PRESEEDED" })
	# 	return []
	# end
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineApplication
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master 
	# Uncomment the following line to enable sync with Application.
	# enable :sync

	#add model specifc code here
	property :property, :string
	property :value, :string
	property :description, :string
	property :usage, :string
	property :requiredOnUIFl, :string

	# derived attributes
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.systemcommon.dataobjects.security.ApplicationDO"
	end
end
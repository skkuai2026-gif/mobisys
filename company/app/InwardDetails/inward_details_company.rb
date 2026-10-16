# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class InwardDetails  
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.3'

	# Uncomment the following line to enable sync with InwardDetail.
	# enable :sync

	#add model specifc code here
	property :authCode, :float, :decimal
	property :midCd, :string
end

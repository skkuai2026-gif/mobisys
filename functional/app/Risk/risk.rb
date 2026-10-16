# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Risk
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with PolicyTopUp.
	# enable :sync

	#add model specifc code here
	property :uwTypeCd, :string
	property :riskCd, :string
	property :riskTypeCd, :string
	property :riskDescription, :string
	property :parentRiskCd, :string
	property :systemUser, :string
	property :isCategory, :string

	# derived attributes
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time


	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.RiskDO"
	end
end
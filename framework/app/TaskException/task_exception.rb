# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class TaskException
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	#add model specifc code here
	property :exceptionTypeCd, :string
	property :exceptionCd, :string
	property :exceptionMessage, :string
	property :correspondenceMessage, :string
	property :exceptionStatusCd, :string
	property :fieldReference, :string
	property :overridable, :string
	property :deferable, :string
	property :deferTillTaskCd, :string
	property :chaseFlag, :string
	property :overrideFlag, :string
	property :chaseTemplateCd, :string
	property :deferTillStageCd, :string
	property :externalReqmtCd, :string
	property :serviceSeq, :string
	property :exceptionSeq, :integer
	property :entitySeq, :string 
	property :overrideAuthLevel, :integer
	property :tabId, :string
	property :correspondenceMessage, :string

	# derived attributes
	property :userId, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string

	index :TE_EntitySeq, [:entitySeq]

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.TaskExceptionDO"
	end   
end
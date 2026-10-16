#encoding: UTF-8
require "CommonModules/schema_module"

class ReleaseDTScript
    include MobiSys::MobiSysEntitySchema
    # include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    # set :partition, :master
  
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here

    property :releaseManagementDtlSeq, :integer
    property :dtScript, :string
    property :guid, :string

	# derived attributes
    property :parentKey, :string
	property :userId, :string
    property :versionID, :integer
    property :id, :integer
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time


	def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.ReleaseDTScriptDO"
    end

end
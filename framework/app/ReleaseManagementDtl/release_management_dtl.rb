#encoding: UTF-8
require "CommonModules/schema_module"

class ReleaseManagementDtl
    include MobiSys::MobiSysEntitySchema
    # include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    # set :partition, :master
  
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specifc code here
	property :releaseManagementSeq, :integer;
	property :entityGuid, :string;
	property :description, :string;
	property :releaseEntityTypeCd, :string;
	property :effectiveDate, :date;

	# derived attributes
    property :parentKey, :string
	property :userId, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many "ReleaseDTScript"

	def self.onlineClassName
      return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.ReleaseManagementDtlDO"
    end

end
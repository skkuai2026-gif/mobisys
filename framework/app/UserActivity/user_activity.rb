# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class UserActivity
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with UserActivity.
  # enable :sync

  #add model specifc code here
  property :uri, :string
  property :params, :string
  property :executionTime, :time
  property :mobiSysDeviceId, :string
  property :deviceSeq, :integer
  property :entityType, :string 
  property :entityRefNumber, :string

  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
    
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.mobisys.dataobjects.UserActivityDO"
  end
  
  def afterSync
    self.delete
  end
    
end

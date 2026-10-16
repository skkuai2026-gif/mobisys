# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
class UserLoginHistory
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'

  property :osVersion, :string
  property :modeCd, :string
  property :loginDt, :time
  property :logoutDt, :time
  property :ip, :string
  property :deviceId, :string
  property :dbVersion, :string
  property :browser, :string
  property :applicationVersion, :string
  property :activity, :string

  # derived attributes
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.security.UserLoginHistoryDO"
  end
  
  
  def afterSync
    self.delete
  end 
end

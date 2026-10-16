# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class SyncActivity
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with SyncActivity.
  # enable :sync

  #add model specifc code here
  property :startDate, :time
  property :endDate, :time
  property :synchronizationType, :string
  property :deviceSeq, :integer
  property :applicationVersion, :float 
  property :dbVersion, :float
  property :dbVersionBeforeSync, :float
  property :dbVersionAfterSync, :float
  property :statusCd, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
    
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.mobisys.dataobjects.SyncActivityDO"
  end

  def self.createNew(synchronizationType)
    newSyncActivity = SyncActivity.new
    newSyncActivity.synchronizationType = synchronizationType
    newSyncActivity.startDate = Time.now
    newSyncActivity.deviceSeq = Application.getValue('deviceSeq').value
    newSyncActivity.applicationVersion =  Rho::RhoConfig.app_version
    newSyncActivity.dbVersion = Application.getValue('DBVERSION').value
    newSyncActivity.dbVersionBeforeSync = Application.getValue('DBVERSION').value
    return newSyncActivity
  end  

  def setErrored
    self.statusCd = 'ERROR'
    self.endDate = Time.now
    self.dbVersionAfterSync = Application.getValue("DBVERSION").value
  end

  def setSuccess
    self.statusCd = 'SUCCESS'
    self.endDate = Time.now
    self.dbVersionAfterSync = Application.getValue("DBVERSION").value
  end  

  def afterSync
    self.delete
  end
    
end

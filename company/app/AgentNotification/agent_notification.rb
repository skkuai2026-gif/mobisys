require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class AgentNotification
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.1'

  # Uncomment the following line to enable sync with Label.
  # enable :sync

  # add model specific code here

  property :agentId, :string
  property :notificationDt, :time
  property :notificationSubject, :string
  property :notificationBody, :string
  property :startDt, :time
  property :endDt, :time
  property :statusCd, :string
  property :notificationType, :string
  property :deleteFlag, :string
  property :entityType, :string
  property :entityGuid, :string
  property :entityRefNum, :string
  property :functionRef, :string
  property :channelId, :string

  # derived attributes
  property :userId, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
      return "com.c2lbiz.symbiosys.company.dataobjects.AgentNotificationDO"
  end

  def self.entitiesForSync
    lastSyncDate = Time.at(0)
    lastSyncDateAppObject = Application.getValue("AgentNotification_" + $userId + '_lastSyncDate')
    if lastSyncDateAppObject
      lastSyncDate = Time.load(lastSyncDateAppObject.value)
    end
    entitiesForSync = []
    agentNotifications = AgentNotification.loadObject(:all)
    agentNotifications.each do |agentNotification|
      if Time.parse(agentNotification.systemUpdatedDt) > Time.parse(lastSyncDate.to_s)
        entitiesForSync.push agentNotification
      end
    end
    return entitiesForSync
  end
end
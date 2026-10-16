# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class AgentReg
  include Rhom::FixedSchema
  
  set :schema_version, '1.0'

  property :activeDays, :integer
  property :agentDesignation, :string
  property :agentId, :string
  property :regPass, :string
  property :applicableProducts, :string
  property :channel, :string
  property :deviceUserSeq, :integer
  property :guid, :string   
  property :licenseIssueDt, :time
  property :agentStatusCd, :string
  property :subChannel, :string
  property :userId, :string
  property :lastLogin, :time
  property :lastSyncDt, :time
  property :licenseExpiryDt, :time
  property :parentAgency, :string
  property :agentClassification, :string
  property :offlineunsuccessfulCount, :integer
  property :userDataDeleteDays, :integer
  property :parentAgencyId, :string
  property :designationId, :string
  property :licenseType, :string
  property :emailId, :string
  property :agentName1, :string
  property :agentName2, :string
  property :joiningDate, :string
  property :mobileNo, :string
  property :offlineAccessFlag, :string
  property :location, :string
  property :field1, :string
  property :field2, :string
  property :field3, :string
  property :field4, :string
  property :field5, :string
  property :field6, :string
  property :field7, :string
  property :field8, :string
  property :field9, :string
  property :field10, :string
  property :field11, :string
  property :field12, :string
  property :field13, :string
  property :field14, :string
  property :field15, :string
  property :agentField11, :string
  property :agentField12, :time
  property :agentField13, :string
  property :agentField14, :string
  property :agentField15, :string
  property :agentField16, :string
  property :agentField17, :string
  property :agentField18, :string
  property :agentField19, :string
  property :agentField20, :string
  property :agentField21, :string
  property :agentField22, :time
  property :agentField23, :string
  property :agentField24, :string
  property :agentField25, :string
  property :agentField26, :string
  property :agentField27, :string
  property :agentField28, :string
  property :agentField29, :string
  property :agentField30, :string
  property :collateralLevelCd, :string  
  property :applicableMenus, :string
  property :enableFingerprintAuth, :string
  property :userAlias, :string
  property :applicableMenusJson, :string
  property :applicableAgentGroups, :string
  property :userLeadDataDeleteDays, :integer
  property :managerAgentId, :string
  
  def self.forAgentId(agentId)
    return AgentReg.find(:first,:conditions=>{'agentId'=>agentId})
  end

  def self.forUserId(userId, returnEncrypted=false)
    agent = nil
    AgentReg.find(:all).each do |agentReg|
      if userId == MobiSys::Encryption.decryptContent(agentReg.userId)
        agentReg.userId = MobiSys::Encryption.decryptContent(agentReg.userId) if !returnEncrypted
        agent = agentReg
        break;
      end
    end
    return agent
  end  
  
  def self.getCurrentAgentReg
    return forUserId($userId)
  end
  
  def self.updateLastSyncDate
    agentReg = forUserId($userId, true)
    agentReg.lastSyncDt = Time.dump(Time.now)
    agentReg.save 
  end

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.mobisys.dataobjects.AgentRegDO"
  end
  
  def self.entitiesForSync
    
  end

  def afterSync
    
  end

  def self.setOfflineServerURL(serverURL = "")
    $rhoconfig[:offline_server_url] = serverURL["offlineServerURL"] if serverURL.to_s != ""
  end

  def self.getRhodesUserFolderPath
    Rho::Application.userFolder
  end

  def self.getRhodesPublicFolderPath
    Rho::Application.publicFolder
  end
  
end
begin 
  require 'AgentReg/agent_reg_company'
rescue LoadError => e
  puts 'agent_reg_company not included'
end
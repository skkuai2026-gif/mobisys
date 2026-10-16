require 'CommonClasses/BaseModel'

module MobiSys
	
	class PolicyAgentListModel < BaseModel
		include MobiSys::BrowserHelper

		def initialize(io)
			#puts "~~~in PolicyAgentListModel initialize: #{io.inspect}"
        	super(io)
			#puts "~~~baseIO:#{self.baseIO}"
		end

		def getModel
			#logInfo("~~~baseIO in PolicyAgentListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            policy = self.parentBaseDO
			policyAgentList = policy.getPolicyAgentList(false)

			if policyAgentList.size == 0
				policyAgent = PolicyAgent.new
				policyAgentList.push(policyAgent)
				
				agentRegdetails = AgentReg.forUserId($userId)
				if agentRegdetails
					policyAgent.agentId = agentRegdetails.agentId
					policyAgent.agentName = agentRegdetails.agentName1
					policyAgent.channelId = agentRegdetails.channel
				end

				policyAgent.commPercent = "100"
				policyAgent.prodnPercent = "100"
				policyAgent.jointFieldWork = "NO"
				policyAgent.primaryAgentFl = "YES"
			end

			return policyAgentList
		end

		def setModel(entity)
			if entity != nil and entity.size > 0
				entity.each{|policyAgent|  self.parentBaseDO.addPolicyAgent(policyAgent) }
			end
			
			return entity
		end

	end
end

begin 
    require 'Policy/PolicyAgentListModel_company'
rescue LoadError => e
    puts 'PolicyAgentListModel_company not included'
end
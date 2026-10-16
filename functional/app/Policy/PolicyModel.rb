require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class PolicyModel < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			#logInfo "~~~baseIO in getPolicyModel:#{self.baseIO.inspect}"
			unless @baseIO.baseDO
				@baseIO.baseDO = Policy.new
				policy = @baseIO.baseDO
		        agentRegDetails = AgentReg.forUserId($userId)

				if policy.baseAgentId.to_s == ""
					policy.baseAgentId = $userId 
					policy.branchCd = agentRegDetails.location if agentRegDetails
				end
				if policy.proposalEntryDt.to_s == ""
					policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
				end
				if policy.proposalReceivedDt.to_s == ""
					policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
				end

				policy.startDt = getDBDate(policy.startDt) if policy.startDt.to_s != ''
    			policy.endDt = getDBDate(policy.endDt) if policy.endDt.to_s != ''
			end
			#Set insuredSameAsProposer flag to show/hide party info on Insured Tab 
			primaryPartyRole = @baseIO.baseDO.getPolicyPartyRole("PRIMARY")
    		@baseIO.baseDO.insuredSameAsProposer = (primaryPartyRole.partySameAsCd.to_s == "PROPOSER") if primaryPartyRole != nil
    		$currentProduct ||= ProductUtil.getProduct(@baseIO.baseDO.baseProductSeq) if @baseIO.baseDO.baseProductSeq.to_s != ""

    		#Add data for non face-to-face
    		if @baseIO.baseDO.allocatedToRole.to_s == ""
				companyFacet = CompanyFacet.find(
	                :first,
	                :conditions => {
	                    { :name => 'facetCd' } => 'NONFACETOFACE'
	                }
	            )
	            if companyFacet && companyFacet.actionValue.to_s == "YES"
	            	@baseIO.baseDO.allocatedToRole = "AGENT"
	            	@baseIO.baseDO.allowModifyAllRoles = "YES"
	            else
	            	@baseIO.baseDO.allocatedToRole = "NA"
	            end
	        end

    		#Lookup Data added for Non Face-to-Face functionality
    		partyNamesHM = {}
    		if @baseIO.baseDO.getPartyNames.size > 0
				@baseIO.baseDO.getPartyNames.each do |partyGuid, partyDesc|
					partyDescList = partyDesc.split("-")
					partyRole = partyDescList.first
					partyRoleList = partyRole.split("/").uniq
					partyNamesHM[partyGuid] = partyRoleList.join("/")+":"+partyDescList[1].to_s
				end
			end
    		MobiSys::CommonUtil.addLookupData(@baseIO, "PARTYNAMES", partyNamesHM)

    		@baseIO.baseDO.quotationSeq = @baseIO.baseDO.quotationRefGuid.gsub("_",".") if @baseIO.baseDO.quotationRefGuid.to_s != ""

			return @baseIO.baseDO
		end
	end
end

begin 
    require 'Policy/PolicyModel_company'
rescue LoadError => e
    puts 'PolicyModel_company not included'
end
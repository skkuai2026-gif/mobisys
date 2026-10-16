require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class PolicyModel_SUNPH < BaseModel
		include MobiSys::BrowserHelper

		def getModel
			# logInfo "~~~baseIO in getPolicyModel:#{self.baseIO.inspect}"
			unless @baseIO.baseDO
				@baseIO.baseDO = Policy.new
				policy = @baseIO.baseDO
		        agentRegDetails = AgentReg.forUserId($userId)
                # puts "agentRegDetails====#{agentRegDetails}"
                # p "policy======#{policy}"
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
            if primaryPartyRole && (primaryPartyRole.partySameAsCd.to_s == "" || primaryPartyRole.partySameAsCd == nil) && primaryPartyRole.roleCd.to_s == "PRIMARY"
               if (@baseIO.baseDO.quoteProposerSameAsInsured.to_s == "YES" || @baseIO.baseDO.quoteProposerSameAsInsured.to_s == "COPYFROMINSURED")
               	    primaryPartyRole.partySameAsCd = "PROPOSER"
               end	
            end 
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
    		primaryRole = @baseIO.baseDO.getPartyByRole("PRIMARY")
    		policyAddtn = @baseIO.baseDO.getPolicyAddionalField("000") 
            if @baseIO.baseDO && @baseIO.baseDO.allocationPartyGuidList.to_s != "" && primaryRole && primaryRole.age.to_s != "" &&  primaryRole.age.to_i < 18
               if policyAddtn && (policyAddtn.field11.to_s == "" || policyAddtn.field11.to_s == "N")
	               	guidList = @baseIO.baseDO.allocationPartyGuidList.split(",")
	                partyList = []
	                guidList.each do |guid|
				      trimmedGuid = guid.nil? ? nil : guid.strip

				      next if !trimmedGuid.nil? &&
				              trimmedGuid.casecmp(primaryRole.guid).zero?

				      partyList << trimmedGuid
				    end

				    if partyList.any?
				      @baseIO.baseDO.allocationPartyGuidList = partyList.join(",")
				    else
				      @baseIO.baseDO.allocationPartyGuidList = nil
				    end 
               end	
            end
    		if @baseIO.baseDO.getPartyNames.size > 0
				@baseIO.baseDO.getPartyNames("","PRIMARY,PROPOSER").each do |partyGuid, partyDesc|
					party = @baseIO.baseDO.getPartyByGuid(partyGuid)
					# policyAddtn = @baseIO.baseDO.getPolicyAddionalField("000") 
					# next if party.age.to_i < 18 && policyAddtn && policyAddtn.field11.to_s == "N"
					partyDescList = partyDesc.split("-")
					partyRole = partyDescList.first
					partyRoleList = partyRole.split("/").uniq
					partyNamesHM[partyGuid] = partyRoleList.join("/")+":"+partyDescList[1].to_s
				end
			end
    		MobiSys::CommonUtil.addLookupData(@baseIO, "PARTYNAMES", partyNamesHM)

    		####################################################################################
    		if @baseIO != nil && @baseIO.baseDO != nil && @baseIO.additionalData["ADDTNL_LOOKUPDATA"] != nil
  				addtnl_lookup_data_hm = @baseIO.additionalData["ADDTNL_LOOKUPDATA"]
  				addtn_lookup_data_hm_list = []
  				party_list = []

				if addtnl_lookup_data_hm["PARTYNAMES"] != nil
				    addtn_lookup_data_hm_list = addtnl_lookup_data_hm["PARTYNAMES"]
				    addtn_lookup_data_hm_list.each do |map|
				      if map.key?("cd") && map["cd"] != nil
				        party_list << map["cd"]
				      end
				    end
				    # unless party_list.empty?
				    #   @baseIO.baseDO.allocationPartyGuidList = party_list.join(",")
				    # end
				end
			end
			
			# @baseIO.baseDO.allocationPartyGuidList = ["Owner/Insured/PAYER:OWNER OWNER"]
    		####################################################################################
    		# @baseIO.baseDO.allocatedPartyGuidList = partyNamesHM.to_s
    		quotation = Quotation.loadObject(:first,:conditions =>{:guid => @baseIO.baseDO.quotationRefGuid})
    		fnaRequest = FNARequest.find(:first, :loadChild => false, :conditions=>{:fnaNum=>  @baseIO.baseDO.fnaId.to_s})
    		@baseIO.baseDO.quotationSeq = quotation.object.gsub("_",".").to_f if quotation
    		@baseIO.baseDO.fnaSeq = fnaRequest.object if fnaRequest
    		@baseIO.baseDO.quotationDt = quotation.quotationDt if quotation

			return @baseIO.baseDO
		end
	end
end

begin 
    require 'Policy/PolicyModel_company'
rescue LoadError => e
    puts 'PolicyModel_company not included'
end
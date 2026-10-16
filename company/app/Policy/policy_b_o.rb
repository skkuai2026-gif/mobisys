#encoding: UTF-8
require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/commonutil'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/metadata'
require 'Product/product_b_o'
require 'Party/party_b_o'
require 'CommonModules/questionnaire'
require 'Product/product_util'

module MobiSys
    class PolicyBO
        include Singleton
        include MobiSys::CommonUtil
        extend MobiSys::BrowserHelper
        include MobiSys::BrowserHelper

        
        PENDING = "PENDING"
        READYFORSYNC = "READYFORSYNC"
        SUBMITTED = "SUBMITTED"
        SYNCDONE = "SYNCDONE"


        ################################################################################
        #-----------------Code based on Validation Metadata Sheet Start----------------#
        ################################################################################
  
		#Validates that the agent joining date is before the Proposal signing date
		def self.checkAgentEffective(policy, errors)
			isValid = true

			policyAgent = policy.getPolicyAgentList[0]
			if policyAgent
				agentRegDetails = AgentReg.find(:first,:conditions=>{'agentId'=>policyAgent.agentId})
				if agentRegDetails != nil && agentRegDetails.joiningDate.to_s != "" && policy.proposalSignedDt.to_s != ""
					joiningDate = Time.parse(agentRegDetails.joiningDate.to_s)
					proposalSignedDt = Time.parse(policy.proposalSignedDt.to_s)
					if joiningDate > proposalSignedDt
                        unless $rhoconfig[:TABFEATUREREQD]
							MobiSys::CommonUtil.addErrors(errors, "agentId", "ERR_AGENTEFFECTIVE", [MobiSys::BrowserHelper.getLabel('agentID')])
						else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalSignedDt", "ERR_AGENTEFFECTIVE", "ERR_AGENTEFFECTIVE", nil,  [MobiSys::BrowserHelper.getLabel('agentID')])
						end
						isValid = false
					end
				end
			end

			return isValid 
		end
		##################################################################################################


      	#Validates that the agent yearFrom is before agent yearTo
      	def self.checkAgentSharingYear(policy, errors)
	      	isValid = true

	      	policy.PolicyAgentList.each do |policyAgent|
	      		if policyAgent.yearFrom.to_s != "" && policyAgent.yearTo.to_s != ""
	      			yearFrom = Time.parse(policyAgent.yearFrom.to_s)
	      			yearTo = Time.parse(policyAgent.yearTo.to_s)
	      			if yearFrom > yearTo
                        unless $rhoconfig[:TABFEATUREREQD]
		      				MobiSys::CommonUtil.addErrors(errors, "agentId", "ERR_POLICYEFFECTIVEFROMINVALID", [yearFrom.strftime("%d/%m/%Y"), yearTo.strftime("%d/%m/%Y"), policyAgent.agentId])
		      			else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policyAgent.guid}-agentId", "ERR_POLICYEFFECTIVEFROMINVALID", "ERR_POLICYEFFECTIVEFROMINVALID", nil, [yearFrom.strftime("%d/%m/%Y"), yearTo.strftime("%d/%m/%Y"), policyAgent.agentId])
						end
	      				isValid = false
	      			end
	      		end 
	      	end

	      	return isValid 
      	end
      	##################################################################################################


      	#Validates that all the agents' commPercent & prodnPercent each total to 100
      	def self.checkAgentSharingPercent(policy, errors)
      		isValid = true

      		commPercentTotal = 0
      		prodnPercentTotal = 0
      		policy.PolicyAgentList.each do |policyAgent|
      			commPercentTotal = commPercentTotal + policyAgent.commPercent.to_i
      			prodnPercentTotal = prodnPercentTotal + policyAgent.prodnPercent.to_i
      		end

      		if commPercentTotal != 100
				unless $rhoconfig[:TABFEATUREREQD]
	      			MobiSys::CommonUtil.addErrors(errors, "agentId", "ERR_INVALIDSUMOFPERCENTAGE", [MobiSys::BrowserHelper.getLabel('commPercent'), commPercentTotal.to_s+"%"])
	      		else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-agentId", "ERR_INVALIDSUMOFPERCENTAGE", "ERR_INVALIDSUMOFPERCENTAGE", nil, [MobiSys::BrowserHelper.getLabel('commPercent'), commPercentTotal.to_s+"%"])
				end
      			isValid = false
      		end
      		if prodnPercentTotal != 100
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "agentId", "ERR_INVALIDSUMOFPERCENTAGE", [MobiSys::BrowserHelper.getLabel('prodnPercent'), prodnPercentTotal.to_s+"%"])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-agentId", "ERR_INVALIDSUMOFPERCENTAGE", "ERR_INVALIDSUMOFPERCENTAGE", nil, [MobiSys::BrowserHelper.getLabel('prodnPercent'), prodnPercentTotal.to_s+"%"])
				end
      			isValid = false
      		end

      		return isValid
      	end
      	##################################################################################################


      	#Validates that the agent on the Policy does not have a TERMINATED status
      	def self.checkAgentStatus(policy, errors)
      		isValid = true

      		policy.getPolicyAgentList.each do |policyAgent|
      			agentRegDetails = AgentReg.find(:first,:conditions=>{'agentId'=>policyAgent.agentId})
      			if agentRegDetails != nil && agentRegDetails.agentStatusCd == "TERMINATED"
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "agentId", "ERR_AGENTINVALID", [MobiSys::BrowserHelper.getLabel('agentID')])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{policyAgent.guid}-agentId", "ERR_AGENTINVALID", "ERR_AGENTINVALID", nil, [MobiSys::BrowserHelper.getLabel('agentID')])
					end
      				isValid = false
      			end
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates that if the Payment frequency for base plan is selected to Monthly, then the Renewal payment mode cannot be CASH
      	def self.checkBasePlanFrequency(policy, errors)
      		isValid = true

      		baseProduct = policy.getBaseProduct
      		renewalPayment = policy.getPolicyPayment("RENEWAL")
      		if baseProduct && baseProduct.paymentFrequencyCd != "" && baseProduct.paymentFrequencyCd == "MONTHLY"
      			if renewalPayment && renewalPayment.paymentMethodCd != "" && renewalPayment.paymentMethodCd == "CASH"
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "paymentMethodCd", "ERR_BASEPLANFREQ", [MobiSys::BrowserHelper.getLabel('INITIAL_PAYMENT_DETAILS')])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{renewalPayment.guid}-paymentMethodCd", "ERR_BASEPLANFREQ", "ERR_BASEPLANFREQ", nil, [MobiSys::BrowserHelper.getLabel('INITIAL_PAYMENT_DETAILS')])
					end
      				isValid = false
      			end
      		end

      		return isValid  
      	end
      	##################################################################################################


      	#Validates that the there are no duplicate policies with the same Policy no., Proposal No. as the current Policy 
      	def self.checkDuplicatePolicyExists(policy, errors)
      		isValid = true

      		dupPolicyList = Policy.loadObject(
      			:all,
      			:conditions => {
      				{:name => 'proposalNum'} => policy.proposalNum.to_s
  				},
  				:loadChild => 'false'
			)

      		if dupPolicyList.length > 1
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "proposalNum", "ERR_DUPLPOLICY", [policy.policyNum, policy.proposalNum])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalNum", "ERR_DUPLPOLICY", "ERR_DUPLPOLICY", nil, [policy.policyNum, policy.proposalNum])
				end
      			isValid = false
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates that at least one Fund allocation exists
      	def self.checkFundAllocation(policy, errors)
      		isValid = true

      		baseProduct = policy.getBaseProduct
      		if baseProduct.PolicyProductInvestmentFundList.length == 0
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "policy", "ERR_MANDATORY_FUNDS", [MobiSys::BrowserHelper.getLabel("INVESTMENTFUND")])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{baseProduct.guid}-policy", "ERR_MANDATORY_FUNDS", "ERR_MANDATORY_FUNDS", nil, [MobiSys::BrowserHelper.getLabel("INVESTMENTFUND")])
				end
      			isValid = false
      		end

      		return isValid 
      	end
      	##################################################################################################

        def self.checkFund(policy,errors)
            isValid = true
            tempErrorHash = Hash.new
            facetData = {}
            facetData = $globalFacetHash[:basic] if $globalFacetHash
            baseProduct = policy.getBaseProduct
            product = MobiSys::ProductUtil.getProduct(baseProduct.productSeq)
            if facetData != nil && facetData.empty?
                if product
                    facetData[:renderFundPanel] = MobiSys::BrowserHelper.renderPanel?('FUNDSREQUIRED', product)
                end
                facetData[:renderPortfoliomodelcd] = MobiSys::BrowserHelper.renderField?('com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductDO.portfolioModelCd')
            end
            if facetData[:renderFundPanel]
                facetData = $globalFacetHash[:fund] if $globalFacetHash
                if facetData[:renderPortfoliomodelcd]
                    if baseProduct.portfolioModelCd.to_s == ""
                        MobiSys::CommonUtil.addErrors(tempErrorHash, "portfolioModelCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('fundCd') << " " <<  MobiSys::BrowserHelper.getLabel('portfolioModelCd')]) 
                        MobiSys::CommonUtil.registerException(policy.guid, "#{baseProduct.guid}-portfolioModelCd", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('fundCd') << " " <<  MobiSys::BrowserHelper.getLabel('portfolioModelCd')])
                        isValid = false   
                    end
                end
            end
            if !tempErrorHash.empty?
                errors[:PolicyProductDO] = Hash.new if !errors[:PolicyProductDO].is_a?(Hash)
                errors[:PolicyProductDO][baseProduct.guid.to_sym] = Hash.new if !errors[:PolicyProductDO][baseProduct.guid.to_sym].is_a?(Hash)
                errors[:PolicyProductDO][baseProduct.guid.to_sym] = errors[:PolicyProductDO][baseProduct.guid.to_sym].merge(tempErrorHash)
            end 
            return isValid
        end

      	#Validates whether party of given roleCd exists for policy
  	  	def self.checkRoleExists(policy, errors, roleCd)
  	  		isValid = true
  	  		roleCdLkp = Lookupvalue.find(
  	                :first,
  	                :conditions => {
  	                    {:name => 'key'} => "ROLETYPE",
  	                    {:name => 'cd'} => roleCd.to_s
  	                },
  	                :op => 'AND',
  	                :select => ['desc']
  	            )
  	  		roleCdDesc = roleCdLkp.desc if roleCdLkp
  	  		if !policy.getParty(roleCd)
  				MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-firstName1", "ERR_MANDATORY", "ERR_MANDATORY", nil, [roleCdDesc.to_s])
  	  			isValid = false
  	  		end
  	  		return isValid
  	  	end
      	##################################################################################################


      	#Validates that Proposer exists on the Policy
      	def self.checkProposerExists(policy, errors)
      		return checkRoleExists(policy, errors, "PROPOSER")
      	end
      	##################################################################################################


      	#Validates that Primary insured exists on the Policy
      	def self.checkInsuredExists(policy, errors)
      		return checkRoleExists(policy, errors, "PRIMARY")
      	end
      	##################################################################################################


      	#Validates that Joint life insured exists on the Policy
      	def self.checkJointLifeExists(policy, errors)
      		return checkRoleExists(policy, errors, "JOINT")
      	end
      	##################################################################################################

      	#Validates that Nominee exists on the Policy
      	def self.checkNominee(policy, errors)
      		@product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
      		nomineeFacet = true 
      		@product.OfflineFacetList.each do |offlineFacet|
      			if offlineFacet.facetId == 'EXCLUDENOMINEECAPTURE' && offlineFacet.actionValue == 'YES'
      				nomineeFacet = false
      				break
      			end    
      		end
      		if nomineeFacet
      			return checkRoleExists(policy, errors, "NOMINEE")
      		end 
      		return true
      	end
      	##################################################################################################


      	#Checks if nominee major age facet is defined at company level then appointee should exist
      	def self.checkAppointeeExists(policy, errors)
      		isValid = true
          nomineeAge = ""
          nomineeName = ""
      		facetObj = $rhoconfig[:majorAge]
      		if facetObj
      			majorAge = facetObj.actionValue
      			nomineeList = policy.getPartyList("NOMINEE")
      			appointeeReqd = false
      			if majorAge.to_s != ""
      				nomineeList.each do |nominee|
      					if nominee.age.to_i < majorAge.to_i
                  nomineeAge = nominee.age
                  nomineeName = nominee.firstName1
      						appointeeReqd = true
      						break
      					end
      				end
      				if appointeeReqd && !policy.getParty("APPOINTEE")
						unless $rhoconfig[:TABFEATUREREQD]
      						MobiSys::CommonUtil.addErrors(errors, "age", "ERR_APPOINTEEREQD", [MobiSys::BrowserHelper.getLabel('NOMINEE')])
      					else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-age", "ERR_APPOINTEEREQD", "ERR_APPOINTEEREQD", nil, [nomineeAge,nomineeName,majorAge])
						end
      					isValid = false
      				end
      			end
      		end

      		return isValid  
      	end
      	##################################################################################################


      	#Validates if at least one contact detail exists for Proposer
      	def self.checkProposerPartyContact(policy, errors)
      		isValid = true

      		insured = policy.getParty("PROPOSER")
      		if insured && insured.PartyContactList.size == 0
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "proposerPartyContact", "ERR_CONTACTTYPE", [MobiSys::BrowserHelper.getLabel("PROPOSER")])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{insured.guid}-proposerPartyContact", "ERR_CONTACTTYPE", "ERR_CONTACTTYPE", nil, [MobiSys::BrowserHelper.getLabel("PROPOSER")])
				end
      			isValid = false
      		end

      		return isValid 
      	end
      	##################################################################################################

        def self.checkProposerPartyAddress(policy, errors)
          isValid = true;
          proposer = policy.getParty("PROPOSER")
          if proposer
            if (proposer.copyFromAddr1.to_s == "") && (proposer.copyFromAddr2.to_s == "") && (proposer.copyFromAddr3.to_s == "") && proposer.PartyAddressList.select{|addr| addr.removed.to_s != "YES"}.size == 0
              isValid = false
            end
          end
          if !isValid
            unless $rhoconfig[:TABFEATUREREQD]
                  MobiSys::CommonUtil.addErrors(errors, "proposerPartyAddress", "ERR_MANDATORYFOR", ["Atleast 1 " << MobiSys::BrowserHelper.getLabel("address"), MobiSys::BrowserHelper.getLabel("PROPOSER")])
            else
              MobiSys::CommonUtil.registerException(policy.guid, "#{proposer.guid}-proposerPartyAddress", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Atleast 1 " << MobiSys::BrowserHelper.getLabel("address"), MobiSys::BrowserHelper.getLabel("PROPOSER")])
            end
          end
          return isValid;
        end

      	#Validates if at least one address detail exists for Primary Insured
      	def self.checkInsuredPartyAddress(policy, errors)
      		isValid = true

      		insured = policy.getParty("PRIMARY")
      		if insured
      			if (insured.copyFromAddr1.to_s == "") && (insured.copyFromAddr2.to_s == "") && (insured.copyFromAddr3.to_s == "") && insured.PartyAddressList.select{|addr| addr.removed.to_s != "YES"}.size == 0
      				isValid = false
      			else 
      				if insured.copyFromAddr1 == "PROPOSERRESIDENTIAL" && !policy.getParty("PROPOSER").getPartyAddress("RESIDENTIAL")
      					isValid = false
      				elsif insured.copyFromAddr2 == "RESIDENTIAL" && (!insured.getPartyAddress("RESIDENTIAL") && insured.copyFromAddr1 != "PROPOSERRESIDENTIAL")
      					isValid = false             
      				elsif insured.copyFromAddr3 == "RESIDENTIAL" && (!insured.getPartyAddress("RESIDENTIAL") && insured.copyFromAddr1 != "PROPOSERRESIDENTIAL")
      					isValid = false
      				elsif insured.copyFromAddr3 == "OFFICE" && (!insured.getPartyAddress("OFFICE") && insured.copyFromAddr2 != "RESIDENTIAL")
      					isValid = false
      				end
      			end
      			if !isValid
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "insuredPartyAddress", "ERR_MANDATORYFOR", ["Atleast 1 " << MobiSys::BrowserHelper.getLabel("address"), MobiSys::BrowserHelper.getLabel("PRIMARY")])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{insured.guid}-insuredPartyAddress", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, ["Atleast 1 " << MobiSys::BrowserHelper.getLabel("address"), MobiSys::BrowserHelper.getLabel("PRIMARY")])
					end
      			end
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates if at least one contact detail exists for Primary Insured
      	def self.checkInsuredPartyContact(policy, errors)
      		isValid = true

      		insured = policy.getParty("PRIMARY")
      		if insured && insured.PartyContactList.size == 0
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "insuredPartyContact", "ERR_CONTACTTYPE", [MobiSys::BrowserHelper.getLabel("PRIMARY")])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{insured.guid}-insuredPartyContact", "ERR_CONTACTTYPE", "ERR_CONTACTTYPE", nil, [MobiSys::BrowserHelper.getLabel("PRIMARY")])
				end
      			isValid = false
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates that the total Nominee sharing percentage is 100 for the Policy
      	def self.checkNomineePercentage(policy, errors)
      		isValid = true
      		nomineeList = policy.getPolicyPartyRoleList("NOMINEE")
      		percentage = 0
      		suppPercent = 0
      		countPrimary = 0
      		countSecondary = 0

      		nomineeList.each do |nominee|
      			if nominee.nomineeTypeCd == nil ||  nominee.nomineeTypeCd.to_s == ""
      				nominee.nomineeTypeCd = "PRIMARY"
      			end  
      			if nominee.percentage != nil
      				if nominee.nomineeTypeCd == "PRIMARY" 
      					percentage = percentage + nominee.percentage.to_i
      					countPrimary = countPrimary + 1
      				elsif nominee.nomineeTypeCd == "SECONDARY"
      					suppPercent = suppPercent+ nominee.percentage.to_i               
      					countSecondary = countSecondary + 1
      				end
      			end
      		end 
      		if percentage != 100 && nomineeList.size > 0 && countPrimary > 0
      			isValid = false
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, 'nomineePercentage', "ERR_PERCENTAGE", [MobiSys::BrowserHelper.getLabel("PrimaryNominee"), percentage.to_s])  
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-nomineePercentage", "ERR_PERCENTAGE", "ERR_PERCENTAGE", nil, [MobiSys::BrowserHelper.getLabel("PrimaryNominee"), percentage.to_s])
				end
      		end
      		if suppPercent != 100 && nomineeList.size() > 0 && countSecondary > 0
      			isValid = false;
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, 'nomineePercentage', "ERR_PERCENTAGE", [MobiSys::BrowserHelper.getLabel("SecNominee"), suppPercent.to_s])  
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-nomineePercentage", "ERR_PERCENTAGE", "ERR_PERCENTAGE", nil, [MobiSys::BrowserHelper.getLabel("SecNominee"), suppPercent.to_s])        
				end
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates the age of the appointee with that defined against APPOINTEEAGE facet at company level
      	def self.checkAppointeeAge(policy, errors)
      		isValid = true

      		facetObj = $rhoconfig[:appointeeAge]
      		if facetObj
      			allowedAppointeeAge = facetObj.actionValue
      			appointee = policy.getParty("APPOINTEE")
      			if appointee.age.to_i < allowedAppointeeAge.to_i
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "age", "ERR_APPOINTEEAGE", [MobiSys::BrowserHelper.getLabel('APPOINTEE')])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{appointee.guid}-age", "ERR_APPOINTEEAGE", "ERR_APPOINTEEAGE", nil, [MobiSys::BrowserHelper.getLabel('APPOINTEE')])
					end
      				isValid = false
      			end
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates that if the Primary Insured is Single then relationship with other Parties cannot be Husband/Wife/Spouse
      	def self.checkPartyRelationshipWithInsured(policy, errors)
      		isValid = true

      		insured = policy.getParty("PRIMARY")
      		if insured && insured.maritalStatusCd == "SINGLE"
      			policy.PartyList.each do |party|
      				if party.guid != insured.guid && party.roleCd != "APPOINTEE"
      					if party.relationCd == "HUSBAND" || party.relationCd == "WIFE" || party.relationCd == "SPOUSE"
							unless $rhoconfig[:TABFEATUREREQD]
      							MobiSys::CommonUtil.addErrors(errors, "relationCd", "ERR_MARITALSTATUS", [MobiSys::BrowserHelper.getLabel(party.roleCd)])
      						else
								MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-relationCd", "ERR_MARITALSTATUS", "ERR_MARITALSTATUS", nil, [MobiSys::BrowserHelper.getLabel(party.roleCd)])
							end
      						isValid = false
      						break
      					end
      				end
      			end
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates that the Inward status is marked as Cleared
      	def self.checkPaymentStatus(policy, errors)
      		isValid = true

      		inward, inwardPolicyList, inwardDetailsList = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
      		if inward && inward.inwardStatusCd != "CLEARED"
				unless $rhoconfig[:TABFEATUREREQD]
      				MobiSys::CommonUtil.addErrors(errors, "inwardStatus", "ERR_PAYMENTCLEARED", [MobiSys::BrowserHelper.getLabel("INWARD")])
      			else
					MobiSys::CommonUtil.registerException(policy.guid, "#{inward.guid}-inwardStatusCd", "ERR_PAYMENTCLEARED", "ERR_PAYMENTCLEARED", nil, [MobiSys::BrowserHelper.getLabel("INWARD")])
				end
      			isValid = false
      		end

      		return isValid 
      	end
      	##################################################################################################


      	#Validates the Proposal entry date wrt other dates
      	def self.checkProposalEntryDate(policy, errors)
      		isValid = true

      		if policy.proposalEntryDt.to_s != ""
      			proposalEntryDt = Time.parse(policy.proposalEntryDt)
      			if policy.proposalSignedDt.to_s != ""
      				proposalSignedDt = Time.parse(policy.proposalSignedDt)
      				if proposalEntryDt < proposalSignedDt
						unless $rhoconfig[:TABFEATUREREQD]
      						MobiSys::CommonUtil.addErrors(errors, "proposalEntryDt", "ERR_DATE2BEFORE", [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), proposalSignedDt.strftime("%d/%m/%Y"), "", ""])
      					else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalEntryDt", "ERR_DATE2BEFORE", "ERR_DATE2BEFORE", nil, [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), proposalSignedDt.strftime("%d/%m/%Y"), "", ""])
						end
      					isValid = false
      				end
      			end

      			if policy.proposalReceivedDt.to_s != ""
      				proposalReceivedDt = Time.parse(policy.proposalReceivedDt)
      				if proposalEntryDt < proposalReceivedDt
						unless $rhoconfig[:TABFEATUREREQD]
      						MobiSys::CommonUtil.addErrors(errors, "proposalEntryDt", "ERR_DATE2BEFORE", [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), proposalReceivedDt.strftime("%d/%m/%Y"), "", ""])
      					else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalEntryDt", "ERR_DATE2BEFORE", "ERR_DATE2BEFORE", nil, [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), proposalReceivedDt.strftime("%d/%m/%Y"), "", ""])
						end
      					isValid = false
      				end
      			end

      			currentDt = Time.new
      			if proposalEntryDt > currentDt
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "proposalEntryDt", "ERR_DATE2AFTER", [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalEntryDt", "ERR_DATE2AFTER", "ERR_DATE2AFTER", nil, [MobiSys::BrowserHelper.getLabel("proposalEntryDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
					end
      				isValid = false
      			end
      		end

      		return isValid
      	end 
    	##################################################################################################


      	#Validates the Proposal received date wrt other dates
      	def self.checkProposalRcvdDate(policy, errors)
      		isValid = true

      		if policy.proposalReceivedDt.to_s != ""
      			proposalReceivedDt = Time.parse(policy.proposalReceivedDt)
      			if policy.proposalSignedDt.to_s != ""
      				proposalSignedDt = Time.parse(policy.proposalSignedDt)
      				if proposalReceivedDt < proposalSignedDt
						unless $rhoconfig[:TABFEATUREREQD]
      						MobiSys::CommonUtil.addErrors(errors, "proposalReceivedDt", "ERR_DATE2BEFORE", [MobiSys::BrowserHelper.getLabel("proposalReceivedDt"), proposalSignedDt.strftime("%d/%m/%Y"), "", ""])
      					else
							MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalReceivedDt", "ERR_DATE2BEFORE", "ERR_DATE2BEFORE", nil, [MobiSys::BrowserHelper.getLabel("proposalReceivedDt"), proposalSignedDt.strftime("%d/%m/%Y"), "", ""])
						end
      					isValid = false
      				end
      			end

      			currentDt = Time.new
      			if proposalReceivedDt > currentDt
					unless $rhoconfig[:TABFEATUREREQD]
      					MobiSys::CommonUtil.addErrors(errors, "proposalReceivedDt", "ERR_DATE2AFTER", [MobiSys::BrowserHelper.getLabel("proposalReceivedDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
      				else
						MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalReceivedDt", "ERR_DATE2AFTER", "ERR_DATE2AFTER", nil, [MobiSys::BrowserHelper.getLabel("proposalReceivedDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
					end
      				isValid = false
      			end
      		end

      		return isValid
      	end 
    	##################################################################################################


      	#Validates that Proposal signed date wrt other dates
      	def self.checkProposalSignedDate(policy, errors)
      		isValid = true
          #method to validate proposal signed date if signature is capturing in tab
          if $rhoconfig[:captureSignatureInTab] && policy.proposalSignedDt.to_s == ""
            unless $rhoconfig[:TABFEATUREREQD]
               MobiSys::CommonUtil.addErrors(errors, "proposalSignedDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("proposalSignedDt")])
             else
              MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalSignedDt", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel("proposalSignedDt")])
            end
              isValid = false
          end
      		if policy.proposalSignedDt.to_s != ""
      			proposalSignedDt = Time.parse(policy.proposalSignedDt)
      			currentDt = Time.new
      			if proposalSignedDt > currentDt
             unless $rhoconfig[:TABFEATUREREQD]
               MobiSys::CommonUtil.addErrors(errors, "proposalSignedDt", "ERR_DATE2AFTER", [MobiSys::BrowserHelper.getLabel("proposalSignedDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
             else
              MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-proposalSignedDt", "ERR_DATE2AFTER", "ERR_DATE2AFTER", nil, [MobiSys::BrowserHelper.getLabel("proposalSignedDt"), currentDt.strftime("%d/%m/%Y"), "", ""])
              end
              isValid = false
            end
          end

        return isValid
      	end 
    	##################################################################################################


      	#Validates the topup policy year from, to wrt base plan term
      	def self.checkTopup(policy, errors)
      		isValid = true

      		baseProduct = policy.getBaseProduct
      		policy.PolicyTopUpList.each do |topUp|
      			if topUp.policyYearFrom && topUp.policyYearTo && topUp.policyYearFrom != "" && topUp.policyYearTo != ""
      				policyYearFrom = Time.parse(topUp.policyYearFrom)
      				policyYearTo = Time.parse(topUp.policyYearTo)

      				if policyYearTo < policyYearFrom
						unless $rhoconfig[:TABFEATUREREQD]
      						MobiSys::CommonUtil.addErrors(errors, "policyYearTo", "ERR_POLICYYEARTOINVALID", [MobiSys::BrowserHelper.getLabel("POLICY")])
      					else
							MobiSys::CommonUtil.registerException(policy.guid, "#{topUp.guid}-policyYearTo", "ERR_POLICYYEARTOINVALID", "ERR_POLICYYEARTOINVALID", nil, [MobiSys::BrowserHelper.getLabel("POLICY")])
						end
      					isValid = false
      				end

      				if baseProduct.productTerm && baseProduct.productTerm != ""
      					productTerm = Time.parse(baseProduct.productTerm)

      					if policyYearTo > productTerm
							unless $rhoconfig[:TABFEATUREREQD]
      							MobiSys::CommonUtil.addErrors(errors, "policyYearTo", "ERR_TOPUPTOYEAR", [MobiSys::BrowserHelper.getLabel("POLICY")])
      						else
								MobiSys::CommonUtil.registerException(policy.guid, "#{topUp.guid}-policyYearTo", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil, [MobiSys::BrowserHelper.getLabel("POLICY")])
							end
      						isValid = false
      					end

      					if policyYearFrom > productTerm
							unless $rhoconfig[:TABFEATUREREQD]
      							MobiSys::CommonUtil.addErrors(errors, "policyYearFrom", "ERR_TOPUPTOYEAR", [MobiSys::BrowserHelper.getLabel("POLICY")])
      						else
								MobiSys::CommonUtil.registerException(policy.guid, "#{topUp.guid}-policyYearFrom", "ERR_TOPUPTOYEAR", "ERR_TOPUPTOYEAR", nil, [MobiSys::BrowserHelper.getLabel("POLICY")])
							end
      						isValid = false
      					end
      				end
      			end
      		end

      		return isValid 
      	end

        ##################################################################################################

        #Validates that if plan options have been defined for the Rider in master definition then a Plan option needs to be selected for the rider in the Policy
        def self.checkRiderPlanOption(policy,errors)
            isValid = true
            
            policy.PolicyProductList.each do |rider|
                if rider.productTypeCd == "RIDER"
                    riderProduct = rider.product
                    if riderProduct == nil
                        riderProduct = MobiSys::ProductUtil.getProduct(rider.productSeq) 
                        rider.product = riderProduct
                    end
                    if riderProduct != nil
                        planOptionFacet = rider.product.getFacet('PLANOPTION')
                        if planOptionFacet && rider.productPlanOptionCd.to_s == ""
							unless $rhoconfig[:TABFEATUREREQD]
                            	MobiSys::CommonUtil.addErrors(errors, "planOption", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('RIDER') << " " <<  rider.product.longName << " " << MobiSys::BrowserHelper.getLabel('for') << " " << rider.PolicyProductInsuredList[0].roleCd]) 
                            else
								MobiSys::CommonUtil.registerException(policy.guid, "#{rider.guid}-planOption", "ERR_MANDATORYFOR", "ERR_MANDATORYFOR", nil, [MobiSys::BrowserHelper.getLabel('planOptionCd'), MobiSys::BrowserHelper.getLabel('RIDER') << " " <<  rider.product.longName << " " << MobiSys::BrowserHelper.getLabel('for') << " " << rider.PolicyProductInsuredList[0].roleCd])
							end
                            isValid = false 
                        end
                    end
                end
            end

            return isValid 
        end
      	##################################################################################################

        #Method to check any duplicate same as party occur in nominee detail.
        def self.validateSameAsInNominee(policy,errors)
            isValid = true
            partySameAsMap = {}
            nomineeList = policy.getPolicyPartyRoleList("NOMINEE")
            nomineeList.each do |nominee|
                if nominee.partySameAsCd != "OTHER"
                    if partySameAsMap.has_key? nominee.partySameAsCd
                        partySameAsRefGuid = partySameAsMap[nominee.partySameAsCd]
                        if (partySameAsRefGuid.to_s != "" ) && (partySameAsRefGuid.split(",").include? nominee.refGuid)
                            party = Party.find(:first, :conditions=>{{:name=>'guid'}=>nominee.refGuid})
                            dupPartySameAs = party.getEntityDesc
							unless $rhoconfig[:TABFEATUREREQD]
                            	MobiSys::CommonUtil.addErrors(errors, "partySameAsCd", "ERR_CHKDUPLICATESAMEAS", [MobiSys::BrowserHelper.getLabel(dupPartySameAs.to_s)])
                            else
								MobiSys::CommonUtil.registerException(policy.guid, "#{nominee.guid}-partySameAsCd", "ERR_CHKDUPLICATESAMEAS", "ERR_CHKDUPLICATESAMEAS", nil, [MobiSys::BrowserHelper.getLabel(dupPartySameAs.to_s)])
							end
                            isValid = false
                            break
                        else
                            partySameAsMap[nominee.partySameAsCd]= partySameAsRefGuid + "," + nominee.refGuid if nominee.refGuid.to_s
                        end
                    else
                        partySameAsMap[nominee.partySameAsCd]= nominee.refGuid
                    end
                end
            end

            return isValid
        end

        #Method to check Inward 
        def self.checkInward(policy,errors)
            isValid = true
            inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
            if !inward
                unless $rhoconfig[:TABFEATUREREQD]
                    MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("initialPayment")])
                else
                    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel("initialPayment")])
                end
                isValid = false
            end
            return isValid

        end

        #Method to check renewal payment
        def self.checkRenewalPayment(policy,errors)
            isValid = true
            renewalPayment = policy.getPolicyPayment("RENEWALPREMIUM")
            if !renewalPayment
                unless $rhoconfig[:TABFEATUREREQD]
                    MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("renewalPayment")])
                else
                    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel("renewalPayment")])
                end
                isValid = false
            end
            return isValid
        end

        #method to check refund payment
        def self.checkRefundPayment(policy,errors)
            isValid = true
            refundPayment = policy.getPolicyPayment("REFUND")
            if !refundPayment
                unless $rhoconfig[:TABFEATUREREQD]
                    MobiSys::CommonUtil.addErrors(errors, "guid", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("refundPayment")])
                else
                    MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel("refundPayment")])
                end
                isValid = false
            end
            return isValid
        end

        ################################################################################
        #-----------------Code based on Validation Metadata Sheet End------------------#
        ################################################################################






        ################################################################################
        #----------------------Code used for Old Validation Start----------------------#
        ################################################################################

      	#Method to check for empty fields in child objects and return removed flag accordingly
      	def self.checkForEmptyFields(object)
            removed = true
            excludedAttributes = ["object", "source_id", "guid", "addressTypeCd", "contactTypeCd","userId","systemUpdatedDt", "emailTypeCd", "parentKey", "systemCreatedDt"]

            object.instance_variable_get(:@vars).each do |key, value|
                if !excludedAttributes.include?(key.to_s)
                    removed = false if value != "" && value != nil
                end
            end

            return removed
        end
      	##################################################################################################


    	#Method to validate Payment Details Tab
    	def self.validatePaymentDetails(policy, errors, facetData)
    		policyPartyRoleList = PolicyPartyRole.loadObject(
    			:all,
    			:conditions => {
    				{:name => 'parentKey'} => policy.object,
    				{:name => 'roleCd'} => "PAYER",
    				:op => 'AND'
    			}
    			)

    		policyPartyRoleList.each do |payerPartyRole|
    			payer = Party.loadObject(:first, :conditions=>{{:name=>'guid'}=>payerPartyRole.refGuid})

    			if payer != nil && payerPartyRole.partySameAsCd.to_s == ""
    				if payerPartyRole.paymentInstructionTypeCd == "INITIAL"
    					MobiSys::PartyBO.validatePartyDetails(payer, facetData, errors)
    				else
    					MobiSys::PartyBO.validatePartyDetails(payer, facetData, errors)
    				end
    			end
    		end

    		policyObject = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => policy.object})
    		inward = policy.getInward(policyObject.proposalNum, "APPLICATION_SUSPENSE")

    		inward.InwardDetailsList.each do |inwardDetails|
    			tempErrorHash = Hash.new
    			if inwardDetails.paymentMethodCd.to_s == ""
    				MobiSys::CommonUtil.addErrors(tempErrorHash, "paymentMethodCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('paymentMethodCd')])      
    			end

    			if ["CHEQUE", "IPG"].include?(inwardDetails.paymentMethodCd.to_s) && inwardDetails.paymentSubTypeCd.to_s == ""
    				MobiSys::CommonUtil.addErrors(tempErrorHash, "paymentSubTypeCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('paymentSubTypeCd')])      
    			end
    			validateInstrumentDetails(inwardDetails, tempErrorHash, "initial", inwardDetails.paymentMethodCd) if inwardDetails.paymentMethodCd.to_s != ""

    			if !tempErrorHash.empty?
    				errors[:InwardDetailsDO] = Hash.new if !errors[:InwardDetailsDO].is_a?(Hash)
    				errors[:InwardDetailsDO][inwardDetails.guid.to_sym] = Hash.new if !errors[:InwardDetailsDO][inwardDetails.guid.to_sym].is_a?(Hash)
    				errors[:InwardDetailsDO][inwardDetails.guid.to_sym] = errors[:InwardDetailsDO][inwardDetails.guid.to_sym].merge(tempErrorHash)
    			end 
    		end

    		renewalPayment = PolicyPayment.loadObject(
    			:first, 
    			:conditions=>{
    				{:name=>'parentKey'}=>policy.object,
    				{:name=>'paymentInstructionTypeCd'}=>"RENEWALPREMIUM",
    				:op => 'AND'
    			}
    			)
    		if renewalPayment
    			tempErrorHash = Hash.new
    			if renewalPayment.paymentMethodCd.to_s == ""
    				MobiSys::CommonUtil.addErrors(tempErrorHash, "paymentMethodCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('paymentMethodCd')])      
    			end
    			if !tempErrorHash.empty?
    				errors[:PolicyPaymentDO] = Hash.new if !errors[:PolicyPaymentDO].is_a?(Hash)
    				errors[:PolicyPaymentDO][renewalPayment.guid.to_sym] = Hash.new if !errors[:PolicyPaymentDO][renewalPayment.guid.to_sym].is_a?(Hash)
    				errors[:PolicyPaymentDO][renewalPayment.guid.to_sym] = errors[:PolicyPaymentDO][renewalPayment.guid.to_sym].merge(tempErrorHash)
    			end

    			tempErrorHash = Hash.new
    			renewalFinancialAccount = PartyFinancialAccount.loadObject(:first, :conditions=>{{:name=>'guid'}=>renewalPayment.partyFinAccRefGuid})
    			if renewalFinancialAccount != nil && renewalPayment.paymentMethodCd.to_s != ""
    				validateInstrumentDetails(renewalFinancialAccount, tempErrorHash, "renewal", renewalPayment.paymentMethodCd)
    			end

    			if !tempErrorHash.empty?
    				errors[:PartyFinancialAccountDO] = Hash.new if !errors[:PartyFinancialAccountDO].is_a?(Hash)
    				errors[:PartyFinancialAccountDO][renewalFinancialAccount.guid.to_sym] = Hash.new if !errors[:PartyFinancialAccountDO][renewalFinancialAccount.guid.to_sym].is_a?(Hash)
    				errors[:PartyFinancialAccountDO][renewalFinancialAccount.guid.to_sym] = errors[:PartyFinancialAccountDO][renewalFinancialAccount.guid.to_sym].merge(tempErrorHash)
    			end
    		end

    		refundPayment = PolicyPayment.loadObject(
    			:first, 
    			:conditions=>{
    				{:name=>'parentKey'}=>policy.object,
    				{:name=>'paymentInstructionTypeCd'}=>"REFUND",
    				:op => 'AND'
    			}
    			)
    		if refundPayment
    			tempErrorHash = Hash.new
    			if refundPayment.paymentMethodCd.to_s == ""
    				MobiSys::CommonUtil.addErrors(tempErrorHash, "paymentMethodCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('paymentMethodCd')])      
    			end
    			if !tempErrorHash.empty?
    				errors[:PolicyPaymentDO] = Hash.new if !errors[:PolicyPaymentDO].is_a?(Hash)
    				errors[:PolicyPaymentDO][refundPayment.guid.to_sym] = Hash.new if !errors[:PolicyPaymentDO][refundPayment.guid.to_sym].is_a?(Hash)
    				errors[:PolicyPaymentDO][refundPayment.guid.to_sym] = errors[:PolicyPaymentDO][refundPayment.guid.to_sym].merge(tempErrorHash)
    			end

    			tempErrorHash = Hash.new
    			refundFinancialAccount = PartyFinancialAccount.loadObject(:first, :conditions=>{{:name=>'guid'}=>refundPayment.partyFinAccRefGuid})
    			if refundFinancialAccount != nil && refundPayment.paymentMethodCd.to_s != ""
    				validateInstrumentDetails(refundFinancialAccount, tempErrorHash, "refund", refundPayment.paymentMethodCd)
    			end

    			if !tempErrorHash.empty?
    				errors[:PartyFinancialAccountDO] = Hash.new if !errors[:PartyFinancialAccountDO].is_a?(Hash)
    				errors[:PartyFinancialAccountDO][refundFinancialAccount.guid.to_sym] = Hash.new if !errors[:PartyFinancialAccountDO][refundFinancialAccount.guid.to_sym].is_a?(Hash)
    				errors[:PartyFinancialAccountDO][refundFinancialAccount.guid.to_sym] = errors[:PartyFinancialAccountDO][refundFinancialAccount.guid.to_sym].merge(tempErrorHash)
    			end
    		end
    	end  
    	##################################################################################################
      

      	#Validates Instrument details for a given inward/policypayment
      	def self.validateInstrumentDetails(paymentObject, errors, paymentType, paymentMethodCd)
      		if paymentType == "initial"
      			if paymentMethodCd.to_s == "CHEQUE"
      				if paymentObject.micrNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      				end

      				if paymentObject.micrNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      				end

      				if paymentObject.bankBranch.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "bankBranch", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankBranch')])      
      				end

      				if paymentObject.instrumentDt.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "instrumentDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('instrumentDt')])      
      				end

      				if paymentObject.bankCd.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "bankCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankCd')])
      				end

      				if paymentObject.accountName.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "accountName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountName')])      
      				end
      			end

      			if ["CHEQUE", "ATM", "IPG"].include?(paymentMethodCd.to_s) && paymentObject.inwardNum.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "inwardNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('inwardNum')])      
      			end

      			if paymentObject.inwardAmount.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "inwardAmount", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('initialPayment') << " - " << MobiSys::BrowserHelper.getLabel('inwardAmount')])      
      			end
      		elsif paymentType == "renewal"
      			if paymentMethodCd.to_s == "directDebit"
      				if paymentObject.micrNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      				end

      				if paymentObject.micrNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      				end

      				if paymentObject.bankCd.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "bankCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankCd')])
      				end

      				if paymentObject.accountName.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "accountName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountName')])      
      				end

      				if paymentObject.accountNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "accountNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountNum')])      
      				end

      				if paymentObject.branchName.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "branchName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankBranch')])      
      				end
      			end

      			if paymentMethodCd.to_s == "creditCard"
      				if paymentObject.cardExpiryYear.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "cardExpiryYear", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('cardExpiryYear')])      
      				end

      				if paymentObject.cardExpiryMnth.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "cardExpiryMnth", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('cardExpiryDt')])      
      				end

      				if paymentObject.accountName.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "accountName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountName')])      
      				end

      				if paymentObject.accountNum.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "accountNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountNum')])      
      				end

      				if paymentObject.branchName.to_s == ""
      					MobiSys::CommonUtil.addErrors(errors, "branchName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('renewalPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankBranch')])      
      				end
      			end
      		elsif paymentType == "refund" && paymentMethodCd.to_s == "directCredit"
      			if paymentObject.micrNum.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      			end

      			if paymentObject.micrNum.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "micrNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('micrNum')])      
      			end

      			if paymentObject.bankCd.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "bankCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankCd')])
      			end

      			if paymentObject.accountName.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "accountName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountName')])      
      			end

      			if paymentObject.accountNum.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "accountNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('accountNum')])      
      			end

      			if paymentObject.branchName.to_s == ""
      				MobiSys::CommonUtil.addErrors(errors, "branchName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('refundPayment') << " - " << MobiSys::BrowserHelper.getLabel('bankBranch')])      
      			end
      		end
      	end
      	##################################################################################################

        
        def self.doNonUWDocumentValidation(policy, errors)
            containers = DocumentContainer.loadObject(:all, 
                :conditions=>{
                    'policyGuid' =>policy.guid
                }
            )
            party_guids = policy.getPartyNames("tab_requirement")

            containers.each do |container|
            	life = policy.getPartyByGuid(container.entityGuid)
              validateServiceDocument(container, party_guids[container.entityGuid], policy, life, errors, false)
              container.persistAll
            end
        end
        ##################################################################################################

        def self.doUWDocumentValidation(policy, errors)
            containers = DocumentContainer.loadObject(:all, 
                :conditions=>{
                    'policyGuid' =>policy.guid
                }
            )
            party_guids = policy.getPartyNames("tab_requirement")

            containers.each do |container|
            	life = policy.getPartyByGuid(container.entityGuid)
              validateServiceDocument(container, party_guids[container.entityGuid], policy, life, errors, true)
              container.persistAll
            end
        end
        ##################################################################################################


    	#Method to validate Requirements Tab
        def self.validateServiceDocument(container, lifeName, policy, life, errors, isAutoUwGeneratedFl = false)
            product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            
            lifePartyRoles = []
            lifePartyRole = nil
            
            policy.PolicyPartyRoleList.each do |policyPartyRole|
                if policyPartyRole.refGuid.to_s == life.guid
                    lifePartyRoles.push policyPartyRole
                end
            end
            lifePartyRoles.each do |lpr|
                if lpr.roleCd.to_s == life.roleCd.to_s
                    lifePartyRole = lpr
                end
            end

            policyPayment = policy.getPolicyPayment("RENEWALPREMIUM")
            if policyPayment != nil && (lifePartyRole.roleCd == "PROPOSER" || lifePartyRole.roleCd == "PAYER") && baseProduct != nil
                baseProduct.paymentMethodCd = policyPayment.paymentMethodCd
            end

            if baseProduct
                originalPartyRole = baseProduct.partyRoleCd
                originalInsureRefGuid = baseProduct.insuredPartyRefGuid
                originalCombinedEntryAge = baseProduct.combinedEntryAge
                baseProduct.partyRoleCd = lifePartyRole.roleCd
                if lifePartyRole.roleCd == "SUPPLEMENTARY" || lifePartyRole.roleCd == "NOMINEE"
                    baseProduct.insuredPartyRefGuid = life.object
                    baseProduct.combinedEntryAge = life.age
                end
            end
            categoriesDerivedFromDT = []
              for i in 0..20
                if i == 0
                  i = ""
                end
                nbReqName = "NBREQUIRMENTS" << i.to_s
                ttms = product.getTableTypeMappingSeq(nbReqName)
                offlineFacet = product.getFacet(nbReqName)
                if (ttms.to_s != '' && ((offlineFacet && offlineFacet.applicableRoles.to_s == "" ) || (offlineFacet  && offlineFacet.applicableRoles.to_s.split(",").include?(life.roleCd.to_s))))
                  defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true)
                  defTables = MobiSys::ProductUtil.getProductDefinitionTableDO(ttms, quotation, baseProduct, life, true)
                  defTables.each do |defTable|
                    if defTable.documentCategoryCd.to_s != ''
                      categoriesDerivedFromDT.push(defTable.documentCategoryCd.split(","))
                    end
                  end
                end
              end
            categoriesDerivedFromDT = categoriesDerivedFromDT.flatten.uniq
            container.ServiceDocumentList.each do |serviceDocument|
            	# only uw document need to validate in cae of uw flag...if non uw then only non uw document need to validate
				if((isAutoUwGeneratedFl && !serviceDocument.isAutoGeneratedFl.to_s == "YES_UW") || (!isAutoUwGeneratedFl && serviceDocument.isAutoGeneratedFl.to_s == "YES_UW"))
					next
				end
                if !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s) && serviceDocument.isAutoGeneratedFl != "YES_UW" && serviceDocument.isAutoGeneratedFl != "QUESTION"
                    serviceDocument.removed = 'YES' 
                    Image.delete_all(
                        :conditions => {
                            {:name=>'parentRefGuid'} => serviceDocument.guid
                        },
                        :op => 'AND'
                    )
                end
                categoriesDerivedFromDT.push(serviceDocument.docCategoryCd) if (serviceDocument.isAutoGeneratedFl == "YES_UW" || serviceDocument.isAutoGeneratedFl == "QUESTION") && !categoriesDerivedFromDT.include?(serviceDocument.docCategoryCd.to_s)
            end
            if baseProduct
                baseProduct.partyRoleCd = originalPartyRole
                baseProduct.insuredPartyRefGuid = originalInsureRefGuid
                baseProduct.combinedEntryAge = originalCombinedEntryAge
            end
            documentCategoryM = DocumentCategory.loadObject( 
                :all,
                :conditions => {
                    { :name => 'categoryCd', :op => 'IN' } => categoriesDerivedFromDT
                }
            )
            
            categoryCdDescHM = {}
            documentCdDescHM = {}
            documentCdObjHM = {}
            documentCdList = []
            docCategoryTypeLookup = Lookupvalue.getValue('DOCCATEGORYTYPE')
            docCategoryTypeLookup.each do |lookup|
                categoryCdDescHM[lookup.cd] = lookup.desc
            end
            documentCategoryM.each do |docCategory|
                # Validating minimum number of documents per category
                totalDocsPerCatg = 0
                container.ServiceDocumentList.each_with_index do |serviceDocument, index|
                    if serviceDocument.docCategoryCd.to_s == docCategory.categoryCd  && serviceDocument.removed.to_s != 'YES' && serviceDocument.selected.to_s == 'YES'
                        totalDocsPerCatg = index + 1
                    end
                end
                
                minNoOfDocuments = docCategory.minNoOfDocuments
                conditionFlag = totalDocsPerCatg < minNoOfDocuments.to_i
                
                if conditionFlag
                    unless $rhoconfig[:TABFEATUREREQD]
                        tempErrorHash = Hash.new
                        MobiSys::CommonUtil.addErrors(tempErrorHash, "minNoOfDocuments", "ERR_MINDOCUMENT", [minNoOfDocuments, categoryCdDescHM[docCategory.categoryTypeCd], lifeName])

                        errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                        errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = Hash.new if !errors[:ServiceDocumentDO][container.guid.to_s.to_sym].is_a?(Hash)
                        errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = errors[:ServiceDocumentDO][container.guid.to_s.to_sym].merge(tempErrorHash)
                    else
                        MobiSys::CommonUtil.registerException(container.policyGuid, "#{docCategory.categoryTypeCd}-docCategoryCd", "ERR_MINDOCUMENT", MobiSys::BrowserHelper.getLabel("ERR_MINDOCUMENT"), $currentTabId, [minNoOfDocuments, categoryCdDescHM[docCategory.categoryTypeCd], lifeName])
                    end
                end
                # Validating mandatory documents per category
                docCategory.DocumentCategoryMapList.each do |docCategoryMap|
                    documentCdDescHM[docCategoryMap.documentCd] = docCategoryMap.documentDesc
                    if docCategoryMap.isMandatoryFl.to_s == 'YES'
                        documentNotFound = true
                        container.ServiceDocumentList.each do |serviceDocument|
                            if serviceDocument.docCategoryCd.to_s == docCategoryMap.categoryCd && serviceDocument.documentCd.to_s == docCategoryMap.documentCd.to_s && serviceDocument.selected.to_s == 'YES' && serviceDocument.removed.to_s != 'YES'
                                documentNotFound = false
                                documentCdList.push(serviceDocument.documentCd.to_s)
                                break
                            end
                        end 
                        if documentNotFound
                            unless $rhoconfig[:TABFEATUREREQD]
                                tempErrorHash = Hash.new
                                MobiSys::CommonUtil.addErrors(tempErrorHash, "documentIsMandatory", "ERR_MANDATORYSERVICEDOC", [docCategoryMap.documentDesc, categoryCdDescHM[docCategory.categoryTypeCd] << ' ' << MobiSys::BrowserHelper.getLabel("categoryCd"), lifeName])
                                errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = Hash.new if !errors[:ServiceDocumentDO][container.guid.to_s.to_sym].is_a?(Hash)
                                errors[:ServiceDocumentDO][container.guid.to_s.to_sym] = errors[:ServiceDocumentDO][container.guid.to_s.to_sym].merge(tempErrorHash)
                            else
                                MobiSys::CommonUtil.registerException(container.policyGuid, "#{container.guid}-documentIsMandatory", "ERR_MANDATORYSERVICEDOC", MobiSys::BrowserHelper.getLabel("ERR_MANDATORYSERVICEDOC"), $currentTabId, [docCategoryMap.documentDesc, categoryCdDescHM[docCategory.categoryTypeCd] << ' ' << MobiSys::BrowserHelper.getLabel("categoryCd"),lifeName])
                            end
                        end
                    else
                    	container.ServiceDocumentList.each do |serviceDocument|
                            if serviceDocument.docCategoryCd.to_s == docCategoryMap.categoryCd && serviceDocument.documentCd.to_s == docCategoryMap.documentCd.to_s && serviceDocument.selected.to_s == 'YES' && serviceDocument.removed.to_s != 'YES'
                                documentCdList.push(serviceDocument.documentCd.to_s)
                                break
                            end
                        end
                    end
                end
            end

            # At least one image is mandatory, if any document is taken
            container.ServiceDocumentList.each_with_index do |serviceDocument, index|
                catgDesc = categoryCdDescHM[serviceDocument.docCategoryTypeCd].to_s + '-' + documentCdDescHM[serviceDocument.documentCd].to_s
                if serviceDocument.imageCount.to_i == 0 && serviceDocument.removed.to_s != 'YES' && serviceDocument.selected.to_s == 'YES'
                    unless $rhoconfig[:TABFEATUREREQD]
                        tempErrorHash = Hash.new
                        MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_MANDATORYSERVICEDOC", [MobiSys::BrowserHelper.getLabel("documentImage"), catgDesc, lifeName])
                        errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                    else
                        MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_MANDATORYSERVICEDOC", "ERR_MANDATORYSERVICEDOC", $currentTabId, [MobiSys::BrowserHelper.getLabel("documentImage"), catgDesc, lifeName])
                    end
                end
                if serviceDocument.disableOcrFl.to_s != "YES"
            	   validateServiceDocumentOcr(documentCdList, serviceDocument, container, policy, life, lifeName, catgDesc, errors)
                end
            end

        end
    	######################################################################################


        def self.validateServiceDocumentOcr(documentCdList, serviceDocument, container, policy, life, lifeName, catgDesc, errors, newImage = nil)
            if $rhoconfig[:ocr_enabled].value == "YES"
                documentCdObjHM = {}
                    documentM = Document.loadObject( 
                    :all,
                    :conditions => {
                        { :name => 'documentCd', :op => 'IN' } => documentCdList
                    }
                )
                documentCdObjHM = Hash[documentM.collect { |k,v| [k.documentCd, k] }]
                documentCdObj = documentCdObjHM[serviceDocument.documentCd.to_s] 
            
                if documentCdObj
                    documentPropertyList = DocumentProperty.find(:all, :conditions => {:parentKey => documentCdObj.object})
                    documentPropertyList.sort!{|x,y| x.priority.to_i <=> y.sortOrder.to_i}
                    ocrValidationProperties = documentPropertyList.select{|dp|dp if dp.ocrValidationMetadata.to_s != ""}
                    if !ocrValidationProperties.empty?
                        #Added a new parameter newImage for Ocr validation before saving data in the Db
                        #Changes done for addImage API Ocr validation
                        images = (newImage != nil ? [newImage] : Image.loadObject(:all, :conditions => { :parentRefGuid => serviceDocument.guid}))
                        images.each do |image|
                            image.OfflineFileList.each do |offlineFile|
                                next unless (/#{$rhoconfig[:applicable_image_extensions].gsub(",","|")}/ === offlineFile.fileLocation.to_s || offlineFile.fileLocation.to_s == "")
                                if offlineFile.fileEncrypted == 'YES'
                                  decodedContent = MobiSys::Encryption.decryptContent("#{offlineFile.fileContents}|#{offlineFile.encryptionIv}")
                                  imageBase64 = MobiSys::Encryption.encodeContents(decodedContent)
                                else
                                  imageBase64 = offlineFile.fileContents
                                end
                                # extractedData = MobiSys::BrowserHelper.documentTextDetection(imageBase64,true,documentCdObj)
                                extractedData = nil

                                extractedData = MobiSys::BrowserHelper.processOCRData(offlineFile.ocrExtractedText) if offlineFile.ocrExtractedText.to_s != ""
                                unless extractedData == nil || extractedData.empty?
                                    if extractedData[:identityTypeCd] != serviceDocument.documentCd
                                        unless $rhoconfig[:TABFEATUREREQD]
                                            tempErrorHash = Hash.new
                                            MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_DOCMISMATCH", [catgDesc])
                                            errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                            errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                                            errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                                        else
                                            MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_DOCMISMATCH", "ERR_DOCMISMATCH", $currentTabId, [catgDesc])
                                        end
                                    else
                                    documentPropertyList.each do |documentProperty|
                                        ocrValidationList = documentProperty.ocrValidationMetadata.to_s.split(",")
                                        ocrValidationList.each do |metaDataCd|
                                            className = metaDataCd.split('.').first
                                            fieldName = metaDataCd.split('.').last
                                            if className == "PartyDO"
                                              saved_data = if (fieldName.to_s.include?('dob') || fieldName.to_s.include?('birthDt'))
                                                getScreenDate(life.send(fieldName.to_sym).to_s)
                                              else
                                                life.send(fieldName.to_sym)
                                              end.to_s.downcase.force_encoding(Encoding::UTF_8)
                                                  if extractedData[:identityTypeCd].to_s == "DRL"
                                                  	if (fieldName.to_s.include?('firstName1'))
                                                  		saved_data = ([life.firstName1, life.middleName1].join(" ")).to_s.downcase
                                                    end
                                                  end

                                                unless extractedData["PartyDO.#{fieldName}"].to_s.downcase.include?(saved_data)
                                                  if extractedData[:identityTypeCd].to_s == "DRL"
                                                  	if (fieldName.to_s.include?('firstName1'))
                                                  		fieldName = "First Name and Middle Name"
                                                    end
                                                  end
                                                  if (fieldName.to_s.include?('birthDt'))
                                                  		fieldName = "dateOfBirth"
                                                  end
                                                    unless $rhoconfig[:TABFEATUREREQD]
                                                        tempErrorHash = Hash.new
                                                        MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_DATAMISMATCH", [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                        errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                                                        errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                                                    else
                                                        MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_DATAMISMATCH", "ERR_DATAMISMATCH", $currentTabId, [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                    end
                                                end
                                            elsif className == "PartyAdditionalFieldsDO"
                                                life.PartyAdditionalFieldsList.each do |partyAddtnl|
                                                    partyAddtnly_saved_data = if (fieldName.to_s.include?('field4') || fieldName.to_s.include?('field7'))
                                                      partyAddtnl.send(fieldName.to_sym)
                                                    end.to_s.downcase.force_encoding(Encoding::UTF_8)
                                                    unless extractedData["PartyAdditionalFieldsDO.#{fieldName}"].to_s.downcase.include?(partyAddtnly_saved_data)
                                                      # unless extractedData["PartyIdentityDO.#{fieldName}"].to_s.downcase.include?(partyIdentity.send(fieldName.to_sym).to_s.downcase)
                                                          unless $rhoconfig[:TABFEATUREREQD]
                                                              tempErrorHash = Hash.new
                                                              MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_DATAMISMATCH", [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                              errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                                              errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                                                              errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                                                          else
                                                              MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_DATAMISMATCH", "ERR_DATAMISMATCH", $currentTabId, [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                          end
                                                      end
                                                end
                                                  
                                            elsif className == "PartyIdentityDO"
                                                life.PartyIdentityList.each do |partyIdentity|
                                                  if extractedData[:identityTypeCd] == partyIdentity.identityTypeCd
                                                  party_identity_saved_data = if (fieldName.to_s.include?('issueDt') || fieldName.to_s.include?('expiryDt'))
                                                    getScreenDate(partyIdentity.send(fieldName.to_sym).to_s)
                                                  else
                                                    partyIdentity.send(fieldName.to_sym)
                                                  end.to_s.downcase.force_encoding(Encoding::UTF_8)
                                                    unless extractedData["PartyIdentityDO.#{fieldName}"].to_s.downcase.include?(party_identity_saved_data)
                                                      # unless extractedData["PartyIdentityDO.#{fieldName}"].to_s.downcase.include?(partyIdentity.send(fieldName.to_sym).to_s.downcase)
                                                          unless $rhoconfig[:TABFEATUREREQD]
                                                              tempErrorHash = Hash.new
                                                              MobiSys::CommonUtil.addErrors(tempErrorHash, "documentCd", "ERR_DATAMISMATCH", [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                              errors[:ServiceDocumentDO] = Hash.new if !errors[:ServiceDocumentDO].is_a?(Hash)
                                                              errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = Hash.new if !errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].is_a?(Hash)
                                                              errors[:ServiceDocumentDO][serviceDocument.guid.to_sym] = errors[:ServiceDocumentDO][serviceDocument.guid.to_sym].merge(tempErrorHash)
                                                          else
                                                              MobiSys::CommonUtil.registerException(container.policyGuid, "#{serviceDocument.guid}-documentCd", "ERR_DATAMISMATCH", "ERR_DATAMISMATCH", $currentTabId, [MobiSys::BrowserHelper.getLabel(fieldName), lifeName, catgDesc])
                                                          end
                                                      end
                                                  end
                                                end
                                            end
                                        end
                                    end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        ##################################################################################################

        def self.checkDocumentForEachLife(policy, errors)
          partyNames = policy.getPartyNames("tab_requirement")
          facetObj = $rhoconfig[:multiDocMode]
          multiDocMode = (facetObj && facetObj.actionValue.to_s == 'YES'? true : false) 
          partyNames.each do |partyGuid, partyDesc|
            isDocumentFound = false
            documentContainer = DocumentContainer.loadObject(
                :first,
                :conditions=>{
                    {:name=>'entityGuid'}=> partyGuid,
                    {:name=>'policyGuid'}=> policy.guid
                },
                :op => 'AND'
            )
            partyDocumentList = []
            partyDocumentList = documentContainer.ServiceDocumentList if documentContainer
            if partyDocumentList.size > 0
              partyDocumentList.each do |serviceDoc|
                if(serviceDoc.documentCd.to_s != "" and serviceDoc.removed.to_s != "YES")
                  if multiDocMode
                    if serviceDoc.selected.to_s == "YES"
                      isDocumentFound = true
                      break
                    end
                  else
                    isDocumentFound = true
                    break
                  end
                end
              end
            end

            if !isDocumentFound
              unless $rhoconfig[:TABFEATUREREQD]
                MobiSys::CommonUtil.addErrors(errors, "#{partyGuid}-requirements", "ERR_MANDATORYFOR", [MobiSys::BrowserHelper.getLabel('REQUIREMENTS'), partyDesc])
              else
                MobiSys::CommonUtil.registerException(policy.guid, "#{partyGuid}-requirements", "ERR_MANDATORYFOR",MobiSys::BrowserHelper.getLabel("ERR_MANDATORYFOR"), nil,  [MobiSys::BrowserHelper.getLabel('requirements'), partyDesc])
              end
            end
          end

          return true
        end

        ##################################################################################################

    	#Method to validate Signature in Agent Declarations Tab
    	def self.validateAgentDeclSignature(agentDeclarationSignature, errors)
            # validation for Signatures
            tempErrorHash = Hash.new
            if agentDeclarationSignature.signature.to_s == ""
            	MobiSys::CommonUtil.addErrors(tempErrorHash, "signature", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('agentSignature')])
            	if !tempErrorHash.empty?
            		errors[:ServiceSignatureDO] = Hash.new if !errors[:ServiceSignatureDO].is_a?(Hash)
            		errors[:ServiceSignatureDO][agentDeclarationSignature.guid.to_sym] = Hash.new if !errors[:ServiceSignatureDO][agentDeclarationSignature.guid.to_sym].is_a?(Hash)
            		errors[:ServiceSignatureDO][agentDeclarationSignature.guid.to_sym] = errors[:ServiceSignatureDO][agentDeclarationSignature.guid.to_sym].merge(tempErrorHash)
            	end
            end
        end        
        ##################################################################################################


      	#Method to validate all EAPP tabs in one go
    	def self.validateAllEappTabs(policy)
            $globalContextObjectMap = {}
            $currentValidationMetadata = nil
            $currentTabId = nil
          	eappErrors = Hash.new
          	product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
      
      		#Validate Agent Details
          	if policy.PolicyAgentList.size > 0
            	errors = Hash.new
	            #New Validation Code
	            # PolicySet.setObject(policy)
	            # validationContexts = PolicySet::ValidationContexts
	            # MobiSys::Validation.validationLoop(policy.hashForSync, validationContexts, errors, "PolicySet")
	            $total_error['agentDetails'] = errors
          	end
          

          	#Validate Proposer Details
          	policyHolder = policy.getParty("PROPOSER")
          	if policyHolder
	        	errors = Hash.new

	            #New Validation Code
	            PartySet.setObject(policyHolder)
	            validationContexts = PartySet::ValidationContexts
	            MobiSys::Validation.validationLoop(policyHolder.hashForSync, validationContexts, errors, "PartySet")
	            $total_error['proposerDetails'] = errors
      		end


      		#Validate Primary Details
      		insured = policy.getParty("PRIMARY")
      		if insured
		        errors = Hash.new

	            #New Validation Code
	            policyPartyRole = policy.getPolicyPartyRole("PRIMARY")
	            if policyPartyRole.partySameAsCd == 'PROPOSER'
	                #  proposer = policy.getParty("PROPOSER")
	                # proposer.roleCd = "PRIMARY"

	                # PartySet.setObject(proposer)
	                # validationContexts = PartySet::ValidationContexts
	                # MobiSys::Validation.validationLoop(proposer.hashForSync, validationContexts, errors, "PartySet")
	            else
	                PartySet.setObject(insured)
	                validationContexts = PartySet::ValidationContexts
	                MobiSys::Validation.validationLoop(insured.hashForSync, validationContexts, errors, "PartySet")
	            end
            	$total_error['insuredDetails'] = errors

            	if insured.birthDt.to_s != ""
              		if policy.proposalSignedDt.to_s != ""
            			toDate = Date.parse(policy.proposalSignedDt)
          			else
            			toDate = Date.parse(Time.new.strftime("%F 00:00:00 %z"))
          			end
		          	birthDt = Date.parse(insured.birthDt)
		          	age1 = MobiSys::ProductUtil.calculateAge(birthDt, MobiSys::ProductUtil::LASTBIRTHDAY, toDate)
		          	age2 = MobiSys::ProductUtil.calculateAge(birthDt, MobiSys::ProductUtil::LASTBIRTHDAY, Time.now)
          			if age2.to_i > age1.to_i
            			MobiSys::CommonUtil.addErrors(eappErrors, "age", "ERR_AGECHANGED", [insured.lastName1])
          			end

		          	difference = MobiSys::ProductUtil.getDifference(toDate, Time.now)
		          	years = difference.to_i / 10000
		          	months = difference.to_i % 10000 / 100
		          	days = difference.to_i % 100
		          	noofDays = years *365 + months*30 + days
          			if noofDays > 30
            			MobiSys::CommonUtil.addErrors(eappErrors, "age", "ERR_DAYS30LIMITSIGN", [])
          			end
        		end
          	end


          	#Validate Joint Life Details
          	jointLifeInsured = policy.getParty("JOINT")
          	if jointLifeInsured
        		errors = Hash.new

            	#New Validation Code
              	PartySet.setObject(jointLifeInsured)
	            validationContexts = PartySet::ValidationContexts
	            MobiSys::Validation.validationLoop(jointLifeInsured.hashForSync, validationContexts, errors, "PartySet")
	            $total_error['jointlifeDetails'] = errors
          	end


          	#Validate Supplementary Details
          	if policy.getParty("SUPPLEMENTARY")
        		errors = Hash.new

	            #New Validation Code
	            policy.PartyList.each do |suppInsured|
	                if suppInsured.roleCd == "SUPPLEMENTARY"
	                    PartySet.setObject(suppInsured)
	                    validationContexts = PartySet::ValidationContexts
	                    MobiSys::Validation.validationLoop(suppInsured.hashForSync, validationContexts, errors, "PartySet")
	                end
	            end
            	$total_error['supplementaryDetails'] = errors
          	end


          	#Validate Coverage Details
          	baseProduct = policy.getBaseProduct
          	if baseProduct
	            errors = Hash.new

	            #New Validation Code
	            PolicySet.setObject(policy)
	            validationContexts = PolicySet::ValidationContexts
	            MobiSys::Validation.validationLoop(policy.hashForSync, validationContexts, errors, "PolicySet")

	            if policy.quotationRefGuid.to_s == ""
	                productErrors = Hash.new
	                policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => policy.object})
	                if policy.getParty("PRIMARY") != nil && policy.getParty("PROPOSER") != nil
                        # set policy product sort order
                        listPolicyProduct = Array.new
                        policy.PolicyProductList.each do |policyProduct|
                            riderAsscFacet = product.getRiderAssociationFacet()
                            if policyProduct.productTypeCd == "RIDER"
                                riderAssc = product.getRiderAssociationDO(nil,baseProduct.productPlanOptionCd,policyProduct.productPlanOptionCd, riderAsscFacet, policyProduct.productSeq, policyProduct.partyRoleCd)
                                policyProduct.sortOrder = riderAssc.sortOrder if riderAssc
                            else
                                policyProduct.sortOrder = 0
                            end
                            listPolicyProduct.push policyProduct
                        end
                        listPolicyProduct.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
                        policy.setPolicyProductList(listPolicyProduct)
	                    quotation = MobiSys::PolicyBO.convertToQuotation(policy)
	                    quotation.QuotationProductList.each do |quotationProduct|
	                        party = quotation.getParty(quotationProduct)
	                        quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!=""
	                    end
                        MobiSys::ProductBO.validatePolicy(quotation, policy, "", productErrors)
                        policy.persistAll
	                    errors = productErrors.merge(errors) if !productErrors.empty?
	                end
	            end
	            $total_error['planDetails'] = errors
          	end

            
          	#Validate Nominee/Appointee Details
          	if policy.getParty("NOMINEE")
	            errors = Hash.new
	           
	            #New Validation Code
	            policy.PolicyPartyRoleList.each do |policyPartyRole|
	                if policyPartyRole.roleCd == "NOMINEE" && policyPartyRole.partySameAsCd.to_s == "OTHER"
	                    party = Party.loadObject(:first, :conditions => {{ :name => 'guid' } => policyPartyRole.refGuid})
	                    if party
	                        party.roleCd = "NOMINEE"
	                        PartySet.setObject(party)
	                        validationContexts = PartySet::ValidationContexts
	                        MobiSys::Validation.validationLoop(party.hashForSync, validationContexts, errors, "PartySet")
	                    end
	                elsif policyPartyRole.roleCd == "APPOINTEE" && policyPartyRole.partySameAsCd.to_s == "OTHER"
	                    party = Party.loadObject(:first, :conditions => {{ :name => 'guid' } => policyPartyRole.refGuid})
	                    if party
	                        party.roleCd = "APPOINTEE"
	                        PartySet.setObject(party)
	                        validationContexts = PartySet::ValidationContexts
	                        MobiSys::Validation.validationLoop(party.hashForSync, validationContexts, errors, "PartySet")
	                    end
	                end
	            end
	            $total_error['beneficiaryDetails'] = errors
          	end


          	#Validate Payment Details
          	if policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE") == nil
        		MobiSys::CommonUtil.addErrors(eappErrors, "paymentDetails", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('paymentDetails')])
      		else
                #Old Validation Code
        		errors = Hash.new
	            # validatePaymentDetails(policy, errors, $globalFacetHash[:payer])
	            # $total_error['paymentDetails'] = errors

                # New Validation Code
                inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
                CollectionSet.setObject(inward.InwardDetailsList[0], inward, inward.InwardPolicyList[0])
                validationContexts = CollectionSet::ValidationContexts
                MobiSys::Validation.validationLoop(inward.hashForSync, validationContexts, errors, "CollectionSet")
                
                if inward.payerTypeCd == "OTHER"
                    inwardPayer = policy.getPayerParty("INITIAL")
                    PartySet.setObject(inwardPayer)
                    validationContexts = PartySet::ValidationContexts
                    MobiSys::Validation.validationLoop(inwardPayer.hashForSync, validationContexts, errors, "PartySet")
                end

                renewalPayment = policy.getPolicyPayment("RENEWALPREMIUM")
                if renewalPayment
                    PolicySet.setObject(nil, renewalPayment)
                    validationContexts = PolicySet::ValidationContexts
                    MobiSys::Validation.validationLoop(renewalPayment.hashForSync, validationContexts, errors, "PolicySet")

                    if renewalPayment.payerTypeCd == "OTHER"
                        renewalPayer = policy.getPayerParty("INITIAL")
                        PartySet.setObject(renewalPayer)
                        validationContexts = PartySet::ValidationContexts
                        MobiSys::Validation.validationLoop(renewalPayer.hashForSync, validationContexts, errors, "PartySet")
                    end

                    renewalFinancialAccount = PartyFinancialAccount.loadObject(:first, :conditions=>{{:name=>'guid'}=>renewalPayment.partyFinAccRefGuid})
                    renewalFinancialAccount.paymentMethodCd = renewalPayment.paymentMethodCd
                    if renewalFinancialAccount != nil && renewalPayment.paymentMethodCd.to_s != ""
                        PartySet.setObject(nil, nil,nil,nil,nil,nil, renewalFinancialAccount)
                        validationContexts = PartySet::ValidationContexts
                        MobiSys::Validation.validationLoop(renewalFinancialAccount.hashForSync, validationContexts, errors, "PartySet")
                    end
                end

                $total_error['paymentDetails'] = errors

                #Validate refund details
                refundPayment = PolicyPayment.loadObject(
                    :first, 
                    :conditions=>{
                        {:name=>'parentKey'}=>policy.object,
                        {:name=>'paymentInstructionTypeCd'}=>"REFUND",
                        :op => 'AND'
                    }
                )
                if refundPayment
                    errors = Hash.new

                    PolicySet.setObject(nil, refundPayment)
                    validationContexts = PolicySet::ValidationContexts
                    MobiSys::Validation.validationLoop(refundPayment.hashForSync, validationContexts, errors, "PolicySet")

                    refundFinancialAccount = PartyFinancialAccount.loadObject(:first, :conditions=>{{:name=>'guid'}=>refundPayment.partyFinAccRefGuid})
                    refundFinancialAccount.paymentMethodCd = refundPayment.paymentMethodCd
                    if refundFinancialAccount != nil && refundPayment.paymentMethodCd.to_s != ""
                        PartySet.setObject(nil, nil,nil,nil,nil,nil, refundFinancialAccount)
                        validationContexts = PartySet::ValidationContexts
                        MobiSys::Validation.validationLoop(refundFinancialAccount.hashForSync, validationContexts, errors, "PartySet")
                    end
                    $total_error['paymentDetails'] = MobiSys::BrowserHelper.deep_merge($total_error['paymentDetails'], errors)
                end
          	end


      		#Validate Questionnaire
	      	container = QuestionContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
	      	errors = Hash.new
	      	count = 0
          getQuestionSetQuestionHash
	      	container.each do |question_container|
		        if question_container.entityTypeCd != "AGENT"
		        	party = Party.loadObject(:first, :conditions => {{:name => 'guid'} => question_container.entityGuid})
                        $currentTabId = "tab_questionnaire"
		          	MobiSys::Questionnaire.validateQuestionnaire(question_container, $questionSetQuestion, errors, party)
                        $currentTabId = nil
		          	count += 1
		        end
      		end
	      	if count == 0
	        	MobiSys::CommonUtil.addErrors(eappErrors, "questionnaire", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('questionnaire')])
	      	end
      		$total_error['questionnaireDetails'] = errors

            if $total_error['questionnaireDetails'].has_key?(:ServiceQuestionResponseDO)
    	      	emptyErrors = true
    	        $total_error['questionnaireDetails'][:ServiceQuestionResponseDO].each do |key, errorHash|
    	        	if errorHash.empty?
    	        		$total_error['questionnaireDetails'][:ServiceQuestionResponseDO].delete(key)
    	        	else
    	        		emptyErrors = false
    	        	end
    	        end
    	        $total_error['questionnaireDetails'].delete(:ServiceQuestionResponseDO) if emptyErrors
            end

            party_guids = policy.getPartyNames()

      		#Validate Service Document
      		errors = Hash.new
      		if policyHolder
      			container = DocumentContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>policyHolder.guid})
      			if container
                    validateServiceDocument(container, party_guids[container.entityGuid], policy, policyHolder, errors)
      			else
      				MobiSys::CommonUtil.addErrors(eappErrors, "requirements", "ERR_MANDATORY", [party_guids[policyHolder.guid].to_s << " " << MobiSys::BrowserHelper.getLabel('requirements')])
      			end
      		end
      		if insured
      			container = DocumentContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>insured.guid})
      			if container
      				validateServiceDocument(container, party_guids[container.entityGuid], policy, insured, errors)
      			else
      				MobiSys::CommonUtil.addErrors(eappErrors, "requirements", "ERR_MANDATORY", [party_guids[insured.guid].to_s << " " << MobiSys::BrowserHelper.getLabel('requirements')])
      			end
      		end
      		$total_error['requirementsDetails'] = errors
      

      		#Validate Agent Declaration
      		errors = Hash.new
      		container = QuestionContainer.loadObject(
      			:first, 
      			:conditions=>{
      				{:name => 'entityGuid'} => policy.guid,
      				{:name => 'entityTypeCd'} => "AGENT"
  				},
  				:op => "AND"
			)
      		if container
                        $currentTabId = "tab_agentDeclaration"
      			MobiSys::Questionnaire.validateQuestionnaire(container, $questionSetQuestion, errors)
                        $currentTabId = nil
      		else
      			MobiSys::CommonUtil.addErrors(eappErrors, "declaration", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('declaration')])
      		end 

      		signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{{:name=>'entityGuid'}=>policy.guid})
      		agentDeclarationSignature = MobiSys::SignatureUtil.getAgentSignature(policy, signatureContainer) if signatureContainer
      		validateAgentDeclSignature(agentDeclarationSignature, errors) if agentDeclarationSignature
      		if signatureContainer == nil || agentDeclarationSignature == nil
      			MobiSys::CommonUtil.addErrors(eappErrors, "agentSignature", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('agentSignature')])
      		end
      		$total_error['agentQuestionDetails'] = errors

            if $total_error['agentQuestionDetails'].has_key?(:ServiceQuestionResponseDO)
          		emptyErrors = true
          		$total_error['agentQuestionDetails'][:ServiceQuestionResponseDO].each do |key, errorHash|
          			if errorHash.empty?
          				$total_error['agentQuestionDetails'][:ServiceQuestionResponseDO].delete(key)
          			else
          				emptyErrors = false
          			end
          		end
          		$total_error['agentQuestionDetails'].delete(:ServiceQuestionResponseDO) if emptyErrors
            end

      		policyErrors = Hash.new
      		PolicySet.setObject(policy, policy.PolicyPaymentList[0], policy.PolicyProductList[0], policy.PolicyTopUpList[0])
      		validationContexts = PolicySet::ValidationContexts
      		MobiSys::Validation.validationLoop(policy.hashForSync, validationContexts, policyErrors, "PolicySet")
      		if !eappErrors.empty?
	      		policyErrors[:PolicyDO] = Hash.new if !policyErrors[:PolicyDO].is_a?(Hash)
	      		policyErrors[:PolicyDO][policy.guid.to_s] = Hash.new if !policyErrors[:PolicyDO][policy.guid.to_s].is_a?(Hash)
	      		policyErrors[:PolicyDO][policy.guid.to_s] = policyErrors[:PolicyDO][policy.guid.to_s].merge(eappErrors)
	      	end
      		$total_error['Policy Details'] = policyErrors
			$ageShowPopup = nil
    	end  
    	##################################################################################################

        #Method to get applicable questionset codes for a given Party.
        def self.getApplicableQuestionnaires(policy, party)
            @quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            partyNames = policy.getPartyNames("tab_questionnaire")

            productFacet = $currentProduct.getFacet('PRODUCTQUESTIONSETGROUP')
            proposerQuestFacet = $currentProduct.getFacet('PROPOSERQUESTIONSETGROUP')

            policyProductInsuredObj = PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>party.guid,{:name=>'roleCd'} => party.roleCd},:op => 'AND')
            displayProductQuestion = true
            displayProposerQuestion = false
            questionSetCd = ""
            proposerQuestionSetCd = ""

            if productFacet
                if productFacet.actionTypeCd=='VALUE' || productFacet.actionTypeCd=='LOOKUP'
                    questionSetCd = productFacet.actionValue
                elsif productFacet.actionTypeCd=='RULE'
                    prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(productFacet.ruleSeq, @quotation, @quotation.getBaseProduct, party)
                    questionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
                end
            end

            if party.roleCd.to_s == 'PROPOSER' 
                insuredPartyRole = policy.getPolicyPartyRole("PRIMARY")
                if insuredPartyRole
                    proposerIsSameAsInsured = insuredPartyRole.partySameAsCd.to_s == 'PROPOSER'
                else
                    proposerIsSameAsInsured = false
                end
                if proposerQuestFacet != nil
                    if proposerQuestFacet.actionTypeCd=='VALUE' || proposerQuestFacet.actionTypeCd=='LOOKUP'
                        proposerQuestionSetCd = proposerQuestFacet.actionValue
                    elsif proposerQuestFacet.actionTypeCd=='RULE'
                        prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(proposerQuestFacet.ruleSeq, @quotation, @baseProduct, party)
                        proposerQuestionSetCd = prodFacetDT.outputAction if prodFacetDT.to_s != ""
                    end
                    displayProposerQuestion = true if proposerQuestionSetCd != ''
                end
                if policyProductInsuredObj == nil && !proposerIsSameAsInsured
                    displayProductQuestion = false
                end
            end

            
            # questionSetData = QuestionSet.loadObject(:all)
            questionSetMapData = QuestionSetMap.find(
                :all,
                :order => ['parentQuestionSetCd', 'displayOrder']
            )
            # RhoLog.error("1809","1809 :-==#{$questionSetData.class}==#{$questionSetData}")
            # RhoLog.error("1810","1810 :-==#{questionSetData.class}==#{questionSetData}")
            clazz = Class.new do
                include MobiSys::Questionnaire 
            end
            getQuestionSetHash
            getQuestionSetQuestionHash
            questionnaire = clazz.new
            proposerApplicableQuestions = nil
            proposerRemovedQuestions = nil
            if displayProductQuestion && displayProposerQuestion            
                applicableQuestions , removedQuestions = questionnaire.getApplicableQuestionnaire($questionSetData, questionSetMapData, questionSetCd, @quotation, policy, party)
                proposerApplicableQuestions, proposerRemovedQuestions = questionnaire.getApplicableQuestionnaire($questionSetData, questionSetMapData, proposerQuestionSetCd, @quotation, policy, party)
            elsif displayProposerQuestion
                applicableQuestions , removedQuestions = questionnaire.getApplicableQuestionnaire($questionSetData, questionSetMapData, proposerQuestionSetCd, @quotation, policy, party)
            else
                applicableQuestions , removedQuestions = questionnaire.getApplicableQuestionnaire($questionSetData, questionSetMapData, questionSetCd, @quotation, policy, party)
            end

            return applicableQuestions , removedQuestions , proposerApplicableQuestions, proposerRemovedQuestions
        end
        ##################################################################################################

        def self.checkQuestionnaireApplicability(question_container, party, applicableQuestions, removedQuestions, proposerApplicableQuestions, proposerRemovedQuestions)
            currentApplicableQuestions = applicableQuestions[party.guid] || {}
            currentRemovedQuestions = removedQuestions[party.guid] || {}
            currentApplicableQuestions.merge!(proposerApplicableQuestions[party.guid]) if party.roleCd == "PROPOSER" && proposerApplicableQuestions && currentApplicableQuestions
            currentRemovedQuestions.merge!(proposerRemovedQuestions[party.guid]) if party.roleCd == "PROPOSER" && proposerRemovedQuestions && currentRemovedQuestions
            serviceQuestionHash = []
            question_container.ServiceQuestionResponseList.each do |serviceQuestionResponse|
                if currentRemovedQuestions.has_key? (serviceQuestionResponse.questionSetCd)
		            # $dirtyQuestionnaireTab = true
                    return true
                end 
                serviceQuestionHash << serviceQuestionResponse.questionSetCd
                question_container.questionnaireTypeCd = serviceQuestionResponse.questionnaireTypeCd unless question_container.questionnaireTypeCd
            end
            # $dirtyQuestionnaireTab = false
            qsqMapCreated = false
            reflexiveQuestionSetQuestionMap = nil
            staticQuestionSetQuestionMap = nil
            currentApplicableQuestions.each_key do |questionSetCd|
                unless serviceQuestionHash.include?(questionSetCd)
                    unless qsqMapCreated
                        reflexiveQuestionSetQuestionMap, staticQuestionSetQuestionMap = createQuestionSetQuestionMap
                        qsqMapCreated = true
                    end
                    qsqToCreate = reflexiveQuestionSetQuestionMap[questionSetCd.to_s] || staticQuestionSetQuestionMap[questionSetCd.to_s]
                    createServiceQuestionResponse(question_container, qsqToCreate, party)
                end
            end
            if qsqMapCreated
                question_container.persistAll
            end
            return false
        end

        def self.createQuestionSetQuestionMap
            reflexiveQuestionSetQuestion = QuestionSetQuestion.find(:all,
                            :conditions => {
                                {:name => 'conditional'} => "REFLEXIVE"
                            },
                            :select => ['questionSetCd', 'dataElementCd', 'lookupkey' ] )
            reflexiveQuestionSetQuestionMap = Hash[reflexiveQuestionSetQuestion.map { |i| [i.questionSetCd, i] }]
            staticQuestionSetQuestion = QuestionSetQuestion.find(:all,
                            :conditions => {
                                {:name => 'conditional'} => "STATIC",
                                {:name => 'displayOrder'} => "1"
                            },
                            :op => "AND",
                            :select => ['questionSetCd', 'dataElementCd', 'lookupkey'] )
            staticQuestionSetQuestionMap = Hash[staticQuestionSetQuestion.map { |i| [i.questionSetCd, i] }]
            return reflexiveQuestionSetQuestionMap, staticQuestionSetQuestionMap
        end

        def self.createServiceQuestionResponse(question_container, questionSetQuestion, party)
            return unless questionSetQuestion
            values = {
						:entityGuid => question_container.policyGuid,
						:questionSetCd => questionSetQuestion.questionSetCd,
						:questionDataElementCd => questionSetQuestion.dataElementCd
						# :versionId => 1
						# :removed => ""
					}

            serviceQuestionResponse = ServiceQuestionResponse.new(values)
            serviceQuestionResponse.partyGuid = party.guid if party
            serviceQuestionResponse.guid = serviceQuestionResponse.uniqueKey
             serviceQuestionResponse.parentReferencePath = serviceQuestionResponse.parentReferencePath
            serviceQuestionResponse.questionnaireTypeCd = question_container.questionnaireTypeCd
            #set response value if default lookup value is configured
            if questionSetQuestion.lookupkey.to_s !=""
                lookup = Lookupvalue.find(
                    :first,
                    :conditions => {
                        {:name => 'key'} => questionSetQuestion.lookupkey.to_s,
                        {:name => 'defaultFl'} => 'YES'
                    }
                )
                if lookup
                    serviceQuestionResponse.responseValue = lookup.cd
                end
            end
            question_container.addServiceQuestionResponse(serviceQuestionResponse)
        end

        def self.validateAllEappTabs_Jazz(policy)
            # Validation
            errors = Hash.new
            $globalContextObjectMap = {}
            $taskExceptionHash = []
            $currentValidationMetadata = nil
            $currentTabId = nil

            preValidateAllEappTabs(policy)


            if $rhoconfig[:contextBasedMetadata]
              classToFind = "#{policy.class.name}DO"
              contextMasterGeneratedArray = []
              if $contextMasterCache.has_key?(classToFind.to_sym)
                contextMasterList = $contextMasterCache[classToFind.to_sym]
                contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,policy)
              end
              MobiSys::Validation.processValidContexts(policy.hashForSync, contextMasterGeneratedArray, "PolicySet")
              validationContextsPolicy = $globalContextObjectMap[policy.guid]
              MobiSys::Validation.validationLoop(policy.hashForSync, validationContextsPolicy, errors, "PolicySet")
            else
              PolicySet.setObject(policy)
              validationContexts = PolicySet::ValidationContexts
              MobiSys::Validation.validationLoop(policy.hashForSync, validationContexts, errors, "PolicySet")
            end

            $currentTabId = nil

            policy.PartyList.each do |party|
                if $rhoconfig[:contextBasedMetadata]
                  validationContexts = $globalContextObjectMap[party.guid]
                else
                  PartySet.setObject(party)
                  validationContexts = PartySet::ValidationContexts
                end
                MobiSys::Validation.validationLoop(party.hashForSync, validationContexts, errors, "PartySet", policy.guid)
                # if party.roleCd.to_s == "PRIMARY" && party.birthDt.to_s != ""
                #     if policy.proposalSignedDt.to_s != ""
                #         toDate = Date.parse(policy.proposalSignedDt)
                #     else
                #         toDate = Date.parse(Time.new.strftime("%F 00:00:00 %z"))
                #     end
                #     birthDt = Date.parse(party.birthDt.to_s)
                #     age1 = MobiSys::ProductUtil.calculateAge(birthDt, MobiSys::ProductUtil::LASTBIRTHDAY, toDate)
                #     age2 = MobiSys::ProductUtil.calculateAge(birthDt, MobiSys::ProductUtil::LASTBIRTHDAY, Time.now)
                #     if age2.to_i > age1.to_i
                #         MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-age", "ERR_AGECHANGED", "ERR_AGECHANGED", "tab_primary", [party.lastName1])
                #     end

                #     difference = MobiSys::ProductUtil.getDifference(toDate, Time.now)
                #     years = difference.to_i / 10000
                #     months = difference.to_i % 10000 / 100
                #     days = difference.to_i % 100
                #     noofDays = years *365 + months*30 + days
                #     if noofDays > 30
                #         MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-age", "ERR_DAYS30LIMITSIGN", "ERR_DAYS30LIMITSIGN", "tab_primary", [])
                #     end
                # end
                $currentTabId = nil
            end

            @inward = policy.getInward(policy.proposalNum, "APPLICATION_SUSPENSE")
            
            if !@inward
              @inward = Inward.new
              @inward.inwardTypeCd = 'NEWBUSINESSR'
              @inward.inwardSubTypeCd = 'BASICPREMIUM'
              @inward.inwardDt = Time.now
              @inward.agentId = policy.baseAgentId
              @inward.status = ""
              policy.addInward(@inward)
              inwardPolicy = InwardPolicy.new
              inwardPolicy.policyNum =  policy.proposalNum if policy.proposalNum
              @inward.addInwardPolicy(inwardPolicy)
            end

            if @inward
                if $rhoconfig[:contextBasedMetadata]
                  classToFind = "#{@inward.class.name}DO"
                  contextMasterGeneratedArray = []
                  if $contextMasterCache.has_key?(classToFind.to_sym)
                    contextMasterList = $contextMasterCache[classToFind.to_sym]
                    contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,@inward)
                  end
                  MobiSys::Validation.processValidContexts(@inward.hashForSync, contextMasterGeneratedArray, "CollectionSet")
                  validationContexts = $globalContextObjectMap[@inward.guid].concat(validationContextsPolicy) if $globalContextObjectMap[@inward.guid]
                else
                  CollectionSet.setObject(@inward)
                  validationContexts = CollectionSet::ValidationContexts
                end
                MobiSys::Validation.validationLoop(@inward.hashForSync, validationContexts, errors, "CollectionSet", policy.guid)
            end

            containers = QuestionContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
            if containers
                partyQuestionContainerEntityGuids = containers.collect{|container| container.entityGuid}
            else
                partyQuestionContainerEntityGuids = []
            end

            party_guids = policy.getPartyNames('tab_questionnaire')
            # Validating questions for all lives
            party_guids.each do |partyGuid, partyName|
                unless partyQuestionContainerEntityGuids.include? partyGuid
                    MobiSys::CommonUtil.registerException(policy.guid, "#{partyGuid}-questionnaire", "ERR_MANDATORY", "ERR_MANDATORY", "tab_questionnaire", ["#{partyName}" + " " + MobiSys::BrowserHelper.getLabel('questionnaire')])
                end
            end
            getQuestionSetQuestionHash
            containers.each do |question_container|
                party = policy.getPartyByGuid(question_container.entityGuid)
                visitTab = false
                if question_container.entityTypeCd.to_s == "AGENT"
                    $currentTabId = "tab_agentDeclaration"
                else
                    $currentTabId = "tab_questionnaire"
                    # applicableQuestions , removedQuestions , proposerApplicableQuestions, proposerRemovedQuestions = getApplicableQuestionnaires(policy,party)
                    # visitTab = checkQuestionnaireApplicability(question_container, party, applicableQuestions, removedQuestions, proposerApplicableQuestions, proposerRemovedQuestions)
                    # if visitTab
                    #     # MobiSys::CommonUtil.registerException(policy.guid, "#{question_container.entityGuid}-questionnaire", "ERR_MANDATORYQUEST", "ERR_MANDATORYQUEST", "tab_questionnaire", [MobiSys::BrowserHelper.getLabel('questionnaire')])
                    #     $currentTabId = nil
                    #     break 
                    # end
                end
                unless visitTab
                   MobiSys::Questionnaire.validateQuestionnaire(question_container, $questionSetQuestion, errors, party,policy,$currentTabId)
                end
                $currentTabId = nil
            end

            containers = DocumentContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
            if containers
                partyDocumentContainerEntityGuids = containers.collect{|container| container.entityGuid}
            else
                partyDocumentContainerEntityGuids = []
            end
            party_guids = {}
            policy.PartyList.each do |party|
            	if ['PRIMARY','PROPOSER','SUPPLEMENTARY','JOINT','PAYER'].include?(party.roleCd)
					       displayName = (party.lastName1.to_s=="" && party.firstName1.to_s=="") ? (party.lastName2.to_s + " " + party.firstName2.to_s) : (party.lastName1.to_s + " " + party.firstName1.to_s)
					       party_guids[party.guid] = "#{MobiSys::BrowserHelper.getLabel(party.roleCd)}-#{displayName}"
				      end
            end

            #Commented this as the same validation is being done through checkDocumentForEachLife method to maintain the same process as online
            # Validating requirements for all lives
            # if policy.insuranceTypeCd.to_s == "LIFE"
            #     party_guids.each do |partyGuid, partyName|
            #         unless partyDocumentContainerEntityGuids.include? partyGuid
            #             MobiSys::CommonUtil.registerException(policy.guid, "#{partyGuid}-requirements", "ERR_MANDATORY", "ERR_MANDATORY", "tab_requirement", ["#{partyName}" + " " + MobiSys::BrowserHelper.getLabel('requirements')])
            #         end
            #     end
            # end

            signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid})
            quotSignatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.quotationRefGuid})
            fnaRequest = FNARequest.loadObject(:first, :conditions => {:fnaNum => policy.fnaId})
            p "fnaRequest====#{fnaRequest}"
            csaSignatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => fnaRequest.guid}) if fnaRequest
            p "csaSignatureContainer===#{csaSignatureContainer}"

            p "quotSignatureContainer=====#{quotSignatureContainer}"
            if signatureContainer
                serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd.to_s == "AGENTDECLARATION" || serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd.to_s == "AGENTSIGNATURECAPTURE"|| serviceSign.signatureTypeCd == "SIGNATURECAPTUREEAPPPROPOSER" || serviceSign.signatureTypeCd == "FATCASIGNATURECAPTURE" || serviceSign.signatureTypeCd == "SIGNATURECAPTUREEAPPPRIMARY" || serviceSign.signatureTypeCd == "PARENTSIGNATURECAPTURE" || serviceSign.signatureTypeCd == "AGENTTYPE" }
                serviceSignatures.each do |serviceSignObj|
                    if $rhoconfig[:contextBasedMetadata]
                      classToFind = "#{serviceSignObj.class.name}DO"
                      contextMasterGeneratedArray = []
                      if $contextMasterCache.has_key?(classToFind.to_sym)
                        contextMasterList = $contextMasterCache[classToFind.to_sym]
                        contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                      end
                      MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                      validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy) if $globalContextObjectMap[serviceSignObj.guid]
                    else
                      ServiceSignatureSet.setObject(serviceSignObj)
                      validationContexts = ServiceSignatureSet::ValidationContexts
                    end
                    MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
                end
            end
            if quotSignatureContainer
                serviceSignatures = quotSignatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTURE3"}
                p "serviceSignatures============#{serviceSignatures}"
                serviceSignatures.each do |serviceSignObj|
                    if $rhoconfig[:contextBasedMetadata]
                      classToFind = "#{serviceSignObj.class.name}DO"
                      contextMasterGeneratedArray = []
                      if $contextMasterCache.has_key?(classToFind.to_sym)
                        contextMasterList = $contextMasterCache[classToFind.to_sym]
                        contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                      end
                      MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                      validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
                    else
                      ServiceSignatureSet.setObject(serviceSignObj)
                      validationContexts = ServiceSignatureSet::ValidationContexts
                    end
                    MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
                end
            end
            if csaSignatureContainer
                serviceSignatures = csaSignatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd.to_s == "AGENTSIGNATURECAPTUREFNA" || serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTUREFNAPROPOSER"}
                serviceSignatures.each do |serviceSignObj|
                	p "serviceSignObj==fna===#{serviceSignObj}"
                    if $rhoconfig[:contextBasedMetadata]
                      classToFind = "#{serviceSignObj.class.name}DO"
                      contextMasterGeneratedArray = []
                      if $contextMasterCache.has_key?(classToFind.to_sym)
                        contextMasterList = $contextMasterCache[classToFind.to_sym]
                        contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                      end
                      MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                      validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
                    else
                      ServiceSignatureSet.setObject(serviceSignObj)
                      validationContexts = ServiceSignatureSet::ValidationContexts
                    end
                    MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
                end
            end
            p "errors======gghgh====#{errors}"
            product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
            listPolicyProduct = []
            riderAsscFacet = product.getRiderAssociationFacet()
            policy.PolicyProductList.each do |policyProduct|
                if policyProduct.productTypeCd == "RIDER"
                    baseProduct = policy.getBaseProduct
                    if baseProduct
                        baseProductPlanOptionCd = baseProduct.productPlanOptionCd.to_s
                    else
                        baseProductPlanOptionCd = policy.productPlanOptionCd.to_s
                    end
                    riderAssc = product.getRiderAssociationDO(nil,baseProductPlanOptionCd,policyProduct.productPlanOptionCd, riderAsscFacet, policyProduct.productSeq, policyProduct.partyRoleCd)
                    policyProduct.sortOrder = riderAssc.sortOrder if riderAssc
                else
                    policyProduct.sortOrder = 0
                end
                listPolicyProduct.push policyProduct
            end

            listPolicyProduct.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
            policy.setPolicyProductList(listPolicyProduct)
            
            quotation = MobiSys::PolicyBO.convertToQuotation(policy)
            quotation.QuotationProductList.each do |quotationProduct|
                party = quotation.getParty(quotationProduct)
                quotationProduct.combinedEntryAge = party.age if party and party.age.to_s !=""
            end
            MobiSys::ProductBO.validatePolicy(quotation, policy, "", Hash.new)
            validateCompanyFacet(policy, errors)

            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
            db.start_transaction
            $taskExceptionHash.each do |taskException|
                taskException.persistAll
            end
            db.commit
            $taskExceptionHash = nil
            $ageShowPopup = nil
            return policy
        end
        ##################################################################################################
        

    	#Method to validate EAPP Signatures
    	def self.validateEappSignature_Jazz(policy, signatureContainer, errors)
        MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache

    		$globalContextObjectMap = {}
            $currentValidationMetadata = nil
            $currentTabId = nil
            $taskExceptionHash = []
            if $rhoconfig[:contextBasedMetadata]
              validationContextsPolicy=[]
              if($globalContextObjectMap == nil || !$globalContextObjectMap.has_key?(policy.guid))
                classToFind = "#{policy.class.name}DO"
                contextMasterGeneratedArray = []
                if $contextMasterCache.has_key?(classToFind.to_sym)
                  contextMasterList = $contextMasterCache[classToFind.to_sym]
                  contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,policy)
                end
                MobiSys::Validation.processValidContexts(policy.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                validationContextsPolicy = $globalContextObjectMap[policy.guid]
              end
            end
            MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
            serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign|serviceSign.signatureTypeCd == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd == "AGENTSIGNATURECAPTURE" || serviceSign.signatureTypeCd == "SIGNATURECAPTUREEAPPPROPOSER" || serviceSign.signatureTypeCd == "FATCASIGNATURECAPTURE" }
            serviceSignatures.each do |serviceSignObj|
                if $rhoconfig[:contextBasedMetadata]
                  classToFind = "#{serviceSignObj.class.name}DO"
                  contextMasterGeneratedArray = []
                  if $contextMasterCache.has_key?(classToFind.to_sym)
                    contextMasterList = $contextMasterCache[classToFind.to_sym]
                    contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                  end
                  MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                  validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
                else 
                  ServiceSignatureSet.setObject(serviceSignObj)
                  validationContexts = ServiceSignatureSet::ValidationContexts
                end
                MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
            end

            quotation = Quotation.loadObject(:first,:conditions =>{:guid => policy.quotationRefGuid})
           
            if quotation
                signatureContainerQuotation = SignatureContainer.loadObject(:first,
                    :conditions => {
                        :entityGuid => quotation.guid
                    }
                )
            end
            # MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-guid", "ERR_PLZCOMPLETE_SIGNATURE", "ERR_PLZCOMPLETE_SIGNATURE", "tab_siIllustration", []) if !signatureContainerQuotation
            if signatureContainerQuotation
                serviceSignatures = signatureContainerQuotation.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd.to_s == "SIGNATURECAPTURE3"}
                p "serviceSignatures============#{serviceSignatures}"
                serviceSignatures.each do |serviceSignObj|
                    if $rhoconfig[:contextBasedMetadata]
                      classToFind = "#{serviceSignObj.class.name}DO"
                      contextMasterGeneratedArray = []
                      if $contextMasterCache.has_key?(classToFind.to_sym)
                        contextMasterList = $contextMasterCache[classToFind.to_sym]
                        contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                      end
                      MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                      validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
                    else
                      ServiceSignatureSet.setObject(serviceSignObj)
                      validationContexts = ServiceSignatureSet::ValidationContexts
                    end
                    MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
                end
            end


            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
            db.start_transaction
            $taskExceptionHash.each do |taskException|
                taskException.persistAll
            end
            db.commit
            $taskExceptionHash = nil
        end
        ##################################################################################################


        #Method to validate EAPP Agent Questions
        def self.validateEappAgentDeclaration_Jazz(policy,errors)
            MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache
            $globalContextObjectMap = {}
            $currentValidationMetadata = nil
            $currentTabId = nil
            $taskExceptionHash = []

            if $rhoconfig[:contextBasedMetadata]
              validationContextsPolicy=[]
              if($globalContextObjectMap == nil || !$globalContextObjectMap.has_key?(policy.guid))
                classToFind = "#{policy.class.name}DO"
                contextMasterGeneratedArray = []
                if $contextMasterCache.has_key?(classToFind.to_sym)
                  contextMasterList = $contextMasterCache[classToFind.to_sym]
                  contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,policy)
                end
                MobiSys::Validation.processValidContexts(policy.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                validationContextsPolicy = $globalContextObjectMap[policy.guid]
              end
            end
            MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
            container = QuestionContainer.loadObject(:all, :conditions=>{{:name=>'policyGuid'}=>policy.guid})
            container.each do |question_container|
                if question_container.entityTypeCd.to_s == "AGENT"
                    $currentTabId = "tab_agentDeclaration"
                    getQuestionSetQuestionHash
                    MobiSys::Questionnaire.validateQuestionnaire(question_container, $questionSetQuestion, errors, nil)
                end
            end

            signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => policy.guid}) 
            if signatureContainer
                serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "AGENTDECLARATION"}
                serviceSignatures.each do |serviceSignObj|
                  if $rhoconfig[:contextBasedMetadata]
                    classToFind = "#{serviceSignObj.class.name}DO"
                    contextMasterGeneratedArray = []
                    if $contextMasterCache.has_key?(classToFind.to_sym)
                      contextMasterList = $contextMasterCache[classToFind.to_sym]
                      contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                    end
                    MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                    validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
                  else 
                    ServiceSignatureSet.setObject(serviceSignObj)
                    validationContexts = ServiceSignatureSet::ValidationContexts
                  end
                  MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
                end
            end
            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
            db.start_transaction
            $taskExceptionHash.each do |taskException|
                taskException.persistAll
            end
            db.commit
            $taskExceptionHash = nil
        end
        ##################################################################################################


        #Method to validate EAPP Signatures
        def self.validateEappSignature(signatureContainer, errors)
            serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign|serviceSign.signatureTypeCd == "SIGNATURECAPTURE" || serviceSign.signatureTypeCd == "AGENTSIGNATURECAPTURE"}
            serviceSignatures.each do |serviceSignObj|
                case serviceSignObj.roleCd
                when "PROPOSER"
                    errorLabel = "policyOwnerSignature"
                when "PRIMARY"
                    errorLabel = "primaryInsuredSignature"
                when "GUARDIAN"
                    errorLabel = "guardianSignature"
                when "SUPPLEMENTARY"
                    errorLabel = "supplementaryInsuredSignature"
                else
                    errorLabel = "agentSignature"
                end
                if serviceSignObj.signature.to_s == ""
                    MobiSys::CommonUtil.addErrors(errors, errorLabel+"signature", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel(errorLabel)])
                end
                #RoleCd for Agent is blank
                #Signature date and place are not captured for agent, Hence, validate only signature for agent
                if serviceSignObj.roleCd.to_s != ""
                    if serviceSignObj.placeOfSignature.to_s == ""
                        MobiSys::CommonUtil.addErrors(errors, errorLabel+"placeOfSignature", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel(errorLabel) << " - " << MobiSys::BrowserHelper.getLabel("proposalSignedPlace")])
                    end
                    if serviceSignObj.signatureDt.to_s == ""
                        MobiSys::CommonUtil.addErrors(errors, errorLabel+"signatureDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel(errorLabel) << " - " << MobiSys::BrowserHelper.getLabel("proposalSignedDt")])
                    end
                end
            end  
        end
        ##################################################################################################


        #Method to validate EAPP Counter Offer Decision
        def self.validateCounterOfferResponse(policy, signatureContainer, errors)
          MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache
    			$globalContextObjectMap = {}
    			$currentValidationMetadata = nil
    			$currentTabId = nil
    			$taskExceptionHash = []
          if $rhoconfig[:contextBasedMetadata]

            validationContextsPolicy=[]
            if($globalContextObjectMap == nil || !$globalContextObjectMap.has_key?(policy.guid))
              classToFind = "#{policy.class.name}DO"
              contextMasterGeneratedArray = []
              if $contextMasterCache.has_key?(classToFind.to_sym)
                contextMasterList = $contextMasterCache[classToFind.to_sym]
                contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,policy)
              end
              MobiSys::Validation.processValidContexts(policy.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
              validationContextsPolicy = $globalContextObjectMap[policy.guid]
            end
          end
    			MobiSys::CommonUtil.clearTaskExceptionList(policy.guid)
    			if signatureContainer
    				serviceSignatures = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == "COUNTEROFFER"}
    				serviceSignatures.each do |serviceSignObj|
              if $rhoconfig[:contextBasedMetadata]
                classToFind = "#{serviceSignObj.class.name}DO"
                contextMasterGeneratedArray = []
                if $contextMasterCache.has_key?(classToFind.to_sym)
                  contextMasterList = $contextMasterCache[classToFind.to_sym]
                  contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,serviceSignObj)
                end
                MobiSys::Validation.processValidContexts(serviceSignObj.hashForSync, contextMasterGeneratedArray, "ServiceSignatureSet")
                validationContexts = $globalContextObjectMap[serviceSignObj.guid].concat(validationContextsPolicy)
              else
                ServiceSignatureSet.setObject(serviceSignObj)
                validationContexts = ServiceSignatureSet::ValidationContexts
              end
    					MobiSys::Validation.validationLoop(serviceSignObj.hashForSync, validationContexts, errors, "ServiceSignatureSet", policy.guid)
    				end
          end

			quotation = Quotation.loadObject(:first, :conditions => {:guid => policy.quotationRefGuid})
			if quotation && quotation.signature != "SUCCESS" && quotation.signatureDt.to_s == ""
				unless $rhoconfig[:TABFEATUREREQD]
					MobiSys::CommonUtil.addErrors(errors, "quotationRefGuid", "ERR_PLZACCEPT", [MobiSys::BrowserHelper.getLabel('SalesIllustration')])
				else
					MobiSys::CommonUtil.registerException(policy.guid, "#{policy.guid}-quotationRefGuid", "ERR_PLZACCEPT", "ERR_PLZACCEPT", nil, [MobiSys::BrowserHelper.getLabel('SalesIllustration')])
				end
			end

			db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
			db.start_transaction
			$taskExceptionHash.each do |taskException|
				taskException.persistAll
			end
			db.commit
			$taskExceptionHash = nil
        end

    	################################################################################
        #-----------------------Code used for Old Validation End-----------------------#
        ################################################################################


        def self.getServiceDocument(policyDocument, docCategoryTypeCd, docCategoryCd, documentCd = nil)
        	returnServiceDocument = nil

        	policyDocument.ServiceDocumentList.each do |serviceDocument|
        		if (serviceDocument != nil && 
        			serviceDocument.docCategoryTypeCd == docCategoryTypeCd &&
        			serviceDocument.docCategoryCd == docCategoryCd)

	        		if (documentCd == nil  || (documentCd != nil && serviceDocument.documentCd == documentCd))
	        			returnServiceDocument = serviceDocument
	        			break
	        		end            
	        	end
	        end
	        return returnServiceDocument
	    end
    	###################################################################################################


      	def self.convertToQuotation(policy,loadQuestionContainer=true)
            quotation = Quotation.new
            quotation.intimationSourceCd = policy.intimationSourceCd
            quotation.quotationDt = policy.riskCommencementDt
            quotation.isBackdatedFl = policy.isBackdatedFl
            quotation.guid = policy.guid
            quotation.insuranceTypeCd = policy.insuranceTypeCd

            quotation.tripTypeCd = policy.tripTypeCd
            quotation.maxTripPeriod = policy.maxTripPeriod
            quotation.travelGeographyCd = policy.travelGeographyCd
            quotation.visitPurposeCd = policy.visitPurposeCd
            quotation.numberOfAdult = policy.numberOfAdult
            quotation.numberOfChildren = policy.numberOfChildren
            quotation.startDt = policy.startDt
            quotation.endDt = policy.endDt
            quotation.coverTypeCd = policy.coverTypeCd
            quotation.uploadFlag = policy.uploadFlag
            
            quotation.quotAddtnlField1 = policy.quotAddtnlField1
            quotation.quotAddtnlField2 = policy.quotAddtnlField2
            quotation.quotAddtnlField3 = policy.quotAddtnlField3
            quotation.quotAddtnlField4 = policy.quotAddtnlField4
            quotation.quotAddtnlField5 = policy.quotAddtnlField5
            quotation.quotAddtnlField6 = policy.quotAddtnlField6
            quotation.quotAddtnlField7 = policy.quotAddtnlField7
            quotation.quotAddtnlField8 = policy.quotAddtnlField8
            quotation.quotAddtnlField9 = policy.quotAddtnlField9
            quotation.quotAddtnlField10 = policy.quotAddtnlField10
            quotation.quotAddtnlField11 = policy.quotAddtnlField11
            quotation.quotAddtnlField12 = policy.quotAddtnlField12
            
            if loadQuestionContainer
                quotQuestionContainer = QuestionContainer.loadObject(
                    :first,
                    :conditions=>{
                        {:name=>'entityGuid'} => policy.uniqueKey,
                        {:name=>'policyGuid'} => policy.uniqueKey
                    },
                    :op=>'AND'
                )
                quotation.questionContainer = quotQuestionContainer if quotQuestionContainer
            end

            insured = policy.getParty("PRIMARY")
            proposer = policy.getParty("PROPOSER")
            if proposer !=nil
                pqp = QuotationParty.new
                pqp.partyTypeCd = proposer.partyTypeCd
                pqp.title = proposer.titleCd
                pqp.otherTitle = proposer.otherTitle
                pqp.firstname = proposer.firstName1
                pqp.lastname = proposer.lastName1
                pqp.age = proposer.age
                pqp.genderCd = proposer.genderCd
                pqp.smoker = proposer.smoker
                pqp.nsap = proposer.nsap
                if proposer.PartyEmploymentList[0]
                    pqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass
                    pqp.industryCd = proposer.PartyEmploymentList[0].industryCd
                    pqp.natureOfDuty = proposer.PartyEmploymentList[0].natureOfDuty

                end
                if proposer.getPartyContact("MOBILE")
                    pqp.contactNum = proposer.getPartyContact("MOBILE").contactNum
                end
                if proposer.getPartyEmail
                    pqp.emailAddress = proposer.getPartyEmail.emailAddress
                end
                pqp.dob = proposer.birthDt
                pqp.citizenshipCd = proposer.citizenshipCd
                pqp.nationality = proposer.citizenshipCd
                pqp.roleCd = proposer.roleCd
                pqp.guid = proposer.guid
                pqp.monthlyIncome = proposer.monthlyIncome
                pqp.annualIncome = proposer.annualIncome
                pqp.maritalStatus = proposer.maritalStatusCd
                pqp.quotPartyAddtnField1 = proposer.quotPartyAddtnField1
                pqp.quotPartyAddtnField2 = proposer.quotPartyAddtnField2
                pqp.quotPartyAddtnField3 = proposer.quotPartyAddtnField3
                pqp.quotPartyAddtnField4 = proposer.quotPartyAddtnField4
                if loadQuestionContainer
                    pqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => proposer.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    pqp.questionContainer = pqpQuestionContainer if pqpQuestionContainer
                end
                quotation.addQuotationParty pqp
            end

            if insured
                iqp = QuotationParty.new
                if insured.roleCd =='PROPOSER'
                    quotation.proposerLASame="COPYFROMINSURED"
                    iqp.age = proposer.age
                    iqp.partyTypeCd = proposer.partyTypeCd
                    iqp.title = proposer.titleCd
                    iqp.otherTitle = proposer.otherTitle
                    iqp.genderCd = proposer.genderCd
                    iqp.smoker = proposer.smoker
                    iqp.nsap = proposer.nsap
                    iqp.relationCd = "SELF"                    
  	                if proposer.PartyEmploymentList[0]
  	                    iqp.occupationCd = proposer.PartyEmploymentList[0].occupationClass
                        iqp.industryCd = proposer.PartyEmploymentList[0].industryCd
                        iqp.natureOfDuty = proposer.PartyEmploymentList[0].natureOfDuty
  	                end
                    if proposer.getPartyContact("MOBILE")
                        iqp.contactNum = proposer.getPartyContact("MOBILE").contactNum
                    end
                    if proposer.getPartyEmail
                        iqp.emailAddress = proposer.getPartyEmail.emailAddress
                    end
                    iqp.dob = proposer.birthDt
                    iqp.firstname=proposer.firstName1
                    iqp.lastname=proposer.lastName1
                    iqp.citizenshipCd=proposer.citizenshipCd
                    iqp.nationality=proposer.citizenshipCd
                    iqp.roleCd="PRIMARY"
                    iqp.monthlyIncome = proposer.monthlyIncome
                    iqp.annualIncome = proposer.annualIncome
                    iqp.guid = proposer.guid
                    iqp.maritalStatus = proposer.maritalStatusCd
                    iqp.quotPartyAddtnField1 = proposer.quotPartyAddtnField1
                    iqp.quotPartyAddtnField2 = proposer.quotPartyAddtnField2
                    iqp.quotPartyAddtnField3 = proposer.quotPartyAddtnField3
                    iqp.quotPartyAddtnField4 = proposer.quotPartyAddtnField4
                    quotation.quotAddtnlField1 = "YES"
                else
                    quotation.proposerLASame=""
                    iqp.age = insured.age
                    iqp.partyTypeCd = insured.partyTypeCd
                    iqp.title = insured.titleCd
                    iqp.otherTitle = insured.otherTitle
                    iqp.genderCd = insured.genderCd
                    iqp.smoker = insured.smoker
                    iqp.nsap = insured.nsap
                    iqp.relationCd = insured.relationCd                 
                    if insured.PartyEmploymentList[0]
                        iqp.occupationCd = insured.PartyEmploymentList[0].occupationClass
                        iqp.industryCd = insured.PartyEmploymentList[0].industryCd
                        iqp.natureOfDuty = insured.PartyEmploymentList[0].natureOfDuty
                    end
                    if insured.getPartyContact("MOBILE")
                        iqp.contactNum = insured.getPartyContact("MOBILE").contactNum
                    end
                    if insured.getPartyEmail
                        iqp.emailAddress = insured.getPartyEmail.emailAddress
                    end
                    iqp.dob = insured.birthDt
                    iqp.firstname=insured.firstName1
                    iqp.lastname=insured.lastName1
                    iqp.citizenshipCd=insured.citizenshipCd
                    iqp.nationality=insured.citizenshipCd
                    iqp.roleCd=insured.roleCd
                    iqp.monthlyIncome = insured.monthlyIncome
                    iqp.annualIncome = insured.annualIncome
                    iqp.guid = insured.guid
                    iqp.maritalStatus = insured.maritalStatusCd
                    iqp.quotPartyAddtnField1 = insured.quotPartyAddtnField1
                    iqp.quotPartyAddtnField2 = insured.quotPartyAddtnField2
                    iqp.quotPartyAddtnField3 = insured.quotPartyAddtnField3
                    iqp.quotPartyAddtnField4 = insured.quotPartyAddtnField4
                    quotation.quotAddtnlField1 = "NO"
                end
                if loadQuestionContainer
                    iqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => insured.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    iqp.questionContainer = iqpQuestionContainer if iqpQuestionContainer
                end
                quotation.addQuotationParty iqp        
            end 

            joint = policy.getParty("JOINT")
            if joint !=nil && joint.removed.to_s != "YES"
                jqp = QuotationParty.new
                jqp.partyTypeCd = joint.partyTypeCd
                jqp.title = joint.titleCd
                jqp.otherTitle = joint.otherTitle
                jqp.firstname = joint.firstName1
                jqp.lastname = joint.lastName1
                jqp.age = joint.age
                jqp.genderCd = joint.genderCd
                jqp.smoker = joint.smoker
                jqp.nsap = joint.nsap
                jqp.relationCd = joint.relationCd
                if joint.PartyEmploymentList[0]
                    jqp.occupationCd = joint.PartyEmploymentList[0].occupationClass
                    jqp.industryCd = joint.PartyEmploymentList[0].industryCd
                    jqp.natureOfDuty = joint.PartyEmploymentList[0].natureOfDuty
                end
                if joint.getPartyContact("MOBILE")
                    jqp.contactNum = joint.getPartyContact("MOBILE").contactNum
                end
                if joint.getPartyEmail
                    jqp.emailAddress = joint.getPartyEmail.emailAddress
                end
                jqp.dob = joint.birthDt
                jqp.citizenshipCd = joint.citizenshipCd
                jqp.nationality = joint.citizenshipCd
                jqp.roleCd = joint.roleCd
                jqp.guid = joint.guid
                jqp.monthlyIncome = joint.monthlyIncome
                jqp.annualIncome = joint.annualIncome
                jqp.maritalStatus = joint.maritalStatusCd
                jqp.quotPartyAddtnField1 = joint.quotPartyAddtnField1
                jqp.quotPartyAddtnField2 = joint.quotPartyAddtnField2
                jqp.quotPartyAddtnField3 = joint.quotPartyAddtnField3
                jqp.quotPartyAddtnField4 = joint.quotPartyAddtnField4
                if loadQuestionContainer
                    jqpQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => joint.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    jqp.questionContainer = jqpQuestionContainer if jqpQuestionContainer
                end
                quotation.addQuotationParty jqp
            end

            #Deepali Singh: 25-08-2015 - Separating logic for base paln and rider, PolicyProductInvestmentFund is only for plan not for rider
            basePlan = policy.getBaseProduct
            if basePlan
                quotationProduct = QuotationProduct.new
                quotation.addQuotationProduct(quotationProduct)

                quotationProduct.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                quotationProduct.productId = basePlan.productId
                quotationProduct.productVersion = basePlan.productVersion
                quotationProduct.productSeq = basePlan.productSeq
                quotationProduct.parentproductSeq = basePlan.parentproductSeq
                quotationProduct.productTypeCd = basePlan.productTypeCd 
                quotationProduct.productFamilyCd = basePlan.productFamilyCd 
                quotationProduct.baseSumAssured = basePlan.baseSumAssured
                quotationProduct.baseAnnualPremium = basePlan.baseAnnualPremium 
                quotationProduct.modalPremium = basePlan.modalPremium
                quotationProduct.capturedPremiumAmt = basePlan.capturedPremiumAmt 
                quotationProduct.productTerm = basePlan.productTerm 
                quotationProduct.premiumPayingTerm = basePlan.premiumPayingTerm 
                quotationProduct.annualizedPremium = basePlan.annualizedPremium 
                quotationProduct.totAnnualizedPremium = basePlan.totAnnualizedPremium
                quotationProduct.vestingAge = basePlan.vestingAge
                quotationProduct.annuityAge = basePlan.annuityAge
                quotationProduct.annuityPerc = basePlan.annuityPerc
                quotationProduct.extraPremium = basePlan.extraPremium
                quotationProduct.maxTargetPremium = basePlan.maxTargetPremium
                quotationProduct.minTargetPremium = basePlan.minTargetPremium
                quotationProduct.recommendedPremium = basePlan.recommendedPremium
                quotationProduct.unapliedPremium = basePlan.unapliedPremium
                quotationProduct.linkedFl = basePlan.linkedFl
                quotationProduct.pdfRequiredFl = basePlan.pdfRequiredFl
                quotationProduct.topUpAllocSameAsPremAllocFl = basePlan.topUpAllocSameAsPremAllocFl
                quotationProduct.targetFundFl = basePlan.targetFundFl
                quotationProduct.builtInRiderFl = basePlan.builtInRiderFl
                quotationProduct.guid = basePlan.guid
                quotationProduct.premiumSAFl = basePlan.premiumSAFl
                quotationProduct.payoutFrequencyCd = basePlan.payoutFrequencyCd

                # every time get copied From Base Plan
                quotationProduct.paymentFrequencyCd = basePlan.paymentFrequencyCd
                quotationProduct.currencyCd = basePlan.currencyCd
                quotationProduct.paymentTypeCd = basePlan.paymentTypeCd
                quotationProduct.minTargetPremium = basePlan.minTargetPremium

                quotationProduct.productPlanOptionCd = basePlan.productPlanOptionCd 
                quotationProduct.planCode = basePlan.planCode 
                quotationProduct.productSeq = basePlan.productSeq
                quotationProduct.coi = basePlan.coi 

                quotationProduct.combinedEntryAge = basePlan.combinedEntryAge
                quotationProduct.portfolioModelCd = basePlan.portfolioModelCd
                quotationProduct.holderRefGuid = basePlan.object
                quotationProduct.selected = basePlan.selected

                quotationProduct.addtnField1 = basePlan.addtnField1 
                quotationProduct.addtnField2 = basePlan.addtnField2 
                quotationProduct.addtnField3 = basePlan.addtnField3 
                quotationProduct.addtnField4 = basePlan.addtnField4 
                quotationProduct.addtnField5 = basePlan.addtnField5 
                quotationProduct.addtnField6 = basePlan.addtnField6 
                # Extra Loading And Duration 
                quotationProduct.flatExtra = basePlan.flatExtra
                #quotationProduct.emr = basePlan.emr 

                quotationProduct.wopPremium = basePlan.wopPremium
                quotationProduct.wopPremium2 = basePlan.wopPremium2
                quotationProduct.wopPremiumQuarterly = basePlan.wopPremiumQuarterly
                quotationProduct.wopPremiumHalfYearly = basePlan.wopPremiumHalfYearly
                quotationProduct.wopPremiumMonthly = basePlan.wopPremiumMonthly
                quotationProduct.wopPremium2Quarterly = basePlan.wopPremium2Quarterly
                quotationProduct.wopPremium2HalfYearly = basePlan.wopPremium2HalfYearly
                quotationProduct.wopPremium2Monthly = basePlan.wopPremium2Monthly
                quotationProduct.wopPremium3 = basePlan.wopPremium3
                quotationProduct.wopPremium3Quarterly = basePlan.wopPremium3Quarterly
                quotationProduct.wopPremium3HalfYearly = basePlan.wopPremium3HalfYearly
                quotationProduct.wopPremium3Monthly = basePlan.wopPremium3Monthly
                quotationProduct.wopPremiumField = basePlan.wopPremiumField
                quotationProduct.wopPremiumField2 = basePlan.wopPremiumField2
                quotationProduct.wopPremiumField3 = basePlan.wopPremiumField3

                quotationProduct.sortOrder = basePlan.sortOrder
                quotationProduct.paidUpFl = basePlan.paidUpFl

                basePlan.PolicyProductInsuredList.each do|policyProductInsured|
                    quotationProduct.partyRoleCd = policyProductInsured.roleCd
                    quotationProduct.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                end

                basePlan.PolicyProductExtraList.each do|policyProductExtra|
                	quotationProductExtra = QuotationProductExtra.new
                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
                    quotationProduct.addQuotationProductExtra(quotationProductExtra)
                end

                basePlan.PolicyProductInvestmentFundList.each do|fund|
                	next if fund.removed.to_s == "YES"
                    quotationFund = QuotationProductInvestmentFund.new
                    quotationFund.fundCd = fund.fundCd
                    quotationFund.allocationPerc = fund.allocationPerc
                    quotationFund.guid = fund.guid
                    quotationFund.topupAllocationPerc = fund.topupAllocationPerc
                    quotationFund.expiryDt = fund.expiryDt
                    quotationFund.fundTypeCd = fund.fundTypeCd
                    quotationFund.maturityDt = fund.maturityDt
                    quotationProduct.addQuotationProductInvestmentFund(quotationFund)
                end

                basePlan.PolicyProductAdditionalList.each do |policyProductAdditional| 
                    quotationProductAdditional = QuotationProductAdditional.new
                    quotationProductAdditional.prdAddtnField1str = policyProductAdditional.prdAddtnField1str
                    quotationProductAdditional.prdAddtnField2str = policyProductAdditional.prdAddtnField2str
                    quotationProductAdditional.prdAddtnField3str = policyProductAdditional.prdAddtnField3str
                    quotationProductAdditional.prdAddtnField4str = policyProductAdditional.prdAddtnField4str
                    quotationProductAdditional.prdAddtnField5str = policyProductAdditional.prdAddtnField5str
                    quotationProductAdditional.prdAddtnField6d = policyProductAdditional.prdAddtnField6d
                    quotationProductAdditional.prdAddtnField7d = policyProductAdditional.prdAddtnField7d
                    quotationProductAdditional.prdAddtnField8d = policyProductAdditional.prdAddtnField8d
                    quotationProductAdditional.prdAddtnField9d = policyProductAdditional.prdAddtnField9d
                    quotationProductAdditional.prdAddtnField10d = policyProductAdditional.prdAddtnField10d
                    quotationProductAdditional.prdAddtnField11d = policyProductAdditional.prdAddtnField11d
                    quotationProductAdditional.prdAddtnField12d = policyProductAdditional.prdAddtnField12d
                    quotationProductAdditional.prdAddtnField13d = policyProductAdditional.prdAddtnField13d
                    quotationProductAdditional.prdAddtnField14d = policyProductAdditional.prdAddtnField14d
                    quotationProductAdditional.prdAddtnField15d = policyProductAdditional.prdAddtnField15d
                    quotationProductAdditional.prdAddtnField16dt = policyProductAdditional.prdAddtnField16dt
                    quotationProductAdditional.prdAddtnField17dt = policyProductAdditional.prdAddtnField17dt
                    quotationProductAdditional.prdAddtnField18dt = policyProductAdditional.prdAddtnField18dt
                    quotationProductAdditional.prdAddtnField19dt = policyProductAdditional.prdAddtnField19dt
                    quotationProductAdditional.prdAddtnField20dt = policyProductAdditional.prdAddtnField20dt
                    quotationProductAdditional.productRefGuid = policyProductAdditional.productRefGuid
                end
            end

            policy.PolicyProductList.each do |policyRider|
                if policyRider.productTypeCd == "RIDER"
                    quotationRider = QuotationProduct.new(:productTypeCd => "RIDER")
                    quotation.addQuotationProduct(quotationRider)
                    quotationRider.product = MobiSys::ProductUtil.getProduct(policyRider.productSeq)
                    quotationRider.productId = policyRider.productId
                    quotationRider.productVersion = policyRider.productVersion
                    quotationRider.productSeq = policyRider.productSeq
                    quotationRider.parentproductSeq = policyRider.parentproductSeq
                    quotationRider.productTypeCd = policyRider.productTypeCd 
                    quotationRider.productFamilyCd = policyRider.productFamilyCd 
                    quotationRider.baseSumAssured = policyRider.baseSumAssured
                    quotationRider.baseAnnualPremium = policyRider.baseAnnualPremium 
                    quotationRider.modalPremium = policyRider.modalPremium
                    quotationRider.capturedPremiumAmt = policyRider.capturedPremiumAmt 
                    quotationRider.productTerm = policyRider.productTerm 
                    quotationRider.premiumPayingTerm = policyRider.premiumPayingTerm 
                    quotationRider.annualizedPremium = policyRider.annualizedPremium 
                    quotationRider.totAnnualizedPremium = policyRider.totAnnualizedPremium
	                quotationRider.vestingAge = policyRider.vestingAge
	                quotationRider.annuityPerc = policyRider.annuityPerc
                    quotationRider.extraPremium = policyRider.extraPremium
                    quotationRider.maxTargetPremium = policyRider.maxTargetPremium
                    quotationRider.minTargetPremium = policyRider.minTargetPremium
                    quotationRider.recommendedPremium = policyRider.recommendedPremium
                    quotationRider.unapliedPremium = policyRider.unapliedPremium
                    quotationRider.linkedFl = policyRider.linkedFl
                    quotationRider.pdfRequiredFl = policyRider.pdfRequiredFl
                    quotationRider.topUpAllocSameAsPremAllocFl = policyRider.topUpAllocSameAsPremAllocFl
                    quotationRider.targetFundFl = policyRider.targetFundFl
                    quotationRider.builtInRiderFl = policyRider.builtInRiderFl
                    quotationRider.guid = policyRider.guid
                    quotationRider.premiumSAFl = policyRider.premiumSAFl
                    quotationRider.productLongName = policyRider.productLongName

                    # every time get copied From Base Plan
                    quotationRider.paymentFrequencyCd = policyRider.paymentFrequencyCd
                    quotationRider.currencyCd = policyRider.currencyCd
                    quotationRider.paymentTypeCd = policyRider.paymentTypeCd
                    quotationProduct.minTargetPremium = policyRider.minTargetPremium

                    quotationRider.productPlanOptionCd = policyRider.productPlanOptionCd 
                    quotationRider.planCode = policyRider.planCode 
                    quotationRider.productSeq = policyRider.productSeq
                    quotationRider.coi = policyRider.coi 

                    quotationRider.combinedEntryAge = policyRider.combinedEntryAge
                    quotationRider.portfolioModelCd = policyRider.portfolioModelCd
                    quotationRider.holderRefGuid = policyRider.object
                    quotationRider.selected = policyRider.selected

                    quotationRider.addtnField1 = policyRider.addtnField1 
                    quotationRider.addtnField2 = policyRider.addtnField2 
                    quotationRider.addtnField3 = policyRider.addtnField3 
                    quotationRider.addtnField4 = policyRider.addtnField4 
                    quotationRider.addtnField5 = policyRider.addtnField5 
                    quotationRider.addtnField6 = policyRider.addtnField6 
                    # Extra Loading And Duration 
                    quotationRider.flatExtra = policyRider.flatExtra

                    quotationRider.wopPremium = policyRider.wopPremium
                    quotationRider.wopPremium2 = policyRider.wopPremium2
                    quotationRider.wopPremiumQuarterly = policyRider.wopPremiumQuarterly
                    quotationRider.wopPremiumHalfYearly = policyRider.wopPremiumHalfYearly
                    quotationRider.wopPremiumMonthly = policyRider.wopPremiumMonthly
                    quotationRider.wopPremium2Quarterly = policyRider.wopPremium2Quarterly
                    quotationRider.wopPremium2HalfYearly = policyRider.wopPremium2HalfYearly
                    quotationRider.wopPremium2Monthly = policyRider.wopPremium2Monthly
                    quotationRider.wopPremium3 = policyRider.wopPremium3
                    quotationRider.wopPremium3Quarterly = policyRider.wopPremium3Quarterly
                    quotationRider.wopPremium3HalfYearly = policyRider.wopPremium3HalfYearly
                    quotationRider.wopPremium3Monthly = policyRider.wopPremium3Monthly
                    quotationRider.wopPremiumField = policyRider.wopPremiumField
                    quotationRider.wopPremiumField2 = policyRider.wopPremiumField2
                    quotationRider.wopPremiumField3 = policyRider.wopPremiumField3
                    quotationRider.paidUpFl = policyRider.paidUpFl

                    quotationRider.sortOrder = policyRider.sortOrder

                    policyRider.PolicyProductInsuredList.each do|policyProductInsured|
                        if quotation.proposerLASame == "COPYFROMINSURED" && policyProductInsured.roleCd.to_s == 'PRIMARY'
                                quotationRider.insuredPartyRefGuid = insured.guid
                        else 
                            quotationRider.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                        end
                        quotationRider.partyRoleCd = policyProductInsured.roleCd
                    end

	                policyRider.PolicyProductExtraList.each do|policyProductExtra|
	                	quotationProductExtra = QuotationProductExtra.new
	                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
	                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
	                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
	                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
	                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
	                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
	                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
	                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
	                    quotationRider.addQuotationProductExtra(quotationProductExtra)
	                end
                elsif policyRider.productTypeCd == "PLANMULTI"
					quotationPlanMulti = QuotationProduct.new(:productTypeCd => "PLANMULTI")
					quotation.addQuotationProduct(quotationPlanMulti)

					quotationPlanMulti.product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
					quotationPlanMulti.productId = policyRider.productId
					quotationPlanMulti.productVersion = policyRider.productVersion
					quotationPlanMulti.productSeq = policyRider.productSeq
					quotationPlanMulti.parentproductSeq = policyRider.parentproductSeq
					quotationPlanMulti.productTypeCd = policyRider.productTypeCd 
					quotationPlanMulti.productFamilyCd = policyRider.productFamilyCd 
					quotationPlanMulti.baseSumAssured = policyRider.baseSumAssured
					quotationPlanMulti.baseAnnualPremium = policyRider.baseAnnualPremium 
					quotationPlanMulti.modalPremium = policyRider.modalPremium
					quotationPlanMulti.capturedPremiumAmt = policyRider.capturedPremiumAmt 
					quotationPlanMulti.productTerm = policyRider.productTerm 
					quotationPlanMulti.premiumPayingTerm = policyRider.premiumPayingTerm 
					quotationPlanMulti.annualizedPremium = policyRider.annualizedPremium 
					quotationPlanMulti.totAnnualizedPremium = policyRider.totAnnualizedPremium
	                quotationPlanMulti.vestingAge = policyRider.vestingAge
	                quotationPlanMulti.annuityPerc = policyRider.annuityPerc
					quotationPlanMulti.extraPremium = policyRider.extraPremium
					quotationPlanMulti.maxTargetPremium = policyRider.maxTargetPremium
					quotationPlanMulti.minTargetPremium = policyRider.minTargetPremium
					quotationPlanMulti.recommendedPremium = policyRider.recommendedPremium
					quotationPlanMulti.unapliedPremium = policyRider.unapliedPremium
					quotationPlanMulti.linkedFl = policyRider.linkedFl
					quotationPlanMulti.pdfRequiredFl = policyRider.pdfRequiredFl
					quotationPlanMulti.topUpAllocSameAsPremAllocFl = policyRider.topUpAllocSameAsPremAllocFl
					quotationPlanMulti.targetFundFl = policyRider.targetFundFl
					quotationPlanMulti.builtInRiderFl = policyRider.builtInRiderFl
					quotationPlanMulti.guid = policyRider.guid
					quotationPlanMulti.premiumSAFl = policyRider.premiumSAFl

					# every time get copied From Base Plan
					quotationPlanMulti.paymentFrequencyCd = policyRider.paymentFrequencyCd
					quotationPlanMulti.currencyCd = policyRider.currencyCd
					quotationPlanMulti.paymentTypeCd = policyRider.paymentTypeCd
                    quotationPlanMulti.minTargetPremium = policyRider.minTargetPremium

					quotationPlanMulti.productPlanOptionCd = policyRider.productPlanOptionCd 
					quotationPlanMulti.planCode = policyRider.planCode 
					quotationPlanMulti.productSeq = policyRider.productSeq
					quotationPlanMulti.coi = policyRider.coi 

					quotationPlanMulti.combinedEntryAge = policyRider.combinedEntryAge
					quotationPlanMulti.portfolioModelCd = policyRider.portfolioModelCd
					quotationPlanMulti.holderRefGuid = policyRider.object
					quotationPlanMulti.selected = policyRider.selected

					quotationPlanMulti.addtnField1 = policyRider.addtnField1 
					quotationPlanMulti.addtnField2 = policyRider.addtnField2 
					quotationPlanMulti.addtnField3 = policyRider.addtnField3 
					quotationPlanMulti.addtnField4 = policyRider.addtnField4 
					quotationPlanMulti.addtnField5 = policyRider.addtnField5 
					quotationPlanMulti.addtnField6 = policyRider.addtnField6 
					# Extra Loading And Duration 
					quotationPlanMulti.flatExtra = policyRider.flatExtra
					#quotationPlanMulti.emr = policyRider.emr 

					quotationPlanMulti.wopPremium = policyRider.wopPremium
					quotationPlanMulti.wopPremium2 = policyRider.wopPremium2
					quotationPlanMulti.wopPremiumQuarterly = policyRider.wopPremiumQuarterly
					quotationPlanMulti.wopPremiumHalfYearly = policyRider.wopPremiumHalfYearly
					quotationPlanMulti.wopPremiumMonthly = policyRider.wopPremiumMonthly
					quotationPlanMulti.wopPremium2Quarterly = policyRider.wopPremium2Quarterly
					quotationPlanMulti.wopPremium2HalfYearly = policyRider.wopPremium2HalfYearly
					quotationPlanMulti.wopPremium2Monthly = policyRider.wopPremium2Monthly
					quotationPlanMulti.wopPremium3 = policyRider.wopPremium3
					quotationPlanMulti.wopPremium3Quarterly = policyRider.wopPremium3Quarterly
					quotationPlanMulti.wopPremium3HalfYearly = policyRider.wopPremium3HalfYearly
					quotationPlanMulti.wopPremium3Monthly = policyRider.wopPremium3Monthly
					quotationPlanMulti.wopPremiumField = policyRider.wopPremiumField
					quotationPlanMulti.wopPremiumField2 = policyRider.wopPremiumField2
					quotationPlanMulti.wopPremiumField3 = policyRider.wopPremiumField3
          quotationPlanMulti.paidUpFl = policyRider.paidUpFl
					policyRider.PolicyProductInsuredList.each do|policyProductInsured|
						if quotation.proposerLASame == "COPYFROMINSURED" && policyProductInsured.roleCd.to_s == 'PRIMARY'
							quotationPlanMulti.insuredPartyRefGuid = insured.guid
						else 
							quotationPlanMulti.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
						end
						quotationPlanMulti.partyRoleCd = policyProductInsured.roleCd
					end
					quotationPlanMulti.sortOrder = policyRider.sortOrder

	                policyRider.PolicyProductExtraList.each do|policyProductExtra|
	                	quotationProductExtra = QuotationProductExtra.new
	                    quotationProductExtra.extraTypeCd = policyProductExtra.extraTypeCd
	                    quotationProductExtra.decisionCd = policyProductExtra.decisionCd
	                    quotationProductExtra.loadingTypeCd = policyProductExtra.loadingTypeCd
	                    quotationProductExtra.processingTypeCd = policyProductExtra.processingTypeCd
	                    quotationProductExtra.extraFlatAmt = policyProductExtra.extraFlatAmt
	                    quotationProductExtra.extraPercent = policyProductExtra.extraPercent
	                    quotationProductExtra.extraFlatDuration = policyProductExtra.extraFlatDuration
	                    quotationProductExtra.extraPercDuration = policyProductExtra.extraPercDuration
	                    quotationPlanMulti.addQuotationProductExtra(quotationProductExtra)
	                end
                end
            end    

            policySupplementary = policy.getPartyList("SUPPLEMENTARY")
            policySupplementary.each do |suplementary|
                quotationParty = QuotationParty.new
                quotationParty.object=suplementary.object
                quotationParty.title = suplementary.titleCd
                quotationParty.otherTitle = suplementary.otherTitle
                quotationParty.firstname=suplementary.firstName1
                quotationParty.lastname=suplementary.lastName1
                quotationParty.age = suplementary.age
                quotationParty.genderCd = suplementary.genderCd
                quotationParty.smoker = suplementary.smoker
                quotationParty.nsap = suplementary.nsap  
                quotationParty.partyTypeCd = suplementary.partyTypeCd

                if suplementary.PartyEmploymentList[0]
                    quotationParty.occupationCd = suplementary.PartyEmploymentList[0].occupationClass
                    quotationParty.industryCd = suplementary.PartyEmploymentList[0].industryCd
                    quotationParty.natureOfDuty = suplementary.PartyEmploymentList[0].natureOfDuty
                end
                if suplementary.getPartyContact("MOBILE")
                    quotationParty.contactNum = suplementary.getPartyContact("MOBILE").contactNum
                end
                if suplementary.getPartyEmail
                    quotationParty.emailAddress = suplementary.getPartyEmail.emailAddress
                end
                quotationParty.dob = suplementary.birthDt
                quotationParty.roleCd = suplementary.roleCd
                quotationParty.relationCd = suplementary.relationCd
                quotationParty.citizenshipCd=suplementary.citizenshipCd
                quotationParty.nationality=suplementary.citizenshipCd
                quotationParty.guid = suplementary.guid
                quotationParty.maritalStatus = suplementary.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = suplementary.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = suplementary.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = suplementary.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = suplementary.quotPartyAddtnField4
                if loadQuestionContainer
                    suppQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions=>{
                                {:name=>'entityGuid'} => suplementary.guid,
                                {:name=>'policyGuid'} => policy.uniqueKey
                            },
                            :op=>'AND'
                        )
                    quotationParty.questionContainer = suppQuestionContainer if suppQuestionContainer
                end
                quotation.addQuotationParty(quotationParty)
            end

            payerList = policy.getPartyList("PAYER")
            payerList.each do |payer|
                quotationParty = QuotationParty.new
                quotationParty.title = payer.titleCd
                quotationParty.guid = payer.guid
                quotationParty.otherTitle = payer.otherTitle
                quotationParty.guid = payer.guid
                quotationParty.firstname = payer.firstName1
                quotationParty.lastname = payer.lastName1
                quotationParty.age = payer.age
                quotationParty.genderCd = payer.genderCd
                quotationParty.smoker = payer.smoker     
                quotationParty.nsap = payer.nsap        
                quotationParty.partyTypeCd = payer.partyTypeCd           
                if payer.PartyEmploymentList[0]
                    quotationParty.occupationCd = payer.PartyEmploymentList[0].occupationClass
                    quotationParty.industryCd = payer.PartyEmploymentList[0].industryCd
                    quotationParty.natureOfDuty = payer.PartyEmploymentList[0].natureOfDuty
                end
                if payer.getPartyContact("MOBILE")
                    quotationParty.contactNum = payer.getPartyContact("MOBILE").contactNum
                end
                if payer.getPartyEmail
                    quotationParty.emailAddress = payer.getPartyEmail.emailAddress
                end
                quotationParty.dob = payer.birthDt
                quotationParty.roleCd = "PAYER"
                quotationParty.relationCd = payer.relationCd
                quotationParty.citizenshipCd=payer.citizenshipCd
                quotationParty.nationality=payer.citizenshipCd
                quotationParty.maritalStatus = payer.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = payer.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = payer.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = payer.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = payer.quotPartyAddtnField4
                quotation.addQuotationParty(quotationParty)
            end

            nomineeList = policy.getPartyList("NOMINEE")
            nomineeList.each do |nomineee|
                quotationParty = QuotationParty.new
                quotationParty.title = nomineee.titleCd
                quotationParty.guid = nomineee.guid
                quotationParty.otherTitle = nomineee.otherTitle
                quotationParty.guid = nomineee.guid
                quotationParty.firstname = nomineee.firstName1
                quotationParty.lastname = nomineee.lastName1
                quotationParty.partyTypeCd = nomineee.partyTypeCd           
                quotationParty.age = nomineee.age
                quotationParty.genderCd = nomineee.genderCd
                quotationParty.smoker = nomineee.smoker
                quotationParty.nsap = nomineee.nsap  
                if nomineee.PartyEmploymentList[0]
                    quotationParty.occupationCd = nomineee.PartyEmploymentList[0].occupationClass
                end
                if nomineee.getPartyContact("MOBILE")
                    quotationParty.contactNum = nomineee.getPartyContact("MOBILE").contactNum
                end
                if nomineee.getPartyEmail
                    quotationParty.emailAddress = nomineee.getPartyEmail.emailAddress
                end
                quotationParty.dob = nomineee.birthDt
                quotationParty.roleCd = "NOMINEE"
                quotationParty.relationCd = nomineee.relationCd
                quotationParty.citizenshipCd=nomineee.citizenshipCd
                quotationParty.nationality=nomineee.citizenshipCd
                quotationParty.maritalStatus = nomineee.maritalStatusCd
                quotationParty.quotPartyAddtnField1 = nomineee.quotPartyAddtnField1
                quotationParty.quotPartyAddtnField2 = nomineee.quotPartyAddtnField2
                quotationParty.quotPartyAddtnField3 = nomineee.quotPartyAddtnField3
                quotationParty.quotPartyAddtnField4 = nomineee.quotPartyAddtnField4
                quotation.addQuotationParty(quotationParty)
            end

            policy.PolicyTopUpList.each do|topUp|
                quotationTopUp = QuotationTopUp.new
                quotationTopUp.topupFrequencyValUnit = topUp.topupFrequencyValUnit
                quotationTopUp.policyYearFrom = topUp.policyYearFrom
                quotationTopUp.policyYearTo = topUp.policyYearTo
                quotationTopUp.topUpTypeCd = topUp.topUpTypeCd
                quotationTopUp.topUpAmount = topUp.topUpAmount
                quotationTopUp.topupFrequencyVal = topUp.topupFrequencyVal
                quotationTopUp.guid = topUp.guid
                quotation.addQuotationTopUp(quotationTopUp)
            end
            quotation.QuotationPartyList.each do |quotationParty|
              if quotationParty.visitedTabs.to_s == ""
                quotationParty.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationParty.roleCd)
              end
            end
            quotation.QuotationProductList.each do|quotationProduct|
              if  quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs  = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
              end
            end
            return quotation       
        end
    	##################################################################################################


    	def self.getBirthdayDashboard()
      		policiesDashboard = Array.new
      		# total
      		sql = ""
      		sql << "Select q.firstname as firstname, q.dob as dob from policy q limit 3"      
      		policies = Policy.find_by_sql(sql)

      		policies.each do |policy|
      			policiesHM = Hash.new
      			policiesHM['LEAD'] = policy.firstname.to_s
      			policiesHM['BIRTHDAY'] = Date.parse(policy.dob).strftime('%m/%d/%Y')
      			policiesDashboard.push(policiesHM)
      		end
      		return policiesDashboard
      	end
    	##################################################################################################


    	def self.getDashboard()
      		policiesDashboard = Array.new
      		# total      
      		policies = Policy.loadObject(:all)

      		policiesHM = Hash.new
      		policiesHM['ILLUSTRATIONS'] = "Total"
      		policiesHM['COUNT'] = policies.size.to_s
      		policiesDashboard.push(policiesHM)

      		# draft
      		policies = Policy.loadObject(  
      			:all,
      			:conditions => {
      				{ :name => 'quoteStatusCd', :op => 'LIKE' } => MobiSys::PolicyBO::PENDING
      			}
  			)
      		policiesHM = Hash.new
      		policiesHM['ILLUSTRATIONS'] = "Draft"
      		policiesHM['COUNT'] = policies.size.to_s
      		policiesDashboard.push(policiesHM)

      		# awaiting conversion
      		policies = Policy.loadObject(  
      			:all, 
      			:conditions => {
      				{ :name => 'quoteStatusCd', :op => 'LIKE' } => '%SYNC%',
      				{ :name => 'signature', :op => 'IS' } => nil,
      				},
      				:op => 'AND'
      				)

      		policiesHM = Hash.new
      		policiesHM['ILLUSTRATIONS'] = "Awaiting Conversion"
      		policiesHM['COUNT'] = policies.size.to_s
      		policiesDashboard.push(policiesHM)

      		# Converted
      		policies = Policy.loadObject(  
      			:all,
      			:conditions => {
      				{ :name => 'quoteStatusCd', :op => 'LIKE' } => '%SYNC%',
      				{ :name => 'signature', :op => 'IS NOT' } => nil,
      				},
      				:op => 'AND'
      				)

      		policiesHM = Hash.new
      		policiesHM['ILLUSTRATIONS'] = "Converted"
      		policiesHM['COUNT'] = policies.size.to_s
      		policiesDashboard.push(policiesHM)

      		return policiesDashboard
      	end
		##################################################################################################


		def self.getDBDateTemp(screenDate)
			if screenDate.to_s != "" && screenDate.is_a?(String)
				dateParts = screenDate.split(/[\-\/ ]/)
				if dateParts[2].length < 3
					screenDate = Time.new(dateParts[0].to_i,dateParts[1].to_i,dateParts[2].to_i)
				else
					screenDate = Time.new(dateParts[2].to_i,dateParts[1].to_i,dateParts[0].to_i)    
				end
			elsif screenDate.to_s != "" && screenDate.is_a?(Integer)
				screenDate = Time.at(screenDate)                  
			end
      		#Swati Ahire 12-06-2014: screen date is neither String nor Integer. Hence nothing is evaluated and nil is returned. Added return for screen date
      		return screenDate
  		end
        ##################################################################################################
        

        def self.underwritePolicy(policy, policyQuestion, policyDocument)
            uwDecision = "ISSUED"
            
            baseProduct = getBaseProduct(policy)
            paProduct = getPAProduct(policy)
            riders = getRiders(policy)
            insured = policy.getParty("PRIMARY")
            proposer = policy.getParty("PROPOSER")
            
            # form questionnaire map
            questions = Hash.new
            
            policyQuestion.PolicyOfflineServiceList.each do |serviceQuestion|
                if serviceQuestion != nil
                    questions[serviceQuestion.dataElementCd] = serviceQuestion.response
                end
            end
          
            # check yes / no questions
            questions.each do |question, response|
                if response == "YES"
                    uwDecision = "REFERTOMANUALUW"
                end
            end
          
            # check medicals
            quotation = Quotation.new
            
            quotation.age = insured.age
            quotation.genderCd = insured.genderCd
            quotation.occupationCd = insured.occupationClass
            
            quotationProduct = QuotationProduct.new    
            quotationProduct.productId = "COMPANY"
            quotationProduct.planCode = baseProduct.planCode
            quotationProduct.baseSumAssured = baseProduct.baseSumAssured

            medicalsDT = MobiSys::ProductBO.getProductDefinitionTable("MEDICALS", quotation, quotationProduct)
          
            if medicalsDT != nil && medicalsDT.documentCategoryCd != nil && medicalsDT.documentCategoryCd != ""
                medicals = DocumentCategoryMap.find(
                    :all, 
                    :conditions => {
                        { :name => 'docCategoryCd' } => medicalsDT.documentCategoryCd
                    }
                )
                medicals.each do |medicalDocument|
                    uwDecision = "MEDICALSPENDING"
                    
                    serviceDocument = getServiceDocument(policyDocument, "MEDICAL", medicalDocument.categoryCd, medicalDocument.documentCd)
                    if serviceDocument == nil
                        serviceDocument = ServiceDocument.new
                        serviceDocument.referenceObject = policyDocument.referenceObject
                        serviceDocument.docCategoryTypeCd = "MEDICAL"
                        serviceDocument.docCategoryCd = medicalDocument.categoryCd
                        serviceDocument.documentCd = medicalDocument.documentCd
                        policyDocument.addServiceDocument(serviceDocument)
                    end          
                end
            end
            return uwDecision
        end 
        ##################################################################################################
        

        def self.computeProductExtra(policy,policyProduct)
            policyProductExtraArray = []
            productExtraTypes = Lookupvalue.loadObject(:all, :conditions=>{{:name=>'key'}=>'PRODUCTEXTRATYPE'})

            productDO = policyProduct.product
            if(productDO == nil && policyProduct.productSeq != nil)
                productDO = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
            end
            if (productDO != nil)
                if productExtraTypes != nil
                    productExtraTypes.each do |productExtraType|
                        facetId = productExtraType.cd
                        if facetId != "PRDDISCOUNT"
                            prdFacet = productDO.getFacet(facetId)
                            if prdFacet
                                offlinePolicyProdExtraList = policyProduct.getPolicyProductExtra(facetId)
                                if offlinePolicyProdExtraList == nil
                                    offlinePolicyProdExtraList = PolicyProductExtra.new
                                    policyProduct.addPolicyProductExtra(offlinePolicyProdExtraList)
                                else
                                    offlinePolicyProdExtraList = offlinePolicyProdExtraList
                                end
                                offlinePolicyProdExtraList.extraTypeCd = facetId 
                                tableTypeMappingSeq = productDO.getTableTypeMappingSeq(facetId)
                                
                                quotation = convertToQuotation(policy)
                                quotationProduct = quotation.QuotationProductList.select{|qp| qp.guid == policyProduct.guid}[0]
                                
                                definitionTable = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, quotationProduct, nil, false, false) if tableTypeMappingSeq
                                if(definitionTable != nil)
                                    offlinePolicyProdExtraList.decisionCd = definitionTable.loadingDecisionCd if definitionTable.loadingDecisionCd && definitionTable.loadingDecisionCd != ""
                                    offlinePolicyProdExtraList.extraFlatAmt = definitionTable.flatLoadingAmt if definitionTable.flatLoadingAmt && definitionTable.flatLoadingAmt != ""
                                    offlinePolicyProdExtraList.extraPercent = definitionTable.loadingPercent if definitionTable.loadingPercent && definitionTable.loadingPercent != ""
                                    offlinePolicyProdExtraList.loadingTypeCd = definitionTable.loadingTypeCd if definitionTable.loadingTypeCd && definitionTable.loadingTypeCd != ""
                                    offlinePolicyProdExtraList.processingTypeCd = definitionTable.processingTypeCd if definitionTable.processingTypeCd
                                    if(!(offlinePolicyProdExtraList.extraTypeCd.include? "TEMPLOADING"))
                                        offlinePolicyProdExtraList.extraFlatDuration = quotationProduct.premiumPayingTerm
                                        offlinePolicyProdExtraList.extraPercDuration = quotationProduct.premiumPayingTerm
                                    end
                                else
                                    offlinePolicyProdExtraList.decisionCd = "STANDARD" 
                                    offlinePolicyProdExtraList.extraFlatDuration = ""
                                    offlinePolicyProdExtraList.extraPercDuration = ""
                                    offlinePolicyProdExtraList.extraFlatAmt = ""
                                    offlinePolicyProdExtraList.extraPercent = ""
                                end
                                policyProductExtraArray.push(offlinePolicyProdExtraList)
                            end
                        end
                    end
                end
            end
            return policyProductExtraArray, policyProduct
        end

        def self.preValidateAllEappTabs(policy)
            policy.PolicyPaymentList.each do |policyPayment|
                if policyPayment.paymentInstructionTypeCd == "RENEWALPREMIUM"
                    @renewalPayment = policyPayment
                elsif policyPayment.paymentInstructionTypeCd == "REFUND"
                    @refundPayment = policyPayment
                end
            end
            policy.PartyList.each do |party|
                if @renewalPayment && party.guid == @renewalPayment.payerPartyRefGuid
                    party.PartyFinancialAccountList.each do |partyFinancialAccount|
                        if partyFinancialAccount.guid == @renewalPayment.partyFinAccRefGuid
                            partyFinancialAccount.paymentMethodCd = @renewalPayment.paymentMethodCd
                            partyFinancialAccount.paymentInstructionTypeCd = @renewalPayment.paymentInstructionTypeCd
                        end
                    end
                end
                if @refundPayment && party.guid == @refundPayment.payerPartyRefGuid
                    party.PartyFinancialAccountList.each do |partyFinancialAccount|
                        if partyFinancialAccount.guid == @refundPayment.partyFinAccRefGuid
                            partyFinancialAccount.paymentMethodCd = @refundPayment.paymentMethodCd
                            partyFinancialAccount.paymentInstructionTypeCd = @refundPayment.paymentInstructionTypeCd
                        end
                    end
                end
            end
        end


        def self.convertToPolicy(quotation, copyInsured = false)
            # if quotation != nil
                policy = Policy.new
                policy.guid = quotation.guid
                policy.quotationRefGuid = quotation.uniqueKey
                policy.bankStaffReferralCd = quotation.bankStaffReferralCd
                policy.quotationRefNum = quotation.quotationRefNum
                policy.leadId = quotation.leadId
                policy.fnaId = quotation.fnaId
                policy.rpqId = quotation.rpqId
                policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
                policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
                policy.isBackdatedFl = quotation.isBackdatedFl
                policy.quotationDt = quotation.quotationDt
                policy.insuranceTypeCd = quotation.insuranceTypeCd
                policy.tripTypeCd = quotation.tripTypeCd
                policy.maxTripPeriod = quotation.maxTripPeriod
                policy.travelGeographyCd = quotation.travelGeographyCd
                policy.visitPurposeCd = quotation.visitPurposeCd
                policy.numberOfAdult = quotation.numberOfAdult
                policy.numberOfChildren = quotation.numberOfChildren
                policy.startDt = quotation.startDt
                policy.endDt = quotation.endDt
                policy.coverTypeCd = quotation.coverTypeCd
                policy.autoRegistrationNum = quotation.autoRegistrationNum
                policy.autoMakeCd = quotation.autoMakeCd
                policy.autoModelCd = quotation.autoModelCd
                policy.questionContainer = quotation.questionContainer
                policy.action = quotation.action
                policy.proposerLASame = quotation.proposerLASame
                policy.uploadFlag = quotation.uploadFlag

                if quotation.isBackdatedFl.to_s == "YES"
                    policy.policyCommencementDt = quotation.quotationDt
                else
                    policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                if quotation.isBackdatedFl.to_s == "YES"
                    policy.riskCommencementDt = quotation.quotationDt
                else
                    policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
                end

                policy.baseAgentId = $userId
                policy.intimationSourceCd = "ESUBMISSION"
                policy.uwDecisionCd = "PENDING"
                policy.statusCd = "PENDING"

                convertIllustrationToEappPlanDetails(quotation, policy)
                
                policyHolder = Party.new(:roleCd => "PROPOSER")
                policy.addParty(policyHolder)
                convertIllustrationToEappParty(quotation, policyHolder, "PROPOSER")
                policyPartyRoleProposer = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => policyHolder.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleProposer)

                if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.getPartyByRole('PRIMARY').partySameAsCd.to_s == 'PROPOSER') && !copyInsured
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => "PROPOSER")
                    policy.addPolicyPartyRole(policyPartyRoleInsured)
                    policy.insuredSameAsProposer = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => policyHolder.guid, :issueAge => policyHolder.age)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                else
                    insured = Party.new(:roleCd => "PRIMARY")
                    policy.addParty(insured)
                    convertIllustrationToEappParty(quotation, insured, "PRIMARY")
                    policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => insured.uniqueKey, :partySameAsCd => "")
                    policy.addPolicyPartyRole(policyPartyRoleInsured)
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => insured.guid, :issueAge => insured.age)
                            policyProduct.addPolicyProductInsured(primaryProductInsured)
                        end
                    end
                end

                if quotation.getPartyByRole("JOINT") && quotation.getPartyByRole("JOINT").removed.to_s != "YES"
                    jointLife = Party.new(:roleCd => "JOINT")
                    policy.addParty(jointLife)
                    convertIllustrationToEappParty(quotation, jointLife, "JOINT")
                    policyPartyRoleJointLife = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => jointLife.uniqueKey)
                    policy.addPolicyPartyRole(policyPartyRoleJointLife)
                    policy.jointLife = 'YES'
                    policy.PolicyProductList.each do |policyProduct|
                        if policyProduct.productTypeCd == 'PLAN'
                            jointProductInsured = PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => jointLife.guid)
                            policyProduct.addPolicyProductInsured(jointProductInsured)
                        end
                    end
                end
                
                product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq) if policy.baseProductSeq.to_s != ""
                familyFloaterFl = product.getFacetValue('FAMILYINSUREDDETAILS').to_s == 'YES' if product
                quotation.getPartyListByRoleCd("SUPPLEMENTARY").each_with_index do |oldParty, index|
                    if oldParty.partySameAsCd == 'PROPOSER' && quotation.insuranceTypeCd == 'AUTO'
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => 'PROPOSER')
                        policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                    else
                        suppLife = Party.new(:roleCd => "SUPPLEMENTARY")
                        policy.addParty(suppLife)
                        convertIllustrationToEappParty(quotation, suppLife, "SUPPLEMENTARY", index)
                        policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => suppLife.uniqueKey)
                        policy.addPolicyPartyRole(policyPartyRoleSuppLife)
                        if familyFloaterFl
                            policy.PolicyProductList.each do |policyProduct|
                                if policyProduct.productTypeCd == 'PLAN'
                                    supProductInsured = PolicyProductInsured.new(:roleCd => "SUPPLEMENTARY", :insuredSequenceTypeCd => "SUPPLEMENTARY", :insuredPartyRefGuid => suppLife.guid)
                                    policyProduct.addPolicyProductInsured(supProductInsured)
                                    break
                                end
                            end 
                        end
                    end
                end
                policyAdditional = PolicyAdditionalFields.new
                policyAdditional.field20 = quotation.additionalField
                policy.addPolicyAdditionalFields(policyAdditional)
                policy.PartyList.each do |party|
                  if  party.visitedTabs.to_s == ""
                    party.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",party.roleCd)
                  end
                end
                policy.PolicyProductList.each do|policyProduct|
                  if policyProduct.visitedTabs.to_s == ""
                    policyProduct.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("POLICY",policyProduct.productTypeCd)
                  end
                end

                #copy lead party identity,contact,address into policy
    			if(quotation.leadId != nil)
    				lead = Lead.loadObject(:first, :conditions => {:leadId => quotation.leadId})
    				partyRefGuid = lead.partyRefGuid
    				if(partyRefGuid.to_s != "")
    					quoteParty = quotation.getPartyByRole("PROPOSER")
    					leadParty = Party.loadObject(:first, :conditions => {:guid => partyRefGuid})
    					if(leadParty != nil)
    						proposerParty = policy.getParty("PROPOSER")
    						proposerParty.citizenshipCd = leadParty.citizenshipCd
    						proposerParty.otherCitizenship = leadParty.otherCitizenship
    						proposerParty.religionCd = leadParty.religionCd
    						proposerParty.raceCd = leadParty.raceCd
    						proposerParty.nonResidentFl = leadParty.nonResidentFl
    						proposerParty.placeOfBirth = leadParty.placeOfBirth
    						proposerParty.countryOfBirth = leadParty.countryOfBirth
    						proposerParty.copyFromAddr3 = leadParty.copyFromAddr3
    						proposerParty.copyFromAddr2 = leadParty.copyFromAddr2
    						if(leadParty.PartyIdentityList.size > 0)
    							leadParty.PartyIdentityList.each do |leadPartyIdentity|
    								if(leadPartyIdentity.identityNum != nil && quoteParty.idNumber.to_s == leadPartyIdentity.identityNum.to_s &&
	    								   leadPartyIdentity.identityTypeCd != nil && quoteParty.idType.to_s == leadPartyIdentity.identityTypeCd.to_s)
	    								next
    								end

    								partyIdentity = PartyIdentity.new
    								MobiSys::CommonUtil.copyFields(leadPartyIdentity, partyIdentity)
    								proposerParty.addPartyIdentity(partyIdentity)
    							end
    						end
    						if(leadParty.PartyAddressList.size > 0)
    							leadParty.PartyAddressList.each do |leadPartyAddressDO|
    								partyAddress = PartyAddress.new
    								MobiSys::CommonUtil.copyFields(leadPartyAddressDO, partyAddress)
    								proposerParty.addPartyAddress(partyAddress)
    							end
    						end
    						if(leadParty.PartyContactList.size > 0)
    							leadParty.PartyContactList.each do |leadPartyContact|
    								if(leadPartyContact.contactTypeCd.to_s == "MOBILE" && quoteParty.contactNum.to_s != "")
    									next
    								end
    								partyContact = PartyContact.new
    								MobiSys::CommonUtil.copyFields(leadPartyContact, partyContact)
    								proposerParty.addPartyContact(partyContact)
    							end
    						end
    						if(leadParty.PartyOtherIncomeList.size > 0)
    							leadParty.PartyOtherIncomeList .each do |leadPartyOtherIncome|
    								partyOtherIncome = PartyOtherIncome.new
    								MobiSys::CommonUtil.copyFields(leadPartyOtherIncome, partyOtherIncome)
    								proposerParty.addPartyOtherIncome(partyOtherIncome)
    							end
    						end
    						#added party email related field
    						if(leadParty.PartyEmailList.size > 0 && quoteParty.emailAddress.to_s == "")
							    leadPartyEmail = leadParty.getPartyEmail("PERSONAL")
							    if(leadPartyEmail != nil) 
		    						partyEmail = PartyEmail.new
		    						MobiSys::CommonUtil.copyFields(leadPartyEmail, partyEmail)
		    						proposerParty.addPartyEmail(partyEmail)
							    end
							end
							#added party employment related field
    						if(leadParty.PartyEmploymentList.size > 0)
							    leadPartyEmployment = leadParty.PartyEmploymentList[0]
							    if(leadPartyEmployment != nil) 
		    						partyEmployment = PartyEmployment.new
		    						MobiSys::CommonUtil.copyFields(leadPartyEmployment, partyEmployment)
		    						proposerParty.addPartyEmployment(partyEmployment)
							    end
							end
							#added PartyAdditionalFields related field
    						if(leadParty.PartyAdditionalFieldsList.size > 0)
							    leadPartyAdditionalFields = leadParty.PartyAdditionalFieldsList[0]
							    if(leadPartyAdditionalFields != nil) 
		    						partyAdditionalFields = PartyAdditionalFields.new
		    						MobiSys::CommonUtil.copyFields(leadPartyAdditionalFields, partyAdditionalFields)
		    						proposerParty.addPartyAdditionalFields(partyAdditionalFields)
							    end
							end
    					end
    				end
    			end

                # policy.persistAll
                
                # @product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
                return policy
            # end
        end

        ##################################################################################################

        #Method to duplicate Quotation Plan data to Policy Plan data
        def self.convertIllustrationToEappPlanDetails(quotation, policy)
            insured = quotation.getPartyByRole('PRIMARY')
            proposer = quotation.getPartyByRole('PROPOSER')
            policy.quotAddtnlField1 = quotation.quotAddtnlField1
            policy.quotAddtnlField2 = quotation.quotAddtnlField2
            policy.quotAddtnlField3 = quotation.quotAddtnlField3
            policy.quotAddtnlField4 = quotation.quotAddtnlField4
            policy.quotAddtnlField5 = quotation.quotAddtnlField5
            policy.quotAddtnlField6 = quotation.quotAddtnlField6
            policy.quotAddtnlField7 = quotation.quotAddtnlField7
            policy.quotAddtnlField8 = quotation.quotAddtnlField8
            policy.quotAddtnlField9 = quotation.quotAddtnlField9
            policy.quotAddtnlField10 = quotation.quotAddtnlField10
            policy.quotAddtnlField11 = quotation.quotAddtnlField11
            policy.quotAddtnlField12 = quotation.quotAddtnlField12
            
            policy.initialTopupFl = quotation.initialTopupFl
            policy.regularTopupFl = quotation.regularTopupFl
            policy.topupOptionCd = quotation.topupOptionCd
            
            if quotation.proposerLASame == "COPYFROMINSURED"
                unselectedRiders = quotation.unselectedRiders.to_s
                unselectedRiders = unselectedRiders.gsub(insured.guid,proposer.guid)
                policy.unselectedRiders = unselectedRiders
            else
                policy.unselectedRiders = quotation.unselectedRiders
            end
            
            quotation.QuotationProductList.each do |quotationProduct|
                if quotationProduct.productTypeCd == 'PLAN'
                    policy.baseProductId = quotationProduct.productId
                    policy.baseProductSeq = quotationProduct.productSeq
                    policy.baseProductFamilyCd = quotationProduct.productFamilyCd
                    policy.productPlanOptionCd = quotationProduct.productPlanOptionCd
                end
                policyProduct = PolicyProduct.new
                policyProduct.guid = quotationProduct.guid
                policyProduct.productTypeCd = quotationProduct.productTypeCd
                policyProduct.productId = quotationProduct.productId
                policyProduct.productSeq = quotationProduct.productSeq
                policyProduct.productPlanOptionCd = quotationProduct.productPlanOptionCd
                policyProduct.parentproductSeq = quotationProduct.parentproductSeq
                policyProduct.productTypeCd  = quotationProduct.productTypeCd
                policyProduct.productFamilyCd = quotationProduct.productFamilyCd
                policyProduct.currencyCd = quotationProduct.currencyCd
                policyProduct.baseSumAssured = quotationProduct.baseSumAssured
                policyProduct.baseAnnualPremium = quotationProduct.baseAnnualPremium
                policyProduct.annualizedPremium = quotationProduct.annualizedPremium 
                policyProduct.totAnnualizedPremium = quotationProduct.totAnnualizedPremium
                policyProduct.vestingAge = quotationProduct.vestingAge
                policyProduct.annuityPerc = quotationProduct.annuityPerc
                policyProduct.modalPremium = quotationProduct.modalPremium
                policyProduct.extraPremium = quotationProduct.extraPremium
                policyProduct.productTerm = quotationProduct.productTerm
                policyProduct.premiumPayingTerm = quotationProduct.premiumPayingTerm
                policyProduct.paymentTypeCd = quotationProduct.paymentTypeCd
                policyProduct.paymentFrequencyCd = quotationProduct.paymentFrequencyCd
                policyProduct.planCode = quotationProduct.planCode
                policyProduct.portfolioModelCd = quotationProduct.portfolioModelCd
                policyProduct.capturedPremiumAmt = quotationProduct.capturedPremiumAmt
                policyProduct.maxTargetPremium = quotationProduct.maxTargetPremium
                policyProduct.minTargetPremium = quotationProduct.minTargetPremium
                policyProduct.recommendedPremium = quotationProduct.recommendedPremium
                policyProduct.unapliedPremium = quotationProduct.unapliedPremium
                policyProduct.combinedEntryAge = quotationProduct.combinedEntryAge
                policyProduct.coi = quotationProduct.coi
                policyProduct.addtnField1 = quotationProduct.addtnField1
                policyProduct.addtnField2 = quotationProduct.addtnField2
                policyProduct.addtnField3 = quotationProduct.addtnField3
                policyProduct.addtnField4 = quotationProduct.addtnField4
                policyProduct.addtnField5 = quotationProduct.addtnField5
                policyProduct.addtnField6 = quotationProduct.addtnField6
                policyProduct.builtInRiderFl = quotationProduct.builtInRiderFl
                policyProduct.productVersion = quotationProduct.productVersion
                policyProduct.selected = quotationProduct.selected
                policyProduct.wopPremium = quotationProduct.wopPremium
                policyProduct.wopPremium2 = quotationProduct.wopPremium2
                policyProduct.wopPremiumQuarterly = quotationProduct.wopPremiumQuarterly
                policyProduct.wopPremiumHalfYearly = quotationProduct.wopPremiumHalfYearly
                policyProduct.wopPremiumMonthly = quotationProduct.wopPremiumMonthly
                policyProduct.wopPremium2Quarterly = quotationProduct.wopPremium2Quarterly
                policyProduct.wopPremium2HalfYearly = quotationProduct.wopPremium2HalfYearly
                policyProduct.wopPremium2Monthly = quotationProduct.wopPremium2Monthly
                policyProduct.wopPremium3 = quotationProduct.wopPremium3
                policyProduct.wopPremium3Quarterly = quotationProduct.wopPremium3Quarterly
                policyProduct.wopPremium3HalfYearly = quotationProduct.wopPremium3HalfYearly
                policyProduct.wopPremium3Monthly = quotationProduct.wopPremium3Monthly
                policyProduct.wopPremiumField = quotationProduct.wopPremiumField
                policyProduct.wopPremiumField2 = quotationProduct.wopPremiumField2
                policyProduct.wopPremiumField3 = quotationProduct.wopPremiumField3
                policyProduct.ropPerc = quotationProduct.ropPerc
                policyProduct.fixedPrmIndexationVal = quotationProduct.fixedPrmIndexationVal
                policyProduct.pdfRequiredFl = quotationProduct.pdfRequiredFl
                policyProduct.pdfFrequencyVal = quotationProduct.pdfFrequencyVal
                policyProduct.pdfPeriod = quotationProduct.pdfPeriod
                policyProduct.paidUpFl = quotationProduct.paidUpFl
                policyProduct.topUpTypeCd = quotationProduct.topUpTypeCd
                policyProduct.annuityAge = quotationProduct.annuityAge
                policyProduct.payingYears = quotationProduct.payingYears
                policyProduct.compAnnualPremium = quotationProduct.compAnnualPremium
                policyProduct.compHalfYlyPremium = quotationProduct.compHalfYlyPremium
                policyProduct.compQtlyPremium = quotationProduct.compQtlyPremium
                policyProduct.compMonthlyPremium = quotationProduct.compMonthlyPremium
                policyProduct.targetFundVal = quotationProduct.targetFundVal
                policyProduct.targetPeriod = quotationProduct.targetPeriod
                policyProduct.payoutFrequencyCd = quotationProduct.payoutFrequencyCd
                policyProduct.productLongName = quotationProduct.productLongName
                policyProduct.sortOrder = quotationProduct.sortOrder

                if (quotation.proposerLASame.to_s == 'YES' || quotation.proposerLASame.to_s == 'COPYFROMINSURED') && quotationProduct.partyRoleCd.to_s == 'PRIMARY'
                    policyProduct.insuredPartyRefGuid = proposer.guid
                else
                    policyProduct.insuredPartyRefGuid = quotationProduct.insuredPartyRefGuid
                end
                policyProduct.partyRoleCd = quotationProduct.partyRoleCd
                policy.addPolicyProduct(policyProduct)

                if quotationProduct.productTypeCd != 'PLAN'
                    policyProductInsured = PolicyProductInsured.new
                    policyProduct.addPolicyProductInsured(policyProductInsured)
                    policyProductInsured.roleCd = policyProduct.partyRoleCd
                    policyProductInsured.insuredPartyRefGuid = policyProduct.insuredPartyRefGuid
                    policyProductInsured.refGuid = policyProduct.insuredPartyRefGuid
                end

                quotationProduct.QuotationProductAdditionalList.each do |qpAdditional|
                    @policyProductAdditional = PolicyProductAdditional.new
                    policyProduct.addPolicyProductAdditional(@policyProductAdditional)
                    @policyProductAdditional.prdAddtnField1str = qpAdditional.prdAddtnField1str
                    @policyProductAdditional.prdAddtnField2str = qpAdditional.prdAddtnField2str
                    @policyProductAdditional.prdAddtnField3str = qpAdditional.prdAddtnField3str
                    @policyProductAdditional.prdAddtnField4str = qpAdditional.prdAddtnField4str
                    @policyProductAdditional.prdAddtnField5str = qpAdditional.prdAddtnField5str
                    @policyProductAdditional.prdAddtnField6d = qpAdditional.prdAddtnField6d
                    @policyProductAdditional.prdAddtnField7d = qpAdditional.prdAddtnField7d
                    @policyProductAdditional.prdAddtnField8d = qpAdditional.prdAddtnField8d
                    @policyProductAdditional.prdAddtnField9d = qpAdditional.prdAddtnField9d
                    @policyProductAdditional.prdAddtnField10d = qpAdditional.prdAddtnField10d
                    @policyProductAdditional.prdAddtnField11d = qpAdditional.prdAddtnField11d
                    @policyProductAdditional.prdAddtnField12d = qpAdditional.prdAddtnField12d
                    @policyProductAdditional.prdAddtnField13d = qpAdditional.prdAddtnField13d
                    @policyProductAdditional.prdAddtnField14d = qpAdditional.prdAddtnField14d
                    @policyProductAdditional.prdAddtnField15d = qpAdditional.prdAddtnField15d
                    @policyProductAdditional.prdAddtnField16dt = qpAdditional.prdAddtnField16dt
                    @policyProductAdditional.prdAddtnField17dt = qpAdditional.prdAddtnField17dt
                    @policyProductAdditional.prdAddtnField18dt = qpAdditional.prdAddtnField18dt
                    @policyProductAdditional.prdAddtnField19dt = qpAdditional.prdAddtnField19dt
                    @policyProductAdditional.prdAddtnField20dt = qpAdditional.prdAddtnField20dt
                end

                quotationProduct.QuotationProductExtraList.each do |quotationProductExtra|
                    policyProductExtra = PolicyProductExtra.new
                    policyProduct.addPolicyProductExtra(policyProductExtra)
                    policyProductExtra.extraTypeCd = quotationProductExtra.extraTypeCd
                    policyProductExtra.decisionCd = quotationProductExtra.decisionCd
                    policyProductExtra.loadingTypeCd = quotationProductExtra.loadingTypeCd
                    policyProductExtra.processingTypeCd = quotationProductExtra.processingTypeCd
                    policyProductExtra.extraFlatAmt = quotationProductExtra.extraFlatAmt
                    policyProductExtra.extraPercent = quotationProductExtra.extraPercent
                    policyProductExtra.extraFlatDuration = quotationProductExtra.extraFlatDuration
                    policyProductExtra.extraPercDuration = quotationProductExtra.extraPercDuration
                end
                
                quotationProduct.QuotationProductInvestmentFundList.each do |quotationFund|
                    policyProductInvestmentFund = PolicyProductInvestmentFund.new
                    policyProduct.addPolicyProductInvestmentFund(policyProductInvestmentFund)
                    policyProductInvestmentFund.fundCd = quotationFund.fundCd
                    policyProductInvestmentFund.allocationPerc = quotationFund.allocationPerc
                    policyProductInvestmentFund.topupAllocationPerc = quotationFund.topupAllocationPerc
                    policyProductInvestmentFund.expiryDt = quotationFund.expiryDt
                    policyProductInvestmentFund.fundTypeCd = quotationFund.fundTypeCd
                    policyProductInvestmentFund.maturityDt = quotationFund.maturityDt
                    policyProductInvestmentFund.sortOrder = quotationFund.sortOrder
                end
            end

            quotation.QuotationTopUpList.each do |topUp|
                if topUp.topUpTypeCd == 'REGULARTOPUP'
                    regularTopUp = PolicyTopUp.new(:topUpTypeCd =>'REGULARTOPUP')
                    policy.addPolicyTopUp(regularTopUp)
                    regularTopUp.topUpAmount = topUp.topUpAmount
                    regularTopUp.topupFrequencyVal = topUp.topupFrequencyVal
                elsif topUp.topUpTypeCd == 'INITIALINVESTMENT'
                    initialTopup = PolicyTopUp.new(:topUpTypeCd =>'INITIALINVESTMENT')
                    policy.addPolicyTopUp(initialTopup)
                    initialTopup.topUpAmount = topUp.topUpAmount
                end     
            end
            policyWithdrawalList = []
            quotation.QuotationWithdrawalList.each do |withdrawal|
              policyWithdrawalList.push(withdrawal)
            end
            policy.policyWithdrawalList = policyWithdrawalList

        end


        ##################################################################################################

        #Method to duplicate QuotationParty object data to policy Party object
        def self.convertIllustrationToEappParty(quotation, newParty, roleCd, supplementaryCount = -1)
            if roleCd == "PROPOSER"
                lead = Lead.loadObject(
                    :first, 
                    :conditions => {
                        { :name => 'leadId' } => quotation.leadId
                    }
                )
            end
            if supplementaryCount > -1 && roleCd == "SUPPLEMENTARY"
                oldParty = quotation.getPartyListByRoleCd(roleCd)[supplementaryCount]
            else
                oldParty = quotation.getPartyByRole(roleCd)
            end
            if oldParty
                oldParty.partyTypeCd = 'INDIVIDUAL' if oldParty.roleCd != "PROPOSER"
                newParty.guid = oldParty.guid
                newParty.quotationPartyGuid = oldParty.guid
                newParty.partyTypeCd = oldParty.partyTypeCd
                newParty.questionContainer = oldParty.questionContainer
                if oldParty.partyTypeCd == 'INDIVIDUAL'
                    newParty.titleCd = oldParty.title
                    newParty.otherTitle = oldParty.otherTitle
                    newParty.firstName1 = oldParty.firstname
                    newParty.middleName1 = oldParty.middlename
                    newParty.lastName1 = oldParty.lastname
                    newParty.extensionName1 = oldParty.extensionName
                    newParty.firstName2 = oldParty.firstname2
                    newParty.middleName2 = oldParty.middlename2
                    newParty.lastName2 = oldParty.lastname2
                    newParty.extensionName2 = oldParty.extensionName2
                    newParty.genderCd = oldParty.genderCd
                    newParty.relationCd = oldParty.relationCd
                    newParty.otherRelation = oldParty.otherRelation
                    newParty.smoker = oldParty.smoker
                    newParty.nsap = oldParty.nsap
                    newParty.coverageCountryCd = oldParty.coverageCountryCd
                    newParty.coverageCityCd = oldParty.coverageCityCd
                    newParty.maritalStatusCd = oldParty.maritalStatus
                    newParty.birthDt = oldParty.dob
                    newParty.age = oldParty.age
                    newParty.monthlyIncome = oldParty.monthlyIncome
                    newParty.annualIncome = oldParty.annualIncome
                    newParty.quotPartyAddtnField1 = oldParty.quotPartyAddtnField1
                    newParty.quotPartyAddtnField2 = oldParty.quotPartyAddtnField2
                    newParty.quotPartyAddtnField3 = oldParty.quotPartyAddtnField3
                    newParty.quotPartyAddtnField4 = oldParty.quotPartyAddtnField4
                    newParty.citizenshipCd = oldParty.nationality
                                
                    partyEmployment = newParty.getPartyEmployment(true)
                    partyEmployment.industryCd = oldParty.industryCd
                    partyEmployment.natureOfDuty = oldParty.natureOfDuty
                    #partyEmployment.occupationClass = oldParty.occupationCd
                    partyEmployment.occupationCd = oldParty.occupationCd
                    
                    partyAddress = newParty.getPartyAddress("RESIDENTIAL", true)
                    partyAddress.addressLine1Lang1 = oldParty.addressLine1Lang1
                    partyAddress.addressLine2Lang1 = oldParty.addressLine2Lang1
                    partyAddress.addressLine3Lang1 = oldParty.addressLine3Lang1
                    partyAddress.addressLine4Lang1 = oldParty.addressLine4
                    partyAddress.countryCd = oldParty.countryCd
                    partyAddress.pinCode = oldParty.pinCode
                    partyAddress.districtCd = oldParty.stateCd
                    partyAddress.cityCd = oldParty.cityCd
                    
                    partyContact1 = newParty.getPartyContact("MOBILE", true)
                    partyContact1.countryCd = oldParty.countryCd
                    partyContact1.stdCode = oldParty.stdCode
                    partyContact1.contactNum = oldParty.contactNum

                    partyEmail = newParty.getPartyEmail(true)
                    partyEmail.emailAddress = oldParty.emailAddress

                    if oldParty.idNumber.to_s != "" && oldParty.idType.to_s != ""
                      newPartyIdentity = PartyIdentity.new
                      newPartyIdentity.identityNum = oldParty.idNumber
                      newPartyIdentity.identityTypeCd = oldParty.idType
                      newParty.addPartyIdentity(newPartyIdentity)
                    end

                    if lead
                        #Copy Lead Party Details
                        leadParty = lead.getLeadParty
                        if leadParty
                          #Nationality Details
                          newParty.countryOfBirth = leadParty.countryOfBirth
                          newParty.nonResidentFl = leadParty.nonResidentFl
                          newParty.raceCd = leadParty.raceCd
                          newParty.religionCd = leadParty.religionCd
                          #Party Identity Details
                          if leadParty.PartyIdentityList.size > 0
                            leadParty.PartyIdentityList.each do |partyIdentity|
                              next if partyIdentity.identityTypeCd.to_s == oldParty.idType.to_s
                              newPartyIdentity = PartyIdentity.new
                              newPartyIdentity.identityNum = partyIdentity.identityNum
                              newPartyIdentity.expiryDt = partyIdentity.expiryDt
                              newPartyIdentity.issueDt = partyIdentity.issueDt
                              newPartyIdentity.identityTypeCd = partyIdentity.identityTypeCd
                              newPartyIdentity.issuingAuthority = partyIdentity.issuingAuthority
                              newParty.addPartyIdentity(newPartyIdentity)
                              newPartyIdentity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newPartyIdentity)
                            end
                          end

                          #Party Other Income Details
                          if leadParty.getPartyOtherIncomeList.size > 0
                            leadParty.getPartyOtherIncomeList.each do |otherIncome|
                              newOtherIncome = PartyOtherIncome.new
                              newOtherIncome.incomeTypeCd = otherIncome.incomeTypeCd
                              newOtherIncome.sourceOfIncome = otherIncome.sourceOfIncome
                              newOtherIncome.incomeAmount = otherIncome.incomeAmount
                              newOtherIncome.otherSourceIncome = otherIncome.otherSourceIncome
                              newOtherIncome.currencyCd = otherIncome.currencyCd
                              newOtherIncome.incomeYear = otherIncome.incomeYear
                              newParty.addPartyOtherIncome(newOtherIncome)
                              newOtherIncome.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(newOtherIncome)
                            end
                          end

                          #Residential and Office Contact Details
                          if leadParty.getPartyContact("OFFICE")
                            leadOfficeContact = leadParty.getPartyContact("OFFICE")
                            partyContact2 = newParty.getPartyContact("OFFICE",true)
                            partyContact2.countryCd = leadOfficeContact.countryCd
                            partyContact2.stdCode = leadOfficeContact.stdCode
                            partyContact2.contactNum = leadOfficeContact.contactNum
                            partyContact2.extensionNum = leadOfficeContact.extensionNum
                            partyContact2.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact2)
                          end

                          if leadParty.getPartyContact("RESIDENTIAL")
                            leadHomeContact = leadParty.getPartyContact("RESIDENTIAL")
                            partyContact3 = newParty.getPartyContact("RESIDENTIAL",true)
                            partyContact3.countryCd = leadHomeContact.countryCd
                            partyContact3.stdCode = leadHomeContact.stdCode
                            partyContact3.contactNum = leadHomeContact.contactNum
                            partyContact3.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact3)
                          end
                        end
                    end 

                    partyEmployment.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmployment)
                    partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    partyContact1.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact1)
                    partyEmail.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmail)
                elsif oldParty.partyTypeCd == 'ORGANIZATION'
                    newParty.corporateName1 = oldParty.corporateName
                    newParty.quotPartyAddtnField1 = oldParty.quotPartyAddtnField1
                    newParty.quotPartyAddtnField2 = oldParty.quotPartyAddtnField2
                    newParty.quotPartyAddtnField3 = oldParty.quotPartyAddtnField3
                    newParty.quotPartyAddtnField4 = oldParty.quotPartyAddtnField4
                    
                    partyIdentity = newParty.getPartyIdentityList(true)[0]
                    partyIdentity.identityNum = oldParty.businessTIN
                    
                    partyAddress = newParty.getPartyAddress("OFFICE", true)
                    partyAddress.addressLine1Lang1 = oldParty.addressLine1Lang1
                    partyAddress.addressLine2Lang1 = oldParty.addressLine2Lang1
                    partyAddress.addressLine3Lang1 = oldParty.addressLine3Lang1
                    partyAddress.addressLine4Lang1 = oldParty.addressLine4
                    partyAddress.countryCd = oldParty.countryCd
                    partyAddress.pinCode = oldParty.pinCode
                    partyAddress.districtCd = oldParty.stateCd
                    partyAddress.cityCd = oldParty.cityCd
                        
                    partyContact = newParty.getPartyContact("OFFICE", true)
                    partyContact.countryCd = oldParty.isdCode
                    partyContact.stdCode = oldParty.stdCode
                    partyContact.contactNum = oldParty.contactNum

                    partyEmail = newParty.getPartyEmail(true)
                    partyEmail.emailAddress = oldParty.emailAddress
                    
                    partyIdentity.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyIdentity)
                    partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
                    partyContact.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyContact)
                    partyEmail.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyEmail)
                end
            end
        end

        ##################################################################################################

        #Method to duplicate Additional Quotation object data to policy object data
        # Deepali Singh: This method is generally to be overridden at company to copy any additional fields from SI to EAPP
        def self.convertIllustrationToEappAdditionalDetails(quotation, policy)
            
        end

        def self.validateCompanyFacet(policy,errors)
            policyProduct = policy.getBaseProduct
            if $rhoconfig[:addtnlEAPPCompanyModelSet] != nil && $rhoconfig[:addtnlEAPPCompanyModelSet].actionValue.to_s != ""
                policyModelSet = PolicyUtil::PolicyModelSet.new
                party = policy.getParty('PRIMARY')
                policy.additionalData = {}
                policyModelSet.execute(policy, policyProduct, party, $rhoconfig[:addtnlEAPPCompanyModelSet].actionValue)
            end
        end

        # Method to copy policy values to existing quotation
        def self.copyToQuotation(policy, quotation)
            quotation.quotAddtnlField1 = policy.quotAddtnlField1
            quotation.quotAddtnlField2 = policy.quotAddtnlField2
            quotation.quotAddtnlField3 = policy.quotAddtnlField3
            quotation.quotAddtnlField4 = policy.quotAddtnlField4
            quotation.quotAddtnlField5 = policy.quotAddtnlField5
            quotation.quotAddtnlField6 = policy.quotAddtnlField6
            quotation.quotAddtnlField7 = policy.quotAddtnlField7
            quotation.quotAddtnlField8 = policy.quotAddtnlField8
            quotation.quotAddtnlField9 = policy.quotAddtnlField9
            quotation.quotAddtnlField10 = policy.quotAddtnlField10
            # copy all products values from policy to quotation           
            policy.PolicyProductList.each do |policyProduct|
                quotation.QuotationProductList.each do |quotationProduct|
                    if policyProduct.guid == quotationProduct.guid 
                        quotationProduct.product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
                        quotationProduct.productId = policyProduct.productId
                        quotationProduct.productVersion = policyProduct.productVersion
                        quotationProduct.productSeq = policyProduct.productSeq
                        quotationProduct.parentproductSeq = policyProduct.parentproductSeq
                        quotationProduct.productTypeCd = policyProduct.productTypeCd 
                        quotationProduct.productFamilyCd = policyProduct.productFamilyCd 
                        quotationProduct.baseSumAssured = policyProduct.baseSumAssured
                        quotationProduct.baseAnnualPremium = policyProduct.baseAnnualPremium 
                        quotationProduct.modalPremium = policyProduct.modalPremium
                        quotationProduct.capturedPremiumAmt = policyProduct.capturedPremiumAmt 
                        quotationProduct.productTerm = policyProduct.productTerm 
                        quotationProduct.premiumPayingTerm = policyProduct.premiumPayingTerm 
                        quotationProduct.annualizedPremium = policyProduct.annualizedPremium 
                        quotationProduct.totAnnualizedPremium = policyProduct.totAnnualizedPremium
                        quotationProduct.vestingAge = policyProduct.vestingAge
                        quotationProduct.annuityPerc = policyProduct.annuityPerc
                        quotationProduct.extraPremium = policyProduct.extraPremium
                        quotationProduct.maxTargetPremium = policyProduct.maxTargetPremium
                        quotationProduct.minTargetPremium = policyProduct.minTargetPremium
                        quotationProduct.recommendedPremium = policyProduct.recommendedPremium
                        quotationProduct.unapliedPremium = policyProduct.unapliedPremium
                        quotationProduct.linkedFl = policyProduct.linkedFl
                        quotationProduct.pdfRequiredFl = policyProduct.pdfRequiredFl
                        quotationProduct.topUpAllocSameAsPremAllocFl = policyProduct.topUpAllocSameAsPremAllocFl
                        quotationProduct.targetFundFl = policyProduct.targetFundFl
                        quotationProduct.builtInRiderFl = policyProduct.builtInRiderFl
                        quotationProduct.guid = policyProduct.guid
                        quotationProduct.premiumSAFl = policyProduct.premiumSAFl
                        quotationProduct.pdfFrequencyVal = policyProduct.pdfFrequencyVal
                        quotationProduct.pdfPeriod = policyProduct.pdfPeriod
                        quotationProduct.payoutFrequencyCd = policyProduct.payoutFrequencyCd
                        # every time get copied From Base Plan
                        quotationProduct.paymentFrequencyCd = policyProduct.paymentFrequencyCd
                        quotationProduct.currencyCd = policyProduct.currencyCd
                        quotationProduct.paymentTypeCd = policyProduct.paymentTypeCd
                        quotationProduct.minTargetPremium = policyProduct.minTargetPremium

                        quotationProduct.productPlanOptionCd = policyProduct.productPlanOptionCd 
                        quotationProduct.planCode = policyProduct.planCode 
                        quotationProduct.productSeq = policyProduct.productSeq
                        quotationProduct.coi = policyProduct.coi 

                        quotationProduct.combinedEntryAge = policyProduct.combinedEntryAge
                        quotationProduct.portfolioModelCd = policyProduct.portfolioModelCd
                        quotationProduct.holderRefGuid = policyProduct.object
                        quotationProduct.selected = policyProduct.selected

                        quotationProduct.addtnField1 = policyProduct.addtnField1 
                        quotationProduct.addtnField2 = policyProduct.addtnField2 
                        quotationProduct.addtnField3 = policyProduct.addtnField3 
                        quotationProduct.addtnField4 = policyProduct.addtnField4 
                        quotationProduct.addtnField5 = policyProduct.addtnField5 
                        quotationProduct.addtnField6 = policyProduct.addtnField6 
                        # Extra Loading And Duration 
                        quotationProduct.flatExtra = policyProduct.flatExtra

                        quotationProduct.wopPremium = policyProduct.wopPremium
                        quotationProduct.wopPremium2 = policyProduct.wopPremium2
                        quotationProduct.wopPremiumQuarterly = policyProduct.wopPremiumQuarterly
                        quotationProduct.wopPremiumHalfYearly = policyProduct.wopPremiumHalfYearly
                        quotationProduct.wopPremiumMonthly = policyProduct.wopPremiumMonthly
                        quotationProduct.wopPremium2Quarterly = policyProduct.wopPremium2Quarterly
                        quotationProduct.wopPremium2HalfYearly = policyProduct.wopPremium2HalfYearly
                        quotationProduct.wopPremium2Monthly = policyProduct.wopPremium2Monthly
                        quotationProduct.wopPremium3 = policyProduct.wopPremium3
                        quotationProduct.wopPremium3Quarterly = policyProduct.wopPremium3Quarterly
                        quotationProduct.wopPremium3HalfYearly = policyProduct.wopPremium3HalfYearly
                        quotationProduct.wopPremium3Monthly = policyProduct.wopPremium3Monthly
                        quotationProduct.wopPremiumField = policyProduct.wopPremiumField
                        quotationProduct.wopPremiumField2 = policyProduct.wopPremiumField2
                        quotationProduct.wopPremiumField3 = policyProduct.wopPremiumField3
                        quotationProduct.paidUpFl = policyProduct.paidUpFl

                        quotationProduct.compAnnualPremium = policyProduct.compAnnualPremium
                        quotationProduct.compHalfYlyPremium = policyProduct.compHalfYlyPremium
                        quotationProduct.compQtlyPremium = policyProduct.compQtlyPremium
                        quotationProduct.compMonthlyPremium = policyProduct.compMonthlyPremium

                        quotationProduct.sortOrder = policyProduct.sortOrder

                        policyProduct.PolicyProductInsuredList.each do|policyProductInsured|
                            if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.proposerLASame == "YES") && policyProductInsured.roleCd.to_s == 'PRIMARY'
                                    quotationProduct.insuredPartyRefGuid = quotation.getPartyByRole('PRIMARY').guid
                            else 
                                quotationProduct.insuredPartyRefGuid = policyProductInsured.insuredPartyRefGuid
                            end
                            quotationProduct.partyRoleCd = policyProductInsured.roleCd
                        end
                    end
                end
            end    
 
            return quotation       
        end

        def self.checkNomineeEffectiveDate(policy, errors)
          isValid = true
          nomineeList = policy.getPolicyPartyRoleList("NOMINEE")
          if nomineeList.size > 0
            nomineeList.each do |nominee|
              if nominee.effectiveFromDt.to_s != "" && nominee.effectiveToDt.to_s != ""
                nomineeEffectiveToDt = Time.parse(nominee.effectiveToDt)
                nomineeEffectiveFromDt = Time.parse(nominee.effectiveFromDt)
                if nomineeEffectiveToDt < nomineeEffectiveFromDt
                  party = nominee
                  party = policy.getPartyByGuid(nominee.refGuid) if(nominee.partySameAsCd.to_s == "OTHER" and nominee.refGuid.to_s != "")
                  MobiSys::CommonUtil.addErrors(errors, "effectiveFromDt", "ERR_DATE2AFTER", [MobiSys::BrowserHelper.getLabel("effectiveFromDt"), MobiSys::BrowserHelper.getLabel("effectiveToDt"), nomineeEffectiveFromDt.strftime("%d/%m/%Y"), nomineeEffectiveToDt.strftime("%d/%m/%Y")])
                  MobiSys::CommonUtil.registerException(policy.guid, "#{party.guid}-effectiveToDt", "ERR_DATE2AFTER", "ERR_DATE2AFTER", nil, [MobiSys::BrowserHelper.getLabel("effectiveFromDt"), MobiSys::BrowserHelper.getLabel("effectiveToDt"), nomineeEffectiveFromDt.strftime("%d/%m/%Y"), nomineeEffectiveToDt.strftime("%d/%m/%Y")])
                  isValid = false
                end
              end
            end
          end
          return isValid
        end

    end
end

begin 
    require 'Policy/policy_b_o_company'
rescue LoadError => e
    puts 'policy_b_o_company not included'
end
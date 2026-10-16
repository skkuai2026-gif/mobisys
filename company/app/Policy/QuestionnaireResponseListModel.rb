require 'CommonClasses/BaseModel'

module MobiSys
	class QuestionnaireResponseListModel < BaseModel
		attr_accessor :questionnaireTypeCd
		def initialize(io)
            # logInfo "~~~in QuestionnaireResponseListModel initialize: #{io.inspect}"
            super(io)
            #logInfo "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			# logInfo("~~~baseIO in QuestionnaireResponseListModel:#{self.baseIO.baseDO.inspect}")
            # logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO}")
            
            $currentPolicy = nil
            self.parentBaseDO = self.baseIO.baseDO if !self.parentBaseDO
            policy = self.parentBaseDO
            $currentPolicy = policy
            $currentProduct ||= MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
            partyQuestionRespContainer = nil
            #check if model is initialized and do not load the questions if it is
            if self.questionnaireTypeCd.to_s == "AGENT"
            	$currentDTCache = {}
				partyQuestionRespContainer = PolicyPartyContainer.new
				#if the model is initialized for merging purpose then no need to fetch and transform all data.. since we are going to delete all and insert all data
				return partyQuestionRespContainer if self.initForMerge
				
				questionnaireTypeList = []
				partyQuestionRespContainer.status = ""
				partyQuestionRespContainer.questionSets = MobiSys::PolicyService.getApplicableQuestionnaireResponse(nil,questionnaireTypeList,@baseIO)				
            elsif self.questionnaireTypeCd.to_s == "INSUREDPARTY"
            	partyQuestionRespContainer = [PolicyPartyContainer.new]
            	#if the model is initialized for merging purpose then no need to fetch and transform all data.. since we are going to delete all and insert all data
            	return partyQuestionRespContainer if self.initForMerge

            	partyQuestionRespContainer = []
            	partyNames = self.parentBaseDO.getPartyNames("tab_questionnaire")

            	partyNames.each do |party|
            		$currentDTCache = {}
            		partyGuid = party[0]
            		questionnaireTypeList = []
            		policyParty = self.parentBaseDO.getPartyByGuid(partyGuid)
            		policyProductInsuredObj = (policyParty != nil ? PolicyProductInsured.loadObject(:first, :loadChild => false, :conditions=>{{:name=>'insuredPartyRefGuid'}=>policyParty.guid,{:name=>'roleCd'} => policyParty.roleCd},:op => 'AND') : nil)

            		policyPartyRole = self.parentBaseDO.getPolicyPartyRoleByPartyGuid(partyGuid,"PRIMARY")
            		#if party has primary insured role then add insured related question sets
            		questionnaireTypeList.push({"INSUREDPARTY" => []}) if policyPartyRole != nil
            		policyPartyRole = self.parentBaseDO.getPolicyPartyRoleByPartyGuid(partyGuid,"PROPOSER")
            		questionnaireTypeList.push({"PROPOSERPARTY" => []}) if policyPartyRole != nil
            		
					if policyProductInsuredObj != nil
						#If Party is insured on some product then add insured related questionsets; this is applicable for Supplementary/Proposer insured on rider
						questionnaireTypeList.push({"INSUREDPARTY" => []}) if questionnaireTypeList.select{|m| m if m.keys.include?("INSUREDPARTY")}.size == 0
					end

            		policyPartyRole = self.parentBaseDO.getPolicyPartyRoleByPartyGuid(partyGuid,"PAYER")
            		questionnaireTypeList.push({"PAYERPARTY" => []}) if policyPartyRole != nil
					policyPartyContainer = PolicyPartyContainer.new
					policyPartyContainer.status = ""
					policyPartyContainer.partyGuid = partyGuid
					partyInfo = party[1].split("-")
					partyName = partyInfo[1].strip.split(" ")
					policyPartyContainer.partyName = (partyName.size > 0 ? (partyName.size > 1 ? partyName[1].to_s+" "+partyName[0].to_s : partyName[0].to_s) : "")
					policyPartyContainer.partyRole = partyInfo[0]
					policyPartyContainer.questionSets = MobiSys::PolicyService.getApplicableQuestionnaireResponse(partyGuid,questionnaireTypeList,@baseIO)
					partyQuestionRespContainer.push(policyPartyContainer)
            	end
			end
			
			return partyQuestionRespContainer
		end


		def setModel(entity)
			if entity != nil
				if self.questionnaireTypeCd.to_s == "AGENT"
					listServiceQuestionResponseUI = []
					return entity if entity.questionSets == nil

					entity.questionSets.each do |questionSetResponse|
						MobiSys::PolicyService.createServiceQuestionSetResponse(entity.partyGuid,questionSetResponse,listServiceQuestionResponseUI,@baseIO,self.questionnaireTypeCd.to_s)
					end

					agentQuestContainer = QuestionContainer.loadObject(
				            :first, 
				            :conditions=>{
				                {:name=>'entityGuid'} => @baseIO.baseDO.uniqueKey,
				                {:name=>'policyGuid'} => @baseIO.baseDO.uniqueKey,
				                {:name=>'entityTypeCd'} => 'AGENT'
				            },
				            :op => 'AND'
				        ) || 
				        QuestionContainer.new(
				            :entityGuid => @baseIO.baseDO.uniqueKey,
				            :entityTypeCd => 'AGENT',
				            :policyGuid => @baseIO.baseDO.uniqueKey
				        )

					 if listServiceQuestionResponseUI.size > 0
						# ServiceQuestionResponse.delete_all(:conditions => {'parentKey'=>agentQuestContainer.object }) if agentQuestContainer != nil
						agentQuestContainer.ServiceQuestionResponseList.each do |previousResponse|
							previousResponse.removed = "YES"
						end
						agentQuestContainer.persistAll
						#Add current response to ServiceResponse
						newAgentQuestContainer = QuestionContainer.loadObject(
					            :first, 
					            :conditions=>{
					                {:name=>'entityGuid'} => @baseIO.baseDO.uniqueKey,
					                {:name=>'policyGuid'} => @baseIO.baseDO.uniqueKey,
					                {:name=>'entityTypeCd'} => 'AGENT'
					            },
					            :op => 'AND'
					        )
						newAgentQuestContainer.addServiceQuestionResponseList(listServiceQuestionResponseUI)
						newAgentQuestContainer.persistAll
					end

				elsif self.questionnaireTypeCd.to_s == "INSUREDPARTY"
					entity.each do |partyContainer|
						listServiceQuestionResponseUI = []
						partyContainer.questionSets.each do |questionSetResponse|
							MobiSys::PolicyService.createServiceQuestionSetResponse(partyContainer.partyGuid,questionSetResponse,listServiceQuestionResponseUI,@baseIO,self.questionnaireTypeCd.to_s)

							if listServiceQuestionResponseUI.size > 0
								party = @baseIO.baseDO.getPartyByGuid(partyContainer.partyGuid)
									#remove existing service question response list
									questContainer = QuestionContainer.loadObject(
										:first,
										:conditions=>{
											{:name=>'entityGuid'} => partyContainer.partyGuid,
											{:name=>'policyGuid'} => @baseIO.baseDO.uniqueKey
										},
										:op=>'AND'
										) || 
									QuestionContainer.new(
										:entityGuid => partyContainer.partyGuid,
										:entityTypeCd => party.roleCd,
										:policyGuid => @baseIO.baseDO.uniqueKey
										)

									# ServiceQuestionResponse.delete_all(
									# 	:conditions => {
									# 		{:name=>'parentkey'} => questContainer.object
									# 	}) if questContainer != nil
									questContainer.ServiceQuestionResponseList.each do |previousResponse|
										previousResponse.removed = "YES"
									end
									questContainer.persistAll
									#Add current response to ServiceResponse
									newQuestContainer = QuestionContainer.loadObject(
										:first,
										:conditions=>{
											{:name=>'entityGuid'} => partyContainer.partyGuid,
											{:name=>'policyGuid'} => @baseIO.baseDO.uniqueKey
										},
										:op=>'AND'
										)
									
									newQuestContainer.addServiceQuestionResponseList(listServiceQuestionResponseUI)
									newQuestContainer.persistAll
							end
						end
					end

				end
			end

			return entity
		end

	end
	
end

begin 
    require 'Policy/QuestionnaireResponseListModel_company'
rescue LoadError => e
    puts 'QuestionnaireResponseListModel_company not included'
end
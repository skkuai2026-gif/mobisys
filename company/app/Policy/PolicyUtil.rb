require 'json'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/schema_module.rb'
require 'CommonModules/entityschema'
require 'CommonClasses/FieldResult'
require 'Policy/policy_b_o'
require 'ostruct'

class Hash
	def get(key)
		self[key]
	end
end

module PolicyUtil
	class ApplicationUtil
		#Method to call online services during Policy Submit & Payment Gateway
		def self.invokeOnlineService(entitiesToBeSynced, methodName, showMessages)
			begin
				clazz = Class.new do
					include MobiSys::BrowserHelper
				end
				obj = clazz.new
				offlineEntitiesHash = Hash.new
				inputHash = Hash.new
				entitiesToBeSynced.each do |onlineClassName, offlineEntity|
					if offlineEntity.class.name.to_s == "Array"
						className = offlineEntity[0].class.name.to_s
					else
						className = offlineEntity.class.name.to_s
					end
					currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
					unless currentEntityTypeHash
						offlineEntitiesHash[onlineClassName] = Hash.new
						currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
					end
					if offlineEntity.class.name.to_s == "Array"
						offlineEntity.each do |oe|
							currentEntityTypeHash[oe.class.name.to_s+oe.guid.to_s] = oe
						end
					else
						currentEntityTypeHash[offlineEntity.class.name.to_s+offlineEntity.guid.to_s] = offlineEntity
					end
				end
				#Offline entities Hash is complete. Now prepare the input Hash
				otherDetailsHM = {}
				entityCounter = 0
				offlineEntitiesHash.each{|key,value|
					# hashArray = Array.new
					hashArray = createJsonForOnline(value,inputHash,otherDetailsHM,entityCounter)
					begin
						inputHash[key] = ::JSON.generate(hashArray)
					rescue StandardError => se
						puts "Error while generating entities from hash =>" + se.to_s
					end
				}
				# log(inputHash.to_s)
				begin
					json = ::JSON.generate(inputHash)
				rescue StandardError => se
					puts "Error while generating JSON of request data =>" + se.to_s
				end
				response = obj.doJSONPost(methodName, json)
				if response.to_s != ''
					resultsHash = Rho::JSON.parse(response)
				else
					resultsHash = {}
				end
				resultsHash.each do |key,value|
					# log "Key: " + key.to_s
					# log "Value: " + value.to_s
					if value.to_s != ""
						entities = Rho::JSON.parse(value)
					else
						entities = []
					end
					# log "Received #{entities.length} of type #{key.to_s}"
					offlineEntities = offlineEntitiesHash[key]
					count = 0
					if offlineEntities
						db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
						db.start_transaction
						entities.each do |entity|
							if entity["class"].to_s != "" 
								className = entity["class"].slice((entity["class"].rindex('.')+1)..(entity["class"].rindex('DO')-1))
							else
								className = key.slice((key.rindex('.')+1)..(key.rindex('DO')-1))
							end
							if entity.has_key?("listPolicyResultList")
								entity["listPolicyResultDOList"] = entity["listPolicyResultList"]
							end
							offlineEntity = offlineEntities[className+entity['guid']]
							unless offlineEntity
								if className == "ServiceDocument"
									documentContainer = DocumentContainer.loadObject(
			                            :first,
			                            :conditions=>{
			                                {:name=>'entityGuid'}=> entity["partyGuid"]
			                            },
			                            :loadChild => 'false'
			                        )
			                        if documentContainer
			                        	entity["parentKey"] = documentContainer.object
			                        end
								end
							end
							onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
							if onlineEntity.versionID == -1 and offlineEntity
								offlineEntity.destroy
							elsif offlineEntity
								offlineEntity.merge(onlineEntity, true)
								offlineEntity.persist('fromSync')
								if offlineEntity.respond_to?('afterSync'.to_sym)
									offlineEntity.afterSync
								end
							else
								onlineEntity.persist
								if onlineEntity.respond_to?('afterSync'.to_sym)
									onlineEntity.afterSync
								end
							end
						end
						db.commit
					end
				end
				return resultsHash
			rescue MobiSys::AuthenticationError => se
				if showMessages
					Alert.show_popup({
						:title=>'',
						:message=>se.to_s,
						:buttons=>["Ok"],
						:callback=>'/app/SyncCategory/loginpopupcallback'
					})
				else
					# RhoLog.error("INVOKEONLINESERVICE",'Authentication error while syncing' + se.to_s)
					raise se
				end
			rescue MobiSys::JSONPostError => se
				if showMessages
					Alert.show_popup({
						:title=>'',
						:message=>se.to_s,
						:buttons=>["Ok"],
						:callback=>'/app/SyncCategory/loginpopupcallback'
					})
				else
					# RhoLog.error("INVOKEONLINESERVICE",'Authentication error while syncing' + se.to_s)
					raise se
				end
			rescue MobiSys::UpgradeApplicationError => ue
				if showMessages
					Alert.show_popup({
						:title=>'',
						:message=>ue.to_s,
						:buttons=>["Ok"],
						:callback=>'/app/SyncCategory/transactionpopupcallback'
					})
				else
					# RhoLog.error("INVOKEONLINESERVICE","Error during Sync.singleTransactions: "+ue.to_s)
					raise ue
				end
			rescue StandardError => se
				if showMessages
					# RhoLog.error("INVOKEONLINESERVICE","Error during Application Validation: "+se.to_s)
				else
					# RhoLog.error("INVOKEONLINESERVICE","Error during Sync.singleTransactions: "+se.to_s)
					raise se
				end
			end
		end
		##################################################################################################

		def self.createJsonForOnline(value,inputHash,otherDetailsHM,entityCounter)
			hashArray = Array.new
			value.each_value do |offlineEntity|
				if offlineEntity.class.name.to_s == "Array"
					offlineEntity.each do |oe|
						hashArray.push oe.hashForSync
					end
				else
					hashArray.push offlineEntity.hashForSync
				end
				if offlineEntity.class.name.to_s == "Quotation"
					if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
						fileName = "#{offlineEntity.class.name.to_s}_#{offlineEntity.quotationRefNum.to_s}_ACCEPT.json"
						filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
						if File.exist?(filePath)
							encryptedContent = File.read(filePath)
							jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
							jsonObjects = Rho::JSON.parse(jsonContent)
							htmlHash = {}
							htmlCount = jsonObjects["htmlCount"].to_i
							for i in 1..htmlCount
								htmlHash["html#{i}"] = jsonObjects["html#{i}"]
							end
							otherDetailsHM["html#{entityCounter+1}"] = htmlHash.to_json
							otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
							otherDetailsHM["entityName#{entityCounter+1}"] = offlineEntity.class.name.to_s
							otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.quotationRefNum.to_s
							otherDetailsHM["htmlCount#{entityCounter+1}"] = jsonObjects["htmlCount"]
							otherDetailsHM["accept#{entityCounter+1}"] = "ACCEPT"
							entityCounter += 1
						end
					end
				elsif offlineEntity.class.name.to_s == "Policy"
					t1 = Time.now

					fileName = "#{offlineEntity.class.name.to_s}_#{offlineEntity.proposalNum.to_s}_ACCEPT.json"
					filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
					if File.exist?(filePath)
						encryptedContent = File.read(filePath)
						jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
						jsonObjects = Rho::JSON.parse(jsonContent)
						htmlHash = {}
	                    htmlCount = 1
	                    htmlHash["html1"] = jsonObjects["html1"]

	                    otherDetailsHM["html#{entityCounter+1}"] = htmlHash.to_json
						otherDetailsHM["graphJSON#{entityCounter+1}"] =  jsonObjects["graphJSON"]
						otherDetailsHM["entityName#{entityCounter+1}"] = offlineEntity.class.name.to_s
						otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.proposalNum.to_s
						otherDetailsHM["htmlCount#{entityCounter+1}"] = "1"
						entityCounter += 1
					end
				end
			end
			inputHash["otherDetails"] = ::JSON.generate(otherDetailsHM) if !otherDetailsHM.empty?
			inputHash["counter"] = entityCounter.to_s if entityCounter > 0
			return hashArray
		end
	end


	class ModelUtil
		#Method to get IllustrationModel record based on modelCd
		def self.getIllustrationModel(modelCd)
			return IllustrationModel.loadObject(
				:first,
				:conditions => {
					:modelCd => modelCd
				}
			)
		end
		##################################################################################################


		#Method to get ModelSet & ModelSetModelMap hierarchy along with associated IllustrationModel based on modelSetCd
		def self.getModelSet(modelSetCd)
			modelSet = ModelSet.loadObject(
				:first,
				:conditions => {
					:modelSetCd => modelSetCd
				}
			)
			if modelSet
				modelSet.ModelSetModelMapList.each do |modelSetModelMap|
					modelSetModelMap.model = getIllustrationModel(modelSetModelMap.modelCd)
				end
			end
			return modelSet
		end
		##################################################################################################

		#Method to load in single db call and cache all the models in modelset
		def self.getModelSetAndModels(modelSetCd)
			modelHM = {}
			modelSet = ModelSet.loadObject(
				:first,
				:conditions => {
					:modelSetCd => modelSetCd
				}
			)
			
			if modelSet
				modelCdArr = modelSet.ModelSetModelMapList.collect{|modelSetModelMap| modelSetModelMap.modelCd}
				illustrationModelList = IllustrationModel.loadObject(
						:all,
						:conditions =>{
		                {
		                    :name => 'modelCd',
		                    :op => 'IN'
		                } => modelCdArr
		            }
				)
				illustrationModelList.each do |illusModel|
					modelHM[illusModel.modelCd] = illusModel
				end
			end
			return modelSet, modelHM
		end
		##################################################################################################


		def self.getExpressionReplacementList(modelFor)
			replaceInputElementsStatic = {}
			#function names
			replaceInputElementsStatic["&lt;"] = "<"
			replaceInputElementsStatic["&gt;"] = ">"
			replaceInputElementsStatic["&amp;&amp;"] = "&&"
			replaceInputElementsStatic["DateDifferenceInDays"] = "com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getDifferenceInDays"
			replaceInputElementsStatic["negativeSign"] = "com.c2lbiz.symbiosys.systemcommon.util.CommonUtil.getNegativeValue"
			replaceInputElementsStatic["YEAR_OF"] = "com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getCalendarYear"
		    replaceInputElementsStatic["MONTH_OF"] = "com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getCalendarMonth"
		    replaceInputElementsStatic["DAY_OF"] = "com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getCalendarDay"
			replaceInputElementsStatic["FormatDate"] = "com.c2lbiz.symbiosys.systemcommon.util.DateUtil.getString"

			#expression replacement for underwriting.
			replaceInputElementsUW = {}
			replaceInputElementsUW["com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party."] = ""
			replaceInputElementsUW["com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy."] = ""
			replaceInputElementsUW["PolicyBasePlanExtraDO"] = PolicyProduct.name.to_s

			#only for underwriting replacing expressions and compiling for now.. since these expressions are not modified at run time.
			if modelFor == "UNDERWRITING" || modelFor == "POLICY"
				replaceInputElementsStatic = replaceInputElementsStatic.merge(replaceInputElementsUW)
			end
			return replaceInputElementsStatic
		end
		##################################################################################################
	end


	class AutoUWUtil
		#Contants used throughout AutoUW process
		LOGCATEGORY					= "AutoUWUtil"
		MUW 						= "MUW"
		FUW 						= "FUW"
		PUW 						= "PUW"
		UWDECISION 					= "UWDECISION"

		#Contants used in the compiled expressions
		UW_TYPE 					= "uwType"
		POLPRODUCT_DO 				= PolicyProduct.name.to_s
		PARTY_DO 					= Party.name.to_s
		PARTYADDRESS_DO 			= PartyAddress.name.to_s
		PARTYIDENTITY_DO 			= PartyIdentity.name.to_s
		PARTYADDTNL_DO 				= PartyAdditionalFields.name.to_s
		POLICY_DO 					= Policy.name.to_s
		POLICYADDTNL_DO 			= PolicyAdditionalFields.name.to_s
		PRDINSURED_DO 				= PolicyProductInsured.name.to_s
		PARTYROLE_DO 				= PolicyPartyRole.name.to_s
		QUESTIONNAIRE_ELEMS 		= "PolicyQuestionSet"
		UWRISKRESULT_DO 			= "PolicyUWRiskResult"
		UW_DECISIONCOUNT 			= "uwDecisionCount"
		UW_DECISIONPRIORITY 		= "uwDecisionPriority"
		POLBASEPLAN_DO 				= "PolicyBasePlan"
		PROPOSERPARTY_DO			= "PolicyProposerDO"
		JOINTPARTY_DO				= "PolicyJointLifeDO"

		#Facet constants
		PRDINSUREDMEDICALROLLUP 	= "PRDINSUREDMEDICALROLLUP"
		PRDMEDICALROLLUP 			= "PRDMEDICALROLLUP"
		POLICYMEDICALUWROLLUP 		= "POLICYMEDICALUWROLLUP"
		PAYERFINROLLUP 				= "PAYERFINROLLUP"
		POLICYFINROLLUP 			= "POLICYFINROLLUP"
		POLICYOTHERADDNLROLLUP 		= "POLICYOTHERADDNLROLLUP"
		POLICYFINALOVERALLUWROLLUP 	= "POLICYFINALOVERALLUWROLLUP"
		POLICYWORKFLOWROLLUP 		= "POLICYWORKFLOWROLLUP"
		MEDICALAUTOUWRULE 			= "MEDICALAUTOUWRULE"
		FINANCIALAUTOUWRULE 		= "FINANCIALAUTOUWRULE"
		POLICYAUTOUWRULE 			= "POLICYAUTOUWRULE"
		COMPUTEDFORMULA 			= "COMPUTEDFORMULA"
		COMPUTEDDECISIONTBL 		= "COMPUTEDDECISIONTBL"
		DYNAMICDECISIONTBL 			= "DYNAMICDECISIONTBL"
		OUTPUTFRMDYNAMICDT 			= "OUTPUTFRMDYNAMICDT"
		UNDERWRITING 				= "UNDERWRITING"


		#Decision Constants
		ACCEPTED 					= "ACCEPTED"
		ACCEPTEDRATED 				= "ACCEPTEDRATED"
		DECLINED 					= "DECLINED"
		DEFFERED 					= "DEFFERED"
		REQUIREMENTPENDING 			= "REQUIREMENTPENDING"
		REFERTOMUW 					= "REFERTOMUW"
		POSTPONE 					= "POSTPONE"
		ADDITIONALREQUIREMENT 		= "ADDITIONALREQUIREMENT"
		PASS 						= "PASS"
		REFERTOUW 					= "REFERTOUW"
		BORDERACCEPTED 				= "BORDERACCEPTED"
		COUNTEROFFER 				= "COUNTEROFFER"


		def initialize
			#Variables used throughout AutoUW process
			@policy 						= nil
			@serviceDocumentList 			= []
			@productUWFacetModelSetMap 		= {}
			#create new hashmap of string,ModelDO for rollupFacetMap
			@rollupFacetMap 				= {}
			@tableTypeMappingIdVersionMap 	= {}
			@replaceInputElementsUW			= {}
			@startTime 						= Time.now.to_i
			@logInfo 						= ""
			@currentLog 					= ""
			@message 						= ""
			@output 						= ""
			@errored 						= false
			#this is a holder for current values being processed that needs to be set in the PolicyResultDO and passed to MVEL
			@currentProcessingValues 		= {}
			@uwDecisionPriority 			= {}
			@uwDecisionCount 				= {}
			@docCatgmap 					= {}
			@rollupBreakFacet 				= false
			@rollupBreakFacetId 			= ""
		end
		##################################################################################################


		#Main method to invoke the auto underwriting rule engine
		def execute(policy, serviceDocumentList)
			@policy = policy
			@serviceDocumentList = serviceDocumentList
			logInfo = @policy.proposalNum.to_s + ": "

			init

			#clear all the decisions in order to rollup
			@policy.uwDecisionCd 			= ""
			@policy.overallUWDecisionCd 	= ""
			@policy.insuredUWDecisionCd 	= ""
			@policy.financerUWDecisionCd 	= ""
			@policy.policyOtherUWDecisionCd = ""
			#nullify all the decisions of products as well
			@policy.PolicyProductList.each do |policyProductDO|
				policyProductDO.decisionCd = ""
				policyProductDO.PolicyProductInsuredList.each do |prdIns|
					prdIns.decisionCd = ""
				end
			end
			@policy.PolicyPartyRoleList.each do |policyPartyRoleDO|
				policyPartyRoleDO.decisionCd = ""
			end
			@policy.PolicyResultList.each do |policyResult|
				policyResult.destroy
			end
			@policy.setPolicyResultList([])

			Rho::Log.info(logInfo + "Time for init: #{Time.now.to_i - @startTime}", LOGCATEGORY)
			@startTime 	= Time.now.to_i
			medicalUW

			Rho::Log.info(logInfo + "Time for Medical UW: #{Time.now.to_i - @startTime}", LOGCATEGORY)
			@startTime 	= Time.now.to_i
			financialUW
			policyUW
			rollupHierarchy

			Rho::Log.info(logInfo + "Time for Financial + Policy UW: #{Time.now.to_i - @startTime}", LOGCATEGORY)
			@startTime 	= Time.now.to_i

			# puts "@currentProcessingValues-------#{@currentProcessingValues.to_json}"
			return serviceDocumentList
		end
		##################################################################################################


		#init Method similar to online code to call all initialization methods
		def init
			initializeEvaluationParams
			initializeRollupFacet
			initializeModelSet
		end
		##################################################################################################


		#Method to initialize decision priority and count
		def initializeEvaluationParams
			@replaceInputElementsUW = PolicyUtil::ModelUtil.getExpressionReplacementList(UNDERWRITING)
			#get all the decisions from lookup and initialize the priority in hashmap to be used for rolling up purpose.
			uwDecisionLkpList = Lookupvalue.getValue(UWDECISION)
			uwDecisionLkpList.each do |uwDecisionLkp|
				@uwDecisionPriority[uwDecisionLkp.cd] 	= uwDecisionLkp.sortOrder.to_s == "" ? 0 : uwDecisionLkp.sortOrder
				@uwDecisionCount[uwDecisionLkp.cd] 		= 0
			end

			@currentProcessingValues[POLICY_DO] 		= @policy
			@currentProcessingValues[POLICYADDTNL_DO] 	= @policy.PolicyAdditionalFieldsList[0]
			@currentProcessingValues[POLBASEPLAN_DO] 	= @policy.getBaseProduct
			@currentProcessingValues[PROPOSERPARTY_DO] 	= @policy.getParty('PROPOSER')
			@currentProcessingValues[JOINTPARTY_DO] 	= @policy.getParty('JOINT')
		end
		##################################################################################################


		#Method to initialize roll-up models
		def initializeRollupFacet
			rollupFacetIds = [PRDINSUREDMEDICALROLLUP, PRDMEDICALROLLUP, POLICYMEDICALUWROLLUP, PAYERFINROLLUP, POLICYFINROLLUP, POLICYOTHERADDNLROLLUP, POLICYFINALOVERALLUWROLLUP, POLICYWORKFLOWROLLUP]
			basePlanProduct = @policy.getBaseProduct
			unless basePlanProduct.product
				basePlanProduct.product = MobiSys::ProductUtil.getProduct(basePlanProduct.productSeq)
			end
			rollupFacetIds.each do |rollupFacetId|
				rollupModelFacet = ""
				uwRollupFacet = basePlanProduct.product.getFacetFast(rollupFacetId)
				if uwRollupFacet != nil
					if uwRollupFacet.actionTypeCd.to_s == "RULE"
						facetValue = uwRollupFacet.ruleSeq
						if facetValue.to_s != ""
							if $quotation
								quotation = $quotation
							else
								quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
							end
							baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
							primary = quotation.getMainInsured(baseProduct)
							dtd = MobiSys::ProductUtil.getProductDefinitionTableDO(facetValue, quotation, baseProduct, primary)
							if dtd != nil && dtd.outputAction.to_s != ""
								rollupModelFacet = dtd.outputAction
							end
						end
	              	elsif uwRollupFacet.actionValue.to_s != ""
						rollupModelFacet = uwRollupFacet.actionValue
	              	end
				else
					$companyFacetCache ||= CompanyFacet.loadObject(:all)
					$companyFacetCache.each do |obj|
						if obj.facetCd == rollupFacetId && obj.actionValue.to_s != ""
							rollupModelFacet = obj.actionValue
						end
					end
				end
				if rollupModelFacet.to_s != ""
					@rollupFacetMap[rollupFacetId] = PolicyUtil::ModelUtil.getIllustrationModel(rollupModelFacet)
				end
			end

			#the below 2 rollup models could be defined at a Rider level as well.. discovered later hence adding separately to the map along with rider id
			distinctRiderProductIds = []
			uwRiderRollupFacetIds = []
			uwRiderRollupFacetIds.push(PRDINSUREDMEDICALROLLUP)
			uwRiderRollupFacetIds.push(PRDMEDICALROLLUP)

			@policy.getPolicyProductByProductTypeCd("RIDER").each do |polProdRider|
				if !distinctRiderProductIds.include?(polProdRider.productId.to_s)
					uwRiderRollupFacetIds.each do |uwRiderFacetId|
						unless polProdRider.product
							polProdRider.product = MobiSys::ProductUtil.getProduct(polProdRider.productSeq)
						end
						rollupModelCd = ""
						uwFacet = polProdRider.product.getFacetFast(uwRiderFacetId)
						if uwFacet
							if uwFacet.actionTypeCd.to_s == "RULE"
								facetValue = uwFacet.ruleSeq
								if facetValue.to_s != ""
									if $quotation
										quotation = $quotation
									else
										quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
									end
									primary = quotation.getMainInsured(polProdRider)
									dtd = MobiSys::ProductUtil.getProductDefinitionTableDO(facetValue, quotation, polProdRider, primary)
									if dtd != nil && dtd.outputAction.to_s != ""
										rollupModelCd = dtd.outputAction
									end
								end
							else
								rollupModelCd = uwFacet.actionValue
							end
						end
						if rollupModelCd.to_s != ""
							@rollupFacetMap[polProdRider.productId.to_s+"-"+uwRiderFacetId] = PolicyUtil::ModelUtil.getIllustrationModel(rollupModelCd)
						end
					end
				end
				distinctRiderProductIds.push(polProdRider.productId.to_s)
			end
		end
		##################################################################################################


		#Method to initialize UW models based on modelset
		def initializeModelSet
			#here loop through all distinct products and 3 facets of MEDICALAUTOUWRULE,FINANCIALAUTOUWRULE, POLICYAUTOUWRULE
			#store these in productUWFacetModelSetMap as PRODUCTID-FACETID
			distinctProductIds = []
			uwFacetIds = []
			uwFacetIds.push(MEDICALAUTOUWRULE)
			#below 2 facets are only for base plan.
			uwFacetIds.push(FINANCIALAUTOUWRULE)
			uwFacetIds.push(POLICYAUTOUWRULE)

			@policy.PolicyProductList.each do |policyProduct|
				if !distinctProductIds.include?(policyProduct.productId.to_s)
					unless policyProduct.product
						policyProduct.product = MobiSys::ProductUtil.getProduct(policyProduct.productSeq)
					end
					uwFacetIds.each do |uwFacetId|
						modelSetCd = ""
						uwFacet = policyProduct.product.getFacetFast(uwFacetId)
						if uwFacet
							if uwFacet.actionTypeCd.to_s == "RULE"
								# if $quotation
								# 	quotation = $quotation
								# else
									quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
								# end
								baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
								primary = quotation.getMainInsured(baseProduct)
								defTable = MobiSys::ProductUtil.getProductDefinitionTableDO(uwFacet.ruleSeq, quotation, baseProduct, primary)
								if defTable
									modelSetCd = defTable.outputAction.to_s
								end
							else
								modelSetCd = uwFacet.actionValue.to_s
							end

							if modelSetCd.to_s != ""
								@productUWFacetModelSetMap[policyProduct.productId+"-"+uwFacetId] = PolicyUtil::ModelUtil.getModelSet(modelSetCd)
							end
						end
					end
				end
				distinctProductIds.push(policyProduct.productId.to_s)
			end
		end
		##################################################################################################


		#Method performs dynamic DT evaluation
		def evaluateDynamicDT(ruleName, objToEvaluate)
			matchedDT = nil
			begin
				ruleCalculator = MobiSys::RuleCalculator.new
				ruleCalculator.ruleName = ruleName
				ruleCalculator.facet = ruleName
				matchedDT = ruleCalculator.evaluateRule(objToEvaluate)
				Rho::Log.info("Dynamic DT->>#{ruleName}" + (matchedDT == nil ? " No matching record" : " Matching record found at: #{matchedDT.hmFieldValues}"), LOGCATEGORY)
			rescue Exception => e
				Rho::Log.error("Error during dynamic DT evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				#retain the first error
				if @message.to_s == ""
					@message = "Error evaluation Dynamic DT Rule: #{ruleName} #{e}"
					@output = "ERROR"
					@errored = true
				end
			end
			return matchedDT
		end
		##################################################################################################


		#Method performs fixed DT evaluation
		def evaluateFixedDT(illusFacetDO, tableTypeMappingSeq, objToEvaluate)
			evaluatedValue 			= nil
			policyProduct 			= @policy.getBaseProduct
			policyProductInsured 	= nil
			policyPayment 			= nil
			party 					= nil
			#initialize all the fixed elements that need to be passed to the DT
			if @policy.PolicyPaymentList.size > 0
				policyPayment = @policy.PolicyPaymentList[0]
			end

			if objToEvaluate.is_a?(PolicyProductInsured)
				policyProductInsured = objToEvaluate
				@policy.PolicyProductList.each do |policyProductObj|
					if policyProductObj.object == policyProductInsured.parentKey
						policyProduct = policyProductObj
						break
					end
				end

				if policyProductInsured.refGuid.to_s != ""
					party = @policy.getPartyByGuid(policyProductInsured.refGuid)
				end

				unless party
					party = @policy.getMainInsured(policyProduct)
				end
			elsif objToEvaluate.is_a?(Party)
				party = objToEvaluate
			end

			if policyProductInsured == nil && policyProduct.PolicyProductInsuredList.size > 0
				policyProductInsured = policyProduct.PolicyProductInsuredList[0]
			end

			if $quotation
				quotation = $quotation
			else
				quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
			end
			baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
			primary = quotation.getMainInsured(baseProduct)

			#check if some additional computed field needs to be passed to the decision table if so then set that in additional DO and pass to DT
			if illusFacetDO != nil && illusFacetDO.computedFieldNameForRule.to_s != ""
				valueToSet = @currentProcessingValues["#{illusFacetDO.computedElementName}"]
				#setting the computed value in field 12 .. generally
				quotation.quotAddtnlField12 = valueToSet.to_s if valueToSet.to_s != ""
				quotation.additionalField = valueToSet.to_s if valueToSet.to_s != ""
			end
			dt = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, baseProduct, primary)
			if dt
				if dt.rate.to_s != ""
					evaluatedValue = dt.rate
				elsif dt.outputAction.to_s != ""
					evaluatedValue = dt.outputAction
				end
			end
			return evaluatedValue
		end
		##################################################################################################


		#Method loops though all the elements in the Models in the set and evaluates
		def evaluateModelSet(modelSet, objToEvaluate)
			return unless modelSet

			Rho::Log.info("Model Set->> #{modelSet.modelSetCd}", LOGCATEGORY)
			if modelSet.ModelSetModelMapList.size == 0
				Rho::Log.info("No Models mapped to  Model Set->> #{modelSet.modelSetCd}", LOGCATEGORY)
			end

			modelSet.ModelSetModelMapList.each do |modelSetMap|
				begin
					evaluateModel = false
					if modelSetMap.ruleSeq.to_s != ""
						#here evaluate the fixed DT to check if the Model should be evaluated
						evaluatedValue = evaluateFixedDT(modelSetMap.ruleSeq, objToEvaluate)
						#if the DT evaluation results in YES then continue with further Model evaluation
						if evaluatedValue.to_s == "YES"
							evaluateModel = true
						end
					else
						evaluateModel = true
					end

					next unless evaluateModel

					modelDO = modelSetMap.model
					if modelDO
						#Check if the compute per instance of exists. if so then evaluate the model for every instance of the object
						if modelDO.computePerInstanceOf.to_s != ""
							Rho::Log.info("Compute per instance of->> #{modelDO.computePerInstanceOf}", LOGCATEGORY)
							#the lookup code contains the expression for getting the child arrayList
							#eg. the lookup code = PartyDO.getListPartyAddressDOList():PartyAddressDO
							#thus it needs to execute getListPartyAddressDOList on the current instance of PartyDO from hashmap
							compPerInst 	= modelDO.computePerInstanceOf.split(":")
							childExpression = compPerInst[0]
							childRetType 	= compPerInst[1]

							allChildInstancesObj = nil
							begin
								objectClass = childExpression.split(".")[0]
								if @currentProcessingValues.has_key?(objectClass)
									childExpression.gsub!("#{objectClass}.", "@currentProcessingValues[\"#{objectClass}\"].")
								end
								allChildInstancesObj = eval(childExpression)
							rescue Exception => e
								#Check if return type was supposed to be questions then do not set as errored since if grid questions do not exist then too it fails
								if !QUESTIONNAIRE_ELEMS == childRetType
									Rho::Log.error("Compute per instance of in not configured correctly. #{childExpression}, it should be a getter method.\n#{e}\n#{e.backtrace}", LOGCATEGORY)
									break
								end
							end
							if allChildInstancesObj != nil && allChildInstancesObj.is_a?(Array)
								#At times the list is the party do itself eg. for Nominee - PolicyDO.getNomineePartyList():PartyDO
								#hence holding the existing PartyDO in temporary variable and then setting it back after the compute per instace of is complete.
								currentProcessingPartyDO = @currentProcessingValues[PARTY_DO]
								numInstances = 0
								allChildInstancesObj.each do |childObj|
									numInstances += 1
									begin
										Rho::Log.info("Instance found->>#{childObj.class.name}", LOGCATEGORY)
										#the child object will be referred to in expression by the return type
										#example PartyAddressDO.countryCd and hence adding to hashmap the current child object
										#this will be replaced for each instance
										#but in case of questionnaire we cannot replace the entire PolicyQuestionSetDO since it contains other question set responses
										#that we do not want to overwrite other than the current QuestionSet grid.
										if QUESTIONNAIRE_ELEMS == childRetType
											existingQuestionResp = @currentProcessingValues[childRetType]
											existingQuestionResp = existingQuestionResp.merge(childObj)
										else
											@currentProcessingValues[childRetType] = childObj
										end
										if currentProcessingPartyDO == nil && (PARTYADDRESS_DO == childRetType || PARTYIDENTITY_DO == childRetType || PARTYADDTNL_DO == childRetType)
											#if the current party is not set and the loop is through the address then it implies it is the Party's address
											#this happens in case of Nominee address PolicyDO.getNomineePartyAddressList
											@policy.PartyList.each do |party|
												if childObj.parentKey == party.object
													@currentProcessingValues[PARTY_DO] = party
													@currentProcessingValues[PARTYADDTNL_DO] = party.getPartyAdditionalField(true)
													@currentProcessingValues[PARTYROLE_DO] = @policy.getPolicyPartyRole(party.roleCd)
													break
												end
											end
										end
										evaluateModel(modelDO, childObj, true, true)
									rescue Exception => e
										#if any error has occurred during execution then do not continue with further evaluation
										#this is to enforce that all exceptions in expressions are handled
										Rho::Log.error("Error during model evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
										break
									end
								end
								if numInstances == 0
									Rho::Log.info("No instances found of #{childRetType} to evaluate model #{modelDO.modelCd}", LOGCATEGORY)
								end
								#At times the list is the party do itself eg. for Nominee - PolicyDO.getNomineePartyList():PartyDO
								#hence setting it back after the compute per instace of is complete with the temporary variable.
								if PARTY_DO == childRetType
									@currentProcessingValues[PARTY_DO] = currentProcessingPartyDO
								end
							end
						else
							#else evaluate model once
							evaluateModel(modelDO, objToEvaluate, true, true)
						end
					end
				rescue Exception => e
					#if any error has occurred during execution then do not continue with further evaluation
					#this is to enforce that all exceptions in expressions are handled
					Rho::Log.error("Error during model set evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
					break
				end
			end
		end
		##################################################################################################


		#Method loops though all the elements in the Models and evaluates
		def evaluateModel(modelDO, objToEvaluate, addResult, isRollupResultReq)
			if isRollupResultReq
				Rho::Log.info("Model->>#{modelDO.modelCd}", LOGCATEGORY)
			else
				Rho::Log.info("Rollup Model->>#{modelDO.modelCd}", LOGCATEGORY)
			end

			modelFieldResult 			= MobiSys::DataObjects::FieldResult.new
			#initialize PolicyResultDO with values required
			policyResultDO 				= PolicyResult.new
			policyResultDO.riskCd 		= modelDO.riskCd
			# sort order added for ordering of records in the order of evaluation.
			policyResultDO.sortOrder 	= @policy.PolicyResultList.size + 1
			#set parent risk code
			riskDO = nil
			parentRisk = Risk.find(
				:first,
				:conditions => {
					:riskCd => modelDO.riskCd
				}
			)
			if parentRisk
				if parentRisk.parentRiskCd.to_s != ""
					riskDO = Risk.find(
						:first,
						:conditions => {
							:id => parentRisk.parentRiskCd
						}
					)
				else
					riskDO = parentRisk
				end
				policyResultDO.parentRiskCd = riskDO.riskCd
			end
			policyResultDO.ruleName = modelDO.modelCd
			policyResultDO.uwTypeCd = @currentProcessingValues[UW_TYPE]
			#set the guid of the PolicyResultDO object to that of the resultant data for link on UI
			modelFieldResult.id = policyResultDO.object
			policyResultDO.policyProductInsuredRefGuid 	= @currentProcessingValues[PRDINSURED_DO].guid if @currentProcessingValues[PRDINSURED_DO]
			policyResultDO.policyProductRefGuid 		= @currentProcessingValues[POLPRODUCT_DO].guid if @currentProcessingValues[POLPRODUCT_DO]
			policyResultDO.partyRoleRefGuid 			= @currentProcessingValues[PARTYROLE_DO].guid if @currentProcessingValues[PARTYROLE_DO]
			policyResultDO.partyRefGuid 				= @currentProcessingValues[PARTY_DO].guid if @currentProcessingValues[PARTY_DO]
			entityDesc = ""

			#for compute per instance there would be multiple instances of the same rule being triggered..
			#and need to access previous rule values in current rule. for this when the model is evaluated first time
			#the previous rule data does not exist and mvel throws an error.. hence initializing with blank policyresult data.
			#when addModelResultData is called again at the end it will just overwrite the blank values.
			if modelDO.computePerInstanceOf
				addModelResultData(modelFieldResult, modelDO)
			end

			modelDO.IllustrationFacetList.each do |illusFacetDO|
				begin
					evaluatedVal = evaluateElement(illusFacetDO, objToEvaluate, modelFieldResult)
					if evaluatedVal.to_s == "break"
						break
					elsif evaluatedVal.to_s == "break_Rollup"
						#if rollup needs to discontinue then set global variable
						@rollupBreakFacet = true
						break
					end
					entityDesc += illusFacetDO.elementLabel.to_s + ":" +  evaluatedVal.to_s + ","
					#set the output into the policyResult field
					if illusFacetDO.inputDataElement
						fieldName = illusFacetDO.inputDataElement
						begin
							eval("policyResultDO.#{fieldName} = evaluatedVal")
						rescue Exception => e
							Rho::Log.error("Unable to call setter on field : #{fieldName}", LOGCATEGORY)
						end
					end
				rescue Exception => e
					#if any error has occurred during execution then do not continue with further evaluation
					#this is to enforce that all exceptions in expressions are handled
					Rho::Log.error("Error during model evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
					break
				end
			end
			#remove the last ,
			entityDesc = entityDesc[0..-1] if entityDesc.length > 0
			policyResultDO.entityDesc = entityDesc
			policyResultDO.parentKey = @policy.object
			policyResultDO.stackTrace = modelFieldResult.to_json
			@policy.addPolicyResult(policyResultDO) if addResult

			#set the current rule data of the current insured in hashmap for further processing
			#since some of the expressions uses previous rule data
			addModelResultData(modelFieldResult, modelDO)

			if isRollupResultReq
				rollupResult(policyResultDO)
			else
				#if rollup of result is done ..it internally calls populate document, populate loading
				#but if not then this is a rollup kind of result but we still need to add documents, loading if added.
				populateDocument(policyResultDO)
				populateLoading(policyResultDO, @currentProcessingValues[POLPRODUCT_DO])
			end
			return policyResultDO
		end
		##################################################################################################


		def addModelResultData(fieldResultDO, modelDO)
			hmInsuredUWRiskRule = @currentProcessingValues[UWRISKRESULT_DO]
			if hmInsuredUWRiskRule
				#loop through the result data and add the element values
				#if no result exists then add null data since would be required in next evaluation
				if fieldResultDO.fieldValueList.size == 0
					modelDO.IllustrationFacetList.each do |illusFacetDO|
						#if hashmap already contains these values then do not overwrite
						#if it contains one element implies it contains all.
						if hmInsuredUWRiskRule.has_key?(modelDO.modelCd.to_s +  "_" + illusFacetDO.computedElementName.to_s)
							break
						end
						hmInsuredUWRiskRule[modelDO.modelCd.to_s +  "_" + illusFacetDO.computedElementName.to_s] = nil
					end
				else
					fieldResultDO.hmFieldValues.keys.each do |elementName|
						hmInsuredUWRiskRule[modelDO.modelCd.to_s + "_" + elementName.to_s] = fieldResultDO.getFieldValue(elementName)
					end
				end
			end
		end
		##################################################################################################


		#this rolls up all the different rollups ie. insured to product to policy for the different types of underwriting
		def rollupHierarchy
			#Medical roll up
			@currentProcessingValues[UW_TYPE] 	= MUW
			prdToPolicyMedRollupExists 			= @rollupFacetMap[POLICYMEDICALUWROLLUP] != nil
			prdInsToPrdMedRollupExists 			= @rollupFacetMap[PRDMEDICALROLLUP] != nil

			#need to check if either of the 2 rollups are existing since the prdtopolicy should be retriggered based on new rollup
			@policy.insuredUWDecisionCd = "" if prdToPolicyMedRollupExists || prdInsToPrdMedRollupExists
			@policy.PolicyProductList.each do |policyProductDO|
				@currentProcessingValues[POLPRODUCT_DO] = policyProductDO
				@currentProcessingValues[PARTY_DO] 		= @policy.getMainInsured(policyProductDO)

				if prdInsToPrdMedRollupExists
					policyProductDO.decisionCd = ""
					policyProductDO.PolicyProductInsuredList.each do |prdIns|
						if PRDMEDICALROLLUP != @rollupBreakFacetId
							@currentProcessingValues[PRDINSURED_DO] = prdIns
							currentInsuredPartyDO = nil
							if prdIns.refGuid.to_s != ""
								currentInsuredPartyDO = @policy.getPartyByGuid(prdIns.refGuid)
							end

							@currentProcessingValues[PARTY_DO] = currentInsuredPartyDO
							if currentInsuredPartyDO
								insuredRoleCd = policyProductDO.partyRoleCd
								insuredRoleCd = "PRIMARY" if insuredRoleCd.to_s == ""
								#Add the policy party role for the Insured on this product. i.e. insured could be the Proposer
								@currentProcessingValues[PARTYROLE_DO] = @policy.getPolicyPartyRoleByPartyGuid(currentInsuredPartyDO.guid, insuredRoleCd)
							end
							policyProductDO.decisionCd = getRolledUpDecision(prdIns.decisionCd, policyProductDO.decisionCd, PRDMEDICALROLLUP)
						end
					end
				end
				if prdToPolicyMedRollupExists || prdInsToPrdMedRollupExists
					if POLICYMEDICALUWROLLUP != @rollupBreakFacetId
						@policy.insuredUWDecisionCd = getRolledUpDecision(policyProductDO.decisionCd, @policy.insuredUWDecisionCd, POLICYMEDICALUWROLLUP)
					end
				end
			end

			#financial roll up
			@currentProcessingValues[UW_TYPE] = FUW
			#TODO financial roll up, policy level rollup etc
			partyRoleToPolicyFinRollupExists = @rollupFacetMap[POLICYFINROLLUP] != nil
			if partyRoleToPolicyFinRollupExists
				#for financial UW the ProductDO should be considered as the base plan
				@policy.financerUWDecisionCd = ""
				basePlan = @policy.getBaseProduct
				proposer = @policy.getParty("PROPOSER")
				payer = @policy.getPayerParty("INITIALPAYMENT")
				finParty = nil
				@policy.PolicyPartyRoleList.each do |policyPartyRoleDO|
					isRollupReq = false
					if "PROPOSER" == policyPartyRoleDO.roleCd
						isRollupReq = true
						finParty = proposer
					elsif "PAYER" == policyPartyRoleDO.roleCd && policyPartyRoleDO.refGuid != proposer.guid
						isRollupReq = true
						finParty = payer
					end
					if isRollupReq
						@currentProcessingValues[POLPRODUCT_DO] = basePlan
						@currentProcessingValues[PARTY_DO] = finParty
						@currentProcessingValues[PARTYADDTNL_DO] = finParty.PartyAdditionalFieldsList[0]
						@currentProcessingValues[PARTYROLE_DO] = policyPartyRoleDO
						if POLICYFINROLLUP != @rollupBreakFacetId
							@policy.financerUWDecisionCd = getRolledUpDecision(policyPartyRoleDO.decisionCd, @policy.financerUWDecisionCd, POLICYFINROLLUP)
						end
					end
				end
			end

			#Policy final overall UW Rollup
			@currentProcessingValues[UW_TYPE] = PUW
			@currentProcessingValues[POLPRODUCT_DO] = @policy.getBaseProduct
			policyFinalOverallUWRollupExists = @rollupFacetMap[POLICYFINALOVERALLUWROLLUP] != nil
			if policyFinalOverallUWRollupExists
				@policy.overallUWDecisionCd = getRolledUpDecision(nil, nil, POLICYFINALOVERALLUWROLLUP)
			else
				@policy.overallUWDecisionCd = getRolledUpDecision(@policy.financerUWDecisionCd, @policy.policyOtherUWDecisionCd, nil)
				@policy.overallUWDecisionCd = getRolledUpDecision(@policy.insuredUWDecisionCd, @policy.overallUWDecisionCd, nil)
			end
			#Policy Workflow rollup
			@policy.uwDecisionCd = ""
			@policy.uwDecisionCd = getRolledUpDecision(@policy.overallUWDecisionCd, @policy.uwDecisionCd, POLICYWORKFLOWROLLUP)
		end
		##################################################################################################


		def rollupResult(policyResultDO)
			unless policyResultDO.decisionCd
				return
			end
			#count the various decisions in the result, to be used for override
			if @uwDecisionCount.has_key?(policyResultDO.decisionCd)
				decisionCount = @uwDecisionCount[policyResultDO.decisionCd]
				@uwDecisionCount[policyResultDO.getDecisionCd] = decisionCount+1
			else
				@uwDecisionCount[policyResultDO.decisionCd] = 1
			end

			#put this decision count hashmap in the values to be processed since can be available for expressions.
			@currentProcessingValues[UW_DECISIONCOUNT] 		= @uwDecisionCount
			@currentProcessingValues[UW_DECISIONPRIORITY] 	= @uwDecisionPriority

			#based on current decision roll up the decision at a Policy product insured level.
			if @currentProcessingValues[PRDINSURED_DO]
				currentPolPrdIns = @currentProcessingValues[PRDINSURED_DO]
				currentPolPrdIns.decisionCd = getRolledUpDecision(policyResultDO.decisionCd, currentPolPrdIns.decisionCd, PRDINSUREDMEDICALROLLUP)
				if @currentProcessingValues[POLPRODUCT_DO]
					currentPolPrdDO = @currentProcessingValues[POLPRODUCT_DO]
					#the decision of the insured needs to be rolled up to the product
					currentPolPrdDO.decisionCd = getRolledUpDecision(currentPolPrdIns.decisionCd, currentPolPrdDO.decisionCd, nil)
					@policy.insuredUWDecisionCd = getRolledUpDecision(currentPolPrdDO.decisionCd, @policy.insuredUWDecisionCd, nil)
				end
			end
			if @currentProcessingValues[PARTYROLE_DO]
				currentPolPartyRoleDO = @currentProcessingValues[PARTYROLE_DO]
				currentPolPartyRoleDO.decisionCd = getRolledUpDecision(policyResultDO.decisionCd, currentPolPartyRoleDO.decisionCd, PAYERFINROLLUP)
				#the decision of the Policy party role needs to be rolled up to the policy
				#@policy.uwDecisionCd = getRolledUpDecision(currentPolPartyRoleDO.decisionCd, @policy.uwDecisionCd)
				@policy.financerUWDecisionCd = getRolledUpDecision(currentPolPartyRoleDO.decisionCd, @policy.financerUWDecisionCd, nil)
				#@policy.policyOtherUWDecisionCd = getRolledUpDecision(currentPolPartyRoleDO.decisionCd, @policy.policyOtherUWDecisionCd)
			end

			if PUW == policyResultDO.uwTypeCd
				@policy.policyOtherUWDecisionCd = getRolledUpDecision(policyResultDO.decisionCd, @policy.policyOtherUWDecisionCd, POLICYOTHERADDNLROLLUP)
			end
			populateDocument(policyResultDO)
			populateLoading(policyResultDO, @currentProcessingValues[POLPRODUCT_DO])
		end
		##################################################################################################


		#Pass as a parameter rollupFacetId - the type of rollup i.e. the facet id. Pass from all calling functions
		def getRolledUpDecision(currentDecision, previousDecision, rollupFacetId)
			rolledUpDecision = nil
			@currentProcessingValues["currentUWDecision"] = currentDecision
			@currentProcessingValues["previousDecision"] = previousDecision

			currentDecisionPriority = @uwDecisionPriority[currentDecision] == nil ? 0 : @uwDecisionPriority[currentDecision]
			previousDecisionPriority = @uwDecisionPriority[previousDecision] == nil ? 0 : @uwDecisionPriority[previousDecision]

			@currentProcessingValues["currentUWDecisionPriority"] = currentDecisionPriority
			@currentProcessingValues["previousUWDecisionPriority"] = previousDecisionPriority

			#check if for the current rollup facet any model exists.
			#i.e. rollupModelDO = @rollupFacetMap[rollupFacetId]
			#if no model exists then do the below comparison itself else call evaluateModel(rollupModelDO, nil, false)
			#evaluateModel will return a PolicyResultDO with the decisionCd set . This decision needs to be returned.
			rollupModelDO = nil
			#only if the rollup for current facet needs to be continued then do a rollup.
			if rollupFacetId.to_s != ""
				#first check if the current policy product is a rider..
				#if so then pick up the rollup defined for the rider for facets PRDINSUREDMEDICALROLLUP, PRDMEDICALROLLUP only
				#if no rollup defined at rider level then don't evaluate based on model ..
				if rollupFacetId == PRDINSUREDMEDICALROLLUP || rollupFacetId == PRDMEDICALROLLUP
					policyProductDO = @currentProcessingValues[POLPRODUCT_DO]
					if policyProductDO.productTypeCd.to_s == "RIDER"
						rollupModelDO = @rollupFacetMap[policyProductDO.productId.to_s+"-"+rollupFacetId]
					else
						rollupModelDO = @rollupFacetMap[rollupFacetId]
					end
				else
					rollupModelDO = @rollupFacetMap[rollupFacetId]
				end
			end
			if rollupModelDO
				policyResultDO = evaluateModel(rollupModelDO, nil, true, false)
				policyResultDO.rollupFacetId = rollupFacetId
				rolledUpDecision = policyResultDO.decisionCd
				if @rollupBreakFacet
					#if break was found for rollup then set the current facet to be discontinued from rollup
					#and reset the global break flag
					@rollupBreakFacetId = rollupFacetId
					@rollupBreakFacet = false
				end
			else
				if previousDecision.to_s == ""
					rolledUpDecision = currentDecision
				else
					if currentDecisionPriority > previousDecisionPriority
						rolledUpDecision = currentDecision
					else
						rolledUpDecision = previousDecision
					end
				end
			end

			rolledUpDecision = currentDecision if rolledUpDecision.to_s == ""

			return rolledUpDecision
		end
		##################################################################################################


		#Method to add loading based on Model Evaluation
		def populateLoading(policyResultDO, policyProductDO)
			#check if the Loading has been populated with extra type then populate the extra data
			if policyResultDO.extraTypeCd.to_s != "" && policyProductDO != nil
				#if the same extra type is already existing in the PolicyProduct then get that else add a new one
				policyProductExtraDO = policyProductDO.getPolicyProductExtra(policyResultDO.extraTypeCd)
				unless policyProductExtraDO
					policyProductExtraDO = PolicyProductExtra.new
					policyProductDO.addPolicyProductExtra(policyProductExtraDO)
				else
					#if extra DO was already existing then check if it is for the same duration as the current.
					#since we cannot add for different durations. we need to have multiple records.
					#TODO but in Model evaluation we have not handled multiple records for same extra type.
					#so for now let it be added.
				end

				policyProductExtraDO.extraTypeCd = policyResultDO.extraTypeCd if policyProductExtraDO.extraTypeCd.to_s == ""

				#Loading Type - FLAT, PERCENT or BOTH.
				if policyProductExtraDO.loadingTypeCd.to_s == ""
					policyProductExtraDO.loadingTypeCd = policyResultDO.loadingTypeCd
				else
					#check if previous loading type is flat and next is percent then set to BOTH...
					if policyResultDO.loadingTypeCd.to_s != "" && policyProductExtraDO.loadingTypeCd != policyResultDO.loadingTypeCd
						policyProductExtraDO.loadingTypeCd = "BOTH"
					end
				end

				#If record exists, then add the new result to the existing value.
				if policyResultDO.extraFlatAmt.to_s != ""
					policyProductExtraDO.extraFlatAmt = policyResultDO.extraFlatAmt.to_f + (policyProductExtraDO.extraFlatAmt.to_s != "" ? policyProductExtraDO.extraFlatAmt.to_f : 0.00)
				end
				#if record exists then check whose duration is higher set the higher duration at product level
				if policyResultDO.extraFlatDuration.to_s != ""
					if policyProductExtraDO.extraFlatDuration.to_s != ""
						if policyResultDO.extraFlatDuration > policyProductExtraDO.extraFlatDuration
							policyProductExtraDO.extraFlatDuration = policyResultDO.extraFlatDuration
						end
					else
						policyProductExtraDO.extraFlatDuration = policyResultDO.extraFlatDuration
					end
				end

				if policyResultDO.extraPercent.to_s != ""
					policyProductExtraDO.extraPercent = policyResultDO.extraPercent.to_f + (policyProductExtraDO.extraPercent.to_s != "" ? policyProductExtraDO.extraPercent.to_f : 0.00)
				end

				if policyResultDO.extraPercDuration.to_s != ""
					if policyProductExtraDO.extraPercDuration.to_s != ""
						if policyResultDO.extraPercDuration > policyProductExtraDO.extraPercDuration
							policyProductExtraDO.extraPercDuration = policyResultDO.extraPercDuration
						end
					else
						policyProductExtraDO.extraPercDuration = policyResultDO.extraPercDuration
					end
				end

				#For extra premium computation call model based premium
				if $quotation
					quotation = $quotation
				else
					quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
				end
				quotationProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
				#MobiSys::ProductBO.calculateModelBasedPremium(1, quotation, quotationProduct, policyProduct.product)
				#here we need to call premiumSAFlagBasedComputation instead of calculateModelBasedPremium
            	#since internally this checks whether premium needs to be computed or SA based on Premium/SA flag
				isWOP = MobiSys::ProductBO.isWOP(quotationProduct, quotation)
				premiumDetailsFacet = policyProductDO.product.getPremiumDetailsFacet
				premiumDetailsDO = nil
				if premiumDetailsFacet
					premiumDetailsDO =	premiumDetailsFacet.OfflinePremiumDetailsList[0]
				end
				MobiSys::ProductBO.premiumSAFlagBasedComputation(quotationProduct, quotation, premiumDetailsDO, isWOP)
				if quotationProduct.productTypeCd == "RIDER"
					MobiSys::ProductBO.calculateRiderValues(quotation, quotationProduct, 1)
				end
				quotation.QuotationProductList.each do |quotationProduct|
					@policy.PolicyProductList.each do |policyProduct|
						if policyProduct.object == quotationProduct.holderRefGuid
							MobiSys::ProductBO.copyCalculatedAttributes(quotationProduct, policyProduct)
						end
					end
				end
			end
		end
		##################################################################################################


		#Method to add additional requirements based on Model Evaluation
		def populateDocument(policyResultDO)
			#check if the category code has been populated with document categories then load the documents.
			#Documents need to be loaded only for actual processing ..
			#in case auto UW is called only for validation then no point loading documents etc.
			#assuming that isServiceRequired will be set to false for computation.
			if policyResultDO.categoryCd.to_s != ""
				#check if the category of document has already been loaded earlier
				#List all the categories that have to be loaded and find using IN clause
				docCatgResList 				= policyResultDO.categoryCd.to_s.split(",")
				docCategoryListForResult 	= []
				docCategoryListToFind 		= []
				docCatgResList.each do |docCatg|
					#first check if this document category is already added for this party due to some other product or another rule
					if checkDocumentExistsForParty(docCatg, policyResultDO.documentCd, policyResultDO.partyRefGuid)
						next
					end
					if @docCatgmap.has_key?(docCatg)
						docCategoryListForResult.push(@docCatgmap[docCatg])
					else
						docCategoryListToFind.push(docCatg)
					end
				end

				if docCategoryListToFind.size > 0
					docCatgListjustFound = DocumentCategory.loadObject(
						:all,
						:conditions => {
							{
								:name => "categoryCd",
								:op => "IN"
							} => docCategoryListToFind
						}
					)
					#add the new documents loaded to the map
					if docCatgListjustFound.size > 0
						docCatgListjustFound.each do |docCat|
							docCategoryListForResult.push(docCat)
							@docCatgmap[docCat.categoryCd] = docCat
						end
					end
				end
				#if document code has been specified then load only those documents else populate all documents mapped.
				docCategoryListForResult.each do |documentCategoryDO|
					documentCategoryMapDOList = []
					if policyResultDO.documentCd.to_s != ""
						documentCdArr = policyResultDO.documentCd.to_s.split(",")
						documentCdArr.each do |document|
							documentCategoryDO.DocumentCategoryMapList.each do |documentCategoryMapDO|
								if document.to_s == documentCategoryMapDO.documentCd.to_s
									documentCategoryMapDOList.push(documentCategoryMapDO)
									break
								end
							end
						end
					else
						documentCategoryMapDOList = documentCategoryDO.DocumentCategoryMapList
					end
					documentCategoryMapDOList.each do |documentCategoryMapDO|
						serviceDoc 							= ServiceDocument.new
						serviceDoc.docCategoryCd 			= documentCategoryDO.categoryCd
						serviceDoc.docCategoryTypeCd 		= documentCategoryDO.categoryTypeCd
						serviceDoc.documentCd 				= documentCategoryMapDO.documentCd
						serviceDoc.partyGuid 				= policyResultDO.partyRefGuid
						serviceDoc.isAutoGeneratedFl 		= "YES_UW"
						serviceDoc.acceptanceStatusCd 		= "PENDING"
						@serviceDocumentList.push(serviceDoc)
					end #end for documentcategory map
				end #end for documentcategory
		 	end #end if null check
		end
		##################################################################################################


		def checkDocumentExistsForParty(categoryCd, documentCd, partyGuid)
			listServiceDocsFound = []
			@serviceDocumentList.each do |serviceDoc|
				if serviceDoc.categoryCd.to_s == categoryCd.to_s && serviceDoc.partyGuid.to_s == partyGuid.to_s
					listServiceDocsFound.push(serviceDoc)
				end
			end
			if listServiceDocsFound.size > 0
				#TODO here for now returning true if documents found.. but it could be that documents were received but have been rejected
				#and are required again so add check for document accepted status as well..
				isDocfound = false
				listServiceDocsFound.each do |serviceDocumentDO|
					if serviceDocumentDO.documentCd.to_s != "" && documentCd.to_s != "" && documentCd.to_s == serviceDocumentDO.documentCd.to_s
						isDocfound = true
					end
				end
				if isDocfound || documentCd == nil
					return true
				end
			end
			return false
		end
		##################################################################################################


		def rollup
			initializeEvaluationParams
			initializeRollupFacet
			#clear all the decisions in order to rollup
			@policy.overallUWDecisionCd 	= ""
			@policy.insuredUWDecisionCd 	= ""
			@policy.financerUWDecisionCd 	= ""
			@policy.policyOtherUWDecisionCd = ""
			#nullify all the decisions of products as well
			@policy.PolicyProductList.each do |policyProductDO|
				policyProductDO.decisionCd = ""
				policyProductDO.PolicyProductInsuredList.each do |prdIns|
					prdIns.decisionCd = ""
				end
			end
			@policy.PolicyPartyRoleList.each do |policyPartyRoleDO|
				policyPartyRoleDO.decisionCd = ""
			end

			policyResultRollupList = []
			@policy.PolicyResultList.each do |polResult|
				if polResult.rollupFacetId.to_s != ""
					policyResultRollupList.push(polResult)
					next
				end
				@policy.PolicyProductList.each do |policyProduct|
					if polResult.policyProductRefGuid == policyProduct.guid
						@currentProcessingValues[POLPRODUCT_DO] = policyProduct
					end
					policyProduct.PolicyProductInsuredList.each do |prdIns|
						if polResult.policyProductInsuredRefGuid == prdIns.guid
							@currentProcessingValues[PRDINSURED_DO] = prdIns
							break
						end
					end
				end

				#if product not found and it is of type Financial UW or Policy UW then assume it is the base plan
				if @currentProcessingValues[POLPRODUCT_DO] == nil && polResult.uwTypeCd.to_s != MUW
					policyProductDO = @policy.getBaseProduct
					polResult.policyProductRefGuid = policyProductDO.guid
					@currentProcessingValues[POLPRODUCT_DO] = policyProductDO
					policyProduct.PolicyProductInsuredList.each do |prdIns|
						if polResult.policyProductInsuredRefGuid == prdIns.guid
							@currentProcessingValues[PRDINSURED_DO] = prdIns
							break
						end
					end
				end
				@currentProcessingValues[UW_TYPE] = polResult.uwTypeCd

				@policy.PartyList.each do |party|
					if polResult.partyRefGuid == party.guid
						@currentProcessingValues[PARTY_DO] = party
						break
					end
				end
				@policy.PolicyPartyRoleList.each do |policyPartyRole|
					if polResult.partyRoleRefGuid == policyPartyRole.guid
						@currentProcessingValues[PARTYROLE_DO] = policyPartyRole
						break
					end
				end
				rollupResult(polResult)
			end
			@policy.setPolicyResultList(@policy.PolicyResultList - policyResultRollupList)
			rollupHierarchy
		end
		##################################################################################################


		#Method performs fixed DT evaluation
		def evaluateExpression(illusFacetDO, objToEvaluate)
			evaluatedValue = nil
			#here check if compiled expression exists then use it else do MVEL.eval
			begin
				#########################Code commented cause compiled expressions are not available in offline
				# if illusFacetDO.compiledExpression.to_s != ""
					evaluatedValue = eval(illusFacetDO.expression)
				# else
				# 	evaluatedValue = MVEL.executeExpression(illusFacetDO.compiledExpression, objToEvaluate, currentProcessingValues)
				# end
			rescue Exception => e
				Rho::Log.error("Error during expression evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				#if there is error in evaluation then check if it is an expression based on Questionnaire
				#if so do not mark as erroneous since questionnaire response may not be present in cases like conditional questionnaire etc.
				#likewise while checking for previous rule result data. eg. if there are no grid question rows then there will be no result objects as well.
				if illusFacetDO.expression.include?(QUESTIONNAIRE_ELEMS + ".") || illusFacetDO.expression.include?(UWRISKRESULT_DO + ".")
					Rho::Log.info("No response found for questionnnaire while evaluating expression: " + illusFacetDO.expression.to_s + " " + e.to_s, LOGCATEGORY)
				else
					logModelError(illusFacetDO, objToEvaluate, evaluatedValue, e)
				end
			end

			return evaluatedValue
		end
		##################################################################################################


		#Method evaluates model elements based on element type invokes MVEL, Fixed/Dynamic DT
		def evaluateElement(illusFacetDO, objToEvaluate, modelFieldResult)
			evaluatedValue = nil
			#maintain the stack trace of each element being evaluated for every result.
			fldResultElem = MobiSys::DataObjects::FieldResult.new
			#set object name for ui purpose
			fldResultElem.objectName = "UWRuleDetailDO"
			fldResultElem.addFieldValue(nil, "elementName", illusFacetDO.elementLabel, "Element")
			#evaluate expression
			if illusFacetDO.facetTypeCd == COMPUTEDFORMULA && illusFacetDO.expression.to_s != ""
				expForDisplay = illusFacetDO.expressionForDisplay.to_s == "" ? "" : illusFacetDO.expressionForDisplay.to_s.gsub!("\"", "")
				fldResultElem.addFieldValue(nil, "expression", expForDisplay, "Expression")
				evalExpression = logModelError(illusFacetDO, objToEvaluate, evaluatedValue, nil, false)
				evalExpression = evalExpression.to_s.gsub!("\"", "")
				fldResultElem.addFieldValue(nil, "evalExpression", evalExpression, "Expression evaluated")
				evaluatedValue = evaluateExpression(illusFacetDO, objToEvaluate)
			elsif illusFacetDO.facetTypeCd == COMPUTEDDECISIONTBL && illusFacetDO.ruleSeq.to_s != ""
				#here evaluate the fixed DT
				evaluatedValue = evaluateFixedDT(illusFacetDO, illusFacetDO.ruleSeq, objToEvaluate)
				fldResultElem.addFieldValue(nil, "expression", @policy.getEntityDesc, "Fixed DT")
				fldResultElem.addFieldValue(nil, "evalExpression", "", "Expression evaluated")
			elsif illusFacetDO.facetTypeCd == DYNAMICDECISIONTBL && illusFacetDO.facetId.to_s != ""
				#here evaluate the dynamic Rule as the Rule name is stored in the facetId column
				#the dynamic DT works on the elements in the model hence pass the modelFieldResult as the object to evaluate
				matchedDT = evaluateDynamicDT(illusFacetDO.facetId, modelFieldResult)
				fldResultElem.addFieldValue(nil, "expression", matchedDT == nil ? "No matching DT record found" : matchedDT.hmFieldValues.to_s, "Decision table")
				fldResultElem.addFieldValue(nil, "evalExpression", "", "Expression evaluated")
				evaluatedValue = modelFieldResult.getFieldValue(illusFacetDO.computedElementName)
			elsif illusFacetDO.facetTypeCd == OUTPUTFRMDYNAMICDT
				#here the value would have already been added as action of the dynamic DT defined above
				evaluatedValue = modelFieldResult.getFieldValue(illusFacetDO.computedElementName)
			end
			fldResultElem.addFieldValue(nil, "elementValue", evaluatedValue.to_s, "Element value")
			#add each element to the Row model result object
			modelFieldResult.addFieldResult(fldResultElem)
			evaluatedValue = 0 if !evaluatedValue.is_a?(Array) && !evaluatedValue.is_a?(Hash) && ![true, false].include?(evaluatedValue) && evaluatedValue.to_f.infinite?
			evaluatedValueDataType = ""
			if illusFacetDO.entityFieldTypeCd.to_s != ""
				entityTypeDO = $entityTypeCache[illusFacetDO.entityFieldTypeCd.to_sym] if $entityTypeCache
				evaluatedValueDataType = entityTypeDO.dataTypeCd.to_s if entityTypeDO
			end
			if evaluatedValueDataType == "STRING"
				evaluatedValue = evaluatedValue.to_s
			elsif evaluatedValue.to_s.match(/^[\d]+$/)
				evaluatedValue = evaluatedValue.to_i
			elsif defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.to_s.match(/^[\d\.]+$/) && $rhoconfig[:useBigDecimal]
				evaluatedValue = evaluatedValue.to_s.to_d
			elsif evaluatedValue.to_s.match(/^[\d\.]+$/)
				evaluatedValue = evaluatedValue.to_f
			else
				evaluatedValue = evaluatedValue.to_s
			end
			Rho::Log.info("Element->>#{illusFacetDO.computedElementName}:#{evaluatedValue}", LOGCATEGORY)
			@currentProcessingValues["#{illusFacetDO.computedElementName}"] = evaluatedValue
			#if the field value is not already existing then add it to the FieldResultDO
			if !modelFieldResult.containsFieldInMap(illusFacetDO.computedElementName)
				modelFieldResult.addFieldValue(nil, illusFacetDO.computedElementName, evaluatedValue, illusFacetDO.elementLabel, illusFacetDO.computationOrder)
			end

			return evaluatedValue
		end
		##################################################################################################


		#Method to get ServiceQuestionResponse records for a specific party or an entity
		def getQuestionResponse(partyGuid=nil)
			hmInsuredQuestion = {}
			hmGridBasedQuestResp = {}
			#either the questionnaires should be for the party or should be for the Agent/Entity (in the case of later the partyGuid would be null
			if partyGuid
				serviceQuestionResponseList = ServiceQuestionResponse.loadObject(
					:all,
					:conditions => {
						:partyGuid => partyGuid
					}
				)
			else
				serviceQuestionResponseList = ServiceQuestionResponse.loadObject(
					:all,
					:conditions => {
						:entityGuid => @policy.guid
					}
				)
			end
			serviceQuestionResponseList.each do |serviceQuestionResponse|
				if serviceQuestionResponse.responseValue.is_a?(Numeric)
					responseValue = serviceQuestionResponse.responseValue.to_f
				else
					responseValue = serviceQuestionResponse.responseValue.to_s
				end
				#if rowguid is not null then it implies it is a grid based question set and there would be multiple responses to the same question set + dataelement
				if serviceQuestionResponse.rowGuid.to_s != ""
					listGridBasedQset = hmGridBasedQuestResp[serviceQuestionResponse.questionSetCd]
					unless listGridBasedQset
						listGridBasedQset = []
						hmGridBasedQuestResp[serviceQuestionResponse.questionSetCd] = listGridBasedQset
					end
					listGridBasedQset.push(serviceQuestionResponse)
				else
					hmInsuredQuestion[serviceQuestionResponse.questionSetCd.to_s + "_" + serviceQuestionResponse.questionDataElementCd.to_s] = responseValue
				end
			end
			#add the grid based service question response as list/records of FieldResultDO
			hmGridBasedQuestResp.keys.each do |gridQuestionSetCd|
				#get the hashmap of values from fieldresultdo and add to arraylist since expression does not understand fieldresultDO
				gridQuestRespResList = MobiSys::CommonUtil.getDTFromQuestionResponse(hmGridBasedQuestResp[gridQuestionSetCd])
				listHmGridResp = []
				gridQuestRespResList.each do |fldResDO|
					#PolicyQuestionSetDO.Medical1_yesNoFl
					hmFldValues = fldResDO.hmFieldValues
					#all the keys will have to be replaced with questionsetcd_dataelementcd
					hmQrespFldValues = {}
					hmFldValues.keys.each do |key|
						hmQrespFldValues[gridQuestionSetCd.to_s + "_" + key.to_s] = hmFldValues[key]
					end
					listHmGridResp.push(hmQrespFldValues)
				end
				hmInsuredQuestion[gridQuestionSetCd] = listHmGridResp
			end

			return hmInsuredQuestion
		end
		##################################################################################################


		#Method performs Medical UW
		def medicalUW
			Rho::Log.info("medicalUW->>", LOGCATEGORY)
			#set the uw type as the risk type medical UW
			@currentProcessingValues[UW_TYPE] = MUW

			#loop through all the PolicyProductInsured and for each get the MEDICALAUTOUWRULE ModelSet and evaluate
			@policy.PolicyProductList.each do |policyProduct|
				@currentProcessingValues[POLPRODUCT_DO] = policyProduct
				Rho::Log.info("Product->>#{policyProduct.productId}", LOGCATEGORY)
				modelSet = @productUWFacetModelSetMap[policyProduct.productId.to_s+"-"+MEDICALAUTOUWRULE]
				if modelSet
					policyProduct.PolicyProductInsuredList.each do |policyProductInsured|
						begin
							@currentProcessingValues[PRDINSURED_DO] = policyProductInsured
							currentInsuredParty = nil
							@policy.PartyList.each do |party|
								if party.guid == policyProductInsured.insuredPartyRefGuid
									currentInsuredParty = party
									break
								end
							end

							@currentProcessingValues[PARTY_DO] = currentInsuredParty
							if currentInsuredParty
								@currentProcessingValues[PARTYADDTNL_DO] = currentInsuredParty.PartyAdditionalFieldsList[0]

								insuredRoleCd = policyProduct.partyRoleCd
								insuredRoleCd = "PRIMARY" if insuredRoleCd.to_s == ""
								#Add the policy party role for the Insured on this product. i.e. insured could be the Proposer
								@currentProcessingValues[PARTYROLE_DO] = @policy.getPolicyPartyRoleByPartyGuid(currentInsuredParty.guid, insuredRoleCd)

								Rho::Log.info("Prd Insured->>#{currentInsuredParty.getEntityDesc}", LOGCATEGORY)

								#set the questionnaire data of the current insured in hashmap
								#questionnaire info needs to be stored in the format PolicyQuestionSetDO.<QuestionSetCd>_<dataElementCd>
								#PolicyQuestionSetDO.Medical_yesNoFl
								@currentProcessingValues[QUESTIONNAIRE_ELEMS] = getQuestionResponse(currentInsuredParty.guid)

								#set the previous rule data of the current insured in hashmap
								#setting new hashmap for each insured
								hmInsuredUWRiskRule = {}
								@currentProcessingValues[UWRISKRESULT_DO] = hmInsuredUWRiskRule
								evaluateModelSet(modelSet, policyProductInsured)
							else
								Rho::Log.info("No party data found for product #{policyProduct.productId}", LOGCATEGORY)
							end
						rescue Exception => e
							#if any error has occurred during execution then do not continue with further evaluation
							#this is to enforce that all exceptions in expressions are handled
							Rho::Log.error("Error during model set evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
							break
						end
					end
				else
					Rho::Log.info("No MEDICALAUTOUWRULE facet Model Set configured for Product: #{policyProduct.productId}", LOGCATEGORY)
				end
			end
		end
		##################################################################################################


		#Method performs Financial UW
		def financialUW
			Rho::Log.info("financialUW->>", LOGCATEGORY)
			@currentProcessingValues[UW_TYPE] = FUW #set the uw type as the risk type Financial UW
			#nullifying the below since these PolicyResult are not at product, insured level.
			@currentProcessingValues[PRDINSURED_DO] = nil
			#for financial UW the ProductDO should be considered as the base plan
			basePlan = @policy.getBaseProduct
			#loop through the Proposer PartyDO, Payer PartyDO if different parties and for each get the FINANCIALAUTOUWRULE ModelSetDO and evaluate
			modeSetDO = @productUWFacetModelSetMap[basePlan.productId.to_s+"-"+FINANCIALAUTOUWRULE]
			if modeSetDO
				@currentProcessingValues[POLPRODUCT_DO] = basePlan
				proposer = @policy.getParty("PROPOSER")
				@currentProcessingValues[PARTY_DO] = proposer
				if proposer
					@currentProcessingValues[PARTYADDTNL_DO] = proposer.PartyAdditionalFieldsList[0]
					@policy.getPolicyPartyRoleList("PROPOSER").each do |partyRole|
						if partyRole.refGuid == proposer.guid
							@currentProcessingValues[PARTYROLE_DO] = partyRole
							break
						end
					end
					#set the questionnaire data of the Proposer in hashmap
					@currentProcessingValues[QUESTIONNAIRE_ELEMS] = getQuestionResponse(proposer.guid)

					#for financial UW no previous Rule data is required
					@currentProcessingValues[UWRISKRESULT_DO] = nil
					evaluateModelSet(modeSetDO, proposer)

					#check if payer is different from Proposer then invoke financial UW for Payer as well
					#listPayers = @policy.getPolicyPartyRoleList("PAYER")
					#get the payer only for first premium payment
					payer = @policy.getPayerParty("INITIALPAYMENT")
					if payer && payer.guid != proposer.guid
						@currentProcessingValues[PARTY_DO] = payer
						@currentProcessingValues[PARTYADDTNL_DO] = payer.PartyAdditionalFieldsList[0]
						@policy.getPolicyPartyRoleList("PAYER").each do |partyRole|
							if partyRole.refGuid == payer.guid
								@currentProcessingValues[PARTYROLE_DO] = partyRole
								break
							end
						end
						evaluateModelSet(modeSetDO, payer)
					end
				end #end proposer not null
			end
		end
		##################################################################################################


		#Method performs Policy level UW
		def policyUW
			Rho::Log.info("policyUW->>", LOGCATEGORY)
			@currentProcessingValues[UW_TYPE] = PUW #set the uw type as the risk type Policy UW
			#for Policy UW the ProductDO should be considered as the base plan
			basePlan = @policy.getBaseProduct
			#Pass the PolicyDO and get the POLICYAUTOUWRULE ModelSetDO and evaluate
			modeSetDO = @productUWFacetModelSetMap[basePlan.productId.to_s+"-"+POLICYAUTOUWRULE]
			if modeSetDO
				@currentProcessingValues[POLPRODUCT_DO] = basePlan
				#commented below since cannot set UW result on the primary insured by default..
				#primaryInsuredParty = @policy.getParty("PRIMARY")
				#currentProcessingValues[PARTY_DO] = primaryInsuredParty
				# @policy.getPolicyPartyRoleList("PRIMARY").each do |partyRole|
				# 	if partyRole.refGuid == primaryInsuredParty.guid
				# 		@currentProcessingValues[PARTYROLE_DO] = partyRole
				# 		break
				# 	end
				# end
				@currentProcessingValues[PARTY_DO] = nil
				@currentProcessingValues[PARTYROLE_DO] = nil
				#set the questionnaire data of the Entity, Agent in hashmap
				@currentProcessingValues[QUESTIONNAIRE_ELEMS] = getQuestionResponse(nil)
				#for Policy UW no previous Rule data is required
				@currentProcessingValues[UWRISKRESULT_DO] = nil
				#nullifying the below since these PolicyResult are not at product, insured level.
				@currentProcessingValues[PRDINSURED_DO] = nil
				evaluateModelSet(modeSetDO, @policy)
			end
		end
		##################################################################################################


		#Method performs Policy level UW
		def logModelError(illusFacetDO, objToEvaluate, evaluatedValue, exception, setError)
			expression 	= illusFacetDO.expression
			modelCd 	= ""
			modelFor 	= ""
			modelObj 	= nil
			if illusFacetDO.parentKey
				modelObj = IllustrationModel.loadObject(
					:first,
					:conditions => {
						:object => illusFacetDO.parentKey
					}
				)
				if modelObj
					modelCd 	= modelObj.modelCd
					modelFor 	= modelObj.modelFor
				end
			end
			finalExpression = ""
			trimExp 	= expression.strip
			miniExpVal 	= nil
			isValidExp 	= false
			begin
				miniExpVal = eval(trimExp)
				isValidExp = true
			rescue Exception => e
				#expression replacement for underwriting. since expression is compiled and is replaced before compiling.
				@replaceInputElementsUW.keys.each do |replaceExp|
					trimExp = trimExp.gsub(replaceExp, @replaceInputElementsUW[replaceExp])
				end
				begin
					miniExpVal = eval(trimExp)
					isValidExp = true
				rescue Exception => e
					Rho::Log.error("Error while evaluating expression: #{trimExp}\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				end
			end
			if isValidExp
				finalExpression = finalExpression + " " + miniExpVal.to_s
			else
				finalExpression = finalExpression + " " + trimExp
			end
			if setError
				errMessage = "Error in expression evaluation for, " + modelFor.to_s + " Model: " + modelCd.to_s + ", Element name: " + illusFacetDO.computedElementName.to_s + ", Element Label: " +  illusFacetDO.elementLabel.to_s + ", Evaluated value: " + evaluatedValue.to_s + ", Original expression: " + illusFacetDO.origExpression.to_s + ", Replaced expression: " + expression.to_s + ", Evaluated expression: " + finalExpression.to_s

				errMessage = errMessage.to_s + ", Exception: " + e.to_s if e
				Rho::Log.info(errMessage, LOGCATEGORY)
				#retain the first error
				unless @message
					@message = errMessage
					@output = "ERROR"
					@errored = true
				end
			end
			return finalExpression
		end
		##################################################################################################
	end

	class PolicyModel
		include MobiSys::BrowserHelper

		#Contants used throughout PolicyModel process
		LOGCATEGORY					= "PolicyModel"

		#Contants used in the compiled expressions
		CURRENT_UIACTION			= "currUIAction"
		CURRENT_UIFIELD				= "currentActiveField"
		CURRENT_UITAB				= "currActiveTab"
		CURRENT_UISTEP				= "currentActiveStep"
		POLPRODUCT_DO 				= PolicyProduct.name.to_s
		PARTY_DO 					= Party.name.to_s
		PARTYADDTNL_DO 				= PartyAdditionalFields.name.to_s
		POLICY_DO 					= Policy.name.to_s
		POLICYADDTNL_DO 			= PolicyAdditionalFields.name.to_s
		PARTYROLE_DO 				= PolicyPartyRole.name.to_s
		POLPAYMENT_DO				= PolicyPayment.name.to_s
		POLINVFUND_DO				= PolicyProductInvestmentFund.name.to_s
		PRDINSURED_DO				= PolicyProductInsured.name.to_s
		PLANPRIMARYINSURED_DO		= "PolicyPrimaryDO"
		PROPOSERPARTY_DO			= "PolicyProposerDO"
		JOINTPARTY_DO				= "PolicyJointLifeDO"
		QUESTIONNAIRE_ELEMS 		= "PolicyQuestionSet"
		OTHERMODELRESULT_DO 		= "PolicyModelOtherResultDO"
		UWRISKRESULT_DO 			= "PolicyUWRiskResult"
		POLBASEPLAN_DO 				= "PolicyBasePlanDO"
		POLRIDER_DO					= "PolicyRiderDO"
		AGENT_DO					= "AgentDO"
		BASE_IO						= "BaseIO"
		QUOTATION_IO				= "QuotationIO"
		OG_QUOTATION_DO				= "OGQuotationDO"
		POLBASEPLANMULTI_DO 		= "PolicyBasePlanMulti"
		PARTYIDENTITY_DO 			= PartyIdentity.name.to_s
		POLICYWITHDRAWAL_DO			= "PolicyWithdrawal"
		POLICYTOPUP_DO				= PolicyTopUp.name.to_s
		PARTYADDRESS_DO 			= PartyAddress.name.to_s
		PLANINVESTMENTFUND_DO		= PolicyProductInvestmentFund.name.to_s
		PRD_MASTER 					= "ProductMasterDO"

		#Facet constants

		COMPUTEDFORMULA 			= "COMPUTEDFORMULA"
		COMPUTEDDECISIONTBL 		= "COMPUTEDDECISIONTBL"
		DYNAMICDECISIONTBL 			= "DYNAMICDECISIONTBL"
		OUTPUTFRMDYNAMICDT 			= "OUTPUTFRMDYNAMICDT"
		# UNDERWRITING 				= "UNDERWRITING"
		POLICY 						= "POLICY"
		CURRENT_CYCLE				= "currCycleCount"
		ILLUSTRATIONMODEL 			= "ILLUSTRATIONMODEL"
		COMPUTEDLOOKUP 				= "COMPUTEDLOOKUP"
		RULEMODEL                   = "RULEMODEL"
		SOLVERMODEL                 = "SOLVERMODEL"
		PRDFACETIMMODEL				= "PRDFACETIMMODEL"
		ADDTNL_IM_EVAL_PARAMS		= "ADDTNL_IM_EVAL_PARAMS"
		DOCUMENT_ELEMS				= "PolicyDocumentDO"

		def initialize
			#Variables used throughout AutoUW process
			@policy 						= nil

			@replaceInputElementsPol			= {}
			# @startTime 						= Time.now.to_i
			# @logInfo 						= ""
			@currentLog 					= ""
			@message 						= ""
			@output 						= ""
			@errored 						= false
			#this is a holder for current values being processed that needs to be set in the PolicyResultDO and passed to MVEL
			@currentProcessingValues 		= {}
		end
		##################################################################################################


		#Main method to start dynamic Model evaluation
		def execute(policy, policyProduct, party, dynamicModelCd, tableTypeMappingSeq = nil, enableCache = true, matchedDTList = nil, quotationIO = nil, currPolicyPayment = nil, expressionHash = nil, illustrationModelList = nil, callFrom = nil)
			# @replaceInputElementsPol = $replaceInputElementsPol
			# Rho::Log.error("*****evaluating model : #{dynamicModelCd}", LOGCATEGORY)
			GC.enable
			@policy = policy
			@policy.additionalData = {} if @policy.additionalData == nil || callFrom == "QUESTIONNAIRE"
			@tableTypeMappingSeq = tableTypeMappingSeq
			@enableCache = enableCache
			@expressionHash = expressionHash
			@callFrom = callFrom

			party.issueAge = policyProduct.combinedEntryAge if policyProduct && party
			

			originalModelCd = "#{dynamicModelCd.to_s}"
			modelCdDynamic = "#{dynamicModelCd.to_s}"
			if $parentReferenceForPolModel
				$parentReferenceForPolModel.to_s.split('~').each do |qesCd|
					lastQues = qesCd.to_s.split("_").last
					if lastQues[0] == "V"
						queSetCd = qesCd.to_s.split("_")
						length = queSetCd.length
						lastqueSetCd = queSetCd[length-2]
						modelCdDynamic << "_#{lastqueSetCd}_#{lastQues}"
					else
						modelCdDynamic << "_#{lastQues}"
					end
					# dynamicModelCd << "_#{lastQues}"
				end
			end

			dbversion = Application.getValue('DBVERSION').value
			className = dynamicModelCd.upcase
			modelFileName = "#{Rho::Application.userFolder}#{className}_#{dbversion}"

			

			modelResultDO = MobiSys::DataObjects::FieldResult.new
			modelResultDOList = []
			if illustrationModelList and illustrationModelList.has_key?(dynamicModelCd)
				illustrationModel = illustrationModelList[dynamicModelCd]
			else
				illustrationModel = IllustrationModel.loadObject(:first, :conditions => {{:name => 'modelCd'} => dynamicModelCd})
			end

			initializeEvaluationParams(policy, policyProduct, party,illustrationModel, modelFileName, tableTypeMappingSeq, quotationIO, currPolicyPayment)

			# if callFrom == "QUESTIONNAIRE"
			# 	# Code file generation starts
			# 	if !File.exist?("#{modelFileName}.rb") || !File.exist?("#{modelFileName}.iseq") 
			# 		begin
			# 			Dir.glob("#{Rho::Application.userFolder}#{className}_*").each do |file|
			# 				if(file.to_s.match(/^.+#{className}_\d+\.\d+.+$/))
			# 					File.delete(file) if File.exists?(file)
			# 				end
			# 			end
			# 		rescue Exception => e
			# 			Rho::Log.error("Error in deleting file \n#{e}\n#{e.backtrace}", LOGCATEGORY)
			# 		end
			# 		lines = Array.new
			# 		lines.push "module PolicyUtil"
			# 		lines.push "	class PolicyModel"
			# 		lines.push "		class #{className}"
			# 		illustrationModel.IllustrationFacetList.each do |ift|
			# 			if ift.expression.to_s != ""
			# 				exp = $parentReferenceForPolModel ? ift.expression.to_s.gsub('$PARENTREFPATH$',$parentReferenceForPolModel) : ift.expression.to_s
			# 				#exp = $parentForPolModel ? ift.expression.to_s.gsub('$PARENT$',$parentForPolModel) : ift.expression.to_s
			# 				exp = $parentForPolModel ? exp.to_s.gsub('$PARENT$',$parentForPolModel) : exp.to_s
			# 				lines.push "			def self.#{ift.computedElementName}(currentProcessingValues)"
			# 				lines.push "				@currentProcessingValues = currentProcessingValues"

			# 				lines.push "				RhoLog.error(\"DynamicDT\", \"#{ift.computedElementName} || \#{(#{exp})} || #{exp} \")" #if ift.computedElementName.to_s == "element110"
			# 				lines.push "				(#{exp})"
			# 				lines.push "    		end"
			# 			end
			# 		end
			# 		lines.push "		end"
			# 		lines.push "	end"
			# 		lines.push "end"
					
					
			# 		file = File.open("#{modelFileName}.rb",'w')# do |f|
			# 		lines.each do |line|
			# 			file.puts line
			# 		end
			# 		file.close
			# 		if Rho::System.platform != "APPLE"
			# 			seq = RubyVM::InstructionSequence.compile_file("#{modelFileName}.rb")
			# 			arr = seq.to_a
			# 			newName ="#{modelFileName}.iseq"
			# 			fseq = File.new(newName, 'w')
			# 			Marshal.dump(arr,fseq)
			# 			fseq.close
			# 		end

			# 	end
			# 	if Rho::System.platform != "APPLE"
			# 		require modelFileName
			# 	else
			# 		b = Object.new.get_binding
			# 		fileContents = File.read("#{modelFileName}.rb")
			# 		eval(fileContents, b)
			# 	end
			# 	# Code file genration ends
			# end
			iftHash = {}
			lookupMap = {}
			# Create iftHash for DynamicDT
			if illustrationModel != nil && illustrationModel.modelFor == "DYNAMICDT"
				illustrationModel.IllustrationFacetList.each do |ift|
					if ift.entityDataTypeCd.to_s == "CONDITION" && ift.outputDisplayTypeCd.to_s == "YES"
						iftHash["CONDITION"] = Array.new if !iftHash["CONDITION"].is_a?(Array)
						iftHash["CONDITION"].push(ift)
					elsif ift.entityDataTypeCd == "ACTION" && ift.outputDisplayTypeCd.to_s == "YES"
						iftHash["ACTION"] = Array.new if !iftHash["ACTION"].is_a?(Array)
						iftHash["ACTION"].push(ift)
					elsif ift.entityDataTypeCd == "POSTDTACTION"
						iftHash["POSTDTACTION"] = Array.new if !iftHash["POSTDTACTION"].is_a?(Array)
						iftHash["POSTDTACTION"].push(ift)
					end
				end

				iftHash.each do |facetType, iftArray|
					iftArray = iftArray.sort{|x,y| x.computationOrder.to_i <=> y.computationOrder.to_i}
				end
			end

			#Check if the compute per instance of exists. if so then evaluate the model for every instance of the object
			if illustrationModel.computePerInstanceOf.to_s != ""
				Rho::Log.info("Compute per instance of->> #{illustrationModel.computePerInstanceOf}", LOGCATEGORY)
				#the lookup code contains the expression for getting the child arrayList
				#eg. the lookup code = PartyDO.getListPartyAddressDOList():PartyAddressDO
				#thus it needs to execute getListPartyAddressDOList on the current instance of PartyDO from hashmap
				compPerInst 	= illustrationModel.computePerInstanceOf.split(":")
				childExpression = compPerInst[0]
				childRetType 	= compPerInst[1]

				allChildInstancesObj = nil
				begin
					objectClass = childExpression.split(".")[0]
					if @currentProcessingValues.has_key?(objectClass)
						childExpression.gsub!("#{objectClass}.", "@currentProcessingValues[\"#{objectClass}\"].")
					end
					allChildInstancesObj = eval(childExpression)
				rescue Exception => e
					#Check if return type was supposed to be questions then do not set as errored since if grid questions do not exist then too it fails
					if !QUESTIONNAIRE_ELEMS == childRetType
						Rho::Log.error("Compute per instance of in not configured correctly. #{childExpression}, it should be a getter method.\n#{e}\n#{e.backtrace}", LOGCATEGORY)
					end
				end
				if allChildInstancesObj != nil && allChildInstancesObj.is_a?(Array)
					#At times the list is the party do itself eg. for Nominee - PolicyDO.getNomineePartyList():PartyDO
					#hence holding the existing PartyDO in temporary variable and then setting it back after the compute per instace of is complete.
					currentProcessingPartyDO = @currentProcessingValues[PARTY_DO]
					numInstances = 0
					allChildInstancesObj.each do |childObj|
						#resetting for per instance elements since if break was encountered for previous record, need to still process the next record.
						@breakEvaluation = false
						numInstances += 1
						begin
							Rho::Log.info("Instance found->>#{childObj.class.name}", LOGCATEGORY)
							#the child object will be referred to in expression by the return type
							#example PartyAddressDO.countryCd and hence adding to hashmap the current child object
							#this will be replaced for each instance
							#but in case of questionnaire we cannot replace the entire PolicyQuestionSetDO since it contains other question set responses
							#that we do not want to overwrite other than the current QuestionSet grid.
							parentParty = nil
							@policy.PartyList.each do |party|
								if childObj.parentKey == party.object
								parentParty = party
									break
								end
							end
							if QUESTIONNAIRE_ELEMS == childRetType
								existingQuestionResp = @currentProcessingValues[childRetType]
								existingQuestionResp = existingQuestionResp.merge(childObj)
							elsif PARTY_DO == childRetType && @currentProcessingValues[PARTY_DO].guid != childObj.guid
								#if per party then questionnaire data should be replaced accordingly
								@currentProcessingValues[PARTY_DO] = childObj
								@currentProcessingValues[QUESTIONNAIRE_ELEMS] = getQuestionResponse(currentProcessingPartyDO)
								@currentProcessingValues[DOCUMENT_ELEMS] = getDocuments(childObj.guid)
								@currentProcessingValues[PARTYROLE_DO] = @policy.getPolicyPartyRoleByPartyGuid(childObj.guid)
								@currentProcessingValues[PARTYADDTNL_DO] = childObj.getPartyAdditionalField
							elsif parentParty && @currentProcessingValues[PARTY_DO].guid != parentParty.guid
									#if the current party is not set and the loop is through the address then it implies it is the Party's address
									#this happens in case of Nominee address PolicyDO.getNomineePartyAddressList
									@currentProcessingValues[PARTY_DO] = parentParty
									@currentProcessingValues[PARTYROLE_DO] = @policy.getPolicyPartyRoleByPartyGuid(parentParty.guid)
									@currentProcessingValues[PARTYADDTNL_DO] = parentParty.getPartyAdditionalField
									@currentProcessingValues[DOCUMENT_ELEMS] = getDocuments(parentParty.guid)
									@currentProcessingValues[childRetType] = childObj

							else
								@currentProcessingValues[childRetType] = childObj
							end
							
							modelResultDO = evaluateModel(illustrationModel, childObj, modelResultDO, iftHash, matchedDTList)
						rescue Exception => e
							#if any error has occurred during execution then do not continue with further evaluation
							#this is to enforce that all exceptions in expressions are handled
							Rho::Log.error("Error during model evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
							break
						end
					end
					if numInstances == 0
						Rho::Log.info("No instances found of #{childRetType} to evaluate model #{illustrationModel.modelCd}", LOGCATEGORY)
					end
				end
			elsif illustrationModel.executeIterativelyFl.to_s == "YES"
				#else check if it is iterative model
				Rho::Log.info("Evaluate iteratively ->> #{illustrationModel.executeIterativelyFl}", LOGCATEGORY)
				@breakEvaluation = false
				numInstances = 0
				onceAtEndIllusFacetList = Array.new

				illustrationModel.IllustrationFacetList.each do |ift|
					#this code has been written to separate once at end facets from others and will work for 10-15 records. Incase of performance issues change the logic as per requirement.
					if ift.computationFreqCd.to_s == "ONCEATEND"
						onceAtEndIllusFacetList.push(ift) if onceAtEndIllusFacetList.select{|illusFacet| illusFacet.object == ift.object}.size == 0
					end
				end

				loop do
					#start the loop with 1
					numInstances += 1
					@currentProcessingValues[CURRENT_CYCLE] = numInstances
					Rho::Log.info("Evaluating Solver cycle ->> #{numInstances}", LOGCATEGORY)

					illustrationModel.setIllustrationFacetList illustrationModel.IllustrationFacetList.sort{|x,y| x.computationOrder <=> y.computationOrder}
					modelResultDO = evaluateModel(illustrationModel, policy, modelResultDO, iftHash, matchedDTList)
					Rho::Log.info("breakEvaluation ->> #{@breakEvaluation}", LOGCATEGORY)
					break if @breakEvaluation == true
					break if numInstances == 100
				end

				if onceAtEndIllusFacetList.size > 0
					onceAtEndIllusFacetList.each do |iftPostDtAction|
						evaluatedValue = evaluateElement(iftPostDtAction, policy, modelResultDO)
						modelResultDO.addFieldValue(nil, iftPostDtAction.origElementName, evaluatedValue, iftPostDtAction.elementLabel, iftPostDtAction.computationOrder)
					end
				end
			else
				#else evaluate model once
				modelResultDO = evaluateModel(illustrationModel, policy, modelResultDO, iftHash, matchedDTList)
			end
			# Rho::Log.error("Total Time for the evaluation of model #{dynamicModelCd}: #{Time.now - modelStartTime}", LOGCATEGORY)
			if illustrationModel != nil && illustrationModel.modelFor == "DYNAMICDT"  # For Dynamic DT Evaluation
				return modelResultDO
			elsif illustrationModel != nil
				return modelResultDO
			end

		end
		##################################################################################################

		def evaluateModel(illustrationModel, objToEvaluate, modelResultDO, iftHash, matchedDTList)
			#open file
			if $rhoconfig[:setPolicyModelLog] == 1
				log_file = Array.new
				log_file.push ">>>>>>>>>>>> #{illustrationModel.modelCd} || #{illustrationModel.modelDesc} || #{illustrationModel.modelFor} START <<<<<<<<<<<<<"
			end

			if illustrationModel != nil && illustrationModel.modelFor == "DYNAMICDT"  # For Dynamic DT Evaluation
				iftHash.each do |facetType, iftArray|
					iftArray = iftArray.sort{|x,y| x.computationOrder.to_i <=> y.computationOrder.to_i}
				end

				#Changed this logic to solve rider evaluation DT issue
				illustrationModel.IllustrationFacetList.each do |iftCondition|
					next if iftCondition.entityDataTypeCd == "ACTION" || iftCondition.entityDataTypeCd == "POSTDTACTION"
					evaluatedValue = evaluateElement(iftCondition, objToEvaluate, modelResultDO)
					modelResultDO.addFieldValue(nil, iftCondition.origElementName, evaluatedValue, iftCondition.elementLabel, iftCondition.computationOrder)
					if $rhoconfig[:setPolicyModelLog] == 1
						log_file.push "#{iftCondition.origElementName.ljust(30,' ')}|| #{iftCondition.elementLabel.ljust(50,' ')}>>> #{evaluatedValue}"
					end
				end


			elsif illustrationModel != nil
				#for compute per instance there would be multiple instances of the same rule being triggered..
				#and need to access previous rule values in current rule. for this when the model is evaluated first time
				#the previous rule data does not exist and mvel throws an error.. hence initializing with blank policyresult data.
				#when addModelResultData is called again at the end it will just overwrite the blank values.
				if illustrationModel.computePerInstanceOf.to_s != ""
					addModelResultData(modelResultDO, illustrationModel)
				end
				illustrationModel.IllustrationFacetList.each do |ift|
					currCycleCount = @currentProcessingValues[CURRENT_CYCLE]
					next if ift.computationFreqCd.to_s == "ONCEATEND"

					#for iterative evaluation the computation frequency is set to ONCE for the elements that need not be evaluated every time.
					#so check if the element is already evaluated then do not evaluate again.
					if(ift.computationFreqCd.to_s == "ONCE" && @currentProcessingValues.has_key?("#{ift.origElementName}") && currCycleCount.to_i > 1)
						#do nothing
					else
						evaluatedValue = evaluateElement(ift, objToEvaluate, modelResultDO)
						modelResultDO.addFieldValue(nil, ift.origElementName, evaluatedValue, ift.elementLabel, ift.computationOrder)
						if $rhoconfig[:setPolicyModelLog] == 1
							log_file.push "#{ift.origElementName.ljust(30,' ')}|| #{ift.elementLabel.ljust(50,' ')}>>> #{evaluatedValue}"
						end
						break if @breakEvaluation
					end
					# set the current rule data in hashmap for further processing.
					# since some of the expressions uses previous rule data
					addModelResultData(modelResultDO, illustrationModel)
				end
			end


			if $rhoconfig[:setPolicyModelLog] == 1
				log_file.push ">>>>>>>>>>>> #{illustrationModel.modelCd} || #{illustrationModel.modelDesc} || #{illustrationModel.modelFor} END <<<<<<<<<<<<<\n\n"
				fileName = "#{$logFileReferenceField}.txt"
				Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                downloadFolder = Rho::RhoApplication.get_blob_folder
                filePath = File.join(downloadFolder, fileName)
                log_file.each do |log|
					File.open(filePath, 'a') { |file| file.puts "#{log}" }
				end
			end
			#Close the file

			if illustrationModel != nil && illustrationModel.modelFor == "DYNAMICDT"
				# generate index key
	  			indexKey = ""
	  			if iftHash["CONDITION"] != nil
		  			iftHash["CONDITION"].each do |iftCondition|
		  				if iftCondition.isSystemFl.to_s == "YES" && (iftCondition.rangeValueFl.to_s == "VALUE" || iftCondition.rangeValueFl.to_s == "VALUEEQUALS")
		  					value = modelResultDO.getFieldValue(iftCondition.origElementName)
		  					if value.to_s =~ /^0\d+$/
								indexKey += value.to_s + '|'
							else
								indexKey += (value.to_s.numeric? ? (value.to_i.to_s + '|') : (value.to_s + '|'))
							end
		  				end
		  			end
		  		end
	  			indexKey = indexKey[0,indexKey.length-1] if indexKey.end_with? '|'
	  			if @enableCache
	  				cacheKey = illustrationModel.id.to_s
	  				cacheKey = cacheKey + "|" + indexKey if indexKey.to_s != ""
	  				productModelDesicionTableList = MobiSys::ProductUtil.getFromDynamicDTCache(cacheKey)
	  				unless productModelDesicionTableList
	  					if indexKey.to_s != ""
	  						productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id, {:name => 'indexKey'} => indexKey}, :op => 'AND')
	  					else
	  						productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id})
	  					end
	  					MobiSys::ProductUtil.addToDynamicDTCache(cacheKey,productModelDesicionTableList)
	  				end
	  			else
	  				if indexKey.to_s != ""
	  					productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id, {:name => 'indexKey'} => indexKey}, :op => 'AND')
	  				else
	  					productModelDesicionTableList = ProductModelDecisionTable.loadObject( :all, :conditions => {{ :name => 'illustrationModelSeq'} => illustrationModel.id})
	  				end
	  			end
	  			modelDecisionTableList = nil
	  			modelDecisionTableList = [] if matchedDTList != nil
				modelDecisionTableDO = evaluateModelDynamicDT(objToEvaluate, modelResultDO, iftHash, productModelDesicionTableList, modelDecisionTableList) if productModelDesicionTableList.size > 0
				if modelDecisionTableList != nil && modelDecisionTableList.size > 0
					modelDecisionTableList.each do |mdt|
						tempModelFieldResultDO = MobiSys::DataObjects::FieldResult.new
						evaluateActionPostAction(objToEvaluate, tempModelFieldResultDO, iftHash, mdt)
						matchedDTList.push(tempModelFieldResultDO)
					end
				else
					if modelDecisionTableDO
						evaluateActionPostAction(objToEvaluate, modelResultDO, iftHash, modelDecisionTableDO)
					elsif productModelDesicionTableList.size > 0
						modelResultDO = nil
					end
				end
			end
			return modelResultDO
		end

		def evaluateActionPostAction(objToEvaluate, modelResultDO, iftHash, modelDecisionTableDO)
			iftHash["ACTION"].each do |iftAction|
				value = modelDecisionTableDO.send iftAction.dtColumnNames
				if value
					modelResultDO.addFieldValue(nil, iftAction.origElementName, value, iftAction.elementLabel, iftAction.computationOrder)
					@currentProcessingValues["#{iftAction.origElementName}"] = value

				end
			end
			if iftHash["POSTDTACTION"]
				iftHash["POSTDTACTION"].each do |iftPostDtAction|
					evaluatedValue = evaluateElement(iftPostDtAction, objToEvaluate, modelResultDO)
					modelResultDO.addFieldValue(nil, iftPostDtAction.origElementName, evaluatedValue, iftPostDtAction.elementLabel, iftPostDtAction.computationOrder)
				end
			end
		end

		def evaluateModelDynamicDT(policy, modelResultDO, iftHash, productModelDesicionTableList, modelDecisionTableList = nil)
			modelDecisionTableDO = nil
			policy.entityDesc = ""
			productModelDesicionTableList.each do |mdt|
				flag = false
				tempEntityDesc = ""
				if iftHash["CONDITION"] != nil
					iftHash["CONDITION"].each do |iftCondition|
             				# RhoLog.error("policyutilllll","iftCondition :- #{iftCondition.computedElementName}")
 
						next if iftCondition.rangeValueFl.to_s == ""
						expressCond = false
						mvelExpressValue = modelResultDO.getFieldValue(iftCondition.origElementName) if modelResultDO
						if mvelExpressValue
							columnNames = iftCondition.dtColumnNames
							if iftCondition.rangeValueFl.to_s == "RANGE"
								colNameArr = columnNames.split(",")
								dtValueFrom = mdt.send colNameArr[0]
								dtValueTo = mdt.send colNameArr[1]
								if dtValueFrom && dtValueTo
									tempProductDefinitionTable, expressCond = RangeValueComparator.checkDefinitionTableRange1(dtValueFrom,dtValueTo,mvelExpressValue,nil,nil,nil)
								else
									expressCond = true
								end
							elsif iftCondition.rangeValueFl.to_s == "VALUE" || iftCondition.rangeValueFl.to_s == "VALUEIN" || iftCondition.rangeValueFl.to_s == "VALUENOTIN" || iftCondition.rangeValueFl.to_s == "VALUEEQUALS" || iftCondition.rangeValueFl.to_s == "CONTAINSVALUEIN"
								dtValueToCompare = mdt.send columnNames
								if dtValueToCompare
									if iftCondition.rangeValueFl.to_s == "VALUE" || iftCondition.rangeValueFl.to_s == "VALUEEQUALS"
										mvelExpressValue = mvelExpressValue.to_f if mvelExpressValue.is_a?(Integer) && dtValueToCompare.is_a?(Float)
										mvelExpressValue = mvelExpressValue.to_s if dtValueToCompare.is_a?(String)
										if dtValueToCompare == mvelExpressValue
											expressCond = true
										else
											if dtValueToCompare.to_s.numeric? && mvelExpressValue.to_s.numeric?
												if dtValueToCompare.to_f == mvelExpressValue.to_f
													expressCond = true
												end
											end
										end
									elsif iftCondition.rangeValueFl.to_s == "VALUEIN"
										expressCond = true if dtValueToCompare.split(",").include? mvelExpressValue
									elsif iftCondition.rangeValueFl.to_s == "VALUENOTIN"
										expressCond = true if !dtValueToCompare.split(",").include? mvelExpressValue
									elsif iftCondition.rangeValueFl.to_s == "CONTAINSVALUEIN"
									    expressCond = true if mvelExpressValue.split(",").include? dtValueToCompare
									end
								else
									expressCond = true
								end
							elsif iftCondition.rangeValueFl.to_s == "BOTH"
	    						colNameArr = columnNames.split(",")
	    						dtValueFrom = mdt.send colNameArr[0]
	    						dtValueTo = mdt.send colNameArr[1]
	    						dtValueToCompare = mdt.send colNameArr[2]
	    						if dtValueToCompare.to_s != ""
									if iftCondition.rangeValueFl.to_s == "VALUE" || iftCondition.rangeValueFl.to_s == "VALUEEQUALS"
										mvelExpressValue = mvelExpressValue.to_f if mvelExpressValue.is_a?(Integer) && dtValueToCompare.is_a?(Float)
										mvelExpressValue = mvelExpressValue.to_s if dtValueToCompare.is_a?(String)
										if dtValueToCompare == mvelExpressValue
											expressCond = true
										else
											if dtValueToCompare.to_s.numeric? && mvelExpressValue.to_s.numeric?
												if dtValueToCompare.to_f == mvelExpressValue.to_f
													expressCond = true
												end
											end
										end
									elsif iftCondition.rangeValueFl.to_s == "VALUEIN"
										expressCond = true if dtValueToCompare.split(",").include? mvelExpressValue
									elsif iftCondition.rangeValueFl.to_s == "VALUENOTIN"
										expressCond = true if !dtValueToCompare.split(",").include? mvelExpressValue
									end
	    						elsif dtValueFrom && dtValueTo
									tempProductDefinitionTable, expressCond = RangeValueComparator.checkDefinitionTableRange1(dtValueFrom,dtValueTo,mvelExpressValue,nil,nil,nil)
								else
									expressCond = true
	    						end
	    					end
             				# RhoLog.error("policyutilllll"," iftCondition :- #{iftCondition.computedElementName} -----expressCond :- #{expressCond}")
 
							if expressCond
								if tempEntityDesc.to_s == ""
									tempEntityDesc += MobiSys::BrowserHelper.getLabel(iftCondition.computedElementName) + " (" + MobiSys::BrowserHelper.getLabel(mvelExpressValue.to_s) + ")"
								else
									tempEntityDesc += "," + MobiSys::BrowserHelper.getLabel(iftCondition.origElementName) + " (" + MobiSys::BrowserHelper.getLabel(mvelExpressValue.to_s) + ")"
								end
								flag = true
							else
								flag = false
								break
							end
 
						end
 
					end
				else
					flag = true
					modelDecisionTableDO = mdt
				end
				if flag
					policy.entityDesc += tempEntityDesc if tempEntityDesc != ""
					if modelDecisionTableList != nil
						modelDecisionTableList.push(mdt)
						next
					else
						modelDecisionTableDO = mdt
					end
					break
				else
					modelDecisionTableDO = nil
				end
			end
 
  			return modelDecisionTableDO
		end
		#Method to initialize decision priority and count
		def initializeEvaluationParams(policy, policyProduct, party,illustrationModel="", modelFileName="", tableTypeMappingSeq = nil, quotationIO = nil, currPolicyPayment = nil)
			# @replaceInputElementsPol = $replaceInputElementsPol
			#get all the decisions from lookup and initialize the priority in hashmap to be used for evaluation purpose.
			if party
				@currentProcessingValues[PARTY_DO] 				= party
				@currentProcessingValues[PARTYADDTNL_DO] 		= party.getPartyAdditionalField
				@currentProcessingValues[PARTYROLE_DO] 			= @policy.getPolicyPartyRoleByPartyGuid(party.guid, party.roleCd)
			end
			@currentProcessingValues[CURRENT_UIACTION]			= @policy.action
			@currentProcessingValues[CURRENT_UIFIELD]			= $currentActiveField
			@currentProcessingValues[CURRENT_UITAB]				= $currentActiveTab
			@currentProcessingValues[CURRENT_UISTEP]			= $currentActiveStep
			@currentProcessingValues[POLICY_DO] 				= @policy
			@currentProcessingValues[POLICYADDTNL_DO] 			= @policy.PolicyAdditionalFieldsList[0]
			@currentProcessingValues[POLBASEPLAN_DO] 			= @policy.getBaseProduct
			@currentProcessingValues[QUESTIONNAIRE_ELEMS] 		= getQuestionResponse(party) if party
			@currentProcessingValues[DOCUMENT_ELEMS] 			= getDocuments(party.guid) if party
			# RhoLog.error("@currentProcessingValues[QUESTIONNAIRE_ELEMS]", "@currentProcessingValues[QUESTIONNAIRE_ELEMS] :- #{@currentProcessingValues[QUESTIONNAIRE_ELEMS]}")
			@currentProcessingValues[PROPOSERPARTY_DO] 			= @policy.getPolicyPartyRole("PROPOSER")
			@currentProcessingValues[JOINTPARTY_DO] 			= @policy.getPolicyPartyRole("JOINT")
			if policyProduct
				@currentProcessingValues[PLANPRIMARYINSURED_DO] 	= @policy.getMainInsured(policyProduct)
				@currentProcessingValues[POLPRODUCT_DO] 			= policyProduct
				@currentProcessingValues[POLRIDER_DO] 				= policyProduct
			end
			@currentProcessingValues[AGENT_DO]					= $agentDetails
			@currentProcessingValues[BASE_IO]					= @policy
			@currentProcessingValues[QUOTATION_IO]				= quotationIO
			if quotationIO
				@currentProcessingValues[OG_QUOTATION_DO]		= quotationIO.baseDO.cloneObject 
				product	= MobiSys::ProductUtil.getProduct(quotationIO.baseDO.getBaseProduct.productSeq)
				@currentProcessingValues[PRD_MASTER]			= MobiSys::ProductUtil.getProductData(product)
			end
			if @policy.getBaseProduct
				if @policy.getBaseProduct.PolicyProductInvestmentFundList.length > 0
					@currentProcessingValues[PLANINVESTMENTFUND_DO] = @policy.getBaseProduct.PolicyProductInvestmentFundList[0]
				end
			end
			@currentProcessingValues[:dynamicModelCd]			= illustrationModel.modelCd.upcase
			@currentProcessingValues[:isComputePerInstanceOf]	= illustrationModel.computePerInstanceOf.to_s != "" ? true : false
			@currentProcessingValues[:modelFileName]			= modelFileName
			@currentProcessingValues[:tableTypeMappingSeq]		= tableTypeMappingSeq if tableTypeMappingSeq.to_s != ""
			hmRuleData = {}
			if @policy.additionalData.to_s != "" && @policy.additionalData[OTHERMODELRESULT_DO].to_s != ""
				hmRuleData = @policy.additionalData[OTHERMODELRESULT_DO]
			end
			@currentProcessingValues[OTHERMODELRESULT_DO] 		= hmRuleData
			@currentProcessingValues[POLPAYMENT_DO]				= currPolicyPayment
		end
		##################################################################################################

		def addModelResultData(fieldResultDO, modelDO)
			hmOtherRuleModelResult = @currentProcessingValues[OTHERMODELRESULT_DO]
			if hmOtherRuleModelResult
				#loop through the result data and add the element values
				#if no result exists then add null data since would be required in next evaluation
				if fieldResultDO.fieldValueList.size == 0
					modelDO.IllustrationFacetList.each do |illusFacetDO|
						#if hashmap already contains these values then do not overwrite
						#if it contains one element implies it contains all.
						if hmOtherRuleModelResult.has_key?(modelDO.modelCd.to_s +  "_" + illusFacetDO.origElementName.to_s)
							break
						end
						hmOtherRuleModelResult[modelDO.modelCd.to_s +  "_" + illusFacetDO.origElementName.to_s] = nil
					end
				else
					fieldResultDO.hmFieldValues.keys.each do |elementName|
						hmOtherRuleModelResult[modelDO.modelCd.to_s + "_" + elementName.to_s] = fieldResultDO.getFieldValue(elementName)
					end
				end
			end
			@policy.additionalData[OTHERMODELRESULT_DO] = hmOtherRuleModelResult
		end

		# #Method to get ServiceQuestionResponse records for a specific party or an entity
		# def getQuestionResponse(party)
		# 	hmInsuredQuestion = {}
		# 	hmGridBasedQuestResp = {}
		# 	serviceQuestionResponseList = []
		# 	#either the questionnaires should be for the party or should be for the Agent/Entity (in the case of later the partyGuid would be null
		# 	if party
		# 		serviceQuestionResponseList = party.questionContainer.ServiceQuestionResponseList if party.questionContainer
		# 	else
		# 		serviceQuestionResponseList = @policy.questionContainer.ServiceQuestionResponseList if @policy.questionContainer
		# 	end

		# 	serviceQuestionResponseList.each do |serviceQuestionResponse|
		# 		if serviceQuestionResponse.responseValue.is_a?(Numeric)
		# 			responseValue = serviceQuestionResponse.responseValue.to_f
		# 		else
		# 			responseValue = serviceQuestionResponse.responseValue.to_s
		# 		end
		# 		#if rowguid is not null then it implies it is a grid based question set and there would be multiple responses to the same question set + dataelement
		# 		if serviceQuestionResponse.rowGuid.to_s != ""
		# 			listGridBasedQset = hmGridBasedQuestResp[serviceQuestionResponse.questionSetCd]
		# 			unless listGridBasedQset
		# 				listGridBasedQset = []
		# 				hmGridBasedQuestResp[serviceQuestionResponse.questionSetCd] = listGridBasedQset
		# 			end
		# 			listGridBasedQset.push(serviceQuestionResponse)
		# 		else
		# 			hmInsuredQuestion[serviceQuestionResponse.questionSetCd.to_s + "_" + serviceQuestionResponse.questionDataElementCd.to_s] = responseValue
		# 			hmInsuredQuestion[serviceQuestionResponse.questionSetCd.to_s + "_" + serviceQuestionResponse.questionDataElementCd.to_s + "_" + "Obj"] = serviceQuestionResponse
		# 		end
		# 	end
		# 	#add the grid based service question response as list/records of FieldResultDO
		# 	hmGridBasedQuestResp.keys.each do |gridQuestionSetCd|
		# 		#get the hashmap of values from fieldresultdo and add to arraylist since expression does not understand fieldresultDO
		# 		gridQuestRespResList = MobiSys::CommonUtil.getDTFromQuestionResponse(hmGridBasedQuestResp[gridQuestionSetCd])
		# 		listHmGridResp = []
		# 		gridQuestRespResList.each do |fldResDO|
		# 			#PolicyQuestionSetDO.Medical1_yesNoFl
		# 			hmFldValues = fldResDO.hmFieldValues
		# 			#all the keys will have to be replaced with questionsetcd_dataelementcd
		# 			hmQrespFldValues = {}
		# 			hmFldValues.keys.each do |key|
		# 				hmQrespFldValues[gridQuestionSetCd.to_s + "_" + key.to_s] = hmFldValues[key]
		# 			end
		# 			listHmGridResp.push(hmQrespFldValues)
		# 		end
		# 		hmInsuredQuestion[gridQuestionSetCd] = listHmGridResp
		# 	end

		# 	return hmInsuredQuestion
		# end


		#Method to get ServiceQuestionResponse records for a specific party or an entity
		def getQuestionResponse(party)
			hmInsuredQuestion = {}

			partyQuestMap = @policy&.additionalData&.dig("PARTY_QUEST_MODELMAP")

			if partyQuestMap && partyQuestMap.key?(party.guid) && partyQuestMap[party.guid].is_a?(Hash) && !partyQuestMap[party.guid].empty?
                hmInsuredQuestion = partyQuestMap[party.guid]
            else
				hmGridBasedQuestResp = {}
				serviceQuestionResponseList = []
				#either the questionnaires should be for the party or should be for the Agent/Entity (in the case of later the partyGuid would be null
				if party
					serviceQuestionResponseList = party.questionContainer.ServiceQuestionResponseList if party.questionContainer
				else
					# serviceQuestionResponseList = @policy.questionContainer.ServiceQuestionResponseList if @policy.questionContainer
				end
				if $currentActiveTab.to_s == "tab_requirement" || $currentActiveTab.to_s == "tab_agentDeclaration"
		          questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'entityGuid' => @policy.uniqueKey, 'policyGuid' => @policy.uniqueKey})
		        else
		        	# questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'entityGuid' => party.uniqueKey, 'policyGuid' => @policy.uniqueKey})
		        	questionContainer = party.questionContainer
		        end  
		        # questionContainer = QuestionContainer.loadObject(:all, :conditions=>{'policyGuid' => @policy.uniqueKey})
				$responseHash.merge!(MobiSys::Questionnaire.setupResponseHash(questionContainer)) if questionContainer
				$responseHash.each do |key, value|
					inputType = $inputTypeOfQuestion["#{value.questionSetCd}_#{value.questionDataElementCd}"]
					isNumericVal = true if Float(value.responseValue) rescue false

				 	# key = "#{serviceQuestionResponse.questionSetCd}|#{serviceQuestionResponse.questionDataElementCd}"
	                # key << "|#{serviceQuestionResponse.parentReferencePath}" if serviceQuestionResponse.parentReferencePath.to_s != ""
	                # key << "|#{serviceQuestionResponse.partyGuid}" if serviceQuestionResponse.partyGuid.to_s != ""
	                # key << "|#{serviceQuestionResponse.rowGuid}" if serviceQuestionResponse.rowGuid.to_s != ""
	                responseObj = $responseHash[key] 
	                if responseObj
	                	responseValue = responseObj.responseValue.to_s
						if isNumericVal && inputType && !(inputType.include?"COMBO")
							responseValue = responseObj.responseValue.to_f
							responseValue = responseObj.responseValue.to_i if !!(responseObj.responseValue =~ /^(\d)+$/)
						end
					else
						responseValue = value.responseValue.to_s
						if isNumericVal && inputType && !(inputType.include?"COMBO")
							responseValue = value.responseValue.to_f
							responseValue = value.responseValue.to_i if !!(value.responseValue =~ /^(\d)+$/)
						end

					end
					# if serviceQuestionResponse.responseValue.is_a?(Numeric)
					# 	responseValue = serviceQuestionResponse.responseValue.to_f
					# else
					# 	responseValue = serviceQuestionResponse.responseValue.to_s
					# end
					#if rowguid is not null then it implies it is a grid based question set and there would be multiple responses to the same question set + dataelement
					if value.parentReferencePath.to_s.include?("Heading") || value.parentReferencePath.to_s.include?("TAHL_he")
						if value.rowGuid.to_s != ""
							listGridBasedQset = hmGridBasedQuestResp[value.questionSetCd+"_"+value.parentReferencePath.to_s]
							unless listGridBasedQset
								listGridBasedQset = []
								hmGridBasedQuestResp[value.questionSetCd+"_"+value.parentReferencePath.to_s] = listGridBasedQset
							end
							listGridBasedQset.push(value)
						else
							hmInsuredQuestion[value.questionSetCd.to_s + "_" + value.questionDataElementCd.to_s+"_"+value.parentReferencePath.to_s] = responseValue
							hmInsuredQuestion[value.questionSetCd.to_s + "_" + value.questionDataElementCd.to_s+"_"+value.parentReferencePath.to_s+ "_" + "Obj"] = value
							hmInsuredQuestion[value.questionSetCd.to_s + "_" + value.questionDataElementCd.to_s + "_" + "Obj"] = value
						end
					else
						hmInsuredQuestion[value.questionSetCd.to_s + "_" + value.questionDataElementCd.to_s] = responseValue
						hmInsuredQuestion[value.questionSetCd.to_s + "_" + value.questionDataElementCd.to_s + "_" + "Obj"] = value
					end
				end
				#add the grid based service question response as list/records of FieldResultDO 
				hmGridBasedQuestResp.keys.each do |gridQuestionSetCd|
					#get the hashmap of values from fieldresultdo and add to arraylist since expression does not understand fieldresultDO
					gridQuestRespResList = MobiSys::CommonUtil.getDTFromQuestionResponse(hmGridBasedQuestResp[gridQuestionSetCd])
					listHmGridResp = []
					gridQuestRespResList.each do |fldResDO|
						#PolicyQuestionSetDO.Medical1_yesNoFl
						hmFldValues = fldResDO.hmFieldValues
						#all the keys will have to be replaced with questionsetcd_dataelementcd
						hmQrespFldValues = {}
						hmFldValues.keys.each do |key|
							hmQrespFldValues[gridQuestionSetCd.to_s + "_" + key.to_s] = hmFldValues[key]
						end
						listHmGridResp.push(hmQrespFldValues)
					end
					hmInsuredQuestion[gridQuestionSetCd] = listHmGridResp
				end
				partyWiseQuestMap = {}
				if @policy.additionalData.to_s != "" && @policy.additionalData["PARTY_QUEST_MODELMAP"].to_s != ""
				# if @policy&.additionalData&.dig("PARTY_QUEST_MODELMAP")
					partyWiseQuestMap = @policy.additionalData["PARTY_QUEST_MODELMAP"]
				end
				partyWiseQuestMap[party.guid] = hmInsuredQuestion
				@policy.additionalData["PARTY_QUEST_MODELMAP"] = partyWiseQuestMap
			end
			hmInsuredQuestionDot = hmInsuredQuestion.to_dot
			return hmInsuredQuestionDot
		end
		##################################################################################################

		#Method to evaluate expression
		def evaluateExpression(illusFacetDO, objToEvaluate)
			evaluatedValue = nil
			#here check if compiled expression exists then use it else do MVEL.eval
			begin
				#########################Code commented cause compiled expressions are not available in offline
				# if illusFacetDO.compiledExpression.to_s != ""
					# evaluatedValue = eval(illusFacetDO.expression)
					expressionKey = illusFacetDO.expression.gsub(" ","")
					# Rho::Log.error("~~expressionKey:#{expressionKey}", LOGCATEGORY)
					if !@currentProcessingValues[:isComputePerInstanceOf] and @expressionHash and @expressionHash.has_key?(expressionKey) and @callFrom != "QUESTIONNAIRE"
						evaluatedValue = @expressionHash[expressionKey]
						# Rho::Log.error("~~getting value from @expressionHash :#{evaluatedValue}", LOGCATEGORY)

					else
					# 	# Rho::Log.error("~~in else", LOGCATEGORY)
						# methodName = illusFacetDO.computedElementName
						# objClass = Object::const_get("PolicyUtil::PolicyModel::#{@currentProcessingValues[:dynamicModelCd]}")
						# evaluatedValue = objClass.send(methodName, @currentProcessingValues)
						# if @currentProcessingValues[:dynamicModelCd].to_s == "DEFAULTINAGENT"
						# 	evaluatedValue = eval("PolicyModel::#{@currentProcessingValues[:dynamicModelCd]}.#{illusFacetDO.computedElementName}(@currentProcessingValues)")
						# else
							evaluatedValue = eval(illusFacetDO.expression)
							if illusFacetDO.expression.include?("QUESTIONNAIRE_ELEMS") && illusFacetDO.expression.count('=') == 1 #&& ["DEFAULTINAGENT"].include?(@currentProcessingValues[:dynamicModelCd].to_s)
								leftSide = illusFacetDO.expression.split('=').first.strip
								beforeLastDot = fixUnbalancedBrackets(leftSide.rpartition('.').first)
								objectToSave = eval(beforeLastDot)
								if objectToSave.class.name.to_s == "ServiceQuestionResponse" && objectToSave.respond_to?(:save)
									objectToSave.persistAll
								end
							end
						# end
						# if @callFrom == "QUESTIONNAIRE"
						# 	evaluatedValue = eval("PolicyModel::#{@currentProcessingValues[:dynamicModelCd]}.#{illusFacetDO.computedElementName}(@currentProcessingValues)")
						# else
							# evaluatedValue = eval(illusFacetDO.expression)
							if !@currentProcessingValues[:isComputePerInstanceOf] and @expressionHash != nil
						# 		# Rho::Log.error("~~adding into @expressionHash", LOGCATEGORY)

								@expressionHash[expressionKey] = evaluatedValue
							end
						# end
					end

					# require @currentProcessingValues[:modelFileName]
					# puts "~~~~~@currentProcessingValues:#{@currentProcessingValues}"
					
					@breakEvaluation = true if evaluatedValue.to_s == "break"
				# else
				# 	evaluatedValue = MVEL.executeExpression(illusFacetDO.compiledExpression, objToEvaluate, currentProcessingValues)
				# end
			rescue Exception => e
				Rho::Log.error("Error during expression evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				#if there is error in evaluation then check if it is an expression based on Questionnaire
				#if so do not mark as erroneous since questionnaire response may not be present in cases like conditional questionnaire etc.
				#likewise while checking for previous rule result data. eg. if there are no grid question rows then there will be no result objects as well.
				if illusFacetDO.expression.include?(QUESTIONNAIRE_ELEMS + ".") || illusFacetDO.expression.include?(OTHERMODELRESULT_DO + ".")
					Rho::Log.info("No response found for questionnnaire/model while evaluating expression: " + illusFacetDO.expression.to_s + " " + e.to_s, LOGCATEGORY)
				else
					logModelError(illusFacetDO, objToEvaluate, evaluatedValue, e, true)
				end
			end

			return evaluatedValue
		end
		##################################################################################################

		def fixUnbalancedBrackets(expr)
		    open_count = expr.count('(')
		    close_count = expr.count(')')
		    if open_count > close_count
		      expr + (')' * (open_count - close_count))
		    elsif close_count > open_count
		      ('(' * (close_count - open_count)) + expr
		    else
		      expr
		    end
		  end

		#Method evaluates model elements based on element type invokes MVEL, Fixed/Dynamic DT
		def evaluateElement(illusFacetDO, objToEvaluate, modelFieldResult)
			fldStartTime = Time.now.to_i
			evaluatedValue = nil
			#maintain the stack trace of each element being evaluated for every result.
			fldResultElem = MobiSys::DataObjects::FieldResult.new
			#set object name for ui purpose
			fldResultElem.objectName = "PolicyModelResultElem"
			fldResultElem.addFieldValue(nil, "elementName", illusFacetDO.elementLabel, "Element")
			if @currentProcessingValues[QUOTATION_IO] != nil
				quotationIO = @currentProcessingValues[QUOTATION_IO]
				quotation = quotationIO.baseDO
				# quotationIO = MobiSys::IO::QuotationIO.new
				# quotationIO.baseDO = @currentProcessingValues[OG_QUOTATION_DO].cloneObject
				# quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(@currentProcessingValues[OG_QUOTATION_DO])
			else
				if $quotation
					quotation = $quotation
				else
					quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
				end
				quotationIO = MobiSys::IO::QuotationIO.new
		        quotationIO.baseDO = quotation.cloneObject
		        quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
		        @currentProcessingValues[QUOTATION_IO] = quotationIO
		    end
			#evaluate expression
			if illusFacetDO.facetTypeCd == COMPUTEDFORMULA && illusFacetDO.expression.to_s != ""
				expForDisplay = illusFacetDO.expression.to_s == "" ? "" : illusFacetDO.expression.to_s.gsub!("\"", "")
				exp = $parentReferenceForPolModel ? illusFacetDO.expression.to_s.gsub('$PARENTREFPATH$',$parentReferenceForPolModel) : illusFacetDO.expression.to_s
				#exp = $parentForPolModel ? ift.expression.to_s.gsub('$PARENT$',$parentForPolModel) : ift.expression.to_s
				illusFacetDO.expression = $parentForPolModel ? exp.to_s.gsub('$PARENT$',$parentForPolModel) : exp.to_s
				# fldResultElem.addFieldValue(nil, "expression", expForDisplay, "Expression")
				# evalExpression = logModelError(illusFacetDO, objToEvaluate, evaluatedValue, nil, false)
				# evalExpression = evalExpression.to_s.gsub!("\"", "")
				# fldResultElem.addFieldValue(nil, "evalExpression", evalExpression, "Expression evaluated")
				evaluatedValue = evaluateExpression(illusFacetDO, objToEvaluate)
			elsif illusFacetDO.facetTypeCd == COMPUTEDDECISIONTBL && illusFacetDO.ruleSeq.to_s != ""
				#here evaluate the fixed DT
				evaluatedValue = evaluateFixedDT(illusFacetDO, illusFacetDO.ruleSeq, objToEvaluate)
				fldResultElem.addFieldValue(nil, "expression", @policy.getEntityDesc, "Fixed DT")
				fldResultElem.addFieldValue(nil, "evalExpression", "", "Expression evaluated")
			elsif illusFacetDO.facetTypeCd == DYNAMICDECISIONTBL && illusFacetDO.facetId.to_s != ""
				#here evaluate the dynamic Rule as the Rule name is stored in the facetId column
				#the dynamic DT works on the elements in the model hence pass the modelFieldResult as the object to evaluate
				matchedDT = evaluateDynamicDT(illusFacetDO.facetId, modelFieldResult)
				fldResultElem.addFieldValue(nil, "expression", matchedDT == nil ? "No matching DT record found" : matchedDT.hmFieldValues.to_s, "Decision table")
				fldResultElem.addFieldValue(nil, "evalExpression", "", "Expression evaluated")
				evaluatedValue = modelFieldResult.getFieldValue(illusFacetDO.origElementName)
			elsif illusFacetDO.facetTypeCd == OUTPUTFRMDYNAMICDT
				#here the value would have already been added as action of the dynamic DT defined above
				evaluatedValue = modelFieldResult.getFieldValue(illusFacetDO.origElementName)
			elsif illusFacetDO.facetTypeCd.to_s == ILLUSTRATIONMODEL || illusFacetDO.facetTypeCd.to_s == PRDFACETIMMODEL
				#here we need to call the entire Illustration Model evaluation. this is typically used for Solvers.
				evaluatedValue = nil
				illModelDOSolver = nil
			    # we need to clone the Quotation data for each cycle since this data should not be used in the next cycle.
			    clonedQuotationIO = MobiSys::IO::QuotationIO.new
			    clonedQuotationIO.baseDO = quotationIO.baseDO
				clonedQuotationIO.baseProduct = quotationIO.baseProduct

				if illusFacetDO.facetId.to_s != ""
					#the facet id will contain the actual model code of Illustration Model
					# illModelDOSolver = MobiSys::ProductBO.loadModel(illusFacetDO.facetId, quotationIO)
					illModelDOSolver = IllustrationModel.loadObject(:first, :conditions => {{ :name => 'modelCd' } => illusFacetDO.facetId.to_s})

					if(illModelDOSolver == nil)
						puts"<<<<<<<<<<<Error No Master defined for Model code " + illusFacetDO.facetId.to_s
						# throw new SymbiosysRuntimeException("No Master defined for Model code " + modelCd);
					end
					quotationIO.illustrationModel = illModelDOSolver
					##verify topup value here
		        	quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO) if illModelDOSolver.to_s != ""
		        	@currentProcessingValues[QUOTATION_IO] = quotationIO #if  @currentProcessingValues[QUOTATION_IO] == nil
		        	# quotationIO.baseDO = @currentProcessingValues[OG_QUOTATION_DO].cloneObject
					if @currentProcessingValues[OG_QUOTATION_DO]
						quotationIO.baseDO = @currentProcessingValues[OG_QUOTATION_DO].cloneObject
					else
						quotationIO.baseDO = @currentProcessingValues[QUOTATION_IO].baseDO.cloneObject
					end
					if @currentProcessingValues[OG_QUOTATION_DO]
						
						quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(@currentProcessingValues[OG_QUOTATION_DO])
					else
						quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(quotationIO.baseDO)
					end
					isModelEvalReqd = true

					if illusFacetDO.inputDataElement.to_s != ""
						conditionalVal = @currentProcessingValues["Computed_#{illusFacetDO.inputDataElement}_end"]
						if conditionalVal.to_s != ""
							isModelEvalReqd = conditionalVal
						end
					end

					if isModelEvalReqd
						modelCd = illusFacetDO.facetId.to_s
						if illusFacetDO.facetTypeCd.to_s == PRDFACETIMMODEL
							if(illusFacetDO.facetId.to_s == "SIMODEL")
								# FacetDO otherDetailsFacet = this.dataObject.getFacetDO(ParameterDataConstants.FACET.OTHERDETAILS);
								# OtherDetailsDO otherDetailsDO = otherDetailsFacet.getOtherDetailsDO();
								# modelCd = otherDetailsDO.getIllustrationFormat();
								product = MobiSys::ProductUtil.getProduct(quotationIO.baseProduct.productSeq)
								otherDetailsFacet = product.getFacetFast("OTHERDETAILS")
								if otherDetailsFacet
									otherDetailsDO = otherDetailsFacet.OfflineOtherDetailsList[0]
									modelCd = otherDetailsDO.illustrationFormat
								end
							else
								product = MobiSys::ProductUtil.getProduct(quotationIO.baseProduct.productSeq)
								modelCd = product.getFacetFast(illusFacetDO.facetId.to_s).actionValue
							end
							
						end
						# the facet id will contain the actual model code of Illustration Model
						illModelDOSolver = ModelUtil.getIllustrationModel(modelCd)
						clonedQuotationIO.illustrationModel = illModelDOSolver
						# Set the PolicyDO as well
						# Removed the setting of PolicyDO since every time the IM is called new Policy
						# should be created since once the IM runs the Policy values are incremented till the end of the term.

						# After all we need to set the PolicyDO since these values itself are used in the IM for solvers.
						# but will be cloning the current PolicyDO itself
						clonedQuotationIO.addModelAdditionalParams("CONSIDER_EXIST_POLICY", true)
						clonedQuotationIO.addModelAdditionalParams("SOLVER_CALL", quotationIO.getModelAdditionalParams["SOLVER_CALL"])
						clonedQuotationIO.addModelAdditionalParams("SOLVERMODELRESULTS", quotationIO.getModelAdditionalParams["SOLVERMODELRESULTS"])
						# clonedQuotationIO.addModelAdditionalParams("FIELD_NAMES_SET", quotationIO.getModelAdditionalParams["FIELD_NAMES_SET"])
						# clonedQuotationIO.addModelAdditionalParams("EXIST_RESULT", quotationIO.listCalculation)
						# clonedQuotationIO.addModelAdditionalParams("EXIST_HDR_RESULT", quotationIO.illustrationHeader)
						# clonedQuotationIO.addModelAdditionalParams("EXIST_RIDER_RESULT", quotationIO.hmRiderComputedAttributes)
						# clonedQuotationIO.addModelAdditionalParams("EXIST_FUND_RESULT", quotationIO.hmFundComputedAttributes)

						currCycleCount = @currentProcessingValues[CURRENT_CYCLE]
						clonedQuotationIO.loopReference = currCycleCount.to_s if currCycleCount != nil
						clonedQuotationIO = MobiSys::ProductBO.callCalculateIllustration(clonedQuotationIO)
						# copy the results from the cloned object to the main IO since next elements would be using the value as of functionality.
						quotationIO.results = clonedQuotationIO.results

						quotationIO.listCalculation = clonedQuotationIO.listCalculation
						quotationIO.illustrationHeader = clonedQuotationIO.illustrationHeader
						# even the IllustrationModelDO is required for value as of functions so setting that as well
						quotationIO.illustrationModel = clonedQuotationIO.illustrationModel
						# even the ModelAdditionalParams is required for value as of functions so setting that as well
						quotationIO.setModelAdditionalParams(clonedQuotationIO.getModelAdditionalParams)
						@currentProcessingValues["modelTotalCycles"] = clonedQuotationIO.getModelAdditionalParams["modelTotalCycles"]
						@currentProcessingValues[QUOTATION_IO] = quotationIO
					end
				end
			elsif illusFacetDO.facetTypeCd.to_s == RULEMODEL || illusFacetDO.facetTypeCd.to_s == SOLVERMODEL
				if illusFacetDO.facetId.to_s != ""
					# Check if there is any conditional element is being used for DT. Since DT need not be evaluated every cycle.
					# EntityFieldTypeCd is being used as Conditional element name as didnt want to add more attributes
					isModelEvalReqd = true

					if illusFacetDO.inputDataElement.to_s != ""
						conditionalVal = @currentProcessingValues["Computed_#{illusFacetDO.inputDataElement}_end"]
						if conditionalVal.to_s != ""
							isModelEvalReqd = conditionalVal
						end
					end
					if isModelEvalReqd
						# the facet id will contain the actual model code of the Policy/DT Model
						modelCd = illusFacetDO.facetId.to_s
						# quotationIO.baseDO = @currentProcessingValues[OG_QUOTATION_DO].cloneObject
						if @currentProcessingValues[OG_QUOTATION_DO]
							quotationIO.baseDO = @currentProcessingValues[OG_QUOTATION_DO].cloneObject
						else
							quotationIO.baseDO = @currentProcessingValues[QUOTATION_IO].baseDO.cloneObject
						end
						# quotationIO.baseProduct = MobiSys::QuotationBO.getBaseProduct(@currentProcessingValues[OG_QUOTATION_DO])
						if @policy
							policy = @policy
						else
							policy = MobiSys::PolicyBO.convertToPolicy(quotationIO.baseDO)
						end
						party = policy.getParty("PRIMARY")
						policy.additionalData = @policy.additionalData if @policy.additionalData != nil
						policyProduct = policy.getBaseProduct if policy
						policyModel = PolicyUtil::PolicyModel.new
						modelResultDO = policyModel.execute(policy, policyProduct, party, modelCd, nil, nil, nil, quotationIO)
					end
				end
			elsif illusFacetDO.facetTypeCd.to_s == ADDTNL_IM_EVAL_PARAMS
				if quotationIO
					evaluatedValue = evaluateExpression(illusFacetDO, objToEvaluate)
					hmAddtnlEvalParams = quotationIO.getModelAdditionalParams["ADDITIONAL_EVAL_PARAMS"]
					hmAddtnlEvalParams = {} if hmAddtnlEvalParams == nil
					hmAddtnlEvalParams[illusFacetDO.computedElementName] = evaluatedValue
					quotationIO.addModelAdditionalParams("ADDITIONAL_EVAL_PARAMS", hmAddtnlEvalParams)
				end
			elsif illusFacetDO.facetTypeCd == COMPUTEDLOOKUP && illusFacetDO.expression.to_s != ""
				#for computed lookup they would be using group functions present in QuotationIO
				expForDisplay = illusFacetDO.expressionForDisplay.to_s == "" ? "" : illusFacetDO.expressionForDisplay.to_s.gsub!("\"", "")
				fldResultElem.addFieldValue(nil, "expression", expForDisplay, "Expression")
				evalExpression = logModelError(illusFacetDO, objToEvaluate, evaluatedValue, nil, false) if $rhoconfig[:setPolicyModelLog] == 2
				evalExpression = evalExpression.to_s.gsub!("\"", "")
				fldResultElem.addFieldValue(nil, "evalExpression", evalExpression, "Expression evaluated")
				evaluatedValue = evaluateExpression(illusFacetDO, @currentProcessingValues[QUOTATION_IO])
			end
			fldResultElem.addFieldValue(nil, "elementValue", evaluatedValue.to_s, "Element value")
			# This log is required only if we need to display the results post execution else we dont need to hold onto the fldResultElem
			fldResultElem.addFieldValue(nil, "timeTaken", (Time.now.to_i - fldStartTime), "Time taken")
			#add each element to the Row model result object
			modelFieldResult.addFieldResult(fldResultElem)
			# evaluatedValue = 0 if !evaluatedValue.is_a?(Array) && !evaluatedValue.is_a?(Hash) && ![true, false].include?(evaluatedValue) && evaluatedValue.to_f.infinite?
			
			evaluatedValue = 0 if evaluatedValue.nil? && !evaluatedValue.is_a?(Array) && !evaluatedValue.is_a?(Hash) && ![true, false].include?(evaluatedValue) && evaluatedValue.to_f.infinite?

			# evaluatedValue = 0 if !evaluatedValue.is_a?(Array) && !evaluatedValue.is_a?(Hash) && (evaluatedValue.nil? || evaluatedValue.to_f.infinite?)


			evaluatedValueDataType = ""
			if illusFacetDO.entityFieldTypeCd.to_s != ""
				entityTypeDO = $entityTypeCache[illusFacetDO.entityFieldTypeCd.to_sym] if $entityTypeCache
				evaluatedValueDataType = entityTypeDO.dataTypeCd.to_s if entityTypeDO
			end
			if evaluatedValueDataType == "STRING"
				evaluatedValue = evaluatedValue.to_s
			elsif evaluatedValue.to_s.match(/^[\d]+$/)
				evaluatedValue = evaluatedValue.to_i
			elsif defined?(BigDecimal) && Float.method_defined?(:to_d) && evaluatedValue.to_s.match(/^[\d\.]+$/) && $rhoconfig[:useBigDecimal]
				evaluatedValue = evaluatedValue.to_s.to_d
			elsif evaluatedValue.to_s.match(/^[\d\.]+$/)
				evaluatedValue = evaluatedValue.to_f
			else
				evaluatedValue = evaluatedValue.to_s
			end
			Rho::Log.info("Element->>#{illusFacetDO.computedElementName}:#{evaluatedValue}", LOGCATEGORY)
			# @currentProcessingValues["Computed_#{illusFacetDO.origElementName}_end"] = evaluatedValue
			@currentProcessingValues["#{illusFacetDO.computedElementName}"] = evaluatedValue
			#if the field value is not already existing then add it to the FieldResultDO
			if !modelFieldResult.containsFieldInMap(illusFacetDO.origElementName)
				modelFieldResult.addFieldValue(nil, illusFacetDO.origElementName, evaluatedValue, illusFacetDO.elementLabel, illusFacetDO.computationOrder)
			end

			return evaluatedValue
		end
		##################################################################################################

		def logModelError(illusFacetDO, objToEvaluate, evaluatedValue, exception, setError)
			expression 	= illusFacetDO.expression
			modelCd 	= ""
			modelFor 	= ""
			modelObj 	= nil
			if illusFacetDO.parentKey
				modelObj = IllustrationModel.loadObject(
					:first,
					:conditions => {
						:object => illusFacetDO.parentKey
					}
				)
				if modelObj
					modelCd 	= modelObj.modelCd
					modelFor 	= modelObj.modelFor
				end
			end
			finalExpression = ""
			trimExp 	= expression.strip
			miniExpVal 	= nil
			isValidExp 	= false
			begin
				miniExpVal = eval(trimExp)
				isValidExp = true
			rescue Exception => e
				#expression replacement for underwriting. since expression is compiled and is replaced before compiling.
				$replaceInputElementsPol.keys.each do |replaceExp|
					trimExp = trimExp.gsub(replaceExp, $replaceInputElementsPol[replaceExp])
				end
				begin
					miniExpVal = eval(trimExp)
					isValidExp = true
				rescue Exception => e
					Rho::Log.error("Error while evaluating expression: #{trimExp}\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				end
			end
			if isValidExp
				finalExpression = finalExpression + " " + miniExpVal.to_s
			else
				finalExpression = finalExpression + " " + trimExp
			end
			if setError
				errMessage = "Error in expression evaluation for, " + modelFor.to_s + " Model: " + modelCd.to_s + ", Element name: " + illusFacetDO.computedElementName.to_s + ", Element Label: " +  illusFacetDO.elementLabel.to_s + ", Evaluated value: " + evaluatedValue.to_s + ", Original expression: " + illusFacetDO.origExpression.to_s + ", Replaced expression: " + expression.to_s + ", Evaluated expression: " + finalExpression.to_s

				errMessage = errMessage.to_s + ", Exception: " + e.to_s if e
				Rho::Log.info(errMessage, LOGCATEGORY)
				#retain the first error
				unless @message
					@message = errMessage
					@output = "ERROR"
					@errored = true
				end
			end
			return finalExpression
		end
		##################################################################################################

		#Method performs dynamic DT evaluation
		def evaluateDynamicDT(ruleName, objToEvaluate)
			matchedDT = nil
			begin
				ruleCalculator = MobiSys::RuleCalculator.new
				ruleCalculator.ruleName = ruleName
				ruleCalculator.facet = ruleName
				matchedDT = ruleCalculator.evaluateRule(objToEvaluate)
				Rho::Log.info("Dynamic DT->>#{ruleName}" + (matchedDT == nil ? " No matching record" : " Matching record found at: #{matchedDT.hmFieldValues}"), LOGCATEGORY)
			rescue Exception => e
				Rho::Log.error("Error during dynamic DT evaluation\n#{e}\n#{e.backtrace}", LOGCATEGORY)
				#retain the first error
				if @message.to_s == ""
					@message = "Error evaluation Dynamic DT Rule: #{ruleName} #{e}"
					@output = "ERROR"
					@errored = true
				end
			end
			return matchedDT
		end
		##################################################################################################


		#Method performs fixed DT evaluation
		def evaluateFixedDT(illusFacetDO, tableTypeMappingSeq, objToEvaluate)
			evaluatedValue 			= nil
			policyProduct 			= @policy.getBaseProduct
			policyProductInsured 	= nil
			policyPayment 			= nil
			party 					= nil
			#initialize all the fixed elements that need to be passed to the DT
			if @policy.PolicyPaymentList.size > 0
				policyPayment = @policy.PolicyPaymentList[0]
			end

			if objToEvaluate.is_a?(PolicyProductInsured)
				policyProductInsured = objToEvaluate
				@policy.PolicyProductList.each do |policyProductObj|
					if policyProductObj.object == policyProductInsured.parentKey
						policyProduct = policyProductObj
						break
					end
				end

				if policyProductInsured.refGuid.to_s != ""
					party = @policy.getPartyByGuid(policyProductInsured.refGuid)
				end

				unless party
					party = @policy.getMainInsured(policyProduct)
				end
			elsif objToEvaluate.is_a?(Party)
				party = objToEvaluate
			end

			if policyProductInsured == nil && policyProduct.PolicyProductInsuredList.size > 0
				policyProductInsured = policyProduct.PolicyProductInsuredList[0]
			end

			if $quotation
				quotation = $quotation
			else
				quotation = MobiSys::PolicyBO.convertToQuotation(@policy)
			end
			baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
			primary = quotation.getMainInsured(baseProduct)

			#check if some additional computed field needs to be passed to the decision table if so then set that in additional DO and pass to DT
			if illusFacetDO != nil && illusFacetDO.computedFieldNameForRule.to_s != ""
				valueToSet = @currentProcessingValues["#{illusFacetDO.origElementName}"]
				#setting the computed value in field 12 .. generally
				quotation.quotAddtnlField12 = valueToSet.to_s if valueToSet.to_s != ""
			end
			dt = MobiSys::ProductUtil.getProductDefinitionTableDO(tableTypeMappingSeq, quotation, baseProduct, primary)
			if dt
				if dt.rate.to_s != ""
					evaluatedValue = dt.rate
				elsif dt.outputAction.to_s != ""
					evaluatedValue = dt.outputAction
				end
			end
			return evaluatedValue
		end
		##################################################################################################

		def getDocuments(partyGuid)
			hmDocCatg = {}
			hmEvalDocs = {}
			hmEvalDocsDot = nil
			# if @policy.additionalData.to_s != "" && @policy.additionalData["PARTY_DOC_MODELMAP"].to_s != "" && @policy.additionalData["PARTY_DOC_MODELMAP"].has_key?("#{partyGuid}")
			if @policy&.additionalData&.dig("PARTY_DOC_MODELMAP")&.key?(partyGuid)
				hmEvalDocsDot = @policy.additionalData["PARTY_DOC_MODELMAP"][partyGuid]
			else
				
				serviceDocListForParty = $partyWiseDocumentCategoryCdHM[partyGuid] if $partyWiseDocumentCategoryCdHM

				hmDocCatg = MobiSys::CommonUtil.getLinkedHashedList("docCategoryCd",serviceDocListForParty) if serviceDocListForParty
				
				hmDocCatg.keys.each do |docCatgCd|
					hmDocCd = MobiSys::CommonUtil.getLinkedHashedList("documentCd", hmDocCatg[docCatgCd])
					hmEvalDocs[docCatgCd] = hmDocCd unless hmDocCd.nil? || hmDocCd.empty?
				end
				
				partyDocumentContainer = DocumentContainer.loadObject(
			            :first,
			            :conditions=>{
			            {:name=>'entityGuid'}=> partyGuid,
			            {:name=>'policyGuid'}=> @policy.uniqueKey
			        }
			        )
				if partyDocumentContainer
					# All selected documents get in ALLSELECTEDDOCUMENTS hashmap key,so that check document as PolicyDocumentDO.ALLSELECTEDDOCUMENTS['PASSPORT']
					documentCdHM = {}
					partyDocumentContainer.ServiceDocumentList.each do |serviceDocumentDO|
						documentCdHM[serviceDocumentDO.documentCd] = serviceDocumentDO if serviceDocumentDO.selected.to_s == "YES"
					end
					
					hmEvalDocs["ALLSELECTEDDOCUMENTS"] = documentCdHM
				end
				
				
				hmEvalDocsDot = ::JSON.parse(hmEvalDocs.to_json, object_class:OpenStruct)
				
				partyWiseDocMap = {}
				# if @policy.additionalData.to_s != "" && @policy.additionalData["PARTY_DOC_MODELMAP"].to_s != ""
				if @policy&.additionalData&.dig("PARTY_DOC_MODELMAP")
					partyWiseDocMap = @policy.additionalData["PARTY_DOC_MODELMAP"]
				end
				partyWiseDocMap[partyGuid] = hmEvalDocsDot
				@policy.additionalData["PARTY_DOC_MODELMAP"] = partyWiseDocMap
				
			end

			return hmEvalDocsDot
		end
	end

	class PolicyModelSet
		include MobiSys::BrowserHelper
		LOGCATEGORY					= "PolicyModelSet"

		def getModelSetModelList(policy, policyProduct, party, modelSetCd, quotationIO = nil)
			modelSetModelMapDOList = []
			policyModelSet = nil
			illustrationModelList = {}
			policyModelSet,illustrationModelList = PolicyUtil::ModelUtil.getModelSetAndModels(modelSetCd)
				if policyModelSet
				modelSetModelMapDOList = policyModelSet.ModelSetModelMapList
				# expressionHash = {}
				# Evaluates the Model added in modelCd and its value will be set on Output action element
				# In list only the DT model will be add whose filter value matches to Output action element
				if policyModelSet.modelCd.to_s != "" && policyModelSet.outputActionElement.to_s != "" && $productIdExist
					policyModel = PolicyUtil::PolicyModel.new
					modelResultDO = policyModel.execute(policy, policyProduct, party, policyModelSet.modelCd, nil, nil, nil, quotationIO)
					if modelResultDO
						fieldValue = modelResultDO.getFieldValue(policyModelSet.outputActionElement)
						if fieldValue.to_s != ""
							modelSetModelMapDOList = []
							policyModelSet.ModelSetModelMapList.each do |modelSetModelMap|
								if fieldValue.to_s == modelSetModelMap.filterValue.to_s
									modelSetModelMapDOList << modelSetModelMap
								elsif modelSetModelMap.filterValue.to_s == ""
									# If filter value is not added then add into the list
									modelSetModelMapDOList << modelSetModelMap
								end
							end
						end
					end
				end
			end
			return modelSetModelMapDOList, illustrationModelList
		end


		def execute(policy, policyProduct, party, modelSetCd, quotationIO = nil)
			begin
					expressionHash = {}
				modelSetModelMapDOList, illustrationModelList = getModelSetModelList(policy, policyProduct, party, modelSetCd, quotationIO)
				modelSetModelMapDOList.each do |modelSetModelMap|
						policyModel = PolicyUtil::PolicyModel.new
						modelResultDO = policyModel.execute(policy, policyProduct, party, modelSetModelMap.modelCd, nil, nil, nil, quotationIO,nil,expressionHash, illustrationModelList)
					end
			rescue Exception => e
				Rho::Log.error("Error in policy model set evaluation in PolicyUtil --->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
		end

	end
end

begin
    require 'Policy/PolicyUtil_company'
rescue LoadError => e
    puts 'PolicyUtil_company not included'
end

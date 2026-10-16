require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/settings.rb'
require 'CommonModules/metadata'
require 'erb'
require 'CommonModules/sym_template_util'
require 'Policy/PolicyUtil'
require 'Product/product_util'
require 'json'


class BaseRestController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper
	include MobiSys
	include MobiSys::SymTemplateUtil


	LOGCATEGORY = "BaseApiController"

	def initialize(io, entity)
		# logInfo("~~~in base rest initialize io:#{io}")
		@baseIO = io
		@entityClass = entity
		$entityClassName = entity
		$replaceInputElementsPol = PolicyUtil::ModelUtil.getExpressionReplacementList("POLICY")
        $agentDetails = AgentReg.getCurrentAgentReg
		MobiSys::Validation.initializeValidationHash unless $validationHash
		MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
		MobiSys::UIMetaData.initializeDataElement unless $dataElementCache
		MobiSys::UIMetaData.initializeEntityType unless $entityTypeCache
		MobiSys::ContextMasterData.initializeContextMasterHash  unless $contextMasterCache
		MobiSys::MetaData.initializeMetadataHash unless $metadataMasterHash
		#For product metadata
		MobiSys::ProductMetaData.initializeProductMetaDataHash unless $productMetaDataCache
		$contextMasterEvalHash = {} if $contextMasterEvalHash== nil || $contextMasterEvalHash.class.to_s != "Hash"
		$parentChildGuidMapping = {} if $parentChildGuidMapping== nil || $parentChildGuidMapping.class.to_s != "Hash"
		$guidClassNameMap = {} if $guidClassNameMap== nil || $guidClassNameMap.class.to_s != "Hash"
		initializeDataXMLHash unless eval("$#{@entityClass}DataXMLHash")

		$metadatafieldsmapCache = Lookupvalue.createLookupCache(["METADATAFIELDSMAP"]) unless $metadatafieldsmapCache
		
		# logInfo("~~~~$#{@entityClass}DataXMLHash")
		# logInfo(eval("$#{@entityClass}DataXMLHash").to_json)
		@success = true
		@message = nil
		$isSaveAction = false

	end

	# protected
	def update
		# logInfo("~~~in BaseApiController update")
		parsedData = parseRequestBodyParams
		# logInfo("~~~~parsedData:#{parsedData}")
		$isSaveAction = true
		setCurrentParams(parsedData)
		fetch(@params["id"])
		if @baseIO.baseDO == nil
			@doNotMerge = true
		end
		fetchData(parsedData, false, false)
		#Added stepActionTabs to get exceptions for all the tabs of a particular step on the UI; If stepActionTabs not present then use visitedTabs
		@stepActionTabs = (@baseIO.baseDO.vars.has_key?(:stepActionTabs) ? @baseIO.baseDO.stepActionTabs : nil )
		process()
		isMetadataRequired = true
		if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
			isMetadataRequired = false
		end
		fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
		@message = "Update Successful." unless @message

		responseHash = generateResponseHash(isMetadataRequired)
		@stepActionTabs = nil
		resetCurrentParams
		render :string => responseHash.to_json
	end

	def generateResponseHash(isMetadataRequired = false, returnData = true)
		responseHash = {}
		responseHash["data"] = @entityHash if returnData
		responseHash["metadata"] = @metadataHash if isMetadataRequired
		visitedTabs = (@stepActionTabs.to_s != "" ? @stepActionTabs : @baseIO.baseDO.visitedTabs)
		responseHash["validationerrors"] = fetchExceptions(@baseIO.baseDO.guid,visitedTabs) if @baseIO.baseDO.guid.to_s != ""
		$lookupArray.uniq!
		if $lookupArray.size > 0

			offlineLookupMList = OfflineLookupM.find(
                :all,
                :conditions =>{
                    {
                        :name => 'lookupKey',
                        :op => 'IN'
                    } => $lookupArray
                }
            )
            @offline_lookupCache = {}
            offlineLookupMList.each do |offlookupm|
            	@offline_lookupCache[offlookupm.lookupKey] = {}
            	@offline_lookupCache[offlookupm.lookupKey] = offlookupm
            end
            lookupValueList = Lookupvalue.getLookupValueIn($lookupArray)
			
            @lookupvalueCache = {}
            lookupValueList.each do |lookup|
            	@lookupvalueCache[lookup.key] = [] if !@lookupvalueCache[lookup.key].is_a?(Array)
            	@lookupvalueCache[lookup.key].push(lookup)
            end

			$lookupArray.uniq.each do |lookup|
				addToLookupHash(lookup)
			end


		end
		responseHash["lookups"] = @lookupHash
		responseHash["success"] = @success
		responseHash["message"] = @message
		return responseHash

	end

	def show
		# logInfo("~~~in BaseApiController show")
		parsedData = parseRequestBodyParams
		isMetadataRequired = true
		if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
			isMetadataRequired = false
		end
		setCurrentParams(parsedData)
		init
		fetch(@params["id"])

		fetchData(parsedData,true,isMetadataRequired)

		@message = "Show Successful." unless @message

		responseHash = generateResponseHash(isMetadataRequired)

		resetCurrentParams

		render :string => responseHash.to_json
	end

	# Method to run search framework
	def index
		# logInfo("~~~in BaseApiController index")
		render :string => "index base_api_controller"
	end

	def invoke
		method = @params["method"].to_s+"Impl"
		id = @params["id"]
		self.send method.to_sym, id
	end

	def action
		# logInfo("~~~in BaseApiController action")
		parsedData = parseRequestBodyParams
		# logInfo("~~~~parsedData in action:#{parsedData}")

		id = @params["id"]
		setCurrentParams(parsedData)
		fetch(id)
		fetchData(parsedData, false, false) if parsedData.has_key?("FormData")
		method = @request['headers']['action']
		result = {}
		result = self.send method.to_sym, id, parsedData
		@message = "Successful" unless @message
		if (result == nil || result['success'] == nil || result['success'].to_s == "true")
			isMetadataRequired = true
			if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
				isMetadataRequired = false
			end
			fetchData(parsedData.reject { |k,v| k == "FormData" },true,isMetadataRequired)
			responseHash = generateResponseHash(isMetadataRequired)
			resetCurrentParams

			render :string => responseHash.to_json
		else
			resetCurrentParams
			render :string => result.to_json
		end
	end

	def create
		# logInfo("~~~in BaseApiController create")
		parsedData = parseRequestBodyParams
		# logInfo("~~~parsedData:#{parsedData}")
		#Discussion points
		#1. setBasePlanDetails to be called if product id is present?
		#2. What will happen for form data sent for grand child classes
		#3. How can we handel form data for list grand children (Eg: Fund list/ Rider List).

		# if parsedData.has_key?('FormData') && parsedData['FormData'].has_key?('Entity')
       	# 	baseDO = MobiSys::BrowserHelper.convertToObject(@entityClass, parsedData["FormData"]["Entity"])
   		# 	@baseIO.baseDO = baseDO
        # end
		init

		isMetadataRequired = true
		if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
			isMetadataRequired = false
		end
		setCurrentParams(parsedData)
		if @request && @request['headers'] && @request['headers']['action'].to_s == "fetchMetadata"
			fetchData(parsedData, false, false) if parsedData.has_key?("FormData")
			@stepActionTabs = (@baseIO.baseDO.vars.has_key?(:stepActionTabs) ? @baseIO.baseDO.stepActionTabs : nil )
		end
		# logInfo("~~~entityClass:#{@entityClass}")
		fetchData(parsedData)

		# if parsedData["FetchData"]["isMetadataRequired"].to_s == "true"
		# 	metadataHash = getMetadata
		# 	@responseHash.merge!(metadataHash)
		@message = "Create Successful."
		# end
		isFetchMetadataCall = true
		isFetchMetadataCall = false if @request && @request['headers'] && @request['headers']['action'].to_s == "fetchMetadata"

		responseHash = generateResponseHash(isMetadataRequired,isFetchMetadataCall)

		resetCurrentParams

		render :string => responseHash.to_json
	end


	def parseRequestBodyParams
		parsed = {}
		if @params.has_key? ('request-body')
			begin
				parsed = ::JSON.parse(@params['request-body'])
			rescue Exception => e
				logError("Error in parsing request-body",e, LOGCATEGORY)
			end
    	end
    	return parsed
	end

	def evaluateContextForObject(object)
		classToFind = "#{object.class.name}DO"
		if $contextMasterCache.has_key?(classToFind.to_sym)
			if !Object.const_get(object.class.name).instance_methods(false).include?(:isParentExtendingContext) || (Object.const_get(object.class.name).instance_methods(false).include?(:isParentExtendingContext) && !object.isParentExtendingContext )
				contextMasterList = $contextMasterCache[classToFind.to_sym]
				contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,object)
				@applicableContextsStack = [] unless @applicableContextsStack.is_a?(Array)
				@applicableContextsStack.push(contextMasterGeneratedArray)
			else
				@applicableContextsStack = [] unless @applicableContextsStack.is_a?(Array)
				@applicableContextsStack.push([])
			end
			@currentApplicableContexts = @applicableContextsStack.flatten
		else
			@applicableContextsStack = [] unless @applicableContextsStack.is_a?(Array)
			@applicableContextsStack.push([])

			@currentApplicableContexts = @applicableContextsStack.flatten
		end
	end

	def contextEnd
		@applicableContextsStack.pop if @applicableContextsStack
		@currentApplicableContexts = @applicableContextsStack ? @applicableContextsStack.flatten : []
	end

	def fetchExceptions(entityGuid, visitedTabs)
		errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(entityGuid,visitedTabs)
		return errors
	end

	def fetchData(parsedData, createResponseHash = true, isMetadataRequired = true)
		@entityHash = {}
		@metadataHash = {}
		@lookupHash = {}
		$lookupArray = []
		@createNewObject = createResponseHash
		isMetadataRequired = isMetadataRequired && createResponseHash
		modelNames = []
		fieldHash = {}
		modelObjects = {}
		entityDataHash = eval("$#{@entityClass}DataXMLHash")
		#If createResponseHash is true, call FetchData Models else call FormData Models
		if createResponseHash
			# If FetchData is not provided, get all data
			if parsedData.has_key?("FetchData") && parsedData['FetchData'].has_key?('Models') && parsedData["FetchData"]["Models"].to_s != ""
				modelNames = parsedData["FetchData"]["Models"].collect{|e| e["ModelName"]}
				fieldHash = parsedData["FetchData"]["Models"].collect{|e| {e["ModelName"] => e["Fields"]} if e.has_key?("Fields")}.compact
		    	fieldHash = fieldHash.reduce({}) { |h, v| h.merge v }
			else
				modelNames = entityDataHash["Entity"]["children"].keys
			end
		else
			modelNames = parsedData["FormData"]["Models"].keys if parsedData.has_key?("FormData") && parsedData['FormData'].has_key?('Models')
		end

		className = entityDataHash["Entity"]["attributes"]["class"]
		attributes = entityDataHash["Entity"]["attributes"].select {|key| key.to_s != "class"}
		# logInfo("~~~attributes:#{attributes}")
		formData = {}
		if parsedData.has_key?('FormData') && parsedData['FormData'].has_key?('Models') && parsedData['FormData']["Models"].has_key?('Entity')
			formData = parsedData['FormData']["Models"]["Entity"]
		end
		if @request && @request['headers'] && @request['headers']['action'].to_s == "fetchMetadata" && !createResponseHash
			fetch(formData["object"]) if formData.has_key?('object')
		end
		preProcessEntity(parsedData, createResponseHash, isMetadataRequired)
		className = className.split('.').last if className.include?"."
		@baseIO.baseDO = processEntity(className, attributes,nil,formData)
		postProcessEntity(parsedData, createResponseHash, isMetadataRequired)
		######
		# Code commented because the evaluation of children objects is done before the evaluation of contexts takes place. hence objects for extended contexts are available.
		# Keeping the Code for Future issues.
		######
		# if (@baseIO.baseDO.respond_to? :contextExtendForClass)
		# 	classtoExtent = @baseIO.baseDO.contextExtendForClass.to_s.split(',')
		# 	classtoExtent.each do |cls|
		# 		modelName = ""
		# 		modelHash = {}
		# 		entityDataHash["Entity"]["children"].each do |key, child|
		# 			if child["attributes"]["objectClassName"] == cls
		# 				modelHash = child
		# 				modelName = key
		# 				break
		# 			end
		# 		end
		# 		# modelHash =  entityDataHash["Entity"]["children"][modelName]
		# 		if checkAttributes(modelHash["attributes"])
		# 			formData = {}
		# 			if parsedData.has_key?('FormData') && parsedData['FormData'].has_key?('Models') && parsedData['FormData']["Models"].has_key?(modelName)
		# 				formData = parsedData['FormData']["Models"][modelName]
		# 			end
		# 			className = modelHash["attributes"]["class"]
		# 			attributes = modelHash["attributes"].select {|key| key.to_s != "class"}
		# 			processModel(modelHash,@baseIO.baseDO,modelName,formData,isMetadataRequired)
		# 		end
		# 	end
		# end
		########
		# extended Context code ends here.
		########
		@baseIO.baseDO.guid = @baseIO.baseDO.uniqueKey unless @baseIO.baseDO.guid
		@baseIO.baseDO.contextGuid = @baseIO.baseDO.uniqueKey unless @baseIO.baseDO.contextGuid
		$guidClassNameMap[@baseIO.baseDO.guid] = @baseIO.baseDO.class.name
		if isMetadataRequired
			evaluateContextForObject(@baseIO.baseDO)
			@metadataHash.merge!(processMetadata(@baseIO.baseDO,attributes))

		end

		#evaluate context and metadata for Main entity here and add the context to a stack
		# evaluateContextForObject(@baseIO.baseDO)
		# logInfo("Class Name :- #{@baseIO.baseDO.class.name} || @currentApplicableContexts :- #{@currentApplicableContexts}")
		if createResponseHash
			@entityHash["Entity"] = @baseIO.baseDO.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }  
			@entityHash["Entity"]["objName"] = "Entity"
		end

		modelNames.each do |modelName|
			# logInfo("~~~modelName:#{modelName}")
			if entityDataHash["Entity"]["children"].has_key? modelName
				# logInfo("~~entityDataHash['Entity']['children'][#{modelName}]:#{entityDataHash["Entity"]["children"][modelName]}")
				#check for companyAttribute and skip if not present in company mmetadata cache
				companyAttribute = ((entityDataHash["Entity"]["children"][modelName]["attributes"].has_key?("companyAttribute") and entityDataHash["Entity"]["children"][modelName]["attributes"]["companyAttribute"].to_s != "") ? entityDataHash["Entity"]["children"][modelName]["attributes"]["companyAttribute"] : "")
				companyAttrMetadataCd = ((attributes.has_key?("companyMetadata") and attributes["companyMetadata"].to_s != "" and companyAttribute.to_s != "") ? attributes["companyMetadata"]+"."+companyAttribute : nil)
				next if companyAttrMetadataCd != nil and !$companyFieldMetaDataCache.include?(companyAttrMetadataCd.to_sym)

				if checkAttributes(entityDataHash["Entity"]["children"][modelName]["attributes"])
					formData = {}
					if parsedData.has_key?('FormData') && parsedData['FormData'].has_key?('Models')
						formData = parsedData["FormData"]["Models"]
					end
					modelEntity = processModel(entityDataHash["Entity"]["children"][modelName],@baseIO.baseDO,modelName,formData,isMetadataRequired)
					if modelEntity && createResponseHash

						currentChildren = entityDataHash['Entity']['children'][modelName].has_key?("children") ? entityDataHash['Entity']['children'][modelName]["children"].keys : []

						if modelEntity.is_a? Array
							@entityHash[modelName] = modelEntity.collect{|m| m.hashForApi(false,currentChildren).select {|key| !["class","userId"].include? key.to_s } }
							@entityHash[modelName].each {|h| h["objName"]=modelName unless h.include? "objName"}
						else
							@entityHash[modelName] = modelEntity.hashForApi(false,currentChildren).select {|key| !["class","userId"].include? key.to_s }
							@entityHash[modelName]["objName"] = modelName
							# logInfo "modelEntity #{modelName} :- #{modelEntity.hashForApi(false,currentChildren).select {|key| !["class","userId"].include? key.to_s }}" if modelEntity
						end
					end
				end
			end
		end
		#context end for main entitiy
		if isMetadataRequired
			contextEnd
		end
		# logInfo("processModelLog @baseIO.baseDO.hashForApi :- #{@baseIO.baseDO.hashForApi}")
		entityDataHash = nil
		#pop the context stack once here (Main entity context)
		contextEnd
	end

	def preProcessEntity(parsedData, createResponseHash = true, isMetadataRequired = true)

	end

	def postProcessEntity(parsedData, createResponseHash = true, isMetadataRequired = true)

	end
	#Neha Comments Done
	#make this a recursive call
	def processModel(modelHash,parentBaseDO=nil,returnKey='',parsedData={}, isMetadataRequired = true)
		className = modelHash["attributes"]["class"]
		attributes = modelHash["attributes"].select {|key| key.to_s != "class"}
		formData = {}
		if parsedData.has_key?(returnKey)
			formData = parsedData[returnKey]
		end
		className = className.split('.').last if className.include?"."
		entity = processEntity(className, attributes,parentBaseDO,formData)

		entityArr = []
		return unless entity

		if !entity.is_a?(Array)
			entityArr = [entity]
		else
			entityArr = entityArr + entity
		end
		#Neha Comments
		#for common attributes check here itself.. (facetid ect.)
		#neha comments Done
		#do not use hashForApi as a whole. convert each object after processModel and convert to hash, use the key of hashmap same as the xml tag name.
		#or add attribute accessors for each xml tag and set the object against it.. convert to hash at the end.
		#neha comments done
		#fetch the metadata and inject in the object here itself.
		#neha comments pending
		#evaluate the context and add context hash to the object with parent reference
		entityArr.each do |parentEntity|
			parentEntity.guid = parentEntity.uniqueKey unless parentEntity.guid
			$parentChildGuidMapping[parentEntity.guid] = parentBaseDO.uniqueKey
			methodNameArr = Object.const_get(parentEntity.class.name).instance_methods(false)
			if methodNameArr && methodNameArr.include?(:isParentExtendingContext) && parentEntity.isParentExtendingContext && parentBaseDO
				parentEntity.contextGuid = parentBaseDO.uniqueKey
			else
				parentEntity.contextGuid = parentEntity.uniqueKey
			end
			$guidClassNameMap[parentEntity.guid] = parentEntity.class.name

			#code to evaluate context and metadata for recursive calls on list objects
			if isMetadataRequired
				if methodNameArr && methodNameArr.include?(:additionalContextObjectList) && parentEntity.additionalContextObjectList(@baseIO.baseDO)
					parentEntity.additionalContextObjectList(@baseIO.baseDO).each do |additionalContextObj|
						evaluateContextForObject(additionalContextObj)
					end
				end
				evaluateContextForObject(parentEntity)
				@metadataHash.merge!(processMetadata(parentEntity,attributes))
			end
			if modelHash.has_key? "children" || parentBaseDO != nil
				modelHash["children"].each do |key, value|
					#check for company attribute and skip if not present in company metadata cache
					companyAttribute = ((value["attributes"].has_key?("companyAttribute") and value["attributes"]["companyAttribute"].to_s != "") ? value["attributes"]["companyAttribute"] : "")
					companyAttrMetadataCd = ((attributes.has_key?("companyMetadata") and attributes["companyMetadata"].to_s != "" and companyAttribute.to_s != "") ? attributes["companyMetadata"]+"."+companyAttribute : nil)
					next if companyAttrMetadataCd != nil and !$companyFieldMetaDataCache.include?(companyAttrMetadataCd.to_sym)

					formDataToPass = formData.is_a?(Array) ? formData : formData.select{|k| k.to_s == key}

					if formData.is_a?(Array)
						formDataToPass = formData.select{|a| a["guid"] == parentEntity.guid}
						formDataToPass = formDataToPass.size > 0 ? formDataToPass[0] : {}
					end
					if checkAttributes(value["attributes"])
						processModel(value,parentEntity,key,formDataToPass,isMetadataRequired)
					end
				end
			end
			#pop context from stack after metadata evaluation and recursive call
			if isMetadataRequired
				contextEnd
			end
		end


		if parentBaseDO && entity && @createNewObject
			methodName = "#{returnKey}="
			parentBaseDO.instance_eval { class << self; self end }.send(:attr_accessor, returnKey) unless parentBaseDO.respond_to? methodName
			# logInfo("returnKey :- #{returnKey} || methodName :- #{methodName} ||  parentBaseDO.class.name :- #{parentBaseDO.class.name} ||  entity :- #{entity}")

			currentChildren = modelHash.has_key?("children") ? modelHash["children"].keys : []

			if entity.is_a?(Array)
				entityHashArray = entity.collect{|x| x.hashForApi(false,currentChildren).select {|key| !["class","userId"].include? key.to_s }}
				entityHashArray.each {|h| h["objName"] = returnKey unless h.include? "objName"}
				
				parentBaseDO.send(methodName, entityHashArray)
			else
				entityHashVal = entity.hashForApi(false,currentChildren).select {|key| !["class","userId"].include? key.to_s }
				entityHashVal["objName"] = returnKey unless entityHashVal.include? "objName"
				
				parentBaseDO.send(methodName, entityHashVal)
			end
		end
		#logInfo "processModelLog called for #{className} || parentBaseDO :- #{parentBaseDO.class.name} || entity :- #{entity}"
		return entity
	end

	#Neha Comments Done
	#use GetModel accross baseModel and all its children
	def processEntity(className, attributes, parentBaseDO = nil,formData={})
		begin
			require "#{@entityClass}/#{className}"
			objClass = Object::const_get("MobiSys::#{className}")
			obj = objClass.new(@baseIO)
			obj.parentBaseDO = parentBaseDO
			# Creating attribute variables for class
			attributes.each do |attrKey, attrValue|
       			methodName = "#{attrKey}="
		        obj.instance_eval { class << self; self end }.send(:attr_accessor, attrKey) unless obj.respond_to? methodName
		        obj.send(methodName, attrValue)
			end
			obj.instance_eval { class << self; self end }.send(:attr_accessor, "createNewObject") unless obj.respond_to? "createNewObject="
			obj.send("createNewObject=", @createNewObject)
			#Added a flag to create a New Entity(Nominee,Payer) by default in PolicyPartyListModel when add API is called
			obj.instance_eval { class << self; self end }.send(:attr_accessor, "addEntity") unless obj.respond_to? "addEntity="
			obj.send("addEntity=", @addEntity)
			#Added a flag and array to check for partySameAsCd in PolicyPartyModel PolicyPartyListModel
			obj.instance_eval { class << self; self end }.send(:attr_accessor, "mergeAndAddFlag") unless obj.respond_to? "mergeAndAddFlag="
			obj.send("mergeAndAddFlag=", true)
			obj.instance_eval { class << self; self end }.send(:attr_accessor, "mergeAndAddArray") unless obj.respond_to? "mergeAndAddArray="
			obj.send("mergeAndAddArray=", [])
			# obj.instance_eval { class << self; self end }.send(:attr_accessor, "formData") unless obj.respond_to? "formData="
			# obj.send("formData=", formData)
			objectClassName = obj.objectClassName
			#Added to check if formData to be merged with Db data for Questionnaire
			#If formData present, Questionnaire getModel will return empty PolicyPartyContainer
			obj.initForMerge = (formData != nil && !formData.empty? ? true : false)
			entity = obj.getModel
			if entity.is_a? Array
				if entity.size > 0
					returnEntity = []
					if formData != nil && !formData.empty?
						formData.each do |e|
							if e
								mergedEntity = nil
								dbEntity = entity.select{|a| a.object == e['object']}
								#If party is SAMEAS and clone object is created, do not merge just use the formEntity
								mergeAndAddFl = ((dbEntity.to_s != "" && dbEntity.size > 0 && !obj.mergeAndAddFlag) ? false : true )
								formEntity = MobiSys::BrowserHelper.convertToObject(objectClassName, e,nil,false)
								if @doNotMerge or ((dbEntity.to_s == "" or dbEntity.size == 0) and formEntity)
									if mergeAndAddFl and parentBaseDO and parentBaseDO.respond_to?("remove#{objectClassName}")
										parentBaseDO.send("remove#{objectClassName}".to_sym, formEntity)
									end
									mergedEntity = formEntity
								else
									mergedEntity = mergeEntity(dbEntity[0],formEntity)
								end
								if mergeAndAddFl and parentBaseDO and parentBaseDO.respond_to?("add#{objectClassName}") and mergedEntity
										parentBaseDO.send("add#{objectClassName}".to_sym, mergedEntity)
								end
								returnEntity.push(mergedEntity)
							end
						end
					else
						returnEntity = entity
					end

				else
					returnEntity = []
					formData.each do |e|
						if e
							formEntity = MobiSys::BrowserHelper.convertToObject(objectClassName, e,nil,false)
							if parentBaseDO and parentBaseDO.respond_to?("add#{objectClassName}") and formEntity
								parentBaseDO.send("add#{objectClassName}".to_sym, formEntity)
							end
							returnEntity.push(formEntity)
						end
					end
				end
			else
				#merge entity only if the Model does not return an Array
				# logInfo "formData :- #{formData}" if className == "QuotationPartyModel"
				if formData != nil && !formData.empty?
					formEntity = MobiSys::BrowserHelper.convertToObject(objectClassName, formData,nil,false)
					dbEntity = ((entity != nil  and formData['object'] == entity.object) ? entity : nil)
					# logInfo "inside unless #{className} || #{formEntity.inspect}" if className == "QuotationPartyModel"
					#If party is SAMEAS and clone object is created, do not merge just use the formEntity
					mergeAndAddFl = (entity.to_s != "" && !obj.mergeAndAddFlag ? false : true )
						if @doNotMerge or dbEntity.to_s == ""
							if mergeAndAddFl and parentBaseDO and parentBaseDO.respond_to?("remove#{objectClassName}")
								parentBaseDO.send("remove#{objectClassName}".to_sym, formEntity)
							end
							returnEntity = formEntity
							#remove entity created by default in getModel when not merged with form data to avoid inserting it in the db
							if entity != nil
								entModelSource = Rho::RhoConfig.sources[entity.class.name.to_s]
								entity.removed = "YES" if entModelSource["schema"]["property"].has_key?("removed")
							end
						else
							returnEntity = mergeEntity(entity,formEntity,parentBaseDO)
						end
						if mergeAndAddFl and parentBaseDO and parentBaseDO.respond_to?("add#{objectClassName}") and returnEntity
							parentBaseDO.send("add#{objectClassName}".to_sym, returnEntity)
						end

					# logInfo "after merge :- #{className} || #{entity.inspect}" if className == "QuotationPartyModel"
				else
					returnEntity = entity
				end
			end
			# logInfo("parentBaseDO.class.name :- #{parentBaseDO.class.name} ||  returnEntity :- #{returnEntity}")
			returnEntity = obj.setModel(returnEntity) if @createNewObject != nil && !@createNewObject

			#Done for new Objects
			# If status is N set removed to YES
			if @request == nil || @request['headers'] == nil || @request['headers']['action'].to_s != "fetchMetadata"
				if returnEntity != nil and @createNewObject != nil && !@createNewObject  && parentBaseDO.respond_to?("status") and parentBaseDO.status.to_s == "N"
					if returnEntity.is_a? Array
						returnEntity.each do |e|
							entityModelSource = Rho::RhoConfig.sources[e.class.name.to_s]
							e.removed = "YES" if (entityModelSource["schema"]["property"].has_key?("removed") and e.respond_to?("status") and e.status.to_s == "N")
						end
					# else
					# 	entityModelSource = Rho::RhoConfig.sources[returnEntity.class.name.to_s]
					# 	returnEntity.removed = "YES" if (entityModelSource["schema"]["property"].has_key?("removed") and returnEntity.respond_to?("status") and returnEntity.status.to_s == "N")
					end
				end
			end

			return returnEntity
		rescue Exception => e
			logError("Error in processEntity",e, LOGCATEGORY)
		end
	end

	def mergeEntity(modelEntity,formEntity,parentBaseDO = nil)
			# logInfo("modelEntity.class.name :- #{modelEntity.class.name} ||  formEntity :- #{formEntity.class.name}")
			modelEntityHash = modelEntity.objectToHash if modelEntity
			if formEntity
				formEntityHash = formEntity.objectToHash
				mergedEntityHash = MobiSys::BrowserHelper.merge_hash(formEntityHash, modelEntityHash)
				mergedEntity = MobiSys::BrowserHelper.hashToObject(modelEntity.class.name, mergedEntityHash)
			else
				mergedEntity = modelEntity
			end
			return mergedEntity
	end

	def getMetadata
		metadataHash = {}
		MobiSys::Validation.initializeValidationHash unless $validationHash
		MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
		MobiSys::UIMetaData.initializeDataElement unless $dataElementCache
		MobiSys::UIMetaData.initializeEntityType unless $entityTypeCache
		MobiSys::ContextMasterData.initializeContextMasterHash  unless $contextMasterCache
		MobiSys::MetaData.initializeMetadataHash unless $metadataMasterHash
		#For product metadata
		MobiSys::ProductMetaData.initializeProductMetaDataHash unless $productMetaDataCache
		@responseHash.each do |key,value|
			# logInfo("~~~~processing metadata for #{key}")
			metadataHash.merge!(processMetadata(value))
		end
		return metadataHash
	end

	def addToLookupHash(lookup,value=nil,currentTagObject=nil,filterCond = {})
		offline_lookup_m = nil # = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookup})

		if @offline_lookupCache
			offline_lookup_m = @offline_lookupCache[lookup]
		else
			offline_lookup_m = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookup})
		end
		selectLookup = []
		lookups = {}
		if offline_lookup_m
			if offline_lookup_m.lookupDataCodeName.to_s != "" and offline_lookup_m.lookupDataDescName.to_s != "" and offline_lookup_m.lookupEntityName.to_s != ""
				if currentTagObject != nil
					filterCondData = (offline_lookup_m.lookupFilterCriteria != nil ? offline_lookup_m.lookupFilterCriteria.scan(/'\$(.*?)'/) : [])
					filterCondData.each do |filter|
						filterCond[filter.first] = (currentTagObject.send filter.first.to_sym).to_s unless filterCond.has_key?(filter.first)
					end
				end
				selectLookup = getOfflineLookupData(lookup, filterCond, nil , offline_lookup_m)
			else
				selectLookup.push(offline_lookup_m)
			end
		else
			selectLookup = @lookupvalueCache[lookup] if @lookupvalueCache && @lookupvalueCache.has_key?(lookup)
			if selectLookup.size == 0
				selectLookup = Lookupvalue.getValue(lookup)
			end
		end
		if selectLookup && selectLookup.size > 0
			sortByOrderLookups,remainingLookups = selectLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
			sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
			remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
			lookups = sortByOrderLookups.concat remainingLookups
		end

		tempArray = []
		tempLookup = {}
		listLookupDataFiltered = filterLookupData(lookup)

		lookups.each do |lookup|
			if(listLookupDataFiltered != nil && !listLookupDataFiltered.include?(lookup.cd))
				next
			end
			tempLookup = {}
			tempLookup["cd"] = lookup.cd
			tempLookup["desc"] = getLabelValue(lookup.desc.to_s)
			tempLookup["isDef"] = 1 if lookup.defaultFl and lookup.defaultFl.to_s == "YES"
			tempLookup["addtnlFld1"] = lookup.additionalField1 if lookup.additionalField1 and lookup.additionalField1.to_s != ""
			tempLookup["addtnlFld2"] = lookup.additionalField2 if lookup.additionalField2 and lookup.additionalField2.to_s != ""
			tempArray.push(tempLookup)
		end
		@lookupHash[lookup.to_s] = tempArray if @lookupHash[lookup.to_s] == nil
	end

	def processMetadata(currentTagObject,attributeHash=nil)
		# Process metadata
		metadataHash = {}
		currentUniqueKey = currentTagObject.uniqueKey.to_s
		metaDataCd = "#{currentTagObject.class.name}DO"
		attrToSend = $attributeHash[$entityClassName] if $attributeHash && $attributeHash[$entityClassName]
		metadataHash[currentUniqueKey] = {} if !metadataHash.has_key? (currentUniqueKey)
		# fields = []
		# modelSource = Rho::RhoConfig.sources[currentTagObject.class.name.to_s]
		#metadata object to check for company field metadata
		companyMetadataObject = ((attributeHash != nil and attributeHash.has_key?("companyMetadata") and attributeHash["companyMetadata"].to_s != "") ? attributeHash["companyMetadata"] : nil)
		# end
		contextEnabledHash = Hash.new
		# m1 = Time.now
		metaDataClass = metaDataCd.to_sym

		if $rhoconfig[:contextBasedMetadata]
			if $contextMasterCache.has_key?(metaDataClass)
				$contextMasterCache[metaDataClass].each do |contextMaster|
					# if expression was used only for defaulting then it does not imply that it is context enabled
					contextEnabledHash[contextMaster.fieldName] = true if contextMaster.expressionTypeCd.to_s != "DEFAULT"
				end
			end
		end
		if $uiMetaDataCache.has_key?(metaDataClass)
			$uiMetaDataCache[metaDataClass].each do |mtdtCd, uiMetaDataDOList|
				field = mtdtCd.to_s.split('.')[1].to_s
				next if attrToSend != nil && (!attrToSend.include? field.to_sym)
				# value = currentTagObject.send field.to_sym
				applicableField = "YES"
				uiMetaDataToProcess = MobiSys::UIMetaData.getUiMetadataPropDOList(uiMetaDataDOList, @currentApplicableContexts)

				if !metadataHash[currentUniqueKey].has_key?(field)
					metadataHash[currentUniqueKey][field] = {}
				end

				uiMtdtHash = metadataHash[currentUniqueKey][field]
				uiMetaDataToProcess.each do |uiMetaData|
					uiMtdtHash[uiMetaData.propertyCd] = uiMetaData.propertyValue.to_s

					case uiMetaData.propertyCd
					when "LOOKUPCD"
						$lookupArray.push(uiMetaData.propertyValue.to_s) if uiMetaData.propertyValue.to_s != "" && $lookupArray
					#Moved labelvalue and tooltip logic below
					# when "LABELKEY"
					# 	uiMtdtHash["LABELVALUE"] = Localization::LabelCache.instance.getLabel(uiMetaData.propertyValue.to_sym)
					# 	tooltipVal = Localization::LabelCache.instance.getLabelToolTipValue(uiMetaData.propertyValue.to_sym)
					# 	uiMtdtHash["TOOLTIP"] = tooltipVal if tooltipVal.to_s != ""
					when "OCR"
						uiMtdtHash[uiMetaData.propertyCd] = (uiMetaData.propertyValue.to_s == "YES" ? uiMetaData.metaDataCd.to_s : "")
					end
				end


				if $rhoconfig[:contextBasedMetadata]
					contextEnabled = true if contextEnabledHash.has_key?(field)

				# 	if $metadataMasterHash && $metadataMasterHash.has_key?("#{metaDataCd}.#{field}".to_sym)
				# 		metadataMasterRecord = $metadataMasterHash["#{metaDataCd}.#{field}".to_sym]
				# 		if metadataMasterRecord
				# 			runTimeDrivingFieldNames = metadataMasterRecord.runtimeDrivingMTDT.to_s
				# 		end
				# 	end
				# else
				# 	runTimeDrivingFieldNames = ""
				end
				# uiMtdtHash["RUNTIMEDRIVINGFIELDNAMES"] = runTimeDrivingFieldNames if runTimeDrivingFieldNames.to_s != ""
				uiMtdtHash["ISCTXENABLED"] = contextEnabled if contextEnabled.to_s != ""

				# Process EntityType config
				entityTypeDO = nil
				dataElementDO = nil
				overrideEntityType = nil
				dataElementDO = $dataElementCache[field.to_sym] if $dataElementCache

                if $validationHash.has_key?(metaDataClass)
                        validationMetaDataDOList = $validationHash[metaDataClass]
                        entityVal = MobiSys::Validation.getValidationDO("ENTITYTYPE", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
                        if entityVal
                        	if entityVal.validationCd.to_s != "" && entityVal.validationCd.to_s == "ENTITYTYPE"
	                             overrideEntityType = entityVal.validationParam
                            end
                        end 
                        newVal = MobiSys::Validation.getValidationDO("LESSEREQUALS", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
						if newVal
							lesserEquals = (newVal == nil ? nil : newVal.validationParam)
							uiMtdtHash[newVal.validationCd] = lesserEquals if lesserEquals
					    end
					    newValFormat = MobiSys::Validation.getValidationDO("FORMAT", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
						if newValFormat
							fieldFormat = (newValFormat == nil ? nil : newValFormat.validationParam)
							uiMtdtHash[newValFormat.validationCd] = fieldFormat if fieldFormat
					    end	
					    newMinvalue = MobiSys::Validation.getValidationDO("MINVALUE", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
						if newMinvalue
							fieldFormat = (newMinvalue == nil ? nil : newMinvalue.validationParam)
							uiMtdtHash[newMinvalue.validationCd] = fieldFormat if fieldFormat
					    end	
					    
				end
				if dataElementDO && overrideEntityType == nil
					entityTypeDO = $entityTypeCache[dataElementDO.entityFieldTypeCd.to_sym] if $entityTypeCache
				end
				
				unless entityTypeDO 
					if overrideEntityType
						entityTypeDO = $entityTypeCache[overrideEntityType.to_sym] if $entityTypeCache
						entity = entityTypeDO.entityFieldTypeCd.to_s
						datatype = entityTypeDO.dataTypeCd.to_s
						uiMtdtHash["DATATYPE"] = datatype if datatype != ""
						entityTypeDO.EntityPropertyList.each do |entityProperty|
							uiMtdtHash[entityProperty.propertyCd] = entityProperty.propertyValue.to_s unless uiMtdtHash.has_key?(entityProperty.propertyCd)
						end
				    end		
				else
					entity = entityTypeDO.entityFieldTypeCd.to_s
					datatype = entityTypeDO.dataTypeCd.to_s
					uiMtdtHash["DATATYPE"] = datatype if datatype != ""
					entityTypeDO.EntityPropertyList.each do |entityProperty|
						uiMtdtHash[entityProperty.propertyCd] = entityProperty.propertyValue.to_s unless uiMtdtHash.has_key?(entityProperty.propertyCd)
					end
				end

				#set applicable value for companyField metadata
				if companyMetadataObject
					lookupValue = $metadatafieldsmapCache[("METADATAFIELDSMAP" + field).to_sym]
					if lookupValue.to_s != ""
						companyMetadataCd = companyMetadataObject + "." + lookupValue.desc
					else
						companyMetadataCd = companyMetadataObject + "." + field
					end
					applicableField = "NO" if !$companyFieldMetaDataCache.include?(companyMetadataCd.to_sym)
				end
				# Added new property in metadata called APPLICABLE to blank out the values. 
				# However, the company-level metadata is overriding this property. 
				# To address this, added a condition that checks if APPLICABLE is null. 
				# Based on this condition, the property is then set to either 'YES' or 'NO'. 
				uiMtdtHash["APPLICABLE"] = applicableField if applicableField.to_s != "" && uiMtdtHash["APPLICABLE"].to_s == ""
			end
		end


		# Process validation metadata
		if $validationHash.has_key?(metaDataClass)
			$validationMtdtList[metaDataClass].each do |field|

				validationMetaDataDOList = $validationHash[metaDataClass]

				val = MobiSys::Validation.getValidationDO("MINOCCURS", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
				minOccurs = (val == nil ? 0 : val.validationParam.to_i > 0 ? val.validationParam.to_i : 0)
				if metadataHash[currentUniqueKey].has_key?(field) && metadataHash[currentUniqueKey][field].to_s != ""
					metadataHash[currentUniqueKey][field]["MINOCCURS"] = minOccurs.to_s
				end
			end
		end


		#If additional lookups are present, add to lookupHash
		if (@baseIO and @baseIO.respond_to?("additionalData") and @baseIO.additionalData != nil and @baseIO.additionalData.has_key?("ADDTNL_LOOKUPS") and @baseIO.additionalData["ADDTNL_LOOKUPS"] != nil)
			@baseIO.additionalData["ADDTNL_LOOKUPS"].each do |addtnlLookup|
				$lookupArray.push(addtnlLookup.keys.first.to_s) if addtnlLookup.keys.first.to_s != "" && $lookupArray

			end
		end

		#If additional lookup data is present, add to lookupHash. This is different from ADDTNL_LOOKUPS as we do not want to get the lookup value from the master table, just add the custom lookup array against the lookup cd
		if (@baseIO and @baseIO.respond_to?("additionalData") and @baseIO.additionalData != nil and @baseIO.additionalData.has_key?("ADDTNL_LOOKUPDATA") and @baseIO.additionalData["ADDTNL_LOOKUPDATA"] != nil)
			@lookupHash = {} if @lookupHash == nil
			@baseIO.additionalData["ADDTNL_LOOKUPDATA"].each do |addtnlLookupKey, addtnlLookupValue|
				@lookupHash[addtnlLookupKey.to_s] = addtnlLookupValue
			end
		end

		metadataHash = loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadataObject)

		# After loading additional metadata then load the label value and tooltip since it should be based on overridden metadata
		if $uiMetaDataCache.has_key?(metaDataClass)
			$uiMetaDataCache[metaDataClass].each do |mtdtCd, uiMetaDataDOList|
				uiMtDtLabel = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, @currentApplicableContexts)
				field = mtdtCd.to_s.split('.')[1].to_s
				if uiMtDtLabel.to_s != ""
					if metadataHash[currentUniqueKey].has_key?(field) && metadataHash[currentUniqueKey][field].to_s != "" && metadataHash[currentUniqueKey][field].has_key?("LABELKEY") && metadataHash[currentUniqueKey][field]["LABELKEY"].to_s != ""
						metadataHash[currentUniqueKey][field]["LABELVALUE"] = Localization::LabelCache.instance.getLabel(uiMtDtLabel.propertyValue.to_s)
						tooltipVal = Localization::LabelCache.instance.getLabelToolTipValue(uiMtDtLabel.propertyValue.to_s)
						metadataHash[currentUniqueKey][field]["TOOLTIP"] = tooltipVal if tooltipVal.to_s != ""
					end
				end
			end
		end
		return metadataHash
	end

	def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata=nil)
		return metadataHash
	end

	def filterLookupData(lookupKey)
		return nil
	end


	def initializeDataXMLHash
		# logInfo("~~~in initializeDataXMLHash")
		#quotation data xml for testing purpose only
		# quotationDataXML = '<?xml version="1.0" encoding="UTF-8"?>
		# 	<Entity class="QuotationModel" package="com.c2lbiz.symbiosys.insurance.quotation.model" objectClassName="Quotation">
		# 		<BasePlan class="QuotationPlanModel" objectClassName="QuotationProduct">
		# 			<FundList class="QuotationInvestmentFundListModel" facetId="FUNDSREQUIRED" objectClassName="QuotationProductInvestmentFund">
		# 			</FundList>
		# 			<PlanExtraList class="QuotationProductExtraListModel" facetId="PRODUCTEXTRAREQUIRED" objectClassName="QuotationProductExtra">
		# 			</PlanExtraList>
		# 			<Discount class="QuotationDiscountModel" facetId="PRDDISCOUNT">
		# 			</Discount>
		# 		</BasePlan>

		# 		<RiderList class="QuotationRiderListModel" objectClassName="QuotationProduct">
		# 			<RiderExtraList class="QuotationProductExtraListModel" facetId="PRODUCTEXTRAREQUIRED" objectClassName="QuotationProductExtra">
		# 			</RiderExtraList>
		# 		</RiderList>

		# 		<Proposer class="QuotationPartyModel" roleCd="PROPOSER" facetId="PROPOSERDIFFERENTFROMINSURED" meta="PolicyProposerDO"  objectClassName="QuotationParty">
		# 		</Proposer>

		# 		<PrimaryInsured class="QuotationPartyModel" roleCd="PRIMARY" objectClassName="QuotationParty">
		# 		</PrimaryInsured>

		# 		<JointLife class="QuotationPartyModel" roleCd="JOINT" facetId="JOINTLIFE" objectClassName="QuotationParty">
		# 		</JointLife>

		# 		<SupplementaryList class="QuotationPartyListModel" roleCd="SUPPLEMENTARY" facetId="SUPPLEMENTARYINSUREDREQUIRED" objectClassName="QuotationParty">
		# 		</SupplementaryList>

		# 		<InitialInvestment class="QuotationTopUpModel" topUpTypeCd="INITIALINVESTMENT" facetId="INITIALINVESTMENTREQUIRED" objectClassName="QuotationTopUp">
		# 		</InitialInvestment>

		# 		<RegularTopup class="QuotationTopUpModel" topUpTypeCd="REGULARTOPUP" facetId="REGULARTOPUPSREQUIRED" objectClassName="QuotationTopUp">
		# 		</RegularTopup>

		# 		<AdHocTopupList class="QuotationTopUpListModel" topUpTypeCd="ADHOCTOPUP" facetId="ADHOCTOPUPSREQUIRED" objectClassName="QuotationTopUp">
		# 		</AdHocTopupList>

		# 		<TransferTopupList class="QuotationTopUpListModel" topUpTypeCd="TRANSFERTOPUP" facetId="TRANSFERCONTRIBUTION" objectClassName="QuotationTopUp">
		# 		</TransferTopupList>

		# 		<WithdrawalList class="QuotationWithdrawalListModel" facetId="WITHDRAWALSREQUIRED" objectClassName="QuotationWithdrawal">
		# 		</WithdrawalList>

		# 		<OutputPreferences class="OutputPreferencesModel" objectClassName="OutputPreferences">
		# 		</OutputPreferences>

		# 		<EmailRequest class="EmailRequestModel" objectClassName="EmailRequest">
		# 		</EmailRequest>

		# 	</Entity>'
		entityMaster = EntityMaster.loadObject(:first, :conditions=>{:entityTypeCd =>@entityClass.upcase })
		if entityMaster
			dataXML = entityMaster.restXmlHierarchy.to_s
			jsonAttributes = entityMaster.restJsonAttributes.tr("\n","").tr("\r","").to_s
		else
			dataXML = ""
			jsonAttributes = ""
		end
		jsonAttributes << ",guid,id,status,versionID,visitedTabs"
		doc = REXML::Document.new(dataXML)
		mainEntityHash = {}
		mainEntityHash = parseXMLNode(mainEntityHash, doc.root)
		eval("$#{@entityClass}DataXMLHash=mainEntityHash")

		# attrHash = Rho::JSON.parse(jsonAttributes)
		# attrHash.each_key do |key|
		attrHash = {}
		attrHash[@entityClass] = jsonAttributes.split(",").collect{|e| e.to_sym}
		# end
		$attributeHash = Hash.new unless $attributeHash
		$attributeHash.merge!(attrHash)
	end

	def parseXMLNode(entityDataHash, node)
		entityDataHash[node.name] = {}
		#Process element and it's attributes
		entityDataHash[node.name]["attributes"] = {}
		node.attributes.each do |key, value|
			entityDataHash[node.name]["attributes"][key] = value
		end
		if node.elements.size > 0
			entityDataHash[node.name]["children"] = {}
		end
		# Loop over child elements and process it
		node.elements.each do |ele|
			# logInfo("~~ele:#{ele.name}")
			parseXMLNode(entityDataHash[node.name]["children"], ele)
		end
		return entityDataHash
	end

	def checkAttributes(attributes)
		isValid = true
		# logInfo "attributes[facetId] #{$currentProduct} :- #{attributes["facetId"].inspect}"
		if attributes.has_key?("facetId")
			# logInfo "attributes[facetId] inside :- #{attributes["facetId"].inspect}"
			isValid = MobiSys::BrowserHelper.renderPanel?(attributes["facetId"], $currentProduct)
		end
		return isValid
	end

	def find
		parsedData = parseRequestBodyParams
		responseHash = {"success" => false}
		if @params.keys.select{|key| key != "request-body"}.size > 0
			findKey = @params.keys[0]
		end
		findValue = @params[findKey]
		@baseIO.baseDO = Object.const_get(@entityClass).loadObject(:first, :conditions => {findKey.to_sym => findValue})
		if @baseIO.baseDO
			isMetadataRequired = true
			if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
				isMetadataRequired = false
			end
			setCurrentParams(parsedData)
			fetchData(parsedData,true,isMetadataRequired)
			@message = "Successful"
			responseHash = generateResponseHash(isMetadataRequired)
			resetCurrentParams
		else
			@message = "#{@entityClass} not found"
			responseHash["success"] = false
			responseHash["message"] = @message
		end

		render :string => responseHash.to_json
	end

	def setCurrentParams(parsedData)
		if !parsedData.empty? && parsedData.has_key?("FetchData")
			if parsedData["FetchData"].has_key?("currentActiveTab")
				$currentActiveTab = parsedData["FetchData"]["currentActiveTab"]
			end
			if parsedData["FetchData"].has_key?("currentActiveField")
				$currentActiveField = parsedData["FetchData"]["currentActiveField"]
			end
			if parsedData["FetchData"].has_key?("currentActiveStep")
				$currentActiveStep = parsedData["FetchData"]["currentActiveStep"]
			end
		end
	end

	def resetCurrentParams
		$currentActiveTab = nil
		$currentActiveField = nil
		$currentActiveStep = nil
	end


	def renderTemplate(options)
	    template = options[:template]
	    return evaluateRb(Rho::Application.userFolder + template,options).to_s.force_encoding("UTF-8")
    end

   def evaluateRb(rootFile,options = nil)
        rootFile = rootFile+'.erb_enc'
        # rootFile = rootFile+'.erb' # for debugging with rhosimulator

        locals = self.clone

        class << locals

          def set_vars(obj = nil)
            @vars = {}
            if obj
              obj.each do |key,value|
                @vars[key.to_sym()] = value if key && key.length > 0
              end
            end
          end

          def method_missing(name, *args)
            unless name == Fixnum
              if name[name.length()-1] == '='
                @vars[name.to_s.chop.to_sym()] = args[0]
              else
                @vars[name]
              end
            end
          end

          def get_binding
            binding
          end
        end
        locals.set_vars(options[:locals])
        begin
            decryptedContent = MobiSys::Encryption.decryptAndDecodeContent(File.read(rootFile).to_s.force_encoding("UTF-8"))
            erb = ERB.new(decryptedContent)
            evaluatedValue = erb.result(locals.get_binding)
        rescue Exception => e
          puts "\nYou have a syntax error in your ERB: #{rootFile}\n#{e.backtrace}"
        end
	  return evaluatedValue
	end

    def loadProductAdditionalMetadata(baseIO, baseProduct, currentTagObject, metadataHash, companyMetadata = nil, objectForMetadata = nil)
    	#create a Product Prdfield MetaData Cache and if the field has metadata in this replace it with the UIMetaData
        currentTagObjectModelSource = Rho::RhoConfig.sources[currentTagObject.class.name.to_s]
        currentUniqueKey = currentTagObject.uniqueKey.to_s
        currentClassname = currentTagObject.class.name.to_s

        product ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s)
        if product && (currentTagObject.is_a?(QuotationProduct) || currentTagObject.is_a?(PolicyProduct))
            facet = product.getFacet("PREMIUMDETAILS")
            premiumDetails = facet.getPremiumDetails
            #add these attributes readonly properties to the metadata array to be returned
            readOnlyFields = premiumDetails.inputDataElement
            readOnlyFieldsArr = readOnlyFields.to_s.split(",")
            readOnlyFieldsArr.each do |attributeField|
                if(metadataHash[currentUniqueKey] != nil && metadataHash[currentUniqueKey]["#{attributeField}"] != nil)
                    metadataHash[currentUniqueKey]["#{attributeField}"]["ENABLED"] = "NO"
                end
            end

            #Add Plan Additional Field data in Metadata array
            for i in 1..6
                currFacetLabelValue = product.getFacet("ADDITIONALCAPTUREFIELD"+i.to_s+"LABEL")
                currFacetInputValue = product.getFacet("ADDITIONALCAPTUREFIELD"+i.to_s+"INPUTTYPE")
                currFacetLookupKey  = product.getFacet("ADDITIONALCAPTUREFIELD"+i.to_s+"LOOKUP")
                addtnlField = 'addtnField'+i.to_s
                metadataHash[currentUniqueKey][addtnlField] = {} if(metadataHash[currentUniqueKey] != nil && metadataHash[currentUniqueKey][addtnlField] == nil)
                # if currFacetLabelValue.to_s != ""
                    metadataHash[currentUniqueKey][addtnlField]["LABELKEY"] = currFacetLabelValue.actionValue if currFacetLabelValue && currFacetLabelValue.actionValue.to_s != ""
                    metadataHash[currentUniqueKey][addtnlField]["INPUTTYPECD"] = currFacetInputValue.actionValue if currFacetInputValue && currFacetInputValue.actionValue.to_s != ""
                    metadataHash[currentUniqueKey][addtnlField]["LOOKUPCD"] = currFacetLookupKey.actionValue if currFacetLookupKey && currFacetLookupKey.actionValue.to_s != ""
                    #add to Lookup Hash
                    addtnlFieldValue = currentTagObject.send addtnlField.to_sym
                    addToLookupHash(currFacetLookupKey.actionValue,addtnlFieldValue) if currFacetLookupKey && currFacetLookupKey.actionValue.to_s != ""
                # else
                	#
                    # metadataHash["#{currentTagObject.uniqueKey}"]["#{addtnlField}"]["APPLICABLE"] = "NO"
                # end
            end

            saLabelKey = product.getFacetValue("SALABEL")
            if saLabelKey.to_s != ""
            	if(metadataHash["#{currentTagObject.uniqueKey}"] != nil && metadataHash["#{currentTagObject.uniqueKey}"]["baseSumAssured"] != nil)
                    metadataHash["#{currentTagObject.uniqueKey}"]["baseSumAssured"]["LABELKEY"] = saLabelKey
                end
            end

            baseAnnualPremLabelKey = product.getFacetValue("ANNUALPREMIUMLABEL")
            if baseAnnualPremLabelKey.to_s != ""
            	if(metadataHash["#{currentTagObject.uniqueKey}"] != nil && metadataHash["#{currentTagObject.uniqueKey}"]["baseAnnualPremium"] != nil)
                    metadataHash["#{currentTagObject.uniqueKey}"]["baseAnnualPremium"]["LABELKEY"] = baseAnnualPremLabelKey
                end
            end

            #If Rider is not selected then its fields should not be read only
            if currentTagObject.productTypeCd.to_s == "RIDER" and currentTagObject.selected.to_s != "YES"
                metadataHash[currentTagObject.uniqueKey].each do |k, v|
                    metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO" if k.to_s != "selected"
                end
            end
        end

        if $productMetaDataCache and $productMetaDataCache.has_key?(baseProduct.productSeq.to_s)
            $productMetaDataCache[baseProduct.productSeq.to_s].each do |field, productMetaDataDOList|
            	field = field.to_s
                next if !currentTagObjectModelSource["schema"]["property"].has_key?(field)
                metadataHash[currentUniqueKey][field] = {} if !metadataHash[currentUniqueKey].has_key?(field)

                # if object name exists then compare the objects are the same
                if !productMetaDataDOList.empty? && productMetaDataDOList["objectName"].to_s != "" && companyMetadata.to_s != ""
                    if !productMetaDataDOList["objectName"].equal?(companyMetadata)
                        next
                    end
                end

                if !productMetaDataDOList.empty?
                	if baseIO.baseDO
	                	if baseIO.baseDO.class.name.to_s == "Quotation"
                            if baseIO.policyDO
                                policy = baseIO.policyDO
                            else
							     policy = MobiSys::PolicyBO.convertToPolicy(baseIO.baseDO)
                                 baseIO.policyDO = policy
                            end
						else
							policy = baseIO.baseDO
						end
					end
                    productMetaDataDOList.each do |propertyCd, prdFieldMetadataDO|
                        ui = MobiSys::ProductMetaData.getProductMetadataPropDO(propertyCd, productMetaDataDOList)
						# metadataHash[currentUniqueKey][field][propertyCd] = ui.propertyValue.to_s if ui.to_s != "" and ui.propertyValue.to_s != ""
                        propertyValue = ui.propertyValue.to_s if ui.to_s != "" and ui.propertyValue.to_s != ""
                        if propertyValue.to_s == ""
                            if ui.to_s != "" && ui.modelCd.to_s != ""
                                begin
									party = nil
									if currentTagObject.is_a?(Party)
										party = currentTagObject
									elsif objectForMetadata.is_a?(Party)
										party = objectForMetadata
									else
										party = policy.getParty("PRIMARY")
									end
									policyProduct = policy.getBaseProduct if policy
                                    policyModel = PolicyUtil::PolicyModel.new
                                    modelResultDO = policyModel.execute(policy, policyProduct, party, ui.modelCd.to_s)
                                    propertyValue = modelResultDO.getFieldValue(ui.outputActionElement) if modelResultDO && ui.outputActionElement.to_s != ""
                                rescue Exception => e
                                    Rho::Log.error("Error in policy model evaluation --->#{e}\n#{e.backtrace}", LOGCATEGORY)
                                end
                            end
                        end

                        metadataHash[currentUniqueKey][field][ui.propertyCd.to_s] = propertyValue

                        if propertyValue.to_s != "" && ui.propertyCd.to_s == "LOOKUPCD"
                        	$lookupArray.push(propertyValue.to_s) if propertyValue.to_s != "" && $lookupArray
                            value = currentTagObject.send field.to_sym
                            addToLookupHash(propertyValue.to_s,value,currentTagObject)
                        end
                    end
                else
                    applicableField = "NO"
                    metadataHash[currentUniqueKey][field]["APPLICABLE"] = "NO"
                end
            end
        end

        return metadataHash
    end
end

#encoding: UTF-8
require 'CommonClasses/FieldResult'

module MobiSys
	module CommonUtil
		# Dynamic DT constants
		MODE 				= "mode"
		FROM 				= "from_"
		TO 					= "to_"
		DAYFROM 			= "dayFrom_"
		DAYTO 				= "dayTo_"
		MONTHFROM 			= "monthFrom_"
		MONTHTO 			= "monthTo_"
		LASTDAY 			= "32"
		IN 					= "in_"
		NOTIN 				= "notIn_"
		COUNT 				= "count"
		EXPRESSIONRULE 		= "expression_"
		EXPRESSION 			= "expression"
		EXPRESSION1 		= "expression1";
		RATE 				= "rate"
		RANK 				= "rank"
		LOOKUP 				= "lookup_"
		PREVIOUSRUNVALUE 	= "previousRunValue"
		PREVIOUSSUMVALUE 	= "previousSumValue"

		FIELDS_MAPPER = {
			:occupationClass    => "occupationCd",
			:firstName1         => "firstname",
			:lastName1          => "lastname",
			:proposalEntryDt    => "quotationDt",
			:proposalReceivedDt => "quotationDt",
			:proposalSignedDt   => "quotationDt",
			:policyIssueDt      => "quotationDt",
			:baseProductId      => "productId",
			:birthDt            => "dob",
			:jointLife          => "jointLifeFlag",
			:maritalStatusCd    => "maritalStatus",
			:educationLevelCd   => "educationCd",
			# new entries
			# :quotationPartyGuid => "guid",
			# :quotationRefGuid   => "uniqueKey",
			:titleCd            => "title",
			:middleName1        => "middlename",
			:extensionName1     => "extensionName",
			:firstName2         => "firstname2",
			:middleName2        => "middlename2",
			:lastName2          => "lastname2",
			:citizenshipCd      => "nationality",
			:addressLine4Lang1  => "addressLine4",
			:districtCd         => "stateCd",
			:identityNum        => "idNumber",
			:identityTypeCd     => "idType",
			:corporateName1     => "corporateName",
			:countryCd          => "isdCode"
		}.freeze
		REVERSE_FIELDS_MAPPER = FIELDS_MAPPER.each_with_object({}) { |(k, v), h| h[v.to_sym] = k.to_s }.freeze

		#Deepali Singh: 07-05-2015 - added below method to find if array is uniq
		def self.isUniq(array)
			array.length == array.uniq.length if array != nil
		end
		###################################################################################################


		#Deepali Singh: 04-01-2017 - added below method to find key in nested hash
		def self.deep_find_key_in_hash(key, object, found=nil)
			if object.respond_to?(:key?) && object.key?(key)
				return object[key]
			elsif object.is_a? Enumerable
				object.find { |*a| found = deep_find_key_in_hash(key, a.last) }
				return found
			end
		end
		###################################################################################################


	    def self.addErrors(errors, key, error, errorParameters=[])
			errorList = errors[key]
			#Deepali Singh: 10-06-2015 - encoding label using utf-8
			errorString = Localization::LabelCache.instance.getLabel(error.to_sym).to_s.force_encoding("UTF-8").clone
			#errorParameters.each_with_index do |str, index|
			#  str =Localization::LabelCache.instance.getLabel(str.to_sym)
			#  errorString = errorString.gsub("{"+(index+1).to_s+"}", str)
			#end

			errorString = replacePlaceHolders(errorString,errorParameters)

			if errorList != nil
				unless errorList.flatten.include? errorString
					errorList.push(errorString) 
				end 
			else
				errorList = Array.new
				errorList.push(errorString)
			end
			errors[key] = errorList      
		end
		###################################################################################################


		def self.replacePlaceHolders(errorString, errorParameters)
			errorParameters.each_with_index do |str, index|
				str = str.to_s
				#Deepali Singh: 10-06-2015 - encoding label using utf-8
				str =Localization::LabelCache.instance.getLabel(str.to_sym).to_s.force_encoding("UTF-8")
				#errorString.gsub!("{"+(index+1).to_s+"}", str)
				errorString = errorString.gsub("{"+(index+1).to_s+"}", str)
			end
			return errorString
		end
		###################################################################################################


		def self.convertToHash(array, key, duplicates=false)
			hash  = Hash.new
			array.each do |entry|
				jointKey = ""
				if key.is_a?(Array)
					key.each do |keyAttribute|       
						attribute = entry.send keyAttribute.to_sym
						jointKey = jointKey.to_s + attribute.to_s     
					end
					value = jointKey
				else  
					value = entry.send key.to_sym
				end
				if duplicates
					array = hash[value]
					unless array
						array = Array.new
						hash[value] = array
					end  
					array.push entry
				else  
					hash[value] = entry
				end  
			end
			return hash
		end
		###################################################################################################


		def self.addUserActivity(uri, params, entityType, entityRefNumber)
			userActivity = UserActivity.new
			userActivity.uri = uri
			userActivity.params = params
			userActivity.executionTime = Time.now
			userActivity.deviceSeq = Application.getValue('deviceSeq').value.to_i
			userActivity.entityType = entityType
			userActivity.entityRefNumber = entityRefNumber
			userActivity.persistAll
		end
		##################################################################################################    


		def self.getLinkedHashedList(columnName, objectList)
			linkedHashMap = {}
			if objectList != nil && objectList.size > 0
				objectList.each do |object|
					if object.is_a?(Hash)
						columnValue = object[columnName.to_sym]
					else
						columnValue = object.send columnName
					end
					if columnValue
						listB = linkedHashMap[columnValue]
						unless listB
							listB = []
						end
						listB.push(object)
						linkedHashMap[columnValue] = listB
					end
				end
			end
			return linkedHashMap
		end
		#################################################################################################


		def self.getDTFromQuestionResponse(questionSetRespList)
			linkHashQuestionSet = {}
			listFieldResult = []
			sortingReqd = false
			if questionSetRespList != nil && questionSetRespList.size > 0
				linkHashQuestionSet = getLinkedHashedList("rowGuid", questionSetRespList)
				listRowGuid = linkHashQuestionSet.keys
				listRowGuid.each do |rowGuid|
					fieldResultDO = MobiSys::DataObjects::FieldResult.new
					linkHashQuestionSet[rowGuid].each do |serviceQuestionResponseDO|
						if "sortOrder" == serviceQuestionResponseDO.questionDataElementCd
							fieldResultDO.sortOrder = serviceQuestionResponseDO.responseValue
							sortingReqd = true
							next
						elsif "inputOrder" == serviceQuestionResponseDO.questionDataElementCd
							fieldResultDO.setInputOrder =serviceQuestionResponseDO.responseValue
							next
						end
						fieldResultDO.objectName = serviceQuestionResponseDO.questionSetCd
						fieldResultDO.addFieldValue(nil, serviceQuestionResponseDO.questionDataElementCd, serviceQuestionResponseDO.responseValue)
					end
					unless fieldResultDO.sortOrder
						fieldResultDO.sortOrder = "0"
						listFieldResult.push(fieldResultDO)
					end
				end
				if sortingReqd
					listFieldResult = listFieldResult.sort{|x,y| x.sortOrder <=> y.sortOrder}
				end
				return listFieldResult
			end
		end
		#################################################################################################


		# This method is used to get the matching row of the definition table rule.This definition rule is linked to any definition like KPI,Incentive,Target
		def self.evaluateApplicableDT(baseDO, ruleDO)
			questionSetRespList = RuleDecisionTable.loadObject(
				:all,
				:conditions => {
					:entityGuid => ruleDO.guid
				}
			)
			listFieldResultDOList = getDTFromQuestionResponse(questionSetRespList)
			quesSetDO = nil
			if ruleDO.definitionTypeCd.to_s == "DYNAMIC_QS"
				quesSetDO = QuestionSet.loadObject(
					:first,
					:conditions => {
						:questionSetCd => ruleDO.definitionCd
					}
				)
			else
				quesSetDO = QuestionSet.loadObject(
					:first,
					:conditions => {
						:questionSetCd => ruleDO.definitionTypeCd
					}
				)
			end
			fieldResult = nil
			return nil if listFieldResultDOList == nil || listFieldResultDOList.size == 0
			
			listFieldResultDOList.each do |fieldResultDO|
				listFieldValueDOList = fieldResultDO.fieldValueList
				matchFound = false
				notinFlag = true
				conditionsExist = false
				evaluatedValues = ""
				listFieldValueDOList.each do |fieldValueDO|
					#check if the attribute is not a condition then continue.
					next if quesSetDO.getQuestionSetQuestion(fieldValueDO.fieldCd).dataElementType.to_s != "CONDITION" || fieldValueDO.fieldValue.to_s == ""

					methodname = nil
					fieldname = nil
					length = fieldValueDO.fieldCd.length
					strFieldCdArr = fieldValueDO.fieldCd.to_s.split("_")
					strStart = strFieldCdArr[0]
					strStart = strStart + "_" if strFieldCdArr.size > 1
					if (strStart.to_s == FROM) || (strStart.to_s == TO) || (strStart.to_s == DAYFROM) || (strStart.to_s == DAYTO) || (strStart.to_s == MONTHFROM) || (strStart.to_s == MONTHTO) || (strStart.to_s == EXPRESSIONRULE) || (strStart.to_s == NOTIN)
						fieldname = fieldValueDO.fieldCd[strStart.length..length]
					else
						fieldname = fieldValueDO.fieldCd
					end

					begin
						conditionsExist = true
						methodResult = nil								
						if baseDO.is_a?(MobiSys::DataObjects::FieldResult)
							if baseDO.getFieldValue(fieldname) != nil
								methodResult = baseDO.getFieldValue(fieldname)
							elsif baseDO.getFieldValue(fieldname.to_s.downcase) != nil
								methodResult = baseDO.getFieldValue(fieldname.to_s.downcase)
							end
						elsif strStart.to_s != EXPRESSIONRULE
							obj = baseDO.send(fieldname.to_sym)
							methodResult = obj.to_s if obj
						end
						evaluatedValues = evaluatedValues + fieldname + ":" + methodResult.to_s + ", "

						if methodResult.to_s != "" || strStart.to_s == EXPRESSIONRULE
							#first check if it is non numeric and a select value in that case there will be no from and to prefix etc.
							if strFieldCdArr.length == 1
								if methodResult.to_s == fieldValueDO.fieldValue.to_s
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							elsif strStart.to_s == FROM
								if methodResult.to_f >= fieldValueDO.fieldValue.to_f
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							elsif strStart.to_s == TO
								if methodResult.to_f <= fieldValueDO.fieldValue.to_f
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							elsif strStart.to_s == DAYFROM || strStart.to_s == DAYTO
								dt = DateTime.strptime(methodResult.to_s,'%d/%m/%Y')
								rhsVal = fieldValueDO.fieldValue.to_i
								
								if fieldValueDO.fieldValue.to_s == LASTDAY
									rhsVal = Date.new(dt.year,dt.month,1).next_month.prev_day
								end
								
								if strStart.to_s == DAYFROM
									if dt.mday >= rhsVal
										matchFound = true
										fieldResult = fieldResultDO
										next
									else
										matchFound = false
										fieldResult = nil
										break
									end
								elsif strStart.to_s == DAYTO
									if dt.mday <= rhsVal
										matchFound = true
										fieldResult = fieldResultDO
										next
									else
										matchFound = false
										fieldResult = nil
										break
									end
								end
							elsif strStart.to_s == MONTHFROM || strStart.to_s == MONTHTO
								difference = MobiSys::DateTimeUtils.dateDifferenceInMonths(methodResult.to_s, Time.now.strftime("%Y-%m-%d"))
								rhsVal = fieldValueDO.fieldValue.to_i
								
								if strStart.to_s == MONTHFROM
									if difference >= rhsVal
										matchFound = true
										fieldResult = fieldResultDO
										next
									else
										matchFound = false
										fieldResult = nil
										break
									end
								elsif strStart.to_s == MONTHTO
									if difference <= rhsVal
										matchFound = true
										fieldResult = fieldResultDO
										next
									else
										matchFound = false
										fieldResult = nil
										break
									end
								end
							#if condition is an expression then the output of the expression should be a boolean 
							elsif strStart.to_s == EXPRESSIONRULE
								expressionFormed = fieldValueDO.fieldValue.to_s.gsub("&lt;", "<")
								expressionFormed = expressionFormed.gsub("&gt;", ">")
								expressionFormed = expressionFormed.gsub("DateDifferenceInDays","MobiSys::DateTimeUtils.dateDifferenceInDays")
								expressionFormed = expressionFormed.gsub("negativeSign","MobiSys::Math.negativeSign")
								expressCond = eval(expressionFormed)
								if expressCond
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							elsif strStart.to_s == NOTIN
								list = fieldValueDO.fieldValue.to_s.split(",")
								if list != nil && list.size > 0
									list.each do |str|
										if str == methodResult.to_s
											notinFlag = false
											break
										end
									end
								end
								#if the value of the record is not present in the not in field list 
								if notinFlag
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							elsif strStart.to_s == IN
								foundIn = false
								list = fieldValueDO.fieldValue.to_s.split(",")
								foundIn = list.include?(methodResult) if list != nil && list.size > 0
								#if the value of the record is not present in the not in field list 
								if foundIn
									matchFound = true
									fieldResult = fieldResultDO
									next
								else
									matchFound = false
									fieldResult = nil
									break
								end
							else
								matchFound = false
								fieldResult = nil
								break
							end
						else
							matchFound = false
							fieldResult = nil
							break
						end
					rescue Exception => e
						Rho::Log.error("Error in evaluateApplicableDT--->#{e}\n#{e.backtrace}", "CommonUtil")
					end
					break if notinFlag
				end

				break if matchFound
				next if notinFlag
				#if no conditions exist (it means only the action exist) then consider that record as the matched DT record 
				fieldResult = fieldResultDO unless conditionsExist
			end

			#if no conditions matched return null;
			return fieldResult unless fieldResult
			
			#apply all the action.
			fieldResult.fieldValueList.each do |fieldValueDO|
				#check if the attribute is not an action then continue.
				next if quesSetDO.getQuestionSetQuestion(fieldValueDO.fieldCd.to_s).dataElementType.to_s != "ACTION" || fieldValueDO.fieldValue.to_s == ""
						
				fieldname = nil
				length = fieldValueDO.fieldCd.length
				strFieldCdArr = fieldValueDO.fieldCd.to_s.split("_")
				strStart = strFieldCdArr[0]
				strStart = strStart + "_"
				expressionFormed = fieldValueDO.fieldValue.to_s.gsub("&lt;", "<")
				expressionFormed = expressionFormed.gsub("&gt;", ">")
				expressionFormed = expressionFormed.gsub("DateDifferenceInDays","MobiSys::DateTimeUtils.dateDifferenceInDays")
				expressionFormed = expressionFormed.gsub("negativeSign","MobiSys::Math.negativeSign")
					
				if strStart.to_s == EXPRESSIONRULE
					fieldname = fieldValueDO.fieldCd.to_s[strStart.length..length]
				else
					fieldname = fieldValueDO.fieldCd
				end
				output = nil
				if strStart.to_s == EXPRESSIONRULE
					output = eval(expressionFormed)
				else
					output = fieldValueDO.fieldValue
				end
				if baseDO.is_a?(MobiSys::DataObjects::FieldResult)
					baseDOFieldValue =  baseDO.getFieldValue(fieldname)
					#if the fieldValue is already existing then set it in that else create new one
					if baseDOFieldValue
						baseDOFieldValue.fieldValue = output
					else
						baseDO.addFieldValue(nil, fieldname, output)
					end
				else
					baseDO.send(fieldname.to_sym, output)
				end
			end
			return fieldResult
		end
		##################################################################################################


		def self.registerException(entitySeq, fieldReference, exceptionCd, exceptionMessage, tabId, errorParameters=[])
			correspondenceMessage = createExceptionForAllLang(exceptionMessage, errorParameters)
			exceptionMessage = Localization::LabelCache.instance.getLabel(exceptionMessage.to_sym).to_s.force_encoding("UTF-8").clone
			exceptionMessage = replacePlaceHolders(exceptionMessage,errorParameters)
			exceptionMessageFromHash(exceptionMessage, errorParameters)
			if tabId.to_s == "" && $currentValidationMetadata
				tabId = $currentValidationMetadata.tabId.to_s
			elsif tabId.to_s == "" && $currentTabId
				tabId = $currentTabId.to_s
			end
			tabId.to_s.strip!

			$taskExceptionHash.push(TaskException.new(
				:entitySeq=>entitySeq,
				:fieldReference=>fieldReference,
				:exceptionCd=>exceptionCd,
				:tabId=>tabId,
				:exceptionMessage=>exceptionMessage,
				:correspondenceMessage=>correspondenceMessage.to_json
			))
		end
		#################################################################################################


		def self.createExceptionForAllLang(exceptionMessage1, errorParameters = [])
			exceptionCd = exceptionMessage1
			langMessageHM = {}
			languageLookup = Lookupvalue.find(
	            :all,
	            :conditions => {
	                {:name => "key"} => "LANGUAGE",
	                {
	                    :name => "cd",
	                    :op => "IN"
	                } => $rhoconfig[:supported_locales].upcase.split(",")
	            },
	            :op => "AND",
	            :select => ['cd','desc','defaultFl','sortOrder'],
	            :order => ['sortOrder']
	        )	        
			languageLookup.each do |language|
				exceptionMessage11 = createExceptionMessage(exceptionMessage1, language.cd, errorParameters)
				langMessageHM[language.cd] = exceptionMessage11.to_s != "" ? exceptionMessage11 : exceptionCd
			end
			return langMessageHM
		end

		def self.createExceptionMessage(exceptionMessage1, languageCd, errorParameters = [])
			exceptionMessage1 = LabelValue.getLabel(exceptionMessage1, languageCd.downcase)
			exceptionMessage12 = nil
			exceptionMessageFromHash(exceptionMessage1, errorParameters)
			errorParameters.each_with_index do |str, index|
				str = str.to_s
				str = LabelValue.getLabel(str, languageCd.downcase)
				exceptionMessage12 = exceptionMessage1.gsub("{"+(index+1).to_s+"}", str)
				exceptionMessage1.gsub!("{"+(index+1).to_s+"}", str) if exceptionMessage1.include?("{")
			end
			if errorParameters.empty?
				exceptionMessage12 = exceptionMessage1
			end
			return exceptionMessage12
		end

		def self.exceptionMessageFromHash(exceptionMessage, errorParameters, languageCd = nil)
			if exceptionMessage && errorParameters
				placeHolderValueHash = errorParameters.last.is_a?(Hash) ? errorParameters.last : {}
				placeHolderValueHash.each do |key, value|
					if languageCd.to_s != ""
						placeHolderLabel = LabelValue.getLabel(value, languageCd.downcase)
					else
						placeHolderLabel = Localization::LabelCache.instance.getLabel(value.to_sym).to_s.force_encoding("UTF-8").clone
					end
					exceptionMessage.gsub!(/\{#{key}\}/, placeHolderLabel) if exceptionMessage.include?("{#{key}}")
				end
			end
		end

		def self.createException(entitySeq, labelKey, objectOnWhichExcptionOccured, fieldNameforException, tabId, valuesToSubstInExc1 ='',valuesToSubstInExc2 ='',valuesToSubstInExc3 ='',valuesToSubstInExc4 ='',valuesToSubstInExc5 ='',valuesToSubstInExc6 ='')
	        errorParameters = [valuesToSubstInExc1,valuesToSubstInExc2,valuesToSubstInExc3,valuesToSubstInExc4,valuesToSubstInExc5,valuesToSubstInExc6]
	        exceptionMessage = Localization::LabelCache.instance.getLabel(labelKey.to_sym).to_s.force_encoding("UTF-8").clone
	        correspondenceMessage = createExceptionForAllLang(labelKey, [valuesToSubstInExc1,valuesToSubstInExc2,valuesToSubstInExc3,valuesToSubstInExc4,valuesToSubstInExc5,valuesToSubstInExc6])
	        exceptionMessage = replacePlaceHolders(exceptionMessage,errorParameters)
	        # objectOnWhichExcptionOccured = objectOnWhichExcptionOccured.objectToHash
	        if objectOnWhichExcptionOccured.is_a?(Array) && objectOnWhichExcptionOccured[0].is_a?(OpenStruct)
	        	objectOnWhichExcptionOccured = openstruct_to_hash(objectOnWhichExcptionOccured[0])
	        elsif objectOnWhichExcptionOccured.is_a?(OpenStruct)
	        	objectOnWhichExcptionOccured = openstruct_to_hash(objectOnWhichExcptionOccured)
	        else
	        	objectOnWhichExcptionOccured = objectOnWhichExcptionOccured.objectToHash
	        end
	        if tabId.to_s == ""
                if objectOnWhichExcptionOccured.key?(:visitedTabs) && objectOnWhichExcptionOccured[:visitedTabs].to_s != ""
                    tabId = objectOnWhichExcptionOccured[:visitedTabs]
                else
                    party = Party.loadObject(:first,:conditions =>{:object => objectOnWhichExcptionOccured[:parentKey]})
                    tabId = party.visitedTabs
                end
	        end
	        tabId.to_s.strip!
	        exceptionCd = "MODELEXC"
	        fieldReference = "#{objectOnWhichExcptionOccured[:guid]}-#{fieldNameforException}"
	        $taskExceptionHash.push(TaskException.new(
                :entitySeq=>entitySeq,
                :fieldReference=>fieldReference,
                :exceptionCd=>exceptionCd,
                :tabId=>tabId,
                :exceptionMessage=>exceptionMessage,
                :correspondenceMessage=>correspondenceMessage.to_json
	        ))
        end

        def self.openstruct_to_hash(object, hash = {})
	    	case object
	    	when OpenStruct then
	    		object.each_pair do |key, value|
	    		hash[key] = openstruct_to_hash(value)
	        end
	        hash
	    	when Array then
	    		object.map { |v| openstruct_to_hash(v) }
	      	else object
	      	end
	    end

		def self.getTaskExceptionList(entitySeq,tabIdList,tabName=nil)
			errors = {}
			errorTabs = ""
			incompleteTabs = []
			taskExceptionList = TaskException.find(
				:all,
				:conditions=>{
					:entitySeq=>entitySeq
				}
			)
			if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
				taskExceptionList.each do |taskException|
					taskException.exceptionMessage = langSpecificTaskException(taskException)
					taskException.tabId = taskException.tabId.to_s.strip == "" ? "Global" : taskException.tabId.to_s.strip
					if taskException.tabId.to_s.empty? || !(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).empty?
						fieldReference = taskException.fieldReference.to_s.split("-")
						fieldObjReference = fieldReference[0].to_s == "" ? "Global" : fieldReference[0].to_s
						fieldAttrReference = fieldReference[1].to_s == "" ? "Global" : fieldReference[1].to_s
						errors[taskException.tabId.to_s] = {} unless errors[taskException.tabId.to_s].is_a?(Hash)
						errors[taskException.tabId.to_s][fieldObjReference] = {} unless errors[taskException.tabId.to_s][fieldObjReference].is_a?(Hash)
						errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference] = "" if errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference].to_s == ""
						if errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference].include? (taskException.exceptionMessage.to_s)
							taskException.delete
						else
							if errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference] != ""
								errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference] << "; #{taskException.exceptionMessage.to_s}"
							else
								errors[taskException.tabId.to_s][fieldObjReference][fieldAttrReference] = taskException.exceptionMessage.to_s	
							end
						end
						if taskException.tabId.to_s.empty?
							errorTabs += ","+tabIdList.to_s
						elsif !(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).empty?
							errorTabs += ","+(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).join(",")
						end
					end
					if (tabName == nil || (tabName.to_s.include? (taskException.tabId.to_s)))
						incompleteTabs += (taskException.tabId.split(",") - tabIdList.to_s.split(","))
					end 
				end
			else
				taskExceptionList.each do |taskException|
					taskException.exceptionMessage = langSpecificTaskException(taskException)
					taskException.tabId = taskException.tabId.to_s.strip
					if taskException.tabId.to_s.empty? || !(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).empty?
						fieldReference = taskException.fieldReference.to_s.split("-")
						errors[taskException.tabId.to_s] = {} unless errors[taskException.tabId.to_s].is_a?(Hash)
						errors[taskException.tabId.to_s][fieldReference[0]] = {} unless errors[taskException.tabId.to_s][fieldReference[0]].is_a?(Hash)
						errors[taskException.tabId.to_s][fieldReference[0]][fieldReference[1]] = [] unless errors[taskException.tabId.to_s][fieldReference[0]][fieldReference[1]].is_a?(Array)
						if errors[taskException.tabId.to_s][fieldReference[0]][fieldReference[1]].include? (taskException.exceptionMessage.to_s)
							taskException.delete
						else
							errors[taskException.tabId.to_s][fieldReference[0]][fieldReference[1]].push(taskException.exceptionMessage.to_s)	
						end
						if taskException.tabId.to_s.empty?
							errorTabs += ","+tabIdList.to_s
						elsif !(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).empty?
							errorTabs += ","+(tabIdList.to_s.split(",") & taskException.tabId.to_s.split(",")).join(",")
						end
					end
					if (tabName == nil || (tabName.to_s.include? (taskException.tabId.to_s)))
						incompleteTabs += (taskException.tabId.split(",") - tabIdList.to_s.split(","))
					end 
				end
			end
			return errors, errorTabs, incompleteTabs.uniq
		end

		def self.getDistinctTaskExceptionMapList(entitySeq)
			listExceptionHM = []
			hmExceptions = {}
			taskExceptionList = TaskException.find(
				:all,
				:conditions=>{
					:entitySeq=>entitySeq
				}
			)
			taskExceptionList.each do |taskException|
				taskException.exceptionMessage = langSpecificTaskException(taskException)
				if !hmExceptions.has_key?(taskException.exceptionMessage.to_s)
					hmExceptions[taskException.exceptionMessage.to_s] = taskException
					listExceptionHM << taskException
				end
			end
			return listExceptionHM
		end

		def self.langSpecificTaskException(taskException)
			if taskException && taskException.correspondenceMessage.to_s != ""
				correspondenceMessageHash = Rho::JSON.parse(taskException.correspondenceMessage)
					if correspondenceMessageHash&.any?
						correspondenceMessageHash.each do |key, value|
						taskException.exceptionMessage = value if key.downcase.to_s == Application.getValue('DEFAULTLOCALE').value.downcase.to_s
					end
				end
			end
			return taskException.exceptionMessage
		end


		def self.getFieldError(errorList, baseDOObj, fieldName)
			errorMesg = nil
			if baseDOObj.to_s == "" || errorList.to_s == "" || fieldName.to_s == ""
				return errorMesg
			end
			errorMap = getLinkedHashedList("fieldReference",errorList) if errorList.to_s != ""
			if errorMap.to_s != "" && errorMap[baseDOObj.guid.to_s+"-"+fieldName].to_s != ""
				taskExceptionList = errorMap[baseDOObj.guid.to_s+"-"+fieldName]
				if taskExceptionList.to_s != ""
					taskExceptionDO = taskExceptionList[0]
					errorMesg = taskExceptionDO.exceptionMessage.to_s
				end
			end
			return errorMesg
		end
	

		#################################################################################################


		def self.clearTaskExceptionList(entitySeq)
			existingTaskEx = TaskException.delete_all(
				:conditions=>{
					:entitySeq=>entitySeq
				}
			)
		end
		#################################################################################################


		def self.getVisitedTabID(tabModule,filterType)
			lookupCd = nil
			lookupValue = Lookupvalue.loadObject(:all, :conditions=>{:key=> "TABID"})
			lookupValue.each do |lookup|
				if lookup.additionalField2 && lookup.additionalField2.split(',').include?(tabModule)
                	additionalField1List = lookup.additionalField1.to_s.split(",")
                	additionalField1List.each do |additionalField1| 
                   		lookupCd = lookup.cd  if additionalField1 == filterType
                	end
                end
            end
            return lookupCd
		end

		def self.copyFieldsOld(sourceObject, targetObject, fieldsToExcludeArr = [])
			if sourceObject != nil && targetObject != nil
				#Hashmap of attributes which do not match across models
				fieldsMapper = {
					:occupationClass    => "occupationCd",
					:firstName1         => "firstname",
					:lastName1          => "lastname",
					:proposalEntryDt    => "quotationDt",
					:proposalReceivedDt => "quotationDt",
					:proposalSignedDt   => "quotationDt",
					:policyIssueDt      => "quotationDt",
					:baseProductId      => "productId",
					:birthDt            => "dob",
					:jointLife          => "jointLifeFlag",
					:maritalStatusCd    => "maritalStatus",
					:educationLevelCd   => "educationCd"
				}
				sourceObjectFields = Rho::RhoConfig.sources[sourceObject.class.name.to_s]["schema"]["property"]
				targetObjectFields = Rho::RhoConfig.sources[targetObject.class.name.to_s]["schema"]["property"].keys

				if sourceObjectFields.size > 0
					sourceObjectFields.each do |sourceField, sourceType|
						next if !fieldsToExcludeArr.empty? && fieldsToExcludeArr.include?(sourceField.to_s)
						stmt = "sourceObject.#{sourceField}"
						attrValue = eval(stmt)
						if targetObjectFields.include?(sourceField) and attrValue != nil
							methodName = "#{sourceField}="
							targetObject.send(methodName, attrValue)
						elsif fieldsMapper.has_key?(sourceField) && fieldsMapper[sourceField].to_s != "" && targetObjectFields.include?(fieldsMapper[sourceField])
							methodName = "#{fieldsMapper[sourceField]}="
							targetObject.send(methodName, attrValue)
						else
							Rho::Log.error("#{targetObject.class.name.to_s} did not respond to #{sourceField}", "CommonUtil")
						end
					end
				end
			end

			return targetObject
		end

		def self.copyFields(sourceObject, targetObject, fieldsToExcludeArr = [])
	      return targetObject if sourceObject.nil? || targetObject.nil?
	      source_class_name = sourceObject.class.name.to_s
	      target_class_name = targetObject.class.name.to_s
	      source_config = Rho::RhoConfig.sources[source_class_name]
	      target_config = Rho::RhoConfig.sources[target_class_name]
	      return targetObject unless source_config && target_config
	      source_fields = source_config["schema"]["property"]
	      target_fields = target_config["schema"]["property"]
	      return targetObject if source_fields.nil? || source_fields.empty?
	      exclude_set = fieldsToExcludeArr.empty? ? nil : fieldsToExcludeArr.map(&:to_s).to_set
	      source_fields.each_key do |sourceField|
	        next if exclude_set && exclude_set.include?(sourceField.to_s)
	        source_field_sym = sourceField.to_sym
	        begin
	          attrValue = sourceObject.send(source_field_sym)
	          next if attrValue.nil?
	          target_field = sourceField.to_s
	          unless target_fields.has_key?(target_field)
	            mapped_field = FIELDS_MAPPER[source_field_sym]
	            if mapped_field && target_fields.has_key?(mapped_field.to_s)
	              target_field = mapped_field.to_s
	            else
	              rev_mapped_field = REVERSE_FIELDS_MAPPER[source_field_sym]
	              if rev_mapped_field && target_fields.has_key?(rev_mapped_field)
	                target_field = rev_mapped_field
	              else
	                next
	              end
	            end
	          end
	          targetObject.send("#{target_field}=", attrValue)
	        rescue => e
	        end
	      end
	      return targetObject
        end

		def self.addLookupData(baseIO, lookupKey, lookupDataHm)
			addtnlLookupList = Array.new
			baseIO.additionalData = {} if (baseIO.additionalData == nil || (baseIO.additionalData != nil and !baseIO.additionalData.is_a?(Hash)))  
			
			if(!baseIO.additionalData.has_key?("ADDTNL_LOOKUPDATA") || (baseIO.additionalData.has_key?("ADDTNL_LOOKUPDATA") and baseIO.additionalData["ADDTNL_LOOKUPDATA"] == nil))
				baseIO.additionalData["ADDTNL_LOOKUPDATA"] = Hash.new
			end

			if lookupDataHm.size > 0
				lookupDataHm.each do |lookupCd, lookupDesc|
					addtnlLookupHash = Hash.new
					addtnlLookupHash['cd'] = lookupCd.to_s
					addtnlLookupHash['desc'] = lookupDesc.to_s
					addtnlLookupList << addtnlLookupHash
				end

				baseIO.additionalData["ADDTNL_LOOKUPDATA"].merge!({lookupKey => addtnlLookupList})
			end
	   	end

	   	def self.getDoubleValue(stringParam)
	   		result = nil
	   		if stringParam.to_s !=""
	   			result = Float(stringParam)
	   		end
	   	end
	end

	class RuleCalculator
		LOGCATEGORY	= "RuleCalculator"
		attr_accessor :ruleDO
		attr_accessor :ruleName
		attr_accessor :facet
		attr_accessor :ruleMap

		def load
			if ruleMap && ruleMap.has_key?(ruleName)
				self.ruleDO = ruleMap[ruleName]
			else
				ruleMap = {} if ruleMap == nil				
				startTime = Time.now.to_i
				if ruleName.to_s == ""
					Rho::Log.error("Rule name associated needs to be set.", LOGCATEGORY)
				end
				#load the rule
				ruleDO = RuleDefinition.find(
					:first,
					:conditions => {
						:definitionCd => ruleName
					}
				)
				unless ruleDO
					Rho::Log.error("Rule definition #{ruleName} does not exist.", LOGCATEGORY)
				end
		        Rho::Log.info("Time taken to load #{ruleName}: #{Time.now.to_i - startTime}", LOGCATEGORY)
		        ruleMap[ruleName] = ruleDO
		        self.ruleDO = ruleDO
			end
		end
		##################################################################################################


		def evaluateRule(calculateDO)
			self.load
			evaluatedRecord = MobiSys::CommonUtil.evaluateApplicableDT(calculateDO, self.ruleDO)
			return evaluatedRecord
		end
		##################################################################################################
	end
end
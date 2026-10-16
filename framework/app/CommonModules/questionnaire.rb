#encoding: UTF-8
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'

module MobiSys
	module Questionnaire
		include MobiSys::BrowserHelper

		#############################################################################################
		######################Questionnaire Hash Generation & Validation Methods#####################
		#############################################################################################


		#Method to get the reflexive QuestionSetQuestion within a list of QuestionSetQuestions
		def self.getReflexiveQuestion(questionSetQuestionList)
			reflexiveQuestion = nil
			questionSetQuestionList.each do |questionSetQuestion|
				if questionSetQuestion[:conditional] == "REFLEXIVE"
					reflexiveQuestion = questionSetQuestion
					break
				end
			end
			return reflexiveQuestion
		end
		#############################################################################################


		#Method to create a hash of the entire questionnaire
		def self.setupQuestionnaireHash(questionSetCd, finalQ, questionSetHash, questionSetMapParentHash)
			return unless questionSetHash
			if questionSetHash[:questionSetTypeCd] == "PARENTWRAPPER" || questionSetHash[:questionSetTypeCd] == "WRAPPER"
				questionSetMapParentHash[questionSetCd].each do |qsetMap|
					if finalQ[qsetMap.childQuestionSetCd]
						questionSetHash["listQuestionSetDOList"] = [] if !questionSetHash["listQuestionSetDOList"].is_a?(Array)
						questionSetHash["listQuestionSetDOList"].push(finalQ[qsetMap.childQuestionSetCd])
						questionSetHash["listQuestionSetDOList"].last[:displayNumber] = qsetMap.displayNumber.to_s
						finalQ.delete(qsetMap.childQuestionSetCd)

						setupQuestionnaireHash(qsetMap.childQuestionSetCd, finalQ, questionSetHash["listQuestionSetDOList"].last, questionSetMapParentHash)
					end
				end
			elsif questionSetHash[:questionSetTypeCd] == "LEAF"
				#Loop over all ConditionalQuestionSetMaps and add them as QuestionSets within the same QuestionSet parent
				if questionSetHash.has_key?("listConditionalQuestionSetMapDOList")
					questionSetHash["listConditionalQuestionSetMapDOList"].sort_by!{|k| k[:displayOrder].to_i}
					questionSetHash["listConditionalQuestionSetMapDOList"].each do |qsetMap|
						if finalQ[qsetMap[:childQuestionSetCd]]
							questionSetHash["listQuestionSetDOList"] = [] if !questionSetHash["listQuestionSetDOList"].is_a?(Array)
							questionSetHash["listQuestionSetDOList"].push(finalQ[qsetMap[:childQuestionSetCd]])
							lastQuestionSetDO = questionSetHash["listQuestionSetDOList"].last
							if lastQuestionSetDO.has_key?("listQuestionSetQuestionDOList")
								unless questionSetHash[:childModelCd]
									reflexiveQuestionDOStatic = getReflexiveQuestion(lastQuestionSetDO["listQuestionSetQuestionDOList"])
									reflexiveQuestionDOCond = getReflexiveQuestion(questionSetHash["listQuestionSetQuestionDOList"]) if questionSetHash["listQuestionSetQuestionDOList"] != nil
								end

								lastQuestionSetDO["listQuestionSetQuestionDOList"].each do |questionSetQuestion|
									if reflexiveQuestionDOStatic
										if questionSetQuestion[:questionCd] == reflexiveQuestionDOStatic[:questionCd]
											questionSetQuestion[:condReflexiveValue] = qsetMap[:reflexiveValue]
											if reflexiveQuestionDOCond
												questionSetQuestion[:dataParent] = "#{reflexiveQuestionDOCond[:questionSetCd]}|#{reflexiveQuestionDOCond[:dataElementCd]}"
											else
												questionSetQuestion[:dataParent] = "#{questionSetHash[:questionSetCd]}"
												questionSetQuestion[:dataModelCd] = "#{questionSetHash[:childModelCd]}"
												questionSetQuestion[:dataModelElementQsetCd] = "#{questionSetHash[:childQSetCdModelElement]}"
											end
										else
											questionSetQuestion[:condReflexiveValue] = reflexiveQuestionDOStatic[:reflexiveValue].to_s != "" ? reflexiveQuestionDOStatic[:reflexiveValue] : "YES"
											questionSetQuestion[:dataParent] = "#{reflexiveQuestionDOStatic[:questionSetCd]}|#{reflexiveQuestionDOStatic[:dataElementCd]}"
										end
									else
										questionSetQuestion[:condReflexiveValue] = qsetMap[:reflexiveValue]
										if reflexiveQuestionDOCond
											questionSetQuestion[:dataParent] = "#{reflexiveQuestionDOCond[:questionSetCd]}|#{reflexiveQuestionDOCond[:dataElementCd]}"
										else
											questionSetQuestion[:dataParent] = "#{questionSetHash[:questionSetCd]}"
											questionSetQuestion[:dataModelCd] = "#{questionSetHash[:childModelCd]}"
											questionSetQuestion[:dataModelElementQsetCd] = "#{questionSetHash[:childQSetCdModelElement]}"
										end
									end
								end
							end
							finalQ.delete(qsetMap[:childQuestionSetCd])

							setupQuestionnaireHash(qsetMap[:childQuestionSetCd], finalQ, questionSetHash["listQuestionSetDOList"].last, questionSetMapParentHash)
						end
					end
				end
				#Loop over all QuestionSetQuestions and add dataParent & condReflexiveValue
				if questionSetHash.has_key?("listQuestionSetQuestionDOList")
					questionSetHash["listQuestionSetQuestionDOList"].sort_by!{|k| k[:displayOrder].to_i}
					reflexiveQuestionDOStatic = getReflexiveQuestion(questionSetHash["listQuestionSetQuestionDOList"])
					questionSetHash["listQuestionSetQuestionDOList"].each do |questionSetQuestion|
						if reflexiveQuestionDOStatic
							if questionSetQuestion[:questionCd] != reflexiveQuestionDOStatic[:questionCd]
								questionSetQuestion[:condReflexiveValue] = reflexiveQuestionDOStatic[:reflexiveValue].to_s != "" ? reflexiveQuestionDOStatic[:reflexiveValue] : "YES"
								questionSetQuestion[:dataParent] = "#{reflexiveQuestionDOStatic[:questionSetCd]}|#{reflexiveQuestionDOStatic[:dataElementCd]}"
							end
						end
						questionSetQuestion[:dataModelCd] = "#{questionSetHash[:childModelCd]}" if questionSetHash[:childModelCd].to_s != ''
						questionSetQuestion[:dataModelElementQsetCd] = "#{questionSetHash[:childQSetCdModelElement]}" if questionSetHash[:childQSetCdModelElement].to_s != ''
						if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
							if questionSetQuestion[:lookupkey].to_s != "" && $questionnaireLookups.to_s != "" && !$questionnaireLookups.include?(questionSetQuestion[:lookupkey].to_s)
								$questionnaireLookups.push(questionSetQuestion[:lookupkey].to_s)
							end
						end
					end
				end
			end
		end
		#############################################################################################


		#Method to create a hash of the entire questionnaire
		def setupApplicableQuestionnaireHash(questionSetCd, finalQ, questionSetHash, questionSetMapParentHash,quotation,policy,applicablePartyHash,removedPartyHash,party)
			if questionSetHash[:questionSetTypeCd] == "PARENTWRAPPER" || questionSetHash[:questionSetTypeCd] == "WRAPPER"
        		tempFinalQMap = {} if !tempFinalQMap.is_a?(Hash)
				removedPartyHash[party.guid] = {} if !removedPartyHash[party.guid].is_a?(Hash)
				applicablePartyHash[party.guid] = {} if !applicablePartyHash[party.guid].is_a?(Hash)
				quotationParty = quotation.getPartyByGuid(party.guid) if party.to_s!=""
				baseProduct = quotation.getBaseProduct
				questionSetMapParentHash[questionSetCd].each do |qsetMap|
					tempFinalQMap[qsetMap.childQuestionSetCd] = finalQ[qsetMap.childQuestionSetCd]
					if tempFinalQMap[qsetMap.childQuestionSetCd] && questionSetHash[:questionSetTypeCd] != "PARENTWRAPPER"
						# party = Party.loadObject(:first, :conditions=>{{:name=>'guid'}=>lifeGuid})
						if tempFinalQMap[qsetMap.childQuestionSetCd][:ruleSeq].to_s != ""
							if quotationParty
								pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(tempFinalQMap[qsetMap.childQuestionSetCd][:ruleSeq], quotation, baseProduct, quotationParty, false, false)
							end
							if pdt == nil || (quotationParty.to_s!="" && pdt != nil && pdt.outputAction != "YES")
								removedPartyHash[party.guid][qsetMap.childQuestionSetCd] = "YES"
								applicablePartyHash[party.guid].delete(qsetMap.childQuestionSetCd)
								next
							else
								applicablePartyHash[party.guid][qsetMap.childQuestionSetCd] = "YES"
							end
						else
							applicablePartyHash[party.guid][qsetMap.childQuestionSetCd] = "YES"
						end
					end
					if finalQ[qsetMap.childQuestionSetCd]
						questionSetHash["listQuestionSetDOList"] = [] if !questionSetHash["listQuestionSetDOList"].is_a?(Array)
						questionSetHash["listQuestionSetDOList"].push(finalQ[qsetMap.childQuestionSetCd])
						questionSetHash["listQuestionSetDOList"].last[:displayNumber] = qsetMap.displayNumber.to_s
						finalQ.delete(qsetMap.childQuestionSetCd)

						setupApplicableQuestionnaireHash(qsetMap.childQuestionSetCd, finalQ, questionSetHash["listQuestionSetDOList"].last, questionSetMapParentHash,quotation,policy,applicablePartyHash,removedPartyHash,party)
					end
				end
			end
		end
		#############################################################################################

		#Main Method to trigger the entire questionnaire hash creating mechanism
		def getApplicableQuestionnaire(questionSetData, questionSetMapData, questionSetCd, quotation, policy, party)
			questionSetMapParentHash = {}
			finalQ = {}
			applicablePartyHash = {}
			removedPartyHash = {}

			questionSetData.each do |questionSet|
				finalQ[questionSet.questionSetCd] = questionSet.hashForSync
			end

			questionSetMapData.each do |questionSetMap|
				questionSetMapParentHash[questionSetMap.parentQuestionSetCd] = [] if !questionSetMapParentHash[questionSetMap.parentQuestionSetCd].is_a?(Array)
				questionSetMapParentHash[questionSetMap.parentQuestionSetCd].push(questionSetMap)
			end
			setupApplicableQuestionnaireHash(questionSetCd, finalQ, finalQ[questionSetCd], questionSetMapParentHash, quotation, policy,applicablePartyHash,removedPartyHash,party)
			
			return applicablePartyHash , removedPartyHash
		end
		#############################################################################################

		#Method to create a response hash of all existing ServiceQuestionResponses for easy lookup
		def self.setupResponseHash(questionContainer)
			responseHash = {}

			questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
				next if serviceQuestionResponse.removed.to_s == 'YES'
				key = "#{serviceQuestionResponse.questionSetCd}|#{serviceQuestionResponse.questionDataElementCd}"
				key << "|#{serviceQuestionResponse.partyGuid}" if serviceQuestionResponse.partyGuid.to_s != ""
				key << "|#{serviceQuestionResponse.rowGuid}" if serviceQuestionResponse.rowGuid.to_s != ""
				responseHash[key] = serviceQuestionResponse
			end

			return responseHash
		end
		#############################################################################################


		#Main Method to trigger the entire questionnaire hash creating mechanism
		def self.getQuestionnaire(questionSetData, questionSetMapData, questionSetCd)
			questionSetMapParentHash = {}
			finalQ = {}

			questionSetData.each do |questionSet|
				finalQ[questionSet.questionSetCd] = questionSet.hashForSync
			end

			questionSetMapData.each do |questionSetMap|
				questionSetMapParentHash[questionSetMap.parentQuestionSetCd] = [] if !questionSetMapParentHash[questionSetMap.parentQuestionSetCd].is_a?(Array)
				questionSetMapParentHash[questionSetMap.parentQuestionSetCd].push(questionSetMap)
			end

			setupQuestionnaireHash(questionSetCd, finalQ, finalQ[questionSetCd], questionSetMapParentHash)
			return finalQ[questionSetCd]
		end
		#############################################################################################


		#Method to validate questionnaire using QuestionContainer & the QuestionSet hash
		def self.validateQuestionnaire(questionContainer, questionSetQuestionData, errors, party=nil)
			questionSetQuestionHash = {}
			questionSetQuestionData.each do |questionSetQuestion|
				questionSetQuestionHash["#{questionSetQuestion.questionSetCd}|#{questionSetQuestion.dataElementCd}"] = questionSetQuestion
			end
			listOfDocumentCdGenerated = []
			questTypeCd = questionContainer.entityTypeCd.to_s
			count = 0
			questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
				errors[:ServiceQuestionResponseDO] = Hash.new if !errors[:ServiceQuestionResponseDO].is_a?(Hash)
				errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym] = Hash.new if !errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym].is_a?(Hash)

				if serviceQuestionResponse.removed != "YES"
					key = "#{serviceQuestionResponse.questionSetCd}|#{serviceQuestionResponse.questionDataElementCd}"
					if party && questionSetQuestionHash[key].to_s!=""
						errorPlaceholder = MobiSys::BrowserHelper.getLabel(questionSetQuestionHash[key].questionCd) << " " << MobiSys::BrowserHelper.getLabel("for") << " " << party.getEntityDesc.to_s
					else
						errorPlaceholder = MobiSys::BrowserHelper.getLabel(questionSetQuestionHash[key].questionCd) if questionSetQuestionHash[key].to_s!=""
					end
					if questionSetQuestionHash.has_key?(key)
						if questionSetQuestionHash[key].mandatory.to_s == "YES" && serviceQuestionResponse.responseValue.to_s == ""
							if $rhoconfig[:TABFEATUREREQD]
								MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_MANDATORY", "ERR_MANDATORY", nil, [errorPlaceholder])
							else
								MobiSys::CommonUtil.addErrors(errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym],"responseValue", "ERR_MANDATORY",[errorPlaceholder])
							end
						elsif serviceQuestionResponse.responseValue.to_s != ""
							if questionSetQuestionHash[key].minValue.to_s != "" && (serviceQuestionResponse.responseValue.to_f < questionSetQuestionHash[key].minValue.to_f)
								if $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_MINVALUE", "ERR_MINVALUE", nil, [errorPlaceholder, questionSetQuestionHash[key].minValue, serviceQuestionResponse.responseValue])
								else
									MobiSys::CommonUtil.addErrors(errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym],"responseValue", "ERR_MINVALUE",[errorPlaceholder, questionSetQuestionHash[key].minValue, serviceQuestionResponse.responseValue])
								end
							end
							if questionSetQuestionHash[key].maxValue.to_s != "" && (serviceQuestionResponse.responseValue.to_f > questionSetQuestionHash[key].maxValue.to_f)
								if $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_MAXVALUE", "ERR_MAXVALUE", nil, [errorPlaceholder, questionSetQuestionHash[key].maxValue, serviceQuestionResponse.responseValue])
								else
									MobiSys::CommonUtil.addErrors(errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym],"responseValue", "ERR_MAXVALUE",[errorPlaceholder, questionSetQuestionHash[key].maxValue, serviceQuestionResponse.responseValue])
								end
							end
							if questionSetQuestionHash[key].maxLength.to_s != "" && (serviceQuestionResponse.responseValue.size > questionSetQuestionHash[key].maxLength.to_i)
								if $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_MAXLENGTH", "ERR_MAXLENGTH", nil, [errorPlaceholder, questionSetQuestionHash[key].maxLength])
								else
									MobiSys::CommonUtil.addErrors(errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym],"responseValue", "ERR_MAXLENGTH",[errorPlaceholder, questionSetQuestionHash[key].maxLength])
								end
							end
							if questionSetQuestionHash[key].inputTypeCd.to_s == "TEXT" && questionSetQuestionHash[key].dataElementType.to_s != "STRING" && questionSetQuestionHash[key].dataElementType.to_s != "" && !(serviceQuestionResponse.responseValue.to_s =~ /^[-+]?[0-9]*\.?[0-9]+$/)
								if $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.registerException(questionContainer.policyGuid, "#{serviceQuestionResponse.guid}-responseValue", "ERR_FORMAT", "ERR_FORMAT", nil, [errorPlaceholder, MobiSys::BrowserHelper.getLabel("NUMERIC")])
								else
									MobiSys::CommonUtil.addErrors(errors[:ServiceQuestionResponseDO][serviceQuestionResponse.guid.to_sym],"responseValue", "ERR_FORMAT",[errorPlaceholder, MobiSys::BrowserHelper.getLabel("NUMERIC")])
								end
							end
							if questionSetQuestionHash[key].documentCd.to_s != "" 
								if serviceQuestionResponse.responseValue.to_s == questionSetQuestionHash[key].reflexiveValue.to_s
									listOfDocumentCdGenerated.push questionSetQuestionHash[key].documentCd
								end
							end
						end
					end
				end
				count += 1
			end
			if count == 0 && questTypeCd.to_s != ""
				excCd = ""
				Localization::LabelCache.instance.getLabel(:ERR_MANDATORYFORQUEST).to_s != "" ? excCd = "ERR_MANDATORYFORQUEST" : excCd = "ERR_MANDATORYFOR"
				MobiSys::CommonUtil.registerException(questionContainer.policyGuid, nil, excCd, excCd, nil, [MobiSys::BrowserHelper.getLabel("questionnaire"), questTypeCd.to_s])
			end
			addDeleteQuestionGeneratedDocuments(questionContainer, listOfDocumentCdGenerated)
		end
		#############################################################################################



		#############################################################################################
		###############################Questionnaire Rendering Methods###############################
		#############################################################################################


		#Method to render checkboxes in questionnaire
		def renderQuestionnaireCheckBox(fieldName, selectedValue, id, currentValue, object=nil, adhocContent=nil)
			toreturn_str = ""
			begin
				toreturn_str << "<input type='checkbox' "
				name = ""
				if fieldName != nil
					if object != nil
						name = $objectMapping[object.object.to_s] + "[" + fieldName + "]"
						toreturn_str << "name='" + name + "' "
					else
						name = fieldName
						toreturn_str << "name='" + fieldName + "' "
					end
				end

				if id != nil
					toreturn_str << "id='" + id + "' "
				else
					toreturn_str << "id='" + fieldName + currentValue + "' "
				end

				if currentValue != nil
					toreturn_str << "value='" + currentValue + "' "
				end

				if selectedValue != nil && currentValue != nil && selectedValue == currentValue 
					toreturn_str << "checked "
				end

				if adhocContent != nil
					toreturn_str << adhocContent
				end

				toreturn_str << " />"
				if System.get_property('platform') == "ANDROID"
					toreturn_str << "\n"
					toreturn_str << "<script>" << "\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').click(function(){\n"
					toreturn_str << "$('input[type=\"text\"]:focus').blur();\n"
					toreturn_str << "$('textarea:focus').blur();\n"
					toreturn_str << "});\n"
					toreturn_str << "</script>"<< "\n"
					toreturn_str << "\n"
				end
			rescue StandardError => se
				puts se
			end

			return toreturn_str;
		end
		#############################################################################################


		#Method to render answer fields based on inputTypeCd
		def renderQuestionAnswer(questionSetQuestion, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
			output = ""
			displayProperty = ""
			maxLength = questionSetQuestion[:maxLength]
			parent = "data-questioncd='#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'"
			if reflexiveQuestionDO != nil && '#{reflexiveQuestionDO[:questionSetCd]}|#{reflexiveQuestionDO[:dataElementCd]}' != '#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'
				parentName = questionSetQuestion[:dataParent]
				if parentName.to_s != ""
					questionSetCd = parentName.split('|')[0]
					dataElementCd = parentName.split('|')[1]
					parentQ = QuestionSetQuestion.find(
			            :first, 
			            :conditions=>{
			                {:name=>'dataElementCd'} => dataElementCd,
			                {:name=>'questionSetCd'} => questionSetCd
			            },
			            :op => 'AND'
			        )
					parentResponseObj = getResponse(parentQ.hashForSync, isGridTypeFl, questionContainer, responseHash, quotationParty)
					if parentResponseObj && parentResponseObj.responseValue == questionSetQuestion[:condReflexiveValue]
						displayProperty = ""
						responseObj.removed = ""
					else
						displayProperty = "style='display:none;'"
						responseObj.removed = "YES"
					end
				end
				
				parent << " data-parent='#{questionSetQuestion[:dataParent]}'"
				parent << " data-reflexivevalue='#{questionSetQuestion[:condReflexiveValue]}'"
			end
            output << renderHiddenField("removed", responseObj.removed, nil, responseObj, parent)

            #set field readonly if enabled is 'NO' and render hidden field for value
			if questionSetQuestion[:enabled] && questionSetQuestion[:enabled].to_s == "NO"
				parent << " disabled='disabled'"
				output << renderHiddenField("responseValue", responseObj.responseValue, nil, responseObj)
			end

			case questionSetQuestion[:inputTypeCd]
			when "TEXT"
				parent << " maxLength= '#{maxLength}'"
				parent << " class='ui-input-text'"
				if questionSetQuestion[:dataElementType].to_s == "STRING" || questionSetQuestion[:dataElementType].to_s == ""
					output << renderInputField("responseValue", responseObj.responseValue, nil, responseObj, parent)
				else
					output << renderNumericField("responseValue", responseObj.responseValue, nil, responseObj, parent)
				end
			when "DATE"
				output << renderDateField("responseValue", responseObj.responseValue, nil, responseObj, parent)
			when "RADIO"
				parent << " onClick = '$(this).reflexiveParentChildDisplayMapping(this);'" if questionSetQuestion[:conditional] == "REFLEXIVE"
				radioLookup = Lookupvalue.find(:all, :conditions=>{'key'=>questionSetQuestion[:lookupkey]})
				lookups = Array.new
				if radioLookup && radioLookup.size > 0
					sortByOrderLookups,remainingLookups = radioLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
					sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
					remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
					lookups = sortByOrderLookups.concat remainingLookups
				end
				lookups.each do |lookup|
					output << renderRadioButton("responseValue", responseObj.responseValue, "#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}", lookup.cd, responseObj, parent,lookup.defaultFl)
					output << renderLabel("#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}", lookup.desc)
				end
			when "CHECKBOX"
				checkboxLookup = Lookupvalue.find(:all, :conditions=>{'key'=>questionSetQuestion[:lookupkey]})
				lookups = Array.new
				if checkboxLookup && checkboxLookup.size > 0
					sortByOrderLookups,remainingLookups = checkboxLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
					sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
					remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
					lookups = sortByOrderLookups.concat remainingLookups
				end
				output << "<fieldset data-role='controlgroup'>"
				lookups.each do |lookup|
					if questionSetQuestion[:lookupkey] != "YESNO"
						output << renderQuestionnaireCheckBox("responseValue", responseObj.responseValue, "#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}", lookup.cd, responseObj, parent)
						output << renderLabel("#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}", lookup.desc)
					elsif lookup.cd == "YES"
						output << renderQuestionnaireCheckBox("responseValue", responseObj.responseValue, "#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}", lookup.cd, responseObj, parent)
						output << renderLabel("#{getObjectMapping(responseObj)}_#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}_#{lookup.cd}",'',nil,nil,'style="width: 0px; padding-left: 1.4em;"')
					end
				end
				output << "</fieldset>"
			when "COMBO", "NCOMBO"
				parent << " onchange = '$(this).reflexiveParentChildDisplayMapping(this);'" if questionSetQuestion[:conditional] == "REFLEXIVE"
				output << getLookup(questionSetQuestion[:lookupkey], "responseValue", responseObj.responseValue, responseObj, nil, parent)
			when "TEXTAREA"
				parent << " maxLength= '#{maxLength}'"
				output << renderTextArea("responseValue", responseObj.responseValue.to_s, nil, responseObj, parent)
			when "HIDDEN"
				output << renderHiddenField("responseValue", responseObj.responseValue, nil, responseObj, parent)
			end
			return output,displayProperty
		end
		#############################################################################################


		#Method to render grid based questions
		def renderGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, quotationParty)
			if reflexiveQuestionDO != nil
				responseObj = getResponse(reflexiveQuestionDO, false, questionContainer, responseHash, quotationParty)
				strRetBuff << renderObject(responseObj, questionContainer)
				strRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
				strRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
				strRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
				strRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)			
				strRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)

				# if reflexiveQuestionDO[:inputTypeCd].to_s == "HIDDEN"
				# 	htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
				# 	strRetBuff << htmlString
				# else
					htmlString, displayProperty = renderQuestionAnswer(reflexiveQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty) 

					strRetBuff << "<div class='ui-grid-a questionGrid' #{displayProperty}>"
					if reflexiveQuestionDO[:mandatory].to_s == "YES"
						strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'><div class='ui-grid-a questionGrid'><div class='ui-block-a' style='width:40px;'>#{reflexiveQuestionDO[:displayNumber]}.</div><div class='ui-block-b' style='width:80%;'>" << getLabelValue(reflexiveQuestionDO[:questionCd]) << "</div><label for='*' class='mandatory1'>&nbsp;*</label></div></div>"
					else
						strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'><div class='ui-grid-a questionGrid'><div class='ui-block-a' style='width:40px;'>#{reflexiveQuestionDO[:displayNumber]}.</div><div class='ui-block-b' style='width:80%;'>" << getLabelValue(reflexiveQuestionDO[:questionCd]) << "</div></div></div>"
					end
					strRetBuff << "<div class='ui-block-b answer'>" << htmlString << "</div>"

					strRetBuff << "</div>"
				# end
			end
			reflexiveResponseObj = responseObj
			rowGuidArray = getRowGuidArray(questionSetQuestionList, reflexiveQuestionDO, responseHash, quotationParty)
			rowGuidArray.push(0) if rowGuidArray.empty?
			for i in rowGuidArray
				strRetBuff << "<div class='illustrationdisplay questionSetBlock' data-rowguid='#{i}' data-removed='false' for='#{getObjectMapping(reflexiveResponseObj)}'>"
				
				if i > 0
					strRetBuff << "<div class='ui-grid-d deleteButtonBlock'><div class='ui-block-a'></div><div class='ui-block-b'></div><div class='ui-block-c'></div><div class='ui-block-d'></div><div class='ui-block-e'>"
					strRetBuff << "<input type='button' data-inline='true' data-icon='delete' data-iconpos='notext' class='deleteButton'>"
					strRetBuff << "</div></div>"
				end

				questionSetQuestionList.each do |questionSetQuestionDO|
					if (reflexiveQuestionDO != nil && questionSetQuestionDO[:questionCd] != reflexiveQuestionDO[:questionCd]) || reflexiveQuestionDO == nil
						responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, quotationParty, i)
						strRetBuff << renderObject(responseObj, questionContainer)
						strRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
						strRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
						strRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
						strRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)
						strRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)
						strRetBuff << renderHiddenField("rowGuid", responseObj.rowGuid, nil, responseObj)

						# if questionSetQuestionDO[:inputTypeCd].to_s == "HIDDEN"
						# 	htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
						# 	strRetBuff << htmlString
						# else
							htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)

							strRetBuff << "<div class='ui-grid-a questionGrid' #{displayProperty}>"
							if questionSetQuestionDO[:mandatory].to_s == "YES"
								strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'>" << getLabelValue(questionSetQuestionDO[:questionCd]) << "<label for='*' class='mandatory1'>&nbsp;*</label></div>"
							else
								strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'>" << getLabelValue(questionSetQuestionDO[:questionCd]) << "</div>"
							end
							strRetBuff << "<div class='ui-block-b answer'>" << htmlString << "</div>"
							strRetBuff << "</div>"
						# end
					end
				end
				strRetBuff << "</div>"
				if displayProperty.to_s == "style='display:none;'"
					strRetBuff << "<script type=\"text/javascript\">
					$(document).ready(function(){
						$(\"div[for='#{getObjectMapping(reflexiveResponseObj)}'][data-rowguid='#{i}']\").css('display', 'none');
					});
					</script>"
				end
			end
			strRetBuff << "<div class='ui-grid-b addMoreButtonBlock' #{displayProperty} for='#{getObjectMapping(reflexiveResponseObj)}'><div class='ui-block-a'></div><div class='ui-block-b'>"
			strRetBuff << "<input type='button' class='addMoreButton' value='"
			strRetBuff << getLabelValue('Add More')
			strRetBuff << "' data-role='button' data-gridquestioncount='#{@totalQuestionSetQuestionCount}'>"
			strRetBuff << "</div><div class='ui-block-c'></div>"
			return displayProperty
		end
		#############################################################################################


		#Method to render non-grid based questions
		def renderNonGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, quotationParty)
			questionSetQuestionList.each do |questionSetQuestionDO|
				responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, quotationParty)
				strRetBuff << renderObject(responseObj, questionContainer)
				strRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
				strRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
				strRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
				strRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)
				strRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)

				# if questionSetQuestionDO[:inputTypeCd].to_s == "HIDDEN"
				# 	htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj,isGridTypeFl, questionContainer, responseHash, quotationParty)
				# 	strRetBuff << htmlString
				# else
					htmlString, displayProperty = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)

					strRetBuff << "<div class='ui-grid-a questionGrid' #{displayProperty}>"
					if questionSetQuestionDO[:mandatory].to_s == "YES"
						strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'><div class='ui-grid-a questionGrid'><div class='ui-block-a' style='width:40px;'>#{questionSetQuestionDO[:displayNumber]}.</div><div class='ui-block-b' style='width:80%;'>" << getLabelValue(questionSetQuestionDO[:questionCd]) << "</div><label for='*' class='mandatory1'>&nbsp;*</label></div></div>"
					else
						strRetBuff << "<div class='ui-block-a question' for='#{getObjectMapping(responseObj)}[responseValue]'><div class='ui-grid-a questionGrid'><div class='ui-block-a' style='width:40px;'>#{questionSetQuestionDO[:displayNumber]}.</div><div class='ui-block-b' style='width:80%;'>" << getLabelValue(questionSetQuestionDO[:questionCd]) << "</div></div></div>"
					end

					strRetBuff << "<div class='ui-block-b answer'>" << htmlString << "</div>"
					strRetBuff << "</div>"
				# end
            end
            return displayProperty
		end
		#############################################################################################


		#Method to get the reflexive QuestionSetQuestion within a list of QuestionSetQuestions
		def getReflexiveQuestion(questionSetQuestionList)
			reflexiveQuestion = nil
			questionSetQuestionList.each do |questionSetQuestion|
				if questionSetQuestion[:conditional] == "REFLEXIVE"
					reflexiveQuestion = questionSetQuestion
					break
				end
			end
			return reflexiveQuestion
		end
		#############################################################################################


		#Method to get an array of all rowGuid values within a list of QuestionSetQuestions
		def getRowGuidArray(questionSetQuestionList, reflexiveQuestionDO, responseHash, quotationParty)
			rowGuidArray = []
			questionSetQuestionList.each do |questionSetQuestion|
				if quotationParty
					partyRef = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{quotationParty.guid}"
				else
					partyRef = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				if (reflexiveQuestionDO != nil && questionSetQuestion[:questionCd] != reflexiveQuestionDO[:questionCd]) || reflexiveQuestionDO == nil
					responseHash.each do |key, response|
						if key.include?(partyRef)
							rowGuidArray.push(response.rowGuid.to_i)
						end
					end
				end
			end
			return rowGuidArray.uniq.sort!
		end
		#############################################################################################


		#Method to get a response of a specific QuestionSetQuestion or create a new one from the responseHash
		def getResponse(questionSetQuestion, isGridTypeFl, questionContainer, responseHash, quotationParty, rowGuid=nil)
			if isGridTypeFl
				if quotationParty
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{quotationParty.guid}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				key << "|#{rowGuid}" if rowGuid
				if !responseHash.has_key?(key) || responseHash[key] == nil
					values = {
						:entityGuid => questionContainer.policyGuid,
						:questionSetCd => questionSetQuestion[:questionSetCd],
						:questionDataElementCd => questionSetQuestion[:dataElementCd],
						:rowGuid => rowGuid,
						:removed => ""
					}

					serviceQuestionResponse = ServiceQuestionResponse.new(values)
					serviceQuestionResponse.partyGuid = quotationParty.guid if quotationParty
					serviceQuestionResponse.questionnaireTypeCd = questionContainer.questionnaireTypeCd

					#set response value if default lookup value is configured
					if questionSetQuestion[:lookupkey].to_s !=""
						lookup = Lookupvalue.find(
                            :first,
                            :conditions => {
                                {:name => 'key'} => questionSetQuestion[:lookupkey].to_s,
                                {:name => 'defaultFl'} => 'YES'
                            }
                        )
						if lookup
							serviceQuestionResponse.responseValue = lookup.cd
						end
					end
					questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
				else
					serviceQuestionResponse = responseHash[key]
				end
			else
				if quotationParty
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{quotationParty.guid}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				if !responseHash.has_key?(key) || responseHash[key] == nil
					values = {
						:entityGuid => questionContainer.policyGuid,
						:questionSetCd => questionSetQuestion[:questionSetCd],
						:questionDataElementCd => questionSetQuestion[:dataElementCd],
						:removed => ""
					}
					serviceQuestionResponse = ServiceQuestionResponse.new(values)
					serviceQuestionResponse.partyGuid = quotationParty.guid if quotationParty
					serviceQuestionResponse.questionnaireTypeCd = questionContainer.questionnaireTypeCd
					#set response value if default lookup value is configured
					if questionSetQuestion[:lookupkey].to_s !=""
						lookup = Lookupvalue.find(
                            :first,
                            :conditions => {
                                {:name => 'key'} => questionSetQuestion[:lookupkey].to_s,
                                {:name => 'defaultFl'} => 'YES'
                            }
                        )
						if lookup
							serviceQuestionResponse.responseValue = lookup.cd
						end
					end
					questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
					responseHash[key] = serviceQuestionResponse
				else
					serviceQuestionResponse = responseHash[key]
				end
			end
			return serviceQuestionResponse
		end
		#############################################################################################


		#Main Method to trigger the entire questionnaire rendering mechanism
		def renderQuestionnaire(questionnaireHash, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct)
			strRetBuff = ""
			header = ""
            displayProperty = ""
			if questionnaireHash[:header].to_s != ""
                if questionnaireHash[:displayNumber].to_s != ""
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                        header = "<div class='ui-grid-a header'><div class='ui-block-a' style='width: 40px;'></div><div class='ui-block-b'><b><u>#{questionnaireHash[:displayNumber]}. #{getLabelValue(questionnaireHash[:header])}</b></u></div></div><br>"
                    else
                        header = "<div class='legend header'><label class='strongLabel'>#{questionnaireHash[:displayNumber]}. #{getLabelValue(questionnaireHash[:header])}</label></div><br>"
                    end
                else
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                        header = "<div class='ui-grid-a header'><div class='ui-block-a' style='width: 40px;'></div><div class='ui-block-b'><b><u>#{getLabelValue(questionnaireHash[:header])}</b></u></div></div><br>"
                    else
                        header = "<div class='legend header'><label class='strongLabel'>#{getLabelValue(questionnaireHash[:header])}</label></div><br>"
                    end
                end
			end

			strRetBuff << "<div class='questionSetBlock' for='#{questionnaireHash[:object]}'>"
			strRetBuff << header
			
			if questionnaireHash.has_key?("listQuestionSetQuestionDOList")	
				reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if !reflexiveQuestionDO
				
				if questionnaireHash[:isGridTypeFl] == "YES"
					renderGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, strRetBuff, true, questionContainer, responseHash, quotationParty)
				else
                    renderNonGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, strRetBuff, false, questionContainer, responseHash, quotationParty)
				end
            end

			if questionnaireHash.has_key?("listQuestionSetDOList")
				questionnaireHash["listQuestionSetDOList"].each do |questionSetDO|
					if questionSetDO[:ruleSeq].to_s == ""
						reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
						strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct)
					else
						if quotationParty
			                pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(questionSetDO[:ruleSeq], quotation, baseProduct, quotationParty, false, false)
			            end
						if quotationParty.to_s!="" && pdt != nil && pdt.outputAction == "YES"
							reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
							strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct)
						else
							ServiceQuestionResponse.delete_all(
								:conditions => {
									{:name=>'parentkey'} => questionContainer.object,
									{:name=>'questionSetCd'} => questionSetDO[:questionSetCd]
								},
								:op => 'AND'
							)
						end
					end
				end
			end
			
			strRetBuff << "</div>"
			return strRetBuff
		end
		#############################################################################################

		def self.addDeleteQuestionGeneratedDocuments(questionContainer, documentCds)
			persistDocuments = false
			documentCdsToBeAdded = documentCds
			container = DocumentContainer.loadObject(:first, 
				:conditions=>{
					{:name=>'entityGuid'} => questionContainer.entityGuid, 
					{:name=>'policyGuid'} => questionContainer.policyGuid
				},
				:op => 'AND'
			)
			if container
				container.ServiceDocumentList.each do |sd|
					if sd.isAutoGeneratedFl.to_s == 'QUESTION'
						persistDocuments = true
						if (!documentCds.empty?) && (documentCds.include? sd.docCategoryCd)
							documentCdsToBeAdded.delete(sd.docCategoryCd)
						else
							sd.removed = 'YES' 
							Image.delete_all(
								:conditions => {
									{:name=>'parentRefGuid'} => sd.guid
								},
								:op => 'AND'
							)
						end
					end
				end
			else
				# creating document container
	            if !documentCdsToBeAdded.empty?
					container = DocumentContainer.new
		            container.entityGuid = questionContainer.entityGuid
		            container.entityTypeCd = 'Party'
		            container.policyGuid = questionContainer.policyGuid
		        end
			end
			documentCategoryMaps = DocumentCategoryMap.loadObject(:all,:conditions => {
                {
                    :name => "categoryCd",
                    :op => "IN"
                } => documentCdsToBeAdded
            },
            :select => ['documentCd,categoryCd']
            )
            
			if documentCategoryMaps
				documentCategoryMapHash = documentCategoryMaps.inject({}) {|hash, dcm| hash[dcm.categoryCd] = dcm.documentCd; hash}
				
				documentCdsToBeAdded.each do |categoryCd|
					puts documentCategoryMapHash[categoryCd]
		            persistDocuments = true
					serviceDocument = ServiceDocument.new
		            serviceDocument.partyGuid = questionContainer.entityGuid
		            serviceDocument.docCategoryCd = categoryCd
		            serviceDocument.documentCd = documentCategoryMapHash[categoryCd]
		            serviceDocument.acceptanceStatusCd = "PENDING"
		            serviceDocument.isAutoGeneratedFl = "QUESTION"
		            container.addServiceDocument(serviceDocument)
				end
				documentCdsToBeAdded.each do |documentCd|
		            persistDocuments = true
					serviceDocument = ServiceDocument.new
		            serviceDocument.partyGuid = questionContainer.entityGuid
		            serviceDocument.docCategoryCd = documentCd
		            serviceDocument.acceptanceStatusCd = "PENDING"
		            serviceDocument.isAutoGeneratedFl = "QUESTION"
		            container.addServiceDocument(serviceDocument)
				end
			end
			container.persistAll if persistDocuments
		end
	end
end

begin
	require 'CommonModules/questionnaire_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
	puts 'questionnaire_Jazz not included'
end

begin 
    require 'CommonModules/questionnaire_company'
rescue LoadError => e
    puts 'questionnaire_company not included'
end
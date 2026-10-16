require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'CommonModules/mobisysuihelper_jazz'

module MobiSys
	module Questionnaire
		include MobiSys::BrowserHelper
    	include MobiSys::UIHelper


		# Method to generate text field
		def printQuestionTextBox(nameAttr, id, value, visibility, enabled, inputType, minOccurs, entity, maxlength, datatype, adhocContent, adhocClass)
			toreturn_str = ""
			begin
				textalign = ""
				readOnly = ""
				className = "input-controll"
				type = "text"
				step = ""
				isNumeric = false
				isNumericString = false
				if datatype.to_s != "" && (datatype == 'DOUBLE' || datatype == 'SHORT' || datatype == 'LONG' || datatype == 'INTEGER')
					textalign = "style='text-align:left;' "
					className = "inputnum "
					type = "tel"
					isNumeric = true
					step = "step='any' "
				end
				
				isNumericString = true if inputType == 'NUMERICSTRING'

				unless enabled
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
					className = className + " readonly"
				end

				className = className +' '+ adhocClass if adhocClass
				
				toreturn_str << "<input type='#{type}' #{step} class='#{className}' "
				# To be checked -- may not be used
				# toreturn_str << "size='#{width}' "  
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' " if minOccurs.to_s != ''
				toreturn_str << readOnly
				# toreturn_str << "data-enhanced='true' " if isNumeric || isNumericString
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "value= '#{value}' "
				toreturn_str << "datatype='#{datatype}' " if datatype.to_s != ''
				toreturn_str << "style='display: none;' " unless visibility
				toreturn_str << textalign
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				# Converting field values to upper/lower case for certain fields
				toreturn_str << "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
				toreturn_str << "#{adhocContent} "
				toreturn_str << "/>"
			rescue Exception => e
				Rho::Log.error("Error in printQuestionTextBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate date control input
		def printQuestionDateControl(nameAttr, id, value, visibility, enabled, minOccurs, entity, maxlength, adhocContent, adhocClass)
			toreturn_str = ""
			begin
				readOnly = "readonly "
				className = "datepicker"
				onChange = "onChange='javascript:catchevent(this);' "
				
				unless enabled
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
					className = className + " inputreadonly"
					onChange = ""
				end
				
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = ""
				end
				className = className + ' '+ adhocClass if adhocClass

				toreturn_str << "<span class='dateicon'>"
				toreturn_str << "<input type='text' "
				toreturn_str << "class='#{className}' "
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' "
				toreturn_str << visibility
				toreturn_str << readOnly
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "value='#{value}' "
				# toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				toreturn_str << onChange
				toreturn_str << "#{adhocContent} "
				toreturn_str << "/>"
				toreturn_str << "</span>"
			rescue Exception => e
				Rho::Log.error("Error in printQuestionDateControl--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate radio buttons
		def printQuestionRadioButton(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, adhocContent, adhocClass)
			toreturn_str = ""
			begin
				readOnly = ""
				className = "input"
				paramCount = 0
				unless enabled
					readOnly = "readonly "+"onFocus='javascript:setNextFieldFocus(this,event);' "
					className = "inputreadonly"
				end
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = " "
				end
				className = className + ' '+ adhocClass if adhocClass

				if lookup.to_s != ""
					radioLookup = Lookupvalue.getValue(lookup)
					lookups = Array.new
					if radioLookup && radioLookup.size > 0
						sortByOrderLookups,remainingLookups = radioLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
						sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
						remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
						lookups = sortByOrderLookups.concat remainingLookups
					end
					lookups.each do |lookup|
						checked = ""
						if (value.to_s == lookup.cd.to_s) || (value.to_s=="" && lookup.defaultFl.to_s == "YES")
							checked = "checked "
						end
						toreturn_str << "<label class='label radioWidth' for='#{id}-#{paramCount}'>"
						toreturn_str << "<input type='radio' "
						toreturn_str << "class='#{className}' "
						toreturn_str << "name='#{nameAttr}' "
						toreturn_str << "id='#{id}-#{paramCount}' "
						toreturn_str << "entity='#{entity}' "
						toreturn_str << "minoccurs='#{minOccurs}' "
						toreturn_str << visibility
						if enabled
							toreturn_str << "onFocus='javascript:return fieldFocus(this);' "
							toreturn_str << "onClick='javascript:catchevent(this);' "
							toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
						#else
						#	toreturn_str << "onClick='return false;' "
						end
						toreturn_str << readOnly
						toreturn_str << "value='#{lookup.cd}' "
						toreturn_str << checked
						toreturn_str << "#{adhocContent} "
						toreturn_str << "/>"
						toreturn_str << Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)
						toreturn_str << "</label>"
						paramCount += 1
					end
				end
			rescue Exception => e
				Rho::Log.error("Error in printQuestionRadioButton--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate checkboxes
		def printQuestionCheckbox(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, adhocContent, adhocClass)
			toreturn_str = ""
			begin
				readOnly = ""
				className = "input"
				checkValue = ""
				unless enabled
					readOnly = "disabled "#+" onFocus='javascript:setNextFieldFocus(this);' "
					className = "inputreadonly"
				end
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = " "
				end
				className = className + ' '+ adhocClass if adhocClass

				if lookup.to_s != ""
					radioLookup = Lookupvalue.getValue(lookup)
					lookups = Array.new
					if radioLookup && radioLookup.size > 0
						sortByOrderLookups,remainingLookups = radioLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
						sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
						remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
						lookups = sortByOrderLookups.concat remainingLookups
					end
					paramCount = 0
					lookups.each do |lookup|
						checked = ""
						# if the lookup is a boolean lookup then mark the check box based on the value
						if lookup.key.to_s == "BOOLEAN" || lookup.key.to_s == "YESNO"
							if value == "YES" || value == "true"
								checked = "checked "
								checkValue = "YES"
							else
								checked = ""
								checkValue = "NO"
							end
						else
							if value.to_s==""
								checked = "checked " if lookup.defaultFl.to_s == "YES"
								checkValue = lookup.cd
							elsif value.split(",").include?(lookup.cd)
								checked = "checked "
								checkValue = lookup.cd
							else
								checkValue = lookup.cd
							end
						end
						
						toreturn_str << "<label class='label' for='#{id}-#{paramCount}'>"
						toreturn_str << "<input type='checkbox' "
						toreturn_str << "class='#{className}' "
						toreturn_str << "name='#{nameAttr}[]' "
						toreturn_str << "id='#{id}-#{paramCount}' "
						toreturn_str << "entity='#{entity}' "
						toreturn_str << "minoccurs='#{minOccurs}' "
						toreturn_str << "data-lookupkey='#{lookup.key}' "
						toreturn_str << visibility
						# if enabled
							# toreturn_str << "onFocus='javascript:return fieldFocus(this);' "
							toreturn_str << "onClick='javascript:inputFieldCheckClicked(this);' "
						# else
							# toreturn_str << "onClick='return false;' "
						# end
						toreturn_str << readOnly
						toreturn_str << "value= '#{checkValue}' "
						toreturn_str << checked
						toreturn_str << "#{adhocContent} "
						toreturn_str << "/>"
						toreturn_str << Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)
						toreturn_str << "</label>"
						# if boolean then print only one check box
						# for checkbox we add a hidden field that gets submitted since if checkbox is not checked null value is submitted.
						if lookup.key.to_s == "BOOLEAN" || lookup.key.to_s == "YESNO"
							hiddenFldName = nameAttr+"_hid"
							# if checkbox value is NO then the name of the hidden field is same as that of the actual field.
							hiddenFldName = nameAttr if value.to_s == "NO" || value.to_s == ""
							toreturn_str << "<input type='hidden' name='#{hiddenFldName}' value='NO' id='#{id}-#{paramCount}_hid'>"
							break
						end
						paramCount += 1
					end
				end
			rescue Exception => e
				Rho::Log.error("Error in printQuestionCheckbox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate select box
		def printQuestionSelectBox(nameAttr, id, value, lookup, visibility, enabled, inputType, minOccurs, entity, adhocContent, adhocClass)
			begin
				toreturn_str = ''
				className = ''
				readOnly = ''
				onChange = "onChange='javascript:catchevent(this);' "#doOnChangeSelect(this);' "
				isReadOnly = false
				selectedstring = ''
				lookups = []
				if lookup.to_s != ""
					offline_lookup_m = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookup})
        			selectLookup = []
					if offline_lookup_m
    					tempLookup = Lookupvalue.new
				        tempLookup.cd = value
				        tempLookup.desc = getLabelValue(value.to_s)
				        selectLookup.push tempLookup
					else						
						selectLookup = Lookupvalue.getValue(lookup)
					end
			      	if selectLookup && selectLookup.size > 0
				        sortByOrderLookups,remainingLookups = selectLookup.partition{|lookup| lookup.sortOrder.to_s != ""}
				        sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
				        remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
				        lookups = sortByOrderLookups.concat remainingLookups
			      	end
					value = Lookupvalue.getDefaultLookupValue(lookup,lookups) if value.to_s == ''
				end
			
				unless enabled
					isReadOnly = true
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
					className = "inputreadonly "
				end
				className = className + ' '+ adhocClass if adhocClass
				
				toreturn_str << "<select class='#{className}' "
				toreturn_str << "data-lookupkey='#{lookup}'"
				if inputType == 'NCOMBO'
					toreturn_str << "name='#{nameAttr}[]' "
				else
					toreturn_str << "name='#{nameAttr}' "
				end
				toreturn_str << "id='#{id}' "
				toreturn_str << "minoccurs='#{minOccurs}' " if minOccurs.to_s != ''
				toreturn_str << "multiple = 'multiple' data-native-menu='false' " if inputType == 'NCOMBO'
				toreturn_str << readOnly
				toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				toreturn_str << onChange
				toreturn_str << " #{adhocContent} "

				unless visibility
					toreturn_str << "style='display: none;' "
				end
				toreturn_str << ">"
				toreturn_str << "<option value='' #{selectedstring}>"+ Localization::LabelCache.instance.getLabel("select".to_sym) +" </option>"
				isSelected = false
				if lookups && lookups.length > 0
					lookups.each do |lookup|
						if inputType == 'NCOMBO'
							valueArr = value.split(",")
							valueArr.each do |val|
								if (val.to_s != '' and val.to_s == lookup.cd.to_s) || (val.to_s=="" && lookup.defaultFl.to_s == "YES")
									selectedstring = "selected"
									isSelected = true
									break
								else
									selectedstring = ""
								end
							end
						else
							if (value.to_s != '' and value.to_s == lookup.cd.to_s) || (value.to_s=="" && lookup.defaultFl.to_s == "YES")
								selectedstring = "selected"
								isSelected = true
							else
								selectedstring = ""
							end
						end
						if lookup.desc.to_s != ''
							toreturn_str << "<option value='#{lookup.cd}' #{selectedstring}>" + Localization::LabelCache.instance.getLabel(lookup.desc.to_sym) + "</option>"
						else
							toreturn_str << "<option value='#{lookup.cd}' #{selectedstring}>"+ lookup.cd + "</option>"
						end
					end
				end
				toreturn_str << "</select>"
				if inputType == 'NCOMBO'
					toreturn_str << "<input type='hidden' "
					toreturn_str << "name='#{nameAttr}' "
					toreturn_str << "value=''/>"
				end
			rescue Exception => e
				Rho::Log.error("Error in printQuestionSelectBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate textarea
		def printQuestionTextArea(nameAttr, id, value, visibility, enabled, minOccurs, entity, adhocContent, adhocClass, maxlength)
			toreturn_str = ""
			begin
				readOnly = ""
				className = "input"
				
				unless enabled
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
					className = "inputreadonly"
				end

				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = ""
				end
				className = className + ' '+ adhocClass if adhocClass
				
				toreturn_str << "<textarea class='#{className} inputta' " 
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' "
				toreturn_str << visibility
				toreturn_str << readOnly
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "#{adhocContent} "
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				toreturn_str << "oninput='javascript:return validateKeyPress(event,this,\"#{@locale}\");' "
				toreturn_str << "onChange='javascript:return validateField(this,\"#{@locale}\");' >"
				toreturn_str << "#{value}"
				toreturn_str << "</textarea>"
			rescue Exception => e
				Rho::Log.error("Error in printQuestionTextArea--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate hidden field
		def printQuestionHiddenField(nameAttr, id, value)
			toreturn_str = ""
			begin
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}'/>"
			rescue Exception => e
				Rho::Log.error("Error in printQuestionHiddenField--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end
		#############################################################################################


		# Method to generate field errors
		def errorQuestionTag(errorMessageList)
			errorMessage = ""
			errorLink = ""
			begin
				id = "#{$objectMapping[@currentTagObject.object.to_s]}_responseValue_err"
				errorMessage << "<span class='question-error-text'>"
				errorMessage << "#{errorMessageList.join('<br>')}"
				errorMessage << "</span>"
				errorLink << "<a href='##{id}' data-rel='popup' data-position-to='window' data-transition='pop' class='icon-error-message'></a>"

				errorMessage << "<div data-role='popup' id='#{id}' data-theme='a' class='ui-corner-all popup-wrapper error-popup'>"
				errorMessage << "<div class='popup-close-cust'>"
				errorMessage << "<a href='#' data-rel='back' class='icon-close'></a>"
				errorMessage << "</div>"
				errorMessage << "<div class='close-before-save'>"
				errorMessage << "<h3>#{getLabelValue('errorList')}</h3>"
				errorMessageList.each do |message|
					errorMessage << "<p>#{message}</p>"
				end
				errorMessage << "</div>"
				errorMessage << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in errorQuestionTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return errorLink, errorMessage
		end
		#############################################################################################


		#Method to render answer fields based on inputTypeCd
		def renderQuestionAnswer(questionSetQuestion, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
			output = ""
			displayProperty = ""
			parentReference = ""
			parent = "data-questioncd='#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}' "
			parent << "data-applyon='#{questionSetQuestion[:applyOn]}' " if questionSetQuestion[:applyOn].to_s != ''
			parent << "data-modelcd='#{questionSetQuestion[:dataModelCd]}' " if questionSetQuestion[:dataModelCd].to_s != '' 
			parent << "data-impactedqsetcds='#{questionSetQuestion[:impactedQSetCd]}' " if questionSetQuestion[:impactedQSetCd].to_s != '' 
			parent << "data-elementname='#{questionSetQuestion[:dataModelElementQsetCd]}' " if questionSetQuestion[:dataModelElementQsetCd].to_s != ''

			if reflexiveQuestionDO != nil && '#{reflexiveQuestionDO[:questionSetCd]}|#{reflexiveQuestionDO[:dataElementCd]}' != '#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'
				parentName = questionSetQuestion[:dataParent]
				if parentName.to_s != "" && parentName.split('|').size == 2
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
				parentReference = "#{questionSetQuestion[:dataParent]}|#{questionSetQuestion[:condReflexiveValue]}" if questionSetQuestion[:dataParent].to_s != ''
				parent << " data-parent='#{questionSetQuestion[:dataParent]}'" if questionSetQuestion[:dataParent].to_s != ''
				parent << " data-reflexivevalue='#{questionSetQuestion[:condReflexiveValue]}'" if questionSetQuestion[:condReflexiveValue].to_s != ''
			end
            output << renderHiddenField("removed", responseObj.removed, nil, responseObj, parent)

			nameAttr = "#{$objectMapping[@currentTagObject.object.to_s]}[responseValue]"
			id = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
			value = responseObj.responseValue
			visibility = questionSetQuestion[:visibility].to_s == "NO" ? false : true
			enabled = questionSetQuestion[:enabled].to_s == "NO" ? false : true
			inputType = questionSetQuestion[:inputTypeCd]
			minOccurs = questionSetQuestion[:mandatory].to_s == "YES" ? "1" : "0"
			entity = questionSetQuestion[:entityFieldTypeCd].to_s
			maxlength = questionSetQuestion[:maxLength].to_s
			datatype = questionSetQuestion[:dataElementType].to_s
			lookup = questionSetQuestion[:lookupkey].to_s

			entityTypeDO = nil
			entityTypeDO = EntityType.loadObject(
				:first,
				:conditions => {
					{:name => 'entityFieldTypeCd'} => questionSetQuestion[:entityFieldTypeCd]
				}
			)
			unless entityTypeDO
				Rho::Log.error("No DataElementDO created for #{questionSetQuestion[:questionSetCd]}", LOGCATEGORY)
			else
				entityTypeDO.EntityPropertyList.each do |entityProperty|
					if entityProperty.propertyCd.to_s == "MAXLENGTH" && maxlength == ""
						maxlength = entityProperty.propertyValue.to_s
					end
				end
			end

            #set field readonly if enabled is 'NO' and render hidden field for value
			if questionSetQuestion[:enabled] && questionSetQuestion[:enabled].to_s == "NO" && questionSetQuestion[:inputTypeCd] != "CHECKBOX"
				parent << " disabled='disabled'"
				output << printQuestionHiddenField(nameAttr, id, value)
			end
			adhocClass = (questionSetQuestion[:conditional] == "REFLEXIVE" || questionSetQuestion[:applyOn] == "YES") ? "callReflexiveClass" : ''

			case questionSetQuestion[:inputTypeCd]

			when "TEXT"
				output << printQuestionTextBox(nameAttr, id, value, visibility, enabled, inputType, minOccurs, entity, maxlength, datatype, parent, adhocClass)

			when "DATE"
				output << printQuestionDateControl(nameAttr, id, value, visibility, enabled, minOccurs, entity, maxlength, parent, adhocClass)
			when "RADIO"
				output << printQuestionRadioButton(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, parent, adhocClass)
			when "CHECKBOX"
				output << printQuestionCheckbox(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, adhocContent, adhocClass)
			when "COMBO", "NCOMBO"
				output << printQuestionSelectBox(nameAttr, id, value, lookup, visibility, enabled, inputType, minOccurs, entity, parent, adhocClass)
			when "TEXTAREA"
				output << printQuestionTextArea(nameAttr, id, value, visibility, enabled, minOccurs, entity, parent, adhocClass,maxlength)
			when "HIDDEN"
				output << printQuestionHiddenField(nameAttr, id, value)
			end
			return output,displayProperty,parentReference
		end
		#############################################################################################


		#Method to render grid based questions
		def renderGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, quotationParty, condReflexiveQuestionDO=nil)
			displayProperty = ''
			finalParentReference = ''
			if reflexiveQuestionDO != nil
				responseObj = getResponse(reflexiveQuestionDO, false, questionContainer, responseHash, quotationParty)
				modelStrRetBuff = modelTagStart("", responseObj, questionContainer, nil, false)

				errorMessageList = []
				errorStyle = ""
				if @errors!=nil && !@errors.empty?
					@errors.each do |tabId, tabErrors|
						if tabErrors.has_key?(@currentTagObject.guid) && tabErrors[@currentTagObject.guid].has_key?('responseValue') && !tabErrors[@currentTagObject.guid]['responseValue'].empty?
							errorMessageList += tabErrors[@currentTagObject.guid]['responseValue']
							errorStyle = "question-error-msg"
						end
					end
				end
				errorLink, errorMessage = errorQuestionTag(errorMessageList) unless errorMessageList.empty?
				
				if condReflexiveQuestionDO
					htmlString, displayProperty, parentReference = renderQuestionAnswer(reflexiveQuestionDO, condReflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty) 
				else
					htmlString, displayProperty, parentReference = renderQuestionAnswer(reflexiveQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty) 
				end
				strRetBuff << "<li class='questionGrid' #{displayProperty} for='#{getObjectMapping(responseObj)}[responseValue]'>"
				strRetBuff << modelStrRetBuff
				strRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
				strRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
				strRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
				strRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)
				strRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)
				if reflexiveQuestionDO[:mandatory].to_s == "YES"
					strRetBuff << "<p class='circle'><span>#{reflexiveQuestionDO[:displayNumber]}</span></p>"
					strRetBuff << "<div class='row-info-bg #{errorStyle}'>"
					strRetBuff << "<p for='#{reflexiveQuestionDO[:questionSetCd]}|#{reflexiveQuestionDO[:dataElementCd]}'>#{getLabelValue(reflexiveQuestionDO[:questionCd])}"
					strRetBuff << "<span id='#{reflexiveQuestionDO[:questionSetCd]}|#{reflexiveQuestionDO[:dataElementCd]}_lblsm' class='mandatory'>*</span>"
					strRetBuff << errorLink unless errorMessageList.empty?
					strRetBuff << "</p>"
				else
					strRetBuff << "<p class='circle'><span>#{reflexiveQuestionDO[:displayNumber]}</span></p>"
					strRetBuff << "<div class='row-info-bg #{errorStyle}'>"
					strRetBuff << "<p>#{getLabelValue(reflexiveQuestionDO[:questionCd])}"
					strRetBuff << errorLink unless errorMessageList.empty?
					strRetBuff << "</p>"
				end
				strRetBuff << "<p class='answer declaration-radio'>" << htmlString << "</p>"
				strRetBuff << errorMessage unless errorMessageList.empty?

				strRetBuff << "</div>"
				strRetBuff << "</li>"
				modelTagEnd
			end
			reflexiveResponseObj = responseObj
			rowGuidArray = getRowGuidArray(questionSetQuestionList, reflexiveQuestionDO, responseHash, quotationParty)
			rowGuidArray.push(0) if rowGuidArray.empty?
			for i in rowGuidArray
				strRetBuff << "<ul class='declaration-text questionSetBlock' data-rowguid='#{i}' data-removed='false' for='#{getObjectMapping(reflexiveResponseObj)}'>"
				
				if i > 0
					strRetBuff << "<div class='ui-grid-d deleteButtonBlock'><div class='ui-block-a'></div><div class='ui-block-b'></div><div class='ui-block-c'></div><div class='ui-block-d'></div><div class='ui-block-e'>"
					strRetBuff << "<input type='button' data-inline='true' data-icon='delete' data-iconpos='notext' class='deleteButton'>"
					strRetBuff << "</div></div>"
				end
				
				questionSetQuestionList.each do |questionSetQuestionDO|
					parentReference = ''
					if (reflexiveQuestionDO != nil && questionSetQuestionDO[:questionCd] != reflexiveQuestionDO[:questionCd]) || reflexiveQuestionDO == nil
						responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, quotationParty, i)
						modelStrRetBuff = modelTagStart("", responseObj, questionContainer, nil, false)
						
						errorMessageList = []
						errorStyle = ""
						if @errors!=nil && !@errors.empty?
							@errors.each do |tabId, tabErrors|
								if tabErrors.has_key?(@currentTagObject.guid) && tabErrors[@currentTagObject.guid].has_key?('responseValue') && !tabErrors[@currentTagObject.guid]['responseValue'].empty?
									errorMessageList += tabErrors[@currentTagObject.guid]['responseValue']
									errorStyle = "question-error-msg"
								end
							end
						end
						errorLink, errorMessage = errorQuestionTag(errorMessageList) unless errorMessageList.empty?
						if reflexiveQuestionDO
							htmlString, displayProperty, parentReference = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
						else
							htmlString, displayProperty, parentReference = renderQuestionAnswer(questionSetQuestionDO, condReflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
						end
						strRetBuff << "<li class='questionGrid' #{displayProperty} for='#{getObjectMapping(responseObj)}[responseValue]'>"
						strRetBuff << modelStrRetBuff
						strRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
						strRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
						strRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
						strRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)
						strRetBuff << renderHiddenField("rowGuid", responseObj.rowGuid, nil, responseObj)
						strRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)
						if questionSetQuestionDO[:mandatory].to_s == "YES"
							strRetBuff << "<div class='row-info-bg #{errorStyle}'>"
							strRetBuff << "<p for='#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}'>#{getLabelValue(questionSetQuestionDO[:questionCd])}"
							strRetBuff << "<span id='#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}_lblsm' class='mandatory'>*</span>"
							strRetBuff << errorLink unless errorMessageList.empty?
							strRetBuff << "</p>"
						else
							strRetBuff << "<div class='row-info-bg #{errorStyle}'>"
							strRetBuff << "<p>#{getLabelValue(questionSetQuestionDO[:questionCd])}"
							strRetBuff << errorLink unless errorMessageList.empty?
							strRetBuff << "</p>"
						end

						strRetBuff << "<p class='answer declaration-radio'>" << htmlString << "</p>"
						strRetBuff << errorMessage unless errorMessageList.empty?

						strRetBuff << "</div>"
						strRetBuff << "</li>"
						modelTagEnd
					end
				end
				strRetBuff << "</ul>"
				if displayProperty.to_s == "style='display:none;'" && reflexiveResponseObj
					strRetBuff << "<script type=\"text/javascript\">
					$(document).ready(function(){
						$(\"ul[for='#{getObjectMapping(reflexiveResponseObj)}'][data-rowguid='#{i}']\").css('display', 'none');
					});
					</script>"
				end
			end
			strRetBuff << "<div class='ui-grid-b addMoreButtonBlock' #{displayProperty} for='#{getObjectMapping(reflexiveResponseObj)}'><div class='ui-block-a'></div><div class='ui-block-b'>"
			strRetBuff << "<input type='button' class='addMoreButton' value='"
			strRetBuff << getLabelValue('Add More')
			strRetBuff << "' data-role='button' data-gridquestioncount='#{@totalQuestionSetQuestionCount}'>"
			strRetBuff << "</div><div class='ui-block-c'></div>"
			return displayProperty, finalParentReference
		end
		#############################################################################################


		#Method to render non-grid based questions
		def renderNonGridQuestions(questionSetQuestionList, reflexiveQuestionDO, strRetBuff, isGridTypeFl, questionContainer, responseHash, quotationParty, policy, childQsetCds)
			displayProperty = ''
			finalParentReference = ''
			questionSetQuestionList.each do |questionSetQuestionDO|
				parentResponse = nil
				if questionSetQuestionDO[:dataParent].to_s != "" && questionSetQuestionDO[:condReflexiveValue].to_s  != "SYSTEM_EXPRESSION"
					parentResponse = responseHash["#{questionSetQuestionDO[:dataParent]}#{"|#{quotationParty.guid}" if quotationParty}"]
					next if questionSetQuestionDO[:condReflexiveValue] != nil && (parentResponse == nil || parentResponse.responseValue != questionSetQuestionDO[:condReflexiveValue])
				end
				if $parentQuestionCd
					next if $parentQuestionCd.to_s == "#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}"
				end
				if questionSetQuestionDO[:dataModelCd].to_s != '' && policy
					life = policy.PartyList.select{|x| x.guid == quotationParty.guid}.first
					if $policyModelList && ($policyModelList.include? questionSetQuestionDO[:dataModelCd].to_s)
						# do nothing
 					else
 						$policyModelList.push questionSetQuestionDO[:dataModelCd].to_s if $policyModelList
						childQuestionSetCds = MobiSys::Questionnaire.evaluateExpressionBasedReflexiveQuestionSet(questionSetQuestionDO[:dataModelCd], questionSetQuestionDO[:dataModelElementQsetCd], questionContainer, life, policy)
 					end
					if childQsetCds.to_s == ''
						childQsetCds << childQuestionSetCds if childQuestionSetCds.to_s != ''
					else
						childQsetCds << ",#{childQuestionSetCds}" if childQuestionSetCds.to_s != ''
					end
					if questionSetQuestionDO[:condReflexiveValue].to_s == 'SYSTEM_EXPRESSION'
						next unless childQsetCds.split(',').include? questionSetQuestionDO[:questionSetCd]
					end
				end
				childStrRetBuff = ''
				parentReference = ''
				responseObj = getResponse(questionSetQuestionDO, isGridTypeFl, questionContainer, responseHash, quotationParty)
				modelStrRetBuff = modelTagStart("", responseObj, questionContainer, nil, false)
				if questionSetQuestionDO[:question].to_s == ''
					childStrRetBuff << "<li class='questionGrid dummyQuestionClass' style='display:none;' for='#{getObjectMapping(responseObj)}[responseValue]' data-onlyquestionsetcd='#{questionSetQuestionDO[:questionSetCd]}'>"
				else
					childStrRetBuff << "<li class='questionGrid' #{displayProperty} for='#{getObjectMapping(responseObj)}[responseValue]' data-onlyquestionsetcd='#{questionSetQuestionDO[:questionSetCd]}'>"
				end
				childStrRetBuff << modelStrRetBuff
				childStrRetBuff << renderHiddenField("partyGuid", responseObj.partyGuid, nil, responseObj)
				childStrRetBuff << renderHiddenField("entityGuid", responseObj.entityGuid, nil, responseObj)
				childStrRetBuff << renderHiddenField("questionSetCd", responseObj.questionSetCd, nil, responseObj)
				childStrRetBuff << renderHiddenField("questionDataElementCd", responseObj.questionDataElementCd, nil, responseObj)
				childStrRetBuff << renderHiddenField("questionnaireTypeCd", responseObj.questionnaireTypeCd, nil, responseObj)

				errorMessageList = []
				errorStyle = ""
				if @errors!=nil && !@errors.empty?
					@errors.each do |tabId, tabErrors|
						if tabErrors.has_key?(@currentTagObject.guid) && tabErrors[@currentTagObject.guid].has_key?('responseValue') && !tabErrors[@currentTagObject.guid]['responseValue'].empty?
							errorMessageList += tabErrors[@currentTagObject.guid]['responseValue']
							errorStyle = "question-error-msg"
						end
					end
				end
				errorLink, errorMessage = errorQuestionTag(errorMessageList) unless errorMessageList.empty?
				
				htmlString, displayProperty, parentReference = renderQuestionAnswer(questionSetQuestionDO, reflexiveQuestionDO, responseObj, isGridTypeFl, questionContainer, responseHash, quotationParty)
				
				if questionSetQuestionDO[:mandatory].to_s == "YES"
					childStrRetBuff << "<p class='circle'><span>#{questionSetQuestionDO[:displayNumber]}</span></p>"
					childStrRetBuff << "<div class='row-info-bg #{errorStyle}'>"
					childStrRetBuff << "<p for='#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}'>#{getLabelValue(questionSetQuestionDO[:questionCd])}"
					childStrRetBuff << "<span id='#{questionSetQuestionDO[:questionSetCd]}|#{questionSetQuestionDO[:dataElementCd]}_lblsm' class='mandatory'>*</span>"
					childStrRetBuff << errorLink unless errorMessageList.empty?
					childStrRetBuff << "</p>"
				else
					childStrRetBuff << "<p class='circle'><span>#{questionSetQuestionDO[:displayNumber]}</span></p>"
					childStrRetBuff << "<div class='row-info-bg #{errorStyle}'>"
					childStrRetBuff << "<p>#{getLabelValue(questionSetQuestionDO[:questionCd])}"
					childStrRetBuff << errorLink unless errorMessageList.empty?
					childStrRetBuff << "</p>"
				end

				childStrRetBuff << "<p class='answer declaration-radio'>" << htmlString << "</p>"
				childStrRetBuff << errorMessage unless errorMessageList.empty?

				childStrRetBuff << "</div>"
				childStrRetBuff << "</li>"
				if (reflexiveQuestionDO && (reflexiveQuestionDO[:guid] != questionSetQuestionDO[:guid]) && displayProperty != '') || $parentQuestionCd != nil
					if @loadChildQuestions
						if $childHTMLHash[parentReference].to_s == ''
							$childHTMLHash[parentReference] = childStrRetBuff
						else
	            			if $childHTMLHash[parentReference].include?("<ul class='declaration-text questionSetBlock'")
			            		if $childHTMLHash[parentReference].start_with?("<div class='sub-questionnaire-bg'")
									insertAt = -12 # count of closing div and ul
								elsif $childHTMLHash[parentReference].start_with?("<div class='questionnaire-bg'")
			            			insertAt = -18 # count of closing div and ul
			            		end
			            		$childHTMLHash[parentReference].to_s.insert(insertAt,childStrRetBuff.to_s)
		            		else
								$childHTMLHash[parentReference] << childStrRetBuff
		            		end
						end
					end
					if (reflexiveQuestionDO && reflexiveQuestionDO[:questionSetCd].to_s != questionSetQuestionDO[:questionSetCd].to_s)
						finalParentReference = parentReference
					end
				else
					finalParentReference = ''
					strRetBuff << childStrRetBuff
				end
				modelTagEnd
            end
            return displayProperty,finalParentReference
		end
		#############################################################################################


		#Main Method to trigger the entire questionnaire rendering mechanism
		def renderQuestionnaire(questionnaireHash, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct, loadChildQuestions, policy=nil, childQsetCds='')
			strRetBuff = ""
			header = ""
            displayProperty = ""
            closeWrapperDiv = false
            closeLeafDiv = false
            questParentReference = ''
            @loadChildQuestions = loadChildQuestions
			if questionnaireHash[:header].to_s != ""
                if questionnaireHash[:displayNumber].to_s != ""
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                        header << "<div class='sub-questionnaire-bg' data-onlyquestionsetcd='#{questionnaireHash[:questionSetCd]}'>"
                        header << "<h3><u>#{questionnaireHash[:displayNumber]}. #{getLabelValue(questionnaireHash[:header])}</u></h3>"
            			closeLeafDiv = true
                    elsif questionnaireHash[:questionSetTypeCd] == "WRAPPER"
                    	header << "<div class='questionnaire-bg'>"
                        header << "<h3><b>#{questionnaireHash[:displayNumber]}. #{getLabelValue(questionnaireHash[:header])}</b></h3>"
                        closeWrapperDiv = true
                    else
                    	header << "<div class='labelHeader'>"
                        header << "<h3><b>#{questionnaireHash[:displayNumber]}. #{getLabelValue(questionnaireHash[:header])}</b></h3>"
                        header << "</div>"
                    end
                else
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                    	header << "<div class='sub-questionnaire-bg' data-onlyquestionsetcd='#{questionnaireHash[:questionSetCd]}'>"
                        header << "<h3><u>#{getLabelValue(questionnaireHash[:header])}</u></h3>"
            			closeLeafDiv = true
                    elsif questionnaireHash[:questionSetTypeCd] == "WRAPPER"
                    	header << "<div class='questionnaire-bg'>"
                        header << "<h3><b>#{getLabelValue(questionnaireHash[:header])}</b></h3>"
                        closeWrapperDiv = true
                    else
                    	header << "<div class='labelHeader'>"
                        header << "<h3><b>#{getLabelValue(questionnaireHash[:header])}</b></h3>"
                        header << "</div>"
                    end
                end
            else
            	if questionnaireHash[:displayNumber].to_s != ""
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                        header << "<div class='sub-questionnaire-bg' data-onlyquestionsetcd='#{questionnaireHash[:questionSetCd]}'>"
            			closeLeafDiv = true
                    elsif questionnaireHash[:questionSetTypeCd] == "WRAPPER"
                    	header << "<div class='questionnaire-bg'>"
                        closeWrapperDiv = true
                    end
                else
                    if questionnaireHash[:questionSetTypeCd] == "LEAF"
                    	header << "<div class='sub-questionnaire-bg' data-onlyquestionsetcd='#{questionnaireHash[:questionSetCd]}'>"
            			closeLeafDiv = true
                    elsif questionnaireHash[:questionSetTypeCd] == "WRAPPER"
                    	header << "<div class='questionnaire-bg'>"
                        closeWrapperDiv = true
                    end
                end
			end
			tempStrRetBuff = ""
			conditionalChildStrRetBuff = ""
			tempStrRetBuff << header
			tempStrRetBuff << "<ul class='declaration-text questionSetBlock' for='#{questionnaireHash[:object]}'>" if questionnaireHash[:questionSetTypeCd] == "LEAF"
			ajaxLoading = false
			
			if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
				if questionnaireHash[:isGridTypeFl] == "YES"
					ajaxLoading = true
					if !reflexiveQuestionDO
						reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"])
					else
						condReflexiveQuestionDO = reflexiveQuestionDO
						reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"])
					end
					displayProperty, questParentReference = renderGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, conditionalChildStrRetBuff, true, questionContainer, responseHash, quotationParty, condReflexiveQuestionDO)
					if condReflexiveQuestionDO
						reflexiveQuestionDO = condReflexiveQuestionDO
					end
				else
					if !reflexiveQuestionDO
						reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"])
					end
                    displayProperty, questParentReference = renderNonGridQuestions(questionnaireHash["listQuestionSetQuestionDOList"], reflexiveQuestionDO, conditionalChildStrRetBuff, false, questionContainer, responseHash, quotationParty, policy, childQsetCds)
				end
			end
            if questParentReference.to_s == '' || ajaxLoading == true
            	strRetBuff = tempStrRetBuff + conditionalChildStrRetBuff
            else
            	if @loadChildQuestions
					if $childHTMLHash[questParentReference].to_s == ''
	            		conditionalChildStrRetBuff << "</ul>" if questionnaireHash[:questionSetTypeCd] == "LEAF" 
						conditionalChildStrRetBuff << "</div>" if closeLeafDiv
						conditionalChildStrRetBuff << "</div>" if closeWrapperDiv
	            		$childHTMLHash[questParentReference] = tempStrRetBuff + conditionalChildStrRetBuff
	            	else
	            		unless $childHTMLHash[questParentReference].include?("<ul class='declaration-text questionSetBlock'")
	            			conditionalChildStrRetBuff << "</ul>" if questionnaireHash[:questionSetTypeCd] == "LEAF" 
							conditionalChildStrRetBuff << "</div>" if closeLeafDiv
							conditionalChildStrRetBuff << "</div>" if closeWrapperDiv
	            			$childHTMLHash[questParentReference] << conditionalChildStrRetBuff
	            			$childHTMLHash[questParentReference].to_s.insert(0,tempStrRetBuff.to_s)
	            		end
	            	end
	            end
            end

			if questionnaireHash.has_key?("listQuestionSetDOList")
				questionnaireHash["listQuestionSetDOList"].each do |questionSetDO|
					if questionSetDO[:ruleSeq].to_s == ""
						reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
						strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct, @loadChildQuestions, policy, childQsetCds)
					else
						pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(questionSetDO[:ruleSeq], quotation, baseProduct, quotationParty, false, false)
					
						#removing party nil check for rendering agent questionnaire after dt evaluation
						if pdt != nil && pdt.outputAction == "YES"
							reflexiveQuestionDO = getReflexiveQuestion(questionnaireHash["listQuestionSetQuestionDOList"]) if questionnaireHash.has_key?("listQuestionSetQuestionDOList")
							strRetBuff << renderQuestionnaire(questionSetDO, reflexiveQuestionDO, questionContainer, responseHash, quotationParty, quotation, baseProduct, @loadChildQuestions, policy, childQsetCds)
						else
							ServiceQuestionResponse.delete_all(
								:conditions => {
									{:name=>'parentkey'} => questionContainer.object,
									{:name=>'questionSetCd'} => questionSetDO[:questionSetCd]
								},
								:op => 'AND'
							)
							if quotationParty
								taskList = TaskException.loadObject(:all, :conditions => {'fieldReference'=> quotationParty.guid + "-questionnaire"})
								TaskException.delete_all(:conditions => {'fieldReference'=> quotationParty.guid + "-questionnaire"})
							end
						end
					end
				end
			end
			if questParentReference.to_s == '' || ajaxLoading == true
				strRetBuff << "</ul>" if questionnaireHash[:questionSetTypeCd] == "LEAF" 
				strRetBuff << "</div>" if closeLeafDiv
				strRetBuff << "</div>" if closeWrapperDiv
			end
			return strRetBuff
		end
		#############################################################################################


		def self.evaluateExpressionBasedReflexiveQuestionSet(childModelCd, childQSetCdModelElement, questionContainer, party, policy)
			policyProduct = policy.getBaseProduct()
			if questionContainer.entityTypeCd == 'AGENT'
	            policy.questionContainer = questionContainer
	        else
	            party.questionContainer = questionContainer if party
	        end
			
			expressionChildQsetCds = ''
			begin
				policyModel = PolicyUtil::PolicyModel.new
				modelResultDO = policyModel.execute(policy, policyProduct, party, childModelCd)
				expressionChildQsetCds = modelResultDO.getFieldValue(childQSetCdModelElement) if modelResultDO
			rescue Exception => e
				Rho::Log.error("Error in policy model evaluation --->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return expressionChildQsetCds
		end

		def self.isQuestionSetApplicable(policyIO, quotation, questionSetDO, partyGuid)
			isApplicable = true
			policy =  policyIO.baseDO
			partyDO = policy.getPartyByGuid(partyGuid)
			baseProduct = MobiSys::QuotationBO.getBaseProduct(quotation)
            $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
			prodFacetDT = MobiSys::ProductUtil.getProductDefinitionTableDO(questionSetDO[:ruleSeq], quotation, baseProduct, partyDO)
            isApplicable = (prodFacetDT.outputAction.to_s == "NO" ? false : true) if prodFacetDT.to_s != ""
           
			return isApplicable
		end

		def self.isQuestionApplicable(questionSet, partyGuid, questionSetQuestionDO,baseIO,questionnaireContainer,responseHash)
            isApplicable = true
            reflexiveQuestionDO = getReflexiveQuestion(questionSet["listQuestionSetQuestionDOList"]) if questionSet["listQuestionSetQuestionDOList"] != nil
            reflexiveValue = "YES"
            party = baseIO.baseDO.getPartyByGuid(partyGuid)

            if(questionSetQuestionDO != nil && reflexiveQuestionDO != nil && questionSetQuestionDO[:conditional] == "STATIC")
                if(reflexiveQuestionDO[:reflexiveValue].to_s != "")
                    reflexiveValue = reflexiveQuestionDO[:reflexiveValue].to_s
                end
                reflexiveResponse = getResponseForApi(reflexiveQuestionDO,questionSet[:isGridTypeFl], questionnaireContainer,responseHash, party)
                if reflexiveQuestionDO[:inputTypeCd].to_s == "NCOMBO" && reflexiveResponse&.responseValue&.to_s != ""
					parentQuestionResponseValueList = reflexiveResponse.responseValue.to_s.split(",")
					unless parentQuestionResponseValueList.include?(reflexiveValue)
						isApplicable = false
					end
                elsif(reflexiveResponse == nil || reflexiveResponse.responseValue.to_s != reflexiveValue)
                    isApplicable = false
                end
            elsif(questionSetQuestionDO == nil || reflexiveQuestionDO == nil || questionSetQuestionDO[:conditional] == "REFLEXIVE")
            	if(questionSetQuestionDO != nil and questionSetQuestionDO[:condReflexiveValue].to_s != "")
                    if(questionSetQuestionDO[:dataModelCd].to_s != "" )
                        childQuesSetEvaluated = evaluateReflexiveChildQuestionSet(baseIO,questionSetQuestionDO,partyGuid)
                        if(questionSet[:questionSetCd].to_s != childQuesSetEvaluated)
                            isApplicable = false
                        end  
                    else
                        #find the service question response for the parent question set reflexive question for the same party
                        parentResponse = nil
                        if questionSetQuestionDO[:dataParent].to_s != "" && questionSetQuestionDO[:condReflexiveValue].to_s  != "SYSTEM_EXPRESSION"
                            parentResponse = responseHash["#{questionSetQuestionDO[:dataParent]}#{"|#{partyGuid}" if partyGuid.to_s != ''}"]
                            isApplicable = false if questionSetQuestionDO[:condReflexiveValue] != nil && (parentResponse == nil || parentResponse.responseValue != questionSetQuestionDO[:condReflexiveValue])
                        end    
                    end
                end
                    
            end

            return isApplicable
        end
 

        def self.evaluateReflexiveChildQuestionSet(policyIO, questionSetQuestionDO, partyGuid)
            polModelDO = PolicyUtil::PolicyModel.new
            policy = policyIO.baseDO
            policyParty = policy.getPartyByGuid(partyGuid)
            policyParty.policyYear = policy.policyYear
            policyProduct = policy.getBaseProduct
            modelResultDO = polModelDO.execute(policy, policyProduct, policyParty, questionSetQuestionDO[:dataModelCd]) if policyProduct

            return modelResultDO.getFieldValue(questionSetQuestionDO[:dataModelElementQsetCd])
        end

        #Method to get a response of a specific QuestionSetQuestion or create a new one from the responseHash
		def self.getResponseForApi(questionSetQuestion, isGridTypeFl, questionContainer, responseHash, quotationParty, rowGuid=nil)
			if isGridTypeFl
				if quotationParty
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{quotationParty.guid}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end
				key << "|#{rowGuid}" if rowGuid

				serviceQuestionResponse = responseHash[key] if responseHash[key] != nil and responseHash.has_key?(key)
			else
				if quotationParty
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{quotationParty.guid}"
				else
					key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}"
				end

				serviceQuestionResponse = responseHash[key] if responseHash[key] != nil and responseHash.has_key?(key)
			end
			return serviceQuestionResponse
		end

		#Get QuestionSetQuestion for a QuestionSet to check for question applicability
		def self.getQuestionSetQuestion(questionSet)
			questionSetQuestionDO = nil

			if questionSet["listQuestionSetQuestionDOList"] != nil
				reflexiveQuestionDO = getReflexiveQuestion(questionSet["listQuestionSetQuestionDOList"]) 

				questionSetQuestionDO = (reflexiveQuestionDO != nil ? reflexiveQuestionDO : questionSet["listQuestionSetQuestionDOList"].first)
			end

			return questionSetQuestionDO
		end

	end
end
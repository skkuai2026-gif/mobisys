#encoding: UTF-8
require 'helpers/browser_helper'
require 'time'
require 'CommonModules/metadata'

module MobiSys
	#UIhelper module contains utility methods used by the functional modules
	#Add any new method which is used by the UI/Controller for UI actions in this module
	module UIHelper
		ENTITYCONTEXT_SET_DO_MAP = {
			:InwardDetails 			=> :CollectionSet,
			:Inward 				=> :CollectionSet,
			:InwardPolicy 			=> :CollectionSet,
			:Party 					=> :PartySet,
			:PartyContact 			=> :PartySet,
			:PartyAddress 			=> :PartySet,
			:PartyIdentity 			=> :PartySet,
			:PartyEmail 			=> :PartySet,
			:PartyEmployment 		=> :PartySet,
			:PartyFinancialAccount 	=> :PartySet,
			:Service 				=> :ServiceSet,
			:ServiceDocument 		=> :ServiceDocumentSet,
			:Quotation 				=> :QuotationSet,
			:QuotationProduct 		=> :QuotationSet,
			:QuotationTopUp 		=> :QuotationSet,
			:QuotationParty 		=> :QuotationSet,
			:QuotationProductExtra 	=> :QuotationSet,
			:QuotationWithdrawal 	=> :QuotationSet,
			:Policy 				=> :PolicySet,
			:PolicyPayment 			=> :PolicySet,
			:PolicyProduct 			=> :PolicySet,
			:PolicyPartyRole 		=> :PolicySet,
			:PolicyTopUp 			=> :PolicySet
		}
		LOGCATEGORY = "UIHelper"

		# Method to render object mapping on the screen and store instance for scope
		def modelTagStart(id, object, parent=nil, count=nil, renderRemovedField=true)
			MobiSys::Validation.initializeValidationHash unless $validationHash
			MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
			MobiSys::ContextMasterData.initializeContextMasterHash  unless $contextMasterCache
			MobiSys::MetaData.initializeMetadataHash unless $metadataMasterHash
			$contextMasterEvalHash = {} if $contextMasterEvalHash== nil || $contextMasterEvalHash.class.to_s != "Hash"
			$parentChildGuidMapping = {} if $parentChildGuidMapping== nil || $parentChildGuidMapping.class.to_s != "Hash"
			toreturn_str = ""
			begin
				objectPrefix = ""
				if $objectMapping.has_key?(object.object.to_s)
					if parent != nil
						objectPrefix = "#{$objectMapping[object.object.to_s]}"
					else # if parent == nil
						objectPrefix = "#{object.class.name}"
					end
				else
					if parent != nil
						if count.to_s != ""
							if parent == "UserActivity"
								$objectCount[parent.to_s] = count
							else
								$objectCount[parent.object.to_s] = count
								$parentChildGuidMapping[object.uniqueKey] = parent.uniqueKey
							end
						else
							if parent == "UserActivity"
								$objectCount[parent.to_s] = $objectCount[parent.to_s].to_i + 1
							else
								$objectCount[parent.object.to_s] = $objectCount[parent.object.to_s].to_i + 1
								$parentChildGuidMapping[object.uniqueKey] = parent.uniqueKey
							end
						end
						$objectCount[object.object.to_s] = 0
						#Condition for checking if the render object is an arrry list. If yes add count to class name.
						$objectMapping[object.object.to_s] = $objectMapping[parent.object.to_s].to_s+"["+object.class.name+"]["+$objectCount[parent.object.to_s].to_s+"]"

						objectPrefix = "#{$objectMapping[object.object.to_s]}"
					else # if parent == nil
						objectPrefix = "#{object.class.name}"

						$objectMapping[object.object.to_s] = object.class.name
						$objectCount[object.object.to_s] = 0
					end
				end

				if id.to_s != ""
					objectID = "#{id}_"
				else
					objectID = "#{$objectMapping[object.object.to_s]}_"
				end

				# the object id for the object in question
				toreturn_str << "<input type=\"hidden\" "
				toreturn_str << "name=\"#{objectPrefix}[object]\" "
				toreturn_str << "id=\"#{objectID}object\" "
				toreturn_str << "value=\"#{object.object}\"/>"

				# render the removed attribute as is
				if renderRemovedField && Rho::RhoConfig.sources[object.class.name.to_s]["schema"]["property"].has_key?("removed")
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\"#{objectPrefix}[removed]\" "
					toreturn_str << "id=\"#{objectID}removed\" "
					toreturn_str << "value=\"#{object.removed}\"/>"
				end

				# the guid for the object in question
				if object.uniqueKey.to_s != ""
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\"#{objectPrefix}[guid]\" "
					toreturn_str << "id=\"#{objectID}guid\" "
					toreturn_str << "value=\"#{object.uniqueKey}\"/>"
				end

				# the guid for the object to evaluate context at runtime.
				if object.uniqueKey.to_s != ""
					toreturn_str << "<input type=\"hidden\" "
					# toreturn_str << "name=\"#{objectPrefix}[guid]\" "
					toreturn_str << "id=\"#{objectID}contextGuid\" "
					if Object.const_get(object.class.name).instance_methods(false) && Object.const_get(object.class.name).instance_methods(false).include?(:isParentExtendingContext) && object.isParentExtendingContext
						toreturn_str << "value=\"#{parent.uniqueKey}\"/>"
					else
						toreturn_str << "value=\"#{object.uniqueKey}\"/>"
					end
				end

				# the systemCreatedDt for the object in question
				toreturn_str << "<input type=\"hidden\" "
				toreturn_str << "name=\"#{objectPrefix}[systemCreatedDt]\" "
				toreturn_str << "id=\"#{objectID}systemCreatedDt\" "
				if object.systemCreatedDt.to_s == ""
					toreturn_str << "value=\"#{Time.now}\"/>"
				else
					toreturn_str << "value=\"#{object.systemCreatedDt.to_s}\"/>"					
				end

				# the parent key for the object to evaluate context at runtime.
				if parent != nil
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\"#{objectPrefix}[parentKey]\" "
					toreturn_str << "id=\"#{objectID}parentKey\" "
					toreturn_str << "value=\"#{parent.object.to_s}\"/>"
				end

				# the name to be used for objects with this id
				toreturn_str << "<input type=\"hidden\" "
				toreturn_str << "name=\"#{object.object}\" "
				toreturn_str << "value=\"#{objectPrefix}\"/>"

				@tagObjStack = [] unless @tagObjStack.is_a?(Array)
				@tagIDStack = [] unless @tagIDStack.is_a?(Array)
				@tagObjStack.push(object)
				@tagIDStack.push(id)

				#@applicableContextsStack becomes empty when the screen is rendered due to pop method called in modelTagEnd.
				#So this array is blank when we add a new section from screen using the ajax call on add button. 
				#hence inherit the context from Parent object if it exists.
				if @applicableContextsStack == nil && parent != nil
					if $contextMasterEvalHash && $contextMasterEvalHash.has_key?(parent.uniqueKey)
						@applicableContextsStack = $contextMasterEvalHash[parent.uniqueKey].collect{|e| e["contextName"].to_sym }
					end
				end

				@currentTagObject = @tagObjStack.last
				@currentTagID = @tagIDStack.last
				if $rhoconfig[:contextBasedMetadata]
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
				else
					if ENTITYCONTEXT_SET_DO_MAP.has_key?(object.class.name.to_sym)
						contextSet = Object.const_get(ENTITYCONTEXT_SET_DO_MAP[object.class.name.to_sym])
						contextSet.setObject(object)
						@applicableContextsStack = [] unless @applicableContextsStack.is_a?(Array)
						@applicableContextsStack.push(contextSet::ValidationContexts)
						
						@currentApplicableContexts = @applicableContextsStack.last
					else
						contextSet = Object.const_get(:GenericSet)
						contextSet.setObject(object)
						@applicableContextsStack = [] unless @applicableContextsStack.is_a?(Array)
						@applicableContextsStack.push(contextSet::ValidationContexts)
						
						@currentApplicableContexts = @applicableContextsStack.last
					end
				end
			rescue Exception => e
				Rho::Log.error("Error in modelTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to end scope for instance object
		def modelTagEnd
			begin
				@tagObjStack.pop
				@tagIDStack.pop
				@applicableContextsStack.pop if @applicableContextsStack
				@currentTagObject = @tagObjStack.last
				@currentTagID = @tagIDStack.last
				if $rhoconfig[:contextBasedMetadata]
					@currentApplicableContexts = @applicableContextsStack.flatten if @applicableContextsStack
				else
					@currentApplicableContexts = @applicableContextsStack.last if @applicableContextsStack
				end
			rescue Exception => e
				Rho::Log.error("Error in modelTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
		end


		# Method to generate an input field - label combination based on Product & Company facets
		def prdFieldDataTag(metaDataObject, fieldIds, facetIds="", metaDataFields="", rowDivision=2, startOnNewLine=true, sizes=nil, rows=nil, cols=nil, labelFacet='')
			toreturn_str = ""
			begin
				fieldList = fieldIds.split(',')
				sizeList = sizes == nil ? [] : sizes.split(',')
				rowList = rows == nil ? [] : rows.split(',')
				colList = cols == nil ? [] : cols.split(',')
				facetIdList = facetIds.to_s != '' ? facetIds.split(',') : []
				metaDataFieldList = metaDataFields.to_s != '' ? metaDataFields.split(',') : []
				renderTypeFlag = true
				if facetIdList.size == 1
					if facetIdList[0].include?("&")
						conditionalFacetIdList = facetIdList[0].split('&')
						conditionalFacetIdList.each do |each_facetid|
							renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(each_facetid, $currentProduct)
							break unless renderTypeFlag
						end
					else
						renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(facetIdList[0], $currentProduct)
					end
				end
				if renderTypeFlag
					fieldList.each_with_index do |field, index|
						if metaDataFieldList[index].to_s != ""
							metaDataCd = metaDataObject + "." + metaDataFieldList[index]
						else
							metaDataCd = metaDataObject + "." + field
						end
						if $companyFieldMetaDataCache.include?(metaDataCd.to_sym)
							visibility = true
							style = ""
							currFieldFacetId = facetIdList[index]
							if !facetIdList.empty? && facetIdList.size != 1 && facetIdList.size > index
								if("#none" == currFieldFacetId)
									renderTypeFlag = true
								elsif currFieldFacetId.include?("&")
									conditionalFacetIdList = currFieldFacetId.split('&')
									conditionalFacetIdList.each do |each_facetid|
										renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(each_facetid, $currentProduct)
										break unless renderTypeFlag
									end
								else
									renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(currFieldFacetId, $currentProduct)
								end
								next unless renderTypeFlag
							end
							if $uiMetaDataCache.has_key?("#{@currentTagObject.class.name}DO.#{field}".to_sym)
								uiMetaDataDOList = $uiMetaDataCache["#{@currentTagObject.class.name}DO.#{field}".to_sym]

								ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
								visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

								ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, @currentApplicableContexts)
								inputType = (ui == nil ? "" : ui.propertyValue.to_s)
							end
							
							style = "style='display:none;' " unless visibility

							if inputType != 'HIDDEN'
								if rowDivision == 2
									if $rhoconfig[:application_view_mode] == 'mobile'
										toreturn_str << "<div class='project-data project-data-mobile' #{style}>"
									else
										toreturn_str << "<div class='project-data' #{style}>"
									end
								elsif rowDivision == 1
									toreturn_str << "<div class='project-data-full' #{style}>"
								end
			                    toreturn_str << "<div class='row-details'>"
			                    productLabel = nil
			                    if labelFacet != ''
			                    	facetName = labelFacet[field.to_sym]
			                    	if facetName
			                    		productLabel = $currentProduct.getFacetValue(facetName).to_s == '' ? field : $currentProduct.getFacetValue(facetName).to_s
			                    	end
			                    end
								toreturn_str << labelTag(field, nil, productLabel)
								toreturn_str << "<p class='col-right'>"
			                end
							toreturn_str << inputTag(field, sizeList[index], rowList[index], colList[index])
							toreturn_str << errorTag(field)
							if inputType != 'HIDDEN'
								toreturn_str << "</p>"
								toreturn_str << "</div>"
								toreturn_str << "</div>"
							end
						end
					end
					if startOnNewLine
						toreturn_str << "<div class='clearfix'></div>"
					end
				end
			rescue Exception => e
				Rho::Log.error("Error in prdFieldDataTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate an input field - label when module is not dependent on Product and company facets
		def layoutFieldTag(fieldIds, rowDivision=2, startOnNewLine=true, sizes=nil, rows=nil, cols=nil)
			toreturn_str = ""
			begin
				fieldList = fieldIds.split(',')
				sizeList = sizes == nil ? [] : sizes.split(',')
				rowList = rows == nil ? [] : rows.split(',')
				colList = cols == nil ? [] : cols.split(',')
				fieldList.each_with_index do |field, index|
					visibility = true
					style = ""

					if $uiMetaDataCache.has_key?("#{@currentTagObject.class.name}DO.#{field}".to_sym)
						uiMetaDataDOList = $uiMetaDataCache["#{@currentTagObject.class.name}DO.#{field}".to_sym]

						ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
						visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, @currentApplicableContexts)
						inputType = (ui == nil ? "" : ui.propertyValue.to_s)
					end
					
					style = "style='display:none;' " unless visibility

					if inputType != 'HIDDEN'
						if rowDivision == 2
							if $rhoconfig[:application_view_mode] == 'mobile'
								toreturn_str << "<div class='project-data project-data-mobile' #{style}>"
							else
								toreturn_str << "<div class='project-data' #{style}>"
							end
						elsif rowDivision == 1
							toreturn_str << "<div class='project-data-full' #{style}>"
						end
								
	                    toreturn_str << "<div class='row-details'>"
						toreturn_str << labelTag(field)
						toreturn_str << "<p class='col-right'>"
					end
					toreturn_str << inputTag(field, sizeList[index], rowList[index], colList[index])
					toreturn_str << errorTag(field) 
					if inputType != 'HIDDEN'
						toreturn_str << "</p>"
						toreturn_str << "</div>"
						toreturn_str << "</div>"
					end
				end
				if startOnNewLine
					toreturn_str << "<div class='clearfix'></div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in layoutFieldTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate field errors
		def errorTag(field, source='')
			toreturn_str = ""
			begin
				errorMessageList = []
				errorStyle = ""
				if @errors!=nil && !@errors.empty?
					@errors.each do |tabId, tabErrors|
						if tabErrors.has_key?(@currentTagObject.guid) && tabErrors[@currentTagObject.guid].has_key?(field) && !tabErrors[@currentTagObject.guid][field].empty?
							errorMessageList += tabErrors[@currentTagObject.guid][field]
							errorStyle = "error-msg"
						end
					end
				end
				unless errorMessageList.empty?
					if @currentTagID
						id = "#{@currentTagID}_#{field}_err"
					else
						id = "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}_err"
					end
					id_js = id
					id_js = id_js.gsub("_err","")
					toreturn_str << "<span class='error-text'>" if source != 'table'
					toreturn_str << "#{errorMessageList.join('<br>')}" if source != 'table'
					toreturn_str << "</span>" if source != 'table'

					if source != 'table' && field != "selected" && errorStyle != ""
						toreturn_str << "<script>" 
						toreturn_str << "$(document).ready(function(){$('[id*= #{id_js}]').closest('.row-details').addClass('error-msg')});" 
						toreturn_str << "</script>"
					end

					if  source == 'table'  && errorStyle != ""
						toreturn_str << "<script>"
						toreturn_str << "$(document).ready(function(){$('[id*= #{id_js}]').closest('div .error-msg-append').addClass('error-msg')});" 
						toreturn_str << "</script>"
					end

					if field == "selected" && errorStyle != ""
						toreturn_str << "<script>"
						toreturn_str << "$(document).ready(function(){$('[id*= #{id_js}]').closest('div').find('.documentDesc').addClass('error-msg')});"
						toreturn_str << "</script>"
					end
	
					toreturn_str << "<a href='##{id}' data-rel='popup' data-position-to='window' data-transition='pop' class='icon-error-message'></a>"

					toreturn_str << "<div data-role='popup' id='#{id}' data-theme='a' class='ui-corner-all popup-wrapper error-popup'>"
					toreturn_str << "<div class='popup-close-cust'>"
					toreturn_str << "<a href='#' data-rel='back' class='icon-close'></a>"
					toreturn_str << "</div>"
					toreturn_str << "<div class='close-before-save'>"
					toreturn_str << "<h3>#{getLabelValue('errorList')}</h3>"
					errorMessageList.each do |errorMessage|
						toreturn_str << "<p>#{errorMessage}</p>"
					end
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
			rescue Exception => e
					Rho::Log.error("Error in errorTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate labels
		def labelTag(field, metaDataObject=nil, labelOverride=nil, showSortIcons=false)
			toreturn_str = ""
			begin
				ui = nil
				val = nil
				label = field
				visibility = true
				help = ""
				minOccurs = 0
				id = ""

				if metaDataObject
					id = "#{metaDataObject}_#{field}"
					metaDataCd = "#{metaDataObject}"
				else
					if @currentTagID
						id = "#{@currentTagID}_#{field}"
					else
						id = "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}"
					end
					metaDataCd = "#{@currentTagObject.class.name}DO"
				end

				if $uiMetaDataCache.has_key?("#{metaDataCd}.#{field}".to_sym)
					uiMetaDataDOList = $uiMetaDataCache["#{metaDataCd}.#{field}".to_sym]

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, @currentApplicableContexts)
					label = (ui == nil ? label : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
					visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("HELP", uiMetaDataDOList, @currentApplicableContexts)
					help = (ui == nil ? "" : ui.propertyValue.to_s)
				end
				label = labelOverride if labelOverride
				if $validationHash.has_key?("#{metaDataCd}".to_sym)
					validationMetaDataDOList = $validationHash["#{metaDataCd}".to_sym]

					val = MobiSys::Validation.getValidationDO("MINOCCURS", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
					minOccurs = (val == nil ? 0 : val.validationParam.to_i > 0 ? val.validationParam.to_i : 0)
				end

				strClass = "col-left "
				strVisibility = ""
				unless visibility
					strVisibility = "style=\"display: none;\" "
				else
					strVisibility = ""
				end
				
				strClass = strClass + "mandatorylabel" if minOccurs > 0
				# only if the label tag is required add it else plain html.
				toreturn_str << "<p class=\"#{strClass}\" #{strVisibility} id=\"#{id}_lbl\" for=\"#{id}\">"
				toreturn_str << getLabelValue(label)
				toreturn_str << "<span id=\"#{id}_lblsm\" class=\"mandatory\">*</span>" if minOccurs > 0 && visibility
				
				tooltipText = getToolTipValue(label.to_sym)
				if tooltipText.strip.to_s != "" && tooltipText.strip.to_s != "null"
					toreturn_str << "<span class=\"tooltip\">"
					toreturn_str << "<i class='icon-questioninfo'></i>"
					toreturn_str << "<span class='tooltiptext'>#{tooltipText}</span>"
					toreturn_str << "</span>"
				end

				if showSortIcons
					toreturn_str << "<span class='sortingIcon'></span>"
				end
				toreturn_str << "</p>"
			rescue Exception => e
				Rho::Log.error("Error in labelTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate any type of input fields
		def inputTag(field, size=nil, rows=nil, cols=nil, isReadOnly=nil, metaDataObject=nil, inputTypeOverride=nil, lookUpCdOverride=nil, additionalNameAttr=nil)
			toreturn_str = ""
			begin
				ui = nil
				val = nil
				label = ""
				lookup = ""
				visibility = true
				enabled = true
				inputType = ""
				caseType = ""
				mask = ""
				inputFormat = ""
				help = ""
				placeHolderReqd = nil
				minOccurs = ""
				id = ""
				nameAttr = ""
				value = ""
				entity = ""
				width = ""
				maxlength = ""
				datatype = ""
				doMask = false
				ocr = ""
				contextEnabled = false
				minlength = ""

				if Application.getValue('DEFAULTLOCALE')
					@locale = Application.getValue('DEFAULTLOCALE').value
				else
					@locale = 'en'
				end

				if metaDataObject
					nameAttr = additionalNameAttr == nil ? field : "#{field}_#{additionalNameAttr}"
					id = additionalNameAttr == nil ? "#{metaDataObject}_#{field}" : "#{metaDataObject}_#{field}_#{additionalNameAttr}"
					metaDataCd = metaDataObject
				else
					nameAttr = additionalNameAttr == nil ? "#{$objectMapping[@currentTagObject.object.to_s]}[#{field}]" : "#{$objectMapping[@currentTagObject.object.to_s]}[#{field}]_#{additionalNameAttr}"
					if @currentTagID
						id = additionalNameAttr == nil ? "#{@currentTagID}_#{field}" : "#{@currentTagID}_#{field}_#{additionalNameAttr}"
					else
						id = additionalNameAttr == nil ? "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}" : "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}_#{additionalNameAttr}"
					end
					metaDataCd = "#{@currentTagObject.class.name}DO"
				end
				metaDataFieldName = "#{metaDataCd}.#{field}"
				if $uiMetaDataCache.has_key?("#{metaDataCd}.#{field}".to_sym)
					uiMetaDataDOList = $uiMetaDataCache["#{metaDataCd}.#{field}".to_sym]

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, @currentApplicableContexts)
					label = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, @currentApplicableContexts)
					lookup = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
					visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("ENABLED", uiMetaDataDOList, @currentApplicableContexts)
					enabled = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
					enabled = isReadOnly if isReadOnly

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, @currentApplicableContexts)
					inputType = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("CASEVALUE", uiMetaDataDOList, @currentApplicableContexts)
					caseType = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("MASK", uiMetaDataDOList, @currentApplicableContexts)
					mask = (ui == nil ? "" : ui.propertyValue.to_s)
					doMask = true if ui

					# To be checked -- may not be used
					ui = MobiSys::UIMetaData.getUiMetadataPropDO("FORMAT", uiMetaDataDOList, @currentApplicableContexts)
					inputFormat = (ui == nil ? "" : ui.propertyValue.to_s)

					# To be checked -- may not be used
					ui = MobiSys::UIMetaData.getUiMetadataPropDO("HELP", uiMetaDataDOList, @currentApplicableContexts)
					help = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("PLACEHOLDERREQD", uiMetaDataDOList, @currentApplicableContexts)
					placeHolderReqd = (ui == nil ? false : (ui.propertyValue.to_s == "YES" ? true : false))

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("MAXLENGTH", uiMetaDataDOList, @currentApplicableContexts)
					maxlength = (ui == nil ? "" : ui.propertyValue.to_s)

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("OCR", uiMetaDataDOList, @currentApplicableContexts)
					ocr = (ui == nil ? "" : (ui.propertyValue.to_s == "YES" ? ui.metaDataCd.to_s : ""))

					ui = MobiSys::UIMetaData.getUiMetadataPropDO("MINLENGTH", uiMetaDataDOList, @currentApplicableContexts)
					minlength = (ui == nil ? "" : ui.propertyValue.to_s)
				end

				if $rhoconfig[:contextBasedMetadata]
					if $contextMasterCache.has_key?("#{metaDataCd}".to_sym)
						$contextMasterCache["#{metaDataCd}".to_sym].each do |contextMaster|
							contextEnabled = true if contextMaster.fieldName.to_s == field
						end
					end

					if $metadataMasterHash && $metadataMasterHash.has_key?("#{metaDataCd}.#{field}".to_sym)
						metadataMasterRecord = $metadataMasterHash["#{metaDataCd}.#{field}".to_sym]
						if metadataMasterRecord
							runTimeDrivingFieldNames = metadataMasterRecord.runtimeDrivingMTDT.to_s
						end
					end
				else
					runTimeDrivingFieldNames = ""
				end
				inputType = inputTypeOverride if inputTypeOverride
				lookup = lookUpCdOverride if lookUpCdOverride
				entityTypeDO = nil
				dataElementDO = DataElement.find(
					:first,
					:conditions => {
						{:name => 'attributeCd'} => field
					},
					:select => ['attributeCd','attributeTypeCd','entityFieldTypeCd','globalFl']
				)
				if dataElementDO
					entityTypeDO = EntityType.loadObject(
						:first,
						:conditions => {
							{:name => 'entityFieldTypeCd'} => dataElementDO.entityFieldTypeCd
						}
					)
				end
				unless entityTypeDO
					Rho::Log.error("No DataElementDO created for #{field}", LOGCATEGORY)
				else
					entity = entityTypeDO.entityFieldTypeCd.to_s
					datatype = entityTypeDO.dataTypeCd.to_s
					entityTypeDO.EntityPropertyList.each do |entityProperty|
						if entityProperty.propertyCd.to_s == "WIDTH"
							if size.to_s == ""
								width = entityProperty.propertyValue.to_s
							else
								width = size
							end
						elsif entityProperty.propertyCd.to_s == "MAXLENGTH" && maxlength == ""
							maxlength = entityProperty.propertyValue.to_s
						elsif entityProperty.propertyCd.to_s == "MASK" && !doMask
							doMask = true
							mask = entityProperty.propertyValue.to_s
						elsif entityProperty.propertyCd.to_s == "MINLENGTH" && minlength == ""
							minlength = entityProperty.propertyValue.to_s
						end
					end
				end

				if $validationHash.has_key?(metaDataCd.to_sym)
					validationMetaDataDOList = $validationHash[metaDataCd.to_sym]
					val = MobiSys::Validation.getValidationDO("MINOCCURS", validationMetaDataDOList, @currentApplicableContexts, "#{metaDataCd}.#{field}")
					minOccurs = (val == nil ? "" : val.validationParam.to_s)
				end

				if metaDataObject
					value = ""
				else
					value = @currentTagObject.send(field.to_sym)
				end
				value = value.to_f if value.class.to_s == "BigDecimal"
				value = value.to_s
				value.gsub!("'","&apos;")

				if doMask
					$attachMaskFieldsHash = {} unless $attachMaskFieldsHash
					if $offlineApplicationMask == nil
						$offlineApplicationMask = $rhoconfig[:number_format_pattern].to_s
        			end
					mask = $offlineApplicationMask if mask.to_s == "" && $offlineApplicationMask
					$attachMaskFieldsHash[mask] = Array.new unless $attachMaskFieldsHash[mask].is_a?(Array)
					$attachMaskFieldsHash[mask].push("#" + id.to_s)
					value = maskDecimal(value,mask) if value.to_s != ""
				end


				if help.to_s != ""
					# toreturn_str << "<a href=\"#\" class=\"tooltip\">"
					helpId = id.gsub(field,'helpLink')
					toreturn_str << "<a	class=\"tooltip helpLink\" id=\"#{helpId}\" href=\"#\" onclick=\"javascript:getCollateral('#{helpId}','#{help}');\">"
					# toreturn_str << "<img src=\"/systemcommon/images/help.png\" style=\"height:17px; width: 17px;\" id=\"#{id}_img\"/>"
					toreturn_str << "<i class='icon-collateral'></i>"
					# toreturn_str << "<span>#{labelHelp}</span>"
					toreturn_str << "</a>"
				end
				
				
				if inputType == "NUMERICSTRING" || inputType == "TEXT" || inputType == "" || inputType == "EMAIL"
					toreturn_str << printTextBox(nameAttr, id, value, label, visibility, enabled, inputType, caseType, mask, placeHolderReqd, minOccurs, entity, width, maxlength, datatype, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "PASSWORD"
					toreturn_str << printPasswordBox(nameAttr, id, value, label, lookup, visibility, enabled, minOccurs, entity, width, maxlength,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "COMBO" || inputType == "FCOMBO" || inputType == "LOOKUPTEXT"
					toreturn_str << printSelectBox(nameAttr, id, value, label, lookup, visibility, enabled, inputType, minOccurs, entity, width, maxlength, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "NCOMBO"
					toreturn_str << printSelectBox(nameAttr, id, value, label, lookup, visibility, enabled, inputType, minOccurs, entity, width, maxlength, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "RADIO"
					toreturn_str << printRadioButton(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName)
				elsif inputType == "CHECKBOX"
					toreturn_str << printCheckbox(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName)
				elsif inputType == "DATE"
					toreturn_str << printDateControl(nameAttr, id, value, label, visibility, enabled, placeHolderReqd, minOccurs, entity, width, maxlength, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "DATETIME" || inputType == "TIMESTAMP"
					toreturn_str << printDateTimeControl(nameAttr, id, value, label, visibility, inputType, enabled, placeHolderReqd, minOccurs, entity, width, maxlength, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName,minlength)
				elsif inputType == "TEXTAREA"
					toreturn_str << printTextArea(nameAttr, id, value,label, rows, cols, visibility, enabled, placeHolderReqd, minOccurs, entity, ocr,contextEnabled,runTimeDrivingFieldNames,metaDataFieldName)
				elsif inputType == "HIDDEN"
					toreturn_str << printHiddenField(nameAttr, id, value,runTimeDrivingFieldNames,metaDataFieldName)
				elsif inputType == "LABELCOMBO"
					toreturn_str << printLabelComboBox(nameAttr, id, value, lookup)
				elsif inputType == "LABEL"
					toreturn_str << printLabel(nameAttr, id, value)
				# To be checked -- may not be used	
				# elsif inputType == "LOOKUPTEXT"
				# 	toreturn_str << printLookupTextField(nameAttr, id, value, label, lookup, visibility, enabled, minOccurs, entity, width, maxlength,contextEnabled)
				elsif inputType == "IMAGE"
					toreturn_str << printImage(nameAttr, id, value)
				elsif inputType == "LINK"
					toreturn_str << printLink(nameAttr, id, value)
				end

			rescue Exception => e
				Rho::Log.error("Error in inputTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate text field
		def printTextBox(nameAttr, id, value, label, visibility, enabled, inputType, caseType, mask, placeHolderReqd, minOccurs, entity, width, maxlength, datatype, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="",minlength)
			toreturn_str = ""
			begin
				textalign = ""
				readOnly = ""
				className = "input-controll "
				type = "text"
				step = ""
				isNumeric = false
				isNumericString = false
				isNumericString = true if inputType == 'NUMERICSTRING'
				
				if datatype.to_s != "" && (datatype == 'DOUBLE' || datatype == 'SHORT' || datatype == 'LONG' || datatype == 'INTEGER') || isNumericString
					textalign = "style='text-align:left;' "
					className << "inputnum "
					type = "tel"
					isNumeric = true
					step = "step='any' "
				end
				type = 'email' if inputType == "EMAIL"

				unless enabled
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
					className = className + " readonly"
				end
				
				toreturn_str << "<input type='#{type}' #{step} class='#{className}' size='#{width}' "
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' " if minOccurs.to_s != ''
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << readOnly
				# toreturn_str << "data-enhanced='true' " if isNumeric || isNumericString
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "minlength='#{minlength}' "
				toreturn_str << "value= '#{value}' "
				toreturn_str << "datatype='#{datatype}' " if datatype.to_s != ''
				toreturn_str << "casevalue='#{caseType}' " if caseType.to_s != ''
				toreturn_str << "placeholder='"
				if enabled
					if placeHolderReqd
						toreturn_str << getLabelValue(label)
					else
						toreturn_str << getLabelValue("plcEnterValue")
					end
				end
				toreturn_str << "' "
				toreturn_str << "data-mask='#{mask}' " if mask.to_s != ''
				toreturn_str << "style='display: none;' " unless visibility
				toreturn_str << textalign
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				# Converting field values to upper/lower case for certain fields
				toreturn_str << "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				toreturn_str << "oninput='javascript:return validateKeyPress(event,this,\"#{@locale}\");' "
				toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
				toreturn_str << "onDrag='return false' onDrop='return false'"
				toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
				toreturn_str << "/>"
			rescue Exception => e
				Rho::Log.error("Error in printTextBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate password text field
		def printPasswordBox(nameAttr, id, value, label, visibility, enabled, minOccurs, entity, width, maxlength,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="",minlength)
			begin
				toreturn_str = ""
				readOnly = ""
				unless enabled
					readOnly = "readonly "+" onFocus='javascript:setNextFieldFocus(this);' "
				end
				toreturn_str << "<input type='password' size='#{width}' "
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' " if minOccurs.to_s != ''
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << readOnly
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "minlength='#{minlength}' "
				toreturn_str << "value= '#{value}' "
				toreturn_str << "datatype='#{datatype}' " if datatype.to_s != ''
				toreturn_str << "casevalue='#{caseType}' " if caseType.to_s != ''
				toreturn_str << "placeholder='"
				if placeHolderReqd
					toreturn_str << getLabelValue(label)
				else
					toreturn_str << getLabelValue("plcEnterValue")
				end
				toreturn_str << "' "
				
				unless visibility
					toreturn_str << "  style='display: none;' "
				end
				toreturn_str << "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				toreturn_str << "onkeypress='javascript:return validateKeyPress(event,this,\"#{@locale}\");' "
				toreturn_str << "/>"
				return toreturn_str
			rescue Exception => e
				Rho::Log.error("Error in printPasswordBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate select box
		def printSelectBox(nameAttr, id, value, label, lookup, visibility, enabled, inputType, minOccurs, entity, width, maxlength, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="",minlength)
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
				elsif value.to_s != ''
					tempLookup = Lookupvalue.new
			        tempLookup.cd = value
			        tempLookup.desc = getLabelValue(value.to_s)
			        lookups.push tempLookup
				end
			
				unless enabled
					isReadOnly = true
					readOnly = "disabled "#+" onFocus='javascript:setNextFieldFocus(this);' "
					className = "inputreadonly "
				end
				unless visibility
					toreturn_str << "<span "
					toreturn_str << "style='display: none;' "
					toreturn_str << ">"
				end
				toreturn_str << "<select #{onChange}  "
				if inputType == 'FCOMBO'
					toreturn_str << "data-native-menu='false' " 
					className << "filterable-select "
				end
				toreturn_str << "class='#{className}' "
				toreturn_str << "data-lookupkey='#{lookup}' "
				if inputType == 'NCOMBO'
					toreturn_str << "name='#{nameAttr}[]' "
				else
					toreturn_str << "name='#{nameAttr}' "
				end
				toreturn_str << "id='#{id}' "
				toreturn_str << "minoccurs='#{minOccurs}' " if minOccurs.to_s != ''
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << "multiple = 'multiple' data-native-menu='false' " if inputType == 'NCOMBO'
				toreturn_str << readOnly
				toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled

				unless visibility
					toreturn_str << "style='display: none;' "
				end
				toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
				toreturn_str << ">"
				# This is required for header label, option without any value
				if inputType == 'FCOMBO'
					toreturn_str << "<option>#{Localization::LabelCache.instance.getLabel(label.to_sym)}</option>"
				end
				isSelected = false
				if value.to_s == ''
					toreturn_str << "<option value='' SELECTED>"+ getLabelValue("select") +" </option>"
					isSelected = true
				elsif inputType == 'NCOMBO'
					toreturn_str << "<option value='' SELECTED>"+ getLabelValue("select") +" </option>"
 				else
					toreturn_str << "<option value='' #{selectedstring}>"+ getLabelValue("select") +" </option>"
				end
		        
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
		              toreturn_str << "<option value='#{lookup.cd}' #{selectedstring}>" + getLabelValue(lookup.desc) + "</option>"
		            else
		              toreturn_str << "<option value='#{lookup.cd}' #{selectedstring}>"+ lookup.cd + "</option>"
		            end
		          end
		        end
				toreturn_str << "</select>"
				unless enabled
					toreturn_str << "<input type='hidden' "
			        toreturn_str << "name='#{nameAttr}' "
			        toreturn_str << "value='#{value}'/>"
			    end
			    unless visibility
			    	toreturn_str << "</span>"
			    end
			rescue Exception => e
				Rho::Log.error("Error in printSelectBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate radio buttons
		def printRadioButton(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="")
			toreturn_str = ""
			begin
				readOnly = ""
				className = "input"
				paramCount = 0
				unless enabled
					readOnly = "readonly disabled "+"onFocus='javascript:setNextFieldFocus(this,event);' "
					className = "inputreadonly"
				end
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = " "
				end

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
						toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
						toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
						toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
						toreturn_str << visibility
						if enabled
							toreturn_str << "onFocus='javascript:return fieldFocus(this);' "
							toreturn_str << "onClick='javascript:catchevent(this);' "
							toreturn_str << "onBlur='javascript:return fieldBlur(this);' "
						else
							toreturn_str << "onClick='return false;' "
						end
						toreturn_str << readOnly
						toreturn_str << "value='#{lookup.cd}' "
						toreturn_str << checked
						toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
						toreturn_str << "/>"
						toreturn_str << getLabelValue(lookup.desc)
						toreturn_str << "</label>"
						paramCount += 1
					end
				end
				# toreturn_str << "<script>"
				# toreturn_str << "var sel_#{id}=new HtmlRadioButton('#{id}',#{paramCount});"
				# toreturn_str << "</script>"
			rescue Exception => e
				Rho::Log.error("Error in printRadioButton--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate checkboxes
		def printCheckbox(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="")
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
						toreturn_str << "<input type='checkbox' "
						toreturn_str << "class='#{className}' "
						toreturn_str << "name='#{nameAttr}[]' "
						toreturn_str << "id='#{id}-#{paramCount}' "
						toreturn_str << "entity='#{entity}' "
						toreturn_str << "minoccurs='#{minOccurs}' "
						toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
						toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
						toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
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
						toreturn_str << "/>"
						toreturn_str << "<label class='label' for='#{id}-#{paramCount}'>"
						toreturn_str << getLabelValue(lookup.desc) if lookup.key.to_s != "BOOLEAN" && lookup.key.to_s != "YESNO"
						toreturn_str << "</label>"
						# if boolean then print only one check box
						break if lookup.key.to_s == "BOOLEAN" || lookup.key.to_s == "YESNO"

						paramCount += 1
					end

					# for checkbox we add a hidden field that gets submitted since if checkbox is not checked null value is submitted.
					if lookup == "BOOLEAN" || lookup == "YESNO"
						hiddenFldName = nameAttr+"_hid"
						# if checkbox value is NO then the name of the hidden field is same as that of the actual field.
						hiddenFldName = nameAttr if value.to_s == "NO" || value.to_s == ""
						toreturn_str << "<input type='hidden' name='#{hiddenFldName}' value='NO' id='#{id}-#{paramCount}_hid'>"
					end
				end
			rescue Exception => e
				Rho::Log.error("Error in printCheckbox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate date control input
		def printDateControl(nameAttr, id, value, label, visibility, enabled, placeHolderReqd, minOccurs, entity, width, maxlength, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="",minlength)
			toreturn_str = ""
			begin
				readOnly = "readonly "
				className = "datepicker"
				onChange = "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				onChange << "onkeypress='javascript:return validateKeyPress(event,this,\"#{@locale}\");' "
				
				unless enabled
					readOnly = readOnly + " onFocus='javascript:setNextFieldFocus(this);' "
					className = className + " readonly inputreadonly"
					onChange = ""
				end
				
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = ""
				end
				
				toreturn_str << "<span class='dateicon'>"
				toreturn_str << "<input type='text' "
				toreturn_str << "class='#{className}' "
				toreturn_str << "size='#{width}' "
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' "
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << visibility
				toreturn_str << readOnly
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "minlength='#{minlength}' "
				toreturn_str << "value='#{value}' "
				toreturn_str << "placeholder='"
				if placeHolderReqd
					toreturn_str << getLabelValue(label)
				else
					toreturn_str << getLabelValue("dateFormat")
				end
				toreturn_str << "' "
				# toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				toreturn_str << onChange
				toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
				toreturn_str << "/>"
				toreturn_str << "</span>"
			rescue Exception => e
				Rho::Log.error("Error in printDateControl--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate date control input
		def printDateTimeControl(nameAttr, id, value, label, visibility, inputType, enabled, placeHolderReqd, minOccurs, entity, width, maxlength, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="",minlength)
			toreturn_str = ""
			begin
				readOnly = "readonly "
				onChange = "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				onChange << "onkeypress='javascript:return validateKeyPress(event,this,\"#{@locale}\");' "
				type = "time"     if inputType == "TIMESTAMP"
				type = "datetime" if inputType == "DATETIME"
				
				unless enabled
					readOnly = readOnly + " disabled onFocus='javascript:setNextFieldFocus(this);' "
					className = " readonly inputreadonly"
					onChange = ""
				end
				
				unless visibility
					visibility = "style='display: none;' "
				else
					visibility = ""
				end
				
				toreturn_str << "<span class='icon-timePicker'>"
				toreturn_str << "<input type='#{type}' "
				toreturn_str << "class='#{className}' "
				toreturn_str << "size='#{width}' "
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' "
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << visibility
				toreturn_str << readOnly
				toreturn_str << "maxlength='#{maxlength}' "
				toreturn_str << "minlength='#{minlength}' "
				toreturn_str << "value='#{value}' "
				toreturn_str << "placeholder='"
				if placeHolderReqd
					toreturn_str << getLabelValue(label)
				else
					toreturn_str << getLabelValue("timeFormat")
				end
				toreturn_str << "' "
				toreturn_str << onChange
				toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
				toreturn_str << "/>"
				toreturn_str << "</span>"
			rescue Exception => e
				Rho::Log.error("Error in printDateTimeControl--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate textarea
		def printTextArea(nameAttr, id, value,label, rows, cols, visibility, enabled, placeHolderReqd, minOccurs, entity, ocr,contextEnabled=false,runTimeDrivingFieldNames=nil,metaDataFieldName="")
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
				
				toreturn_str << "<textarea class='#{className} inputta' " 
				toreturn_str << "name='#{nameAttr}' "
				toreturn_str << "id='#{id}' "
				toreturn_str << "rows='#{rows}' "
				toreturn_str << "cols='#{cols}' "
				toreturn_str << "entity='#{entity}' "
				toreturn_str << "minoccurs='#{minOccurs}' "
				toreturn_str << "contextEnabled='#{contextEnabled}' " if contextEnabled
				toreturn_str << "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}' " if runTimeDrivingFieldNames.to_s != ""
				toreturn_str << "metaDataFieldName='#{metaDataFieldName}' " if metaDataFieldName.to_s != ""
				toreturn_str << "placeholder='"
				if placeHolderReqd
					toreturn_str << getLabelValue(label)
				else
					toreturn_str << getLabelValue("plcEnterValue")
				end
				toreturn_str << "' "
				toreturn_str << visibility
				toreturn_str << readOnly
				toreturn_str << "onFocus='javascript:return fieldFocus(this);' " if enabled
				toreturn_str << "onChange='javascript:return validateField(this,\"#{@locale}\");' "
				toreturn_str << "onDrag='return false' onDrop='return false'"
				toreturn_str << "onkeypress='javascript:return validateKeyPress(event,this,\"#{@locale}\");' >"
				toreturn_str << value
				toreturn_str << "data-metadataCd='#{ocr}' " if ocr.to_s != ""
				toreturn_str << "</textarea>"
			rescue Exception => e
				Rho::Log.error("Error in printTextArea--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate hidden field
		def printHiddenField(nameAttr, id, value,runTimeDrivingFieldNames=nil,metaDataFieldName="")
			toreturn_str = ""
			begin
				runTimeDrivingFieldNamesStr = runTimeDrivingFieldNames.to_s != "" ? "runTimeDrivingFieldNames='#{runTimeDrivingFieldNames}'" : ""
				metaDataFieldNameStr = metaDataFieldName.to_s != "" ? "metaDataFieldName='#{metaDataFieldName}'" : ""
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}' #{runTimeDrivingFieldNamesStr} #{metaDataFieldNameStr}/>"
			rescue Exception => e
				Rho::Log.error("Error in printHiddenField--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# To be checked -- may not be used
		def printLookupTextField(nameAttr, id, value, label, lookup, visibility, enabled, minOccurs, entity, width, maxlength)
			toreturn_str = ""
			begin
			rescue Exception => e
				Rho::Log.error("Error in printLookupTextField--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate an image tag
		def printImage(nameAttr, id, value)
			toreturn_str = ""
			begin
				# Print hidden field to hold the value
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}'/>"
				toreturn_str << "<img id='img' src='#{value}' width='950px' onclick='imageClick(event);'/>"
			rescue Exception => e
				Rho::Log.error("Error in printImage--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate anchor tag
		def printLink(nameAttr, id, value)
			toreturn_str = ""
			begin
				# Print hidden field to hold the value
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}'/>"
				toreturn_str << "<a	class=\"label\" href=\"javascript:void(0)\" onclick=\"window.open('#{value}');\">"
				toreturn_str << "View"
				toreturn_str << "</a>"
			rescue Exception => e
				Rho::Log.error("Error in printLink--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end

		#Method to generate label combo box
		def printLabelComboBox(nameAttr, id, value, lookup)
			toreturn_str = ""
			comboText = ""
			begin
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}'/>"
        		selectLookup = []
				lookups = []
				if lookup.to_s != ""
					offline_lookup_m = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookup})
					if offline_lookup_m
						partition = offline_lookup_m.offlineDBPartition.to_s != '' ? offline_lookup_m.offlineDBPartition.to_s : 'master'
						db = Rho::Database.new(Rho::Application.databaseFilePath(partition),'app');
						if offline_lookup_m.lookupDataSortOrderName.to_s != ""
							sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName}, #{offline_lookup_m.lookupDataSortOrderName} FROM #{offline_lookup_m.lookupEntityName} "
						else
							sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName} FROM #{offline_lookup_m.lookupEntityName} "
						end
						filterCriteria = offline_lookup_m.lookupFilterCriteria.to_s
						
						sql << "WHERE #{filterCriteria} " if filterCriteria.to_s != ""
						sql << "ORDER BY #{offline_lookup_m.lookupDataSortOrderName}" if offline_lookup_m.lookupDataSortOrderName.to_s != ""
						results = db.execute_sql(sql)
						db.close()
						results.each do |result|
							if result.values[0].to_s == value
								tempLookup = Lookupvalue.new
						        tempLookup.cd = result.values[0].to_s
						        tempLookup.desc = getLabelValue(result.values[1].to_s)
						        tempLookup.sortOrder = result.values[2].to_s if offline_lookup_m.lookupDataSortOrderName.to_s != "" && result.values[2]
						        selectLookup.push tempLookup
						    end
						end
					else
						selectLookup = Lookupvalue.getValue(lookupKey)
					end
				end
				if selectLookup.to_s != ""
					selectLookup.each do |lookup|
						if lookup.desc.to_s != ''
		              		comboText = getLabelValue(lookup.desc)
		            	else
		              		comboText = lookup.cd
		            	end
		            end
		            toreturn_str << comboText
		        else
		            toreturn_str << value
		        end

			rescue Exception => e
				Rho::Log.error("Error in printLabelComboBox--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# # Method to generate label field to be used mostly in fielddatagrid
		def printLabel(nameAttr, id, value)
			toreturn_str = ""
			begin
				toreturn_str << "<input type='hidden' name='#{nameAttr}' id='#{id}' value='#{value}'/>"
				toreturn_str << getLabelValue(value)
			rescue Exception => e
				Rho::Log.error("Error in printLabel--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate a header
		def headerTag(heading, mode="", reference="", backLink="", moreOptions="", moreOptionsURLS="",modelLogFile="")
			toreturn_str = ""
			begin
				offlineApplicationEnvironmentLocal = OfflineApplication.find(
					:first,
					:conditions => {
						{ :name => 'PROPERTY' } => 'ENVIRONMENT'
				})

				if offlineApplicationEnvironmentLocal != nil
					if  offlineApplicationEnvironmentLocal.value == nil
						offlineApplicationEnvironmentLocal.value = "PRODUCTION"
					end
				else
					offlineApplicationEnvironmentLocal = OfflineApplication.new
					offlineApplicationEnvironmentLocal.property = 'ENVIRONMENT'
					offlineApplicationEnvironmentLocal.value = "PRODUCTION"
				end
				mode = "edit" if reference.to_s!=""
				moreOptionsList = moreOptions.split(",")
				moreOptionsURLSList = moreOptionsURLS.split(",")
				if $rhoconfig[:application_view_mode] == 'mobile' && (mode == "home" || mode == "search")
					toreturn_str << "<span class='icon-action menu-icon' rel='external'></span>"
				end
				toreturn_str << "<div data-role='header' data-position='fixed' id='page-header' class='ui-fixed-hidden'>"
				if mode == "home" || mode == "search"
					if $rhoconfig[:application_view_mode] != 'mobile'
						toreturn_str << "<img src='/public/jazz/images/logo.jpg' alt='logo' class='logo-img'>"
					end
				else
					if backLink.to_s != ""
						if @params.has_key?('trigger_source') && @params['trigger_source'] == "search"
							backLink = "javascript:backButton();"
						end
						toreturn_str << "<a class='btn-back' href='#{backLink}' data-transition='slide' data-direction='reverse' rel='external'><i class='icon-arrow-back'></i>#{getLabelValue('BACK')}</a>"						
					end
				end

				toreturn_str << "<h2>"
				if mode == "edit"
					toreturn_str << "#{getLabelValue(heading)}"
					toreturn_str << " (#{reference}) " if reference.to_s != ""
				elsif mode == "add"
					toreturn_str << "#{getLabelValue('add')} #{getLabelValue(heading)}"
				else
					toreturn_str << "#{getLabelValue(heading)}"
				end
				toreturn_str << "</h2>"

				toreturn_str << "<div class='header-action-bg'>"
				if mode == "home" || mode == "search"
					# Settings Dropdown
					toreturn_str << "<div class='header-action'>"
					toreturn_str << "<a href='#' data-role='button' class='setting'>"
					toreturn_str << "<i class='icon-settting'></i>"
					toreturn_str << "</a>"
					toreturn_str << "<div class='setting-details'>"
					toreturn_str << "<ul>"
					toreturn_str << "<li><a rel='external' href='/app/SyncCategory/syncPreferences'>#{getLabelValue('SYNC')}</a></li>"
					toreturn_str << "<li><a rel='external' href='/app/SyncCategory/partialSyncPreferences'>#{getLabelValue('PARTIAL_SYNC')}</a></li>" if offlineApplicationEnvironmentLocal.value != "PRODUCTION"
					toreturn_str << "<li><a rel='external' href='/app/LabelValue/languageSettings'>#{getLabelValue('LANGUAGESETTINGS')}</a></li>"
					toreturn_str << "<li><a rel='external' href='/app/Menu/colorSettings'>#{getLabelValue('themeSetting')}</a></li>"
					toreturn_str << "<li><a rel='external' href='/app/Menu/onlineServer'>#{getLabelValue('onlineServer')}</a></li>"
					toreturn_str << "<li><a rel='external' href='/app/Menu/offlineServer'>#{getLabelValue('offlineServer')}</a></li>"
					currentAgentReg = AgentReg.getCurrentAgentReg
					if !$rhoconfig[:singleDeviceLogin] && (currentAgentReg.enableFingerprintAuth.to_s == "YES" || (currentAgentReg.enableFingerprintAuth.to_s != "YES" && AgentReg.find(:all, :conditions =>{{:name =>'enableFingerprintAuth'} =>'YES'}).size == 0))
						toreturn_str << "<li><a rel='external' href='/app/Menu/securitySetting'>#{getLabelValue('securitySetting')}</a></li>"
					end
					if offlineApplicationEnvironmentLocal.value != "PRODUCTION"
						toreturn_str << "<li><a rel='external' href='/app/Menu/setPolicyModelLog'>#{getLabelValue('setPolicyModelLog')}</a></li>" 
						toreturn_str << "<li><a rel='external' href='/app/Menu/uploadLogs'>#{getLabelValue('Uploadlog')}</a></li>"
					end
					toreturn_str << "<li><a rel='external' href='/app/Menu/about'>#{getLabelValue('About')}</a></li>"
					toreturn_str << "</ul>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"

					# Profile Dropdown
					toreturn_str << "<div class='header-action'>"
					toreturn_str << "<a href='#' data-role='button' class='profile'>"
					toreturn_str << "<i class='icon-profile'></i>"
					toreturn_str << "</a>"
					toreturn_str << "<div class='profile-details'>"
					toreturn_str << "<ul>"
					toreturn_str << "<li><a rel='external' href='/app/Menu/profile'>#{getLabelValue('My Profile')}</a></li>"
					toreturn_str << "<li><a rel='external' href='/app/Menu/exit'>#{getLabelValue('Exit')}</a></li>"
					toreturn_str << "</ul>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"

				elsif (mode == "add" || mode == "edit") && !moreOptionsList.empty?
					if offlineApplicationEnvironmentLocal.value.to_s != "PRODUCTION" 
						displayLogBtn = "none"
						if modelLogFile != "" && $rhoconfig[:setPolicyModelLog] == 1
							displayLogBtn = ""
						end
						$logFileReferenceField = modelLogFile
	 					toreturn_str << "<div class='header-action' id='showLogBtn' style='display:#{displayLogBtn}'>"
	 					toreturn_str << "<a href='javascript: showLogFile(\"#{modelLogFile}\")' data-role='button' class='' title='Show Log' id='policyModelLogLink'>"
	 					toreturn_str << "<i class='icon-basic'></i>"
	 					toreturn_str << "</a>"
	 					toreturn_str << "</div>"
 					end
					toreturn_str << "<div class='header-action'>"
					toreturn_str << "<a href='#' data-role='button' class='quicklink'>"
					toreturn_str << "<i class='icon-menu-bar'></i>"
					toreturn_str << "</a>"
					toreturn_str << "<div class='quicklink-details'>"
					toreturn_str << "<ul>"
					moreOptionsList.each_with_index do |option, index|
						toreturn_str << "<li id='quicklink_#{option}'><a rel='external' href='#{moreOptionsURLSList[index].to_s}'>#{getLabelValue(option)}</a></li>"
					end
					toreturn_str << "</ul>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
				if (@errors==nil || @errors.empty?) && (@incompleteTabs==nil || @incompleteTabs.empty?)
					errorDisplay = "style='display:none;' "
				end
				size = 0
				if (@errors && !@errors.empty?)
					@errors.each do |tabId, tabErrors|
						tabErrors.each do |guid, fieldError|
							fieldError.each do |field, errorMessageList|
								size += errorMessageList.size
							end
						end
					end
				end
				if (@incompleteTabs && !@incompleteTabs.empty?)
					size += @incompleteTabs.size
				end
				size = "" if size.to_i == 0
				toreturn_str << "<div class='header-action' #{errorDisplay}>"
				toreturn_str << "<a href='#error-list' data-rel='popup' data-position-to='window' data-transition='pop' class='common-error ui-link' title='Error List' aria-expanded='false' aria-haspopup='true' aria-owns='error-list'>"
				toreturn_str << "<i class='icon-error-message'></i>"
				toreturn_str << "</a>"
				toreturn_str << "<span class='error-notification'>#{size}</span>"
				toreturn_str << "</div>"

				toreturn_str << "</div>"

				toreturn_str << "<div data-role='popup' id='error-list' data-theme='a' class='ui-corner-all popup-wrapper error-popup'>"
				if (@errors && !@errors.empty?) || (@incompleteTabs && !@incompleteTabs.empty?)
					toreturn_str << "<div class='popup-close-cust'>"
					toreturn_str << "<a href='#' data-rel='back' class='icon-close'></a>"
					toreturn_str << "</div>"
					toreturn_str << "<div class='close-before-save'>"
					toreturn_str << "<h3>#{getLabelValue('errorList')}</h3>"
					toreturn_str << "<div class='error-list-bg'>"
					if (@errors && !@errors.empty?)
						@errors.each do |tabId, tabErrors|
							toreturn_str << "<h4 class='tabId'>#{getLabelValue(tabId)}:</h4>"
							toreturn_str << "<ul>"
							tabErrors.each do |guid, fieldError|
								fieldError.each do |field, errorMessageList|
									errorMessageList.each do |errorMessage|
										toreturn_str << "<li class='errorMessage'>#{errorMessage}</li>"
									end
								end
							end
							toreturn_str << "</ul>"
						end
					end
					if (@incompleteTabs && !@incompleteTabs.empty?)
						@incompleteTabs.each do |incompleteTab|
							if incompleteTab.to_s != ""
								errMessage = MobiSys::CommonUtil.replacePlaceHolders(getLabelValue("PLZ_ENTER"), [incompleteTab])
								toreturn_str << "<h4 class='incompleteTab'>#{errMessage}</h4>"
							end
						end
					end
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
				toreturn_str << "</div>"
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in headerTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate page tag
		def pageTagStart(id,title="", adhocClass="")
			toreturn_str = ""
			begin
				#Reset the hash maps created for runtime context evaluation.
				$parentChildGuidMapping = nil
				$contextMasterEvalHash = nil

				className = adhocClass.to_s != '' ? "class='#{adhocClass}'"  : ''

				toreturn_str << "<div data-role='page' id='#{id}' data-title='#{title}' #{className}>"
			rescue Exception => e
				Rho::Log.error("Error in pageTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate end page tag
		def pageTagEnd
			toreturn_str = ""
			begin
				toreturn_str << "</div>"
				
			rescue Exception => e
				Rho::Log.error("Error in pageTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate menu tag
		def menuTag(currentModule='HOME',isMinimumRequired=false)
			toreturn_str = ""
			begin
				activeClass = "class='active'"
				agentRegdetails = AgentReg.getCurrentAgentReg
				menuConfigs = agentRegdetails.applicableMenus.to_s != "" ? agentRegdetails.applicableMenus.to_s : $rhoconfig[:menuConfig].to_s

				isMinimumRequired = false if $rhoconfig[:application_view_mode] == "mobile"
				if menuConfigs
	            	toreturn_str << "<div class='fixed-left-menu'>"
		            toreturn_str << "<ul class='menu-wrapper home-menu'>"
		            toreturn_str << "<a #{activeClass if currentModule=='HOME'} href='/app/Menu/landingPage' data-transition='slide' rel='external'>"
		            toreturn_str << "<li><i class='icon-home'></i>"
					unless isMinimumRequired
	                	toreturn_str << "<h6>#{getLabelValue('HOME')}</h6>"
	                end
	                toreturn_str << "</li>"
	                toreturn_str << "</a>"
		            menuConfigs.split(',').each do |eachMenu|
		                if eachMenu == 'LeadManagementTab'
			                toreturn_str << "<a #{activeClass if currentModule=='LEADS'} href='/app/Lead/search' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-leads'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('LEADS')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
			            elsif eachMenu == 'CollateralTab'
			            	if $rhoconfig[:useCollateralRenderLevel]
								toreturn_str << "<a #{activeClass if currentModule=='COLLATERAL'} href='/app/CollateralRenderLevel/fetch' data-transition='slide' rel='external'>"
							else
								toreturn_str << "<a #{activeClass if currentModule=='COLLATERAL'} href='/app/Level0/entrypoint' data-transition='slide' rel='external'>"
							end
				            toreturn_str << "<li><i class='icon-collateral'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('COLLATERAL')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
			            elsif eachMenu == 'FNA'
			            	toreturn_str << "<a #{activeClass if currentModule=='FNA'} href='/app/FNARequest/search' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-fna-rpq'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('FNA & RPQ')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
			            elsif eachMenu == 'SalesIllustrationTab'
			            	toreturn_str << "<a #{activeClass if currentModule=='SALESILLUSTRATION'} href='/app/Menu/getInsuranceType?module=SALESILLUSTRATION' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-illustration'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('ILLUSTRATION')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
			            elsif eachMenu == 'NewBusinessTab'
			            	toreturn_str << "<a #{activeClass if currentModule=='EAPP'} href='/app/Menu/getInsuranceType?module=EAPP' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-e-app'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('EAPP')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
			            elsif eachMenu == 'GenerateMultipleOutputs'
			            	toreturn_str << "<a #{activeClass if currentModule=='GENERATEMULTIPLEOUTPUTS'} href='/app/Quotation/illustrationSelect' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-illustration'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('GenerateMultipleOutputs')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"    
			            elsif eachMenu == 'RECEIPTING'
			            	toreturn_str << "<a #{activeClass if currentModule=='RECEIPTING'} href='/app/Menu/receipting' data-transition='slide' rel='external'>"
				            toreturn_str << "<li><i class='icon-receipting'></i>"
							unless isMinimumRequired
			                	toreturn_str << "<h6>#{getLabelValue('RECEIPTING')}</h6>"
			                end
			                toreturn_str << "</li>"
			                toreturn_str << "</a>"
						end
		            end
	                toreturn_str << "</ul>"
	                toreturn_str << "</div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in menuTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to start a tabbar tag
        def tabbarTagStart(ids, labels, imgNames="", isNumberingReqd=false)
            toreturn_str = ""
            begin
                isNumberingReqd = false # numeric tabs are depricated.
                @idList = ids.split(",")
                labelsList = labels.split(",")
                imgNamesList = imgNames.split(",")
                @currentActiveTabIdx = -1
                @tabToBeLoaded = @params['sym_current_Tab']
                @tabToBeLoaded = @idList[0] unless @tabToBeLoaded
                toreturn_str << "<input type='hidden' name='sym_current_Tab' id='sym_current_Tab' value='#{@tabToBeLoaded}'>"
                
                toreturn_str << "<div data-role='main' class='ui-content'>"
                toreturn_str << "<div class='main-content-wrapper main-content-full touch'>"
                if isNumberingReqd 
                        toreturn_str << "<div class='section-tab'>"
                else
                        toreturn_str << "<div class='basic-contentwrapper'>" 
                		toreturn_str << "<div class='basictop-navareawrapper'>"
                        toreturn_str << "<div class='basictop-navarea'>"
                end
                toreturn_str << "<ul class='mobile-baasic-nav tab-mobile'>"
				width = 100.0/@idList.size
                classNameNext = "style='width:#{width}%;'"
                @idList.each_with_index do |id, index|
	                act = ""
	                tabErrorCount = 0
	                if (@errors && !@errors.empty?)
	                    @errors.each do |tabId, tabErrors|
                            if tabId == id
                                tabErrors.each do |guid, fieldError|
                                	currentErrorCount = 0
                                	fieldError.each do |errorKey,errorMessages|
                                		currentErrorCount = currentErrorCount + errorMessages.size
                                	end
                                    tabErrorCount = tabErrorCount + currentErrorCount
                                end
                            end
                        end
	                end
                    if @errorTabs && @visitedTabs.include?(id)
                        if @errorTabs.include?(id) || @incompleteTabs.include?(id)
                                tabStatus = "<span class='errorcounter' id='error-notification'>#{tabErrorCount}</span>"
                        else
                                tabStatus = "<img class='progress-notification' src='/public/jazz/images/progress-completed.png' alt='Completed successfully'>"
                        end
                    end
                    if @tabToBeLoaded != nil && @tabToBeLoaded == id
                        act = "class='active'"
                        @currentActiveTabIdx = index
                    end

                    # toreturn_str << "<li #{classNameNext}>"
                    toreturn_str << "<li>"
                    toreturn_str << "<a href='javascript:submitTabForm(\"#{id}\");' data-url='##{id}' data-transition='slide' #{act}>"
                    if  isNumberingReqd
						toreturn_str << "<span class='tab-icon-bg'>#{index+1}</span><p class='tab-name'>#{getLabelValue(labelsList[index].to_s)}#{tabStatus}</p>"					
                    else
                            toreturn_str << "<i class='#{imgNamesList[index].to_s}'>#{tabStatus}</i><span>#{getLabelValue(labelsList[index].to_s)}</span>"
                    end
                    toreturn_str << "</a>"
                    toreturn_str << "</li>"
                    if index != @idList.size-1
                    	# toreturn_str << "<li class='p-0'><i class='icon-arrow-right02'></i></li>"
            		end
            	end
                toreturn_str << "<p class='btn-toggle'><i class='icon-action'></i></p>"
                toreturn_str << "</ul>"
                toreturn_str << "</div>" # closing section-tab/ basictop-navarea
                toreturn_str << "</div>" if !isNumberingReqd  # closing navareawrapper
                if isNumberingReqd
                    toreturn_str << "<div class='project-content-bg'>"
                    toreturn_str << "<div class='project-content'>"
                else
                    toreturn_str << "<div class='tab-content-area'>"
                end
            rescue Exception => e
                Rho::Log.error("Error in tabbarTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
            end
            return toreturn_str
        end


		# Method to end a tabbar tag
		def tabbarTagEnd(isNumberingReqd=false, customFooter=false, buttonUrl="", buttonLabel="")
			toreturn_str = ""
			begin
				toreturn_str << MobiSys::BrowserHelper.attachMaskAll(true)
				if isNumberingReqd
					if System::get_property('platform') == 'ANDROID' && !Rho::System.isRhoSimulator && $rhoconfig[:application_view_mode] != "mobile"
						toreturn_str << "<div style='margin-bottom: 350px!important;'></div>"
					end
					toreturn_str << "</div>" # closing project-content
					toreturn_str << "</div>" #closing project-content-bg
				else
					if System::get_property('platform') == 'ANDROID' && !Rho::System.isRhoSimulator && $rhoconfig[:application_view_mode] != "mobile"
						toreturn_str << "<div style='margin-bottom: 350px!important;'></div>"
					end
					toreturn_str << "</div>" # closing tab-content-area
				end

				unless isNumberingReqd
					toreturn_str << "</div>" # closing basic-contentwrapper
				end

				# calculate total buttons to get the width per button
				totalButtons = 2.0
				
				if @currentActiveTabIdx > 0
					totalButtons+=1
				end
				if @currentActiveTabIdx < (@idList.size-1)
					totalButtons+=1
				end
				
				width = 100.0/totalButtons - 0.25
				classNameNext = "style='width:#{width}%;'"
				footerMobile = ""
				footerMobile = "footer-mobile" if $rhoconfig[:application_view_mode] == "mobile"
				toreturn_str << "</div>" # closing main-content-wrapper
				toreturn_str << "<div class='footer-bg #{footerMobile}'>"
				if customFooter
					buttonUrlList = buttonUrl.split('|')
					buttonLabelList = buttonLabel.split('|')
					width = 100.0/buttonUrlList.size
					classNameNext = "style='width:#{width}%;'"
					
					buttonUrlList.each_with_index do |url,i|
						toreturn_str << "<a href='#{url}' data-transition='slide' #{classNameNext}>#{getLabelValue(buttonLabelList[i])}</a>"
					end
				else
					if @currentActiveTabIdx > 0
						toreturn_str << "<a href='javascript:submitTabForm(\"#{@idList[@currentActiveTabIdx-1]}\");' data-transition='slide' #{classNameNext}>"
						toreturn_str << "<i class='icon-save-previous'></i><span class='footer-link-text'>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "#{getLabelValue('saveAndPrev')}"
						toreturn_str << "</span>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "</a>"
					end

					toreturn_str << "<a href='javascript:submitTabForm(\"#{@idList[@currentActiveTabIdx]}\",true);' data-transition='slide' #{classNameNext}>"
					toreturn_str << "<i class='icon-close02'></i><span class='footer-link-text'>" if $rhoconfig[:application_view_mode] == "mobile"
					toreturn_str << "#{getLabelValue('Discard')}"
						toreturn_str << "</span>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "</a>"

					toreturn_str << "<a href='javascript:submitTabForm(\"#{@idList[@currentActiveTabIdx]}\",false);' data-transition='slide' #{classNameNext}>"
					toreturn_str << "<i class='icon-save'></i><span class='footer-link-text'>" if $rhoconfig[:application_view_mode] == "mobile"
					toreturn_str << "#{getLabelValue('Save')}"
						toreturn_str << "</span>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "</a>"

					if @currentActiveTabIdx < @idList.size-1
						toreturn_str << "<a href='javascript:submitTabForm(\"#{@idList[@currentActiveTabIdx+1]}\");' data-transition='slide' #{classNameNext}>"
						toreturn_str << "<i class='icon-save-continue'></i><span class='footer-link-text'>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "#{getLabelValue('saveAndCont')}"
						toreturn_str << "</span>" if $rhoconfig[:application_view_mode] == "mobile"
						toreturn_str << "</a>"
					end
				end
				toreturn_str << "</div>" # closing footer-bg
				toreturn_str << "</div>" # closing ui-content

				@idList = nil
				@currentActiveTabIdx = nil
			rescue Exception => e
				Rho::Log.error("Error in tabbarTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to start a tab tag
		def tabTagStart(id)
			toreturn_str = ""
			begin
				toreturn_str << "<div id='#{id}'>"
			rescue Exception => e
				Rho::Log.error("Error in tabTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to end a tab tag
		def tabTagEnd
			toreturn_str = ""
			begin
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in tabTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to start a navbar tag
		def navbarTagStart(ids, labels)
			toreturn_str = ""
			begin
				idList = ids.split(',')
				labelList = labels.split(',')
				@navbarToBeLoaded = @params['sym_navbar']
				@tabToBeLoaded = @params['sym_current_Tab'] if @params['sym_current_Tab'].to_s != ''
				@navbarToBeLoaded = @tabToBeLoaded + '-' + idList[0].to_s if @navbarToBeLoaded.to_s == ''
				toreturn_str << "<input type='hidden' name='sym_navbar' id='sym_navbar' value='#{@navbarToBeLoaded}'>"

				toreturn_str << "<div class='subTabs'>"
				toreturn_str << "<div data-role='navbar'>"
				toreturn_str << "<ul class='tab-name' role='tablist'>"
				idList.each_with_index do |id, index|
					id = @tabToBeLoaded + '-' + id
					toreturn_str << "<li><a "
					toreturn_str << "class='ui-btn-active' " if @navbarToBeLoaded != nil && id == @navbarToBeLoaded
					
					toreturn_str << "href='javascript:submitTabForm(\"#{@tabToBeLoaded}\",false,\"#{id}\");' data-url='##{id}' data-transition='slide'
					>"
					toreturn_str << getLabelValue(labelList[index])
					toreturn_str << "</a></li>"
				end
				toreturn_str << "</ul>"
				toreturn_str << "</div>"
				toreturn_str << "<div id='navbarContent' role='tabpanel'>"
			rescue Exception => e
				Rho::Log.error("Error in navbarTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to end a navbar tag
		def navbarTagEnd
			toreturn_str = ""
			begin
				toreturn_str << "</div>" # closing .subTabs
				toreturn_str << "</div>" # closing .subTabs
			rescue Exception => e
				Rho::Log.error("Error in navbarTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate form tag
		def formTagStart(nameAttr,action,entityId="")
			toreturn_str = ""
			begin
				toreturn_str << "<form id='#{nameAttr}' name='#{nameAttr}' action='#{action}' method='POST' >"
				toreturn_str << "<input type='hidden' id='entityId' value='#{entityId}'/>"
			rescue Exception => e
				Rho::Log.error("Error in formTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate end form tag
		def formTagEnd
			toreturn_str = ""
			begin
				toreturn_str << "</form>"
			rescue Exception => e
				Rho::Log.error("Error in formTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate panel tag
		def panelTagStart(accordionView=true)
			toreturn_str = ""
			begin
				if accordionView
					toreturn_str << "<div class='collapse-panel' data-role='collapsible-set' data-iconpos='right' data-corners='false' data-theme='c'>"
				else
					toreturn_str << "<div class='collapse-panel' data-iconpos='right' data-corners='false' data-theme='c'>"
				end
			rescue Exception => e
				Rho::Log.error("Error in panelTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str		
		end


		# Method to generate end panel tag
		def panelTagEnd
			toreturn_str = ""
			begin
				# toreturn_str << "<div class='clearfix'></div>"
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in panelTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str		
		end


		# Method to generate each collapsible tag
		def subPanelTagStart(collapsibleHeader,collapseRequired=true,facetIds="",collapsiblePanel=true,adhocContent='')
			toreturn_str = ""
			begin
				facetIdList = facetIds.to_s != '' ? facetIds.split(',') : []
				renderTypeFlag = true
				
				facetIdList.each_with_index do |facet, index|
					if facet.include?("&")
						conditionalFacetIdList = facet.split('&')
						conditionalFacetIdList.each do |each_facetid|
							renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(each_facetid, $currentProduct)
							break unless renderTypeFlag
						end
					else
						renderTypeFlag = MobiSys::BrowserHelper.renderPanel?(facet, $currentProduct)
					end
					break if renderTypeFlag
				end

				visibility = !renderTypeFlag ? "style='display:none;'" : ""
				if collapsiblePanel
					toreturn_str << "<div data-role='collapsible' data-collapsed='#{collapseRequired}' #{visibility} data-iconpos='right'>"
					toreturn_str << "<h3 #{adhocContent} >#{getLabelValue(collapsibleHeader)}</h3>"
				else
					toreturn_str << "<div #{visibility}>"
					toreturn_str << "<div class='labelHeader'>"
					toreturn_str << "<h3 #{adhocContent} >#{getLabelValue(collapsibleHeader)}</h3>"
					toreturn_str << "</div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in subPanelTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str		
		end


		# Method to generate each collapsible end tag
		def subPanelTagEnd
			toreturn_str = ""
			begin
				toreturn_str << "</div>"
				toreturn_str << "<div class='clearfix'></div>"
			rescue Exception => e
				Rho::Log.error("Error in subPanelTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str		
		end


		# Method to generate tabular tag
		def fieldDataEntryGridTagStart(id, metaDataObject, columnIds, objects, parent, labelObject=nil, checkboxMode='', startCount="", metaDataFields="", allowDelete=true, isFormWiseDisplay=false, isPanelLayoutDisplay=false, accordionView=true, collapseRequired=true, headerFieldName="", headerPrefix="",columnWidths="",facetIds="",collapsiblePanel=true,ignoreMetadata=false, isFilterRequiredFl=false, listOfHiddenFields=nil, isMoreReqd=false)
			toreturn_str = ""
			minOccurs = ""
			visibility = nil
			@columnIds = columnIds
			@checkboxMode = checkboxMode
			begin
				metaDataFieldList = metaDataFields.to_s != '' ? metaDataFields.split(',') : []
				toreturn_str << "<div class='#{id}-main-class' >"
				if isPanelLayoutDisplay
					toreturn_str << panelTagStart(accordionView)
					toreturn_str << subPanelTagStart(headerFieldName, collapseRequired, facetIds,collapsiblePanel)
				end
				if isFormWiseDisplay
					if objects && objects.size > 0
						objects.each_with_index do |object,index|
							gridID = "grid_#{index}_#{id}"
							toreturn_str << "<div class='add-section'>" 
							toreturn_str << "<i class='close-add-section icon-close' onClick='javascript:catchevent(this);' id='#{gridID}_removed'></i>" if allowDelete
							toreturn_str << modelTagStart(gridID, object, parent, startCount.to_i+index)
							if ignoreMetadata
								toreturn_str << layoutFieldTag(columnIds,nil)
							else
								toreturn_str << prdFieldDataTag(metaDataObject,columnIds,nil,metaDataFields)
							end
							modelTagEnd
							toreturn_str << "</div>"
						end
					end
				else
					toreturn_str << "<div class='table-section'>"
					if isFilterRequiredFl
						toreturn_str << "<form>"
    					toreturn_str << "<input class='filterableTableInput' id='#{id}_filterTable-input' data-type='search'>"
						toreturn_str << "</form>"
						# toreturn_str << "<input type='search' class='filterableTableInput' id='#{id}_filterTable-input' value=''>"
						toreturn_str << "<table data-role='table' class='ui-responsive' data-input='##{id}_filterTable-input' data-filter='true'>"
					else
						toreturn_str << "<table data-role='table' class='ui-responsive'>"

					end
					toreturn_str << "<thead>"
					toreturn_str << "<tr>"
					toreturn_str<< "<th style= 'display: none'></th>" if $rhoconfig[:application_view_mode] == 'mobile' 
					columnIdList = columnIds.split(',')
					columnWidthList = columnWidths.split(',')

					modelTagStart(id, labelObject, parent)
					columnIdList.each_with_index do |column,index|
						if metaDataFieldList[index].to_s != ""
							metaDataCd = metaDataObject + "." + metaDataFieldList[index]
						else
							metaDataCd = metaDataObject + "." + column
						end
						if ignoreMetadata || $companyFieldMetaDataCache.include?(metaDataCd.to_sym)
							visibility = nil
							style = ""

							if $uiMetaDataCache.has_key?("#{@currentTagObject.class.name}DO.#{column}".to_sym)
								uiMetaDataDOList = $uiMetaDataCache["#{@currentTagObject.class.name}DO.#{column}".to_sym]

								ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
								visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
							end
							
							toreturn_str << "<th "
							toreturn_str << "style='width:#{columnWidthList[index]}%' " if columnWidthList[index]
							toreturn_str << "style='display:none !important;'" unless visibility
							toreturn_str << ">"
							toreturn_str << labelTag(column)
							toreturn_str << "</th>"
						end
					end
					modelTagEnd
					if checkboxMode != ''
						toreturn_str << "<th style='width:5%'>"
						toreturn_str << "<p class='col-left'>"
						if checkboxMode == 'add'
							toreturn_str << getLabelValue('select')
						elsif checkboxMode == 'delete'
							toreturn_str << getLabelValue('delete')
						end
						toreturn_str << "</p>"
						toreturn_str << "</th>" 
					end
					if isMoreReqd
						toreturn_str << "<th style='width:5%'>"
						toreturn_str << "<p class='col-left'>"
						toreturn_str << getLabelValue('More')
						toreturn_str << "</p>"
						toreturn_str << "</th>" 
					end

					toreturn_str << "</tr>"
					toreturn_str << "</thead>"
					toreturn_str << "<tbody>"
					if objects && objects.size > 0
						objects.each_with_index do |object,index|
							gridID = "grid_#{startCount.to_i+index}_#{id}"
							toreturn_str << "<tr class='add-tabular-row'>"
							toreturn_str << "<td style='display: none'>" if $rhoconfig[:application_view_mode] == 'mobile' 
							toreturn_str << modelTagStart(gridID, object, parent, startCount.to_i+index)
							toreturn_str << "</td>" if  $rhoconfig[:application_view_mode] == 'mobile' 
							columnIdList.each_with_index do |column, colIndex|
								if metaDataFieldList[colIndex].to_s != ""
									metaDataCd = metaDataObject + "." + metaDataFieldList[colIndex]
								else
									metaDataCd = metaDataObject + "." + column
								end
								if ignoreMetadata || $companyFieldMetaDataCache.include?(metaDataCd.to_sym)
									visibility = nil
									style = ""

									if $uiMetaDataCache.has_key?("#{@currentTagObject.class.name}DO.#{column}".to_sym)
										uiMetaDataDOList = $uiMetaDataCache["#{@currentTagObject.class.name}DO.#{column}".to_sym]

										ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts)
										visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
									end

									style = "style='display:none;'" unless visibility
									
									toreturn_str << "<td #{style} >"
									toreturn_str << "<div class='error-msg-append'>"
									toreturn_str << inputTag(column)
									toreturn_str << "</div>"
									toreturn_str << errorTag(column,'table')
									toreturn_str << "</td>"
								end
							end
							if listOfHiddenFields != nil
								toreturn_str << "<td style='display:none;' >"
								listOfHiddenFields.split(',').each do |hiddenFieldName|
									toreturn_str << inputTag(hiddenFieldName, nil, nil, nil, nil, nil, 'HIDDEN')
								end
								toreturn_str << "</td>"
							end
							if checkboxMode == 'add' && @currentTagObject.send("removed".to_sym).to_s == ""
								checked = "checked"
							end
							if checkboxMode == 'delete' 
								toreturn_str << "<td class='close-checkbox'>"
							elsif checkboxMode != ''
								toreturn_str << "<td>"
							end
							if checkboxMode != ''
								toreturn_str << "<label class='label' for='#{gridID}_removeButton'>"
								toreturn_str << "<input type='checkbox' id='#{gridID}_removeButton' onClick='javascript:catchevent(this);' data-checkbox-mode='#{@checkboxMode}' #{checked}/>"
								toreturn_str << "</label>"
								toreturn_str << "</td>"
							end
							if isMoreReqd
								toreturn_str << "<td><a href=\"javascript:addMore_#{id}('#{gridID}');\" data-rel='popup' data-transition='pop'><i class='icon-action' ></i></a></td>"
							end
							modelTagEnd
							toreturn_str << "</tr>"
						end
					end
					toreturn_str << "</tbody>"
					toreturn_str << "</table>"
					toreturn_str << "</div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in fieldDataEntryGridTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		# Method to generate end fieldDataEntryGridTag
		def fieldDataEntryGridTagEnd(id, objects, label, allowAdd=true ,isFormWiseDisplay=false, isPanelLayoutDisplay=false)
			toreturn_str = ""
			count = objects ? objects.size : 0
			begin
				if isFormWiseDisplay
					toreturn_str << "<div class='clearfix'></div>"
					if allowAdd
						toreturn_str << "<div class='project-data-full' style='padding-right:1%;'>"
						toreturn_str << "<a class='anchor-add-section' id='#{id}_addButton' href='#' onClick='javascript:catchevent(this);'>"
						toreturn_str << "<div class='button-add-section'>"
						toreturn_str << getLabelValue(label)
						toreturn_str << "<i class='icon-plus'></i>"
						toreturn_str << "<span class='notification'>#{count}</span>"
						toreturn_str << "</div>"
						toreturn_str << "</a>"
						toreturn_str << "</div>"								
					end
					toreturn_str << "<div class='clearfix'></div>"
				else
					toreturn_str << "<div class='clearfix'></div>"
					if allowAdd
						toreturn_str << "<div class='project-data-full' style='padding-right:1%;'>"
						toreturn_str << "<a class='anchor-add-section' data-columns='#{@columnIds}' data-checkbox-mode='#{@checkboxMode}' id='#{id}_addButton' href='#' onClick='javascript:catchevent(this);'>"
						toreturn_str << "<div class='button-add-section'>"
						toreturn_str << getLabelValue(label)
						toreturn_str << "<i class='icon-plus'></i>"
						toreturn_str << "<span class='notification'>#{count}</span>"
						toreturn_str << "</div>"
						toreturn_str << "</a>"
						toreturn_str << "</div>"
					end
					toreturn_str << "<div class='clearfix'></div>"
				end
				if isPanelLayoutDisplay
					toreturn_str << subPanelTagEnd
					toreturn_str << panelTagEnd
				end
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in fieldDataEntryGridTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str		
		end


		# Method to generate input fields using Questionnaire configuration
		# entityDO can be Policy or Quotation, responseHash is list of all serviceQuestionResponse for particular QuestionContainer, Pass life only if question belongs to life and not Policy or Quotation
		def qstFieldDataTag(fieldIds, questionSetCd, questionContainer, entityDO, responseHash, life=nil, rowDivision=2, startOnNewLine=true)
			toreturn_str = ""
			begin
				fieldList = fieldIds.split(',')
				if fieldList.size > 0
					toreturn_str << modelTagStart("formBasedQuestionContainer", questionContainer) 
					toreturn_str << renderHiddenField("entityGuid", questionContainer.entityGuid, nil, questionContainer) 
					toreturn_str << renderHiddenField("policyGuid", questionContainer.policyGuid, nil, questionContainer)
					toreturn_str << renderHiddenField("entityTypeCd", questionContainer.entityTypeCd, nil, questionContainer) 
					toreturn_str << renderHiddenField("additionalFieldQuest", questionContainer.additionalFieldQuest, nil, questionContainer) 
				end
				fieldList.each_with_index do |field,index|
					questionSetQuestionObj = QuestionSetQuestion.find(
			            :first, 
			            :conditions=>{
			                {:name=>'dataElementCd'} => field,
			                {:name=>'questionSetCd'} => questionSetCd
			            },
			            :op => 'AND'
			        )
			        if questionSetQuestionObj
			        	questionSetQuestion = questionSetQuestionObj.hashForSync
						responseObj = getResponseForTag(questionSetQuestion, questionContainer, responseHash, entityDO, life)
						formId = "formBasedServiceQstRsp_#{index}"
						toreturn_str << modelTagStart(formId, responseObj, questionContainer, nil, false)

						hiddenNameAttr = "#{$objectMapping[@currentTagObject.object.to_s]}"
						toreturn_str << printHiddenField("#{hiddenNameAttr}[partyGuid]", "#{formId}_partyGuid", responseObj.partyGuid)
						toreturn_str << printHiddenField("#{hiddenNameAttr}[entityGuid]", "#{formId}_entityGuid", responseObj.entityGuid)
						toreturn_str << printHiddenField("#{hiddenNameAttr}[questionSetCd]", "#{formId}_questionSetCd", responseObj.questionSetCd)
						toreturn_str << printHiddenField("#{hiddenNameAttr}[questionDataElementCd]", "#{formId}_questionDataElementCd", responseObj.questionDataElementCd)
						toreturn_str << printHiddenField("#{hiddenNameAttr}[questionnaireTypeCd]", "#{formId}_questionnaireTypeCd", responseObj.questionnaireTypeCd)
						toreturn_str << printHiddenField("#{hiddenNameAttr}[removed]", "#{formId}_removed", responseObj.removed)

						errorMessageList = []
						errorStyle = ""
						if @errors!=nil && !@errors.empty?
							@errors.each do |tabId, tabErrors|
								if tabErrors.has_key?(@currentTagObject.guid) && tabErrors[@currentTagObject.guid].has_key?('responseValue') && !tabErrors[@currentTagObject.guid]['responseValue'].empty?
									errorMessageList += tabErrors[@currentTagObject.guid]['responseValue']
									errorStyle = "error-msg"
								end
							end
						end
						errorLink, errorMessage = errorQuestionTag(errorMessageList) unless errorMessageList.empty?

						nameAttr = "#{$objectMapping[@currentTagObject.object.to_s]}[responseValue]"
						if life
							id = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{life.guid}"
						else
							id = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{entityDO.guid}"
						end
						value = responseObj.responseValue
						visibility = questionSetQuestion[:visibility].to_s == "NO" ? false : true
						enabled = questionSetQuestion[:enabled].to_s == "NO" ? false : true
						inputType = questionSetQuestion[:inputTypeCd]
						minOccurs = questionSetQuestion[:mandatory].to_s == "YES" ? "1" : "0"
						entity = questionSetQuestion[:entityFieldTypeCd].to_s
						maxlength = questionSetQuestion[:maxlength].to_s
						datatype = questionSetQuestion[:dataElementType].to_s
						lookup = questionSetQuestion[:lookupkey].to_s
						fieldLabelCd = questionSetQuestion[:questionCd].to_s == '' ? field : questionSetQuestion[:questionCd].to_s
						adhocContent = "data-questioncd='#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}'"
			            #set field readonly if enabled is 'NO' and render hidden field for value
						if questionSetQuestion[:enabled] && questionSetQuestion[:enabled].to_s == "NO"
							adhocContent << " disabled='disabled'"
							toreturn_str << printHiddenField(nameAttr, id, value)
						end
						style = "style='display:none;' " unless visibility

						if inputType != 'HIDDEN'
							if rowDivision == 2
								toreturn_str << "<div class='project-data' #{style}>"
							elsif rowDivision == 1
								toreturn_str << "<div class='project-data-full' #{style}>"
							end
		                    toreturn_str << "<div class='row-details #{errorStyle}'>"
		                    
							toreturn_str << labelTag(fieldLabelCd, nil)
							toreturn_str << "<p class='col-right'>"
		                end

						if inputType == "NUMERICSTRING" || inputType == "TEXT" || inputType == "" || inputType == "EMAIL"
							toreturn_str << printTextBox(nameAttr, id, value, label, visibility, enabled, inputType, caseType, mask, placeHolderReqd, minOccurs, entity, width, maxlength, datatype)
						elsif inputType == "PASSWORD"
							toreturn_str << printPasswordBox(nameAttr, id, value, label, lookup, visibility, enabled, minOccurs, entity, width, maxlength)
						elsif inputType == "COMBO" || inputType == "FCOMBO" || inputType == "LOOKUPTEXT"
							toreturn_str << printSelectBox(nameAttr, id, value, label, lookup, visibility, enabled, inputType, minOccurs, entity, width, maxlength)
						elsif inputType == "NCOMBO"
							toreturn_str << printSelectBox(nameAttr, id, value, label, lookup, visibility, enabled, inputType, minOccurs, entity, width, maxlength)
						elsif inputType == "RADIO"
							toreturn_str << printRadioButton(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity)
						elsif inputType == "CHECKBOX"
							toreturn_str << printCheckbox(nameAttr, id, value, lookup, visibility, enabled, minOccurs, entity)
						elsif inputType == "DATE"
							toreturn_str << printDateControl(nameAttr, id, value, label, visibility, enabled, placeHolderReqd, minOccurs, entity, width, maxlength)
						elsif inputType == "DATETIME" || inputType == "TIMESTAMP"
							toreturn_str << printDateTimeControl(nameAttr, id, value, label, visibility, inputType, enabled, placeHolderReqd, minOccurs, entity, width, maxlength)
						elsif inputType == "TEXTAREA"
							toreturn_str << printTextArea(nameAttr, id, value, rows, cols, visibility, enabled, placeHolderReqd, minOccurs, entity)
						elsif inputType == "HIDDEN"
							toreturn_str << printHiddenField(nameAttr, id, value)
						elsif inputType == "LABELCOMBO"
							toreturn_str << printLabelComboBox(nameAttr, id, value, lookup)
						elsif inputType == "LABEL"
							toreturn_str << printLabel(nameAttr, id, value)
						elsif inputType == "IMAGE"
							toreturn_str << printImage(nameAttr, id, value)
						elsif inputType == "LINK"
							toreturn_str << printLink(nameAttr, id, value)
						end
						toreturn_str << errorTag('responseValue') 
						if inputType != 'HIDDEN'
							toreturn_str << "</p>"
							toreturn_str << "</div>"
							toreturn_str << "</div>"
						end
						modelTagEnd
					end
				end
				modelTagEnd if fieldList.size > 0
				if startOnNewLine
					toreturn_str << "<div class='clearfix'></div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in qstFieldDataTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end

		def getResponseForTag(questionSetQuestion, questionContainer, responseHash, entity, life=nil)
			if life
				key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{entity.uniqueKey}|#{life.uniqueKey}"
			else
				key = "#{questionSetQuestion[:questionSetCd]}|#{questionSetQuestion[:dataElementCd]}|#{entity.uniqueKey}"
			end
			if !responseHash.has_key?(key) || responseHash[key] == nil

				values = {
					:entityGuid => questionContainer.policyGuid,
					:questionSetCd => questionSetQuestion[:questionSetCd],
					:questionDataElementCd => questionSetQuestion[:dataElementCd],
					:questionnaireTypeCd => questionContainer.additionalFieldQuest,
					:removed => ""
				}
				serviceQuestionResponse = ServiceQuestionResponse.new(values)
				serviceQuestionResponse.partyGuid = life.uniqueKey if life
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
			return serviceQuestionResponse
		end

		#Method to create a response hash of all existing ServiceQuestionResponses for easy lookup
		def self.setupResponseHashForTag(questionContainer)
			responseHash = {}

			questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponse|
				key = "#{serviceQuestionResponse.questionSetCd}|#{serviceQuestionResponse.questionDataElementCd}|#{serviceQuestionResponse.entityGuid}"
				key << "|#{serviceQuestionResponse.partyGuid}" if serviceQuestionResponse.partyGuid.to_s != ""
				responseHash[key] = serviceQuestionResponse
			end

			return responseHash
		end

		# Method to generate a search form
		# renderSearchWrapper flag to render or not parent wrapper with full width. If set as 'false', search form will be rendered within it's respective parent wrapper
		# tabWidthClass to set width of tabs using css class.
		def searchTag(columnIds, metaDataObject, resultList, advanced=true, delete=true, resultActionLabels='', resultActionIcons='', resultActionHrefs='', addButtonURL='', moreOptions='', moreOptionsURLS='', areTabsRequired=false, tabLabels='', tabLinks='', navigationLinks='', message='',renderSearchWrapper=true, tabWidthClass='',openUrl='',tabLayout='horizontal',linkAt = 0)
			toreturn_str = ""
			width = ""
			begin
				columnIdList = columnIds.split(",")
				hiddenColumnIndex = []
				action = false
				if resultActionLabels != '' && resultActionIcons != '' && resultActionHrefs != ''
					resultActionLabelsList = resultActionLabels.split(",")
					resultActionIconsList = resultActionIcons.split(",")
					resultActionHrefsList = resultActionHrefs.split(",")
					action = true
				end

				moreOptionsList = moreOptions.split(",")
				moreOptionsURLSList = moreOptionsURLS.split(",")

				MobiSys::Validation.initializeValidationHash unless $validationHash
				MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
				MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache
				toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.min.js'></script>"
    			toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.number.js'></script>"
    			toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.date.js'></script>"

				toreturn_str << "<div class='main-content-wrapper' id='search-wrapper'>" if renderSearchWrapper
				if areTabsRequired
					tabWidthClass = 'col-33' if tabWidthClass == ""
					toreturn_str << "<input type='hidden' id='currentTab' name='currentTab' value=#{@currentTab}>"
					if tabLayout == "vertical"
						toreturn_str << "<div class='leftnavigation'>"
						toreturn_str << "<div class='sec-nav'>"
						tablabelsList = tabLabels.split(",")
						tabLinksList = tabLinks.split(",")
						toreturn_str << "<ul>"
						tablabelsList.each_with_index do |label,index|
							toreturn_str << "<a href=\"#{tabLinksList[index]}\">"
							if label.downcase == @currentTab.downcase
								toreturn_str << "<li class='sec-nav-li-selected' id='#{label}'>"
							else
								toreturn_str << "<li class='sec-nav-li' id='#{label}'>"
							end
							toreturn_str << "#{getLabelValue(label)}"
							toreturn_str << " <span id='#{label}_count'>"
							toreturn_str << "</span>"
							toreturn_str << "</li>"
							toreturn_str << "</a>"
						end
						toreturn_str << "</ul>"
						toreturn_str << "</div>"
						toreturn_str << "</div>"
					else
						toreturn_str << "<div class='search-top-bg search-top-tabs'>"
						tablabelsList = tabLabels.split(",")
						tabLinksList = tabLinks.split(",")
						tablabelsList.each_with_index do |label,index|
							toreturn_str << "<a href=\"#{tabLinksList[index]}\">"
							activeclass = ""
							activeclass = "active" if label.downcase == @currentTab.downcase
							toreturn_str << "<div class='#{tabWidthClass} tab-cust #{activeclass}' id='#{label}'>"
							toreturn_str << "#{getLabelValue(label)}"
							toreturn_str << "</div></a>"
						end
						toreturn_str << "</div>"
					end
					if navigationLinks != ''
						toreturn_str << "<div class='search-top-bg search-top-tabs'>"
						navigationLinksList = navigationLinks.split(",")
						toreturn_str << "<a href=\"#{navigationLinksList.first}\">"
						toreturn_str << "<div class='ui-link ui-btn ui-btn-left ui-btn-inline navbutton-left' data-role='button' data-corners='false' data-inline='true' role='button'>"
						toreturn_str << "#{getLabelValue('PREVIOUS')}</div></a>"
						toreturn_str << "<div id='leadActivityMessage'>#{message}</div>"
						toreturn_str << "<a href=\"#{navigationLinksList.last}\">"
						toreturn_str << "<div class='ui-link ui-btn ui-btn-right ui-btn-inline navbutton-right' data-role='button' data-corners='false' data-inline='true' role='button'>"
						toreturn_str << "#{getLabelValue('NEXT')}</div></a>"
						toreturn_str << "</div>"
					end
				end
				
				toreturn_str << "<div id='contentpane_Test' class='rightcontentpane'>" if tabLayout == "vertical"

				toreturn_str << "<div class='search-top-bg'>"

				toreturn_str << "<div class='ui-field-contain'>"
				toreturn_str << "<input type='search' name='mainSearchField' id='search' value= '#{@mainSearchField}' placeholder='Search' class='search-bar'>"
				toreturn_str << "</div>"
				toreturn_str << "<div class='advance-search-btn1 search-btn-bg'>"
					toreturn_str << "<a href='#' id='search-go' data-role='button' data-corners='false' data-inline='true'>#{getLabelValue('GO')}</a>"
					toreturn_str << "</div>"
				toreturn_str << "<div class='search-mobile-bg'>" if $rhoconfig[:application_view_mode] == "mobile"
				if advanced
					toreturn_str << "<div class='advance-search-btn search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' data-corners='false' data-inline='true'>#{getLabelValue('advancedSearch')}</a>"
					toreturn_str << "</div>"
				end
				if resultList.size > 0 && delete
					toreturn_str << "<div class='delete-illustration search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' data-corners='false' data-inline='true'>#{getLabelValue('deleteRec')} #{getLabelValue('')}</a>"
					toreturn_str << "</div>"

					toreturn_str << "<div class='delete-confirm-bg'>"
					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='delete' data-corners='false' data-inline='true'>#{getLabelValue('delete')}</a>"
					toreturn_str << "</div>"
						toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='selectAll' data-corners='false' data-inline='true'>#{getLabelValue('selectAll')}</a>"
					toreturn_str << "</div>"

					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='cancel' data-corners='false' data-inline='true'>#{getLabelValue('CANCEL')}</a>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
				toreturn_str << "</div>" if $rhoconfig[:application_view_mode] == "mobile"
				toreturn_str << "<div class='btn-mobile-bg'>"
				if moreOptionsList.size > 0
					toreturn_str << "<div class='add-illustration-bg'>"
					toreturn_str << "<a class='leads-add add-illustration' href='#' data-transition='slide' title='More'>"
					toreturn_str << "<span class='button-text'>#{getLabelValue('More')} </span><i class='icon-menu-bar'></i> "
					toreturn_str << "</a>"
					toreturn_str << "<div class='add-illustration-details'>"
					toreturn_str << "<ul>"
					moreOptionsList.each_with_index do |option,index|
						toreturn_str << "<li><a rel='external' href=#{moreOptionsURLSList[index].to_s}>#{getLabelValue(option)}</a></li>"
					end
					toreturn_str << "</ul>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end

				toreturn_str << "<a class='leads-add' href='#{addButtonURL}' data-transition='slide' rel='external'><span class='button-text'>#{getLabelValue('Add')}</span> <i class='icon-plus'></i></a>" if addButtonURL != ''
				toreturn_str << "</div>"
				toreturn_str << "</div>"
				
				toreturn_str << "<div class='table-section'>"
				toreturn_str << "<table data-role='table' id='search-table' class='ui-responsive search-header-fixed'>"
				toreturn_str << "<thead>"
				if advanced
					toreturn_str << "<tr class='advance-search-field'>"
					columnIdList.each do |column|
						hidden = ""
						if $uiMetaDataCache.has_key?("#{metaDataObject}.#{column}".to_sym) && $rhoconfig[:application_view_mode] != 'mobile'
							uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{column}".to_sym]
							ui = MobiSys::UIMetaData.getUiMetadataPropDO("WIDTH", uiMetaDataDOList, @currentApplicableContexts)
							width = (ui == nil ? "" : ui.propertyValue.to_s)
							ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, [],"array")
							visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
							hidden = "display:none;" unless visibility 
						end
						toreturn_str << "<th style='width:#{width}%;#{hidden}'>"
						toreturn_str << inputTag(column,nil,nil,nil,nil,metaDataObject)
						toreturn_str << "</th>"
					end
					toreturn_str << "<th>"
					toreturn_str << "<div class='advance-search-btn1'>"
					toreturn_str << "<a class='close-advance-search-field' href='#' data-role='button' data-corners='false' data-inline='true'>X</a>"
					toreturn_str << "</div>"
					toreturn_str << "</th>"
					toreturn_str << "</tr>"
				end
				toreturn_str << "<tr>"
				columnIdList.each_with_index do |column,index|
					hidden = ""
					if $uiMetaDataCache.has_key?("#{metaDataObject}.#{column}".to_sym) && $rhoconfig[:application_view_mode] != 'mobile'
						uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{column}".to_sym]
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("WIDTH", uiMetaDataDOList, @currentApplicableContexts)
						width = (ui == nil ? "" : ui.propertyValue.to_s)
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, [],"array")
						visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
						unless visibility 
							hiddenColumnIndex <<index
							hidden = "display:none;"
						end
					end
					toreturn_str << "<th style='width:#{width}%;#{hidden}'>"
					toreturn_str << labelTag(column,metaDataObject, nil ,true)
					toreturn_str << "</th>"
				end
				toreturn_str << "<th class='text-center no-sort' data-sort-method='none'>Action</th>" if action
				toreturn_str << "<th class='text-center no-sort' data-sort-method='none'>&nbsp;</th>" unless action
				toreturn_str << "</tr>"
				toreturn_str << "</thead>"

				toreturn_str << "<tbody id='searchTable'>"
				resultList.each do |object,resultObject|
					toreturn_str << "<tr>"
					resultObject.each_with_index do |field,index|
						hidden = ""
						hidden = "display:none;" if (hiddenColumnIndex.include?index)
						if index == linkAt && openUrl.to_s != ""
							objectUrl = openUrl.to_s.gsub("#object",object.to_s)
							toreturn_str << "<td style='#{hidden}'><a href='#{objectUrl}' rel='external' class= 'ui-link'><span class='field-value'>#{field}</span></a></td>" 
						else	
							toreturn_str << "<td style='#{hidden}'><span class='field-value'>#{field}</span></td>"
						end
					end
					if action
						toreturn_str << "<td class='text-center action-toggle-bg'>"
						toreturn_str << "<div class='action-toggle-open'>"
						toreturn_str << "<i class='icon-action'></i>"
						toreturn_str << "</div>"

						toreturn_str << "<div class='delete-checkbox'>"
						toreturn_str << "<label for='#{object}'>"
						toreturn_str << "<input type='checkbox' id='#{object}' name='deleteCheck[]' value='#{object}'>"
						toreturn_str << "</label>"
						toreturn_str << "</div>"

						toreturn_str << "<div class='action-status-show'>"
						toreturn_str << "<div class='action-status-show-group'>"
						resultActionLabelsList.each_with_index do |resultActionLabel,index|
							if index > 0 
								if (index+1) %4 == 0
									styleClass = "sllrm-color"
								elsif (index+1)%4 == 3
									styleClass = "fna-color"
								elsif (index+1)%4 == 2
									styleClass = "status-color"
								elsif (index+1)%4 == 1
									styleClass = ""
								end
							end
							url = resultActionHrefsList[index].to_s.gsub("#object",object.to_s)
							if url.include?("#")
								popupAttr = "data-rel='popup' data-position-to='window' data-transition='pop'"
							else
								popupAttr = "rel='external'"
							end
							toreturn_str << "<div class='col-table-22 #{styleClass}'>"
							toreturn_str << "<a href='#{url}' #{popupAttr}>"
							toreturn_str << "<i class='#{resultActionIconsList[index]}'></i><span>#{getLabelValue(resultActionLabel)}</span>"
							toreturn_str << "</a>"
							toreturn_str << "</div>"
						end
						toreturn_str << "</div>"
						toreturn_str << "<div class='col-table-12 action-toggle-close'><a href=''><i class='icon-close'></i></a></div>"
						toreturn_str << "</div>"
						toreturn_str << "</div>"
						toreturn_str << "</td>"
					else
						
						toreturn_str << "<td class='text-center action-toggle-bg'>"
						toreturn_str << "<div class='action-toggle-open'>&nbsp;"
						toreturn_str << "</div>"
						toreturn_str << "</td>"
					end
					toreturn_str << "</tr>"
				end
				toreturn_str << "</tbody>"
				toreturn_str << "</table>"
				toreturn_str << "</div>"
				toreturn_str << "</div>" if tabLayout == "vertical"
        		toreturn_str << "</div>"  if renderSearchWrapper
				toreturn_str << "<script type='text/javascript'>new Tablesort(document.getElementById('search-table'));</script>"
			rescue Exception => e
				Rho::Log.error("Error in searchTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str	
		end


		def listSearchTag(searchName='',searchFor='',metaDataObject='', advanced=true, delete=true,resultActionLabels = '', resultActionIcons = '', resultActionHrefs ='', addButtonURL='', moreOptions='', moreOptionsURLS='', navigationLinks='', message='',renderSearchWrapper=true, tabWidthClass='',tabLayout='horizontal')
			searchData = {}
			resultActionLabelsArr = []
			resultActionIconsArr = []
			resultActionHrefsArr = []
			searchForList = (searchName.to_s == "" && searchFor.to_s != "")
			db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'app');
			#query will come from Search
			if searchForList
				searchList = Search.getSearchByType(searchFor)
				alertStage = @params['alertStage'].to_s != "" ? @params['alertStage'].to_s : searchList[0].searchName
				tabIdList = searchList.collect{ |x| x.searchName.to_s}
				tabIds = tabIdList.join(',')
				jsFunctionList = searchList.collect{ |x| "javascript:setSearchStageAndSubmit('" + x.searchName.to_s + "')"}
				jsFunctions = jsFunctionList.join(',')
			else
				alertStage = searchName
				tabIds = ""
				jsFunctions = ""
			end
			search = Search.getSearchByName(alertStage)
			if search.resultActions.to_s != ""
				resultActionsMap = search.parseLinksforResultActionstoHM
				resultActionsMap.each do |key, value|
					resultActionLabelsArr << key
					resultActionHrefsArr << value['link']
					resultActionIconsArr << value['icon']
				end
				resultActionLabels = resultActionLabelsArr.join(',')
				resultActionHrefs = resultActionHrefsArr.join(',')
				resultActionIcons = resultActionIconsArr.join(',')
			end
			sql = formSearchQuery(search)
			searchResultList = db.execute_sql(sql)
			if searchForList
				searchList = Search.getSearchByType(searchFor)
				countHash = {}
				
				searchList.each do |searchMaster|
					sql = formSearchQuery(searchMaster)
					searchResultList1 = db.execute_sql(sql)
					countHash[searchMaster.searchName] = searchResultList1.size
				end
			end
			db.close()
			@currentTab = @params['currentTab']
			@currentTab = alertStage unless @currentTab

			searchResultFieldList = search.SearchResultFieldList

			positionList = []
			metaDataCdList = []
			linkList = []
			modifyQueryList = []
			modifyFromList = []
			lookupsToBeAdded = []
			openUrlLink = ""
			linkIndex = 0
			counter = 0
			searchResultFieldList.sort{|x,y| x.position.to_i<=>y.position.to_i}.each do |searchResultField|
				next if searchResultField.metaDataCd.to_s == ""
				if searchResultField.submitId != nil
					linkRecord = searchResultFieldList.find{ |resultField| resultField.id.to_s == searchResultField.submitId.to_s }
					openUrlLink = linkRecord.link.to_s
					linkIndex = counter
				end
				metaDataCd = ""
				metaDataObject = ""
				if searchResultField.metaDataCd.to_s != "" && searchResultField.metaDataCd.to_s.include?('.')
					metaDataCd = searchResultField.metaDataCd.to_s.split('.').last
					metaDataObject = searchResultField.metaDataCd.to_s.split('.').first
				end
				uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{metaDataCd}".to_sym]
				# ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, [],"array")
				# visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
				# next unless visibility
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, [],"array")
				lookup = (ui == nil ? "" : ui.propertyValue.to_s)
				if(lookup.to_s != "")
					lookupsToBeAdded << "#{metaDataObject}_#{metaDataCd}"
				end
				positionList << searchResultField.position
				metaDataCdList << metaDataCd
				linkList << searchResultField.link
				modifyQueryList << searchResultField.modifyQuery
				modifyFromList << searchResultField.modifyFromPartition ||= "master"
				counter = counter + 1
			end
			
			columnList = metaDataCdList.join(',')
			searchResultList.each do |searchResult_entry|
				searchFilterPassed = true
				stageFilterPassed = true
				if searchResult_entry 
					
					if @params['mainSearchField'].to_s == ""
						searchResult_entry.each do|key , value|
							if @params[key].to_s != ""
								searchFilterPassed = false unless value.to_s.include?(@params[key])
							end
						end
					else
						searchFilterPassed = false
						searchResult_entry.each do|key , value|
							if value.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) != nil
								searchFilterPassed = true
							end
						end
					end
					if searchFilterPassed && stageFilterPassed
						searchData[searchResult_entry["object"]] = [] 
						metaDataCdList.each_with_index do |fieldCd, index|
							if modifyQueryList[index]
								begin
									sqlQuery = modifyQueryList[index].gsub('${value}',searchResult_entry[fieldCd])
									dbMaster = Rho::Database.new(Rho::Application.databaseFilePath(modifyFromList[index]),'app');
									valueFromDb = dbMaster.execute_sql(sqlQuery)
									dbMaster.close()
									value = valueFromDb[0].values[0]
								rescue Exception => e
									value = searchResult_entry[fieldCd]
								end
							else
								value = searchResult_entry[fieldCd]
							end
							searchData[searchResult_entry["object"]] << value
						end
					end
				end
			end
			toreturn_str = searchTag(columnList,metaDataObject,searchData,advanced,delete,resultActionLabels,resultActionIcons,resultActionHrefs,addButtonURL,moreOptions,moreOptionsURLS,searchForList,tabIds ,jsFunctions,navigationLinks,message,renderSearchWrapper,tabWidthClass,openUrlLink,tabLayout,linkIndex)
			if searchForList
				toreturn_str << "<input type='hidden' name='alertStage' id='alertStage' value='#{alertStage}'/>"
				toreturn_str << "<input type='hidden' name='countHash' id='countHash' value='#{countHash.to_json}'/>"
				toreturn_str << "<script type=\"text/javascript\">"
				toreturn_str << "if ($(\"#countHash\").val() != undefined){"
				toreturn_str << "var hashVal = $.parseJSON($(\"#countHash\").val());"
				toreturn_str << "for (var key in hashVal) {"
				toreturn_str << "	$(\"#\" + key + \"_count\").html(\"(\" + hashVal[key] + \")\");"
				toreturn_str << "	}"
				toreturn_str << "}"
				toreturn_str << "</script>"
			end
			if search.deleteLink.to_s != ""
				toreturn_str << "<script type=\"text/javascript\">"
				toreturn_str << "$('.delete-confirm-bg .search-btn-bg a#delete').click(function() {"
				toreturn_str << "	if($(\"input:checkbox[name='deleteCheck[]']:checked\").length > 0) {"
				toreturn_str << "		deleteFromSearch('#{search.deleteLink}');"
				toreturn_str << "	}"
				toreturn_str << "});"
				toreturn_str << "</script>"
			end
			if lookupsToBeAdded.size > 0
				toreturn_str << "<script type=\"text/javascript\">"
				lookupsToBeAdded.each do |metadataCode|
					toreturn_str << "function #{metadataCode}_onFocus(obj){"
					toreturn_str << "	if (obj != null){"
					toreturn_str << "		id = obj.id;"
					toreturn_str << "		lookupkey = obj.getAttribute(\"data-lookupkey\");"
					toreturn_str << "		filterCondition = {};"
					toreturn_str << "		loadLookupData(lookupkey, filterCondition, id);"
					toreturn_str << "	}"
					toreturn_str << "}"
				end
				toreturn_str << "</script>"
			end
			toreturn_str << ""
			return toreturn_str
		end

		def formatSearchResult(value , type)
			case type.downcase
			when 'string'
				return getLabelValue(value)
			when 'date'
				return getScreenDate(value)
			when 'number'
				return value.to_s
			else
				return value
			end
		end

		def formSearchQuery(search, inputCriteria = nil)
			queryString = ""
			isFirstCriterion = true
			sql = search.mainQuery.to_s.gsub('$userId' , "#{AgentReg.forUserId($userId, true).userId}")
			if !sql.downcase.start_with?('select')
				queryString << "select "
				resultSize = search.SearchResultFieldList.size
				search.SearchResultFieldList.sort{|x,y| x.position.to_i<=>y.position.to_i}.each_with_index do |searchResultFieldDO,index|
					if searchResultFieldDO.resultFieldQuery.to_s != ""
						queryString << searchResultFieldDO.resultFieldQuery.to_s
						if (index < resultSize - 1)
							queryString << " , "
						end
					end
				end
				queryString << " from "
			end
			queryString << sql #main Query

			if inputCriteria && !inputCriteria.empty?
				staticSearchCriteriaList = search.SearchCriterionList.sort_by(&:columnPosition)
				staticSearchCriteriaList.each do |criterionDO|
					if criterionDO.metaDataCd.to_s != "" && criterionDO.subQueryOffline.to_s != ""
						value = inputCriteria[criterionDO.metaDataCd].to_s
						next if value.empty?

	        			metaDataClass = criterionDO.metaDataCd.to_s.split('.')[0].to_sym
						if $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(criterionDO.metaDataCd.to_sym)
							uiMetaDataDOList = $uiMetaDataCache[metaDataClass][criterionDO.metaDataCd.to_sym]
							ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, [])
							inputType = (ui == nil ? "" : ui.propertyValue.to_s)
						end

						if inputType.to_s == "DATE"
							date = Date.parse(value)
							value = date.strftime('%d/%m/%Y')
						end

						if isFirstCriterion && !search.mainQuery.downcase.include?(" where ") && !search.mainQuery.downcase.include?("\nwhere ")
							queryString << " where "
						else
							queryString << " and " unless criterionDO.subQueryOffline.downcase.include?(" or ") || criterionDO.subQueryOffline.downcase.include?(" and ")
						end
						isFirstCriterion = false
						if criterionDO.subQueryOffline.downcase.include?("like")
							queryString << "#{criterionDO.subQueryOffline} '%#{value}%'"
						else
							queryString << "#{criterionDO.subQueryOffline} '#{value}'"
						end
						if (criterionDO.postSubQuery.to_s != "")
							queryString << "  #{criterionDO.postSubQuery.to_s}"
						end
					end
				end
			end
			
			# append the post main query
			if (search.postQuery.to_s != "")
				queryString << "  #{search.postQuery.to_s}"
			end
			puts "SQL Search Query: #{search.searchName} :#{queryString.to_s}"

			return queryString
		end
		
		# Method to generate a signature pad
		def signatureTag(field, header=nil)
			toreturn_str = ""
			begin
				if @currentTagID
					id = "#{@currentTagID}_#{field}"
				else
					id = "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}"
				end
				toreturn_str << "<div class='signature-declaration-wrapper'>"
				toreturn_str << "<h4>#{getLabelValue(header)}</h4>"
				toreturn_str << "<div class='signature-content-wrapper-left'>"
				toreturn_str << "<div style='display: none;'>"
				toreturn_str << inputTag(field)
				toreturn_str << "</div>"

				toreturn_str << "<div for='#{id}' class='signaturePad'>"
				if @currentTagObject.send(field.to_sym).to_s != ""
					displayProperty = ""
					toreturn_str << "<div class='overlay' for='#{id}' style='position:absolute; opacity:1; background-color:#CB5432;'></div>"
				else
					displayProperty = "style='display: none;'"
				end
				toreturn_str << "</div>"

				toreturn_str << "<div class='ui-grid-d clearButtonDiv' for='#{id}' #{displayProperty}>"
				toreturn_str << "<div class='ui-block-a'></div>"
				toreturn_str << "<div class='ui-block-b'></div>"
				toreturn_str << "<div class='ui-block-c'></div>"
				toreturn_str << "<div class='ui-block-d'></div>"
				toreturn_str << "<div class='ui-block-e'>"
				toreturn_str << "<button type='button' for='#{id}' class='ui-btn ui-mini clearButton'>Clear</button>"
				toreturn_str << "</div>"
				toreturn_str << "</div>"
				
				toreturn_str << "</div>"
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in signatureTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str	
		end


		# Method to generate a button
		def buttonTag(type, id, label='', href='#', adhocContent='')
			toreturn_str = ""
			begin
				case type
				when 'anchor'
					toreturn_str << "<a href='#{href}' id='#{id}' class='button-default' #{adhocContent}>#{getLabelValue(label)}</a>"
				else
					toreturn_str << "<button type='button' id='#{id}' class='button-default' #{adhocContent}>#{getLabelValue(label)}</button>"
				end
			rescue Exception => e
				Rho::Log.error("Error in buttonTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
		end


		#Function to setup a filter to map fields based on FieldTargetValueMap
	    def setupFilterUsingFieldTargetValueMap(mappingKey, filterable=false, object=nil)
	    	mappingHash = {}
	    	tableResult = FieldTargetValueMap.find(
	    		:all,
	    		:conditions => {
	    			{:name=>'mappingKey'} => mappingKey
	    		}
    		)
	    	
	    	if tableResult.size > 0
	    		if filterable
	    			lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>tableResult[0].targetLookupCd}) if tableResult[0]
	    			lookupHash = {}
	    			lookupsArray.each do |lookup|
	    				if getLabelValue(lookup.desc).to_s != ""
	    					lookupHash[lookup.cd] = getLabelValue(lookup.desc)
	    				elsif getLabelValue(lookup.cd).to_s != ""
	    					lookupHash[lookup.cd] = getLabelValue(lookup.cd)
	    				elsif lookup.desc.to_s != ""
	    					lookupHash[lookup.cd] = lookup.desc
	    				else
	    					lookupHash[lookup.cd] = lookup.cd
	    				end
	    			end
	    		end
	    		tableResult.each do |record|
	    			mappingHash['drivingField'] = record.drivingField
	    			mappingHash['targetField'] = record.targetField
	    			if filterable
	    				mappingHash['targetMapList'] = {} if !mappingHash['targetMapList'].is_a?(Hash)
	    				mappingHash['targetMapList'][record.drivingValue] = {} if !mappingHash['targetMapList'][record.drivingValue].is_a?(Hash)
	    				mappingHash['targetMapList'][record.drivingValue][record.targetValue] = lookupHash[record.targetValue] if lookupHash.has_key?(record.targetValue)
	    			else
	    				mappingHash['targetMapList'] = {} if !mappingHash['targetMapList'].is_a?(Hash)
	    				mappingHash['targetMapList'][record.drivingValue] = record.targetValue
	    			end
	    		end
	    		require 'json'
	    		toreturn_str = ""
	    		toreturn_str << "<script type='text/javascript'>"
    			toreturn_str << "$(document).ready(function(){"
	    		toreturn_str << "fieldTargetValueMapFilterSetup('" << mappingHash.to_json << "', '" << filterable.to_s << "', '" << object << "');"
				toreturn_str << "});"
				toreturn_str << "</script>"
	    		return toreturn_str
	    	end
	    end

	    
	    # method to get masked value
		def getMaskedValue(object,field)
			$contextMasterEvalHash = {} if $contextMasterEvalHash== nil || $contextMasterEvalHash.class.to_s != "Hash"
			$parentChildGuidMapping = {} if $parentChildGuidMapping== nil || $parentChildGuidMapping.class.to_s != "Hash"
	    	value = ""
	    	begin
	    		if object && field.to_s != ""
			    	doMask = false
		            mask = ""
		            value = object.send(field.to_sym)
		            value = value.to_f if value.class.to_s == "BigDecimal"
		            value = value.to_s
		            value.gsub!("'","&apos;")

					if $rhoconfig[:contextBasedMetadata]
			            classToFind = object.class.name + "DO"
						if $contextMasterCache.has_key?(classToFind.to_sym)
							contextMasterList = $contextMasterCache[classToFind.to_sym]
							contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,object)
						else
							contextMasterGeneratedArray = []
						end
					else
			            if ENTITYCONTEXT_SET_DO_MAP.has_key?(object.class.name.to_sym)
							contextSet = Object.const_get(ENTITYCONTEXT_SET_DO_MAP[object.class.name.to_sym])
						else
							contextSet = Object.const_get(:GenericSet)
						end
						contextSet.setObject(object)
						currentApplicableContexts = contextSet::ValidationContexts
					end
		            if $uiMetaDataCache.has_key?("#{object.class.name}DO.#{field}".to_sym)
		                uiMetaDataDOList = $uiMetaDataCache["#{object.class.name}DO.#{field}".to_sym]
						if $rhoconfig[:contextBasedMetadata]
		               		ui = MobiSys::UIMetaData.getUiMetadataPropDO("MASK", uiMetaDataDOList, contextMasterGeneratedArray)
		               	else
			                ui = MobiSys::UIMetaData.getUiMetadataPropDO("MASK", uiMetaDataDOList, currentApplicableContexts)
			            end
		                mask = (ui == nil ? "" : ui.propertyValue.to_s)
		                doMask = true if ui
		            end
		            entityTypeDO = nil
		            dataElementDO = DataElement.find(
		                :first,
		                :conditions => {
		                    {:name => 'attributeCd'} => field
		                },
		                :select => ['attributeCd','attributeTypeCd','entityFieldTypeCd','globalFl']
		            )
		            if dataElementDO
		                entityTypeDO = EntityType.loadObject(
		                    :first,
		                    :conditions => {
		                        {:name => 'entityFieldTypeCd'} => dataElementDO.entityFieldTypeCd
		                    }
		                )
		            end
		            unless entityTypeDO
		                Rho::Log.error("No DataElementDO created for #{field}", LOGCATEGORY)
		            else
		                entity = entityTypeDO.entityFieldTypeCd.to_s
		                datatype = entityTypeDO.dataTypeCd.to_s
		                entityTypeDO.EntityPropertyList.each do |entityProperty|
		                    if entityProperty.propertyCd.to_s == "MASK" && !doMask
		                        doMask = true
		                        mask = entityProperty.propertyValue.to_s
		                    end
		                end
		            end
		            if doMask
		                if $offlineApplicationMask == nil
		                    $offlineApplicationMask = $rhoconfig[:number_format_pattern].to_s
		                end
		                mask = $offlineApplicationMask if mask.to_s == "" && $offlineApplicationMask
		                value = maskDecimal(value,mask) if value.to_s != ""
		            end
		        end
	        rescue Exception => e
				Rho::Log.error("Error in getMaskedValue--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
            return value
	    end


	    # method to get a pop up
	    def popupTagStart(id, closeRequired=true, header="")
	    	toreturn_str = ""
			begin
				toreturn_str << "<div id='#{id}' data-role='popup' data-theme='a' class='ui-corner-all popup-wrapper error-popup' >"
				if header != ''
					toreturn_str << "<div class='labelHeader\"><h3>" + getLabelValue(header)  + "</h3></div>"
				end
				if closeRequired
					toreturn_str << " <div class='popup-close-cust' ><a href='#' data-rel='back' class='icon-close'></a></div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in popupTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
	    end

	    # method to get a pop up
	    def popupTagEnd()
	    	toreturn_str = ""
			begin
				toreturn_str << "</div>"
			rescue Exception => e
				Rho::Log.error("Error in popupTagEnd--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
	    end

	   	# method to get a signature pop up
		#showButton = true, to show capture button from this tag, showButton = false, to show capture button from output html.
		#placeOfSignatureField, pass field name of place of signature if applicable.
	    def signaturePopupTag(field, popupId, closeRequired=true, linkLabel="", header="", showButton=true, placeOfSignatureField=nil)
	    	toreturn_str = ""
			begin
				if @currentTagID
					id = "#{@currentTagID}_#{field}"
				else
					id = "#{$objectMapping[@currentTagObject.object.to_s]}_#{field}"
				end
				if showButton
					toreturn_str << "<a href='##{popupId}' data-guid='#{popupId}' data-rel='popup' class='button-default ui-btn ui-corner-all ui-shadow ui-btn-inline' data-transition='pop'>"
					toreturn_str << getLabelValue(linkLabel)
					toreturn_str << "</a>"
				end
				toreturn_str << "<div id='#{popupId}' data-role='popup' data-theme='a' class='signaturePopup ui-corner-all popup-wrapper' >"
				if header != ''
					toreturn_str << "<div class='heading'>#{getLabelValue(header)}</div>"
				end
				if closeRequired
					toreturn_str << " <div class='popup-close-cust' ><a href='#' data-rel='back' class='icon-close'></a></div>"
				end
				toreturn_str << " <div role='main' class='ui-content'>"

				toreturn_str << "<div class='signaturePopup-declaration-wrapper'>"
				toreturn_str << "<div class=''>"
				toreturn_str << "<div style='display: none;'>"
				toreturn_str << inputTag(field)
				toreturn_str << "</div>"

				toreturn_str << "<div for='#{id}' class='signaturePad'>"
				if @currentTagObject.send(field.to_sym).to_s != ""
					displayProperty = ""
					toreturn_str << "<div class='overlay' for='#{id}' style='position:absolute; opacity:1; background-color:#CB5432;'></div>"
				else
					displayProperty = "style='display: none;'"
				end
				toreturn_str << "</div>"
			
				toreturn_str << "</div>"
				if placeOfSignatureField
					toreturn_str <<	"<div class='project-data-full' style='float: left'>"
					toreturn_str << "<div class='row-details'>"
	                toreturn_str << labelTag(placeOfSignatureField)
	                toreturn_str << "<p class='col-right'>"
	                toreturn_str << inputTag(placeOfSignatureField)
	                toreturn_str << errorTag(placeOfSignatureField)
					toreturn_str << "</p>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
				toreturn_str << "</div>"
				toreturn_str << "</div>"
				toreturn_str << "<div class='summary-btn-bg'>"
				toreturn_str << "<a for='#{id}' class='ui-btn ui-mini okSignatureButton' data-id='#{popupId}' data-rel='back'>"
				toreturn_str << getLabelValue('ok')
				toreturn_str << "</a>"
	
				toreturn_str << "<a for='#{id}' class='ui-btn ui-mini clearButton'>#{getLabelValue('Clear')}</a>"
				toreturn_str << "</div>"
				toreturn_str << "</div>"
				
			rescue Exception => e
				Rho::Log.error("Error in popupTagStart--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str
	    end


	    # Method to add ocr button with functionality
	    def ocrButtonTag
	    	controllerName = @request['model']
	    	id = @currentTagID
	    	toreturn_str = ""
	    	begin
				if $rhoconfig[:ocr_enabled].value == "YES"
					toreturn_str << "<div class='labelHeader'>"
					toreturn_str << "<h3>#{getLabelValue('ocrPopulate')}</h3>"
					toreturn_str << "</div>"

					toreturn_str << "<div id='#{id}_ocrScanButtonContainer' class='ocrScanButtonContainer'>"
					toreturn_str << "<a href='javascript:takePictureOCR(false, \"#{controllerName}\", \"#{id}\");' id='#{id}_ocrScanButton' data-role='button' class='button-default ocrScanButton'>#{getLabelValue('fromCamera')} <i class=\"icon-snapshot\"></i></a>"
					toreturn_str << "<a href='javascript:takePictureOCR(true, \"#{controllerName}\", \"#{id}\");' id='#{id}_ocrChooseButton' data-role='button' class='button-default ocrChooseButton'>#{getLabelValue('fromGallery')} <i class=\"icon-images\"></i></a>"
					toreturn_str << "</div>"
				end
			rescue Exception => e
				Rho::Log.error("Error in ocrButtonTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			
			return toreturn_str
	    end


	    def multiSelectsearchTag(columnIds, metaDataObject, resultList, advanced=true, delete=true, resultActionLabels='', resultActionIcons='', resultActionHrefs='', addButtonURL='',generateIllustrationButton='', moreOptions='', moreOptionsURLS='', areTabsRequired=false, tabLabels='', tabLinks='', navigationLinks='', message='',renderSearchWrapper=true, tabWidthClass='',openUrl='')
			toreturn_str = ""
			width = ""
			begin
				columnIdList = columnIds.split(",")
				action = false
				if resultActionLabels != '' && resultActionIcons != '' && resultActionHrefs != ''
					resultActionLabelsList = resultActionLabels.split(",")
					resultActionIconsList = resultActionIcons.split(",")
					resultActionHrefsList = resultActionHrefs.split(",")
					action = true
				end

				moreOptionsList = moreOptions.split(",")
				moreOptionsURLSList = moreOptionsURLS.split(",")

				MobiSys::Validation.initializeValidationHash unless $validationHash
				MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
				MobiSys::ContextMasterData.initializeContextMasterHash unless $contextMasterCache
				toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.min.js'></script>"
    			toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.number.js'></script>"
    			toreturn_str << "<script src='/public/jazz/libraries/tablesort/tablesort.date.js'></script>"

				toreturn_str << "<div class='main-content-wrapper' id='search-wrapper'>" if renderSearchWrapper
				if areTabsRequired
					tabWidthClass = 'col-33' if tabWidthClass == ""
					toreturn_str << "<input type='hidden' id='currentTab' name='currentTab' value=#{@currentTab}>"
					toreturn_str << "<div class='search-top-bg search-top-tabs'>"
					tablabelsList = tabLabels.split(",")
					tabLinksList = tabLinks.split(",")
					tablabelsList.each_with_index do |label,index|
						toreturn_str << "<a href=\"#{tabLinksList[index]}\">"
						activeclass = ""
						activeclass = "active" if label.downcase == @currentTab.downcase
						toreturn_str << "<div class='#{tabWidthClass} tab-cust #{activeclass}' id='#{label}'>"
						toreturn_str << "#{getLabelValue(label)}"
						toreturn_str << "</div></a>"
					end
					toreturn_str << "</div>"
					if navigationLinks != ''
						toreturn_str << "<div class='search-top-bg search-top-tabs'>"
						navigationLinksList = navigationLinks.split(",")
						toreturn_str << "<a href=\"#{navigationLinksList.first}\">"
						toreturn_str << "<div class='ui-link ui-btn ui-btn-left ui-btn-inline navbutton-left' data-role='button' data-corners='false' data-inline='true' role='button'>"
						toreturn_str << "#{getLabelValue('PREVIOUS')}</div></a>"
						toreturn_str << "<div id='leadActivityMessage'>#{message}</div>"
						toreturn_str << "<a href=\"#{navigationLinksList.last}\">"
						toreturn_str << "<div class='ui-link ui-btn ui-btn-right ui-btn-inline navbutton-right' data-role='button' data-corners='false' data-inline='true' role='button'>"
						toreturn_str << "#{getLabelValue('NEXT')}</div></a>"
						toreturn_str << "</div>"
					end
				end

				toreturn_str << "<div class='search-top-bg'>"

				toreturn_str << "<div class='ui-field-contain'>"
				toreturn_str << "<input type='search' name='mainSearchField' id='search' value= '#{@mainSearchField}' placeholder='Search' class='search-bar'>"
				toreturn_str << "</div>"
				toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' id='search-go' data-role='button' data-corners='false' data-inline='true'>#{getLabelValue('GO')}</a>"
					toreturn_str << "</div>"
					toreturn_str << "<div class='search-mobile-bg'>" if $rhoconfig[:application_view_mode] == "mobile"
				# if advanced
					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a data-role='button' id='showIllustrationPanel'href='#{addButtonURL}'style='min-width:40px;' data-inline='true' data-corners='false'>
									#{getLabelValue('generate')}&nbsp;#{getLabelValue('SALESILLUSTRATION')}</a>" 
					toreturn_str << "</div>"

				# end
					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a data-role='button' id='showPdfPanel'href='#{addButtonURL}'style='min-width:40px;'data-inline='true' data-corners='false'>
									#{getLabelValue('generate')}&nbsp;#{getLabelValue('output pdf')}</a>" 
					toreturn_str << "</div>"

					
		 			toreturn_str << "<div class='search-btn-bg'>"						
		 		    toreturn_str << "<a data-role='button' id='generateIllustrationButton' href='#' style='min-width:100px;'data-inline='true' data-corners='false'>
                                         #{getLabelValue('Generate Illustration')}</a>"
                    toreturn_str << "</div>"                     
                    toreturn_str << "<div class='search-btn-bg'>" 
                    toreturn_str << "<a data-role='button' id='generatePdfButton' href='#' style='min-width:100px;'data-inline='true' data-corners='false'>
                                      #{getLabelValue('Generate PDF')}</a>"
                    toreturn_str << "</div>"                   
                    toreturn_str << "<div class='search-btn-bg'>"                  
                    toreturn_str << "<a data-role='button' id='cancelButton' href='#'style='min-width:100px;'data-inline='true' data-corners='false'>
                    				#{getLabelValue('CANCEL')}</a>"
                    toreturn_str << "</div>"

				if resultList.size > 0 && delete
					toreturn_str << "<div class='delete-illustration search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' data-corners='false' data-inline='true'>#{getLabelValue('deleteRec')} #{getLabelValue('')}</a>"
					toreturn_str << "</div>"

					toreturn_str << "<div class='delete-confirm-bg'>"
					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='delete' data-corners='false' data-inline='true'>#{getLabelValue('delete')}</a>"
					toreturn_str << "</div>"
						toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='selectAll' data-corners='false' data-inline='true'>#{getLabelValue('selectAll')}</a>"
					toreturn_str << "</div>"

					toreturn_str << "<div class='search-btn-bg'>"
					toreturn_str << "<a href='#' data-role='button' id='cancel' data-corners='false' data-inline='true'>#{getLabelValue('CANCEL')}</a>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end
				toreturn_str << "</div>" if $rhoconfig[:application_view_mode] == "mobile"
				toreturn_str << "<div class='btn-mobile-bg'>"
				if moreOptionsList.size > 0
					toreturn_str << "<div class='add-illustration-bg'>"
					toreturn_str << "</a>"
					toreturn_str << "<div class='add-illustration-details'>"
					toreturn_str << "<ul>"
					moreOptionsList.each_with_index do |option,index|
					end
					toreturn_str << "</ul>"
					toreturn_str << "</div>"
					toreturn_str << "</div>"
				end

				toreturn_str << "</div>"
				toreturn_str << "</div>"
				
				toreturn_str << "<div class='table-section'>"
				toreturn_str << "<table data-role='table' id='search-table' class='ui-responsive search-header-fixed'>"
				toreturn_str << "<thead>"
				if advanced
					toreturn_str << "<tr class='advance-search-field'>"
					columnIdList.each do |column|
						if $uiMetaDataCache.has_key?("#{metaDataObject}.#{column}".to_sym) && $rhoconfig[:application_view_mode] != 'mobile'
							uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{column}".to_sym]
							ui = MobiSys::UIMetaData.getUiMetadataPropDO("WIDTH", uiMetaDataDOList, @currentApplicableContexts)
							width = (ui == nil ? "" : ui.propertyValue.to_s)
						end
						toreturn_str << "<th style='width:#{width}%'>"
						toreturn_str << inputTag(column,nil,nil,nil,nil,metaDataObject)
						toreturn_str << "</th>"
					end
					toreturn_str << "<th>"
					toreturn_str << "<div class='advance-search-btn1'>"
					toreturn_str << "<a class='close-advance-search-field' href='#' data-role='button' data-corners='false' data-inline='true'>X</a>"
					toreturn_str << "</div>"
					toreturn_str << "</th>"
					toreturn_str << "</tr>"
				end
				toreturn_str << "<tr>"
				columnIdList.each do |column|
					if $uiMetaDataCache.has_key?("#{metaDataObject}.#{column}".to_sym) && $rhoconfig[:application_view_mode] != 'mobile'
						uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{column}".to_sym]
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("WIDTH", uiMetaDataDOList, @currentApplicableContexts)
						width = (ui == nil ? "" : ui.propertyValue.to_s)
					end
					toreturn_str << "<th style='width:#{width}%'>"
					toreturn_str << labelTag(column,metaDataObject, nil ,true)
					toreturn_str << "</th>"
				end
				toreturn_str << "<th class='text-center no-sort' data-sort-method='none'>Action</th>" if action
				toreturn_str << "</tr>"
				toreturn_str << "</thead>"

				toreturn_str << "<tbody id='searchTable'>"
				resultList.each do |object,resultObject|
					toreturn_str << "<tr>"
					resultObject.each_with_index do |field,index|
						if index == 0 && openUrl.to_s != ""
							objectUrl = openUrl.to_s.gsub("#object",object.to_s)
							toreturn_str << "<td><a href='#{objectUrl}' rel='external' class= 'ui-link'><span class='field-value'>#{field}</span></a></td>" 
						else	
							toreturn_str << "<td><span class='field-value'>#{field}</span></td>"
						end
					end
					if action
						toreturn_str << "<td class='text-center action-toggle-bg'>"
						toreturn_str << "<div class='action-toggle-open'>"
						toreturn_str << "<i class='icon-action'></i>"
						toreturn_str << "</div>"

						toreturn_str << "<div class='illustration-checkbox'>"
						toreturn_str << "<label for='#{object}'>"
						toreturn_str << "<input type='checkbox' id='#{object}' name='illustrationCheck[]' value='#{object}'>"
						toreturn_str << "</label>"
						toreturn_str << "</div>"

						toreturn_str << "<div class='action-status-show'>"
						toreturn_str << "<div class='action-status-show-group'>"
						resultActionLabelsList.each_with_index do |resultActionLabel,index|
							if index > 0 
								if (index+1) %4 == 0
									styleClass = "sllrm-color"
								elsif (index+1)%4 == 3
									styleClass = "fna-color"
								elsif (index+1)%4 == 2
									styleClass = "status-color"
								elsif (index+1)%4 == 1
									styleClass = ""
								end
							end
							url = resultActionHrefsList[index].to_s.gsub("#object",object.to_s)
							if url.include?("#")
								popupAttr = "data-rel='popup' data-position-to='window' data-transition='pop'"
							else
								popupAttr = "rel='external'"
							end
							toreturn_str << "<div class='col-table-22 #{styleClass}'>"
							toreturn_str << "<a href='#{url}' #{popupAttr}>"
							toreturn_str << "<i class='#{resultActionIconsList[index]}'></i><span>#{getLabelValue(resultActionLabel)}</span>"
							toreturn_str << "</a>"
							toreturn_str << "</div>"
						end
						toreturn_str << "</div>"
						toreturn_str << "<div class='col-table-12 action-toggle-close'><a href=''><i class='icon-close'></i></a></div>"
						toreturn_str << "</div>"
						toreturn_str << "</div>"
						toreturn_str << "</td>"
					end
					toreturn_str << "</tr>"
				end
				toreturn_str << "</tbody>"
				toreturn_str << "</table>"
				toreturn_str << "</div>"
        		toreturn_str << "</div>"  if renderSearchWrapper
        		toreturn_str << "<script type='text/javascript'>new Tablesort(document.getElementById('search-table'));</script>"
			rescue Exception => e
				Rho::Log.error("Error in searchTag--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			return toreturn_str	
		end

	end
end

begin
	require 'CommonModules/mobisysuihelper_jazz_company'
rescue LoadError => e
	puts 'mobisysuihelper_jazz_company not included'
end
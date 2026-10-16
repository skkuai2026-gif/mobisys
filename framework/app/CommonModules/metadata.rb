require 'time'
if Rho::System.platform != "APPLE"
	require "#{Rho::Application.userFolder}entity_context"
else
	fileContents = File.read("#{Rho::Application.userFolder}entity_context.rb")
	eval(fileContents)
end


module MobiSys
	class MetaData
		LOGCATEGORY = "Metadata"

		#Method to create a global MetadataHash based on Metadata Master
	    def self.initializeMetadataHash
	    	metadataMaster = MetadataMaster.find(
				:all,
				:select => ['fieldTypeCd','metaDataCd','objectName','attributeCd','runtimeDrivingMTDT']
			)

			$metadataMasterHash = Hash.new

	    	metadataMaster.each do |metadataRecord|
	    		next if metadataRecord.attributeCd == nil
	    		endIndex = metadataRecord.objectName.index('.') ? metadataRecord.objectName.index('.')-1:-1
				classKey = metadataRecord.objectName[0..endIndex]
	    		attributeKey = "#{classKey}.#{metadataRecord.attributeCd}".to_sym
				# $metadataMasterHash[attributeKey] = Array.new if !$metadataMasterHash[attributeKey].is_a?(Array)
    			$metadataMasterHash[attributeKey] = metadataRecord

    			# $metadataMasterHash[classKey][attributeKey] = Array.new if !$metadataMasterHash[classKey][attributeKey].is_a?(Array)
				# $metadataMasterHash[classKey][attributeKey].push(metadataRecord)
	    	end
	    	puts "metadataMasterHash created with size #{$metadataMasterHash.size}"
	    end

		def self.evalContext(fieldValue, contextSetDataType, validationContexts)
			eliminatedTabIds = []
			case validationContexts.class.to_s
			when "Array"
				contextSetDataType = "array"
				#Adding Current Active tab context to the context array list (This is passed from UI and used to hide and show fields based on tab for the same object.)
				validationContexts.push($currentActiveTab.to_sym) if $currentActiveTab && !validationContexts.include?($currentActiveTab.to_sym)
				# Hardcoding OFFLINE context
				validationContexts.push(:OFFLINE) if !validationContexts.include?(:OFFLINE)
			when "Class"
				contextSetDataType = "class"
			end
  			tabIdArray = fieldValue.tabId.to_s.split(",")
 			validContext = fieldValue.contextCd.to_s.split(",")
 			performTabIdContextMapping = tabIdArray.size == validContext.size
			validContext.delete_if.with_index do |x,index|
 				result = false
 				if x.index("&")==nil
					if x.index("!") != nil
						inverse = true
						x.gsub!("!","")
					end
 					if contextSetDataType == "array"
 						result = !validationContexts.include?(x.to_sym)
 					else
	 					if validationContexts.respond_to?(x.to_sym)
	 						result = !validationContexts.send(x.to_sym)
	 					else
	 						result = true
	 					end
	 				end
					result = !result if inverse
 				else
 					result = x.split("&").collect do |y|
						if y.index("!") != nil
							inverse = true
							y.gsub!("!","")
						end
						singleContextResult = true
	 					if contextSetDataType == "array"
 							singleContextResult = validationContexts.include?(y.to_sym)
	 					else
	 						if validationContexts.respond_to?(y.to_sym)
	 							singleContextResult = validationContexts.send(y.to_sym)
	 						else
	 							singleContextResult = false
	 						end
	 					end
	 					singleContextResult = !singleContextResult if inverse
	 					singleContextResult
 					end != x.split("&").collect{ true }
 				end
 				if performTabIdContextMapping && result
 					eliminatedTabIds.push(index)
 				end
 				result
 			end
 			if performTabIdContextMapping
	 			tabIdArray.delete_if.with_index { |_, index| eliminatedTabIds.include? index }
	 			fieldValue.evaluatedTabId = tabIdArray.join(",")
	 		end

	 		return validContext
		end
	end



	class Validation
		LOGCATEGORY = "ValidationMetadata"

		#Method to convert hash to object
		def self.from_hash(className, hash)
			objClass = Object.const_get(className)
			obj = objClass.new
			hash.each do |key,value|
				next if value == nil
				next if key.to_s=='source_id'
				next if key.to_s=='class'
				next if value.class.name.to_s == 'Array'
				begin
					exp = 'obj.'+key.to_s+"='"+value.to_s.gsub("'","\\\\'")+"'"
					eval(exp)
				rescue StandardError => boom
					puts boom
				end
			end
			return obj
		end


		#Method to create a global validationHash based on Validation Metadata
	    def self.initializeValidationHash
	    	validationMetadata = ValidationMetadata.find(
				:all,
				:select => ['contextCd','exceptionCd','validationCd','validationParam','metaDataCd','propertyFields','disabled','tabId']
			)

			$validationHash = Hash.new
			$validationMtdtList = Hash.new

	    	validationMetadata.each do |validationRecord|
	    		endIndex = validationRecord.metaDataCd.index('.') ? validationRecord.metaDataCd.index('.')-1:-1
				classKey = validationRecord.metaDataCd[0..endIndex].to_sym
				$validationMtdtList[classKey] = Array.new if !$validationMtdtList[classKey].is_a?(Array)
				fieldCd = validationRecord.metaDataCd.to_s.split('.').size > 0 ? validationRecord.metaDataCd.to_s.split('.')[1] : ""
				$validationMtdtList[classKey] << fieldCd if !$validationMtdtList[classKey].include?(fieldCd)
				$validationHash[classKey] = Hash.new if !$validationHash[classKey].is_a?(Hash)
	    		contextKey = validationRecord.validationCd.to_sym
    			$validationHash[classKey][contextKey] = Hash.new if !$validationHash[classKey][contextKey].is_a?(Hash)

				if validationRecord.contextCd.to_s == "Global" || validationRecord.contextCd.to_s == ""
					contextScope = :GLOBAL
				else
					contextScope = :NONGLOBAL
				end

				$validationHash[classKey][contextKey][contextScope] = Hash.new if !$validationHash[classKey][contextKey][contextScope].is_a?(Hash)

				$validationHash[classKey][contextKey][contextScope][validationRecord.metaDataCd] = Array.new if !$validationHash[classKey][contextKey][contextScope][validationRecord.metaDataCd].is_a?(Array)
				$validationHash[classKey][contextKey][contextScope][validationRecord.metaDataCd].push(validationRecord)
	    	end
	    end


	    #Method to get all the mandatory fields for a specific class
	    def self.getMandatoryFields(className, validationContexts)
	    	if $validationHash.has_key?(className.to_sym)
		  		mandatoryFields = Array.new
		 		validateClassHash = $validationHash[className.to_sym]
		 		case validationContexts.class.to_s
				when "Array"
					contextSetDataType = "array"
				when "Class"
					contextSetDataType = "class"
				end
		 		#Create hash to be passed to mandatory validation for Global context
		 		if validateClassHash.has_key?(:MINOCCURS) && validateClassHash[:MINOCCURS].has_key?(:GLOBAL)
				   	validateClassHash[:MINOCCURS][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				mandatoryFields.push(fieldKey.split(".").last) if fieldValue.validationParam == "1" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
				end

				#Create hash to be passed to mandatory validation for NONGLOBAL context
				if validateClassHash.has_key?(:MINOCCURS) && validateClassHash[:MINOCCURS].has_key?(:NONGLOBAL)
				  	validateClassHash[:MINOCCURS][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
					  		if fieldValue.disabled.to_s != "YES"
						 		if fieldValue.contextCd.index(",")==nil
						 			contextArray = [fieldValue.contextCd]
						 		else
						 			contextArray = fieldValue.contextCd.split(",")
						 		end

						 		validContext = fieldValue.contextCd.split(",").delete_if do |x|
					 				if x.index("&")==nil
					 					if contextSetDataType == "array"
					 						!validationContexts.include?(x.to_sym)
					 					else
						 					if validationContexts.respond_to?(x.to_sym)
						 						!validationContexts.send(x.to_sym)
						 					else
						 						true
						 					end
						 				end
					 				else
					 					x.split("&").collect do |y|
					 						if contextSetDataType == "array"
					 							validationContexts.include?(y.to_sym)
						 					else
						 						if validationContexts.respond_to?(y.to_sym)
						 							validationContexts.send(y.to_sym)
						 						else
						 							false
						 						end
						 					end
					 					end != x.split("&").collect{ true }
					 				end
					 			end
					 			unless validContext.empty?
					 				if fieldValue.validationParam == "1" && !mandatoryFields.include?(fieldKey)
					 					mandatoryFields.push(fieldKey.split(".").last)
					 				elsif fieldValue.validationParam == "0" && mandatoryFields.include?(fieldKey)
					 					mandatoryFields.delete(fieldKey.split(".").last)
					 				end
					 			end
					 		end
					 	end
					end
				end
				mandatoryFields = mandatoryFields.uniq
				
				return mandatoryFields
			end
	    end


	    #Method to perform mandatory field validation
		def self.mandatoryValidation(object, field, errors, parentObj=nil)
			fieldName = field.metaDataCd.split('.').last
			fieldLabel = fieldName
			tabId = field.tabId
			if field.evaluatedTabId.to_s != ""
				tabId = field.evaluatedTabId
			end
			
			metaDataClass = field.metaDataCd.to_s.split('.')[0].to_sym
			if $uiMetaDataCache != nil && $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(field.metaDataCd.to_sym) && $globalContextObjectMap.has_key?(object[:guid])
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", $uiMetaDataCache[metaDataClass][field.metaDataCd.to_sym], $globalContextObjectMap[object[:guid]], "array")
				fieldLabel = ui.propertyValue.to_s if ui
			end

			if field.exceptionCd.to_s != ""
				exceptionCd = field.exceptionCd
			else
				exceptionCd = "ERR_MANDATORY"
			end

			exceptionMessage = replacePropertyFields(field, fieldName, exceptionCd, object)
			placeHolderValues = replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj)

			if fieldName.include?("List")
				fieldKey = fieldName[0..0].upcase + fieldName[1..-1]
				if !object.has_key?("list" + fieldKey) || object["list" + fieldKey].empty?
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel)])
					else
						MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), placeHolderValues])
					end
				end
			else
				if !object.has_key?(fieldName.to_sym) || object[fieldName.to_sym].to_s.strip =="" 
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel)])
					else
						MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), placeHolderValues])
					end
				end
			end
		end


		#Method to validate field as per Regex expression
		def self.formatValidation(object, field, errors, parentObj=nil)
			fieldName = field.metaDataCd.split('.').last
			fieldLabel = fieldName
			tabId = field.tabId
			if field.evaluatedTabId.to_s != ""
				tabId = field.evaluatedTabId
			end
			
			metaDataClass = field.metaDataCd.to_s.split('.')[0].to_sym
			if $uiMetaDataCache != nil && $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(field.metaDataCd.to_sym) && $globalContextObjectMap.has_key?(object[:guid])
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", $uiMetaDataCache[metaDataClass][field.metaDataCd.to_sym], $globalContextObjectMap[object[:guid]], "array")
				fieldLabel = ui.propertyValue.to_s if ui
			end

			if field.exceptionCd.to_s != ""
				exceptionCd = field.exceptionCd
			else
				exceptionCd = "ERR_FORMAT"
			end
			
			exceptionMessage = replacePropertyFields(field, fieldName, exceptionCd, object)
			placeHolderValues = replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj)

			regex = /#{field.validationParam}/
			if object.has_key?(fieldName.to_sym)
				fieldValue = object[fieldName.to_sym].to_s.force_encoding(Encoding::UTF_8)
				if (/#{regex.source}/.match(fieldValue)).to_s != fieldValue.to_s
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel)])
					else
						MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), field.validationParam, placeHolderValues])
					end
				end
			end
		end

		#Method to validate field as per blacklist expression
		def self.isBlacklistValid(object, field, errors, parentObj=nil)
			fieldName = field.metaDataCd.split('.').last
			fieldLabel = fieldName
			tabId = field.tabId
			if field.evaluatedTabId.to_s != ""
				tabId = field.evaluatedTabId
			end
			
			metaDataClass = field.metaDataCd.to_s.split('.')[0].to_sym
			if $uiMetaDataCache != nil && $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(field.metaDataCd.to_sym) && $globalContextObjectMap.has_key?(object[:guid])
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", $uiMetaDataCache[metaDataClass][field.metaDataCd.to_sym], $globalContextObjectMap[object[:guid]], "array")
				fieldLabel = ui.propertyValue.to_s if ui
			end

			if field.exceptionCd.to_s != ""
				exceptionCd = field.exceptionCd
			else
				exceptionCd = "ERR_BLACKLISTCHAR"
			end
			
			exceptionMessage = replacePropertyFields(field, fieldName, exceptionCd, object)
			placeHolderValues = replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj)
			regex = Regexp.union((field.validationParam || "").split(","))
			if object.has_key?(fieldName.to_sym)
				fieldValue = object[fieldName.to_sym].to_s.force_encoding(Encoding::UTF_8)
				if regex.match(fieldValue)
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel)])
					else
						MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), regex.match(fieldValue), field.validationParam, placeHolderValues])
					end
				end
			end
		end

		#Method to validate field as per Regex expression
		def self.greaterLesserValidation(object, field, errors, parentObj=nil)
			fieldName = field.metaDataCd.split('.').last
			className = field.metaDataCd.split('D').first
			fieldLabel = fieldName
			tabId = field.tabId
			if field.evaluatedTabId.to_s != ""
				tabId = field.evaluatedTabId
			end
			
			metaDataClass = field.metaDataCd.to_s.split('.')[0].to_sym
			if $uiMetaDataCache != nil && $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(field.metaDataCd.to_sym) && $globalContextObjectMap.has_key?(object[:guid])
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", $uiMetaDataCache[metaDataClass][field.metaDataCd.to_sym], $globalContextObjectMap[object[:guid]], "array")
				fieldLabel = ui.propertyValue.to_s if ui
			end
			
			if field.exceptionCd.to_s != ""
				exceptionCd = field.exceptionCd
			elsif field.validationCd.to_s == "GREATER"
				exceptionCd = "ERR_COMPAREVAL"
			else
				exceptionCd = "ERR_COMPAREVALLESS"
			end
			
			exceptionMessage = replacePropertyFields(field, fieldName, exceptionCd, object)
			placeHolderValues = replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj)
			# if Rho::RhoConfig.sources[className]["schema"]["property"].has_key?(fieldName)
			# 	dataType = Rho::RhoConfig.sources[className]["schema"]["property"][fieldName][0].to_s
			# end

            if object.has_key?(fieldName.to_sym) && object[fieldName.to_sym]!=""
				if field.validationCd.to_s == "LESSEREQUALS"
					# if dataType == "date"
						begin
							srcDate = Time.parse(object[fieldName.to_sym].to_s)
							if field.validationParam.to_s == "TODAY"
								targetDate = Time.parse(Time.new.strftime("%F 00:00:00 %z"))
							elsif object.has_key?(field.validationParam.to_sym)
								targetDate = Time.parse(object[field.validationParam.to_sym])
							else
								targetDate = Time.parse(field.validationParam.to_s)
							end
							if srcDate != nil && targetDate != nil && srcDate >= targetDate
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s)])
								else
									MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s), placeHolderValues])
								end
							end
						rescue Exception => e
							puts "Invalid date validation: #{e}"
						end
					# elsif dataType != "string"
					# 	src = object[fieldName.to_sym].to_f
					# 	if object.has_key?(field.validationParam.to_sym)
					# 		target = object[field.validationParam.to_sym].to_f
					# 	else
					# 		target = field.validationParam.to_f
					# 	end
					# 	if src > target
					# 		MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), field.validationParam.to_s])
					# 	end
					# end
				elsif field.validationCd.to_s == "LESSER"
					# if dataType == "date"
						begin
							srcDate = Time.parse(object[fieldName.to_sym].to_s)
							if field.validationParam.to_s == "TODAY"
								targetDate = Time.parse(Time.new.strftime("%F 00:00:00 %z"))
							elsif object.has_key?(field.validationParam.to_sym)
								targetDate = Time.parse(object[field.validationParam.to_sym])
							else
								targetDate = Time.parse(field.validationParam.to_s)
							end
							if srcDate != nil && targetDate != nil && srcDate > targetDate
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s)])
								else
									MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s), placeHolderValues])
								end
							end
						rescue Exception => e
							puts "Invalid date validation: #{e}"
						end
					# elsif dataType != "string"
					# 	src = object[fieldName.to_sym].to_f
					# 	if object.has_key?(field.validationParam.to_sym)
					# 		target = object[field.validationParam.to_sym].to_f
					# 	else
					# 		target = field.validationParam.to_f
					# 	end
					# 	if src >= target
					# 		MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), field.validationParam.to_s])
					# 	end
					# end
				elsif field.validationCd.to_s == "GREATEREQUALS"
					# if dataType == "date"
						begin
							srcDate = Time.parse(object[fieldName.to_sym].to_s)
							if field.validationParam.to_s == "TODAY"
								targetDate = Time.parse(Time.new.strftime("%F 00:00:00 %z"))
							elsif object.has_key?(field.validationParam.to_sym)
								targetDate = Time.parse(object[field.validationParam.to_sym])
							else
								targetDate = Time.parse(field.validationParam.to_s)
							end
							if srcDate != nil && targetDate != nil && srcDate <= targetDate
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s)])
								else
									MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s), placeHolderValues])
								end
							end
						rescue Exception => e
							puts "Invalid date validation: #{e}"
						end
					# elsif dataType != "string"
					# 	src = object[fieldName.to_sym].to_f
					# 	if object.has_key?(field.validationParam.to_sym)
					# 		target = object[field.validationParam.to_sym].to_f
					# 	else
					# 		target = field.validationParam.to_f
					# 	end
					# 	if src <= target
					# 		MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), field.validationParam.to_s])
					# 	end
					# end
				elsif field.validationCd.to_s == "GREATER"
					# if dataType == "date"
						begin
							srcDate = Time.parse(object[fieldName.to_sym].to_s)
							if field.validationParam.to_s == "TODAY"
								targetDate = Time.parse(Time.new.strftime("%F 00:00:00 %z"))
							elsif object.has_key?(field.validationParam.to_sym)
								targetDate = Time.parse(object[field.validationParam.to_sym])
							else
								targetDate = Time.parse(field.validationParam.to_s)
							end
							if srcDate != nil && targetDate != nil && srcDate < targetDate
								unless $rhoconfig[:TABFEATUREREQD]
									MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s)])
								else
									MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.getLabel(field.validationParam.to_s), placeHolderValues])
								end
							end
						rescue Exception => e
							puts "Invalid date validation: #{e}"
						end
					# elsif dataType != "string"
					# 	src = object[fieldName.to_sym].to_f
					# 	if object.has_key?(field.validationParam.to_sym)
					# 		target = object[field.validationParam.to_sym].to_f
					# 	else
					# 		target = field.validationParam.to_f
					# 	end
					# 	if src <= target
					# 		MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel), field.validationParam.to_s])
					# 	end
					# end
				end
			end
		end
		
		#Method to validate field as per minValue
		def self.minValueValidation(object, field, errors, parentObj=nil)
			fieldName = field.metaDataCd.split('.').last
			fieldLabel = fieldName
			tabId = field.tabId
			if field.evaluatedTabId.to_s != ""
				tabId = field.evaluatedTabId
			end
			metaDataClass = field.metaDataCd.to_s.split('.')[0].to_sym
			if $uiMetaDataCache != nil && $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(field.metaDataCd.to_sym) && $globalContextObjectMap.has_key?(object[:guid])
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", $uiMetaDataCache[metaDataClass][field.metaDataCd.to_sym], $globalContextObjectMap[object[:guid]], "array")
				fieldLabel = ui.propertyValue.to_s if ui
			end

			if field.exceptionCd.to_s != ""
				exceptionCd = field.exceptionCd
			else
				exceptionCd = "ERR_#{field.validationCd}"
			end
			
			exceptionMessage = replacePropertyFields(field, fieldName, exceptionCd, object)
			placeHolderValues = replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj)

			if object.has_key?(fieldName.to_sym)
				fieldValue = object[fieldName.to_sym].to_s.force_encoding(Encoding::UTF_8)
				if fieldValue.to_f < field.validationParam.to_f
					unless $rhoconfig[:TABFEATUREREQD]
						MobiSys::CommonUtil.addErrors(errors, fieldName, exceptionMessage, [MobiSys::BrowserHelper.getLabel(fieldLabel)])
					else
						MobiSys::CommonUtil.registerException(@entitySeq, "#{object[:guid]}-#{fieldName}", exceptionCd, exceptionCd, tabId, [MobiSys::BrowserHelper.getLabel(fieldLabel), MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(field.validationParam),$currencyFormat),MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(fieldValue),$currencyFormat)])
					end
				end
			end
		end
		#Method to replace property fields
		def self.replacePropertyFields(field, fieldName, exceptionCd, object)
			if field.propertyFields.to_s != ""
				# Split propertyFields on commas to handle multiple values
				property_tokens = field.propertyFields.to_s.split(",")
				property_tokens.each do |token|
					token = token.strip
					next unless MobiSys::BrowserHelper.getLabel(exceptionCd).include?(token)

					placeHolderValue = nil

					if token == "entityDesc"
						className = field.metaDataCd.split('.').first.rpartition('DO').first
						tempObject = object.clone
						tempObject.each do |key, value|
							if key.to_s.include?("List") || ["source_id", "versionID", "class"].include?(key.to_s)
								tempObject.delete(key)
							else
								tempObject[key] = value.to_s if !value.is_a?(Hash) && !value.is_a?(Array)
							end
						end
						placeHolderValue = MobiSys::BrowserHelper.convertToObject(className, tempObject).getEntityDesc.to_s
					elsif token == "roleCd"
						placeHolderValue = object[:roleCd].to_s
					elsif token == "productTypeCd"
						placeHolderValue = object[:productTypeCd].to_s
					else
						if object.has_key?(token.to_sym)
						placeHolderValue = object[token.to_sym].to_s
						else
						placeHolderValue = object[fieldName.to_sym].to_s
						end
					end
					# Replace placeholder in exceptionCd for this token
					exceptionCd = MobiSys::BrowserHelper.getLabel(exceptionCd).gsub("{#{token}}", MobiSys::BrowserHelper.getLabel(placeHolderValue))
				end
			end

			return exceptionCd
		end

		def self.replacePropertyFields1(field, fieldName, exceptionCd, object, parentObj=nil)
			placeHolderValueHash = {}
			if field.propertyFields.to_s != ""
				# Split propertyFields into tokens (handles both single and multiple values)
				property_tokens = field.propertyFields.to_s.split(",")

				property_tokens.each do |token|
					token = token.strip
					next unless MobiSys::BrowserHelper.getLabel(exceptionCd).include?(token)

					placeHolderValue = nil

					if token == "entityDesc"
						className = field.metaDataCd.split('.').first.rpartition('DO').first
						tempObject = object.clone
							tempObject.each do |key, value|
								if key.to_s.include?("List") || ["source_id", "versionID", "class"].include?(key.to_s)
									tempObject.delete(key)
								else
									tempObject[key] = value.to_s if !value.is_a?(Hash) && !value.is_a?(Array)
								end
							end
							placeHolderValue = MobiSys::BrowserHelper.convertToObject(className, tempObject).getEntityDesc.to_s
						elsif token == "roleCd"
							placeHolderValue = object[:roleCd].to_s == "" ? (parentObj[:roleCd].to_s != "" ? parentObj[:roleCd].to_s : "") : object[:roleCd].to_s
						elsif token == "productTypeCd"
							placeHolderValue = object[:productTypeCd].to_s
						else
							if object.has_key?(token.to_sym)
								placeHolderValue = object[token.to_sym].to_s
							else
								placeHolderValue = object[fieldName.to_sym].to_s
							end
						end
						# Replace placeholder in exceptionCd for this token
						exceptionCd = MobiSys::BrowserHelper.getLabel(exceptionCd).gsub("{#{token}}", MobiSys::BrowserHelper.getLabel(placeHolderValue))
						# Store the placeholder value in the hash for reference
						placeHolderValueHash[token] = placeHolderValue
					end
				end

			return placeHolderValueHash
		end


		#Method to validate field as per custom validation method
		def self.customValidation(objectHash, field, errors)
			if !field.metaDataCd.index('.')
				boClassName = field.metaDataCd.gsub('DO', 'BO')
				className = field.metaDataCd.gsub('DO', '')
				validationMethod = field.validationParam

				#Include the required BO file
				require className+'/'+className.gsub(/(?<=.)([A-Z])/){|m| "_#{$1}"}.downcase+'_b_o'

				if MobiSys.const_get(boClassName).respond_to?(validationMethod.to_sym)
					#Convert to object from hash
					object = MobiSys::MobiSysFixedSchema.from_hash(className,objectHash)

					$currentTabId = field.tabId
					MobiSys.const_get(boClassName).send(validationMethod.to_sym, object, errors)
					$currentTabId = nil
				end
			end
		end


		#Method to execute all applicable validations for a given class
		def self.validationLoop(object, validationContexts, errors, validationSetName, entitySeq=nil, contextSetDataType="class", parentObj=nil)
        	className = object["class"].split(".")[-1]
        	validationContexts = [] if validationContexts == nil
        	if object[:removed].to_s !="YES"
        		if entitySeq
	        		@entitySeq = entitySeq
	        	else
	        		@entitySeq = object[:guid]
	        	end
	        end
        	case validationContexts.class.to_s
        	when "Array"
        		contextSetDataType="array"
        	when "Class"
        		contextSetDataType="class"
        	end

    	 	#------------------Loop over Validation Metadata for given class start------------------
		  	if object[:removed].to_s !="YES" && $validationHash.has_key?(className.to_sym)
		  		if contextSetDataType == "class"
		        	validContexts = (validationContexts.methods - Object.methods).select{|x| validationContexts.respond_to?(x.to_sym) && validationContexts.send(x.to_sym)}
		        	$globalContextObjectMap.merge!({object[:guid]=>validContexts}) if $globalContextObjectMap
		        end

		  		mandatoryFields 	= Hash.new
		  		formatFields 		= Hash.new
		  		lesserequalsFields 	= Hash.new
		  		lesserFields 		= Hash.new
		  		greaterFields 		= Hash.new
		  		minValueFields 		= Hash.new
		  		blackListFields 	= Hash.new
		  		
		 		validateClassHash 	= $validationHash[className.to_sym]
		 		#Create hash to be passed to mandatory validation for Global context
		 		if validateClassHash.has_key?(:MINOCCURS) && validateClassHash[:MINOCCURS].has_key?(:GLOBAL)
				   	validateClassHash[:MINOCCURS][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				mandatoryFields[fieldKey] = fieldValue if fieldValue.validationParam == "1" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
				end

				#Create hash to be passed to format validation for Global context
				if validateClassHash.has_key?(:FORMAT) && validateClassHash[:FORMAT].has_key?(:GLOBAL)
				   	validateClassHash[:FORMAT][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				formatFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

				#Create hash to be passed to lesserequals validation for Global context
				if validateClassHash.has_key?(:LESSEREQUALS) && validateClassHash[:LESSEREQUALS].has_key?(:GLOBAL)
				   	validateClassHash[:LESSEREQUALS][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				lesserequalsFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

				#Create hash to be passed to lesser validation for Global context
				if validateClassHash.has_key?(:LESSER) && validateClassHash[:LESSER].has_key?(:GLOBAL)
				   	validateClassHash[:LESSER][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				lesserFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

				#Create hash to be passed to greater validation for Global context
				if validateClassHash.has_key?(:GREATER) && validateClassHash[:GREATER].has_key?(:GLOBAL)
				   	validateClassHash[:GREATER][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				greaterFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

				#Create hash to be passed to mandatory validation for NONGLOBAL context
				if validateClassHash.has_key?(:MINOCCURS) && validateClassHash[:MINOCCURS].has_key?(:NONGLOBAL)
				  	validateClassHash[:MINOCCURS][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
					  		if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				if fieldValue.validationParam == "1" && !mandatoryFields.has_key?(fieldKey)
					 					mandatoryFields[fieldKey] = fieldValue
					 				elsif fieldValue.validationParam == "0" && mandatoryFields.has_key?(fieldKey)
					 					mandatoryFields = mandatoryFields.tap { |h| h.delete(fieldKey) }
					 				end
					 			end
					 		end
					 	end
					end
				end

				#Create hash to be passed to format validation for NONGLOBAL context
				if validateClassHash.has_key?(:FORMAT) && validateClassHash[:FORMAT].has_key?(:NONGLOBAL)	
					validateClassHash[:FORMAT][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
						 	if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				formatFields[fieldKey] = fieldValue
					 			end
					 		end
					 	end
					end
				end

				#Create hash to be passed to lesserequals validation for NONGLOBAL context
				if validateClassHash.has_key?(:LESSEREQUALS) && validateClassHash[:LESSEREQUALS].has_key?(:NONGLOBAL)	
					validateClassHash[:LESSEREQUALS][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				lesserequalsFields[fieldKey] = fieldValue
					 			end
					 		end
					 	end
					end
				end

				#Create hash to be passed to lesser validation for NONGLOBAL context
				if validateClassHash.has_key?(:LESSER) && validateClassHash[:LESSER].has_key?(:NONGLOBAL)	
					validateClassHash[:LESSER][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				lesserFields[fieldKey] = fieldValue
					 			end
					 		end
					 	end
					end
				end

				#Create hash to be passed to greater validation for NONGLOBAL context
				if validateClassHash.has_key?(:GREATER) && validateClassHash[:GREATER].has_key?(:NONGLOBAL)	
					validateClassHash[:GREATER][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				greaterFields[fieldKey] = fieldValue
					 			end
					 		end
					 	end
					end
				end

				if validateClassHash.has_key?(:GREATEREQUALS) && validateClassHash[:GREATEREQUALS].has_key?(:NONGLOBAL)	
					validateClassHash[:GREATEREQUALS][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				greaterFields[fieldKey] = fieldValue
					 			end
					 		end
					 	end
					end
				end

				if validateClassHash.has_key?(:MINVALUE) && validateClassHash[:MINVALUE].has_key?(:GLOBAL)
				   	validateClassHash[:MINVALUE][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				minValueFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

			  	if validateClassHash.has_key?(:MINVALUE) && validateClassHash[:MINVALUE].has_key?(:NONGLOBAL)
				   	validateClassHash[:MINVALUE][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				minValueFields[fieldKey] = fieldValue
					 			end
					 		end
			  			end
				  	end
			  	end

			  	#Create hash to be passed to blacklist validation for GLOBAL context
			  	if validateClassHash.has_key?(:BLACKLISTCHARS) && validateClassHash[:BLACKLISTCHARS].has_key?(:GLOBAL)
				   	validateClassHash[:BLACKLISTCHARS][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
			  				blackListFields[fieldKey] = fieldValue if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
			  			end
				  	end
			  	end

			  	#Create hash to be passed to blacklist validation for NONGLOBAL context
			  	if validateClassHash.has_key?(:BLACKLISTCHARS) && validateClassHash[:BLACKLISTCHARS].has_key?(:NONGLOBAL)
				   	validateClassHash[:BLACKLISTCHARS][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
					 				blackListFields[fieldKey] = fieldValue
					 			end
					 		end
			  			end
				  	end
			  	end

				tempErrorHash = Hash.new

				#Pass mandatory fields' hash for validation
				mandatoryFields.each do |fieldKey, fieldValue|
					mandatoryValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass format fields' hash for validation
				formatFields.each do |fieldKey, fieldValue|
					formatValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass lesserequals fields' hash for validation
				lesserequalsFields.each do |fieldKey, fieldValue|
					greaterLesserValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass lesser fields' hash for validation
				lesserFields.each do |fieldKey, fieldValue|
					greaterLesserValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass greater fields' hash for validation
				greaterFields.each do |fieldKey, fieldValue|
					greaterLesserValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				minValueFields.each do |fieldKey, fieldValue|
				    minValueValidation(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass blacklist fields' hash for validation
				blackListFields.each do |fieldKey, fieldValue|
					isBlacklistValid(object,fieldValue,tempErrorHash,parentObj)
				end

				#Pass objects for custom validation for GLOBAL context
				if validateClassHash.has_key?(:CUSTOM) && validateClassHash[:CUSTOM].has_key?(:GLOBAL)	
					validateClassHash[:CUSTOM][:GLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
								if fieldValue.metaDataCd.include?("Quotation")
									customValidation(object,fieldValue,errors)
								else
									customValidation(object,fieldValue,tempErrorHash)
								end
							end
						end
					end
				end

				#Pass objects for custom validation for NONGLOBAL context
				if validateClassHash.has_key?(:CUSTOM) && validateClassHash[:CUSTOM].has_key?(:NONGLOBAL)	
					validateClassHash[:CUSTOM][:NONGLOBAL].each do |fieldKey, validationRecord|
						validationRecord.each do |fieldValue|
							if fieldValue.validationParam.to_s != "" && fieldValue.disabled.to_s != "YES"
					  			validContext = MobiSys::MetaData.evalContext(fieldValue, contextSetDataType, validationContexts)
					 			unless validContext.empty?
									if fieldValue.metaDataCd.include?("Quotation")
										customValidation(object,fieldValue,errors)
									else
										customValidation(object,fieldValue,tempErrorHash)
									end
								end
							end
						end
					end
				end
				
	        	#Create new error hash based on classname and object guid if errors present
	        	if !tempErrorHash.empty?
		    	 	errors[className.to_sym] = Hash.new if !errors[className.to_sym].is_a?(Hash)
		    	 	errors[className.to_sym][object[:guid].to_sym] = Hash.new if !errors[className.to_sym][object[:guid].to_sym].is_a?(Hash)
		    	 	errors[className.to_sym][object[:guid].to_sym] = errors[className.to_sym][object[:guid].to_sym].merge(tempErrorHash)
	    	 	end
			end
			#------------------Loop over Validation Metadata for given class end------------------


			#Repeat the process recursively for child objects
			object.collect{|x,y| (y.class==Array)? y : nil }.compact.each do |z|
				z.each do |y|
					#Get contexts based on current object
					if y.has_key?("class")
						className = y["class"].split(".")[-1].gsub("DO","")
						validationSet = Object.const_get(validationSetName) if eval("defined? (#{validationSetName})") == "constant"
						if (validationSet != nil && validationSet.respond_to?(className)) || validationSetName.to_s == "GenericSet"
							convertedObject = from_hash(className,y)
							if contextSetDataType == 'class'
								validationSet.setObject(convertedObject)
							else
								validationContexts = $globalContextObjectMap[y[:guid]]
							end
							validationLoop(y, validationContexts, errors, validationSetName, @entitySeq, contextSetDataType, object)
						elsif $globalContextObjectMap && $globalContextObjectMap.has_key?(y[:guid])
							validationContexts = $globalContextObjectMap[y[:guid]]
							validationLoop(y, validationContexts, errors, validationSetName, @entitySeq, contextSetDataType, object)
						end
					end
				end
			end
		end


		# Method to get validationMetadata object based on property code and current object context
		def self.getValidationDO(propertyCd, validationDOList, currentApplicableContexts, metaDataCd, returnList=false, contextSetDataType="class", returnDisabled=false)
			unless returnList
				validationDO = nil
			else
				returnValidationDOList = []
			end
			begin
				if validationDOList.has_key?(propertyCd.to_sym) && validationDOList[propertyCd.to_sym].has_key?(:GLOBAL) && validationDOList[propertyCd.to_sym][:GLOBAL].has_key?(metaDataCd) && validationDOList[propertyCd.to_sym][:GLOBAL][metaDataCd].size > 0 && (!returnDisabled && validationDOList[propertyCd.to_sym][:GLOBAL][metaDataCd][0].disabled.to_s != "YES")
					unless returnList
						validationDO = validationDOList[propertyCd.to_sym][:GLOBAL][metaDataCd][0]
					else
						returnValidationDOList += validationDOList[propertyCd.to_sym][:GLOBAL][metaDataCd]
					end
				end
				if validationDOList.has_key?(propertyCd.to_sym) && validationDOList[propertyCd.to_sym].has_key?(:NONGLOBAL) && validationDOList[propertyCd.to_sym][:NONGLOBAL].has_key?(metaDataCd) && currentApplicableContexts != nil
					validationDOList[propertyCd.to_sym][:NONGLOBAL][metaDataCd].each do |validationRecord|
						if returnDisabled || (!returnDisabled && validationRecord.disabled.to_s != "YES")
							validContext = MobiSys::MetaData.evalContext(validationRecord, contextSetDataType, currentApplicableContexts)
				 			unless validContext.empty?
								unless returnList
				 					validationDO = validationRecord
				 				else
				 					returnValidationDOList << validationRecord
				 				end
				 			end
				 		end
			 		end
		 		end
 			rescue Exception => e
				Rho::Log.error("Error in getValidationDO--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			unless returnList
 				return validationDO
 			else
 				return returnValidationDOList
 			end
		end


		# Method to check if current method name is applicable for current object context
		def self.validateMethodCall(objToValidate, methodName, moduleName)
			shouldValidate = true
			$currentValidationMetadata = nil
			if $validationHash.has_key?("#{moduleName}DO".to_sym) && $validationHash["#{moduleName}DO".to_sym].has_key?(:SYSTEMFIXED) && $validationHash["#{moduleName}DO".to_sym][:SYSTEMFIXED].size > 0 && $globalContextObjectMap
				validationContextList = getValidationDO("SYSTEMFIXED", $validationHash["#{moduleName}DO".to_sym], $globalContextObjectMap[objToValidate.guid], "#{moduleName}DO", true, "array", true)
				if validationContextList.empty?
					shouldValidate = false
				else
					validationContextList.each do |validationMetaDataDOi|
						if validationMetaDataDOi.validationParam.to_s == methodName
							if validationMetaDataDOi.disabled.to_s == "YES"
								shouldValidate = false
								break
							end
							$currentValidationMetadata = validationMetaDataDOi
							break
						end
					end
				end
			end
			return shouldValidate
		end


		def self.processValidContexts(object, validationContexts, validationSetName)
			className = object["class"].split(".")[-1]
			if object[:removed].to_s !="YES" && $validationHash.has_key?(className.to_sym)
				if $rhoconfig[:contextBasedMetadata]
	        		$globalContextObjectMap.merge!({object[:guid]=>validationContexts}) if $globalContextObjectMap
	        	else
	        		validContexts = (validationContexts.methods - Object.methods).select{|x| validationContexts.respond_to?(x.to_sym) && validationContexts.send(x.to_sym)}
	        		$globalContextObjectMap.merge!({object[:guid]=>validContexts}) if $globalContextObjectMap
	        	end
				#Repeat the process recursively for child objects
				object.collect{|x,y| (y.class==Array)? y : nil }.compact.each do |z|
					z.each do |y|
						#Get contexts based on current object
						if y.has_key?("class")
							className = y["class"].split(".")[-1].gsub("DO","")
							convertedObject = from_hash(className,y)
							if $rhoconfig[:contextBasedMetadata]
								contextMasterGeneratedArray = []
								if $contextMasterCache.has_key?((className+"DO").to_sym)
									contextMasterList = $contextMasterCache[(className+"DO").to_sym]
									contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,convertedObject)
								end
								contextMasterGeneratedArray.concat(validationContexts) if validationContexts
								processValidContexts(y, contextMasterGeneratedArray, validationSetName)
							else
								validationSet = Object.const_get(validationSetName)
								if validationSet.respond_to?(className) || validationSetName.to_s == "GenericSet"
									validationSet.setObject(convertedObject)
									processValidContexts(y, validationContexts, validationSetName)
								end
							end
						end
					end
				end
			end
		end
	end


	class ContextMasterData
		LOGCATEGORY = "ContextMaster"

		def self.initializeContextMasterHash
			contextMasters = ContextMaster.find(
	    		:all,
	    		:select => ['className','fieldName','contextNameExpression', 'expressionTypeCd']
	    	)
			$contextMasterCache = Hash.new
			contextMasters.each do |contextMaster|
				classNameKey = contextMaster.className.to_s.to_sym
				$contextMasterCache[classNameKey] = Array.new if !$contextMasterCache[classNameKey].is_a?(Array)
				$contextMasterCache[classNameKey].push(contextMaster)
	    	end
		end

		#method to evaluate the context name based on the expression or the attribute value.
		def self.evaluateContextField(object, attrName, expression)
			# Directly evaluate the expression if attrName and expression are valid
			if expression.to_s != ""
				object.send(:define_singleton_method, :contextExpressionEval) do |expr|
					eval(expr)
				end
				contextName = object.contextExpressionEval(expression)
			else
				# Fallback to get the attribute value if no expression is provided
				contextName = object.send(attrName.to_sym) rescue nil
				# puts "contextName :- #{contextName} for object.#{attrName} and Object = #{object.class.name}"
			end
			return contextName
		end

		#Method to generate ana array of current applicable context for the given array and its extended classes (for example Party - PartyAdditionalFields)
		def self.generateContextModuleArray(contextMasterList,object,contextMasterArray = [],evalHashGuid = nil,isRecursive = false)
			
			evalHashGuid = object.uniqueKey if evalHashGuid == nil 
			$contextMasterEvalHash[evalHashGuid] = Array.new unless isRecursive
			contextMasterList.each do |contextMaster|
				#call method to evaluate the context name based on the expression or the attribute value.
				contextName = evaluateContextField(object,contextMaster.fieldName,contextMaster.contextNameExpression)
				# Do not do further evaluation for context if need to default
				if contextMaster.fieldName.to_s != "" && contextMaster.contextNameExpression.to_s != "" && contextMaster.expressionTypeCd.to_s == "DEFAULT"
					object.send("#{contextMaster.fieldName}=", contextName) if object.send("#{contextMaster.fieldName}").to_s == ""
					next
				end

		        if contextName.to_s != "" && contextName.to_s != "XXX" && contextName.to_s != "null"
		        	contextMasterArray << contextName.to_sym
		        	#Generate a hash containing context details and push it in an array. this array will hold all the context master related data for the current object and its extended classes.
		        	contextMasterEval = {"fieldName" => contextMaster.fieldName, 
		        		"contextNameExpression" => contextMaster.contextNameExpression,
		        		"className" => contextMaster.className,
		        		"contextName" => contextName}
					# $contextMasterEvalHash[evalHashGuid] = Array.new unless $contextMasterEvalHash[evalHashGuid].is_a?(Array)
					$contextMasterEvalHash[evalHashGuid].push(contextMasterEval)
				else
					contextMasterEval = {"fieldName" => contextMaster.fieldName, 
		        		"contextNameExpression" => contextMaster.contextNameExpression,
		        		"className" => contextMaster.className,
		        		"contextName" => :DUMMYCONTEXT}
	        		# evalHashGuid = object.uniqueKey if evalHashGuid == nil 
					# $contextMasterEvalHash[evalHashGuid] = Array.new unless $contextMasterEvalHash[evalHashGuid].is_a?(Array)
					$contextMasterEvalHash[evalHashGuid].push(contextMasterEval)
				end
			end

			#Block to make a recursive call to add context of extended class to parent class. Guid passed for the global has is Parent class guid.
			if Object.const_get(object.class.name).instance_methods(false) && Object.const_get(object.class.name).instance_methods(false).include?(:contextExtendForClass)
				classesToInclude = object.contextExtendForClass.to_s.split(',')
				if classesToInclude.size > 0
					classesToInclude.each do |className|
						classToFind = "#{className}DO"
						if $contextMasterCache.has_key?(classToFind.to_sym)
							classContextMasterList = $contextMasterCache[classToFind.to_sym]
							classList = object.send "#{className}List".to_sym
							if classList.size > 0
								classList.each do |objectToSend|
									generateContextModuleArray(classContextMasterList,objectToSend,contextMasterArray,object.uniqueKey,true)
								end
							end
						end
					end
				end
			end
			return contextMasterArray
		end

		

	end


	class UIMetaData
		LOGCATEGORY = "UIMetaData"

		#Method to create a global uiMetaDataCache based on UIMetaData
	    def self.initializeUiMetaDataHash
	    	uiMetaDatas = UiMetaDataProperty.find(
	    		:all,
	    		:select => ['contextCd','propertyCd','propertyValue','metaDataCd']
	    	)
	    	$companyFieldMetaDataCache ||= CompanyFieldMetadata.find(:all,:select => ['inputMetadataCd']).collect{|companyFieldMetadata| companyFieldMetadata.inputMetadataCd.to_sym}
			$uiMetaDataCache = Hash.new

	    	uiMetaDatas.each do |uiMetaData|
	    		metaDataClass = uiMetaData.metaDataCd.to_s.split('.')[0].to_sym
				metaDataCdKey = uiMetaData.metaDataCd.to_s.to_sym
				$uiMetaDataCache[metaDataClass] = Hash.new if !$uiMetaDataCache[metaDataClass].is_a?(Hash)
				$uiMetaDataCache[metaDataClass][metaDataCdKey] = Hash.new if !$uiMetaDataCache[metaDataClass][metaDataCdKey].is_a?(Hash)

				if uiMetaData.contextCd.to_s.upcase == "GLOBAL" || uiMetaData.contextCd.to_s == ""
					contextScope = :GLOBAL
				else
					contextScope = :NONGLOBAL
				end

				$uiMetaDataCache[metaDataClass][metaDataCdKey][contextScope] = Hash.new if !$uiMetaDataCache[metaDataClass][metaDataCdKey][contextScope].is_a?(Hash)
				$uiMetaDataCache[metaDataClass][metaDataCdKey][contextScope][uiMetaData.propertyCd.to_s.to_sym] = Array.new if !$uiMetaDataCache[metaDataClass][metaDataCdKey][contextScope][uiMetaData.propertyCd.to_s.to_sym].is_a?(Array)
				$uiMetaDataCache[metaDataClass][metaDataCdKey][contextScope][uiMetaData.propertyCd.to_s.to_sym].push(uiMetaData)
	    	end
	    end

	    def self.initializeDataElement
	    	dataElements = DataElement.find(
	    		:all,
	    		:select => ['attributeCd','attributeTypeCd','entityFieldTypeCd','globalFl']
	    	)
			$dataElementCache = Hash.new

	    	dataElements.each do |dataElement|
				key = dataElement.attributeCd.to_s.to_sym
				$dataElementCache[key] = Hash.new if !$dataElementCache[key].is_a?(Hash)
				$dataElementCache[key] = dataElement
	    	end
	    end

	    def self.initializeEntityType
	    	entityTypes = EntityType.loadObject(:all)
	    	$entityTypeCache = Hash.new
	    	entityTypes.each do |entityType|
				key = entityType.entityFieldTypeCd.to_s.to_sym
				$entityTypeCache[key] = Hash.new if !$entityTypeCache[key].is_a?(Hash)
				$entityTypeCache[key] = entityType
	    	end
	    end


		# Method to get uiMetadataProperty object based on property code and current object context
		def self.getUiMetadataPropDO(propertyCd, uiMetaDataDOList, currentApplicableContexts, contextSetDataType="class")
			uiMetaDataPropertyDO = nil
			begin
				if uiMetaDataDOList.has_key?(:GLOBAL) && uiMetaDataDOList[:GLOBAL].has_key?(propertyCd.to_sym) && uiMetaDataDOList[:GLOBAL][propertyCd.to_sym].size > 0
					uiMetaDataPropertyDO = uiMetaDataDOList[:GLOBAL][propertyCd.to_sym][0]
				end
				if uiMetaDataDOList.has_key?(:NONGLOBAL) && uiMetaDataDOList[:NONGLOBAL].has_key?(propertyCd.to_sym) && currentApplicableContexts != nil
					uiMetaDataDOList[:NONGLOBAL][propertyCd.to_sym].each do |uiMetaData|
						validContext = MobiSys::MetaData.evalContext(uiMetaData, contextSetDataType, currentApplicableContexts)
			 			unless validContext.empty?
			 				uiMetaDataPropertyDO = uiMetaData
			 			end
			 		end
		 		end
 			rescue Exception => e
				Rho::Log.error("Error in getUiMetadataPropDO--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
 			return uiMetaDataPropertyDO
		end

		# Method to get uiMetadataProperty object based on property code and current object context
		def self.getUiMetadataPropDOList(uiMetaDataDOList, currentApplicableContexts, contextSetDataType="class")
			uiMetaDataPropertyDO = nil
			returnHash = {}
			begin
				if uiMetaDataDOList.has_key?(:GLOBAL)
					uiMetaDataDOList[:GLOBAL].each do |key,value|
						returnHash[key] = value[0]
					end
				end
				if uiMetaDataDOList.has_key?(:NONGLOBAL) #&& uiMetaDataDOList[:NONGLOBAL].has_key?(propertyCd.to_sym) && currentApplicableContexts != nil
					uiMetaDataDOList[:NONGLOBAL].each do |key, value|
						value.each do |val|
							validContext = MobiSys::MetaData.evalContext(val, contextSetDataType, currentApplicableContexts)
				 			unless validContext.empty?
								returnHash[key] = val
				 			end
				 		end
			 		end
		 		end
 			rescue Exception => e
				Rho::Log.error("Error in getUiMetadataPropDO--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
 			return returnHash.values
		end
	end

	class ProductMetaData
		LOGCATEGORY = "ProductMetaData"

		#Method to create a global productMetaDataCache based on Product PrdFieldMetaData
	    def self.initializeProductMetaDataHash
	    	products = Product.loadObject(:all)
	    	$productMetaDataCache = Hash.new

		    products.each do |product, key|
		    	productSeq = product.id.to_s
		    	if productSeq != ""
			    	product.PrdFieldMetaDataList.each do |productMetaData|
			    		$productMetaDataCache[productSeq] = Hash.new if !$productMetaDataCache[productSeq].is_a?(Hash)
		     			metaDataCdKey = productMetaData.fieldCd.to_s.to_sym
						$productMetaDataCache[productSeq][metaDataCdKey.to_s.to_sym] = Hash.new if !$productMetaDataCache[productSeq][metaDataCdKey.to_s.to_sym].is_a?(Hash)
						if productMetaData.propertyCd.to_s != ""
							$productMetaDataCache[productSeq][metaDataCdKey.to_s.to_sym][productMetaData.propertyCd.to_s.to_sym] = Array.new if !$productMetaDataCache[productSeq][metaDataCdKey.to_s.to_sym][productMetaData.propertyCd.to_s.to_sym].is_a?(Array)
							$productMetaDataCache[productSeq][metaDataCdKey.to_s.to_sym][productMetaData.propertyCd.to_s.to_sym].push(productMetaData)
						end
			    	end
			    end
		    end

	    end

	    def self.createPrdFieldMetaDataMap(product)
	    	if product
	    		# set prd metadata attribute map
	    		prdFieldMetaDataMap = Hash.new
	    		product.PrdFieldMetaDataList.each do |prdFieldMetaDataDO|
	    			objectName = prdFieldMetaDataDO.objectName
	    			objectName = "QuotationProductDO" if objectName.to_s == ""
	    			# create hashmap key as object name and field name,if object name is blank then it consider as base plan or rider.
	    			prdFieldMetaDataMapKey = objectName.to_s+"-"+prdFieldMetaDataDO.fieldCd.to_s
	    			prdFieldMetaDataDOList = prdFieldMetaDataMap[prdFieldMetaDataMapKey]
	    			prdFieldMetaDataDOList = Array.new if prdFieldMetaDataDOList == nil
	    			prdFieldMetaDataDOList << prdFieldMetaDataDO
	    			prdFieldMetaDataMap[prdFieldMetaDataMapKey] = prdFieldMetaDataDOList
	    		end
	    	end
	    end

		# Method to get productMetadataProperty object based on property code
		def self.getProductMetadataPropDO(propertyCd, productMetaDataDOList)
			productMetaDataPropertyDO = nil
			begin
				if productMetaDataDOList.has_key?(propertyCd.to_sym) && productMetaDataDOList[propertyCd.to_sym].size > 0
					productMetaDataPropertyDO = productMetaDataDOList[propertyCd.to_sym][0]
				end
			rescue Exception => e
				Rho::Log.error("Error in getProductMetadataPropDO--->#{e}\n#{e.backtrace}", LOGCATEGORY)
			end
			
 			return productMetaDataPropertyDO
		end
	end
end
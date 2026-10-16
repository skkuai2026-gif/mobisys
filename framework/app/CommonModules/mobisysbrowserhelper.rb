#encoding: UTF-8
require 'helpers/browser_helper'
require 'time'
require 'zlib'
require 'stringio'
require 'json'
require 'base64'

module MobiSys
	#Browserhelper module contains utility methods used by the functional modules
	#Add any new method which is used by the UI/Controller for UI actions in this module
	module BrowserHelper
		DYNAMICLOOKUP = "DYNAMICLOOKUP"
		$objectMapping = Hash.new
		$objectCount = Hash.new
		JS_ESCAPE_MAP = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }
		JS_ESCAPE_MAP["\342\200\250".force_encoding(Encoding::UTF_8).encode!] = '&#x2028;'
		JS_ESCAPE_MAP["\342\200\251".force_encoding(Encoding::UTF_8).encode!] = '&#x2029;'

		def gunzip(data)
			io = StringIO.new(data, "rb")
			gz = Zlib::GzipReader.new(io)
			decompressed = gz.read
		end


		def escape_javascript(javascript)
			if javascript
				result = javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| JS_ESCAPE_MAP[match] }
			else
				''
			end
		end
		##################################################################################################


		def getDate
			title = @params['title']
			if @params['datetime'] != nil && @params['datetime'] != ""
				initial_time = Time.strptime(@params['datetime'], "%d/%m/%Y")
				datetime = @params['datetime']
			else
				initial_time = Time.now
				datetime = initial_time.strftime("%d/%m/%Y")
			end
			DateTimePicker.choose("/app/#{self.class.name.chomp('Controller')}/dateTimeCallback", title, initial_time, 1, @params['fieldKey']+'|1|'+datetime)
		end
		##################################################################################################


		def getDateTime
			title = @params['title']
			if @params['datetime'] != nil && @params['datetime'] != ""
				initial_time = Time.strptime(@params['datetime'], "%d/%m/%Y %H:%M:%S %z")
				datetime = @params['datetime']
			else
				initial_time = Time.now
				datetime = initial_time.strftime("%d/%m/%Y %H:%M:%S %z")
			end
			DateTimePicker.choose("/app/#{self.class.name.chomp('Controller')}/dateTimeCallback", title, initial_time, 0, @params['fieldKey']+'|0|'+datetime)
		end
		##################################################################################################


		def getTime
			title = @params['title']
			if @params['datetime'] != nil && @params['datetime'] != ""
				initial_time = Time.strptime(@params['datetime'], "%H:%M:%S %z")
				datetime = @params['datetime']
			else
				initial_time = Time.now
				datetime = initial_time.strftime("%H:%M:%S %z")
			end
			DateTimePicker.choose("/app/#{self.class.name.chomp('Controller')}/dateTimeCallback", title, initial_time, 2, @params['fieldKey']+'|2|'+datetime)
		end
		##################################################################################################


		def addUserActivityHelper(uri, params, entityType, entityRefNumber=nil)
			MobiSys::CommonUtil.addUserActivity(uri, params, entityType, entityRefNumber)
		end
		##################################################################################################


		def dateTimeCallback
			params = @params
			opaque = @params['opaque']
			data = opaque.split("|")
			timeString = ""
			if data[1] == "0"
				timeString = "%d/%m/%Y %H:%M:%S %z"
			elsif data[1] == "1"
				timeString = "%d/%m/%Y"
			else
				timeString = "%H:%M:%S"
			end
			if @params['result'] != nil
				#WebView.execute_js('setFieldValue("'+data[0].split("#")[1]+'","'+Time::at(@params['result'].to_i).strftime(timeString)+'");')
				WebView.execute_js('setFieldValue("'+data[0]+'","'+Time::at(@params['result'].to_i).strftime(timeString)+'");')
			else
				WebView.execute_js('setFieldValue("'+data[0].split("#")[1]+'","'+data[2]+'");')
			end
		end
		##################################################################################################


		def self.renderSmsLink(phoneNumber, description=nil)
			html = "<a href=\"sms:#{phoneNumber}\">#{description}</a>" if description
			html = "<a href=\"sms:#{phoneNumber}\">#{phoneNumber}</a>" unless description
			return html
		end
		##################################################################################################


		def self.renderCallLink(phoneNumber,description=nil)
			html = "<a href=\"tel:#{phoneNumber}\">#{description}</a>" if description
			html = "<a href=\"tel:#{phoneNumber}\">#{phoneNumber}</a>" unless description
			return html
		end
		##################################################################################################


		def self.convertToObjectWithMerge(className, hash)
			storedEntity = eval("#{className}.loadObject(:first,:conditions=>{:object=>'#{hash['object']}'})")
			storedEntityHash = storedEntity.objectToHash if storedEntity
			formEntity = convertToObject(className, hash)

			if storedEntity
				formEntityHash = formEntity.objectToHash
				mergedEntityHash = merge_hash(formEntityHash, storedEntityHash)
				mergedEntity = hashToObject(className, mergedEntityHash)
			else
				mergedEntity = formEntity
			end
			return mergedEntity
		end
		##################################################################################################


		def self.hashToObject(className, hash)
			modelSource = Rho::RhoConfig.sources[className]
			objClass = Object.const_get(className)
			obj = objClass.new
			hash.each do |key,value|
				next if value == nil
				next if key.to_s=='source_id' || key.to_s == 'userId' || key.to_s=='class'
				if value.class.name.to_s == 'Array'
					value.each do |each_elem|
						if each_elem.is_a?(Hash)
							childClassName = key.to_s.gsub('list', '').gsub('DOList','')
							childObj = hashToObject(childClassName, each_elem)
							eval("obj.add#{childClassName}(childObj)")
						end
					end
				else
					begin
						properties = modelSource["schema"]["property"][key.to_s]
						methodName = "#{key}=".to_sym
						if properties
							if properties[1] and (properties[1] == :nondecimal or properties[1] == :decimal) and value != ""
								convertedValue = value.to_s.gsub(",", "")
								if properties[0] == :integer
									exp = "obj.#{key}=#{convertedValue.to_i}"
								else
									exp = "obj.#{key}=#{convertedValue.to_f}"
								end
								eval(exp)
							elsif properties[0] && properties[0] == :date && value.to_s != ""
								begin
									Time.parse(value.to_s)
									dateParts = value.split(/[\-\/ :]/)
									if dateParts[2].length < 3
										value = Time.new(dateParts[0].to_i,dateParts[1].to_i,dateParts[2].to_i,dateParts[3].to_i,dateParts[4].to_i)
									else
										value = Time.new(dateParts[2].to_i,dateParts[1].to_i,dateParts[0].to_i,dateParts[3].to_i,dateParts[4].to_i)
									end
								rescue Exception => e
									value = ""
								end
								exp = 'obj.' + key.to_s + '="' + value.to_s + '"'
								eval(exp)
							else
								obj.send(methodName, value)
							end
						else
							obj.send(methodName, value)
						end
					rescue StandardError => boom
						puts boom
					end
				end
			end
			return obj
		end
		##################################################################################################


		def self.merge_hash(formEntityHash, storedEntityHash)
			formEntityHash.each do |key,value|
				next if key == 'object'.to_sym || key.to_s.start_with?('list')
				storedEntityHash[key] = formEntityHash[key]
			end
			# # Iterate over storedEntityHash to set missing keys to nil
			# storedEntityHash.each_key do |key|
			# 	storedEntityHash[key] = '' unless formEntityHash.key?(key)
			# end

			childFormEntityHash = formEntityHash.select{|k, v| k.to_s.start_with? 'list'}
			childFormEntityHash.each do |key, childFormEntities|
				childStoredEntities = storedEntityHash[key]
				if childStoredEntities
					childFormEntities.each do |eachFormEntity|
						addChild = true
						childStoredEntities.each do |eachStoredEntity|
							if eachStoredEntity[:object] == eachFormEntity[:object]
								merge_hash(eachFormEntity, eachStoredEntity)
								addChild = false
								break
							end
						end
						#Adding handling for cases where a new child is added to existing list.
						if addChild
							storedEntityHash[key].push eachFormEntity
						end
					end
				else
					#Adding handling for cases where a new child list is added.
					storedEntityHash[key] = childFormEntities
				end
			end
			return storedEntityHash
		end
		##################################################################################################


		def self.convertToObject(className, hash,parentObj = nil,loadChildren=true)
			object = Object.const_get(className).new
			object.parentBaseDO = parentObj if parentObj
			modelSource = Rho::RhoConfig.sources[className]
			attrToSendList = Object.const_get(className).instance_methods(false)

			hash.each do |key,value|
				if value.is_a? Hash
					if loadChildren
						value.each do |innerKey, innerValue|
							child = convertToObject(key,innerValue,object)
							methodName = ("add" + key.to_s).to_sym
							object.send(methodName, child)
						end
					end
				elsif Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1' and value.is_a? Array
					next
				else
					next unless value if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
					value = value.join(",") if value.is_a? Array
					# next if value == ""
					# modelSource = Rho::RhoConfig.sources[className]
					properties = modelSource["schema"]["property"][key]
					methodName = "#{key}=".to_sym
					value.gsub!("&apos;","'") if value.is_a? String
					val = value
					if properties
						if properties[0] and (properties[0] == :integer or properties[0] == :float or properties[0] == :double) and value.to_s != ""
							value = value.gsub(",", "") if value.is_a? String
							if properties[0] == :integer
								value = value.to_i
							else
								value = value.to_f
							end
						elsif properties[0] && (properties[0] == :date or properties[0] == :time) && value.to_s != ""
							begin
								if value.is_a?(Integer)
									value = Time.at(value/1000)
								else
									Time.parse(value.to_s)
									dateParts = value.split(/[\-\/ :]/)
									if dateParts[2].length < 3
										value = Time.new(dateParts[0].to_i,dateParts[1].to_i,dateParts[2].to_i,dateParts[3].to_i,dateParts[4].to_i,dateParts[5].to_i)
									else
										value = Time.new(dateParts[2].to_i,dateParts[1].to_i,dateParts[0].to_i,dateParts[3].to_i,dateParts[4].to_i,dateParts[5].to_i)
									end
								end
							rescue Exception => e
								value = ""
							end
							value = value.to_s
						end
					end
					if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1'
						object.send(methodName, value) if modelSource["schema"]["property"].has_key?(key.to_s) || (key.to_s == 'object' && value.to_s != "")
					else
						object.send(methodName, value)
					end
				end
			end

			#To set attr_accessors of Party if API
			if Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1' and attrToSendList
				attrToSendList.each do |att|
					next if att.to_s=='source_id'
					if hash.has_key?(att.to_s) && !hash[att.to_s].nil? && (!hash[att.to_s].is_a?(Array) && !hash[att.to_s].is_a?(Hash) || (className.to_s == "PolicyPartyContainer"))
					# if hash&.has_key?(att.to_s) && !hash[att.to_s].nil?
						attMethodName = "#{att}="
						object.send(attMethodName, hash[att.to_s])
					end
				end
			end
			return object
		end
		##################################################################################################


		#Returns a collection of data objects which needs to be iterated over to 'persist' in the database.
		#Calls internally convertToObject method to collect the objects
		def self.convertToObjectList(className, hash)
			collected_obj_list = []
			hash.each_with_index do |(key, value), i|
				if value.is_a? Hash
					listObject = convertToObject(className, value)
					collected_obj_list << listObject
				end
			end
			return collected_obj_list
		end
		##################################################################################################


		def geo_callback
			@@lat = 0
			@@long = 0

			if @params['status'] =='ok'
				#GeoLocation.set_notification '', '', 2
				#WebView.navigate url_for(:action => :map_all)
				@@lat = GeoLocation.latitude
				@@long = GeoLocation.longitude
				#Alert.show_status("Geo location callback", "Geo location received with lat #{@@lat} and long #{@@long}", "OK")
			end
		end
		##################################################################################################


		def reEvaluateContext
	        evalHashGuid = @params['guid'].to_s
	        #get all the context masters for the current object and attribute only (excluding the parents) to reEvaluate the context name and replace it in the global context map
	        id = @params['id'].to_s
	        value = @params['value'].to_s
	        attrName = id.include?("_") ? id[id.rindex('_')+1..-1].to_s : ""
	        if $contextMasterEvalHash[evalHashGuid].size > 0
	        	$contextMasterEvalHash[evalHashGuid].each do |contextMaster|
	        		if contextMaster["fieldName"].to_s == attrName
	        			className = contextMaster["className"].to_s.gsub("DO","")
	        			expression = contextMaster["contextNameExpression"].to_s
	        			objClass = Object.const_get(className)
						obj = objClass.new
						begin
							exp = 'obj.'+attrName.to_s+"='"+value.to_s.gsub("'","\\\\'")+"'"
							eval(exp)
						rescue StandardError => boom
							puts boom
						end
						newContextName = MobiSys::ContextMasterData.evaluateContextField(obj,attrName,expression)
						contextMaster["contextName"] = newContextName.to_s
	        		end
	        	end
	        end
	    end

	    #Method to evaluate the metadata for a given object based on its applicable context.
	    def evaluateMetadata
	        evalHashGuid = @params['guid'].to_s
	        metaDataCd = @params['metaDataCd'].to_s
	        id = @params['id'].to_s
	        @currentApplicableContexts = []
	        label = ""
			visibility = true
			enabled = true
			minOccurs = ""
			maxlength = ""
			minlength = ""

	        @currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym }
        	evalHashGuid = $parentChildGuidMapping[evalHashGuid]
			#while loop to add all the contexts of the parent classes except the top most parent.
			if $parentChildGuidMapping[evalHashGuid]
				while $parentChildGuidMapping[evalHashGuid] do
					@currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym }
					evalHashGuid = $parentChildGuidMapping[evalHashGuid]
				end
				#To include the Contexts of the Main class (Grandparent) since the Global hash will not have it as a key $parentChildGuidMapping[evalHashGuid] condition in the while loop will fail for the top most parent class.
				@currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym }
			end
	        @currentApplicableContexts.flatten!
			if $uiMetaDataCache.has_key?(metaDataCd.to_sym)
				uiMetaDataDOList = $uiMetaDataCache[metaDataCd.to_sym]
				ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, @currentApplicableContexts,"array")
				label = (ui == nil ? "" : ui.propertyValue.to_s)

				ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts,"array")
				visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

				ui = MobiSys::UIMetaData.getUiMetadataPropDO("ENABLED", uiMetaDataDOList, @currentApplicableContexts,"array")
				enabled = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
				# enabled = isReadOnly if isReadOnly

				ui = MobiSys::UIMetaData.getUiMetadataPropDO("MAXLENGTH", uiMetaDataDOList, @currentApplicableContexts)
				maxlength = (ui == nil ? "" : ui.propertyValue.to_s)

				ui = MobiSys::UIMetaData.getUiMetadataPropDO("MINLENGTH", uiMetaDataDOList, @currentApplicableContexts)
				minlength = (ui == nil ? "" : ui.propertyValue.to_s)
			end
			metaDataCdDOName = metaDataCd.index(".") != nil ? metaDataCd.split(".")[0] : ""
			if $validationHash.has_key?(metaDataCdDOName.to_sym)
				validationMetaDataDOList = $validationHash[metaDataCdDOName.to_sym]
				val = MobiSys::Validation.getValidationDO("MINOCCURS", validationMetaDataDOList, @currentApplicableContexts, metaDataCd)
				minOccurs = (val == nil ? "" : val.validationParam.to_s)
			end


			#label related code start
			strClass = "col-left "
			strVisibility = ""
			unless visibility
				strVisibility = "style=\"display: none;\" "
			else
				strVisibility = ""
			end
			toreturn_str = ""
			strClass = strClass + "mandatorylabel" if minOccurs.to_i > 0
			# only if the label tag is required add it else plain html.
			toreturn_str << "<p class=\"#{strClass}\" #{strVisibility} id=\"#{id}_lbl\" for=\"#{id}\">"
			toreturn_str << getLabelValue(label)
			toreturn_str << "<span id=\"#{id}_lblsm\" class=\"mandatory\">*</span>" if minOccurs.to_i > 0 && visibility

			tooltipText = getToolTipValue(label.to_sym)
			if tooltipText.strip.to_s != "" && tooltipText.strip.to_s != "null"
				toreturn_str << "<span class=\"tooltip\">"
				toreturn_str << "<i class='icon-questioninfo'></i>"
				toreturn_str << "<span class='tooltiptext'>#{tooltipText}</span>"
				toreturn_str << "</span>"
			end
			toreturn_str << "</p>"
			#label related code end
	        returnHash = Hash.new
	        returnHash["metaDataCd"] = metaDataCd
	        returnHash["label"] = toreturn_str
			returnHash["visibility"] = visibility
			returnHash["enabled"] = enabled
			returnHash["minOccurs"] = minOccurs
			returnHash["maxlength"] = maxlength
			returnHash["minlength"] = minlength
			render :string => returnHash.to_json
	    end

		#Deepali Singh: 01/03/2016 - Added configurable dimensions setting
		def takePicture
			cameraCallback = :camera_callback
			containerId = ""
			@@persistOcr = false
			@@controllerName = @request['model']
			if @params.has_key?("isOcr") && @params["isOcr"] == "true"
				cameraCallback = :camera_callback_ocr
				@@containerId = @params["containerId"] if @params.has_key?("containerId")
			elsif (@params.has_key?("persistOcr") && @params["persistOcr"].to_s == "true")
				@@persistOcr = true
			end
			@choosePicture = false
			@choosePicture = true if @params.has_key?("choosePicture") && @params["choosePicture"] == "true"

			@@parentRefGuid = @params['parentRefGuid']
			if !@choosePicture
				mainCameraInfo = Camera::get_camera_info("main")
				frontCameraInfo = Camera::get_camera_info("front")

			if $rhoconfig[:default_image_dimension] != nil
				dimensionParts = $rhoconfig[:default_image_dimension].split("x")

				if dimensionParts[0] != nil
					width = dimensionParts[0]
				else
					width = 960
				end

				if dimensionParts[1] != nil
					height = dimensionParts[1]
				else
					height = 720
				end

				if dimensionParts[2] != nil && ( dimensionParts[2] == "Grayscale" || dimensionParts[2] == "RGB")
					colorModel = dimensionParts[2]
				else
					colorModel = "Grayscale"
				end
			else
				width = 960
				height = 720
				colorModel = "Grayscale"
			end
				p "height: #{height} width: #{width}"
				options_hash = Hash.new
				#Deepali Singh: 01/03/2016- android and iOS expect different keys for setting height and width of the image (CameraSettings.java and PickImageDelegate.m)

				options_hash = {"camera_type" => "main","color_model" => colorModel, 'desired_width' => width, 'desired_height' => height, 'desiredWidth' => width, 'desiredHeight' => height, 'saveToDeviceGallery' => 'false','enableEditing' => false  }
				if mainCameraInfo == nil
					frontCameraInfo = Camera::get_camera_info("front")
					# puts "No Main Camera"
					options_hash = Hash.new
					options_hash = {"camera_type" => "front","color_model" => colorModel, 'desired_width' => width, 'desired_height' => height, 'desiredWidth' => width, 'desiredHeight' => height ,'enableEditing' => false}
					if frontCameraInfo == nil
						puts "No Front Camera"
					end
				end
			end
			if System.get_property('is_emulator') || @choosePicture
				Camera::choose_picture(url_for(:action => cameraCallback))
			else
				Camera::take_picture(url_for(:action => cameraCallback),options_hash)
			end
		end
		##################################################################################################


		def camera_callback
			fileName = nil
			if @params['status'] == 'ok'
				if @params['filePath'].to_s != ""
					image_uri = @params['filePath']
				else
					#create image record in the DB
					image_uri = @params['image_uri']
					#Deepali Singh: 04/12/2016- rhodes-oss returns filepath in imageUri variable instead of image_uri
					image_uri = @params['imageUri'] if image_uri.to_s == ""
				end

				image = Image.new
				offlineFile = OfflineFile.new
				image.parentRefGuid = @@parentRefGuid
				if ((System::get_property('platform') == 'ANDROID') || (System::get_property('platform') == 'APPLE') || (System::get_property('platform') == "WINDOWS_DESKTOP"))
					image.dateTimeTaken = Time.now
					fileExtension = image_uri.split("#{File::SEPARATOR}").last.split('.').last

					devSeqObj = Application.getValue(MobiSys::DEVICESEQ)
					deviceSeq = devSeqObj ? devSeqObj.value : ''
					fileName = "#{Time.now.to_i}_#{$userId}_#{deviceSeq}.#{fileExtension}"
					if @params['filePath'].to_s != ""
						realFileLocation = @params['filePath']
					else
						#Deepali Singh: 04/12/2016- rhodes-oss returns filepath in imageUri variable instead of image_uri
	        			Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
	        			realFileLocation = Rho::RhoApplication.get_blob_path(image_uri)
	        		end
        			puts "Captured Image uri:: #{image_uri} fileName: #{fileName} realFileLocation: #{realFileLocation}"

					imageSize = File.size(realFileLocation)
					if !(defined?(@@lat)).nil? && !(defined?(@@long)).nil? && $rhoconfig.has_key?(:image_location_enabled) and $rhoconfig[:image_location_enabled]=='YES'
						image.latitude = @@lat
						image.longitude = @@long
					end
					encodedContent = ""
					#encrypt_images flag removed from rhoconfig.txt/settings.erb. Following code to check for encrypting camera images & quotation signature is kept if required in future
					if $rhoconfig.has_key?(:encrypt_images) and $rhoconfig[:encrypt_images]=='YES'
						bytes = nil
						File.open(realFileLocation,"rb") do |file|
					        bytes = file.read
					    end
						encodedContent = MobiSys::Encryption.encryptContent(bytes)
						parts = encodedContent.rpartition('|')
						offlineFile.fileContents = parts[0]
						offlineFile.encryptionIv = parts[2]
						offlineFile.fileEncrypted = 'YES'
					else
						encodedContent = MobiSys::Encryption.encodeFileContents(realFileLocation)
						offlineFile.fileEncrypted = 'NO'
						offlineFile.fileContents = encodedContent
					end
					# just saving fileName in fileLocation
					offlineFile.fileLocation = fileName

					offlineFile.md5Hash = MobiSys::Encryption.digest(offlineFile.fileContents)
					if $rhoconfig.has_key?(:image_size_limit)
						maxSize = ($rhoconfig[:image_size_limit].to_f).round(2)
						if (imageSize / 1000).round(2) > maxSize
							Alert.show_popup({
		                        :message => getLabelValue('ERR_IMAGE_SIZE_LIMIT', [maxSize.to_i.to_s]),
		                        :title => '',
		                        :icon => :info,
		                        :buttons => ["OK"]
	                        })
							File.delete(realFileLocation) if File.exists?(realFileLocation) && !@choosePicture
							return
						end
					end
					image.addOfflineFile offlineFile
					image.persistAll

					# Delete image file from location once record persisted in db
					File.delete(realFileLocation) if File.exists?(realFileLocation) && !@choosePicture

					begin
						imageCaptured(image)
						if @@persistOcr
							if ((System::get_property('platform') == 'ANDROID') || (System::get_property('platform') == 'APPLE') || (System::get_property('platform') == "WINDOWS_DESKTOP"))
								# Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
								# realFileLocation = Rho::RhoApplication.get_blob_path(image_uri)
								@@imageBase64 = encodedContent
								@@offlineFile = offlineFile
								# Delete image file from location once record persisted in db
								# File.delete(realFileLocation) if File.exists?(realFileLocation)
								extractedData = MobiSys::BrowserHelper.documentTextDetection(@@imageBase64, false, nil, "updateOcrExtractedText")
							end
						end
					rescue NoMethodError => nme
						#Ignore. Calling controller has not implemented imageCaptured(image) method
					end
				end
			elsif @parms["status"].to_s == "extnotsupported"
				Alert.show_popup({
		            :message => getLabelValue('extnotsupported'),
                    :title => getLabelValue('error'),
                    :buttons => ["OK"]
                })
			end
		end
		##################################################################################################

		def updateOcrExtractedText(extractedData = nil)
			if extractedData == nil
				extractedData = @params['extractedData']
			end
			if @@offlineFile
				offlineFile = OfflineFile.loadObject(:first, :conditions=>{'object'=>@@offlineFile.object})
				offlineFile.ocrExtractedText = extractedData
				offlineFile.persistAll
				@@offlineFile = nil
				@@imageBase64 = nil
			end
		end
		##################################################################################################

		def pickDocument
			@@parentRefGuid = @params['parentRefGuid']
			Rho::DocumentPicker.pickDocument($rhoconfig[:applicable_doc_extensions],url_for(:action => :camera_callback))
		end
		##################################################################################################


		def renderSmsLink(phoneNumber, description=nil, image=false)
			if description == nil
				description = phoneNumber
			end
			html = "<a href=\"sms:#{phoneNumber}\">"
			if image
				html << "<img src = \"/public/images/SalesIllustration/sms.png\">"
			end
			html << description
			html << "</a>"

			return html
		end
		##################################################################################################


		def renderCallLink(phoneNumber,description=nil, image=false)
			if description == nil
				description = phoneNumber
			end
			html = "<a href=\"tel:#{phoneNumber}\">"
			if image
				html << "<img src = \"/public/images/SalesIllustration/call.png\">"
			end
			html << description
			html << "</a>"
			return html
		end
		##################################################################################################


		def renderEmailLink(email, description=nil, image=false)
			if description == nil
				description = email
			end
			html = "<a href=\"mailto:#{email}\">"
			if image
				html << "<img src = \"/public/images/SalesIllustration/email.png\">"
			end
			html << description
			html << "</a>"

			return html
		end
		##################################################################################################


		def renderErrorList(errors)
			errorsParse = errors
			toreturn_str = ""
			return toreturn_str unless errorsParse
			toreturn_str << "<ul>"
			errorsParse.each do |key, hash|
				#puts "this is the key #{key} this is hash #{hash}"
				hash.each do |key1,value|
					if value != nil
						value.each do |errorlist|
							if errorlist!= nil
								toreturn_str << "<li>" << errorlist.to_s.force_encoding("UTF-8") << '</li>'
							end
						end
					end
				end
			end
			toreturn_str << "</ul>"
			return toreturn_str
		end
		##################################################################################################


		def renderErrorTag(msg,errors,formname)
			toreturn_str = ""
			toreturn_str = toreturn_str.to_s.force_encoding("UTF-8")
			begin
				if msg ==nil and errors==nil and formname==nil
					return ""
				end

				if msg!=nil
					toreturn_str << "<legend>" << Localization::LabelCache.instance.getLabel(msg.to_sym).to_s.force_encoding("UTF-8") << "</legend>"
				end

				# toreturn_str << "<font color='red'>"
				toreturn_str << "<ul>"
				eval(errors).each_pair do |key,value|
					if value != nil
						value.each do |error|
							toreturn_str << "<li>" << error.to_s.force_encoding("UTF-8") << '</li>'
						end
					end
				end
				# toreturn_str << "</font>"
				toreturn_str << "</ul>"
				# if errors!=nil and formname!=nil
				#   toreturn_str << " <script>"
				#   toreturn_str << " mark_errors(\"#"+formname+"\", "+errors.tr("\"", "'").tr("=>", ": ")+");"
				#   toreturn_str << " </script>"
				# end
			rescue StandardError => se
				puts se
				toreturn_str << "</font>"
			end

			return toreturn_str
		end
		##################################################################################################


		def getObjectCount(object)
			$objectCount[object.object.to_s]
		end
		##################################################################################################


		def setObjectCount(object, count)
			if object != nil
				$objectCount[object.object.to_s] = count
			end
		end
		##################################################################################################


		def setObjectMapping(object, name)
			if object != nil
				$objectMapping[object.object.to_s] = name
			end
		end
		##################################################################################################


		def resetObjectMapping
			$objectMapping = Hash.new
			$objectCount = Hash.new
		end
		##################################################################################################


		def getObjectMapping(object)
			toreturn_str = ""
			begin
				toreturn_str << $objectMapping[object.object.to_s]
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		# render object mapping on the screen
		# 1. render object id on screen
		def renderObject(object, parent=nil, count=nil)
			toreturn_str = ""
			begin
				if parent != nil
					#Condition for checking if the render object is an arrry list. If yes add count to class name.
					if count != nil
						$objectMapping[object.object.to_s] = "#{object.class.name}[#{count}]"
					else
						$objectMapping[object.object.to_s] = $objectMapping[parent.object.to_s].to_s+"["+object.class.name+"]["+$objectCount[parent.object.to_s].to_s+"]"
					end
					#puts $objectMapping[parent].to_s
					#puts ">>>Object mapping found is #{parent.to_s}: #{$objectCount[parent.to_s]}"
					# the object id for the object in question
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\""+$objectMapping[object.object.to_s]+"[object]\" "
					toreturn_str << "value=\""+object.object.to_s+"\" />"

					if object.uniqueKey.to_s != ""
						# the guid for the object in question
						toreturn_str << "<input type=\"hidden\" "
						toreturn_str << "name=\""+$objectMapping[object.object.to_s]+"[guid]\" "
						toreturn_str << "value=\"" + object.uniqueKey.to_s + "\" />"
					end
					#Deepali Singh: 26/01/2016 - Setting systemcreatedDt in hidden field
					if object.systemCreatedDt.to_s == ""
						toreturn_str << "<input type=\"hidden\" "
						toreturn_str << "name=\""+$objectMapping[object.object.to_s]+"[systemCreatedDt]\" "
						toreturn_str << "value=\"" + Time.now.to_s + "\" />"
					end

					# the name to be used for objects with this id
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\""+object.object.to_s+"\" "
					toreturn_str << "value=\""+$objectMapping[object.object.to_s]+"\" />"
					if parent == 'UserActivity'
						$objectCount[parent.to_s] = $objectCount[parent.to_s].to_i + 1
					else
						$objectCount[parent.object.to_s] = $objectCount[parent.object.to_s].to_i + 1
					end
					$objectCount[object.object.to_s] = 0
				else # if parent == nil
					#resetObjectMapping()

					# the object id for the object in question
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\""+object.class.name+"[object]\" "
					toreturn_str << "value=\""+object.object.to_s+"\" />"

					#Deepali Singh: 26/01/2016 - Setting systemcreatedDt in hidden field
					if object.systemCreatedDt.to_s == ""
						toreturn_str << "<input type=\"hidden\" "
						toreturn_str << "name=\""+object.class.name+"[systemCreatedDt]\" "
						toreturn_str << "value=\"" + Time.now.to_s + "\" />"
					end

					# the object id for the object in question
					if object.uniqueKey.to_s != ""
						toreturn_str << "<input type=\"hidden\" "
						toreturn_str << "name=\""+object.class.name+"[guid]\" "
						toreturn_str << "value=\"" + object.uniqueKey.to_s + "\" />"
					end

					# the name to be used for objects with this id
					toreturn_str << "<input type=\"hidden\" "
					toreturn_str << "name=\""+object.object.to_s+"\" "
					toreturn_str << "value=\""+object.class.name+"\" />"

					$objectMapping[object.object.to_s] = object.class.name
					$objectCount[object.object.to_s] = 0
				end # parent exists check
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		#date = yyyy-MM-dd hh:mm:ss.sss
		#screenDate = dd/MM/YYYY
		def getDBDate(screenDate)
			if screenDate != nil && screenDate != "" && screenDate.is_a?(String)
				dateParts = screenDate.split(/[\-\/ ]/)
				if dateParts[2].length < 3
					screenDate = Time.new(dateParts[0].to_i,dateParts[1].to_i,dateParts[2].to_i)
				else
					screenDate = Time.new(dateParts[2].to_i,dateParts[1].to_i,dateParts[0].to_i)
				end
			elsif screenDate.to_s != "" && screenDate.is_a?(Integer)
				screenDate = Time.at(screenDate)
			end
			return screenDate
		end
		##################################################################################################


		#date = yyyy-MM-dd hh:mm:ss.sss
		#screenDate = dd/MM/YYYY
		def getScreenDate(date)
			screenDate = ""
			if (date.to_s.include? ".") && (date.to_s.include? "+")
				dateTimeParts = date.split(" ")
				dateParts = dateTimeParts[0].to_s() +" " + dateTimeParts[1].to_s()
				screenDate = Time.strptime(dateParts, "%Y-%m-%d %H:%M:%S.%L").strftime('%d/%m/%Y')
			elsif  date.to_s.include? "."
				screenDate = Time.strptime(date, "%Y-%m-%d %H:%M:%S.%L %z").strftime('%d/%m/%Y')
			elsif  date.to_s.include? ":"
				screenDate = Time.strptime(date, "%Y-%m-%d %H:%M:%S %z").strftime('%d/%m/%Y')
			else
				if date.to_s != "" && date != nil #.to_s.match(/\d+/).to_s==date.to_s
					screenDate = getDBDate(date).strftime("%d/%m/%Y")
				else
					screenDate= date
				end
			end
			return screenDate
		end
		##################################################################################################


		#datetime = yyyy-MM-dd hh:mm:ss.sss
		#screenDateTime = dd/MM/YYYY hh:mm p
		def getDBDateTime(screenDateTime)
			dateTime = nil
			if screenDateTime != nil && screenDateTime != ""
				dateTimeParts = screenDateTime.split(" ")
				if dateTimeParts[0].include?("/")
					dateParts = dateTimeParts[0].split("/")
				else
					dateParts = dateTimeParts[0].split("-")
				end
				offset = dateTimeParts[2]
				offset = Time.now().strftime('%z') unless offset
				timeParts = Time.parse(dateTimeParts[1] + " " + offset).strftime("%H:%M:%S").split(":")
				dateTime = Time.new(
					dateParts[0].to_i,
					dateParts[1].to_i,
					dateParts[2].to_i,
					timeParts[0].to_i,
					timeParts[1].to_i,
					timeParts[2].to_i
				)
			end
			return dateTime
		end
		##################################################################################################


		#datetime = yyyy-MM-dd hh:mm:ss.sss
		#screenDateTime = dd/MM/YYYY hh:mm p
		def getScreenDateTime(dateTime)
			screenDateTime = ""
			if dateTime != nil && dateTime != ""
				screenDate = Time.strptime(dateTime, "%Y-%m-%d %H:%M:%S %z").strftime('%d/%m/%Y %H:%M:%S')
			end
			return screenDate
		end
		##################################################################################################


		# en = dd/MM/yyyy
		# th = dd/MM/yyyy+543
		def getThaiDate(enDate)
			thDate = ""
			if enDate != nil && enDate != ""
				dateParts = enDate.split("/")
				thDate << dateParts[0] << "/"
				thDate << dateParts[1] << "/"
				thDate << (dateParts[2].to_i+543).to_s
			end
			return thDate
		end
		##################################################################################################


		# th = dd/MM/yyyy
		# en = dd/MM/yyyy-543
		def getEnglishDate(thDate)
			enDate = ""
			if thDate != nil && thDate != ""
				dateParts = thDate.split("/")
				enDate << dateParts[0] << "/"
				enDate << dateParts[1] << "/"
				enDate << (dateParts[2].to_i-543).to_s
			end
			return enDate
		end
		##################################################################################################


		#<label for="quotation[quotationSeq]" class="fieldLabel">Quotationseq</label>
		def renderLabel(id, labelKey, styleClass=nil,object = nil, adhocContent=nil)
			toreturn_str = ""
			tostrMandatory = ""
			begin
				toreturn_str << "<label "
				tostrMandatory << ""
				if id!=nil
					if object !=nil
						toreturn_str << "for=\""+$objectMapping[object.object.to_s]+"["+id+"]\" "
					else
						toreturn_str << "for=\""+id+"\" "
					end
				end

				if styleClass!=nil
					if styleClass == "mandatory"
						tostrMandatory <<   renderLabel(' *','&nbsp;*','mandatory1',nil)
						toreturn_str << "class=\"fieldLabel ui-input-text\""
					else
						toreturn_str << "class=\""+styleClass+"\""
					end
				elsif
					toreturn_str << "class=\"fieldLabel ui-input-text\""
				end

				if adhocContent != nil
					toreturn_str << adhocContent <<" "
				end

				toreturn_str << " >"
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
				toreturn_str << tostrMandatory
				toreturn_str << "</label>"
			rescue StandardError => se
				puts "In renderLabel rescue #{se}"
			end
			return toreturn_str
		end
		##################################################################################################


		#<label for="quotation[quotationSeq]" class="fieldLabel">Quotationseq</label>
		def renderQuestionnaireLabel(id, labelKey, styleClass=nil,object = nil)
			toreturn_str = ""
			begin
				toreturn_str << "<label "
				if id!=nil
					if object !=nil
						toreturn_str << "for=\""+$objectMapping[object.object.to_s]+"["+id+"]\" "
					else
						toreturn_str << "for=\""+id+"\" "
					end
				end

				if styleClass!=nil
					toreturn_str << "class=\""+styleClass+"\">"
				elsif
					toreturn_str << "class=\"questionnairefieldLabel ui-input-text\">"
				end
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
				toreturn_str << "</label>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		def renderReflexiveQuestionnaireLabel(id, labelKey, styleClass=nil,object = nil)
			toreturn_str = ""
			begin
				toreturn_str << "<label "
				if id!=nil
					if object !=nil
						toreturn_str << "for=\""+$objectMapping[object.object.to_s]+"["+id+"]\" "
					else
						toreturn_str << "for=\""+id+"\" "
					end
				end

				if styleClass!=nil
					toreturn_str << "class=\""+styleClass+"\">"
				elsif
					toreturn_str << "class=\"questionnairefieldLabelindented\">"
				end
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
				toreturn_str << "</label>"
			rescue StandardError => se
				puts se
			end

			return toreturn_str
		end
		##################################################################################################

		def getOfflineLookupData(lookupKey, filterCondition,lookupDataCd = nil, offline_lookup_m = nil)
			offline_lookup_m = OfflineLookupM.find(:first,:conditions => {:lookupKey => lookupKey}) if offline_lookup_m == nil
			selectLookup = []
			lookups = []
			if offline_lookup_m
				partition = offline_lookup_m.offlineDBPartition.to_s != '' ? offline_lookup_m.offlineDBPartition.to_s : 'master'
				db = Rho::Database.new(Rho::Application.databaseFilePath(partition),partition)
				db.start_transaction
				if offline_lookup_m.lookupDataSortOrderName.to_s != ""
					sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName}, #{offline_lookup_m.lookupDataSortOrderName} as sortingKey FROM #{offline_lookup_m.lookupEntityName} "
				else
					sql = "SELECT #{offline_lookup_m.lookupDataCodeName}, #{offline_lookup_m.lookupDataDescName} FROM #{offline_lookup_m.lookupEntityName} "
				end
				filterCriteria = offline_lookup_m.lookupFilterCriteria.to_s
				filterCondition.each do |key,value|
					if filterCriteria.include?("$#{key}")
						filterCriteria.gsub!("$#{key}", value.to_s)
					else
						filterCriteria << " and " if filterCriteria.to_s != ""
						filterCriteria << " #{key} = '#{value.to_s}' "
					end
				end
				sql << "WHERE #{filterCriteria} " if filterCriteria.to_s != ""
				sql << "ORDER BY #{offline_lookup_m.lookupDataSortOrderName}" if offline_lookup_m.lookupDataSortOrderName.to_s != ""
				results = db.execute_sql(sql)
				db.commit
				#if lookupDataCd is passed then only fetch the description of selected offline lookup cd.
				if lookupDataCd != nil
					results.each do |result|
						if lookupDataCd.to_s == result.values[0].to_s
							selectLookup = getLabelValue(result.values[1].to_s)
							break
						end
					end
				else
					results.each do |result|
						tempLookup = Lookupvalue.new
						tempLookup.cd = result.values[0].to_s
						tempLookup.desc = getLabelValue(result.values[1].to_s)
						tempLookup.sortOrder = result.values[2].to_s if offline_lookup_m.lookupDataSortOrderName.to_s != "" && result.values[2]
						lookups.push tempLookup
					end
				end
			else
			#if lookupDataCd is passed then only fetch the description of selected lookup cd.
				if lookupDataCd != nil
					selectLookup = Lookupvalue.getLookupValue(lookupKey,lookupDataCd)
				else
					lookups = Lookupvalue.getValue(lookupKey)
				end
			end
			#will not go here in case of getting description since lookups array will be empty during this flow.
			if lookups && lookups.size > 0
				sortByOrderLookups,remainingLookups = lookups.partition{|lookup| lookup.sortOrder.to_s != ""}
				sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
				remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
				selectLookup = sortByOrderLookups.concat remainingLookups
			end
			return selectLookup
		end

		# fetch label values
		def getLabelValue(labelKey, errorParameters=[])
			toreturn_str = ""
			begin
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
			rescue StandardError => se
				puts se
			end
			toreturn_str = MobiSys::CommonUtil.replacePlaceHolders(toreturn_str,errorParameters) if errorParameters.compact.any?
			return toreturn_str
		end
		##################################################################################################


		def getToolTipValue(labelKey, errorParameters=[])
			toreturn_str = ""
			begin
				toreturn_str << Localization::LabelCache.instance.getLabelToolTipValue(labelKey.to_sym)
			rescue StandardError => se
				puts se
			end
			toreturn_str = MobiSys::CommonUtil.replacePlaceHolders(toreturn_str,errorParameters) if errorParameters.compact.any?
			return toreturn_str
		end
		##################################################################################################


		def getlabelValueExtra(labelKey, errorParameters=[])
			toreturn_str = ""
			begin
				toreturn_str << Localization::LabelCache.instance.getlabelExtraValue(labelKey.to_sym)
			rescue StandardError => se
				puts se
			end
			toreturn_str = MobiSys::CommonUtil.replacePlaceHolders(toreturn_str,errorParameters) if errorParameters.compact.any?
			return toreturn_str
		end
		##################################################################################################


		def self.getLabel(labelKey)
			toreturn_str = ""
			begin
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		def renderTextArea(id,value,placeholdervalue,object = nil, adhocContent=nil)
			toreturn_str = ""
			begin
				toreturn_str << "<textarea "
				name = ""
				if id!=nil
					if object !=nil
						name = $objectMapping[object.object.to_s]+"["+id+"]"
						toreturn_str << "name=\""+name+"\" "
						toreturn_str << "id=\""+name+"\" "
					else
						name = id
						toreturn_str << "name=\"#{name}\" "
						toreturn_str << "id=\"#{name}\" "
					end
				end

				if adhocContent != nil
					toreturn_str << adhocContent <<" "
				end

				toreturn_str << ">"
				toreturn_str << value.to_s
				toreturn_str << "</textarea>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		# <input type="text" id="quotation[quotationSeq]" name="quotation[quotationSeq]" value="<%= @quotation.quotationSeq %>" <%= placeholder( "Quotationseq" ) %> />
		def renderInputField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"text",object, nil, adhocContent)
		end
		##################################################################################################


		def renderQuestionnaireInputField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"text",object, 'questionnaireInputField', adhocContent)
		end
		##################################################################################################


		def renderEmailField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"email",object, "", adhocContent)
			# return renderTextField(id,value,placeholdervalue,"text",object, nil, adhocContent)
		end
		##################################################################################################


		def renderTelephoneField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"tel",object, "", adhocContent)
		end
		##################################################################################################


		def renderCountField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, value, placeholdervalue, "number", object, "countField", adhocContent)
		end
		##################################################################################################


		def renderQuestionnaireCountField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, value, placeholdervalue, "number", object, "questionnaireCountField", adhocContent)
		end
		##################################################################################################


		def renderPreciseAmountField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, value, placeholdervalue, "number", object, "amountField", adhocContent)
		end
		##################################################################################################


		def renderAmountUpto2DecimalField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, renderDecimalUpto2Places(value), placeholdervalue, "number", object, "amountField", adhocContent)
		end
		##################################################################################################


		def renderPreciseQuestionnaireAmountField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, value, placeholdervalue, "number", object, "questionnaireAmountField", adhocContent)
		end
		##################################################################################################


		def renderRangeField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, renderInt(value), placeholdervalue, "range", object, nil, adhocContent)
		end
		##################################################################################################


		def renderAmountField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id, value, placeholdervalue, "number", object, "amountField", adhocContent)
			# return renderTextField(id, value, placeholdervalue, "text", object, "amountField", adhocContent)
		end
		##################################################################################################


		def renderNumericField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			html = renderTextField(id, value, placeholdervalue, "number", object, nil, adhocContent)
			return html
		end
		##################################################################################################


		def self.checkNil(val)
			outVal=val
			if val==nil
				outVal=""
			end
			return outVal
		end
		##################################################################################################


		# <input type="password" id="quotation[quotationSeq]" name="quotation[quotationSeq]" value="<%= @quotation.quotationSeq %>" <%= placeholder( "Quotationseq" ) %> />
		def renderPasswordField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"password",object, nil, adhocContent)
		end
		##################################################################################################


		def renderCheckBox(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"checkbox",object, nil, adhocContent)
		end
		##################################################################################################


		def renderDateField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << renderTextField(id,value,placeholdervalue,"text",object, "dateField", adhocContent)

			if id!=nil
				if object !=nil
					nameVal=$objectMapping[object.object.to_s]+"["+id+"]"
				else
					nameVal=id
				end
			end

			unless System.get_property('platform') == 'WINDOWS_DESKTOP'
				toreturn_str << "\n"
				toreturn_str << "<img src =\"/public/images/icon-date_picker-huge.png\" class=\"datepickerimg\" onclick=\"captureDate('Enter date', $(this).siblings('input:visible').attr('name'));\"/>" <<"\n"
				toreturn_str << "<script>" << "\n"
				toreturn_str << "setReadOnly($('input[name=\""<< nameVal<<"\"]'), true);"<< "\n"
				toreturn_str << "</script>"<< "\n"
				toreturn_str << "\n"
			end
			return toreturn_str
		end
		##################################################################################################


		def renderTimeField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << renderTextField(id,value,placeholdervalue,"text",object, "dateField", adhocContent)

			if id!=nil
				if object !=nil
					nameVal=$objectMapping[object.object.to_s]+"["+id+"]"
				else
					nameVal=id
				end
			end

			toreturn_str << "\n"
			toreturn_str << "<img src =\"/public/images/icon-date_picker-huge.png\" class=\"datepickerimg\" onclick=\"captureTime('Enter time', $(this).siblings('input').attr('name'));\"/>" <<"\n"
			toreturn_str << "<script>" << "\n"
			toreturn_str << "setReadOnly($('input[name=\""<< nameVal<<"\"]'), true);"<< "\n"
			toreturn_str << "</script>"<< "\n"
			toreturn_str << "\n"
			return toreturn_str
		end
		##################################################################################################


		def renderDateTimeField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << renderTextField(id,value,placeholdervalue,"text",object, "dateTimeField", adhocContent)

			if id!=nil
				if object !=nil
					nameVal=$objectMapping[object.object.to_s]+"["+id+"]"
				else
					nameVal=id
				end
			end

			toreturn_str << "\n"
			toreturn_str << "<img src =\"/public/images/icon-date_picker-huge.png\" class=\"datepickerimg\" onclick=\"captureDateTime('Enter date and time', $(this).siblings('input').attr('name'));\"/>"<<"\n"
			toreturn_str << "<script>" << "\n"
			toreturn_str << "setReadOnly($('input[name=\""<< nameVal<<"\"]'), true);"<< "\n"
			toreturn_str << "</script>"<< "\n"
			toreturn_str << "\n"
			return toreturn_str
		end
		##################################################################################################


		def renderDateTimeJS
			toreturn_str = ""
			toreturn_str << "\n"
			toreturn_str << "<script>\n"
			toreturn_str << "function captureDateTime(title, fieldKey)\n"
			toreturn_str << "{\n"
			toreturn_str << "  $.get('/app/#{self.class.name.chomp('Controller')}/getDateTime', {title: title, fieldKey: fieldKey, datetime: $(fieldKey).val() });\n"
			toreturn_str << "  return false;\n"
			toreturn_str << "}"
			toreturn_str << "\n"
			toreturn_str << "function captureDate(title, fieldKey)\n"
			toreturn_str << "{\n //alert(fieldKey); \n"
			toreturn_str << "  $.get('/app/#{self.class.name.chomp('Controller')}/getDate', {title: title, fieldKey: fieldKey, datetime: $(fieldKey).val() });\n"
			toreturn_str << "  return false;\n"
			toreturn_str << "}"
			toreturn_str << "\n"
			toreturn_str << "function captureTime(title, fieldKey)\n"
			toreturn_str << "{\n"
			toreturn_str << "  $.get('/app/#{self.class.name.chomp('Controller')}/getTime', {title: title, fieldKey: fieldKey, datetime: $(fieldKey).val() });\n"
			toreturn_str << "  return false;\n"
			toreturn_str << "}\n"
			toreturn_str << "</script>"

			return toreturn_str
		end
		##################################################################################################


		def renderSignatureInlineField(id, object=nil, screen_width=nil,screen_height=nil, inline=nil)
			name_str = ""
			toreturn_str = ""
			signaturestr = ""
			if id!=nil
				if object !=nil
					name_str = $objectMapping[object.object.to_s]+"["+id+"]"
					toreturn_str << "name=\""+name_str+"\" "
					toreturn_str << "id=\""+name_str+"\" "
				else
					name_str = id
					toreturn_str << "name=\""+name_str+"\" "
					toreturn_str << "id=\""+name_str+"\" "
				end
			end
			signaturestr << "<div class='sigPad'>
			<ul class='sigNav'>"
			if inline
				signaturestr << "<li class='typeIt'><a href='#type-it' class='current'>Disable</a></li>
				<li class='drawIt'><a href='#draw-it'>Sign</a></li>"
			end
			signaturestr << "<li class='clearButton'><a href='#clear'>Clear</a></li>
			</ul>
			<div>
			<div class='typed'></div>
			<canvas style=\"background-color:#{ (object.send(id.to_sym).to_s=='')? '#b2b2b2' : '#990000' }\" class='pad' width='#{screen_width}' height='#{screen_height}'></canvas>
			<input type='hidden' #{toreturn_str} class='output' value=\"#{object.send(id.to_sym)}\">
			</div>
			</div>"
			return signaturestr
		end
		##################################################################################################


		def renderSignaturePopupField(id, object=nil, screen_width=nil, screen_height=nil, popup=nil, popup_object=nil, link_text='Signature Field')
			## Namrata added for testing
			abc = 'id'
			signaturestr = "<a id='#{abc}' href='##{popup_object}'>#{link_text}</a>
			<div style='display:none'>
			<div id='#{popup_object}'style='background-color:#b2b2b2;'>
			#{renderSignatureInlineField(id, object, screen_width, screen_height, popup)}
			</div>
			</div>"
			return signaturestr
		end
		##################################################################################################


		def renderSignaturePopupFieldForFNA(id, object=nil, screen_width=nil, screen_height=nil, popup=nil, popup_object=nil)
			signaturestr = "<a id='inline' data-role='button' href='##{popup_object}'>#{getLabelValue('SIGN')}</a>
			<div style='display:none'>
			<div id='#{popup_object}'>
			#{renderSignatureInlineFieldForFNA(id, object, screen_width, screen_height, popup)}
			</div>
			</div>"

			return signaturestr
		end
		##################################################################################################


		def renderSignatureInlineFieldForFNA(id, object=nil, screen_width=nil,screen_height=nil, inline=nil)
			name_str = ""
			toreturn_str = ""
			signaturestr = ""
			screen_width = screen_width.to_i + 30;
			if id!=nil
				if object !=nil
					name_str = $objectMapping[object.object.to_s]+"["+id+"]"
					toreturn_str << "name=\""+name_str+"\" "
					toreturn_str << "id=\""+name_str+"\" "
				else
					name_str = id
					toreturn_str << "name=\""+name_str+"\" "
					toreturn_str << "id=\""+name_str+"\" "
				end
			end
			signaturestr << "<div class='sigPad' style= \"width: 100%; height: 90%\">
			<ul class='sigNav' style=\"background-color:#ffffff; width:100%\">"
			if inline
				signaturestr << "<li class='typeIt'><a href='#type-it' class='current'>Disable</a></li>
				<li class='drawIt'><a href='#draw-it'>Sign</a></li>"
			end
			signaturestr << "<li class='clearButton'><a href='#clear'>Clear</a></li>
			</ul>
			<div>
			<div class='typed'></div>
			<canvas style=\"background-color:#{ (object.send(id.to_sym).to_s=='')? '#b2b2b2' : '#990000' }\" class='pad' width='#{screen_width}' height='#{screen_height}'></canvas>
			<input type='hidden' #{toreturn_str} class='output' value=\"#{object.send(id.to_sym)}\">
			</div>
			</div>"
			return signaturestr
		end
		##################################################################################################


		def returnAppHeightWeight(screen_str, factor)
			screen_str = (System.get_property(screen_str) * factor).round
			screen_str = "#{screen_str}px;"
			return screen_str
		end
		##################################################################################################


		def renderHiddenField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			return renderTextField(id,value,placeholdervalue,"hidden",object, nil, adhocContent)
		end
		##################################################################################################


		# generic method for rendering input fields
		#####################################################################
		# current implementation varies for apple and android devices.
		# For apple devices, the system will use the HTML input type features
		# For android devices, these features are not fully supported by Samsung devices.
		# Hence, the same has to manuall handled by MobiSys
		#####################################################################
		def renderTextField(id,value,placeholdervalue,type,object = nil, styleClass = nil, adhocContent=nil)
			#isManuallyHandled = (System::get_property('platform') == "ANDROID" || System::get_property('platform') == "APPLE")  && !(type == "hidden" || type == "checkbox" || type == "password" || type == "range")
			isManuallyHandled = (System::get_property('platform') == "ANDROID" || System::get_property('platform') == "APPLE" || System::get_property('platform') == "WINDOWS_DESKTOP") && !(type == "hidden" || type == "checkbox" || type == "password" || type == "" || type == "email" || type == "tel" || type == "number")

			toreturn_str = ""
			begin
				if type!=nil
					if !isManuallyHandled
						if type=="number"
							toreturn_str << "<input type='tel'"
						else
							toreturn_str << "<input type=\""+type+"\" "
						end
					else # if isManuallyHandled
						toreturn_str << "<input type=\"text\" "
					end
				else
					type="text"
					toreturn_str << "<input type=\"text\" "
				end

				name = ""
				if id!=nil
					if object !=nil
						name = $objectMapping[object.object.to_s]+"["+id+"]"
						toreturn_str << "name=\""+name+"\" "
						toreturn_str << "id=\""+name+"\" "
					else
						name = id
						toreturn_str << "name=\""+name+"\" "
						toreturn_str << "id=\""+name+"\" "
					end
				end

				if type!="checkbox"
					if value!=nil
						toreturn_str << "value=\""+value.to_s+"\" "
					end
				else
					if value!=nil and value=="on"
						toreturn_str << "checked "
					end
				end

				if placeholdervalue!=nil
					# toreturn_str << placeholder(placeholdervalue) << " "
				end

				if styleClass != nil
					toreturn_str << "class=\"" << styleClass <<"\" "
				end

				if adhocContent != nil
					toreturn_str << adhocContent <<" "
				end

				toreturn_str << " />"

				if type=="checkbox"
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
				end

				if type=="tel"
					toreturn_str << "\n"
					toreturn_str << "<script> \n$(document).ready(function(){\n"
					toreturn_str << "var contactNumber = '';\n"
					toreturn_str << "var lastChildWidth = $('input[name=\"" << name << "\"]').parent().children('input').last().width();\n
					var widthPerc = lastChildWidth / $('input[name=\"" << name << "\"]').parent().width() * 100;"
					toreturn_str << "if (widthPerc>36) {\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').parent().children('input').last().width(lastChildWidth-30);\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').parent().children('input').each(function() {
					contactNumber += $(this).val();});\n"
					toreturn_str << "}\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').parent().children('a').remove();\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').parent().append(\""
					toreturn_str << "<a href='tel:\"+contactNumber+\"'><img src='/public/images/SalesIllustration/call.png'></a>"
					toreturn_str << "\");\n"
					toreturn_str << "});\n</script>"
					toreturn_str << "\n"
				end

				if type=="email"
					toreturn_str << "\n"
					toreturn_str << "<script> \n$(document).ready(function(){\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').width('55.3%');\n"
					toreturn_str << "$('input[name=\"" << name << "\"]').parent().append(\""
					toreturn_str << "<a href='mailto:#{value}'>"
					toreturn_str << "<img src='/public/images/SalesIllustration/email.png'></a>"
					toreturn_str << "\");\n"
					toreturn_str << "});\n</script>"
					toreturn_str << "\n"
				end

				# add script validation here
				if isManuallyHandled
					toreturn_str << "<script>"
					toreturn_str << "$(\"input[name='"+name+"']\").keypress(function(event){"
					toreturn_str << " if( !allowedKeyStroke('"+type+"', event.keyCode) ) event.preventDefault();"
					toreturn_str << "});"
					toreturn_str << " "
					if type=="number"
						toreturn_str << "$(\"input[name='"+name+"']\").blur(function(event){  if(this.value.match(/^\\d+(\\.\\d+)?$/)==null){this.value=\"\"} });"
					end
					toreturn_str << "</script>"
				end

				if styleClass == "countField"
					toreturn_str << "<script>"
					toreturn_str << "$(\"input[name='"+name+"']\").keyup(function(event){"
					toreturn_str << " if( $(this).val().length > 2 ) {$(this).val($(this).val().substring(0, 2));}"
					toreturn_str << "});"
					toreturn_str << "</script>"
				end

			rescue StandardError => se
				puts se
			end
			return toreturn_str;
		end
		##################################################################################################


		def renderRadioButton(fieldName, selectedValue, id, currentValue, object=nil, adhocContent=nil,defaultFl=nil)
			toreturn_str = ""
			begin

				toreturn_str << "<input type=\"radio\" "
				name = ""
				if fieldName!=nil
					if object !=nil
						name = $objectMapping[object.object.to_s]+"["+fieldName+"]"
						toreturn_str << "name=\""+name+"\" "
					else
						name = fieldName
						toreturn_str << "name=\""+fieldName+"\" "
					end
				end

				if id!=nil
					toreturn_str << "id=\""+id+"\" "
				else
					toreturn_str << "id=\""+fieldName+currentValue+"\" "
				end

				if currentValue != nil
					toreturn_str << "value=\""+currentValue+"\" "
				end

				# block for defaulting
				if selectedValue.to_s=="" and defaultFl == 'YES'
					selectedValue=currentValue
				end


				if selectedValue !=nil and currentValue != nil and selectedValue == currentValue
					toreturn_str << "checked "
				end

				# if selectedValue!=nil and selectedValue != currentValue
				#   toreturn_str << "checked"
				# end

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
		##################################################################################################


		#Get Lookup method renders the lookup onthe UI based on the lookupkey sent as
		# parameter. The method takes care of multi lingual localization of description
		# based on the locale of the app stored in the application table
		# Parameters for the method are
		# lookupket : Lookup identifier, which is to be rendered
		# fieldname : Name of the select option rendered on the field
		# selectedvalue: The value of the field in the form model. This is used to
		# add selected flag on the option
		def getLookup(lookupkey,fieldname,selectedvalue,object = nil, lookupdata=nil, adhocContent = nil)
			return renderLookup(lookupkey, fieldname, selectedvalue, nil, object, lookupdata, adhocContent)
		end
		##################################################################################################


		def getQuestionnaireLookup(lookupkey,fieldname,selectedvalue,object = nil, lookupdata=nil, adhocContent = nil)
			return renderLookup(lookupkey, fieldname, selectedvalue, nil, object, lookupdata, adhocContent)
		end
		##################################################################################################


		#<select name="flip-1" id="flip-1" data-role="slider">
		def getSwitch(lookupkey,fieldname,selectedvalue,object = nil, lookupdata=nil, adhocContent = nil)
			return renderLookupSwitch(lookupkey, fieldname, selectedvalue, "slider", object, lookupdata, adhocContent)
		end
		##################################################################################################


		def getQuestionnaireRadioButton(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil)
			if(lookupkey != DYNAMICLOOKUP)
				lookups = Lookupvalue.find(:all,:conditions=>{'key'=>lookupkey})
			else # (lookupkey == "DYNAMICARRAY")
				lookups = lookupdata
			end

			returnStr = ""
			radioName = ""
			lookup_name = ""

			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end
				fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]"
				#puts ">>>fieldname"
				returnStr << "<div data-role=\"fieldcontain\">"
				returnStr << "  <fieldset data-role=\"controlgroup\" data-type=\"horizontal\">"
				#puts ">>>#{returnStr}"
				lookups.each_with_index{ |lookup,index|
					returnStr << "    <input type=\"radio\" name=\"#{fieldname}\" id=\"#{fieldname}#{index}\" value=\"#{lookup.cd}\""
					#puts ">>>#{returnStr}"
					returnStr << "checked=\"checked\"" if lookup.cd == selectedvalue
					#puts ">>>#{returnStr}"
					returnStr << adhocContent if adhocContent != nil && adhocContent != ""
					returnStr << "/>"
					#puts ">>>#{returnStr}"
					returnStr << "    <label for=\"#{fieldname}#{index}\">#{Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)}</label>"
					#puts ">>>#{returnStr}"
        		}
				returnStr << "  </fieldset>"
				returnStr << "</div>"
				#puts ">>>#{returnStr}"
			rescue StandardError => se
				puts "Exception occured in getQuestionnaireRadioButton #{se}"
			end

			return returnStr
		end
		##################################################################################################


		def renderLookupSwitch(lookupkey, fieldname, selectedvalue, dataRole=nil, object = nil, lookupdata = nil, adhocContent = nil)
			if(lookupkey != DYNAMICLOOKUP)
				lookups = Lookupvalue.find(:all,:conditions=>{'key'=>lookupkey})
			else # (lookupkey == "DYNAMICARRAY")
				lookups = lookupdata
			end

			toreturn_str = ""
			selectedstring = ""
			lookup_name = ""

			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end

				if object !=nil
					toreturn_str << "<select name=\""+$objectMapping[object.object.to_s]+"["+lookup_name+"]\" "
				else
					toreturn_str << "<select name=\""+lookup_name+"\""
				end

				if object != nil
					toreturn_str << " id=\"" + $objectMapping[object.object.to_s] + "[" + lookup_name+"]\" "
				else
					toreturn_str << " id=\"" + lookup_name+"\" "
				end

				if dataRole != nil
					toreturn_str << " data-role=\""+dataRole+"\""
				end

				if adhocContent != nil
					toreturn_str << " "+adhocContent.to_s
				end

				toreturn_str << ">"
				isSelected = false
				if lookups.length > 0
					lookups.each do |lookup|
						if (selectedvalue!=nil and selectedvalue == lookup.cd) || (selectedvalue.to_s=="" && lookup.defaultFl.to_s == "YES")
							selectedstring = "SELECTED"
							isSelected = true
						else
							selectedstring = ""
						end
						if lookup.desc!=nil
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel(lookup.desc.to_sym) +" </option>"
						else
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ lookup.cd + " </option>"
						end
					end
				end

				if isSelected == false && selectedvalue != nil
					toreturn_str << "<option value=\""+selectedvalue+"\" SELECTED>"+ Localization::LabelCache.instance.getLabel(selectedvalue) +" </option>"
				end

				toreturn_str << "</select>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		# generic method for rendering all lookup related fields
		def renderLookup(lookupkey, fieldname, selectedvalue, dataRole=nil, object = nil, lookupdata = nil, adhocContent = nil)
			if(lookupkey != DYNAMICLOOKUP)
				lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>lookupkey})
			else # (lookupkey == "DYNAMICARRAY")
				lookupsArray = lookupdata
			end
			#Deepali Singh :04-01-2016 sorting array by sortOrder and desc
			lookups = Array.new
			if lookupsArray && lookupsArray.size > 0
				sortByOrderLookups,remainingLookups = lookupsArray.partition{|lookup| lookup.sortOrder.to_s != ""}
				sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
				remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
				lookups = sortByOrderLookups.concat remainingLookups
			end

			toreturn_str = ""
			selectedstring = ""
			lookup_name = ""

			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end

				if object !=nil
					toreturn_str << "<select name=\""+$objectMapping[object.object.to_s]+"["+lookup_name+"]\" "
				else
					toreturn_str << "<select name=\""+lookup_name+"\""
				end

				if object != nil
					toreturn_str << " id=\"" + $objectMapping[object.object.to_s] + "[" + lookup_name+"]\" "
				else
					toreturn_str << " id=\"" + lookup_name+"\" "
				end

				if dataRole != nil
					toreturn_str << " data-role=\""+dataRole+"\""
				end

				if adhocContent != nil
					toreturn_str << " "+adhocContent.to_s
				end

				toreturn_str << ">"
				toreturn_str << "<option value=\"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel("select".to_sym) +" </option>"
				isSelected = false
				if lookups.length > 0
					lookups.each do |lookup|
						# Deepali Singh: 04-01-2016 comparing values in same format (to_s)
						if (selectedvalue!=nil and selectedvalue.to_s == lookup.cd.to_s) || (selectedvalue.to_s=="" && lookup.defaultFl.to_s == "YES")
							selectedstring = "SELECTED"
							isSelected = true
						else
							selectedstring = ""
						end
						if lookup.desc!=nil
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel(lookup.desc.to_sym) +" </option>"
						else
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ lookup.cd + " </option>"
						end
					end
				end

				toreturn_str << "</select>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		# generic method for rendering all lookup related fields
		def renderComboLookup(lookupkey, fieldname, selectedvalue, object = nil, lookupdata = nil, adhocContent = nil)
			if(lookupkey != DYNAMICLOOKUP)
				lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>lookupkey})
			else # (lookupkey == "DYNAMICARRAY")
				lookupsArray = lookupdata
			end
			#Deepali Singh :04-01-2016 sorting array by sortOrder and desc
			lookups = Array.new
			if lookupsArray && lookupsArray.size > 0
				sortByOrderLookups,remainingLookups = lookupsArray.partition{|lookup| lookup.sortOrder.to_s != ""}
				sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
				remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
				lookups = sortByOrderLookups.concat remainingLookups
			end

			toreturn_str = ""
			selectedstring = ""
			lookup_name = ""

			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end

				toreturn_str << "<select "

				if object != nil
					toreturn_str << " id=\"" + $objectMapping[object.object.to_s] + "[" + lookup_name+"]\" "
					id = $objectMapping[object.object.to_s] + "[" + lookup_name+"]"
				else
					toreturn_str << " id=\"" + lookup_name+"\" "
					id = lookup_name
				end

				if adhocContent != nil
					toreturn_str << " "+adhocContent.to_s
				end

				toreturn_str << " multiple='multiple' data-native-menu='false'>"
				toreturn_str << "<option value=\"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel("select".to_sym) +" </option>"
				isSelected = false
				if lookups.length > 0
					lookups.each do |lookup|
						if (selectedvalue.to_s != "" and selectedvalue.include?(lookup.cd.to_s)) || (selectedvalue.to_s=="" && lookup.defaultFl.to_s == "YES")
							selectedstring = "SELECTED"
							isSelected = true
						else
							selectedstring = ""
						end
						if lookup.desc!=nil
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel(lookup.desc.to_sym) +" </option>"
						else
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ lookup.cd + " </option>"
						end

					end
				end

				if isSelected == false && selectedvalue != nil && selectedvalue != ""
					toreturn_str << "<option value=\""+selectedvalue.to_s+"\" SELECTED>"+ Localization::LabelCache.instance.getLabel(selectedvalue) +" </option>"
				end

				toreturn_str << "</select>"
				toreturn_str << "<input type='hidden' "
				if object !=nil
					toreturn_str << "name='"+$objectMapping[object.object.to_s]+"["+lookup_name+"]' "
					name = $objectMapping[object.object.to_s]+"["+lookup_name+"]"
				else
					toreturn_str << "name='"+lookup_name+"'' "
					name = lookup_name
				end
				toreturn_str << "value=''/>"

				toreturn_str << "<script type='text/javascript'>"
				toreturn_str << "foo = $('[id=\""+id+"\"]').val();"
				toreturn_str << "if(foo!=null)"
				toreturn_str << "$('[name=\""+name+"\"]').val(foo.join());"

				toreturn_str << "$('[id=\""+id+"\"]').change(function(){"
				toreturn_str << "foo = $(this).val();"
				toreturn_str << "if(foo!=null)"
				toreturn_str << "{"
				toreturn_str << "$('[name=\""+name+"\"]').val(foo.join());"
				toreturn_str << "}"
				toreturn_str << "else"
				toreturn_str << "{"
				toreturn_str << "$('[name=\""+name+"\"]').val('');"
				toreturn_str << "}"
				toreturn_str << "});"
				toreturn_str << "</script>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		##################################################################################################


		# Deepali Singh :04-01-2016 Method to get filterable select box
		def renderFilterableSelect(lookupkey, fieldname, selectedvalue, object = nil, lookupdata = nil, adhocContent = nil, headerLabelKey="")
			if(lookupkey != DYNAMICLOOKUP)
				lookupsArray = Lookupvalue.find(:all,:conditions=>{'key'=>lookupkey})
			else # (lookupkey == "DYNAMICARRAY")
				lookupsArray = lookupdata
			end
			#Deepali Singh :04-01-2016 sorting array by sortOrder and desc
			lookups = Array.new
			if lookupsArray && lookupsArray.size > 0
				sortByOrderLookups,remainingLookups = lookupsArray.partition{|lookup| lookup.sortOrder.to_s != ""}
				sortByOrderLookups.sort_by!{|lookUp| lookUp.sortOrder.to_i} if sortByOrderLookups.size > 0
				remainingLookups.sort!{|a, b| a.desc.to_s <=> b.desc.to_s} if remainingLookups.size > 0
				lookups = sortByOrderLookups.concat remainingLookups
			end

			toreturn_str = ""
			selectedstring = ""
			lookup_name = ""

			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end
				if object !=nil
					toreturn_str << "<select name=\""+$objectMapping[object.object.to_s]+"["+lookup_name+"]\" "
				else
					toreturn_str << "<select name=\""+lookup_name+"\""
				end

				if object != nil
					toreturn_str << " id=\"" + $objectMapping[object.object.to_s] + "[" + lookup_name+"]\" "
					id = $objectMapping[object.object.to_s] + "[" + lookup_name+"]"
				else
					toreturn_str << " id=\"" + lookup_name+"\" "
					id = lookup_name

				end

				if dataRole != nil
					toreturn_str << " data-role=\""+dataRole+"\""
				end

				toreturn_str << 'data-native-menu="false" class="filterable-select"'

				if adhocContent != nil
					toreturn_str << " "+adhocContent.to_s
				end

				toreturn_str << ">"
				isSelected = false
				# This is required for header label, option without any value
				toreturn_str << "<option>"+ Localization::LabelCache.instance.getLabel(headerLabelKey.to_sym) +" </option>"

				if selectedvalue.to_s == ''
					toreturn_str << "<option value='' SELECTED>"+ Localization::LabelCache.instance.getLabel("select".to_sym) +" </option>"
					isSelected = true
				else
					toreturn_str << "<option value='' "+selectedstring+">"+ Localization::LabelCache.instance.getLabel("select".to_sym) +" </option>"
				end
				if lookups && lookups.length > 0
					lookups.each do |lookup|
						# Overriding method to compare seletced value in same format (to_s)
						if (selectedvalue!=nil and selectedvalue.to_s == lookup.cd.to_s) || (selectedvalue.to_s=="" && lookup.defaultFl.to_s == "YES")
							selectedstring = "SELECTED"
							isSelected = true
						else
							selectedstring = ""
						end
						if lookup.desc!=nil
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ Localization::LabelCache.instance.getLabel(lookup.desc.to_sym) +" </option>"
						else
							toreturn_str << "<option value=\""+lookup.cd+"\" "+selectedstring+">"+ lookup.cd + " </option>"
						end
					end
				end
				if isSelected == false && selectedvalue != nil && selectedvalue != ""
					toreturn_str << "<option value=\""+selectedvalue.to_s+"\" SELECTED>"+ Localization::LabelCache.instance.getLabel(selectedvalue) +" </option>"
				end
				toreturn_str << "</select>"
			rescue StandardError => se
				puts se
			end
			return toreturn_str
		end
		#######################################################################################


		# <div class="legend">
		# <%= renderLabel('InsuredInformation','INSUREDINFORMATION','strongLabel') %>
		# <input type = 'hidden' value = '-' name = 'state_InsuredInformation'>
		# <img name='collapse_InsuredInformation' src = '/public/images/SalesIllustration/less.jpg' align = "right">
		# </div>
		def renderLegend(name, label, defaultState = '-')
			toreturn_str = ""
			toreturn_str << "<div class='legend'>"
			toreturn_str << renderLabel(name, label, 'strongLabel')

			if defaultState == '-'
				toreturn_str << "<input type = 'hidden' value = '-' name = 'state_"<< name <<"'>"
				toreturn_str << "<img name='collapse_" << name <<"' src = '/public/images/SalesIllustration/less.jpg' align = 'right'/>"
			else
				toreturn_str << "<input type = 'hidden' value = '+' name = 'state_"<< name <<"'>"
				toreturn_str << "<img name='collapse_" << name <<"' src = '/public/images/SalesIllustration/more.jpg' align = 'right'/>"
			end
			toreturn_str << "</div>"
			return toreturn_str
		end
		##################################################################################################


		# <div name = "container" data-dojo-type="dijit/layout/TabContainer" style="width: 100%; height: <%= System.get_property('real_screen_height').to_i - 20 %>px">
		def renderTabContainer(name, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << "<div name = '#{name}' data-dojo-type='dijit/layout/TabContainer' "
			if adhocContent != nil
				toreturn_str << adhocContent
			end
			toreturn_str << ">"
			return toreturn_str
		end
		##################################################################################################


		def endTabContainer
			toreturn_str = ""
			toreturn_str << "</div>"
			return toreturn_str
		end
		##################################################################################################


		# <div data-dojo-type="dijit/layout/ContentPane" title="Basic" data-dojo-props="selected:true">
		def renderTabContentPane(name, label, selected = false, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << "<div name = '#{name}' data-dojo-type='dijit/layout/ContentPane' "

			if label != nil
				toreturn_str << " title = '#{getLabelValue(label)}' "
			else
				toreturn_str << " title = '#{getLabelValue(name)}' "
			end

			if selected
				toreturn_str << " data-dojo-props='selected:true' "
			end

			if adhocContent != nil
				toreturn_str << adhocContent
			end
			toreturn_str << ">"
			return toreturn_str
		end
		##################################################################################################


		def endTabContentPane
			toreturn_str = ""
			toreturn_str << "</div>"
			return toreturn_str
		end
		##################################################################################################


		def renderToolbar(toolbar)
			if toolbar == -1
				Rho::NativeToolbar.remove
			else
				quickLinksArray = [{
					:label        => 'Home',
					:action       => 'callback:/app/Menu/prompt?url=/app/Menu/landingPage',
					:icon         => '/public/images/SalesIllustration/100-Home.png',
					:colored_icon => true
				}]

				$rhoconfig[:menuConfig].split(",").each do |menuItem|
					case
					when menuItem == "COLLATERAL" && toolbar != 1
						quickLinksArray.push({
							:label        => 'Collateral',
							:action       => 'callback:/app/Menu/prompt?url=/app/Level0/entrypoint',
							:icon         => '/public/images/SalesIllustration/cms.png',
							:colored_icon => true
						})
					when menuItem == "LEADS" && toolbar != 2
						quickLinksArray.push({
							:label        => 'Leads',
							:action       => 'callback:/app/Menu/prompt?url=/app/Menu/leads',
							:icon         => '/public/images/SalesIllustration/100-Leads.png',
							:colored_icon => true
						})
					when menuItem == "SALESILLUSTRATION" && toolbar != 3
						quickLinksArray.push({
							:label        => 'SalesIllustration',
							:action       => 'callback:/app/Menu/prompt?url=/app/Menu/salesIllustration',
							:icon         => '/public/images/SalesIllustration/Sales-Illustrations2.png',
							:colored_icon => true
						})
					when menuItem == "EAPP" && toolbar != 4
						quickLinksArray.push({
							:label        => 'Eapp',
							:action       => 'callback:/app/Menu/prompt?url=/app/Menu/eapp',
							:icon         => '/public/images/SalesIllustration/E-Application.png',
							:colored_icon => true
						})
					when menuItem == "RECEIPTING" && toolbar != 5
						quickLinksArray.push({
							:label        => 'Receipting',
							:action       => 'callback:/app/Menu/prompt?url=/app/Menu/receipting',
							:icon         => '/public/images/SalesIllustration/SalesIllustration.png',
							:colored_icon => true
						})
					when menuItem == "CALCULATORS" && toolbar != 6
						quickLinksArray.push({
							:label        => 'Calculators',
							:action       => 'callback:/app/Menu/prompt?url=/app/Menu/calculators',
							:icon         => '/public/images/SalesIllustration/calculatorbutton.png',
							:colored_icon => true
						})
					end
				end

				quickLinksArray.push({
					:action       => :separator
				})

				if Rho::System.getProperty("platform").to_s != "APPLE"
					quickLinksArray.push({
						:label        => 'About',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/about',
						:icon         => '/public/images/SalesIllustration/100-About-Device.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'Exit',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/exit',
						:icon         => '/public/images/SalesIllustration/FINAL-Exit.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'Sync',
						:action       => 'callback:/app/Menu/prompt?url=/app/SyncCategory/syncPreferences',
						:icon         => '/public/images/SalesIllustration/100-Synchronize.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'SETTINGS',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/settings',
						:icon         => '/public/images/SalesIllustration/SettingsPCG.png',
						:colored_icon => true
					})
				else
					quickLinksArray.push({
						:label        => 'About',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/about',
						:icon         => '/public/images/SalesIllustration/100-About-Device.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'SETTINGS',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/settings',
						:icon         => '/public/images/SalesIllustration/SettingsPCG.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'Sync',
						:action       => 'callback:/app/Menu/prompt?url=/app/SyncCategory/syncPreferences',
						:icon         => '/public/images/SalesIllustration/100-Synchronize.png',
						:colored_icon => true
					})
					quickLinksArray.push({
						:label        => 'Exit',
						:action       => 'callback:/app/Menu/prompt?url=/app/Menu/exit',
						:icon         => '/public/images/SalesIllustration/FINAL-Exit.png',
						:colored_icon => true
					})
				end
				Rho::NativeToolbar.create(quickLinksArray)
			end
		end
		##################################################################################################


		def self.renderNumber(number,decimal=0)
			counter = 0
			returnString = ""
			number.to_f.round(decimal).to_s.reverse.each_char do |ch|
				if counter==3
					counter = 0
					returnString << ","
				end
				returnString << ch
				counter = counter + 1
			end

			return returnString.reverse
		end
		##################################################################################################


		def renderNumber(number,decimal=0)
			counter = 0
			returnString = ""
			number.to_f.round(decimal).to_s.reverse.each_char do |ch|
				if counter==3
					counter = 0
					returnString << ","
				end
				returnString << ch
				counter = counter + 1
			end
			return returnString.reverse
		end
		##################################################################################################


		def renderNumberFloor(number)
			counter = 0
			returnString = ""
			number.to_i.to_s.reverse.each_char do |ch|
				if counter==3
					counter = 0
					returnString << ","
				end
				returnString << ch
				counter = counter + 1
			end
			return returnString.reverse
		end
		##################################################################################################


		def renderInt(number)
			return number.to_i.round(0).to_s
		end
		##################################################################################################


		def renderDecimalUpto2Places(number)
			if number != nil
				return number.round(2).to_s
			else
				return number.to_i
			end
		end
		##################################################################################################


		def renderTabbar
			Rho::NativeTabbar.create_vertical(
				[
					{
						:label => 'Tab 1',
						:action => '/app/Inward/tab1',
						:icon => '/public/images/SalesIllustration/capture.png',
						:reload => false
					},
					{
						:label => 'Tab 2',
						:action => '/app/Inward/tab2',
						:icon => '/public/images/SalesIllustration/compare.png',
						:reload => false
					}
				]
			)
		end
		##################################################################################################


		#comments for method
		#Deepali Singh: 08/08/2016 - zip json file and then upload to server
		def doJSONPost(*args)
			if not (args.size == 2 || args.size == 4)
				raise ArgumentError.new('Incorrect number of arguments in call to doJSONPost.')
			else
				url = args[0]
				clearJsonString = args[1]
				mobiSysDeviceIdAppObject = Application.getValue(MobiSys::MOBISYSDEVICEID);
				mobiSysDeviceId = nil
				mobiSysDeviceId = mobiSysDeviceIdAppObject.value if mobiSysDeviceIdAppObject
				userName, password = (args.size == 4) ? [args[2], args[3]] : ((args.size == 2) ? [$userId, $userPassword] : [nil, nil])
				$redirectionFlag = true

				device = Device.new
				device.deviceName = System::get_property('device_name')
				device.osVersion = System::get_property('os_version')
				device.appVersion = Rho::RhoConfig.app_version
				device.masterDBVersion = Application.getValue('DBVERSION').value
				device.devicePlatform = System::get_property('platform')
				device.mobiSysDeviceId = mobiSysDeviceId if mobiSysDeviceId
				notificationRegTokenObj = Application.getValue("NOTIFICATIONREGTOKEN")
				device.deviceId = notificationRegTokenObj.value if notificationRegTokenObj

				devSeqObj = Application.getValue(MobiSys::DEVICESEQ);
				deviceSeq = devSeqObj.value if devSeqObj

				begin
					deviceData = ::JSON.generate(device)
				rescue StandardError => se
					puts "Error while generating device JSON request =>" + se
				end

				inputHash = Hash.new

				if Rho::RhoConfig.use_AES_encoding =='YES' && device.deviceName != "Win32"
					jsonString = "XX"
					jsonString << EncrypterUtil::EncrypterUtilStringHelper::encrypt(clearJsonString)
				else
					jsonString = clearJsonString
				end

				inputHash['USERNAME'] = userName
				inputHash['PASSWORD'] = password
				inputHash['DEVICE'] = deviceData
				inputHash['DATA'] = jsonString
				inputHash['DEVICESEQ'] = deviceSeq

				devicedatetime = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')

				inputHash['deviceSysTime'] = devicedatetime

				begin
					data = ::JSON.generate(inputHash)
				rescue StandardError => se
					puts "Error while generating final JSON request =>" + se
				end
				currentTime = Time.now.strftime('%Y-%m-%d %H:%M:%S:%L%z')
				currentTime = currentTime.to_s.gsub(/^.*(\\|\/)/, '')
				currentTime = currentTime.gsub(/[^0-9A-Za-z.\-]/, '_')
				fileName = "#{currentTime}_#{userName}_#{deviceSeq}"

				name = File.join(Rho::RhoApplication::get_base_app_path(),fileName)
				json = File.open(name,"w")
				json.write(data)
				json.close

				# creating zip file
				local_path_to_zip = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}.zip")
				filePath = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}")
				Rho::System.zipFile(local_path_to_zip, name)
				# uploading a zip file
				upload_url = Application.getValue('online_server_url').value + "/baseMobileFileUpload.run"
				download_url = Application.getValue('online_server_url').value + "/baseMobileFileDownload.run"

				uploadStatus = Rho::AsyncHttp.upload_file(
					:url=>upload_url,
					:ssl_verify_peer=> $ssl_verify_peer,
					:headers => {"username"=>userName,"password"=>password,"beanName"=>url,"fileName" => fileName},
					:filename=>local_path_to_zip
				)
				# if uploadStatus['status'] == "ok"
				# 	result = Rho::AsyncHttp.download_file(
				# 		:url => download_url,
				# 		:filename => local_path_to_zip,
				# 		:headers => {"username"=>userName,"password"=>password,"filename"=> fileName.to_s+".zip"},
				# 		:overwriteFile => true,
				# 		:ssl_verify_peer => $ssl_verify_peer
				# 	)
				# else
				# 	result = uploadStatus
				# end
				result = uploadStatus
				compressed = Base64.strict_decode64(result['body'])
				decompressed = gunzip(compressed)
				# puts "result--------#{result}"
				# puts "compressed------#{compressed}"
				# puts "decompressed------#{decompressed}"
				puts "compress ratio: #{compressed.length.to_f / result['body'].length.to_f}"
				File.delete(name) if File.exists?(name)
				File.delete(local_path_to_zip) if File.exists?(local_path_to_zip)

				if result['status'] == "ok"
					# Rho::System.unzipFile(local_path_to_zip)
					# jsonContent = File.read(filePath.to_s+".txt")
					# outputHash = Rho::JSON.parse(jsonContent)
					outputHash = Rho::JSON.parse(decompressed)
					File.delete(local_path_to_zip) if File.exists?(local_path_to_zip)
					File.delete(filePath.to_s+".txt") if File.exists?(filePath.to_s+".txt")
					mobiSysDeviceId = outputHash[MobiSys::MOBISYSDEVICEID]
					#mobiSysDeviceId getting updated after coming from online for 2nd time
					if mobiSysDeviceId.to_s != ""
						if Application.getValue(MobiSys::MOBISYSDEVICEID)
							Application.updateValue(MobiSys::MOBISYSDEVICEID,mobiSysDeviceId)
						else
							Application.create(MobiSys::MOBISYSDEVICEID,mobiSysDeviceId)
						end
					end
					#variable key,online reg dt and deviceseq added in output hash and saved in application table
					viewCd = outputHash[MobiSys::VIEWCD]
					if viewCd
						app_viewCd = Application.getValue(MobiSys::VIEWCD)
						if app_viewCd
							Application.updateValue(MobiSys::VIEWCD,viewCd)
						else
							Application.create(MobiSys::VIEWCD,viewCd)
						end
					end
					#get the application table viewcd
					#if app view cd exists
					#update
					#else
					#create
					#else
					#load
					#end
					onlineRegDt = outputHash[MobiSys::ONLINEREGDT]
					if onlineRegDt
						app_onlineRegDt = Application.getValue(MobiSys::ONLINEREGDT)
						if app_onlineRegDt
							Application.updateValue(MobiSys::ONLINEREGDT,onlineRegDt)
						else
							Application.create(MobiSys::ONLINEREGDT,onlineRegDt)
						end
					end
					deviceSeq = outputHash[MobiSys::DEVICESEQ]
					if deviceSeq
						app_deviceSeq = Application.getValue(MobiSys::DEVICESEQ)
						if app_deviceSeq
							Application.updateValue(MobiSys::DEVICESEQ,deviceSeq)
						else
							Application.create(MobiSys::DEVICESEQ,deviceSeq)
						end
					else
						deviceSeq = Application.getValue(MobiSys::DEVICESEQ)
					end
					deviceDeactivated = outputHash[MobiSys::DEVICEDISABLED]
					userDeactivated = outputHash[MobiSys::USERDISABLED]
					bundleURL = outputHash[MobiSys::BUNDLEURL]
					authenticationMessage = outputHash[MobiSys::AUTHENTICATIONMESSAGE]
					deviceSysTime = outputHash[MobiSys::DEVICESYSTIME]
					if deviceDeactivated
						mobiSysDeviceIdAppObject = Application.getValue(MobiSys::MOBISYSDEVICEID)
						Rhom::Rhom.database_full_reset(false, true)
						Application.create(MobiSys::MOBISYSDEVICEID,mobiSysDeviceIdAppObject.value)
						Application.create(MobiSys::DEVICEDISABLED,'YES')
						Application.create('seeded','seeded');
						# Delete all last sync dates
						Application.delete_all(
							:conditions => {
								{
									:name => 'key',
									:op => 'LIKE'
								} => "%_lastSyncDate%"
							}
						)
						raise MobiSys::JSONPostError.new(getLabelValue('DEVICEDEACTIVATED'))
					elsif userDeactivated
						agentReg = AgentReg.forUserId(userName)
						if agentReg
							#destroy all user data
							userTransactionEntities = SyncEntity.find(:all,:conditions=>{:entitySubCategory=>'USERTRANSACTIONS'})
							$userId = userName
							userTransactionEntities.each do |userTransactionEntity|
								entityName = userTransactionEntity.entityName
								next if entityName == "UserActivity" or entityName == "SyncActivity" or entityName == "UserLoginHistory"
								exp = entityName +'.loadObject(:all)'
								entities = eval(exp)
								entities.each do |entity|
									entity.delete
								end
							end
							# Delete all last sync dates for the current user
							Application.delete_all(
								:conditions => {
									{
										:name => 'key',
										:op => 'LIKE'
									} => "%_#{$userId}_lastSyncDate%"
								}
							)
							$userId = nil
							agentReg.destroy if agentReg
							### if zero  agent present then deactivate the device
							agentcount = AgentReg.find(:count)
							if agentcount == 0
								mobiSysDeviceIdAppObject = Application.getValue(MobiSys::MOBISYSDEVICEID)
								Rhom::Rhom.database_full_reset(false, true)
								Application.create(MobiSys::MOBISYSDEVICEID,mobiSysDeviceIdAppObject.value)
								Application.create(MobiSys::DEVICEDISABLED,'YES')
								Application.create('seeded','seeded');
								# Delete all last sync dates
								Application.delete_all(
									:conditions => {
										{
											:name => 'key',
											:op => 'LIKE'
										} => "%_lastSyncDate%"
									}
								)
								raise MobiSys::JSONPostError.new(getLabelValue('DEVICEDEACTIVATED'))
							else
								raise MobiSys::JSONPostError.new(getLabelValue('USERDISABLED'))
							end
						else
							raise MobiSys::JSONPostError.new(getLabelValue('USERDISABLED'))
						end
					elsif bundleURL
						if Rho::RhoConfig.exists?('upgrade_prompt') and Rho::RhoConfig.upgrade_prompt=='YES'
							if System::get_property('platform').downcase.include?("windows")
								$js = 'showConfirm("Application upgrade","'+getLabelValue("UPGRADEAPPLICATION")+'","'+getLabelValue("UPGRADENOW")+'","'+getLabelValue("UPGRADELATER")+'","'+bundleURL+'");'
							else
								Alert.show_popup( {
									:message => getLabelValue("UPGRADEAPPLICATION"),
									:title => 'Application upgraded',
									:buttons => [{:id=>"ok",:title=> getLabelValue("UPGRADENOW")},{:id=>"cancel",:title=>getLabelValue("UPGRADELATER")}],
									:callback => url_for(:action => :on_dismiss_popup1,:query => {"url" => bundleURL})
								})
							end
						end
						#upgradeApp(bundleURL)
						raise MobiSys::UpgradeApplicationError.new(getLabelValue('UPGRADEAPPLICATION'))
					elsif authenticationMessage
						raise MobiSys::JSONPostError.new(authenticationMessage)
					elsif deviceSysTime
						raise MobiSys::JSONPostError.new(getLabelValue('DEVICESYNTIMEERROR'))
					else
						encryptedOutputData = outputHash['DATA']
						if encryptedOutputData.to_s.start_with?('XX')
							encryptedOutputDataNoPadding = encryptedOutputData.to_s[2..-1]
							outputData = EncrypterUtil::EncrypterUtilStringHelper::decrypt(encryptedOutputDataNoPadding)
						else # if not 'ANDROID'
							outputData = encryptedOutputData
						end
						return outputData
					end

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
				elsif result['status'] == "error" and result['http_error'] == "403"
					File.delete(local_path_to_zip) if File.exists?(local_path_to_zip)
					rhodownload = local_path_to_zip + ".rhodownload"
					File.delete(rhodownload) if File.exists?(rhodownload)
					File.delete(filePath.to_s+".txt") if File.exists?(filePath.to_s+".txt")

					$login = false
					userName = args[2] if args.size == 4
					userName = $userId if args.size == 2
					password = args[3] if args.size == 4
					password = $userPassword if args.size == 2
					agentReg = AgentReg.forUserId(userName, true)
					if agentReg and password == agentReg.regPass #Authentication failed for valid credentials. Remove password from AgentReg to invalidate it.
						agentReg.regPass = nil
						agentReg.save
					end
					$errors = Hash.new
					$errors['USERNAMEPWD'] = getLabelValue('USERNAMEPWD')
					WebView.navigate(Rho::RhoConfig.start_path)

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
					$redirectionFlag = false
					raise MobiSys::AuthenticationError.new(getLabelValue('USERNAMEPWD'))
				elsif result['status']=='error' && result['error_code']=="1" && Rho::Log.readLogFile(300).to_s.include?('SSL')
					puts "SSL peer certificate or SSH remote key was not OK"

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
					raise MobiSys::InvalidSSLCertificateError.new(getLabelValue('SERVERERROR'))
				else
					File.delete(local_path_to_zip) if File.exists?(local_path_to_zip)
					rhodownload = local_path_to_zip + ".rhodownload"
					File.delete(rhodownload) if File.exists?(rhodownload)
					File.delete(filePath.to_s+".txt") if File.exists?(filePath.to_s+".txt")

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
					raise MobiSys::ServerUnavailableError.new(getLabelValue('SERVERERROR'))
				end
			end
		end
		##################################################################################################


		def on_dismiss_popup1()
			id = @params["button_id"]
			if id == 'cancel'
				puts 'Application exits. OK pressed on dialog'
				System.exit
			elsif id== 'ok'
				url = @params['url']
				puts url
				if url!="nullnull"
					upgradeApp(url)
				end
			end
			#raise MobiSys::UpgradeApplicationError.new(getLabelValue('UPGRADEAPPLICATION'))
		end
		##################################################################################################


		def upgradeApp(bundleURL)
			begin
				System.set_sleeping(false)
				redirect :action => :wait_download
				puts 'Inside Customer/testApplicationUpgrade'
				folder_name = Rho::RhoApplication::get_base_app_path  + "../downloads"
				puts "**************folder_name " + folder_name

				if !Dir.exist?(folder_name)
					Dir.mkdir folder_name
				end

				puts "*******Folder created"
				file_name = File.join(folder_name, "app.zip")
				puts "********file_name: " + file_name
				System.set_sleeping(false)
				Rho::AsyncHttp.download_file(
					:url => bundleURL,
					:filename => file_name,
					:headers => {},
					:callback => url_for(:action => :bundledownload_callback),
					:callback_param => "filePath=#{file_name}"
				)
			rescue StandardError => boom
				puts boom;
				logMessage boom
			end
		end
		##################################################################################################


		def bundledownload_callback
			puts 'Download completed successfully'
			puts "***********http_error" + @params["http_error"]
			filePath = @params["filePath"]
			System.unzip_file filePath
			puts 'File unzipped successfully'

			#Create backup directory
			backup_directory = Rho::RhoApplication::get_base_app_path  + "../backup"
			puts ">>>>>>>Backup directory: " + backup_directory
			#backup_directory = File.realpath(backup_directory)
			if !Dir.exist?(backup_directory)
				Dir.mkdir backup_directory
				puts "Backup directory created!"
			end

			begin
				puts "*************Before backup files"
				#Create a backup of contents of apps folder. The backup created gets rid of the symbolic links which prevent the application upgrade.
				backupApp

				#Now clear the apps folder
				cleanapps

				#Restore the files/folders from backup created.
				restoreFromBackup

				#Congratulations! You now have apps directory without any symbolic links. Now copy the new files
				puts "*************Before copy new files"
				copyNewFiles
			rescue StandardError => boom
				puts ">>>>>>>>>>>>Exception occured : " + boom
				rollbackFileChanges
			end

			cleanup
			System.set_sleeping(true)
			Alert.show_popup( {
				:message => 'The application has been upgraded and will now exit. Please restart the application.',
				:title => 'Application upgraded',
				:icon => :alert,
				:buttons => ["OK"],
				:callback => url_for(:action => :on_dismiss_popup)
			})
		end
		##################################################################################################


		def copyNewFiles
			puts ">>>>>>>>>>>>>rhofilelist: " + File.join(Rho::RhoApplication::get_base_app_path + "../downloads/RhoBundle/apps","rhofilelist.txt")
			rhofilelist = File.join(Rho::RhoApplication::get_base_app_path + "../downloads/RhoBundle/apps","rhofilelist.txt")
			filelist = Array.new
			File.foreach(rhofilelist) {|x|
				filelist.push x
			}
			filelist.each do |fileName|
				puts ">>>>>>>>>Processing filename: " + fileName
				filename = nil;
				filetype = nil;
				fileName.split("\t").each_with_index do |word,index|
					if index == 0
						filename = word
					elsif index == 1
						filetype = word
					end
				end

				if filetype == "dir"
					#Check if the directory exists in base app. if not create it.
					dir = Rho::RhoApplication::get_base_app_path  + filename
					unless Dir.exist? dir
						Dir.mkdir dir
						puts ">>>>>>>>>>>Created directory: " + dir
					end
				else
					originalFile = Rho::RhoApplication::get_base_app_path + filename
					puts ">>>>>>>>>>>>Copying originalFile: " + originalFile
					puts ">>>>>>>>>>>>original file exisits? " + File.exists?(originalFile).to_s

					newFile = Rho::RhoApplication::get_base_app_path + "../downloads/RhoBundle/apps/" + filename
					puts ">>>>>>>>>>>>New file: " + newFile
					puts ">>>>>>>>>>>>new file exisits? " + File.exists?(newFile).to_s
					#File.rename(newFile,originalFile) if File.exists? newFile
					if File.exists? newFile
						FileUtils::copy_entry(newFile, originalFile, false, false, true)
						puts "Copied file :" + originalFile
					else
						#File specified in the manifest but not included in the bundle. Implies the file is to be deleted.
						File.delete originalFile
					end
				end
			end
		end
		##################################################################################################


		def backupApp
			puts "$$$$$$$$$backupApp called!"
			newFileList = getFiles(Rho::RhoApplication::get_base_app_path)
			newFileList.each do |filename|
				puts ">>>>>>>>>>>Processing: " + filename
				fileparts = filename.rpartition("/")
				actualFileName = fileparts[2]
				puts ">>>>>>>>>>Actual filename: " + actualFileName
				if actualFileName == 'app' or actualFileName == 'public'
					backupDirPath = File.join(Rho::RhoApplication::get_base_app_path + "../backup/",actualFileName)
					puts ">>>>>>>>>>File is a directory? " + File.directory?(filename).to_s
					if File.directory?(filename)
						puts ">>>>>>>Inside if " + Rho::RhoApplication::get_base_app_path + "../backup"
						FileUtils::cp_r(filename,File.realpath(Rho::RhoApplication::get_base_app_path + "../backup"))
						#FileUtils::rm_rf filename
					else
						originalDirectoryName = File.readlink(Rho::RhoApplication::get_base_app_path + actualFileName) + "/../" + actualFileName
						puts ">>>>>>>>>Original directory name: " + originalDirectoryName
						FileUtils::cp_r(originalDirectoryName,backupDirPath)
						#File.delete(filename)
					end
				else
					puts "Copying file: "
					FileUtils::copy(filename,Rho::RhoApplication::get_base_app_path + "../backup/")
					#File.delete(filename)
				end
			end
		end
		##################################################################################################


		def cleanup
			#Delete backup and download directories
			FileUtils::rm_rf(Rho::RhoApplication::get_base_app_path  + "../backup")
			FileUtils::rm_rf(Rho::RhoApplication::get_base_app_path  + "../downloads")
		end
		##################################################################################################


		def cleanapps
			#Delete all everything present in apps directory
			puts ">>>>>>>>>>>>>>Inside cleanapp"
			newFileList = getFiles(Rho::RhoApplication::get_base_app_path)
			newFileList.each do |filename|
				puts ">>>>>>>>>>>Processing: " + filename
				fileparts = filename.rpartition("/")
				actualFileName = fileparts[2]
				puts ">>>>>>>>>>Actual filename: " + actualFileName
				if actualFileName == 'app' or actualFileName == 'public'
					backupDirPath = File.join(Rho::RhoApplication::get_base_app_path + "../backup/",actualFileName)
					puts ">>>>>>>>>>File is a directory? " + File.directory?(filename).to_s
					if File.directory?(filename)
						FileUtils::rm_rf filename
					else
						File.delete(filename)
					end
				else
					puts ">>>>>>>>>>>>>>>>Here"
					FileUtils::rm_f(filename)
				end
			end
		end
		##################################################################################################


		def restoreFromBackup
			#Copy app files from backup
			baseDir = Dir.new(Rho::RhoApplication::get_base_app_path + "../backup/")
			baseDir.each {|fileName|
				absFileName = File.absolute_path(fileName,baseDir)
				puts "****************Got #{absFileName}"
				if fileName != "." and fileName != ".."
					if File.directory? absFileName
						puts "***********#{absFileName} is a directory."
						FileUtils::cp_r(absFileName,Rho::RhoApplication::get_base_app_path)
						puts "***********directory copied."
					else
						FileUtils::copy(absFileName,Rho::RhoApplication::get_base_app_path)
						puts "***********file copied."
					end
				end
			}
		end
		##################################################################################################


		def rollbackFileChanges
			cleanapps
			restoreFromBackup
		end
		##################################################################################################


		def on_dismiss_popup
			begin
				id = @params["button_id"]
				if id == 'OK'
					logMessage 'Application exits. OK pressed on dialog'
					System.exit
				end
			rescue StandardError => boom
				puts boom
				logMessage boom
			end
		end
		##################################################################################################


		def getFiles(directory)
			fileNames = Array.new
			if File.directory? directory
				baseDir = Dir.new(directory)
				baseDir.each {|fileName|
					absFileName = File.absolute_path(fileName,baseDir)
					puts "****************Got #{absFileName}"
					if fileName != "." and fileName != ".."
						if File.directory? fileName
							fileNames.push "Directory: " + fileName
							puts "****************Its a directory!"
							files = getFiles(fileName)
							fileNames.concat files
						else
							fileNames.push absFileName
						end
					end
				}
			end
			return fileNames
		end
		##################################################################################################


		def self.getExpDate(date)
			screenDate = ""
			if date != nil && date != ""
				if date.to_s.include? "."
					screenDate = Time.strptime(date, "%Y-%m-%d %H:%M:%S.%L %z").strftime('%d/%m/%Y')
				else
					screenDate = Time.strptime(date, "%Y-%m-%d %H:%M:%S %z").strftime('%d/%m/%Y')
				end
			end
			return screenDate
		end
		##################################################################################################


		def renderReadonlyDateField(id,value,placeholdervalue,object = nil, adhocContent=nil)
			toreturn_str = ""
			toreturn_str << renderTextField(id,value,placeholdervalue,"text",object, "dateField", adhocContent)

			if id!=nil
				if object !=nil
					nameVal=$objectMapping[object.object.to_s]+"["+id+"]"
				else
					nameVal=id
				end
			end

			toreturn_str << "\n"
			toreturn_str << "<img src =\"/public/images/icon-date_picker-huge.png\" class=\"datepickerimg\" \"/>" <<"\n"
			toreturn_str << "<script>" << "\n"
			toreturn_str << "setReadOnly($('input[name=\""<< nameVal<<"\"]'), true);"<< "\n"
			toreturn_str << "</script>"<< "\n"
			toreturn_str << "\n"
			return toreturn_str
		end
		##################################################################################################


		def maskNumbers(obj)
			modelSource = Rho::RhoConfig.sources[obj.class.name.to_s]
			modelSource["schema"]["property"].each do |property, valueArray|
				if valueArray[1] != nil && valueArray[1] == :decimal
					stmt = "obj.#{property}"
					value = eval(stmt)
					value = maskDecimal(value)
					stmt = "obj.#{property}='#{value}'"
					eval(stmt)
				elsif valueArray[1] != nil && valueArray[1] == :nondecimal
					stmt = "obj.#{property}"
					value = eval(stmt)
					value = maskDecimal(value)
					stmt = "obj.#{property}='#{value}'"
					eval(stmt)
				end
			end

			childClassList = $childClasses[obj.class.name]
			if childClassList
				childClassList.each do |childClass|
					stmt = "obj.#{childClass}List"
					children = eval(stmt)
					if children
						children.each do |child|
							maskNumbers(child)
						end
					end
				end
			end
		end
		##################################################################################################


		def maskDecimal(number,mask=nil)
			if mask.to_s != ""
				if /\A-?(?:\d+(?:\.\d*)?|\.\d+)\z/.match(number.to_s) == nil
			        return number #return as it is.
			    end

			    mask = mask + "." unless mask.include?(".")

			    #convert any string to number according to formation sign.
			    number = mask[0] == '-'? -number.to_f : +number.to_f

			    ##process only abs(), and turn on flag.
			    if number < 0
			    	isNegative = true
			    	number= -number
			    end
			    #search for separator for grp & decimal, anything not digit, not +/- sign, not #.
			    result = mask.scan(/[^\d\-\+#]/)
			    decimal = (result && result[result.length-1]) || '.' #treat the right most symbol as decimal
			    group = (result && result[1] && result[0]) || ','  #treat the left most symbol as group separator

			    #split the decimal for the format string if any.
			    mask = mask.split(decimal)
			    #Fix the decimal first, toFixed will auto fill trailing zero.
			    number = "%.#{(mask[1] && mask[1].length)}f" % number if mask[1]
			    #convert number to string and trim off *all* trailing decimal zero(es)
			    # i,f = number.to_i, number.to_f
				# i==f ? number=i.to_s : number=f.to_s
			    # number = number.to_s.sub(/(\.\d*?[1-9])0+$/, '')
			    number = number.to_s.sub(/\.?0*$/, "")
			    #fill back any trailing zero according to format
			    pos_trail_zero = mask[1] && mask[1].rindex('0') #look for last zero in format
			    part = []
		        if number.to_s.include? '.'
		            part = number.to_s.split('.')
		        else
		            part[0] = number.to_s
		        end

			    #integer will get !part[1]
			    if (!part[1] || part[1] && part[1].length <= pos_trail_zero.to_i)
			        number = "%.#{pos_trail_zero+1}f" % number if pos_trail_zero
			    end

			    szSep = mask[0].split(group) #look for separator
			    mask[0] = szSep.join('') #join back without separator for counting the pos of any leading 0.

			    pos_lead_zero = mask[0] && mask[0].index('0')

			    if (pos_lead_zero && pos_lead_zero > -1 )
			        while (part[0].length < (mask[0].length - pos_lead_zero))
			            part[0] = '0' + part[0]
			        end
			    elsif (+part[0].to_i == 0)
			        part[0] = ''
				end

				number = number.to_s.split('.')
			    number[0] = part[0]

			    #process the first group separator from decimal (.) only, the rest ignore.
			    #get the length of the last slice of split result.
			    pos_separator = ( szSep[1] && szSep[ szSep.length-1].length)
			    if (pos_separator)
			        integer = number[0]
			        str = ''
			        offset = integer.length % pos_separator
			        for i in 0..integer.length-1
			            str << integer[i] #ie6 only support charAt for sz.
			            #-pos_separator so that won't trail separator on full length
			            if (((i-offset+1)%pos_separator)== 0 && i<(integer.length-pos_separator) )
			                str << group
			            end
			        end
			        number[0] = str
			    end

			    number[1] = (mask[1] && number[1])? decimal+number[1] : ""
			    maskedNum = (isNegative ? '-' : '') + number[0] + number[1] #put back any negation and combine integer and fraction.
			else
				dec='.'
				sep=','
				begin
					num = MobiSys::Math.round(number, 2) if number.to_s != ""
				rescue
					num = number
				end
				num = number unless number
				num = num.to_s.sub(/\./, dec)
				dec = Regexp.escape dec
				maskedNum = num.reverse.gsub(/(\d\d\d)(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
				#puts ">>>number: #{number} maskednumber: #{maskedNum}"
			end
			return maskedNum
		end
		##################################################################################################


		def thosandSeperator(number)
			parts = number.to_s.split('.')
			parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,") if parts.size > 0
			parts.join('.')
		end
		##################################################################################################


		def attachMask(elementId)
			return_str = ""
			return_str << "<script>\n"
			return_str << "  $(\"input[name='#{elementId}']\").focus(function(){\n"
			return_str << "    number = $(\"input[name='#{elementId}']\").val();\n"
			return_str << "    while(number.indexOf(\",\") != -1){number = number.replace(/,/,\"\");}\n"
			return_str << "    $(\"input[name='#{elementId}']\").val(number);\n"
			return_str << "  });\n\n"

			return_str << "  $(\"input[name='#{elementId}']\").keypress(function(){\n"
			return_str << "     if (event.keyCode === 46 && (this.value.split('.').length === 2 || this.selectionStart == 0)) { return false; }"
			return_str << "     else { var regex = /^[0-9.\\b]+$/; "
			return_str << "       if( !regex.test(String.fromCharCode(event.which)) ) { event.preventDefault(); }"
			return_str << "  } });\n\n"

			return_str << "  $(\"input[name='#{elementId}']\").blur(function(){\n"
			return_str << "    $(\"input[name='#{elementId}']\").val(format( \"#,##0.##\", $(\"input[name='#{elementId}']\").val()));\n"
			return_str << "  });"
			return_str << "</script>\n"
			#puts ">>>return_str : #{return_str}"
			return_str
		end
		##################################################################################################


		def self.renderPanel?(facetId, product)
			isValid = false
			prod = product.getFacet(facetId) if product && !$ignore_product
			if prod
				isValid = true if prod.actionValue == "YES"
			elsif $ignore_product
				facet = Facet.loadObject(:first,:conditions=>{{:name=>'facetId'}=> facetId})
				if facet and facet.facetTypeCd == "COMPANY"
					$companyFacetCache ||= CompanyFacet.loadObject(:all)
					$companyFacetCache.each do |obj|
						if obj.facetCd == facetId and obj.actionValue == "YES"
							isValid = true
							break
						end
					end
				else
					isValid = true
				end
			else
				$companyFacetCache ||= CompanyFacet.loadObject(:all)
				$companyFacetCache.each do |obj|
					if obj.facetCd == facetId and obj.actionValue == "YES"
						isValid = true
						break
					end
				end
			end
			return isValid
		end
		##################################################################################################


		def self.getFacetMappedValue(facetId, product)
			returnValue = nil
			prod = product.getFacet(facetId) if product
			if prod
				returnValue = prod.actionValue
			else
				$companyFacetCache ||= CompanyFacet.loadObject(:all)
				$companyFacetCache.each do |obj|
					if obj.facetCd == facetId
						returnValue = obj.actionValue
						break
					end
				end
			end
			return returnValue
		end
		##################################################################################################


		def self.renderField?(metadataCd)
			isValid = false
			$metaDataCache ||= CompanyFieldMetadata.loadObject(:all)
			$metaDataCache.each do |obj|
				if obj.inputMetadataCd == metadataCd
					isValid = true
					break
				end
			end
			return isValid
		end
		##################################################################################################


		def self.getFacetValueByPlanOption(facetId, product, quotationProduct)
			renderType = false
			currFacet = product.getFacet(facetId) if product && !$ignore_product
			if currFacet
				if currFacet.actionValue == "YES"
					if currFacet.schemeId.to_s==""
						# if no riders are set show for all plan options
						renderType = true
					else
						renderType = !currFacet.schemeId.split(",").find{|planoption| planoption == quotationProduct.productPlanOptionCd }.nil?
					end
				end
			elsif $ignore_product
				facet = Facet.loadObject(:first,:conditions=>{{:name=>'facetId'}=> facetId})
				if facet and facet.facetTypeCd == "COMPANY"
					$companyFacetCache ||= CompanyFacet.loadObject(:all)
					$companyFacetCache.each do |obj|
						if obj.facetCd == facetId and obj.actionValue == "YES"
							renderType = true
							break
						end
					end
				else
					renderType = true
				end
			else
				#check if it is defined at a company level
				$companyFacetCache ||= CompanyFacet.loadObject(:all)
				$companyFacetCache.each do |obj|
					if obj.facetCd == facetId and obj.actionValue == "YES"
						renderType = true
						break
					end
				end
			end
			return renderType
		end
		##################################################################################################


		def self.numberRound(number, decimal = 0)
			number.to_f.round(decimal).to_s
		end
		##################################################################################################


		def self.formatNumber(number, format)
			#puts "inside formatNumber"
			commaIndex = format.index(',')
			decimalIndex = format.index('.')
			decimalDelimiter = "."
			commaDelimiter = ","
			numberDecimalArray = number.split(decimalDelimiter)

			if commaIndex && decimalIndex && commaIndex > decimalIndex
				decimalDelimiter = ","
				commaDelimiter = "."
			else
				decimalDelimiter = "."
				commaDelimiter = ","
			end

			if numberDecimalArray.length > 1 && numberDecimalArray[1].to_i != 0
				formatDecimalArray = format.split(decimalDelimiter)
				formatCommaArray = formatDecimalArray[0].split(commaDelimiter)
				numberOfDigits = formatCommaArray[formatCommaArray.length - 1].length

				getFormat = format.gsub( '#','\d' )
				formatForDigitsBeforeDecimal = getFormat.split(decimalDelimiter)
				formatForDigitsBeforeComma = formatForDigitsBeforeDecimal[0].split(commaDelimiter)
				digitFormat = formatForDigitsBeforeComma[formatForDigitsBeforeComma.length - 1]

				n = numberDecimalArray[0]
				maskedNum = n.reverse.gsub(/(#{digitFormat})(?=\d)/, "\\1#{commaDelimiter}").reverse
				maskedNum = maskedNum + decimalDelimiter + numberDecimalArray[1]
				#  puts ">>>>>>>>>>>>>number: #{number} maskednumber: #{maskedNum}"
			else
				getFormat = format.gsub( '#','\d' )
				formatForDigitsBeforeDecimal = getFormat.split(decimalDelimiter)
				formatForDigitsBeforeComma = formatForDigitsBeforeDecimal[0].split(commaDelimiter)
				digitFormat = formatForDigitsBeforeComma[formatForDigitsBeforeComma.length - 1]
				n = numberDecimalArray[0]
				maskedNum = n.reverse.gsub(/(#{digitFormat})(?=\d)/, "\\1#{commaDelimiter}").reverse
				#puts ">>>>>>>>>>>>>number: #{number} maskednumber: #{maskedNum}"
			end
			maskedNum
		end
		##################################################################################################


		def getQuestionnaireCheckbox(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil)
			if(lookupkey != DYNAMICLOOKUP)
				lookups = Lookupvalue.find(:all,
					:conditions=>{
						'key'=>lookupkey
					},
					:order=>'sortOrder',
					:orderdir=>'ASC'
				)
			else # (lookupkey == "DYNAMICARRAY")
				lookups = lookupdata
			end

			returnStr = ""
			radioName = ""
			lookup_name = ""
			begin
				if fieldname!=nil
					lookup_name = fieldname
				else
					lookup_name = lookupkey
				end
				fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]" unless object.nil?
				lookups.each_with_index do |lookup,index|
					if (lookupkey == 'FNA_FINANCIAL_NEED')
						returnStr << " <input type='checkbox' name='#{fieldname}#{index}' id='#{fieldname}#{index}' value='#{lookup.cd}'"
						returnStr << "checked='checked'" if (selectedvalue.is_a?(Array) && (selectedvalue.include? lookup.cd.to_i))
					elsif (lookupkey == 'PASSION_QUESTION' || lookupkey == 'CONTACT_FOR_SURVEY_QUESTION')
						returnStr << " <input type='checkbox' name='#{fieldname}' id='#{fieldname}#{index}' value='#{lookup.cd}' onclick='uncheckOtherOptions(this)'"
						if selectedvalue.to_s != ""
							if selectedvalue.is_a?(Array)
								selectedVal = selectedvalue[0].to_s
							else
								selectedVal = selectedvalue.to_s
							end
							returnStr << "checked='checked'" if selectedvalue.to_s != "" && lookup.cd.to_s == selectedVal
						end
					else
						returnStr << " <input type='checkbox' name='#{fieldname}' id='#{fieldname}#{index}' value='#{lookup.cd}'"
						if selectedvalue.to_s != ""
							if selectedvalue.is_a?(Array)
								selectedVal = selectedvalue[0].to_s
							else
								selectedVal = selectedvalue.to_s
							end
							returnStr << "checked='checked'" if selectedvalue.to_s != "" && lookup.cd.to_s == selectedVal
						end
					end
					returnStr << "/>"
					returnStr << " <label for='#{fieldname}#{index}'>#{Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)} </label>"
					returnStr << "<br/>"
					# if lookup.cd == "OTHERS"
					#   returnStr << "<div>"
					#   returnStr << renderTextField('otherPassion', object.otherPassion, "", "text", object, nil, 'maxlength="50"')
					#   returnStr << "</div><br>"
					# elsif lookup.cd == "FACEBOOK"
					#   returnStr << "<div>"
					#   returnStr << renderTextField('facebookAccountId', object.facebookAccountId, "", "text", object, nil, 'maxlength="50"')
					#   returnStr << "</div>"
					# elsif lookup.cd == "TWITTER"
					#   returnStr << "<div>"
					#   returnStr << renderTextField('twitterAccountId', object.twitterAccountId, "", "text", object, nil, 'maxlength="50"')
					#   returnStr << "</div>"
					# end
				end
			rescue StandardError => se
				#puts "Exception occured in getQuestionnaireRadioButton #{se}"
				#puts se.backtrace
			end
			return returnStr
		end
		##################################################################################################


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
						if Localization::LabelCache.instance.getLabel(lookup.desc.to_sym).to_s != ""
							lookupHash[lookup.cd] = Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)
						elsif Localization::LabelCache.instance.getLabel(lookup.cd.to_sym).to_s != ""
							lookupHash[lookup.cd] = Localization::LabelCache.instance.getLabel(lookup.cd.to_sym)
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
				toreturn_str << "fieldTargetValueMapFilterSetup('" << mappingHash.to_json << "', '" << filterable.to_s << "', '" << getObjectMapping(object) << "');"
				return toreturn_str
			end
		end
		##################################################################################################


		#Function to deeply merge two hashes
		def self.deep_merge(first, second)
			merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
			return first.merge(second, &merger)
		end
		##################################################################################################


		#Function to mask fields as per given decimal format or in OfflineApplication
	 	def self.attachMaskAll(functionRequired = false)
	    	toreturn_str = ""
	    		if $attachMaskFieldsHash
	    			toreturn_str << "<script>\n"
	    			toreturn_str << "function attachMaskAll(){" if functionRequired
		    		$attachMaskFieldsHash.each do |mask,fieldIds|
		    			if mask.to_s == ""
				    		mask = "#,##0.##" #default masking format
				    	end
				    	ids = fieldIds.join(",")
						toreturn_str << "  $(\"#{ids}\").focus(function(){\n"
						toreturn_str << "    number = $(this).val();\n"
						toreturn_str << "    while(number.indexOf(\",\") != -1){number = number.replace(/,/,\"\");}\n"
						toreturn_str << "    $(this).val(number);\n"
						toreturn_str << "  });\n\n"

						regex = mask.include?(".") ? '/^[0-9.\\b]+$/' : '/^[0-9\\b]+$/'
						mask = mask + "." unless mask.include?(".")

						toreturn_str << "  $(\"#{ids}\").keypress(function(){\n"
						toreturn_str << "     if (event.keyCode === 46 && (this.value.split('.').length === 2 || this.selectionStart == 0)) { return false; }"
						toreturn_str << "     else { var regex = #{regex}; "
						toreturn_str << "       if( !regex.test(String.fromCharCode(event.which)) ) { event.preventDefault(); }"
						toreturn_str << "  } });\n\n"

						toreturn_str << "  $(\"#{ids}\").blur(function(){\n"
						toreturn_str << "  if ($(this).val()!=\"\"){\n"
						toreturn_str << "    $(this).val(format( \"#{mask}\", $(this).val()));\n"
						toreturn_str << "  }"
						toreturn_str << "  });"
					end
					toreturn_str << "  }" if functionRequired
					toreturn_str << "</script>\n"
					$attachMaskFieldsHash = nil
				end
			return toreturn_str
		end
		##################################################################################################


		# Function to detect connectivity with the online server
		def self.detectConnection(url="")
			# url = Application.getValue('online_server_url').value if url.to_s == ""
			# if System::get_property('platform') == 'ANDROID' && !Rho::System.isRhoSimulator
		 #      response = Rho::Network.get({:url => url,:verifyPeerCertificate=> $ssl_verify_peer, :headers => {"detectConnection"=>"detectConnection"}, :body => "detectConnection"})
		 #    else
		 #      response = Rho::Network.get({:url => url,:verifyPeerCertificate=> false})
		 #    end
			# if response.has_key?("status") && response["status"] == "ok"
				return true
			# else
			# 	return false
			# end
		end
		##################################################################################################


		# Function to extract data from captured image
		def self.documentTextDetection(imageBase64, useOnlineMode=true,documentCdObj=nil, callbackFunction="processOfflineOCRData")
			textAnnotations = ""
			p "useOnlineMode=====#{useOnlineMode}"
			p "defined?(Rho::Ocr)====#{defined?(Rho::Ocr)}"
			if false#!useOnlineMode && defined?(Rho::Ocr) #&& !(System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection('https://www.google.com/'))
				# if System::get_property('platform') == 'APPLE'
				# 	imageBase64 = "data:image/jpg;base64,"+imageBase64.to_s
				# end
				@@documentCdObj = documentCdObj
				# if @@controllerName && @@controllerName.to_s == ""
					@@controllerName = "Lead"
				# end
				# Rho::Ocr.documentTextDetection(imageBase64.to_s, "/app/#{@@controllerName}/#{callbackFunction}")
				puts "inside document text detection *******"
				textAnnotations = Rho::Ocr.documentTextDetection(imageBase64.to_s)

				puts "in offline OCR------"
				puts "~~~~~~extractedData offline ocr: #{textAnnotations}"
				extractedData = processOCRData(textAnnotations['extractedData'],documentCdObj)
			elsif System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection('https://www.google.com/')
				puts "in online OCR------"
				requestHash = {
					"requests"=> [
						{
							"image"=> {"content"=> imageBase64.to_s},
							"features"=> [{"type"=> "DOCUMENT_TEXT_DETECTION"}]
						}
					]
				}
				result = Rho::Network.post({
					url: 'https://vision.googleapis.com/v1/images:annotate?key=AIzaSyBYPMV90dlGGtaMfNy31J6w2xeRndRQT68',
					headers: { 'Content-Type' => 'application/json' },
					verifyPeerCertificate: false,
					body: requestHash.to_json
				})
				# puts "ocr result----#{result['body']}"
				response = Rho::JSON.parse(result['body'])
				if response != nil && response.key?("responses") && !response["responses"][0].empty?
					textAnnotations = response["responses"][0]["textAnnotations"][0]["description"]
					puts "~~~~~~extractedData online ocr: #{textAnnotations}"
					if @@persistOcr
						if @@offlineFile
							offlineFile = OfflineFile.loadObject(:first, :conditions=>{'object'=>@@offlineFile.object})
							offlineFile.ocrExtractedText = textAnnotations
							offlineFile.persistAll
							@@offlineFile = nil
							@@imageBase64 = nil
						end
					else
						@@offlineFile.ocrExtractedText = textAnnotations
						extractedData = processOCRData(textAnnotations,documentCdObj)
					end
				end
			end
			return extractedData
		end
		##################################################################################################


		def processOfflineOCRData
			extractedData = MobiSys::BrowserHelper.processOCRData(@params['extractedData'],@@documentCdObj)
			@@documentCdObj = nil
			if extractedData.to_s != ""
				returnHash = extractedData.select{|k,v| k.to_s != "rawText"}
				returnHash['containerId'] = @@containerId
				WebView.execute_js("extractImageData(#{returnHash.to_json})")
			end
		end
		##################################################################################################
		def self.setOcrDetails(isPersistOcr,offlineFile)
			@@persistOcr = isPersistOcr
			@@offlineFile = offlineFile
		end
		##################################################################################################


		def self.processOCRData(textAnnotations,currDocumentDO = nil)
			extractedData = {}
			extractedTextList = textAnnotations.split("\n")
			extractedData[:rawText] = textAnnotations
			if currDocumentDO == nil
				documents = Document.loadObject(:all,
					:conditions=>{
						{
	                        :name=>'ocrIdentifier',
	                        :op => 'IS NOT'
	                    }=> nil
	                },
					:order => 'ocrPriority'
				)
			else
				documents = [currDocumentDO]
			end

			# ID type derivation loop
			document = nil
			modifiedExtractedTextList = []
			removeExtractedTextList = []
			extractedTextList.each do |extractedText|
				result = false
				extractedText.gsub!(/[^A-Za-z0-9\/\.\s\-]/,"")
				extractedText.strip!
				if extractedText.to_s != ""
					modifiedExtractedTextList.push(extractedText)
				end
			end
			documents.each do |doc|
				ocrIdentifierArr = doc.ocrIdentifier.split("|")
				matchFound = 0

				doesInclude = false
				modifiedExtractedTextList.each do |extText|
					if ocrIdentifierArr.map{|x| extText.downcase.include? x.downcase}.include? true
						removeExtractedTextList.push(extText)
						matchFound = matchFound + 1
						doesInclude = true
					end
				end
				if matchFound > 0
					extractedData[:identityTypeCd] = doc.documentCd
					document = doc
					result = true
					break
				end
			end

			if removeExtractedTextList.size > 0
				removeExtractedTextList.uniq.each do |removeExtractedText|
					modifiedExtractedTextList.delete(removeExtractedText)
				end
			end
			# Field data derivation loop
			if document && document.DocumentPropertyList.size > 0
				listDocumentProperty = document.DocumentPropertyList
				listDocumentProperty.sort!{|x,y| x.priority.to_i <=> y.priority.to_i}
				listDocumentProperty.delete_if do |documentProperty|
					result = false
					modifiedExtractedTextList.delete_if do |extractedText|
						next if extractedText.to_s == ""
						if documentProperty.lookupValues.to_s != ""
							derivedValue = nil
							if documentProperty.attributeRegex == "identityTypeCd"
								derivedValue = documentProperty.lookupValues.split(",")
									.select {
										|e| e if e.split(":").first == extractedData[:identityTypeCd]
									}
									.map {
										|e| e.split(":").last
									}[0]
							elsif (Regexp.new(documentProperty.attributeRegex).freeze =~ extractedText.downcase) != nil
								derivedValue = documentProperty.lookupValues.split(",")
								.select{
									|e| e if e.split(":").first == extractedText.downcase.scan(Regexp.new(documentProperty.attributeRegex)).first
								}
								.map {
									|e| e.split(":").last
								}[0]
							end
						else
							regEx = documentProperty.attributeRegex
							regExOptions = regEx[regEx.rindex('/')..-1] 	#getting options for regex
							regEx = regEx[1,regEx.rindex('/')-1] 			#getting regex excluding start and end marker '/'
							regExp = Regexp.new(regEx,regExOptions)
							if (regExp.freeze =~ extractedText.downcase) != nil
								derivedValue = extractedText.scan(regExp).last
							end
						end

						if derivedValue
						    ocrPrePopulationArray =	documentProperty.ocrPrePopulationMetadata.split(",")
						    ocrPrePopulationArray.each do |attribute|
						    	extractedData[attribute] = derivedValue
						    end
							result = true
							break
						end
						result
					end
					result
				end
			end
			extractedData = ocrCustomDataProcessing(modifiedExtractedTextList, extractedData)
			return extractedData
		end
		##################################################################################################


		# Function to process data extracted from OCR
		def self.ocrCustomDataProcessing(extractedTextList, extractedData)
			# Special field data derivation loop
			if extractedData[:identityTypeCd] == "PASSPORT"
				extractedTextList.each_with_index do |extractedText, index|
					if extractedData[:fullName].to_s == "" && extractedText.downcase.include?("surname")
						extractedData[:fullName] = extractedTextList[index+2] + " " +extractedTextList[index+1]
					end
				end
			end

			extractedData.each do |key, value|
				if extractedData[:identityTypeCd] == "DRIVLICE" && extractedData[key].to_s.downcase.include?("name")
					extractedData[key] = extractedData[key].gsub(/(name)\s*/i, "")
				end
				if extractedData[key].to_s.downcase.include?("dob")
					extractedData[key].gsub!(/(dob)\s*/i, "")
				end
				if key.to_s.downcase.include?("dob") || key.to_s.downcase.include?("birthDt")
					extractedData[key].gsub!("-", "/")
				end
				if extractedData[:fullName].to_s == ""
					nameArr = extractedData[key].to_s.split(" ")
				else
					nameArr = extractedData[:fullName].to_s.split(" ")
				end
				if key.to_s.downcase.include?("firstname")
					extractedData[key] = nameArr[0]
					extractedData[key] = nameArr[0] + " " + nameArr[1] if nameArr.size == 4 || nameArr.size == 5
				end
				if key.to_s.downcase.include?("middlename")
					extractedData[key] = ""
					extractedData[key] = nameArr[1] if nameArr.size == 3
					extractedData[key] = nameArr[2] if nameArr.size == 5
				end
				if key.to_s.downcase.include?("lastname")
					extractedData[key] = ""
					extractedData[key] = nameArr[1] if nameArr.size == 2
					extractedData[key] = nameArr[2] if nameArr.size == 3
					extractedData[key] = nameArr[2] + " " + nameArr[3] if nameArr.size == 4
					extractedData[key] = nameArr[3] + " " + nameArr[4] if nameArr.size == 5
				end
			end

			return extractedData
		end
		##################################################################################################


		def camera_callback_ocr
			fileName = nil
			if @params['status'] == 'ok'
				image_uri = @params['image_uri']
				image_uri = @params['imageUri'] if image_uri.to_s == ""
				if ((System::get_property('platform') == 'ANDROID') || (System::get_property('platform') == 'APPLE') || (System::get_property('platform') == "WINDOWS_DESKTOP"))
					Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
					realFileLocation = Rho::RhoApplication.get_blob_path(image_uri)
					@@imageBase64 = MobiSys::Encryption.encodeFileContents(realFileLocation)
					# Delete image file from location once record persisted in db
					File.delete(realFileLocation) if File.exists?(realFileLocation)
					extractedData = MobiSys::BrowserHelper.documentTextDetection(@@imageBase64, false, nil, "processOfflineOCRData")
					if extractedData.to_s != ""
						returnHash = extractedData.select{|k,v| k.to_s != "rawText"}
						returnHash['containerId'] = @@containerId
						WebView.execute_js("extractImageData(#{returnHash.to_json})")
					end
				end
			end
		end

		def logInfo(message, category = "APP")
			Rho::Log.info(message, category)
		end

		def logError(message, exception = nil, category = nil)
			category = self.class.to_s if category == nil
			if exception.to_s != ""
				Rho::Log.error("#{message}--->#{exception}\n#{exception.backtrace}", category)
			else
				Rho::Log.error("#{message}", category)

			end
		end

		def logWarning(message, category = "APP")
			Rho::Log.warning(message, category)
		end

		def logFatalError(message, exception, category = "APP")
			Rho::Log.fatalError("#{message}--->#{exception}\n#{exception.backtrace}", category)
		end

		def openstruct_to_hash(object, hash = {})
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

	    def getLookupValDesc(lookupKey, lookupDataCd)
			lookup_desc = ""
			lookup_desc = getOfflineLookupData(lookupKey, {},lookupDataCd)
			return lookup_desc
		end

		def getLookupDataObject(lookupKey,lookupDataCd)
        	lookup_value = Lookupvalue.find(
            :first, 
            :select => ['key','cd','desc','companyCd', 'typeCd', 'valueFrom', 'valueTo', 'sortOrder', 'additionalField1', 'additionalField2', 'defaultFl'], 
            :conditions=>{{ :name => 'key'} => lookupKey, {:name => 'cd'} => lookupDataCd})
        	return lookup_value
    	end
		##################################################################################################
	end

	class JSONPostError < StandardError
	end

	class AuthenticationError < StandardError
	end

	class UpgradeApplicationError < StandardError
	end

	class ServerUnavailableError < StandardError
	end

	class InvalidSSLCertificateError < StandardError
	end
end

begin
	require 'CommonModules/mobisysbrowserhelper_company'
rescue LoadError => e
	puts 'mobisysbrowserhelper_company not included'
end

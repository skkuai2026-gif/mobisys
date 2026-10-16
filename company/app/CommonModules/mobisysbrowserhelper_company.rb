require 'helpers/browser_helper'
require 'time'
require 'zlib'
require 'stringio'
require 'json'
require 'base64'
require 'CommonModules/entityschema'
require 'fileutils'

module MobiSys
	#Browserhelper module contains utility methods used by the functional modules
	#Add any new method which is used by the UI/Controller for UI actions in this module
	module BrowserHelper		
		def doJSONPost(*args)
			$doJSONPostErrors = {}
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
				p "password====#{password}"
				dimoge = Application.getValue('Dimoge').value

				inputHash['USERNAME'] = userName
				inputHash['PASSWORD'] = $rhoconfig[:use_okta_authentication].to_s != "YES" ? password : $accessToken
				# inputHash['PASSWORD'] = password
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
				sha256_checksum = MobiSys::Encryption.calculate_zip_checksum(local_path_to_zip)
          		# password = $accessToken if $rhoconfig[:use_okta_authentication].to_s == "YES"


				uploadStatus = Rho::AsyncHttp.upload_file(
					:url=>upload_url,
					:ssl_verify_peer=> $ssl_verify_peer,
					:headers => {"username"=>userName,"password"=>password,"beanName"=>url,"fileName" => fileName, "dataId"=>sha256_checksum, "Dimoge" => dimoge},
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
				puts "result--------#{result}"
				
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
						$doJSONPostErrors[403] = getLabelValue('DEVICEDEACTIVATED')
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
								$doJSONPostErrors[403] = getLabelValue('DEVICEDEACTIVATED')
								raise MobiSys::JSONPostError.new(getLabelValue('DEVICEDEACTIVATED'))
							else
								$doJSONPostErrors[403] = getLabelValue('USERDISABLED')
								raise MobiSys::JSONPostError.new(getLabelValue('USERDISABLED'))
							end
						else
							$doJSONPostErrors[403] = getLabelValue('USERDISABLED')
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
						$doJSONPostErrors[403] = getLabelValue('UPGRADEAPPLICATION')
						raise MobiSys::UpgradeApplicationError.new(getLabelValue('UPGRADEAPPLICATION'))
					elsif authenticationMessage
						$doJSONPostErrors[403] = authenticationMessage
						raise MobiSys::JSONPostError.new(authenticationMessage)
					elsif deviceSysTime
						$doJSONPostErrors[403] = getLabelValue('DEVICESYNTIMEERROR')
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
					#$errors['USERNAMEPWD'] = getLabelValue('USERNAMEPWD')
					$errors['RESTARTAPP'] = getLabelValue('RESTARTAPP')
					WebView.navigate(Rho::RhoConfig.start_path)

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
					$redirectionFlag = false
					$doJSONPostErrors[403] = "forbidden"
					#raise MobiSys::AuthenticationError.new(getLabelValue('USERNAMEPWD'))
					raise MobiSys::AuthenticationError.new(getLabelValue('RESTARTAPP'))
				elsif result['status']=='error' && result['error_code']=="1" && Rho::Log.readLogFile(300).to_s.include?('SSL')
					puts "SSL peer certificate or SSH remote key was not OK"

					if deviceSeq.to_s != ""
						Dir.glob("#{Rho::Application.userFolder}/*_#{deviceSeq}*").each do |file|
							File.delete(file) if File.exists?(file)
						end
					end
					$doJSONPostErrors[result['http_error']] = getLabelValue('SERVERERROR')
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
					$doJSONPostErrors[result['http_error']] = getLabelValue('SERVERERROR')
					raise MobiSys::ServerUnavailableError.new(getLabelValue('SERVERERROR'))
				end
			end
		end

		#################To improve Questionnaire Performance############
		def getQuestionSetHash
		    begin
		      dbversion = Application.getValue('DBVERSION').value
		      unless $questionSetData
		        if !File.file?(Rho::Application.userFolder.to_s+"questionSetData_#{dbversion}.txt")
		        	Dir.glob("#{Rho::Application.userFolder}/questionSetData_*").each do |file|
                File.delete(file) if File.exists?(file)
            	end
	            $questionSet = QuestionSet.loadObject(:all)
	            questionSetData = $questionSet.map{|x| x.hashForSync}
	            fileObject = File.new(Rho::Application.userFolder.to_s+"questionSetData_#{dbversion}.txt",'w+')
	            fileObject.write(questionSetData.to_json)
	            fileObject.rewind   # set cursor on starting
							fileText = fileObject.read()
	            fileObject.close()
	            questionSetData = Rho::JSON.parse(fileText)
	            $questionSetData = questionSetData.map{|x|MobiSys::MobiSysEntitySchema.from_json("QuestionSet",x)}
		        else
	            fileObject = File.open(Rho::Application.userFolder.to_s+"questionSetData_#{dbversion}.txt","r")
	            fileText = fileObject.read()
	            questionSetData = Rho::JSON.parse(fileText)
	            $questionSetData = $questionSet = questionSetData.map{|x|MobiSys::MobiSysEntitySchema.from_json("QuestionSet",x)}
			    		fileObject.close()
			    	end
		      end
		      return
		    rescue Exception => e
		      puts "Exception while $questionSetHash creation ---> #{e}"
		    end
		end
		####################################################################

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


		#####################################################################

		# fetch label values
		def self.getLabelValue(labelKey, errorParameters=[])
			toreturn_str = ""
			begin
				toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym)
			rescue StandardError => se
				puts se
			end
			toreturn_str = MobiSys::CommonUtil.replacePlaceHolders(toreturn_str,errorParameters) if errorParameters.compact.any?
			## Handle <b> tag: if present, convert text inside <b> to Unicode bold letters
			# toreturn_str = toreturn_str =~ /<b>/i ? toreturn_str.gsub(/<b>(.*?)<\/b>/i){ $1.chars.map{ |c| c =~ /[A-Z]/ ? (c.ord+0x1D3BF).chr(Encoding::UTF_8) : c =~ /[a-z]/ ? (c.ord+0x1D3B9).chr(Encoding::UTF_8) : c }.join } : toreturn_str

			return toreturn_str
		end

		def geo_callback
			@@lat = 0
			@@long = 0

			if @params['status'] =='ok'
				#GeoLocation.set_notification '', '', 2
				#WebView.navigate url_for(:action => :map_all)
				# @@lat = GeoLocation.latitude
				# @@long = GeoLocation.longitude
				#Alert.show_status("Geo location callback", "Geo location received with lat #{@@lat} and long #{@@long}", "OK")
			end
		end

		def getQuestionSetQuestionHash
			dbversion = Application.getValue('DBVERSION').value
			begin
		    	if $inputTypeOfQuestion.empty?
			      	if !File.file?(Rho::Application.userFolder.to_s+"questionSetQuestionData_#{dbversion}.txt")
			        	Dir.glob("#{Rho::Application.userFolder}/questionSetQuestionData_*").each do |file|
	                		File.delete(file) if File.exists?(file)
	            		end
				      	$questionSetQuestion =  QuestionSetQuestion.loadObject(:all)
				      
			            $questionSetQuestion.each do |questionSet|
							$inputTypeOfQuestion["#{questionSet.questionSetCd}_#{questionSet.dataElementCd}"] = "#{questionSet.inputTypeCd}"
						end
						questionSetQuestionData = $questionSetQuestion.map{|x| x.hashForSync}
			            fileObject = File.new(Rho::Application.userFolder.to_s+"questionSetQuestionData_#{dbversion}.txt",'w+')
			            fileObject.write(questionSetQuestionData.to_json)
			            fileObject.close()
			      	else
				      	fileObject = File.open(Rho::Application.userFolder.to_s+"questionSetQuestionData_#{dbversion}.txt","r")
			            fileText = fileObject.read()
			            questionSetQuestionData = Rho::JSON.parse(fileText)
			            $questionSetQuestion = questionSetQuestionData.map{|x|MobiSys::MobiSysEntitySchema.from_json("QuestionSetQuestion",x)}
					    		fileObject.close()
					    $questionSetQuestion.each do |questionSet|
							$inputTypeOfQuestion["#{questionSet.questionSetCd}_#{questionSet.dataElementCd}"] = "#{questionSet.inputTypeCd}"
						end
				    end
			 	end
		    rescue Exception => e
		    	puts "Exception encountered in getQuestionSetQuestionHash----#{e.inspect}"
		    end
		end

		# Extracted method for setting up $inputTypeOfQuestion
		def populateInputTypeOfQuestion(question_set_question)
		  $inputTypeOfQuestion ||= {} # Ensure it's initialized
		  question_set_question.each do |questionSet|
		    $inputTypeOfQuestion["#{questionSet.questionSetCd}_#{questionSet.dataElementCd}"] = questionSet.inputTypeCd.to_s
		  end
		end

		# Function to extract data from captured image
		def self.documentTextDetection(imageBase64, useOnlineMode=true,documentCdObj=nil, callbackFunction="processOfflineOCRData")
			textAnnotations = ""
			if false#!useOnlineMode && defined?(Rho::Ocr) #&& !(System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection('https://www.google.com/'))
				# if System::get_property('platform') == 'APPLE'
				# 	imageBase64 = "data:image/jpg;base64,"+imageBase64.to_s
				# end
				@@documentCdObj = documentCdObj
				# if @@controllerName && @@controllerName.to_s == ""
					@@controllerName = "Lead"
				# end
				# Rho::Ocr.documentTextDetection(imageBase64.to_s, "/app/#{@@controllerName}/#{callbackFunction}")
				textAnnotations = Rho::Ocr.documentTextDetection(imageBase64.to_s)

				puts "in offline OCR------"
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
				response = Rho::JSON.parse(result['body'])
				if response != nil && response.key?("responses") && !response["responses"][0].empty?
					textAnnotations = response["responses"][0]["textAnnotations"][0]["description"]
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
				# p "attrToSendList====#{attrToSendList}"
				attrToSendList.each do |att|
					next if att.to_s=='source_id'
					# if(hash.has_key?(att.to_s) && hash[att.to_s] != nil && !hash[att.to_s].is_a?(Array) && !hash[att.to_s].is_a?(Hash))
					if hash.has_key?(att.to_s) && !hash[att.to_s].nil? && (!hash[att.to_s].is_a?(Array) && !hash[att.to_s].is_a?(Hash) || (className.to_s == "PolicyPartyContainer"))

						attMethodName = "#{att}="
						object.send(attMethodName, hash[att.to_s])
					end
				end
			end
			return object
		end


		############################
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
				extractedText.gsub!(/[^A-Za-z0-9\/\.\s\-]/, "")
				extractedText.strip!
				if extractedText.to_s != ""
					modifiedExtractedTextList.push(extractedText)
				end
			end
			documents.each do |doc|
				ocrIdentifierArr = doc.ocrIdentifier.split("|")
				matchFound = 0

				doesInclude = false
				ocrIdentifierArr.each do|ocrIden|
					result=false
					modifiedExtractedTextList.each do |extText|
						flag = extText.downcase.include?(ocrIden.downcase)
						if flag
							removeExtractedTextList.push(extText)
							matchFound = matchFound + 1
							result = true
							doesInclude = true
							break
						end

					end
					if !result
						break
					end
				end
				if ocrIdentifierArr.size.to_i == matchFound
					extractedData[:identityTypeCd] = doc.documentCd
					document = doc
					result = true
					break
				end
			end
			if removeExtractedTextList.size > 0
				removeExtractedTextList.each do |removeExtractedText|
					modifiedExtractedTextList.delete(removeExtractedText)
				end
			end
			if document && document.DocumentPropertyList.size > 0
				listDocumentProperty = document.DocumentPropertyList
				listDocumentProperty.sort!{|x,y| x.priority.to_i <=> y.priority.to_i}
				listDocumentProperty.delete_if do |documentProperty|
					if removeExtractedTextList.size > 0
						removeExtractedTextList.each do |removeExtractedText|
							modifiedExtractedTextList.delete(removeExtractedText)
						end
					end
					result = false
					modifiedExtractedTextList.delete_if do |extractedText|
						next if extractedText.to_s == ""
						# derivedValue = nil
						if documentProperty.lookupValues.to_s != ""
							if documentProperty.attributeRegex == "identityTypeCd"
								derivedValue = documentProperty.lookupValues.split(",")
									.select {
										|e| e if e.split(":").first == extractedData[:identityTypeCd]
									}
									.map {
										|e| e.split(":").last
									}[0]
								# break if derivedValue
							elsif (Regexp.new(documentProperty.attributeRegex).freeze =~ extractedText.downcase) != nil
								test1 = extractedText.downcase.scan(Regexp.new(documentProperty.attributeRegex)).first
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
							regEx = regEx[1...regEx.rindex("/")] if regEx
							regExp = Regexp.new(regEx, Regexp::IGNORECASE) if regEx
							if (regExp.freeze =~ extractedText.downcase) != nil
								derivedValue = extractedText.scan(regExp)
							end
						end
						p "derivedValue===========#{derivedValue}"
						if derivedValue
						    ocrPrePopulationArray =	documentProperty.ocrPrePopulationMetadata.split(",")
						    ocrPrePopulationArray.each do |attribute|
						    	extractedData[attribute] = derivedValue
						    end
							result = true
							removeExtractedTextList.push(extractedText)
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
		############################
		# Function to process data extracted from OCR
		def self.ocrCustomDataProcessing(extractedTextList, extractedData)
			p "ocrCustomDataProcessing=company********===#{extractedTextList}"
			ocrCustomDataProcessingSUNPH(extractedTextList,extractedData)
			# Special field data derivation loop
			if extractedData[:identityTypeCd] == "PAS"
				extractedTextList.each_with_index do |extractedText, index|
					if extractedData[:fullName].to_s == "" && extractedText.downcase.include?("surname")
						extractedData[:fullName] = extractedTextList[index+2] + " " +extractedTextList[index+1]
					end
				end
			end
			documentId = extractedData[:identityTypeCd]

			extractedData.each do |key, value|
				if extractedData[:identityTypeCd] == "DRL" && extractedData[key].to_s.downcase.include?("name")
					extractedData[key] = extractedData[key].gsub(/(name)\s*/i, "")
				end
				if key.to_s.downcase.include?("dob") || key.to_s.downcase.include?("birthdt") || key.to_s.downcase.include?("issuedt") || key.to_s.downcase.include?("expirydt")
					value = extractedData[key]
					dateConverted = convertToFormattedDate(value.to_s,documentId)
					extractedData[key] = dateConverted
				elsif key.to_s.downcase.include?("field4")
					value = extractedData[key]
					country = countryCd("CNTRY",value.to_s)
					extractedData[key] = country
				elsif key.to_s.downcase.include?("field7")
					value = extractedData[key]
					country = countryCd("CTZEN",value.to_s)
					extractedData[key] = country
				elsif key.to_s.downcase.include?("countryofbirth")
					value = extractedData[key]
					country = countryCd("BTLOC",value.to_s)
					extractedData[key] = country
				end
			end
			return extractedData
		end

		def self.java_to_ruby_date_format(fmt)
  			fmt.gsub("yyyy", "%Y").gsub("MM", "%m").gsub("dd", "%d")
		end

		def self.convertToFormattedDate(dateStr,documentId)
			p "dateStr===11====#{dateStr}"
			ocrDateFormatLookup = Lookupvalue.loadObject(:all, :conditions=> {:key => "OCRDATEFORMAT" })
			dateFormatDoc = ""
			if ocrDateFormatLookup.size > 0
	        ocrDateFormatLookup.each do |ocrLkup|
	            if 	ocrLkup.cd.to_s == documentId
	            	dateFormatDoc = ocrLkup.desc
	            end
	        end
	        end

	       	targetFormat = "dd/MM/yyyy";
	   		if dateStr.is_a?(String) && dateStr.strip.start_with?("[")
			  	dateStr = JSON.parse(dateStr)
			end
		 	if dateStr.is_a?(Array)
    			dateStr = dateStr.first
    		end
		  	begin
				ruby_format = java_to_ruby_date_format(dateFormatDoc)
		
				parsed_date1 = Date.strptime(dateStr.to_s, ruby_format)
			rescue ArgumentError => e
    		puts "Exception in format conversion: #{e.class} - #{e.message}"
			end
			# parsed_date1 =Date.strptime(dateStr, dateFormatDoc)
			if parsed_date1.to_s != ""
			parsed_date = Date.parse(parsed_date1.to_s).strftime("%d/%m/%Y")
			else
			parsed_date = Date.parse(dateStr.to_s).strftime("%d/%m/%Y")
			end
			p "parsed_date===#{parsed_date}"
			return parsed_date
		end

		def self.countryCd(lookupkey,extractedText)
			lookUpData = Lookupvalue.find(:all, :conditions => { 'key' => lookupkey })
			lookUpData.each do|lookUp|
				# p "lookUp====#{lookUp}"
				if lookUp && lookUp.additionalField2.to_s != ""

					if lookUp.additionalField2.to_s.include?(",")
                		additionalField2List = lookUp.additionalField2.to_s.split(",")
	                	additionalField2List.each do |additionalField2| 
	                   		extractedText = lookUp.cd  if additionalField2.to_s.downcase == extractedText.to_s.downcase
	                   		break
	                	end
					else
						if(lookUp.additionalField2.to_s.downcase == extractedText.to_s.downcase)
							extractedText = lookUp.cd
							break
						end
					end
					
				end
			end
			return extractedText
		end

		def self.ocrCustomDataProcessingSUNPH(extractedTextList,extractedData)
			if extractedData.to_s == ""
			 	return
			end
			updated_data = {}
			if extractedData[:identityTypeCd] == "DRL"
			 	# fullName = extractedTextList[4]
			 	count = 0
			 	extractedRawData = extractedData[:rawText].split("\n")
			 	fullName = extractedRawData[5]
			 	licenseNoExpDt = extractedRawData[20]
			 	pattern = /^([A-Z0-9\-]+)\s+(\d{4}\/\d{2}\/\d{2})$/
				if regMatch = licenseNoExpDt.match(pattern)
				  license_no = regMatch[1]
				  date = regMatch[2]
				  extractedData["PartyIdentityDO.identityNum"] = license_no
				  extractedData["PartyIdentityDO.expiryDt"] = date
				end
			 	if fullName.to_s != ""
			 	  # parsedName = parseName(fullName)
			 	  parsedName  = fullName.split(",")	
			 	  parsedName.each do|namee|
			 	  	if(count.to_i == 0)
			 	  	  extractedData["PartyDO.lastName1"] = namee
			 	  	end
			 	  	if (count.to_i == 1)
			 	  		extractedData["PartyDO.firstName1"] = namee.strip
			 	  	end
			 	  	if (count.to_i == 2)
			 	  		extractedData["PartyDO.middleName1"] = namee
			 	  	end
			 	  	count += 1
			 	  end
			 	  # return
			 	else
			 		p "no name found"
			 	end
			end
			extractedData.each do |key, value|

				if extractedData[:identityTypeCd] == "UMID" && (key.to_s.downcase.include?("birthdt"))
					text_split = extractedData[key]
					if text_split && !text_split.first.strip.empty?
						parts = text_split.first.strip.split(/\s+/)
						if parts.size >= 6
							sex = parts[1];  #"M" or "F"
	                        dob = parts[5];  #"YYYY/MM/DD"
							if sex == "M"
							  sex = "MALE" 
							elsif sex == "F" 
							  sex = "FEMALE" 
							else
							  p "Invalid gender code"
							end

							updated_data["PartyDO.genderCd"] = sex
	                    	updated_data["QuotationDO.genderCd"] = sex
	                    	updated_data[key] = dob
						end
					end
				end
			end
			extractedData.merge!(updated_data)
			return extractedData
		end

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
            elsif @params['status'].to_s == "error"
				Alert.show_popup({
		                          :message => getLabelValue("#{@params['message']}"),
		                          :title => 'Warning',
		                          :icon => :info,
		                          :buttons => ["OK"]
		                        })
			end
		end

	end
end
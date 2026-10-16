require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/encryption'
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'
require 'json'
require 'date'


class AgentRegController < BaseRestController
	include BrowserHelper
	include MobiSys::BrowserHelper

	def initialize
		# logInfo("~~~in AgentRegController initialize")
	end

	def addError(errors, errorKey, errorMsg)
		errors[errorKey] = errorMsg unless errors.has_key? errorKey
	end

	def login
		agentRegHash = {}
		data = {}
		responseHash = Hash.new
		errors = Hash.new
		if @params.has_key? ('request-body')
			begin
				agentRegHash = Rho::JSON.parse(@params['request-body'])	
			rescue Exception => e
				logError("Error in parsing request-body",e, LOGCATEGORY)
			end
    	end 
    	return false if !agentRegHash.has_key?('userId')
    	if agentRegHash.has_key?('online_server_url') && agentRegHash['online_server_url'].to_s != ""
	    	online_server = Application.getValue('online_server_url')
			online_server.value = agentRegHash['online_server_url'].to_s
			online_server.save 
		end
    	$agentRegHash = agentRegHash
    	agentRegHash['userId'] = agentRegHash['userId'].to_s.upcase
		registeredAgentReg = AgentReg.forUserId(agentRegHash['userId'], true) if Application.getValue(MobiSys::MOBISYSDEVICEID)
		disabledAppObject = Application.getValue(MobiSys::DEVICEDISABLED)
		@registered = (registeredAgentReg)? true : false
		logInfo("Mode is @registered " + @registered.to_s)
		currentAgentReg = AgentReg.new(:userId => agentRegHash['userId'], :regPass => agentRegHash['regPass'])
		currentAgentReg.activeDays = registeredAgentReg.activeDays if @registered
		currentAgentReg.lastLogin = registeredAgentReg.lastLogin if @registered
		has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
		$agentProduct = ""
		# has_network = false # for offline test only
		begin
			$login = false
			upgrading = false
			if disabledAppObject
				addError(errors,'REGISTERDEACTIVATEDDEVICE', getLabelValue('REGISTERDEACTIVATEDDEVICE'))
			else
				agentLastLoginTime = Time.now
				agentLastLoginTimeAppObj = Application.getValue('agentLastLoginTimestamp').value
				agentLastLoginTime = Time.parse(agentLastLoginTimeAppObj) if agentLastLoginTimeAppObj and agentLastLoginTimeAppObj != ''
				nowTime = Time.now.to_i
				if agentLastLoginTime.to_i <= nowTime
					if @registered and not has_network
						#Offline login
						if registeredAgentReg.regPass
							#Offline credentials valid.
							#Authenticate against offline credentials
							#Check if user can be authenticated against offline credentials or be forced to login online.
							if $rhoconfig[:TABFEATUREREQD]
								forceNetworkLogin = MobiSys::Sync.processForceLoginSyncConditions("login", agentRegHash['userId'], currentAgentReg.activeDays)
							else
								lastLoginTime = Time.load(currentAgentReg.lastLogin)
								expiryTime = lastLoginTime + (currentAgentReg.activeDays.to_i * 24 * 60 * 60)
								timeDiff = expiryTime - Time.now
								forceNetworkLogin = timeDiff <= 0
							end


							################# modified by zeeshan to check if user is ACTIVE/INACTIVE
							licenseExpireTimeDiff = checkifactive(registeredAgentReg)
							############################ end
							offlineAllowSuccessCount = $rhoconfig[:offlineAllowSuccessCount].to_i
							if offlineAllowSuccessCount <= registeredAgentReg.offlineunsuccessfulCount.to_i
								count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
								registeredAgentReg.offlineunsuccessfulCount = count
								registeredAgentReg.save
								addError(errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
							else
								if forceNetworkLogin
									addError(errors,'MAXOFFLINETIME',getLabelValue('MAXOFFLINETIME'))
								else
									if (licenseExpireTimeDiff <= 0)
										addError(errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
									elsif currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
										$login = true
									else
										#addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
										count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
										registeredAgentReg.offlineunsuccessfulCount = count
										registeredAgentReg.save
										if offlineAllowSuccessCount.to_i <= registeredAgentReg.offlineunsuccessfulCount.to_i
											addError(errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
										else
											addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
										end
									end
								end
							end
						else
							#Cannot login with offline access since credentials are invalid.
							addError(errors,'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
						end  
					elsif @registered and has_network
						#Online login
						begin
							#if device has network, sync authentication information against online service
							localLastLogin = currentAgentReg.lastLogin 
							currentAgentReg.lastLogin = nil if @registered #Removing last login date time from object as it creates problem while generating JSON
							onlineAgentReg = doJSON(currentAgentReg)
							if onlineAgentReg
								registeredAgentReg.regPass = currentAgentReg.regPass unless registeredAgentReg.regPass == currentAgentReg.regPass
								registeredAgentReg.activeDays = onlineAgentReg.activeDays unless registeredAgentReg.activeDays == onlineAgentReg.activeDays
								registeredAgentReg.lastLogin = Time.dump(Time.now)
								registeredAgentReg.licenseIssueDt = onlineAgentReg.licenseIssueDt
								registeredAgentReg.channel = onlineAgentReg.channel
								registeredAgentReg.subChannel = onlineAgentReg.subChannel
								registeredAgentReg.parentAgency = onlineAgentReg.parentAgency
								registeredAgentReg.agentDesignation = onlineAgentReg.agentDesignation
								registeredAgentReg.agentClassification = onlineAgentReg.agentClassification
								registeredAgentReg.agentId = onlineAgentReg.agentId
								registeredAgentReg.applicableProducts = onlineAgentReg.applicableProducts
								registeredAgentReg.agentStatusCd = onlineAgentReg.agentStatusCd
								registeredAgentReg.offlineunsuccessfulCount = 0
								registeredAgentReg.licenseType = onlineAgentReg.licenseType
								registeredAgentReg.location = onlineAgentReg.location
								registeredAgentReg.deviceUserSeq = onlineAgentReg.deviceUserSeq
								registeredAgentReg.agentName1 = onlineAgentReg.agentName1
								registeredAgentReg.agentName2 = onlineAgentReg.agentName2
								registeredAgentReg.emailId = onlineAgentReg.emailId
								registeredAgentReg.joiningDate = onlineAgentReg.joiningDate
								registeredAgentReg.mobileNo = onlineAgentReg.mobileNo
								registeredAgentReg.userDataDeleteDays = onlineAgentReg.userDataDeleteDays
								registeredAgentReg.userLeadDataDeleteDays = onlineAgentReg.userLeadDataDeleteDays
								registeredAgentReg.offlineAccessFlag = onlineAgentReg.offlineAccessFlag
								registeredAgentReg.field1 = onlineAgentReg.field1
								registeredAgentReg.field2 = onlineAgentReg.field2
								registeredAgentReg.field3 = onlineAgentReg.field3
								registeredAgentReg.field4 = onlineAgentReg.field4
								registeredAgentReg.field5 = onlineAgentReg.field5
								registeredAgentReg.field6 = onlineAgentReg.field6
								registeredAgentReg.field7 = onlineAgentReg.field7
								registeredAgentReg.field8 = onlineAgentReg.field8
								registeredAgentReg.field9 = onlineAgentReg.field9
								registeredAgentReg.field10 = onlineAgentReg.field10
								registeredAgentReg.field11 = onlineAgentReg.field11
								registeredAgentReg.field12 = onlineAgentReg.field12
								registeredAgentReg.field13 = onlineAgentReg.field13
								registeredAgentReg.field14 = onlineAgentReg.field14
								registeredAgentReg.field15 = onlineAgentReg.field15
								registeredAgentReg.agentField11 = onlineAgentReg.agentField11
								registeredAgentReg.agentField12 = onlineAgentReg.agentField12
								registeredAgentReg.agentField13 = onlineAgentReg.agentField13
								registeredAgentReg.agentField14 = onlineAgentReg.agentField14
								registeredAgentReg.agentField15 = onlineAgentReg.agentField15
								registeredAgentReg.agentField16 = onlineAgentReg.agentField16
								registeredAgentReg.agentField17 = onlineAgentReg.agentField17
								registeredAgentReg.agentField18 = onlineAgentReg.agentField18
								registeredAgentReg.agentField19 = onlineAgentReg.agentField19
								registeredAgentReg.agentField20 = onlineAgentReg.agentField20
								registeredAgentReg.agentField21 = onlineAgentReg.agentField21
								registeredAgentReg.agentField22 = onlineAgentReg.agentField22
								registeredAgentReg.agentField23 = onlineAgentReg.agentField23
								registeredAgentReg.agentField24 = onlineAgentReg.agentField24
								registeredAgentReg.agentField25 = onlineAgentReg.agentField25
								registeredAgentReg.agentField26 = onlineAgentReg.agentField26
								registeredAgentReg.agentField27 = onlineAgentReg.agentField27
								registeredAgentReg.agentField28 = onlineAgentReg.agentField28
								registeredAgentReg.agentField29 = onlineAgentReg.agentField29
								registeredAgentReg.agentField30 = onlineAgentReg.agentField30
								registeredAgentReg.collateralLevelCd = onlineAgentReg.collateralLevelCd
                				registeredAgentReg.applicableMenus = onlineAgentReg.applicableMenus
                				registeredAgentReg.applicableMenusJson = onlineAgentReg.applicableMenusJson
                				registeredAgentReg.applicableAgentGroups = onlineAgentReg.applicableAgentGroups
								registeredAgentReg.save

							#$login = true
							end
							################# modified by zeeshan to check if user is ACTIVE/INACTIVE
							licenseExpireTimeDiff = checkifactive(registeredAgentReg)

							if (licenseExpireTimeDiff <= 0)
								addError(errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
							else
								if currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
									$login = true
								else
									addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
								end
							end
						rescue MobiSys::ServerUnavailableError => boom
							#try offline login
							#Authenticate against offline credentials
							#Check if user can be authenticated against offline credentials or be forced to login online.
							if registeredAgentReg.regPass and registeredAgentReg.regPass != ""#if password available, that means agent credentials are still valid
								if $rhoconfig[:TABFEATUREREQD]
									forceNetworkLogin = MobiSys::Sync.processForceLoginSyncConditions("login", agentRegHash['userId'], currentAgentReg.activeDays)
								else
									lastLoginTime = Time.load(localLastLogin)
									expiryTime = lastLoginTime + (currentAgentReg.activeDays.to_i * 24 * 60 * 60)
									timeDiff = expiryTime - Time.now
									forceNetworkLogin = timeDiff <= 0
								end

								################# modified by zeeshan to check if status is ACTIVE/INACTIVE
								licenseExpireTimeDiff = checkifactive(registeredAgentReg)

								offlineAllowSuccessCount = $rhoconfig[:offlineAllowSuccessCount].to_i
								if offlineAllowSuccessCount <= registeredAgentReg.offlineunsuccessfulCount.to_i
									count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
									registeredAgentReg.offlineunsuccessfulCount = count
									registeredAgentReg.save
									addError(errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
								else

									if forceNetworkLogin
										addError(errors,'MAXOFFLINETIME',getLabelValue('MAXOFFLINETIME'))
									else
										if (licenseExpireTimeDiff <= 0)
											addError(errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
										elsif currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
											$login = true
										else
											#addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
											count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
											registeredAgentReg.offlineunsuccessfulCount = count
											registeredAgentReg.save
											if offlineAllowSuccessCount.to_i <= registeredAgentReg.offlineunsuccessfulCount.to_i
												addError(errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
											else
												addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
											end
										end
									end
								end
							else
								#Password not available. User credentials are invalid and cannot login with offline mode.
								addError(errors, 'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
							end
						end

					elsif not @registered and has_network
						#Registration
						onlineAgentReg = doJSON(currentAgentReg)
						if onlineAgentReg
							currentAgentReg.userId = onlineAgentReg.userId
							currentAgentReg.activeDays = onlineAgentReg.activeDays
							currentAgentReg.deviceUserSeq = onlineAgentReg.deviceUserSeq
							currentAgentReg.licenseIssueDt = onlineAgentReg.licenseIssueDt
							currentAgentReg.channel = onlineAgentReg.channel
							currentAgentReg.subChannel = onlineAgentReg.subChannel
							currentAgentReg.parentAgency = onlineAgentReg.parentAgency
							currentAgentReg.agentDesignation = onlineAgentReg.agentDesignation
							currentAgentReg.agentClassification = onlineAgentReg.agentClassification
							currentAgentReg.agentId = onlineAgentReg.agentId
							currentAgentReg.applicableProducts = onlineAgentReg.applicableProducts
							currentAgentReg.offlineunsuccessfulCount = 0
							currentAgentReg.agentName1 = onlineAgentReg.agentName1
							currentAgentReg.agentName2 = onlineAgentReg.agentName2
							currentAgentReg.emailId = onlineAgentReg.emailId
							currentAgentReg.licenseType = onlineAgentReg.licenseType
							currentAgentReg.joiningDate = onlineAgentReg.joiningDate
							currentAgentReg.mobileNo = onlineAgentReg.mobileNo
							currentAgentReg.offlineAccessFlag = onlineAgentReg.offlineAccessFlag
							currentAgentReg.location = onlineAgentReg.location
							currentAgentReg.field1 = onlineAgentReg.field1
							currentAgentReg.field2 = onlineAgentReg.field2
							currentAgentReg.field3 = onlineAgentReg.field3
							currentAgentReg.field4 = onlineAgentReg.field4
							currentAgentReg.field5 = onlineAgentReg.field5
							currentAgentReg.field6 = onlineAgentReg.field6
							currentAgentReg.field7 = onlineAgentReg.field7
							currentAgentReg.field8 = onlineAgentReg.field8
							currentAgentReg.field9 = onlineAgentReg.field9
							currentAgentReg.field10 = onlineAgentReg.field10
							currentAgentReg.field11 = onlineAgentReg.field11
							currentAgentReg.field12 = onlineAgentReg.field12
							currentAgentReg.field13 = onlineAgentReg.field13
							currentAgentReg.field14 = onlineAgentReg.field14
							currentAgentReg.field15 = onlineAgentReg.field15
							currentAgentReg.agentField11 = onlineAgentReg.agentField11
							currentAgentReg.agentField12 = onlineAgentReg.agentField12
							currentAgentReg.agentField13 = onlineAgentReg.agentField13
							currentAgentReg.agentField14 = onlineAgentReg.agentField14
							currentAgentReg.agentField15 = onlineAgentReg.agentField15
							currentAgentReg.agentField16 = onlineAgentReg.agentField16
							currentAgentReg.agentField17 = onlineAgentReg.agentField17
							currentAgentReg.agentField18 = onlineAgentReg.agentField18
							currentAgentReg.agentField19 = onlineAgentReg.agentField19
							currentAgentReg.agentField20 = onlineAgentReg.agentField20
							currentAgentReg.agentField21 = onlineAgentReg.agentField21
							currentAgentReg.agentField22 = onlineAgentReg.agentField22
							currentAgentReg.agentField23 = onlineAgentReg.agentField23
							currentAgentReg.agentField24 = onlineAgentReg.agentField24
							currentAgentReg.agentField25 = onlineAgentReg.agentField25
							currentAgentReg.agentField26 = onlineAgentReg.agentField26
							currentAgentReg.agentField27 = onlineAgentReg.agentField27
							currentAgentReg.agentField28 = onlineAgentReg.agentField28
							currentAgentReg.agentField29 = onlineAgentReg.agentField29
							currentAgentReg.agentField30 = onlineAgentReg.agentField30
							currentAgentReg.userDataDeleteDays = onlineAgentReg.userDataDeleteDays
							currentAgentReg.userLeadDataDeleteDays = onlineAgentReg.userLeadDataDeleteDays
							currentAgentReg.agentStatusCd = onlineAgentReg.agentStatusCd
							currentAgentReg.collateralLevelCd = onlineAgentReg.collateralLevelCd
              				currentAgentReg.applicableMenus = onlineAgentReg.applicableMenus
              				currentAgentReg.applicableMenusJson = onlineAgentReg.applicableMenusJson
							#############################
							currentAgentReg.lastLogin = Time.dump(Time.now)
							################# modified by zeeshan for ACTIVE/INACTIVE status verification
							licenseExpireTimeDiff = checkifactive(onlineAgentReg)
							############################ end
							if (licenseExpireTimeDiff <= 0)
								#Login failed. Expiry date is before current time. Disallow login
								addError(errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
							else
								currentAgentReg.userId = MobiSys::Encryption.encryptContent(currentAgentReg.userId)
								currentAgentReg.save
								$login = true
							end
						end
					else
						#Registration attempt without network access.
						addError(errors,'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
					end

				else
					addError(errors,'INVALIDDEVICETIME',getLabelValue('INVALIDDEVICETIME'))
				end 
			end
		rescue StandardError => boom
			if boom.is_a? MobiSys::AuthenticationError
				addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
			else
				addError(errors,boom.message, boom.message)
			end
		end
		# $login = true # for offline testing only
		if $login
			languages = Lookupvalue.find(
	            :all,
	            :conditions => {
	                {:name => "key"} => "LANGUAGE",
	                {
	                    :name => "cd",
	                    :op => "IN"
	                } => $rhoconfig[:supported_locales].to_s.upcase.split(",")
	            },
	            :op => "AND",
	            :select => ['cd','desc'],
	            :order => ['sortOrder']
	        )
	        #Code to sync releasemanagement tables
			
	        validLang = false
	        languages.each do |lang|
                validLang = true if lang.cd == agentRegHash['language']
            end
            if validLang
				selectedLanguage = agentRegHash['language'].downcase
				Application.updateValue('DEFAULTLOCALE',selectedLanguage)
	            Localization::LabelCache.instance.resetLabels(selectedLanguage)
	        end
			currentAgentReg.userId = MobiSys::Encryption.decryptContent(currentAgentReg.userId) if !@registered
			$userId = currentAgentReg.userId
			$userPassword = currentAgentReg.regPass
			if $rhoconfig[:incrementalMasterSyncApproach].to_s == "YES"
				if has_network
					MobiSys::Sync.syncReleaseMgmtData(currentAgentReg)
				end
				updateSyncConditions(currentAgentReg)
			end
			applicationPropertiesHM = {}
			errors = Hash.new
			Application.updateValue('agentLastLoginTimestamp',Time.now)
			if @registered
				logUserLoginDetails('LOGIN')
			else
				logUserLoginDetails('REGISTRATION')
			end
			forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
			#Add Offline Application Properties
			offline_applications = OfflineApplication.find(:all, :conditions => {:requiredOnUIFl => 'YES'}, :select => ['property as prop','value'])
			offline_applications.each do |record|
				key = record.prop.to_s
				if key == "ENVIRONMENT"
					key = "APP_ENVIRONMENT"
				end
				applicationPropertiesHM[key] = record.value.to_s
			end
			
			masterDBUpgradeDate = (masterDBUpgradeDt.to_s != "" ? DateTime.parse(masterDBUpgradeDt.to_s).strftime('%Q').to_i : 0)
			transactionSyncDate = (transactionSyncDt.to_s != "" ? DateTime.parse(transactionSyncDt.to_s).strftime('%Q').to_i : 0)

			# temporarycode for collateral  & collateralRenderLevel sync only
			# collateralSyncFl = Application.getValue('collateralSyncFl')
			# if (collateralSyncFl and collateralSyncFl.value.to_s != "true") or collateralSyncFl == nil
			# 	record1 = {"PRDFAMILY1": ["Product Family 1","PRD_FAMILY1", "INLINE", "HTML", "A whole of life plan that aims to provide growth for money","175b20632cbe1c986499a5cd000baad1", "product_category1.jpg","PNG"]}
			# 	record2 = {"PRDFAMILY2": ["Product Family 2","PRD_FAMILY2", "INLINE", "HTML", "A whole of life plan that aims to provide growth for money","175b202a2cbe1c9833d215ac000b7677","product_category2.jpg","PNG"]}
			# 	record3 = {"productvideo": ["Product",nil, "", "MEDIA", "PRD_MP4","175b208e2cbe1c9827ff799d000bb5b5","BFLBrandPresentationClip.mp4","MP4"]}
			# 	record4 = {"fund": ["Fund",nil, "", "MEDIA", "FUND","176220862cbe1c9838b01fe100015c00","FundFactSheet.pdf","PDF"]}
			# 	record5 = {"PRDFAMILY3": ["Product Family 3","PRD_FAMILY3", "INLINE", "HTML", "The Retirement plans are aimed at provisioning for post-Retirement medical & living expenses","175b202a2cbe1c9833d215ac000b7677","Retirement.jpg","PNG"]}
			# 	record6 = {"HeatlhProductFamily": ["Heatlh Product Family","HEALTH_PRDFAMILY", "INLINE", "HTML", "Cover your Health","181286d6280d12604587ba640003dbd5","HealthImage.jpg","PNG"]}
			# 	record7 = {"PRDFAMILY4": ["Product Family 4","PRD_FAMILY4", "INLINE", "HTML", "Cover all your Home Insurance needs including the property and the valuables","17c49fee2cbe1c9855eb5f9b0006982e","HomeInsurance.png","PNG"]}
			# 	[record1, record2, record3, record4,record5, record6,record7].each do |record|
			# 		record.each do |key,value|
			# 			collateralRenderLevel = CollateralRenderLevel.new
			# 			collateral = Collateral.new
			# 			collateralRenderLevel.levelCd = key.to_s
			# 			collateralRenderLevel.levelDesc = value[0].to_s
			# 			collateralRenderLevel.header1 = value[0].to_s
			# 			collateralRenderLevel.icon = value[1] if value[1] != nil
			# 			collateralRenderLevel.contentEmbedTypeCd = value[2].to_s
			# 			collateralRenderLevel.contentPart1TypeCd = value[3].to_s
			# 			collateralRenderLevel.contentPart1 = value[4].to_s
			# 			collateralRenderLevel.userId = agentRegHash['regPass']
			# 			collateralRenderLevel.versionID = 2
			# 			collateralRenderLevel.guid = value[5].to_s
			# 			collateral.collateralCd = (value[1] != nil) ? value[1].to_s : value[4].to_s
			# 			collateral.levelCd = 'PS_HP' if key.to_s != "fund"
			# 			collateral.header = (key.to_s != "fund") ? "Product video" : "Fund fact sheet"
			# 			collateral.description = (key.to_s != "fund") ? "Product video" : "Fund fact sheet"
			# 			collateral.fileName = value[6].to_s
			# 			collateral.fileType = value[7].to_s
			# 			collateral.embedType = 'EXTERNAL'
			# 			collateral.colVersion = 1
			# 			collateral.colStatus = 'COMPLETED'
			# 			collateral.userId = $userId
			# 			collateral.versionID = 1
			# 			collateral.guid = 55
			# 			collateralRenderLevel.save
			# 			collateral.save
			# 		end
			# 	end
			# 	if collateralSyncFl
			# 		Application.updateValue('collateralSyncFl',"true")
			# 	else
			# 		Application.create('collateralSyncFl',"true")
			# 	end
			# end
			userLoginData = {}
			userLoginData["UserName"] = AgentReg.getCurrentAgentReg.agentName1
			# data["status"] = "success"
			data["UserId"] = $userId
			data["userType"] = "AGENT"
			data["userLoginData"] = userLoginData
			data["syncMandatory"] = navigateToSync
			data["ApplicationProperties"] = applicationPropertiesHM
			data["registered"] = @registered
			responseHash['success'] = true
			responseHash['message'] = "Login Successful"
		else
			message = (errors.values.is_a? Array) ? errors.values.size > 0 ? errors.values[0] : "Login Failed" : errors.values.to_s
			responseHash['success'] = false
			responseHash['message'] = message
			responseHash['status'] = 401
			responseHash['timestamp'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
            responseHash['error'] = "Unauthorized"
		end
		responseHash['data'] = data if !data.empty?
		render :string => responseHash.to_json
	end

	def logUserLoginDetails(activity)
		userLoginHistory = UserLoginHistory.new
		userLoginHistory.modeCd = 'OFFLINE'
		userLoginHistory.deviceId = Application.getValue('deviceSeq').value.to_s
		userLoginHistory.loginDt = Time.now
		userLoginHistory.osVersion = System::get_property('os_version').to_s
		userLoginHistory.dbVersion = Application.getValue('DBVERSION').value
		userLoginHistory.applicationVersion = Rho::RhoConfig.app_version
		userLoginHistory.activity = activity
		userLoginHistory.persistAll
	end

	def doJSON(currentAgentReg)
		agentregJSON = ::JSON.generate(currentAgentReg)    
		url = '/agentregs.run'
		result = doJSONPost(url, agentregJSON, currentAgentReg.userId, currentAgentReg.regPass)
		agentRegHash = Rho::JSON.parse(result)
		$agentRegHash['dbVersion'] = agentRegHash['dbVersion']
		$agentRegHash['outputImageVersion'] = agentRegHash['outputImageVersion']
		$agentRegHash['dbMandatory'] = agentRegHash['dbMandatory']
        #Code to sync releasemanagement tables
		# MobiSys::Sync.syncReleaseMgmtData(currentAgentReg)
		# Compare DB & Output Images version mismatch
		if $rhoconfig[:incrementalMasterSyncApproach].to_s != "YES"
			dBVersionOffObj = Application.getValue('DBVERSION')
			outputImageVersionOffObj = Application.getValue('OUTPUTIMAGESVERSION')

			# releaseDt = ReleaseManagement.getFirstSyncDate(currentAgentReg)
			# Update master db upgrade date in Application table
			masterDbUpgradeDtObj = Application.getValue('MASTERDBUPGRADEDATE')
			unless masterDbUpgradeDtObj
				masterDbUpgradeDtObj = Application.create('MASTERDBUPGRADEDATE',Time.at(0))
			end
			# if releaseDt
				masterDbUpgradeDtObj.value = agentRegHash['masterDBUpgradeDt']
				# masterDbUpgradeDtObj.value = releaseDt
			# else
	            # masterDbUpgradeDtObj.value = Time.new(2300, 01, 01)

			# end
			masterDbUpgradeDtObj.save

			# if releaseDt && releaseDt <= Time.now
			# 	dbMandatoryVal = "YES"
			# else
			# 	dbMandatoryVal = "NO"
			# end

			# Update master db mandatory flag in Application table
			dbMandatory = Application.getValue('MASTERDBMANDATORY')
			unless dbMandatory
				dbMandatory = Application.create('MASTERDBMANDATORY',"NO")
			end
			# dbMandatory.value = dbMandatoryVal
			dbMandatory.value = agentRegHash['dbMandatory']
			dbMandatory.save

			# Update master data mismatch status in Application table
			masterDataMismatchObj = Application.getValue('MASTERDATAMISMATCH')
			unless masterDataMismatchObj
				masterDataMismatchObj = Application.create('MASTERDATAMISMATCH',"NO")
			end

			if agentRegHash['dbVersion'].to_s != dBVersionOffObj.value.to_s	|| agentRegHash['outputImageVersion'].to_s != outputImageVersionOffObj.value.to_s
			# if releaseDt != nil || agentRegHash['outputImageVersion'].to_s != outputImageVersionOffObj.value.to_s
				masterDataMismatchObj.value = "YES"
				masterDataMismatchObj.save
			else
				masterDataMismatchObj.value = "NO"
				masterDataMismatchObj.save
			end
		end

		onlineAgentReg = MobiSys::MobiSysFixedSchema.from_hash('AgentReg',agentRegHash)
		onlineAgentReg.applicableMenusJson = onlineAgentReg.applicableMenusJson
		return onlineAgentReg
	end

	def updateSyncConditions(currentAgentReg)
		outputImageVersionOffObj = Application.getValue('OUTPUTIMAGESVERSION')
		releaseDt = ReleaseManagement.getFirstSyncDate(currentAgentReg)
		# Update master db upgrade date in Application table
		masterDbUpgradeDtObj = Application.getValue('MASTERDBUPGRADEDATE')
		unless masterDbUpgradeDtObj
			masterDbUpgradeDtObj = Application.create('MASTERDBUPGRADEDATE',Time.at(0))
		end
		if releaseDt
			# masterDbUpgradeDtObj.value = agentRegHash['masterDBUpgradeDt']
			masterDbUpgradeDtObj.value = releaseDt
		else
            masterDbUpgradeDtObj.value = Time.new(2300, 01, 01)

		end
		masterDbUpgradeDtObj.save

		if releaseDt && releaseDt <= Time.now
			dbMandatoryVal = "YES"
		else
			dbMandatoryVal = "NO"
		end

		# Update master db mandatory flag in Application table
		dbMandatory = Application.getValue('MASTERDBMANDATORY')
		unless dbMandatory
			dbMandatory = Application.create('MASTERDBMANDATORY',"NO")
		end
		dbMandatory.value = dbMandatoryVal
		# dbMandatory.value = agentRegHash['dbMandatory']
		dbMandatory.save

		# Update master data mismatch status in Application table
		masterDataMismatchObj = Application.getValue('MASTERDATAMISMATCH')
		unless masterDataMismatchObj
			masterDataMismatchObj = Application.create('MASTERDATAMISMATCH',"NO")
		end

		# if agentRegHash['dbVersion'].to_s != dBVersionOffObj.value.to_s	|| agentRegHash['outputImageVersion'].to_s != outputImageVersionOffObj.value.to_s
		if false #releaseDt.to_s != "" || $agentRegHash['outputImageVersion'].to_s != outputImageVersionOffObj.value.to_s
			masterDataMismatchObj.value = "YES"
			masterDataMismatchObj.save
		else
			masterDataMismatchObj.value = "NO"
			masterDataMismatchObj.save
		end
	end

	def checkifactive(agent)
		return (agent.agentStatusCd=="ACTIVE")? 1 : 0
	end
	
	def fetchAPIURL
        restAPIURL = Lookupvalue.loadObject(:all, :conditions=> {:key => "RESTAPIURL" })
        restAPIURLHash = {}
       	if restAPIURL
	        online_server_url = $rhoconfig[:online_server_url].sub('/systemcommon','')
	        online_server_url = Application.getValue('online_server_url').value.sub('/systemcommon','') if Application.getValue('online_server_url')
	        restAPIURL.each do |apiUrl|
	        	restAPIURLHash[apiUrl.cd] = (apiUrl.desc.to_s.start_with?('/systemcommon') ? "#{online_server_url}#{apiUrl.desc}" : "#{$rhoconfig[:offline_server_url]}#{apiUrl.desc}") 
	        end
	    end
	    if $rhoconfig[:can_change_online_server] == 'YES'
        	restAPIURLHash["online_server_url"] = $rhoconfig[:online_server_url]
        	restAPIURLHash["online_server_url"] = Application.getValue('online_server_url').value if Application.getValue('online_server_url')
        end
        ## we need agent credentials to login using biometrics authentication
        agentList = AgentReg.find(:all)
        if agentList.size >= 1
            userId = MobiSys::Encryption.decryptContent(agentList[0].userId)
            password = agentList[0].regPass
            enableFingerprintAuth = agentList[0].enableFingerprintAuth
            restAPIURLHash["USERCREDENTIALS"] = {"userId" => userId, "password" => password, "enableFingerprintAuth" => enableFingerprintAuth}
        end

        responseHash = {"data" => {"restAPIURL" => restAPIURLHash}, "success" => true}
        render :string => responseHash.to_json
    end

    def getLabels
    	parsedData = parseRequestBodyParams
        responseHash = {}
        outputMap = {}
        labelsMap = {}
    	if parsedData.has_key?("labelKeyList")
			labelKeyList = parsedData["labelKeyList"]
		end
        if !labelKeyList.empty?
	        labelKeyList.each do |labelKey|
	        	outputMap[labelKey] = MobiSys::UIGenUtilHelper.getLabelValue(labelKey, Application.getValue('DEFAULTLOCALE').value.downcase)
	        end
	    end
	    labelsMap["labels"] = outputMap
	    responseHash["data"] = labelsMap if !labelsMap.empty?
		render :string => responseHash.to_json
    end

end

begin 
	require 'AgentReg/agent_reg_controller_company'
rescue LoadError => e
	puts 'agent_reg_controller_company not included'
end
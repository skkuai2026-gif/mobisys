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


	def registerPinForDevice
		parsedData = parseRequestBodyParams
        responseHash = {}
		pinRegistered = false
		userId = parsedData["userId"].to_s.upcase  if parsedData.has_key?("userId")  
		pin = parsedData["pin"].to_s.upcase  if parsedData.has_key?("pin") 
		registeredAgentReg = AgentReg.forUserId(userId, true) if Application.getValue(MobiSys::MOBISYSDEVICEID)
		disabledAppObject = Application.getValue(MobiSys::DEVICEDISABLED)
		registered = (registeredAgentReg) ? true : false
		begin
			if disabledAppObject
				responseHash['success'] = false
				responseHash['message'] = getLabelValue('REGISTERDEACTIVATEDDEVICE')
			else
				agentLastLoginTime = Time.now
				agentLastLoginTimeAppObj = Application.getValue('agentLastLoginTimestamp').value
				agentLastLoginTime = Time.parse(agentLastLoginTimeAppObj) if agentLastLoginTimeAppObj and agentLastLoginTimeAppObj != ''
				nowTime = Time.now.to_i

				if agentLastLoginTime.to_i <= nowTime
					if registered
						registeredAgentReg.agentField11 = pin
						registeredAgentReg.agentField12 = Time.dump(Time.now)
						registeredAgentReg.save
						pinRegistered = true
						responseHash['success'] = true
						responseHash['message'] = "Successful"
					else
						responseHash['success'] = false
						responseHash['message'] = getLabelValue('PROBLEMINREGISTERINGPIN')
					end
				else
					responseHash['success'] = false
					responseHash['message'] = getLabelValue('INVALIDDEVICETIME')
				end
			end
		rescue StandardError => boom
			responseHash['success'] = false
			responseHash['message'] = boom.message unless boom.is_a? MobiSys::AuthenticationError
		end

		if pinRegistered
			$login = true
			registeredAgentReg = AgentReg.forUserId(userId, true) if Application.getValue(MobiSys::MOBISYSDEVICEID)

			logUserLoginDetails('REGISTERPIN')
		end
		render :string => responseHash.to_json
	end

	def loginWithPin
		parsedData = parseRequestBodyParams
        responseHash = {}
		data = {}
        agentRegHash = {}
		pin = parsedData["pin"].to_s.upcase  if parsedData.has_key?("pin")  
		agentRegHash['userId'] = parsedData["advisorCode"].to_s.upcase  if parsedData.has_key?("advisorCode") 
		$userId = agentRegHash['userId']
		registeredAgentReg = AgentReg.forUserId(agentRegHash['userId'], true) if Application.getValue(MobiSys::MOBISYSDEVICEID)
		disabledAppObject = Application.getValue(MobiSys::DEVICEDISABLED)
		@registered = (registeredAgentReg) ? true : false
		puts "loginPIN Mode is @registered " + @registered.to_s
		currentAgentReg = AgentReg.new(:userId => agentRegHash['userId'], :agentField11 => pin)
		currentAgentReg.field14 = registeredAgentReg.field14 if @registered
		currentAgentReg.agentField12 = registeredAgentReg.agentField12 if @registered
		# currentAgentReg.lastPINRegistration = registeredAgentReg.lastPINRegistration if @registered
		# currentAgentReg.lastLogin = registeredAgentReg.lastLogin if @registered

		networkIssue = false
		isValid = true

		# has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
		begin
			$login = false
			upgrading = false
			if disabledAppObject
				responseHash['success'] = false
				responseHash['message'] = getLabelValue('REGISTERDEACTIVATEDDEVICE')
			else
				agentLastLoginTime = Time.now
				agentLastLoginTimeAppObj = Application.getValue('agentLastLoginTimestamp').value
				agentLastLoginTime = Time.parse(agentLastLoginTimeAppObj) if agentLastLoginTimeAppObj and agentLastLoginTimeAppObj != ''
				nowTime = Time.now.to_i
				if agentLastLoginTime.to_i <= nowTime
					if @registered
						#Offline login
						if registeredAgentReg.agentField11.to_s != ""
							#Offline credentials valid.
							#Authenticate against offline credentials
							#Check if user can be authenticated against offline credentials or be forced to login online.
							if $rhoconfig[:TABFEATUREREQD]
								forceNetworkLogin = false#MobiSys::Sync.processForceLoginSyncConditions("login", agentRegHash['userId'], currentAgentReg.field14)
								if !forceNetworkLogin
									lastPINRegistrationTime = Time.load(currentAgentReg.agentField12.to_s)
									expiryTime = lastPINRegistrationTime + (currentAgentReg.field14.to_i * 24 * 60 * 60)
									timeDiff = expiryTime - Time.now
									forcePINRegistration = timeDiff <= 0
								end
							else
								lastPINRegistrationTime = Time.load(currentAgentReg.agentField12.to_s)
								expiryTime = lastPINRegistrationTime + (currentAgentReg.field14.to_i * 24 * 60 * 60)
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
								responseHash['success'] = false
								responseHash['message'] = "Maximum number of invalid login attempts reached. Please login while the device is online."
							else
								if forceNetworkLogin
									responseHash['success'] = false
								 	responseHash['message'] = getLabelValue('MAXOFFLINETIME')
								elsif forcePINRegistration
									responseHash['success'] = false
									responseHash['message'] = getLabelValue('NEEDNETWORKACCESS')

								else
									if (licenseExpireTimeDiff <= 0)
										responseHash['success'] = false
								 		responseHash['message'] = getLabelValue('RENEWLICENSE')
									elsif currentAgentReg.userId.to_s == MobiSys::Encryption.decryptContent(registeredAgentReg.userId).to_s and currentAgentReg.agentField11.to_s == registeredAgentReg.agentField11.to_s
										$login = true
									else
										count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
										registeredAgentReg.offlineunsuccessfulCount = count
										registeredAgentReg.save
										if offlineAllowSuccessCount.to_i <= registeredAgentReg.offlineunsuccessfulCount.to_i
											responseHash['success'] = false
											responseHash['message'] = "Maximum number of invalid login attempts reached. Please login while the device is online."
										else
											responseHash['success'] = false
											responseHash['message'] = getLabelValue('INVALIDCREDENTIALS')
										end
									end
								end
							end
						else
							#Cannot login with offline access since credentials are invalid.
							responseHash['success'] = false
							responseHash['message'] = getLabelValue('NEEDNETWORKACCESS')
						end
					else
						#Registration attempt without network access.
						responseHash['success'] = false
						responseHash['message'] = getLabelValue('USERNOTREGISTERED')
					end

				else
					responseHash['success'] = false
					responseHash['message'] = getLabelValue('INVALIDDEVICETIME')
				end
			end
		rescue StandardError => boom
			responseHash['success'] = false
			responseHash['message'] = boom.message unless boom.is_a? MobiSys::AuthenticationError
		end
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

			registeredAgentReg.userId = MobiSys::Encryption.decryptContent(registeredAgentReg.userId)
			$userId = registeredAgentReg.userId
			logUserLoginDetails('LOGINWITHPIN')
			Application.updateValue('agentLastLoginTimestamp',Time.now)
			forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
			
			applicationPropertiesHM = {}
			#Add Offline Application Properties
			offline_applications = OfflineApplication.find(:all, :conditions => {:requiredOnUIFl => 'YES'}, :select => ['property as prop','value'])
			offline_applications.each do |record|
				key = record.prop.to_s
				if key == "ENVIRONMENT"
					key = "APP_ENVIRONMENT"
				end
				applicationPropertiesHM[key] = record.value.to_s
			end
			applicationPropertiesHM["DOWNLOADCLIENTFLAG"] = AgentReg.getCurrentAgentReg.agentField13.to_s if AgentReg.getCurrentAgentReg.agentField13.to_s != ""
			masterDBUpgradeDate = (masterDBUpgradeDt.to_s != "" ? DateTime.parse(masterDBUpgradeDt.to_s).strftime('%Q').to_i : 0)
			transactionSyncDate = (transactionSyncDt.to_s != "" ? DateTime.parse(transactionSyncDt.to_s).strftime('%Q').to_i : 0)

			userLoginData = {}
			userLoginData["UserName"] = AgentReg.getCurrentAgentReg.agentName1
			userLoginData["AgentId"] = AgentReg.getCurrentAgentReg.agentId
			userLoginData["UserId"] = $userId
			userLoginData["agentInfo"] = {}
			userLoginData["agentInfo"]["channel"] = AgentReg.getCurrentAgentReg.channel
			userLoginData["agentInfo"]["agentId"] = AgentReg.getCurrentAgentReg.agentId
			# data["status"] = "success"
			data["UserId"] = $userId
			data["userType"] = "AGENT"
			data["userLoginData"] = userLoginData
			data["syncMandatory"] = false
			data["ApplicationProperties"] = applicationPropertiesHM
			data["registered"] = @registered
			responseHash['success'] = true
			responseHash['message'] = "Login Successful"
		end
		render :string => responseHash.to_json
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
    	$accessToken = agentRegHash['accessToken']
    	$refreshToken = agentRegHash['refreshToken']

    	agentRegHash['userId'] = agentRegHash['userId'].to_s.upcase
		registeredAgentReg = AgentReg.forUserId(agentRegHash['userId'], true) if Application.getValue(MobiSys::MOBISYSDEVICEID)
		disabledAppObject = Application.getValue(MobiSys::DEVICEDISABLED)
		@registered = (registeredAgentReg)? true : false
		logInfo("Mode is @registered " + @registered.to_s)
		currentAgentReg = AgentReg.new(:userId => agentRegHash['userId'], :regPass => agentRegHash['regPass'])
		currentAgentReg.activeDays = registeredAgentReg.activeDays if @registered
		currentAgentReg.lastLogin = registeredAgentReg.lastLogin if @registered
		currentAgentReg.field14 = registeredAgentReg.field14 if @registered

		has_network = System::get_property('has_network') #&& MobiSys::BrowserHelper.detectConnection
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

					if @registered and not has_network and $rhoconfig[:use_okta_authentication].to_s != "YES"
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
					elsif @registered and not has_network and $rhoconfig[:use_okta_authentication].to_s == "YES"
						#Offline login with PIN
						$login = true  
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
								# registeredAgentReg.agentField11 = onlineAgentReg.agentField11
								# registeredAgentReg.agentField12 = onlineAgentReg.agentField12
								registeredAgentReg.agentField13 = onlineAgentReg.agentField13
								registeredAgentReg.agentField14 = onlineAgentReg.agentField14
								registeredAgentReg.agentField15 = onlineAgentReg.agentField15
								registeredAgentReg.agentField16 = onlineAgentReg.agentField16
								registeredAgentReg.agentField17 = onlineAgentReg.agentField17
								registeredAgentReg.agentField18 = onlineAgentReg.agentField18
								registeredAgentReg.agentField19 = onlineAgentReg.agentField19
								# registeredAgentReg.agentField20 = onlineAgentReg.agentField20
								# registeredAgentReg.agentField21 = onlineAgentReg.agentField21
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
								if $rhoconfig[:use_okta_authentication].to_s == "YES"
									$login = true
								else
									if currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
										$login = true
									else
										addError(errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
									end
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
							# currentAgentReg.agentField11 = onlineAgentReg.agentField11
							# currentAgentReg.agentField12 = onlineAgentReg.agentField12
							currentAgentReg.agentField13 = onlineAgentReg.agentField13
							currentAgentReg.agentField14 = onlineAgentReg.agentField14
							currentAgentReg.agentField15 = onlineAgentReg.agentField15
							currentAgentReg.agentField16 = onlineAgentReg.agentField16
							currentAgentReg.agentField17 = onlineAgentReg.agentField17
							currentAgentReg.agentField18 = onlineAgentReg.agentField18
							currentAgentReg.agentField19 = onlineAgentReg.agentField19
							# currentAgentReg.agentField20 = onlineAgentReg.agentField20
							# currentAgentReg.agentField21 = onlineAgentReg.agentField21
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

			if $login
				if !@registered
					userId = MobiSys::Encryption.decryptContent(currentAgentReg.userId) 
				else
					userId = currentAgentReg.userId
				end
				currentAgentRegOkta = AgentReg.forUserId(userId, true)
				currentAgentRegOkta.agentField20 = $accessToken
				currentAgentRegOkta.agentField21 = $refreshToken
				currentAgentRegOkta.save
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
			# $userPassword = currentAgentReg.regPass
			$userPassword = $rhoconfig[:use_okta_authentication].to_s == "YES" ? $accessToken : currentAgentReg.regPass
			
			# if $rhoconfig[:incrementalMasterSyncApproach].to_s == "YES"
			# 	if has_network
			# 		MobiSys::Sync.syncReleaseMgmtData(currentAgentReg)
			# 	end
			# 	updateSyncConditions(currentAgentReg)
			# end
			applicationPropertiesHM = {}
			errors = Hash.new
			Application.updateValue('agentLastLoginTimestamp',Time.now)
			

			if @registered
				logUserLoginDetails('LOGIN')
			else
				logUserLoginDetails('REGISTRATION')
			end
			syncNotification
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
			applicationPropertiesHM["DOWNLOADCLIENTFLAG"] = AgentReg.getCurrentAgentReg.agentField13.to_s if AgentReg.getCurrentAgentReg.agentField13.to_s != ""
			applicationPropertiesHM['SYSTEMDATE'] = Time.parse(Time.now.to_s).strftime("%d-%B-%Y")
			masterDBUpgradeDate = (masterDBUpgradeDt.to_s != "" ? DateTime.parse(masterDBUpgradeDt.to_s).strftime('%Q').to_i : 0)
			transactionSyncDate = (transactionSyncDt.to_s != "" ? DateTime.parse(transactionSyncDt.to_s).strftime('%Q').to_i : 0)

			#register 6 digit PIN
			forcePINRegistration = false

			if AgentReg.getCurrentAgentReg.agentField11.to_s == ""
				forcePINRegistration = true
			else
				lastPINRegistrationTime = Time.load(AgentReg.getCurrentAgentReg.agentField12.to_s)
				expiryTime = lastPINRegistrationTime + (AgentReg.getCurrentAgentReg.field14.to_i * 24 * 60 * 60)
				timeDiff = expiryTime - Time.now
				forcePINRegistration = timeDiff <= 0
			end

			userLoginData = {}
			userLoginData["UserName"] = AgentReg.getCurrentAgentReg.agentName1
			userLoginData["AgentId"] = AgentReg.getCurrentAgentReg.agentId
			userLoginData["UserId"] = $userId
			userLoginData["agentInfo"] = {}
			userLoginData["agentInfo"]["channel"] = AgentReg.getCurrentAgentReg.channel
			userLoginData["agentInfo"]["agentId"] = AgentReg.getCurrentAgentReg.agentId
			userLoginData["agentInfo"]["field12"] = AgentReg.getCurrentAgentReg.field12
			userLoginData["agentInfo"]["field6"] = AgentReg.getCurrentAgentReg.field6
			userLoginData["agentInfo"]["field13"] = AgentReg.getCurrentAgentReg.field13
			appleOrUatUser = AgentReg.getCurrentAgentReg.agentClassification.to_s.split(",") if AgentReg.getCurrentAgentReg.agentClassification.to_s != ""
			navigateToSync = false if appleOrUatUser && appleOrUatUser.include?("#{$userId}")
			# data["status"] = "success"
			data["UserId"] = $userId
			data["userType"] = "AGENT"
			data["userLoginData"] = userLoginData
			data["syncMandatory"] = navigateToSync
			data["ApplicationProperties"] = applicationPropertiesHM
			data["registered"] = @registered
			data["loginPin"] = forcePINRegistration ? '' : AgentReg.getCurrentAgentReg.agentField11
			responseHash['success'] = true
			responseHash['message'] = "Login Successful"
		else
			message = (errors.values.is_a? Array) ? errors.values.size > 0 ? errors.values[0] : "Login Failed" : errors.values.to_s
			responseHash['success'] = false
			responseHash['message'] = message
			responseHash['status'] = 401
			responseHash['timestamp'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
            responseHash['error'] = "Unauthorized"
            if $doJSONPostErrors != nil and $doJSONPostErrors != {}
				errorCode = $doJSONPostErrors.keys.first
	            responseHash['status'] = errorCode
	            responseHash['error'] = $doJSONPostErrors[errorCode]
	            responseHash['message'] = $doJSONPostErrors[errorCode]
			end
			responseHash['timestamp'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
		end
		responseHash['data'] = data if !data.empty?
		render :string => responseHash.to_json
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

            agentId = agentList[0].agentId
			agentField11 = agentList[0].agentField11
			accessToken = agentList[0].agentField20
			refreshToken = agentList[0].agentField21

            # restAPIURLHash["USERCREDENTIALS"] = {"userId" => userId, "password" => password, "enableFingerprintAuth" => enableFingerprintAuth}
            restAPIURLHash["USERCREDENTIALS"] = {"userId" => userId, "password" => password, "enableFingerprintAuth" => enableFingerprintAuth, "agentId" => agentId, "agentField11" => agentField11,"accessToken" => accessToken,"refreshToken" => refreshToken}

        end

        responseHash = {"data" => {"restAPIURL" => restAPIURLHash}, "success" => true}
        render :string => responseHash.to_json
    end

	def getProposalVersion
		data = {}
		responseHash = {}
		versionLookUps = []
		propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
        proposalVersion = propVersion.value.to_s if propVersion
        proposalVersionLookUp = Lookupvalue.new
        proposalVersionLookUp.cd = proposalVersion.to_s
        proposalVersionLookUp.desc = proposalVersion.to_s
        versionLookUps.push(proposalVersionLookUp)
		appVersion = getLabelValue(Rho::RhoConfig.app_version)
		dbVersion =  Application.getValue('DBVERSION').value if Application.getValue('DBVERSION')
        data["proposalVersion"] = versionLookUps
		data["appVersion"] = appVersion
		data["dbVersion"] = dbVersion
		responseHash['data'] = data if !data.empty?
		responseHash['success'] = true
		responseHash['message'] = "proposalVersion"
		render :string => responseHash.to_json
    end 

    def disclaimerShow
    	data = {}
		responseHash = {}
    	field12 = AgentReg.getCurrentAgentReg.field12.to_s
    	mdrtFlag = false
    	if field12.to_s == "YES"
    		mdrtFlag = true
    	end	
    	data["mdrtFlag"] = mdrtFlag
    	responseHash['data'] = data if !data.empty?
    	render :string => responseHash.to_json
    end 	

    def acceptLoginDisclaimer
	    parsedData = parseRequestBodyParams
        responseHash = {}
		data = {}
		begin
			acceptResponse = parsedData["acceptedResponse"]  if parsedData.has_key?("acceptedResponse") 
			if acceptResponse.to_s == "YES"
	           responseHash['success'] = true
			   responseHash['message'] = "Disclaimer accepted"
			else
			   responseHash['success'] = true
			   responseHash['message'] = "Disclaimer not accepted"
		    end	
		rescue StandardError => se
			puts "Error while generating JSON of request data" + se.to_s
			responseHash["success"] = false
			responseHash['message'] = getLabelValue('SERVERERROR')
	    end		
	    render :string => responseHash.to_json	
    end
    
    #Push notification changes start from mahesh by shubham
	def syncNotification
		responseHash = {}
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            begin
                WebView.execute_js("loading('show');")
                syncEntityHash = Hash.new
                inputHash = Hash.new
                className = AgentNotification.onlineClassName

                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new

                lastSyncDate = Time.at(0)
                lastSyncDateAppObject = Application.getValue("AgentNotification_" + $userId + '_lastSyncDate')
                if lastSyncDateAppObject
                    lastSyncDate = Time.load(lastSyncDateAppObject.value)
                end

                begin
                    json = ::JSON.generate(inputHash)
                rescue StandardError => se
                    puts "Error while generating JSON of request data" + se.to_s
                end

                inputHash[className] = lastSyncDate.strftime("%Y-%m-%d %H:%M:%S.%L %z")
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/agentNotification.run', json)
                resultsHash = Rho::JSON.parse(response)

                resultsHash.each do |key,value|
                    next if value.to_s == '' || value.to_s == '[]' || value.empty?
                    entities = Rho::JSON.parse(value)

                    db = ::Rho::RHO.get_src_db("AgentNotification")
                    db.start_transaction
                    begin
                        entities.each do |mainEntity|
                            next if mainEntity[key].to_s == ''
                            subEntity = Rho::JSON.parse(mainEntity[key])[0]
                            storedEntity = AgentNotification.loadObject(:first, :conditions=>{:guid=> subEntity['guid'].to_s})

                            entityObject = MobiSys::MobiSysEntitySchema.from_hash("AgentNotification",subEntity)
                            if storedEntity and entityObject.versionID == '-1'
                                storedEntity.delete
                            elsif storedEntity
                                storedEntity.merge(entityObject)
                                storedEntity.persist('fromSync')
                                if storedEntity.respond_to?('afterSync'.to_sym)
                                    storedEntity.afterSync
                                end
                            else
                                entityObject.persist('fromSync')
                                if entityObject.respond_to?('afterSync'.to_sym)
                                    entityObject.afterSync
                                end
                            end
                        end
                        db.commit
                    rescue StandardError => se
                        db.rollback
                        log('Error while syncing entities: ' + se.to_s)
                        raise se
                    end
                end

                if lastSyncDateAppObject
                    Application.updateValue("AgentNotification_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                else
                    Application.create("AgentNotification_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                end
            rescue StandardError => se
                puts "Exception: #{se}\n#{se.backtrace}"
            end
        else
            # Alert.show_popup({
            #     :message => getLabelValue('CHECKNETWORK'),
            #     :title => '',
            #     :icon => :info,
            #     :buttons => [('OK')]
            # })
        end
        responseHash["success"] = true
        responseHash["message"] = "Successful"
        render :string => responseHash.to_json
    end

    def getResponseAndAppClose
    	fresh_install_required = Application.getValue('FRESH_INSTALL_REQUIRED')&.value
    	p "inside getResponseAndAppClose***#{fresh_install_required}"
	    responseHash = {
	      success: true,
	      message: "Successful",
	      fresh_install_required: fresh_install_required
	    }
	    render :string => responseHash.to_json
	end

	def sendData
    	syncEntities = Hash.new
    	currentAgentReg = AgentReg.getCurrentAgentReg
    	responseHash = {}
    	parsedData = Rho::JSON.parse(@params['request-body'])
    	if parsedData.has_key?('refId')
            userActivity = UserActivity.find(:all,:conditions=>{:entityRefNumber=>parsedData['refId'].to_s})   
            syncEntities[UserActivity.onlineClassName] = userActivity.to_json if userActivity
        end

    	has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
    	syncEntities["agentID"] = currentAgentReg.agentId if currentAgentReg
    	uploadStatus = ""
    	if has_network
    		begin
    			response = doJSONPost('/sendDataController.run', ::JSON.generate(syncEntities))
				if response.to_s == "success"
					responseHash["success"] = true
                	responseHash["message"] = getLabelValue('dataSentSuccessfully')
				else
					responseHash["success"] = false
					messageToPopup = getLabelValue('SERVERERROR')
				end

    		rescue Exception => se
    			responseHash["success"] = false
				messageToPopup = getLabelValue('SERVERERROR')
    		end
	   	else
	   		responseHash["success"] = false
			messageToPopup = getLabelValue('REQUIRENETWORK')
    	end
  	end

	
end


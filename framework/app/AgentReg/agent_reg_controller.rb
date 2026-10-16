require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/encryption'
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'
require 'json'
require 'date'


class AgentRegController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper

	# GET /AgentReg/login
	def login
		if $login
			@agentreg = AgentReg.new
			path = $rhoconfig[:post_login_path].split("/")
			redirect :controller => path[2], :action => path[3]
		else 
			$agentRegHash = nil
			@agentreg = AgentReg.new
			if !$errors
				$errors = Hash.new
			end
			
			if $rhoconfig[:can_change_online_server] == 'NO'
				render :action => :login, :layout => :newEAPPLayout 
			else
				if @onlineServer == nil
					@onlineServer = Application.getValue('online_server_url').value if Application.getValue('online_server_url')
				end
				if $savedUrl == "true"
					render :action => :login, :layout => :newEAPPLayout
				else
					render :action => :onlineServer, :layout => :newEAPPLayout
				end 
			end 
		end
	end

	def loginOnLangChange
		$agentRegHash = nil
		@agentreg = AgentReg.new

		if !$errors
			$errors = Hash.new
		end
		render :action => :login 
	end


	def loginwait
		renderToolbar(-1)
		$agentRegHash = @params['AgentReg']
		System.start_timer(1000,url_for(:action=>:register),"")
		render :action => :loginWaitPage, :layout => :newEAPPLayout
	end


	# GET /AgentReg/register
	def register
		WebView.execute_js("loading('show');")
		$errors = Hash.new
		agentRegHash=$agentRegHash
		agentRegHash['userId'] = agentRegHash['userId'].to_s.upcase
		registeredAgentReg = AgentReg.forUserId(agentRegHash['userId'], true) if Application.getValue(MobiSys::MOBISYSDEVICEID)
		disabledAppObject = Application.getValue(MobiSys::DEVICEDISABLED)
		@registered = (registeredAgentReg)? true : false
		puts "Mode is @registered " + @registered.to_s
		currentAgentReg = AgentReg.new(:userId => agentRegHash['userId'], :regPass => agentRegHash['regPass'])
		currentAgentReg.activeDays = registeredAgentReg.activeDays if @registered
		currentAgentReg.lastLogin = registeredAgentReg.lastLogin if @registered
		has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
		$agentProduct = ""

		begin
			$login = false
			upgrading = false
			if disabledAppObject
				addError($errors,'REGISTERDEACTIVATEDDEVICE', getLabelValue('REGISTERDEACTIVATEDDEVICE'))
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
								addError($errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
							else
								if forceNetworkLogin
									addError($errors,'MAXOFFLINETIME',getLabelValue('MAXOFFLINETIME'))
								else
									if (licenseExpireTimeDiff <= 0)
										addError($errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
									elsif currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
										$login = true
									else
										#addError($errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
										count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
										registeredAgentReg.offlineunsuccessfulCount = count
										registeredAgentReg.save
										if offlineAllowSuccessCount.to_i <= registeredAgentReg.offlineunsuccessfulCount.to_i
											addError($errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
										else
											addError($errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
										end
									end
								end
							end
						else
							#Cannot login with offline access since credentials are invalid.
							addError($errors,'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
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
								registeredAgentReg.collateralLevelCd = onlineAgentReg.collateralLevelCd
                				registeredAgentReg.applicableMenus = onlineAgentReg.applicableMenus
								registeredAgentReg.save

							#$login = true
							end
							################# modified by zeeshan to check if user is ACTIVE/INACTIVE
							licenseExpireTimeDiff = checkifactive(registeredAgentReg)

							if (licenseExpireTimeDiff <= 0)
								addError($errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
							else
								if currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
									$login = true
								else
									addError($errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
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
									addError($errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
								else

									if forceNetworkLogin
										addError($errors,'MAXOFFLINETIME',getLabelValue('MAXOFFLINETIME'))
									else
										if (licenseExpireTimeDiff <= 0)
											addError($errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
										elsif currentAgentReg.userId == MobiSys::Encryption.decryptContent(registeredAgentReg.userId) and currentAgentReg.regPass ==  registeredAgentReg.regPass
											$login = true
										else
											#addError($errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
											count = registeredAgentReg.offlineunsuccessfulCount.to_i + 1
											registeredAgentReg.offlineunsuccessfulCount = count
											registeredAgentReg.save
											if offlineAllowSuccessCount.to_i <= registeredAgentReg.offlineunsuccessfulCount.to_i
												addError($errors,'maximumOfflineFailcount',getLabelValue('Maximum number of invalid login attempts reached. Please login while the device is online.'))
											else
												addError($errors,'INVALIDCREDENTIALS', getLabelValue('INVALIDCREDENTIALS'))
											end
										end
									end
								end
							else
								#Password not available. User credentials are invalid and cannot login with offline mode.
								addError($errors, 'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
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
							currentAgentReg.userDataDeleteDays = onlineAgentReg.userDataDeleteDays
							currentAgentReg.userLeadDataDeleteDays = onlineAgentReg.userLeadDataDeleteDays
							currentAgentReg.agentStatusCd = onlineAgentReg.agentStatusCd
							currentAgentReg.collateralLevelCd = onlineAgentReg.collateralLevelCd
              				currentAgentReg.applicableMenus = onlineAgentReg.applicableMenus
							#############################
							currentAgentReg.lastLogin = Time.dump(Time.now)
							################# modified by zeeshan for ACTIVE/INACTIVE status verification
							licenseExpireTimeDiff = checkifactive(onlineAgentReg)
							############################ end
							if (licenseExpireTimeDiff <= 0)
								#Login failed. Expiry date is before current time. Disallow login
								addError($errors,'RENEWLICENSE',getLabelValue('RENEWLICENSE'))
							else
								currentAgentReg.userId = MobiSys::Encryption.encryptContent(currentAgentReg.userId)
								currentAgentReg.save
								$login = true
							end
						end
					else
						#Registration attempt without network access.
						addError($errors,'NEEDNETWORKACCESS', getLabelValue('NEEDNETWORKACCESS'))
					end

				else
					addError($errors,'INVALIDDEVICETIME',getLabelValue('INVALIDDEVICETIME'))
				end 
			end
		rescue StandardError => boom
			addError($errors,boom.message, boom.message) unless boom.is_a? MobiSys::AuthenticationError 
		end
		if $login
			currentAgentReg.userId = MobiSys::Encryption.decryptContent(currentAgentReg.userId) if !@registered
			$userId = currentAgentReg.userId
			$userPassword = currentAgentReg.regPass
			$errors = Hash.new
			Application.updateValue('agentLastLoginTimestamp',Time.now)
			if @registered
				logUserLoginDetails('LOGIN')
				WebView.navigate('/app/AgentReg/postLogin')
			else
				logUserLoginDetails('REGISTRATION')
				WebView.navigate('/app/AgentReg/postLogin?mode=REGISTRATION')  
			end
		else
			WebView.navigate('/app/AgentReg/login')
		end
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


	def productFilter
		@AgentRegdetails =AgentReg.getCurrentAgentReg
		return @AgentRegdetails
	end


	def doJSON(currentAgentReg)
		agentregJSON = ::JSON.generate(currentAgentReg)    
		url = '/agentregs.run'
		result = doJSONPost(url, agentregJSON, currentAgentReg.userId, currentAgentReg.regPass)
		agentRegHash = Rho::JSON.parse(result)
		$agentRegHash['dbVersion'] = agentRegHash['dbVersion']
		$agentRegHash['outputImageVersion'] = agentRegHash['outputImageVersion']
		$agentRegHash['dbMandatory'] = agentRegHash['dbMandatory']
		onlineAgentReg = MobiSys::MobiSysFixedSchema.from_hash('AgentReg',agentRegHash)
		return onlineAgentReg
	end


	def addError(errors, errorKey, errorMsg)
		#puts errors.class.name.to_s
		errors[errorKey] = errorMsg unless errors.has_key? errorKey
	end


	# POST /AgentReg/postLogin
	def postLogin
		#mobiSysDeviceId loaded
		mobdevid = Application.getValue(MobiSys::MOBISYSDEVICEID) if MobiSys::MOBISYSDEVICEID
		#fixed key value
		fixed_key = $rhoconfig[:FIX_MOBISYS_ID_COMPONENT]
		#online registration date value
		online_reg_dt = Application.getValue(MobiSys::ONLINEREGDT)
		online_reg_dt_key = online_reg_dt.value
		#variable key value
		view_cd = Application.getValue(MobiSys::VIEWCD)
		view_cd_key = view_cd.value
		#concatenation and decryption of mobiSysDeviceId
		mob_key = fixed_key.to_s + online_reg_dt_key.to_s + view_cd_key.to_s
		$mobiSysDeviceId = MobiSys::Encryption.decryptAndDecodeContent(mobdevid.value,mob_key)

		########### below code written in the  disclaimer submit method
		if $rhoconfig.has_key?(:disclaimer_enabled) and $rhoconfig[:disclaimer_enabled]=='YES'
			render :action => :disclaimer
		else
			checkSyncPreferences
		end
	end


	def disclaimer
	end


	def checkSyncPreferences
		$showSync = false
		firstSync = Application.getValue('PRIMARYDATALASTSYNCDATE')

		if firstSync
			#Calculate the time bomb period
			lastSyncDate = Time.load(firstSync.value)
			expiryDate = lastSyncDate + (AgentReg.getCurrentAgentReg.activeDays.to_i * 24 * 60 * 60)
			timeDiff = expiryDate - Time.now
			if timeDiff < 0
				$showSync = true
				$dbUpdateMandatory = true
			end   
		else
			$showSync = true
			$dbUpdateMandatory = true
		end

		unless $showSync
			upgradeApp,mandatory = checkMasterDataVersion
			$showSync = upgradeApp
			$dbUpdateMandatory = mandatory
		end

		if $showSync
			#WebView.navigate('/app/SyncCategory/syncPreferences')
			redirect :controller => :SyncCategory , :action =>:syncPreferences
		else
			# WebView.navigate($rhoconfig[:post_login_path]) 
			redirect :action => :login
		end
	end  


	def disclaimerSubmit
		disclaimerId = @params['id'][1..-1].chop
		if disclaimerId == "agree"
			$login = true
			checkSyncPreferences
		else
			redirect :controller => :Menu, :action =>:exit
		end
	end


	def checkMasterDataVersion
		has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
		upgradeApp = false
		mandatory = false
		if has_network
			begin
				if($agentRegHash['dbVersion'] != nil)
					dBVersionOff = Application.getValue('DBVERSION').value
					if($agentRegHash['dbVersion'] != dBVersionOff) 
						upgradeApp = true
						if($agentRegHash['dbMandatory'] == "YES")
							mandatory = true
						end
					end
				else
					inputHash = Hash.new
					inputHash[Application.getValue('DBVERSION').value] = nil
					json = ::JSON.generate(inputHash)
					response = doJSONPost('/CheckMasterDataVersion.run', json)
					#process results
					resultsHash = Rho::JSON.parse(response)
					upgradeApp = true if resultsHash.length > 0

					mandatory = true if resultsHash.values[1] and resultsHash.values[1] == "YES"
					puts "mandatory value";
					puts mandatory.to_s;
					maxDbUpgradeDate = Date.parse resultsHash.values[0] if mandatory == true;
					puts "maxDbUpgradeDate value:";
					puts maxDbUpgradeDate.to_s;
					currentDate = Time.new;

					if(maxDbUpgradeDate.to_s != "")
						applicationParam = Application.find(:first,:conditions => {:key => 'MASTERDBUPGRADEDATE'})
						if(applicationParam == nil)  
							applicationParam = Application.new
							applicationParam.key = 'MASTERDBUPGRADEDATE';
							applicationParam.value = maxDbUpgradeDate;
							applicationParam.save;
						else
							applicationParam.value = maxDbUpgradeDate;
							applicationParam.save;
						end

						if(maxDbUpgradeDate == currentDate.to_date || currentDate.to_date  > maxDbUpgradeDate)
							# mandatory
							puts "maxDbUpgradeDate is today";
							$isMaxDbUpgrade = "YES"
						elsif ( currentDate.to_date  < maxDbUpgradeDate )
							puts "Do You want to upgrade now ?";
							$isMaxDbUpgrade = "NO"
						end
					end
					redirect :controller => :SyncCategory , :action =>:syncPreferences
				end
				unless upgradeApp
					if($agentRegHash['outputImageVersion'] != nil)
						outputImageVersionOff = Application.getValue('OUTPUTIMAGESVERSION').value
						if $agentRegHash['outputImageVersion'] != outputImageVersionOff
							upgradeApp = true
						end
					else
						inputHash = Hash.new
						inputHash[Application.getValue('OUTPUTIMAGESVERSION').value] = nil
						json = ::JSON.generate(inputHash)
						response = doJSONPost('/CheckOutputImagesVersion.run', json)
						resultsHash = Rho::JSON.parse(response)
						upgradeApp = true if resultsHash.length > 0
					end
				end
			rescue StandardError => se
				RhoLog::error('AgentRegController',se.to_s)
			end
		else
			applicationParam = Application.find(:first,:conditions => {:key => 'MASTERDBUPGRADEDATE'})
			currentDate = Time.new;
			if(applicationParam != nil)  
				if(maxDbUpgradeDate == currentDate.to_date || currentDate.to_date  > maxDbUpgradeDate)
					maxDbUpgradeDate = applicationParam.value;
					# mandatory
					puts "maxDbUpgradeDate is today";
					$isMaxDbUpgrade = "YES"
				elsif ( currentDate.to_date  < maxDbUpgradeDate )
					puts "Do You want to upgrade now ?";
					$isMaxDbUpgrade = "NO"
				end
			end
			redirect :controller => :SyncCategory , :action =>:syncPreferences
		end
		return upgradeApp,mandatory   
	end


	def warningTimerCallBack
		puts ">>>warningTimerCallBack called"
		if !$warningActive && $login
			$warningActive = true
			System.stop_timer((url_for :controller=>:AgentReg, :action=>:warningTimerCallBack))
			System.start_timer((Rho::RhoConfig.applicationtimeout.to_i - Rho::RhoConfig.warningtimeout.to_i).to_i, (url_for :controller=>:AgentReg, :action=>:sessionTimerCallBack), "sessionTimer")
			if System::get_property('platform').downcase.include?("windows")
				WebView.execute_js("applicationTimeOut('#{getLabelValue('APPLICATIONTIMEOUTWARNING')}')");
			else
				Alert.show_popup({
					:message => getLabelValue('APPLICATIONTIMEOUTWARNING'), 
					:title => getLabelValue('APPLICATIONTIMEOUT'),
					:buttons => ["OK"],
					:callback => url_for(:action => :dismissSessionPopup)
				})
			end
		end
	end

	def sessionTimerCallBack
		puts ">>>sessionTimerCallBack called"
		System.stop_timer((url_for :controller=>:AgentReg, :action=>:sessionTimerCallBack))
		renderToolbar(-1)
		$login = false
		$warningActive = false
		Alert.hide_popup
		WebView.navigate(Rho::RhoConfig.start_path)
	end


	def exitCallback
		System.exit
	end  


	def dismissSessionPopup
		puts ">>>dismissSessionPopup called"
		begin
			if @params["button_title"] == 'OK'
				diffTime = nil
				diffTime = (Time.now.to_i * 1000) - $inactivityTimer if defined? $inactivityTimer
				if diffTime && diffTime >= Rho::RhoConfig.applicationtimeout.to_i
					$login = false
					$warningActive = false
					WebView.navigate(Rho::RhoConfig.start_path)
				else
					System.stop_timer((url_for :controller=>:AgentReg, :action=>:sessionTimerCallBack))
					$warningActive = false
					resetTimer
				end
			end
		rescue StandardError => boom
			puts boom
		end
	end


	def checkifactive(agent)
		return (agent.agentStatusCd=="ACTIVE")? 1 : 0
	end
	
	def loginOnLangChange
		$agentRegHash = nil
		@agentreg = AgentReg.new

		if !$errors
			$errors = Hash.new
		end
		render :action => :login 
	end
	
	def onlineServer
		$rhoconfig[:create_db_seed] = @params["create_db_seed"]
		@onlineServer = @params['online_server_url']
		if @onlineServer == nil
			@onlineServer = Application.getValue('online_server_url').value
		else 
			online_server = Application.getValue('online_server_url')
			online_server.value = @onlineServer
			online_server.save 
			$savedUrl = "true"
		end
		@agentreg = AgentReg.new
		render :action => :login, :layout => :newEAPPLayout
	end

	# storing encryption keys
	def encryptPass
		WebView.execute_js("loading('show');")
        returnHash = {}
        returnHash[:RSA_KEY_encryptionExponent] = $rhoconfig[:RSA_KEY_encryptionExponent]
        returnHash[:RSA_KEY_modulus] = $rhoconfig[:RSA_KEY_modulus]
        render :nothing => true
        return returnHash.to_json
    end
	
end

begin 
	require 'AgentReg/agent_reg_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
	puts 'agent_reg_controller_Jazz not included'
end

begin 
	require 'AgentReg/agent_reg_controller_company'
rescue LoadError => e
	puts 'agent_reg_controller_company not included'
end
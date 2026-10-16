require 'CommonModules/mobisysuihelper_jazz'

class AgentRegController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper
    include MobiSys::UIHelper

	# GET /AgentReg/login
	def login
		WebView.execute_js("loading('show');")
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
				enableFingerprintScan
				render :file => "/AgentReg/login_Jazz.erb", :layout => :jazzLayout
			else
				if @onlineServer == nil
					@onlineServer = Application.getValue('online_server_url').value if Application.getValue('online_server_url')
				end
				if $savedUrl == "true"
					enableFingerprintScan
					render :file => "/AgentReg/login_Jazz.erb", :layout => :jazzLayout
				else
					render :file => "/AgentReg/onlineServer_Jazz.erb", :layout => :jazzLayout
				end 
			end 
		end
	end


	def onlineServer
		WebView.execute_js("loading('show');")
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
		enableFingerprintScan
		@agentreg = AgentReg.new
		render :file => "/AgentReg/login_Jazz.erb", :layout => :jazzLayout
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
			render :file => "/AgentReg/disclaimer_Jazz.erb", :layout => :jazzLayout
		else
			checkSyncPreferences
		end
	end


	def loginwait
		WebView.execute_js("loading('show');")
		renderToolbar(-1)
		$agentRegHash = @params['AgentReg']
		System.start_timer(1000,url_for(:action=>:register),"")
		render :file => "/AgentReg/loginWaitPage_Jazz.erb", :layout => :jazzLayout
	end


	def doJSON(currentAgentReg)
		agentregJSON = ::JSON.generate(currentAgentReg)
		result = doJSONPost('/agentregs.run', agentregJSON, currentAgentReg.userId, currentAgentReg.regPass)
		agentRegHash = Rho::JSON.parse(result)

		# Compare DB & Output Images version mismatch
		dBVersionOffObj = Application.getValue('DBVERSION')
		outputImageVersionOffObj = Application.getValue('OUTPUTIMAGESVERSION')
		
		# Update master db mandatory flag in Application table
		dbMandatory = Application.getValue('MASTERDBMANDATORY')
		unless dbMandatory
			dbMandatory = Application.create('MASTERDBMANDATORY',"NO")
		end
		dbMandatory.value = agentRegHash['dbMandatory']
		dbMandatory.save
		
		# Update master db upgrade date in Application table
		masterDbUpgradeDtObj = Application.getValue('MASTERDBUPGRADEDATE')
		unless masterDbUpgradeDtObj
			masterDbUpgradeDtObj = Application.create('MASTERDBUPGRADEDATE',Time.at(0))
		end
		masterDbUpgradeDtObj.value = agentRegHash['masterDBUpgradeDt']
		masterDbUpgradeDtObj.save


		# Update master data mismatch status in Application table
		masterDataMismatchObj = Application.getValue('MASTERDATAMISMATCH')
		unless masterDataMismatchObj
			masterDataMismatchObj = Application.create('MASTERDATAMISMATCH',"NO")
		end

		if agentRegHash['dbVersion'].to_s != dBVersionOffObj.value.to_s	|| agentRegHash['outputImageVersion'].to_s != outputImageVersionOffObj.value.to_s
			masterDataMismatchObj.value = "YES"
			masterDataMismatchObj.save
		else
			masterDataMismatchObj.value = "NO"
			masterDataMismatchObj.save
		end

		onlineAgentReg = MobiSys::MobiSysFixedSchema.from_hash('AgentReg',agentRegHash)
		return onlineAgentReg
	end


	def checkSyncPreferences
		forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

		if navigateToSync
			redirect :controller => :SyncCategory , :action => :syncPreferences, :query => {:forceNetworkLogin => forceNetworkLogin, :navigateToSync => navigateToSync, :masterSyncEnabled => masterSyncEnabled, :masterSyncDefault => masterSyncDefault, :transactionSyncEnabled => transactionSyncEnabled, :transactionSyncDefault => transactionSyncDefault, :masterDBUpgradeDt => masterDBUpgradeDt, :transactionSyncDt => transactionSyncDt, :masterDBMandatory => masterDBMandatory}
		else
			redirect :action => :login
		end
	end


	def push_callback
		puts "$$$$$ push_callback : #{@params}"

		"rho_push"
	end


	def get_device_id
		dev_id = Rho::Push.getDeviceId()
		notificationRegToken = Application.getValue("NOTIFICATIONREGTOKEN")
		Application.create("NOTIFICATIONREGTOKEN",dev_id) unless notificationRegToken
		# puts "$$$$$ Device ID from Ruby PUSH device id is = ["+dev_id.to_s+"]"
	end


	def wait_for_device_id
		# timer callback for checking push device id
		# puts "$$$$$ AgentReg.wait_for_device_id called !"
		dev_id = Rho::Push.getDeviceId()
		# puts "$$$$$ current push device id is = ["+dev_id.to_s+"]"

		if dev_id != nil
			notificationRegToken = Application.getValue("NOTIFICATIONREGTOKEN")
			Application.create("NOTIFICATIONREGTOKEN",dev_id) unless notificationRegToken
			# now application receive push device id from system!
			Rho::Timer.stop('/app/AgentReg/wait_for_device_id')
			# puts "$$$$$ Now we has push device id !"
		else
			# puts "$$$$$ Now we do not has push device id - should restart timer again !"
			Rho::Timer.start(500, '/app/AgentReg/wait_for_device_id', "rho_callback=1")
		end
	end


	def enableFingerprintScan
		if defined?(Rho::Fingerprint) && !Rho::System.isRhoSimulator && (System::get_property('platform') == 'ANDROID' || System::get_property('platform') == 'APPLE')
			agentList = AgentReg.find(:all)
			if $rhoconfig[:singleDeviceLogin] && agentList.size == 1
				@@userId = MobiSys::Encryption.decryptContent(agentList[0].userId)
				@@password = agentList[0].regPass
				agentList[0].enableFingerprintAuth = "YES"
				agentList[0].save
				Rho::Fingerprint.enableFingerprintScan(url_for(:action => :fetchCredsBasedOnFingerprintAuth))
			else
				agentList.each do |agent|
					if agent.enableFingerprintAuth.to_s == "YES"
						@@userId = MobiSys::Encryption.decryptContent(agent.userId)
						@@password = agent.regPass
						Rho::Fingerprint.enableFingerprintScan(url_for(:action => :fetchCredsBasedOnFingerprintAuth))
						break
					end
				end
			end
		end
	end


	def fetchCredsBasedOnFingerprintAuth
		puts "FingerprintAuthStatus----#{@params['authStatus']}"
		puts "FingerprintAuthStatusMessage----#{@params['statusMessage']}"
		if @params["authStatus"].to_s == "true"
			WebView.execute_js("fetchCredsBasedOnFingerprintAuth('#{@@userId}', '#{@@password}')")
		end
	end



end
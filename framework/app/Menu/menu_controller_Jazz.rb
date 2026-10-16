require 'CommonModules/mobisysuihelper_jazz'

class MenuController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper
    include MobiSys::UIHelper


	# GET /Menu/landingPage
	def landingPage
		Mobisys::Settings.updateRhoconfigParams
		@leadsDashboard = MobiSys::LeadBO.getDashboard()
		@quotationsDashboard = MobiSys::QuotationBO.getDashboard()
		@birthdayDashboard = MobiSys::QuotationBO.getBirthdayDashboard()
		@productsDashboard = MobiSys::ProductBO.getDashboard()
		MobiSys::ProductBO.freeSpace
		synList = $rhoconfig[:synConfig]
		manuList = $rhoconfig[:menuConfig]
		@synList = synList.split(',')
		@manuList = manuList.split(',')

		# Loading trackleads
		@trackLeads = {}
		@currentTab = 'NEWLEAD' unless @currentTab
		leadList = Lead.loadObject(:all)
		leadList.each do |lead|
			trackLead_entry = TrackLead.loadObject(:first,:conditions=>{:leadId=>lead.leadId.to_s})
			if trackLead_entry
				trackLead_entry.proposerName = lead.firstname.to_s + " " + lead.lastname.to_s
				@trackLeads[trackLead_entry.object] = [trackLead_entry.proposerName.to_s, trackLead_entry.productId.to_s, trackLead_entry.fnaId.to_s,trackLead_entry.quotationRefNum.to_s,trackLead_entry.proposalNum.to_s,getLabelValue(trackLead_entry.statusCd.to_s)] if trackLead_entry.fnaId.to_s == "" && trackLead_entry.quotationRefNum.to_s == "" && trackLead_entry.policyNum.to_s == ""
			end
		end

		@moreOptions, @moreOptionsURLS = requiredQuickLinks

		render :action =>:landingPage_Jazz, :layout => :jazzLayoutWithGraph
	end

	def about
		WebView.execute_js("loading('show');")
		@programVersion = Rho::RhoConfig.app_version

		if Application.getValue('mobiSysDeviceId') != nil
			@deviceId = Application.getValue('mobiSysDeviceId').value
		end

		@programReleaseDate = Rho::RhoConfig.last_release_date
		primaryDataLastSyncDate = Application.getValue('PRIMARYDATALASTSYNCDATE')
		if primaryDataLastSyncDate != nil
			@lastPrimaryDataSync = Time.load(primaryDataLastSyncDate.value).strftime("%d/%m/%Y %H:%M:%S")
		else
			@lastPrimaryDataSync = nil
		end

		currentAgentReg = AgentReg.getCurrentAgentReg
		if currentAgentReg != nil
			if currentAgentReg.lastSyncDt
				lastSyncDate = Time.load(currentAgentReg.lastSyncDt)  
				@lastApplicationDataSync = lastSyncDate.strftime("%d/%m/%Y %H:%M:%S")
			else
				@lastApplicationDataSync = nil
			end

			forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")

			useUpto = transactionSyncDt
			useUpto = masterDBUpgradeDt if masterSyncDefault == "ON" && masterDBUpgradeDt < transactionSyncDt
			
			@useUpto = useUpto.strftime("%d/%m/%Y %H:%M:%S")

			if currentAgentReg.userId
				@userId = currentAgentReg.userId
			else
				@userId = nil
			end

			if currentAgentReg.channel
				@channel = currentAgentReg.channel
			else
				@channel = nil
			end

			if currentAgentReg.licenseType
				@licenseType = currentAgentReg.licenseType
			else
				@licenseType = nil
			end

			if currentAgentReg.agentName1
				@agentName1 = currentAgentReg.agentName1
			else
				@agentName1 = nil
			end

			if currentAgentReg.location
				@location = currentAgentReg.location
			else
				@location = nil
			end

			if currentAgentReg.agentId
				@agentId = currentAgentReg.agentId
			else
				@agentId = nil
			end
		else
			@lastApplicationDataSync = nil
			@useUpto = nil
			@agentId = nil
			@channel = nil
			@licenseType = nil
			@agentName1 = nil
			@location = nil
		end

		if Application.getValue('DBVERSION') != nil    
			@offlineMasterDBVersion = Application.getValue('DBVERSION').value
		end

		lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
		if lastCollateralSyncDate
			@lastCollateralSyncDate = Time.load(lastCollateralSyncDate.value).strftime("%d/%m/%Y %H:%M:%S")
		else
			@lastCollateralSyncDate = nil
		end

		render :action => :about_Jazz, :layout => :jazzLayout
	end

	def onlineServer
		WebView.execute_js("loading('show');")
		@onlineServer = @params['online_server_url']
		if @onlineServer == nil
			@onlineServer = Application.getValue('online_server_url').value
		else
			online_server = Application.getValue('online_server_url')
			online_server.value = @onlineServer
			online_server.save 
		end
		render :action => :onlineServer_Jazz, :layout => :jazzLayout
	end

	def offlineServer
		@uses_rules = @params['uses_rules']
		if @uses_rules == nil
			@uses_rules = Application.getValue('uses_rules').value
		else
			uses_rules = Application.getValue('uses_rules')
			uses_rules.value = @uses_rules
			uses_rules.save 
		end
		render :action => :offlineServer_Jazz, :layout => :jazzLayout
	end

	def securitySetting
		@enableFingerprintAuth = @params['enableFingerprintAuth']
		if @enableFingerprintAuth == nil
			@enableFingerprintAuth = AgentReg.getCurrentAgentReg.enableFingerprintAuth
		else
			currentAgentReg = AgentReg.forUserId($userId, true)
			# currentAgentReg.userId = MobiSys::Encryption.encryptContent(currentAgentReg.userId)
			currentAgentReg.enableFingerprintAuth = @enableFingerprintAuth
			currentAgentReg.save 
		end
		render :action => :securitySetting_Jazz, :layout => :jazzLayout
	end

	def showPopUp
		title = getLabelValue(@params['title'])
		message = getLabelValue(@params['message'])
		buttonLabel = getLabelValue("OK")
		Alert.show_popup({
			:title=>title,
			:message=>message,
			:buttons=>[buttonLabel]
		})
		render :action => :showPopUp
	end

	def getInsuranceType
		WebView.execute_js("loading('show');")
		insuranceTypeCd = nil
		showInsuranceCapturePage = false
		@actionModule = @params['module']
		lookup_values = Lookupvalue.getValue('INSURANCETYPE')
		if lookup_values
			@insuranceTypes = lookup_values.collect{|lk| lk.cd}
			showInsuranceCapturePage = true if @insuranceTypes.size > 1
			if @insuranceTypes.size == 1
				insuranceTypeCd = @insuranceTypes[0]
			end
		end
		if @actionModule == 'SALESILLUSTRATION'
			if @params.has_key?('leadid')
				@url = "/app/Quotation/newCaptureIllustration?leadid=#{@params['leadid']}&insuranceTypeCd="
				navigation_url = "#{url_for :controller => :Quotation, :action => :newCaptureIllustration, :query => {:leadid => @params['leadid'], :insuranceTypeCd => insuranceTypeCd}}"
			else
				@url = '/app/Quotation/search?insuranceTypeCd='
				navigation_url = "#{url_for :controller => :Quotation, :action => :search, :query => {:insuranceTypeCd => insuranceTypeCd}}"
			end
		elsif @actionModule == 'EAPP'
			@url = '/app/Policy/searchProposal?insuranceTypeCd='
			navigation_url = "#{url_for :controller => :Policy, :action => :searchProposal, :query => {:insuranceTypeCd => insuranceTypeCd}}"
		end
		if showInsuranceCapturePage
			render :action => 'captureInsuranceType', :layout => :jazzLayout
		else
			WebView.navigate("#{navigation_url}")
		end
	end

	def colorSettings
		@colorHash = {}
		$rhoconfig[:colors].split(',').each do |color|
			if color == 'blue'
				@colorHash[color] = '#143181'
			else
				@colorHash[color] = ''
			end
		end
		render :action => :colorSettings, :layout => :jazzLayout
	end

	def changeColor
		if @params['color'] == 'blue'
			$blueTheme = true
		else
			$blueTheme = false
		end
		redirect :action => :colorSettings, :layout => :jazzLayout
	end

	def landingSubmit
		@leadStage = @params['leadStage'].to_s
		@trackLeads = {}
		trackLeadList = TrackLead.loadObject(:all)
		@currentTab = @params['currentTab']
		@currentTab = 'NEWLEAD' unless @currentTab
		proposerName = @params['proposerName'].to_s.strip.downcase if @params['proposerName'] != nil
        productId = @params['productId'].strip.to_s if @params['productId'] != nil
        fnaId = @params['fnaId'].strip.to_s if @params['fnaId'] != nil
        quotationRefNum = @params['quotationRefNum'].strip.to_s if @params['quotationRefNum'] != nil
        proposalNum = @params['proposalNum'].strip.to_s if @params['proposalNum'] != nil
        statusCd = @params['statusCd'].to_s.strip.downcase if @params['statusCd'] != nil
		trackLeadList.each do |trackLead_entry|
			lead = Lead.loadObject(:first,:conditions=>{:leadId=>trackLead_entry.leadId.to_s})
			searchFilterPassed = true
			stageFilterPassed = false
			if trackLead_entry && lead
				trackLead_entry.proposerName = lead.firstname.to_s + " " + lead.lastname.to_s
				if @leadStage == "" || @leadStage == "newlead"
					if trackLead_entry.fnaId.to_s == "" && trackLead_entry.quotationRefNum.to_s == "" && trackLead_entry.policyNum.to_s == ""
						stageFilterPassed = true
					end
				elsif @leadStage == "searchLead"
					stageFilterPassed = true
					if @params['mainSearchField'].to_s == ""
						if proposerName != ""
                        	searchFilterPassed = false unless trackLead_entry.proposerName.to_s.include?(proposerName)
                    	end
                    	if productId != "" 
                    		searchFilterPassed = false unless trackLead_entry.productId.to_s.include?(productId)
                    	end
                    	if fnaId != ""
                    		searchFilterPassed = false unless trackLead_entry.fnaId.to_s.include?(fnaId)
                    	end
                    	if quotationRefNum != ""
                    		searchFilterPassed = false unless trackLead_entry.quotationRefNum.to_s.include?(quotationRefNum)
                    	end
                    	if proposalNum != ""
                    		searchFilterPassed = false unless trackLead_entry.proposalNum.to_s.include?(proposalNum)
                    	end
                    	if statusCd != ""
                    		searchFilterPassed = false unless trackLead_entry.statusCd.to_s.include?(statusCd)
                    	end
					elsif trackLead_entry.leadId.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil && 
						trackLead_entry.proposerName.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil && 
						trackLead_entry.productId.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil && 
						trackLead_entry.quotationRefNum.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil && 
						trackLead_entry.policyNum.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil &&
						trackLead_entry.statusCd.to_s.downcase.index(@params['mainSearchField'].to_s.downcase) == nil
						searchFilterPassed = false
					end
				else
					if @leadStage == "fna" && trackLead_entry.fnaId.to_s != "" && trackLead_entry.quotationRefNum.to_s == "" && trackLead_entry.policyNum.to_s == ""
						stageFilterPassed = true
					elsif @leadStage == "si" && trackLead_entry.quotationRefNum.to_s != "" && trackLead_entry.policyNum.to_s == "" && trackLead_entry.proposalNum.to_s == ''
						stageFilterPassed = true
					elsif @leadStage == "eapp" && (trackLead_entry.policyNum.to_s != "" || trackLead_entry.proposalNum.to_s != '')
						stageFilterPassed = true
					end
				end
				@trackLeads[trackLead_entry.object] = [trackLead_entry.proposerName.to_s, trackLead_entry.productId.to_s, trackLead_entry.fnaId.to_s,trackLead_entry.quotationRefNum.to_s,trackLead_entry.proposalNum.to_s,getLabelValue(trackLead_entry.statusCd.to_s)] if searchFilterPassed && stageFilterPassed
			end
		end

		@moreOptions, @moreOptionsURLS = requiredQuickLinks
		
		render :action =>:landingPage_Jazz, :layout => :jazzLayoutWithGraph
	end

	def showLead
		id = @params['id'][1..-1].chop
		trackLead = TrackLead.loadObject(:first,:conditions=>{:object=>id.to_s})
		lead = Lead.loadObject(:first, :conditions => {:object => trackLead.leadId.gsub("_",".") })
		if lead
			redirect :action => :showLead, :controller => :Lead, :id => lead.object
		end
	end


	def showFNA
		id = @params['id'][1..-1].chop
		trackLead = TrackLead.loadObject(:first,:conditions=>{:object=>id.to_s})
		fnaRequest = FNARequest.loadObject( :first, :conditions => { :fnaNum => trackLead.fnaId } )
		if fnaRequest
			redirect :action => :show, :controller => :FNARequest, :query => {:fnaNum => fnaRequest.fnaNum}
		else
			Alert.show_popup({
                :message => getLabelValue('No FNA found.'), 
                :title => getLabelValue("error"),
                :buttons => ["OK"]
            })
            redirect :action => :landingPage, :controller => :Menu, :layout => :jazzLayout
		end
	end


	def showQuotation
		id = @params['id'][1..-1].chop
		trackLead = TrackLead.loadObject(:first,:conditions=>{:object=>id.to_s})
		quotation = Quotation.loadObject(:first, :conditions => {:quotationRefNum => trackLead.quotationRefNum})
		if quotation
			redirect :action => :show, :controller => :Quotation, :query => {:quotationId => quotation.quotationRefNum}
		else
			Alert.show_popup({
                :message => getLabelValue('No quotation found.'), 
                :title => getLabelValue("error"),
                :buttons => ["OK"]
            })
            redirect :action => :landingPage, :controller => :Menu, :layout => :jazzLayout
		end
	end


	def showProposal
		id = @params['id'][1..-1].chop
		trackLead = TrackLead.loadObject(:first,:conditions=>{:object=>id.to_s})
		policy = Policy.loadObject(:first, :conditions => {:proposalNum => trackLead.proposalNum})
		if policy
			redirect :action => :showProposal, :controller => :Policy, :id => policy.object
		else
   			Rho::WebView.executeJavascript("raiseAlert(getLabelValue('No policy found.'),[],locale);")
            redirect :action => :landingPage, :controller => :Menu, :layout => :jazzLayout
		end
	end

	def requiredQuickLinks
		quickLinks = Hash.new
		quickLinks['Add Lead_Menu_LV'] = '/app/Lead/newLead'
		quickLinks['ACTIVITYLIST'] = '/app/Lead/activityList'

		quickLinkLabels = quickLinks.keys.join(",")
        quickLinkActions = quickLinks.values.join(",")

        return quickLinkLabels,quickLinkActions

	end

	def addProposal
		id = @params['id'][1..-1].chop
		trackLead = TrackLead.loadObject(:first,:conditions=>{:object=>id.to_s})
		quotation = Quotation.loadObject(:first, :conditions => {:quotationRefNum => trackLead.quotationRefNum})
		if quotation
			redirect :action => :linkToEapp, :controller => :Quotation, :query =>{ :quotationId => quotation.object}
		else
			Alert.show_popup({
                :message => getLabelValue('No quotation found.'), 
                :title => getLabelValue("error"),
                :buttons => ["OK"]
            })
            redirect :action => :landingPage, :controller => :Menu, :layout => :jazzLayout
		end
	end

	def backButton
        Rho::WebView.navigateBack
    end
    def profile
    	render :action =>:profile_Jazz, :layout => :jazzLayout
    end

    def landingAlertSubmit
		render :action =>:landingPageAlert_Jazz, :layout => :jazzLayoutWithGraph
	end

	def setPolicyModelLog
		@setPolicyModelLog = @params['setPolicyModelLog'].to_s
		if @params['setPolicyModelLog'].to_s == "YES"
			$rhoconfig[:setPolicyModelLog] = 1
		elsif @params['setPolicyModelLog'].to_s == "NO"
			$rhoconfig[:setPolicyModelLog] = 0
		end

		$rhoconfig[:setPolicyModelLog] == 1 ? @setPolicyModelLog = "YES" : @setPolicyModelLog = "NO"
		
		render :action => :setPolicyModelLog, :layout => :jazzLayout
	end

	def showLogFile
	    fileName = "#{@params['logFileName']}.txt"
		Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
		downloadFolder = Rho::RhoApplication.get_blob_folder
		filePath = File.join(downloadFolder, fileName)
		if File::exist? filePath
			System.open_url filePath
		else
			Alert.show_popup({:title=>'Policy Log',
			:message=>'Error: Policy Log file not available.',
			:buttons=>["OK"]})
		end
    end

    def uploadLogs
		currentTime = Time.now.strftime('%Y-%m-%d %H:%M:%S:%L%z')
		currentTime = currentTime.to_s.gsub(/^.*(\\|\/)/, '')
		currentTime = currentTime.gsub(/[^0-9A-Za-z.\-]/, '_')
		zipfilename = "rholog_#{currentTime}"
		logFilePath = Rho::Log.filePath
		destFile = "#{zipfilename}.txt"
		# sourcefilepath = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}")
		destFilePath = Rho::RhoFile.join(Rho::Application.userFolder, "#{destFile}")
		if File.exist?(logFilePath)
			Rho::RhoFile.copy(logFilePath, destFilePath)
			userName = $userId
			password =  $userPassword
			local_path_to_zip = Rho::RhoFile.join(Rho::Application.userFolder, "#{zipfilename}.zip")
			Rho::System.zipFile(local_path_to_zip, destFilePath)
			upload_url = Application.getValue('online_server_url').value + "/RhoLogFileDownload.run"
			begin
                Rho::AsyncHttp.upload_file(
                  :url => upload_url,
                  :filename => local_path_to_zip,
                  :body => "", #=> leave blank, AsyncHttp will fill in multipart body
                  :headers => {"username"=>$userId,"password"=>$userPassword},
                  :callback => '/app/Menu/timerCallback2',
                  :callback_param => "local_path_to_zip=#{local_path_to_zip}&destFilePath=#{destFilePath}",
                  :ssl_verify_peer => $ssl_verify_peer)
            rescue Exception => e
                puts ">>>exception in upload file: #{e}"
            end
			redirect :action => :uploadingfile, :controller => :Menu
		else
			Alert.show_popup({
                :message => getLabelValue('No such file.'), 
                :title => getLabelValue("error"),
                :buttons => ["OK"]
            })
            redirect :action => :landingPage, :controller => :Menu
		end
		
	end

	def uploadingfile
        render :action=>:uplodinglog_Jazz, :layout => :jazzLayout
    end

    def timerCallback2
    	puts ">>>upload Completed with params: #{@params}"
    	if @params.has_key?('status') and @params['status'].to_s == 'ok'
    		message = getLabelValue('File uploaded successfully')
	 		
	 	else
	 		message = getLabelValue('Error occurred while uploading file')
	 	end
	 	File.delete(@params['local_path_to_zip']) if @params.has_key?('local_path_to_zip') and File.exists?(@params['local_path_to_zip']) 
		File.delete(@params['destFilePath']) if @params.has_key?('destFilePath') and File.exists?(@params['destFilePath'])	
	 	Alert.show_popup({
            :message => message, 
            :title => getLabelValue("Info"),
            :buttons => ["OK"]
        })
        WebView.navigate('/app/Menu/landingPage')
    end
end
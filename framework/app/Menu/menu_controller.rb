require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Quotation/quotation_b_o'
require 'Lead/lead_b_o'
require 'Product/product_b_o'
require 'date'
require 'CommonModules/metadata'
require 'CommonModules/settings.rb'

class MenuController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper


	# def prompt
	# 	url = @params['url']
 #    	if @params['calledFrom'] == 'Exit'
 #      		Alert.show_popup( { :message => getLabelValue("Are you sure you want to exit?"), :title => getLabelValue("TOOLBAR_PROMPT_TITLE"),
	# 			:buttons=>["Ok","Cancel"],
	# 			:callback => url_for(:action => :prompt_dismiss,:query => {"url" => url}) } )
	# 	else
	# 		Alert.show_popup( { :message => getLabelValue("TOOLBAR_PROMPT_MESSAGE"),
	# 			:buttons=>["Ok","Cancel"],
	# 			:callback => url_for(:action => :prompt_dismiss,:query => {"url" => url}) } )
	# 	end  
 #  	end

	# def prompt_dismiss
	# 	id = @params["button_index"]
	# 	if id.to_s == '0'
	# 		url = @params["url"]
	# 		WebView.navigate(url)
	# 	end
	# end


	# GET /Menu/landingPage
	def landingPage		
		renderToolbar(0)
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
		render :action =>:landingPage, :layout => :newEAPPLayout
	end

	# GET /Menu/settings
	def settings
		renderToolbar(0)
		render :back => :landingPage, :layout => :newEAPPLayout
	end


	# GET /Menu/salesIllustration
	def salesIllustration
		$filteredPlans = nil
		MobiSys::ProductBO.freeSpace
		renderToolbar(3)
		render :action =>:salesIllustration, :layout => :newEAPPLayout
	end


	# GET /Menu/salesInformation
	def salesInformation
		renderToolbar(0)
		render :back => :landingPage
	end


	# GET /Menu/agentInformation
	def agentInformation
		renderToolbar(0)
		render :back => :landingPage
	end


	# GET /Menu/about
	def about
		renderToolbar(0)
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

			if primaryDataLastSyncDate != nil
				useUpto = Time.load(primaryDataLastSyncDate.value) + (currentAgentReg.activeDays.to_i * 24 * 60 * 60)
			else
				useUpto = Time.now  + (currentAgentReg.activeDays.to_i * 24 * 60 * 60)
			end

			#useUpto = Time.load(primaryDataLastSyncDate.value) + (currentAgentReg.activeDays.to_i * 24 * 60 * 60)
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

		render :action => :about, :layout => :newEAPPLayout
	end


	# GET /Menu/exit
	def exit
		logUserExitDetails
		# session termination
		$login = false
		System.exit
		render :action => :exit
	end


	def logUserExitDetails
		userLoginHistory = UserLoginHistory.new
		userLoginHistory.modeCd = 'OFFLINE'
		userLoginHistory.deviceId = Application.getValue('deviceSeq').value.to_s
		userLoginHistory.logoutDt = Time.now
		userLoginHistory.osVersion = System::get_property('os_version').to_s
		userLoginHistory.dbVersion = Application.getValue('DBVERSION').value.to_s
		userLoginHistory.applicationVersion = Rho::RhoConfig.app_version
		userLoginHistory.activity = 'LOGOUT'
		userLoginHistory.persistAll
	end


	def leads
		renderToolbar(2)
		render :action => :leads, :layout => :newEAPPLayout
	end
	
	def fna
	  	renderToolbar(0)
	  	render :action => :fna, :layout => :newEAPPLayout
	end


	def eapp
		$filteredPlans = nil
		renderToolbar(4)
		render :action => :eapp, :layout => :newEAPPLayout
	end


	def receipting
		renderToolbar(5)
	end


	def calculators
		renderToolbar(6)
	end


	# GET /app/Menu/showPopUp
	def showPopUp
		title = @params['title']
		message = @params['message']
		puts "Popup >> " << title << ":" << message
		Alert.show_popup({:title=>title,
			:message=>message,
			:buttons=>[getLabelValue("OK")]})

		render :action => :showPopUp
	end


	# GET /Menu
	def index
		@menus = Menu.find(:all)
		render :back => '/app'
	end


	# GET /Menu/{1}
	def show
		@menu = Menu.find(@params['id'])
		if @menu
			render :action => :show, :back => url_for(:action => :index)
		else
			redirect :action => :index
		end
	end


	def product_filter
		$renderPage = @params['render_page']
	end


	def product_filter_illustration
		$renderPage = @params['render_page']
	end


	# def filter_product
	# 	@sql = ""
	# 	if @params["sex"] == 'MALE'
	# 		@sql << "SELECT productId, PlanType FROM ProductFiltering where genderCd like ('MALE%') "
	# 		@sql << " and entryAgeFrom < #{@params['age']} and entryAgeTO > #{@params['age']} " if @params['age'] != ""
	# 		@sql << "and productTypeCd != 'RIDER' and smokerStatus = '#{@params['smoker']}' group by productId"
	# 	else
	# 		@sql << "SELECT productId, PlanType FROM ProductFiltering where genderCd like ('%FEMALE') "
	# 		@sql << " and entryAgeFrom < #{@params['age']} and entryAgeTO > #{@params['age']} " if @params['age'] != ""
	# 		@sql << "and productTypeCd != 'RIDER' and smokerStatus = '#{@params['smoker']}' group by productId"
	# 	end
	# 	$filteredPlans = ProductFiltering.find_by_sql(@sql)
	# 	redirect :controller => :Policy, :action => :productSelect
	# end


	# def filter_product_illustration
	# 	@sql = ""
	# 	if @params["sex"] == 'MALE'
	# 		@sql << "SELECT productId, PlanType FROM ProductFiltering where genderCd like ('MALE%') "
	# 		@sql << " and entryAgeFrom < #{@params['age']} and entryAgeTO > #{@params['age']} " if @params['age'] != ""
	# 		@sql << "and productTypeCd != 'RIDER' and smokerStatus = '#{@params['smoker']}' group by productId"
	# 	else
	# 		@sql << "SELECT productId, PlanType FROM ProductFiltering where genderCd like ('%FEMALE') "
	# 		@sql << " and entryAgeFrom < #{@params['age']} and entryAgeTO > #{@params['age']} " if @params['age'] != ""
	# 		@sql << "and productTypeCd != 'RIDER' and smokerStatus = '#{@params['smoker']}' group by productId"
	# 	end
	# 	$filteredPlans = ProductFiltering.find_by_sql(@sql)
	# 	redirect :controller => :Quotation, :action => :productPage
	# end


	# GET /Menu/new
	def new
		@menu = Menu.new
		render :action => :new, :back => url_for(:action => :index)
	end


	# GET /Menu/{1}/edit
	def edit
		@menu = Menu.find(@params['id'])
		if @menu
			render :action => :edit, :back => url_for(:action => :index)
		else
			redirect :action => :index
		end
	end


	# POST /Menu/create
	def create
		@menu = Menu.create(@params['menu'])
		redirect :action => :index
	end


	# POST /Menu/{1}/update
	def update
		@menu = Menu.find(@params['id'])
		@menu.update_attributes(@params['menu']) if @menu
		redirect :action => :index
	end


	# POST /Menu/{1}/delete
	def delete
		@menu = Menu.find(@params['id'])
		@menu.destroy if @menu
		redirect :action => :index  
	end

	def login
		renderToolbar(-1)
		render :action => :login, :back => url_for(:action => :index)
	end

	def loginwait
		renderToolbar(-1)
		System.start_timer(1000,url_for(:action=>:synchronisewait),"")
		render :action => :loginWaitPage

	end

	def synchronisewait
		System.stop_timer(url_for(:action=>:synchronisewait))
		sleep(1)
		agentReg = AgentReg.forUserId($userId)
		if agentReg == nil
			agentReg = AgentReg.new
			agentReg.userId = MobiSys::Encryption.encryptContent($userId)
			agentReg.deviceUserSeq = 420840
			agentReg.applicableProducts='FWD,PAP'
		end
		agentReg.save

		deviceId = Application.getValue(MobiSys::MOBISYSDEVICEID)

		if deviceId == nil    
			deviceId = Application.new
			deviceId.key=MobiSys::MOBISYSDEVICEID
			deviceId.value = 'TEMPMOBISYSDEVICEID123456789'
			deviceId.save 
		end
		if Rho::RhoConfig.exists?('test_post_login')
			WebView.navigate(Rho::RhoConfig.test_post_login)
		end

		WebView.navigate(url_for( :action => :landingPage))
	end


	def synchronise
		renderToolbar(0)
		render :action => :landingPage, :back => url_for(:action => :index)
	end


	def getDate
		title = @params['title']
		if @params['datetime'] != nil && @params['datetime'] != ""
			initial_time = Time.strptime(@params['datetime'], "%d/%m/%Y")
			datetime = @params['datetime']
		else
			initial_time = Time.now
			datetime = initial_time.strftime("%d/%m/%Y")
		end
		DateTimePicker.choose('/app/Menu/dateTimeCallback', title, initial_time, 1, @params['fieldKey']+'|1|'+datetime) 
	end 


	def getDateTime
		title = @params['title']
		if @params['datetime'] != nil && @params['datetime'] != ""
			initial_time = Time.strptime(@params['datetime'], "%d/%m/%Y %H:%M:%S %z")
			datetime = @params['datetime']
		else
			initial_time = Time.now
			datetime = initial_time.strftime("%d/%m/%Y %H:%M:%S %z")
		end
		DateTimePicker.choose('/app/Menu/dateTimeCallback', title, initial_time, 0, @params['fieldKey']+'|0|'+datetime) 
	end 


	def getTime
		title = @params['title']
		if @params['datetime'] != nil && @params['datetime'] != ""
			initial_time = Time.strptime(@params['datetime'], "%I:%M:%S %z %p")
			datetime = @params['datetime']
		else
			initial_time = Time.now
			datetime = initial_time.strftime("%I:%M:%S %z %p")
		end
		DateTimePicker.choose('/app/Menu/dateTimeCallback', title, initial_time, 2, @params['fieldKey']+'|2|'+datetime) 
	end 


	def dateTimeCallback
		params = @params
		opaque = @params['opaque']
		data = opaque.split("|")
		timeString = ""
		if data[1] == "0"
			# timeString = "%d/%m/%Y %I:%M:%S %z"  
			timeString = "%d/%m/%Y %I:%M %p"  
		elsif data[1] == "1"
			timeString = "%d/%m/%Y"
		else
			timeString = "%I:%M:%S %p"
		end

		if @params['result'] != nil
			WebView.execute_js('setFieldValue("'+data[0]+'","'+Time::at(@params['result'].to_i).strftime(timeString)+'");')
		end
  	end


	def register
		renderToolbar(-1)    
		render :action => :register, :back => url_for(:action => :index)
	end


	def onlineServer
		renderToolbar(0) 
		@onlineServer = @params['online_server_url']
		if @onlineServer == nil
			@onlineServer = Application.getValue('online_server_url').value
		else
			online_server = Application.getValue('online_server_url')
			online_server.value = @onlineServer
			online_server.save 
		end
		render :action => :onlineServer, :layout => :newEAPPLayout
	end


	def offlineServer
		renderToolbar(0) 
		@uses_rules = @params['uses_rules']
		if @uses_rules == nil
			@uses_rules = Application.getValue('uses_rules').value
		else
			uses_rules = Application.getValue('uses_rules')
			uses_rules.value = @uses_rules
			uses_rules.save 
		end
		render :action => :offlineServer, :layout => :newEAPPLayout
	end

end

begin 
    require 'Menu/menu_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'menu_controller_Jazz not included'
end

begin 
    require 'Menu/menu_controller_company'
rescue LoadError => e
    puts 'menu_controller_company not included'
end
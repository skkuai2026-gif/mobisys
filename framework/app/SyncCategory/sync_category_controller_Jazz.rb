require 'CommonModules/mobisysuihelper_jazz'

class SyncCategoryController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    # POST /SyncCategory/syncPreferences
    def syncPreferences
    	WebView.execute_js("loading('show');")
		renderToolbar(-1)
		synList = $rhoconfig[:synConfig].split(',')

		@params["forceNetworkLogin"], @params["navigateToSync"], @params["masterSyncEnabled"], @params["masterSyncDefault"], @params["transactionSyncEnabled"], @params["transactionSyncDefault"], @params["masterDBUpgradeDt"], @params["transactionSyncDt"], @params["masterDBMandatory"] = MobiSys::Sync.processForceLoginSyncConditions("sync") if @params.empty?

		# heading + list of transactions is a category
		# each entity that can be synced (has a sync slider button) is a transaction
		# each category can have one heading and a list of transactions

		@category = {}
		SyncCategory.find(:all).each do |syncCategory|
			@category[getLabelValue(syncCategory.categoryCd.to_s).to_s] = [] unless 
			@category[getLabelValue(syncCategory.categoryCd.to_s).to_s].is_a?(Array)
			if synList.include?(syncCategory.subCategoryCd.to_s)
				enableText = ""
				selectedValue = "OFF"
				transaction_hash = {:note=>""}
				if syncCategory.subCategoryCd.to_s == "MASTER"
					if $rhoconfig[:create_db_seed] != "YES"
						enableText = "disabled" if @params["masterSyncEnabled"].to_s == "false"
						selectedValue = "ON" if @params["masterSyncDefault"].to_s == "ON"
					end
					transaction_hash[:label] = getLabelValue(syncCategory.subCategoryCd.to_s)
					transaction_hash[:torender] = renderLookupSwitch("SWITCH", "syncCategory[#{syncCategory.subCategoryCd}]", selectedValue, "flipswitch", nil, nil, enableText)
					if @params["masterSyncEnabled"].to_s == "true"
							transaction_hash[:note] = getLabelValue('NEWDBAVAILABLE');
					 	if @params["masterSyncDefault"].to_s == "ON" && @params["masterDBMandatory"].to_s == "true"
								transaction_hash[:note] = transaction_hash[:note] + "<br>"+getLabelValue('NEXTMASTERSYNC') +" "+ getScreenDate(@params['masterDBUpgradeDt'].to_s)
						end
					elsif @params["masterSyncDefault"].to_s == "ON"
							transaction_hash[:note] = getLabelValue('NEWDBAVAILABLE')
					end
				elsif syncCategory.subCategoryCd.to_s == "USERTRANSACTIONS"
					if $rhoconfig[:create_db_seed] != "YES"
						enableText = "disabled" if @params["transactionSyncEnabled"].to_s == "false"
						selectedValue = "ON" if @params["transactionSyncDefault"].to_s == "ON"
					end
					transaction_hash[:label] = getLabelValue(syncCategory.subCategoryCd.to_s)
					transaction_hash[:torender] = renderLookupSwitch("SWITCH", "syncCategory[#{syncCategory.subCategoryCd}]", selectedValue, "flipswitch", nil, nil, enableText)
					if @params["transactionSyncDefault"].to_s == "OFF"
						transaction_hash[:note] = getLabelValue('NEXTUSERTRANSACTIONSYNC') +" "+getScreenDate(@params['transactionSyncDt'].to_s)
					end
				else
					if $rhoconfig[:create_db_seed] != "YES"
						selectedValue = "ON" if $collateralUpdateMandatory
					end
					transaction_hash[:label] = getLabelValue(syncCategory.subCategoryCd.to_s)
					transaction_hash[:torender] = renderLookupSwitch("SWITCH", "syncCategory[#{syncCategory.subCategoryCd}]", selectedValue, "flipswitch", nil, nil, enableText)
				end
				@category[getLabelValue(syncCategory.categoryCd.to_s).to_s] << transaction_hash
            end
        end
        @backLink = $rhoconfig[:post_login_path] if @params["forceNetworkLogin"].to_s == "false"

        render :action => :preferences_Jazz, :layout => :jazzLayout
    end

    def partialSyncPreferences
		@backLink = $rhoconfig[:post_login_path]
		$original_create_db_seed = $rhoconfig[:create_db_seed]
		$original_seed_from_db = $rhoconfig[:seed_from_db]
		$rhoconfig[:create_db_seed] = "YES"
		$rhoconfig[:seed_from_db] = "NO"

    	@syncEntities = SyncEntity.find(:all,:conditions=>{:entitySubCategory=>"MASTER"})
     	render :action => :partialPreferences_Jazz, :layout => :jazzLayout
    end

    def partialSynchronize
        syncEntities = Array.new
		currentSyncEntities = SyncEntity.find(:all,:conditions=>{:entitySubCategory=>"MASTER"})
	   	if currentSyncEntities
	   	    currentSyncEntities.each do |syncEntity|
  				if @params["partialSyncCheck"].include? syncEntity.entityName
	   	    		syncEntities.push syncEntity
					eval("#{syncEntity.entityName}.delete_all()")
					if $childClasses[syncEntity.entityName.to_s]
						$childClasses[syncEntity.entityName.to_s].each do |child|
							eval("#{child}.delete_all()")
						end
					end
	   	    	end
	   	    end
   	 	end
        $syncEntities = syncEntities
        System.start_timer(2000,url_for(:action=>:timerCallbackPartial),$syncEntities.to_s)
        render :action => :syncProgress_Jazz, :layout => :jazzLayout
    end    	
    
    def timerCallbackPartial
    System.stop_timer(url_for(:action=>:timerCallback))
    begin
      $syncLogs = Array.new
      $partialSync = true
      transactionEntityCount = MobiSys::Sync.All($syncEntities)
      MobiSys::ProductBO.freeSpace
	  $partialSync = nil
	  #reset db flag parameter
		$rhoconfig[:create_db_seed] = $original_create_db_seed
		$original_create_db_seed = nil
		$rhoconfig[:seed_from_db] = $original_seed_from_db
		$original_seed_from_db = nil
        WebView.navigate($rhoconfig[:post_login_path])
      
    rescue StandardError => boom
      puts boom
    end
  end


    def synchronize
        syncEntities = Array.new
        if @params['syncCategory']
        	@params['syncCategory'].each do |key,value|
        		puts "+++++" + key.to_s
        		puts "-----" + value.to_s
        		if value.to_s == 'ON'
					#Fetch the SyncEntitites
					currentSyncEntities = SyncEntity.find(:all,:conditions=>{:entitySubCategory=>key.to_s})
					if currentSyncEntities
						currentSyncEntities.each do |currentSyncEntity|
							syncEntities.push currentSyncEntity
						end
					end  
					puts ">>Found #{syncEntities.to_s} for processing"
				end
			end
		end
        puts Thread.current.inspect + "Found #{syncEntities.size} for processing"
        $syncEntities = syncEntities
        System.start_timer(2000,url_for(:action=>:timerCallback),$syncEntities.to_s)
        render :action=> :syncProgress_Jazz, :layout => :jazzLayout
    end

end
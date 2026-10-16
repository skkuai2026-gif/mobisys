require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'


class SyncEntityController < BaseRestController
	include BrowserHelper
	include MobiSys::BrowserHelper

	def initialize
		# logInfo("~~~in AgentRegController initialize")
	end

	def getEntitiesForSync
        responseHash = {}
        responseHash["SyncCategories"] = []
        metadataHash = {}
        doSync = ($rhoconfig[:create_db_seed].to_s == "YES" ? true : false)
        transactionEntities = SyncEntity.loadObject(:all)
        transactionCategoryList = SyncCategory.find(:all).map {|x| x.subCategoryCd.to_s}
        forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
     	
        transactionEntities.each_with_index do |entity, index|
        	tempHash = {}
            category = entity.entitySubCategory
	        entityGuid = entity.object.to_s.gsub(".","_")
            entityHash = {
            	"object" => entity.object,
            	"guid"	=> entityGuid,
	            "entityName" => entity.entityName,
	            "entityType" => entity.entityType,
	            "entitySubCategory" => entity.entitySubCategory,
	            "syncStatus" => nil,
	            "selected" => "NO",
	            "isHidden" => (entity.entityName.to_s == "UserActivity" || entity.entityName.to_s == "SyncActivity" || entity.entityName.to_s == "UserLoginHistory") ? true : false
            }

            #Adding metadata for entity selected attribute for partial sync
            if category.to_s == "MASTER" and doSync
				metadataHash[entityGuid] = {"selected" => {
													"INPUTTYPECD" => "CHECKBOX",
													"LOOKUPCD" => "BOOLEAN",
													"ENABLED" => ($rhoconfig[:app_environment].to_s != "PRODUCTION" ? "YES" : "NO")
												}
									}
			end

	        if responseHash["SyncCategories"].select{|syncEntity| syncEntity["entitySubCategory"] == category}.size == 0
	            object = ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6) + index
	            guid = object.to_s.gsub(".","_")

	            tempHash["entityType"] = entity.entityType 
	            tempHash["entitySubCategory"] = category
	            tempHash["asyncFl"] = (category.to_s == "USERTRANSACTIONS" ? true : false) 
            	tempHash["selected"] = "NO"
            	tempHash["object"] = object
            	tempHash["guid"] = guid
            	tempHash["syncEntities"] = []
            	tempHash["syncStatus"] = nil
            	tempHash["doMasterSync"] = doSync if category.to_s == "MASTER"
            	isEnabled = "YES"

            	responseHash["SyncCategories"] << tempHash
            	if category.to_s == "MASTER"
					if $rhoconfig[:create_db_seed] != "YES"
						enableText = "disabled" if masterSyncEnabled.to_s == "false"
						isEnabled = "NO" if masterSyncEnabled.to_s == "false" && masterSyncDefault.to_s == "ON"
						if masterSyncDefault.to_s == "ON"
							tempHash["selected"] = "YES"
						end
					end
					tempHash["label"] = getLabelValue(category.to_s)
					#Last sync Date
					lastSync = Application.getValue('PRIMARYDATALASTSYNCDATE')
					tempHash["note"] = ""
					tempHash["note"] = getLabelValue('lastSyncDt')+" "+ getScreenDate(Time.load(lastSync.value).to_s) if lastSync
					if masterSyncEnabled.to_s == "true"
						tempHash["note"] = tempHash["note"] + " | " if tempHash["note"] != ""
						tempHash["note"] = tempHash["note"] + getLabelValue('NEWDBAVAILABLE')
					 	if masterSyncDefault.to_s == "ON" && masterDBMandatory.to_s == "true"
					 		d = DateTime.parse(masterDBUpgradeDt.to_s)       
							apiDate = d.strftime('%Q').to_i
					 		tempHash["nextSyncDt"] = apiDate
							tempHash["note"] = tempHash["note"] + " | "+getLabelValue('NEXTMASTERSYNC') +" "+ getScreenDate(masterDBUpgradeDt.to_s)
						end
					elsif masterSyncDefault.to_s == "ON"
						tempHash["note"] = tempHash["note"] + " | " if tempHash["note"] != ""
						tempHash["note"] = tempHash["note"] + getLabelValue('NEWDBAVAILABLE')
					end
				elsif category.to_s == "USERTRANSACTIONS"
					if $rhoconfig[:create_db_seed] != "YES"
						enableText = "disabled" if transactionSyncEnabled.to_s == "false"
						isEnabled = "NO" if transactionSyncEnabled.to_s == "false"
						if transactionSyncDefault.to_s == "ON"
							tempHash["selected"] = "YES"
						end
					end
					tempHash["label"] = getLabelValue(category.to_s)
					if transactionSyncDefault.to_s == "OFF"
						d = DateTime.parse(transactionSyncDt.to_s)       
						apiDate = d.strftime('%Q').to_i
						tempHash["nextSyncDt"] = apiDate
						tempHash["note"] = getLabelValue('NEXTUSERTRANSACTIONSYNC') +" "+getScreenDate(transactionSyncDt.to_s)
					end
				else
					if $rhoconfig[:create_db_seed] != "YES"
						tempHash["selected"] = "YES" if $collateralUpdateMandatory
					end
					tempHash["label"] = getLabelValue(category.to_s)
				end
				
				#To check if sync is mandatory
				tempHash["isEnabled"] = isEnabled
            	#Adding metadata for selected attribute
				metadataHash[guid] = {"selected" => {
														"INPUTTYPECD" => "CHECKBOX",
														"LOOKUPCD" => "BOOLEAN",
														"ENABLED" => isEnabled
													}
									}
	        end
	        responseHash["SyncCategories"].select{|syncEntity| syncEntity["entitySubCategory"] == category}.first["syncEntities"] << entityHash if (entity.entityType.to_s != "MASTER" || (entity.entityType.to_s == "MASTER" && doSync))
		end

		#Add CollateralFile to entities array if Collateral Entities exist
		# collateralEntitySize = responseHash["SyncCategories"].select{|syncCategory| syncCategory["entitySubCategory"].to_s == "COLLATERAL"}.first['syncEntities'].size
		# if collateralEntitySize > 0
		# 	colFileObject = ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6) + collateralEntitySize
		# 	colFileGuid = colFileObject.to_s.gsub(".","_")
        # 	collateralFilesHash = {
        # 		"object" => colFileObject,
        # 		"guid" => colFileGuid,
        # 		"entityName" => "CollateralFiles",
        # 		"entityType" => "TRANSACTION",
        # 		"entitySubCategory" => "COLLATERAL",
        # 		"syncStatus" => nil,
        # 		"selected" => "NO"
        # 	}

        # 	responseHash["SyncCategories"].select{|syncCategory| syncCategory["entitySubCategory"].to_s == "COLLATERAL"}.first['syncEntities'] << collateralFilesHash
        # end

		responseHash["SyncCategories"].sort_by!{|x| transactionCategoryList.index x['entitySubCategory']}
		
		lookupHash =  {"BOOLEAN" => [{"cd"=> "YES","desc" => "Yes"},{"cd"=> "NO","desc" => "No"}] }
		returnHash = {"data" => responseHash,"metadata" => metadataHash,"lookups" => lookupHash }
		returnHash['success'] = true
        returnHash['message'] = "Successful"
        render :string => returnHash.to_json
    end

    def syncSingleEntity
    	GC.enable
        params = parseRequestBodyParams
        type = params["type"]
        subCategory = params["subCategory"]
        returnHash = {}
		has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
		if has_network
			if type == "TRANSACTION" && subCategory == "USERTRANSACTIONS"
				returnHash = syncUserTransaction(params)
			elsif type == "TRANSACTION" && subCategory == "COLLATERAL"
				returnHash = syncCollateral(params)
			elsif type == "MASTER" && subCategory == "MASTER"
				if $rhoconfig[:create_db_seed].to_s == "YES"
					returnHash = syncMasterEntity(params)
				else
					returnHash = ($rhoconfig[:incrementalMasterSyncApproach].to_s != "YES" ? syncMasterDBDownload : syncMasterData(params)) 
				end
			end
		else
			returnHash = {"data" => {"error" => getLabelValue('CHECKNETWORK')}}
			returnHash['success'] = false
			returnHash['message'] = getLabelValue('CHECKNETWORK')
		end
		GC.disable
		render :string => returnHash.to_json
	end
	
	def syncUserTransaction(params)
		GC.enable
		type = params["type"]
        subCategory = params["subCategory"]
		entityName = params["entityName"]
		syncEntity = SyncEntity.loadObject(:first, :conditions => {:entityType => type, :entitySubCategory => subCategory, :entityName=> entityName})
		$syncLogHash = Hash.new
		syncLog = MobiSys::SyncLog.new
		syncLog.entityName = syncEntity.entityName
		syncLog.status = 'Pending'
		syncLog.recordsReceived=0
		syncLog.recordsProcessed=0
		$syncLogHash[syncEntity.entityName] = syncLog
		MobiSys::Sync.Transactions1([syncEntity])
		returnHash = {"data" => {}}
		returnHash["data"][syncLog.entityName] = {}
		returnHash["data"][syncLog.entityName]["entityName"] = syncLog.entityName
		returnHash["data"][syncLog.entityName]["status"] = syncLog.status
		returnHash["data"][syncLog.entityName]["recordsReceived"] = syncLog.recordsReceived
		returnHash["data"][syncLog.entityName]["recordsProcessed"] = syncLog.recordsProcessed
		if syncLog.status.to_s == "Completed"
			returnHash["success"] = true
			returnHash["message"] = "Successful"
		else
			returnHash["success"] = false
			returnHash["message"] = "Unsuccessful"
		end
		GC.disable
		return returnHash
	end

	def syncCollateral(params)
		type = params["type"]
        subCategory = params["subCategory"]
		entityName = params["entityName"]
		returnHash = {"data" => {}}
		$collateralDownloadHash = Hash.new if $collateralDownloadHash == nil
		$syncLogHash = Hash.new
		$collateralSyncLogs = Hash.new
		$collateralSyncFailed = 0
		syncLog = nil
		if entityName == "CollateralFiles"
			syncLog = MobiSys::SyncLog.new
			syncLog.entityName = "CollateralDownload"
			syncLog.status = 'Pending'
			syncLog.recordsReceived=0
			syncLog.recordsProcessed=0
			$syncLogHash["CollateralDownload"] = syncLog
			$collateralSyncLogs["CollateralDownload"] = syncLog
			MobiSys::Sync.collateralFileSyncForApi
			# $collateralDownloadHash = nil
		else
			syncEntity = SyncEntity.loadObject(:first, :conditions => {:entityType => type, :entitySubCategory => subCategory, :entityName=> entityName})
			syncLog = MobiSys::SyncLog.new
			syncLog.entityName = syncEntity.entityName
			syncLog.status = 'Pending'
			syncLog.recordsReceived=0
			syncLog.recordsProcessed=0
			$collateralSyncLogs[syncEntity.entityName] = syncLog
			$syncLogHash[syncEntity.entityName] = syncLog
			MobiSys::Sync.Transactions([syncEntity])
		end
		returnHash["data"][syncLog.entityName] = {}
		returnHash["data"][syncLog.entityName]["entityName"] = syncLog.entityName
		returnHash["data"][syncLog.entityName]["status"] = syncLog.status
		returnHash["data"][syncLog.entityName]["recordsReceived"] = syncLog.recordsReceived
		returnHash["data"][syncLog.entityName]["recordsProcessed"] = syncLog.recordsProcessed

		if syncLog.status.to_s == "Completed"
			returnHash["success"] = true
			returnHash["message"] = "Successful"
		else
			returnHash["success"] = false
			returnHash["message"] = "Unsuccessful"
		end

		return returnHash
	end

	def syncMasterDBDownload
		$syncLogHash = Hash.new
		$masterSyncCompleted = false
		$outputImagesSyncCompleted = false
		$entityContextSyncCompleted = false
		syncLog = MobiSys::SyncLog.new
		syncLog.entityName = "Masters"
		syncLog.status = 'Pending'
		syncLog.recordsReceived=0
		syncLog.recordsProcessed=0
		$syncLogHash["Masters"] = syncLog
		syncLog = MobiSys::SyncLog.new
		syncLog.entityName = "OutputImages"
		syncLog.status = 'Pending'
		syncLog.recordsReceived=0
		syncLog.recordsProcessed=0
		$syncLogHash['OutputImages'] = syncLog
		syncLog = MobiSys::SyncLog.new
		$masterSyncActivity = SyncActivity.createNew('MASTER')
		MobiSys::Sync.masterFileSyncForApi
		MobiSys::Sync.outputImagesSyncForApi
		
		#Update last sync date in the application table - start
		if $masterSyncCompleted and $outputImagesSyncCompleted
			MobiSys::Sync.syncApplicationDate
		else
			$masterSyncActivity.setErrored
		end
		$masterSyncActivity.persist
		returnHash = {"data" => {}}
		totalEntities = $syncLogHash.keys.size
        completedEntities = 0

		$syncLogHash.each do |key,value|
			returnHash["data"][key] = {}
			returnHash["data"][key]["entityName"] = value.entityName
			returnHash["data"][key]["status"] = value.status
			returnHash["data"][key]["recordsReceived"] = value.recordsReceived
			returnHash["data"][key]["recordsProcessed"] = value.recordsProcessed
			completedEntities += 1 if value.status.to_s == "Completed"
		end
		
		if totalEntities != completedEntities
			returnHash["success"] = false
			returnHash["message"] = "Unsuccessful"
		else
			returnHash["success"] = true
			returnHash["message"] = "Successful"
		end

		return returnHash
	end

	def syncMasterEntity(params)
		type = params["type"]
        subCategory = params["subCategory"]
		entityName = params["entityName"]
		isLastEntity = params["lastEntity"]
		isPartialSync = params["isPartialSync"]
		syncEntity = SyncEntity.loadObject(:first, :conditions => {:entityType => type, :entitySubCategory => subCategory, :entityName=> entityName})
		$partialSync = ((isPartialSync != nil && isPartialSync.to_s == "true") ? true : false)
		if $partialSync
			eval("#{syncEntity.entityName}.delete_all()")
			if $childClasses[syncEntity.entityName.to_s]
				$childClasses[syncEntity.entityName.to_s].each do |child|
					eval("#{child}.delete_all()")
				end
			end
		end

		$syncLogHash = Hash.new
        syncLog = MobiSys::SyncLog.new
        syncLog.entityName = syncEntity.entityName
        syncLog.status = 'Pending'
        syncLog.recordsReceived=0
        syncLog.recordsProcessed=0
        $syncLogs.push syncLog
        $syncLogHash[syncEntity.entityName] = syncLog

        MobiSys::Sync.TimedMaster([syncEntity],isLastEntity)
        totalEntities = $syncLogHash.size
        completedEntities = 0

		returnHash = {"data" => {}}
		returnHash["data"][syncLog.entityName] = {}
		returnHash["data"][syncLog.entityName]["entityName"] = syncLog.entityName
		returnHash["data"][syncLog.entityName]["status"] = syncLog.status
		returnHash["data"][syncLog.entityName]["recordsReceived"] = syncLog.recordsReceived
		returnHash["data"][syncLog.entityName]["recordsProcessed"] = syncLog.recordsProcessed
		if syncLog.status.to_s == "Completed"
			returnHash["success"] = true
			returnHash["message"] = "Successful"
		else
			returnHash["success"] = false
			returnHash["message"] = "Unsuccessful"
		end

		return returnHash
	end

	def syncMasterData(params)
        Rho::RHO.load_all_sources()
        currentAgentReg = AgentReg.getCurrentAgentReg
		releaseList = ReleaseManagement.getReleases(currentAgentReg)
		relLkp = Lookupvalue.getValue("RELEASEENTITYCLASSNAME")
		releaseMapping = {}
		skipSync = {}
		syncLogHash = Hash.new
		relLkp.each do |rel|
			releaseMapping[rel.cd] = rel.desc
			skipSync[rel.cd] = true if rel.additionalField1.to_s == "YES"
		end
		if releaseList
			releaseList.each do |release|
				syncLog = MobiSys::SyncLog.new
				syncName = "#{release.releaseCd.to_s}" 
				syncLog.entityName = syncName
				syncLog.status = 'Pending'
				syncLog.recordsReceived=0
				syncLog.recordsProcessed=0
				syncLogHash[syncName] = syncLog
				puts "syncing entity #{release.releaseCd.to_s}"
				syncMasterEntities(release)
				syncDTScripts(release)
				syncLog.status = 'Completed'
				puts "sync complete for #{release.releaseCd.to_s}"
				release.releaseStatusCd = "MOVED"
				release.persist
			end

		end
		totalEntities = syncLogHash.keys.size
        completedEntities = 0

		returnHash = {"data" => {}}
		syncLogHash.each do |key,value|
			returnHash["data"][key] = {}
			returnHash["data"][key]["entityName"] = value.entityName
			returnHash["data"][key]["status"] = value.status
			returnHash["data"][key]["recordsReceived"] = value.recordsReceived
			returnHash["data"][key]["recordsProcessed"] = value.recordsProcessed
			completedEntities += 1 if value.status.to_s == "Completed"
		end
		
		if totalEntities != completedEntities
			returnHash["success"] = false
			returnHash["message"] = "Unsuccessful"
		else
			returnHash["success"] = true
			returnHash["message"] = "Successful"
		end
		return returnHash
	end

	def syncMasterEntities(release)
		clazz = Class.new do
            include MobiSys::BrowserHelper 
        end
        obj = clazz.new
        inputHash = Hash.new
        entityHash = Hash.new
        className = "MASTERSYNC"
        entityHash["id"] = release.id if release.id.to_s != ""
        inputHash[className] = ::JSON.generate(entityHash)
        json = ::JSON.generate(inputHash)
        response = obj.doJSONPost('/OfflineReleaseSync.run', json)
        resultsHash = Rho::JSON.parse(response)
   		offlineClassNameLkp = Lookupvalue.getValue("OFFLINECLASSNAMEMAP")
   		offlineClassNameMap = {}
   		offlineClassNameLkp.each do |lkp|
   			offlineClassNameMap[lkp.desc] = lkp.additionalField2
   		end
        resultsHash.each do |key,value|
            next if value.to_s == '' || value.to_s == '[]' || value.empty?
            ojectList = []
            objGuidList = []
            # objectListMap[key] = ojectList
            entities = Rho::JSON.parse(value)
            count = 0
            count1 = 0
            entityName = offlineClassNameMap[key] 
	        db = ::Rho::RHO.get_src_db(entityName)
	        db.start_transaction
            begin
                entities.each do |mainEntity|
                    next if mainEntity[key].to_s == ''
                    subEntityList = Rho::JSON.parse(mainEntity[key])
                    subEntityList.each do |subEntity|
                    	if entityName.to_s == "CollateralRenderLevel" || entityName.to_s == "Collateral" 
	                    	entityObject = MobiSys::MobiSysEntitySchema.from_hash(entityName,subEntity)
	                    else
	                    	entityObject = MobiSys::MobiSysFixedSchema.from_hash(entityName,subEntity)
	                    end
	                    objGuidList << entityObject.guid
	                    ojectList << entityObject
	                    count1 = count1 + 1
	                end
                end
                #delete existing entities
                dbEntityLst = eval(entityName + ".loadObject(:all, :conditions => {
						                {
						                    :name => 'guid',
						                    :op => 'IN'
						                } => #{objGuidList}
            	})")
				dbEntityLst.each do |dbEntity|
					dbEntity.delete if dbEntity != nil
				end
                ojectList.each do |entityObject|
                    entityObject.persist('fromSync')
                    if entityObject.respond_to?('afterSync'.to_sym)
                        entityObject.afterSync
                    end
                    count = count + 1
                end
                db.commit
            rescue StandardError => se
                db.rollback
                puts "Error while syncing entities #{key}: #{se.to_s}"
                raise se
            end
            puts "@@@@Processed #{count} entites of type " + entityName
        end
	end

	def syncDTScripts(release)
		clazz = Class.new do
            include MobiSys::BrowserHelper 
        end
        obj = clazz.new
        inputHash = Hash.new
        entityHash = Hash.new
        className = ReleaseManagementDtl.onlineClassName

        releaseDtlList = release.getDTReleaseDtl
        releaseDtlList.each do |relDtl|
        	entityHash["guid"] = relDtl.guid if relDtl.guid.to_s != ""
        	inputHash[className] = ::JSON.generate(entityHash)
	        json = ::JSON.generate(inputHash)
	        response = obj.doJSONPost('/OfflineReleaseSync.run', json)
	        resultsHash = Rho::JSON.parse(response)
	        resultsHash.each do |key,value|
	            next if value.to_s == '' || value.to_s == '[]' || value.empty?
	            entities = Rho::JSON.parse(value)
	            entityName = "ReleaseManagementDtl"
            	count = 0
		        db = nil
		        db1 = nil
	            begin
	                entities.each do |mainEntity|
	                    next if mainEntity[key].to_s == ''
	                    subEntityList = Rho::JSON.parse(mainEntity[key])
	                    subEntityList.each do |subEntity|
					        db = ::Rho::RHO.get_src_db(entityName)
					        db.start_transaction
				        	db1 = ::Rho::RHO.get_src_db("ProductDefinitionTable")
							db1.start_transaction
		                    entityObject = MobiSys::MobiSysEntitySchema.from_hash(entityName,subEntity)
		              #       storedEntity = eval(entityName + ".loadObject(:first,:conditions=>{:guid=>'#{entityObject.guid.to_s}'})")
			            	# if storedEntity
                #                 storedEntity.merge(entityObject)
                #                 storedEntity.persist('fromSync')
                #                 if storedEntity.respond_to?('afterSync'.to_sym)
                #                     storedEntity.afterSync
                #                 end
                #             else
                #                 entityObject.persist('fromSync')
                #                 if entityObject.respond_to?('afterSync'.to_sym)
                #                     entityObject.afterSync
                #                 end
                #             end
			                entityObject.ReleaseDTScriptList.each do |relDtScr|
			                    result = db1.execute_batch_sql(relDtScr.dtScript) if relDtScr.dtScript.to_s != ""
								# Rho::Log.error("result :- #{result}", "DT Import")
			                    count = count + 1
			                end
			        		db1.commit
			        		db.commit
		                end
	                end
	            rescue StandardError => se
	                db.rollback
	                db1.rollback if db1
	                puts "Error while syncing entities #{key}: #{se.to_s}"
	                raise se
	            end
	            puts "@@@@Processed #{count} entites of type " + entityName
	        end
        end
	end
	# def exportDt
	# 	tempHash = {"success"=>true}
 #        params = parseRequestBodyParams
 #        pageSize = params["pageSize"]
 #      	pdt = ProductDefinitionTable.loadObject(:all,:per_page => pageSize.to_i)
 #      	fileName = "#{Rho::Application.userFolder}ProductDefinitionTable.json"
	# 	file = File.open(fileName,'w')
	# 	file.puts pdt.to_json
	# 	file.close
	# 	returnHash = {"data" => tempHash}
	# 	returnHash['success'] = true
 #        returnHash['message'] = "Successful"
 #        render :string => returnHash.to_json
	# end


	# def importDT
	# 	logInfo("pdtObjects.class.name")
	# 	tempHash = {"success"=>true}
 #        params = parseRequestBodyParams
 #        fileName = params["fileName"]
 #        t1 = Time.now
 #      	fileName1 = "#{Rho::Application.userFolder}#{fileName}.sql"
	# 	fileContents = File.read("#{fileName1}")
	# 	logInfo("fileContents.length :- #{fileContents.length}")
	# 	begin
	# 		db = Rho::Database.new(Rho::Application.databaseFilePath('master'),'app');
 #            db.start_transaction
	# 		result = db.execute_batch_sql(fileContents)
	# 		Rho::Log.error("result :- #{result}", "DT Import")
 #            db.commit
	# 		db.close()
	# 	rescue Exception => e
	# 		Rho::Log.error("Error occured #{e.backtrace} ", "DT Import")
	# 		db.close()
	# 	end
	# 	# pdtObjects = Rho::JSON.parse(fileContents)
 #        # onlineEntity = MobiSys::MobiSysFixedSchema.from_hash("ProductDefinitionTable",pdtObjects[0])
 #        # pdtObjects.each {|pdt| MobiSys::MobiSysFixedSchema.from_hash("ProductDefinitionTable",pdt).persistAll("fromSync")}
 #        t2 = Time.now
	# 	Rho::Log.error("Total Time for saving DT Records = #{t2-t1}s ", "DT Import")
	# 	logInfo("pdtObjects save complete")
	# 	returnHash = {"data" => tempHash}
	# 	returnHash['success'] = true
 #        returnHash['message'] = "Successful"
 #        render :string => returnHash.to_json
	# end
end
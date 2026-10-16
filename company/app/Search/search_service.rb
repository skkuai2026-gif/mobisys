require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisysuihelper_jazz'
require 'CommonModules/metadata'


module MobiSys
	class SearchService
        extend MobiSys::BrowserHelper
        extend MobiSys::UIHelper
        
        def self.search(params)
            MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache
            # searchData = {}
            searchResultData =[]
            searchCriteriaData = {}
            returnHash = {}
			inputCriteria = {}
			resultActionLabelsArr = []
			resultActionIconsArr = []
            resultActionHrefsArr = []
            lookupList = []
            countHash = nil
            searchName = params["name"]
            requestBody = params["request-body"]
			requestHash = Rho::JSON.parse(requestBody)
			inputCriteria = requestHash["searchCriteriaData"] if requestHash && requestHash["searchCriteriaData"]
		    searchFor = params["searchFor"]
			searchForList = (searchName.to_s == "" && searchFor.to_s != "")
			if Application.getValue('DEFAULTLOCALE')
				@locale = Application.getValue('DEFAULTLOCALE').value
			else
				@locale = 'en'
			end
			#query will come from Search
			if searchForList
				searchList = Search.getSearchByType(searchFor)
				alertStage = params['alertStage'].to_s != "" ? params['alertStage'].to_s : searchList[0].searchName
				tabIds = searchList.collect{ |x| x.searchName.to_s}
				# tabIds = tabIdList.join(',')
				jsFunctions = searchList.collect{ |x| "javascript:setSearchStageAndSubmit('" + x.searchName.to_s + "')"}
				# jsFunctions = jsFunctionList.join(',')
			else
				alertStage = searchName
				tabIds = []
				jsFunctions = []
			end
            search = Search.getSearchByName(alertStage)
            unless search
                return "No Search Found", false
            end
            partition = search.queryPartition.to_s != "" ? search.queryPartition.to_s : "local"
            db = get_db_partition(partition)
			# db = Rho::Database.new(Rho::Application.databaseFilePath(partition),'app');
			if search.resultActions.to_s != ""
				resultActionsMap = search.parseLinksforResultActionstoHM
				resultActionsMap.each do |key, value|
					resultActionLabelsArr << key
					resultActionHrefsArr << value['link']
					resultActionIconsArr << value['icon']
				end
				# resultActionLabels = resultActionLabelsArr.join(',')
				# resultActionHrefs = resultActionHrefsArr.join(',')
				# resultActionIcons = resultActionIconsArr.join(',')
			end
			sql = formSearchQuery(search, inputCriteria)
			searchResultList = db.execute_sql(sql)
			if searchForList
				searchList = Search.getSearchByType(searchFor)
				countHash = {}
				
				searchList.each do |searchMaster|
					sql = formSearchQuery(searchMaster)
					searchResultList1 = db.execute_sql(sql)
					countHash[searchMaster.searchName] = searchResultList1.size
				end
			end
			# db.close()
			currentTab = params['currentTab']
			currentTab = alertStage unless @currentTab

			searchResultFieldList = search.SearchResultFieldList
			searchResultInfo = {}
			positionList = []
			metaDataCdList = []
			linkList = []
			modifyQueryList = []
			modifyFromList = []
			lookupsToBeAdded = []
			inputFieldMapper = {}
			# openUrlLink = ""
			# linkIndex = 0
			counter = 0
            deleteLink = search.deleteLink.to_s 
			searchResultFieldList.sort{|x,y| x.position.to_i<=>y.position.to_i}.each do |searchResultField|
				searchResultFieldHM = {}
				# next if searchResultField.metaDataCd.to_s == ""
				# if searchResultField.submitId.to_s != ""
				# 	searchResultFieldHM["submitId"] = searchResultField.submitId
				# 	# linkRecord = searchResultFieldList.find{ |resultField| resultField.id.to_s == searchResultField.submitId.to_s }
				# 	# openUrlLink = linkRecord.link.to_s
				# 	# linkIndex = counter
				# end
				# metaDataCd = ""
				# metaDataObject = ""
				# if searchResultField.metaDataCd.to_s != "" && searchResultField.metaDataCd.to_s.include?('.')
				# 	metaDataCd = searchResultField.metaDataCd.to_s.split('.').last
				# 	metaDataObject = searchResultField.metaDataCd.to_s.split('.').first
				# end
				# uiMetaDataDOList = $uiMetaDataCache["#{metaDataObject}.#{metaDataCd}".to_sym]
				# # ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, [],"array")
				# # visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))
				# # next unless visibility
				# ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, [],"array")
				# lookup = (ui == nil ? "" : ui.propertyValue.to_s)
				# if(lookup.to_s != "")
				# 	lookupsToBeAdded << "#{metaDataObject}_#{metaDataCd}"
				# end
				# positionList << searchResultField.position
				# metaDataCdList << metaDataCd
				# linkList << searchResultField.link
				
				# counter = counter + 1
				header = nil
				visibility = true
				if(searchResultField.metaDataCd.to_s != "")
        			metaDataClass = searchResultField.metaDataCd.to_s.split('.')[0].to_sym
					if $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(searchResultField.metaDataCd.to_sym)
						uiMetaDataDOList = $uiMetaDataCache[metaDataClass][searchResultField.metaDataCd.to_sym]

						ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList,[])
						label = searchResultField.metaDataCd.split(".").last
						label = (ui == nil ? label : ui.propertyValue.to_s)
						header = getLabelValue(label)
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList,[])
						visibility = (ui == nil ? visibility : (ui.propertyValue.to_s != "NO"))

						ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, [])
						lookup = (ui == nil ? "" : ui.propertyValue.to_s)
						lookupList << lookup if lookup.to_s != ""
						ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, [])
						inputType = (ui == nil ? "" : ui.propertyValue.to_s)

					end
					# header = MetaDataUtil.getInstance().getMetaDataDO(searchResultField.metaDataCd).getUiMetadataPropDO("LABELKEY").getPropertyValue();
					# header = ResourceUtil.getInstance().getLabelValueString(header, userDO.getLanguageCd());
				end
				if searchResultField.resultFieldQuery.to_s != ""
					modifyQueryList << searchResultField.modifyQuery
					modifyFromList << searchResultField.modifyFromPartition ||= "master"
				end
				if searchResultField.metaDataCd.to_s != "" && searchResultField.criteriaFieldQuery.to_s != "" && inputCriteria.has_key?(searchResultField.metaDataCd) && inputCriteria[searchResultField.metaDataCd].to_s != ""
					inputFieldMapper[searchResultField.criteriaFieldQuery] = (inputType.to_s == "DATE" ? Date.parse(inputCriteria[searchResultField.metaDataCd]).strftime('%d/%m/%Y') : inputCriteria[searchResultField.metaDataCd])
				end
				searchResultFieldHM["header"] =  header
				searchResultFieldHM["metadata"] =  searchResultField.metaDataCd if searchResultField.metaDataCd.to_s != ""
				searchResultFieldHM["position"] =  searchResultField.position
				searchResultFieldHM["link"] =  searchResultField.link
				searchResultFieldHM["LOOKUPCD"] =  lookup if lookup.to_s != ""
				searchResultFieldHM["INPUTTYPECD"] =  inputType if inputType.to_s != ""
				searchResultFieldHM["VISIBILITY"] =  "NO" if !visibility
				if searchResultField.submitId.to_s != ""
					searchResultFieldHM["submitId"] =  searchResultField.submitId
				end
				if searchResultField.metaDataCd.to_s == ""
					searchResultFieldHM["isRecordId"] =  true
				end
				searchCriteriaData[searchResultField.metaDataCd.to_s] = inputCriteria.has_key?(searchResultField.metaDataCd) ? inputCriteria[searchResultField.metaDataCd].to_s : nil
				searchResultInfo[searchResultField.id] = searchResultFieldHM
			end

			# get advanced filter search criteria
			staticSearchCriteriaList = search.SearchCriterionList
			staticSearchCriteriaList.sort!{|x,y| x.columnPosition <=> y.columnPosition}
			staticSearchCriteriaList  = staticSearchCriteriaList.select { |item| item[:displayTypeCd] == 'STATIC' }
			searchCriteriaInfoRows = []
			if !staticSearchCriteriaList.empty?
				maxRowValue = 0
				staticSearchCriteriaList.each do |searchCriterionDO|
					if searchCriterionDO.rowPosition.to_s != "" && searchCriterionDO.rowPosition.to_i > maxRowValue
						maxRowValue = searchCriterionDO.rowPosition.to_i
					end
					searchCriteriaData[searchCriterionDO.metaDataCd.to_s] = inputCriteria.has_key?(searchCriterionDO.metaDataCd) ? inputCriteria[searchCriterionDO.metaDataCd].to_s : nil
				end
				searchCriteriaInfoHM = {}
				for i in 1..maxRowValue
					searchCriteriaInfoCols = []
					staticSearchCriteriaList.each do |searchCriterionDO|
						header = nil
						visibility = true
						if(searchCriterionDO.metaDataCd.to_s != "")
		        			metaDataClass = searchCriterionDO.metaDataCd.to_s.split('.')[0].to_sym
							if $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(searchCriterionDO.metaDataCd.to_sym)
								uiMetaDataDOList = $uiMetaDataCache[metaDataClass][searchCriterionDO.metaDataCd.to_sym]

								ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList,[])
								label = searchCriterionDO.metaDataCd.split(".").last
								label = (ui == nil ? label : ui.propertyValue.to_s)
								header = getLabelValue(label)
								ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList,[])
								visibility = (ui == nil ? visibility : (ui.propertyValue.to_s != "NO"))

								ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, [])
								lookup = (ui == nil ? "" : ui.propertyValue.to_s)
								lookupList << lookup if lookup.to_s != ""
								ui = MobiSys::UIMetaData.getUiMetadataPropDO("INPUTTYPECD", uiMetaDataDOList, [])
								inputType = (ui == nil ? "" : ui.propertyValue.to_s)

							end
						end

						searchCriteriaInfoHM["header"] =  header
						searchCriteriaInfoHM["metadata"] =  searchCriterionDO.metaDataCd if searchCriterionDO.metaDataCd.to_s != ""
						searchCriteriaInfoHM["LOOKUPCD"] =  lookup if lookup.to_s != ""
						searchCriteriaInfoHM["INPUTTYPECD"] =  inputType if inputType.to_s != ""
						searchCriteriaInfoHM["VISIBILITY"] =  "NO" if !visibility

						if searchCriterionDO.rowPosition.to_s != "" && i == searchCriterionDO.rowPosition.to_i
							colPosition = searchCriterionDO.columnPosition.to_s != "" ? searchCriterionDO.columnPosition.to_i - 1 : 0
							begin
								searchCriteriaInfoCols[colPosition] = searchCriteriaInfoHM
							rescue Exception => e
								puts "Invalid column postion for metadata #{searchCriterionDO.metaDataCd}"
							end
						end
						searchCriteriaInfoRows << searchCriteriaInfoCols
					end
				end
			end
			# columnList = metaDataCdList.join(',')
			if requestHash["executeSearch"] == true
				searchResultList.each do |searchResult_entry|
					searchFilterPassed = true
					stageFilterPassed = true
					if searchResult_entry 
						
						searchResult_entry.each do|key , value|
							if inputFieldMapper[key].to_s != ""
								searchFilterPassed = false unless value.to_s.downcase.include?(inputFieldMapper[key].downcase)
							end
						end
						
						if searchFilterPassed && stageFilterPassed
							searchData = [] 
							# metaDataCdList.each_with_index do |fieldCd, index|
							index = 0
							searchResult_entry.each do|key , value|
								if modifyQueryList[index]
									begin
										sqlQuery = modifyQueryList[index].gsub('${value}',value.to_s).gsub('${languageCd}',@locale.to_s)
										# dbMaster = Rho::Database.new(Rho::Application.databaseFilePath(modifyFromList[index]),'app');
	            						dbMaster = get_db_partition(modifyFromList[index])
										valueFromDb = dbMaster.execute_sql(sqlQuery)
										# dbMaster.close()
										value = valueFromDb[0].values[0]
									rescue Exception => e
										value = value
									end
								end
								index = index + 1
								searchData << value
							end
							searchResultData << searchData
						end
					end
	            end
	            searchCriteriaData.each do |key, val|
	            	value = val && val == '' ? nil : val
	            	searchCriteriaData[key] = value
	            end
	        end    
            returnHash["searchResultInfo"] = searchResultInfo 
            returnHash["searchResultData"] = searchResultData 
            returnHash["searchCriteriaData"] = searchCriteriaData 
            returnHash["searchCriteriaInfo"] = searchCriteriaInfoRows

            # returnHash["jsFunctions"] = jsFunctions if searchForList
            # returnHash["tabIds"] = tabIds if searchForList
            # returnHash["searchForList"] = searchForList 
            # returnHash["openUrlLink"] = openUrlLink 
            # returnHash["linkIndex"] = linkIndex 
            returnHash["deleteLink"] = deleteLink if deleteLink.to_s != ""
            #returnHash["resultActionLabelsArr"] = resultActionLabelsArr 
            #returnHash["resultActionIconsArr"] = resultActionIconsArr 
            #returnHash["resultActionHrefsArr"] = resultActionHrefsArr 
            # returnHash["currentTab"] = currentTab 
            # returnHash["countHash"] = countHash if countHash
            return returnHash, true,lookupList.uniq
        end


        def self.get_db_partition(partition = "local")
        	db = nil
        	#executing query on appropriate partition. this fix was provided by TAU to execute sql queries on encrypted DB.
    		#The query needs to be executed on any class whose table is present in that partition
        	if partition.to_s != "local"
    			db = ::Rho::RHO.get_src_db("LabelValue")
        	else
        		db = ::Rho::RHO.get_src_db("Application")
        	end
        	return db
        end
    end
end
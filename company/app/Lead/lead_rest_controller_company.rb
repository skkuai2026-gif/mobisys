require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Lead/lead_service'
require 'Quotation/quotation_service'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'TrackLead/track_lead_b_o'
require 'CommonClasses/LeadIO'
require 'CommonModules/entityschema'
require 'CommonModules/mobisysuihelper_jazz'
require 'CommonModules/metadata'
require 'date'


class LeadController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def isInvalid
        invalid = false
        if @baseIO.baseDO != nil && @baseIO.baseDO.statusCd.to_s == "CLOSED"
            invalid = true
        end
        return invalid
    end

    def fetch(id)
        lead = Lead.loadObject(:first, :conditions => {:object => id})
        @baseIO.baseDO = lead
        if lead
            fnaRecordForUpdateObj,quotationRecordForUpdateObj,proposalRecordForUpdateObj = MobiSys::LeadService.findAllEntities(lead)
            @baseIO.baseDO.fnaSeq = fnaRecordForUpdateObj.first if !fnaRecordForUpdateObj.empty?
            @baseIO.baseDO.quotationSeq = quotationRecordForUpdateObj.first if !quotationRecordForUpdateObj.empty?
        end
    end

    def process
    	lead = @baseIO.baseDO
        # Changes related to cascading CR under BAU
        if lead.leadSource && !lead.leadSource.strip.empty?
            fnaRecordForUpdateObj,quotationRecordForUpdateObj,proposalRecordForUpdateObj = MobiSys::LeadService.findAllEntities(lead,true)
        end
        #############################################
        lead.leadId = SequenceNoGenerator.getNextNumber('LEAD') if lead.leadId.to_s == ""
        lead.LeadActivityList.each do |leadActivity|
            leadActivity.activityDt = getDBDateTime(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
            leadActivity.closureDate = getDBDateTime(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""
        end
        # saveModel = @saveModel != nil ? @saveModel : true
        MobiSys::LeadService.saveValidate(lead) if lead.statusCd != "CLOSED"
        newlead = Lead.loadObject(:first,:conditions=>{:object=> lead.object.to_s})
        @baseIO.baseDO = newlead
        fnaRecordForUpdateObj,quotationRecordForUpdateObj,proposalRecordForUpdateObj = MobiSys::LeadService.findAllEntities(lead)
        @baseIO.baseDO.fnaSeq = fnaRecordForUpdateObj.first if !fnaRecordForUpdateObj.empty?
        @baseIO.baseDO.quotationSeq = quotationRecordForUpdateObj.first if !quotationRecordForUpdateObj.empty?
        if newlead.statusCd == "COMPLETED" && newlead.leadSourceOther.to_s == ""
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            if has_network
                begin
                    leadParty = newlead.getLeadParty
                    advisorEmail = leadParty.getPartyEmail.emailAddress if leadParty.getPartyEmail
                    userId = $userId.to_s
                    advisorPhone = leadParty.getPartyContact("PHILIPPINESNUM").contactNum if leadParty.getPartyContact("PHILIPPINESNUM")
                    partyId = newlead.leadId.to_s[0,9]
                    firstName = leadParty.firstName1
                    offlineEntities = Hash.new
                    offlineEntities[newlead.class.name.to_s+ newlead.guid.to_s] = newlead
                    offlineEntities[leadParty.class.name.to_s+ leadParty.guid.to_s] = leadParty
                    syncEntities = Hash.new
                    syncEntities[Lead.onlineClassName] = ::JSON.generate([{Lead.onlineClassName => [newlead.hashForSync]}.to_json])
                    syncEntities[Party.onlineClassName] = ::JSON.generate([{Party.onlineClassName => [leadParty.hashForSync]}.to_json])

                    begin
                        json = ::JSON.generate(syncEntities)
                    rescue StandardError => se
                        puts "Error while generating JSON of request data" + se.to_s
                    end
                    # leadDetailsHash = { emailId: advisorEmail, userId: userId, mobileNumber: advisorPhone, partyId: partyId, firstName: firstName}
                    response = doJSONPost('/leadSendEmailOtp.run', json)
                    if response.to_s != ''
                        resultsHash = Rho::JSON.parse(response)
                    else
                        resultsHash = {}
                    end
                    resultsHash.each do |key,value|
                        if value.to_s != ""
                            entities = Rho::JSON.parse(value)
                        else
                            entities = []
                        end
                        if offlineEntities
                            db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                            db.start_transaction
                            entities.each do |entity|
                                className = entity["class"].slice((entity["class"].rindex('.')+1)..(entity["class"].rindex('DO')-1))
                                offlineEntity = offlineEntities[className+entity['guid']]
                                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
                                if onlineEntity.versionID == -1 and offlineEntity
                                    offlineEntity.destroy
                                elsif offlineEntity
                                    offlineEntity.merge(onlineEntity)
                                    offlineEntity.persist('fromSync')
                                    if offlineEntity.respond_to?('afterSync'.to_sym)
                                        offlineEntity.afterSync
                                    end
                                else
                                    onlineEntity.persist
                                    if onlineEntity.respond_to?('afterSync'.to_sym)
                                        onlineEntity.afterSync
                                    end
                                end
                            end
                            db.commit
                        end
                    end
                    if response.to_s != ""
                        responseHash = Rho::JSON.parse(response.to_s)
                    end

                    # responseHash['success'] = true
                    # responseHash['message'] = "Successful"           
                rescue StandardError => se
                    puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    # responseHash['success'] = false
                    # responseHash['message'] = "Exception in doJSONPost:"
                end
            # else
            #     results="ERR_NETWORK"
            end
            # if results == "ERR_NETWORK"
            #     responseHash['success'] = false
            #     responseHash['message'] = MobiSys::BrowserHelper.getLabel('ERR_NETWORK')
            # end
            # render :string => responseHash.to_json
        end
    end

    def createFNA(id, parseData)
        lead = @baseIO.baseDO
        responseHash = {}
        if lead
            fna = MobiSys::LeadService.newFNA(lead)
            lead.fnaSeq = fna.object
        else
            responseHash = {"success" => false,
                            "message" => "FNA not found."}
        end
        return responseHash
    end

    def deleteLead
        parsedData = parseRequestBodyParams
        responseHash = {"successDeletedLead" => 0, "failedDeletedLead" => 0}
        if @params.has_key?("id")
            fetch(@params["id"])
            lead = @baseIO.baseDO
            if lead
                quotationList = Quotation.find(:all, :conditions => {:leadId => lead.leadId})
                if quotationList.size > 0
                    responseHash = {"success" => false, "message" => getLabelValue('ERR_LEADDELET')}
                else
                    MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
                    lead.delete
                    responseHash = {"success" => true, "message" => MobiSys::CommonUtil.replacePlaceHolders("deletedSuccessfully",["CLIENT"])}
                end
            else
                responseHash["success"] = false
                responseHash["message"] = "Lead not found"
            end
        elsif (parsedData.has_key?("ids") && parsedData['ids'].to_s != "")
                leadIds = parsedData['ids'].split(',')
                if leadIds.size > 0
                    leadIds.each do |id|
                        fetch(id) if id != ""
                        lead = @baseIO.baseDO
                        if lead
                            quotationList = Quotation.find(:all, :conditions => {:leadId => lead.leadId})
                            if quotationList.size > 0
                                failedDeletedLead = failedDeletedLead = responseHash["failedDeletedLead"].to_i 
                                failedDeletedLead += 1
                                responseHash["failedDeletedLead"] = failedDeletedLead
                            else
                                MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
                                lead.delete
                                successDeletedLead = successDeletedLead = responseHash["successDeletedLead"].to_i 
                                successDeletedLead += 1
                                responseHash["successDeletedLead"] = successDeletedLead
                            end
                        end
                    end
                    message = ""
                    if responseHash["successDeletedLead"].to_i > 0
                        message += "Successfully deleted #{responseHash["successDeletedLead"]} lead(s). "
                    end

                    if responseHash["failedDeletedLead"] > 0
                        message += "#{responseHash["failedDeletedLead"]} lead(s) could not be deleted. #{getLabelValue('ERR_LEADDELET')}"
                    end
                    responseHash = {"success" => true, "message" => message}
                end
        else
            responseHash["success"] = false
            responseHash["message"] = "Lead Id is required for deletion."
        end

        render :string => responseHash.to_json
    end

    def LoadAgentNotification
        responseHash = {}
        filteredNotifications = []
        agentNotificationData = AgentNotification.find(:all, :order => 'systemUpdatedDt', :orderdir => 'DESC')
        agentNotificationData.each do |agent|
            if agent.statusCd.to_s != "DELETE" && agent.statusCd.to_s != "DRAFT" && agent.startDt.to_s != "" && agent.endDt.to_s != "" && Date.parse(agent.startDt.to_s) <= Date.parse(Time.now.to_s) && Date.parse(agent.endDt.to_s) >= Date.parse(Time.now.to_s)
                filteredNotifications << agent
            end
        end
        
        latestNotifications =  filteredNotifications[0]

        responseHash["data"] = latestNotifications
        render :string => responseHash.to_json
    end

    def nullIfBlank(value)
        return value.to_s == '' ? '' : value.strip
    end

    def formatBirthDate(value)
      return nil if value.to_s.strip == ""

      if value.is_a?(Date)
        value.strftime('%d/%b/%Y')
      else
        begin
          Date.strptime(value, '%d/%m/%Y').strftime('%d/%b/%Y')
        rescue ArgumentError
          Date.strptime(value, '%d/%b/%Y').strftime('%d/%b/%Y')
        end
      end
    end

    def searchClient
        parsedData = parseRequestBodyParams
        responseHash = {}
        
        MobiSys::UIMetaData.initializeUiMetaDataHash unless $uiMetaDataCache #add
        searchResultList = {}
        searchCriterionFieldHM= {}
        clientList = {}
        searchData = {}
        searchCriteriaData = {} #add
        requestBody = @params["request-body"]
        requestHash = Rho::JSON.parse(requestBody)
        inputCriteria = requestHash["searchCriteriaData"] if requestHash && requestHash["searchCriteriaData"]

        search = Search.getSearchByName('DownloadClientAPI')
        unless search
            return "No Search Found", false
        end

        hmSearchCriteria = nil
        searchResultFieldList = search.SearchResultFieldList
        searchResultInfo = {}
        positionList = []
        metaDataCdList = []
        linkList = []
        modifyQueryList = []
        modifyFromList = []
        lookupsToBeAdded = []
        inputFieldMapper = {}
        counter = 0
        deleteLink = search.deleteLink.to_s 
        searchResultFieldList.sort{|x,y| x.position.to_i<=>y.position.to_i}.each do |searchResultField|
            searchResultFieldHM = {}
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


        staticSearchCriteriaList = search.SearchCriterionList
        staticSearchCriteriaList.sort!{|x,y| x.columnPosition <=> y.columnPosition}
        staticSearchCriteriaList  = staticSearchCriteriaList.select { |item| item.vars[:displayTypeCd] == 'STATIC' }
        searchCriteriaInfoRows = []
        if !staticSearchCriteriaList.empty?
            maxRowValue = 0
            staticSearchCriteriaList.each do |searchCriterionDO|
                if searchCriterionDO.rowPosition.to_s != "" && searchCriterionDO.rowPosition.to_i > maxRowValue
                    maxRowValue = searchCriterionDO.rowPosition.to_i
                end
                searchCriteriaData[searchCriterionDO.metaDataCd.to_s] = inputCriteria.has_key?(searchCriterionDO.metaDataCd) ? inputCriteria[searchCriterionDO.metaDataCd].to_s : nil
            end
            # searchCriteriaInfoHM = {} # put this hashmap inside for loop to get unique search critria fields
            for i in 1..maxRowValue
                searchCriteriaInfoCols = []
                staticSearchCriteriaList.each do |searchCriterionDO|
                    searchCriteriaInfoHM = {}
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
                            ui = MobiSys::UIMetaData.getUiMetadataPropDO("PLACEHOLDER", uiMetaDataDOList, [])
                            placeholder = (ui == nil ? "" : ui.propertyValue.to_s)
                            ui = MobiSys::UIMetaData.getUiMetadataPropDO("MAXLENGTH", uiMetaDataDOList, [])
                            maxlength = (ui == nil ? "" : ui.propertyValue.to_s)
                            ui = MobiSys::UIMetaData.getUiMetadataPropDO("WIDTH", uiMetaDataDOList, [])
                            width = (ui == nil ? "" : ui.propertyValue.to_s)

                        end
                    end

                    searchCriteriaInfoHM["header"] =  header
                    searchCriteriaInfoHM["metadata"] =  searchCriterionDO.metaDataCd if searchCriterionDO.metaDataCd.to_s != ""
                    searchCriteriaInfoHM["LOOKUPCD"] =  lookup if lookup.to_s != ""
                    searchCriteriaInfoHM["INPUTTYPECD"] =  inputType if inputType.to_s != ""
                    searchCriteriaInfoHM["VISIBILITY"] =  "NO" if !visibility
                    searchCriteriaInfoHM["PLACEHOLDER"] =  placeholder if placeholder.to_s != ""
                    searchCriteriaInfoHM["MAXLENGTH"] =  maxlength if maxlength.to_s != ""
                    searchCriteriaInfoHM["WIDTH"] =  width if width.to_s != ""

                    if searchCriterionDO.rowPosition.to_s != "" && i == searchCriterionDO.rowPosition.to_i
                        colPosition = searchCriterionDO.columnPosition.to_s != "" ? searchCriterionDO.columnPosition.to_i - 1 : 0
                        begin
                            searchCriteriaInfoCols[colPosition] = searchCriteriaInfoHM
                        rescue Exception => e
                            puts "Invalid column postion for metadata #{searchCriterionDO.metaDataCd}"
                        end
                    end
                    # searchCriteriaInfoRows << searchCriteriaInfoCols # put this array push logic outside for loop to stop overriding previous search criteria
                end
                searchCriteriaInfoRows << searchCriteriaInfoCols
            end
        end

        isValid = false
        message = nil
        if requestHash["executeSearch"] == true
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection 
            if has_network
                syncEntities = Hash.new
                currentAgentReg = AgentReg.getCurrentAgentReg

                syncEntities["USERID"] =  ::JSON.generate([{"USERID" => [currentAgentReg.agentId.to_s]}.to_json]) if currentAgentReg && currentAgentReg.agentId.to_s != ""

                syncEntities['SearchLeadDO.firstNameLead'] = ::JSON.generate([{'SearchLeadDO.firstNameLead' => [nullIfBlank(inputCriteria['SearchLeadDO.firstNameLead'].downcase)] }.to_json]) if inputCriteria['SearchLeadDO.firstNameLead'].to_s != ""

                syncEntities['SearchLeadDO.middleNameLead'] = ::JSON.generate([{'SearchLeadDO.middleNameLead' => [nullIfBlank(inputCriteria['SearchLeadDO.middleNameLead'].downcase)] }.to_json]) if inputCriteria['SearchLeadDO.middleNameLead'].to_s != ""

                syncEntities['SearchLeadDO.lastNameLead'] = ::JSON.generate([{'SearchLeadDO.lastNameLead' => [nullIfBlank(inputCriteria['SearchLeadDO.lastNameLead'].downcase)] }.to_json]) if inputCriteria['SearchLeadDO.lastNameLead'].to_s != ""

                syncEntities['SearchLeadDO.policyNumLead'] = ::JSON.generate([{'SearchLeadDO.policyNumLead' => [nullIfBlank(inputCriteria['SearchLeadDO.policyNumLead'])] }.to_json]) if inputCriteria['SearchLeadDO.policyNumLead'].to_s != ""

                if inputCriteria['SearchLeadDO.birthDtLead'].to_s != ""
                    birthdate = formatBirthDate(inputCriteria['SearchLeadDO.birthDtLead'])
                    if birthdate
                        syncEntities['SearchLeadDO.birthDtLead'] = ::JSON.generate([{'SearchLeadDO.birthDtLead' => [birthdate] }.to_json])  
                    end
                end

                resultsHash = {}
                begin
                    json = ::JSON.generate(syncEntities)
                    response = doJSONPost('/searchClientController.run', json)
                    if response.to_s != ''
                        resultsHash = Rho::JSON.parse(response)
                        isValid= true
                        message="Successful"
                    else
                        isValid = false
                        message = getLabelValue('ERR_SEARCHNODATAFOUND')
                    end

                rescue StandardError => se
                    puts "Error while generating entities hash for sync =>" + se.to_s
                    isValid = false
                    message = getLabelValue('SERVERERROR')
                end
            else
                isValid = false
                message = getLabelValue('ERR_NETWORK')
            end
        end

        if resultsHash && !resultsHash.empty?
            resultsHash['searchResultData'].each do |row|
                leadBusinessId = row[6]
                row[5] = getRecordExists(leadBusinessId)
            end
            searchData = resultsHash
        end
        searchData['searchResultInfo'] = searchResultInfo
        searchData['searchCriteriaData'] = searchCriteriaData
        searchData['searchCriteriaInfo'] = searchCriteriaInfoRows
        responseHash = {"data" => searchData}
        responseHash['success'] = isValid
        responseHash['message'] = message

        render :string => responseHash.to_json
    end

    def downloadClientAction

        requestBody = @params["request-body"]
        requestHash = Rho::JSON.parse(requestBody)
        responseHash = {}
        inputCriteria = requestHash["selectedIds"] if requestHash && requestHash["selectedIds"]

        isValid = false
        message = nil
        
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            syncEntities = Hash.new

            if !inputCriteria.empty?
                syncEntities['selectedIds'] = (inputCriteria.map { |v| nullIfBlank(v) })
            end

            resultsHash = {}
                begin
                    json = ::JSON.generate(syncEntities)
                    response = doJSONPost('/downloadClientActionController.run', json)
                    if response.to_s != ''
                        resultsHash = Rho::JSON.parse(response)
                        resultsHash.each do |key,value|
                            next if value.to_s == '' || value.to_s == '[]' || value.empty?
                            begin
                                db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
                                db.start_transaction
                                    value.each do |entity|
                                        next if entity.to_s == ''
                                        if entity["class"]
                                           className = entity["class"].slice((entity["class"].rindex('.')+1)..(entity["class"].rindex('DO')-1))
                                        else
                                           className = key 
                                        end    
                                        exp = className + ".loadObject(:first,:conditions=>{:guid=>'" + entity['guid'].to_s + "'})"
                                        storedEntity = eval(exp)
                                        entityObject = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
                                        if storedEntity and entityObject.versionID == '-1'
                                            storedEntity.delete
                                        elsif storedEntity
                                            storedEntity.merge(entityObject)
                                            storedEntity.persist
                                        else
                                            entityObject.persist
                                        end
                                    end
                                db.commit
                                isValid= true
                                message="Successful"
                            rescue StandardError => se
                                db.rollback
                                RhoLog.error('Error while syncing entities: ', se.to_s)
                                isValid= false
                                message=getLabelValue('SERVERERROR')
                            end
                        end
                    else
                        isValid = false
                        message = getLabelValue('ERR_SEARCHNODATAFOUND')
                    end

                rescue StandardError => se
                    puts "Error while generating entities hash for sync =>" + se.to_s
                    isValid = false
                    message = getLabelValue('SERVERERROR')
                end

        else
            isValid = false
            message = getLabelValue('IMPORT_FAILED')
        end

        responseHash['success'] = isValid
        responseHash['message'] = message

        render :string => responseHash.to_json
    end

    def getRecordExists(leadBusinessId)

        sql= "select * from Lead where leadSourceOther = '#{leadBusinessId.to_s}' "
        lead = Lead.find_by_sql(sql)

        return lead.length > 0 ?  "YES" : "NO"
    end

end

begin 
    require 'Lead/lead_controller_company'
rescue LoadError => e
    puts 'lead_controller_company not included'
end
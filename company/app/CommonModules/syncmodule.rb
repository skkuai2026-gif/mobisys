require 'json'
require 'date'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/schema_module'
require 'CommonModules/syncutil'
require 'CommonModules/entityschema'

module MobiSys

    class SyncLog
        attr_accessor :entityName
        attr_accessor :status
        attr_accessor :recordsProcessed
        attr_accessor :recordsReceived
    end  
  
    class Sync
        def self.refreshUI
            if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                percentage = 0
                total = $syncLogs.length
                processed = 0
                recordsProcessed = 0
                recordsReceived = 0
                entityName = ""

                $syncLogs.each do |syncLog|
                    processed = processed + 1 if syncLog.status == "Completed" or syncLog.status == 'In process'
                    percentage = (syncLog.recordsProcessed.to_f/syncLog.recordsReceived) * 100 if syncLog.status == 'In process' and syncLog.recordsProcessed != 'NA'
                    if syncLog.status == 'In process' and syncLog.recordsProcessed != 'NA'
                        recordsProcessed = syncLog.recordsProcessed
                        recordsReceived = syncLog.recordsReceived
                        entityName = syncLog.entityName
                    end
                end
                WebView.execute_js("update_progress('#{percentage}','#{processed}','#{total}','#{entityName}','#{recordsProcessed}','#{recordsReceived}')")
            end
        end

        def self.refreshDownloadUI
            if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                percentage = 0
                total = $collateralSyncLogs.length
                processed = 0
                recordsProcessed = 0
                recordsReceived = 0
                entityName = ""

                $collateralSyncLogs.each do |syncLog|
                    processed = processed + 1 if syncLog.status == "Completed" or syncLog.status == 'In process'
                    percentage = (syncLog.recordsProcessed.to_f/syncLog.recordsReceived) * 100 if syncLog.status == 'In process' and syncLog.recordsProcessed != 'NA'
                    if syncLog.status == 'In process' and syncLog.recordsProcessed != 'NA'
                        recordsProcessed = syncLog.recordsProcessed
                        recordsReceived = syncLog.recordsReceived
                        entityName = syncLog.entityName
                    end
                end
                WebView.execute_js("collateralFileDownload('#{percentage}','#{processed}','#{total}','#{entityName}','#{recordsProcessed}','#{recordsReceived}')")
            end
        end

        #New sync code to split transactions according to page.
        def self.Transactions1(*args)
            log("Starting transactions sync")
            if args and args.size > 0
                syncEntities = args[0]
            else  
                #Load the SyncEntity master to find out all entities to be synced
                syncEntities = SyncEntity.loadObject(:all, :conditions=>{:enabled=>'YES'})
            end
            log "Found #{syncEntities.length} entities to be synced." if syncEntities
            syncEntityHash = Hash.new
            inputHash = Hash.new
      
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            showSuccessAlert = false
            syncEntities.each_with_index do |syncEntity, i|
                showSuccessAlert = false
                next if syncEntity.entityName != nil && syncEntity.entityName == "EmailQuotation"
                syncLog = $syncLogHash[syncEntity.entityName]
                syncLog.status = 'In process'
                refreshUI
                #exp = syncEntity.entityName + '.respond_to?(:entitiesForSync)'
                #result = syncEntity.entityName.respond_to?(:entitiesForSync)
                result = Object.const_get(syncEntity.entityName).respond_to?(:entitiesForSync)
                #log(exp)  
                #result = eval(exp)
                entitiesForSync = nil
                #Find lastSyncDate for entity
                lastSyncDate = Time.at(0)
                lastSyncDateAppObject = Application.getValue(syncEntity.entityName + "_" + $userId + '_lastSyncDate')
                if lastSyncDateAppObject
                    lastSyncDate = Time.load(lastSyncDateAppObject.value)
                end
                if result
                    log "Calling entitiesForSync on class"
                    entitiesForSync = eval(syncEntity.entityName + '.entitiesForSync')
                    log "Received #{entitiesForSync.size} objects of type #{syncEntity.entityName}"
                else
                    fetchQuery = syncEntity.entityName + ".loadObject(:all)"
                    allEntitiesForSync = eval(fetchQuery)  
                    entitiesForSync = []
                    allEntitiesForSync.each do |each_entity|
                        if Time.parse(each_entity.systemUpdatedDt) > Time.parse(lastSyncDate.to_s)
                            entitiesForSync.push each_entity
                        end
                    end
                end
                log "Found #{entitiesForSync.size} entities of type #{syncEntity.entityName} for sync"
                log "Page size for sync is #{$rhoconfig[:syncpagesize]}"
        
                if entitiesForSync.size > 0
                    while entitiesForSync.size > 0
                        page = entitiesForSync.slice!(0,$rhoconfig[:syncpagesize].to_i)
                        entities(page,false)
                    end #while clone.size > 0 end  
                end #if entitiesForSync end
                #All local entities which were modified are merged now.
                #Call controller for getting add deleted entities 
                next if syncEntity.entityName == "UserActivity" or syncEntity.entityName == "SyncActivity" or syncEntity.entityName == "UserLoginHistory"
                inputHash = Hash.new
                exp = syncEntity.entityName + ".onlineClassName"
                className = eval(exp)
                inputHash[className] = lastSyncDate.strftime("%Y-%m-%d %H:%M:%S.%L %z")
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/ModifiedEntities.run', json)
                resultsHash = Rho::JSON.parse(response)
                resultsHash.each do |key,value|
                    next if value.to_s == '' || value.to_s == '[]' || value.empty?
                    # log "Key: " + key.to_s
                    # log "Value: " + value.to_s
                    entities = Rho::JSON.parse(value)
                    syncLog.recordsReceived = entities.length
                    
                    count = 0
                    syncLog.recordsProcessed = count
                    log("Before refreshUI")
                    refreshUI
                    db = ::Rho::RHO.get_src_db(syncEntity.entityName)
                    db.start_transaction
                    begin
                        entities.each do |mainEntity|
                            next if mainEntity[key].to_s == ''
                            subEntity = Rho::JSON.parse(mainEntity[key])[0]
                            if key == Policy.onlineClassName
                                inputHash1 = Hash.new
                                inputHash1[className] = subEntity['id'].to_s
                                json = ::JSON.generate(inputHash1)
                                response = obj.doJSONPost('/downloadEntity.run', json)
                                next if response.to_s == ""
                                mainEntity = Rho::JSON.parse(response)
                                policyEntity = Rho::JSON.parse(mainEntity[key])[0]
                                # log("Before loadObject: " + entity.to_s)
                                exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + policyEntity['guid'].to_s + "'})"
                                # log(exp)  
                                storedEntity = eval(exp)
                                # log(syncEntity.entityName)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,policyEntity)
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
                                if mainEntity[ServiceDocument.onlineClassName].to_s != ''
                                    serviceDocumentEntities = Rho::JSON.parse(mainEntity[ServiceDocument.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceDocumentEntities size : #{serviceDocumentEntities.size}"
                                    partiesGuid = []
                                    if serviceDocumentEntities.size > 0
                                        validServiceDocumentGuids = serviceDocumentEntities.map { |e| e['guid'] }.to_set
                                        partiesGuid = serviceDocumentEntities.collect{|x| x['partyGuid']}.uniq
                                        partiesGuid.each do |partyGuid|
                                            documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'entityGuid' => partyGuid, 'policyGuid' => policyEntity['guid']})
                                            unless documentContainer
                                                documentContainer = DocumentContainer.new
                                                documentContainer.entityGuid = partyGuid
                                                documentContainer.entityTypeCd = 'Party'
                                                documentContainer.policyGuid = policyEntity['guid']
                                            end 
                                            serviceDocumentEntities.each do |serviceDocumentEntity|  
                                                if serviceDocumentEntity['partyGuid'] == partyGuid
                                                    serviceDocument = MobiSys::MobiSysEntitySchema.from_hash('ServiceDocument',serviceDocumentEntity)
                                                    dbServiceDocumentEntity = nil
                                                    documentContainer.ServiceDocumentList.each do |serviceDocumentOfflineEntity|
                                                        if serviceDocumentOfflineEntity.guid == serviceDocument.guid
                                                            dbServiceDocumentEntity = serviceDocumentOfflineEntity
                                                        else
                                                            # mark removed if not in validServiceDocumentGuids
                                                            serviceDocumentOfflineEntity.removed = validServiceDocumentGuids.include?(serviceDocumentOfflineEntity.guid) ? nil : "YES"
                                                        end
                                                    end
                                                    if  dbServiceDocumentEntity != nil
                                                        dbServiceDocumentEntity.merge(serviceDocument)
                                                        if dbServiceDocumentEntity.respond_to?('afterSync'.to_sym)
                                                            dbServiceDocumentEntity.afterSync
                                                        end
                                                    else
                                                        documentContainer.addServiceDocument(serviceDocument)
                                                        if serviceDocument.respond_to?('afterSync'.to_sym)
                                                            serviceDocument.afterSync
                                                        end
                                                    end
                                                end
                                            end 
                                            documentContainer.persistAll('fromSync')
                                        end
                                    else
                                        documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                                        documentContainer&.ServiceDocumentList&.each do |serviceDocumentOfflineEntity|
                                            serviceDocumentOfflineEntity.removed = "YES"
                                        end
                                        documentContainer&.persistAll('fromSync')
                                    end
                                end

                                if mainEntity[Image.onlineClassName].to_s != ''
                                    imageEntities = Rho::JSON.parse(mainEntity[Image.onlineClassName])
                                    if imageEntities.size > 0
                                        documentContainers = DocumentContainer.find(
                                            :all,
                                            :conditions => {
                                                'policyGuid' => policyEntity['guid']
                                            }
                                        )
                                        documentContainers.each do |documentContainer|
                                            serviceDocuments = documentContainer.ServiceDocumentList
                                            serviceDocuments.each do |serviceDocumentOfflineEntity|
                                                Image.delete_all(
                                                    :conditions => {
                                                        'parentRefGuid' => serviceDocumentOfflineEntity.guid
                                                    }
                                                )
                                                serviceDocumentOfflineEntity.imageCount = nil
                                                serviceDocumentOfflineEntity.persistAll('fromSync')
                                            end
                                        end
                                        imageEntities.each do |imageEntity|
                                            imageOfflineEntity = Image.loadObject(:first, :conditions=>{'guid' => imageEntity['guid']})
                                            image = MobiSys::MobiSysEntitySchema.from_hash('Image',imageEntity)
                                            if imageOfflineEntity.to_s != "" && imageOfflineEntity.guid == image.guid
                                                imageOfflineEntity.merge(image)
                                                if imageOfflineEntity.respond_to?('afterSync'.to_sym)
                                                    imageOfflineEntity.afterSync
                                                end
                                                imageOfflineEntity&.persistAll('fromSync')
                                            else
                                                image.persistAll('fromSync')
                                                serviceDocument = ServiceDocument.loadObject(:first,:conditions=>{'guid' => imageEntity['parentRefGuid']})
                                                # serviceDocument.selected = "YES"
                                                if serviceDocument.imageCount.to_s == ""
                                                    serviceDocument.imageCount =  1
                                                else
                                                    serviceDocument.imageCount =  serviceDocument.imageCount + 1
                                                end
                                                serviceDocument.persistAll
                                                if image.respond_to?('afterSync'.to_sym)
                                                    image.afterSync
                                                end
                                            end
                                        end                                        
                                    else
                                        documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                                        documentContainer&.ServiceDocumentList&.each do |serviceDocumentOfflineEntity|
                                            # serviceDocumentOfflineEntity&.removed = "YES"
                                            Image.delete_all(
                                                :conditions => {
                                                    {:name=>'parentRefGuid'} => serviceDocumentOfflineEntity.guid
                                                },
                                                :op => 'AND'
                                            )
                                        end
                                        # documentContainer&.persistAll('fromSync')
                                    end
                                end

                                if mainEntity[ServiceQuestionResponse.onlineClassName].to_s != ''
                                    serviceQuestionResponseEntities =  Rho::JSON.parse(mainEntity[ServiceQuestionResponse.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceQuestionResponseEntities size : #{serviceQuestionResponseEntities.size}"
                                    partiesGuid = []
                                    if serviceQuestionResponseEntities.size > 0
                                        validQuestionResponseGuids = serviceQuestionResponseEntities.map { |e| e['guid'] }.to_set
                                        partiesGuid = serviceQuestionResponseEntities.collect{|x| x['partyGuid']}.uniq
                                        partiesGuid.each do |partyGuid|
                                            if partyGuid.to_s == ""
                                                questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid'],'entityGuid' => policyEntity['guid']},:op => "AND" )
                                            else
                                                questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'entityGuid' => partyGuid, 'policyGuid' => policyEntity['guid']})
                                            end
                                            unless questionContainer
                                                questionContainer = QuestionContainer.new 
                                                if partyGuid
                                                    questionContainer.entityGuid = partyGuid   
                                                    questionContainer.entityTypeCd = entityObject.getPartyByGuid(partyGuid).roleCd
                                                else
                                                    questionContainer.entityGuid = policyEntity['guid']
                                                    questionContainer.entityTypeCd = "AGENT"
                                                end                                 
                                                questionContainer.policyGuid = policyEntity['guid']
                                            end 
                                            serviceQuestionResponseEntities.each do |serviceQuestionResponseEntity| 
                                                if (serviceQuestionResponseEntity['partyGuid'].to_s == partyGuid.to_s) || (questionContainer.entityTypeCd.to_s == "AGENT" && serviceQuestionResponseEntity['partyGuid'].to_s == "")
                                                    serviceQuestionResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceQuestionResponse',serviceQuestionResponseEntity)
                                                    dbserviceQuestionResponseEntity = nil
                                                    questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponseOfflineEntity|
                                                        if serviceQuestionResponseOfflineEntity.guid == serviceQuestionResponse.guid
                                                            dbserviceQuestionResponseEntity = serviceQuestionResponseOfflineEntity
                                                        else
                                                            # mark removed if not in validQuestionResponseGuids
                                                            serviceQuestionResponseOfflineEntity.removed = validQuestionResponseGuids.include?(serviceQuestionResponseOfflineEntity.guid) ? nil : "YES"
                                                        end
                                                    end
                                                    if  dbserviceQuestionResponseEntity != nil
                                                        dbserviceQuestionResponseEntity.merge(serviceQuestionResponse)
                                                        if dbserviceQuestionResponseEntity.respond_to?('afterSync'.to_sym)
                                                            dbserviceQuestionResponseEntity.afterSync
                                                        end
                                                    else
                                                        questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
                                                        if serviceQuestionResponse.respond_to?('afterSync'.to_sym)
                                                            serviceQuestionResponse.afterSync
                                                        end
                                                    end
                                                end
                                            end 
                                            questionContainer.persistAll('fromSync')
                                        end
                                    else
                                        questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                                        questionContainer&.ServiceQuestionResponseList&.each do |serviceQuestionResponseOfflineEntity|
                                            serviceQuestionResponseOfflineEntity.removed = "YES"
                                        end
                                        questionContainer&.persistAll('fromSync')
                                    end
                                end

                                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceSignatureEntities size : #{serviceSignatureEntities.size}"
                                    if serviceSignatureEntities.size > 0
                                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                                        serviceSignatureEntities.each do |serviceSignatureEntity|
                                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => policyEntity['guid']})
                                            unless signatureContainer
                                                signatureContainer = SignatureContainer.new
                                                signatureContainer.entityTypeCd = 'Policy'                                    
                                                signatureContainer.entityGuid = policyEntity['guid']
                                            end 
                                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                                            dbServiceSignatureEntity = nil
                                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                                else
                                                    # mark removed if not in validServiceSignatureGuids
                                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                                end
                                            end
                                            if  dbServiceSignatureEntity != nil
                                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                                if dbServiceSignatureEntity.respond_to?('afterSync'.to_sym)
                                                    dbServiceSignatureEntity.afterSync
                                                end
                                            else
                                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            end
                                            signatureContainer.persistAll('fromSync')
                                        end
                                    else
                                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => policyEntity['guid']})
                                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                                            serviceSignatureOfflineEntity.removed = "YES"
                                        end
                                        signatureContainer&.persistAll('fromSync')
                                    end
                                end

                                if mainEntity[Inward.onlineClassName].to_s != ''
                                    inwardEntities = Rho::JSON.parse(mainEntity[Inward.onlineClassName])
                                    if inwardEntities.size > 0
                                        puts "Transaction ModifiedEntities inwardEntities size : #{inwardEntities.size}"
                                        inwardEntities.each do |inwardEntity|
                                            inwardEntity = MobiSys::MobiSysEntitySchema.from_hash('Inward',inwardEntity)
                                            if storedEntity
                                                inwardOfflineEntity = storedEntity.getInward(policyEntity['proposalNum'], "APPLICATION_SUSPENSE") 
                                                if inwardOfflineEntity.to_s != "" && inwardOfflineEntity.guid == inwardEntity.guid
                                                    inwardOfflineEntity.merge(inwardEntity)
                                                    inwardOfflineEntity.persist('fromSync')
                                                    if inwardOfflineEntity.respond_to?('afterSync'.to_sym)
                                                       inwardOfflineEntity.afterSync
                                                    end 
                                                else
                                                    inwardEntity.persistAll 
                                                    if inwardEntity.respond_to?('afterSync'.to_sym)
                                                       inwardEntity.afterSync
                                                    end 
                                                end
                                            else
                                                inwardEntity.persistAll 
                                                if inwardEntity.respond_to?('afterSync'.to_sym)
                                                    inwardEntity.afterSync
                                                end 
                                            end
                                        end
                                    end
                                end
                                MobiSys::CommonUtil.clearTaskExceptionList(entityObject.guid)
                                if  mainEntity[TaskException.onlineClassName].to_s != ''
                                    taskExceptionEntities = Rho::JSON.parse(mainEntity[TaskException.onlineClassName])
                                    if taskExceptionEntities.size > 0
                                        puts "Transaction ModifiedEntities taskExceptionEntities size : #{taskExceptionEntities.size}"
                                        taskExceptionEntities.each do |taskException|
                                            exception = MobiSys::MobiSysEntitySchema.from_hash('TaskException', taskException) 
                                            exception.entitySeq = entityObject.guid
                                            exception.persistAll('fromSync') 
                                        end  
                                    end
                                end



                            elsif key == Quotation.onlineClassName
                                quotationEntity = subEntity
                                # log("Before loadObject: " + entity.to_s)
                                exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + quotationEntity['guid'].to_s + "'})"
                                # log(exp)  
                                storedEntity = eval(exp)
                                # log(syncEntity.entityName)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,quotationEntity)
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
                                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceSignatureEntities for quotation size : #{serviceSignatureEntities.size}"
                                    if serviceSignatureEntities.size > 0
                                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                                        serviceSignatureEntities.each do |serviceSignatureEntity|
                                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => quotationEntity['guid']})
                                            unless signatureContainer
                                                signatureContainer = SignatureContainer.new
                                                signatureContainer.entityTypeCd = 'Quotation'                                    
                                                signatureContainer.entityGuid = quotationEntity['guid']
                                            end 
                                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                                            dbServiceSignatureEntity = nil
                                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                                else
                                                    # mark removed if not in validServiceSignatureGuids
                                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                                end
                                            end
                                            if  dbServiceSignatureEntity != nil
                                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            else
                                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            end
                                            signatureContainer.persistAll('fromSync')
                                        end
                                    else
                                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => quotationEntity['guid']})
                                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                                            serviceSignatureOfflineEntity.removed = "YES"
                                        end
                                        signatureContainer&.persistAll('fromSync')
                                    end
                                end
                            elsif key == Lead.onlineClassName
                                leadEntity = subEntity
                                # log("Before loadObject: " + entity.to_s)
                                exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + leadEntity['guid'].to_s + "'})"
                                # log(exp)  
                                storedEntity = eval(exp)
                                # log(syncEntity.entityName)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,leadEntity)
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
                                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceSignatureEntities for Lead size : #{serviceSignatureEntities.size}"
                                    if serviceSignatureEntities.size > 0
                                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                                        serviceSignatureEntities.each do |serviceSignatureEntity|
                                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => leadEntity['guid']})
                                            unless signatureContainer
                                                signatureContainer = SignatureContainer.new
                                                signatureContainer.entityTypeCd = 'Lead'                                    
                                                signatureContainer.entityGuid = leadEntity['guid']
                                            end 
                                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                                            dbServiceSignatureEntity = nil
                                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                                else
                                                    # mark removed if not in validServiceSignatureGuids
                                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                                end
                                            end
                                            if  dbServiceSignatureEntity != nil
                                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            else
                                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            end
                                            signatureContainer.persistAll('fromSync')
                                        end
                                    else
                                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => leadEntity['guid']})
                                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                                            serviceSignatureOfflineEntity.removed = "YES"
                                        end
                                        signatureContainer&.persistAll('fromSync')
                                    end
                                end
                            elsif key == FNARequest.onlineClassName
                                fnaRequestEntity = subEntity
                                # log("Before loadObject: " + entity.to_s)
                                exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + fnaRequestEntity['guid'].to_s + "'})"
                                # log(exp)  
                                storedEntity = eval(exp)
                                # log(syncEntity.entityName)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,fnaRequestEntity)
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
                                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                                    puts " Transaction ModifiedEntities serviceSignatureEntities for quotation size : #{serviceSignatureEntities.size}"
                                    if serviceSignatureEntities.size > 0
                                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                                        serviceSignatureEntities.each do |serviceSignatureEntity|
                                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => fnaRequestEntity['guid']})
                                            unless signatureContainer
                                                signatureContainer = SignatureContainer.new
                                                signatureContainer.entityTypeCd = 'FNARequest'                                    
                                                signatureContainer.entityGuid = fnaRequestEntity['guid']
                                            end 
                                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                                            dbServiceSignatureEntity = nil
                                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                                else
                                                    # mark removed if not in validServiceSignatureGuids
                                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                                end
                                            end
                                            if  dbServiceSignatureEntity != nil
                                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            else
                                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                                    serviceSignatureEntityResponse.afterSync
                                                end
                                            end
                                            signatureContainer.persistAll('fromSync')
                                        end
                                    end
                                else
                                    signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => fnaRequestEntity['guid']})
                                    signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                                        serviceSignatureOfflineEntity.removed = "YES"
                                    end
                                    signatureContainer&.persistAll('fromSync')
                                end
                            else
                                # log("Before loadObject: " + entity.to_s)
                                exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + subEntity['guid'].to_s + "'})"
                                # log(exp)  
                                storedEntity = eval(exp)
                                # log(syncEntity.entityName)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,subEntity)
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
                            count = count + 1
                            syncLog.recordsProcessed = count
                            refreshUI
                        end
                        db.commit
                    rescue StandardError => se
                        db.rollback
                        # if showMessages
                        #     Alert.show_popup({
                        #         :title=>'',
                        #         :message=>se.to_s, 
                        #         :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                        #     })
                        # else
                            log('Error while syncing entities: ' + se.to_s)
                            raise se
                        # end
                    end
                    log "@@@@Processed #{count} entites of type " + syncEntity.entityName
                end
                syncLog.status='Completed'
                refreshUI
                showSuccessAlert = true
                #Call controller for getting add deleted entities end
                #Store tne lastSyncDate for the entity
                puts "after:#{lastSyncDateAppObject}"
                if lastSyncDateAppObject
                    Application.updateValue(syncEntity.entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                else
                    Application.create(syncEntity.entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                end     
                #Store tne lastSyncDate for the entity
            end #syncEntities.each ends
            if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                if showSuccessAlert
                    $transactionSyncCompleted = true
                    Alert.show_popup({
                        :title=> '',
                        :message=> MobiSys::BrowserHelper.getLabel("SUCCESS"),
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                    })  
                end
            end
            #User previous data to be deleted
            MobiSys::SyncUtil.deleteUserData
        end
        #New sync code to split transactions according to page ends.
            
        #Synchronises transactions
        def self.Transactions(*args)
            # log("Starting transactions sync")
            if args and args.size > 0
                syncEntities = args[0]
            else  
                #Load the SyncEntity master to find out all entities to be synced
                syncEntities = SyncEntity.loadObject(:all, :conditions=>{:enabled=>'YES'})
            end
            # puts "Found #{syncEntities.length} entities to be synced." if syncEntities
            syncEntityHash = Hash.new
            inputHash = Hash.new
            if $rhoconfig[:syncapproach]=='NEW'
                #New sync approach - start
                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new
                showSuccessAlert = false
                syncEntities.each do |syncEntity|
                    showSuccessAlert = false
                    # log("Starting sync for #{syncEntity.entityName}")
                    syncLog = $syncLogHash[syncEntity.entityName]
                    syncLog.status = 'In process'
                    refreshUI
                    inputHash = Hash.new
                    exp = syncEntity.entityName + ".onlineClassName"
                    className = eval(exp)
                    syncEntityHash[className] = syncEntity.entityName
                    exp = syncEntity.entityName + ".loadObject(:all)"
                    entities = eval(exp)
                    array = Array.new
                    lastSyncDate = Time.at(0)
                    lastSyncDateAppObject = Application.getValue(syncEntity.entityName + "_" + $userId + '_lastSyncDate')
                    if lastSyncDateAppObject
                        lastSyncDate = Time.load(lastSyncDateAppObject.value)
                    end
                    entities.each do |entity|
                        entity.beforeSync if entity.respond_to?('beforeSync'.to_sym)
                        array.push entity.hashForSync
                    end
                    begin
                        inputHash[className] = ::JSON.generate(array)
                    rescue StandardError => se
                        puts "Error while generating entities hash for sync =>" + se.to_s
                    end
                    #Now sync    
                    begin
                        json = ::JSON.generate(inputHash)
                    rescue StandardError => se
                        puts "Error while generating JSON of request data =>" + se.to_s
                    end
                    response = obj.doJSONPost('/SyncEntities.run', json)
                    resultsHash = Rho::JSON.parse(response)
                    resultsHash.each do |key,value|
                        entities = Rho::JSON.parse(value)
                        syncLog.recordsReceived = entities.length
                        count = 0
                        syncLog.recordsProcessed = count
                        refreshUI
                        className = syncEntityHash[key]
                        if ["Level0","Level1","Level2","Level3","Level4","CollateralRenderLevel"].include?(className.to_s) && entities.length > 0
                            exp = className + ".delete_all()"
                            eval(exp)
                        end
                        db = ::Rho::RHO.get_src_db(className)
                        db.start_transaction
                        begin
                            entities.each do |entity|
                                exp = className + ".loadObject(:first,:conditions=>{:guid=>'" + entity['guid'].to_s + "'})"
                                storedEntity = eval(exp)
                                entityObject = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
                                if storedEntity and entityObject.versionID == '-1'
                                    storedEntity.delete
                                elsif storedEntity
                                    storedEntity.merge(entityObject)
                                    if storedEntity.respond_to?('afterSync'.to_sym)
                                        storedEntity.afterSync
                                    end
                                    storedEntity.persist('fromSync')
                                else
                                    if entityObject.respond_to?('afterSync'.to_sym)
                                        entityObject.afterSync
                                    end
                                    entityObject.persist('fromSync')
                                end
                                count = count + 1
                                syncLog.recordsProcessed = count
                                refreshUI
                            end
                            db.commit
                        rescue StandardError => se
                            db.rollback
                            if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                                if showMessages
                                    Alert.show_popup({
                                        :title=>'',
                                        :message=>se.to_s, 
                                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                                    })
                                else
                                    log('Error while syncing entities: ' + se.to_s)
                                    raise se
                                end
                            else
                                log('Error while syncing entities: ' + se.to_s)
                                raise se
                            end
                        end
                        log "@@@@Processed #{count} entites of type " + syncEntity.entityName
                    end
                    syncLog.status = 'Completed'
                    if syncEntity.entityName != "Collateral"
                        if lastSyncDateAppObject 
                            Application.updateValue(syncEntity.entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                        else
                            Application.create(syncEntity.entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                        end   
                    end
                    refreshUI
                    showSuccessAlert = true unless syncEntity.entitySubCategory == 'COLLATERAL'
                end #syncEntitites.each ends 
                if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                    if showSuccessAlert
                        Alert.show_popup({
                            :title=>'',
                            :message=>MobiSys::BrowserHelper.getLabel("SUCCESS"),
                            :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                        })  
                    end
                end
                #New sync approach - end
            else
            #Old sync approach - start
            syncEntities.each do |syncEntity|
                syncLog = $syncLogHash[syncEntity.entityName]
                syncLog.status = 'In process'
                exp = syncEntity.entityName + ".onlineClassName"
                className = eval(exp)
                syncEntityHash[className] = syncEntity.entityName
                exp = syncEntity.entityName + ".loadObject(:all)"
                entities = eval(exp)
                array = Array.new
                entities.each do |entity|
                    array.push entity.hashForSync
                end
                inputHash[className] = ::JSON.generate(array)   
                end
                #Data collected now. Create JSON
                json = ::JSON.generate(inputHash)     
                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new
                response = obj.doJSONPost('/SyncEntities.run', json)
                resultsHash = Rho::JSON.parse(response)
                # puts resultsHash
                resultsHash.each do |key,value|
                    # puts "Key: " + key.to_s
                    # puts "Value: " + value.to_s
                    entities = Rho::JSON.parse(value)
                    className = syncEntityHash[key]
                    syncLog = $syncLogHash[className]
                    syncLog.recordsReceived = entities.length
                    count = 0
                    entities.each do |entity|
                        puts "Entity class: " + entity.class.name.to_s
                        exp = className + ".loadObject(:first,:conditions=>{:guid=>'" + entity['guid'].to_s + "'})"
                        puts exp
                        storedEntity = eval(exp)
                        entityObject = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
                        if storedEntity and entityObject.versionID == '-1'
                            storedEntity.delete
                        elsif storedEntity
                            storedEntity.merge(entityObject)
                            storedEntity.persist('fromSync')
                            if storedEntity.respond_to?('afterSync'.to_sym)
                                storedEntity.afterSync
                            end
                        else
                            entityObject.persist
                            if entityObject.respond_to?('afterSync'.to_sym)
                                entityObject.afterSync
                            end
                        end
                        count = count + 1
                        syncLog.recordsProcessed = count
                    end
                    syncLog.status='Completed'  
                end
                #Old sync approach end
            end  
        end    
        #Synchronize transactions ends
    
        #Single Transactions
        def self.SingleTransactions(*args)
            log("Starting single transactions sync")
            if args and args.size > 0
                syncEntities = args[0]
            else  
                #Load the SyncEntity master to find out all entities to be synced
                syncEntities = SyncEntity.loadObject(:all, :conditions=>{:enabled=>'YES'})
            end
            puts "Found #{syncEntities.length} entities to be synced." if syncEntities
            syncEntityHash = Hash.new
            inputHash = Hash.new
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            syncEntities.each do |syncEntity|
                #log("Starting sync for #{syncEntity.entityName}")
                next if syncEntity.entityName != nil && syncEntity.entityName == "EmailQuotation"
                syncLog = $syncLogHash[syncEntity.entityName]
                syncLog.status = 'In process'
                refreshUI
                inputHash = Hash.new
                exp = syncEntity.entityName + ".onlineClassName"
                className = eval(exp)
                syncEntityHash[className] = syncEntity.entityName
                exp = syncEntity.entityName + ".loadObject(:all)"
                entities = eval(exp)
                array = Array.new
                # sync each entity
                syncLog.recordsReceived = entities.length
                begin
                    entities.each_with_index do |entity, index|
                        entityArray = Array.new          
                        entityArray.push entity
                        entities(entityArray, false)            
                        syncLog.recordsProcessed = index
                        refreshUI
                    end
                rescue StandardError => se
                    puts "Error while generating entities hash for sync =>" + se.to_s
                end
                # now sync empty array and fetch everything
                begin
                    inputHash[className] = ::JSON.generate(array)
                rescue StandardError => se
                    log "Error while syncing individual entities =>" + se.to_s
                end
                #Now sync          
                begin
                    json = ::JSON.generate(inputHash)
                rescue StandardError => se
                    puts "Error while generating JSON of request data =>" + se.to_s
                end
        
                response = obj.doJSONPost('/SyncEntities.run', json)
                resultsHash = Rho::JSON.parse(response)
                resultsHash.each do |key,value|
                    entities = Rho::JSON.parse(value)
                    syncLog.recordsReceived = entities.length
                    count = 0;
                    syncLog.recordsProcessed = count
                    refreshUI
                    className = syncEntityHash[key]
                    entities.each do |entity|
                        exp = className + ".loadObject(:first,:conditions=>{:guid=>'" + entity['guid'].to_s + "'})"
                        storedEntity = eval(exp)
                        entityObject = MobiSys::MobiSysEntitySchema.from_hash(className,entity)
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
                        count = count + 1 unless syncEntity.entityName == 'Collateral'
                        syncLog.recordsProcessed = count
                        refreshUI
                    end
                    log "@@@@Processed #{count} entites of type " + syncEntity.entityName
                end
                syncLog.status='Completed' unless syncEntity.entityName == 'Collateral'
                refreshUI   
            end #syncEntitites.each ends 
        end    
        #Synchronize Single Transactions ends

        #Synchronise masters
        def self.Masters(syncEntities)
            puts "Found #{syncEntities.length} masters to be synced."
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            if $rhoconfig[:syncapproach]=='NEW'
                #This approach involves calling sync for each entity
                syncEntities.each do |syncEntity|
                    puts "###Processing entity " + syncEntity.entityName
                    inputHash = Hash.new
                    syncEntityHash = Hash.new
                    exp = syncEntity.entityName + ".onlineClassName"
                    className = eval(exp)
                    onlineClassName = syncEntity.entityName
                    exp = syncEntity.entityName + ".loadObject(:all)"
                    entities = eval(exp)
                    offlineHash = Hash.new
                    entities.each do |entity|
                        syncEntityHash[entity.guid] = entity.versionID
                        offlineHash[entity.guid] = entity
                    end
                    inputHash[className] = syncEntityHash
                    #Now sync
                    json = ::JSON.generate(inputHash)
                    response = obj.doJSONPost('/SyncMasters.run', json)
                    resultsHash = Rho::JSON.parse(response)
                    resultsHash.each do |key,value|
                        onlineEntities = Rho::JSON.parse(value)
                        puts "@@@@Received #{onlineEntities.length} entities of type " + syncEntity.entityName
                        count = 0;
                        puts "Crossed count"
                        className = syncEntityHash[key]
                        onlineEntities.each do |entity|
                            onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(syncEntity.entityName,entity)
                            offlineEntity = offlineHash[onlineEntity.guid]
                            if offlineEntity and onlineEntity.versionID.to_i > 0
                                #Offline entity exists. Online entity is modified. Merge and save
                                offlineEntity.merge(onlineEntity)
                                offlineEntity.persist('fromSync')
                                offlineEntity.afterSync if offlineEntity.respond_to?('afterSync'.to_sym)
                            elsif offlineEntity and onlineEntity.versionID.to_i == -1
                                #Online entity has been deleted. Delete the offline entity
                                offlineEntity.destroy
                            elsif not offlineEntity and onlineEntity.versionID.to_i > 0
                                #Entity does not exist offline. save it.
                                onlineEntity.persist
                                onlineEntity.afterSync if onlineEntity.respond_to?('afterSync'.to_sym)
                            end
                            count = count + 1    
                        end
                        puts "@@@@Processed #{count} entites of type " + syncEntity.entityName    
                    end
                end #syncEntities loop ends    
            else
                #Old approach code starts
                inputHash = Hash.new
                offlineEntityHash = Hash.new
                offlineClassNamesHash = Hash.new
                #Iterate through all sync entities, load respective offline entitites and prepare inputHash and offlineEntityHash
                syncEntities.each do |syncEntity|
                    exp = syncEntity.entityName + ".onlineClassName"
                    onlineClassName = eval(exp)
                    offlineClassName = syncEntity.entityName
                    offlineClassNamesHash[onlineClassName] = offlineClassName
                    exp = offlineClassName + ".loadObject(:all)"
                    offlineEntities = eval(exp)
                    offlineEntitiesHash = Hash.new
                    syncEntityHash = Hash.new
                    offlineEntities.each do |offlineEntity|
                        offlineEntitiesHash[offlineEntity.guid] = offlineEntity
                        syncEntityHash[offlineEntity.guid] = offlineEntity.versionID
                    end #offlineEntities.each ends

                    #Put the offlineEntitiesHash in offlineEntityHash
                    offlineEntityHash[onlineClassName] = offlineEntitiesHash

                    #Put the syncEntityHash in inputHash
                    inputHash[onlineClassName] = syncEntityHash
                
                end #syncEntitites.each ends
                #Now sync
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/SyncMasters.run', json)
                
                #process results
                resultsHash = Rho::JSON.parse(response)
                resultsHash.each do |key,value|
                    onlineEntities = Rho::JSON.parse(value)
                    offlineClassName = offlineClassNamesHash[key]
                    puts "@@@@Received #{onlineEntities.length} entities of type " + offlineClassName

                    offlineEntities = offlineEntityHash[key]
                    count = 0;
                    onlineEntities.each do |entity|
                        onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(offlineClassName,entity)
                        offlineEntity = offlineEntities[onlineEntity.guid]
                        if offlineEntity and onlineEntity.versionID.to_i > 0
                            #Offline entity exists. Online entity is modified. Merge and save
                            offlineEntity.merge(onlineEntity)
                            offlineEntity.persist('fromSync')
                            offlineEntity.afterSync if offlineEntity.respond_to?('afterSync'.to_sym)
                        elsif offlineEntity and onlineEntity.versionID.to_i == -1
                            #Online entity has been deleted. Delete the offline entity
                            offlineEntity.destroy
                        elsif not offlineEntity and onlineEntity.versionID.to_i > 0
                            #Entity does not exist offline. save it.
                            onlineEntity.persist
                            onlineEntity.afterSync if onlineEntity.respond_to?('afterSync'.to_sym)
                        end
                        count = count + 1    
                    end
                    puts "@@@@Processed #{count} entites of type " + offlineClassName    
                end
                #Old approach code ends
            end
            path_to_zip_file = Rhom::Rhom.database_export('master')
            puts '>>>Path to zip file: ' + path_to_zip_file    

            #Update last sync date in the application table - start
            primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
            if primarySyncDateAppObject == nil
                Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
            else
                Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))  
            end
            #Update last sync date in the application table - end
        end
        #Synchronise masters end
    
        #Synchronize all start
        def self.All(syncEntities)
            GC.enable
            System.set_sleeping(false)
            log('Inside sync.All')
            $masterSyncCompleted = false
            $outputImagesSyncCompleted = false
            $entityContextSyncCompleted = false
            $transactionSyncCompleted = false
            $syncRunning = true
            $collateralSyncFailed = 0
            $collateralDownloadHash = {}
            masters = Array.new
            transactions = Array.new
            products = Array.new
            collateral = Array.new
            syncEntities.each do |syncEntity|
                if syncEntity.entityType == "TRANSACTION"
                    if syncEntity.entitySubCategory == "COLLATERAL"
                        collateral.push syncEntity
                    else
                        transactions.push syncEntity
                    end  
                elsif syncEntity.entityType == "MASTER"   
                  masters.push syncEntity
                end
            end

            log('Segregated entities')

            $syncLogs = Array.new
            $syncLogHash = Hash.new
            $collateralSyncLogs = Array.new
            masters.each do |syncEntity|
                syncLog = MobiSys::SyncLog.new
                syncLog.entityName = syncEntity.entityName
                syncLog.status = 'Pending'
                syncLog.recordsReceived=0
                syncLog.recordsProcessed=0
                $syncLogs.push syncLog
                $syncLogHash[syncEntity.entityName] = syncLog
            end
            log('Created master sync logs')
            transactions.each do |syncEntity|
                next if syncEntity.entityName != nil && syncEntity.entityName == "EmailQuotation"
                syncLog = MobiSys::SyncLog.new
                syncLog.entityName = syncEntity.entityName
                syncLog.status = 'Pending'
                syncLog.recordsReceived=0
                syncLog.recordsProcessed=0
                $syncLogs.push syncLog
                $syncLogHash[syncEntity.entityName] = syncLog
            end

            collateral.each do |syncEntity|
                syncLog = MobiSys::SyncLog.new
                syncLog.entityName = syncEntity.entityName
                syncLog.status = 'Pending'
                syncLog.recordsReceived=0
                syncLog.recordsProcessed=0
                $syncLogs.push syncLog
                $syncLogHash[syncEntity.entityName] = syncLog
            end  

            if collateral.size > 0
                syncLog = MobiSys::SyncLog.new
                syncLog.entityName = 'CollateralDownload'
                syncLog.status = 'Pending'
                syncLog.recordsReceived = 0
                syncLog.recordsProcessed = 0
                $collateralSyncLogs.push syncLog 
                $syncLogHash['CollateralDownload'] = syncLog
            end

            if $rhoconfig[:create_db_seed] == 'YES'
                products.each do |syncEntity|
                    syncLog = MobiSys::SyncLog.new
                    syncLog.entityName = syncEntity.entityName
                    syncLog.status = 'Pending'
                    syncLog.recordsReceived=0
                    syncLog.recordsProcessed=0
                    $syncLogs.push syncLog
                    $syncLogHash[syncEntity.entityName] = syncLog
                end  
            else
                if masters.length > 0
                    syncLog = MobiSys::SyncLog.new
                    syncLog.entityName = 'Masters'
                    syncLog.status = 'Pending'
                    syncLog.recordsReceived='NA'
                    syncLog.recordsProcessed='NA'
                    $syncLogs.push syncLog
                    $syncLogHash['Masters'] = syncLog

                    syncLog = MobiSys::SyncLog.new
                    syncLog.entityName = 'OutputImages'
                    syncLog.status = 'Pending'
                    syncLog.recordsReceived='NA'
                    syncLog.recordsProcessed='NA'
                    $syncLogs.push syncLog
                    $syncLogHash['OutputImages'] = syncLog    
                      
                    syncLog = MobiSys::SyncLog.new
                    syncLog.entityName = 'EntityContext'
                    syncLog.status = 'Pending'
                    syncLog.recordsReceived='NA'
                    syncLog.recordsProcessed='NA'
                    $syncLogs.push syncLog
                    $syncLogHash['EntityContext'] = syncLog           
                end
            end    

            sleep(3)
            log('Created transaction sync logs')
            #Masters(masters)
            #TimedMaster(masters) if masters.length > 0
            if masters.length > 0
                if $rhoconfig[:create_db_seed] == 'YES'
                    TimedMaster(masters)
                else
                    $masterSyncActivity = SyncActivity.createNew('MASTER')
                    masterFileSync
                    outputImagesSync
                    entityContextFileSync
                 
                    #Update last sync date in the application table - start
                    if $masterSyncCompleted and $outputImagesSyncCompleted
                        syncApplicationDate
                    else
                        $masterSyncActivity.setErrored
                    end
                    $masterSyncActivity.persist

                    #Update last sync date in the application table - end
                    $showSync = false
                    $dbUpdateMandatory = false
                    refreshUI
                end
            else
                $masterSyncCompleted = true
                $outputImagesSyncCompleted = true
                $entityContextSyncCompleted = true
            end  
            log('Master sync completed')
            transactionSyncActivity = SyncActivity.createNew("TRANSCATIONS")
            begin
                if transactions.length > 0
                    Transactions1(transactions) #if transactions.length > 0
                    AgentReg.updateLastSyncDate #if transactions.length > 0
                else
                    $transactionSyncCompleted = true
                end
                transactionSyncActivity.setSuccess
            rescue MobiSys::AuthenticationError => se
                log('Authentication exception while transaction sync')
                transactionSyncActivity.statusCd = 'ERROR'
                #Do nothing. System is already on login screen
                Alert.show_popup({:title=>'Error',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'})  
            rescue MobiSys::UpgradeApplicationError => ue
                transactionSyncActivity.setErrored
                Alert.show_popup({:title=>'',:message=>ue.to_s, 
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'})    
            rescue StandardError => se
                log('Exception occured while syncing transactions.' + se.to_s)
                transactionSyncActivity.setErrored
                Alert.show_popup({:title=>'',
                  :message=>MobiSys::BrowserHelper.getLabel('TRANSACTIONSYNCFAILEDMESSAGE'),
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'})
            end
            transactionSyncActivity.persist  if transactions.length > 0
            log('transaction sync completed')

            log("Starting collateral sync")
            begin
                if collateral.length > 0
                    pendingCollaterals = Collateral.find(:all,:conditions=>{'colStatus'=>'PENDING'})
                    pendingCollaterals.each do |pendingCollateral|
                        pendingCollateral.destroy
                    end
                    checkCollateralVersion(false)
                    Transactions(collateral)
                    collateralFileSync
                    lastCollateralSyncDate = Application.getValue("Collateral_" + $userId + '_lastSyncDate')
                    if lastCollateralSyncDate
                        Application.updateValue("Collateral_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                    else
                        Application.create("Collateral_" + $userId + '_lastSyncDate',Time.dump(Time.now))
                    end
                end  
                if collateral.length > 0 and $collateralDownloadHash.empty?
                    lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
                    if lastCollateralSyncDate
                        Application.updateValue('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                    else
                        Application.create('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                    end
                end
            rescue MobiSys::AuthenticationError => se
                log('Authentication exception while collateral sync')
                #Do nothing. System is already on login screen
                 Alert.show_popup({:title=>'Error',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'}) 
            rescue MobiSys::UpgradeApplicationError => ue
                Alert.show_popup({:title=>'',:message=>ue.to_s, 
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'})    
            rescue StandardError => se
                log('Exception occured while Collateral sync' + se.to_s)
                Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('COLLATERALSYNCFAILEDMESSAGE'),
                  :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                  :callback=>'/app/SyncCategory/transactionpopupcallback'})
            end
            log("Collateral sync completed")
            System.set_sleeping(true)
            GC.disable
            if transactions
                return transactions.length
            else  
                return 0
            end
        end  
        #Synchronize all end

        def self.syncApplicationDate
            $masterSyncActivity.setSuccess
            primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
            if primarySyncDateAppObject == nil
                Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
            else
                Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
            end
        end
    
        #TimedMaster start
        def self.TimedMaster(syncEntities,isLastEntity=false)
            Rho::RHO.load_all_sources
            puts "Found #{syncEntities.length} masters to be synced."
            if syncEntities.length == 0
                return
            end  
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            db = ::Rho::RHO.get_src_db('ProductFamily')
            log(db.to_s)
            isLastEntity = true if((Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='1' and isLastEntity.to_s == "true"))
            
            if $rhoconfig[:syncapproach]=='NEW'
                #NEW sync approach starts
                log(syncEntities.to_s)
                syncEntities.each do |syncEntity|
                    syncLog = $syncLogHash[syncEntity.entityName]
                    syncLog.status = 'In process'
                    refreshUI
                    exp = syncEntity.entityName + ".onlineClassName"
                    onlineClassName = eval(exp)
                    inputHash = Hash.new
                    log("After getting online classname #{onlineClassName}")
                    #exp = "require_source '" + syncEntity.entityName + "'"
                    #log(exp)
                    #eval(exp)
                    sql = 'select max(systemUpdatedDt) as systemUpdatedDt from ' + syncEntity.entityName
                    #products = ProductFiltering.find_by_sql(@sql)
                    exp = syncEntity.entityName + '.find_by_sql(sql)'
                    results = eval(exp)
                    results.each do |result|
                        inputHash[onlineClassName] = result.systemUpdatedDt
                    end

                    if nil == inputHash[onlineClassName]
                        inputHash[onlineClassName] = Time.at(0)
                    end

                    json = ::JSON.generate(inputHash)
                    response = obj.doJSONPost('/SyncTimedMasters.run', json)
                    response = ::JSON.generate(response)
                    response.gsub!("&sing;", "'")
                    response.gsub!("listSearchCriteriaDOList", "listSearchCriterionDOList")
                    #process results
                    resultsHash = Rho::JSON.parse(response)
                    resultsHash.each do |key,onlineEntities|
                        # value.gsub!("&sing;", "'")
                        # onlineEntities = Rho::JSON.parse(value)
                        offlineClassName = syncEntity.entityName
                        syncLog.recordsReceived = onlineEntities.length
                        count = 0;
                        syncLog.recordsProcessed = count
                        refreshUI
                        db = ::Rho::RHO.get_src_db(offlineClassName)
                        db.start_transaction
                        begin
                            onlineEntities.each do |hash|
                                # hash = Rho::JSON.parse(entity)
                                onlineEntity = MobiSys::MobiSysFixedSchema.from_hash(offlineClassName,hash)
                                offlineEntity = Object.const_get(syncEntity.entityName).loadObject(:first,:conditions=>{:guid=> hash['guid'].to_s })
                                if offlineEntity
                                    #Offline entity exists. Online entity is modified. Merge and save
                                    offlineEntity.merge(onlineEntity)
                                    offlineEntity.persist('fromSync')
                                    offlineEntity.afterSync if offlineEntity.respond_to?('afterSync'.to_sym)
                                else
                                    #Entity does not exist offline. save it.
                                    onlineEntity.persist('fromSync')
                                    onlineEntity.afterSync if onlineEntity.respond_to?('afterSync'.to_sym)
                                end
                                count = count + 1
                                puts Thread.current.inspect + "@@@@Processed #{count}/#{onlineEntities.length} " + syncEntity.entityName
                                syncLog.recordsProcessed = count
                                refreshUI
                            end
                            db.commit
                        rescue
                            db.rollback
                            Alert.show_popup({
                                :title=>'',
                                :message=>MobiSys::BrowserHelper.getLabel('MASTERSYNCFAILEDMESSAGE'),
                                :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                                :callback=>'/app/SyncCategory/transactionpopupcallback'
                            })
                            puts "sync failed for "+offlineClassName.to_s
                        end

                        puts "@@@@Processed #{count} entites of type " + offlineClassName
                        refreshUI
                    end#resultsHash.each loop ends
                    syncLog.status='Completed'
                    refreshUI  
                end #syncEntities.each ends 
                #NEW sync approach ends
            else
                #OLD sync approach starts
                inputHash = Hash.new
                offlineClassNameHash = Hash.new
                syncEntities.each do |syncEntity|
                    syncLog = $syncLogHash[syncEntity.entityName]
                    syncLog.status = 'In process'
                    exp = syncEntity.entityName + ".onlineClassName"
                    onlineClassName = eval(exp)
                    offlineClassNameHash[onlineClassName] = syncEntity.entityName
                    sql = 'select max(systemUpdatedDt) as systemUpdatedDt from ' + syncEntity.entityName
                    products = ProductFiltering.find_by_sql(@sql)
                    exp = syncEntity.entityName + '.find_by_sql(sql)'
                    results = eval(exp)
                    results.each do |result|
                        inputHash[onlineClassName] = result.systemUpdatedDt
                    end
                end #syncEntities.each ends
                json = ::JSON.generate(inputHash)
                puts "json submitted to server -> #{json}"
                response = obj.doJSONPost('/SyncTimedMasters.run', json)
                #process results
                resultsHash = Rho::JSON.parse(response)
                resultsHash.each do |key,value|
                    onlineEntities = Rho::JSON.parse(value)
                    offlineClassName = offlineClassNameHash[key]
                    syncLog = $syncLogHash[offlineClassName]
                    puts "@@@@Received #{onlineEntities.length} entities of type " + offlineClassName
                    count = 0;
                    syncLog.recordsReceived = onlineEntities.length
                    syncLog.recordsProcessed = count
                    onlineEntities.each do |entity|
                        onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(offlineClassName,entity)
                        exp = syncEntity.entityName + ".loadObject(:first,:conditions=>{:guid=>'" + entity['guid'].to_s + "'})"
                        offlineEntity = eval(exp)
                        if offlineEntity
                            #Offline entity exists. Online entity is modified. Merge and save
                            offlineEntity.merge(onlineEntity)
                            offlineEntity.persist('fromSync')
                            offlineEntity.afterSync if offlineEntity.respond_to?('afterSync'.to_sym)
                        else
                            #Entity does not exist offline. save it.
                            onlineEntity.persist('fromSync')
                            onlineEntity.afterSync if onlineEntity.respond_to?('afterSync'.to_sym)
                        end
                        count = count + 1
                        puts "@@@@Processed #{count}/#{onlineEntities.length} " + syncEntity.entityName
                        syncLog.recordsProcessed = count    
                    end
                    puts "@@@@Processed #{count} entites of type " + offlineClassName
                    syncLog.status='Completed'
                end#resultsHash.each loop ends
                #OLD sync approach ends
            end

            if $rhoconfig[:create_db_seed] == 'YES' &&  (!defined?($partialSync) || (defined?($partialSync) && $partialSync == false)) && isLastEntity.to_s == "true"
                #path_to_zip_file = Rhom::Rhom.database_export('master')
                originalFile = File.join(Rho::RhoApplication.get_blob_folder, "..")
                originalFile = File.join(originalFile, "syncdbmaster.sqlite")
                path_to_zip_file = File.join(Rho::RhoApplication.get_blob_folder, "..")
                path_to_zip_file = File.join(path_to_zip_file, "syncdbmastercopy.sqlite")
                FileUtils::copy_file(originalFile, path_to_zip_file, false, false)
                puts '>>>Path to zip file: ' + path_to_zip_file
                #Master db upload code start
                puts ">>>before upload"
                url = Application.getValue('online_server_url').value + "/SyncProductDTDB.run"
                begin
                    Rho::AsyncHttp.upload_file(
                      :url => url,
                      :filename => path_to_zip_file,
                      :body => "", #=> leave blank, AsyncHttp will fill in multipart body
                      #:headers => {"Content-Type"=>"text/plain"}, #=> used as body text content type
                      :headers => {"username"=>$userId,"password"=>$userPassword},
                      :callback => '/app/SyncEntity/masterFileUploadCallback',
                      :callback_param => "fileName=#{path_to_zip_file}",
                      :ssl_verify_peer => $ssl_verify_peer)
                    puts ">>>upload done"
                rescue Exception => e
                    puts ">>>exception in upload file: #{e}"
                end
                #Master db upload code end
            end      
               
            #Update last sync date in the application table - start
            primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
            if primarySyncDateAppObject == nil
                Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
            else
                Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
            end
            #Update last sync date in the application table - end    
        end  
        #TimedMaster end
    
        #entitites start
        def self.entities(entitiesToBeSynced, showMessages)
            log "Starting sync for #{entitiesToBeSynced.length} entities"
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            offlineEntitiesHash = Hash.new
            inputHash = Hash.new
            entitiesToBeSynced.each do |offlineEntity|
                className = offlineEntity.class.name.to_s
                exp = className + ".onlineClassName"
                onlineClassName = eval(exp)
                currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
                unless currentEntityTypeHash
                    offlineEntitiesHash[onlineClassName] = Hash.new
                    currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
                end
                currentEntityTypeHash[offlineEntity.guid] = offlineEntity    
            end #entitiesToBeSynced.each ends
          
            #Offline entities Hash is complete. Now prepare the input Hashx.
            otherDetailsHM = {}

            offlineEntitiesHash.each do |key,value|
                hashArray = Array.new
                entityCounter = 0
                value.each_value do |offlineEntity|
                    offlineEntity.beforeSync if offlineEntity.respond_to?('beforeSync'.to_sym)
                    entityPackage = getEntitiesToBeSynced(key,offlineEntity,entityCounter,otherDetailsHM)
                    entityCounter = entityPackage['counter']
                    entityPackage.delete('counter')
                    hashArray.push entityPackage.to_json
                end
                
                inputHash["otherDetails"] = ::JSON.generate(otherDetailsHM) if !otherDetailsHM.empty?
                inputHash["counter"] = entityCounter.to_s if entityCounter > 0
                begin
                    inputHash[key] = ::JSON.generate(hashArray)
                rescue StandardError => se
                    puts "Error while generating entities from hash =>" + se.to_s
                end
            end
            # log(inputHash.to_s)
            begin
                json = ::JSON.generate(inputHash)
            rescue StandardError => se
                puts "Error while generating JSON of request data =>" + se.to_s
            end
            begin
                response = obj.doJSONPost('/MergeEntities.run', json)
                raise MobiSys::StandardError.new(MobiSys::BrowserHelper.getLabel('ERR_SYSTEMERROR')) if response.to_s == ""
                resultsHash = Rho::JSON.parse(response)
                resultsHash.each do |key,value|
                    next if value.to_s == '' || value.to_s == '[]' || value.empty?
                    # log "Key: " + key.to_s
                    # log "Value: " + value.to_s
                    entities = Rho::JSON.parse(value)

                    offlineEntities = offlineEntitiesHash[key]
                    count = 0
                    
                    begin
                        db = ::Rho::RHO.get_db_partitions()['local']
                        db.start_transaction
                        entities.each do |mainEntity|
                            next if mainEntity[key].to_s == ''
                            getEntitiesToBeSavedPostSync(key,mainEntity,offlineEntities)
                        end#entities.each ends
                        db.commit
                    rescue StandardError => se
                        db.rollback
                        if showMessages
                            Alert.show_popup({:title=>'',:message=>se.to_s, 
                            :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                        else
                            log('Error while syncing entities: ' + se.to_s)
                            raise se
                        end
                    end
                end #resultsHash.each ends
            rescue MobiSys::AuthenticationError => se
                if showMessages
                    Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=>'/app/SyncCategory/loginpopupcallback'})
                else
                    log('Authentication error while syncing' + se.to_s)
                    raise se
                end
            rescue MobiSys::JSONPostError => se
                if showMessages
                    Alert.show_popup({:title=>'',:message=>se.to_s, 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=>'/app/SyncCategory/loginpopupcallback'})
                else
                    log('Authentication error while syncing' + se.to_s)
                    raise se
                end
            rescue MobiSys::UpgradeApplicationError => ue
                if showMessages
                    Alert.show_popup({:title=>'',:message=>ue.to_s, 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=>'/app/SyncCategory/transactionpopupcallback'})
                else
                    log("Error during Sync.singleTransactions: "+ue.to_s)
                    raise ue
                end
            rescue StandardError => se
                if showMessages
                    Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('EMAILSYNCFAILEDMESSAGE'),
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=>'/app/SyncCategory/transactionpopupcallback'})
                else
                    log("Error during Sync.singleTransactions: "+se.to_s)
                    raise se
                end
            end            
        end
        #entitites start
    
        #sendEmailRequest
        def self.sendEmailRequest(entitiesToBeSynced, showMessages, url=nil)
            returnHash = nil
            log "Starting sync for #{entitiesToBeSynced.length} entities"
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            offlineEntitiesHash = Hash.new
            inputHash = Hash.new
            entitiesToBeSynced.each do |offlineEntity|
                className = offlineEntity.class.name.to_s
                exp = className + ".onlineClassName"
                onlineClassName = eval(exp)
                currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
                unless currentEntityTypeHash
                    offlineEntitiesHash[onlineClassName] = Hash.new
                    currentEntityTypeHash = offlineEntitiesHash[onlineClassName]
                end
                currentEntityTypeHash[offlineEntity.guid] = offlineEntity    
            end #entitiesToBeSynced.each ends
          
            #Offline entities Hash is complete. Now prepare the input Hashx
          
            offlineEntitiesHash.each do |key,value|
                hashArray = Array.new
                value.each_value do |offlineEntity|
                    offlineEntity.beforeSync if offlineEntity.respond_to?('beforeSync'.to_sym)
                    hashArray.push offlineEntity.hashForSync
                    @fnaRequest = offlineEntity if offlineEntity.class.name.to_s == "FNARequest"
                    @outputpreference = offlineEntity if offlineEntity.class.name.to_s == "OutputPreferences"
                end
                 
                begin
                    inputHash[key] =  ::JSON.generate([{key => hashArray}.to_json])
                rescue StandardError => se
                    puts "Error while generating entities from hash =>" + se.to_s
                end
            end
            if @fnaRequest && @outputpreference
                $hide_sign_flag = false
                filePath = MobiSys::UIGenUtilFNA.generateOutputHTML(@fnaRequest, @outputpreference)
                $hide_sign_flag = nil
                encryptedContent = File.read(filePath)
                jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                jsonObjects = Rho::JSON.parse(jsonContent)
                inputHash["html"] = jsonObjects["html"]
                inputHash["graphJSON"] = jsonObjects["graphJSON"]
                inputHash["languageCd"] = jsonObjects["languageCd"]
                File.delete(filePath) if File.exists?(filePath)
            end
            log(inputHash.to_s)
          
            begin
                json = ::JSON.generate(inputHash)
            rescue StandardError => se
                puts "Error while generating JSON of request data =>" + se.to_s
            end

            begin
                if url
                    response = obj.doJSONPost(url, json)
                else  
                    response = obj.doJSONPost('/SendEmailRequest.run', json)
                end  
                resultsHash = Rho::JSON.parse(response)
                returnHash = resultsHash
                resultsHash.each do |key,val|
                    next if (key.to_s == "PDFCONTENT" || key.to_s == "pdfFile")
                    val = Rho::JSON.parse(val)
                    if val.is_a?(Array)
                        val.each do |value|
                            next if (key.to_s == "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.OutputPreferencesDO")
                            # entities = Rho::JSON.parse(value)


                            entities = Rho::JSON.parse(value[key])
                            log "Received #{entities.length} of type #{key.to_s}"
                            offlineEntities = offlineEntitiesHash[key]
                            count = 0

                            entities.each do |entity|
                                offlineEntity = offlineEntities[entity['guid']]
                                className = offlineEntity.class.name.to_s
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
                            end#entities.each ends
                        end   
                    end
                end #resultsHash.each ends
                if showMessages
                    # Alert.show_popup( {
                    #     :message => MobiSys::BrowserHelper.getLabel('EMAILSENT'),
                    #     :title => '',
                    #     :icon => :alert,
                    #     :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
                    # } )
                end
            rescue MobiSys::AuthenticationError => se
                if showMessages
                    Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                else
                    log('Authentication error while syncing' + se.to_s)
                    raise se
                end
            rescue MobiSys::JSONPostError => se
                if showMessages
                    Alert.show_popup({:title=>'',:message=>se.to_s, 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                else
                    log('Authentication error while syncing' + se.to_s)
                    raise se
                end
            rescue MobiSys::UpgradeApplicationError => ue
                if showMessages
                    Alert.show_popup({:title=>'',:message=>ue.to_s, 
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                    else
                        log("Error during Sync.singleTransactions: "+ue.to_s)
                        raise ue
                    end
            rescue StandardError => se
                if showMessages
                  Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('EMAILSYNCFAILEDMESSAGE'),
                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]})
                else
                  log("Error during Sync.singleTransactions: "+se.to_s)
                  raise se
                end            
            end
            return returnHash    
        end
        #sendEmailRequest

        def self.log(message)
            RhoLog::info('Sync', message)
        end
    
        def self.getSyncLogHTML
            html = ""
            html  << "<table width='100%' border='1' cellspacing='0'><tr><th>Entity name<th>Status<th>Entities received<th>Entitites processed</tr>"
            $syncLogs.each do |syncLog|
                html << "<tr><td>#{syncLog.entityName}<td>#{syncLog.status}"
                if syncLog.recordsReceived
                    html << "<td>#{syncLog.recordsReceived}"
                else
                    html << "<td>0"  
                end
                if syncLog.recordsProcessed
                    html << "<td>#{syncLog.recordsProcessed}"
                else
                    html << "<td>0"  
                end
                html << "</tr>"
            end
            html << "</table>"
            return html     
        end

        def self.outputImagesSync
            clazz = Class.new do 
                include MobiSys::BrowserHelper
            end
            obj = clazz.new
            showSuccessAlert = false
            syncLog = $syncLogHash['OutputImages']
            begin
                syncLog.status = 'In process'
                WebView.execute_js("downloadFile()")
                inputHash = Hash.new
                inputHash[Application.getValue('OUTPUTIMAGESVERSION').value] = nil
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/SyncOutputImages.run',json)
                resultsHash = Rho::JSON.parse(response)
                if resultsHash.has_key? "error"
                    Alert.show_popup("error")
                    Alert.show_popup({:title=>'',:message=>resultsHash["error"],
                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    :callback=> '/app/SyncCategory/transactionpopupcallback'})
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                        downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../outputimages')
                        Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                        downloadFolder = File.realpath(downloadFolder)
                        filePath = File.join(downloadFolder,fileName)
                        url = "#{Application.getValue('online_server_url').value}/File.run"
                        Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :headers => {"username"=>$userId,"password"=>$userPassword, "filename" => fileName},
                            :callback => '/app/SyncCategory/outputimagesdownload',
                            :overwriteFile => true,
                            :callback_param => "outputimagesversion=#{key}&filePath=#{filePath}",
                            :ssl_verify_peer => $ssl_verify_peer)
                        syncLog.status = 'Downloading file.'
                    end
                end
                if resultsHash.length == 0
                    $outputImagesSyncCompleted = true
                    syncLog.status = "Completed"
                    #Update last sync date in the application table - start
                    primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
                    if primarySyncDateAppObject == nil
                        Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
                    else
                        Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
                    end
                    Application.updateValue('MASTERDATAMISMATCH',"NO")
                    #Update last sync date in the application table - end
                    refreshUI
                    showSuccessAlert = true
                    if showSuccessAlert
                        Alert.show_popup({
                            :title=>'',
                            :message=>MobiSys::BrowserHelper.getLabel("SUCCESS"),
                            :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                        }) 
                    end
                end
            rescue MobiSys::AuthenticationError => se
                #Do nothing
                log('Authentication failure')
                Alert.show_popup({:title=>'Error',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    :callback=>'/app/SyncCategory/transactionpopupcallback'}) 
                $outputImagesSyncCompleted = false;
            rescue StandardError => se
                syncLog.status='Failed'
                log('Output images sync failed' + se.to_s)
                Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERSYNCFAILEDMESSAGE'),
                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    :callback=>'/app/SyncCategory/transactionpopupcallback'})  
                # WebView.navigate('/app/SyncCategory/syncPreferences')
            end
        end  
    
        def self.masterFileSync
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            syncLog = $syncLogHash['Masters']
            begin
                syncLog.status = 'In process'
                #refreshUI
                WebView.execute_js("downloadFile()")
                inputHash = Hash.new
                inputHash[Application.getValue('DBVERSION').value] = nil
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/SyncMasterDB.run', json)
                #process results
                resultsHash = Rho::JSON.parse(response)
                dimoge = Application.getValue('Dimoge').value
                # if error exist then alert else continue sync
                if resultsHash.has_key?("error")
                    Alert.show_popup({:title=>'',:message=>resultsHash["error"],
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=> $dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback'})
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                        downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
                        Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                        downloadFolder = File.realpath(downloadFolder)
                        filePath = File.join(downloadFolder, fileName)
                        url = Application.getValue('online_server_url').value + "/File.run"
                        syncLog.status = 'Downloading file.'
                        Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName, "Dimoge" => dimoge},
                            :callback => '/app/SyncCategory/masterdownload',
                            :overwriteFile => true,
                            :callback_param => "dbVersion=#{key}&filePath=#{filePath}",
                            :ssl_verify_peer => $ssl_verify_peer
                        )
                    end
                end 
                if resultsHash.length == 0
                    $masterSyncCompleted = true
                    syncLog.status = 'Completed'
                    #Update last sync date in the application table - start
                    primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
                    if primarySyncDateAppObject == nil
                        Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
                    else
                        Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
                    end
                    Application.updateValue('MASTERDATAMISMATCH',"NO")
                    #Update last sync date in the application table - end
                    refreshUI
                end
            rescue MobiSys::AuthenticationError => se
                #Do nothing
                log('Authentication failure')
                $masterSyncCompleted = false;
            rescue StandardError => se
                syncLog.status='Failed'
                log('Master sync failed' + se.to_s)
                Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERSYNCFAILEDMESSAGE'),
                    :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    :callback=>'/app/SyncCategory/transactionpopupcallback'})
                    #WebView.navigate('/app/AgentReg/postLogin')
                # WebView.navigate('/app/SyncCategory/syncPreferences')
            end      
        end

        def self.masterFileSyncForApi
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            syncLog = $syncLogHash['Masters']
            begin
                syncLog.status = 'In process'
                #refreshUI
                # WebView.execute_js("downloadFile()")
                inputHash = Hash.new
                inputHash[Application.getValue('DBVERSION').value] = nil
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/SyncMasterDB.run', json)
                dimoge = Application.getValue('Dimoge').value
                #process results
                resultsHash = Rho::JSON.parse(response)

                # if error exist then alert else continue sync
                if resultsHash.has_key?("error")
                    # Alert.show_popup({:title=>'',:message=>resultsHash["error"],
                    #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    #     :callback=> $dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback'})
                    syncLog.status = 'error'
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                        downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
                        Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                        downloadFolder = File.realpath(downloadFolder)
                        filePath = File.join(downloadFolder, fileName)
                        url = Application.getValue('online_server_url').value + "/File.run"
                        syncLog.status = 'Downloading file.'
                        result = Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName, "Dimoge" => dimoge},
                            # :callback => '/app/SyncCategory/masterdownload',
                            :overwriteFile => true,
                            # :callback_param => "dbVersion=#{key}&filePath=#{filePath}",
                            :ssl_verify_peer => $ssl_verify_peer
                        )
                        masterdownload(key,filePath,result)
                    end
                end 
                if resultsHash.length == 0
                    $masterSyncCompleted = true
                    syncLog.status = 'Completed'
                    #Update last sync date in the application table - start
                    primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
                    if primarySyncDateAppObject == nil
                        Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
                    else
                        Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
                    end
                    Application.updateValue('MASTERDATAMISMATCH',"NO")
                    #Update last sync date in the application table - end
                    # refreshUI
                end
            rescue MobiSys::AuthenticationError => se
                #Do nothing
                log('Authentication failure')
                $masterSyncCompleted = false;
            rescue StandardError => se
                syncLog.status='Failed'
                log('Master sync failed' + se.to_s)
                # Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERSYNCFAILEDMESSAGE'),
                #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                #     :callback=>'/app/SyncCategory/transactionpopupcallback'})
                    #WebView.navigate('/app/AgentReg/postLogin')
                $syncLogHash['Masters'].status = 'error'
                # WebView.navigate('/app/SyncCategory/syncPreferences')
            end      
        end

        def self.outputImagesSyncForApi
            clazz = Class.new do 
                include MobiSys::BrowserHelper
            end
            obj = clazz.new
            showSuccessAlert = false
            syncLog = $syncLogHash['OutputImages']
            begin
                syncLog.status = 'In process'
                inputHash = Hash.new
                inputHash[Application.getValue('OUTPUTIMAGESVERSION').value] = nil
                json = ::JSON.generate(inputHash)
                response = obj.doJSONPost('/SyncOutputImages.run',json)
                resultsHash = Rho::JSON.parse(response)
                if resultsHash.has_key? "error"
                    syncLog.status = 'error'
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
                        downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../outputimages')
                        Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
                        downloadFolder = File.realpath(downloadFolder)
                        filePath = File.join(downloadFolder,fileName)
                        url = "#{Application.getValue('online_server_url').value}/File.run"
                        result = Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :headers => {"username"=>$userId,"password"=>$userPassword, "filename" => fileName},
                            # :callback => '/app/SyncCategory/outputimagesdownload',
                            :overwriteFile => true,
                            # :callback_param => "outputimagesversion=#{key}&filePath=#{filePath}",
                            :ssl_verify_peer => $ssl_verify_peer)
                        outputimagesdownload(key,filePath,result)
                        syncLog.status = 'Downloading file.'
                    end
                end
                if resultsHash.length == 0
                    $outputImagesSyncCompleted = true
                    syncLog.status = "Completed"
                    #Update last sync date in the application table - start
                    primarySyncDateAppObject = Application.getValue('PRIMARYDATALASTSYNCDATE')
                    if primarySyncDateAppObject == nil
                        Application.create('PRIMARYDATALASTSYNCDATE', Time.dump(Time.now))
                    else
                        Application.updateValue('PRIMARYDATALASTSYNCDATE',Time.dump(Time.now))
                    end
                    Application.updateValue('MASTERDATAMISMATCH',"NO")
                    #Update last sync date in the application table - end
                    # refreshUI
                    # showSuccessAlert = true
                    # if showSuccessAlert
                    #     Alert.show_popup({
                    #         :title=>'',
                    #         :message=>MobiSys::BrowserHelper.getLabel("SUCCESS"),
                    #         :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                    #     }) 
                    # end
                end
            rescue MobiSys::AuthenticationError => se
                #Do nothing
                log('Authentication failure')
                # Alert.show_popup({:title=>'Error',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                #     :callback=>'/app/SyncCategory/transactionpopupcallback'}) 
                $syncLogHash['OutputImages'].status = 'error'
                $outputImagesSyncCompleted = false;
            rescue StandardError => se
                syncLog.status='Failed'
                log('Output images sync failed' + se.to_s)
                # Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERSYNCFAILEDMESSAGE'),
                #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                #     :callback=>'/app/SyncCategory/transactionpopupcallback'})  
                # WebView.navigate('/app/SyncCategory/syncPreferences')
            end
        end 

        def self.entityContextFileSyncForApi
            clazz = Class.new do 
                include MobiSys::BrowserHelper
            end
            obj = clazz.new
            syncLog = $syncLogHash['EntityContext']
            begin
                syncLog.status = 'In process'
                response = obj.doJSONPost('/SyncEntityContextFile.run',"")
                resultsHash = Rho::JSON.parse(response)
                if resultsHash.has_key? "error"
                    syncLog.status = 'error'
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        if Rho::System.platform == 'WINDOWS_DESKTOP' || Rho::System.isRhoSimulator
                            filePath = File.join(Rho::RhoApplication.get_blob_folder, fileName)
                        else
                            filePath = File.join(Rho::RhoApplication.userFolder, fileName)
                        end
                        url = "#{Application.getValue('online_server_url').value}/File.run"
                        syncLog.status = 'Downloading file.'
                        result = Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :overwriteFile => true,
                            :headers => {"username"=>$userId,"password"=>$userPassword, "filename" => fileName},
                            :ssl_verify_peer => $ssl_verify_peer)
                        if result['status'] == "ok"
                            $entityContextSyncCompleted = true
                            syncLog.status = "Completed"
                        else
                            $entityContextSyncCompleted = false
                            syncLog.status='Failed'
                        end
                    end
                end
                if resultsHash.length == 0
                    $entityContextSyncCompleted = true
                    syncLog.status = "Completed"
                end
            rescue MobiSys::AuthenticationError => se
               #Do nothing
                log('Authentication failure')
                syncLog.status='Failed'
                $entityContextSyncCompleted = false
            rescue StandardError => se
                $entityContextSyncCompleted = false
                syncLog.status='Failed'
                log('entityContext sync failed' + se.to_s)
            end
        end

        def self.masterdownload(dbVersion,filePath,downloadResult)
            syncLog = $syncLogHash['Masters']
            if downloadResult['status'] == 'ok' and downloadResult['http_error'] != "404" and downloadResult['http_error'] != "500"
                product = Product.new
                product.save
                product.delete
                backupDBFiles
                selectedLanguage = Application.getValue('DEFAULTLOCALE').value
                result = Rhom::Rhom.database_import('master',filePath)
                Localization::LabelCache.instance.resetLabels(selectedLanguage)
                puts "DB import was successful with result #{result}" if result
                puts "DB import returned no result" unless result
                if result
                    restoreFiles
                    File::delete filePath if File::exist? filePath
                    Application.updateValue("DBVERSION",dbVersion)
                    syncLog.status = 'Completed'
                    $masterSyncCompleted = true

                    if $outputImagesSyncCompleted and $masterSyncCompleted
                    #Update last sync date in the application table - start
                    
                        MobiSys::Sync.syncApplicationDate

                        #Update last sync date in the application table - end
                        $showSync = false
                        $dbUpdateMandatory = false
                        # set syncFlag to NO at online DeviceusermapDO      
                        inputHash = Hash.new
                        inputHash["YES"] = nil
                        json = ::JSON.generate(inputHash)
                        response = doJSONPost('/SyncFlagDB.run', json)
                    #process results  
                    end 
                else
                    syncLog.status = 'DB import failed'
                    $masterSyncActivity.setErrored
                    # Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERIMPORTFAILEDMESSAGE'),
                    # :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                    # :callback=> $dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback' })
                end
            else
                syncLog.status = 'File download failed'
                $masterSyncActivity.setErrored
                # Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERDOWNLOADFAILEDMESSAGE'),
                #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                #     :callback=>$dbUpdateMandatory ? '/app/SyncCategory/transactionpopupcallback' : '/app/SyncCategory/loginpopupcallback'})
            end
            $masterSyncActivity.persistAll
            # MobiSys::Sync.refreshUI
            # if $collateralDownloadHash.empty? && $masterSyncCompleted && $outputImagesSyncCompleted && $entityContextSyncCompleted && $transactionSyncCompleted
            #     WebView.navigate($rhoconfig[:post_login_path]) 
            # else
            #     WebView.navigate('/app/SyncCategory/syncPreferences')
            # end
            #render :action => :blank
        end

        def self.outputimagesdownload(outputimagesversion,filePath,downloadResult)
            syncLog = $syncLogHash['OutputImages']
            # outputimagesversion = @params['outputimagesversion']
            # filePath = @params['filePath']
            if downloadResult['status'] == 'ok' and downloadResult['http_error'] != "404" and downloadResult['http_error'] != "500"
                System.unzip_file filePath
                File.delete filePath
                outputimagespath = "#{Rho::RhoApplication.get_base_app_path}public/images/outputimages"
                Dir.mkdir outputimagespath unless Dir.exist? outputimagespath
                Dir.foreach(outputimagespath) { |existingFile|
                    next if existingFile == "." or existingFile == ".."
                    existingFilePath = "#{outputimagespath}/#{existingFile}"
                    # File.delete existingFilePath
                }
                sourceDir = "#{Rho::RhoApplication.get_blob_folder}/../outputimages"
                outputimagespath = "#{Rho::RhoApplication.get_base_app_path}public/images"
                FileUtils.cp_r(sourceDir,outputimagespath)
                FileUtils.rm_rf sourceDir
                Application.updateValue("OUTPUTIMAGESVERSION",outputimagesversion)
                $outputImagesSyncCompleted = true
                syncLog.status = "Completed"
            else
                syncLog.status = 'File download failed'
                $masterSyncActivity.setErrored
                # Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('MASTERDOWNLOADFAILEDMESSAGE'),
                #     :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                #     :callback=>'/app/SyncCategory/transactionpopupcallback'})
            end
            # MobiSys::Sync.refreshUI
            if $outputImagesSyncCompleted and $masterSyncCompleted
            #Update last sync date in the application table - start
            
                MobiSys::Sync.syncApplicationDate

                #Update last sync date in the application table - end
                # set syncFlag to NO at online DeviceusermapDO      
                inputHash = Hash.new
                inputHash["YES"] = nil
                json = ::JSON.generate(inputHash)
                response = doJSONPost('/SyncFlagDB.run', json)
            end
            $masterSyncActivity.persistAll
            # if $collateralDownloadHash.empty? && $masterSyncCompleted && $outputImagesSyncCompleted && $entityContextSyncCompleted && $transactionSyncCompleted
            # WebView.navigate($rhoconfig[:post_login_path]) 
            # else
            # WebView.navigate('/app/SyncCategory/syncPreferences')
            # end
        end  

        def self.backupDBFiles
            if Dir.exist? Rho::RhoApplication.get_blob_folder
                backupDir = Rho::RhoApplication.get_blob_folder + '/../backup'
                Dir.mkdir backupDir unless (Dir.exist? backupDir)
                FileUtils.cp_r(Rho::RhoApplication.get_blob_folder + '/.', backupDir)        
            end
        end

        def self.restoreFiles
            Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
            backupDir = Rho::RhoApplication.get_blob_folder + '/../backup/.'
            FileUtils.cp_r(backupDir, Rho::RhoApplication.get_blob_folder)
            FileUtils.rm_rf backupDir
        end

        def self.collateralFileSync
            $syncLogHash['CollateralDownload'].recordsReceived = $collateralDownloadHash.size
            if $collateralDownloadHash.empty?
                lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
                if lastCollateralSyncDate
                    Application.updateValue('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                else
                    Application.create('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                end
                if defined? $onlineCollateralVersion 
                    Application.updateValue('COLLATERALVERSION', $onlineCollateralVersion) if $onlineCollateralVersion.to_s != ''
                end
                label = MobiSys::BrowserHelper.getLabel("COLLATERAL") + " " + MobiSys::BrowserHelper.getLabel("SUCCESS") 
                Alert.show_popup({:title=>'', :message=>label, :buttons=>["Ok"] })
                WebView.navigate($rhoconfig[:post_login_path]) if $collateralDownloadHash.empty? and $masterSyncCompleted and $outputImagesSyncCompleted
            else
                $collateralDownloadHash.each do |fileName, status|
                    Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
                    filePath = File.join(Rho::RhoApplication.get_blob_folder, fileName)
                    url = "#{Application.getValue('online_server_url').value}/File.run"
                    $syncLogHash['CollateralDownload'].status = 'In process'
                    refreshDownloadUI
                    has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                    if !has_network
                        if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0') 
                            Alert.show_popup( {
                                :message => MobiSys::BrowserHelper.getLabel('ERR_NETWORK'),
                                :title => '',
                                :icon => :info,
                                :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]} )
                            WebView.navigate('/app/SyncCategory/syncPreferences')
                        else
                            $syncLogHash['CollateralDownload'].status = 'error'
                        end
                    else
                        Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :overwriteFile => true,
                            :headers => {"username"=>$userId,"password"=>$userPassword, "filename" =>"public%2Fcollateral%2F" + fileName},
                            :callback => '/app/Collateral/collateraldownload_callback',
                            :callback_param => "fileName=#{fileName}&filePath=#{filePath}",
                            :ssl_verify_peer => $ssl_verify_peer
                        )
                    end
                end
            end
        end

        def self.collateralFileSyncForApi
            $syncLogHash['CollateralDownload'].recordsReceived = $collateralDownloadHash.size
            $collateralDownloadHash.each do |fileName, status|
                Dir.mkdir(Rho::RhoApplication.get_blob_folder) unless Dir.exist?(Rho::RhoApplication.get_blob_folder)
                filePath = File.join(Rho::RhoApplication.get_blob_folder, fileName)
                url = "#{Application.getValue('online_server_url').value}/File.run"
                $syncLogHash['CollateralDownload'].status = 'In process'
                refreshDownloadUI
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if !has_network
                        $syncLogHash['CollateralDownload'].status = 'error'
                else
                    result = Rho::AsyncHttp.download_file(
                        :url => url,
                        :filename => filePath,
                        :overwriteFile => true,
                        :headers => {"username"=>$userId,"password"=>$userPassword, "filename" =>"public%2Fcollateral%2F" + fileName},
                        # :callback => '/app/Collateral/collateraldownload_callback',
                        # :callback_param => "fileName=#{fileName}&filePath=#{filePath}",
                        :ssl_verify_peer => $ssl_verify_peer
                    )
                    collateraldownload_callback(fileName, filePath, result)
                end
            end
        end


        def self.collateraldownload_callback(fileName,filePath,result)
            downloadStatus = result["status"]
            httpErrorCd = result["http_error"]
            
            collateralList = Collateral.find(
                :all,
                :conditions=>{
                    {
                        :name => "collateralCd",
                        :op => "IN"
                    } => $collateralDownloadHash[fileName].split(",")
                }
            )
            begin
                if downloadStatus == "ok" and httpErrorCd != 404
                    #File download successfull. Change the filename from URL to local path.
                    windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
                    is_rho_simulator = Rho::System.isRhoSimulator
                    # for windows platform moving files from downloads to collateral folder as images require relative path.
                    if windows_platform
                        destFilePath = File.join(Rho::Application.publicFolder, "collateral")
                        Dir.mkdir(destFilePath) unless Dir.exist?(destFilePath)
                        destFilePath = File.join(destFilePath, fileName)

                        fileCopyStatus = Rho::RhoFile.copy(filePath, destFilePath)
                        
                        if fileCopyStatus == 0
                            File.delete(filePath) 
                            collateralList.each do |collateral|
                                if is_rho_simulator
                                    if collateral.embedType.to_s == "EXTERNAL"
                                        collateral.fileName = destFilePath
                                    else
                                        collateral.fileName = destFilePath[destFilePath.index("public")-1..-1]
                                    end
                                else
                                    if collateral.embedType.to_s == "EXTERNAL"
                                        collateral.fileName = destFilePath
                                    else
                                        collateral.fileName = destFilePath[destFilePath.index("public")-1..-1]
                                    end
                                end
                                collateral.colStatus = "COMPLETED"
                                collateral.persistAll
                            end
                        end
                    else
                        collateralList.each do |collateral|
                            if is_rho_simulator
                                if collateral.embedType.to_s == "EXTERNAL"
                                    collateral.fileName = filePath
                                else
                                    collateral.fileName = filePath[filePath.index("rhosimulator")-1..-1]
                                end
                            else
                                collateral.fileName = filePath
                            end
                            collateral.colStatus = "COMPLETED"
                            collateral.persistAll
                        end
                    end
                    $collateralDownloadHash.delete(fileName)
                else
                    #Delete the offline collateral data object since file download has failed.
                    collateralList.each do |collateral|
                        collateral.destroy
                    end
                    $collateralDownloadHash.delete(fileName)
                    $collateralSyncFailed = $collateralSyncFailed + 1
                    File.delete(filePath+".rhodownload") if File.exists?(filePath+".rhodownload")
                end
                $syncLogHash['CollateralDownload'].recordsProcessed = $syncLogHash['CollateralDownload'].recordsProcessed + 1
                # $syncLogHash['Collateral'].recordsProcessed = $syncLogHash['Collateral'].recordsProcessed + 1
            rescue StandardError => se
                puts se
            end
            $syncLogHash['CollateralDownload'].status = "Completed" if $collateralDownloadHash.empty?
            if $collateralDownloadHash.empty? and $collateralSyncFailed == 0
                lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
                if lastCollateralSyncDate
                    Application.updateValue('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                else
                    Application.create('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
                end
                if defined? $onlineCollateralVersion 
                    Application.updateValue('COLLATERALVERSION', $onlineCollateralVersion) if $onlineCollateralVersion.to_s != ''
                end
                # label = MobiSys::BrowserHelper.getLabel("COLLATERAL") + " " + MobiSys::BrowserHelper.getLabel("SUCCESS") 
                # Alert.show_popup({:title=>'', :message=>label, :buttons=>["Ok"] })
                # WebView.navigate($rhoconfig[:post_login_path]) if $collateralDownloadHash.empty? and $masterSyncCompleted and $outputImagesSyncCompleted
            elsif $collateralDownloadHash.empty? and $collateralSyncFailed > 0
                # Alert.show_popup({
                # 	:title=>'',
                # 	:message=>getLabelValue('COLLATERALSYNCFAILEDMESSAGE'),
                # 	:buttons=>["Ok"],
                # 	:callback=>url_for(:controller=>:SyncCategory, :action=>:transactionpopupcallback)
                # })
                # WebView.navigate('/app/SyncCategory/syncPreferences')
            end
        end
    
        def self.checkCollateralVersion(updateMandatoryFlag = true)
            has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
            $syncCollateral = false if updateMandatoryFlag
            $collateralUpdateMandatory = false if updateMandatoryFlag
            if has_network
                begin
                    inputHash = Hash.new
                    inputHash[Application.getValue('COLLATERALVERSION').value] = nil
                    json = ::JSON.generate(inputHash)
                    clazz = Class.new do
                        include MobiSys::BrowserHelper 
                    end
                    obj = clazz.new
                    response = obj.doJSONPost('/CheckCollateralVersion.run', json)
                    #process results
                    resultsHash = Rho::JSON.parse(response)
                    if resultsHash.length > 0
                        $syncCollateral = true if updateMandatoryFlag
                        $onlineCollateralVersion = resultsHash.keys[0]
                        $collateralUpdateMandatory = true if resultsHash.values[1] and resultsHash.values[1] == "YES" and  updateMandatoryFlag
                    end
                rescue StandardError => se
                    RhoLog::error('Level0Controller',se.to_s)
                end
            end
            # return syncCollateral,mandatory  
        end
        
        def self.entityContextFileSync
            clazz = Class.new do 
                include MobiSys::BrowserHelper
            end
            obj = clazz.new
            showSuccessAlert = false
            syncLog = $syncLogHash['EntityContext']
            begin
                syncLog.status = 'In process'
                WebView.execute_js("downloadFile()")
                response = obj.doJSONPost('/SyncEntityContextFile.run',"")
                resultsHash = Rho::JSON.parse(response)
                if resultsHash.has_key? "error"
                    Alert.show_popup("error")
                    Alert.show_popup({:title=>'',:message=>resultsHash["error"],
                        :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                        :callback=> '/app/SyncCategory/transactionpopupcallback'})
                else
                    resultsHash.each do |key,value|
                        fileName = value
                        if Rho::System.platform == 'WINDOWS_DESKTOP' || Rho::System.isRhoSimulator
                            filePath = File.join(Rho::RhoApplication.get_blob_folder, fileName)
                        else
                            filePath = File.join(Rho::RhoApplication.userFolder, fileName)
                        end
                        url = "#{Application.getValue('online_server_url').value}/File.run"
                        syncLog.status = 'Downloading file.'
                        result = Rho::AsyncHttp.download_file(
                            :url => url,
                            :filename => filePath,
                            :overwriteFile => true,
                            :headers => {"username"=>$userId,"password"=>$userPassword, "filename" => fileName},
                            :ssl_verify_peer => $ssl_verify_peer)
                        if result['status'] == "ok"
                            $entityContextSyncCompleted = true
                            syncLog.status = "Completed"
                        else
                            $entityContextSyncCompleted = false
                            syncLog.status='Failed'
                            log('entityContext sync failed' + result['status'].to_s)
                            Alert.show_popup({:title=>'',
                                :message=>MobiSys::BrowserHelper.getLabel('entityContextFailedMessage'),
                                :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                                :callback=>'/app/SyncCategory/transactionpopupcallback'
                            })  
                        end
                    end
                end
                if resultsHash.length == 0
                    $entityContextSyncCompleted = true
                    syncLog.status = "Completed"
                    refreshUI
                    showSuccessAlert = true
                    if showSuccessAlert
                       Alert.show_popup({
                           :title=>'',
                           :message=>MobiSys::BrowserHelper.getLabel("SUCCESS"),
                           :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")]
                       }) 
                   end
                end
            rescue MobiSys::AuthenticationError => se
               #Do nothing
                log('Authentication failure')
                Alert.show_popup({:title=>'Error',:message=>MobiSys::BrowserHelper.getLabel('ERR_AUTH_TRANS'), 
                   :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                   :callback=>'/app/SyncCategory/transactionpopupcallback'}) 
                $entityContextSyncCompleted = false
            rescue StandardError => se
                $entityContextSyncCompleted = false
                syncLog.status='Failed'
                log('entityContext sync failed' + se.to_s)
                Alert.show_popup({:title=>'',:message=>MobiSys::BrowserHelper.getLabel('entityContextFailedMessage'),
                   :buttons=>[MobiSys::BrowserHelper.getLabel("Ok")],
                   :callback=>'/app/SyncCategory/transactionpopupcallback'
                })  
            end
        end

        def self.processForceLoginSyncConditions(checkType=nil, userId=nil, activeDays=nil)
            unless userId || activeDays
                currentAgentReg = AgentReg.getCurrentAgentReg
                userId = $userId
                activeDays = currentAgentReg.activeDays
            end
            lastTransactionSyncDt = Time.at(0)
            masterDBUpgradeDt = Time.at(0)
            masterDBMandatory = false
            masterDataMismatch = false
            activeDaysElapsed = false
            masterDBEffectiveReached = false

            forceNetworkLogin = false
            navigateToSync = false
            masterSyncEnabled = false
            masterSyncDefault = "OFF"
            transactionSyncEnabled = false
            transactionSyncDefault = "OFF"

            Application.find(:all).each do |appObject|
                if appObject.key.to_s == "MASTERDBUPGRADEDATE"
                    masterDBUpgradeDt = Date.parse(appObject.value)
                    masterDBUpgradeDt = Time.new(masterDBUpgradeDt.year, masterDBUpgradeDt.month, masterDBUpgradeDt.day)
                elsif appObject.key.to_s == "MASTERDATAMISMATCH" && appObject.value.to_s == "YES"
                    masterDataMismatch = true
                elsif appObject.key.to_s == "MASTERDBMANDATORY" && appObject.value.to_s == "YES"
                    masterDBMandatory = true
                elsif appObject.key.to_s.include?("_#{userId}_lastSyncDate")
                    # Compute the latest transaction sync dat for the current user
                    timeObj = Time.load(appObject.value)
                    timeObj = Time.new(timeObj.strftime("%Y").to_i,timeObj.strftime("%m").to_i,timeObj.strftime("%d").to_i,0,0,0)
                    lastTransactionSyncDt = timeObj if timeObj > lastTransactionSyncDt
                end
            end

            # fix to make transcation syn optional on first login
            if lastTransactionSyncDt == Time.at(0)
                lastTransactionSyncDt = Time.now
            end
            # Decide whether Active days elapsed? i.e Last Trans Sync Date + Active Day < Today
            transactionSyncDt = lastTransactionSyncDt + (activeDays.to_i * 24 * 60 * 60)
            if transactionSyncDt < Time.now
                activeDaysElapsed = true
            end

            # Master DB Effective Date reached? i.e MASTERDBUPGRADEDATEMAX < Today
            if masterDBUpgradeDt < Time.now
                masterDBEffectiveReached = true
            end

            # Check to decide forceful navigation to sync page, sync page defaults and forceful network login
            if activeDaysElapsed || (!activeDaysElapsed && masterDataMismatch)
                navigateToSync = true
            end

            if (activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (!activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached && !masterDBMandatory) ||
                (!activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached && !masterDBMandatory)
                masterSyncEnabled = true
            end

            if (activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached) ||
                (!activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (!activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached)
                masterSyncDefault = "ON"
            end
            
            if (!activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (!activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached) ||
                (!activeDaysElapsed && !masterDataMismatch && !masterDBEffectiveReached) ||
                (!activeDaysElapsed && !masterDataMismatch && masterDBEffectiveReached)
                transactionSyncEnabled = true
            end

            if (activeDaysElapsed && masterDataMismatch && !masterDBEffectiveReached) ||
                (activeDaysElapsed && masterDataMismatch && masterDBEffectiveReached) ||
                (activeDaysElapsed && !masterDataMismatch && !masterDBEffectiveReached) ||
                (activeDaysElapsed && !masterDataMismatch && masterDBEffectiveReached)
                transactionSyncDefault = "ON"
            end

            if navigateToSync && ((!masterSyncEnabled && masterSyncDefault == "ON") || (!transactionSyncEnabled && transactionSyncDefault == "ON"))
                forceNetworkLogin = true
            end

            if checkType.to_s == "login"
                return forceNetworkLogin
            elsif checkType.to_s == "sync"
                return forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory
            end
        end


        def self.getEntitiesToBeSynced(entityName,offlineEntity,entityCounter,otherDetailsHM)
            entityPackage = Hash.new
            htmlArray = Array.new
            graphJsonArray = Array.new

            entityPackage[entityName] = [offlineEntity.hashForSync]

            if entityName == Policy.onlineClassName
                questionContainers = QuestionContainer.loadObject(
                    :all, 
                    :conditions=>{
                        {:name=>'policyGuid'} => offlineEntity.guid
                    }
                )
                if questionContainers
                    tempList = []
                    questionContainers.each do |questionContainer|
                        questionContainer.ServiceQuestionResponseList.each do |sq|
                            tempList.push sq.hashForSync
                        end
                    end
                    entityPackage[ServiceQuestionResponse.onlineClassName] = tempList.flatten
                end
                documentContainers = DocumentContainer.loadObject(
                    :all,
                    :conditions=>{
                        {:name=>'policyGuid'}=> offlineEntity.guid
                    }
                )
                if documentContainers
                    tempList = []
                    tempImageList = []
                    documentContainers.each do |documentContainer|
                        documentContainer.ServiceDocumentList.each do |sd|
                            tempList.push sd.hashForSync
                        end
                    end
                    entityPackage[ServiceDocument.onlineClassName] = tempList.flatten

                    documentContainers.each do |documentContainer|
                        partyDocumentList = documentContainer.ServiceDocumentList 
                        partyDocumentList.each do|partydoc|
                            imageList = Image.loadObject(:all, :conditions=>{{:name=>'parentRefGuid'}=>partydoc.uniqueKey})
                            imageList.each do|img|
                                tempImageList.push img.hashForSync
                            end
                        end
                    end
                    entityPackage[Image.onlineClassName] = tempImageList.flatten
                end

                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => offlineEntity.guid})            
                # if signatureContainers
                #     tempList = []
                #     signatureContainers.each do |serviceSignature|
                #         serviceSignature.ServiceSignatureList.each do |ss|
                #             tempList.push ss.hashForSync
                #         end
                #     end
                #     entityPackage[ServiceSignature.onlineClassName] = tempList.flatten
                # end
                serviceSignatureArray = Array.new
                if signatureContainers
                    signatureContainers.each do|serviceSignature|
                        serviceSignature.ServiceSignatureList.each do |sign|
                            serviceSignatureArray.push sign.hashForSync
                        end
                    end    
                end
                entityPackage[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0

                servSignArray = entityPackage[ServiceSignature.onlineClassName]
                if servSignArray
                    servSignArray.each do |servSign|
                      if servSign[:signature].to_s != "" && servSign[:signature].to_s.start_with?('ZLIBCMP')
                        compressed_signature = servSign[:signature].sub(/^ZLIBCMP/, '')
                        decoded_compressed_signature = MobiSys::Encryption.decodeContents(compressed_signature)
                        original_signature = MobiSys::Encryption.unZipData(decoded_compressed_signature)
                        servSign[:signature] = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(original_signature)
                      end
                    end
                end  


                entityPackage[ServiceSignature.onlineClassName] = servSignArray if servSignArray

                inward = offlineEntity.getInward(offlineEntity.proposalNum, "APPLICATION_SUSPENSE")
                if inward
                    inwardHash = inward.hashForSync
                    if inwardHash["listInwardDetailsDOList"]
                      inwardHash["listInwardDetailsDOList"].each do |detail|
                        if detail[:authCode].to_s != ""
                           detail[:authCode] = detail[:authCode].to_s
                        end   
                      end
                    end
                   entityPackage[Inward.onlineClassName] = [inwardHash]
                end

                # taskException = TaskException.loadObject(:all,:condition=>{:entitySeq => offlineEntity.guid})
                # if taskException
                #     entityPackage[TaskException.onlineClassName] = taskException
                #     puts "taskException.size:#{taskException.size}"
                #     puts "entityPackage[TaskException.onlineClassName]:#{entityPackage[TaskException.onlineClassName]}"
                # end

            elsif entityName == Quotation.onlineClassName
                if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
                    fileName = "#{offlineEntity.class.name.to_s}_#{offlineEntity.quotationRefNum.to_s}_ACCEPT.json"
                    filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
                    if File.exist?(filePath)
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlHash = {}
                        htmlCount = jsonObjects["htmlCount"].to_i
                        for i in 1..htmlCount
                            htmlHash["html#{i}"] = jsonObjects["html#{i}"]
                        end
                        otherDetailsHM["html#{entityCounter+1}"] = htmlHash.to_json
                        otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{entityCounter+1}"] = offlineEntity.class.name.to_s
                        otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.quotationRefNum.to_s
                        otherDetailsHM["entityGuid#{entityCounter+1}"] = offlineEntity.guid.to_s
                        otherDetailsHM["htmlCount#{entityCounter+1}"] = jsonObjects["htmlCount"]
                        otherDetailsHM["accept#{entityCounter+1}"] = "ACCEPT"
                        entityCounter += 1
                    end
                end
                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => offlineEntity.guid})  
                # if signatureContainers
                #     tempList = []
                #     signatureContainers.each do |serviceSignature|
                #         serviceSignature.ServiceSignatureList.each do |ss|
                #             tempList.push ss.hashForSync
                #         end
                #     end
                #     entityPackage[ServiceSignature.onlineClassName] = tempList.flatten
                # end
                serviceSignatureArray = Array.new
                if signatureContainers
                    signatureContainers.each do|serviceSignature|
                        serviceSignature.ServiceSignatureList.each do |sign|
                            serviceSignatureArray.push sign.hashForSync
                        end
                    end    
                end
                entityPackage[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0

                servSignArray = entityPackage[ServiceSignature.onlineClassName]
                if servSignArray
                    servSignArray.each do |servSign|
                      if servSign[:signature].to_s != "" && servSign[:signature].to_s.start_with?('ZLIBCMP')
                        compressed_signature = servSign[:signature].sub(/^ZLIBCMP/, '')
                        decoded_compressed_signature = MobiSys::Encryption.decodeContents(compressed_signature)
                        original_signature = MobiSys::Encryption.unZipData(decoded_compressed_signature)
                        servSign[:signature] = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(original_signature)
                      end
                    end
                end    

                entityPackage[ServiceSignature.onlineClassName] = servSignArray if servSignArray


                # taskException = TaskException.loadObject(:all,:condition=>{:entitySeq => offlineEntity.guid})
                # if taskException
                #     entityPackage[TaskException.onlineClassName] = taskException
                # end
            elsif entityName == Lead.onlineClassName
                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => offlineEntity.guid})            
                if signatureContainers
                    tempList = []
                    signatureContainers.each do |serviceSignature|
                        serviceSignature.ServiceSignatureList.each do |ss|
                            tempList.push ss.hashForSync
                        end
                    end
                    entityPackage[ServiceSignature.onlineClassName] = tempList.flatten
                end
            elsif entityName == FNARequest.onlineClassName
                if offlineEntity.statusCd == "FNASUBMIT"
                    fileName = "Fna_" + offlineEntity.fnaNum + ".json"
                    filePath = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}")
                    if File.exist? filePath
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlArray.push File.read(filePath)
                        otherDetailsHM["html#{entityCounter+1}"] = jsonObjects["html"]
                        otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{entityCounter+1}"] = 'Fna'
                        otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.fnaNum
                        otherDetailsHM["entityGuid#{entityCounter+1}"] = offlineEntity.guid

                        entityCounter += 1
                    end
                end
                
                signatureContainers = SignatureContainer.loadObject(:all,:conditions =>{:entityGuid => offlineEntity.guid})            
                # if signatureContainers
                #     tempList = []
                #     signatureContainers.each do |serviceSignature|
                #         serviceSignature.ServiceSignatureList.each do |ss|
                #             tempList.push ss.hashForSync
                #         end
                #     end
                #     entityPackage[ServiceSignature.onlineClassName] = tempList.flatten
                # end
                serviceSignatureArray = Array.new
                if signatureContainers
                    signatureContainers.each do|serviceSignature|
                        serviceSignature.ServiceSignatureList.each do |sign|
                            serviceSignatureArray.push sign.hashForSync
                        end
                    end    
                end
                entityPackage[ServiceSignature.onlineClassName] = serviceSignatureArray if serviceSignatureArray.size > 0

                servSignArray = entityPackage[ServiceSignature.onlineClassName]
                if servSignArray
                    servSignArray.each do |servSign|
                      if servSign[:signature].to_s != "" && servSign[:signature].to_s.start_with?('ZLIBCMP')
                        compressed_signature = servSign[:signature].sub(/^ZLIBCMP/, '')
                        decoded_compressed_signature = MobiSys::Encryption.decodeContents(compressed_signature)
                        original_signature = MobiSys::Encryption.unZipData(decoded_compressed_signature)
                        servSign[:signature] = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(original_signature)
                      end
                    end
                end    


                entityPackage[ServiceSignature.onlineClassName] = servSignArray if servSignArray

            elsif entityName == EmailRequest.onlineClassName
                outputpreference = OutputPreferences.loadObject(
                    :first,
                    :conditions => {
                        :guid => offlineEntity.outputPrefEntityGuid
                    }
                )
                if offlineEntity.entityName == "FNA"
                    fileName = "Fna_#{offlineEntity.entityNumber}_#{outputpreference.languageCd}.json"
                    filePath = Rho::RhoFile.join(Rho::Application.userFolder, "#{fileName}")
                    if File.exist?(filePath)
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlArray.push File.read(filePath)
                        otherDetailsHM["html#{entityCounter+1}"] = jsonObjects["html"]
                        otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{entityCounter+1}"] = 'Fna'
                        otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.entityNumber
                        otherDetailsHM["entityGuid#{entityCounter+1}"] = offlineEntity.guid.to_s
                        otherDetailsHM["languageCd#{entityCounter+1}"] = outputpreference.languageCd
                       
                        entityCounter += 1
                    else
                        fnaRequest = FNARequest.loadObject(
                            :first,
                            :conditions => {
                                :guid => offlineEntity.entityGuid
                            }
                        )
                        filePath = MobiSys::UIGenUtilFNA.generateOutputHTML(fnaRequest, outputpreference)
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlArray.push File.read(filePath)
                        otherDetailsHM["html#{entityCounter+1}"] = jsonObjects["html"]
                        otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{entityCounter+1}"] = 'Fna'
                        otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.entityNumber
                        otherDetailsHM["entityGuid#{entityCounter+1}"] = offlineEntity.guid.to_s
                        otherDetailsHM["languageCd#{entityCounter+1}"] = outputpreference.languageCd
                        
                        entityCounter += 1
                    end
                elsif offlineEntity.entityName == "Quotation"
                    fileName = "#{offlineEntity.entityName}_#{offlineEntity.entityNumber}_#{outputpreference.guid}.json"
                    filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
                    if File.exist?(filePath)
                        encryptedContent = File.read(filePath)
                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
                        jsonObjects = Rho::JSON.parse(jsonContent)
                        htmlHash = {}
                        htmlCount = jsonObjects["htmlCount"].to_i
                        for i in 1..htmlCount
                            htmlHash["html#{i}"] = jsonObjects["html#{i}"]
                        end
                        otherDetailsHM["html#{entityCounter+1}"] = htmlHash.to_json
                        otherDetailsHM["graphJSON#{entityCounter+1}"] = jsonObjects["graphJSON"]
                        otherDetailsHM["entityName#{entityCounter+1}"] = offlineEntity.entityName
                        otherDetailsHM["entityNum#{entityCounter+1}"] = offlineEntity.entityNumber
                        otherDetailsHM["entityGuid#{entityCounter+1}"] = offlineEntity.guid.to_s
                        otherDetailsHM["languageCd#{entityCounter+1}"] = outputpreference.languageCd
                        otherDetailsHM["htmlCount#{entityCounter+1}"] = jsonObjects["htmlCount"]
                        otherDetailsHM["outputPrefEntityGuid#{entityCounter+1}"] = offlineEntity.outputPrefEntityGuid
                        entityCounter += 1
                    end
                end
            end
            
            entityPackage['counter'] = entityCounter
            return entityPackage
        end


        def self.getEntitiesToBeSavedPostSync(entityName,mainEntity,offlineEntities)
            subEntity = Rho::JSON.parse(mainEntity[entityName])[0]

            if offlineEntities
                offlineEntity = offlineEntities[subEntity['guid']]
            end
            if entityName == Policy.onlineClassName
                policyEntity = subEntity
                
                className = offlineEntity.class.name.to_s
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,policyEntity)
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
                if mainEntity[ServiceDocument.onlineClassName].to_s != ''
                    serviceDocumentEntities = Rho::JSON.parse(mainEntity[ServiceDocument.onlineClassName])
                    partiesGuid = []
                    if serviceDocumentEntities.size > 0
                        validServiceDocumentGuids = serviceDocumentEntities.map { |e| e['guid'] }.to_set
                        partiesGuid = serviceDocumentEntities.collect{|x| x['partyGuid']}.uniq
                        partiesGuid.each do |partyGuid|
                            documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'entityGuid' => partyGuid, 'policyGuid' => policyEntity['guid']})
                            unless documentContainer
                                documentContainer = DocumentContainer.new
                                documentContainer.entityGuid = partyGuid
                                documentContainer.entityTypeCd = 'Party'
                                documentContainer.policyGuid = policyEntity['guid']
                            end 
                            serviceDocumentEntities.each do |serviceDocumentEntity|  
                                if serviceDocumentEntity['partyGuid'] == partyGuid
                                    serviceDocument = MobiSys::MobiSysEntitySchema.from_hash('ServiceDocument',serviceDocumentEntity)
                                    dbServiceDocumentEntity = nil
                                    documentContainer.ServiceDocumentList.each do |serviceDocumentOfflineEntity|
                                        if serviceDocumentOfflineEntity.guid == serviceDocument.guid
                                            dbServiceDocumentEntity = serviceDocumentOfflineEntity
                                        else
                                            # mark removed if not in validServiceDocumentGuids
                                            serviceDocumentOfflineEntity.removed = validServiceDocumentGuids.include?(serviceDocumentOfflineEntity.guid) ? nil : "YES"
                                        end
                                    end
                                    if  dbServiceDocumentEntity != nil
                                        dbServiceDocumentEntity.merge(serviceDocument)
                                        if dbServiceDocumentEntity.respond_to?('afterSync'.to_sym)
                                            dbServiceDocumentEntity.afterSync
                                        end
                                    else
                                        documentContainer.addServiceDocument(serviceDocument)
                                        if serviceDocument.respond_to?('afterSync'.to_sym)
                                            serviceDocument.afterSync
                                        end
                                    end
                                end
                            end 
                            documentContainer.persistAll('fromSync')
                        end
                    else
                        documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                        documentContainer&.ServiceDocumentList&.each do |serviceDocumentOfflineEntity|
                            serviceDocumentOfflineEntity.removed = "YES"
                        end
                        documentContainer&.persistAll('fromSync')
                    end
                end

                if mainEntity[ServiceQuestionResponse.onlineClassName].to_s != ''
                    serviceQuestionResponseEntities =  Rho::JSON.parse(mainEntity[ServiceQuestionResponse.onlineClassName])
                    # puts "ModifiedEntities serviceQuestionResponseEntities size : #{serviceQuestionResponseEntities.size}"
                    partiesGuid = []
                    if serviceQuestionResponseEntities.size > 0
                        validQuestionResponseGuids = serviceQuestionResponseEntities.map { |e| e['guid'] }.to_set
                        partiesGuid = serviceQuestionResponseEntities.collect{|x| x['partyGuid']}.uniq
                        partiesGuid.each do |partyGuid|
                            if partyGuid.to_s == ""
                                questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid'],'entityGuid' => policyEntity['guid']},:op => "AND" )
                            else
                                questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'entityGuid' => partyGuid, 'policyGuid' => policyEntity['guid']})
                            end
                            unless questionContainer
                                questionContainer = QuestionContainer.new 
                                if partyGuid
                                    questionContainer.entityGuid = partyGuid   
                                    questionContainer.entityTypeCd = onlineEntity.getPartyByGuid(partyGuid).roleCd
                                else
                                    questionContainer.entityGuid = policyEntity['guid']
                                    questionContainer.entityTypeCd = "AGENT"
                                end                                 
                                questionContainer.policyGuid = policyEntity['guid']
                            end 
                            serviceQuestionResponseEntities.each do |serviceQuestionResponseEntity| 
                                if (serviceQuestionResponseEntity['partyGuid'].to_s == partyGuid.to_s) || (questionContainer.entityTypeCd.to_s == "AGENT" && serviceQuestionResponseEntity['partyGuid'].to_s == "")
                                    serviceQuestionResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceQuestionResponse',serviceQuestionResponseEntity)
                                    dbserviceQuestionResponseEntity = nil
                                    questionContainer.ServiceQuestionResponseList.each do |serviceQuestionResponseOfflineEntity|
                                        if serviceQuestionResponseOfflineEntity.guid == serviceQuestionResponse.guid
                                            dbserviceQuestionResponseEntity = serviceQuestionResponseOfflineEntity
                                        else
                                            # mark removed if not in validQuestionResponseGuids
                                            serviceQuestionResponseOfflineEntity.removed = validQuestionResponseGuids.include?(serviceQuestionResponseOfflineEntity.guid) ? nil : "YES"
                                        end
                                    end
                                    if  dbserviceQuestionResponseEntity != nil
                                        dbserviceQuestionResponseEntity.merge(serviceQuestionResponse)
                                        if dbserviceQuestionResponseEntity.respond_to?('afterSync'.to_sym)
                                            dbserviceQuestionResponseEntity.afterSync
                                        end
                                    else
                                        questionContainer.addServiceQuestionResponse(serviceQuestionResponse)
                                        if serviceQuestionResponse.respond_to?('afterSync'.to_sym)
                                            serviceQuestionResponse.afterSync
                                        end
                                    end
                                end
                            end 
                            questionContainer.persistAll('fromSync')
                        end
                    else
                        questionContainer = QuestionContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                        questionContainer&.ServiceQuestionResponseList&.each do |serviceQuestionResponseOfflineEntity|
                            serviceQuestionResponseOfflineEntity.removed = "YES"
                        end
                        questionContainer&.persistAll('fromSync')
                    end
                end

                if mainEntity[Image.onlineClassName].to_s != ''
                    imageEntities = Rho::JSON.parse(mainEntity[Image.onlineClassName])
                    # puts "ModifiedEntities imageEntities size : #{imageEntities.size}"
                    if imageEntities.size > 0
                        documentContainers = DocumentContainer.find(
                            :all,
                            :conditions => {
                                'policyGuid' => policyEntity['guid']
                            }
                        )
                        documentContainers.each do |documentContainer|
                            serviceDocuments = documentContainer.ServiceDocumentList
                            serviceDocuments.each do |serviceDocumentOfflineEntity|
                                Image.delete_all(
                                    :conditions => {
                                        'parentRefGuid' => serviceDocumentOfflineEntity.guid
                                    }
                                )
                                serviceDocumentOfflineEntity.imageCount = nil
                                serviceDocumentOfflineEntity.persistAll('fromSync')
                            end
                        end
                        imageEntities.each do |imageEntity|
                            imageOfflineEntity = Image.loadObject(:first, :conditions=>{'guid' => imageEntity['guid']})
                            image = MobiSys::MobiSysEntitySchema.from_hash('Image',imageEntity)
                            if imageOfflineEntity.to_s != "" && imageOfflineEntity.guid == image.guid
                                imageOfflineEntity.merge(image)
                                if imageOfflineEntity.respond_to?('afterSync'.to_sym)
                                    imageOfflineEntity.afterSync
                                end
                                imageOfflineEntity&.persistAll('fromSync')
                            else
                                image.persistAll('fromSync')
                                serviceDocument = ServiceDocument.loadObject(:first,:conditions=>{'guid' => imageEntity['parentRefGuid']})
                                # serviceDocument.selected = "YES"
                                if serviceDocument.imageCount.to_s == ""
                                    serviceDocument.imageCount =  1
                                else
                                    serviceDocument.imageCount =  serviceDocument.imageCount + 1
                                end
                                serviceDocument.persistAll
                                if image.respond_to?('afterSync'.to_sym)
                                    image.afterSync
                                end
                            end
                        end                                        
                    else
                        documentContainer = DocumentContainer.loadObject(:first, :conditions=>{'policyGuid' => policyEntity['guid']})
                        documentContainer&.ServiceDocumentList&.each do |serviceDocumentOfflineEntity|
                            # serviceDocumentOfflineEntity&.removed = "YES"
                            Image.delete_all(
                                :conditions => {
                                    {:name=>'parentRefGuid'} => serviceDocumentOfflineEntity.guid
                                },
                                :op => 'AND'
                            )
                        end
                        # documentContainer&.persistAll('fromSync')
                    end
                end

                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                    puts "ModifiedEntities serviceSignatureEntities size : #{serviceSignatureEntities.size}"
                    if serviceSignatureEntities.size > 0
                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                        serviceSignatureEntities.each do |serviceSignatureEntity|
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => policyEntity['guid']})
                            unless signatureContainer
                                signatureContainer = SignatureContainer.new
                                signatureContainer.entityTypeCd = 'Policy'                                    
                                signatureContainer.entityGuid = policyEntity['guid']
                            end 
                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                            dbServiceSignatureEntity = nil
                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                else
                                    # mark removed if not in validServiceSignatureGuids
                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                end
                            end
                            if  dbServiceSignatureEntity != nil
                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                if dbServiceSignatureEntity.respond_to?('afterSync'.to_sym)
                                    dbServiceSignatureEntity.afterSync
                                end
                            else
                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            end
                            signatureContainer.persistAll('fromSync')
                        end
                    else
                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => policyEntity['guid']})
                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                            serviceSignatureOfflineEntity.removed = "YES"
                        end
                        signatureContainer&.persistAll('fromSync')
                    end
                end
                if mainEntity[Inward.onlineClassName].to_s != ''
                    inwardEntities = Rho::JSON.parse(mainEntity[Inward.onlineClassName])
                    # puts "ModifiedEntities inwardEntities size : #{inwardEntities.size}"
                    inwardOfflineEntity = offlineEntity.getInward(policyEntity['proposalNum'], "APPLICATION_SUSPENSE")
                    if inwardEntities.size > 0
                        inwardEntities.each do |inwardEntity|
                            inwardEntity = MobiSys::MobiSysEntitySchema.from_hash('Inward',inwardEntity)
                            if inwardOfflineEntity.to_s != "" && inwardOfflineEntity.guid == inwardEntity.guid
                                inwardOfflineEntity.merge(inwardEntity)
                                inwardOfflineEntity.persist('fromSync')
                                if inwardOfflineEntity.respond_to?('afterSync'.to_sym)
                                    inwardOfflineEntity.afterSync
                                end
                            else

                                inwardEntity.persistAll 
                                if inwardEntity.respond_to?('afterSync'.to_sym)
                                   inwardEntity.afterSync
                                end
                            end
                        end
                    end
                end



            elsif entityName == Quotation.onlineClassName
                quotationEntity = subEntity
                offlineEntity = offlineEntities[quotationEntity['guid']]
                
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash('Quotation',quotationEntity)
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
                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                    if serviceSignatureEntities.size > 0
                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                        serviceSignatureEntities.each do |serviceSignatureEntity|
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => quotationEntity['guid']})
                            unless signatureContainer
                                signatureContainer = SignatureContainer.new
                                signatureContainer.entityTypeCd = 'Quotation'                                    
                                signatureContainer.entityGuid = quotationEntity['guid']
                            end 
                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                            dbServiceSignatureEntity = nil
                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                else
                                    # mark removed if not in validServiceSignatureGuids
                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                end
                            end
                            if  dbServiceSignatureEntity != nil
                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            else
                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            end
                            signatureContainer.persistAll('fromSync')
                        end
                    else
                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => quotationEntity['guid']})
                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                            serviceSignatureOfflineEntity.removed = "YES"
                        end
                        signatureContainer&.persistAll('fromSync')
                    end
                end
            elsif entityName == Lead.onlineClassName
                leadEntity = subEntity
                offlineEntity = offlineEntities[leadEntity['guid']]
                
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash('Lead',leadEntity)
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
                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                    if serviceSignatureEntities.size > 0
                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                        serviceSignatureEntities.each do |serviceSignatureEntity|
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => leadEntity['guid']})
                            unless signatureContainer
                                signatureContainer = SignatureContainer.new
                                signatureContainer.entityTypeCd = 'Lead'                                    
                                signatureContainer.entityGuid = leadEntity['guid']
                            end 
                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                            dbServiceSignatureEntity = nil
                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                else
                                    # mark removed if not in validServiceSignatureGuids
                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"

                                end
                            end
                            if  dbServiceSignatureEntity != nil
                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            else
                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            end
                            signatureContainer.persistAll('fromSync')
                        end
                    else
                        signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => leadEntity['guid']})
                        signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                            serviceSignatureOfflineEntity.removed = "YES"
                        end
                        signatureContainer&.persistAll('fromSync')
                    end
                end
            elsif entityName == FNARequest.onlineClassName
                fnaRequestEntity = subEntity
                offlineEntity = offlineEntities[fnaRequestEntity['guid']]
                
                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash('FNARequest',fnaRequestEntity)
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
                if mainEntity[ServiceSignature.onlineClassName].to_s != ''
                    serviceSignatureEntities =  Rho::JSON.parse(mainEntity[ServiceSignature.onlineClassName])
                    if serviceSignatureEntities.size > 0
                        validServiceSignatureGuids = serviceSignatureEntities.map { |e| e['guid'] }.to_set
                        serviceSignatureEntities.each do |serviceSignatureEntity|
                            signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => fnaRequestEntity['guid']})
                            unless signatureContainer
                                signatureContainer = SignatureContainer.new
                                signatureContainer.entityTypeCd = 'FNARequest'                                    
                                signatureContainer.entityGuid = fnaRequestEntity['guid']
                            end 
                            serviceSignatureEntityResponse = MobiSys::MobiSysEntitySchema.from_hash('ServiceSignature',serviceSignatureEntity)
                            dbServiceSignatureEntity = nil
                            signatureContainer.ServiceSignatureList.each do |serviceSignatureOfflineEntity|
                               
                                if serviceSignatureOfflineEntity.guid == serviceSignatureEntityResponse.guid
                                    dbServiceSignatureEntity = serviceSignatureOfflineEntity
                                else
                                    # mark removed if not in validServiceSignatureGuids
                                    serviceSignatureOfflineEntity.removed = validServiceSignatureGuids.include?(serviceSignatureOfflineEntity.guid) ? nil : "YES"
                                end
                            end
                            if  dbServiceSignatureEntity != nil
                                dbServiceSignatureEntity.merge(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            else
                                signatureContainer.addServiceSignature(serviceSignatureEntityResponse)
                                if serviceSignatureEntityResponse.respond_to?('afterSync'.to_sym)
                                    serviceSignatureEntityResponse.afterSync
                                end
                            end
                            signatureContainer.persistAll('fromSync')
                        end
                    end
                else
                    signatureContainer = SignatureContainer.loadObject(:first, :conditions=>{ {:name=>'entityGuid'} => fnaRequestEntity['guid']})
                    signatureContainer&.ServiceSignatureList&.each do |serviceSignatureOfflineEntity|
                        serviceSignatureOfflineEntity.removed = "YES"
                    end
                    signatureContainer&.persistAll('fromSync')
                end
            else
                offlineEntity = offlineEntities[subEntity['guid']]
                className = offlineEntity.class.name.to_s

                onlineEntity = MobiSys::MobiSysEntitySchema.from_hash(className,subEntity)
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
            MobiSys::CommonUtil.clearTaskExceptionList(onlineEntity.guid)
            if  mainEntity[TaskException.onlineClassName].to_s != ''
                taskExceptionEntities = Rho::JSON.parse(mainEntity[TaskException.onlineClassName])
                if taskExceptionEntities.size > 0
                    taskExceptionEntities.each do |taskException|
                        exception = MobiSys::MobiSysEntitySchema.from_hash('TaskException', taskException) 
                        exception.entitySeq = onlineEntity.guid
                        exception.persistAll('fromSync') 
                    end  
                end
            end
        end

        def self.syncReleaseMgmtData(currentAgentReg)
            currUserId = $userId == nil
            userPass = $userPassword == nil
            $userId = currentAgentReg.userId unless $userId 
            $userPassword = currentAgentReg.regPass unless $userPassword
            entityName = "ReleaseManagement"

            #Find lastSyncDate for entity
            lastSyncDate = Time.at(0)
            lastSyncDateAppObject = Application.getValue(entityName + "_" + $userId + '_lastSyncDate')
            if lastSyncDateAppObject
                lastSyncDate = Time.load(lastSyncDateAppObject.value)
            end
            clazz = Class.new do
                include MobiSys::BrowserHelper 
            end
            obj = clazz.new
            inputHash = Hash.new
            entityHash = Hash.new
            exp = entityName + ".onlineClassName"
            className = eval(exp)

            entityHash["systemUpdatedDt"] = lastSyncDate.strftime("%Y-%m-%d %H:%M:%S.%L %z")
            inputHash[className] = ::JSON.generate(entityHash)
            json = ::JSON.generate(inputHash)
            response = obj.doJSONPost('/OfflineReleaseSync.run', json, currentAgentReg.userId, currentAgentReg.regPass)
            resultsHash = Rho::JSON.parse(response)
            resultsHash.each do |key,value|
                next if value.to_s == '' || value.to_s == '[]' || value.empty?
                entities = value
                # entities = Rho::JSON.parse(value)
                count = 0
                db = ::Rho::RHO.get_src_db(entityName)
                db.start_transaction
                begin
                    entities.each do |mainEntity|
                        next if mainEntity[key].to_s == ''
                        subEntity = mainEntity[key][0]
                        # subEntity = Rho::JSON.parse(mainEntity[key])[0]
                        entityObject = MobiSys::MobiSysEntitySchema.from_hash(entityName,subEntity)
                        entityObject.persist('fromSync')
                        if entityObject.respond_to?('afterSync'.to_sym)
                            entityObject.afterSync
                        end
                        count = count + 1
                    end
                    db.commit
                rescue StandardError => se
                    db.rollback
                    log('Error while syncing entities: ' + se.to_s)
                    raise se
                end
                log "@@@@Processed #{count} entites of type " + entityName
            end
            if lastSyncDateAppObject
                Application.updateValue(entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
            else
                Application.create(entityName + "_" + $userId + '_lastSyncDate',Time.dump(Time.now))
            end  
            if currUserId
                $userId = nil
            end
            if userPass
                $userPassword = nil
            end
        end
    end  
end
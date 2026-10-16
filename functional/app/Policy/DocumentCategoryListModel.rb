require 'CommonClasses/BaseModel'

module MobiSys
    
    class DocumentCategoryListModel < BaseModel

        def initialize(io)
            #puts "~~~in ServiceDocumentListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

        def getModel
            documentCategoryContainerList = []
            policy = @baseIO.baseDO
            partyGuid = self.parentBaseDO.partyGuid.to_s
            documentContainer = DocumentContainer.loadObject(
                :first,
                :conditions=>{
                    {:name=>'entityGuid'}=> partyGuid,
                    {:name=>'policyGuid'}=> policy.guid
                },
                :op => 'AND'
            )
            documentCategoryList = []
            partyCategoryDocList = []
            @baseIO.additionalData = {} if (@baseIO.additionalData == nil || (@baseIO.additionalData != nil and !@baseIO.additionalData.is_a?(Hash)))
            if documentContainer
                serviceDocumentList = documentContainer.ServiceDocumentList
                serviceDocumentList.each do |serviceDoc|
                    next if documentCategoryList.include? serviceDoc.docCategoryCd
                    MobiSys::PolicyService.createDocumentCategoryContainer(serviceDoc.docCategoryCd,partyGuid, documentCategoryList,documentCategoryContainerList,serviceDoc.guid)
                end
            end
            party = policy.getPartyByGuid(partyGuid)
            categoriesDerivedFromDT = MobiSys::PolicyService.getDocumentCategoryCd(policy, party)
            if categoriesDerivedFromDT.size >  documentCategoryList.size
                categoriesDerivedFromDT.each do |docCategoryCd|
                    unless documentCategoryList.include?(docCategoryCd)
                        partyDocumentList = MobiSys::PolicyService.createServiceDocument(partyGuid, docCategoryCd)
                        partyCategoryDocList.push({docCategoryCd => partyDocumentList})
                        serviceDocGuid = partyDocumentList[0].uniqueKey
                        MobiSys::PolicyService.createDocumentCategoryContainer(docCategoryCd,partyGuid, documentCategoryList,documentCategoryContainerList,serviceDocGuid)
                    end
                end
            end

            @baseIO.additionalData["ServiceDocumentList"] = partyCategoryDocList

            return documentCategoryContainerList
        end

        def setModel(entity)
            if entity && entity.size > 0
                entity.each do |docContainer|
                    docContainer.docPartyGuid = self.parentBaseDO.partyGuid
                end
            end
            return entity
        end

    end
end
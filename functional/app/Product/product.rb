# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Product
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master

    property :productId,         :string
    property :productVersion,    :string
    property :versionName,       :string
    property :longName,          :string
    property :shortName,         :string
    property :description,       :string
    property :productTypeCd,     :string
    property :productFamilyId,   :string
    property :productStatusCd,   :string
    property :launchDt,          :date
    property :withdrawDt,        :date
    property :productKey,        :string
    property :sortOrder,         :integer
    property :category1Cd,       :string
    property :category2Cd,       :string
    property :category3Cd,       :string
    property :bancsProductId,    :string
    property :productUin,        :string
    property :collateralLevelCd, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time

    has_many 'OfflineFacet'
    has_many 'OfflineProductModelMap'
    has_many 'PrdFieldMetaData'
    
    index :prd_productId, [:productId]
    index :prd_productSeq, [:id]
    index :prdFamilyprdType, [:productFamilyId,:productTypeCd]

    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.ProductDO"
    end

    def afterSync
        #puts "After sync ProductDO called..."
    end
    
    def getFacetFast(facetName)
        # Code for momeization
        @offlineFacet ||= {}
        @offlineFacet[facetName] ||= self.OfflineFacetList.select{|facet| facet.facetId==facetName}.first
    end

    def getFacet(facetName)
        offlineFacet = nil
        self.OfflineFacetList.each do |facet|
            if facet.facetId == facetName
                offlineFacet = facet
                break
            end
        end
        return offlineFacet 
    end
    
    def getFacets(facetName)
        offlineFacet = Array.new
        self.OfflineFacetList.each do |facet|
            if facet.facetId == facetName
                offlineFacet.push(facet)
            end
        end
        return offlineFacet 
    end
      
    def getPremiumDetailsFacet
        return getFacet("PREMIUMDETAILS")
    end

    def getOtherDetailsFacet
        return getFacet("OTHERDETAILS")
    end

    def getRiderAssociationFacet
        return getFacet("RIDERASSOCIATION")
    end

    def getOverrideReturnRatesFacet
        return getFacet("OVERRIDERETURNRATES")
    end
    
    def getFacetValue(facetId)
        facetValue = nil
        if getFacet(facetId) != nil
            facetValue = getFacet(facetId).actionValue
        end
        return facetValue;
    end
    
    def getMinMaxPPTermFacet
        return getFacet("MINMAXPPTERM")
    end
    
    def getMinMaxSumAssuredFaccet
        return getFacet("MINMAXSUMASSURED")
    end
    
    def getTableTypeMappingSeq(facetId)
        ttms = nil
        facet = getFacet(facetId)
        if facet
            if facet.ruleSeq
                ttms = facet.ruleSeq
            elsif facet.OfflineFacetDetailsList.size > 0
                facetDetails = facet.OfflineFacetDetailsList[0]
                ttms = facetDetails.tableTypeMappingSeq if facetDetails
            end   
        end
        return ttms
    end
    
    def getPremiumModel(currencyCd)
        if currencyCd and currencyCd != ""
            self.OfflineProductModelMapList.each do |prdModelMap|
                return prdModelMap if prdModelMap.currencyCd == currencyCd
            end
            return self.OfflineProductModelMapList[0] if self.OfflineProductModelMapListSize > 0
        else
            return self.OfflineProductModelMapList[0] if self.OfflineProductModelMapListSize > 0
        end
        return nil
    end

    def getProductModelMap
        @productmodelmap ||= self.OfflineProductModelMapList.first
    end
    
    # Fetching rider association record based on plan option and applicable role
    def getRiderAssociationDO(riderProductId, productPlanOptionCd, riderPlanOptionCd, riderAsscFacet, riderProductSeq = nil, riderRoleCd='')
        riderAssociationDO = nil
        riderAutoPopulationReqFlag = self.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')
        
        if  riderAsscFacet != nil
            listRiderAssociationDO = riderAsscFacet.OfflineRiderAssociationList
            listRiderAssociationDO.each do |riderAsscDO|
                if (riderProductSeq.to_s != '' && riderProductSeq.to_s == riderAsscDO.productSeq.to_s) || (riderProductId.to_s != '' && riderProductId.to_s == riderAsscDO.productId.to_s)
                    if riderAutoPopulationReqFlag == 'YES' && riderAsscDO.applicableRoles.to_s != ''
                        unless riderAsscDO.applicableRoles.to_s.include? riderRoleCd
                            next
                        end
                    end
                    planOptionMatched = true
                    if riderAsscDO.basePlanOptionCd.to_s != '' && productPlanOptionCd.to_s != ''
                        if riderAsscDO.basePlanOptionCd.to_s == productPlanOptionCd.to_s
                            planOptionMatched = true
                        else
                            planOptionMatched = false
                        end
                    end
                    if riderAsscDO.planOptionCd.to_s != '' && riderPlanOptionCd.to_s != '' 
                        if riderAsscDO.planOptionCd.to_s == riderPlanOptionCd.to_s
                            planOptionMatched = true
                        else
                            planOptionMatched = false
                        end
                    end
                    if planOptionMatched
                        riderAssociationDO = riderAsscDO
                        break
                    end
                end
            end  
        end
        return riderAssociationDO  
    end  

    def getFacetByFacetType(facetTypeCd)
        facetList = []
        self.OfflineFacetList.each do |facet|
            if facet.facetTypeCd.to_s != "" && facet.facetTypeCd.to_s == facetTypeCd
                facetList.push(facet)
            end
        end
        return facetList

    end
end

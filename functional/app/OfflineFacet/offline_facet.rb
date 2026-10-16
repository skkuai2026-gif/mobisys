# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineFacet
  include MobiSys::MobiSysFixedSchema
    
    set :schema_version, '1.0'
    set :partition, :master
    
    #add model specifc code here
    property :productseq, :integer
    property :facetId, :string
    property :facetTypeCd, :string
    property :schemeId, :string
    property :agentId, :string
    property :serviceTaxFl, :string
    property :serviceTaxRate, :float
    property :privilegeCd, :string
    property :actionTypeCd, :string
    property :actionValue, :string
    property :ruleSeq, :integer
    property :lookupKey, :string
    property :lookupDataCd, :string
    property :effectiveFromDt, :time
    property :effectiveToDt, :time
    property :facetGroupCd, :string
    property :labelKey, :string
    property :applicableRoles,:string
    
    has_many 'OfflineFacetDetails'
    has_many 'OfflineSingleLife'
    has_many 'OfflineJointLife'
    has_many 'OfflineFamilyFloater'
    has_many 'OfflinePlanOption'
    has_many 'OfflineRiderAssociation'
    has_many 'OfflineOtherDetails'
    has_many 'OfflinePremiumDetails'
    has_many 'OfflineRiderGroupDefinition'
    
    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
    index :oft_parentKey, [:parentKey]
  
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.FacetDO"
    end

    def getFacetDetails
      # Done By Zeeshan - The ||= is for momoization so that the results are cached for the particular instance
      @offlineFacetDetails ||= self.OfflineFacetDetailsList.first
    end

    def getPremiumDetails
      # Done By Zeeshan - The ||= is for momoization so that the results are cached for the particular instance
      @offlinePremiumDetails ||= self.OfflinePremiumDetailsList.first  
    end

    def getRiderAssociation
      # Done By Zeeshan - The ||= is for momoization so that the results are cached for the particular instance
      @offlineRiderAssociation ||= self.OfflineRiderAssociationList
    end

    def getPlanOption
      @offlinePlanOption ||= self.OfflinePlanOptionList
    end

    def getPlanOptionByPlanOptionCd(planOptionCd)
      planOption = nil
      self.OfflinePlanOptionList.each do |planOptionDO|
        if planOptionDO.optionCd == planOptionCd
          planOption = planOptionDO
          break
        end
      end
      return planOption
    end
end

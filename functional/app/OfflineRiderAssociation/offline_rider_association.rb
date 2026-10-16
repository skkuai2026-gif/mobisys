# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineRiderAssociation
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with RiderAssociation.
	# enable :sync

	#add model specifc code here
	property :parentproductSeq, :integer
	property :facetSeq, :integer
	property :effectiveFromDt, :date
	property :effectiveToDt, :date
	property :productSeq, :integer
	property :productId, :string
	property :productVersion, :integer
	property :associationRelationTTmapSeq, :integer
	property :followsBaseProductFl, :string
	property :waivePremiumForWOPFl, :string
	property :saPercTableTypeMapSeq, :integer
	property :basePlanOptionCd, :string
	property :planOptionCd, :string
	property :premiumPercTableTypeMapSeq, :integer
	property :minMaxTermTableTypeMapSeq, :integer
	property :ppTermTableTypeMapSeq, :integer
	property :groupId, :string
	property :termAsPlan, :string
	property :pptAsPlan, :string
	property :supplLifeAppl, :string
	property :jointLifeAppl, :string
	property :evaluateUWRules, :string
	property :builtInRiderFl, :string
	property :linkedFl, :string
	property :riderModelCd, :string
	property :entryAgeTableTypeMapSeq, :integer
	property :sortOrder, :integer
	property :labelKey, :string
	property :impactedRiders, :string
	property :applicableRoles, :string
	property :impactedFields, :string
	property :dependentRiderRoleCd, :string
	property :inputDataElement, :string

	# derived attributes
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	index :ora_parentKey, [:parentKey]

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.RiderAssociationDO"
	end

	def getLabelKey(facetId)
		facetIdLabelKeyMap = {}
		labelKey = ""
		facetIdLabelKeyMapList = self.labelKey.to_s.split(",")
		facetIdLabelKeyMapList.each do |facetIdLabelKey|
			index = facetIdLabelKey.index("-")
			facetIdLabelKeyMap[facetIdLabelKey[0..index-1]] = facetIdLabelKey[index + 1..facetIdLabelKey.size] if index
		end
		labelKey = facetIdLabelKeyMap[facetId] if facetIdLabelKeyMap.has_key?(facetId)
		return labelKey
	end
end
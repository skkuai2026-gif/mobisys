# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OfflineRiderGroupDefinition
	include MobiSys::MobiSysFixedSchema
	  
	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with RiderGroupDefinition.
	# enable :sync

	#add model specifc code here
	property :facetSeq, :integer
	property :groupId, :string
	property :minRider, :integer
	property :maxRider, :integer
	#property :minSA, :float
	#property :maxSA, :float
	property :saflatAmountPercentFl, :string
	property :premiumflatAmountPercentFl, :string
	property :minPremium, :float
	property :maxPremium, :float
	property :roleCd, :string
	property :minMaxTTSeq, :integer
	property :labelKey, :string

	# derived attributes
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	index :orgd_parentKey, [:parentKey]

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.product.RiderGroupDefinitionDO"
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
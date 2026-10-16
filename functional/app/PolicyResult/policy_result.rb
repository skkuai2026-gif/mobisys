# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class PolicyResult
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with PolicyTopUp.
	# enable :sync

	#add model specifc code here
	property :uwTypeCd, :string
	property :riskCd, :string
	property :ruleName, :string
	property :iterationNo, :integer
	property :decisionCd, :string
	property :decisionValue, :string
	property :remarksKey, :string
	property :loadingValue, :float
	property :loadingDuration, :integer
	property :extraTypeCd, :string
	property :loadingTypeCd, :string
	property :extraFlatAmt, :float
	property :extraPercent, :float
	property :extraFlatDuration, :integer
	property :extraPercDuration, :integer
	property :categoryCd, :string
	property :policyProductRefGuid, :string
	property :policyProductInsuredRefGuid, :string
	property :partyRoleRefGuid, :string
	property :partyRefGuid, :string
	property :parentRiskCd, :string
	property :documentCd, :string
	property :reasonCd, :string
	property :exclusionTypeCd, :string
	property :event, :string
	property :benefit, :string
	property :cause, :string
	property :periodTypeCd, :string
	property :periodUnit, :string
	property :icdCd, :string
	property :icdDesc, :string
	property :policySeq, :integer
	property :sortOrder, :integer
	property :rollupFacetId, :string
	property :exclLoadingTypeCd, :string
	property :exclPeriodTypeCd, :string
	property :exclPeriodUnit, :string
	property :exclValue, :float
	property :exclDuration, :integer

	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string

	attr_accessor :entityDesc
	attr_accessor :stackTrace

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyResultDO"
	end
end

begin 
    require 'PolicyResult/policy_result_company'
rescue LoadError => e
    puts 'policy_result_company not included'
end

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class PolicyProductInsured
	include MobiSys::MobiSysEntitySchema
	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with Label.
	# enable :sync

	#add model specifc code here
	property :partyId, :string
	property :uwClassCd, :string
	property :issueAge, :int
	property :insuredSequenceTypeCd, :string
	property :uwDecisionCd, :string
	property :uwDecisionValue, :string
	property :unit, :string
	property :reason, :string
	property :ageExtra, :int
	property :tsarValue, :int
	property :financialTsarValue, :int
	property :totSumAssured, :int
	property :decisionCd, :string

	property :roleCd, :string
	property :insuredPartyRefGuid, :string
	property :customerId, :string
	property :policyProductSeq, :integer
	property :refGuid, :string

	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyProductInsuredDO"
	end
end

begin
	require 'PolicyProductInsured/policy_product_insured_company'
rescue LoadError => e
	puts 'policy_product_insured_company not included'
end
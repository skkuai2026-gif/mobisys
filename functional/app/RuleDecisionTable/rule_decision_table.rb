require "CommonModules/schema_module"

class RuleDecisionTable
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with RuleDecisionTable.
	# enable :sync

	#add model specifc code here
	property :questionSetCd, :int
	property :questionDataElementCd, :string
	property :documentCd, :string
	property :questionnaireTypeCd, :string
	property :entityGuid, :string
	property :partyGuid, :string
	property :rowGuid, :string
	property :responseValue, :string
	property :score, :string
	property :weight, :string
	property :parentQuestionSeq, :string

	# derived attributes  
	property :userId, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.systemcommon.dataobjects.service.RuleDecisionTableDO"
	end

	def afterSync
		# puts "After sync called for RuleDecisionTable"   
	end 
end

begin
	require 'RuleDecisionTable/rule_decision_table_company'
rescue LoadError => e
	puts 'rule_decision_table_company not included'
end
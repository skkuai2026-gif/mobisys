require "CommonModules/schema_module"

class RuleDefinition
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master

	# Uncomment the following line to enable sync with RuleDefinition.
	# enable :sync

	#add model specifc code here
	property :definitionCd, :string
	property :description, :string
	property :versionNum, :integer
	property :definitionTypeCd, :string
	property :vocabularyCodes, :string

	# derived attributes  
	property :userId, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.RuleDefinitionDO"
	end
	
	def afterSync
		# puts "After sync called for RuleDefinition"   
	end 
end

begin
	require 'RuleDefinition/rule_definition_company'
rescue LoadError => e
	puts 'rule_definition_company not included'
end
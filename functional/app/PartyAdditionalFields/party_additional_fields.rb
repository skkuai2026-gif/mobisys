# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyAdditionalFields
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
	  
	# Uncomment the following line to enable sync with Label.
	# enable :sync

	#add model specifc code here
	property :field1, :string
	property :field2, :string
	property :field3, :string
	property :field4, :string
	property :field5, :string
	property :field6, :string
	property :field7, :string
	property :field8, :string
	property :field9, :string
	property :field10, :string
	property :field11, :string
	property :field12, :string
	property :field13, :string
	property :field14, :string
	property :field15, :string
	property :field16, :string
	property :field17, :string
	property :field18, :string
	property :field19, :string
	property :field20, :string
	property :field21, :string
	property :field22, :string
	property :field23, :string
	property :field24, :string
	property :field25, :string
	property :field26, :string
	property :field27, :string
	property :field28, :string
	property :field29, :string
	property :field30, :string
	property :field31, :string
	property :field32, :string
	property :field33, :string
	property :field34, :string
	property :field35, :string
	property :field36, :string
	property :field37, :string
	property :field38, :string
	property :field39, :string
	property :field40, :string
	property :field41, :string
	property :field42, :string
	property :field43, :string
	property :field44, :string
	property :field45, :string
	property :field46, :string
	property :field47, :string
	property :field48, :string
	property :field49, :string
	property :field50, :string
	property :partyAddtnField51Dt, :date
	property :partyAddtnField52Dt, :date

	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string


	#online-offline sync methods
	def self.onlineClassName
	    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyAdditionalFieldsDO"
	end

	def self.entitiesForSync
	end

	def afterSync
		#puts "After sync called for Party Additional Fields"
	end

	#Method to indicate that this class is extended for context evaluation.
  	def isParentExtendingContext
    	return true
  	end 
end

begin 
    require 'PartyAdditionalFields/party_additional_fields_company'
rescue LoadError => e
    puts 'party_additional_fields_company not included'
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Inward  
    include MobiSys::MobiSysEntitySchema
    
  	set :schema_version, '1.0'
  
	# Uncomment the following line to enable sync with Lead.
	# enable :sync

	#add model specifc code here
	property :inwardSeq, :integer
	property :inwardDt, :date
	property :receiptPurpose, :string
	property :receiptRefNum, :string
	property :inwardAmount, :float
	property :inwardStatusCd, :string
  	property :inwardTypeCd, :string
  	property :inwardSubTypeCd, :string
  	property :removed, :string
  	property :agentId, :string

	#added for FWDHK
	property :payerTypeCd, :string
	property :payerPartyId, :string
  	property :payerPartyRefGuid, :string
	property :paymentMethodCd, :string
	property :fileName, :string
	property :receiptId, :string
	
	#derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	has_many 'InwardDetails'
	has_many 'InwardPolicy'

    attr_accessor :isMicrApplicable
      

	#online-offline sync methods
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collection.InwardDO"
	end


	def self.entitiesForSync
		entitiesForSync = Inward.loadObject(:all)
	end


	def afterSync
		puts "After sync called for inward " + self.receiptRefNum.to_s    
	end
end
begin 
    require 'Inward/inward_company'
rescue LoadError => e
    puts 'inward_company not included'
end
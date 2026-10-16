# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class PartyFinancialAccount
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
	  
	# Uncomment the following line to enable sync with Label.
	# enable :sync

	#add model specifc code here
	property :accountCategoryCd, :string
	property :accountTypeCd, :string
	property :bankCd, :string
	property :sortCd, :string
	property :branchCd, :string
	property :bankName, :string
	property :branchName, :string
	property :accountNum, :string
	property :accountHolderName, :string
	property :cardTypeCd, :string
	property :cardExpiryDt, :date
	property :cardExpiryMnth, :string
	property :cardExpiryYear, :string
	property :accountName, :string
	property :cash, :string
	property :swiftCd, :string
	property :directDebitType, :string

	#Swati Ahire 06-04-2015: Newly added fields
	property :refundAccountHolderName, :string
	property :ifscCd, :string
	property :amount, :integer
	property :partyFinancialAccountSeq, :integer
	property :paymentTypeCd, :string
	property :micrNum, :string
	property :currency, :string

	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string

	attr_accessor :paymentMethodCd
	attr_accessor :paymentInstructionTypeCd
    attr_accessor :isMicrApplicable

	#online-offline sync methods
	def self.onlineClassName
	    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.party.PartyFinancialAccountDO"
	end

	def self.entitiesForSync
	end

	def afterSync
		#puts "After sync called for party financial"
	end 
end

begin 
    require 'PartyFinancialAccount/party_financial_account_company'
rescue LoadError => e
    puts 'party_financial_account_company not included'
end
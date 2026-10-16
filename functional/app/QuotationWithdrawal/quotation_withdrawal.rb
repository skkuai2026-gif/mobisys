# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationWithdrawal
 	include MobiSys::MobiSysEntitySchema

 	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with QuotationWithdrawal.
	# enable :sync

	#add model specifc code here
	property :policyYearFrom, :integer
	property :policyYearTo, :integer
	property :withdrawalAmount, :float, :decimal
	property :ageFrom, :integer
	property :ageTo, :integer
	property :frequencyVal, :integer
	property :dateFrom, :date
	property :dateTo, :date
	property :catgTypeCd, :string
	property :catgSubTypeCd, :string
	property :frequencyTypeCd, :string
	property :wthdAddtnlField1, :string
	property :withdrawalPercent, :float


	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time
	property :removed, :string

	# online attributes
	property :quotationSeq, :string
	property :ageFrom, :integer
	property :ageTo, :integer
	property :frequencyVal, :integer

	def self.onlineClassName
	  return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationWithdrawalDO"
	end

end

begin 
    require 'QuotationWithdrawal/quotation_withdrawal_company'
rescue LoadError => e
    puts 'quotation_withdrawal_company not included'
end
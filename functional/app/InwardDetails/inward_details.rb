# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class InwardDetails  
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with InwardDetail.
	# enable :sync

	#add model specifc code here
	property :inwardSeq, :integer
	property :inwardNum, :string
	property :bankCd, :string
	property :bankBranch, :string
	property :accountNum, :string
	property :inwardAmount, :float, :decimal
	property :micrNum, :string
	property :instrumentDt, :date
	property :statusCode, :string
	property :instrumentStatusCd, :string
	property :refVoucherNo, :string
    property :removed, :string

	#added for FWDHK
	property :payerSameAs, :string
	property :relationship, :string
	property :instrumentNum, :string
	property :bankName, :string
	property :accountCategoryCd,:string
	property :cardTypeCd, :string
	property :creditCardNum, :string
	property :cardHolderName, :string
	property :cardExpiryMnth, :string
	property :cardExpiryYear, :string
	property :approvalCd, :string
	property :bankRefNum, :string
	property :serialNum, :string
	property :policyNo1, :string
	property :policyNo2, :string
	property :policyNo3, :string
	property :paymentCurrency, :string
	property :currencyAmount, :integer
	property :paymentMethodCd, :string
	property :paymentSubTypeCd, :string
	property :accountName, :string
	property :paymentFrequencyCd, :string
	property :currency, :string
	
	property :issuingBank,	:string
	property :swiftCd, :string
	property :directDebitType, :string
	property :sortCode, :string
	property :ifscCd, :string
	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	attr_accessor :entityDesc

    def getEntityDesc
    	if self.entityDesc == nil
        	self.entityDesc = "Initial"
        end
    end
	#online-offline sync methods
  	def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.collection.InwardDetailsDO"
  	end

  	def self.entitiesForSync
        entitiesForSync = InwardDetail.loadObject(:all)
  	end


  	def afterSync
        puts "After sync called for inward detail " + self.inwardNum.to_s    
  	end
end

begin 
    require 'InwardDetails/inward_details_company'
rescue LoadError => e
    puts 'inward_details_company not included'
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationProductAdditional
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'
	# Uncomment the following line to enable sync with QuotationProductAdditional.
	# enable :sync

	#add model specific code here
	property :prdAddtnField1str, :string
	property :prdAddtnField2str, :string
	property :prdAddtnField3str, :string
	property :prdAddtnField4str, :string
	property :prdAddtnField5str, :string
	property :prdAddtnField6d, :float
	property :prdAddtnField7d, :float
	property :prdAddtnField8d, :float
	property :prdAddtnField9d, :float  
	property :prdAddtnField10d, :float  
	property :prdAddtnField11d, :float  
	property :prdAddtnField12d, :float  
	property :prdAddtnField13d, :float  
	property :prdAddtnField14d, :float  
	property :prdAddtnField15d, :float  
	property :prdAddtnField16dt, :date  
	property :prdAddtnField17dt, :date  
	property :prdAddtnField18dt, :date 
	property :prdAddtnField19dt, :date  
	property :prdAddtnField20dt, :date  
	property :productRefGuid, :string  

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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationProductAdditionalDO"
	end

	    
    #Method to indicate that this class is extended for context evaluation.
    def isParentExtendingContext
        return true
    end 

		
end

begin 
	require 'QuotationProductAdditional/quotation_product_additional_company'
rescue LoadError => e
	puts 'quotation_product_additional_company not included'
end 
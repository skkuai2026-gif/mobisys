# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class QuotationAdditionalFields
    include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.0'
        
    property :quotationAdditionalFieldsSeq, :integer
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
    property :policyField30, :string
    property :policyField31, :string
    property :policyField32, :string
    property :policyField33, :string
    property :policyField34, :string
    property :policyField35, :string
    property :policyField36, :string
    property :policyField37, :string
    property :policyField38, :string
    property :policyField39, :string
    property :policyField40, :string

    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time


    def self.onlineClassName
        return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationAdditionalFieldsDO"
    end

    # def self.entitiesForSync
    # end

        
    #Method to indicate that this class is extended for context evaluation.
    def isParentExtendingContext
        return true
    end 

end

begin 
    require 'QuotationAdditionalFields/quotation_additional_fields_company'
rescue LoadError => e
    puts 'quotation_additional_fields_company not included'
end
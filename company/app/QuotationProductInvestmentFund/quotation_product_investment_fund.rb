# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationProductInvestmentFund
  include MobiSys::MobiSysEntitySchema

    set :schema_version, '1.0'
        
    # Uncomment the following line to enable sync with Label.
    # enable :sync
  
    #add model specific code here

    property :quotationProductInvestmentFundSeq, :integer
    property :fundCd,         :string
    property :allocationPerc, :float

    property :topupAllocationPerc, :integer 
    property :expiryDt, :date
    property :fundTypeCd, :string
    property :maturityDt, :date
    
    # not synced
    property :fmc,            :integer
    property :fundValue,      :integer
    property :fmcValue,       :integer

    # online attributes
    property :quotationProductSeq, :string
    property :topupAllocationPerc, :float
    property :expiryDt, :date
    property :fundTypeCd, :string
    property :sortOrder, :integer

    
    # derived attributes
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string

    attr_accessor :fundDesc, :fundMedia, :fundRiskClassLabel, :addtnlFld1Str, :addtnlFld2Str
        
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationProductInvestmentFundDO"
    end
end

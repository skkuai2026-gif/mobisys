# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
class QuotationTopUp
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with QuotationTopUp.
  # enable :sync

  #add model specifc code here
  
  property :policyYearFrom, :integer
  property :policyYearTo, :integer
  property :topUpAmount, :float, :decimal
  property :topUpTypeCd, :string
  property :topupFrequencyVal, :integer
  property :topupFrequencyValUnit, :string
  property :ageFrom, :string
  property :ageTo, :string

  property :topUpPeriod, :integer
  
  # online attributes
  property :quotationSeq, :string
  # property :topUpPeriod, :integer

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
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationTopUpDO"
  end
end

begin 
    require 'QuotationTopUp/quotation_top_up_company'
rescue LoadError => e
    puts 'quotation_top_up_company not included'
end 
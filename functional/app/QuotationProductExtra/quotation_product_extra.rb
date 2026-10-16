# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

class QuotationProductExtra
  include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with QuotationProductExtra.
  # enable :sync

  #add model specifc code here
  property :extraTypeCd, :string
  property :decisionCd, :string
  property :loadingTypeCd, :string
  property :processingTypeCd, :string
  property :extraFlatAmt, :float, :decimal
  property :extraPercent, :float
  property :extraFlatDuration, :integer
  property :extraPercDuration, :integer

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
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationProductExtraDO"
  end
    
end

begin 
    require 'QuotationProductExtra/quotation_product_extra_company'
rescue LoadError => e
    puts 'quotation_product_extra_company not included'
end 
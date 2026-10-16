# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'

# You can add more methods here
class QuotationProductWithdrawal
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with QuotationProductWithdrawal.
  # enable :sync

  #add model specifc code here
  property :policyYearFrom, :integer
  property :policyYearTo, :integer
  property :withdrawalAmount, :integer
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time


    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationProductWithdrawalDO"
    end
end

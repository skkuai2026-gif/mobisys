# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNALifeProtectionNeed

  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNALifeProtectionNeed.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :integer
  property  :montlyExpenseAmt, :integer, :decimal
  property  :expenseYears, :integer  
  property  :protectionNeedPVAmt, :integer, :decimal
  property  :educationNeedPVAmt, :integer, :decimal
  property  :otherLiabilitiesAmt, :integer, :decimal
  property  :existingAssetAmt, :integer, :decimal
  property  :existingCoverageAmt, :integer, :decimal
  property  :noOfChildren, :integer
  property  :shortfallAmt, :integer, :decimal
  property  :removed, :string
  property  :CalculatorTypeCd, :string  
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  #attr_accessor :entityDesc
 
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNALifeProtectionNeedDO"
  end
  
end

begin 
  require 'FNALifeProtectionNeed/f_n_a_life_protection_need_company'
rescue LoadError => e
  puts 'f_n_a_life_protection_need_company not included'
end 

# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class PolicyTopUp
  include MobiSys::MobiSysEntitySchema
    
      set :schema_version, '1.0'

  # Uncomment the following line to enable sync with PolicyTopUp.
  # enable :sync

  #add model specifc code here
  property :guid, :string
  property :policyYearFrom, :integer
  property :policyYearTo, :integer
  property :topUpTypeCd, :string
  property :topUpAmount, :float, :decimal
  property :topupFrequencyVal, :float
  property :topupFrequencyValUnit, :string
  property :ageFrom, :string
  property :ageTo, :string
  
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
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.policy.PolicyTopUpDO"
  end
    

  #################################New Properties################################# 
   property :topUpPeriod, :integer
end

begin 
  require 'PolicyTopUp/policy_top_up_company'
rescue LoadError => e
  puts 'policy_top_up_company not included'
end

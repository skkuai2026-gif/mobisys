# The model has already been created by the framework, and extends Rhom::RhomObject

require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class FNARulesDT
  include MobiSys::MobiSysEntitySchema
    
  set :schema_version, '1.0'
  set :partition, :master

  #Swati Ahire 28-06-2014
  property :ruleName,         :string
  property :fnaFinancialNeed, :string
  property :fnaAvgMonthIncome,:string 
  #property :fnaFundSource,     :string
  property :fnaGoalDuration, :string
  property :result, :string 
  
  # derived attributes  
   property :userId,       :string
   property :parentKey,    :string
   property :versionID,    :integer
   property :id,           :integer
   property :guid,         :string
   property :systemCreatedDt, :time
   property :systemUpdatedDt, :time
   property :priority, :integer

  #add model specific code here
  # model specific methods
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.FNARulesDTDO"
  end
  
  def afterSync
    #puts "After sync called for FNARules " + self.id.to_s    
  end
end

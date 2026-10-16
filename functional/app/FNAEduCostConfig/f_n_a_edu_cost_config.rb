# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAEduCostConfig

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'
	set :partition, :master

  # Uncomment the following line to enable sync with FNAEduCostConfig.
  # enable :sync

  #add model specifc code here
  property  :effectiveFromDt, :time
  property  :countryOfStudyCd, :string
  property  :noOfYears, :integer
  property  :annualTuitionFee, :float
  property  :annualLivingExpenses, :float
  property  :averageInflationRate, :float
  property  :averageYield, :float
  property  :effectiveToDt, :time
	
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAEduCostConfigDO"
  end
  
end

begin 
	require 'FNAEduCostConfig/f_n_a_edu_cost_config_company'
rescue LoadError => e
	puts 'f_n_a_edu_cost_config_company not included'
end 

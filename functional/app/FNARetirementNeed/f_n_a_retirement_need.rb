# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNARetirementNeed

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNARetirementNeed.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :integer
  property  :retirementAge, :integer
  property  :currentAge, :integer
  property  :ageExpectancy, :integer
  property  :monthlyExpensesPVAmt, :integer, :decimal
  property  :monthlyExpensesFVAmt, :integer, :decimal
  property  :totRetirementNeedAmt, :integer, :decimal
  property  :futureContributionAmt, :integer, :decimal
  property  :futureContributionRate, :float, :decimal
  property  :totFutureContributionAmt, :integer, :decimal
  property  :accumulatedAmt, :integer, :decimal
  property  :accumulatedRate, :float, :decimal
  property  :totAccumulatedAmt, :integer, :decimal
  property  :projectReservedAmt, :integer, :decimal
  property  :otherMontlySavingsAmt, :integer, :decimal
  property  :otherMontlySavingsRate, :float, :decimal
  property  :totOtherSavingsAmt, :integer, :decimal
  property  :otherLumpsumAmt, :integer, :decimal
  property  :otherLumpsumRate, :float, :decimal
  property  :totOtherLumpSumAmt, :integer, :decimal
  property  :retirementReservedAmt, :integer, :decimal
  property  :monthlySavingsReqdAmt, :integer, :decimal
  property  :lumsumReqdAmt, :integer, :decimal
  property  :removed, :string
 	
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNARetirementNeedDO"
  end
  
end

begin 
	require 'FNARetirementNeed/f_n_a_retirement_need_company'
rescue LoadError => e
	puts 'f_n_a_retirement_need_company not included'
end 

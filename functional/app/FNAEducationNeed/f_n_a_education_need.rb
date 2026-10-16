# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAEducationNeed

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAEducationNeed.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :string
  property  :childName, :string
  property  :age, :integer
  property  :countryOfStudyCd, :string
  property  :savingPeriod, :integer
  property  :educationNeedFVAmt, :integer, :decimal
  property  :educationFundFVAmt, :integer, :decimal
  property  :monthlySavingsReqdAmt, :float
  property  :lumsumReqdAmt, :float
  property  :FNARequestSeq, :string
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAEducationNeedDO"
  end
  
end

begin 
	require 'FNAEducationNeed/f_n_a_education_need_company'
rescue LoadError => e
	puts 'f_n_a_education_need_company not included'
end 

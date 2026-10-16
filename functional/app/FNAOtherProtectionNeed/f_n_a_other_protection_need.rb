# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAOtherProtectionNeed

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAOtherProtectionNeed.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :float
  property  :hincomeNeededAmt, :integer, :decimal
  property  :hincomeCoveredAmt, :integer, :decimal
  property  :hinsuranceNeededAmt, :integer, :decimal
  property  :hinsuranceCoveredAmt, :integer, :decimal
  property  :sfbNeededAmt, :integer, :decimal
  property  :sfbCoveredAmt, :integer, :decimal
  property  :ciInsuranceNeededAmt, :integer, :decimal
  property  :ciInsuranceCoveredAmt, :integer, :decimal
  property  :addInsuranceNeededAmt, :integer, :decimal
  property  :addInsuranceCoveredAmt, :integer, :decimal
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAOtherProtectionNeedDO"
  end
  
end

begin 
	require 'FNAOtherProtectionNeed/f_n_a_other_protection_need_company'
rescue LoadError => e
	puts 'f_n_a_other_protection_need_company not included'
end 

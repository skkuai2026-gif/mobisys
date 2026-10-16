# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAFund
  include Rhom::PropertyBag

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAParty.
  # enable :sync

  #add model specifc code here
  property :fundCd, :string
  property :allocationPerc, :string
  property :topupAllocationPerc, :float
  property :expiryDt, :date
  property :maturityDt, :date
  property :fundTypeCd, :string
  property :sortOrder, :integer
  property :field1, :string
  property :field2, :string
  property :field3, :string
  property :field4, :string
  property :field5, :string
	
  # derived attributes  
  property :removed, :string
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  attr_accessor :fundDesc, :fundMedia, :fundRiskClassLabel
  
  def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAFundDO"
  end

end

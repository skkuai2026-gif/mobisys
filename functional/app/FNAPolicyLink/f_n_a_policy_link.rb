# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAPolicyLink

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAPolicyLink.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :integer
  property  :policyNum, :string
	
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :removed, :string

  #attr_accessor :entityDesc
 
  def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAPolicyLinkDO"
  end
  
end

begin 
	require 'FNAPolicyLink/f_n_a_policy_link_company'
rescue LoadError => e
	puts 'f_n_a_policy_link_company not included'
end 

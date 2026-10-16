# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAIOSelected
  #include Rhom::PropertyBag

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAIOSelected.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :string
  property  :fnaBaseProductRefGuid, :string
  property  :fnaRiderProductRefGuid, :string
  property  :selectedFlag, :string
  property  :removed, :string
  property  :quotationId, :string
 
	
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAIOSelectedDO"
  end
  
end

begin 
	require 'FNAIOSelected/f_n_a_i_o_selected_company'
rescue LoadError => e
	puts 'f_n_a_i_o_selected_company not included'
end 

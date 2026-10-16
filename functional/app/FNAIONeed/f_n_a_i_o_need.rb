# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAIONeed
  
	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAIONeed.
  # enable :sync

  #add model specifc code here
  property  :fnaRequestRefGuid, :string
  property  :fnaQ1ResponseRefGuid, :string
  property  :fnaQ2ResponseRefGuid, :string
  property  :fnaQ1ResponseCd, :string
  property  :fnaQ2ResponseCd, :string
  property  :productAvailableFl, :string
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
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAIONeedDO"
  end
  
end

begin 
	require 'FNAIONeed/f_n_a_io_need_company'
rescue LoadError => e
	puts 'f_n_a_io_need_company not included'
end 

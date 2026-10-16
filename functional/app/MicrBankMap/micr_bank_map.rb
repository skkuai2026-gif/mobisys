# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module' 
class MicrBankMap
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  set :partition, :master
  
  property :micrNum, :string
  property :bankName, :string
  property :bankBranch, :string
  property :location, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time


  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.MicrBankMapDO"
  end
  
  def self.entitiesForSync
  end
  
  def afterSync
    puts "After sync called MicrBankMap"
  end 

end
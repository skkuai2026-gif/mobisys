# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module' 
class BankBranchMap
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  set :partition, :master
  
  property :bankCd, :string
  property :branchCd, :string
  property :branchName, :string
  property :companyCd, :string
  property :swiftCd, :string
  property :bankBranchAddtnField1, :string
  property :bankBranchAddtnField2, :string
  property :bankBranchAddtnField3, :string
  property :bankBranchAddtnField4, :string
  property :bankBranchAddtnField5, :string
  property :bankBranchAddtnField6, :float
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time


  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.BankBranchMapDO"
  end
  
  def self.entitiesForSync
  end
  
  def afterSync
    puts "After sync called BankBranchMap"
  end 

end
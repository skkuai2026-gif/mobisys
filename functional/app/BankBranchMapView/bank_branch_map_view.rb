# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class BankBranchMapView
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
  set :partition, :master
  
  property :bankBranchCd, :string
  property :bankCd, :string
  property :bankName, :string
  property :bankNameTh, :string
  property :bankBranchName, :string
  property :bankBranchNameTh, :string
  property :fromDt, :date
  #new FWDHK
  property :bankBranchMapSeq, :string
  property :branchCd, :string
  property :branchName, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.BankBranchMapViewDO"
  end
  
  def self.entitiesForSync
  end
  
  def afterSync
    puts "After sync called BankBranchMasterDO"
  end 
  
end

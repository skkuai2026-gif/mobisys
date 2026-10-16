# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class ProvinceZipCodeMap
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
    
  property :provinceDesc, :string
  property :zipCode, :string
  property :zipAmphoeCd, :string
  property :fromDt, :date
  property :toDt, :date
  property :provinceCd, :string
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.ProvinceZipCodeMapDO"
            
          end
          
          def self.entitiesForSync
          end
          
          def afterSync
            puts "After sync called OccupationClassGroupMapDO"
         
          end 
    
end

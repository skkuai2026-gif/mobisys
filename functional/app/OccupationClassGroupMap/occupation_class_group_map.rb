# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class OccupationClassGroupMap
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
    
  property :occupationName, :string
  property :shortDesc, :string  
  property :occupationGroupName, :string
  property :occupationGroupCd, :string
  property :occupationNotForSale, :integer
  #property :occupationsortOrder, :integer
  property :occClassForAddPA, :string
  property :derivedOccupationClass, :string
  property :occupationTypeCd, :string
  property :occupationId, :string 
  property :occupationRate, :int
  property :occupationSortOrder, :int
  property :occNotForSaleWP, :string
  property :occNotForSaleAI, :string
  property :occNotForSaleRCCAI, :string
  property :occNotForSaleADD, :string
  property :occNotForSaleHealth, :string
  property :occHealthMaxLimit, :int
  property :occNotForSaleCIYRT, :string
  property :occRefCd, :string
  property :occupationClass, :string
  property :PAMaxLimit, :float
  
  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  
  
  



  
  def self.onlineClassName
            return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.OccupationClassGroupMapDO"
           end
           
           def self.entitiesForSync
           end
           
           def afterSync
             puts "After sync called ProvinceZipCodeMapDO"
          
           end 
     
  
 
end

require "CommonModules/schema_module"

class PincodeCityStateCountryMapping
    include MobiSys::MobiSysFixedSchema

    set :schema_version, '1.0'
    set :partition, :master
      
    # Uncomment the following line to enable sync with Lookupvalue.
    # enable :sync
  
    #add model specifc code here
    
    property :pinCode, :string
    property :cityCd, :string
    property :cityDesc, :string
    property :stateDesc, :string
    property :stateCd, :string
    property :countryCd, :string

    # derived attributes
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.PincodeCityStateCountryMapViewDO"
  end
             
  def self.entitiesForSync
  end
             
  def afterSync
    puts "After sync called PincodeCityStateCountryMapViewDO"
  end 
    
end

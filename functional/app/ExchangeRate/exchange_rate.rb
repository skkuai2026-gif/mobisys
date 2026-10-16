# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class ExchangeRate
  include MobiSys::MobiSysFixedSchema
  
  set :schema_version, '1.0'
  set :partition, :master
  # Uncomment the following line to enable sync with ExchangeRate.
  # enable :sync

    property :fromCurrency, :string
    property :toCurrency, :string
    property :rate, :double
    property :effectiveDt, :date
     
    #derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :string
    
        
   def self.onlineClassName
     return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.syminterfaceclient.ExchangeRateDO"
   end
   
   def self.entitiesForSync
   end
   
   def afterSync
     puts "After sync called for party" + self.partyId.to_s
   end
end

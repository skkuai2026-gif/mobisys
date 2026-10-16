# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Relegion
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
    
  property :relegionId, :string
  property :relegionShortDesc, :string
  property :relegionDescTh, :string
  property :relegionDescEn, :string
  property :fromDt, :date
  property :toDt, :date

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
         return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.RelegionDO"
       end
       
       def self.entitiesForSync
       end
       
       def afterSync
         puts "After sync called for relegion id"
      
       end 
    
  
end

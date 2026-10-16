# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class Relationship
  include MobiSys::MobiSysFixedSchema

  set :schema_version, '1.0'
    
  property :relationshipCd, :string
  property :relationshipDesc, :string
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
       return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.RelationshipDO"
     end
     
     def self.entitiesForSync
     end
     
     def afterSync
       puts "After sync called for relationship name"
    
     end 
  
end

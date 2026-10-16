# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here

require 'CommonModules/entityschema'

class DocumentContainer
  include MobiSys::MobiSysEntitySchema
  
  set :schema_version, '1.0'
    
  property :entityGuid, :string
  property :entityTypeCd, :string
  property :policyGuid, :string
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  has_many "ServiceDocument"
  has_many 'DocumentContainer'
  # Uncomment the following line to enable sync with QuestionContainer.
  # enable :sync

  #add model specific code here
end

begin 
    require 'DocumentContainer/document_container_company'
rescue LoadError => e
    puts 'document_container_company not included'
end

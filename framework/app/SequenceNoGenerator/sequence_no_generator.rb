# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
class SequenceNoGenerator
  include MobiSys::MobiSysEntitySchema
  set :schema_version, '1.0'
       
  property :deviceUserSeq, :integer
  property :lastNumber, :integer
  property :typeCd, :string
  property :entityLength, :integer
       
             
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  property :removed, :string
  #add model specific code here
  
  def self.getNextNumber(entityType)
    numberGenerator = SequenceNoGenerator.loadObject(:first, :conditions=>{{:name=>'typeCd'}=>entityType})
    unless numberGenerator
      numberGenerator = SequenceNoGenerator.new
      numberGenerator.typeCd = entityType
      numberGenerator.lastNumber = 0
      numberGenerator.deviceUserSeq = AgentReg.getCurrentAgentReg.deviceUserSeq
      numberGenerator.entityLength = 6
      numberGenerator.persistAll
    end
    number = numberGenerator.lastNumber + 1
    numberGenerator.lastNumber = number
    numberGenerator.persistAll
    return "%0#{numberGenerator.entityLength}d"%numberGenerator.deviceUserSeq + "%0#{numberGenerator.entityLength}d"%number
  end
end

begin 
    require 'SequenceNoGenerator/sequence_no_generator_company'
rescue LoadError => e
    puts 'sequence_no_generator_company not included'
end
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
    # numberGenerator.lastNumber = 0
      numberGenerator.deviceUserSeq = AgentReg.getCurrentAgentReg.deviceUserSeq
      numberGenerator.entityLength = 7 if entityType == "POLICY"
      numberGenerator.entityLength = 7 if entityType == "QUOTATION"
      numberGenerator.entityLength = 5 unless entityType == "POLICY" or entityType == "QUOTATION"
    numberGenerator.persist
    end
    #number = numberGenerator.lastNumber + 1
    #numberGenerator.lastNumber = number

    numberGenerator.persist
    #Swati Ahire 15-08-2014: Changed format of quotation reference number

    if (System::get_property('platform') == 'ANDROID')
      deviceType = 'A'
    elsif (System::get_property('platform') == 'APPLE')
      deviceType = 'I'
    elsif (System::get_property('platform') == "WINDOWS_DESKTOP")
      deviceType = 'W'
    else
      deviceType = 'D'
    end

    number = 0;
    r = Random.new

    if entityType == "QUOTATION"
      number = r.rand(1000000...9999999);
      numberGenerator.systemUpdatedDt
      updateDt = numberGenerator.systemUpdatedDt.strftime('%d%m%Y%H%M%S')
      #updateDt = Time.parse(numberGenerator.systemUpdatedDt.to_s).strftime('%d%m%Y%H%M%S')
      tempString = MobiSys::Encryption.decryptContent(numberGenerator.userId)
      if (System::get_property('platform') == 'ANDROID')
        deviceType = 'A8'
      elsif (System::get_property('platform') == 'APPLE')
        deviceType = 'I8'
      elsif (System::get_property('platform') == "WINDOWS_DESKTOP")
        deviceType = 'W8'
      else
        deviceType = 'D8'
      end
      return "#{tempString}#{deviceType}#{updateDt}#{number}"
    elsif entityType.to_s == "POLICY"
      number = r.rand(10000...99999);
      @AgentRegdetails = AgentReg.forUserId($userId)
      if @AgentRegdetails
        @agentId = @AgentRegdetails.agentId
      end
      # @agentId = MobiSys::Encryption.decryptContent(@AgentRegdetails.agentId)
      return "EA"+@agentId+deviceType+Time.now.strftime("%d%m%Y%H%M%S").to_s+number.to_s
    elsif entityType.to_s == "FNA"  || entityType.to_s == "RPQID"
      number = r.rand(10000...99999);
      @AgentRegdetails = AgentReg.forUserId($userId)
      if @AgentRegdetails
        @agentId = @AgentRegdetails.agentId
      end
      # p "deviceType===>#{deviceType} #{number}"
      return "C"+@agentId+deviceType+Time.now.strftime("%d%m%Y%H%M%S").to_s+number.to_s
    else
      number = r.rand(1000000...9999999);
      @AgentRegdetails = AgentReg.forUserId($userId)
      if @AgentRegdetails
        @agentId = @AgentRegdetails.agentId
      end
      # p "deviceType===>#{deviceType} #{number}"
      return "L"+@agentId+deviceType+Time.now.strftime("%d%m%Y%H%M%S").to_s+number.to_s
    end

  end
end

begin
    require 'SequenceNoGenerator/sequence_no_generator_company'
rescue LoadError => e
    puts 'sequence_no_generator_company not included'
end

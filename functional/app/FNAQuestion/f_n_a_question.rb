require "CommonModules/schema_module"

class FNAQuestion
    include MobiSys::MobiSysFixedSchema
  
    set :schema_version, '1.0'
    set :partition, :master
        
    # Uncomment the following line to enable sync with FNAQuestion.
    # enable :sync
  
    #add model specifc code here
    property :questionCd, :string
    property :questionTypeCd, :string
    property :questionGroupName, :string
    property :sortOrder, :integer
    property :questionShortDesc, :string
    property :effectiveFromDt, :date
    property :effectiveToDt, :date

    # derived attributes  
    property :userId, :string
    property :parentKey, :string
    property :versionID, :integer
    property :id, :integer
    property :guid, :string
    property :systemCreatedDt, :time
    property :systemUpdatedDt, :time
    property :removed, :String
    
    def self.onlineClassName
      return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAQuestionDO"
    end
    
    def self.entitiesForSync
    end
    
    def afterSync
      # puts "After sync called for FNAQuestion"   
    end 

    def getChannelMapping
        channelMappings = questionGroupName.split("|")
        agent = AgentReg.getCurrentAgentReg
        channel = agent.channel+agent.subChannel
        labels = channelMappings.select{|c| c.index(channel) }.first.split(":")[1]
        (labels)? labels.split(",") : []
    end
end

begin
    require 'FNAQuestion/f_n_a_question_company'
rescue LoadError => e
    puts 'f_n_a_question_company not included'
end
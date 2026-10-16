require 'CommonClasses/BaseModel'

module MobiSys
	
	class ServiceQuestionResponseListModel < BaseModel

        def initialize(io)
            #puts "~~~in ServiceQuestionResponseListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo("~~~baseIO in ServiceQuestionResponseListModel:#{self.baseIO.inspect}")
            #logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
            serviceQuestionResponseList = []
            questionContainer = QuestionContainer.loadObject(
                                    :first,
                                    :conditions=>{
                                        {:name=>'entityGuid'} => self.parentBaseDO.guid,
                                        {:name=>'policyGuid'} => self.baseIO.baseDO.guid
                                    },
                                    :op=>'AND'
                                )
            if questionContainer
                serviceQuestionResponseList = questionContainer.ServiceQuestionResponseList
                responseArray = serviceQuestionResponseList.select{ |s| s.partyGuid == self.parentBaseDO.guid }
                if responseArray.size != serviceQuestionResponseList.size
                    agentQuestionContainer = QuestionContainer.loadObject(
                            :first,
                            :conditions => {
                                {:name => 'entityGuid'} => @baseIO.baseDO.guid, 
                                {:name => 'policyGuid'} => @baseIO.baseDO.guid,
                                {:name => 'entityTypeCd'} => 'AGENT'
                            },
                            :op => 'AND'
                        )
                    serviceQuestionResponseList = agentQuestionContainer.ServiceQuestionResponseList
                end
            end

            return serviceQuestionResponseList
        end

        def setModel(entity)
            if entity
                questionContainer = QuestionContainer.loadObject(
                                        :first,
                                        :conditions=>{
                                            {:name=>'entityGuid'} => self.parentBaseDO.guid,
                                            {:name=>'policyGuid'} => self.baseIO.baseDO.guid
                                        },
                                        :op=>'AND'
                                    )

                if questionContainer == nil
                    questionContainer = QuestionContainer.new(
                                            :entityGuid     => self.parentBaseDO.guid,
                                            :entityTypeCd   => self.parentBaseDO.roleCd,
                                            :policyGuid     => @baseIO.baseDO.guid 
                                        )
                end

                if questionContainer.ServiceQuestionResponseList.size > 0 && questionContainer.additionalFieldQuest.to_s != 'FORMBASED' 
                    ServiceQuestionResponse.delete_all(
                                    :conditions => {
                                        {:name=>'parentkey'} => questionContainer.object
                                })
                end

                if entity.size > 0
                    entity.each do |serviceQuestionResponse|
                        if serviceQuestionResponse
                            serviceQuestionResponse.partyGuid = self.parentBaseDO.guid if serviceQuestionResponse.partyGuid.to_s == ""
                            serviceQuestionResponse.entityGuid = @baseIO.baseDO.guid if serviceQuestionResponse.entityGuid.to_s == ""
                        end
                    end
                end
                questionContainer.persistAll
            end

            return entity
        end

    end
end

begin 
    require 'Policy/ServiceQuestionResponseListModel_company'
rescue LoadError => e
    puts 'ServiceQuestionResponseListModel_company not included'
end
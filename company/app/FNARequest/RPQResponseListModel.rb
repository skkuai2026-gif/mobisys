require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys

	class RPQResponseListModel < BaseModel
		
		include MobiSys::BrowserHelper

		def getModel
			leadRPQ = self.parentBaseDO
			puts "leadRPQ=======#{leadRPQ.class}=======#{leadRPQ}"
			return nil if leadRPQ == nil
			if leadRPQ != nil
				rpqResponseDOList = leadRPQ.getRPQResponseList
				#RPQResponse.loadObject(:all, :conditions => { :parentKey => leadRPQ.object.to_s })
				rpqResponseDOList = [] if rpqResponseDOList == nil || rpqResponseDOList == ""
				if rpqResponseDOList.size.to_i == 0
					questionList = leadRPQ.rpqQuestionFromLookup
					if questionList && questionList.size.to_i > 0
						questionList.each do |rpqQue|
							rpqQuestionResponseObj = leadRPQ.getQuestionResponserpq(rpqQue.cd)
							rpqQuestionResponseObj.rpqId = leadRPQ.rpqId
							leadRPQ.addLeadRPQ(rpqQuestionResponseObj)
							rpqResponseDOList.push(rpqQuestionResponseObj)
						end
					end
				elsif rpqResponseDOList.size.to_i != 0
					templistrpqrequest = nil
					rpqrisklistmap = {}
					rpqResponseDOList.each do |rpqresponsetemp|
					  if templistrpqrequest.nil?
					    templistrpqrequest = rpqresponsetemp.question
					  else
					    templistrpqrequest += ",#{rpqresponsetemp.question}"
					  end
					  rpqrisklistmap[rpqresponsetemp.question] = rpqresponsetemp
					end
					rpqResponseList = leadRPQ.rpqQuestionFromLookup
					if rpqResponseList && !rpqResponseList.empty?
					  rpqResponseDOList = []
					  rpqResponseList.each do |res|
					    question = res.cd.to_s
					    unless templistrpqrequest.include?(question)
					      rpqresponse = RPQResponseDO.new
					      rpqresponse.rpqId = leadRPQ.rpqId
					      rpqresponse.userId = leadRPQ.userId
					      rpqresponse.question = question
					      leadRPQ.addLeadRPQ(rpqresponse)
						  rpqResponseDOList.push(rpqresponse)
					    else
					      rpqResponseDOList.push(rpqrisklistmap[question])
					    end
					  end
					end
				end
			end
			return rpqResponseDOList
		end

		def setModel(entity)
			leadRPQ = self.parentBaseDO
			entity.each do|ent|
			    if ent.score.to_s != ""
				   leadRPQ.addRPQResponse(ent)
				   leadRPQ.persistAll
			    end 
		    end	
			return entity
	    end		
	end	
end

begin 
    require 'FNARequest/RPQResponseListModelcompany'
rescue LoadError => e
    puts 'RPQResponseListModelcompany not included'
end
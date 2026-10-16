require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class FNARequestAdditionalListModel < BaseModel
		include MobiSys::BrowserHelper

		def initialize(io)
            super(io)
        end

		def getModel
			puts "self.calledFor.to_s========10========#{self.calledFor.to_s}"
			fnaRequest = self.parentBaseDO
			return nil if fnaRequest == nil

			returnFnaRequestAddtnlList = fnaRequest.getFNARequestAdditionalList
			returnFnaRequestAddtnlList = [] if returnFnaRequestAddtnlList.to_s == ""
			if (self.calledFor.to_s.upcase == "ALLDATA")
				questionList = fnaRequest.fnaQuestionFromLookup
				if returnFnaRequestAddtnlList.size.to_i == 0 && self.createNewObject
					if questionList && questionList.size.to_i > 0
						questionList.each do |fnaQues|
							qnaQuestionResponseObj = fnaRequest.getFNARequestAdditional(fnaQues.cd)
							fnaRequest.addFNARequestAdditional(qnaQuestionResponseObj)
							returnFnaRequestAddtnlList.push(qnaQuestionResponseObj)
						end
					end
				elsif (!returnFnaRequestAddtnlList.empty? && returnFnaRequestAddtnlList.size > 0)
            		tempListFNARequest = nil
            		fnaRiskListMap = Hash.new
            		returnFnaRequestAddtnlList.each do |fnaRequestAdditional|
            			if (tempListFNARequest == nil)
							tempListFNARequest = fnaRequestAdditional.field1.to_s
            			else
            				tempListFNARequest = tempListFNARequest + "," + fnaRequestAdditional.field1.to_s
            			end
            			fnaRiskListMap[fnaRequestAdditional.field1.to_s] = fnaRequestAdditional
            		end

					returnFnaRequestAddtnlList = []
					questionList.each do |fnaQues|
						if !tempListFNARequest.include?(fnaQues.cd.to_s) && self.createNewObject
	            			fnaRequestAdditionalObj = fnaRequest.getFNARequestAdditional(fnaQues.cd)
			                fnaRequest.addFNARequestAdditional(fnaRequestAdditionalObj)
			                returnFnaRequestAddtnlList << fnaRequestAdditionalObj
			            else
			            	returnFnaRequestAddtnlList << fnaRiskListMap[fnaQues.cd.to_s]
			            end
            		end
				end
			elsif (self.calledFor.to_s.upcase == "PRIORITYDATA")
				tempFnaReqList = []
				returnFnaRequestAddtnlList.each do |fnaRequestAdditional|
            		if (fnaRequestAdditional.field2.to_s != "")
            			tempFnaReqList << fnaRequestAdditional
            		end
            	end
            	returnFnaRequestAddtnlList = tempFnaReqList
            	returnFnaRequestAddtnlList.sort_by! {|fnaReqAddtnl| fnaReqAddtnl.field2.to_i}
			end

			returnFnaRequestAddtnlList.compact!

            fnaRequest.setFNARequestAdditionalList(returnFnaRequestAddtnlList)
			return returnFnaRequestAddtnlList
		
		end

		def setModel(entity)
			fnaRequest = self.parentBaseDO
			if entity && entity.size > 0
				entity.each do |addtn|
					if addtn.field2.to_s != "" && addtn.field3.to_s == ""
                       self.parentBaseDO.reasonForRecoCd = nil
				    end		
                    addtn.removed = "YES" if addtn.field2.to_s == ""
                    addtn.removed = "" if addtn.field2.to_s != "" && addtn.status.to_s != "N" && addtn.removed.to_s == "YES"
    			end
			end
			return entity
		end
	end	
end

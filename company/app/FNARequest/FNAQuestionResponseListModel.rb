require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys

	class FNAQuestionResponseListModel < BaseModel
		
		include MobiSys::BrowserHelper

		def getModel
			fnaParty = self.parentBaseDO
			return nil if fnaParty == nil
			listFNAQuestionResponse = []
			listFNAQuestionResponse = fnaParty.getQuestionResponseList
			if listFNAQuestionResponse.size.to_i == 0
				questionList = fnaParty.fnaQuestionFromLookup
				if questionList && questionList.size.to_i > 0
					questionList.each do |fnaQue|
						qnaQuestionResponseObj = fnaParty.getQuestionResponse(fnaQue.cd)
						fnaParty.addFNAParty(qnaQuestionResponseObj)
						listFNAQuestionResponse.push(qnaQuestionResponseObj)
					end
				end
			end 
			return listFNAQuestionResponse
		end	
	end	
end

begin 
    require 'FNARequest/FNAQuestionResponseListModel_company'
rescue LoadError => e
    puts 'FNAQuestionResponseListModel_company not included'
end
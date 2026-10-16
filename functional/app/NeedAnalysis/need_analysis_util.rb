require 'singleton'

module MobiSys
	class NeedAnalysisUtil
		def self.getProfileList(needAnalysisDO, facetId)
			profileList = Array.new
			needAnalysisDO.ServiceQuestionList.each do |serviceQuestion|
			  #puts ">>>question: #{serviceQuestion.response} class:#{serviceQuestion.response.class.to_s}"
			  next unless serviceQuestion.response
        questionSetQuestion = QuestionSetQuestion.find(:first,:conditions=>{{:name=>'questionCd'}=>serviceQuestion.questionCd})
        inputType = questionSetQuestion.inputTypeCd
        #puts ">>>inputType: #{inputType}"
        case inputType
        when "COUNT"
          value = serviceQuestion.response.to_i
          sqlString = "select * from ProductDefinitionTable where facetId='#{facetId}' and key='#{serviceQuestion.questionCd}' and value=#{value}"
          #puts ">>>sqlString: #{sqlString}"
          dtList = ProductDefinitionTable.find_by_sql(sqlString)
          profileList.concat dtList
          
          #Load all definition table rows where value matches the range.
          sqlString = "select * from ProductDefinitionTable where facetId='#{facetId}' and key='#{serviceQuestion.questionCd}' and valueFrom <= #{serviceQuestion.response} and valueTo >= #{serviceQuestion.response}"
          #puts ">>>sqlString: #{sqlString}"
          dtList = ProductDefinitionTable.find_by_sql(sqlString)
          profileList.concat dtList
          
        else
          #Load All definition table rows where value matches
          sqlString = "select * from ProductDefinitionTable where facetId='#{facetId}' and key='#{serviceQuestion.questionCd}' and value='#{serviceQuestion.response}'"
          #puts ">>>sqlString: #{sqlString}"
          dtList = ProductDefinitionTable.find_by_sql(sqlString)
          profileList.concat dtList
        end				
			end	
			return profileList
		end
	end		
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'
class QuestionSet
	include MobiSys::MobiSysFixedSchema

	set :schema_version, '1.0'
	set :partition, :master  

	# Uncomment the following line to enable sync with Product.
	# enable :sync

	#add model specifc code here
	property :questionSetCd, :string
	property :questionSetDescription, :string
	property :questionSetTypeCd, :string
	property :header, :string
	property :isGridTypeFl, :string
	property :ruleName, :string
	property :ruleSeq, :integer
	property :childModelCd, :string
	property :childQSetCdModelElement, :string
  
    # derived attributes
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	has_many 'QuestionSet'
	has_many 'QuestionSetQuestion'
	has_many 'ConditionalQuestionSetMap'

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.systemcommon.dataobjects.masters.QuestionSetDO"
	end

	def afterSync
		#puts "After sync ProductDO called..."
	end

	def getQuestionSetQuestion(dataElementCd)
		self.QuestionSetQuestionList.each do |questionSetQuestion|
			return questionSetQuestion if questionSetQuestion.dataElementCd.to_s == dataElementCd
		end
		return nil
	end
end
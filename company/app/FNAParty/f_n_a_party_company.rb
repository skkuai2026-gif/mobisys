# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAParty
  include Rhom::PropertyBag

	include MobiSys::MobiSysEntitySchema

  # Uncomment the following line to enable sync with FNAParty.
  # enable :sync

  #add model specifc code here
	
  def fnaQuestionFromLookup
     # agent = AgentReg.getCurrentAgentReg
     # @@questionSeq ||= FNAQuestion.find(:all, :conditions=>{ { :name => 'questionGroupName',:op => 'like' } => "%#{agent.channel+agent.subChannel}:%" }, :order=>'sortOrder', :orderdir=>'ASC')
     questionList = Lookupvalue.find(:all, :conditions=>{{:name => 'key'} => 'FNA_QUESTIONS'}, :order=>'sortOrder', :orderdir=>'ASC')
     return questionList
  end

  def getQuestionResponseList
    returnQuestionReponse = []
    self.FNAQuestionResponseList.each do |questionResponse|
      returnQuestionReponse.push(questionResponse)
    end
    return returnQuestionReponse
  end
end


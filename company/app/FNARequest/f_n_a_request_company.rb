# The model has already been created by the framework, and extends Rhom::RhomObject
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class FNARequest
  	include MobiSys::MobiSysEntitySchema
  	include BrowserHelper
  	include MobiSys::BrowserHelper

  	property :visitedTabs, :string
    property :leadId,       :string
    property :step, :integer
    property :stepActionTabs, :string
    property :id, :string

    has_many 'FNARequestAdditional'
    has_many 'FNAFund'

    attr_accessor :isRPQApplicable, :quotationSeq, :leadSeq, :isPrioritySelected, :isForexAcrreditation

  	def beforeSync
      	# self.systemUpdatedDt = Time.now
      	# self.persistAll
      	#Do nothing. To be implemented in company layer
    end
    
  	def afterSync
      # self.statusCd = 'SYNCDONE'
      # self.persistAll
  	end

    def fnaQuestionFromLookup
     # agent = AgentReg.getCurrentAgentReg
     # @@questionSeq ||= FNAQuestion.find(:all, :conditions=>{ { :name => 'questionGroupName',:op => 'like' } => "%#{agent.channel+agent.subChannel}:%" }, :order=>'sortOrder', :orderdir=>'ASC')
     questionList = Lookupvalue.find(:all, :conditions=>{{:name => 'key'} => 'FNA_QUESTIONS'}, :order=>'sortOrder', :orderdir=>'ASC')
     return questionList
  end

  def getFNARequestAdditional(question)
    returnFnaRequestAddtnl = nil
    self.FNARequestAdditionalList.each do |fnaAddtn|
      if fnaAddtn.field1.to_s == question.to_s
        returnFnaRequestAddtnl = fnaAddtn
        break
      end
    end
    
    if returnFnaRequestAddtnl == nil
      returnFnaRequestAddtnl = FNARequestAdditional.new(:field1=>question)
    end

    return returnFnaRequestAddtnl
  end

  def getFNARequestAdditionalList
    returnFnaRequestAddtnl = []
    self.FNARequestAdditionalList.each do |fnaReqAddtnl|
      returnFnaRequestAddtnl.push(fnaReqAddtnl) if fnaReqAddtnl
    end
    return returnFnaRequestAddtnl
  end

  def getFNAFundByFundCd(fundCd, createNewObject)
    fundDO = nil

    self.FNAFundList.each do |fnaFund|
      if (fnaFund.fundCd.to_s == fundCd.to_s)
        fundDO = fnaFund
        break
      end
    end

    if fundDO == nil && createNewObject
      fundDO = FNAFund.new(:fundCd => fundCd.to_s)
    end

    return fundDO
  end
end
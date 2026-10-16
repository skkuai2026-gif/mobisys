# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class FNAParty
  include Rhom::PropertyBag

	include MobiSys::MobiSysEntitySchema
  
	set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNAParty.
  # enable :sync

  #add model specifc code here
	property  :partyRoleCd, :string
	property  :titleCd,  :string
	property  :firstName1, :string
	property  :firstName2, :string
	property  :middleName1, :string
  property  :middleName2, :string
  property  :lastName1, :string
  property  :lastName2, :string
  property  :birthDt, :date
  property  :age, :integer
  property  :genderCd,  :string
  property  :maritalStatusCd, :string
	property  :noOfDependents, :integer
	property  :occupationCd, :string
	property  :industryCd, :string
	property  :natureOfDuty, :string
	property  :educationLevelCd, :string
	property  :contactNum, :string
	property  :mobileNum, :string
  property  :emailAddress, :string
  property  :countryCd,  :string
  property  :addressLine1Lang1, :string
  property  :addressLine2Lang1, :string
  property  :addressLine3Lang1, :string
  property  :addressLine4Lang1, :string
  property  :addressLine5Lang1, :string
  property  :addressLine6Lang1, :string
  property  :addressLine6Lang2, :string
  property  :existingLIDurationCd,  :string
	
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
	
  attr_accessor :entityDesc

  has_many 'FNAQuestionResponse'

  def getEntityDesc
		# self.entityDesc = MobiSys::BrowserHelper.getLabel(self.PartyRoleCd.to_s) + " " + self.firstName1.to_s + " " + self.middleName1.to_s + " " + self.lastName1.to_s
    self.entityDesc = MobiSys::BrowserHelper.getLabel(self.PartyRoleCd.to_s) + self.lastName1.to_s + " " + self.firstName1.to_s
  end
  
  def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAPartyDO"
  end

  def questionSeq
     # agent = AgentReg.getCurrentAgentReg
     # @@questionSeq ||= FNAQuestion.find(:all, :conditions=>{ { :name => 'questionGroupName',:op => 'like' } => "%#{agent.channel+agent.subChannel}:%" }, :order=>'sortOrder', :orderdir=>'ASC')
     @@questionSeq ||= FNAQuestion.find(:all, :order=>'sortOrder', :orderdir=>'ASC')
  end
  
  def getQuestionResponse(question)
    returnQuestionReponse = nil
    self.FNAQuestionResponseList.each do |questionResponse|
      if questionResponse.fnaQuestionCd.to_s == question.to_s
        returnQuestionReponse = questionResponse
        break
      end
    end
    
    if returnQuestionReponse == nil
      returnQuestionReponse = FNAQuestionResponse.new(:fnaQuestionCd=>question)
    end

    return returnQuestionReponse
  end

  def getFNAQuestionResponseGuid(fnaQuestionCdByUser)
      returnGuid = nil
      self.FNAQuestionResponseList.each do |object|
        if object.fnaQuestionCd == fnaQuestionCdByUser
          returnGuid = object.guid
        end
      end
      return returnGuid
  end

end

begin 
	require 'FNAParty/f_n_a_party_company'
rescue LoadError => e
	puts 'f_n_a_party_company not included'
end 

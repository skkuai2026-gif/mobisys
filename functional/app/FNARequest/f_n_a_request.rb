# The model has already been created by the framework, and extends Rhom::RhomObject
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
#require 'Lead/lead'
# You can add more methods here
class FNARequest
  include MobiSys::MobiSysEntitySchema
  include BrowserHelper
  include MobiSys::BrowserHelper
  set :schema_version, '1.0'

  # Uncomment the following line to enable sync with FNARequest.
  # enable :sync

  # add model specific code here
  
  #FNA specific columns
  property :fnaNum,  :string
  property :agentId, :string
  property :requestDt,    :date 
  property :laSameAsApplicantFl, :string
  property :statusCd, :string
  property :witnessId, :string
  property :witnessName, :string
  property :applicantSignDt, :date
  property :applicantSignature, :string
  property :witnessSignDt, :date
  property :witnessSignature, :string
  property :agentSignDt, :date
  property :agentSignature, :string
  property :totSumAssured, :integer, :decimal
  property :inflationRate,  :float
  property :returnRate, :float
  property :reasonForRecommendation, :string
  property :reasonForDeviation, :string
  property :marketingInfoFl, :string 
  property :consentExpiryDt, :date 
  property :consentFl, :string 
  property :reasonForRecoCd, :string
  property :nonDisclosureofAssets, :string
  property :causeForDeviation, :string
  property :addtnField1Str, :string
  property :addtnField2Str, :string
  property :addtnField3Str, :string
  property :addtnField4Str, :string
  property :addtnField5Str, :string
  property :addtnField6D, :integer, :decimal
  property :addtnField7D, :integer, :decimal
  property :addtnField8D, :float
  property :addtnField9D, :float
  property :addtnField10D, :float
  property :addtnField11DT, :date
  property :addtnField12DT, :date
  property :removed, :string
  
  # derived attributes  
  property :userId,       :string
  property :parentKey,    :string
  property :versionID,    :integer
  property :id,           :integer
  property :guid,         :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time


  has_many 'FNAParty'
  has_many 'FNAIONeed'
  has_many 'FNAIOProduct'
  has_many 'FNAIOSelected'
  has_many 'FNAPolicyLink'
  has_many 'FNARetirementNeed'
  has_many 'FNAOtherTargetNeed'
  has_many 'FNAOtherProtectionNeed'
  has_many 'FNAEducationNeed'
  has_many 'FNALifeProtectionNeed'
	 
  	# model specific methods
	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNARequestDO"
	end
	
	def self.entitiesForSync
		entitiesForSync = FNARequest.loadObject(:all)
	end
	
	def afterSync
	  if self.statusCd.to_s == 'FNASUBMIT'
          self.statusCd = 'SYNCDONE'
          self.persist
      end
	end 

	def questionSeq
		agent = AgentReg.getCurrentAgentReg
		@@questionSeq ||= FNAQuestion.find(:all, :conditions=>{ { :name => 'questionGroupName',:op => 'like' } => "%#{agent.channel+agent.subChannel}:%" }, :order=>'sortOrder', :orderdir=>'ASC')
	# @@questionSeq ||= FNAQuestion.find(:all, :order=>'sortOrder', :orderdir=>'ASC')
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

	def getParty(partyRoleCd)
	  	returnParty = nil      
	  	self.FNAPartyList.each do |party|
		  	if party.partyRoleCd == partyRoleCd
		  	 	returnParty = party
			  	break
		  	end
	  	end    
	  	return returnParty
	end

  def getOtherTargetNeed()
      returnOtherTargetNeed = Array.new
      if self.FNAOtherTargetNeedList.size > 0  
          self.FNAOtherTargetNeedList.each do |otherTargetNeed|
              returnOtherTargetNeed.push(otherTargetNeed)
          end   
      end  
      return returnOtherTargetNeed
  end 

  def getFNAEducationNeed()
      returnEducationNeed = Array.new
      if self.FNAEducationNeedList.size > 0 
          self.FNAEducationNeedList.each do |educationNeed|
              returnEducationNeed.push(educationNeed)
          end  
      end  
      return returnEducationNeed
  end   

  def getFNAIOProduct()
      returnFNAIOProduct = Array.new
      if self.FNAIOProductList.size > 0 
          self.FNAIOProductList.each do |iOProduct|
              returnFNAIOProduct.push(iOProduct)
          end  
      end  
      return returnFNAIOProduct
  end

  def getFNAIOProductIDList()
      productIdList = Array.new
      if self.FNAIOProductList.size > 0
          self.FNAIOProductList.each do |iOProduct|
              productIntroducedList = iOProduct.productIntroduced.split(",") if iOProduct.productIntroduced.to_s != ""

              if productIntroducedList.to_s != ""
                productIntroducedList.each do |id|
                    productIdList.push(id) if !productIdList.include?(id)
                end
              end
          end 
      end
      return productIdList
  end
  

  def getFNAIOSelected()
      returnFNAIOSelected = Array.new
      if self.FNAIOSelectedList.size > 0 
          self.FNAIOSelectedList.each do |iOSelect|
              returnFNAIOSelected.push(iOSelect)
          end  
      end  
      return returnFNAIOSelected
  end 

  def get_product_ref_guid(io_product)
      @fnaProductlist = []
      @fnaProductlist = FNAProduct.find(
          :all,
          :conditions => {
              { :name => 'guid', :op => 'IN'} => io_product.fnaProductRefGuid.split(",")
          },
          :op => 'AND',
          :select => ['productId', 'guid', 'object', 'shortName', 'productTypeCd']
      )

      return  @fnaProductlist
  end

  def get_product_id_by_guid(guid)
      @fnaProductId = FNAProduct.find(
          :first,
          :conditions => {
              { :name => 'guid'} => guid
          },
          :op => 'AND',
          :select => ['productId', 'guid', 'object', 'shortName', 'productTypeCd'])
      return  @fnaProductId
  end

  def get_product_plans(ioproduct)
    @productsRecommendedList = FNAProduct.find(
        :first,
        :conditions => {
            { :name => 'guid', :op => 'IN'} => ioproduct
        },
        :op => 'AND',
        :select => ['productId', 'guid', 'object', 'shortName', 'productTypeCd'])
    return @productsRecommendedList.productTypeCd
  end	

end

begin
	require 'FNARequest/f_n_a_request_company'
rescue LoadError => e
	puts 'f_n_a_request_company not included'
end

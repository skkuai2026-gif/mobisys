require 'CommonClasses/BaseModel'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
	
	class QuotationModel < BaseModel
		include MobiSys::BrowserHelper

		#Neha Comments Done
		#create attribute accessor for attributes of xml
		# def initialize(io)
		# 	puts "~~~in QuotationModel initialize: #{io.inspect}"
		# 	# self.baseIO = io
        # 	super(io)
		# 	puts "~~~baseIO:#{self.baseIO}"
		# end

		def getModel
			# logInfo "~~~baseIO in getQuotationModel:#{self.baseIO.inspect}"
			unless self.baseIO.baseDO
				self.baseIO.baseDO = Quotation.new if self.createNewObject
				if self.baseIO.baseDO
					self.baseIO.baseDO.quotationDt = Time.now.strftime("%d/%m/%Y") if self.baseIO.baseDO.quotationDt.to_s == ""
					self.baseIO.baseDO.insuranceTypeCd = "LIFE" if self.baseIO.baseDO.insuranceTypeCd.to_s == ""
				end
			end
        	agentRegdetails = AgentReg.getCurrentAgentReg 

			self.baseIO.baseDO.proposerLASame = "YES" if self.baseIO.baseDO != nil and self.baseIO.baseDO.proposerLASame.to_s != "" and self.baseIO.baseDO.proposerLASame.to_s == "COPYFROMINSURED"
        	self.baseIO.baseDO.proposerLASame = "NO" if self.baseIO.baseDO != nil and self.baseIO.baseDO.proposerLASame.to_s != "" and self.baseIO.baseDO.proposerLASame.to_s == "OTHER"
        	isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
	        if self.baseIO.baseDO != nil && isAgeEditableFl.to_s != ''
	            self.baseIO.baseDO.isAgeEditableFl = isAgeEditableFl
	        end

	        isEditableQuoRefNumFl = MobiSys::BrowserHelper.getFacetMappedValue('ISEDITABLEQUOREFNUMFL',$currentProduct)
	        if self.baseIO.baseDO != nil && isEditableQuoRefNumFl.to_s != ''
	            self.baseIO.baseDO.isEditableQuoRefNumFl = isEditableQuoRefNumFl
	        end

	        isQuotationDtEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('BACKDATINGALLOWED',$currentProduct)
	        if self.baseIO.baseDO != nil && isQuotationDtEditableFl.to_s != ''
	            self.baseIO.baseDO.isQuotationDtEditableFl = isQuotationDtEditableFl
	        end
	        p "inside quo model sunph****company******"
			# self.baseIO.baseDO.channel = agentRegdetails.channel if agentRegdetails && self.baseIO.baseDO && self.baseIO.baseDO.leadId.to_s == ""
			if agentRegdetails && self.baseIO.baseDO && self.baseIO.baseDO.leadId.to_s == ""
				self.baseIO.baseDO.channel = agentRegdetails.channel 
	        	self.baseIO.baseDO.agentId = agentRegdetails.agentId
	        end
	        baseProduct = self.baseIO.baseDO.getBaseProduct if self.baseIO.baseDO != nil
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
	       
			return self.baseIO.baseDO
		end

		def setModel(entity)
			entity.insuranceTypeCd = "LIFE" if entity.insuranceTypeCd.to_s == ""
			entity.proposerLASame = "NO" if entity.proposerLASame.to_s == ""
			entity.quotationDt = Time.now.strftime("%d/%m/%Y") if entity.quotationDt.to_s == ""
			entity.proposerLASame = "COPYFROMINSURED" if entity != nil and entity.proposerLASame.to_s == "YES"
			self.baseIO.baseProduct = MobiSys::ProductUtil.getProduct(entity.productSeq.to_s) if entity.productSeq.to_s != ""
			return entity
		end

	end
	
end

begin 
    require 'Quotation/QuotationModel_company'
rescue LoadError => e
    puts 'QuotationModel_company not included'
end
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'CommonModules/mobisysbrowserhelper'
class Quotation
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.1'

	# Uncomment the following line to enable sync with Label.
	# enable :sync

	property :proposalVersion, :string

	#add model specifc code here
	property :proposalVersion, :string

	#add model specifc code here
	attr_accessor :entityTypeCd
	attr_accessor :isEappLinkApplicable
	attr_accessor :entityTypeCd
	attr_accessor :allocatedToRole
	attr_accessor :isViewEappApplicable

	def getQuotationPartyByRole(roleCd)
		self.QuotationPartyList.each do |quotationParty|
			return quotationParty if quotationParty.roleCd == roleCd
		end
		return nil
	end

	def self.entitiesForSync
		lastSyncDate = Time.at(0)
		lastSyncDateAppObject = Application.getValue("Quotation_" + $userId + '_lastSyncDate')
		if lastSyncDateAppObject
			lastSyncDate = Time.load(lastSyncDateAppObject.value)
		end
		entitiesForSync = []
		quotations = Quotation.loadObject(:all)
		quotations.each do |quotation|
			if (Time.parse(quotation.systemUpdatedDt) > Time.parse(lastSyncDate.to_s)) && (quotation.leadId.to_s == "" || quotation.proposalNum.to_s != "")
                entitiesForSync.push quotation
            end
		end
		return entitiesForSync
	end

	def afterSync
		puts "After sync called for quotation " + self.quotationRefNum.to_s
		#Deleting generated json files
		if $rhoconfig[:offlineOutputGeneration] && $rhoconfig[:htmlGenerationOnAcceptQuotation]
			fileName = "#{self.class.name.to_s}_#{self.quotationRefNum.to_s}_ACCEPT.json"
			filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
			if File.exist?(filePath)
				FileUtils.rm_r filePath
			end
		end
		primaryPartyGuid = self.getPartyByRole("PRIMARY").guid
		quotationPortfolioModelCode = ""
		unless $rhoconfig[:TABFEATUREREQD]
			self.QuotationProductList.each do |quotationProduct|
				quotationProduct.selected = 'on' if quotationProduct.builtInRiderFl != 'YES' && quotationProduct.productTypeCd == 'RIDER'
				if (self.proposerLASame.to_s == "YES" || self.proposerLASame.to_s == "COPYFROMINSURED") && (quotationProduct.partyRoleCd.to_s == "PRIMARY" || quotationProduct.partyRoleCd.to_s == "PROPCUMINS")
					quotationProduct.insuredPartyRefGuid = primaryPartyGuid
					quotationProduct.partyRoleCd = "PRIMARY"
				end

				if quotationProduct.productTypeCd.to_s == "PLAN"
					quotationPortfolioModelCode = quotationProduct.portfolioModelCd.to_s
				end
			end
			if (self.proposerLASame.to_s == "YES" || self.proposerLASame.to_s == "COPYFROMINSURED")
			  # Update unselectedRiders GUID
			  if self.unselectedRiders.to_s != ""
			    self.unselectedRiders = self.unselectedRiders.to_s.sub(
			      /^[^:]+/,
			      primaryPartyGuid
			    )
			  end
			end
		else 
			self.QuotationProductList.each do |quotationProduct|
				quotationProduct.selected = 'YES' if quotationProduct.builtInRiderFl != 'YES' && quotationProduct.productTypeCd == 'RIDER'
				if (self.proposerLASame.to_s == "YES" || self.proposerLASame.to_s == "COPYFROMINSURED") && (quotationProduct.partyRoleCd.to_s == "PRIMARY" || quotationProduct.partyRoleCd.to_s == "PROPCUMINS")
					quotationProduct.insuredPartyRefGuid = primaryPartyGuid
					quotationProduct.partyRoleCd = "PRIMARY"
				end
				if quotationProduct.productTypeCd.to_s == "PLAN"
					quotationPortfolioModelCode = quotationProduct.portfolioModelCd.to_s
				end

			end
			if (self.proposerLASame.to_s == "YES" || self.proposerLASame.to_s == "COPYFROMINSURED")
			  if self.unselectedRiders.to_s != ""
			    self.unselectedRiders = self.unselectedRiders.to_s.sub(
			      /^[^:]+/,
			      primaryPartyGuid
			    )
			  end
			end
		end

		self.quoteStatusCd = MobiSys::QuotationBO::SYNCDONE if self.quoteStatusCd == "ACCEPTED"
		MobiSys::CommonUtil.addUserActivity('QUOTATIONSYNCEDFROMONLINE',"quotationRefNum => #{self.quotationRefNum},proposalNum => #{self.proposalNum},quotationGuid => #{self.guid},quotationfnaId => #{self.fnaId},quotationPortfolioModelCode => #{quotationPortfolioModelCode}", 'QUOTATION', self.quotationRefNum)
		self.persistAll
	end
end

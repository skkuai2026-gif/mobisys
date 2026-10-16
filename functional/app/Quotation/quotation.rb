# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'CommonModules/mobisysbrowserhelper'
class Quotation
	include MobiSys::MobiSysEntitySchema

	set :schema_version, '1.0'

	# Uncomment the following line to enable sync with Label.
	# enable :sync

	#add model specifc code here

	property :quotationSeq, :integer
	property :productId, :string
	property :productVersion, :string
	property :quotationDt, :date
	property :quoteStatusCd, :string
	property :policyNum, :string
	property :proposalNum, :string
	property :quotationRefNum, :string
	property :genderCd, :string
	property :age, :integer
	property :ageMonths, :integer
	property :ageDays, :integer
	property :occupationCd, :string
	property :smoker, :string
	property :proposerLASame , :string
	property :jointLife, :string
	property :signature, :string
	property :productTypeCd, :string
	property :productFamilyCd, :string
	property :policyYear, :integer
	property :agentId, :string
	property :channel, :string
	property :subChannel, :string
	property :parentAgency, :string
	property :topupOptionCd, :string
	property :regularTopupFl, :string
	property :initialTopupFl, :string
	property :withdrawalFl, :string
	property :solverTypeCd, :string
	property :withdrawalRateTypeCd, :string
	# online attributes
	property :childUserId, :string
	property :coverTypeCd, :string
	property :quotationExpiryDt, :date
	property :isEditableQuoRefNumFl, :string
	property :uploadFlag, :string
	property :termTypeCd, :string
	property :pptermTypeCd, :string
	property :multiplierTypeCd, :string
	property :termCalculationBasisCd, :string
	property :isAgeEditableFl, :string
	property :issueDt, :date
	property :quotAddtnlField1, :string
	property :quotAddtnlField2, :string
	property :quotAddtnlField3, :string
	property :quotAddtnlField4, :string
	property :quotAddtnlField5, :string
	property :quotAddtnlField6, :string
	property :quotAddtnlField7, :string
	property :quotAddtnlField8, :string
	property :quotAddtnlField9, :string
	property :quotAddtnlField10, :string
	property :payingYears, :integer
	property :unselectedRiders, :string
	property :signatureDt, :time
	property :leadId,       :string
	property :fnaId,        :string
	property :rpqId,        :string
	property :agentSignature, :string
	property :visitedTabs, :string
	property :agentSignatureDt, :time
	property :quotAddtnlField11, :string
	property :quotAddtnlField12, :string
	property :isBackdatedFl, :string
	property :insuranceTypeCd, :string
	property :tripTypeCd, :string
	property :maxTripPeriod, :integer
	property :travelGeographyCd, :string
	property :visitPurposeCd, :string
	property :numberOfAdult, :integer
	property :numberOfChildren, :integer
	property :startDt, :date 
	property :endDt, :date
	property :autoRegistrationNum, :string
	property :autoMakeCd, :string
	property :autoModelCd, :string
	property :supplementaryLives, :string
	property :step, :integer
	property :stepActionTabs, :string
	property :appVersion, :string
	property :dbVersion, :string
	property :systTransferOptionCd, :string
	property :uploadFlag, :string
	property :entityStatus, :string
	property :proposalVersion, :string
	property :campaignCode, :string


	# derived attributes  
	property :userId, :string
	property :parentKey, :string
	property :versionID, :integer
	property :id, :integer
	property :guid, :string
	property :systemCreatedDt, :time
	property :systemUpdatedDt, :time

	attr_accessor :currentLayout
	attr_accessor :proposerAttainedAge
	attr_accessor :intimationSourceCd
	attr_accessor :citizenshipCd
	attr_accessor :proposerCitizenshipCd
	attr_accessor :jointLAIndustryCd
	attr_accessor :jointLACitizenshipCd
	attr_accessor :jointLAAttainedAge

	attr_accessor :additionalField #Added additional field to send one computed field to DT evaluation.
	attr_accessor :field20
	attr_accessor :field21
	attr_accessor :currentPartyRole
	attr_accessor :apoProductId
	attr_accessor :taskExcDO
	attr_accessor :basePlan
	attr_accessor :payorOccupationClass 
	attr_accessor :entityDesc 
	attr_accessor :paymentInstructionTypeCd
	attr_accessor :isTopupTypeRequiredFl
	attr_accessor :isQuotationDtEditableFl
	attr_accessor :pptCalcBasis

	attr_accessor :totAnnualPremium
	attr_accessor :totModalPremium
	attr_accessor :totSumAssured
	attr_accessor :totalCoi

	attr_accessor :questionContainer
	attr_accessor :policySeq

	attr_accessor :isInvalid
	attr_accessor :invalidReason
	attr_accessor :isCompleted
	attr_accessor :currentSolverFacetId
	attr_accessor :action
	attr_accessor :productSeq
	attr_accessor :proposerLACopyCd
	attr_accessor :entityTypeCd
	

	has_many 'QuotationProduct'
	has_many 'QuotationTopUp'
	has_many 'QuotationParty'
	has_many 'QuotationWithdrawal'
	has_many 'Image'
	has_many 'QuotationAdditionalFields'

	def getBasePlan
		return getBaseProduct
	end

	#return the list of child classes whose context need to be evaluated along with this class.
  	def contextExtendForClass
        return "QuotationAdditionalFields"
  	end

	def getBaseProduct
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.productTypeCd == 'PLAN'
				@basePlan = quotationProduct
				break
			end
		end 
		@basePlan
	end    

	# ext method to fetch PA product    
	def getPAProduct
	end

	# ext method to fetch riders    
	def getRiders
		riderList = Array.new
		basePlan = getBaseProduct
		if basePlan.productSeq.to_s != ""
			product = MobiSys::ProductUtil.getProduct(basePlan.productSeq)
			riderAutoPopulationReqFlag =  product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')
			if riderAutoPopulationReqFlag == 'YES'
				self.QuotationProductList.each do |quotationProduct|
					riderList.push quotationProduct if quotationProduct.productTypeCd == "RIDER" && quotationProduct.selected.to_s == "YES"
				end
			else
				self.QuotationProductList.each do |quotationProduct|
					riderList.push quotationProduct if quotationProduct.productTypeCd == "RIDER" && quotationProduct.removed.to_s == ""
				end
			end
			#Swati Ahire 27-08-2014: Sort riders by sortOrder
			riderList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
		end
		return riderList
	end

	def getRidersByParty(guid)
		riderList = Array.new
		self.QuotationProductList.each do |quotationProduct|
			riderList.push quotationProduct if quotationProduct.productTypeCd == "RIDER" && quotationProduct.insuredPartyRefGuid.to_s == guid
		end
		riderList.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
		return riderList
	end

	def getBuiltInRiders
		builtInRiderList = []
		self.QuotationProductList.each do |quotationProduct|
			builtInRiderList.push quotationProduct if quotationProduct.productTypeCd == "RIDER" and quotationProduct.builtInRiderFl == "YES"
		end
		return builtInRiderList
	end

	def self.onlineClassName
		return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.quotation.QuotationDO"
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
			if Time.parse(quotation.systemUpdatedDt) > Time.parse(lastSyncDate.to_s)
                entitiesForSync.push quotation
            end
		end
		return entitiesForSync
	end

	def beforeSync
		# self.systemUpdatedDt = Time.now
		persistEntity = false

		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.totAnnualizedPremium.to_s == 'NaN'
				quotationProduct.totAnnualizedPremium = 0.0 
				persistEntity = true
			end
		end
		self.persistAll if persistEntity
		#Do nothing. To be implemented in company layer
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
		unless $rhoconfig[:TABFEATUREREQD]
			self.QuotationProductList.each do |quotationProduct|
				quotationProduct.selected = 'on' if quotationProduct.builtInRiderFl != 'YES' && quotationProduct.productTypeCd == 'RIDER'
			end
		else 
			self.QuotationProductList.each do |quotationProduct|
				quotationProduct.selected = 'YES' if quotationProduct.builtInRiderFl != 'YES' && quotationProduct.productTypeCd == 'RIDER'
			end
		end

		self.quoteStatusCd = MobiSys::QuotationBO::SYNCDONE if self.quoteStatusCd == "ACCEPTED"
		self.persistAll
	end

	def getProposerLADifferent
		return proposerLASame == "on" ? "NO" : "YES"
	end

	def getJointLifeFlag
		return jointLife == "YES" ? "YES" : "NO"
	end

	def getRiderCount
		riderCount = 0
		self.QuotationProductList.each do |quotationProduct|
			riderCount += 1 if quotationProduct.productTypeCd == "RIDER"
		end
		return riderCount
	end

	def getTopup(policyYear)
		topup = nil
		self.QuotationTopUpList.each do |quotationTopup|
			if quotationTopup.removed.to_s == ""
				if quotationTopup.policyYearFrom.to_s != "" and quotationTopup.policyYearTo.to_s != "" and quotationTopup.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= quotationTopup.policyYearTo.to_i
					topup = quotationTopup
					break 
				end
			end
		end
		unless topup
			topup = QuotationTopUp.new
			topup.topUpAmount = 0.0
		end
		return topup
	end

	def getTopupByType(topupType)
		topup = []
		self.QuotationTopUpList.each do |quotationTopup|
			if quotationTopup.topUpTypeCd != nil and quotationTopup.topUpTypeCd == topupType
				topup.push(quotationTopup)
			end
		end
		return topup
	end

	def getQuotationTopup(policyYear, topuUpTypeCd)
        topup = nil
        self.QuotationTopUpList.each do |quotationTopup|
            if quotationTopup.removed.to_s == "" && topuUpTypeCd.to_s != '' && quotationTopup.topUpTypeCd.to_s == topuUpTypeCd
                if quotationTopup.policyYearFrom.to_s != "" and quotationTopup.policyYearTo.to_s != "" and quotationTopup.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= quotationTopup.policyYearTo.to_i
                    topup = quotationTopup
                    break 
                end
            end
        end
        unless topup
            topup = QuotationTopUp.new
            topup.topUpAmount = 0.0
        end
        return topup
    end

	def getRegularPolicyTopupAmt(policyYear)
		topupAmt = 0
		topup = nil
		self.QuotationTopUpList.each do |quotationTopup|
			if "REGULARTOPUP" == quotationTopup.topUpTypeCd
				topup = quotationTopup
				break
			end
		end
		if topup
			if (topup.topupFrequencyVal and topup.topupFrequencyVal.to_f != 0 and (topup.topupFrequencyValUnit.to_s == "" || topup.topupFrequencyValUnit.to_s == "YEARS"))
				if policyYear%topup.topupFrequencyVal.to_f == 0
					topupAmt = topup.topUpAmount.to_f
				end  
			elsif (topup.topupFrequencyVal == nil || topup.topupFrequencyValUnit.to_s == "MONTHS")
				topupAmt = topup.topUpAmount.to_f
			end  
		end
		return topupAmt
	end

	def getInitialInvestmentAmt(policyYear)
		initialInvestmentAmt = 0
		initialInvestment = nil
		self.QuotationTopUpList.each do |quotationTopup|
			if "INITIALINVESTMENT" == quotationTopup.topUpTypeCd
				initialInvestment = quotationTopup
				break
			end
		end
		if initialInvestment
			initialInvestmentAmt = initialInvestment.topUpAmount.to_f
		end
		return initialInvestmentAmt
	end

	def getWithdrawal(policyYear)
		withdrawal = nil
		self.QuotationWithdrawalList.each do |quotationWithdrawal|
			next if quotationWithdrawal.removed && quotationWithdrawal.removed != ""
			if quotationWithdrawal.policyYearFrom != nil and quotationWithdrawal.policyYearTo!=nil and quotationWithdrawal.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= quotationWithdrawal.policyYearTo.to_i
				withdrawal = quotationWithdrawal
				break 
			end
		end
		unless withdrawal
			withdrawal = QuotationWithdrawal.new
			withdrawal.withdrawalAmount = 0.0
			withdrawal.policyYearFrom = 0.0
			withdrawal.policyYearTo = 0.0
		end
		return withdrawal
	end


	def getPolicyWithdrawalByCategory(policyYear, policyMonth = 0, catgTypeCd = nil, catgSubTypeCd = nil)
		withdrawal = nil
		isCatgRegular = catgTypeCd.to_s == "" ? true : false
		isSubCatgRegular = catgSubTypeCd.to_s == "" ? true : false
		currMonthCycle = (policyYear-1) * 12 + policyMonth
		self.QuotationWithdrawalList.each do |quotationWithdrawal|
			next if quotationWithdrawal.removed && quotationWithdrawal.removed != ""
			if((isCatgRegular && (quotationWithdrawal.catgTypeCd.to_s == "" || quotationWithdrawal.catgTypeCd.to_s == "REGULAR") || (quotationWithdrawal.catgTypeCd.to_s != "" && quotationWithdrawal.catgTypeCd.to_s == catgTypeCd.to_s )) && (isSubCatgRegular && (quotationWithdrawal.catgSubTypeCd.to_s == "" || quotationWithdrawal.catgSubTypeCd.to_s == "REGULAR") || (quotationWithdrawal.catgSubTypeCd.to_s != "" && quotationWithdrawal.catgSubTypeCd.to_s == catgSubTypeCd.to_s )))
				if quotationWithdrawal.policyYearFrom != nil and quotationWithdrawal.policyYearTo != nil
					if quotationWithdrawal.policyYearFrom.to_i <= policyYear.to_i and policyYear.to_i <= quotationWithdrawal.policyYearTo.to_i
						withdrawal = quotationWithdrawal
						break 
					end
				elsif quotationWithdrawal.dateFrom != nil && quotationWithdrawal.dateTo != nil
					# get the month difference
					cycleFrom = MobiSys::DateTimeUtils.dateDifferenceInMonths(self.issueDt, quotationWithdrawal.dateFrom) + 1
					cycleTo = MobiSys::DateTimeUtils.dateDifferenceInMonths(self.issueDt, quotationWithdrawal.dateTo) + 1
					if(cycleFrom <= currMonthCycle && currMonthCycle <= cycleTo)
						withdrawal = quotationWithdrawal;
						break;
					end
				end
			end
		end
		if withdrawal == nil
			withdrawal = QuotationWithdrawal.new
			withdrawal.withdrawalAmount = 0.0
			# withdrawal.policyYearFrom = 0.0
			# withdrawal.policyYearTo = 0.0
		elsif withdrawal.withdrawalAmount.to_s == ""
			withdrawal.withdrawalAmount = 0.0
		end
		return withdrawal
	end
  
	#Method to get insured name for a given quotation
	def getInsuredName
		insuredName = ""
		insured = self.getPartyByRole("PRIMARY")
		if insured
			if insured.title == "OTHER"
				insuredName1 = insured.otherTitle.to_s + " " + insured.firstname.to_s + " " + insured.lastname.to_s
				insuredName2 = insured.otherTitle.to_s + " " + insured.firstname2.to_s + " " + insured.lastname2.to_s	
			else 
				insuredName1 = MobiSys::BrowserHelper.getLabel(insured.title.to_s) + " " + insured.firstname.to_s + " " + insured.lastname.to_s
				insuredName2 = MobiSys::BrowserHelper.getLabel(insured.title.to_s + " " + insured.firstname2.to_s) + " " + insured.lastname2.to_s
			end
			if insuredName1 != ""
				insuredName = insuredName1
			else
				insuredName = insuredName2
			end
		end
		return insuredName
	end

	def getPartyByRole(roleCd)
		self.QuotationPartyList.each do |quotationParty|
			return quotationParty if quotationParty.roleCd == roleCd
		end
		return nil
	end

	def getPartyListByRoleCd(roleCd)
		partyList = Array.new
		self.QuotationPartyList.each do |quotationParty|
			partyList.push quotationParty if quotationParty.roleCd == roleCd
		end
		return partyList
	end  

	def getPartyByGuid(guid)
		party=nil
		self.QuotationPartyList.each do |quotationParty|
			if quotationParty.uniqueKey==guid
				party=quotationParty
			end
		end
		return party
	end

	def getPartyRoleCds
		roleCds = []
		roleCds = self.QuotationPartyList.group_by{|party| party.roleCd}.keys.uniq
		return roleCds
	end

	def getParty(quotationProduct)
		quotationParty = nil
		if quotationProduct
			if(self.proposerLASame!="COPYFROMINSURED" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)|| (self.proposerLASame!="COPYFROMINSURED" && quotationProduct.partyRoleCd == "PRIMARY")
				quotationParty = self.getPartyByRole("PRIMARY")
			elsif self.proposerLASame!="COPYFROMINSURED" && quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="PROPOSER"
				quotationParty = self.getPartyByRole("PROPOSER")
			elsif (self.proposerLASame=="COPYFROMINSURED" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)  || (self.proposerLASame=="COPYFROMINSURED" && (quotationProduct.partyRoleCd=="PRIMARY"  || quotationProduct.partyRoleCd=="PROPOSER"))
				quotationParty = self.getPartyByRole("PRIMARY")
			elsif quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="JOINT"
				quotationParty = self.getPartyByRole("JOINT")        
			elsif quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="SUPPLEMENTARY"
				quotationParty=self.getPartyByGuid(quotationProduct.insuredPartyRefGuid)
			else
				quotationParty = self.getPartyByRole("PRIMARY")
			end  
		end
	end

	def getPartyOld(quotationProduct)
		quotationParty= QuotationParty.new
		if quotationProduct !=nil
			if(self.proposerLASame!="on" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)|| (self.proposerLASame!="on" && quotationProduct.partyRoleCd == "PRIMARY")
				quotationParty.firstname=self.firstname
				quotationParty.roleCd="PRIMARY"
				quotationParty.title=self.title
				quotationParty.middlename=self.middlename
				quotationParty.lastname=self.lastname
				quotationParty.genderCd=self.genderCd
				quotationParty.dob=self.dob
				quotationParty.age=self.age
				quotationParty.occupationCd=self.occupationCd
				quotationParty.nsap=self.nsap
				quotationParty.smoker=self.smoker
				quotationParty.relationCd=self.relationCd
				quotationParty.attainedAge=self.attainedAge
				quotationParty.industryCd=self.industryCd
				quotationParty.citizenshipCd=self.citizenshipCd
			elsif self.proposerLASame!="on" && quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="PROPOSER"
				quotationParty.firstname=self.proposerFirstname
				quotationParty.roleCd="PROPOSER"
				quotationParty.title=self.proposerTitle
				quotationParty.middlename=self.proposerMiddlename
				quotationParty.lastname=self.proposerLastname
				quotationParty.genderCd=self.proposerGenderCd
				quotationParty.dob=self.proposerDob
				quotationParty.age=self.proposerAge
				quotationParty.occupationCd=self.proposerOccupationCd
				quotationParty.nsap=self.proposerNsap
				quotationParty.smoker=self.proposerSmoker
				quotationParty.relationCd=self.proposerRelationWithPrimaryCd
				quotationParty.attainedAge=self.proposerAttainedAge
				quotationParty.industryCd=self.proposerIndustryCd
				quotationParty.citizenshipCd=self.proposerCitizenshipCd
			elsif (self.proposerLASame=="on" && quotationProduct.productTypeCd == "PLAN" && quotationProduct.partyRoleCd ==nil)  || (self.proposerLASame=="on" && (quotationProduct.partyRoleCd=="PRIMARY"  || quotationProduct.partyRoleCd=="PROPOSER"))
				quotationParty.firstname=self.proposerFirstname
				quotationParty.roleCd="PROPCUMINS"
				quotationParty.title=self.proposerTitle
				quotationParty.middlename=self.proposerMiddlename
				quotationParty.lastname=self.proposerLastname
				quotationParty.genderCd=self.proposerGenderCd
				quotationParty.dob=self.proposerDob
				quotationParty.age=self.proposerAge
				quotationParty.occupationCd=self.proposerOccupationCd
				quotationParty.nsap=self.proposerNsap
				quotationParty.smoker=self.proposerSmoker
				quotationParty.relationCd=self.proposerRelationWithPrimaryCd
				quotationParty.attainedAge=self.proposerAttainedAge  
				quotationParty.industryCd=self.proposerIndustryCd
				quotationParty.citizenshipCd=self.proposerCitizenshipCd
			elsif quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="JOINT"
				quotationParty.firstname=self.jointLAFirstname
				quotationParty.roleCd="JOINT"
				quotationParty.title=self.jointLATitle
				quotationParty.middlename=self.jointLAMiddlename
				quotationParty.lastname=self.jointLALastname
				quotationParty.genderCd=self.jointLAGenderCd
				quotationParty.dob=self.jointLADob
				quotationParty.age=self.jointLAAge
				quotationParty.occupationCd=self.jointLAOccupationCd
				quotationParty.nsap=self.jointLANsap
				quotationParty.smoker=self.jointLASmoker
				quotationParty.relationCd=self.jointLARelationWithPrimaryCd
				quotationParty.jointLAAttainedAge=self.jointLAAttainedAge
				quotationParty.industryCd=self.jointLAIndustryCd
				quotationParty.citizenshipCd=self.jointLACitizenshipCd
			elsif quotationProduct.partyRoleCd !=nil && quotationProduct.partyRoleCd=="SUPPLEMENTARY"
				quotationParty=self.getPartyByGuid(quotationProduct.insuredPartyRefGuid)
			end
		end
		if quotationParty!=nil && quotationParty.age !=nil && self.policyYear!=nil
			quotationParty.attainedAge =  quotationParty.age.to_i + (self.policyYear.to_i - 1)
		end
		return quotationParty
	end

	def getMainRider(quotationProduct)
		mainRider = nil
		listPolPrd = self.QuotationProductList
		listPolPrd.each do |polPrdRider|
			if polPrdRider.productTypeCd == "RIDER" and quotationProduct.parentproductSeq != nil and quotationProduct.object != polPrdRider.object
				if quotationProduct.parentproductSeq.to_i == polPrdRider.productSeq.to_i
					currMainInsured = getMainInsured(quotationProduct)
					polPrdRiderMainInsured = getMainInsured(polPrdRider)

					if currMainInsured != nil and polPrdRiderMainInsured != nil and currMainInsured.object == polPrdRiderMainInsured.object
						mainRider = polPrdRider
						break
					end
				end
			end
		end
		if mainRider == nil
			mainRider = QuotationProduct.new(:productSeq => 0, :productTerm => 0, :premiumPayingTerm => 0, :productPlanOptionCd => "", :baseSumAssured => 0, :productTypeCd => "RIDER")
		end
		return mainRider
	end

	def getMainInsured(quotationProduct)
		mainInsured = nil
		if quotationProduct &&  quotationProduct.insuredPartyRefGuid != nil && quotationProduct.insuredPartyRefGuid != ""
			mainInsured = getPartyByGuid(quotationProduct.insuredPartyRefGuid)
		elsif quotationProduct && quotationProduct.partyRoleCd != nil && quotationProduct.partyRoleCd != ""
			mainInsured = getPartyByRole(quotationProduct.partyRoleCd)
		else
			mainInsured = getPartyByRole("PRIMARY")
		end
		return mainInsured
	end

	def getQuotationProductByProductId(productId)
		baseProduct =  nil
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.productId == productId
				baseProduct = quotationProduct
				break
			end
		end
		baseProduct
	end


	def getNonBuiltInRiders
		riderList = []
		self.QuotationProductList.each do |quotationProduct|
			riderList.push quotationProduct if quotationProduct.productTypeCd == "RIDER" and quotationProduct.builtInRiderFl != "YES"
		end
		return riderList
	end

	def getRegularTopup
		regularTopup = nil
		self.QuotationTopUpList.each do |quotationTopup|
			if quotationTopup.topUpTypeCd == "REGULARTOPUP"
				regularTopup = quotationTopup
				break
			end
		end
		return regularTopup
	end

	def getInitialInvestment
		initialInvestment = nil
		self.QuotationTopUpList.each do |quotationTopup|
			if quotationTopup.topUpTypeCd == "INITIALINVESTMENT"
				initialInvestment = quotationTopup
				break
			end
		end
		return initialInvestment
	end

	def getRegularTopupPeriod
		regularTopup = getRegularTopup
		return (regularTopup and regularTopup.topUpPeriod) ? regularTopup.topUpPeriod : 0.0
	end

	def getRegularTopUpPeriod
		getRegularTopupPeriod
	end

	def getRegularWithdrawalYears
		withdrawalYears = Array.new
		self.QuotationWithdrawalList.each do |quotationWithdrawal|
			withdrawalYears.push quotationWithdrawal.policyYearFrom.to_i if quotationWithdrawal.policyYearFrom and quotationWithdrawal.policyYearFrom != ""
		end
		return withdrawalYears
	end

	def getQuotationProductByProductTypeCd(productTypeCd)
		quotationProducts =  []
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.productTypeCd.to_s == productTypeCd
				quotationProducts.push quotationProduct
			end
		end
		return quotationProducts
	end

	def calculateTotalSumAssured
		totalSumAssured = 0.0
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.removed.to_s != 'YES'
				totalSumAssured += quotationProduct.baseSumAssured.to_f
			end
		end
		self.totSumAssured = totalSumAssured
	end 

	def calculateTotalModalPremium
		totalModalPremium = 0.0
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.removed.to_s != 'YES'
				totalModalPremium += quotationProduct.modalPremium.to_f
			end
		end
		self.totModalPremium = totalModalPremium
	end

	def calculateTotalCoi
		totalCoi = 0.0
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.removed.to_s != 'YES'
				totalCoi += quotationProduct.coi.to_f
			end
		end
		self.totalCoi = totalCoi
	end

	def calculateTotalAnnualPremium
		totalBaseAnnualPremium = 0.0
		self.QuotationProductList.each do |quotationProduct|
			if quotationProduct.removed.to_s != 'YES'
				totalBaseAnnualPremium += quotationProduct.baseAnnualPremium.to_f
			end
		end
		self.totAnnualPremium = totalBaseAnnualPremium
	end

	def getPlanList
		planList = []
		self.QuotationProductList.each do |quotationProduct|
			planList.push(quotationProduct) if quotationProduct.productTypeCd == "PLAN" || quotationProduct.productTypeCd == "PLANMULTI"
		end
		return planList
	end

	def getPartyByRelation(relationCd)
		relationParty = QuotationParty.new
		if relationCd.to_s != ''
			self.QuotationPartyList.each do |quotationparty|
				if quotationparty.relationCd.to_s == relationCd.to_s
					relationParty = quotationparty
					break
				end
			end
		end
		return relationParty
	end

	def getQuotationAdditionalFieldsDO
		quotationAdditionalFieldsDO = nil
		if self.QuotationAdditionalFieldsList.size > 0
			quotationAdditionalFieldsDO = self.QuotationAdditionalFieldsList[0]
		else
			quotationAdditionalFieldsDO = QuotationAdditionalFields.new
			self.addQuotationAdditionalFields(quotationAdditionalFieldsDO)
		end
		return quotationAdditionalFieldsDO
	end

	def getBasePlanAdditionalDO
		quotationProductAdditional = nil
		quotationProduct = self.getBaseProduct
		quotationProductAdditionalList = quotationProduct.QuotationProductAdditionalList
		if quotationProductAdditionalList && quotationProductAdditionalList.size > 0
			quotationProductAdditional = quotationProductAdditionalList[0]
		else
			quotationProductAdditional = QuotationProductAdditional.new
			quotationProduct.addQuotationProductAdditional(quotationProductAdditional)
		end
		return quotationProductAdditional
	end

	def getBasePlanMulti(currInsuredGuid)
		quotatationProductDO = nil
		self.QuotationProductList.each do |quotationProduct|
			if ( quotationProduct.productTypeCd.to_s == 'PLANMULTI'  && quotationProduct.insuredPartyRefGuid != nil && quotationProduct.insuredPartyRefGuid == currInsuredGuid)
				quotatationProductDO = quotationProduct
				break
			end
		end 
		return quotatationProductDO 
	end 

	def getTotalServiceTax
        totServiceTax = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.serviceTax != nil )
                totServiceTax = totServiceTax + quotationProduct.serviceTax
            end
        end
        return totServiceTax
    end


    def getTotSumAssured
        totSumAssured = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.baseSumAssured != nil )
                totSumAssured =  totSumAssured + quotationProduct.baseSumAssured
            end
        end
        return totSumAssured
    end

    def getTotAnnualPremium
        totAnnualPremium = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.baseAnnualPremium != nil )
                totAnnualPremium = totAnnualPremium + quotationProduct.baseAnnualPremium.to_f
            end
        end
        return totAnnualPremium
    end

    def getTotModalPremium
        totModalPremium = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.modalPremium != nil )
                totModalPremium = totModalPremium + quotationProduct.modalPremium.to_f
            end
        end
        return totModalPremium
    end

    def getTotExtraPremium
        totExtraPremium = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.extraPremium != nil )
                totExtraPremium = totExtraPremium + quotationProduct.extraPremium
            end
        end
        return totExtraPremium
    end

    def getTotalCoi
        totCoi = 0.0
        self.QuotationProductList.each do |quotationProduct|
            if (quotationProduct != nil && quotationProduct.coi != nil )
                totCoi = totCoi + quotationProduct.coi
            end
        end
        return totCoi
    end

    def getOrderedPartyList
    	roleOrderList = ['PROPOSER','PRIMARY','JOINT','SUPPLEMENTARY']
    	orderedPartyList = Array.new
    	roleOrderList.each do |role|
    		self.QuotationPartyList.each do |party|
    			orderedPartyList.push(party) if party.roleCd == role
    		end
    	end

    	return orderedPartyList
    end

    def currencyCd
		currencyCd = nil
		basePlan = self.getBaseProduct
		if(basePlan != nil)
			currencyCd = basePlan.currencyCd
		end
	    return currencyCd
    end

    def getEntityTypeCd
      entityTypeCd = self.entityTypeCd
      entityTypeCd = "QUOTATION" if entityTypeCd.to_s == ""
      return entityTypeCd
    end
    
    # method added to get topup by type. This method is called from expression, hence the name is same as online
    def getPolicyTopupForType(topUpType)
        topUpRet = nil
        self.QuotationTopUpList.each do |top_up|
            next unless top_up.topUpTypeCd.upcase == topUpType.upcase
            topUpRet = top_up 
        end
        if topUpRet == nil
            topUpRet = QuotationTopUp.new
            topUpRet.topUpAmount = 0.0
            topUpRet.topUpTypeCd = topUpType
        end
        return topUpRet
    end
end
require 'Quotation/quotation_company'
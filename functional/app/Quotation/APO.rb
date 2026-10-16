require 'Quotation/quotation_util'
require 'Product/product_b_o'
require 'CommonClasses/QuotationIO'
require 'CommonModules/commonutil'

module MobiSys
	class APO
		include Singleton

		attr_accessor :originalQuotationIO, :apoQuotationIO

		def self.find
			originalProductDO = @originalQuotationIO.baseProduct
			apoFindModelCd = originalProductDO.getFacetValue("APOFINDFACET")
			return unless apoFindModelCd
			MobiSys::ProductBO.loadModel("APOFINDFACET", @originalQuotationIO)
      @originalQuotationIO = MobiSys::ProductBO.callCalculateIllustration(@originalQuotationIO)
      if @originalQuotationIO.baseDO.apoProductId
        @apoQuotationIO = MobiSys::IO::QuotationIO.new
        apoQuotationDO = @originalQuotationIO.baseDO.cloneObject
        apoQuotationDO.getRiders.each do |rider|
          rider.baseSumAssured = nil
          rider.baseAnnualPremium = nil
          rider.modalPremium = nil
          rider.wopPremium = nil
        end
        apoQuotationDO.apoProductId = @originalQuotationIO.baseDO.apoProductId
        apoQuoteProductDO = apoQuotationDO.getBasePlan
        apoQuoteProductDO.productId = apoQuotationDO.apoProductId
        apoQuoteProductDO.product = nil
        apoQuoteProductDO.productSeq = nil
        apoQuoteProductDO.productVersion = nil
        @apoQuotationIO.baseDO = apoQuotationDO
        MobiSys::QuotationUtil.setBaseProductDetail(@apoQuotationIO, apoQuoteProductDO)
        #if the base product returned is non existing then nullify everything.
        @apoQuotationIO = nil unless @apoQuotationIO.baseProduct
        @originalQuotationIO.illustrationModel = nil
      end #if @originalQuotationIO.baseDO.apoProductId
		end

		def self.execute(quotationIO)
			@originalQuotationIO = quotationIO
			find
      return nil unless @apoQuotationIO
			createQuotation
      postCreateQuotation
      validateQuotation
      postValidateQuotation
			generateIllustration
			return @apoQuotationIO
		end

    def self.postCreateQuotation
      #Do nothing. To be implemented in implementation layer
    end

    def self.postValidateQuotation
      #Do nothing. To be implemented in implementation layer
    end  

		def self.createQuotation
			return unless @apoQuotationIO
			@apoQuotationIO.baseDO.quotationRefNum = "APO_#{@apoQuotationIO.baseDO.quotationRefNum}"

			@msg = ""
	    @errors = Hash.new
			originalProductDO = @originalQuotationIO.baseProduct
      apoProductDO = @apoQuotationIO.baseProduct
			apoCopyModelCd = apoProductDO.getFacetValue("APOCOPYFACET")
			return nil unless apoCopyModelCd

			MobiSys::ProductBO.loadModel('APOCOPYFACET', @apoQuotationIO)
			@apoQuotationIO = MobiSys::ProductBO.callCalculateIllustration(@apoQuotationIO)

      results = MobiSys::DataObjects::Results.new
      results = MobiSys::DataObjects::Results.new
      results.createAttr("quotation")
      results.quotation = @apoQuotationIO.baseDO
      results.createAttr("quotationProduct")
      results.createAttr("basePlan")
      results.basePlan = @apoQuotationIO.baseDO.getBaseProduct
      
      results.createAttr("currCycleCount")
      results.createAttr("currPolicyYear")
      results.createAttr("currPolicyMonth")
      results.createAttr("currIllusNetRate")
      results.createAttr("quotationIO")
      results.quotationIO = @apoQuotationIO
      results.createAttr("investmentFund")

      illusModelDO = @apoQuotationIO.illustrationModel
      illusModelDO.IllustrationFacetList.each do |illusFacetDO|
        next unless illusFacetDO.inputElementSource == "investmentFund"
        next unless illusFacetDO.computePerInstanceOf == "FUND"
        @apoQuotationIO.baseDO.getBasePlan.QuotationProductInvestmentFundList.each do |investmentFund|
          originalComputedElementName = illusFacetDO.computedElementName
          newComputedElementName = "#{illusFacetDO.computedElementName}_#{investmentFund.fundCd}"
          results.createAttr(newComputedElementName)
          illusFacetDO.computedElementName = newComputedElementName
          @apoQuotationIO.baseDO.getBasePlan.fundCd = investmentFund.fundCd
          evaluatedValue = MobiSys::ProductBO.evaluateField(illusModelDO, illusFacetDO, @apoQuotationIO.baseDO, results, @apoQuotationIO.baseDO.getBasePlan, @apoQuotationIO)
          exp = "#{illusFacetDO.inputDataElement}=".to_sym
          investmentFund.send exp, evaluatedValue
          illusFacetDO.computedElementName = originalComputedElementName
        end  
      end  

      #Collate all investment fund DO's with same fundCd
      qpifList = @apoQuotationIO.baseDO.getBasePlan.QuotationProductInvestmentFundList
      fundHash = MobiSys::CommonUtil.convertToHash(qpifList,"fundCd",true)
      finalFundList = Array.new
      fundHash.each_pair{|fundCd, fundList|
        newFund = QuotationProductInvestmentFund.new
        newFund.fundCd = fundCd
        newFund.allocationPerc = 0.0
        fundList.each do |oldFund|
          newFund.allocationPerc += oldFund.allocationPerc.to_f
        end
        fundMaster = Fund.find(:first,:conditions=>{{:name=>'fundCd'}=>fundCd})
        newFund.fundTypeCd = fundMaster.fundTypeCd
        newFund.expiryDt = fundMaster.expiryDt
        newFund.maturityDt = fundMaster.maturityDt
        finalFundList.push newFund
      }
      @apoQuotationIO.baseDO.getBasePlan.setQuotationProductInvestmentFundList finalFundList
		end

    def self.validateQuotation
      @apoQuotationIO.baseDO.getRiders.each do |rider|
        rider.partyRoleCd = 'PRIMARY' unless rider.partyRoleCd
      end

      @apoQuotationIO.baseDO.QuotationProductList.each do |quotationProduct|
        party = @apoQuotationIO.baseDO.getParty(quotationProduct)
        quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!=""
      end
      
      MobiSys::QuotationBO.validate(@apoQuotationIO.baseDO, @msg, @errors)
    end  
		
		def self.generateIllustration
			return unless @apoQuotationIO
      product = @apoQuotationIO.baseProduct
      apoSiModelCd = product.getFacetValue('APOSIMODEL')
			MobiSys::ProductBO.loadModel(apoSiModelCd ? 'APOSIMODEL' : 'SIMODEL', @apoQuotationIO)
			@apoQuotationIO = MobiSys::ProductBO.callCalculateIllustration(@apoQuotationIO)
		end
	end
end

require 'Quotation/APO_company'
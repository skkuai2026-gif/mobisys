module MobiSys
  class APO
    include Singleton

    def self.postCreateQuotation

      replaceInputElements = MobiSys::DataObjects::Results.new
      replaceInputElements.createAttr("quotation")
      replaceInputElements.quotation = @apoQuotationIO

      replaceInputElements.createAttr("quotationProduct")
      replaceInputElements.quotationProduct = @apoQuotationIO.baseDO.getBaseProduct

      listRiderQuotationProductDOToAdd = Array.new
      riderProductIds = @apoQuotationIO.getIllustrationHeaderFieldValue("rideralternateproductoffering")
      illusModelDO = @apoQuotationIO.illustrationModel
      if riderProductIds != nil
        if riderProductIds == "NA"
          basePlan = @apoQuotationIO.baseDO.getBasePlan
          @apoQuotationIO.baseDO.setQuotationProductList listRiderQuotationProductDOToAdd
          @apoQuotationIO.baseDO.addQuotationProduct basePlan
        else
          riderProductIdList = riderProductIds.split(",")
          riderProductSeq_Ver = []
          riderProductIdList.each do |productId|

            product_APO_Product_Ver = MobiSys::ProductUtil.getProduct(@apoQuotationIO.baseDO.getBaseProduct.productSeq)

            facetRADO_For_APO_Ver = product_APO_Product_Ver.getFacet('RIDERASSOCIATION')
            offlineRiderAssociationList_Ver = facetRADO_For_APO_Ver.OfflineRiderAssociationList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i} if facetRADO_For_APO_Ver
            offlineRiderAssociationList_Ver.each do |offlineRiderAssociation_Ver|
              if productId == offlineRiderAssociation_Ver.productId
                  riderProductSeq_Ver = offlineRiderAssociation_Ver.productSeq
                break
              end
            end

            rqp = QuotationProduct.new
            rqp.selected = "YES"
            rqp.productId = productId

            products = Product.loadObject(:all,:conditions=>{{:name=>'id'}=>riderProductSeq_Ver})
            products.each do |product|
              if product && product.productTypeCd == "RIDER"
                rqp.productTypeCd = "RIDER"
              elsif product && product.productTypeCd == "PLAN"
                rqp.productTypeCd = "PLAN"
              end
              if productId
                rqp.productSeq = product.id
                rqp.product = product
              end
            end
            listRiderQuotationProductDOToAdd.push rqp
            @apoQuotationIO.baseDO.addQuotationProduct(rqp)
          end  
        end
      else
        listRiderQuotationProductDOToAdd = @apoQuotationIO.baseDO.getRiders
      end
      isLoadingUpdate = false
      illusModelDO.IllustrationFacetList.each do |illusFacetDO|
      
        if illusFacetDO.inputElementSource != nil && illusFacetDO.inputElementSource == "policyBasePlanExtraDO"
          @apoQuotationIO.baseDO.getBasePlan.QuotationProductExtraList.each do |policyProductExtraDO|
            if policyProductExtraDO != nil
              evaluatedVal = MobiSys::ProductBO.evaluateField(illusModelDO,illusFacetDO, @apoQuotationIO.baseDO,replaceInputElements,@apoQuotationIO.baseDO.getBasePlan,@apoQuotationIO)
              
              policyProductExtraDO.extraFlatAmt = evaluatedVal
              policyProductExtraDO.extraPercent = evaluatedVal
              policyProductExtraDO.extraFlatDuration = evaluatedVal
              policyProductExtraDO.extraPercDuration = evaluatedVal
              isLoadingUpdate =true
            end
          end
        elsif illusFacetDO.inputElementSource != nil && illusFacetDO.inputElementSource == "policyRiderExtraDO"
          @apoQuotationIO.baseDO.getRiders.each do |policyProductDO|
            policyProductDO.QuotationProductExtraList.each do |policyProductExtraDO|
            evaluatedVal = MobiSys::ProductBO.evaluateField(illusModelDO,illusFacetDO, @apoQuotationIO.baseDO,replaceInputElements,policyProductDO,@apoQuotationIO)
            
              policyProductExtraDO.extraFlatAmt = evaluatedVal
              policyProductExtraDO.extraPercent = evaluatedVal
              policyProductExtraDO.extraFlatDuration = evaluatedVal
              policyProductExtraDO.extraPercDuration = evaluatedVal
              isLoadingUpdate =true
            end
          end
        end
        
      end
      @apoQuotationIO.createAttr("listRiderQuotationProductDOToAdd")
      @apoQuotationIO.listRiderQuotationProductDOToAdd = listRiderQuotationProductDOToAdd
    end

    def self.postValidateQuotation
      return unless @apoQuotationIO
      finalListQuotationProductDOToAdd = Array.new
      listRiderQuotationProductDOToAdd = @apoQuotationIO.listRiderQuotationProductDOToAdd
      listRiderQuotationProductDOToAdd.each do |riderQuoteProduct|
        @apoQuotationIO.baseDO.getRiders.each do |riderQuotationProduct|
          if riderQuoteProduct.productId == riderQuotationProduct.productId
            finalListQuotationProductDOToAdd.push riderQuotationProduct
            break
          end  
        end  
      end  
      finalListQuotationProductDOToAdd.push @apoQuotationIO.baseDO.getBasePlan
      @apoQuotationIO.baseDO.setQuotationProductList finalListQuotationProductDOToAdd
    end

    def self.validateQuotation
      @apoQuotationIO.baseDO.getRiders.each do |rider|
        rider.partyRoleCd = 'PRIMARY' unless rider.partyRoleCd
      end

      @apoQuotationIO.baseDO.QuotationProductList.each do |quotationProduct|
        party = @apoQuotationIO.baseDO.getParty(quotationProduct)
        quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!=""
      end

      product = Product.loadObject(:first, :conditions=>{
      :id => @apoQuotationIO.baseDO.getBaseProduct.productSeq
      })
      premiumDetailsFacet = product.getPremiumDetailsFacet
      premiumDetails = premiumDetailsFacet.OfflinePremiumDetailsList[0]
      if  @apoQuotationIO.baseDO.getBaseProduct.paymentTypeCd == 'SINGLE'
        @apoQuotationIO.baseDO.getBaseProduct.baseSumAssured = nil
      else
        @apoQuotationIO.baseDO.getBaseProduct.baseAnnualPremium = nil
      end
   #below logic is for auto population of riders
       aporiders = []
       
       aporiderSelectField = {}
       
       
    
     product = Product.loadObject(:first, :conditions=>{
      :id => @apoQuotationIO.baseDO.getBaseProduct.productSeq
      })
    @riderAutoPopulationReqFlag =  product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED')


        

    if @riderAutoPopulationReqFlag == "YES"
      facetRADO = product.getFacet('RIDERASSOCIATION')

      if facetRADO != nil
        basePlan = @apoQuotationIO.baseDO.getBaseProduct
        @apoQuotationIO.baseDO.proposerLASame == "COPYFROMINSURED" ?  primaryPartyDO = @apoQuotationIO.baseDO.getPartyByRole('PROPOSER') : primaryPartyDO = @apoQuotationIO.baseDO.getPartyByRole('PRIMARY')
        basePlan.combinedEntryAge = primaryPartyDO.age.to_i
        #maintain a hashmap of existing rider records.. All the riders with the same product seq should be maintained..
        # One Rider product can be taken by multiple insureds..Primary/ Joint/ Supplementary.
        existingQuoteProducts = {}
        @apoQuotationIO.baseDO.QuotationProductList.each do |quotationProduct|
          #existing records should be auto selected.
          # quotationProductDO.setIsObjectSelected(MasterDataConstants.BOOLEAN.YES);
          next if "RIDER" != quotationProduct.productTypeCd
          #Swati Ahire: Added by comparing with online code
          # quotationProduct.selected = 'on'
          listExistRiders = nil
          if existingQuoteProducts[quotationProduct.productSeq.to_s] != nil
            listExistRiders = (existingQuoteProducts[quotationProduct.productSeq.to_s])
          else
            # listExistRiders.push(quotationProduct)
            listExistRiders = []
          end
          listExistRiders.push(quotationProduct)
          existingQuoteProducts[quotationProduct.productSeq.to_s] = listExistRiders
        end

        facetRADO.OfflineRiderAssociationList.each do |offlineRiderAssociation|
          #Do not consider built in riders at all..
          if offlineRiderAssociation.builtInRiderFl == 'YES'
            next
          end
          # only consider those rider association whose base plan option match.
          #if basePlan.basePlanOptionCd  && offlineRiderAssociation.basePlanOptionCd  && !basePlan.basePlanOptionCd == offlineRiderAssociation.getBasePlanOptionCd
          if basePlan.productPlanOptionCd  && offlineRiderAssociation.productPlanOptionCd  && basePlan.productPlanOptionCd != offlineRiderAssociation.basePlanOptionCd
            next
          end
          defTableDO = nil 
          listDefinitionTable = nil 
          isByDefaultOptional = true

          if offlineRiderAssociation.associationRelationTTmapSeq != nil
            listDefinitionTable = MobiSys::ProductUtil.getProductDefinitionTables(offlineRiderAssociation.associationRelationTTmapSeq)
         
            if(listDefinitionTable != nil || listDefinitionTable.size > 0)
            # if even one record is found defined as optional .. it implies that rider is optional only under certain conditions.. 
            # else by default consider it as optional.//User cannot define all possible combinations for rider to be optional .. if it is always optional.
              listDefinitionTable.each do |defnTableDOInList|
               
                if defnTableDOInList.associationRelationCd == 'OPTIONAL' || defnTableDOInList.associationRelationCd == 'OPTIONALDEFAULT'
                  isByDefaultOptional = false;
                  break;
                end
              end
            end

            defTableDO = MobiSys::ProductBO.getProductDefinitionTable(offlineRiderAssociation.associationRelationTTmapSeq, @apoQuotationIO.baseDO, basePlan)

            
          #   //if dt matched then based on the association relation mark as mandatory, auto selected ..
          
            if defTableDO != nil  || isByDefaultOptional == true
              apoAutoPopulateRider(@apoQuotationIO.baseDO,aporiders, existingQuoteProducts, offlineRiderAssociation, defTableDO);             
            end
          else
            apoAutoPopulateRider(@apoQuotationIO.baseDO,aporiders, existingQuoteProducts, offlineRiderAssociation, defTableDO); 
          end
        end
      end
    end

      # Add condition to check aporiders with existing original quotation riders
      aporiders.reject! {|x| x.selected != 'YES' || existingQuoteProducts[x.productSeq.to_s] == nil}
      basePlan = @apoQuotationIO.baseDO.getBasePlan
      @apoQuotationIO.baseDO.setQuotationProductList aporiders
      @apoQuotationIO.baseDO.addQuotationProduct basePlan

      
      MobiSys::QuotationBO.validate(@apoQuotationIO.baseDO, @msg, @errors)


      if(!checkAPORiders(@apoQuotationIO, @originalQuotationIO))

        @apoQuotationIO = nil;
      else
        apoRiderIds = []
        readOnlyFields = {}
        productHash = {}
        isWOPF1 = {}
        isValidateRequired = false
        @apoQuotationIO.baseDO.getRiders.each do |apoRider|
          apoRiderIds.push(apoRider.productId)
        end
        products = Product.loadObject(:all,:conditions=>{{:name=>'productId', :op => 'IN'}=>apoRiderIds})

        products.each do |prod|
          productHash[prod.productId] = prod
          readOnlyFields[prod.productId] = prod.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement if prod.getPremiumDetailsFacet
          isWOPF1[prod.productId] = prod.getOtherDetailsFacet.OfflineOtherDetailsList[0].isWOPFl if prod.getOtherDetailsFacet
        end
        if @originalQuotationIO.baseDO.getBaseProduct.paymentTypeCd != 'SINGLE'
          @originalQuotationIO.baseDO.getRiders.each do |originalrider|
            @apoQuotationIO.baseDO.getRiders.each do |apoRider|
              if originalrider.productId == apoRider.productId
                if readOnlyFields[apoRider.productId] != 'baseSumAssured' && isWOPF1[apoRider.productId] != 'YES'
                  if originalrider.baseSumAssured.to_f < apoRider.baseSumAssured.to_f
                    apoRider.baseSumAssured = originalrider.baseSumAssured.to_f
                    apoRider.baseAnnualPremium = nil
                    apoRider.annualizedPremium = nil
                    apoRider.modalPremium = nil
                    apoRider.wopPremium = nil
                    isValidateRequired = true
                   # MobiSys::QuotationBO.validate(@apoQuotationIO.baseDO, @msg, @errors)
                  end
                elsif isWOPF1[apoRider.productId] == 'YES'
                  apoRider.baseSumAssured = nil
                  apoRider.baseAnnualPremium = nil
                  apoRider.annualizedPremium = nil
                  apoRider.modalPremium = nil
                  apoRider.wopPremium = nil
                  isValidateRequired = true
                end
                break
              end
            end
          end
        end
        MobiSys::QuotationBO.validate(@apoQuotationIO.baseDO, @msg, @errors) if isValidateRequired
        if @originalQuotationIO.baseDO.getBaseProduct.paymentTypeCd != 'SINGLE'
          @apoQuotationIO.baseDO.getTopupByType('INITIALINVESTMENT')[0] = @originalQuotationIO.baseDO.getTopupByType('INITIALINVESTMENT')[0]
          riderTotalPremium = 0
          apoRiderTotalPremium = 0 
          @originalQuotationIO.baseDO.getRiders.each do |rider|
            riderTotalPremium += rider.annualizedPremium.to_f
          end
          planBaseAnnualPremium = @originalQuotationIO.baseDO.getBasePlan.baseAnnualPremium==nil ? 0 : @originalQuotationIO.baseDO.getBasePlan.baseAnnualPremium.to_f;
          annualPremium = @originalQuotationIO.baseDO.getBasePlan.extraPremium == nil ? 0.0 : @originalQuotationIO.baseDO.getBasePlan.extraPremium.to_f;
          totalPremium = MobiSys::Math.roundNearest(((riderTotalPremium).to_f + (planBaseAnnualPremium).to_f + (annualPremium).to_f),2)
          annualexcesspremium = @originalQuotationIO.baseDO.getTopupByType('REGULARTOPUP')[0].topUpAmount
          totalInitialAnnualPremium = totalPremium.to_f + annualexcesspremium.to_f

          @apoQuotationIO.baseDO.getRiders.each do |apoRider|
            # Set annualizedPremium with baseAnnualPremium to match with online code
            apoRider.annualizedPremium = apoRider.baseAnnualPremium.to_f
            apoRiderTotalPremium += apoRider.annualizedPremium.to_f
          end
          apoPlanBaseAnnualPremium = @apoQuotationIO.baseDO.getBasePlan.baseAnnualPremium==nil ? 0 : @apoQuotationIO.baseDO.getBasePlan.baseAnnualPremium.to_f;
          apoAnnualPremium = @apoQuotationIO.baseDO.getBasePlan.extraPremium == nil ? 0.0 : @apoQuotationIO.baseDO.getBasePlan.extraPremium.to_f;
          apoTotalPremium = MobiSys::Math.roundNearest(((apoRiderTotalPremium).to_f + (apoPlanBaseAnnualPremium).to_f + (apoAnnualPremium).to_f),2)
          apoAnnualexcesspremium = totalInitialAnnualPremium - apoTotalPremium
          @apoQuotationIO.baseDO.getTopupByType('REGULARTOPUP')[0].topUpAmount = apoAnnualexcesspremium.to_f

          #if totalPremium < apoTotalPremium
          #  @apoQuotationIO = nil
          #end
          if apoAnnualexcesspremium.to_f < 0
            MobiSys::CommonUtil.clearTaskExceptionList(@apoQuotationIO.baseDO.guid)  #SUNSS 2896
            @apoQuotationIO = nil
          end
        end   
      end

    end  

    def self.addBlankRider(quotation, riderAssociation = nil )
      rider = QuotationProduct.new(:productTypeCd => 'RIDER', :partyRoleCd => 'PRIMARY', :builtInRiderFl => 'NO')
      if riderAssociation != nil 
        rider.productSeq = riderAssociation.productSeq
        rider.productId = riderAssociation.productId
        rider.productPlanOptionCd = riderAssociation.productPlanOptionCd
        rider.linkedFl = riderAssociation.linkedFl
        rider.sortOrder = riderAssociation.sortOrder
      end
      quotation.addQuotationProduct(rider)
      return rider
    end

      def self.apoAutoPopulateRider(quotationDO,aporiders, existingQuoteProducts, riderAssociationDO, defTableDO, onRefresh = nil)
        aponewRiderFields = {}
        aporiderHash = {}
        aporiderDisableField = {}
        unselectedRidersArray = quotationDO.unselectedRiders.to_s.split("|").map{|a| a.split(":")[1]}.join(",").split(",").uniq if quotationDO.unselectedRiders != nil
        riderKeyId = riderAssociationDO.productSeq
        
        if onRefresh
          riderProductList = nil 
        elsif existingQuoteProducts && existingQuoteProducts.has_key?(riderKeyId.to_s)
          riderProductList = existingQuoteProducts[riderKeyId.to_s]
        end
        if riderProductList == nil
            riderProductList = []
            riderProductList.push(addBlankRider(quotationDO, riderAssociationDO))
        end
        riderProductList.each do |riderProduct|
            product = Product.loadObject(:first, :conditions =>  {
                                                      {
                                                        :name => 'id'
                                                      } => riderProduct.productSeq
                                                    })
          aponewRiderFields[riderProduct.productSeq.to_i] =  product.getPremiumDetailsFacet.OfflinePremiumDetailsList[0].inputDataElement if product and product.getPremiumDetailsFacet
          aporiderHash[riderProduct.productSeq] = product.longName if product
          if defTableDO != nil
            if defTableDO.associationRelationCd == 'MANDATORY'
              flag = true;
              if onRefresh == nil
                if unselectedRidersArray != nil && unselectedRidersArray != []
                  unselectedRidersArray.each do |unselectedRide|
                    if unselectedRide.to_s == riderProduct.productSeq.to_s
                      flag = false;
                      break;
                    end
                  end
                end
              end
              riderProduct.selected = "YES" if flag
              # @riderSelectField[riderProduct.object] = "YES"# riderProduct.setIsObjectSelected(MasterDataConstants.BOOLEAN.YES);
              aporiderDisableField[riderProduct.object] = "YES" # riderProduct.setMandatoryCheckFl(MasterDataConstants.BOOLEAN.YES);
            elsif defTableDO.associationRelationCd == 'OPTIONALDEFAULT'
              flag = true;
              if onRefresh == nil
                if unselectedRidersArray != nil && unselectedRidersArray != []
                  unselectedRidersArray.each do |unselectedRide|
                    if unselectedRide.to_s == riderProduct.productSeq.to_s
                      flag = false;
                      break;
                    end
                  end
                end
              end
              riderProduct.selected = "YES" if flag
              # @riderSelectField[riderProduct.object] = "YES"
              aporiderDisableField[riderProduct.object] = "NO"
              # riderProduct.setIsObjectSelected(MasterDataConstants.BOOLEAN.YES);
              # Need to reset back the mandatory to NO.. as it could have been mandatory earlier.. but due to new set of conditions on refresh is now no longer mandatory
              # riderProduct.setMandatoryCheckFl(MasterDataConstants.BOOLEAN.NO);
            elsif defTableDO.associationRelationCd == 'OPTIONAL'
              aporiderDisableField[riderProduct.object] = "NO"
              #do not mark as selected as optional select for User.
              #Need to reset back the mandatory to NO.. as it could have been mandatory earlier.. but due to new set of conditions on refresh is now no longer mandatory
              # riderProduct.setMandatoryCheckFl(MasterDataConstants.BOOLEAN.NO);
            end
          else
            #riderProduct.setMandatoryCheckFl(MasterDataConstants.BOOLEAN.NO);
            aporiderDisableField[riderProduct.object] = "NO"
          end
          aporiders.push(riderProduct)
        end
      end

      def self.generateIllustration
        return unless @apoQuotationIO
        product = @apoQuotationIO.baseProduct
        apoSiModelCd = product.getFacetValue('APOSIMODEL')
        MobiSys::ProductBO.loadModel(apoSiModelCd ? 'APOSIMODEL' : 'SIMODEL', @apoQuotationIO)
        @apoQuotationIO = MobiSys::ProductBO.callCalculateIllustration(@apoQuotationIO, 'APOSIMODEL')
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
          fundMaster = Fund.find(:first,:conditions=>{{:name=>'fundCd'}=>fundCd.to_s})
          if fundMaster
            newFund.fundTypeCd = fundMaster.fundTypeCd
            newFund.expiryDt = fundMaster.expiryDt
            newFund.maturityDt = fundMaster.maturityDt
            finalFundList.push newFund
          end  
        }
        @apoQuotationIO.baseDO.getBasePlan.setQuotationProductInvestmentFundList finalFundList
      end

      def self.checkAPORiders(apoQuotationIO, originalQuotationIO)
        apoFlag = true;
        if(apoQuotationIO != nil)
           apoFlag = false;
          if(originalQuotationIO.baseDO != nil)
            orgRiderList = originalQuotationIO.baseDO.getRiders;
            apoRiderList = apoQuotationIO.baseDO.getRiders;
            if(orgRiderList == nil || orgRiderList.size == 0)
              apoFlag = true;
            elsif(apoRiderList == nil || apoRiderList.size == 0)
              apoFlag = true;
            elsif(apoRiderList.size > 0 && orgRiderList.size > 0)
              count = 0;
              orgRiderList.each do |orgQuotationProductDO|
                apoRiderList.each do |apoQuotationProductDO|
                  if(apoQuotationProductDO.productId == orgQuotationProductDO.productId)
                    count = count + 1
                    break
                  end
                end
              end
              if(count == orgRiderList.size)
                apoFlag = true;
              end
            end
          end
        end
        return apoFlag;
      end
      
  end
end


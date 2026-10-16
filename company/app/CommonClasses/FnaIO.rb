module MobiSys
  module IO
    class FnaIO
      attr_accessor :baseDO
      attr_accessor :pageAttributes, :baseProduct, :multiplierReqd, :illustrationReportsList
      attr_accessor :listCalculation, :illustrationHeader, :illustrationModel
      attr_accessor :hmRiderComputedAttributes, :hmFundComputedAttributes
      attr_accessor :validateQuotationWSFlag, :prdPremiumModelMap, :hmQuotPrdComputedAttributes 
      attr_accessor :currentRate, :currentIllustrationRate, :currentQuotationPrdInvFundDO, :currentCycleCount, :finalMap, :templatePageMappingDO
      attr_accessor :htmlContent, :outputPreferencesDO
      attr_accessor :isSIModelRateFundWise, :originalSIModel, :currentRateTypeCd
      attr_accessor :loopReference
      attr_accessor :results, :computationCycles
      attr_accessor :modelAdditionalParams, :leadRPQDO
      
      def initialize
        @hmRiderComputedAttributes = Hash.new
        @hmFundComputedAttributes = Hash.new
        @modelAdditionalParams = {}
        @currentCycleCount = 0
      end  
      
      def getIllustrationHeaderFieldValue(fieldName, forRate=nil)
        return getIllustrationTableFieldValue(@illustrationHeader, fieldName, forRate)
      end
      
      def getIllustrationHeaderField(fieldName, forRate=nil)
        return getIllustrationTableField(@illustrationHeader, fieldName,forRate);
      end
      
      def getIllustrationHeaderFieldResult(forRate) 
        headerFieldResultforRate = nil
        @illustrationHeader.fieldResultList.each do |innerRateFieldResult|
          if innerRateFieldResult.objectName == forRate.to_s
            headerFieldResultforRate = innerRateFieldResult;
            break;
          end
        end
        return headerFieldResultforRate;
      end
      
      def getIllustrationTableField(fieldResultTable, fieldName, forRate)
        fieldToReturn = nil
        if fieldResultTable
          if fieldResultTable.has_key? fieldName
            fieldToReturn = fieldResultTable.getFieldValueDO(fieldName);
          else #if does not exist as part of every cycle fields.. check if computed per rate.
            if forRate
              fieldResultTable.fieldResultList.each do |innerRateFieldResult|
                if innerRateFieldResult.getObjectName() == forRate.to_s
                  fieldToReturn = innerRateFieldResult.fieldValueDO.getFieldValueDO(fieldName)
                  break
                end
              end
            end
          end
        end
        return fieldToReturn;
      end

      def getIllustrationTableFieldValueObject_new(fieldResultTable, fieldName, forRate)
        valueToReturn = nil
        illustrationFacet = originalSIModel.getIllustrationFacet(fieldName)
        unless illustrationFacet
          illustrationFacet = originalSIModel.getIllustrationFacet(fieldName[0,fieldName.index("_summation")]) if fieldName.include? "_summation"
        end  
        return valueToReturn unless illustrationFacet
        case illustrationFacet.computationFreqCd
        when "EVERYCYCLE","ONCE"
          if fieldResultTable.containsFieldInMap fieldName
            valueToReturn = fieldResultTable.getFieldValueObject(fieldName)
          end
        when "EVERYCYCLEPERRATE"
          if forRate
            forRateStr = forRate.to_s
            fieldResultTable.fieldResultList.each do |innerRateFieldResult|
              if innerRateFieldResult.objectName == forRateStr
                if innerRateFieldResult.containsFieldInMap(fieldName)
                  valueToReturn = innerRateFieldResult.getFieldValueObject(fieldName)
                  fieldObjFound = true
                  break
                end
              end
            end
          end
        when nil
          if illustrationFacet.computePerInstanceOf == "FUND"
            if @currentQuotationPrdInvFundDO
              liFundFldRes = @hmFundComputedAttributes[@currentQuotationPrdInvFundDO]
              if liFundFldRes and liFundFldRes.size > @currentCycleCount
                fundFieldResultForCycle = liFundFldRes[currentCycleCount]
                if @isSIModelRateFundWise
                  illustrationFundRate = @originalSIModel.getFundRate(@currentQuotationPrdInvFundDO.fundCd, @currentRateTypeCd)
                  forRate = illustrationFundRate.rate
                  if fundFieldResultForCycle.containsFieldInMap fieldName
                    valueToReturn = fundFieldResultForCycle.getFieldValueObject(fieldName)
                  else
                    forRateStr = forRate.to_s
                    fundFieldResultForCycle.fieldResultList.each do |innerRateFieldResult|
                      if innerRateFieldResult.objectName == forRateStr
                        if innerRateFieldResult.containsFieldInMap fieldName
                          valueToReturn = innerRateFieldResult.getFieldValueObject(fieldName)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        return valueToReturn
      end

      def getIllustrationTableFieldValueObject(fieldResultTable, fieldName, forRate)
        valueToReturn = nil
        fieldObjFound = false
        if fieldResultTable
          if fieldResultTable.containsFieldInMap fieldName
            valueToReturn = fieldResultTable.getFieldValueObject(fieldName)
            fieldObjFound = true
          else #if does not exist as part of every cycle fields.. check if computed per rate.
            if forRate
              forRateStr = forRate.to_s

              fieldResultTable.fieldResultList.each do |innerRateFieldResult|
                if innerRateFieldResult.objectName == forRateStr
                  if innerRateFieldResult.containsFieldInMap(fieldName)
                    valueToReturn = innerRateFieldResult.getFieldValueObject(fieldName)
                    fieldObjFound = true
                    break
                  end  
                end #if innerRateFieldResult.objectName == forRateStr
              end #fieldResultTable.fieldResultList.each do |innerRateFieldResult| 

              #if the field was not found as part of per rate field objects then it must be part of fund fields
              if not fieldObjFound and @currentQuotationPrdInvFundDO
                liFundFldRes = @hmFundComputedAttributes[@currentQuotationPrdInvFundDO]

                if liFundFldRes and liFundFldRes.size > @currentCycleCount
                  fundFieldResultForCycle = liFundFldRes[currentCycleCount]
                  if @isSIModelRateFundWise
                    illustrationFundRate = nil
                    @originalSIModel.IllustrationRateList.each do |illustrationRate|
                      if @currentQuotationPrdInvFundDO.fundCd == illustrationRate.fundCd
                        if @currentRateTypeCd and @currentRateTypeCd == illustrationRate.rateTypeCd
                          illustrationFundRate = illustrationRate
                          break
                        end #if @currentRateTypeCd and @currentRateTypeCd == illustrationRate.rateTypeCd
                      end #if @currentQuotationPrdInvFundDO.fundCd == illustrationRate.fundCd
                    end #@originalSIModel.IllustrationRateList.each do |illustrationRate|

                    unless illustrationFundRate
                      #puts "No rate defined for fund #{@currentQuotationPrdInvFundDO.fundCd}"
                    else
                      forRate = illustrationFundRate.rate
                    end #unless illustrationFundRate
                  end #if @isSIModelRateFundWise
                  valueToReturn = getIllustrationTableFieldValueObject(fundFieldResultForCycle, fieldName, forRate)
                end #if liFundFldRes and liFundFldRes.size > @currentCycleCount
              end #if not fieldObjFound and currentQuotationPrdInvFundDO
            end #if forRate
          end #if fieldResultTable.containsFieldInMap fieldName
        end #if fieldResultTable 
        return valueToReturn
      end

      def getIllustrationTableFieldValue(fieldResultTable, fieldName, forRate)
        #retObj = getIllustrationTableFieldValueObject_new(fieldResultTable, fieldName, forRate)
        retObj = getIllustrationTableFieldValueObject(fieldResultTable, fieldName, forRate)
        return retObj
      end
        
      def group_summation(fieldname, fromCycle, toCycle)
        summation = 0
        return summation if fromCycle < 0
        actualFieldName = "arr_#{fieldname}"
        actualFieldName << (@currentQuotationPrdInvFundDO ? @currentQuotationPrdInvFundDO.fundCd : "")
        actualFieldName << (@currentIllustrationRate ? @currentIllustrationRate.rateTypeCd : "")
        methodName = actualFieldName.to_sym
        array = @results.send methodName
        if array and array != 0
          ((fromCycle - 1)..(toCycle - 1)).each do |i|
            element = array[i]
            summation += element
          end
        else
          listFieldResult = @listCalculation
          for i in fromCycle..toCycle
            next if ((i-1) == listFieldResult.size) or ((i - 1) < 0)
            currResult = listFieldResult[i-1]
            @currentCycleCount = i-1
            fieldValue = getIllustrationTableFieldValue(currResult, fieldname, @currentRate)
            summation += fieldValue if fieldValue
          end
        end  
        return summation
      end #def group_summation(fieldName, fromCycle, toCycle)

      def group_minimum(fieldname, fromCycle, toCycle)
        #puts "group_minimum fieldName: #{fieldname} fromCycle: #{fromCycle} toCycle: #{toCycle}"
        minimum = nil
        return minimum if fromCycle < 0
        actualFieldName = "arr_#{fieldname}"
        actualFieldName << (@currentQuotationPrdInvFundDO ? @currentQuotationPrdInvFundDO.fundCd : "")
        actualFieldName << (@currentIllustrationRate ? @currentIllustrationRate.rateTypeCd : "")
        #actualFieldName << (rateType ? rateType : (@currentIllustrationRate ? @currentIllustrationRate.rateTypeCd : ""))
        methodName = actualFieldName.to_sym
        array = @results.send methodName
        if array and array != 0
          ((fromCycle - 1)..(toCycle - 1)).each do |i|
            element = array[i]
            minimum = element if minimum == nil or minimum > element
          end
        else
          listFieldResult = @listCalculation
          i = fromCycle
          while i<= toCycle
            next if ((i -1) == listFieldResult.size) or ((i-1) < 0)
            currResult = listFieldResult[i - 1]
            @currentCycleCount = i - 1
            fieldValue = getIllustrationTableFieldValue(currResult, fieldname, @currentRate)
            if minimum
              minimum = fieldValue if (fieldValue and (fieldValue < minimum or i == fromCycle))
            else
              minimum = fieldValue
            end  
            
            i+=1
          end
        end  
        return minimum
      end #def group_minium(fieldname, fromCycle, toCycle)

      def group_maximum(fieldname, fromCycle, toCycle)
        #puts "group_maximum fieldname: #{fieldname} fromCycle: #{fromCycle} toCycle: #{toCycle}"
        maximum = nil
        return maximum if fromCycle < 0
        actualFieldName = "arr_#{fieldname}"
        actualFieldName << (@currentQuotationPrdInvFundDO ? @currentQuotationPrdInvFundDO.fundCd : "")
        actualFieldName << (@currentIllustrationRate ? @currentIllustrationRate.rateTypeCd : "")
        methodName = actualFieldName.to_sym
        array = @results.send methodName
        if array and array != 0
          ((fromCycle - 1)..(toCycle - 1)).each do |i|
            element = array[i]
            maximum = element if maximum == nil or maximum < element
          end
        else  
          listFieldResult = @listCalculation
          i = fromCycle
          while i <= toCycle
            next if ((i -1) == listFieldResult.size) or ((i-1) < 0)
            currResult = listFieldResult[i - 1]
            @currentCycleCount = i - 1
            fieldValue = getIllustrationTableFieldValue(currResult, fieldname, @currentRate)
            if maximum
              maximum = fieldValue if (fieldValue and (fieldValue > maximum or i == fromCycle))
            else
              maximum = fieldValue
            end  
            i+=1
          end
        end 
        return maximum
      end #def group_maximum(fieldname, fromCycle, toCycle)

      def group_irr(fieldName, fromCycle, toCycle, rate, lastFieldName)
        irr = 0
        #TODO
        return irr
      end #def group_irr(fieldName, fromCycle, toCycle, rate, lastFieldName) 

      def group_valueAsOf(fieldName,cycleCount, rateType=nil)
        valueAsOf = 0
        actualFieldName = "arr_#{fieldName}"
        actualFieldName << (@currentQuotationPrdInvFundDO ? @currentQuotationPrdInvFundDO.fundCd : "")
        actualFieldName << (rateType ? rateType : (@currentIllustrationRate ? @currentIllustrationRate.rateTypeCd : ""))
        methodName = actualFieldName.to_sym
        array = @results.send methodName
        if array and array != 0
          valueAsOf = array[cycleCount - 1] if array.size >= cycleCount
        else  
          if cycleCount > 0
            listFieldResult = @listCalculation
            currResult = listFieldResult[cycleCount - 1]
            valueAsOfRate = @currentRate
            if rateType and rateType != ''
              if @illustrationModel
                illusRateDO = @illustrationModel.getIllustrationRate(rateType)
                valueAsOfRate = illusRateDO.rate if illusRateDO
              end  
            end  
            @currentCycleCount = cycleCount - 1
            @currentRateTypeCd = rateType
            #valueAsOf = self.getIllustrationTableFieldValueObject_new(currResult, fieldName, valueAsOfRate)
            valueAsOf = self.getIllustrationTableFieldValueObject(currResult, fieldName, valueAsOfRate)
          end
        end  
        return valueAsOf
      end

      def group_ProjectionValue(totPremiumPaidWithTopup_fieldName, projectedValueRate_fieldName)
        retValue = 0
        currentRateValue = 0
        totPremiumPaidWithTopup = 0
        listFieldResult = @listCalculation
        rateFieldValue = getIllustrationTableFieldValue(listFieldResult[listFieldResult.size - 1], projectedValueRate_fieldName, @currentRate)
        currentRateValue = rateFieldValue if rateFieldValue
        listFieldResult.each do |currResult|
          fieldValue = getIllustrationTableFieldValue(currResult, totPremiumPaidWithTopup_fieldName, @currentRate)
          if fieldValue
            totPremiumPaidWithTopup = fieldValue
          else
            totPremiumPaidWithTopup = 0  
          end #if fieldValue
          retValue += totPremiumPaidWithTopup
          retValue += (currentRateValue/100) * retValue
        end #listFieldResult.each do |currResult|
      end  #def group_ProjectionValue(totPremiumPaidWithTopup_fieldName, projectedValueRate_fieldName)

      def input_maximum(inputSource,inputDataElement)
        objDOList = getObjDOList(inputSource)
        maximum = 0.0
        if objDOList
          objDOList.each do |objDO|
            value = objDO.send inputDataElement.to_sym
            maximum = value.to_f if value and value.to_f > maximum.to_f
          end
        end

        return maximum
      end  

      def input_minimum(inputSource,inputDataElement)
        objDOList = getObjDOList(inputSource)
        minimum = nil
        if objDOList
          objDOList.each do |objDO|
            value = objDO.send inputDataElement.to_sym
            if minimum
              minimum = value.to_f if value and value.to_f <= minimum.to_f
            else  
              minimum = value.to_f
            end  
          end
        end
        return minimum
      end

      def input_summation(inputSource,inputDataElement)
        objDOList = getObjDOList(inputSource)
        summation = 0.0
        if objDOList
          objDOList.each do |objDO|
            value = objDO.send inputDataElement.to_sym
            summation += value if value
          end
        end  
        return summation
      end  

      def getObjDOList(inputSource)
        objDOList = nil
        if inputSource.include? "self.quotation.getWithdrawal"
          objDOList = baseDO.QuotationWithdrawalList          
        elsif inputSource.include? "InvestmentFund"
          objDOList = baseDO.getBaseProduct.QuotationProductInvestmentFundList
        elsif inputSource.include? "Rider"
           objDOList = baseDO.getRiders   
        elsif inputSource.include? "quotation.getParty"
          objDOList = baseDO.getPartyListByRoleCd("SUPPLEMENTARY")
        elsif inputSource.include? "Topup"
          objDOList = baseDO.QuotationTopUpList
        end
        return objDOList
      end

      def method_missing(name, *args)
        puts ">>>Missing method in QuotationIO: methodName: #{name}"
        puts Kernel.caller
      end  

      def createAttr(attr)
        methodName = "#{attr}="
        self.instance_eval { class << self; self end }.send(:attr_accessor, attr) unless self.respond_to? methodName
      end

      def resetModelCalculation
        listCalculation = Array.new
        illustrationHeader = nil
        @hmRiderComputedAttributes = Hash.new
        @hmFundComputedAttributes = Hash.new               
      end

      def getModelAdditionalParams
        return @modelAdditionalParams;
      end

      def setModelAdditionalParams(modelAdditionalParams)
        @modelAdditionalParams = modelAdditionalParams
      end

      def addModelAdditionalParams(paramKey, paramValue)
        @modelAdditionalParams[paramKey] = paramValue
      end

    end
  end
end
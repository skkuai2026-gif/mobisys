require 'Product/product_b_o'
require 'date'

module MobiSys
    class CalculatorBO
      
#       Human Life Value     
#        property :field01, :int #How much annual income will your dependants need if you die today?
#        property :field02, :int #How much annual income does your family get from other sources (other than your earnings)? (Rs.)
#        property :field03, :int #What is your expected inflation rate? (percent)
#        property :field04, :int #What is your expected return on investment? (percent)
#        property :field05, :int #For how many years do you want to provide this income for your family? (Years)
#        property :field06, :int #If you have any outstanding loans in your name which your family would have to repay, give the amount (Rs.)
#        property :field07, :int #What is the present value of all your investments? (Rs.)
#        property :field08, :int #How much insurance do you already have? (Rs.)
        
       def self.humanLifeIlustration(calculator)
         neededIncome = calculateFutureValue(calculator.field01,calculator.field03,calculator.field05)
         familyTotalIncome=calculateFutureValue(calculator.field02,calculator.field03,calculator.field05)
         incomeNeeds =(neededIncome.to_f - familyTotalIncome.to_f)
         incomeNeedsVal=incomeNeeds
         outstandingLoansOPVal=calculator.field06.to_i
         insuranceNeedsVal=incomeNeeds-(-1*calculator.field06.to_i)
         availableInvestmentsOPVal=calculator.field07.to_i
         presentInsuranceOPVal=calculator.field08.to_i
         additionalInsuranceVal=incomeNeeds - (-1 *calculator.field06.to_i)-calculator.field08.to_i
         
         calculator.output03=incomeNeedsVal
         calculator.output04=outstandingLoansOPVal
         calculator.output05=insuranceNeedsVal
         calculator.output06=availableInvestmentsOPVal
         calculator.output07=presentInsuranceOPVal
         calculator.output08=additionalInsuranceVal
       end

       ########################################################################################################################################
       
#       Child education
#       property :field23, :int #Child's Age
#       property :field24, :int #At what age your child would enter College
#       property :field25, :int #Aspired Degree
#       property :field26, :int #Current cost of degree
#       property :field27, :int #Inflation rate %
       
       def self.calcChildEducation(calculator)
         stepSize=10000
         term=(calculator.field24.to_i-calculator.field23.to_i)
         calculator.output02=calculateFutureValue(calculator.field26,calculator.field27,term)
         inputValue = 0  
         if term != 0
           inputValue= calculator.output02/(term)
         end
         calculator.output01=calculateApproximation(inputValue,calculator.field27.to_i,term,calculator.output02.to_i,stepSize)
       end
       ##############################################################################################################################################

#    Marriage Input
#       property :field09, :int #Your Age
#       property :field10, :int #Child's Age
#       property :field11, :int #How much would you like to spend on your Child's marriage
#       property :field12, :int #At what age your child would get married
#       property :field13, :int #Inflation rate %
#       property :field14, :int #Expected growth rate %
#    Marriage  Output
#         property :output09, :int #Annual investment regired
#         property :output10, :int #future cost of Marriage 
       
      def self.calcMarriageValue(calculator)
         stepSize=10000
         term=(calculator.field12.to_i-calculator.field10.to_i)
         currentCost=calculator.field11
         futureValueRate=calculator.field13
         growthRate=calculator.field14.to_i
         futureCost=calculateFutureValue(currentCost,futureValueRate,term)
         calculator.output10=futureCost
         inputValue = 0  
         if term != 0
           inputValue= futureCost.to_f/(term)
         end
         needToinvestAnnualy=calculateApproximation(inputValue,growthRate,term,futureCost.to_i,stepSize)
         calculator.output09=needToinvestAnnualy
      end
       ############################################################################################################################################
           
#     Retirement Inputs
#       property :field15, :int #Monthly Income Required (Current Value)
#       property :field16, :int #Years left for Retirement(Years)
#       property :field17, :int #Inflation Expected upto retirement(%)
#       property :field18, :int #% Increase in Investments/year
#       property :field19, :int #Return Expected(%) from Investments before retirement
#       property :field20, :int #Total Retirement years
#       property :field21, :int #inflation Expected during retirement(%)
#       property :field22, :int #Return Expected(%) from Investments during retirement
#    Retirement Calculator Outputs
#       property :output11, :int #Annual investment regired
#       property :output12, :int #Retiremrnt Cost
      
      def self.calcRetirementValue(calculator)
               
        # calculating cost at retirement year
               stepSize=10000
               termW=calculator.field16.to_i
               currentCostW=(calculator.field15.to_f)*12
               futureValueRateW=calculator.field17
               growthRateW=calculator.field19.to_i
               futureCost=calculateFutureValue(currentCostW,futureValueRateW,termW)
        
        #Calculating total reirement cost all retirement years         
               termR=calculator.field20.to_i
               currentCostR=futureCost
               futureValueRateR=calculator.field21
               growthRateR=calculator.field22.to_i
               totalFutureCost=computeAccumulatedFutureValue(futureCost, futureValueRateR, termR)
               calculator.output12=totalFutureCost
              
               
        #investment required yearly 
               inputValue = 0  
               if termW != 0
                 inputValue= totalFutureCost.to_f/(termW)
               end   
               needToinvestAnnualy=calculateApproximation(inputValue,growthRateW,termW,totalFutureCost,stepSize)
               calculator.output11=needToinvestAnnualy
               #calculator.output11= 0
      end 
      #############################################################################################################################################
      
      # Rainbow retirement solver
      #      property :field28, :string  #gender
      #      property :field29, :int     #age
      #      property :field30, :string  #smoker
      #      property :field31, :int     #interest rate
      #      property :field32, :int     #surrender value
      #      property :field33, :int     #max year
      #      property :field34, :string  #solver type
      #      property :field35, :int     #target year
      #      property :field36, :int     #premium value
      
      def self.solveRR1(calculator)

        # new quotation
        @quotation = Quotation.new        
        @quotation.age = calculator.field29       
        @quotation.genderCd = calculator.field28
        @quotation.occupationCd = '1'
         
        # Base
        @baseProduct = QuotationProduct.new
        @baseProduct.productTypeCd = "PLAN"
        @baseProduct.productFamilyCd = "ENDOWMENT"
        @baseProduct.planCode = "RR1"
        @baseProduct.baseSumAssured = 100
        @baseProduct.productId = "RR1"
        @baseProduct.paymentFrequencyCd = "YEARLY"
        @quotation.addQuotationProduct(@baseProduct)

        @baseProduct.baseAnnualPremium = calculator.field36
        @baseProduct.modalPremium = calculator.field36
          
        MobiSys::ProductBO.implementPlanCode(@baseProduct, @quotation.age)

        if calculator.field34 == "PREMIUMPERIOD" 
               
          @benefitTable = MobiSys::ProductBO.generateRREndowmentIllustration(@quotation, @baseProduct, calculator.field31)
          
          @benefitTable.each do |benefitRow|
            if benefitRow != nil
              if benefitRow["surrenderValueL"] != nil 
                if benefitRow["surrenderValueL"].to_f > calculator.field32.to_f
                  calculator.field35 = benefitRow["policyYear"]
                  calculator.field32 = benefitRow["surrenderValueL"].to_f
                  break
                else
                  puts " #{benefitRow["policyYear"]}: #{benefitRow["surrenderValueL"]}"
                end
              end
            end
          end
        
        else
          
          error_p = 1
          error=2000
          stepsize = 10000

          inputValue = calculator.field32.to_f / 100.0
          changedInput = inputValue
          
          while error > 500 || error < 0 do
            puts error.to_s << " | " << changedInput.to_s

            @baseProduct.baseAnnualPremium = changedInput 
            @baseProduct.modalPremium = changedInput          
            
            @benefitTable = MobiSys::ProductBO.generateRREndowmentIllustration(@quotation, @baseProduct, calculator.field31)
            
            if @benefitTable[calculator.field35.to_i] == nil
              break
            end
            
            @currSurrender = @benefitTable[calculator.field35.to_i]["surrenderValueL"]
              
            error = @currSurrender - calculator.field32.to_f
            if (!(error<0 and error_p<0)&&!(error>0 and error_p>0))
                 stepsize = stepsize.to_f / 10
            end
              # changedInput = changedInput - (error>0 ? stepsize:(stepsize*(-1)))
            if(error<0)
               changedInput = changedInput + stepsize 
            else
               changedInput = changedInput -(stepsize)
            end
            error_p = error
          end
          calculator.field36 = changedInput
          calculator.field32 = @currSurrender

        end
               
      end 
      #############################################################################################################################################
      
      def self.calculateFutureValue(currentValue, rate , term)
            futureValue=currentValue
            if(term.to_i>0)
              for i in (term.to_i).downto(1)
                futureRate=(1 + rate.to_f/100)
                futureValue = futureRate.to_f * futureValue.to_f 
              end
            end
            return futureValue;
      end
       ##########################################################################################################################################     
      
      def self.calculateApproximation(inputValue, rate, years, targetValue, stepsize)
          error_p = 1
          error=2
          changedInput = inputValue
          while error > 1 || error < -1 do
            puts error.to_s << " | " << changedInput.to_s
               afv = computeAccumulatedFutureValue(changedInput, rate, years)
               error = afv - targetValue
               if (!(error<0 and error_p<0)&&!(error>0 and error_p>0))
                   stepsize = stepsize.to_f / 10
               end
#             changedInput = changedInput - (error>0 ? stepsize:(stepsize*(-1)))
               if(error<0)
                 changedInput = changedInput + stepsize 
               else
                 changedInput = changedInput -(stepsize)
               end
                error_p = error
           end
           return changedInput
      end
      ###########################################################################################################################################
      
     def self.computeAccumulatedFutureValue(inputValue, rate, years)
           accumulatedFutureValue = 0
            for year in 0..years-1
               accumulatedFutureValue += calculateFutureValue(inputValue, rate,year)
           end 
           return accumulatedFutureValue
      end
     ############################################################################################################# 
    
      end
    end

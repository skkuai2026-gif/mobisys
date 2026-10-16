require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Policy/policy_b_o'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Quotation/quotation_b_o'
require 'NeedAnalysis/need_analysis_util'
require 'date'

class NeedAnalysisController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper

  def generateQuestionaire
    @wrapperQuestionSets = Hash.new
    @questionSetQuestionHM = Hash.new
    @questionSetHM = Hash.new
    @needAnalysis = NeedAnalysis.new
    @needAnalysis.leadGuid = @params['leadGuid']
    wrapperQuestionSet = QuestionSet.find(:first, 
                                                :conditions => {
                                                   { 
                                                     :name => 'questionSetCd'
                                                   } => 'LifeStyleAndPersonal'
                                                })
            puts ">>>>>>Wrapper Question Set: #{wrapperQuestionSet}"                                    
          # each wrapper question would have a list of leaf questions
                                                
          leafQuestionSetCdList = QuestionSetMap.find(:all, 
                                                      :conditions => {
                                                         { 
                                                           :name => 'parentQuestionSetCd'
                                                         } => 'LifeStyleAndPersonal'
                                                      },
                                                      :order=>'displayOrder',  
                                                      :orderdir=>'ASC'  
                                                      )
            puts ">>>>>>Leaf Question Set: #{leafQuestionSetCdList}"
          # iterate through each child question
          leafQuestionSetCdList.each do |questionSetMap|
            
            childQuestionSetList = QuestionSet.find(:all, 
                                                :conditions => {
                                                   { 
                                                     :name => 'questionSetCd'
                                                   } => questionSetMap.childQuestionSetCd
                                                })
                                                
             childQuestionSetList.each do |childQuestionSet|
                 puts ">>>>>>Child Question Set: #{childQuestionSet.questionSetCd}"
                 # iterate through leaf questions and prepare hashmap of leaf question set, questionsetquestion list
                 questionSetQuestionList = QuestionSetQuestion.find( :all, 
                                                                     :conditions => {
                                                                         {
                                                                           :name => 'questionSetCd'
                                                                         } => childQuestionSet.questionSetCd
                                                                       },
                                                                     :order=>'displayOrder',  
                                                                     :orderdir=>'ASC'  
                                                                   )
                 puts ">>>Found #{questionSetQuestionList.size} questions"                                                 
                 childQuestionSet.setQuestionSetQuestionList(questionSetQuestionList)
                 wrapperQuestionSet.addQuestionSet(childQuestionSet)
                 questionSetQuestionList.each do |questionSetQuestion|
                   serviceQuestion = MobiSys::PolicyBO.getServiceQuestion(@needAnalysis,childQuestionSet.questionSetCd,questionSetQuestion.questionCd,questionSetQuestion.dataElementCd)
                   puts ">>>>>Found serviceQuestionDO" if serviceQuestion
                   unless serviceQuestion
                     puts ">>>>>Creating Service DO for Question set question: #{questionSetQuestion.questionCd}"
                     serviceQuestion = ServiceQuestion.new
                     serviceQuestion.questionCd = questionSetQuestion.questionCd
                     serviceQuestion.dataElementCd = questionSetQuestion.dataElementCd
                     serviceQuestion.response = questionSetQuestion.defaultValue
                     @needAnalysis.addServiceQuestion(serviceQuestion)
                     #@questionSetQuestionHM[questionSetQuestion.questionCd] = serviceQuestion
                     @questionSetHM[questionSetQuestion.questionCd] = questionSetQuestion
                     puts ">>>>>Created and added Service DO for Question set question:"
                   end
                 end
             end                                     
          end
          
          @wrapperQuestionSets['LifeStyleAndPersonal'] = wrapperQuestionSet
          @needAnalysis.ServiceQuestionList.each do |sq|
            puts ">>>question cd: #{sq.questionCd}"
          end      
          puts "================================================================"
    
  render :action => :renderQuestionnaire
  end
  
  def execute
    @needAnalysis = MobiSys::BrowserHelper.convertToObject('NeedAnalysis', @params['NeedAnalysis'])
    @needAnalysis.persistAll
    puts "#{@needAnalysis.ServiceQuestionList}"
    profileList = MobiSys::NeedAnalysisUtil.getProfileList(@needAnalysis,'NEEDANALYSIS')
    profileList.each do |profile|
      puts ">>>Profile received: #{profile.result}"
    end 
    puts "#{@needAnalysis.object}"
    @needAnalysis = NeedAnalysis.loadObject(  :first,
                           :conditions => {
                             :object => @needAnalysis.object
                           }
                        )      
    @retirementAge = 0;                    
    needAnalysisServiceQuestions = @needAnalysis.ServiceQuestionList            
    if needAnalysisServiceQuestions != nil && needAnalysisServiceQuestions.size > 0
      needAnalysisServiceQuestions.each do |needAnalysisServiceQuestion|
        if needAnalysisServiceQuestion.dataElementCd == "expectedRetirementAge"
          @retirementAge = needAnalysisServiceQuestion.response
        end
        puts "Adding Service Questions"
      end
    end 
    render :action => :graphInput, :back => '/app/Menu/leads'
  end  
  
  def createEvent
    id = @params['needAnalysisObject']
    @counter = @params['counter']
    puts ">>>>>>#{@counter}"  
    puts "The id sent is #{id}"
    @needAnalysis = NeedAnalysis.new       
    @needAnalysis.object = id    
    setObjectCount(@needAnalysis, @counter)
    puts ">>>Object count is: #{getObjectCount(@needAnalysis)}"
    puts ">>>Parent is: #{@needAnalysis.object}"
    setObjectMapping(@needAnalysis, @needAnalysis.class.name)    
    puts "Inside Create Event #{@needAnalysis}"                           
    @event = Event.new
    puts ">>>params received in createEvent: #{@params}"
    @event.age = @params['age']
    @event.amount = @params['amount']
    render :action => :renderEvents, :layout => false, :use_layout_on_ajax => false  
  end 
  
  def calculate
    @currentAge = 0
    @Income = 0
    @Expenses = 0
    @EMI = 0
    @EMIPeriod = 0
    @totalAssets = 0
    @retirementAge = 0
    @retirementAmount = 0
    @adhocExpenses = 0
    @incomeAddition = 0
    @maxAmountOnYAxis = 0
    @needAnalysis = MobiSys::BrowserHelper.convertToObject('NeedAnalysis', @params['NeedAnalysis'])
    needAnalysisObject = @needAnalysis.object
    @needAnalysisMerge = NeedAnalysis.loadObject( :first,
                                                  :conditions => {
                                                    :object => needAnalysisObject
                                                  }
                                               )    
    needAnalysisServiceQuestions = @needAnalysisMerge.ServiceQuestionList            
    if needAnalysisServiceQuestions != nil && needAnalysisServiceQuestions.size > 0
      needAnalysisServiceQuestions.each do |needAnalysisServiceQuestion|
        @needAnalysisMerge.addServiceQuestion(needAnalysisServiceQuestion)
      end
    end                               
    needAnalysisEvents = @needAnalysis.EventList
      if needAnalysisEvents != nil && needAnalysisEvents.size > 0
        needAnalysisEvents.each do |needAnalysisEvent|
          @needAnalysisMerge.addEvent(needAnalysisEvent)
        end
      end
    @needAnalysisMerge.persistAll
    puts "persisted" 
    @mainHash = Hash.new
    
    if needAnalysisServiceQuestions != nil && needAnalysisServiceQuestions.size > 0
      needAnalysisServiceQuestions.each do |needAnalysisServiceQuestion|
        if needAnalysisServiceQuestion.dataElementCd == "currentAge"
          @currentAge = (needAnalysisServiceQuestion.response).to_i
        elsif needAnalysisServiceQuestion.dataElementCd == "EMIPeriod"
          @EMIPeriod = (needAnalysisServiceQuestion.response).to_i
        end  
      end
    end  
    @EMITillAge =  @currentAge + @EMIPeriod
    @startAge = @currentAge
    if needAnalysisServiceQuestions != nil && needAnalysisServiceQuestions.size > 0
      needAnalysisServiceQuestions.each do |needAnalysisServiceQuestion|
        if needAnalysisServiceQuestion.dataElementCd == "expectedRetirementAge"
          @retirementAge = (needAnalysisServiceQuestion.response).to_i
        end  
      end
    end 
    subHash = Hash.new             
          needAnalysisEvents = @needAnalysisMerge.EventList
          if needAnalysisEvents != nil && needAnalysisEvents.size > 0
            @tempcounter = 0
            needAnalysisEvents.each do |needAnalysisEvent|
              if (needAnalysisEvent.age).to_i == @currentAge
                @adhocExpenses = (needAnalysisEvent.amount).to_i
              end
              if needAnalysisEvent.eventType == "RETIREMENT"
                @retirementAge = (needAnalysisEvent.age).to_i
                @retirementAmount = (needAnalysisEvent.amount).to_i
              end
            end
          end
          @alert = 0
          
          needAnalysisServiceQuestions = @needAnalysisMerge.ServiceQuestionList            
          if needAnalysisServiceQuestions != nil && needAnalysisServiceQuestions.size > 0
            needAnalysisServiceQuestions.each do |needAnalysisServiceQuestion|
              if needAnalysisServiceQuestion.dataElementCd == "monthlyIncome"
                @Income = (needAnalysisServiceQuestion.response).to_i
                @Income = @Income * 12
                subHash["yearlyIncome"] = @Income
                @incomeAddition = @incomeAddition + @Income
              elsif needAnalysisServiceQuestion.dataElementCd == "monthlyExpenses"
                @Expenses = (needAnalysisServiceQuestion.response).to_i
                @Expenses = @Expenses * 12
                subHash["yearlyExpenses"] = @Expenses
              elsif needAnalysisServiceQuestion.dataElementCd == "EMI"
                @EMI = (needAnalysisServiceQuestion.response).to_i
                @EMI = @EMI * 12
                subHash["EMI"] = @EMI    
              elsif needAnalysisServiceQuestion.dataElementCd == "totalAssets"
                @totalAssets = (needAnalysisServiceQuestion.response).to_i
              end  
              subHash["adhocExpenses"] = @adhocExpenses
              @adhocExpenses = 0  
            end
          end 
          @totalAssetstemp = @Income + @totalAssets
          @totalAssetstemp = @totalAssetstemp + (@totalAssets * 0.1)
          @totalAssetstemp = @totalAssetstemp - @Expenses
          @totalAssetstemp = @totalAssetstemp - @EMI
          @totalAssetstemp = @totalAssetstemp - @adhocExpenses
          subHash["savings"] = @totalAssetstemp
          @maxAmountOnYAxis = @totalAssetstemp
          @totalAssets = @totalAssetstemp 
          subHash["termInsurance"] = 0
          @adhocExpenses = 0  
    @mainHash[@currentAge] = subHash
    @currentAge = @currentAge + 1
    @EMIPeriod = @EMIPeriod - 1
         
    while @currentAge <= 100 do  
      subHash = Hash.new         
      if @currentAge <= @retirementAge
        needAnalysisEvents = @needAnalysisMerge.EventList
        if needAnalysisEvents != nil && needAnalysisEvents.size > 0
          @tempcounter = 0
          needAnalysisEvents.each do |needAnalysisEvent|
            if (needAnalysisEvent.age).to_i == @currentAge
              @adhocExpenses = (needAnalysisEvent.amount).to_i
            end
          end
        end  
        @Incometemp = @Income + (@Income * 0.1)
        @Expensestemp = @Expenses + (@Expenses * 0.08)
        @totalAssetstemp = @Incometemp + @totalAssets
        @totalAssetstemp = @totalAssetstemp + (@totalAssets * 0.1)
        @totalAssetstemp = @totalAssetstemp - @Expensestemp
        @totalAssetstemp = @totalAssetstemp - @EMI
        @totalAssetstemp = @totalAssetstemp - @adhocExpenses
        if @Expensestemp <= (@Incometemp + @totalAssetstemp)
          subHash["yearlyIncome"] = @Incometemp 
          @Income = @Incometemp
          @incomeAddition = @incomeAddition + @Income
          subHash["yearlyExpenses"] = @Expensestemp
          @Expenses = @Expensestemp
          subHash["savings"] = @totalAssetstemp
          @totalAssets = @totalAssetstemp
        else
          subHash["yearlyIncome"] = @Incometemp
          @incomeAddition = @incomeAddition + @Incometemp
          subHash["yearlyExpenses"] = @Incometemp
          subHash["savings"] = @totalAssets
        end
        if @maxAmountOnYAxis < @totalAssets
          @maxAmountOnYAxis = @totalAssets
        end
        if @EMIPeriod > 0
          subHash["EMI"] = @EMI
        else
          subHash["EMI"] = 0
        end
        subHash["adhocExpenses"] = @adhocExpenses  
        @adhocExpenses = 0  
        @mainHash[@currentAge] = subHash
        subHash["termInsurance"] = 0
      else  
        needAnalysisEvents = @needAnalysisMerge.EventList
        if needAnalysisEvents != nil && needAnalysisEvents.size > 0
          @tempcounter = 0
          needAnalysisEvents.each do |needAnalysisEvent|
            if (needAnalysisEvent.age).to_i == @currentAge
              @adhocExpenses = (needAnalysisEvent.amount).to_i
            end
          end
        end
        @Incometemp = @totalAssets * 0.07
        @Expensestemp = @Expenses + (@Expenses * 0.08)
        @totalAssetstemp = @Incometemp + @totalAssets
        @totalAssetstemp = @totalAssetstemp - @Expensestemp
        @totalAssetstemp = @totalAssetstemp - @EMI
        @totalAssetstemp = @totalAssetstemp - @adhocExpenses
        if @Expensestemp <= (@Incometemp + @totalAssetstemp)
          subHash["yearlyIncome"] = @Incometemp
          @Income = @Incometemp
          @incomeAddition = @incomeAddition + @Income
          subHash["yearlyExpenses"] = @Expensestemp
          @Expenses = @Expensestemp
          subHash["savings"] = @totalAssetstemp
          @totalAssets = @totalAssetstemp
        else
          subHash["yearlyIncome"] = @Incometemp
          @incomeAddition = @incomeAddition + @Incometemp
          subHash["yearlyExpenses"] = @Incometemp
          subHash["savings"] = @totalAssets
        end
        if @maxAmountOnYAxis < @totalAssets
          @maxAmountOnYAxis = @totalAssets
        end
        if @EMIPeriod > 0
          subHash["EMI"] = @EMI
        else
          subHash["EMI"] = 0
        end
        subHash["adhocExpenses"] = @adhocExpenses 
        @adhocExpenses = 0     
        @mainHash[@currentAge] = subHash
        subHash["termInsurance"] = 0  
      end
      @currentAge = @currentAge + 1
      @EMIPeriod = @EMIPeriod - 1
    end
    @yearsTillRetirement = @retirementAge - @startAge
    @averageIncome = @incomeAddition/@yearsTillRetirement
    @termInsurance = @averageIncome * 4
    @mainHash.each{|key, value| 
    if key <= @retirementAge
      value["termInsurance"] = @termInsurance
    end
    }
    puts "Main Hash : #{@mainHash}"
    render :action => :needAnalysisProductResults, :back => '/app/Menu/leads'
  end
end

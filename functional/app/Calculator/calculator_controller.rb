require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Calculator/calculator_b_o'

class CalculatorController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper
#  include MobiSys::CalculatorBO
  
  def humanlife
    @calculator = Calculator.new
    render :action => :humanlife
  end
  
  def marriage
    @calculator = Calculator.new
    render :action => :marriage
  end
    
  def retirement
    @calculator = Calculator.new
    render :action => :retirement
  end
  
  def childeducation
    @calculator = Calculator.new
    render :action => :childeducation
  end    

  def rr1Solver
    @calculator = Calculator.new
    @calculator.field29 = 30
    @calculator.field31 = 9
    @calculator.field32 = 1000000
    @calculator.field33 = 30
    
    render :action => :rr1Solver
  end    
 
  def rr1SolverOutput
    @calculator = MobiSys::BrowserHelper.convertToObject('Calculator', @params['Calculator'])
    MobiSys::CalculatorBO.solveRR1(@calculator)
    render :action => :rr1SolverOutput
  end
  
  # GET /Calculator/showcalculator
  def showcalculator
    @calculator = @params['calc']
      
    @level0 =  Level0.find(@params['id'])
    @level0s = Level0.find(
                :all,
                :order => 'sortOrder',
                :orderdir => 'ASC'
              )
    @level1s = Level1.find(
                :all,
                :order => 'sortOrder',
                :orderdir => 'ASC'
              )
              
    @frameworkCollaterals =  Collateral.find(
                                :all, 
                                :conditions => { 
                                  {
                                    :name => "levelCd", 
                                    :op => "IS" 
                                  } => nil
                                } 
                              )
    @collateralHM = {}
      
    @frameworkCollaterals.each_with_index{|collateral,index|
      @collateralHM[collateral.collateralCd] = collateral
    }

    if @calculator == "1"
      redirect :action => :hlv
    elsif @calculator == "2"
      redirect :action => :death
    else
      redirect :action => :hlv
    end
  end
  
  def calcHumanLifeValue
    @calculator = MobiSys::BrowserHelper.convertToObject('Calculator', @params['Calculator'])
    MobiSys::CalculatorBO.humanLifeIlustration(@calculator)
    #@calculator.persistAll
    render :action => :humanlifeoutput
  end
  
def calcMarriageValue
    @calculator = MobiSys::BrowserHelper.convertToObject('Calculator', @params['Calculator'])
    MobiSys::CalculatorBO.calcMarriageValue(@calculator)
    render :action => :marriageoutput
  end
  
def calcRetirementValue
    @calculator = MobiSys::BrowserHelper.convertToObject('Calculator', @params['Calculator'])
    MobiSys::CalculatorBO.calcRetirementValue(@calculator)  
    render :action => :retirementoutput
  end
  
def calcChildEducationValue
    @calculator = MobiSys::BrowserHelper.convertToObject('Calculator', @params['Calculator'])
    MobiSys::CalculatorBO.calcChildEducation(@calculator)  
    render :action => :childeducationoutput
  end

end



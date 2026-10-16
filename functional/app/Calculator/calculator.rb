# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
  
class Calculator
    include MobiSys::MobiSysEntitySchema

  set :schema_version, '1.0'
    
  # Uncomment the following line to enable sync with Level2.
  # enable :sync

  #C2L add model specifc code here
  
  #input fields
  # Human Life
  property :field01, :int #How much annual income will your dependants need if you die today?
  property :field02, :int #How much annual income does your family get from other sources (other than your earnings)? (Rs.)
  property :field03, :int #What is your expected inflation rate? (percent)
  property :field04, :int #What is your expected return on investment? (percent)
  property :field05, :int #For how many years do you want to provide this income for your family? (Years)
  property :field06, :int #If you have any outstanding loans in your name which your family would have to repay, give the amount (Rs.)
  property :field07, :int #What is the present value of all your investments? (Rs.)
  property :field08, :int #How much insurance do you already have? (Rs.)

  # Marriage
  property :field09, :int #Your Age
  property :field10, :int #Child's Age
  property :field11, :int #How much would you like to spend on your Child's marriage
  property :field12, :int #At what age your child would get married
  property :field13, :int #Inflation rate %
  property :field14, :int #Expected growth rate %
 
  # Retirement
  property :field15, :int #Monthly Income Required (Current Value)
  property :field16, :int #Years left for Retirement(Years)
  property :field17, :int #Inflation Expected upto retirement(%)
  property :field18, :int #% Increase in Investments/year
  property :field19, :int #Return Expected(%) from Investments before retirement
  property :field20, :int #Total Retirement years
  property :field21, :int #inflation Expected during retirement(%)
  property :field22, :int #Return Expected(%) from Investments during retirement

  # Child education
  property :field23, :int #Child's Age
  property :field24, :int #At what age your child would enter College
  property :field25, :int #Aspired Degree
  property :field26, :int #Current cost of degree
  property :field27, :int #Inflation rate %
    
  # Rainbow retirement solver
  property :field28, :string  #gender
  property :field29, :int     #age
  property :field30, :string  #smoker
  property :field31, :int     #interest rate
  property :field32, :int     #surrender value
  property :field33, :int     #max year
  property :field34, :string  #solver type
  property :field35, :int     #target year
  property :field36, :int     #premium value
  
  # Out put Fields 
 
  # Child education and Marriage Calculator
  property :output01, :int #Annual investment regired
  property :output02, :int #future cost of degree 
  
  # human life 
  property :output03, :int #Income needed by your dependants (Rs.)
  property :output04, :int #Outstanding loans to be repayed (Rs.)
  property :output05, :int #Total insurance needs (Rs.)
  property :output06, :int #Present value of all your investments (Rs.)
  property :output07, :int #Amount of insurance you already have (Rs.)
  property :output08, :int #Additional amount of life insurance you need to buy (Rs.)
  
  # Marriage Calculator
  property :output09, :int #Annual investment regired
  property :output10, :int #future cost of Marriage 
  
  # Retirement Calculator
   property :output11, :int #Annual investment regired
   property :output12, :int #Retiremrnt Cost
  
  # derived attributes  
  property :userId, :string
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
end

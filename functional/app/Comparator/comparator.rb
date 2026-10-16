# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Comparator
  include Rhom::FixedSchema
  
  set :partition, :master

  # Uncomment the following line to enable sync with Comparator.
  # enable :sync

  #add model specifc code here
  property :comparatorId, :string
  property :categoryCd, :string
  property :productCd, :string
  property :competitorCd, :string
  property :competitorProductCd, :string
  property :collateralCd, :string
  property :versionId, :integer
  
  def self.from_json(o)
      agentReg = Comparator.new;
      agentReg.comparatorId = o["comparatorId"]
      agentReg.categoryCd = o["categoryCd"]
      agentReg.productCd = o["productCd"]
      agentReg.competitorCd = o["competitorCd"]
      agentReg.competitorProductCd = o["competitorProductCd"]
      agentReg.collateralCd = o["collateralCd"]
      agentReg.versionId = o["versionID"]
      return agentReg
    end
end

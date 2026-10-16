require 'CommonModules/schema_module'
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class CompanyFacet
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with CompanyFacet.
  # enable :sync
  set :schema_version, '1.0'
  set :partition, :master

  property :facetCd, :string
  property :actionTypeCd, :string
  property :actionValue, :string
  property :ruleSeq, :integer
  property :lookupKey, :string
  property :lookupDataCd, :string
  property :effectiveFromDt, :date
  property :effectiveToDt, :date

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.CompanyFacetDO"
  end

end

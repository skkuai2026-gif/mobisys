# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class Facet
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with Facet.
  # enable :sync
  set :schema_version, '1.0'
  set :partition, :master

  property :facetId, :string
  property :facetTypeCd, :string
  property :facetApplicabilityCd, :string
  property :description, :string
  property :facetGroupCd, :string
  property :disableFl, :string
  property :facetUsageDesc, :string
  property :facetForCd, :string
  property :companyCd, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time
  
  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.FacetMDO"
  end

  def afterSync

  end

end

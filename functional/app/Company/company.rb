# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/schema_module'

class Company
  include MobiSys::MobiSysFixedSchema

  # Uncomment the following line to enable sync with Company.
  # enable :sync
  set :schema_version, '1.0'
	set :partition, :master

  property :companyCd, :string

  # derived attributes
  property :parentKey, :string
  property :versionID, :integer
  property :id, :integer
  property :guid, :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  has_many 'CompanyFacet'
  has_many 'CompanyFieldMetadata'

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.master.CompanyDO"
  end

  def afterSync
  end

end


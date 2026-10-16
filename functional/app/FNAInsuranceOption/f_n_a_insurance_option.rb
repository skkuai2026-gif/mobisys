# The model has already been created by the framework, and extends Rhom::RhomObject
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class FNAInsuranceOption

  include MobiSys::MobiSysEntitySchema
  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with FNAInsuranceOption.
  # enable :sync
  # add model specific code here

  property :FNAInsuranceOptionSeq,        :integer
  property :FNARequestSeq,     :integer
  property :FNAProductSeq,        :integer
  property :CustomerResponse,        :string
  property :IntroducedFlag,        :string
  property :SelectedFlag,        :string
  property :Term,        :integer
  property :PPT,        :integer
  property :ProductTypeCd,        :string
  property :BaseFNAProductSeq,        :integer

  # derived attributes

  property :userId,       :string
  property :parentKey,    :string
  property :versionID,    :integer
  property :id,           :integer
  property :guid,         :string
  property :systemCreatedDt, :time
  property :systemUpdatedDt, :time

  # model specific methods

  def self.onlineClassName
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.lead.FNAInsuranceOptionDO"
  end

  def afterSync
    # puts "After sync called for FNAInsuranceOption " + self.leadId.to_s
  end

end
# The model has already been created by the framework, and extends Rhom::RhomObject
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

# You can add more methods here
class FNAQuestionResponse

  include MobiSys::MobiSysEntitySchema
  set :schema_version, '1.0'
  # Uncomment the following line to enable sync with FNAQuestionResponse.
  # enable :sync
  # add model specific code here

  property :fnaRequestRefGuid, :string
  property :fnaPartyRefGuid,  :string
  property :fnaQuestionCd,  :string
  property :fnaQuestionLookupDataCd,  :string
  property :customerResponseFl,  :string
  property :responseValue,  :string
  property :removed, :string

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
    return "com.c2lbiz.symbiosys.insurance.businesscommon.dataobjects.fna.FNAQuestionResponseDO"
  end

  def afterSync
    # puts "After sync called for FNAQuestionResponse " + self.leadId.to_s
  end

end
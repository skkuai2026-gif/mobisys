# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'

class Lead
  include MobiSys::MobiSysEntitySchema
  
    set :schema_version, '1.1'

    # Uncomment the following line to enable sync with Lead.
    # enable :sync
  
    property :uploadedFl, :string
    
    def afterSync
      puts "After sync called for lead " + self.leadId.to_s 
      if self.statusCd == "COMPLETED" && self.uploadedFl.to_s != "EMAILANDOTPSENT" && self.leadSourceOther.to_s == ""
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
            begin
                leadParty = self.getLeadParty
                advisorEmail = leadParty.getPartyEmail.emailAddress if leadParty.getPartyEmail
                userId = $userId.to_s
                advisorPhone = leadParty.getPartyContact("PHILIPPINESNUM").contactNum if leadParty.getPartyContact("PHILIPPINESNUM")
                partyId = self.leadId
                syncEntities = Hash.new
                syncEntities[Lead.onlineClassName] = ::JSON.generate([{Lead.onlineClassName => [self.hashForSync]}.to_json])
                syncEntities[Party.onlineClassName] = ::JSON.generate([{Party.onlineClassName => [leadParty.hashForSync]}.to_json])
                begin
                    json = ::JSON.generate(syncEntities)
                rescue StandardError => se
                    puts "Error while generating JSON of request data" + se.to_s
                end
                # leadDetailsHash = { emailId: advisorEmail, userId: userId, mobileNumber: advisorPhone, partyId: partyId, firstName: firstName}
                # result = doJSONPost('/leadSendEmailOtp.run', syncEntities)
                clazz = Class.new do
                    include MobiSys::BrowserHelper 
                end
                obj = clazz.new
                result = obj.doJSONPost('/leadSendEmailOtp.run', json)
                if result.to_s != ""
                    responseHash = Rho::JSON.parse(result.to_s)
                end          
            rescue StandardError => se
                puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
            end
            return
        end
      end   
    end
end

begin 
    require 'Lead/lead_company'
rescue LoadError => e
    puts 'lead_company not included'
end
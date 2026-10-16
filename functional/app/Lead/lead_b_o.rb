require 'CommonModules/commonutil'

module MobiSys
	class LeadBO
		include MobiSys::CommonUtil

		PENDING = "PENDING"
		READYFORSYNC = "READYFORSYNC"
		SYNCDONE = "SYNCDONE"

    
        def self.getDashboard
        	leadsDashboard = Array.new
            # total      
            leads = Lead.loadObject(:all)
          
            leadsHM = Hash.new
            leadsHM['LEADS'] = "Total"
            leadsHM['COUNT'] = leads.size.to_s
            leadsDashboard.push(leadsHM)

            # draft
            leads = Lead.loadObject(:all,
              	:conditions => {
          		    { 
          			   :name => 'statusCd',
          			   :op => 'LIKE'
          			} => MobiSys::LeadBO::PENDING
          		}
      		)
            leadsHM = Hash.new
            leadsHM['LEADS'] = "Draft"
            leadsHM['COUNT'] = leads.size.to_s
            leadsDashboard.push(leadsHM)
          
            # Awaiting activities
            leads = Lead.loadObject(:all,
              	:conditions => {
              		{ 
              			:name => 'statusCd',
              			:op => 'LIKE'
          			} => MobiSys::LeadBO::READYFORSYNC
          		}
      		)
          
            leadsHM = Hash.new
            leadsHM['LEADS'] = "Ready for Sync"
            leadsHM['COUNT'] = leads.size.to_s
            leadsDashboard.push(leadsHM)

            # Activities
            leads = LeadActivity.loadObject(  :all )

            leadsHM = Hash.new
            leadsHM['LEADS'] = "Activities"
            leadsHM['COUNT'] = leads.size.to_s
            leadsDashboard.push(leadsHM)

            return leadsDashboard
        end
        ###################################################################################################
    

    	def self.validate(lead, errors)
      		if lead.firstname.to_s == ""
        		MobiSys::CommonUtil.addErrors(errors, "firstname", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("firstName")])
      		elsif lead.firstname.size > 60
        		MobiSys::CommonUtil.addErrors(errors, "firstname", "ERR_MAXLEN", [MobiSys::BrowserHelper.getLabel("firstName"), "60"])
      		end

      		if lead.lastname.to_s == ""
      			MobiSys::CommonUtil.addErrors(errors, "lastname", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("lastName")])
      		elsif lead.lastname.size > 60
      			MobiSys::CommonUtil.addErrors(errors, "lastname", "ERR_MAXLEN", [MobiSys::BrowserHelper.getLabel("lastName"), "60"])
      		end

      		if (lead.emailAddress.to_s == "") && (lead.mobileNumber.to_s == "") && (lead.residenceNumber.to_s == "") && (lead.officeNumber.to_s == "")
      			MobiSys::CommonUtil.addErrors(errors, "someContactMandatory", "ERR_MANDATORYCONTACT", [MobiSys::BrowserHelper.getLabel("contactTypeCd")])
      		end

      		if lead.emailAddress.to_s != "" && (/[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/.match(lead.emailAddress)) == nil
      			MobiSys::CommonUtil.addErrors(errors, "emailAddress", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel("emailID")])
      		end

      		if lead.mobileNum.to_s != "" && (/[0]{1}+[0-9\ ]/.match(lead.mobileNum)) == nil
      			MobiSys::CommonUtil.addErrors(errors, "mobileNum", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel("mobileNum")])
      		end

      		if lead.title == "MR" && lead.genderCd != "MALE"
      			MobiSys::CommonUtil.addErrors(errors, "genderCd", "ERR_INVALIDGENDER", [MobiSys::BrowserHelper.getLabel(lead.title), MobiSys::BrowserHelper.getLabel("MALE")])
      		elsif (lead.title == "MRS" || lead.title == "MS")  && (lead.genderCd != "FEMALE")
      			MobiSys::CommonUtil.addErrors(errors, "genderCd", "ERR_INVALIDGENDER", [MobiSys::BrowserHelper.getLabel(lead.title), MobiSys::BrowserHelper.getLabel("FEMALE")])
      		end

      		if lead.dob.to_s != "" && Time.parse(lead.dob.to_s) >= Time.now 
      			MobiSys::CommonUtil.addErrors(errors, "dob", "ERR_DATE", [MobiSys::BrowserHelper.getLabel('birthDt'), Time.now.strftime("%d-%m-%Y")])
      		end

      		if lead.age.to_s != "" && lead.age.to_i < 18
      			MobiSys::CommonUtil.addErrors(errors, "dob", "Age cannot be less than 18 years old", []) 
      		end

          lead.LeadActivityList.each do |leadActivity|
              if leadActivity.type.to_s == ""
                  MobiSys::CommonUtil.addErrors(errors, "type", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel("activityType")])
              end
          end
      end    
    	###################################################################################################

      def self.validate_Jazz(lead, errors)
          $globalContextObjectMap = {}
          $currentValidationMetadata = nil
          $currentTabId = nil
          $taskExceptionHash = []

          if $rhoconfig[:contextBasedMetadata]
            classToFind = "#{lead.class.name}DO"
            contextMasterGeneratedArray = []
            if $contextMasterCache.has_key?(classToFind.to_sym)
              contextMasterList = $contextMasterCache[classToFind.to_sym]
              contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,lead)
            end
            MobiSys::Validation.processValidContexts(lead.hashForSync, contextMasterGeneratedArray, "GenericSet")
            validationContexts = $globalContextObjectMap[lead.guid]
          else
            GenericSet.setObject(lead)
            validationContexts = GenericSet::ValidationContexts
          end
          MobiSys::Validation.validationLoop(lead.hashForSync, validationContexts, errors, "GenericSet")

          #function to run policy model based validations
          validateCompanyFacet(lead,errors)
          db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
          db.start_transaction
          $taskExceptionHash.each do |taskException|
              taskException.persistAll
          end
          db.commit
          $taskExceptionHash = nil
      end
    #########################################################################################################

      def self.checkClosureDate(lead,errors)
        isValid = true
         lead.LeadActivityList.each do |leadActivity|
          leadActivity.activityDt.to_s != "" && leadActivity.closureDate.to_s != ""
          from_date = (leadActivity.activityDt.to_s)
          to_date =  (leadActivity.closureDate.to_s)
            if to_date < from_date
              MobiSys::CommonUtil.registerException(lead.guid,"#{leadActivity.guid}-closureDate","ERR_COMPAREVAL","ERR_COMPAREVAL",nil,[MobiSys::BrowserHelper.getLabel("closureDate"),MobiSys::BrowserHelper.getLabel("activityDt")])
            end
            isValid = false
         end
         return isValid
      end


      def self.validateCompanyFacet(lead,errors)
        #run additional model set for validation  and value set.
        policy = Policy.new
        policy.guid = lead.guid
        leadParty = lead.getLeadParty
        origRoleCd = leadParty.roleCd
        party = Party.new
        party = leadParty
        party.roleCd = "PROPOSER"
        policy.addParty(party)
        # create policy party role record
        policy.createPolicyPartyRole(party, party.roleCd)

        policyProduct = policy.getBaseProduct
        if $rhoconfig[:addtnlLEADCompanyModelSet] != nil && $rhoconfig[:addtnlLEADCompanyModelSet].actionValue.to_s != ""
            policyModelSet = PolicyUtil::PolicyModelSet.new
            party = policy.getParty('PROPOSER')
            policyModelSet.execute(policy, policyProduct, party, $rhoconfig[:addtnlLEADCompanyModelSet].actionValue)
        end
        # convert policy to lead party back to after policy model evaluation
        proposerParty = policy.getPartyByRole("PROPOSER")
        leadParty = proposerParty
        leadParty.roleCd = origRoleCd
      end
	end
end

begin
	require 'Lead/lead_b_o_company'
rescue LoadError => e
	puts 'lead_b_o_company not included'
end
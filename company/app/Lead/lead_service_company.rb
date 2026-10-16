require 'CommonModules/entityschema'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Lead/lead_b_o'
require 'Product/product_b_o'
module MobiSys
	class LeadService
		extend MobiSys::BrowserHelper

		def self.saveValidate(lead,saveLead = true)
			lead.statusCd = "PENDING"
	        #preSave(@params,lead) #Company Layer Implementation
	        lead.persistAll
	        #postSave(@params,lead) #Company Layer Implementation
	        newlead = Lead.loadObject(:first,:conditions=>{:object=> lead.object.to_s})
	        errors = Hash.new
	        MobiSys::CommonUtil.clearTaskExceptionList(newlead.guid)
	        MobiSys::LeadBO.validate_Jazz(newlead, errors)
	        errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(newlead.guid,newlead.visitedTabs)
	        if errors.empty? && incompleteTabs.empty? && saveLead
	           # updateCalendar(newlead)
	           # updateContacts(newlead)
	           newlead.statusCd = "COMPLETED"
	           newlead.persistAll
	       end
		end

		def self.newFNA(lead)
	        fnaRequest = FNARequest.new
	        fnaProposer = FNAParty.new(:partyRoleCd => "PROPOSER")
	        fnaProposer.setRoleCd("PROPOSER")
	        fnaRequest.addFNAParty(fnaProposer)
	        agentRegdetails = AgentReg.getCurrentAgentReg
	        if agentRegdetails != nil
	            fnaRequest.agentId = agentRegdetails.agentId
	        end
	        fnaRequest.leadId = lead.leadId
	        fnaRequest.requestDt = Time.now
	        fnaRequest.statusCd = "PENDING"
	        fnaRequest.addtnField1Str = "PENDING"
	        @@variablesave = nil
	        fnaRequest.fnaNum = nil
	        leadParty = lead.getLeadParty
	        if leadParty.to_s != ""
	            fnaProposer.firstName1 = leadParty.firstName1
	            fnaProposer.lastName1 = leadParty.lastName1
	            fnaProposer.middleName1 = leadParty.middleName1
	            fnaProposer.age = leadParty.age
	            fnaProposer.birthDt = leadParty.birthDt
	            # fnaProposer.contactNum = leadParty.contactNum
	            # fnaProposer.emailAddress = leadParty.emailAddress
	            fnaProposer.educationLevelCd = leadParty.extensionName1
	            fnaProposer.maritalStatusCd = leadParty.maritalStatusCd # populate civil status from lead - for C360
	        end
		    fnaRequest.fnaNum = SequenceNoGenerator.getNextNumber('FNA') if fnaRequest.fnaNum.to_s == ""  
		    # fnaRequest.isRPQApplicable = true
		    questionList = fnaProposer.fnaQuestionFromLookup
			if questionList && questionList.size.to_i > 0
				questionList.each do |fnaQue|
					qnaQuestionResponseObj = fnaProposer.getQuestionResponse(fnaQue.cd)
					fnaProposer.addFNAParty(qnaQuestionResponseObj)
				end
			end
		    fnaRequest.persistAll
            MobiSys::CommonUtil.addUserActivity('CREATED_FNA_FROM_LEAD',"fnaNum => #{fnaRequest.fnaNum},fnaGuid => #{fnaRequest.guid},leadGuid => #{lead.guid},leadId => #{lead.leadId}", 'LEAD', fnaRequest.fnaNum)

	        return fnaRequest
        end

        def self.newQuotation(lead)
            $rhoconfig[:moduleForProductValidations] = "Quotation"
            quotation = Quotation.new
            quotation.leadId = lead.leadId
            quotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
            quotation.step = 0
            quotation.quoteStatusCd = "PENDING"
            quotation.insuranceTypeCd = lead.insuranceTypeCd

            agentRegdetails = AgentReg.getCurrentAgentReg
            quotation = MobiSys::LeadService.setAgentDetails(quotation, agentRegdetails)
            quotation.quotationDt = getScreenDate(Time.now.to_s)
            #to set agent location in branch name field(quotAddtnlField2)
            quotation.quotAddtnlField2 = agentRegdetails.location if agentRegdetails
            quotation.quotAddtnlField11 = agentRegdetails.licenseType if agentRegdetails
            quotation.isAgeEditableFl = nil
            isAgeEditableFl = MobiSys::BrowserHelper.getFacetMappedValue('AGECAPTUREREQUIRED',$currentProduct)
            quotation.isAgeEditableFl = isAgeEditableFl if isAgeEditableFl.to_s != ''
            #Copy Party Details to Quotation Party
            quotationParty = QuotationParty.new(:roleCd => "PROPOSER")
            quotation.addQuotationParty(quotationParty)

            leadParty = lead.PartyList[0]
            if leadParty
            	quotationParty.partyTypeCd = leadParty.partyTypeCd
	            quotationParty.title = leadParty.titleCd
	            quotationParty.firstname = leadParty.firstName1
	            quotationParty.middlename = leadParty.middleName1
	            quotationParty.lastname = leadParty.lastName1
	            quotationParty.corporateName = leadParty.corporateName1
	            quotationParty.corporateName2 = leadParty.corporateName2
	            quotationParty.genderCd = leadParty.genderCd
	            quotationParty.age = leadParty.age
	            quotationParty.dob = leadParty.birthDt
	            quotationParty.industryCd = leadParty.industryCd
	            quotationParty.natureOfDuty = leadParty.natureOfDuty
	            quotationParty.occupationCd = leadParty.occupationCd
	            quotationParty.nationality = leadParty.citizenshipCd
	            quotationParty.smoker = leadParty.smoker
	            quotationParty.nsap = leadParty.nsap
	            quotationParty.coverageCountryCd = leadParty.coverageCountryCd
	            quotationParty.coverageCityCd = leadParty.coverageCityCd
	            quotationParty.contactNum = (leadParty.getPartyContact("MOBILE") ? leadParty.getPartyContact("MOBILE").contactNum : nil)
	            quotationParty.emailAddress = (leadParty.getPartyEmail("PERSONAL") ? leadParty.getPartyEmail("PERSONAL").emailAddress : nil)
	            residentialAddress = leadParty.getPartyAddress("RESIDENTIAL")

	            #Copy Party Address fields to Quotation Party
	            if residentialAddress
	                quotationParty.addressLine1Lang1 = residentialAddress.addressLine1Lang1
	                quotationParty.addressLine2Lang1 = residentialAddress.addressLine2Lang1
	                quotationParty.addressLine3Lang1 = residentialAddress.addressLine3Lang1
	                quotationParty.addressLine4 = residentialAddress.addressLine4Lang1
	                quotationParty.countryCd = residentialAddress.countryCd
	                quotationParty.stateCd = residentialAddress.stateCd
	                quotationParty.cityCd = residentialAddress.cityCd
	                quotationParty.pinCode = residentialAddress.pinCode
	            end

	            if leadParty.PartyIdentityList.size > 0
	            	partyIdentity = leadParty.PartyIdentityList[0]
	            	quotationParty.idType = partyIdentity.identityTypeCd
	            	quotationParty.idNumber = partyIdentity.identityNum
	            end
	        end
	        if leadParty.partyTypeCd.to_s == 'ORGANIZATION'
	             quotation.quotAddtnlField12 = 'INDIVIDUAL' 
	        end     

	        propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
            if quotation.proposalVersion.to_s == ''
            	quotation.proposalVersion = propVersion.value.to_s if propVersion
            end
            
            insuredParty = QuotationParty.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
            quotation.addQuotationParty(insuredParty)
            quotation.status = ""
            postGetQuotationFromLead(quotation, lead)
            quotation.persistAll
            MobiSys::CommonUtil.addUserActivity('CREATED_QUOTATION_FROM_LEAD',"quotationRefNum => #{quotation.quotationRefNum},quotationGuid => #{quotation.guid},leadGuid => #{lead.guid},leadId => #{quotation.leadId}", 'LEAD', quotation.quotationRefNum)

            return quotation
        end

        def self.findAllEntities(lead,modify=false)
        	leadParty = lead.getLeadParty
        	fnaRecordForUpdate = fnaRecordForUpdateObj = []
			quotationRecordForUpdate = quotationRecordForUpdateObj = []
			proposalRecordForUpdate = proposalRecordForUpdateObj = []

			if lead.leadId && leadParty && leadParty.partyTypeCd.to_s != ""
				partyType = leadParty.partyTypeCd

			    fnaStatusToInclude       = ["PENDING", "COMPLETED"]
			    quotationStatusToInclude = ["PENDING", "COMPLETED", "ACCEPTED", "SYNCDONE"]
			    policyStatusToInclude    = ["PENDING", "COMPLETED", "LOCKED"]

			    if partyType.casecmp('INDIVIDUAL').zero?
			    	fnaEntities = FNARequest.find(
                          :all,
                          :conditions => {
                            { :name => 'leadId' } => lead.leadId.to_s,
                            { :name => 'statusCd', :op => 'IN'} => fnaStatusToInclude
                          },
                          :op => 'AND',
                          :select => ['fnaNum', 'object']
                        )
			    	if !fnaEntities.empty?
				    	fnaRecordForUpdate = fnaEntities.map do |record|
						  record.instance_variable_get(:@vars)[:fnaNum]
						end
						fnaRecordForUpdateObj = fnaEntities.map do |record|
						  record.instance_variable_get(:@vars)[:object]
						end
					end
			    end
			    
			    if !fnaRecordForUpdate.empty?
			    	fnaRecordForUpdate.each do |fnaNum|
					    quotationEntities = Quotation.find(
		                          :all,
		                          :conditions => {
		                            { :name => 'fnaId' } => fnaNum.to_s,
		                            { :name => 'quoteStatusCd', :op => 'IN'} => quotationStatusToInclude
		                          },
		                          :op => 'AND',
		                          :select => ['quotationRefNum', 'object']
		                        )
					    linkedQuotation = []
					    if !quotationEntities.empty?
					    	linkedQuotation = quotationEntities.map do |record|
							  record.instance_variable_get(:@vars)[:quotationRefNum]
							end
						end
						if !linkedQuotation.empty?
							linkedQuotation.each do |refNum|
						    	policyEntities = Policy.find(
				                      :all,
				                      :conditions => {
				                        { :name => 'quotationRefNum' } => refNum.to_s,
				                        { :name => 'statusCd', :op => 'IN'} => policyStatusToInclude
				                      },
				                      :op => 'AND',
				                      :select => ['proposalNum','object','statusCd']
				                    )
						    	if !policyEntities.empty?
						    		if !quotationEntities.empty?
								    	quotationRecordForUpdate.push("#{refNum}")
										quotationRecordForUpdateObj = quotationEntities.map do |record|
										  record.instance_variable_get(:@vars)[:object]
										end
									end
							    	proposalRecordForUpdate = policyEntities.map do |record|
									  record.instance_variable_get(:@vars)[:proposalNum]
									end
									proposalRecordForUpdateObj = policyEntities.map do |record|
									  record.instance_variable_get(:@vars)[:object]
									end
								else
									policy = Policy.find(
				                      :all,
				                      :conditions => {
				                        { :name => 'quotationRefNum' } => refNum.to_s
				                      },
				                      :select => ['proposalNum','object','statusCd']
				                    )
									if !quotationEntities.empty? && policy.empty?
								    	quotationRecordForUpdate.push("#{refNum}") 
										quotationRecordForUpdateObj = quotationEntities.map do |record|
										  record.instance_variable_get(:@vars)[:object]
										end
									end
								end
							end
						end
					end
				else
					quotationEntities = Quotation.find(
		                          :all,
		                          :conditions => {
		                            { :name => 'leadId' } => lead.leadId.to_s,
		                            { :name => 'quoteStatusCd', :op => 'IN'} => quotationStatusToInclude
		                          },
		                          :op => 'AND',
		                          :select => ['quotationRefNum', 'object']
		                        )
					linkedQuotation = []
				    if !quotationEntities.empty?
				    	linkedQuotation = quotationEntities.map do |record|
						  record.instance_variable_get(:@vars)[:quotationRefNum]
						end
					end
					if !linkedQuotation.empty?
						linkedQuotation.each do |refNum|
					    	policyEntities = Policy.find(
			                      :all,
			                      :conditions => {
			                        { :name => 'quotationRefNum' } => refNum.to_s,
			                        { :name => 'statusCd', :op => 'IN'} => policyStatusToInclude
			                      },
			                      :op => 'AND',
			                      :select => ['proposalNum','object','statusCd']
			                    )
					    	if !policyEntities.empty?
					    		if !quotationEntities.empty?
							    	quotationRecordForUpdate.push("#{refNum}")
									quotationRecordForUpdateObj = quotationEntities.map do |record|
									  record.instance_variable_get(:@vars)[:object]
									end
								end
						    	proposalRecordForUpdate = policyEntities.map do |record|
								  record.instance_variable_get(:@vars)[:proposalNum]
								end
								proposalRecordForUpdateObj = policyEntities.map do |record|
								  record.instance_variable_get(:@vars)[:object]
								end
							else
								policy = Policy.find(
			                      :all,
			                      :conditions => {
			                        { :name => 'quotationRefNum' } => refNum.to_s
			                      },
			                      :select => ['proposalNum','object','statusCd']
			                    )
								if !quotationEntities.empty? && policy.empty?
							    	quotationRecordForUpdate.push("#{refNum}")
									quotationRecordForUpdateObj = quotationEntities.map do |record|
									  record.instance_variable_get(:@vars)[:object]
									end
								end
							end
						end
					end
				end
		    	
		    	if modify
			    	if partyType.casecmp('INDIVIDUAL').zero?
			    		updatePartyData("FNA", fnaRecordForUpdate, "PROPOSER",
	                      leadParty.firstName1, leadParty.middleName1,
	                      leadParty.lastName1, leadParty.extensionName1) if !fnaRecordForUpdate.empty?
			    		updatePartyData("QUOTATION", quotationRecordForUpdate, "PROPOSER",
	                      leadParty.firstName1, leadParty.middleName1,
	                      leadParty.lastName1, leadParty.extensionName1) if !quotationRecordForUpdate.empty?
			    		updatePartyData("POLICY", proposalRecordForUpdate, "PROPOSER",
	                      leadParty.firstName1, leadParty.middleName1,
	                      leadParty.lastName1, leadParty.extensionName1) if !proposalRecordForUpdate.empty?
			    	else
			    		updatePartyOrganizationData("QUOTATION", quotationRecordForUpdate, "PROPOSER",
	                      leadParty.corporateName1) if !quotationRecordForUpdate.empty?
			    		updatePartyOrganizationData("POLICY", proposalRecordForUpdate, "PROPOSER",
	                      leadParty.corporateName1) if !proposalRecordForUpdate.empty?
			    	end
			    end
			end
			return fnaRecordForUpdateObj,quotationRecordForUpdateObj,proposalRecordForUpdateObj
        end

        def self.updatePartyData(updateType, referenceNums, roleCd, firstName, middleName, lastName, extraField)
		  if referenceNums.nil? || referenceNums.empty?
		    puts "No reference numbers provided."
		    return
		  end

		  query = nil
		  params = []
		  logMessage = ""
		  placeholders = referenceNums.map { |s| "\"#{s}\"" }.join(", ")

		  case updateType
		  when "FNA"
		  	begin
			  	db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
	            db.start_transaction
				sql = "UPDATE FNAParty SET firstName1 = ?, middleName1 = ?, lastName1 = ?, educationLevelCd = ? " \
				        "WHERE partyRoleCd = ? AND parentKey IN (SELECT object FROM FNARequest WHERE fnaNum IN (#{placeholders}))"
				params = [firstName, middleName, lastName, extraField, roleCd]
				db.execute_sql(sql, params)
			    db.commit
			rescue Exception => e
			  db.rollback
			  puts "Transaction failed: #{e.message}"
			end
		  when "QUOTATION"
		  	begin
			    db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
	            db.start_transaction
				sql = "UPDATE QuotationParty SET firstName = ?, middleName = ?, lastName = ?, extensionName = ? " \
				        "WHERE roleCd = ? AND parentKey IN (SELECT object FROM Quotation WHERE quotationRefNum IN (#{placeholders}))"
				params = [firstName, middleName, lastName, extraField, roleCd]
				db.execute_sql(sql, params)
				roleCd = "PRIMARY"
				quotPartyAddtnField4 = "YES"
				sql2 = "UPDATE QuotationParty SET firstName = ?, middleName = ?, lastName = ?, extensionName = ? " \
				        "WHERE roleCd = ? AND quotPartyAddtnField4 = ? AND parentKey IN (SELECT object FROM Quotation WHERE quotationRefNum IN (#{placeholders}))"
				params = [firstName, middleName, lastName, extraField, roleCd, quotPartyAddtnField4]
				db.execute_sql(sql2, params)
			    db.commit
			rescue Exception => e
			  db.rollback
			  puts "Transaction failed: #{e.message}"
			end
		  when "POLICY"
		  	begin
			    db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
	            db.start_transaction
				sql = "UPDATE Party SET firstName1 = ?, middleName1 = ?, lastName1 = ?, extensionName1 = ? " \
				        "WHERE roleCd = ? AND parentKey IN (SELECT object FROM Policy WHERE proposalNum IN (#{placeholders}))"
				params = [firstName, middleName, lastName, extraField, roleCd]
				db.execute_sql(sql, params)
				roleCd = "PRIMARY"
				quoteProposerSameAsInsured = "YES"
				sql2 = "UPDATE Party SET firstName1 = ?, middleName1 = ?, lastName1 = ?, extensionName1 = ? " \
				        "WHERE roleCd = ? AND parentKey IN (SELECT object FROM Policy WHERE  quoteProposerSameAsInsured = ? AND proposalNum IN (#{placeholders}))"
				params = [firstName, middleName, lastName, extraField, roleCd, quoteProposerSameAsInsured]
				db.execute_sql(sql2, params)
			    db.commit
			rescue Exception => e
			  db.rollback
			  puts "Transaction failed: #{e.message}"
			end
		  end
		end

		def self.updatePartyOrganizationData(updateType, referenceNums, roleCd, corporateName1)
		  if referenceNums.nil? || referenceNums.empty?
		    puts "No reference numbers provided."
		    return
		  end

		  query = nil
		  params = []
		  logMessage = ""
		  placeholders = referenceNums.map { |s| "\"#{s}\"" }.join(", ")

		  case updateType
		  when "QUOTATION"
		  	begin
			    db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
	            db.start_transaction
				sql = "UPDATE QuotationParty SET corporateName = ?" \
				        "WHERE roleCd = ? AND parentKey IN (SELECT object FROM Quotation WHERE quotationRefNum IN (#{placeholders}))"
				params = [corporateName1, roleCd]
				db.execute_sql(sql, params)
			    db.commit
			rescue Exception => e
			  db.rollback
			  puts "Transaction failed: #{e.message}"
			end
		  when "POLICY"
		  	begin
			    db = Rho::Database.new(Rho::Application.databaseFilePath("local"),"local")
	            db.start_transaction
				sql = "UPDATE Party SET corporateName1 = ? " \
				        "WHERE roleCd = ? AND parentKey IN (SELECT object FROM Policy WHERE proposalNum IN (#{placeholders}))"
				params = [corporateName1, roleCd]
				db.execute_sql(sql, params)
			    db.commit
			rescue Exception => e
			  db.rollback
			  puts "Transaction failed: #{e.message}"
			end
		  end
		end
	end
end
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
	           updateCalendar(newlead)
	           updateContacts(newlead)
	           newlead.statusCd = "COMPLETED"
	           newlead.persistAll
	       end
		end

		#Method to add lead activities to mobile device calendar
		def self.updateCalendar(lead)
			if System::get_property('has_calendar')
				lead.LeadActivityList.each do |leadActivity|
					event = Hash.new
					event["title"] = leadActivity.type
					event["notes"] = leadActivity.description
					event["reminder"] = 5
					event["start_date"] = leadActivity.activityDt
					leadActivity.closureDate = leadActivity.activityDt if leadActivity.closureDate.to_s == ""
					event["end_date"] = leadActivity.closureDate
					if System::get_property('platform') == 'APPLE' || System::get_property('platform') == 'ANDROID'
						# begin 
						# 	if leadActivity.calendarId.to_s == ""
						# 		calendar = MobiSys::Calendar.create(event)
						# 		leadActivity.calendarId = calendar["id"]
						# 	else
						# 		calendar = MobiSys::Calendar.update(leadActivity.calendarId, event)
						# 	end
						# rescue MobiSys::CalendarAccessError => error 
						# 	puts "Calendar Access Not Available"
						# end
					end
				end
				lead.persistAll
			end
		end

		#Method to add lead to mobile device address book
		def self.updateContacts(lead)
			contact = Hash.new
			contact["first_name"] = lead.firstname
			contact["last_name"] = lead.lastname
			contact["mobile_number"] = lead.mobileNumber
			contact["business_number"] = lead.officeNumber
			contact["email_address"] = lead.emailAddress
			unless System.get_property('is_emulator')
				if System::get_property('platform') == 'APPLE' || System::get_property('platform') == 'ANDROID'
					begin
						if lead.contactId.to_s == ""
							contactEntry = MobiSys::Contacts.create(contact)
							lead.contactId = contactEntry["id"]
							lead.persistAll
						else
							contactEntry = MobiSys::Contacts.update(lead.contactId, contact)
						end
					rescue MobiSys::ContactsAccessError => error
						puts "Address Book Access Not Available"
					end
				end
			end  
		end

	    def self.setAgentDetails(quotation, agentRegdetails)
	        if agentRegdetails != nil
	            quotation.agentId = agentRegdetails.agentId
	            quotation.channel = agentRegdetails.channel
	            quotation.subChannel = agentRegdetails.subChannel
	            quotation.parentAgency = agentRegdetails.parentAgency
	        end

	        return quotation
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
            insuredParty = QuotationParty.new(:roleCd => "PRIMARY", :partyTypeCd => "INDIVIDUAL")
            quotation.addQuotationParty(insuredParty)
            quotation.status = ""
            postGetQuotationFromLead(quotation, lead)
            quotation.persistAll
            return quotation
        end

        def self.postGetQuotationFromLead(quotation, lead)
        	return quotation
        end

        def self.processExtractedImageData(leadParty,extractedData)
        	return if extractedData.to_s == ""

        	partyIdentity = partyAddress = partyContact = partyEmail = nil
        	identityType = extractedData[:identityTypeCd]
		
			partyIdentity = leadParty.getPartyIdentity(identityType) if identityType.to_s != ""
			partyIdentity = leadParty.PartyIdentityList[0] if(partyIdentity == nil and leadParty.PartyIdentityList.size > 0)
				
			addressTypeCd = extractedData[:addressTypeCd]
			partyAddress = leadParty.getPartyAddress(addressTypeCd) if addressTypeCd.to_s != ""
			partyAddress = leadParty.PartyAddressList[0] if(partyAddress == nil and leadParty.PartyAddressList.size > 0)
		
			contactTypeCd = extractedData[:contactTypeCd]
			partyContact = leadParty.getPartyContact(contactTypeCd) if contactTypeCd.to_s != ""
			partyContact = leadParty.PartyContactList[0] if(partyContact == nil and leadParty.PartyContactList.size > 0)
		
			emailTypeCd = extractedData[:emailTypeCd]
			partyEmail = leadParty.getPartyEmail

		    extractedData.each do |attributeName, attributeVal|
		    	next unless attributeVal.to_s != ""

				if (attributeName.to_s.include?("PartyDO") || attributeName.to_s.include?("PartyIdentityDO"))
					metadataCd = attributeName.to_s.split('.')
					className = metadataCd[0]
					fieldName = metadataCd[1]
					attrFieldName = "#{fieldName}="
					
					begin
						if className.to_s == "PartyDO"
							leadParty.send(attrFieldName,attributeVal.to_s)
							if fieldName.to_s == "birthDt"
								birthDt = getScreenDate(attributeVal.to_s)
					            commencementDt = getScreenDate(Time.new.to_s)
					            age = 0
					            if birthDt != nil and commencementDt != ""
					            	ageCalculationBasis = MobiSys::ProductUtil::LASTBIRTHDAY
					                companyFacetAgeCalculationBasis = CompanyFacet.find(
					                    :first,
					                    :conditions => {
					                        { :name => 'facetCd' } => 'AGECALCULATIONBASIS'
					                    }
					                )
					                if companyFacetAgeCalculationBasis && companyFacetAgeCalculationBasis.actionValue.to_s != ""
					                    ageCalculationBasis = companyFacetAgeCalculationBasis.actionValue.to_s
					                end
					                age = MobiSys::ProductUtil.getAge(birthDt, ageCalculationBasis, commencementDt)
					                age = age.split("|")[0]
					            end
					            leadParty.age = age.to_i
							end
						elsif (className.to_s == "PartyIdentityDO" and partyIdentity != nil)
	        				if ((fieldName.to_s == "identityTypeCd" and partyIdentity.identityTypeCd.to_s == "") || fieldName.to_s != "identityTypeCd")
	        					partyIdentity.send(attrFieldName,attributeVal.to_s)
	        				end
	        				partyIdentity.status = ""
						elsif (className.to_s == "PartyAddressDO" and partyAddress != nil)
	        				if ((fieldName.to_s == "addressTypeCd" and partyAddress.addressTypeCd.to_s == "") || fieldName.to_s != "addressTypeCd")
	        					partyAddress.send(attrFieldName,attributeVal.to_s)
	        				end
	        				partyAddress.status = ""
						elsif (className.to_s == "PartyContactDO" and partyContact != nil)
							if ((fieldName.to_s == "contactTypeCd" and partyContact.contactTypeCd.to_s == "") || fieldName.to_s != "contactTypeCd")
	        					partyContact.send(attrFieldName,attributeVal.to_s)
	        				end
	        				partyContact.status = ""
						elsif (className.to_s == "PartyEmailDO" and partyEmail != nil)
							if ((fieldName.to_s == "emailTypeCd" and partyEmail.emailTypeCd.to_s == "") || fieldName.to_s != "emailTypeCd")
	        					partyEmail.send(attrFieldName,attributeVal.to_s)
	        				end
	        				partyEmail.status = ""
						end
					rescue StandardError => boom
						#do nothing.
					end

				end
		    end
        end
	end
end

begin 
    require 'Lead/lead_service_company'
rescue LoadError => e
    puts 'lead_service_company not included'
end
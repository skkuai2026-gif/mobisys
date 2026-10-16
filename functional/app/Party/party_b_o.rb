#encoding: UTF-8
require 'Product/product_b_o'
require 'CommonModules/commonutil'
require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

module MobiSys
    class PartyBO
        include Singleton
        include MobiSys::CommonUtil
        include BrowserHelper
        extend MobiSys::BrowserHelper

  
	    #Validates the gender title mapping based on that setup in master configuration
	    def self.checkGenderTitleMapping(party, errors)
			isValid = true
			unless $rhoconfig[:TABFEATUREREQD]
				if party.genderCd.to_s != "" && party.titleCd.to_s != ""
					if party.titleCd == "MR" && party.genderCd != "MALE" 
						MobiSys::CommonUtil.addErrors(errors,"titleCd", "ERR_INVALIDTITLEGENDER", ["MR","Male"])      
						isValid = false
					end
					if party.titleCd == "MRS"  && party.genderCd != "FEMALE" 
						MobiSys::CommonUtil.addErrors(errors,"titleCd", "ERR_INVALIDTITLEGENDER", ["MRS","Female"])
						isValid = false
					end
					if party.titleCd == "MS"  && party.genderCd != "FEMALE" 
						MobiSys::CommonUtil.addErrors(errors,"titleCd", "ERR_INVALIDTITLEGENDER", ["MS","Female"])
						isValid = false
					end
				end
			else
				policyGuid = party.parentKey.gsub(".","_")
				fieldTargetValueMap = FieldTargetValueMap.loadObject(:all, :conditions=>{{:name=>'targetField'}=> "genderCd"})
				if party.genderCd.to_s != "" && party.titleCd.to_s != ""
					fieldTargetValueMap.each do |fields|
						if (party.titleCd == fields.drivingValue && party.genderCd != fields.targetValue)
							MobiSys::CommonUtil.registerException(policyGuid,"#{party.guid}-genderCd","ERR_GENDERTITLE","ERR_GENDERTITLE",nil)
							isValid = false
						end
					end
				end
			end
			return isValid 
	    end
	    ##################################################################################################
  

	    #Validates that any of the party's birthdate is not beyond system date
	    def self.checkBirthDate(party, errors)
			isValid = true

	    	currentDt = Time.new
    		if party.birthDt.to_s != ""
    			birthDt = Time.parse(party.birthDt.to_s)
	    		if birthDt > currentDt
    				MobiSys::CommonUtil.addErrors(errors, "birthDt", "ERR_DOB", [MobiSys::BrowserHelper.getLabel(party.roleCd)])
					isValid = false
    			end
    		end

			return isValid 
	    end
	    ##################################################################################################
  

	    #Validates that Identity details are not expired
	    def self.checkIdentityDates(partyIdentity, errors)
	    	isValid = true
	    	party = nil
	    	currentDt =  Time.parse(Time.new.strftime("%F 00:00:00 %z"))
	    	if partyIdentity.class.name == "Party"
	    		party = partyIdentity
	    		policyGuid = party.parentKey.gsub(".","_")
	    		partyIdentityList = party.getPartyIdentityList
	    		partyIdentityList.each do |partyIdentity|
	    			issueDt = Time.parse(partyIdentity.issueDt.to_s) if partyIdentity.issueDt.to_s != ""
		    		expiryDt = Time.parse(partyIdentity.expiryDt.to_s) if partyIdentity.expiryDt.to_s != ""
	    			if partyIdentity.issueDt.to_s != ""	
		    			if issueDt > currentDt
							MobiSys::CommonUtil.registerException(policyGuid, "#{partyIdentity.guid}-issueDt", "ERR_DATEAFTER", "ERR_DATEAFTER", nil,[MobiSys::BrowserHelper.getLabel("issueDt"),getScreenDate(partyIdentity.issueDt.to_s), partyIdentity.identityTypeCd.to_s, "NO. #{partyIdentity.identityNum.to_s}","Todays's Date",getScreenDate(currentDt.to_s),party.getEntityDesc])
						isValid = false
	    				end
	    			end

	    			if partyIdentity.expiryDt.to_s != ""
		    			if expiryDt < currentDt
							MobiSys::CommonUtil.registerException(policyGuid, "#{partyIdentity.guid}-expiryDt", "ERR_DATEBEFORE", "ERR_DATEBEFORE", nil,[MobiSys::BrowserHelper.getLabel("expiryDt"),getScreenDate(partyIdentity.expiryDt.to_s), partyIdentity.identityTypeCd.to_s, "NO. #{partyIdentity.identityNum.to_s}","Today's Date",getScreenDate(currentDt.to_s),party.getEntityDesc])
						isValid = false
	    				end
	    			end

	    			if partyIdentity.expiryDt.to_s != "" && partyIdentity.issueDt.to_s != ""
	    				if issueDt == expiryDt
							MobiSys::CommonUtil.registerException(policyGuid, "#{partyIdentity.guid}-expiryDt", "ERR_DATESAME", "ERR_DATESAME", nil,[MobiSys::BrowserHelper.getLabel("expiryDt"),getScreenDate(partyIdentity.expiryDt.to_s), partyIdentity.identityTypeCd.to_s, "NO. #{partyIdentity.identityNum.to_s}",MobiSys::BrowserHelper.getLabel("issueDt"),getScreenDate(partyIdentity.issueDt.to_s),party.getEntityDesc])
						isValid = false
	    				end
	    			end
	    		end
	    		return isValid 
			else
				party = Party.loadObject(:first, :conditions=>{{:name=>'object'}=>partyIdentity.parentKey},:loadChild => 'false')
			
	    		issueDt = Time.parse(partyIdentity.issueDt.to_s)
	    		
		    	expiryDt = Time.parse(partyIdentity.expiryDt.to_s)
		    	
		     	if partyIdentity.issueDt.to_s != ""	
		    		if issueDt > currentDt
			      		MobiSys::CommonUtil.addErrors(errors, "issueDt", "ERR_IDENTITY", [MobiSys::BrowserHelper.getLabel(party.roleCd)])
						isValid = false
	    			end
	    		end

	    		if partyIdentity.expiryDt.to_s != ""
		    		if expiryDt < currentDt
	    				MobiSys::CommonUtil.addErrors(errors, "expiryDt", "ERR_IDENTITY", [MobiSys::BrowserHelper.getLabel(party.roleCd)])
						isValid = false
	    			end
	    		end
	  
				return isValid 
			end
	    end
	    ##################################################################################################


	    #Validates party details
	    def self.validatePartyDetails(party, facetData, errors)
	    	tempErrorHash = Hash.new
	    	if facetData[:renderCustomerId] && party.customerId.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "customerId", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('customerId')]) 
			end

	    	if facetData[:renderPartytypecd] && party.partyTypeCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "partyTypeCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('proposerPartyTypeCd')]) 
			end

			if party.partyTypeCd == 'INDIVIDUAL'
				if facetData[:renderTitlecd] && party.titleCd.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "titleCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('titleCd')]) 
				end

				if facetData[:renderFirstname1] && party.firstName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "firstName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('firstName1')]) 
				elsif facetData[:renderFirstname1] && (/[^a-zA-Z0-9\-\']/.match(party.firstName1.force_encoding(Encoding::UTF_8))) 
					MobiSys::CommonUtil.addErrors(tempErrorHash, "firstName1", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('firstName1'), MobiSys::BrowserHelper.getLabel('valid')])
				end

				if facetData[:renderMiddlenamePanel]
					if facetData[:renderMiddlename1] && party.middleName1.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash, "middleName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('middleName1')]) 
					elsif facetData[:renderMiddlename1] && (/[^a-zA-Z0-9\-\']/.match(party.middleName1.force_encoding(Encoding::UTF_8)))
						MobiSys::CommonUtil.addErrors(tempErrorHash, "middleName1", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('middleName1'), MobiSys::BrowserHelper.getLabel('valid')]) 
					end
				end	

				if facetData[:renderLastname1] && party.lastName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "lastName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('lastName1')]) 
				elsif facetData[:renderLastname1] && (/[^a-zA-Z0-9\-\']/.match(party.lastName1.force_encoding(Encoding::UTF_8)))
					MobiSys::CommonUtil.addErrors(tempErrorHash, "lastName1", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('lastName1'), MobiSys::BrowserHelper.getLabel('valid')]) 
				end

				if facetData[:renderExtensionname1] && party.extensionName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "extensionName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('extensionName1')]) 
				end

				if facetData[:renderMultiLanguagePanel]
					if facetData[:renderFirstname2] && party.firstName2.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash, "firstName2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('firstName2')]) 
					elsif facetData[:renderFirstname2] && (/[^a-zA-Z0-9\-\']/.match(party.firstName2.force_encoding(Encoding::UTF_8)))
						MobiSys::CommonUtil.addErrors(tempErrorHash, "firstName2", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('firstName2'), MobiSys::BrowserHelper.getLabel('valid')]) 
					end

					if facetData[:renderMiddlenamePanel] && facetData[:renderMiddlename2] && party.middleName2.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash, "middleName2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('middlename2')]) 
					elsif facetData[:renderMiddlenamePanel] && facetData[:renderMiddlename2] && (/[^a-zA-Z0-9\-\']/.match(party.middleName2.force_encoding(Encoding::UTF_8)))
						MobiSys::CommonUtil.addErrors(tempErrorHash, "middleName2", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('middlename2'), MobiSys::BrowserHelper.getLabel('valid')]) 
					end

					if facetData[:renderLastname2] && party.lastName2.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash, "lastName2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('lastname2')]) 
					elsif facetData[:renderLastname2] && (/[^a-zA-Z0-9\-\']/.match(party.lastName2.force_encoding(Encoding::UTF_8)))
						MobiSys::CommonUtil.addErrors(tempErrorHash, "lastName2", "ERR_FORMAT", [MobiSys::BrowserHelper.getLabel('lastname2'), MobiSys::BrowserHelper.getLabel('valid')]) 
					end

					if facetData[:renderExtensionname2] && party.extensionName2.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash, "extensionName2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('extensionName2')]) 
					end
				end	

				if facetData[:renderBirthdt] && party.birthDt.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "birthDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('birthDt')]) 
				end

				if facetData[:renderAge] && party.age.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"age", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('age')])      
				end

				if facetData[:renderGendercd] && party.genderCd.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"genderCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('genderCd')])      
				end

				if facetData[:renderRelationcd] && party.relationCd.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"relationCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('proposerRelation')])      
				end

				if facetData[:renderCountryOfBirth] && party.countryOfBirth.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"countryOfBirth", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('countryOfBirth')])      
				end

				if facetData[:renderPlaceOfBirth] && party.placeOfBirth.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"placeOfBirth", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('placeOfBirth')])      
				end

				if facetData[:renderMaritalStatusCd] && party.maritalStatusCd.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"maritalStatusCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('maritalStatusCd')])      
				end

				if facetData[:renderMotherMaidenFirstname] && party.motherMaidenFirstname.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"motherMaidenFirstname", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('motherMaidenFirstname')])      
				end

				if facetData[:renderMotherMaidenLastname] && party.motherMaidenLastname.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"motherMaidenLastname", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('motherMaidenLastname')])      
				end

				if facetData[:renderSmokerPanel] && facetData[:renderSmoker] && party.smoker.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"smoker", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('smoker')])      
				end

				if facetData[:renderNsapPanel] && facetData[:renderNsap] && party.nsap.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"nsap", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('nsap')])      
				end

				if facetData[:renderFatherFirstName1] && party.fatherFirstName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"fatherFirstName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('fatherFirstName')])      
				end

				if facetData[:renderFatherMiddleName1] && party.fatherMiddleName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"fatherMiddleName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('fatherMiddleName')])      
				end

				if facetData[:renderFatherLastName1] && party.fatherLastName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash,"fatherLastName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('fatherLastName')])      
				end

				if facetData[:renderCoverageLocPanel]
					if facetData[:renderCoveragecountrycd] && party.coverageCountryCd.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"coverageCountryCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('coverageCountryCd')])      
					end

					if facetData[:renderCoveragecitycd] && party.coverageCityCd.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"coverageCityCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('coverageCityCd')])      
					end
				end	

				if facetData[:renderNationalityPanel]
					if facetData[:renderCitizenshipCd] && party.citizenshipCd.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"citizenshipCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('citizenshipCd')])      
					end

					if party.citizenshipCd.to_s == "OTHERS" && facetData[:renderOtherCitizenship] && party.otherCitizenship.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"otherCitizenship", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('otherCitizenship')])      
					end

					if facetData[:renderNonResidentFl] && party.nonResidentFl.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"nonResidentFl", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('nonResidentFl')])      
					end

					if facetData[:renderReligionCd] && party.religionCd.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"religionCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('religionCd')])      
					end

					if facetData[:renderRaceCd] && party.raceCd.to_s == ""
						MobiSys::CommonUtil.addErrors(tempErrorHash,"raceCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('race')])      
					end
				end	

				if facetData[:renderTitlecd] && facetData[:renderGendercd]
					checkGenderTitleMapping(party, tempErrorHash)
				end
			
				if facetData[:renderAge] && facetData[:renderMaritalStatusCd]
					if party.age.to_i <= 17 && party.maritalStatusCd == "M"
						MobiSys::CommonUtil.addErrors(tempErrorHash, "age", "ERR_MARITALSTATUS", [MobiSys::BrowserHelper.getLabel('MARRIED')])            
					end
				end

				if facetData[:renderIdentityPanel]
					partyIdentity = party.getPartyIdentityList
					validatePartyIdentity(partyIdentity[0], facetData, errors) if partyIdentity[0]
					validatePartyIdentity(partyIdentity[1], facetData, errors) if partyIdentity[1]
				end

				if facetData[:renderOccupationPanel]
					partyEmployment = party.getPartyEmployment
					if partyEmployment
						if facetData[:renderOccupationTypeCd] && partyEmployment.occupationTypeCd.to_s == "EMPLOYED" || partyEmployment.occupationTypeCd.to_s == "BUSINESS"
							validatePartyEmployment(partyEmployment, facetData, errors)
					
							if facetData[:renderAge] && facetData[:renderAnnualIncome] && party.age.to_i <= 17 && partyEmployment.annualIncome.to_i > 0
								MobiSys::CommonUtil.addErrors(tempErrorHash, "annualIncome", "ERR_INCOME", [party.firstName1])
							end
						end
					end
				end

				if facetData[:renderAddressPanel]
					if party.copyFromAddr1.to_s == "" && facetData[:renderHomeAddressPanel]
						homeAddress = party.getPartyAddress("RESIDENTIAL")
						validatePartyAddress(homeAddress, facetData, errors) if homeAddress
					end

					if partyEmployment
						if facetData[:renderOccupationTypeCd] && facetData[:renderOfficeAddressPanel] && partyEmployment.occupationTypeCd.to_s == "EMPLOYED" && party.copyFromAddr2.to_s == ""
				        	businessAddress = party.getPartyAddress("OFFICE")
							validatePartyAddress(businessAddress, facetData, errors) if businessAddress
						end
					end

					if partyEmployment
						if facetData[:renderOccupationTypeCd] && partyEmployment.occupationTypeCd.to_s == "BUSINESS"
							if party.copyFromAddr2.to_s == "" && facetData[:renderOfficeAddressPanel]
				        		businessAddress = party.getPartyAddress("OFFICE")
								validatePartyAddress(businessAddress, facetData, errors) if businessAddress
							end
							if party.copyFromAddr3.to_s == "" && facetData[:renderPermanentAddressPanel]
					        	permanentAddress = party.getPartyAddress("PERMANENT")
								validatePartyAddress(permanentAddress, facetData, errors) if permanentAddress
							end
						end
					end
				end

				if facetData[:renderContactPanel]
					if facetData[:renderHomeContactPanel]
				        partyContactHome = party.getPartyContact("RESIDENTIAL")
		    			validatePartyContact(partyContactHome, facetData, errors) if partyContactHome
		    		end

		    		if facetData[:renderOfficeContactPanel]
				        partyContactOffice = party.getPartyContact("OFFICE") 
		    			validatePartyContact(partyContactOffice, facetData, errors) if partyContactOffice
		    		end	

		    		if facetData[:renderMobileContactPanel]	
				        partyContactMobile = party.getPartyContact("MOBILE")
		    			validatePartyContact(partyContactMobile, facetData, errors) if partyContactMobile
		    		end

		    		if facetData[:renderEmailPanel]
		    			partyEmail = party.getPartyEmail
		    			validatePartyEmail(partyEmail, facetData, errors) if partyEmail
	    			end
				end
			elsif party.partyTypeCd == 'ORGANIZATION'
				if facetData[:renderCorporatePanel] && facetData[:renderCorporatename1] && party.corporateName1.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "corporateName1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('companyName1')])      
				end

				if facetData[:renderMultiLanguagePanel] && facetData[:renderCorporatePanel] && facetData[:renderCorporatename2] && party.corporateName2.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "corporateName2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('companyName2')])      
				end

				if facetData[:renderIdentityPanel]
					partyIdentity = party.getPartyIdentityList
					validatePartyIdentity(partyIdentity[0], facetData, errors) if partyIdentity[0]
					validatePartyIdentity(partyIdentity[1], facetData, errors) if partyIdentity[1]
				end

				if facetData[:renderAddressPanel] && facetData[:renderOfficeAddressPanel]
		        	businessAddress = party.getPartyAddress("OFFICE")
					validatePartyAddress(businessAddress, facetData, errors) if businessAddress
				end

				if facetData[:renderContactPanel]
			        if facetData[:renderHomeContactPanel]
				        partyContactHome = party.getPartyContact("RESIDENTIAL")
		    			validatePartyContact(partyContactHome, facetData, errors) if partyContactHome
		    		end

		    		if facetData[:renderOfficeContactPanel]
				        partyContactOffice = party.getPartyContact("OFFICE") 
		    			validatePartyContact(partyContactOffice, facetData, errors) if partyContactOffice
		    		end	

		    		if facetData[:renderMobileContactPanel]	
				        partyContactMobile = party.getPartyContact("MOBILE")
		    			validatePartyContact(partyContactMobile, facetData, errors) if partyContactMobile
		    		end

		    		if facetData[:renderEmailPanel]
		    			partyEmail = party.getPartyEmail
		    			validatePartyEmail(partyEmail, facetData, errors) if partyEmail
	    			end
				end
			end

			if !tempErrorHash.empty?
		    	errors[:PartyDO] = Hash.new if !errors[:PartyDO].is_a?(Hash)
	    	 	errors[:PartyDO][party.guid.to_sym] = Hash.new if !errors[:PartyDO][party.guid.to_sym].is_a?(Hash)
		    	errors[:PartyDO][party.guid.to_sym] = errors[:PartyDO][party.guid.to_sym].merge(tempErrorHash)
		    end
	    end
	    ##################################################################################################


	    #Validates PartyIdentity details for a given party
	    def self.validatePartyIdentity(partyIdentity, facetData, errors)
	    	tempErrorHash = Hash.new
			if facetData[:renderIdentityTypeCd] && partyIdentity.identityTypeCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "identityTypeCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('identityTypeCd')])      
			end

			if facetData[:renderIdentityNum] && partyIdentity.identityNum.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "identityNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('identityNum')])      
			end

			if facetData[:renderIssuingAuthority] && partyIdentity.issuingAuthority.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "issuingAuthority", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('issuingAuthority')])      
			end

			if facetData[:renderIssueDt] && partyIdentity.issueDt.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "issueDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('issueDt')])      
			end

			if facetData[:renderExpiryDt] && partyIdentity.expiryDt.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "expiryDt", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('expiryDt')])      
			end

			if facetData[:renderIssueDt] && facetData[:renderExpiryDt]
				checkIdentityDates(partyIdentity, tempErrorHash)
			end

			if !tempErrorHash.empty?
		    	errors[:PartyIdentityDO] = Hash.new if !errors[:PartyIdentityDO].is_a?(Hash)
	    	 	errors[:PartyIdentityDO][partyIdentity.guid.to_sym] = Hash.new if !errors[:PartyIdentityDO][partyIdentity.guid.to_sym].is_a?(Hash)
		    	errors[:PartyIdentityDO][partyIdentity.guid.to_sym] = errors[:PartyIdentityDO][partyIdentity.guid.to_sym].merge(tempErrorHash)
			end
	    end
	    ##################################################################################################


	    #Validates PartyEmployment details for a given party
	    def self.validatePartyEmployment(partyEmployment, facetData, errors)
	    	tempErrorHash = Hash.new
			if facetData[:renderOccupationTypeCd] && partyEmployment.occupationTypeCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "occupationTypeCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('occupationCd')])      
			end

			if facetData[:renderEmployerName] && partyEmployment.employerName.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "employerName", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('employerName')])      
			end

			if facetData[:renderPepCd] && partyEmployment.pepCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "pepCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('pepCd')])      
			end

			if facetData[:renderAnnualIncome] && partyEmployment.annualIncome.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "annualIncome", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('annualIncome')])      
			end

			if facetData[:renderIndustrycd] && partyEmployment.industryCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "industryCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('industryCd')])      
			end

			if facetData[:renderNatureofduty] && partyEmployment.natureOfDuty.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "natureOfDuty", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('natureOfDuty')])      
			end

			if facetData[:renderOccupationClassPanel] && facetData[:renderOccupationclass] && partyEmployment.occupationClass.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "occupationClass", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('occupationClass')])      
			end

			if !tempErrorHash.empty?
		    	errors[:PartyIdentityDO] = Hash.new if !errors[:PartyIdentityDO].is_a?(Hash)
	    	 	errors[:PartyIdentityDO][partyEmployment.guid.to_sym] = Hash.new if !errors[:PartyIdentityDO][partyEmployment.guid.to_sym].is_a?(Hash)
		    	errors[:PartyIdentityDO][partyEmployment.guid.to_sym] = errors[:PartyIdentityDO][partyEmployment.guid.to_sym].merge(tempErrorHash)
		    end
	    end
	    ##################################################################################################


	    #Validates PartyAddress details for a given party
	    def self.validatePartyAddress(partyAddress, facetData, errors)
	    	tempErrorHash = Hash.new
	    	if facetData[:renderAddressLine1Lang1] && partyAddress.addressLine1Lang1.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine1Lang1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine1')])      
			end
			
			if facetData[:renderaddressLine2Lang1] && partyAddress.addressLine2Lang1.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine2Lang1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine2')])      
			end
			
			if facetData[:renderaddressLine3Lang1] && partyAddress.addressLine3Lang1.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine3Lang1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine3')])      
			end
			
			if facetData[:renderaddressLine4Lang1] && partyAddress.addressLine4Lang1.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine4Lang1", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine4')])      
			end

			if facetData[:renderMultiLanguagePanel]
				if facetData[:renderAddressLine1Lang2] && partyAddress.addressLine1Lang2.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine1Lang2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine1')])      
				end
				
				if facetData[:renderaddressLine2Lang2] && partyAddress.addressLine2Lang2.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine2Lang2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine2')])      
				end
				
				if facetData[:renderaddressLine3Lang2] && partyAddress.addressLine3Lang2.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine3Lang2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine3')])      
				end
				
				if facetData[:renderaddressLine4Lang2] && partyAddress.addressLine4Lang2.to_s == ""
					MobiSys::CommonUtil.addErrors(tempErrorHash, "addressLine4Lang2", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('addressLine4')])      
				end
			end	
			
			if facetData[:renderAddressCountryCd] && partyAddress.countryCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "countryCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('countryCd')])      
			end
			
			if facetData[:renderPinCode] && partyAddress.pinCode.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "pinCode", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('PinCode')])      
			end
			
			if facetData[:renderDistrictCd] && partyAddress.districtCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "districtCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('stateCd')])      
			end
			
			if facetData[:renderCityCd] && partyAddress.cityCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "cityCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('cityCd')])      
			end

			if !tempErrorHash.empty?
				errors[:PartyAddressDO] = Hash.new if !errors[:PartyAddressDO].is_a?(Hash)
	    	 	errors[:PartyAddressDO][partyAddress.guid.to_sym] = Hash.new if !errors[:PartyAddressDO][partyAddress.guid.to_sym].is_a?(Hash)
		    	errors[:PartyAddressDO][partyAddress.guid.to_sym] = errors[:PartyAddressDO][partyAddress.guid.to_sym].merge(tempErrorHash)
		    end
	    end
	    ##################################################################################################


	    #Validates PartyContact details for a given party
	    def self.validatePartyContact(partyContact, facetData, errors)
		    tempErrorHash = Hash.new
			if facetData[:renderCountryCd] && partyContact.countryCd.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "countryCd", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('countryCd')])      
			end

			if facetData[:renderStdCode] && partyContact.stdCode.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "stdCode", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('stdCode')])      
			end

			if facetData[:renderContactNum] && partyContact.contactNum.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "contactNum", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('contactNum')])      
			end

	    	if !tempErrorHash.empty?
		    	errors[:PartyContactDO] = Hash.new if !errors[:PartyContactDO].is_a?(Hash)
	    	 	errors[:PartyContactDO][partyContact.guid.to_sym] = Hash.new if !errors[:PartyContactDO][partyContact.guid.to_sym].is_a?(Hash)
		    	errors[:PartyContactDO][partyContact.guid.to_sym] = errors[:PartyContactDO][partyContact.guid.to_sym].merge(tempErrorHash)
		    end
	    end
	    ##################################################################################################
	    

	    #Validates PartyEmail details for a given party
	    def self.validatePartyEmail(partyEmail, facetData, errors)
	    	tempErrorHash = Hash.new
			if facetData[:renderEmailaddress] && partyEmail.emailAddress.to_s == ""
				MobiSys::CommonUtil.addErrors(tempErrorHash, "emailAddress", "ERR_MANDATORY", [MobiSys::BrowserHelper.getLabel('emailID')])      
			end

			if !tempErrorHash.empty?
		    	errors[:PartyEmailDO] = Hash.new if !errors[:PartyEmailDO].is_a?(Hash)
	    	 	errors[:PartyEmailDO][partyEmail.guid.to_sym] = Hash.new if !errors[:PartyEmailDO][partyEmail.guid.to_sym].is_a?(Hash)
		    	errorHash = errors[:PartyEmailDO][partyEmail.guid.to_sym]
		    end	
	    end
	    ##################################################################################################
    end
end

begin 
    require 'Party/party_b_o_company'
rescue LoadError => e
    puts 'party_b_o_company not included'
end
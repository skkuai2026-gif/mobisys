require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisyssignature'
require 'RPQResponse/r_p_q_response_b_o'
require 'date'

class LeadRPQController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper


	#Method to get lookups for City & State based on Industry lookup and Pincode value
    def getPincodeCityStateCountryLookups(lead = nil)
        if lead
            countryCd = lead.country
            pinCode = lead.pincode
        else
            countryCd = @params['countryCd']
            pinCode = @params['pinCode']
            @option = @params['option']
        end

        @districtLookUps = Array.new
        @cityLookUps = Array.new

        districtCityLookup = PincodeCityStateCountryMapping.loadObject(
            :all,
            :conditions => {
                { :name => 'countryCd' }=> countryCd,
                { :name => 'pinCode' }=> pinCode,
                :op => 'AND'
            }
        )   

        districtCityLookup.each do |distCity|
            districtLookup = Lookupvalue.new
            districtLookup.cd = distCity.stateCd.to_s
            districtLookup.desc = distCity.stateDesc.to_s
            @districtLookUps.push(districtLookup)

            cityLookup = Lookupvalue.new
            cityLookup.cd = distCity.cityCd.to_s
            cityLookup.desc = distCity.cityDesc.to_s
            @cityLookUps.push(cityLookup)
        end   
        @districtLookUps.uniq!{|district| district.desc}
        @cityLookUps.uniq!{|city| city.desc}

        if lead
            return @districtLookUps, @cityLookUps
        else
            html = ""
            html << render(:partial => 'getDynamicLookups')
            return html
        end
    end
    ##################################################################################################


	#Method to extend the expiry date by 3 months
  	def extendExpiryDt
  		id = @params['id'][1..-1].chop
  		leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:object => id.to_s})
    	expiryDt = Date.parse(leadRPQ.expiryDt.to_s) >> 3
    	leadRPQ.update_attributes(:expiryDt => expiryDt)
    	if @params.has_key?('capture')
    		redirect :action => :showRPQ, :id => leadRPQ.object.to_s, :query => {:submit => ''}
    	else
    		redirect :action => :searchRPQ
    	end
	end
    ##################################################################################################


  	#Method to render the search page for RPQ
  	def searchRPQ
	  	WebView.execute_js("showLoadingMessage()")

        searchResultSettings = SearchResultSettings.loadObject( 
	  		:all,
	  		:conditions => {
  				{
	  				:name => 'searchName',
	  				:op => 'LIKE'
				} => "LEADSEARCH"
  			}   
		)
  		@settingsHash = MobiSys::CommonUtil.convertToHash(searchResultSettings, "columnName")

        @searchResult = Array.new

        if !@params.empty?
            name = @params['name'].to_s
            mobileNumber = @params['mobileNumber'].to_s
            emailAddress = @params['emailAddress'].to_s
            signatureDt = @params['signatureDt'].to_s
            expiryDt = @params['expiryDt'].to_s

            leadRPQList = LeadRPQ.loadObject(
                :all,
                :per_page => 200,
                :order => 'object', 
                :orderdir => 'DESC',
                :select => ['title', 'firstname', 'lastname', 'mobileNumber', 'object', 'emailAddress', 'signatureDt', 'expiryDt', 'outputInsurancePlanSuited']
            )

            leadRPQList.each do |leadRPQ|
                validRPQ = true

                leadFullName = getLabelValue(leadRPQ.title.to_s) + " " + leadRPQ.firstname.to_s + " " + leadRPQ.lastname.to_s

                if name != ""
                    validRPQ = false if leadFullName.index(name.to_s) == nil
                end
                
                if mobileNumber != "" && validRPQ
                    validRPQ = false if leadRPQ.mobileNumber.to_s.index(mobileNumber.to_s) == nil
                end
                
                if emailAddress != "" && validRPQ
                    validRPQ = false if leadRPQ.emailAddress.to_s.index(emailAddress.to_s) == nil
                end
                
                if signatureDt != "" && validRPQ
                    validRPQ = false if leadRPQ.signatureDt.to_s.index(signatureDt.to_s) == nil
                end
                
                if expiryDt != "" && validRPQ
                    validRPQ = false if leadRPQ.expiryDt.to_s.index(expiryDt.to_s) == nil
                end
                
                if validRPQ
                    leadRPQHash = Hash.new
                    leadRPQHash[:object] = leadRPQ.object
                    if leadFullName.to_s.strip != ""
                        leadRPQHash[:name] = leadFullName
                    else
                        leadRPQHash[:name] = "-"
                    end
                    if leadRPQ.mobileNumber.to_s != ""
                        leadRPQHash[:mobileNumber] = leadRPQ.mobileNumber
                    else
                        leadRPQHash[:mobileNumber] = "-"
                    end
                    if leadRPQ.emailAddress.to_s != ""
                        leadRPQHash[:emailAddress] = leadRPQ.emailAddress
                    else
                        leadRPQHash[:emailAddress] = "-"
                    end
                    if leadRPQ.signatureDt.to_s != ""
                        leadRPQHash[:signatureDt] = getScreenDate(leadRPQ.signatureDt)
                    else
                        leadRPQHash[:signatureDt] = "-"
                    end
                    if leadRPQ.expiryDt.to_s != ""
                        leadRPQHash[:expiryDt] = getScreenDate(leadRPQ.expiryDt)
                        if Time.parse(leadRPQ.expiryDt.to_s) < Time.now
                        	leadRPQHash[:extendFl] = true
                        else
                    		leadRPQHash[:extendFl] = false
                    	end
                    else
                        leadRPQHash[:expiryDt] = "-"
                    	leadRPQHash[:extendFl] = false
                    end
                    leadRPQHash[:statusCd] = leadRPQ.statusCd
                    @searchResult.push(leadRPQHash)
                end
            end
        end

        render :action => :searchRPQ, :layout => :newEAPPLayout
  	end
    ##################################################################################################


    #Method to display existing RPQ
	def showRPQ
	  	WebView.execute_js("showLoadingMessage()")

    	id = @params['id'][1..-1].chop
        @str = @params['str'].to_s
        @selectedProductId = @params['selectedProductId'].to_s

  		$total_error = Hash.new if !@params.has_key?('submit')
    	@leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:object => id.to_s})
    	@saved_response = RPQResponse.loadObject(:all, :conditions => { :rpqId => @leadRPQ.rpqId.to_s },:loadChild => 'false')
	    
	    @leadRPQ.dob = getScreenDate(@leadRPQ.dob) if @leadRPQ.dob.to_s != ""
	    @leadRPQ.agentSignatureDt = getScreenDate(@leadRPQ.agentSignatureDt) if @leadRPQ.agentSignatureDt.to_s != ""
	    @leadRPQ.signatureDt = getScreenDate(@leadRPQ.signatureDt) if @leadRPQ.signatureDt.to_s != ""

	  	@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@leadRPQ)
 		@questionKeys = MobiSys::RPQResponseBO::QUESTION_SEQUENCE
 		@application = Application.getValue('DEFAULTLOCALE')

 		if @leadRPQ.expiryDt.to_s != "" && Time.parse(@leadRPQ.expiryDt.to_s) < Time.now
        	@extendFl = true
        else
    		@extendFl = false
    	end

    	render :action => :captureRPQ, :layout => :newEAPPLayout
  	end
    ##################################################################################################
  

  	#Method to create new RPQ using existing data from LeadFNA
  	def newRPQ
	  	WebView.execute_js("showLoadingMessage()")
        @leadRPQ = LeadRPQ.new
        $total_error = Hash.new
        @leadRPQ.rpqId = SequenceNoGenerator.getNextNumber('RPQID')
        if !$rhoconfig[:TABFEATUREREQD]
            leadFNA = LeadFNA.loadObject(:first,:conditions => {:object => @params['id'][1..-2]}, :loadChild => 'false') 
            @leadRPQ.fnaId = leadFNA.fnaId
            @leadRPQ.leadId = leadFNA.leadId
            @leadRPQ.title = leadFNA.title
            @leadRPQ.firstname = leadFNA.firstname
            @leadRPQ.middlename = leadFNA.middlename
            @leadRPQ.lastname = leadFNA.lastname
            @leadRPQ.genderCd = leadFNA.genderCd
            @leadRPQ.maritalStatus = leadFNA.maritalStatus
            @leadRPQ.dob = leadFNA.dob
            @leadRPQ.age = leadFNA.age
            @leadRPQ.leadSource = leadFNA.leadSource
            @leadRPQ.leadSourceOther = leadFNA.leadSourceOther
            @leadRPQ.occupationCd = leadFNA.occupationCd
            @leadRPQ.incomeGroup = leadFNA.incomeGroup
            @leadRPQ.natureOfDuty = leadFNA.natureofDutyId
            @leadRPQ.nationality = leadFNA.nationality
            @leadRPQ.residenceNumber = leadFNA.residenceNumber
            @leadRPQ.officeNumber = leadFNA.officeNumber
            @leadRPQ.mobileNumber = leadFNA.mobileNumber
            @leadRPQ.emailAddress = leadFNA.emailAddress
            @leadRPQ.fromTime = leadFNA.fromTime
            @leadRPQ.toTime = leadFNA.toTime
            @leadRPQ.address1 = leadFNA.address1
            @leadRPQ.address2 = leadFNA.address2
            @leadRPQ.address3 = leadFNA.address3
            @leadRPQ.address4 = leadFNA.address4
            @leadRPQ.country = leadFNA.country
            @leadRPQ.pincode = leadFNA.pincode
            @leadRPQ.state = leadFNA.state
            @leadRPQ.city = leadFNA.city
        elsif @params['fnaId'].to_s != "" 
            if @params['fnaId'].include? ('{')
                @str = @params['fnaId'][1..-1].chop
                strArrayOfIdAndProduct = []
                fnaPlan = ""
                fnaIOSelectedGuid = ""
            else
                @str = @params['fnaId']
            end
            
            if @str
                if @str.include?("|")
                    strArrayOfIdAndProduct = @str.split("|")
                    id = strArrayOfIdAndProduct[0]
                    strArrayOfIdAndProduct.shift
                    fnaIOSelectedGuid = strArrayOfIdAndProduct[0]
                    strArrayOfIdAndProduct.shift
                    fnaPlan = strArrayOfIdAndProduct[0].to_s
                    fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
                else
                    id = @str
                    fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
                end
                fnaParty = fnaRequest.getParty("PROPOSER")
            else  
                fnaRequest = nil
            end

            if fnaRequest && fnaRequest.leadId != ""
                lead = Lead.loadObject( :first, :conditions => { :leadId => fnaRequest.leadId } )

                @leadRPQ.fnaId = fnaRequest.fnaNum
                @leadRPQ.leadId = fnaRequest.leadId
                @leadRPQ.title = fnaParty.titleCd
                @leadRPQ.firstname = fnaParty.firstName1
                @leadRPQ.middlename = fnaParty.middleName1
                @leadRPQ.lastname = fnaParty.lastName1
                @leadRPQ.genderCd = fnaParty.genderCd
                @leadRPQ.maritalStatus = fnaParty.maritalStatusCd
                @leadRPQ.dob = fnaParty.birthDt
                @leadRPQ.age = fnaParty.age
                @leadRPQ.leadSource = lead.leadSource
                @leadRPQ.leadSourceOther = lead.leadSourceOther
                @leadRPQ.occupationCd = fnaParty.occupationCd
                @leadRPQ.incomeGroup = lead.incomeGroup 
                @leadRPQ.natureOfDuty = fnaParty.natureOfDuty
                @leadRPQ.nationality = lead.nationality 
                @leadRPQ.residenceNumber = fnaParty.contactNum
                @leadRPQ.officeNumber = fnaParty.officeNumber 
                @leadRPQ.mobileNumber = fnaParty.mobileNum
                @leadRPQ.emailAddress = fnaParty.emailAddress
                @leadRPQ.fromTime = lead.fromTime
                @leadRPQ.toTime = lead.toTime
                @leadRPQ.address1 = fnaParty.addressLine1Lang1
                @leadRPQ.address2 = fnaParty.addressLine2Lang1
                @leadRPQ.address3 = fnaParty.addressLine3Lang1
                @leadRPQ.address4 = fnaParty.addressLine4Lang1
                @leadRPQ.country = fnaParty.countryCd
                @leadRPQ.pincode = lead.pincode
                @leadRPQ.state = lead.state
                @leadRPQ.city = lead.city
            end
       
        elsif $lead_obj.to_s != "" 
            @selectedProductId = @params['selectedProductId']
            lead = Lead.loadObject(:first, :conditions => {:object => $lead_obj.to_s})
            @leadRPQ.leadId = lead.leadId
            @leadRPQ.title = lead.title
            @leadRPQ.firstname = lead.firstname
            @leadRPQ.middlename = lead.middlename
            @leadRPQ.lastname = lead.lastname
            @leadRPQ.genderCd = lead.genderCd
            @leadRPQ.maritalStatus = lead.maritalStatus
            @leadRPQ.dob = lead.dob
            @leadRPQ.age = lead.age
            @leadRPQ.leadSource = lead.leadSource
            @leadRPQ.leadSourceOther = lead.leadSourceOther
            @leadRPQ.occupationCd = lead.occupationCd
            @leadRPQ.incomeGroup = lead.incomeGroup 
            @leadRPQ.natureOfDuty = lead.natureofDutyId
            @leadRPQ.nationality = lead.nationality 
            @leadRPQ.residenceNumber = lead.residenceNumber
            @leadRPQ.officeNumber = lead.officeNumber 
            @leadRPQ.mobileNumber = lead.mobileNumber
            @leadRPQ.emailAddress = lead.emailAddress
            @leadRPQ.fromTime = lead.fromTime
            @leadRPQ.toTime = lead.toTime
            @leadRPQ.address1 = lead.address1
            @leadRPQ.address2 = lead.address2
            @leadRPQ.address3 = lead.address3
            @leadRPQ.address4 = lead.address4
            @leadRPQ.country = lead.country
            @leadRPQ.pincode = lead.pincode
            @leadRPQ.state = lead.state
            @leadRPQ.city = lead.city

        end  

	    @leadRPQ.dob = getScreenDate(@leadRPQ.dob) if @leadRPQ.dob.to_s != ""
	    @leadRPQ.agentSignatureDt = getScreenDate(@leadRPQ.agentSignatureDt) if @leadRPQ.agentSignatureDt.to_s != ""
	    @leadRPQ.signatureDt = getScreenDate(@leadRPQ.signatureDt) if @leadRPQ.signatureDt.to_s != ""
	  	@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@leadRPQ)
 		@application = Application.getValue('DEFAULTLOCALE')
 		@questionKeys = MobiSys::RPQResponseBO::QUESTION_SEQUENCE
 		@extendFl = false
        $lead_obj = nil 
	    render :action => :captureRPQ, :layout => :newEAPPLayout 
  	end
    ##################################################################################################
  

  	#Method to save & validate leadRPQ capture screen
	def executeSubmit
	  	WebView.execute_js("showLoadingMessage()")

        @str = @params['str'].to_s
        @selectedProductId = @params['selectedProductId'].to_s
		leadRPQ = MobiSys::BrowserHelper.convertToObject('LeadRPQ', @params['LeadRPQ'])
      	leadRPQ.agentId = AgentReg.getCurrentAgentReg.agentId
    	leadRPQ.dob = getDBDate(leadRPQ.dob) if leadRPQ.dob.to_s != ""
    	leadRPQ.agentSignatureDt = getDBDate(leadRPQ.agentSignatureDt) if leadRPQ.agentSignatureDt.to_s != ""
    	leadRPQ.signatureDt = getDBDate(leadRPQ.signatureDt) if leadRPQ.signatureDt.to_s != ""
        leadRPQ.expiryDt = Date.parse(leadRPQ.signatureDt.to_s) >> 6 if leadRPQ.signatureDt.to_s != ""
        
        if leadRPQ.agentSignatureCd.to_s != "" && !leadRPQ.agentSignatureCd.to_s.start_with?('ZLIBCMP')
            leadRPQ.agentSignatureCd = leadRPQ.agentSignatureCd.gsub!('data:image/png;base64,','')
            original_signature_decoded = MobiSys::Encryption.decodeContents(leadRPQ.agentSignatureCd)
            compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
            leadRPQ.agentSignatureCd = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
        end

        if leadRPQ.signatureCd.to_s != "" && !leadRPQ.signatureCd.to_s.start_with?('ZLIBCMP')
            leadRPQ.signatureCd = leadRPQ.signatureCd.gsub!('data:image/png;base64,','')
            original_signature_decoded = MobiSys::Encryption.decodeContents(leadRPQ.signatureCd)
            compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
            leadRPQ.signatureCd = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
        end
      	
        lookupkeys = MobiSys::RPQResponseBO::QUESTION_SEQUENCE
	    errorQuestions = []
		rpq_score = 0
        RPQResponse.delete_all(:conditions =>{'rpqId' => leadRPQ.rpqId })
		# save responses, add errors, and calculate rpq_score in this loop
		lookupkeys.each do |key|
			if @params[key.to_s].nil?
				errorQuestions << key
			else
				rpqResponse = RPQResponse.new(:rpqId => leadRPQ.rpqId.to_s, :question => key.to_s, :score => @params[key.to_s].to_s)
				rpqResponse.persistAll
				rpq_score = rpq_score + @params[key].to_i
			end
		end
		if !errorQuestions.empty? && (errorQuestions.any? {|k| k.include? 'RPQ' } == true)
			rpq_score = 0
		end

	    leadRPQ.statusCd = "PENDING"
        leadRPQ.rpqScore = rpq_score.to_s
      	leadRPQ.persistAll

      	errors = Hash.new
      	leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:object => leadRPQ.object})
      	MobiSys::RPQResponseBO.validate(errors, leadRPQ, errorQuestions)
      	$total_error['LeadRPQ'] = errors
      	if errors.empty?
	    	leadRPQ.statusCd = ""
      		leadRPQ.persistAll
      	end

	    redirect :action => :showRPQ, :id => leadRPQ.object.to_s, :query => {:submit => '', :str => @str , :selectedProductId=> @selectedProductId}
	end
    ##################################################################################################
end

begin 
    require 'LeadRPQ/lead_r_p_q_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'lead_r_p_q_controller_Jazz not included'
end

begin 
    require 'LeadRPQ/lead_r_p_q_controller_company'
rescue LoadError => e
    puts 'lead_r_p_q_controller_company not included'
end
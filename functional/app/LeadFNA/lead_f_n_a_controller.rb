require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisyssignature'
require 'FNAResponse/f_n_a_response_b_o'
require 'date'
require 'time'

class LeadFNAController < Rho::RhoController
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


    #Method to get array of FNA question keys
    def getQuestionKeysArray(selectType = nil)
    	if selectType == "single"
    		return ['FNA_LIFE_STAGE','FNA_INCOME_PERCENT_FOR_PREMIUM','FNA_AVG_MONTH_INCOME', 'FNA_FUND_SOURCE','FNA_GOAL_DURATION']
    	elsif selectType == "multiple"
    		return ['FNA_FINANCIAL_NEED']
    	else
    		return ['FNA_LIFE_STAGE','FNA_FINANCIAL_NEED','FNA_AVG_MONTH_INCOME','FNA_FUND_SOURCE', 'FNA_INCOME_PERCENT_FOR_PREMIUM','FNA_GOAL_DURATION']
		end	
    end
    ##################################################################################################


	#Method to extend the expiry date by 3 months
  	def extendExpiryDt
  		id = @params['id'][1..-1].chop
  		leadfna = LeadFNA.loadObject(:first, :conditions => {:object => id.to_s})
    	expiryDt = Date.parse(leadfna.expiryDt.to_s) >> 3
    	leadfna.update_attributes(:expiryDt => expiryDt)
    	if @params.has_key?('capture')
    		redirect :action => :showFNA, :id => leadfna.object.to_s, :query => {:submit => ''}
    	else
    		redirect :action => :searchFNA
    	end
	end
    ##################################################################################################


  	#Method to render the search page for FNA
  	def searchFNA
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

            leadFNAList = LeadFNA.loadObject(
                :all,
                :per_page => 200,
                :order => 'object', 
                :orderdir => 'DESC',
                :select => ['title', 'firstname', 'lastname', 'mobileNumber', 'object', 'emailAddress', 'signatureDt', 'expiryDt', 'outputInsurancePlanSuited']
            )

            leadFNAList.each do |leadFNA|
                validFNA = true

                leadFullName = getLabelValue(leadFNA.title.to_s) + " " + leadFNA.firstname.to_s + " " + leadFNA.lastname.to_s

                if name != ""
                    validFNA = false if leadFullName.index(name.to_s) == nil
                end
                
                if mobileNumber != "" && validFNA
                    validFNA = false if leadFNA.mobileNumber.to_s.index(mobileNumber.to_s) == nil
                end
                
                if emailAddress != "" && validFNA
                    validFNA = false if leadFNA.emailAddress.to_s.index(emailAddress.to_s) == nil
                end
                
                if signatureDt != "" && validFNA
                    validFNA = false if leadFNA.signatureDt.to_s.index(signatureDt.to_s) == nil
                end
                
                if expiryDt != "" && validFNA
                    validFNA = false if leadFNA.expiryDt.to_s.index(expiryDt.to_s) == nil
                end
                
                if validFNA
                    leadFNAHash = Hash.new
                    leadFNAHash[:object] = leadFNA.object
                    if leadFullName.to_s.strip != ""
                        leadFNAHash[:name] = leadFullName
                    else
                        leadFNAHash[:name] = "-"
                    end
                    if leadFNA.mobileNumber.to_s != ""
                        leadFNAHash[:mobileNumber] = leadFNA.mobileNumber
                    else
                        leadFNAHash[:mobileNumber] = "-"
                    end
                    if leadFNA.emailAddress.to_s != ""
                        leadFNAHash[:emailAddress] = leadFNA.emailAddress
                    else
                        leadFNAHash[:emailAddress] = "-"
                    end
                    if leadFNA.signatureDt.to_s != ""
                        leadFNAHash[:signatureDt] = getScreenDate(leadFNA.signatureDt)
                    else
                        leadFNAHash[:signatureDt] = "-"
                    end
                    if leadFNA.expiryDt.to_s != ""
                        leadFNAHash[:expiryDt] = getScreenDate(leadFNA.expiryDt)
                        if Time.parse(leadFNA.expiryDt.to_s) < Time.now
                        	leadFNAHash[:extendFl] = true
                        else
                    		leadFNAHash[:extendFl] = false
                    	end
                    else
                        leadFNAHash[:expiryDt] = "-"
                    	leadFNAHash[:extendFl] = false
                    end
                    leadFNAHash[:outputInsurancePlanSuited] = leadFNA.outputInsurancePlanSuited
                    leadFNAHash[:fnaStatus] = leadFNA.fnaStatus
                    @searchResult.push(leadFNAHash)
                end
            end
        end

        render :action => :searchFNA, :layout => :newEAPPLayout
  	end
    ##################################################################################################


    #Method to display existing FNA
	def showFNA
	  	WebView.execute_js("showLoadingMessage()")

    	id = @params['id'][1..-1].chop
  		$total_error = Hash.new if !@params.has_key?('submit')
    	@leadfna = LeadFNA.loadObject(:first, :conditions => {:object => id.to_s})
    	@saved_response = FNAResponse.loadObject(:all, :conditions => { :fnaId => @leadfna.fnaId.to_s }, :loadChild => 'false')
	    
	    @leadfna.dob = getScreenDate(@leadfna.dob) if @leadfna.dob.to_s != ""
	    @leadfna.agentSignatureDt = getScreenDate(@leadfna.agentSignatureDt) if @leadfna.agentSignatureDt.to_s != ""
	    @leadfna.signatureDt = getScreenDate(@leadfna.signatureDt) if @leadfna.signatureDt.to_s != ""

	  	@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@leadfna)
	  	@single_select_questions = getQuestionKeysArray("single")
 		@questionKeys = getQuestionKeysArray
 		@application = Application.getValue('DEFAULTLOCALE')

 		if @leadfna.expiryDt.to_s != "" && Time.parse(@leadfna.expiryDt.to_s) < Time.now
        	@extendFl = true
        else
    		@extendFl = false
    	end

    	render :action => :captureFNA, :layout => :newEAPPLayout
  	end
    ##################################################################################################
  

  	#Method to create new FNA using existing data from Lead
  	def newFNA
	  	WebView.execute_js("showLoadingMessage()")

        lead = Lead.loadObject(:first,:conditions => {:object => @params['id'][1..-2]}, :loadChild => 'false')

	    @leadfna = LeadFNA.new
	    $total_error = Hash.new

        @leadfna.fnaId = SequenceNoGenerator.getNextNumber('FNAID')
	    @leadfna.leadId = lead.leadId
	    @leadfna.title = lead.title
	    @leadfna.firstname = lead.firstname
	    @leadfna.middlename = lead.middlename
	    @leadfna.lastname = lead.lastname
	    @leadfna.genderCd = lead.genderCd
	    @leadfna.maritalStatus = lead.maritalStatus
	    @leadfna.dob = lead.dob
	    @leadfna.age = lead.age
	    @leadfna.leadSource = lead.leadSource
	    @leadfna.leadSourceOther = lead.leadSourceOther
	    @leadfna.occupationCd = lead.occupationCd
	    @leadfna.incomeGroup = lead.incomeGroup
	    @leadfna.natureOfDuty = lead.natureofDutyId
	    @leadfna.nationality = lead.nationality
	    @leadfna.residenceNumber = lead.residenceNumber
	    @leadfna.officeNumber = lead.officeNumber
	    @leadfna.mobileNumber = lead.mobileNumber
	    @leadfna.emailAddress = lead.emailAddress
	    @leadfna.fromTime = lead.fromTime
	    @leadfna.toTime = lead.toTime
	    @leadfna.address1 = lead.address1
	    @leadfna.address2 = lead.address2
	    @leadfna.address3 = lead.address3
	    @leadfna.address4 = lead.address4
	    @leadfna.country = lead.country
	    @leadfna.pincode = lead.pincode
	    @leadfna.state = lead.state
	    @leadfna.city = lead.city

	    @leadfna.dob = getScreenDate(@leadfna.dob) if @leadfna.dob.to_s != ""
	    @leadfna.agentSignatureDt = getScreenDate(@leadfna.agentSignatureDt) if @leadfna.agentSignatureDt.to_s != ""
	    @leadfna.signatureDt = getScreenDate(@leadfna.signatureDt) if @leadfna.signatureDt.to_s != ""
	  	@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@leadfna)
	  	@single_select_questions = getQuestionKeysArray("single")
 		@questionKeys = getQuestionKeysArray
 		@application = Application.getValue('DEFAULTLOCALE')
 		@extendFl = false

	    render :action => :captureFNA, :layout => :newEAPPLayout
  	end
    ##################################################################################################


	#Method called for determining Insurance Plan Suited based on Question 2(Financial Need) and Question 5(Source of Fund) option
	def getInsurancePlan(rule, planOptions, fnaGoalDuration)
		planRule = FNARulesDT.find(
			:first,
			:conditions => {
				{:name => 'ruleName'} => rule.to_s,
				{:name => 'fnaGoalDuration'} => fnaGoalDuration.to_s
			},
			:op => 'AND'
		)
		if planRule
			result = planRule.result
		else
			result = "Unit Linked Life Insurance"
		end
		return result
	end
    ##################################################################################################


  	#Method to get result from FNARulesDT based on column and value changed load to find
  	def getRuleOutput(rule, columnName, columnVal, fnaGoalDuration=nil)
  		result = ""
  		if fnaGoalDuration != nil
  			planRule = FNARulesDT.find(
  				:all,
  				:conditions => {
  					{:name => 'ruleName'} => rule,
  					{
						:name => columnName,
						:op => 'IN'
					} => columnVal.to_s,
					{:name => 'fnaGoalDuration'} => fnaGoalDuration.to_s
				},
				:op => 'AND'
			)
			if planRule
				result = ""
				planRule.each_with_index do |res,i|
					if res.result == "N/A"
						result = 'N/A'
						next
					end
					if i == 0
						result = res.result
					else
						result = result << "," << res.result
					end
				end
			end
		else
			planRule = FNARulesDT.find(
				:first,
				:conditions => {
					{:name => 'ruleName'} => rule,
					{
						:name => columnName,
						:op => 'IN'
					} => columnVal.to_s
				},
				:op => 'AND'
			)
			if planRule
				result = planRule.result
			end
		end
		return result
	end
    ##################################################################################################


  	#Method to get output based on questions answered
  	def getOutputDetails(fnaId)
		outputPlan = ""
		outputRiders = ""
		outputInsuranceProtectionAmt = ""
		outputPaymentPeriod = ""
		fnaRespObj = FNAResponse.loadObject(:all,:conditions =>  {{:name => 'fnaId'} => fnaId.to_s})

		fnaRulesDT = FNARulesDT.new
		fnaRulesDT.fnaFinancialNeed = fnaRespObj.select{|resp| resp.question.to_s.include? "FNA_FINANCIAL_NEED"}.map{ |only_resp| only_resp.score }
		fnaRulesDT.fnaAvgMonthIncome = fnaRespObj.select{|resp| resp.question.to_s.include? "FNA_AVG_MONTH_INCOME"}.map{ |only_resp| only_resp.score }
		fnaRulesDT.fnaGoalDuration = fnaRespObj.select{|resp| resp.question.to_s.include? "FNA_GOAL_DURATION"}.map{ |only_resp| only_resp.score }
		fnaGoalDuration = fnaRespObj.select{|resp| resp.question.to_s == "FNA_GOAL_DURATION"}.map{ |only_resp| only_resp.score }
		rule_arr = ["PLAN","RIDER","PROTECTIONAMOUNT","PAYMENT"]
		getRiderRecord = FNARulesDT.find_by_sql("select * from FNARulesDT where ruleName='RIDER' and fnaFinancialNeed like '%,%' order by priority desc")
		rule_arr.each do |rule|
			if rule == "PLAN"
				outputPlan = getInsurancePlan(rule, fnaRulesDT.fnaFinancialNeed.map{|i| i.to_i},fnaGoalDuration[0])  
			elsif rule == "RIDER"
				outputRiders = getRuleOutput(rule,'fnaFinancialNeed',fnaRulesDT.fnaFinancialNeed.join(','),fnaGoalDuration[0])
			elsif rule == "PROTECTIONAMOUNT"
				outputInsuranceProtectionAmt = getRuleOutput(rule,'fnaAvgMonthIncome',fnaRulesDT.fnaAvgMonthIncome[0])
			else
				outputPaymentPeriod = getRuleOutput(rule,'fnaGoalDuration',fnaRulesDT.fnaGoalDuration[0])
			end
		end
		return outputPlan, outputRiders, outputInsuranceProtectionAmt, outputPaymentPeriod
	end
    ##################################################################################################
  

  	#Method to save & validate leadFNA capture screen
	def executeSubmit
	  	WebView.execute_js("showLoadingMessage()")

		leadFNA = MobiSys::BrowserHelper.convertToObject('LeadFNA', @params['LeadFNA'])

      	leadFNA.agentId = AgentReg.getCurrentAgentReg.agentId
    	leadFNA.dob = getDBDate(leadFNA.dob) if leadFNA.dob.to_s != ""
    	leadFNA.agentSignatureDt = getDBDate(leadFNA.agentSignatureDt) if leadFNA.agentSignatureDt.to_s != ""
    	leadFNA.signatureDt = getDBDate(leadFNA.signatureDt) if leadFNA.signatureDt.to_s != ""
        leadFNA.expiryDt = Date.parse(leadFNA.signatureDt.to_s) >> 6 if leadFNA.signatureDt.to_s != ""

        if leadFNA.agentSignatureCd.to_s != "" && !leadFNA.agentSignatureCd.to_s.start_with?('ZLIBCMP')
            leadFNA.agentSignatureCd = leadFNA.agentSignatureCd.gsub!('data:image/png;base64,','')
            original_signature_decoded = MobiSys::Encryption.decodeContents(leadFNA.agentSignatureCd)
            compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
            leadFNA.agentSignatureCd = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
        end

        if leadFNA.signatureCd.to_s != "" && !leadFNA.signatureCd.to_s.start_with?('ZLIBCMP')
            leadFNA.signatureCd = leadFNA.signatureCd.gsub!('data:image/png;base64,','')
            original_signature_decoded = MobiSys::Encryption.decodeContents(leadFNA.signatureCd)
            compressed_signature = MobiSys::Encryption.zipData(original_signature_decoded)
            leadFNA.signatureCd = 'ZLIBCMP' + MobiSys::Encryption.encodeContents(compressed_signature)
        end

      	lookupkeys = getQuestionKeysArray
	    errorQuestions = []
	    fna_score = 0
        FNAResponse.delete_all(:conditions =>{'fnaId' => leadFNA.fnaId })
	    # save responses, add errors, and calculate fna_score in this loop 
	    key_list = @params.keys.select{|key| key.include? 'FNA_FINANCIAL_NEED'}
	    lookupkeys.each do |key|
	      	if (key.to_s == 'FNA_FINANCIAL_NEED' && key_list.size == 0) || (key.to_s != 'FNA_FINANCIAL_NEED' && @params[key.to_s].nil?) 
	        	errorQuestions << key
	      	else
	        	if key.to_s == 'FNA_FINANCIAL_NEED' && !key_list.empty?
		          	key_list.each do |fna_key|
		            	@fnaResponse = FNAResponse.new(:fnaId => leadFNA.fnaId.to_s, :question => fna_key, :score => @params[fna_key].to_s)
		            	@fnaResponse.persistAll
		          	end
	        	else
	        		@fnaResponse = FNAResponse.new(:fnaId => leadFNA.fnaId.to_s, :question => key, :score => @params[key].to_s)
	        	end
	        	if key.to_s != 'FNA_FINANCIAL_NEED'
	          		@fnaResponse.persistAll
	        	end
	        	fna_score = fna_score + @params[key].to_i
	      	end
	    end

	    leadFNA.fnaStatus = "PENDING"
        leadFNA.fnaScore = fna_score.to_s
      	leadFNA.persistAll

      	errors = Hash.new
      	leadFNA = LeadFNA.loadObject(:first, :conditions => {:object => leadFNA.object})
      	MobiSys::FNAResponseBO.validate(errors, leadFNA, errorQuestions)
      	$total_error['LeadFNA'] = errors
      	if errors.empty?
      		leadFNA.outputInsurancePlanSuited, leadFNA.outputRiders, leadFNA.outputInsuranceProtectionAmount, leadFNA.outputPaymentPeriod = getOutputDetails(leadFNA.fnaId)
	    	leadFNA.fnaStatus = ""
      		leadFNA.persistAll
      	end

	    redirect :action => :showFNA, :id => leadFNA.object.to_s, :query => {:submit => ''}
	end
    ##################################################################################################


    #Method to validate & save leadFNA and redirect to capture RPQ screen
	def addRPQ
        WebView.execute_js("showLoadingMessage()")

	    leadFNA = MobiSys::BrowserHelper.convertToObject('LeadFNA', @params['LeadFNA'])
  		leadFNA.dob = getDBDate(leadFNA.dob) if leadFNA.dob.to_s != ""
    	leadFNA.agentSignatureDt = getDBDate(leadFNA.agentSignatureDt) if leadFNA.agentSignatureDt.to_s != ""
    	leadFNA.signatureDt = getDBDate(leadFNA.signatureDt) if leadFNA.signatureDt.to_s != ""
        leadFNA.expiryDt = Date.parse(leadFNA.signatureDt.to_s) >> 6 if leadFNA.signatureDt.to_s != ""
  		leadFNA.persistAll
  		
  		errors = Hash.new
      	leadFNA = LeadFNA.loadObject(:first, :conditions => {:object => leadFNA.object})
      	MobiSys::FNAResponseBO.validate(errors, leadFNA, errorQuestions)
      	$total_error['LeadFNA'] = errors

  		if !errors.empty?
	    	redirect :action => :showFNA, :id => leadFNA.object.to_s, :query => {:submit => ''}
	    else
			redirect :action => :newRPQ, :controller => :LeadRPQ, :id => leadFNA.object
	    end
	end
    ##################################################################################################


    #Method to save leadFNA and redirect to graphical FNA screen
	def addGraphicalFNA
        WebView.execute_js("showLoadingMessage()")

	    leadFNA = MobiSys::BrowserHelper.convertToObject('LeadFNA', @params['LeadFNA'])
  		leadFNA.dob = getDBDate(leadFNA.dob) if leadFNA.dob.to_s != ""
    	leadFNA.agentSignatureDt = getDBDate(leadFNA.agentSignatureDt) if leadFNA.agentSignatureDt.to_s != ""
    	leadFNA.signatureDt = getDBDate(leadFNA.signatureDt) if leadFNA.signatureDt.to_s != ""
        leadFNA.expiryDt = Date.parse(leadFNA.signatureDt.to_s) >> 6 if leadFNA.signatureDt.to_s != ""
  		leadFNA.persistAll

  		redirect :controller => :FNADisplay, :action => :index_new, :id => leadFNA.object
	end
    ##################################################################################################
end

begin 
    require 'LeadFNA/lead_f_n_a_controller_company'
rescue LoadError => e
    puts 'lead_f_n_a_controller_company not included'
end
 	
require 'CommonModules/mobisysuihelper_jazz'

class LeadRPQController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    def requiredTabs
        requiredTabs = Hash.new
        tabIconsArr = Array.new
        requiredTabs['tab_basic'] = "tab_basic"
        tabIconsArr.push("icon-owner")
        requiredTabs['tab_questionnaire'] = "tab_questionnaire"
        tabIconsArr.push("icon-questionnaire")
        if @leadRPQ.statusCd == "COMPLETE" || @leadRPQ.visitedTabs.to_s.include?('tab_signature')
            requiredTabs['tab_signature'] = "tab_signature"
            tabIconsArr.push("icon-declaration")
        end
        tabName = requiredTabs.keys.join(",")
        tabLabel = requiredTabs.values.join(",")
        tabIcons = tabIconsArr.join(",")
        return tabName,tabLabel, tabIcons
    end

 	def requiredQuickLinks(leadRPQ)
        quickLinks = Hash.new
        if @str.to_s == ""
        	quickLinks['CAPTUREILLUSTRATION'] = url_for :controller => :Quotation, :action=> :newCaptureIllustration, :query => { :rpqId => leadRPQ.rpqId, :insuranceTypeCd => 'LIFE', :selectedProductId => @selectedProductId }
        else
        	quickLinks['CAPTUREILLUSTRATION'] = url_for :controller => :Quotation, :action=> :newCaptureIllustration, :query => { :fnaId => @str }
        end
       

        quickLinkLabels = quickLinks.keys.join(",")
        quickLinkActions = quickLinks.values.join(",")

        return quickLinkLabels,quickLinkActions
    end


     #Method to display existing RPQ
	def showRPQ
    	id = @params['id'][1..-1].chop
        @str = @params['str'].to_s
        @selectedProductId = @params['selectedProductId'].to_s

    	@leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:object => id.to_s})
    	@saved_response = RPQResponse.loadObject(:all, :conditions => { :rpqId => @leadRPQ.rpqId.to_s },:loadChild => 'false')
	    @total_score = @saved_response.inject(0){|sum,x| sum + x.score }
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
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@leadRPQ.guid,@leadRPQ.visitedTabs)
        @visitedTabs = @leadRPQ.visitedTabs
        @tabName, @tabLabel, @tabIcons = requiredTabs
        @quickLinkLabels, @quickLinkActions = requiredQuickLinks(@leadRPQ)
    	render :action => :captureRPQ_Jazz, :layout => :jazzLayout
  	end
    ##################################################################################################
  

  	#Method to create new RPQ using existing data from LeadFNA
  	def newRPQ
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
        @tabName, @tabLabel, @tabIcons = requiredTabs
        @quickLinkLabels, @quickLinkActions = requiredQuickLinks(@leadRPQ)
	    render :action => :captureRPQ_Jazz, :layout => :jazzLayout 
  	end
    ##################################################################################################
  

  	#Method to save & validate leadRPQ capture screen
	def executeSubmit
        @str = @params['str'].to_s
        @selectedProductId = @params['selectedProductId'].to_s
        if @params.has_key?('mode') && @params['mode'] == "FETCH"
            if LeadRPQ.find(:first,:conditions=>{:object=>@params['formData']['LeadRPQ']['object']})
                redirect :action => :showRPQ, :query => {"sym_current_Tab" => @params['sym_current_Tab']}, :id => @params['formData']['LeadRPQ']['object']
            else
                redirect :action => :newRPQ
            end
        else
    		leadRPQ = MobiSys::BrowserHelper.convertToObjectWithMerge('LeadRPQ', @params['LeadRPQ'])

            if @params.has_key?('currentTab') && @params['currentTab'] == "tab_basic"
              	leadRPQ.agentId = AgentReg.getCurrentAgentReg.agentId
            	leadRPQ.dob = getDBDate(leadRPQ.dob) if leadRPQ.dob.to_s != ""
            elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_questionnaire"
                lookupkeys = MobiSys::RPQResponseBO::QUESTION_SEQUENCE
                errorQuestions = []
                rpq_score = 0

                # save responses, add errors, and calculate rpq_score in this loop
                lookupkeys.each_with_index do |key, kindex|
                    if @params[key.to_s].nil?
                        errorQuestions << key
                    else 
                        #Update Existing Response if it Exists
                        if(@params['RPQResponse'][kindex]['object'] != "")
                            leadRPQ.RPQResponseList.each{|rpqresponse|
                                if rpqresponse.object.to_s == @params['RPQResponse'][kindex]['object'].to_s
                                    rpqresponse.score = @params[rpqresponse.question.to_s].to_s
                                end
                            }
                        else
                            rpqResponse = RPQResponse.new(:parentKey => leadRPQ.object.to_s, :rpqId => leadRPQ.rpqId.to_s, :question => key.to_s, :score => @params[key.to_s].to_s)
                            #Remove Persist All and Add RPQ Response as Lead RPQ Child
                            leadRPQ.addRPQResponse(rpqResponse)
                        end
                        rpq_score = rpq_score + @params[key].to_i
                    end
                end
                if !errorQuestions.empty? && (errorQuestions.any? {|k| k.include? 'RPQ' } == true)
                    rpq_score = 0
                end
                
                leadRPQ.rpqScore = rpq_score.to_s
            elsif @params.has_key?('currentTab') && @params['currentTab'] == "tab_signature"
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
            end
            unless leadRPQ.visitedTabs.to_s.include?(@params['currentTab'])
                leadRPQ.visitedTabs = leadRPQ.visitedTabs.to_s + "," + @params['currentTab']
            end
            leadRPQ.statusCd = "PENDING"
          	leadRPQ.persistAll

          	errors = Hash.new
          	dbLeadRPQ = LeadRPQ.loadObject(:first, :conditions => {:object => leadRPQ.object})
            MobiSys::CommonUtil.clearTaskExceptionList(dbLeadRPQ.guid)
          	MobiSys::RPQResponseBO.validate(errors, dbLeadRPQ, errorQuestions)
            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(dbLeadRPQ.guid,dbLeadRPQ.visitedTabs)
          	# $total_error['LeadRPQ'] = errors
          	if @errors.empty? && @incompleteTabs.empty? && dbLeadRPQ.visitedTabs.to_s.include?('tab_questionnaire') && !dbLeadRPQ.visitedTabs.to_s.include?('tab_signature')
    	    	dbLeadRPQ.statusCd = "COMPLETE"
          		dbLeadRPQ.persistAll
            elsif @errors.empty? && @incompleteTabs.empty? && dbLeadRPQ.visitedTabs.to_s.include?('tab_signature')
                dbLeadRPQ.statusCd = "SIGNED"
                dbLeadRPQ.persistAll
          	end

            if @params['currentTab'] == 'tab_questionnaire' && @params['sym_current_Tab'] == 'tab_questionnaire' && @errors.empty?
                @params['sym_current_Tab'] = 'tab_signature'
            end

            redirect :action => :showRPQ, :id => dbLeadRPQ.object.to_s, :query => {:submit => '', :str => @str , :selectedProductId=> @selectedProductId, "sym_current_Tab" => @params['sym_current_Tab']}
        end
	end
    ##################################################################################################

end
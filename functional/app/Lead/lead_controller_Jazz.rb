require 'CommonModules/mobisysuihelper_jazz'
require 'TrackLead/track_lead_b_o'

class LeadController < Rho::RhoController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    def requiredTabs
        requiredTabs = Hash.new
        tabIconsArr = Array.new
        requiredTabs['tab_basic'] = "tab_basic"
        tabIconsArr.push("icon-owner")
        requiredTabs['tab_contact'] = "tab_contact"
        tabIconsArr.push("icon-coverage")
        requiredTabs['tab_activity'] = "tab_activity"
        tabIconsArr.push("icon-rider-details")
        tabName = requiredTabs.keys.join(",")
        tabLabel = requiredTabs.values.join(",")
        tabIcons = tabIconsArr.join(",")
        return tabName,tabLabel, tabIcons
    end

    def search
        render :action => :searchLead_Jazz, :layout => :jazzLayout
    end

    def newLead
        @tabName, @tabLabel, @tabIcons = requiredTabs
        @lead = Lead.new
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@lead)
        render :action => :captureLead_Jazz, :layout => :jazzLayout
    end

    def showLead
        id = @params['id'][1..-1].chop
        @tabName, @tabLabel, @tabIcons = requiredTabs
        @lead = Lead.loadObject(:first, :conditions => {:object => id })
        preShowLead
        @lead.dob = getScreenDate(@lead.dob) if @lead.dob.to_s != ""

        @leadActivityCount = 0
        @leadActivity = Array.new
        @lead.LeadActivityList.each do |leadActivity|
            leadActivity.activityDt = getScreenDateTime(leadActivity.activityDt) if leadActivity.activityDt.to_s != ""
            leadActivity.closureDate = getScreenDateTime(leadActivity.closureDate) if leadActivity.closureDate.to_s != ""
            @leadActivity << leadActivity
            @leadActivityCount += 1
        end
        @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@lead.guid,@lead.visitedTabs)
        @visitedTabs = @lead.visitedTabs.to_s
        @quickLinkLabels,@quickLinkActions = requiredQuickLinks(@lead)
        postShowLead
        render :action => :captureLead_Jazz, :layout => :jazzLayout
    end

    def addActivity(leadActivity=nil, lead=nil, leadObjectName=nil, leadActivityCount=nil)
        if leadActivity != nil && lead != nil && leadObjectName != nil && leadActivityCount
            @leadActivity = leadActivity
            @lead = lead
            @leadActivityCount = leadActivityCount +1
        else
            leadObject = @params['leadObject']
            @leadActivityCount = @params['leadActivityCount'].to_i + 1
            @lead = Lead.new
            @lead.object = leadObject
            @leadActivity = LeadActivity.new
            @lead.addLeadActivity(@leadActivity)
        end
        html = ""
        html << render(:partial => 'addLeadActivity_Jazz')
        return html
    end

    def removeLeadActivity
        leadActivity = LeadActivity.loadObject(:first, :conditions=>{{:name=>'object'}=>@params['leadActivityObject']})
        if leadActivity
            if System::get_property('platform') == 'APPLE' || System::get_property('platform') == 'ANDROID'
                begin 
                    if leadActivity.calendarId.to_s != ""
                        MobiSys::Calendar.delete(leadActivity.calendarId)
                    end
                rescue MobiSys::CalendarAccessError => error 
                    puts "Calendar Access Not Available"
                end
            end
            leadActivity.destroy
        end
    end

    def executeSubmit
        resetObjectMapping
        if @params.has_key?('mode') && @params['mode'] == "FETCH"
            if Lead.find(:first,:conditions=>{:object=>@params['formData']['Lead']['object']})
                redirect :action => :showLead, :query => {"sym_current_Tab" => @params['sym_current_Tab']}, :id => @params['formData']['Lead']['object']
            else
                redirect :action => :newLead
            end
        else
            lead = MobiSys::BrowserHelper.convertToObject('Lead', @params['Lead'])
            # lead.leadId = lead.uniqueKey
            lead.leadId = SequenceNoGenerator.getNextNumber('LEAD') if lead.leadId.to_s == ""
            unless lead.visitedTabs.to_s.include?(@params['currentTab'])
                lead.visitedTabs = lead.visitedTabs.to_s + "," + @params['currentTab']
            end
            lead.LeadActivityList.each do |leadActivity|
                leadActivity.activityDt = getDBDateTime(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
                leadActivity.closureDate = getDBDateTime(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""
            end
            lead.statusCd = "PENDING"
            preSave(@params,lead)
            lead.persistAll
            postSave(@params,lead)
            newlead = Lead.loadObject(:first,:conditions=>{:object=> lead.object.to_s})
            errors = Hash.new
            MobiSys::CommonUtil.clearTaskExceptionList(newlead.guid)
            MobiSys::LeadBO.validate_Jazz(newlead, errors)
            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(newlead.guid,newlead.visitedTabs)
            @visitedTabs = newlead.visitedTabs.to_s
            if @errors.empty? && @incompleteTabs.empty?
               updateCalendar(newlead)
               updateContacts(newlead)
               newlead.statusCd = "COMPLETE"    #should status and persistAll lines be before update lines
               newlead.persistAll
            end
            MobiSys::TrackLeadBO.updateTrackLead(newlead)
           redirect :action => :showLead, :id => newlead.object.to_s, :query => {"sym_current_Tab" => @params['sym_current_Tab'],:submit => ''}
        end
    end

    def activityList
        @searchResultList = {}

        if @params['deleteCheck'].to_s != ""
            @params['deleteCheck'].each do |leadActivityId|
                lead_activity = LeadActivity.loadObject( :first, :conditions => { :object => leadActivityId} )
                MobiSys::CommonUtil.clearTaskExceptionList((lead_activity.parentKey.to_s.sub! '.','_'))
                lead_activity.delete if lead_activity
            end
        end

        @currentTab = @params['currentTab'] # [DAILY, WEEKLY, MONTHLY]
        @currentTab = 'DAILY' unless @currentTab

        @index = @params['index']
        @index = 0 unless @index

        @index = @index.to_i
        @today = Date.parse(Time.now.to_s)

        if @currentTab == 'DAILY'
            @fromDate,@toDate = @today.next_day(@index),@today.next_day(@index)
        elsif @currentTab == 'WEEKLY'
            @weekindex = @index * 7
            @fromDate = @today.next_day(@weekindex.to_i)

            # start of week and end of week
            @fromDate = @fromDate - @fromDate.wday
            @toDate = @fromDate + 6  
        elsif @currentTab == 'MONTHLY'
            @fromDate = @today.next_month(@index)
            @fromDate = @fromDate - (@fromDate.mday - 1)
            @toDate = Date.new(@fromDate.year, @fromDate.month, -1)
        end

        @mesg = MobiSys::CommonUtil.replacePlaceHolders(getLabelValue('leadActivityMessage'),[@currentTab,getScreenDate(@fromDate.to_s),getScreenDate(@toDate.to_s)])
        unless @params.empty?       # no need for this check as there are always going to be params
	        
	        mainSearchField = @params['mainSearchField'].to_s.strip.downcase if @params['mainSearchField'] != nil
			leadName = @params['leadName'].to_s.strip.downcase if @params['leadName'] != nil
			activityType = @params['activityType'].to_s.strip if @params['activityType'] != nil
			activityDt = @params['activityDt'].to_s if @params['activityDt'] != nil
			closureDate = @params['closureDate'].to_s if @params['closureDate'] != nil

	        leadList = Lead.loadObject(:all)

	        leadList.each do |lead|
	            leadtitle = getLabelValue(lead.title.to_s).to_s.downcase
				leadfirstname = lead.firstname.to_s.downcase
				leadlastname = lead.lastname.to_s.downcase
	            name_combos = [leadfirstname,leadlastname,leadfirstname + " " + leadlastname,leadtitle + leadfirstname,leadtitle + leadfirstname + " " + leadlastname]

	            leadFullName = (getLabelValue(lead.title.to_s)+" "+lead.firstname.to_s+" "+lead.lastname.to_s).strip
     

	            lead.LeadActivityList.each do |leadActivity|    
                    if mainSearchField != ""
                        activitysearchflag = false
                        name_combos.each do|name|
                            if (name.include? mainSearchField) 
                                activitysearchflag = true
                                 break
                            end
                        end  
                        if (leadActivity.type.to_s.downcase.include? mainSearchField.to_s.downcase)|| (mainSearchField.to_s) == getScreenDate(leadActivity.activityDt.to_s) || (mainSearchField.to_s) == getScreenDate(leadActivity.closureDate.to_s)
                            activitysearchflag = true
                        end
                        if activitysearchflag == true
                            @searchResultList[leadActivity.object] = [leadFullName,getLabelValue(leadActivity.type),getScreenDate(leadActivity.activityDt.to_s),getScreenDate(leadActivity.closureDate.to_s)]
                        end
                    else
                        if leadName != ""
                            name_combos.each do |name|
                                if (name.include? leadName)
                                @searchResultList[leadActivity.object] = [leadFullName,getLabelValue(leadActivity.type),getScreenDate(leadActivity.activityDt.to_s),getScreenDate(leadActivity.closureDate.to_s)]
                                end
                            end
                        else 
	                        if activityType == "" || (leadActivity.type.to_s.downcase.include? activityType.to_s.downcase)
	                    	    if activityDt == "" || (activityDt.to_s) == getScreenDate(leadActivity.activityDt.to_s)
	                    		    if closureDate == "" || (closureDate.to_s)== getScreenDate(leadActivity.closureDate.to_s)
                                        dbactivityDt = nil
                                        dbclosureDt = nil
	                    			    dbactivityDt = Date.parse(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
									    dbclosureDt = Date.parse(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""

	                    			    if dbactivityDt && dbclosureDt
					                       next if (dbactivityDt < @fromDate && dbclosureDt < @fromDate) || (dbactivityDt > @toDate && dbclosureDt > @toDate)
					                   elsif dbactivityDt
                                            next if (dbactivityDt < @fromDate || dbactivityDt > @toDate)
					                   elsif dbclosureDt
                                            next if(dbclosureDt < @fromDate || dbclosureDt > @toDate)
					                   end
	                    			    @searchResultList[leadActivity.object] = [leadFullName,getLabelValue(leadActivity.type),getScreenDate(leadActivity.activityDt.to_s),getScreenDate(leadActivity.closureDate.to_s)]
                                    end
	                    		end
	                    	end
	                    end
	                end
	            end
	        end
	    end
        render :action => :activityList_Jazz, :layout => :jazzLayout
    end

    def showLeadActivity
    	activityObject = @params['id'][1..-1].chop
    	lead_activity = LeadActivity.find(:first,:conditions => {:object => activityObject})
    	lead = Lead.find(:first,:condition => {:object => lead_activity.parentKey})
    	redirect :action => :showLead, :id => lead_activity.parentKey.to_s, :query => {"sym_current_Tab" => 'tab_activity',:submit => ''}
    end

    def addFNA
        if @params.has_key?("action")
            if @params['id'].include? "{"
                lead_object = @params['id'][1..-1].chop
            else
                lead_object = @params['id']
            end
            lead = Lead.loadObject(:first, :conditions => {:object => lead_object})

            if @params["action"]=="addFNA"
                lead.persist
                if @params.has_key?("subaction")
                    redirect :action => :newFNA, :controller => :LeadFNA, :id => lead.object, :query => {:graphicalFNA => ''} if @params["subaction"]=="graphicalFNA"
                else
                    redirect :action => :newFNA, :controller => :FNARequest, :id => lead.object
                end
            end
        end
    end

    def profile
        id = @params["id"][1..-1].chop
        @lead = Lead.loadObject(:first, :conditions => {:object => id.to_s},:loadChild => false)
        @lead.dob = getScreenDate(@lead.dob) if @lead.dob.to_s != ""
        render :action => :profilePage_Jazz, :layout => :jazzLayout
    end

	def closeLead
		lead = Lead.loadObject(:first,:conditions=>{{:name=>'object'} =>@params['lead_object'].to_s})
        if lead
            lead.statusCd = "CLOSED"
            lead.persistAll
            MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
            MobiSys::TrackLeadBO.updateTrackLead(lead)
            if @params['source'] == "search"
                redirect :action => :search
            else
                WebView.navigate(url_for :action => :showLead, :id => lead.object.to_s, :query => {:submit => ''})
            end
        else
            redirect :action => :search
        end
	end

    def addQuotation
        if @params['id'].include? "{"
            lead_object = @params['id'][1..-1].chop
        else 
            lead_object = @params['id']
        end
        lead = Lead.loadObject(:first, :conditions => {:object => lead_object.to_s})
            WebView.navigate( url_for :action => :getInsuranceType, :controller => :Menu, :query => {:leadid => lead.object.to_s,:module=>'SALESILLUSTRATION'})
    end

    def addGFNA
       if @params['id'].include? "{"
            lead_object = @params['id'][1..-1].chop
        else 
            lead_object = @params['id']
        end
        lead = Lead.loadObject(:first, :conditions => {:object => lead_object})
        errors = Hash.new
        $lead_obj = lead_object
        MobiSys::LeadBO.validate_Jazz(lead, errors)

        if lead.statusCd.to_s == "CLOSED" || lead.statusCd.to_s == "PENDING"
            Rho::WebView.executeJavascript("raiseAlert(getLabelValue('ERR_CLOSE_LEAD','GFNA'),[],locale)");

        elsif (!errors.empty?)
            Alert.show_popup({
                    :message => getLabelValue('Please enter all mandatory details'),
                    :title => '', 
                    :icon => :info,
                    :buttons => ["OK"] 
                })
            redirect :action => :showLead, :id => lead.object.to_s, :query => {"sym_current_Tab" => @params['sym_current_Tab'],:submit => ''}
        else
            WebView.navigate ('/public/dream-catcher/index.html')
        end
        redirect :action => :showLead, :id => lead.object.to_s, :query => {"sym_current_Tab" => @params['sym_current_Tab'],:submit => ''}
    end

    def requiredQuickLinks(lead)
        quickLinks = Hash.new

        quickLinks['FNA'] =  url_for :controller => :Lead, :action=> :addFNA, :query => {:id => lead.object , :action => "addFNA"}
        quickLinks['GFNA'] = url_for :controller => :Lead, :action=> :addGFNA, :query => {:id => lead.object}
        quickLinks['Quotation'] = url_for :controller => :Lead ,:action => :addQuotation , :query =>{:id => lead.object}
        quickLinks['CLOSELEAD'] = '#'

        quickLinkLabels = quickLinks.keys.join(",")
        quickLinkActions = quickLinks.values.join(",")

        return quickLinkLabels,quickLinkActions
    end

    #Method to get lookups for City & State based on Industry lookup and Pincode value
    def getPincodeCityStateCountryLookups(lead = nil)
  
        countryCd = @params['countryCd']
        pinCode = @params['pinCode']
        @option = @params['option']

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

            if @option == "district"
                @selectLookup = @districtLookUps
            else
                 @selectLookup = @cityLookUps
            end
            render :action => :filterLookupData, :layout => false
    end

    def deleteLead
        if @params['deleteCheck'].to_s != ""
            @params['deleteCheck'].each do |selectedleadObj|
                lead = Lead.loadObject( :first, :conditions => { :object => selectedleadObj } )
                MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
                lead.delete if lead
            end
        end
        WebView.navigate("#{url_for :controller => :Lead, :action => :search}")
    end
    
    def preShowLead
        # Do nothing this method is to be implemented in company layer        
    end

    def postShowLead
        # Do nothing this method is to be implemented in company layer        
    end

    def preSave(params,lead)
        # Do nothing this method is to be implemented in company layer        
    end

    def postSave(params,lead)
        # Do nothing this method is to be implemented in company layer        
    end
end
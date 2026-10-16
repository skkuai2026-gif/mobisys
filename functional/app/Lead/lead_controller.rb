require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/mobisyscontacts'
require 'CommonModules/mobisyscalendar'
require 'CommonModules/commonutil'
require 'Lead/lead_b_o'
require 'rho/rhoevent.rb'
require 'date'

class LeadController < Rho::RhoController
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


	#Method to get lookups for Nature of Duty & Occupation based on Industry lookup
	def getIndustryNatureofdutyLookups(option = nil, lead = nil)
		if lead
			industryCd = lead.industryCd
			@option = option
		else
			industryCd = @params['industryCd']
			@option = @params['option']
		end

		
		case @option
		when "all"
			industries = Array.new
			natureOfDutyLookups = Array.new

			nodLookups =  IndustryOccupation.loadObject(:all)
			nodLookups.each do |nod|
				nodLookup = Lookupvalue.new
				nodLookup.cd = nod.industryCd.to_s
				nodLookup.desc = nod.industryCd.to_s
				industries.push(nodLookup)
			end   
			industries.uniq!{|industry| industry.desc}

			if industryCd!="" and industryCd!="null"
				natureOfDuty = IndustryOccupation.loadObject(
					:all, 
					:conditions => {
						{ :name => 'industryCd' } => industryCd
					}
				) 
			else
				natureOfDuty = IndustryOccupation.loadObject(:all)
			end
			natureOfDuty.each do |place|
				natureOfDutyLookup = Lookupvalue.new
				natureOfDutyLookup.cd = place.natureOfDutyCd.to_s
				natureOfDutyLookup.desc = place.natureOfDutyCd.to_s
				natureOfDutyLookups.push(natureOfDutyLookup)
			end
			natureOfDutyLookups.uniq!{|place| place.desc}

			return industries, natureOfDutyLookups
		when "industries"
			@industries = Array.new

			nodLookups =  IndustryOccupation.loadObject(:all)
			nodLookups.each do |nod|
				nodLookup = Lookupvalue.new
				nodLookup.cd = nod.industryCd.to_s
				nodLookup.desc = nod.industryCd.to_s
				@industries.push(nodLookup)
			end   
			@industries.uniq!{|industry| industry.desc}

			html = ""
			html << render(:partial => 'getDynamicLookups')
			return html
		when "natureofduty"
			@natureOfDutyLookups = Array.new

			if industryCd!="" and industryCd!="null"
				natureOfDuty = IndustryOccupation.loadObject(
					:all, 
					:conditions => {
						{ :name => 'industryCd' } => industryCd
					}
				) 
			else
				natureOfDuty = IndustryOccupation.loadObject(:all)
			end
			natureOfDuty.each do |place|
				natureOfDutyLookup = Lookupvalue.new
				natureOfDutyLookup.cd = place.natureOfDutyCd.to_s
				natureOfDutyLookup.desc = place.natureOfDutyCd.to_s
				@natureOfDutyLookups.push(natureOfDutyLookup)
			end
			@natureOfDutyLookups.uniq!{|place| place.desc}
			
			html = ""
			html << render(:partial => 'getDynamicLookups')
			return html
		end
	end
	##################################################################################################


	#Method to get party age based on entered birth date
	def getAge
		@birthDt = @params["birthDt"]
		if @birthDt != nil
			dateParts = @birthDt.split("/")
			@age = MobiSys::ProductUtil.calculateAge(Time.new(dateParts[2].to_i, dateParts[1].to_i, dateParts[0].to_i), MobiSys::ProductUtil::LASTBIRTHDAY, Time.now)
		end
		
		html = ""
		html << render(:partial => 'age')
		return html
	end
	##################################################################################################


	#Method to get party birth date based on entered age
	def getBirthDt
		@age = @params["age"]
		if @age != nil
			@birthDt = MobiSys::ProductUtil.calculateDOB(@age, Time.now)
		end

		html = ""
		html << render(:partial => 'birthDt')
		return html
	end
	##################################################################################################


	#Method to add lead activities to mobile device calendar
	def updateCalendar(lead)
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
					begin 
						if leadActivity.calendarId.to_s == ""
							calendar = MobiSys::Calendar.create(event)
							leadActivity.calendarId = calendar["id"]
						else
							calendar = MobiSys::Calendar.update(leadActivity.calendarId, event)
						end
					rescue MobiSys::CalendarAccessError => error 
						puts "Calendar Access Not Available"
					end
				end
			end
			lead.persistAll
		end
	end
	##################################################################################################
  


	#Method to add lead to mobile device address book
	def updateContacts(lead)
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
	##################################################################################################


	#Method to render the search page for lead
	def searchLead
		WebView.execute_js("showLoadingMessage()")

		if @params['deleteCheck'].to_s != ""
			@params['deleteCheck'].each do |selectedLeadId |
				lead = Lead.loadObject( :first, :conditions => { :object => selectedLeadId } )
				lead.delete if lead
			end
		end

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
			leadName = @params['leadName'].to_s
			leadMobile = @params['leadMobile'].to_s
			leadEmail = @params['leadEmail'].to_s
			leadStatus = @params['leadStatus'].to_s

			leadList = Lead.loadObject(
				:all,
				:per_page => 200,
				:order => 'leadId', 
				:orderdir => 'DESC',
				:select => ['title', 'firstname', 'lastname', 'mobileNumber', 'object', 'emailAddress', 'statusCd']
			)

			leadList.each do |lead|
				validLead = true

				leadFullName = getLabelValue(lead.title.to_s) + " " + lead.firstname.to_s + " " + lead.lastname.to_s

				if leadName != ""
					validLead = false if leadFullName.index(leadName.to_s) == nil
				end
				
				if leadMobile != "" && validLead
					validLead = false if lead.mobileNumber.to_s.index(leadMobile.to_s) == nil
				end
				
				if leadEmail != "" && validLead
					validLead = false if lead.emailAddress.to_s.index(leadEmail.to_s) == nil
				end
				
				if leadStatus != "" && validLead
					validLead = false if lead.statusCd.to_s.index(leadStatus.to_s) == nil
				end
				
				if validLead
					leadHash = Hash.new
					leadHash[:object] = lead.object
					if leadFullName.to_s.strip != ""
						leadHash[:leadName] = leadFullName
					else
						leadHash[:leadName] = "-"
					end
					if lead.mobileNumber.to_s != ""
						leadHash[:leadMobile] = lead.mobileNumber
					else
						leadHash[:leadMobile] = "-"
					end
					if lead.emailAddress.to_s != ""
						leadHash[:leadEmail] = lead.emailAddress
					else
						leadHash[:leadEmail] = "-"
					end
					if lead.statusCd.to_s != ""
						leadHash[:leadStatus] = getLabelValue(lead.statusCd)
					else
						leadHash[:leadStatus] = "-"
					end
					@searchResult.push(leadHash)
				end
			end
		end

		render :action => :searchLead, :layout => :newEAPPLayout
	end
	##################################################################################################


	#Method to render the search page for lead activity
	def activityList
		WebView.execute_js("showLoadingMessage()")
		@searchResult = Array.new

		@type = @params['type'] # [DAILY, WEEKLY, MONTHLY]
		if @type == nil
			@type = 'DAILY'
		end

		@index = @params['index']
		if @index == nil
			@index = '0'
		end

		@index = @index.to_i
		@header = getLabelValue(@type) + ' ' + getLabelValue('ACTIVITYLIST')
		@today = Date.parse(Time.now.to_s)

		if @type == 'DAILY'
			if @index < 0
				@fromDate = @today.prev_day(@index.to_i * - 1)
			elsif @index > 0
				@fromDate = @today.next_day(@index.to_i)
			else
				@fromDate = @today
			end
			@toDate = @fromDate  
		elsif @type == 'WEEKLY'
			@weekindex = @index * 7

			if @index < 0
				@fromDate = @today.prev_day(@weekindex.to_i * - 1)
			elsif @index > 0
				@fromDate = @today.next_day(@weekindex.to_i)
			else
				@fromDate = @today
			end

			# start of week and end of week
			@fromDate = @fromDate - @fromDate.wday
			@toDate = @fromDate + 6  
		elsif @type == 'MONTHLY'
			if @index < 0
			   @fromDate = @today.prev_month(@index.to_i * - 1)
		   	elsif @index > 0
			   @fromDate = @today.next_month(@index.to_i)
		   	else
			   @fromDate = @today
		   	end
		   	@fromDate = @fromDate - (@fromDate.mday - 1)
		   	@toDate = Date.new(@fromDate.year, @fromDate.month, -1)
	   	end

	   	leadList = Lead.loadObject(:all)

	   	leadList.each do |lead|
	   		validLead = true
	   		leadFullName = getLabelValue(lead.title.to_s) + " " + lead.firstname.to_s + " " + lead.lastname.to_s

	   		validLead = false if lead.statusCd == "CLOSED"

	   		lead.LeadActivityList.each do |leadActivity|
	   			if !@params.empty?
	   				leadName = @params['leadName'].to_s
	   				activityType = @params['activityType'].to_s
	   				activityDt = @params['activityDt'].to_s
	   				closureDate = @params['closureDate'].to_s

	   				if leadName != ""
	   					validLead = false if leadFullName.index(leadName.to_s) == nil
	   				end

	   				if activityType != ""
	   					validLead = false if leadActivity.type.to_s.index(activityType.to_s) == nil
	   				end

	   				if activityDt != ""
	   					validLead = false if leadActivity.activityDt.to_s.index(activityDt.to_s) == nil
	   				end

	   				if closureDate != ""
	   					validLead = false if leadActivity.closureDate.to_s.index(closureDate.to_s) == nil
	   				end
	   			end

	   			validActivity = true
	   			activityDt = Date.parse(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
	   			closureDate = Date.parse(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""

	   			if validLead && leadActivity.activityDt.to_s != "" && leadActivity.closureDate.to_s != ""
	   				if (activityDt > @toDate) || (closureDate < @fromDate)
	   					validActivity = false
	   				end
	   			elsif validLead && leadActivity.activityDt.to_s != ""
	   				if (activityDt > @toDate)
	   					validActivity = false
	   				end
	   			elsif validLead && leadActivity.closureDate.to_s != ""
	   				if (closureDate < @fromDate)
	   					validActivity = false
	   				end
	   			end

	   			if validLead && validActivity
	   				activityHash = Hash.new
	   				activityHash[:leadObject] = lead.object
	   				activityHash[:activityObject] = leadActivity.object
	   				if leadFullName.to_s != ""
	   					activityHash[:leadName] = leadFullName
	   				else
	   					activityHash[:leadName] = "-"
	   				end
	   				if leadActivity.type.to_s != ""
	   					activityHash[:activityType] = getLabelValue(leadActivity.type)
	   				else
	   					activityHash[:activityType] = "-"
	   				end
	   				if leadActivity.activityDt.to_s != ""
	   					activityHash[:activityDt] = getScreenDate(leadActivity.activityDt.to_s)
	   				else
	   					activityHash[:activityDt] = "-"
	   				end
	   				if leadActivity.closureDate.to_s != ""
	   					activityHash[:closureDate] = getScreenDate(leadActivity.closureDate.to_s)
	   				else
	   					activityHash[:closureDate] = "-"
	   				end
	   				@searchResult.push(activityHash)
	   			end
	   		end
	   	end

		render :action => :activityList, :layout => :newEAPPLayout
	end
	##################################################################################################


	#Method to display existing lead
	def showLead
		WebView.execute_js("showLoadingMessage()")
		id = @params['id'][1..-1].chop
		@leadActivityFocus = @params['leadActivity'] if @params['leadActivity']
		$total_error = Hash.new if !@params.has_key?('submit')

		@lead = Lead.loadObject(:first, :conditions => {:object => id })
		@lead.leadCaptureDate = getScreenDate(Time.now.to_s)
		@lead.dob = getScreenDate(@lead.dob) if @lead.dob.to_s != ""

		@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@lead)
		@industries, @natureOfDutyLookups = getIndustryNatureofdutyLookups("all", @lead)

		@leadActivityCount = 0
		@leadActivity_form = ""
		@lead.LeadActivityList.each do |leadActivity|
			@leadActivity_form << addLeadActivity(@lead, leadActivity, @leadActivityCount)
			@leadActivityCount += 1
		end

		render :action => :captureLead, :layout => :newEAPPLayout
	end
	##################################################################################################


	#Method to create new lead
	def newLead
		WebView.execute_js("showLoadingMessage()")
		$total_error = Hash.new

		@lead = Lead.new
		@lead.leadId = @lead.uniqueKey
		@lead.leadCaptureDate = getScreenDate(Time.now.to_s)
		@lead.dob = getScreenDate(@lead.dob) if @lead.dob.to_s != ""
		
		@districtLookUps, @cityLookUps = getPincodeCityStateCountryLookups(@lead)
		@industries, @natureOfDutyLookups = getIndustryNatureofdutyLookups("all", @lead)

		@leadActivityCount = 0
		@leadActivity_form = ""

		render :action => :captureLead, :layout => :newEAPPLayout
	end
	##################################################################################################


	#Method to add Lead Activity
	def addLeadActivity(lead=nil, leadActivity=nil, leadActivityCount=nil)
		if lead != nil && leadActivity != nil && leadActivityCount != nil
			@leadActivityCount = leadActivityCount
			@lead = lead
			@leadActivity = leadActivity
			@leadActivity.activityDt = getScreenDateTime(@leadActivity.activityDt.to_s) if @leadActivity.activityDt.to_s != ""
			@leadActivity.closureDate = getScreenDateTime(@leadActivity.closureDate.to_s) if @leadActivity.closureDate.to_s != ""
		else
			@lead = Lead.new
			@lead.object = @params['leadObject']
			@leadActivityCount = @params['leadActivityCount']
			@leadActivity = LeadActivity.new
			@lead.addLeadActivity(@leadActivity)
			@leadActivity.activityDt = getScreenDateTime(Time.new.strftime("%F 00:00:00 %z"))
			@lead.addActivityFlag = "false"
		end

		maskNumbers(@leadActivity)
		setObjectCount(@lead, @leadActivityCount)
		setObjectMapping(@lead, @lead.class.name) 

		html = ""
		html << "<div class='#{@leadActivityCount}' data-role='collapsible' data-iconpos='right' name='leadActivity' id='leadActivity#{@leadActivityCount}'>"
		html << render(:partial => 'captureLeadActivityHeader')
		html << renderObject(@leadActivity, @lead)
		html << render(:partial => 'captureLeadActivity')
		html << "</div>"
		return html   
	end
	##################################################################################################


	#Method to remove Lead Activity
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
	##################################################################################################


	#Method to save & validate lead capture screen
	#Method to validate & save lead and redirect to capture FNA screen
	#Method to close the lead without validation
	def executeSubmit
		resetObjectMapping
		WebView.execute_js("showLoadingMessage()")
		lead = MobiSys::BrowserHelper.convertToObject('Lead', @params['Lead'])
		lead.dob = getDBDate(lead.dob) if lead.dob.to_s != ""
		lead.statusCd = "PENDING"
		lead.LeadActivityList.each do |leadActivity|
			leadActivity.activityDt = getDBDateTime(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
			leadActivity.closureDate = getDBDateTime(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""
		end
		if @params.has_key?("action")
			if @params["action"]=="closeLead"
				$total_error = Hash.new
				lead.statusCd = "CLOSED"
				lead.persistAll
				redirect :action => :showLead, :id => lead.object.to_s, :query => {:submit => ''}
				
			end
			if @params["action"]=="addFNA"
			  lead.persistAll
			  errors = Hash.new
			  MobiSys::LeadBO.validate(lead, errors)
			  $total_error['Lead'] = errors

				if !errors.empty?
					redirect :action => :showLead, :id => lead.object.to_s, :query => {:submit => ''}
				elsif @params.has_key?("subaction")
					redirect :action => :newFNA, :controller => :LeadFNA, :id => lead.object, :query => {:graphicalFNA => ''} if @params["subaction"]=="graphicalFNA"
				else
					redirect :action => :newFNA, :controller => :LeadFNA, :id => lead.object
				end
			end
		else
			lead.persistAll
			errors = Hash.new
			MobiSys::LeadBO.validate(lead, errors)
			$total_error['Lead'] = errors

			if errors.empty?    
			   updateCalendar(lead)
			   updateContacts(lead)
			   lead.statusCd = ""
			   lead.persistAll
		   end
		   redirect :action => :showLead, :id => lead.object.to_s, :query => {:submit => ''}
		end
	end
	################################################################################################## 

	def setTitleGender
		title = @params['title']
		gender = FieldTargetValueMap.find(
			:first,
			:conditions => {
				{:name => :mappingKey} => 'TitleGender',
				{:name => :drivingValue} => title
			}
			)
		gender = (gender)? gender.targetValue : ""
		render :string => gender
	end


	##################################################################################################   

	def getPosition
		GeoLocation.set_notification url_for(:action => :geo_callback), "", 3
		# WebView.execute_js("updateLocation(19.123988, 72.891455)")
	end
	##################################################################################################  

	def geo_callback
		if @params['known_position'].to_i != 0 && @params['status'] =='ok'
			WebView.execute_js("updateLocation(#{@params['latitude']}, #{@params['longitude']})")
			GeoLocation.turnoff
		else
			WebView.execute_js("locationServiceAlert()")
		end
	end 
	##################################################################################################  

	def getAddress
		latitude = @params['latitude']      
		longitude = @params['longitude'] 

		propertyMap = Hash.new  
		propertyMap['url'] = 'http://maps.googleapis.com/maps/api/geocode/json?latlng='+latitude.to_s+','+longitude.to_s + '&sensor=false'

		responce = Rho::Network.get(propertyMap)  
		if responce['status']=="ok"
			responceBody=responce['body']

			responceBodyParsed = Rho::JSON.parse(responceBody)
			results= responceBodyParsed['results']
			
			#----address line 1----
			premise=''
			street_number=''

			#----address line 2----
			route=''  #prefer GEOMETRIC_CENTER

			#----address line 3----
			neighborhood=''
			sublocality_level_3='' #prefer GEOMETRIC_CENTER

			#----address line 4----
			sublocality_level_2=''
			sublocality_level_1=''

			locality=''  #city/town
			administrative_area_level_1=''  #state/province
			country=''
			postal_code=''

			address=''

			results.each do |value|
				if value['geometry']['location_type']=="ROOFTOP"
					componentsArray=value['address_components']
					componentsArray.each do |valueArray|

						if valueArray['types'][0]=="route"
							route = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="premise"
							premise = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="street_number"
							street_number = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="sublocality_level_3"
							sublocality_level_3 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="sublocality_level_2"
							sublocality_level_2 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="neighborhood"
							neighborhood = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="sublocality_level_1"
							sublocality_level_1 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="locality"
							locality = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="administrative_area_level_1"
							administrative_area_level_1 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="country"
							country = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="postal_code"
							postal_code = valueArray['long_name'] if valueArray['long_name'] !=""
						end

					end

				end

				if value['geometry']['location_type']=="GEOMETRIC_CENTER"
					componentsArray=value['address_components']
					componentsArray.each do |valueArray|

						if valueArray['types'][0]=="route"
							route = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="sublocality_level_3"
							sublocality_level_3 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="locality"
							locality = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="administrative_area_level_1"
							administrative_area_level_1 = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="country"
							country = valueArray['long_name'] if valueArray['long_name'] !=""
						end

						if valueArray['types'][0]=="postal_code"
							postal_code = valueArray['long_name'] if valueArray['long_name'] !=""
						end
					end
				end

				address1 = premise + " " + street_number
				address2 = route
				address3 = sublocality_level_3 + " " + sublocality_level_2 + " " + neighborhood 
				address4 = sublocality_level_1

				address = {
					:address1 => address1,
					:address2 => address2,
					:address3 => address3,
					:address4 => address4,
					:city => locality,
					:state => administrative_area_level_1,
					:country => country,
					:pincode => postal_code
				}
			end

		end

		render :string => address.to_json

	end
	##################################################################################################  
end

begin 
    require 'Lead/lead_controller_Jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'lead_controller_Jazz not included'
end

begin
	require 'Lead/lead_controller_company'
rescue LoadError => e
	puts 'lead_controller_company not included'
end
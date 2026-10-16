require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Lead/lead_service'
require 'Quotation/quotation_service'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'TrackLead/track_lead_b_o'
require 'CommonClasses/LeadIO'

class LeadController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
        # logInfo "~~~in lead rest initialize"
        super(MobiSys::IO::LeadIO.new, "Lead")
    end

    def process
    	lead = @baseIO.baseDO
        lead.leadId = SequenceNoGenerator.getNextNumber('LEAD') if lead.leadId.to_s == ""
        lead.LeadActivityList.each do |leadActivity|
            leadActivity.activityDt = getDBDateTime(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
            leadActivity.closureDate = getDBDateTime(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""
        end
        
        MobiSys::LeadService.saveValidate(lead) if lead.statusCd != "CLOSED"
    end

    def validate(id, parsedData)
        lead = @baseIO.baseDO
        lead.leadId = SequenceNoGenerator.getNextNumber('LEAD') if lead.leadId.to_s == ""
        lead.LeadActivityList.each do |leadActivity|
            leadActivity.activityDt = getDBDateTime(leadActivity.activityDt.to_s) if leadActivity.activityDt.to_s != ""
            leadActivity.closureDate = getDBDateTime(leadActivity.closureDate.to_s) if leadActivity.closureDate.to_s != ""
        end
        
        MobiSys::LeadService.saveValidate(lead,false) if lead.statusCd != "CLOSED"
    end

    def init
    end

    def fetch(id)
        lead = Lead.loadObject(:first, :conditions => {:object => id})
    	@baseIO.baseDO = lead
    end

    def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata=nil)
        #set fields to read only if lead is closed
        if currentTagObject != nil && @baseIO.baseDO != nil && @baseIO.baseDO.statusCd.to_s == "CLOSED"
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
            end
        end
        return metadataHash
    end

    def createQuotation(id, parseData)
        lead = @baseIO.baseDO
        responseHash = {}
        if lead
            quotation = MobiSys::LeadService.newQuotation(lead)
            lead.quotationSeq = quotation.object
        else
            responseHash = {"success" => false,
                            "message" => "Lead  not found."}
        end
        return responseHash
    end

    def computeAge
        parsedData = parseRequestBodyParams
        dob = age = nil
        dob = parsedData['dob'] if parsedData.has_key?("dob")
        age = parsedData['age'] if parsedData.has_key?("age")
        responseHash = {}

        if dob.to_s != ""
            birthDt = getScreenDate(Time.at(dob/1000).to_s) if parsedData['dob'].to_s != ""
            referenceDt = getScreenDate(Time.at(parsedData['referenceDate']/1000).to_s) if parsedData["referenceDate"].to_s != ""
            commencementDt = (referenceDt.to_s != "" ? referenceDt : getScreenDate(Time.new.to_s))
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
            responseHash['data'] = {"age" => age.to_i}
        elsif age.to_s != ""
            referenceDt = Time.at(parsedData['referenceDate']/1000) if parsedData["referenceDate"].to_s != ""
            commencementDt = (referenceDt.to_s != "" ? referenceDt : Time.now)
            dt = MobiSys::ProductUtil.calculateDOB(age, commencementDt)
            d = DateTime.parse(dt.to_s)       
            birthDt = d.strftime('%Q').to_i
            responseHash['data'] = {"dob" => birthDt}
        end
        
        responseHash['success'] = true
        responseHash['message'] = "Successful"
        render :string => responseHash.to_json
    end

    def addLeadActivity
        parsedData = parseRequestBodyParams
        responseHash = {}
        lead = fetch(@params["id"]) if @params.has_key?("id")
        if lead
            @metadataHash = {}
            @lookupHash = {}
            isMetadataRequired = true
            if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
                isMetadataRequired = false
            end
            leadActivity = LeadActivity.new
            lead.addLeadActivity(leadActivity)
            responseHash["data"] = {}
            responseHash["data"]["LeadActivity"] = leadActivity.hashForApi(false)
            responseHash["metadata"] = @metadataHash.merge!(processMetadata(leadActivity))
            responseHash["lookups"] = @lookupHash
            responseHash["success"] = true
            responseHash["message"] = 'Successful'
        else
            responseHash["success"] = false
            responseHash["message"] = "Lead not found"
        end
        render :string => responseHash.to_json
    end

    def deleteLead
        parsedData = parseRequestBodyParams
        responseHash = {}
        if @params.has_key?("id")
            fetch(@params["id"])
            lead = @baseIO.baseDO
            if lead
                MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
                lead.delete
                responseHash = {"success" => true, "message" => "Successful"}
            else
                responseHash["success"] = false
                responseHash["message"] = "Lead not found"
            end
        elsif (parsedData.has_key?("ids") && parsedData['ids'].to_s != "")
                leadIds = parsedData['ids'].split(',')
                if leadIds.size > 0
                    leadIds.each do |id|
                        fetch(id) if id != ""
                        lead = @baseIO.baseDO
                        if lead
                            MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
                            lead.delete
                        end
                    end
                    responseHash = {"success" => true, "message" => "Successful"}
                end
        else
            responseHash["success"] = false
            responseHash["message"] = "Lead Id is required for deletion."
        end

        render :string => responseHash.to_json
    end

    def closeLead(id, parsedData)
        responseHash = {}
        @metadataHash = {}
        @lookupHash = {}
        lead = @baseIO.baseDO
        if lead
            lead.statusCd = "CLOSED"
            MobiSys::CommonUtil.clearTaskExceptionList(lead.guid)
            lead.persistAll
        else
            responseHash["success"] = false
            responseHash["message"] = "Lead not found."
        end
        return responseHash
    end

    def addPartyIdentity
        parsedData = parseRequestBodyParams
        responseHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        partyIdentity = PartyIdentity.new
        partyIdentity.identityTypeCd = parsedData["identityTypeCd"] if parsedData.has_key?("identityTypeCd")
        responseHash["data"] = {}
        responseHash["data"]["PartyIdentity"] = partyIdentity.hashForApi(false).select {|key| !["class","userId"].include? key.to_s }
        if isMetadataRequired
            evaluateContextForObject(partyIdentity)
            responseHash["metadata"] = processMetadata(partyIdentity)
            contextEnd
            responseHash["lookups"] = @lookupHash
        end
        responseHash["success"] = true
        responseHash["message"] = 'Successful'
        render :string => responseHash.to_json
    end

    def addPartyOtherIncome
        parsedData = parseRequestBodyParams
        responseHash = {}
        @lookupHash = {}
        fetch(@params["id"]) if @params.has_key?("id")
        policy = @baseIO.baseDO
        isMetadataRequired = true
        if parsedData.has_key?("FetchData") && parsedData["FetchData"].has_key?("isMetadataRequired") &&parsedData["FetchData"]["isMetadataRequired"].to_s == 'false'
            isMetadataRequired = false
        end
        partyOtherIncome = PartyOtherIncome.new
        responseHash["data"] = {}
        responseHash["data"]["PartyOtherIncome"] = partyOtherIncome.hashForApi(false)
        if isMetadataRequired
            evaluateContextForObject(partyOtherIncome)
            responseHash["metadata"] = processMetadata(partyOtherIncome)
            contextEnd
            responseHash["lookups"] = @lookupHash
        end
        responseHash["success"] = true
        responseHash["message"] = 'Successful'
        render :string => responseHash.to_json
    end

    def populateOCRData
        parsedData = parseRequestBodyParams
        fetch(@params["id"]) if @params.has_key?("id")
        imageContent = parsedData["ImageContent"]
        party = parsedData["Party"]
        responseHash = {}
        persistOcr = false
        @lookupHash = {}
        metadataHash = {}

        leadParty = (party != nil ? MobiSys::BrowserHelper.convertToObject("Party",party,nil,false) : nil)
        offlineFile = OfflineFile.new
        MobiSys::BrowserHelper.setOcrDetails(persistOcr,offlineFile)
        extractedData = MobiSys::BrowserHelper.documentTextDetection(imageContent, false, nil, "processOfflineOCRData")
        extractedData = extractedData.select{|k,v| k.to_s != "rawText"} if extractedData.to_s != ""

        if extractedData.to_s == ""
            responseHash["success"] = false
            responseHash["message"] = "Error in processing OCR data. Please contact system administrator."
        elsif leadParty == nil
            responseHash["success"] = false
            responseHash["message"] = "Party not found."
        else
            partyIdentity = partyAddress = partyContact = nil

            #Convert all Party Children to objects and add them to the Party
            $LeadDataXMLHash['Entity']['children']['LeadParty']['children'].each do |key,value|
                partyChild = nil
                className = value['attributes']['objectClassName']
                methodName = ("add" + className.to_s).to_sym
                if key.to_s.include?("List") and party[key] != nil and party[key].size > 0
                    partyChild = MobiSys::BrowserHelper.convertToObject(className,party[key][0],nil,false)
                    if partyChild != nil
                        leadParty.send(methodName,partyChild) 
                        partyIdentity = partyChild if key.to_s == "IdentityList"
                    end
                elsif !key.to_s.include?("List") and party[key] != nil
                    partyChild = MobiSys::BrowserHelper.convertToObject(className,party[key],nil,false)
                    if partyChild != nil
                        leadParty.send(methodName,partyChild)
                        partyContact = partyChild if key.to_s == "ResidentalContact"
                        partyAddress = partyChild if key.to_s == "ResidentalAddress"
                    end
                end
            end

            if partyIdentity == nil
                partyIdentity = PartyIdentity.new
                leadParty.addPartyIdentity(partyIdentity)
            end
            if partyAddress == nil
                partyAddress = PartyAddress.new(:addressTypeCd => "RESIDENTIAL")
                leadParty.addPartyAddress(partyAddress)
            end
            if partyContact == nil
                partyContact = PartyContact.new(:contactTypeCd => "RESIDENTIAL")
                leadParty.addPartyContact(partyContact)
            end
            #Process the ocr data and add it to the Party
            MobiSys::LeadService.processExtractedImageData(leadParty,extractedData)

            evaluateContextForObject(leadParty)
            metadataHash.merge!(processMetadata(leadParty))

            $LeadDataXMLHash['Entity']['children']['LeadParty']['children'].each do |key,value|
                methodName = "#{key}="
                leadParty.instance_eval { class << self; self end }.send(:attr_accessor, key) unless leadParty.respond_to? methodName
                #Initialize to array by default if object is List as we need to send blank array in response (For eg AdditionalFieldsList)
                childToSend = (key.to_s.include?("List") ? [] : nil)
                childObjectKey = "#{value['attributes']['objectClassName']}List"
                childObjectList = leadParty.send childObjectKey.to_sym
                
                if childObjectList.size > 0
                    if key.to_s.include?("List")
                        childToSend = childObjectList
                    else
                        if childObjectKey.to_s == "PartyContactList"
                            childToSend = childObjectList.select{|contact| contact.contactTypeCd == value['attributes']['contactTypeCd']}[0]
                        elsif childObjectKey.to_s == "PartyAddressList"
                            childToSend = childObjectList.select{|address| address.addressTypeCd == value['attributes']['addressType']}[0]
                        else
                            childToSend = childObjectList[0]
                        end
                    end
                end

                if childToSend != nil
                    leadParty.send(methodName, childToSend.hashForApi(false))
                    if childToSend.is_a?(Array)
                        childToSend.each do |partyChild|
                            evaluateContextForObject(partyChild)
                            metadataHash.merge!(processMetadata(partyChild))
                            contextEnd
                        end
                    else
                        evaluateContextForObject(childToSend)
                        metadataHash.merge!(processMetadata(childToSend))
                        contextEnd
                    end
                end
            end
            contextEnd
            currentChildren = $LeadDataXMLHash['Entity']['children']["LeadParty"].has_key?("children") ? $LeadDataXMLHash['Entity']['children']["LeadParty"]["children"].keys : []

            responseHash["data"] = {}
            responseHash["data"]['Party'] = leadParty.hashForApi(false,currentChildren)
            responseHash["metadata"] = metadataHash
            responseHash["lookups"] = @lookupHash
            responseHash["success"] = true
            responseHash["message"] = "Successful"
        end

        render :string => responseHash.to_json
    end

end

begin 
    require 'Lead/lead_controller_company'
rescue LoadError => e
    puts 'lead_controller_company not included'
end
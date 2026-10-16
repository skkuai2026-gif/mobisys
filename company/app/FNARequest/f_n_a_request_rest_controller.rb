require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'FNARequest/f_n_a_request_service'
require 'Quotation/quotation_service'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'FNARequest/f_n_a_request_b_o'
require 'CommonClasses/FnaIO'
require 'time'
require 'FNARequest/UIGenUtilFNA'

class FNARequestController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
        # logInfo "~~~in lead rest initialize"
        super(MobiSys::IO::FnaIO.new, "FNARequest")
    end

    def process
    	fna = @baseIO.baseDO
        rpq = @baseIO.leadRPQDO
        rpq.nationality = MobiSys::FNARequestService.setFundReasonApplicable(rpq) if rpq
        MobiSys::FNARequestService.saveValidate(fna,rpq) if fna.statusCd != "CLOSED"
        @baseIO.baseDO.isRPQApplicable = MobiSys::FNARequestService.isRPQApplicable(fna)
        @baseIO.baseDO.isForexAcrreditation = isForexAcrreditation
        @baseIO.baseDO.isPrioritySelected = isPrioritySelected
    end

    def generateResponseHash(isMetadataRequired = false, returnData = true)
        responseHash = {}
        responseHash["data"] = @entityHash if returnData
        responseHash["metadata"] = @metadataHash if isMetadataRequired
        visitedTabs = (@stepActionTabs.to_s != "" ? @stepActionTabs : @baseIO.baseDO.visitedTabs)
        # visitedTabs = @baseIO.baseDO.visitedTabs
        responseHash["validationerrors"] = fetchExceptions(@baseIO.baseDO.guid,visitedTabs) if @baseIO.baseDO.guid.to_s != ""
        $lookupArray.uniq!
        if $lookupArray.size > 0

            offlineLookupMList = OfflineLookupM.find(
                :all,
                :conditions =>{
                    {
                        :name => 'lookupKey',
                        :op => 'IN'
                    } => $lookupArray
                }
            )
            @offline_lookupCache = {}
            offlineLookupMList.each do |offlookupm|
                @offline_lookupCache[offlookupm.lookupKey] = {}
                @offline_lookupCache[offlookupm.lookupKey] = offlookupm
            end
            lookupValueList = Lookupvalue.getLookupValueIn($lookupArray)
            
            @lookupvalueCache = {}
            lookupValueList.each do |lookup|
                @lookupvalueCache[lookup.key] = [] if !@lookupvalueCache[lookup.key].is_a?(Array)
                @lookupvalueCache[lookup.key].push(lookup)
            end

            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end


        end
        responseHash["lookups"] = @lookupHash
        responseHash["success"] = @success
        responseHash["message"] = @message
        return responseHash

    end

    def copyFnaRequest(id,parsedData)
        sourceFna = @baseIO.baseDO
        responseHash = {}
        if sourceFna
            sourceRpq = targetToBeRpq = ""
            targetToBeFna = FNARequest.new
            sourceRpq = @baseIO.leadRPQDO
            targetToBeRpq = LeadRPQ.new if sourceRpq
            targetToBeFna, targetToBeRpq = MobiSys::FNARequestService.copyFnaAndRpq(sourceFna, targetToBeFna, sourceRpq, targetToBeRpq)
            @baseIO.baseDO = targetToBeFna
            @baseIO.leadRPQDO = targetToBeRpq
            @baseIO.baseDO.id = targetToBeFna.object.to_s
            responseHash["success"] = true
            responseHash["message"] = "Successful"
        else
            responseHash["success"] = false
            responseHash["message"] = "Fna not found"
        end
        return responseHash
    end

    def getFundRisk
        parsedData = parseRequestBodyParams
        responseHash = {}
        fundListbasisRiskProfile = []
        rpqScore = parsedData['rpqScore'].to_i if parsedData.has_key?("rpqScore")
        if (rpqScore.to_s != "")
            fundRiskClass = ""
            rpqLookupData = MobiSys::FNARequestService.getFundRisk(rpqScore)
            fundRiskClassLabel = ""
            if (rpqLookupData.to_s != "" && rpqLookupData.cd.to_s != "")
                labelDO = LabelValue.find( :first, :conditions => {{ :name => 'key'} => rpqLookupData.cd.to_s})
                fundRiskClass = labelDO.value
                fundRiskClassLabel = labelDO.labelValueExtra
            end

            companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
            companyColorValue = companyColor.value.to_s if companyColor
            if companyColorValue && companyColorValue.to_s == "SLOCPI"
                fundPackageList = Lookupvalue.find(:all, :conditions => { 'key' => "FUNDPACKAGESLOCPI" }, :order => ['sortOrder'])
                fundPackageList.each do |fundPkg|
                    if fundPkg.valueFrom.to_s != "" && fundPkg.valueTo.to_s != "" && fundPkg.valueFrom.to_i <= rpqScore && fundPkg.valueTo.to_i >= rpqScore
                        fundListbasisRiskProfile.push fundPkg.cd
                    end
                end
            end

            if fundListbasisRiskProfile.size > 1
                fundTable = MobiSys::FNARequestService.createTableForFund(fundListbasisRiskProfile, fundRiskClass)
            end

            responseHash = {"data" => {"fundRiskClass" => fundRiskClass, "fundRiskClassLabel" => fundRiskClassLabel, "FundTable" => fundTable},
                                "success" => true,
                                "message" => "Successful"}
        else
            responseHash = {"success" => false,
                                "message" => "RPQ Score not received try again"}
        end
        render :string => responseHash.to_json
    end

    def isRiskFundApplicable
      parsedData = parseRequestBodyParams
      flagMain = false
      fxFlag = false

      agent = AgentReg.getCurrentAgentReg
      if agent && agent.field6 && agent.field6.casecmp('FX').zero?
          fxFlag = true
      end

      facet = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"PACKAGEFUNDAPPLICABLE"})

      if facet && facet.actionValue.casecmp('YES').zero? && fxFlag
        flagMain = true
      end

      responseHash = {"data" => {"isRiskFundApplicable" => flagMain},
                                "success" => true,
                                "message" => "Successful"}
      render :string => responseHash.to_json
    end

    def populateFundListbasisRiskProfile
      parsedData = parseRequestBodyParams
      fundRiskClass = nil
      fundListbasisRiskProfile = []
      fundListDesc = []
      lookupMap = {}

      if parsedData.has_key?('rpqScore')
        packageScore = parsedData['rpqScore'].to_i

        rpqLookupData = MobiSys::FNARequestService.getFundRisk(packageScore)
        fundPackageList = Lookupvalue.find(:all, :conditions => { 'key' => "FUNDPACKAGESLOCPI" }, :order => ['sortOrder'])

        if rpqLookupData && rpqLookupData.desc
          labelDO = MobiSys::BrowserHelper.getLabel(rpqLookupData.desc)
          fundRiskClass = labelDO
        end

        fundPackageList.each do |fundPkg|
          lookupDO = fundPkg 

          if lookupDO.valueFrom && lookupDO.valueTo
            if packageScore >= lookupDO.valueFrom && packageScore <= lookupDO.valueTo
              fundListbasisRiskProfile << lookupDO.cd
              fundListDesc << lookupDO.desc
            end
          end
        end
        lookupMap[fundListbasisRiskProfile] = fundListDesc
        responseHash = {"data" => {"FundListbasisRiskProfile" => lookupMap},
                                "success" => true,
                                "message" => "Successful"}
        render :string => responseHash.to_json
      end
    end

    def fundListOptionWithoutIndiviual
      parsedData = parseRequestBodyParams
      fundListCd = []

      if parsedData.has_key?('selected') && parsedData['selected'] != 'INDIVIDUAL'
        packageFund = parsedData['selected'].delete('"').to_s if parsedData['selected'].to_s != ""

          fundPackageList = Lookupvalue.find(:all, :conditions => { 'key' => packageFund.to_s }, :order => ['sortOrder'])
          if fundPackageList
            fundPackageList.each do |pkg|
              lookupDO = pkg
              fundListCd << lookupDO.cd
            end
          end  
        responseHash = {"data" => {"FundListCd" => fundListCd},
                                "success" => true,
                                "message" => "Successful"}
        render :string => responseHash.to_json
      end
    end

    def defaultFundPackage
      parsedData = parseRequestBodyParams
      defaultFund = ""
      fnaId = ""
      fxFlag = false
      productFlag = false
      success = ""
      message = ""

      agentDo = AgentReg.getCurrentAgentReg
      if agentDo && agentDo.field6 && agentDo.field6.casecmp("FX").zero?
        fxFlag = true
      end
      
      if parsedData.has_key?("fnaId")
        fnaId = parsedData["fnaId"].to_s
        fnaRequest = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})

        if %w[RL1P0E RD1U0A SGPAB_R SGPAB_G GM7U0GR GM7U0GG RD1U0C].include?(fnaRequest.reasonForRecoCd)
          productFlag = true
        end
      end

      if fxFlag && !productFlag
        if parsedData.has_key?("packageScore")
          packageScore = parsedData["packageScore"].to_i
          fundPkg = Lookupvalue.find(:all, :conditions => { 'key' => "FUNDPACKAGES" }, :order => ['sortOrder'])

          fundPkg.each do |fndPkg|
            lookup = fndPkg
            if lookup.additionalField1 &&
               packageScore >= lookup.valueFrom &&
               packageScore <= lookup.valueTo &&
               lookup.additionalField1.casecmp("YES").zero?
              defaultFund = lookup.cd
            end
          end
          success = true
          message = "Successful"
        else
          message = "Package Score not received try again"
          success = false
        end
      else
        if productFlag
          message = "Packages are not allowed for selected Product."
        elsif !fxFlag
          message = "Packages are not allowed because user does not has FX accreditation."
        end
        success = false
      end
      responseHash = {"data" => {"defaultFund" => defaultFund},
                                "success" => success,
                                "message" => message}
      render :string => responseHash.to_json
    end

    def populateIndividualFunds
      parsedData = parseRequestBodyParams
      fnaId = ""
      fundRiskClassDesc = ""
      if parsedData.has_key?("fnaId")
        fnaId = parsedData["fnaId"].to_s
      end

      rpqResponseDoList = nil
      leadRpqDo = LeadRPQ.loadObject(:first, :conditions => {:fnaId => fnaId})
      leadRpqDo.address1 = "INDIVIDUAL"
      if leadRpqDo
        rpqResponseDoList = leadRpqDo.RPQResponseList
        rpqResList = leadRpqDo.rpqQuestionFromLookup

        if rpqResponseDoList.empty? && leadRpqDo.rpqId.to_s != ""
          if !rpqResList.empty?
            rpqResList.each do |lkpDataDo|
              rpqResponseDo = RPQResponse.new
              rpqResponseDo.rpqId = leadRpqDo.rpqId
              rpqResponseDo.userId = leadRpqDo.userId
              rpqResponseDo.question = lkpDataDo.cd
              leadRpqDo.addLeadRPQ(rpqResponseDo)
              rpqResponseDoList << rpqResponseDo
            end
          end
        end
      end

      fnaRequestDo = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})

      listFnaFundDo = []
      rpqFundList = Lookupvalue.find(:all,:conditions=>{'key'=>"RPQFUNDS"})

      fieldTargetValueMapDoList = FieldTargetValueMap.find(
                    :all,
                    :conditions => {
                        {:name=>'mappingKey'} => "RPQFUND"
                    }
                )
      FNAFund.delete_all(:conditions => {{:name=>'parentkey'} => fnaRequestDo.object})
      if fieldTargetValueMapDoList && !fieldTargetValueMapDoList.empty?
        @metadataHash = {}
        fieldTargetValueMapDoList.each do |fieldTargetValueMapDo|
          if fieldTargetValueMapDo.targetValue && fieldTargetValueMapDo.drivingValue
            if fieldTargetValueMapDo.drivingValue.casecmp(fnaRequestDo.reasonForRecoCd).zero?
              rpqFund = rpqFundList.select {|fund| fund.cd.to_s == fieldTargetValueMapDo.targetValue.to_s }[0]
              if rpqFund
                fnaFundDo = fnaRequestDo.getFNAFundByFundCd(rpqFund.cd.to_s, true)
                if fnaFundDo
                    fnaFundDo.field1 = rpqFund.additionalField1.to_s
                    fnaFundDo.field2 = rpqFund.additionalField2.to_s
                    fnaFundDo.guid = fnaFundDo.object.to_s.gsub('.', '_') if fnaFundDo.guid.to_s == ""
                    fnaFundDo.allocationPerc = ""
                    risk = ""
                    risk = Lookupvalue.getLookupValue("FUNDRISKCLASS",rpqFund.additionalField1.to_s)
                    risk = "High" if risk.to_s == ""
                    fnaFundDo.fundRiskClassLabel = risk
                end
                listFnaFundDo.push(fnaFundDo.hashForApi)
                fnaRequestDo.addFNAFund(fnaFundDo)
                @metadataHash.merge!(processMetadata(fnaFundDo))
              end
             end
          end
        end
      end
      responseHash = {"data" => {"FNAFundList" => listFnaFundDo, "leadRPQDOList" => rpqResponseDoList, "LeadRPQ" => leadRpqDo},
                                "success" => true,
                                "message" => "Successful"}
       @lookupHash = {}
        if $lookupArray
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
        end
        responseHash['lookups'] = @lookupHash
        responseHash["metadata"] = @metadataHash
        render :string => responseHash.to_json
    end

    def populateFundListBasisPackage
      parsedData = parseRequestBodyParams
      address2 = ""
      fnaId = ""
      fundRiskClassDesc = ""

      if parsedData.has_key?("address2")
        address2 = parsedData["address2"].to_s
      end

      if parsedData.has_key?("fnaId")
        fnaId = parsedData["fnaId"].to_s
      end

      fnaRequestDo = FNARequest.loadObject(:first, :conditions => {:fnaNum => fnaId})
      listFnaFundDo = []

      fundPkg = Lookupvalue.find(
                    :all,
                    :conditions =>{
                        {
                            :name => 'key'
                        } => address2
                    }
                )

      rpqFundList = Lookupvalue.find(
                :all,
                :conditions =>{
                    {
                        :name => 'key'
                    } => "RPQFUNDS"
                }
            )

      rpqResponseDoList = nil
      leadRpqDo = nil

      leadRpqDo = LeadRPQ.loadObject(:first, :conditions => {:fnaId => fnaId})
      leadRpqDo.address1 = "PACKAGE"
      if leadRpqDo

        rpqResponseDoList = leadRpqDo.getRPQResponseList

        rpqResList = leadRpqDo.rpqQuestionFromLookup

        if rpqResponseDoList.empty? && leadRpqDo.rpqId.to_s != ""
          if !rpqResList.empty?
            rpqResList.each do |lkpDataDo|
              rpqResponseDo = RPQResponse.new
              rpqResponseDo.rpqId = leadRpqDo.rpqId
              rpqResponseDo.userId = leadRpqDo.userId
              rpqResponseDo.question = lkpDataDo.cd
              leadRpqDo.addRPQResponse(rpqResponseDo)
              rpqResponseDoList << rpqResponseDo
            end
          end
        end
      end
      FNAFund.delete_all(:conditions => {{:name=>'parentkey'} => fnaRequestDo.object})
      @metadataHash = {}
      fundPkg.each do |baseDo|
        baseLookup = baseDo.key
        if address2 == baseLookup
          rpqFund = rpqFundList.select {|fund| fund.cd.to_s == baseDo.cd.to_s }[0]
          fnaFundDo = fnaRequestDo.getFNAFundByFundCd(baseDo.cd.to_s, true)
          fnaFundDo.field1 = rpqFund.additionalField1.to_s
          fnaFundDo.allocationPerc = baseDo.additionalField2.to_f
          fnaFundDo.field2 = rpqFund.additionalField2.to_s
          fnaFundDo.guid = fnaFundDo.object.to_s.gsub('.', '_') if fnaFundDo.guid.to_s == ""
          if baseDo && baseDo.additionalField1      
                fundRiskClassLabel = Lookupvalue.find(:first, :conditions=>{{:name=>'key'}=>"FUNDRISKCLASS", {:name=>'cd'} => baseDo.additionalField1.to_s},:op => 'AND')
                fnaFundDo.fundRiskClassLabel = fundRiskClassLabel.desc
          end
          listFnaFundDo << fnaFundDo.hashForApi
          fnaRequestDo.addFNAFund(fnaFundDo)
          @metadataHash.merge!(processMetadata(fnaFundDo))
        end
      end
      unless listFnaFundDo.empty?
        responseHash = {"data" => {"FNAFundList" => listFnaFundDo, "leadRPQDOList" => rpqResponseDoList, "LeadRPQ" => leadRpqDo},
                                "success" => true,
                                "message" => "Successful"}
        @lookupHash = {}
        if $lookupArray
            $lookupArray.uniq.each do |lookup|
                addToLookupHash(lookup)
            end
        end
        responseHash['lookups'] = @lookupHash
        responseHash["metadata"] = @metadataHash
      end
      render :string => responseHash.to_json
    end


    def deleteFNARequest
        parsedData = parseRequestBodyParams
        responseHash = {}
        ids = @params["id"] if @params.has_key?("id")
        ids =  parsedData['id'] if (parsedData.has_key?("id") && ids.to_s == "")
        isMultiDelete = false
        responseHash = {"successDeletedFNARequest" => 0, "failedDeletedFNARequest" => 0}
        if (ids != "") 
            if ids.to_s.include?(",")
                isMultiDelete = true
                id_str = ids.split(",")
                id_str.each do |idString|
                    responseHash = deleteSingleFNARequest(idString, responseHash, isMultiDelete)
                end
            else  
                responseHash = deleteSingleFNARequest(ids, responseHash, isMultiDelete)
            end
        elsif @baseIO.object.to_s != ""
            responseHash = deleteSingleFNARequest(@baseIO.object, responseHash, isMultiDelete)
        else 
            responseHash = {"success" => false,
                            "message" => "FNA Id is required for deletion."}
        end
        if isMultiDelete
            message = ""
            successDeletedFNARequest = responseHash["successDeletedFNARequest"]
            if successDeletedFNARequest.to_i > 0
                message = MobiSys::CommonUtil.replacePlaceHolders("successDeletedRec",[successDeletedFNARequest])
            end
            failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
            if failedDeletedFNARequest.to_i > 0
                message = MobiSys::CommonUtil.replacePlaceHolders("failedDeletedFNARequest",[failedDeletedFNARequest])
            end
            responseHash = {"message" => message}
        end
        render :string => responseHash.to_json
    end

    def deleteSingleFNARequest(id, responseHash, isMultiDelete)
        fetch(id)
        fna = @baseIO.baseDO
        leadRPQ = @baseIO.leadRPQDO
        if !@baseIO.baseDO
            if isMultiDelete
                failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
                failedDeletedFNARequest += 1
                responseHash["failedDeletedFNARequest"] = failedDeletedFNARequest
            else
                responseHash["success"] = false
                responseHash["message"] = "FNARequest not found."
            end
        elsif !(MobiSys::FNARequestBO::ACCEPTED == @baseIO.baseDO.statusCd.to_s)
            quotationList = Quotation.find(:all, :conditions => {:fnaId => @baseIO.baseDO.fnaNum})
            policy = Policy.find(:first, :conditions => {:fnaId => @baseIO.baseDO.fnaNum})
            if quotationList.size > 0 && policy
                failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
                failedDeletedFNARequest += 1
                responseHash["failedDeletedFNARequest"] = failedDeletedFNARequest
                message = getLabelValue("linkProposalCSADeleted")
                responseHash["success"] = false 
                responseHash["message"] = message
            elsif quotationList.size > 0
                failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
                failedDeletedFNARequest += 1
                responseHash["failedDeletedFNARequest"] = failedDeletedFNARequest
                message = getLabelValue("linkProposalCSADeletedNew")
                responseHash["success"] = false 
                responseHash["message"] = message
            else
                MobiSys::CommonUtil.clearTaskExceptionList(fna.guid)
                MobiSys::CommonUtil.clearTaskExceptionList(leadRPQ.guid) if leadRPQ
                responseHash["success"] = false 
                fna.delete
                leadRPQ.delete if leadRPQ
                begin
                    if isMultiDelete
                        successDeletedFNARequest = responseHash["successDeletedFNARequest"]
                        successDeletedFNARequest += 1
                        responseHash["successDeletedFNARequest"] = successDeletedFNARequest
                    else
                        message = MobiSys::CommonUtil.replacePlaceHolders("deletedSuccessfully",["fnaRequests"])
                        responseHash["success"] = true
                        responseHash["message"] = message
                    end  
                rescue StandardError => e
                    if isMultiDelete
                        failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
                        failedDeletedFNARequest += 1
                        responseHash["failedDeletedFNARequest"] = failedDeletedFNARequest
                    else
                        responseHash["success"] = false 
                        responseHash["message"] = e.message
                    end
                end
            end 
        elsif MobiSys::FNARequestBO::ACCEPTED == @baseIO.baseDO.statusCd.to_s
            if isMultiDelete
                failedDeletedFNARequest = responseHash["failedDeletedFNARequest"]
                failedDeletedFNARequest += 1
                responseHash["failedDeletedFNARequest"] = failedDeletedFNARequest
            else
                message = getLabelValue("acceptedRecDeleted")
                responseHash["success"] = false,
                responseHash["message"] = message
            end
        end
        return responseHash
    end

    def getSignatureHashMap(signatureTypeCd)
      signatureHashMap = {}
      agentSign = nil
      proposerSign = nil
      proposerGuid = nil

      @baseIO.baseDO.FNAPartyList.each do |fnapdo|
        if fnapdo.partyRoleCd == "PROPOSER"
          proposerGuid = fnapdo.guid
        end
      end

      @baseIO.ServiceSignatureList.each do |serviceSign|
        if signatureTypeCd == "SIGNATURECAPTURE" && signatureTypeCd == serviceSign.signatureTypeCd
          proposerSign = serviceSign
          break
        elsif signatureTypeCd == "AGENTSIGNATURECAPTURE" && signatureTypeCd == serviceSign.signatureTypeCd
          agentSign = serviceSign
          break
        end
      end

      if signatureTypeCd == "SIGNATURECAPTURE"
        if proposerSign.nil?
          proposerSign = ServiceSignature.new
          proposerSign.signatureTypeCd = "SIGNATURECAPTURE"
          proposerSign.roleCd = "PROPOSER"
          proposerSign.partyGuid = proposerGuid unless proposerGuid.nil?
          proposerSign.entityGuid = @baseIO.baseDO.guid
          @baseIO.serviceSignatureList << proposerSign
        end
        signatureHashMap["ProposerSignature"] = proposerSign

      elsif signatureTypeCd == "AGENTSIGNATURECAPTURE"
        if agentSign.nil?
          agentSign = ServiceSignature.new
          agentSign.signatureTypeCd = "AGENTSIGNATURECAPTURE"
          agentSign.roleCd = "AGENT"
          agentSign.entityGuid = @baseIO.baseDO.guid
          @baseIO.serviceSignatureList << agentSign
        end
        signatureHashMap["AgentSignature"] = agentSign
      end
      return signatureHashMap
    end

    def linkSI
        quotation = MobiSys::FNARequestService.getLinkQuotation(@baseIO)
        if quotation
            @baseIO.baseDO.quotationSeq = quotation.object
            process
        else
            @baseIO.errored = true
        end
    end

     def loadAdditionalMetadata(currentTagObject,metadataHash,companyMetadata=nil)
        if currentTagObject != nil && @baseIO.baseDO != nil && (@baseIO.baseDO.isCompleted || @baseIO.baseDO.isInvalid)
            metadataHash[currentTagObject.uniqueKey].each do |k, v|
                metadataHash[currentTagObject.uniqueKey][k]["ENABLED"] = "NO"
            end
        end
        return metadataHash
    end

    def getRPQFunds
        parsedData = parseRequestBodyParams
        responseHash = {}
        responseHash["data"] = {}
        
        # rpqScore = parsedData['rpqScore'].to_i if parsedData.has_key?("rpqScore")

        # if rpqScore.to_s != ""
            # p"inside----if---660-----rpqScore-----#{rpqScore}"
            # rpqLookupData = MobiSys::FNARequestService.getFundRisk(rpqScore)
            # p"inside---------rpqLookupData-----#{rpqLookupData}"
            # if rpqLookupData.to_s != ""
                fundAcrreditation = ""
                agentDO = AgentReg.getCurrentAgentReg
                fundAcrreditation = agentDO.field6 if agentDO
                # fieldTargetValueMapDOList = FieldTargetValueMap.find(
                #     :all,
                #     :conditions => {
                #         {:name=>'mappingKey'} => "FundRiskProfile"
                #     }
                # )

                # fundRiskProfileMap = {}

                # if !fieldTargetValueMapDOList.empty? && fieldTargetValueMapDOList.length > 0 
                #     fieldTargetValueMapDOList.each do |fieldTargetValueMapDO|
                #         if fieldTargetValueMapDO.targetValue.to_s != "" && fieldTargetValueMapDO.drivingValue.to_s != ""
                #             riskProdifileList = fieldTargetValueMapDO.targetValue.split(",")
                #             fundRiskProfileMap[fieldTargetValueMapDO.drivingValue.to_s] = riskProdifileList
                #         end
                #     end   
                # end

                rpqFundList = Lookupvalue.find(
                    :all,
                    :conditions =>{
                        {
                            :name => 'key'
                        } => "RPQFUNDS"
                    }
                )
            
                if !rpqFundList.empty? && rpqFundList.length > 0
                  comboValueList = []
                  rpqFundList.each do |lkpDataDO|
                      cd = lkpDataDO.cd
                      # if (lkpDataDO && lkpDataDO.additionalField2.to_s != "" && fundAcrreditation.to_s != lkpDataDO.additionalField2.to_s) || (fundRiskProfileMap.has_key?(cd.to_s) && fundRiskProfileMap[cd.to_s].to_s != "" && !fundRiskProfileMap[cd.to_s].include?(rpqLookupData.cd.to_s))
                      #     next
                      # end
                      if fundAcrreditation.to_s == "" && lkpDataDO.additionalField2.to_s != ""
                        next
                      end

                      comboValueHM = {}
                      comboValueHM["cd"] = cd
                      comboValueHM["desc"] = lkpDataDO.desc
                      comboValueList.push(comboValueHM)
                  end
                  # responseHash = {"value" => comboValueList,
                  #                 "success" => true,
                  #                 "message" => "RPQ Fund received"}

                  responseHash['data']['values'] = comboValueList
                  responseHash['success'] = true
                  render :string => responseHash.to_json
                end
            # end
        # else
        #   p"inside-------else-----711----------"
        #     responseHash = {"success" => false,
        #                     "message" => "RPQ Score not received try again"}    
        # end
    end

    def validate(id, parsedData)
        fna = @baseIO.baseDO
        rpq = @baseIO.leadRPQDO
        fna.fnaNum = SequenceNoGenerator.getNextNumber('FNA') if fna.fnaNum.to_s == ""
        rpq.nationality = MobiSys::FNARequestService.setFundReasonApplicable(rpq) if rpq
        MobiSys::FNARequestService.saveValidate(fna,rpq) if fna.statusCd != "CLOSED"
    end

    def isCompleted
        isCompleted = false
        if @baseIO.baseDO && MobiSys::FNARequestBO::ACCEPTED == @baseIO.baseDO.statusCd
            isCompleted = true
        end
        return isCompleted
    end

    def isPrioritySelected
        isPrioritySelected = false
        demolist = []
        listFNARequestAdditionalDO = @baseIO.baseDO.FNARequestAdditionalList
        if listFNARequestAdditionalDO && !listFNARequestAdditionalDO.empty? 
            count = 0
            listFNARequestAdditionalDO.each do |fnaQuestionRqsponse|
                if fnaQuestionRqsponse.field2.to_s != ""
                    demolist.push(fnaQuestionRqsponse.field2)
                    count += 1
                end
            end
            if count == 3
                isPrioritySelected = true
            end
        end
        return isPrioritySelected
    end

    def isForexAcrreditation
        isForexAcrreditation = false
        agentDO = AgentReg.getCurrentAgentReg
        if (agentDO && agentDO.field6.to_s != "" && "FX".downcase == agentDO.field6.strip.downcase)
            isForexAcrreditation = true
        end
        return isForexAcrreditation
    end

    def getCSAProductRecommendation
        parsedData = parseRequestBodyParams
        responseHash = {}
        field1Value = parsedData['field1'] if parsedData.has_key?("field1")
        if field1Value.to_s != "" 
            fieldTargetValueMapDOList = FieldTargetValueMap.find(
                :all,
                :conditions => {
                    {:name=>'mappingKey'} => "CSAProductCategoryType"
                }
            )

            productList = []

            if !fieldTargetValueMapDOList.empty? && fieldTargetValueMapDOList.length > 0 
                fieldTargetValueMapDOList.each do |fieldTargetValueMapDO| 
                    if fieldTargetValueMapDO.targetValue.to_s != "" && fieldTargetValueMapDO.drivingValue.to_s != ""
                        if fieldTargetValueMapDO.drivingValue.to_s.downcase == field1Value.to_s.downcase
                            productList.push(fieldTargetValueMapDO.targetValue)
                        end
                    end
                end
            end
            
            csaPlanList = Lookupvalue.find(
                :all,
                :conditions =>{
                    {
                        :name => 'key'
                    } => "CSAPlanCatMap"
                }
            )
            if !csaPlanList.empty? && csaPlanList.length > 0
                comboValueList = []
                csaPlanList.each do |lkpDataDO|
                    if productList.include? lkpDataDO.cd.to_s
                        comboValueHM = {}
                        comboValueHM["cd"] = lkpDataDO.cd.to_s
                        comboValueHM["desc"] = lkpDataDO.desc.to_s
                        comboValueList.push(comboValueHM) 
                    end
                end
                responseHash ={"data" => {"values" => comboValueList},
                                "success" => true,
                                "message" => "Product recomendation received."}
            end
        else
            responseHash = {"success" => false,
                            "message" => "Product recomendation not received try again."}
        end
        render :string => responseHash.to_json
    end

    def viewLeadOnFNA
        parsedData = parseRequestBodyParams
        responseHash = {}
        leadId = parsedData['leadId'] if parsedData.has_key?("leadId")
        if leadId
            lead = Lead.loadObject(:first, :conditions=>{:leadId=>leadId.to_s}) if leadId.to_s != ""
            if lead
                responseHash = {"data" => {"leadSeq" => lead.object.to_s},
                                "success" => true,
                                "message" => "Lead found."}
            else
                responseHash = {"success" => false,
                                "message" => "Lead  not found."}
            end
        else
            responseHash = {"success" => false,
                                "message" => "LEAD ID not received try again"}
        end
        render :string => responseHash.to_json
    end

    def fetchExceptions(entityGuid, visitedTabs)
        errors,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(entityGuid,visitedTabs)
        rpq = @baseIO.leadRPQDO
        fna = @baseIO.baseDO
        if rpq
            error,errorTabs,incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(rpq.guid,fna.visitedTabs)
            errors = errors.merge(error)
        end
        return errors
    end

    def init
    end

    def createQuotation(id, parseData)
        fnaRequest = @baseIO.baseDO
        responseHash = {}
        if fnaRequest
            quotation = MobiSys::FNARequestService.newQuotation(fnaRequest)
            fnaRequest.quotationSeq = quotation.object
        else
            responseHash = {"success" => false,
                            "message" => "fnaRequest  not found."}
        end
        return responseHash
    end

    def fetch(id)
        fna = FNARequest.loadObject(:first, :conditions => {:object => id})
        leadRPQ = LeadRPQ.loadObject(:first, :conditions=>{:fnaId=>fna.fnaNum}) if fna.fnaNum.to_s != ""
    	@baseIO.baseDO = fna
        @baseIO.leadRPQDO = leadRPQ
        @baseIO.baseDO.isRPQApplicable = MobiSys::FNARequestService.isRPQApplicable(fna) if fna
        leadRPQ.nationality = MobiSys::FNARequestService.setFundReasonApplicable(leadRPQ) if leadRPQ
        @baseIO.baseDO.isForexAcrreditation = isForexAcrreditation
    end

    def viewFNAPreview
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
         parsedModels = parsedData["FormData"]["Models"]
        if parsedModels && parsedModels.has_key?("Entity")
           witnessSignature = parsedModels["Entity"]["witnessSignature"]
        end
        # process()
        fnaRequest = @baseIO.baseDO
        fnaRequest = FNARequest.loadObject(:first, :conditions=>{:object=> fnaRequest.object.to_s})
        $graphHtmlHM = {}
        $graphHtmlCounter = 0
        $agentFlagRS = false
        proposalNum = parsedData["proposalNum"]
        policy = Policy.find(:first, :conditions => {:proposalNum => proposalNum.to_s}) if proposalNum
        $policy = policy
        if fnaRequest && policy
            fnaRequest.marketingInfoFl = policy.proposalNum
            fnaRequest.witnessSignature = witnessSignature if witnessSignature
            fnaRequest.persistAll
        end 
        $policyFlag = "true" if policy
        if proposalNum.to_s != "" && policy 
            if policy.allocatedToRole.to_s != "" && policy.allocatedToRole.to_s == "AGENT"
              $agentFlagRS = true   
            end
            if policy.statusCd.to_s != "SUBMITTED"
                $submitPolicyFlag = false
            end 
        end 
        # if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""
        #     outputPref = OutputPreferences.new
        #     outputPref = MobiSys::FNARequestService.defaultOutputPreferences(outputPref)
        #     responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        # else
            html = ""
            MobiSys::FNARequestService.initializeFNARequestIO(fnaRequest, @baseIO.outputPreferencesDO)
            # $fnaIO.bodyContent = ""
            # $fnaIO.cssContent = ""
            # $fnaIO.isFullHTMLRequired = parsedData["isFullHTMLRequired"].to_s != "" ? parsedData["isFullHTMLRequired"] : true
            # $fnaIO.isTemplateBasedOutput = false
            $fnaIO = MobiSys::IO::FnaIO.new
            responseHash["data"] = {}
            $fnaIO.baseDO =  fnaRequest
            MobiSys::UIGenUtilFNA.findTemplatePageMapping($fnaIO)
            MobiSys::UIGenUtilFNA.getHtmlStringandGeneratePDF(true, $fnaIO) 
            responseHash['data'] = {"CSAPreview" => $fnaIO.htmlContent}
            responseHash['success'] = true
            responseHash['message'] = "CSA preview generated successfully."
        render :string => responseHash.to_json
    end
end
require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'Product/product_b_o'
require 'Quotation/quotation_b_o'
require 'Quotation/quotation_util'
require 'Quotation/quotation_service'
require 'Quotation/UIGenUtil'
require 'Quotation/QuoteIllustration'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'
require 'TrackLead/track_lead_b_o'
require 'Quotation/Solver'
require 'ostruct'
require 'CommonModules/sym_template_util'
require 'erb'

class QuotationController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper
    include MobiSys::SymTemplateUtil

    def process
        # logInfo "~~~in quotation process"
        #Add executeLife code here for initializin quot_product
        quotation = @baseIO.baseDO
        baseProduct = quotation.getBaseProduct()
        newBaseProduct = baseProduct if baseProduct
        $currentProduct ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
       
        if baseProduct.nil?
            baseProduct = QuotationProduct.new
            baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, quotation)
            quotation.addQuotationProduct(baseProduct)
        elsif baseProduct.productSeq.to_s == ""
            baseProduct = MobiSys::QuotationService.setBaseProductDetails(baseProduct, $currentProduct, quotation)
        end

        if $currentProduct
            baseProduct.product = $currentProduct
        else
            baseProduct.product = Product.new
        end

        #check if any party attributes have changed then need to check if product is still applicable
        if (!@baseIO.additionalData || !@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") || (@baseIO.additionalData.has_key?("TRIGGERCHANGEPLAN") && @baseIO.additionalData['TRIGGERCHANGEPLAN'].to_s != "YES"))
            #MobiSys::QuotationUtil.checkProductApplicable(quotation)
        end

        if @baseIO.baseDO.proposerLASame.to_s == 'YES' || @baseIO.baseDO.proposerLASame.to_s == "COPYFROMINSURED"
            @baseIO.baseDO.proposerLASame = "COPYFROMINSURED"
        else
            @baseIO.baseDO.proposerLASame = "NO"
        end
        @baseIO.baseDO.QuotationPartyList.each do |quotationParty|
            if  quotationParty.visitedTabs.to_s == ""
                quotationParty.visitedTabs = MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationParty.roleCd)
            end
            if quotationParty.dob.to_s != ""
                quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                quotationParty.age = MobiSys::ProductBO.calculateAge(quotation, quotation.getBaseProduct, quotationParty, nil, getScreenDate(Time.new.to_s)).split("|")[0]
                quotationParty.dob = getDBDate(quotationParty.dob.to_s)
            end
            if (quotation.proposerLASame == "COPYFROMINSURED" || quotation.proposerLASame == 'YES')
                quotationParty.quotPartyAddtnField4  = "YES"
            else
                quotationParty.quotPartyAddtnField4 = "NO"
            end
            if quotationParty.roleCd.to_s == "PRIMARY"
                quotationParty.partyTypeCd = "INDIVIDUAL" if quotationParty.partyTypeCd.to_s == ""
            end
        end
        @baseIO.baseDO.QuotationProductList.each do|quotationProduct|
            if quotationProduct.visitedTabs.to_s == ""
                quotationProduct.visitedTabs =  MobiSys::CommonUtil.getVisitedTabID("QUOTATION",quotationProduct.productTypeCd)
            end
        end 

        reqBodyHash = Hash.new
        formDataHash = Hash.new
        modelsHash = Hash.new
        entityHash = Hash.new

        if @params.has_key? ('request-body')
            begin
                reqBodyHash = Rho::JSON.parse(@params['request-body']) 
                formDataHash = reqBodyHash['FormData'] if reqBodyHash.has_key? ('FormData')
                modelsHash = formDataHash['Models'] if formDataHash.has_key? ('Models')
                entityHash = modelsHash['Entity'] if modelsHash.has_key? ('Entity')
                if entityHash && entityHash['stepActionTabs'].to_s == "tab_selProduct," && (entityHash['productFamilyCd'].to_s != newBaseProduct.productFamilyCd || entityHash['productId'].to_s != newBaseProduct.productId )
                    if quotation.visitedTabs.include? (",tab_plan")
                        quotation.update_attributes(:visitedTabs => quotation.visitedTabs.to_s.gsub(",tab_plan",""))
                    end
                end
            rescue Exception => e
                logError("Error in parsing request-body",e, LOGCATEGORY)
            end
        end 

        MobiSys::CommonUtil.clearTaskExceptionList(quotation.guid)
        # saveValidate
        saveModel = @saveModel != nil ? @saveModel : true
        if quotation.action.to_s == ""
            quotation.action = "Save"
        end
        MobiSys::QuotationService.saveValidate(quotation,saveModel)
        MobiSys::QuotationService.populateMultiLife(quotation)
        @baseIO.baseDO.isInvalid = isInvalid
        @baseIO.baseDO.isCompleted = isCompleted
        @baseIO.baseDO.entityTypeCd = "QUOTATION" #Temp added need to discuss with Nikhil
    end

    def viewCSA
        parsedData = parseRequestBodyParams
        fnaId = parsedData['fnaId'] if parsedData.has_key?("fnaId")        
        fnaRequest = FNARequest.find(:first, :conditions => {:fnaNum => fnaId.to_s}) if fnaId

        responseHash = {}
        if fnaRequest.to_s != ''
            responseHash = {"data" => {"fnaSeq" => fnaRequest.object.to_s},
                                "success" => true,
                                "message" => "Success."}
        else
            responseHash = {"success" => false, "message" => "FNA Seq not found try again."}
        end
        render :string => responseHash.to_json
    end

    def viewLeadOnQuotation
        parsedData = parseRequestBodyParams
        leadId = parsedData['leadId'] if parsedData.has_key?("leadId")        
        lead = Lead.find(:first, :conditions => {:leadId => leadId.to_s}) if leadId

        responseHash = {}
        if lead.to_s != ''
            responseHash = {"data" => {"leadSeq" => lead.object.to_s},
                                "success" => true,
                                "message" => "Success."}
        else
            responseHash = {"success" => false, "message" => "Lead Seq not found try again."}
        end
        render :string => responseHash.to_json
    end

    def generateIllustrationPdf
        parsedData = parseRequestBodyParams
        responseHash = {}
        data = {}
        fetch(@params["id"]) if @params.has_key?("id")
        fetchData(parsedData,false,false)
        quotation = @baseIO.baseDO
       
        if $rhoconfig[:capture_output_preferences].to_s == "YES" and @baseIO.outputPreferencesDO.to_s == ""
            outputPref = OutputPreferences.new
            outputPref = MobiSys::QuotationService.defaultOutputPreferences(outputPref)

            responseHash = {"data" => {"OutputPreferences" => outputPref.hashForApi(false)} }
        else
            if $rhoconfig[:offlinePDFGeneration] && !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP'
                # ofline pdf generation
                MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                result = MobiSys::QuotationService.generateOfflinePDFHTML()
                if result.has_key?('error') and result['error'].to_s != ""
                    responseHash['success'] = false
                    responseHash['message'] = result['error'].to_s
                else
                    responseHash['data'] = {"FileName" => result['pdfFileName'], "pdfMode" => "offlinePDFGeneration"}
                    responseHash['success'] = true
                    responseHash['message'] = "Pdf generated successfully."
                end
            else
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    forceNetworkLogin, navigateToSync, masterSyncEnabled, masterSyncDefault, transactionSyncEnabled, transactionSyncDefault, masterDBUpgradeDt, transactionSyncDt, masterDBMandatory = MobiSys::Sync.processForceLoginSyncConditions("sync")
                    if navigateToSync
                        responseHash['success'] = false
                        responseHash['message'] = "Please take Primary database sync."
                    else
                        quotationPartyList = quotation.QuotationPartyList
                        lastNamePrimary = ''
                        firstNamePrimary = ''
                        filename = ''
                        baseProduct = quotation.getBasePlan
                        quotationPartyList.each do |quotationParty|
                            if quotationParty.roleCd == 'PRIMARY'
                              lastNamePrimary = quotationParty.lastname
                              firstNameArray = quotationParty.firstname.split(" ")
                              firstNamePrimary = firstNameArray.map do |word|
                                word.strip.empty? ? '' : word.strip[0].upcase
                              end.join
                            end
                        end

                        company =  CompanyFacet.find(
                                :first,
                                :conditions => {
                                    { :name => 'facetCd' } => 'PROPPDFFILENAME'
                                }
                            )
                        if company.actionTypeCd.to_s == "RULE"
                            facetValue = company.ruleSeq 
                            pdt = MobiSys::ProductUtil.getProductDefinitionTableDO(facetValue, quotation, baseProduct)
                            facetValuePlanCd = pdt.outputAction
                            dateTime = DateTime.now.strftime('%d%m%Y%H%M%S')
                            filename = "#{lastNamePrimary}_#{firstNamePrimary}_#{facetValuePlanCd}_#{dateTime}.pdf"
                        end
                        if $rhoconfig[:offlineOutputGeneration]
                            
                            $CreateOutputFiles = false

                            MobiSys::QuotationService.initializeQuotationIO(quotation, @baseIO.outputPreferencesDO)

                            result = MobiSys::QuotationService.generateOutputHTML()
                            if result.has_key?('error') and result['error'].to_s != ""
                                responseHash['success'] = false
                                responseHash['message'] = result['error'].to_s
                            else
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => filename}
                                responseHash['success'] = true
                                responseHash['message'] = "Pdf generated successfully."
                            end
                        else
                            outputPreferencesDO = nil
                            outputPreferencesDO = @baseIO.outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES" 
                            result = MobiSys::QuotationService.get_pdf(quotation, outputPreferencesDO)
                            if result and result.has_key?('PDFCONTENT')
                                responseHash['data'] = {"pdfFileContents" => result['PDFCONTENT'], "FileName" => filename}
                                responseHash['success'] = true
                                responseHash['message'] = "Pdf generated successfully."
                            else
                                responseHash['success'] = false
                                responseHash['message'] = "Error generating pdf."
                            end
                        end
                    end
                else
                    responseHash['success'] = false
                    responseHash['message'] = getLabelValue('CHECKNETWORK')
                end
            end            
        end

        render :string => responseHash.to_json 
    end

    def newPolicy(quotation)
        $rhoconfig[:moduleForProductValidations] = "Policy"
        quotpolicy = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
        agentRegdetails = AgentReg.getCurrentAgentReg
        
        if quotpolicy
            policy = quotpolicy
        else
            policy = Policy.new
            policy.quotationRefGuid = quotation.uniqueKey
            policy.bankStaffReferralCd = quotation.bankStaffReferralCd
            policy.quotationRefNum = quotation.quotationRefNum
            policy.branchCd = quotation.quotAddtnlField2
            policy.quotAddtnlField5 = agentRegdetails.field11
            policy.quotAddtnlField6 = agentRegdetails.field12
            policy.leadId = quotation.leadId
            policy.fnaId = quotation.fnaId
            policy.rpqId = quotation.rpqId
            policy.proposalEntryDt = Time.new.strftime("%F 00:00:00 %z")
            policy.proposalReceivedDt = Time.new.strftime("%F 00:00:00 %z")
            policy.isBackdatedFl = quotation.isBackdatedFl
            policy.quotationDt = quotation.quotationDt
            policy.insuranceTypeCd = quotation.insuranceTypeCd
            policy.supplementaryLives = quotation.supplementaryLives if quotation.supplementaryLives.to_s != ""
            policy.step = 0
            policy.statusCd = "PENDING"

            if quotation.isBackdatedFl.to_s == "YES"
                policy.policyCommencementDt = quotation.quotationDt
            else
                policy.policyCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end

            if quotation.isBackdatedFl.to_s == "YES"
                policy.riskCommencementDt = quotation.quotationDt
            else
                policy.riskCommencementDt = Time.new.strftime("%F 00:00:00 %z")
            end
            p "policy======#{policy}"
            policy.baseAgentId = $userId
            policy.proposalNum = SequenceNoGenerator.getNextNumber('POLICY')
            # policy.policyNum = policy.proposalNum
            policy.intimationSourceCd = "ESUBMISSION"
            policy.uwDecisionCd = "PENDING"

            #Add data for non face-to-face
            companyFacet = CompanyFacet.find(
                :first,
                :conditions => {
                    { :name => 'facetCd' } => 'NONFACETOFACE'
                }
            )
            if companyFacet && companyFacet.actionValue.to_s == "YES"
                policy.allocatedToRole = "AGENT"
                policy.allowModifyAllRoles = "YES"
            else
                policy.allocatedToRole = "NA"
            end

            MobiSys::PolicyBO.convertIllustrationToEappPlanDetails(quotation, policy)
            
            policyHolder = Party.new(:roleCd => "PROPOSER")
            policy.addParty(policyHolder)
            MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, policyHolder, "PROPOSER")
            policyPartyRoleProposer = PolicyPartyRole.new(:roleCd => "PROPOSER", :refGuid => policyHolder.uniqueKey)
            policy.addPolicyPartyRole(policyPartyRoleProposer)

            if quotation.proposerLASame == "COPYFROMINSURED"
                policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => policyHolder.uniqueKey, :partySameAsCd => "PROPOSER")
                policy.addPolicyPartyRole(policyPartyRoleInsured)
                policy.insuredSameAsProposer = true
                policy.quoteProposerSameAsInsured = "YES"
                policyHolder.relationCd = "INSUR"
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => policyHolder.guid)
                        policyProduct.addPolicyProductInsured(primaryProductInsured)
                    end
                end
            else
                insured = Party.new(:roleCd => "PRIMARY")
                policy.addParty(insured)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, insured, "PRIMARY")
                policyPartyRoleInsured = PolicyPartyRole.new(:roleCd => "PRIMARY", :refGuid => insured.uniqueKey, :partySameAsCd => "")
                policy.addPolicyPartyRole(policyPartyRoleInsured)
                policy.insuredSameAsProposer = false
                policy.quoteProposerSameAsInsured = "NO"
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        primaryProductInsured = PolicyProductInsured.new(:roleCd => "PRIMARY", :insuredSequenceTypeCd => "PRIMARY", :insuredPartyRefGuid => insured.guid)
                        policyProduct.addPolicyProductInsured(primaryProductInsured)
                    end
                end
            end

            if quotation.getPartyByRole("JOINT")
            jointLife = Party.new(:roleCd => "JOINT")
                policy.addParty(jointLife)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, jointLife, "JOINT")
                policyPartyRoleJointLife = PolicyPartyRole.new(:roleCd => "JOINT", :refGuid => jointLife.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleJointLife)
                
                policy.PolicyProductList.each do |policyProduct|
                    if policyProduct.productTypeCd == 'PLAN'
                        jointProductInsured = PolicyProductInsured.new(:roleCd => "JOINT", :insuredSequenceTypeCd => "JOINT", :insuredPartyRefGuid => jointLife.guid)
                        policyProduct.addPolicyProductInsured(jointProductInsured)
                    end
                end
            end

            quotation.getPartyListByRoleCd("SUPPLEMENTARY").each_with_index do |oldParty, index|
                suppLife = Party.new(:roleCd => "SUPPLEMENTARY")
                policy.addParty(suppLife)
                MobiSys::PolicyBO.convertIllustrationToEappParty(quotation, suppLife, "SUPPLEMENTARY", index)
                policyPartyRoleSuppLife = PolicyPartyRole.new(:roleCd => "SUPPLEMENTARY", :refGuid => suppLife.uniqueKey)
                policy.addPolicyPartyRole(policyPartyRoleSuppLife)
            end
            policy.persistAll
            quotation.proposalNum = policy.proposalNum
            quotation.persistAll
        end
        product = MobiSys::ProductUtil.getProduct(policy.baseProductSeq)
        return policy
    end

    def fetch(id)
        quotation = Quotation.loadObject(:first, :conditions => {:object => id})
        @baseIO.baseDO = quotation
        policy = Policy.loadObject(:first, :conditions=>{:quotationRefGuid=>@baseIO.baseDO.guid.to_s})
        if policy.to_s != ""
            @baseIO.baseDO.policySeq = policy.object
        end
        @baseIO.baseDO.isEappLinkApplicable = MobiSys::QuotationService.isEappLinkApplicable(quotation) if quotation
    end

    def convertToEapp(id, parseData)
        quotation = @baseIO.baseDO
        err_message = ''
        responseHash = {}
        proposalExpiredCheck = MobiSys::QuotationService.hasProposalExpired(quotation) if quotation
        unless proposalExpiredCheck
            if quotation != nil
                if quotation.isBackdatedFl.to_s == "YES"
                    policy = newPolicy(quotation)
                    quotation.policySeq = policy.object
                else
                    if quotation.quotationExpiryDt.to_s != "" && (Time.now.to_date - Date.strptime(getScreenDate(quotation.quotationExpiryDt.to_s), "%d/%m/%Y") > 0)
                        err_message = 'ERR_QUOTATION_EXPIRED'
                    elsif !(($rhoconfig[:captureSignOnSIOutput] || quotation.signature.to_s != "") && quotation.signatureDt.to_s != "" && (quotation.quoteStatusCd == "ACCEPTED" || quotation.quoteStatusCd == "SYNCDONE"))
                        err_message = 'Quotation status should be accepted.'
                    else
                        isAgeValid = true
                        quotation.QuotationPartyList.each do |quotationParty|
                            if quotationParty.dob.to_s != ""
                                quotationParty.dob = getScreenDate(quotationParty.dob.to_s)
                                newAge = MobiSys::ProductBO.calculateAge(quotation, quotation.getBaseProduct, quotationParty, nil, getScreenDate(Time.new.to_s)).split("|")[0]
                                quotationParty.dob = getDBDate(quotationParty.dob.to_s)
                                if newAge.to_i != quotationParty.age.to_i
                                    isAgeValid = false
                                    break
                                end
                            end
                        end
                        unless isAgeValid
                            err_message = 'ERR_AGE_CHANGED'
                        else
                            policy = newPolicy(quotation)
                            quotation.policySeq = policy.object
                        end
                    end
                end
            else
                err_message = 'Quotation not found.'
            end
        else
        Alert.show_popup({
            :message => MobiSys::BrowserHelper.getLabel('Quotation is expired'),
            :title => '',
            :icon => :alert,
            :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
        })
            err_message = "Quotation is expired"
        end
        
        if err_message != ''
            responseHash['success'] = false
            responseHash['message'] = err_message
        end
        return responseHash
    end
end

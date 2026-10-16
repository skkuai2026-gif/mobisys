require 'date'
require 'time'
require 'singleton'
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/commonutil'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/metadata'
require 'Product/product_b_o'
require 'Party/party_b_o'
require 'CommonModules/questionnaire'
require 'Product/product_util'

module MobiSys
  class FNARequestBO
    include Singleton
    include MobiSys::CommonUtil
    
    PENDING = "PENDING"
    COMPLETED = "COMPLETED"
    ACCEPTED = "ACCEPTED"
    SYNCDONE = "SYNCDONE"

    def self.validate_Jazz(entity, errors)
        $globalContextObjectMap = {}
        $currentValidationMetadata = nil
        $currentTabId = nil
        $taskExceptionHash = []

        if $rhoconfig[:contextBasedMetadata]
          classToFind = "#{entity.class.name}DO"
          contextMasterGeneratedArray = []
          if $contextMasterCache.has_key?(classToFind.to_sym)
            contextMasterList = $contextMasterCache[classToFind.to_sym]
            contextMasterGeneratedArray = MobiSys::ContextMasterData.generateContextModuleArray(contextMasterList,entity)
          end
          MobiSys::Validation.processValidContexts(entity.hashForSync, contextMasterGeneratedArray, "GenericSet")
          validationContexts = $globalContextObjectMap[entity.guid]
        else
          GenericSet.setObject(entity)
          validationContexts = GenericSet::ValidationContexts
        end
        MobiSys::Validation.validationLoop(entity.hashForSync, validationContexts, errors, "GenericSet")

        #function to run policy model based validations
        # validateCompanyFacet(entity,errors)
        db = Rho::Database.new(Rho::Application.databaseFilePath('local'),'local')
        db.start_transaction
        $taskExceptionHash.each do |taskException|
            taskException.persistAll
        end
        db.commit
        $taskExceptionHash = nil
    end

    #Ashwini: 09-05-2017: Basic Details Validations code start
    def self.validateBasicDetails(fnaParty, errors)
      isValid = true
      responseCheck = true
      tempErrorHash = Hash.new
      # if fnaParty.firstName1 == nil || fnaParty.firstName1 == ""
      #   MobiSys::CommonUtil.addErrors(tempErrorHash,"firstName1",MobiSys::BrowserHelper.getLabel('ERR_GIVEN_NAME_MANDATORY').force_encoding(Encoding::UTF_8),[])
      # end
      if fnaParty.lastName1 == nil || fnaParty.lastName1 == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"lastName1",MobiSys::BrowserHelper.getLabel('ERR_FAMILY_NAME_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.mobileNum == nil || fnaParty.mobileNum == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"mobileNum",MobiSys::BrowserHelper.getLabel('ERR_CONTACT_NUMBER_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      # if fnaParty.emailAddress == nil || fnaParty.emailAddress == ""
      #   MobiSys::CommonUtil.addErrors(tempErrorHash,"emailAddress",MobiSys::BrowserHelper.getLabel('ERR_EMAIL_MANDATORY').force_encoding(Encoding::UTF_8),[])
      # end

        if !tempErrorHash.empty?
          errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
          errors[:FNAParty][fnaParty.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaParty.guid.to_sym].is_a?(Hash)
          errors[:FNAParty][fnaParty.guid.to_sym] = errors[:FNAParty][fnaParty.guid.to_sym].merge(tempErrorHash)
        end
    end

    #Ashwini: 09-05-2017: Questionnaire Validations code start
    def self.validateQuestionnaireDetails(fnaParty, fnaRequest, errors)
      isEmpty = false
      isQ4bEmpty = false
      fnaParty.FNAQuestionResponseList.each do |response|
        tempErrorHash = Hash.new
        if "FNA_PRODUCT_PURPOSE".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_PRODUCT_PURPOSE" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q1_UNANS').force_encoding(Encoding::UTF_8),[])
          end
          if response.fnaQuestionLookupDataCd != nil || response.fnaQuestionLookupDataCd != ""
              if response.fnaQuestionLookupDataCd.include? "FNAQothersPurposePS"
                if response.responseValue == nil || response.responseValue == ""
                  MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q1_OTHER').force_encoding(Encoding::UTF_8),[])
                end
              end
          end
        end
        if "FNA_PRODUCT_TYPE".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_PRODUCT_TYPE" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q2_UNANS').force_encoding(Encoding::UTF_8),[])
          end
          if response.fnaQuestionLookupDataCd != nil || response.fnaQuestionLookupDataCd != ""
              if response.fnaQuestionLookupDataCd.include? "FNAQothersTypePS"
                if response.responseValue == nil || response.responseValue == ""
                  MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q2_OTHER').force_encoding(Encoding::UTF_8),[])
                end
              end
          end
        end
        if "FNA_POLICY_TARGET_HORIZON".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_POLICY_TARGET_HORIZON" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q3_UNANS').force_encoding(Encoding::UTF_8),[])
          end
        end
        if "FNA_GOAL_DURATION".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_GOAL_DURATION" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q4c_UNANS').force_encoding(Encoding::UTF_8),[])
          end
        end
         if "FNA_INCOME_PERCENT_FOR_PREMIUM".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_INCOME_PERCENT_FOR_PREMIUM" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q4d_UNANS').force_encoding(Encoding::UTF_8),[])
          end
          if response.fnaQuestionCd == "FNA_INCOME_PERCENT_FOR_PREMIUM" && response.fnaQuestionLookupDataCd.to_s == "FNAQmorethan50pc"
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ADVISORY_MESSAGE_Q4d').force_encoding(Encoding::UTF_8),[])
          end
        end
         if "FNA_FUND_SOURCE".include? response.fnaQuestionCd.to_s
          if response.fnaQuestionCd == "FNA_FUND_SOURCE" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_Q4e_UNANS').force_encoding(Encoding::UTF_8),[])
          else
            # Tejashree:07-07-2017 Validation for Please enter ot her source of funds in Q4e code start
            @array4d = [] 
            @value4d = response.fnaQuestionLookupDataCd
              if @value4d.nil? || @value4d == 0
              else
                @array4d << @value4d.split(",")
                @array4d.first.each do |val|
                  if val == "FNAQothersSourcePS"
                    if response.responseValue.to_s == nil || response.responseValue.to_s == ""
                     MobiSys::CommonUtil.addErrors(tempErrorHash,response.responseValue,MobiSys::BrowserHelper.getLabel('ERR_Q4e_OTHER').force_encoding(Encoding::UTF_8),[])
                    end
                  end
                end
              end
          end
        end
        if "FNA_IS_REGULAR_INCOME".include? response.fnaQuestionCd.to_s
          if( response.fnaQuestionCd == "FNA_IS_REGULAR_INCOME" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "") && fnaRequest.nonDisclosureofAssets.to_s == ""
            MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_OWN_HW').force_encoding(Encoding::UTF_8),[])
            isEmpty = true
          end
        end
        if "FNA_AMOUNT_OF_LIQUID_ASSETS".include? response.fnaQuestionCd.to_s
          # puts "FNA_AMOUNT_OF_LIQUID_ASSETS"
          # p "nil : #{response.fnaQuestionLookupDataCd != nil} ......... tingting : #{response.fnaQuestionLookupDataCd != ''}"
          if (response.fnaQuestionLookupDataCd.to_s != "")
          # puts "select at least one amount"
            fnaParty.FNAQuestionResponseList.each do |response|
              # puts "going in FNA_LIQUID_ASSETS_TOTAL: #{"FNA_LIQUID_ASSETS_TOTAL".include? response.fnaQuestionCd.to_s}"
              if "FNA_LIQUID_ASSETS_TOTAL".include? response.fnaQuestionCd.to_s
                # puts "FNA_LIQUID_ASSETS_TOTAL"
                if (response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "")
                  # puts "error displayed 1"
                  MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('Q4B_LIQUID_ASSET_MANDATORY').force_encoding(Encoding::UTF_8),[])
                end
              end
            end
          end
          if (response.fnaQuestionCd == "FNA_AMOUNT_OF_LIQUID_ASSETS" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "") && fnaRequest.nonDisclosureofAssets.to_s == ""
            if isEmpty == false
                # MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_OWN_HW').force_encoding(Encoding::UTF_8),[])
                isQ4bEmpty = true
            end
          end
          # modified by Vaibhav 24-07 (included validation for other field of Q 4b)
          if response.fnaQuestionLookupDataCd.to_s != ""
            if response.fnaQuestionLookupDataCd.include? "FNAQothersLiquidAssetPS"
              if response.responseValue == nil || response.responseValue == ""
                MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('OTHER_4_B').force_encoding(Encoding::UTF_8),[])
              end
            end
          end
        end
        if "FNA_LIQUID_ASSETS_TOTAL".include? response.fnaQuestionCd.to_s
          # puts "select at least one checkbox"
          if (response.fnaQuestionLookupDataCd.to_s != "")
            fnaParty.FNAQuestionResponseList.each do |response|
              if "FNA_AMOUNT_OF_LIQUID_ASSETS".include? response.fnaQuestionCd.to_s
                # puts "FNA_AMOUNT_OF_LIQUID_ASSETS"
                if (response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "")
                  # puts "error displayed 2"
                  MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('Q4B_AMOUNT_MANDATORY').force_encoding(Encoding::UTF_8),[])
                end
              end
            end
          end
        end
        if isQ4bEmpty == true
          if "FNA_LIQUID_ASSETS_TOTAL".include? response.fnaQuestionCd.to_s
            # puts "select at least one checkbox"
            # if (response.fnaQuestionLookupDataCd.to_s != "")
              # fnaParty.FNAQuestionResponseList.each do |response|
                # if "FNA_AMOUNT_OF_LIQUID_ASSETS".include? response.fnaQuestionCd.to_s
                  # puts "FNA_AMOUNT_OF_LIQUID_ASSETS"
                  # if (response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "")
                    # puts "error displayed 2"
                    # MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('Q4B_AMOUNT_MANDATORY').force_encoding(Encoding::UTF_8),[])
                  # end
                # end
              # end
            # end
            if (response.fnaQuestionCd == "FNA_LIQUID_ASSETS_TOTAL" && response.fnaQuestionLookupDataCd == nil || response.fnaQuestionLookupDataCd == "") && fnaRequest.nonDisclosureofAssets.to_s == ""
                MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('ERR_OWN_HW').force_encoding(Encoding::UTF_8),[])
                # isQ4bEmpty = true
            # elsif (response.fnaQuestionCd == "FNA_LIQUID_ASSETS_TOTAL" && response.fnaQuestionLookupDataCd != nil || response.fnaQuestionLookupDataCd == "" || response.    fnaQuestionLookupDataCd.to_s == "0") && fnaRequest.nonDisclosureofAssets.to_s == ""

            end
          end
        end


          
        
        if !tempErrorHash.empty?
          errors[:FNAQuestionResponse] = Hash.new if !errors[:FNAQuestionResponse].is_a?(Hash)
          errors[:FNAQuestionResponse][response.guid.to_sym] = Hash.new if !errors[:FNAQuestionResponse][response.guid.to_sym].is_a?(Hash)
          errors[:FNAQuestionResponse][response.guid.to_sym] = errors[:FNAQuestionResponse][response.guid.to_sym].merge(tempErrorHash)
        end
      end
    end
    
    #Tejashree: 15-o6-2017 AffordibilityCr Basic tab validation
   
    def self.validateAffordibilityCr(fnaParty, errors)
      isEmpty = false
      fnaParty.FNAQuestionResponseList.each do |response|
        tempErrorHash = Hash.new
        @array = [] 
       
          if "FNA_GOAL_DURATION".include?response.fnaQuestionCd.to_s
            @valuetofrom = Lookupvalue.find(
              :all,
              :conditions => {
                {:name => 'cd'} =>  response.fnaQuestionLookupDataCd
               },
               :op => 'AND',
               :select => ['valueTo']
             )
            if @value4d.nil? || @value4d == 0
               @flagincome = false
            else
                @array << @value4d.split(",")
                @flagincome = false
                @array.first.each do |val|
                    if val == "FNAQincome"
                      @flagincome = true 
                    end
                end
            end
            @valuetofrom.each do |value|
              if (fnaParty.age.to_i + value.valueTo.to_i) > 65 
                if @flagincome == false
                  MobiSys::CommonUtil.addErrors(tempErrorHash,response.fnaQuestionCd,MobiSys::BrowserHelper.getLabel('PT_EXCEEDS_RET_AGE').force_encoding(Encoding::UTF_8),[])
                end
              end
            end
      end
        if !tempErrorHash.empty?
          errors[:FNAQuestionResponse] = Hash.new if !errors[:FNAQuestionResponse].is_a?(Hash)
          errors[:FNAQuestionResponse][response.guid.to_sym] = Hash.new if !errors[:FNAQuestionResponse][response.guid.to_sym].is_a?(Hash)
          errors[:FNAQuestionResponse][response.guid.to_sym] = errors[:FNAQuestionResponse][response.guid.to_sym].merge(tempErrorHash)
        end
      end
    end

    #Ashwini: 09-05-2017: Q5 Introduction Validations code start
     def self.validateProductIntroduced(fnaRequest,fnaProposer,products_selected_array,errors,warningErrors)
      tempErrorHash = Hash.new
      warning_temp_hash= Hash.new
      @prod_group = []
      @prod_family = []
      @prod_type_cd = []
      @cause_For_Deviation_q6 = []
      @products_introduced_list = FNAProduct.find(
              :all,
              :conditions => {
                { :name => 'guid', :op => 'IN'} => products_selected_array.flatten.uniq,
               
              },
              :op => 'AND',
              :select => ['productId', 'guid', 'object', 'productTypeCd', 'productFamilyId', 'productGroupName', 'naBenefitTerm']
            )

      @productFamilyCd = []

      if products_selected_array.flatten.uniq.size.to_i > 8
         MobiSys::CommonUtil.addErrors(tempErrorHash,"WARNING_ONLY_5_PRODUCTS_SELECTED",MobiSys::BrowserHelper.getLabel('WARNING_ONLY_5_PRODUCTS_SELECTED').force_encoding(Encoding::UTF_8),[])
      end
      
      # 1. Please select 1 more Non-ILAS Product for Product Comparison Purpose.”   ERROR message 
        @isNaBenefitTermPresent = false      
        @products_introduced_list.each do |introduced_products|
          if introduced_products.productFamilyId !=nil && introduced_products.productFamilyId != ""
             @prod_family << introduced_products.productFamilyId
          end
          
          if introduced_products.productTypeCd !=nil && introduced_products.productTypeCd != ""
             @prod_type_cd << introduced_products.productTypeCd
          end
        end

        #Ashwini : New Q6B validation rule added to disable/enable q6b
        isNaBenefitTermPresent = false
        @products_introduced_list.each do |introduced_products|
          fnaProposer.FNAQuestionResponseList.each do |q_resp|
            if q_resp.fnaQuestionCd == "FNA_POLICY_TARGET_HORIZON"
              if introduced_products.naBenefitTerm != nil && introduced_products.naBenefitTerm.to_s != ""
               if introduced_products.naBenefitTerm.include?q_resp.fnaQuestionLookupDataCd
                  isNaBenefitTermPresent = true
                  @cause_For_Deviation_q6 << "Q6b_4"
               end
              end
            end
          end 
        end
          

        product_family_list = @prod_family.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

        product_type_cd_list = @prod_type_cd.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

        product_type_cd_list.each do |producttypecd,count|
          if producttypecd == "PLAN"
              if count.to_i == 1
                 MobiSys::CommonUtil.addErrors(tempErrorHash,"ATLEAST_2_BASE_PLANS",MobiSys::BrowserHelper.getLabel('ATLEAST_2_BASE_PLANS').force_encoding(Encoding::UTF_8),[])
              end
          end
        end

        @check_investLinkcount = 0
         product_family_list.each do |product_family,count|
          if product_family == "INVESTLINK"
              @check_investLinkcount = count
          end
        end

        @checkcount = products_selected_array.flatten.uniq.size.to_i - @check_investLinkcount
          if @checkcount.to_i == 0 || products_selected_array.flatten.uniq.size.to_i == 0
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_1_ILAS_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_1_ILAS_PRODUCT').force_encoding(Encoding::UTF_8),[])
          end
          # Ashwini - Only Rider can not be selected with ILAS Product. Base plan should be selected
          @countBasePlanCheck = false
          @countRiderPlanCheck = false
          @countBasePlan = 0
          if @prod_family.include?"INVESTLINK" 
            @products_introduced_list.each do |list| 
              if list.productFamilyId != "INVESTLINK" && list.productTypeCd == "RIDER"
               @countRiderPlanCheck = true 
              elsif list.productFamilyId != "INVESTLINK" && list.productTypeCd == "PLAN"
                @countBasePlanCheck = true 
                break
              end
            end
          end

          if @countBasePlanCheck  == false && @countRiderPlanCheck == true
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_1_ILAS_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_1_ILAS_PRODUCT').force_encoding(Encoding::UTF_8),[])
          end

        # 2. Product(s) with different payment term only is not accepted as Other Insurance Option. - ERROR message
        @products_introduced_list.each do |introduced_products|
          if introduced_products.productGroupName !=nil && introduced_products.productGroupName != ""
            @prod_group << introduced_products.productGroupName
          end
        end
        product_grp_list = @prod_group.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

        product_grp_list.each do |product,count|
          if count > 1 && @prod_group.uniq.size == 1
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_DIFF_PAYMENT_TERM",MobiSys::BrowserHelper.getLabel('ERR_DIFF_PAYMENT_TERM').force_encoding(Encoding::UTF_8),[])
            break
          end
        end

      @agent_Id = AgentReg.getCurrentAgentReg.agentId

      applicableProductsList = AgentReg.find(
                          :all,
                          :conditions => {
                          { :name => 'agentId' } => @agent_Id
                          },
                          :op => 'AND',
                          :select => ['applicableProducts'])

      @agentRegApplicableProducts = applicableProductsList.collect{|x| x.applicableProducts}

      #product matrix logic
      fnaGoalDuration = fnaProposer.getQuestionResponse('FNA_GOAL_DURATION')
      lrm = {}
      #Q4-C
      lrm[:FNA_GOAL_DURATION] = FNAProductMatrix.find(  
              :all,
              :conditions => {
                { :name => 'fnaQuestionCd' }=> 'FNA_GOAL_DURATION',
                { :name => 'fnaQuestionLookupDataCd' }=> fnaGoalDuration.fnaQuestionLookupDataCd
            },
            :op => 'AND',
            :select => ['fnaProductSeq']
      )

      applicableProductSeqList = FNAProduct.find(  
              :all,
              :conditions => {
                { :name => 'productId' ,:op => 'IN' } => @agentRegApplicableProducts.first 
            
             },
             :op => 'AND',
             :select => ['guid']
      )


      @commonProducts = applicableProductSeqList.collect{|x| x.guid} & lrm[:FNA_GOAL_DURATION].collect{|x| x.fnaProductSeq}

      #Q1 Response list - A,B
      fnaQ1Response = fnaProposer.getQuestionResponse('FNA_PRODUCT_PURPOSE')
      fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      @fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Q2 Response list - B,C
      fnaQ2Response = fnaProposer.getQuestionResponse('FNA_PRODUCT_TYPE')
      @fnaQ2ResponseList = fnaQ2Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Iterate over Q1 response list to get the recommended products
      @resulthash={}
      isLessThanOne = true
      isLessThanOne_q2 = true
      collectCounts_q1 = {}
      collectCounts_q2 = {}

      @fnaQ1ResponseList.each do |q1Response|
          lrm[:FNA_PRODUCT_PURPOSE] = FNAProductMatrix.find(
            :all,
            :conditions => {
              { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_PURPOSE',
              { :name => 'fnaQuestionLookupDataCd' } => q1Response.to_s
                       },
            :op => 'AND',
            :select => ['fnaProductSeq']
          )
          #Find recommended products of Q1 which are present in Q4-C
          @common = lrm[:FNA_PRODUCT_PURPOSE].collect{|x| x.fnaProductSeq} 
          #check if introduced products are present in @common of each Q1 respomse.
          @count_q1_products = 0
          products_selected_array.flatten.each do |product|
            if @common.include?product
              @count_q1_products = @count_q1_products + 1
            end
          end


        collectCounts_q1[q1Response] = @count_q1_products

        # Warning Hash - 3. "There are some needs of the client not addressed according to the current products introduced. Do you wish to continue?”  WARNING
         @count_of_q1_products = []
        if collectCounts_q1 != ""
          collectCounts_q1.each do |q2_option, product_count|
            @count_of_q1_products << product_count
          end
        end

        
        if @count_of_q1_products.include?0
            MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_NOT_INTRODUCED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_NOT_INTRODUCED').force_encoding(Encoding::UTF_8),[])
            @cause_For_Deviation_q6 << "Q6b_1"
        end

      end
        @count_q2_products = 0
        @q2_products = []
        @fnaQ2ResponseList.each do |q2Response|
           @resulthash[:FNA_PRODUCT_TYPE] =  FNAProductMatrix.find(
            :all,
            :conditions => {
              { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_TYPE',
              { :name => 'fnaQuestionLookupDataCd' } => q2Response.to_s
              # { :name => 'fnaProductSeq', :op => 'IN' } => @common
            },
            :op => 'AND',
            :select => ['fnaProductSeq']
           )

             @productsList = @resulthash[:FNA_PRODUCT_TYPE].collect{|x| x.fnaProductSeq}

              @count_q2_products = 0
              products_selected_array.flatten.each do |product|
                if @productsList.include?product
                  @count_q2_products = @count_q2_products + 1
                end
              end
              collectCounts_q2[q2Response] = @count_q2_products
        end

       
        # Warning Hash - 3. "There are some needs of the client not addressed according to the current products introduced. Do you wish to continue?”  WARNING
        @count_of_q2_products = []
        if collectCounts_q2 != ""
          collectCounts_q2.each do |q2_option, product_count|
            @count_of_q2_products << product_count
          end
        end
        # Ashwini 27-07-2017: To fix defect UAT defect 325 added validation for q2 
        if @count_of_q2_products.include?0
            MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_NOT_INTRODUCED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_NOT_INTRODUCED').force_encoding(Encoding::UTF_8),[])
            @cause_For_Deviation_q6 << "Q6b_1"  
        end

        collectCounts_q1.each do |q1_response, product_introduced|
          if product_introduced > 1
             isLessThanOne = false

             break
          end
        end
          
      if isLessThanOne == true
        MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_MEET_1_OBJ",MobiSys::BrowserHelper.getLabel('ERR_MEET_1_OBJ').force_encoding(Encoding::UTF_8),[])
      end

      # 4. Warning q1-- There are some needs of the current products introduced exceeded the client needs. Do you wish to continue?
      @responses_against_q1 = FNAProductMatrix.find(
                          :all,
                          :conditions => {
                            { :name => 'fnaProductSeq', :op => 'IN'} => products_selected_array.flatten,
                            { :name => 'fnaQuestionCd', :op => 'IN'} => "FNA_PRODUCT_PURPOSE"
                          },
                          :op => 'AND',
                          :select => ['fnaProductSeq', 'fnaQuestionCd', 'fnaQuestionLookupDataCd', 'productTypeCd']
                        )
      @fna_q1_Question_Responses = []

      fnaProposer.FNAQuestionResponseList.each do |responses|
          if responses.fnaQuestionCd == "FNA_PRODUCT_PURPOSE"
              @fna_q1_Question_Responses << responses.fnaQuestionLookupDataCd.split(",")
          end
      end

      @options_against_q1_list =[]
      @client_introduced_resp_needs_for_q1 = []

      @responses_against_q1.each do |key|
        @options_against_q1_list << key.fnaQuestionLookupDataCd
      end


      # # Ashwini 27-07-2017: To fix defect UAT defect 325 removed validation from q1 and added for q2
        # Remove q1 and retain q2
      # @client_introduced_resp_needs_for_q1 << @options_against_q1_list.uniq
      # @client_introduced_resp_needs_for_q1.first.each do |q1_resp|
      #   if !@fna_q1_Question_Responses.flatten.include?q1_resp
      #       MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_EXCEEDED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_EXCEEDED').force_encoding(Encoding::UTF_8),[])
      #       # @cause_For_Deviation_q6 << "Q6b_1"
      #   end
      # end

      #5. Warning q2-- There are some needs of the current products introduced exceeded the client needs. Do you wish to continue?
      @responses_against_q2 = FNAProductMatrix.find(
                          :all,
                          :conditions => {
                            { :name => 'fnaProductSeq', :op => 'IN'} => products_selected_array.flatten,
                            { :name => 'fnaQuestionCd', :op => 'IN'} => "FNA_PRODUCT_TYPE"
                          },
                          :op => 'AND',
                          :select => ['fnaProductSeq', 'fnaQuestionCd', 'fnaQuestionLookupDataCd', 'productTypeCd']
                        )
    
      @fna_q2_Question_Responses = []

      fnaProposer.FNAQuestionResponseList.each do |responses|
          if responses.fnaQuestionCd == "FNA_PRODUCT_TYPE"
              @fna_q2_Question_Responses << responses.fnaQuestionLookupDataCd.split(",")
          end
      end

      @options_against_q2_list =[]
      @client_introduced_resp_needs_for_q2 = []

      @responses_against_q2.each do |key|
        @options_against_q2_list << key.fnaQuestionLookupDataCd
      end


      @client_introduced_resp_needs_for_q2 << @options_against_q2_list.uniq
      # Ashwini 27-07-2017: To fix defect UAT defect 325 removed validation from q1 and added for q2
      @client_introduced_resp_needs_for_q2.first.each do |q2_resp|
        if !@fna_q2_Question_Responses.flatten.include?q2_resp
             MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_EXCEEDED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_EXCEEDED').force_encoding(Encoding::UTF_8),[])
             @cause_For_Deviation_q6 << "Q6b_1"
        end
      end

      if !tempErrorHash.empty?
        errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
      end

      if !warning_temp_hash.empty?
        warningErrors[:FNARequest] = Hash.new if !warningErrors[:FNARequest].is_a?(Hash)
        warningErrors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !warningErrors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
        warningErrors[:FNARequest][fnaRequest.guid.to_sym] = warningErrors[:FNARequest][fnaRequest.guid.to_sym].merge(warning_temp_hash)
      end
     
        @cause_For_Deviation_q6_uniq = @cause_For_Deviation_q6.uniq
        return errors,warningErrors, @cause_For_Deviation_q6_uniq, @isNaBenefitTermPresent
    end
      
    #Ashwini - Question 6a and 6b enable/disable validtaion rules
    def self.get_rule_for_q6_validation(fnaRequest)
        fnaParty = fnaRequest.FNAPartyList[0]
        @isRuleApplicable = false
        @is_4b_selected = false
        @question_responses_list = FNAQuestionResponse.find(
            :all,
            :conditions => {
              {:name => 'fnaQuestionCd', :op => 'IN'} => "FNA_INCOME_PERCENT_FOR_PREMIUM, FNA_AMOUNT_OF_LIQUID_ASSETS, FNA_FUND_SOURCE, FNA_POLICY_TARGET_HORIZON",
              {:name => 'parentKey'} => fnaParty.object
             },
             :op => 'AND',
             :select => ['fnaQuestionLookupDataCd', 'fnaQuestionCd']
             
        )
        #rule2  if answer to Q4d is > 50%
        @causeForDeviation = []
        @question_responses_list.each do |questionresponse|
            if questionresponse.fnaQuestionCd == "FNA_INCOME_PERCENT_FOR_PREMIUM"  
                if questionresponse.fnaQuestionLookupDataCd == "FNAQmorethan50pc" 
                   @isRuleApplicable = true
                   @causeForDeviation << "Q6b_2"
                end        
            end
           #rule5
            # @is_4b_selected = true
              if questionresponse.fnaQuestionCd == "FNA_AMOUNT_OF_LIQUID_ASSETS"
                if questionresponse.fnaQuestionLookupDataCd == ""  || questionresponse.fnaQuestionLookupDataCd == nil
                  @is_4b_selected = true
                  @isRuleApplicable = true
                end        
              end
        end #end first iteration

       #rule5's and condition  - If Q4b is not selected, and select “Saving” and/or “Investment” only in Q4e
        if @is_4b_selected == true
            @question_responses_list.each do |questionresponse|
              if questionresponse.fnaQuestionCd == "FNA_FUND_SOURCE"
                  if questionresponse.fnaQuestionLookupDataCd == "FNAQsavings,FNAQinvestments"
                      @isRuleApplicable = true
                      @causeForDeviation << "Q6b_5"
                  elsif questionresponse.fnaQuestionLookupDataCd == "FNAQsavings"
                           @isRuleApplicable = true
                           @causeForDeviation << "Q6b_5"
                  elsif  questionresponse.fnaQuestionLookupDataCd == "FNAQinvestments"
                           @isRuleApplicable = true
                           @causeForDeviation << "Q6b_5"
                  end
              end
            end #end second iteration
        end
        
        #Rule 3  total face amount of purchased product > 30% higher than shortfall
        lifeProtectionNeedObj = fnaRequest.FNALifeProtectionNeedList[0]
        # added temporary check
         if  !lifeProtectionNeedObj.nil?
            if fnaRequest.totSumAssured != nil || fnaRequest.totSumAssured != "" && lifeProtectionNeedObj.shortfallAmt!=nil || lifeProtectionNeedObj.shortfallAmt != ""
               calculate_shortfall = 1.3 * lifeProtectionNeedObj.shortfallAmt.to_i
               if fnaRequest.totSumAssured.to_i > calculate_shortfall.to_i
                  @isRuleApplicable = true
                  @causeForDeviation << "Q6b_3"
               end
            end
        else
              if fnaRequest.totSumAssured.to_i > 0
                  @causeForDeviation << "Q6b_3"
              end

        end

        return @causeForDeviation
    end

    #Tejashree:22-06-2017: Life Protection Validations code start
    def self.validateLifeProtectionNeed(fnaRequest, errors)
      isEmpty = false
      tempErrorHash = Hash.new
      fnaLifeprotection =  fnaRequest.FNALifeProtectionNeedList[0]
      
       @iRate = FNARequest.find(
            :all,
            :conditions => {
              {:name => 'object'} => fnaRequest.object
             },
             :op => 'AND',
             :select => ['inflationRate']      
        )
      
       @rRate = FNARequest.find(
            :all,
            :conditions => {
              {:name => 'object'} => fnaRequest.object
             },
             :op => 'AND',
             :select => ['returnRate']      
        )
     
      @iRate.each do |iRate|
      
      if iRate.inflationRate.to_i < 0 || iRate.inflationRate.to_i > 1000 || iRate.inflationRate == "" || iRate.inflationRate == nil
        MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaRequest",MobiSys::BrowserHelper.getLabel('ERR_INFLATION_UNANS').force_encoding(Encoding::UTF_8),[])
      end
    end
    @rRate.each do |rRate|
      
      if rRate.returnRate.to_i < 0 || rRate.returnRate.to_i > 1000 || rRate.returnRate == "" || rRate.returnRate == nil
         MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaRequest",MobiSys::BrowserHelper.getLabel('ERR_RETURN_UNANS').force_encoding(Encoding::UTF_8),[])
      end
      end


      if fnaLifeprotection != nil 
      if fnaLifeprotection.shortfallAmt == nil || fnaLifeprotection.shortfallAmt == ""  
        MobiSys::CommonUtil.addErrors(tempErrorHash,"shortfallAmt",MobiSys::BrowserHelper.getLabel('SHORTFALLMANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaLifeprotection.montlyExpenseAmt == nil || fnaLifeprotection.montlyExpenseAmt == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"montlyExpenseAmt",MobiSys::BrowserHelper.getLabel('MTHEXPMANDATORY').force_encoding(Encoding::UTF_8),[])
      end  
      else
        MobiSys::CommonUtil.addErrors(tempErrorHash,"shortfallAmt",MobiSys::BrowserHelper.getLabel('SHORTFALLMANDATORY').force_encoding(Encoding::UTF_8),[])
        MobiSys::CommonUtil.addErrors(tempErrorHash,"montlyExpenseAmt",MobiSys::BrowserHelper.getLabel('MTHEXPMANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if !tempErrorHash.empty?
          errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
          errors[:FNAParty][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaRequest.guid.to_sym].is_a?(Hash)
          errors[:FNAParty][fnaRequest.guid.to_sym] = errors[:FNAParty][fnaRequest.guid.to_sym].merge(tempErrorHash)
      end
      return errors
    end
   
  #Tejashree:17-08-2017:  Life Protection Validations for Complex version code start 
  def self.validateLifeProtectionNeedComplex(fnaRequest, errors)
    isEmpty = false
    tempErrorHash = Hash.new
    fnaLifeprotection =  fnaRequest.FNALifeProtectionNeedList[0]
      @iRate = FNARequest.find(
            :all,
            :conditions => {
              {:name => 'object'} => fnaRequest.object
             },
             :op => 'AND',
             :select => ['inflationRate']      
        )
      
       @rRate = FNARequest.find(
            :all,
            :conditions => {
              {:name => 'object'} => fnaRequest.object
             },
             :op => 'AND',
             :select => ['returnRate']      
        )
     
      @iRate.each do |iRate|
      if iRate.inflationRate.to_i < 0 || iRate.inflationRate.to_i > 1000 || iRate.inflationRate == "" || iRate.inflationRate == nil
        MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaRequest",MobiSys::BrowserHelper.getLabel('ERR_INFLATION_UNANS').force_encoding(Encoding::UTF_8),[])
      end
      end

      @rRate.each do |rRate|
      if rRate.returnRate.to_i < 0 || rRate.returnRate.to_i > 1000 || rRate.returnRate == "" || rRate.returnRate == nil
         MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaRequest",MobiSys::BrowserHelper.getLabel('ERR_RETURN_UNANS').force_encoding(Encoding::UTF_8),[])
      end
      end


      if fnaLifeprotection != nil 
      if fnaLifeprotection.montlyExpenseAmt == nil || fnaLifeprotection.montlyExpenseAmt == "" || fnaLifeprotection.shortfallAmt == nil || fnaLifeprotection.shortfallAmt == "" 
        MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaLifeprotection",MobiSys::BrowserHelper.getLabel('ERR_LIFE_NEEDS').force_encoding(Encoding::UTF_8),[])
      end
      else
        MobiSys::CommonUtil.addErrors(tempErrorHash,"fnaLifeprotection",MobiSys::BrowserHelper.getLabel('ERR_LIFE_NEEDS').force_encoding(Encoding::UTF_8),[])
      end
      if !tempErrorHash.empty?
          errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
          errors[:FNAParty][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaRequest.guid.to_sym].is_a?(Hash)
          errors[:FNAParty][fnaRequest.guid.to_sym] = errors[:FNAParty][fnaRequest.guid.to_sym].merge(tempErrorHash)
      end
      return errors
  end


  #Tejashree:22-06-2017: Policy Details Validations code start
   def self.validatePolicyDetails(fnaRequest, policyarray, errors)
    isEmpty = false
    tempErrorHash = Hash.new

    if policyarray.size == 0
      MobiSys::CommonUtil.addErrors(tempErrorHash,"policyarray",MobiSys::BrowserHelper.getLabel('ERR_MIN_1_POLICY_NO').force_encoding(Encoding::UTF_8),[])
    end
    if policyarray.size !=  policyarray.uniq.size
       MobiSys::CommonUtil.addErrors(tempErrorHash,"policyarray",MobiSys::BrowserHelper.getLabel('NO_DUPLICATE_POLICY_NOS').force_encoding(Encoding::UTF_8),[])
    end
     if !tempErrorHash.empty?
      errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
      errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
      errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
     end
  
      return errors
   end

   #Tejashree:29-08-2017: Ilas Non Ilas Validations code start
   def self.validateIlasNonIlascondition(fnaRequest, array_FNAProduct_productId_List, agentRegApplicableProducts, errors)
    isEmpty = false
    tempErrorHash = Hash.new
    
    array_FNAProduct_productId_List.each do |productRecommended|
      if !agentRegApplicableProducts.include?productRecommended
         MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_ILAS_LICENSE",MobiSys::BrowserHelper.getLabel('ERR_ILAS_LICENSE').force_encoding(Encoding::UTF_8),[])
      end
    end
     if !tempErrorHash.empty?
      errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
      errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
      errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
     end
    return errors
   end
  #Tejashree:22-06-2017: Product Selection Validations code start
  #Ashwini: 05-08-2017: Either of sum assured, Premiums are blannk then thrwow validation on preview and submit Selection tab
    def self.validateProductSelection(fnaRequest, fnaIOSelectedArray, errors)
        isEmpty = false
        tempErrorHash = Hash.new
        fnaRequest_new = FNARequest.loadObject( :first, :conditions => { :object => fnaRequest.object } )
        fnaIOSelected =  fnaRequest.FNAIOSelectedList[0]
        fnaParty = fnaRequest.FNAPartyList[0]

        fnaQuestionResponse = FNAQuestionResponse.find(
            :all,
            :conditions => {
                {:name => 'fnaQuestionCd', :op => 'IN'} => 'FNA_GOAL_DURATION',
                {:name => 'parentKey'} => fnaParty.object
            },
            :op => 'AND',
            :select => ['fnaQuestionCd','fnaQuestionLookupDataCd']
        )
        
        fnaQuestionResponse.each do |fnaQuestionResponse|
            @value_fnaQuestionLookupDataCd = fnaQuestionResponse.fnaQuestionLookupDataCd
        end
        if fnaIOSelected != nil 
            if fnaIOSelectedArray.size == 0
                MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_SELECT_ATLEAST_ONE_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_SELECT_ATLEAST_ONE_PRODUCT').force_encoding(Encoding::UTF_8),[])
            end
            if (fnaRequest.totSumAssured.to_s == "" || fnaRequest.totSumAssured.to_i == 0) && (fnaRequest.addtnField6D.to_s == "" || fnaRequest.addtnField6D.to_i == 0) && (fnaRequest.addtnField7D.to_s == "" || fnaRequest.addtnField7D.to_i == 0)
              MobiSys::CommonUtil.addErrors(tempErrorHash,"ATLEAST_1_PREMIUM_MANDATORY",MobiSys::BrowserHelper.getLabel('ATLEAST_1_PREMIUM_MANDATORY').force_encoding(Encoding::UTF_8),[])
            end
        else
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_SELECT_ATLEAST_ONE_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_SELECT_ATLEAST_ONE_PRODUCT').force_encoding(Encoding::UTF_8),[])
             if (fnaRequest.totSumAssured.to_s == "" || fnaRequest.totSumAssured.to_i == 0) && (fnaRequest.addtnField6D.to_s == "" || fnaRequest.addtnField6D.to_i == 0) && (fnaRequest.addtnField7D.to_s == "" || fnaRequest.addtnField7D.to_i == 0)
              MobiSys::CommonUtil.addErrors(tempErrorHash,"ATLEAST_1_PREMIUM_MANDATORY",MobiSys::BrowserHelper.getLabel('ATLEAST_1_PREMIUM_MANDATORY').force_encoding(Encoding::UTF_8),[])
            end

        end
        #Rule 8.The total regular premium is higher than the analyzed Max regular premium
        #**** Ashwini : Below commented validations are added on Preview during UAT ****** 
        if fnaRequest.addtnField7D !=nil || fnaRequest.addtnField7D != ""
            if fnaRequest.addtnField7D.to_i > fnaRequest_new.addtnField8D.to_i
               MobiSys::CommonUtil.addErrors(tempErrorHash,"LABEL_1_REGULAR_PREMIUM_MAX",MobiSys::BrowserHelper.getLabel('LABEL_1_REGULAR_PREMIUM_MAX').force_encoding(Encoding::UTF_8),[fnaRequest_new.addtnField8D.to_i])
            end
        end

        #Rule 9. #The total single premium is higher than the analyzed
        if fnaRequest.addtnField6D !=nil || fnaRequest.addtnField6D != ""
            if fnaRequest.addtnField6D.to_i > fnaRequest_new.addtnField9D.to_i
               MobiSys::CommonUtil.addErrors(tempErrorHash,"LABEL_1_SINGLE_PREMIUM_MAX",MobiSys::BrowserHelper.getLabel('LABEL_1_SINGLE_PREMIUM_MAX').force_encoding(Encoding::UTF_8),[fnaRequest_new.addtnField9D.to_i])
            end
        end

       

        if !tempErrorHash.empty?
            errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
            errors[:FNAParty][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaRequest.guid.to_sym].is_a?(Hash)
            errors[:FNAParty][fnaRequest.guid.to_sym] = errors[:FNAParty][fnaRequest.guid.to_sym].merge(tempErrorHash)
        end
        return errors
    end

    def self.validateOtherTargetSaving(fnaRequest, errors)
        isEmpty = false
        tempErrorHash = Hash.new
        # fnaOtherTargetSavings =  fnaRequest.FNAOtherTargetNeedList[]
        fnaOtherTargetSavings = FNAOtherTargetNeed.find(
            :all,
            :conditions => {
                {:name => 'parentKey'} => fnaRequest.object
            },
        )
        fnaParty = fnaRequest.FNAPartyList[0]

        fnaOtherTargetSavings.each do |object|
            if object.savingsPeriod == nil || object.savingsPeriod == ""
                MobiSys::CommonUtil.addErrors(tempErrorHash,"savingsPeriod",MobiSys::BrowserHelper.getLabel('ERR_INTEGER').force_encoding(Encoding::UTF_8),[])
            end
            if object.targetSavingAmt == nil || object.targetSavingAmt == ""
                MobiSys::CommonUtil.addErrors(tempErrorHash,"savingsPeriod",MobiSys::BrowserHelper.getLabel('ERR_TARGET_SAVINGS_MANDATORY').force_encoding(Encoding::UTF_8),[])
            end
        end

        if !tempErrorHash.empty?
            errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
            errors[:FNAParty][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaRequest.guid.to_sym].is_a?(Hash)
            errors[:FNAParty][fnaRequest.guid.to_sym] = errors[:FNAParty][fnaRequest.guid.to_sym].merge(tempErrorHash)
        end

        return errors

    end

   #Tejashree:03-July-2017: Reason For Recommendation Validations code start
   def self.validateReasonsForRecommendation(fnaRequest, errors)
    isEmpty = false
    tempErrorHash = Hash.new
    if fnaRequest.addtnField2Str == "" || fnaRequest.addtnField2Str == nil
    else
      if fnaRequest.reasonForRecommendation == "" || fnaRequest.reasonForRecommendation == nil
         MobiSys::CommonUtil.addErrors(tempErrorHash,"reasonForRecommendation",MobiSys::BrowserHelper.getLabel('ERR_6a_OTHERREASON').force_encoding(Encoding::UTF_8),[])
      end
    end

    if !tempErrorHash.empty?
      errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
      errors[:FNAParty][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaRequest.guid.to_sym].is_a?(Hash)
      errors[:FNAParty][fnaRequest.guid.to_sym] = errors[:FNAParty][fnaRequest.guid.to_sym].merge(tempErrorHash)
    end

    return errors
   end

   
   #Ashwini : Check whether products are available on needs selection
    def self.checkProductsExist(fnaRequest,errors)
    p "in checkProductsExist"
    tempErrorHash = Hash.new
      @products_available = [] 
      @fnaIoProductList =  FNAIOProduct.loadObject( :all, :conditions => {'parentKey'=>fnaRequest.object} )
      @fnaIoProductList.each do |products|
        @products_available << products.productRecommended.split(",")
      end
        baseProductList = FNAProduct.find(  
              :all,
              :conditions => {
                { :name => 'guid' ,:op => 'IN' } => @products_available.flatten.uniq,
                { :name => 'productTypeCd' } => "PLAN" 
              },
              :op => 'AND',
              :select => ['productId', 'productTypeCd']
        )
        # if @fnaIoProductList.empty?
        #     MobiSys::CommonUtil.addErrors(tempErrorHash,"NO_PRODS_AVAILABLE_CHOICES",MobiSys::BrowserHelper.getLabel('NO_PRODS_AVAILABLE_CHOICES').force_encoding(Encoding::UTF_8),[])
        # end

        if baseProductList.empty?
            MobiSys::CommonUtil.addErrors(tempErrorHash,"NO_PRODS_AVAILABLE_CHOICES",MobiSys::BrowserHelper.getLabel('NO_PRODS_AVAILABLE_CHOICES').force_encoding(Encoding::UTF_8),[])
        end
       

      if !tempErrorHash.empty?
        errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
      end
      return errors
    end

    def self.validateReasonsForRecommendationForQuestionSelected(fnaRequest,errors)

        tempErrorHash = Hash.new
        if (fnaRequest.reasonForRecoCd.to_s == "" && fnaRequest.addtnField2Str.to_s == "" && fnaRequest.reasonForDeviation.to_s == "")
          MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_6a_6b_UNANS",MobiSys::BrowserHelper.getLabel('ERR_6a_6b_UNANS').force_encoding(Encoding::UTF_8),[])
        end
        fnaRequest_new = FNARequest.loadObject( :first, :conditions => { :object => fnaRequest.object } )

        fnaParty = fnaRequest.FNAPartyList[0]
        @question_responses_list = FNAQuestionResponse.find(
            :all,
            :conditions => {
              {:name => 'fnaQuestionCd', :op => 'IN'} => "FNA_INCOME_PERCENT_FOR_PREMIUM, FNA_AMOUNT_OF_LIQUID_ASSETS, FNA_FUND_SOURCE, FNA_POLICY_TARGET_HORIZON",
              {:name => 'parentKey'} => fnaParty.object
             },
             :op => 'AND',
             :select => ['fnaQuestionLookupDataCd', 'fnaQuestionCd']
        )
            
        #Rule 8.The total regular premium is higher than the analyzed Max regular premium
        #**** Ashwini : Below commented validations are added on Preview during UAT ****** 
        #**** Tejashree : Repetative Code thats why commented ********#
        # if fnaRequest.addtnField7D !=nil || fnaRequest.addtnField7D != ""
        #     if fnaRequest.addtnField7D.to_i > fnaRequest_new.addtnField8D.to_i
        #       MobiSys::CommonUtil.addErrors(tempErrorHash,"LABEL_1_REGULAR_PREMIUM_MAX",MobiSys::BrowserHelper.getLabel('LABEL_1_REGULAR_PREMIUM_MAX').force_encoding(Encoding::UTF_8),[fnaRequest_new.addtnField8D.to_i])
        #     end
        # end

        #Rule 9. #The total single premium is higher than the analyzed
        # if fnaRequest.addtnField6D !=nil || fnaRequest.addtnField6D != ""
        #     if fnaRequest.addtnField6D.to_i > fnaRequest_new.addtnField9D.to_i
        #       MobiSys::CommonUtil.addErrors(tempErrorHash,"LABEL_1_SINGLE_PREMIUM_MAX",MobiSys::BrowserHelper.getLabel('LABEL_1_SINGLE_PREMIUM_MAX').force_encoding(Encoding::UTF_8),[fnaRequest_new.addtnField9D.to_i])
        #     end
        # end

        if !tempErrorHash.empty?
            errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
            errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
            errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
        end
        return errors
    end
   
   #Tejashree:22-06-2017: Basic Details All Validations code start
    def self.validateBasicDetailsAll(fnaParty, errors)
      isValid = true
      responseCheck = true
      tempErrorHash = Hash.new
       if fnaParty.firstName1 == nil || fnaParty.firstName1 == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"firstName1",MobiSys::BrowserHelper.getLabel('ERR_GIVEN_NAME_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.lastName1 == nil || fnaParty.lastName1 == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"lastName1",MobiSys::BrowserHelper.getLabel('ERR_FAMILY_NAME_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.birthDt == nil || fnaParty.birthDt == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"birthDt",MobiSys::BrowserHelper.getLabel('ERR_DOB_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.age != nil || fnaParty.age != "" 
        if fnaParty.age.to_i < 18 && fnaParty.age.to_i != 0
          MobiSys::CommonUtil.addErrors(tempErrorHash,"birthDt",MobiSys::BrowserHelper.getLabel('ERR_AGE_MORETHAN_18').force_encoding(Encoding::UTF_8),[])
        end
      end
      if fnaParty.occupationCd == nil || fnaParty.occupationCd == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"occupationCd",MobiSys::BrowserHelper.getLabel('ERR_OCCUPATION_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.maritalStatusCd == nil || fnaParty.maritalStatusCd == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"maritalStatusCd",MobiSys::BrowserHelper.getLabel('ERR_MARITAL_STATUS_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      if fnaParty.educationLevelCd == nil || fnaParty.educationLevelCd == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"educationLevelCd",MobiSys::BrowserHelper.getLabel('ERR_EDUCATIONLEVEL_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
     #Tejashree Nikam:31-Aug-2017 Address field validation change for alleast one field filled 
      array_address = []
      array_address << fnaParty.addressLine3Lang1
      array_address << fnaParty.addressLine4Lang1
      array_address << fnaParty.addressLine1Lang1
      array_address << fnaParty.addressLine6Lang1
      array_address << fnaParty.addressLine2Lang1
      array_address << fnaParty.addressLine5Lang1
      array_address << fnaParty.countryCd
     
      array_address = array_address.compact 
      array_address = array_address.reject { |e| e.to_s.empty? }
  
      if array_address.size == 0
        MobiSys::CommonUtil.addErrors(tempErrorHash,"addressLine4Lang1",MobiSys::BrowserHelper.getLabel('ERR_RESADDR_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      
      if fnaParty.mobileNum == nil || fnaParty.mobileNum == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"mobileNum",MobiSys::BrowserHelper.getLabel('ERR_CONTACT_NUMBER_MANDATORY').force_encoding(Encoding::UTF_8),[])
      end
      # if fnaParty.emailAddress == nil || fnaParty.emailAddress == ""
      #   MobiSys::CommonUtil.addErrors(tempErrorHash,"emailAddress",MobiSys::BrowserHelper.getLabel('ERR_EMAIL_MANDATORY').force_encoding(Encoding::UTF_8),[])
      # end
      if fnaParty.existingLIDurationCd == nil || fnaParty.existingLIDurationCd == ""
        MobiSys::CommonUtil.addErrors(tempErrorHash,"existingLIDurationCd",MobiSys::BrowserHelper.getLabel('YRSFORINSURANCE').force_encoding(Encoding::UTF_8),[])
      end

        if !tempErrorHash.empty?
          errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
          errors[:FNAParty][fnaParty.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaParty.guid.to_sym].is_a?(Hash)
          errors[:FNAParty][fnaParty.guid.to_sym] = errors[:FNAParty][fnaParty.guid.to_sym].merge(tempErrorHash)
        end
        return errors
    end

    def self.get_response_change_alert(fnaParty,warningErrors)
      warning_Errors_Hash = Hash.new
      MobiSys::CommonUtil.addErrors(warning_Errors_Hash,"WARNING_ERASE_PRODUCT_DATA",MobiSys::BrowserHelper.getLabel('WARNING_ERASE_PRODUCT_DATA').force_encoding(Encoding::UTF_8),[])
        if !warning_Errors_Hash.empty?
          warningErrors[:FNAParty] = Hash.new if !warningErrors[:FNAParty].is_a?(Hash)
          warningErrors[:FNAParty][fnaParty.guid.to_sym] = Hash.new if !warningErrors[:FNAParty][fnaParty.guid.to_sym].is_a?(Hash)
          warningErrors[:FNAParty][fnaParty.guid.to_sym] = warningErrors[:FNAParty][fnaParty.guid.to_sym].merge(warning_Errors_Hash)
        end
        return warningErrors
    end

    #Ashwini : Validate Product Introduced on Preview
    def self.validateProductIntroducedOnPreview(fnaRequest,fnaProposer,products_selected_array,errors)
      tempErrorHash = Hash.new
      warning_temp_hash= Hash.new
      @prod_group = []
      @prod_family = []
      @prod_type_cd = []
      @cause_For_Deviation_q6 = []

      @products_introduced_list = FNAProduct.find(
              :all,
              :conditions => {
                { :name => 'guid', :op => 'IN'} => products_selected_array.flatten.uniq,
               
              },
              :op => 'AND',
              :select => ['productId', 'guid', 'object', 'productTypeCd', 'productFamilyId', 'productGroupName', 'naBenefitTerm']
            )

      if products_selected_array.flatten.uniq.size.to_i > 8
         MobiSys::CommonUtil.addErrors(tempErrorHash,"WARNING_ONLY_5_PRODUCTS_SELECTED",MobiSys::BrowserHelper.getLabel('WARNING_ONLY_5_PRODUCTS_SELECTED').force_encoding(Encoding::UTF_8),[])
      end

   
      @isNaBenefitTermPresent = false
      @products_introduced_list.each do |introduced_products|
        fnaProposer.FNAQuestionResponseList.each do |q_resp|
          if introduced_products.productGroupName == "SEDU"  || introduced_products.productGroupName == "HEDU" 
              if q_resp.fnaQuestionCd == "FNA_FUND_SOURCE"
                  if  q_resp.fnaQuestionLookupDataCd != nil || q_resp.fnaQuestionLookupDataCd != ""
                    if !q_resp.fnaQuestionLookupDataCd.include?"FNAQincome"
                        MobiSys::CommonUtil.addErrors(tempErrorHash,"PT_EXCEEDS_RET_AGE’",MobiSys::BrowserHelper.getLabel('PT_EXCEEDS_RET_AGE').force_encoding(Encoding::UTF_8),[])
                    end
                  end
              end
          end 
          if q_resp.fnaQuestionCd == "FNA_POLICY_TARGET_HORIZON"
              if introduced_products.naBenefitTerm != nil && introduced_products.naBenefitTerm.to_s != ""
               if introduced_products.naBenefitTerm.include?q_resp.fnaQuestionLookupDataCd
                  @isNaBenefitTermPresent = true
                  @cause_For_Deviation_q6 << "Q6b_4"
               end
              end
          end
        end
      end
      
      # 1. Please select 1 more Non-ILAS Product for Product Comparison Purpose.”   ERROR message 
      
        @products_introduced_list.each do |introduced_products|
          if introduced_products.productFamilyId !=nil && introduced_products.productFamilyId != ""
             @prod_family << introduced_products.productFamilyId
          end

          if introduced_products.productTypeCd !=nil && introduced_products.productTypeCd != ""
             @prod_type_cd << introduced_products.productTypeCd
          end

        end

              
        #Ashwini -  Additional CR- If any of the product introduced is ‘ILAS’ then Q1 a and Q1 e should have been selected. 
                    #If not then throw error message.
          if !@prod_family.empty?
            if @prod_family.include?"INVESTLINK"
                fnaProposer.FNAQuestionResponseList.each do |q1a_q1e_resp|
                  if q1a_q1e_resp.fnaQuestionCd == "FNA_PRODUCT_PURPOSE" 
                    q1a_q1e_resp.fnaQuestionLookupDataCd.split(",")
                    if ((q1a_q1e_resp.fnaQuestionLookupDataCd.include?"FNAQfinancialProtection") && (!q1a_q1e_resp.fnaQuestionLookupDataCd.include?"FNAQinvestment"))
                         MobiSys::CommonUtil.addErrors(tempErrorHash,"ILAS_SELECT_1A_1E",MobiSys::BrowserHelper.getLabel('ILAS_SELECT_1A_1E').force_encoding(Encoding::UTF_8),[])
                    end
                    if ((!q1a_q1e_resp.fnaQuestionLookupDataCd.include?"FNAQfinancialProtection") && (q1a_q1e_resp.fnaQuestionLookupDataCd.include?"FNAQinvestment"))
                         MobiSys::CommonUtil.addErrors(tempErrorHash,"ILAS_SELECT_1A_1E",MobiSys::BrowserHelper.getLabel('ILAS_SELECT_1A_1E').force_encoding(Encoding::UTF_8),[])
                    end
                  end  
                end  
            end 
          end

        product_family_list = @prod_family.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

        @check_investLinkcount = 0
         product_family_list.each do |product_family,count|
          if product_family == "INVESTLINK"
              @check_investLinkcount = count
          end
        end


        @checkcount = products_selected_array.flatten.uniq.size.to_i - @check_investLinkcount
          if @checkcount.to_i == 0|| products_selected_array.flatten.uniq.size.to_i == 0
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_1_ILAS_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_1_ILAS_PRODUCT').force_encoding(Encoding::UTF_8),[])
          end

         # Ashwini - Only Rider can not be selected with ILAS Product. Base plan should be selected
          @checkcount = products_selected_array.flatten.uniq.size.to_i - @check_investLinkcount
          if @checkcount.to_i == 0 || products_selected_array.flatten.uniq.size.to_i == 0
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_1_ILAS_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_1_ILAS_PRODUCT').force_encoding(Encoding::UTF_8),[])
          end
          # Ashwini - Only Rider can not be selected with ILAS Product. Base plan should be selected
          @countBasePlanCheck = false
          @countRiderPlanCheck = false
          @countBasePlan = 0
          if @prod_family.include?"INVESTLINK" 
            @products_introduced_list.each do |list| 
              if list.productFamilyId != "INVESTLINK" && list.productTypeCd == "RIDER"
               @countRiderPlanCheck = true 
              elsif list.productFamilyId != "INVESTLINK" && list.productTypeCd == "PLAN"
                @countBasePlanCheck = true 
                break
              end
            end
          end

          if @countBasePlanCheck  == false && @countRiderPlanCheck == true
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_1_ILAS_PRODUCT",MobiSys::BrowserHelper.getLabel('ERR_1_ILAS_PRODUCT').force_encoding(Encoding::UTF_8),[])
          end

        product_type_cd_list = @prod_type_cd.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }
       
        product_type_cd_list.each do |producttypecd,count|
           if producttypecd == "PLAN"
              if count.to_i == 1
                 MobiSys::CommonUtil.addErrors(tempErrorHash,"ATLEAST_2_BASE_PLANS",MobiSys::BrowserHelper.getLabel('ATLEAST_2_BASE_PLANS').force_encoding(Encoding::UTF_8),[])
              end
          end
        end

        # 2. Product(s) with different payment term only is not accepted as Other Insurance Option. - ERROR message
        @products_introduced_list.each do |introduced_products|
          if introduced_products.productGroupName !=nil && introduced_products.productGroupName != ""
            @prod_group << introduced_products.productGroupName
          end
        end
        product_grp_list = @prod_group.each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

        product_grp_list.each do |product,count|
          if count > 1 && @prod_group.uniq.size == 1
            MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_DIFF_PAYMENT_TERM",MobiSys::BrowserHelper.getLabel('ERR_DIFF_PAYMENT_TERM').force_encoding(Encoding::UTF_8),[])
            break
          end
        end

      @agent_Id = AgentReg.getCurrentAgentReg.agentId

      applicableProductsList = AgentReg.find(
                          :all,
                          :conditions => {
                          { :name => 'agentId' } => @agent_Id
                          },
                          :op => 'AND',
                          :select => ['applicableProducts'])

      @agentRegApplicableProducts = applicableProductsList.collect{|x| x.applicableProducts}

      #product matrix logic
      fnaGoalDuration = fnaProposer.getQuestionResponse('FNA_GOAL_DURATION')
      lrm = {}
      #Q4-C
      lrm[:FNA_GOAL_DURATION] = FNAProductMatrix.find(  
              :all,
              :conditions => {
                { :name => 'fnaQuestionCd' }=> 'FNA_GOAL_DURATION',
                { :name => 'fnaQuestionLookupDataCd' }=> fnaGoalDuration.fnaQuestionLookupDataCd
            },
            :op => 'AND',
            :select => ['fnaProductSeq']
      )

      applicableProductSeqList = FNAProduct.find(  
              :all,
              :conditions => {
                { :name => 'productId' ,:op => 'IN' } => @agentRegApplicableProducts.first 
            
             },
             :op => 'AND',
             :select => ['guid']
      )


      @commonProducts = applicableProductSeqList.collect{|x| x.guid} & lrm[:FNA_GOAL_DURATION].collect{|x| x.fnaProductSeq}

      #Q1 Response list - A,B
      fnaQ1Response = fnaProposer.getQuestionResponse('FNA_PRODUCT_PURPOSE')
      fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      @fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Q2 Response list - B,C
      fnaQ2Response = fnaProposer.getQuestionResponse('FNA_PRODUCT_TYPE')
      @fnaQ2ResponseList = fnaQ2Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Iterate over Q1 response list to get the recommended products
      @resulthash={}
      isLessThanOne = true
      isLessThanOne_q2 = true
      collectCounts_q1 = {}
      collectCounts_q2 = {}

      @fnaQ1ResponseList.each do |q1Response|
          lrm[:FNA_PRODUCT_PURPOSE] = FNAProductMatrix.find(
            :all,
            :conditions => {
              { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_PURPOSE',
              { :name => 'fnaQuestionLookupDataCd' } => q1Response.to_s
                       },
            :op => 'AND',
            :select => ['fnaProductSeq']
          )
          #Find recommended products of Q1 which are present in Q4-C
          @common = lrm[:FNA_PRODUCT_PURPOSE].collect{|x| x.fnaProductSeq} 
          #check if introduced products are present in @common of each Q1 respomse.
          @count_q1_products = 0
          products_selected_array.flatten.each do |product|
            if @common.include?product
              @count_q1_products = @count_q1_products + 1
            end
          end


        collectCounts_q1[q1Response] = @count_q1_products

        # Warning Hash - 3. "There are some needs of the client not addressed according to the current products introduced. Do you wish to continue?”  WARNING
         @count_of_q1_products = []
        if collectCounts_q1 != ""
          collectCounts_q1.each do |q2_option, product_count|
            @count_of_q1_products << product_count
          end
        end

        if @count_of_q1_products.include?0
            # MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_NOT_INTRODUCED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_NOT_INTRODUCED').force_encoding(Encoding::UTF_8),[])
            @cause_For_Deviation_q6 << "Q6b_1"
        end

      end
        @count_q2_products = 0
        @q2_products = []
        @fnaQ2ResponseList.each do |q2Response|
           @resulthash[:FNA_PRODUCT_TYPE] =  FNAProductMatrix.find(
            :all,
            :conditions => {
              { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_TYPE',
              { :name => 'fnaQuestionLookupDataCd' } => q2Response.to_s
              # { :name => 'fnaProductSeq', :op => 'IN' } => @common
            },
            :op => 'AND',
            :select => ['fnaProductSeq']
           )

             @productsList = @resulthash[:FNA_PRODUCT_TYPE].collect{|x| x.fnaProductSeq}

              @count_q2_products = 0
              products_selected_array.flatten.each do |product|
                if @productsList.include?product
                  @count_q2_products = @count_q2_products + 1
                end
              end
              collectCounts_q2[q2Response] = @count_q2_products
        end

       
        # Warning Hash - 3. "There are some needs of the client not addressed according to the current products introduced. Do you wish to continue?”  WARNING
        @count_of_q2_products = []
        if collectCounts_q2 != ""
          collectCounts_q2.each do |q2_option, product_count|
            @count_of_q2_products << product_count
          end
        end

        if @count_of_q2_products.include?0
            # MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_NOT_INTRODUCED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_NOT_INTRODUCED').force_encoding(Encoding::UTF_8),[])
        end

        collectCounts_q1.each do |q1_response, product_introduced|
          if product_introduced > 1
             isLessThanOne = false

             break
          end
        end
          
      if isLessThanOne == true
        MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_MEET_1_OBJ",MobiSys::BrowserHelper.getLabel('ERR_MEET_1_OBJ').force_encoding(Encoding::UTF_8),[])
      end

      # 4. Warning q1-- There are some needs of the current products introduced exceeded the client needs. Do you wish to continue?
      @responses_against_q1 = FNAProductMatrix.find(
                          :all,
                          :conditions => {
                            { :name => 'fnaProductSeq', :op => 'IN'} => products_selected_array.flatten,
                            { :name => 'fnaQuestionCd', :op => 'IN'} => "FNA_PRODUCT_PURPOSE"
                          },
                          :op => 'AND',
                          :select => ['fnaProductSeq', 'fnaQuestionCd', 'fnaQuestionLookupDataCd', 'productTypeCd']
                        )
      @fna_q1_Question_Responses = []

      fnaProposer.FNAQuestionResponseList.each do |responses|
          if responses.fnaQuestionCd == "FNA_PRODUCT_PURPOSE"
              @fna_q1_Question_Responses << responses.fnaQuestionLookupDataCd.split(",")
          end
      end

      @options_against_q1_list =[]
      @client_introduced_resp_needs_for_q1 = []

      @responses_against_q1.each do |key|
        @options_against_q1_list << key.fnaQuestionLookupDataCd
      end


      @client_introduced_resp_needs_for_q1 << @options_against_q1_list.uniq

      # @client_introduced_resp_needs_for_q1.first.each do |q1_resp|
      #   if !@fna_q1_Question_Responses.flatten.include?q1_resp
      #       # MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_EXCEEDED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_EXCEEDED').force_encoding(Encoding::UTF_8),[])
      #       @cause_For_Deviation_q6 << "Q6b_1"
      #   end
      # end

      #5. Warning q2-- There are some needs of the current products introduced exceeded the client needs. Do you wish to continue?
      @responses_against_q2 = FNAProductMatrix.find(
                          :all,
                          :conditions => {
                            { :name => 'fnaProductSeq', :op => 'IN'} => products_selected_array.flatten,
                            { :name => 'fnaQuestionCd', :op => 'IN'} => "FNA_PRODUCT_TYPE"
                          },
                          :op => 'AND',
                          :select => ['fnaProductSeq', 'fnaQuestionCd', 'fnaQuestionLookupDataCd', 'productTypeCd']
                        )
    
      @fna_q2_Question_Responses = []

      fnaProposer.FNAQuestionResponseList.each do |responses|
          if responses.fnaQuestionCd == "FNA_PRODUCT_TYPE"
              @fna_q2_Question_Responses << responses.fnaQuestionLookupDataCd.split(",")
          end
      end

      @options_against_q2_list =[]
      @client_introduced_resp_needs_for_q2 = []

      @responses_against_q2.each do |key|
        @options_against_q2_list << key.fnaQuestionLookupDataCd
      end


      @client_introduced_resp_needs_for_q2 << @options_against_q2_list.uniq

      @client_introduced_resp_needs_for_q2.first.each do |q2_resp|
        if !@fna_q2_Question_Responses.flatten.include?q2_resp
             # MobiSys::CommonUtil.addErrors(warning_temp_hash,"ERR_NEEDS_EXCEEDED",MobiSys::BrowserHelper.getLabel('ERR_NEEDS_EXCEEDED').force_encoding(Encoding::UTF_8),[])
             @cause_For_Deviation_q6 << "Q6b_1"
              
        end
      end

      if !tempErrorHash.empty?
        errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
      end

        
        if @cause_For_Deviation_q6 != nil
          @cause_For_Deviation_q6_uniq = @cause_For_Deviation_q6.uniq
        else 
          @cause_For_Deviation_q6_uniq = nil
        end
        
        return errors, @cause_For_Deviation_q6_uniq, @isNaBenefitTermPresent
    end
    

    #Tejashree:11-09-2017: Withdrawn Product Validation
    def self.validatewithdrawnproduct(fnaCopied, array_FNAProduct_productId_List, errors)
        isEmpty = false
        tempErrorHash = Hash.new
        
        @date = Date.parse(Time.now.to_s)
        array_FNAProduct_productId_List.each do |withdrawndt|
        if withdrawndt.to_s != ""
        @date2 = Date.parse(withdrawndt.to_s)
        if @date2 <= @date
            MobiSys::CommonUtil.addErrors(tempErrorHash,"SIGN_DATE_NOT_AFTER_WITHDRAWN_DATE",MobiSys::BrowserHelper.getLabel('SIGN_DATE_NOT_AFTER_WITHDRAWN_DATE').force_encoding(Encoding::UTF_8),[])
        end
        end
      end
        if !tempErrorHash.empty?
            errors[:FNAParty] = Hash.new if !errors[:FNAParty].is_a?(Hash)
            errors[:FNAParty][fnaCopied.guid.to_sym] = Hash.new if !errors[:FNAParty][fnaCopied.guid.to_sym].is_a?(Hash)
            errors[:FNAParty][fnaCopied.guid.to_sym] = errors[:FNAParty][fnaCopied.guid.to_sym].merge(tempErrorHash)
        end


        return errors
    end


    def self.validateSignatures(fnaRequest,errors)
        tempErrorHash = Hash.new
        if fnaRequest.applicantSignature.to_s == "" && fnaRequest.applicantSignDt.to_s == "" 
             MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_APPLICANT_SIGN_1 ",MobiSys::BrowserHelper.getLabel('ERR_APPLICANT_SIGN_1 ').force_encoding(Encoding::UTF_8),[])
        end
        if fnaRequest.agentSignature.to_s == "" && fnaRequest.agentSignDt.to_s == ""
             MobiSys::CommonUtil.addErrors(tempErrorHash,"ERR_CONSULTANT_SIGN_1",MobiSys::BrowserHelper.getLabel('ERR_CONSULTANT_SIGN_1').force_encoding(Encoding::UTF_8),[])
        end

        if !tempErrorHash.empty?
        errors[:FNARequest] = Hash.new if !errors[:FNARequest].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = Hash.new if !errors[:FNARequest][fnaRequest.guid.to_sym].is_a?(Hash)
        errors[:FNARequest][fnaRequest.guid.to_sym] = errors[:FNARequest][fnaRequest.guid.to_sym].merge(tempErrorHash)
       end
       return errors
    end

    def self.validateFNAData(fnaRequest, errors)
      isValid = true
      tempErrorHash = Hash.new
      fnaRequestAdditionalList = fnaRequest.FNARequestAdditionalList
      otherFiel4Blank = false
      demoList = []
      if fnaRequestAdditionalList && fnaRequestAdditionalList.size > 0
        count = 0
        fnaRequestAdditionalList.each do |fnaReqAddtnl|
          if fnaReqAddtnl.field2.to_s != ""
            if fnaReqAddtnl.field1.to_s == "FNA_Q1PartA_option8" && fnaReqAddtnl.field4.to_s == ""
              MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaReqAddtnl.guid}-field4", "ERR_MANDATORY", "ERR_MANDATORY", nil, [MobiSys::BrowserHelper.getLabel('field4otherSpec')])
              isValid = false
            end
            demoList.push(fnaReqAddtnl.field2);
            count += 1
          end
        end
        if (count == 0)
          MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequest.guid}-UNIQUEfields", "ERR_CSA_PRIORITY", "ERR_CSA_PRIORITY", nil, [])
          isValid = false
        else
          duplicateNum = ""
          dupArray = []
          demoList.each do |dl|
            dupArray << dl.to_i
          end

          for i in 0...(dupArray.length)
            for j in (i + 1)...(dupArray.length)
              if dupArray[i] == dupArray[j]
                if duplicateNum.to_s == ""
                  duplicateNum = dupArray[j].to_s
                else
                  duplicateNum += "," + dupArray[j].to_s
                end
              end
            end
          end

          if duplicateNum.to_s != ''
            fnaRequest.FNARequestAdditionalList.each do |fnaReqAddtnl|
              if fnaReqAddtnl.field2.to_s != '' && duplicateNum.include?(fnaReqAddtnl.field2.to_s)
                MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaReqAddtnl.guid}-field2", "ERR_UNIQUEVALUE", "ERR_UNIQUEVALUE", nil, [])
                isValid = false
              end
            end
          end

          if (count > 3)
            MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequestAdditionalList[0].guid}-UNIQUEfields", "ERR_CSA_PRIORITY_MAX", "ERR_CSA_PRIORITY_MAX", nil, [])
            isValid = false
          end
        end
      else
        MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequest.guid}-UNIQUEfields", "ERR_CSA_PRIORITY", "ERR_CSA_PRIORITY", nil, [])
          isValid = false
      end
      return isValid
    end

    def self.validateFundData(fnaRequest, errors)
      isValid = true
      tempErrorHash = Hash.new

      isRPQApplicable = MobiSys::FNARequestService.isRPQApplicable(fnaRequest)
      companyColor = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
      companyColorValue = companyColor.value.to_s if companyColor

      if isRPQApplicable
        listFNAFundDO = fnaRequest.FNAFundList
        if listFNAFundDO == nil || listFNAFundDO.size == 0
          MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequest.guid}-UNIQUEfields", "ERR_MANDATORYFUNDS", "ERR_MANDATORYFUNDS", nil, [])
          isValid = false
        elsif listFNAFundDO.size > 0
          count = 0
          totalAllocation = 0
          listFNAFundDO.each do |fund|
            if fund.allocationPerc.to_s != ""
              count += 1
              if totalAllocation.to_f == 0.0
                totalAllocation = fund.allocationPerc.to_f
              else
                totalAllocation = totalAllocation.to_f + fund.allocationPerc.to_f
              end
            end
          end
          if count > 10 && companyColorValue.to_s == 'SLGFI'
            MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequest.guid}-UNIQUEfields", "ERR_FUNDCOUNT", "ERR_FUNDCOUNT", nil, [])
            isValid = false
          end

          if totalAllocation == 0.0
            isValid = false
            MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{fnaRequest.guid}-UNIQUEfields", "ERR_MANDATORYFUNDS", "ERR_MANDATORYFUNDS", nil, [])
          elsif totalAllocation < 100.0
            isValid = false
            MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{listFNAFundDO[0].guid}-allocationPerc", "ERR_INVESTMENTPERCENTAGE_CSA", "ERR_INVESTMENTPERCENTAGE_CSA", nil, ["Fund allocation", totalAllocation.to_i.to_s])
          elsif totalAllocation > 100.0
            isValid = false
            MobiSys::CommonUtil.registerException(fnaRequest.guid, "#{listFNAFundDO[0].guid}-allocationPerc", "ERR_INVESTMENTPERCENTAGE_CSA", "ERR_INVESTMENTPERCENTAGE_CSA", nil, ["Fund allocation", totalAllocation.to_i.to_s])
          end

        end
      end

      return isValid
    end

    def self.validateRPQData(fnaRequest, errors)
      isValid = true
      maxAdvisorFunds = CompanyFacet.find(:first, :conditions => {:facetCd => "MAXADVISORFUNDS"})
      advisorFundSize = maxAdvisorFunds.actionValue.to_i if maxAdvisorFunds
      maxClientFunds = CompanyFacet.find(:first, :conditions => {:facetCd => "MAXADVISORFUNDS"})
      clientFundSize = maxClientFunds.actionValue.to_i if maxClientFunds
      # companyColour = $rhoconfig[:companyColour]
      companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
      leadRPQ = LeadRPQ.loadObject(:first, :conditions => {:rpqID => fnaRequest.addtnField1Str})
      
      if leadRPQ && leadRPQ.education.to_s != '' && (companyColour.to_s != "" && companyColour.value.to_s == "SLOCPI")
        fundList = leadRPQ.education.split(",")
        if fundList.size > advisorFundSize.to_i
          MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-education", "ERR_RANGE", "ERR_RANGE", nil, [MobiSys::BrowserHelper.getLabel('CSAeducation'), advisorFundSize.to_s])
          isValid = false
        end
      end

      if leadRPQ && leadRPQ.incomeGroup.to_s != '' && (companyColour.to_s != "" && companyColour.value.to_s == "SLOCPI")
        clientFundList = leadRPQ.incomeGroup.split(",")
        if clientFundList.size > clientFundSize.to_i
          MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-incomeGroup", "ERR_RANGE", "ERR_RANGE", nil, [MobiSys::BrowserHelper.getLabel('CSAincomeGroup'), clientFundSize.to_s])
          isValid = false
        end
      end

      if leadRPQ && leadRPQ.rpqScore.to_s != ''
        if leadRPQ.rpqScore.to_i <= 0
          MobiSys::CommonUtil.registerException(leadRPQ.guid, "#{leadRPQ.guid}-rpqScore", "ERR_MANDATORYFORRISKSCORE", "ERR_MANDATORYFORRISKSCORE", nil, [])
          isValid = false
        end
      end
      return isValid
    end

  end #FnaBO class
end   #Module
require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'FNARequest/fna_b_o'
require 'CommonModules/commonutil'
require 'rho/rhoevent.rb'
require 'date'
require 'time'
require 'CommonModules/mobisysuihelper_jazz'
require 'FNARequest/UIGenUtilFNA'
require 'CommonClasses/FnaIO'
require 'Policy/PolicyUtil'

class FNARequestController < Rho::RhoController
  include BrowserHelper
  include MobiSys::BrowserHelper
  include MobiSys::UIHelper

      @@variablesave = nil
      # $prewFlag = "abc"
      def thosandSeperator(number)
        parts = number.to_s.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,") if parts.size > 0
        parts.join('.')
      end

    def settingValue
        @@variablesave = @params['saveMarketingInfoFl']
    end

    def newFNA
        $flagQ3 = true
        $flagQ3New = true
        $flagProductIntro = true
        $flagProductIntroNew = true
        WebView.execute_js("showLoadingMessage()")
        $currentLanguageCode =  Application.getValue('DEFAULTLOCALE').value
        @fnaRequest = FNARequest.new
        @fnaProposer = FNAParty.new(:partyRoleCd => "PROPOSER")
        #$total_error = Hash.new
        @fnaRequest.addFNAParty(@fnaProposer)
        @agentRegdetails = AgentReg.getCurrentAgentReg
        @fnaRequest = setAgentDetails(@fnaRequest, @agentRegdetails)
        @fnaRequest.requestDt = Time.now
        @fnaRequest.statusCd = "FNAPENDING"
        @fnaRequest.addtnField1Str = "FNAPENDING"
        $ShowFlag = ""
        @fnaRequest.marketingInfoFl = @@variablesave
        @@variablesave = nil
        @fnaRequest.fnaNum = nil
        # //Tejashree: 01-Nov-2017 - For Link FNA Popup
        if @params['quotationId'] .to_s != ""
            @quotation = Quotation.loadObject( :first, :conditions => { :object => @params['quotationId'] } )
            @policyholder = @quotation.getPartyByRole("PROPOSER")
            @fnaProposer.firstName1 = @policyholder.firstname
            @fnaProposer.lastName1 = @policyholder.lastname
            @fnaProposer.age = @policyholder.age
            @fnaProposer.birthDt = @policyholder.dob
            @fnaProposer.mobileNum = @policyholder.contactNum
            @fnaProposer.emailAddress = @policyholder.emailAddress
        end
        @fnaRequest.persist
        render :action => :FNACapture, :layout => :sunlifeHKLayout
    end


    # Added by teja on 5th April 2017 for pics tab start
    def newFNAPics
        WebView.execute_js("showLoadingMessage()")
        @fnaRequest = FNARequest.new
        @fnaProposer = FNAParty.new(:partyRoleCd => "PROPOSER")
        render :action => :Pics, :layout => :sunlifeHKLayout
    end

    def getHandwrittenNote
        # WebView.execute_js("showLoadingMessage()")
        html =""
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        html << render(:partial => 'FNAHand_Written_Note')
        return html
    end

    def submitHandWrittenNote
        fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
        fnaRequest.persist
    end

    # Added by vaibhav on 18th April 2017 for pics tab start
    def submitPicsPage
        fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
        fnaRequest.persist
    end


    # Added by Vaibhav on 11th April 2017 for DECLARATION tab start
    def getDeclaration
        if @params['id'].include? ('{')
          id = @params['id'][1..-1].chop
        else
          id = @params['id']
        end
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaRequest.applicantSignDt = getScreenDate(@fnaRequest.applicantSignDt) if @fnaRequest.applicantSignDt != nil || @fnaRequest.applicantSignDt != ""
        @fnaRequest.agentSignDt = getScreenDate(@fnaRequest.agentSignDt) if @fnaRequest.agentSignDt != nil || @fnaRequest.agentSignDt != ""
        @pageLanguage = Application.getValue('DEFAULTLOCALE').value

        html = ""
        html << render(:partial => 'FNADeclaration')
        return html
    end

    def submitDeclaration
        @error_exist= false
        fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
        fnaRequest.marketingInfoFl = nil unless fnaRequest.marketingInfoFl
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => fnaRequest.object } )
        @array_productIntroduced = []
        @fnaRequest.FNAIOProductList.each do |fnaIoProduct|
            @array_productIntroduced << fnaIoProduct.productIntroduced
        end
        @array_productIntroduced = @array_productIntroduced.flatten
        @array_productIntroduced = @array_productIntroduced.compact
        @array_productIntroduced_new = []
        @array_productIntroduced.each do |productIntroduced|
            @array_productIntroduced_new << productIntroduced.split(",")
        end
        @array_productIntroduced_new = @array_productIntroduced_new.flatten
        @array_productIntroduced_new = @array_productIntroduced_new.compact
        @FNAProduct_productId_List = FNAProduct.find(
            :all,
            :conditions => {
                {:name => 'id', :op => 'IN'} =>  @array_productIntroduced_new
                },
                :op => 'AND',
                :select => ['withdrawDt']
            )
        @array_FNAProduct_productId_List = []
        @FNAProduct_productId_List.each do |productId|
            @array_FNAProduct_productId_List << productId.withdrawDt
        end
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.flatten
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.compact
        errors = {}
        errors1 = Hash.new
        errors = MobiSys::FnaBO.validatewithdrawnproduct(@fnaRequest, @array_FNAProduct_productId_List, errors1)
        # errors.empty? ? $total_error.reject!{ |k| k == 'esignature' }  : $total_error['esignature'] = errors

        if errors.empty?
            @error_exist = false
            if fnaRequest.applicantSignature != nil && fnaRequest.agentSignature != nil && fnaRequest.applicantSignature.to_s != '' && fnaRequest.agentSignature.to_s != '' && fnaRequest.agentSignDt != nil && fnaRequest.applicantSignDt != nil && fnaRequest.agentSignDt.to_s != '' && fnaRequest.applicantSignDt.to_s != ''
                fnaRequest.statusCd= "FNASIGNED"
                fnaRequest.addtnField1Str = "FNASIGNED"
                fnaRequest.versionID = fnaRequest.versionID.to_i + 1
                fnaRequest.persist
            end
        else
          @error_exist = true
        end
        render :string => @error_exist.to_json
    end

    # Tejashree : added needs tab and it's submit method with the calculations
    def getNeeds
      if @params['id'].include? ('{')
        id = @params['id'][1..-1].chop
      else
        id = @params['id']
      end
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end
      @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )

        if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
          @fnaLifeProtectionNeed = FNALifeProtectionNeed.new
          @fnaRequest.addFNALifeProtectionNeed(@fnaLifeProtectionNeed)
        end
      if @fnaLifeProtectionNeed.CalculatorTypeCd == 'CALCTYPECOMPLEX'
        @fnaEducationNeed = FNAEducationNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
        if @fnaEducationNeed == nil || @fnaEducationNeed == ""
          @fnaEducationNeed = FNAEducationNeed.new
          @fnaRequest.addFNAEducationNeed(@fnaEducationNeed)
        end

        if @fnaLifeProtectionNeed.existingCoverageAmt && @fnaLifeProtectionNeed.existingAssetAmt
           @totalCurrentCapital = @fnaLifeProtectionNeed.existingAssetAmt.to_i + @fnaLifeProtectionNeed.existingCoverageAmt.to_i
           @totalofLumpSumInvestment = 0
           @totalcapitalneed = @fnaLifeProtectionNeed.protectionNeedPVAmt.to_i + @fnaLifeProtectionNeed.otherLiabilitiesAmt.to_i + @totalofLumpSumInvestment.to_i  + @fnaLifeProtectionNeed.educationNeedPVAmt.to_i

        else
           @totalCurrentCapital = 0
           @totalcapitalneed = 0
           @educationNeedFVAmt = 0
           @educationFundFVAmt = 0
           @shortFallChildEducation = 0
           # @fnaLifeProtectionNeed.shortfallAmt = 0
        end
        html = ""
        html << render(:partial => 'FNALife_Protection_Need')
        return html
      else

        #########################################################################
        html = ""
        html << render(:partial => 'FNALife_Protection_Need_ShortV')
        return html
      end
    end

    def previewtab
     @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
     redirect :action => :executePreview, :id => @fnaRequest.object.to_s
    end

    def getNeedsclear
     @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
     FNALifeProtectionNeed.delete_all(:conditions=>{'parentKey'=> @params['id']})
     redirect :action => :getNeedsLargeV, :id => @fnaRequest.object.to_s
    end

    def getNeedsLargeVclear
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      FNALifeProtectionNeed.delete_all(:conditions=>{'parentKey'=> @params['id']})
      FNAEducationNeed.delete_all(:conditions=>{'parentKey'=> @params['id']})
      redirect :action => :getNeeds, :id => @fnaRequest.object.to_s
    end

    def getNeedsLargeV
      if @params['id'].include? ('{')
        id = @params['id'][1..-1].chop
      else
        id = @params['id']
      end
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

      @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => {:parentKey => @fnaRequest.object } )
      @fnaEducationNeed = FNAEducationNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
      if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
        @fnaLifeProtectionNeed = FNALifeProtectionNeed.new
        @fnaRequest.addFNALifeProtectionNeed(@fnaLifeProtectionNeed)
      end

      if @fnaEducationNeed == nil || @fnaEducationNeed == ""
        @fnaEducationNeed = FNAEducationNeed.new
        @fnaRequest.addFNAEducationNeed(@fnaEducationNeed)
      end

      if @fnaLifeProtectionNeed.existingCoverageAmt && @fnaLifeProtectionNeed.existingAssetAmt
         @totalCurrentCapital = @fnaLifeProtectionNeed.existingAssetAmt.to_i + @fnaLifeProtectionNeed.existingCoverageAmt.to_i
         @totalofLumpSumInvestment = 0
         @totalcapitalneed = @fnaLifeProtectionNeed.protectionNeedPVAmt.to_i + @fnaLifeProtectionNeed.otherLiabilitiesAmt.to_i + @totalofLumpSumInvestment.to_i + @fnaLifeProtectionNeed.educationNeedPVAmt.to_i
      else
         @totalCurrentCapital = 0
         @totalcapitalneed = 0
         @educationNeedFVAmt = 0
         @educationFundFVAmt = 0
         @shortFallChildEducation = 0
      end
      html = ""
      html << render(:partial => 'FNALife_Protection_Need')
      return html
    end

    def calculateFnaLifeProtectionNeed
      if @params["inflationRate"] == "" || @params["inflationRate"] == nil
        @inflationRate = 0
      else
        @inflationRate = @params["inflationRate"]
      end
      if @params["returnRate"] == "" || @params["returnRate"] == nil
        @returnRate = 0
      else
        @returnRate = @params["returnRate"]
      end
      if @params["montlyExpenseAmt"] == "" || @params["montlyExpenseAmt"] == nil
        @montlyExpenseAmt = 0
      else
        @montlyExpenseAmt = @params["montlyExpenseAmt"]
      end
      if @params["expenseYears"] == "" || @params["expenseYears"] == nil
        @expenseYears = 0
      else
        @expenseYears = @params["expenseYears"]
      end
      if @params["otherLiabilitiesAmt"] == "" || @params["otherLiabilitiesAmt"] == nil
        @otherLiabilitiesAmt = 0
      else
        @otherLiabilitiesAmt = @params["otherLiabilitiesAmt"]
      end
      if @params["totalCurrentCapital"] == "" || @params["totalCurrentCapital"] == nil
        @totalCurrentCapital = 0
      else
        @totalCurrentCapital = @params["totalCurrentCapital"]
      end
      if @params["educationNeedPVAmt"] == "" || @params["educationNeedPVAmt"] == nil
        @educationNeedPVAmt = 0
      else
        @educationNeedPVAmt = @params["educationNeedPVAmt"]
      end
      if @params["existingAssetAmt"] == "" || @params["existingAssetAmt"] == nil
        @existingAssetAmt = 0
      else
        @existingAssetAmt = @params["existingAssetAmt"]
      end
      if @params["existingCoverageAmt"] == "" || @params["existingCoverageAmt"] == nil
        @existingCoverageAmt = 0
      else
        @existingCoverageAmt = @params["existingCoverageAmt"]
      end

      @realmonthlyrate = (100.to_f * ( ( 1 + ( ( 1 + ( @returnRate.to_f/ 100.to_f ) ) ** ( 1 /12.to_f ) - 1 ) ) / ( 1 + ( ( 1 + ( @inflationRate.to_f/ 100.to_f ) ) ** ( 1 /12.to_f ) - 1 ) ) - 1 ) )

      if @realmonthlyrate.to_f == 0
          @e = 12 * @expenseYears.to_f
      else
          @e = ( ( 1 - ( 1 / ( 1 + ( @realmonthlyrate.to_f  / 100.to_f ) ) ) ** ( @expenseYears.to_f * 12.to_f ) ) / ( 1 - ( 1 / ( 1 + ( @realmonthlyrate.to_f  / 100.to_f ) ) ) ) )
      end

      @protectionNeedPVAmt = (@montlyExpenseAmt.to_i *  @e).round

      @totalofLumpSumInvestment = 0

      @totalcapitalneed = @protectionNeedPVAmt.to_i + @otherLiabilitiesAmt.to_i + @totalofLumpSumInvestment.to_i + @educationNeedPVAmt.to_i

      @totalCurrentCapital =  @existingAssetAmt.to_i + @existingCoverageAmt.to_i

      @shortFallLifeProtection = @totalcapitalneed.to_i - @totalCurrentCapital.to_i

      if @shortFallLifeProtection < 0
        @shortFallLifeProtection = 0
      end

       returnStr = @protectionNeedPVAmt.to_s + "|" + @totalcapitalneed.to_s + "|" + @totalCurrentCapital.to_s + "|" + @shortFallLifeProtection.to_s

       render :string => returnStr.to_json
    end

    # Tejashree : submit Life Protection Need
    def submitFnaLifeProtectionNeed
      @error_exist= false
      $total_error = Hash.new
      @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
      @fnaRequest.persist
      @changeLifeNeedShortV = @params['changeLifeNeedShortV']
      @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => {:object => @fnaRequest.object} )

        if @changeLifeNeedShortV == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end

      @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
      errors = {}

        errors1 = Hash.new


          if @fnaLifeProtectionNeed.CalculatorTypeCd != 'CALCTYPECOMPLEX'
          errors = MobiSys::FnaBO.validateLifeProtectionNeed(@fnaRequest, errors1)
          else
          errors =MobiSys::FnaBO.validateLifeProtectionNeedComplex(@fnaRequest, errors1)
          end

        errors.empty? ? $total_error.reject!{ |k| k == 'LifeProtectionNeed' }  : $total_error['LifeProtectionNeed'] = errors
            if errors.empty?
                @error_exist = false
                $total_error = Hash.new
            else
                @error_exist = true
            end

        render :string => @error_exist.to_json
    end


    def healthNeeds
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      @fnaOtherProtectionNeed = FNAOtherProtectionNeed.find( :first, :conditions => { :parentKey => @fnaRequest.object } )
      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

      if @fnaOtherProtectionNeed == nil
        @fnaOtherProtectionNeed = FNAOtherProtectionNeed.new
        @fnaRequest.addFNAOtherProtectionNeed(@fnaOtherProtectionNeed)
      end
       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end


      @HIncomeShortFall = @fnaOtherProtectionNeed.hincomeNeededAmt.to_i -  @fnaOtherProtectionNeed.hincomeCoveredAmt.to_i
      if @HIncomeShortFall < 0
         @HIncomeShortFall = 0
       end
      @HInsuranceShortFall =  @fnaOtherProtectionNeed.hinsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.hinsuranceCoveredAmt.to_i
       if @HInsuranceShortFall < 0
         @HInsuranceShortFall = 0
       end
      @SFBShortFall = @fnaOtherProtectionNeed.sfbNeededAmt.to_i - @fnaOtherProtectionNeed.sfbCoveredAmt.to_i
       if @SFBShortFall < 0
         @SFBShortFall = 0
       end
      @CIInsuranceShortFall = @fnaOtherProtectionNeed.ciInsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.ciInsuranceCoveredAmt.to_i
       if @CIInsuranceShortFall < 0
         @CIInsuranceShortFall = 0
       end
      @ADDInsuranceShortFall = @fnaOtherProtectionNeed.addInsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.addInsuranceCoveredAmt.to_i
       if @ADDInsuranceShortFall < 0
         @ADDInsuranceShortFall = 0
       end

      @NeededAmt = @fnaOtherProtectionNeed.hincomeNeededAmt.to_i + @fnaOtherProtectionNeed.hinsuranceNeededAmt.to_i + @fnaOtherProtectionNeed.sfbNeededAmt.to_i + @fnaOtherProtectionNeed.ciInsuranceNeededAmt.to_i + @fnaOtherProtectionNeed.addInsuranceNeededAmt.to_i

      @CoveredAmt = @fnaOtherProtectionNeed.hincomeCoveredAmt.to_i + @fnaOtherProtectionNeed.hinsuranceCoveredAmt.to_i + @fnaOtherProtectionNeed.sfbCoveredAmt.to_i + @fnaOtherProtectionNeed.ciInsuranceCoveredAmt.to_i + @fnaOtherProtectionNeed.addInsuranceCoveredAmt.to_i

      @ShortFall = @NeededAmt.to_i -  @CoveredAmt.to_i
      if @ShortFall < 0
        @ShortFall = 0
       end
      html = ""
      html << render(:partial => 'FNAHealth_Protection_Need')
      return html
    end

    def calculateFnaHealthProtectionNeed
      @hincomeNeededAmt = @params["hincomeNeededAmt"]
      @hincomeCoveredAmt = @params["hincomeCoveredAmt"]
      @HIncomeShortFall = @params["HIncomeShortFall"]

      @hinsuranceNeededAmt = @params["hinsuranceNeededAmt"]
      @hinsuranceCoveredAmt = @params["hinsuranceCoveredAmt"]
      @HInsuranceShortFall = @params["HInsuranceShortFall"]

      @sfbNeededAmt = @params["sfbNeededAmt"]
      @sfbCoveredAmt = @params["sfbCoveredAmt"]
      @SFBShortFall = @params["SFBShortFall"]

      @ciInsuranceNeededAmt = @params["ciInsuranceNeededAmt"]
      @ciInsuranceCoveredAmt = @params["ciInsuranceCoveredAmt"]
      @CIInsuranceShortFall = @params["CIInsuranceShortFall"]

      @addInsuranceNeededAmt = @params["addInsuranceNeededAmt"]
      @addInsuranceCoveredAmt = @params["addInsuranceCoveredAmt"]
      @ADDInsuranceShortFall = @params["ADDInsuranceShortFall"]

      @NeededAmt = @hincomeNeededAmt.to_i + @hinsuranceNeededAmt.to_i + @sfbNeededAmt.to_i + @ciInsuranceNeededAmt.to_i + @addInsuranceNeededAmt.to_i


      @CoveredAmt = @hincomeCoveredAmt.to_i + @hinsuranceCoveredAmt.to_i + @sfbCoveredAmt.to_i + @ciInsuranceCoveredAmt.to_i + @addInsuranceCoveredAmt.to_i

      @ShortFall = @NeededAmt.to_i - @CoveredAmt.to_i
      if @ShortFall < 0
        @ShortFall = 0
      end

      returnStr = @NeededAmt.to_s + "|" + @CoveredAmt.to_s + "|" + @ShortFall.to_s

      render :string => returnStr.to_json
    end


    def submitFnaOtherProtectionNeed
      @params.delete("TOTAL_EXPECTED_COVERAGE")
      @params.delete("TOTAL_EXISTING_COVERAGE")
      @params.delete("MEDICAL_SHORTFALL")

      @params.delete("HINCOME_SHORTFALL_RISK_PROT_NEEDS")
      @params.delete("HINSURANCE_SHORTFALL_RISK_PROT_NEEDS")
      @params.delete("SFB_SHORTFALL_RISK_PROT_NEEDS")
      @params.delete("CIINSURANCE_SHORTFALL_RISK_PROT_NEEDS")
      @params.delete("ADDINSURANCE_SHORTFALL_RISK_PROT_NEEDS")
      @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
      @changeHealthNeed = @params['changeHealthNeed']
      @fnaRequest.persist

       @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
        if @changeHealthNeed == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end
    end

    def retirementNeeds
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaRetirementNeed = FNARetirementNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
        if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
        end
        if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
         @fnaRequest.returnRate = 4
        end
        @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
        if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
          @fnaRequest.persist
        end

        if @fnaRetirementNeed == nil || @fnaRetirementNeed == ""
            @fnaRetirementNeed = FNARetirementNeed.new
            @fnaRequest.addFNARetirementNeed(@fnaRetirementNeed)
            @fnaRetirementNeed.monthlySavingsReqdAmt = 0
            @fnaRetirementNeed.lumsumReqdAmt = 0
            @fnaRetirementNeed.monthlyExpensesFVAmt = 0
            @fnaRetirementNeed.totRetirementNeedAmt = 0
            @fnaRetirementNeed.totFutureContributionAmt = 0
            @fnaRetirementNeed.totAccumulatedAmt = 0
            @fnaRetirementNeed.totOtherSavingsAmt = 0
            @fnaRetirementNeed.totOtherLumpSumAmt = 0
        end

        if @fnaRetirementNeed.totRetirementNeedAmt
            @totRetirementNeedAmt = @fnaRetirementNeed.totRetirementNeedAmt
        else
            @totRetirementNeedAmt = 0
        end

        @projectedMRFfundatretire = @fnaRetirementNeed.totFutureContributionAmt.to_i + @fnaRetirementNeed.totAccumulatedAmt.to_i
        @projectedLumpSumAmt = @fnaRetirementNeed.totOtherSavingsAmt.to_i + @fnaRetirementNeed.totOtherLumpSumAmt.to_i
        @shortfall = @totRetirementNeedAmt.to_i -  @projectedMRFfundatretire.to_i - @projectedLumpSumAmt.to_i

        if @shortfall < 0
            @shortfall = 0
        end

        @yearstoretire = @fnaRetirementNeed.retirementAge.to_i - @fnaRetirementNeed.currentAge.to_i
        if @yearstoretire < 0
          @yearstoretire = 0
        end
        @expectedretperiod = @fnaRetirementNeed.retirementAge.to_i
        if @expectedretperiod < 0
          @expectedretperiod = 0
        end

        if @expectedretperiod != nil
            @expectedretperiod1 = @fnaRetirementNeed.ageExpectancy.to_i - @expectedretperiod.to_i
            if @expectedretperiod1 < 0
                @expectedretperiod1 = 0
            end
        end

        html = ""
        html << render(:partial => 'FNARetirement_Planning')
        return html
    end


    def calculateFnaRetirementPlanningNeeds
        if @params["inflationRate"] == "" || @params["inflationRate"] == nil
            @inflationRate = 0
        else
            @inflationRate = @params["inflationRate"]
        end
        if @params["returnRate"] == "" || @params["returnRate"] == nil
            @returnRate = 0
        else
            @returnRate = @params["returnRate"]
        end
        if @params["monthlyExpensesPVAmt"] == "" || @params["monthlyExpensesPVAmt"] == nil
            @monthlyExpensesPVAmt = 0
        else
            @monthlyExpensesPVAmt = @params["monthlyExpensesPVAmt"]
        end
        if @params["currentAge"] == "" || @params["currentAge"] == nil
            @currentAge = 0
        else
            @currentAge = @params["currentAge"]
        end
        if @params["yearstoretire"] == "" || @params["yearstoretire"] == nil
            @yearstoretire = 0
        else
            @yearstoretire = @params["yearstoretire"]
        end
        if @params["expectedretperiod"] == "" || @params["expectedretperiod"] == nil
            @expectedretperiod = 0
        else
            @expectedretperiod = @params["expectedretperiod"]
        end
        if @params["futureContributionAmt"] == "" || @params["futureContributionAmt"] == nil
            @futureContributionAmt = 0
        else
            @futureContributionAmt = @params["futureContributionAmt"]
        end
        if @params["futureContributionRate"] == "" || @params["futureContributionRate"] == nil
            @futureContributionRate = 0
        else
            @futureContributionRate = @params["futureContributionRate"]
        end
        if @params["accumulatedAmt"] == "" || @params["accumulatedAmt"] == nil
            @accumulatedAmt = 0
        else
            @accumulatedAmt = @params["accumulatedAmt"]
        end
        if @params["accumulatedRate"] == "" || @params["accumulatedRate"] == nil
            @accumulatedRate = 0
        else
            @accumulatedRate = @params["accumulatedRate"]
        end
        if @params["otherMontlySavingsAmt"] == "" || @params["otherMontlySavingsAmt"] == nil
            @otherMontlySavingsAmt = 0
        else
            @otherMontlySavingsAmt = @params["otherMontlySavingsAmt"]
        end
        if @params["otherMontlySavingsRate"] == "" || @params["otherMontlySavingsRate"] == nil
            @otherMontlySavingsRate = 0
        else
            @otherMontlySavingsRate = @params["otherMontlySavingsRate"]
        end
        if @params["otherLumpsumAmt"] == "" || @params["otherLumpsumAmt"] == nil
            @otherLumpsumAmt = 0
        else
            @otherLumpsumAmt = @params["otherLumpsumAmt"]
        end
        if @params["otherLumpsumRate"] == "" || @params["otherLumpsumRate"] == nil
            @otherLumpsumRate = 0
        else
            @otherLumpsumRate = @params["otherLumpsumRate"]
        end

        @mothlyretirementexpenses = (@monthlyExpensesPVAmt.to_f * ( 1 + ( @inflationRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f ).round

        @mothlyretirementexpenses2 = (@monthlyExpensesPVAmt.to_f * ( 1 + ( @inflationRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f )

        @realmonthlyrate = 100.to_f * ( ( 1 + ( ( 1 + ( @returnRate.to_f / 100.to_f ) ) ** ( 1 /12.to_f ) - 1 ) ) / ( 1 + ( ( 1 + ( @inflationRate.to_f / 100.to_f ) ) ** ( 1 /12.to_f ) - 1 ) ) - 1 )

        if @realmonthlyrate == 0
            @e = 12 *  @expectedretperiod.to_f
        else
            @e = ( ( 1 - ( 1 / ( 1 + ( @realmonthlyrate.to_f  / 100.to_f ) ) ) ** ( @expectedretperiod.to_f * 12.to_f  ) ) / ( 1 - ( 1 / ( 1 + ( @realmonthlyrate.to_f  / 100.to_f ) ) ) ) )
        end

        @totalretirementneeds =  (@mothlyretirementexpenses2 *  @e).round

        if @futureContributionRate == nil || @futureContributionRate == ""
            @totalmonthlyMRFfuturecontribution = 0
		    elsif @futureContributionRate.to_f == 0.0
		    @totalmonthlyMRFfuturecontribution = ( @futureContributionAmt.to_f * 12.to_f * @yearstoretire.to_f ).round
        else
            # if @currentAge.to_i + @yearstoretire.to_i + @expectedretperiod.to_i > 60
                @totalmonthlyMRFfuturecontribution  = ( @futureContributionAmt.to_f * ( ( ( 1 + ( @futureContributionRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f - 1 ) / ( ( 1 + (  @futureContributionRate.to_f / 100.to_f ) ) ** ( 1 / 12.to_f ) - 1 ) * ( 1 + ( @futureContributionRate.to_f / 100.to_f ) ) ** ( 1/ 12.to_f ) ) ).round
            # else
            #     @totalmonthlyMRFfuturecontribution = 0
            # end
        end

        # if  @currentAge.to_i + @yearstoretire.to_i + @expectedretperiod.to_i > 60
            @totalmonthlyMRFaccumulatedvalue = (@accumulatedAmt.to_f * ( 1 + ( @accumulatedRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f ).round
        # else
        #     @totalmonthlyMRFaccumulatedvalue = 0
        # end

        @projectedMRFfundatretire = @totalmonthlyMRFaccumulatedvalue.to_i + @totalmonthlyMRFfuturecontribution.to_i

        if @otherMontlySavingsRate.to_f == 0.0
           @totOtherSavingsAmt = ( @otherMontlySavingsAmt.to_f * 12.to_f * @yearstoretire.to_f ).round
        else
            @totOtherSavingsAmt = ( @otherMontlySavingsAmt.to_f * ( ( ( 1 + ( @otherMontlySavingsRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f - 1 ) / ( ( 1 + ( @otherMontlySavingsRate.to_f / 100.to_f ) ) ** ( 1.to_f / 12.to_f ) - 1 ) * ( 1 + ( @otherMontlySavingsRate.to_f / 100.to_f ) ) ** ( 1.to_f / 12.to_f ) ) ).round
        end

        @totOtherLumpSumAmt = ( @otherLumpsumAmt.to_f * ( 1 + ( @otherLumpsumRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f ).round

        @projectedLumpSumAmt = @totOtherSavingsAmt.to_i + @totOtherLumpSumAmt.to_i

        @shortfall = @totalretirementneeds.to_i - @projectedMRFfundatretire.to_i -  @projectedLumpSumAmt.to_i

        if @shortfall < 0
            @shortfall = 0
        end

        if @yearstoretire.to_i == 0
            @monthlysavingsrequired = 0
        elsif @returnRate.to_f == 0.0
            @monthlysavingsrequired = ( @shortfall.to_f / ( 12.to_f * @yearstoretire.to_f ) ).round
        else
            @monthlysavingsrequired = ( ( @shortfall.to_f * ( ( 1 + @returnRate.to_f / 100.to_f ) ** ( 1.to_f / 12.to_f ) - 1 ) ) / ( ( 1 + @returnRate.to_f / 100.to_f ) ** ( 1.to_f / 12.to_f ) ) / ( ( ( 1 + @returnRate.to_f / 100.to_f ) ** ( 1.to_f / 12.to_f ) ) ** ( 12.to_f * @yearstoretire.to_f ) - 1 ) ).round
        end

        @lumpsuminvestmentrequired = ( @shortfall.to_f / ( 1 + ( @returnRate.to_f / 100.to_f ) ) ** @yearstoretire.to_f ).round

        returnStr = @mothlyretirementexpenses.to_s + "|" + @totalretirementneeds.to_s + "|" + @totalmonthlyMRFfuturecontribution.to_s + "|" + @totalmonthlyMRFaccumulatedvalue.to_s + "|" + @projectedMRFfundatretire.to_s + "|" + @totOtherSavingsAmt.to_s + "|" + @totOtherLumpSumAmt.to_s + "|" + @projectedLumpSumAmt.to_s + "|" + @shortfall.to_s + "|" + @monthlysavingsrequired.to_s + "|" +
        @lumpsuminvestmentrequired.to_s

        render :string => returnStr.to_json
    end


    def submitFNARetirementNeed
      @params["FNARequest"]["FNAParty"]["0"].delete("AGE_EXPECTANCY")
      @params["FNARequest"]["FNARetirementNeed"]["1"].delete("AGE_EXPECTANCY")
      @params.delete("AGE_EXPECTANCY")
      @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
      @changeRetirementNeed = @params['changeRetirementNeed']
      @fnaRequest.persist
      @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
        if @changeRetirementNeed == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end
    end

    def otherTargetSaving
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end
      # @fnaOtherTargetNeed = FNAOtherTargetNeed.loadObject( :all, :conditions => { :parentKey => @fnaRequest.object } )
      @fnaOtherTargetNeed = FNAOtherTargetNeed.find( :all, :conditions => { :parentKey => @fnaRequest.object } )
      if @fnaOtherTargetNeed == nil || @fnaOtherTargetNeed == "" || @fnaOtherTargetNeed.size == 0
        fnaOtherTargetNeed = FNAOtherTargetNeed.new
        @fnaOtherTargetNeed << fnaOtherTargetNeed
        @fnaRequest.addFNAOtherTargetNeed(fnaOtherTargetNeed)
       else
        @currnet_shortfall = []
        @mothly_saving_shortfall = []
        @lumpsum_investment_shortfall = []
        @fnaOtherTargetNeed.each do |fnaothrtarneed|
           @currnet_shortfall << fnaothrtarneed.targetSavingAmt if fnaothrtarneed.targetSavingAmt.to_s != ""
           @mothly_saving_shortfall << fnaothrtarneed.monthlySavingsReqdAmt if fnaothrtarneed.monthlySavingsReqdAmt.to_s != ""
           @lumpsum_investment_shortfall << fnaothrtarneed.lumsumReqdAmt if fnaothrtarneed.lumsumReqdAmt.to_s != ""
        end
      if @currnet_shortfall.empty?
      else
      @totalcurrentshortfall = @currnet_shortfall.inject(0){|sum,x| sum + x }
      end
      if @mothly_saving_shortfall.empty?
      else
      @totalmonthlysavingsshortfall = @mothly_saving_shortfall.inject(0){|sum,x| sum + x }
      end
      if @lumpsum_investment_shortfall.empty?
      else
      @totallumpsuminvshortfall = @lumpsum_investment_shortfall.inject(0){|sum,x| sum + x }
      end
      end
      html = ""
      html << render(:partial => 'FNAOther_Target_saving')
      return html
    end

    def additionalgoalTabs
      id = @params.fetch("object")
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
      fnaProposer = @fnaRequest.getParty("PROPOSER")
      @fnaOtherTargetNeed = FNAOtherTargetNeed.new
      @fnaRequest.addFNAOtherTargetNeed(@fnaOtherTargetNeed)
      html = ""
      html << render(:partial => 'FNAOther_Target_Saving_Need_Additional_GoalsAdd')
      return html
    end

    def calculateotherTargetSaving
        @TargetSavingAmtArry = @params["selectedtargetSavingAmt"]
        @SavingsPeriodArry = @params["selectedsavingsPeriod"]
        if @params["returnRate"] == "" || @params["returnRate"] == nil
            @returnRate = 0
        else
            @returnRate = @params["returnRate"]
        end

        if @params["inflationRate"] == "" || @params["inflationRate"] == nil
            @inflationRate = 0
        else
            @inflationRate = @params["inflationRate"]
        end

        @array_final = []
        @array_sum_monthlysavingrequired = []
        @array_sum_lumpsuminvestementrequired = []

        if (@TargetSavingAmtArry.size == 1 && @TargetSavingAmtArry[0].to_i == 0) || (@SavingsPeriodArry.size == 0 && @SavingsPeriodArry[0].to_i == 0)
            @monthlysavingrequired = 0
            @lumpsuminvestementrequired = 0
        else
            @SavingsPeriodArry.zip(@TargetSavingAmtArry).each do |savingsPeriod, targetSavingAmt|
                if @returnRate.to_f == 0.0
                    @monthlysavingrequired = ( targetSavingAmt.to_f / ( 12.to_f * savingsPeriod.to_f ) ).round
                    @array_final << @monthlysavingrequired
                    @array_sum_monthlysavingrequired << @monthlysavingrequired if @monthlysavingrequired.to_s != ""

                    @lumpsuminvestementrequired =  (targetSavingAmt.to_f / (( 1 + ( @returnRate.to_f / 100 ) ) ** savingsPeriod.to_f)).round
                    @array_sum_lumpsuminvestementrequired << @lumpsuminvestementrequired
                    @array_final << @lumpsuminvestementrequired if @lumpsuminvestementrequired.to_s != ""

                elsif savingsPeriod.to_i == 0
                    @monthlysavingrequired = 0
                    @array_final << @monthlysavingrequired
                    @array_sum_monthlysavingrequired << @monthlysavingrequired if @monthlysavingrequired.to_s != ""

                    @lumpsuminvestementrequired =  (targetSavingAmt.to_f / (( 1 + ( @returnRate.to_f / 100 ) ) ** savingsPeriod.to_f)).round
                    @array_sum_lumpsuminvestementrequired << @lumpsuminvestementrequired
                    @array_final << @lumpsuminvestementrequired if @lumpsuminvestementrequired.to_s != ""

                else
                    @monthlysavingrequired =  ((targetSavingAmt.to_f * ( ( 1 + ( @returnRate.to_f / 100.to_f ) ) ** ( 1 / 12.to_f ) - 1 ) ) / ( ( 1 + ( @returnRate.to_f / 100.to_f  ) ) ** ( 1 / 12.to_f  ) ) / ( ( ( 1 + ( @returnRate.to_f / 100.to_f  ) ) ** ( 1 / 12.to_f ) ) ** ( 12 * savingsPeriod.to_f ) - 1 )).round
                    @array_final << @monthlysavingrequired
                    @array_sum_monthlysavingrequired << @monthlysavingrequired if @monthlysavingrequired.to_s != ""

                    @lumpsuminvestementrequired =  (targetSavingAmt.to_f / (( 1 + ( @returnRate.to_f / 100 ) ) ** savingsPeriod.to_f)).round
                    @array_sum_lumpsuminvestementrequired << @lumpsuminvestementrequired
                    @array_final << @lumpsuminvestementrequired if @lumpsuminvestementrequired.to_s != ""
                end
            end
        end

        @currnet_shortfall = 0

        @TargetSavingAmtArry.each do |tarsav|
            @currnet_shortfall = @currnet_shortfall.to_i + tarsav.to_i
        end


        if @array_sum_monthlysavingrequired.empty?
        else
            @mothly_saving_shortfall = @array_sum_monthlysavingrequired.inject(0){|sum,x| sum + x }
        end

        if @array_sum_lumpsuminvestementrequired.empty?
        else
            @lumpsum_investment_shortfall = @array_sum_lumpsuminvestementrequired.inject(0){|sum,x| sum + x }
        end

        returnStr =  @array_final.to_s + "|" + @currnet_shortfall.to_s + "|" + @mothly_saving_shortfall.to_s + "|" + @lumpsum_investment_shortfall.to_s

        render :string => returnStr.to_json
    end

    def submitFNAOtherTargetNeed
      FNAOtherTargetNeed.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object']})
      @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
      @fnaRequest.persist
      @changeOtherNeed = @params['changeOtherNeed']
      @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
        if @changeOtherNeed == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end
    end

    def shortfallSummary
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      @fnaRetirementNeed = FNARetirementNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
      @fnaOtherProtectionNeed = FNAOtherProtectionNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
      @fnaOtherTargetNeed = FNAOtherTargetNeed.loadObject( :all, :conditions => { :parentKey => @fnaRequest.object } )
      @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )
      @fnaEducationNeed = FNAEducationNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object } )

     if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
         @montlyExpenseAmt = 0
         @shortfallAmt = 0
      else
       if @fnaLifeProtectionNeed.CalculatorTypeCd == 'CALCTYPECOMPLEX'
          if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
             @totalCurrentCapital = 0
             @totalcapitalneed = 0
             @educationNeedFVAmt = 0
             @educationFundFVAmt = 0
             @shortFallChildEducation = 0
             @shortFallLifeProtection = 0
          else
             @totalCurrentCapital = @fnaLifeProtectionNeed.existingAssetAmt.to_i + @fnaLifeProtectionNeed.existingCoverageAmt.to_i
             @totalofLumpSumInvestment = 0
             @totalcapitalneed = @fnaLifeProtectionNeed.protectionNeedPVAmt.to_i + @fnaLifeProtectionNeed.otherLiabilitiesAmt.to_i + @totalofLumpSumInvestment.to_i + @fnaLifeProtectionNeed.educationNeedPVAmt.to_i
             @shortFallLifeProtection =  @totalcapitalneed.to_i - @totalCurrentCapital.to_i
              if @shortFallLifeProtection < 0
                @shortFallLifeProtection = 0
              end
          end
      else
             if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
              @montlyExpenseAmt = 0
              @shortfallAmt = 0
            else
                if @fnaLifeProtectionNeed.montlyExpenseAmt.to_i < 0
                   @montlyExpenseAmt = 0
                else
                @montlyExpenseAmt = @fnaLifeProtectionNeed.montlyExpenseAmt
                end
                if @fnaLifeProtectionNeed.shortfallAmt.to_i < 0
                   @shortfallAmt = 0
                else
                @shortfallAmt = @fnaLifeProtectionNeed.shortfallAmt
                end
            end
        end


      end

      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
         @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

      if @fnaRetirementNeed == nil || @fnaRetirementNeed == ""
          @totRetirementNeedAmt = 0
          @projectedMRFfundatretire = 0
          @projectedLumpSumAmt = 0
          @shortfall = 0
          @yearstoretire = 0
          @expectedretperiod = 0
          @expectedretperiod1 = 0
      else
          @totRetirementNeedAmt = @fnaRetirementNeed.totRetirementNeedAmt
          @projectedMRFfundatretire = @fnaRetirementNeed.totFutureContributionAmt.to_i + @fnaRetirementNeed.totAccumulatedAmt.to_i
          @projectedLumpSumAmt = @fnaRetirementNeed.totOtherSavingsAmt.to_i + @fnaRetirementNeed.totOtherLumpSumAmt.to_i
          @shortfall = @totRetirementNeedAmt.to_i -  @projectedMRFfundatretire.to_i - @projectedLumpSumAmt.to_i
          if @shortfall.to_i < 0
            @shortfall = 0
          end
          @yearstoretire = @fnaRetirementNeed.retirementAge.to_i - @fnaRetirementNeed.currentAge.to_i
          @expectedretperiod = @fnaRetirementNeed.currentAge.to_i
          if @expectedretperiod != nil
             @expectedretperiod1 = 85 - @expectedretperiod.to_i
          end
      end


      if @fnaOtherProtectionNeed == nil || @fnaOtherProtectionNeed == ""
          @HIncomeShortFall = 0
          @HInsuranceShortFall = 0
          @SFBShortFall = 0
          @CIInsuranceShortFall = 0
          @ADDInsuranceShortFall = 0
          @NeededAmt = 0
          @CoveredAmt = 0
          @ShortFall = 0
          @hincomeNeededAmt = 0
          @hincomeCoveredAmt = 0
          @sfbNeededAmt = 0
          @sfbCoveredAmt =  0
          @ciInsuranceNeededAmt = 0
          @ciInsuranceCoveredAmt = 0
          @addInsuranceNeededAmt = 0
          @addInsuranceCoveredAmt = 0
          @hinsuranceNeededAmt = 0
          @hinsuranceCoveredAmt = 0

      else
          @hincomeNeededAmt= @fnaOtherProtectionNeed.hincomeNeededAmt
          @hincomeCoveredAmt = @fnaOtherProtectionNeed.hincomeCoveredAmt
          @hinsuranceNeededAmt = @fnaOtherProtectionNeed.hinsuranceNeededAmt
          @hinsuranceCoveredAmt = @fnaOtherProtectionNeed.hinsuranceCoveredAmt
          @sfbNeededAmt = @fnaOtherProtectionNeed.sfbNeededAmt
          @sfbCoveredAmt = @fnaOtherProtectionNeed.sfbCoveredAmt
          @ciInsuranceNeededAmt = @fnaOtherProtectionNeed.ciInsuranceNeededAmt
          @ciInsuranceCoveredAmt =  @fnaOtherProtectionNeed.ciInsuranceCoveredAmt
          @addInsuranceNeededAmt =  @fnaOtherProtectionNeed.addInsuranceNeededAmt
          @addInsuranceCoveredAmt = @fnaOtherProtectionNeed.addInsuranceCoveredAmt

          @HIncomeShortFall = @fnaOtherProtectionNeed.hincomeNeededAmt.to_i -  @fnaOtherProtectionNeed.hincomeCoveredAmt.to_i
          if @HIncomeShortFall.to_i < 0
            @HIncomeShortFall = 0
          end
          @HInsuranceShortFall =  @fnaOtherProtectionNeed.hinsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.hinsuranceCoveredAmt.to_i
          if @HInsuranceShortFall.to_i < 0
            @HInsuranceShortFall = 0
          end
          @SFBShortFall = @fnaOtherProtectionNeed.sfbNeededAmt.to_i - @fnaOtherProtectionNeed.sfbCoveredAmt.to_i
          if @SFBShortFall.to_i < 0
            @SFBShortFall = 0
          end
          @CIInsuranceShortFall = @fnaOtherProtectionNeed.ciInsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.ciInsuranceCoveredAmt.to_i
          if @CIInsuranceShortFall.to_i < 0
            @CIInsuranceShortFall = 0
          end
          @ADDInsuranceShortFall = @fnaOtherProtectionNeed.addInsuranceNeededAmt.to_i - @fnaOtherProtectionNeed.addInsuranceCoveredAmt.to_i
          if @ADDInsuranceShortFall.to_i < 0
            @ADDInsuranceShortFall = 0
          end
        end

        if @fnaOtherTargetNeed == nil || @fnaOtherTargetNeed == ""

          @totalcurrentshortfall = 0
          @totalmonthlysavingsshortfall = 0
          @totallumpsuminvshortfall = 0

        else
          @currnet_shortfall = []
          @mothly_saving_shortfall = []
          @lumpsum_investment_shortfall = []
          @fnaOtherTargetNeed.each do |fnaothrtarneed|
             @currnet_shortfall << fnaothrtarneed.targetSavingAmt if fnaothrtarneed.targetSavingAmt.to_s != ""
             @mothly_saving_shortfall << fnaothrtarneed.monthlySavingsReqdAmt if fnaothrtarneed.monthlySavingsReqdAmt.to_s != ""
             @lumpsum_investment_shortfall << fnaothrtarneed.lumsumReqdAmt if fnaothrtarneed.lumsumReqdAmt.to_s != ""
          end
          if @currnet_shortfall.empty?
             @totalcurrentshortfall = 0
          else
          @totalcurrentshortfall = @currnet_shortfall.inject(0){|sum,x| sum + x }
          end
          if @mothly_saving_shortfall.empty?
            @totalmonthlysavingsshortfall = 0
          else
          @totalmonthlysavingsshortfall = @mothly_saving_shortfall.inject(0){|sum,x| sum + x }
          end
          if @lumpsum_investment_shortfall.empty?
             @totallumpsuminvshortfall = 0
          else
          @totallumpsuminvshortfall = @lumpsum_investment_shortfall.inject(0){|sum,x| sum + x }
          end
        end

        html = ""
        html << render(:partial => 'FNAShortfall_Summary')
        return html
    end

   ####################################################################

    # Vaibhav Kumawat (15-09-2017) : added method to linking FNA to SI
    def LinkToSI
      @productAndRiders = []
      @str = ""
      @productAndRiders.push(@params['productSeq'])
      @str << @params['id'].to_s

	    @fnaProductCode = []

	    fnaIOSelectedList = FNAIOSelected.find(:all, :conditions => { :fnaBaseProductRefGuid => @params['productSeq'].to_s, :parentKey => @params['id'].to_s }  )
        fnaIOSelectedList.each do |fnaIOSelectedObject|
            if fnaIOSelectedObject.selectedFlag == "on" && fnaIOSelectedObject.fnaRiderProductRefGuid != nil
                @productAndRiders.push(fnaIOSelectedObject.fnaRiderProductRefGuid)
            end
            if fnaIOSelectedObject.selectedFlag == "on" && fnaIOSelectedObject.fnaRiderProductRefGuid == nil
                @str << "|" <<  fnaIOSelectedObject.guid
            end
        end

        @productAndRiders.each do |element|
            product = FNAProduct.find(:first, :conditions => { :id => element })
            @fnaProductCode.push(product.productId)
            @str << "|" << product.productId
        end

        basePlan = FNAProduct.find(:first, :conditions => { :id => @productAndRiders[0] })
        fnaSIProduct = FNASIProductLink.find( :first,  :conditions => { :fnaProductId => basePlan.productId } )

        if fnaIOSelectedList[0].to_s != "" && fnaSIProduct.configuredAs.to_s != "NA"
            WebView.navigate("#{url_for :controller=> :Quotation, :action => :newCaptureIllustration, :query => { :fnaId => @str.to_s } }")
        elsif fnaSIProduct.configuredAs.to_s == "NA"
            Alert.show_popup({
                :message => getLabelValue('NA_FOR_SI'),
                :title => '',
                :buttons => [getLabelValue('OK')]
            })
        end
    end

   ####################################################################

    # Tejashree : added policy number tab and it's submit method on 01-June-2017
    def getPolicyNo
        @noOfPolicy = 5
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaPolicyLink = FNAPolicyLink.find( :all, :conditions => { :parentKey => @fnaRequest.object } )
        if @fnaPolicyLink.size == 0 || @fnaPolicyLink == "" || @fnaPolicyLink == nil || @fnaPolicyLink.size <  @noOfPolicy.to_i
            (@noOfPolicy.to_i-@fnaPolicyLink.size).times do |i|
                setObjectCount(@fnaRequest, i+1)
                setObjectMapping(@fnaRequest, @fnaRequest.class.name)
                fnaPlo = FNAPolicyLink.new
                @fnaPolicyLink << fnaPlo
                @fnaRequest.addFNAPolicyLink(fnaPlo)
            end
        end
        html = ""
        html << render(:partial => 'FNAPolicy_Number')
        return html
    end

    def submitPolicyNumber
        @error_exist= false

        @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
        @fnaRequest.persist

        FNAPolicyLink.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object'], 'policyNum' => ""})

        @fnaPolicyLink = FNAPolicyLink.find( :all, :conditions => { :parentKey => @fnaRequest.object } )

        @policyarray =[]
        @fnaPolicyLink.each do |policy|
        @policyarray << policy.policyNum if policy.policyNum.to_s!=""
        end

        errors = {}

        errors1 = Hash.new
        errors = MobiSys::FnaBO.validatePolicyDetails(@fnaRequest, @policyarray, errors1)
        errors.empty? ? $total_error.reject!{ |k| k == 'policyNo' }  : $total_error['policyNo'] = errors

            if errors.empty?
                @error_exist = false
                $total_error = Hash.new
            else
                @error_exist = true
            end

        render :string => @error_exist.to_json
    end

    ####################################################################

    # updated by Vaibhav on 18th April 2017 for basic Details tab start
    # Ashwini : get Basic details Tab
    def getBasicDetails
      $selected_tab = 'getBasicDetails' #set the current tab
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      if @fnaRequest.inflationRate == nil ||  @fnaRequest.inflationRate == ""
        @fnaRequest.inflationRate = 3
      end
      if @fnaRequest.returnRate == nil ||  @fnaRequest.returnRate == ""
        @fnaRequest.returnRate = 4
      end
      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaProposer.birthDt = getScreenDate(@fnaProposer.birthDt) if @fnaProposer.birthDt != nil || @fnaProposer.birthDt != ""
        @occupationlist = Array.new
        nodLookups  = {}

        nodLookups  = Lookupvalue.find(
                            :all,
                            :order => "key",
                            :orderdir => 'ASC',
                            :conditions => {
                                { :name=>'key' } => 'OCCUPATIONTITLE'
                            },
                        )

        nodLookups.each do |nod|
            @occupationlist << Lookupvalue.new(:cd => nod.cd, :desc => getLabelValue(nod.desc))
        end

        if @fnaRequest.fnaNum.to_s != ""
          $fnaNumclone = @fnaRequest.fnaNum
        else
          $fnaNumclone = nil
        end
        valueOfQ3 = FNAQuestionResponse.find(
                            :all,
                            :conditions => {
                              {:name=>'fnaQuestionCd'} => 'FNA_POLICY_TARGET_HORIZON'
                                },
                            :op => 'AND',
                            :select => ['fnaQuestionLookupDataCd']
                            )

        valueOfQ3.each do |q3_val|
            $lookupdataCdQ3 = q3_val.fnaQuestionLookupDataCd
        end

        html = ""
        html << render(:partial => 'FNAProposer')

        return html
    end

    # Ashwini : Submit Basic details Tab
    def submitBasicDetails
      @error_exist= false
      @warnings_exist = false
      @changeStatusCd = @params['changeStatusCd']
      @basicTabOnSave = @params['basicTabOnSave']

      @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest',@params['FNARequest'])
      fnaParty = @fnaRequest.FNAPartyList[0]
      responseChange = false
      responseChangeOfQ3 = false

      fnaParty.FNAQuestionResponseList.each do |fnaQuestionResponse|
        if "FNA_PRODUCT_PURPOSE,FNA_PRODUCT_TYPE,FNA_GOAL_DURATION".include? fnaQuestionResponse.fnaQuestionCd.to_s
          responseChangeObj= FNAQuestionResponse.find(
             :first,
                  :conditions => {
                    { :name => 'object'} => fnaQuestionResponse.object,
                    { :name => 'fnaQuestionLookupDataCd'} => fnaQuestionResponse.fnaQuestionLookupDataCd.to_s
                  },
          )
          responseChange = true if responseChangeObj == nil
        end
      end

      fnaParty.FNAQuestionResponseList.each do |fnaQuestionResponse|
        if "FNA_POLICY_TARGET_HORIZON".include? fnaQuestionResponse.fnaQuestionCd.to_s
          responseChangeObj= FNAQuestionResponse.find(
             :first,
                  :conditions => {
                    { :name => 'object'} => fnaQuestionResponse.object,
                    { :name => 'fnaQuestionLookupDataCd'} => fnaQuestionResponse.fnaQuestionLookupDataCd
                  },
          )
          # responseChange = true if responseChangeObj == nil && fnaQuestionResponse.fnaQuestionLookupDataCd.to_s != ""
          responseChangeOfQ3 = true if responseChangeObj == nil
        end
      end

      fnaParty.FNAQuestionResponseList.each do |fnaQuestionResponse|
        if fnaQuestionResponse.fnaQuestionCd == "FNA_GOAL_DURATION"
           if fnaQuestionResponse.fnaQuestionLookupDataCd.to_s == ""
              responseChange = false
           end
        end
        if fnaQuestionResponse.fnaQuestionCd == "FNA_POLICY_TARGET_HORIZON"
            if fnaQuestionResponse.fnaQuestionLookupDataCd.to_s == ""
              responseChangeOfQ3 = false
           end
        end
      end


      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
      if @fna_req_status.include?@statusCd
           responseChange = false
           responseChangeOfQ3 = false
      end

      if responseChange == true || responseChangeOfQ3 == true
        $derivedCauseForDeviationValues = nil
      end


      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      @fnaRequest.consentFl = "off" unless @fnaRequest.consentFl

        @fnaProposer.FNAQuestionResponseList.each do |resp|
          resp.fnaRequestRefGuid = @fnaRequest.guid
          resp.fnaPartyRefGuid = @fnaProposer.guid
          resp.responseValue = nil unless resp.responseValue
        end

         @fnaQuestionResponseListCheck =  FNAQuestionResponse.loadObject(:all, :conditions => {'parentKey'=>fnaParty.object})

        if @fnaQuestionResponseListCheck.empty?
          responseChange = false
          responseChangeOfQ3 = false
        end

      @fnaRequest.persist

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
      fnaGoalDuration = @fnaProposer.getQuestionResponse('FNA_GOAL_DURATION')


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
                { :name => 'productId' ,:op => 'IN' } => @agentRegApplicableProducts.first,

             },
             :op => 'AND',
             :select => ['guid','launchDt', 'withdrawDt']
      )


      products_valid = []
      applicableProductSeqList.each do |fna_prod|
        launch_date = Date.parse(fna_prod.launchDt.to_s)
        system_date = Date.parse(Time.now.to_s)
        if fna_prod.withdrawDt.to_s != ""
          withdrawn_date = Date.parse(fna_prod.withdrawDt.to_s)

            products_valid << fna_prod.guid if withdrawn_date > system_date  && launch_date <= system_date
        else
            products_valid << fna_prod.guid if launch_date <= system_date
        end
      end


      @commonProducts = products_valid & lrm[:FNA_GOAL_DURATION].collect{|x| x.fnaProductSeq}

      #Q1 Response list - A,B
      fnaQ1Response = @fnaProposer.getQuestionResponse('FNA_PRODUCT_PURPOSE')
      fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      @fnaQ1ResponseList = fnaQ1Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Q2 Response list - B,C
      fnaQ2Response = @fnaProposer.getQuestionResponse('FNA_PRODUCT_TYPE')
      @fnaQ2ResponseList = fnaQ2Response.fnaQuestionLookupDataCd.to_s.split(",")
      #Iterate over Q1 response list to get the recommended products
      @resulthash={}

        @fnaQ1ResponseList.each do |q1Response|
          lrm[:FNA_PRODUCT_PURPOSE] = FNAProductMatrix.find(
            :all,
            :conditions => {
              { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_PURPOSE',
              { :name => 'fnaQuestionLookupDataCd' } => q1Response.to_s,
                       },
            :op => 'AND',
            :select => ['fnaProductSeq']
          )
          #Find recommended products of Q1 which are present in Q4-C
          # @common = lrm[:FNA_GOAL_DURATION].collect{|x| x.fnaProductSeq} & lrm[:FNA_PRODUCT_PURPOSE].collect{|x| x.fnaProductSeq}
          @common = @commonProducts & lrm[:FNA_PRODUCT_PURPOSE].collect{|x| x.fnaProductSeq}
          @fnaQ2ResponseList.each do |q2Response|
             @resulthash[q1Response+"|"+q2Response] =  FNAProductMatrix.find(
              :all,
              :conditions => {
                { :name => 'fnaQuestionCd' } => 'FNA_PRODUCT_TYPE',
                { :name => 'fnaQuestionLookupDataCd' } => q2Response.to_s,
                { :name => 'fnaProductSeq', :op => 'IN' } => @common
              },
              :op => 'AND',
              :select => ['fnaProductSeq']
            ).collect{|x| x.fnaProductSeq}
          end
      end

      @res_hash = {}
      @resulthash.each do |resp_code, res_value|
        @res_hash[resp_code]={}
        array=[]
        res_value.each do |respValue|
          sql_querry = "select productId, guid, object from FNAProduct where id =#{respValue} "
          array << FNAProduct.find_by_sql(sql_querry)
        end
        @res_hash[resp_code] = array
      end

      #Ashwini:01-09-2017: Added Alternate Tab HIDE/SHOW for ILAS products
        $contains_ILAS_Product_q1 = false
        $contains_ILAS_Product_q2 = false
        @ilas_products_list = []
        @all_products = []
        @alternateProducts = []

        @resulthash.each do |needs,products_recommended|
          @ilas_products_list << products_recommended
        end

        @fnaProposer.FNAQuestionResponseList.each do |questionCd|
          if questionCd.fnaQuestionCd == "FNA_PRODUCT_PURPOSE"
             if questionCd.fnaQuestionLookupDataCd.to_s == "FNAQfinancialProtection,FNAQinvestment"
                $contains_ILAS_Product_q1 = true
             end
          end
          if questionCd.fnaQuestionCd == "FNA_PRODUCT_TYPE"
             if questionCd.fnaQuestionLookupDataCd.to_s == "FNAQpureInsurancePolicyHolder"
                $contains_ILAS_Product_q2 = true
             end
          end
        end

       @fnaIoNeedList =  FNAIONeed.loadObject( :all, :conditions => {'parentKey'=>@fnaRequest.object} )


      if @fnaIoNeedList.empty?
        @resulthash.each do |key, value|
        @fnaIoNeed = FNAIONeed.new
        @fnaRequest.addFNAIONeed(@fnaIoNeed)
        q1Responsekey = key.split("|").first
        q2Responsekey = key.split("|").last
        @fnaIoNeed.fnaRequestRefGuid = @fnaRequest.guid
        @fnaIoNeed.fnaQ1ResponseRefGuid = fnaQ1Response.guid
        @fnaIoNeed.fnaQ2ResponseRefGuid = fnaQ2Response.guid
        @fnaIoNeed.fnaQ1ResponseCd = q1Responsekey
        @fnaIoNeed.fnaQ2ResponseCd = q2Responsekey
        @resulthash[key].empty? ? @fnaIoNeed.productAvailableFl = "NO" : @fnaIoNeed.productAvailableFl = "YES"
        end
     else
        if responseChange == true || responseChangeOfQ3 == true
            FNAIONeed.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object']})
            @resulthash.each do |key, value|
            @fnaIoNeed = FNAIONeed.new
            @fnaRequest.addFNAIONeed(@fnaIoNeed)
            q1Responsekey = key.split("|").first
            q2Responsekey = key.split("|").last
            @fnaIoNeed.fnaRequestRefGuid = @fnaRequest.guid
            @fnaIoNeed.fnaQ1ResponseRefGuid = fnaQ1Response.guid
            @fnaIoNeed.fnaQ2ResponseRefGuid = fnaQ2Response.guid
            @fnaIoNeed.fnaQ1ResponseCd = q1Responsekey
            @fnaIoNeed.fnaQ2ResponseCd = q2Responsekey
            @resulthash[key].empty? ? @fnaIoNeed.productAvailableFl = "NO" : @fnaIoNeed.productAvailableFl = "YES"
            end
        end
     end

    @fnaRequest.persist
    fna_product_List =  FNAProduct.find(:all)

      fna_product_List.each do |product_obj|
           @all_products << product_obj.guid
      end

      if !@ilas_products_list.flatten.uniq.empty?
          @alternateProducts = @all_products - @ilas_products_list.flatten.uniq
      end

    @fnaIoProductList =  FNAIOProduct.loadObject( :all, :conditions => {'parentKey'=>@fnaRequest.object} )


      if @fnaIoProductList.empty?
        @fnaRequest.FNAIONeedList.each do |fnaneed|
          @res_hash.each do |resKey, resValue|
            products_introduced = []
            if fnaneed.fnaQ1ResponseCd == resKey.split('|').first && fnaneed.fnaQ2ResponseCd == resKey.split('|').last
              if resValue[0].to_s!="" and resValue[0].first.to_s!=""
                @fnaIoProduct = FNAIOProduct.new
                @fnaRequest.addFNAIOProduct(@fnaIoProduct)
                     resValue.map{|res| products_introduced<< res[0].guid}
                     @fnaIoProduct.productRecommended = products_introduced.join(",")
                     @fnaIoProduct.fnaRequestRefGuid = @fnaRequest.guid
                     @fnaIoProduct.fnaIONeedRefGuid  = fnaneed.guid
              end
            end
          end
        end
       if !@alternateProducts.empty? && $contains_ILAS_Product_q1 && $contains_ILAS_Product_q2
          @fnaIoProduct = FNAIOProduct.new
          @fnaRequest.addFNAIOProduct(@fnaIoProduct)
          @fnaIoProduct.fnaRequestRefGuid = @fnaRequest.guid
          @fnaIoProduct.productRecommended  = @alternateProducts.join(",")
        end
      else
        if responseChange == true || responseChangeOfQ3 == true
            FNAIOProduct.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object']})
            FNAIOSelected.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object']})
            @fnaRequest.FNAIONeedList.each do |fnaneed|
              @res_hash.each do |resKey, resValue|
                products_introduced = []
                if fnaneed.fnaQ1ResponseCd == resKey.split('|').first && fnaneed.fnaQ2ResponseCd == resKey.split('|').last
                  if resValue[0].to_s!="" and resValue[0].first.to_s!=""
                    @fnaIoProduct = FNAIOProduct.new
                    @fnaRequest.addFNAIOProduct(@fnaIoProduct)
                         resValue.map{|res| products_introduced<< res[0].guid}
                         @fnaIoProduct.productRecommended = products_introduced.join(",")
                         @fnaIoProduct.fnaRequestRefGuid = @fnaRequest.guid
                         @fnaIoProduct.fnaIONeedRefGuid  = fnaneed.guid
                  end
                end
              end
            end
            if !@alternateProducts.empty? && $contains_ILAS_Product_q1 && $contains_ILAS_Product_q2
                @fnaIoProduct = FNAIOProduct.new
                @fnaRequest.addFNAIOProduct(@fnaIoProduct)
                @fnaIoProduct.fnaRequestRefGuid = @fnaRequest.guid
                @fnaIoProduct.productRecommended  = @alternateProducts.join(",")
            end
        end
      end

      @fnaRequest.persist
      errors = {}
      errors1 = Hash.new
      errors2 = Hash.new
      errors3 = Hash.new
      errors4 = Hash.new
      errors5 = Hash.new
      @warningErrors = Hash.new


       MobiSys::FnaBO.validateBasicDetails(@fnaProposer, errors1)
       if @basicTabOnSave != "true"
         MobiSys::FnaBO.validateQuestionnaireDetails(@fnaProposer, @fnaRequest, errors2)
         MobiSys::FnaBO.validateAffordibilityCr(@fnaProposer, errors3)
         MobiSys::FnaBO.checkProductsExist(@fnaRequest, errors4)
       end

      #Ashwini : 12-07-2017 : to clear consideration tab on question response change
       $change_in_resp = false
       @fnaQuestionResponseList =  FNAQuestionResponse.loadObject( :all, :conditions => {'parentKey'=>@fnaProposer.object} )
        if responseChange == true || responseChangeOfQ3 == true
         if !@fnaQuestionResponseListCheck.empty? && @basicTabOnSave != "true"
            $change_in_resp = true
            @warningErrors = MobiSys::FnaBO.get_response_change_alert(@fnaProposer, errors5)
         end
        end

       errors = MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(errors1,errors2),errors3),errors4)
       # errors.empty? ? $total_error.reject!{ |k| k == 'basicPage' }  : $total_error['basicPage'] = errors

       if @warningErrors.empty?
          @warnings_exist = false
       else
          @warnings_exist = true
       end

       if errors.empty?
           @error_exist = false
           $total_error = Hash.new
           if fnaParty.lastName1 != "" && fnaParty.mobileNum != ""
           if $fnaNumclone == nil
            @fnaRequest.fnaNum = SequenceNoGenerator.getNextNumber('@fnaRequest')
           else
            @fnaRequest.fnaNum = $fnaNumclone
           end
           @fnaRequest.persist
           else
         end
       else
           @error_exist = true
            if fnaParty.lastName1 != "" && fnaParty.mobileNum != ""
            if $fnaNumclone == nil
            @fnaRequest.fnaNum = SequenceNoGenerator.getNextNumber('@fnaRequest')
           else
            @fnaRequest.fnaNum = $fnaNumclone
           end
           @fnaRequest.persist
          else

         end
       end

        # Ashwini:02-08-2017: update FNA status to FNAPENDING if there are changes found in Basic Info tab
        @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
        if @changeStatusCd == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end
        #Ashwini:09-08-2017:clear consideration Tab data when reponse changes
        if responseChange == true || responseChangeOfQ3 == true
           # $derivedCauseForDeviationValues = nil
           @fna_Request_Obj.update_attributes(:reasonForDeviation => nil, :reasonForRecommendation => nil, :addtnField2Str => nil, :reasonForRecoCd => nil)
        end

       returnStr = ""
       returnStr =  @error_exist.to_json + "|" + @warnings_exist.to_json + "|" + @warningErrors.to_json
       render :string => returnStr
    end

    #Ashwini: 07-04-2017 : Product Matrix Logic and Basic Page save
    def getProductList
        # WebView.execute_js("showLoadingMessage()")
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] })
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @questionSeq = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_PURPOSE'
                 },
                 :op => 'AND',
                 :select => ['cd']
            )
       @questionres = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      if !@questionres.empty?
        @questionres.each do |res1|
           @response1 = res1.fnaQuestionLookupDataCd
        end
      end

        if @response1 == nil || @response1 == ""
           @resp1 = ""
        else
         @resp1 = @response1.split(',')
        end
       @questionSeq1 = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_TYPE'
                 },
                 :op => 'AND',
                 :select => ['cd']
            )

       @questionres1 = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      if !@questionres1.empty?
        @questionres1.each do |res2|
           @response2 = res2.fnaQuestionLookupDataCd
        end
      end

      if @response2 == nil || @response2 == ""
           @resp2 = ""
      else
          @resp2 = @response2.split(',')
      end
      @fnaIOSelectedList = FNAIOSelected.find(:all, :conditions => { :parentKey => @fnaRequest.object}, :order => ["fnaBaseProductRefGuid"])
      @array_base = []
      @array_final_id= []
      @fnaIOSelectedList.each do |product|
        @array_base << product.fnaBaseProductRefGuid
        @array_base << product.fnaRiderProductRefGuid
      end
      @array_base = @array_base.compact
      @array_final_id = @array_base.uniq


      @questionSeq = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_PURPOSE'
                 },
                 :op => 'AND',
                 :select => ['cd']

            )
       @questionres = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )

      if !@questionres.empty?
        @questionres.each do |res1|
           @response1 = res1.fnaQuestionLookupDataCd
        end
      end
        if @response1 == nil || @response1 == ""
           @resp1 = ""
        else
         @resp1 = @response1.split(',')
        end
       @questionSeq1 = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_TYPE'
                 },
                 :op => 'AND',
                 :select => ['cd']
            )

       @questionres1 = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      if !@questionres1.empty?
        @questionres1.each do |res2|
           @response2 = res2.fnaQuestionLookupDataCd
        end

      end

      if @response2 == nil || @response2 == ""
           @resp2 = ""
      else
          @resp2 = @response2.split(',')
      end
      @array_productmax1 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']
            )

      @response1 = []
      @productmax1 = []
      if !@array_productmax1.empty?
        @array_productmax1.each do |prod_intro1|
          @response1 << prod_intro1.fnaQuestionLookupDataCd
        end
      end

      @response1 = @response1.compact
      @productmax1 = @response1.uniq

       @array_productmax2 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      @response2 = []
      @productmax2 = []
      if !@array_productmax2.empty?
        @array_productmax2.each do |prod_intro2|
          @response2 << prod_intro2.fnaQuestionLookupDataCd
        end
      end
      @response2 = @response2.compact
      @productmax2 = @response2.uniq


       @mismatch1 = []
       @mismatch2 = []
       @mismatch1 = @resp1 - @productmax1
       @mismatch2 = @resp2 - @productmax2

       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end
       html = ""
       html << render(:partial => 'FNAProduct_List')
      return html
    end

    def submitProductListDetails
       @error_exist = false
       @warnings_exist = false
       $isNaBenefitTermPresent = false
       @statusCd = @params['statuscode']
       @changeInProductIntro = @params['changeProductFrom']

       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       # if @statusCd.to_s != "FNASIGNED" ||  @statusCd.to_s != "FNASUBMIT" || @statusCd.to_s != "SYNCDONE"
       if !@fna_req_status.include?(@statusCd.to_s )
         FNAIOSelected.delete_all(:conditions=>{'parentKey'=>@params['FNARequest']['object']})
         @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
         @fnaProposer = FNAParty.loadObject( :first, :conditions => {'parentKey'=>@params['FNARequest']['object']} )

         @fnaIoProducts = @params['FNARequest']['FNAIOProduct']
          @products_selected = []
            @fnaRequest.FNAIOProductList.each do |io_product|
              @fnaIoProducts.each do|io_product_index,io_product_obj|

                if io_product_obj["productIntroduced"]!="" && io_product_obj["productIntroduced"] != nil
                   if io_product.object == io_product_obj["object"]

                      io_product.productIntroduced = io_product_obj["productIntroduced"]
                      @products_selected << io_product_obj["productIntroduced"]
                   end
                end
              end
            end

          @products_selected_array = []
          @products_selected.each do |index|
            @products_selected_array << index.split(",")
          end

         @fnaRequest.persist

          base_product_list ={}
          base_product_list =  FNAProduct.find(
                      :all,
                      :conditions => {
                        { :name => 'guid', :op => 'IN'} => @products_selected_array.flatten.uniq,
                        { :name => 'productTypeCd'} => 'PLAN'
                      },
                      :op => 'AND',
                      :select => ['productId', 'guid', 'object', 'shortName', 'productTypeCd']
                    )
           rider_product_list = FNAProduct.find(
                      :all,
                      :conditions => {
                        { :name => 'guid', :op => 'IN'} => @products_selected_array.flatten.uniq,
                        { :name => 'productTypeCd'} => 'RIDER'
                      },
                      :op => 'AND',
                      :select => ['productId', 'guid', 'object', 'shortName', 'productTypeCd']
                    )
          base_product_list.each do |plan|
            @fnaIoSelected = FNAIOSelected.new
            @fnaRequest.addFNAIOSelected(@fnaIoSelected)
            @fnaIoSelected.fnaBaseProductRefGuid = plan.guid
          end


          base_product_list.each do |baseProduct|
            rider_product_list.each do |riderProduct|
              @fnaIoSelected = FNAIOSelected.new
              @fnaRequest.addFNAIOSelected(@fnaIoSelected)
                @fnaIoSelected.fnaBaseProductRefGuid = baseProduct.guid
                @fnaIoSelected.fnaRiderProductRefGuid = riderProduct.guid
            end
          end

           @fnaRequest.persist

           # Ashwini:02-08-2017: update FNA status to FNAPENDING if there are changes found in Basic Info tab
            @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
            if @changeInProductIntro == "true"
              @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
            end

            errors = {}
            errors5 = Hash.new
            errors6 = Hash.new
            @warningErrors = {}
            errors, @warningErrors, $derivedCauseForDeviationValues , $isNaBenefitTermPresent = MobiSys::FnaBO.validateProductIntroduced(@fnaRequest,@fnaProposer,@products_selected_array,errors5,errors6)

            errors.empty? ? $total_error.reject!{ |k| k == 'getProductList' }  : $total_error['getProductList'] = errors

           if errors.empty?
               @error_exist = false
           else
               @error_exist = true
           end

           if  @warningErrors.empty?
              @warnings_exist = false
           else
               @warnings_exist = true
           end


           returnStr = ""
           returnStr =  @error_exist.to_json + "|" + @warnings_exist.to_json + "|" + @warningErrors.to_json
           render :string => returnStr
       else
           returnStr = ""
           errors = {}

           returnStr =  @error_exist.to_json + "|" + @warnings_exist.to_json + "|" + @warningErrors.to_json
           render :string => returnStr
       end

    end




    #Tejashree : To get products on product selection tab
    def getProductSelection
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
      @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => { :parentKey => @fnaRequest.object} )

      #Tejashree : Calculate Maximum Regular Premium, Maximum Single Premium, Additional Retirement Age check
      if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
        @shortfallAmt = 0
      else
      if @fnaLifeProtectionNeed.CalculatorTypeCd.to_s == "CALCTYPECOMPLEX"
         @total = (@fnaLifeProtectionNeed.protectionNeedPVAmt.to_i + @fnaLifeProtectionNeed.otherLiabilitiesAmt.to_i + @fnaLifeProtectionNeed.educationNeedPVAmt.to_i) - (@fnaLifeProtectionNeed.existingAssetAmt.to_i + @fnaLifeProtectionNeed.existingCoverageAmt.to_i)
        @shortfallAmt  = (@total.to_i * 1.3).round
        if @shortfallAmt < 0
          @shortfallAmt = 0
        end
      else
       if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
          @shortfallAmt = 0
      else
        if  @fnaLifeProtectionNeed.shortfallAmt == nil ||  @fnaLifeProtectionNeed.shortfallAmt == ""
          @shortfallAmt = 0
        else
          @shortfallAmt  = (@fnaLifeProtectionNeed.shortfallAmt * 1.3).round
        end
      end
      end

      if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
       @montlyExpenseAmt = 0
      else
        @montlyExpenseAmt = @fnaLifeProtectionNeed.montlyExpenseAmt
        if @montlyExpenseAmt == nil || @montlyExpenseAmt == ""
          @montlyExpenseAmt = 0
        end
      end
    end
      @fnaQuestionResponse = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd', :op => 'IN'} => '"FNA_IS_REGULAR_INCOME", "FNA_AMOUNT_OF_LIQUID_ASSETS", "FNA_GOAL_DURATION", "FNA_INCOME_PERCENT_FOR_PREMIUM", "FNA_FUND_SOURCE","FNA_LIQUID_ASSETS_TOTAL"',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionCd','fnaQuestionLookupDataCd', 'responseValue']

            )
        @array_fnaQuestionLookupDataCd = []
        @fnaQuestionResponse.each do |fnaQuestionResponse|
          @array_fnaQuestionLookupDataCd << fnaQuestionResponse.fnaQuestionLookupDataCd
        end

       @valuetofrom = Lookupvalue.find(
                :all,
                :conditions => {
                  {:name => 'cd', :op => 'IN'} =>  @array_fnaQuestionLookupDataCd
                 },
                 :op => 'AND',
                 :select => ['cd', 'valueFrom', 'valueTo']
               )


       # Maximum Regular Premium
        $flag4a = ''
        @fnaQuestionResponse.each do |fnaQuestionResponse|
          if fnaQuestionResponse.fnaQuestionCd == "FNA_IS_REGULAR_INCOME"
            if fnaQuestionResponse.fnaQuestionLookupDataCd == nil || fnaQuestionResponse.fnaQuestionLookupDataCd == ""
               @fnaRequest.addtnField8D =  0
            elsif fnaQuestionResponse.fnaQuestionLookupDataCd == "FNAQspecificAmount"
               @value4a = fnaQuestionResponse.responseValue
               $flag4a = true
            else
              @valuetofrom.each do |value|
                if fnaQuestionResponse.fnaQuestionLookupDataCd == value.cd
                  @value4a = value.valueTo
                  $flag4a = true
                end
              end
            end
          end
        end

      #Maximum Single Premium
      $flag4b = ""
       @fnaQuestionResponse.each do |fnaQuestionResponse|
        if fnaQuestionResponse.fnaQuestionCd == "FNA_LIQUID_ASSETS_TOTAL"
          if fnaQuestionResponse.fnaQuestionLookupDataCd == nil || fnaQuestionResponse.fnaQuestionLookupDataCd == ""
            @fnaRequest.addtnField9D =  0
          else
            $flag4b = true
            @value4b = fnaQuestionResponse.fnaQuestionLookupDataCd
          end
        end
      end


       @fnaQuestionResponse.each do |fnaQuestionResponse|
          if fnaQuestionResponse.fnaQuestionCd == "FNA_INCOME_PERCENT_FOR_PREMIUM"
            @valuetofrom.each do |value|
              if fnaQuestionResponse.fnaQuestionLookupDataCd == value.cd
                @value4d = value.valueTo
              end
            end
            if $flag4a == true
              @value4a = @value4a.to_s.gsub(",", "")
              @value4d = @value4d.to_s.gsub(",", "")
              @fnaRequest.addtnField8D = ((@value4a.to_i - @montlyExpenseAmt.to_i) * (@value4d.to_f/100)).round
              if @fnaRequest.addtnField8D < 0
                @fnaRequest.addtnField8D = 0
              end
            end
            if $flag4b == true
              @value4b = @value4b.to_s.gsub(",", "")
              @value4d = @value4d.to_s.gsub(",", "")
              @fnaRequest.addtnField9D = (@value4b.to_i * (@value4d.to_f/100)).round
              if @fnaRequest.addtnField9D < 0
                @fnaRequest.addtnField9D = 0
              end
            end
          end
        end
      @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

      @fnaQuestionResponse = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd', :op => 'IN'} => 'FNA_GOAL_DURATION',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionCd','fnaQuestionLookupDataCd']

            )

       @fnaQuestionResponse.each do |fnaQuestionResponse|
         @value_fnaQuestionLookupDataCd = fnaQuestionResponse.fnaQuestionLookupDataCd
       end

      @fnaIOSelectedList = FNAIOSelected.find(:all, :conditions => { :parentKey => @fnaRequest.object}, :order => ["fnaBaseProductRefGuid"])
      @array_base = []
      @array_final_id= []
      @fnaIOSelectedList.each do |product|
        @array_base << product.fnaBaseProductRefGuid
        @array_base << product.fnaRiderProductRefGuid
      end
      @array_base = @array_base.compact
      @array_final_id = @array_base.uniq
      @products = {}
      @products = FNAProduct.find(
                :all,
                :conditions => {
                  {:name => 'guid', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['productId','shortName','object','guid','productTypeCd']
            )

       @ridermapping = {}
       @ridermapping = FNARiderMapping.find(
                     :all,
                     :conditions => {
                      {:name => 'fnaParentProductSeq', :op =>'IN'} => @array_final_id
                     },
                     :op => 'AND',
                     :select => ['fnaParentProductSeq','fnaProductSeq']
          )

      array_basepro = []
      @fnaIOSelectedList.each do |prod|
        if prod.fnaBaseProductRefGuid != nil && prod.fnaRiderProductRefGuid == nil
          @result_base = {}
          @products.each do |pro|
            if "#{pro.guid}" == "#{prod.fnaBaseProductRefGuid}"
              @result_base["#{pro.productId}|#{pro.productTypeCd}"] = prod
            end
          end
          array_basepro.push(@result_base) if defined?(@result_base) != nil && !@result_base.empty?
        else
          @products.each do |pro|
            @ridermapping.each do |rider|
              if "#{rider.fnaParentProductSeq}" == "#{prod.fnaBaseProductRefGuid}"
                if "#{rider.fnaProductSeq}" == "#{prod.fnaRiderProductRefGuid}"
                  if "#{pro.guid}" == "#{prod.fnaRiderProductRefGuid}"
                    @result_base["#{pro.productId}|#{pro.productTypeCd}"] = prod
                  end
                end
              end
            end
          end
          array_basepro.push(@result_base) if defined?(@result_base) != nil && !@result_base.empty?
        end
      end
      @array_final = []
      @array_final = array_basepro.uniq

      @questionSeq = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_PURPOSE'
                 },
                 :op => 'AND',
                 :select => ['cd']

            )
       @questionres = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )

      if !@questionres.empty?
        @questionres.each do |res1|
           @response1 = res1.fnaQuestionLookupDataCd
        end
      end
        if @response1 == nil || @response1 == ""
           @resp1 = ""
        else
         @resp1 = @response1.split(',')
        end
       @questionSeq1 = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_TYPE'
                 },
                 :op => 'AND',
                 :select => ['cd']
            )

       @questionres1 = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      if !@questionres1.empty?
        @questionres1.each do |res2|
           @response2 = res2.fnaQuestionLookupDataCd
        end

      end

      if @response2 == nil || @response2 == ""
           @resp2 = ""
      else
          @resp2 = @response2.split(',')
      end
      @array_productmax1 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']
            )

      @response1 = []
      @productmax1 = []
      if !@array_productmax1.empty?
        @array_productmax1.each do |prod_intro1|
          @response1 << prod_intro1.fnaQuestionLookupDataCd
        end
      end

      @response1 = @response1.compact
      @productmax1 = @response1.uniq

       @array_productmax2 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      @response2 = []
      @productmax2 = []
      if !@array_productmax2.empty?
        @array_productmax2.each do |prod_intro2|
          @response2 << prod_intro2.fnaQuestionLookupDataCd
        end
      end
      @response2 = @response2.compact
      @productmax2 = @response2.uniq
      @applicableMenus = AgentReg.getCurrentAgentReg.applicableMenus.split(",")


       @mismatch1 = []
       @mismatch2 = []
       @mismatch1 = @resp1 - @productmax1
       @mismatch2 = @resp2 - @productmax2

      html = ""
      html << render(:partial => 'FNAProduct_Selection')
      return html
    end

    def submitProductSelection
        @error_exist= false
        $total_error = Hash.new
        @fnarequest = FNARequest.loadObject( :first, :conditions => { :object => @params['FNARequest']['object']} )
        @changeInSelectionTab = @params['changeSelectionForm']


        if @fnarequest.statusCd.to_s == "FNASIGNED" || @fnarequest.statusCd.to_s == "FNASUBMIT" || @fnarequest.statusCd.to_s == "SYNCDONE"
        else
            @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
            @fnaRequest.FNAIOSelectedList.each do |fan|
                fan.update_attributes(:selectedFlag => "off" ) if fan.selectedFlag.to_s ==""
                if fan.quotationId.to_s != ''
                    @quotation = Quotation.find(:first, conditions: { { name: 'quotationRefNum' } => fan.quotationId })
                    @quotation.update_attributes(fnaId: "#{@fnarequest.fnaNum}|#{fan.guid}")
                end
            end

            @statusCd = @params['statuscode']
            @fnaRequest.persist

            @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
            if @changeInSelectionTab == "true"
              @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
            end

        end

        @fnaIOSelected = FNAIOSelected.find( :all, :conditions => { :parentKey => @fnaRequest.object } )
        @fnaIOSelectedArray =[]
        @fnaIOSelected.each do |ioselected|
            @fnaIOSelectedArray << ioselected.selectedFlag if ioselected.selectedFlag.to_s == "on"
        end
        @fnaIOSelectedArray = @fnaIOSelectedArray.compact

        errors = {}
        errors1 = Hash.new
        errors = MobiSys::FnaBO.validateProductSelection(@fnaRequest, @fnaIOSelectedArray, errors1)
        $total_error['productSelection'] = errors
        if errors.empty?
            @error_exist = false
            $total_error = Hash.new
        else
            @error_exist = true
        end
         render :string => @error_exist.to_json
      end

    # Added by Vaibhav on 10th April 2017 for REASON FOR RECOMMENDATIONS tab start
    def getReasonsForRecommendation
      $isConsiderationTabVisited = true
      @rules_of_q6_validation = []
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => @params['id'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")

      @products_selected = []
      @products_selected_array = []
        @fnaRequest.FNAIOProductList.each do |io_product|
            if io_product.productIntroduced != nil && io_product.productIntroduced.to_s != ""
               @products_selected << io_product.productIntroduced
            end
        end

        @products_selected.each do |index|
          @products_selected_array << index.split(",")
        end

      @rules_of_q6_validation <<  MobiSys::FnaBO.get_rule_for_q6_validation(@fnaRequest)

      errors = {}
      errors5 = {}
      errors6 = {}
      warningErrors = {}

      errors, warningErrors, $derivedCauseForDeviationValues, $isNaBenefitTermPresent = MobiSys::FnaBO.validateProductIntroduced(@fnaRequest,@fnaProposer,@products_selected_array,errors5,errors6)

      #Ashwini 12-02-2017: Get the value of warning from product intro and raise validation for Q6b on Consideration tab to disable the question 6a
      if $derivedCauseForDeviationValues !=nil
         @rules_of_q6_validation << $derivedCauseForDeviationValues
      end
      @cause_for_deviation_list = @rules_of_q6_validation.flatten
      @cause_for_deviation_string = @cause_for_deviation_list.join(",")
      @fnaRequest.causeForDeviation = @cause_for_deviation_string
      if @cause_for_deviation_list.empty?
         @fnaRequest.reasonForDeviation = nil
      end
      #Vaibhav 12-02-2017: remove below fields for change in condition of @cause_for_deviation
      if !@cause_for_deviation_list.empty?
        @fnaRequest.reasonForRecoCd = nil
        @fnaRequest.reasonForRecommendation = nil
        @fnaRequest.addtnField2Str = nil
      end
       @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end

      @causeForDeviation =  @fnaRequest.causeForDeviation
      html = ""
      html << render(:partial => 'FNAReasonsForRecommendation')
      return html
    end

    def submitReasonsForRecommendation
        # puts "~~~~~@params: #{@params.to_json}"
        @error_exist= false
        @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
        @changeConsiderationForm = @params['changeConsiderationForm']
        @fnaRequest.reasonForRecoCd = nil unless @fnaRequest.reasonForRecoCd
        @fnaRequest.reasonForRecommendation = nil unless @fnaRequest.reasonForRecommendation
        @fnaRequest.reasonForDeviation = nil unless @fnaRequest.reasonForDeviation
        @fnaRequest.addtnField2Str = nil unless @fnaRequest.addtnField2Str
        # @reasonForRecommendation = @params['reasonForRecommendation']
        # @variable = @params['variable']

        errors = {}
        errors1 = Hash.new

        @fnaRequest.persist

        # errors = MobiSys::FnaBO.validateReasonsForRecommendation(@fnaRequest, @variable, errors1)
        errors = MobiSys::FnaBO.validateReasonsForRecommendation(@fnaRequest, errors1)
        errors.empty? ? $total_error.reject!{ |k| k == 'reasonsForRecommendation' }  : $total_error['reasonsForRecommendation'] = errors

        # $total_error['reasonsForRecommendation'] = errors

        if errors.empty?
            @error_exist = false
            $total_error = Hash.new
        else
            @error_exist = true
        end

      @fna_Request_Obj = FNARequest.loadObject(:first, :conditions => { :object => @fnaRequest.object} )
        if @changeConsiderationForm == "true"
          @fna_Request_Obj.update_attributes(:addtnField1Str=>'FNAPENDING')
        end

        render :string => @error_exist.to_json
    end

    # Added by Vaibhav on 10th April 2017 for REASON FOR RECOMMENDATIONS tab end
    def setAgentDetails(fnaRequest, agentRegdetails)
        if agentRegdetails != nil
            fnaRequest.agentId = agentRegdetails.agentId
        end
        fnaRequest
    end


    def search
        $flagQ3 = true
        $flagQ3New = true
        $flagProductIntro = true
        $flagProductIntroNew = true
        @searchResultList = {}

        if @params['deleteCheck'].to_s != ""
            @params['deleteCheck'].each do |selectedFnaId|
                fna = FNARequest.loadObject( :first, :conditions => { :object => selectedFnaId } )
                MobiSys::CommonUtil.clearTaskExceptionList(fna.guid) # why does it has entry in task exception
                fna.delete if fna
            end
        end

        if !@params.empty?
            mainSearchField = @params['mainSearchField'].downcase
            fnaName = @params['fullName'].downcase
            fnaMobile = @params['contactNum'].downcase
            fnaEmail = @params['emailAdd'].downcase
            fnaNumber = @params['fnaNum'].downcase
            fnaUpdatedDate = @params['systemUpdatedDt'].downcase
            fnaStatus = @params['statusCd'].downcase
            noOfRows = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'})
            if noOfRows && noOfRows.value != nil
                searchRows = noOfRows.value.to_i
            else
                searchRows = 30
            end

            searchRows = searchRows.to_s

            sqlStr = "select par.lastname1, req.agentId, par.firstname1, par.mobileNum, par.emailAddress, req.consentFl, req.fnanum, req.addtnField11DT, req.statusCd, req.requestDt, req.systemCreatedDt, req.systemUpdatedDt, req.applicantSignDt, req.addtnField11Dt, req.id, req.object from FNARequest req, FNAParty par where (par.parentkey = req.object and req.agentId = '" + $userId + "') and ((par.mobileNum like '%" + fnaMobile + "%') or (par.firstname1 like '%" + fnaName + "%') or (par.lastname1 like '%" + fnaName + "%') or (par.emailAddress like '%" + fnaEmail + "%')) order by req.systemUpdatedDt desc LIMIT '"+ searchRows +"'"

            fnaRequestList = FNARequest.find_by_sql(sqlStr)
            fnaRequestList.each do |fnaRequest|
                proposer = fnaRequest.getPartyByRole("PROPOSER")
                fullName = (fnaRequest.lastName1.to_s.strip + " " + fnaRequest.firstName1.to_s.strip).downcase
                fnaMobileNum = fnaRequest.mobileNum.to_s.downcase
                fnaMailAddress = fnaRequest.emailAddress.to_s.downcase
                fnaRequestNumber = fnaRequest.fnaNum.to_s.downcase
                fnaRequestStatus = getLabelValue(fnaRequest.statusCd).downcase
                fnaRequestUpdatedDate = getScreenDate(fnaRequest.systemUpdatedDt).to_s.downcase
                fnaSubmittedDate = getScreenDate(fnaRequest.addtnField11DT).to_s.downcase

                if fnaRequest.consentExpiryDt != nil
                    consentDate = Date.parse fnaRequest.consentExpiryDt
                else
                    fnaRequestDate = fnaRequest.requestDt
                    fnaRequestInDateFormat = Date.parse fnaRequestDate
                    fnaConsentExpiryDays = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'})
                    if fnaConsentExpiryDays && fnaConsentExpiryDays.value != nil
                        requiredays = fnaConsentExpiryDays.value.to_i
                    else
                        requiredays = 0
                    end

                    consentDate = (fnaRequestInDateFormat + requiredays)
                end

                todayDate = Date.today

                if fnaRequest.consentFl == "on" || (consentDate >= todayDate && fnaRequest.consentFl != "on")

                    validFNA = true

                    if mainSearchField != ""
                        unless fullName.include?(mainSearchField) || fnaMobileNum.include?(mainSearchField) || fnaMailAddress.include?(mainSearchField) || fnaRequestNumber.include?(mainSearchField) || fnaRequestUpdatedDate.include?(mainSearchField) || fnaRequestStatus.include?(mainSearchField)
                          fnaStatus.include?(mainSearchField)
                            validFNA = false
                        end
                    else
                        if fnaName != "" && validFNA
                            validFNA = false unless fullName.downcase.include?(fnaName)
                        end

                        if fnaMobile != "" && validFNA
                            validFNA = false unless fnaRequest.mobileNum.to_s.include?(fnaMobile)
                        end

                        if fnaEmail != "" && validFNA
                            validFNA = false unless fnaRequest.emailAddress.to_s.downcase.include?(fnaEmail.downcase)
                        end

                        if fnaNumber != "" && validFNA
                           validFNA = false unless fnaRequest.fnaNum.to_s.include?(fnaNumber)
                        end

                        if fnaUpdatedDate != "" && validFNA
                          validFNA = false unless  fnaRequestUpdatedDate.include?(getScreenDate(fnaUpdatedDate))
                        end

                        if fnaStatus != "" && validFNA
                          validFNA = false unless fnaRequestStatus.include?(getLabelValue(fnaStatus))
                        end
                    end

                    consentFlag = fnaRequest.consentFl

                    if validFNA
                        @searchResultList[fnaRequest.object] = [fnaRequestNumber,fullName,fnaMobileNum,fnaMailAddress,getLabelValue(fnaRequestStatus),fnaRequestUpdatedDate,fnaSubmittedDate]
                        # if fnaRequest.consentFl == "on" && fnaRequest.statusCd == "FNAPENDING"
                        # end
                    end
                end
            end
        end

        render :action => :FNASearch_Jazz, :layout => :jazzLayout
    end

    # Search method used on version 5
    # def search
    #     @searchResultList = []

    #     if !@params.empty?
    #         # puts "~~~~~@params: #{@params.to_json}"
    #         fnaName = @params['name']
    #         fnaMobile = @params['mobileNumber']
    #         fnaEmail = @params['emailAddress']

    #         if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'})
    #             if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'}).value != nil
    #                 searchRows = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'}).value.to_i
    #             else
    #                 searchRows = 30
    #             end
    #         else
    #             searchRows = 30
    #         end

    #         searchRows = searchRows.to_s
    #         sqlStr = "select par.lastname1, req.agentId, par.firstname1, par.mobileNum, par.emailAddress, req.consentFl, req.fnanum, req.addtnField11DT, req.statusCd, req.requestDt, req.systemCreatedDt, req.systemUpdatedDt, req.applicantSignDt, req.addtnField11Dt, req.id, req.object from FNARequest req, FNAParty par where (par.parentkey = req.object and req.agentId = '" + $userId + "') and ((par.mobileNum like '%" + fnaMobile + "%') or (par.firstname1 like '%" + fnaName + "%') or (par.lastname1 like '%" + fnaName + "%') or (par.emailAddress like '%" + fnaEmail + "%')) order by req.systemUpdatedDt desc LIMIT '"+ searchRows +"'"
    #         x = Time.now
    #         fnaRequestList = FNARequest.find_by_sql(sqlStr)
    #         y = Time.now

    #         fnaRequestList.each do |fnaRequest|
    #             if fnaRequest.consentExpiryDt != nil
    #                 consentDate = Date.parse fnaRequest.consentExpiryDt
    #             else
    #                 fnaRequestDate = fnaRequest.requestDt
    #                 fnaRequestInDateFormat = Date.parse fnaRequestDate

    #                 if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'}).value != nil
    #                     requiredays = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'}).value.to_i
    #                 else
    #                     requiredays = 0
    #                 end

    #                 consentDate = (fnaRequestInDateFormat + requiredays)
    #             end

    #             todayDate = Date.today

    #             if fnaRequest.consentFl == "on" || (consentDate >= todayDate && fnaRequest.consentFl != "on")
    #                 validFNA = true

    #                 partyFullname = fnaRequest.lastName1.to_s + " " + fnaRequest.firstName1.to_s

    #                 if fnaName != "" && validFNA
    #                     validFNA = false unless partyFullname.downcase.include?(fnaName.downcase)
    #                 end

    #                 if fnaMobile != "" && validFNA
    #                     validFNA = false unless fnaRequest.mobileNum.to_s.include?(fnaMobile)
    #                 end

    #                 if fnaEmail != "" && validFNA
    #                     validFNA = false unless fnaRequest.emailAddress.to_s.downcase.include?(fnaEmail.downcase)
    #                 end

    #                 if validFNA
    #                     fnaRequestHash = Hash.new
    #                     fnaRequestHash[:object] = fnaRequest.object
    #                     if partyFullname.to_s.strip != ""
    #                         fnaRequestHash[:name] = partyFullname
    #                     else
    #                         fnaRequestHash[:name] = "-"
    #                     end
    #                     if fnaRequest.mobileNum.to_s != ""
    #                         fnaRequestHash[:mobileNum] = fnaRequest.mobileNum.to_s
    #                     else
    #                         fnaRequestHash[:mobileNum] = "-"
    #                     end
    #                     if fnaRequest.emailAddress.to_s != ""
    #                         fnaRequestHash[:emailAddress] = fnaRequest.emailAddress.to_s
    #                     else
    #                         fnaRequestHash[:emailAddress] = "-"
    #                     end
    #                     if fnaRequest.fnaNum.to_s != ""
    #                         fnaRequestHash[:fnaNum] = fnaRequest.fnaNum.to_s
    #                     else
    #                         fnaRequestHash[:fnaNum] = "-"
    #                     end
    #                     if fnaRequest.statusCd.to_s != ""
    #                         fnaRequestHash[:statusCd] = getLabelValue(fnaRequest.statusCd)
    #                     else
    #                         fnaRequestHash[:statusCd] = "-"
    #                     end
    #                     if fnaRequest.systemCreatedDt.to_s != ""
    #                         fnaRequestHash[:systemCreatedDt] = getScreenDate(fnaRequest.systemCreatedDt)
    #                     else
    #                         fnaRequestHash[:systemCreatedDt] = "-"
    #                     end
    #                     if fnaRequest.systemUpdatedDt.to_s != ""
    #                         fnaRequestHash[:systemUpdatedDt] = getScreenDate(fnaRequest.systemUpdatedDt)
    #                     else
    #                         fnaRequestHash[:systemUpdatedDt] = "-"
    #                     end
    #                     if fnaRequest.applicantSignDt.to_s != ""
    #                         fnaRequestHash[:applicantSignDt] = getScreenDate(fnaRequest.applicantSignDt)
    #                     else
    #                         fnaRequestHash[:applicantSignDt] = "-"
    #                     end
    #                     if fnaRequest.addtnField11DT.to_s != ""
    #                         fnaRequestHash[:submitDt] = getScreenDate(fnaRequest.addtnField11DT)
    #                     else
    #                         fnaRequestHash[:submitDt] = "-"
    #                     end
    #                     if fnaRequest.consentFl.to_s != ""
    #                         fnaRequestHash[:consentFl] = fnaRequest.consentFl
    #                     else
    #                         fnaRequestHash[:consentFl] = "-"
    #                     end
    #                     @searchResultList.push(fnaRequestHash)
    #                 end
    #             end
    #         end
    #     end
    #     render :action => :FNASearch, :layout => :newEAPPLayout
    # end
    # Added by Vaibhav on 6th April 2017 for search Page end

    def deleteFna
        # p "deleteFna"
        fnaObject = @params['id'][1..-2]
        @fna = FNARequest.loadObject(:first, :conditions=>{{:name=>'object'}=>fnaObject})
        if @fna !=nil
            # @fna.getImage().delete
            @fna.delete
        end
        # @rpq = RPQ.loadObject(:first, :conditions=>{:fnaId=>@fna.fnaId})
        # if @rpq
        #     @rpq.getImage().delete
        #     @rpq.delete
        # end
        redirect :action => :search
    end

    # Added by Vaibhav on 13th April 2017 for search Page start
    def show
        $action = "show"

        if @params['id'].to_s != ""
            if @params['id'].include? ('{')
              id = @params['id'][1..-1].chop
            else
              id = @params['id']
            end
            @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
        elsif @params['fnaNum'].to_s != ""
            if @params['fnaNum'].include? ('{')
              fnaNum = @params['fnaNum'][1..-1].chop
            else
              fnaNum = @params['fnaNum']
            end
            @fnaRequest = FNARequest.loadObject( :first, :conditions => { :fnaNum => fnaNum } )
        end

        @fnaProposer = @fnaRequest.getParty("PROPOSER") if @fnaRequest
        @fnaInsured = @fnaRequest.getParty("PROPOSER") if @fnaRequest
        $currentLanguageCode =  Application.getValue('DEFAULTLOCALE').value
        $ShowFlag = true
        render :action => :FNACapture, :layout => :sunlifeHKLayout
    end

    def showpreview
       @set_req_tab = @params["set_get_req_tab"] == "TRUE"
       $action = "show"
        if @params['id'].include? ('{')
          id = @params['id'][1..-1].chop
        else
          id = @params['id']
        end
        # RhoLog.error("Checking the value of id :", "#{id.inspect}")
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaInsured = @fnaRequest.getParty("PROPOSER")
        $currentLanguageCode =  Application.getValue('DEFAULTLOCALE').value
        $ShowFlag = true
        render :action => :FNACapture, :layout => :sunlifeHKLayout
    end

      #Method to get party age based on entered birth date
    def getAge
      @birthDt = @params["birthDt"]

      if @birthDt != nil
        dateParts = @birthDt.split("/")
        @age = MobiSys::ProductUtil.calculateAge(Time.new(dateParts[2].to_i, dateParts[1].to_i, dateParts[0].to_i), MobiSys::ProductUtil::LASTBIRTHDAY, Time.now)
      end

      render :string => @age.to_json
    end


    #Tejashree:11-09-2017: Withdrawn Product Validation
    def withdrawnProductValidation
        @error_exist= false
        if @params['id'].include? ('{')
          id = @params['id'][1..-1].chop
        else
          id = @params['id']
        end
        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )

        @array_productIntroduced = []
        @fnaRequest.FNAIOProductList.each do |fnaIoProduct|
            @array_productIntroduced << fnaIoProduct.productIntroduced
        end
        @array_productIntroduced = @array_productIntroduced.flatten
        @array_productIntroduced = @array_productIntroduced.compact
        @array_productIntroduced_new = []
        @array_productIntroduced.each do |productIntroduced|
            @array_productIntroduced_new << productIntroduced.split(",")
        end
        @array_productIntroduced_new = @array_productIntroduced_new.flatten
        @array_productIntroduced_new = @array_productIntroduced_new.compact
        @FNAProduct_productId_List = FNAProduct.find(
            :all,
            :conditions => {
                {:name => 'id', :op => 'IN'} =>  @array_productIntroduced_new
                },
                :op => 'AND',
                :select => ['withdrawDt']
            )
        @array_FNAProduct_productId_List = []
        @FNAProduct_productId_List.each do |productId|
            @array_FNAProduct_productId_List << productId.withdrawDt
        end
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.flatten
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.compact

        errors = {}
        errors1 = Hash.new
        errors = MobiSys::FnaBO.validatewithdrawnproduct(@fnaRequest, @array_FNAProduct_productId_List, errors1)
        errors.empty? ? $total_error.reject!{ |k| k == 'withdrawnproduct' }  : $total_error['withdrawnproduct'] = errors

        if errors.empty?

            @error_exist = false
            $total_error = Hash.new
            WebView.navigate(url_for :action => :cloneFna, :id => @fnaRequest.object.to_s, :query => {'type' => 'copy'})
            # redirect :action => :cloneFna, :id => @fnaRequest.object.to_s
        else

            @error_exist = true
            # @url = '/app/FNARequest/{<%= @fnaRequest.object.to_s %>}/cloneFna?type=copy'
             # Alert.show_popup( { :message => getLabelValue("Withdrawn Product Validation"), :buttons=>["Ok","Cancel"],:callback => url_for(:action => :cloneFna, :id => @fnaRequest.object.to_s, :query => {'type' => 'copy'}) } )
            returnStr = (url_for :action => :cloneFna, :id => @fnaRequest.object.to_s, :query => {'type' => 'copy'}).to_s + "|" + @error_exist.to_s
            render :string => returnStr.to_json
        end
    end


    # Added by Vaibhav on 13th April 2017 for show method end

    def cloneFna

        if @params['id'].include? ('{')
          id = @params['id'][1..-1].chop
        else
          id = @params['id']
        end

        @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object => id } )
        @fnaNum = @fnaRequest.fnaNum unless @fnaRequest.nil?
        @saved_response = FNAResponse.find(:all, :conditions => { :fnaNum => @fnaNum.to_s }) if @fnaNum

        # handle copy requests
        # type = @params['type']
        # if type != nil && type=="copy"
        if id != nil
            # clone existing @fnaRequest and regenerate its Id and clear its signature and guid
            fnaCopied = @fnaRequest.cloneObject
            # fnaCopied.persist
            fnaCopied.update_attributes(:agentSignDt => nil,:witnessSignDt => nil,:applicantSignDt => nil,:agentSignature => nil,:witnessSignature => nil,:applicantSignature => nil,:statusCd => "FNAPENDING",:addtnField1Str => "FNAPENDING",:consentFl => nil,:marketingInfoFl => nil,:requestDt => Time.now, :addtnField11DT => nil, :systemCreatedDt => Time.now, :systemUpdatedDt => Time.now, :guid => nil, :id => nil, :fnaNum => nil, :versionID => nil )

            fnaCopied.fnaNum = @fnaNum = SequenceNoGenerator.getNextNumber('@fnaRequest')
            fnaCopied.guid = fnaCopied.object.gsub(".","_")

            @fnaProposer = fnaCopied.getParty("PROPOSER")
            @fnaProposer.update_attributes(:guid => nil, :id => nil, :systemCreatedDt => Time.now, :systemUpdatedDt => Time.now, :versionID => nil )
            @fnaProposer.guid = @fnaProposer.object.gsub(".","_")

            if fnaCopied.getParty("PROPOSER").FNAQuestionResponseList && fnaCopied.getParty("PROPOSER").FNAQuestionResponseList.size > 0
                fnaCopied.getParty("PROPOSER").FNAQuestionResponseList.each do |qp|
                    qp.fnaRequestRefGuid = fnaCopied.guid
                    qp.fnaPartyRefGuid = fnaCopied.getParty("PROPOSER").guid
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNAIONeedList && fnaCopied.FNAIONeedList.size > 0
                fnaCopied.FNAIONeedList.each do |qp|
                  variable = qp.guid
                  qp.fnaRequestRefGuid = fnaCopied.guid
                  qp.id = nil
                  qp.systemCreatedDt = Time.now
                  qp.systemUpdatedDt = Time.now
                  qp.versionID = nil
                  qp.guid = qp.object.gsub(".","_")
                  qp.fnaQ1ResponseRefGuid = fnaCopied.getParty("PROPOSER").getFNAQuestionResponseGuid("FNA_PRODUCT_PURPOSE")
                  qp.fnaQ2ResponseRefGuid = fnaCopied.getParty("PROPOSER").getFNAQuestionResponseGuid("FNA_PRODUCT_TYPE")
                  if qp.productAvailableFl == "YES"
                    fnaCopied.FNAIOProductList.each do |product|
                      if product.fnaIONeedRefGuid == variable
                        product.fnaRequestRefGuid = fnaCopied.guid
                        product.guid = product.object.gsub(".","_")
                        product.fnaIONeedRefGuid = qp.guid
                        product.id = nil
                        product.systemCreatedDt = Time.now
                        product.systemUpdatedDt = Time.now
                        product.versionID = nil
                      end
                    end
                  end
                end
            end
            if fnaCopied.FNAIOSelectedList && fnaCopied.FNAIOSelectedList.size > 0
                fnaCopied.FNAIOSelectedList.each do |qp|
                  qp.fnaRequestRefGuid = fnaCopied.guid
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.quotationId = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNAPolicyLinkList && fnaCopied.FNAPolicyLinkList.size > 0
                fnaCopied.FNAPolicyLinkList.each do |qp|
                  # puts "qp.guid ========before FNAPolicyLink=========== #{qp.guid}"
                    # qp.guid = qp.object.gsub(".","_")
                  # puts "qp.guid ========after FNAPolicyLink=========== #{qp.guid}"

                  # to remove policy number from copying
                  # puts "qp.guid ========before FNAPolicyLink=========== #{fnaCopied.FNAPolicyLinkList.to_json}"
                  qp.removed = 'YES'
                  #   fnaCopied.FNAPolicyLinkList.delete(qp)
                  # puts "qp.guid ========after FNAPolicyLink=========== #{fnaCopied.FNAPolicyLinkList.to_json}"
                end
            end
            if fnaCopied.FNARetirementNeedList && fnaCopied.FNARetirementNeedList.size > 0
                fnaCopied.FNARetirementNeedList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNAOtherTargetNeedList && fnaCopied.FNAOtherTargetNeedList.size > 0
                fnaCopied.FNAOtherTargetNeedList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNAOtherProtectionNeedList && fnaCopied.FNAOtherProtectionNeedList.size > 0
                fnaCopied.FNAOtherProtectionNeedList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNAEducationNeedList && fnaCopied.FNAEducationNeedList.size > 0
                fnaCopied.FNAEducationNeedList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end
            if fnaCopied.FNALifeProtectionNeedList && fnaCopied.FNALifeProtectionNeedList.size > 0
                fnaCopied.FNALifeProtectionNeedList.each do |qp|
                    qp.guid = qp.object.gsub(".","_")
                    qp.id = nil
                    qp.systemCreatedDt = Time.now
                    qp.systemUpdatedDt = Time.now
                    qp.versionID = nil
                end
            end

            fnaCopied.persist

            # clone all the FNA Responses and map them to the newly generated FNA-id also clear their guid
            @saved_response.each do |fnaResponse|
                fnaResponseCloned = fnaResponse.cloneObject

                fnaResponseCloned.update_attributes(:fnaNum => fnaCopied.fnaNum,:guid => nil,:parentKey =>fnaCopied.object,:partyRoleCd=>'PROPOSER', :id => nil)
                fnaResponseCloned.guid = fnaResponseCloned.object.gsub(".","_")
                fnaResponseCloned.save
            end
            redirect :action => :show, :id => fnaCopied.object
        end
    end

    # Added by Vaibhav on 31st May 2017 for fnaExpirySearch Page start
    def fnaExpirySearch
        @searchResultList = []
        @flagForSearch = true
        # @ifSelectedDateIsLessThanToday = false

        if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'}).value != nil
            @requiredays = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'}).value.to_i
        else
            @requiredays = 0
        end

        if !@params.empty?
            @flagForSearch = false
            # puts "~~~~~@params: #{@params.to_json}"
            # fnaName = @params['name']
            # fnaMobile = @params['mobileNumber']
            # fnaEmail = @params['emailAddress']
            fnaExpiryDate = @params['date']

            dateArray = fnaExpiryDate.split("/")
            fnaExpiryDateFormat = Time.new(dateArray[2],dateArray[1],dateArray[0])
            today = Time.now

            # if today > fnaExpiryDateFormat
            #     # Calling alert
            #     @ifSelectedDateIsLessThanToday = true
            # end

            # puts "today: #{today}"
            # puts "fnaExpiryDateFormat: #{fnaExpiryDateFormat}"

            #  FOR :COUNT = OfflineApplication.find(:first, :conditions =>{{:name =>'key'} =>'SEARCHRESULT'}),
            # fnaRequestList = FNARequest.loadObject(
            #     :all,
            #     # :per_page => "3",
            #     :conditions=>{
            #         "1"=>"1",
            #         :statusCd => "FNAPENDING",
            #     },
            #     :order => "requestDt",
            #     :orderdir => "ASC",
            #     :select => ['fnaNum', 'statusCd', 'requestDt', 'systemCreatedDt', 'systemUpdatedDt', 'agentSignDt','consentFl']
            # )


            # puts "~~~~~@params: #{fnaRequestList.to_json}"
            # puts "````",fnaRequestList
            # puts "fnaRequestList size",fnaRequestList.size
            # validfnareq = Array.new

            # i = 0

            if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'}).value != nil
                searchRows = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'SEARCHRESULTS'}).value.to_i
            else
                searchRows = 30
            end

            searchRows = searchRows.to_s
            sqlStr = "select par.lastname1, req.agentId, par.firstname1, par.mobileNum, par.emailAddress, req.consentFl, req.fnanum, req.addtnField11DT, req. statusCd, req. consentExpiryDt, req.systemUpdatedDt, req.requestDt, req.systemCreatedDt, req.id, req.object from FNARequest req, FNAParty par where par.parentkey = req.object and req.consentFl != 'on' and req. statusCd = 'FNAPENDING'  and req.consentExpiryDt <= '" + fnaExpiryDateFormat.to_s + "' and req.consentExpiryDt >= '" + today.to_s + "' and req.agentId = '" + $userId + "' order by req.consentExpiryDt LIMIT '"+ searchRows +"'"

            fnaRequestList = FNARequest.find_by_sql(sqlStr)
            if fnaRequestList.length > 0
                # @flagForSearch = false
                fnaRequestList.each do |fnaRequest|
                    # if i < searchRows
                        # puts "i= #{i}"
                        # fnaRequestDate = fnaRequest.requestDt
                        # puts "converting fnaRequestDate string to date format",fnaRequestDate
                        # fnaRequestInDateFormat = Date.parse fnaRequestDate

                        # expiryDate = (fnaRequestInDateFormat + @requiredays.to_i)

                        # discarding expired FNA
                        # next if fnaExpiryDateFormat < expiryDate
                        # next if today > expiryDate

                        # next if fnaRequest.consentFl.to_s != ''

                        # puts "checking",(fnaRequestInDateFormat+15)
                        # if today < (fnaRequestInDateFormat+15)
                        #     puts "control here"
                        #     # fnaRequestList.delete(fnaRequest)
                        #     validfnareq << fnaRequest
                        #     # next
                        # end
                        # dateone = Date.today
                        # datetwo = Date.today
                        # datetwo = datetwo+3
                        # puts "can compare date" if dateone < datetwo
                        # puts "cannot compare date" if dateone > datetwo

                        # proposer = fnaRequest.getParty("PROPOSER")
                        # validFNA = true
                        partyFullname = fnaRequest ? getLabelValue(fnaRequest.lastName1.to_s + " " + fnaRequest.firstName1.to_s) : ""

                        # if fnaExpiryDate != "" && validFNA
                        #     validFNA = false unless getScreenDate(expiryDate).include?getScreenDate(fnaExpiryDate)
                        # end

                        # if validFNA
                            fnaRequestHash = Hash.new
                            fnaRequestHash[:object] = fnaRequest.object
                            if partyFullname.to_s.strip != ""
                                fnaRequestHash[:name] = partyFullname
                            else
                                fnaRequestHash[:name] = "-"
                            end
                            if fnaRequest.mobileNum.to_s != ""
                                fnaRequestHash[:mobileNum] = fnaRequest.mobileNum.to_s
                            else
                                fnaRequestHash[:mobileNum] = "-"
                            end
                            if fnaRequest.emailAddress.to_s != ""
                                fnaRequestHash[:emailAddress] = fnaRequest.emailAddress.to_s
                            else
                                fnaRequestHash[:emailAddress] = "-"
                            end
                            if fnaRequest.fnaNum.to_s != ""
                                fnaRequestHash[:fnaNum] = fnaRequest.fnaNum.to_s
                            else
                                fnaRequestHash[:fnaNum] = "-"
                            end
                            if fnaRequest.statusCd.to_s != ""
                                fnaRequestHash[:statusCd] = getLabelValue(fnaRequest.statusCd)
                            else
                                fnaRequestHash[:statusCd] = "-"
                            end
                            if fnaRequest.systemUpdatedDt.to_s != ""
                                fnaRequestHash[:systemUpdatedDt] = getScreenDate(fnaRequest.systemUpdatedDt)
                            else
                                fnaRequestHash[:systemUpdatedDt] = "-"
                            end
                            if fnaRequest.requestDt.to_s != ""
                                # fnaRequestHash[:requestDt] = (expiryDate.strftime("%d") +"/"+ expiryDate.strftime("%m") +"/"+ expiryDate.strftime("%Y"))
                                fnaRequestHash[:requestDt] = getScreenDate(fnaRequest.consentExpiryDt)
                            else
                                fnaRequestHash[:requestDt] = "-"
                            end
                            if fnaRequest.consentFl.to_s != ""
                                fnaRequestHash[:consentFl] = fnaRequest.consentFl
                            else
                                fnaRequestHash[:consentFl] = "-"
                            end
                            @searchResultList.push(fnaRequestHash)

                            # i= i + 1
                        # end
                    # else break
                    # end
                end
            end
            # puts "validfnareq size",validfnareq.size,validfnareq
        end
        @requireDaysOfExpiry = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'FNACONSENTEXPIRYDAYS'}).value.to_i
        render :action => :FNAExpirySearch, :layout => :newEAPPLayout
    end



    def captureDate
        # p "in date"
        @date = @params['date']
        # p "date: #{date}"
        @id = @params['id']
        # p "id: #{id}"
        @date = Time.now.strftime("%d/%m/%Y") if @date == nil || @date == ""
        # p "@date: #{@date}"

        if @date != nil
            parts = @date.split("/")
            @day = parts[0]
            @month = parts[1]
            @year = parts[2]
        end

        render :action => :dialog
    end

    # Added by Vaibhav on 6th April 2017 for Questionnaire Part start
    # Tejashree Nikam:15-June-2017 Modified foe ipa problem
    def getQuestionnaireCheckbox(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil)
        if(lookupkey != DYNAMICLOOKUP)
            lookups = Lookupvalue.find(:all,
                :conditions=>{
                'key'=>lookupkey
            },
                :order=>'sortOrder',
                :orderdir=>'ASC'
            )
            else # (lookupkey == "DYNAMICARRAY")
            lookups = lookupdata
            end
            returnStr = ""
            radioName = ""
            lookup_name = ""
            begin
                if fieldname!=nil
                    lookup_name = fieldname
                else
                    lookup_name = lookupkey
                end
                # returnStr << "console.log('in change #{lookups}');"
                if lookups.size > 1
                    returnStr << renderHiddenField('fnaQuestionLookupDataCd', object.fnaQuestionLookupDataCd, 'fnaQuestionLookupDataCd', object)
                    lookups.each_with_index do |lookup,index|
                        fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]" unless object.nil?
                        returnStr << "<div class='ui-grid-a'>"

                        returnStr << "<div class='ui-block-a' style=\"width: 5%;\">"

                        returnStr << " <input type='checkbox' style='display:none;' name='#{fieldname}#{index}' id='#{fieldname}#{index}' value='#{lookup.cd}'"
                        returnStr << "checked='checked'" if ( selectedvalue.is_a?(Array) && ( selectedvalue.include?(lookup.cd.to_s) ) )
                        returnStr << "/>"
                        returnStr << "</div>"

                        returnStr << "<div class='ui-block-b' style=\"width: 90%;\">"
                        returnStr << " <label for='#{fieldname}#{index}' class=\"icon-checkbox\" style=\"top:3px;\"></label>"
                        labelforQuestion = "#{Localization::LabelCache.instance.getLabel(lookup.desc.to_sym)}".force_encoding(Encoding::UTF_8)

                        returnStr << labelforQuestion.gsub("___________________________","\t"+renderInputField('responseValue',object.responseValue,'responseValue',object, ' maxlength="255" class="material-input pseudo-material-input" style="width:61%;border-bottom:1px grey solid;text-align:left;padding : 0px !important;" '))
                        returnStr << "<br/><br/>"
                        returnStr << "</div>"
                        returnStr << "</div>"
                    end
                else
                    labelforQuestion = "#{Localization::LabelCache.instance.getLabel(lookups[0].desc.to_sym)}".force_encoding(Encoding::UTF_8)

                     # returnStr << labelforQuestion.gsub("___________________________","\t"+renderNumericField('fnaQuestionLookupDataCd',object.fnaQuestionLookupDataCd,'responseValue',object, 'maxlength="10" width="15%" style="width:10%;border-bottom:1px solid grey !important;text-align:left;"')+attachMaskForAmountHk("#{getObjectMapping(object)}[fnaQuestionLookupDataCd]"))

                     returnStr << labelforQuestion.gsub("___________________________","\t"+renderNumericField('fnaQuestionLookupDataCd',object.fnaQuestionLookupDataCd,'responseValue',object, 'maxlength="10" width="15%" style="width:10%;border-bottom:1px solid grey !important;text-align:left;"')+attachMask("#{getObjectMapping(object)}[fnaQuestionLookupDataCd]"))

                     # returnStr << labelforQuestion.gsub("___________________________","\t"+renderInputField('fnaQuestionLookupDataCd',object.fnaQuestionLookupDataCd,'fnaQuestionLookupDataCd',object, 'maxlength="14" class="material-input pseudo-material-input" style="width:15%;border-bottom:1px grey solid;text-align:left;"'))
                     # returnStr << attachMask("#{getObjectMapping(object)}[fnaQuestionLookupDataCd]")
                end
                returnStr << "\n<script>\n"
                      # returnStr << "$('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').blur(function() {\n"
                      # returnStr << "  if(this.value!=\"\" && $(this).prev().find('input:checked').size()==0) {\n"
                      # returnStr << "    $(this).prev().find('label').trigger('click');\n"
                      # returnStr << "  } else if(this.value==\"\" && $(this).prev().find('input:checked').size()==1)  {\n"
                      # returnStr << "    $(this).prev().find('label').trigger('click');\n"
                      # returnStr << "  }\n"
                      # returnStr << "})\n"

                      # returnStr << " $(document).ready(function() {\n"
                      # #returnStr << "console.log("'in ready'");"
                      # returnStr << " if($(this).parent().parent().next().children().attr('name') == \""+$objectMapping[object.object.to_s]+"[responseValue]\" && !$(this).is(':checked')) {\n"
                      # returnStr << "console.log('in change #{name}');"
                      # returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').prop('disabled', true);\n"
                      # returnStr << " }\n"
                      # returnStr << " })\n"

                returnStr << " $('[id*=\""+fieldname+"\"]').change(function() {\n"
            # returnStr << "console.log('in change #{fieldname}');"

                returnStr << " if($(this).parent().parent().next().children().attr('name') == \""+$objectMapping[object.object.to_s]+"[responseValue]\" && $(this).is(':checked')) {\n"
            # returnStr << "console.log('checked #{fieldname}');"
                returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').prop('disabled', false);\n"
                returnStr << " }\n"

                returnStr << " if($(this).parent().parent().next().children().attr('name') == \""+$objectMapping[object.object.to_s]+"[responseValue]\" && !$(this).is(':checked')) {\n"
            # returnStr << "console.log('unchecked #{fieldname}');"
                returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').val('');\n"
                returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').prop('disabled', true);\n"
                returnStr << " }\n"
                returnStr << " })\n"
                returnStr << " </script>\n"
                if System.get_property('platform') == "ANDROID"
                    returnStr << "\n<script>\n"
                    returnStr << "$('input[name*=\"" << fieldname << "\"]').click(function(){\n"
                    returnStr << "$('input[type=\"text\"]:focus').blur();\n"
                    returnStr << "$('textarea:focus').blur();\n"
                    returnStr << "});\n"
                    returnStr << "</script>\n"
                    returnStr << "\n"
                end
            rescue StandardError => se
                RhoLog::error("getQuestionnaireCheckbox","Exception occured in getQuestionnaireCheckbox #{se}")
                puts se.backtrace
            end
        return returnStr
    end
    # Added by Vaibhav on 6th April 2017 for Questionnaire Part end

    def getQuestionRadioButton(lookupkey, fieldname, selectedvalue, object=nil, lookupdata=nil, adhocContent=nil, desc=false)
      if(lookupkey != DYNAMICLOOKUP)
        lookups = Lookupvalue.find(:all,
            :conditions=>{
            'key'=>lookupkey
          },
            :order=>'sortOrder',
            :orderdir=>'ASC'
         )
      else # (lookupkey == "DYNAMICARRAY")
        lookups = lookupdata
        end
        returnStr = ""
        radioName = ""
        lookup_name = ""
        begin
          if fieldname!=nil
            lookup_name = fieldname
          else
            lookup_name = lookupkey
          end
          fieldname = $objectMapping[object.object.to_s]+"["+lookup_name+"]" unless object.nil?
          lookups.each_with_index do |lookup,index|
          returnStr << "<div class='ui-grid-a'>"

          returnStr << "<div class='ui-block-a' style=\"width: 5%;\">"
            returnStr << renderRadioButton('fnaQuestionLookupDataCd', selectedvalue,"#{fieldname}#{index}", lookup.cd, object, adhocContent)
          returnStr << "</div>"

          returnStr << "<div class='ui-block-b' style=\"width: 90%;\">"
          returnStr << " <label for='#{fieldname}#{index}' style=\"padding-left: 10px;padding-top: 10px;margin-left: -6%;z-index: 10;margin-top: -33px;\" ></label>"
            labelkey = (desc)? lookup.desc.to_sym : lookup.cd.to_sym
            labelforQuestion = "#{Localization::LabelCache.instance.getLabel(labelkey)}".force_encoding(Encoding::UTF_8)
            returnStr << labelforQuestion.gsub("___________________________","\t"+renderAmountField('responseValue',object.responseValue,'responseValue',object, 'maxlength="10" width="50%" style="border-bottom:1px solid grey !important;text-align:left;padding : 0px !important;"')+attachMask("#{getObjectMapping(object)}[responseValue]"))
            returnStr << "<br/><br>"
          returnStr << "</div>"
          returnStr << "</div>"
          end
          returnStr << "\n<script>\n"
          # returnStr << " $(document).ready(function() {\n"

          returnStr << "$('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').blur(function(){\n"
          returnStr << "  if(this.value!=\"\" && $(this).prev().find('input:checked').size()==0) {\n"
          returnStr << "    $(this).prev().find('label').trigger('click');\n"
          returnStr << "  }\n"
          returnStr << "})\n"

          returnStr << "$('[id*=\""+fieldname+"\"]').change(function(){\n"
          returnStr << "  if($('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').prev().find('input').attr('id')!=$(this).attr('id')){\n"
          returnStr << "    $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').val('');\n"
          returnStr << "  }\n"
          returnStr << "})\n"

        returnStr << " $('[id*=\""+fieldname+"\"]').change(function() {\n"
        # returnStr << " console.log('in change #{fieldname}');"
            # checked condition starts
            returnStr << " if($(this).parent().parent().next().children('input').attr('name') == \""+$objectMapping[object.object.to_s]+"[responseValue]\" && $(this).is(':checked')) {\n"
        # returnStr << "console.log('in loop_1 #{$objectMapping[object.object.to_s]+"[responseValue]"} ');"
            returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').parent().parent().next().children('input').prop('disabled',false);\n"

            # specific for Qusetion 4a(i)
            returnStr << "$('input[id=\"FNARequest[FNAParty][0][FNAQuestionResponse][3][FNA_IS_REGULAR_INCOME]0\"]').parent().parent().next().children('input').prop('disabled',false);"
            # specific for Qusetion 4a(i)
            returnStr << " }\n"


          # specific for Qusetion 4a(i)
            returnStr << "if (!$('input[id=\"FNARequest[FNAParty][0][FNAQuestionResponse][3][FNA_IS_REGULAR_INCOME]0\"]').is(':checked')){\n"
            returnStr << "$('input[id=\"FNARequest[FNAParty][0][FNAQuestionResponse][3][FNA_IS_REGULAR_INCOME]0\"]').parent().parent().next().children('input').val('');"
            returnStr << "$('input[id=\"FNARequest[FNAParty][0][FNAQuestionResponse][3][FNA_IS_REGULAR_INCOME]0\"]').parent().parent().next().children('input').prop('disabled','true');"
            returnStr << " }\n"
          # specific for Qusetion 4a(i)


          # unchecked conditon starts
            returnStr << " if($(this).parent().parent().next().children('input').attr('name') == \""+$objectMapping[object.object.to_s]+"[responseValue]\" && !$(this).is(':checked')) {\n"
        # returnStr << "console.log('in loop_2 #{$objectMapping[object.object.to_s]} ');"
            returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').parent().parent().next().children('input').val('');\n"
            returnStr << "console.log($objectMapping[object.object.to_s]+[responseValue]);"
        # returnStr << "console.log('in loop_2 } ');"
            returnStr << " $('[name=\""+$objectMapping[object.object.to_s]+"[responseValue]\"]').parent().parent().next().children('input').prop('disabled','true');\n"

          returnStr << " }\n"
          returnStr << " })\n"
          returnStr << "</script>\n"
          if System.get_property('platform') == "ANDROID"
            returnStr << "\n"
            returnStr << "<script>" << "\n"
            returnStr << "$('input[name*=\"" << fieldname << "\"]').click(function(){\n"
            returnStr << "$('input[type=\"text\"]:focus').blur();\n"
            returnStr << "$('textarea:focus').blur();\n"
            returnStr << "});\n"
            returnStr << "</script>"<< "\n"
            returnStr << "\n"
          end
        rescue StandardError => se
          puts "Exception occured in getQuestionnaireRadioButton #{se}"
          puts se.backtrace
        end
        return returnStr
    end

        ##################################################################################################


     #Tejashree Nikam: 06-06-2017 Method to save policy and validate all tabs
    def executeSave
        WebView.execute_js("showLoadingMessage()")
        fnarequestObj = @params['FNARequest']['object']
        @fnarequest = FNARequest.loadObject(:first, :conditions=>{:object=> fnarequestObj})
        if @fnarequest.policyNum != nil
           @fnaRequest = MobiSys::BrowserHelper.convertToObject('FNARequest', @params['FNARequest'])
           @fnaRequest.persist
        end
        #Clear global error Hash

       WebView.navigate(url_for :action => :show, :id => @fnarequest.object.to_s, :query => {:submit => ''})
    end


    def executePreview
        WebView.execute_js("showLoadingMessage()")
         # fnarequestObj = @params['FNARequest']['object']
         # @fnarequest = FNARequest.loadObject(:first, :conditions=>{:object=> fnarequestObj})
        $total_error = Hash.new
        @error_exist= false
        $isNaBenefitTermPresent = false
        if $ShowFlag == true
            # fnarequestObj = @params['FNARequest']['object']
            # @fnarequest = FNARequest.loadObject(:first, :conditions=>{:object=> fnarequestObj})
            fnaObj = @params['id'][1..-1].chop
        else
            fnaObj = @params['FNARequest']['object']
        end

        @fnaRequest = FNARequest.loadObject(  :first, :conditions => {
                                                    :object => fnaObj
                                                }
                                            )
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @array_productIntroduced = []
        @fnaRequest.FNAIOProductList.each do |fnaIoProduct|
            @array_productIntroduced << fnaIoProduct.productIntroduced
        end
        @array_productIntroduced = @array_productIntroduced.flatten
        @array_productIntroduced = @array_productIntroduced.compact
        @array_productIntroduced_new = []
        @array_productIntroduced.each do |productIntroduced|
            @array_productIntroduced_new << productIntroduced.split(",")
        end
        @array_productIntroduced_new = @array_productIntroduced_new.flatten
        @array_productIntroduced_new = @array_productIntroduced_new.compact
        @FNAProduct_productId_List = FNAProduct.find(
            :all,
            :conditions => {
                {:name => 'id', :op => 'IN'} =>  @array_productIntroduced_new
                },
                :op => 'AND',
                :select => ['withdrawDt']
            )
        @array_FNAProduct_productId_List = []
        @FNAProduct_productId_List.each do |productId|
            @array_FNAProduct_productId_List << productId.withdrawDt
        end
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.flatten
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.compact

        @fnaLifeProtectionNeed = FNALifeProtectionNeed.loadObject( :first, :conditions => { :parentKey => fnaObj } )


     #Tejashree : Calculate Maximum Regular Premium, Maximum Single Premium, Additional Retirement Age check
      if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
        @shortfallAmt = 0
      else
      if @fnaLifeProtectionNeed.CalculatorTypeCd.to_s == "CALCTYPECOMPLEX"
        @total = (@fnaLifeProtectionNeed.protectionNeedPVAmt.to_i + @fnaLifeProtectionNeed.otherLiabilitiesAmt.to_i) - (@fnaLifeProtectionNeed.existingAssetAmt.to_i + @fnaLifeProtectionNeed.existingCoverageAmt.to_i)
        @shortfallAmt  = (@total.to_i * 1.3).round
      else
       if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
          @shortfallAmt = 0
      else
        if  @fnaLifeProtectionNeed.shortfallAmt == nil ||  @fnaLifeProtectionNeed.shortfallAmt == ""
          @shortfallAmt = 0
        else
          @shortfallAmt  = (@fnaLifeProtectionNeed.shortfallAmt * 1.3).round
        end
      end
      end

      if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
       @montlyExpenseAmt = 0
      else
        @montlyExpenseAmt = @fnaLifeProtectionNeed.montlyExpenseAmt
        if @montlyExpenseAmt == nil || @montlyExpenseAmt == ""
          @montlyExpenseAmt = 0
        end
      end
    end
      @fnaQuestionResponse = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd', :op => 'IN'} => '"FNA_IS_REGULAR_INCOME", "FNA_AMOUNT_OF_LIQUID_ASSETS", "FNA_GOAL_DURATION", "FNA_INCOME_PERCENT_FOR_PREMIUM", "FNA_FUND_SOURCE","FNA_LIQUID_ASSETS_TOTAL"',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionCd','fnaQuestionLookupDataCd', 'responseValue']

            )
        @array_fnaQuestionLookupDataCd = []
        @fnaQuestionResponse.each do |fnaQuestionResponse|
          @array_fnaQuestionLookupDataCd << fnaQuestionResponse.fnaQuestionLookupDataCd
        end

       @valuetofrom = Lookupvalue.find(
                :all,
                :conditions => {
                  {:name => 'cd', :op => 'IN'} =>  @array_fnaQuestionLookupDataCd
                 },
                 :op => 'AND',
                 :select => ['cd', 'valueFrom', 'valueTo']
               )


       # Maximum Regular Premium
        $flag4a = ''
        @fnaQuestionResponse.each do |fnaQuestionResponse|
          if fnaQuestionResponse.fnaQuestionCd == "FNA_IS_REGULAR_INCOME"
            if fnaQuestionResponse.fnaQuestionLookupDataCd == nil || fnaQuestionResponse.fnaQuestionLookupDataCd == ""
               @fnaRequest.addtnField8D =  0
            elsif fnaQuestionResponse.fnaQuestionLookupDataCd == "FNAQspecificAmount"
               @value4a = fnaQuestionResponse.responseValue
               $flag4a = true
            else
              @valuetofrom.each do |value|
                if fnaQuestionResponse.fnaQuestionLookupDataCd == value.cd
                  @value4a = value.valueTo
                  $flag4a = true
                end
              end
            end
          end
        end

      #Maximum Single Premium
      $flag4b = ""
       @fnaQuestionResponse.each do |fnaQuestionResponse|
        if fnaQuestionResponse.fnaQuestionCd == "FNA_LIQUID_ASSETS_TOTAL"
          if fnaQuestionResponse.fnaQuestionLookupDataCd == nil || fnaQuestionResponse.fnaQuestionLookupDataCd == ""
            @fnaRequest.addtnField9D =  0
          else
            $flag4b = true
            @value4b = fnaQuestionResponse.fnaQuestionLookupDataCd
          end
        end
      end


       @fnaQuestionResponse.each do |fnaQuestionResponse|
          if fnaQuestionResponse.fnaQuestionCd == "FNA_INCOME_PERCENT_FOR_PREMIUM"
            @valuetofrom.each do |value|
              if fnaQuestionResponse.fnaQuestionLookupDataCd == value.cd
                @value4d = value.valueTo
              end
            end
            if $flag4a == true
              @value4a = @value4a.to_s.gsub(",", "")
              @value4d = @value4d.to_s.gsub(",", "")
              @fnaRequest.addtnField8D = ((@value4a.to_i - @montlyExpenseAmt.to_i) * (@value4d.to_f/100)).round
              if @fnaRequest.addtnField8D < 0
                @fnaRequest.addtnField8D = 0
              end
            end
            if $flag4b == true
              @value4b = @value4b.to_s.gsub(",", "")
              @value4d = @value4d.to_s.gsub(",", "")
              @fnaRequest.addtnField9D = (@value4b.to_i * (@value4d.to_f/100)).round
              if @fnaRequest.addtnField9D < 0
                @fnaRequest.addtnField9D = 0
              end
            end
          end
        end
         @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]
       if !@fna_req_status.include?(@fnaRequest.statusCd.to_s )
        @fnaRequest.persist
       end
        @products_selected = []
        @fnaRequest.FNAIOProductList.each do |io_product|
            if io_product.productIntroduced != nil && io_product.productIntroduced.to_s != ""
               @products_selected << io_product.productIntroduced
            end
        end

          @products_selected_array = []
          @products_selected.each do |index|
            @products_selected_array << index.split(",")
          end

        @fnaParty = @fnaRequest.FNAPartyList[0]

        @fnaIOSelected = FNAIOSelected.find( :all, :conditions => { :parentKey => fnaObj } )
            @fnaIOSelectedArray =[]

            @fnaIOSelected.each do |ioselected|

            @fnaIOSelectedArray << ioselected.selectedFlag if ioselected.selectedFlag.to_s == "on"
           end
           @fnaIOSelectedArray = @fnaIOSelectedArray.compact



        errors = {}
        errors1 = Hash.new
        errors2 = Hash.new
        errors3 = Hash.new
        errors4 = Hash.new
        errors5 = Hash.new
        errors6 = Hash.new
        errors7 = Hash.new
        errors8 = Hash.new
        errors9 = Hash.new
        errors10 = Hash.new
        @fna_req_status = ["FNASIGNED", "FNASUBMIT", "SYNCDONE"]

        MobiSys::FnaBO.validateBasicDetailsAll(@fnaParty, errors1)
        if !@fna_req_status.include?(@fnaRequest.statusCd.to_s)
          MobiSys::FnaBO.validateQuestionnaireDetails(@fnaParty, @fnaRequest, errors2)
        end
        if @fnaLifeProtectionNeed == nil || @fnaLifeProtectionNeed == ""
          MobiSys::FnaBO.validateLifeProtectionNeed(@fnaRequest, errors3)
        else
          if @fnaLifeProtectionNeed.CalculatorTypeCd != 'CALCTYPECOMPLEX'
          MobiSys::FnaBO.validateLifeProtectionNeed(@fnaRequest, errors3)
          else
          MobiSys::FnaBO.validateLifeProtectionNeedComplex(@fnaRequest, errors3)
          end
        end
        MobiSys::FnaBO.validateProductSelection(@fnaRequest, @fnaIOSelectedArray, errors4)
        MobiSys::FnaBO.validateReasonsForRecommendationForQuestionSelected(@fnaRequest, errors5)
        MobiSys::FnaBO.validateReasonsForRecommendation(@fnaRequest, errors6)
        # MobiSys::FnaBO.validateOtherTargetSaving(@fnaRequest, errors7)
         errors9, @causeForDeviationOnPreview, $isNaBenefitTermPresent = MobiSys::FnaBO.validateProductIntroducedOnPreview(@fnaRequest,@fnaParty,@products_selected_array,errors8)
        # MobiSys::FnaBO.validatewithdrawnproduct(@fnaRequest, @array_FNAProduct_productId_List, errors10)
        errors =  MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(MobiSys::BrowserHelper.deep_merge(errors1,errors4), errors3), errors2), errors5), errors6), errors9), errors10)
        $total_error[getLabelValue('MESSAGE_ERRORS')] = errors

        @rules_of_q6_validation = []
        @rules_of_q6_validation <<  MobiSys::FnaBO.get_rule_for_q6_validation(@fnaRequest)
        #Ashwini 12-02-2017: Get the value of warning from product intro and raise validation for Q6b on Consideration tab to disable the question 6a
        if !@fna_req_status.include?(@fnaRequest.statusCd.to_s)
          if $derivedCauseForDeviationValues.to_s != "" || @causeForDeviationOnPreview.to_s !=""
             # @rules_of_q6_validation << $derivedCauseForDeviationValues
             @rules_of_q6_validation << @causeForDeviationOnPreview
          end

          if !@rules_of_q6_validation.empty?
            @cause_for_deviation_list = @rules_of_q6_validation.flatten
            @cause_for_deviation_string = @cause_for_deviation_list.join(",")
            @fnaRequest.causeForDeviation = @cause_for_deviation_string
          end
          if @cause_for_deviation_list.empty?
             @fnaRequest.reasonForDeviation = nil
          end
          #Vaibhav 12-02-2017: remove below fields for change in condition of @cause_for_deviation
          if !@cause_for_deviation_list.empty?
            @fnaRequest.reasonForRecoCd = nil
            @fnaRequest.reasonForRecommendation = nil
            @fnaRequest.addtnField2Str = nil
          end
            @fnaRequest.persist if $isConsiderationTabVisited.to_s == ""
       end

       # @error_exist = errors.empty? ? false : true #it will check if the errors exist ?
        if errors.empty?
            @error_exist = false
        html = ""
        render :string => @error_exist.to_json

        $fnaIO = MobiSys::IO::FnaIO.new
        $fnaIO.baseDO =  @fnaRequest
        MobiSys::UIGenUtilFNA.findTemplatePageMapping($fnaIO)
        MobiSys::UIGenUtilFNA.getHtmlStringandGeneratePDF(true, $fnaIO)

        if @fnaRequest.statusCd == "FNASIGNED" || @fnaRequest.statusCd == "FNASUBMIT" || @fnaRequest.statusCd == "SYNCDONE"
        else
           @fnaRequest.addtnField1Str = "FNACOMPLETE"
           @fnaRequest.persist
         end
         $total_error = Hash.new
         if OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'PREVIEWTIMER'}).value != nil
          @set_timer = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'PREVIEWTIMER'}).value.to_i
         else
          @set_timer = 5
         end

         #  WebView.navigate(url_for :action => :show, :id => @fnarequest.object.to_s, :query => {:submit => ''})
        render :action=>:show_preview, :layout => :sunlifeHKLayout

       else
           @error_exist = true
           WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
       end

    end

  #Tejashree Nikam: 07-06-2017 Method to send create email
  def email
    WebView.execute_js("showLoadingMessage()")
    $hide_sign_flag = false
    fnaObject = @params['id'][1..-1].chop
    @fnaRequest = FNARequest.loadObject(
      :first,
      :conditions => {
        :object => fnaObject
      }
    )

    @fnaProposer = @fnaRequest.getParty("PROPOSER")
    @outputPreferences = OutputPreferences.new

    @emailRequest = EmailRequest.new
    @emailRequest.entityGuid = @fnaRequest.guid
    @emailRequest.entityNumber = @fnaRequest.fnaNum
    @emailId =  AgentReg.find( :first, :conditions => { :agentId => @fnaRequest.agentId },  :op => 'AND',
                      :select => ['emailId'])
    @emailRequest.ccEmail = @emailId.emailId
    @emailRequest.toEmail = @fnaProposer.emailAddress
    @emailRequest.toEmail = @fnaProposer.emailAddress if @emailRequest.toEmail.to_s == ""
    @emailRequest.entityName = 'FNA'
    @emailRequest.outputPrefEntityGuid = @outputPreferences.uniqueKey

    @locales = Lookupvalue.find(
      :all,
      :conditions => {
        {:name => "key"} => "LANGUAGE",
        {
          :name => "cd",
          :op => "IN"
        } => $rhoconfig[:supported_locales].upcase.split(",")
      },
      :op => "AND",
      :select => ['cd','desc'],
      :order => ['sortOrder']
    )
    @setlanguage =  Application.getValue('DEFAULTLOCALE').value
    render :action => :email, :id=> fnaObject, :layout => :sunlifeHKLayout
  end

   #Tejashree Nikam: 07-06-2017 Method to send create email
  def emailFNA

    WebView.execute_js("showLoadingMessage()")
    $hide_sign_flag = false
    emailRequest = MobiSys::BrowserHelper.convertToObject('EmailRequest', @params['EmailRequest'])
    emailRequest.emailReqStatusCd = "PENDING"
    emailRequest.persist
    @fnaRequest = FNARequest.loadObject(  :first,
      :conditions => {
        :guid => emailRequest.entityGuid
      }
    )
    #OutputPreferences persist,retrieving and sync code added
    if @params['OutputPreferences']
      outputPref = MobiSys::BrowserHelper.convertToObject('OutputPreferences', @params['OutputPreferences'])
      outputPref.persist
      outputpreference = OutputPreferences.loadObject(
        :first,
        :conditions => {
          :guid => emailRequest.outputPrefEntityGuid
        }
      )
    end
    # signature_image = Image.loadObject(:first, :conditions=>{{:name=>'parentRefGuid'}=>quotation.uniqueKey})

    # @params['OutputPreferences']['languageCd']

    has_network = System::get_property('has_network')
    if has_network
      showSync = false
      # firstSync = Application.getValue('PRIMARYDATALASTSYNCDATE')
      # if firstSync
      #   #Calculate the time bomb period
      #   lastSyncDate = Time.load(firstSync.value)
      #   expiryDate = lastSyncDate + (AgentReg.getCurrentAgentReg.activeDays.to_i * 24 * 60 * 60)
      #   timeDiff = expiryDate - Time.now
      #   if timeDiff < 0
      #     showSync = true
      #   end
      # else
      #   #showSync = true
      #   showSync = false
      # end
      if showSync
        Alert.show_popup({
          :message => getLabelValue('MAXOFFLINETIME'),
          :title => '',
          :icon => :alert,
          :buttons => ['OK'],
          :callback => url_for(:action => :show_sync_callback)
        })
      else
        syncEntities = []
        # if signature_image!=nil
        #     syncEntities.push signature_image unless signature_image.uploadStatus == 'DONE'
        # end
        syncEntities.push @fnaRequest# if @fnaRequest.statusCd != 'SYNCDONE'
        syncEntities.push emailRequest
        $hide_sign_flag = false
        if outputpreference
          syncEntities.push outputpreference
        end

        begin
          MobiSys::Sync.sendEmailRequest(syncEntities, true)
          WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
          # WebView.navigate("/app/FNARequest/{#{@fnaRequest.object}}/illustration1")
        rescue StandardError => se
          #do nothing
          puts "exception: #{se}"
        end
      end
    else
      Alert.show_popup({
        :message => getLabelValue('EMAILREQUESTQUEUED'),
        :title => '',
        :icon => :alert,
        :buttons => ['OK'],
        :callback => WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
      })
    end

    # render :action => :email, :layout => :sunlifeHKLayout
  end

    def checkNetwork
        @network = "NETWORK"
        has_network = System::get_property('has_network')
        if !has_network
            @network = "NONETWORK"
        end
        render :action => :networkTest
    end


 #Method to submit FNA to online server
    def executeSubmit
        WebView.execute_js("showLoadingMessage()")
        $hide_sign_flag = ""
        @error_exist= false
        fnarequestObj = @params['FNARequest']['object']
        @fnaRequest = FNARequest.loadObject(:first, :conditions=>{:object=> fnarequestObj})
        @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaIoProductList = FNAIOProduct.find(
                :all,
                :conditions => {
                  {:name => 'parentKey'} => fnarequestObj
                 },
                 :op => 'AND',
                 :select => ['productRecommended']

            )
        @array_productRecommended = []
        @fnaIoProductList.each do |fnaIoProduct|
            @array_productRecommended << fnaIoProduct.productRecommended.split(",")
        end
        @array_productRecommended = @array_productRecommended.flatten
        @array_productRecommended = @array_productRecommended.uniq
        @FNAProduct_productId_List = FNAProduct.find(
                :all,
                :conditions => {
                  {:name => 'id', :op => 'IN'} =>  @array_productRecommended
                 },
                 :op => 'AND',
                 :select => ['productId']
               )
        @array_FNAProduct_productId_List = []
        @FNAProduct_productId_List.each do |productId|
            @array_FNAProduct_productId_List << productId.productId.split(",")
        end
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.flatten
        @array_FNAProduct_productId_List = @array_FNAProduct_productId_List.uniq

         @agent_Id = AgentReg.getCurrentAgentReg.agentId
         @applicableProductsList = AgentReg.find(
                          :all,
                          :conditions => {
                          { :name => 'agentId' } => @agent_Id
                          },
                          :op => 'AND',
                          :select => ['applicableProducts'])
        @agentRegApplicableProducts = @applicableProductsList.collect{|x| x.applicableProducts}
        @agentRegApplicableProducts = @agentRegApplicableProducts.first.split(",")

        @fnaPolicyLink = FNAPolicyLink.find( :all, :conditions => { :parentKey => @fnaRequest.object } )
            @policyarray =[]
            @fnaPolicyLink.each do |policy|
            @policyarray << policy.policyNum if policy.policyNum.to_s!=""
        end

        html = ""

        errors = {}

        errors1 = Hash.new
        errors2 = Hash.new
        MobiSys::FnaBO.validatePolicyDetails(@fnaRequest, @policyarray, errors1)
        MobiSys::FnaBO.validateIlasNonIlascondition(@fnaRequest, @array_FNAProduct_productId_List, @agentRegApplicableProducts, errors2)

        errors = MobiSys::BrowserHelper.deep_merge(errors1,errors2)

        # errors, @warningErrors = MobiSys::FnaBO.validatePolicyDetails(@fnaRequest, @policyarray, errors1, errors2)

        # $total_error[getLabelValue('PolicyNumber')] = errors

         # @error_exist = errors.empty? ? false : true #it will check if the errors exist ?

        if errors.empty?
            @error_exist = false
            WebView.execute_js("showLoadingMessage()")

            if @fnaRequest.fnaNum.to_s == ""
                @fnaRequest.fnaNum = SequenceNoGenerator.getNextNumber('FNA')
            end

            if @fnaRequest.statusCd != "FNASUBMIT"
                @fnaRequest.addtnField1Str = "FNASUBMIT"
                @fnaRequest.statusCd = "FNASUBMIT"
                @fnaRequest.versionID = @fnaRequest.versionID.to_i + 1
                @fnaRequest.addtnField11DT = Time.now
                @fnaRequest.persist
            end
            $showSign = true
            $hide_sign_flag = true
            filePath = MobiSys::UIGenUtilFNA.generateOutputHTML(@fnaRequest)
            $showSign = nil
            $hide_sign_flag = nil
            has_network = System::get_property('has_network')

            begin
                if has_network
                    jsonContent = File.read(filePath)
                    responseHash = {}

                    result = doJSONPost('/callFnaService.run', jsonContent)
                    responseHash = Rho::JSON.parse(result)

                    if responseHash.has_key?(FNARequest.onlineClassName) && responseHash[FNARequest.onlineClassName].to_s != ""
                        entity = Rho::JSON.parse(responseHash[FNARequest.onlineClassName])
                        entityObject = MobiSys::MobiSysEntitySchema.from_hash('FNARequest',entity[0])
                        oldFnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=> entityObject.fnaNum})
                        entityObject.object = oldFnaRequest.object
                        entityObject.guid = oldFnaRequest.guid
                        entityObject.statusCd = "SYNCDONE"
                        entityObject.persist
                        Alert.show_popup({
                            :message => getLabelValue('SUCCESS_FNA_SUBMIT'),
                            :title => '',
                            :icon => :info,
                            :buttons => ['OK']
                        })
                    end
                else
                    Alert.show_popup({
                        :message => getLabelValue('SYNC_MANUALLY'),
                        :title => '',
                        :icon => :info,
                        :buttons => ['OK']
                    })
                end

                WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
            rescue StandardError => se
                puts se.backtrace
                Alert.show_popup({
                    :message => getLabelValue('SERVERERROR'),
                    :title => '',
                    :icon => :info,
                    :buttons => ['OK']
                })
                WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
            end
            # WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s, :query => {:submit => ''})
        else

            @error_exist = true

            render :string => @error_exist.to_json

            WebView.navigate(url_for :action => :show, :id => @fnaRequest.object.to_s)
        end
                # if  @warningErrors.empty?
                # @warnings_exist = false
                # else
                #  @warnings_exist = true
                # end
                # html = ""
            # html << render(:partial => 'errors')
            #  return html
            # returnStr = ""
            # returnStr =  @error_exist.to_json + "|" + @warnings_exist.to_json + "|" + @warningErrors.to_json
            # render :string => returnStr
    end

    ##################################################################################################
    #Tejashree:14-08-2017 Loaddata on Product Introduction Tab
    def loaddata
      @fnaRequest = FNARequest.loadObject( :first, :conditions => { :object =>  @params['FNARequest']['object'] } )
      @fnaProposer = @fnaRequest.getParty("PROPOSER")
        @fnaIoProducts = @params['FNARequest']['FNAIOProduct']
          @products_selected = []
            @fnaRequest.FNAIOProductList.each do |io_product|
              @fnaIoProducts.each do|io_product_index,io_product_obj|

                if io_product_obj["productIntroduced"]!="" && io_product_obj["productIntroduced"] != nil
                   if io_product.object == io_product_obj["object"]

                      io_product.productIntroduced = io_product_obj["productIntroduced"]
                      @products_selected << io_product_obj["productIntroduced"]
                   end
                end
              end
            end

          @products_selected_array = []
          @array_final_id = []
          @products_selected.each do |index|
            @products_selected_array << index.split(",")
          end
          @array_final_id = @products_selected_array.flatten
          @array_final_id = @array_final_id.uniq

      @questionSeq = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_PURPOSE'
                 },
                 :op => 'AND',
                 :select => ['cd']

            )

       @questionres = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )

      if !@questionres.empty?
        @questionres.each do |res1|
           @response1 = res1.fnaQuestionLookupDataCd
        end
      end
        if @response1 == nil || @response1 == ""
           @resp1 = ""
        else
         @resp1 = @response1.split(',')
        end

       @questionSeq1 = Lookupvalue.find(
                :all,
                :order=>'sortOrder',
                :orderdir=>'ASC',
                :conditions => {
                  {:name => 'key', :op => 'IN'} => 'FNA_PRODUCT_TYPE'
                 },
                 :op => 'AND',
                 :select => ['cd']
            )

       @questionres1 = FNAQuestionResponse.find(
                :all,
                :conditions => {
                  {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                  {:name => 'parentKey'} => @fnaProposer.object
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      if !@questionres1.empty?
        @questionres1.each do |res2|
           @response2 = res2.fnaQuestionLookupDataCd
        end

      end

      if @response2 == nil || @response2 == ""
           @resp2 = ""
      else
          @resp2 = @response2.split(',')
      end

      @array_productmax1 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_PURPOSE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']
            )

      @response1 = []
      @productmax1 = []
      if !@array_productmax1.empty?
        @array_productmax1.each do |prod_intro1|
          @response1 << prod_intro1.fnaQuestionLookupDataCd
        end
      end

      @response1 = @response1.compact
      @productmax1 = @response1.uniq

       @array_productmax2 = FNAProductMatrix.find(
                  :all,
                  :conditions => {
                   {:name => 'fnaQuestionCd'} => 'FNA_PRODUCT_TYPE',
                   {:name => 'fnaProductSeq', :op =>'IN'} => @array_final_id
                 },
                 :op => 'AND',
                 :select => ['fnaQuestionLookupDataCd']

            )
      @response2 = []
      @productmax2 = []
      if !@array_productmax2.empty?
        @array_productmax2.each do |prod_intro2|
          @response2 << prod_intro2.fnaQuestionLookupDataCd
        end
      end
      @response2 = @response2.compact
      @productmax2 = @response2.uniq

       @mismatch1 = []
       @mismatch2 = []
       @mismatch1 = @resp1 - @productmax1
       @mismatch2 = @resp2 - @productmax2

      html = ""
      html << render(:partial => 'FNAProduct_List_Product_selected')
      return html
    end

    def getTabErrors
        # if $total_error.has_key?('tabID')
        #     $total_error['tabID'].delete(:FNAParty)
        #     $total_error['tabID'].delete(:FNARequest)
        #     $total_error['tabID'].delete(:FNAQuestionResponse)
        # end
        p "******getTabErrors*************************#{$total_error.to_json}"
        if !@params.has_key?('tabID')
            render :string => $total_error.to_json
        else
            render :string => $total_error[@params['tabID']].to_json
        end

    end


  def openPDF(downloadFolder="",fileName="")
    html = ""
    downloadFolder = Rho::Application.publicFolder
    downloadFolder = Rho::RhoFile.join(downloadFolder, "pdf")

    pdfrow = OfflineApplication.find(:first,:conditions=>{:property=>"FACTORTABLEPDF"})
    fileName = pdfrow.value if fileName == ""

    filePath = File.join(downloadFolder, fileName)
    if File::exist? filePath
      System.open_url filePath
      html << "<div><p>success</p></div>"
    else
      html << "<div><p>error</p></div>"
    end
    return html
  end

  def checkQ3
    $flagQ3New = false
    $flagQ3 = false
    render :string => $flagQ3.to_json
  end

  def checkProductIntro
    $flagProductIntro = false
    $flagProductIntroNew = false
    render :string => $flagProductIntro.to_json
  end

    def getUnlinkedQuotations
        unlinked_quotations_result = []
        html = ''
        quotations = Quotation.loadObject(
            :all,
            select: ['quotationRefNum', 'quoteStatusCd', 'object', 'systemUpdatedDt', 'fnaId', 'quotationExpiryDt'],
            conditions: {
                { name: 'fnaId' } => '',
                { name: 'quotationExpiryDt', op: '>' } => Date.today,
                op: 'AND'
            },
            order: 'systemUpdatedDt',
            orderdir: 'DESC'
        )
        fnaProduct = FNAProduct.find(:first,  conditions: { guid: @params['fnaProductGuid'] })
        fnaSIProductLink = FNASIProductLink.find(:first, conditions: { fnaProductId: fnaProduct.productId }) if fnaProduct
        if fnaSIProductLink
          siProductId = fnaSIProductLink.siProductId.to_s
          optionCd = fnaSIProductLink.optionCd.to_s
          fnaParty = FNAParty.loadObject(:first, conditions: { parentKey: @params['objectId'] }, loadChild: false)
          proposerNameDB = fnaParty ? "#{fnaParty.firstName1} #{fnaParty.lastName1}".downcase : ''
          quotations.each do |quotation|
              unlinked_quotations = {}
              proposer = quotation.getPartyByRole("PROPOSER")
              baseproduct = quotation.getBaseProduct
              productPlanOptionCd = baseproduct.productPlanOptionCd.to_s
              productId = baseproduct.productId.to_s
              quotationStatusUI = quotation.quoteStatusCd.to_s
              product = MobiSys::ProductUtil.getProduct(baseproduct.productSeq)
              insured = quotation.getMainInsured(baseproduct)
              if proposer
                  proposerNameUI = if proposer.partyTypeCd.to_s == 'ORGANIZATION'
                      proposer.corporateName.to_s
                  else
                      (proposer.lastname.to_s + " " + proposer.firstname.to_s)
                  end.strip[0..19].to_s.downcase
              end
              if insured
                  insuredNameUI = "#{insured.lastname} #{insured.firstname}"
              end
              if product
                  productNameUI =  "#{getLabelValue(product.shortName)} #{productPlanOptionCd}"
              end
              if productPlanOptionCd.eql?(optionCd) && productId.eql?(siProductId) && proposerNameDB.eql?(proposerNameUI)
                  unlinked_quotations[:quotationRefNum] = quotation.quotationRefNum
                  unlinked_quotations[:insuredNameUI] = insuredNameUI
                  unlinked_quotations[:product] = getLabelValue(productNameUI)
                  unlinked_quotations[:status] = getLabelValue(quotationStatusUI)
                  unlinked_quotations[:object] = quotation.object
                  unlinked_quotations_result << unlinked_quotations
              end
          end
        end
        html << render(partial: 'unlinkedQuotationTable', locals: { unlinked_quotations_result: unlinked_quotations_result })
        return html
    end

end



begin
    require 'FNARequest/f_n_a_request_controller_company'
rescue LoadError => e
    puts 'f_n_a_request_controller_company not included'
end


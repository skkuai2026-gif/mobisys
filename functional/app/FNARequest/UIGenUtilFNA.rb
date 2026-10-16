#encoding: UTF-8
require 'Application/application'
require 'CommonModules/mobisysbrowserhelper_company'
#require 'Policy/UIGenUtilEappHelper'

require 'time'
module MobiSys
    class UIGenUtilFNA

    def self.getHtmlStringandGeneratePDF(isHtml, fnaIO, apoPolicyIO=nil)
    
        $mvelHashMap = {}
        htmlBufferFinal = "".force_encoding(Encoding::UTF_8)
        htmlBufferPage = ""
        ulhtmlBuffer = ""
        htmlContent = Hash.new
        fnaIO.htmlContent = htmlContent
        
        listPageSectionDO = []

        if apoPolicyIO
            finalMapNew(apoPolicyIO)
        end

        if apoPolicyIO
            $mvelHashMap = populateMvelHashMap(fnaIO, $mvelHashMap, apoPolicyIO) #Need to write method for populateMvelHashMap
        else
            $mvelHashMap = populateMvelHashMap(fnaIO, $mvelHashMap) #Need to write method for populateMvelHashMap
        end

        #call for questinaires

        #getQuestionnairesDetailsOfParty(policyIO,$mvelHashMap)

        #unless illustrationModelDO == nil
            # elemMap = CommonUtil.convertToHash(illustrationModelDO.IllustrationFacetList, 'computedElementName')
        #end

        if fnaIO.templatePageMappingDO != nil and fnaIO.templatePageMappingDO.size > 0
            htmlBufferFinal << getCssStyle if isHtml #Need to write method for getCssStyle
            pagenumber = 0

            fnaIO.templatePageMappingDO.each do |templatePageMappingDOo|
                puts ">>>Processing templatePageMappingDO with id: #{templatePageMappingDOo.id}, pageName: #{templatePageMappingDOo.pageName}"
                if templatePageMappingDOo.mvelConditionRuby.to_s == "" or checkMvelCondition(templatePageMappingDOo,fnaIO,$mvelHashMap)
            
                    isFundList = false
                    fundList = nil
                    recurringFund = 1
                    isFundList = ("fundList" == templatePageMappingDOo.fund)

                    if($mvelHashMap["fundList"] != nil)
                      fundList = $mvelHashMap["fundList"]
                    end
                    # if(isFundList)
                    #   recurringFund = fundList.size
                    # end
                    begin
                        # if fundList.size != 0
                        #   $mvelHashMap["currentFundDO"] = fundList[fundList.size-recurringFund]
                        #   $mvelHashMap["currentFundCd"] = fundList[fundList.size-recurringFund].fundCd
                        # end
                        returnHashMap = {}
                        returnHashMap["repeatPage"] = true

                        $mvelHashMap["pagenumber"] = pagenumber + 1
                            while returnHashMap["repeatPage"] == true do
                                if templatePageMappingDOo.isAPOFl and templatePageMappingDOo.isAPOFl == "YES"
                                    returnHashMap = createPage(isHtml, apoPolicyIO, templatePageMappingDOo, $mvelHashMap, returnHashMap, pagenumber)
                                else
                                    returnHashMap = createPage(isHtml, fnaIO, templatePageMappingDOo, $mvelHashMap, returnHashMap, pagenumber)
                                end
                                htmlContent[returnHashMap['pagenumber']] = {"name" => templatePageMappingDOo.pageName, "content" => returnHashMap['page']}
            
                                htmlBufferPage << returnHashMap["page"].force_encoding(Encoding::UTF_8)
                                pagenumber = returnHashMap["pagenumber"]
                                puts ">>>processed page: #{pagenumber}"
                            end
                        recurringFund = recurringFund - 1
                    end while (recurringFund >= 1)
                end
            end

            totalPages = htmlContent.keys.size
            totalSkipNumber = 0
            i = 1
            while i<=pagenumber
                if htmlContent[i]["content"].include? "$SKIPPAGENUMBER$"
                    totalSkipNumber = totalSkipNumber - 1
                end
                i = i + 1
            end
            skipPageNumber = 0
            htmlBuffer = ""
            i = 1
            while i<=pagenumber
                if htmlContent[i]["content"].include? "$SKIPPAGENUMBER$"
                    skipPageNumber = skipPageNumber - 1
                    htmlContent[i]["content"].gsub!('$SKIPPAGENUMBER$',"") unless $showPdf
                else
                    htmlContent[i]["content"].gsub!('$PAGENUMBER$',(i+skipPageNumber).to_s)
                    htmlContent[i]["content"].gsub!('$TOTALPAGENUMBER$',(pagenumber + totalSkipNumber).to_s)
                end
                i = i + 1
            end
            pagenumber = pagenumber - 1
        end
        htmlBufferFinal << htmlBufferPage
    end



    def self.getCssStyle
      return "<style type='text/css'>
              .body{
                font-family: Verdana;
                word-wrap: break-word;
                background-color: #FFFFFF;
                height: 100%;
              }

              .shadetabs{
              padding: 3px 0;
              margin-left: 0;
              margin-top: 1px;
              margin-bottom: 0;
              font: bold 12px Verdana;
              list-style-type: none;
              text-align: left; /*set to left, center, or right to align the menu as desired*/
              }

              .shadetabs li{
              display: inline;
              margin: 0;
              }

              .shadetabs li a{
              text-decoration: none;
              position: relative;
              z-index: 1;
                padding: 3px 7px;
                margin-right: 3px;
                border: 1px solid #778;
                color: #fff;
                background-color:#06F;
                }
                
                .shadetabs li a:visited{
                color: #fff;
                }
                
                .shadetabs li a:hover{
                text-decoration: underline;
                color: #fff;
                }
                
                .shadetabs li a.selected{ /*selected main tab style */
                position: relative;
                top: 1px;
                }

              .shadetabs li a.selected{ /*selected main tab style */
              background-color:#fff;
              border-bottom-color: white;
              color:#000;
              }

              .shadetabs li a.selected:hover{ /*selected main tab style */
              text-decoration: none;
              }

              </style>"
    end






def maskDecimal(number)
    dec='.'
    sep=','
    number='%.2f'% number if number.to_s != ""   
    begin

      num = MobiSys::Math.round(number,2) if number.to_s != ""     
    rescue
       num = number       
    end
    num = number unless number
    num = num.to_s.sub(/\./, dec)
    dec = Regexp.escape dec
    maskedNum = num.reverse.gsub(/(\d{3})(?=\d)(?!\d*#{dec})/, "\\1#{sep}").reverse
    maskedNum
  end



    # def getFNAProduct(id)
    #     # returnObject = nil      
    #     # self.FNAProductList.each do |object|
    #     #     if object.id == id
    #     #         returnObject = object
            
    #     #     end
    #     # end
    #     # return returnObject
        
    #     fnaProductObject = FNAProduct.find(:first, :conditions=>{'id'=>id})
    #     return fnaProductObject
    #     if fnaProductObject
    #       return fnaProductObject
    #     else
          
    #       return nil  
    #     end  
    # end


    def self.getFNAProduct(id)
        fnaProductObject = FNAProduct.find(:first, :conditions=>{'id'=>id})
        return fnaProductObject
        if fnaProductObject
          return fnaProductObject
        else
          return nil  
        end  
    end

    def self.getFNAPolicyNumber(object)
        fnaPolicyNumberlist = FNAPolicyLink.loadObject( :all, :conditions => { :parentKey => object } )
        policyNumberlistfordisplay = ""
        if fnaPolicyNumberlist.size == 0
            return policyNumberlistfordisplay
        else 
            i = 1
            fnaPolicyNumberlist.each do |number|
                if i < fnaPolicyNumberlist.size
                    policyNumberlistfordisplay << number.policyNum.to_s + ", "
                    i = i + 1
                elsif i == fnaPolicyNumberlist.size
                    policyNumberlistfordisplay << number.policyNum.to_s 
                end
            end
        end
        return policyNumberlistfordisplay
    end

    def self.populateMvelHashMap(fnaIO, mvelHashMap, apoPolicyIO=nil)
        mvelHashMap["fnaIO"] = fnaIO
        mvelHashMap["fnaDO"] = fnaIO.baseDO
        mvelHashMap["lifeprotection"] = mvelHashMap["fnaDO"].FNALifeProtectionNeedList[0] if mvelHashMap["fnaDO"].FNALifeProtectionNeedList.size > 0
        mvelHashMap["otherprotection"] = mvelHashMap["fnaDO"].FNAOtherProtectionNeedList[0] if mvelHashMap["fnaDO"].FNAOtherProtectionNeedList.size > 0
        mvelHashMap["retirementprotection"] = mvelHashMap["fnaDO"].FNARetirementNeedList[0] if mvelHashMap["fnaDO"].FNARetirementNeedList.size > 0
        # mvelHashMap["otherTargetNeed"] = mvelHashMap["fnaDO"].FNAOtherTargetNeedList[0] if mvelHashMap["fnaDO"].FNAOtherTargetNeedList.size > 0
        # mvelHashMap["educationNeed"] = mvelHashMap["fnaDO"].FNAEducationNeedList[0] if mvelHashMap["fnaDO"].FNAEducationNeedList.size > 0
        p "***mvelHashMap***hide_sign_flag***************#{$hide_sign_flag}"
        mvelHashMap["hide_sign_flag"] = $hide_sign_flag

        
   
      # @proposerParty=policyIO.baseDO.getParty("PROPOSER")
      # @primaryParty=policyIO.baseDO.getParty("PRIMARY")
      # @mailingParty=policyIO.baseDO.getParty("MAILINGADDRESS")
      # @beneficiaryPartyRoles =policyIO.baseDO.getPartyList("NOMINEE")
      # beneficiaryList = []
      #   @beneficiaryPartyRoles.each do |partyRole|
      #       party = Party.loadObject(:first, :conditions => {{ :name => 'guid' } => partyRole.guid})
      #       beneficiaryList << party
      #          p "@beneficiaryPartyRole=====>#{partyRole}"
      #          p "@beneficiaryParty=====>#{party}"
            
      #   end
      # mvelHashMap["beneficiaryList"] = beneficiaryList
      # p "beneficiaryList=====>#{beneficiaryList[0]}"
      # p "beneficiaryList.size================>#{beneficiaryList.size}"

      # mvelHashMap["proposerParty"] = @proposerParty if @proposerParty
      # mvelHashMap["primaryParty"] = @primaryParty if @primaryParty
      # mvelHashMap["mailingParty"] = @mailingParty if @mailingParty

      # mvelHashMap["primaryPartyAdditional"] = @primaryParty.getPartyAdditionalField if @primaryParty.getPartyAdditionalField
      # mvelHashMap["proposerPartyAdditional"] = @proposerParty.getPartyAdditionalField if @proposerParty.getPartyAdditionalField

      # mvelHashMap["primaryPartyAddressRESIDENTIAL"] = @primaryParty.getPartyAddress("RESIDENTIAL") if @primaryParty.getPartyAddress("RESIDENTIAL")
      # mvelHashMap["primaryPartyAddressPERMANENT"] = @primaryParty.getPartyAddress("PERMANENT") if @primaryParty.getPartyAddress("PERMANENT")
      # mvelHashMap["primaryPartyAddressOFFICE"] = @primaryParty.getPartyAddress("OFFICE") if @primaryParty.getPartyAddress("OFFICE")

      # mvelHashMap["proposerPartyAddressRESIDENTIAL"] = @proposerParty.getPartyAddress("RESIDENTIAL") if @proposerParty.getPartyAddress("RESIDENTIAL")
      # mvelHashMap["proposerPartyAddressPERMANENT"] = @proposerParty.getPartyAddress("PERMANENT") if @proposerParty.getPartyAddress("PERMANENT")
      # mvelHashMap["proposerPartyAddressOFFICE"] = @proposerParty.getPartyAddress("OFFICE") if @proposerParty.getPartyAddress("OFFICE")

      # mvelHashMap["proposerPartyAddressMAILINGADDRESS"] = @proposerParty.getPartyAddress("MAILINGADDRESS") if @proposerParty.getPartyAddress("MAILINGADDRESS")

      # mvelHashMap["proposerPartyEmployment"] = @proposerParty.getPartyEmployment if @proposerParty.getPartyEmployment
      # mvelHashMap["primaryPartyEmployment"] = @primaryParty.getPartyEmployment if @primaryParty.getPartyEmployment

      # mvelHashMap["proposerPartyContact"] = @proposerParty.getPartyContact("PHILIPPINESNUM") if @proposerParty.getPartyContact("PHILIPPINESNUM")

      # mvelHashMap["proposerPartyEmail"] = @proposerParty.getPartyEmail if @proposerParty.getPartyEmail

      # mvelHashMap["policyAdditional"] = policyIO.baseDO.getAdditionalFields if policyIO.baseDO.getAdditionalFields




      # # p "policy in uigen====>#{policyIO.baseDO}"
      #  p "primaryPartyEmployment=======>#{@primaryPartyEmployment}"
      #  p "proposerPartyContact=======>#{@proposerParty.getPartyContact("PHILIPPINESNUM")}"
      # # p "primaryPartyAdditional=======>#{@proposerParty}"
      # # p "primaryPartyAdditional=======>#{@proposerParty.getPartyAdditionalField}"
      # # p "primaryPartyAdditional=======>#{@proposerParty.PartyAdditionalFieldList}"
      # # p "primaryPartyAdditional=======>#{@proposerParty.PartyAdditionalFieldList[0]}"
      # productHash = Hash.new
      # mvelHashMap['productHash'] = productHash
      # productDO = Product.loadObject(:first, :conditions => {:Id => policyIO.baseDO.getBaseProduct.productSeq})
      # productHash[productDO.id] = productDO
      # #if productNameDO != nil
      # mvelHashMap["productDO"] = productDO if productDO
      # #end

     #  fundDOFinderList = Fund.loadObject(:all, :order => 'sortOrder', :orderdir => 'ASC')
     #  fundDOHashMap = CommonUtil.convertToHash(fundDOFinderList, "fundCd")

     #  if apoPolicyIO
     #    mvelHashMap["apoPolicyIO"] = apoPolicyIO

     #    premiumFacetDO =  apoPolicyIO.baseDO.getBasePlan().product.getFacet("PREMIUMDETAILS")

     #    if premiumFacetDO and premiumFacetDO.OfflinePremiumDetailsList[0]
     #      mvelHashMap["apoPremiumDetailsDO"] = premiumFacetDO.OfflinePremiumDetailsList[0]
     #    else
     #      mvelHashMap["apoPremiumDetailsDO"] = nil
     #    end

     #    apoPolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList.each do |qpif|
     #      if qpif.allocationPerc
     #        mvelHashMap["apochosenFundCd"] = qpif.fundCd
     #      end
     #    end



     #    #//14th Nov 2013 start
     #    #mvelHashMap["apoFundList"] = apopolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList
     #    apoFundList = []
     #    apoFundListHashMap = CommonUtil.convertToHash(apoPolicyIO.baseDO.getBasePlan.QuotationProductInvestmentFundList, "fundCd") #Need to code for ruby
     #    fundDOFinderList.each do |fundDO2|
     #      if apoFundListHashMap.has_key?(fundDO2.fundCd)
     #        if apoFundListHashMap[fundDO2.fundCd].allocationPerc != nil
     #          apoFundList << apoFundListHashMap[fundDO2.fundCd]
     #        end
     #      end
     #    end
     #    mvelHashMap["apoFundList"] = apoFundList
     #    #//14th Nov 2013 end



     #    apoRiderLIst = apoPolicyIO.baseDO.getRiders
     #    apoRiderLIst.each do |rider|
     #      mvelHashMap[rider.productId] = rider
     #    end
     #    mvelHashMap["apoRiderList"] = apoRiderLIst
     #  else
     #    mvelHashMap["apoPolicyIO"] = nil
     #  end
     # if policyIO.baseDO.getRiders.to_s!=""
     #  policyIO.baseDO.getRiders.each do |rider|
     #    mvelHashMap[rider.productId] = rider
     #  end
     # end
     #  finderList = Product.find(:all, :conditions => {:productTypeCd => 'RIDER'}, :order => 'sortOrder', :orderdir => 'ASC') #Need to add sort condition

     #  finderList.each do |productDO2|
     #    if !mvelHashMap.has_key?(productDO2.productId)
     #      mvelHashMap[productDO2.productId] = nil
     #    else
     #      productHash[productDO2.id] = Product.loadObject(:first,:conditions=>{:productId=>productDO2.productId})
     #    end
     #  end

     #  if policyIO.baseDO.getRiders.to_s!=""
     #  riderListHashMap = CommonUtil.convertToHash(policyIO.baseDO.getRiders, "productId")

     #  @riderList = []
     #  finderList.each do |productDO2|
     #    if riderListHashMap.has_key?(productDO2.productId)
     #      @riderList << riderListHashMap[productDO2.productId]
     #    end
     #  end
     #  end
     #  #generating the hashmap for the ridersQuotationProduts that are not attatched with quotation
     #  #quotationProductDORiderHashMap = CommonUtil.getInstance().getHashedList("productId", finderList) #Ruby code required

     #  policyProductDORiderHashMap = CommonUtil.convertToHash(finderList, "productId")

     #  policyIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList.each do |fund|
     #    if fund.allocationPerc != nil
     #      mvelHashMap[fund.fundCd] = fund
     #    end
     #  end



     #  fundDOFinderList.each do |fundDO2|
     #    if !mvelHashMap.has_key?(fundDO2.fundCd)
     #      mvelHashMap[fundDO2.fundCd] = nil
     #    end
     #  end

     #  fundList = []
     #  fundListHashMap = CommonUtil.convertToHash(policyIO.baseDO.getBaseProduct.PolicyProductInvestmentFundList, "fundCd") #Need to code for ruby

     #  fundDOFinderList.each do |fundDO2|
     #    if fundListHashMap.has_key?(fundDO2.fundCd)
     #      if fundListHashMap[fundDO2.fundCd].allocationPerc != nil
     #        fundList << fundListHashMap[fundDO2.fundCd]
     #      end
     #    end
     #  end



     #  mvelHashMap["fundList"] = fundList
     #  mvelHashMap["riderList"] = @riderList
     #  mvelHashMap["fundDOHashMap"] = fundDOHashMap
     #  mvelHashMap["policyProductDORiderHashMap"] = policyProductDORiderHashMap

     #  #adding helper class in hashmap
     #  #UIGenUtilCompanyHelper.getUpdateHashMap(mvelHashMap)
     #  mvelHashMap["mvelHashMap"] = mvelHashMap
     #  mvelHashMap["riderListHashMap"] = riderListHashMap
=begin
      dt = Time.parse(policyIO.baseDO.quotationDt.to_s)
      mvelHashMap["calendarYear"] = dt.year
=end
      return mvelHashMap
    end

    def self.checkMvelCondition(sectionDetailsDO, fnaIO, mvelHashMap)
      # policyDO = mvelHashMap["policyDO"]
      #p "sectionDetailsDO.mvelConditionRuby==============>#{sectionDetailsDO.mvelConditionRuby}"
      if sectionDetailsDO.mvelConditionRuby.to_s != ""
        eval sectionDetailsDO.mvelConditionRuby
      end
    end

    def self.createPage(ishtml, fnaIO, templatePageMappingDO, mvelHashMap, returnHashMap, pagenumber)
      pageSectionDO = PageSection.new
      htmlBuffer = "".force_encoding(Encoding::UTF_8)
      newtemplatePageMappingDO = {}
      newtemplatePageMappingDO = templatePageMappingDO

      if ishtml and $showPdf != true
        htmlBuffer << "<!--Processing page: #{templatePageMappingDO.id}-->".force_encoding(Encoding::UTF_8)
        htmlBuffer << getCssStyle.force_encoding(Encoding::UTF_8)
        htmlBuffer << "<div id=\"output"+pagenumber.to_s+"\" class=\"tabcontent\">".force_encoding(Encoding::UTF_8)
      end

      listPageHeaderSectionMappingDO = PageHeaderSectionMapping.loadObject(:all, :conditions => {:pageHeaderSeq => newtemplatePageMappingDO.pageHeaderSeq}, :order => 'displayOrder', :orderdir => 'ASC')
      repeatHashMap = {}
      if returnHashMap.has_key?("repeatPageFrom")
        repeatHashMap["repeatPageFrom"] = returnHashMap["repeatPageFrom"]
        repeatHashMap["skipPolicyseq"] = returnHashMap["skipPolicyseq"]
        repeatHashMap["skipAge"] = returnHashMap["skipAge"]
      end
      listPageHeaderSectionMappingDO.each do |pageHeaderSectionMappingDO|
        pageSectionDO = PageSection.loadObject(:first, :conditions => {:id => pageHeaderSectionMappingDO.pageSectionSeq})
        if pageSectionDO != nil && (pageHeaderSectionMappingDO.mvelConditionRuby == nil || (eval pageHeaderSectionMappingDO.mvelConditionRuby))
          # if pageSectionDO
          puts ">>>processing pageSectionDO with id: #{pageSectionDO.id}"
          pageSectionDO.SectionDetailsList.sort{|x,y| x.displayOrder.to_i<=>y.displayOrder.to_i}.each do |sectionDetailsDO|
            #next unless Application.getValue('SectionDetails').value.include? sectionDetailsDO.id.to_s
            puts ">>>processing sectionDetailsDO with id: #{sectionDetailsDO.id} #{repeatHashMap} "
            #puts ">>>processing sectionDetailsDO with label1ruby as: #{sectionDetailsDO.label1ruby}"
            p "showpdf value is #{$showPdf}"
            if sectionDetailsDO.mvelConditionRuby.to_s == "" or checkMvelCondition(sectionDetailsDO,fnaIO,mvelHashMap)
              if sectionDetailsDO and sectionDetailsDO.elementType and sectionDetailsDO.onlyType and (sectionDetailsDO.onlyType == "HTML" or sectionDetailsDO.onlyType=="PDF")
                if sectionDetailsDO.onlyType == "HTML" and $showPdf != true
                  repeatHashMap = processPage(sectionDetailsDO,fnaIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
                elsif sectionDetailsDO.onlyType == "PDF" and $showPdf == true
                  repeatHashMap = processPage(sectionDetailsDO,fnaIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
                end
              else
                repeatHashMap = processPage(sectionDetailsDO,fnaIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
              end
            end
          end
        end
      end

      if ishtml
        htmlBuffer << "</div><!--div class tabcontent end-->".force_encoding(Encoding::UTF_8)
      else
        #If condition used for PDF generation on client side
        QuotationRequestUtil.getInstance().generateQuotationPDFFileUsingBuffer(fnaIO, nil, htmlBuffer, fnaIO.getBaseDO().getId() +"-"+ pagenumber)
      end
      returnHashMap["page"] = htmlBuffer
      pagenumber = pagenumber+1
      returnHashMap["pagenumber"] = pagenumber
      returnHashMap["repeatPage"] = false
      if repeatHashMap.has_key?("repeatPageFrom")
        returnHashMap["repeatPageFrom"] = repeatHashMap["repeatPageFrom"]
        returnHashMap["skipPolicyseq"] = repeatHashMap["skipPolicyseq"]
        returnHashMap["skipAge"] = repeatHashMap["skipAge"]
        returnHashMap["repeatPage"] = true
      end

      return returnHashMap
    end

  def self.processPage(sectionDetailsDO, fnaIO, htmlBuffer, mvelHashMap, returnHashMapPage, ishtml, divHide)
      htmlBuffer << "<!-- Processing sectionDetailsDO with id #{sectionDetailsDO.id} -->".force_encoding(Encoding::UTF_8)
      element = ""
      rate = ""
      max = 0
      policyYearCondition = ""
      ageCondition = ""
      mvelPolicyYear = ""
      mvelAge = ""
      tdStyle = ""
      tableSpace=""

      if true

        if fnaIO.outputPreferencesDO && fnaIO.outputPreferencesDO.languageCd != nil && fnaIO.outputPreferencesDO.languageCd.upcase != 'EN'
          sectionDetailsDO.label1Ruby = sectionDetailsDO.label2Ruby
        elsif fnaIO.outputPreferencesDO.to_s == ""
          @language =  Application.getValue('DEFAULTLOCALE').value
          if @language != nil && @language.upcase != 'EN'
            sectionDetailsDO.label1Ruby = sectionDetailsDO.label2Ruby
          end
        end
        
        if sectionDetailsDO != nil and sectionDetailsDO.includeTd and sectionDetailsDO.includeTd.upcase! == "YES"
          htmlBuffer << "#{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
          divHide = false
        end

        label1Ruby = nil
        if sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "HTML"
          value = ""
          if sectionDetailsDO.label1Ruby != nil && sectionDetailsDO.label1Ruby.include?("$PATH$") #need to write equivalent code for ruby
            pPATH = ""
            if ishtml
              pPATH = "/public/images/FNA/outputimages/"
              label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
            else
              label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
            end
          else
            label1Ruby = sectionDetailsDO.label1Ruby
          end
          htmlBuffer << processProperty(label1Ruby, fnaIO, mvelHashMap).force_encoding(Encoding::UTF_8)
        elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "IMAGE"
          if ishtml
            htmlBuffer << "<img src=\"/systemcommon/pdfGenerated/illustration/" + sectionDetailsDO + "\" " + sectionDetailsDO.property1 + " >".force_encoding(Encoding::UTF_8)
          else
            htmlBuffer << "<img src=\"" + sectionDetailsDO + "\" " + sectionDetailsDO.property1 + " >".force_encoding(Encoding::UTF_8)
          end

        elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "STATIC"
          if divHide
            htmlBuffer << "<div #{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
          end
          str = processProperty(sectionDetailsDO.label1Ruby,fnaIO,mvelHashMap).force_encoding(Encoding::UTF_8)
          htmlBuffer << str.force_encoding(Encoding::UTF_8)
          if divHide
            htmlBuffer << "</div>".force_encoding(Encoding::UTF_8)
          end

        elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "STYLE"
          htmlBuffer << "<style type=\"text/css\">".force_encoding(Encoding::UTF_8)
          htmlBuffer << sectionDetailsDO.label1Ruby.force_encoding(Encoding::UTF_8)
          htmlBuffer << "</style>".force_encoding(Encoding::UTF_8)

        elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "TABLE" && fnaIO.baseDO.getBaseProduct.productTerm !=nil
          sectionDetailsDO.label1Ruby = sectionDetailsDO.label1Ruby.gsub("\r","").gsub("\n","")
          if sectionDetailsDO.label1Ruby!= nil && sectionDetailsDO.label1Ruby.include?("${") && sectionDetailsDO.label1Ruby.include?("}$") #Need to write ruby equivalent code
            if sectionDetailsDO.label1Ruby.include?("mvel${") && sectionDetailsDO.label1Ruby.include?("}$mvel") #Need to write ruby equivalent code
              staticcontent = sectionDetailsDO.label1Ruby
              finalString = ""
              while staticcontent.include?("mvel${") #Need to write ruby equivalent code for the whole block
                startindex = staticcontent.index("mvel${")
                finalString << staticcontent[0, startindex]
                staticcontent = staticcontent[startindex+"mvel${".length,staticcontent.length]
                endindex = staticcontent.index("}$mvel")
                element2 = staticcontent[0,endindex]
                element2 = element2.strip
                finalString << (eval(element2))
                staticcontent = staticcontent[endindex+"mvel${".length,staticcontent.length]
                staticcontent = staticcontent.gsub("#", ";")#Need to see if code is required or not
              end
              tempStr = (finalString + staticcontent).gsub("$SEMI$", "")
              sectionDetailsDO.label1Ruby = tempStr #Need to see if code is required or not
            end #467
            if sectionDetailsDO.label1Ruby.include?("element${") && sectionDetailsDO.label1Ruby.include?("}$element")
              element = extract(sectionDetailsDO.label1Ruby,"element")
            end
            if sectionDetailsDO.label1Ruby.include?("rate${") && sectionDetailsDO.label1Ruby.include?("}$rate")
              rate = extract(sectionDetailsDO.label1Ruby,"rate")
            else
              elemlabel1Ruby = element.split(",")
              elemlabel1Ruby.each do |ev|
                if(ev.include?("~"))
                  rate << "0~0,"
                else
                  rate << "0,"
                end
              end
              rate = rate[0, rate.length-1]
            end

            if sectionDetailsDO.label1Ruby.include?("max${") && sectionDetailsDO.label1Ruby.include?("}$max")
              max = extract(sectionDetailsDO.label1Ruby,"max")
            end

            if sectionDetailsDO.label1Ruby.include?("policyYearCondition${") && sectionDetailsDO.label1Ruby.include?("}$policyYearCondition") #Need to write ruby equivalent code for the whole block
              policyYearCondition = extract(sectionDetailsDO.label1Ruby,"policyYearCondition")
            end

            if sectionDetailsDO.label1Ruby.include?("ageCondition${") && sectionDetailsDO.label1Ruby.include?("}$ageCondition")
              ageCondition = extract(sectionDetailsDO.label1Ruby,"ageCondition")
            end

            if sectionDetailsDO.label1Ruby.include?("mvelPolicyYear${") && sectionDetailsDO.label1Ruby.include?("}$mvelPolicyYear")
              mvelPolicyYear = extract(sectionDetailsDO.label1Ruby, "mvelPolicyYear")
            end

            if sectionDetailsDO.label1Ruby.include?("mvelAge${") && sectionDetailsDO.label1Ruby.include?("}$mvelAge")
              mvelAge = extract(sectionDetailsDO.label1Ruby,"mvelAge")
            end

            if sectionDetailsDO.label1Ruby.include?("tableSpace${") && sectionDetailsDO.label1Ruby.include?("}$tableSpace")
              tableSpace = extract(sectionDetailsDO.label1Ruby,"tableSpace")
            end

            if sectionDetailsDO.label1Ruby.include?("tdStyle${") && sectionDetailsDO.label1Ruby.include?("}$tdStyle")
              tdStyle = extract(sectionDetailsDO.label1Ruby,"tdStyle")
            else
              elemValue=element.split(",")
              elemValue.each do |ev|
                if ev.include?("~")
                  tdStyle << "nil~nil,"
                else
                  tdStyle << "nil,"
                end
              end
              tdStyle = tdStyle[0, tdStyle.length-1]
            end
          end
        end
      end
      #Swati Ahire 19-06-2014: Replaced sectionDetailsDO.includeTd with sectionDetailsDO.includeTD
      if sectionDetailsDO != nil && sectionDetailsDO.includeTD && sectionDetailsDO.includeTD.upcase! == "YES"
        htmlBuffer << "</TD>".force_encoding(Encoding::UTF_8)
      end
      #p "htmlBuffer---------LAST#{htmlBuffer}"

      return returnHashMapPage
    end



    
    #Returns list of years in string format
    def self.getlist(value, sectionDetailsDOValue)
      numbers = Array.new
      new_str = value.to_s.split(',')
      new_str.each_with_index do |str_arr, i|
        if str_arr.include?('-')
          new_str_arr = str_arr.split('-')
          if new_str_arr[0] == nil || new_str_arr[0].strip  == ""
            next
          end
          if new_str_arr[0].to_i > new_str_arr[1].to_i
            new_str_arr[1].to_i.upto(new_str_arr[0].to_i) do |innerStr|
              numbers.push innerStr
            end
          else
            new_str_arr[0].to_i.upto(new_str_arr[1].to_i) do |innerStr|
              numbers.push innerStr
            end
          end
        else
          numbers.push str_arr.to_i
        end
      end
      yearConditionSort = true
      if sectionDetailsDOValue.include? "yearConditionSort${" and sectionDetailsDOValue.include? "}$yearConditionSort"
        yearConditionSort = extract(sectionDetailsDOValue, "yearConditionSort")
      end
      if yearConditionSort and yearConditionSort.to_s.downcase == "true"
        numbers.sort!
      end
      return numbers
    end


    def self.evaluateExpression(expression, mvelHashMap, fnaIO)
        results = MobiSys::DataObjects::Results.new
        results.createAttr('fnaIO')
        results.setAttr('fnaIO', fnaIO)
        results.createAttr('productDO')
        results.setAttr('productDO', mvelHashMap['productDO'])
        results.createAttr('productHash')
        results.setAttr('productHash', mvelHashMap['productHash'])
        # results.createAttr('quotationProductDORiderHashMap')
        # results.setAttr('quotationProductDORiderHashMap',mvelHashMap['quotationProductDORiderHashMap'])
        results.createAttr('mvelHashMap')
        results.setAttr('mvelHashMap', mvelHashMap)
        # results.createAttr('apopolicyIO')
        # results.setAttr('apopolicyIO', mvelHashMap['apopolicyIO'])
        results.defineMethod("testing",expression)
        return results.testing.to_s
    end

    def self.processProperty(value, fnaIO, mvelHashMap)
      finalString = "".force_encoding(Encoding::UTF_8)
      staticcontent = value
      if staticcontent && staticcontent.include?("si${") && staticcontent.include?("}$si")
        while staticcontent.include?("si${")
          startindex = staticcontent.index("si${")
          finalString << staticcontent[0, startindex].force_encoding(Encoding::UTF_8)
          staticcontent = staticcontent[startindex+"si${".length, staticcontent.length] #Need ruby code
          endindex = staticcontent.index("}$si")
          element = staticcontent[0, endindex]
          element = element.strip

          if fnaIO.getIllustrationHeaderFieldValue(element) == nil
            finalString << "Element "+element+" Not found".force_encoding(Encoding::UTF_8) #Need to check if code works in ruby or not
          else
            finalString << fnaIO.getIllustrationHeaderFieldValue(element).force_encoding(Encoding::UTF_8)
          end
          staticcontent = staticcontent[endindex+"si${".length,staticcontent.length] #Ruby code required
        end
        return processProperty(finalString + staticcontent, fnaIO, mvelHashMap)
      elsif staticcontent && staticcontent.include?("label${") && staticcontent.include?("}$label")
        while staticcontent.include?("label${")
          startindex = staticcontent.index("label${")
          finalString << staticcontent[0, startindex].force_encoding(Encoding::UTF_8)
          staticcontent << staticcontent[startindex+"label${".length, staticcontent.length]
          endindex = staticcontent.index("}$label")
          element = staticcontent[0,endindex]
          element=element.strip
          finalString = MobiSys::UIGenUtilHelper.getLabelValue(element, Application.getValue('DEFAULTLOCALE').value).force_encoding(Encoding::UTF_8)
          staticcontent = staticcontent[endindex+"label${".length, staticcontent.length]
        end
        return processProperty(finalString + staticcontent, fnaIO, mvelHashMap)
      elsif staticcontent && staticcontent.include?("mvel${") && staticcontent.include?("}$mvel")
        i = 1
        while staticcontent.include?("mvel${")
          startindex = staticcontent.index("mvel${")
          finalString << staticcontent[0,startindex].force_encoding(Encoding::UTF_8)
          staticcontent = staticcontent[startindex + "mvel${".length,staticcontent.length]
          endindex=staticcontent.index("}$mvel")
          element = staticcontent[0,endindex]

          # finalString << evaluateExpression(element, mvelHashMap, policyIO).force_encoding(Encoding::UTF_8)

          begin
            finalString << evaluateExpression(element, mvelHashMap, fnaIO).force_encoding(Encoding::UTF_8)
          rescue Exception => e
            finalString << e.to_s
          end

          #puts "finalString: #{finalString}"
          staticcontent = staticcontent[endindex + "mvel${".length, staticcontent.length]
          i+=1
        end
        return processProperty((finalString + staticcontent).gsub("$SEMI$", ";"), fnaIO, mvelHashMap)
      else
        finalString = staticcontent
      end
      return finalString
    end

    def self.extract(source,marker)
      #puts ">>>source: #{source}"
      #puts ">>>marker: #{marker}"
      ext = source[source.index("#{marker}${") + "#{marker}${".length,source.index("}$#{marker}")]
      ext = ext[0,ext.index("}$#{marker}")]
      #puts "returning ext: #{ext}"
      return ext
    end
    #sanket preview for eapp
    def self.findTemplatePageMapping(fnaIO)
     p "****hide_sign_flag******************************#{$hide_sign_flag}"

     
      finalTemplatePageMappingDOList = []
      queryString = "Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where 
              outputDO.templateMasterSeq = tpmDO.templateMasterSeq 
            and outputDO.fund='FNA' order by tpmDO.displayOrder"
      
      templatePageMappingDOList = TemplatePageMapping.find_by_sql(queryString)
      p "templatePageMappingDOList*************#{templatePageMappingDOList}"
      templatePageMappingDOList.each do |templatePageMappingDOListev|
        finalTemplatePageMappingDOList << templatePageMappingDOListev
      end

     
      puts ">>>finalListSize: #{finalTemplatePageMappingDOList.size}"
      $fnaIO.templatePageMappingDO = finalTemplatePageMappingDOList
    end


    
    

    
    #############################################################################################

    def self.getLabel(labelKey)
      toreturn_str = ""

      begin
        toreturn_str << Localization::LabelCache.instance.getLabel(labelKey.to_sym).to_s.force_encoding("UTF-8")
      rescue StandardError => se
        puts se
      end

      return toreturn_str
    end

    #############################################################################################
    

    def self.generateOutputHTML(fnarequest, outputpreference=nil)
      fileName = "Fna_#{fnarequest.fnaNum}.json"
      if outputpreference
      fileName = "Fna_#{fnarequest.fnaNum}_#{outputpreference.languageCd}.json"
      end
      filePath = Rho::RhoFile.join(Rho::Application.userFolder, fileName)
      unless File::exist?(filePath)
        $showPdf = true
        $fnaIO = MobiSys::IO::FnaIO.new
        $fnaIO.baseDO = fnarequest
        if outputpreference
          $fnaIO.outputPreferencesDO = outputpreference
        end
        $showPdf=true
        findTemplatePageMapping($fnaIO)
        getHtmlStringandGeneratePDF(true, $fnaIO)
        $showPdf = nil

        filehtml = ""
        filehtml << "<!DOCTYPE html>"
        filehtml << "<html lang=\"en\">"
        filehtml << "<head>"
        filehtml << "<meta charset=\"utf-8\">"
        filehtml << "</head>"
        filehtml << "<body>"

        totalPages = $fnaIO.htmlContent.size
        skipPageNumber=0;
        totalSkipNumber = 0;
        $fnaIO.htmlContent.each_pair do |pageNumber, page|
          if(page["content"].include? "$SKIPPAGENUMBER$")
            totalSkipNumber = totalSkipNumber - 1;  
          end
      end
      $fnaIO.htmlContent.each_pair do |pageNumber, page|
        content = page["content"]
        if(content.include? "$ZEROMARGIN$")
          content.gsub!("$ZEROMARGIN$", "")
          content << "<div style=\"margin:0px !important;padding:0px !important;\">"
        else
          content << "<div class=\"bodyDiv\">"
        end
        if(content.include? "$SKIPPAGENUMBER$")
          skipPageNumber = skipPageNumber - 1
          content.gsub!("$SKIPPAGENUMBER$", "")
          if(pageNumber != totalPages)
            content << "<pd4ml:page.break></div></div>"
          else
            content << "</div>"
          end
        else
          content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
          content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
          if(pageNumber != totalPages)
            content << "<pd4ml:page.break></div></div>"
          else
            content << "</div>"
          end
        end
        filehtml << content
      end
      filehtml << "</body>"
      filehtml << "</html>"

      filehtml.gsub!('/public/jquery/','')
      filehtml.gsub!('/public/js/RGraph/','')
      filehtml.gsub!('/public/js/FNA/','')
      filehtml.gsub!('/public/images/SalesIllustration/','')
      filehtml.gsub!('/public/images/FNA/outputimages/','')
      filehtml.gsub!('/public/css/FNA/','')
      filehtml.gsub!('/public/js/','')
      filehtml.gsub!('/public/images/outputimages/','')
      filehtml.gsub!('/public/css/','')
    
      syncEntities = {}
      syncEntities["html"] = filehtml
      syncEntities["graphJSON"] = ""
      syncEntities["languageCd"] = "EN"
      if outputpreference
        syncEntities["languageCd"] = outputpreference.languageCd
      end
      syncEntities[FNARequest.onlineClassName] = [$fnaIO.baseDO.hashForSync].to_json

      jsonFile = File.new(filePath,'w')
      encryptedContent = MobiSys::Encryption.encryptAndEncodeContent(syncEntities.to_json)
      jsonFile.write(encryptedContent)
      jsonFile.close
    end

    return filePath
  end

  end
end


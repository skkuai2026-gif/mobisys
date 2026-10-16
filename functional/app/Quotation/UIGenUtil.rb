#encoding: UTF-8
require 'Application/application'
require 'Quotation/UIGenUtilCompanyHelper'
require 'time'
module MobiSys
	class UIGenUtil

		def self.getHtmlStringandGeneratePDF(isHtml, quotationIO, apoQuotationIO=nil)
  			mvelHashMap = {}
			htmlBufferFinal = "".force_encoding(Encoding::UTF_8)
			htmlBufferPage = ""
			ulhtmlBuffer = ""
			illustrationModelDO = quotationIO.illustrationModel
			htmlContent = Array.new
			quotationIO.htmlContent = htmlContent

			listPageSectionDO = []
     
			if apoQuotationIO
				finalMapNew(apoQuotationIO)
			end

			if apoQuotationIO
				mvelHashMap = populateMvelHashMap(quotationIO, mvelHashMap, apoQuotationIO) #Need to write method for populateMvelHashMap
			else
				mvelHashMap = populateMvelHashMap(quotationIO, mvelHashMap) #Need to write method for populateMvelHashMap
			end

			unless illustrationModelDO == nil
				elemMap = CommonUtil.convertToHash(illustrationModelDO.IllustrationFacetList, 'computedElementName')
			end

			if quotationIO.templatePageMappingDO != nil and quotationIO.templatePageMappingDO.size > 0
				htmlBufferFinal << getCssStyle if isHtml #Need to write method for getCssStyle

				
				quotationIO.templatePageMappingDO.each do |groupCd,templatePageMappingDOPart|
					pagenumber = 0
					tempHtmlHash = Hash.new
					templatePageMappingDOPart.each do |templatePageMappingDOo|
						#next unless Application.getValue("PageHeaders").value.to_i == templatePageMappingDOo.pageHeaderSeq.to_i
	         # next unless Application.getValue("PageHeaders").value.split(',').include?(templatePageMappingDOo.pageHeaderSeq.to_s)
						
						if templatePageMappingDOo.mvelConditionRuby.to_s == "" or checkMvelCondition(templatePageMappingDOo,quotationIO,mvelHashMap)

							isFundList = false
							fundList = nil
							recurringFund = 1
							isFundList = ("fundList" == templatePageMappingDOo.fund)
						
							if(mvelHashMap["fundList"] != nil)
								fundList = mvelHashMap["fundList"]
							end
							if(isFundList)
								recurringFund = fundList.size
							end
							begin
								if fundList.size != 0
									mvelHashMap["currentFundDO"] = fundList[fundList.size-recurringFund] 
									mvelHashMap["currentFundCd"] = fundList[fundList.size-recurringFund].fundCd
								end
								returnHashMap = {}
								returnHashMap["repeatPage"] = true
								
								mvelHashMap["pagenumber"] = pagenumber + 1
								while returnHashMap["repeatPage"] == true do
									if templatePageMappingDOo.isAPOFl and templatePageMappingDOo.isAPOFl == "YES"
										returnHashMap = createPage(isHtml, apoQuotationIO, templatePageMappingDOo, mvelHashMap, returnHashMap, pagenumber)
									else
										returnHashMap = createPage(isHtml, quotationIO, templatePageMappingDOo, mvelHashMap, returnHashMap, pagenumber)
									end	
									tempHtmlHash[returnHashMap['pagenumber']] = {"name" => templatePageMappingDOo.pageName, "content" => returnHashMap['page'], "signature"=>returnHashMap['signature']}
									htmlBufferPage << returnHashMap["page"].force_encoding(Encoding::UTF_8)
									pagenumber = returnHashMap["pagenumber"]
									
								end
								recurringFund = recurringFund -1
							end while (recurringFund >= 1)
						end
					end
					
					totalPages = tempHtmlHash.keys.size
					totalSkipNumber = 0
					i = 1
					while i<=pagenumber
						if tempHtmlHash[i]["content"].include? "$SKIPPAGENUMBER$"
							totalSkipNumber = totalSkipNumber - 1
						end
						i = i + 1
					end
					skipPageNumber = 0
					htmlBuffer = ""
						i = 1
						while i<=pagenumber
							if tempHtmlHash[i]["content"].include? "$SKIPPAGENUMBER$"
								skipPageNumber = skipPageNumber - 1
								tempHtmlHash[i]["content"].gsub!('$SKIPPAGENUMBER$',"") unless $showPdf
							else
								tempHtmlHash[i]["content"].gsub!('$PAGENUMBER$',(i+skipPageNumber).to_s)
					    	tempHtmlHash[i]["content"].gsub!('$TOTALPAGENUMBER$',(pagenumber + totalSkipNumber).to_s) 
							end
							i = i + 1
						end
					pagenumber = pagenumber - 1
					htmlContent.push(tempHtmlHash)
				end
			end
			htmlBufferFinal << ulhtmlBuffer 
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

	 def self.populateMvelHashMap(quotationIO, mvelHashMap, apoQuotationIO=nil)
	  	mvelHashMap["quotationIO"] = quotationIO
	  	if quotationIO.baseDO.proposerLASame.to_s == ""
	  		quotationIO.baseDO.proposerLASame = "OTHER"
	  	end
	  	mvelHashMap['offlinePDF'] = $offlinePDF if $offlinePDF && $offlinePDF.to_s != ""
	  	#p "mvelHashMap['offlinePDF']==>#{mvelHashMap['offlinePDF']}"
	  	
	  	mvelHashMap["signaturecontainer"] = SignatureContainer.loadObject(:first,
                                            :conditions => {
                                            :entityGuid => quotationIO.baseDO.guid
                                            }
                                        )
	  	mvelHashMap["quotationDO"] = quotationIO.baseDO
	  	productHash = Hash.new
	  	mvelHashMap['productHash'] = productHash
			productDO = Product.loadObject(:first, :conditions => {:Id => quotationIO.baseDO.getBaseProduct.productSeq})
      productHash[productDO.id] = productDO
			#if productNameDO != nil
			mvelHashMap["productDO"] = productDO if productDO
			#end

			fundDOFinderList = Fund.loadObject(:all, :order => 'sortOrder', :orderdir => 'ASC')
			fundDOHashMap = CommonUtil.convertToHash(fundDOFinderList, "fundCd")

			if apoQuotationIO
				mvelHashMap["apoquotationIO"] = apoQuotationIO
						
				premiumFacetDO =  apoQuotationIO.baseDO.getBasePlan().product.getFacet("PREMIUMDETAILS")
				
				if premiumFacetDO and premiumFacetDO.OfflinePremiumDetailsList[0]
					mvelHashMap["apoPremiumDetailsDO"] = premiumFacetDO.OfflinePremiumDetailsList[0]
				else
					mvelHashMap["apoPremiumDetailsDO"] = nil
				end

				apoQuotationIO.baseDO.getBasePlan.QuotationProductInvestmentFundList.each do |qpif|
					if qpif.allocationPerc.to_i > 0
						mvelHashMap["apochosenFundCd"] = qpif.fundCd
					end	
				end	

	

				#//14th Nov 2013 start
				#mvelHashMap["apoFundList"] = apoQuotationIO.baseDO.getBasePlan.QuotationProductInvestmentFundList
				apoFundList = []
				apoFundListHashMap = CommonUtil.convertToHash(apoQuotationIO.baseDO.getBasePlan.QuotationProductInvestmentFundList, "fundCd") #Need to code for ruby			
				fundDOFinderList.each do |fundDO2|
					if apoFundListHashMap.has_key?(fundDO2.fundCd)
						if apoFundListHashMap[fundDO2.fundCd].allocationPerc.to_i > 0
							apoFundList << apoFundListHashMap[fundDO2.fundCd]
						end
					end
				end
				mvelHashMap["apoFundList"] = apoFundList
				#//14th Nov 2013 end



				apoRiderLIst = apoQuotationIO.baseDO.getRiders
				apoRiderLIst.each do |rider|
					mvelHashMap[rider.productId] = rider
				end	
				mvelHashMap["apoRiderList"] = apoRiderLIst
			else
				mvelHashMap["apoquotationIO"] = nil
			end	
			
			quotationIO.baseDO.getRiders.each do |rider|
				mvelHashMap[rider.productId] = rider
			end
			quotationIO.baseDO.getBuiltInRiders.each do |rider|
				mvelHashMap[rider.productId] = rider
			end

			finderList = Product.find(:all, :conditions => {:productTypeCd => 'RIDER'}, :order => 'sortOrder', :orderdir => 'ASC') #Need to add sort condition

			finderList.each do |productDO2|	
				if !mvelHashMap.has_key?(productDO2.productId)
					
					mvelHashMap[productDO2.productId] = nil
				else
					
					productHash[productDO2.id] = Product.loadObject(:first,:conditions=>{:productId=>productDO2.productId})
				end
			end

			riderListHashMap = CommonUtil.convertToHash(quotationIO.baseDO.getRiders, "productSeq")
			#p "riderListHashMap===>#{riderListHashMap}"
			builinriderListHashMap = CommonUtil.convertToHash(quotationIO.baseDO.getBuiltInRiders, "productSeq")
			#p "builinriderListHashMap===>#{builinriderListHashMap}"
			

			@riderList = []
			finderList.each do |productDO2|
				if riderListHashMap.has_key?(productDO2.id)
					@riderList << riderListHashMap[productDO2.id]
				end
			end
			#p "@riderList===>#{@riderList}"
			finderList.each do |productDO2|
				if builinriderListHashMap.has_key?(productDO2.id)
					@riderList << builinriderListHashMap[productDO2.id]
				end
			end
			#p "@riderList===>#{@riderList}"
			

			#generating the hashmap for the ridersQuotationProduts that are not attatched with quotation 
			#quotationProductDORiderHashMap = CommonUtil.getInstance().getHashedList("productId", finderList) #Ruby code required
 
			quotationProductDORiderHashMap = CommonUtil.convertToHash(finderList, "productId")

			quotationIO.baseDO.getBaseProduct.QuotationProductInvestmentFundList.each do |fund|
				if fund.allocationPerc != nil && fund.allocationPerc.to_i > 0
					mvelHashMap[fund.fundCd] = fund
				end
			end

			

			fundDOFinderList.each do |fundDO2|
				if !mvelHashMap.has_key?(fundDO2.fundCd)
					mvelHashMap[fundDO2.fundCd] = nil
				end
			end

			fundList = []
			fundListHashMap = CommonUtil.convertToHash(quotationIO.baseDO.getBaseProduct.QuotationProductInvestmentFundList, "fundCd") #Need to code for ruby
			
			fundDOFinderList.each do |fundDO2|
				if fundListHashMap.has_key?(fundDO2.fundCd)
					if fundListHashMap[fundDO2.fundCd].allocationPerc.to_i > 0
						fundList << fundListHashMap[fundDO2.fundCd]
					end
				end
			end

			
			@riderList = @riderList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}

			mvelHashMap["fundList"] = fundList
			mvelHashMap["riderList"] = @riderList
			
			mvelHashMap["fundDOHashMap"] = fundDOHashMap
			mvelHashMap["quotationProductDORiderHashMap"] = quotationProductDORiderHashMap
			mvelHashMap["proposalSignature"]=ServiceSignature.loadObject(:first, :conditions => {:entityGuid => quotationIO.baseDO.guid})
			#adding helper class in hashmap
			UIGenUtilCompanyHelper.getUpdateHashMap(mvelHashMap)
			mvelHashMap["mvelHashMap"] = mvelHashMap
			#Swati Ahire 18-06-2014: Added riderListHashMap in mvelHashMap
			mvelHashMap["riderListHashMap"] = riderListHashMap
			dt = Time.parse(quotationIO.baseDO.quotationDt.to_s)
			mvelHashMap["calendarYear"] = dt.year

			agentDO = AgentReg.getCurrentAgentReg
			mvelHashMap["agentDO"] = agentDO if agentDO
			return mvelHashMap
	  end

	  

	  def self.checkMvelCondition(sectionDetailsDO, quotationIO, mvelHashMap)
			quotationDO = mvelHashMap["quotationDO"]
			#Swati Ahire 20-06-2014: Added blank check before evaluating mvelConditionRuby
			productDO = mvelHashMap["productDO"]
			if sectionDetailsDO.mvelConditionRuby.to_s != ""
				eval sectionDetailsDO.mvelConditionRuby
			end
		end


	  def self.createPage(ishtml, quotationIO, templatePageMappingDO, mvelHashMap, returnHashMap, pagenumber)
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
				
					pageSectionDO.SectionDetailsList.sort{|x,y| x.displayOrder.to_i<=>y.displayOrder.to_i}.each do |sectionDetailsDO|
						#next unless Application.getValue('SectionDetails').value.include? sectionDetailsDO.id.to_s
						
						if sectionDetailsDO.mvelConditionRuby.to_s == "" or checkMvelCondition(sectionDetailsDO,quotationIO,mvelHashMap)
							if sectionDetailsDO and sectionDetailsDO.elementType and sectionDetailsDO.onlyType and (sectionDetailsDO.onlyType == "HTML" or sectionDetailsDO.onlyType=="PDF")
								if sectionDetailsDO.onlyType == "HTML" and $showPdf != true
									repeatHashMap = processPage(sectionDetailsDO,quotationIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
								elsif sectionDetailsDO.onlyType == "PDF" and $showPdf == true
									repeatHashMap = processPage(sectionDetailsDO,quotationIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
								end
							else
								repeatHashMap = processPage(sectionDetailsDO,quotationIO,htmlBuffer,mvelHashMap,repeatHashMap,ishtml,true)
							end		
						end
					end
				end
			end
			if ishtml
				htmlBuffer << "</div><!--div class tabcontent end-->".force_encoding(Encoding::UTF_8)
			else
				#If condition used for PDF generation on client side
				QuotationRequestUtil.getInstance().generateQuotationPDFFileUsingBuffer(quotationIO, nil, htmlBuffer, quotationIO.getBaseDO().getId() +"-"+ pagenumber)
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
			if repeatHashMap["signature"] 
				returnHashMap["signature"] = repeatHashMap["signature"]
			end
			return returnHashMap
	  end

	  def self.processPage(sectionDetailsDO, quotationIO, htmlBuffer, mvelHashMap, returnHashMapPage, ishtml, divHide)
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

	 			if quotationIO.outputPreferencesDO && quotationIO.outputPreferencesDO.languageCd != nil && quotationIO.outputPreferencesDO.languageCd.upcase != 'EN'
	 				sectionDetailsDO.label1Ruby = sectionDetailsDO.label2Ruby
	 			end	
				
				if sectionDetailsDO != nil and sectionDetailsDO.includeTd and sectionDetailsDO.includeTd.upcase! == "YES"
					htmlBuffer << "<TD #{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
					divHide = false
				end

				label1Ruby = nil
				if sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "HTML" 
					value = ""
					if sectionDetailsDO.label1Ruby != nil && sectionDetailsDO.label1Ruby.include?("$PATH$") #need to write equivalent code for ruby
						pPATH = ""
						if ishtml
							if $quotationIO.isFullHTMLRequired.to_s != ""
								pPATH = "/assets/theme/images/company/"
							else
								pPATH = "/public/images/outputimages/"
							end
							label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
						else
							label1Ruby = sectionDetailsDO.label1Ruby.gsub("$PATH$", pPATH) #Need to write ruby equivalent code
						end
					else
						label1Ruby = sectionDetailsDO.label1Ruby
					end
					htmlBuffer << processProperty(label1Ruby, quotationIO, mvelHashMap).to_s.force_encoding(Encoding::UTF_8)
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
					str = processProperty(sectionDetailsDO.label1Ruby,quotationIO,mvelHashMap).to_s.force_encoding(Encoding::UTF_8)
					htmlBuffer << str.force_encoding(Encoding::UTF_8)
					if divHide
						htmlBuffer << "</div>".force_encoding(Encoding::UTF_8)
					end

				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "STYLE"
					htmlBuffer << "<style type=\"text/css\">".force_encoding(Encoding::UTF_8)
					htmlBuffer << sectionDetailsDO.label1Ruby.to_s.force_encoding(Encoding::UTF_8)
					htmlBuffer << "</style>".force_encoding(Encoding::UTF_8)

				elsif sectionDetailsDO != nil && sectionDetailsDO.elementType != nil && sectionDetailsDO.elementType == "TABLE" && quotationIO.baseDO.getBaseProduct.productTerm !=nil
					sectionDetailsDO.label1Ruby = sectionDetailsDO.label1Ruby.to_s.gsub("\r","").gsub("\n","")
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
					if returnHashMapPage.has_key?("rowCount")
			    		returnHashMapPage["rowCount"] = 1
					end
					if element.include?("~")
						elm = element[0,element.index("~")] << element[element.index(","),element.length]
						rate1 = rate[0,rate.index("~")] << rate[rate.index(","),rate.length]

						tdStyle1 = tdStyle[0, tdStyle.index("~")] << tdStyle[tdStyle.index(","),tdStyle.length]
						
						if !returnHashMapPage["skipPolicyseq"]
							returnHashMapPage["skipPolicyseq"] = false
							processTable(returnHashMapPage, max, quotationIO, elm, rate1, htmlBuffer, sectionDetailsDO, mvelPolicyYear, mvelAge, mvelHashMap, tdStyle1, policyYearCondition, ageCondition, true,tableSpace) #539
						end

						if returnHashMapPage.has_key?("skipAge") && !returnHashMapPage["skipAge"]
				 			elm = element[element.index("~")+1, element.length]
				 			rate1=rate[rate.index("~")+1, rate.length]
					 		tdStyle1=tdStyle[tdStyle.index("~")+1, tdStyle.length]
							returnHashMapPage["skipPolicyseq"] = true
							processTable(returnHashMapPage,max,quotationIO,elm,rate1,htmlBuffer,sectionDetailsDO,mvelPolicyYear,mvelAge,mvelHashMap,tdStyle1,policyYearCondition,ageCondition,false,tableSpace)
				 		end
				 	else
				 		processTable(returnHashMapPage,max,quotationIO,element,rate,htmlBuffer,sectionDetailsDO,mvelPolicyYear,mvelAge,mvelHashMap,tdStyle,policyYearCondition,ageCondition,true,tableSpace)
					end
				end
			end
			#Swati Ahire 19-06-2014: Replaced sectionDetailsDO.includeTd with sectionDetailsDO.includeTD
			if sectionDetailsDO != nil && sectionDetailsDO.includeTD && sectionDetailsDO.includeTD.upcase! == "YES"
				htmlBuffer << "</TD>".force_encoding(Encoding::UTF_8)
			end
			if sectionDetailsDO != nil && ((sectionDetailsDO.label1Ruby.to_s != "" && sectionDetailsDO.label1Ruby.include?("getSignature")) || (sectionDetailsDO.label2Ruby.to_s != "" && sectionDetailsDO.label2Ruby.include?("getSignature")))
				returnHashMapPage["signature"] = mvelHashMap["CurrentSignature"]
			end
			return returnHashMapPage
		end

		def self.processTable(returnHashMapPage, max, quotationIO, element, rate, htmlBuffer, sectionDetailsDO, mvelPolicyYear, mvelAge, mvelHashMap, tdStyle, policyYearCondition, ageCondition, skipAge, tableSpace) 
			
			startnum=1
			if returnHashMapPage.has_key?("repeatPageFrom")
       	startnum = returnHashMapPage["repeatPageFrom"]
      end

      if max == 0
				max = quotationIO.baseDO.getBaseProduct.productTerm
			end
			elemValue = element.split(",")
			rateValue = rate.split(",")
      rowNum = 1

      if returnHashMapPage.has_key?("rowCount")
  	 		rowNum = returnHashMapPage["rowCount"]
      end

      loopList= getlist("1-#{quotationIO.baseDO.getBaseProduct.productTerm}", sectionDetailsDO.label1Ruby)
      if policyYearCondition != "" && elemValue.length > 0 && elemValue[0] == mvelPolicyYear
  	 		loopList = getlist(policyYearCondition,sectionDetailsDO.label1Ruby)
  	 	end

			if ageCondition and ageCondition != "" and elemValue.length > 0 and elemValue[0] == mvelAge
				loopList = getlist(ageCondition,sectionDetailsDO.label1Ruby)
				j=0
				while j<loopList.size
					loopList[j] = loopList[j] - quotationIO.baseDO.getPartyListByRoleCd("PRIMARY")[0].age
					j += 1
				end
			end
			j = startnum
			while j <= loopList.size
				i = loopList[j - 1]
				if ((quotationIO.finalMap.has_key? i) and i <= (quotationIO.baseDO.getBaseProduct.productTerm.to_i + 10) and ((mvelHashMap.has_key? "maxTableYear") ? (i <= mvelHashMap["maxTableYear"].to_i) : true))
					if rowNum.to_i <= max.to_i

						mvelHashMap["tableRowCount"] =  rowNum.to_i
						htmlBuffer << "<tr> \n".force_encoding(Encoding::UTF_8)
						pos = 0
						mvelHashMap["mvelPolicyYear"] = quotationIO.finalMap[i][mvelPolicyYear][rateValue[0].strip] if mvelPolicyYear != "" && quotationIO.finalMap[i][mvelPolicyYear] != nil

						mvelHashMap["mvelAge"] = quotationIO.finalMap[i][mvelAge][rateValue[0].strip] if mvelAge != ""

						tdStyle2 = tdStyle

						if tdStyle.include?("mvelPerCycle${") and tdStyle.include?("}$mvelPerCycle")
	                        staticcontent = tdStyle
	                       
	                        temp = 1
	                        finalString = ""
	                        while staticcontent.include?("mvelPerCycle${")
                                
                                element2 = extract(staticcontent,"mvelPerCycle")
								#Swati Ahire 30-08-2014: Added strip 
								element2 = element2.strip
                                endindex = staticcontent.index("}$mvelPerCycle")
                                begin
                                    finalString << evaluateExpression(element2, mvelHashMap,quotationIO).to_s
                                rescue StandardError => boom
                                   
                                    finalString << "mvelPerCycle error #{boom}"
                                end        
                                staticcontent=staticcontent[endindex+"mvelPerCycle${".length,staticcontent.length]
                                # staticcontent = staticcontent.slice!(endindex + "mvelPerCycle${".length,staticcontent.length)
                                temp = temp + 1
	                        end
	                        tdStyle2 = (finalString + staticcontent).gsub("$SEMI$",";")
	                       
				        end
						tdStylePerCycle = tdStyle2.split(",")
						elemValue.each do |ev|
						  #Swati Ahire 30-08-2014: Added strip 
						  ev = ev.strip
							if not tdStyle2.include?("mvelPerCycle error")
								if tdStylePerCycle[pos] and tdStylePerCycle[pos].strip != "nil"
									htmlBuffer << "<td #{tdStylePerCycle[pos]}>".force_encoding(Encoding::UTF_8)
								elsif sectionDetailsDO.property1
									htmlBuffer << "<td #{sectionDetailsDO.property1}>".force_encoding(Encoding::UTF_8)
								else
									htmlBuffer << "<td>".force_encoding(Encoding::UTF_8)
								end			
							else
								htmlBuffer << "<td> #{tdStyle2}".force_encoding(Encoding::UTF_8)
							end

							if quotationIO.finalMap[i] == nil || quotationIO.finalMap[i][ev] == nil
								htmlBuffer << "Element #{ev} not found".force_encoding(Encoding::UTF_8)
							else
								val = ""
							if sectionDetailsDO.label1Ruby and sectionDetailsDO.label1Ruby.include?("#{ev}_modifyPerCycle${") and sectionDetailsDO.label1Ruby.include?("}$#{ev}_modifyPerCycle")
								val = extract(sectionDetailsDO.label1Ruby,"#{ev}_modifyPerCycle")
			                  # Changes 26 sep start
							elsif sectionDetailsDO.label1Ruby and sectionDetailsDO.label1Ruby.include?("#{ev}_#{rateValue[pos].strip}_modifyPerCycle${")   and sectionDetailsDO.label1Ruby.include?("}$#{ev}_#{rateValue[pos].strip}_modifyPerCycle")
              					val=extract(sectionDetailsDO.label1Ruby,"#{ev}_#{rateValue[pos].strip}_modifyPerCycle")
							end
								#Swati Ahire 30-08-2014: Added strip 
								value = quotationIO.finalMap[i][ev][rateValue[pos].strip]
								mvelHashMap["currentCycle"] = i
								mvelHashMap["currentElement"] = ev
								mvelHashMap["currentRate"] = rateValue[pos].strip
								#Swati Ahire 14-07-2014: Added blank check for value
								value = MobiSys::UIGenUtilCompanyHelper.roundingTableData(mvelHashMap,value) if value.to_s != ""
								if val != ""
									val.gsub!("mvelPolicyYear",mvelHashMap["mvelPolicyYear"].to_s) if mvelHashMap.has_key? "mvelPolicyYear"
									val.gsub!("mvelAge",mvelHashMap["mvelAge"].to_s) if mvelHashMap.has_key? "mvelAge"
									val.gsub!(ev, value.to_s) if val.include? ev

									if val.include? "mvelPerCycle${" and val.include? "}$mvelPerCycle"
										staticcontent = val
										finalString = ""
										while staticcontent.include? "mvelPerCycle${"
											#finalString << extract(staticcontent,"mvelPerCycle")
											element2 = extract(staticcontent,"mvelPerCycle")
					                      #Swati Ahire 30-08-2014: Added strip 
					                      element2 = element2.strip
					                     
											begin

											
												# temp = evaluateExpression(element2, mvelHashMap, quotationIO)
												
												finalString << evaluateExpression(element2, mvelHashMap, quotationIO)
											rescue Exception => e
												finalString << "#{e}"
											end
											endindex = staticcontent.index("}$mvelPerCycle")
											staticcontent=staticcontent[endindex+"mvelPerCycle${".length,staticcontent.length]
										end
										val = (finalString + staticcontent).gsub("$SEMI$",";")
									end
									value = val	
								end
								#Swati Ahire 14-07-2014: Added blank check for value
								htmlBuffer << value.force_encoding(Encoding::UTF_8) if value.to_s != ""
								#here
							end
							htmlBuffer << "</td> \n".force_encoding(Encoding::UTF_8)
							pos += 1
						end	
						htmlBuffer << "</tr> \n".force_encoding(Encoding::UTF_8)
						if tableSpace != nil && tableSpace.to_s != ""
							if tableSpace.include?("mvelPerCycle${") && tableSpace.include?("}$mvelPerCycle")
								staticcontent=tableSpace;
								finalString="";
								while(staticcontent.include? "mvelPerCycle${")
									startindex = staticcontent.index("mvelPerCycle${")
									finalString << staticcontent[0, startindex]
									staticcontent = staticcontent[startindex+14,staticcontent.length]
									endindex = staticcontent.index("}$mvelPerCycle")
									element2 = staticcontent[0,endindex]
									element2 = element2.strip
									begin
									finalString << evaluateExpression(element2, mvelHashMap,quotationIO).to_s
									rescue StandardError => boom
										finalString << "<tr><td>mvelPerCycle error #{boom}</td></tr>"
									end	
									staticcontent = staticcontent[endindex+"mvelPerCycle${".length,staticcontent.length]
								end
								#//changes 17 apr 2014 start
								htmlBuffer << (finalString + staticcontent).gsub("$SEMI$", "")
								#//changes 17 apr 2014 end
							end
						end
					else
						mvelHashMap["pageContinue"] = true
						returnHashMapPage["repeatPageFrom"] = j
						returnHashMapPage["skipAge"] = skipAge
						break
					end #if rowNum <= max
					if j == loopList.size
						returnHashMapPage.delete "repeatPageFrom"
						returnHashMapPage["rowCount"] = rowNum + 1
						returnHashMapPage["skipAge"] = false
						mvelHashMap.delete "pageContinue"
					end	#if j == loopList.size
					rowNum += 1
			  #Swati Ahire 30-08-2014: Added else condition by comparing with online code
				else
				    returnHashMapPage.delete "repeatPageFrom"
		            returnHashMapPage["rowCount"] = rowNum
		            returnHashMapPage["skipAge"] = false
		            mvelHashMap.delete "pageContinue"
				end	#if quotationIO.finalMap.has_key? i
				j += 1
			end #while j < loopList.size
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

		def self.evaluateExpression(expression, mvelHashMap, quotationIO)
			results = MobiSys::DataObjects::Results.new
			results.createAttr('quotationIO')
			results.setAttr('quotationIO', quotationIO)
			results.createAttr('productDO')
			results.setAttr('productDO', mvelHashMap['productDO'])
			results.createAttr('productHash')
			results.setAttr('productHash', mvelHashMap['productHash'])
			results.createAttr('quotationProductDORiderHashMap')
			results.setAttr('quotationProductDORiderHashMap',mvelHashMap['quotationProductDORiderHashMap'])
			results.createAttr('mvelHashMap')
			results.setAttr('mvelHashMap', mvelHashMap)
			results.createAttr('apoquotationIO')
			results.setAttr('apoquotationIO', mvelHashMap['apoquotationIO'])
			results.defineMethod("testing",expression)
			return results.testing.to_s
		end	

		def self.processProperty(value, quotationIO, mvelHashMap)
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

					if quotationIO.getIllustrationHeaderFieldValue(element) == nil
						finalString << "Element "+element+" Not found".force_encoding(Encoding::UTF_8) #Need to check if code works in ruby or not
					else
						finalString << quotationIO.getIllustrationHeaderFieldValue(element).force_encoding(Encoding::UTF_8)
					end
					staticcontent = staticcontent[endindex+"si${".length,staticcontent.length] #Ruby code required
				end
				return processProperty(finalString + staticcontent, quotationIO, mvelHashMap)
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
				return processProperty(finalString + staticcontent, quotationIO, mvelHashMap)
			elsif staticcontent && staticcontent.include?("mvel${") && staticcontent.include?("}$mvel")
				i = 1
				while staticcontent.include?("mvel${")
					startindex = staticcontent.index("mvel${")
					finalString << staticcontent[0,startindex].force_encoding(Encoding::UTF_8)
					staticcontent = staticcontent[startindex + "mvel${".length,staticcontent.length]
					endindex=staticcontent.index("}$mvel")
					element = staticcontent[0,endindex]

					# finalString << evaluateExpression(element, mvelHashMap, quotationIO).force_encoding(Encoding::UTF_8)	
					
					begin
						finalString << evaluateExpression(element, mvelHashMap, quotationIO).force_encoding(Encoding::UTF_8)	
					rescue Exception => e
						finalString << e.to_s
					end
					
				
					staticcontent = staticcontent[endindex + "mvel${".length, staticcontent.length]
					i+=1
				end
				return processProperty((finalString + staticcontent).gsub("$SEMI$", ";"), quotationIO, mvelHashMap)
			else
				finalString = staticcontent	
			end
			return finalString
		end

		def self.extract(source,marker)
			
			ext = source[source.index("#{marker}${") + "#{marker}${".length,source.index("}$#{marker}")]
			ext = ext[0,ext.index("}$#{marker}")]
			
			return ext
		end

		def self.finalMapNew(quotationIO)
			listCalculation = quotationIO.listCalculation
			illustrationModel = quotationIO.illustrationModel
			if illustrationModel
				elemMap = CommonUtil.convertToHash(illustrationModel.IllustrationFacetList, 'computedElementName')
				finalMap = Hash.new
				isMonthly = (illustrationModel.computationFrequencyCd == 'MONTHLY') ? true : false
				row = 1
				listCalculation.each do |calcRes|
					if isMonthly
						if calcRes.id.to_s != "" && calcRes.id % 12 != 0
							next
						end	#if calcRes.id % 12 != 0
					end	#if isMonthly

					calcRes.fieldValueList.each do |calcCol|
						next unless calcCol
						calcCol.fieldValue = calcCol.fieldValue.to_f if calcCol.fieldValue.class.to_s == "BigDecimal"
						facetDO = elemMap[calcCol.fieldCd]
						next unless facetDO
						if facetDO.outputDisplayTypeCd
							hm = Hash.new
							innerhm = Hash.new

							if finalMap.has_key? row
								innerhm = finalMap[row]
								if innerhm.has_key? calcCol.fieldCd
									hm = innerhm[calcCol.fieldCd]
									innerKey = "0"
									hm[innerKey] = calcCol.fieldValue
								else
									innerKey = "0"
									hm[innerKey] = calcCol.fieldValue
									innerhm[calcCol.fieldCd] = hm
									finalMap[row] = innerhm
								end #if innerhm.has_key? calcCol.fieldCd
							end #if finalMap.has_key? row

							innerKey = "0"
							hm[innerKey] = calcCol.fieldValue
							innerhm[calcCol.fieldCd] = hm
							finalMap[row] = innerhm
						end #if facetDO.outputDisplayTypeCd	
					end #calcRes.fieldValueList.each do |calcCol|

					#per rate per cycle records
					calcRes.fieldResultList.each do |innerCalc|
						innerCalc.fieldValueList.each do |calcCol|
							calcCol.fieldValue = calcCol.fieldValue.to_f if calcCol.fieldValue.class.to_s == "BigDecimal"
							facetDO = elemMap[calcCol.fieldCd]
							if facetDO and facetDO.outputDisplayTypeCd
								hm = Hash.new
								innerhm = Hash.new

								if finalMap.has_key? row
									innerhm = finalMap[row]
									if innerhm.has_key? calcCol.fieldCd
										hm = innerhm[calcCol.fieldCd]
										innerKey = innerCalc.objectName
										innerKey ||= "0"
										hm[innerKey] = calcCol.fieldValue
									else
										innerKey = innerCalc.objectName
										innerKey ||= "0"
										hm[innerKey] = calcCol.fieldValue
										innerhm[calcCol.fieldCd] = hm
										finalMap[row] = innerhm
									end	#if innerhm.has_key? calcCol.fieldCd
								end	#if finalMap.has_key? row

								innerKey = innerCalc.objectName
								innerKey ||= "0"
								hm[innerKey] = calcCol.fieldValue
								innerhm[calcCol.fieldCd] = hm
								finalMap[row] = innerhm
							end	#if facetDO and facetDO.outputDisplayTypeCd
						end	#innerCalc.fieldValueList.each do |calcCol|
					end	#calcRes.fieldResultList.each do |innerCalc|
					row += 1
				end #listCalculation.each do |calcRes|	

				hmFundComputedAttributes = quotationIO.hmFundComputedAttributes
				iterFundList = hmFundComputedAttributes.keys
				iterFundList.each do |qpif|
					row = 1
					listFundCalculation = hmFundComputedAttributes[qpif]
					listFundCalculation.each do |calcRes|
						if isMonthly
							if calcRes.id.to_s != "" && calcRes.id % 12 != 0
								next
							end	#if calcRes.id % 12 != 0
						end #if isMonthly

						calcRes.fieldValueList.each do |calcCol|
							calcCol.fieldValue = calcCol.fieldValue.to_f if calcCol.fieldValue.class.to_s == "BigDecimal"
							facetDO = elemMap[calcCol.fieldCd]
							if facetDO and facetDO.computationOrder
								hm = Hash.new
								innerhm = Hash.new
								if finalMap.has_key? row
									innerhm = finalMap[row]
									if innerhm.has_key? calcCol.fieldCd
										hm = innerhm[calcCol.fieldCd]
										innerKey = "0#{qpif.fundCd}"
										hm[innerKey] = calcCol.fieldValue
									else
										innerKey = "0#{qpif.fundCd}"
										hm[innerKey] = calcCol.fieldValue
										innerhm[calcCol.fieldCd] = hm
										finalMap[row] = innerhm
									end #if innerhm.has_key? calcCol.fieldCd
								end #if finalMap.has_key? row

								innerKey = "0#{qpif.fundCd}"
								hm[innerKey] = calcCol.fieldValue
								innerhm[calcCol.fieldCd] = hm
								finalMap[row] = innerhm
							end	#if facetDO and facetDO.computationOrder
						end #calcRes.fieldValueList.each do |calcCol|

						#per rate per cycle records
						calcRes.fieldResultList.each do |innerCalc|
							innerCalc.fieldValueList.each do |calcCol|
								calcCol.fieldValue = calcCol.fieldValue.to_f if calcCol.fieldValue.class.to_s == "BigDecimal"
								hm = Hash.new
								innerhm = Hash.new

								if finalMap.has_key? row
									innerhm = finalMap[row]
									if innerhm.has_key? calcCol.fieldCd
										hm = innerhm[calcCol.fieldCd]
										innerKey = innerCalc.objectName
										innerKey ||= "0"
										hm["#{innerKey}#{qpif.fundCd}"] = calcCol.fieldValue
									else	
										innerKey = innerCalc.objectName
										innerKey ||= "0"
										hm["#{innerKey}#{qpif.fundCd}"] = calcCol.fieldValue
										innerhm[calcCol.fieldCd] = hm
										finalMap[row] = innerhm
									end	#if innerhm.has_key? calcCol.fieldCd
								end	#if finalMap.has_key? row
								innerKey = innerCalc.objectName
								innerKey ||= "0"
								hm["#{innerKey}#{qpif.fundCd}"] = calcCol.fieldValue
								innerhm[calcCol.fieldCd] = hm
								finalMap[row] = innerhm
							end	#innerCalc.fieldValueList.each do |calcCol|
						end	#calcRes.fieldResultList.each do |innerCalc|
						row += 1
					end	#listFundCalculation.each do |calcRes|
				end	#iterFundList.each do |qpif|

				hmRiderComputedAttributes = quotationIO.hmRiderComputedAttributes
				iterRiderList = hmRiderComputedAttributes.keys
				iterRiderList.each do |quotationProduct|
					row = 1
					monthCount = 0
					listRiderCalculation = hmRiderComputedAttributes[quotationProduct]
					listRiderCalculation.each do |calcRes|
						if isMonthly
							monthCount += 1
							if monthCount % 12 != 0
								next
							end #if monthCount % 12 != 0
						end #if isMonthly

						calcRes.fieldValueList.each do |calcCol|
							calcCol.fieldValue = calcCol.fieldValue.to_f if calcCol.fieldValue.class.to_s == "BigDecimal"
							facetDO = elemMap[calcCol.fieldCd]
							if facetDO and facetDO.computationOrder
								hm = Hash.new
								innerhm = Hash.new

								if finalMap.has_key? row
									innerhm = finalMap[row]
									if innerhm.has_key? calcCol.fieldCd
										hm = innerhm[calcCol.fieldCd]
										innerKey = "0#{quotationProduct.productId}"
										hm[innerKey] = calcCol.fieldValue
									else
										innerKey = "0#{quotationProduct.productId}"
										hm[innerKey] = calcCol.fieldValue
										innerhm[calcCol.fieldCd] = hm
										finalMap[row] = innerhm
									end	#if innerhm.has_key? calcCol.fieldCd
								end #if finalMap.has_key? row

								innerKey = "0#{quotationProduct.productId}"
								hm[innerKey] = calcCol.fieldValue
								innerhm[calcCol.fieldCd] = hm
								finalMap[row] = innerhm
							end #if facetDO and facetDO.computationOrder
						end #calcRes.fieldValueList.each do |calcCol|
						row += 1
					end	#listRiderCalculation.each do |calcRes|
				end	#iterRiderList.each do |quotationProduct|
				quotationIO.finalMap = finalMap
			end #if illustrationModel
		end	#def self.finalMapNew(quotationIO)


		def self.generateGraphJSON(quotationIO, jsonStr, imageName, methodName)
			quotationIO.graphJSON ||= []
			quotationIO.graphJSON << {:fileName=>imageName,:methodName=>methodName,:jsonData=>jsonStr}
		end

		def self.getSignature(mvelHashMap, signatureTypeCd)
			quotation = mvelHashMap["quotationDO"]
			serviceSignature = nil
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid}) 
		    serviceSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == signatureTypeCd}.first if signatureContainer
		    if serviceSignature.to_s != ""
		    	if serviceSignature.signature.to_s != "" && serviceSignature.signature.to_s.start_with?('ZLIBCMP')
		    		serviceSignature.signature = serviceSignature.signature.gsub!('ZLIBCMP','')
		    		original_signature_decoded = MobiSys::Encryption.decodeContents(serviceSignature.signature)
		    		uncompressed_signature = MobiSys::Encryption.unZipData(original_signature_decoded)
		    		serviceSignature.signature = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(uncompressed_signature)
		    	end
		    	sigantureImage = "<img src='#{serviceSignature.signature}' id='signature#{signatureTypeCd}_img' width='245' height='50'>"
		    else
		    	sigantureImage = "<img id='signature#{signatureTypeCd}_img' width='245' height='50' style='display:none'>"
		    end
		    return sigantureImage
		end


		def self.getSignatureDt(mvelHashMap, signatureTypeCd)
			quotation = mvelHashMap["quotationDO"]
			serviceSignature = nil
			signatureDtHtml = ""
			signatureContainer = SignatureContainer.loadObject(:first, :conditions => {:entityGuid => quotation.guid}) 
		    serviceSignature = signatureContainer.ServiceSignatureList.select{|serviceSign| serviceSign.signatureTypeCd == signatureTypeCd}.first if signatureContainer
		    if serviceSignature.to_s != "" && serviceSignature.signatureDt.to_s != ""
		    	time = Time.parse(serviceSignature.signatureDt.to_s)
    			signatureDt = time.strftime('%d %B %Y')
			end
			signatureDtHtml = "<div style='text-align: center;' id='signature#{signatureTypeCd}_dt'>#{signatureDt}</div>"
		    return signatureDtHtml
		end
	end
end
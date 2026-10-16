require 'CommonModules/entityschema'
# require 'CommonModules/syncmodule'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'Product/product_util'
require 'Quotation/APO'
require 'date'




module MobiSys
	class QuotationService
		extend MobiSys::BrowserHelper
		
		def self.isEappLinkApplicable(quotation)
			baseProduct = quotation.getBaseProduct if quotation
			quotParty = quotation.getParty(baseProduct)
			product ||= MobiSys::ProductUtil.getProduct(baseProduct.productSeq.to_s) if baseProduct
			isEappLinkApplicable = false
			if quotation && product && quotation.quoteStatusCd.to_s == "ACCEPTED"
				linkToEAPPActivator = product.getFacet('LINKTOEAPPACTIVATOR')
				defTableDO = MobiSys::ProductUtil.getProductDefinitionTableDO(linkToEAPPActivator.ruleSeq, quotation, baseProduct, quotParty) if linkToEAPPActivator  #check with niharika
				if defTableDO != nil and defTableDO.outputAction.to_s == "YES"
					isEappLinkApplicable = true
			   end
			end
			return isEappLinkApplicable
		end

		def self.getPortfolioModels(quotation,baseProduct,product)
	        offlineProductModelArray = []

	        fundDervFacet = product.getFacet("FUNDMODELDERIVATION")
	        fundDervFacetTT = product.getTableTypeMappingSeq("FUNDMODELDERIVATION")
	        if fundDervFacet && fundDervFacetTT
		        quotationIO = MobiSys::IO::QuotationIO.new
	            quotationIO.baseDO = quotation
	            quotationIO.baseProduct = baseProduct
	            fundDervFacetProductDef = MobiSys::ProductBO.getProductDefinitionTable(fundDervFacetTT, quotation, baseProduct, nil, quotationIO)
	            if fundDervFacetProductDef
	            	if fundDervFacetProductDef.outputAction.to_s != ""
	            		if quotationIO.baseProduct.portfolioModelCd.to_s != "" && quotationIO.baseProduct.portfolioModelCd.to_s != fundDervFacetProductDef.outputAction.to_s
	            			quotationIO.baseProduct.QuotationProductInvestmentFundList.each(&:delete)
	            		end
	                	offlineProductModelArray = fundDervFacetProductDef.outputAction.split(',')
	                end
	            else
	                # if dt is not match then set port folio model cd as null and clear out fund records.
					# earlier this logic is there in angular,now moved here
					quotationIO.baseProduct.QuotationProductInvestmentFundList.each(&:delete)
					quotationIO.baseProduct.portfolioModelCd = nil
	            end
	        else
	            if baseProduct.currencyCd.to_s != ""
	                premiumModel = product.getPremiumModel(baseProduct.currencyCd.to_s)
	                offlineProductModelArray.push premiumModel.modelCd if premiumModel
	            else
	                product.OfflineProductModelMapList.each do |offlineProductModel|
	                    offlineProductModelArray.push(offlineProductModel.modelCd)
	                end
	            end
	        end

	        models = Model.loadObject(
	            :all, 
	            :conditions => {
	                {
	                    :name => 'modelCd',
	                    :op => 'IN'
	                    } => offlineProductModelArray
	                }
	            )

	        return models
    	end

    	def self.copyQuotationToPolicyAttributes(quotation,policy)
        	# copy quotation related fields to policy do
			fieldsToExcludeArr = ["guid", "id", "versionID"]
        	policy = MobiSys::CommonUtil.copyFields(quotation, policy, fieldsToExcludeArr)
			policy.proposalEntryDt = quotation.quotationDt
			policy.proposalReceivedDt = quotation.quotationDt
			policy.proposalSignedDt = quotation.quotationDt
			quotation.issueDt = quotation.quotationDt if quotation.issueDt.to_s == ""
			policy.policyIssueDt = quotation.issueDt
			policy.riskCommencementDt = quotation.quotationDt
			quoteBasePlan = quotation.getBasePlan
			if quoteBasePlan
				policy.baseProductId = quoteBasePlan.productId
				policy.baseProductVersion = quoteBasePlan.productVersion
				policy.baseProductTypeCd = quoteBasePlan.productTypeCd
				policy.baseProductFamilyCd = quoteBasePlan.productFamilyCd
			end
			if quotation.proposerLASame.to_s == "COPYFROMINSURED"
			   policy.quoteProposerSameAsInsured = "YES"
			else   
			   policy.quoteProposerSameAsInsured = quotation.proposerLASame
			end   
			policy.baseAgentId = $userId

			# for changing quotation party guid ref in unselectedRiders
			quotationPartyAndPolicyPartyGuidMap = {}
			policy.PartyList.each do |partyDO|
				quotationPartyAndPolicyPartyGuidMap[partyDO.quotationPartyGuid] = partyDO.guid
			end

			#copy quotation party related fields to policy party
			copyQuotationPartyToPolicyPartyAttributes(quotation,policy)
			#create new quotation product and copy product related fields
			copyQuotationProductToPolicyProductAttributes(quotation,policy, quotationPartyAndPolicyPartyGuidMap)
			#create new quotation top up and withdraw and copy related fields
			copyQuotationExtra(quotation,policy)
			#copy quotation additional field into 000 type of policy additional fields and reatin other fields
			copyAdditionalFields(quotation,policy)

			riders = []
			partyGuids = []
			unselectedRiders = quotation.unselectedRiders
            if quotation.proposerLASame == "COPYFROMINSURED" || quotation.proposerLASame == "YES"
                insured = quotation.getPartyByRole('PRIMARY')
                proposer = quotation.getPartyByRole('PROPOSER')
                unselectedRiders = quotation.unselectedRiders.to_s
                unselectedRiders = unselectedRiders.gsub(insured.guid,proposer.guid)
            end
			if unselectedRiders.to_s != ""
				riders = unselectedRiders.split("|");
				partyGuids = Array.new(riders.length)
				riders.each_with_index do |rider, i|
					values = rider.split(/\s*:\s*/)
					partyGuids[i] = values[0]
				end
				unselectedRiders = ""
			end

			if partyGuids.to_s != ""
				partyGuids.each_with_index do |guid, i|
					partyGuids[i] = quotationPartyAndPolicyPartyGuidMap[guid]
					rider = riders[i]
					oldPrdSeq = rider.split(":").last
					unselectedRiders += "#{partyGuids[i]}:#{oldPrdSeq}|"
				end
			end
			policy.unselectedRiders = unselectedRiders
			return policy
        end

    	def self.hasProposalExpired(quotation)
	        proposalVersionMatrix = Lookupvalue.loadObject(
	            :first,
	            :conditions => {
	                {:name => 'cd'} => quotation.proposalVersion.to_s,
	                {:name => 'key'} => 'PROPOSALVERMATRIX'},
	            :op => 'AND'
	        )
	        if proposalVersionMatrix
	            proposalStartDt = proposalVersionMatrix.additionalField1
	            proposalEndDt = proposalVersionMatrix.additionalField2
	            currentTime = Time.now

	            if proposalEndDt.to_s != ""
	                if currentTime.to_date >= MobiSys::ProductUtil.getDBDate(proposalStartDt.to_s).to_date && currentTime.to_date <= MobiSys::ProductUtil.getDBDate(proposalEndDt.to_s).to_date
	                    return false
	                else
	                    return true
	                end
	            else
	                return false
	            end
	        end
	    end

	    def self.commonShowBenefitTable
	        #puts "!!!!!!!!!!!!!!!!!!!!!!!!#{$quotationIO.inspect}"
	        #MobiSys::QuotationUtil.finalMapNew($quotationIO)
	        MobiSys::UIGenUtil.finalMapNew($quotationIO)
	        #puts "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#{$quotationIO.inspect}"
	        MobiSys::QuotationUtil.findTemplatePageMapping($quotationIO)
	        #puts "****************************************#{$quotationIO.inspect}"
	        MobiSys::UIGenUtil.getHtmlStringandGeneratePDF(true, $quotationIO, $apoQuotationIO)
	        #puts "****************************************#{$quotationIO.inspect}"
	        MobiSys::UIGenUtilCompanyHelper.alterDataInOutput
	    end

	    #Method to generate HTML source for offline PDF generation based on offline HTML
	    def self.generateOfflinePDFHTML
	    	companyColour = OfflineApplication.find(:first, :conditions =>{{:name =>'PROPERTY'} =>'COMPANYCOLOUR'})
		    returnHash = {}
	        if System.get_property('platform') == 'ANDROID'
	            $showPdf = true
	        elsif System.get_property('platform') == 'APPLE'
	            $offlinePDF = "true"
	            $outputPageSize = "Letter"
	            $outputPageHeightMM = "279.4mm"
	            $outputPageWidthMM = "220mm" if companyColour != nil && companyColour.value == "SLOCPI"
	            $outputPageWidthMM = "215.9mm"
	            $outputPageHeightPX = "1056px"
	            $outputPageWidthPX = "816px"
	            $outputPagePaddingLeftMM = "1mm"
	            $outputPagePaddingRightMM = "1mm"
	        end
	        GC.enable
	        GC.start
	        $quotationIO.offlinePDFGeneration = "true"
	        commonShowBenefitTable
	        GC.enable
	        GC.start
	        $showPdf = nil

	        filehtml = ""
	        if System.get_property('platform') == 'ANDROID'
	            filehtml << "<!DOCTYPE html>"
	            filehtml << "<html lang=\"en\">"
	            filehtml << "<head>"
	            filehtml << "<meta charset=\"utf-8\">"
	            filehtml << "</head>"
	            filehtml << "<body>"
	        end
	            $offlinePDF = ""

	        $quotationIO.htmlContent.each do |htmlContent|
	            if !htmlContent.empty?
	                totalPages = htmlContent.size
	                skipPageNumber=0;
	                totalSkipNumber = 0;
	                htmlContent.each_pair do |pageNumber, page|
	                    if(page["content"].include? "$SKIPPAGENUMBER$")
	                        totalSkipNumber = totalSkipNumber - 1;
	                    end
	                end
	                htmlContent.each_pair do |pageNumber, page|
	                    content = page["content"]
	                    if(page["content"].include? "$ZEROMARGIN$")
	                        content.gsub!("$ZEROMARGIN$", "")
	                        filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
	                    else
	                        filehtml  << "<div class=\"bodyDiv\">"
	                    end
	                    if(content.include? "$SKIPPAGENUMBER$")
	                        skipPageNumber = skipPageNumber - 1
	                        content.gsub!("$SKIPPAGENUMBER$", "")
	                        if(pageNumber != totalPages)
	                            if System.get_property('platform') == 'APPLE'
	                                content << "</div><pd4ml:page.break>"
	                            else
	                                content << "<pd4ml:page.break></div></div>"
	                            end
	                        else
	                            content << "</div>"
	                        end
	                    else
	                        content.gsub!("$PAGENUMBER$", (pageNumber+skipPageNumber).to_s)
	                        content.gsub!("$TOTALPAGENUMBER$",(totalPages+totalSkipNumber).to_s);
	                        if(pageNumber != totalPages)
	                            if System.get_property('platform') == 'APPLE'
	                                content << "</div><pd4ml:page.break>"
	                            else
	                                content << "<pd4ml:page.break></div></div>"
	                            end
	                        else
	                            content << "</div>"
	                        end
	                    end
	                    filehtml << content
	                end
	            end
	        end

	        if System.get_property('platform') == 'ANDROID'
	            filehtml << "</body>"
	            filehtml << "</html>"
	        end

	        primaryParty = $quotationIO.baseDO.getPartyByRole("PRIMARY")
	        
	        # lastName = primaryParty.lastname
	       
	        # firstName = primaryParty.firstname
	        lastName  = primaryParty.lastname.to_s.gsub(/[^A-Za-z0-9_-]/, '')
			firstName = primaryParty.firstname.to_s.gsub(/[^A-Za-z0-9_-]/, '')
	        
	        facet = CompanyFacet.loadObject(:first, :conditions=>{{:name=>'facetCd'}=>"PROPPDFFILENAME"})
	        
	        facetSeq = facet.ruleSeq
	        
	        if facet
	           
	        dtforshortname = MobiSys::ProductUtil.getProductDefinitionTableDO(facetSeq, $quotationIO.baseDO, $quotationIO.baseDO.getBaseProduct)
	        
	        end
	        time = Time.new
	        fileName = lastName + "_"+ firstName.split.map(&:chr).join + "_"+ dtforshortname.outputAction.to_s + "_"+ time.strftime("%d%m%Y%H%M%S")
	       
	        #Create output folder
	        outputFolder = Rho::RhoFile.join(Rho::Application.userFolder, fileName)
	        Rho::RhoFile.makeDir(outputFolder) unless Rho::RhoFile.exists(outputFolder)
	        
	        #Copy output resources
	        data = filehtml.scan(/\/public\/[^"\s]+\.(?:js|css|jpg|jpeg|png)/i).uniq
	        if System.get_property('platform') == 'APPLE'
	            data = data + [
	                "/public/jquery/jquery-3.7.1.min.js",
	                "/public/js/RGraph/RGraph.bar.js",
	                "/public/js/RGraph/RGraph.hbar.js",
	                "/public/js/RGraph/RGraph.scatter.js",
	                "/public/js/RGraph/RGraph.common.annotate.js",
	                "/public/js/RGraph/RGraph.common.context.js",
	                "/public/js/RGraph/RGraph.common.dynamic.js",
	                "/public/js/RGraph/RGraph.common.effects.js",
	                "/public/js/RGraph/RGraph.common.resizing.js",
	                "/public/js/RGraph/RGraph.common.tooltips.js",
	                "/public/js/RGraph/RGraph.common.zoom.js",
	                "/public/js/RGraph/RGraph.drawing.circle.js",
	                "/public/js/RGraph/RGraph.drawing.image.js",
	                "/public/js/RGraph/RGraph.drawing.marker1.js",
	                "/public/js/RGraph/RGraph.drawing.marker2.js",
	                "/public/js/RGraph/RGraph.drawing.text.js",
	                "/public/js/RGraph/RGraph.drawing.xaxis.js",
	                "/public/js/RGraph/RGraph.drawing.yaxis.js",
	                "/public/js/RGraph/RGraph.drawing.rect.js",
	                "/public/js/RGraph/RGraph.line.js",
	                "/public/js/RGraph/RGraph.common.core.js",
	                "/public/js/RGraph/RGraph.pie.js",
	                "/public/js/RGraph/RGraph.common.key.js",
	                "/public/css/main_company.css",
	                "/public/css/AGNDLI.ttf",
	                "/public/css/AGNDL.ttf",
	                "/public/css/AGNDM.ttf",
	                "/public/css/AGNDMI.ttf",
	                "/public/css/NotoSansCJKRegular.ttc",
	                "/public/css/NotoSansCJKBold.ttc",
	                "/public/css/NotoSansCJKscRegular.otf",
	                "/public/css/Gioveb__.ttf",
	                "/public/css/Giovebi_.ttf",
	                "/public/css/Giovew__.ttf",
	                "/public/css/Giovewb_.ttf",
	                "/public/css/Giovewi_.ttf",
	                "/public/css/AgendaBold.ttf",
	                "/public/css/AgendaLight.ttf",
	                "/public/css/AgendaMedium.ttf"

	            ]
	        end
	        data.each do |entry|
	            newEntry = entry.gsub('"','')
	            @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
	            FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
	        end

	        #Remove relative paths
	        filehtml.gsub!('/public/jquery/','')
	        filehtml.gsub!('/public/js/RGraph/','')
	        filehtml.gsub!('/public/js/','')
	        if System.get_property('platform') == 'ANDROID'
	            filehtml.gsub!('/public/images/SalesIllustration/',"#{outputFolder}/")
	            filehtml.gsub!('/public/images/outputimages/',"#{outputFolder}/")
	            filehtml.gsub!('</pd4ml:page.footer>','</pd4ml:page.footer><main_body>')
	            filehtml.gsub!('</div><!--div class tabcontent end--><pd4ml:page.break></div></div>','</main_body></div><!--div class tabcontent end--><pd4ml:page.break></div></div>')
	            # UI changes...ideally to be moved to section details
	            filehtml.gsub!('height="40%"','')
	            filehtml.gsub!('height="10%"','')
	            # filehtml.gsub!('width="2%"','')
	            filehtml.gsub!('<tr> <td> <b  style="font-size:10px;font-family:arial;color:#003946">','<tr width="30%"><td></td></tr><tr width="30%"> <td> <b  style="font-size:10px;font-family:arial;color:#003946">')
	            filehtml.gsub!('<!-- Processing sectionDetailsDO with id 820101 -->','<!-- Processing sectionDetailsDO with id 820101 --><main_body>')
	            filehtml.gsub!('font-size:14px;"><b>THIS','font-size:9px;"><b>THIS')
	            filehtml.gsub!('<div style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;color:#003946;padding-top:10px;"> <b>Prepared by</b></div>','<p style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;color:#003946;padding-top:10px;"> <b>Prepared by</b></p>')
	            filehtml.gsub!('<div style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;"> 1)&nbsp;&nbsp;&nbsp;&nbsp;Assumes using Premium Holiday feature after Commitment Period if the Investment Fund Value is still enough to pay mandatory charges by due date.</div>','<p style="font-size:10px;font-family:arial;margin-left:5px;margin-right:5px;"> 1)&nbsp;&nbsp;&nbsp;&nbsp;Assumes using Premium Holiday feature after Commitment Period if the Investment Fund Value is still enough to pay mandatory charges by due date.</p>')
	            filehtml.gsub!('style=" margin-bottom: 10px;"','')
	            filehtml.gsub!('style="margin-bottom:10px"','')
	        elsif System.get_property('platform') == 'APPLE'
	            filehtml.gsub!('/public/images/SalesIllustration/','')
	            filehtml.gsub!('/public/images/outputimages/','')
	        end
	        filehtml.gsub!('/public/css/','')
	        filehtml.gsub!('/public/jazz/js/','')

	        begin
	            if System.get_property('platform') == 'ANDROID'
	                #Generate HTML file
	               # htmlFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}.html")
	                htmlFileName = Rho::RhoFile.join(outputFolder, "#{fileName}.html")
	                File.open(htmlFileName,'w') do |f|
	                    f.puts filehtml
	                end
	            end

	            #pdfFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}.pdf")
	            pdfFileName = Rho::RhoFile.join(outputFolder, "#{fileName}.pdf")
	            objects = Rho::Pdfgen.enumerate
	            obj = objects[0]

	            if System.get_property('platform') == 'ANDROID'
	                # Android code
	                res = obj.generateAndroidPDF(htmlFileName, "PORTRAIT", "YES", "")
	            elsif System.get_property('platform') == 'APPLE'
	                # iOS code
	                individualPages = filehtml.split("<pd4ml:page.break>")
	                listOfPdfs = ""
	                individualPages.each_with_index do |page, index|
	                    headerSplit = ""
	                    if page.include?("<pd4ml:page.header>")
	                        headerSplit = page[page.index("<pd4ml:page.header>")..page.index("</pd4ml:page.header>")+19]
	                    end
	                    footerSplit = ""
	                    if page.include?("<pd4ml:page.footer>")
	                        footerSplit = page[page.index("<pd4ml:page.footer>")..page.index("</pd4ml:page.footer>")+19]
	                    end
	                    mainSplit = page
	                    if mainSplit.include?("<pd4ml:page.header>")
	                        mainSplit = mainSplit.gsub(headerSplit,"")
	                    end
	                    if mainSplit.include?("<pd4ml:page.footer>")
	                        mainSplit = mainSplit.gsub(footerSplit,"")
	                    end

	                    if companyColour != nil && companyColour.value == "SLGFI"
	                        pdfheight=1051
	                       	mainSplit = headerSplit+mainSplit+footerSplit
	                        mainSplit.gsub!("<pd4ml:page.footer>","<pd4ml:page.footer id='footer' style='width:99%;'>")
	                        mainSplit.gsub!("<table width='100%' class='fontFamilyATL' id='footerLayout'><tr>","<table width='100%' class='fontFamilyATL'><tr><td width='5%'>&nbsp;</td>")
	                        mainSplit.gsub!("<td width='100%' id='pdfFooterSize'>","<td width='90%'>")
	                        mainSplit.gsub!("</tr id='footerEnd'></table>","<td width='5%'>&nbsp;</td></tr></table>")
	                        mainSplit.gsub!("<div id='footerLogo1'>","<div style='clear:both;position: absolute;top:251.5mm;width:100%'>")
	                        mainSplit.gsub!("<div id='footerLogo2'>","<div style='clear:both;position: absolute;top:251.5mm;width:100%'>")
	                        mainSplit.gsub!("id='footerLogo3'","style='position: absolute;top:210mm;width:87%'")
	                        mainSplit.gsub!("<div id='footerLogo5'>","<div style='clear:both;position: absolute;top:255mm;width:100%'>")
	                        mainSplit.gsub!("id='footerLogo4'","style='position: absolute;right:5px;'")
	                        mainSplit.gsub!("id='footerLogo5BANCA'","style='position: absolute;right:5px;margin-bottom:-10px !important'")
	                        mainSplit.gsub!("id='toplineWidth'","style='width:234mm !important'")
	                        mainSplit.gsub!("id='coverpageFooter'","style='clear:both;position: absolute;top:251.65mm;width:100%'")##agency
	                        mainSplit.gsub!("id='coverpageBANCARCBCFooter'","style='clear:both;position: absolute;top:250mm;width:105%;margin-left:-15px;margin-right:-15px;'")
	                        mainSplit.gsub!("id='coverpagebancaFooter'","style='clear:both;position: absolute;top:254mm;width:105%;margin-left:-20px;margin-right:-20px'")##first page non bank,banca TRAD
	                        mainSplit.gsub!("id='coverpagebancaFooterVUL'","style='clear:both;position: absolute;top:253mm;width:105%;margin-left:-25px'")##VULcoveragePage of BANCA
	                        mainSplit.gsub!("id='coverpageagencyFooter23'","style='clear:both;position: absolute;top:255mm;width:100%;margin-left:-57px;border:0px solid black'")
	                        mainSplit.gsub!("id='barcodeFooter'","style='clear:both;position: absolute;top:238.9mm'")
	                        mainSplit.gsub!("id='barcodeFooter2'","style='clear:both;position: absolute;top:254.4mm;border:1px solid black'")
	                        mainSplit.gsub!("id='nonBankCaveat'","style='clear:both;position: absolute;top:250mm;width:105%;margin-left:-20px;margin-right:-20px'")
	                        mainSplit.gsub!("id='bancaVulCaveat'","style='clear:both;position: absolute;top:249mm;width:105%;margin-left:-25px'")
	                        mainSplit.gsub!("id='bancaTradCaveat'"," style='clear:both;position: absolute;top:252mm;width:100%;margin-left:-5px;margin-right:15px;'")
	                        mainSplit.gsub!("id='barcodeImage'"," style='clear:both;position: absolute;top:237mm;padding-bottom:-65px !important'")
	                        mainSplit.gsub!("id='leftmargin'>","style='margin-left:-57px !important;'>")
	                        mainSplit.gsub!("id='marginTopImg'>","style='margin-top:5px !important;'>")
	                    else
	                    	pdfheight=1056
	                    	# mainSplit.gsub!("$(document).height()","$(document).height()*window.devicePixelRatio")
		                    # mainSplit.gsub!("$(document).width()","$(document).width()*window.devicePixelRatio")
							mainSplit = headerSplit+mainSplit+footerSplit
		                    mainSplit.gsub!("<pd4ml:page.footer>","<pd4ml:page.footer id='footer' style='width:99%;'>")
		                    mainSplit.gsub!("<table width='100%' class='fontFamilyATL' id='footerLayout'><tr>","<table width='100%' class='fontFamilyATL'><tr><td width='5%'>&nbsp;</td>")
		                    mainSplit.gsub!("<td width='100%' id='pdfFooterSize'>","<td width='90%'>")
		                    mainSplit.gsub!("</tr id='footerEnd'></table>","<td width='5%'>&nbsp;</td></tr></table>")
		                    mainSplit.gsub!("<div id='footerLogo1'>","<div style='clear:both;position: absolute;top:251.5mm;width:100%'>")
		                    mainSplit.gsub!("<div id='footerLogo2'>","<div style='clear:both;position: absolute;top:251.5mm;width:100%'>")
		                    mainSplit.gsub!("id='footerLogo3'","style='position: absolute;top:210mm;width:87%'")
		                    mainSplit.gsub!("<div id='footerLogo5'>","<div style='clear:both;position: absolute;top:255.8mm;width:100%'>")
		                    mainSplit.gsub!("id='footerLogo4'","style='position: absolute;right:5px;'")
		                    mainSplit.gsub!("id='footerLogo5BANCA'","style='position: absolute;right:5px;margin-bottom:-10px !important'")
		                    mainSplit.gsub!("id='toplineWidth'","style='width:234mm !important'")
		                    mainSplit.gsub!("id='coverpageFooter'","style='clear:both;position: absolute;top:251.75mm;width:100%'")##agency
		                    mainSplit.gsub!("id='coverpageBANCARCBCFooter'","style='clear:both;position: absolute;top:251.5mm;width:105%;margin-left:-15px;margin-right:-15px;'")
		                    mainSplit.gsub!("id='coverpagebancaFooter'","style='clear:both;position: absolute;top:255.5mm;width:105%;margin-left:-20px;margin-right:-20px'")##first page non bank,banca TRAD
		                    mainSplit.gsub!("id='coverpagebancaFooterVUL'","style='clear:both;position: absolute;top:253.7mm;width:105%;margin-left:-25px'")##VULcoveragePage of BANCA
		                    mainSplit.gsub!("id='coverpageagencyFooter23'","style='clear:both;position: absolute;top:256.9mm;width:100%;margin-left:-57px;border:0px solid black'")
		                    mainSplit.gsub!("id='barcodeFooter'","style='clear:both;position: absolute;top:238.9mm'")
		                    mainSplit.gsub!("id='barcodeFooter2'","style='clear:both;position: absolute;top:254.4mm;border:1px solid black'")
		                    mainSplit.gsub!("id='nonBankCaveat'","style='clear:both;position: absolute;top:251.3mm;width:105%;margin-left:-20px;margin-right:-20px'")
		                    mainSplit.gsub!("id='bancaVulCaveat'","style='clear:both;position: absolute;top:250mm;width:105%;margin-left:-25px'")
		                    mainSplit.gsub!("id='bancaTradCaveat'"," style='clear:both;position: absolute;top:253mm;width:100%;margin-left:-5px;margin-right:15px;'")
		                    mainSplit.gsub!("id='barcodeImage'"," style='clear:both;position: absolute;top:238.5mm;padding-bottom:-65px !important'")
		                    mainSplit.gsub!("id='leftmargin'>","style='margin-left:-57px !important;'>")
		                    mainSplit.gsub!("id='marginTopImg'>","style='margin-top:5px !important;'>")
	                    end
	                    
	                    filehtml = ""
	                    filehtml << "<!DOCTYPE html>"
	                    filehtml << "<html lang=\"en\">"
	                    filehtml << "<head>"
	                    filehtml << "<meta charset=\"utf-8\">"
	                    filehtml << "<script type=\"text/javascript\" src=\"jquery-3.7.1.min.js\"></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.core.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.annotate.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.context.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.dynamic.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.effects.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.resizing.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.tooltips.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.zoom.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.key.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.circle.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.image.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker1.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker2.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.text.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.xaxis.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.yaxis.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.rect.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.bar.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.hbar.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.scatter.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.line.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.pie.js\" ></script>"
	                    filehtml << "<link rel=\"stylesheet\" type=\"text/css\" href=\"main_company.css\" />"
	                    filehtml << "</head>"
	                    filehtml << "<body style='border:1px solid white'>"
	                    filehtml << "<style type='text/css'>#footer{clear:both;position:absolute;}</style>"
	                    filehtml << "<style type='text/css'>@media print {* { -webkit-print-color-adjust: exact !important; } }</style>" #DPHSS-1680
	                    #filehtml << "<style type='text/css'>#footer{clear:both;position:absolute;}table {border-collapse:collapse; table-layout:fixed;}table td{word-wrap:break-word;}</style>"
	                    filehtml << mainSplit
	                    filehtml << "<script type=\"text/javascript\">$(document).ready(function(){document.body.style.height='#{$outputPageHeightMM}';document.body.style.width='#{$outputPageWidthMM}';document.body.style.paddingLeft='#{$outputPagePaddingLeftMM}';document.body.style.paddingRight='#{$outputPagePaddingRightMM}';document.body.style.margin='0';
	                    var footer = document.getElementById('footer');
	                    if (footer) {
	                        var height = footer.offsetHeight;
	                        var style = getComputedStyle(footer);
	                        height += parseInt(style.marginTop || 0) + parseInt(style.marginBottom || 0);
	                        footer.style.top = (#{pdfheight} - height)-8+'px';
	                    }
	                    });</script>"
	                    #footer.style.top = (1056-height)-8+'px';});</script>"

	                    filehtml << "<script type=\"text/javascript\">$(window).load(function(){$('.pisImg').css(\"width\", 827 +\"px\");$('.pisImg').css(\"height\", 1160 +\"px\");});</script>"
	                    filehtml << "</body>"
	                    filehtml << "</html>"
	                    GC.enable
	                    GC.start
	                     #tempHTMLFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{index}.html")
	                     #tempPDFFileName = Rho::RhoFile.join(outputFolder, "#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{index}.pdf")

	                    tempHTMLFileName = Rho::RhoFile.join(outputFolder, "#{fileName}_#{index}.html")
	                    tempPDFFileName = Rho::RhoFile.join(outputFolder, "#{fileName}_#{index}.pdf")
	                    File.open(tempHTMLFileName,'w') do |f|
	                        f.puts(filehtml)
	                    end
	                    res = obj.generateIOSPDF(tempHTMLFileName, tempPDFFileName)
	                    listOfPdfs += "#{tempPDFFileName}|"
	                end
	                userPassword = ""
	                masterPassword = ""
					pdfPasswordEnabled = "NO"

	                # Configure PDF password protection
	        		pdfPasswordEnabled = OfflineApplication.find(:first, :conditions=>{:property=>'IS_ENCRYPTEDDOWNLOADPDF_REQD'})

	                if pdfPasswordEnabled != nil && pdfPasswordEnabled.value == "YES" && $quotationIO.baseDO.QuotationPartyList.size > 0
	                    primaryParty = $quotationIO.baseDO.getPartyByRole("PRIMARY")
	                    if primaryParty
	                    	if primaryParty.dob.to_s != ""
	                    		userPassword = DateTime.parse(primaryParty.dob.to_s).strftime("%d%b%Y")
	                    	end
	                        if primaryParty.lastname.to_s != "" && $quotationIO.baseDO.leadId.to_s !=""
	                            userPassword = userPassword+primaryParty.lastname.to_s[0].upcase
	                        end
	                    end
	                end

	                if pdfPasswordEnabled != nil && pdfPasswordEnabled.value == "YES"
		                masterPassword = (MobiSys::Encryption.decryptContent($quotationIO.baseDO.userId)).to_s
					end

	                res = obj.mergeIOSPDF(listOfPdfs[0..-2], pdfFileName, masterPassword, userPassword)
	            end
	            GC.enable
	            GC.start
	            returnHash['pdfFileName'] = pdfFileName
	            # pdfFolder = Rho::RhoFile.join(Rho::Application.userFolder, "OUTPUT_FOLDER")
	            # FileUtils.rm_rf(pdfFolder) if Rho::RhoFile.exists(pdfFolder)
	            # Rho::RhoFile.makeDir(pdfFolder) unless Rho::RhoFile.exists(pdfFolder)
	            # if File.exist?(pdfFolder)
	            #     FileUtils.cp(pdfFileName, pdfFolder)
	            # end
	            # finalPdfFileName = Rho::RhoFile.join(pdfFolder, "#{fileName}.pdf")
	            
	            # Rho::System.openUrl(finalPdfFileName)
	        rescue StandardError => se
	            puts "exception: #{se.backtrace}"
		        returnHash["error"] = getLabelValue('ILLUSTRATIONDOWNLOADFAILED',[errorPopup])
	        end
		    return returnHash

	        # redirect :action => :show, :id => $quotationIO.baseDO.object, :layout => :jazzLayout
	    end

	    def self.saveValidate(quotation, needToPersist = true, mode = "")
	        @quotation = quotation
	        return false if @quotation != nil && ((@quotation.quoteStatusCd.to_s == 'ACCEPTED' || @quotation.quoteStatusCd.to_s == 'SYNCDONE') && @quotation.entityStatus.to_s != "REOPEN")
	       
	        @quotation.quotationDt = getDBDate(@quotation.quotationDt) if @quotation.quotationDt != nil && @quotation.quotationDt != ""
	        @quotation.jointLife = nil if @quotation.jointLife == nil || @quotation.jointLife =='NO'

	        # @quotation.jointLife = nil unless @quotation.jointLife #Line added so that on flag gets removed when de-selecting the flag on screen.
	        @baseProduct = @quotation.getBaseProduct()
	        $currentProduct ||= MobiSys::ProductUtil.getProduct(@baseProduct.productSeq)
	        currencyCode = @baseProduct != nil ? @baseProduct.currencyCd : nil
	        $currencyFormat = nil
	        if currencyCode
	            lookupValueOfCurrencyMaster = Lookupvalue.find(:first, :conditions =>  {
	                    {
	                        :name => 'key',
	                    } => 'CURRENCYMASTER',
	                    {
	                        :name => 'cd',
	                    } => currencyCode
	                },
	                :op => 'AND'
	            )

	            if lookupValueOfCurrencyMaster != nil
	                if lookupValueOfCurrencyMaster.additionalField1 != nil
	                    $currencyFormat = lookupValueOfCurrencyMaster.additionalField1
	                end
	            end
	        end
	        if $currencyFormat == nil
	            $currencyFormat = $rhoconfig[:number_format_pattern].to_s
	        end
	        if @baseProduct.product == nil
	            quot_product = MobiSys::ProductUtil.getProduct(@baseProduct.productSeq)
	        else  
	            quot_product = @baseProduct.product
	        end
	        #Code block to check if BATCHSETTLEMENTOPTION is present or not
	        #If present do the needful
	        planOptionFacet = quot_product.getFacet('BATCHSETTLEMENTOPTION') if quot_product
	        if planOptionFacet
	            prdBankPart = quot_product.getFacet('PRDBANKINGPARTNER')
	            @quotation.quotAddtnlField1 = (prdBankPart && !prdBankPart.actionValue.nil?) ? prdBankPart.actionValue : @quotation.quotAddtnlField1
	            prdIssueDt = quot_product.getFacet('PRDISSUEDATE')
	            @quotation.issueDt = (prdIssueDt && !prdIssueDt.actionValue.nil?) ? prdIssueDt.actionValue : @quotation.quotationDt
	        else
	            # @quotation.quotAddtnlField1 ='nil'
	            @quotation.issueDt = @quotation.quotationDt
	        end
	        #BATCHSETTLEMENTOPTION code block ends

	        # set covert type base upon product facet
	        if quot_product.getFacetValue('FAMILYINSUREDDETAILS') == "YES"
	        	@quotation.coverTypeCd = "FAMILYFLOATER"
        	elsif quot_product.getFacetValue('MULTILIFEAPPLICABLE') == "YES"
        		@quotation.coverTypeCd = "INDIVIDUAL"
        	end

	        # Quotation expiry date computation
	        expiryDays = MobiSys::BrowserHelper.getFacetMappedValue("QUOTATIONEXPIRYDAYS", nil)
	        if expiryDays.to_s != "" && @quotation.quotationDt.to_s != "" && @quotation.quotationExpiryDt.to_s == ""
	            @quotation.quotationExpiryDt = getDBDate((Date.strptime(getScreenDate(@quotation.quotationDt.to_s), "%d/%m/%Y") + expiryDays.to_i).strftime("%d/%m/%Y").to_s)
	        end

	        # Quotation backdated flag computation
	        if @quotation.systemCreatedDt.to_s != "" && @quotation.quotationDt.to_s != ""
	            if (Date.strptime(getScreenDate(@quotation.systemCreatedDt.to_s), "%d/%m/%Y") - Date.strptime(getScreenDate(@quotation.quotationDt.to_s), "%d/%m/%Y") > 0)
	                @quotation.isBackdatedFl = "YES"
	            else
	                @quotation.isBackdatedFl = "NO"
	            end
	        end

	        @insured = MobiSys::QuotationBO.getInsured(@quotation)
	        @policyHolder = MobiSys::QuotationBO.getPolicyHolder(@quotation)
	        @quotation.proposerLASame = 'COPYFROMINSURED' if @quotation.insuranceTypeCd == 'TRAVEL'
	        if @policyHolder == nil && @quotation.proposerLASame == "COPYFROMINSURED"
	            @policyHolder = QuotationParty.new(:roleCd => "PROPOSER")
	            @quotation.addQuotationParty(@policyHolder)
	        end

	        @quotation.proposerLASame = nil unless @quotation.proposerLASame #Line added so that on flag gets removed when de-selecting the floag on screen.
	        if @quotation.proposerLASame == 'YES' ||  @quotation.proposerLASame == "COPYFROMINSURED"
	            proposerLASameCopy
	        end

	        if quot_product.getFacetValue('PROPOSERDIFFERENTFROMINSURED') == "YES"
		        @quotation.proposerLASame = "NO" if @quotation.proposerLASame == nil
			elsif @quotation.insuranceTypeCd.to_s == "LIFE" || @quotation.insuranceTypeCd == nil
				@quotation.proposerLASame = "YES" if @quotation.proposerLASame == nil
			end
	        
	        #code for removing on value from db on uncheck
	        @baseProduct.topUpAllocSameAsPremAllocFl = nil unless @baseProduct.topUpAllocSameAsPremAllocFl
	        #end of code for removing on value from db on uncheck
	        @riders = MobiSys::QuotationBO.getRiders(@quotation)
	        getBuiltInRiderList(quot_product, @quotation)
	        if quot_product.getFacetValue('RIDERAUTOPOPULATIONREQUIRED') == "YES"
	            if needToPersist == true 
	                @newriders = @quotation.getNonBuiltInRiders
	                # callMethodFlag = @params['currentTab'].to_s != "tab_rider" && @params['sym_current_Tab'].to_s != 'tab_rider'
	                # if callMethodFlag
	                    loadRiderProducts(@quotation, quot_product, false)
	                # end
	                if $rhoconfig[:TABFEATUREREQD]
	                    # especially for cases where personal details are changed and some riders are no longer applicable
	                    unless ($displayRidersHM == nil || $displayRidersHM.empty?)
	                        @quotation.QuotationProductList.each do |qp|
	                            if qp.productTypeCd.to_s == 'RIDER' && qp.builtInRiderFl.to_s != 'YES'
	                                if (qp.partyRoleCd == 'PRIMARY' || qp.partyRoleCd == 'PROPOSER') && @quotation.proposerLASame == 'COPYFROMINSURED'
	                                    qp.removed = 'YES' unless ($displayRidersHM['SAMEAS'].values.flatten.compact.collect{|x| x.object}.include? qp.object)
	                                else
	                                    qp.removed = 'YES' unless ($displayRidersHM[qp.insuredPartyRefGuid] != nil and $displayRidersHM[qp.insuredPartyRefGuid].values.flatten.compact.collect{|x| x.object}.include? qp.object)
	                                end
	                            end
	                        end
	                    else
	                        if mode != "copy"
	                            @quotation.QuotationProductList.each do |qp|
	                                if qp.productTypeCd.to_s == 'RIDER' && qp.builtInRiderFl.to_s != 'YES'
	                                    qp.removed = 'YES'
	                                end
	                            end
	                        end
	                    end
	                else
	                    @newriders.each do |rider|
	                        rider.selected = nil unless rider.selected
	                        if (rider.selected.to_s != "on" && rider.selected.to_s != 'YES')
	                            rider.removed = "YES" if rider.builtInRiderFl != 'YES'
	                            @quotation.removeQuotationProduct(rider) if rider.builtInRiderFl != 'YES'
	                        elsif rider.selected.to_s == 'on' || rider.selected.to_s == 'YES'
	                            rider.removed = ''
	                        end
	                    end
	                end
	            else
	                @riders.each do |rider|
	                    rider.selected = nil unless rider.selected
	                    if (rider.selected.to_s != "on" && rider.selected.to_s != 'YES')
	                        rider.removed = "YES" if rider.builtInRiderFl != 'YES'
	                    elsif rider.selected.to_s == 'on' || rider.selected.to_s == 'YES'
	                        rider.removed = ''
	                    end
	                end
	            end
	        end

	        @funds = @baseProduct.QuotationProductInvestmentFundList
	        
	        ######## check duplicate quotationRefNum########################################
	        if needToPersist and (@quotation.quotationRefNum == nil || @quotation.quotationRefNum == "")
	            @quotation.quotationRefNum = SequenceNoGenerator.getNextNumber('QUOTATION')
	        end
	        

	        @riders = MobiSys::QuotationBO.getRiders(@quotation) if needToPersist

	        @riders.each do |rider|
	            if rider.productSeq.to_s != '' && (["on","YES"].include?(rider.selected.to_s) || rider.builtInRiderFl.to_s == "YES")
	                @riderProduct = MobiSys::ProductUtil.getProduct(rider.productSeq)

	                rider.paymentTypeCd = @baseProduct.paymentTypeCd
	                rider.paymentFrequencyCd = @baseProduct.paymentFrequencyCd
	                rider.currencyCd = @baseProduct.currencyCd
	                if @riderProduct
	                    rider.productVersion = @riderProduct.productVersion
	                    rider.productFamilyCd = @riderProduct.productFamilyId
	                end

	                if rider.partyRoleCd != "SUPPLEMENTARY"
	                    @quotation.QuotationPartyList.each do |party|
	                        if party.roleCd == rider.partyRoleCd
	                            rider.insuredPartyRefGuid = party.guid
	                            break
	                        end
	                    end
	                end
	            else
	                rider.removed = 'YES'
	            end
	        end

	        #actions with quotation
	        @quotation.QuotationPartyList.each do |quotationParty|
	            quotationParty.dob = getDBDate(quotationParty.dob) if quotationParty.dob != nil && quotationParty.dob != ""
	        end

	        @quotation.productVersion = @baseProduct.productVersion
	        ### Namrata commented for testing
	        @quotation.productSeq = @baseProduct.productSeq
	        @quotation.productId = @baseProduct.productId
	        @quotation.productTypeCd = @baseProduct.productTypeCd
	        @quotation.productFamilyCd = @baseProduct.productFamilyCd

	        #Code to set combinedEntryAge starts
	        @quotation.QuotationProductList.each do |quotationProduct|
	            party = @quotation.getParty(quotationProduct)
	            quotationProduct.combinedEntryAge = party.age if party and party.age and party.age!=""
	        end
	        #code to set combinedEntryAge ends
	    

	        ### if supplementary is marked for deletion then delete it's rider too
	        # unless $rhoconfig[:TABFEATUREREQD]
	        supplementaryLife = MobiSys::QuotationBO.getSupplementaryLife(@quotation)  
	        supplementaryLife.each do |suppParty|
	            if suppParty.removed == "YES"
	                @quotation.QuotationProductList.each do |quotationProduct|
	                    if (quotationProduct.productTypeCd == "RIDER" || quotationProduct.productTypeCd == 'PLANMULTI') && quotationProduct.insuredPartyRefGuid == suppParty.guid
	                        quotationProduct.removed = "YES"
	                    end  
	                end
	            end
	        end
	        # end
	        @baseProduct.minTargetPremium = 0.0 if @baseProduct.minTargetPremium.to_s == ""
	        @baseProduct.maxTargetPremium = 0.0 if @baseProduct.maxTargetPremium.to_s == ""
	        @baseProduct.recommendedPremium = 0.0 if @baseProduct.recommendedPremium.to_s == ""
	        @baseProduct.unapliedPremium = 0.0 if @baseProduct.unapliedPremium.to_s == ""

	        # now check if multi life is applicable (i.e. SA, premium exists on the supp lives).. in that case add QuotationProductDOs.
	        supplementaryProductFacet = quot_product.getFacet('MULTILIFEAPPLICABLE')
	        if supplementaryProductFacet
	        	createMultiLifeQuotationProduct()
	        end
	        # set quotation product sort order
	        listQuotationProduct = Array.new
	        riderAsscFacet = quot_product.getRiderAssociationFacet()
	        @quotation.QuotationProductList.each do |quotationProduct|
	            if quotationProduct.productTypeCd == "RIDER"
	                riderAssc = quot_product.getRiderAssociationDO(nil,@baseProduct.productPlanOptionCd,quotationProduct.productPlanOptionCd, riderAsscFacet, quotationProduct.productSeq, quotationProduct.partyRoleCd)
	                quotationProduct.sortOrder = (riderAssc.sortOrder.to_s != "" ? riderAssc.sortOrder : riderAssc.id) if riderAssc
	            else
	                quotationProduct.sortOrder = 0
	            end
	            listQuotationProduct.push quotationProduct
	        end
	        listQuotationProduct.sort!{|x,y| x.sortOrder.to_i <=> y.sortOrder.to_i}
	        @quotation.setQuotationProductList(listQuotationProduct)
	        # Function for blanking out fields based on partyTypeCd (INDIVIDUAL/ORGANIZATION)
	        setPartyFields(@quotation)
	        # This method is implemented in company layer
	        # preValidate(params, needToPersist, @quotation)
	        @errors = Hash.new
	        isValidated = MobiSys::QuotationBO.validate(@quotation, @msg, @errors)
	        # This method is implemented in company layer
	        # postValidate(params, needToPersist, @quotation)
	        if $rhoconfig[:TABFEATUREREQD]
	            @errors,@errorTabs,@incompleteTabs = MobiSys::CommonUtil.getTaskExceptionList(@quotation.guid,@quotation.visitedTabs)
	            tabName, tabLabel = requiredTabs
	            visitedTabs = @quotation.visitedTabs.to_s.split(",").reject{ |c| c.empty? }
	            tabName = tabName.split(",")
	            if (@errors!=nil && !@errors.empty?) || (@incompleteTabs!=nil && !@incompleteTabs.empty?) || ((tabName - visitedTabs).join("").to_s != "" && ((tabName - visitedTabs).join("").to_s != "tab_supplementary") && (tabName - visitedTabs).join("").to_s != "tab_selProduct")
	                @msg = "ERROR"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::PENDING
	            else
	                @msg = "SUCCESS"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
	            end
	        else
	            if !isValidated
	                @msg = "ERROR"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::PENDING
	            else
	                @msg = "SUCCESS"
	                @quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
	            end
	        end
	        #For step feature in UI
	        incrementStep(@quotation,true)

	        if needToPersist
	            @quotation.childUserId = $userId
	            @quotation.appVersion = Rho::RhoConfig.app_version
	            @quotation.dbVersion = Application.getValue('DBVERSION').value
	            @quotation.persistAll
	        end
	    end


	     def self.copyQuotation(srcQuotation, targetQuotation, isShow=true)
            if isShow ## show
                targetQuotation = srcQuotation.cloneObject
                targetQuotation.quotationRefNum = ""
                targetQuotation.quoteStatusCd = "PENDING"
                targetQuotation.entityStatus = nil
                targetQuotation.signature = ""
                targetQuotation.agentSignature = ""
                targetQuotation.productId = srcQuotation.productId
                targetQuotation.guid = nil
                targetQuotation.quotationDt = Time.now.strftime("%d/%m/%Y")
                targetQuotation.systemCreatedDt = ""
                targetQuotation.id = ''
                targetQuotation.fnaId = srcQuotation.fnaId
                targetQuotation.rpqId = srcQuotation.rpqId
                targetQuotation.proposalNum = nil
                targetQuotation.step = srcQuotation.step - 1 if srcQuotation.quoteStatusCd.to_s == "ACCEPTED"
       
                #Deepali Singh - 04/04/2016 Resetting all old guids to new guids      
                partyOldNewGuidMapping = Hash.new
                # partyGuidMapping = @params['partyGuidMapping'].split('|')
                # oldGuids = partyGuidMapping[0].split(',')
                # newGuids = partyGuidMapping[1].split(',')
                # oldGuids.each_with_index do |oldGuid,index|
                #     partyOldNewGuidMapping[oldGuid] = newGuids[index]
                #     targetQuotation.unselectedRiders.to_s.gsub!(oldGuid,newGuids[index])
                # end
                if targetQuotation.QuotationPartyList && targetQuotation.QuotationPartyList.size > 0
                    targetQuotation.QuotationPartyList.each do |qp|
                        partyOldNewGuidMapping[qp.guid] = qp.object.gsub(".","_")
                    end

                    targetQuotation.QuotationPartyList.each do |qp|
                        qp.guid = qp.object.gsub(".","_")
                        qp.systemCreatedDt = ''
                        qp.id = ''
                        if qp.QuotationPartyAddressList && qp.QuotationPartyAddressList.size > 0
                            qp.QuotationPartyAddressList.each do |qpa|
                                qpa.guid = qpa.object.gsub(".","_")
                                qpa.systemCreatedDt = ''
                                qpa.id = ''
                            end 
                        end
                    end
                end
                @partyGuidMapping = "#{partyOldNewGuidMapping.keys.join(',')}|#{partyOldNewGuidMapping.values.join(',')}"
                partyGuidMapping = @partyGuidMapping.split('|')
                oldGuids = partyGuidMapping[0].split(',')
                newGuids = partyGuidMapping[1].split(',')
                
                oldGuids.each_with_index do |oldGuid,index|
                    partyOldNewGuidMapping[oldGuid] = newGuids[index]
                    targetQuotation.unselectedRiders.to_s.gsub!(oldGuid,newGuids[index])
                end

                if targetQuotation.QuotationProductList && targetQuotation.QuotationProductList.size > 0
                    targetQuotation.QuotationProductList.each do |qp|
                        if qp.insuredPartyRefGuid.to_s != ""
                            qp.insuredPartyRefGuid = partyOldNewGuidMapping[qp.insuredPartyRefGuid] 
                        end
                        qp.guid = qp.object.gsub(".","_")
                        qp.systemCreatedDt = ''
                        qp.id = ''
                        if qp.QuotationProductInvestmentFundList && qp.QuotationProductInvestmentFundList.size > 0
                            qp.QuotationProductInvestmentFundList.each do |qpif|
                                qpif.guid = qpif.object.gsub(".","_")
                                qpif.systemCreatedDt = ''
                                qpif.id = ''
                            end 
                        end
                        if qp.QuotationProductExtraList && qp.QuotationProductExtraList.size > 0
                            qp.QuotationProductExtraList.each do |qpe|
                                qpe.guid = qpe.object.gsub(".","_")
                                qpe.systemCreatedDt = ''
                                qpe.id = ''
                            end 
                        end
                        if qp.QuotationProductAdditionalList && qp.QuotationProductAdditionalList.size > 0
                            qp.QuotationProductAdditionalList.each do |qpe|
                                qpe.guid = qpe.object.gsub(".","_")
                                qpe.systemCreatedDt = ''
                                qpe.id = ''
                            end 
                        end
                    end
                end

                if targetQuotation.QuotationTopUpList && targetQuotation.QuotationTopUpList.size > 0
                    targetQuotation.QuotationTopUpList.each do |qp|
                        qp.guid = qp.object.gsub(".","_")
                        qp.systemCreatedDt = ''
                        qp.id = ''
                    end
                end
                if targetQuotation.QuotationWithdrawalList && targetQuotation.QuotationWithdrawalList.size > 0
                    targetQuotation.QuotationWithdrawalList.each do |qp|
                        qp.guid = qp.object.gsub(".","_")
                        qp.systemCreatedDt = ''
                        qp.id = ''
                    end
                end
                if targetQuotation.QuotationAdditionalFieldsList && targetQuotation.QuotationAdditionalFieldsList.size > 0
                    targetQuotation.QuotationAdditionalFieldsList.each do |qp|
                        qp.guid = qp.object.gsub(".","_")
                        qp.systemCreatedDt = ''
                        qp.id = ''
                    end
                end
                targetQuotation.status = ""
                propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
                targetQuotation.proposalVersion =  propVersion.value.to_s if propVersion && propVersion.value.to_s != ""

                return targetQuotation 
            else ## execute 
                targetColnnedQuotation = srcQuotation.cloneObject  
                quotationProductLst = targetColnnedQuotation.QuotationProductList
                quotationTopUpLst = targetColnnedQuotation.QuotationTopUpList
                quotationPartyLst = targetColnnedQuotation.QuotationPartyList
                quotationWithdrawalLst = targetColnnedQuotation.QuotationWithdrawalList
                imageLst = targetColnnedQuotation.ImageList
                quotationAdditionalFieldsLst = targetColnnedQuotation.QuotationAdditionalFieldsList  
                # copying data again in quotation as these fields are not present in current form
                targetQuotation.productVersion  = srcQuotation.productVersion
                targetQuotation.productTypeCd = srcQuotation.productTypeCd
                targetQuotation.productFamilyCd = srcQuotation.productFamilyCd
                targetQuotation.topupOptionCd = srcQuotation.topupOptionCd
                targetQuotation.regularTopupFl = srcQuotation.regularTopupFl
                targetQuotation.initialTopupFl = srcQuotation.initialTopupFl
                targetQuotation.withdrawalFl = srcQuotation.withdrawalFl
                targetQuotation.solverTypeCd = srcQuotation.solverTypeCd
                targetQuotation.withdrawalRateTypeCd = srcQuotation.withdrawalRateTypeCd

                targetQuotation.childUserId = srcQuotation.childUserId
                targetQuotation.coverTypeCd = srcQuotation.coverTypeCd
                targetQuotation.isEditableQuoRefNumFl = srcQuotation.isEditableQuoRefNumFl
                targetQuotation.uploadFlag = srcQuotation.uploadFlag
                targetQuotation.termTypeCd = srcQuotation.termTypeCd
                targetQuotation.pptermTypeCd = srcQuotation.pptermTypeCd
                targetQuotation.multiplierTypeCd = srcQuotation.multiplierTypeCd
                targetQuotation.termCalculationBasisCd = srcQuotation.termCalculationBasisCd
                targetQuotation.isAgeEditableFl = srcQuotation.isAgeEditableFl

                targetQuotation.quotAddtnlField5 = srcQuotation.quotAddtnlField5
                targetQuotation.quotAddtnlField6 = srcQuotation.quotAddtnlField6
                targetQuotation.quotAddtnlField7 = srcQuotation.quotAddtnlField7
                targetQuotation.quotAddtnlField8 = srcQuotation.quotAddtnlField8
                targetQuotation.quotAddtnlField9 = srcQuotation.quotAddtnlField9
                targetQuotation.quotAddtnlField10 = srcQuotation.quotAddtnlField10
                targetQuotation.payingYears = srcQuotation.payingYears
                targetQuotation.unselectedRiders = srcQuotation.unselectedRiders
                targetQuotation.leadId = srcQuotation.leadId
                targetQuotation.fnaId = srcQuotation.fnaId
                targetQuotation.rpqId = srcQuotation.rpqId
                propVersion = OfflineApplication.find(:first, :conditions=>{:property=>'PROPOSALVERSION'})
                targetQuotation.proposalVersion =  propVersion.value.to_s if propVersion && propVersion.value.to_s != ""

                partyOldNewGuidMapping = Hash.new
                partyGuidMapping = @params['partyGuidMapping'].split('|')
                oldGuids = partyGuidMapping[0].split(',')
                newGuids = partyGuidMapping[1].split(',')
                oldGuids.each_with_index do |oldGuid,index|
                    partyOldNewGuidMapping[oldGuid] = newGuids[index]
                    targetQuotation.unselectedRiders.to_s.gsub!(oldGuid,newGuids[index])
                end
                targetQuotation.persistAll 
                copiedQuotation = Quotation.loadObject(:first,:conditions=>{:object=>targetQuotation.object})
                copiedQuotation.QuotationProductList.each do |quotationProduct|  
                    quotationProduct.removed = "YES"
                end
                quotationProductLst.each do |quotationProduct| 
                    if quotationProduct.insuredPartyRefGuid.to_s != ""
                        quotationProduct.insuredPartyRefGuid = partyOldNewGuidMapping[quotationProduct.insuredPartyRefGuid] 
                    end
                    quotationProduct.guid = quotationProduct.object.gsub(".","_")
                    quotationProduct.systemCreatedDt = Time.now
                    quotationProduct.id = nil
                    if quotationProduct.QuotationProductInvestmentFundList && quotationProduct.QuotationProductInvestmentFundList.size > 0
                        quotationProduct.QuotationProductInvestmentFundList.each do |qpif|
                            qpif.guid = qpif.object.gsub(".","_")
                            qpif.systemCreatedDt = Time.now
                            qpif.id = nil
                        end 
                    end
                    if quotationProduct.QuotationProductExtraList && quotationProduct.QuotationProductExtraList.size > 0
                        quotationProduct.QuotationProductExtraList.each do |qpe|
                            qpe.guid = qpe.object.gsub(".","_")
                            qpe.systemCreatedDt = Time.now
                            qpe.id = nil
                        end 
                    end
                    if quotationProduct.QuotationProductAdditionalList && quotationProduct.QuotationProductAdditionalList.size > 0
                        quotationProduct.QuotationProductAdditionalList.each do |qpe|
                            qpe.guid = qpe.object.gsub(".","_")
                            qpe.systemCreatedDt = ''
                            qpe.id = ''
                        end 
                    end
                    copiedQuotation.addQuotationProduct(quotationProduct)
                end

                quotationPartyLst.each do |quotationParty|
                    if quotationParty.roleCd != 'PRIMARY' && quotationParty.roleCd != 'PROPOSER' && quotationParty.roleCd != 'JOINT'
                        copiedQuotation.addQuotationParty(quotationParty)
                    end
                end
                copiedQuotation.QuotationPartyList.each do |qp|
                    # resetting the object of quotationparty to the one created at the instant of first clone or show
                    qp.object = partyOldNewGuidMapping[qp.guid].gsub("_",".") if partyOldNewGuidMapping[qp.guid].to_s != ''
                    qp.guid = qp.object.gsub(".","_")
                    qp.systemCreatedDt = Time.now
                    qp.id = nil
                end

                quotationTopUpLst.each do |quotationTopUp|
                    quotationTopUp.guid = quotationTopUp.object.gsub(".","_")
                    quotationTopUp.systemCreatedDt = Time.now
                    quotationTopUp.id = nil
                    copiedQuotation.addQuotationTopUp(quotationTopUp)
                end  

                quotationWithdrawalLst.each do |quotationWithdrawal|
                    quotationWithdrawal.guid = quotationWithdrawal.object.gsub(".","_")
                    quotationWithdrawal.systemCreatedDt = Time.now
                    quotationWithdrawal.id = nil
                    copiedQuotation.addQuotationWithdrawal(quotationWithdrawal)
                end

                imageLst.each do |image|
                    copiedQuotation.addImage(image)
                end

                quotationAdditionalFieldsLst.each do |quotationAdditionalFields|
                    quotationAdditionalFields.guid = quotationAdditionalFields.object.gsub(".","_")
                    quotationAdditionalFields.systemCreatedDt = Time.now
                    quotationAdditionalFields.id = nil
                    copiedQuotation.addQuotationAdditionalFields(quotationAdditionalFields)
                end 
                copiedQuotation.status = ""

                return copiedQuotation 
            end
        end

	    def self.initializeQuotationIO(quotation, outputPreferencesDO)
	    	quotationIO = MobiSys::IO::QuotationIO.new
            quotationIO.baseDO = quotation
            quotationIO.outputPreferencesDO = outputPreferencesDO if $rhoconfig[:capture_output_preferences].to_s == "YES"

            if quotationIO.outputPreferencesDO == nil
            	outputPref = OutputPreferences.new
                quotationIO.outputPreferencesDO = defaultOutputPreferences(outputPref)
            end

            quotePlan = MobiSys::QuotationBO.getBaseProduct(quotation)
            
            if quotePlan.product == nil
                product = MobiSys::ProductUtil.getProduct(quotePlan.productSeq)
            else
                product = quotePlan.product
            end  
            #Product.loadObject(:first, :conditions => {{ :name => 'id' } => quotePlan.productSeq})
            quotationIO.baseProduct = product
            MobiSys::QuotationBO.prePremiumOffsetSolver(quotationIO)
            preGenerateIllustration(quotationIO)
            quotationIO.illustrationModel = nil
            MobiSys::ProductBO.loadModel("SIMODEL",quotationIO)
            $quotationIO = MobiSys::ProductBO.callCalculateIllustration(quotationIO)
            postGenerateIllustration($quotationIO)
            return quotationIO
	    end

	    def self.preGenerateIllustration(quotationIO)
	        $apoQuotationIO = nil
	        $apoQuotationIO = MobiSys::APO.execute(quotationIO)  if quotationIO.baseProduct.getFacetFast('APOFINDFACET')
	        topupOptionCd = quotationIO.baseDO.topupOptionCd
	        puts ">>>topupOptionCd in quotation: #{topupOptionCd}"
			#This is commented for time being to run the solver based on model. remove the false condition to run this code.

			#This is implemented To show Annual excess on Preview DPHSS-8072
			basePlan = quotationIO.baseDO.getBaseProduct
			solverModelFacet = $currentProduct.getFacetValue('TARGETFUNDSOLVERFORV8') if $currentProduct
			if solverModelFacet && (topupOptionCd.to_s != "EXCESSWITHOUTPH" || topupOptionCd.to_s != "EXCESSWITHPH")
				MobiSys::Solver.execute(quotationIO, "TARGETFUNDSOLVERFORV8")
		    end		

	        if (topupOptionCd == "TFCALCULATIONWITHOUTPH" or topupOptionCd == "TFCALCULATIONWITHPH" or topupOptionCd == "EXCESSANDTFCALCULATIONWITHPH") && false
	            computedFundValue = 0.0
	            basePlanQuote = quotationIO.baseDO.getBaseProduct
	            if basePlanQuote.productTerm == nil or basePlanQuote.productTerm == ""
	                puts "Error: No product term entered. Evaluation runs for the entire product term."
	                return
	            end  
	            targetFundVal = basePlanQuote.targetFundVal
	            return unless targetFundVal and targetFundVal.to_i != 0
	            targetFundValue = MobiSys::Math.roundDown(targetFundVal,0);
	            targetFundPeriod = basePlanQuote.targetPeriod
	            return unless targetFundPeriod and targetFundPeriod != 0
	            originalProductTerm = basePlanQuote.productTerm
	            targetPeriodRef = basePlanQuote.targetPeriodRefCd
	            if targetPeriodRef
	                if targetPeriodRef == "TARGETAGE"
	                    currentAge = quotationIO.baseDO.getPartyByRole("PRIMARY").age
	                    targetFundPeriod = basePlanQuote.targetPeriod.to_i - currentAge.to_i
	                end  
	            end

	            basePlanQuote.productTerm = targetFundPeriod
	            regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	            unless regularQuotationTopup
	                regularQuotationTopup = QuotationTopUp.new
	                regularQuotationTopup.topUpAmount = 0
	                regularQuotationTopup.topUpTypeCd = "REGULARTOPUP"
	                quotationIO.baseDO.addQuotationTopUp regularQuotationTopup
	            end

	            orignalQuotation = quotationIO.baseDO
	            quotationIO.baseDO = orignalQuotation.cloneObject

	            #Ready to start calculations now.
	            #puts ">>>starting calculations with targetFundVal: #{targetFundVal}"          
	            regularExcess = regularQuotationTopup.topUpAmount
	            computedFundValue = 0.0
	            iterations = 0
	            requiredTopUpAmt = regularQuotationTopup.topUpAmount;
	            regularQuotationTopup.topUpPeriod = targetFundPeriod
	            puts"requiredTopUp:" + regularQuotationTopup.topUpAmount.to_s + "requiredTopUpAmt : "  + requiredTopUpAmt.to_s
	            # ProductBO productBO = (ProductBO)SymbiosysApplicationContext.getInstance().getApplicationContextObject("productBO",quotationIO.getCompanyDO().getCompanyCd());
	            # productBO.setDO(quotationIO.getBaseProduct());
	            # //productBO.loadModel(facetId, quotationIO);
	            # regularQuotationTopup.setTopUpPeriod(targetFundPeriod);
	            # System.out.println("requiredTopUp:" + regularQuotationTopup.getTopUpAmount() + "requiredTopUpAmt : "  + requiredTopUpAmt);
	            # MobiSys::ProductBO..loadModel("TARGETFUNDVALUECALC", quotationIO);
	            # # quotationIO.resetModelCalculation();
	            # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 

	            solveForTarget(quotationIO, regularExcess)
	            # PolicyDO policyDO = quotationIO.getPolicyDO();
	            computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	            puts"computedFundValue : " + computedFundValue.to_s

	            isComputedFundValueGreater=false;
	            if(computedFundValue > targetFundValue)
	                isComputedFundValueGreater=true;
	            end
	            puts"targetFundValue : " + targetFundValue.to_s

	            # noofpayingyears = targetFundPeriod;

	            # 11-13-2014
	            if(!isComputedFundValueGreater)
	                mintopup=0.0;
	                maxtopup=0.0;
	                if "PHP" == basePlanQuote.currencyCd
	                    maxtopup=500000;
	                    incrementBy = 500000;
	                elsif "USD"== basePlanQuote.currencyCd
	                    maxtopup=50000;
	                    incrementBy = 50000;
	                end
	                requiredAvgTopUp=0.0;
	                checkedAvgTopUp =0.0;
	                loop do 
	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	                    regularQuotationTopup.topUpAmount = maxtopup
	                    # //    productBO.loadModel(facetId, quotationIO);
	                    # quotationIO.resetModelCalculation();
	                    # quotationIO =  MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, maxtopup)

	                    computedFundValue =  MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    if(computedFundValue == 0)
	                        break;
	                    end

	                    if(computedFundValue < targetFundValue)
	                        mintopup=maxtopup;
	                        maxtopup=maxtopup+incrementBy;
	                    end
	                    puts"computedFundValue : #{computedFundValue}"
	                    break if !(computedFundValue <= targetFundValue);
	                end
	                puts"Got range value between : #{mintopup}  and #{maxtopup}"
	                loop do 
	                    if((("TFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd) || 
	                        ("EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd)) && ("PHP" == basePlanQuote.currencyCd))
	                        incrementBy=100;
	                    else
	                        incrementBy=1;
	                    end

	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

	                    requiredAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;

	                    regularQuotationTopup.topUpAmount = requiredAvgTopUp
	                    puts"requiredTopUp: " + regularQuotationTopup.topUpAmount.to_s

	                    # quotationIO.resetModelCalculation();
	                    # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, requiredAvgTopUp)

	                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    puts"computedFundValue " + computedFundValue.to_s
	                    if(computedFundValue == 0)
	                        break;
	                    end

	                    if(computedFundValue < targetFundValue)
	                        mintopup=requiredAvgTopUp;
	                    else
	                        maxtopup=requiredAvgTopUp;
	                    end
	                    checkedAvgTopUp = MobiSys::Math.roundUp(((mintopup+maxtopup)/2)/ incrementBy, 0) * incrementBy;
	                    puts"computedFundValue : #{computedFundValue.inspect}"
	                    break if !((checkedAvgTopUp < maxtopup) || (computedFundValue < targetFundValue));
	                end

	                regularQuotationTopup.topUpAmount = MobiSys::Math.roundUp(requiredAvgTopUp,0);

	            elsif (isComputedFundValueGreater && "EXCESSANDTFCALCULATIONWITHPH" == quotationIO.baseDO.topupOptionCd) 
	                noofpayingyears = targetFundPeriod;
	                decrementBy = 1;

	                loop do 
	                    noofpayingyears = noofpayingyears - decrementBy
	                    # //computedFundValue = requiredTopUp * 50 * 100;//TARGETFUNDVALUECALC model evaluation
	                    # //invoke the fund value calculation model to compute the fund value
	                    # //regularQuotationTopup.setTopUpPeriod(noofpayingyears);

	                    quotationIO.baseDO = orignalQuotation.cloneObject
	                    regularQuotationTopup = quotationIO.baseDO.getRegularTopup

	                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	                    regularQuotationTopup.topUpAmount = requiredTopUpAmt
	                    puts"no of paying years:==3rd" + noofpayingyears.to_s
	                    quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	                    # //      productBO.loadModel(facetId, quotationIO);
	                    # quotationIO.resetModelCalculation();
	                    # quotationIO = MobiSys::ProductBO.calculateIllustration(quotationIO); 
	                    # policyDO = quotationIO.getPolicyDO();
	                    solveForTarget(quotationIO, requiredTopUpAmt)


	                    # computedFundValue = CommonUtil.getRoundedDownDouble(policyDO.getBasePlan().getTargetFundVal(),0);
	                    computedFundValue = MobiSys::Math.roundDown(quotationIO.baseDO.getBasePlan.targetFundVal,0);
	                    puts"computedFundValue  : " + computedFundValue.to_s
	                    puts"targetFundValue   : " + targetFundValue.to_s
	                    if(computedFundValue == 0)
	                        break;      
	                    end      
	                    break if !( computedFundValue >= targetFundValue);
	                end
	                noofpayingyears = noofpayingyears + decrementBy
	                regularQuotationTopup.topUpPeriod = noofpayingyears
	                quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears
	            end
	            puts ">>>completed all loops: iterations: #{iterations} regularExcess: #{regularExcess}"
	            basePlanQuote.productTerm = originalProductTerm
	            orignalQuotation.getBasePlan.payingYears = quotationIO.baseDO.getBasePlan.payingYears

	            orignalQuotation.getRegularTopup.topUpAmount = quotationIO.baseDO.getRegularTopup.topUpAmount
	            quotationIO.baseDO = orignalQuotation

	            regularQuotationTopup = quotationIO.baseDO.getRegularTopup
	            # regularQuotationTopup.topUpAmount = regularExcess
	            # quotationIO.baseDO.getBasePlan.payingYears = noofpayingyears

	            quotationIO.illustrationModel = nil
	        end  
	        return quotationIO
	    end

	    def self.copyQuotationPartyToPolicyPartyAttributes(quotation, policy)
        	# TODO new supplementary case need to handle in policy
        	quotation.QuotationPartyList.each do |quoteParty|
        		if quotation.proposerLASame.to_s == "YES"
        			if quotation.proposerLACopyCd.to_s == "PROPOSERCOPIEDFROMLA"
        				if quoteParty.roleCd.to_s == "PROPOSER"
        					next
        				end
        			elsif quotation.proposerLACopyCd.to_s == "LACOPIEDFROMPROPOSER" || quotation.proposerLACopyCd.to_s == ""
        				if quoteParty.roleCd.to_s == "PRIMARY"
        					next
        				end
        			end
        		end
        		# just copy party related fields
        		policy.PartyList.each do |party|
        			if (quoteParty.roleCd.to_s == party.roleCd.to_s || (party.roleCd.to_s == "PROPCUMINS" && (quoteParty.roleCd.to_s == "PROPOSER" || quoteParty.roleCd.to_s == "PRIMARY")))
						fieldsToExcludeArr = ["guid", "id", "versionID","title","maritalStatus"]
        				party = MobiSys::CommonUtil.copyFields(quoteParty, party, fieldsToExcludeArr)
						party.quotationPartyGuid = quoteParty.guid
						party.firstName1 = quoteParty.firstname
						party.lastName1 = quoteParty.lastname
						party.middleName1 = quoteParty.middlename
						party.firstName2 = quoteParty.firstname2
						party.lastName2 = quoteParty.lastname2
						party.middleName2 = quoteParty.middlename2
						party.corporateName1 = quoteParty.corporateName
						party.titleCd = quoteParty.title if quoteParty.title.to_s != ''
						party.nonResidentFl = quoteParty.nsap
						party.occupationClass = quoteParty.occupationCd
						party.educationLevelCd = quoteParty.educationCd

						party.copyFromAddr3 = quoteParty.educationCd
						party.copyFromAddr2 = quoteParty.residency
						
						party.birthDt = quoteParty.dob
						party.extensionName1 = quoteParty.extensionName
						party.citizenshipCd = quoteParty.nationality
						party.otherReligion = quoteParty.officeIsdCode

						party.relationCd = "INSUR" if quotation.proposerLASame.to_s == "COPYFROMINSURED"


						# copy employment related fields
						if party.PartyEmploymentList.to_s != "" && party.PartyEmploymentList.size > 0
							partyEmploymentDO = party.PartyEmploymentList[0]
							if partyEmploymentDO.to_s != ""
								partyEmploymentDO.natureOfDuty = quoteParty.natureOfDuty if quoteParty.natureOfDuty.to_s != ''
								partyEmploymentDO.industryCd = quoteParty.industryCd #if quoteParty.industryCd.to_s != ''
								partyEmploymentDO.occupationCd = quoteParty.occupationCd
								if quoteParty.monthlyIncome.to_s != "" && quoteParty.monthlyIncome > 0
									partyEmploymentDO.annualIncome = quoteParty.monthlyIncome
								else
									partyEmploymentDO.annualIncome = quoteParty.annualIncome if quoteParty.annualIncome.to_s != ''
								end
							end
						end

						# copy contact related fields
						partyContactDO = party.getPartyContact("MOBILE")
						if partyContactDO.to_s != ""
							partyContactDO.countryCd = quoteParty.isdCode if quoteParty.isdCode.to_s != ''
							partyContactDO.contactNum = quoteParty.contactNum if quoteParty.contactNum.to_s != ''
							partyContactDO.stdCode = quoteParty.stdCode if quoteParty.stdCode.to_s != ''
						end

						# copy email address related fields
						partyEmailDO = party.getPartyEmail
						if partyEmailDO.to_s != ""
							partyEmailDO.emailAddress = quoteParty.emailAddress if quoteParty.emailAddress.to_s != ""
						end

						# copy party identity related fields
						if quoteParty.idType.to_s != ""
							partyIdentityDO = party.getPartyIdentity(quoteParty.idType)
							if partyIdentityDO.to_s != ""
								partyIdentityDO.identityNum = quoteParty.idNumber
							end
						end

						# copy party address related fields
						quoteParty.QuotationPartyAddressList.each do |quotationPartyAddressDO|
							party.PartyAddressList.each do |partyAddressDO|

								["RESIDENTIAL","PERMANENT","OFFICE"].each do |addressType|
			                      partyAddress = party.getPartyAddress(addressType.to_s, true)
			                      partyAddress.removed = "YES" if MobiSys::PolicyBO.checkForEmptyFields(partyAddress)
			                    end
			                    
								if quotationPartyAddressDO.addressTypeCd.to_s != "" && partyAddressDO.addressTypeCd.to_s != "" && quotationPartyAddressDO.addressTypeCd.to_s == partyAddressDO.addressTypeCd.to_s
									fieldsToExcludeArr = ["addressLine1Lang1","addressLine2Lang1","addressLine3Lang1","pinCode","guid", "id", "versionID"]
									partyAddressDO = MobiSys::CommonUtil.copyFields(quotationPartyAddressDO, partyAddressDO, fieldsToExcludeArr)
								end
							end
						end
        				break
        			end
        		end # end of policy party looup
        	end # end of QuotaionParty looup        	
        end

        def self.copyQuotationProductToPolicyProductAttributes(quotation, policy, quotationPartyAndPolicyPartyGuidMap)
        	quoteBasePlan = quotation.getBasePlan
        	policyProductDOList = []
        	policy.PolicyProductList.each do |ppd|
			    ppd.removed = "YES"
			end
			policy.persistAll
        	quotation.QuotationProductList.each do |quotationProductDO|
        		# create new product do and copy product related fields
        		policyProductDO = PolicyProduct.new
        		fieldsToExcludeArr = ["guid", "id", "versionID"]
        		policyProductDO = MobiSys::CommonUtil.copyFields(quotationProductDO, policyProductDO, fieldsToExcludeArr)
        		# store reference of quotation product guid in policyproduct since required during comparison later.
        		policyProductDO.holderRefGuid = quotationProductDO.guid
        		if quotationProductDO.pdfPeriod.to_s == ""
        			policyProductDO.pdfPeriod = 0
        		else
        			policyProductDO.pdfPeriod = quotationProductDO.pdfPeriod
        		end
        		if policyProductDO.annualIncome.to_s == "" && quoteBasePlan.annualIncome.to_s != ""
					policyProductDO.annualIncome = quoteBasePlan.annualIncome
				end
				policyProductDO.monthlyIncome = quotationProductDO.monthlyIncome
				if policyProductDO.monthlyIncome.to_s == "" && quoteBasePlan.monthlyIncome.to_s != ""
					policyProductDO.monthlyIncome = quoteBasePlan.monthlyIncome
				end

				policyProductDO.productTerm = quotationProductDO.productTerm
				if (policyProductDO.productTerm.to_s == "" || policyProductDO.productTerm.to_i == 0) && quoteBasePlan.productTerm.to_s != ""
					policyProductDO.productTerm = quoteBasePlan.productTerm
				end

				if policyProductDO.partyRoleCd.to_s == ""
					policyProductDO.partyRoleCd = "PRIMARY"
				end
				if quotationProductDO.pdfFrequencyVal.to_s == ""
        			policyProductDO.pdfFrequencyVal = 0
        		else
        			policyProductDO.pdfFrequencyVal = quotationProductDO.pdfFrequencyVal
        		end

        		# add wop flag
        		policyProductDO.isWOP = isWOP(policyProductDO, policy)

        		# create PolicyProductInsured
        		prid = PolicyProductInsured.new
        		prid.insuredSequenceTypeCd = policyProductDO.partyRoleCd
        		prid.roleCd = policyProductDO.partyRoleCd
        		roleParty = nil
        		if quotationProductDO.insuredPartyRefGuid.to_s != ""
        			quotation.proposerLASame = "YES" if quotation.proposerLASame.to_s == "COPYFROMINSURED"
        			# if primary and proposer are different and rider taken by proposer,after changing into primary proposer same case then need to set proper party guid on rider.
        			if quotation.proposerLASame.to_s == "YES" && policy.getPartyDOByGuid(quotationProductDO.insuredPartyRefGuid).to_s == ""
        				roleParty = policy.getPartyByRole("PROPCUMINS")
        				if roleParty.to_s != ""
        					prid.refGuid = roleParty.guid
        					policyProductDO.insuredPartyRefGuid = roleParty.guid
        				end
        			else
        				# prid.refGuid = quotationProductDO.insuredPartyRefGuid
        				# policyProductDO.insuredPartyRefGuid = quotationProductDO.insuredPartyRefGuid
        				# roleParty = policy.getPartyDOByGuid(quotationProductDO.insuredPartyRefGuid)
        				prid.refGuid = quotationPartyAndPolicyPartyGuidMap[quotationProductDO.insuredPartyRefGuid]
        				policyProductDO.insuredPartyRefGuid = quotationPartyAndPolicyPartyGuidMap[quotationProductDO.insuredPartyRefGuid]
        				roleParty = policy.getPartyDOByGuid(quotationProductDO.insuredPartyRefGuid)
        			end
        			# setting Combined Entry Age For Rider
        			if roleParty.to_s != ""
        				policyProductDO.combinedEntryAge = roleParty.age
        			end
        		else
        			roleParty = policy.getPartyByRole(policyProductDO.partyRoleCd)
        			if roleParty.to_s != ""
    					prid.refGuid = roleParty.guid
    					policyProductDO.insuredPartyRefGuid = roleParty.guid
    					# setting Combined Entry Age For Rider
    					policyProductDO.combinedEntryAge = roleParty.age
    				end
        		end
        		# setting combined Entry Age back to persist 
        		quotationProductDO.combinedEntryAge = policyProductDO.combinedEntryAge
        		policyProductDO.addPolicyProductInsured(prid)

        		quotationProductDO.QuotationProductExtraList.each do |quotationProductExtraDO|
                	policyProductExtraDO = PolicyProductExtra.new
        			fieldsToExcludeArr = ["guid", "id", "versionID"]
                	policyProductExtraDO = MobiSys::CommonUtil.copyFields(quotationProductExtraDO, policyProductExtraDO, fieldsToExcludeArr)
        			policyProductDO.addPolicyProductExtra(policyProductExtraDO)
                end

                quotationProductDO.QuotationProductAdditionalList.each do |quotationProductAdditionalDO|
                	policyProductAdditionalDO = PolicyProductAdditional.new
        			fieldsToExcludeArr = ["guid", "id", "versionID"]
                	policyProductAdditionalDO = MobiSys::CommonUtil.copyFields(quotationProductAdditionalDO, policyProductAdditionalDO, fieldsToExcludeArr)
        			policyProductDO.addPolicyProductAdditional(policyProductAdditionalDO)
                end

                if policyProductDO.productTypeCd.to_s == "PLAN"
                	policy.baseProductSeq = policyProductDO.productSeq
	                quoteBasePlan.QuotationProductInvestmentFundList.each do |qpif|
	                	if qpif.allocationPerc.to_s != "" && qpif.topupAllocationPerc.to_s != ""
		                	ppif = PolicyProductInvestmentFund.new
		        			fieldsToExcludeArr = ["guid", "id", "versionID"]
		                	ppif = MobiSys::CommonUtil.copyFields(qpif, ppif, fieldsToExcludeArr)
		        			policyProductDO.addPolicyProductInvestmentFund(ppif)
		        		end
	                end
	            end
	            policyProductDOList.push(policyProductDO)
        	end
        	policy.setPolicyProductList(policyProductDOList)
        end

        def self.leadEmailOtpSent(quotation)
            lead = Lead.loadObject(:first, :conditions=>{:leadId=>quotation.leadId}) if quotation && quotation.leadId != nil
            if lead && lead.statusCd == "COMPLETED" && lead.uploadedFl.to_s != "EMAILANDOTPSENT" && lead.leadSourceOther.to_s == ""
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    begin
                        leadParty = lead.getLeadParty
                        advisorEmail = leadParty.getPartyEmail.emailAddress if leadParty.getPartyEmail
                        userId = $userId.to_s
                        advisorPhone = leadParty.getPartyContact("PHILIPPINESNUM").contactNum if leadParty.getPartyContact("PHILIPPINESNUM")
                        partyId = lead.leadId
                        syncEntities = Hash.new
                        syncEntities[Lead.onlineClassName] = ::JSON.generate([{Lead.onlineClassName => [lead.hashForSync]}.to_json])
                        syncEntities[Party.onlineClassName] = ::JSON.generate([{Party.onlineClassName => [leadParty.hashForSync]}.to_json])
                        begin
                            json = ::JSON.generate(syncEntities)
                        rescue StandardError => se
                            puts "Error while generating JSON of request data" + se.to_s
                        end
                        # leadDetailsHash = { emailId: advisorEmail, userId: userId, mobileNumber: advisorPhone, partyId: partyId, firstName: firstName}
                        # result = doJSONPost('/leadSendEmailOtp.run', syncEntities)
                        clazz = Class.new do
                            include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        result = obj.doJSONPost('/leadSendEmailOtp.run', json)
                        if result.to_s != ""
                            responseHash = Rho::JSON.parse(result.to_s)
                        end          
                    rescue StandardError => se
                        puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    end
                end
            end
            return
        end

        def self.refreshEapp(quotation)
        	if quotation
        		existingPolicyDO = Policy.loadObject(:first, :conditions => {:quotationRefGuid => quotation.guid })
        		if existingPolicyDO
        			# clone policy record so that company project retain some existing policy records fields in postCopyQuotationToPolicyAttributes
        			clonePolicyDO = existingPolicyDO.cloneObject
        			# just copy only quotation related fields and retain policy fields 
					currPolicyDO = copyQuotationToPolicyAttributes(quotation,existingPolicyDO);
					postCopyQuotationToPolicyAttributes(quotation,currPolicyDO,clonePolicyDO);
        			# save that merge policy do
        			currPolicyDO.versionID = existingPolicyDO.versionID
        			currPolicyDO.step = 0
        			currPolicyDO.guid = existingPolicyDO.guid
        			currPolicyDO.statusCd = "PENDING"
        			currPolicyDO.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
				      policyAdditionalFieldsDO.update_attributes(:policyField31 => "FaceToFace") if policyAdditionalFieldsDO.additionalTypeCd.to_s == "000"
				    end

        			currPolicyDO.persistAll

					policyPortfolioModelCode = existingPolicyDO.PolicyProductList
					           			  .find { |ppd| 
					                        ppd.productTypeCd == "PLAN"
					                      }&.portfolioModelCd

					quotationPortfolioModelCode = quotation.QuotationProductList
					           			  .find { |qpd| 
					                        qpd.productTypeCd == "PLAN"
					                      }&.portfolioModelCd

				    # addUserActivity in refreshEapp
                    MobiSys::CommonUtil.addUserActivity('REFRESHEAPP_OFFLINE',"quotationRefNum => #{currPolicyDO.quotationRefNum},proposalNum => #{currPolicyDO.proposalNum},quotationGuid => #{currPolicyDO.guid},quotationfnaId => #{currPolicyDO.fnaId},policyPortfolioModelCode => #{policyPortfolioModelCode},quotationPortfolioModelCode => #{quotationPortfolioModelCode} ", 'POLICY', currPolicyDO.proposalNum)
        			return currPolicyDO
        		end
        	end
        end

        def self.copyQuotationExtra(quotation, policy)
        	# Copy topup related fields as well .. Create new list and copy and reset all.
        	quotation.QuotationTopUpList.each do |quotationTopUpDO|
        		policyTopUpDO = PolicyTopUp.new
        		fieldsToExcludeArr = ["guid", "id", "versionID"]
        		policyTopUpDO = MobiSys::CommonUtil.copyFields(quotationTopUpDO, policyTopUpDO, fieldsToExcludeArr)
        		policy.addPolicyTopUp(policyTopUpDO)
        	end
        	# Copy withdrawal related fields as well .. Create new list and copy and reset all.
        	policyWithdrawalList = []
        	quotation.QuotationWithdrawalList.each do |quotationWithdrawalDO|
        		policyWithdrawalList.push(quotationWithdrawalDO)
        	end
        	policy.policyWithdrawalList = policyWithdrawalList
        end

        def self.copyAdditionalFields(quotation, policy)
        	# copy quotation additional field into 000 type of policy additional fields and reatin other fields
        	if quotation.getQuotationAdditionalFieldsDO.to_s != ""
        		quotation.getQuotationAdditionalFieldsDO.each do |quotationAdditionalFieldsDO|
        			policy.PolicyAdditionalFieldsList.each do |policyAdditionalFieldsDO|
        				if policyAdditionalFieldsDO.additionalTypeCd.to_s == "000"
				        	fieldsToExcludeArr = ["guid", "id", "versionID"]
		        			policyWithdrawalDO = MobiSys::CommonUtil.copyFields(quotationAdditionalFieldsDO, policyAdditionalFieldsDO, fieldsToExcludeArr)
				        	break
			        	end
			        end
        		end
        	end
        end

        def self.fnaDataSync(quotation)
            fnaRequest = FNARequest.loadObject(:first, :conditions=>{:fnaNum=>quotation.fnaId}) if quotation &&quotation.fnaId.to_s != ""
            if fnaRequest 
                has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
                if has_network
                    begin
                        leadRPQ = LeadRPQ.loadObject(:first,:conditions => {{:name=>'rpqId'}=>fnaRequest.addtnField1Str}) if fnaRequest && fnaRequest.addtnField1Str.to_s != ""
                        syncEntities = Hash.new
                        syncEntities[FNARequest.onlineClassName] = ::JSON.generate([{FNARequest.onlineClassName => [fnaRequest.hashForSync]}.to_json])
                        syncEntities[LeadRPQ.onlineClassName] = ::JSON.generate([{LeadRPQ.onlineClassName => [leadRPQ.hashForSync]}.to_json]) if leadRPQ
                        begin
                            json = ::JSON.generate(syncEntities)
                        rescue StandardError => se
                            puts "Error while generating JSON of request data" + se.to_s
                        end
                        
                        clazz = Class.new do
                            include MobiSys::BrowserHelper 
                        end
                        obj = clazz.new
                        result = obj.doJSONPost('/fnaSyncData.run', json)
                        if result.to_s != ""
                        	resultsHash = Rho::JSON.parse(result)
                        	resultsHash.each do |key,value|
			                    next if value.to_s == '' || value.to_s == '[]' || value.empty?# || key.to_s != className
			                    entities = Rho::JSON.parse(value)
	                    	   	begin
			                        db = ::Rho::RHO.get_db_partitions()['local']
			                        db.start_transaction
			                        entities.each do |mainEntity|
			                            next if mainEntity.to_s == ''
			                            className = key.split('.').last# Remove trailing "DO" if it exists
										classNameWithoutDO = className.sub(/DO$/, '')
	                                    exp = classNameWithoutDO + ".loadObject(:first,:conditions=>{:guid=>'" + mainEntity['guid'].to_s + "'})"
		                                storedEntity = eval(exp)
	                                    entityObject = MobiSys::MobiSysEntitySchema.from_hash("#{classNameWithoutDO}",mainEntity)
					                    if storedEntity and entityObject.versionID == '-1'
			                                storedEntity.delete
			                            elsif storedEntity
			                                storedEntity.merge(entityObject)
			                                storedEntity.persist('fromSync')
			                                if storedEntity.respond_to?('afterSync'.to_sym)
			                                    storedEntity.afterSync
			                                end
			                            else
			                                entityObject.persist('fromSync')
			                                if entityObject.respond_to?('afterSync'.to_sym)
			                                    entityObject.afterSync
			                                end
			                            end
			                        end
			                        db.commit
			                    rescue StandardError => se
			                        db.rollback
			                        RhoLog.error('Error while syncing entities: ', se.to_s)
			                    end
		                    end
                        end         
                    rescue StandardError => se
                        puts "Exception in doJSONPost: #{se}\n#{se.backtrace}"
                    end
                end
            end
            return
        end

        #Method to generate HTML source for online PDF generation based on offline HTML
	    def self.generateOutputHTML
	     	$showPdf = true
            commonShowBenefitTable()
            $showPdf = nil	        
	        filehtmlArray = Array.new
	        returnHash = {}
	        generateHTMLfor = "pdf"
	        generateHTMLfor = "email" if (@params and @params['emailRequestObj'].to_s != "") or $quotationIO.emailRequestDO.to_s != ""
	        $quotationIO.htmlContent.each do |htmlContent|
	            if !htmlContent.empty?
	                filehtml = ""
	                filehtml << "<!DOCTYPE html>"
	                filehtml << "<html lang=\"en\">"
	                filehtml << "<head>"
	                filehtml << "<meta charset=\"utf-8\">"
	                filehtml << "</head>"
	                filehtml << "<body>"

	                totalPages = htmlContent.size
	                skipPageNumber=0;
	                totalSkipNumber = 0;
	                htmlContent.each_pair do |pageNumber, page|
	                    if(page["content"].include? "$SKIPPAGENUMBER$")
	                        totalSkipNumber = totalSkipNumber - 1;  
	                    end
	                end
	                htmlContent.each_pair do |pageNumber, page|
	                    content = page["content"]
	                    if(page["content"].include? "$ZEROMARGIN$")
	                        content.gsub!("$ZEROMARGIN$", "")
	                        filehtml  << "<div style=\"margin:0px !important;padding:0px !important;\">"
	                    else
	                        filehtml  << "<div class=\"bodyDiv\">"
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

	                # data = filehtml.scan(/"\/public\S*[js|css|jpg|png]"/)
	                # data.each do |entry|
	                #     newEntry = entry.gsub('"','')
	                #     @absolutePath = "#{Rho::RhoApplication.get_base_app_path()}#{newEntry}"
	                #     FileUtils.cp(@absolutePath, "#{outputFolder}#{File::SEPARATOR}")
	                # end
	                filehtml.gsub!('/public/jquery/','')
	                filehtml.gsub!('/public/js/RGraph/','')
	                filehtml.gsub!('/public/js/','')
	                filehtml.gsub!('/public/images/SalesIllustration/','')
	                filehtml.gsub!('/public/images/outputimages/','')
	                filehtml.gsub!('/public/css/','')
	                filehtmlArray.push(filehtml)
	            end
	        end
	        begin
	            syncEntities = {}
	            filehtmlArray.each_with_index do |filehtml, index|
	                syncEntities["html#{index+1}"] = filehtml
	            end
	            syncEntities["htmlCount"] = filehtmlArray.size.to_s
	            syncEntities["graphJSON"] = $quotationIO.graphJSON

	            $quotationIO.baseDO.quoteStatusCd = 'ACCEPTED' if $quotationIO.baseDO.quoteStatusCd == 'SYNCDONE'
	            quotation = Quotation.loadObject(:first, :conditions => {:object => $quotationIO.baseDO.object})
	            quotation.userId = MobiSys::Encryption.encryptContent($userId) if $userId
	            syncEntities[Quotation.onlineClassName] = ::JSON.generate([{Quotation.onlineClassName => [quotation.hashForSync]}.to_json])
	            
	            jsonFileSuffix = ""
	            if $quotationIO.baseDO.quoteStatusCd == 'ACCEPTED' && $rhoconfig[:htmlGenerationOnAcceptQuotation]
	                jsonFileSuffix = "ACCEPT"
	                if $rhoconfig[:offlineOutputGeneration]
	                    fileName = "Quotation_#{$quotationIO.baseDO.quotationRefNum.to_s}_ACCEPT.json"
	                    filePath = Rho::RhoFile.join(Rho::RhoApplication.userFolder, "#{fileName}")
	                    if File.exist?(filePath)
	                        encryptedContent = File.read(filePath)
	                        jsonContent = MobiSys::Encryption.decryptAndDecodeContent(encryptedContent)
	                        jsonObjects = Rho::JSON.parse(jsonContent)
	                        htmlHash = {}
	                        htmlCount = jsonObjects["htmlCount"].to_i
	                        for i in 1..htmlCount
	                            htmlHash["html#{i}"] = jsonObjects["html#{i}"]
	                        end
	                        otherDetailsHM = {}
	                        otherDetailsHM["html#{1}"] = htmlHash.to_json
	                        otherDetailsHM["graphJSON#{1}"] = jsonObjects["graphJSON"]
	                        otherDetailsHM["entityName#{1}"] = $quotationIO.baseDO.class.name.to_s
	                        otherDetailsHM["entityNum#{1}"] = $quotationIO.baseDO.quotationRefNum.to_s
	                        otherDetailsHM["entityGuid#{1}"] = $quotationIO.baseDO.guid.to_s
	                        otherDetailsHM["htmlCount#{1}"] = jsonObjects["htmlCount"]
	                        otherDetailsHM["accept#{1}"] = "ACCEPT"
	                        syncEntities["otherDetails"] = ::JSON.generate(otherDetailsHM) if !otherDetailsHM.empty?
	                    end
	                end
	            end
	            if (@params and @params['outputPrefObj'].to_s != "") or $quotationIO.outputPreferencesDO.to_s != ""
	            	if $quotationIO.outputPreferencesDO.to_s != ""
	            		outputPreferencesDO = $quotationIO.outputPreferencesDO
	            	else
	                	outputPreferencesDO = OutputPreferences.loadObject(:first,:conditions=>{:object => @params['outputPrefObj']},:loadChild=>false)
	                end
	                if outputPreferencesDO
	                    syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
	                end
	            else
	                outputPreferencesDO = OutputPreferences.new
	                outputPreferencesDO = defaultOutputPreferences(outputPreferencesDO)
	                outputPreferencesDO.persistAll
	                syncEntities[OutputPreferences.onlineClassName] = ::JSON.generate([{OutputPreferences.onlineClassName => [outputPreferencesDO.hashForSync]}.to_json]) 
	            end
	            if generateHTMLfor == "email"
	            	if $quotationIO.emailRequestDO.to_s != ""
	            		emailRequestDO = $quotationIO.emailRequestDO
	            	else
	                	emailRequestDO = EmailRequest.loadObject(:first,:conditions=>{:object => @params['emailRequestObj']},:loadChild=>false)
	            	end
	                if emailRequestDO
	                	jsonFileSuffix = emailRequestDO.outputPrefEntityGuid
	                    syncEntities[EmailRequest.onlineClassName] = ::JSON.generate([{EmailRequest.onlineClassName => [emailRequestDO.hashForSync]}.to_json])                   
	                end
	            end

	            signaturecontainer = SignatureContainer.loadObject(:first,
	                                            :conditions => {
	                                            :entityGuid => $quotationIO.baseDO.guid
	                                            }
	                                        )
	            if signaturecontainer
	                tempList = []
	                    signaturecontainer.ServiceSignatureList.each do |ss|
	                        tempList.push ss.hashForSync
	                    end
	                syncEntities[ServiceSignature.onlineClassName] = ::JSON.generate([{ServiceSignature.onlineClassName => tempList.flatten}.to_json])
	            end
	            if $CreateOutputFiles == true && jsonFileSuffix.to_s != ""
	                jsonFileName= Rho::RhoApplication.userFolder + File::SEPARATOR + "Quotation_#{$quotationIO.baseDO.quotationRefNum.gsub('/','')}_#{jsonFileSuffix}.json"
	                file = File.open(jsonFileName,'w+b')
	                encryptedContent = MobiSys::Encryption.encryptAndEncodeContent(syncEntities.to_json)
	                file.write(encryptedContent)
	                file.close
	                returnHash['success'] = true
	            elsif !$CreateOutputFiles
	                clazz = Class.new do
	                    include MobiSys::BrowserHelper 
	                end
	                obj = clazz.new

	                if generateHTMLfor == "pdf"
	                    response = obj.doJSONPost('/GenerateIllustrationPDF.run', ::JSON.generate(syncEntities))
	                    resultsHash = Rho::JSON.parse(response)
	                    fileName = resultsHash['pdfFile']
	                    if resultsHash[Quotation.onlineClassName]
	                        quotation_hash = Rho::JSON.parse(resultsHash[Quotation.onlineClassName])[0]
	                        existingQuotation = Quotation.loadObject(:first, conditions: { object: $quotationIO.baseDO.object })
	                        quotation = MobiSys::MobiSysEntitySchema.from_hash('Quotation', quotation_hash)
	                        existingQuotation.merge(quotation)
	                        existingQuotation.persistAll
	                    end

	                    if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')

		                    Dir.mkdir Rho::RhoApplication.get_blob_folder unless Dir.exist? Rho::RhoApplication.get_blob_folder
		                    downloadFolder = File.join(Rho::RhoApplication.get_blob_folder,'../downloads')
		                    Dir.mkdir downloadFolder unless Dir.exist? downloadFolder
		                    filePath = File.join(downloadFolder, fileName)
		                    File.delete(filePath) if File::exist?(filePath)

		                    decFCont = Base64.strict_decode64(resultsHash['PDFCONTENT'])
		                    File.open(filePath, 'wb') { |file| file.write(decFCont) }
		                    System.open_url(filePath)
		                 else
		                 	returnHash['PDFCONTENT'] = resultsHash['PDFCONTENT']
		                 end

	                    # url = Application.getValue('online_server_url').value + "/GetIllustrationPDF.run"
	                    # Rho::AsyncHttp.download_file(
	                    #   :url => url,
	                    #   :filename => filePath,
	                    #   :headers => {"username"=>$userId,"password"=>$userPassword,"filename" => fileName},
	                    #   :callback => '/app/Quotation/quotationPdfdownload',
	                    #   :callback_param => "filePath=#{filePath}&quotationObject=#{$quotationIO.baseDO.object}",
	                    #   :ssl_verify_peer => $ssl_verify_peer)
	                else
	                    response = obj.doJSONPost('/SendEmailRequest.run', ::JSON.generate(syncEntities))
	                    if response != ""
	                        emailRequestDO.afterSync if generateHTMLfor == "email"
	                        resultsHash = Rho::JSON.parse(response)
                        	resultsHash.each do |key,value|
			                    next if value.to_s == '' || value.to_s == '[]' || value.empty?# || key.to_s != className
			                    entities = Rho::JSON.parse(value)
	                    	   	begin
			                        db = ::Rho::RHO.get_db_partitions()['local']
			                        db.start_transaction
			                        entities.each do |mainEntity|
			                            next if mainEntity.to_s == ''
			                            className = key.split('.').last# Remove trailing "DO" if it exists
										classNameWithoutDO = className.sub(/DO$/, '')
										dataGuid = nil
										mainEntity.each do |key,value|
											 data = JSON.parse(value)
											 data.each do |datakey|
												 exp = classNameWithoutDO + ".loadObject(:first,:conditions=>{:guid=>'" + datakey['guid']+ "'})"         
				                                storedEntity = eval(exp)
			                                    entityObject = MobiSys::MobiSysEntitySchema.from_hash("#{classNameWithoutDO}",datakey)
							                    if storedEntity and entityObject.versionID == '-1'
					                                storedEntity.delete
					                            elsif storedEntity
					                                storedEntity.merge(entityObject)
					                                storedEntity.persist('fromSync')
					                                if storedEntity.respond_to?('afterSync'.to_sym)
					                                    storedEntity.afterSync
					                                end
					                            else
					                                entityObject.persist('fromSync')
					                                if entityObject.respond_to?('afterSync'.to_sym)
					                                    entityObject.afterSync
					                                end
					                            end 
					                        end          
										end
			                        end
			                        db.commit
			                    rescue StandardError => se
			                        db.rollback
			                        RhoLog.error('Error while syncing entities: ', se.to_s)
			                    end
		                    end
	                    end
	                    if !Rho::RhoConfig.exists?('create_sdk_build') || (Rho::RhoConfig.exists?('create_sdk_build') and Rho::RhoConfig.create_sdk_build.to_s=='0')
		                    Alert.show_popup({
		                        :message => MobiSys::BrowserHelper.getLabel('EMAILSENT'),
		                        :title => '',
		                        :icon => :alert,
		                        :buttons => [MobiSys::BrowserHelper.getLabel("Ok")]
		                    })
		                else
		                	returnHash = response
		                end
	                end
	            end
	            if generateHTMLfor == "email"
	                errorPopup = getLabelValue('Email')
	            else
	                errorPopup = getLabelValue('ILLUSTRATIONDOWNLOAD')
	            end
	        rescue StandardError => se
	            puts "exception: #{se.backtrace}"
	            returnHash["error"] = getLabelValue('DOWNLOADFAILED',[errorPopup])
	        end
	        return returnHash
	    end
         def self.reopenQuotation(policy)
        	if policy
        		quotation = Quotation.loadObject(:first,:conditions => {{:name=>'quotationRefNum'}=>policy.quotationRefNum})
        		quotation.entityStatus = "REOPEN"
        		quotation.step = 0
        		quotation.quoteStatusCd = MobiSys::QuotationBO::COMPLETED
        		quotation.policyNum = nil
        		signatureContainer = SignatureContainer.loadObject(:first,:conditions =>{:entityGuid => quotation.guid})
		        if signatureContainer
			        signatureContainer.ServiceSignatureList.delete_if do |signature|
					    signature.destroy
					    true
					end
					signatureContainer.destroy
				end
		        saveValidate(quotation)
		        return quotation
        	end
        end

        def self.proposerLASameCopy
	        @insured.partyTypeCd = "INDIVIDUAL"
	        @insured.title = @policyHolder.title
	        @insured.otherTitle = @policyHolder.otherTitle
	        @insured.firstname = @policyHolder.firstname
	        @insured.middlename = @policyHolder.middlename
	        @insured.lastname = @policyHolder.lastname
	        @insured.extensionName = @policyHolder.extensionName
	        @insured.firstname2 = @policyHolder.firstname2
	        @insured.middlename2 = @policyHolder.middlename2
	        @insured.lastname2 = @policyHolder.lastname2
	        @insured.extensionName2 = @policyHolder.extensionName2
	        @insured.genderCd = @policyHolder.genderCd
	        @insured.dob = @policyHolder.dob
	        @insured.age = @policyHolder.age
	        @insured.relationCd = @policyHolder.relationCd
	        @insured.smoker = @policyHolder.smoker
	        @insured.industryCd = @policyHolder.industryCd
	        @insured.countryCd = @policyHolder.countryCd
	        @insured.contactNum = @policyHolder.contactNum
	        @insured.emailAddress = @policyHolder.emailAddress
	        @insured.natureOfDuty = @policyHolder.natureOfDuty
	        @insured.occupationCd = @policyHolder.occupationCd
	        @insured.nsap = @policyHolder.nsap
	        @insured.nationality = @policyHolder.nationality
	        if @insured.QuotationPartyAddressList.empty?
		        @policyHolder.QuotationPartyAddressList.each do |proposerPartyAdddress|
					primaryPartyAdddress = QuotationPartyAddress.new
					fieldsToExcludeArr = ["guid"]
					primaryPartyAdddress = MobiSys::CommonUtil.copyFields(proposerPartyAdddress, primaryPartyAdddress, fieldsToExcludeArr)
					@insured.addQuotationPartyAddress(primaryPartyAdddress)
		        end
		    else
		       @policyHolder.QuotationPartyAddressList.each do |proposerPartyAdddress|
					primaryPartyAdddressList = @insured.QuotationPartyAddressList
					primaryPartyAdddressList.each do|primaryPartyAdddress|
						# added removed != 'YES' condition for stop duplication of insured party address objects on save quotation for C360 when lead party address is copied into quotation party address
						if primaryPartyAdddress.addressTypeCd == proposerPartyAdddress.addressTypeCd && primaryPartyAdddress.removed.to_s != "YES"
							fieldsToExcludeArr = ["guid"]
							primaryPartyAdddress = MobiSys::CommonUtil.copyFields(proposerPartyAdddress, primaryPartyAdddress, fieldsToExcludeArr)
							@insured.addQuotationPartyAddress(primaryPartyAdddress)
					    end
				    end		
		        end 
		    end
		end
		
		def self.setPartyFields(quotation)
        	if quotation
	        	quotation.QuotationPartyList.each do |quotationPartyDO|
	        		if quotationPartyDO.partyTypeCd.to_s == "INDIVIDUAL"
	        			quotationPartyDO.corporateName = nil
	        			quotationPartyDO.corporateName2 = nil
	        		elsif quotationPartyDO.partyTypeCd.to_s == "ORGANIZATION"
	        			quotationPartyDO.title = nil
						quotationPartyDO.firstname = nil
						quotationPartyDO.firstname2 = nil
						quotationPartyDO.lastname = nil
						quotationPartyDO.middlename = nil
						quotationPartyDO.middlename2 = nil
						quotationPartyDO.smoker = nil
						quotationPartyDO.lastname2 = nil
						quotationPartyDO.dob = nil
						quotationPartyDO.genderCd = nil
						quotationPartyDO.age = nil
						# quotationPartyDO.nsap = nil
						quotationPartyDO.coverageCityCd = nil
						quotationPartyDO.coverageCountryCd = nil
						quotationPartyDO.maritalStatus = nil
						quotationPartyDO.idType = nil
						quotationPartyDO.idNumber = nil
						quotationPartyDO.industryCd = nil
						quotationPartyDO.natureOfDuty = nil
						quotationPartyDO.occupationCd = nil
	        		end
	        	end
	        end
        end
	end
end

begin 
    require 'Quotation/quotation_service_company'
rescue LoadError => e
    puts 'quotation_service_company not included'
end
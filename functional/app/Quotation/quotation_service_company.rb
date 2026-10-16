require 'CommonModules/entityschema'
# require 'CommonModules/syncmodule'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'Product/product_util'
require 'Quotation/APO'




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
	        
	        lastName = primaryParty.lastname
	       
	        firstName = primaryParty.firstname
	        
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
	        data = filehtml.scan(/\/public\S*[js|css|jpg|png]/)
	        if System.get_property('platform') == 'APPLE'
	            data = data + [
	                "/public/jquery/jquery-1.11.3.min.js",
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
	                        mainSplit.gsub!("$(document).ready","$(window).load")
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
		                    mainSplit.gsub!("$(document).ready","$(window).load")
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
	                    filehtml << "<script type=\"text/javascript\" src=\"jquery-1.11.3.min.js\"></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.bar.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.hbar.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.scatter.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.annotate.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.context.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.dynamic.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.effects.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.resizing.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.tooltips.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.zoom.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.circle.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.image.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker1.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.marker2.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.text.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.xaxis.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.yaxis.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.drawing.rect.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.line.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.core.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.pie.js\" ></script>"
	                    filehtml << "<script type=\"text/javascript\" src=\"RGraph.common.key.js\" ></script>"
	                    filehtml << "<link rel=\"stylesheet\" type=\"text/css\" href=\"main_company.css\" />"
	                    filehtml << "</head>"
	                    filehtml << "<body style='border:1px solid white'>"
	                    filehtml << "<style type='text/css'>#footer{clear:both;position:absolute;}</style>"
	                    filehtml << "<style type='text/css'>@media print {* { -webkit-print-color-adjust: exact !important; } }</style>" #DPHSS-1680
	                    #filehtml << "<style type='text/css'>#footer{clear:both;position:absolute;}table {border-collapse:collapse; table-layout:fixed;}table td{word-wrap:break-word;}</style>"
	                    filehtml << mainSplit
	                    filehtml << "<script type=\"text/javascript\">$(window).load(function(){document.body.style.height='#{$outputPageHeightMM}';document.body.style.width='#{$outputPageWidthMM}';document.body.style.paddingLeft='#{$outputPagePaddingLeftMM}';document.body.style.paddingRight='#{$outputPagePaddingRightMM}';document.body.style.margin='0';
	                    var footer = document.getElementById('footer');
	                    var height = footer.offsetHeight;
	                    var style = getComputedStyle(footer);
	                    height += parseInt(style.marginTop) + parseInt(style.marginBottom);
	                    footer.style.top = (#{pdfheight} - height)-8+'px';});</script>"
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
	                if $quotationIO.baseDO.QuotationPartyList.size > 0
	                    primaryParty = $quotationIO.baseDO.getPartyByRole("PRIMARY")
	                    if primaryParty
	                        if primaryParty.lastname.to_s.size < 4
	                            userPassword = primaryParty.lastname.to_s.upcase+primaryParty.age.to_s
	                        else
	                            userPassword = primaryParty.lastname.to_s[0..3].upcase+primaryParty.age.to_s
	                        end
	                    end
	                end
	                masterPassword = (MobiSys::Encryption.decryptContent($quotationIO.baseDO.userId)).to_s
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

	end
end

begin 
    require 'Quotation/quotation_service_company'
rescue LoadError => e
    puts 'quotation_service_company not included'
end
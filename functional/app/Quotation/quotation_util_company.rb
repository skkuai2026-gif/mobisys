require 'CommonModules/entityschema'
require 'CommonModules/syncmodule'
require 'Quotation/quotation_b_o'
require 'Product/product_b_o'
require 'Quotation/UIGenUtil'
require 'Product/product_util'

module MobiSys
	class QuotationUtil
		def self.findTemplatePageMapping(quotationIO)
	  		quotationProduct = quotationIO.baseDO.getBaseProduct
		  	currency = quotationProduct.currencyCd
		  	
		  	product = quotationIO.baseProduct.productId
			productVersion = quotationProduct.productVersion

		  	finalTemplatePageMappingDOList = {}
		  	quot_prod = MobiSys::ProductUtil.getProduct(quotationProduct.productSeq)
	  		offlineFacet = quot_prod.getFacet("SITEMPLATEID")
		  	if offlineFacet
  				template = TemplateMaster.loadObject(:first, :conditions=> {'templateId' => offlineFacet.actionValue})
  				templatePageMappingDOList = TemplatePageMapping.loadObject(:all, :conditions=> {'templateMasterSeq' => template.id}, :order=>'displayOrder', :orderdir=>'ASC')
  				templatePageMappingDOList.each do |templatePageMappingDOListev|
					groupCd = templatePageMappingDOListev.groupCd.to_s != "" ? templatePageMappingDOListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDOListev)
				end
	  			$quotationIO.templatePageMappingDO = finalTemplatePageMappingDOList
		  	else
			  	queryString = "Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where 
			  		outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq 
					  and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null) and tpmDO.displayOrder < 501 and (outputDO.productVersion = '#{productVersion}' or outputDO.productVersion is null ) order by tpmDO.displayOrder"
			  	puts "queryString: #{queryString}"
			  	templatePageMappingDOList = TemplatePageMapping.find_by_sql(queryString)
				templatePageMappingDOList.each do |templatePageMappingDOListev|
					groupCd = templatePageMappingDOListev.groupCd.to_s != "" ? templatePageMappingDOListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDOListev)
				end

				riderList = quotationIO.baseDO.getRiders

				riderListString = ""
				maxElement = riderList.size
				riderList.each_with_index do |rider, i|
				  riderListString << "'#{rider.productId}'"
				  riderListString << "," if i < maxElement - 1
				end

				queryString = "Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null) and outputDO.productVersion = '#{productVersion}' and tpmDO.rider in (#{riderListString}) and tpmDO.displayOrder > 500 
						order by tpmDO.displayOrder,tpmDO.rider"
				puts ">>>queryString: #{queryString}"
				unless riderList == []
					templatePageMappingDORiderList = TemplatePageMapping.find_by_sql(queryString)
					puts ">>>templatePageMappingDORiderList: #{templatePageMappingDORiderList.inspect}"
					#finalTemplatePageMappingDOList << templatePageMappingDORiderList
					templatePageMappingDORiderList.each do |templatePageMappingDORiderListev|
						groupCd = templatePageMappingDORiderListev.groupCd.to_s != "" ? templatePageMappingDORiderListev.groupCd.to_s : 'NoGroupCd'
						finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
						finalTemplatePageMappingDOList[groupCd].push(templatePageMappingDORiderListev)
					end
				end

				templatePageMappingList = TemplatePageMapping.find_by_sql("Select tpmDO.* from OutputContext outputDO , TemplatePageMapping tpmDO where 
					outputDO.product = '#{product}' and outputDO.templateMasterSeq = tpmDO.templateMasterSeq and (outputDO.entityTypeCd = '' or outputDO.entityTypeCd is null)  and tpmDO.displayOrder > 800 and (outputDO.productVersion = '#{productVersion}' or outputDO.productVersion is null )
					order by tpmDO.displayOrder")

				#finalTemplatePageMappingDOList << templatePageMappingList
				templatePageMappingList.each do |templatePageMappingListev|
					groupCd = templatePageMappingListev.groupCd.to_s != "" ? templatePageMappingListev.groupCd.to_s : 'NoGroupCd'
					finalTemplatePageMappingDOList[groupCd] = [] unless finalTemplatePageMappingDOList[groupCd].is_a?(Array)
					finalTemplatePageMappingDOList[groupCd].push(templatePageMappingListev)
				end
				puts ">>>finalListSize: #{finalTemplatePageMappingDOList.size}"
				$quotationIO.templatePageMappingDO = finalTemplatePageMappingDOList
			end
	  	end
	end
end
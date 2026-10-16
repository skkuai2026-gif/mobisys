require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'Product/product_util'
require 'date'
require 'CommonModules/mobisyssignature'
require 'LabelValue/label_value'
require 'json'

class ProductController < BaseRestController
    include BrowserHelper
    include MobiSys::BrowserHelper

    def initialize
        # logInfo "~~~in product rest initialize"
    end

    def fetch(id)
        # logInfo "~~~@baseIO in fetch:#{@baseIO}"
        product = Product.loadObject(:first, :conditions => {:object => id})
    	@baseIO.baseDO = product
    end

    def getUIFacets
        parsedData = parseRequestBodyParams
        productSeq = ((parsedData.has_key?("productSeq") && parsedData['productSeq'].to_s != "")? parsedData['productSeq'] : nil)
        responseHash = {}

        if productSeq.to_s != ""
            product = Product.loadObject(:first, :conditions => {:id => productSeq})
            if product
                uiFacetHash = MobiSys::ProductUtil.getProductData(product)
                responseHash["data"] = uiFacetHash
                responseHash['success'] = true
                responseHash['message'] = "Successful"
            else
                responseHash['success'] = false
                responseHash['message'] = "Product not found"
            end
        else
            #Get Company Facets if no productSeq
            uiFacetHash = {}

            companyFacets = CompanyFacet.find(
                :all
            )
           
            sysDate = Time.new.strftime("%F 00:00:00 %z")
            if companyFacets
                companyFacets.each do |companyFacet|
                    validFacet = false
                    actionValue = nil
                    if companyFacet.effectiveFromDt.to_s != "" && companyFacet.effectiveToDt.to_s != "" && sysDate.to_s != ""
                        if (!(MobiSys::ProductUtil.getDifference(Date.strptime(getScreenDate(sysDate), "%d/%m/%Y"),Date.strptime(getScreenDate(companyFacet.effectiveFromDt), "%d/%m/%Y")) < 0) && !(MobiSys::ProductUtil.getDifference(Date.strptime(getScreenDate(sysDate), "%d/%m/%Y"),Date.strptime(getScreenDate(companyFacet.effectiveToDt), "%d/%m/%Y")) > 1))
                            validFacet = true
                        end
                    else
                        validFacet = true
                    end
                    if validFacet
                        actionValue = MobiSys::ProductUtil.getCompanyFacetValue(companyFacet)
                        if actionValue.to_s == "" && companyFacet.actionTypeCd.to_s == "MODEL"
                            # evaluate policy model and get output action value\
                            modelCd = companyFacet.actionValue
                            policy = Policy.new
                            policyModelSet = PolicyUtil::PolicyModelSet.new
                            fldrdo = policyModelSet.execute(policy,nil,nil,modelCd)
                            if fldrdo.to_s != ""
                                outputAction = fldrdo.getFieldValue("outputAction")
                                facetmDO = Facet.loadObject(:first,:conditions=>{{:name=>'facetId'}=> outputAction})
                                if facetmDO && facetmDO.facetGroupCd.to_s = "XMLUIFORMAT"
                                    actionValue = companyFacet.actionValue.to_s if companyFacet.facetCd.to_s == outputAction.to_s
                                else
                                    actionValue = fldrdo.getFieldValue("outputAction")
                                end
                            end
                        end
                    uiFacetHash[companyFacet.facetCd] = actionValue
                    end
                end
            end

            responseHash["data"] = uiFacetHash
            responseHash['success'] = true
            responseHash['message'] = "Successful"
        end

        render :string => responseHash.to_json
    end
    
end
require 'BaseRest/base_rest_controller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/schema_module'
require 'CommonModules/syncmodule'


class MetadataController < BaseRestController
	include BrowserHelper
	include MobiSys::BrowserHelper

	def initialize
		# logInfo("~~~in AgentRegController initialize")
	end

    def reEvaluateContext
        params = parseRequestBodyParams
        evalHashGuid = params['contextGuid'].to_s
        #get all the context masters for the current object and attribute only (excluding the parents) to reEvaluate the context name and replace it in the global context map
        fieldName = params['fieldName'].to_s
        value = params['value'].to_s
        isValid = false
        # fieldName = id.include?("_") ? id[id.rindex('_')+1..-1].to_s : ""
        if $contextMasterEvalHash[evalHashGuid] && $contextMasterEvalHash[evalHashGuid].size > 0
            $contextMasterEvalHash[evalHashGuid].each do |contextMaster|
                if contextMaster["fieldName"].to_s == fieldName
                    isValid = true
                    className = contextMaster["className"].to_s.gsub("DO","")
                    expression = contextMaster["contextNameExpression"].to_s
                    objClass = Object.const_get(className)
                    obj = objClass.new
                    begin
                        exp = 'obj.'+fieldName.to_s+"='"+value.to_s.gsub("'","\\\\'")+"'"
                        eval(exp)
                    rescue StandardError => boom
                        puts boom
                    end
                    newContextName = MobiSys::ContextMasterData.evaluateContextField(obj,fieldName,expression)
                    contextMaster["contextName"] = newContextName.to_s
                end
            end
        end
        returnHash = Hash.new
        if isValid == true
            returnHash["success"] = true
            returnHash["message"] = "Successful"
        else
            returnHash["success"] = false
            returnHash["message"] = "No Context Found"
        end
        render :string => returnHash.to_json
    end

    def evaluateMetadata
        params = parseRequestBodyParams
        evalHashGuid = params['guid'].to_s
        # metaDataCd = params['metaDataCd'].to_s
        fieldName = params['fieldName'].to_s
        metaDataCd = $guidClassNameMap[evalHashGuid].to_s + "DO." + fieldName
        # id = params['id'].to_s
        @currentApplicableContexts = []
        label = ""
        visibility = true
        enabled = true
        minOccurs = ""
        maxlength = ""
        minlength = ""
        lookupcd = ""
        isValid = false
        if $contextMasterEvalHash[evalHashGuid]
            @currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym }
        end
        evalHashGuid = $parentChildGuidMapping[evalHashGuid]
        #while loop to add all the contexts of the parent classes except the top most parent.
        if $parentChildGuidMapping[evalHashGuid]
            while $parentChildGuidMapping[evalHashGuid] do
                @currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym }
                evalHashGuid = $parentChildGuidMapping[evalHashGuid]
            end
        end
            #To include the Contexts of the Main class (Grandparent) since the Global hash will not have it as a key $parentChildGuidMapping[evalHashGuid] condition in the while loop will fail for the top most parent class.
        @currentApplicableContexts << $contextMasterEvalHash[evalHashGuid].collect{|e| e["contextName"].to_sym } if $contextMasterEvalHash[evalHashGuid]
        @currentApplicableContexts.flatten!
        metaDataClass = metaDataCd.to_s.split('.')[0].to_sym
        if $uiMetaDataCache.has_key?(metaDataClass) && $uiMetaDataCache[metaDataClass].has_key?(metaDataCd.to_sym)
            isValid = true
            uiMetaDataDOList = $uiMetaDataCache[metaDataClass][metaDataCd.to_sym]
            ui = MobiSys::UIMetaData.getUiMetadataPropDO("LABELKEY", uiMetaDataDOList, @currentApplicableContexts,"array")
            label = (ui == nil ? "" : ui.propertyValue.to_s)

            ui = MobiSys::UIMetaData.getUiMetadataPropDO("VISIBILITY", uiMetaDataDOList, @currentApplicableContexts,"array")
            visibility = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

            ui = MobiSys::UIMetaData.getUiMetadataPropDO("LOOKUPCD", uiMetaDataDOList, @currentApplicableContexts,"array")
            lookupcd = (ui == nil ? "" : ui.propertyValue.to_s)

            ui = MobiSys::UIMetaData.getUiMetadataPropDO("ENABLED", uiMetaDataDOList, @currentApplicableContexts,"array")
            enabled = (ui == nil ? true : (ui.propertyValue.to_s == "NO" ? false : true))

            ui = MobiSys::UIMetaData.getUiMetadataPropDO("MAXLENGTH", uiMetaDataDOList, @currentApplicableContexts)
            maxlength = (ui == nil ? "" : ui.propertyValue.to_s)

            ui = MobiSys::UIMetaData.getUiMetadataPropDO("MINLENGTH", uiMetaDataDOList, @currentApplicableContexts)
            minlength = (ui == nil ? "" : ui.propertyValue.to_s)
        end
        metaDataCdDOName = metaDataCd.index(".") != nil ? metaDataCd.split(".")[0] : ""
        if $validationHash.has_key?(metaDataCdDOName.to_sym)
            validationMetaDataDOList = $validationHash[metaDataCdDOName.to_sym]
            val = MobiSys::Validation.getValidationDO("MINOCCURS", validationMetaDataDOList, @currentApplicableContexts, metaDataCd)
            minOccurs = (val == nil ? "" : val.validationParam.to_s)
            isValid = true if minOccurs.to_s != ""
        end

        returnHash = Hash.new
        if isValid == true
            # returnHash["metaDataCd"] = metaDataCd
            returnHash["data"] = Hash.new
            returnHash["data"]["LABELKEY"] = label if label.to_s != ""
            returnHash["data"]["VISIBILITY"] = visibility
            returnHash["data"]["ENABLED"] = enabled
            returnHash["data"]["LOOKUPCD"] = lookupcd if lookupcd.to_s != ""
            returnHash["data"]["MINOCCURS"] = minOccurs if minOccurs.to_s != ""
            returnHash["data"]["MAXLENGTH"] = maxlength if maxlength.to_s != ""
            returnHash["data"]["MINLENGTH"] = minlength if minlength.to_s != ""
            returnHash["success"] = true
            returnHash["message"] = "Successful"
        else
            returnHash["success"] = false
            returnHash["message"] = "No Metadata Found"
        end
        render :string => returnHash.to_json
    end
end
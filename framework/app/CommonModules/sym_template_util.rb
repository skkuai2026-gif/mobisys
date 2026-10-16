require 'base64'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/math'
require 'CommonModules/ChartFactory'
require 'ostruct'
require 'time'


module MobiSys

	module SymTemplateUtil

		include MobiSys::BrowserHelper
		include MobiSys::Math
		include MobiSys::DateTimeUtils
		# include MobiSys::ChartFactory

		def getImageSrc(imagePath,viewType)
			if viewType.downcase == "pdf"
				if (imagePath != nil && (imagePath.to_s.start_with?("http") || imagePath.to_s.start_with?("file:")))
					return imagePath
				else
					return "file:" + imagePath.to_s
				end
			else
				encodedString = ""
				if File.exists?(imagePath)
					encodedString =
						File.open(imagePath, "rb") do |file|
							MobiSys::Encryption.encodeContents(file.read)
						end
				end
				encodedString = "data:image/png;base64,#{encodedString}" if encodedString.to_s != ""
				return encodedString
			end
		end

		def getImageContent(image)
			return "" if image == nil
			encodedString = ""
			if(image != nil)
				encodedString = image
				if image.to_s.start_with?('ZLIBCMP')
		    		image = image.gsub!('ZLIBCMP','')
		    		decodedImage = MobiSys::Encryption.decodeContents(image)
		    		uncompressed_image = MobiSys::Encryption.unZipData(decodedImage)
		    		encodedString = 'data:image/png;base64,' + MobiSys::Encryption.encodeContents(uncompressed_image)
		    	end
		    end
			return encodedString
		end

		def getLabelValue(labelKey)
			str = ""
			str = MobiSys::BrowserHelper.getLabel(labelKey.to_s)
			return str
		end

		def getLabelValueForLang(labelKey, languageCd)
			labelValue = LabelValue.getLabel(labelKey, languageCd.downcase!)
			if labelValue == nil or (labelValue and labelValue == "")
				labelValue = labelKey
			end
			return labelValue
		end

		def getLookupValDesc(lookupKey, lookupDataCd)
			lookup_desc = ""
			lookup_desc = getOfflineLookupData(lookupKey, {},lookupDataCd)
			return lookup_desc
		end

		def getLookupValDescForLang(lookupKey, lookupDataCd, languageCd)
			lookup_desc = ""
			lookup_desc = getLookupValDesc(lookupKey, lookupDataCd)
			lookup_desc = getLabelValueForLang(lookup_desc, languageCd) if lookup_desc.to_s != ""
			return lookup_desc
		end

		def checkNull(obj)
			if obj != nil
				return obj.to_s
			else
				return ""
			end
		end

		def getFormattedDecimal(obj)
			formattedNum = ""
			if obj != nil
	            format = $rhoconfig[:number_format_pattern]

				formattedNum = getFormattedDecimalAs(obj,format)
			end
			return formattedNum
		end

		def getFormattedDecimalAs(obj, format)
			formattedNum = ""
			if obj != nil
				format = $rhoconfig[:number_format_pattern].to_s if format == nil
                formattedAmountStr = MobiSys::BrowserHelper.formatNumber(MobiSys::BrowserHelper.numberRound(obj,2), format)
			end
			return formattedAmountStr
		end

		def getIntValue(obj)
			if obj != nil
				return MobiSys::Math.toInt(obj)
			else
				return nil
			end
		end

		def getAbsoluteValue(obj)
			if obj != nil
				if obj.is_a?(Integer)
					return obj.abs
				else
					return obj.to_i.abs
				end
			else
				return nil
			end
		end

		def roundUpInt(obj)
			if obj != nil
				return obj.to_f.ceil
			else
				return nil
			end
		end

		def getZero(obj)
			if obj != nil
				return obj
			else
				return 0
			end
		end

		def getFormattedDate(obj)
			date = nil
			date = getDBDate(obj).strftime("%d/%m/%Y") if obj
			# date = MobiSys::DateTimeUtils.formatDate(date)
			return date.to_s
		end

		def getFormattedDateAs(obj,format)
			date = nil
			date = getDBDate(obj).strftime(format.to_s) if obj
			return date.to_s
		end

		def self.loadHTMLBodyContent(htmlContent, bodyContent, cssContent)
			# Removing HTML tags
			htmlContent.gsub!(/<!DOCTYPE HTML>/i, "")
			htmlContent.gsub!(/<html>/i, "")
			htmlContent.gsub!(/<\/html>/i, "")
			htmlContent.gsub!(/<body>/i, "")
			htmlContent.gsub!(/<\/body>/i, "")
			htmlContent.gsub!(/<head>/i, "")
			htmlContent.gsub!(/<\/head>/i, "")

			htmlContent.gsub!("\t", "")
			htmlContent.gsub!("\n", "")

			# Adding styles separately since these are added to the head tag rather than as part of html body content.
			# Since some browsers ignore this
			if htmlContent =~ /<style type="text\/css">/i
				css_start = htmlContent =~ /<style type="text\/css">/i
				css_end = htmlContent =~ /<\/style>/i
				cssContent << htmlContent[(css_start + '<style type="text/css">'.length)...css_end].strip

				bodyContent_string1 = htmlContent[0...css_start].strip
				bodyContent_string2 = htmlContent[(css_end + 8)...htmlContent.length].strip
				bodyContent << "#{bodyContent_string1} #{bodyContent_string2}"
			else
				bodyContent << htmlContent
			end
		end


		def getChartStr(chartName,vars,width,height,addtnlCurrData1,addtnlCurrData2,addtnlCurrData3)
			return MobiSys::ChartFactory.generateChart(chartName,vars,width,height,addtnlCurrData1,addtnlCurrData2,addtnlCurrData3)
		end

		def getSignature(allSignaturesList,entityGuid,partyGuid,signTypeCd, roleCd)
			serviceSignature = nil
			if allSignaturesList != nil && allSignaturesList.size > 0
			    serviceSignature = allSignaturesList.select{|serviceSign| (serviceSign.signatureTypeCd == signTypeCd && serviceSign.partyGuid == partyGuid)}.first
			end
			if serviceSignature == nil
				serviceSignature = ServiceSignature.new(:signatureTypeCd => signTypeCd.to_s, :entityGuid => entityGuid , :roleCd => roleCd.to_s, :partyGuid => partyGuid)
				serviceSignature.guid = serviceSignature.uniqueKey
  				allSignaturesList << serviceSignature
			end
			serviceSignatureOStruct = !serviceSignature.is_a?(OpenStruct) ? ::JSON.parse(serviceSignature.to_json, object_class:OpenStruct) : serviceSignature
		    return serviceSignatureOStruct
		end

		def getFieldError(errorList, baseDOObj, fieldName)
			return MobiSys::CommonUtil.getFieldError(errorList, baseDOObj, fieldName)
		end

		def getPageCount(maxRows, totalTermCount)
			noOfPages = 0
			if maxRows != nil && totalTermCount != nil
				noOfPages = getIntValue(roundUpInt(totalTermCount.to_f/maxRows.to_f))
			end
			return noOfPages
		end

		def incrementPage(this)
			this.sym_page_count += 1
		end

		def getSubString(obj, beginIndex, endIndex)
			if obj.to_s != ""
				if endIndex.to_s != ""
					return obj[beginIndex..endIndex-1]
				else
					return obj[beginIndex..-1]
				end
			else
				return nil
			end
		end

		def getStringLength(obj)
			if obj.to_s != ""
				return obj.length
			else
				return nil
			end
		end

		def toLowerCase(obj)
			if obj.to_s != ""
				return obj.downcase
			else
				return nil
			end
		end

		def toUpperCase(obj)
			if obj.to_s != ""
				return obj.upcase
			else
				return nil
			end
		end

		def getDayOfMonth(obj)
			if obj.to_s != ""
				dtDate = obj
				if obj.is_a?(String)
					dtDate = DateTime.strptime(obj,'%Y-%m-%d')
				end
				return dtDate.day
			else
				return nil
			end
		end

		def getMonth(obj)
			if obj.to_s != ""
				dtDate = obj
				if obj.is_a?(String)
					dtDate = DateTime.strptime(obj,'%Y-%m-%d')
				end
				return dtDate.month
			else
				return nil
			end
		end

		def getYear(obj)
			if obj.to_s != ""
				dtDate = obj
				if obj.is_a?(String)
					dtDate = DateTime.strptime(obj,'%Y-%m-%d')
				end
				return dtDate.year
			else
				return nil
			end
		end

		def getPolicyQuestionnaireHTML(this)
			policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => this.eapp.Policy.Entity.object})
			return MobiSys::UIGenUtilEapp.getPolicyQuestionnaireHTML(policy)
		end

		def getPolicyQuestionnaireHTMLForParty(this, partyGuid)
			policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => this.eapp.Policy.Entity.object})
			return MobiSys::UIGenUtilEapp.getPolicyQuestionnaireHTMLForParty(policy, partyGuid)
		end

		def getPolicyQuestionnaireHTMLTableForParty(this, partyGuid, includeTable)
			policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => this.eapp.Policy.Entity.object})
			return MobiSys::UIGenUtilEapp.getPolicyQuestionnaireHTMLTableForParty(policy, partyGuid, includeTable)
		end

		def isQuestionApplicableForParty(this, partyGuid)
			policy = Policy.loadObject(:first, :conditions=>{{:name => 'object'} => this.eapp.Policy.Entity.object})
			return MobiSys::UIGenUtilEapp.isQuestionApplicableForParty(policy, partyGuid)
		end

		def getRoundedUpDouble(obj, precision)
			if obj != nil
				return MobiSys::Math.roundUp(obj, precision)
			else
				return nil
			end
		end

		def getRoundedDownDouble(obj, precision)
			if obj != nil
				return MobiSys::Math.roundDown(obj, precision)
			else
				return nil
			end
		end

		def getRoundedNearestDouble(obj, precision)
			if obj != nil
				return MobiSys::Math.roundNearest(obj, precision)
			else
				return nil
			end
		end
	end

end

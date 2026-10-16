require 'CommonModules/mobisysuihelper_jazz'

class LabelValueController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    def languageSettings
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

		render :action => :languageSettings_Jazz, :layout => :jazzLayout
	end

	def changeLanguage
		begin
			selectedLanguage = @params['language']
			Application.updateValue('DEFAULTLOCALE',selectedLanguage)
			Localization::LabelCache.instance.resetLabels(selectedLanguage)
			redirect :action => :landingPage, :controller => :Menu, :layout => :jazzLayout
		rescue StandardError => e
			puts ">>>Exception in changeLanguage: #{e}"
		end
	end

	def getMultipleLabelValue
		returnHash = {}
		@params['labelKeys'].to_s.split('|').each do |labelKey|
    		returnHash[labelKey.to_sym] = getLabelValue(labelKey).to_s
		end
		render :nothing => true
    	return returnHash.to_json
	end

	def getLabelValueForJs
		replaceParameter = [@params['replaceParameter'].to_s]
		return render(:string => getLabelValue(@params['labelKey'], replaceParameter).to_s)
	end
end
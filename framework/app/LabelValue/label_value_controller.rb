require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'CommonModules/mobisysbrowserhelper'

class LabelValueController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper

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

		render :action => :languageSettings, :layout => :newEAPPLayout
	end


	def changeLanguage
		begin
			selectedLanguage = @params['language']
			Application.updateValue('DEFAULTLOCALE',selectedLanguage)
			Localization::LabelCache.instance.resetLabels(selectedLanguage)
			redirect :action => :settings, :controller => :Menu, :layout => :newEAPPLayout
		rescue StandardError => e
			puts ">>>Exception in changeLanguage: #{e}"
		end
	end
end

begin 
    require 'LabelValue/label_value_controller_jazz' if $rhoconfig[:TABFEATUREREQD]
rescue LoadError => e
    puts 'label_value_controller_jazz not included'
end

begin 
	require 'LabelValue/label_value_controller_company'
rescue LoadError => e
	puts 'label_value_controller_company not included'
end
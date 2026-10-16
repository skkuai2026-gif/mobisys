module Mobisys
	class Settings
		def self.setRhoconfigParams
			$questionSetData = nil
        	$questionSet = nil
        	$inputTypeOfQuestion = {}
        	$questionSetQuestion = nil
        	$responseHash = {}
			$rhoconfig = {}

			#Post login page for your application
			$rhoconfig[:post_login_path] = "/app/Menu/landingPage"

			# SLOCPI ST URL 
			$rhoconfig[:online_server_url] = "http://192.168.200.115:8091/systemcommon"

			# SLGFI ST URL 
			# $rhoconfig[:online_server_url] = "http://192.168.200.133:8091/systemcommon"		


			# External

            # ST1 EXTERNAL URL
			# $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-st1/systemcommon"
			# $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-st1/systemcommon"

			# AT1 EXTERNAL URL
			# $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-at1/systemcommon"
			# $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-at1/systemcommon"

			# ST2 EXTERNAL URL
		    #$rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-st2/systemcommon"
		    # $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-st2/systemcommon"

		    # AT2 EXTERNAL URL
		    #$rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-at2/systemcommon"
		    # $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-at2/systemcommon"

		    # Dev EXTERNAL URL
		    # $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-dev/systemcommon"
		    # $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-dev/systemcommon"

		    #STAGE EXTERNAL URL
		    # $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slocpi-stage/systemcommon"
			# $rhoconfig[:online_server_url] = "https://stage.sunlife.com.ph/sunsmartpos-slgfi-stage/systemcommon"


		    # PROD URL
		    # $rhoconfig[:online_server_url] = "https://sunsmartpos.sunlife.com.ph/systemcommon"
			# $rhoconfig[:online_server_url] = "https://sunsmartpos.sunlifegrepa.com/systemcommon"


			$rhoconfig[:Dimoge] = "4ef7967a95929d4f7e41c5cabc305ff52b17f24dsu"

			$rhoconfig[:uses_rules] = "ONLINE"
			
			$rhoconfig[:syncapproach] = "NEW"
			# $rhoconfig[:syncapproach = "STAGGERED

			$rhoconfig[:syncpagesize] = "10"
			
			# GeoLocation callback interval in seconds
			$rhoconfig[:geolocation_callback_interval] = "30"

			# Set flag to specify if location tagging is available for images.
			$rhoconfig[:image_location_enabled] = "NO"

			$rhoconfig[:encrypt_images] = "NO"

			# DB seeding
			$rhoconfig[:create_db_seed] = "NO"

			###### refresh app version set ######
			$rhoconfig[:fresh_app_version] = '1.5'
			$rhoconfig[:fresh_install] = 'NO' 
			###### refresh app version set ######


			# $rhoconfig[:SunPHComp] = 'SLGFI'
		    $rhoconfig[:SunPHComp] = 'SLOCPI'

			$rhoconfig[:use_okta_authentication] = "NO"
			# $rhoconfig[:use_okta_authentication] = "YES"

			$rhoconfig[:initial_db_version] = "50.9"
			# $rhoconfig[:initial_db_version] = "6.1"

			$rhoconfig[:initial_outputimages_version] = "1.0"

			$rhoconfig[:initial_collateral_version] = "1.0"

			$rhoconfig[:seed_from_db] = "YES"

			# Sync configuration
			$rhoconfig[:synConfig] = "APPLICATION,MASTER,USERTRANSACTIONS,PRODUCT,COLLATERAL"

			# Menu & Quicklinks configuration
			$rhoconfig[:menuConfig] = "COLLATERAL,LEADS,FNA,RPQ,SALESILLUSTRATION,EAPP,RECEIPTING,CODEGENERATION,CALCULATORS,GENERATEMULTIPLEOUTPUTS"

			# Fixed Key value used in encryption
			$rhoconfig[:FIX_MOBISYS_ID_COMPONENT] = "1234567890123456"

			# Offline access count
			$rhoconfig[:offlineAllowSuccessCount] = "3"

			$rhoconfig[:agentLastLoginTimestamp] = ""

			# Flag to control whether to show the disclaimer page or not.
			$rhoconfig[:disclaimer_enabled] = "YES"

			# Supported locales
			$rhoconfig[:supported_locales] = "en,bh,hi,th"

			# Flag to show menu option in settings which enables user to change the online server URL points to. Should always be set to "NO" for production builds.
			$rhoconfig[:can_change_online_server] = "NO"

			# RSA Key
			$rhoconfig[:RSA_KEY_encryptionExponent] = '10001'
			$rhoconfig[:RSA_KEY_decryptionExponent] = '202700adbd85e2d7182720c3a0ee19c1'
			$rhoconfig[:RSA_KEY_modulus] = '30db31542ace0f7d37a629ee5eba28cb'

			# Encrypt DB fields on specific platforms
			$rhoconfig[:encrypt_db_on_platform] = 'WINDOWS_DESKTOP,ANDROID,APPLE'

			# Flag to trigger migration which changes stored userId not encrypted to encypted.
			$rhoconfig[:trigger_migration] = false

			$rhoconfig[:TABFEATUREREQD] = true
			
			# Flag to capture documents using browser capture for windows exe
			$rhoconfig[:windowsOpenCameraInBrowser] = false
			
			$rhoconfig[:colors] = 'orange,blue'

			#Flag to disable Big decimal usage for solver models. default value is set as true.
			#project teams can set the flag as false before initializing the solver model and reset back to true once the solver evaluation is done.
			$rhoconfig[:useBigDecimal] = false

			$rhoconfig[:useCollateralRenderLevel] = true

			# Flag to render default(tablet) view or mobile view.
			if !Rho::System.isRhoSimulator && System.get_property('platform') != 'WINDOWS_DESKTOP' && (Rho::System.screenWidth.to_i < 768)
				$rhoconfig[:application_view_mode] = 'mobile'
			else
				$rhoconfig[:application_view_mode] = 'default'
			end

			$rhoconfig[:applicable_image_extensions] = 'png,jpg,tiff'

			$rhoconfig[:applicable_doc_extensions] = 'pdf,pptx,docx'

			$rhoconfig[:paymentPollCount] = 1

			$rhoconfig[:paymentPollInterval] = 3
			
			$rhoconfig[:restApiTesting] = false
			#Setting Policy Model Log
			$rhoconfig[:setPolicyModelLog] = Rho::RhoConfig.LogToOutput.to_i

			$rhoconfig[:offline_server_url] = "http://127.0.0.1:9000"

			$blueTheme = false
		end

		def self.updateRhoconfigParams
			offlineApplicationList = OfflineApplication.find(
				:all,
				:conditions => {
					{
						:name => "PROPERTY",
						:op => "IN"
					} => [
							"OCR_ENABLED",
							"NEW_VALIDATIONS_IN_PRODUCTBO",
							"GET_ADDRESS_FROM_GEO",
							"PDF_GENERATION_BASED_ON_HTML",
							"HTML_GENERATION_ON_ACCEPTQUOTATION",
							"TAB_BASED_PRODUCT_SELECTION",
							"IMAGE_EXTENSIONS",
							"DOCUMENT_EXTENSIONS",
							"DEFAULT_IMAGE_DIMENSION",
							"OFFLINE_PDF_GENERATION",
							"ISOUTPUTPREFERENCESREQ",
							"CAPTURE_SIGNATURE_ON_QUOTATAION",
							"GET_PDF_ENABLED",
							"LINK_TO_EAPP_ENABLED",
							"decimalformat",
							"IS_SINGLE_PDF_REQUIRED",
							"CAPTURE_AGENT_SIGNATURE_ON_QUOTATAION",
							"ISPLANLOADINGREFRESHFL",
							"PRODUCT_FILTER_PAGE",
							"CAPTURE_SIGNATURE_IN_TAB",
							"IMAGE_SIZE_LIMIT",
							"SINGLEDEVICELOGIN",
							"NEED_ANALYSIS_MAX_AMOUNT",
							"CONTEXT_BASED_METADATA_EVALUATION",
							"PAYMENT_POLL_COUNT",
							"PAYMENT_POLL_INTERVAL",
							"ENVIRONMENT", #For API Login
							"dateformat", #For API Login
							"timeformat", #For API Login
							"INCREMENTALMASTERSYNCAPPROACH"
						]
				},
				:select => ['property as prop','value']
			)


			offlineApplicationList.each do |offlineApplication|
				case offlineApplication.prop.to_s
				when "OCR_ENABLED"
					$rhoconfig[:ocr_enabled] = offlineApplication
				when "NEW_VALIDATIONS_IN_PRODUCTBO"
					$rhoconfig[:new_validations_in_productbo] = offlineApplication.value
				when "GET_ADDRESS_FROM_GEO"
					$rhoconfig[:get_address_from_geo] = offlineApplication.value
				when "PDF_GENERATION_BASED_ON_HTML"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:offlineOutputGeneration] = true
					else
						$rhoconfig[:offlineOutputGeneration] = false
					end
				when "HTML_GENERATION_ON_ACCEPTQUOTATION"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:htmlGenerationOnAcceptQuotation] = true
					else
						$rhoconfig[:htmlGenerationOnAcceptQuotation] = false
					end
				when "TAB_BASED_PRODUCT_SELECTION"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:tab_based_product_selection] = true
					else
						$rhoconfig[:tab_based_product_selection] = false
					end
				when "IMAGE_EXTENSIONS"
					$rhoconfig[:applicable_image_extensions] = offlineApplication.value
				when "DOCUMENT_EXTENSIONS"
					$rhoconfig[:applicable_doc_extensions] = offlineApplication.value
				when "DEFAULT_IMAGE_DIMENSION"
					$rhoconfig[:default_image_dimension] = offlineApplication.value
				when "OFFLINE_PDF_GENERATION"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:offlinePDFGeneration] = true
					else
						$rhoconfig[:offlinePDFGeneration] = false
					end
				when "ISOUTPUTPREFERENCESREQ"
					$rhoconfig[:capture_output_preferences] = offlineApplication.value
				when "CAPTURE_SIGNATURE_ON_QUOTATAION"
					$rhoconfig[:capture_signature_on_quotataion] = offlineApplication.value
				when "GET_PDF_ENABLED"
					$rhoconfig[:get_pdf_enabled] = offlineApplication.value
				when "LINK_TO_EAPP_ENABLED"
					$rhoconfig[:link_to_eapp_enabled] = offlineApplication.value
				when "decimalformat"
					$rhoconfig[:number_format_pattern] = offlineApplication.value
				when "IS_SINGLE_PDF_REQUIRED"
					$rhoconfig[:isSinglePDFRequired] = offlineApplication.value
				when "CAPTURE_AGENT_SIGNATURE_ON_QUOTATAION"
					$rhoconfig[:capture_agent_signature_on_quotataion] = offlineApplication.value
				when "ISPLANLOADINGREFRESHFL"
					$rhoconfig[:refresh_loading_section] = offlineApplication.value
				when "PRODUCT_FILTER_PAGE"
					$rhoconfig[:product_filter_page] = offlineApplication.value
				when "CAPTURE_SIGNATURE_IN_TAB"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:captureSignatureInTab] = true
					else
						$rhoconfig[:captureSignatureInTab] = false
					end
				when "IMAGE_SIZE_LIMIT"
					$rhoconfig[:image_size_limit] = offlineApplication.value
				when "SINGLEDEVICELOGIN"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:singleDeviceLogin] = true
					else
						$rhoconfig[:singleDeviceLogin] = false
					end
				when "NEED_ANALYSIS_MAX_AMOUNT"
					$rhoconfig[:need_Analysis_Max_Amount] = offlineApplication.value
				when "CONTEXT_BASED_METADATA_EVALUATION"
					if offlineApplication && offlineApplication.value == "YES"
						$rhoconfig[:contextBasedMetadata] = true
					else
						$rhoconfig[:contextBasedMetadata] = false
					end
				when "PAYMENT_POLL_COUNT"
					$rhoconfig[:paymentPollCount] = offlineApplication.value
				when "PAYMENT_POLL_INTERVAL"
					$rhoconfig[:paymentPollInterval] = offlineApplication.value
				when "ENVIRONMENT"
					$rhoconfig[:app_environment] = offlineApplication.value
				when "dateformat"
					$rhoconfig[:dateformat] = offlineApplication.value
				when "timeformat"
					$rhoconfig[:timeformat] = offlineApplication.value
				when "INCREMENTALMASTERSYNCAPPROACH"
					$rhoconfig[:incrementalMasterSyncApproach] = offlineApplication.value
				end
			end


			companyFacetList = CompanyFacet.find(
				:all,
				:conditions => {
					{
						:name => "facetCd",
						:op => "IN"
					} => [
							"CAPTURE_SIGNATURE_ON_EAPP_PREVIEW",
							"CAPTURE_COUNTEROFFER_RESPONSE",
							"FUW_APPLICABLE",
							"MAJORAGE",
							"MULTIDOCAPPLICABLE",
							"PRDSELECTION",
							"CAPTURE_SIGNATURE_ON_SI_OUTPUT",
							"APPOINTEEAGE",
							"EAPPAPPLICABLE",
							"ADDTNLSICOMPANYMODELSET",
							"ADDTNLLEADCOMPANYMODELSET",
							"ADDTNLEAPPCOMPANYMODELSET",
							"NONFACETOFACE"
						]
				}
			)

			companyFacetList.each do |companyFacet|
				case companyFacet.facetCd.to_s
				when "CAPTURE_SIGNATURE_ON_EAPP_PREVIEW"
					if companyFacet && companyFacet.actionValue == "YES"
						$rhoconfig[:captureSignOnEappPreview] = true
					else
						$rhoconfig[:captureSignOnEappPreview] = false
					end
				when "CAPTURE_COUNTEROFFER_RESPONSE"
					if companyFacet && companyFacet.actionValue == "YES"
						$rhoconfig[:capture_counteroffer_response] = true
					else
						$rhoconfig[:capture_counteroffer_response] = false
					end
				when "FUW_APPLICABLE"
					if companyFacet && companyFacet.actionValue == "YES"
						$rhoconfig[:fuw_applicable] = true
					else
						$rhoconfig[:fuw_applicable] = false
					end
				when "MAJORAGE"
					$rhoconfig[:majorAge] = companyFacet
				when "MULTIDOCAPPLICABLE"
					$rhoconfig[:multiDocMode] = companyFacet
				when "PRDSELECTION"
					$rhoconfig[:prdSelection] = companyFacet
				when "CAPTURE_SIGNATURE_ON_SI_OUTPUT"
					if companyFacet && companyFacet.actionValue == "YES"
						$rhoconfig[:captureSignOnSIOutput] = true
					else
						$rhoconfig[:captureSignOnSIOutput] = false
					end
				when "APPOINTEEAGE"
					$rhoconfig[:appointeeAge] = companyFacet
				when "EAPPAPPLICABLE"
					$rhoconfig[:eappApplicable] = companyFacet
				when "ADDTNLSICOMPANYMODELSET"
					$rhoconfig[:addtnlSICompanyModelSet] = companyFacet
				when "ADDTNLEAPPCOMPANYMODELSET"
					$rhoconfig[:addtnlEAPPCompanyModelSet] = companyFacet
				when "ADDTNLLEADCOMPANYMODELSET"
					$rhoconfig[:addtnlLEADCompanyModelSet] = companyFacet
				when "NONFACETOFACE"
					$rhoconfig[:nonFaceToFace] = companyFacet
				end
			end
		end
	end	
end

class CollateralRenderLevelController < Rho::RhoController
	include BrowserHelper
	include MobiSys::BrowserHelper
    include MobiSys::UIHelper

    def fetch
        has_network = System::get_property('has_network') && MobiSys::BrowserHelper.detectConnection
        if has_network
	    	MobiSys::Sync.checkCollateralVersion unless @params.has_key?'levelCd'
	    end
    	count = CollateralRenderLevel.find(:count,:conditions => {:userId=>AgentReg.forUserId($userId, true).userId})
        if ($syncCollateral || count.to_i == 0) && has_network
            redirect :controller => :SyncCategory , :action =>:syncPreferences
        elsif ($syncCollateral || count.to_i == 0) && !has_network
        	Alert.show_popup({:title=>getLabelValue('COLLATERAL'),
	                :message=>getLabelValue('ERR_NETWORK'),
	                :buttons=>["OK"]})
        	WebView.navigate(url_for(:controller=> :Menu, :action => :landingPage))
        else
			@setLevelCd = @params['levelCd']
			if @setLevelCd == nil
				levelCdsFromAgentReg = AgentReg.getCurrentAgentReg().collateralLevelCd ? AgentReg.getCurrentAgentReg().collateralLevelCd.split(",") : []
				@setLevelCd = levelCdsFromAgentReg[0]
			end
			@collateralRenderLevelDO = CollateralRenderLevel.loadObject(:first,
				           :conditions => {
				           	:levelCd => @setLevelCd
				           }
				          )
			unless @collateralRenderLevelDO
				Alert.show_popup({:title=>getLabelValue('COLLATERAL'),
	                :message=>getLabelValue('collateralMissing'),
	                :buttons=>["OK"]})
            	WebView.navigate(url_for(:controller=> :Menu, :action => :landingPage))
			end
			@collateralRenderLevelChildDOList = CollateralRenderLevel.loadObject(:all,
				           :conditions => {
				           	:parentLevelCd => @collateralRenderLevelDO.levelCd
				           })
			@collateralRenderLevelChildDOList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}

			if @collateralRenderLevelDO.previousMenuFl.to_s == "YES"
				@parentColRenderLevelDO = CollateralRenderLevel.loadObject(:first,
					           :conditions => {
					           	:levelCd => @collateralRenderLevelDO.parentLevelCd
					           }
					          )
				@parentColRenderLevelChildDOList = CollateralRenderLevel.loadObject(:all,
					           :conditions => {
					           	:parentLevelCd => @parentColRenderLevelDO.levelCd
					           }
					          )
				@parentColRenderLevelChildDOList.sort!{|x,y| x.sortOrder.to_i<=>y.sortOrder.to_i}
			end

			@colRenderLevelToFindList = []
			@colRenderLevelToFindList += @collateralRenderLevelChildDOList if @collateralRenderLevelChildDOList
			@colRenderLevelToFindList += @parentColRenderLevelChildDOList if @parentColRenderLevelChildDOList
			@colRenderLevelToFindList << @collateralRenderLevelDO

			collateralCdToFind = []
			@colRenderLevelToFindList.each do |colRenderLevelDO|
				if colRenderLevelDO.icon != nil
					collateralCdToFind << colRenderLevelDO.icon
				end
			end
			collateralList = Collateral.loadObject(:all, 
				:conditions =>{
								{:name => 'collateralCd', :op => 'IN'} => collateralCdToFind
							})
			@collateralMap = Hash.new
			windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
			is_rho_simulator = Rho::System.isRhoSimulator
			collateralList.each do |collateral|
				if windows_platform
					filePath = File.join(Rho::Application.publicFolder, "collateral")
					filePath = File.join(filePath, collateral.fileName)
                    unless collateral.embedType.to_s == "EXTERNAL"
                        filePath = filePath[filePath.index("public")-1..-1]
                    end
				else
					if is_rho_simulator
                        filePath = File.join(Rho::RhoApplication.get_blob_folder, collateral.fileName)
                        unless collateral.embedType.to_s == "EXTERNAL"
                            filePath = filePath[filePath.index("rhosimulator")-1..-1]
                        end
                    else
                        filePath = File.join(Rho::RhoApplication.userFolder, collateral.fileName)
                    end
				end
                collateral.fileName = filePath
			 	@collateralMap[collateral.collateralCd] = collateral
			end
			collateralView = ("Collateral_"+@collateralRenderLevelDO.childLayoutTypeCd)
	       	if @params['ajaxCall'] && @params['ajaxCall']== "true"
	       		html = ""
	       		html << render(:action => collateralView.to_sym)
	       		return html
	       	else
	        	render :action => collateralView.to_sym, :layout => :jazzLayout
	        end
	    end
	end	
end

require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'rho/rhonativeviewmanager'
require 'CommonModules/mobisysbrowserhelper'
require 'CommonModules/syncmodule'


class CollateralController < Rho::RhoController
  	include BrowserHelper
  	include MobiSys::BrowserHelper

  	def fetchCollateral(collateralId)
  		collateralPath = Collateral.find(
  			:all, 
  			:conditions => { 
  				{
  					:name => "collateralCd", 
  					:op => "IN" 
				} => collateralId 
			} 
		)
  		return collateralPath
  	end


  	# GET /Collateral/showProductCollateral
  	def showProductCollateral
  		embedType = "INLINE"
		windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
		is_rho_simulator = Rho::System.isRhoSimulator

  		if @params['product'] != nil    
  			collateralDT = ProductDefinitionTable.find(:all, 
  				:conditions => { 
  					{ 
  						:name => 'productId', 
					} => @params['product'],
					{ 
						:name => 'facetId', 
					} => "COLLATERAL"
				},
				:op => 'AND'
			)
		end

  		if @params['planCode'] != nil
  			filteredProduct = ProductFiltering.loadObject(:first,
  				:conditions => {
  					{
  						:name => 'planCode'
					} => @params['planCode'],
				}
			)
  			filteredProductId = filteredProduct.productId if filteredProduct != nil

  			collateralDT = ProductDefinitionTable.find(:all, 
  				:conditions => { 
  					{ 
  						:name => 'productId' 
					} => filteredProductId,
					{
						:name => 'planCd'
					} => @params['planCode'],
					{ 
						:name => 'facetId', 
					} => "COLLATERAL"
				},
				:op => 'AND'
			)
  		end

  		if collateralDT != nil && collateralDT.size > 0 && collateralDT[0].collateralCd != nil
  			collateral = Collateral.find( :all, 
  				:conditions => { 
  					{ 
  						:name => 'collateralCd', 
					} => collateralDT[0].collateralCd
				}                                     
			)
  			if collateral.size > 0
  				if collateral[0].colStatus == 'PRESEEDED'
  					@mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral[0].fileName)
  				else
            		#Decode file
		            if collateral[0].fileEncrypted == 'YES'
		            	fileName = collateral[0].fileName
                		fileName = File.join(Rho::RhoApplication.get_blob_folder, fileName)
		            	encryptionIV = collateral[0].encryptionIv
		            	MobiSys::Encryption.decryptFile(fileName,encryptionIV)
		            end  
		            @mediaName = collateral[0].fileName
					if windows_platform
	                    @mediaName = File.join(Rho::RhoApplication.publicFolder,"collateral", @mediaName)
	                else
                    	if is_rho_simulator
                    		@mediaName = File.join(Rho::RhoApplication.get_blob_folder, @mediaName)
		                else
		                	@mediaName = File.join(Rho::RhoApplication.userFolder, @mediaName) 
		                end
	                end
        		end
		        @fileType = collateral[0].fileType
		        embedType = collateral[0].embedType
		    end
		end                                

		if embedType == "EXTERNAL"
			# works for apple
			#System.open_url @mediaName
			puts 'opening '+@mediaName
      		System.open_url @mediaName
  		else
  			render :action => :dialog
  		end
  	end
  
  
  	def showCollateral
  		embedType = "INLINE"
  		levelObject = @params['levelObject']
  		search = @params['search']
		windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
		is_rho_simulator = Rho::System.isRhoSimulator
  		if @params['cCd'] != nil    
  			collateral = Collateral.find( :first, 
  				:conditions => { 
  					{ 
  						:name => 'collateralCd', 
					} => @params['cCd']
				}
			)                                         
  		end


  		if collateral.colStatus == 'PRESEEDED'
  			@mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral.fileName)
  		else
          	#Decode file
          	if collateral.fileEncrypted == 'YES'
	          	fileName = collateral.fileName
	          	if windows_platform
                    fileName = File.join(Rho::RhoApplication.publicFolder,"collateral", fileName)
                else
                	if is_rho_simulator
                		fileName = File.join(Rho::RhoApplication.get_blob_folder, fileName)
	                else
	                	fileName = File.join(Rho::RhoApplication.userFolder, fileName) 
	                end
                end
        		
	          	encryptionIV = collateral.encryptionIv
	          	MobiSys::Encryption.decryptFile(fileName,encryptionIV)
          	end  
          	@mediaName = collateral.fileName
            if windows_platform
                @mediaName = File.join(Rho::RhoApplication.publicFolder,"collateral", @mediaName)
            else
            	if is_rho_simulator
            		@mediaName = File.join(Rho::RhoApplication.get_blob_folder, @mediaName)
                else
                	@mediaName = File.join(Rho::RhoApplication.userFolder, @mediaName) 
                end
            end
      	end
      	@fileType = collateral.fileType
      	embedType = collateral.embedType

    	# works for apple
    	#System.open_url @mediaName
    	puts 'opening '+@mediaName
    
    	System.open_url @mediaName
    	redirect '/app/Collateral/search?id='+levelObject+'&search='+search
	end
  
  
  	# GET /Collateral/showpopup
  	def showpopup
	  	embedType = "INLINE"

		windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
		is_rho_simulator = Rho::System.isRhoSimulator
	  	if @params['medianame'] != nil    
	  		collateral = Collateral.find(:all, 
	  			:conditions => { 
	  				{
	  					:name => "collateralCd", 
	  					:op => "IN" 
  					} => @params['medianame'] 
  				} 
			)
	  		if collateral.size > 0
	  			if collateral[0].colStatus == 'PRESEEDED'
	  				@mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral[0].fileName)
	  			else
	  				@mediaName = collateral[0].fileName
	  				if windows_platform
		                @mediaName = File.join(Rho::RhoApplication.publicFolder,"collateral", @mediaName)
		            else
		            	if is_rho_simulator
                    		@mediaName = File.join(Rho::RhoApplication.get_blob_folder, @mediaName)
		                else
		                	@mediaName = File.join(Rho::RhoApplication.userFolder, @mediaName) 
		                end
		            end
               end
	  			@fileType = collateral[0].fileType
	  			embedType = collateral[0].embedType
	  		end                                
	  	end

	  	if @params['levelCd'] != nil    
	  		collateral = Collateral.find(
	  			:all, 
	  			:conditions => { 
	  				{
	  					:name => "levelCd", 
	  					:op => "IN" 
  					} => @params['levelCd'] 
  				} 
			)
	  		if collateral.size > 0
	  			if collateral[0].colStatus == 'PRESEEDED'
	  				@mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral[0].fileName)
	  			else
	  				@mediaName = collateral[0].fileName
	  				if windows_platform
		                @mediaName = File.join(Rho::RhoApplication.publicFolder,"collateral", @mediaName)
		            else
		                if is_rho_simulator
		            		@mediaName = File.join(Rho::RhoApplication.get_blob_folder, @mediaName)
		                else
		                	@mediaName = File.join(Rho::RhoApplication.userFolder, @mediaName) 
		                end
		            end
                end
	  			@fileType = collateral[0].fileType
	  			embedType = collateral[0].embedType
	  		end

	  	end   

	  	if @params['collateralCd'] != nil    
	  		collateral = Collateral.find(
	  			:all, 
	  			:conditions => { 
	  				{
	  					:name => "collateralCd", 
	  					:op => "IN" 
  					} => @params['collateralCd'] 
  				} 
			)
	  		if collateral.size > 0
	  			if collateral[0].colStatus == 'PRESEEDED'
	  				@mediaName = File.join(Rho::RhoApplication.get_base_app_path(),collateral[0].fileName)
	  			else
	  				@mediaName = collateral[0].fileName
	  				if windows_platform
		                @mediaName = File.join(Rho::RhoApplication.publicFolder,"collateral", @mediaName)
		            else
		                if is_rho_simulator
		            		@mediaName = File.join(Rho::RhoApplication.get_blob_folder, @mediaName)
		                else
		                	@mediaName = File.join(Rho::RhoApplication.userFolder, @mediaName) 
		                end
		            end
                end
	  			@fileType = collateral[0].fileType
	  			embedType = collateral[0].embedType
	  		end

	  	end  

	  	if embedType == "EXTERNAL"
	      	# works for apple
	      	#System.open_url @mediaName
	      	puts 'opening '+@mediaName
	      
	     	System.open_url @mediaName
	  	else
	  		render :action => :dialog, :back => '../Level0/'
	  	end
	end

  
  	# GET /Collateral
  	def index
	    @collaterals = Collateral.find(:all)
	    render :back => '/app'
  	end
  
  
	def search
		@level0 =  Level0.find(@params['id'])
		@level0s = Level0.find(
			:all,
			:order => 'sortOrder',
			:orderdir => 'ASC'
		)
		@level1s = Level1.find(
			:all,
			:order => 'sortOrder',
			:orderdir => 'ASC'
		)

		@frameworkCollaterals =  Collateral.find(
			:all, 
			:conditions => { 
				{
					:name => "levelCd", 
					:op => "IS" 
				} => nil
			} 
		)

		@collateralHM = {}

		@frameworkCollaterals.each_with_index{|collateral,index|
			@collateralHM[collateral.collateralCd] = collateral  
		}
		renderToolbar(1)
		@searchValue = "%"+@params['search']+"%" if @params['search']

		cond1 = {
			:conditions => { 
				{
					:name => 'header',
					:op => 'LIKE' 
				} => @searchValue, 
				{ 
					:name => 'description',
					:op => 'LIKE'
				} => @searchValue
			}, 
			:op => 'OR'
		}

		cond2 = {
			:conditions => { 
				{
					:name => 'embedType', 
					:op => 'LIKE'
				} => 'EXTERNAL'
			}   
		} 


		@collaterals = Collateral.loadObject(
			:all,
			:conditions => [cond1, cond2], 
			:op => 'AND', 
			:select => ['collateralCd','header','description','fileName','levelCd']
		)
		puts "#{@collaterals}"
		@collaterals.each do |col|
			puts "just in loop"
			puts "#{col.levelCd}"
			if col.levelCd
				puts "inside if"
				@levelCode = col.levelCd
				@path = ""
				@level4 = Level4.find( :first, 
					:conditions => { 
						{ 
							:name => 'levelCd', 
						} => @levelCode
					}
				) 
				@level3 = Level3.find( :first, 
					:conditions => { 
						{ 
							:name => 'levelCd', 
						} => @levelCode
					}
				) 
				@level2 = Level2.find( :first, 
					:conditions => { 
						{ 
							:name => 'levelCd', 
						} => @levelCode
					}
				) 
				@level1 = Level1.find( :first, 
					:conditions => { 
						{ 
							:name => 'levelCd', 
						} => @levelCode
					}
				)
				@level0 = Level0.find( :first, 
					:conditions => { 
						{ 
							:name => 'levelCd', 
						} => @levelCode
					}
				)    
				if @level0 != nil
					@path = "" + @level0.name1+ @level0.name2 + @path
					col.path = @path
					col.persistAll
				elsif @level1 != nil
					@path = " > " + @level1.name + @path
					@level0 = Level0.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level1.level0_levelCd
						}
					)  
					@path = "" + @level0.name1+ @level0.name2 + @path 
					col.path = @path 
					col.persistAll  
				elsif @level2 != nil
					@path = " > " + @level2.header + @path
					@level1 = Level1.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level2.level1_levelCd
						}
					) 
					@path = " > " + @level1.name + @path
					@level0 = Level0.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level1.level0_levelCd
						}
					)  
					@path = "" + @level0.name1+ @level0.name2 + @path 
					col.path = @path
					col.persistAll
				elsif @level3 != nil
					@path = " > " + @level3.name + @path
					@level2 = Level2.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level3.level2_levelCd
						}
					) 
					@path = " > " + @level2.header + @path
					@level1 = Level1.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level2.level1_levelCd
						}
					) 
					@path = " > " + @level1.name + @path
					@level0 = Level0.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level1.level0_levelCd
						}
					)  
					@path = "" + @level0.name1+ @level0.name2 + @path 
					col.path = @path
					col.persistAll
				elsif @level4 != nil
					@path = " > " + @level4.name + @path
					@level3 = Level3.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level4.level3_levelCd
						}
					) 
					@path = " > " + @level3.name + @path
					@level2 = Level2.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level3.level2_levelCd
						}
					) 
					@path = " > " + @level2.header + @path
					@level1 = Level1.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level2.level1_levelCd
						}
					) 
					@path = " > " + @level1.name + @path
					@level0 = Level0.find( :first, 
						:conditions => { 
							{ 
								:name => 'levelCd', 
							} => @level1.level0_levelCd
						}
					)  
					@path = "" + @level0.name1+ @level0.name2 + @path 
					col.path = @path 
					col.persistAll                                                  
				end                 
				puts "#{@path}"
				puts "#{col.path}"   
			end          
		end

		puts "End of Search"
		render :action => :index
	end
	
	def openURL
		url = @params["url"]
		System.open_url url
	end
  
  
	def collateraldownload_callback
	  	fileName = @params["fileName"]
	  	filePath = @params["filePath"]
	  	downloadStatus = @params["status"]
	  	httpErrorCd = @params["http_error"]
	  	
	  	collateralList = Collateral.find(
	  		:all,
	  		:conditions=>{
	  			{
	  				:name => "collateralCd",
	  				:op => "IN"
	  			} => $collateralDownloadHash[fileName].split(",")
	  		}
	  	)
	  	begin
	  		if downloadStatus == "ok" and httpErrorCd != 404
				#File download successfull. Change the filename from URL to local path.
				windows_platform = System.get_property('platform') == 'WINDOWS_DESKTOP'
				is_rho_simulator = Rho::System.isRhoSimulator
				# for windows platform moving files from downloads to collateral folder as images require relative path.
				if windows_platform
					destFilePath = File.join(Rho::Application.publicFolder, "collateral")
					Dir.mkdir(destFilePath) unless Dir.exist?(destFilePath)
					destFilePath = File.join(destFilePath, fileName)

					fileCopyStatus = Rho::RhoFile.copy(filePath, destFilePath)
					
					if fileCopyStatus == 0
						File.delete(filePath) 
						collateralList.each do |collateral|
							unless $rhoconfig[:useCollateralRenderLevel]
								if is_rho_simulator
		                            if collateral.embedType.to_s == "EXTERNAL"
		                                collateral.fileName = destFilePath
		                            else
		                                collateral.fileName = destFilePath[destFilePath.index("public")-1..-1]
		                            end
		                        else
									if collateral.embedType.to_s == "EXTERNAL"
			                            collateral.fileName = destFilePath
			                        else
			                            collateral.fileName = destFilePath[destFilePath.index("public")-1..-1]
			                        end
			                    end
			                else
                            	collateral.fileName = fileName
			                end
		                    collateral.colStatus = "COMPLETED"
                    		collateral.persistAll
						end
					end
				else
					fileCopyStatus = 0
					unless is_rho_simulator
						destFilePath = Rho::Application.userFolder
						Dir.mkdir(destFilePath) unless Dir.exist?(destFilePath)
						destFilePath = File.join(destFilePath, fileName)

						fileCopyStatus = Rho::RhoFile.copy(filePath, destFilePath)
					end
					if fileCopyStatus == 0
						unless is_rho_simulator
							File.delete(filePath) 
						end
						collateralList.each do |collateral|
							unless $rhoconfig[:useCollateralRenderLevel]
								if is_rho_simulator
		                         	if collateral.embedType.to_s == "EXTERNAL"
		                            	collateral.fileName = filePath
			                        else
			                            collateral.fileName = filePath[filePath.index("rhosimulator")-1..-1]
			                        end
			                    else
			                		#check for embedType = "EXTERNAL" if it does not work then trim the file name.
			                        collateral.fileName = destFilePath
			                    end
			                else
	                        	collateral.fileName = fileName
			                end
		                    collateral.colStatus = "COMPLETED"
	                    	collateral.persistAll
						end
					end
				end
				$collateralDownloadHash.delete(fileName)
			else
				#Delete the offline collateral data object since file download has failed.
				collateralList.each do |collateral|
					collateral.destroy
				end
				$collateralDownloadHash.delete(fileName)
				$collateralSyncFailed = $collateralSyncFailed + 1
				File.delete(filePath+".rhodownload") if File.exists?(filePath+".rhodownload")
			end
			$syncLogHash['CollateralDownload'].recordsProcessed = $syncLogHash['CollateralDownload'].recordsProcessed + 1
            MobiSys::Sync.refreshDownloadUI
			# $syncLogHash['Collateral'].recordsProcessed = $syncLogHash['Collateral'].recordsProcessed + 1
		rescue StandardError => se
			puts se
		end
		$syncLogHash['CollateralDownload'].status = "Completed" if $collateralDownloadHash.empty?
		if $collateralDownloadHash.empty? and $collateralSyncFailed == 0
			lastCollateralSyncDate = Application.getValue('LASTCOLLATERALSYNCDATE')
			if lastCollateralSyncDate
				Application.updateValue('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
			else
				Application.create('LASTCOLLATERALSYNCDATE',Time.dump(Time.now))
			end
			if defined? $onlineCollateralVersion 
                Application.updateValue('COLLATERALVERSION', $onlineCollateralVersion) if $onlineCollateralVersion.to_s != ''
            end
			label = MobiSys::BrowserHelper.getLabel("COLLATERAL") + " " + MobiSys::BrowserHelper.getLabel("SUCCESS") 
            Alert.show_popup({:title=>'', :message=>label, :buttons=>["Ok"] })
			WebView.navigate($rhoconfig[:post_login_path]) if $collateralDownloadHash.empty? and $masterSyncCompleted and $outputImagesSyncCompleted
		elsif $collateralDownloadHash.empty? and $collateralSyncFailed > 0
			Alert.show_popup({
				:title=>'',
				:message=>getLabelValue('COLLATERALSYNCFAILEDMESSAGE'),
				:buttons=>["Ok"],
				:callback=>url_for(:controller=>:SyncCategory, :action=>:transactionpopupcallback)
			})
        	WebView.navigate('/app/SyncCategory/syncPreferences')
		end
	end
end
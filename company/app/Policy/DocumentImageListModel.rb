require 'CommonClasses/BaseModel'

module MobiSys
	
	class DocumentImageListModel < BaseModel

		def initialize(io)
            #puts "~~~in DocumentImageListModel initialize: #{io.inspect}"
            super(io)
            #puts "~~~baseIO:#{self.baseIO}"
        end

		def getModel
			#logInfo "~~~baseIO in DocumentImageListModel:#{self.baseIO.inspect}"
			#logInfo("~~~in self.parentBaseDO : #{self.parentBaseDO.class.name}")
		    documentImageList = DocumentImage.getDocumentImages(self.parentBaseDO.guid)

			return documentImageList
		end

		def setModel(entity)
			if entity && entity.size > 0 && self.parentBaseDO.removed.to_s != "YES"
				images = Image.loadObject(:all, :conditions => {{:name=>'parentRefGuid'} => self.parentBaseDO.guid})
				entityObjects = entity.map(&:object)
				imagesToBeDeleted = images.select do |img|
					!entityObjects.include?(img.object)
				end

				imagesToBeDeleted.each do |image|
					deleteExtraImages(image)
				end
				count = 0
				entity.each do |ent|
					if ent.removed.to_s != "YES"
						image = nil
						offlineFile = nil
						serviceDoc = self.parentBaseDO
						image = images.select{|m| m if m.object == ent.object}.first
						isNewImage = false
							
						if image == nil
							isNewImage = true
				            serviceDoc.imageCount = serviceDoc.imageCount.to_i + 1
				            serviceDoc.acceptanceStatusCd = 'FULFILLED'
				            serviceDoc.receivedDt = Time.now
				            image = Image.new
				            offlineFile = OfflineFile.new
				            image.object = ent.object
				            image.addOfflineFile(offlineFile)
				            image.parentRefGuid = serviceDoc.guid
						end
				        image.dateTimeTaken = Time.now
						image.latitude = ent.latitude
			            image.longitude = ent.longitude
			            offlineFile = image.OfflineFileList[0]
			            fileExtension = ent.fileLocation.split('.').last
			            documentCd = self.parentBaseDO.documentCd
			            countStr = count
			            countStr = "" if count == 0
						fileName = "#{documentCd}#{countStr.to_s}_#{$userId}_#{Date.today.strftime("%Y%m%d")}_#{Time.now.strftime("%Y%m%d%H%M%S")}.#{fileExtension}"
			            count = count + 1
			            offlineFile.fileLocation = fileName

			            if $rhoconfig.has_key?(:encrypt_images) and $rhoconfig[:encrypt_images]=='YES' and ent.fileContents.to_s != ""
			            	parts = ent.fileContents.rpartition('|')
			            	offlineFile.fileContents = parts[0]
			            	offlineFile.encryptionIv = parts[2]
			            	offlineFile.fileEncrypted = "YES"
			            else
			            	offlineFile.fileEncrypted = 'NO'  
			            	offlineFile.fileContents = ent.fileContents
			            end
			            offlineFile.md5Hash = MobiSys::Encryption.digest(offlineFile.fileContents) if offlineFile.fileContents.to_s != ""
			           
	        			if $isSaveAction
		        			image.persistAll
				            serviceDoc.persistAll
				        end

			            if isNewImage and self.parentBaseDO.ocrCheckReqd.to_s == "YES"
			            	persistOcr = true
			            	imageBase64 = offlineFile.fileContents
			            	begin
			            		MobiSys::BrowserHelper.setOcrDetails(persistOcr,offlineFile)
			            		extractedData = MobiSys::BrowserHelper.documentTextDetection(imageBase64, false, nil, "updateOcrExtractedText")
			            	rescue NoMethodError => nme
								#Ignore. Calling controller has not implemented imageCaptured(image) method
							end
						end
						# currentUIimg[ent.guid] = image
					else
						image = images.select{|m| m if m.object == ent.object}.first
						deleteExtraImages(image)
					end
				end
			end

			return entity
		end

		def deleteExtraImages(image)
			if image
				File.delete(image.OfflineFileList[0].fileLocation) if File.exist?(image.OfflineFileList[0].fileLocation)
	            image.OfflineFileList[0].destroy
	            image.destroy

	            self.parentBaseDO.imageCount = (self.parentBaseDO.imageCount.to_i - 1) if self.parentBaseDO.imageCount.to_i > 0
				self.parentBaseDO.persistAll if $isSaveAction
			end
		end

	end
end

begin 
    require 'Policy/DocumentImageListModel_company'
rescue LoadError => e
    puts 'DocumentImageListModel_company not included'
end
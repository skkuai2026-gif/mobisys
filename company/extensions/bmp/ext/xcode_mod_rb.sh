#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

puts "~~~~1111 bmp"
# Copy Frameworks to project folder
FileUtils.copy_entry("platform/iphone/Frameworks", "../../../project/iphone/Frameworks", true, true, true)

puts "~~~~2222 bmp"

# Formulate a list of Frameworks
framework_files = Dir["../../../project/iphone/Frameworks/**/*.framework"]

# Print Framework list
puts framework_files


# # Copy Resources to project folder
# FileUtils.copy_entry("platform/iphone/Resources", "../../../project/iphone/Resources", true, true, true)

# # Formulate a list of Resources
# resources_files = Dir["../../../project/iphone/Resources/**/*.bundle"]

# # Print Resources list
# puts resources_files

# Get Xcode project
xcode_project = Dir["../../../project/iphone/*.xcodeproj"].last

# Print Xcode project path
puts xcode_project

project = Xcodeproj::Project.open(xcode_project)


# Add Frameworks to Xcode project
frameworkGroup = project.frameworks_group
# Get the build phase
framework_buildphase = project.objects.select{|x| x.class == Xcodeproj::Project::Object::PBXFrameworksBuildPhase}[0];
existingFrameworkList = frameworkGroup.files.collect{|x| x.path.to_s}
framework_files.each do |framework|
	framework = File.join("Frameworks", File.basename(framework))
	puts "Processing : #{framework}"
	unless existingFrameworkList.include?(File.basename(framework))
		libRef = frameworkGroup.new_reference(framework)
		# Add it to the build phase
		framework_buildphase.add_file_reference(libRef)
	end
end


# # Add Resources to Xcode project
# resourcesGroup = project['Resources']
# # Get the build phase
# resources_buildphase = project.objects.select{|x| x.class == Xcodeproj::Project::Object::PBXResourcesBuildPhase}[0];
# existingResourcesList = resourcesGroup.files.collect{|x| x.path.to_s}
# resources_files.each do |resource|
# 	resource = File.join("Resources", File.basename(resource))
# 	puts "Processing : #{resource}"
# 	unless existingResourcesList.include?(File.basename(resource))
# 	File.basename(resource)
# 		resRef = resourcesGroup.new_reference(resource, :group)
# 		# Add it to the build phase
# 		resources_buildphase.add_file_reference(resRef)
# 	end
# end


# Add System Frameworks to Xcode project
# unless existingFrameworkList.include?('System/Library/Frameworks/LocalAuthentication.framework')
# 	libRef = frameworkGroup.new_reference('System/Library/Frameworks/LocalAuthentication.framework')
# 	framework_buildphase.add_file_reference(libRef)
# end
# unless existingFrameworkList.include?('System/Library/Frameworks/StoreKit.framework')
# 	libRef = frameworkGroup.new_reference('System/Library/Frameworks/StoreKit.framework')
# 	framework_buildphase.add_file_reference(libRef)
# end
unless existingFrameworkList.include?('System/Library/Frameworks/Accelerate.framework')
	libRef = frameworkGroup.new_reference('System/Library/Frameworks/Accelerate.framework')
	framework_buildphase.add_file_reference(libRef)
end
# unless existingFrameworkList.include?('System/Library/Frameworks/CoreImage.framework')
# 	libRef = frameworkGroup.new_reference('System/Library/Frameworks/CoreImage.framework')
# 	framework_buildphase.add_file_reference(libRef)
# end


# Set Other Linker flags
project.targets.each do |target|
	target.build_configurations.each do |config|
		config.build_settings["OTHER_LDFLAGS[sdk=*][arch=*]"] = "-ObjC -filelist rhodeslibs.txt"
		config.build_settings["OTHER_LDFLAGS"] = "-ObjC -filelist rhodeslibs.txt"
	end
end


# # Add GoogleService-Info.plist to Xcode project
# infoPlistPresent = false
# project.main_group.files.each do |file|
# 	if file.path == 'GoogleService-Info.plist'
# 		infoPlistPresent = true
# 		break
# 	end
# end
# unless infoPlistPresent
# 	infoPlistRef = project.main_group.new_file('GoogleService-Info.plist')
# 	resources_buildphase.add_file_reference(infoPlistRef)
# end


project::save()
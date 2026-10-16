#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

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


# Add System Frameworks to Xcode project
unless existingFrameworkList.include?('System/Library/Frameworks/LocalAuthentication.framework')
	libRef = frameworkGroup.new_reference('System/Library/Frameworks/LocalAuthentication.framework')
	framework_buildphase.add_file_reference(libRef)
end


project::save()
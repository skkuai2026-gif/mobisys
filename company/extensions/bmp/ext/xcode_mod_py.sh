#!/usr/bin/env python
import os

from distutils.dir_util import copy_tree
from glob import glob
from pbxproj import XcodeProject
from pbxproj.pbxextensions.ProjectFiles import FileOptions

# Copy Frameworks to project folder
copy_tree("platform/iphone/Frameworks", "../../../project/iphone/Frameworks")

# Formulate a list of Frameworks
framework_files = [y for x in os.walk("../../../project/iphone/Frameworks") for y in glob(os.path.join(x[0], '*.framework'))]

# Print Framework list
print framework_files


# Copy Resources to project folder
copy_tree("platform/iphone/Resources", "../../../project/iphone/Resources")

# Formulate a list of Resources
resources_files = [y for x in os.walk("../../../project/iphone/Resources") for y in glob(os.path.join(x[0], '*.bundle'))]

# Print Resources list
print resources_files


# Get Xcode project
for file in os.listdir("../../../project/iphone"):
    if file.endswith(".xcodeproj"):
    	xcode_project = os.path.join(os.path.join("../../../project/iphone", file), "project.pbxproj")

# Print Xcode project path
print xcode_project

project = XcodeProject.load(xcode_project)

# Add Frameworks to Xcode project
frameworkGroup = project.get_or_create_group('Frameworks')
framework_file_options = FileOptions(weak=False, embed_framework=False)
for framework in framework_files:
	print "Processing :"+os.path.join("Frameworks", os.path.basename(framework))
	project.add_file(os.path.join("Frameworks", os.path.basename(framework)), parent=frameworkGroup, force=False, file_options=framework_file_options)


# Add Resources to Xcode project
resourcesGroup = project.get_or_create_group('Resources')
resource_file_options = FileOptions(weak=False)
for resource in resources_files:
	print "Processing :"+os.path.join("Resources", os.path.basename(resource))
	project.add_file(os.path.join("Resources", os.path.basename(resource)), parent=resourcesGroup, force=False, file_options=resource_file_options)


# Add System Frameworks to Xcode project
project.add_file('System/Library/Frameworks/LocalAuthentication.framework', parent=frameworkGroup, tree='SDKROOT', force=False, file_options=framework_file_options)
project.add_file('System/Library/Frameworks/StoreKit.framework', parent=frameworkGroup, tree='SDKROOT', force=False, file_options=framework_file_options)
project.add_file('System/Library/Frameworks/Accelerate.framework', parent=frameworkGroup, tree='SDKROOT', force=False, file_options=framework_file_options)
project.add_file('System/Library/Frameworks/CoreImage.framework', parent=frameworkGroup, tree='SDKROOT', force=False, file_options=framework_file_options)


# Set Other Linker flags
project.set_flags('OTHER_LDFLAGS[sdk=*][arch=*]', ['-ObjC','-filelist','rhodeslibs.txt'])
project.add_other_ldflags(['-ObjC','-filelist','rhodeslibs.txt'])


# Add GoogleService-Info.plist to Xcode project
project.add_file('GoogleService-Info.plist', force=False)

project.save()
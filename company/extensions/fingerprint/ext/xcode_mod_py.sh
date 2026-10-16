#!/usr/bin/env python
import os

from pbxproj import XcodeProject
from pbxproj.pbxextensions.ProjectFiles import FileOptions

# Get Xcode project
for file in os.listdir("../../../project/iphone"):
    if file.endswith(".xcodeproj"):
    	xcode_project = os.path.join(os.path.join("../../../project/iphone", file), "project.pbxproj")

# Print Xcode project path
xcode_project = os.path.abspath(xcode_project)
print xcode_project

# Add Frameworks to Xcode project
project = XcodeProject.load(xcode_project)
frameworkGroup = project.get_or_create_group('Frameworks')
file_options = FileOptions(weak=False,embed_framework=False)
project.add_file('System/Library/Frameworks/LocalAuthentication.framework', parent=frameworkGroup, tree='SDKROOT', force=False, file_options=file_options)
project.save()
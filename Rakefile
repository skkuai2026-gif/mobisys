require 'yaml'
require 'fileutils'

if Rake.application.top_level_tasks.to_s.include?("rhosimulator")
	if File.exists? "company/build_rhosimulator.yml"
		$app_config = YAML::load_file("company/build_rhosimulator.yml")
	else
		$app_config = YAML::load_file("framework/build_rhosimulator.yml")
	end
elsif Rake.application.top_level_tasks.to_s.include?("win32")
	if File.exists? "company/build_win32.yml"
		$app_config = YAML::load_file("company/build_win32.yml")
	else
		$app_config = YAML::load_file("framework/build_win32.yml")
	end
elsif Rake.application.top_level_tasks.to_s.include?("android")
	if File.exists? "company/build_android.yml"
		$app_config = YAML::load_file("company/build_android.yml")
	else
		$app_config = YAML::load_file("framework/build_android.yml")
	end
elsif Rake.application.top_level_tasks.to_s.include?("iphone")
	if File.exists? "company/build_iphone.yml"
		$app_config = YAML::load_file("company/build_iphone.yml")
	else
		$app_config = YAML::load_file("framework/build_iphone.yml")
	end
else
	$app_config = YAML::load_file("build.yml")
end

$isSdkBuild = false
File.open('rhoconfig.txt').each do |line|
	$isSdkBuild = true if line.include?("create_sdk_build") && line.split("=")[1].strip == "1"
end

$app_path = File.expand_path(File.dirname(__FILE__))

class Dir
	def self.mkdir_r(directory)
		tree = directory.split("/")
		# puts tree.to_s
		path = ""
		tree.each_with_index do |dir, index|
			if index == 0
				path = dir
			else  
				path = File.join(path, dir)
			end  
			unless Dir.exists? path
				Dir.mkdir path
			end
		end
	end
end


def processFolder(dir, bool)
	files = Dir["#{dir}/**/*"].reject{|f| f =~ /\.framework\/./}
	files.each do |file|
		#Skip copying public/lib folder for all builds except windows
		next if file.include?("/lib/") && !Rake.application.top_level_tasks.to_s.include?("win32")
		
		#Skip copying public/static folder
		next if file.include?("/static/") || file.include?("/public/collateral/") || (file.include?("/public/tessdata/") && (!$app_config || !$app_config['extensions'].include?("ocr")))

		tree = file.gsub("#{dir}/","").split("/")
		next if tree[0] == "extensions" && (!$app_config || !$app_config['extensions'].include?(tree[1].to_s.downcase))

		# Skip copying non api controller files for sdk build
		next if $isSdkBuild && file.include?("_controller") && !file.include?("_rest_controller")

		# Skip copying erb and js files for sdk build
		next  if $isSdkBuild && (file.include?(".erb") || file.include?(".js")) && !file.include?("public")

		#Skip copying public folder for sdk build
		next if $isSdkBuild && file.include?("/public/") && !file.include?("/public/images/outputimages") && !file.include?("/public/images/SalesIllustration") && !file.include?("/public/fonts") && !file.include?("/public/jazz") && !file.include?("/public/images/output") && !file.include?("/public/jquery/jquery-3.7.1.min.js") && !file.include?("/public/js/RGraph") && !file.include?("/public/css")

		if File.directory?(file)
			if file.include?(".framework")
				FileUtils.copy_entry(file, file.gsub("#{dir}/",""), true, false, true)
			else
				dir_file = file.gsub("#{dir}/","")
				if dir_file.length > 0
					unless Dir.exists? dir_file
						Dir.mkdir_r(dir_file)
					end
				end
			end
		else
			newFileName = file.gsub("#{dir}/","")
			newFileName.gsub!("_rest_controller","_controller") if $isSdkBuild && !newFileName.include?("base_rest_controller") && newFileName.include?("_rest_controller")
			dir_file = newFileName.rpartition('/')[0]
			if dir_file.length > 0
				unless Dir.exists? dir_file
					Dir.mkdir_r(dir_file)
				end
			end
			if bool
				if File.mtime(file) > File.mtime('timestamp.txt')
					FileUtils.cp(file, newFileName)
					puts ">>>Copying #{file} to #{newFileName}"
				end  
			else
				FileUtils.cp(file, newFileName)
				puts ">>>Copying #{file} to #{newFileName}"
			end  
		end
	end
end


#Check if rake command is used for production cleaning
if Rake.application.top_level_tasks.to_s.include?("clean")
	#Delete timestamp & clear root folder contents
	puts ">>>Deleting timestamp.txt"
	FileUtils.rm_rf("timestamp.txt", :secure => true)
	puts ">>>Clearing app folder"
	FileUtils.rm_rf(Dir.glob('app/*'), :secure => true)
	puts ">>>Clearing public folder"
	FileUtils.rm_rf(Dir.glob('public/*'), :secure => true)
	puts ">>>Clearing icon folder"
	FileUtils.rm_rf(Dir.glob('icon/*'), :secure => true)
	puts ">>>Clearing extensions folder"
	FileUtils.rm_rf(Dir.glob('extensions/*'), :secure => true)
	puts ">>>Deleting project folder"
	FileUtils.rm_rf("project", :secure => true)
end


#Check if timestamp.txt exists & copy content
bool = File.exists? "timestamp.txt"
processFolder("framework", bool)
processFolder("functional", bool)
processFolder("company",bool)


#Use build.yml based on mode and platform of app execution
if Rake.application.top_level_tasks.to_s.include?("rhosimulator") && (File.exists? "build_rhosimulator.yml" )
	File.rename("build_rhosimulator.yml", "build.yml")
elsif Rake.application.top_level_tasks.to_s.include?("win32") && (File.exists? "build_win32.yml")
	File.rename("build_win32.yml", "build.yml")
elsif Rake.application.top_level_tasks.to_s.include?("android") && (File.exists? "build_android.yml")
	File.rename("build_android.yml", "build.yml")
elsif Rake.application.top_level_tasks.to_s.include?("iphone") && (File.exists? "build_iphone.yml") 
	File.rename("build_iphone.yml", "build.yml")
end


unless File.exists? "build.yml"
	puts "Cannot find build.yml"
	exit 1
end


#Create/Update timestamp.txt file
FileUtils.touch('timestamp.txt')


if ENV["RHO_HOME"].nil?
	if $app_config["sdk"] 
		rakefilepath = "#{$app_config["sdk"]}/Rakefile"
	else
		begin
			rakefilepath = `get-rhodes-info --rhodes-path`.chomp
			rakefilepath  = File.join(rakefilepath, "Rakefile")
		rescue
			rakefilepath  = ""	
		end
	end  
else
	rakefilepath = "#{ENV["RHO_HOME"]}/Rakefile"
end


unless File.exists? rakefilepath
	puts "\nCannot find your Rhodes gem or source path: #{rakefilepath}"
	puts "\nIf you have the sdk on your path or have installed the gem this"
	puts "can be resolved by running 'set-rhodes-sdk'"
	puts "\nYou can also set this manually by modifying your build.yml or"
	puts "setting the environment variable RHO_HOME"
	exit 1
end


load rakefilepath
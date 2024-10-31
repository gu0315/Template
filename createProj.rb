require 'xcodeproj'
require 'fileutils'
require 'digest'


NAME = ARGV.at(0);
BUNDLEID = ARGV.at(1);
DIR = ARGV.at(2);

def createProj()
    # 创建指定目录
    project_dir = "#{DIR}/#{NAME}"
    FileUtils.mkdir_p(project_dir);
    # 创建Example.xcodeproj工程文件，并保存
    Xcodeproj::Project.new("#{project_dir}/#{NAME}.xcodeproj").save
    # 打开创建的Example.xcodeproj文件
    proj = Xcodeproj::Project.open("#{project_dir}/#{NAME}.xcodeproj")
    # 创建一个分组，名称为Example，对应的路径为./Example
    group = proj.main_group.new_group("#{NAME}", "#{project_dir}/#{NAME}")
    # 文件
    filesInTarget = Array[
        "AppDelegate.swift",
        "ViewController.swift",
        "Base.lproj/LaunchScreen.storyboard",
        "Base.lproj/Main.storyboard",
        "Assets.xcassets",
        "#{NAME}-Bridging-Header.h"
    ];
    # 创建target，主要的参数 type: application :dynamic_library framework :static_library 意思大家都懂的
    target = proj.new_target(:application, "#{NAME}", :ios)
    sourceFiles = []
    # 将文件加入到target中
    filesInTarget.each do |file|
        fr = group.new_reference(file)
        
        if fr.path.include?(".bundle") || fr.path.include?(".storyboard") || fr.path.include?(".xcassets")
            unless target.resources_build_phase.include?(fr)
                build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
                build_file.file_ref = fr
                target.resources_build_phase.files << build_file
            end
        elsif fr.path.include?(".h") || fr.path.include?("-Bridging-Header.h")
            headerPhase = target.headers_build_phase
            unless headerPhase.build_file(fr)
                build_file = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
                build_file.file_ref = fr
                build_file.settings = { 'ATTRIBUTES' => ['Public'] }
                headerPhase.files << build_file
            end
        else
            sourceFiles << fr
        end
    end
    
    group.new_reference("Info.plist");
    # target添加相关的文件引用，这样编译的时候才能引用到
    target.add_file_references(sourceFiles)
    # copy build_configurations
    target.add_build_configuration('Inhouse', :release)
    proj.add_build_configuration("Inhouse", :release)

    # 添加target配置信息
    target.build_configuration_list.set_setting('INFOPLIST_FILE', "$(SRCROOT)/#{NAME}/Info.plist")
    target.build_configuration_list.set_setting("VALID_ARCHS", "$(ARCHS_STANDARD)");
    target.build_configuration_list.set_setting("SWIFT_VERSION", "5.0");
    target.build_configuration_list.set_setting("MARKETING_VERSION", "1.0");
    target.build_configuration_list.set_setting("PRODUCT_BUNDLE_IDENTIFIER", "#{BUNDLEID}");
    target.build_configuration_list.set_setting('SWIFT_OBJC_BRIDGING_HEADER', "$(SRCROOT)/#{NAME}-Bridging-Header.h")

    #recreate schemes
    proj.recreate_user_schemes(visible = true)
    # create scheme
    inhouseScheme = Xcodeproj::XCScheme.new
    inhouseScheme.add_build_target(target)
    inhouseScheme.set_launch_target(target)
    inhouseScheme.launch_action.build_configuration = 'Inhouse'
    inhouseScheme.archive_action.build_configuration = 'Inhouse'
    inhouseScheme.save_as(proj.path, "#{NAME}-Inhouse")

    releaseScheme = Xcodeproj::XCScheme.new
    releaseScheme.add_build_target(target)
    releaseScheme.set_launch_target(target)
    releaseScheme.save_as(proj.path, "#{NAME}-Release")

    #设置target相关配置
    proj.build_configurations.map do |item|
        item.build_settings["SWIFT_VERSION"] = "5.0"
        if item.name == "Inhouse"
            # item.build_settings.update(proj.build_settings("Inhouse"))
            item.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = 'INHOUSE=1'
            item.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'Inhouse'
            item.build_settings['BUNDLE_ID_SUFFIX'] = '.Inhouse'
        end
        if item.name == "Release"
            item.build_settings.update(proj.build_settings("Release"))
            item.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = 'RELEASE=1'
            item.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'Release'
            item.build_settings['BUNDLE_ID_SUFFIX'] = '.Release'
        end
    end
    #  build_configurations
    target.build_configurations.map do |item|
        #设置target相关配置
        item.build_settings["SWIFT_VERSION"] = "5.0"
        if item.name == "Inhouse"
            item.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "#{BUNDLEID}.Inhouse"
        end
    end
    # 保存
    proj.save
end

#脚本入口
def execute
    # createModuleLib
    createProj
end

execute

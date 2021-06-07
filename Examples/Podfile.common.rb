$generate_multiple_pod_projects = false

$osx_platform = "10.10"
$ios_platform = "12.0"
$tvos_platform = "12.0"

$repo = "file://" + File.expand_path("../../", Dir.pwd) + "/.git"

def tweaks
  post_install do |installer|
    # Change settings per build config
    installer.pods_project.targets.each do |target|

      # Change settings per target, per build configuration
      target.build_configurations.each do |config|        
        config.build_settings.delete("ARCHS")
        
        config.build_settings["MACOSX_DEPLOYMENT_TARGET"] = $osx_platform
        config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = $ios_platform
        config.build_settings["TVOS_DEPLOYMENT_TARGET"] = $tvos_platform
      end

    end
  end
end
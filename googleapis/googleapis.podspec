Pod::Spec.new do |s|
  s.name     = 'googleapis'
  s.version  = '0.0.1'
  s.license  = 'Apache 2.0'
  s.authors  = { 'Google Inc.' => 'timburks@google.com'}
  s.homepage = 'http://github.com/GoogleCloudPlatform/ios-docs-samples'
  s.source   = { :git => 'https://github.com/GoogleCloudPlatform/ios-docs-samples.git',
                 :tag => '0.0.1' }
  s.summary  = 'Service definitions for Google Cloud Platform APIs'	  

  s.ios.deployment_target = '7.1'
  s.osx.deployment_target = '10.9'

  # Run protoc with the Objective-C and gRPC plugins to generate protocol messages and gRPC clients.
  # You can run this command manually if you later change your protos and need to regenerate.
  s.prepare_command = "protoc --objc_out=. --objcgrpc_out=. google/*/*.proto google/*/*/*.proto google/*/*/*/*.proto"

  # The --objc_out plugin generates a pair of .pbobjc.h/.pbobjc.m files for each .proto file.
  s.subspec "Messages" do |ms|
    ms.source_files = "google/**/*.pbobjc.{h,m}"
    ms.header_mappings_dir = "."
    ms.requires_arc = false
    ms.dependency "Protobuf", "~> 3.0.0-beta-3"
    ms.pod_target_xcconfig = {
         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    }
  end

  # The --objcgrpc_out plugin generates a pair of .pbrpc.h/.pbrpc.m files for each .proto file with
  # a service defined.
  s.subspec "Services" do |ss|
    ss.source_files = "google/**/*.pbrpc.{h,m}"
    ss.header_mappings_dir = "."
    ss.requires_arc = true
    ss.dependency "gRPC-ProtoRPC", "~> 0.14"
    ss.dependency "#{s.name}/Messages"
  end
end


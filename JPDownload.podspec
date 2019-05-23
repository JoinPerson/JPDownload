Pod::Spec.new do |s|
  s.name         = 'JPDownload'
  s.version      = '0.0.1'
  s.summary      = '一个用于下载的工具里面包含一次性下载、分片下载、断点续传，可以根据业务需要选择相对应的下载功能'
  s.homepage     = 'https://github.com/JoinPerson/JPDownload'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = {'JoinPerson' => '867480592@qq.com'}
  s.platform     = :ios, '8.0'
  s.source       = {:git => 'https://github.com/JoinPerson/JPDownload.git', :tag => s.version}
  s.source_files = 'JPDownload/Classes/*.{h,m}'
  s.public_header_files = 'JPDownload/Classes/*.h'
end

Pod::Spec.new do |spec|
  spec.name         = 'Drawsana'
  spec.version      = '0.12.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://asana.github.io/Drawsana'
  spec.documentation_url = 'https://asana.github.io/Drawsana'
  spec.authors      = { 'Steve Landey' => 'stevelandey@asana.com' }
  spec.summary      = 'Let your users mark up images with freehand drawings, shapes, and text'
  spec.source       = { :git => 'https://github.com/asana/Drawsana.git', :tag => '0.12.0' }
  spec.source_files = 'Drawsana/**/*.swift'

  spec.platform 	= :ios, '11.0'

  spec.swift_version = '5.2'
end

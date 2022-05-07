Pod::Spec.new do |s|
  s.name             = "MuPDF"
  s.version          = "1.11"
  s.summary          = "A lightweight PDF and XPS viewer."
  s.description      = <<-DESC
                       MuPDF is a small, fast, and yet complete PDF viewer. 
                       It supports PDF 1.7 with transparency, encryption, 
                       hyperlinks, annotations, searching and more. It also
                       reads XPS and OpenXPS documents.
  DESC
  s.homepage         = "http://www.mupdf.com/"
  s.license          = { :type => "Affero GNU GPL v3", :file => 'COPYING' }
  s.author           = "Artifex Software Inc"
  s.source           = { :git => "https://github.com/ArtifexSoftware/mupdf.git", :tag => s.version.to_s }

  s.platform     = :ios, '8.0'

  s.subspec 'Core' do |ss|
    ss.vendored_libraries = "libs/*.a"
    ss.source_files = 'libmupdf/include/**/*.h'
    ss.header_mappings_dir = 'libmupdf/include/mupdf'
  end

  s.subspec 'View' do |ss|
    ss.requires_arc= false
    ss.dependency 'MuPDF/Core'
    ss.source_files = 'SpecClasses/**/*.{h,m}'
  end
end


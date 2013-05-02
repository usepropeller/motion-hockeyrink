# -*- encoding: utf-8 -*-

Version = "0.1.2"

Gem::Specification.new do |spec|
  spec.name = 'motion-hockeyrink'
  spec.summary = 'HockeyApp integration for RubyMotion projects'
  spec.description = "motion-hockeyrink allows RubyMotion projects to easily embed the HockeyApp SDK and be submitted to HockeyApp."
  spec.author = 'Clay Allsopp'
  spec.email = 'clay@usepropeller.com'
  spec.homepage = 'https://github.com/usepropeller/motion-hockeyrink'
  spec.version = Version

  spec.add_dependency "hockeyapp-config"

  files = []
  files << 'README.md'
  files << 'LICENSE'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files = files
end

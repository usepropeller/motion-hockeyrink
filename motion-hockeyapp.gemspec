# -*- encoding: utf-8 -*-

Version = "1.0"

Gem::Specification.new do |spec|
  spec.name = 'motion-hockeyapp'
  spec.summary = 'HockeyApp integration for RubyMotion projects'
  spec.description = "motion-hockeyapp allows RubyMotion projects to easily embed the HockeyApp SDK and be submitted to HockeyApp."
  spec.author = 'Clay Allsopp'
  spec.email = 'clay@usepropeller.com'
  spec.homepage = 'https://github.com/usepropeller/motion-testflight'
  spec.version = Version

  spec.add_dependency "hockeyapp"

  files = []
  files << 'README.md'
  files << 'LICENSE'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files = files
end

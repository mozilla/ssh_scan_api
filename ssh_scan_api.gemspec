$: << "lib"
require 'ssh_scan_api/version'
require 'date'

Gem::Specification.new do |s|
  s.name = 'ssh_scan_api'
  s.version = SSHScan::API_VERSION
  s.authors = ["Harsh Vardhan", "Rishabh Saxena", "Ashish Gaurav", "Jonathan Claudius" ]
  s.date = Date.today.to_s
  s.email = 'jclaudius@mozilla.com'
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("lib/**/*") +
            Dir.glob("bin/**/*") +
            [".gitignore",
             ".rspec",
             ".travis.yml",
             "CONTRIBUTING.md",
             "Gemfile",
             "Rakefile",
             "README.md",
             "ssh_scan_api.gemspec"]
  s.license       = "ruby"
  s.require_paths = ["lib"]
  s.executables   = s.files.grep(%r{^bin/[^\/]+$}) { |f| File.basename(f) }
  s.summary = 'ssh_scan API'
  s.description = 'An API for performing SSH scans'
  s.homepage = 'http://rubygems.org/gems/ssh_scan_api'

  s.add_dependency('ssh_scan', '0.0.24')
  s.add_dependency('mongo')
  s.add_dependency('sinatra')
  s.add_dependency('sinatra-contrib')
  s.add_dependency('thin')
  s.add_dependency('haml')
  s.add_dependency('secure_headers')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('pry')
  s.add_development_dependency('rspec', '~> 3.0')
  s.add_development_dependency('rspec-its', '~> 1.2')
  s.add_development_dependency('rake')
  s.add_development_dependency('rubocop')
end

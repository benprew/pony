# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'pony'
  s.version = "1.12"

  s.summary = "Send email in one command: Pony.mail(:to => 'someone@example.com', :body => 'hello')"
  s.description = s.summary
  s.authors = ["Adam Wiggins", "Ben Prew"]
  s.email = 'ben@throwingbones.com'
  s.homepage = 'http://github.com/benprew/pony'
  s.license = 'MIT'

  s.files = ["README.md", "Rakefile", "pony.gemspec" ] + Dir.glob("{lib,spec}/**/*")
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.add_runtime_dependency 'mail', '>= 2.0'
  s.add_development_dependency "rspec", ">= 2.14"
  s.add_development_dependency "rake"
end

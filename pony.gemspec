# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{pony}
  s.version = "1.1"

  s.description = "Send email in one command: Pony.mail(:to => 'someone@example.com', :body => 'hello')"
  s.summary = s.description
  s.authors = ["Adam Wiggins", "maint: Ben Prew"]
  s.email = %q{ben.prew@gmail.com}
  s.homepage = %q{http://github.com/benprew/pony}
  s.rubyforge_project = "pony"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.files = ["README.rdoc", "Rakefile", "pony.gemspec" ] + Dir.glob("{lib,spec}/**/*")
  s.has_rdoc = false
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.add_dependency 'mail', '>2.0'
  s.add_development_dependency "rspec", ">= 2.0.0"  
  s.platform = Gem::Platform::RUBY
end

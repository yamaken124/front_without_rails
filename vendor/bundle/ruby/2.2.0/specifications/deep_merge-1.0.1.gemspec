# -*- encoding: utf-8 -*-
# stub: deep_merge 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "deep_merge"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Steve Midgley"]
  s.date = "2011-07-28"
  s.description = "Recursively merge hashes. Now works with Ruby 1.9 and ActiveSupport"
  s.email = "dan@kallistec.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "http://github.com/danielsdeleo/deep_merge"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "Merge Deeply Nested Hashes"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 10.1"])
    else
      s.add_dependency(%q<rake>, ["~> 10.1"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 10.1"])
  end
end

# -*- encoding: utf-8 -*-
# stub: github-linguist 5.3.2 ruby lib
# stub: ext/linguist/extconf.rb

Gem::Specification.new do |s|
  s.name = "github-linguist"
  s.version = "5.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["GitHub"]
  s.date = "2017-10-31"
  s.description = "We use this library at GitHub to detect blob languages, highlight code, ignore binary files, suppress generated files in diffs, and generate language breakdown graphs."
  s.executables = ["linguist", "git-linguist"]
  s.extensions = ["ext/linguist/extconf.rb"]
  s.files = ["bin/git-linguist", "bin/linguist", "ext/linguist/extconf.rb"]
  s.homepage = "https://github.com/github/linguist"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.8"
  s.summary = "GitHub Language detection"

  s.installed_by_version = "2.4.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<charlock_holmes>, ["~> 0.7.5"])
      s.add_runtime_dependency(%q<escape_utils>, ["~> 1.1.0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.19"])
      s.add_runtime_dependency(%q<rugged>, [">= 0.25.1"])
      s.add_development_dependency(%q<minitest>, [">= 5.0"])
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.9"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<plist>, ["~> 3.1"])
      s.add_development_dependency(%q<pry>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_development_dependency(%q<color-proximity>, ["~> 0.2.1"])
      s.add_development_dependency(%q<licensed>, [">= 0"])
      s.add_development_dependency(%q<licensee>, ["~> 8.8.0"])
    else
      s.add_dependency(%q<charlock_holmes>, ["~> 0.7.5"])
      s.add_dependency(%q<escape_utils>, ["~> 1.1.0"])
      s.add_dependency(%q<mime-types>, [">= 1.19"])
      s.add_dependency(%q<rugged>, [">= 0.25.1"])
      s.add_dependency(%q<minitest>, [">= 5.0"])
      s.add_dependency(%q<rake-compiler>, ["~> 0.9"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<plist>, ["~> 3.1"])
      s.add_dependency(%q<pry>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<color-proximity>, ["~> 0.2.1"])
      s.add_dependency(%q<licensed>, [">= 0"])
      s.add_dependency(%q<licensee>, ["~> 8.8.0"])
    end
  else
    s.add_dependency(%q<charlock_holmes>, ["~> 0.7.5"])
    s.add_dependency(%q<escape_utils>, ["~> 1.1.0"])
    s.add_dependency(%q<mime-types>, [">= 1.19"])
    s.add_dependency(%q<rugged>, [">= 0.25.1"])
    s.add_dependency(%q<minitest>, [">= 5.0"])
    s.add_dependency(%q<rake-compiler>, ["~> 0.9"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<plist>, ["~> 3.1"])
    s.add_dependency(%q<pry>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<color-proximity>, ["~> 0.2.1"])
    s.add_dependency(%q<licensed>, [">= 0"])
    s.add_dependency(%q<licensee>, ["~> 8.8.0"])
  end
end

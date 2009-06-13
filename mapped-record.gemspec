# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mapped-record}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Henry Hsu"]
  s.date = %q{2009-06-13}
  s.description = %q{Auto-magically map Hash[keys] to ActiveRecord.attributes}
  s.email = ["henry@qlane.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = ["History.txt", "LICENSE", "Manifest.txt", "README.rdoc", "Rakefile", "lib/mapped-record.rb", "lib/mapped-record/hash/mappable.rb", "lib/mapped-record/mapping.rb", "script/console", "script/destroy", "script/generate", "test/database.yml", "test/hashed-record/hash/test_mappable.rb", "test/hashed-record/test_mapping.rb", "test/test_helper.rb", "test/test_mapped_record.rb"]
  s.homepage = %q{http://github.com/hsume2/mapped-record}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mapped-record}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Auto-magically map Hash[keys] to ActiveRecord.attributes}
  s.test_files = ["test/hashed-record/hash/test_mappable.rb", "test/hashed-record/test_mapping.rb", "test/test_helper.rb", "test/test_mapped_record.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_development_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.0.2"])
      s.add_dependency(%q<newgem>, [">= 1.4.1"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.0.2"])
    s.add_dependency(%q<newgem>, [">= 1.4.1"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end

require_relative 'lib/ruml/version'

Gem::Specification.new do |spec|
  spec.name          = "ruml"
  spec.version       = Ruml::VERSION
  spec.authors       = ["Samuel Rizzo"]
  spec.email         = ["rizzolabs@gmail.com"]

  spec.summary       = %q{Generate PlantUML from Ruby code}
  spec.description   = %q{Generate PlantUML from Ruby code}
  spec.homepage      = "https://github.com/srizzo/ruml"
  spec.licenses      = ['MIT']
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/srizzo/ruml"
  spec.metadata["changelog_uri"] = "https://github.com/srizzo/ruml/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "binding_of_caller", "~> 1.0"
end

require_relative 'lib/line_message_creator/version'

Gem::Specification.new do |spec|
  spec.name          = "line_message_creator"
  spec.version       = LineMessageCreator::VERSION
  spec.authors       = ["Hiroto Ohira"]
  spec.email         = ["hiroto100114@gmail.com"]

  spec.summary       = %q{Simple Line message creator for Rails.}
  spec.homepage      = "https://github.com/HirotoOhria/line_message_creator"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/HirotoOhria/line_message_creator"
  spec.metadata["changelog_uri"] = "https://github.com/HirotoOhria/line_message_creator/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end

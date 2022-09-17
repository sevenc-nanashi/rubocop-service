# frozen_string_literal: true

require_relative "lib/rubocop/service/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-service"
  spec.version = Rubocop::Service::VERSION
  spec.authors = ["sevenc-nanashi"]
  spec.email = ["sevenc7c@sevenc7c.com"]

  spec.summary = "Provides support of rubocop server, for Windows!"
  spec.homepage = "https://github.com/sevenc-nanashi/rubocop-service"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata[
    "source_code_uri"
  ] = "https://github.com/sevenc-nanashi/rubocop-service"
  spec.metadata["changelog_uri"] = "https://github.com/sevenc-nanashi/rubocop-service/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0")
        .reject do |f|
          (f == __FILE__) ||
            f.match(
              %r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)}
            )
        end
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "rubocop", "~> 1.36.0"

  spec
end

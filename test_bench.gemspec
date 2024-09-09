# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'test_bench'
  spec.version = "0.0.0.0"
  spec.summary = "Some summary"
  spec.description = ' '

  spec.authors = ["Brightworks Digital"]
  spec.email = ["development@brightworks.digital"]
  spec.homepage = "http://test-bench.software"

  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/test-bench/test-bench"

  spec.files = Dir.glob('lib/**/*')
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'test_bench-fixture'
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "factory_bot_rails"
require "json_schemer"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Add more helper methods to be used by all tests here...
    include FactoryBot::Syntax::Methods

    def assert_schema(schema_path, json)
      schema_file = File.expand_path("../schemas/#{schema_path}", __FILE__)
      schemer = JSONSchemer.schema(Pathname.new(schema_file))
      errors = schemer.validate(json).to_a
      assert errors.empty?, "Schema validation failed: #{errors.map { |e| e.slice('data_pointer', 'type', 'schema_pointer') }}"
    end
  end
end

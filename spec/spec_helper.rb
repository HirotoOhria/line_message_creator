require "bundler/setup"
require "line_message_creator"

LineMessageCreator.line_message_dir = Pathname.new(__dir__).join('fixtures')
LineMessageCreator.helper_dir       = LineMessageCreator.line_message_dir.join('helpers')

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

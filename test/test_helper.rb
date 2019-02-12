# frozen_string_literal: true

require File.expand_path('../test/dummy/config/environment.rb', __dir__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../db/migrate', __dir__)
require 'rails/test_help'
require 'minitest/mock'

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('fixtures', __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + '/files'
  ActiveSupport::TestCase.fixtures :all
end

require 'pry'

# require 'minitest/reporters'
# MiniTest::Reporters.use!

def simple_sheet(ary)
  xls = Axlsx::Package.new
  workbook = xls.workbook
  sheet = workbook.add_worksheet(name: 'Import')

  ary.each do |a|
    sheet.add_row a
  end

  # Tempfile.open(%w[simple_sheet .xlsx]) do |f|
  #   f.write(xls.to_stream.read)
  #   f
  # end

  xls.to_stream
end

# frozen_string_literal: true

require 'test_helper'

class AccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  model Account

  column 'id', 'id', attribute: 'id'
  column 'name', 'name', attribute: 'name'
  column 'description', 'description', attribute: 'description'
end

class NoHeaderAccountImporter < Importo::BaseImporter
  ignore_header false
  includes_header false
  allow_duplicates false

  model Account

  column 'id', 'id', attribute: 'id'
  column 'name', 'name', attribute: 'name'
  column 'description', 'description', attribute: 'description'
end

module Importo
  class ImportTest < ActiveSupport::TestCase
    test 'imports an excel file' do
      import = Import.create(importo_ownable: Account.create(name: 'test'), kind: 'account', file_name: simple_sheet([%w[id name description], %w[aid atest atest-description]]).path)
      import.schedule
      assert_equal 'scheduled', import.state
      import.import

      assert_nothing_raised do
        assert_difference -> { Account.count }, 1 do
          import.importer.import!
        end
      end
      assert_equal 'completed', import.reload.state
    end

    test 'imports an excel file with no headers' do
      import = Import.create(importo_ownable: Account.create(name: 'test'), kind: 'no_header_account', file_name: simple_sheet([%w[aid atest atest-description], %w[bid btest btest-description]]).path)
      import.schedule
      assert_equal 'scheduled', import.state
      import.import

      assert_nothing_raised do
        assert_difference -> { Account.count }, 2 do
          import.importer.import!
        end
      end
      assert_equal 'completed', import.reload.state, import.results
    end

    test 'finds the correct header row when it is the first row' do
      import = Import.create(importo_ownable: Account.create(name: 'test'), kind: 'account', file_name: simple_sheet([%w[id name description], %w[aid atest atest-description]]).path)
      importer = import.importer
      assert_equal 1, importer.send(:header_row)
    end

    test 'finds the correct header row when there are random rows in front' do
      import = Import.create(importo_ownable: Account.create(name: 'test'), kind: 'account', file_name: simple_sheet([%w[], %w[a b c], %w[id name description], %w[aid atest atest-description]]).path)
      importer = import.importer
      assert_equal 3, importer.send(:header_row)
    end
  end
end

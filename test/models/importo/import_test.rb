# frozen_string_literal: true

require 'test_helper'

class AccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  field 'id', 'id'
  field 'name', 'name'
  field 'description', 'description'

  def build(row)
    account = Account.find_or_create_by(id: row['id'])
    account.name = row['name']
    account.description = row['description']
    account
  end
end

module Importo
  class ImportTest < ActiveSupport::TestCase
    test 'imports an excel file' do
      import = Import.create(importo_ownable: Account.create(name: 'test'), kind: 'account', file_name: simple_sheet([%w[id name description], %w[id test test-description]]).path)
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
  end
end

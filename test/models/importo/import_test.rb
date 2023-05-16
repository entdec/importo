# frozen_string_literal: true

require 'test_helper'

class TranslatedAccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  model Account

  column attribute: 'id'
  column attribute: 'name'
  column attribute: 'description'

  def current_user
    User.find_or_create_by(name: 'test')
  end
end

class AccountImporter < Importo::BaseImporter
  includes_header true
  allow_duplicates false

  model Account

  column attribute: 'id'
  column attribute: 'name'
  column attribute: 'description', strip_tags: false

  def current_user
    User.find_or_create_by(name: 'test')
  end
end

class NoHeaderAccountImporter < Importo::BaseImporter
  ignore_header false
  includes_header false
  allow_duplicates false

  model Account

  column attribute: 'id'
  column attribute: 'name'
  column attribute: 'description'

  def current_user
    User.find_or_create_by(name: 'test')
  end
end

module Importo
  class ImportTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    
    test 'imports an excel file' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'account')
      import.original.attach(io: simple_sheet([%w[id name description], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      
      import.schedule
      assert_equal 'scheduled', import.state
      
      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      #perform_enqueued_jobs
      #Sidekiq::Worker.drain_all

      assert_import(import)
    end

    test 'import strips html tags unless strip_tags is set to false' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'account')
      import.original.attach(io: simple_sheet([%w[id name description], ['aid', '<strong>a</strong>test', '<strong>atest</strong>-description']]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      import.schedule
      assert_equal 'scheduled', import.state

      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      assert_nothing_raised do
        assert_difference -> { Account.count }, 1 do
          import.importer.import!
        end
      end

      account = Account.find_by_name('atest')
      refute_nil account
      assert_equal '<strong>atest</strong>-description', account.description
      assert_equal 'completed', import.reload.state, import.results
    end

    test 'imports an excel file with no headers' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'no_header_account')
      import.original.attach(io: simple_sheet([%w[aid atest atest-description], %w[bid btest btest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save
      import.schedule
      assert_equal 'scheduled', import.state
      
      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      assert_nothing_raised do
        assert_difference -> { Account.count }, 2 do
          import.importer.import!
        end
      end
      assert_equal 'completed', import.reload.state, import.results
    end

    test 'finds the correct header row when it is the first row' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'account')
      import.original.attach(io: simple_sheet([%w[id name description], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      importer = import.importer
      assert_equal 1, importer.send(:header_row)
    end

    test 'finds the correct header row when there are random rows in front' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'account')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], %w[id name description], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      importer = import.importer
      assert_equal 3, importer.send(:header_row)
    end

    test 'finds the correct translated header row with default language (en)' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Name', 'Description'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      importer = import.importer
      assert_equal 3, importer.send(:header_row)
    end

    test 'finds the correct translated header row with nl language' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account', locale: 'nl')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Naam', 'Omschrijving'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      importer = import.importer
      assert_equal 3, importer.send(:header_row)
    end

    test 'finds the correct translated header row with nl language while default locale is active (en)' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Naam', 'Omschrijving'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      importer = import.importer
      assert_equal 3, importer.send(:header_row)
    end

    test 'imports an excel file with the headers in nl while the current locale is nl' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account', locale: 'nl')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Naam', 'Omschrijving'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      import.schedule
      assert_equal 'scheduled', import.state
      
      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      assert_import(import)
    end

    test 'imports an excel file with the headers in nl while the current locale is en' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Naam', 'Omschrijving'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      import.schedule
      assert_equal 'scheduled', import.state
      
      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      assert_import(import)
    end

    test 'imports an excel file with the headers in en and nl while the current locale is en' do
      import = Import.new(importo_ownable: Account.create(name: 'test'), kind: 'translated_account')
      import.original.attach(io: simple_sheet([%w[], %w[a b c], ['Record ID', 'Naam', 'Description'], %w[aid atest atest-description]]), filename: 'simple_sheet.xlsx')
      assert import.save, import.errors.messages
      import.schedule
      assert_equal 'scheduled', import.state
      
      import.import
      Importo::ImportJobCallback.new.on_complete(nil, import_id: import.id)

      assert_import(import)
    end

    private

    def assert_import(import)
      assert_nothing_raised do
        assert_difference -> { Account.count }, 1 do
          import.importer.import!
        end
      end

      account = Account.find_by_name('atest')
      refute_nil account
      assert_equal 'atest-description', account.description
      assert_equal 'completed', import.reload.state
    end
  end
end

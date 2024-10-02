

# frozen_string_literal: true-

require "axlsx"
require "roo/excelx"

module Importo
  module TestHelpers
    def simple_sheet(an_array, sheet_name: "Import")
      xls = Axlsx::Package.new
      workbook = xls.workbook
      sheet = workbook.add_worksheet(name: sheet_name)

      an_array.each do |a|
        sheet.add_row a
      end

      xls.to_stream
    end

    def sample_sheet(kind, locale: I18n.locale)
      excel = Importo::Import.new(kind: kind, locale: locale).importer.sample_file

      Roo::Excelx.new(excel.set_encoding("BINARY"))
    end

    def import_sheet(kind, sheet, filename: "import.xlsx", locale: I18n.locale, owner: @owner)
      import = Importo::Import.new(kind: kind, locale: locale, importo_ownable: owner)

      import.original.attach(io: sheet, filename: filename, content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", identify: false)
      import.save!

      ImportService.perform(import: import)
      ImportJobCallback.new.on_complete({import_id: import.id})
      import
    end
  end
end

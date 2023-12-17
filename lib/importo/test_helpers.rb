# frozen_string_literal: true

require "axlsx"

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
  end
end

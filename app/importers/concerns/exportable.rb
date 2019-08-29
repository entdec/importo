
# frozen_string_literal: true

require 'active_support/concern'

module Exportable
  extend ActiveSupport::Concern

  #
  # Generates a sample excel file as a stream
  #
  def sample_file
    export(sample_data)
  end

  def sample_data
    [columns.map { |_, c| c.options[:example] || '' }]
  end

  #
  # Generates an export based on the attributes and scope.
  #
  def export_file
    export(export_data)
  end

  def export_data
    export_scope.map { |record| export_row(record) }
  end

  def export_scope
    if self.class.allow_export?
      model.all
    else
      model.none
    end
  end

  def export_row(record)
    columns.map do |_, c|
      c.options[:attribute] ? record.attributes[c.options[:attribute].to_s] : ''
    end
  end

  def export(data_rows)
    xls = Axlsx::Package.new
    xls.use_shared_strings = true
    workbook = xls.workbook
    sheet = workbook.add_worksheet(name: friendly_name&.pluralize || model.name.demodulize.pluralize)
    workbook.styles do |style|
      introduction_style = style.add_style(bg_color: 'E2EEDA')
      header_style = style.add_style(b: true, bg_color: 'A8D08E', border: { style: :thin, color: '000000' })
      header_required_style = style.add_style(b: true, bg_color: 'A8D08E', fg_color: 'C00100', border: { style: :thin, color: '000000' })

      # Introduction
      introduction.each_with_index do |intro, i|
        text = intro.is_a?(Symbol) ? I18n.t(intro, scope: [:importers, self.class.name.underscore.to_s, :introduction]) : intro
        sheet.add_row [text], style: [introduction_style] * columns.count
        sheet.merge_cells "A#{i + 1}:#{nr_to_col(columns.count - 1)}#{i + 1}"
      end

      # Header row
      sheet.add_row columns.values.map(&:name), style: columns.map { |_, c| c.options[:required] ? header_required_style : header_style }

      columns.each.with_index do |f, i|
        field = f.last
        sheet.add_comment ref: "#{nr_to_col(i)}#{introduction.count + 1}", author: '', text: field.hint, visible: false if field.hint.present?
      end

      number = workbook.styles.add_style format_code: '#'
      text = workbook.styles.add_style format_code: '@'

      styles = columns.map { |_, c| c.options[:example].is_a?(Numeric) ? number : text }

      # Examples
      data_rows.each do |data|
        sheet.add_row data, style: styles
      end
    end

    sheet.column_info[0].width = 10

    sheet = workbook.add_worksheet(name: I18n.t('importo.sheet.explanation.name'))

    workbook.styles do |style|
      introduction_style = style.add_style(bg_color: 'E2EEDA')
      header_style = style.add_style(b: true, bg_color: 'A8D08E', border: { style: :thin, color: '000000' })

      column_style = style.add_style(b: true)
      required_style = style.add_style(b: true, fg_color: 'C00100')
      wrap_style = workbook.styles.add_style alignment: { wrap_text: true }

      # Introduction
      introduction.each_with_index do |intro, i|
        text = intro.is_a?(Symbol) ? I18n.t(intro, scope: [:importers, self.class.name.underscore.to_s, :introduction]) : intro
        sheet.add_row [text], style: [introduction_style] * 2
        sheet.merge_cells "A#{i + 1}:B#{i + 1}"
      end

      # Header row
      sheet.add_row [I18n.t('importo.sheet.explanation.column'), I18n.t('importo.sheet.explanation.explanation')], style: [header_style] * 2
      columns.each do |_, c|
        styles = [c.options[:required] ? required_style : column_style, wrap_style]
        sheet.add_row [c.name, c.explanation], style: styles
      end
    end

    sheet.column_info[0].width = 40
    sheet.column_info[1].width = 150

    xls.to_stream
  end
end
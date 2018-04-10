# frozen_string_literal: true

class <%=name%>Importer < ApplicationImporter
  # Whether the excel sheet should contain a header
  includes_header true
  # Whether to allow importing of duplicates
  allow_duplicates false
  # Whether to ignore the given header and use our internal mapping
  ignore_header false

  fields 'id'   => 'record ID of the <%=name%> (only if you want to update)',
         'name' => 'name of the <%=name%>'

  # Here you will build the record based on the row
  def build(row)
    record = <%=name%>.find_or_initialize_by(id: row['id'])
    record.name = row['name']
    record
  end

  # Uncomment if you need to do something before saving the record
  # def before_save(record, _row)
  # end
end

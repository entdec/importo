# Importo

Short description and motivation.

## Usage

Add an `app/importers` folder to your Rails app which will contain all importers.
It's recommended to add an ApplicationImporter that inherits from `Importo::BaseImporter` and that all other importers inherit from.

```ruby
class ApplicationImporter < Importo::BaseImporter
end
```

```ruby
class ProductsImporter < ApplicationImporter
  includes_header true
  allow_duplicates false
  allow_export true

  model Product
  friendly_name 'Product'

  introduction %i[what columns required_column first_line save_locally translated more_information]

  column attribute: :id

  # attributes
  column attribute: :name, required: true
  column attribute: :description, strip_tags: false
  column attribute: :number, export: { format: 'text', value: ->(record) { record.number }, example: 'FLAG-NLD-001' }, style: {b: true}
  column attribute: :expires_on, export: { format: 'dd/mm/yyyy h:mm'}
  column name: :price, export: { format: 'number', value: ->(record) { record.price } }
  column attribute: :images do |value|
    value.split(',').map do |image|
      uri = URI.parse(image)

      { filename: File.basename(uri.to_s), io: URI.open(uri) }
    end
  end

  def export_scope
    Current.account.products
  end
end
```
export args for column is optional, format takes excel custom format codes default is General  

You should add translations to your locale files:

```yaml
en:
  importers:
    products_importer:
      introduction:
        what: "With this Excel sheet multiple shipments can be imported at once. Mind the following:"
        columns: "- Columns may be deleted or their order may be changed."
        required_column: "- Columns in red are mandatory."
        first_line: "- The first line is an example and must be removed."
        save_locally: "- You can save this Excel file locally and fill it in partially, so you can re-use it."
        translated: "- Columns and contents of this sheet are translated based on your locale, make sure you import in the same locale as you download the sample file."
        more_information: 'Check the comments with each column and the "Explanation" sheet for more information.'
      column:
        name: Name
        number: Number
        description: Description
        images: Images
      # Shown in note in import sheet
      hint:
        id: 36 characters, existing of hexadecimal numbers, separated by dashes
        images: Allows multiple image urls, separated by comma
      # Below items are show in explanation sheet
      explanation:
        id: Record-id, only needed if you want to update an existing record
      example:
        id: 12345678-1234-1234-1234-123456789012
        name: TEST-123
        number: TEST-123
        description: Test product
      value:
        id: Optional

```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'importo'
```

Importo depends on Sidekiq Pro's batch functionality, 
though you can use [sidekiq-batch](https://github.com/entdec/sidekiq-batch) as a drop-in for that.

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install importo
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

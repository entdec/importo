# Importo

Short description and motivation.

## Usage

Add a `app/importers` folder to your Rails app and create a class that inherits from `Importo::Base`:

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
  column attribute: :name
  column attribute: :number
  column attribute: :description, strip_tags: false
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
      explanation:
        id: Record-id, only needed if you want to update an existing record
      hint:
        id: 36 characters, existing of hexadecimal numbers, separated by dashes
        images: Allows multiple image urls, separated by comma
      introduction: null
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'importo'
```

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

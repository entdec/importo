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

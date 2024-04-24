# frozen_string_literal: true

if defined? ActionTable
  class Importo::ImportsTable < ActionTable::ActionTable
  model Importo::Import

  column(:created_at, html_value: proc { |import| l(import.created_at.in_time_zone(Time.zone), format: :short).to_s })
  column(:user, sortable: false) { |import| import.importo_ownable.name }
  column(:kind, sortable: false)
  column(:original, sortable: false) { |import| link_to(import.original.filename, main_app.rails_blob_path(import.original, disposition: "attachment"), target: "_blank") }
  column(:state)
  column(:result, sortable: false) { |import| import.result.attached? ? link_to(import.result_message, main_app.rails_blob_path(import.result, disposition: "attachment"), target: "_blank") : import.result_message }
  column(:extra_links, sortable: false) { |import| Importo.config.admin_extra_links.call(import).map { |name, link| link_to(link[:text], link[:url], title: link[:title], target: "_blank", class: link[:icon]) } }

  column :actions, title: "", sortable: false do |import|
    content_tag(:span) do
      if import.can_revert?
        concat link_to(content_tag(:i, nil, class: "fa fa-undo"), importo.undo_import_path(import), data: {turbo_method: :post, turbo_confirm: "Are you sure? This will undo this import."})
      end
      if Importo.config.admin_can_destroy.call(import)
        concat link_to(content_tag(:i, nil, class: "fa fa-trash"), importo.import_path(import), class: "float-right", data: {turbo_method: :delete, turbo_confirm: "Are you sure? This will prevent duplicate imports from being detected."})
      end
    end
  end

  # filter(:importo_ownable){ parameter: :ownable, collection_proc: -> { Importo::Import.order(created_at: :desc).limit(200).map(&:importo_ownable).uniq.sort_by(&:name).map { |o| [o.name, "#{o.class.name}##{o.id}"] } } } )

  initial_order :created_at, :desc

  private

  def scope
    @scope = Importo.config.admin_visible_imports.call
    @scope
  end
end
else
  class Importo::ImportsTable
  end
end

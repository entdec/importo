# frozen_string_literal: true

class Importo::ImportsTable < ActionTable::ActionTable
  model Importo::Import

  column(:created_at) { |import| l(import.created_at.in_time_zone(Time.zone), format: :short).to_s }
  column(:user, filter: { parameter: :ownable, collection_proc: -> { Importo::Import.order(created_at: :desc).limit(200).map(&:importo_ownable).uniq.sort_by(&:name).map { |o| [o.name, "#{o.class.name}##{o.id}"] } } } ) { |import| import.importo_ownable.name }
  column(:kind, sortable: false)
  column(:original, sortable: false) { |import| link_to(import.original.filename, main_app.rails_blob_path(import.original, disposition: "attachment"), target: '_blank') }
  column(:state)
  column(:result, sortable: false) { |import| import.result.attached? ? link_to(import.result_message, main_app.rails_blob_path(import.result, disposition: "attachment"), target: '_blank') : import.result_message }
  column(:extra_links, sortable: false) { |import| Importo.config.admin_extra_links(import).map { |name, link| link_to(link[:text], link[:url], title: link[:title], target: '_blank', class: link[:icon]) }}

  column :actions, title: '', sortable: false do |import|
    content_tag(:span) do
      if import.can_revert?
        concat link_to(content_tag(:i, nil, class: 'fa fa-undo'), importo.undo_import_path(import), method: :post, data: { confirm: 'Are you sure? This will undo this import.' })
      end
      if Importo.config.admin_can_destroy(import)
        concat link_to(content_tag(:i, nil, class: 'fa fa-trash'), importo.import_path(import), method: :delete, class: 'float-right', data: { confirm: 'Are you sure? This will prevent duplicate imports from being detected.' })
      end
    end
  end

  initial_order :created_at, :desc

  private

  def scope
    @scope = Importo.config.admin_visible_imports
  end

  def filtered_scope
    @filtered_scope = scope
    @filtered_scope = @filtered_scope.where(importo_ownable_type: params[:ownable].split('#').first, importo_ownable_id: params[:ownable].split('#').last) if params[:ownable]

    @filtered_scope
  end
end

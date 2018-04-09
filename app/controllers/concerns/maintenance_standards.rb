# frozen_string_literal: true

module MaintenanceStandards
  # Informs the user and redirects when needed
  #
  # @param result [Boolean] was update or create succesful
  # @param path [URL] where to redirect to
  # @param notice [String] What to show on success
  # @param error [String] What to show on error
  # @param render_action [Symbol] What to render
  #
  def flash_and_redirect(result, path, notice, error, render_action = :edit)
    if result
      if params[:commit] == 'continue'
        flash.now[:notice] = notice
      else
        redirect_to(path, notice: notice) && return
      end
    else
      flash.now[:error] = error
    end
    render render_action
  end
end

# frozen_string_literal: true

module Datagridable
  extend ActiveSupport::Concern

  # End the controller method with this function to respond with the format
  # requested by the user.
  def respond_with_datagrid(grid = @grid, filename:, **parameters)
    parameters[:locals] ||= {}
    parameters[:locals][:grid] = grid
    parameters[:locals][:filename] = filename
    do_not_render = false
    respond_to do |format|
      format.html
      format.csv do
        do_not_render = true
        send_data grid.to_csv, filename: "#{filename}.csv"
      end
      format.pdf do
        parameters[:pdf] = filename
        parameters[:layout] = 'pdf'
      end
    end

    begin
      # We might have a customized view, try it first.
      render(**parameters) unless do_not_render
    rescue ActionView::MissingTemplate => e
      # Fallback on the generic view.
      begin
        #
        # At least one dependency breaks `#render` on ActionController.
        # Thus, using `render("some_name")` will fail with the PDF being
        # unusable, viewing the source returns a GUID.
        #
        # The solution is to pass the thing to render as `_normalize_args`
        # would.
        #
        # See:
        #  * https://github.com/mileszs/wicked_pdf/blob/2742687ab8a7558bdc703022e93193826c85f032/lib/wicked_pdf/pdf_helper.rb#L29-L31
        #  * https://github.com/rails/rails/blob/1b984fc258656f741b02565e7c50b4bb45f7de52/actionpack/lib/abstract_controller/rendering.rb#L75-L90
        #
        #
        render(file: 'datagrid/index', **parameters)
      rescue ActionView::MissingTemplate
        # Raise the initial error, instead of the new one.
        raise e
      end
    end
  end
end

class WelcomeController < ApplicationController
  layout 'curate_nd/1_column'

  respond_to :html
  def index
    respond_with
  end

  private

  def show_action_bar?
    false
  end
end

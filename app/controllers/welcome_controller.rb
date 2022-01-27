# frozen_string_literal: true

class WelcomeController < ApplicationController
  # #layout 'site'

  def index
    if @current_user
      redirect_to controller: 'user', action: 'dashboard'
      nil
    end
  end
end

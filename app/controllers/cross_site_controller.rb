# frozen_string_literal: true

# The CrossSiteController provides urls for other sites to access PE partials.
# This is mainly so PN and PE can have the same header, footers and other common layouts.
# Generally these partials are just html, no stylesheet links etc.
class CrossSiteController < ApplicationController
  # Partial with links to sign in or sign out along with help and home.
  def sign_in_out
    render partial: 'sign_in_out'
  end

  # Partial with link to advanced publication creation page.
  def advanced_create
    render partial: 'advanced_create'
  end

  # Partial with complete header.
  def header
    render partial: 'header'
  end

  # Partial with complete footer.
  def footer
    render partial: 'footer'
  end
end

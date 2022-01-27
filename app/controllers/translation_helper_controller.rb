# frozen_string_literal: true

class TranslationHelperController < ApplicationController
  layout false

  def wheretogo; end

  # Helper Terms
  def terms
    # get the terms
    gloss = HGVTransGlossary.new

    @glossary = gloss.to_chooser
  end

  # Helper - view not in use - using button to and 'add_new_lang_to_xml' method in hgv_trans_identifiers_controller
  # to limit the languages added to those set up in the system
  def new_lang; end

  # Helper Linebreak
  def linebreak; end

  # Helper Division Other
  def division; end

  # Helper Tryit
  def tryit; end
end

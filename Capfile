# frozen_string_literal: true

load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/cached_externals/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'

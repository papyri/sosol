# frozen_string_literal: true

begin
  require 'metric_fu'

  MetricFu::Configuration.run do |config|
    config.metrics -= [:rcov]
    config.graphs = []
  end
rescue LoadError
end

#!/usr/bin/env ruby
# frozen_string_literal: true

task :nuke_test_repo do
  FileUtils.rm_rf(Rails.root.join(*%w[db test git canonical.git]))
end

Rake::Task['test:integration'].enhance [:nuke_test_repo, 'git:db:canonical:clone']

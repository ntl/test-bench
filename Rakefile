# frozen_string_literal: true

require "bundler/gem_tasks"

task :test do
  require 'bundler/setup'
  require 'test_bench'
  TestBench::Run.('test/automated', exclude: '*_init.rb')
end

task default: :test

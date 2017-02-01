#!/usr/bin/ruby

require 'simplecov' if ENV['COVERAGE']
require 'rspec'
require 'loggability/spechelpers'

module SpecHelpers

	TEST_LISTSDIR = ENV['TEST_LISTSDIR'] || '/tmp/lists'

	###############
	module_function
	###############

	### Create a temporary working directory and return
	### a Pathname object for it.
	###
	def make_tempdir
		dirname = "%s.%d.%0.4f" % [
			'ezmlm_spec',
			Process.pid,
			(Time.now.to_f % 3600),
		  ]
		tempdir = Pathname.new( Dir.tmpdir ) + dirname
		tempdir.mkpath

		return tempdir
	end
end


RSpec.configure do |config|
	include SpecHelpers

	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.order = 'random'
	config.mock_with( :rspec ) do |mock|
		mock.syntax = :expect
	end

	config.include( SpecHelpers )
end



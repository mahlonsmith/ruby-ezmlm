#!/usr/bin/ruby

require 'simplecov' if ENV['COVERAGE']
require 'rspec'
require 'loggability/spechelpers'
require 'fileutils'

module SpecHelpers
	include FileUtils

	TEST_LIST_NAME = 'waffle-lovers'
	TEST_LIST_HOST = 'lists.syrup.info'
	TEST_OWNER     = 'listowner@rumpus-the-whale.info'

	TEST_SUBSCRIBERS = %w[
		pete.chaffee@toadsmackers.com
		dolphinzombie@alahalohamorra.com
		piratebanker@yahoo.com
	]

	TEST_MODERATORS = %w[
		dolphinzombie@alahalohamorra.com
	]

	###############
	module_function
	###############

	### Create a copy of a fresh listdir into /tmp.
	###
	def make_listdir
		dirname = "/tmp/%s.%d.%0.4f" % [
			'ezmlm_list',
			Process.pid,
			(Time.now.to_f % 3600),
		  ]
		list = Pathname.new( __FILE__ ).dirname + 'data' + 'testlist'
		cp_r( list.to_s, dirname )

		return dirname
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



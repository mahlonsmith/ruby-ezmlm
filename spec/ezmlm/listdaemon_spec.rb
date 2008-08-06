#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}


begin
	require 'ostruct'
	require 'spec/runner'
	require 'spec/lib/helpers'
	require 'ezmlm/listdaemon'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


describe Ezmlm::ListDaemon do
	include Ezmlm::SpecHelpers


	DEFAULT_ADDRESS = Ezmlm::ListDaemon::DEFAULT_ADDRESS
	DEFAULT_PORT = Ezmlm::ListDaemon::DEFAULT_PORT


	it "can return a struct that contains its default options" do
		opts = Ezmlm::ListDaemon.default_options
		
		opts.should be_an_instance_of( OpenStruct )
		opts.bind_addr.should == DEFAULT_ADDRESS
		opts.bind_port.should == DEFAULT_PORT
		opts.debugmode.should == false
		opts.helpmode.should == false
	end

	describe "created with defaults" do

		DEFAULT_URL = "druby://%s:%d" % [ DEFAULT_ADDRESS, DEFAULT_PORT ]

		before( :each ) do
			@test_list_dir = Pathname.new( 'lists' )
			@daemon = Ezmlm::ListDaemon.new( @test_list_dir )
		end
		

		it "can be started and will return a thread" do
			mock_drb_thread = mock( "drb thread" )
			
			DRb.should_receive( :start_service ).with( DEFAULT_URL, @daemon.service )
			DRb.should_receive( :thread ).and_return( mock_drb_thread )

			@daemon.start.should == mock_drb_thread
		end
	end


	describe "created with an options struct" do

		TEST_ADDRESS = '0.0.0.0'
		TEST_PORT = 17771
		TEST_URL = "druby://%s:%d" % [ TEST_ADDRESS, TEST_PORT ]

		before( :each ) do
			@test_list_dir = Pathname.new( 'lists' )

			@opts = Ezmlm::ListDaemon.default_options
			@opts.bind_addr = TEST_ADDRESS
			@opts.bind_port = TEST_PORT

			@daemon = Ezmlm::ListDaemon.new( @test_list_dir, @opts )
		end
		

		it "can be started and will return a thread" do
			mock_drb_thread = mock( "drb thread" )
			
			DRb.should_receive( :start_service ).with( TEST_URL, @daemon.service )
			DRb.should_receive( :thread ).and_return( mock_drb_thread )

			@daemon.start.should == mock_drb_thread
		end
	end

end


describe Ezmlm::ListDaemon::Service do
	
	before( :each ) do
		@dummydir = 'lists'
		@service = Ezmlm::ListDaemon::Service.new( @dummydir )
	end

	
	it "can return a list object by name if there is a corresponding listdir" do
		@service.get_list( 'announce' ).should be_an_instance_of( Ezmlm::List )
	end
	
	it "raises an exception when asked for a list whose name contains invalid characters" do
		lambda {
			@service.get_list( 'glarg beegun' )
		}.should raise_error( ArgumentError )
	end
	
	it "can iterate over listdirs, yielding each as a Ezmlm::List object" do
		Ezmlm.should_receive( :each_list ).with( Pathname.new(@dummydir) ).and_yield( :a_list )
		@service.each_list {|l| l.should == :a_list }
	end
	
end

# listservice = DRbObject.new( nil, 'druby://lists.laika.com:23431' )
# announce = listservice.each_list do |list|
# 	last_posts << list.last_post
# end
# announce = listservice.get_list( 'announce' )
# 
# announce.last_post
# 
# 

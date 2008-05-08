#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec/runner'
	require 'spec/lib/helpers'
	require 'ezmlm/list'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


describe Ezmlm::List do
	include Ezmlm::SpecHelpers


	LISTDIR = Pathname.new( 'list' )

	TEST_SUBSCRIBERS = %w[
		pete.chaffee@toadsmackers.com
		dolphinzombie@alahalohamorra.com
		piratebanker@yahoo.com
	  ]

	TEST_MODERATORS = %w[
		dolphinzombie@alahalohamorra.com
	  ]

	TEST_OWNER = 'listowner@rumpus-the-whale.info'

	TEST_CUSTOM_MODERATORS_DIR = '/foo/bar/clowns'
		



	it "can create a new list"

	### 
	### List manager functions
	### 
	describe "list manager functions" do
		
		before( :each ) do
			@listpath = LISTDIR.dup
			@list = Ezmlm::List.new( @listpath )
		end
		
		
		it "can return a list of subscribers' email addresses" do
			subscribers_dir = LISTDIR + 'subscribers'
			
			expectation = Pathname.should_receive( :glob ).with( subscribers_dir + '*' )

			TEST_SUBSCRIBERS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end
				
			subscribers = @list.subscribers
			
			subscribers.should have(TEST_SUBSCRIBERS.length).members
			subscribers.should include( *TEST_SUBSCRIBERS )
		end


		### Subscriber moderation

		it "knows that subscription moderation is enabled if the dir/modsub file exists" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_closed()
		end
		
		it "knows that subscription moderation is enabled if the dir/remote file exists" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_closed()
		end
		
		
		it "knows that subscription moderation is disabled if neither the dir/modsub nor " +
		   "dir/remote files exist" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( false )

			@list.should_not be_closed()
		end


		it "returns an empty array of subscription moderators for an open list" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( false )

			@list.subscription_moderators.should be_empty()
		end
	
		it "can return a list of subscription moderators' email addresses" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( true )
			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).once.and_return( true )

			# Try to read directory names from both config files
			modsub_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			remote_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			
			# Read subscribers from the default directory
			subscribers_dir = mock( "Mock moderator subscribers directory" )
			@listpath.should_receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			subscribers_dir.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		
		it "can return a list of subscription moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( true )
			@listpath.should_receive( :+ ).with( 'remote' )

			# Try to read directory names from both config files
			modsub_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			modsub_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		it "can get a list of modererators when remote subscription moderation is enabled" +
           " and the modsub configuration is empty" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( false )
            remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).twice.and_return( remote_path_obj )
            remote_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			remote_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			remote_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end

		### Message moderation
		
		it "knows that subscription moderation is enabled if the dir/modpost file exists" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_moderated()
		end
		
		it "knows that subscription moderation is disabled if the dir/modpost file doesn't exist" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( false )

			@list.should_not be_moderated()
		end


		it "returns an empty array of message moderators for an open list" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( false )

			@list.message_moderators.should be_empty()
		end
	
	
		it "can return a list of message moderators' email addresses" do
			# Test the moderation config file for existence
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from the config file
			modpost_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			
			# Read subscribers from the default directory
			subscribers_dir = mock( "Mock moderator subscribers directory" )
			@listpath.should_receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			subscribers_dir.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		
		it "can return a list of message moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			modpost_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			modpost_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end


		### List owner
		
		TEST_CONFIG_WITHOUT_OWNER = <<-"EOF".gsub( /^\t+/, '' )
		F:-aBCDeFGHijKlMnOpQrStUVWXYZ
		X:
		D:/var/qmail/alias/lists/waffle-lovers/
		T:/var/qmail/alias/.qmail-waffle-lovers
		L:waffle-lovers
		H:lists.syrup.info
		C:
		0:
		3:
		4:
		5:
		6:
		7:
		8:
		9:
		EOF
		
		it "returns nil when the list doesn't have an owner in its config" do
			config_path_obj = mock( "Config path object" )
			@listpath.should_receive( :+ ).with( 'config' ).and_return( config_path_obj )
			config_path_obj.should_receive( :read ).and_return( TEST_CONFIG_WITHOUT_OWNER )

			@list.owner.should == nil
		end
		
			
		TEST_CONFIG_WITH_OWNER = <<-"EOF".gsub( /^\t+/, '' )
		F:-aBCDeFGHijKlMnOpQrStUVWXYZ
		X:
		D:/var/qmail/alias/lists/waffle-lovers/
		T:/var/qmail/alias/.qmail-waffle-lovers
		L:waffle-lovers
		H:lists.syrup.info
		C:
		0:
		3:
		4:
		5:#{TEST_OWNER}
		6:
		7:
		8:
		9:
		EOF
		
		it "can return the email address of the list owner" do
			config_path_obj = mock( "Config path object" )
			@listpath.should_receive( :+ ).with( 'config' ).and_return( config_path_obj )
			config_path_obj.should_receive( :read ).and_return( TEST_CONFIG_WITH_OWNER )

			@list.owner.should == TEST_OWNER
		end

	end
	
	### 
	### Archive functions
	### 
	it "can return the count of archived posts"

	it "can return a hash of the subjects of all archived posts to message ids"
	it "can return an Array of the subjects of all archived posts"

	it "can return a hash of the threads of all archived posts to message ids"
	it "can return an Array of the threads of all archived posts"

	it "can return a hash of the authors of all archived posts to message ids"
	it "can return an Array of the authors of all archived posts"


	it "can fetch the body of an archived post by message id"
	it "can fetch the header of an archived post by message id"

	it "can fetch the date of the last archived post"
	it "can fetch the author of the last archived post"
	it "can fetch the subject of the last archived post"

end



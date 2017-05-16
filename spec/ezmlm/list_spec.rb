# vim: set nosta noet ts=4 sw=4 ft=rspec:

require_relative '../spec_helpers'

describe Ezmlm::List do

	before( :each ) do
		@listdir = make_listdir()
	end

	after( :each ) do
		rm_r( @listdir )
	end

	let( :list ) do
		described_class.new( @listdir )
	end


	it "returns the list name" do
		expect( list.name ).to eq( TEST_LIST_NAME )
	end

	it "returns the list host" do
		expect( list.host ).to eq( TEST_LIST_HOST )
	end

	it "returns the list address" do
		expect( list.address ).to eq( TEST_LIST_NAME + '@' + TEST_LIST_HOST )
	end

	it "returns nil if the list owner isn't an email address" do
		expect( list.owner ).to eq( nil )
	end

	it "returns an email address owner" do
		expect( list ).to receive( :read ).with( 'owner' ).and_return( TEST_OWNER )
		expect( list.owner ).to eq( TEST_OWNER )
	end


	it "can add a new subscriber" do
		list.add_subscriber( *TEST_SUBSCRIBERS )
		expect( list.is_subscriber?( TEST_SUBSCRIBERS.first ) ).to be_truthy
	end

	it "returns the list of subscibers" do
		list.add_subscriber( *TEST_SUBSCRIBERS )
		list.add_subscriber( 'notanemailaddress' )
		expect( list.subscribers.length ).to eq( 3 )
		expect( list.subscribers ).to include( TEST_SUBSCRIBERS.first )
	end

	it "can remove a current subscriber" do
		list.add_subscriber( *TEST_SUBSCRIBERS )
		list.remove_subscriber( 'notanemailaddress' )
		list.remove_subscriber( TEST_MODERATORS.first )
		expect( list.subscribers.length ).to eq( 2 )
	end


	it "can add a new moderator" do
		list.add_moderator( *TEST_MODERATORS )
		expect( list.is_moderator?( TEST_MODERATORS.first ) ).to be_truthy
	end

	it "returns the list of moderators" do
		list.add_moderator( *TEST_MODERATORS )
		expect( list.moderators.length ).to eq( 1 )
		expect( list.moderators ).to include( TEST_MODERATORS.first )
	end

	it "can remove a current moderator" do
		list.add_moderator( *TEST_MODERATORS )
		list.remove_moderator( TEST_MODERATORS.first )
		expect( list.moderators ).to be_empty
	end


	it "can add a blacklisted address" do
		list.add_blacklisted( *TEST_MODERATORS )
		expect( list.is_blacklisted?( TEST_MODERATORS.first ) ).to be_truthy
	end

	it "returns the list of blacklisted addresses" do
		list.add_blacklisted( *TEST_MODERATORS )
		expect( list.blacklisted.length ).to eq( 1 )
		expect( list.blacklisted ).to include( TEST_MODERATORS.first )
	end

	it "can remove a blacklisted address" do
		list.add_blacklisted( *TEST_MODERATORS )
		list.remove_blacklisted( TEST_MODERATORS.first )
		expect( list.blacklisted ).to be_empty
	end


	it "can add an allowed address" do
		list.add_allowed( *TEST_MODERATORS )
		expect( list.is_allowed?( TEST_MODERATORS.first ) ).to be_truthy
	end

	it "returns the list of allowed addresses" do
		list.add_allowed( *TEST_MODERATORS )
		expect( list.allowed.length ).to eq( 1 )
		expect( list.allowed ).to include( TEST_MODERATORS.first )
	end

	it "can remove a allowed address" do
		list.add_allowed( *TEST_MODERATORS )
		list.remove_allowed( TEST_MODERATORS.first )
		expect( list.allowed ).to be_empty
	end


	it 'returns the current public/private state' do
		expect( list.public? ).to be_truthy
		expect( list.private? ).to be_falsey
	end

	it 'can set the privacy state' do
		list.public = false
		expect( list.public? ).to be_falsey
		expect( list.private? ).to be_truthy

		list.private = false
		expect( list.private? ).to be_falsey
		expect( list.public? ).to be_truthy
	end


	it 'can set the remote subscription state' do
		expect( list.remote_subscriptions? ).to be_falsey
		list.remote_subscriptions = true
		expect( list.remote_subscriptions? ).to be_truthy
		list.remote_subscriptions = false
		expect( list.remote_subscriptions? ).to be_falsey
	end


	it 'can set subscription moderation state' do
		expect( list.moderated_subscriptions? ).to be_falsey
		list.moderated_subscriptions = true
		expect( list.moderated_subscriptions? ).to be_truthy
		list.moderated_subscriptions = false
		expect( list.moderated_subscriptions? ).to be_falsey
	end


	it 'can set posting moderation state' do
		expect( list.moderated? ).to be_falsey
		list.moderated = true
		expect( list.moderated? ).to be_truthy
		list.moderated = false
		expect( list.moderated? ).to be_falsey
	end


	it 'can set moderation-only posting' do
		expect( list.moderator_posts_only? ).to be_falsey
		list.moderator_posts_only = true
		expect( list.moderator_posts_only? ).to be_truthy
		list.moderator_posts_only = false
		expect( list.moderator_posts_only? ).to be_falsey
	end


	it 'can set user-only posting' do
		expect( list.user_posts_only? ).to be_falsey
		list.user_posts_only = true
		expect( list.user_posts_only? ).to be_truthy
		list.user_posts_only = false
		expect( list.user_posts_only? ).to be_falsey
	end


	it 'user+moderation together sets non-subscriber moderation' do
		expect( list.user_posts_only? ).to be_falsey
		expect( list.moderated? ).to be_falsey

		list.moderated = true
		list.user_posts_only = true

		expect( list.listdir + 'noreturnposts' ).to exist

		list.moderated = false
		expect( list.listdir + 'noreturnposts' ).to_not exist
	end


	it 'can set archival status' do
		expect( list.archived? ).to be_truthy
		list.archived = false
		expect( list.archived? ).to be_falsey
		list.archived = true
		expect( list.archived? ).to be_truthy
	end


	it 'can limit archive access to moderators only' do
		expect( list.private_archive? ).to be_falsey
		list.private_archive = true
		expect( list.private_archive? ).to be_truthy
		list.private_archive = false
		expect( list.private_archive? ).to be_falsey
	end


	it 'can limit archive access to list subscribers only' do
		expect( list.guarded_archive? ).to be_falsey
		list.guarded_archive = true
		expect( list.guarded_archive? ).to be_truthy
		list.guarded_archive = false
		expect( list.guarded_archive? ).to be_falsey
	end


	it 'can toggle digest status' do
		expect( list.digested? ).to be_falsey
		list.digest = true
		expect( list.digested? ).to be_truthy
		list.digest = false
		expect( list.digested? ).to be_falsey
	end

	it 'returns a default digest kbyte size' do
		expect( list.digest_kbytesize ).to eq( 64 )
	end

	it 'can set a new digest kbyte size' do
		list.digest_kbytesize = 300
		expect( list.digest_kbytesize ).to eq( 300 )
	end

	it 'returns a default digest message count' do
		expect( list.digest_count ).to eq( 10 )
	end

	it 'can set a new digest message count' do
		list.digest_count = 25
		expect( list.digest_count ).to eq( 25 )
	end

	it 'returns a default digest timeout' do
		expect( list.digest_timeout ).to eq( 48 )
	end

	it 'can set a new digest timeout' do
		list.digest_timeout = 24
		expect( list.digest_timeout ).to eq( 24 )
	end


	it 'can set subscription confirmation' do
		expect( list.confirm_subscriptions? ).to be_truthy
		list.confirm_subscriptions = false
		expect( list.confirm_subscriptions? ).to be_falsey
		list.confirm_subscriptions = true
		expect( list.confirm_subscriptions? ).to be_truthy
	end

	it 'can set unsubscription confirmation' do
		expect( list.confirm_unsubscriptions? ).to be_truthy
		list.confirm_unsubscriptions = false
		expect( list.confirm_unsubscriptions? ).to be_falsey
		list.confirm_unsubscriptions = true
		expect( list.confirm_unsubscriptions? ).to be_truthy
	end


	it 'can set message posting confirmation' do
		expect( list.confirm_postings? ).to be_falsey
		list.confirm_postings = true
		expect( list.confirm_postings? ).to be_truthy
		list.confirm_postings = false
		expect( list.confirm_postings? ).to be_falsey
	end


	it 'can toggle remote subscriber lists for moderators' do
		expect( list.allow_remote_listing? ).to be_falsey
		list.allow_remote_listing = true
		expect( list.allow_remote_listing? ).to be_truthy
		list.allow_remote_listing = false
		expect( list.allow_remote_listing? ).to be_falsey
	end


	it 'can toggle bounce management' do
		expect( list.bounce_warnings? ).to be_truthy
		list.bounce_warnings = false
		expect( list.bounce_warnings? ).to be_falsey
		list.bounce_warnings = true
		expect( list.bounce_warnings? ).to be_truthy
	end


	it 'returns a default max message size' do
		expect( list.maximum_message_size ).to eq( 0 )
	end

	it 'can set a new max message size' do
		list.maximum_message_size = 1024 * 300
		expect( list.maximum_message_size ).to eq( 307200 )
	end


	it 'can return the total message count for a pristine list' do
		expect( list ).to receive( :read ).with( 'archnum' ).and_return( nil )
		expect( list.message_count ).to eq( 0 )
	end

	it 'can return the total message count for a list with deliveries' do
		expect( list.message_count ).to eq( 150 )
	end


	it 'can generate a message number to thread index' do
		idx = list.index
		expect( idx.size ).to be( 150 )
		expect( idx[39][:thread] ).to eq( 'cadgeokhhaieijmndokb' )
	end


	it 'fetches thread objects upon request' do
		expect( list.thread('cadgeokhhaieijmndokb') ).to be_a( Ezmlm::List::Thread )
	end

	it 'returns nil when fetching an invalid thread' do
		expect( list.thread('whatever') ).to be_nil
	end


	it 'fetches author objects upon request' do
		expect( list.author('ojjhjlapnejjlbcplabi') ).to be_a( Ezmlm::List::Author )
	end

	it 'fetches author objects by email address' do
		author = list.author( 'ojjhjlapnejjlbcplabi' )
		expect( list.author('yvette@example.net').name ).to eq( author.name )
	end

	it 'returns nil when fetching an invalid author' do
		expect( list.author('whatever') ).to be_nil
	end


	context 'fetching messages' do
		it 'returns nil if archiving is disabled' do
			expect( list ).to receive( :archived? ).and_return( false )
			expect( list.message(1) ).to be_nil
		end

		it 'returns nil when fetching an invalid message id' do
			expect( list.message(2389234) ).to be_nil
		end

		it 'raises an error if the message archive is empty' do
			expect( list ).to receive( :message_count ).and_return( 0 )
			expect {
				list.message( 1 )
			}.to raise_error( RuntimeError, /message archive is empty/i )
		end

		it 'returns an archived message' do
			message = list.message( 1 )
			expect( message.id ).to be( 1 )
			expect( message.subject ).to match( /compress program/ )
		end

		it 'can iterate across all messages' do
			message = nil
			list.each_message do |m|
				if m.id == 20
					message = m
					break
				end
			end
			expect( message ).to_not be_nil
			expect( message.id ).to be( 20 )
		end
	end
end


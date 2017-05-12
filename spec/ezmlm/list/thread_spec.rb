# vim: set nosta noet ts=4 sw=4 ft=rspec:

require_relative '../../spec_helpers'


describe Ezmlm::List::Thread do

	before( :all ) do
		@listdir = make_listdir()
	end

	after( :all ) do
		rm_r( @listdir )
	end

	let( :list ) do
		Ezmlm::List.new( @listdir )
	end

	let ( :thread_id ) { "hdohjgmgfakappbhjnkp" }


	context 'instantiating' do

		it 'raises error if provided an unknown list object' do
			expect {
				described_class.new( true, 1 )
			}.to raise_error( ArgumentError, /unknown list/i )
		end

		it 'raises error if thread indexing is disabled' do
			expect( list ).to receive( :threaded? ).and_return( false )
			expect {
				described_class.new( list, thread_id )
			}.to raise_error( RuntimeError, /indexing is not enabled/i )
		end

		it 'raises error if passed a malformed thread ID' do
			expect {
				described_class.new( list, 'whatever' )
			}.to raise_error( ArgumentError, /malformed/i )
		end

		it 'raises error when unable to read thread file' do
			allow( list ).to receive( :listdir ).and_return( Pathname('/nope') )
			expect( list ).to receive( :threaded? ).and_return( true )
			expect {
				described_class.new( list, thread_id )
			}.to raise_error( RuntimeError, /unknown thread/i )
		end

		it 'parses a thread index from the archive' do
			thread = described_class.new( list, thread_id  )
			expect( thread ).to be_a( Ezmlm::List::Thread )
		end


		context 'an instance of' do

			let( :thread ) { described_class.new( list, thread_id ) }

			it 'knows its subject' do
				expect( thread.subject ).to match( /ai on the microchip/i )
			end

			it 'contains a list of message ids' do
				expect( thread.messages ).to eq( [20, 108] )
			end

			it 'contains a list of author ids' do
				expect( thread.authors ).to eq( ["mdncdmmkeffdjkopffbj", "ffcambaeljjifcodfjoc"] )
			end

			it 'holds messages that belong to the thread' do
				expect( thread.messages.size ).to be( 2 )
				expect( thread.first.subject ).to match( /microchip/i )
				expect( thread.first.body.to_s ).to match( /protocol/i )
				expect( thread.first.from.first ).to match( /block@example.net/i )
			end

			it 'is enumerable' do
				expect( thread.any?{|m| m.id == 20 }).to be_truthy
			end
		end
	end
end


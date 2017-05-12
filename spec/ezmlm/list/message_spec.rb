# vim: set nosta noet ts=4 sw=4 ft=rspec:

require_relative '../../spec_helpers'


describe Ezmlm::List::Message do

	before( :all ) do
		@listdir = make_listdir()
	end

	after( :all ) do
		rm_r( @listdir )
	end

	let( :list ) do
		Ezmlm::List.new( @listdir )
	end


	context 'instantiating' do

		it 'raises error if provided an unknown list object' do
			expect {
				described_class.new( true, 1 )
			}.to raise_error( ArgumentError, /unknown list/i )
		end

		it 'raises error if given a message number smaller than possible' do
			expect {
				described_class.new( list, -20 )
			}.to raise_error( ArgumentError, /invalid message number \(impossible/i )
			expect {
				described_class.new( list, 0 )
			}.to raise_error( ArgumentError, /invalid message number \(impossible/i )
		end

		it 'raises error if given a message higher than the list count' do
			expect {
				described_class.new( list, 200 )
			}.to raise_error( ArgumentError, /invalid message number \(out of list/i )
		end

		it 'raises error when unable to read message' do
			allow( list ).to receive( :listdir ).and_return( Pathname('/nope') )
			expect( list ).to receive( :message_count ).and_return( 1 )
			expect {
				described_class.new( list, 1 )
			}.to raise_error( RuntimeError, /unable to determine message path/i )
		end

		it 'parses a message from the archive' do
			message = described_class.new( list, 1 )
			expect( message ).to be_a( Ezmlm::List::Message )
		end


		context 'an instance of' do

			let( :message ) { described_class.new( list, 1 ) }

			it 'can be stringified' do
				expect( message.to_s ).to match( /need to copy the wireless/ )
			end

			it 'knows what thread it is a member of' do
				expect( message.thread ).to be_a( Ezmlm::List::Thread )
				expect( message.thread.id ).to eq( 'dipjdfoipmjmlcnacell' )
			end

			it 'knows the author' do
				expect( message.author ).to be_a( Ezmlm::List::Author )
				expect( message.author.id ).to eq( 'odhojfifmnbblilkmbfh' )
			end

			it 'passes all other method calls to the underlying Mail::Message' do
				expect( message.to.first ).to eq( 'testlist@lists.laika.com' )
				expect( message.body.to_s ).to match( /need to copy the wireless/ )
				expect( message.subject ).to match( /Trying to compress/ )
			end
		end
	end
end

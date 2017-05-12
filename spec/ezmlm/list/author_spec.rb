# vim: set nosta noet ts=4 sw=4 ft=rspec:

require_relative '../../spec_helpers'


describe Ezmlm::List::Author do

	before( :all ) do
		@listdir = make_listdir()
	end

	after( :all ) do
		rm_r( @listdir )
	end

	let( :list ) do
		Ezmlm::List.new( @listdir )
	end

	let ( :author_id ) { "idijebinbeadbfecldlb" }


	context 'instantiating' do

		it 'raises error if provided an unknown list object' do
			expect {
				described_class.new( true, 1 )
			}.to raise_error( ArgumentError, /unknown list/i )
		end

		it 'raises error if thread indexing is disabled' do
			expect( list ).to receive( :threaded? ).and_return( false )
			expect {
				described_class.new( list, author_id )
			}.to raise_error( RuntimeError, /indexing is not enabled/i )
		end

		it 'raises error if passed a malformed author ID' do
			expect {
				described_class.new( list, 'whatever' )
			}.to raise_error( ArgumentError, /malformed/i )
		end

		it 'raises error when unable to read index file' do
			allow( list ).to receive( :listdir ).and_return( Pathname('/nope') )
			expect( list ).to receive( :threaded? ).and_return( true )
			expect {
				described_class.new( list, author_id )
			}.to raise_error( RuntimeError, /unknown author/i )
		end

		it 'parses an author index from the archive' do
			author = described_class.new( list, author_id  )
			expect( author ).to be_a( Ezmlm::List::Author )
		end

		context 'an instance of' do

			let( :author ) { described_class.new( list, author_id ) }

			it 'knows the author name' do
				expect( author.name ).to match( /Jessy Labadie/i )
			end

			it 'holds messages that belong to the author' do
				expect( author.messages.size ).to be( 1 )
				expect( author.first.subject ).to match( /interface/i )
				expect( author.first.body.to_s ).to match( /protocol/i )
				expect( author.first.from.first ).to match( /karianne@example.net/i )
			end

			it 'holds threads that the author has participated in' do
				expect( author.threads.size ).to be( 1 )
				expect( author.threads.first ).to eq( 'caaabjkbghlcbokpfpeg' )
			end

			it 'is enumerable' do
				expect( author.any?{|m| m.id == 111 }).to be_truthy
			end
		end
	end
end


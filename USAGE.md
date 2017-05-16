
Usage
=======

Here's a quick rundown of how to use this library.  For specifics, see
the generated RDoc.


Examples
--------


*Print the list address for all lists in a directory*:

	Ezmlm.each_list( '/lists' ) do |list|
		puts list.address
	end


*Check if I'm subscribed to a list, and if so, unsubscribe*:

(You don't really have to check first, subscribe and unsubscribe are
idempotent.)

	list = Ezmlm::List.new( '/lists/waffle-lovers' )

	if list.include?( 'mahlon@martini.nu' )
		list.unsubscribe( 'mahlon@martini.nu' )
	end

	puts "The list now has %d subscribers!" % [ list.subscribers.size ]


*Iterate over the subscriber list*:

	list.subscribers.each do |subscriber|
		# ...
	end


*Make the list moderated, and add a moderator*:

	list.moderated = true
	list.add_moderator( 'mahlon@martini.nu' )
	list.moderated? #=> true

All other list behavior tunables operate in a similar fashion, see RDoc
for details.


*Archiving!*

All of the archival pieces take advantage of Ezmlm-IDX extensions.
If you want to use these features, you'll want to enable archiving
and indexing for your lists, using the -a and -i flags to ezmlm-make.
(Enabling archiving with this library also enables indexing and thread
indexes, I assume that since you're using ezmlm-idx, you want these
enhancements!)

	list.archived? #=> false
	list.archived = true
	list.archived? #=> true

If your list(s) already had archiving enabled (the default to
ezmlm-make) but not indexing, you can manually run ezmlm-archive to
rebuild the necessary files - afterwards, they are kept up to date
automatically.


*How many messages are in the archive?*:

	list.message_count #=> 123


*Fetch message number 100 from the archive*:

	message = list.message( 100 ) or abort "No such message."

	puts message.subject
	puts message.body.to_s # Print just the body of the message.
	puts message.to_s      # Print the entire, unparsed message.

	thread = message.thread # Returns an Ezmlm::List::Thread object
	author = message.author # Returns an Ezmlm::List::Author object

As a general rule, methods called on the Ezmlm::List object return nil
if they are unable to perform the requested task.  Instantiating the
underlying objects directly raise with a specific error.  The following
are equivalent, but behave differently:

	message = list.message( 10000 ) # nonexistent message, returns nil
	message = Ezmlm::List::Message.new( list, 10000 ) # Raises a RuntimeError 

Message objects act as "Mail" objects from the excellent library from
Mikel Lindsaar (https://github.com/mikel/mail).  See its documentation
for specifics.


*Iterate over messages in a specific thread*:

Messages know what thread they belong to.  Once you have a thread object
from a message, it is an enumerable.  Iterate or sort on it using
standard Ruby methods.

	thread.each do |message|
		# ...
	end

Threads are also aware of who participated in the conversation, via the
'authors' and 'each_author' methods.


*Iterate over messages from a specific author:*

Messages know who authored them.  Once you have an author object from a
message, it is an enumerable.  Iterate or sort on it using standard Ruby
methods.

	author.each do |message|
		# ...
	end

An Author object is also aware of all threads the author participated
in, via the 'threads' and 'each_thread' methods.



require 'drb'
DRb.start_service
lists = DRbObject.new( nil, 'druby://localhost:32315' )
l = lists.get_list( 'announce' )
l.last_post


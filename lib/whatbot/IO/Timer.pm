###########################################################################
# whatbot/IO/Timer.pm
###########################################################################
#
# Timer functionality for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::Timer extends whatbot::IO {
    # time_queue is an array. each item is of the form:
    #  [ int time, coderef sub, ...  ]
    #
    # "..." can be any number of args to be sent to the sub when it is called at time.
    has 'time_queue' => ( is => 'rw', isa => 'ArrayRef', default => sub { return [] } );
    has 'next_time'  => ( is => 'rw', isa => 'Int', default => 0 );

    method BUILD ($) {
        $self->name('Timer');
        $self->me( $self->name );
    }

    method enqueue ( Int $time, $sub, @args ) {
    	$time += time if ( $time < 86400 );
	
    	my $new_item = [$time, $sub, @args];
    	my $queue = $self->time_queue;
	
        # add and sort 
        push @$queue, $new_item;
        @$queue = sort { $a->[0] <=> $b->[0] } @$queue;

    	$self->next_time($queue->[0]->[0]);
    }

    method remove ( Int $time, $sub, @args ) {
    	# remove the first perfect match. I doubt this will be called much, 
    	# but here it is anyway
    	my $match_item = [$time, $sub, @args];
    	my $queue = $self->time_queue;
	
        print STDERR "match item: (", join(', ', @$match_item), ")\n";

    	if (@$queue) {
ITEMLOOP:   foreach my $index (0 .. $#{$queue}) {
    			my $item = $queue->[$index];

                print STDERR "item $index: (", join(', ', @$item), ")\n";
			
    			next if (@$item != @$match_item);

    			my $i;
    			for ($i = 0; $i <= $#$item; $i++) {
    				if ($item->[$i] ne $match_item->[$i]) {
    					next ITEMLOOP;
    				}
    			}

   				# remove it!
   				splice @$queue, $index, 1;
					
 				# if we took it off the front, adjust next_time
 				if ($index == 0) {
 					if (@$queue) {
 						# next time is the time of the thing at the front
 						$self->next_time($queue->[0]->[0]);
 					} else {
 						$self->next_time(0);
 					}
 				}

 				return 1;

    		} # end foreach

    	} # end if queue
	
    	return 0;
    }

    method event_loop() {
    	my $next = $self->next_time;
    	return unless $next;
	
    	my $now  = time;
    	return if ($now <= $next);
	
    	my $queue = $self->time_queue;
	
    	if (@$queue) {
    		my ($when, $sub, @args) = @{$queue->[0]};
		
    		if ($when > $now) {
    			# uh oh...
    			$self->log->error("last_time in timer was not the same as the first item in the queue...");
    		} else {
    			&$sub(@args);
    			shift @$queue;
			
    			if (@$queue) {
    				# next time is the time of the thing at the front
    				$self->next_time($queue->[0]->[0]);
    			} else {
    				$self->next_time(0);
    			}
    		}
    	}
    }
}

1;

=pod

=head1 NAME

whatbot::IO::Timer - Timer functionality for whatbot.

=head1 SYNOPSIS

 sub something_awesome : GlobalRegEx('do it later') {
     my ( $self, $message ) = @_;
     
     my $medium = $message->origin;
     $self->timer->enqueue(10, \&done_later, $self, $medium, "it");
     return "ok";
 }

 sub done_later {
     my ( $self, $medium, $what ) = @_;
     
     my $response = whatbot::Message->new(
         from    => $medium->me,
         to      => "",
         content => "I did $what"
     );
     
     $medium->send_message($response);
 }

=head1 DESCRIPTION

whatbot::IO::Timer - Timer functionality for whatbot.

=head1 PUBLIC METHODS

=over 4

=item enqueue($when, $sub, [@args ...])

The only way to really interact with the timer. C<$when> is in seconds -- 
either seconds since Jan 1 1970, or, if less than 86400, seconds from now. 
C<$sub> is a reference to any code, and C<@args>, if provided, are passed 
directly to that subroutine at call-time.

=item event_loop()

Called every event loop, from the main whatbot class. Runs all code scheduled
for this second. If called multiple times per second, only runs once.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::IO

=over 4

=item whatbot::IO::Timer

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut

###########################################################################
# whatbot/Store.pm
###########################################################################
# Base class for whatbot Storage
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Store extends whatbot::Component {
    use Digest::SHA1 qw(sha1_hex);

    has 'handle' => ( is => 'rw', isa => 'Any' );

    method connect {
    }

    method store ( $table, $assignRef ) {
    }

    method retrieve ( $table, $columnRef, $queryRef, $numberItems ) {
    }

    method delete ( $table, $queryRef ) {
    }

    method update ( $table, $assignRef, $queryRef ) {
    }

    method factoid ( $subject, $is?, $from?, $plural? ) {
    	return if (!$subject);
    	
    	my $original = $subject;
    	$subject = lc($subject);
	
    	# Get existing factoid info, if available
    	my ($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
    	return undef if (!defined($factoid) and !$is);
	
    	# Assign fact info if defined
    	if ($is) {
		
    		# Nuke all factoids if user says no
    		if ($subject =~ /no, /i) {
    			$subject =~ s/no, //i;
    			$self->forget($subject);
    		}
		
    		unless (defined $factoid) {
    			# Check if ignore
    			return undef if ($self->ignore($subject));
			
    			# Check if plural
    			my $isPlural = $plural;
    			# if (length($subject) > 2 and $subject =~ /s$/ and $subject !~ /'s$/) {
    			# 	if ($subject =~ /(s|z|x|sh|ch|[^aeiou]y)es$/) {
    			# 		$isPlural = 1;
    			# 	} elsif ($original =~ /^[A-Z][a-z]+$/) {
    			# 		$isPlural = 0;
    			# 	}
    			# }
			
    			$self->store("factoid", {
    				is_or		=> 0,
    				is_plural	=> $isPlural,
    				created		=> time,
    				updated		=> time,
    				subject		=> $subject
    			});
    			($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
    		}
		
    		# Remove also, because we don't care
    		my $also = 0;
    		if ($is =~ /^also/) {
    			$also = 1;
    			$is =~ s/^also //;
    		}
		
    		# Nuke <reply> if not or and more than one fact
    		if ($is =~ /^<reply>/) {
    			my ($factoidCount) = @{ $self->retrieve("factoid_description", [ "COUNT(*) AS count" ], { factoid_id => $factoid->{factoid_id}}) };
    			unless ($factoidCount->{count} == 0 or (defined $factoid->{is_or} and $factoid->{is_or} == 1)) {
    				return undef;
    			}
    		}
		
    		# Nuke response if we already have a reply
    		my ($firstFact) = @{ $self->retrieve(
    			"factoid_description",
    			[qw/description/],
    			{ factoid_id => $factoid->{factoid_id} },
    			1
    		) };
    		if (defined $firstFact and $firstFact->{description} =~ /^<reply>/) {
    			return undef;
    		}	
			
    		# Check if exists
    		if (defined $factoid
    			and my ($desc) = @{ $self->retrieve("factoid_description", [qw/factoid_id/], { factoid_id => $factoid->{factoid_id}, hash => sha1_hex($is) }) }) {
    			return undef;
    		}
		
    		if ($is =~ /\|\|/) {
    			$self->update('factoid', { is_or => 1 }, { factoid_id => $factoid->{factoid_id} });
    			($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
    			foreach my $fact (split(/ \|\| /, $is)) {
    				$self->store("factoid_description", {
    					factoid_id	=> $factoid->{factoid_id},
    					description	=> $fact,
    					hash		=> sha1_hex($fact),
    					user		=> $from,
    					updated		=> time
    				});
    			}
    		} else {
    			my $result = $self->store("factoid_description", {
    				factoid_id	=> $factoid->{factoid_id},
    				description	=> $is,
    				hash		=> sha1_hex($is),
    				user		=> $from,
    				updated		=> time
    			});
    		}
    	}
	
    	# Retrieve factoid description
    	my @facts = @{ $self->retrieve(
    		"factoid_description",
    		[qw/description user/],
    		{ factoid_id => $factoid->{factoid_id} }
    	) };
	
    	# If facts are given, return hashref of factoid data and facts
    	if (@facts) {
    		if (scalar(@facts) == 1) {
    			return {
    				user => $facts[0]->{user},
    				factoid => $factoid,
    				facts => [ $facts[0]->{description} ],
    			};
    		} else {
    			$_ = $_->{description} foreach @facts;
    			return {
    				factoid	=> $factoid,
    				facts	=> \@facts
    			};
    		}
    	}
	
    	return undef;
    }

    method forget ( Str $subject ) {
    	$subject = lc($subject);
	
    	my ($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id/], { subject => $subject }) };
    	return undef unless (defined $factoid);
	
    	$self->delete("factoid_description", { factoid_id => $factoid->{factoid_id} });
    	$self->delete("factoid", { factoid_id => $factoid->{factoid_id} });
	
    	return 1;
    }

    method ignore ( Str $subject, $store? ) {
    	$subject = lc($subject);
	
    	my ($ignore) = @{ $self->retrieve("factoid_ignore", [qw/subject/], { subject => $subject }) };
	
    	if ($store and !defined $ignore) {
    		$self->store("factoid_ignore", { subject => $subject });
    		($ignore) = @{ $self->retrieve("factoid_ignore", [qw/subject/], { subject => $subject }) };
    	}
	
    	return $ignore;
    }

    method seen ( $user, $message ) {
    	$user = lc($user);
	
    	my ($itemRef) = @{$self->retrieve("seen", [qw/user timestamp message/], { user => $user })};
    	if (defined $message) {
    		$self->delete("seen", { user => $user });
    		$self->store("seen", { user => $user, message => $message, timestamp => time });
    		($itemRef) = @{$self->retrieve("seen", [qw/user timestamp message/], { user => $user })};
    	}
	
    	return $itemRef;
    }
}

1;

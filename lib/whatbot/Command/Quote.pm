###########################################################################
# whatbot/Command/Quote.pm
###########################################################################
# DEFAULT: Quote
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Quote;
use Moose;
use HTML::Entities;
BEGIN {
	extends 'whatbot::Command';
	with 'whatbot::Command::Role::Template';
}

use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
	if (
		$self->my_config
		and $self->my_config->{enabled}
		and $self->my_config->{enabled} eq 'yes'
	) {
		$self->web(
			'/quote',
			\&quote_list
		);
	}
}

sub help : Command {
    my ( $self ) = @_;
    
    return [
        'Quote is available through a web browser at '
        . sprintf( '%s/quote', $self->web_url() )
        . '. You may add a quote by using:',
        'quote <user> "<quote>"',
        'Example: quote AwesomeUser "That was incredible!"'
    ];
}

sub add_quote : GlobalRegEx('^quote (.*) "(.*?)"\s*$') {
	my ( $self, $message, $captures ) = @_;
	
	my $quoted = $captures->[0];
	my $content = $captures->[1];
	my $quote = $self->model('Quote')->create({
		'user'    => $message->from,
		'quoted'  => $quoted,
		'content' => encode_entities($content),
	});
	if ($quote) {
		return 'Quote added to quoteboard. ' . $self->web_url . '/quote';
	}
	return 'Could not create quote.';
}

sub quote_list {
	my ( $self, $cgi ) = @_;

	return unless ( $self->check_access($cgi) );

	my %state = ();

	print "Content-type: text/html\r\n\r\n";
	if ( $cgi->request_method eq 'POST' ) {
		$self->_submit_form( $cgi, \%state );
	}

	$state{'quotes'} = $self->model('Quote')->search({ '_order_by' => 'timestamp desc' });

	$self->template->process( _quote_list_tt2(), \%state ) or die $Template::ERROR;

	return;
}

sub _submit_form {
	my ( $self, $cgi, $state ) = @_;

	foreach my $required ( qw( nickname quoted content ) ) {
		unless ( $cgi->param($required) ) {
			$state->{'error'} = 'Missing ' . $required . '.';
			return;
		}
	}

	my $paste = $self->model('Quote')->create({
		'user'    => $cgi->param('nickname'),
		'quoted'  => $cgi->param('quoted'),
		'content' => encode_entities( $cgi->param('content') ),
	});
	if ($paste) {
		$state->{'success'} = 1;
	} else {
		$state->{'error'} = 'Unknown error creating quote.';		
	}
	return;
}

sub check_access {
	my ( $self, $cgi ) = @_;

	return unless (
		$self->my_config
		and $self->my_config->{enabled}
		and $self->my_config->{enabled} eq 'yes'
	);
	if ( $self->my_config->{limit_ip} ) {
		return unless ( $cgi->remote_addr eq $self->my_config->{limit_ip} );
	}

	return 1;
}

sub _header {
	return q{
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>[% title OR 'whatbot Quoteboard' %]</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<style type="text/css">
		body {
			padding-top: 60px;
			font-family: Candara, sans-serif;
			font-size: 14px;
		}
		div.error {
			padding: 14px;
			background-color: #fee;
			border: 1px solid #f00;
			margin-bottom: 18px;
		}
		div.success {
			padding: 14px;
			background-color: #efe;
			border: 1px solid #0f0;
			margin-bottom: 18px;
		}
		div.pastedata {
			margin-bottom: 18px;
		}
		div.code {
			padding: 14px;
		}
		div.quote-body {
			margin-bottom: 18px;
		}
	</style>
	<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
</head>
<body>
	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-inner">
		<div class="container">
			<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
			</button>
			<a class="brand" href="/quote">whatbot Quoteboard</a>
			<div class="nav-collapse collapse">
			<ul class="nav"></ul>
			</div>
		</div>
		</div>
	</div>

	<div class="container">
[% IF error %]
		<div class="error">
			[% error %]
		</div>
[% END %]
};
}

sub _footer {
	return q{
	</div>
	<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
	<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
</body>
</html>
};
}

sub _quote_list_tt2 {
	my $string = _header() . q{
[% USE date(format='%Y-%m-%d at %H:%M:%S %Z') %]
[% IF success %]
		<div class="success">
			Quote added successfully.
		</div>
[% END %]
		<p>
			This is the whatbot Quoteboard.
		</p>
		<div class="accordion" id="accordion2">
			<div class="accordion-group">
				<div class="accordion-heading">
					<a class="accordion-toggle" data-toggle="collapse" data-parent="#accordion2" href="#collapseOne">
					Add a Quote
					</a>
				</div>
				<div id="collapseOne" class="accordion-body collapse">
					<div class="accordion-inner">
						<form method="post">
						<fieldset class="form-inline">
							<legend>Quote Info</legend>
							<input type="text" name="nickname" placeholder="Submitted By">
							<input type="text" name="quoted" placeholder="Nickname to Quote">
						</fieldset>
						<fieldset>
							<legend>Quote Text</legend>
							<textarea rows="8" name="content" class="input-xxlarge"></textarea>
						</fieldset>
						<fieldset>
							<button type="submit" class="btn">Quote</button>
						</fieldset>
						</form>
					</div>
				</div>
			</div>
		</div>
		<h2>Quotes</h2>
		<div class="quote-list">
[% FOREACH quote IN quotes %]
			<div class="quote-body">
				<blockquote>
					<p>[% quote.content FILTER html_line_break %]</p>
					<small>[% quote.quoted %], on [% date.format(quote.timestamp) %]</small>
				</blockquote>
			</div>
[% END %]
		</div>
} . _footer();
	return \$string;
}

__PACKAGE__->meta->make_immutable();

1;

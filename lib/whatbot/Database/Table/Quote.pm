###########################################################################
# whatbot/Database/Table/Quote.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::Table::Quote;
use Moose;
extends 'whatbot::Database::Table';

sub BUILD { 
    my ($self) = @_;

    $self->init_table({
        'name'        => 'quote',
        'primary_key' => 'quote_id',
        'indexed'     => [ 'user', 'quoted' ],
        'defaults'    => {
            'timestamp' => { 'database' => 'now' }
        },
        'columns'     => {
            'quote_id' => {
                'type'  => 'integer'
            },
            'timestamp' => {
                'type'  => 'integer'
            },
            'user' => {
                'type'  => 'varchar',
                'size'  => 255
            },
            'quoted' => {
                'type'  => 'varchar',
                'size'  => 255
            },
            'content' => {
                'type'  => 'text'
            },
        }
    });
}

1;

=pod

=head1 NAME

whatbot::Database::Table::Quote - Database model for Quote

=head1 SYNOPSIS

 use whatbot::Database::Table::Quote;

=head1 DESCRIPTION

whatbot::Database::Table::Quote does stuff.

=head1 METHODS

=over 4

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Quote

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut

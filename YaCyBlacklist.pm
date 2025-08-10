use strict;
use warnings;

package WWW::YaCyBlacklist;
# ABSTRACT: a Perl module to parse and execute YaCy blacklists

our $AUTHORITY = 'cpan:IBRAUN';
$WWW::YaCyBlacklist::VERSION = '0.8';

use Moose;
use Moose::Util::TypeConstraints;
use IO::All;
use URI::URL;
require 5.8.0;

=head1 SYNOPSIS

    use WWW::YaCyBlacklist;

    my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
    $ycb->read_from_array(
        'test1.co/fullpath',
        'test2.co/.*',
    );
    $ycb->read_from_files(
        '/path/to/1.black',
        '/path/to/2.black',
    );

    print "Match!" if $ycb->check_url( 'http://test1.co/fullpath' );
    my @urls = (
        'https://www.perlmonks.org/',
        'https://metacpan.org/',
    );
    my @matches = $ycb->find_matches( @urls );
    my @nonmatches = $ycb->find_non_matches( @urls );

    $ycb->sortorder( 1 );
    $ycb->sorting( 'alphabetical' );
    $ycb->filename( '/path/to/new.black' );
    $ycb->store_list( );

=method C<new(%options)>

=method C<use_regex =E<gt> 0|1> (default C<1>)

Can only be set in the constructor and never be changed any later. If C<false>, the pattern will not get checked if the
C<host> part is a regular expression (but the patterns remain in the list).
=cut

# Needed if RegExps do not compile
has 'use_regex' => (
    is  => 'ro',
    isa => 'Bool',
    default => 1,
);

=method C<filename =E<gt> '/path/to/file.black'> (default C<ycb.black>)

This is the file printed by C<store_list>
=cut

has 'filename' => (
    is  => 'rw',
    isa => 'Str',
    default => 'ycb.black',
);

has 'file_charset' => (
    is  => 'ro',
    isa => 'Str',
    default => 'UTF-8',
    init_arg => undef,
);

has 'origorder' => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
    init_arg => undef,
);

=method C<sortorder =E<gt>  0|1> (default C<0>)

0 ascending, 1 descending
Configures C<sort_list>
=cut

has 'sortorder' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

=method C<sorting =E<gt> 'alphabetical|length|origorder|random|reverse_host'> (default C<'origorder>)

Configures C<sort_list>
=cut

has 'sorting' => (
    is  => 'rw',
    isa => enum([qw[ alphabetical length origorder random reverse_host ]]),
    default => 'origorder',
);

has 'patterns' => (
    is=>'rw',
    isa => 'HashRef',
    traits  => [ 'Hash' ],
    default => sub { {} },
    init_arg => undef,
);

sub _check_host_regex {

    my ($self, $pattern) = @_;

    return 0 if $pattern =~ /^[\w\-\.\*]+$/; # underscores are not allowed in domain names but sometimes happen in subdomains
    return 1;
}

=method C<void read_from_array( @patterns )>

Reads a list of YaCy blacklist patterns.
=cut

sub read_from_array {

    my ($self, @lines) = @_;

    foreach my $line ( @lines ) {
        if ( CORE::length $line > 0 ) {
            ${ $self->patterns }{ $line }{ 'origorder' } = $self->origorder( $self->origorder + 1 );
            ( ${ $self->patterns }{ $line }{ 'host' }, ${ $self->patterns }{ $line }{ 'path' } ) = split /(?!\\)\/+?/, $line, 2;
            ${ $self->patterns }{ $line }{ 'path' } = '/' . ${ $self->patterns }{ $line }{ 'path' };
            ${ $self->patterns }{ $line }{ 'host_regex' } = $self->_check_host_regex( ${ $self->patterns }{ $line }{ 'host' } );
        }
    }
}

=method C<void read_from_files( @files )>

Reads a list of YaCy blacklist files.
=cut

sub read_from_files {

    my ($self, @files) = @_;
    my @lines;

    grep { push( @lines, io( $_ )->encoding( $self->file_charset )->chomp->slurp ) } @files;

    # chomp is not fully reliable with Windows files in Linux
    grep { my $s = $_; $s =~ s/\r$//; $s } @lines;

    $self->read_from_array( @lines );
}

=method C<int length( )>

Returns the number of patterns in the current list.
=cut

sub length {

    my $self = shift;
    return scalar keys %{ $self->patterns };
}

=method C<bool check_url( $URL )>

1 if the URL was matched by any pattern, 0 otherwise.
=cut

sub check_url {

    my $self = shift;
    my $url = shift;
    return 1 if $url !~ /^(ht|f)tps?\:\/\//i;
    $url .= '/' if $url =~ /\:\/\/[\w\-\.]+$/;
    $url = new URI $url;
    my $pq = ( defined $url->query ) ? $url->path.'?'.$url->query : $url->path;

    foreach my $pattern ( keys %{ $self->patterns } ) {

        my $path = '^' . ${ $self->patterns }{ $pattern }{ path } . '$';
        next if $pq !~ /$path/;
        my $host = ${ $self->patterns }{ $pattern }{ host };

        if ( !${ $self->patterns }{ $pattern }{ host_regex } ) {

            if ( index( ${ $self->patterns }{ $pattern }{ host }, '*') > -1 ) {

                $host =~ s/\*/.*/g;
                return 1 if $url->host =~ /^$host$/;
            }
            else {
                return 1 if index( $url->host, ${ $self->patterns }{ $pattern }{ host } ) > -1 && $url->host =~ /^([\w\-]+\.)*$host$/;
            }
        }
        else {
            return 1 if $self->use_regex && $url->host  =~ /^$host$/;
        }
    }
    return 0;
}

=method C<@URLS_OUT find_matches( @URLS_IN )>

Returns all URLs which was matches by the current list.
=cut

sub find_matches {

    my $self = shift;
    my @urls;
    grep { push( @urls, $_ ) if $self->check_url( $_ ) } @_;
    return @urls;
}

=method C<@URLS_OUT find_non_matches( @URLS_IN )>

Returns all URLs which was not matches by the current list.
=cut

sub find_non_matches {

    my $self = shift;
    my @urls;
    grep { push( @urls, $_ ) if !$self->check_url( $_ ) } @_;
    return @urls;
}

=method C<void delete_pattern( $pattern )>

Removes a pattern from the current list.
=cut

sub delete_pattern {

    my $self = shift;
    my $pattern = shift;
    delete( ${ $self->patterns }{ $pattern } ) if exists( ${ $self->patterns }{ $pattern } ) ;
}

=method C<@patterns sort_list( )>

Returns a list of patterns configured by C<sorting> and C<sortorder>.
=cut

sub sort_list {

    my $self = shift;
    return keys %{ $self->patterns } if $self->sorting eq 'random';
    my @sorted_list;

    @sorted_list = sort keys %{ $self->patterns } if $self->sorting eq 'alphabetical';
    @sorted_list = sort { CORE::length $a <=> CORE::length $b } keys %{ $self->patterns } if $self->sorting eq 'length';
    @sorted_list = sort { ${ $self->patterns }{ $a }{ origorder } <=> ${ $self->patterns }{ $b }{ origorder } } keys %{ $self->patterns } if $self->sorting eq 'origorder';
    @sorted_list = sort { reverse( ${ $self->patterns }{ $a }{ host } ) cmp reverse( ${ $self->patterns }{ $b }{ host } ) } keys %{ $self->patterns }  if $self->sorting eq 'reverse_host';

   return @sorted_list if $self->sortorder;
   return reverse( @sorted_list );
}

=method C<void store_list( )>

Prints the current list to a file. Executes C<sort_list( )>.
=cut

sub store_list {

    my $self = shift;
    join( "\n", $self->sort_list( ) ) > io( $self->filename );
}

1;
no Moose;
__PACKAGE__->meta->make_immutable;

=head1 OPERATIONAL NOTES

C<WWW::YaCyBlacklist> checks the path part including the leading separator C</>. This protects against regexp compiling errors with leading quantifiers. So do not something like C<host.tld/^path> although YaCy allows this.

C<check_url( )> alway returns true if the protocol of the URL is not C<https?> or C<ftps?>.

=head1 BUGS

YaCy does not allow host patterns with two ore more stars at the time being. C<WWW::YaCyBlacklist> does not check for this but simply executes. This is rather a YaCy bug.

If there is something you would like to tell me, there are different channels for you:

=over

=item *

L<GitHub issue tracker|https://github.com/CarlOrff/WWW-YaCyBlacklist/issues>

=item *

L<CPAN issue tracker|https://rt.cpan.org/Public/Dist/Display.html?WWW-YaCyBlacklist>

=item *

L<Project page on my homepage|https://ingram-braun.net/erga/the-www-yacyblacklist-module/>

=item *

L<Contact form on my homepage|https://ingram-braun.net/erga/legal-notice-and-contact/>

=back

=head1 SOURCE

=over

=item *

L<De:Blacklists|https://wiki.yacy.net/index.php/De:Blacklists> (German).

=item *

L<Dev:APIlist|https://wiki.yacy.net/index.php/Dev:APIlist>

=back

=head1 SEE ALSO

=over

=item *

L<YaCy homepage|https://yacy.net/>

=item *

L<YaCy community|https://community.searchlab.eu/>

=back
package Posy::Plugin::Flickr::Photo;

#
# $Id: Photo.pm,v 1.4 2005/08/03 04:22:43 blair Exp $
#

use 5.008001;
use strict;
use warnings;
use Flickr::API;
use Posy::Plugin::Cache::File 0.1;
use XML::XPath;

=head1 NAME

Posy::Plugin::Flickr::Photo - Simple inclusion of Flickr photos

=head1 VERSION

This document describes Posy::Plugin::Flickr::Photo version B<0.2>.

=cut

our $VERSION = 0.2;

=head1 SYNOPSIS

  @plugins = qw(
    Posy::Core 
    ...
    Posy::Plugin::Flickr::Photo
  );

  @entry_actions = qw(
    ...
    parse_entry
    flickr_photo
    render_entry
    ...
  );

  And in one's entry files:
    {{photo:flickr photo id}}

=head1 DESCRIPTION

This module simplifies including and linking to images hosted at
Flickr.

=head1 INTERFACE

=cut

my %cf;

=head2 init()

  $self->init();

Reads Flickr API key.

=cut
sub init {
  my $self = shift;
  $self->SUPER::init();

  # read configuration file
  my $cf = File::Spec->catfile(
    $self->{config_dir}, 'plugins', 'flickr-photo'
  );
  %cf = $self->read_config_file($cf);
  unless (defined $cf{api_key}) {
    warn "No Flickr API key defined!\n";  
  }
  1;
} # init()

=head2 flickr_photo()

  $self->flickr_photo($flow_state, $current_entry, $entry_state);

Alters C<$current_entry->{body}> by adding embedded images and links to
images hosted at Flickr wherever a properly formatted string is
encountered in the body.

=cut
sub flickr_photo {
  my ($self, $flow_state, $current_entry, $entry_state) = @_;
  my $body = $current_entry->{body};
  if ($body and ($body =~ m|{{photo:\d+?}}|)) {
    $body =~ s|{{photo:(\d+?)}}|$self->_embed_and_link_img($1)|ego;
    $current_entry->{body} = $body;
  }
  1;
} # flickr_photo()

# Fetch information via L<Flickr::API>
sub _api_get {
  my ($self, $id) = @_;
  my $api = $self->_api_init();
  my $response = $api->execute_method(
    'flickr.photos.getSizes', {
      'photo_id'  => $id
  });
  unless ($response->{success}) {
    warn "$response->{error_code} $response->{error_message}\n";
  } else {
    my $xp = XML::XPath->new(xml => $response->content);
    my $nodeset = $xp->find('//size[@label=\'Small\']');
    for my $node ($nodeset->get_nodelist) {
      if ($node->getAttribute("label") eq 'Small') {
        my $html = 
          "<div align=\"center\">\n"                                .
          "<a href=\""  . $node->getAttribute("url")    . "\">\n"   .
          "<img src=\"" . $node->getAttribute("source") . "\"/>\n"  .
          "</a>\n</div>\n";
        warn "adding ($id) to cache\n";
        $self->{cache}->set($id, $html);
        return $html;
      }
    }
  }
} # _api_get()

# Initialize L<Flickr::API>
sub _api_init {
  my $self = shift;
  return new Flickr::API({ key => $cf{api_key} });
} # _api_init()

# Initialize L<Cache::File> cache
sub _cache_init {
  my $self = shift;
  my $root = File::Spec->catfile(
    $self->{state_dir}, 'flickr-photo'
  );
  $self->{cache} = Posy::Plugin::Cache::File->new(
    cache_root      => $root,
    default_expires => '1d',
    lock_level      => Cache::File::LOCK_LOCAL
  );
} # _cache_init()

# Create HTML for embedding and linking to the Flickr photo
sub _embed_and_link_img {
  my ($self, $id) = @_;
  $self->_cache_init();
  my $html = $self->{cache}->get($id);
  unless ($html) {
    warn "failed to load ($id) from cache\n";
    return $self->_api_get($id);
  }
} # _embed_and_link_img {

=head1 SEE ALSO

L<Perl>, L<Posy>, L<Flickr::API>, L<Posy::Plugin::Cache::File>,
L<XML::XPath>, L<http://flickr.com/>

=head1 TODO

=over 4

=item * Add L<Posy::Plugin::Log4perl> support

=item * Make input pattern identifier configurable

=item * Make output configurable

=item * Make L<Posy::Plugin::Cache::File> configurable

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Posy-Plugin-Flickr-Photo@rt.cpan.org> or through the web interface
at 
L<http://rt.cpan.org>.

=head1 AUTHOR

blair christensen., E<lt>blair@devclue.comE<gt>

<http://devclue.com/blog/code/posy/Posy::Plugin::Flickr::Photo/>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by blair christensen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO
WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE
LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS
AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE
OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA
BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES
OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY
OF SUCH DAMAGES.

=cut

1;


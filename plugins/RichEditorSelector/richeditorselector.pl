# $id$
package MT::Plugin::RichEditorSelector;

use strict;
use warnings;

use MT 4.0;

use base 'MT::Plugin';
our $VERSION = '1.00';

my $plugin = __PACKAGE__->new(
    {
        name => 'Rich text editor selector',
        id => 'RichEditorSelector',
        key => 'RichEditorSelector',
        description =>
          'You can choose the favorite rich text editor.',
        author_name => 'Yuji Takayama',
        author_link => 'http://takayama.vox.com/',
        version     => $VERSION,
        settings    => new MT::PluginSettings([
            ['editor_name', { Default => 'archetype'}]
        ]),
        blog_config_template => 'config.tmpl',
    }
);

MT->add_plugin($plugin);
MT->add_callback( 'pre_run',  9, $plugin, \&_hdlr_pre_run );

sub _hdlr_pre_run {
    my ( $cb, $app ) = @_;

    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');
    return unless $blog_id;

    my $user = $app->user;
    return unless $user;
    my $user_id = $user->id;

    my $editor = $plugin->get_config_value( 'editor_name',
        'blog:' . $blog_id . ':user:' . $user_id );
    return unless $editor;

    # Switch editor
    $app->config( 'RichTextEditor', $editor );
}

sub load_config {
    my $plugin = shift;
    my ( $param, $scope ) = @_;

    my $app    = MT->instance;
    return unless $app->can('user');
    $scope .= ':user:' . $app->user->id if $scope =~ m/^blog:/;

    my $editor = $plugin->get_config_value('editor_name', $scope);
    unless ($editor) {
        my $default_config  = $plugin->settings->defaults;
        $editor = $default_config->{editor_name};
    }

    my $editors = $app->registry('richtext_editors');
    return unless $editor;

    my @editors;
    foreach my $key (keys %$editors) {
        push @editors, {name => $editors->{$key}->{label}->(), key => $key, selected => ($editor eq $key ? 1 : 0)};
    }
    $param->{editors} = \@editors;
}

sub save_config {
    my $plugin = shift;
    my $app    = MT->instance;
    return unless $app->can('user');

    my ( $param, $scope ) = @_;
    $scope .= ':user:' . $app->user->id if $scope =~ m/^blog:/;
    $plugin->SUPER::save_config( $param, $scope );
}

sub reset_config {
    my $plugin = shift;
    my $app    = MT->instance;
    return unless $app->can('user');
    my ($scope) = @_;
    $scope .= ':user:' . $app->user->id if $scope =~ m/^blog:/;
    $plugin->SUPER::reset_config($scope);
}

1;

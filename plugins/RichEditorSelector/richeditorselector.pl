# $id$
package MT::Plugin::RichEditorSelector;

use strict;
use warnings;

use MT 4.0;

use base 'MT::Plugin';
our $VERSION = '1.1';

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
        system_config_template => 'config.tmpl',
    }
);

MT->add_plugin($plugin);
MT->add_callback( 'pre_run',  9, $plugin, \&_hdlr_pre_run );
MT->add_callback( 'cms_post_save.author',  9, $plugin, \&_post_save_author );
MT->add_callback( 'MT::App::CMS::template_param.edit_author', 9, $plugin, \&_add_field );

sub _post_save_author {
    my $eh = shift;
    my ( $app, $obj, $original ) = @_;

    my $q     = $app->param;
    my $value = $q->param('editor_name');
    return unless $value;

    my $param;
    $param->{editor_name} = $value;
    $plugin->save_config($param, 'system');
}

sub _add_field {
    my ( $eh, $app, $param, $tmpl ) = @_;
    return unless UNIVERSAL::isa( $tmpl, 'MT::Template' );

    # Load from plugin config
    my $editor = _get_config_value($app);

    # Load registered editors.
    my $editors = $app->registry('richtext_editors');
    return unless $editor;

    # Make options field
    my $options;
    foreach my $key ( keys %$editors ) {
        my $selected = $editor eq $key ? 'selected="selected"' : '';
        $options
            .= '<option value="' 
            . $key . '" '
            . $selected . '>'
            . $editors->{$key}->{label}->()
            . '</option>';
    }

    # Make innerHTML
    my $innerHTML
        = '<select name="editor_name" id="editor_name" class="se">' 
        . $options
        . '</select>';

    # Transform
    my $host_node = $tmpl->getElementById('tag_delim')
        or return $app->error('cannot get the tag_delim block');
    my $block_node = $tmpl->createElement(
        'app:setting',
        {   id    => 'editor_name',
            label => 'Rich text editor',
            hint  => 'Which kind of rich text editor do you like?',
        }
    ) or return $app->error('cannot create the element');
    $block_node->innerHTML($innerHTML);
    $tmpl->insertAfter( $block_node, $host_node )
        or return $app->error('failed to insertAfter.');
}


sub _hdlr_pre_run {
    my ( $cb, $app ) = @_;

    # Load
    my $editor = _get_config_value($app);

    # Switch editor
    $app->config( 'RichTextEditor', $editor );
}

sub load_config {
    my $plugin            = shift;
    my ( $param, $scope ) = @_;

    my $app       = MT->instance;
    my $editor    = _get_config_value($app);
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

    my ( $param, $scope ) = @_;
    $scope = _get_scope($app);
    $plugin->SUPER::save_config( $param, $scope );
}

sub reset_config {
    my $plugin  = shift;
    my $app     = MT->instance;
    my ($scope) = @_;

    $scope = _get_scope($app);
    $plugin->SUPER::reset_config($scope);
}

sub _get_scope {
    my ($app) = @_;

    my $user = $app->user;
    return unless $user;

    my $user_id = $user->id;
    return 'configuration:system'.':user:' . $user_id
}

sub _get_config_value {
    my ($app, $scope)   = @_;
    $scope = _get_scope($app) unless $scope;
    my $editor = $plugin->get_config_value( 'editor_name', $scope);
    unless ($editor) {
        my $default_config  = $plugin->settings->defaults;
        $editor = $default_config->{editor_name};
    }
    return $editor;
}

1;

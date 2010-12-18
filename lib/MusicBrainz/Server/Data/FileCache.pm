package MusicBrainz::Server::Data::FileCache;
use Moose;
use namespace::autoclean;

use DBDefs;
use Digest::MD5 qw( md5_hex );
use Javascript::Closure;
use CSS::Minifier;
use IO::All;

with 'MusicBrainz::Server::Data::Role::Context';

sub modified {
    my ($self, $path) = @_;
    $path = DBDefs::STATIC_FILES_DIR . "/$path";
    my $cache = $self->c->cache('file-cache');
    my $key = "mtime:$path";

    my $mtime = $cache->get($key);
    unless (defined $mtime) {
        $mtime = (stat($path))[9];
        $cache->set($key, $mtime);
    }

    return $mtime;
}


sub squash {
    my ($self, $minifier, $suffix, @files) = @_;
    @files = map { DBDefs::STATIC_FILES_DIR . '/' . $_ } @files;
    my $hash = md5_hex(join ",", map {
        (stat($_))[9] . $_ 
    } sort @files);

    my $path = DBDefs::STATIC_PREFIX . "/$hash.$suffix";
    my $file = DBDefs::STATIC_FILES_DIR . "/$hash.$suffix";
    unless (-e$file) {
        &$minifier(input => join("\n", map { io($_)->all } @files)) > io($file);
    }

    return $path;
}

sub squash_scripts {
    my $self = shift;

    return $self->squash(\&Javascript::Closure::minify, "js", @_);
}

sub squash_styles {
    my $self = shift;

    return $self->squash(\&CSS::Minifier::minify, "css", @_);
}

__PACKAGE__->meta->make_immutable;
1;

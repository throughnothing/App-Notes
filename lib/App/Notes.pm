package App::Notes;
use v5.10;
use Capture::Tiny qw( capture );
use Exporter 'import';
use Git::Repository;
use List::MoreUtils qw( firstidx );
use Path::Class qw( file dir );

# ABSTRACT: Simple. Git-based. Notes.

our @EXPORT = qw(
    editor notes_dir notes_repo auto_sync track_file has_origin find_notes
    read_stdin check_stdin get_title get_filename is_yes edit_file
    pre_process_base post_process_base invalid_base init_base sync_base
);


sub editor { $ENV{EDITOR} || 'vim' }
sub notes_dir { dir( $ENV{APP_NOTES_DIR} ) || dir( $ENV{HOME}, '.notes' ) }
sub notes_repo { file( notes_dir, '.git' ) }
sub auto_sync {  $ENV{APP_NOTES_AUTOSYNC} // 1 }
sub track_file { file( notes_dir, '.track' ) }

sub init_base {
    my ( $c ) = @_;

    die "Notes dir already exists!" if -d notes_dir();

    my $dir = notes_dir();
    my $repo = $ARGV[0];
    my $output = capture {
        if( $repo ) {
            say "Initializing notes from $repo...";
            Git::Repository->run( clone => $repo, $dir->stringify );
        } else {
            say "Initializing notes ($dir)...";
            print Git::Repository->run( init => $dir->stringify );
        }
    }
}

sub pre_process_base {
    my ( $c ) = @_;
    my $cmd = $c->cmd;

    # If we aren't initializing, check to make sure our notes directory exists
    if( $cmd ne 'init' ) {
        if( -d notes_repo() ) {
            $c->stash->{git} = Git::Repository->new( git_dir => notes_repo() );
        } else {
            # We are not initialized
            die "Notes Directory has not been initialized!\n" .
                "Run init [remote git repo] to initialize.\n";
        }
    }

    return if not $c->is_command($cmd) or $cmd ~~ [qw( help init sync )];
    sync_base( $c, pull_only => 1 ) if auto_sync();
}

sub post_process_base {
    my ( $c ) = @_;
    my $cmd = $c->cmd;
    if($c->is_command($cmd) and not $cmd ~~ [qw( help init list show sync )]) {
        sync_base( $c, push_only => 1 ) if auto_sync();
    }
    say $c->output if $c->output;
}

sub invalid_base {
    my ( $c ) = @_;
    my $cmd = $c->cmd;
    ($cmd) = grep { /^$cmd/ } $c->commands;
    $cmd ? $c->execute( $cmd ) : $c->execute( 'help' );
    return; # This makes the command name not be printed from the last line
}

sub has_origin {
    grep { /^origin$/ } split ' ', $_[0]->stash->{git}->run( 'remote' )
}

sub find_notes {
    my ( $c, %args ) = @_;
    my $search = $args{search};
    my @notes = map file($_), sort {-M $a <=> -M $b} glob file(notes_dir, '*');

    # Filter results if requested
    if (defined $search) {
        @notes = grep { $_->basename =~ /$search/i } @notes;
        # If there is an exact match, make sure it is first
        my $idx = firstidx { $search eq $_->basename } @notes;
        unshift @notes, splice @notes, $idx, 1 if $idx > 0;
    }

    return \@notes;
}

sub read_stdin { local $/; <STDIN> }

sub check_stdin { ( -t STDIN ) ? 0 : read_stdin() }

sub get_title { join ' ', @ARGV; }

sub get_filename {
    return undef unless $_[0];
    ( my $r = $_[0] ) =~ s/ /-/g;
    return  $r;
}

sub is_yes { shift ~~ /^y(es)?$/i }

sub edit_file {
    my ( $c, $file, %args ) = @_;

    $args{check_stdin} //= 1; # Default to check stdin
    my $verb = ( -e $file->stringify ) ? "Updated " : "Created ";

    my $stdin = $args{check_stdin} ? check_stdin() : 0;
    if( $stdin ) {
        open FILE, ( $args{append} ? '>>' : '>' ), $file;
        print FILE $stdin;
        close FILE;
    } else {
        my $cmd = [ editor(), $file ];
        # Let them edit the file
        system join( ' ', @$cmd );
    }

    # Commit their changes if they wrote the file
    if ( -e $file ) {
        my $output = capture {
            $c->stash->{git}->run( add => $file->stringify );
            $c->stash->{git}->run( commit => '-m', $verb . $file->basename );
        };
    }
}

sub sync_base {
    my ( $c, %args ) = @_;
    return unless has_origin( $c );

    my $output = capture {
        $c->stash->{git}->run( 'pull' ) unless $args{push_only};
        $c->stash->{git}->run( 'push' ) unless $args{pull_only};
    };
    return;
}

1;

=pod

=head1 SYNOPSIS

Check out L<notes> and L<track> for more info.

=cut


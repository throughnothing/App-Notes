# NAME

notes - Simple. Git-based. Notes.

# VERSION

version 0.002

# SYNOPSIS

    Usage: notes command [arguments]

    Available Commands:
        add     add a new note, and edit it
        append  append to a note ( from STDIN )
        delete  delete the note
        edit    edit a note
        help    show syntax and available commands
        init    Initiliazie notes (optionally from remote repo)
        list    lists id and subject of all notes
        replace replace the contents of the note ( from STDIN )
        show    show the contents of the note
        sync    Sync notes with remote (pull + push)

    # To get started
    $ notes init
    # Or, optionally, get started with an existing git repo
    $ notes init git@gist.github.com:12343.git

    # Create a note and edit it (with $EDITOR, or vim by default)
    # Note name will be Hello-World
    $ notes add Hello World
    # Add another (markdown) note via STDIN
    $ echo "# Title" | notes add TEST.md

    # List notes
    $ notes list
    TEST.md
    Hello-World

    # List notes w/filter (case-insensitive)
    $ notes list te
    TEST.md

    # Edit a note (finds the most recently edited match, case insensitive)
    # This will open up the Hello-World note created above
    $ notes edit hel

    # Will replace the contents of Hello-World with "Hello, World"
    $ echo "Hello, World" | notes replace hel

    # Will append "END" to Hello-World
    $ echo "END" | notes append he

    # Sync notes with remote (if your git repo has a remote)
    $ notes sync

# DESCRIPTION

[App::Notes](http://search.cpan.org/perldoc?App::Notes) is a very simple command line tool that lets you creat, edit,
search, and manage simple text-based notes inside of a git repository.

This is very useful for keeping notes in a repository
(especially a `gist` on [GitHub](http://github.com)) that can be sync'ed
across machines, and also for keeping a history of all your notes.

Every time a note is created, modified or removed, [App::Notes](http://search.cpan.org/perldoc?App::Notes) will commit
the change to the git repo.  By default, It will `pull` before each command
executes, and `push` when its done (except on `list` and `show` commands).
To turn this behavior off, set `APP_NOTES_AUTO_SYNC=0`, and then you can
manually pull/push with `notes sync`.

# AUTHOR

William Wolf <throughnothing@gmail.com>

# COPYRIGHT AND LICENSE



William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.
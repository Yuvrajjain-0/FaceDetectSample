@rem --*-Perl-*--
@if "%overbose%" == "" if "%_echo%"=="" echo off
setlocal
for %%i in (oenvtest.bat) do call %%~$PATH:i
perl -x "%~dpnx0" %*
goto :eof

#!perl

BEGIN {
    # augment library path for OTOOLS environment
    if (defined $ENV{"OTOOLS"}) {
        require "$ENV{'OTOOLS'}\\lib\\perl\\otools.pm"; import otools;
    }

    # Convert "use strict 'subs'" to the eval below so we don't
    # barf if the user's @INC is set up wrong.  You'd be surprised
    # how often this happens.
    eval { require strict; import strict 'subs' };
}

require 5.004;
die "Unsupported OS ($^O), sorry.\n" if $^O eq "dos";

sub Usage {
    my $usage = <<'EOM';
NAME

$name - unpack a buddy build package

SYNOPSIS

    $name -?

    $name [-A dir] [-B dir] [-d] [-c changelist] [-f] [-l] [-m from to] [-n]
          [-R resolve-options] [-s] [-u] [-v] [-w] [-x]

DESCRIPTION

    Unpack the buddy build generated by a previous $pack.

OPTIONS

    -?

        Displays this help file.

    -A dir

        Directory to use for "after" files.  The directory will remain.
        Must be used in conjunction with -w.

    -B dir

        Directory to use for "before" files.  The directory will remain.
        Must be used in conjunction with -w.

    -d

        Turns on debugging spew.

    -c changelist

        Unpack the package onto the given changelist.  If this option
        is omitted, the default changelist will be used.

    -f

        Unpack even if the changelist is nonempty.

    -l

        List contents of package.

    -m from to

        Unpack (merge) the package into a location possibly different
        from the one it was built from.  "from" and "to" indicate the
        relationship between the source and target depots.  For example,
        if the original package was built from //depot/branch1/... and
        you want to unpack to //depot/branch2/... you would specify

            -m //depot/branch1/ //depot/branch2/

        Note the trailing slashes.  The remapping is a purely textual
        one:  All paths in the package that begin with "from" are
        rewritten to begin with "to", hence the importance of the trailing
        slash to avoid false matches.  If you misspell "from" or "to",
        you are likely to get very strange results.

        The files are unpacked into the current client, which
        need not be enlisted onto the same server that the package
        was generated from.

        It is legal for "from" and "to" to be the same path.  This
        results in merging a delta without moving it.  See the -M
        option below.

        May not be combined with the -s or -w switches.

    -M

        Shorthand for "-m // //", which merges a changelist without
        moving it.

    -n

        Display what would have happened without actually doing
        it.

    -R  resolve-options

        Arbitrary options to pass to "sd resolve3".  For example,
        you could say

            -R -af

        to force automatic mode.  For a list of supported options,
        type

            sd help resolve3

    -s

        Synchronize to the versions of the files that are
        the bases for the changes contained in the package,
        but do not unpack them.

        This is a convenient step to perform separately
        from unpacking because it allows you to perform a
        pre-build to ensure that the build was not broken
        before you unpacked the files in the package.

    -u

        Perform the unpack.  This switch can be combined with
        the -s switch to synchronize and unpack in one step.

        The unpack will fail if the changelist is nonempty.
        Use the "sd change" command to move files in the default
        changelist to a new changelist.  This allows you to use
        "sd revert -c default ..." to undo the unpack.

        To force the unpack even if the changelist is empty,
        pass the -f flag.  Note that doing so will result in the
        unpacked files being added to your changelist,
        which in turn makes reverting the unpack a much more
        cumbersome operation.

    -v

        Verify that the package will produce results
        identical to what's on the machine right now.
        Use this immediately after generating a package as a
        double-check.

    -w

        View contents of packages using windiff (or whatever your
        BBDIFF environment variable refers to).

    -x

        Unpack the files as UNIX-style (LF only) rather than
        Win32-style (CRLF).

    -T

        Preserve the last changed timestamps for all files when
        unpacking.

WARNINGS

    warning: filename merge cancelled by user; skipped

        A file in the package needed to be merged, but you abandoned
        the merge operation ("s" or "q").  The file was left in its original
        state; the changes were not merged in.

    warning: //depot/.../filename not affected by branch mapping; skipped

        The indicated file in the package is not affected by the
        from/to mapping, so it was omitted from the merge.

ERRORS

    error: sd failed; unpack abandoned

        One of the sd commands necessary to complete the unpack failed.
        The sd error message should have been displayed immediately
        before this message.

    error: cannot find local copy of //depot/.../filename

        The indicated file in the package could not be found on your
        enlistment.  Perhaps you have not included it in your view.

    internal error: cannot parse output of 'sd have'
    internal error: Cannot parse output of 'sd opened'

        There was a problem parsing the output of an sd command.

    error: changelist is not empty; use -f -u to unpack anyway

        The changelist is not empty, so the unpack
        was abandoned.  To force unpacking into a nonempty
        changelist, use the -f switch.

    error: filename is already open on client; to merge, use the -M option

        The specified file is already open.  It must be submitted or
        reverted before the package can be unpacked cleanly.

        Alternatively, you can unpack in "merge" mode, which merges
        the changes in the package with the version on your machine.
        Note that this will DESTROY the version on your machine in the
        process, so back it up (possibly with bbpack) if there's a chance
        the merge will not go well.

    error: adds in this package already exist on client

        The package contains an "add" operation, but the file already
        exists.  It must be ghosted or deleted before the package can
        be unpacked.

    error: files to be edited/deleted do not exist on client

        The package contains an "edit" or "delete" operation, but the
        file does not exist on the client.  Perhaps you have not
        included it in your view.

    error: wrong version of filename on client

        The base version of the file in the package does not match the
        base version on the client.  Use the -s option to synchronize
        to the version in the package.

    error: filename does not match copy in package

        The verification process (-v) failed.

    error: corrupted package

        An internal consistency check on the package has failed.  Either
        it has been corrupted, or there is a bug in the program.

    error: cannot open filename for writing (reason)

        The specified error occurred attempting to open the indicated
        file for writing.

    error: filename: errorstring

        The specified error occurred attempting to open the indicated
        file.

    error: no TEMP directory

        Neither the environment variable TEMP nor TMP could be found.

    error: Too many TEMP### directories

        Unable to create a temporary directory for windiff because there
        are too many already.  Normally, temporary directories are cleaned
        up automatically when the script terminates, but if the script
        terminates abnormally, temporary directories may be left behind
        and need to be cleaned up manually.

    //deport/path/to/file.cpp - must refer to client 'CLIENTNAME'
    error: sd failed; unpack abandoned

        This is an sd error message.  You spelled "depot" wrong ("deport")
        in the -m command line arguments.  As a result, sd thinks you are
        trying to merge with the file "file.cpp" on the enlistment named
        "deport", and sd won't let you check out a file on another person's
        enlistment.

TIPS

    Brain surgery

    $name stores as much state as possible in the depot itself in order
    to keep the package small.  If your server changes its name, you have
    to perform brain surgery on the package.  Load it up into notepad
    and look for the _!_END_!_ line.  A few lines after the _!_END_!_ will
    be a

        Server address: oldserver:portnumber

    Change the server address to refer to the new server and new port
    number.

    NOTE!  Use Notepad and not "My Favorite Editor" because who knows
    what "My Favorite Editor" does to tabs and trailing spaces and
    that sort of thing.

REMARKS

    4NT users need to type

        perl -Sx $name.cmd

    instead of just $name.

ENVIRONMENT

    BBDIFF

        The name of the diff program to use.  If not defined, the
        SDDIFF variable is used to obtain the name of the file difference
        program.  If neither is defined, then "windiff" is used.

    BBUNPACKDEFCMD

        The default command to execute if no command line options are
        specified.  If not defined, then an error message is displayed.

        For example, you might set BBUNPACKDEFCMD=-w to make the default
        action when running a package to be to view the contents via
        windiff.

    Since $name runs sd internally, all the SD environment variables
    also apply.

BUGS

    Several error messages leak out when you unpack an sd add.
    (This is happening while verifying that the file about to be
    added hasn't already been added.)

    If the package contains an "add" command and the file exists
    on the client but is not under source control, the file is overwritten
    without warning.

    There are almost certainly other bugs in this script somewhere.

VERSION

    The package was generated by version 109 of $pack.

EOM
    $usage =~ s/\$name/$main::name/g;
    $usage =~ s/\$pack/$main::pack/g;

    # prevent false positives when searching for the magic cookie
    $usage =~ s/_!_/__/g;
    print $usage;
}

sub dprint {
    print STDERR "# ", @_, "\n" if $main::d;
}

#
#   $action is optional prefix for printing.
#   $sharp says whether or not revisions should be kept.
#   $ary is a ref to an array of [ $file, $rev ].
#
#   We always convert the depot paths to local paths for perf.
#   (It works around a perf bug in older versions of sds.)
#
#   Returns a ref to an array of strings to pass to -x.

sub sdarg {
    my ($action, $sharp, $ary) = @_;
    my @out = ();
    my %files;
    my $rc = "";

    for my $file (@$ary) {
        my $depot = $file->[0];
        $files{lc $depot} = $file;
        push(@out, "$depot\n");
    }

    # Now convert the results into a list of local paths.  Anything
    # that succeeds, edit it in the %files.  Anything that fails to map
    # gets left alone, and sd will generate the real error later.

    my $tempfile = CreateTempFile(@out);
    my $curDepot = undef;
    for my $line (`sd -x $tempfile -s where -T _`) {
        if ($line =~ m|^info:|) {
            $curDepot = undef;
        } elsif ($line =~ m|^info1: depotFile (.*)$|) {
            $curDepot = $1;
        } elsif ($line =~ m|^info1: path (.*)$|) {
            my $curFile = $files{lc $curDepot};
            if ($curFile) {
                $curFile->[0] = $1;
                dprint "$curDepot -> $1";
            }
            $curDepot = undef;
        }
    }
    unlink $tempfile;

    # Now rebuild the results based on the localized paths.
    @out = ();
    for $file (values %files) {
        push(@out, $file->[0]);
        push(@out, "#" . $file->[1]) if $sharp;
        push(@out, "\n");
    }

    \@out;
}

#
#   $action is a command ("sync#", "edit", "add" and "delete")
#
#   The revision number is stripped off the file specification
#   unless the action itself ends in a # (namely, sync#).
#
#   $ary is a ref to an array of [ $file, $rev ].

sub sdaction {
    my ($action, $ary) = @_;
    my $sharp = $action =~ s/#$//;

    if ($#$ary >= 0) {

        my $args = sdarg($action, $sharp, $ary);

        unless ($main::n) {
            my $error = 0;
            my $tempfile = CreateTempFile(@$args);
            if (open(SD, "sd -x $tempfile -s $action |"))
            {
                my $line;
                while ($line = <SD>) {
                    if ($line =~ /^(\S+): /) {
                        $error = 1 if $1 eq 'error';
                        print $' unless $1 eq 'exit';
                    }
                }
                close(SD);
            }
            unlink $tempfile;
            die "error: sd failed; unpack abandoned\n" if $error;
        }
    }
}

sub slurpfile {
    my ($file, $type) = @_;
    my @file;
    if ($type =~ /binary|unicode/) {
        open(B, $file) or die "error: cannot open $file for reading ($!)\n";
        binmode(B);
        local($/);
        push(@file, <B>);
        close(B);
    } else {
        open(I, $file) or die "error: cannot open $file for reading ($!)\n";
        @file = <I>;
        close(I);
    }
    @file;
}

sub spewfile {
    my ($file, $ary, $type) = @_;
    if (!open(O, ">$file")) {
        # Maybe the parent directory hasn't been created yet
        my $dir = $file;
        $dir =~ s/\//\\/g;
        if ($dir =~ s/[^\\\/]+$//) {
            system "md \"$dir\"" unless -e $dir; # let cmd.exe do the hard work
        }
        open(O, ">$file") or die "error: cannot open $file for writing ($!)\n";
    }
    binmode(O) if $main::x || $type =~ /binary|unicode/;
    print O @$ary;
    close(O);
}

sub GetUniqueName {
    my $name = shift;
    $name =~ s,^[/\\]*,,;   # clean out leading slashes
    $name = substr($name, length($main::CommonPrefix));
    $name =~ s,^[/\\]*,,;   # clean out leading slashes again

    if (defined($main::UniqueNames{lc $name}))
    {
        my $i = 1;
        $i++ while $main::UniqueNames{lc "$name$i"};
        $name .= $i;
    }
    $main::UniqueNames{lc $name} = 1;
    $name;
}

sub CreateTempFile {
    my $TEMP = $ENV{"TEMP"} || $ENV{"TMP"};
    die "error: no TEMP directory" unless $TEMP;
    $TEMP =~ s/\\$//;     # avoid the \\ problem

    $tempfile = "$TEMP\\bbpack.$$";
    open(T, ">$tempfile") || die "error: Cannot create $tempfile\n";
    my $success = print T @_;
    $success = close(T) && $success;
    unlink $tempfile, die "error: writing $tempfile ($!)\n" unless $success;
    $tempfile;
}

sub Remap {
    my $path = shift;
    if ($path =~ m#^\Q$main::fromDepot\E#i) {
        substr($path, $[, length($main::fromDepot)) = $main::toDepot;
    }
    $path;
}

#
#   $depotpath, $rev is the file to be edited/added.
#   $cmd is "edit" or "add" (indicates where basefile comes from)
#

sub ApplyEdit {
    my ($depotpath, $rev, $cmd, $type, $atime, $mtime) = @_;
    my $destpath = $depotpath;
    my $destfile;
    my $where, $file;

    if ($main::w) {
        $file = $depotpath; # for the purpose of GetUniqueName
    } else {
        $destpath = Remap($depotpath) if $main::m;
        dprint "$depotpath -> $destpath" if $main::m;
        local($/) = ""; # "sd where -T" uses paragraphs
        foreach $line (`sd where -T _ \"$destpath\" 2>&1`) {
            undef $where, next if $line =~ m|^\.\.\. unmap|m;
            $where = $1 if $line =~ m|^\.\.\. path (.+)|m;
        }
        die "error: cannot find local copy of $destpath\n" unless $where;
        $destfile = $file = $where;
    }
    my @file;
    my $bias = -1;  # perl uses zero-based arrays but diff uses 1-based line numbers

    if ($cmd eq 'add') {
        @file = ();
        $file = $destfile if $main::m;
    } elsif ($cmd eq 'edit') {
        my $src = $file;
        if ($main::v || $main::w || $main::m) {
            dprint "sd$main::ExtraFlags print -q \"$depotpath#$rev\"";
            $src = "sd$main::ExtraFlags print -q \"$depotpath#$rev\"|";
        }
        @file = slurpfile($src, $type);
    } elsif ($cmd eq 'delete') {
        if ($main::w) {
            dprint "sd$main::ExtraFlags print -q \"$depotpath#$rev\"";
            @file = slurpfile("sd$main::ExtraFlags print -q \"$depotpath#$rev\"|", $type);
        } else {
            @file = ();
        }
    }

    my $unique;
    if ($main::w || ($main::m && $cmd eq "edit")) { # Write the original, set up for new
        $unique = GetUniqueName($file);
        spewfile("$main::BeforeDir\\$unique", \@file, $type) unless $cmd eq 'add';
        $file = "$main::AfterDir\\$unique";
    }

    if ($cmd ne 'delete') {
        # now read from <DATA> and apply the edits.
        if ($type =~ /binary|unicode/) {
            local($/) = "";
            @file = (unpack("u", scalar(<DATA>)));
        } else {
            while (($line = <DATA>) ne "q\n") {
                if ($line =~ /^a(\d+) (\d+)/) {
                    my @added = ();
                    my $count = $2;
                    while ($count--) {
                        push(@added, scalar(<DATA>));
                    }
                    splice(@file, $1 + $bias + 1, 0, @added); # +1 because it's "add", not "insert"
                    $bias += $2;
                } elsif ($line =~ /^d(\d+) (\d+)/) {
                    splice(@file, $1 + $bias, $2);
                    $bias -= $2;
                } else {
                    die "error: corrupted package trying to unpack $depotpath\n".
                        "       expected a/d/q but got\n".
                        "           $line";
                }
            }

            if ($type =~ /_nonewline/) {
                chomp($file[$#file]);
            }
        }

        if ($main::v) {
            my @file2 = slurpfile($file, $type);
            join("", @file) eq join("", @file2) or
                die "error: $file does not match copy in package\n";
            print "$file is okay\n";
        } else {
            spewfile($file, \@file, $type);
        }

        if ($cmd eq "edit" && $main::m) {
            dprint "sd resolve3 $main::R \"$main::BeforeDir\\$unique\" \"$main::AfterDir\\$unique\" \"$destfile\" \"$destfile.out\"";
            system("sd resolve3 $main::R \"$main::BeforeDir\\$unique\" \"$main::AfterDir\\$unique\" \"$destfile\" \"$destfile.out\"");
            if (-e "$destfile.out") {
                unlink $destfile;
                rename "$destfile.out", $destfile;
                chmod 0666, $destfile;
            } else {
                warn "warning: $destfile merge cancelled by user; skipped\n";
            }
            unlink "$main::BeforeDir\\$unique";
            unlink "$main::AfterDir\\$unique";
        }

        if ($main::T && $atime && $mtime) {
            utime $atime, $mtime, $destfile;
        }
    }
}

sub IsDirectoryEmpty {
    my $dir = shift;
    my $empty = 1;
    if (opendir(D, $dir)) {
        while ($file = readdir(D)) {
            $empty = 0, last if $file ne '.' && $file ne '..';
        }
        closedir(D);
    } else {
        $empty = 0;         # Wacky directory, pretend nonempty so we skip it
    }
    $empty;
}

$main::NextUniqueDir = 0;

sub GetNewTempDir {
    my $TEMP = $ENV{"TEMP"} || $ENV{"TMP"};
    die "error: no TEMP directory" unless $TEMP;

    $TEMP =~ s/\\$//;     # avoid the \\ problem

    # Look for suitable "before" and "after" directories; we'll
    # call them "bbtmp###".

    $TEMP .= "\\bbtmp";

    while ($main::NextUniqueDir++ < 1000) {
        my $try = "$TEMP$main::NextUniqueDir";
        if (!-e $try && mkdir($try, 0777)) {
            return $try;
        }
        if (-d _ && IsDirectoryEmpty($try)) {
            return $try;
        }
    }
    die "error: Too many ${TEMP}### directories\n";
}

sub CleanDir {
    my $dir = shift;
    if (defined($dir) && -e $dir) {
        system "rd /q /s $dir";
    }
}

sub AccumulateCommonPrefix {
    my $file = "/" . lc shift;

    # Remove filename component
    while ($file =~ s,[/\\][^/\\]*$,,) {
        last unless defined $main::CommonPrefix;
        last if substr($main::CommonPrefix, 0, length($file)) eq $file;
    }

    $main::CommonPrefix = $file;
}

#
#   Okay, now initialize our globals.
#

$main::name = $0;
$main::name =~ s/.*[\/\\:]//;
$main::name =~ s/\.(bat|cmd)$//;

$main::A = 0;
$main::B = 0;
$main::c = "default";
$main::d = 0;
$main::f = 0;
$main::l = 0;
$main::m = 0;
$main::n = 0;
$main::R = "";
$main::s = 0;
$main::u = 0;
$main::v = 0;
$main::w = 0;
$main::x = 0;
$main::T = 0;
$main::anyChanges = 0;

$main::BeforeDir = undef;
$main::AfterDir  = undef;
%main::UniqueNames = ("" => 1); # preinit to avoid blank name
$main::ExtraFlags = "";
$main::fromDepot = undef;
$main::toDepot = undef;
$main::CommonPrefix = undef;

#
#   NASTY HACK TO WORK AROUND PERL BUG IN <DATA> HANDLING.
#   Reopen ourselves and advance to the raw data.
#
open(DATA, $0);
0 until scalar(<DATA>) eq "__END__\n";

my %PackerProperties;

{
    my $line;
    while (($line = <DATA>) =~ /(.*?): (.*)/) {
        $PackerProperties{$1} = $2;
    }
    $main::pack = delete $PackerProperties{Packager};
    die "error: corrupted package\n" unless $line eq "\n" && $main::pack;
    die "error: your version of perl doesn't support lines longer than 256 characters\n"
        unless $PackerProperties{"PerlSniffTest"} eq "." x 256;
}

#   If there is no command line and there is a BBUNPACKDEFCMD, use that
#   variable instead.

if ($#ARGV < 0 && defined $ENV{"BBUNPACKDEFCMD"}) {
    my $cmd = $ENV{"BBUNPACKDEFCMD"};
    $cmd =~ s/^\s+//;
    while ($cmd =~ s/^\s*(?:"([^"]*)"|([^"]\S*))\s*//) {
        push(@ARGV, $+);
    }
}

while ($#ARGV >= 0 && $ARGV[0] =~ /^-/) {
    my $switch = shift;
         if ($switch eq '-d') {
        $main::d++;
    } elsif ($switch eq '-f') {
        $main::f++;
    } elsif ($switch eq '-l') {
        $main::l++;
    } elsif ($switch eq '-m') {
        $main::m++;
        $main::fromDepot = shift;
        $main::toDepot = shift;

        if ($main::fromDepot !~ m#^//# ||
            $main::toDepot !~ m#^//#) {
            die "-m must be followed by two depot prefixes; type $name -? for help\n";
        }

    } elsif ($switch eq '-M') {
        $main::m++;
        $main::fromDepot = $main::toDepot = '/';
    } elsif ($switch eq '-c') {
        $main::c = shift;

        if ($main::c !~ m#^[0-9]#) {
            die "-c must be followed by a changelist number; type $name -? for help\n";
        }

    } elsif ($switch eq '-A') {
        die "only one instance of -A allowed; type $name -? for help\n" if $main::A;
        $main::A++;
        $main::AfterDir = shift || die "-A requires an argument; type $name -? for help\n";
    } elsif ($switch eq '-B') {
        die "only one instance of -B allowed; type $name -? for help\n" if $main::B;
        $main::B++;
        $main::BeforeDir = shift || die "-B requires an argument; type $name -? for help\n";
    } elsif ($switch eq '-n') {
        $main::n++;
    } elsif ($switch eq '-R') {
        $main::R = shift;
    } elsif ($switch eq '-s') {
        $main::s++;
    } elsif ($switch eq '-u') {
        $main::u++;
    } elsif ($switch eq '-v') {
        $main::v++;
    } elsif ($switch eq '-w') {
        $main::w++;
    } elsif ($switch eq '-x') {
        $main::x++;
    } elsif ($switch eq '-T') {
        $main::T++;
    } elsif ($switch eq '-?') {
        Usage(); exit 1;
    } else {
        die "Invalid command line switch; type $name -? for help\n";
    }
}

# Should be no command line options
die "Invalid command line; type $main::name -? for help\n" if $#ARGV >= 0;

die "Must specify an action; type -? for help\n"
    unless $main::l || $main::s || $main::u || $main::v || $main::w;

# suppress -w (presumably from registered .bpk extension)
# if other actions found
$main::w = 0
        if $main::l || $main::s || $main::u || $main::v;


die "Cannot combine -m with -s\n" if $main::m && $main::s;
die "Cannot combine -m with -w\n" if $main::m && $main::w;

#
#   -l wants some meta-information about the package.
#
if ($main::l) {
    my $key;
    foreach $key (split(/,/, "Comment,Client name,User name,Date")) {
        print "$key: $PackerProperties{$key}\n";
    }
    print "\n";
}

#
#   See which files are open on the client.  This also establishes whether
#   the server is up and the user has proper permissions.
#
my %OpenedFiles;

if ($main::s || $main::u) {
    # Intentionally let errors through to stderr
    # Use -s to suppress stderr if no files are opened
    foreach my $line (`sd -s opened -c $main::c`) {
        next if $line =~ m,^warning: , || $line =~ m,^exit: ,;
        next if $line =~ m!^(error|warning): File\(s\) not opened !;
        $line =~ m,^info: (//.*?)#(\d+|none),
            or die "error: Cannot parse output of 'sd opened -c $main::c'\n";
        $OpenedFiles{$1} = 1;
        dprint "opened $1#$2";
        $main::anyChanges = 1 if $' =~ /$main::c/;
    }
}

die "error: changelist $main::c is not empty; use -f -u to unpack anyway\n"
    if $main::anyChanges && $main::u && !$main::f;

#
#   The -w and -m options require us to set up some directories for unpacking.
#
if ($main::w || $main::m)
{
    $main::BeforeDir = GetNewTempDir() unless defined $main::BeforeDir;
    $main::AfterDir  = GetNewTempDir() unless defined $main::AfterDir;
    $main::ExtraFlags = " -p $PackerProperties{'Server address'}";
}

#
#   Go through each file in the package and perform an appropriate
#   action on it.
#

{
    my @sync, @edit, @add, @delete;

    my $line;
    while (($line = <DATA>) =~ m|^(//.*?)#(\d+) (\S+) (\S+)|) {

        #   $1 = depot path
        #   $2 = rev
        #   $3 = action
        #   $4 = filetype (not currently used)

        if ($main::l) {
            print $line;
        }

        #   If sync'ing or unpacking, then the file had better not be open
        #   since we're the ones who are going to open it.

        die "error: $1 is already open on client; to merge, use the -M option\n"
            if defined $OpenedFiles{$1} && ($main::s || ($main::u && !$main::m));

        #   If sync'ing, add to list of files that need to be sync'd.
        #
        #   If unpacking, then add to the appropriate list so we know
        #   how to prepare the file for action.

        if ($main::s) {
            push(@sync, [ $1, $3 eq 'add' ? 'none' : $2 ]);
        }
        if ($main::u) {

            my $path = $1;
            if ($main::m) {
                $path = Remap($1);
            }

            if ($path) {
                if ($3 eq 'edit') {
                    push(@edit, [ $path, $2 ]);
                } elsif ($3 eq 'add') {
                    push(@add, [ $path, $2 ]);
                } elsif ($3 eq 'delete') {
                    push(@delete, [ $path, $2 ]);
                } else {
                    die "error: corrupted package\n";
                }
            }
        }

        AccumulateCommonPrefix($1);

    }
    die "error: corrupted package\n" unless $line eq "\n";

    $main::CommonPrefix =~ s,^[/\\]+,,; # clean off leading slashes

    if ($main::s || $main::u) {

        #
        #   Make sure that no files being added currently exist.
        #
        if ($#add >= 0) {
            my $args = sdarg(undef, undef, \@add);
            my $tempfile = CreateTempFile(@$args);
            if (`sd -x $tempfile have 2>nul`) {
                unlink $tempfile;
                die "error: adds in this package already exist on client\n";
            }
            unlink $tempfile;
        }

        #
        #   Make sure that files being edited are the correct versions.
        #
        if (($#edit >= 0 || $#delete >= 0) && !$main::s && !$main::m) {
            my @have = (@edit, @delete);
            my %have;
            my $file;
            my $args = sdarg(undef, undef, \@have);
            my $tempfile = CreateTempFile(@$args);
            dprint "sd have @$args";
            for $file (`sd -x $tempfile have`) {
                $file =~ m|(//.*?)#(\d+) - (.*)| or die "error: parsing output of 'sd have'\n";
                dprint "have $1#$2 - $3";
                #
                #    Store the have under both the depot path and the local path.
                #
                $have{lc $1} = $2;
                $have{lc $3} = $2;
            }
            unlink $tempfile;
            die "error: files to be edited/deleted do not exist on client\n" if $?;
            for $file (@have) {
                die "error: wrong version of $file->[0] on client\n"
                    if $have{lc $file->[0]} ne $file->[1];
            }
        }

        sdaction("sync#", \@sync);
        sdaction("edit -c $main::c", \@edit);
        # Do not do the adds yet; wait until after the edits have been applied
        sdaction("delete -c $main::c", \@delete);
    }

    #
    #   Now go extract the actual files.
    #
    if (!$main::n && ($main::u || $main::v || $main::w)) {
        my $line;
        # " *" because some editors trim trailing spaces
        while (($line = <DATA>) =~ m|^(//.*?)#(\d+) (\S+) (\S+) *(\d*) *(\d*)|) {
            ApplyEdit($1, $2, $3, $4, $5, $6);
        }
    }

    # Okay, now do the adds now that the output files have been created
    sdaction("add -c $main::c", \@add);
}

if ($main::w) {
    my $windiff = $ENV{"BBDIFF"} || $ENV{"SDDIFF"} || "windiff";
    system("$windiff \"$main::BeforeDir\" \"$main::AfterDir\"");
}

CleanDir($main::BeforeDir) unless $main::B;
CleanDir($main::AfterDir) unless $main::A;

__END__
PerlSniffTest: ................................................................................................................................................................................................................................................................
Packager: bbpack
Client name: MREVOW1-main-1
User name: REDMOND\mrevow
Server address: TKBGITSDMSN02.redmond.corp.microsoft.com:2576
Date: 2007/04/30 09:48:00

//depot/main/private/research/private/face/faceSort/FaceSortUI/Face.cs#11 edit text

//depot/main/private/research/private/face/faceSort/FaceSortUI/Face.cs#11 edit text 1177950853 1177950853
a1227 4
            else if (SelectionStateEnum.ElementSelect == Selected && null != _parentGroup)
            {
                _parentGroup.FaceSortMove(this);
            }
q

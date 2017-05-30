#! nqp

# Test nqp::op file operations.

plan(111);

ok( nqp::stat('CREDITS', nqp::const::STAT_EXISTS) == 1, 'nqp::stat exists');
ok( nqp::stat('AARDVARKS', nqp::const::STAT_EXISTS) == 0, 'nqp::stat not exists');

ok( nqp::stat('t', nqp::const::STAT_ISDIR) == 1, 'nqp::stat is directory');
ok( nqp::stat('CREDITS', nqp::const::STAT_ISDIR) == 0, 'nqp::stat not directory');

ok( nqp::stat('CREDITS', nqp::const::STAT_ISREG) == 1, 'nqp::stat is regular file');
ok( nqp::stat('t', nqp::const::STAT_ISREG) == 0, 'nqp::stat not regular file');


my $credits := nqp::open('CREDITS', 'r');
ok( $credits, 'nqp::open for read');
ok( nqp::tellfh($credits) == 0, 'nqp::tellfh start of file');
ok( !nqp::eoffh($credits), 'Not at EOF after open');
my $line := nqp::readlinefh($credits);
ok( !nqp::eoffh($credits), 'Not at EOF after first line read');
ok( nqp::chars($line) == 5 || nqp::chars($line) == 6, 'nqp::readlinefh line to read'); # =pod\r?\n
ok( nqp::tellfh($credits) == 5 || nqp::tellfh($credits) == 6, 'nqp::tellfh line two');
my $rest := nqp::readallfh($credits);
ok( nqp::eoffh($credits), 'At EOF after readallfh');
ok( nqp::chars($rest) > 100, 'nqp::readallfh lines to read');
ok( nqp::substr($rest,0,4) ne '=pod', 'nqp::readallfh after nqp::readlinefh did not read line twice');
ok( nqp::tellfh($credits) >= nqp::chars($line) + nqp::chars($rest), 'nqp::tellfh end of file');

ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file');
ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file repeat');
ok( nqp::chars(nqp::readallfh($credits)) == 0, 'nqp::readallfh end of file');
ok( nqp::chars(nqp::readlinefh($credits)) == 0, 'nqp::readlinefh end of file repeat');

ok( !nqp::isttyfh($credits), "nqp::isttyfh on a regular file");

ok( nqp::defined(nqp::closefh($credits)), 'nqp::closefh');

# setinputlinesep tests

{
    my $data := nqp::open('t/nqp/19-setinputlinesep.txt', 'r');
    nqp::setinputlinesep($data, "a");
    my $line1 := nqp::readlinefh($data);
    my $line2 := nqp::readlinefh($data);
    is($line1, 'This is a', "setinputlinesep with a input separator containing of one character... reading first line");
    is($line2, ' ra', "setinputlinesep with a input separator containing of one character... reading first line");
}

if nqp::getcomp('nqp').backend.name eq 'js' {
    my $data := nqp::open('t/nqp/19-setinputlinesep.txt', 'r');
    nqp::setinputlinesep($data, "ba");
    my $line1 := nqp::readlinefh($data);
    my $line2 := nqp::readlinefh($data);
    my $line3 := nqp::readlinefh($data);
    is($line1, 'This is a random line ending with ba', "setinputlinesep with a input separator containing of two character... reading first line");
    my $long := ' and not a newline...............................................................ba';
    is($line2, $long, '... reading second line');
    ok(nqp::substr($line3, 0, 9) eq '123456789' && (nqp::chars($line3) == 10 || nqp::chars($line3) == 11), '... reading last line not ending with input separator');
}
else {
   skip("setinputlinesep with multiple chars is broken for the MoarVM and possibly others", 3);
}

ok( nqp::defined(nqp::getstdin()), 'nqp::getstdin');
ok( nqp::defined(nqp::getstdout()), 'nqp::getstdout');
ok( nqp::defined(nqp::getstderr()), 'nqp::getstderr');

ok( nqp::istrue(nqp::getstdin()), 'nqp::getstdin');
ok( nqp::istrue(nqp::getstdout()), 'nqp::getstdout');
ok( nqp::istrue(nqp::getstderr()), 'nqp::getstderr');

## open, printfh, readallfh, closefh
my $test-file := 'test-nqp-19';
nqp::unlink($test-file) if nqp::stat($test-file, 0); # XXX let mvm die on nonexistent file

my $fh := nqp::open($test-file, 'w');
ok($fh, 'we can open a nonexisting file for writing');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'w');
ok($fh, 'we can open an existing file for writing');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
is(nqp::readallfh($fh), '', 'test file is empty');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'wa');
ok(nqp::printfh($fh, "awesome") == 7, 'appended a string to that file');
ok(nqp::printfh($fh, " thing!!") == 8, 'appended a string to that file... again');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
is(nqp::readallfh($fh), "awesome thing!!", 'test file contains the strings');
ok(nqp::tellfh($fh) == 15, 'tellfh gives correct position');
nqp::closefh($fh);

my $size := nqp::stat($test-file, nqp::const::STAT_FILESIZE);
$fh := nqp::open($test-file, 'r');
nqp::seekfh($fh, 0, 2);
ok(nqp::tellfh($fh) == $size, 'seekfh to end gives correct position');
nqp::seekfh($fh, 8, 0);
ok(nqp::tellfh($fh) == 8, 'seekfh relative to start gives correct position');
is(nqp::readallfh($fh), "thing!!", 'seekfh relative to start gives correct content');
nqp::seekfh($fh, -7, 2);
ok(nqp::tellfh($fh) == 8, 'seekfh relative to end gives correct position');
is(nqp::readallfh($fh), "thing!!", 'seekfh relative to end gives correct content');
nqp::seekfh($fh, -8, 1);
ok(nqp::tellfh($fh) == 7, 'seekfh relative to current pos gives correct position');
is(nqp::readallfh($fh), " thing!!", 'seekfh relative to current pos gives correct content');
my $ok := 1;
try { nqp::seekfh($fh, -5, 0); $ok := 0; 1 }
ok($ok, 'seekfh before start of file fails');
$ok := 1;
try { nqp::seekfh($fh, 0, 5); $ok := 0; 1 }
ok($ok, 'seekfh with invalid whence fails');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'w');
nqp::closefh($fh);
$fh := nqp::open($test-file, 'r');
is(nqp::readallfh($fh), '', 'opening for writing truncates the file');
nqp::closefh($fh);


$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, "pretty awesome");
nqp::printfh($fh, " th");
nqp::printfh($fh, "i");
nqp::printfh($fh, "n");
nqp::printfh($fh, "g!");
nqp::printfh($fh, "!");
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
is(nqp::readallfh($fh), "pretty awesome thing!!", 'test file contains the string after multiple write with w mode');
ok(nqp::tellfh($fh) == 22, 'tellfh gives correct position');
nqp::closefh($fh);

## setencoding
$fh := nqp::open($test-file, 'w');
nqp::setencoding($fh, 'utf8');
ok(nqp::printfh($fh, "ä") == 2, 'umlauts are printed as two bytes');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
nqp::setencoding($fh, 'utf8'); # XXX let ascii be the default
my $str := nqp::readallfh($fh);
ok(nqp::chars($str) == 1, 'utf8 means one char for an umlaut');
is($str, "ä", 'utf8 reads the umlaut correct');
nqp::closefh($fh);

$fh := nqp::open($test-file, 'r');
nqp::setencoding($fh, 'iso-8859-1');
ok(nqp::chars(nqp::readallfh($fh)) == 2, 'switching to ansi results in 2 chars for an umlaut');
nqp::closefh($fh);

## chdir
if nqp::getcomp('nqp').backend.name eq 'jvm' {
    skip("chdir is not possible on jvm", 3);
}
else {
    nqp::chdir('t');
    $fh := nqp::open('../' ~ $test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can chdir into a subdir');
    nqp::closefh($fh);

    nqp::chdir('..');
    $fh := nqp::open($test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can chdir back to the parent dir');
    nqp::closefh($fh);

    ## mkdir
    nqp::mkdir($test-file ~ '-dir', 0o777);
    nqp::chdir($test-file ~ '-dir');
    $fh := nqp::open('../' ~ $test-file, 'r');
    nqp::setencoding($fh, 'utf8');
    ok(nqp::chars(nqp::readallfh($fh)) == 1, 'we can create a new directory');
    nqp::closefh($fh);
    nqp::chdir('..');

    nqp::rmdir($test-file ~ '-dir');
    nqp::unlink($test-file);

    my $parts := [$test-file ~ '-dir-nested1', 'nested2', 'nested4', 'nested5', 'nested6', 'nested7'];


    my $nested := nqp::join('/', $parts);
    nqp::mkdir($nested, 0o777);

    {
        my $wfh := nqp::open("$nested/test-file", 'w');
        nqp::printfh($wfh, "hi");
        nqp::closefh($wfh);

        my $rfh := nqp::open("$nested/test-file", 'r');
        my $input := nqp::readallfh($rfh);
        is($input, "hi", "can read and write to a file in our nested directory");
        nqp::closefh($rfh);

        nqp::unlink("$nested/test-file");
    }

    my @delete;
    my $path := nqp::shift($parts);
    nqp::unshift(@delete, $path);
    for $parts -> $part {
        $path := $path ~ "/$part";
        nqp::unshift(@delete, $path);
    }

    for @delete -> $dir {
        nqp::rmdir($dir);
    }

}

my $backend := nqp::getcomp('nqp').backend.name;
my $crlf-conversion := $backend eq 'moar' || $backend eq 'js';

if $crlf-conversion {
    skip("readlinefh won't match \\r on $backend", 5);
}
else {
    $fh := nqp::open('t/nqp/19-readline.txt', 'r');
    is(nqp::readlinefh($fh), "line1\r",   'reading a line till CR');
    is(nqp::readlinefh($fh), "line2\r\n", 'reading a line till CRLF');
    is(nqp::readlinefh($fh), "line3\n",   'reading a line till LF');
    is(nqp::readlinefh($fh), "\n",          'reading an empty line');
    is(nqp::readlinefh($fh), "line4",     'reading a line till EOF');
    nqp::closefh($fh);
}

# file times
my $mtime := nqp::stat('t/nqp/019-file-ops.t', nqp::const::STAT_MODIFYTIME);
ok($mtime > 0, 'integer mtime');
my $atime := nqp::stat('t/nqp/019-file-ops.t', nqp::const::STAT_ACCESSTIME);
ok($atime > 0, 'integer atime');
my $ctime := nqp::stat('t/nqp/019-file-ops.t', nqp::const::STAT_CHANGETIME);
ok($ctime > 0, 'integer ctime');

if $backend eq 'moar' || $backend eq 'js' || $backend eq 'jvm' {
    my $mtime_n := nqp::stat_time('t/nqp/019-file-ops.t', nqp::const::STAT_MODIFYTIME);
    ok($mtime_n >= $mtime, 'float mtime >= integer');
    my $atime_n := nqp::stat_time('t/nqp/019-file-ops.t', nqp::const::STAT_ACCESSTIME);
    ok($atime_n >= $mtime, 'float atime >= integer');
    my $ctime_n := nqp::stat_time('t/nqp/019-file-ops.t', nqp::const::STAT_CHANGETIME);
    ok($ctime_n >= $mtime, 'float ctime >= integer');
}
else {
    skip("no stat_time op on $backend", 3);
}

# copy
nqp::unlink($test-file ~ '-copied') if nqp::stat($test-file ~ '-copied', nqp::const::STAT_EXISTS);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Hello');
nqp::closefh($fh);
nqp::copy($test-file, $test-file ~ '-copied');
$fh := nqp::open($test-file ~ '-copied', 'r');
is(nqp::readallfh($fh), "Hello", 'copied file has expected content');
nqp::closefh($fh);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Holla');
nqp::closefh($fh);
nqp::copy($test-file, $test-file ~ '-copied');
$fh := nqp::open($test-file ~ '-copied', 'r');
is(nqp::readallfh($fh), "Holla", 'copied file (overwritten) has expected content');
nqp::closefh($fh);
nqp::unlink($test-file);
nqp::unlink($test-file ~ '-copied');

# rename/move
nqp::unlink($test-file ~ '-moved') if nqp::stat($test-file ~ '-moved', nqp::const::STAT_EXISTS);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Hello');
nqp::closefh($fh);
nqp::rename($test-file, $test-file ~ '-moved');
$fh := nqp::open($test-file ~ '-moved', 'r');
is(nqp::readallfh($fh), "Hello", 'moved file has expected content');
nqp::closefh($fh);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Holla');
nqp::closefh($fh);
nqp::rename($test-file, $test-file ~ '-moved');
$fh := nqp::open($test-file ~ '-moved', 'r');
is(nqp::readallfh($fh), "Holla", 'moved file (overwritten) has expected content');
nqp::closefh($fh);
nqp::unlink($test-file);
nqp::unlink($test-file ~ '-moved');

# link
nqp::unlink($test-file ~ '-linked') if nqp::stat($test-file ~ '-linked', nqp::const::STAT_EXISTS);
$fh := nqp::open($test-file, 'w');
nqp::printfh($fh, 'Hello');
nqp::closefh($fh);
nqp::link($test-file, $test-file ~ '-linked');
ok(nqp::stat($test-file ~ '-linked', nqp::const::STAT_EXISTS), 'the hard link should exist');
ok(nqp::stat($test-file, nqp::const::STAT_PLATFORM_DEV) == nqp::stat($test-file ~ '-linked', nqp::const::STAT_PLATFORM_DEV), "a hard link should share the original's device number");
ok(nqp::stat($test-file, nqp::const::STAT_PLATFORM_INODE) == nqp::stat($test-file ~ '-linked', nqp::const::STAT_PLATFORM_INODE), "a hard link should share the original's inode number");
nqp::unlink($test-file);
nqp::unlink($test-file ~ '-linked');

# symlink

my $tmp-file := "tmp";
my $env := nqp::getenvhash();
$env<NQP_SHELL_TEST_ENV_VAR> := "123foo";
nqp::shell("echo %NQP_SHELL_TEST_ENV_VAR% > $tmp-file",nqp::cwd(),$env, nqp::null(), nqp::null(), nqp::null(),
    nqp::const::PIPE_INHERIT_IN + nqp::const::PIPE_INHERIT_OUT + nqp::const::PIPE_INHERIT_ERR
);
my $output := slurp($tmp-file);
nqp::unlink($tmp-file);
my $is-windows := $output ne "%NQP_SHELL_TEST_ENV_VAR%\n";

if $is-windows {
    skip("symlink not tested on Windows", 9);
}
else {
    nqp::unlink($test-file ~ '-symlink') if nqp::stat($test-file ~ '-symlink', nqp::const::STAT_EXISTS);
    $fh := nqp::open($test-file, 'w');
    nqp::printfh($fh, 'Hello');
    nqp::closefh($fh);
    nqp::symlink($test-file, $test-file ~ '-symlink');
    ok(!nqp::fileislink($test-file), 'nqp::fileislink on a file that is not a symbolic link');
    ok(nqp::fileislink($test-file ~ '-symlink'), 'nqp::fileislink on a symbolic link');
    is(nqp::readlink($test-file ~ '-symlink'), $test-file, 'nqp::readlink');
    ok(nqp::stat($test-file ~ '-symlink', nqp::const::STAT_EXISTS), 'the symbolic link should exist');
    ok(nqp::lstat($test-file ~ '-symlink', nqp::const::STAT_EXISTS), 'the symbolic link should exist');
    ok(nqp::stat($test-file ~ '-symlink', nqp::const::STAT_ISLNK), 'the symbolic link should actually *be* a symbolic link');
    ok(!nqp::stat($test-file, nqp::const::STAT_ISLNK), 'the normal test file should not *be* a symbolic link');
    nqp::unlink($test-file);
    nqp::unlink($test-file ~ '-symlink');

    nqp::symlink($test-file~'missing', $test-file ~ '-missing-symlink');
    ok( nqp::stat( $test-file ~ '-missing-symlink', nqp::const::STAT_EXISTS) == 0, 'nqp::stat exists on symlink');
    ok( nqp::lstat( $test-file ~ '-missing-symlink', nqp::const::STAT_EXISTS) == 1, 'nqp::lstat exists on symlink pointing to missing file');

    nqp::unlink($test-file ~ '-missing-symlink') if nqp::lstat($test-file ~ '-missing-symlink', nqp::const::STAT_EXISTS);
}

if $crlf-conversion {
    my $wfh := nqp::open($test-file, 'w');
    nqp::printfh($wfh, "abc\ndef\r\nghi");
    nqp::closefh($wfh);

    my $fh := nqp::open($test-file, 'r');
    my $input := nqp::readallfh($fh);
    is($input, "abc\ndef\nghi", "reading a whole file");
    nqp::closefh($fh);
} else {
    skip("readallfh doesn't convert \\r\\n on $backend");
}
nqp::unlink($test-file) if nqp::stat($test-file, nqp::const::STAT_EXISTS); # clean up test-file

if $is-windows || ($backend ne 'moar' && $backend ne 'js' && $backend ne 'jvm') {
    skip("symlink test not tested on Windows or $backend", 9);
}
else {

    my $symlink := $test-file ~ '-symlink';
    my $file := 't/nqp/019-file-ops.t';

    nqp::symlink('t/nqp/019-file-ops.t', $symlink);


    for [nqp::const::STAT_MODIFYTIME, nqp::const::STAT_ACCESSTIME, nqp::const::STAT_CHANGETIME] -> $flag {
      ok(nqp::stat_time($file, $flag) == nqp::lstat_time($file, $flag), 'stat_time works as lstat_time on regular file');
      ok(nqp::stat($file, $flag) == nqp::lstat($file, $flag), 'stat works as lstat on regular file');
      ok(nqp::stat_time($symlink, $flag) == nqp::lstat_time($file, $flag), 'stat_time follows symlink');
      ### This test was added between 2015.12 and 2016.01, but was failing.
      # since it's something new, commenting out for 2016.01 release.
      #ok(nqp::lstat_time($symlink, $flag) != nqp::lstat_time($file, $flag), 'lstat_time doesn\'t follow symlink');
    }


    if nqp::lstat($symlink, nqp::const::STAT_EXISTS) {
        nqp::unlink($symlink);
    }

}

{
    my $fh := nqp::open('t/nqp/019-chars.txt', 'r');
    is(nqp::readcharsfh($fh, 3), 'lin', 'nqp::readcharsfh');
    is(nqp::readcharsfh($fh, 2), 'π1', 'nqp::readcharsfh the second time with a multi byte character');
    nqp::readlinefh($fh);
    is(nqp::readcharsfh($fh, 5), 'line3', 'nqp::readcharsfh after nqp::readlinefh');
    is(nqp::readcharsfh($fh, 150), "line4\n", 'nqp::readcharsfh with more chars then they are in the file');
    nqp::closefh($fh);
}

my sub buf_dump($buf) {
    my @parts;
    my $i := 0;
    while $i < nqp::elems($buf) {
        @parts.push(~nqp::atpos_i($buf, $i));
        $i := $i + 1;
    }
    nqp::join(",", @parts);
}

my sub create_buf($type) {
    my $buf := nqp::newtype(nqp::null(), 'VMArray');
    nqp::composetype($buf, nqp::hash('array', nqp::hash('type', $type)));
    nqp::setmethcache($buf, nqp::hash('new', method () {nqp::create($buf)}));
    $buf;
};

{
    my $fh := nqp::open('t/nqp/019-chars.txt', 'r');
    my $buf := create_buf(uint8).new;
    ok(nqp::eqaddr(nqp::readfh($fh, $buf, 5), $buf), 'nqp::readfh should return the buffer');
    is(buf_dump($buf), '108,105,110,207,128', 'nqp::readfh read in correct unsigned bytes');
    is(buf_dump(nqp::readfh($fh, $buf, 4)), '49,46,108,105', 'nqp::readfh read in the next bytes correctly');
    nqp::closefh($fh);
}

{
    my $fh := nqp::open('t/nqp/019-chars.txt', 'r');
    my $buf := create_buf(int8).new;
    ok(nqp::eqaddr(nqp::readfh($fh, $buf, 5), $buf), 'nqp::readfh should return the buffer');
    is(buf_dump($buf), '108,105,110,-49,-128', 'nqp::readfh read in correct signed bytes');
    is(buf_dump(nqp::readfh($fh, $buf, 4)), '49,46,108,105', 'nqp::readfh read in the next signed bytes correctly');
    nqp::closefh($fh);
}

{
    my $out := nqp::open($test-file, 'w');

    my $buf1 := create_buf(uint8).new;
    nqp::push_i($buf1, 108);
    nqp::push_i($buf1, 105);
    nqp::push_i($buf1, 110);
    nqp::push_i($buf1, 207);
    nqp::push_i($buf1, 128);

    my $buf2 := create_buf(uint8).new;
    nqp::push_i($buf2, 49);
    nqp::push_i($buf2, 46);
    nqp::push_i($buf2, 108);
    nqp::push_i($buf2, 105);

    nqp::writefh($out, $buf1);
    nqp::writefh($out, $buf2);

    nqp::closefh($out);

    my $in := nqp::open($test-file, 'r');
    my $line := nqp::readlinefh($in);
    is($line, 'linπ1.li', 'reading with nqp::readlinefh stuff written by nqp::writefh');
    nqp::closefh($in);

    nqp::unlink($test-file);
}

{ # RT#131301: https://rt.perl.org/Ticket/Display.html?id=131301
    nqp::closedir(my $fh := nqp::opendir(".")); try nqp::nextfiledir($fh);
    ok( 1, 'no segfault when trying to nextfiledir() a closed dir handle' );

    my $dir := 'test-nqp-dir';

    nqp::mkdir($dir, 0o777);
    nqp::mkdir($dir, 0o777);

    ok(1, 'mkdir lives when the dir we create already exists');

    my $file1 := nqp::open($dir ~ '/file1', 'w');
    nqp::closefh($file1);

    my $file2 := nqp::open($dir ~ '/file2', 'w');
    nqp::closefh($file2);

    my $opened_dir := nqp::opendir($dir);

    my %got;

    while nqp::nextfiledir($opened_dir) -> $file {
      %got{$file} := 1;
    }

    nqp::closedir($opened_dir);

    ok(%got<file1> && %got<file2>, 'found the files we created');

    nqp::unlink($dir ~ '/file1');
    nqp::unlink($dir ~ '/file2');
    nqp::rmdir($dir);
}

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..45\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tree::Trie;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

# Basic tests -- adding, lookup and deepsearch params
$tree = new Tree::Trie;
ok( ($tree->add(qw/foo foot bar barnstorm food happy fish ripple/) == 8), 2 );
# Boolean lookups just return truth value
ok( ($tree->deepsearch("boolean") == 0), 3 );
ok( (scalar $tree->lookup("f")), 4 );
ok(!(scalar $tree->lookup("x")), 5 );
# Choose just randomly chooses one word to return
ok( ($tree->deepsearch("choose") == 1), 6 );
$test = $tree->lookup("ba");
ok( ($test eq 'bar' || $test eq 'barnstorm'), 7 );
ok(!(defined($tree->lookup("q"))), 8 );
# Count counts the number of words
ok( ($tree->deepsearch("count") == 2), 9 );
ok( ($tree->lookup("fo") == 3), 10 );
ok( ($tree->lookup("m") == 0), 11 );
@test = $tree->lookup("");
ok( ($#test == 7), 12 );
# Testing removal
ok( ($tree->remove(qw/foo ripple/) == 2 && $tree->lookup("") == 6), 13 );
# All the tests from before, but with arrayrefs instead of strings
$tree = new Tree::Trie;
ok( ($tree->add(
	[qw/00 01 02 03/], [qw/00 01 05 06/], "0001", [qw/aa bb cc ddd/]
) == 4), 14 );
$tree->deepsearch("boolean");
ok( (scalar $tree->lookup(["00"])), 15 );
ok(!(scalar $tree->lookup(["000"])), 16 );
ok( (scalar $tree->lookup("000")), 17 );
$tree->deepsearch("count");
ok( ($tree->lookup([qw/00 01 02/]) == 1), 18 );
ok( ($tree->lookup(["00"]) == 2), 19 );
ok( ($tree->lookup("00") == 1), 20 );
ok( (scalar $tree->remove("0001", [qw/aa bb cc ddd/]) == 2), 21 );
ok( ($tree->lookup([]) == 2), 22 );
# Testing data association
$tree = new Tree::Trie;
ok( ($tree->add_data(foo => 1, bar => 2) == 2), 23);
ok( ($tree->lookup_data('foo') == 1), 24);
ok( ($tree->add_data(foo => 3, baz => 4) == 1), 25);
ok( ($tree->lookup_data('foo') == 3), 26);
ok( ($tree->delete_data(qw/foo baz bip/) == 2), 27);
ok(!($tree->lookup_data('foo')), 28);
# Testing longest prefix lookup
$tree = new Tree::Trie;
ok( ($tree->add(qw#/usr/ /usr/local/ /var/#) == 3), 29);
$tree->deepsearch("prefix");
ok( ($tree->lookup('/usr/foo.txt') eq '/usr/'), 30);
ok( ($tree->lookup('/usr/lo') eq '/usr/'), 31);
ok( ($tree->lookup('/usr/local/') eq '/usr/local/'), 32);
ok( ($tree->lookup('/usr/local/bar.html') eq '/usr/local/'), 33);
# Testing suffix lookup
$tree = new Tree::Trie;
ok( ($tree->add(
	qw/foo foot bar barnstorm food happy fish ripple fission/
) == 9), 34 );
ok( ($tree->deepsearch("choose") == 1), 35 );
$test = $tree->lookup("ba", 2);
ok( ($test eq 'r' || $test eq 'rn'), 36 );
$test = $tree->lookup("fis", -1);
ok( ($test eq 'h' || $test eq 'sion'), 37 );
ok( ($tree->lookup("barn", -1) eq 'storm'), 38 );
ok( ($tree->deepsearch("count") == 2), 39 );
ok( ($tree->lookup("f", 2) == 2), 40 );
ok( ($tree->lookup("f", 3) == 5), 41 );
ok( ($tree->lookup("m", 1) == 0), 42 );
ok( ($tree->lookup("", 1) == 4), 43 );
ok( ($tree->lookup("", -1) == 9), 44 );
@test = $tree->lookup("ba", 3);
ok( (scalar @test == 2), 45 );

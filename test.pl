# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tree::Trie;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub ok { unless (shift()) { print "not "; } print "ok " . shift() . "\n" }

$x = 2;
$tree = new Tree::Trie;
ok( ($tree->add(qw/foo foot bar barnstorm food happy fish ripple/) == 8), 2 );
ok( ($tree->deepsearch("boolean") == 0), 3 );
ok( (scalar $tree->lookup("f")), 4 );
ok(!(scalar $tree->lookup("x")), 5 );
ok( ($tree->deepsearch("choose") == 1), 6 );
$test = $tree->lookup("ba");
ok( ($test eq 'bar' || $test eq 'barnstorm'), 7 );
ok(!(defined($tree->lookup("q"))), 8 );
ok( ($tree->deepsearch("count") == 2), 9 );
ok( ($tree->lookup("fo") == 3), 10 );
ok( ($tree->lookup("m") == 0), 11 );
@test = $tree->lookup("");
ok( ($#test == 7), 12 );
ok( ($tree->remove(qw/foo ripple/) == 2 && $tree->lookup("") == 6), 13 );
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

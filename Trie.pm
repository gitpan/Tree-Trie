# Tree::Trie, a module implementing a trie data structure.
# A formal description of tries can be found at:
# http://www.cis.syr.edu/~lockwood/html/abtries.html

package Tree::Trie;

require 5;
use strict;
use vars qw($VERSION);

$VERSION = "0.1";

##   Here there be methods

# The constructor method.  It's very simple, and I refuse to explain.
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{_MAINHASHREF} = {};
  bless($self, $class);
  return($self);
}

# The add() method takes a list of words as arguments and attempts to add
# them to the trie. In list context, returns a list of words successfully
# added.  In scalar context, returns a count of these words.  As of this
# version, the only reason a word can fail to be added is if it is already
# in the trie.  Or, I suppose, if there was a bug. :)
sub add {
  my($self) = shift;
  my(@words) = @_;

  my(@letters,@retarray);
  my($ref,$word,$letter) = ("","","");
  my($retnum) = 0;

  # Process each word...
  foreach $word (@words) {
    @letters = split('',$word);
    # Start at the top of the Trie...
    $ref = $self->{_MAINHASHREF};
    # Pull off letters one at a time.
    while (defined($letter = shift(@letters))) {
      # If that letter already had a branch from where we are, then we just
      # walk down that branch.
      if (exists $ref->{$letter}) {
        $ref = \%{ $ref->{$letter} };
      }
      else {
        # Once we find an letter for which there is no branch then we 
        # call the internal populate function to fill it in.
        $ref->{$letter} = _populate(@letters);
        # Update the applicable counter...
        if (wantarray) {
          push(@retarray,$word);
        }
        else {
          $retnum++;
        }
        # And move to the next word.
        last;
      }
    }
    # If we ran out of letters without finding an unpopulted branch and there
    # is not already a leaf node there, we add the leaf node.
    unless ((scalar @letters) || (exists $ref->{'00'})) {
      $ref->{'00'} = undef;
      # And again, update the correct counter.
      if (wantarray) {
        push(@retarray,$word);
      }
      else {
        $retnum++;
      }
    }
  }
  # When done, return results.
  return (wantarray ? @retarray : $retnum);
}

# The internal subroutine _populate() is just a convenient way to build a hash
# that looks like (for the word apple) {a}->{p}->{p}->{l}->{e}->{00}.  Returns
# a ref to the new hash, allowing us to include this branch structure in the
# main trie.
sub _populate {
  my(@letters) = @_;

  my(%temphash) = ();

  my($letter) = shift @letters;
  # Ooh, recursion.  Yay. :)
  unless (scalar @letters) {
    $temphash{$letter}{'00'} = undef;
  }
  else {
    $temphash{$letter} = _populate(@letters);
  }
  return \%temphash;
}

# The lookup() method searches for words (or beginnings of words) in the trie.
# It takes a single word as an argument and, in scalar context, either returns
# the word itself (if it exists), or a word beginning with the word being
# searched for, or undef if no words begin with the word being searched for.
# In list context, returns a list of all the words in the trie which begin
# with the given word.
sub lookup {
  my($self) = shift;
  my($word) = shift;

  my($ref) = $self->{_MAINHASHREF};

  my($letter) = "";
  my($stub,$nextletter) = ("","");
  my(@retarray) = ();

  my(@letters) = split('',$word);
  # Like everything else, we step across each letter
  while(defined($letter = shift(@letters))) {
    # If, at any point, we find that we've run out of tree before we've run out
    # of word, then there is nothing in the trie that begins with the input 
    # word, so we return an error status.
    unless (exists $ref->{$letter}) {
      return;
    }
    # If the letter is there, we just walk down the trie.
    $ref = \%{ $ref->{$letter} };
  }
  # Once we've walked all the way down the tree to the end of the word we were
  # given, there are a few things that can be done, depending on the context
  # that the method was called in.
  if (wantarray) {
    # If they want an array, then we use the walktree subroutine to collect all
    # of the words beneath our current location in the trie, and return them.
    @retarray = _walktree($word,$ref);
    return @retarray;
  }
  else {
    # If they want a scalar, then I continue to walk down the trie, collecting
    # letters, until we find a leaf node, at which point we stop.  Not that
    # this works properly if the exact word is in the trie.  Yay.
    until (exists $ref->{'00'}) {
      $nextletter = each(%{ $ref });
      # I need to call this to clear the each() call.
      keys(%{ $ref });
      $stub .= $nextletter;
      $ref = \%{ $ref->{$nextletter} };
    }
    return $word . $stub;
  }
}

# The walktree() sub takes a word beginning and a hashref (hopefully to a trie)
# and walks down the trie, gathering all of the word endings and retuning them
# appended to the word beginning.
sub _walktree {
  my($word,$ref) = @_[0,1];

  my($key) = "";
  my(@retarray) = ();

  # This is kind of tricky.  The value of the leaf nodes (which are hash keys)
  # is undef, so if $ref isn't defined then we're at a leaf and hit the base
  # case of the recursion.
  unless (defined($ref)) {
    # We've already appended the '00' in the leaf node, so we have to get rid
    # of it.  Oops.
    chop $word;
    chop $word;
    return $word;
  }
  foreach $key (keys %{ $ref }) {
    push(@retarray,_walktree($word . $key,$ref->{$key}));
  }
  return @retarray;
}

# The remove() method takes a list of words and, surprisingly, removes them
# from the trie.  It returns, in scalar context, the number of words removed.
# In list context, returns a list of the words removed.  As of now, the only
# reason a word would fail to be removed is if it's not in the trie in the
# first place.  Or, again, if there's a bug...  :)
sub remove {

  # The basic strategy here is as follows:
  ##
  # We walk down the trie one node at a time.  If at any point, we see that a
  # node can be deleted (that is, its only child is the one which continues the
  # word we're deleting) then we mark it as the 'last deleteable'.  If at any
  # point we find a node which *cannot* be deleted (it has more children other
  # than the one for the word we're working on), then we unmark our 'last
  # deleteable' from before.  Once done, delete from the last deleteable node
  # down.
  my($self) = shift;
  my(@words) = @_;

  my($word,$letter,$ref) = ("","","");
  my(@letters,@ldn,@retarray);
  my($retnum) = 0;

  foreach $word (@words) {
    @letters = split('',$word);
    # For each word, we need to put the leaf node entry at the end of the list
    # of letters.  We then reset the starting ref, and @ldn, which stands for
    # 'last deleteable node'.  It contains the ref of the hash and the key to
    # be deleted.  It does not seem possible to store a value passable to
    # the 'delete' builtin in a scalar, so we're forced to do this.
    push(@letters,'00');
    $ref = $self->{_MAINHASHREF};
    @ldn = ();
    
    # This is a special case, if the first letter of the word is the only 
    # key of the main hash.  I might not really need it, but this works as
    # it is.
    if (((scalar keys(%{ $ref })) == 1) && (exists $ref->{$letters[0]})) {
      @ldn = ($ref);
    }
    # And now we go down the trie, as described above.
    while (defined($letter = shift(@letters))) {
      # We break out if we're at the end, or if we're run out of trie before
      # finding the end of the word -- that is, if the word isn't in the
      # trie.
      last if ($letter eq '00');
      last unless exists($ref->{$letter});
      if (scalar keys(%{ $ref->{$letter} }) == 1 && exists $ref->{$letter}{$letters[0]}) {
        unless (scalar @ldn) {
          @ldn = ($ref,$letter);
        }
      }
      else {
        @ldn = ();
      }
      $ref = \%{ $ref->{$letter} };
    }
    # If we broke out and there were still letters left in @letters, then the
    # word must not be in the trie.  Furthermore, if we got all the way to
    # the end, but there's no leaf node, the word must not be in the trie.
    next if (scalar @letters);
    next unless (exists($ref->{'00'}));
    # If @ldn is empty, then the only deleteable node is the leaf node, so
    # we set this up.
    if (scalar @ldn == 0) {
      @ldn = ($ref,'00');
    }
    # If there's only one entry in @ldn, then it's the ref of the top of our
    # Trie.  If that's marked as deleteable, then we can just nuke the entire
    # hash.
    if (scalar @ldn == 1) {
      %{ $ldn[0] } = ();
    }
    # Otherwise, we just delete the key we want to.
    else {
      delete($ldn[0]->{$ldn[1]});
    }
    # And then just return stuff.
    if (wantarray) {
      push (@retarray,$word);
    }
    else {
      $retnum++;
    }
  }
  if (wantarray) {
    return @retarray;
  }
  else {
    if ($retnum) {
      return $retnum;
    }
    else {
      return undef;
    }
  }
}
1;

__END__

=head1 NAME

Tree::Trie - An implementation of the Trie data structure in Perl

=head1 SYNOPSIS

 use Tree::Trie;
 use strict;

 my($trie) = new Tree::Trie;
 $trie->add(qw[aeode calliope clio erato euterpe melete melpomene mneme 
   polymnia terpsichore thalia urania]);
 my(@all) = $trie->lookup("");
 my(@ms)  = $trie->lookup("m");
 $" = "--";
 print "Entire trie contains: @all\nMuses beginning with 'm': @ms\n";
 my(@deleted) = $trie->remove(qw[calliope thalia doc]);
 print "Deleted @deleted\n";
 

=head1 DESCRIPTION

This module implements a trie data structure.  The term "trie" comes from the
word reB<trie>val, but is generally pronounced like "try".  A trie is a tree
structure, the nodes of which represent letters in a word.  For example, the
final lookup for the word 'bob' would look something like 
C<$ref-E<gt>{'b'}{'o'}{'b'}{'00'}> (the '00' being the end marker).  Only nodes
which would represent words in the trie exist, making the structure slightly
smaller than a hash of the same data set.

The advantages of the trie over other data storage methods is that lookup
times are O(1) WRT the size of the index.  For sparse data sets, it is probably
not as efficient as performing a binary search on a sorted list, and for small
files, it has a lot of overhead.  The main advantage (at least from my 
perspective) is that it provides a relatively cheap method for finding a list
of words in your set which begin with a certain string.

=head1 METHODS

=over 4

=item new

This is the constructor method for the class.  It takes no arguments.


=item add(word0 [, word1...wordN])

This method attempts to add words 0 through N to the trie.  Returns, in list
context, the words successfully added to the trie.  In scalar context, returns
the number of words successfully added.  As of this release, the only reason
a word would fail to be added is if it is already in the trie.


=item remove(word0 [, word1...wordN])

This method attempts to remove words 0 through N from the trie.  Returns, in
list context, the words successfully removed from the trie.  In scalar context,
returns the number of words successfully removed.  As of this release, the only
reason a word would fail to be removed is if it is not already in the trie.


=item lookup(word0)

This method performs lookups on the trie.  In scalar context, returns the first
word found in the trie which begins with word0.  If word0 exists exactly in
the trie, returns word0.  Returns undef if no words beginning with word0 are
in the trie.  In list context, returns a complete list of words in the trie
which begin with word0.

To get a list of all words in the trie, use C<lookup("")> in list context.

=back

=head1 Future Work

=over 4

=item * 

I plan on making a "DeepSearch" (or similarly named) method, allowing the 
bahviour of the lookup method in scalar context to be configured -- it will be
able to return undef if word0 does not exist exactly in the trie.

=item *

The ability to associate data with each word in a trie will be added.

=item *

There are a few methods of compression that allow you same some amount of space 
in the trie.  I have to figure out which ones are worth implemeting.  I may
end up making the different compression methods configurable.

=item *

The ability to have Tree::Trie store its internal hash as a TIE object of some
sort.

=back

=head1 AUTHOR

Copyright 1999 Avi Finkel <F<avi@lycos.com>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

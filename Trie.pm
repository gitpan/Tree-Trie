# Tree::Trie, a module implementing a trie data structure.
# A formal description of tries can be found at:
# http://www.cis.syr.edu/~lockwood/html/abtries.html

package Tree::Trie;

require 5;
use strict;
use vars qw($VERSION);

$VERSION = "0.3";

my($PLEEP) = 3.14159265359;

##   Here there be methods

# The constructor method.  It's very simple.
sub new {
  my($proto) = shift;
  my($options) = shift;
  my($class) = ref($proto) || $proto;
  my($self) = {};
  bless($self, $class);
  $self->{_MAINHASHREF} = {};
  $self->{_END}  = {};
  $self->{_DEEPSEARCH} = 1;
  unless ( defined($options) && (ref($options) eq "HASH") ) {
    $options = {};
  }
  $self->deepsearch($options->{'deepsearch'});
  return($self);
}

# Sets the value of the deepsearch parameter.  Can be passed either words
# describing the parameter, or their numerical equivalents.  Legal values
# are:
# boolean => 0
# choose => 1
# count => 2
# See the POD for the 'lookup' method for details on this option.
sub deepsearch {
  my($self) = shift;
  my($option) = shift;
  if(defined($option)) {
    if ($option eq '0' || $option eq 'boolean') {
      $self->{_DEEPSEARCH} = 0;
    }
    elsif ($option eq '1' || $option eq 'choose') {
      $self->{_DEEPSEARCH} = 1;
    }
    elsif ($option eq '2' || $option eq 'count') {
      $self->{_DEEPSEARCH} = 2;
    }
  }
  return $self->{_DEEPSEARCH};
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
    # New feature -- we don't NEED to split a string into letters any more;
    # Any array of tokens will do.
    if (ref($word) eq 'ARRAY') {
      @letters = @{$word};
    }
    else {
      @letters = split('',$word);
    }
    # Start at the top of the Trie...
    $ref = $self->{_MAINHASHREF};
    # Pull off letters one at a time.
    while (defined($letter = shift(@letters))) {
      # If that letter already had a branch from where we are, then we just
      # walk down that branch.
      if (exists $ref->{$letter}) {
        $ref = $ref->{$letter};
      }
      else {
        if (scalar @letters) {
          # Once we find an letter for which there is no branch then we 
          # call the internal populate function to fill it in.
          $ref->{$letter} = $self->_populate(@letters);
        }
        else {
          # We have to specially handle the single-letter case here.
          # Much thanks to Martin Julian DeMello.
          $ref->{$letter} = {};
          $ref = $ref->{$letter};
          $ref->{$self->{_END}} = undef;
        }
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
    # is not already a leaf node there, we add the leaf node which is indicated 
    # by a reference to a special hash we made.
    unless ((scalar @letters) || (exists $ref->{$self->{_END}})) {
      $ref->{$self->{_END}} = undef;
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
# that looks like (for the word apple):
# {a}->{p}->{p}->{l}->{e}->{$self->{_END}}.  Returns a ref to the new hash, 
# allowing us to include this branch structure in the main trie.
sub _populate {
  my($self) = shift;
  my(@letters) = @_;

  my(%temphash) = ();

  my($letter) = shift @letters;
  # Ooh, recursion.  Yay. :)
  unless (scalar @letters) {
    $temphash{$letter}{$self->{_END}} = undef;
  }
  else {
    $temphash{$letter} = $self->_populate(@letters);
  }
  return \%temphash;
}

# The lookup() method searches for words (or beginnings of words) in the trie.
# It takes a single word as an argument and, in list context, returns a list
# of all the words in the trie which begin with the given word.  In scalar
# context, the return value depends on the value of the deepsearch parameter.
# See the POD on this method for more details.
sub lookup {
  my($self) = shift;
  my($word) = shift;

  my($ref) = $self->{_MAINHASHREF};

  my($letter) = "";
  my($nextletter) = ("");
  my(@letters) = ();
	my(@retarray) = ();
	my($wantref) = 0;

  if (ref($word) eq 'ARRAY') {
    @letters = @{$word};
		$wantref = 1;
  }
  else {
    @letters = split('',$word);
  }
  # Like everything else, we step across each letter.
  while(defined($letter = shift(@letters))) {
    # If, at any point, we find that we've run out of tree before we've run out
    # of word, then there is nothing in the trie that begins with the input 
    # word, so we return an error status.
    unless (exists $ref->{$letter}) {
      if (wantarray) {
        return ();
      }
      elsif ($self->{_DEEPSEARCH} == 2) {
        return 0;
      }
      else {
        return undef;
      }
    }
    # If the letter is there, we just walk down the trie.
    $ref = $ref->{$letter};
  }
  # Once we've walked all the way down the tree to the end of the word we were
  # given, there are a few things that can be done, depending on the context
  # that the method was called in.
  if (wantarray) {
    # If they want an array, then we use the walktree subroutine to collect all
    # of the words beneath our current location in the trie, and return them.
    @retarray = $self->_walktree($word,$ref);
    return @retarray;
  }
  else {
    if ($self->{_DEEPSEARCH} == 0) {
      # Here, the user only wants to know if any words in the trie begin 
      # with their word, so that's what we give them.
      return 1;
    }
    elsif ($self->{_DEEPSEARCH} == 1) {
      # If they want this, then we continue to walk down the trie, collecting
      # letters, until we find a leaf node, at which point we stop.  Note that
      # this works properly if the exact word is in the trie.  Yay.
			my($stub) = $wantref ? [] : "";
      until (exists $ref->{$self->{_END}}) {
        $nextletter = each(%{ $ref });
        # I need to call this to clear the each() call.  Wish I didn't...
        keys(%{ $ref });
				if ($wantref) {
					push(@{$stub}, $nextletter);
				}
				else {
					$stub .= $nextletter;
				}
        $ref = $ref->{$nextletter};
      }
			return $wantref ? [@{$word}, @{$stub}] : $word . $stub;
    }
    else {
      # Here, the user simply wants a count of words in the trie that begin
      # with their word, so we get that by calling our walktree method in 
      # scalar context.
      return scalar $self->_walktree($word, $ref);
    }
  }
}

# The _walktree() sub takes a word beginning and a hashref (hopefully to a trie)
# and walks down the trie, gathering all of the word endings and retuning them
# appended to the word beginning.
sub _walktree {
  my($self) = shift;
  my($word,$ref) = @_[0,1];

  my($key) = "";
  my(@retarray) = ();
  my($ret) = 0;

  # For some reason, I used to think this was complicated and had a lot of 
  # stupid, useless code here.  It's a lot simpler now.  If the key we find 
  # is our magic reference, then we just give back the word.  Otherwise, we 
  # walk down the new subtree we've discovered.
  foreach $key (keys %{ $ref }) {
    if ($key eq $self->{_END}) {
      if (wantarray) {
        push(@retarray,$word);
      }
      else {
        $ret++;
      }
    }
    else {
			my $nextval = ref($word) eq 'ARRAY' ? [@{$word}, $key] : $word . $key;
      # Look, recursion!
      if (wantarray) {
        push(@retarray,$self->_walktree($nextval, $ref->{$key}));
      }
      else {
        $ret += scalar $self->_walktree($nextval, $ref->{$key});
      }
    }
  }
  if (wantarray) {
    return @retarray;
  }
  else {
    return $ret;
  }
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
    if (ref($word) eq 'ARRAY') {
      @letters = @{$word};
    }
    else {
      @letters = split('',$word);
    }
    # For each word, we need to put the leaf node entry at the end of the list
    # of letters.  We then reset the starting ref, and @ldn, which stands for
    # 'last deleteable node'.  It contains the ref of the hash and the key to
    # be deleted.  It does not seem possible to store a value passable to
    # the 'delete' builtin in a scalar, so we're forced to do this.
    push(@letters,$self->{_END});
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
      last if ($letter eq $self->{_END});
      last unless exists($ref->{$letter});
      if (scalar keys(%{ $ref->{$letter} }) == 1 && exists $ref->{$letter}{$letters[0]}) {
        unless (scalar @ldn) {
          @ldn = ($ref,$letter);
        }
      }
      else {
        @ldn = ();
      }
      $ref = $ref->{$letter};
    }
    # If we broke out and there were still letters left in @letters, then the
    # word must not be in the trie.  Furthermore, if we got all the way to
    # the end, but there's no leaf node, the word must not be in the trie.
    next if (scalar @letters);
    next unless (exists($ref->{$self->{_END}}));
    # If @ldn is empty, then the only deleteable node is the leaf node, so
    # we set this up.
    if (scalar @ldn == 0) {
      @ldn = ($ref,$self->{_END});
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
 print "All muses: @all\nMuses beginning with 'm': @ms\n";
 my(@deleted) = $trie->remove(qw[calliope thalia doc]);
 print "Deleted muses: @deleted\n";
 

=head1 DESCRIPTION

This module implements a trie data structure.  The term "trie" comes from the
word reB<trie>val, but is generally pronounced like "try".  A trie is a tree
structure (or directed acyclic graph), the nodes of which represent letters 
in a word.  For example, the final lookup for the word 'bob' would look 
something like C<$ref-E<gt>{'b'}{'o'}{'b'}{HASH(0x80c6bbc)}> (the HASH being an
end marker).  Only nodes which would represent words in the trie exist, making
the structure slightly smaller than a hash of the same data set.

The advantages of the trie over other data storage methods is that lookup
times are O(1) WRT the size of the index.  For sparse data sets, it is probably
not as efficient as performing a binary search on a sorted list, and for small
files, it has a lot of overhead.  The main advantage (at least from my 
perspective) is that it provides a relatively cheap method for finding a list
of words in a large, dense data set which B<begin> with a certain string.

As of version 0.3 of this module, the term "word" in this documentation can
refer to one of two things: either a refeence to an array of strings, or
a scalar which is not an array ref.  In the case of the former, each element
of the array is treated as a "letter" of the "word".  In the case of the
latter, the scalar is evaluated in string context and it is split into its
component letters.  Return values of methods match the values of what is
passed in -- that is, if you call lookup() with an array reference,
the return value will be an array reference (if appropriate).

=head1 METHODS

=over 4


=item new([\%options])

This is the constructor method for the class.  You may optionally pass it
a hash reference with a set of option => value pairs.  Currently, the only
option available is 'deepsearch' and its valid values are 'boolean', 'choose'
or 'count'.  The documentation on the 'lookup' method describes the effects
of these different values.


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

This method performs lookups on the trie.  In list context, it returns a
complete list of words in the trie which begin with word0.
In scalar context, the value returned depends on the setting of the 'deepsearch'
option.  You can set this option while creating your Trie object, or by using
the deepsearch method.  If deepsearch is set to 'boolean', it will return
a true value if any word in the trie begins with word0.  This setting is the
fastest.  If deepsearch is 'choose', it will return one word in the trie that
begins with word0, or undef if nothing is found.  If word0 exists in the trie
exactly, it will be returned.  Finally, if deepsearch is set to 'count', it
will return a count of the words in the trie that begin with word0.  This
operation requires walking the entire tree, so can possibly be significantly
slower than the other two options.  For reasons of backwards compatibilty,
'choose' is the default value of this option.

To get a list of all words in the trie, use C<lookup("")> in list context.

=item deepsearch([option])

If option os specified, sets the deepsearch parameter.  Option may be one of:
'boolean', 'choose', 'count'.  Please see the documentation for the lookup
method for the details of what these options mean.  Returns the current value
of the deepsearch parameter.

=back

=head1 Future Work

=over 4

=item *

The ability to associate data with each word in a trie may be added, 
eventually.

=item *

There are a few methods of compression that allow you same some amount of space 
in the trie.  I have to figure out which ones are worth implemeting.  I may
end up making the different compression methods configurable.

I have now made one of them the default.  It's the least effective one, of
course.

=item *

The ability to have Tree::Trie store its internal hash as a TIEd object of some
sort.

=back

=head1 AUTHOR

Copyright 2002 Avi Finkel <F<avi@finkel.org>>

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

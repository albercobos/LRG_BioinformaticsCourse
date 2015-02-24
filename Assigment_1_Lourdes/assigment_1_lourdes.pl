#!perl
use strict;
use warnings;
use Gene;
use StockDatabase;
use HybridCross;

# Main

# this is just a friendly message to the users of the program
unless ($ARGV[0] && $ARGV[1] && $ARGV[2] && $ARGV[3]){ #unless 4 arguments are passed to the script
 # print an informative message about the usage of the program 
 print "\n\n\nUSAGE: perl ProcessHybridCrossData.pl gene_information.tsv seed_stock_data.tsv cross_data.tsv new_stock_filename.tsv\n\n\n";
 exit 0; # and exit
}

# get the 4 filenames
my $gene_data_file = $ARGV[0]; # contains gene information
my $stock_data_file = $ARGV[1]; # contains stock information
my $cross_data_file = $ARGV[2]; # contains hybridcross information
my $new_stock_data_filename = $ARGV[3]; # new stock filename

my $gene_data = &load_gene_data($gene_data_file); # call load data subroutine
# $gene_data is a hashref of $gene_data(Gene_ID) = $Gene_Object

my $stock_database=StockDatabase->new(); # create a new stock database
$stock_database->load_from_file($stock_data_file, $gene_data); # call load data method
# stock data file, hashref $gene_data
# $stock_database is an object with a hash of seed stock objects as attribute

&plant_seeds($stock_database, 7); # current stock database, plant 7 grams
# this line calls on a subroutine that updates the status of every seed record in the database
# after planting a certain amount of seeds

$stock_database->write_database($new_stock_data_filename); # new database filename
# the line above creates the file new_stock_filename.tsv with the current state of the seed stock database
# the new state reflects the fact that we just planted 7 grams of seed...

&process_cross_data($cross_data_file, $stock_database); # cross data file, stock database object
# the line above tests the linkage
# the Gene objects become updated with the other genes they are linked to.

print "\n\nFinal Report:\n\n";

foreach my $gene (keys %{$gene_data}){ # for each of the genes in the gene_data hash
 if ($gene_data->{$gene}->has_linkage){ # only process the Gene Object if it has linked genes
  # has_linkage is a predicate for Linkage_To
  my $gene_name = $gene_data->{$gene}->Gene_Name; # get the name of that gene
  my $LinkedGenes = $gene_data->{$gene}->Linkage_To; # get the Gene objects that are linked to it
  foreach my $linked(@{$LinkedGenes}){ # dereference the array, and then for each of the array members
    my $linked_name = $linked->Gene_Name; # get its name using the Gene_Name property
    print "$gene_name is linked to $linked_name\n"; # and print the information
  }
 }
}


# Subroutines

sub load_gene_data{
# retrieves gene information from a file (tab-delimited) and creates a hash of gene objects from it
  my $gene_data_file=$ARGV[0]; # file containing gene information
  # fields are delimited by tab and has a header line
  my %gene_data; # hash of $gene_data{Gene_ID} = $Gene_Object
  open(FILEHANDLE, "<$gene_data_file") or die "File $gene_data_file could not be opened\n"; # open the file or die a warning message
  while (<FILEHANDLE>){ # for each of the lines in the file
    next if $. < 2; # skip the header line
    my ($gene_id, $gene_name, $mutant_phenotype) = split "\t", $_; # split the line by the tab delimiter
    # and store the values of each field
    chomp ($gene_id, $gene_name, $mutant_phenotype); # remove the newline character
    my $gene_object=Gene->new( # create a new Gene Object
    # assign each variable to the correct property of $gene_object                          
      Gene_Name => $gene_name,
      Gene_ID => $gene_id,
      Mutant_Phenotype => $mutant_phenotype
    );
    $gene_data{$gene_id}=$gene_object; # store $gene_object inside the hash as a value, with its gene id as key
  }
  close FILEHANDLE; #close the file
  return \%gene_data; # return the hashref of %gene_data   
}



sub plant_seeds{
# updates the status of every seed record in the stock database object
# after planting a certain amount of seeds
  my ($stock_database, $amount) = @_; # current stock database, amount (in grams) of seeds to plant
  my($day, $month, $year)=(localtime)[3,4,5]; # localtime[3,4,5] returns the day of the month,
  # the month in a range 0-11 and the number of years since 1900
  my $date="$day/" . ($month+1) . "/" . ($year+1900); # obtain current date
  my @run_out; # array that will store the identifiers of the empty stocks (if any)
  my $seed_stocks = $stock_database->SeedStocks; # get the hashref of SeedStocks
  foreach my $stock_id (keys %{$seed_stocks}){ # for each of the seed stock ids in the database
    my $stock_object=$stock_database->get_seed_stock($stock_id); # get the corresponding stock object
    my $grams_left=$stock_object->Grams_Left; # retrieve the amount of grams left
    if ($grams_left<$amount || $grams_left==$amount) { # only if the seed amount to plant
    # is less than or equal to the current seed amount of the stock:
      $grams_left=0; # set the seed amount to 0
      push (@run_out, $stock_id); # store the stock id inside @run_out
    } else { # only if the seed amount to plant is greater than the current stock
      $grams_left=$grams_left-$amount; # take out the amount from it
    }
    $stock_object->Grams_Left($grams_left); #update the seed amount of the stock
    $stock_object->Last_Planted($date); #update the Last_Planted attribute with current date
  }
  if (@run_out) { # warn the user only if there are empty stocks
    foreach (@run_out) { #for each element in the array
      print "WARNING: we have run out of Seed Stock $_\n"; #display a warning message about the empty stock
    }  
  }
}

sub process_cross_data{
# tests the linkage between the genes involved in a hybrid cross
# The corresponding gene objects become updated with the other genes they are linked to
  my ($cross_data_file, $stock_database) = @_; # cross information filename, stock database object
  my $cross_data=&load_cross_data($cross_data_file, $stock_database); #call load data function
  # $cross_data is a hashref of $cross_data(Stock_ID_1)(Stock_ID_2) = $HybridCross_Object
  foreach my $parent_1 (sort keys %{$cross_data}){ # for each pair of Parent 1 and Parent 2 in the cross_data hash
    foreach my $parent_2 (keys %{$cross_data->{$parent_1}}){
      my $cross_object=$cross_data->{$parent_1}{$parent_2}; # get the corresponing cross object
      my $chi_square=&compute_chi_square($cross_object); # get the chi square value of the cross object
      if ($chi_square>7.8147){ # accept the linkage only if the chi square value is greater than
      # the probability of chi square with 3 degrees of freedom (number of phenotypes - 1)
      # and a probability level of 5%
        my $stock_object_1=$stock_database->get_seed_stock($parent_1); # get the stock object of Parent 1
        my $stock_object_2=$stock_database->get_seed_stock($parent_2); # get the stock object of Parent 2
        my $linked_gene=$stock_object_1->Gene_Object; # get the gene object of stock 1
        push @{$stock_object_2->Gene_Object->{Linkage_To}}, $linked_gene; # add the gene object of stock 1
        # as a linked gene of gene object of stock 2 ('Linkage_To' is a property of ArrayRef[Gene])
        $linked_gene=$stock_object_2->Gene_Object; # get the gene object of stock 2
        push @{$stock_object_1->Gene_Object->{Linkage_To}}, $linked_gene; # add the gene object of stock 2
        # as a linked gene of gene object of stock 1 ('Linkage_To' is a property of ArrayRef[Gene])
      }
    } 
  }
}


sub load_cross_data{
# retrieves hybrid cross information from a file (tab-delimited) and creates a hash of hybridcross objects from it  
  my ($cross_data_file, $stock_database) = @_; # cross information file, stock database object
  my %cross_data; # hash of $cross_data(Stock_ID_1)(Stock_ID_2) = $HybridCross_Object
  open(FILEHANDLE, "<$cross_data_file") or die "File $cross_data_file could not be opened\n"; #open the file or die a warning message
  while (<FILEHANDLE>){ # for each of the lines in the file
    next if $. < 2; # skip the header line
    my ($stock_id_1, $stock_id_2, $wild , $p1, $p2, $p1_p2) = split "\t", $_; # split the line by tab delimiter
    # and store the values of the fields
    chomp ($stock_id_1, $stock_id_2, $wild , $p1, $p2, $p1_p2); # remove the newline character
    my $stock_object_1=$stock_database->get_seed_stock($stock_id_1); # get the stock object of Parent 1 with the corresponding
    # stock id from the database 
    my $stock_object_2=$stock_database->get_seed_stock($stock_id_2); # get the stock object of Parent 2 with the corresponding
    # stock id from the database
    my $cross_object=HybridCross->new( # create a new HybridCross Object
    # assign each variable to the correct property of $cross_object  
      SeedStock_Object_1 => $stock_object_1,
      SeedStock_Object_2 => $stock_object_2,
      F2_Wild => $wild,
      F2_P1 => $p1,
      F2_P2 => $p2,
      F2_P1P2 => $p1_p2
    );
    $cross_data{$stock_id_1}{$stock_id_2}=$cross_object; # store $cross_object inside the hash as a value,
    # with the stock ids of Parent 1 and Parent 2 as keys (bidimensional hash)
  }
  close FILEHANDLE; # close the file
  return \%cross_data; # return the hashref of %cross_data
}

sub compute_chi_square{
# computes the chi square value for a hybridcross object 
  my ($cross_object)=@_; # get the cross object
  my @obs = ( #array containing observed values of offspring
    $cross_object->F2_Wild, # observed offspring of wild
    $cross_object->F2_P1, # observed offspring of p1 recessive
    $cross_object->F2_P2, # observed offspring of p2 recessive
    $cross_object->F2_P1P2 # observed offspring of p1p2 recessive
  );
  my $total=0; # value set to zero to avoid perl warning message at the following line:
  foreach (@obs) {$total=$total+$_;} # add all the observed values to get the total offspring
  my @exp = ( # array containing expected values
    (9/16)*$total, # expected proportion of wild offspring
    (3/16)*$total, # expected proportion of p1 recessive offspring
    (3/16)*$total, # expected proportion of p2 recessive offspring
    (1/16)*$total # expected proportion of p1p2 recessive offspring
  );
  my $chi_square=0; # value set to zero to avoid perl warning message at the for loop
  my $pairs=scalar @obs; # get the total number of observed values
  # which is equal to the total number of expected values
  for (my $i=0;$i<$pairs;$i++) { # for every pair of observed and expected values
    $chi_square=$chi_square+(($obs[$i]-$exp[$i])**2)/$exp[$i]; # summatory of (Observed - Expected)²/Expected
  }
  return $chi_square; # return the chi square value
}

exit 1;

package StockDatabase;
use SeedStock;
use Moose;

# Attributes

has 'SeedStocks' => ( # a place to store the seed stocks of the database
    is=>'rw',
    isa=>'HashRef[SeedStock]' # must be a hash ref of SeedStock objects
);

# Methods

sub load_from_file{
# retrieves stock information from a file (tab-delimited) and creates seed stock objects from it,
# which are store inside the SeedStocks property (Hashref[SeedStock]) of the stock database object
  my ($self, $stock_data_file, $gene_data) = @_; # stock database object, file containing stock information,
  # hashref of $gene_data{Gene_ID} = $Gene_Object
  # in stock file, fields are delimited by tab and has a header line
  open(FILEHANDLE, "<$stock_data_file") or die "File $stock_data_file could not be opened\n"; #open the file or die a warning message
  my %seed_stocks; # hash that will store the stock objects
  # this hash will be used to assign the HashRef[SeedStocks] attribute of the database  
  while (<FILEHANDLE>){ # for each of the lines in the file
    next if $. < 2; # skip the header line
    my ($stock_id, $gene_id, $last_planted, $storage, $grams_left) = split "\t", $_; # split the line by tab delimiter
    # and store the values of the fields
    chomp ($stock_id, $gene_id, $last_planted, $storage, $grams_left); # remove the newline character
    my $gene_object=$gene_data->{$gene_id}; # get the gene object with the corresponding id from $gene_data
    my $stock_object=SeedStock->new( # create a new Stock Object
    # assign each variable to the correct property of $stock_object
        Stock_ID => $stock_id,
        Gene_Object => $gene_object,
        Last_Planted => $last_planted,
        Storage => $storage,
        Grams_Left => $grams_left
    );
    $seed_stocks{$stock_id} = $stock_object; # store $stock_object inside the hash, with its stock id as key
  }
  close FILEHANDLE; # close the file
  $self->SeedStocks(\%seed_stocks); # once all the stocks have been stored in the hash,
  # assign it to the SeedStocks property
}

sub get_seed_stock{
# given a stock id, retrieves the corresponding stock object stored in the database
    my ($self, $stock_id) = @_; # stock database object, stock id
    my $stock_object = $self->SeedStocks->{$stock_id}; # get the stock object from the hashref SeedStocks (Hashref[SeedStock])   
    return $stock_object; # return the stock
}

sub write_database{
# creates the file new_stock_filename.tsv with the current state of the stock database
  my ($self, $new_stock_data_filename) = @_; # stock database object, name of new file
  open(OUTFILE, ">$new_stock_data_filename"); # create the new stock data file
  print OUTFILE "Seed_Stock\tMutant_Gene_ID\tLast_Planted\tStorage\tGrams_Remaining\n"; # print header
  my $seed_stocks = $self->SeedStocks; # get the hashref of SeedStocks
  foreach my $stock_id (keys %{$seed_stocks}){ # for each of the seed stock ids in the database
    my $stock_object=$self->get_seed_stock($stock_id); # get the corresponding stock object
    # print the data of the object delimited by tab
    print OUTFILE $stock_object->Stock_ID . "\t" . $stock_object->Gene_Object->Gene_ID . "\t";
    print OUTFILE $stock_object->Last_Planted . "\t" . $stock_object->Storage . "\t";
    print OUTFILE $stock_object->Grams_Left . "\n";
  }
  close OUTFILE; # close the file
}
1;



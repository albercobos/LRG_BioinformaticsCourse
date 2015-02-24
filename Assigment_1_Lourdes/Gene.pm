package Gene;
use Moose;

# Attributes

has 'Gene_Name' => (
    is=>'rw',
    isa=>'Str'
);
has 'Gene_ID' => (
    is=>'rw',
    isa=>'Str',
    trigger => sub{ # excute the following piece of code every time a new Gene_ID value is set
        my ($self, $id)=@_; # $gene_object, $new value of Gene_ID
        unless ($id=~/A[Tt]\d[Gg]\d{5}/){ # unless the id verifies the Arabidopsis gene identifier format
            die "$id is not a valid Arabidopsis gene identifier\n"; # die a warning message
        }
    }  
);
has 'Linkage_To' =>(
    is=>'rw',
    isa=>'ArrayRef[Gene]', # must be an array ref of Gene Objects
    predicate=>'has_linkage',
);
has 'Mutant_Phenotype' =>(
    is=>'rw',
    isa=>'Str'
);

1;
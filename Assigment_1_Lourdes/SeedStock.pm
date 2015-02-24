package SeedStock;
use Moose;

# Attributes

has 'Stock_ID' => (
    is=>'rw',
    isa=>'Str'
);
has 'Gene_Object' => (
    is=>'rw',
    isa=>'Gene' # must be a Gene Object
);
has 'Last_Planted' => (
    is=>'rw',
    isa=>'Str'
);
has 'Storage' => (
    is=>'rw',
    isa=>'Str'
);
has 'Grams_Left' => (
    is=>'rw',
    isa=>'Int',
);

1;
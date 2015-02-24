package HybridCross;
use Moose;

# Attributes

has 'SeedStock_Object_1' => ( # stock object of Parent 1
    is=>'rw',
    isa=>'SeedStock' # must be a Seed Stock object
);
has 'SeedStock_Object_2' => ( # stock object of Parent 2
    is=>'rw',
    isa=>'SeedStock' # must be a Seed Stock object   
);
has 'F2_Wild' => ( # wild offspring
    is=>'rw',
    isa=>'Int'    
);
has 'F2_P1' => ( # p1 recessive offspring
    is=>'rw',
    isa=>'Int'     
);
has 'F2_P2' => ( # p2 recessive offspring
    is=>'rw',
    isa=>'Int'     
);
has 'F2_P1P2' => ( # p1 and p2 recessive offspring
    is=>'rw',
    isa=>'Int'     
);
1;
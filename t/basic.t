use Mojo::Base -strict;

use Test::More tests => 4;
use Test::Mojo;

use_ok 'Compras';

my $t = Test::Mojo->new('Compras');
$t->get_ok('/compras')->status_is(200)->content_like(qr/Lista de compras/i);

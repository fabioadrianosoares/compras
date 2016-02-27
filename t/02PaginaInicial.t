use Mojo::Base -strict;

use Test::More tests => 16;
use Test::Mojo;

use utf8;

use_ok 'Compras';

my $t = Test::Mojo->new('Compras');
$t->get_ok('/compras')->status_is(200)->text_is('html head title' => 'Lista de Compras', 'Titulo');

# validar existencia dos links do menu
$t->text_is('html body a[href="/compras/secao"]' => 'Seção', 'Link para secoes');
$t->text_is('html body a[href="/compras/produto"]' => 'Produto', 'Link para produtos');
$t->text_is('html body a[href="/compras/lista"]' => 'Lista', 'Link para listas');

# is($t->tx->res->dom('html body h1')->first->text, 'Lista de compras', 'Titulo do corpo');

$t->get_ok('/compras/secao')->status_is(200)->text_is('html body h2' => 'Nenhuma seção cadastrada');
$t->get_ok('/compras/produto')->status_is(200)->text_is('html body h2' => 'Nenhum produto cadastrado');
$t->get_ok('/compras/lista')->status_is(200)->text_is('html body h2' => 'Nenhuma lista cadastrada');

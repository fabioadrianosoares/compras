use Mojo::Base -strict;

use Test::More tests => 150;
use Test::Mojo;

use File::Basename 'dirname';

use utf8;

use_ok 'Compras';

my $t = Test::Mojo->new('Compras');

$t->get_ok('/compras/secao/editar')->status_is(200)->element_exists('html body form', 'Formulario para inclusao');

## Cadastrar uma secao, editar e excluir na sequencia.
$t->post_form_ok('/compras/secao/salvar' => {id => '', nome => 'Dummy', salvar => 'salvar'});
$t->status_is(200)->content_like(qr/Registro incluido/, 'Confirmar Primeira Secao');

$t->get_ok('/compras/secao')->status_is(200)->text_is('html body ul li a' => 'Dummy', 'Link para edicao');

my $edicao = $t->tx->res->dom('html body ul li a')->first->attrs('href');

ok $edicao, 'URL para edicao';

$t->get_ok($edicao)->status_is(200)->text_is('html body h1' => 'Editar Seção', 'Formulario de Edicao');

my $dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
	salvar => 'salvar',
	};

ok $dados->{id}, 'Id do registro';
is $dados->{nome}, 'Dummy', 'Id do registro';

$dados->{nome} = 'New Dummy';

$t->post_form_ok('/compras/secao/salvar' => $dados);
$t->status_is(200)->content_like(qr/Registro atualizado/, 'Confirmar Primeira edicao');

$t->get_ok('/compras/secao')->status_is(200)->text_is('html body ul li a' => 'New Dummy', 'Link para edicao');

delete $dados->{salvar};
$dados->{excluir} = 'excluir';

$t->post_form_ok('/compras/secao/salvar' => $dados);
$t->status_is(200)->content_like(qr/Confirma exclusão da seção/, 'Confirmacao do usuario para Primeira exclusao');

my $exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attrs('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/, 'Confirmar Primeira exclusao');

## Cadastrar tres secoes. 
foreach my $nome ('A', 'B', 'C') {
	$t->post_form_ok('/compras/secao/salvar' => {id => '', nome => "Secao $nome", salvar => 'salvar'});
	$t->status_is(200)->content_like(qr/Registro incluido/, "Criar Secao $nome");
}

$t->get_ok('/compras/secao')->status_is(200);
my @registros = ();
$t->tx->res->dom('html body ul li a')->each(sub {
		push @registros, $_->attrs('href');
	});

is scalar(@registros), 3, 'Confirmar quantidade de registros';

# Alterar o nome de todas acrescentando o nominal.
my $i = 0;
my @confirmar = ();
foreach $edicao (@registros) {
	$i++;
	$t->get_ok($edicao)->status_is(200)->text_is('html body h1' => 'Editar Seção');

	my $dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
		nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
		salvar => 'salvar',
		};

	$dados->{nome} .= " $i";
	push @confirmar, $dados->{nome};

	$t->post_form_ok('/compras/secao/salvar' => $dados);
	$t->status_is(200)->content_like(qr/Registro atualizado/);	
}

$t->get_ok('/compras/secao')->status_is(200);
foreach $i (0..$#registros) {
	$t->text_is('html body ul li a[href="' . $registros[$i] . '"]', $confirmar[$i]); 
}

## Excluir a segunda.
$t->get_ok($registros[1])->status_is(200)->text_is('html body h1' => 'Editar Seção');

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
	excluir => 'excluir',
	};

$t->post_form_ok('/compras/secao/salvar' => $dados);
$t->status_is(200)->content_like(qr/Confirma exclusão da seção/);

$exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attrs('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/);

$t->get_ok('/compras/secao')->status_is(200);
foreach $i (0, 2) {
	$t->text_is('html body ul li a[href="' . $registros[$i] . '"]', $confirmar[$i]); 
}

is $t->tx->res->dom('html body ul li a')->size, 2;

## Excluir a ultima.
$t->get_ok($registros[2])->status_is(200)->text_is('html body h1' => 'Editar Seção');

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
	excluir => 'excluir',
	};

$t->post_form_ok('/compras/secao/salvar' => $dados);
$t->status_is(200)->content_like(qr/Confirma exclusão da seção/);

$exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attrs('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/);

$t->get_ok('/compras/secao')->status_is(200);
$t->text_is('html body ul li a[href="' . $registros[0] . '"]', $confirmar[0]); 

is $t->tx->res->dom('html body ul li a')->size, 1;

## Excluir a unica.
$t->get_ok($registros[0])->status_is(200)->text_is('html body h1' => 'Editar Seção');

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
	excluir => 'excluir',
	};

$t->post_form_ok('/compras/secao/salvar' => $dados);
$t->status_is(200)->content_like(qr/Confirma exclusão da seção/);

$exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attrs('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/);

$t->get_ok('/compras/secao')->status_is(200)->text_is('html body h2' => 'Nenhuma seção cadastrada');

## Cadastrar as secoes do arquivo 'produtos.txt'.
open my $arquivo, "<", dirname(__FILE__) . "/produtos.txt"
	or fail("Carregar arquivo de produtos");

$i = 0;
while (<$arquivo>) {
	if (/:: (.+)/) {
		$t->post_form_ok('/compras/secao/salvar' => {id => '', nome => $1, salvar => 'salvar'});
		$t->status_is(200)->content_like(qr/Registro incluido/);
		$i++;
	}
}

close $arquivo;

$t->get_ok('/compras/secao')->status_is(200);
is $t->tx->res->dom('html body ul li a')->size, $i, "Inclusao em lote do arquivo";

## editar secao que nao existe
$t->get_ok('/compras/secao/editar/99999')->status_is(200)->text_is('html body h1' => 'Nova Seção');

$t->post_form_ok('/compras/secao/salvar' => {id => 99999, nome => 'Dummy', salvar => 'salvar'});
$t->status_is(200)->text_is('html body h2' => 'Seção não encontrada');

$t->post_form_ok('/compras/secao/salvar' => {id => 99999, salvar => 'salvar'});
$t->status_is(200)->text_is('html body h2' => 'Nome não informado');

# excluir secao que nao existe
$t->get_ok('/compras/secao/excluir/99999')->status_is(200)->text_is('html body h2' => 'Seção não encontrada');

use Mojo::Base -strict;

use Test::More tests => 323;
use Test::Mojo;

use File::Basename 'dirname';

use utf8;

use_ok 'Compras';

## Funcao para fazer parse na lista de secoes
sub ParseComboSecoes {
	# todo Utilizar combo como origem
	my $dom = shift;
	my @retorno = ();
	$dom->at('html > body > section > form > select[name="secao"]')->find('option')->each(sub {
			push @retorno, {id => $_->attr('value'),
				nome => $_->text};
		});
	return @retorno;
}

## Funcao para fazer parse na lista de produtos
sub ParseListaProdutos {
	my $dom = shift;
	my @retorno = ();
	$dom->find('html > body > section > ul > li')->each(sub {
		my $link = $_->at('a[href^="/compras/secao/editar/"]');
		if ($link && $link->attr('href') =~ m|/secao/editar/(\d+)|) {
			my $secao = {id => $1,
				nome => $link->text,
				link => $link->attr('href'),
				produtos => []};
			$_->find('ul > li > a')->each(sub {
				if ($_->attr('href') =~ m|/produto/editar/(\d+)|) {
					push @{$secao->{produtos}}, {id => $1,
						nome => $_->text,
						link => $_->attr('href')};
				}
			});
			push @retorno, $secao;
		}
	});
	return @retorno;
}

my $t = Test::Mojo->new('Compras');

## Cadastrar secao dummy
$t->post_ok('/compras/secao/salvar' => form => {id => '', nome => 'Dummy', salvar => 'salvar'});
$t->status_is(200)->content_like(qr/Registro incluido/, 'Confirmar Primeira Secao');

## Criar produto a partir do link do menu
$t->get_ok('/compras/produto/editar')->status_is(200)->element_exists('html body form', 'Formulario para inclusao');

my $id_secao_dummy = undef;

my @secoes = ParseComboSecoes($t->tx->res->dom);
foreach my $secao (@secoes) {
	if ($secao->{nome} eq 'Dummy') {
		$id_secao_dummy = $secao->{id};
		last;
	}
}

ok $id_secao_dummy, 'ID da secao Dummy';

$t->post_ok('/compras/produto/salvar' => form => {id => '', nome => 'Dummy', secao => $id_secao_dummy, salvar => 'salvar'});
$t->status_is(200)->content_like(qr/Registro incluido/, 'Confirmar Primeiro Produto');

$t->get_ok('/compras/produto')->status_is(200);

my $id_produto_dummy = undef;

foreach my $secao (ParseListaProdutos($t->tx->res->dom)) {
	if ($secao->{id} == $id_secao_dummy) {
		foreach my $produto (@{$secao->{produtos}}) {
			if ($produto->{nome} eq 'Dummy') {
				$id_produto_dummy = $produto->{id};
			}
		}
		last;
	}
}

ok $id_produto_dummy, 'Produto Dummy';

## Alterar nome do produto

$t->get_ok("/compras/produto/editar/$id_produto_dummy")->status_is(200)->text_is('html body h1' => 'Editar Produto', 'Formulario de Edicao');

my $dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attr('value'),
	secao => $t->tx->res->dom('form select[name="secao"]')->first->at('option[selected]')->attr('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attr('value'),
	salvar => 'salvar',
	};

ok $dados->{id}, 'Id do registro';
is $dados->{secao}, $id_secao_dummy, 'Id da secao';
is $dados->{nome}, 'Dummy', 'Id do registro';

$dados->{nome} = 'New Dummy';

$t->post_ok('/compras/produto/salvar' => form => $dados);
$t->status_is(200)->content_like(qr/Registro atualizado/, 'Confirmar Primeira edicao');

$t->get_ok('/compras/produto')->status_is(200);

my $achou = undef;
foreach my $secao (ParseListaProdutos($t->tx->res->dom)) {
	if ($secao->{id} == $id_secao_dummy) {
		foreach my $produto (@{$secao->{produtos}}) {
			if ($produto->{id} == $id_produto_dummy && $produto->{nome} eq 'New Dummy') {
				$achou = 1;
			}
		}
		last;
	}
}

ok $achou, 'Alterar nome do produto';

## Trocar secao do produto
$t->post_ok('/compras/secao/salvar' => form => {id => '', nome => 'Dummy Nova', salvar => 'salvar'});
$t->status_is(200)->content_like(qr/Registro incluido/, 'Confirmar Segunda Secao');

$t->get_ok("/compras/produto/editar/$id_produto_dummy")->status_is(200)->text_is('html body h1' => 'Editar Produto', 'Formulario de Edicao');

my $id_secao_dummy_nova = undef;

foreach my $secao (ParseComboSecoes($t->tx->res->dom)) {
	if ($secao->{nome} eq 'Dummy Nova') {
		$id_secao_dummy_nova = $secao->{id};
		last;
	}
}

ok $id_secao_dummy_nova, 'Segunda secao';

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attr('value'),
	secao => $id_secao_dummy_nova,
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attr('value'),
	salvar => 'salvar',
	};

$t->post_ok('/compras/produto/salvar' => form => $dados);
$t->status_is(200)->content_like(qr/Registro atualizado/, 'Confirmar Primeira edicao');

$t->get_ok('/compras/produto')->status_is(200);

$achou = undef;
foreach my $secao (ParseListaProdutos($t->tx->res->dom)) {
	if ($secao->{id} == $id_secao_dummy_nova) {
		foreach my $produto (@{$secao->{produtos}}) {
			if ($produto->{id} == $id_produto_dummy) {
				$achou = 1;
			}
		}
		last;
	}
}

ok $achou, 'Alterar secao do produto';

## excluir produto
$t->get_ok("/compras/produto/editar/$id_produto_dummy")->status_is(200)->text_is('html body h1' => 'Editar Produto', 'Formulario de Edicao');

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attr('value'),
	secao => $t->tx->res->dom('form select[name="secao"]')->first->at('option[selected]')->attr('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attr('value'),
	salvar => 'salvar',
	};

delete $dados->{salvar};
$dados->{excluir} = 'excluir';

$t->post_ok('/compras/produto/salvar' => form => $dados);

$t->status_is(200)->content_like(qr/Confirma exclusão do produto/, 'Confirmacao do usuario para Primeiro produto');

my $exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attr('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/, 'Confirmar Primeira exclusao');

# excluir secoes dummy
$t->get_ok("/compras/secao/excluir/$id_secao_dummy")->status_is(200)->content_like(qr/Registro excluido/, 'Excluir secao Dummy');
$t->get_ok("/compras/secao/excluir/$id_secao_dummy_nova")->status_is(200)->content_like(qr/Registro excluido/, 'Excluir secao Dummy Nova');

## Cadastrar as produtos do arquivo 'produtos.txt'.
open my $arquivo, "<", dirname(__FILE__) . "/produtos.txt"
	or fail("Carregar arquivo de produtos");

my $i = 0;
my $secao_atual = undef;
while (<$arquivo>) {
	if (/:: (.+)/) {
		$secao_atual = undef;
		foreach my $secao (@secoes) {
			if ($secao->{nome} eq $1) {
				$secao_atual = $secao->{id};
				last;
			}
		}
		ok $secao_atual, 'Procurar secao ' . $1;
	} elsif (/^([^ :]{2}.+)/) {
		if ($secao_atual) {
			$t->post_ok('/compras/produto/salvar' => form => {id => '', secao => $secao_atual, nome => $1, salvar => 'salvar'});
			$t->status_is(200)->content_like(qr/Registro incluido/);
			$i++;
		} else {
			fail("Secao nao castradata para produto $1");
		}
	} 
}

close $arquivo;

$t->get_ok('/compras/produto')->status_is(200);

my $produtos = 0;
foreach my $secao (ParseListaProdutos($t->tx->res->dom)) {
	foreach my $produto (@{$secao->{produtos}}) {
		$produtos++;
	}
}
is $produtos, $i, "Inclusao em lote do arquivo";

## editar produto que nao existe
$t->get_ok('/compras/produto/editar/99999')->status_is(200)->text_is('html body h1' => 'Novo Produto');

$t->post_ok('/compras/produto/salvar' => form => {id => 99999, nome => 'Dummy', salvar => 'salvar'});
$t->status_is(200)->text_is('html body h2' => 'Produto não encontrado');

$t->post_ok('/compras/produto/salvar' => form => {id => 99999, salvar => 'salvar'});
$t->status_is(200)->text_is('html body h2' => 'Nome não informado');

# excluir produto que nao existe
$t->get_ok('/compras/produto/excluir/99999')->status_is(200)->text_is('html body h2' => 'Produto não encontrado');

use Mojo::Base -strict;

use Test::More tests => 97;
use Test::Mojo;

use File::Basename 'dirname';

use utf8;

use_ok 'Compras';

## Funcao para fazer parse na lista de produtos
sub ParseListaProdutos {
	my $dom = shift;
	my @retorno = ();
	$dom->find('html > body > form > ul > li')->each(sub {
		$_->find('ul > li')->each(sub {
			my $nome = $_->text;
			my $produto = $_->at('input[name="produto"]');
			if ($produto && $_->children->size == 2) {
				my $id = $produto->attrs('value');
				my $checked = $produto->attrs('checked') ? 1 : 0;
				my $observacao = $_->at('input[name="observacao_' . $id . '"]')->attrs('value');
				push @retorno, {id => $id,
					nome => $nome,
					checked => $checked,
					observacao => $observacao};
			}
		});
	});
	return @retorno;
}

## Funcao para fazer parse na lista de 'listas'
sub ParseListaListas {
	my $dom = shift;
	my @retorno = ();
	$dom->find('html > body > ul > li > a')->each(sub {
		if ($_->attrs('href') =~ m|/lista/editar/(\d+)|) {
			push @retorno, {id => $1,
				nome => substr($_->text, 13),
				link => $_->attrs('href')};
		}
	});
	return @retorno;
}

my $t = Test::Mojo->new('Compras');

$t->get_ok('/compras/lista/editar')->status_is(200)->element_exists('html body form', 'Formulario para inclusao');

my @produtos = ParseListaProdutos($t->tx->res->dom);

## criar lista com cinco produtos
my @produtos_sel = map {$produtos[$_]->{id}} (0, 3, 5, 7, 11);

my $dados = {id => '', 
	produto => [@produtos_sel], 
	nome => 'Lista Dummy', 
	salvar => 'salvar'};

map {$dados->{'observacao_' . $_} = 'Obs ' . $_} @produtos_sel[1..2];

$t->post_form_ok('/compras/lista/salvar' => $dados);
$t->status_is(200)->content_like(qr/Registro incluido/, 'Confirmar Primeira Lista');

$t->get_ok('/compras/lista')->status_is(200);
my $id_lista_dummy = undef;
foreach my $lista (ParseListaListas($t->tx->res->dom)) {
	if ($lista->{nome} eq 'Lista Dummy') {
		$id_lista_dummy = $lista->{id};
		last;
	}
}

ok $id_lista_dummy, 'Buscar Lista';

$t->get_ok("/compras/lista/editar/$id_lista_dummy")->status_is(200)->text_is('html body h1' => 'Editar Lista', 'Formulario de Edicao');

@produtos = ParseListaProdutos($t->tx->res->dom);

for my $i (0..4) {
	my $achou = 0;
	foreach my $produto (@produtos) {
		if ($produto->{id} == $produtos_sel[$i]) {
			$achou = $produto->{checked};

			if ($i == 1 || $i == 2) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			}

			last;
		}
	}
	ok $achou, 'Confirmacao de inclusao ' . $i;
}

foreach my $produto (@produtos) {
	if ($produto->{checked}) {
		my $achou = 0;
		foreach my $id (@produtos_sel) {
			if ($produto->{id} == $id) {
				$achou = 1;
				last;
			}
		}
		ok $achou, 'Confirmacao de inclusao ' . $produto->{nome};
		if ($produto->{observacao} ne '') {
			if ($produto->{id} == $produtos_sel[1] || $produto->{id} == $produtos_sel[2]) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			} else {
				fail 'Confirmacao de inclusao';
			}
		}
	}
}

## alterar lista
foreach my $produto (@produtos) {
	unless ($produto->{checked}) {
		push @produtos_sel, $produto->{id};
		last;
	}
}

shift @produtos_sel;

$dados = {id => $id_lista_dummy, 
	produto => [@produtos_sel], 
	nome => 'Lista Dummy Nova', 
	salvar => 'salvar'};

map {$dados->{'observacao_' . $_} = 'Obs ' . $_} @produtos_sel[1..2];

$t->post_form_ok('/compras/lista/salvar' => $dados);
$t->status_is(200)->content_like(qr/Registro atualizado/, 'Confirmar alterar Lista');

$t->get_ok('/compras/lista')->status_is(200);
my $achou = undef;
foreach my $lista (ParseListaListas($t->tx->res->dom)) {
	if ($id_lista_dummy == $lista->{id} && $lista->{nome} eq 'Lista Dummy Nova') {
		$achou = 1;
		last;
	}
}
ok $achou, 'Alterar nome lista';

$t->get_ok("/compras/lista/editar/$id_lista_dummy")->status_is(200)->text_is('html body h1' => 'Editar Lista', 'Formulario de Edicao');

@produtos = ParseListaProdutos($t->tx->res->dom);

for my $i (0..4) {
	my $achou = 0;
	foreach my $produto (@produtos) {
		if ($produto->{id} == $produtos_sel[$i]) {
			$achou = $produto->{checked};

			if ($i == 1 || $i == 2) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			}

			last;
		}
	}
	ok $achou, 'Confirmacao de alteracao';
}

foreach my $produto (@produtos) {
	if ($produto->{checked}) {
		my $achou = 0;
		foreach my $id (@produtos_sel) {
			if ($produto->{id} == $id) {
				$achou = 1;
				last;
			}
		}
		ok $achou, 'Confirmacao de alteracao';
		if ($produto->{observacao} ne '') {
			if ($produto->{id} == $produtos_sel[1] || $produto->{id} == $produtos_sel[2]) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			} else {
				fail 'Confirmacao de alteracao';
			}
		}
	}
}

## copiar lista
$t->get_ok("/compras/lista/editar/$id_lista_dummy")->status_is(200)->text_is('html body h1' => 'Editar Lista', 'Formulario de Edicao');

my $copiar = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Copiar';
	})->attrs('href');

ok $copiar, 'Link para copiar';

$t->get_ok($copiar)->status_is(200)->text_is('html body h1' => 'Nova Lista', 'Formulario para copia');
	
is $t->tx->res->dom('form input[name="id"]')->first->attrs('value'), '', 'Id em branco';

@produtos = ParseListaProdutos($t->tx->res->dom);

for my $i (0..4) {
	my $achou = 0;
	foreach my $produto (@produtos) {
		if ($produto->{id} == $produtos_sel[$i]) {
			$achou = $produto->{checked};

			if ($i == 1 || $i == 2) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			}

			last;
		}
	}
	ok $achou, 'Confirmacao de copia';
}

foreach my $produto (@produtos) {
	if ($produto->{checked}) {
		my $achou = 0;
		foreach my $id (@produtos_sel) {
			if ($produto->{id} == $id) {
				$achou = 1;
				last;
			}
		}
		ok $achou, 'Confirmacao de copia';
		if ($produto->{observacao} ne '') {
			if ($produto->{id} == $produtos_sel[1] || $produto->{id} == $produtos_sel[2]) {
				is $produto->{observacao}, 'Obs ' . $produto->{id}, 'Observacao';
			} else {
				fail 'Confirmacao de copia';
			}
		}
	}
}

# exportar arquivo
$t->get_ok("/compras/lista/editar/$id_lista_dummy")->status_is(200);

my $exportar = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Exportar';
	})->attrs('href');

ok $exportar, 'Link para exportar';

$t->get_ok($exportar)->status_is(200)->header_like('Content-Disposition' => qr/attachment/, 'Download arquivo');

if ($t->tx->res->headers->content_disposition =~ /filename="([^"]+)"/) {
	$exportar = "/tmp/$1";
	unlink $exportar if (-f $exportar);
	$t->tx->res->content->asset->move_to($exportar);
	my @procurar = ();
	foreach my $produto (@produtos) {
		if ($produto->{checked}) {
			push @procurar, $produto->{nome} . ($produto->{observacao} eq '' ? '' : ' - ' . $produto->{observacao});
		}
	}	
	
	open my $arquivo, '<:utf8', $exportar or fail "Abrir arquivo para leitura";
	while (my $linha = <$arquivo>) {
		chomp $linha;
		my $achou = 0;
		for my $i (0..4) {
			if ($linha eq $procurar[$i]) {
				$achou = 1;
				$procurar[$i] = 'achou';
				last;
			}
		}
		ok $achou, 'Linha do arquivo selecionada "' . $linha . '"';
	}
	close $arquivo;
	foreach my $linha (@procurar) {
		is $linha, 'achou', 'Linha no arquivo';
	}
}

## excluir lista
$t->get_ok("/compras/lista/editar/$id_lista_dummy")->status_is(200)->text_is('html body h1' => 'Editar Lista', 'Formulario de Edicao');

$dados = {id => $t->tx->res->dom('form input[name="id"]')->first->attrs('value'),
	nome => $t->tx->res->dom('form input[name="nome"]')->first->attrs('value'),
	excluir => 'excluir'
	};

$t->post_form_ok('/compras/lista/salvar' => $dados);

$t->status_is(200)->content_like(qr/Confirma exclusão da lista/, 'Confirmacao do usuario para excluir lista');

my $exclusao = $t->tx->res->dom('html body a')->first(sub {
		$_->text eq 'Sim';
	})->attrs('href');

$t->get_ok($exclusao)->status_is(200)->content_like(qr/Registro excluido/, 'Confirmar Primeira exclusao');

use Mojo::Base -strict;
use Test::More tests => 1;

BEGIN {
    BAIL_OUT('Variavel de ambiente CAMINHO_BANCO nao informada') unless (defined($ENV{CAMINHO_BANCO}));
}

if (-f $ENV{CAMINHO_BANCO}) {
	ok unlink($ENV{CAMINHO_BANCO}), "Limpeza do arquivo do banco: $ENV{CAMINHO_BANCO}";
} else {
	pass "Limpeza do arquivo do banco: $ENV{CAMINHO_BANCO}";
}

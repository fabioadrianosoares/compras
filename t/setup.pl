#! /usr/bin/perl

BEGIN {
	# $ENV{CAMINHO_BANCO}, '/home/fabio/desktop/sistemas/compras/fontes/db/banco.sqlite3';
	push @INC, '/home/fabio/desktop/sistemas/compras/fontes/lib';
}

use Compras::Model;
use utf8;

open my $arquivo, "<", "produtos.txt"
	or die "Falha ao abrir arquivo com produtos.";
	
my $secao = undef;

while (my $linha = <$arquivo>) {
	utf8::decode($linha);
	chomp $linha;
	if ($linha =~ /^:: *(.+)/) {
		print "incluir secao $1\n";
		$secao = Compras::Model::Secao->create(nome => $1);
	} elsif ($linha =~ /.../ && $secao) {
		print "incluir produto $linha\n";
		Compras::Model::Produto->create(secao => $secao->id, nome => $linha);
	}
}

close $linha;

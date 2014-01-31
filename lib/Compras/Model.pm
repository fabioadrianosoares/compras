package Compras::Model;

use Mojo::Base -strict;
use utf8;

BEGIN {
	die "Variavel de ambiente CAMINHO_BANCO nao informada" unless (defined($ENV{CAMINHO_BANCO}));
}

use ORLitex {
	file => $ENV{CAMINHO_BANCO},
	create => sub {
		my $dbh = shift;

		$dbh->do('CREATE TABLE secao (
			id integer not null primary key AUTOINCREMENT,
			nome text not null
		)');

		$dbh->do('CREATE TABLE produto (
			id integer not null primary key AUTOINCREMENT, 
			secao integer not null,
			nome text not null
		)');

		$dbh->do('CREATE TABLE lista (
			id integer not null primary key AUTOINCREMENT,
			data integer not null,
			nome text not null
		)');

		$dbh->do('CREATE TABLE item_lista (
			id integer not null primary key AUTOINCREMENT,
			lista integer not null,
			produto integer not null,
			observacao text null
		)');
		
		$dbh->do('PRAGMA user_version = 1');
	},
	user_version => 1
};

package Compras::Model::Secao;

sub buscar_por_id {
	shift;
	my $id = shift;
	shift @{__PACKAGE__->select('where id = ?', $id)};
}

package Compras::Model::Produto;

sub buscar_por_id {
	shift;
	my $id = shift;
	shift @{__PACKAGE__->select('where id = ?', $id)};
}

sub buscar_por_secao {
	shift;
	my $secao = shift;
	@{__PACKAGE__->select('where secao = ? order by nome asc', $secao)};
}

package Compras::Model::Lista;

sub buscar_por_id {
	shift;
	my $id = shift;
	shift @{__PACKAGE__->select('where id = ?', $id)};
}

sub data_dmy {
	my $data = (shift)->data;
	if ($data =~ /(\d{4})(\d{2})(\d{2})/) {
		"$3/$2/$1";
	} else {
		"";
	}	
}

sub secoes {
	my $self = shift;
	unless (exists $self->{secoes}) {
		my @itens_lista = Compras::Model::ItemLista->select('where lista = ?', $self->id);
		my @secoes = Compras::Model::Secao->select('order by nome asc');
		foreach (@secoes) {
			my @produtos = Compras::Model::Produto->buscar_por_secao($_->id);
			foreach my $produto (@produtos) {
				$produto->{selecionado} = 0;
				$produto->{observacao} = '';
				foreach (@itens_lista) {
					if ($produto->id == $_->produto) {
						$produto->{selecionado} = 1;
						$produto->{observacao} = $_->observacao;
						last;
					}
				}
			}
			$_->{produtos} = [@produtos];
		}
		$self->{secoes} = \@secoes;
	}
	return @{$self->{secoes}}; 
}

# 				<li><%= check_box produto => $_->id, %checked %><%= $_->nome %> <%= text_field 'observacao_' . $_->id => $_->observacao %></li>

1;

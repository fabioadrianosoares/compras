package Compras::Lista;
use Mojo::Base 'Mojolicious::Controller';
use utf8;
use Date::Simple qw(today);

sub listar {
	my $self = shift;
	
	my $listas = Compras::Model::Lista->select('order by nome asc');
	
	$self->render(listas => $listas);
}

sub editar {
  my $self = shift;

  my $id = $self->stash('id');
  
  my $lista = undef;
  
  unless ($id && defined($lista = Compras::Model::Lista->buscar_por_id($id))) {
		$lista = Compras::Model::Lista->new(data => today()->as_d8);
	}
  
  $self->stash(novo => ($lista->id ? 0 : 1),
		lista => $lista, 
		copiar => 0);
  
}

sub copiar {
  my $self = shift;

  my $lista = Compras::Model::Lista->buscar_por_id($self->stash('id'));
  
  $self->stash(novo => 1,
		lista => $lista, 
		copiar => 1);
}

sub salvar {
  my $self = shift;

  my $id = $self->param('id');
  my $nome = $self->param('nome');
  my $lista = undef;
  
  unless ($nome =~ /\w+/) {
    $self->render(mensagem => 'Nome nao informado');
    return;
  }

  utf8::decode($nome);
  
  if ($id) {
 
    $lista = Compras::Model::Lista->buscar_por_id($id);
    
    unless ($lista) {
      $self->render(mensagem => 'Lista não encontrada');
      return;
    }
    
    if ($self->param('excluir')) {
      $self->render(template => 'lista/confirmar_exclusao', 
            id => $lista->id,
            nome => $lista->nome);
      return;
    }
        
    unless ($lista->update(nome => $nome)) {
      $self->render(mensagem => 'Falha ao atualizar lista');
      return;
    }
  } else {
    $lista = Compras::Model::Lista->create(nome => $nome, data => today()->as_d8);
    
    unless ($lista) {
      $self->render(mensagem => 'Falha ao incluir lista');
      return;
    }
  }
  
  Compras::Model::ItemLista->delete_where('lista = ?', $lista->id);

  foreach my $produto (@{$self->every_param('produto')}) {
    my $observacao = $self->param('observacao_' . $produto) || '';
    utf8::decode($observacao);
    Compras::Model::ItemLista->create(
      lista => $lista->id,
      produto => $produto,
      observacao => $observacao
    );
  }
  
  $self->render(mensagem => 'Registro ' . ($id ? 'atualizado' : 'incluido'));

}

sub excluir {
  my $self = shift;

  my $id = $self->stash('id');

  my $lista = Compras::Model::Lista->buscar_por_id($id);
  
  unless ($lista) {
    $self->render(mensagem => 'Lista não encontrada');
    return;
  }

  Compras::Model::ItemLista->delete_where('lista = ?', $lista->id);
  
  unless ($lista->delete()) {
    $self->render(mensagem => 'Falha ao excluir lista');
    return;
  }
  
  $self->render(mensagem => 'Registro excluido');

}

sub exportar {
  my $self = shift;

  my $id = $self->stash('id');

  my $lista = Compras::Model::Lista->buscar_por_id($id);
  
  unless ($lista) {
    $self->render(mensagem => 'Lista não encontrada', template => 'mensagem', title => 'Exportar');
    return;
  }

  $self->res->headers->add('Content-Type', 'text/plain');
  $self->res->headers->add('Content-Disposition', 'attachment; filename="' . $lista->data . '_' . $lista->nome . '.txt"');

  $self->res->headers->add('Cache-Control', 'private');
  $self->res->headers->add('Pragma', 'private');
  $self->res->headers->add('Expires', 'Mon, 26 Jul 1997 05:00:00 GMT');  
  
  $self->render(lista => $lista);
}

1;

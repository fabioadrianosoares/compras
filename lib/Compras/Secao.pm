package Compras::Secao;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

sub listar {
  my $self = shift;
  
	my $secoes = Compras::Model::Secao->select('order by nome asc');
	
	$self->render(secoes => $secoes);
}

sub editar {
  my $self = shift;

  my $id = $self->stash('id');
  
  my $secao = undef;
  
  unless ($id && defined($secao = Compras::Model::Secao->buscar_por_id($id))) {
		$secao = Compras::Model::Secao->new();
	}

	my @produtos = Compras::Model::Produto->buscar_por_secao($secao->id);
	
	$self->render(novo => ($secao->id ? 0 : 1),
		secao => $secao,
		produtos => \@produtos);
  
}

sub salvar {
  my $self = shift;

  my $id = $self->param('id');
  my $nome = $self->param('nome');
  my $secao = undef;
  
  unless (defined($nome) && $nome =~ /\w+/) {
    $self->render(mensagem => 'Nome não informado');
    return;
  }

  utf8::decode($nome);
  
  if ($id) {
 
    $secao = Compras::Model::Secao->buscar_por_id($id);
    
    unless ($secao) {
      $self->render(mensagem => 'Seção não encontrada');
      return;
    }
    
    if ($self->param('excluir')) {
      $self->render(template => 'secao/confirmar_exclusao', 
            id => $secao->id,
            nome => $secao->nome);
      return;
    }
        
    unless ($secao->update(nome => $nome)) {
      $self->render(mensagem => 'Falha ao atualizar seção');
      return;
    }
  } else {
    $secao = Compras::Model::Secao->create(nome => $nome);
    
    unless ($secao) {
      $self->render(mensagem => 'Falha ao incluir seção');
      return;
    }
  }
  
  $self->render(mensagem => 'Registro ' . ($id ? 'atualizado' : 'incluido'));
  
}

sub excluir {
  my $self = shift;

  my $id = $self->stash('id');

  my $secao = Compras::Model::Secao->buscar_por_id($id);
  
  unless ($secao) {
    $self->render(mensagem => 'Seção não encontrada');
    return;
  }
  
  unless ($secao->delete()) {
    $self->render(mensagem => 'Falha ao excluir seção');
    return;
  }
  
  $self->render(mensagem => 'Registro excluido');

}

1;

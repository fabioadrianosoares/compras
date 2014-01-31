package Compras::Produto;
use Mojo::Base 'Mojolicious::Controller';
use utf8;

sub listar {
	my $self = shift;
	
	my $secoes = Compras::Model::Secao->select('order by nome asc');
	
	my $existe_produto = 0;
	foreach (@{$secoes}) {
		$_->{produtos} = [Compras::Model::Produto->buscar_por_secao($_->id)];
		$existe_produto = 1 if (!$existe_produto && scalar(@{$_->{produtos}}));
	}
	$secoes = [] unless ($existe_produto);
	
	$self->render(secoes => $secoes);
}

sub editar {
  my $self = shift;

  my $id = $self->stash('id');
  my $secao = $self->param('secao') // 0;
  my $secoes = Compras::Model::Secao->select('order by nome asc');
  
  my $produto = undef;
  
  unless ($id && defined($produto = Compras::Model::Produto->buscar_por_id($id))) {
		$produto = Compras::Model::Produto->new(secao => $secao);
	}
  
  $self->stash(novo => ($produto->id ? 0 : 1),
		produto => $produto,
		secoes => $secoes);
  
}

sub salvar {
  my $self = shift;

  my $id = $self->param('id');
  my $nome = $self->param('nome');
  my $secao = $self->param('secao');
  my $produto = undef;
  
  unless (defined($nome) && $nome =~ /\w+/) {
    $self->render(mensagem => 'Nome não informado');
    return;
  }

  utf8::decode($nome);

  if ($id) {
 
    $produto = Compras::Model::Produto->buscar_por_id($id);
    
    unless ($produto) {
      $self->render(mensagem => 'Produto não encontrado');
      return;
    }
    
    if ($self->param('excluir')) {
      $self->render(template => 'produto/confirmar_exclusao', 
            id => $produto->id,
            nome => $produto->nome);
      return;
    }
        
    unless ($produto->update(secao => $secao, nome => $nome)) {
      $self->render(mensagem => 'Falha ao atualizar produto');
      return;
    }
  } else {
    $produto = Compras::Model::Produto->create(secao => $secao, nome => $nome);
    
    unless ($produto) {
      $self->render(mensagem => 'Falha ao incluir produto');
      return;
    }
    
    $self->render(template => 'produto/incluir', mensagem => 'Registro incluido', secao => $secao);
    return;
  }
  
  $self->render(mensagem => 'Registro ' . ($id ? 'atualizado' : 'incluido'));
  
}

sub excluir {
  my $self = shift;

  my $id = $self->stash('id');

  my $produto = Compras::Model::Produto->buscar_por_id($id);
  
  unless ($produto) {
    $self->render(mensagem => 'Produto não encontrado');
    return;
  }
  
  unless ($produto->delete()) {
    $self->render(mensagem => 'Falha ao excluir produto');
    return;
  }
  
  $self->render(mensagem => 'Registro excluido');

}

1;

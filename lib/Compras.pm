package Compras;
use Mojo::Base 'Mojolicious';
use Compras::Model;
use utf8;

# This method will run once at server start
sub startup {
  my $self = shift;
  
  $self->secret('em buraco de tatu');
  
	if (($ENV{MOJO_MODE} // '') ne 'production') {
		# Documentation browser under "/perldoc"
		$self->plugin('PODRenderer');
	}
  $self->plugin('DataHelper');

  # Routes
  my $r = $self->routes->route('/compras');
  
  my $secao = $r->route('/secao')->to('secao#listar');
  $secao->route('/')->to(title=> 'Seção');
  $secao->route('/editar/:id', id => qr/\d+/)->via('GET')->name('secao_editar')->to('#editar', id => 0);
  $secao->route('/salvar')->via('POST')->name('secao_salvar')->to('#salvar', template => 'mensagem');
  $secao->route('/excluir/:id', id => qr/\d+/)->name('secao_excluir')->to('#excluir', template => 'mensagem', title => 'Excluir');

  my $produto = $r->route('/produto')->to('produto#listar');
  $produto->route('/')->to(title => 'Produto');
  $produto->route('/editar/:id', id => qr/\d+/)->via('GET')->name('produto_editar')->to('#editar', id => 0);
  $produto->route('/salvar')->via('POST')->name('produto_salvar')->to('#salvar', template => 'mensagem');
  $produto->route('/excluir/:id', id => qr/\d+/)->name('produto_excluir')->to('#excluir', template => 'mensagem', title => 'Excluir');

  my $lista = $r->route('/lista')->to('lista#listar');
  $lista->route('/')->to(title => 'Lista');
  $lista->route('/editar/:id', id => qr/\d+/)->via('GET')->name('lista_editar')->to('#editar', id => 0);
  $lista->route('/copiar/:id', id => qr/\d+/)->via('GET')->name('lista_copiar')->to('#copiar', template => 'lista/editar');
  $lista->route('/salvar')->via('POST')->name('lista_salvar')->to('#salvar', template => 'mensagem');
  $lista->route('/excluir/:id', id => qr/\d+/)->name('lista_excluir')->to('#excluir', template => 'mensagem', title => 'Excluir');
  $lista->route('/exportar/:id', id => qr/\d+/)->name('lista_exportar')->to('#exportar');

  $r->route('/')->to(cb => sub {$_[0]->render('inicial/index')});

#	if (($ENV{MOJO_MODE} // '') eq 'production') {
#		$self->hook(before_dispatch => sub {
#			shift->req->url->base(Mojo::URL->new('/compras'));
#		});
#	}
}

1;

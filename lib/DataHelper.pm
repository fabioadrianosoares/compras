package DataHelper;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;

  # Add "config" helper
  $app->helper(data_visual => 
    sub { 
      my $data = $_[1];
      if ($data =~ /(\d{4})(\d{2})(\d{2})/) {
        return "$3/$2/$1";
      } else {
        return "";
      }
    }
  );

}

1;
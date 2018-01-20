package Bakeoff::Command::go;
use Mojo::Base 'Mojolicious::Command';

$|=1;

use Mojo::Util 'getopt';

has description => 'Start Bakeoff';
has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  getopt
    'e|ext=s'    => \(my $ext = 'psv'),
    'f|field=s'  => \(my $field_delim = '|'),
    'r|record=s' => \(my $record_delim = "\r\n"),
    'b|batch=i'  => \(my $batch = 100),
    'n|min=i'    => \my $minid,
    'x|max=i'    => \my $maxid;

  $minid ||= $self->app->source->db->query('select min(id) as minid from a left join b using (id)')->hash->{minid};
  $maxid ||= $self->app->source->db->query('select max(id) as maxid from a left join b using (id)')->hash->{maxid};

  for (my $id = $minid; $id <= $maxid; $id+=$batch) {
    last if $id > $maxid;
    print '.';
    $self->app->minion->enqueue(bakeoff => [$id, $batch, $ext, $field_delim, $record_delim]);
  }
  print "\n";
}

1;

package Manoc::ManifoldRole::SSH;
use Moose::Role;

sub connect {
  my $ssh = Net::OpenSSH->new($host);

}

no Moose::Role;
1:

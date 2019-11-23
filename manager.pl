#! /usr/bin/perl
#
#snmpget
#
#Author: Mora
#

#usamos nuestro modulo creado
use lib "/home/fermi/net-snmp-5.8";
use pc;
use router;

#uso del tiempo en formato POSIX
use Time::Local;
use POSIX qw/strftime/;

##Obtenemos la hora actual
my ($s, $min, $h, $d, $m ,$y) = localtime();
my $time = timelocal $s, $min, $h, $d, $m, $y;
my $mind = strftime "%M", $s, $min+1, $h, $d, $m, $y;

my $op = 1;

while($op >= 1){
 my ($s, $min, $h, $d, $m, $y) = localtime();
 my $min = strftime "%M", $s, $min, $h, $d, $m, $y;
 
 if ($min eq $mind){
  #empieza
  #Actualizamos la info de la pc 
  pc->updat3();

  #Actualiza info de los Routers
  router->updat3();
  $mind = strftime "%M", $s, $min+1, $h, $d, $m, $y;

 }else{
  print "Choose an option\n";
  print " 1- PC \n 2- Routers \n";
  print "Info: ";
  my $info = <STDIN>;
  print "\n-----------------------------\n";
  if ($info == 1){
   print "PC\n";
   pc->showInfo();
  }elsif($info == 2){
   Router->showInfo();
  }else{
   print "Invalid option\n";
  }
 }

 print "Continue?: 1-Y, 0-N: ";
 $op = <STDIN>;
}

print "End\n";

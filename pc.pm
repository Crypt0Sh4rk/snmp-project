#! /usr/bin/perl -w
#
#snmpget
#
#Author: Mora
#

package pc;

#usamos nuestro modulo creado
use lib "/home/fermi/adminSnmp";
use connDB;

use strict;
use warnings;
#uso del tiempo en formato POSIX
use Time::Local;
use POSIX qw/strftime/;

##Obtenemos la hora actual
my ($s, $min, $h, $d, $m, $y) = localtime();

my $time = timelocal $s, $min, $h, $d, $m, $y;
my $today = strftime "%Y-%m-%d", localtime $time;
my $hour = strftime "%H:%M:%S", localtime $time;


#empieza
sub updat3{

#establecemos conexion
my $dbh = connDB->connect();

#arreglo de ips
my @ip_list = ('192.168.100.10','192.168.100.11');

##arreglo de oid's
my @list_oid = ('1.3.6.1.4.1.2021.11.10.0','1.3.6.1.4.1.2021.11.11.0','1.3.6.1.4.1.2021.4.5.0','1.3.6.1.4.1.2021.4.6.0','1.3.6.1.4.1.2021.9.1.6.1','1.3.6.1.4.1.2021.9.1.8.1','1.3.6.1.4.1.2021.9.1.7.1');

my $snmp;

foreach my $ip (@ip_list){
 $snmp -> {$ip}  = new SNMP::Util(-device => $ip, -community => 'public');
}

my @datospc;

foreach my $ip (@ip_list){

 if ( ($snmp -> {$ip} -> ping_check()) eq '1' ) {
  print "Updating $ip info\n";
 }else{
  print "The device with $ip is not available\n";
  next;
 }

 foreach my $oid (@list_oid){
  my @get_values = $snmp -> {$ip} -> get('ontvef',$oid);
  push(@datospc,$get_values[3]);
 }


 #esta parte para insertar datos
 my $memo = $datospc[2] - $datospc[3];

 my $ram_threshold = 90;
 my $cpu_threshold = 30;
 my $disk_threshold = 30;

 if (($memo*100/$datospc[2]) <= $ram_threshold){
  #print "preparando correo\n";
  print "$today $hour\n";
  print "$ip\n";
  print "RAM memory has reached threshold... $memo\n";
 }

 
 if ($datospc[1] <= $cpu_threshold){
  #print "preparando correo\n";
  print "$today $hour\n";
  print "$ip\n";
  print "CPU has reached threshold... $memo\n";
 }

 
 if ($datospc[6] <= $disk_threshold){
  #print "preparando correo\n";
  print "$today $hour\n";
  print "$ip\n";
  print "Disk capacity has reached threshold. Available capacity: $memo\n";
 }

 $dbh->do("insert into computer(fecha,hora,use_proc,free_proc,mem_tot,mem_free,mem_use,RAM_tot,RAM_free,RAM_use,ip) values(".$dbh->quote($today).",".$dbh->quote($hour).",$datospc[0],$datospc[1],$datospc[4],$datospc[6],$datospc[5],$datospc[2],$memo,$datospc[3],".$dbh->quote($ip).")");

 @datospc=();

}

 #Finaliza la base de datos
 $dbh->disconnect();

}

sub showInfo{

#establecemos conexion
my $dbh = connDB->connect();

my @ip_list = ('192.168.100.10');

foreach my $ip (@ip_list){

my $sth = $dbh->prepare("select * from computer where ip = '$ip' order by id_com desc limit 1");
$sth->execute();

my $ref = $sth->fetchrow_hashref();

 print "PC-Linux\n";
 print "ip: $ref->{ip}\n";
 print "Las update: $ref->{fecha} $ref->{hora}\n";
 my $cpu = 100 - $ref->{free_proc};
 print "CPU usage: $cpu\%\n";
# print "Libre de cpu por el sistema: $ref->{free_proc}\n";
# print "Memoria RAM Total: $ref->{RAM_tot}\n";
# print "Memoria RAM usada: $ref->{RAM_use}\n";
 my $ram = $ref->{RAM_free}*100/$ref->{RAM_tot}; 
 printf ("RAM memory available: %.2f",$ram);
 print "%\n";	
# print "Memoria de disco duro total: $ref->{Mem_tot}\n";
# print "Memoria de disco duro usado: $ref->{Mem_use}\n";
 my $disco = $ref->{Mem_free} * 100 / $ref->{Mem_tot};
 printf ("Free space disk: %.2f",$disco);
 print "%\n";	
 #Finaliza la consulta
 $sth->finish();
}

 #Finaliza la base de datos
 $dbh->disconnect();

}

1;

#! /usr/bin/perl
#
#snmpget
#
#Author: Mora
#

package router;

#usamos nuestro modulo creado
use lib "/home/fermi/adminSnmp";
use connDB;

use strict;
use warnings;
##Uso del modulo para snmp
use SNMP::Util;
#uso del tiempo en formato POSIX
use Time::Local;
use POSIX qw/strftime/;

##Obtenemos la hora actual
my ($s, $min, $h, $d, $m, $y) = localtime();

my $time = timelocal $s, $min, $h, $d, $m, $y;
my $today = strftime "%Y-%m-%d", localtime $time;
my $hour = strftime "%H:%M:%S", localtime $time;


sub updat3{

#establecemos conexion
my $dbh = connDB->connect();


#arreglo de ip's
my @IP_array = ('192.168.10.1','192.168.10.2','192.168.10.14','192.168.10.18','192.168.10.6','192.168.10.26');
#arreglo de oids
my @oid_list = ('1.3.6.1.2.1.1.5.0','1.3.6.1.4.1.9.9.48.1.1.1.5.1','1.3.6.1.4.1.9.9.48.1.1.1.6.1','1.3.6.1.2.1.2.1.0');

#Comunidad
my $Comm_string = "public";
my $snmp;

#busca las ip's
foreach my $IP (@IP_array){
 $snmp -> {$IP} = new SNMP::Util(-device => $IP, -community => $Comm_string);
}

#arreglo de datos
my @datos;

#imprime los datos
foreach my $IP (@IP_array){

 if( ($snmp->{$IP}->ping_check()) eq '1'){
   print "Updating $IP info\n";
 }else{
  print "The device $IP is not available.\n";
  next;
 }

 foreach my $oid (@oid_list){
  my @get_values = $snmp -> {$IP} -> get('ontvef',$oid);
  push(@datos,$get_values[3]);
 }

 #inicia insercion de datos en Router
 my $memoria = $datos[1] + $datos[2];
 my $nombre = $datos[0]; 

 my $umbral_cpu = 10;
 my $umbral_ram = 40;

 if ($datos[2] <= $umbral_ram){
  #print "Preparando correo\n";
  print "Date: $today $hour\n";
  print "ip: $IP\n";
  print "RAM memory has reached threshold\n";
 }

 if ($datos[2] <= $umbral_cpu){
  #print "Preparando correo\n";
  print "Date: $today $hour\n";
  print "ip: $IP\n";
  print "CPU usage has reached the threshold\n";
 }


  #calculo del ancho de bando de la interfaz 2
  my $umbral_ancho = 100;
  my $seg = 10;
  my @ifInOctects = $snmp -> {$IP} -> get('ontvef', '1.3.6.1.2.1.2.2.1.10.2');
  my @ifOutOctects = $snmp -> {$IP} -> get('ontvef', '1.3.6.1.2.1.2.2.1.16.2');
  my @ifSpeed = $snmp -> {$IP} -> get('ontvef', '1.3.6.1.2.1.2.2.1.5.2');
  my $input = ($ifInOctects[4]*8*100) / ($seg * $ifSpeed[4]);
  my $output = ($ifOutOctects[4]*8*100) / ($seg * $ifSpeed[4]);


 $dbh -> do("insert into router(fecha,hora,nombre,RAM_tot,RAM_free,RAM_use,Num_int,banda_in,banda_out) values(".$dbh->quote($today).",".$dbh->quote($hour).",".$dbh->quote($datos[0]).",$memoria, $datos[2], $datos[1],$datos[3],$input,$output)");
 
 #inicio las interfaces de cada router 
 my @interface;
 my @elementos;

 for (my $i = 1; $i <= $datos[3]; $i++){
  push(@interface,$i);
  for(my $j = 1; $j <= $datos[3]; $j++){
   push(@elementos,'1.3.6.1.2.1.2.2.1.2.'.$i);
   push(@elementos,'1.3.6.1.2.1.2.2.1.4.'.$i);
   push(@elementos,'1.3.6.1.2.1.2.2.1.3.'.$i);
  }
  foreach my $elemento (@elementos){
   my @get_values = $snmp -> {$IP} -> get('ontvef',$elemento);
   push(@interface,$get_values[4]);
  }

  #inicia insercion de datos en Interface
  #seleccionamos el ultimo dato de la columna id_R de router
  my $sth = $dbh->prepare("select * from Router order by id_r desc");
  $sth->execute();
  my $ref = $sth->fetchrow_arrayref();
  my $sim = $ref->[0];
  $sth->finish();
  
  $dbh -> do("insert into Interface(id_r,Nombre_r,id_int_r,descripcion,tipo,mtu) values($sim,".$dbh->quote($datos[0]).",".$dbh->quote($interface[0]).",".$dbh->quote($interface[1]).",".$dbh->quote($interface[3]).",$interface[2])");
=pod
  print "|  ID:\t $interface[0]\n";
  print "|  Descripcion:\t $interface[1]\n";
  print "|  MTU:\t $interface[2]\n";
  print "|  Tipo:\t $interface[3]\n";
  print "-------------------------------------------\n";
=cut

  @interface = ();
  @elementos = ();
  }

 @datos = ();

}

#Finaliza la base de datos
$dbh->disconnect();

}



sub showInfo{

 #establecemos conexion
 my $dbh = connDB->connect();

 #arreglo de ip's
 my @IP_array = ('10.10.10.13','10.10.10.10','10.10.10.5','10.10.10.2');

 my $tam = @IP_array;
 print "¿Choose your router?\n";
 for(my $i = 1; $i<$tam; $i++){
  print "($i)- Router $i\n";
 }
 print "Option: ";
 my $op = <STDIN>;
 print "\n---------------------------\n";
 chop($op);
 my $nom = "Agent_r$op";
 #hacemos la consulta
 my $sth = $dbh->prepare("select * from router where nombre = '$nom' order by id_r desc limit 1");
 $sth->execute();
 
 my $ref = $sth->fetchrow_hashref();

 print "--------------Router: $ref->{nombre} \n";
 print "|  Last update: $ref->{fecha} $ref->{hora}\n";
 my $ram = $ref->{RAM_free} * 100 / $ref->{RAM_tot};
 printf ("|  RAM memory available:\t %.2f",$ram);
 print "%\n";
# my $cpu = $ref->{use_proc};
# printf ("|  Uso de cpu hace 1 min:\t %.2f",$cpu);
# print "%\n";
 print "|  Bandwidht usage:\t $ref->{banda_in}\n";
 print "%\n";
 print "|  Number of interfaces:\t $ref->{banda_out}\n";
 print "%\n";



 #terminamos
 $sth->finish();
 #desconectamos
 $dbh->disconnect();
}

1;

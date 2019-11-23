#! /usr/bin/perl -w
package connDB;

use strict;
use DBI;

#variables de conexion
my $db_user = "root";
my $db_pass = "toor";
my $host_name = "localhost";
my $db_name = "snmp_project";

#conexion
my $q_string = "DBI:mysql:host=$host_name;database=$db_name";

sub connect{
 return (DBI->connect($q_string,$db_user,$db_pass, {PrintError => 0, RaiseError => 1}))
}

1;

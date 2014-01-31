#! /bin/bash

TIPO=$1;
PROC=`ps -Af | grep /home/fabio/sites/compras/script/compras | grep -v grep | awk '{print $2}'`;

if [ "$TIPO" == "parar" ] ; then
	if [ "$PROC" != "" ] ; then
		kill -9 $PROC;
	fi;
else
	if [ "$PROC" == "" ] ; then
		nohup perl /home/fabio/sites/compras/script/compras daemon & 	
	fi;
fi; 

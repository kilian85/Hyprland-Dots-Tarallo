#!/usr/bin/env bash
uptime -p | sed \
  's/^up /da /;
   s/ days\?/ giorni/;
   s/ hours\?/ ore/;
   s/ minutes\?/ minuti/;
   s/ seconds\?/ secondi/'

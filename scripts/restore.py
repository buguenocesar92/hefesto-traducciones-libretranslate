#!/usr/bin/env python3
import sys
from common import ROOT,CONFIG,dc,sha,verify
if len(sys.argv)!=2:raise SystemExit('Uso: python3 scripts/restore.py /ruta/respaldo')
p=verify(sys.argv[1])
for n in CONFIG:
    if n=='.env':continue
    if not (ROOT/n).is_file() or sha(ROOT/n)!=sha(p/n):raise SystemExit('Kit/configuracion distinta: '+n)
if dc('ps','--services','--status','running',capture_output=True,text=True).stdout.strip():raise SystemExit('Detener todos los servicios del destino')
for folder in ['/keys','/models']:
    if dc('run','--rm','--no-deps','-T','--entrypoint','find','filetools',folder,'-mindepth','1','-print','-quit',capture_output=True,text=True).stdout.strip():raise SystemExit('Volumen destino ocupado: '+folder)
for name,folder in [('keys.tar.gz','/keys'),('models.tar.gz','/models')]:
    with (p/name).open('rb') as f:dc('run','--rm','--no-deps','-T','--entrypoint','tar','filetools','-xzf','-','-C',folder,stdin=f)
dc('run','--rm','--no-deps','-T','permissions')
print('Restaurado; servicios detenidos. Revisar claves recuperadas y ensayar en privado.')

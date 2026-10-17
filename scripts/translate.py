import argparse,base64,getpass,json,os,sys,urllib.request,urllib.parse
p=argparse.ArgumentParser(description='Traducir texto de stdin mediante instancia propia HTTPS')
p.add_argument('--url',required=True);p.add_argument('--source',default='es',choices=['es','en']);p.add_argument('--target',default='en',choices=['es','en'])
a=p.parse_args();u=urllib.parse.urlsplit(a.url)
if u.scheme!='https' or not u.hostname or u.username or u.password or u.query or u.fragment:raise SystemExit('Usar URL HTTPS propia sin credenciales/query')
text=sys.stdin.read(12001)
if not text or len(text)>3000:raise SystemExit('Introducir entre 1 y 3000 caracteres por stdin')
user=input('Usuario Basic Auth: ') if sys.stdin.isatty() else os.environ.get('HEFESTO_BASIC_USER','')
if not user:raise SystemExit('Definir HEFESTO_BASIC_USER')
pw=getpass.getpass('Clave Basic Auth: ')
key=os.environ.get('HEFESTO_API_KEY','')
body={'q':text,'source':a.source,'target':a.target,'format':'text'}
if key:body['api_key']=key
req=urllib.request.Request(a.url.rstrip('/')+'/translate',data=json.dumps(body).encode(),headers={'Content-Type':'application/json','Authorization':'Basic '+base64.b64encode((user+':'+pw).encode()).decode()})
# Disable redirects so Basic credentials/text never follow an unexpected redirect.
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*a,**kw):return None
try:
    with urllib.request.build_opener(NoRedirect).open(req,timeout=180) as r:data=json.load(r)
except Exception as e:raise SystemExit('La solicitud fallo; comprobar endpoint, acceso y limites. Tipo: '+type(e).__name__)
print(data['translatedText'])

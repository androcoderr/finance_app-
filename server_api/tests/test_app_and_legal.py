"""Zorunlu güncelleme, sağlık kontrolü ve yasal sayfalar."""
import os, sys
sys.path.insert(0, os.getcwd())
import app as A
from extension import limiter; limiter.enabled = False

c = A.app.test_client()
ok = lambda n, cond: print(('PASS ' if cond else 'FAIL ') + n)

A.app.config['MIN_APP_VERSION_CODE'] = 3
A.app.config['LATEST_APP_VERSION_CODE'] = 5
d = c.get('/app/config?version_code=2').get_json()
ok('old: required', d['update_required'] is True and d['update_available'] is True)
d = c.get('/app/config?version_code=4').get_json()
ok('between: available only', d['update_required'] is False and d['update_available'] is True)
d = c.get('/app/config?version_code=5').get_json()
ok('latest: nothing', d['update_required'] is False and d['update_available'] is False)
ok('config via header', c.get('/app/config', headers={'X-App-Version-Code': '2'}).get_json()['update_required'] is True)
ok('garbage version: no flags', c.get('/app/config?version_code=abc').get_json()['update_required'] is False)
r = c.post('/auth/login', json={'email': 'a@x.com', 'password': 'x'}, headers={'X-App-Version-Code': '2'})
ok('old app blocked 426', r.status_code == 426 and r.get_json()['update_required'] is True)
ok('old app blocked on GET too', c.get('/categories', headers={'X-App-Version-Code': '2'}).status_code == 426)
ok('min version passes', c.post('/auth/login', json={'email': 'a@x.com', 'password': 'x'}, headers={'X-App-Version-Code': '3'}).status_code == 401)
ok('no header passes (web pages)', c.get('/privacy').status_code == 200 and c.get('/reset-password?token=x').status_code == 200)
ok('health/config ok for old app', c.get('/health', headers={'X-App-Version-Code': '1'}).status_code == 200
   and c.get('/app/config', headers={'X-App-Version-Code': '1'}).status_code == 200)
A.app.config['MIN_APP_VERSION_CODE'] = 1; A.app.config['LATEST_APP_VERSION_CODE'] = 1
ok('defaults: v1 fine', c.get('/app/config?version_code=1').get_json()['update_required'] is False)

r = c.get('/health'); ok('health ok', r.status_code == 200 and r.get_json()['status'] == 'ok')

html = c.get('/privacy').get_data(as_text=True)
ok('privacy default controller', 'uygulamanın geliştiricisi' in html and 'yurt dışına' not in html)
os.environ['DATA_CONTROLLER_NAME'] = 'Test <b>Kişi</b>'; os.environ['HOSTING_LOCATION'] = 'Almanya (Frankfurt)'
html = c.get('/privacy').get_data(as_text=True)
ok('privacy env values + escaped', 'Test &lt;b&gt;Kişi&lt;/b&gt;' in html and 'Almanya (Frankfurt)' in html and 'yurt dışına' in html)
ok('delete page ok', c.get('/delete-account').status_code == 200)

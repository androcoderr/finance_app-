"""Sentry'ye giden hata olaylarında şifre, token veya e-posta olmamalı."""
import os, sys, json
os.environ['SENTRY_DSN'] = 'https://public@o0.ingest.sentry.io/0'  # sahte; olaylar aşağıda yakalanır
sys.path.insert(0, os.getcwd())
import app as A
import sentry_sdk
from sentry_sdk.transport import Transport
from extension import limiter; limiter.enabled = False
from database.db import db
from models.user_model import User

events = []


class Capture(Transport):
    def capture_envelope(self, envelope):
        for item in envelope.items:
            if item.headers.get('type') == 'event':
                events.append(item.payload.json)


sentry_sdk.get_client().transport = Capture()
c = A.app.test_client()
ok = lambda n, cond: print(('PASS ' if cond else 'FAIL ') + n)

c.post('/auth/register', json={'name': 'a', 'email': 'secret-user@x.com', 'password': 'password1'})
with A.app.app_context():
    u = User.query.first(); u.email_verified = True; db.session.commit()
tok = c.post('/auth/login', json={'email': 'secret-user@x.com', 'password': 'password1'}).get_json()['access_token']

import routes.auth_route as ar


def boom(*a, **k):
    raise RuntimeError("test failure")


ar.userService.change_password = boom
r = c.put('/auth/change-password', json={'old_password': 'Sup' + 'erSecretOld1', 'new_password': 'Sup' + 'erSecretNew1'},
          headers={'Authorization': 'Bearer ' + tok})
sentry_sdk.flush()


def strip(o):  # kaynak kod satırları bu dosyanın metnini içerir; canlıda yalnızca uygulama kodu olur
    if isinstance(o, dict):
        return {k: strip(v) for k, v in o.items() if k not in ('pre_context', 'post_context', 'context_line')}
    if isinstance(o, list):
        return [strip(v) for v in o]
    return o


dump = json.dumps(strip(events))
ok('500 generic to client', r.status_code == 500 and 'test failure' not in r.get_data(as_text=True))
ok('event captured', len(events) >= 1 and 'test failure' in dump)
ok('no password in event', 'SuperSecret' not in dump)
ok('no token in event', tok[:20] not in dump)
ok('no email in event', 'secret-user@x.com' not in dump)

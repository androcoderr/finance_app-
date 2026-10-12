"""Güvenlik: token iptali, girdi doğrulama, tekrarlayan işlemler, CORS, başlıklar, istek sınırı."""
import os, sys, base64
sys.path.insert(0, os.getcwd())
import app as A
from routes.password_reset_route import generate_reset_token
from models.user_model import User
from database.db import db

c = A.app.test_client()
ok = lambda name, cond: print(('PASS ' if cond else 'FAIL ') + name)


def reg(email):
    c.post('/auth/register', json={'name': 'a', 'email': email, 'password': 'password1'})
    with A.app.app_context():
        u = User.query.filter_by(email=email).first(); u.email_verified = True; db.session.commit()
    d = c.post('/auth/login', json={'email': email, 'password': 'password1'}).get_json()
    return d['user']['id'], d['access_token'], d['refresh_token']


uid, at, rt = reg('a@x.com'); H = {'Authorization': 'Bearer ' + at}
ok('normal request works', c.get(f'/users/{uid}', headers=H).status_code == 200)
ok('refresh works', c.post('/auth/refresh', headers={'Authorization': 'Bearer ' + rt}).status_code == 200)
r = c.put('/auth/change-password', json={'old_password': 'password1', 'new_password': 'password2'}, headers=H)
d = r.get_json(); ok('change-password returns new tokens', r.status_code == 200 and 'access_token' in d)
ok('old access rejected', c.get(f'/users/{uid}', headers=H).status_code == 401)
ok('old refresh rejected', c.post('/auth/refresh', headers={'Authorization': 'Bearer ' + rt}).status_code == 401)
H = {'Authorization': 'Bearer ' + d['access_token']}; rt = d['refresh_token']
ok('new access works', c.get(f'/users/{uid}', headers=H).status_code == 200)
ok('new refresh works', c.post('/auth/refresh', headers={'Authorization': 'Bearer ' + rt}).status_code == 200)
ok('login works', c.post('/auth/login', json={'email': 'a@x.com', 'password': 'password2'}).status_code == 200)

with A.app.app_context():
    u = db.session.get(User, uid); t = generate_reset_token(u)
p = t.split('.')[0]; p += '=' * (-len(p) % 4)
ok('reset token hides email', b'a@x.com' not in base64.urlsafe_b64decode(p))
ok('verify token', c.post('/api/verify-reset-token', json={'token': t}).status_code == 200)
ok('reset password', c.post('/api/reset-password', json={'token': t, 'password': 'password3'}).status_code == 200)
ok('reset token single use', c.post('/api/reset-password', json={'token': t, 'password': 'password4'}).status_code == 400)
ok('tokens dead after reset', c.get(f'/users/{uid}', headers=H).status_code == 401)
H = {'Authorization': 'Bearer ' + c.post('/auth/login', json={'email': 'a@x.com', 'password': 'password3'}).get_json()['access_token']}

cid = c.get('/categories').get_json()[0]['id']
base = {'amount': 1, 'category_id': cid, 'type': 'expense', 'frequency': 'daily'}
ok('recurring 1900 rejected', c.post('/recurring', json={**base, 'start_date': '1900-01-01T00:00:00.000'}, headers=H).status_code == 400)
ok('recurring bogus type rejected', c.post('/recurring', json={**base, 'type': 'bogus', 'start_date': '2026-01-01T00:00:00.000'}, headers=H).status_code == 400)
ok('recurring bogus frequency rejected', c.post('/recurring', json={**base, 'frequency': 'hourly', 'start_date': '2026-01-01T00:00:00.000'}, headers=H).status_code == 400)
from datetime import date, timedelta
recent = (date.today() - timedelta(days=37)).isoformat() + 'T00:00:00.000'
r = c.post('/recurring', json={**base, 'start_date': recent}, headers=H)
ok('recurring valid created', r.status_code == 201); rid = r.get_json()['id']
r = c.put(f'/recurring/{rid}', json={'amount': 5}, headers=H); ok('recurring partial update', r.status_code == 200 and r.get_json()['amount'] == 5)
ok('recurring update bad type rejected', c.put(f'/recurring/{rid}', json={'type': 'x'}, headers=H).status_code == 400)
n = len(c.get(f'/users/{uid}/transactions', headers=H).get_json()); n2 = len(c.get(f'/users/{uid}/transactions', headers=H).get_json())
ok(f'materialize once ({n} rows, stable)', n == n2 and 30 <= n <= 45)

r = c.options('/auth/login', headers={'Origin': 'https://evil.com', 'Access-Control-Request-Method': 'POST'})
ok('no CORS header', 'Access-Control-Allow-Origin' not in r.headers)

T = lambda **kw: c.post(f'/users/{uid}/transactions', json={"amount": 10, "category_id": cid, "date": "2026-01-01T00:00:00.000Z", "type": "expense", **kw}, headers=H)
ok('valid tx (Z date)', T().status_code == 201)
ok('negative rejected', T(amount=-5).status_code == 400)
ok('huge rejected', T(amount=1e300).status_code == 400)
ok('string amount rejected', T(amount="10").status_code == 400)
ok('bad category rejected', T(category_id="nope").status_code == 400)
ok('long description rejected', T(description="x" * 300).status_code == 400)
ok('bad date rejected', T(date="yesterday").status_code == 400)
r = c.post(f'/users/{uid}/transactions', data='{"amount": NaN, "category_id": "%s", "date":"2026-01-01T00:00:00", "type":"expense"}' % cid, headers={**H, 'Content-Type': 'application/json'})
ok('NaN rejected', r.status_code == 400)
ok('goal valid', c.post('/goals', json={'name': 'Tatil', 'target_amount': 1000}, headers=H).status_code == 201)
ok('goal negative rejected', c.post('/goals', json={'name': 'x', 'target_amount': -1}, headers=H).status_code == 400)
ok('goal no body', c.post('/goals', headers=H).status_code == 400)
ok('bill valid', c.post('/bills', json={'name': 'Elektrik', 'amount': 100, 'due_day': 5, 'category': 'Fatura'}, headers=H).status_code == 201)
ok('bill long name rejected', c.post('/bills', json={'name': 'x' * 200, 'amount': 100, 'due_day': 5, 'category': 'Fatura'}, headers=H).status_code == 400)
ok('profile long name rejected', c.put('/users/profile', json={'name': 'x' * 200}, headers=H).status_code == 400)
ok('big body 413', c.post('/goals', data='x' * (2 * 1024 * 1024), headers={**H, 'Content-Type': 'application/json'}).status_code == 413)

r = c.get('/reset-password?token=x')
ok('security headers', r.headers.get('Referrer-Policy') == 'no-referrer' and 'Content-Security-Policy' in r.headers and r.headers.get('X-Content-Type-Options') == 'nosniff')

uid2, at2, rt2 = reg('b@x.com'); H2 = {'Authorization': 'Bearer ' + at2}
ok('delete account', c.delete('/users/profile', headers=H2).status_code == 200)
ok('refresh dead after delete', c.post('/auth/refresh', headers={'Authorization': 'Bearer ' + rt2}).status_code == 401)

codes = [c.post('/auth/login', json={'email': 'z@x.com', 'password': 'wrongpass'}) for _ in range(7)]
ok('login rate limit JSON 429', codes[-1].status_code == 429 and 'error' in codes[-1].get_json())

# Token olmadan kullanıcı verisine dokunan hiçbir uç açılmamalı
import re
public = {'/api/2fa/check-status/<session_token>', '/api/forgot-password', '/api/reset-password',
          '/api/verify-reset-token', '/app/config', '/auth/2fa/complete/<session_token>', '/auth/login',
          '/auth/register', '/auth/resend-code', '/auth/verify-email', '/categories',
          '/categories/<category_id>', '/delete-account', '/health', '/privacy', '/reset-password'}
from extension import limiter; limiter.enabled = False
open_rules = []
for rule in A.app.url_map.iter_rules():
    if rule.endpoint == 'static' or rule.rule in public:
        continue
    url = re.sub(r'<[^>]+>', 'x', rule.rule)
    for m in rule.methods - {'HEAD', 'OPTIONS'}:
        if c.open(url, method=m, json={}).status_code != 401:
            open_rules.append(f'{m} {rule.rule}')
ok(f'all non-public endpoints need a token {open_rules or ""}', not open_rules)

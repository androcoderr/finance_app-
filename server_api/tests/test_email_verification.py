"""E-posta doğrulama: kayıt, kod, deneme sınırı, yeniden gönderme, ele geçirme, e-posta değişikliği, temizlik."""
import os, sys, re
from datetime import datetime, timedelta
sys.path.insert(0, os.getcwd())
import app as A
import services.email_verification_service as ev
from database.db import db
from models.user_model import User
from extension import limiter; limiter.enabled = False

sent = []
ev.send_mail = lambda to, subj, html, dev_log=None: sent.append((to, re.search(r'>(\d{6})<', html).group(1)))
c = A.app.test_client()
ok = lambda n, cond: print(('PASS ' if cond else 'FAIL ') + n)


def clear_cooldown(email):
    with A.app.app_context():
        u = User.query.filter_by(email=email).first(); u.verification_sent_at = None; db.session.commit()


r = c.post('/auth/register', json={'name': 'Ali', 'email': 'Ali@X.com', 'password': 'password1'})
d = r.get_json(); ok('register 201 no token', r.status_code == 201 and 'access_token' not in d and d['requires_verification'] and d['email'] == 'ali@x.com')
ok('code sent', len(sent) == 1 and sent[0][0] == 'ali@x.com')
code = sent[-1][1]
r = c.post('/auth/login', json={'email': 'ali@x.com', 'password': 'password1'})
ok('login unverified 403', r.status_code == 403 and r.get_json()['requires_verification'])
ok('login within cooldown no new code', len(sent) == 1)
r = c.post('/auth/resend-code', json={'email': 'ali@x.com'})
ok('resend within cooldown 429', r.status_code == 429 and r.get_json()['retry_after'] > 0)
ok('resend unknown email 200', c.post('/auth/resend-code', json={'email': 'nobody@x.com'}).status_code == 200)
V = lambda **kw: c.post('/auth/verify-email', json={'email': 'ali@x.com', 'code': code, 'password': 'password1', **kw})
ok('verify wrong password 400', V(password='nope12345').status_code == 400)
wrong = '000000' if code != '000000' else '111111'
r = V(code=wrong); ok('wrong code 400 w/ remaining', r.status_code == 400 and '4' in r.get_json()['error'])
r = V(); d = r.get_json()
ok('verify ok returns tokens', r.status_code == 200 and 'access_token' in d and d['user']['email_verified'] is True)
H = {'Authorization': 'Bearer ' + d['access_token']}
ok('token works', c.get(f"/users/{d['user']['id']}", headers=H).status_code == 200)
ok('login after verify 200', c.post('/auth/login', json={'email': 'ali@x.com', 'password': 'password1'}).status_code == 200)
ok('register verified email 400', c.post('/auth/register', json={'name': 'x', 'email': 'ali@x.com', 'password': 'password9'}).status_code == 400)
ok('verify again 400', V().status_code == 400)

# Profilden e-posta değiştirilemez; ad değişir
ok('email change rejected', c.put('/users/profile', json={'email': 'evil@x.com'}, headers=H).status_code == 400)
r = c.put('/users/profile', json={'name': 'Yeni Ad', 'email': 'ALI@x.com'}, headers=H)
ok('same email + name ok', r.status_code == 200 and r.get_json()['user']['name'] == 'Yeni Ad')

# 5 yanlış deneme kodu kilitler
c.post('/auth/register', json={'name': 'B', 'email': 'b@x.com', 'password': 'password1'}); bcode = sent[-1][1]
W = lambda code: c.post('/auth/verify-email', json={'email': 'b@x.com', 'code': code, 'password': 'password1'})
bad = '000000' if bcode != '000000' else '111111'
for _ in range(5):
    r = W(bad)
ok('5th wrong -> new code msg', 'yeni kod' in r.get_json()['error'].lower())
ok('correct code after lock rejected', W(bcode).status_code == 400)
clear_cooldown('b@x.com')
ok('resend after cooldown 200', c.post('/auth/resend-code', json={'email': 'b@x.com'}).status_code == 200)
ok('new code works', W(sent[-1][1]).status_code == 200)

# Doğrulanmamış adresi başkası yeniden kaydederse eski şifreyle doğrulanamaz
c.post('/auth/register', json={'name': 'Attacker', 'email': 'v@x.com', 'password': 'attacker1'})
clear_cooldown('v@x.com')
ok('re-register unverified 201', c.post('/auth/register', json={'name': 'Victim', 'email': 'v@x.com', 'password': 'victim123'}).status_code == 201)
vcode = sent[-1][1]
ok('attacker password cannot verify', c.post('/auth/verify-email', json={'email': 'v@x.com', 'code': vcode, 'password': 'attacker1'}).status_code == 400)
ok('owner verifies', c.post('/auth/verify-email', json={'email': 'v@x.com', 'code': vcode, 'password': 'victim123'}).status_code == 200)

# Süresi dolan kod; şifre sıfırlama e-postayı doğrular
c.post('/auth/register', json={'name': 'E', 'email': 'e@x.com', 'password': 'password1'}); ecode = sent[-1][1]
with A.app.app_context():
    u = User.query.filter_by(email='e@x.com').first(); u.verification_expires_at = datetime.utcnow() - timedelta(seconds=1); db.session.commit()
r = c.post('/auth/verify-email', json={'email': 'e@x.com', 'code': ecode, 'password': 'password1'})
ok('expired code 400', r.status_code == 400 and 'süresi' in r.get_json()['error'])
from routes.password_reset_route import generate_reset_token
with A.app.app_context():
    t = generate_reset_token(User.query.filter_by(email='e@x.com').first())
c.post('/api/reset-password', json={'token': t, 'password': 'password2'})
ok('reset verifies email', c.post('/auth/login', json={'email': 'e@x.com', 'password': 'password2'}).status_code == 200)

# 7 günden eski doğrulanmamış kayıtlar temizlenir
old = datetime.utcnow() - timedelta(days=8)
for email in ('old@x.com', 'fresh@x.com', 'resent@x.com', 'oldverified@x.com'):
    c.post('/auth/register', json={'name': 'a', 'email': email, 'password': 'password1'})
with A.app.app_context():
    for email in ('old@x.com', 'resent@x.com', 'oldverified@x.com'):
        u = User.query.filter_by(email=email).first(); u.created_at = old
        u.verification_sent_at = old if email != 'resent@x.com' else datetime.utcnow()
    User.query.filter_by(email='oldverified@x.com').first().email_verified = True
    db.session.commit()
c.post('/auth/register', json={'name': 'a', 'email': 'trigger@x.com', 'password': 'password1'})
with A.app.app_context():
    left = {u.email for u in User.query.all()}
ok('old unverified purged', 'old@x.com' not in left)
ok('fresh / re-sent / verified kept', {'fresh@x.com', 'resent@x.com', 'oldverified@x.com', 'trigger@x.com'} <= left)

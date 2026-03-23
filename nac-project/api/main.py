from fastapi import FastAPI, HTTPException
from database import get_db_pool, get_redis
from models import AuthRequest, AuthorizeRequest, AccountingRequest
from passlib.hash import bcrypt
import json

app = FastAPI(title="NAC Policy Engine")

# ---------------------------------------------------------------
# /auth  →  Kullanıcı adı + şifre doğrula
# FreeRADIUS buraya sorar: "Bu adam içeri girebilir mi?"
# ---------------------------------------------------------------
@app.post("/auth")
async def authenticate(req: AuthRequest):
    pool = await get_db_pool()
    redis = await get_redis()

    rate_key = f"fail:{req.username}"

    # Rate-limiting: 5 başarısız denemeden sonra 5 dakika kilitle
    fail_count = await redis.get(rate_key)
    if fail_count and int(fail_count) >= 5:
        raise HTTPException(status_code=429, detail="Too many failed attempts")

    # Veritabanından hashlenmiş şifreyi çek
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT value FROM radcheck WHERE username=$1 AND attribute='Cleartext-Password'",
            req.username
        )

    if not row:
        await redis.incr(rate_key)
        await redis.expire(rate_key, 300)
        raise HTTPException(status_code=401, detail="User not found")

    # bcrypt ile şifre doğrula
    if not bcrypt.verify(req.password, row["value"]):
        await redis.incr(rate_key)
        await redis.expire(rate_key, 300)
        raise HTTPException(status_code=401, detail="Invalid password")

    # Başarılı giriş: hata sayacını sıfırla
    await redis.delete(rate_key)
    return {"status": "accept"}


# ---------------------------------------------------------------
# /authorize  →  Kullanıcıya hangi VLAN atansın?
# FreeRADIUS buraya sorar: "Bunu nereye koyalım?"
# ---------------------------------------------------------------
@app.post("/authorize")
async def authorize(req: AuthorizeRequest):
    pool = await get_db_pool()

    async with pool.acquire() as conn:
        # Kullanıcının grubunu bul
        group = await conn.fetchrow(
            "SELECT groupname FROM radusergroup WHERE username=$1",
            req.username
        )
        if not group:
            raise HTTPException(status_code=404, detail="User group not found")

        # Grubun VLAN attribute'larını çek
        rows = await conn.fetch(
            "SELECT attribute, op, value FROM radgroupreply WHERE groupname=$1",
            group["groupname"]
        )

    attributes = [{"attribute": r["attribute"], "op": r["op"], "value": r["value"]} for r in rows]
    return {"group": group["groupname"], "attributes": attributes}


# ---------------------------------------------------------------
# /accounting  →  Oturum verisini kaydet
# FreeRADIUS buraya söyler: "Bu adam şu kadar kaldı, kaydet"
# ---------------------------------------------------------------
@app.post("/accounting")
async def accounting(req: AccountingRequest):
    pool = await get_db_pool()
    redis = await get_redis()

    async with pool.acquire() as conn:
        if req.acctstatustype == "Start":
            await conn.execute("""
                INSERT INTO radacct
                    (acctsessionid, acctuniqueid, username, nasipaddress,
                     callingstationid, acctstarttime)
                VALUES ($1,$2,$3,$4,$5, NOW())
                ON CONFLICT (acctuniqueid) DO NOTHING
            """, req.acctsessionid, req.acctuniqueid, req.username,
                req.nasipaddress, req.callingstationid)

            # Aktif oturumu Redis'e ekle
            await redis.hset("active_sessions", req.acctuniqueid,
                             json.dumps({"username": req.username,
                                         "nas": req.nasipaddress}))

        elif req.acctstatustype == "Stop":
            await conn.execute("""
                UPDATE radacct SET
                    acctstoptime       = NOW(),
                    acctsessiontime    = $1,
                    acctinputoctets    = $2,
                    acctoutputoctets   = $3,
                    acctterminatecause = $4
                WHERE acctuniqueid = $5
            """, req.acctsessiontime, req.acctinputoctets,
                req.acctoutputoctets, req.acctterminatecause,
                req.acctuniqueid)

            # Aktif oturumdan kaldır
            await redis.hdel("active_sessions", req.acctuniqueid)

    return {"status": "ok"}


# ---------------------------------------------------------------
# /users  →  Tüm kullanıcıları listele
# ---------------------------------------------------------------
@app.get("/users")
async def list_users():
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT u.username, u.groupname FROM radusergroup u"
        )
    return [{"username": r["username"], "group": r["groupname"]} for r in rows]


# ---------------------------------------------------------------
# /sessions/active  →  Redis'ten aktif oturumları getir
# ---------------------------------------------------------------
@app.get("/sessions/active")
async def active_sessions():
    redis = await get_redis()
    sessions = await redis.hgetall("active_sessions")
    return {k: json.loads(v) for k, v in sessions.items()}
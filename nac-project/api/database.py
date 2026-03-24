import os
import asyncpg
import redis.asyncio as aioredis

DATABASE_URL = os.getenv("DATABASE_URL")
REDIS_URL = os.getenv("REDIS_URL")

db_pool = None

async def get_db_pool():
    global db_pool
    if db_pool is None:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
    return db_pool

redis_client = None

async def get_redis():
    global redis_client
    if redis_client is None:
        redis_client = aioredis.from_url(REDIS_URL, decode_responses=True)
    return redis_client
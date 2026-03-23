from pydantic import BaseModel
from typing import Optional

# /auth endpoint'ine FreeRADIUS'tan gelecek JSON
class AuthRequest(BaseModel):
    username: str
    password: str

# /authorize endpoint'ine gelecek JSON
class AuthorizeRequest(BaseModel):
    username: str

# /accounting endpoint'ine gelecek JSON
class AccountingRequest(BaseModel):
    username: str
    nasipaddress: str
    acctsessionid: str
    acctuniqueid: str
    acctstatustype: str             # Start, Interim-Update, Stop
    acctsessiontime: Optional[int] = 0
    acctinputoctets: Optional[int] = 0
    acctoutputoctets: Optional[int] = 0
    acctterminatecause: Optional[str] = None
    callingstationid: Optional[str] = None
    framedipaddress: Optional[str] = None
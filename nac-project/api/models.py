from pydantic import BaseModel
from typing import Optional

class AuthRequest(BaseModel):
    username: str
    password: str

class AuthorizeRequest(BaseModel):
    username: str

class AccountingRequest(BaseModel):
    username: str
    nasipaddress: str
    acctsessionid: str
    acctuniqueid: str
    acctstatustype: str
    acctsessiontime: Optional[int] = 0
    acctinputoctets: Optional[int] = 0
    acctoutputoctets: Optional[int] = 0
    acctterminatecause: Optional[str] = None
    callingstationid: Optional[str] = None
    framedipaddress: Optional[str] = None
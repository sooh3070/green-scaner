import os

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api import scan, chat

app = FastAPI(title="Green Scanner API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_API_KEY = os.getenv("API_KEY", "")


@app.middleware("http")
async def require_api_key(request: Request, call_next):
    if request.url.path == "/" or not _API_KEY:
        return await call_next(request)
    if request.headers.get("X-API-Key") != _API_KEY:
        return JSONResponse(status_code=401, content={"detail": "인증 실패"})
    return await call_next(request)

app.include_router(scan.router, prefix="/scan", tags=["scan"])
app.include_router(chat.router, prefix="/chat", tags=["chat"])


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_request, _exc):
    return JSONResponse(status_code=400, content={"detail": "잘못된 요청입니다."})


@app.get("/")
async def health_check():
    return {"status": "ok", "service": "green-scanner-api", "version": "0.1.0"}

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, auth, exceptions
import random
import json
import torch
import tweepy
from fastapi_cache import FastAPICache
from fastapi_cache.backends.inmemory import InMemoryBackend
from fastapi_cache.decorator import cache
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import os
import re
from datetime import datetime
from .model import NeuralNet
from .nltk_utils import bag_of_words, tokenize
import asyncio
from typing import List 
import requests 
from bs4 import BeautifulSoup
from typing import List, Optional

# Inisialisasi Firebase Admin SDK
cred = credentials.Certificate("E:\Flutter_project\guardianeye\guardianeye-4766a-firebase-adminsdk-ol0rb-e0fb54202e.json")
firebase_admin.initialize_app(cred)

app = FastAPI()

# Twitter API credentials
bearer_token = "AAAAAAAAAAAAAAAAAAAAAAQIyQEAAAAAffAXaWnBImAc7AOfOtxUVNIWqeg%3DamgBCrUuziKy8Scnth28UrQRMHG6XgFFfZW4XIlwYbexIai3po"
client = tweepy.Client(bearer_token=bearer_token)

# Setup FastAPI Cache
@app.on_event("startup")
async def startup():
    FastAPICache.init(InMemoryBackend())




# =========================================================
# Twitter API Integration
# =========================================================

@app.get("/tweets/")
@cache(expire=300)  # Cache selama 5 menit
async def get_bmkg_tweets():
    try:
        # Mendapatkan user_id dari username
        user = client.get_user(username="infoBMKG")
        user_id = user.data.id

        # Mengambil tweet terbaru
        response = client.get_users_tweets(user_id, max_results=5, tweet_fields=["attachments"])

        tweet_list = []
        for tweet in response.data:
            tweet_data = {
                "date": tweet.created_at.isoformat() if tweet.created_at else "Unknown",
                "tweet": tweet.text,
                "imageUrl": None,
            }

            # Mengecek jika tweet memiliki media, seperti gambar
            if 'media' in tweet.attachments:
                media = tweet.attachments['media']
                tweet_data["imageUrl"] = media[0]['url'] if media else None

            tweet_list.append(tweet_data)

        return {
            "tweets": tweet_list,
            "rate_limit_remaining": response.meta.get("x-rate-limit-remaining", "Unknown"),
            "rate_limit_reset": response.meta.get("x-rate-limit-reset", "Unknown"),
        }
    except tweepy.TooManyRequests as e:
        raise HTTPException(status_code=429, detail="Terlalu banyak permintaan. Harap coba lagi nanti.")
    except tweepy.TweepyException as e:
        raise HTTPException(status_code=500, detail=f"Error fetching tweets: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error fetching user ID: {str(e)}")

# =========================================================
# User Authentication (Login and Registration)
# =========================================================

class UserLogin(BaseModel):
    email: str
    password: str

@app.post("/login/")
async def login(user: UserLogin):
    try:
        # Verifikasi kredensial pengguna menggunakan Firebase Auth
        user_record = auth.get_user_by_email(user.email)
        return {"message": "Login berhasil", "user_id": user_record.uid}
    except exceptions.FirebaseError as e:
        raise HTTPException(status_code=401, detail=f"Kredensial tidak valid: {str(e)}")

class UserRegister(BaseModel):
    email: str
    password: str

@app.post("/register/")
async def register(user: UserRegister):
    try:
        # Membuat akun pengguna baru di Firebase Auth
        user_record = auth.create_user(
            email=user.email,
            password=user.password
        )
        return {"message": "Pengguna berhasil didaftarkan", "user_id": user_record.uid}
    except exceptions.FirebaseError as e:
        raise HTTPException(status_code=400, detail=f"Gagal mendaftarkan pengguna: {str(e)}")

# =========================================================
# Chatbot Implementation
# =========================================================

# Load intents dan model chatbot
with open(r'E:\Flutter_project\guardianeye\backend\intents.json', 'r') as json_data:
    intents = json.load(json_data)

FILE = r"E:\Flutter_project\guardianeye\data_edukasi.pth"
data = torch.load(FILE)

input_size = data["input_size"]
hidden_size = data["hidden_size"]
output_size = data["output_size"]
all_words = data['all_words']
tags = data['tags']
model_state = data["model_state"]

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

model = NeuralNet(input_size, hidden_size, output_size).to(device)
model.load_state_dict(model_state)
model.eval()

bot_name = "Sam"

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(chat_request: ChatRequest):
    sentence = chat_request.message
    sentence = tokenize(sentence)
    X = bag_of_words(sentence, all_words)
    X = X.reshape(1, X.shape[0])
    X = torch.from_numpy(X).to(device)

    output = model(X)
    _, predicted = torch.max(output, dim=1)
    tag = tags[predicted.item()]

    probs = torch.softmax(output, dim=1)
    prob = probs[0][predicted.item()]

    if prob.item() > 0.75:
        for intent in intents['intents']:
            if tag == intent["tag"]:
                response = random.choice(intent['responses'])
                return ChatResponse(response=response)
    else:
        return ChatResponse(response="I do not understand...")
    
    

# =========================================================
# BMKG API Integration
# =========================================================

def fetch_bmkg_gempa_data():
    """
    Fungsi untuk mengambil data gempa terkini dari API BMKG.
    """
    url = "https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise exception jika status code bukan 200
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        return {"error": f"Gagal mengambil data dari BMKG: {str(e)}"}

class GempaItem(BaseModel):
    Tanggal: str
    Jam: str
    DateTime: str
    Coordinates: str
    Lintang: str
    Bujur: str
    Magnitude: str
    Kedalaman: str
    Wilayah: str
    Potensi: str

class BMKGGempaResponse(BaseModel):
    gempa: List[GempaItem]

@app.get("/bmkg/gempa-terkini", response_model=BMKGGempaResponse)
@cache(expire=300)  # Cache selama 5 menit
async def get_bmkg_gempa_terkini():
    """
    Endpoint untuk mendapatkan data gempa terkini dari BMKG.
    """
    data = fetch_bmkg_gempa_data()
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
    
    # Pastikan data yang diterima sesuai dengan struktur yang diharapkan
    if "Infogempa" not in data or "gempa" not in data["Infogempa"]:
        raise HTTPException(status_code=500, detail="Struktur data BMKG tidak valid")
    
    return {"gempa": data["Infogempa"]["gempa"]}


# =========================================================
# Model Pydantic untuk Data Banjir
# =========================================================

class BanjirItem(BaseModel):
    id: str
    nprop: str
    nkab: str
    kejadian: str
    tanggal: str
    lokasi: Optional[str]
    desa_terdampak: Optional[str]
    keterangan: Optional[str]
    penyebab: Optional[str]
    kronologis: Optional[str]
    sumber: Optional[str]
    mengungsi: Optional[str]
    rumah_terendam: Optional[str]
    longitude: Optional[str]
    latitude: Optional[str]

class BanjirResponse(BaseModel):
    banjir: List[BanjirItem]

# =========================================================
# Fungsi untuk Mengambil Data Banjir dari API DIBI BNPB
# =========================================================

def fetch_banjir_data():
    """
    Fungsi untuk mengambil data banjir dari API DIBI BNPB.
    """
    url = "https://dibi.bnpb.go.id/baru/get_markers?pr=&kb=&th=2025&bl=&jn=&lm=c&tg1=2025-23-01&tg2=2025-01-23"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise exception jika status code bukan 200
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        return {"error": f"Gagal mengambil data banjir dari DIBI BNPB: {str(e)}"}

# =========================================================
# Endpoint untuk Data Banjir
# =========================================================

@app.get("/banjir", response_model=BanjirResponse)
@cache(expire=300)  # Cache selama 5 menit
async def get_banjir():
    """
    Endpoint untuk mendapatkan data banjir terkini dari DIBI BNPB.
    """
    data = fetch_banjir_data()
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
    
    # Pastikan data yang diterima sesuai dengan struktur yang diharapkan
    if not isinstance(data, list):
        raise HTTPException(status_code=500, detail="Struktur data banjir tidak valid")
    
    return {"banjir": data}



# =========================================================
# BMKG API Integration (Auto Gempa)
# =========================================================

class AutoGempaItem(BaseModel):
    Tanggal: str
    Jam: str
    DateTime: str
    Coordinates: str
    Lintang: str
    Bujur: str
    Magnitude: str
    Kedalaman: str
    Wilayah: str
    Potensi: str
    Dirasakan: str
    Shakemap: str

class AutoGempaResponse(BaseModel):
    gempa: AutoGempaItem

def fetch_auto_gempa_data():
    """
    Fungsi untuk mengambil data gempa terkini dari API BMKG.
    """
    url = "https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise exception jika status code bukan 200
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        return {"error": f"Gagal mengambil data dari BMKG: {str(e)}"}

@app.get("/bmkg/auto-gempa", response_model=AutoGempaResponse)
@cache(expire=300)  # Cache selama 5 menit
async def get_auto_gempa():
    """
    Endpoint untuk mendapatkan data gempa terkini dari BMKG.
    """
    data = fetch_auto_gempa_data()
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
    
    # Pastikan data yang diterima sesuai dengan struktur yang diharapkan
    if "Infogempa" not in data or "gempa" not in data["Infogempa"]:
        raise HTTPException(status_code=500, detail="Struktur data BMKG tidak valid")
    
    return {"gempa": data["Infogempa"]["gempa"]}


   # Model Pydantic untuk Data Pintu Air
class PintuAirItem(BaseModel):
    nama_pintu: str
    latitude: str
    longitude: str
    record_status: int
    tinggi_air: int
    tinggi_air_sebelumnya: int
    tanggal: str
    status_siaga: str

class PintuAirResponse(BaseModel):
    pintu_air: List[PintuAirItem]

# Fungsi untuk Mengambil Data Pintu Air
def fetch_pintu_air_data():
    """
    Fungsi untuk mengambil data pintu air dari URL yang diberikan.
    """
    url = "https://poskobanjir.dsdadki.web.id/datatmalaststatus.json"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raise exception jika status code bukan 200
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        return {"error": f"Gagal mengambil data pintu air: {str(e)}"}

# Endpoint untuk Data Pintu Air
@app.get("/pintu-air", response_model=PintuAirResponse)
@cache(expire=300)  # Cache selama 5 menit
async def get_pintu_air():
    """
    Endpoint untuk mendapatkan data pintu air terkini.
    """
    data = fetch_pintu_air_data()
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
    
    # Menyaring data yang penting
    filtered_data = []
    for item in data:
        filtered_item = {
            "nama_pintu": item.get("NAMA_PINTU_AIR"),
            "latitude": item.get("LATITUDE"),
            "longitude": item.get("LONGITUDE"),
            "record_status": item.get("RECORD_STATUS"),
            "tinggi_air": item.get("TINGGI_AIR"),
            "tinggi_air_sebelumnya": item.get("TINGGI_AIR_SEBELUMNYA"),
            "tanggal": item.get("TANGGAL"),
            "status_siaga": item.get("STATUS_SIAGA")
        }
        filtered_data.append(filtered_item)
    
    return {"pintu_air": filtered_data}




# =========================================================
# Jalankan Server
# =========================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
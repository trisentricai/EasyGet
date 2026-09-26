@echo off
set DATABASE_URL=sqlite:///db.sqlite3
cd /d %~dp0
..\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000 --noreload > server_out.txt 2>&1

FROM python:3.9-slim

ENV PYTHONUNBUFFERED=1

RUN python3 -m pip install -U --pre "yt-dlp[default]"
RUN python3 -m pip install Flask

COPY cookies.txt .
COPY flask-app.py .

CMD ["python", "flask-app.py"]
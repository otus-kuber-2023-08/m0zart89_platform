FROM python:3.9-slim
WORKDIR /app
RUN useradd -u 1001 appuser
USER appuser
EXPOSE 8000
CMD ["python3", "-m", "http.server"]
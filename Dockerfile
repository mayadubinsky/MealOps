FROM python:3.14.3-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
RUN addgroup --system mealops \
    && adduser --system --ingroup mealops mealops
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=mealops:mealops app.py index.html ./
USER mealops
EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
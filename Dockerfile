# ─────────────────────────────────────────
# STAGE 1: Builder
# Install dependencies in an isolated layer
# ─────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy only requirements first (better layer caching)
COPY requirements.txt .

# Install dependencies into a local directory
RUN pip install --upgrade pip && \
    pip install --prefix=/install -r requirements.txt

# ─────────────────────────────────────────
# STAGE 2: Production image
# Lean, non-root, hardened runtime image
# ─────────────────────────────────────────
FROM python:3.11-slim AS production

WORKDIR /app

# Copy installed packages from builder stage only
COPY --from=builder /install /usr/local

# Copy application source code
COPY app.py config.py database.py utils.py ./

# Create a non-root user and switch to it
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

USER appuser

# Expose the Flask port
EXPOSE 5000

# Health check — hits the home route every 30s
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

# Run the app
CMD ["python", "app.py"]

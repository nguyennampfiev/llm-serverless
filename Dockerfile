FROM python:3.13-slim AS builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -t /app

# Aggressive cleanup of Python packages
RUN find /app -type d -name "tests" -o -name "test" -o -name "*.dist-info" -o -name "__pycache__" | xargs rm -rf 2>/dev/null || true \
    && find /app -type f -name "*.pyc" -o -name "*.pyo" -o -name "*.pyx" -o -name "*.c" -o -name "*.cpp" | xargs rm -f 2>/dev/null || true \
    && find /app -name "*.so" -exec strip --strip-unneeded {} + 2>/dev/null || true

# Remove unnecessary Gradio assets (these are HUGE)
RUN rm -rf /app/gradio/templates/frontend/assets/*.map \
    && rm -rf /app/gradio_client 2>/dev/null || true

FROM python:3.13-slim
WORKDIR /app

# Copy only necessary Python packages
COPY --from=builder /app /app

# Copy application code
COPY --exclude=*.pyc --exclude=__pycache__ --exclude=.git --exclude=.pytest_cache --exclude=*.md . /app

# Install awslambdaric and final cleanup
RUN pip install --no-cache-dir awslambdaric \
    && find /app -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true \
    && find /app -type f -name "*.pyc" -o -name "*.pyo" | xargs rm -f 2>/dev/null || true \
    && rm -rf /root/.cache /tmp/* /var/tmp/*

ENTRYPOINT ["/usr/local/bin/python", "-m", "awslambdaric"]
CMD ["main.handler"]
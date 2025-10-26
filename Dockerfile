# Dockerfile
FROM public.ecr.aws/lambda/python:3.11

# copy requirements and app
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# copy project
COPY . /var/task

# Lambda image runtime expects a handler. We export handler name "app.handler" (Mangum object)
# When using the base image, the default CMD is ["app.handler"] style via the runtime, but we set ENTRYPOINT to the runtime.
CMD ["main.handler"]

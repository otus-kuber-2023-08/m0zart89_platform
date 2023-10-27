FROM python:3.10
RUN pip install kopf kubernetes pyyaml jinja2
COPY templates ./templates
COPY mysql-operator.py ./mysql-operator.py
CMD kopf run /mysql-operator.py
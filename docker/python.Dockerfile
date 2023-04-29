FROM python:3.9-alpine
# Or any preferred Python version.
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev \
    && apk add --no-cache mariadb-dev
RUN pip install mysqlclient SQLAlchemy faker SQLAlchemy-Utils python-dotenv
RUN apk del build-deps

ADD services/metering/metering_engine.py .
CMD [ "python", "./metering_engine.py" ]
# Or enter the name of your unique directory and parameter set.
import uuid
import random
import os
import time
from dotenv import load_dotenv, dotenv_values
from pathlib import Path

from datetime import datetime
from decimal import Decimal
from faker import Faker
from sqlalchemy import MetaData, String, select, create_engine, ForeignKey, create_engine, Numeric
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session
from sqlalchemy.sql.expression import func, select
from sqlalchemy_utils import database_exists, create_database

load_dotenv("./../../.env")

# set some default behaviours
number_of_customers = int(os.environ.get('AWS_NUMBER_OF_CUSTOMERS'))
# number_of_meters_per_customer = 1.1
metering_interval_seconds = int(os.environ.get('AWS_METERING_INTERVAL_SECONDS'))

# set the seed and locale for random entries
Faker.seed(10)
fake = Faker("en_AU")

# MySQL connectivity - use environment variables for connectivity
mysql_user = os.environ.get('AWS_MYSQL_USER')
mysql_password = os.environ.get('AWS_MYSQL_PASSWORD')
mysql_host = os.environ.get('AWS_MYSQL_HOST')
mysql_port = os.environ.get('AWS_MYSQL_PORT')
mysql_database_name = os.environ.get('AWS_MYSQL_DATABASE')


mysql_url = 'mysql://{0}:{1}@{2}:{3}/{4}'.format(mysql_user, mysql_password, mysql_host, mysql_port, mysql_database_name)
print (mysql_url)

#############################
#  PREPARE DATABASE ENGINE  #
#############################

engine = create_engine(mysql_url, echo=True)

if not database_exists(mysql_url):
    create_database(mysql_url)

meta = MetaData()
meta.create_all(engine)


#####################
# CLASS DEFINITIONS #
#####################

class Base(DeclarativeBase):
    pass

class Customer(Base):
    __tablename__ = 'customer'

    id: Mapped[int] = mapped_column(primary_key=True)
    first_name: Mapped[str] = mapped_column(String(30))
    last_name: Mapped[str] = mapped_column(String(30))
    address_street: Mapped[str] = mapped_column(String(256))
    address_suburb: Mapped[str] = mapped_column(String(30)) 
    address_postcode: Mapped[str] = mapped_column(String(6))

    # children: Mapped[list["Meter"]] = relationship()

    def __init__(self):
        self.first_name = fake.first_name()
        self.last_name = fake.last_name()
        self.address_street = fake.street_address()
        self.address_suburb = fake.city()
        self.address_postcode = fake.postcode()


class Meter(Base):
    __tablename__ = 'meter'

    nmi: Mapped[str] = mapped_column(String(40), primary_key=True)
    customer_id: Mapped[int] = mapped_column(ForeignKey("customer.id"))
    address_street: Mapped[str] = mapped_column(String(256))
    address_suburb: Mapped[str] = mapped_column(String(100))
    address_postcode: Mapped[str] = mapped_column(String(5))

    def __init__(self, customer):
        self.customer_id = customer.id
        self.nmi = str(uuid.uuid4())
        self.address_street = fake.street_address()
        self.address_suburb = fake.city()
        self.address_postcode = fake.postcode()


class Metering(Base):
    __tablename__ = 'metering'

    id: Mapped[int] = mapped_column(primary_key=True)
    nmi: Mapped[str] = mapped_column(String(40), ForeignKey("meter.nmi"))
    reading_kWh: Mapped[Decimal] = mapped_column(Numeric(10,2))
    timestamp: Mapped[datetime]


    def __init__(self, nmi):
        self.nmi = nmi
        self.reading_kWh = round(random.uniform(0, 100), 2)
        self.timestamp = datetime.now()

# Create the tables if they don't exist
Base.metadata.create_all(engine)


########################
#  INITIAL DATA SETUP  #
########################


with Session(engine) as session:
    rows = session.query(Meter).count()
    if rows == 0:
        for i in range(number_of_customers):
            customer = Customer()
            session.add(customer);
            session.commit()
            session.add(Meter(customer));
            session.commit()

# Setup the list of meters
meters_stmt = select(Meter.nmi)
with engine.connect() as conn:
    rs = conn.execute(meters_stmt)
    meters = [r for r in rs]


###################
#    MAIN LOOP    #
###################

while True:
    
    # Slow down the loop

    with Session(engine) as session:
        for row in meters:
            
            reading = Metering(row[0])
            session.add(reading)
        # Save everything to the database
        session.commit()

    time.sleep(metering_interval_seconds)
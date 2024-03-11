--1. Создать базу данных.

CREATE DATABASE Hotel;
GO

--2. 3-4 основные таблицы для своего проекта.

use Hotel;
GO


CREATE TABLE Rooms(
	Room_id int not null,
	number	varchar(100)  not null,
	category varchar(20)  not null,
	Employee_id int not null
);

CREATE TABLE Tariffs(
	Tariff_id int not null,
	price	money  not null ,
	begin_date date,
	end_date date,
	Service_id int not null
);

CREATE TABLE Bookings(
	Booking_id int not null,
	create_date date,
	begin_date date,
	end_date date,
	Guests_id int not null,
	Room_id int not null,
	Service_id int not null
);

CREATE TABLE b_Bookings_Services(
	Bookings_Services_id int not null,
	Booking_id int not null,
	Service_id int not null
);

--3. Первичные и внешние ключи для всех созданных таблиц.

ALTER TABLE Tariffs  ADD  PRIMARY KEY (Tariff_id);
ALTER TABLE Tariffs  ADD  CONSTRAINT FK_Service_Tariff FOREIGN KEY(Service_id)
REFERENCES Services (Service_id);

ALTER TABLE Rooms  ADD  PRIMARY KEY (Room_id);
ALTER TABLE Rooms  ADD  CONSTRAINT FK_Employee_Room FOREIGN KEY(Employee_id)
REFERENCES Employees (Employee_id);

ALTER TABLE Bookings  ADD  PRIMARY KEY (Booking_id);
ALTER TABLE Bookings  ADD  CONSTRAINT FK_Guests_Booking FOREIGN KEY(Guests_id)
REFERENCES Guests (Guests_id);
ALTER TABLE Bookings  ADD  CONSTRAINT FK_Room_Booking FOREIGN KEY(Room_id)
REFERENCES Rooms (Room_id);
ALTER TABLE Bookings  ADD  CONSTRAINT FK_Service_Booking FOREIGN KEY(Service_id)
REFERENCES Services (Service_id);

ALTER TABLE b_Bookings_Services  ADD  PRIMARY KEY (Bookings_Services_id);
ALTER TABLE b_Bookings_Services  ADD  CONSTRAINT FK_Booking_Book_Serv FOREIGN KEY(Booking_id)
REFERENCES Bookings (Booking_id);
ALTER TABLE b_Bookings_Services  ADD  CONSTRAINT FK_Service_Book_Serv FOREIGN KEY(Service_id)
REFERENCES Services (Service_id);

--4. 1-2 индекса на таблицы.

CREATE INDEX idx_begin_date on Bookings (begin_date);

ALTER TABLE Rooms ADD CONSTRAINT UK_room_number UNIQUE (number);

--5. Наложите по одному ограничению в каждой таблице на ввод данных.

ALTER TABLE Tariffs ADD  CONSTRAINT def_begin_date DEFAULT (getdate()) FOR begin_date;

ALTER TABLE Rooms ADD  CONSTRAINT def_category DEFAULT (N'Первая категория') FOR category;

ALTER TABLE Bookings ADD CONSTRAINT constr_beg 
		CHECK (create_date <= begin_date);

ALTER TABLE b_Bookings_Services 
	ADD CONSTRAINT constr_Book_Serv 
		CHECK (Service_id is not null);


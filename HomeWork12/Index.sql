use Hotel;
В предыдущей домашней работе было перенесено поле и по совместительству внешний ключ Service_id из таблицы Bookings 
 в таблицу Rooms, т к в таблице броней уже есть ссылка на комнату. Поэтому ссылка на услугу проживания в определенной категории номера 
 будет храниться в таблице команат Rooms.

--Составить список забронированных номеров.

Drop index if exists idx_begin_date;

CREATE NONCLUSTERED INDEX idx_date on Bookings (begin_date, end_date);
CREATE NONCLUSTERED INDEX idx_Room_id on Bookings (Room_id);

SELECT b.[Booking_id]
      ,b.[begin_date]
      ,b.[end_date]
      ,b.[Room_id]
	  ,r.category
	  ,r.number
  FROM [Bookings] b
  join Rooms r on r.Room_id = b.Room_id
  where getdate() between [begin_date] and [end_date]
  order by r.category


 --Составить список номеров и их гостей, которые обслуживаются одним сотрудником

  CREATE NONCLUSTERED INDEX idx_guest on Bookings (Guests_id);
  CREATE NONCLUSTERED INDEX idx_fio on Employees (fio);
  CREATE NONCLUSTERED INDEX idx_room_Employee_id on Rooms (Employee_id);
  CREATE NONCLUSTERED INDEX idx_room_number on Rooms (number);
  CREATE NONCLUSTERED INDEX idx_Guests_id on Bookings (Guests_id);

 SELECT e.[Employee_id]
      ,e.[fio]
	  ,r.number
	  ,r.category
	  ,b.booking_id
	  ,g.fio
  FROM [Employees] e
  join [Rooms] r on r.Employee_id = e.Employee_id
  join Bookings b on r.Room_id = b.Room_id
  left join Guests g on g.Guests_id = b.Guests_id
  order by e.[fio], r.number
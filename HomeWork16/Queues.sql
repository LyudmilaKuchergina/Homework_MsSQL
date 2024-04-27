USE [Hotel]

-- Необходимо получить список забронированных номеров заданной категории на заданную дату

-- Создаю таблицу, куда будут добавляться найденные забронированные номера
CREATE TABLE [dbo].[Booked_Rooms](
	[Booked_Rooms_id] [int] NOT NULL,
	[requested_date] [date] NULL,
	[Room_id] [int] NOT NULL,
	[number] [varchar](100) NOT NULL,
	[category] [varchar](20) NOT NULL
PRIMARY KEY CLUSTERED 
(
	[Booked_Rooms_id] ASC
)
) ON [PRIMARY]

USE [Hotel]
GO
CREATE SEQUENCE [Booked_Rooms_id] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO
ALTER TABLE [dbo].[Booked_Rooms] ADD  CONSTRAINT [DF_Booked_Rooms_Booked_Rooms_id]  DEFAULT (NEXT VALUE FOR [Booked_Rooms_id]) FOR [Booked_Rooms_id]
GO


ALTER DATABASE Hotel
SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE;
ALTER AUTHORIZATION    
   ON DATABASE::Hotel TO [sa];
ALTER DATABASE Hotel SET TRUSTWORTHY ON;

--Создаем типы сообщений
USE [Hotel]
-- For Request
CREATE MESSAGE TYPE
[//Hotel/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML; 
-- For Reply
CREATE MESSAGE TYPE
[//Hotel/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

--Создаем контракт(определяем какие сообщения в рамках этого контракта допустимы)
CREATE CONTRACT [//Hotel/SB/Contract]
      ([//Hotel/SB/RequestMessage]
         SENT BY INITIATOR,
       [//Hotel/SB/ReplyMessage]
         SENT BY TARGET
      );

--Создаем ОЧЕРЕДЬ таргета
CREATE QUEUE TargetQueueHotel;
--и сервис таргета
CREATE SERVICE [//Hotel/SB/TargetService]
       ON QUEUE TargetQueueHotel
       ([//Hotel/SB/Contract]);

--то же для ИНИЦИАТОРА
CREATE QUEUE InitiatorQueueHotel;

CREATE SERVICE [//Hotel/SB/InitiatorService]
       ON QUEUE InitiatorQueueHotel
       ([//Hotel/SB/Contract]);

--Создаем процедуры в скрипте CreateProcedure
--1. SendNewBookedRoom.sql - процедура которая вызывается в процессе какого-то техпроцесса - НЕ АКТИВАЦИОННАЯ для очередей
--2. GetNewBookedRoom.sql - АКТИВАЦИОННАЯ процедура(всегда без параметров)
--3. ConfirmBookedRoom.sql - АКТИВАЦИОННАЯ процедура - обработка сообщения что все прошло хорошо

--тепер настроим ОЧЕРЕДЬ или так можем рулить прецессами связанными с очередями
USE [Hotel]
GO
--пока с MAX_QUEUE_READERS = 0 чтобы вручную вызвать процедуры и увидеть все своими глазами 
ALTER QUEUE [dbo].[InitiatorQueueHotel] WITH STATUS = ON --OFF=очередь НЕ доступна(ставим если глобальные проблемы)
                                          ,RETENTION = OFF --ON=все завершенные сообщения хранятся в очереди до окончания диалога
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=после 5 ошибок очередь будет отключена
	                                      ,ACTIVATION (STATUS = ON --OFF=очередь не активирует ХП(в PROCEDURE_NAME)(ставим на время исправления ХП, но с потерей сообщений)  
										              ,PROCEDURE_NAME = dbo.ConfirmBookedRoom
													  ,MAX_QUEUE_READERS = 0 --количество потоков(ХП одновременно вызванных) при обработке сообщений(0-32767)
													                         --(0=тоже не позовется процедура)(ставим на время исправления ХП, без потери сообщений) 
													  ,EXECUTE AS OWNER --учетка от имени которой запустится ХП
													  ) 

GO
ALTER QUEUE [dbo].[TargetQueueHotel] WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.GetNewBookedRoom
												   ,MAX_QUEUE_READERS = 0
												   ,EXECUTE AS OWNER 
												   ) 
GO



----
--Начинаем тестировать
----

  select *
  from [dbo].[Bookings] b
  left join [dbo].[Rooms] r on r.Room_id = b.Room_id
  where r.category = N'Полулюкс'
  and '2024-03-30' between b.begin_date and b.end_date; 

--отправляем конкретный ид в таргет-сервис = на выходе наш select для просмотра
EXEC dbo.SendNewBookedRoom
	@date = '2024-03-30', @category = N'Полулюкс';

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueHotel;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueHotel;

--Таргет(получаем сообщение)=вручную запускаем активационные сообщения
EXEC dbo.GetNewBookedRoom;


--Initiator(второе пока)
EXEC dbo.ConfirmBookedRoom;

--список диалогов
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce --представление диалогов(постепенно очищается) чтобы ее не переполнять - --НЕЛЬЗЯ ЗАВЕРШАТЬ ДИАЛОГ ДО ОТПРАВКИ ПЕРВОГО СООБЩЕНИЯ
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

SELECT *
FROM [dbo].[Booked_Rooms]
WHERE category = N'Полулюкс'
  and requested_date = '2024-03-30';

--Теперь поставим 1 для ридеров(очередь должна вызвать все процедуры автоматом)
ALTER QUEUE [dbo].[InitiatorQueueHotel] WITH STATUS = ON --OFF=очередь НЕ доступна(ставим если глобальные проблемы)
                                          ,RETENTION = OFF --ON=все завершенные сообщения хранятся в очереди до окончания диалога
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=после 5 ошибок очередь будет отключена
	                                      ,ACTIVATION (STATUS = ON --OFF=очередь не активирует ХП(в PROCEDURE_NAME)(ставим на время исправления ХП, но с потерей сообщений)  
										              ,PROCEDURE_NAME = dbo.ConfirmBookedRoom
													  ,MAX_QUEUE_READERS = 1 --количество потоков(ХП одновременно вызванных) при обработке сообщений(0-32767)
													                         --(0=тоже не позовется процедура)(ставим на время исправления ХП, без потери сообщений) 
													  ,EXECUTE AS OWNER --учетка от имени которой запустится ХП
													  ) 

GO
ALTER QUEUE [dbo].[TargetQueueHotel] WITH STATUS = ON 
                                       ,RETENTION = OFF 
									   ,POISON_MESSAGE_HANDLING (STATUS = OFF)
									   ,ACTIVATION (STATUS = ON 
									               ,PROCEDURE_NAME = dbo.GetNewBookedRoom
												   ,MAX_QUEUE_READERS = 1
												   ,EXECUTE AS OWNER 
												   ) 

GO

--и пошлем сообщение с другим ИД
EXEC dbo.SendNewBookedRoom
	@date = '2024-03-20'
	,@category = N'Стандарт';

--проверяем
SELECT *
FROM [dbo].[Booked_Rooms]
WHERE category = N'Стандарт'
  and requested_date = '2024-03-20';


-- Очистка

USE [Hotel]
DROP SERVICE [//Hotel/SB/TargetService]
GO

DROP SERVICE [//Hotel/SB/InitiatorService]
GO

DROP QUEUE [dbo].[TargetQueueHotel]
GO 

DROP QUEUE [dbo].[InitiatorQueueHotel]
GO

DROP CONTRACT [//Hotel/SB/Contract]
GO

DROP MESSAGE TYPE [//Hotel/SB/RequestMessage]
GO

DROP MESSAGE TYPE [//Hotel/SB/ReplyMessage]
GO

DROP PROCEDURE IF EXISTS  dbo.SendNewBookedRoom;

DROP PROCEDURE IF EXISTS  dbo.GetNewBookedRoom;

DROP PROCEDURE IF EXISTS  dbo.ConfirmBookedRoom;


DROP TABLE dbo.Booked_Rooms;

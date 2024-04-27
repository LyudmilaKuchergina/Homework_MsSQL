USE [Hotel]

-- ���������� �������� ������ ��������������� ������� �������� ��������� �� �������� ����

-- ������ �������, ���� ����� ����������� ��������� ��������������� ������
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

--������� ���� ���������
USE [Hotel]
-- For Request
CREATE MESSAGE TYPE
[//Hotel/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML; 
-- For Reply
CREATE MESSAGE TYPE
[//Hotel/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 

--������� ��������(���������� ����� ��������� � ������ ����� ��������� ���������)
CREATE CONTRACT [//Hotel/SB/Contract]
      ([//Hotel/SB/RequestMessage]
         SENT BY INITIATOR,
       [//Hotel/SB/ReplyMessage]
         SENT BY TARGET
      );

--������� ������� �������
CREATE QUEUE TargetQueueHotel;
--� ������ �������
CREATE SERVICE [//Hotel/SB/TargetService]
       ON QUEUE TargetQueueHotel
       ([//Hotel/SB/Contract]);

--�� �� ��� ����������
CREATE QUEUE InitiatorQueueHotel;

CREATE SERVICE [//Hotel/SB/InitiatorService]
       ON QUEUE InitiatorQueueHotel
       ([//Hotel/SB/Contract]);

--������� ��������� � ������� CreateProcedure
--1. SendNewBookedRoom.sql - ��������� ������� ���������� � �������� ������-�� ����������� - �� ������������� ��� ��������
--2. GetNewBookedRoom.sql - ������������� ���������(������ ��� ����������)
--3. ConfirmBookedRoom.sql - ������������� ��������� - ��������� ��������� ��� ��� ������ ������

--����� �������� ������� ��� ��� ����� ������ ���������� ���������� � ���������
USE [Hotel]
GO
--���� � MAX_QUEUE_READERS = 0 ����� ������� ������� ��������� � ������� ��� ������ ������� 
ALTER QUEUE [dbo].[InitiatorQueueHotel] WITH STATUS = ON --OFF=������� �� ��������(������ ���� ���������� ��������)
                                          ,RETENTION = OFF --ON=��� ����������� ��������� �������� � ������� �� ��������� �������
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=����� 5 ������ ������� ����� ���������
	                                      ,ACTIVATION (STATUS = ON --OFF=������� �� ���������� ��(� PROCEDURE_NAME)(������ �� ����� ����������� ��, �� � ������� ���������)  
										              ,PROCEDURE_NAME = dbo.ConfirmBookedRoom
													  ,MAX_QUEUE_READERS = 0 --���������� �������(�� ������������ ���������) ��� ��������� ���������(0-32767)
													                         --(0=���� �� ��������� ���������)(������ �� ����� ����������� ��, ��� ������ ���������) 
													  ,EXECUTE AS OWNER --������ �� ����� ������� ���������� ��
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
--�������� �����������
----

  select *
  from [dbo].[Bookings] b
  left join [dbo].[Rooms] r on r.Room_id = b.Room_id
  where r.category = N'��������'
  and '2024-03-30' between b.begin_date and b.end_date; 

--���������� ���������� �� � ������-������ = �� ������ ��� select ��� ���������
EXEC dbo.SendNewBookedRoom
	@date = '2024-03-30', @category = N'��������';

SELECT CAST(message_body AS XML),*
FROM dbo.TargetQueueHotel;

SELECT CAST(message_body AS XML),*
FROM dbo.InitiatorQueueHotel;

--������(�������� ���������)=������� ��������� ������������� ���������
EXEC dbo.GetNewBookedRoom;


--Initiator(������ ����)
EXEC dbo.ConfirmBookedRoom;

--������ ��������
SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce --������������� ��������(���������� ���������) ����� �� �� ����������� - --������ ��������� ������ �� �������� ������� ���������
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

SELECT *
FROM [dbo].[Booked_Rooms]
WHERE category = N'��������'
  and requested_date = '2024-03-30';

--������ �������� 1 ��� �������(������� ������ ������� ��� ��������� ���������)
ALTER QUEUE [dbo].[InitiatorQueueHotel] WITH STATUS = ON --OFF=������� �� ��������(������ ���� ���������� ��������)
                                          ,RETENTION = OFF --ON=��� ����������� ��������� �������� � ������� �� ��������� �������
										  ,POISON_MESSAGE_HANDLING (STATUS = OFF) --ON=����� 5 ������ ������� ����� ���������
	                                      ,ACTIVATION (STATUS = ON --OFF=������� �� ���������� ��(� PROCEDURE_NAME)(������ �� ����� ����������� ��, �� � ������� ���������)  
										              ,PROCEDURE_NAME = dbo.ConfirmBookedRoom
													  ,MAX_QUEUE_READERS = 1 --���������� �������(�� ������������ ���������) ��� ��������� ���������(0-32767)
													                         --(0=���� �� ��������� ���������)(������ �� ����� ����������� ��, ��� ������ ���������) 
													  ,EXECUTE AS OWNER --������ �� ����� ������� ���������� ��
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

--� ������ ��������� � ������ ��
EXEC dbo.SendNewBookedRoom
	@date = '2024-03-20'
	,@category = N'��������';

--���������
SELECT *
FROM [dbo].[Booked_Rooms]
WHERE category = N'��������'
  and requested_date = '2024-03-20';


-- �������

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

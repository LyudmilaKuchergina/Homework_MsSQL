
CREATE PROCEDURE dbo.SendNewBookedRoom
	@date date,
	@category varchar(20) 
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN --на всякий случай в транзакции, т.к. это еще не относится к транзакции ПЕРЕДАЧИ сообщения

	--Формируем XML с корнем RequestMessage
	SELECT @RequestMessage = (SELECT b.Room_id as RoomID, @date as requested_date
							  FROM dbo.[Bookings] AS b
							  left join [Hotel].[dbo].[Rooms] r on r.Room_id = b.Room_id
							  WHERE @date  between b.begin_date and b.end_date
							  AND r.category = @category
							  FOR XML AUTO, root('RequestMessage')); 
	
	
	--Создаем диалог
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//Hotel/SB/InitiatorService] --от этого сервиса(это сервис текущей БД, поэтому он НЕ строка)
	TO SERVICE
	'//Hotel/SB/TargetService'    --к этому сервису(это сервис который может быть где-то, поэтому строка)
	ON CONTRACT
	[//Hotel/SB/Contract]         --в рамках этого контракта
	WITH ENCRYPTION=OFF;        --не шифрованный

	--отправляем одно наше подготовленное сообщение, но можно отправить и много сообщений, которые будут обрабатываться строго последовательно)
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//Hotel/SB/RequestMessage]
	(@RequestMessage);
	
	--Это для визуализации - на проде это не нужно
	SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END
GO

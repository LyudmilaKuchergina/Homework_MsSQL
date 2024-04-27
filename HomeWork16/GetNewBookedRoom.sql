CREATE PROCEDURE dbo.GetNewBookedRoom --будет получать сообщение на таргете
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@RoomID INT,
			@requested_date date,
			@xml XML; 
			--@temp_table table (requested_date date, RoomID varchar(50));
	
	BEGIN TRAN; 

	--Получаем сообщение от инициатора которое находится у таргета
	RECEIVE TOP(1) --обычно одно сообщение, но можно пачкой
		@TargetDlgHandle = Conversation_Handle, --ИД диалога
		@Message = Message_Body, --само сообщение
		@MessageType = Message_Type_Name --тип сообщения( в зависимости от типа можно по разному обрабатывать) обычно два - запрос и ответ
	FROM dbo.TargetQueueHotel; --имя очереди которую мы ранее создавали

	SELECT @Message; --не для прода

	SET @xml = CAST(@Message AS XML);

	--достали ИД
	SELECT @RoomID = R.Iv.value('@RoomID','varchar(50)')
	,@requested_date = R.Iv.value('@requested_date','date')
	FROM @xml.nodes('/RequestMessage/b') as R(Iv);

	--IF EXISTS (SELECT * FROM [dbo].[Bookings] WHERE Room_id in (4,5) and cast('2024-03-20' as date) between begin_date and end_date)
	--BEGIN
		 insert into [dbo].[Booked_Rooms] --@temp_table--[dbo].[Booked_Rooms]
		 (		   
			requested_date,
			Room_id
			,[number]
			,[category]
		 )
		  select   			  
			  R.Iv.value('@requested_date','date') 
			  ,R.Iv.value('@RoomID','varchar(max)')
			  ,ro.[number]
			  ,ro.[category]
		  from @xml.nodes('/RequestMessage/b') as R(Iv)
		  join [dbo].[Rooms] ro on R.Iv.value('@RoomID','varchar(max)') = ro.Room_id;

		 /* select * from @temp_table;

		 insert into [dbo].[Booked_Rooms]
		 (		   
			requested_date
			,Room_id
			,[number]
			,[category]
		 )
		  select   			  
			  t.requested_date
			  ,t.Room_id
			  ,r.[number]
			  ,r.[category]
		  from @temp_table t
		  join [dbo].[Rooms] r on t.Room_id = r.Room_id;*/
	--END;
	
	SELECT @Message AS ReceivedRequestMessage, @MessageType; --не для прода
	
	-- Confirm and Send a reply
	IF @MessageType=N'//Hotel/SB/RequestMessage' --если наш тип сообщения
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; --ответ
	    --отправляем сообщение нами придуманное, что все прошло хорошо
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//Hotel/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle; 
	END 
	
	SELECT @ReplyMessage AS SentReplyMessage; --не для прода - это для теста

	COMMIT TRAN;
END
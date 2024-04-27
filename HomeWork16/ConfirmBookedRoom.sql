--����� �� ������ ����
CREATE PROCEDURE dbo.ConfirmBookedRoom
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

	    --�������� ��������� �� ������� ������� ��������� � ����������
		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueueHotel; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; --��� ������ ����
		
		SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; --�� ��� �����

	COMMIT TRAN; 
END



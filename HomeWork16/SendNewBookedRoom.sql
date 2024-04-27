
CREATE PROCEDURE dbo.SendNewBookedRoom
	@date date,
	@category varchar(20) 
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN --�� ������ ������ � ����������, �.�. ��� ��� �� ��������� � ���������� �������� ���������

	--��������� XML � ������ RequestMessage
	SELECT @RequestMessage = (SELECT b.Room_id as RoomID, @date as requested_date
							  FROM dbo.[Bookings] AS b
							  left join [Hotel].[dbo].[Rooms] r on r.Room_id = b.Room_id
							  WHERE @date  between b.begin_date and b.end_date
							  AND r.category = @category
							  FOR XML AUTO, root('RequestMessage')); 
	
	
	--������� ������
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//Hotel/SB/InitiatorService] --�� ����� �������(��� ������ ������� ��, ������� �� �� ������)
	TO SERVICE
	'//Hotel/SB/TargetService'    --� ����� �������(��� ������ ������� ����� ���� ���-��, ������� ������)
	ON CONTRACT
	[//Hotel/SB/Contract]         --� ������ ����� ���������
	WITH ENCRYPTION=OFF;        --�� �����������

	--���������� ���� ���� �������������� ���������, �� ����� ��������� � ����� ���������, ������� ����� �������������� ������ ���������������)
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//Hotel/SB/RequestMessage]
	(@RequestMessage);
	
	--��� ��� ������������ - �� ����� ��� �� �����
	SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END
GO

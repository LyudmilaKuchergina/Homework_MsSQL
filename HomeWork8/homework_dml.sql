/*
Задания выполняются с использованием базы данных WideWorldImporters.
Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

 insert into [Sales].[Customers]
 (		   
	  [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
 )
output
	  inserted.[CustomerID]
	, inserted.[CustomerName]
	, inserted.[BillToCustomerID]
	, inserted.[CustomerCategoryID]
	, inserted.[PrimaryContactPersonID]
	, inserted.[DeliveryMethodID]
	, inserted.[DeliveryCityID]
	, inserted.[PostalCityID]
	, inserted.[AccountOpenedDate]
	, inserted.[StandardDiscountPercentage]
	, inserted.[IsStatementSent]
    , inserted.[IsOnCreditHold]
    , inserted.[PaymentDays]
    , inserted.[PhoneNumber]
	, inserted.[FaxNumber]
	, inserted.[WebsiteURL]
    , inserted.[DeliveryAddressLine1]
	, inserted.[DeliveryPostalCode]
	, inserted.[PostalAddressLine1]
	, inserted.[PostalPostalCode]
	, inserted.[LastEditedBy]	
  select 
  	  top (5) [CustomerName] + ' Test'
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	from [Sales].[Customers];

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

delete from [Sales].[Customers]
	where [CustomerID] in 
	(select top (1) [CustomerID] from [Sales].[Customers] where [CustomerName] like '%test%'
	order by [CustomerID])


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update [Sales].[Customers] set [CustomerName] = [CustomerName] + ' update'
	where [CustomerID] in 
	(select top (1) [CustomerID] from [Sales].[Customers] where [CustomerName] like '%test%'
	order by [CustomerID])

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

merge [Sales].[Customers] as target
using (select [CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy] from [Sales].[Customers] where [CustomerName] like '%test%')
as source ([CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
	on target.[CustomerName] = source.[CustomerName]
	when matched then
		update set [CustomerName] = source.[CustomerName] +' Test merge update'
	when not matched then
		insert ([CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
		values (source.[CustomerName] + ' Test merge insert'
      ,source.[BillToCustomerID]
      ,source.[CustomerCategoryID]
      ,source.[BuyingGroupID]
      ,source.[PrimaryContactPersonID]
      ,source.[AlternateContactPersonID]
      ,source.[DeliveryMethodID]
      ,source.[DeliveryCityID]
      ,source.[PostalCityID]
      ,source.[CreditLimit]
      ,source.[AccountOpenedDate]
      ,source.[StandardDiscountPercentage]
      ,source.[IsStatementSent]
      ,source.[IsOnCreditHold]
      ,source.[PaymentDays]
      ,source.[PhoneNumber]
      ,source.[FaxNumber]
      ,source.[DeliveryRun]
      ,source.[RunPosition]
      ,source.[WebsiteURL]
      ,source.[DeliveryAddressLine1]
      ,source.[DeliveryAddressLine2]
      ,source.[DeliveryPostalCode]
      ,source.[DeliveryLocation]
      ,source.[PostalAddressLine1]
      ,source.[PostalAddressLine2]
      ,source.[PostalPostalCode]
      ,source.[LastEditedBy])
	  output inserted.*, $action;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

Exec sp_configure 'show advanced options', 1;
Go
Reconfigure;
Go
Exec sp_configure 'xp_cmdshell', 1;
Reconfigure;
Go

Select @@Servername

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" out "C:\Otus\Customers.txt" -T -w -t"%$ty&" -S HOME-PC\SQL2022'

SELECT [CustomerID]
      ,[CustomerName]
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      ,[ValidFrom]
      ,[ValidTo]
  INTO [WideWorldImporters].[Sales].[Customers_Copy]
  FROM [WideWorldImporters].[Sales].[Customers]
  Where 1 = 2;

  BULK INSERT [WideWorldImporters].[Sales].[Customers_Copy]
	FROM "C:\Otus\Customers.txt"
	WITH (
	batchsize = 1000,
	datafiletype = 'widechar',
	fieldterminator = '%$ty&',
	rowterminator = '\n',
	keepnulls,
	tablock);

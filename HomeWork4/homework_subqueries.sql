/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "03 - ����������, CTE, ��������� �������".
������� ����������� � �������������� ���� ������ WideWorldImporters.
����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak
�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ��� ���� �������, ��� ��������, �������� ��� �������� ��������:
--  1) ����� ��������� ������
--  2) ����� WITH (��� ����������� ������)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

--  1) ����� ��������� ������
SELECT [PersonID] 
      ,[FullName]
  FROM [Application].[People]
  where [IsSalesperson] = 1
  and [PersonID] not in (SELECT
  [SalespersonPersonID]
  FROM [Sales].[Invoices]
  where [InvoiceDate] = '2015-07-04');

--  2) ����� WITH (��� ����������� ������)
with InvoicesCTE as
(SELECT
  [SalespersonPersonID]
  , [InvoiceDate]
  FROM [Sales].[Invoices]
  where [InvoiceDate] = '2015-07-04')

SELECT p.[PersonID] 
      ,p.[FullName]
  FROM [Application].[People] p
  left join InvoicesCTE i on i.[SalespersonPersonID] = p.[PersonID]
  where p.[IsSalesperson] = 1 and i.[InvoiceDate] is NULL;
  
/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/
--  1) ����� ��������� ������
SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems]
 where UnitPrice = (SELECT min(UnitPrice)
 FROM [Warehouse].[StockItems]);

--  2) ����� WITH (��� ����������� ������)
 with MinPriceCTE as
 (SELECT min(UnitPrice) as minUnitPrice
 FROM [Warehouse].[StockItems])

SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems] si
 join MinPriceCTE mp on mp.minUnitPrice = si.UnitPrice;

 --  3)������ ������� ����������
SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems]
 where UnitPrice <= all (SELECT UnitPrice
 FROM [Warehouse].[StockItems]);

/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

--  1) left join 
SELECT TOP (5) ct.[CustomerTransactionID]
      ,ct.[CustomerID]
      ,ct.[TransactionAmount]
	  ,c.[CustomerName]
FROM [Sales].[CustomerTransactions] ct
  left join [Sales].[Customers] c on c.[CustomerID] = ct.CustomerID
order by ct.[TransactionAmount] desc;

--  2) ����� WITH (��� ����������� ������)
 with Top5AmountCTE as
 (SELECT TOP (5) [CustomerTransactionID]
      ,[CustomerID]
      ,[TransactionAmount]
  FROM [Sales].[CustomerTransactions]
  order by [TransactionAmount] desc)

SELECT ct.[CustomerTransactionID]
      ,ct.[CustomerID]
      ,ct.[TransactionAmount]
	  ,c.[CustomerName]
FROM Top5AmountCTE ct
  left join [Sales].[Customers] c on c.[CustomerID] = ct.CustomerID;

--  3) ����� ��������� ������
SELECT ct.[CustomerTransactionID]
      ,ct.[CustomerID]
      ,ct.[TransactionAmount]
	  ,c.[CustomerName]
FROM [Sales].[CustomerTransactions] ct
  left join [Sales].[Customers] c on c.[CustomerID] = ct.CustomerID
  where ct.[CustomerTransactionID] in (SELECT TOP (5) [CustomerTransactionID]
  FROM [Sales].[CustomerTransactions]
  order by [TransactionAmount] desc);


/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/

--  1) ��������� ��������� � in 
SELECT c.DeliveryCityID 
	,cit.CityName
	,p.FullName as PackedByPersonFullName
  FROM  [Warehouse].[StockItemTransactions] sit
  left join [Warehouse].[StockItems] si on si.StockItemID = sit.StockItemID
  left join [Sales].[Invoices] i on i.InvoiceID = sit.InvoiceID 
  left join [Application].[People] p on i.PackedByPersonID = p.PersonID
  left join [Sales].[Customers] c on c.CustomerID = i.CustomerID
  left join [Application].[Cities] cit on cit.CityID = c.DeliveryCityID
  where si.[UnitPrice] in (SELECT TOP (3) [UnitPrice]
  FROM [Warehouse].[StockItems]
  order by [UnitPrice] desc)  and sit.TransactionTypeID = 10
  group by c.DeliveryCityID 
	,cit.CityName
	,p.FullName
	order by c.DeliveryCityID 
	,cit.CityName;

--  2) ��������� ��������� � any
	SELECT c.DeliveryCityID 
	,cit.CityName
	,p.FullName as PackedByPersonFullName
  FROM  [Warehouse].[StockItemTransactions] sit
  left join [Warehouse].[StockItems] si on si.StockItemID = sit.StockItemID
  left join [Sales].[Invoices] i on i.InvoiceID = sit.InvoiceID 
  left join [Application].[People] p on i.PackedByPersonID = p.PersonID
  left join [Sales].[Customers] c on c.CustomerID = i.CustomerID
  left join [Application].[Cities] cit on cit.CityID = c.DeliveryCityID
  where si.[UnitPrice] = any (SELECT TOP (3) [UnitPrice]
  FROM [Warehouse].[StockItems]
  order by [UnitPrice] desc)  and sit.TransactionTypeID = 10
  group by c.DeliveryCityID 
	,cit.CityName
	,p.FullName
	order by c.DeliveryCityID 
	,cit.CityName;

--  3) ����� WITH (��� ����������� ������)

with Top3PriceCTE as
(SELECT TOP (3) [UnitPrice]
  FROM [Warehouse].[StockItems]
  order by [UnitPrice] desc)

SELECT c.DeliveryCityID 
	,cit.CityName
	,p.FullName as PackedByPersonFullName
  FROM  [Warehouse].[StockItemTransactions] sit
  left join [Warehouse].[StockItems] si on si.StockItemID = sit.StockItemID
  join Top3PriceCTE cte on cte.[UnitPrice] = si.[UnitPrice]
  left join [Sales].[Invoices] i on i.InvoiceID = sit.InvoiceID 
  left join [Application].[People] p on i.PackedByPersonID = p.PersonID
  left join [Sales].[Customers] c on c.CustomerID = i.CustomerID
  left join [Application].[Cities] cit on cit.CityID = c.DeliveryCityID
  where sit.TransactionTypeID = 10
  group by c.DeliveryCityID 
	,cit.CityName
	,p.FullName
	order by c.DeliveryCityID 
	,cit.CityName;

-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
�������� ����� ���� �������
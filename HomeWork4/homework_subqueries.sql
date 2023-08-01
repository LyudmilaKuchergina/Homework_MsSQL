/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "03 - Подзапросы, CTE, временные таблицы".
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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--  1) через вложенный запрос
SELECT [PersonID] 
      ,[FullName]
  FROM [Application].[People]
  where [IsSalesperson] = 1
  and [PersonID] not in (SELECT
  [SalespersonPersonID]
  FROM [Sales].[Invoices]
  where [InvoiceDate] = '2015-07-04');

--  2) через WITH (для производных таблиц)
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
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--  1) через вложенный запрос
SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems]
 where UnitPrice = (SELECT min(UnitPrice)
 FROM [Warehouse].[StockItems]);

--  2) через WITH (для производных таблиц)
 with MinPriceCTE as
 (SELECT min(UnitPrice) as minUnitPrice
 FROM [Warehouse].[StockItems])

SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems] si
 join MinPriceCTE mp on mp.minUnitPrice = si.UnitPrice;

 --  3)второй вариант подзапроса
SELECT StockItemID
	,StockItemName
	,UnitPrice
 FROM [Warehouse].[StockItems]
 where UnitPrice <= all (SELECT UnitPrice
 FROM [Warehouse].[StockItems]);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--  1) left join 
SELECT TOP (5) ct.[CustomerTransactionID]
      ,ct.[CustomerID]
      ,ct.[TransactionAmount]
	  ,c.[CustomerName]
FROM [Sales].[CustomerTransactions] ct
  left join [Sales].[Customers] c on c.[CustomerID] = ct.CustomerID
order by ct.[TransactionAmount] desc;

--  2) через WITH (для производных таблиц)
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

--  3) через вложенный запрос
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
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--  1) вложенный подзапрос с in 
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

--  2) вложенный подзапрос с any
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

--  3) через WITH (для производных таблиц)

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
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

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
напишите здесь свое решение
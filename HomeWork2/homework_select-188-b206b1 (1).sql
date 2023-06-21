/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT TOP (1000) [StockItemID]
      ,[StockItemName]
 FROM [Warehouse].[StockItems]
 where [StockItemName] like '%urgent%'
 or [StockItemName] like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT Sup.SupplierID, Sup.SupplierName
  FROM [Purchasing].[Suppliers] Sup
  left join [Purchasing].[PurchaseOrders] Ord on Ord.SupplierID = Sup.SupplierID
  where Ord.SupplierID is null
  order by Sup.SupplierID;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

use [WideWorldImporters]

SELECT  Ord.[OrderID]
		,CONVERT(varchar, Ord.[OrderDate], 104) OrderDate
		,DATENAME(month,[OrderDate]) AS OrderMonth
		,DATEPart(quarter,[OrderDate]) AS OrderQuarter
		,iif(DATEPart(month,[OrderDate]) <= 4, 1, iif(DATEPart(month,[OrderDate]) > 4 and DATEPart(month,[OrderDate]) <= 8, 2, iif(DATEPart(month,[OrderDate]) > 8, 3, 0)))AS OrderThird
		,Cus.[CustomerName]
  FROM [Sales].[OrderLines] OrdLin
  left join [Sales].[Orders] Ord on OrdLin.[OrderID] = Ord.[OrderID]
  left join [Sales].[Customers] Cus on Cus.CustomerID = Ord.CustomerID
  where (OrdLin.[UnitPrice] > 100 or OrdLin.[Quantity] > 20) and OrdLin.[PickingCompletedWhen] is not null
  order by OrderQuarter, OrderThird, Ord.OrderDate
  offset 1000 rows fetch first 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

use [WideWorldImporters]

select 
dm.DeliveryMethodName
,po.ExpectedDeliveryDate
,su.SupplierName
,pe.FullName
from Purchasing.PurchaseOrders po
left join Application.DeliveryMethods dm on dm.DeliveryMethodID = po.DeliveryMethodID
left join Purchasing.Suppliers su on su.SupplierID = po.SupplierID
left join Application.People pe on pe.PersonID = po.ContactPersonID
where ExpectedDeliveryDate >= '2013-01-01' and ExpectedDeliveryDate <= '2013-01-31'
and (dm.DeliveryMethodName = 'Air Freight' or dm.DeliveryMethodName = 'Refrigerated Air Freight')
and po.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT top 10 
inv.InvoiceID as [ID заказа]
,CONVERT(varchar, inv.InvoiceDate, 104) as [Дата продажи]
,cus.CustomerName as [Клиент]
,peo.FullName as [Сотрудник оформивший заказ]
FROM [Sales].[Invoices] inv 
left join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
left join [Application].[People] peo on peo.[PersonID] = inv.SalespersonPersonID
order by inv.InvoiceDate desc, 
inv.InvoiceID desc;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT distinct
inv.CustomerID as [ID клиента]
,cus.CustomerName as [Имя клиента]
,cus.PhoneNumber as [Номер телефона клиента]
  FROM [WideWorldImporters].[Sales].[Invoices] inv
  left join [WideWorldImporters].[Sales].[InvoiceLines] il on il.InvoiceID = inv.InvoiceID 
  join [WideWorldImporters].[Warehouse].[StockItems] si on si.[StockItemID] = il.[StockItemID] and si.StockItemName = 'Chocolate frogs 250g'
  left join [WideWorldImporters].[Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
  order by inv.CustomerID

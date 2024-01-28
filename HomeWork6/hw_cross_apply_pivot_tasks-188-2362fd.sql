/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

	USE WideWorldImporters;

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select * from (
SELECT SUBSTRING(cus.CustomerName, 16, len(cus.CustomerName) - 16) as [Название клиента]
	  ,isNull(il.Quantity, 0) as [Количество]
	  ,DATEADD(day, 1 - DAY(inv.[InvoiceDate]), inv.[InvoiceDate]) as [Начало месяца]
  FROM [Sales].[Invoices] inv
	join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
where inv.[CustomerID] in (2,3,4,5,6)
) sel
pivot (sum([Количество])
for [Название клиента] in ([Peeples Valley, AZ], [Medicine Lodge, KS] , [Gasport, NY], [Sylvanite, MT], [Jessie, ND]))
as PVT_My
order by [Начало месяца]

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
select * from (
select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2 from 
[Sales].[Customers]
where CustomerName like '%Tailspin Toys%'
) as sel
unpivot (AddressLine for AdrressName in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) as unpv;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select * from
(
SELECT [CountryID]
      ,[CountryName]
     --,[IsoAlpha3Code]
	  ,isNULL(cast([IsoAlpha3Code] AS nvarchar),'') [IsoAlpha3Code]
	  ,isNULL(cast([IsoNumericCode] AS nvarchar),'') [IsoNumericCode]
  FROM [Application].[Countries]
  ) as sel
unpivot (Code for CountryName1 in ([IsoAlpha3Code],[IsoNumericCode])) as unpv;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

use [WideWorldImporters];

Select  cust.CustomerID [Id клиента]
	  , cust.CustomerName [Название клиента]
	  , ca.StockItemID [id товара]
	  , ca.[Цена] 
	  , ca.InvoiceDate 
	  from
[Sales].[Customers] cust
cross apply
	(SELECT distinct Top 2 il.StockItemID
	  ,il.UnitPrice as [Цена]
	  ,inv.CustomerID
	  ,max(inv.InvoiceDate) InvoiceDate
		FROM [Sales].[Invoices] inv
		join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID 
		where inv.CustomerID = cust.CustomerID
	group by il.StockItemID
	  ,il.UnitPrice, inv.CustomerID
	order by [Цена]  desc) as ca
order by [Id клиента], [Цена] desc

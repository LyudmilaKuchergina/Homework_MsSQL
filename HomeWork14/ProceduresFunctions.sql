/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "18 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION [Sales].[MaxInvoiceCustomer]()
RETURNS nvarchar(100)
AS
BEGIN
	Declare @Result nvarchar(100);
	select @Result = 
	(
	select top 1 [Название клиента] from(
	select 
		cus.CustomerName as [Название клиента]
		, sum(il.ExtendedPrice) as [Сумма покупки]
		,RANK() OVER (ORDER BY sum(il.ExtendedPrice) DESC) Rank_sum
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	group by inv.InvoiceID, cus.CustomerName
	) sel
	where Rank_sum = 1)

	Return @Result;
END;

select [Sales].[MaxInvoiceCustomer]() as 'MaxInvoiceCustomer'

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE FUNCTION [Sales].[SumBySelectedCustomer](@CustomerID int)
RETURNS decimal(18,2)
AS
BEGIN
	Declare @Result decimal(18,2);
	select @Result = 
	(
	select [Сумма покупки] from(
	select 
		cus.CustomerName as [Название клиента]
		,inv.CustomerID
		, sum(il.ExtendedPrice) as [Сумма покупки]
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	where inv.CustomerID = @CustomerID
	group by cus.CustomerName, inv.CustomerID
	) sel
	)

	Return @Result;
END;

select [Sales].[SumBySelectedCustomer](834) as 'SumBySelectedCustomer'

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

--Вывести список самого популярного продукта (по количеству проданных) 
--в каждом месяце за 2015 год (по 1 популярному продукту в каждом месяце).

CREATE FUNCTION [Sales].[f_PopularProduct]()
RETURNS table
AS
RETURN
	(
select sel2.* from
(
select 
    sel.[Год месяц продажи]
  , sel.[id продукта]
  , sel.[Название продукта]
  , sel.[Количество]
  , row_number() over (partition by sel.[Год месяц продажи] order by sel.[Количество] desc) as [Место по популярности]
from 
(
	select
		format(inv.InvoiceDate, 'yyyyMM') as [Год месяц продажи] 
		 ,il.StockItemID as [id продукта]
		, il.Description as [Название продукта]
		, sum(il.Quantity) as [Количество]
	from Sales.[InvoiceLines] il
	join [Sales].Invoices inv  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	and inv.InvoiceDate <= '20151231'
	group by format(inv.InvoiceDate, 'yyyyMM') 
		 ,il.StockItemID
		, il.Description	
 ) sel
) sel2
where sel2.[Место по популярности] in (1)
);

CREATE OR ALTER PROCEDURE [Sales].[p_PopularProduct]
AS
BEGIN
SET NOCOUNT ON

select sel2.* from
(
select 
    sel.[Год месяц продажи]
  , sel.[id продукта]
  , sel.[Название продукта]
  , sel.[Количество]
  , row_number() over (partition by sel.[Год месяц продажи] order by sel.[Количество] desc) as [Место по популярности]
from 
(
	select
		format(inv.InvoiceDate, 'yyyyMM') as [Год месяц продажи] 
		 ,il.StockItemID as [id продукта]
		, il.Description as [Название продукта]
		, sum(il.Quantity) as [Количество]
	from Sales.[InvoiceLines] il
	join [Sales].Invoices inv  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	and inv.InvoiceDate <= '20151231'
	group by format(inv.InvoiceDate, 'yyyyMM') 
		 ,il.StockItemID
		, il.Description	
) sel
) sel2
where sel2.[Место по популярности] in (1)
order by [Год месяц продажи], [Количество] desc;
END;

set statistics time, io on

SELECT * from [Sales].[f_PopularProduct]()
order by [Год месяц продажи], [Количество] desc;

EXEC [Sales].[p_PopularProduct];


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

-- Все клиенты с 2 последними их покупками

CREATE FUNCTION [Sales].[LastInvoicesCustomers](@CustomerID int)
RETURNS table
AS
RETURN
	(
SELECT sel.[id клиента]
	 , sel.[InvoiceID]
	 , sel.[Дата покупки]
	 , sum(il.ExtendedPrice) as [Сумма покупки] 
FROM 
(
SELECT inv.[InvoiceID]
      ,inv.[CustomerID] as [id клиента]
      ,inv.[InvoiceDate]  as [Дата покупки]
	  ,dense_rank() over (partition by inv.[CustomerID] order by inv.[InvoiceDate] desc, inv.[InvoiceID] desc) as [Номер покупки]	
  FROM [Sales].[Invoices] inv  where inv.CustomerID = @CustomerID
) sel
join [Sales].[InvoiceLines] il  on il.InvoiceID = sel.InvoiceID
where sel.[Номер покупки] in (1,2)
group by  sel.[id клиента]
		, sel.[InvoiceID]
		, sel.[Дата покупки]
	);


SELECT cus.CustomerName [Название клиента], c.*
FROM [Sales].[Customers] cus
CROSS APPLY [Sales].[LastInvoicesCustomers](cus.CustomerID) c
order by c.[id клиента], c.[Дата покупки] desc;





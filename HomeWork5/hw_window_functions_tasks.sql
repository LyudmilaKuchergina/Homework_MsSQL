/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
use [WideWorldImporters];
select    sel.[id продажи]
		, sel.[Название клиента]
		, sel.[Дата продажи]
		, sel.[Сумма продажи]
		, (select sum(il2.ExtendedPrice) from Sales.Invoices inv2
		join [Sales].[InvoiceLines] il2  on il2.InvoiceID = inv2.InvoiceID
		where sel.[Год месяц продажи]>=cast(format(inv2.InvoiceDate, 'yyyyMM') as int)
		and inv2.InvoiceDate >= '20150101'
		) as [Сумма нарастающим итогом]
from
(
	select
		inv.InvoiceID  as [id продажи]
		,cus.CustomerName as [Название клиента]
		, inv.InvoiceDate as [Дата продажи]
		, sum(il.ExtendedPrice) as [Сумма продажи]
		, cast(format(inv.InvoiceDate, 'yyyyMM') as int) as [Год месяц продажи]
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	
	group by inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cast(format(inv.InvoiceDate, 'yyyyMM') as int)
) sel
order by sel.[Дата продажи], sel.[id продажи];

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
use [WideWorldImporters];
	select distinct
		inv.InvoiceID  as [id продажи]
		,cus.CustomerName as [Название клиента]
		, inv.InvoiceDate as [Дата продажи]
		, sum(il.ExtendedPrice) over (partition by il.InvoiceID) as [Сумма продажи]	
		, sum(il.ExtendedPrice) over (order by format(inv.InvoiceDate, 'yyyyMM')) as [Сумма нарастающим итогом]
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	
	order by [Дата продажи], [id продажи];

-- Без оконных функций: Время ЦП = 217281 мс, затраченное время = 246485 мс.
-- С оконными функциями: Время ЦП = 1500 мс, затраченное время = 2064 мс. 

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

use [WideWorldImporters];
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
	where inv.InvoiceDate >= '20160101'	and inv.InvoiceDate <= '20161231'
	group by format(inv.InvoiceDate, 'yyyyMM') 
		 ,il.StockItemID
		, il.Description	
) sel
) sel2
where sel2.[Место по популярности] in (1,2)
order by sel2.[Год месяц продажи], sel2.[Количество] desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
 пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
 посчитайте общее количество товаров и выведете полем в этом же запросе
 посчитайте общее количество товаров в зависимости от первой буквы названия товара
 отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
 предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
 сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

use [WideWorldImporters];
SELECT [StockItemID] as [id товара]
      ,[StockItemName] as [Название]
	  ,left([StockItemName], 1) as [Первая буква]
      ,[Brand] as [Брэнд]
      ,[UnitPrice] as [Цена]
      ,[TypicalWeightPerUnit] as [Вес товара на 1 шт.]
	  ,row_number() over (partition by left([StockItemName], 1) order by [StockItemName]) as [Нумерация товара по первой букве]
	  ,count([StockItemID]) over () as [Общее количество товаров]
	  ,count([StockItemID]) over (partition by left([StockItemName], 1)) as [Количество товара по первой букве]
	  ,lead([StockItemID],1) over (order by [StockItemName]) as [Следующий id товара по названию]
	  ,lag([StockItemID],1) over (order by [StockItemName]) as [Предыдущий id товара по названию]
	  ,coalesce(lag([StockItemName],2) over (order by [StockItemName]), 'No items') as [Название 2 строки назад по названию]
	  ,ntile(30) over (order by [TypicalWeightPerUnit]) as [Группа товара по весу]
  FROM [Warehouse].[StockItems]
  order by [StockItemName]

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

use [WideWorldImporters];
select sel.[id клиента]
	, sel.[Название клиента]
	, sel.[id сотрудника]
	, sel.[ФИО сотрудника]
	, sel.[Дата продажи]
	, sel.[Сумма сделки] from
(
SELECT distinct inv.[InvoiceID]
      ,inv.[CustomerID] as [id клиента]
	  ,cus.CustomerName as [Название клиента]
      ,inv.[SalespersonPersonID] as [id сотрудника]
	  ,peop.[FullName] as [ФИО сотрудника]
	  ,sum(il.ExtendedPrice) over (partition by il.InvoiceID) as [Сумма сделки]	
      ,inv.[InvoiceDate]  as [Дата продажи]
	  ,dense_rank() over (partition by inv.[SalespersonPersonID] order by inv.[InvoiceDate] desc, inv.[InvoiceID] desc) as [Номер клиента]
  FROM [Sales].[Invoices] inv
	join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
	join [Application].[People] peop on peop.[PersonID] = inv.[SalespersonPersonID]
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
) sel
where sel.[Номер клиента] = 1
order by sel.[id сотрудника], sel.[Дата продажи]

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

use [WideWorldImporters];

select sel.[id клиента]
		, sel.[Название клиента]
		, sel.[id товара]
		, sel.[Цена]
		, max(sel.[Дата покупки]) as [Дата покупки] from 
(
SELECT inv.[InvoiceID]
      ,inv.[CustomerID] as [id клиента]
	  ,cus.CustomerName as [Название клиента]
	  , il.StockItemID as [id товара]
	  ,il.UnitPrice as [Цена]
      ,inv.[InvoiceDate]  as [Дата покупки]
	  ,dense_rank() over (partition by inv.[CustomerID] order by il.UnitPrice desc, il.StockItemID desc) as [Номер клиента]	
	  ,il.InvoiceLineID
  FROM [Sales].[Invoices] inv
	join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
) sel
where sel.[Номер клиента] in (1,2)
group by sel.[id клиента]
		, sel.[Название клиента]
		, sel.[id товара]
		, sel.[Цена]
order by sel.[id клиента], sel.[Цена] desc ,[Дата покупки] desc

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
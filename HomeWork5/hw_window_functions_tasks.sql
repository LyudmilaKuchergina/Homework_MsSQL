/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "06 - ������� �������".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters
/*
1. ������� ������ ����� ������ ����������� ������ �� ������� � 2015 ���� 
(� ������ ������ ������ �� ����� ����������, ��������� ����� � ������� ������� �������).
��������: id �������, �������� �������, ���� �������, ����� �������, ����� ����������� ������

������:
-------------+----------------------------
���� ������� | ����������� ���� �� ������
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
������� ����� ����� �� ������� Invoices.
����������� ���� ������ ���� ��� ������� �������.
*/
use [WideWorldImporters];
select    sel.[id �������]
		, sel.[�������� �������]
		, sel.[���� �������]
		, sel.[����� �������]
		, (select sum(il2.ExtendedPrice) from Sales.Invoices inv2
		join [Sales].[InvoiceLines] il2  on il2.InvoiceID = inv2.InvoiceID
		where sel.[��� ����� �������]>=cast(format(inv2.InvoiceDate, 'yyyyMM') as int)
		and inv2.InvoiceDate >= '20150101'
		) as [����� ����������� ������]
from
(
	select
		inv.InvoiceID  as [id �������]
		,cus.CustomerName as [�������� �������]
		, inv.InvoiceDate as [���� �������]
		, sum(il.ExtendedPrice) as [����� �������]
		, cast(format(inv.InvoiceDate, 'yyyyMM') as int) as [��� ����� �������]
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	
	group by inv.InvoiceID, cus.CustomerName, inv.InvoiceDate, cast(format(inv.InvoiceDate, 'yyyyMM') as int)
) sel
order by sel.[���� �������], sel.[id �������];

/*
2. �������� ������ ����� ����������� ������ � ���������� ������� � ������� ������� �������.
   �������� ������������������ �������� 1 � 2 � ������� set statistics time, io on
*/
use [WideWorldImporters];
	select distinct
		inv.InvoiceID  as [id �������]
		,cus.CustomerName as [�������� �������]
		, inv.InvoiceDate as [���� �������]
		, sum(il.ExtendedPrice) over (partition by il.InvoiceID) as [����� �������]	
		, sum(il.ExtendedPrice) over (order by format(inv.InvoiceDate, 'yyyyMM')) as [����� ����������� ������]
	from Sales.Invoices inv
	join [Sales].[Customers] cus on cus.CustomerID=inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20150101'	
	order by [���� �������], [id �������];

-- ��� ������� �������: ����� �� = 217281 ��, ����������� ����� = 246485 ��.
-- � �������� ���������: ����� �� = 1500 ��, ����������� ����� = 2064 ��. 

/*
3. ������� ������ 2� ����� ���������� ��������� (�� ���������� ���������) 
� ������ ������ �� 2016 ��� (�� 2 ����� ���������� �������� � ������ ������).
*/

use [WideWorldImporters];
select sel2.* from
(
select 
    sel.[��� ����� �������]
  , sel.[id ��������]
  , sel.[�������� ��������]
  , sel.[����������]
  , row_number() over (partition by sel.[��� ����� �������] order by sel.[����������] desc) as [����� �� ������������]
from 
(
	select
		format(inv.InvoiceDate, 'yyyyMM') as [��� ����� �������] 
		 ,il.StockItemID as [id ��������]
		, il.Description as [�������� ��������]
		, sum(il.Quantity) as [����������]
	from Sales.[InvoiceLines] il
	join [Sales].Invoices inv  on il.InvoiceID = inv.InvoiceID
	where inv.InvoiceDate >= '20160101'	and inv.InvoiceDate <= '20161231'
	group by format(inv.InvoiceDate, 'yyyyMM') 
		 ,il.StockItemID
		, il.Description	
) sel
) sel2
where sel2.[����� �� ������������] in (1,2)
order by sel2.[��� ����� �������], sel2.[����������] desc

/*
4. ������� ����� ��������
���������� �� ������� ������� (� ����� ����� ������ ������� �� ������, ��������, ����� � ����):
 ������������ ������ �� �������� ������, ��� ����� ��� ��������� ����� �������� ��������� ���������� ������
 ���������� ����� ���������� ������� � �������� ����� � ���� �� �������
 ���������� ����� ���������� ������� � ����������� �� ������ ����� �������� ������
 ���������� ��������� id ������ ������ �� ����, ��� ������� ����������� ������� �� ����� 
 ���������� �� ������ � ��� �� �������� ����������� (�� �����)
* �������� ������ 2 ������ �����, � ������ ���� ���������� ������ ��� ����� ������� "No items"
 ����������� 30 ����� ������� �� ���� ��� ������ �� 1 ��

��� ���� ������ �� ����� ������ ������ ��� ������������� �������.
*/

use [WideWorldImporters];
SELECT [StockItemID] as [id ������]
      ,[StockItemName] as [��������]
	  ,left([StockItemName], 1) as [������ �����]
      ,[Brand] as [�����]
      ,[UnitPrice] as [����]
      ,[TypicalWeightPerUnit] as [��� ������ �� 1 ��.]
	  ,row_number() over (partition by left([StockItemName], 1) order by [StockItemName]) as [��������� ������ �� ������ �����]
	  ,count([StockItemID]) over () as [����� ���������� �������]
	  ,count([StockItemID]) over (partition by left([StockItemName], 1)) as [���������� ������ �� ������ �����]
	  ,lead([StockItemID],1) over (order by [StockItemName]) as [��������� id ������ �� ��������]
	  ,lag([StockItemID],1) over (order by [StockItemName]) as [���������� id ������ �� ��������]
	  ,coalesce(lag([StockItemName],2) over (order by [StockItemName]), 'No items') as [�������� 2 ������ ����� �� ��������]
	  ,ntile(30) over (order by [TypicalWeightPerUnit]) as [������ ������ �� ����]
  FROM [Warehouse].[StockItems]
  order by [StockItemName]

/*
5. �� ������� ���������� �������� ���������� �������, �������� ��������� ���-�� ������.
   � ����������� ������ ���� �� � ������� ����������, �� � �������� �������, ���� �������, ����� ������.
*/

use [WideWorldImporters];
select sel.[id �������]
	, sel.[�������� �������]
	, sel.[id ����������]
	, sel.[��� ����������]
	, sel.[���� �������]
	, sel.[����� ������] from
(
SELECT distinct inv.[InvoiceID]
      ,inv.[CustomerID] as [id �������]
	  ,cus.CustomerName as [�������� �������]
      ,inv.[SalespersonPersonID] as [id ����������]
	  ,peop.[FullName] as [��� ����������]
	  ,sum(il.ExtendedPrice) over (partition by il.InvoiceID) as [����� ������]	
      ,inv.[InvoiceDate]  as [���� �������]
	  ,dense_rank() over (partition by inv.[SalespersonPersonID] order by inv.[InvoiceDate] desc, inv.[InvoiceID] desc) as [����� �������]
  FROM [Sales].[Invoices] inv
	join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
	join [Application].[People] peop on peop.[PersonID] = inv.[SalespersonPersonID]
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
) sel
where sel.[����� �������] = 1
order by sel.[id ����������], sel.[���� �������]

/*
6. �������� �� ������� ������� ��� ����� ������� ������, ������� �� �������.
� ����������� ������ ���� �� ������, ��� ��������, �� ������, ����, ���� �������.
*/

use [WideWorldImporters];

select sel.[id �������]
		, sel.[�������� �������]
		, sel.[id ������]
		, sel.[����]
		, max(sel.[���� �������]) as [���� �������] from 
(
SELECT inv.[InvoiceID]
      ,inv.[CustomerID] as [id �������]
	  ,cus.CustomerName as [�������� �������]
	  , il.StockItemID as [id ������]
	  ,il.UnitPrice as [����]
      ,inv.[InvoiceDate]  as [���� �������]
	  ,dense_rank() over (partition by inv.[CustomerID] order by il.UnitPrice desc, il.StockItemID desc) as [����� �������]	
	  ,il.InvoiceLineID
  FROM [Sales].[Invoices] inv
	join [Sales].[Customers] cus on cus.CustomerID = inv.CustomerID
	join [Sales].[InvoiceLines] il  on il.InvoiceID = inv.InvoiceID
) sel
where sel.[����� �������] in (1,2)
group by sel.[id �������]
		, sel.[�������� �������]
		, sel.[id ������]
		, sel.[����]
order by sel.[id �������], sel.[����] desc ,[���� �������] desc

--����������� ������ ��� ������� ������� ��� ������� ������� ������� ������� �������� � �������� ��������� � �������� �� ������������������. 
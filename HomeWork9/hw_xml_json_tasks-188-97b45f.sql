/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

---- OPENXML

declare @xmlDocument XML;
 select @xmlDocument = BulkColumn
 from OpenRowSet
 (Bulk 'C:\Users\Lyuda\Documents\StockItems-188-1fb5df.xml', SINGLE_CLOB) as Data;

Select @xmlDocument as [@xmlDocument];

declare @docHandle int;
exec sp_xml_preparedocument @docHandle output, @xmlDocument;
select @docHandle as docHandle;

MERGE [Warehouse].[StockItems] AS target
USING (select * from openXML(@docHandle, 'StockItems/Item',2)
with (
StockItemName nvarchar(100) '@Name'
, SupplierID int 'SupplierID'
, UnitPackageID int 'Package/UnitPackageID'
, OuterPackageID int 'Package/OuterPackageID'
, QuantityPerOuter int 'Package/QuantityPerOuter'
, TypicalWeightPerUnit decimal(18,3) 'Package/TypicalWeightPerUnit'
, LeadTimeDays int 'LeadTimeDays'
, IsChillerStock bit 'IsChillerStock'
, TaxRate decimal(18,3) 'TaxRate'
, UnitPrice decimal(18,2) 'UnitPrice'
)
) AS source (StockItemName
, SupplierID
, UnitPackageID
, OuterPackageID
, QuantityPerOuter
, TypicalWeightPerUnit
, LeadTimeDays
, IsChillerStock
, TaxRate
, UnitPrice)
    ON target.StockItemName = source.StockItemName
WHEN MATCHED THEN 
    UPDATE SET   OuterPackageID = source.OuterPackageID
				,QuantityPerOuter = source.QuantityPerOuter
				,TypicalWeightPerUnit = source.TypicalWeightPerUnit
				,LeadTimeDays = source.LeadTimeDays
				,IsChillerStock = source.IsChillerStock
				,TaxRate = source.TaxRate
				,UnitPrice = source.UnitPrice
WHEN NOT MATCHED THEN
    INSERT (StockItemName
, SupplierID
, UnitPackageID
, OuterPackageID
, QuantityPerOuter
, TypicalWeightPerUnit
, LeadTimeDays
, IsChillerStock
, TaxRate
, UnitPrice
, LastEditedBy) 
 values
 (source.StockItemName
, source.SupplierID
, source.UnitPackageID
, source.OuterPackageID
, source.QuantityPerOuter
, source.TypicalWeightPerUnit
, source.LeadTimeDays
, source.IsChillerStock
, source.TaxRate
, source.UnitPrice
, 1);

---- XQuery

declare @x XML;
set @x = (
select * from OPENROWSET
	(Bulk 'C:\Users\Lyuda\Documents\StockItems-188-1fb5df.xml', SINGLE_CLOB) as d);
/*
select 
 t.Item.value('@Name[1]', 'nvarchar(100)') as [StockItemName],
 t.Item.value('SupplierID[1]', 'int') as [SupplierID],
 t.Item.value('(Package/UnitPackageID)[1]', 'int') as [UnitPackageID],
 t.Item.value('(Package/OuterPackageID)[1]', 'int') as [OuterPackageID],
 t.Item.value('(Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter],
 t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit],
 t.Item.value('LeadTimeDays[1]', 'int') as [LeadTimeDays],
 t.Item.value('IsChillerStock[1]', 'bit') as [IsChillerStock],
 t.Item.value('TaxRate[1]', 'decimal(18,3)') as [TaxRate],
 t.Item.value('UnitPrice[1]', 'decimal(18,2)') as [UnitPrice]
-- t.Item.query('.')
 from @x.nodes('StockItems/Item') as t(Item);*/

 MERGE [Warehouse].[StockItems] AS target
USING (select 
 t.Item.value('@Name[1]', 'nvarchar(100)') as [StockItemName],
 t.Item.value('SupplierID[1]', 'int') as [SupplierID],
 t.Item.value('(Package/UnitPackageID)[1]', 'int') as [UnitPackageID],
 t.Item.value('(Package/OuterPackageID)[1]', 'int') as [OuterPackageID],
 t.Item.value('(Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter],
 t.Item.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit],
 t.Item.value('LeadTimeDays[1]', 'int') as [LeadTimeDays],
 t.Item.value('IsChillerStock[1]', 'bit') as [IsChillerStock],
 t.Item.value('TaxRate[1]', 'decimal(18,3)') as [TaxRate],
 t.Item.value('UnitPrice[1]', 'decimal(18,2)') as [UnitPrice]
 from @x.nodes('StockItems/Item') as t(Item)
) AS source (
StockItemName
, SupplierID
, UnitPackageID
, OuterPackageID
, QuantityPerOuter
, TypicalWeightPerUnit
, LeadTimeDays
, IsChillerStock
, TaxRate
, UnitPrice)
    ON target.StockItemName = source.StockItemName
WHEN MATCHED THEN 
    UPDATE SET   OuterPackageID = source.OuterPackageID
				,QuantityPerOuter = source.QuantityPerOuter
				,TypicalWeightPerUnit = source.TypicalWeightPerUnit
				,LeadTimeDays = source.LeadTimeDays
				,IsChillerStock = source.IsChillerStock
				,TaxRate = source.TaxRate
				,UnitPrice = source.UnitPrice
WHEN NOT MATCHED THEN
    INSERT (StockItemName
, SupplierID
, UnitPackageID
, OuterPackageID
, QuantityPerOuter
, TypicalWeightPerUnit
, LeadTimeDays
, IsChillerStock
, TaxRate
, UnitPrice
, LastEditedBy) 
 values
 (source.StockItemName
, source.SupplierID
, source.UnitPackageID
, source.OuterPackageID
, source.QuantityPerOuter
, source.TypicalWeightPerUnit
, source.LeadTimeDays
, source.IsChillerStock
, source.TaxRate
, source.UnitPrice
, 1);

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
select
  StockItemName as [@Name]
, SupplierID
, UnitPackageID as [Package/UnitPackageID]
, OuterPackageID as [Package/OuterPackageID]
, QuantityPerOuter as [Package/QuantityPerOuter]
, TypicalWeightPerUnit as [Package/TypicalWeightPerUnit]
, LeadTimeDays
, IsChillerStock
, TaxRate
, UnitPrice
from [Warehouse].[StockItems] for xml path('Item'), root('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
   StockItemID
  ,StockItemName
  ,json_value(CustomFields, '$.CountryOfManufacture') as [CountryOfManufacture]
  ,json_value(CustomFields, '$.Tags[0]') as [FirstTag]
from [Warehouse].[StockItems]

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select 
   StockItemID
   ,StockItemName
   ,isnull(json_value(CustomFields, '$.Tags[0]'),'')+ isnull(', '+json_value(CustomFields, '$.Tags[1]'),'')
   + isnull(', '+json_value(CustomFields, '$.Tags[2]'),'')as [Tags]
   ,CA_Tags.[Key]
   ,CA_Tags.Value
from [Warehouse].[StockItems]
CROSS APPLY OpenJSON(CustomFields, '$.Tags') CA_Tags
where CA_Tags.Value = 'Vintage'

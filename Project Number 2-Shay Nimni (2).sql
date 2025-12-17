--***Shay Nimni Project Num 2- Solving Analytical Questions***--

----** Ex 1
with cte1
as(
select YEAR(InvoiceDate) as 'Year',
SUM(sl.ExtendedPrice-sl.TaxAmount)as 'IncomePerYear',
COUNT(distinct MONTH(si.invoicedate))as 'NumberOfDistinctMonths',
convert(decimal(10,2),(SUM(sl.UnitPrice*sl.Quantity)/ COUNT(distinct MONTH(si.invoicedate)))*12 ) as'YearlyLinearIncome'
from Sales.Invoices si join Sales.InvoiceLines sl
on si.InvoiceID= sl.InvoiceID
group by year(InvoiceDate)
)
select Year, IncomePerYear,NumberOfDistinctMonths,YearlyLinearIncome,
convert(decimal(10,2),((YearlyLinearIncome- LAG(YearlyLinearIncome,1) over(order by year))/
LAG(YearlyLinearIncome,1) over(order by year))*100) as 'GrowthRate'
from cte1
order by YEAR

--** Ex 2
with cte1
as
(
select YEAR(si.InvoiceDate)as 'TheYear',
DATEPART(QQ,si.InvoiceDate) as 'TheQuarter',
sc.CustomerName,
SUM(sl.ExtendedPrice-sl.TaxAmount) as 'IncomePerYear'
from Sales.Customers sc join Sales.Invoices si
on sc.CustomerID= si.CustomerID
join Sales.InvoiceLines sl
on si.InvoiceID= sl.InvoiceID
Group by YEAR(si.InvoiceDate),DATEPART(QQ,si.InvoiceDate),sc.CustomerName
),
cte2
as
(
select*
from(select TheYear,TheQuarter,CustomerName,IncomePerYear,
     ROW_NUMBER() over(partition by theyear,thequarter order by incomeperyear desc)as 'DNR'
     from cte1)o
where DNR<=5
)
select c1.TheYear,c1.TheQuarter,c1.CustomerName,c1.IncomePerYear,c2.DNR
from cte1 c1 join cte2 c2
on c1.IncomePerYear= c2.IncomePerYear
order by TheYear,TheQuarter,DNR

--** EX 3
with cte1
as
(
select ws.StockItemID, ws.StockItemName,SUM(si.ExtendedPrice-si.TaxAmount) as TotalProfit
from Warehouse.StockItems ws join Sales.InvoiceLines si
on ws.StockItemID = si.StockItemID
group by ws.StockItemID, ws.StockItemName
)

select top 10 StockItemID,StockItemName, TotalProfit
from cte1
order by TotalProfit desc

--** EX 4
with cte1
as
(
select ws.StockItemID,ws.StockItemName,ws.UnitPrice, ws.RecommendedRetailPrice,
(ws.RecommendedRetailPrice-ws.UnitPrice) as 'NominalProductProfit'
from Warehouse.StockItems ws 
where ws.ValidTo > GETDATE()
group by ws.StockItemID,ws.StockItemName,ws.RecommendedRetailPrice,ws.UnitPrice
)
select ROW_NUMBER() over(order by DNR) as RN,*
from (select *,DENSE_RANK() over(order by NominalProductProfit desc) as DNR
      from cte1)o

--** EX 5
with cte_sup
as
(
select*
from (select distinct SupplierID,SupplierName 
      from Purchasing.Suppliers)o
),
cte_pro
as
(
select StockItemID,StockItemName,SupplierID
from Warehouse.StockItems 
)

select CONCAT(cs.SupplierID,' - ',cs.SupplierName) as 'SupplierDetails',
STRING_AGG(CONCAT(cp.StockItemID,' ',cp.StockItemName),'/,') as 'ProductDetails'
from cte_sup cs join cte_pro cp
on cs.SupplierID= cp.SupplierID
group by CONCAT(cs.SupplierID,' - ',cs.SupplierName),cs.SupplierID
order by cs.SupplierID

-- EX 6
 select top 5 sc.CustomerID,ac.CityName,pc.CountryName,pc.Continent,pc.Region,
 SUM(sl.ExtendedPrice)as 'TotalExtendedPrice'
 from sales.InvoiceLines sl join sales.Invoices si
 on sl.InvoiceID= si.InvoiceID
 join Sales.Customers sc
 on si.CustomerID= sc.CustomerID
 join Application.Cities ac
 on sc.PostalCityID= ac.CityID
 join Application.StateProvinces ap
 on ac.StateProvinceID= ap.StateProvinceID
 join Application.Countries pc
 on ap.CountryID= pc.CountryID
 group by sc.CustomerID,ac.CityName,pc.CountryName,pc.Continent,pc.Region
 order by TotalExtendedPrice desc

 --EX 7
with cte_MonthlySales
as
(
select YEAR(so.OrderDate) as OrderYear,MONTH(so.OrderDate) as OrderMonth,
SUM(il.ExtendedPrice-il.TaxAmount) as MonthlyAmount
from Sales.InvoiceLines il join Sales.Invoices si
on il.InvoiceID= si.InvoiceID
join  Sales.Orders so
on si.OrderID= so.OrderID
group by YEAR(OrderDate),MONTH(OrderDate)
union all
select YEAR(so.OrderDate), null as OrderMonth, 
SUM(il.ExtendedPrice-il.TaxAmount) as MonthlyAmount
from Sales.InvoiceLines il join Sales.Invoices si
on il.InvoiceID= si.InvoiceID
join  Sales.Orders so
on si.OrderID= so.OrderID
group by YEAR(so.OrderDate)
)

select OrderYear,
ISNULL(CAST(OrderMonth as varchar),'GrandTotal')as OrderMonth,
FORMAT(MonthlyAmount,'N2') as MonthlyAmount,
FORMAT(SUM(MonthlyAmount) over(partition by orderyear order by case when ordermonth is null then 13 else ordermonth end),'N2')as CumulativeTotal
from cte_MonthlySales
order by OrderYear,case when ordermonth is null then 13 else ordermonth end

 --EX 8
 select OrderMonth,[2013],[2014],[2015],[2016]
 from (select YEAR(OrderDate) as Year,MONTH(OrderDate) as OrderMonth,OrderID
       from sales.Orders)o
 pivot(count(orderid) for Year in ([2013],[2014],[2015],[2016]))p
 order by 1

 --EX 9
with cte_orders
as
(
 select sc.CustomerID,sc.CustomerName,so.OrderDate,
 LAG(so.OrderDate,1) over (partition by sc.customerid order by so.orderdate) as PreviousOrderDate,
 DATEDIFF(DAY, LAG(OrderDate) OVER (PARTITION BY sc.CustomerID ORDER BY so.OrderDate), OrderDate) as DaysSinceLastOrder
from sales.Orders so join Sales.Customers sc
on so.CustomerID= sc.CustomerID
)
select CustomerID,CustomerName,OrderDate,PreviousOrderDate,DaysSinceLastOrder,
AVG(DaysSinceLastOrder) over (partition by CustomerID) as AvgDaysBetweenOrders,
case
           when AVG(DaysSinceLastOrder) over (partition by CustomerID) >= DaysSinceLastOrder 
           then 'Active'
           else 'Potential Churn'
       end as CustomerStatus
from cte_orders
group by CustomerID,CustomerName,OrderDate,PreviousOrderDate,DaysSinceLastOrder
order by CustomerID,CustomerName

--EX 10
With cte_group
as 
(
    select 
        cc.CustomerCategoryName,
        case 
            when sc.CustomerName like 'Tailspin%' then 'Tailspin'
            when sc.CustomerName like 'Wingtip%' then 'Wingtip'
            else sc.CustomerName
        end as GroupCustomerName
    from Sales.Customers sc
    join Sales.CustomerCategories cc
        on sc.CustomerCategoryID = cc.CustomerCategoryID
), 
cte_count 
as 
(
    select 
        CustomerCategoryName,
        COUNT(DISTINCT GroupCustomerName) as CustomerCOUNT
    from cte_group
    group by CustomerCategoryName
)
select
    CustomerCategoryName,
    CustomerCOUNT,
    SUM(CustomerCOUNT) OVER () as TotalCustCount,
    concat ( CAST(100.0 * CustomerCOUNT / SUM(CustomerCOUNT) over () as DECIMAL(5,2)),'%') 
        AS DistributionFactor
from cte_count

order by CustomerCategoryName;


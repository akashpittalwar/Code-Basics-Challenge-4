use gdb023;

-- request1
select distinct(market) 
from dim_customer 
where customer = "Atliq Exclusive" and region="APAC"; 

-- request2
-- select * from dim_product;
-- select * from fact_sales_monthly;

select product,count(product) as variants from dim_product group by product;
select count(distinct(product)) as Distinct_Products , count(distinct(product_code)) as Distinct_Product_Code from dim_product ;

-- As per products
with CTE1 as 
(select a.product_code,a.product,b.fiscal_year 
from dim_product a join fact_sales_monthly b 
on a.product_code=b.product_code),
CTE2 as 
(select count(distinct case when CTE1.fiscal_year=2020 then CTE1.product end ) as unique_product_2020 , 
count(distinct case when CTE1.fiscal_year=2021 then CTE1.product end ) as unique_product_2021 
from CTE1)
select unique_product_2020,unique_product_2021,
round(((unique_product_2021-unique_product_2020)/unique_product_2020) * 100,2) as percentage_chg 
from CTE2;

-- As per product code cause of different variants
-- with CTE1 as (select a.product_code,a.product,b.fiscal_year from dim_product a join fact_sales_monthly b on a.product_code=b.product_code),
-- CTE2 as (select count(distinct case when CTE1.fiscal_year=2020 then CTE1.product_code end ) as unique_product_2020 , 
-- count(distinct case when CTE1.fiscal_year=2021 then CTE1.product_code end ) as unique_product_2021 
-- from CTE1)
-- select unique_product_2020,unique_product_2021,round(((unique_product_2021-unique_product_2020)/unique_product_2020) * 100,2) as percentage_chg 
-- from CTE2;


-- request3
-- As per product
select segment, count(distinct(product)) as product_count
from dim_product group by segment order by product_count desc;

-- As per Variants
-- select segment, count(distinct(product_code)) as unique_variant_product_count
-- from dim_product group by segment order by unique_variant_product_count desc;

-- request4
with req4 as 
(select a.product_code, a.segment,a.product, b.fiscal_year
from dim_product a join fact_sales_monthly b 
on a.product_code = b.product_code),
req41 as 
(select segment,
count(distinct case when req4.fiscal_year=2020 then req4.product end) as product_count_2020,
count(distinct case when req4.fiscal_year=2021 then req4.product end) as product_count_2021 
from req4 group by segment order by product_count_2020 desc )
select segment,product_count_2020,product_count_2021,
product_count_2021-product_count_2020 as difference 
from req41 order by difference desc;

-- with req4 as (select a.product_code, a.segment,a.product, b.fiscal_year
-- from dim_product a join fact_sales_monthly b on a.product_code = b.product_code),
-- req41 as (select segment,count(distinct case when req4.fiscal_year=2020 then req4.product_code end) as product_count_2020,
-- count(distinct case when req4.fiscal_year=2021 then req4.product_code end) as product_count_2021 
-- from req4 group by segment order by product_count_2020 desc )
-- select segment,product_count_2020,product_count_2021, product_count_2021-product_count_2020 as difference 
-- from req41 order by difference desc;

-- request5
-- with req5 as (select a.product_code, a.product , b.manufacturing_cost 
-- from dim_product a join fact_manufacturing_cost b on a.product_code = b.product_code )
-- select * from req5 where manufacturing_cost=(select min(manufacturing_cost) from req5) 
-- or manufacturing_cost=(select max(manufacturing_cost)from req5) ;

select a.product_code, a.product , b.manufacturing_cost 
from dim_product a join fact_manufacturing_cost b on a.product_code = b.product_code
where manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost ) 
or manufacturing_cost=(select max(manufacturing_cost)from fact_manufacturing_cost ) ;


-- request6
-- select * from fact_pre_invoice_deductions;

with req6 as 
(select a.customer_code , a.customer, a.market, b.fiscal_year , b.pre_invoice_discount_pct 
from dim_customer a join fact_pre_invoice_deductions b
on a.customer_code = b.customer_code ),
req61 as 
(select customer ,round(avg(pre_invoice_discount_pct),3) as ave,market,fiscal_year 
from req6 where fiscal_year = 2021 and market='India' 
group by customer order by ave desc limit 0,5)
select req6.customer,req6.customer_code,req61.ave as average_discount_percentage
from req61 join req6 
on req6.customer=req61.customer and req6.fiscal_year = 2021 and req6.market='India' 
order by req61.ave desc ;

-- request6 possibility
with req6 as
(select a.customer_code , a.customer, a.market, b.fiscal_year , b.pre_invoice_discount_pct 
from dim_customer a join fact_pre_invoice_deductions b 
on a.customer_code = b.customer_code)
select customer,customer_code ,round(avg(pre_invoice_discount_pct),3) as average_discount_percentage 
from req6 where fiscal_year = 2021 and market='India' 
group by customer,customer_code order by average_discount_percentage desc limit 0,5;

-- request 7
-- with req7 as (select a.customer_code, a.customer, c.product_code , c.gross_price , c.fiscal_year , b.date, b.sold_quantity 
-- from dim_customer a join fact_Sales_monthly b 
-- on a.customer_code = b.customer_code 
-- join fact_gross_price c 
-- on c.product_code=b.product_code)
-- select month(date) as Month, Year(date) as Year, sum(gross_price*sold_quantity) as Gross_Sales_Amount,customer 
-- from req7 
-- where customer = 'Atliq Exclusive' 
-- group by Month,Year order by Month;

-- optimal
select month(b.date) as Month, Year(b.date) as Year, sum(c.gross_price*b.sold_quantity) as Gross_Sales_Amount
from dim_customer a join fact_Sales_monthly b 
on a.customer_code = b.customer_code 
join fact_gross_price c 
on c.product_code=b.product_code 
where a.customer = 'Atliq Exclusive' 
group by Month,Year order by Month;

-- request 8
select 
case
when month(date) in (9,10,11) then '1st Quarter' 
when month(date) in (12,1,2) then '2nd Quarter' 
when month(date) in (3,4,5) then '3rd Quarter' 
when month(date) in (6,7,8) then '4th Quarter' end 
as Quarter,
sum(sold_quantity) as total_sold_quantity
from fact_Sales_monthly where fiscal_year=2020 
group by Quarter order by total_sold_quantity desc ;

-- request9
with req9 as
(select channel, round(sum(c.gross_price*b.sold_quantity)/1000000,2) as Gross_Sales_mln
from dim_customer a join fact_Sales_monthly b 
on a.customer_code = b.customer_code 
join fact_gross_price c 
on c.product_code=b.product_code 
where b.fiscal_year = 2021 group by channel order by Gross_Sales_mln)
select *, (Gross_Sales_mln*100)/sum(Gross_Sales_mln) over() as Percentage from req9;

-- request 10
with req10 as (select a.division, a.product, a.product_code, sum(b.sold_quantity) as total_sold_quantity
from dim_product a join fact_sales_monthly b
on a.product_code = b.product_code
where fiscal_year = 2021
group by a.division,a.product, a.product_code ),
req101 as (select *,rank()over(partition by division order by total_sold_quantity desc) as Rank_Order from req10 )
select * from req101 where Rank_Order<=3;
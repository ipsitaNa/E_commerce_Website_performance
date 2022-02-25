-- CALCULATE monthly trends for gsearch sessions and orders

select 
YEAR(date(s.created_at)) as year,
month(date(s.created_at)) as month,
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct s.website_session_id) as sess_ord_conver_rate
from
website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
group by 1,2;


-- calculate monthly gserach simailr trends but splitting out brand and nonbrand campaigns seperately

select 
YEAR(date(s.created_at)) as year,
MONTH(date(s.created_at)) as month,
count(distinct case when s.utm_campaign='brand' then s.website_session_id else null end) as brand_sessions,
count(distinct case when s.utm_campaign='brand' then o.order_id else null end) as brand_orders,
count(distinct case when s.utm_campaign='nonbrand' then s.website_session_id else null end) as nonbrand_sessions,
count(distinct case when s.utm_campaign='nonbrand' then o.order_id else null end) as nonbrand_orders
from website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
group by 1,2;

-- CALCULATE monthly sessions and orders split by device type;

select
YEAR((s.created_at)) as year,
MONTH((s.created_at)) as month,
count(distinct case when s.device_type='mobile' then s.website_session_id else null end) as mobile_sessions,
count(distinct case when s.device_type='mobile' then o.order_id else null end) as mobile_orders,
count(distinct case when s.device_type='desktop' then s.website_session_id else null end) as desktop_sessions,
count(distinct case when s.device_type='desktop' then o.order_id else null end) as desktop_orders
from website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
and s.utm_campaign = 'nonbrand'
group by 1,2;


-- CALCULATE session to to order conversion rates
select 
YEAR(date(s.created_at)) as year,
month(date(s.created_at)) as month,
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct s.website_session_id) as sess_ord_conver_rate
from
website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.created_at < '2012-11-27'
group by 1,2;

-- CALCULATE the incresed orders after lander-1 tets has been deployed around june 29 and use nonbrand sessions to claculate INCREMENATL ORDERS 
with landing_page as (
select 
	s.website_session_id as sessions,
    min(p.created_at) as first_created_at,
    min(p.website_pageview_id) as first_pg_view
from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where s.created_at < '2012-07-28' -- test has been running till this date
and p.website_pageview_id >= 23504 -- first pagevieqw _id for lander-1 so we need to fairly test for home and lander-1
and s.utm_source  = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1),
landing_page_sess as (
select 
	lp.sessions,
    p.pageview_url as landing_page
from landing_page lp 
left join website_pageviews p on lp.first_pg_view = p.website_pageview_id
where p.pageview_url in  ('/home','/lander-1')
),
landing_pg_orders as (
select 
ls.sessions,
ls.landing_page,
o.order_id
from
landing_page_sess ls 
left join orders o on ls.sessions = o.website_session_id
)
select 
landing_page,
count(distinct sessions) as sessions,
count(distinct order_id) as orders,
count(distinct order_id) /count(distinct sessions)  as sesss_to_orde_rate
 from landing_pg_orders
 group by landing_page; 
 
 /* 
 # landing_page, sessions, orders, sesss_to_orde_rate
'/home',		 '2234',	 '71', 	'0.0318'
'/lander-1', 	'2287',	 '94',		 '0.0411'
 */
 
 
 -- 0.0318 for /home  vs 0.0411 for lander-1 
 -- 0.0093 additional orders per sessions
 -- we need to knoe how many orders have been increases after the test which happened 07/29
 -- first find the last session_id which had home_page for gsearch nonarnd(that;s been asked)
 select 
 max(s.website_session_id) as most_recnt_gsearch_nonbrand_home_pageview
 from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where p.pageview_url = '/home'
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand' 
and s.created_at < '2012-11-27';  -- 17145 this is last session_id where the traffic was to home 

-- we know the increnetal conversion rate of lander-1 as comapre to  is 0.0093, we can estimate the  incremenatl value of orderds
select 
* ,
round(a.sessions_since_test * 0.0093,2) as incremental_orders
from 
(select 
count(s.website_session_id) as sessions_since_test
from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where p.pageview_url = '/lander-1' 
and s.website_session_id > 17145
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand' 
and s.created_at < '2012-11-27') a ;
/* 
# sessions_since_test, incremental_orders
'22024',				 '204.82'

*/


-- CALCULATE monthly trends for gsearch sessions and orders

select 
YEAR(date(s.created_at)) as year,
month(date(s.created_at)) as month,
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct s.website_session_id) as sess_ord_conver_rate
from
website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
group by 1,2;


-- calculate monthly gserach simailr trends but splitting out brand and nonbrand campaigns seperately

select 
YEAR(date(s.created_at)) as year,
MONTH(date(s.created_at)) as month,
count(distinct case when s.utm_campaign='brand' then s.website_session_id else null end) as brand_sessions,
count(distinct case when s.utm_campaign='brand' then o.order_id else null end) as brand_orders,
count(distinct case when s.utm_campaign='nonbrand' then s.website_session_id else null end) as nonbrand_sessions,
count(distinct case when s.utm_campaign='nonbrand' then o.order_id else null end) as nonbrand_orders
from website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
group by 1,2;

-- CALCULATE monthly sessions and orders split by device type;

select
YEAR((s.created_at)) as year,
MONTH((s.created_at)) as month,
count(distinct case when s.device_type='mobile' then s.website_session_id else null end) as mobile_sessions,
count(distinct case when s.device_type='mobile' then o.order_id else null end) as mobile_orders,
count(distinct case when s.device_type='desktop' then s.website_session_id else null end) as desktop_sessions,
count(distinct case when s.device_type='desktop' then o.order_id else null end) as desktop_orders
from website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.utm_source  = 'gsearch'
and s.created_at < '2012-11-27'
and s.utm_campaign = 'nonbrand'
group by 1,2;


select distinct utm_source, utm_campaign,http_referer from website_sessions
where created_at < '2012-11-27';

select
YEAR((s.created_at)) as year,
MONTH((s.created_at)) as month,
count(distinct case when s.utm_source='gsearch' then s.website_session_id else null end) as gsearch_paid_sessions,
count(distinct case when s.utm_source='bsearch' then s.website_session_id else null end) as bsearch_paid_orders,
count(distinct case when s.utm_source is null and http_referer is not null then s.website_session_id else null end) as organic_search_sessions,
count(distinct case when s.utm_source is null and http_referer is  null then s.website_session_id else null end) as direct_type_in_sessions
from website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.created_at < '2012-11-27'
group by 1,2;


select 
YEAR(date(s.created_at)) as year,
month(date(s.created_at)) as month,
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
count(distinct o.order_id)/count(distinct s.website_session_id) as sess_ord_conver_rate
from
website_sessions s left join 
orders o on s.website_session_id = o.website_session_id
where s.created_at < '2012-11-27'
group by 1,2;

-- CALCULATE 
with landing_page as (
select 
	s.website_session_id as sessions,
    min(p.created_at) as first_created_at,
    min(p.website_pageview_id) as first_pg_view
from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where s.created_at < '2012-07-28' -- test has been running till this date
and p.website_pageview_id >= 23504 -- first pagevieqw _id for lander-1 so we need to fairly test for home and lander-1
and s.utm_source  = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1),
landing_page_sess as (
select 
	lp.sessions,
    p.pageview_url as landing_page
from landing_page lp 
left join website_pageviews p on lp.first_pg_view = p.website_pageview_id
where p.pageview_url in  ('/home','/lander-1')
),
landing_pg_orders as (
select 
ls.sessions,
ls.landing_page,
o.order_id
from
landing_page_sess ls 
left join orders o on ls.sessions = o.website_session_id
)
select 
landing_page,
count(distinct sessions) as sessions,
count(distinct order_id) as orders,
count(distinct order_id) /count(distinct sessions)  as sesss_to_orde_rate
 from landing_pg_orders
 group by landing_page; 
 
 -- 0.0318 for /home  vs 0.0411 for lander-1 
 -- 0.0093 additional orders per sessions
 -- we need to knoe how many orders have been increases after the test which happened 07/29
 -- first find the last session_id which had home_page for gsearch nonarnd(that;s been asked)
 select 
 max(s.website_session_id) as most_recnt_gsearch_nonbrand_home_pageview
 from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where p.pageview_url = '/home'
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand' 
and s.created_at < '2012-11-27';  -- 17145 this is last session_id where the traffic was to home 

-- we know the increnetal conversion rate of lander-1 as comapre to  is 0.0093, we can estimate the  incremenatl value of orderds
select 
* ,
round(a.sessions_since_test * 0.0093,2) as incremental_orders
from 
(select 
count(s.website_session_id) as sessions_since_test
from website_sessions s 
 left join website_pageviews p on s.website_session_id = p.website_session_id
where p.pageview_url = '/lander-1' 
and s.website_session_id > 17145
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand' 
and s.created_at < '2012-11-27') a ;

-- funnel analaysis for home_landing page and lander_1 and comapre 
-- funnel leves -> /home -> products  -> mr_fuzzy_page -> cart_page-> shipping_page ->billing_page  ->thank_you_page
  -- funnel leves -> /lander-1 -> products  -> mr_fuzzy_page -> cart_page-> shipping_page ->billing_page  ->thank_you_page  

create temporary table session_made_it_flagged	
select 
a.sessions,
max(homepage) as homepage_visits,
max(lander_1page) as lander_1_visits,
max(products_page) as products_page,
max(mr_fuzzy_page) as mr_fuzzy_page,
max(cart_page) as cart_page,
max(shipping_page) as shipping_page,
max(billing_page) as billing_page,
max(thank_you_page) as thank_you_page
from
(select 
s.website_session_id as sessions,
p.pageview_url as pageviews,
case when p.pageview_url = '/home' then 1 else 0 end as homepage,
case when p.pageview_url = '/lander-1' then 1 else 0 end as lander_1page,
case when p.pageview_url = '/products' then 1 else 0 end as products_page,
case when p.pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mr_fuzzy_page,
case when p.pageview_url = '/cart' then 1 else 0 end as cart_page,
case when p.pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when p.pageview_url = '/billing' then 1 else 0 end as billing_page,
case when p.pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thank_you_page 
from website_sessions s 
left join website_pageviews p on s.website_session_id = p.website_session_id
where  s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand' 
and  s.created_at between '2012-06-19' and '2012-07-28'
order by 1,2) a
group by 1;

-- now i will make two groups homepage and landpage using case in a column and will group by it with
select 
case when homepage_visits = 1 then 'homepage_visits'
	when lander_1_visits = 1 then 'lander_1_visits'
else 'check logic!' end as landing_pages,
count(distinct sessions) as sessions,
count(distinct case when products_page = 1  then sessions else null  end) as to_products,
count(distinct case when mr_fuzzy_page = 1  then sessions else null  end) as to_mr_fuzzy,
count(distinct case when cart_page = 1  then sessions else null  end) as to_cart,
count(distinct case when shipping_page = 1  then sessions else null  end) as to_shipping,
count(distinct case when billing_page = 1  then sessions else null  end) as to_billing,
count(distinct case when thank_you_page = 1  then sessions else null  end) as to_thank_you
from session_made_it_flagged
group by 1;

-- Quantifying the impact of our billing test  
-- In marketing, “lift” represents an increase in sales in response to some form of advertising or promotion. 
-- we want to check what is the increase in sales after introducing billing-2 for the month of sep and nov
create temporary table lift_calculation
select
b.*,
revenue_per_billing_seen - lag(b.revenue_per_billing_seen,1)over(order by billing_version_seen) as lift
from
(select 
	a.pageview_url as billing_version_seen,
	count(distinct a.website_session_id) as sessions,
    round(sum(a.price_usd)/count(distinct a.website_session_id),2) as revenue_per_billing_seen
from
(select 
 p.website_session_id,
 p.pageview_url,
 o.order_id,
 o.price_usd
from website_pageviews p 
left join orders o on p.website_session_id = o.website_session_id
where pageview_url in ('/billing','/billing-2')
and p.created_at between '2012-09-10' and '2012-11-10')a
group by 1)b;


-- we have calculated the lift, now we want to find vlaue of billing test
-- See how many sessions we expect to get in a month (we do this by counting the sessions for the past month).
-- Then, we multiply our "improvement per session" (aka "lift per session") by the number of  sessions we see in a month to
--  estimate the total improvement generated for the business on a monthly basis,i.e., both billing and billing-2

SELECT
COUNT(website_session_id)*8.34  AS vallue_of_billing_test   -- 9098.94
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2')
AND created_at BETWEEN '2012-10-27' AND '2012-11-27'; -- past month 

-- 1091 billing sessions past month
-- LIFT: $8.34 per billing session
-- VALUE OF BILLING TEST: $9098.94 over the past month

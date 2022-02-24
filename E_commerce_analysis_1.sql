--CALCULATE top traffic sources . Where are the bulk of website sessions are coming ? break it down by utm_source,utm_campaign,http_referer

select 
count(distinct website_session_id) as sessions,
utm_source,utm_campaign,http_referer
 from website_sessions
 where 
 created_at < '2012-04-12'
 group by 2,3,4 order by 1 desc;
 /*# sessions, utm_source, utm_campaign, http_referer
'3506', 'gsearch', 'nonbrand', 'https://www.gsearch.com'
'26', 	NULL, NULL, NULL
'25', 	NULL, NULL, 'https://www.gsearch.com'
'24', 	'gsearch', 'brand', 'https://www.gsearch.com'
'7', 	NULL, NULL, 'https://www.bsearch.com'
'7', 	'bsearch', 'brand', 'https://www.bsearch.com'
 */
 
 
 
 --CALCULATE the conversion rate from session to orders. we want at least 4% CVR from sessions . If lower rate,then we have to optimese search bids
 select 
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
round(count(distinct o.order_id)/count(distinct s.website_session_id),2) as ses_ord_conv_rt
from website_sessions s 
left join orders o on s.website_session_id = o.website_session_id
where s.created_at < '2012-04-14'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand';

/* 
# sessions, orders, ses_ord_conv_rt
'3825', 	'111', 	'0.03'

*/
-- We are below 4%. We will need to dial down our search bids a bit. we are over sepdning based on the current CVR
/*  NEXT STEPS
--Monitor the impact of bid reductions
--Analyze the performace trending by device type in order to refine biding strategy 
*/

-- Based on your CVR analysis, we bid down gserach nonbrand on 2012-04-15.
--CALCULATE gserach nonbrand trended session by week to see if the bid has changed. add the week start date and count sessions --recveid the mail on 2012-05-13


select 
 DATE_ADD(date(created_at), INTERVAL(1-DAYOFWEEK(date(created_at))) DAY) as FirstDayOfWeek,
 year(created_at) as year,
week(created_at) as week,
count(distinct website_session_id) as sessions
 from website_sessions 
 where created_at < '2012-05-10'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
 group by year(created_at),
 week(created_at)
 order by 1;
 
 /*
 # FirstDayOfWeek, year, week, sessions
'2012-03-18', '2012', '12', '861'
'2012-03-25', '2012', '13', '947'
'2012-04-01', '2012', '14', '1148'
'2012-04-08', '2012', '15', '987'
'2012-04-15', '2012', '16', '642'
'2012-04-22', '2012', '17', '593'
'2012-04-29', '2012', '18', '684'
'2012-05-06', '2012', '19', '372'
*/

--It does look like gserach nonbrand is farily sensitive to bid changes as you can see below. We want max vol but dont wnat to sepnd more n ads
/*
2012-04-15	2012	16	642
2012-04-22	2012	17	593
2012-04-29	2012	18	684
2012-05-06	2012	19	372*/


--CALCULATE CVR from sessions to orders based on device  type

 select 
s.device_type,
count(distinct s.website_session_id) as sessions,
count(distinct o.order_id) as orders,
round(count(distinct o.order_id)/count(distinct s.website_session_id),2) as ses_ord_conv_rt
from website_sessions s 
left join orders o on s.website_session_id = o.website_session_id
where s.created_at < '2012-05-11'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by s.device_type;
/* 
# device_type, sessions, orders, ses_ord_conv_rt
'desktop',		 '3873', '144',  '0.04'
'mobile', 		'2468',  '24',   '0.01'
*/

-- After analysing device level CVR ,we realised desktop was doing well,so we bid our gsearch nonbrand desktop campaigns on 2012-05-19 till 9th july 
-- pull weekly trends for both desktop and mobile  

 select 
date_add(date(created_at),Interval(1-dayofweek(date(created_at))) day) as week_day_start,
count(Distinct case when device_type = 'desktop' then website_session_id else 0 end) as desktop_sessions,
count(distinct case when device_type = 'mobile' then website_session_id else 0 end) as mobile_sessions
from website_sessions 
where created_at < '2012-06-09'
and created_at > '2012-04-15'
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
group by year(date(created_at)),
week(date(created_at));

-- CALCULATE the most-viewed website pages, ranked by session volume ?
select
p.pageview_url,
count(distinct p.website_session_id) as sessions
from website_pageviews p 
where p.created_at < '2012-06-09'
 group by 1 order by 2 desc;
 
 /* 
 # pageview_url, 			sessions
'/home',		 			'10332'
'/products', 				'4200'
'/the-original-mr-fuzzy', 	'3008'
'/cart', 					'1296'
'/shipping', 				'862'
'/billing',					 '712'
'/thank-you-for-your-order', '305'  */

-- CALCULATE top page entries
--It means I need to know how many sessions are landing to first entry page whther its home or product , what is the user session id is getting into first 


with first_page_view as 
 (select 
 website_session_id,
 min(website_pageview_id) as min_pg_view
 from website_pageviews
 where created_at < '2012-06-12'
 group by 1)
 select 
 count(distinct fp.website_session_id) as session,
 w.pageview_url as landing_page
 from first_page_view fp 
 left join website_pageviews w on fp.min_pg_view = w.website_pageview_id
 group by 2;
 
 /* 
 # session, landing_page
'10623', 	  '/home'

 */

 -- CALCULATE BOUNCED RATES 
 -- finding first page_views for each relevant session 
 -- identifying the landpage of each session 
 -- counting pageviews for each session , to identify "bounces"
 -- summarzing by couting total sessions and bounced session
 
 With sessions_n_bounces as 
  (select 
   website_session_id,
   created_at,
   pageview_url,
   website_pageview_id,
  min(website_pageview_id)over(partition by website_session_id) as min_pg,
  count(website_pageview_id)over(partition by website_session_id) as cnt_page_vews
  from website_pageviews),
  session as (
  select website_session_id  as session
  from sessions_n_bounces where created_at < '2012-06-14' 
  and pageview_url = '/home'),
  bounces as 
(select 
 website_session_id as bounced_sessions
 from sessions_n_bounces
where cnt_page_vews = 1)
select 
count(distinct s.session) as total_session,
count(distinct b.bounced_sessions) as bounced_session,
count(distinct b.bounced_sessions)/count(distinct s.session) as bounced_rate
from session s 
left join bounces b on s.session = b.bounced_sessions;
/* 
# total_session, bounced_session, bounced_rate
'10965', 			'6488', 		'0.5917'
*/



 
 
 --  pull bounce rates for the two groups - '/home' and '/lander-1' 
--CALCULATE we have done an A/B testing. we are testing with a differnt landing page 

 -- find out whne the new page / lander is launhced first created
  -- finding first page_views for each relevant session 
 -- identifying the landpage of each session 
 -- counting pageviews for each session , to identify "bounces"
 -- summarzing by couting total sessions and bounced session
 
 select 
	min(created_at) as created_at,
    min(website_pageview_id) as first_webpage_id
from website_pageviews 
where pageview_url = '/lander-1'
and created_at is not null;  -- first created at 2012-06-19 11:05:54 -- first pageview_id 23504

-- creating first page test views 
-- we want to test the page views which was after lander-1 has been created so we will lmit with page id of lander first created
-- we want to test these pages views for gserach and nonbrand thus joining with websites essions

With  first_test_B_pageviews AS(
	select 
	p.website_session_id as sessions,
	min(p.website_pageview_id) as min_pgview_id
from 
	website_pageviews p
JOIN website_sessions s on p.website_session_id = s.website_session_id
and s.created_at < '2012-07-28'
and p.website_pageview_id > 23504 -- the min page view id we found ifrts fir lander-1
and s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1),
 nonbrand_test_session_w_landing_page as (    -- now find sessions whihch have landing page as home or lander-1

 select 
	f.sessions,
    p.pageview_url as landing_page
from first_test_B_pageviews f
left join website_pageviews p on f.min_pgview_id = p.website_pageview_id
where p.pageview_url in ('/home','/lander-1')),
nonbrand_test_bounced_session as (  		-- count pagevies per session no of  sessions whihc have only visited first landing page for both hone and lander
	lp.sessions,
    lp.landing_page as landing_pg,
    count(p.website_pageview_id) 
from nonbrand_test_session_w_landing_page lp 
left join website_pageviews p on lp.sessions = p.website_session_id
group by 1,2
having count(p.website_pageview_id) = 1)
select 
	a.landing_page,
    count(distinct a.sessions) as sessions,
    count(distinct b.sessions) as bounced_session,
	count(distinct b.sessions)/count(distinct a.sessions) as bounced_rate
from nonbrand_test_session_w_landing_page a
left join nonbrand_test_bounced_session b on a.sessions = b.sessions
group by 1;

/* 
# landing_page, sessions, bounced_session, bounced_rate
'/home',     		'2234', 	'1304', '0.5837'
'/lander-1', 		'2286', 	'1213', '0.5306'

lander-1 the new Testing page is indeed better than home. so for A/B testing B testing page was better comapre to the initial A
*/


-- CALCULATE land page trend analysis Bounce rate analysis trended weekly 
-- pull the vol of  paid search nonbrand traffic on /home and /lander-1 ,trended weekly since June1st

with  sess_frst_page_pagecount as (
select 
	s.website_session_id as sessions,
	min(p.website_pageview_id) as first_pgvie_id,
    count(p.website_pageview_id) as pageviews_per_sess
from website_sessions s
left join website_pageviews p on s.website_session_id = p.website_session_id
where 
s.created_at  > '2012-06-01'
 and  s.created_at < '2012-08-31' and
 s.utm_source = 'gsearch'
and s.utm_campaign = 'nonbrand'
group by 1),
-- i need all the info of the above tabke and  their corresponding landing and dates created
 sess_counts_lander_home  as (select 
 s.*,
 p.pageview_url as ladning_page,
 p.created_at
from sess_frst_page_pagecount s
left join website_pageviews p on s.first_pgvie_id = p.website_pageview_id
where p.pageview_url IN('/home','/lander-1'))
select 
	YEARWEEK(created_at	) as year_week,
    MIN(date(created_at)) as week_start,
    COUNT(distinct sessions) as total_sessions,
    count(CASE When pageviews_per_sess = 1 then sessions end ) as bounced_session,
    count(CASE when ladning_page = '/home' then sessions end) as home_sessions,
    count(CASE when ladning_page = '/lander-1' then sessions end) as lander_sessions,
    count(CASE When pageviews_per_sess = 1 then sessions end )*1.0/COUNT(distinct sessions) as bounce_rate
from sess_counts_lander_home 
group by 1;
/* 
# year_week, week_start, total_sessions, bounced_session, home_sessions, lander_sessions, bounce_rate
'201222', '2012-06-01', '215', '129', '215', '0', '0.6000'
'201223', '2012-06-03', '796', '465', '796', '0', '0.5842'
'201224', '2012-06-10', '873', '537', '873', '0', '0.6151'
'201225', '2012-06-17', '837', '472', '505', '332', '0.5639'
'201226', '2012-06-24', '756', '441', '365', '391', '0.5833'
'201227', '2012-07-01', '789', '457', '402', '387', '0.5792'
*/


-- FUNNEL ANALYSIS fro lander-1 new test page --> lander-1 -->products -->mr-fuzzy ->cart -> shipping->billing -> thankYou

 create temporary table clickthrough_counts
select * 
from 
(
 with visitors as (   -- -- VISITORS (DEFINES THE GROUP WE FOLLOW THROUGH THE FUNNEL) that is no of sessions who have landing page
 select 
	distinct s.website_session_id as sessions,
    min(p.created_at)
from website_sessions s 
left join website_pageviews p on s.website_session_id = p.website_session_id
where pageview_url = '/lander-1' 
 and s.utm_source = 'gsearch'
 and s.utm_campaign = 'nonbrand'
 group by 1
 having min(p.created_at)  between  '2012-08-05' and '2012-09-05'
),
products as (
select 
distinct v.sessions
from visitors v 
join  website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/products'
),
mr_fuzzy as (
select 
distinct v.sessions
from products v 
join   website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/the-original-mr-fuzzy'
),
cart as (
select 
distinct v.sessions
from mr_fuzzy v 
join   website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/cart'
),
shipping as (
select 
distinct v.sessions
from cart v 
join   website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/shipping'
),
 billing as (
select 
distinct v.sessions
from shipping v 
join   website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/billing'
),
thank_you as (
select 
distinct v.sessions
from billing v 
join   website_pageviews p on v.sessions = p.website_session_id
where p.pageview_url = '/thank-you-for-your-order'
)
select 'lander-1' as funnel ,count(*) as clickthrough  from visitors
	UNION
select 'products' as funnel ,count(*) as clickthrough from products
	UNION
select 'the-original-mr-fuzzy' as funnel ,count(*) as clickthrough from mr_fuzzy
	UNION
select 'cart' as funnel ,count(*) as clickthrough from cart
	UNION
select 'shipping' as funnel ,count(*) as clickthrough from shipping
	UNION
 select 'billing' as funnel ,count(*) as clickthrough from billing
	UNION
select 'thank-you-for-your-order' as funnel ,count(*) as clickthrough from thank_you ;
)a;

select 
	max(case when funnel = 'products' then clickthrough else null end)/max(case when funnel = 'lander-1' then clickthrough else null end) as lander1_clickthrough,
    max(case when funnel = 'the-original-mr-fuzzy' then clickthrough else null end)/max(case when funnel = 'products' then clickthrough else null end) as products_clickthrough,
    max(case when funnel = 'cart' then clickthrough else null end)/max(case when funnel = 'the-original-mr-fuzzy' then clickthrough else null end) as mr_fuzzy_clickthrough,
    max(case when funnel = 'shipping' then clickthrough else null end)/max(case when funnel = 'cart' then clickthrough else null end) as cart_clickthrough,
    max(case when funnel = 'billing' then clickthrough else null end)/max(case when funnel = 'shipping' then clickthrough else null end) as shipping_clickthrough,
    max(case when funnel = 'thank-you-for-your-order' then clickthrough else null end)/max(case when funnel = 'billing' then clickthrough else null end) as billing_clickthrough
from clickthrough_counts;

-- -- CALCULATE  drop-off at each funnel 

select 
	*,
    lag(clickthrough,1)over() as lag_row,
    round((1.0 - clickthrough/lag(clickthrough, 1) over ()),2) as drop_off_rate
from clickthrough_counts;

-- CALCULATE A/B funnel conversion analysis of sessions to orders for two differnet billing tets pages (Billing and billing-2)


 
 select 
	a.billing_version_seen ,
    count(distinct a.sessions) as sessions,
    count(distinct a.orders) as orders,
    count(distinct a.orders)/count(distinct a.sessions) as billing_ord_rate
from
(select 
p.website_session_id as sessions,
p.pageview_url as billing_version_seen,
o.order_id as orders
from website_pageviews p 
left join orders o on p.website_session_id = o.website_session_id
where  p.created_at < '2012-11-10' 
and p.website_pageview_id >= 53550 -- first time created page id for billing_2(find it using min pageview)id when it view_url is billing-2), we need a fair comaprinsion between billig and billing_2
and p.pageview_url in ('/billing','/billing-2'))a
group by 1 ;



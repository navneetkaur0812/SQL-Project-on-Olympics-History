
select * from athletes;

select * from athlete_events;

select *  
from athletes a 
join athlete_events e on a.id = e.athlete_id;
select distinct team from athletes;

select distinct year from athlete_events order by year;

--Q1: which team has won the maximum gold medals over the years.

select top 1 team, count(distinct event) as no_of_gold_medals 
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Gold' 
group by team 
order by no_of_gold_medals desc;


--Q2: for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver

with m as 
(
select team, year, count (distinct event) as number_of_silver_medals, 
dense_rank() over (partition by team order by count (distinct event) desc) as max_silver_rank
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Silver' 
group by team, year
), cte as 
(
Select team, 
sum(number_of_silver_medals) as total_silver_medals,
max(case when max_silver_rank = 1 then year end) as year_of_max_silver
from m 
group by team
) 
select team, total_silver_medals,year_of_max_silver
from cte 
where year_of_max_silver is not null;



--Q3: which player has won maximum gold medals amongst the players 
--which have won only gold medal (never won silver or bronze) over the years

select top 1 name, no_of_gold_medals from 
(
select id, name, 
sum(case when medal = 'Gold' then 1 else 0 end) as no_of_gold_medals,
sum(case when medal = 'Silver' then 1 else 0 end) as no_of_silver_medals,
sum(case when medal = 'Bronze' then 1 else 0 end) as no_of_bronze_medals
from athletes a 
join athlete_events e on a.id = e.athlete_id 
group by id, name 
) m 
where no_of_silver_medals = 0 and no_of_bronze_medals = 0 and no_of_gold_medals <> 0 
order by no_of_gold_medals desc;


--Q4: in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year . In case of a tie print comma separated player names.


with m as 
(
select year, name,
count(medal) as no_of_gold_medals,
(case when count(medal) = (max(count(medal)) over (partition by year)) then name end) as max_gold_player
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Gold'
group by year, name 
) 
select year, no_of_gold_medals,
string_agg(max_gold_player, ', ') as players 
from  m
where max_gold_player is not null 
group by year, no_of_gold_medals;


--Q5: in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport

select distinct *
from
(
select medal, year, sport, event,
dense_rank() over(partition by medal order by year) as rank
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where team = 'India' and medal is not null 
) m
where rank =1;


--Q6: Find players who won gold medal in summer and winter olympics both.

--using self join
with abc as 
( select a.name, medal, season
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Gold' and season in ('Summer', 'Winter') 
), new as 
(
select abc.name as name1, abc.season as season1, xyz.name as name2, xyz.season as season2
from abc 
join abc xyz on abc.name = xyz.name 
)
select distinct name1
from new  
where season1 <> season2;

--OR 

select name
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Gold' 
group by name 
having count(distinct season) =2;


--Q7: find players who won gold, silver and bronze medal in a single olympics. print player name along with year.

--using self join
with cte as 
(
select a.name, e.games,  medal, year
from athletes a 
join athlete_events e on a.id = e.athlete_id 
) , ctee as
(
select cte.name as name1, cte.games as games1, cte.medal as medal1, cte.year as year1, 
cte1.name as name2, cte1.games as games2, cte1.medal as medal2, cte1.year as year2,
cte2.name as name3, cte2.games as games3, cte2.medal as medal3, cte2.year as year3
from 
cte join cte as cte1 on cte.name= cte1.name 
join cte as cte2 on cte1.name = cte2.name 
) 
select distinct name1, year1 from ctee 
where games1 = games2 and games2 = games3 and medal1 <> medal2 and medal2 <> medal3 and medal1 <> medal3
and medal1 is not null and medal2 is not null and medal3 is not null 
order by year1; 

--OR

select name, year 
from athletes a 
join athlete_events e on a.id = e.athlete_id  
group by name, year 
having count(distinct medal) = 3;


--Q8: find players who have won gold medals in consecutive 3 summer olympics in the same event . Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

with cte as 
(
select name, year, event
from athletes a 
join athlete_events e on a.id = e.athlete_id 
where medal = 'Gold' and season = 'Summer' and year >=2000
group by name, year, event
), m as (
select *, lag(year,1) over(partition by name, event order by year) as prev_year,
lead(year,1) over(partition by name, event order by year) as next_year 
from cte 
)
select * from m 
where prev_year = year-4 and next_year = year+4;


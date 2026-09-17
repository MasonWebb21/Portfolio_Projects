/* English Premier League Data Exploration (1993-2023)

Skills Used: Window Functions, CTE, Aggregate Functions, Unions, Cases

*/

--Ranking all the premier league teams by the highest homegoals that were scored in a single match during the 2022-2023 season
--Showcasing a basic window function / aggregate function

SELECT
	seasonendyear, 
	hometext AS club, 
	MAX(homegoals) AS highest_homegoal_tally,
	ROW_NUMBER () over(order by(MAX(homegoals)) DESC) AS max_homegoals_ranking
FROM pldata 
GROUP BY hometext,seasonendyear
HAVING seasonendyear = 2023;

--Formulating an end of season total points scored tally for every year that Queens Park Rangers was a part of EPL
--CASE was utitlized in ordered to effectively order the raw data with only full term result column avaliable in the raw data

SELECT seasonendyear,
    SUM(CASE 
        WHEN ftr = 'H' and hometext = 'QPR' THEN 3
		WHEN ftr = 'A' and awayteam = 'QPR' THEN 3
		WHEN ftr = 'D' THEN 1
        ELSE 0
    END) AS QPR_totalpoints	
FROM pldata
WHERE (awayteam = 'QPR' or hometext = 'QPR')
 AND seasonendyear BETWEEN 1993 AND 2023
 GROUP BY seasonendyear
 ORDER BY QPR_totalpoints desc;

 --Ordering the seasons where Chelsea scored the highest amount of EPL home goals (Filter the top 5) 
 --Aggregate Function used on Case (filtering all the chelsea home goals)

SELECT seasonendyear,
	AVG(CASE
		WHEN hometext = 'Chelsea' THEN homegoals
		ELSE NULL
	END) AS Chelsea_Home_Goals_Total

FROM pldata
GROUP BY seasonendyear
ORDER BY Chelsea_Home_Goals_Total DESC 
LIMIT 5;

--Using a weighted average method of the 10 most recent seasons, calculating is the probability that if you are going to a premier league game this season that it is going to be a scoreless draw?
--Leveraging a CTE to in order to aggregate a nested function (named weighted_average_info)
--Since the selected seasons all had 380 games can use 10% allocation for equal weighting amount in the calculation

WITH weighted_average_info AS (
	SELECT 
		seasonendyear, 
		COUNT(*) AS total_games, 
		COUNT(*) FILTER (WHERE homegoals = 0 AND awaygoals = 0) AS Zero_Zero_Draws,
		--::numeric is fixing issue where integer value will truncate to zero
		COUNT(*) FILTER (WHERE homegoals = 0 AND awaygoals = 0) ::numeric / COUNT(*) AS Zero_Zero_Draw_Percentage
	FROM pldata
	GROUP BY seasonendyear
	ORDER BY seasonendyear DESC 
	LIMIT 10
)

SELECT ROUND (SUM(Zero_Zero_Draw_Percentage)*.10 * 100, 5) AS wa_scoreless_draw_percentage
FROM weighted_average_info;


--Displaying which teams in the 90s were the most dominant and held the greatest goal differential
--CTE was created with a union to more effectively syncronize the match data per club between home/away (team_results)

WITH team_results AS (
    -- Home team
    SELECT
        seasonendyear,
        hometext AS team,
        homegoals AS goals_for,
        awaygoals AS goals_against
    FROM pldata

UNION ALL
	-- Away team
	SELECT
        seasonendyear,
        awayteam AS team,
        awaygoals AS goals_for,
        homegoals AS goals_against
    FROM pldata
)

SELECT 
team, seasonendyear,
SUM(goals_for) AS goals_for,
SUM(goals_for) - SUM(goals_against) AS goal_diff
FROM team_results
WHERE seasonendyear BETWEEN 1990 AND 1999
GROUP BY seasonendyear, team
ORDER BY goal_diff DESC
LIMIT 10;

--Creating a table that showcases the 90th percentile of total home goals scored by team within the scope of 2013-2023 seasons
--A CTE/Percent Rank Window function combination was used in order to filter to the top 10%

WITH homegoals_lastten_total AS (
	SELECT  
		hometext,
		seasonendyear,
		SUM(homegoals) AS season_homegoals,
		PERCENT_RANK() OVER(ORDER BY SUM(homegoals)) AS p_rank
		FROM pldata
		WHERE seasonendyear BETWEEN 2013 AND 2023
		GROUP BY hometext, seasonendyear
)

SELECT 
	hometext, 
	seasonendyear, 
	season_homegoals, 
	p_rank, 
	-- 19 home games per season & multiplaction by 1.0 fixes truncation issue
	season_homegoals*1.0/19 as average_homegoals
FROM homegoals_lastten_total
WHERE p_rank >= 0.9
ORDER BY season_homegoals DESC;

--General Context of Home Goals Per Game during those seasons  

SELECT  
	seasonendyear,
	ROUND(AVG(homegoals), 5) AS avg_season_homegoals
FROM pldata
WHERE seasonendyear BETWEEN 2013 AND 2023
GROUP BY seasonendyear
ORDER BY seasonendyear DESC;
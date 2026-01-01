-- ============================================================================
-- BASEBALL OPERATIONS ANALYTICS
-- ============================================================================
-- Analysing team spending efficiency, player career trajectories, and 
-- workforce composition patterns using advanced SQL techniques.
--
-- Skills demonstrated: Window functions, CTEs, cumulative calculations,
-- date manipulation, pivoting, and multi-table joins.
--
-- Author: Rachel Berger
-- GitHub: github.com/bergerache
-- ============================================================================


-- ============================================================================
-- TEAM SPENDING ANALYSIS
-- ============================================================================
-- Understanding how teams allocate budgets over time, identifying top spenders,
-- and tracking cumulative investment milestones.
-- ============================================================================

-- Which teams are in the top 20% for average annual spending?
-- (Banking parallel: Identifying high-value customers by transaction volume)

WITH annual_team_spend AS (
    SELECT 	teamID, 
            yearID, 
            SUM(salary) AS total_spend
    FROM	salaries
    GROUP BY teamID, yearID
),
            
team_percentiles AS (
    SELECT	teamID, 
            AVG(total_spend) AS avg_annual_spend,
            NTILE(5) OVER (ORDER BY AVG(total_spend) DESC) AS spend_quintile
    FROM	annual_team_spend
    GROUP BY teamID
)
            
SELECT  teamID,
        ROUND(avg_annual_spend / 1000000, 2) AS avg_spend_millions,
        spend_quintile
FROM    team_percentiles
WHERE   spend_quintile = 1
ORDER BY avg_spend_millions DESC;


-- How has each team's cumulative spending grown over time?
-- (Banking parallel: Running balance calculations, cumulative AUM tracking)

WITH annual_team_spend AS (
    SELECT  teamID, 
            yearID, 
            SUM(salary) AS total_spend
    FROM    salaries
    GROUP BY teamID, yearID
)
                        
SELECT  teamID,
        yearID,
        ROUND(total_spend / 1000000, 2) AS annual_spend_millions,
        ROUND(SUM(total_spend) OVER (
            PARTITION BY teamID 
            ORDER BY yearID
        ) / 1000000, 2) AS cumulative_spend_millions
FROM    annual_team_spend
ORDER BY teamID, yearID;


-- When did each team's cumulative spending first exceed $1 billion?
-- (Banking parallel: Time-to-threshold analysis, milestone tracking)

WITH annual_team_spend AS (
    SELECT  teamID, 
            yearID, 
            SUM(salary) AS total_spend
    FROM    salaries
    GROUP BY teamID, yearID
),
                        
cumulative_spend AS (
    SELECT  teamID,
            yearID,
            SUM(total_spend) OVER (
                PARTITION BY teamID 
                ORDER BY yearID
            ) AS running_total
    FROM    annual_team_spend
),

billion_threshold AS (
    SELECT  teamID,
            yearID,
            running_total,
            ROW_NUMBER() OVER (
                PARTITION BY teamID 
                ORDER BY yearID
            ) AS rn
    FROM    cumulative_spend
    WHERE   running_total > 1000000000
)

SELECT  teamID,
        yearID AS first_year_over_1B,
        ROUND(running_total / 1000000000, 2) AS cumulative_spend_billions
FROM    billion_threshold
WHERE   rn = 1
ORDER BY first_year_over_1B;


-- ============================================================================
-- PLAYER CAREER ANALYSIS
-- ============================================================================
-- Examining player career trajectories, tenure patterns, and team loyalty
-- to understand workforce dynamics.
-- ============================================================================

-- What are the career lengths of players, and at what age did they start/end?
-- (Banking parallel: Customer tenure analysis, lifecycle stage identification)

WITH player_dates AS (
    SELECT  playerID,
            nameGiven,
            CAST(CONCAT(birthYear, '-', birthMonth, '-', birthDay) AS DATE) AS birth_date,
            CAST(debut AS DATE) AS debut_date,
            CAST(finalGame AS DATE) AS final_date
    FROM    players
)
             
SELECT  playerID,
        nameGiven,
        birth_date,
        debut_date,
        final_date,
        TIMESTAMPDIFF(YEAR, birth_date, debut_date) AS age_at_debut,
        TIMESTAMPDIFF(YEAR, birth_date, final_date) AS age_at_retirement,
        TIMESTAMPDIFF(YEAR, debut_date, final_date) AS career_length_years
FROM    player_dates
WHERE   birth_date IS NOT NULL 
    AND debut_date IS NOT NULL
ORDER BY career_length_years DESC;


-- Which team did each player start and end their career with?
-- (Banking parallel: First product vs current product analysis, customer journey endpoints)

WITH player_teams AS (
    SELECT  playerID,
            teamID,
            yearID,
            FIRST_VALUE(teamID) OVER (
                PARTITION BY playerID 
                ORDER BY yearID
            ) AS first_team,
            FIRST_VALUE(teamID) OVER (
                PARTITION BY playerID 
                ORDER BY yearID DESC
            ) AS last_team,
            ROW_NUMBER() OVER (
                PARTITION BY playerID 
                ORDER BY yearID
            ) AS rn
    FROM    salaries
)
                
SELECT  playerID, 
        first_team, 
        last_team,
        CASE WHEN first_team = last_team THEN 'Yes' ELSE 'No' END AS career_loyalty
FROM    player_teams
WHERE   rn = 1
ORDER BY playerID;


-- How many players showed long-term loyalty (same team for 10+ years)?
-- (Banking parallel: Long-term customer retention analysis)

WITH player_teams AS (
    SELECT  playerID,
            FIRST_VALUE(teamID) OVER (
                PARTITION BY playerID 
                ORDER BY yearID
            ) AS first_team,
            FIRST_VALUE(teamID) OVER (
                PARTITION BY playerID 
                ORDER BY yearID DESC
            ) AS last_team,
            ROW_NUMBER() OVER (
                PARTITION BY playerID 
                ORDER BY yearID
            ) AS rn
    FROM    salaries
),
                
player_careers AS (
    SELECT  playerID,
            TIMESTAMPDIFF(YEAR, 
                CAST(debut AS DATE), 
                CAST(finalGame AS DATE)
            ) AS career_length
    FROM    players
),
                
loyal_players AS (
    SELECT  t.playerID, 
            t.first_team, 
            t.last_team, 
            c.career_length
    FROM    player_teams t
    LEFT JOIN player_careers c ON t.playerID = c.playerID
    WHERE   t.rn = 1 
        AND t.first_team = t.last_team 
        AND c.career_length > 10
)
            
SELECT  COUNT(*) AS loyal_long_career_players,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT playerID) FROM salaries), 1) AS pct_of_all_players
FROM    loyal_players;


-- ============================================================================
-- TALENT PIPELINE ANALYSIS
-- ============================================================================
-- Analysing which institutions produce the most professional players
-- and how this has evolved over time.
-- ============================================================================

-- Which schools have produced the most professional players?
-- (Banking parallel: Lead source analysis, channel effectiveness)

SELECT      sd.name_full AS school_name,
            COUNT(DISTINCT s.playerID) AS players_produced
FROM        schools s
INNER JOIN  school_details sd ON s.schoolID = sd.schoolID
GROUP BY    s.schoolID, sd.name_full
ORDER BY    players_produced DESC
LIMIT       10;


-- How has player production by school changed across decades?
-- (Banking parallel: Cohort analysis, trend identification over time)

WITH school_decades AS (
    SELECT  FLOOR(s.yearID / 10) * 10 AS decade,
            sd.name_full AS school_name,
            COUNT(DISTINCT s.playerID) AS players_produced
    FROM    schools s
    INNER JOIN school_details sd ON s.schoolID = sd.schoolID
    GROUP BY decade, s.schoolID, sd.name_full
),
            
ranked_schools AS (
    SELECT  decade,
            school_name,
            players_produced,
            ROW_NUMBER() OVER (
                PARTITION BY decade 
                ORDER BY players_produced DESC
            ) AS decade_rank
    FROM    school_decades
)
            
SELECT  decade,
        school_name,
        players_produced,
        decade_rank
FROM    ranked_schools
WHERE   decade_rank <= 3
ORDER BY decade DESC, decade_rank;


-- ============================================================================
-- WORKFORCE COMPOSITION ANALYSIS
-- ============================================================================
-- Examining player characteristics and how physical attributes have
-- evolved over time.
-- ============================================================================

-- What is the batting hand distribution across teams?
-- (Banking parallel: Customer segmentation by product preference)

WITH player_team_batting AS (
    SELECT DISTINCT 
            s.teamID, 
            s.playerID, 
            p.bats
    FROM    salaries s 
    LEFT JOIN players p ON s.playerID = p.playerID
)

SELECT 	teamID, 
        COUNT(playerID) AS total_players,
        ROUND(SUM(CASE WHEN bats = 'R' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_right,
        ROUND(SUM(CASE WHEN bats = 'L' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_left,
        ROUND(SUM(CASE WHEN bats = 'B' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_both
FROM    player_team_batting
WHERE   teamID IS NOT NULL
GROUP BY teamID
ORDER BY teamID;


-- How have player physical attributes changed decade over decade?
-- (Banking parallel: Customer demographic shifts, trend analysis)

WITH decade_averages AS (
    SELECT  FLOOR(YEAR(debut) / 10) * 10 AS decade,
            ROUND(AVG(height), 1) AS avg_height,
            ROUND(AVG(weight), 1) AS avg_weight,
            COUNT(*) AS player_count
    FROM    players
    WHERE   debut IS NOT NULL 
        AND height IS NOT NULL 
        AND weight IS NOT NULL
    GROUP BY FLOOR(YEAR(debut) / 10) * 10
)
            
SELECT  decade,
        avg_height,
        avg_weight,
        player_count,
        ROUND(avg_height - LAG(avg_height) OVER (ORDER BY decade), 2) AS height_change,
        ROUND(avg_weight - LAG(avg_weight) OVER (ORDER BY decade), 2) AS weight_change
FROM    decade_averages
WHERE   decade IS NOT NULL
ORDER BY decade;


-- ============================================================================
-- SUMMARY
-- ============================================================================
-- This analysis demonstrates:
--   • Window functions (ROW_NUMBER, NTILE, LAG, FIRST_VALUE)
--   • Common Table Expressions (CTEs) for readable, modular queries
--   • Cumulative/running calculations
--   • Date manipulation and tenure analysis
--   • Pivoting with CASE WHEN
--   • Multi-table joins
--
-- These techniques directly transfer to financial services analytics:
--   • Customer lifetime value calculations
--   • Running balance and cumulative metrics
--   • Cohort and trend analysis
--   • Customer segmentation
--   • Retention and loyalty analysis
-- ============================================================================

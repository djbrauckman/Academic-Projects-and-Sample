select * from fcp_2023.results_csv WHERE `date` = '2022-10-01' AND `time` = '12:30:00';
select * from fcp_2023.results_csv WHERE homeTeam = 'tottenham' or awayTeam = 'tottenham';
SELECT * FROM G18.team; WHERE teamName = 'Tottenham';
select * From G18.team_season_div ORDER BY teamId;
select * from G18.fixture;
select * from G18.team_fixture order by fixtureId;


INSERT INTO G18.team_fixture (teamId, fixtureId, isHome, shots, shotsTarget, corners, fouls, yellowCards, redCards, goalsHT, goalsFT)
SELECT t.teamId, f.fixtureId, 1 AS isHome, rc.hs, rc.hst, rc.hc, rc.hf, rc.hy, rc.hr, rc.hthg, rc.fthg
FROM fcp_2023.results_csv rc 
	JOIN G18.team t on t.teamName = rc.homeTeam
    JOIN G18.season s on s.seasonName = rc.season
    JOIN G18.fixture f on f.seasonId = s.seasonId
WHERE f.`date` = rc.`date`
	AND f.`time` = rc.`time`
    AND f.htr = rc.htr
    AND f.ftr = rc.ftr
ORDER BY f.fixtureId;

INSERT INTO G18.team_fixture (teamId, fixtureId, isHome, shots, shotsTarget, corners, fouls, yellowCards, redCards, goalsHT, goalsFT)
SELECT t.teamId, f.fixtureId, 0 AS isHome, rc.`as`, rc.ast, rc.ac, rc.af, rc.ay, rc.ar, rc.htag, rc.ftag
FROM fcp_2023.results_csv rc 
	JOIN G18.team t on t.teamName = rc.awayTeam
    JOIN G18.season s on s.seasonName = rc.season
    JOIN G18.fixture f on f.seasonId = s.seasonId
WHERE f.`date` = rc.`date`
	AND f.`time` = rc.`time`
    AND f.htr = rc.htr
    AND f.ftr = rc.ftr
ORDER BY f.fixtureId;


select * 
from fcp_2023.results_csv
where awayTeam = 'Fortuna Dusseldorf'
AND homeTeam = 'Ingolstadt'; 

select t.teamName, tf.* 
from G18.team_fixture tf
	JOIN G18.team t on t.teamId = tf.teamId
    JOIN G18.fixture f on f.fixtureId = tf.fixtureId
WHERE f.fixtureId = 97;


    

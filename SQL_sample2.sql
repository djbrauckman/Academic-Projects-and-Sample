--ISQS-6338 FCP PART 2 - SQL Table Creation and Data Migration
--Group 18
--Danny Brauckman, Jordan Gussett, Bryan Loeffler, Ashley Ramnath

--Create tables without any FKs

--Create team table
CREATE TABLE `G18`.`team`
(
`teamId`   INT(8)       NOT NULL    AUTO_INCREMENT,
`teamName` VARCHAR(75)  NOT NULL,
PRIMARY KEY (`teamId`)
);

--Create league table
CREATE TABLE `G18`.`league`
(
`leagueId`   INT(8)       NOT NULL    AUTO_INCREMENT,
`leagueName` VARCHAR(75)  NOT NULL,
PRIMARY KEY (`leagueId`)
);

--Create referee table
CREATE TABLE `G18`.`referee`
(
`refId`   INT(8)       NOT NULL    AUTO_INCREMENT,
`refName` VARCHAR(75)  NOT NULL,
PRIMARY KEY (`refId`)
);

--Create season table
CREATE TABLE `G18`.`season`
(
`seasonId`   INT(8)       NOT NULL  AUTO_INCREMENT,
`seasonName` VARCHAR(75)  NOT NULL  UNIQUE,
PRIMARY KEY (`seasonId`)
);

------------------------------------------------
--Create FK Constraint tables

--Create Division table
CREATE TABLE `G18`.`division`
(
`divisionId`    INT(8)       NOT NULL,
`divisionName`  VARCHAR(75)  NOT NULL,
`leagueId`      INT(8)       NOT NULL,
PRIMARY KEY (`divisionId`),
CONSTRAINT `league_fk` FOREIGN KEY (`leagueId`)
    REFERENCES `G18`.`league`(`leagueId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);

--Create Fixture table
CREATE TABLE `G18`.`fixture`
(
`fixtureId`     INT(8)       NOT NULL    AUTO_INCREMENT,
`seasonId`      INT(8)       NOT NULL,
`refId`         INT(8)       NULL,
`date`          DATE         NOT NULL,
`time`          TIME         NOT NULL,
`htr`           CHAR(3)      NOT NULL,
`ftr`           CHAR(3)      NOT NULL,
PRIMARY KEY (`fixtureId`),
CONSTRAINT `referee_fk` FOREIGN KEY (`refId`)
    REFERENCES `G18`.`referee`(`refId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
CONSTRAINT `season_fk` FOREIGN KEY (`seasonId`)
    REFERENCES `G18`.`season`(`seasonId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);

--Create team_season_div table
CREATE TABLE `G18`.`team_season_div`
(
`teamId`     INT(8)       NOT NULL,
`seasonId`   INT(8)       NOT NULL,
`divisionId` INT(8)       NOT NULL,
PRIMARY KEY (`teamId`, 'seasonId'),
CONSTRAINT `team_fk` FOREIGN KEY (`teamId`)
    REFERENCES `G18`.`team`(`teamId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
CONSTRAINT `division_fk` FOREIGN KEY (`divisionId`)
    REFERENCES `G18`.`division`(`divisionId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION,
FOREIGN KEY (`seasonId`)
    REFERENCES `G18`.`season`(`seasonId`)
);

--Create team_fixture table
CREATE TABLE `G18`.`team_fixture`
(
`teamId`        INT(8)       NOT NULL,
`fixtureId`     INT(8)       NOT NULL,
`isHome`        TINYINT(1)   NOT NULL,
`shots`         INT(2)       NOT NULL,
`shotsTarget`   INT(2)       NOT NULL,
`corners`       INT(2)       NOT NULL,
`fouls`         INT(2)       NOT NULL,
`yellowCards`   INT(2)       NOT NULL,
`redCards`      INT(2)       NOT NULL,
`goalsHT`       INT(2)       NOT NULL,
`goalsFT`       INT(2)       NOT NULL,
PRIMARY KEY (`teamId`, `fixtureId`),
CONSTRAINT `fixture_fk` FOREIGN KEY (`fixtureId`)
    REFERENCES `G18`.`fixture`(`fixtureId`)
    ON DELETE NO ACTION ON UPDATE NO ACTION
);

-------------------------------------------------------
--DML

--Insert teams data
INSERT INTO G18.team (teamName)
SELECT DISTINCT(homeTeam) FROM fcp_2023.results_csv;

--Insert teams data for teams that only had away games
INSERT INTO G18.team (teamName)
SELECT DISTINCT(awayTeam) 
FROM fcp_2023.results_csv rc
WHERE NOT EXISTS(SELECT 1 FROM G18.team t WHERE t.teamName = rc.awayTeam)    

--Insert referee data
INSERT INTO G18.referee (refName)
SELECT DISTINCT(referee) FROM fcp_2023.results_csv;

--Insert league data
INSERT INTO G18.league (leagueName)
SELECT DISTINCT(league) FROM fcp_2023.results_csv;

--Insert season data 
INSERT INTO G18.season (seasonName)
SELECT DISTINCT(season) FROM fcp_2023.results_csv ORDER BY season;

--Insert division data
INSERT INTO G18.division (divisionName, leagueId)
SELECT DISTINCT(r.`div`), l.leagueID 
	FROM G18.league l
		JOIN fcp_2023.results_csv r on r.league = l.leagueName;

--Insert fixture data
INSERT INTO G18.fixture (seasonId, refId, `date`, `time`, htr, ftr)
SELECT s.seasonId, r.refId, rc.`date`, rc.`time`, rc.htr, rc.ftr
FROM fcp_2023.results_csv rc 
	JOIN G18.season s ON s.seasonName = rc.season
    JOIN G18.referee r ON r.refName = rc.referee;

--Insert team_season_div data based on homeTeam join
INSERT INTO G18.team_season_div (teamId, seasonId, divisionId)
SELECT t.teamId, s.seasonId, d.divisionId
FROM fcp_2023.results_csv rc 
	JOIN G18.team t ON t.teamName = rc.homeTeam
    JOIN G18.season s ON s.seasonName = rc.season 
    JOIN G18.division d ON d.divisionName = rc.`div`
GROUP BY t.teamId, s.seasonId, d.divisionId
ORDER BY t.teamId; 

--Insert team_season_div data based on awayTeam join + where we don't already have records
INSERT INTO G18.team_season_div (teamId, seasonId, divisionId)
SELECT t.teamId, s.seasonId, d.divisionId
FROM fcp_2023.results_csv rc 
	JOIN G18.team t ON t.teamName = rc.awayTeam
    JOIN G18.season s ON s.seasonName = rc.season 
    JOIN G18.division d ON d.divisionName = rc.`div`
WHERE NOT EXISTS(
SELECT 1 FROM G18.team_season_div tsd WHERE tsd.teamId = t.teamId
	AND tsd.seasonId = s.seasonId
    AND tsd.divisionId = d.divisionId
)
GROUP BY t.teamId, s.seasonId, d.divisionId
ORDER BY t.teamId; 

--Insert team fixture data
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

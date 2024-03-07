-- Mise en forme des data necessaire (conversion char --> number)
ALTER TABLE ProjectPortfolioCovid..CovidDeath
ALTER COLUMN total_deaths float

UPDATE ProjectPortfolioCovid..CovidDeath
SET total_deaths = NULL WHERE total_deaths=0

ALTER TABLE ProjectPortfolioCovid..CovidDeath
ALTER COLUMN total_cases float

UPDATE ProjectPortfolioCovid..CovidDeath
SET total_cases = NULL WHERE total_cases=0

---- % des chances de mourir si infecté par le Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathpercentage 
FROM ProjectPortfolioCovid..CovidDeath
WHERE location like 'fr%' 
and continent is not null
ORDER BY 1, 2

---- % population ayant contracter le Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS covidpercentage 
FROM ProjectPortfolioCovid..CovidDeath
WHERE location like 'fr%' 
AND continent is not null
ORDER BY 1, 2

---- Pays avec le plus d'infecter (infection rate/population)
SELECT location, population, MAX(new_cases) AS HighestInfectionCount, MAX((new_cases/population))*100 AS MaxpercentagePopinfected  
FROM ProjectPortfolioCovid..CovidDeath
--WHERE location like 'fr%'
WHERE continent is not null
GROUP BY location, population
ORDER BY MaxpercentagePopinfected DESC

-- Pays avec le plus de mort / population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM ProjectPortfolioCovid..CovidDeath
--WHERE location like 'fr%' 
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Continent avec plus de mort
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM ProjectPortfolioCovid..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- nombre de nouveau cas (hebdomadaire) dans le monde
SELECT date, SUM(new_cases) AS SumNewCases
FROM ProjectPortfolioCovid..CovidDeath
WHERE continent is not null
GROUP BY date
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2

--nombre de nouveau cas, de mort et % total de mort dans le monde
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeath,(SUM(new_deaths)/(NULLIF(SUM(new_cases), 0))*100) AS PercentageDeath
FROM ProjectPortfolioCovid..CovidDeath
WHERE continent is not null
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2

--nombre de nouveau cas, de mort et % total de mort (hebdomadaire) dans le monde
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeath,(SUM(new_deaths)/(NULLIF(SUM(new_cases), 0))*100) AS PercentageDeath
FROM ProjectPortfolioCovid..CovidDeath
WHERE continent is not null
GROUP BY date
HAVING SUM(new_cases) <> 0
ORDER BY 1, 2


-- IMPACT DE LA VACCINATION
SELECT *
FROM ProjectPortfolioCovid..CovidVaccination

-- Cumulatif du nombre de personne dans le monde qui ont été vacciné  --> il faudrait groupé par mois ? ou semaine ?
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CONVERT(bigint, vaccin.new_vaccinations)) 
	OVER (Partition by death.location ORDER BY death.date) 
	AS CumulativeOfNewVaccination
FROM ProjectPortfolioCovid..CovidDeath AS death
JOIN ProjectPortfolioCovid..CovidVaccination AS vaccin
	ON death.location = vaccin.location
	and death.date = vaccin.date
WHERE death.continent is not null
ORDER BY 2,3

-- % population vacciné en fonction du temps
--CTE
WITH PopVsVac (Continent, Location, Date, Population, new_vaccinations, CumulativeOfNewVaccination) 
AS (
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CONVERT(bigint, vaccin.new_vaccinations)) 
	OVER (Partition by death.location ORDER BY death.date) 
	AS CumulativeOfNewVaccination
FROM ProjectPortfolioCovid..CovidDeath AS death
JOIN ProjectPortfolioCovid..CovidVaccination AS vaccin
	ON death.location = vaccin.location
	and death.date = vaccin.date
WHERE death.continent is not null
)
SELECT*, (CumulativeOfNewVaccination/Population)*100 
FROM PopVsVac

--TempTable
DROP TABLE if exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(Continent nvarchar (255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
CumulativeOfNewVaccination numeric)
INSERT INTO #PercentagePopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CONVERT(bigint, vaccin.new_vaccinations)) 
	OVER (Partition by death.location ORDER BY death.date) 
	AS CumulativeOfNewVaccination
FROM ProjectPortfolioCovid..CovidDeath AS death
JOIN ProjectPortfolioCovid..CovidVaccination AS vaccin
	ON death.location = vaccin.location
	and death.date = vaccin.date
WHERE death.continent is not null

SELECT*, (CumulativeOfNewVaccination/Population)*100 
FROM #PercentagePopulationVaccinated


--Creating View to store data for later visualization

CREATE VIEW PercentagePopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vaccin.new_vaccinations,
	SUM(CONVERT(bigint, vaccin.new_vaccinations)) 
	OVER (Partition by death.location ORDER BY death.date) 
	AS CumulativeOfNewVaccination
FROM ProjectPortfolioCovid..CovidDeath AS death
JOIN ProjectPortfolioCovid..CovidVaccination AS vaccin
	ON death.location = vaccin.location
	and death.date = vaccin.date
WHERE death.continent is not null


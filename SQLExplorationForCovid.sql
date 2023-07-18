Select *
from PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
order by 3,4

--Select *
--from PortfolioProject..CovidVaccinations$
--order by 3,4

--Select Data in Use

Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
order by 1,2

--Total Cases vs Total Deaths
--Shows chances of dying from covid in a country

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS DECIMAL)/CAST(total_cases AS DECIMAL))*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL AND location like '%Canada%'
order by 5 DESC

--Total Cases vs Population
--shows percentage of population that contacted covid

SELECT location, date, total_cases, population, (CAST(total_cases AS DECIMAL)/CAST(population AS DECIMAL))*100 as PercentagePopulationInfected
from PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL and location like '%Canada%'
order by 1,2

--Countries with highest infection rates compared to population

Select Location, population, MAX(total_cases) AS HighestInfectionCount,  MAX(CAST(total_cases AS DECIMAL)/CAST(population AS DECIMAL))*100 as PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
--WHERE location like '%nigeria%'
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

--Countries with the highest Death Count vs Population

Select location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Grouping by Continent and showing the highest death count

Select location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS


SELECT
--date, 
SUM(new_cases) AS TotalNewCases,
SUM(new_deaths) AS TotalNewDeaths,
CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE (SUM(new_deaths)/SUM(new_cases))*100 END AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is NOT NULL
--AND location like '%Canada%'
--GROUP BY date
ORDER BY 1,2

--Total Vaccination vs Population and adding a cumulative people vaccinated count 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,ISNULL(vac.new_vaccinations,0))) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS CumulativePeopleVaccinatedCount
FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3

--Creating a Total Cumulative People Vaccinated Count Percentage
-- Using CTE
WITH PopvsVac (Continent, Location, date, Population, New_Vaccinations, CumulativePeopleVaccinatedCount)
AS
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,ISNULL(vac.new_vaccinations,0))) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS CumulativePeopleVaccinatedCount
FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is NOT NULL
)

SELECT *,(CumulativePeopleVaccinatedCount/Population)*100 AS CumulativePeopleVaccinatedCountPercentage
FROM PopvsVac

--Creating a Total Cumulative People Vaccinated Count Percentage
-- Using TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CumulativePeopleVaccinatedCount numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,ISNULL(vac.new_vaccinations,0))) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS CumulativePeopleVaccinatedCount
FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *,(CumulativePeopleVaccinatedCount/Population)*100 AS CumulativePeopleVaccinatedCountPercentage
FROM #PercentPopulationVaccinated

--Creating View to store data for Visualizations


CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(BIGINT,ISNULL(vac.new_vaccinations,0))) OVER (PARTITION BY dea.location ORDER BY dea.location,
	dea.date) AS CumulativePeopleVaccinatedCount
FROM PortfolioProject..CovidDeaths$ dea
	JOIN PortfolioProject..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME = 'PercentPopulationVaccinated';

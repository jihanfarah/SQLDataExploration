-- Data preview

SELECT * 
FROM CovidDeath
ORDER BY 3,4

SELECT TOP 10
iso_code, location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeath
ORDER BY 1, 2 ASC

SELECT TOP 10
iso_code, location, date, new_vaccinations
FROM CovidVaccination
ORDER BY 1, 2 ASC

SELECT DISTINCT iso_code, location
FROM CovidDeath
WHERE iso_code LIKE '%OWID%'

-- Looking at total cases vs total deaths

SELECT TOP 10 
location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeath
WHERE location like '%Indonesia%'
ORDER BY 1, 2 DESC

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT TOP 10
location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeath
WHERE location like '%Indonesia%'
ORDER BY 1, 2 DESC

-- Looking at countries with highest infection rate compared to population

SELECT TOP 10 
location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeath
WHERE iso_code NOT LIKE '%OWID%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with the Highest Death Count per Population

SELECT TOP 10
location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeath
WHERE iso_code NOT LIKE '%OWID%'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Showing Continents with the Highest Death Count per Population

SELECT 
	continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeath
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT 
	SUM(new_cases) AS total_cases, 
	SUM(cast(new_deaths AS int)) AS total_deaths, 
	SUM(cast(new_deaths AS int))/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidDeath
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1, 2

-- Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
	AS RollingPeopleVaccinated, 
	-- (RollingPeopleVaccinated/population)*100
From CovidDeath dea
Join CovidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.location = 'Indonesia'
order by 2,3

-- USE CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT 
	dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		AS RollingPeopleVaccinated
FROM CovidVaccination vac
JOIN CovidDeath dea
	ON dea.location = vac.location
	AND dea.date = vac.date
)

SELECT TOP 10
	*, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM PopvsVac
WHERE location = 'Indonesia'
ORDER BY date DESC

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CAST(vac.new_vaccinations AS float),
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		AS RollingPeopleVaccinated
FROM CovidVaccination vac
JOIN CovidDeath dea
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/population)*100 AS VaccinatedPercentage
FROM #PercentPopulationVaccinated
WHERE Location = 'Indonesia'
ORDER BY Date DESC


-- CREATE VIEW 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, 
	CAST(vac.new_vaccinations AS float) new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		AS RollingPeopleVaccinated
FROM CovidVaccination vac
JOIN CovidDeath dea
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


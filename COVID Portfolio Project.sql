SELECT *
FROM PortfolioProject..CovidDeaths$
where continent is not null
order by 3,4

--SELECT *
--FROM PortfolioProject..CovidVacinations$
--order by 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT Location, date, total_cases, population,
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
order by 1,2


-- Looking at Countries with Highest infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))* 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
Group by Location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
WHERE continent is not null
Group by Location
order by TotalDeathCount desc

-- LET'S BREAK  THINGS DOWN BY CONTINENT


-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
WHERE continent is not null
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS
-- Showing Dates with DeathPercentage

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,     
	CASE
        WHEN SUM(new_cases) = 0 THEN 0  -- Handle division by zero
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END AS Deathpercentage
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null
Group By date
order by 1,2

-- Showing Overall Death Percentage

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,     
	CASE
        WHEN SUM(new_cases) = 0 THEN 0  -- Handle division by zero
        ELSE SUM(new_deaths) * 100.0 / SUM(new_cases)
    END AS Deathpercentage
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
where continent is not null
--Group By date
order by 1,2

-- Looking at Total Population vs Vaccination

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Showing population vaccinated per country
-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingVaccinationPercentage
FROM PopvsVac

--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population numeric,
New_vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Creating view to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations AS BIGINT)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVacinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *
FROM PercentPopulationVaccinated
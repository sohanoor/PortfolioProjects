Select *
From PortfolioProject.dbo.CovidDeaths;

Select *
From PortfolioProject.dbo.CovidVaccination;

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2

-- Looking at Total Cases Vs Total Deaths

Select Location, date, total_cases, total_deaths 
--(total_deaths/total_cases)*100 as DeathPercentage
,CONVERT(DECIMAL(15, 3), total_deaths) AS 'total_deaths'
,CONVERT(DECIMAL(15, 3), total_cases) AS 'total_cases'
,CONVERT(DECIMAL(15, 3), (CONVERT(DECIMAL(15, 3), total_deaths) / CONVERT(DECIMAL(15, 3), total_cases)))*100 AS 'DeathPercentage'
From PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Looking at Total Cases Vs Population
Select Location, date, population, total_cases  
--(total_cases /population)*100 as CasePercentage
,CONVERT(DECIMAL(15, 3), total_cases) AS 'total_cases'
,CONVERT(DECIMAL(15, 3), population) AS 'population'
,CONVERT(DECIMAL(15, 3), (CONVERT(DECIMAL(15, 3), total_cases) / CONVERT(DECIMAL(15, 3), population)))*100 AS 'CasePercentage'
From PortfolioProject..CovidDeaths
where location like '%desh%'
order by 1,2


--Looking at Countries with Highest Infection Rate compared to population
Select Location, Population, Max(total_cases) as HighestInfectionCount 
,Max((total_cases/population))*100 as PercentagePopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentagePopulationInfected DESC


--Showing Countries with Highest Death Count per Population
Select Location, Max(cast(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
Where  continent is not null
Group by Location
order by TotalDeathCount DESC


--LET'S BREAK THINGS DOWN BY CONTINENT
--Showing continents with the highest death count per population
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount 
From PortfolioProject..CovidDeaths
Where  continent is not null
Group by continent
order by TotalDeathCount DESC


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1,2


--Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 --SUM(Convert(int, vac.new_vaccinations)) OVER (Partition by dea.location  || ERROR: **Arithmetic overflow error converting expression to data type int**
 SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location -- use BIGINT
	Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null -- and vac.new_vaccinations is not null
order by 2,3

--USE CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null --and vac.new_vaccinations is not null
)
Select *, (RollingPeopleVaccinated/Population) * 100
From PopvsVac


-- TEMP TABLE 
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null --and vac.new_vaccinations is not null

Select *, (RollingPeopleVaccinated/Population) * 100
From #PercentPopulationVaccinated


--Creating view to store data for later visualization 

Create View PercentPopulationVaccinateds as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(Convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location 
	Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
	Join PortfolioProject..CovidVaccination vac
		on dea.location = vac.location
		and dea.date = vac.date
where dea.continent is not null --and vac.new_vaccinations is not null
--order by 2,3

Select * 
From PercentPopulationVaccinateds
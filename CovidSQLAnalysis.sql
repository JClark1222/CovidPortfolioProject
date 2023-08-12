select * 
from CovidProject..coviddeaths
Where continent is not null
order by 3,4

--select * 
--from CovidProject..covidvaccinations
--order by 3,4

--select the data that we are going to be using
select Location, date, total_cases, new_cases, total_deaths, population
from CovidProject..coviddeaths
order by 1,2


--looking at the Total Cases vs Total Deaths
--This shows the likelihood of passing away if you contracted covid in the states
select Location, date, total_cases, total_deaths, CAST(total_deaths AS float) / CAST(total_cases AS float) * 100 as DeathPercentage
from CovidProject..coviddeaths
Where location like '%states%'
order by 1,2


--Looking at Total Cases vs Population
--Which percentage of the population contracted covid

select Location, date, population, total_cases,  CAST(total_cases AS float) / CAST(population AS float) * 100 as PercentofPopulationInfected
from CovidProject..coviddeaths
Where location like '%states%'
order by 1,2

--BREAKING IT DOWN BY CONTINENT

select continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
from CovidProject..coviddeaths
Where continent is null
AND location not like '%income' 
AND location not like '%world%'
Group by continent
order by TotalDeathCount desc

-- Showing the continents with the highest death count per population

select continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
from CovidProject..coviddeaths
Where continent is not null
AND location not like '%income' 
AND location not like '%world%'
Group by continent
order by TotalDeathCount desc

--What countries have the Highest Infection Rates compared to the population

select Location, population, MAX(total_cases) as HighestInfectionCount, MAX(CAST(total_cases AS float) / CAST(population AS float)) * 100 as PercentofPopulationInfected
from CovidProject..coviddeaths
Group by location, population
order by PercentofPopulationInfected desc


-- Showing countries with the Highest Death Count per population

select Location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
from CovidProject..coviddeaths
Where continent is not null
Group by location
order by TotalDeathCount desc



-- GLOBAL NUMBERS

select 
SUM(new_cases) as total_cases, 
SUM(CAST(new_deaths AS int)) as total_deaths,
SUM(CAST(new_deaths AS int))/NULLIF(SUM(new_cases),0) * 100 as DeathPercentage
from CovidProject..coviddeaths
Where continent is not null
--Group By date
order by 1,2

--Looking at total population vs vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
From CovidProject..coviddeaths dea
Join CovidProject..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
From CovidProject..coviddeaths dea
Join CovidProject..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)

Select *, (NULLIF(RollingPeopleVaccinated,0)/population)*100 as Percentages
From PopvsVac

--Temp Table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccincations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
From CovidProject..coviddeaths dea
Join CovidProject..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

Select *, (NULLIF(RollingPeopleVaccinated,0)/population)*100 as Percentages
From #PercentPopulationVaccinated


--Creating View to storae data for later visualizations

Create View PopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date ROWS UNBOUNDED PRECEDING) as RollingPeopleVaccinated
From CovidProject..coviddeaths dea
Join CovidProject..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

select * from dbo.PopulationVaccinated

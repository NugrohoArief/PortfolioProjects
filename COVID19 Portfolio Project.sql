select continent, location, population, date, new_cases, total_cases, new_deaths, total_deaths 
from PortfolioProject..CovidDeaths
order by 2,4

-- Total Cases vs Total Deaths in Indonesia

select location, date, total_cases, total_deaths, cast(total_deaths as numeric)/cast(total_cases as numeric)*100 death_percentage
from PortfolioProject..CovidDeaths
where location = 'Indonesia'
order by 1,2

-- Total Cases vs Total Deaths

select location, date, total_cases, total_deaths, cast(total_deaths as numeric)/cast(total_cases as numeric)*100 death_percentage
from PortfolioProject..CovidDeaths
where continent is not NULL
order by 1,2

-- Total Cases vs Population

select location, date, population, total_cases, total_deaths, (total_cases/population)*100 InfectedPercentage
from PortfolioProject..CovidDeaths
where continent is not NULL
order by 1,2

-- Countries with the highest Infection Rate compared to population

select location, population, max(cast(total_cases as int)) HighestInfectionCount, max(cast(total_cases as int)/population) *100 IntfectionRate
from PortfolioProject..CovidDeaths
where continent is not NULL
group by location, population
order by 4 desc

-- Countries with the highest death count per population

select location, population, max(cast(total_deaths as int)) num_of_deaths, max(cast(total_deaths as int)/population) *100 deaths_per_population
from PortfolioProject..CovidDeaths
where continent is not NULL
group by location, population
order by 4 desc

-- Covid Death rate in global

select sum(new_cases) num_of_cases, sum(new_deaths) num_of_deaths, (sum(new_deaths)/sum(new_cases))*100 covid_death_rate 
from PortfolioProject..CovidDeaths
where continent is not NULL

-- Countries with highest covid Death rate

select location, max(cast(total_cases as int)) num_of_cases, max(cast(total_deaths as int)) num_of_deaths, (max(cast(total_deaths as decimal)))/(max(cast(total_cases as decimal)))*100 covid_death_rate
from PortfolioProject..CovidDeaths
where continent is not NULL
group by location
order by 4 desc

-- Covid Death rate in Indonesia

select location, max(cast(total_cases as int)) num_of_cases, max(cast(total_deaths as int)) num_of_deaths, (max(cast(total_deaths as decimal)))/(max(cast(total_cases as decimal)))*100 covid_death_rate
from PortfolioProject..CovidDeaths
where continent is not NULL
and location = 'Indonesia'
group by location
order by 4 desc

-- Continent with highest death count

select continent, sum(new_deaths) num_of_deaths
from PortfolioProject..CovidDeaths
where continent is not NULL
group by continent
order by num_of_deaths desc

-- The highest new covid cases worldwide

select date, sum(new_cases) total_new_case
from PortfolioProject..CovidDeaths
where continent is not NULL
and new_cases is not NULL
and new_cases >= 1
group by date
order by total_new_case desc

-- The highest new covid cases in Indonesia

select date, new_cases
from PortfolioProject..CovidDeaths
where location = 'Indonesia'
order by new_cases desc

-- data vaccinations global

select *
from PortfolioProject..CovidVaccinations
where continent is not NULL
order by location, date

-- countries with highest population density

select location, round(max(population_density),2) pop_density
from PortfolioProject..CovidVaccinations
group by location
order by 2 desc

-- data vaccinations in Indonesia

select *
from PortfolioProject..CovidVaccinations
where location = 'Indonesia'
order by date

-- People vaccinated in Indonesia

select location, date, population, new_people_vaccinated_smoothed, 
sum(cast(new_people_vaccinated_smoothed as int)) over (partition by location order by location, date) num_people_vaccinated
from PortfolioProject..CovidVaccinations
where continent is not NULL
and location = 'Indonesia'

-- countries Population vs People Vaccinated

with PopVac (location, date, population, new_people_vaccinated_smoothed, num_people_vaccinated) 
as (
select dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
sum(cast(new_people_vaccinated_smoothed as int)) over (partition by dea.location order by dea.location, dea.date) num_people_vaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on	dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
)

select location, max(round((num_people_vaccinated/population)*100,3)) people_vac_percentage
from PopVac
where num_people_vaccinated is not NULL
group by location
order by people_vac_percentage desc

-- People vaccinated vs Covid Cases in Indonesia
-- TEMP TABLE

drop table if exists #VaccVsCasesIndonesia
create table #VaccVsCasesIndonesia
(
location nvarchar(255),
date datetime,
population numeric,
new_people_vaccinated_smoothed int,
num_people_vaccinated int,
new_cases int,
total_cases int
)

insert into #VaccVsCasesIndonesia
select vac.location, vac.date, vac.population, vac.new_people_vaccinated_smoothed
,sum(cast(vac.new_people_vaccinated_smoothed as int)) over (partition by vac.location order by vac.location, vac.date) num_people_vaccinated
,dea.new_cases, dea.total_cases
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on	dea.location = vac.location
		and dea.date = vac.date
where vac.continent is not NULL
and vac.location = 'Indonesia'

select *, (num_people_vaccinated/population)*100 vacc_percentage, (total_cases/population)*100 cases_percentage
from #VaccVsCasesIndonesia

-- People vaccinated vs Covid Cases vs Covid Death Global
-- TEMP TABLE

drop table if exists #CovidGlobal
create table #CovidGlobal
(
location nvarchar(255),
date datetime,
population numeric,
new_people_vaccinated int,
total_people_vaccinated int,
new_cases int,
total_cases numeric,
new_deaths int,
total_deaths numeric
)

insert into #CovidGlobal
select vac.location, vac.date, vac.population, vac.new_people_vaccinated_smoothed
,sum(cast(vac.new_people_vaccinated_smoothed as int)) over (partition by vac.location order by vac.location, vac.date) num_people_vaccinated
,dea.new_cases, dea.total_cases, dea.new_deaths, dea.total_deaths
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on	dea.location = vac.location
		and dea.date = vac.date
where vac.continent is not NULL

select location, date, population, 
new_cases, total_cases, (total_cases/population)*100 cases_per_population_percentage, 
new_deaths, total_deaths, (total_deaths/total_cases)*100 deaths_rate_percentage, 
new_people_vaccinated, total_people_vaccinated, (total_people_vaccinated/population)*100 vacc_percentage
from #CovidGlobal
order by location, date

-- Creating View to store data for later vizualisation

create view PercentPopulationVaccinated as
(
select dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
sum(cast(new_people_vaccinated_smoothed as int)) over (partition by dea.location order by dea.location, dea.date) num_people_vaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on	dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not NULL
)

select *
from PercentPopulationVaccinated



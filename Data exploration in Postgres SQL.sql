select * from covid_deaths;
delete from  covid_deaths where location = 'location';

--changing datatype to numeric
alter table covid_deaths alter column total_deaths type numeric ;
alter table covid_deaths alter column total_cases type numeric;

--total deaths vs total cases
select location,date,total_cases,total_deaths,round((total_deaths/total_cases)*100,2) as death_percentage 
from covid_deaths;

--showing likelihood you may die if you contact covid in this continent
select continent,location,date,total_cases,total_deaths,round((total_deaths/total_cases)*100,2) as death_percentage 
from covid_deaths
where continent like '%Asia%';

--find out total unique locations
select count(distinct location) from covid_deaths;

--find out maximum cases and deaths accoring to location
select location,max(total_cases) as cases,max(total_deaths) as deaths
from covid_deaths
group by location;

--total cases vs population and shows what percentage of population affected
ALTER TABLE covid_deaths alter COLUMN population type numeric USING population::numeric;

select location,date,population,total_cases,round((total_cases/population)*100,2) as affected_pop 
from covid_deaths 
--where location = 'India';

--which continent has more affected
select continent,location,max(total_cases) as HighInfectionCount
from covid_deaths
where total_cases is not null and continent is not null
group by continent,location
order by HighInfectionCount desc
limit 20; 

--shows countries with highest death count per population
select location,max(total_deaths) as HighDeathCount
from covid_deaths
where total_deaths is not null and continent is not null
group by location,total_deaths
order by total_deaths desc;

--showing which continent is not null
select continent,max(total_deaths) as HighDeathCount
from covid_deaths
where  continent is not null
group by continent
order by HighDeathCount desc;

--showing how many patients are admitted to hospital and how many are in icu per million
select location,hosp_patients_per_million,icu_patients_per_million 
from covid_deaths 
where hosp_patients_per_million,icu_patients_per_million is not null;

----showing weekly analysis of how many patients are admitted to hospital and how many are in icu per million 
select location,population,date,weekly_hosp_admissions_per_million,weekly_icu_admissions_per_million 
from covid_deaths 
where weekly_hosp_admissions_per_million is not null and weekly_icu_admissions_per_million is not null;

--showing how many new_cases and deaths has occured on daily basis
select date,sum(cast(new_cases as numeric)) as tcases,sum(cast(new_deaths as numeric)) as tdeaths,
sum(cast(new_deaths as numeric))/sum(cast(new_cases as numeric))*100 as DeathPercent
from covid_deaths
where continent is not null
group by date
order by 1,2;

select * from covid_vaccinations

--joining both tables
select * from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date

--total population vs new vaccinations per day
select cd.date,cd.location,cd.population,cv.new_vaccinations
from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date 
order by 1,2;

--showing aggregate function
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
sum(cast(cv.new_vaccinations as integer)) over (partition by cd.location order by cd.location,cd.date)
from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date 
where cd.continent is not null
order by 2;

--Using CTE 
With PopVsVac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated) as
(select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
sum(cast(cv.new_vaccinations as integer)) over (partition by cd.location order by cd.location,
												cd.date) as RollingPeopleVaccinated
												
from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date 
where cd.continent is not null
--order by 2;
)
select *,round((RollingPeopleVaccinated/population)*100,2) from PopVsVac


--Temp table
drop table if exists PercentPopulationVaccinated
create table PercentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
sum(cast(cv.new_vaccinations as integer)) over (partition by cd.location order by cd.location,
												cd.date) as RollingPeopleVaccinated
												
from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date 
where cd.continent is not null
--order by 2;

select *,round((RollingPeopleVaccinated/population)*100,2) from PercentPopulationVaccinated


--create view to store data for later vizulisation
create view PercentPopulationVaccinated as
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
sum(cast(cv.new_vaccinations as integer)) over (partition by cd.location order by cd.location,cd.date) as RollingPeopleVaccinated
from covid_deaths cd join covid_vaccinations cv
on cd.location = cv.location
and cd.date = cv.date 
where cd.continent is not null;
-- changing datatype of table coviddeaths and table covidvaccinations from varchar to datetime
select * 
from PortfolioProject..Coviddeaths
where try_convert(datetime,date,103) is null and date is not null
select * 
from PortfolioProject..CovidVaccinations
where try_convert(datetime,date,103) is null and date is not null

select * into PortfolioProject..Coviddeaths_backup
from PortfolioProject..Coviddeaths
select * into PortfolioProject..CovidVaccinationsbackup
from PortfolioProject..CovidVaccinations

alter table PortfolioProject..Coviddeaths
add date_temp datetime;
alter table PortfolioProject..CovidVaccinations
add date_temp datetime;

update PortfolioProject..Coviddeaths
set date_temp=convert(datetime,date,103)
update PortfolioProject..CovidVaccinations
set date_temp=convert(datetime,date,103)

alter table PortfolioProject..Coviddeaths
drop column date;
alter table PortfolioProject..CovidVaccinations
drop column date;

exec sp_rename 'PortfolioProject..Coviddeaths.date_temp','date','column';
exec sp_rename 'PortfolioProject..CovidVaccinations.date_temp','date','column';

select * 
from PortfolioProject..Coviddeaths
order by 3,4

--select * 
--from PortfolioProject..CovidVaccinations
--order by 3,4

select location,date,total_cases,population 
from PortfolioProject..Coviddeaths
order by 1,2

--death rate
--death rate in india
select location,date,total_cases,total_deaths,(convert(bigint,total_deaths)/nullif(convert(bigint,total_cases),0))*100 as DeathPercentage
from PortfolioProject..Coviddeaths
where location like '%india%'
order by 1,2

--looking at total cases versus population in india
select location,date,population,total_cases,(convert(bigint,total_cases)/nullif(convert(bigint,population),0))*100 as CasesperCapita
from PortfolioProject..Coviddeaths
where location like '%india%'
order by 1,2

--contries with highest casespercapita
select location,population,max(convert(bigint,total_cases)) as maxcases,max((convert(bigint,total_cases)/nullif(convert(bigint,population),0))*100) as MaxCasesperCapita
from PortfolioProject..Coviddeaths
group by location,population
order by MaxCasesperCapita desc

--maxdeathcount
select location,max(cast(total_deaths as bigint)) as deathcount
from PortfolioProject..Coviddeaths
where trim(continent) is not null and trim(continent)<>''
group by location
order by deathcount desc

--continentwise distribution
select continent,max(cast(total_deaths as bigint)) as deathcount
from PortfolioProject..Coviddeaths
where trim(continent) is not null and trim(continent)<>''
group by continent
order by deathcount desc

--newdeathrate
select date,sum(cast(new_cases as bigint)) as totalnewcases,sum(cast(new_deaths as bigint)) as totalnewdeaths,sum(convert(bigint,new_deaths))/sum(nullif(convert(bigint,new_cases),0))*100 as newdeathrate
from PortfolioProject..Coviddeaths
where trim(continent) is not null and trim(continent)<>''
group by date
order by 1,2,3

--new vaccinations and total vaccinations per day
select d.continent,d.location,d.date,d.population,v.new_vaccinations,sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as totalvaccinationsuptilnow
from PortfolioProject..Coviddeaths d
join PortfolioProject..CovidVaccinations v
    on d.location=v.location
	and d.date=v.date
where trim(d.continent) is not null and trim(d.continent)<>''
order by 2,3

--vaccination rate daily in cte
with popvac(continent,location,date,population,new_vaccinations,totalvaccinationsuptilnow)
as(
select d.continent,d.location,d.date,d.population,v.new_vaccinations,sum(convert(bigint,v.new_vaccinations)) over (partition by d.location order by d.location,d.date) as totalvaccinationsuptilnow
from PortfolioProject..Coviddeaths d
join PortfolioProject..CovidVaccinations v
    on d.location=v.location
	and d.date=v.date
where trim(d.continent) is not null and trim(d.continent)<>''
)
select *,totalvaccinationsuptilnow/(convert(float,population))*100 as vacrate
from popvac

--vaccination rate daily in temp table
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated(
continent nvarchar(55),
location nvarchar(55),
date datetime,
population bigint,
new_vaccination bigint,
totalvaccinationsuptilnow numeric
)
insert into #percentpopulationvaccinated
select d.continent,d.location,d.date,d.population,v.new_vaccinations,sum(convert(bigint,new_vaccinations)) over (partition by d.location order by d.location,d.date) as totalvaccinationsuptilnow
from PortfolioProject..Coviddeaths d
join PortfolioProject..CovidVaccinations v
    on d.location=v.location
	and d.date=v.date
where trim(d.continent) is not null and trim(d.continent)<>''

select *,totalvaccinationsuptilnow/(convert(float,population))*100 as vacrate
from #percentpopulationvaccinated


----vaccination rate daily in view
create view percentpopulationvaccinated as
select d.continent,d.location,d.date,d.population,v.new_vaccinations,sum(convert(bigint,new_vaccinations)) over (partition by d.location order by d.location,d.date) as totalvaccinationsuptilnow
from PortfolioProject..Coviddeaths d
join PortfolioProject..CovidVaccinations v
    on d.location=v.location
	and d.date=v.date
where trim(d.continent) is not null and trim(d.continent)<>''

select *,totalvaccinationsuptilnow/(convert(bigint,population))*100 as vacrate
from percentpopulationvaccinated


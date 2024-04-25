/*
	Covid-19 data set exploration
*/

---Default value to see the whole dataset of covid death
SELECT *
FROM
	CovidDeath
WHERE 
	continent IS NOT NULL

---Checking the infected cases and death causes by infection in different location
---The likely hood of dying in Vietnam was around 3% but now drop to 0% in 2024
SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,ROUND(total_deaths/total_cases,2)*100 AS percentage_of_death
FROM
	CovidDeath
WHERE
	location LIKE 'Vietnam'
ORDER BY
	location
	,date

---Checking the country that had the highest percentage of death in covid pandemic 
---Highest percentage is France
SELECT 
	location
	,date
	,total_cases
	,total_deaths
	,ROUND(total_deaths/total_cases,2)*100 AS percentage_of_death
FROM
	CovidDeath
WHERE
	ROUND(total_deaths/total_cases,2)*100 > 100
ORDER BY
	location
	,date


---Total Case vs Population
SELECT 
	location
	,date
	,total_cases
	,population
FROM
	CovidDeath
--WHERE
--	location LIKE 'Vietnam'
ORDER BY
	location
	,date


---Country that have the highest infection case
SELECT
	location
	, population
	, MAX(total_cases) AS highest_infection_case
	,MAX(ROUND(total_cases/population,2))*100 AS percentage_of_infectPopulation
FROM
	CovidDeath
GROUP BY
	location
	,population
ORDER BY
	percentage_of_infectPopulation DESC

---Showing country that have the highest death per population
SELECT
	location
	,population
	,MAX(CAST(total_deaths AS int)) AS highest_death_count
	,MAX(ROUND(total_deaths/population,2))*100 AS percentage_of_death_population
FROM
	CovidDeath
WHERE
	continent IS NOT NULL
GROUP BY
	location
	,population
ORDER BY
	highest_death_count DESC

----SAME AS ABOVE BUT FOR CONTINENT
SELECT
	continent
	,MAX(CAST(total_deaths AS int)) AS highest_death_count
	
FROM
	CovidDeath
WHERE
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	highest_death_count DESC

---The more accurate for the death count in location
SELECT
	location
	,MAX(CAST(total_deaths AS int)) AS highest_death_count
	
FROM
	CovidDeath
WHERE
	continent IS NULL
GROUP BY
	location
ORDER BY
	highest_death_count DESC

---Total Case vs population in continent
SELECT 
	continent
	,population
	,total_cases

FROM
	CovidDeath
WHERE
	continent IS NOT NULL 
	AND total_cases IS NOT NULL
ORDER BY
	continent
	, population

---Highest percentage in continent
SELECT 
	continent
	,date
	,total_cases
	,total_deaths
	,ROUND(total_deaths/total_cases,2)*100 AS percentage_of_death
FROM
	CovidDeath
WHERE
	continent IS NOT NULL 
	AND total_cases IS NOT NULL 
	AND total_deaths IS NOT NULL
ORDER BY
	continent
	,date

---Numbers of global in covid
---Could not add date in since the data have 0 as value instead of Null
---Will cause error when try to add date
SELECT
	 SUM(new_cases)AS Total_case
	, SUM(CAST(new_deaths AS int)) AS Total_death
	, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS PercentageOfDeathGlobal
FROM
	CovidDeath
WHERE
	continent IS NOT NULL

---Default value to see the whole dataset of covid vacinated
SELECT *
FROM
	CovidVac

--Total case and positive rate in different country
SELECT
	location
	, SUM(CAST(total_tests AS float)) AS total_tests
	, SUM(CAST(positive_rate AS float)) AS positive_rate
FROM 
	CovidVac
WHERE
	total_tests IS NOT NULL
	AND positive_rate IS NOT NULL
GROUP BY
	location
ORDER BY
	location


---Total cases and total vacination in different country (does include positive rate being null)
SELECT
	location
	, SUM(CAST(total_tests AS float)) AS total_tests
	, SUM(CAST(total_vaccinations AS float)) AS total_vaccinations
FROM
	CovidVac
WHERE
	total_tests IS NOT NULL
	AND total_vaccinations IS NOT NULL
GROUP BY
	location
ORDER BY
	location

---Total cases and total vaccinations in different country (doesn't include positive rate being null)
SELECT
	location
	, SUM(CAST(total_tests AS float)) AS total_tests
	, SUM(CAST(total_vaccinations AS float)) AS total_vaccinations
FROM
	CovidVac
WHERE
	total_tests IS NOT NULL
	AND total_vaccinations IS NOT NULL
	AND positive_rate IS NOT NULL
GROUP BY
	location
ORDER BY
	location

---Total tests and vaccinations in Vietnam
SELECT
	location
	, SUM(CAST(total_tests AS float)) AS total_tests
	, SUM(CAST(total_vaccinations AS float)) AS total_vaccinations
FROM
	CovidVac
WHERE
	total_tests IS NOT NULL
	AND total_vaccinations IS NOT NULL
	AND positive_rate IS NOT NULL
	AND location LIKE 'Vietnam'
GROUP BY
	location
ORDER BY
	location

---Total vaccinations and death in different country through out time
SELECT
	CD.location
	,CD.date
	,SUM(CONVERT(float,CD.total_deaths)) 
		OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS deaths_total
	,SUM(CONVERT(float, CV.total_vaccinations)) 
		OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS vaccinations_total
FROM
	CovidDeath AS CD
	JOIN CovidVac AS CV
		ON
	CD.location = CV.location
	AND CD.date = CV.date
ORDER BY
	CD.location
	,CD.date

---Total population vs vaccinations over time
SELECT
	CD.continent
	,CD.location
	,CD.date
	,CD.population
	,CV.new_vaccinations
	,SUM(CONVERT(float,new_vaccinations)) 
		OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_people_vaccinated
FROM
	CovidDeath AS CD
	JOIN CovidVac AS CV
		ON
	CD.location = CV.location
	AND CD.date = CV.date
ORDER BY
	2,3

---CTE
WITH PopulationVaccinate (continent,location,date,population,new_vaccinations,rolling_people_vaccinated)
AS
(
	SELECT
		CD.continent
		,CD.location
		,CD.date
		,CD.population
		,CV.new_vaccinations
		,SUM(CONVERT(float,new_vaccinations)) 
			OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_people_vaccinated
	FROM
		CovidDeath AS CD
		JOIN CovidVac AS CV
			ON
		CD.location = CV.location
		AND CD.date = CV.date
	WHERE
		CD.continent IS NOT NULL
)
SELECT 
	*
	,(rolling_people_vaccinated/population)*100 AS percentage_of_vaccinated
FROM
	PopulationVaccinate

---View to store data for visualization
CREATE VIEW PopulationVaccinatePercentage 
AS
	SELECT
		CD.continent
		,CD.location
		,CD.date
		,CD.population
		,CV.new_vaccinations
		,SUM(CONVERT(float,new_vaccinations)) 
			OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_people_vaccinated
	FROM
		CovidDeath AS CD
		JOIN CovidVac AS CV
			ON
		CD.location = CV.location
		AND CD.date = CV.date
	WHERE
		CD.continent IS NOT NULL



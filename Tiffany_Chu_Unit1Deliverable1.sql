/*
Report By: Tiffany Chu
Date: January 18, 2024
Objective: Evaluate which airline stock would bring shareholders the highest ROI
Source: Flight data for 2018 and 2019 from the three most traveled airlines
*/ 

SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY';
USE airtraffic; -- data source

-- A look into tables and its columns
SELECT * FROM airports;
SELECT * FROM flights;

/* Question 1 Part 1: 
Basic information: 
By finding the total count of flights of both years and comparing them, this allows us to compare 
performance between years. 
There were 3218653 flights in 2018 and 3302708 in 2019, which may indicate that there was slighly
more demand, based on this 2.61% increase.
*/

SELECT
COUNT(*) AS FlightsIn,
YEAR(FlightDate) AS Year
FROM flights
WHERE FlightDate BETWEEN '2018-01-01' AND '2019-12-31'
GROUP BY YEAR(FlightDate);

/*
Question 1 Part 2: 
Counting the total number of flights cancelled or departed late over both years gave us a count of 6428998. 
Compared to the total number of flights in total (2633237/6521361) = 0.4041. Which can tell us of any flight getting
delayed or canclled is 0.4%. However do note that factors such as weather and destination will impact this probability. 
*/ 

SELECT COUNT(*) AS TotalFlights
FROM flights
WHERE flightDate BETWEEN '2018-01-01' AND '2019-12-31';
  -- finding total number of flights (6521361)

SELECT COUNT(*) AS TotalCanOrDelay
FROM  flights 
WHERE (cancelled = 1) OR (DepDelay > 0) AND 
(FlightDate BETWEEN '2018-01-01' AND '2019-12-31'); -- Cancelled or delayed flights in 2018 and 2019 totalled 92363

/*
Question 1 Part 3: Show the number of flights that were cancelled, broken down by the reason for cancellation.

By separating the total number of cancellations by the reason, helps us understand the most possible reasons for 
cancellations. 
There were four cancellation reasons:
weather (50225), carrier (34141), national air system (7962), and security (35)

Finding the percentage of each reason used the formula (reason/ totalcancellations(92363)) which gives us:
Weather Percentage=57.88%
Carrier Percentage=39.38%
National Air System Percentage=9.15%
Security Percentage=0.04%
*/
SELECT CancellationReason, COUNT(*) AS TotalCancellation
FROM flights
WHERE cancelled = 1 AND CancellationReason = ('Weather' OR 'Carrier' OR 'National Air System' OR 'Security')
GROUP BY CancellationReason;
 
 /*
 Question 1 Part 4
By finding the total number of flights and percentage of flights cancelled for each month in 2019,
the cyclic nature of airline revenue seems to say that spring months see the highest cancellations 
and less during winter months. First extracting the month from the FlightDate and counting the total number of flights.
Then summing the number of cancelled flights, and calculating the percentage of cancelled flights 
by dividing the number of cancelled flights by the total number of flights and multiplying by 100 provides
us with the percent of cancelled flights per month.
The highest percentage of flights cancelled in months April(2.7%) and May(2.4%), 
the lowest percentage of flights were cancelled in months December(0.51%) and November(0.59%),
however given that there are more flights mid-year, this could put more strain on the airline industry/system and 
cause issues within their operations due to the lower capacity to handle the increased rate of flights. 
Knowing that flights that are cancelled usually incur large fees for the airline company, these expenses will decrease
their profits significantly. 
 */
 
SELECT 
MONTH(FlightDate) AS months, 
COUNT(*) AS TotalFlights,
SUM(cancelled = 1) AS CancelledFlights,
(SUM(cancelled = 1) / COUNT(*)) * 100 AS PercentCancelled
FROM flights WHERE YEAR(FlightDate) = 2019
GROUP BY months
ORDER BY PercentCancelled;
 

/*
Question 2 part 1:
Two tables for 2018 and 2019 showing the total miles traveled and number of flights broken down by airline.
*/

SELECT *  FROM Miles2018; -- take look at the table 

CREATE TABLE Miles2018 
SELECT 
AirlineName,
SUM(Distance) AS TotalMiles2018,
COUNT(ArrTime) AS TotalFlights2018 -- total flights that were not cancelled (must have arrived)
from flights WHERE YEAR(FlightDate) = 2018
GROUP BY AirlineName;

CREATE TABLE Miles2019 
SELECT 
	AirlineName,
	SUM(Distance) AS TotalMiles2019,
	COUNT(ArrTime) AS TotalFlights2019
from flights
WHERE YEAR(FlightDate) = 2019
GROUP BY AirlineName;
 
DROP TABLE IF EXISTS Miles2018, Miles2019; -- ensuring reproducibility

/*
Question 2 Part 2
The year-over-year percent change in total flights and miles traveled for each airline.
*/
/*
Investment guidance I can provide based on this:
The two airlines (Delta and American) show positive year-over-year percent changes in both total flights 
and total miles traveled, it might be a positive indicator for growth, potentially making it an attractive
investment. Its also good to consider that Southwest experienced a negative percent change, this is concerning as
it indicates that future performance is variable or may be negative, Southwest is one to divest in. 

The year-over-year percent change in total flights and miles traveled for each airline:
Delta Air Lines Inc. 		4.6981
American Airlines Inc. 		2.7549
Southwest Airlines Co. 		-0.2930
*/
SELECT 
  Miles2018.AirlineName,
  Miles2018.TotalFlights2018,
  Miles2019.TotalFlights2019,
  ((Miles2019.TotalFlights2019 - Miles2018.TotalFlights2018) / Miles2018.TotalFlights2018) * 100 
	AS PercentChangeFlights,
  Miles2018.TotalMiles2018,
  Miles2019.TotalMiles2019,
  ((Miles2019.TotalMiles2019 - Miles2018.TotalMiles2018) / Miles2018.TotalMiles2018) * 100 
	AS PercentChangeMiles
FROM
  Miles2018
INNER JOIN
  Miles2019
ON
  Miles2018.AirlineName = Miles2019.AirlineName;

/* 
Question 3 Part 1

This query retrieves the top 10 airports based on the total number of (non-cancelled) flights.
It joins the flights and airports tables on the DestAirportID and AirportID columns, the
groups the result by airports.AirportName and airports.AirportID.
The results are ordered by TotalFlights in descending order, and only the top 10 rows are returned.
By first joining the the elements from both tables, and then aggregating an grouping, this takes 
much longer to sort through the data to produce the output as it does all the heavy calculations before filtering
*/ 

-- this calculates the average flights of airports
SELECT 
  COUNT(flights.id) / COUNT(DISTINCT airports.AirportID) AS AverageFlightsOfAirport
  FROM flights
INNER JOIN airports 
	ON flights.DestAirportID = airports.AirportID
WHERE Cancelled = 0  ;

-- this finds the top 10 airports with the most flights
SELECT 
  airports.AirportID,
  airports.AirportName,
  COUNT(flights.id) AS TotalFlights -- calculates the total number of flights for each airport
FROM flights
INNER JOIN airports 
	ON flights.DestAirportID = airports.AirportID
WHERE Cancelled = 0  							-- condition excludes cancelled flights from the count.
GROUP BY airports.AirportName, airports.AirportID
	ORDER BY TotalFlights DESC
	LIMIT 10;

/*
Question 3 Part 2
Answer the same question but using a subquery to aggregate & limit the flight data before your join with the 
airport information, hence optimizing your query runtime.

This query uses a subquery (TopDest) to pre-calculate the counts for each destination airport first, 
so then the join with the airports table is performed on a smaller set of aggregated data.
The main query then joins the airports table with the aggregated results from the subquery on the AirportID and DestAirportID.
Which is then ordered by TotalFlights in descending order. 

This simpler version of the earlier query is much faster as 
it sorts and calculates less data, the subquery handles the bulk of the work efficiency, and the main function
combines the results, resulting in a shorter runtime. The previous query took 120 seconds to run, and the below subquery
took 20 seconds to run, a 6x decrease!

The airports the three airlines utilize most commonly are Hartsfield-Jackson Atlanta International (592229),
Dallas/Fort Worth International (307979), and Phoenix Sky Harbor International (250553), the former a significant increase
than the average number of flights of all airports (38728.9) 
*/

SELECT
    TopDest.DestAirportID, 
    airports.AirportName,
    TopDest.TotalFlights
FROM airports
JOIN (
    SELECT
        DestAirportID,
        COUNT(id) AS TotalFlights -- counts total flights first 
    FROM flights
    WHERE Cancelled = 0 -- Exclude cancelled flights
    GROUP BY DestAirportID
    ORDER BY TotalFlights DESC
    LIMIT 10
) AS TopDest -- returns most flights by airport destination, aliased ad TopDest
ON airports.AirportID = TopDest.DestAirportID 
ORDER BY TotalFlights DESC;



/*
Question 4 Part 1

 Although they dont directly provide information about fuel or equipment costs. The assumption 
is that the total miles traveled reflects total fuel costs, and the distance traveled per plane gives 
an approximation of total equipment costs.
 
 Out of the 3 Airlines that operated in 2018 and 2019, Southwest had the least airplanes out of the three,
 so planes from Southwest travelled an average that was 1.5327x more than Delta Air lines, and 1.4248x more
 than American Airlines. 
 
 Number of unique planes that each airline operates in 2018-19
993	- American Airlines Inc.
988	- Delta Air Lines Inc.
754	- Southwest Airlines Co.
*/

-- This query calculates the number of unique aircraft each airline operated during 2018-19.
SELECT 
	COUNT(DISTINCT Tail_Number) AS NumPlanes,
	AirlineName
FROM flights 
WHERE YEAR(FlightDate) BETWEEN '2018' AND '2019'
GROUP BY AirlineName
ORDER BY NumPlanes DESC;

/* Question 4 Part 2
A higher number of unique aircraft may indicate higher operating costs (likely related to maintenance, crew, 
 and overall management of a larger number of planes.) However, we dont know the size of the planes, so although Southwest has
the least number of planes, they may be significantly larger to sit more people. 

Since Southwest has a higher average distance per aircraft, it may suggest they have longer flights or better efficiency in utilizing each aircraft, 
which could impact fuel costs and operational costs.
Note that these are indirect indicators, and for a comprehensive financial analysis, financial data is needed for further analysis*/

/*
Query calculates the average distance traveled per aircraft for each airline over 2018-19.
Similarly, the total miles traveled by each airline gives an idea of total fuel costs and the 
distance traveled per plane gives an approximation of total equipment costs.

Average distance traveled per aircraft:
American Airlines Inc.		1884615.0241691843
Delta Air Lines Inc.		1752719.335020243
Southwest Airlines Co.		2684921.656498674
*/
SELECT 
	AirlineName,
    COUNT(DISTINCT Tail_Number) AS NumPlanes,
    SUM(Distance) AS TotalDistance,
    SUM(Distance) / COUNT(DISTINCT Tail_Number) AS AvgDistPerPlane -- total distance divided by number of planes
FROM flights 
WHERE YEAR(FlightDate) BETWEEN '2018' AND '2019'
GROUP BY AirlineName
ORDER BY NumPlanes DESC;


/*
Question 5 Part 1
On time performance indicates customer satisfaction which is key for choosing airline investments as 
they predict stock success. The query results show that evening flights experience the most delays, 
however, that may be because most are working in the afternoon and flights are most common during this
time of day. It may be better to select airlines that aim for night flights.
*/

-- This finds the average departure delay for each time-of-day combination
SELECT 
 AVG( 
 CASE WHEN DepDelay < 0 THEN 0 ELSE DepDelay -- since some departures are early, count as 0 rather than a negative value
    END
  ) AS AvgDepDelay,
CASE -- categorizes and names each time of day
    WHEN HOUR(CRSDepTime) BETWEEN 7 AND 11 THEN "1-morning"
    WHEN HOUR(CRSDepTime) BETWEEN 12 AND 16 THEN "2-afternoon"
    WHEN HOUR(CRSDepTime) BETWEEN 17 AND 21 THEN "3-evening"
    ELSE "4-night"
END AS TimeOfDay
FROM flights
GROUP BY TimeOfDay; -- splits by day

-- Question5 Part2 - the average departure delay for each airport and time-of-day combination.
/* the query combines flight and airport data, calculates the average departure delay for each 
 airport per time of day, and splits the results based on the time of day for each unique 
 combination of airport and time of day.
 
 This query shows that Napa County is actually earlier on average, especially during the night. 
 This may garner positive reviews for Pine Bluff Regional Airport Grider Field. 
*/

SELECT 
    airports.AirportName,
     AVG( 
		CASE WHEN DepDelay < 0 THEN 0 ELSE DepDelay 
	END) AS AvgDepDelay,
    CASE
        WHEN HOUR(flights.CRSDepTime) BETWEEN 7 AND 11 THEN '1-morning'
        WHEN HOUR(flights.CRSDepTime) BETWEEN 12 AND 16 THEN '2-afternoon'
        WHEN HOUR(flights.CRSDepTime) BETWEEN 17 AND 21 THEN '3-evening'
        ELSE '4-night'
    END AS TimeOfDay
FROM flights
INNER JOIN airports 
ON airports.id = flights.id 
WHERE flights.DepDelay IS NOT NULL -- excludes NULL values 
GROUP BY airports.AirportName, TimeOfDay
ORDER BY AvgDepDelay ASC;
  
/*
Question5 Part3 - 
This limits average departure delay analysis to morning delays and airports with at least 10,000 flights,
the query retrieves the average morning departure delay for airports with a scheduled departure time 
between 7 AM and 11 AM, and it excludes airports with fewer than 10,000 flights. 

This shows that Bob Hope Airport experiences the lowest average of average morning departure delays, which
may be a positive indicator for investing into as delays are a huge source of customer dissatistaction as it 
butterfly effects into other operational issues.
*/


SELECT 
    airports.AirportName,
         AVG( 
		CASE WHEN flights.DepDelay < 0 THEN 0 ELSE flights.DepDelay 
	END) AS AvgMornDepDelay,
    '1-morning' AS TimeOfDay
FROM flights
INNER JOIN airports 
ON airports.AirportID = flights.DestAirportID
WHERE HOUR(flights.CRSDepTime) BETWEEN 7 AND 11
GROUP BY airports.AirportName -- splits by the airport name
HAVING COUNT(flights.id) >= 10000 -- excludes flights under 10000
ORDER BY AvgMornDepDelay ASC; 

/*
Question5 Part4 - 
This query extends the query from the previous query and names the top-10 airports with
the highest average morning delay and the cities of the airports location. It first finds the average 
flight delay of all airports 

The results show that Newark Liberty International has the highest morning depart delay (14.53) and
is located in Newark, NJ. This can suggest poor operations within the airport, as the average delay is 
7.9055 and when compared to Newark (14.53), it says that the delay time is 2x the average for Newark.

Top ten airports and their cities with highest average morning delay
Newark Liberty International	- Newark, NJ
San Francisco International		- San Francisco, CA
John F. Kennedy International	- New York, NY
Dallas/Fort Worth International	- Dallas/Fort Worth, TX
Chicago O'Hare International	- Chicago, IL
Philadelphia International		- Philadelphia, PA
LaGuardia						- New York, NY
Miami International				- Miami, FL
Seattle/Tacoma International	- Seattle, WA
*/

SELECT 
    AVG( 
		CASE WHEN flights.DepDelay < 0 THEN 0 ELSE flights.DepDelay 
	END) AS AvgMornDepDelay
FROM flights
INNER JOIN airports 
ON airports.AirportID = flights.DestAirportID
WHERE HOUR(flights.CRSDepTime) BETWEEN 7 AND 11 
HAVING COUNT(flights.id) >= 10000; 

-- the top-10 airports (with >10000 flights) with the highest average morning delay
SELECT 
    airports.AirportName,
    airports.city,
    AVG( 
		CASE WHEN flights.DepDelay < 0 THEN 0 ELSE flights.DepDelay 
	END) AS AvgMornDepDelay,
    '1-morning' AS TimeOfDay
FROM flights
INNER JOIN airports 
ON airports.AirportID = flights.DestAirportID
WHERE HOUR(flights.CRSDepTime) BETWEEN 7 AND 11
GROUP BY airports.AirportName, airports.city -- splits by the airport name
HAVING COUNT(flights.id) >= 10000
ORDER BY AvgMornDepDelay DESC
LIMIT 10; 


/*
Conclusion: Since the fund managers are hoping to invest in one of the three main airlines, Southwest, American, 
and Delta, I provide a summary of my findings. 
Southwest is leading in having the most miles and lights in both 2018-2019, however, when comparing the change in 
both years, Southwest has a decreased number of total flights and miles compared to its previous year. Whereas the 
other two airlines, Delta and American, have increased their number of flights and miles. More notably, 
Delta Airlines, although the lowest total flights and miles compared to the rest, increased by 5.6% which can 
indicate that their future performance may be positive. As well, given their relatively lower demand now, their 
stock price may be lower now, and given the increased demand from 2018-2019, this may continue going up in coming years.

*/

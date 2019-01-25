 USE [User_FT]
 GO

IF (object_id('tempdb..#RepList') is not null) drop table #RepList
--IDENTIFY ALL TEAM MEMBERS TO ASSIGN CM TO EXCEPT MANAGEMENT

SELECT  ROW_NUMBER() over(ORDER BY newid()) ROW , [Name] AS [Assignee]
INTO #REPLIST
FROM [CMS].[Lookup].[User]
WHERE [Name] NOT IN ('#####', '#####','#####','#######') 


DECLARE @MAXROW AS INT  --How MANY times will the loop run
SET @MAXROW = (SELECT MAX(ROW) FROM #REPLIST)  -- Variable holding the number of reps 
--SET @MAXROW = 1  -- FOR TESTING TO ONLY assign 1 CM
DECLARE @name AS VARCHAR (100)   -- variable for team member


DECLARE @INTCOUNTER AS INT    --create counter variable for the loop
SET @INTCOUNTER = 1           -- set variable to look at row 1

WHILE @INTCOUNTER <= @MAXROW  --will make the loop go from row 1 to the last row
--WHILE @INTCOUNTER <= 1  --will make the loop go to row 1 for testing only 
BEGIN

--NAME OPTIONS---
SET @name = (SELECT [Assignee] FROM #REPLIST WHERE ROW = @INTCOUNTER) 


---INSERT CM INFO IN A TEMP TABLE
 
IF (object_id('tempdb..#TempC') is not null) drop table #TempC

CREATE TABLE #TempC 
( 
  [Request_ID] [INT],
  [StartDate] [DATE],
  [EndDate] [DATE],
  [Sys Prins] [Nvarchar](MAX)
)

INSERT INTO #TempC 

SELECT  TOP 5 
	 B.[Request_ID]
	,B.[StartDate]
    ,B.[EndDate]
	,B.[Sys Prins]	 ----TO ONLY SELECT 5 UNIQUE CM'S PER PERSON 	

FROM (SELECT  
		ROW_NUMBER() OVER(ORDER BY NewID()) AS ID
		,CM.[Request_ID]
		,CM.[StartDate]
		,CM.[EndDate]
		,CM.[Sys Prins]	 FROM [CMS].[Data].[CM_Master] CM 
 
	 WHERE CM_Status in ('User Testing','Post Validation','Completed')
		AND CM.request_type <> 'Bill Presentation'
		AND (CM.customer_type <> 'Commercial' OR (CM.customer_type = 'Commercial'AND CM.SubType <> 'CSG'))

---TO GET ACTIVE/PENDING TASKS 

		AND (CM.startdate <= getdate()-1) ---EVERYTHING THAT STARTED PRINTING IN THE PAST up to the day before thgis query is ran- 
		AND  (CM.enddate between getdate() and '2025-12-30') ---INCLUDING THOSE WITH NO END DATE (2025)
		AND CM.SubType not in ('Service Center','FCC','ReCat') ------BILL MESSAGES ONLY

		AND  NOT EXISTS (SELECT [CM#] FROM [dbo].[Assigned_CM] c2 where c2.[ASSIGNMENT DATE] = CAST(GETDATE() AS DATE)
                            AND [CM#] = CM.[Request_ID]) ----IF ALREADY STORED IN THE TRACKING TABLE TODAY DON'T SELECT AGAIN
		AND NOT EXISTS (SELECT [CM#]  FROM [dbo].[Assigned_CM] c1 where c1.[ASSIGNMENT DATE] = CAST(GETDATE()-7 AS DATE)
							AND c1.[ASSIGNED TO] = @name AND [CM#] = [Request_ID])  --- SAME INDIVIDUALS SHOULDN'T WORK ON THE SAME CM'S EVERY WEEK
						       ) B

--ORDER BY newid() 


---INSERT ASSIGNED TASK AND NAMES INTO TRACKING TABLE

INSERT INTO [dbo].[Assigned_CM]  ([CM#],[ASSIGNED TO],[ASSIGNMENT DATE],[STARTDATE],[EndDATE])

SELECT [Request_ID], @name AS [ASSINGED TO], CAST(GETDATE() AS DATE) AS [ASSIGNMENT DATE], [STARTDATE],[EndDATE]
FROM #TempC D


SET @INTCOUNTER = @INTCOUNTER + 1

END


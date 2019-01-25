USE [User_FT]
 GO
WITH     Task  AS (SELECT ROW_NUMBER() OVER(ORDER BY NewID()) AS ID, * 
						FROM [CMS].[Data].[CM_Master] CM 
						WHERE CM_Status in ('User Testing','Post Validation','Completed')
								and CM.request_type <> 'Bill Presentation'
								and (CM.customer_type <> 'Commercial'
								OR (CM.customer_type = 'Commercial'
								and CM.SubType <> 'CSG'))

								---TO GET ACTIVE CM'S 

								and (CM.startdate <= getdate()-1) ---EVERYTHING THAT STARTED PRINTING IN THE PAST up to the day before- 
								and  (CM.enddate between getdate() and '2025-12-30') ---INCLUDING THOSE WITH NO END DATE (2025)
								and CM.SubType not in ('Service Center','FCC','ReCat') ------BILL MESSAGES ONLY

								AND  NOT EXISTS (SELECT [CM#] 
													FROM [dbo].[Assigned_CM] c2 
													where c2.[ASSIGNMENT DATE] = CAST(GETDATE() AS DATE) 
														AND [CM#] = CM.[Request_ID]) ), ----IF ALREADY STORED IN THE TRACKING TABLE TODAY DON'T SELECT AGAIN
														 
          Employee    AS (SELECT ROW_NUMBER() OVER(ORDER BY NewID()) AS ID, * 
						FROM [CMS].[Lookup].[User] 
						WHERE [Name] NOT IN ('#####', '#####','#####','#######'))

INSERT INTO [dbo].[Assigned_CM]  ([CM#],[ASSIGNED TO],[ASSIGNMENT DATE],[STARTDATE],[EndDATE])

SELECT Task.Request_ID,Employee.[Name], CAST(GETDATE() AS DATE) AS [ASSIGNMENT DATE], Task.StartDate, Task.EndDate
		FROM Employee
			LEFT JOIN Task ON Employee.ID = FLOOR((Task.ID-1) % (SELECT COUNT(*) FROM Employee))+1
		Where NOT EXISTS (SELECT [CM#] 
							FROM [dbo].[Assigned_CM] c1 
							where c1.[ASSIGNMENT DATE] = CAST(GETDATE()-7 AS DATE)
									AND c1.[CM#] = Task.[Request_ID] 
									AND C1.[ASSIGNED TO]= Employee.[Name])
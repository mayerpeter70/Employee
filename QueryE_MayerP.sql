--E.1. Create a list of employees 

SELECT E.BusinessEntityID, CONCAT(P.LastName, ', ',P.FirstName,' ',P.MiddleName) AS Name, EA.EmailAddress, 
	CONCAT(PP.PhoneNumber,' (',PNT.Name,')')
FROM dbo.Employee E 
INNER JOIN dbo.Person P ON P.BusinessEntityID = E.BusinessEntityID
LEFT JOIN dbo.PersonPhone PP ON PP.BusinessEntityID = E.BusinessEntityID
LEFT JOIN dbo.EmailAddress EA ON EA.BusinessEntityID = E.BusinessEntityID
LEFT JOIN dbo.PhoneNumberType PNT ON PNT.PhoneNumberTypeID = PP.PhoneNumberTypeID 
ORDER BY Name
GO

--E.2. Employees having birthday today 

SELECT E.BusinessEntityID,E.BirthDate, CONCAT(P.LastName,' ,',P.FirstName,' ',P.MiddleName) AS Name
FROM dbo.Employee E
INNER JOIN dbo.Person P ON P.BusinessEntityID = E.BusinessEntityID
WHERE DAY(E.BirthDate) = DAY(GETDATE()) AND MONTH(E.BirthDate) = MONTH(GETDATE())
ORDER BY Name

--E.3. Employees having been working at multiple departments  

SELECT DISTINCT E.BusinessEntityID, CONCAT(P.LastName,', ',P.FirstName,' ',P.MiddleName) EmpName
FROM Employee E
INNER JOIN Person P ON P.BusinessEntityID = E.BusinessEntityID
INNER JOIN EmployeeDepartmentHistory EDH ON EDH.BusinessEntityID = E.BusinessEntityID
WHERE EDH.EndDate IS NOT NULL
ORDER BY EmpName

--E.4.Employees currently working alone in any Shift at any Department

SELECT MIN(E.BusinessEntityID) BizID, MIN(CONCAT(P.LastName,', ',P.FirstName,' ',P.MiddleName)) PersonName, S.Name,D.Name
FROM Employee E
LEFT JOIN EmployeeDepartmentHistory EDH ON EDH.BusinessEntityID = E.BusinessEntityID
LEFT JOIN Person P ON P.BusinessEntityID = E.BusinessEntityID
LEFT JOIN Shift S ON S.ShiftID = EDH.ShiftID
LEFT JOIN Department D ON D.DepartmentID = EDH.DepartmentID
GROUP BY D.Name, S.Name
HAVING COUNT(D.Name)=1
ORDER BY PersonName

/*H.1.
List employees being active at a pre-given day (default value: today)*/


DECLARE @Year date = CONVERT(date,GETDATE())
SELECT STRING_AGG(CONCAT(P.LastName,', ',P.FirstName,' ',P.MiddleName), ', ') Staff, D.Name Department, S.Name Shift
FROM Employee E
LEFT JOIN Person P ON P.BusinessEntityID = E.BusinessEntityID
LEFT JOIN EmployeeDepartmentHistory EDH ON EDH.BusinessEntityID = E.BusinessEntityID
LEFT JOIN Department D ON D.DepartmentID = EDH.DepartmentID
LEFT JOIN Shift S ON S.ShiftID = EDH.ShiftID
WHERE EDH.StartDate < @Year AND (EDH.EndDate IS NULL OR EDH.EndDate  > CONVERT(date,GETDATE()))
GROUP BY D.Name, S.StartTime, S.Name
ORDER BY S.StartTime

/*H.2.
List salespersons who sold at least one bike */

--PC.ProductCategoryID (1) -> LIKE %Bike%
SELECT DISTINCT SOH.SalesPersonID, MIN(CONCAT(P.LastName,', ',P.FirstName,' ',P.MiddleName)) PersonName, 
	YEAR(SOH.DueDate) Year, COUNT(SOH.SalesOrderID)
FROM SalesOrderHeader SOH
INNER JOIN Person P ON P.BusinessEntityID = SOH.SalesPersonID
INNER JOIN SalesOrderDetail SOD ON SOD.SalesOrderID = SOH.SalesOrderID
LEFT JOIN Product PR ON PR.ProductID = SOD.ProductID
LEFT JOIN ProductSubcategory PRS ON PRS.ProductSubcategoryID = PR.ProductSubcategoryID
WHERE SOH.SalesPersonID IS NOT NULL AND PRS.Name LIKE '%Bike%'
GROUP BY SOH.SalesPersonID, YEAR(SOH.DueDate)
ORDER BY SOH.SalesPersonID

/*H.3.
Monthly sales to vendors per salesperson  
*/

SELECT SOH.SalesPersonID BusinessEntityID, MIN(CONCAT(P.LastName,', ',P.FirstName,' ',P.MiddleName)) PersonName, 
	SUM(SOH.SubTotal), DATEPART(YEAR,SOH.DueDate) Year, DATEPART(MONTH,SOH.DueDate) Month, 
FROM SalesOrderHeader SOH
LEFT JOIN Customer C ON C.CustomerID = SOH.CustomerID
LEFT JOIN Person P ON P.BusinessEntityID = SOH.SalesPersonID
WHERE C.StoreID IS NOT NULL
GROUP BY SOH.SalesPersonID, DATEPART(YEAR,SOH.DueDate), DATEPART(MONTH,SOH.DueDate)
ORDER BY PersonName, Year, Month

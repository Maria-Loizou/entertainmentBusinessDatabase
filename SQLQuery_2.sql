--CREATE DATABASE mydb

USE mydb
GO
--DROP THE TABLES IF THEY EXIST
--DROP FIRST THE REFERENCING, THEN THE REFERED 
DROP TABLE IF EXISTS dbo.Tickets
DROP TABLE IF EXISTS dbo.Customers
DROP TABLE IF EXISTS dbo.Memberships
DROP TABLE IF EXISTS dbo.Companies
DROP TABLE IF EXISTS dbo.Countries
DROP TABLE IF EXISTS dbo.Events
DROP TABLE IF EXISTS dbo.MembershipTypes

--CREATE TABBLES
--CREATE FIRST THE REFERED, TEHN THE REFERENCING

CREATE TABLE dbo.MembershipTypes(
    id NVARCHAR(50) PRIMARY KEY,
    name NVARCHAR(50)
);

CREATE TABLE dbo.Events(
    id NVARCHAR(50) PRIMARY KEY,
    eventName NVARCHAR(50) NOT NULL,
    eventDate DATE NOT NULL CHECK (eventDate >= '2022-01-01' AND eventDate <= '2023-12-31')
);

CREATE TABLE dbo.Countries(
    countryCode NVARCHAR(50) PRIMARY KEY,
    countryName NVARCHAR(50)
);

CREATE TABLE dbo.Companies(
    id NVARCHAR(50) PRIMARY KEY,
    name NVARCHAR(50)
);

CREATE TABLE dbo.Memberships(
    id NVARCHAR(50) PRIMARY KEY,
    membershipTypeId NVARCHAR(50) FOREIGN KEY REFERENCES dbo.MembershipTypes(id),
    validUntil DATE
);

CREATE TABLE dbo.Customers(
    firstName NVARCHAR(50) NOT NULL,
    lastName NVARCHAR(50) NOT NULL,
    middleName NVARCHAR(50),
    email NVARCHAR(50) PRIMARY KEY,
    membershipId NVARCHAR(50) FOREIGN KEY REFERENCES dbo.Memberships(id),
    gender NVARCHAR(1) NOT NULL CHECK (gender IN ('M', 'm', 'F', 'f')),
    dob DATE NOT NULL CHECK (dob >= '1920-01-01' AND dob <= '2020-12-31'),
    partnerId NVARCHAR(50) FOREIGN KEY REFERENCES dbo.Companies(id),
    country NVARCHAR(50) NOT NULL FOREIGN KEY REFERENCES dbo.Countries(countryCode),  
);

CREATE TABLE dbo.Tickets(
    price FLOAT CHECK (price >= 0),
    eventId NVARCHAR(50) NOT NULL FOREIGN KEY REFERENCES dbo.Events(id),
    email NVARCHAR(50) NOT NULL FOREIGN KEY REFERENCES dbo.Customers(email),
    used NUMERIC(1) CHECK (used IN (0,1))
    
);

--BULK INSERT DATA 
BULK INSERT dbo.Companies
FROM '/Companies.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.Countries
FROM '/Countries.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.Customers
FROM '/Customers.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.Events
FROM '/Events.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.Memberships
FROM '/Memberships.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.Tickets
FROM '/Tickets.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

BULK INSERT dbo.MembershipTypes
FROM '/MembershipTypes.csv'
WITH
(
	FORMAT='CSV',
	FIRSTROW=2
);

--Query 1 
SELECT E.eventName, count(T.eventId) AS numberOfTickets
FROM Events AS E
INNER JOIN Tickets AS T
ON E.id = T.eventId
GROUP BY E.eventName
HAVING count(T.eventId) = (
SELECT MAX(eventTicketsSold.ticketCount) 
FROM (SELECT T.eventId, count(T.eventId) AS ticketCount
FROM Tickets AS T
GROUP BY T.eventID) AS eventTicketsSold)
ORDER BY E.eventName ASC

--Query 2
SELECT country, count(eventID)AS numberOfEvents
FROM (SELECT country, eventID
FROM Customers AS C
LEFT JOIN Tickets AS T
ON C.email = T.Email
GROUP BY C.country, eventID) AS eventsInCountries
GROUP BY country
ORDER BY numberOfEvents DESC

--Query 3
SELECT TOP 1 MT.name, avg(T.price)AS averageRevenue
FROM Customers AS C
INNER JOIN Tickets AS T 
ON C.email = T.email
INNER JOIN Memberships AS M
ON C.membershipId = M.id
INNER JOIN MembershipTypes AS MT 
ON M.membershipTypeId = MT.id
WHERE T.used = 1 
GROUP BY MT.name
ORDER BY averageRevenue DESC

--Query 4 
WITH named_membership AS (SELECT Customers.email, Customers.partnerId, Memberships.membershipTypeId, MembershipTypes.name
FROM Customers 
LEFT JOIN Memberships
ON Customers.membershipId = Memberships.id
LEFT JOIN MembershipTypes
ON MembershipTypes.id = Memberships.membershipTypeId)
SELECT Companies.name AS companyName, MembershipTypes.name AS membershipTypeName, count(membershipTypeId) AS numberOfCustomers
FROM Companies
CROSS JOIN MembershipTypes
LEFT JOIN named_membership
ON Companies.id = named_membership.partnerId AND MembershipTypes.name = named_membership.name
GROUP BY Companies.name, MembershipTypes.name
ORDER BY Companies.name DESC

-- Query 5 
SELECT TOP 1 E.eventName, E.eventDate, count(T.eventId) AS numberOfUnusedTickets
FROM Events AS E
INNER JOIN Tickets As T
ON E.id = T.eventId
WHERE T.used = 0 
GROUP BY E.eventName, E.eventDate
ORDER BY numberOfUnusedTickets ASC,eventDate DESC

--Query 6 
SELECT C.gender, COUNT(C.gender) AS numberOfAdults
FROM Customers AS C 
WHERE 18 <= DATEDIFF(YEAR, dob, GETDATE()) 
GROUP BY C.gender

--Query 7 
SELECT C.email, M.validUntil AS expirationDate
FROM Customers AS C
INNER JOIN Memberships AS M
ON C.membershipId = M.id
WHERE M.validUntil BETWEEN GETDATE() AND DATEADD ("d", 14, GETDATE())

-------------------------------------------------------------------------








--Query 4 
SELECT C.name AS companyName, MT.name AS membershipName, count(Cust.email) AS numberOfCustomers
FROM Companies AS C
INNER JOIN Customers AS Cust
ON Cust.partnerId = C.id
FULL OUTER JOIN Memberships as M
ON Cust.membershipId = M.id
FULL OUTER JOIN MembershipTypes AS MT
ON M.membershipTypeId = MT.id
GROUP BY C.name, MT.name
ORDER BY C.name DESC






--Query 4 
SELECT  C.name AS companyName, MT.name AS membershipName, COUNT(Cust.email)
FROM Companies AS C
LEFT JOIN Customers AS Cust
ON Cust.partnerId = C.id
LEFT JOIN Memberships as M
ON Cust.membershipId = M.id
LEFT JOIN MembershipTypes AS MT
ON M.membershipTypeId = MT.id
GROUP BY C.name, MT.name
ORDER BY C.name DESC


SELECT C.name AS companyName, MT.name AS membershipName
FROM Companies AS C
FULL OUTER JOIN Customers AS Cust
ON Cust.partnerId = C.id
LEFT JOIN Memberships as M
ON Cust.membershipId = M.id
FULL OUTER JOIN MembershipTypes AS MT
ON M.membershipTypeId = MT.id
ORDER BY C.name DESC


SELECT C.name AS companyName, MT.name AS membershipName
FROM Memberships as M 
INNER JOIN MembershipTypes AS MT 
ON M.membershipTypeId = MT.id
FULL OUTER JOIN Customers as Cust
ON Cust.membershipId = M.id
FULL OUTER JOIN Companies as C
ON Cust.partnerId = C.id
ORDER BY C.name DESC


SELECT  Co.name
FROM Companies AS Co
LEFT JOIN Customers AS Cust
ON Cust.partnerId = Co.id 
INNER JOIN (SELECT *
FROM Companies as C
CROSS JOIN MembershipTypes as MT) as CompanyMemberships
ON Co.name = CompanyMemberships.name

SELECT C.name AS companyName, MT.name AS membershipName , count(Cust.email)
FROM Companies AS C
INNER JOIN Customers AS Cust
ON Cust.partnerId = C.id
RIGHT JOIN Memberships AS M
ON Cust.membershipId = M.id
RIGHT JOIN MembershipTypes AS MT
ON MT.id = M.membershipTypeId
GROUP BY C.name, MT.name
ORDER BY C.name DESC



SELECT * --C.name AS companyName, MT.name AS membershipName, COUNT(Cust.email)
FROM Companies AS C
LEFT JOIN Customers AS Cust
ON Cust.partnerId = C.id
LEFT JOIN Memberships as M
ON Cust.membershipId = M.id
CROSS APPLY MembershipTypes AS MT
ORDER BY C.name DESC

SELECT *
FROM Customers 
INNER JOIN Companies 
ON partnerId = Companies.id 
RIGHT JOIN Memberships 
ON membershipId = Memberships.id 
LEFT JOIN (SELECT *
FROM Companies 
CROSS JOIN MembershipTypes) 
 
SELECT *
FROM MembershipTypes AS MT 
RIGHT JOIN Memberships AS M
ON M.membershipTypeId = MT.id

   

WITH named_membership AS (SELECT Customers.email, Customers.partnerId, Memberships.membershipTypeId, MembershipTypes.name
FROM Customers 
LEFT JOIN Memberships
ON Customers.membershipId = Memberships.id
LEFT JOIN MembershipTypes
ON MembershipTypes.id = Memberships.membershipTypeId)
SELECT * --Companies.name, MembershipTypes.name, COUNT(membershipTypeID)
FROM named_membership
LEFT JOIN Companies
ON named_membership.partnerId = Companies.id
CROSS JOIN MembershipTypes
--GROUP BY Companies.name, MembershipTypes.name
ORDER BY Companies.name DESC

WITH named_membership AS (SELECT Customers.email, Customers.partnerId, Memberships.membershipTypeId, MembershipTypes.name
FROM Customers 
LEFT JOIN Memberships
ON Customers.membershipId = Memberships.id
LEFT JOIN MembershipTypes
ON MembershipTypes.id = Memberships.membershipTypeId)
SELECT Companies.name, MembershipTypes.name, count(membershipTypeId)
FROM Companies
CROSS JOIN MembershipTypes
LEFT JOIN named_membership
ON Companies.id = named_membership.partnerId AND MembershipTypes.name = named_membership.name
GROUP BY Companies.name, MembershipTypes.name
ORDER BY Companies.name DESC

SELECT  C.name AS companyName, MT.name AS membershipName, COUNT(Cust.email)
FROM Companies AS C
LEFT JOIN Customers AS Cust
ON Cust.partnerId = C.id
LEFT JOIN Memberships as M
ON Cust.membershipId = M.id
LEFT JOIN MembershipTypes AS MT
ON M.membershipTypeId = MT.id
GROUP BY C.name, MT.name
ORDER BY C.name DESC
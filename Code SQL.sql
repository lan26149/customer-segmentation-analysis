CREATE DATABASE RFM
GO 

USE RFM
GO

ALTER TABLE Superstore ADD CONSTRAINT PK1 PRIMARY KEY (Row_ID)
GO

-- Mô tả dữ liệu
SELECT * FROM Superstore
GO 

SELECT COUNT(*) FROM Superstore
GO
-- 10194

SELECT MAX(Order_Date), MIN(Order_Date)
FROM Superstore
GO
-- Max: 2023-12-30
-- Min: 2020-01-03

SELECT COUNT(DISTINCT Order_ID) FROM Superstore
GO
-- 5111

SELECT COUNT(DISTINCT Customer_ID) FROM Superstore
GO 
--804

-- Xử lý dữ liệu
SELECT Customer_ID, Customer_Name,
	DATEDIFF(DAY, MAX(Order_Date), '2023-12-30') AS Recency,
	COUNT(DISTINCT Order_ID) AS Frequency,
	ROUND(CAST(SUM(Sales) AS FLOAT),2) AS Monetary,
	ROW_NUMBER() OVER (ORDER BY (DATEDIFF(DAY, MAX(Order_Date), '2023-12-30')) DESC) AS rn_Recency,
	ROW_NUMBER() OVER (ORDER BY (COUNT(DISTINCT Order_ID))) AS rn_Frequency,
	ROW_NUMBER() OVER (ORDER BY (ROUND(CAST(SUM(Sales) AS FLOAT),2))) AS rn_Monetary
INTO #Processing
FROM Superstore
GROUP BY Customer_ID, Customer_Name

SELECT *, 
  CASE
	WHEN Recency > ( SELECT Recency FROM #Processing WHERE rn_Recency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing)) THEN '1'
	WHEN Recency > ( SELECT Recency FROM #Processing WHERE rn_Recency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing))
		AND Recency <= (SELECT Recency FROM #Processing WHERE rn_Recency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing)) THEN '2'
	WHEN Recency > ( SELECT Recency FROM #Processing WHERE rn_Recency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.75 AS INT) FROM #Processing))
		AND Recency <= (SELECT Recency FROM #Processing WHERE rn_Recency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing)) THEN '3'
	ELSE '4' END AS R_score,
  CASE 
	WHEN Frequency < ( SELECT Frequency FROM #Processing WHERE rn_Frequency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing))
		AND Frequency >= ( SELECT Frequency FROM #Processing WHERE rn_Frequency = 1) THEN '1'
	WHEN Frequency < ( SELECT Frequency FROM #Processing WHERE rn_Frequency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing))
		AND Frequency >= (SELECT Frequency FROM #Processing WHERE rn_Frequency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing)) THEN '2'
	WHEN Frequency < ( SELECT Frequency FROM #Processing WHERE rn_Frequency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.75 AS INT) FROM #Processing))
		AND Frequency >= (SELECT Frequency FROM #Processing WHERE rn_Frequency = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing)) THEN '3'
	ELSE '4' END AS F_score,
  CASE 
	WHEN Monetary < ( SELECT Monetary FROM #Processing WHERE rn_Monetary = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing))
		AND Monetary >= ( SELECT Monetary FROM #Processing WHERE rn_Monetary = 1) THEN '1'
	WHEN Monetary < ( SELECT Monetary FROM #Processing WHERE rn_Monetary = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing))
		AND Monetary >= (SELECT Monetary FROM #Processing WHERE rn_Monetary = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.25 AS INT) FROM #Processing)) THEN '2'
	WHEN Monetary < ( SELECT Monetary FROM #Processing WHERE rn_Monetary = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.75 AS INT) FROM #Processing))
		AND Monetary >= (SELECT Monetary FROM #Processing WHERE rn_Monetary = (SELECT CAST(COUNT(DISTINCT Customer_ID)*0.5 AS INT) FROM #Processing)) THEN '3'
	ELSE '4' END AS M_score
INTO #Calculation
FROM #Processing

SELECT *, CONCAT(R_score,F_score,M_score) AS Segment INTO #Result FROM #Calculation

SELECT *, CASE
	WHEN Segment IN ('444', '443', '434', '344') THEN 'Champions'
	WHEN Segment IN ('442', '433', '432', '343', '334') THEN 'Loyal Customer'
	WHEN Segment IN ('441', '431', '423', '342', '341', '333', '332', '331', '323') THEN 'Potential Loyalist'
	WHEN Segment IN ('422', '421', '412', '411', '322', '321', '312', '311') THEN 'Recent Customer'
	WHEN Segment IN ('424', '414', '413', '324', '314', '313') THEN 'Promising'
	WHEN Segment IN ('244', '243', '242', '234', '233', '232', '224', '142', '133') THEN 'Customers Needing Attention'
	WHEN Segment IN ('241', '231', '222', '221', '213', '212', '211', '141', '132', '131', '123', '122') THEN 'About to Sleep'
	WHEN Segment IN ('214', '144', '143', '134', '114', '113') THEN 'Can''t Lose Them'
	ELSE 'Lost Customer' END AS Customer_Segmentation
INTO #Segmentation
FROM #Result

SELECT * INTO Segmentation FROM #Segmentation

SELECT * FROM Segmentation
GO

-- Mô hình hóa dữ liệu
ALTER TABLE Segmentation ADD CONSTRAINT PK2 PRIMARY KEY (Customer_ID)
GO

ALTER TABLE Superstore ADD CONSTRAINT FK1 FOREIGN KEY (Customer_ID) REFERENCES Segmentation (Customer_ID)
GO

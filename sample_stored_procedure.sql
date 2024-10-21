INSERT INTO VT_PDA_LU_TIME

SELECT PROMO_WEEK_ID AS WEEK_ID  

, NULL AS WEEK_ID_MINUS_1
, NULL AS PGM_PERIOD_ID
, NULL AS FISCAL_WEEK_ID
, NULL AS FISCAL_QUARTER_ID
, NULL AS UPDATE_TS_MT

FROM DW_DSS.LU_PROMO_DAY

WHERE DIVISION_ID = 25 

AND D_DATE = (
  SELECT D_DATE
  FROM DW_DSS.LU_DAY_MERGE
  WHERE WEEKDAY_NBR = 4  
  AND WEEK_ID = (
    SELECT WEEK_ID
    FROM DW_DSS.LU_DAY_MERGE
    WHERE D_DATE = CURRENT_DATE + 7  
    GROUP BY 1)
  GROUP BY 1)   

GROUP BY 1;


   


UPDATE VT_PDA_LU_TIME

SET WEEK_ID_MINUS_1 = (
  
  SELECT PROMO_WEEK_ID  
 
  FROM DW_DSS.LU_PROMO_DAY
  
  WHERE DIVISION_ID = 25 
  
  AND D_DATE = (
    SELECT D_DATE
    FROM DW_DSS.LU_DAY_MERGE
    WHERE WEEKDAY_NBR = 4  
    AND WEEK_ID = (
      SELECT WEEK_ID
      FROM DW_DSS.LU_DAY_MERGE
      WHERE D_DATE = CURRENT_DATE  
      GROUP BY 1)
    GROUP BY 1)
  
  GROUP BY 1);

  



UPDATE VT_PDA_LU_TIME

SET PGM_PERIOD_ID = (
   
   SELECT PERIOD_ID AS PGM_PERIOD_ID
  
   FROM
  
    (SELECT PERIOD_ID, RANK() OVER (ORDER BY MAX(PERIOD_ID) DESC) - 1 AS COMPLETED_PROMO_PERIODS_BEFORE_ALLOCATION_WEEK  
    FROM DW_DSS.LU_PROMO_DAY
    WHERE DIVISION_ID = 25 
    AND D_DATE <= (
      SELECT D_DATE
      FROM DW_DSS.LU_DAY_MERGE
      WHERE WEEKDAY_NBR = 4  
      AND WEEK_ID = (
        SELECT WEEK_ID
        FROM DW_DSS.LU_DAY_MERGE
        WHERE D_DATE = CURRENT_DATE + 7  
        GROUP BY 1)
      GROUP BY 1)      
      
    GROUP BY 1) AS X
   
   WHERE COMPLETED_PROMO_PERIODS_BEFORE_ALLOCATION_WEEK = 2  
   
   GROUP BY 1);  





UPDATE VT_PDA_LU_TIME AS A

SET FISCAL_WEEK_ID = B.WEEK_ID
, FISCAL_QUARTER_ID = B.QUARTER_ID 
FROM (

  SELECT WEEK_ID, QUARTER_ID 
  FROM DW_DSS.LU_DAY_MERGE 
  WHERE D_DATE = (
   SELECT MAX(D_DATE) 
   FROM DW_DSS.LU_PROMO_DAY
   WHERE DIVISION_ID = 25  
   AND PROMO_WEEK_ID = (SELECT WEEK_ID FROM VT_PDA_LU_TIME GROUP BY 1)  
   )
       
  GROUP BY 1,2

) AS B;

 






UPDATE VT_PDA_LU_TIME
SET UPDATE_TS_MT = CURRENT_TIMESTAMP;




DELETE FROM TEMP_MARKETING.PDA_LU_TIME; 



INSERT INTO TEMP_MARKETING.PDA_LU_TIME

SELECT *
FROM VT_PDA_LU_TIME;









CREATE OR REPLACE TABLE TEMP_MARKETING.PDA_LU_HH (
HOUSEHOLD_ID BIGINT
, PRIM_STORE_ID INT
, J4U_REGION_ID INT
, DIVISION_ID INT
, REGISTERED_IND BYTEINT
, ALCOHOL_BUYER_IND BYTEINT
, BABY_BUYER_IND BYTEINT
, BEEF_BUYER_IND BYTEINT
, CAT_BUYER_IND BYTEINT
, CHICKEN_BUYER_IND BYTEINT
, DOG_BUYER_IND BYTEINT
, PORK_BUYER_IND BYTEINT
, SEAFOOD_BUYER_IND BYTEINT
, UPDATE_TS_MT TIMESTAMP
) ;





INSERT INTO TEMP_MARKETING.PDA_LU_HH

SELECT A.HOUSEHOLD_ID
, A.PRIM_STORE_ID
, A.DIVISION_ID AS J4U_REGION_ID
, CASE WHEN A.DIVISION_ID = 26 THEN 25 WHEN A.DIVISION_ID = 28 THEN 27 ELSE A.DIVISION_ID END AS DIVISION_ID
, CASE WHEN B.HOUSEHOLD_ID IS NOT NULL THEN 1 ELSE 0 END AS REGISTERED_IND
, 0 AS ALCOHOL_BUYER_IND
, 0 AS BABY_BUYER_IND
, 0 AS BEEF_BUYER_IND
, 0 AS CAT_BUYER_IND
, 0 AS CHICKEN_BUYER_IND
, 0 AS DOG_BUYER_IND
, 0 AS PORK_BUYER_IND
, 0 AS SEAFOOD_BUYER_IND
, CURRENT_TIMESTAMP UPDATE_TS_MT  

FROM TEMP_CMS.JAA_HH_DIV_PRIMARY_STORE AS A    

LEFT JOIN TEMP_MARKETING.J4U_ONLINE_REGISTERED_HHS AS B   
ON A.HOUSEHOLD_ID = B.HOUSEHOLD_ID
AND B.J4U_FIRST_VISIT_DT IS NOT NULL

WHERE A.PGM_PERIOD_ID = (SELECT PGM_PERIOD_ID FROM TEMP_MARKETING.PDA_LU_TIME GROUP BY 1)

AND A.DIVISION_ID IN (5,17,19,20,25,26,27,28,29,30,32,33,34,35)

GROUP BY 1,2,3,4,5;




UPDATE TEMP_MARKETING.PDA_LU_HH AS A

SET BABY_BUYER_IND = B.BABY_BUYER_IND
, DOG_BUYER_IND = B.DOG_BUYER_IND
, CAT_BUYER_IND = B.CAT_BUYER_IND
, CHICKEN_BUYER_IND = B.CHICKEN_BUYER_IND
, BEEF_BUYER_IND = B.BEEF_BUYER_IND
, PORK_BUYER_IND = B.PORK_BUYER_IND
, SEAFOOD_BUYER_IND = B.SEAFOOD_BUYER_IND
, ALCOHOL_BUYER_IND = B.ALCOHOL_BUYER_IND

FROM (
  
  SELECT HOUSEHOLD_ID 
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 1 AND ATTRIBUTE_FLAG = 1 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS BABY_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 2 AND ATTRIBUTE_FLAG = 1 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS DOG_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 3 AND ATTRIBUTE_FLAG = 1 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS CAT_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 4 AND ATTRIBUTE_FLAG = 1 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS CHICKEN_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 4 AND ATTRIBUTE_FLAG = 2 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS BEEF_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 4 AND ATTRIBUTE_FLAG = 3 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS PORK_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 4 AND ATTRIBUTE_FLAG = 4 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS SEAFOOD_BUYER_IND
  , CASE WHEN COUNT(CASE WHEN ATTRIBUTE_ID = 5 AND ATTRIBUTE_FLAG = 1 THEN HOUSEHOLD_ID END) > 0 THEN 1 ELSE 0 END AS ALCOHOL_BUYER_IND
  
  FROM TEMP_CMS.AA_J4U_HH_ATTRIBUTES 
  
  WHERE RUN_ID = (SELECT PGM_PERIOD_ID FROM TEMP_MARKETING.PDA_LU_TIME GROUP BY 1)
  
  GROUP BY 1

) AS B

WHERE A.HOUSEHOLD_ID = B.HOUSEHOLD_ID;







UPDATE TEMP_MARKETING.PDA_LU_HH
SET UPDATE_TS_MT = CURRENT_TIMESTAMP;





















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_LU_OFFER (
OFFER_NBR INT
, OFFER_DSC VARCHAR(100)
, REP_UPC BIGINT
, CLASS_ID INT
, CATEGORY_ID INT
, GROUP_ID INT
, DEPT_NM VARCHAR(100)
, ATTRIBUTE_NM VARCHAR(50)
, UPDATE_TS_MT TIMESTAMP
) 
;







INSERT INTO VT_PDA_LU_OFFER

SELECT A.OFFER_NBR
, A.OFFER_DSC
, A.REP_UPC
, B.CLASS_ID
, B.CATEGORY_ID
, B.GROUP_ID
, D.DEPT_NM
, NULL AS ATTRIBUTE_NM
, NULL AS UPDATE_TS_MT

FROM 
  
  (SELECT OFFER_NBR, REP_UPC, SUBSTR(MAX(TRIM(COALESCE(VERBIAGE1,'')) || ' ' || TRIM(COALESCE(VERBIAGE2,'')) || ' ' || TRIM(COALESCE(VERBIAGE3,''))),1,100) AS OFFER_DSC
  , ROW_NUMBER() OVER (PARTITION BY OFFER_NBR ORDER BY COUNT(*) DESC) RNK
  FROM TEMP_CMS.JAA_CONSOL_OFF_BNK 
  WHERE WEEK_ID = (SELECT WEEK_ID FROM TEMP_MARKETING.PDA_LU_TIME GROUP BY 1) 
  AND PROGRAM_TYPE = 'DIVWKLY' 
  AND PROGRAM_SUBTYPE NOT LIKE '%DEFAULT%'
  AND REP_UPC > 0

  GROUP BY 1,2) AS A

JOIN DW_DSS.LU_UPC AS B
ON A.REP_UPC = B.UPC_ID
AND A.RNK = 1 
JOIN 

  (SELECT CATEGORY_ID, DEPARTMENT_ID 
  FROM DW_DSS.LU_RESPONSIBILITY 
  WHERE CORPORATION_ID = 1 
  GROUP BY 1,2) AS C
  
ON B.CATEGORY_ID = C.CATEGORY_ID
  
JOIN TEMP_MARKETING.SES_UPC_HIER AS D  
ON C.DEPARTMENT_ID = D.DEPARTMENT_ID

GROUP BY 1,2,3,4,5,6,7
;







UPDATE VT_PDA_LU_OFFER AS A

SET ATTRIBUTE_NM = B.ATTRIBUTE_NM

FROM (
  SELECT OFFER_NBR
  
  
  
  , CASE 
  
   WHEN GROUP_ID = 65
     AND CATEGORY_ID NOT IN (6530,6540) 
     AND CLASS_ID NOT IN (651105,651110)
    THEN 'BABY'
  
  WHEN CATEGORY_ID IN (3206,3207,3209,3210)   
    THEN 'CAT'
  
  WHEN CATEGORY_ID IN (3201,3202,3203,3204)  
    THEN 'DOG'
  
  WHEN GROUP_ID = 89 
     AND CATEGORY_ID NOT IN (8955,8935) 
    THEN 'ALCOHOL'
   
  WHEN CATEGORY_ID IN (8104,8830,8833,8840,8841,8846,8866, 8203,8857, 8858, 8863)
    THEN 'CHICKEN'
   
  WHEN CATEGORY_ID IN (8801,8802,8804,8810,8820,8850,8815,8808)
    THEN 'BEEF'    
  
  WHEN CATEGORY_ID IN (8825,8855,8856,8859,4505, 8853)
    THEN 'PORK'    
   
  WHEN CATEGORY_ID IN (8608,8610,8615,8625,8630,8632,8640,8645,8650,8655,8685,8690,8693,8695, 2301,2305)
    THEN 'SEAFOOD' 
  
  END AS ATTRIBUTE_NM
  
  
 
  FROM VT_PDA_LU_OFFER
  
  GROUP BY 1,2

) AS B

WHERE A.OFFER_NBR = B.OFFER_NBR;



 









UPDATE VT_PDA_LU_OFFER
SET UPDATE_TS_MT = CURRENT_TIMESTAMP; 


DELETE FROM TEMP_MARKETING.PDA_LU_OFFER;



INSERT INTO TEMP_MARKETING.PDA_LU_OFFER

SELECT *
FROM VT_PDA_LU_OFFER;






















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_LU_OFFER_UPCS (
UPC_ID BIGINT
, OFFER_NBR INT
, OFFER_DSC VARCHAR(100)
, DEPARTMENT_ID INT
, DEPARTMENT_NM VARCHAR(100)
, GROUP_ID INT
, GROUP_NM VARCHAR(100)
, CATEGORY_ID INT
, CATEGORY_NM VARCHAR(100)
, CLASS_ID INT
, CLASS_NM VARCHAR(100)
, ATTRIBUTE_NM VARCHAR(50)
, MANUF_TYPE_CD VARCHAR(5)
, BRAND_CD INT
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;







INSERT INTO VT_PDA_LU_OFFER_UPCS

SELECT B.UPC_ID
, MIN(C.OFFER_NBR) AS OFFER_NBR
, NULL AS OFFER_DSC
, 0 AS DEPARTMENT_ID
, NULL AS DEPARTMENT_NM
, 0 AS GROUP_ID
, NULL AS GROUP_NM
, 0 AS CATEGORY_ID
, NULL AS CATEGORY_NM
, 0 AS CLASS_ID
, NULL AS CLASS_NM
, NULL AS ATTRIBUTE_NM
, NULL AS MANUF_TYPE_CD
, 0 AS BRAND_CD
, NULL AS UPDATE_TS_MT  

FROM DW_DSS.LU_OFFER AS A

JOIN DW_DSS.COPIENT_ITEM_PROMO_PRC AS B
ON A.INCENTIVE_ID = B.INCENTIVE_ID

JOIN TEMP_CMS.JAA_CONSOL_OFF_BNK AS C
ON A.CLIENT_OFFER_ID = C.REQ_ID

JOIN DW_DSS.LU_UPC AS D
ON B.UPC_ID = D.UPC_ID

WHERE B.UPC_ID > 0

AND C.WEEK_ID = (SELECT WEEK_ID FROM TEMP_MARKETING.PDA_LU_TIME GROUP BY 1) 
AND C.PROGRAM_TYPE = 'DIVWKLY' 
AND C.PROGRAM_SUBTYPE NOT LIKE '%DEFAULT%'

AND D.GROUP_ID BETWEEN 1 AND 97
AND D.DEPARTMENT_ID > 0
AND D.DEPT_SECTION_NM IS NOT NULL
AND TRIM(D.DEPT_SECTION_NM)<>' '   

GROUP BY 1;







UPDATE VT_PDA_LU_OFFER_UPCS AS A

SET DEPARTMENT_ID = B.DEPARTMENT_ID
, DEPARTMENT_NM = B.DEPARTMENT_NM
, GROUP_ID = B.GROUP_ID
, GROUP_NM = B.GROUP_NM
, CATEGORY_ID = B.CATEGORY_ID
, CATEGORY_NM = B.CATEGORY_NM
, CLASS_ID = B.CLASS_ID
, CLASS_NM = B.CLASS_NM
, MANUF_TYPE_CD = B.MANUF_TYPE_CD
, BRAND_CD = B.BRAND_CD
, ATTRIBUTE_NM = B.ATTRIBUTE_NM
, OFFER_DSC = B.OFFER_DESC

FROM (
  
  SELECT A.OFFER_NBR
  , C.DEPARTMENT_ID
  , INITCAP(TRIM(LOWER(C.DEPARTMENT_NM))) AS DEPARTMENT_NM  
  , C.GROUP_ID
  , INITCAP(TRIM(LOWER(C.GROUP_NM))) AS GROUP_NM 
  , C.CATEGORY_ID
  , INITCAP(TRIM(LOWER(C.CATEGORY_NM))) AS CATEGORY_NM  
  , B.CLASS_ID
  , INITCAP(TRIM(LOWER(B.CLASS_NM))) AS CLASS_NM 
  , TRIM(B.MANUF_TYPE_CD) AS MANUF_TYPE_CD
  , TRIM(B.BRAND_CD) AS BRAND_CD  
  , A.ATTRIBUTE_NM
  , MAX(A.OFFER_DSC) AS OFFER_DESC
  , ROW_NUMBER() OVER (PARTITION BY A.OFFER_NBR ORDER BY COUNT(*) DESC) R1
  
  FROM VT_PDA_LU_OFFER AS A
  
  JOIN DW_DSS.LU_UPC AS B
  ON A.REP_UPC = B.UPC_ID
  
  JOIN 
    (SELECT DEPARTMENT_ID, DEPARTMENT_NM, GROUP_ID, GROUP_NM, CATEGORY_ID, CATEGORY_NM 
    FROM DW_DSS.LU_RESPONSIBILITY 
    WHERE CORPORATION_ID = 1 
    GROUP BY 1,2,3,4,5,6) AS C
    
  ON B.CATEGORY_ID = C.CATEGORY_ID   
  
 
  
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12

) AS B

WHERE A.OFFER_NBR = B.OFFER_NBR
AND B.R1 = 1;
















UPDATE VT_PDA_LU_OFFER_UPCS
SET UPDATE_TS_MT = CURRENT_TIMESTAMP;




DELETE FROM TEMP_MARKETING.PDA_LU_OFFER_UPCS;



INSERT INTO TEMP_MARKETING.PDA_LU_OFFER_UPCS

SELECT *
FROM VT_PDA_LU_OFFER_UPCS;








CREATE OR REPLACE TEMPORARY TABLE VT_PDA_OFFER_STORE_SCAN (
OFFER_NBR INT
, STORE_ID INT
, SCAN_DAYS_CHECK INT
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;








USE WAREHOUSE PROD_CARD_MARKETING_BIG_WH;
INSERT INTO VT_PDA_OFFER_STORE_SCAN

SELECT C.OFFER_NBR, A.STORE_ID, 7 AS SCAN_DAYS_CHECK, CURRENT_TIMESTAMP UPDATE_TS_MT

FROM DW_DSS.TXN_FACTS AS A

JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
ON A.STORE_ID = B.STORE_ID

JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS C
ON A.UPC_ID = C.UPC_ID   
  
WHERE TXN_DTE BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE - 1
AND TXN_HDR_SRC_CD = 0
AND MISC_ITEM_QTY = 0
AND DEPOSIT_ITEM_QTY = 0
AND REV_DTL_SUBTYPE_ID IN (0,7)




GROUP BY 1,2
HAVING SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT) > 0     




UNION


SELECT C.OFFER_NBR, A.STORE_ID, 7 AS SCAN_DAYS_CHECK, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM DW_DSS.TXN_FACTS AS A

JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
ON A.STORE_ID = B.STORE_ID       

JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS C
ON A.PLU_CD = C.UPC_ID  
  
WHERE TXN_DTE BETWEEN CURRENT_DATE - 7 AND CURRENT_DATE - 1
AND TXN_HDR_SRC_CD = 0
AND MISC_ITEM_QTY = 0
AND DEPOSIT_ITEM_QTY = 0
AND REV_DTL_SUBTYPE_ID IN (0,7)




AND A.PLU_CD > 0  

GROUP BY 1,2
HAVING SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT) > 0; 













DELETE FROM TEMP_MARKETING.PDA_OFFER_STORE_SCAN;



INSERT INTO TEMP_MARKETING.PDA_OFFER_STORE_SCAN

SELECT *
FROM VT_PDA_OFFER_STORE_SCAN;



















USE SCHEMA TEMP_MARKETING;

CREATE OR REPLACE TEMPORARY TABLE VT_PDA_HH_OFFER_SALES (
HOUSEHOLD_ID BIGINT
, FISCAL_WEEK_ID INT
, OFFER_NBR INT
, CATEGORY_ID INT
, NET_SALES DEC(18,2)
, TXNS BIGINT
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;





INSERT INTO VT_PDA_HH_OFFER_SALES

SELECT HOUSEHOLD_ID, WEEK_ID AS FISCAL_WEEK_ID, OFFER_NBR, CATEGORY_ID, SUM(SALES) AS NET_SALES, COUNT(DISTINCT TXN_ID) AS TXNS, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM

  (SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.UPC_ID = D.UPC_ID
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE
  
  JOIN
  
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*13 AND CURRENT_DATE - 7*1
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.PLU_CD = D.UPC_ID 
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID   
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE    
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*13 AND CURRENT_DATE - 7*1
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  AND A.PLU_CD > 0  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3,4;






INSERT INTO VT_PDA_HH_OFFER_SALES

SELECT HOUSEHOLD_ID, WEEK_ID AS FISCAL_WEEK_ID, OFFER_NBR, CATEGORY_ID, SUM(SALES) AS NET_SALES, COUNT(DISTINCT TXN_ID) AS TXNS, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM

  (SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.UPC_ID = D.UPC_ID
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7*14
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.PLU_CD = D.UPC_ID  
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID   
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE    
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7*14
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  AND A.PLU_CD > 0  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3,4;






INSERT INTO VT_PDA_HH_OFFER_SALES

SELECT HOUSEHOLD_ID, WEEK_ID AS FISCAL_WEEK_ID, OFFER_NBR, CATEGORY_ID, SUM(SALES) AS NET_SALES, COUNT(DISTINCT TXN_ID) AS TXNS, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM

  (SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.UPC_ID = D.UPC_ID
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*40 AND CURRENT_DATE - 7*27
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.PLU_CD = D.UPC_ID  
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID   
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE    
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*40 AND CURRENT_DATE - 7*27
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  AND A.PLU_CD > 0  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3,4;






INSERT INTO VT_PDA_HH_OFFER_SALES

SELECT HOUSEHOLD_ID, WEEK_ID AS FISCAL_WEEK_ID, OFFER_NBR, CATEGORY_ID, SUM(SALES) AS NET_SALES, COUNT(DISTINCT TXN_ID) AS TXNS, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM

  (SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.UPC_ID = D.UPC_ID
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*56 AND CURRENT_DATE - 7*41
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT D.OFFER_NBR
  , D.OFFER_DSC
  , D.CATEGORY_ID
  , CAST(A.TXN_ID AS DEC(26,0)) AS TXN_ID
  , A.TXN_DTE
  , F.WEEK_ID
  , C.HOUSEHOLD_ID    
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS B
  ON A.STORE_ID = B.STORE_ID
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS C
  ON A.CARD_NBR = C.CARD_NBR
  AND C.HOUSEHOLD_ID > 0
  
  JOIN TEMP_MARKETING.PDA_LU_OFFER_UPCS AS D
  ON A.PLU_CD = D.UPC_ID  
  
  JOIN TEMP_MARKETING.PDA_LU_HH AS E
  ON C.HOUSEHOLD_ID = E.HOUSEHOLD_ID   
  
  JOIN DW_DSS.LU_DAY_MERGE AS F
  ON A.TXN_DTE = F.D_DATE    
  
  JOIN
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*56 AND CURRENT_DATE - 7*41
   GROUP BY 1) AS G
  
  ON F.WEEK_ID = G.WEEK_ID  
   
  WHERE TXN_DTE >= CURRENT_DATE - 430
  AND TXN_HDR_SRC_CD = 0
  AND MISC_ITEM_QTY = 0
  AND DEPOSIT_ITEM_QTY = 0
  AND REV_DTL_SUBTYPE_ID IN (0,7)
  
  
  AND A.PLU_CD > 0  
  
  GROUP BY 1,2,3,4,5,6,7
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3,4;







DELETE FROM TEMP_MARKETING.PDA_HH_OFFER_SALES;



INSERT INTO TEMP_MARKETING.PDA_HH_OFFER_SALES

SELECT *

FROM VT_PDA_HH_OFFER_SALES;




SELECT COUNT(DISTINCT CATEGORY_ID) FROM TEMP_MARKETING.PDA_HH_OFFER_SALES ;

SELECT COUNT(DISTINCT OFFER_NBR) FROM TEMP_MARKETING.PDA_HH_OFFER_SALES ;








CREATE OR REPLACE TEMPORARY TABLE VT_PDA_HH_CAT_WEEK (
HOUSEHOLD_ID BIGINT
, CATEGORY_ID INT
, FISCAL_WEEK_ID INT
, WEEKS_AGO INT
, RECENT_PURCH_RANK INT
) ON COMMIT PRESERVE ROWS;




INSERT INTO VT_PDA_HH_CAT_WEEK

SELECT A.HOUSEHOLD_ID
, A.CATEGORY_ID
, A.WEEK_ID AS FISCAL_WEEK_ID
, B.WEEKS_AGO
, ROW_NUMBER() OVER (PARTITION BY A.HOUSEHOLD_ID, A.CATEGORY_ID ORDER BY MAX(A.WEEK_ID) DESC) AS RECENT_PURCH_RANK

FROM TEMP_MARKETING.FISCAL_WK_HH_CATEGORY_SPEND AS A 

JOIN
  (SELECT WEEK_ID, RANK() OVER (ORDER BY MAX(WEEK_ID) DESC) AS WEEKS_AGO
  FROM DW_DSS.LU_DAY_MERGE
  WHERE WEEK_ID >= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*56 GROUP BY 1)  
  AND WEEK_ID <= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*1 GROUP BY 1)
  GROUP BY 1) AS B

ON A.WEEK_ID = B.WEEK_ID    
  
WHERE A.WEEK_ID >= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*56 GROUP BY 1) 
AND A.WEEK_ID <= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*1 GROUP BY 1)

GROUP BY 1,2,3,4; 





















CREATE OR REPLACE TEMPORARY TABLE VT_MULT_CAT_PURCH AS (

  SELECT A.HOUSEHOLD_ID, A.CATEGORY_ID
  
  FROM TEMP_MARKETING.FISCAL_WK_HH_CATEGORY_SPEND AS A  
  
  JOIN
    
    (SELECT WEEK_ID
    FROM DW_DSS.LU_DAY_MERGE
    WHERE D_DATE BETWEEN CURRENT_DATE - 7*56 AND CURRENT_DATE - 7
    GROUP BY 1) AS B
    
  ON A.WEEK_ID = B.WEEK_ID
  
  GROUP BY 1,2
HAVING COUNT(DISTINCT A.WEEK_ID) > 1
  
  

); 






















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_MULT_PURCH_CYCLE (
HOUSEHOLD_ID BIGINT
, CATEGORY_ID INT
, PURCH_CYCLE_WKS INT
) ON COMMIT PRESERVE ROWS;




INSERT INTO VT_PDA_MULT_PURCH_CYCLE

SELECT HOUSEHOLD_ID
, CATEGORY_ID
, AVG(WKS_BTWN_PURCHASES) AS PURCH_CYCLE_WKS

FROM
  
  (SELECT A.HOUSEHOLD_ID, A.CATEGORY_ID, B.FISCAL_WEEK_ID, B.WEEKS_AGO - A.WEEKS_AGO AS WKS_BTWN_PURCHASES
  
  FROM VT_PDA_HH_CAT_WEEK AS A
  
  JOIN VT_PDA_HH_CAT_WEEK AS B
  ON A.HOUSEHOLD_ID = B.HOUSEHOLD_ID 
  AND A.CATEGORY_ID = B.CATEGORY_ID
  AND A.RECENT_PURCH_RANK = B.RECENT_PURCH_RANK - 1
  
  JOIN VT_MULT_CAT_PURCH AS C 
  ON A.HOUSEHOLD_ID = C.HOUSEHOLD_ID
  AND A.CATEGORY_ID = C.CATEGORY_ID
  AND B.HOUSEHOLD_ID = C.HOUSEHOLD_ID
  AND B.CATEGORY_ID = C.CATEGORY_ID   
  
  GROUP BY 1,2,3,4) AS X

GROUP BY 1,2;
















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_PURCH_CYCLE (
HOUSEHOLD_ID BIGINT
, CATEGORY_ID INT
, RECENT_WEEKS_AGO_BOUGHT INT
, PURCH_CYCLE_WEEKS INT
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;





INSERT INTO VT_PDA_PURCH_CYCLE

SELECT HOUSEHOLD_ID
, CATEGORY_ID
, MIN(WEEKS_AGO) AS RECENT_WEEKS_AGO_BOUGHT
, NULL AS PURCH_CYCLE_WEEKS
, NULL AS UPDATE_TS_MST

FROM VT_PDA_HH_CAT_WEEK

GROUP BY 1,2;













UPDATE VT_PDA_PURCH_CYCLE AS A

SET PURCH_CYCLE_WEEKS = B.PURCH_CYCLE_WEEKS

FROM (

  SELECT HOUSEHOLD_ID, CATEGORY_ID, AVG(PURCH_CYCLE_WKS) AS PURCH_CYCLE_WEEKS
  FROM VT_PDA_MULT_PURCH_CYCLE
  GROUP BY 1,2
HAVING PURCH_CYCLE_WEEKS <= 8
  

) AS B

WHERE A.HOUSEHOLD_ID = B.HOUSEHOLD_ID
AND A.CATEGORY_ID = B.CATEGORY_ID;









UPDATE VT_PDA_PURCH_CYCLE AS A

SET PURCH_CYCLE_WEEKS = B.ELITE_PURCH_CYCLE_WEEKS

FROM (
  
  SELECT A.HOUSEHOLD_ID, A.CATEGORY_ID, B.ELITE_PURCH_CYCLE_WEEKS
  
  FROM VT_PDA_PURCH_CYCLE AS A
  
  JOIN

    (SELECT CATEGORY_ID, AVG(PURCH_CYCLE_WKS) AS ELITE_PURCH_CYCLE_WEEKS
    FROM VT_PDA_MULT_PURCH_CYCLE
    WHERE HOUSEHOLD_ID IN (
     SELECT HOUSEHOLD_ID
     FROM DW_DSS.FACTS_SEGMENT_WEEK
     WHERE QUARTERLY_LEVEL2_SEGMENT_ID = 1
     AND WEEK_ID = (SELECT MAX(WEEK_ID) FROM DW_DSS.FACTS_SEGMENT_WEEK)
     GROUP BY 1)  
    
    GROUP BY 1
HAVING ELITE_PURCH_CYCLE_WEEKS < 12
     
    ) AS B
  
  ON A.CATEGORY_ID = B.CATEGORY_ID
  
  WHERE A.PURCH_CYCLE_WEEKS IS NULL
  
  GROUP BY 1,2,3  

) AS B

WHERE A.HOUSEHOLD_ID = B.HOUSEHOLD_ID
AND A.CATEGORY_ID = B.CATEGORY_ID;









UPDATE VT_PDA_PURCH_CYCLE
SET PURCH_CYCLE_WEEKS = 12
WHERE PURCH_CYCLE_WEEKS IS NULL;




UPDATE VT_PDA_PURCH_CYCLE
SET UPDATE_TS_MT = CURRENT_TIMESTAMP;




DELETE FROM TEMP_MARKETING.PDA_PURCH_CYCLE;



INSERT INTO TEMP_MARKETING.PDA_PURCH_CYCLE

SELECT *
FROM VT_PDA_PURCH_CYCLE;


















CREATE OR REPLACE TEMPORARY TABLE VT_CAT_DIV_WK_SALES AS (

  SELECT CATEGORY_ID, DIVISION_ID, WEEK_ID, SUM(NET_AMT) AS SALES
  
  FROM TEMP_MARKETING.FISCAL_WK_HH_CATEGORY_SPEND  
  
  WHERE WEEK_ID >= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*52 GROUP BY 1)  
  AND WEEK_ID <= (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7*1 GROUP BY 1)    
    
  GROUP BY 1,2,3

); 



















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_SEASONALITY (
CATEGORY_ID INT
, DIVISION_ID SMALLINT
, SEASONALITY_INDEX DEC(18,2)
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;





INSERT INTO VT_PDA_SEASONALITY

SELECT CATEGORY_ID, DIVISION_ID, SEASONALITY_INDEX, CURRENT_TIMESTAMP AS UPDATE_TS_MT

FROM
  
  (SELECT A.CATEGORY_ID, A.DIVISION_ID, A.WEEK_ID, A.SALES, B.AVG_WKLY_SALES, CAST(A.SALES AS DEC(18,4))/NULLIF(B.AVG_WKLY_SALES,'0') * 100 AS SEASONALITY_INDEX
  
  FROM VT_CAT_DIV_WK_SALES AS A
  
  JOIN
  
   (SELECT CATEGORY_ID, DIVISION_ID, AVG(SALES) AS AVG_WKLY_SALES
   FROM VT_CAT_DIV_WK_SALES
   GROUP BY 1,2) AS B
  
  ON A.CATEGORY_ID = B.CATEGORY_ID
  AND A.DIVISION_ID = B.DIVISION_ID
  
  GROUP BY 1,2,3,4,5) AS X

WHERE WEEK_ID = (SELECT WEEK_ID - 100 FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE + 7 GROUP BY 1)

GROUP BY 1,2,3;






DELETE FROM TEMP_MARKETING.PDA_SEASONALITY;



INSERT INTO TEMP_MARKETING.PDA_SEASONALITY

SELECT *
FROM VT_PDA_SEASONALITY;


















USE SCHEMA TEMP_CMS;
CREATE OR REPLACE TEMPORARY TABLE VT_PDA_ATTRIBUTE_BUYERS (
HOUSEHOLD_ID BIGINT
, ATTRIBUTE_NM VARCHAR(50)
, UPDATE_TS_MT TIMESTAMP
) ON COMMIT PRESERVE ROWS;





INSERT INTO VT_PDA_ATTRIBUTE_BUYERS

SELECT E.HOUSEHOLD_ID


, CURRENT_TIMESTAMP AS UPDATE_TS_MT      

FROM DW_DSS.TXN_FACTS AS A

JOIN DW_DSS.LU_UPC AS B
ON A.UPC_ID = B.UPC_ID 

JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
ON A.STORE_ID = C.STORE_ID

JOIN DW_DSS.LU_DAY_MERGE AS D
ON A.TXN_DTE = D.D_DATE

JOIN DW_DSS.LU_CARD_ACCOUNT AS E
ON A.CARD_NBR = E.CARD_NBR
AND E.HOUSEHOLD_ID > 0  

JOIN
  (SELECT WEEK_ID
  FROM DW_DSS.LU_DAY_MERGE
  WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7
  GROUP BY 1) AS F

ON D.WEEK_ID = F.WEEK_ID

JOIN

  (SELECT HOUSEHOLD_ID
  FROM TEMP_MARKETING.WKLY_HH_SEG
  WHERE WEEK_ID = (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7 GROUP BY 1)
  GROUP BY 1) AS G

ON E.HOUSEHOLD_ID = G.HOUSEHOLD_ID
  
WHERE A.TXN_DTE >= CURRENT_DATE - 365
AND A.TXN_HDR_SRC_CD = 0
AND A.MISC_ITEM_QTY = 0
AND A.DEPOSIT_ITEM_QTY = 0
AND A.REV_DTL_SUBTYPE_ID IN (0,7)

AND B.GROUP_ID BETWEEN 1 AND 97
AND B.CATEGORY_ID <> 9020 
AND B.DEPARTMENT_ID > 0
AND B.DEPT_SECTION_NM IS NOT NULL
AND TRIM(B.DEPT_SECTION_NM)<>' '   

AND ATTRIBUTE_NM IS NOT NULL    

GROUP BY 1,2
HAVING SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT) > 0     




UNION


SELECT E.HOUSEHOLD_ID


, CURRENT_TIMESTAMP AS UPDATE_TS_MT         

FROM DW_DSS.TXN_FACTS AS A

JOIN DW_DSS.LU_UPC AS B
ON A.PLU_CD = B.UPC_ID  

JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
ON A.STORE_ID = C.STORE_ID 

JOIN DW_DSS.LU_DAY_MERGE AS D
ON A.TXN_DTE = D.D_DATE  

JOIN DW_DSS.LU_CARD_ACCOUNT AS E
ON A.CARD_NBR = E.CARD_NBR
AND E.HOUSEHOLD_ID > 0   

JOIN
  (SELECT WEEK_ID
  FROM DW_DSS.LU_DAY_MERGE
  WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7
  GROUP BY 1) AS F

ON D.WEEK_ID = F.WEEK_ID        

JOIN
  (SELECT HOUSEHOLD_ID
  FROM TEMP_MARKETING.WKLY_HH_SEG
  WHERE WEEK_ID = (SELECT WEEK_ID FROM DW_DSS.LU_DAY_MERGE WHERE D_DATE = CURRENT_DATE - 7 GROUP BY 1)
  GROUP BY 1) AS G

ON E.HOUSEHOLD_ID = G.HOUSEHOLD_ID   
  
WHERE A.TXN_DTE >= CURRENT_DATE - 365
AND A.TXN_HDR_SRC_CD = 0
AND A.MISC_ITEM_QTY = 0
AND A.DEPOSIT_ITEM_QTY = 0
AND A.REV_DTL_SUBTYPE_ID IN (0,7)

AND B.GROUP_ID BETWEEN 1 AND 97
AND B.CATEGORY_ID <> 9020 
AND B.DEPARTMENT_ID > 0
AND B.DEPT_SECTION_NM IS NOT NULL
AND TRIM(B.DEPT_SECTION_NM)<>' '   

AND A.PLU_CD > 0    

AND ATTRIBUTE_NM IS NOT NULL

GROUP BY 1,2
HAVING SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT) > 0;    








DELETE FROM TEMP_MARKETING.PDA_ATTRIBUTE_BUYERS;



INSERT INTO TEMP_MARKETING.PDA_ATTRIBUTE_BUYERS

SELECT *
FROM TEMP_CMS.VT_PDA_ATTRIBUTE_BUYERS;
















CREATE OR REPLACE TEMPORARY TABLE VT_PDA_HH_UPC_WKLY_SALES AS (

   SELECT HOUSEHOLD_ID, UPC_ID, WEEK_ID AS FISCAL_WEEK_ID, SUM(SALES) AS NET_SALES, CAST(NULL AS TIMESTAMP(0)) AS UPDATE_TS_MT
   
   FROM
   
    (SELECT E.HOUSEHOLD_ID
    , A.UPC_ID
    , D.WEEK_ID
    , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES    
    
    FROM DW_DSS.TXN_FACTS AS A
    
    JOIN DW_DSS.LU_UPC AS B
    ON A.UPC_ID = B.UPC_ID 
    
    JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
    ON A.STORE_ID = C.STORE_ID
    
    JOIN DW_DSS.LU_DAY_MERGE AS D
    ON A.TXN_DTE = D.D_DATE
   
    JOIN DW_DSS.LU_CARD_ACCOUNT AS E
    ON A.CARD_NBR = E.CARD_NBR
    AND E.HOUSEHOLD_ID > 0         
    
    JOIN
      
      (SELECT WEEK_ID
      FROM DW_DSS.LU_DAY_MERGE
      WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7*20
      GROUP BY 1) AS F
    
    ON D.WEEK_ID = F.WEEK_ID
      
    WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE 
    AND A.TXN_HDR_SRC_CD = 0
    AND A.MISC_ITEM_QTY = 0
    AND A.DEPOSIT_ITEM_QTY = 0
    AND A.REV_DTL_SUBTYPE_ID IN (0,7)
    
    AND B.GROUP_ID BETWEEN 1 AND 97
    AND B.CATEGORY_ID <> 9020 
    AND B.DEPARTMENT_ID > 0
    AND B.DEPT_SECTION_NM IS NOT NULL
    AND TRIM(B.DEPT_SECTION_NM)<>' '   
    
    GROUP BY 1,2,3
HAVING SALES > 0    
    
    
    
    
    UNION ALL
    
    
    SELECT E.HOUSEHOLD_ID
    , A.PLU_CD 
    , D.WEEK_ID
    , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES      
    
    FROM DW_DSS.TXN_FACTS AS A
    
    JOIN DW_DSS.LU_UPC AS B
    ON A.PLU_CD = B.UPC_ID  
   
    JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
    ON A.STORE_ID = C.STORE_ID 
    
    JOIN DW_DSS.LU_DAY_MERGE AS D
    ON A.TXN_DTE = D.D_DATE  
    
    JOIN DW_DSS.LU_CARD_ACCOUNT AS E
    ON A.CARD_NBR = E.CARD_NBR
    AND E.HOUSEHOLD_ID > 0        
      
    JOIN
      
      (SELECT WEEK_ID
      FROM DW_DSS.LU_DAY_MERGE
      WHERE D_DATE BETWEEN CURRENT_DATE - 7*26 AND CURRENT_DATE - 7*20
      GROUP BY 1) AS F
    
    ON D.WEEK_ID = F.WEEK_ID
      
    WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE
    AND A.TXN_HDR_SRC_CD = 0
    AND A.MISC_ITEM_QTY = 0
    AND A.DEPOSIT_ITEM_QTY = 0
    AND A.REV_DTL_SUBTYPE_ID IN (0,7)
    
    AND B.GROUP_ID BETWEEN 1 AND 97
    AND B.CATEGORY_ID <> 9020 
    AND B.DEPARTMENT_ID > 0
    AND B.DEPT_SECTION_NM IS NOT NULL
    AND TRIM(B.DEPT_SECTION_NM)<>' '   
    
    AND A.PLU_CD > 0  
    
    GROUP BY 1,2,3
HAVING SALES > 0
    
    ) AS X
   
   GROUP BY 1,2,3

); 






  



INSERT INTO VT_PDA_HH_UPC_WKLY_SALES 

SELECT HOUSEHOLD_ID, UPC_ID, WEEK_ID AS FISCAL_WEEK_ID, SUM(SALES) AS NET_SALES, NULL AS UPDATE_TS_MT

FROM

  (SELECT E.HOUSEHOLD_ID
  , A.UPC_ID
  , D.WEEK_ID
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES    
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_UPC AS B
  ON A.UPC_ID = B.UPC_ID 
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
  ON A.STORE_ID = C.STORE_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS D
  ON A.TXN_DTE = D.D_DATE

  JOIN DW_DSS.LU_CARD_ACCOUNT AS E
  ON A.CARD_NBR = E.CARD_NBR
  AND E.HOUSEHOLD_ID > 0         
  
  JOIN
   
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*19 AND CURRENT_DATE - 7*10
   GROUP BY 1) AS F
  
  ON D.WEEK_ID = F.WEEK_ID
   
  WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE 
  AND A.TXN_HDR_SRC_CD = 0
  AND A.MISC_ITEM_QTY = 0
  AND A.DEPOSIT_ITEM_QTY = 0
  AND A.REV_DTL_SUBTYPE_ID IN (0,7)
  
  AND B.GROUP_ID BETWEEN 1 AND 97
  AND B.CATEGORY_ID <> 9020 
  AND B.DEPARTMENT_ID > 0
  AND B.DEPT_SECTION_NM IS NOT NULL
  AND TRIM(B.DEPT_SECTION_NM)<>' '   
  
  GROUP BY 1,2,3
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT E.HOUSEHOLD_ID
  , A.PLU_CD 
  , D.WEEK_ID
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES      
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_UPC AS B
  ON A.PLU_CD = B.UPC_ID    

  JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
  ON A.STORE_ID = C.STORE_ID 
  
  JOIN DW_DSS.LU_DAY_MERGE AS D
  ON A.TXN_DTE = D.D_DATE  
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS E
  ON A.CARD_NBR = E.CARD_NBR
  AND E.HOUSEHOLD_ID > 0        
   
  JOIN
   
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*19 AND CURRENT_DATE - 7*10
   GROUP BY 1) AS F
  
  ON D.WEEK_ID = F.WEEK_ID
   
  WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE 
  AND A.TXN_HDR_SRC_CD = 0
  AND A.MISC_ITEM_QTY = 0
  AND A.DEPOSIT_ITEM_QTY = 0
  AND A.REV_DTL_SUBTYPE_ID IN (0,7)
  
  AND B.GROUP_ID BETWEEN 1 AND 97
  AND B.CATEGORY_ID <> 9020 
  AND B.DEPARTMENT_ID > 0
  AND B.DEPT_SECTION_NM IS NOT NULL
  AND TRIM(B.DEPT_SECTION_NM)<>' '   
  
  AND A.PLU_CD > 0   
  
  GROUP BY 1,2,3
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3;






INSERT INTO VT_PDA_HH_UPC_WKLY_SALES

SELECT HOUSEHOLD_ID, UPC_ID, WEEK_ID AS FISCAL_WEEK_ID, SUM(SALES) AS NET_SALES, NULL AS UPDATE_TS_MT

FROM

  (SELECT E.HOUSEHOLD_ID
  , A.UPC_ID
  , D.WEEK_ID
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES    
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_UPC AS B
  ON A.UPC_ID = B.UPC_ID 
  
  JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
  ON A.STORE_ID = C.STORE_ID
  
  JOIN DW_DSS.LU_DAY_MERGE AS D
  ON A.TXN_DTE = D.D_DATE

  JOIN DW_DSS.LU_CARD_ACCOUNT AS E
  ON A.CARD_NBR = E.CARD_NBR
  AND E.HOUSEHOLD_ID > 0         
  
  JOIN
   
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*9 AND CURRENT_DATE - 7*1
   GROUP BY 1) AS F
  
  ON D.WEEK_ID = F.WEEK_ID
   
  WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE 
  AND A.TXN_HDR_SRC_CD = 0
  AND A.MISC_ITEM_QTY = 0
  AND A.DEPOSIT_ITEM_QTY = 0
  AND A.REV_DTL_SUBTYPE_ID IN (0,7)
  
  AND B.GROUP_ID BETWEEN 1 AND 97
  AND B.CATEGORY_ID <> 9020 
  AND B.DEPARTMENT_ID > 0
  AND B.DEPT_SECTION_NM IS NOT NULL
  AND TRIM(B.DEPT_SECTION_NM)<>' '   
  
  GROUP BY 1,2,3
HAVING SALES > 0    
  
  
  
  
  UNION ALL
  
  
  SELECT E.HOUSEHOLD_ID
  , A.PLU_CD 
  , D.WEEK_ID
  , ZEROIFNULL(SUM(NET_AMT + MKDN_WOD_ALLOC_AMT + MKDN_POD_ALLOC_AMT)) AS SALES      
  
  FROM DW_DSS.TXN_FACTS AS A
  
  JOIN DW_DSS.LU_UPC AS B
  ON A.PLU_CD = B.UPC_ID   

  JOIN DW_DSS.LU_STORE_FINANCE_OM AS C
  ON A.STORE_ID = C.STORE_ID 
  
  JOIN DW_DSS.LU_DAY_MERGE AS D
  ON A.TXN_DTE = D.D_DATE  
  
  JOIN DW_DSS.LU_CARD_ACCOUNT AS E
  ON A.CARD_NBR = E.CARD_NBR
  AND E.HOUSEHOLD_ID > 0        
   
  JOIN
   
   (SELECT WEEK_ID
   FROM DW_DSS.LU_DAY_MERGE
   WHERE D_DATE BETWEEN CURRENT_DATE - 7*9 AND CURRENT_DATE - 7*1
   GROUP BY 1) AS F
  
  ON D.WEEK_ID = F.WEEK_ID
   
  WHERE A.TXN_DTE BETWEEN CURRENT_DATE - 365 AND CURRENT_DATE 
  AND A.TXN_HDR_SRC_CD = 0
  AND A.MISC_ITEM_QTY = 0
  AND A.DEPOSIT_ITEM_QTY = 0
  AND A.REV_DTL_SUBTYPE_ID IN (0,7)
  
  AND B.GROUP_ID BETWEEN 1 AND 97
  AND B.CATEGORY_ID <> 9020 
  AND B.DEPARTMENT_ID > 0
  AND B.DEPT_SECTION_NM IS NOT NULL
  AND TRIM(B.DEPT_SECTION_NM)<>' '           
  
  AND A.PLU_CD > 0    
  
  GROUP BY 1,2,3
HAVING SALES > 0
  
  ) AS X

GROUP BY 1,2,3;






UPDATE VT_PDA_HH_UPC_WKLY_SALES
SET UPDATE_TS_MT = CURRENT_TIMESTAMP;




DELETE FROM TEMP_MKTG.PDA_HH_UPC_WKLY_SALES;



INSERT INTO TEMP_MKTG.PDA_HH_UPC_WKLY_SALES

SELECT *
FROM VT_PDA_HH_UPC_WKLY_SALES;

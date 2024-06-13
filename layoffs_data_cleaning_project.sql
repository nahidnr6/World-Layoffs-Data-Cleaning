-- Data Cleaning 
-- 1. Remove Duplicates 
-- 2. Standardize the Data 
-- 3. Null Values or blank values
-- 4. Remove Any Columns or rows 

-- Creating a new table layoffs_staging that we can alter because you don't want to alter the raw table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Displays the duplicate rows by partioning the data and creating and new column called row_num . All duplicates have 
-- a row_num > 1 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY location, company,
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
-- Deletes the duplicate 
DELETE 
FROM duplicate_cte
WHERE row_num > 1; 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2
WHERE row_num > 1; 

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY location, company,
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2;

DELETE
FROM layoffs_staging2
WHERE row_num > 1; 

-- Standardizing data

-- Trims any blank spaces before or after the company name
SELECT company, (trim(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = (trim(company));

SELECT DISTINCT industry 
FROM layoffs_staging2;

-- Shows that we have some values in the industry column that are null or empty
SELECT * 
FROM layoffs_staging2
WHERE industry = 'Travel';

-- This code could be used to populate the missing industry values if we had another value to compare it too
/* UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;    */


UPDATE layoffs_staging2
SET industry = 'Travel' 
WHERE company = 'Airbnb';

-- Change the date from a text/string into a date column. This is very important if we want to do time series analysis

SELECT `date`, 
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Change typos in country column
-- This shows that there is a 'United States' value and 'United States.' value 
SELECT distinct country
FROM layoffs_staging2
WHERE country like 'United States%';

-- Fixes this 
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Look at Null Values 

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- 4. remove any columns and rows we need to

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use
DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM world_layoffs.layoffs_staging2;

-- Don't need the row_num column anymore
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * 
FROM world_layoffs.layoffs_staging2;
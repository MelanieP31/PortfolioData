SELECT*
FROM dbo.NashvilleHousing

--PROJECT DATA CLEANING IN SQL

-----------------------------------------------------------------------------------------------
--Standardize Date format
SELECT SaleDate
FROM dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate Date

SELECT SaleDate
FROM dbo.NashvilleHousing

--------------------------------------------------------------------------------------------
--POPULATE ADRESS
SELECT *
FROM ProjectPortfolioCovid..NashvilleHousing
WHERE PropertyAddress is null

--Search if we can determine it - si le meme ID alors la meme adresse
SELECT *
FROM ProjectPortfolioCovid..NashvilleHousing
ORDER BY ParcelID

--Join by itself avec le meme ParselID (mais Transaction unique pour pas avoir de doublons créer artificiellement)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM ProjectPortfolioCovid..NashvilleHousing a
JOIN ProjectPortfolioCovid..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--fonction for populate (algo : if a.property is null --> b.property adresse ; function ISNULL())
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolioCovid..NashvilleHousing a
JOIN ProjectPortfolioCovid..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null

--Mettre dans un UPDATE
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolioCovid..NashvilleHousing a
JOIN ProjectPortfolioCovid..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


---------------------------------------------------------------------------------------------
--BREAKING OUT ADRESS INTO INDIVIDUAL COLUMN (Adress, City, State)

SELECT PropertyAddress
FROM NashvilleHousing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as NewAddress,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAdress nvarchar(250)

UPDATE NashvilleHousing
SET PropertySplitAdress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(250)

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT PropertySplitAdress, PropertySplitCity
FROM NashvilleHousing

-- Owner Adress avec Parse
SELECT OwnerAddress
FROM NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerAdressSplit nvarchar(250)
ALTER TABLE NashvilleHousing
ADD OwnerCity nvarchar(250)
ALTER TABLE NashvilleHousing
ADD OwnerState nvarchar(250)

UPDATE NashvilleHousing
SET OwnerAdressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT OwnerAdressSplit, OwnerCity, OwnerState
FROM NashvilleHousing

----------------------------------------------------------------------------------------------------
--'Sold and vacant' field : change Y and N to Yes or No
SELECT Distinct (SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END

----------------------------------------------------------------------------------------
--REMOVE DUPLICATE  --> normalement pas de délétion des réplicat, au pire on les met ailleurs
--Si tout les entrées ParcelID, ... sont les mêmes alors c'est un réplicat 
--ROW_NUMBER() OVER( PARTITION BY --> Numérote les sorties : si une seule avec tout id =1 si 2 sont id pour tout les param = 2, etc ...


WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
				 ORDER BY UniqueID
				 ) AS row_num
FROM NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


----------------------------------------------------------------------------------------
--DELETE UNUSED COLUMNS (pas dans les data, mais dans les View normalement)

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT*
FROM NashvilleHousing
select *
from PortfolioProject..NashvilleHousing


-- Standatdize date format


select SaleDate, cast(SaleDate as date) SaleDateConverted
from PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = cast(SaleDate as date)

alter table PortfolioProject..NashvilleHousing
add SaleDateConverted date;

Update PortfolioProject..NashvilleHousing
SET SaleDateConverted = cast(SaleDate as date)

select SaleDateConverted
from PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = SaleDateConverted


-- Populate Property Address Data


select *
from PortfolioProject..NashvilleHousing
where PropertyAddress is NULL

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
from PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
where b.PropertyAddress is NULL


------ Populate from b.PropertyAddress then update to the table


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
where a.PropertyAddress is NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID


-- Breaking out address into individual column (address, city, state) and then update to table


select PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) prop_address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) prop_city
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
add prop_address nvarchar(255);

update PortfolioProject..NashvilleHousing
SET prop_address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


alter table PortfolioProject..NashvilleHousing
add prop_city nvarchar(255);

update PortfolioProject..NashvilleHousing
SET prop_city = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

select OwnerAddress, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'),1) owner_state,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),2) owner_city,
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3) owner_address
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
add owner_state nvarchar(255),
	owner_city nvarchar(255),
	owner_address nvarchar (255)

update PortfolioProject..NashvilleHousing
SET owner_state = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)),
    owner_city = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)),
	owner_address = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'),3))


-- Change Y and N to Yes and No in 'SoldAsVacant' field


select distinct SoldAsVacant, count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by SoldAsVacant

select SoldAsVacant, 
CASE when SoldAsVacant = 'Y' then 'Yes'
	 when SoldAsVacant = 'N' then 'No'
	 else SoldAsVacant
	 end
	 as SoldAsVacantUpdate
from PortfolioProject..NashvilleHousing

update PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
						else SoldAsVacant
						end

-- Remove Duplicates


select *, 
	ROW_NUMBER() over (partition by ParcelID,
									PropertyAddress,
									SaleDate,
									SalePrice,
									LegalReference 
						order by ParcelID) as row_num
from PortfolioProject..NashvilleHousing

with ROWNUM as
(
select *, 
	ROW_NUMBER() over (partition by ParcelID,
									PropertyAddress,
									SaleDate,
									SalePrice,
									LegalReference 
						order by ParcelID) as row_num
from PortfolioProject..NashvilleHousing
)

select *
from ROWNUM
where row_num >1


-- Delete unused column


select *
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict


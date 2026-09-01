SELECT "Id", "Title", "ImageUrl"
FROM "Stories"
WHERE "ImageUrl" LIKE '%/uploads/%';

SELECT "Id", "Name", "ImageUrl"
FROM "Services"
WHERE "ImageUrl" LIKE '%/uploads/%';

SELECT "Id", "Name", "MainImageUrl"
FROM "Products"
WHERE "MainImageUrl" LIKE '%/uploads/%';

SELECT "Id", "ProductId", "ImageUrl"
FROM "ProductImages"
WHERE "ImageUrl" LIKE '%/uploads/%';

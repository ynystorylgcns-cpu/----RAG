SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    d.description AS column_comment
FROM pg_catalog.pg_attribute a
JOIN pg_catalog.pg_class c
    ON a.attrelid = c.oid
JOIN pg_catalog.pg_namespace n
    ON c.relnamespace = n.oid
LEFT JOIN pg_catalog.pg_description d
    ON d.objoid = c.oid
   AND d.objsubid = a.attnum
WHERE
    a.attnum > 0
    AND NOT a.attisdropped
    AND c.relkind = 'r'
    AND n.nspname = 'rag'
ORDER BY
    c.relname,
    a.attnum;
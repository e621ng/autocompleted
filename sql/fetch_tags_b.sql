SELECT
    tags.id,
    tags.name,
    tags.post_count,
    tags.category,
    NULL AS antecedent_name
FROM tags
WHERE show_trgm($1) <> '{}'
  AND tags.name % $1
  AND tags.post_count > 0
ORDER BY trunc(3 * similarity(name, $1)) DESC, post_count DESC, name DESC
LIMIT 10;

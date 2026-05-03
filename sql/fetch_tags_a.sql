(
    SELECT
        tags.id,
        tags.name,
        tags.post_count,
        tags.category,
        NULL AS antecedent_name,
        length(tags.name) AS name_length
    FROM tags
    WHERE tags.name LIKE $1 ESCAPE E'\\'
      AND tags.post_count > 0
    ORDER BY tags.post_count DESC
    LIMIT 10
)
UNION ALL
(
    SELECT
        id,
        name,
        post_count,
        category,
        antecedent_name,
        length(antecedent_name) AS name_length
    FROM (
        SELECT DISTINCT ON (tags.name)
            tags.id,
            tags.name,
            tags.post_count,
            tags.category,
            tag_aliases.antecedent_name
        FROM tag_aliases
        INNER JOIN tags ON tags.name = tag_aliases.consequent_name
        WHERE tag_aliases.antecedent_name LIKE $1 ESCAPE E'\\'
          AND tag_aliases.status IN ('active', 'processing', 'queued')
          AND tag_aliases.post_count > 0
          AND tags.name NOT LIKE $1 ESCAPE E'\\'
        ORDER BY tags.name, tag_aliases.post_count DESC
    ) deduped_aliases
    ORDER BY post_count DESC
    LIMIT 10
)
ORDER BY name_length, post_count DESC
LIMIT 10

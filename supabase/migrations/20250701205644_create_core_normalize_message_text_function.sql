-- -*- sql-product: postgres; -*-

create or replace function normalize_message_text(text)
  returns text
  language sql
  immutable
  returns null on null input
as $$
  select regexp_replace(
    regexp_replace(
      regexp_replace(
        $1,
        E'\t', ' ', 'g'),
        E'\n{3,}', E'\n\n', 'g'),
        E'[ \t]+$', '', 'gm')
$$;

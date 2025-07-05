-- -*- sql-product: postgres; -*-

create schema if not exists core;

create table core.ticket (
  id bigint primary key generated always as identity,
  document jsonb
);

create or replace function core.normalize_message_text(text)
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

create or replace function core.format_ticket_for_embedding(t core.ticket)
  returns table(id bigint, formatted text)
  language sql
  set search_path = 'core', 'public'
as $function$
  select
  t.id,
  core.normalize_message_text(
    format(
$template$
## TICKET SUBJECT
%s
    
## TICKET DESCRIPTION
%s
$template$,
    t.document->'ticket_with_messages'->>'subject',
    t.document->'ticket_with_messages'->>'content'));
  $function$;

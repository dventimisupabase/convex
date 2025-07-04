-- -*- sql-product: postgres; -*-

create schema if not exists core;

create table core.ticket (
  id bigint primary key generated always as identity,
  document jsonb
);

create or replace function core.format_ticket_for_embedding(t core.ticket)
  returns table(id bigint, formatted text)
  language sql
  set search_path = 'core', 'public'
as $function$
  select
  t.id,
  format(
    $template$
    SUBJECT:
    ==========
    %s
    
    CONTENT:
    ==========
    %s
    $template$,
    t.document->'ticket_with_messages'->'subject',
    t.document->'ticket_with_messages'->'content');
  $function$;

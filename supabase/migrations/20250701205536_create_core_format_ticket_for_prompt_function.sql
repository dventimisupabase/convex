-- -*- sql-product: postgres; -*-

create or replace function core.format_ticket_for_prompt(t core.ticket_with_messages)
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
